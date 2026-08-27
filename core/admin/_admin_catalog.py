"""
Fast pg_catalog queries for the admin dialog (avoid information_schema + N+1).
"""

from __future__ import annotations

import json
import os
from datetime import date, datetime
from typing import Any, Callable, Iterable, Optional

from ...libs import tools_db

RowFetcher = Callable[[str, Optional[list]], Optional[list[tuple]]]

_SCHEMAS_WITH_SYS_VERSION = """
SELECT n.nspname
FROM pg_catalog.pg_namespace n
JOIN pg_catalog.pg_class c ON c.relnamespace = n.oid
WHERE c.relname = 'sys_version'
  AND c.relkind = 'r'
  AND n.nspname NOT LIKE 'pg_%%'
  AND n.nspname <> 'information_schema'
ORDER BY n.nspname
"""

_AUX_SCHEMAS = """
SELECT nspname
FROM pg_catalog.pg_namespace
WHERE nspname = ANY(ARRAY['am', 'cm', 'audit'])
"""


def _tools_db_fetch(sql: str, params: Optional[list] = None) -> Optional[list[tuple]]:
    rows = tools_db.get_rows(sql, commit=False, params=params, log_info=False)
    if rows is None and tools_db.dao and tools_db.dao.last_error:
        tools_db.dao.rollback()
    return rows


def _tools_db_fetch_per_schema(sql: str, params: Optional[list] = None) -> Optional[list[tuple]]:
    """Like _tools_db_fetch but skips permission errors on individual schema probes."""
    rows = tools_db.get_rows(sql, commit=False, params=params, log_info=False, is_thread=True)
    if rows is None and tools_db.dao and tools_db.dao.last_error:
        tools_db.dao.rollback()
    return rows


def _quote_ident(name: str) -> str:
    return '"' + str(name).replace('"', '""') + '"'


def _quote_literal(name: str) -> str:
    return "'" + str(name).replace("'", "''") + "'"


def fetch_schema_names_with_sys_version(fetcher: RowFetcher = _tools_db_fetch) -> list[str]:
    rows = fetcher(_SCHEMAS_WITH_SYS_VERSION, None)
    if not rows:
        return []
    return [str(row[0]) for row in rows]


def fetch_sys_version_schemas(
    project_type: Optional[str] = None,
    fetcher: RowFetcher = _tools_db_fetch_per_schema,
) -> list[tuple[str, str]]:
    """Return [(schema_name, project_type), ...] for accessible ws/ud-like schemas.

    Always probe project_type via @fetcher (same connection as the schema list).
    Default fetcher suppresses per-schema permission errors on the main dao.
    """
    schema_names = fetch_schema_names_with_sys_version(fetcher)
    if not schema_names:
        return []

    result: list[tuple[str, str]] = []
    for schema_name in schema_names:
        if schema_name in _SATELLITE_SCHEMAS:
            continue
        rows = fetcher(
            f"SELECT project_type FROM {_quote_ident(schema_name)}.sys_version LIMIT 1",
            None,
        )
        if rows and rows[0] and rows[0][0] is not None:
            result.append((str(schema_name), str(rows[0][0])))

    if project_type is None:
        return result

    want = project_type.upper()
    return [(s, pt) for s, pt in result if str(pt).upper() == want]


def fetch_aux_schema_flags(fetcher: RowFetcher = _tools_db_fetch) -> dict[str, bool]:
    rows = fetcher(_AUX_SCHEMAS, None)
    present = {str(row[0]) for row in rows} if rows else set()
    return {
        "am": "am" in present,
        "cm": "cm" in present,
        "audit": "audit" in present,
    }


def schema_exists(name: str, fetcher: RowFetcher = _tools_db_fetch) -> bool:
    row = fetcher("SELECT to_regnamespace(%s) IS NOT NULL", [name])
    return bool(row and row[0] and row[0][0])


def is_audit_fully_installed(fetcher: RowFetcher = _tools_db_fetch) -> bool:
    """True when full audit DDL is present (not just the CM dependency stub)."""
    row = fetcher("SELECT to_regclass('audit.log') IS NOT NULL", None)
    return bool(row and row[0] and row[0][0])


