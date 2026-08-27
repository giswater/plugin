"""Tests for persistent database connection in gw config."""

from __future__ import annotations

from pathlib import Path

import pytest

from giswater_admin import conn as conn_mod
from giswater_admin.install import config


@pytest.fixture
def cfg_root(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    monkeypatch.setattr(config, "config_dir", lambda: tmp_path)
    monkeypatch.setattr(config, "config_file", lambda: tmp_path / "config.yaml")
    monkeypatch.delenv("PGDATABASE", raising=False)
    monkeypatch.delenv("PGUSER", raising=False)
    monkeypatch.delenv("PGSERVICE", raising=False)
    return tmp_path


def test_resolve_from_database_conn(cfg_root: Path) -> None:
    config.set_config_value(
        "database.conn",
        "postgresql://gisadmin:secret@db.example.com:5433/mydb",
    )
    info = conn_mod.resolve(None, None)
    assert info.user == "gisadmin"
    assert info.password == "secret"
    assert info.host == "db.example.com"
    assert info.port == "5433"
    assert info.dbname == "mydb"


def test_resolve_from_database_config_file(cfg_root: Path, tmp_path: Path) -> None:
    conn_file = tmp_path / "conn.yaml"
    conn_file.write_text(
        "host: 10.0.0.5\nport: 5432\nuser: postgres\ndbname: gw_db\n",
        encoding="utf-8",
    )
    config.set_config_value("database.config", str(conn_file))
    info = conn_mod.resolve(None, None)
    assert info.host == "10.0.0.5"
    assert info.user == "postgres"
    assert info.dbname == "gw_db"


def test_cli_conn_overrides_user_config(cfg_root: Path) -> None:
    config.set_config_value("database.conn", "postgresql://local@127.0.0.1:5432/localdb")
    info = conn_mod.resolve("postgresql://override@remote:5432/remote", None)
    assert info.user == "override"
    assert info.host == "remote"
    assert info.dbname == "remote"


def test_cli_config_overrides_database_conn(cfg_root: Path, tmp_path: Path) -> None:
    config.set_config_value("database.conn", "postgresql://stored@127.0.0.1:5432/stored")
    conn_file = tmp_path / "conn.yaml"
    conn_file.write_text("host: cli\nuser: cli\ndbname: cli\n", encoding="utf-8")
    info = conn_mod.resolve(None, str(conn_file))
    assert info.host == "cli"
    assert info.dbname == "cli"


def test_database_conn_preferred_over_database_config(
    cfg_root: Path, tmp_path: Path
) -> None:
    config.set_config_value("database.conn", "postgresql://url@127.0.0.1:5432/urldb")
    conn_file = tmp_path / "conn.yaml"
    conn_file.write_text("host: file\nuser: file\ndbname: file\n", encoding="utf-8")
    config.set_config_value("database.config", str(conn_file))
    info = conn_mod.resolve(None, None)
    assert info.user == "url"
    assert info.dbname == "urldb"


def test_user_config_preferred_over_env(cfg_root: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    config.set_config_value("database.conn", "postgresql://stored@127.0.0.1:5432/stored")
    monkeypatch.setenv("PGDATABASE", "envdb")
    monkeypatch.setenv("PGUSER", "envuser")
    info = conn_mod.resolve(None, None)
    assert info.user == "stored"
    assert info.dbname == "stored"


def test_malformed_url_without_host_raises_clear_error() -> None:
    with pytest.raises(RuntimeError, match="must include host after '@'"):
        conn_mod.resolve(
            "postgresql://user:secretpassword/mydb",
            None,
        )


def test_resolve_conn_service_equals() -> None:
    info = conn_mod.resolve("service=localhost_giswater", None)
    assert info.service == "localhost_giswater"
    assert info.dbname == ""
    assert info.safe_repr() == "service=localhost_giswater"


def test_resolve_conn_bare_service_name() -> None:
    info = conn_mod.resolve("localhost_giswater", None)
    assert info.service == "localhost_giswater"


def test_resolve_conn_empty_service_rejected() -> None:
    with pytest.raises(RuntimeError, match="pg_service name"):
        conn_mod.resolve("service=", None)


def test_resolve_conn_botched_url_not_a_service() -> None:
    with pytest.raises(RuntimeError, match="postgres URL, service=NAME"):
        conn_mod.resolve("user:pass@host/db", None)


def test_no_connection_without_sources(cfg_root: Path) -> None:
    with pytest.raises(RuntimeError, match="gw config set database.conn"):
        conn_mod.resolve(None, None)


def test_has_connection_source(cfg_root: Path) -> None:
    assert not conn_mod.has_connection_source()
    config.set_config_value("database.conn", "postgresql://u@h/d")
    assert conn_mod.has_user_config()
    assert conn_mod.has_connection_source()
