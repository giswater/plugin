#!/usr/bin/env python3
"""Detect i18n text changes by comparing origin PostgreSQL schemas with API baseline.

Workflow (CI)::

  1. GET  /api/i18n/messages          — full i18n baseline in one call (no query params)
  2. Read origin schemas (PostgreSQL) — ws_trans, ud_trans, etc.
  3. Classify new / changed / deleted rows
  4. POST /api/i18n/clear_pending_detections — clear prior pending rows (body: {detected_version})
  5. POST /api/i18n/cat_*_text        — upload detections (see docs/post-detections.md)

Authentication uses the same cookie session as scripts/i18n_export_zips.py.
Credentials: TRANSLATIONS_API_URL, TRANSLATIONS_API_USER, TRANSLATIONS_API_PASSWORD.

Origin database: ORIGIN_PG_CONN or --origin-conn (default in CI: GW_CONN).
"""

from __future__ import annotations

import argparse
import ast
import hashlib
import json
import logging
import os
import re
import sys
import psycopg2
import psycopg2.extras
from dataclasses import dataclass, field
from enum import Enum
from itertools import product
from pathlib import Path
from typing import Any, Callable, Iterable, Optional

_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from i18n_api_client import (  # noqa: E402
    DEFAULT_CHANGED_PATH,
    DEFAULT_CLEAR_PENDING_PATH,
    DEFAULT_DELETED_PATH,
    DEFAULT_MESSAGES_PATH,
    DEFAULT_NEW_PATH,
    TABLE_EXTRA_COLUMNS,
    catalog_primary_key_columns,
    clear_pending_detections,
    extra_columns_from_row,
    normalize_pk_value,
    primary_keys_from_row,
    TranslationsApiClient,
    fetch_i18n_messages,
    resolve_setting,
    upload_detection_records,
    validate_detection_record,
)


log = logging.getLogger(__name__)

SKIP_FOLDER_NAMES = frozenset({"packages", "resources"})
TRANSLATABLE_JSON_KEYS = frozenset(
    {"label", "tooltip", "placeholder", "text", "comboNames", "vdefault_value"}
)
# Scan JSON blobs for these keys too, but extract inner SQL literals rather than the query.
_JSON_BLOB_SCAN_KEYS = TRANSLATABLE_JSON_KEYS | {"dvQueryText"}
_DVQUERY_KEY = "dvQueryText"
# Prefer SQL-escaped ''text'' (JSON dumps) then 'text' (parsed JSON / DB text).
# Content is [^']+ so ''a'' AS sort_order cannot span into a later AS idval.
_DVQUERY_IDVAL_RE = re.compile(
    r"(?:''([^']+)''|'([^']+)')\s+AS\s+idval\b",
    re.IGNORECASE,
)
# UNION SELECT -999,'ALL VISIBLE SECTORS' — positional idval with no alias.
_DVQUERY_UNION_LITERAL_RE = re.compile(
    r"\bUNION(?:\s+ALL)?\s+SELECT\s+-?\d+\s*,\s*(?:''([^']+)''|'([^']+)')",
    re.IGNORECASE,
)
# Tables whose extra_columns hold a content blob (org_text/text), not identity fields.
_BLOB_CONTENT_TABLES = frozenset({
    "dbstyle", "dbjson", "dbconfig_form_fields_json", "dbconfig_form_fields_query",
})
_SQL_IDENTIFIER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

_FIELDS = ("message", "msg", "title", "inf_text")
_PATTERNS = ("=", " =", "= ", " = ")
_QUOTES = ('"', "'", "(")
_KEYS: tuple[str, ...] = tuple(
    f"{f}{p}{q}" for f, p, q in product(_FIELDS, _PATTERNS, _QUOTES)
)
# "message" must precede "msg" so "message = ..." is not treated as msg.
_FIELD_LINE_RE = re.compile(r"^(message|msg|title|inf_text)\s*=")
_ASSIGN_PREFIX_RE = re.compile(r"^(message|msg|title|inf_text)\s*=\s*")
_FSTRING_LITERAL_RE = re.compile(r'f["\']')
# Prefer triple quotes so """...""" / '''...''' are one segment, not empty "".
_QUOTED_SEGMENTS_RE = re.compile(r'("""|\'\'\'|["\'])(.*?)\1', re.DOTALL)
_TAG_TEXT_RE = re.compile(r">(.*?)<")
_TAG_ACTION_BLOCK_RE = re.compile(r'<action name="([^"]+)">(.*?)</action>', re.DOTALL)
_TAG_PROPERTY_TEXT_RE = re.compile(r'<property name="text">\s*<string>(.*?)</string>', re.DOTALL)
_TAG_BTN_WIDGET_RE = re.compile(
    r'<widget class="QPushButton" name="(btn_[^"]+)">(.*?)</widget>', re.DOTALL
)
_WIDGET_NAME_RE = re.compile(r'name="(.*?)"')
_DBSTYLE_LABEL_RE = re.compile(r'rule.*label="([^"]*)"')


class SourceType(str, Enum):
    PYTHON = "python"
    UI_DIALOG = "ui_dialog"
    DB = "db"


class UpdateKind(str, Enum):
    NEW = "new"
    TEXT_CHANGED = "changed"
    DELETED = "deleted"


@dataclass
class DbLocation:
    """Origin metadata needed to serialize and hash a detection record."""

    table_i18n: str
    table_org: str = ""
    schema_org: str = ""
    project_type: str = ""
    columns: dict[str, Any] = field(default_factory=dict)


@dataclass
class ExtractedString:
    """One PK-level detection (text maps per docs/post-detections.md)."""

    source_type: SourceType
    translation_key: str
    identifier: str
    update_kind: UpdateKind
    db_location: Optional[DbLocation] = None
    text_values: dict[str, str] = field(default_factory=dict)
    old_text_values: dict[str, str] = field(default_factory=dict)
    new_text_values: dict[str, str] = field(default_factory=dict)


@dataclass
class PythonScanStats:
    assignment_lines: int = 0
    extraction_events: int = 0
    duplicate_occurrences: int = 0


@dataclass
class SearcherConfig:
    repo_root: Path
    project_types: list[str]
    origin_schemas: dict[str, str]
    dry_run: bool = False


def _validate_sql_identifier(value: str, kind: str = "identifier") -> str:
    """Reject values that are unsafe to interpolate into SQL identifiers."""
    if not value or not _SQL_IDENTIFIER_RE.fullmatch(value):
        raise ValueError(f"Invalid SQL {kind}: {value!r}")
    return value


# region Table catalog

@dataclass(frozen=True)
class TableColumns:
    """Columns that align one i18n table with an origin table."""

    i18n: tuple[str, ...]
    origin: tuple[str, ...]


_PROJECT_TABLES: dict[str, tuple[tuple[str, ...], tuple[str, ...]]] = {
    "ws": (
        (
            "dbconfig_csv", "dbconfig_param_system", "dbconfig_form_fields",
            "dbconfig_typevalue", "dbfprocess", "dbmessage", "dbparam_user",
            "dbconfig_form_tabs", "dbconfig_report", "dbconfig_toolbox",
            "dbfunction", "dbtypevalue", "dbconfig_form_tableview",
            "dbconfig_visit_parameter", "dbtable", "dbconfig_form_fields_feat",
            "dbbasic_tables", "dblabel", "dbplan_price", "dbstyle", "dbjson",
            "dbconfig_form_fields_json", "dbconfig_form_fields_query",
        ),
        ("su_feature",),
    ),
    "ud": (
        (
            "dbparam_user", "dbconfig_param_system", "dbconfig_form_fields",
            "dbconfig_typevalue", "dbfprocess", "dbmessage", "dbconfig_csv",
            "dbconfig_form_tabs", "dbconfig_report", "dbconfig_toolbox",
            "dbfunction", "dbtypevalue", "dbconfig_form_tableview",
            "dbconfig_visit_parameter", "dbtable", "dbconfig_form_fields_feat",
            "dbbasic_tables", "dblabel", "dbplan_price", "dbstyle", "dbjson",
            "dbconfig_form_fields_json", "dbconfig_form_fields_query",
        ),
        ("su_feature",),
    ),
    "am": (("dbconfig_engine", "dbconfig_form_tableview", "dbbasic_tables"), ()),
    "cm": (
        (
            "dbconfig_form_fields", "dbconfig_form_tabs", "dbconfig_param_system",
            "dbtypevalue", "dbfprocess", "dbtable", "dbconfig_form_tableview",
            "dbconfig_form_fields_json", "dbconfig_form_fields_query",
        ),
        (),
    ),
}

_TABLE_COLUMNS: dict[str, TableColumns] = {
    "dbconfig_form_fields": TableColumns(
        ("formname", "formtype", "tabname", "source", "lb_en_us", "tt_en_us", "pl_en_us"),
        ("formname", "formtype", "tabname", "columnname", "label", "tooltip", "placeholder"),
    ),
    "dbparam_user": TableColumns(("source", "lb_en_us", "tt_en_us"), ("id", "label", "descript")),
    "dbconfig_param_system": TableColumns(
        ("source", "lb_en_us", "tt_en_us"), ("parameter", "label", "descript")
    ),
    "dbconfig_typevalue": TableColumns(("formname", "source", "tt_en_us"), ("typevalue", "id", "idval")),
    "dblabel": TableColumns(("CAST(source AS INTEGER) AS source", "vl_en_us"), ("id", "idval")),
    "dbmessage": TableColumns(
        ("CAST(source AS INTEGER) AS source", "ms_en_us", "ht_en_us"),
        ("id", "error_message", "hint_message"),
    ),
    "dbfprocess": TableColumns(
        ("CAST(source AS INTEGER) AS source", "ex_en_us", "in_en_us", "na_en_us"),
        ("fid", "except_msg", "info_msg", "fprocess_name"),
    ),
    "dbconfig_csv": TableColumns(
        ("CAST(source AS INTEGER) AS source", "al_en_us", "ds_en_us"), ("fid", "alias", "descript")
    ),
    "dbconfig_form_tabs": TableColumns(
        ("formname", "source", "lb_en_us", "tt_en_us"), ("formname", "tabname", "label", "tooltip")
    ),
    "dbconfig_report": TableColumns(
        ("CAST(source AS INTEGER) AS source", "al_en_us", "ds_en_us"), ("id", "alias", "descript")
    ),
    "dbconfig_toolbox": TableColumns(
        ("CAST(source AS INTEGER) AS source", "al_en_us", "ob_en_us"), ("id", "alias", "observ")
    ),
    "dbfunction": TableColumns(("CAST(source AS INTEGER) AS source", "ds_en_us"), ("id", "descript")),
    "dbtypevalue": TableColumns(
        ("typevalue", "source", "vl_en_us", "ds_en_us"), ("typevalue", "id", "idval", "descript")
    ),
    "dbconfig_form_tableview": TableColumns(
        ("columnname", "source", "al_en_us"), ("columnname", "objectname", "alias")
    ),
    "dbtable": TableColumns(("source", "ds_en_us", "al_en_us"), ("id", "descript", "alias")),
    "dbplan_price": TableColumns(
        ("source", "ds_en_us", "tx_en_us", "pr_en_us"), ("id", "descript", "text", "price")
    ),
    "dbconfig_visit_parameter": TableColumns(("source", "ds_en_us"), ("id", "descript")),
    "su_feature": TableColumns(
        ("feature_class", "feature_type", "lb_en_us", "ds_en_us"),
        ("feature_class", "feature_type", "id", "descript"),
    ),
    "dbconfig_engine": TableColumns(
        ("parameter", "method", "lb_en_us", "ds_en_us", "pl_en_us"),
        ("parameter", "method", "label", "descript", "placeholder"),
    ),
    "dbstyle": TableColumns(
        ("source", "layername", "org_text", "hint", "lb_en_us"),
        ("styleconfig_id", "layername", "stylevalue"),
    ),
}
_DEFAULT_TABLE_COLUMNS = TableColumns(("source", "lb_en_us"), ("id", "label"))
_I18N_METADATA_COLUMNS = ("project_type", "source_code", "context")


