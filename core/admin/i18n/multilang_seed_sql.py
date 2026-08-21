"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

Parse bundled baseline SQL and build INSERT/DELETE statements that seed
the multilang satellite schema.

Baselines are loaded per project_type (ws, ud, am, cm). Also provides
locale-name helpers and multilang admin-function SQL runners.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
from dataclasses import dataclass, field
from typing import Any, Callable, Iterable, Optional, Sequence

# Hardcoded initial language scope.
SEED_LANGUAGE_ID = "en_us"
SEED_LANGUAGE_FOLDER = "en_US"

# Relative dbmodel paths to bundled baseline SQL (language folder appended).
_I18N_BASELINE_ROOTS: dict[str, str] = {
    "ws": os.path.join("schemas", "main", "ws", "final_pass", "i18n"),
    "ud": os.path.join("schemas", "main", "ud", "final_pass", "i18n"),
    "am": os.path.join("schemas", "addon", "am", "final_pass", "i18n"),
    "cm": os.path.join("schemas", "addon", "cm", "final_pass", "i18n"),
}

TRANSLATABLE_PROJECT_TYPES: frozenset[str] = frozenset(_I18N_BASELINE_ROOTS.keys())

# Baseline SQL file stem -> multilang schema table (mains_language_ui.md scope).
# Adding a new entry also requires a matching extraction branch in
# blocks_to_multilang_rows.
BASELINE_TO_MULTILANG_TABLE: dict[str, str] = {
    "dbconfig_form_fields": "config_form_fields",
    "dbconfig_form_fields_feat": "config_form_fields",
    "dbconfig_form_fields_json": "config_form_fields_json",
    "dbtable": "sys_table",
    "dbmessage": "sys_message",
    "dbfunction": "sys_function",
    "dbfprocess": "sys_fprocess",
    "dbparam_user": "sys_param_user",
    "dbconfig_form_tabs": "config_form_tabs",
    "dbconfig_param_system": "config_param_system",
    "dblabel": "sys_label",
    "dbconfig_csv": "config_csv",
    "dbconfig_form_tableview": "config_form_tableview",
    "dbjson": "config_json",
    "dbconfig_report": "config_report",
    "dbconfig_toolbox": "config_toolbox",
    "dbconfig_typevalue": "config_typevalue",
    "dbtypevalue": "typevalue",
    "dbconfig_visit_parameter": "config_visit_parameter",
    "dbplan_price": "plan_price",
    "dbstyle": "sys_style",
}

MULTILANG_UI_TABLES: tuple[str, ...] = tuple(sorted(
    set(BASELINE_TO_MULTILANG_TABLE.values()) | {"value_state", "value_state_type"}
))

# Baseline files whose UPDATE context selects the satellite table.
_MULTI_CONTEXT_BASELINES: frozenset[str] = frozenset({"dbbasic_tables"})

_CORE_BASELINE_FILES: tuple[str, ...] = tuple(BASELINE_TO_MULTILANG_TABLE.keys()) + tuple(
    sorted(_MULTI_CONTEXT_BASELINES)
)

# Baseline SQL files per project type (skip missing files at load time).
_PROJECT_TYPE_TABLES: dict[str, tuple[str, ...]] = {
    "ws": _CORE_BASELINE_FILES,
    "ud": _CORE_BASELINE_FILES,
    "am": (
        "dbconfig_form_tableview",
    ),
    "cm": (
        "dbconfig_form_fields",
        "dbconfig_form_fields_json",
        "dbconfig_form_tabs",
        "dbconfig_param_system",
        "dbfprocess",
        "dbtable",
        "dbconfig_form_tableview",
        "dbtypevalue",
    ),
}

UPDATE_HEADER_RE = re.compile(
    r"UPDATE\s+(?P<context>\w+)\s+AS\s+t\s+SET\s+(?P<set_clause>.+?)\s+FROM\s*\(\s*VALUES\s*",
    re.IGNORECASE | re.DOTALL,
)

# Matches ") AS v(" outside of string literals (found via quote-aware scan).
ALIAS_CLAUSE_RE = re.compile(r"\)\s*AS\s+v\s*\(", re.IGNORECASE)

SET_ASSIGN_RE = re.compile(
    r"(?P<target>\w+)\s*=\s*(?:REPLACE\s*\(\s*)?v\.(?P<alias>\w+)",
    re.IGNORECASE,
)

_ORG_TO_I18N_DEFAULT = {
    "alias": "al",
    "descript": "ds",
    "label": "lb",
    "tooltip": "tt",
    "placeholder": "pl",
    "idval": "vl",
    "error_message": "ms",
    "hint_message": "ht",
    "except_msg": "ex",
    "info_msg": "in",
    "fprocess_name": "na",
    "observ": "ob",
    "widgetcontrols": "text",
    "filterparam": "text",
    "inputparams": "text",
    "text": "tx",
    "stylevalue": "tx",
    "price": "pr",
    "name": "na",
    "value": "vl",
}

# Context-specific org column -> multilang column overrides.
_CONTEXT_I18N_OVERRIDES: dict[str, dict[str, str]] = {
    "config_typevalue": {"idval": "tt"},
    "sys_param_user": {"descript": "tt"},
    "config_param_system": {"descript": "tt"},
    "sys_style": {"stylevalue": "tx"},
}

# ON CONFLICT target columns per multilang table (must match DDL PK).
_TABLE_CONFLICT_KEYS: dict[str, tuple[str, ...]] = {
    "config_form_fields": ("tabname", "context", "formname", "formtype", "project_type", "source", "lang"),
    "config_form_fields_json": (
        "tabname", "context", "formname", "formtype", "project_type", "source", "hint", "lang",
    ),
    "config_form_tabs": ("project_type", "context", "formname", "source", "lang"),
    "config_param_system": ("project_type", "context", "source", "lang"),
    "sys_fprocess": ("project_type", "context", "source", "lang"),
    "sys_function": ("project_type", "context", "source", "lang"),
    "sys_message": ("project_type", "context", "source", "lang"),
    "sys_param_user": ("project_type", "context", "source", "lang"),
    "sys_table": ("project_type", "context", "source", "lang"),
    "sys_label": ("project_type", "context", "source", "lang"),
    "config_csv": ("project_type", "context", "source", "lang"),
    "config_form_tableview": ("project_type", "context", "source", "columnname", "lang"),
    "config_json": ("project_type", "context", "source", "hint", "lang"),
    "config_report": ("project_type", "context", "source", "lang"),
    "config_toolbox": ("project_type", "context", "source", "lang"),
    "config_typevalue": ("project_type", "context", "formname", "source", "lang"),
    "typevalue": ("project_type", "context", "typevalue", "source", "lang"),
    "config_visit_parameter": ("project_type", "context", "source", "lang"),
    "value_state": ("project_type", "context", "source", "lang"),
    "value_state_type": ("project_type", "context", "source", "lang"),
    "plan_price": ("project_type", "context", "source", "lang"),
    "sys_style": ("project_type", "context", "source", "layername", "lang"),
}