def is_audit_stub(fetcher: RowFetcher = _tools_db_fetch) -> bool:
    """True when audit namespace exists but full audit structure was never loaded."""
    return schema_exists("audit", fetcher) and not is_audit_fully_installed(fetcher)


def schema_names_matching(pattern: str, fetcher: RowFetcher = _tools_db_fetch) -> list[str]:
    """ILIKE match on namespace names (pg_catalog)."""
    sql = """
        SELECT nspname
        FROM pg_catalog.pg_namespace
        WHERE nspname ILIKE %s
        ORDER BY nspname
    """
    rows = fetcher(sql, [pattern])
    if not rows:
        return []
    return [str(row[0]) for row in rows]


def find_cm_schema(fetcher: RowFetcher = _tools_db_fetch) -> Optional[str]:
    for schema_name, project_type in fetch_sys_version_schemas(fetcher=fetcher):
        if str(project_type).lower() == "cm":
            return schema_name
    return None


def make_psycopg2_fetcher(conn: Any) -> RowFetcher:
    """Build a RowFetcher from an open psycopg2 connection (worker thread)."""

    def _fetch(sql: str, params: Optional[list] = None) -> Optional[list[tuple]]:
        try:
            with conn.cursor() as cur:
                cur.execute(sql, params or ())
                return cur.fetchall()
        except Exception:
            try:
                conn.rollback()
            except Exception:
                pass
            return None

    return _fetch


def combo_items_for_project_type(
    schemas: Iterable[tuple[str, str]],
    project_type: str,
) -> list[list[str]]:
    want = project_type.upper()
    return [[s, s] for s, pt in schemas if str(pt).upper() == want]


def combo_items_all_schemas(schemas: Iterable[tuple[str, str]]) -> list[list[str]]:
    """Return [[schema_name, display_label], ...] for ws/ud schemas."""
    return [
        [name, f"({str(pt).upper()}) - {name}"]
        for name, pt in schemas
        if str(pt).upper() in ("WS", "UD")
    ]


def project_type_for_schema(
    schemas: Iterable[tuple[str, str]],
    schema_name: str,
) -> Optional[str]:
    for name, pt in schemas:
        if str(name) == str(schema_name):
            return str(pt).lower()
    return None


_SATELLITE_SCHEMAS = frozenset({"multilang", "utils", "cibs", "am", "cm", "audit"})

_SYS_VERSION_COLUMNS = """
SELECT n.nspname, a.attname
FROM pg_catalog.pg_namespace n
JOIN pg_catalog.pg_class c ON c.relnamespace = n.oid
JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid
WHERE c.relname = 'sys_version'
  AND c.relkind IN ('r', 'p')
  AND n.nspname = ANY(%s::text[])
  AND a.attname = ANY(ARRAY['giswater', 'version', 'addparam', 'date', 'language', 'project_type'])
  AND a.attnum > 0
  AND NOT a.attisdropped
"""


def _format_sys_version_date(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, (datetime, date)):
        if isinstance(value, date) and not isinstance(value, datetime):
            value = datetime.combine(value, datetime.min.time())
        return value.strftime("%d-%m-%Y %H:%M:%S")
    return str(value)


def _inventory_date_fields(created_raw: Any, updated_raw: Any) -> dict[str, str]:
    date_created = _format_sys_version_date(created_raw)
    date_updated = _format_sys_version_date(updated_raw)
    if date_created and date_updated and date_created == date_updated:
        date_updated = ""
    return {"date_created": date_created, "date_updated": date_updated}


def _sys_version_columns_by_schema(
    schema_names: Iterable[str],
    fetcher: RowFetcher,
) -> dict[str, set[str]]:
    names = list(schema_names)
    if not names:
        return {}
    rows = fetcher(_SYS_VERSION_COLUMNS, [names])
    result: dict[str, set[str]] = {name: set() for name in names}
    if not rows:
        return result
    for schema_name, column_name in rows:
        result.setdefault(str(schema_name), set()).add(str(column_name))
    return result


