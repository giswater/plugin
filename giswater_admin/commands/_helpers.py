"""Shared helpers used by multiple subcommands."""

from __future__ import annotations

import argparse
import os
from typing import Any, Optional

from .. import conn as conn_mod
from ..engine import BuildParams, Manifest
from ..engine.manifest_registry import (
    addon_kinds,
    all_kinds,
    load_kind_manifest,
    main_kinds,
)
from ..engine.builder import ProgressCb
from ..engine.sql_runner import ConnectionLike, FileExec
from ..engine.timing_report import all_files, summarize_build
from ..log_format import format_done, format_file, format_phase
from ..output import Out


class SuperuserRequired(RuntimeError):
    """Raised when a CLI command requires a PostgreSQL superuser session."""


_SUPERUSER_SQL = """
SELECT
  current_user,
  COALESCE((
    SELECT rolsuper FROM pg_roles WHERE rolname = current_user
  ), FALSE)
"""


def manifest_for(args: argparse.Namespace, kind: str) -> Manifest:
    try:
        return load_kind_manifest(args.dbmodel_path, kind)
    except Exception as e:
        from ..engine.manifest import ManifestError

        if isinstance(e, ManifestError):
            raise
        raise ManifestError(str(e)) from e


def validate_tier_kind(
    dbmodel_path: str,
    kind: str,
    *,
    tier: str,
    out: Out,
) -> bool:
    known_fn = {
        "main": main_kinds,
        "addon": addon_kinds,
    }.get(tier, all_kinds)
    allowed = known_fn(dbmodel_path)
    if kind.lower() not in allowed:
        out.error(
            f"Unknown kind '{kind}' for tier '{tier}'. "
            f"Known: {sorted(allowed)}. Run `gw manifest list`."
        )
        return False
    return True


def needs_connection(args: argparse.Namespace) -> bool:
    """``--check`` runs offline; everything else needs a real connection."""
    if not getattr(args, "check", False):
        return True
    # Even in check mode, if user passed --conn/--config/PG*, honour it
    # so they get the safe_repr() in the output.
    return bool(
        args.conn
        or args.config
        or conn_mod.has_connection_source()
    )


def open_conn(
    args: argparse.Namespace,
    out: Out | None = None,
    *,
    require_superuser: bool = True,
) -> ConnectionLike:
    info = conn_mod.resolve(args.conn, args.config)
    conn = conn_mod.open_connection(info, autocommit=False)
    if require_superuser:
        user, is_super = user_is_superuser(conn)
        if not is_super:
            conn.close()
            msg = (
                "Giswater CLI requires a PostgreSQL superuser. "
                f"Connected as '{user}' (superuser=false)."
            )
            if out is not None:
                out.error(msg)
            raise SuperuserRequired(msg)
    return conn


def user_is_superuser(conn: Any) -> tuple[str, bool]:
    """Return ``(current_user, is_superuser)``."""
    try:
        with conn.raw.cursor() as cur:  # type: ignore[attr-defined]
            cur.execute(_SUPERUSER_SQL)
            row = cur.fetchone()
    except Exception:  # noqa: BLE001
        try:
            conn.rollback()
        except Exception:  # noqa: BLE001
            pass
        return ("", False)
    if not row:
        return ("", False)
    return (str(row[0]), bool(row[1]))


def safe_target_repr(args: argparse.Namespace) -> str:
    try:
        return conn_mod.resolve(args.conn, args.config).safe_repr()
    except RuntimeError:
        return ""


def detect_project_type(conn: Any, schema: str) -> str:
    """
    Return ``project_type`` (``ws``, ``ud``, ``cm``, ``am``, ``utils``)
    of ``schema`` based on its ``sys_version`` row, or empty if not
    detectable. ``conn`` is a Psycopg2Adapter (has ``.raw``).
    """
    try:
        with conn.raw.cursor() as cur:  # type: ignore[attr-defined]
            cur.execute(
                f"SELECT project_type FROM \"{schema}\".sys_version "
                "ORDER BY id DESC LIMIT 1"
            )
            row = cur.fetchone()
            if row and row[0]:
                return str(row[0]).lower()
    except Exception:  # noqa: BLE001
        try:
            conn.rollback()
        except Exception:  # noqa: BLE001
            pass
    return ""


def detect_project_version(conn: Any, schema: str) -> str:
    try:
        with conn.raw.cursor() as cur:  # type: ignore[attr-defined]
            cur.execute(
                f'SELECT giswater FROM "{schema}".sys_version '
                "ORDER BY id DESC LIMIT 1"
            )
            row = cur.fetchone()
            if row and row[0]:
                return str(row[0])
    except Exception:  # noqa: BLE001
        try:
            conn.rollback()
        except Exception:  # noqa: BLE001
            pass
    return ""