# Multilang columns that must be double-quoted in generated SQL.
_QUOTED_SQL_COLUMNS = frozenset({"source", "in", "text", "parameter", "method"})


def _quote_sql_col(name: str) -> str:
    if name in _QUOTED_SQL_COLUMNS:
        return f'"{name}"'
    return name


def _dedupe_rows_by_conflict_key(
    table: str,
    rows: Sequence[MultilangRow],
) -> list[MultilangRow]:
    """Keep one row per ON CONFLICT target; later baseline rows win."""
    conflict_keys = _TABLE_CONFLICT_KEYS.get(table)
    if not conflict_keys or not rows:
        return list(rows)

    deduped: dict[tuple[Any, ...], MultilangRow] = {}
    for row in rows:
        key = tuple(row.values.get(col) for col in conflict_keys)
        existing = deduped.get(key)
        if existing is None:
            deduped[key] = row
            continue
        merged = dict(existing.values)
        for col, val in row.values.items():
            if val is not None:
                merged[col] = val
        deduped[key] = MultilangRow(table=row.table, values=merged)
    return list(deduped.values())


@dataclass
class ParsedUpdateBlock:
    context: str
    set_targets: dict[str, str]  # org column -> v alias
    value_aliases: list[str]
    rows: list[list[Any]] = field(default_factory=list)
    json_hints: list[str] = field(default_factory=list)  # SET targets stored as hint (json cols)


@dataclass
class MultilangRow:
    table: str
    values: dict[str, Any]


def baseline_i18n_dir(
    sql_root: str,
    project_type: str,
    *,
    lang: str = SEED_LANGUAGE_FOLDER,
) -> str | None:
    """Return bundled baseline i18n folder for a project type, or None if unsupported."""
    pt = normalize_project_type(project_type)
    if not pt:
        return None
    rel = _I18N_BASELINE_ROOTS.get(pt)
    if not rel:
        return None
    return os.path.join(sql_root, rel, lang)


def normalize_project_type(project_type: str | None) -> str | None:
    if not project_type:
        return None
    key = str(project_type).strip().lower()
    if key in TRANSLATABLE_PROJECT_TYPES:
        return key
    return None


def normalize_language_id(locale: str | None) -> str:
    """Normalize locale to multilang.cat_language / row lang id (en_us)."""
    if not locale:
        return SEED_LANGUAGE_ID
    text = str(locale).strip().replace("-", "_")
    parts = text.split("_", 1)
    if len(parts) == 2 and parts[0] and parts[1]:
        return f"{parts[0].lower()}_{parts[1].lower()}"
    return text.lower()


def normalize_language_folder(locale: str | None) -> str:
    """Normalize locale to bundled i18n folder name (en_US)."""
    if not locale:
        return SEED_LANGUAGE_FOLDER
    text = str(locale).strip().replace("-", "_")
    parts = text.split("_", 1)
    if len(parts) == 2 and parts[0] and parts[1]:
        return f"{parts[0].lower()}_{parts[1].upper()}"
    return text


def project_type_has_baseline(
    sql_root: str,
    project_type: str,
    *,
    lang: str = SEED_LANGUAGE_FOLDER,
) -> bool:
    i18n_dir = baseline_i18n_dir(sql_root, project_type, lang=lang)
    if not i18n_dir or not os.path.isdir(i18n_dir):
        return False
    return any(name.endswith(".sql") for name in os.listdir(i18n_dir))


def seed_table_files_for_project_type(
    project_type: str,
    sql_root: str,
    *,
    lang: str = SEED_LANGUAGE_FOLDER,
) -> tuple[str, ...]:
    """Baseline table files to import for one project type (existing files only)."""
    pt = normalize_project_type(project_type)
    if not pt:
        return ()

    i18n_dir = baseline_i18n_dir(sql_root, pt, lang=lang)
    if not i18n_dir or not os.path.isdir(i18n_dir):
        return ()

    tables: list[str] = []
    for baseline_file in _PROJECT_TYPE_TABLES.get(pt, ()):
        if not _baseline_is_seedable(baseline_file):
            continue
        if os.path.isfile(os.path.join(i18n_dir, f"{baseline_file}.sql")):
            tables.append(baseline_file)
    return tuple(tables)


def _baseline_is_seedable(baseline_file: str) -> bool:
    if baseline_file in _MULTI_CONTEXT_BASELINES:
        return True
    target = BASELINE_TO_MULTILANG_TABLE.get(baseline_file)
    return bool(target and target in _TABLE_CONFLICT_KEYS)


def _parse_sql_string_literal(inner: str, start: int, *, escape: bool = False) -> tuple[str, int]:
    """Parse a SQL string starting after the opening quote; return (value, next_index)."""
    length = len(inner)
    i = start
    chars: list[str] = []
    while i < length:
        ch = inner[i]
        if escape and ch == "\\" and i + 1 < length:
            nxt = inner[i + 1]
            if nxt == "n":
                chars.append("\n")
            elif nxt == "t":
                chars.append("\t")
            elif nxt == "r":
                chars.append("\r")
            elif nxt in ("\\", "'"):
                chars.append(nxt)
            else:
                chars.append(nxt)
            i += 2
            continue
        if ch == "'":
            if i + 1 < length and inner[i + 1] == "'":
                chars.append("'")
                i += 2
                continue
            return "".join(chars), i + 1
        chars.append(ch)
        i += 1
    return "".join(chars), i


def parse_sql_value_tuple(raw: str) -> list[Any]:
    """Parse one SQL VALUES tuple: (a, 'b', NULL, 1) or (1, E'text', NULL)."""
    text = raw.strip()
    if not text.startswith("(") or not text.endswith(")"):
        msg = "Invalid tuple: {0}"
        msg_params = (repr(raw[:80]),)
        raise ValueError(msg.format(*msg_params))
    inner = text[1:-1]
    values: list[Any] = []
    i = 0
    length = len(inner)

    while i < length:
        while i < length and inner[i] in " \t\n\r,":
            i += 1
        if i >= length:
            break

        # PostgreSQL escape-string: E'...' / e'...'
        if (
            i + 1 < length
            and inner[i] in "Ee"
            and inner[i + 1] == "'"
        ):
            value, i = _parse_sql_string_literal(inner, i + 2, escape=True)
            values.append(value)
            continue

        if inner[i] == "'":
            value, i = _parse_sql_string_literal(inner, i + 1, escape=False)
            values.append(value)
            continue

        if inner[i:].upper().startswith("NULL") and (
            i + 4 >= length or inner[i + 4] in " \t\n\r,)"
        ):
            values.append(None)
            i += 4
            continue

        start = i
        while i < length and inner[i] not in ",)":
            i += 1
        token = inner[start:i].strip()
        if not token:
            # Unexpected char (e.g. stray ')'); advance to avoid infinite loop.
            i += 1
            continue
        if re.fullmatch(r"-?\d+", token):
            values.append(int(token))
        elif re.fullmatch(r"-?\d+\.\d+", token):
            values.append(float(token))
        else:
            values.append(token)

    return values