def _version_column_for_schema(schema_name: str, columns: set[str]) -> str:
    if schema_name in _SATELLITE_SCHEMAS:
        for col in ("version", "giswater"):
            if col in columns:
                return col
    else:
        for col in ("giswater", "version"):
            if col in columns:
                return col
    return ""


def _fetch_sys_version_addparam(
    schema_name: str,
    fetcher: RowFetcher,
    *,
    columns: set[str] | None = None,
) -> dict[str, Any]:
    """Return parsed addparam when the column exists; {} otherwise."""
    if columns is None:
        columns = _sys_version_columns_by_schema([schema_name], fetcher).get(schema_name, set())
    if "addparam" not in columns:
        return {}
    row = fetcher(
        f"SELECT addparam FROM {_quote_ident(schema_name)}.sys_version "
        "ORDER BY id DESC LIMIT 1",
        None,
    )
    if not row or not row[0]:
        return {}
    return _parse_addparam(row[0][0])


def _parse_addparam(addparam: Any) -> dict[str, Any]:
    if isinstance(addparam, dict):
        return addparam
    if addparam:
        try:
            parsed = json.loads(addparam)
            if isinstance(parsed, dict):
                return parsed
        except (TypeError, ValueError):
            pass
    return {}


def _format_linked_entry(kind: str, schema: str) -> str:
    kind_l = str(kind or "").lower()
    schema_s = str(schema or kind or "").lower()
    if not kind_l:
        return schema_s
    if schema_s == kind_l:
        return kind_l
    return f"{kind_l}:{schema_s}"


def _entry_from_sys_version_row(
    schema_name: str,
    project_type: Any,
    version: Any,
    addparam: Any,
) -> dict[str, Any]:
    entry: dict[str, Any] = {
        "schema": schema_name,
        "kind": str(project_type or ""),
        "version": str(version or ""),
        "profile": "",
        "linked": "",
        "date_created": "",
        "date_updated": "",
    }
    ap = _parse_addparam(addparam)
    env = ap.get("environment") or {}
    if isinstance(env, dict):
        entry["profile"] = str(env.get("creation_profile") or "")

    if ap.get("parent_schemas"):
        entry["linked"] = ", ".join(str(x) for x in ap.get("parent_schemas") or [])
    elif ap.get("network_parents"):
        linked = []
        for kind, schemas in (ap.get("network_parents") or {}).items():
            for schema in schemas or []:
                linked.append(_format_linked_entry(str(kind), str(schema)))
        entry["linked"] = ", ".join(linked)
    elif ap.get("satellites"):
        linked = []
        for kind, meta in (ap.get("satellites") or {}).items():
            if isinstance(meta, dict) and meta.get("enabled"):
                linked.append(_format_linked_entry(str(kind), str(meta.get("schema", kind))))
        entry["linked"] = ", ".join(linked)
    return entry


def _append_linked_satellite(linked: str, satellite: str, schema: str) -> str:
    sat_l = satellite.lower()
    parts = [part.strip() for part in linked.split(",") if part.strip()]
    if any(
        part.lower() == sat_l or part.lower().startswith(f"{sat_l}:")
        for part in parts
    ):
        return ", ".join(parts)
    parts.append(_format_linked_entry(satellite, schema))
    return ", ".join(parts)


def _legacy_parent_satellites(
    schema_name: str,
    fetcher: RowFetcher,
) -> list[tuple[str, str]]:
    """Map legacy config_param_system flags to (satellite, schema) pairs."""
    linked: list[tuple[str, str]] = []
    row = fetcher(
        f"SELECT value FROM {_quote_ident(schema_name)}.config_param_system "
        "WHERE parameter = 'admin_cibs_schema' LIMIT 1",
        None,
    )
    if row and row[0] and str(row[0][0]).lower() in ("true", "t", "1"):
        linked.append(("cibs", "cibs"))
    return linked