def tables_dic(schema_type: str) -> tuple[list[str], list[str]]:
    """Return copies of catalogued db/su tables for a project type."""
    dbtables, sutables = _PROJECT_TABLES[schema_type]
    return list(dbtables), list(sutables)


def _iter_project_db_tables(project_type: str) -> list[str]:
    """Tables scanned from origin schemas. ``su_*`` entries stay catalogued but excluded."""
    dbtables, _sutables = tables_dic(project_type)
    return [name for name in dbtables if not name.startswith("su_")]


def _basic_table_columns(table_org: str, project_type: str) -> TableColumns:
    if table_org == "config_param_system":
        return TableColumns(("source", "na_en_us"), ("parameter", "value"))
    if table_org == "value_state" and project_type in ("ud", "ws"):
        return TableColumns(("source", "na_en_us", "ob_en_us"), ("id", "name", "observ"))
    if project_type == "am":
        return TableColumns(("source", "na_en_us"), ("id", "idval"))
    return TableColumns(("source", "na_en_us"), ("id", "name"))


def get_columns_to_compare(table_i18n: str, table_org: str, project_type: str) -> tuple[list[str], list[str]]:
    """Return i18n and origin columns, including common i18n metadata."""
    table_name = table_i18n.split(".")[-1]
    columns = (
        _basic_table_columns(table_org, project_type)
        if table_name == "dbbasic_tables"
        else _TABLE_COLUMNS.get(table_name, _DEFAULT_TABLE_COLUMNS)
    )
    return [*columns.i18n, *_I18N_METADATA_COLUMNS], list(columns.origin)


def _normalize_i18n_columns(columns_i18n: list[str]) -> list[str]:
    result = []
    for col in columns_i18n:
        if "CAST(" in col:
            result.append(col[5:].split(" ")[0])
        else:
            result.append(col)
    return result


_ORIGIN_TABLES: dict[str, tuple[str, ...]] = {
    "dbjson": ("config_report", "config_toolbox"),
    "dbplan_price": ("plan_price",),
    "dbstyle": ("sys_style",),
    "dbconfig_form_fields_json": ("config_form_fields",),
    "dbconfig_form_fields_query": ("config_form_fields",),
    "dbconfig_form_fields_feat": ("config_form_fields",),
    "dbconfig_engine": ("config_engine", "config_engine_def"),
}
_TYPEVALUE_ORIGIN_TABLES: dict[str, tuple[str, ...]] = {
    "am": ("sys_typevalue",),
    "cm": ("sys_typevalue",),
    "ws": ("edit_typevalue", "plan_typevalue", "om_typevalue"),
    "ud": ("edit_typevalue", "plan_typevalue", "om_typevalue"),
}
_SU_ORIGIN_TABLES: dict[str, tuple[str, ...]] = {
    "su_feature": ("cat_feature",),
}
_BASIC_ORIGIN_TABLES: dict[str, tuple[str, ...]] = {
    "ws": ("value_state_type", "value_state", "config_param_system"),
    "ud": ("value_state_type", "value_state", "config_param_system"),
    "am": ("value_result_type", "value_status"),
}
_ORIGIN_QUERY_CONDITIONS: dict[tuple[str, str], str] = {
    ("dbbasic_tables", "config_param_system"): "parameter = 'admin_currency'",
}


def find_table_org(table_i18n: str, project_type: str) -> list[str]:
    table_name = table_i18n.split(".")[-1]
    if table_name == "dbtypevalue":
        return list(_TYPEVALUE_ORIGIN_TABLES.get(project_type, ()))
    if table_name == "dbbasic_tables":
        return list(_BASIC_ORIGIN_TABLES.get(project_type, ()))
    if table_name in _ORIGIN_TABLES:
        return list(_ORIGIN_TABLES[table_name])
    if table_name.startswith("dbconfig"):
        return [table_name[2:]]
    if table_name.startswith("su_"):
        return list(_SU_ORIGIN_TABLES.get(table_name, ()))
    return [f"sys_{table_name[2:]}" if table_name.startswith("db") else table_name]


def find_table_org_with_context(
    i18n_rows: list[dict],
    table_name: str,
    project_type: str,
) -> list[str]:
    tables_org = find_table_org(table_name, project_type)
    if table_name.startswith("su_") or table_name == "dbbasic_tables":
        return tables_org
    seen_contexts = set(tables_org)
    for row in i18n_rows:
        if row.get("project_type") != project_type:
            continue
        context = row.get("context")
        if context and context not in seen_contexts:
            tables_org.append(str(context))
            seen_contexts.add(str(context))
    return tables_org

# endregion


# region Shared scan helpers

def _find_files(
    path: Path,
    file_type: str,
    extra_avoid_list: Optional[Iterable[str]] = None,
) -> list[Path]:
    result: list[Path] = []
    avoid = set(SKIP_FOLDER_NAMES)
    if extra_avoid_list:
        avoid.update(extra_avoid_list)
    for folder, subfolders, files in os.walk(path):
        subfolders[:] = [d for d in subfolders if d not in avoid]
        if Path(folder).name in avoid:
            continue
        for fname in files:
            if fname.endswith(file_type):
                result.append(Path(folder) / fname)
    return sorted(result)


def _read_stripped_lines(file_path: Path) -> Optional[list[str]]:
    try:
        return [line.strip() for line in file_path.read_text(encoding="utf-8").splitlines()]
    except OSError as exc:
        log.warning("Cannot read %s: %s", file_path, exc)
        return None


def _contains_fstring_literal(text: str) -> bool:
    """True when the assignment uses an f-string literal (must not be translated as-is)."""
    return bool(_FSTRING_LITERAL_RE.search(text))


def _parse_field_from_key(key: str) -> str:
    match = _FIELD_LINE_RE.match(key)
    if match:
        return match.group(1)
    for fld in _FIELDS:
        if key.startswith(fld):
            return fld
    return "msg"


def _wrap_assignment_text(field_name: str, text: str) -> str:
    """Wrap extracted text so embedded quotes do not break later parsing."""
    if '"""' in text and "'''" in text:
        escaped = text.replace("\\", "\\\\").replace('"', '\\"')
        return f'{field_name} = "{escaped}"'
    if '"""' in text:
        return f"{field_name} = '''{text}'''"
    return f'{field_name} = """{text}"""'


def _decode_python_string_segment(quote: str, part: str) -> str:
    """Evaluate one quoted Python segment so escapes match runtime.

    ``msg = "Hello\\nWorld"`` must yield a real newline, the same string
    ``tools_qt.tr`` looks up. Raw file text between quotes is not that string.
    """
    try:
        decoded = ast.literal_eval(f"{quote}{part}{quote}")
    except (SyntaxError, ValueError):
        return part
    return decoded if isinstance(decoded, str) else part


def _extract_python_assignment_message(content: str) -> Optional[str]:
    """Extract one whole message from a msg/message/title assignment.

    Keeps embedded newlines as part of the same message (parenthesized
    concatenations and triple-quoted literals). Python escapes such as
    ``\\n`` / ``\\t`` are decoded so the catalog key matches runtime.
    """
    match = _ASSIGN_PREFIX_RE.match(content)
    if not match:
        return None
    rhs = content[match.end():]
    if not rhs:
        return None

    segments = _QUOTED_SEGMENTS_RE.findall(rhs)
    if not segments:
        return None
    return "".join(
        _decode_python_string_segment(quote, part) for quote, part in segments
    )


_FIELD_BY_KEY = {key: _parse_field_from_key(key) for key in _KEYS}


def _msg_multiline_end(
    found_lines: list,
    full_text: str,
    num_line: int,
    field_name: str = "msg",
) -> list:
    if _contains_fstring_literal(full_text):
        return found_lines
    matches = _QUOTED_SEGMENTS_RE.findall(full_text)
    if matches:
        joined = "".join(m[1] for m in matches)
        found_lines.append((num_line, _wrap_assignment_text(field_name, joined)))
    else:
        found_lines.append((num_line, full_text.strip()))
    return found_lines


_TRIPLE_ASSIGN_RE_BY_FIELD = {
    field: re.compile(rf'^{re.escape(field)}\s*=\s*("""|\'\'\')(.*)$')
    for field in _FIELDS
}


def _scan_triple_quoted_assignment(
    stripped_lines: list[str],
    idx: int,
    field_name: str,
) -> Optional[tuple[str, int]]:
    """Scan triple-quoted msg/message/title assignments, including multiline bodies."""
    line = stripped_lines[idx]
    match = _TRIPLE_ASSIGN_RE_BY_FIELD[field_name].match(line)
    if not match:
        return None
    quote, after = match.group(1), match.group(2)
    closer = after.find(quote)
    if closer != -1:
        body = after[:closer]
        return _wrap_assignment_text(field_name, body), idx

    parts = [after]
    pos = idx + 1
    total = len(stripped_lines)
    while pos < total:
        next_line = stripped_lines[pos]
        closer = next_line.find(quote)
        if closer != -1:
            parts.append(next_line[:closer])
            body = "\n".join(parts)
            return _wrap_assignment_text(field_name, body), pos
        parts.append(next_line)
        pos += 1
    return None


