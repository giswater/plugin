"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import queue
import threading
import time
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

# One aux connection for every combo query. Each info form used to start one
# QgsTask per combo; the task pool put them on different threads and each
# thread called get_aux_conn(). With pg_hba PAM that is one ROPC login per
# combo, and Keycloak locks the user (user_temporarily_disabled).
_JOB_QUEUE = queue.Queue()
_WORKER_LOCK = threading.Lock()
_WORKER_STARTED = False
_CONN_EPOCH = 0
_CONN_EPOCH_LOCK = threading.Lock()
# After a failed connect, do not open again for every queued combo.
_CONNECT_RETRY_SECONDS = 30


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
    """Drop cached combo rows so the next form fill hits Postgres.

    Also retires the shared aux connection. A project switch changes
    search_path; the next query opens one new connection, not one per combo.
    """
    global _CONN_EPOCH
    with _COMBO_CACHE_LOCK:
        _COMBO_QUERY_CACHE.clear()
    with _CONN_EPOCH_LOCK:
        _CONN_EPOCH += 1


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


def _close_aux(conn) -> None:
    if conn is None:
        return
    try:
        tools_db.dao.delete_aux_con(conn)
    except Exception:
        pass


def _ensure_combo_worker() -> None:
    global _WORKER_STARTED
    with _WORKER_LOCK:
        if _WORKER_STARTED:
            return
        thread = threading.Thread(target=_combo_aux_worker, name="gw-combo-aux", daemon=True)
        thread.start()
        _WORKER_STARTED = True


def _open_aux(last_fail):
    """Open the shared aux connection. ``last_fail`` is ``(monotonic, error)``."""
    when, err = last_fail
    if err and (time.monotonic() - when) < _CONNECT_RETRY_SECONDS:
        return None, err, last_fail
    try:
        aux_result = tools_db.dao.get_aux_conn()
    except Exception as exc:
        fail = (time.monotonic(), f"get_aux_conn failed: {exc}")
        return None, fail[1], fail
    if aux_result is None or isinstance(aux_result, dict):
        message = ""
        if isinstance(aux_result, dict):
            message = str(aux_result.get("last_error") or "")
        fail = (time.monotonic(), message or "Could not get auxiliary connection")
        return None, fail[1], fail
    return aux_result, "", (0.0, "")


def _query_on_conn(conn, query: str):
    """Run one combo query. Returns ``(rows, error, conn_or_none)``.

    A bad SQL statement keeps the connection. A dead connection is closed so
    the next job opens one new session, not one per remaining combo.
    """
    try:
        cursor = tools_db.dao.get_cursor(conn)
        cursor.execute(query)
        rows = cursor.fetchall()
        cursor.close()
        conn.commit()
        materialized = [(_safe_get(r, 0), _safe_get(r, 1)) for r in rows or []]
        _cache_put(query, materialized)
        return materialized, "", conn
    except Exception as exc:
        fatal = exc.__class__.__name__ in ("OperationalError", "InterfaceError")
        if not fatal:
            try:
                conn.rollback()
            except Exception:
                fatal = True
        if fatal:
            _close_aux(conn)
            return [], str(exc), None
        return [], str(exc), conn


def _combo_aux_worker() -> None:
    """Own the only combo aux connection. Jobs from every info form share it."""
    conn = None
    epoch = -1
    last_fail = (0.0, "")
    while True:
        job = _JOB_QUEUE.get()
        if job is None:
            _close_aux(conn)
            return
        query, use_cache, slot, event = job
        try:
            if use_cache:
                cached = get_combo_rows_cached(query)
                if cached is not None:
                    slot[0] = cached
                    slot[1] = ""
                    continue
            with _CONN_EPOCH_LOCK:
                current_epoch = _CONN_EPOCH
            if conn is not None and epoch != current_epoch:
                _close_aux(conn)
                conn = None
            epoch = current_epoch
            closed = True
            if conn is not None:
                try:
                    closed = bool(conn.closed)
                except Exception:
                    closed = True
            if closed:
                conn, err, last_fail = _open_aux(last_fail)
                if conn is None:
                    slot[0] = []
                    slot[1] = err
                    continue
            rows, err, conn = _query_on_conn(conn, query)
            slot[0] = rows
            slot[1] = err
        except Exception as exc:
            slot[0] = []
            slot[1] = str(exc)
            _close_aux(conn)
            conn = None
            last_fail = (time.monotonic(), slot[1])
        finally:
            event.set()


def _execute_combo_query(query: str, use_cache: bool = True, cancel_check=None):
    """Run ``query`` on the shared aux connection. Returns ``(rows, error)``."""
    if use_cache:
        cached = get_combo_rows_cached(query)
        if cached is not None:
            return cached, ""

    _ensure_combo_worker()
    slot = [None, ""]
    event = threading.Event()
    _JOB_QUEUE.put((query, use_cache, slot, event))
    while not event.wait(0.05):
        if cancel_check is not None and cancel_check():
            return [], "cancelled"
    return slot[0] or [], slot[1]


class GwComboLoaderTask(QgsTask, QObject):
    """Background task that loads dv_querytext rows for an async combo widget.

    Each `GwAsyncComboBox` owns a monotonically increasing token. When the user
    triggers a reload (e.g. parent combo changed), the widget bumps the token
    and starts a new task. The signal handler in the widget ignores results
    coming from older tokens so stale rows can never overwrite fresh data.

    Every combo query runs on one background thread and one aux connection, so
    opening an info form does not open one Postgres session per combo. Identical
    SQL is cached for the session. The cache is dropped on project load and
    after a write. Opening the popup always queries again.
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

        self._rows, self._error = _execute_combo_query(
            self._query, self._use_cache, cancel_check=self.isCanceled
        )
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
