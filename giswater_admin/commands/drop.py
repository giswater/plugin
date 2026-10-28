"""``drop`` subcommand."""

from __future__ import annotations

import argparse

from ..engine import drop_schema
from ..output import Out
from . import _helpers as h


def run(args: argparse.Namespace, out: Out) -> int:
    if not args.yes:
        out.error("drop is destructive; pass --yes to confirm.")
        return 1

    safe = args.schema.replace('"', '').replace(';', '')
    cascade = bool(args.cascade)
    sql = f'DROP SCHEMA IF EXISTS "{safe}" {"CASCADE" if cascade else "RESTRICT"};'

    if args.check:
        out.result({"ok": True, "mode": "check", "sql": sql})
        return 0

    conn = h.open_conn(args, out)
    try:
        fx = drop_schema(conn, safe, cascade=cascade, commit=True)
        if not fx.ok:
            conn.rollback()
    finally:
        conn.close()

    out.result(
        {
            "ok": fx.ok,
            "schema": safe,
            "cascade": cascade,
            "error": fx.error or None,
            "cleanup": fx.notes or None,
        }
    )
    return 0 if fx.ok else 1