def _scan_key(
    stripped_lines: list[str], key: str, candidates: Iterable[int]
) -> list[tuple[int, str]]:
    """Baseline _search_lines scan for one key over pre-read, pre-stripped lines.

    `candidates` holds the indexes of lines that can start a match (lines
    beginning with the key's field name); multiline accumulation still consumes
    every following line, exactly like the baseline sequential scan.
    """
    found_lines: list[tuple[int, str]] = []
    is_paren = "(" in key
    field_name = _parse_field_from_key(key)
    total = len(stripped_lines)
    consumed_until = -1  # last line swallowed by a multiline block

    for idx in candidates:
        if idx <= consumed_until:
            continue
        line = stripped_lines[idx]
        if not line.startswith(key):
            continue
        if _contains_fstring_literal(line):
            continue
        if not is_paren:
            # ``msg = "`` also matches ``msg = """``; handle triple quotes as one message.
            triple = _scan_triple_quoted_assignment(stripped_lines, idx, field_name)
            if triple is not None:
                content, end_idx = triple
                found_lines.append((idx, content))
                if end_idx > idx:
                    consumed_until = end_idx
                continue
            content = line
            pos = idx + 1
            while pos < total:
                next_line = stripped_lines[pos]
                if next_line and next_line[0] in "'\"":
                    content += next_line
                    pos += 1
                else:
                    break
            found_lines.append((idx, content))
            if pos > idx + 1:
                consumed_until = pos - 1
            continue
        if line.endswith(")"):
            found_lines = _msg_multiline_end(found_lines, line, idx, field_name)
            continue
        full_text = line
        pos = idx + 1
        while pos < total:
            full_text += stripped_lines[pos]
            if stripped_lines[pos].endswith(")"):
                found_lines = _msg_multiline_end(found_lines, full_text, pos, field_name)
                break
            pos += 1
        consumed_until = pos

    return found_lines


def _normalize_concatenated_assignment(content: str, field_name: str) -> str:
    """Join adjacent string literals in ``msg = "a" "b"`` style assignments."""
    match = _ASSIGN_PREFIX_RE.match(content)
    if not match:
        return content
    rhs = content[match.end():]
    if rhs.startswith("("):
        return content
    segments = _QUOTED_SEGMENTS_RE.findall(rhs)
    if len(segments) <= 1:
        return content
    joined = "".join(part for _quote, part in segments)
    return _wrap_assignment_text(field_name, joined)


# endregion


# region Python messages (_update_py_messages)

_PYMESSAGE_SOURCE_CODE = "giswater"


def _scan_python_messages(scan_root: Path) -> tuple[dict[str, None], PythonScanStats]:
    """Scan .py files and return unique message strings with scan stats."""
    messages: dict[str, None] = {}
    stats = PythonScanStats()
    scan_root = scan_root.resolve()

    for file_path in _find_files(scan_root, ".py"):
        stripped_lines = _read_stripped_lines(file_path.resolve())
        if stripped_lines is None:
            continue

        candidates: dict[str, list[int]] = {field: [] for field in _FIELDS}
        for idx, line in enumerate(stripped_lines):
            field_match = _FIELD_LINE_RE.match(line)
            if field_match:
                candidates[field_match.group(1)].append(idx)
                stats.assignment_lines += 1

        for key in _KEYS:
            field_candidates = candidates[_FIELD_BY_KEY[key]]
            if not field_candidates:
                continue
            field_name = _FIELD_BY_KEY[key]
            for _num_line, content in _scan_key(stripped_lines, key, field_candidates):
                if _contains_fstring_literal(content):
                    continue
                content = _normalize_concatenated_assignment(content, field_name)
                message = _extract_python_assignment_message(content)
                if message is None:
                    continue
                stats.extraction_events += 1
                if not message.strip():
                    continue
                if message in messages:
                    stats.duplicate_occurrences += 1
                    continue
                messages[message] = None

    return messages, stats


def _pymessage_row(source: str, ms_en_us: str | None = None) -> dict[str, Any]:
    text = ms_en_us if ms_en_us is not None else source
    return {
        "source": source,
        "source_code": _PYMESSAGE_SOURCE_CODE,
        "project_type": "python",
        "context": "pymessage",
        "ms_en_us": text.strip(),
    }


def _columns_from_baseline_pk(
    table_name: str,
    baseline_row: dict[str, Any],
    *,
    text_values: Optional[dict[str, str]] = None,
) -> dict[str, Any]:
    """Copy PK columns from a baseline row as-is (no defaults) for deleted detections."""
    columns: dict[str, Any] = {
        column: baseline_row.get(column, "")
        for column in catalog_primary_key_columns(table_name)
    }
    if text_values:
        for key, value in text_values.items():
            columns[key] = value
    return columns


def _make_finding(
    *,
    source_type: SourceType,
    table_name: str,
    translation_key: str,
    update_kind: UpdateKind,
    columns: dict[str, Any],
    text_values: Optional[dict[str, str]] = None,
    old_text_values: Optional[dict[str, str]] = None,
    new_text_values: Optional[dict[str, str]] = None,
    table_org: str = "",
    schema_org: str = "",
    project_type: str = "",
) -> ExtractedString:
    return ExtractedString(
        source_type=source_type,
        translation_key=translation_key,
        identifier=table_name,
        update_kind=update_kind,
        text_values=dict(text_values or {}),
        old_text_values=dict(old_text_values or {}),
        new_text_values=dict(new_text_values or {}),
        db_location=DbLocation(
            table_i18n=table_name,
            table_org=table_org,
            schema_org=schema_org,
            project_type=project_type,
            columns=columns,
        ),
    )


def _pymessage_finding(
    source: str,
    update_kind: UpdateKind,
    *,
    text_values: dict[str, str] | None = None,
    old_text_values: dict[str, str] | None = None,
    new_text_values: dict[str, str] | None = None,
    baseline_row: Optional[dict[str, Any]] = None,
) -> ExtractedString:
    if update_kind == UpdateKind.DELETED and baseline_row is not None:
        ms_en_us = str(baseline_row.get("ms_en_us", "") or "").strip()
        columns = _columns_from_baseline_pk(
            "pymessage",
            baseline_row,
            text_values={"ms_en_us": ms_en_us},
        )
        # Source is the message key; keep baseline value even when it has leading spaces.
        source = str(baseline_row.get("source", source) or source)
    else:
        ms_en_us = source
        if text_values and "ms_en_us" in text_values:
            ms_en_us = text_values["ms_en_us"]
        elif new_text_values and "ms_en_us" in new_text_values:
            ms_en_us = new_text_values["ms_en_us"]
        columns = _pymessage_row(source, ms_en_us)
    return _make_finding(
        source_type=SourceType.PYTHON,
        table_name="pymessage",
        translation_key=source,
        update_kind=update_kind,
        columns=columns,
        text_values=text_values,
        old_text_values=old_text_values,
        new_text_values=new_text_values,
    )


def _classify_scanned_rows(
    scanned: dict[Any, dict[str, str]],
    baseline_by_key: dict[Any, dict[str, Any]],
    text_columns: tuple[str, ...],
    *,
    include_deleted: Optional[Callable[[Any], bool]] = None,
    treat_empty_baseline_as_new: bool = True,
) -> list[tuple[Any, UpdateKind, dict[str, str], dict[str, str], dict[str, str], Optional[dict[str, Any]]]]:
    """Compare scanned column maps with API baseline rows on primary key."""
    classified: list[
        tuple[Any, UpdateKind, dict[str, str], dict[str, str], dict[str, str], Optional[dict[str, Any]]]
    ] = []

    def _cell(row: dict[str, Any] | None, column: str) -> str:
        if row is None:
            return ""
        return _normalize_cell_value(row.get(column, ""))

    for key, column_map in scanned.items():
        baseline = baseline_by_key.get(key)
        if baseline is None:
            text_values = {
                col: _normalize_cell_value(column_map.get(col, ""))
                for col in text_columns
                if _normalize_cell_value(column_map.get(col, ""))
            }
            if text_values:
                classified.append((key, UpdateKind.NEW, text_values, {}, {}, None))
            continue

        if treat_empty_baseline_as_new and all(not _cell(baseline, col) for col in text_columns):
            text_values = {
                col: _normalize_cell_value(column_map.get(col, ""))
                for col in text_columns
                if _normalize_cell_value(column_map.get(col, ""))
            }
            if text_values:
                classified.append((key, UpdateKind.NEW, text_values, {}, {}, None))
            continue

        old_map: dict[str, str] = {}
        new_map: dict[str, str] = {}
        for col in text_columns:
            if col not in column_map:
                continue
            scanned_val = _normalize_cell_value(column_map.get(col, ""))
            baseline_val = _cell(baseline, col)
            if scanned_val != baseline_val:
                old_map[col] = baseline_val
                new_map[col] = scanned_val
        if old_map:
            classified.append((key, UpdateKind.TEXT_CHANGED, {}, old_map, new_map, baseline))

    for key, baseline in baseline_by_key.items():
        if key in scanned:
            continue
        if include_deleted is not None and not include_deleted(key):
            continue
        text_values = {
            col: _cell(baseline, col)
            for col in text_columns
            if _cell(baseline, col)
        }
        if text_values:
            classified.append((key, UpdateKind.DELETED, text_values, {}, {}, baseline))

    return classified


def extract_py_candidates(
    i18n_rows: list[dict],
    config: SearcherConfig,
) -> list[ExtractedString]:
    """Compare scanned Python sources against the API pymessage baseline."""
    scan_root = config.repo_root
    scanned, stats = _scan_python_messages(scan_root)

    log.info(
        "Py message scan: %d assignment line(s), %d extraction(s), "
        "%d unique string(s) (%d duplicate occurrence(s) collapsed)",
        stats.assignment_lines,
        stats.extraction_events,
        len(scanned),
        stats.duplicate_occurrences,
    )

    baseline_by_pk = _index_baseline_rows(
        _baseline_by_table(i18n_rows, "pymessage"),
        ("source", "source_code"),
    )

    scanned_texts = {
        (source, _PYMESSAGE_SOURCE_CODE): {"ms_en_us": source}
        for source in scanned
    }
    findings: list[ExtractedString] = []
    kind_counts = {UpdateKind.NEW: 0, UpdateKind.TEXT_CHANGED: 0, UpdateKind.DELETED: 0}
    for key, update_kind, text_values, old_map, new_map, baseline in _classify_scanned_rows(
        scanned_texts, baseline_by_pk, ("ms_en_us",)
    ):
        source = key[0] if isinstance(key, tuple) else str(key)
        if not source.strip():
            continue
        kind_counts[update_kind] += 1
        findings.append(
            _pymessage_finding(
                source,
                update_kind,
                text_values=text_values,
                old_text_values=old_map,
                new_text_values=new_map,
                baseline_row=baseline,
            )
        )

    log.info(
        "Py message extraction: %d detection(s) vs baseline "
        "(new=%d, changed=%d, deleted=%d)",
        len(findings),
        kind_counts[UpdateKind.NEW],
        kind_counts[UpdateKind.TEXT_CHANGED],
        kind_counts[UpdateKind.DELETED],
    )

    findings.extend(_extract_pydialog_candidates(i18n_rows, scan_root))

    log.info("Python extraction: %d detection(s)", len(findings))
    return findings

# endregion


# region UI dialogs and toolbars (_update_py_dialogs)

_PYDIALOG_DEFAULT_PROJECT_TYPE = "utils"
# Qt UI encodes a literal "&" as "&&"; XML stores that as "&amp;&amp;". Skip O&M
# labels so amp/&& formatting does not create false pydialog diffs.
_PYDIALOG_IGNORE_TEXTS = frozenset({"O&&M", "O&amp;&amp;M", "O&M", "O&amp;M"})