def split_value_tuples(values_blob: str) -> list[str]:
    """Split VALUES blob into individual tuple strings."""
    tuples: list[str] = []
    depth = 0
    start: int | None = None
    in_quote = False
    idx = 0
    length = len(values_blob)

    while idx < length:
        ch = values_blob[idx]
        if ch == "'":
            if not in_quote:
                in_quote = True
            elif idx + 1 < length and values_blob[idx + 1] == "'":
                idx += 1
            else:
                in_quote = False
            idx += 1
            continue

        if in_quote:
            idx += 1
            continue

        if ch == "(":
            if depth == 0:
                start = idx
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0 and start is not None:
                tuples.append(values_blob[start: idx + 1])
                start = None
        idx += 1

    return tuples


def _find_alias_clause(sql_text: str, start: int) -> re.Match[str] | None:
    """Find ``) AS v(`` starting at/after *start*, skipping SQL string literals."""
    in_quote = False
    idx = start
    length = len(sql_text)

    while idx < length:
        ch = sql_text[idx]
        if ch == "'":
            if not in_quote:
                in_quote = True
            elif idx + 1 < length and sql_text[idx + 1] == "'":
                idx += 2
                continue
            else:
                in_quote = False
            idx += 1
            continue

        if in_quote:
            idx += 1
            continue

        match = ALIAS_CLAUSE_RE.match(sql_text, idx)
        if match is not None:
            return match
        idx += 1

    return None


def _parse_update_from_header(
    sql_text: str,
    header: re.Match[str],
) -> ParsedUpdateBlock | None:
    values_start = header.end()
    alias_match = _find_alias_clause(sql_text, values_start)
    if alias_match is None:
        return None

    values_blob = sql_text[values_start: alias_match.start()]
    aliases_start = alias_match.end()
    alias_close = sql_text.find(")", aliases_start)
    if alias_close == -1:
        return None

    aliases = [
        part.strip()
        for part in sql_text[aliases_start:alias_close].split(",")
        if part.strip()
    ]
    context = header.group("context")
    set_clause = header.group("set_clause")

    set_targets: dict[str, str] = {}
    json_hints: list[str] = []
    for set_match in SET_ASSIGN_RE.finditer(set_clause):
        target = set_match.group("target")
        alias = set_match.group("alias")
        set_targets[target] = alias
        if target in ("widgetcontrols", "filterparam", "inputparams"):
            json_hints.append(target)

    rows: list[list[Any]] = []
    for tuple_raw in split_value_tuples(values_blob):
        try:
            rows.append(parse_sql_value_tuple(tuple_raw))
        except ValueError:
            continue

    if not rows:
        return None

    return ParsedUpdateBlock(
        context=context,
        set_targets=set_targets,
        value_aliases=aliases,
        rows=rows,
        json_hints=json_hints,
    )


def parse_update_blocks(sql_text: str) -> list[ParsedUpdateBlock]:
    """Parse ``UPDATE … AS t SET … FROM (VALUES …) AS v(…)`` blocks.

    Uses the real UPDATE header regex so the word UPDATE inside translated
    string literals (e.g. ``'… FOR UPDATE operation'``) is ignored.
    """
    blocks: list[ParsedUpdateBlock] = []
    for header in UPDATE_HEADER_RE.finditer(sql_text):
        block = _parse_update_from_header(sql_text, header)
        if block is not None:
            blocks.append(block)
    return blocks


def _alias_index(aliases: Sequence[str], name: str) -> int | None:
    try:
        return aliases.index(name)
    except ValueError:
        lowered = name.lower()
        for idx, alias in enumerate(aliases):
            if alias.lower() == lowered:
                return idx
    return None


def _cell(row: Sequence[Any], aliases: Sequence[str], alias: str) -> Any:
    idx = _alias_index(aliases, alias)
    if idx is None or idx >= len(row):
        return None
    return row[idx]


def _first_cell(row: Sequence[Any], aliases: Sequence[str], *names: str) -> Any:
    for name in names:
        value = _cell(row, aliases, name)
        if value is not None:
            return value
    return None


def _org_to_i18n(context: str, org_column: str) -> str | None:
    overrides = _CONTEXT_I18N_OVERRIDES.get(context, {})
    if org_column in overrides:
        return overrides[org_column]
    return _ORG_TO_I18N_DEFAULT.get(org_column)


def _sql_literal(value: Any, *, as_json: bool = False) -> str:
    if value is None:
        return "NULL"
    text = str(value).replace("'", "''")
    if as_json:
        return f"'{text}'::json"
    return f"'{text}'"