def report_result(
    args: argparse.Namespace,
    out: Out,
    manifest: Manifest,
    params: BuildParams,
    result: Any,
) -> int:
    """Render a build result. Returns process exit code."""
    payload = {
        "ok": result.ok,
        "kind": manifest.kind,
        "schema": params.schema_name,
        "profile": params.profile,
        "cancelled": getattr(result, "cancelled", False),
        "phases": [
            {
                "phase": pr.phase_id,
                "ok": pr.ok,
                "skipped": pr.skipped,
                "files_executed": len(pr.files),
                "first_failure": next(
                    (
                        {"path": fx.path, "error": fx.error}
                        for fx in pr.files
                        if not fx.ok
                    ),
                    None,
                ),
            }
            for pr in result.phases
        ],
    }
    if getattr(args, "timing", False):
        top = int(getattr(args, "timing_top", 20))
        summary = summarize_build(result, top=top)
        out.timing_summary(summary)
        if getattr(args, "json", False):
            timing_payload: dict[str, Any] = dict(summary)
            if getattr(args, "timing_detail", False):
                timing_payload["files"] = all_files(result)
            payload["timing"] = timing_payload
    out.result(payload)
    return 0 if result.ok else 1


def cm_parent_supported(dbmodel_path: str, parent_type: str) -> bool:
    """
    Return ``True`` when cm integration SQL exists for ``parent_type``.
    """
    if not parent_type:
        return False
    ddl = os.path.join(
        dbmodel_path, "schemas", "addon", "cm", "integration", parent_type, "integration.sql"
    )
    return os.path.isfile(ddl)


def cibs_parent_supported(dbmodel_path: str, parent_type: str) -> bool:
    if not parent_type:
        return False
    ddl = os.path.join(
        dbmodel_path,
        "schemas",
        "addon",
        "cibs",
        "integration",
        parent_type,
        "integration.sql",
    )
    return os.path.isfile(ddl)


def am_parent_supported(dbmodel_path: str, parent_type: str) -> bool:
    """Return ``True`` when am integration SQL exists for ``parent_type``."""
    if not parent_type:
        return False
    ddl = os.path.join(
        dbmodel_path,
        "schemas",
        "addon",
        "am",
        "integration",
        parent_type,
        "integration.sql",
    )
    return os.path.isfile(ddl)


def detect_am_linked_parent(conn: Any, schema: str = "am") -> str:
    """
    Return the WS parent schema name already linked to ``am``, or empty.

    Reads ``parentSchema`` / ``parent_schemas`` from the latest ``sys_version`` row.
    """
    try:
        with conn.raw.cursor() as cur:  # type: ignore[attr-defined]
            cur.execute(
                """
                SELECT 1
                FROM pg_catalog.pg_attribute a
                JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
                JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = %s
                  AND c.relname = 'sys_version'
                  AND a.attname = 'addparam'
                  AND a.attnum > 0
                  AND NOT a.attisdropped
                LIMIT 1
                """,
                [schema],
            )
            if cur.fetchone() is None:
                return ""
            cur.execute(
                f'SELECT addparam FROM "{schema}".sys_version '
                "ORDER BY id DESC LIMIT 1"
            )
            row = cur.fetchone()
            if not row or not row[0]:
                return ""
            addparam = row[0]
            if isinstance(addparam, str):
                import json

                addparam = json.loads(addparam)
            if not isinstance(addparam, dict):
                return ""
            parent = addparam.get("parentSchema") or addparam.get("parent_schema")
            if parent:
                return str(parent)
            parents = addparam.get("parent_schemas") or []
            if isinstance(parents, list) and parents:
                return str(parents[-1])
    except Exception:  # noqa: BLE001
        try:
            conn.rollback()
        except Exception:  # noqa: BLE001
            pass
    return ""


class NoopConn:
    """``ConnectionLike`` stub used in ``--check`` paths (no DB calls)."""

    def execute(self, sql, *, filepath=None):  # noqa: D401 - protocol shape
        return True

    def last_error(self) -> str:
        return ""

    def commit(self) -> None:
        pass

    def rollback(self) -> None:
        pass

    def close(self) -> None:
        pass


def build_progress_cb(
    out: Out,
    *,
    timing: bool = False,
    timing_threshold_ms: int = 0,
) -> ProgressCb:
    """Phase milestones and per-file lines (when ``out.verbose``)."""
    state = {"last_label": ""}
    out.style.show_timing_ms = bool(timing)

    def progress(
        seen: int,
        total: int,
        label: str,
        fx: Optional[FileExec] = None,
    ) -> None:
        if label.startswith("phase:"):
            if label != state["last_label"]:
                phase_id = label.split(":", 1)[1]
                out.info(format_phase(seen, total, phase_id, style=out.style))
                state["last_label"] = label
        elif label == "done":
            if label != state["last_label"]:
                out.info(format_done(seen, total, style=out.style))
                state["last_label"] = label
        elif out.verbose:
            ms = None
            if timing and fx is not None:
                if timing_threshold_ms and fx.duration_ms < timing_threshold_ms:
                    return
                ms = fx.duration_ms
            out.progress(
                format_file(seen, total, label, ms=ms, style=out.style)
            )

    return progress


def progress_cb_for_args(out: Out, args: argparse.Namespace) -> ProgressCb:
    """Build a progress callback wired to CLI timing flags."""
    out.style.sql_root = getattr(args, "dbmodel_path", "") or out.style.sql_root
    out.style.show_timing_ms = bool(getattr(args, "timing", False))
    return build_progress_cb(
        out,
        timing=getattr(args, "timing", False),
        timing_threshold_ms=int(getattr(args, "timing_threshold_ms", 0)),
    )
