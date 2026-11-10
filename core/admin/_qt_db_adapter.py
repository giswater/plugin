"""
ConnectionLike adapter over ``tools_db`` for the QGIS plugin runtime.

Lets :class:`giswater_admin.engine.SchemaBuilder` execute against the
plugin's single ``QSqlDatabase`` session without dragging psycopg2 into
QGIS. Transactions stay where they always were (the engine never
commits; the plugin commits via ``tools_db.dao.commit()`` after the
task succeeds).
"""

from __future__ import annotations

from ...libs import lib_vars, tools_db


def _format_db_error(exc: object | None) -> str:
    if exc is None:
        return ""
    parts: list[str] = []

    db_text = getattr(exc, "databaseText", None)
    if callable(db_text):
        primary = str(db_text() or "").strip()
        if primary:
            parts.append(primary)

    if not parts:
        text = str(exc).strip()
        if text:
            parts.append(text)

    driver_text = getattr(exc, "driverText", None)
    if callable(driver_text):
        driver = str(driver_text() or "").strip()
        if driver and driver not in parts[0]:
            parts.append(f"DRIVER: {driver}")

    return "\n".join(parts)


class QtDbAdapter:
    """Implements :class:`giswater_admin.engine.ConnectionLike`."""

    def __init__(self, *, dev_commit: bool = False) -> None:
        # When dev_commit is True the engine commits each file (legacy
        # `force_commit` mode used to survive a single failing file).
        self._dev_commit = bool(dev_commit)
        self._error = ""
        self._statement_position = 0

    # --------------------------------------------------------- ConnectionLike

    def execute_scalar(self, sql: str, *, filepath: str | None = None):
        """Return ``(first_column, ok)``. Used to read the satellite version before integrate."""
        self._statement_position = 0
        row = tools_db.get_row(
            sql,
            log_info=False,
            log_sql=False,
            commit=self._dev_commit,
            is_thread=True,
        )
        if row:
            self._error = ""
            return (row[0], True)
        err = lib_vars.session_vars.get("last_error")
        if err:
            self._error = _format_db_error(err)
            return (None, False)
        self._error = ""
        return (None, True)

    def execute(self, sql: str, *, filepath: str | None = None) -> bool:
        self._statement_position = 0
        ok = tools_db.execute_sql(
            sql,
            log_sql=False,
            log_error=False,
            commit=self._dev_commit,
            filepath=filepath,
            is_thread=True,
            show_exception=False,
        )
        if not ok:
            raw = lib_vars.session_vars.get("last_error")
            self._error = _format_db_error(raw) or "tools_db.execute_sql returned False"
        else:
            self._error = ""
        return bool(ok)

    def last_error(self) -> str:
        return self._error

    def last_statement_position(self) -> int:
        return self._statement_position

    def commit(self) -> None:
        tools_db.dao.commit()

    def rollback(self) -> None:
        tools_db.dao.rollback()

    def close(self) -> None:
        # Plugin owns the session; engine must not close it.
        return