def _pydialog_project_type(*, baseline_row: Optional[dict[str, Any]] = None) -> str:
    """Prefer baseline project_type; default only when creating rows without a baseline."""
    if baseline_row is not None:
        return str(baseline_row.get("project_type", "") or "").strip()
    return _PYDIALOG_DEFAULT_PROJECT_TYPE


def _pydialog_row(
    actual_source: str,
    dialog_name: str,
    toolbar_name: str,
    *,
    project_type: str = _PYDIALOG_DEFAULT_PROJECT_TYPE,
    lb_en_us: str = "",
    tt_en_us: str = "",
) -> dict[str, Any]:
    row: dict[str, Any] = {
        "source_code": "giswater",
        "project_type": project_type,
        "dialog_name": dialog_name,
        "toolbar_name": toolbar_name,
        "source": actual_source,
        "lb_en_us": lb_en_us,
    }
    if tt_en_us:
        row["tt_en_us"] = tt_en_us
    return row


def _pydialog_finding(
    actual_source: str,
    dialog_name: str,
    toolbar_name: str,
    update_kind: UpdateKind,
    *,
    text_values: dict[str, str] | None = None,
    old_text_values: dict[str, str] | None = None,
    new_text_values: dict[str, str] | None = None,
    baseline_row: Optional[dict[str, Any]] = None,
) -> ExtractedString:
    lb_en_us = ""
    tt_en_us = ""
    if text_values:
        lb_en_us = text_values.get("lb_en_us", "")
        tt_en_us = text_values.get("tt_en_us", "")
    elif new_text_values:
        lb_en_us = new_text_values.get("lb_en_us", "")
        tt_en_us = new_text_values.get("tt_en_us", "")
    elif old_text_values and baseline_row is not None:
        lb_en_us = str(baseline_row.get("lb_en_us", "") or "")
        tt_en_us = str(baseline_row.get("tt_en_us", "") or "")

    if update_kind == UpdateKind.DELETED and baseline_row is not None:
        text_cols = {"lb_en_us": lb_en_us}
        if tt_en_us:
            text_cols["tt_en_us"] = tt_en_us
        columns = _columns_from_baseline_pk(
            "pydialog",
            baseline_row,
            text_values=text_cols,
        )
        project_type = str(baseline_row.get("project_type", "") or "").strip()
        actual_source = str(baseline_row.get("source", actual_source) or actual_source)
    else:
        project_type = _pydialog_project_type(baseline_row=baseline_row)
        if not project_type:
            project_type = _PYDIALOG_DEFAULT_PROJECT_TYPE
        columns = _pydialog_row(
            actual_source,
            dialog_name,
            toolbar_name,
            project_type=project_type,
            lb_en_us=lb_en_us,
            tt_en_us=tt_en_us,
        )
    return _make_finding(
        source_type=SourceType.UI_DIALOG,
        table_name="pydialog",
        translation_key=actual_source,
        update_kind=update_kind,
        project_type=project_type,
        columns=columns,
        text_values=text_values,
        old_text_values=old_text_values,
        new_text_values=new_text_values,
    )


def _baseline_by_table(
    i18n_rows: list[dict],
    table_name: str,
) -> list[dict[str, Any]]:
    return [row for row in i18n_rows if row.get("table_name") == table_name]


def _index_baseline_rows(
    rows: list[dict[str, Any]],
    key_fields: tuple[str, ...],
) -> dict[Any, dict[str, Any]]:
    indexed: dict[Any, dict[str, Any]] = {}
    for row in rows:
        if len(key_fields) == 1:
            key: Any = str(row.get(key_fields[0], "") or "")
            if not str(key).strip():
                continue
        else:
            key = tuple(str(row.get(field, "") or "") for field in key_fields)
            if not key[0]:
                continue
        indexed[key] = row
    return indexed


def _index_widget_context(raw_lines: list[str]) -> list[int]:
    """For each line, index of the nearest preceding named UI object.

    Both ``<widget`` and ``<action name=`` are sources. QAction strings are
    catalogued only from ``toolTip`` (tt_en_us); labels are ignored.
    """
    context: list[int] = []
    named_line = -1
    for line in raw_lines:
        if "<widget" in line:
            named_line = len(context)
        if "<action name=" in line:
            named_line = len(context)
        context.append(named_line)
    return context


def _named_object_is_action(raw_lines: list[str], named_line: int) -> bool:
    return named_line >= 0 and '<action name=' in raw_lines[named_line]


def _search_dialog_info(
    file_path: Path,
    raw_lines: list[str],
    widget_context: list[int],
    num_line: int,
) -> tuple[str, str, str]:
    toolbar_name = file_path.parent.name
    dialog_name = file_path.stem

    named_line = widget_context[num_line]
    if named_line < 0:
        return dialog_name, toolbar_name, ""

    match = _WIDGET_NAME_RE.search(raw_lines[named_line])
    source = match.group(1) if match else ""
    return dialog_name, toolbar_name, source


def _scan_ui_dialogs(
    scan_root: Path,
) -> dict[tuple[str, str, str], dict[str, str]]:
    processed: dict[tuple[str, str, str], dict[str, str]] = {}
    scan_root = scan_root.resolve()

    def _entry(key: tuple[str, str, str]) -> dict[str, str]:
        return processed.setdefault(key, {})

    for file_path in _find_files(scan_root, ".ui"):
        file_path = file_path.resolve()
        try:
            raw_lines = file_path.read_text(encoding="utf-8").splitlines(keepends=True)
        except OSError as exc:
            log.warning("Cannot read %s: %s", file_path, exc)
            continue

        widget_context = _index_widget_context(raw_lines)
        in_tooltip_property = False
        for num_line, raw_line in enumerate(raw_lines):
            content = raw_line.strip()
            if content.startswith('<property name="toolTip"'):
                in_tooltip_property = True
                continue
            if in_tooltip_property and content.startswith("</property>"):
                in_tooltip_property = False
                continue
            if not content.startswith("<string>"):
                continue
            dialog_name, toolbar_name, source = _search_dialog_info(
                file_path, raw_lines, widget_context, num_line
            )
            match = _TAG_TEXT_RE.search(content)
            if not match:
                continue
            message_text = match.group(1).strip()
            if message_text in _PYDIALOG_IGNORE_TEXTS:
                continue
            if _named_object_is_action(raw_lines, widget_context[num_line]) and (
                not in_tooltip_property
            ):
                continue
            column = "tt_en_us" if in_tooltip_property else "lb_en_us"
            if not message_text and column == "lb_en_us":
                continue
            if source.startswith("dlg_") or source == dialog_name:
                actual_source = f"dlg_{dialog_name}"
            else:
                actual_source = str(source).strip()
            if not actual_source:
                continue
            _entry((actual_source, dialog_name, toolbar_name))[column] = message_text

    _entry(("btn_help", "common", "common"))["lb_en_us"] = "Help"
    return processed


def _extract_pydialog_candidates(
    i18n_rows: list[dict],
    scan_root: Path,
) -> list[ExtractedString]:
    scanned = _scan_ui_dialogs(scan_root.joinpath("core", "ui"))
    baseline_by_key = _index_baseline_rows(
        _baseline_by_table(i18n_rows, "pydialog"),
        ("source", "dialog_name", "toolbar_name"),
    )

    findings: list[ExtractedString] = []
    for key, update_kind, text_values, old_map, new_map, baseline in _classify_scanned_rows(
        scanned,
        baseline_by_key,
        ("lb_en_us", "tt_en_us"),
        include_deleted=lambda dialog_key: dialog_key[0] != "dlg_admin",
    ):
        ignored_texts = (
            set(text_values.values()) | set(old_map.values()) | set(new_map.values())
        ) & _PYDIALOG_IGNORE_TEXTS
        if ignored_texts:
            continue
        actual_source, dialog_name, toolbar_name = key
        findings.append(
            _pydialog_finding(
                actual_source,
                dialog_name,
                toolbar_name,
                update_kind,
                text_values=text_values,
                old_text_values=old_map,
                new_text_values=new_map,
                baseline_row=baseline,
            )
        )

    log.info("UI dialog extraction: %d detection(s)", len(findings))
    return findings


# region Origin PostgreSQL

class OriginDb:
    def __init__(self, conninfo: str) -> None:
        try:
            self._conn = psycopg2.connect(conninfo)
        except psycopg2.Error as exc:
            raise RuntimeError(f"Failed to connect to origin database: {exc.__class__.__name__}") from None
        self._conn.autocommit = True

    def close(self) -> None:
        self._conn.close()

    def fetch_all(self, sql: str, params: Optional[tuple[Any, ...]] = None) -> list[dict[str, Any]]:
        try:
            with self._conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute(sql, params)
                return [dict(row) for row in cur.fetchall()]
        except psycopg2.Error as exc:
            raise RuntimeError(f"Origin database query failed: {exc.__class__.__name__}: {exc}") from None

    def table_exists(self, schema: str, table: str) -> bool:
        schema = _validate_sql_identifier(schema, "schema")
        table = _validate_sql_identifier(table, "table")
        rows = self.fetch_all(
            "SELECT EXISTS ("
            "  SELECT 1 FROM information_schema.tables "
            "  WHERE table_schema = %s AND table_name = %s"
            ") AS exists",
            (schema, table),
        )
        return bool(rows and rows[0].get("exists"))

    def schema_exists(self, schema: str) -> bool:
        schema = _validate_sql_identifier(schema, "schema")
        rows = self.fetch_all(
            "SELECT EXISTS ("
            "  SELECT 1 FROM information_schema.schemata "
            "  WHERE schema_name = %s"
            ") AS exists",
            (schema,),
        )
        return bool(rows and rows[0].get("exists"))

    def verify_lang(self, schema: str) -> bool:
        schema = _validate_sql_identifier(schema, "schema")
        if not self.table_exists(schema, "sys_version"):
            return False
        rows = self.fetch_all(
            f"SELECT language FROM {schema}.sys_version ORDER BY id DESC LIMIT 1"
        )
        if not rows:
            return False
        lang = str(rows[0].get("language", "")).lower()
        return lang in ("no_tr",)

    def schema_version(self, schema: str) -> str:
        schema = _validate_sql_identifier(schema, "schema")
        if not self.table_exists(schema, "sys_version"):
            return ""
        rows = self.fetch_all(
            f"SELECT giswater FROM {schema}.sys_version ORDER BY id DESC LIMIT 1"
        )
        if not rows:
            return ""
        return str(rows[0].get("giswater", "") or "")

# endregion


# region Row comparison helpers

def _normalize_cell_value(value: Any) -> str:
    """Normalize PK / metadata scalars. Does not reinterpret JSON text."""
    return normalize_pk_value(value)