def blocks_to_multilang_rows(
    table: str,
    blocks: Iterable[ParsedUpdateBlock],
    *,
    project_type: str = "",
    lang: str = SEED_LANGUAGE_ID,
) -> list[MultilangRow]:
    rows: list[MultilangRow] = []
    stamped_type = str(project_type or "")
    for block in blocks:
        for raw in block.rows:
            values: dict[str, Any] = {
                "project_type": stamped_type,
                "context": block.context,
                "lang": lang,
            }

            if table == "dbconfig_form_fields":
                values.update({
                    "source": _cell(raw, block.value_aliases, "columnname"),
                    "formname": _cell(raw, block.value_aliases, "formname"),
                    "formtype": _cell(raw, block.value_aliases, "formtype"),
                    "tabname": _cell(raw, block.value_aliases, "tabname"),
                })
            elif table == "dbconfig_form_fields_feat":
                values.update({
                    "source": _cell(raw, block.value_aliases, "columnname"),
                    "formname": _cell(raw, block.value_aliases, "formname"),
                    "formtype": _cell(raw, block.value_aliases, "formtype"),
                    "tabname": _cell(raw, block.value_aliases, "tabname"),
                })
            elif table == "dbconfig_form_fields_json":
                values.update({
                    "source": _cell(raw, block.value_aliases, "columnname"),
                    "formname": _cell(raw, block.value_aliases, "formname"),
                    "formtype": _cell(raw, block.value_aliases, "formtype"),
                    "tabname": _cell(raw, block.value_aliases, "tabname"),
                    "hint": block.json_hints[0] if block.json_hints else "widgetcontrols",
                    "text": _cell(raw, block.value_aliases, "text"),
                })
            elif table == "dbconfig_form_tabs":
                values.update({
                    "formname": _cell(raw, block.value_aliases, "formname"),
                    "source": _cell(raw, block.value_aliases, "tabname"),
                })
            elif table == "dbconfig_param_system":
                values["source"] = _cell(raw, block.value_aliases, "parameter")
            elif table == "dblabel":
                values["source"] = _cell(raw, block.value_aliases, "id")
            elif table == "dbconfig_csv":
                values["source"] = _cell(raw, block.value_aliases, "fid")
            elif table == "dbconfig_form_tableview":
                values.update({
                    "source": _cell(raw, block.value_aliases, "objectname"),
                    "columnname": _cell(raw, block.value_aliases, "columnname"),
                })
            elif table == "dbjson":
                values.update({
                    "source": _cell(raw, block.value_aliases, "id"),
                    "hint": block.json_hints[0] if block.json_hints else "filterparam",
                    "text": _cell(raw, block.value_aliases, "text"),
                })
            elif table == "dbconfig_typevalue":
                values.update({
                    "formname": _first_cell(
                        raw, block.value_aliases, "formname", "typevalue",
                    ),
                    "source": _first_cell(
                        raw, block.value_aliases, "source", "id",
                    ),
                })
            elif table == "dbtypevalue":
                values.update({
                    "typevalue": _cell(raw, block.value_aliases, "typevalue"),
                    "source": _first_cell(
                        raw, block.value_aliases, "source", "id",
                    ),
                })
            elif table == "dbconfig_visit_parameter":
                values["source"] = _cell(raw, block.value_aliases, "id")
            elif table == "dbstyle":
                values.update({
                    "source": _first_cell(
                        raw, block.value_aliases, "styleconfig_id", "source",
                    ),
                    "layername": _cell(raw, block.value_aliases, "layername"),
                    "tx": _cell(raw, block.value_aliases, "stylevalue"),
                })
            elif table == "dbbasic_tables":
                if block.context == "config_param_system":
                    values["source"] = _first_cell(
                        raw, block.value_aliases, "parameter", "id",
                    )
                elif block.context in ("value_state", "value_state_type"):
                    values["source"] = _cell(raw, block.value_aliases, "id")
                else:
                    continue
            elif table in (
                "dbparam_user", "dbmessage", "dbfprocess", "dbfunction", "dbtable",
                "dbconfig_report", "dbconfig_toolbox", "dbplan_price",
            ):
                key = "fid" if table == "dbfprocess" else "id"
                values["source"] = _cell(raw, block.value_aliases, key)
            else:
                continue

            for org_col, v_alias in block.set_targets.items():
                i18n_col = _org_to_i18n(block.context, org_col)
                if not i18n_col:
                    continue
                if table in ("dbconfig_form_fields_json", "dbjson") and i18n_col == "text":
                    values["text"] = _cell(raw, block.value_aliases, v_alias)
                else:
                    values[i18n_col] = _cell(raw, block.value_aliases, v_alias)

            if values.get("source") is not None:
                values["source"] = str(values["source"])
            if values.get("formname") is not None:
                values["formname"] = str(values["formname"])
            if values.get("columnname") is not None:
                values["columnname"] = str(values["columnname"])
            if values.get("typevalue") is not None:
                values["typevalue"] = str(values["typevalue"])
            if values.get("layername") is not None:
                values["layername"] = str(values["layername"])
            if table == "dbstyle":
                values.pop("hint", None)
                values.pop("org_text", None)
                values.pop("lb", None)

            target_table = BASELINE_TO_MULTILANG_TABLE.get(table)
            if table == "dbbasic_tables":
                if block.context == "config_param_system":
                    target_table = "config_param_system"
                elif block.context in ("value_state", "value_state_type"):
                    target_table = block.context
                else:
                    continue
            if not target_table:
                continue
            if table == "dbconfig_typevalue" and (
                values.get("formname") is None or values.get("source") is None
            ):
                continue
            if table == "dbtypevalue" and (
                values.get("typevalue") is None or values.get("source") is None
            ):
                continue
            if table == "dbbasic_tables" and values.get("source") is None:
                continue
            if table == "dbplan_price" and values.get("source") is None:
                continue
            if table == "dbstyle" and (
                values.get("source") is None
                or values.get("layername") is None
            ):
                continue
            rows.append(MultilangRow(table=target_table, values=values))
    return rows


def build_insert_sql(
    table: str,
    rows: Sequence[MultilangRow],
    *,
    batch_size: int = 500,
    on_conflict: str = "update",
) -> list[str]:
    """Build batched INSERT statements.

    on_conflict:
      - ``update``: ON CONFLICT DO UPDATE (schema create/reseed)
      - ``nothing``: ON CONFLICT DO NOTHING
      - ``none``: plain INSERT (caller must delete existing rows first)
    """
    rows = _dedupe_rows_by_conflict_key(table, rows)
    if not rows:
        return []

    conflict_keys = _TABLE_CONFLICT_KEYS.get(table)
    if not conflict_keys:
        return []

    mode = str(on_conflict or "update").strip().lower()
    if mode not in ("update", "nothing", "none"):
        mode = "update"

    statements: list[str] = []
    for start in range(0, len(rows), batch_size):
        chunk = rows[start: start + batch_size]
        columns: list[str] = []
        seen: set[str] = set()
        for row in chunk:
            for col in row.values:
                if col not in seen:
                    seen.add(col)
                    columns.append(col)
        update_cols = [
            col for col in columns
            if col not in conflict_keys and col not in ("project_type", "context", "lang")
        ]

        values_sql: list[str] = []
        for row in chunk:
            literals = []
            for col in columns:
                val = row.values.get(col)
                as_json = col == "text" and table in (
                    "config_form_fields_json", "config_json",
                )
                literals.append(_sql_literal(val, as_json=as_json))
            values_sql.append(f"({', '.join(literals)})")

        quoted_columns = ", ".join(_quote_sql_col(col) for col in columns)
        values_clause = ", ".join(values_sql)
        if mode == "none":
            sql = (
                f"INSERT INTO multilang.{table} ({quoted_columns}) "
                f"VALUES {values_clause};"
            )
        else:
            conflict = ", ".join(_quote_sql_col(key) for key in conflict_keys)
            if mode == "nothing" or not update_cols:
                conflict_sql = f"ON CONFLICT ({conflict}) DO NOTHING"
            else:
                update_clause = ", ".join(
                    f"{_quote_sql_col(col)} = EXCLUDED.{_quote_sql_col(col)}"
                    for col in update_cols
                )
                conflict_sql = f"ON CONFLICT ({conflict}) DO UPDATE SET {update_clause}"
            sql = (
                f"INSERT INTO multilang.{table} ({quoted_columns}) "
                f"VALUES {values_clause} "
                f"{conflict_sql};"
            )
        statements.append(sql)
    return statements


