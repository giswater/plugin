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
from qgis.core import QgsProject, QgsTask, QgsVectorLayer

from ...libs import tools_db, tools_log

_COMBO_CACHE_LOCK = threading.Lock()
_COMBO_QUERY_CACHE: "OrderedDict[str, list]" = OrderedDict()
_COMBO_CACHE_MAX = 128
_LAYER_WATCH_INSTALLED = False

# Writes that can change rows a combo query would return. Reads (gw_fct_get*)
# must not flush the cache or every info form misses and the cache is useless.
_WRITE_FN_PREFIXES = (
    'gw_fct_set',
    'gw_fct_upsert',
    'gw_fct_insert',
    'gw_fct_delete',
)

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


def procedure_changes_combo_sources(function_name: str) -> bool:
    """True for plugin writes that can insert/update/delete combo source rows."""
    if not function_name:
        return False
    name = str(function_name).split('.')[-1].lower()
    if name.startswith('gw_fct_get'):
        return False
    return name.startswith(_WRITE_FN_PREFIXES)


def clear_combo_query_cache() -> None:
    """Drop cached combo rows so the next form fill hits Postgres."""
    with _COMBO_CACHE_LOCK:
        _COMBO_QUERY_CACHE.clear()


def install_combo_cache_invalidation() -> None:
    """Drop the cache when a layer edit is committed (attribute table, digitizing).

    Those writes never go through ``gw_fct_*``, so ``execute_procedure`` cannot
    see them. One hook for the project singleton; each layer is connected once.
    """
    global _LAYER_WATCH_INSTALLED
    project = QgsProject.instance()
    if project is None:
        return
    if not _LAYER_WATCH_INSTALLED:
        project.layersAdded.connect(_watch_combo_cache_layers)
        _LAYER_WATCH_INSTALLED = True
    _watch_combo_cache_layers(list(project.mapLayers().values()))


def _watch_combo_cache_layers(layers) -> None:
    for layer in layers or []:
        if not isinstance(layer, QgsVectorLayer):
            continue
        try:
            if layer.property('_gw_combo_cache_hook'):
                continue
            layer.setProperty('_gw_combo_cache_hook', True)
            layer.afterCommitChanges.connect(clear_combo_query_cache)
        except RuntimeError:
            continue


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


def _execute_combo_query(query: str, use_cache: bool = True):
    """Run ``query`` and return ``(rows, error)``."""
    if use_cache:
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
    so opening many features reuses the same combo payloads. The cache is dropped
    on project load and after a write. Opening the popup always queries again,
    so a row inserted outside QGIS shows up on the next click.
    """

    # token, rows (list of psycopg2 DictRow / tuples), error (str, '' on success)
    rows_loaded = pyqtSignal(int, list, str)

    def __init__(self, description: str, query: str, token: int, use_cache: bool = True):
        QObject.__init__(self)
        QgsTask.__init__(self, description, QgsTask.Flag.CanCancel)
        self._query = query
        self._token = token
        self._use_cache = use_cache
        self._rows = []
        self._error = ""

    @property
    def token(self) -> int:
        return self._token

    def run(self) -> bool:
        if self.isCanceled():
            return False

        self._rows, self._error = _execute_combo_query(self._query, self._use_cache)
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
