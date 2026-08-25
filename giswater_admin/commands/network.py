"""``network show`` / ``network update`` — network topology and lockstep upgrades."""

from __future__ import annotations

import argparse
import sys

from ..engine.schema_catalog import (
    SchemaListFilter,
    database_network_payload,
    discover_database_network,
    format_database_network,
    format_schema_list,
    list_schemas,
    make_conn_fetcher,
    schema_list_payload,
)
from ..output import Out
from . import _helpers as h


def run_show(args: argparse.Namespace, out: Out) -> int:
    if getattr(args, "flat", False):
        return _run_show_flat(args, out)

    conn = h.open_conn(args, out, require_schema_admin=False)
    try:
        fetcher = make_conn_fetcher(conn)
        schema_filter = getattr(args, "schema", None) or getattr(args, "anchor", None) or None
        db = discover_database_network(fetcher, schema_filter=schema_filter)
        if not db.cluster.nodes and not db.other_schemas:
            out.error("No Giswater schemas discovered in this database.")
            return 1

        payload = database_network_payload(db)
        if getattr(args, "json", False):
            out.result(payload)
        else:
            database = _database_name(args)
            sys.stdout.write(format_database_network(db, database=database) + "\n")
        return 0
    finally:
        conn.close()


def _run_show_flat(args: argparse.Namespace, out: Out) -> int:
    out.warn("network show --flat is deprecated; use `gw schema list` instead.")
    return _run_schema_list(args, out)


def _run_schema_list(args: argparse.Namespace, out: Out) -> int:
    kinds = getattr(args, "schema_types", None) or []
    flt = SchemaListFilter(
        tier=getattr(args, "tier", "all") or "all",
        kinds=frozenset(kinds),
    )
    conn = h.open_conn(args, out, require_schema_admin=False)
    try:
        fetcher = make_conn_fetcher(conn)
        items = list_schemas(fetcher, filter=flt)
        schema_name = getattr(args, "schema", None)
        if schema_name:
            items = [item for item in items if item.schema == schema_name]
            if not items:
                out.error(f"schema '{schema_name}' has no sys_version table.")
                return 1
        if getattr(args, "json", False):
            out.result(schema_list_payload(items))
            return 0
        database = _database_name(args)
        sys.stdout.write(format_schema_list(items, database=database) + "\n")
        return 0
    finally:
        conn.close()


def _database_name(args: argparse.Namespace) -> str:
    from .. import conn as conn_mod  # noqa: WPS433

    try:
        return conn_mod.resolve(args.conn, args.config).dbname or ""
    except RuntimeError:
        return ""