def load_baseline_rows_for_project_type(
    sql_root: str,
    project_type: str,
    *,
    lang_id: str = SEED_LANGUAGE_ID,
    lang_folder: str | None = None,
) -> list[MultilangRow]:
    """Parse baseline SQL once for a project type; project_type is left empty."""
    folder = lang_folder or SEED_LANGUAGE_FOLDER
    pt = normalize_project_type(project_type)
    if not pt:
        return []

    i18n_dir = baseline_i18n_dir(sql_root, pt, lang=folder)
    if not i18n_dir or not os.path.isdir(i18n_dir):
        return []

    all_rows: list[MultilangRow] = []
    for baseline_file in _PROJECT_TYPE_TABLES.get(pt, ()):
        if not _baseline_is_seedable(baseline_file):
            continue
        path = os.path.join(i18n_dir, f"{baseline_file}.sql")
        if not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8") as handle:
            sql_text = handle.read()
        blocks = parse_update_blocks(sql_text)
        all_rows.extend(
            blocks_to_multilang_rows(
                baseline_file,
                blocks,
                project_type="",
                lang=lang_id,
            )
        )
    return all_rows


def rows_for_project_type(
    template_rows: Sequence[MultilangRow],
    project_type: str,
) -> list[MultilangRow]:
    """Shallow-copy template rows with project_type stamped."""
    pt = str(project_type or "").strip().lower()
    return [
        MultilangRow(table=row.table, values={**row.values, "project_type": pt})
        for row in template_rows
    ]


def _statements_from_rows(
    rows: Sequence[MultilangRow],
    *,
    on_conflict: str = "update",
    batch_size: int = 500,
) -> list[str]:
    by_table: dict[str, list[MultilangRow]] = {}
    for row in rows:
        by_table.setdefault(row.table, []).append(row)

    statements: list[str] = []
    for target_table in MULTILANG_UI_TABLES:
        table_rows = by_table.get(target_table) or []
        table_batch = 5 if target_table == "sys_style" else batch_size
        statements.extend(
            build_insert_sql(
                target_table,
                table_rows,
                batch_size=table_batch,
                on_conflict=on_conflict,
            )
        )
    return statements


def seed_sql_for_project_types(
    sql_root: str,
    project_types: Sequence[str],
    *,
    lang: str = SEED_LANGUAGE_ID,
    on_conflict: str = "update",
    batch_size: int = 500,
) -> list[tuple[str, list[str]]]:
    """Build seed SQL for many project types, parsing each baseline once.

    Returns a list of ``(project_type, statements)`` in the same order as
    ``project_types``.
    """
    lang_id = normalize_language_id(lang)
    lang_folder = normalize_language_folder(lang)

    templates: dict[str, list[MultilangRow]] = {}
    result: list[tuple[str, list[str]]] = []
    for project_type in project_types:
        pt = normalize_project_type(project_type)
        if not pt:
            result.append((str(project_type or ""), []))
            continue
        if pt not in templates:
            templates[pt] = load_baseline_rows_for_project_type(
                sql_root,
                pt,
                lang_id=lang_id,
                lang_folder=lang_folder,
            )
        template = templates[pt]
        if not template:
            result.append((pt, []))
            continue
        rows = rows_for_project_type(template, pt)
        result.append(
            (
                pt,
                _statements_from_rows(
                    rows, on_conflict=on_conflict, batch_size=batch_size,
                ),
            )
        )
    return result


_fingerprint_cache: dict[str, str] = {}


def invalidate_baseline_fingerprint_cache(sql_root: str | None = None) -> None:
    """Drop cached baseline fingerprints (all, or for one sql_root)."""
    if sql_root is None:
        _fingerprint_cache.clear()
    else:
        _fingerprint_cache.pop(sql_root, None)


def compute_baseline_fingerprint(sql_root: str) -> str:
    """Fingerprint of bundled en_US baseline SQL files (content + mtime)."""
    cached = _fingerprint_cache.get(sql_root)
    if cached is not None:
        return cached

    digest = hashlib.sha256()
    for pt in sorted(TRANSLATABLE_PROJECT_TYPES):
        table_files = seed_table_files_for_project_type(pt, sql_root)
        if not table_files:
            continue
        digest.update(pt.encode("utf-8"))
        i18n_dir = baseline_i18n_dir(sql_root, pt)
        if not i18n_dir:
            continue
        for baseline_file in table_files:
            path = os.path.join(i18n_dir, f"{baseline_file}.sql")
            digest.update(baseline_file.encode("utf-8"))
            digest.update(str(os.path.getmtime(path)).encode("utf-8"))
            with open(path, "rb") as handle:
                for chunk in iter(lambda: handle.read(65536), b""):
                    digest.update(chunk)
    fingerprint = digest.hexdigest()
    _fingerprint_cache[sql_root] = fingerprint
    return fingerprint


def baseline_needs_reseed(sql_root: str, stored_fingerprint: str | None) -> bool:
    if not stored_fingerprint:
        return True
    return compute_baseline_fingerprint(sql_root) != stored_fingerprint


def parse_stored_seeded_project_types(addparam: Any) -> set[str]:
    """Read seeded project types from multilang.sys_version.addparam."""
    if not addparam:
        return set()
    try:
        data = json.loads(addparam) if isinstance(addparam, str) else addparam
    except (TypeError, ValueError):
        return set()
    if not isinstance(data, dict):
        return set()
    raw = data.get("seeded_project_types")
    if raw is None:
        # Backward compatible with older addparam payloads.
        raw = data.get("seeded_schemas") or []
    if not isinstance(raw, list):
        return set()
    return {str(name).strip().lower() for name in raw if name}


def fetch_seeded_project_types_from_multilang(
    fetcher: Callable[[str, Optional[list]], Optional[list[tuple]]],
) -> set[str]:
    """Return project types that currently have rows in multilang seed tables."""
    if not MULTILANG_UI_TABLES:
        return set()
    parts = [
        f"SELECT project_type FROM multilang.{table} "
        "WHERE project_type IS NOT NULL AND BTRIM(project_type) <> ''"
        for table in MULTILANG_UI_TABLES
    ]
    sql = (
        "SELECT DISTINCT lower(btrim(project_type)) FROM ("
        + " UNION ALL ".join(parts)
        + ") AS seeded"
    )
    rows = fetcher(sql, None)
    if not rows:
        return set()
    return {str(row[0]).strip().lower() for row in rows if row and row[0]}