def _canonicalize_jsonish(value: Any) -> str | None:
    """Return canonical JSON text for arrays/objects; None when not JSON-shaped.

    ``config_typevalue.idval`` / ``tt_en_us`` values are JSON arrays that often
    share leading tokens (``["OM", "ANALYTICS"]`` vs ``[..., "INPUT"]``). Plain
    ``str(list)`` (Python single quotes) or mixed JSON spacing makes equal arrays
    look different and floods changed detections. Canonical JSON keeps exact
    full-value equality stable; row identity stays on catalog PK (formname+source).
    """
    if isinstance(value, (list, dict)):
        return json.dumps(value, ensure_ascii=False)
    if not isinstance(value, str):
        return None
    text = value.strip()
    if len(text) < 2 or text[0] not in "[{":
        return None
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError:
        # Origin/API may still carry a Python list/dict repr from older runs.
        if not ((text.startswith("[") and text.endswith("]")) or (
            text.startswith("{") and text.endswith("}")
        )):
            return None
        try:
            parsed = ast.literal_eval(text)
        except (SyntaxError, ValueError):
            return None
    if isinstance(parsed, (list, dict)):
        return json.dumps(parsed, ensure_ascii=False)
    return None


def _normalize_compare_value(value: Any, column: str) -> str:
    """Normalize one cell for row diffs: JSON-canonicalize ``*_en_us`` text."""
    if "en_us" in column:
        canonical = _canonicalize_jsonish(value)
        if canonical is not None:
            return canonical
    return _normalize_cell_value(value)


def _normalize_blob_compare_value(value: Any) -> str:
    """Blob equality that ignores JSON pretty-printing (newlines, tabs, spacing).

    ``config_report.filterparam`` and friends are stored with arbitrary
    indentation, so byte equality floods changed detections for blobs whose
    content is identical. Non-JSON blobs (dbstyle QML) keep exact text.
    """
    if isinstance(value, (list, dict)):
        parsed: Any = value
    else:
        text = _normalize_cell_value(value).replace("\r\n", "\n").replace("\r", "\n")
        if len(text) < 2 or text[0] not in "[{":
            return text
        try:
            parsed = json.loads(text)
        except json.JSONDecodeError:
            return text
    return json.dumps(sort_keys_deep(parsed), separators=(",", ":"), ensure_ascii=False)


def _dict_to_values_tuple(d: dict, keys: list[str]) -> tuple:
    return tuple(_normalize_compare_value(d.get(k, ""), k) for k in keys)


def _pk_tuple(row: dict, pk_keys: list[str]) -> tuple:
    """PK identity only (never text). Overlapping idval/tt strings cannot collide."""
    return tuple(_normalize_cell_value(row.get(k, "")) for k in pk_keys)


def _pk_columns(keys: list[str]) -> list[str]:
    return [k for k in keys if "en_us" not in k]


def _row_compare_columns(table_name: str, columns_i18n: list[str]) -> list[str]:
    """Compare PK + *_en_us only for blob tables so extra_columns do not affect diff."""
    if table_name not in TABLE_EXTRA_COLUMNS:
        return columns_i18n
    pk_cols = list(catalog_primary_key_columns(table_name))
    en_us_cols = [col for col in columns_i18n if "en_us" in col]
    seen: set[str] = set()
    compare: list[str] = []
    for col in pk_cols + en_us_cols:
        if col not in seen:
            seen.add(col)
            compare.append(col)
    return compare


def _set_diff_rows(rows_a: list[dict], rows_b: list[dict], keys: list[str]) -> list[dict]:
    set_b = {_dict_to_values_tuple(r, keys) for r in rows_b}
    set_a = {_dict_to_values_tuple(r, keys) for r in rows_a}
    diff_tuples = set_a - set_b
    return [r for r in rows_a if _dict_to_values_tuple(r, keys) in diff_tuples]


def _classify_diff_rows(
    rows_org: list[dict],
    rows_i18n: list[dict],
    keys: list[str],
    *,
    table_name: str = "",
) -> list[tuple[dict, UpdateKind, Optional[dict]]]:
    # Always index by catalog PK (e.g. formname+source for dbconfig_typevalue),
    # never by idval/tt text — overlapping JSON arrays must not share identity.
    pk_keys = (
        list(catalog_primary_key_columns(table_name))
        if table_name
        else _pk_columns(keys)
    )
    i18n_by_pk = {_pk_tuple(row, pk_keys): row for row in rows_i18n}
    classified: list[tuple[dict, UpdateKind, Optional[dict]]] = []
    for row in _set_diff_rows(rows_org, rows_i18n, keys):
        previous = i18n_by_pk.get(_pk_tuple(row, pk_keys))
        if previous is not None:
            classified.append((row, UpdateKind.TEXT_CHANGED, previous))
        else:
            classified.append((row, UpdateKind.NEW, None))
    return classified


def _classify_deleted_rows(
    rows_org: list[dict],
    rows_i18n: list[dict],
    keys: list[str],
    *,
    table_name: str = "",
) -> list[dict]:
    """Rows in i18n baseline whose PK no longer exists in aligned org rows."""
    pk_keys = (
        list(catalog_primary_key_columns(table_name))
        if table_name
        else _pk_columns(keys)
    )
    org_pks = {_pk_tuple(row, pk_keys) for row in rows_org}
    classified: list[dict] = []
    for row in rows_i18n:
        if _pk_tuple(row, pk_keys) not in org_pks:
            classified.append(row)
    return classified


def _org_i18n_column_pairs(columns_org: list[str], columns_i18n: list[str]) -> list[tuple[str, str]]:
    compare_i18n = _normalize_i18n_columns(columns_i18n[: max(0, len(columns_i18n) - 3)])
    pairs: list[tuple[str, str]] = []
    for i, org_col in enumerate(columns_org):
        if i >= len(compare_i18n):
            break
        i18n_col = compare_i18n[i]
        if i18n_col not in ("project_type", "source_code", "context"):
            pairs.append((i18n_col, org_col))
    return pairs


def _clean_rows_org(rows_org: list[dict], columns_org: list[str], project_type: str, table_org: str) -> list[dict]:
    cleaned = []
    extra = {"project_type": project_type, "source_code": "giswater", "context": table_org}
    all_cols = set(columns_org) | set(extra)
    for row in rows_org:
        clean_row = dict(row)
        clean_row.update(extra)
        for col in all_cols:
            val = clean_row.get(col, "")
            if val is None:
                clean_row[col] = ""
            if project_type == "cm" and col == "id" and table_org == "sys_table":
                parts = str(val).split("_")
                if len(parts) >= 2:
                    clean_row[col] = parts[-2] + "_" + parts[-1]
        cleaned.append(clean_row)
    return cleaned


def _flatten_baseline_extra_columns(row: dict[str, Any], table_name: str) -> dict[str, Any]:
    """Lift GET-baseline extra_columns (e.g. org_text/text) onto the row for diffs."""
    declared = TABLE_EXTRA_COLUMNS.get(table_name, ())
    if not declared:
        return row
    extra = row.get("extra_columns")
    if not isinstance(extra, dict):
        return row
    flat = dict(row)
    for column in declared:
        if flat.get(column) in (None, "") and column in extra:
            flat[column] = extra[column]
    return flat


def _clean_rows_i18n(rows_i18n: list[dict], columns_i18n: list[str], project_type: str, table_i18n: str) -> list[dict]:
    cleaned = []
    table_name = table_i18n.split(".")[-1]
    for row in rows_i18n:
        clean_row = _flatten_baseline_extra_columns(dict(row), table_name)
        for col in columns_i18n:
            val = clean_row.get(col, "")
            if val is None:
                clean_row[col] = ""
            if project_type == "cm" and col == "source" and "dbtable" in table_i18n:
                parts = str(val).split("_")
                if len(parts) >= 2:
                    clean_row[col] = parts[-2] + "_" + parts[-1]
        cleaned.append(clean_row)
    return cleaned


def _align_org_rows(
    rows_org: list[dict],
    columns_org: list[str],
    columns_i18n: list[str],
    project_type: str,
    table_org: str,
) -> list[dict]:
    pairs = _org_i18n_column_pairs(columns_org, columns_i18n)
    aligned_org: list[dict] = []
    for row in rows_org:
        aligned: dict[str, Any] = {
            i18n_col: row.get(org_col, "") for i18n_col, org_col in pairs
        }
        aligned["project_type"] = row.get("project_type", project_type)
        aligned["source_code"] = row.get("source_code", "giswater")
        aligned["context"] = row.get("context", table_org)
        aligned_org.append(aligned)
    return aligned_org


def _en_us_text_map(row: dict[str, Any], en_us_columns: list[str], *, require_nonempty: bool) -> dict[str, str]:
    return {
        col: _normalize_compare_value(row.get(col, ""), col)
        for col in en_us_columns
        if not require_nonempty or _normalize_compare_value(row.get(col, ""), col)
    }


def _blob_content_column(table_name: str) -> Optional[str]:
    """Return org_text/text for blob content tables; None otherwise."""
    if table_name not in _BLOB_CONTENT_TABLES:
        return None
    declared = TABLE_EXTRA_COLUMNS.get(table_name, ())
    return declared[0] if declared else None


def _findings_from_db_row(
    row: dict,
    table_name: str,
    table_org: str,
    schema_org: str,
    project_type: str,
    columns_i18n: list[str],
    *,
    update_kind: UpdateKind = UpdateKind.NEW,
    previous_row: Optional[dict] = None,
) -> list[ExtractedString]:
    """Build one PK-level detection with text JSON maps (docs/post-detections.md)."""
    en_us_columns = [c for c in columns_i18n if "en_us" in c]
    translation_key = str(primary_keys_from_row(table_name, row).get("source", ""))
    # Deleted detections must keep the baseline PK (including project_type / source_code).
    row_project_type = str(row.get("project_type") or "").strip()
    if update_kind == UpdateKind.DELETED:
        finding_project_type = row_project_type or project_type
    else:
        finding_project_type = project_type or row_project_type

    def _finding(
        kind: UpdateKind,
        *,
        text_values: Optional[dict[str, str]] = None,
        old_text_values: Optional[dict[str, str]] = None,
        new_text_values: Optional[dict[str, str]] = None,
    ) -> ExtractedString:
        return _make_finding(
            source_type=SourceType.DB,
            table_name=table_name,
            translation_key=translation_key,
            update_kind=kind,
            table_org=table_org,
            schema_org=schema_org,
            project_type=finding_project_type,
            columns=dict(row),
            text_values=text_values,
            old_text_values=old_text_values,
            new_text_values=new_text_values,
        )

    if update_kind == UpdateKind.TEXT_CHANGED:
        if previous_row is None:
            return []
        old_map: dict[str, str] = {}
        new_map: dict[str, str] = {}
        for col in en_us_columns:
            new_val = _normalize_compare_value(row.get(col, ""), col)
            old_val = _normalize_compare_value(previous_row.get(col, ""), col)
            if new_val != old_val:
                old_map[col] = old_val
                new_map[col] = new_val
        if old_map:
            return [_finding(UpdateKind.TEXT_CHANGED, old_text_values=old_map, new_text_values=new_map)]
        # Same PK + labels: emit only when the content blob drifted.
        blob_col = _blob_content_column(table_name)
        if not blob_col:
            return []
        schema_blob = _normalize_blob_compare_value(row.get(blob_col, ""))
        baseline_blob = _normalize_blob_compare_value(previous_row.get(blob_col, ""))
        # An absent baseline blob means the API did not expose the column, which
        # is not evidence of drift; syncing on it would flag every row.
        if not schema_blob or not baseline_blob or schema_blob == baseline_blob:
            return []
        text_values = _en_us_text_map(row, en_us_columns, require_nonempty=True)
        if not text_values:
            return []
        return [_finding(
            UpdateKind.TEXT_CHANGED,
            old_text_values=dict(text_values),
            new_text_values=dict(text_values),
        )]

    text_values = _en_us_text_map(row, en_us_columns, require_nonempty=True)
    if not text_values:
        return []
    return [_finding(update_kind, text_values=text_values)]