def register_parent_satellite_enabled(
    parent_schema: str,
    satellite: str,
    *,
    satellite_schema: str | None = None,
    gw_version: str | None = None,
    fetcher: RowFetcher = _tools_db_fetch,
) -> bool:
    """Mark a satellite as enabled on a WS/UD parent sys_version row."""
    if not parent_schema:
        return False
    if gw_version is None:
        row = fetcher(
            f"SELECT giswater FROM {_quote_ident(parent_schema)}.sys_version "
            "ORDER BY id DESC LIMIT 1",
            None,
        )
        gw_version = str(row[0][0]) if row and row[0] and row[0][0] else ""
    sat_schema = satellite_schema or satellite
    payload = json.dumps(
        {
            "data": {
                "gwVersion": gw_version,
                "mergeAddparam": {
                    "satellites": {
                        satellite.lower(): {
                            "enabled": True,
                            "schema": sat_schema,
                        }
                    }
                },
            }
        },
        ensure_ascii=False,
    )
    sql = (
        f"SELECT {_quote_ident(parent_schema)}.gw_fct_admin_sys_version_register("
        f"$${payload}$$)"
    )
    try:
        row = fetcher(sql, None)
    except Exception:
        return False
    return row is not None


def fetch_schema_inventory(fetcher: RowFetcher = _tools_db_fetch) -> list[dict[str, Any]]:
    """Unified schema list for Manage schemas dialog."""
    names = set(fetch_schema_names_with_sys_version(fetcher))
    for satellite in _SATELLITE_SCHEMAS:
        if schema_exists(satellite, fetcher):
            names.add(satellite)

    if not names:
        return []

    columns_by_schema = _sys_version_columns_by_schema(names, fetcher)
    inventory: list[dict[str, Any]] = []

    for schema_name in sorted(names):
        empty_entry: dict[str, Any] = {
            "schema": schema_name,
            "kind": "",
            "version": "",
            "profile": "",
            "linked": "",
            "date_created": "",
            "date_updated": "",
        }
        columns = columns_by_schema.get(schema_name, set())
        version_col = _version_column_for_schema(schema_name, columns)
        if not version_col:
            inventory.append(empty_entry)
            continue
        select_cols = ["project_type", version_col]
        if "addparam" in columns:
            select_cols.append("addparam")
        if "date" in columns:
            qn = _quote_ident(schema_name)
            select_cols.extend([
                f"(SELECT date FROM {qn}.sys_version ORDER BY id ASC LIMIT 1)",
                f"(SELECT date FROM {qn}.sys_version ORDER BY id DESC LIMIT 1)",
            ])

        row = fetcher(
            f"SELECT {', '.join(select_cols)} "
            f"FROM {_quote_ident(schema_name)}.sys_version "
            "ORDER BY id DESC LIMIT 1",
            None,
        )
        if not row or not row[0]:
            inventory.append(empty_entry)
            continue

        values = row[0]
        addparam = None
        next_idx = 2
        if "addparam" in columns and len(values) > 2:
            addparam = values[2]
            next_idx = 3
        entry = _entry_from_sys_version_row(schema_name, values[0], values[1], addparam)
        if "date" in columns and len(values) > next_idx + 1:
            entry.update(_inventory_date_fields(values[next_idx], values[next_idx + 1]))
        if str(entry.get("kind") or "").upper() in ("WS", "UD"):
            linked = str(entry.get("linked") or "")
            for satellite, sat_schema in _legacy_parent_satellites(schema_name, fetcher):
                linked = _append_linked_satellite(linked, satellite, sat_schema)
            entry["linked"] = linked
        inventory.append(entry)

    return inventory


