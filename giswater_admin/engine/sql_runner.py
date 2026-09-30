"""
SQL execution layer.

The engine only ever talks to a :class:`ConnectionLike` — a thin
protocol satisfied by:

- ``adapters.psycopg2_adapter.Psycopg2Adapter`` (CLI + tests)
- ``core.admin._qt_db_adapter.QtDbAdapter`` (QGIS plugin)

Keeping execution behind a protocol means the engine never imports Qt
or psycopg2; either adapter is plug-and-play.
"""

from __future__ import annotations

import json
import logging
import os
import time
from dataclasses import dataclass
from typing import Any, Mapping, Protocol

from .templating import apply_subs

log = logging.getLogger(__name__)


def _statement_position(conn: ConnectionLike) -> int:
    getter = getattr(conn, "last_statement_position", None)
    if callable(getter):
        return int(getter() or 0)
    return 0


def _preview_sql(sql: str, limit: int = 480) -> str:
    collapsed = " ".join(sql.split())
    if len(collapsed) > limit:
        return collapsed[:limit] + "…"
    return collapsed


@dataclass
class FileExec:
    """Result of executing one SQL file (or inline statement)."""

    path: str
    ok: bool = False
    error: str = ""
    sql: str = ""
    statement_position: int = 0
    duration_ms: int = 0
    notes: str = ""


class ConnectionLike(Protocol):
    """Minimal contract the engine needs from a connection adapter."""

    def execute(self, sql: str, *, filepath: str | None = None) -> bool:
        """Run ``sql``. Return True on success, False on error.

        Adapters MUST capture the underlying error and expose it via
        :meth:`last_error` so the engine can populate :class:`FileExec`.
        """

    def last_error(self) -> str:
        """Return the most recent error message (empty when ok)."""

    def commit(self) -> None:
        ...

    def rollback(self) -> None:
        ...

    def close(self) -> None:
        ...


def list_sql_files(folder: str, recursive: bool = False) -> list[str]:
    """List ``.sql`` files in ``folder``. Stable alphabetical order."""
    out: list[str] = []

    if not os.path.exists(folder):
        return out

    if not os.path.isdir(folder):
        out.append(folder)
        return out

    if recursive:
        for root, _dirs, files in os.walk(folder):
            for name in sorted(files):
                if name.endswith(".sql") and not name.startswith("."):
                    out.append(os.path.join(root, name))
    else:
        for name in sorted(os.listdir(folder)):
            if not name.endswith(".sql") or name.startswith("."):
                continue
            full = os.path.join(folder, name)
            if os.path.isfile(full):
                out.append(full)
    return out


def execute_file(
    conn: ConnectionLike,
    path: str,
    subs: Mapping[str, str],
    commit: bool = False,
) -> FileExec:
    """Read, substitute, and execute one SQL file."""
    if not os.path.isfile(path):
        return FileExec(path=path, ok=False, error=f"file not found: {path}")

    with open(path, "r", encoding="utf-8") as f:
        raw = f.read()
    sql = apply_subs(raw, subs)
    log.debug("execute_file path=%s sql_preview=%s", path, _preview_sql(sql))

    fx = FileExec(path=path, sql=sql)
    t0 = time.perf_counter()
    try:
        fx.ok = conn.execute(sql, filepath=path)
        if not fx.ok:
            fx.error = conn.last_error() or "execute returned False"
            fx.statement_position = _statement_position(conn)
        elif commit:
            conn.commit()
    except Exception as e:  # noqa: BLE001 - boundary
        fx.ok = False
        fx.error = f"{type(e).__name__}: {e}"
    finally:
        fx.duration_ms = int((time.perf_counter() - t0) * 1000)
    return fx


def execute_inline(
    conn: ConnectionLike,
    sql: str,
    *,
    label: str = "inline",
    commit: bool = False,
) -> FileExec:
    log.debug("execute_inline label=%s sql_preview=%s", label, _preview_sql(sql))
    fx = FileExec(path=f"<{label}>", sql=sql)
    t0 = time.perf_counter()
    try:
        fx.ok = conn.execute(sql)
        if not fx.ok:
            fx.error = conn.last_error() or "execute returned False"
            fx.statement_position = _statement_position(conn)
        elif commit:
            conn.commit()
    except Exception as e:  # noqa: BLE001
        fx.ok = False
        fx.error = f"{type(e).__name__}: {e}"
    finally:
        fx.duration_ms = int((time.perf_counter() - t0) * 1000)
    return fx


def execute_function_call(
    conn: ConnectionLike,
    function: str,
    payload: Any,
    commit: bool = False,
) -> FileExec:
    """
    Execute a Giswater-style server-side function call.

    Mirrors :func:`tools_gw.execute_procedure`: builds ``SELECT
    schema.fn($${...JSON...}$$)`` and submits it as one statement.
    Adapters that need a typed return can wrap this; we only need
    success/failure here.
    """
    body_json = json.dumps(payload, ensure_ascii=False) if not isinstance(payload, str) else payload
    sql = f"SELECT {function}($${body_json}$$);"
    log.debug("execute_function_call fn=%s sql_preview=%s", function, _preview_sql(sql))
    fx = FileExec(path=f"<fn:{function}>", sql=sql)
    t0 = time.perf_counter()
    try:
        fx.ok = conn.execute(sql)
        if not fx.ok:
            fx.error = conn.last_error() or "function returned False"
            fx.statement_position = _statement_position(conn)
        if fx.ok and commit:
            conn.commit()
    except Exception as e:  # noqa: BLE001
        fx.ok = False
        fx.error = f"{type(e).__name__}: {e}"
    finally:
        fx.duration_ms = int((time.perf_counter() - t0) * 1000)
    return fx