def _compare_db_rows(
    expected_rows: list[dict],
    baseline_rows: list[dict],
    columns_i18n: list[str],
    *,
    table_name: str,
    table_org: str,
    schema_org: str,
    project_type: str,
) -> list[ExtractedString]:
    """Classify aligned rows and emit findings for all three update kinds.

    For blob content tables, a second pass emits ``changed`` when PK and labels
    match but org_text/text drifted from the schema.
    """
    compare_keys = _row_compare_columns(table_name, columns_i18n)
    pk_keys = list(catalog_primary_key_columns(table_name))
    i18n_by_pk = {_pk_tuple(row, pk_keys): row for row in baseline_rows}
    findings: list[ExtractedString] = []
    classified_pks: set[tuple] = set()

    for row, update_kind, previous_row in _classify_diff_rows(
        expected_rows, baseline_rows, compare_keys, table_name=table_name
    ):
        classified_pks.add(_pk_tuple(row, pk_keys))
        findings.extend(
            _findings_from_db_row(
                row,
                table_name,
                table_org,
                schema_org,
                project_type,
                columns_i18n,
                update_kind=update_kind,
                previous_row=previous_row,
            )
        )
    for row in _classify_deleted_rows(
        expected_rows, baseline_rows, compare_keys, table_name=table_name
    ):
        classified_pks.add(_pk_tuple(row, pk_keys))
        findings.extend(
            _findings_from_db_row(
                row,
                table_name,
                table_org,
                schema_org,
                project_type,
                columns_i18n,
                update_kind=UpdateKind.DELETED,
            )
        )

    # Same PK + labels (not in set-diff): still sync drifted content blobs.
    blob_col = _blob_content_column(table_name)
    if blob_col:
        blob_findings: list[ExtractedString] = []
        for row in expected_rows:
            pk = _pk_tuple(row, pk_keys)
            if pk in classified_pks:
                continue
            previous = i18n_by_pk.get(pk)
            if previous is None:
                continue
            blob_findings.extend(
                _findings_from_db_row(
                    row,
                    table_name,
                    table_org,
                    schema_org,
                    project_type,
                    columns_i18n,
                    update_kind=UpdateKind.TEXT_CHANGED,
                    previous_row=previous,
                )
            )
        if blob_findings:
            log.info(
                "%s/%s: %d detection(s) from %s drift only",
                table_name, table_org, len(blob_findings), blob_col,
            )
        findings.extend(blob_findings)

    return findings

# endregion


# region Detection records and upload

def sort_keys_deep(value: object) -> object:
    if value is None or not isinstance(value, (dict, list)):
        return value
    if isinstance(value, list):
        return [sort_keys_deep(item) for item in value]
    return {
        key: sort_keys_deep(value[key])  # type: ignore[index]
        for key in sorted(value.keys())  # type: ignore[union-attr]
    }


_PY_TABLES = frozenset({"pymessage", "pydialog", "pytoolbar"})
# Internal-only columns on py* rows; omitted from POST body per docs/post-detections.md.
_PY_POST_OMIT_COLUMNS = frozenset({"context", "project_type", "table_org", "schema_org"})


def _py_post_fields(table_name: str, loc: DbLocation) -> dict[str, str]:
    """Extra top-level POST fields for py* tables (docs/post-detections.md)."""
    if table_name == "pydialog":
        project_type = str(loc.project_type or loc.columns.get("project_type", "") or "").strip()
        return {"project_type": project_type}
    return {}


def _include_pk_field(table_name: str, column: str) -> bool:
    return not (table_name in _PY_TABLES and column in _PY_POST_OMIT_COLUMNS)


def _kind_for_hash(kind: UpdateKind) -> str:
    if kind == UpdateKind.TEXT_CHANGED:
        return "changed"
    if kind == UpdateKind.DELETED:
        return "deleted"
    return "new"