def get_utils_network_parents(fetcher: RowFetcher = _tools_db_fetch) -> dict[str, list[str]]:
    """Read WS/UD parent schemas from utils.sys_version.addparam (legacy config fallback)."""
    result: dict[str, list[str]] = {"ws": [], "ud": []}
    if not schema_exists("utils", fetcher):
        return result

    ap = _fetch_sys_version_addparam("utils", fetcher)
    network = ap.get("network_parents") or {}
    if isinstance(network, dict):
        for kind in ("ws", "ud"):
            values = network.get(kind) or []
            if isinstance(values, list):
                result[kind] = [str(v) for v in values if v]

    if not result["ws"] and not result["ud"]:
        parents = ap.get("parent_schemas") or []
        if isinstance(parents, list):
            for schema_name in parents:
                entry = _fetch_schema_sys_version_entry(str(schema_name), fetcher)
                kind = str(entry.get("kind") or "").lower()
                if kind in result and str(schema_name) not in result[kind]:
                    result[kind].append(str(schema_name))

    if not result["ws"]:
        legacy = fetcher(
            "SELECT value FROM utils.config_param_system WHERE parameter = 'ws_current_schema'",
            None,
        )
        if legacy and legacy[0] and legacy[0][0]:
            result["ws"] = [str(legacy[0][0])]
    if not result["ud"]:
        legacy = fetcher(
            "SELECT value FROM utils.config_param_system WHERE parameter = 'ud_current_schema'",
            None,
        )
        if legacy and legacy[0] and legacy[0][0]:
            result["ud"] = [str(legacy[0][0])]
    return result


_NETWORK_SATELLITE_ORDER = ("multilang", "utils", "cibs", "am", "cm", "audit")


def _version_tuple(version: Any) -> tuple:
    parts = str(version or "0").split(".")
    if len(parts) >= 4:
        parts = parts[:3]
    nums = []
    for part in parts:
        try:
            nums.append(int(part))
        except ValueError:
            nums.append(0)
    return tuple(nums) if nums else (0,)


def _fetch_schema_sys_version_entry(
    schema_name: str,
    fetcher: RowFetcher = _tools_db_fetch,
) -> dict[str, Any]:
    if not schema_exists(schema_name, fetcher):
        return {}

    columns_by_schema = _sys_version_columns_by_schema([schema_name], fetcher)
    columns = columns_by_schema.get(schema_name, set())
    version_col = _version_column_for_schema(schema_name, columns)
    if not version_col:
        return {"schema": schema_name, "kind": "", "version": "", "addparam": {}}
    select_cols = ["project_type", version_col]
    if "addparam" in columns:
        select_cols.append("addparam")

    row = fetcher(
        f"SELECT {', '.join(select_cols)} "
        f"FROM {_quote_ident(schema_name)}.sys_version "
        "ORDER BY id DESC LIMIT 1",
        None,
    )
    if not row or not row[0]:
        return {"schema": schema_name, "kind": "", "version": "", "addparam": {}}

    values = row[0]
    addparam = values[2] if len(values) > 2 else None
    return {
        "schema": schema_name,
        "kind": str(values[0] or ""),
        "version": str(values[1] or ""),
        "addparam": _parse_addparam(addparam),
    }


def linked_satellites_for_parent(
    schema_name: str,
    fetcher: RowFetcher = _tools_db_fetch,
) -> str:
    """Comma-separated satellite schemas linked to a WS/UD parent (addparam + legacy flags)."""
    entry = _fetch_schema_sys_version_entry(schema_name, fetcher)
    kind = str(entry.get("kind") or "").upper()
    if kind not in ("WS", "UD"):
        return ""

    row_entry = _entry_from_sys_version_row(
        schema_name,
        entry.get("kind"),
        entry.get("version"),
        entry.get("addparam") or {},
    )
    linked = str(row_entry.get("linked") or "")
    for satellite, sat_schema in _legacy_parent_satellites(schema_name, fetcher):
        linked = _append_linked_satellite(linked, satellite, sat_schema)
    return linked


def get_anchor_satellites(
    anchor_schema: str,
    fetcher: RowFetcher = _tools_db_fetch,
) -> dict[str, Any]:
    entry = _fetch_schema_sys_version_entry(anchor_schema, fetcher)
    satellites = entry.get("addparam", {}).get("satellites") or {}
    return satellites if isinstance(satellites, dict) else {}