def delete_project_type_seed_sql(project_types: Iterable[str]) -> list[str]:
    """Build DELETE statements for removed project types."""
    statements: list[str] = []
    for project_type in project_types:
        esc = str(project_type).replace("'", "''").strip().lower()
        if not esc:
            continue
        for table in MULTILANG_UI_TABLES:
            statements.append(
                f"DELETE FROM multilang.{table} WHERE project_type = '{esc}';"
            )
    return statements


def _locale_display_name(lang_id: str, folder: str) -> str | None:
    """Return display name from bundled locales.sqlite locales table, if available."""
    try:
        import sqlite3

        # core/admin/i18n -> plugin root is three levels up.
        plugin_dir = os.path.abspath(
            os.path.join(os.path.dirname(__file__), os.pardir, os.pardir, os.pardir)
        )
        db_path = os.path.join(plugin_dir, "resources", "gis", "locales.sqlite")
        if not os.path.isfile(db_path):
            return None
        with sqlite3.connect(db_path) as conn:
            row = conn.execute(
                "SELECT name FROM locales WHERE locale = ? OR lower(locale) = ? LIMIT 1",
                (folder, lang_id),
            ).fetchone()
        if row and row[0]:
            return str(row[0])
    except Exception:
        return None
    return None


def ensure_cat_language_sql(lang: str, idval: str | None = None) -> str:
    """INSERT ON CONFLICT DO NOTHING for multilang.cat_language."""
    lang_id = normalize_language_id(lang)
    if idval is not None:
        complete_name = idval
    else:
        folder = normalize_language_folder(lang)
        complete_name = _locale_display_name(lang_id, folder) or folder
    esc_id = lang_id.replace("'", "''")
    esc_val = str(complete_name).replace("'", "''")
    return (
        f"INSERT INTO multilang.cat_language (id, idval) "
        f"VALUES ('{esc_id}', '{esc_val}') "
        "ON CONFLICT (id) DO NOTHING;"
    )


def build_multilang_user_preference_sql(
    schema_name: str,
    language: str,
    *,
    sql_schema_name: str | None = None,
    is_default: bool = False,
) -> str:
    """Build SQL to upsert or clear multilang_language in config_param_user."""
    schema_sql = (sql_schema_name or str(schema_name or "")).strip()
    if not schema_sql:
        return ""
    if is_default or str(language or "").strip().lower() == "default":
        return (
            f"DELETE FROM {schema_sql}.config_param_user "
            "WHERE parameter = 'multilang_language' AND cur_user = current_user;"
        )
    lang_id = normalize_language_id(language).replace("'", "''")
    return (
        ensure_cat_language_sql(language)
        + f"INSERT INTO {schema_sql}.config_param_user (parameter, value, cur_user) "
        f"VALUES ('multilang_language', '{lang_id}', current_user) "
        "ON CONFLICT (parameter, cur_user) DO UPDATE SET value = EXCLUDED.value;"
    )


def multilang_user_param_provision_sql(
    *,
    enable: bool,
    schema_name: str | None = None,
) -> str:
    """Enable or disable multilang_language widgets on network schemas."""
    schema_arg = "NULL"
    if schema_name:
        esc_schema = str(schema_name).replace("'", "''")
        schema_arg = f"'{esc_schema}'"
    return (
        "SELECT multilang.gw_fct_admin_multilang_user_param("
        f"{'true' if enable else 'false'}, {schema_arg});"
    )



_MULTILANG_VIEW_FCT_FILES: tuple[str, ...] = (
    "gw_fct_admin_build_multilang_view_sql.sql",
    "gw_fct_admin_manage_multilang_views.sql",
)


def _multilang_fct_dir() -> str:
    plugin_dir = os.path.abspath(
        os.path.join(os.path.dirname(__file__), os.pardir, os.pardir, os.pardir)
    )
    return os.path.join(
        plugin_dir, "dbmodel", "schemas", "addon", "multilang", "base", "fct"
    )