def compute_detection_key(
    loc: DbLocation,
    kind: UpdateKind,
    normalized_primary_keys: dict[str, Any],
    detected_version: str,
) -> str:
    payload: dict[str, Any] = {
        "table_name": loc.table_i18n,
        "primary_keys": dict(sorted(normalized_primary_keys.items())),
        "kind": _kind_for_hash(kind),
        "detected_version": detected_version,
    }
    if loc.table_i18n == "pydialog":
        post_fields = _py_post_fields(loc.table_i18n, loc)
        payload["project_type"] = post_fields["project_type"]
    elif loc.table_i18n not in _PY_TABLES:
        payload["table_org"] = loc.table_org
        payload["schema_org"] = loc.schema_org
        payload["project_type"] = loc.project_type
    payload = sort_keys_deep(payload)
    serialized = json.dumps(payload, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(serialized.encode("utf-8")).hexdigest()


def finding_to_record(finding: ExtractedString, detected_version: str) -> dict[str, Any]:
    if finding.db_location is None:
        raise ValueError("DB finding missing db_location")
    loc = finding.db_location
    normalized_primary_keys = primary_keys_from_row(loc.table_i18n, loc.columns)
    detection_key = compute_detection_key(loc, finding.update_kind, normalized_primary_keys, detected_version)
    kind = _kind_for_hash(finding.update_kind)
    # Prefer PK source_code from the found row; only default for non-deleted when missing.
    source_code = normalized_primary_keys.get("source_code", "")
    if not source_code and finding.update_kind != UpdateKind.DELETED:
        source_code = "giswater"
    record: dict[str, Any] = {
        "detection_key": detection_key,
        "table_name": loc.table_i18n,
        "source_code": source_code,
        "detected_version": detected_version,
    }
    if loc.table_i18n in _PY_TABLES:
        record.update(_py_post_fields(loc.table_i18n, loc))
    else:
        record["table_org"] = loc.table_org
        record["schema_org"] = loc.schema_org
        record["project_type"] = loc.project_type or _normalize_cell_value(
            loc.columns.get("project_type", "")
        )
        record["context"] = _normalize_cell_value(loc.columns.get("context", loc.table_org))

    for key, value in normalized_primary_keys.items():
        if _include_pk_field(loc.table_i18n, key):
            record[key] = value

    record["extra_columns"] = extra_columns_from_row(loc.table_i18n, loc.columns, kind=kind)

    if finding.update_kind == UpdateKind.TEXT_CHANGED:
        record["old_text_values"] = dict(finding.old_text_values)
        record["new_text_values"] = dict(finding.new_text_values)
    else:
        record["text_values"] = dict(finding.text_values)

    validate_detection_record(record, kind=kind)
    return record


def _finding_has_payload(finding: ExtractedString) -> bool:
    if finding.update_kind == UpdateKind.TEXT_CHANGED:
        return bool(finding.old_text_values) and bool(finding.new_text_values)
    return bool(finding.text_values)


def group_records(findings: list[ExtractedString], detected_version: str) -> dict[str, list[dict[str, Any]]]:
    grouped: dict[str, list[dict[str, Any]]] = {"changed": [], "deleted": [], "new": []}
    kind_bucket = {
        UpdateKind.TEXT_CHANGED: "changed",
        UpdateKind.DELETED: "deleted",
        UpdateKind.NEW: "new",
    }
    for finding in findings:
        if finding.db_location is None or not _finding_has_payload(finding):
            continue
        bucket = kind_bucket.get(finding.update_kind)
        if bucket is None:
            continue
        grouped[bucket].append(finding_to_record(finding, detected_version))
    return grouped

# endregion


# region JSON / feat / dbstyle extractors

def _unescape_sql_string(text: str) -> str:
    """Turn SQL-escaped quotes (''text'') into a plain catalog string."""
    return text.replace("''", "'")


def _extract_dvquery_idval_texts(query: str) -> list[str]:
    """User-facing combo labels embedded as string literals in dvQueryText SQL.

    Matches ``'User selected expl' AS idval`` and positional
    ``UNION SELECT -999,'ALL VISIBLE SECTORS'``. Skips sort_order, WHERE
    predicates, and column aliases such as ``name AS idval``.
    """
    found: list[str] = []
    seen: set[str] = set()

    def _add(raw: str | None) -> None:
        if not raw:
            return
        text = _unescape_sql_string(raw).strip()
        if not text or text in seen:
            return
        seen.add(text)
        found.append(text)

    for match in _DVQUERY_IDVAL_RE.finditer(query):
        _add(match.group(1) or match.group(2))
    for match in _DVQUERY_UNION_LITERAL_RE.finditer(query):
        _add(match.group(1) or match.group(2))
    return found


def _extract_translatable_strings(data: Any) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []

    def recurse(item: Any) -> None:
        if isinstance(item, dict):
            entry: dict[str, Any] = {}
            for key, value in item.items():
                if key.lower() == _DVQUERY_KEY.lower() and isinstance(value, str):
                    texts = _extract_dvquery_idval_texts(value)
                    if texts:
                        entry[_DVQUERY_KEY] = texts
                elif key in TRANSLATABLE_JSON_KEYS:
                    if key == "comboNames" and isinstance(value, list):
                        entry[key] = value
                    elif isinstance(value, str):
                        entry[key] = value
                recurse(value)
            if entry:
                results.append(entry)
        elif isinstance(item, list):
            for sub in item:
                recurse(sub)

    recurse(data)
    return results


def _json_column_for_table_org(table_org: str) -> str:
    if table_org == "config_report":
        return "filterparam"
    if table_org == "config_toolbox":
        return "inputparams"
    if table_org == "config_form_fields":
        return "widgetcontrols"
    return ""


_FEAT_FORM_RULES: tuple[tuple[str, str], ...] = (
    ("ARC", "ve_arc"),
    ("NODE", "ve_node"),
    ("CONNEC", "ve_connec"),
    ("GULLY", "ve_gully"),
    ("ELEMENT", "ve_element"),
    ("LINK", "ve_link"),
    ("FLWREG", "ve_flwreg"),
)


def _form_fields_feat_exclude_condition(column_prefix: str = "", negation: bool = True) -> str:
    prefix = f"{column_prefix}." if column_prefix else ""
    form_conditions = " OR ".join(
        f"({prefix}formname LIKE '{form_prefix}%%' OR {prefix}formname = '{form_prefix}')"
        for _, form_prefix in _FEAT_FORM_RULES
    )
    if negation:
        return f"NOT ({prefix}formtype = 'form_feature' AND ({form_conditions}))"
    else:
        return f"({prefix}formtype = 'form_feature' AND ({form_conditions}))"


def _append_sql_condition(query: str, condition: str) -> str:
    if " WHERE " in query.upper():
        return f"{query} AND {condition}"
    return f"{query} WHERE {condition}"


def _get_dbstyle_rows(rows_org: list[dict]) -> list[dict]:
    result = []
    for row in rows_org:
        stylevalue = row.get("stylevalue", "") or ""
        i = 1
        for line in stylevalue.split("\n"):
            m = _DBSTYLE_LABEL_RE.search(line)
            if m:
                new_row = dict(row)
                new_row["hint"] = f"label_{i}"
                new_row["lb_en_us"] = m.group(1)
                new_row["org_text"] = stylevalue
                i += 1
                result.append(new_row)
    return result


def _filter_i18n_rows(
    all_rows: list[dict],
    table_name: str,
    project_type: str,
) -> list[dict]:
    return [
        row for row in all_rows
        if row.get("table_name", row.get("table_i18n", "")) in ("", table_name)
        and (not row.get("project_type") or row.get("project_type") == project_type)
    ]


def _filter_i18n_rows_by_context(rows: list[dict], table_org: str) -> list[dict]:
    """Keep baseline rows that belong to the current origin table (e.g. edit_typevalue)."""
    return [row for row in rows if str(row.get("context", "")) == table_org]


def _normalize_json_text(text: str) -> str:
    """Flatten JSON formatting newlines before sending a translatable value."""
    return re.sub(r"[ \t]*[\r\n]+[ \t]*", " ", text).strip()


def _parse_json_payload(text_blob: str) -> Any:
    """Parse a JSON column text blob for label extraction; None if invalid."""
    if text_blob in ("", "None"):
        return None
    try:
        return json.loads(text_blob)
    except (json.JSONDecodeError, TypeError):
        return None


def _extract_json_table(
    origin: OriginDb,
    i18n_rows: list[dict],
    table_name: str,
    table_org: str,
    schema_org: str,
    project_type: str,
) -> list[ExtractedString]:
    column = _json_column_for_table_org(table_org)
    if not column:
        return []

    is_form_fields = table_name == "dbconfig_form_fields_json"
    if is_form_fields:
        pk_column_org = ["formname", "formtype", "tabname", "columnname"]
        columns_i18n = [
            "source_code", "project_type", "context", "formname", "formtype",
            "tabname", "source", "hint", "lb_en_us", "text",
        ]
    else:
        pk_column_org = ["id"]
        columns_i18n = [
            "source_code", "project_type", "context", "hint", "source", "lb_en_us", "text",
        ]

    where_conditions = [
        f"""{column}::text ILIKE '%%{key}":%%'""" for key in _JSON_BLOB_SCAN_KEYS
    ]
    where_clause = " OR ".join(where_conditions)
    # Fetch literal DB text so extra_columns.text matches the schema exactly.
    query_org = (
        f"SELECT {', '.join(pk_column_org)}, {column}::text AS text_raw "
        f"FROM {schema_org}.{table_org} WHERE {where_clause}"
    )
    rows_org = origin.fetch_all(query_org)

    rows_i18n = _filter_i18n_rows_by_context(
        _clean_rows_i18n(
            _filter_i18n_rows(i18n_rows, table_name, project_type),
            columns_i18n,
            project_type,
            table_name,
        ),
        table_org,
    )

    expected: list[dict] = []
    for row in rows_org:
        text_blob = row.get("text_raw")
        if text_blob in (None, "", "None"):
            continue
        text_blob = str(text_blob)
        payload = _parse_json_payload(text_blob)
        if payload is None:
            continue
        datas = _extract_translatable_strings(payload)
        for i, data in enumerate(datas):
            for key, text in data.items():
                values: list[tuple[str, str]] = []
                if key == _DVQUERY_KEY and isinstance(text, list):
                    for j, item in enumerate(text):
                        text_val = _normalize_json_text(str(item)).strip()
                        if text_val:
                            values.append((f"{key}_{i}_{j}", text_val))
                elif isinstance(text, list):
                    text_val = ", ".join(_normalize_json_text(str(t)) for t in text).strip()
                    if text_val:
                        values.append((f"{key}_{i}", text_val))
                elif isinstance(text, str):
                    text_val = _normalize_json_text(text)
                    if text_val:
                        values.append((f"{key}_{i}", text_val))
                for hint, text_val in values:
                    if is_form_fields:
                        expected.append({
                            "source_code": "giswater",
                            "project_type": project_type,
                            "context": table_org,
                            "formname": row["formname"],
                            "formtype": row["formtype"],
                            "tabname": row["tabname"],
                            "source": row["columnname"],
                            "hint": hint,
                            "lb_en_us": text_val,
                            "text": text_blob,
                        })
                    else:
                        expected.append({
                            "source_code": "giswater",
                            "project_type": project_type,
                            "context": table_org,
                            "hint": hint,
                            "source": row["id"],
                            "lb_en_us": text_val,
                            "text": text_blob,
                        })

    return _compare_db_rows(
        expected,
        rows_i18n,
        columns_i18n,
        table_name=table_name,
        table_org=table_org,
        schema_org=schema_org,
        project_type=project_type,
    )


def _extract_form_fields_query_table(
    origin: OriginDb,
    i18n_rows: list[dict],
    table_name: str,
    table_org: str,
    schema_org: str,
    project_type: str,
) -> list[ExtractedString]:
    """Hardcoded combo labels inside ``config_form_fields.dv_querytext``."""
    pk_column_org = ["formname", "formtype", "tabname", "columnname"]
    columns_i18n = [
        "source_code", "project_type", "context", "formname", "formtype",
        "tabname", "source", "hint", "lb_en_us", "text",
    ]

    query_org = (
        f"SELECT {', '.join(pk_column_org)}, dv_querytext "
        f"FROM {schema_org}.{table_org} "
        f"WHERE dv_querytext IS NOT NULL AND btrim(dv_querytext) <> ''"
    )
    rows_org = origin.fetch_all(query_org)

    rows_i18n = _filter_i18n_rows_by_context(
        _clean_rows_i18n(
            _filter_i18n_rows(i18n_rows, table_name, project_type),
            columns_i18n,
            project_type,
            table_name,
        ),
        table_org,
    )

    expected: list[dict] = []
    for row in rows_org:
        text_blob = row.get("dv_querytext")
        if text_blob in (None, "", "None"):
            continue
        text_blob = str(text_blob)
        literals = _extract_dvquery_idval_texts(text_blob)
        for i, text_val in enumerate(literals):
            if not text_val:
                continue
            expected.append({
                "source_code": "giswater",
                "project_type": project_type,
                "context": table_org,
                "formname": row["formname"],
                "formtype": row["formtype"],
                "tabname": row["tabname"],
                "source": row["columnname"],
                "hint": f"{_DVQUERY_KEY}_{i}",
                "lb_en_us": text_val,
                "text": text_blob,
            })

    return _compare_db_rows(
        expected,
        rows_i18n,
        columns_i18n,
        table_name=table_name,
        table_org=table_org,
        schema_org=schema_org,
        project_type=project_type,
    )


def _extract_feat_table(
    origin: OriginDb,
    i18n_rows: list[dict],
    table_name: str,
    schema_org: str,
    project_type: str,
) -> list[ExtractedString]:
    pk_column_org = ["formname", "formtype", "tabname", "columnname"]
    columns_org = ["label", "tooltip", "placeholder"]
    columns_i18n = [
        "feature_type", "source_code", "project_type", "context",
        "formtype", "tabname", "source", "lb_en_us", "tt_en_us", "pl_en_us", "formname",
    ]

    query_org = f"SELECT {', '.join(pk_column_org)}, {', '.join(columns_org)} FROM {schema_org}.config_form_fields"
    query_org = _append_sql_condition(
                        query_org, _form_fields_feat_exclude_condition(negation=False)
                    )
    rows_org = origin.fetch_all(query_org)

    rows_i18n = _filter_i18n_rows_by_context(
        _clean_rows_i18n(
            _filter_i18n_rows(i18n_rows, table_name, project_type),
            columns_i18n,
            project_type,
            table_name,
        ),
        "config_form_fields",
    )

    expected: list[dict] = []
    for feature_type, prefix in _FEAT_FORM_RULES:
        repeated_rows: list[tuple[str, str, str]] = []
        for row in rows_org:
            formname = str(row.get("formname", ""))
            if row.get("formtype") != "form_feature":
                continue
            if not (formname.startswith(prefix) or formname == prefix):
                continue
            repeated_row = (row.get("formtype"), row.get("tabname"), row.get("columnname"))
            if repeated_row in repeated_rows:
                continue
            label = _normalize_cell_value(row.get("label", ""))
            tooltip = _normalize_cell_value(row.get("tooltip", ""))
            placeholder = _normalize_cell_value(row.get("placeholder", ""))
            if not label and not tooltip and not placeholder:
                continue
            expected.append({
                "feature_type": feature_type,
                "source_code": "giswater",
                "project_type": project_type,
                "context": "config_form_fields",
                "formtype": row.get("formtype", ""),
                "tabname": row.get("tabname", ""),
                "source": row.get("columnname", ""),
                "formname": formname,
                "lb_en_us": label,
                "tt_en_us": tooltip,
                "pl_en_us": placeholder,
            })
            repeated_rows.append(repeated_row)

    return _compare_db_rows(
        expected,
        rows_i18n,
        columns_i18n,
        table_name=table_name,
        table_org="config_form_fields",
        schema_org=schema_org,
        project_type=project_type,
    )


def _extract_dbstyle_table(
    origin: OriginDb,
    i18n_rows: list[dict],
    table_name: str,
    table_org: str,
    schema_org: str,
    project_type: str,
) -> list[ExtractedString]:
    columns_i18n_raw, columns_org = get_columns_to_compare(table_name, table_org, project_type)
    columns_i18n = _normalize_i18n_columns(columns_i18n_raw)

    rows_i18n = _filter_i18n_rows_by_context(
        _clean_rows_i18n(
            _filter_i18n_rows(i18n_rows, table_name, project_type),
            columns_i18n,
            project_type,
            table_name,
        ),
        table_org,
    )

    query_org = f"SELECT {', '.join(columns_org)} FROM {schema_org}.{table_org}"
    rows_org = _get_dbstyle_rows(origin.fetch_all(query_org))
    columns_org_compare = list(columns_org)
    if "hint" not in columns_org_compare:
        columns_org_compare.extend(["hint", "lb_en_us"])
    rows_org = _clean_rows_org(rows_org, columns_org_compare, project_type, table_org)
    aligned_org = _align_org_rows(
        rows_org, columns_org_compare, columns_i18n, project_type, table_org
    )

    return _compare_db_rows(
        aligned_org,
        rows_i18n,
        columns_i18n,
        table_name=table_name,
        table_org=table_org,
        schema_org=schema_org,
        project_type=project_type,
    )


def extract_db_candidates(
    origin: OriginDb,
    i18n_rows: list[dict],
    config: SearcherConfig,
) -> list[ExtractedString]:
    findings: list[ExtractedString] = []

    for project_type in config.project_types:
        schema_org = config.origin_schemas.get(project_type)
        if not schema_org:
            continue
        schema_org = _validate_sql_identifier(schema_org, "schema")

        if not origin.schema_exists(schema_org):
            log.warning("Origin schema %s does not exist", schema_org)
            continue
        if not origin.verify_lang(schema_org):
            log.warning("Origin schema %s language is not no_TR", schema_org)
            continue

        for table_name in _iter_project_db_tables(project_type):
            table_i18n_rows = _filter_i18n_rows(i18n_rows, table_name, project_type)
            findings.extend(
                _extract_one_db_table(
                    origin,
                    table_i18n_rows,
                    table_name,
                    schema_org,
                    project_type,
                )
            )

    log.info("DB extraction: %d detection(s)", len(findings))
    return findings


def _extract_one_db_table(
    origin: OriginDb,
    table_i18n_rows: list[dict],
    table_name: str,
    schema_org: str,
    project_type: str,
) -> list[ExtractedString]:
    """Dispatch one catalog table to the matching extractor."""
    findings: list[ExtractedString] = []
    for table_org in find_table_org_with_context(table_i18n_rows, table_name, project_type):
        table_org = _validate_sql_identifier(table_org, "table")
        if not origin.table_exists(schema_org, table_org):
            continue

        if table_name == "dbconfig_form_fields_feat":
            findings.extend(
                _extract_feat_table(origin, table_i18n_rows, table_name, schema_org, project_type)
            )
            continue
        if table_name == "dbconfig_form_fields_query":
            findings.extend(
                _extract_form_fields_query_table(
                    origin, table_i18n_rows, table_name, table_org, schema_org, project_type
                )
            )
            continue
        if "json" in table_name:
            findings.extend(
                _extract_json_table(
                    origin, table_i18n_rows, table_name, table_org, schema_org, project_type
                )
            )
            continue
        if table_name == "dbstyle":
            findings.extend(
                _extract_dbstyle_table(
                    origin, table_i18n_rows, table_name, table_org, schema_org, project_type
                )
            )
            continue

        columns_i18n_raw, columns_org = get_columns_to_compare(table_name, table_org, project_type)
        columns_i18n = _normalize_i18n_columns(columns_i18n_raw)
        rows_i18n = _filter_i18n_rows_by_context(
            _clean_rows_i18n(table_i18n_rows, columns_i18n, project_type, table_name),
            table_org,
        )

        cols_org_sql = ", ".join(columns_org)
        query_org = f"SELECT {cols_org_sql} FROM {schema_org}.{table_org}"
        if table_name == "dbconfig_form_fields":
            query_org = _append_sql_condition(
                query_org, _form_fields_feat_exclude_condition(negation=True)
            )
        origin_condition = _ORIGIN_QUERY_CONDITIONS.get((table_name, table_org))
        if origin_condition:
            query_org = _append_sql_condition(query_org, origin_condition)
        rows_org = origin.fetch_all(query_org)
        rows_org = _clean_rows_org(rows_org, columns_org, project_type, table_org)
        aligned_org = _align_org_rows(
            rows_org, columns_org, columns_i18n, project_type, table_org
        )
        findings.extend(
            _compare_db_rows(
                aligned_org,
                rows_i18n,
                columns_i18n,
                table_name=table_name,
                table_org=table_org,
                schema_org=schema_org,
                project_type=project_type,
            )
        )
    return findings

# endregion


# region CLI

def _parse_origin_schemas(raw: str | None, project_types: list[str]) -> dict[str, str]:
    defaults = {"ws": "ws_trans", "ud": "ud_trans", "cm": "cm", "am": "am"}
    if not raw:
        return {
            pt: _validate_sql_identifier(defaults[pt], "schema")
            for pt in project_types
            if pt in defaults
        }
    result: dict[str, str] = {}
    for part in raw.split(","):
        part = part.strip()
        if not part:
            continue
        if "=" not in part:
            raise ValueError(f"Invalid origin schema mapping: {part!r} (expected project=schema)")
        project, schema = part.split("=", 1)
        project = project.strip()
        if not project:
            raise ValueError(f"Invalid origin schema mapping: {part!r}")
        result[project] = _validate_sql_identifier(schema.strip(), "schema")
    return result


def _resolve_detected_version(
    origin: OriginDb,
    origin_schemas: dict[str, str],
    cli_version: str,
) -> str:
    for schema in origin_schemas.values():
        version = origin.schema_version(schema)
        if version:
            return version
    return cli_version


def _read_metadata_version(repo_root: Path) -> str:
    metadata = repo_root / "metadata.txt"
    if not metadata.is_file():
        return ""
    for line in metadata.read_text(encoding="utf-8").splitlines():
        if line.startswith("version="):
            return line.split("=", 1)[1].strip()
    return ""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Detect i18n text changes and upload to the translations API.",
    )
    parser.add_argument("--base-url", default=None, help="Translations API base URL")
    parser.add_argument("--user", default=None, help="API username")
    parser.add_argument("--password", default=None, help="API password")
    parser.add_argument(
        "--messages-path",
        default=None,
        help=f"GET path for i18n baseline (default: {DEFAULT_MESSAGES_PATH})",
    )
    parser.add_argument(
        "--changed-path",
        default=None,
        help=f"POST path for changed texts (default: {DEFAULT_CHANGED_PATH})",
    )
    parser.add_argument(
        "--deleted-path",
        default=None,
        help=f"POST path for deleted texts (default: {DEFAULT_DELETED_PATH})",
    )
    parser.add_argument(
        "--new-path",
        default=None,
        help=f"POST path for new texts (default: {DEFAULT_NEW_PATH})",
    )
    parser.add_argument(
        "--origin-conn",
        default=None,
        help="PostgreSQL connection string for origin schemas (env: ORIGIN_PG_CONN or GW_CONN)",
    )
    parser.add_argument(
        "--project-types",
        default="ws,ud",
        help="Comma-separated project types to scan (default: ws,ud)",
    )
    parser.add_argument(
        "--origin-schemas",
        default=None,
        help="Comma-separated project=schema mappings (default: ws=ws_trans,ud=ud_trans,...)",
    )
    parser.add_argument(
        "--version",
        default=None,
        help="Detected version fallback (default: origin sys_version or metadata.txt)",
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Plugin repository root (default: current directory)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Classify and print counts without POSTing detections",
    )
    parser.add_argument(
        "--json-out",
        default=None,
        help="Optional path to write grouped detection records as JSON",
    )
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable debug logging")
    return parser.parse_args()