def _satellite_schema_name(
    kind: str,
    satellites: dict[str, Any],
    fetcher: RowFetcher,
) -> Optional[str]:
    meta = satellites.get(kind) or satellites.get(kind.upper()) or {}
    if isinstance(meta, dict):
        if meta.get("enabled") is False:
            return None
        schema_name = str(meta.get("schema") or kind)
        if schema_exists(schema_name, fetcher):
            return schema_name

    if kind == "cm":
        cm_schema = find_cm_schema(fetcher=fetcher)
        if cm_schema:
            return cm_schema

    if schema_exists(kind, fetcher):
        return kind
    return None


def build_network_update_plan(
    anchor_schema: str,
    plugin_version: str,
    fetcher: RowFetcher = _tools_db_fetch,
) -> list[dict[str, Any]]:
    """Ordered update targets for the network anchored on a WS/UD schema."""
    anchor_entry = _fetch_schema_sys_version_entry(anchor_schema, fetcher)
    anchor_kind = str(anchor_entry.get("kind") or "").upper()
    if anchor_kind not in ("WS", "UD"):
        return []

    plugin_v = _version_tuple(plugin_version)
    plan: list[dict[str, Any]] = []
    anchor_version = str(anchor_entry.get("version") or "0.0.0")
    plan.append({
        "kind": anchor_kind.lower(),
        "schema": anchor_schema,
        "version": anchor_version,
        "needs_update": _version_tuple(anchor_version) < plugin_v,
        "parent_schema": anchor_schema,
        "parent_type": anchor_kind.lower(),
    })

    satellites = get_anchor_satellites(anchor_schema, fetcher)
    for kind in _NETWORK_SATELLITE_ORDER:
        schema_name = _satellite_schema_name(kind, satellites, fetcher)
        if not schema_name:
            continue
        entry = _fetch_schema_sys_version_entry(schema_name, fetcher)
        version = str(entry.get("version") or "0.0.0")
        plan.append({
            "kind": kind,
            "schema": schema_name,
            "version": version,
            "needs_update": _version_tuple(version) < plugin_v,
            "parent_schema": anchor_schema,
            "parent_type": anchor_kind.lower(),
        })
    return plan


def schema_needs_plugin_update(version: str, plugin_version: str) -> bool:
    return _version_tuple(version) < _version_tuple(plugin_version)


def parent_satellite_linked(
    inventory: list[dict[str, Any]],
    parent_schema: str,
    satellite: str = "utils",
) -> bool:
    """True when a WS/UD parent row lists the satellite in ``linked`` (from addparam)."""
    row = find_inventory_row(inventory, schema=parent_schema)
    if not row:
        return False
    sat_l = satellite.lower()
    linked = str(row.get("linked") or "")
    for part in linked.split(","):
        p = part.strip().lower()
        if p == sat_l or p.startswith(f"{sat_l}:"):
            return True
    return False


def am_parent_kind_supported(sql_dir: str, parent_kind: str) -> bool:
    """True when AM integration SQL exists for this parent kind (ws|ud)."""
    kind = str(parent_kind or "").strip().lower()
    if not kind or not sql_dir:
        return False
    return os.path.isfile(
        os.path.join(
            sql_dir, "schemas", "addon", "am", "integration", kind, "integration.sql"
        )
    )


def am_linked_parent_kinds(
    am_row: Optional[dict[str, Any]],
    inventory: list[dict[str, Any]],
) -> set[str]:
    """WS/UD kinds already attached to the singleton am schema (at most one each)."""
    kinds: set[str] = set()
    names: list[str] = []
    addparam = (am_row or {}).get("addparam") or {}
    if isinstance(addparam, dict):
        for key in ("parentSchema", "parent_schema"):
            val = addparam.get(key)
            if val:
                names.append(str(val))
        parents = addparam.get("parent_schemas") or []
        if isinstance(parents, list):
            names.extend(str(p) for p in parents if p)
    by_schema = {str(row.get("schema") or ""): row for row in inventory or []}
    for name in names:
        kind = str((by_schema.get(name) or {}).get("kind") or "").upper()
        if kind in ("WS", "UD"):
            kinds.add(kind)
    for row in inventory or []:
        kind = str(row.get("kind") or "").upper()
        schema = str(row.get("schema") or "")
        if kind in ("WS", "UD") and schema and parent_satellite_linked(inventory, schema, "am"):
            kinds.add(kind)
    return kinds