def ensure_multilang_tables_ddl() -> str:
    """CREATE TABLE IF NOT EXISTS for multilang tables added after the first install."""
    return """
DO $BODY$
BEGIN
    IF to_regnamespace('multilang') IS NULL THEN
        RETURN;
    END IF;

    CREATE TABLE IF NOT EXISTS multilang.config_typevalue (
        id serial4 NOT NULL,
        project_type text NOT NULL,
        context text NOT NULL,
        formname text NOT NULL,
        "source" text NOT NULL,
        lang text NOT NULL DEFAULT 'en_us',
        tt text NULL,
        updated_by text DEFAULT CURRENT_USER NULL,
        updated_on timestamptz DEFAULT now() NULL,
        CONSTRAINT config_typevalue_id_uniq UNIQUE (id),
        CONSTRAINT config_typevalue_pkey PRIMARY KEY (project_type, context, formname, "source", lang),
        CONSTRAINT config_typevalue_lang_fkey FOREIGN KEY (lang) REFERENCES multilang.cat_language(id)
    );

    CREATE INDEX IF NOT EXISTS idx_config_typevalue_lang
        ON multilang.config_typevalue USING btree (lang);

    GRANT SELECT ON TABLE multilang.config_typevalue TO role_basic;

    CREATE TABLE IF NOT EXISTS multilang.typevalue (
        id serial4 NOT NULL,
        project_type text NOT NULL,
        context text NOT NULL,
        typevalue text NOT NULL,
        "source" text NOT NULL,
        lang text NOT NULL DEFAULT 'en_us',
        vl text NULL,
        ds text NULL,
        updated_by text DEFAULT CURRENT_USER NULL,
        updated_on timestamptz DEFAULT now() NULL,
        CONSTRAINT typevalue_id_uniq UNIQUE (id),
        CONSTRAINT typevalue_pkey PRIMARY KEY (project_type, context, typevalue, "source", lang),
        CONSTRAINT typevalue_lang_fkey FOREIGN KEY (lang) REFERENCES multilang.cat_language(id)
    );

    CREATE INDEX IF NOT EXISTS idx_typevalue_lang
        ON multilang.typevalue USING btree (lang);

    GRANT SELECT ON TABLE multilang.typevalue TO role_basic;

    CREATE TABLE IF NOT EXISTS multilang.config_visit_parameter (
        id serial4 NOT NULL,
        project_type text NOT NULL,
        context text NOT NULL,
        "source" text NOT NULL,
        lang text NOT NULL DEFAULT 'en_us',
        ds text NULL,
        updated_by text DEFAULT CURRENT_USER NULL,
        updated_on timestamptz DEFAULT now() NULL,
        CONSTRAINT config_visit_parameter_id_uniq UNIQUE (id),
        CONSTRAINT config_visit_parameter_pkey PRIMARY KEY (project_type, context, "source", lang),
        CONSTRAINT config_visit_parameter_lang_fkey FOREIGN KEY (lang) REFERENCES multilang.cat_language(id)
    );

    CREATE INDEX IF NOT EXISTS idx_config_visit_parameter_lang
        ON multilang.config_visit_parameter USING btree (lang);

    GRANT SELECT ON TABLE multilang.config_visit_parameter TO role_basic;

    ALTER TABLE multilang.config_param_system ADD COLUMN IF NOT EXISTS vl text NULL;

    CREATE TABLE IF NOT EXISTS multilang.value_state (
        id serial4 NOT NULL,
        project_type text NOT NULL,
        context text NOT NULL,
        "source" text NOT NULL,
        lang text NOT NULL DEFAULT 'en_us',
        na text NULL,
        ob text NULL,
        updated_by text DEFAULT CURRENT_USER NULL,
        updated_on timestamptz DEFAULT now() NULL,
        CONSTRAINT value_state_id_uniq UNIQUE (id),
        CONSTRAINT value_state_pkey PRIMARY KEY (project_type, context, "source", lang),
        CONSTRAINT value_state_lang_fkey FOREIGN KEY (lang) REFERENCES multilang.cat_language(id)
    );

    CREATE INDEX IF NOT EXISTS idx_value_state_lang
        ON multilang.value_state USING btree (lang);

    GRANT SELECT ON TABLE multilang.value_state TO role_basic;

    CREATE TABLE IF NOT EXISTS multilang.value_state_type (
        id serial4 NOT NULL,
        project_type text NOT NULL,
        context text NOT NULL,
        "source" text NOT NULL,
        lang text NOT NULL DEFAULT 'en_us',
        na text NULL,
        updated_by text DEFAULT CURRENT_USER NULL,
        updated_on timestamptz DEFAULT now() NULL,
        CONSTRAINT value_state_type_id_uniq UNIQUE (id),
        CONSTRAINT value_state_type_pkey PRIMARY KEY (project_type, context, "source", lang),
        CONSTRAINT value_state_type_lang_fkey FOREIGN KEY (lang) REFERENCES multilang.cat_language(id)
    );

    CREATE INDEX IF NOT EXISTS idx_value_state_type_lang
        ON multilang.value_state_type USING btree (lang);

    GRANT SELECT ON TABLE multilang.value_state_type TO role_basic;

    CREATE TABLE IF NOT EXISTS multilang.plan_price (
        id serial4 NOT NULL,
        project_type text NOT NULL,
        context text NOT NULL,
        "source" text NOT NULL,
        lang text NOT NULL DEFAULT 'en_us',
        ds text NULL,
        tx text NULL,
        pr text NULL,
        updated_by text DEFAULT CURRENT_USER NULL,
        updated_on timestamptz DEFAULT now() NULL,
        CONSTRAINT plan_price_id_uniq UNIQUE (id),
        CONSTRAINT plan_price_pkey PRIMARY KEY (project_type, context, "source", lang),
        CONSTRAINT plan_price_lang_fkey FOREIGN KEY (lang) REFERENCES multilang.cat_language(id)
    );

    CREATE INDEX IF NOT EXISTS idx_plan_price_lang
        ON multilang.plan_price USING btree (lang);

    GRANT SELECT ON TABLE multilang.plan_price TO role_basic;

    IF to_regclass('multilang.sys_style') IS NOT NULL
       AND EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'multilang'
              AND table_name = 'sys_style'
              AND column_name = 'hint'
       )
    THEN
        DROP TABLE multilang.sys_style;
    END IF;

    CREATE TABLE IF NOT EXISTS multilang.sys_style (
        id serial4 NOT NULL,
        project_type text NOT NULL,
        context text NOT NULL,
        "source" text NOT NULL,
        layername text NOT NULL,
        lang text NOT NULL DEFAULT 'en_us',
        tx text NULL,
        updated_by text DEFAULT CURRENT_USER NULL,
        updated_on timestamptz DEFAULT now() NULL,
        CONSTRAINT sys_style_id_uniq UNIQUE (id),
        CONSTRAINT sys_style_pkey PRIMARY KEY (project_type, context, "source", layername, lang),
        CONSTRAINT sys_style_lang_fkey FOREIGN KEY (lang) REFERENCES multilang.cat_language(id)
    );

    ALTER TABLE multilang.sys_style ADD COLUMN IF NOT EXISTS tx text NULL;

    CREATE INDEX IF NOT EXISTS idx_sys_style_lang
        ON multilang.sys_style USING btree (lang);

    GRANT SELECT ON TABLE multilang.sys_style TO role_basic;
END
$BODY$;
"""


def multilang_view_functions_ddl() -> str:
    """CREATE OR REPLACE the view helper functions from plugin SQL files."""
    fct_dir = _multilang_fct_dir()
    chunks: list[str] = []
    for fname in _MULTILANG_VIEW_FCT_FILES:
        path = os.path.join(fct_dir, fname)
        with open(path, encoding="utf-8") as handle:
            chunks.append(handle.read().replace("SCHEMA_NAME", "multilang"))
    return "\n".join(chunks)


def multilang_views_provision_sql(
    *,
    enable: bool,
    schema_name: str | None = None,
) -> str:
    """Recreate UI translation views (JOIN when enable, plain when disable)."""
    schema_arg = "NULL"
    if schema_name:
        esc_schema = str(schema_name).replace("'", "''")
        schema_arg = f"'{esc_schema}'"
    return (
        "SELECT multilang.gw_fct_admin_manage_multilang_views("
        f"{'true' if enable else 'false'}, {schema_arg});"
    )


def _coerce_json_result(json_result: Any) -> dict[str, Any] | None:
    if json_result is None:
        return None
    if isinstance(json_result, dict):
        return json_result
    if isinstance(json_result, str):
        try:
            parsed = json.loads(json_result)
        except (TypeError, ValueError):
            return None
        return parsed if isinstance(parsed, dict) else None
    return None


