"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import threading
from collections import OrderedDict

from qgis.PyQt.QtCore import QObject, pyqtSignal
from qgis.core import QgsTask

from ...libs import tools_db, tools_log

_COMBO_CACHE_LOCK = threading.Lock()
_COMBO_QUERY_CACHE: "OrderedDict[str, list]" = OrderedDict()
_COMBO_CACHE_MAX = 128

_thread_local = threading.local()


def get_combo_rows_cached(query: str):
    """Return a copy of cached rows for ``query``, or ``None`` on miss."""
    if not query:
        return None
    with _COMBO_CACHE_LOCK:
        rows = _COMBO_QUERY_CACHE.get(query)
        if rows is None:
            return None
        _COMBO_QUERY_CACHE.move_to_end(query)
        return list(rows)


def clear_combo_query_cache() -> None:
    """Drop all cached combo query results (e.g. after project reload)."""
    with _COMBO_CACHE_LOCK:
        _COMBO_QUERY_CACHE.clear()


def _cache_put(query: str, rows: list) -> None:
    if not query:
        return
    with _COMBO_CACHE_LOCK:
        _COMBO_QUERY_CACHE[query] = list(rows)
        _COMBO_QUERY_CACHE.move_to_end(query)
        while len(_COMBO_QUERY_CACHE) > _COMBO_CACHE_MAX:
            _COMBO_QUERY_CACHE.popitem(last=False)


def _borrow_thread_aux_conn():
    """Reuse one aux PG connection per QgsTask worker thread."""
    conn = getattr(_thread_local, "combo_aux_conn", None)
    if conn is not None:
        try:
            if not conn.closed:
                return conn, ""
        except Exception:
            pass
        _thread_local.combo_aux_conn = None

    try:
        aux_result = tools_db.dao.get_aux_conn()
    except Exception as exc:
        return None, f"get_aux_conn failed: {exc}"

    if aux_result is None or isinstance(aux_result, dict):
        err = ""
        if isinstance(aux_result, dict):
            err = str(aux_result.get("last_error") or "")
        return None, err or "Could not get auxiliary connection"

    _thread_local.combo_aux_conn = aux_result
    return aux_result, ""


def _invalidate_thread_aux_conn() -> None:
    conn = getattr(_thread_local, "combo_aux_conn", None)
    if conn is None:
        return
    _thread_local.combo_aux_conn = None
    try:
        tools_db.dao.delete_aux_con(conn)
    except Exception:
        pass


def _execute_combo_query(query: str):
    """Run ``query`` and return ``(rows, error)``."""
    cached = get_combo_rows_cached(query)
    if cached is not None:
        return cached, ""

    conn, err = _borrow_thread_aux_conn()
    if conn is None:
        return [], err

    try:
        cursor = tools_db.dao.get_cursor(conn)
        cursor.execute(query)
        rows = cursor.fetchall()
        cursor.close()
        conn.commit()
        materialized = [(_safe_get(r, 0), _safe_get(r, 1)) for r in rows or []]
        _cache_put(query, materialized)
        return materialized, ""
    except Exception as exc:
        try:
            conn.rollback()
        except Exception:
            pass
        _invalidate_thread_aux_conn()
        return [], str(exc)


class GwComboLoaderTask(QgsTask, QObject):
    """Background task that loads dv_querytext rows for an async combo widget.

    Each `GwAsyncComboBox` owns a monotonically increasing token. When the user
    triggers a reload (e.g. parent combo changed), the widget bumps the token
    and starts a new task. The signal handler in the widget ignores results
    coming from older tokens so stale rows can never overwrite fresh data.

    Connections are reused per worker thread and identical SQL is cached in memory
    for the session so opening many features reuses the same combo payloads.
    """

    # token, rows (list of psycopg2 DictRow / tuples), error (str, '' on success)
    rows_loaded = pyqtSignal(int, list, str)

    def __init__(self, description: str, query: str, token: int):
        QObject.__init__(self)
        QgsTask.__init__(self, description, QgsTask.Flag.CanCancel)
        self._query = query
        self._token = token
        self._rows = []
        self._error = ""

    @property
    def token(self) -> int:
        return self._token

    def run(self) -> bool:
        if self.isCanceled():
            return False

        self._rows, self._error = _execute_combo_query(self._query)
        return not self._error

    def finished(self, result: bool) -> None:
        if not result and not self._error:
            self._error = "cancelled"

        if self._error:
            tools_log.log_warning(
                "GwComboLoaderTask failed: {0}", msg_params=(self._error,)
            )

        try:
            self.rows_loaded.emit(self._token, self._rows, self._error)
        except RuntimeError:
            # Receiver was destroyed (dialog closed before task finished).
            pass

    def cancel(self) -> None:
        super().cancel()


def _safe_get(row, idx):
    """Return row[idx] for tuples and DictRow alike, or None on missing index."""
    try:
        return row[idx]
    except (IndexError, KeyError, TypeError):
        return None