def am_kind_is_linked(
    am_row: Optional[dict[str, Any]],
    inventory: list[dict[str, Any]],
    kind: str,
) -> bool:
    """True when am is already linked to a parent of this WS|UD kind."""
    return str(kind or "").upper() in am_linked_parent_kinds(am_row, inventory)


def am_is_integrated(
    am_row: Optional[dict[str, Any]],
    inventory: list[dict[str, Any]],
) -> bool:
    """True when the singleton ``am`` schema is already linked to a WS parent."""
    if not am_row:
        return False
    addparam = am_row.get("addparam") or {}
    if isinstance(addparam, dict):
        if addparam.get("parentSchema") or addparam.get("parent_schema"):
            return True
        parents = addparam.get("parent_schemas") or []
        if isinstance(parents, list) and parents:
            return True
    for row in inventory:
        kind = str(row.get("kind") or "").upper()
        schema = str(row.get("schema") or "")
        if kind == "WS" and schema and parent_satellite_linked(inventory, schema, "am"):
            return True
    return False


def find_inventory_row(
    inventory: list[dict[str, Any]],
    *,
    schema: Optional[str] = None,
    kind: Optional[str] = None,
) -> Optional[dict[str, Any]]:
    want_kind = kind.upper() if kind else None
    for row in inventory:
        if schema is not None and row.get("schema") == schema:
            return row
        if want_kind and str(row.get("kind") or "").upper() == want_kind:
            return row
    return None


_TRANSLATABLE_KINDS = frozenset({"ws", "ud", "am", "cm"})


def fetch_schema_translation_info(
    fetcher: RowFetcher = _tools_db_fetch,
    *,
    kinds: frozenset[str] | set[str] | None = None,
) -> list[dict[str, Any]]:
    """
    Return [{schema, kind, version, language}, ...] for Giswater schemas that
    expose ``sys_version``. Missing/legacy columns are tolerated (empty strings).
    """
    wanted = {str(k).lower() for k in (kinds or _TRANSLATABLE_KINDS)}
    names = fetch_schema_names_with_sys_version(fetcher)
    if not names:
        return []

    columns_by_schema = _sys_version_columns_by_schema(names, fetcher)
    result: list[dict[str, Any]] = []

    for schema_name in sorted(names):
        columns = columns_by_schema.get(schema_name, set())
        version_col = _version_column_for_schema(schema_name, columns)
        if not version_col:
            continue

        select_cols = ["project_type", version_col]
        has_language = "language" in columns
        if has_language:
            select_cols.append("language")

        row = fetcher(
            f"SELECT {', '.join(select_cols)} "
            f"FROM {_quote_ident(schema_name)}.sys_version "
            "ORDER BY id DESC LIMIT 1",
            None,
        )
        if not row or not row[0]:
            continue

        values = row[0]
        kind = str(values[0] or "").strip().lower()
        if not kind or kind not in wanted:
            continue

        version = str(values[1] or "") if len(values) > 1 else ""
        language = ""
        if has_language and len(values) > 2:
            language = str(values[2] or "")

        result.append({
            "schema": schema_name,
            "kind": kind,
            "version": version,
            "language": language,
        })
    return result


def fetch_multilang_operative_languages(
    fetcher: RowFetcher = _tools_db_fetch,
) -> set[str]:
    """
    Return operative multilang language ids (folder form) when the multilang
    schema exists. Missing schema/tables return an empty set (non-fatal).
    """
    try:
        if not schema_exists("multilang", fetcher):
            return set()
    except Exception:
        return set()

    try:
        from .i18n_baseline_seed import (
            fetch_seeded_language_ids,
            normalize_language_folder,
        )
        ids = fetch_seeded_language_ids(fetcher)
    except Exception:
        return set()

    return {normalize_language_folder(lang) for lang in ids if lang}
