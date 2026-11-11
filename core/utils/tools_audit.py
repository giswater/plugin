"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import json
import threading
import time

from ...libs import lib_vars, tools_db, tools_log
from .activity_body import cap_utf8, shape_activity_body

# Allowlist of calls written to audit.activity. Failures of every gw_fct_* go to
# audit.error and do not consult this set. Widen it only in a plugin release.
_ACTIVITY_FUNCTIONS = frozenset((
    'gw_fct_setarcdivide',
    'gw_fct_setarcfusion',
    'gw_fct_setmincut',
    'gw_fct_config_mapzones',
    'gw_fct_graphanalytics_mapzones_advanced',
    'gw_fct_setrepairpsector',
    'gw_fct_psector_duplicate',
    'gw_fct_create_dscenario_empty',
    'gw_fct_manage_dscenario_values',
    'gw_fct_duplicate_dscenario',
))

_PURGE_S = 3600
_tls = threading.local()

_INSERT_ACTIVITY = (
    "INSERT INTO audit.activity (schema_name, kind, name, status, body) "
    "VALUES (%s, %s, %s, %s, %s::jsonb)"
)
_INSERT_ERROR = (
    "INSERT INTO audit.error (schema_name, function_name, status, message, sqlstate, origin) "
    "VALUES (%s, %s, %s, %s, %s, 'call')"
)
_BUMP = "SELECT audit.gw_fct_activity_user_bump(%s, %s, %s)"
_PURGE = "SELECT audit.gw_fct_activity_purge()"
# has_table_privilege is false for a column-only INSERT grant.
_PROBE = """
SELECT CASE
    WHEN to_regclass('audit.activity') IS NULL THEN false
    WHEN to_regclass('audit.error') IS NULL THEN false
    WHEN has_any_column_privilege('audit.activity', 'INSERT') IS NOT TRUE THEN false
    WHEN has_any_column_privilege('audit.error', 'INSERT') IS NOT TRUE THEN false
    ELSE true
END
"""
_PROBE_BUMP = """
SELECT CASE
    WHEN to_regclass('audit.activity_user') IS NULL THEN false
    WHEN to_regprocedure('audit.gw_fct_activity_user_bump(text,text,text)') IS NULL THEN false
    WHEN has_function_privilege(
        'audit.gw_fct_activity_user_bump(text,text,text)', 'EXECUTE') IS NOT TRUE THEN false
    ELSE true
END
"""


class _State(object):
    """UI-thread cache for the audit connection. Workers do not use it."""

    def __init__(self):
        self.conn = None
        self.off = False
        self.probed = False
        self.enabled = False
        self.bump = False
        self.last_purge = 0.0


def trace(event):
    """Record that the user entered a flow. No-op when the audit addon is absent."""
    name = '' if event is None else str(event)
    _write('place', name, '', {}, False, force_purge=(event == 'project'))


def reset():
    """Close the UI audit connection and clear session flags."""
    st = getattr(_tls, 'st', None)
    if st is not None and st.conn is not None:
        _drop(st.conn)
    _tls.st = None


def snapshot(function_name, parameters):
    """Shaped body for an allowlisted call, taken before the caller rewrites it."""
    try:
        if _bare_name(function_name) not in _ACTIVITY_FUNCTIONS:
            return None
        return shape_activity_body(parameters)
    except Exception:
        return {'unparseable': True, 'bytes': 0}


def after_call(function_name, body, json_result, last_error, is_thread):
    """One row after a gw_fct_* call. The mincut cursor uses this too; its except does not."""
    try:
        name = _bare_name(function_name)
        if _is_failure(json_result, last_error):
            status, message, sqlstate = _error_bits(json_result, last_error)
            _write('error', name, status, None, is_thread, message, sqlstate)
            return
        if not isinstance(json_result, dict):
            return
        if json_result.get('status') == 'Accepted' and name in _ACTIVITY_FUNCTIONS:
            if not isinstance(body, dict):
                body = shape_activity_body(body)
            _write('call', name, 'Accepted', body or {}, is_thread)
    except Exception as exc:
        _log(exc)


def _state():
    st = getattr(_tls, 'st', None)
    if st is None:
        st = _State()
        _tls.st = st
    return st


def _log(exc):
    if exc is None:
        return
    try:
        detail = cap_utf8(str(exc), 300)
        tools_log.log_info("Activity trace skipped: {0}", msg_params=(detail,))
    except Exception:
        pass


def _schema():
    name = lib_vars.schema_name
    if not name:
        return ''
    return str(name)


def _bare_name(function_name):
    if not isinstance(function_name, str):
        return ''
    return function_name.rsplit('.', 1)[-1]


def _closed(conn):
    return conn is None or getattr(conn, 'closed', 1) != 0


def _drop(conn):
    if conn is None:
        return
    try:
        if tools_db.dao is not None:
            tools_db.dao.delete_aux_con(conn)
            return
    except Exception:
        pass
    try:
        conn.close()
    except Exception:
        pass


def _open():
    """Own autocommit connection. Never the caller's dao or aux_conn."""
    if tools_db.dao is None:
        return None
    try:
        conn = tools_db.dao.get_aux_conn()
    except Exception as exc:
        _log(exc)
        return None
    if conn is None:
        return None
    try:
        conn.autocommit = True
    except Exception as exc:
        _drop(conn)
        _log(exc)
        return None
    return conn


def _exec(conn, sql, params):
    """Run SQL on the audit connection. Does not touch dao.last_error."""
    cur = None
    try:
        cur = conn.cursor()
        if params is None:
            cur.execute(sql)
        else:
            cur.execute(sql, params)
        row = cur.fetchone() if cur.description is not None else None
        return True, row
    except Exception as exc:
        return False, exc
    finally:
        if cur is not None:
            try:
                cur.close()
            except Exception:
                pass


