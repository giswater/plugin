"""Superuser / role_system gate on ``open_conn``."""

from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from giswater_admin.commands import _helpers as h
from giswater_admin.commands._helpers import SchemaAdminRequired, SuperuserRequired
from giswater_admin.output import Out


class _CursorCtx:
    def __init__(self, row: tuple) -> None:
        self._row = row

    def __enter__(self):
        return self

    def __exit__(self, *args) -> None:
        return None

    def execute(self, sql: str) -> None:
        self._sql = sql

    def fetchone(self):
        return self._row


def _conn(row: tuple) -> MagicMock:
    conn = MagicMock()
    conn.raw.cursor.return_value = _CursorCtx(row)
    return conn


def test_user_is_superuser() -> None:
    conn = _conn(("postgres", True, True))
    user, is_super = h.user_is_superuser(conn)
    assert user == "postgres"
    assert is_super is True


def test_open_conn_rejects_plain_user() -> None:
    conn = _conn(("app_user", False, False))
    out = Out()
    args = MagicMock(conn="postgresql://app@localhost/db", config=None)
    with patch.object(h.conn_mod, "open_connection", return_value=conn):
        with pytest.raises(SchemaAdminRequired):
            h.open_conn(args, out)


def test_open_conn_accepts_superuser() -> None:
    conn = _conn(("postgres", True, False))
    out = Out()
    args = MagicMock(conn="postgresql://postgres@localhost/db", config=None)
    with patch.object(h.conn_mod, "open_connection", return_value=conn):
        opened = h.open_conn(args, out)
    assert opened is conn


def test_open_conn_accepts_role_system() -> None:
    conn = _conn(("gisadmin", False, True))
    out = Out()
    args = MagicMock(conn="postgresql://gisadmin@localhost/db", config=None)
    with patch.object(h.conn_mod, "open_connection", return_value=conn):
        opened = h.open_conn(args, out)
    assert opened is conn


def test_open_conn_require_superuser_rejects_role_system() -> None:
    conn = _conn(("gisadmin", False, True))
    out = Out()
    args = MagicMock(conn="postgresql://gisadmin@localhost/db", config=None)
    with patch.object(h.conn_mod, "open_connection", return_value=conn):
        with pytest.raises(SuperuserRequired):
            h.open_conn(args, out, require_superuser=True)


def test_open_conn_skip_schema_admin_check() -> None:
    conn = _conn(("app_user", False, False))
    out = Out()
    args = MagicMock(conn="postgresql://app@localhost/db", config=None)
    with patch.object(h.conn_mod, "open_connection", return_value=conn):
        opened = h.open_conn(args, out, require_schema_admin=False)
    assert opened is conn