def multilang_json_error_message(
    json_result: Any,
    *,
    sql: str | None = None,
) -> str:
    """Build a user-facing message from a multilang admin function JSON result."""
    data = _coerce_json_result(json_result)
    if not data:
        msg = "Empty response from database function."
        return msg

    message = data.get("message")
    if isinstance(message, dict) and message.get("text"):
        text = str(message["text"])
    elif isinstance(message, str):
        text = message
    else:
        text = ""

    errors = data.get("errors")
    if isinstance(errors, list) and errors:
        details: list[str] = []
        for item in errors[:5]:
            if not isinstance(item, dict):
                continue
            schema = item.get("schema") or "?"
            view = item.get("view")
            table = item.get("table")
            err = item.get("error") or item.get("NOSQLERR") or item.get("SQLERRM") or "unknown error"
            target = view or table or schema
            details.append(f"{schema}.{target}: {err}")
        if details:
            suffix = "; ".join(details)
            if len(errors) > 5:
                suffix += f"; ... ({len(errors) - 5} more)"
            text = f"{text} {suffix}".strip() if text else suffix

    if text:
        return text

    for key in ("SQLERR", "NOSQLERR", "SQLERRM"):
        if data.get(key):
            return str(data[key])

    if sql:
        msg = "Multilang function failed. SQL: {0}"
        msg = msg.format(sql)
        return msg
    msg = "Multilang function failed."
    return msg


def run_multilang_function_sql(
    sql: str,
    *,
    aux_conn: Any = None,
    adapter: Any = None,
    is_thread: bool = False,
    show_exception: bool = True,
    log_sql: bool = False,
) -> tuple[dict[str, Any] | None, bool]:
    """Execute a multilang admin function returning json and interpret its status."""
    from ....libs import lib_vars, tools_db, tools_log

    json_result: dict[str, Any] | None = None

    if adapter is not None:
        value, ok = adapter.execute_scalar(sql)
        if not ok:
            err = adapter.last_error() or "SQL execution failed."
            lib_vars.session_vars["last_error"] = err
            lib_vars.session_vars["last_error_msg"] = err
            msg = "Multilang function SQL failed"
            tools_log.log_warning(msg, parameter=err)
            return None, False
        json_result = _coerce_json_result(value)
    else:
        row = tools_db.get_row(
            sql,
            commit=True,
            log_sql=log_sql,
            aux_conn=aux_conn,
            is_thread=is_thread,
        )
        if not row or row[0] is None:
            message = "SQL execution failed."
            err = lib_vars.session_vars.get("last_error") or message
            lib_vars.session_vars["last_error_msg"] = err
            msg = "Multilang function SQL failed"
            tools_log.log_warning(msg, parameter=err)
            return None, False
        json_result = _coerce_json_result(row[0])

    if not json_result:
        msg = "Multilang function returned an invalid JSON response."
        lib_vars.session_vars["last_error"] = msg
        lib_vars.session_vars["last_error_msg"] = msg
        tools_log.log_warning(msg, parameter=sql)
        return None, False

    if log_sql:
        msg = "Multilang function response"
        tools_log.log_db(json_result, header=msg)

    status = json_result.get("status")
    if status == "Failed":
        err = multilang_json_error_message(json_result, sql=sql)
        lib_vars.session_vars["last_error"] = err
        lib_vars.session_vars["last_error_msg"] = err
        msg = "Multilang function failed"
        tools_log.log_warning(msg, parameter=err)
        if show_exception and not is_thread:
            from ...utils import tools_gw

            tools_gw.manage_json_exception(json_result, sql=sql, is_thread=is_thread)
        return json_result, False

    if status != "Accepted":
        err = multilang_json_error_message(json_result, sql=sql)
        lib_vars.session_vars["last_error"] = err
        lib_vars.session_vars["last_error_msg"] = err
        msg = "Multilang function returned unexpected status"
        tools_log.log_warning(msg, parameter=err)
        if show_exception and not is_thread:
            from ...utils import tools_gw

            tools_gw.manage_json_exception(json_result, sql=sql, is_thread=is_thread)
        return json_result, False

    message = json_result.get("message")
    if isinstance(message, dict) and message.get("text"):
        tools_log.log_info(str(message["text"]))
    return json_result, True


def build_change_lang_sql(
    schema_name: str,
    language: str,
    *,
    multilang_exists: bool,
    project_type: str | None = None,
    sql_schema_name: str | None = None,
) -> str:
    """Build SQL to update project language and optional multilang user preference.

    When ``multilang_exists`` is False, only ``sys_version.language`` is updated.
    Preference is stored in the network schema config_param_user row.
    """
    lang = str(language or "").replace("'", "''")
    schema_sql = (sql_schema_name or str(schema_name or "")).strip()
    schema_value = str(schema_name or "").replace('"', "").replace("'", "''").strip()
    pt = normalize_project_type(project_type) or ""
    statements = [f"UPDATE {schema_sql}.sys_version SET language = '{lang}';"]
    if multilang_exists and schema_value and pt:
        statements.append(
            build_multilang_user_preference_sql(
                schema_name,
                language,
                sql_schema_name=schema_sql,
            )
        )
    return "".join(statements)


def delete_language_seed_sql(lang: str, *, drop_catalog: bool = True) -> list[str]:
    """Build DELETE statements for one language across multilang seed tables."""
    lang_id = normalize_language_id(lang)
    esc = lang_id.replace("'", "''")
    statements: list[str] = []
    for table in MULTILANG_UI_TABLES:
        statements.append(f"DELETE FROM multilang.{table} WHERE lang = '{esc}';")
    if drop_catalog:
        statements.append(f"DELETE FROM multilang.cat_language WHERE id = '{esc}';")
    return statements


def fetch_seeded_language_ids(
    fetcher: Callable[[str, Optional[list]], Optional[list[tuple]]],
) -> set[str]:
    """Return language ids present in multilang.cat_language."""
    rows = fetcher("SELECT id FROM multilang.cat_language", None)
    if not rows:
        return set()
    return {normalize_language_id(str(row[0])) for row in rows if row and row[0]}


def language_baselines_exist(sql_root: str, lang: str) -> bool:
    """True when at least one project type has bundled SQL for this language folder."""
    lang_folder = normalize_language_folder(lang)
    return any(
        project_type_has_baseline(sql_root, pt, lang=lang_folder)
        for pt in TRANSLATABLE_PROJECT_TYPES
    )


def seeded_project_types_out_of_sync(current: set[str], stored: set[str]) -> bool:
    """True when project-type sets differ from the last multilang seed."""
    return {str(x).lower() for x in (current or ())} != {str(x).lower() for x in (stored or ())}


def translatable_project_types_with_baseline(sql_root: str) -> list[str]:
    """Return sorted project types that have bundled baseline SQL."""
    return sorted(
        pt
        for pt in TRANSLATABLE_PROJECT_TYPES
        if project_type_has_baseline(sql_root, pt)
    )