def _probe_conn(conn):
    ok, row = _exec(conn, _PROBE, None)
    if not ok:
        return False, False, row
    if not (row and row[0]):
        return False, False, None
    ok_bump, row_bump = _exec(conn, _PROBE_BUMP, None)
    if not ok_bump:
        return True, False, None
    return True, bool(row_bump and row_bump[0]), None


def _close_cached(st):
    _drop(st.conn)
    st.conn = None


def _ui_reopen(st):
    _close_cached(st)
    conn = _open()
    if conn is None:
        st.off = True
        return None
    st.conn = conn
    return conn


def _ui_conn(st):
    conn = st.conn
    if conn is not None and _closed(conn):
        _close_cached(st)
        conn = None
    if conn is None:
        conn = _open()
        if conn is None:
            st.off = True
            return None
        st.conn = conn
    return conn


def _ensure_probed(st):
    if st.probed:
        return st.enabled
    enabled, bump, err = _probe_conn(st.conn)
    if err is not None and _closed(st.conn):
        if _ui_reopen(st) is None:
            return False
        enabled, bump, err = _probe_conn(st.conn)
        if err is not None and _closed(st.conn):
            st.off = True
            _log(err)
            return False
    if err is not None:
        _log(err)
        st.probed = True
        st.enabled = False
        st.bump = False
        _close_cached(st)
        return False
    st.probed = True
    st.enabled = enabled
    st.bump = bump
    if not enabled:
        _close_cached(st)
    return enabled


def _maybe_purge(st, force):
    now = time.monotonic()
    if not force and (now - st.last_purge) < _PURGE_S:
        return
    st.last_purge = now
    if st.conn is None:
        return
    ok, err = _exec(st.conn, _PURGE, None)
    if ok:
        return
    _log(err)
    if _closed(st.conn):
        _ui_reopen(st)


def _reopen(st, is_thread, conn):
    if is_thread:
        _drop(conn)
        return _open()
    return _ui_reopen(st)


def _insert(conn, sql, params, kind, name, bump, st, is_thread):
    ok, err = _exec(conn, sql, params)
    if not ok and _closed(conn):
        conn = _reopen(st, is_thread, conn)
        if conn is None:
            return None
        ok, err = _exec(conn, sql, params)
        if not ok and _closed(conn) and st is not None and not is_thread:
            st.off = True
    if not ok:
        _log(err)
        return conn
    if not bump:
        return conn
    ok_bump, err_bump = _exec(conn, _BUMP, (_schema(), kind, name))
    if not ok_bump:
        _log(err_bump)
    return conn


def _run_worker(sql, params, kind, name):
    conn = _open()
    if conn is None:
        return
    live = conn
    try:
        enabled, bump, err = _probe_conn(conn)
        if not enabled:
            # A failed worker connect must not turn the UI writer off.
            if err is not None and not _closed(conn):
                _log(err)
            return
        live = _insert(conn, sql, params, kind, name, bump, None, True) or conn
    finally:
        _drop(live)
        if live is not conn:
            _drop(conn)


def _run_ui(sql, params, kind, name, force_purge):
    st = _state()
    if st.off or (st.probed and not st.enabled):
        return
    if _ui_conn(st) is None:
        return
    if not _ensure_probed(st):
        return
    _maybe_purge(st, force_purge)
    if st.conn is None:
        return
    live = _insert(st.conn, sql, params, kind, name, st.bump, st, False)
    if live is not None:
        st.conn = live


def _run(is_thread, sql, params, kind, name, force_purge):
    if tools_db.dao is None:
        return
    if is_thread:
        _run_worker(sql, params, kind, name)
        return
    _run_ui(sql, params, kind, name, force_purge)


def _message(json_result):
    msg = json_result.get('message')
    if isinstance(msg, dict):
        msg = msg.get('text') or ''
    if not msg:
        msg = json_result.get('NOSQLERR') or json_result.get('SQLERR') or json_result.get('MSGERR') or ''
    if isinstance(msg, dict):
        msg = msg.get('text') or ''
    if msg is None:
        return ''
    return str(msg)


def _error_bits(json_result, last_error):
    status = ''
    message = ''
    sqlstate = ''
    if isinstance(json_result, dict):
        if json_result.get('status') is not None:
            status = str(json_result.get('status'))
        message = _message(json_result)
        sqlstate = str(json_result.get('SQLSTATE') or json_result.get('sqlstate') or '')
    if last_error is not None:
        if not message:
            message = str(last_error)
        pgcode = getattr(last_error, 'pgcode', None)
        if pgcode and not sqlstate:
            sqlstate = str(pgcode)
        if not status:
            status = 'Error'
    return status, cap_utf8(message), cap_utf8(sqlstate, 64)


def _is_failure(json_result, last_error):
    if isinstance(json_result, dict):
        status = json_result.get('status')
        if status in ('Failed', 'Error'):
            return True
        if 'status' not in json_result:
            return True
        return False
    if json_result is False:
        return True
    return last_error is not None


def _write(kind, name, status, body, is_thread, message='', sqlstate='', force_purge=False):
    try:
        schema = _schema()
        if kind == 'error':
            sql = _INSERT_ERROR
            params = (schema, name or '', status or '', message or '', sqlstate or '')
        else:
            payload = body if isinstance(body, dict) else {}
            sql = _INSERT_ACTIVITY
            params = (
                schema, kind, name or '', status or '',
                json.dumps(payload, ensure_ascii=False, default=str),
            )
        _run(is_thread, sql, params, kind, name or '', force_purge)
    except Exception as exc:
        _log(exc)