def _upload_grouped_records(
    api: TranslationsApiClient,
    grouped: dict[str, list[dict[str, Any]]],
    *,
    detected_version: str,
    new_path: str,
    changed_path: str,
    deleted_path: str,
    clear_pending_path: str = DEFAULT_CLEAR_PENDING_PATH,
    dry_run: bool,
) -> None:
    # Clear prior pending rows before uploading this run's detections.
    clear_pending_detections(api, detected_version, clear_pending_path, dry_run=dry_run)
    for kind, path in (
        ("new", new_path),
        ("changed", changed_path),
        ("deleted", deleted_path),
    ):
        upload_detection_records(api, path, grouped[kind], dry_run=dry_run, kind=kind)


def main() -> int:
    args = parse_args()
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s: %(message)s",
    )

    base_url = (resolve_setting(args.base_url, "TRANSLATIONS_API_URL") or "").strip()
    user = (resolve_setting(args.user, "TRANSLATIONS_API_USER", "") or "").strip()
    password = (resolve_setting(args.password, "TRANSLATIONS_API_PASSWORD", "") or "").strip()
    origin_conn = (
        resolve_setting(args.origin_conn, "ORIGIN_PG_CONN")
        or resolve_setting(None, "GW_CONN")
        or ""
    ).strip()

    if not base_url:
        print("Error: missing API base URL. Set TRANSLATIONS_API_URL or pass --base-url.", file=sys.stderr)
        return 1
    if not origin_conn:
        print(
            "Error: missing origin DB connection. Set ORIGIN_PG_CONN/GW_CONN or pass --origin-conn.",
            file=sys.stderr,
        )
        return 1

    project_types = [p.strip() for p in args.project_types.split(",") if p.strip()]
    origin_schemas = _parse_origin_schemas(args.origin_schemas, project_types)
    repo_root = Path(args.repo_root).resolve()

    messages_path = resolve_setting(args.messages_path, "I18N_MESSAGES_PATH", DEFAULT_MESSAGES_PATH)
    changed_path = resolve_setting(args.changed_path, "I18N_CHANGED_PATH", DEFAULT_CHANGED_PATH)
    deleted_path = resolve_setting(args.deleted_path, "I18N_DELETED_PATH", DEFAULT_DELETED_PATH)
    new_path = resolve_setting(args.new_path, "I18N_NEW_PATH", DEFAULT_NEW_PATH)

    config = SearcherConfig(
        repo_root=repo_root,
        project_types=project_types,
        origin_schemas=origin_schemas,
        dry_run=args.dry_run,
    )

    origin = OriginDb(origin_conn)
    try:
        cli_version = (args.version or _read_metadata_version(repo_root) or "").strip()
        detected_version = _resolve_detected_version(origin, origin_schemas, cli_version)
        if not detected_version:
            print("Error: could not resolve detected_version.", file=sys.stderr)
            return 1
        log.info("Detected version: %s", detected_version)

        with TranslationsApiClient(base_url, user, password) as api:
            log.info("Fetching full i18n baseline from %s (no query filters)", messages_path)
            i18n_rows = fetch_i18n_messages(api, messages_path or DEFAULT_MESSAGES_PATH)
            log.info("Loaded %d i18n row(s) from API; filtering by table/project in memory", len(i18n_rows))

            findings_db = extract_db_candidates(origin, i18n_rows, config)
            findings_py = extract_py_candidates(i18n_rows, config)
            findings = findings_db + findings_py
            grouped = group_records(findings, detected_version)

            if args.json_out:
                out_path = Path(args.json_out)
                out_path.parent.mkdir(parents=True, exist_ok=True)
                out_path.write_text(
                    json.dumps(grouped, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8",
                )
                log.info("Wrote %s", out_path)

            print(
                "Detections (unique records to POST): "
                f"{len(grouped['new'])} new, "
                f"{len(grouped['changed'])} changed, "
                f"{len(grouped['deleted'])} deleted"
            )

            _upload_grouped_records(
                api,
                grouped,
                detected_version=detected_version,
                new_path=new_path or DEFAULT_NEW_PATH,
                changed_path=changed_path or DEFAULT_CHANGED_PATH,
                deleted_path=deleted_path or DEFAULT_DELETED_PATH,
                dry_run=config.dry_run,
            )

        return 0
    except (RuntimeError, ValueError, psycopg2.Error) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    finally:
        origin.close()


if __name__ == "__main__":
    raise SystemExit(main())

# endregion
