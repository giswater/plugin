"""sql_runner / execute_file behaviour against a fake connection."""

from __future__ import annotations

from pathlib import Path

from giswater_admin.engine.sql_runner import (
    execute_file,
    execute_function_call,
    execute_inline,
    list_sql_files,
)


class _RecConn:
    """Records every statement; can be told to fail."""

    def __init__(self, ok: bool = True, error_msg: str = "") -> None:
        self.ok = ok
        self.error_msg = error_msg
        self.executed: list[tuple[str, str | None]] = []
        self.commits = 0
        self.rollbacks = 0

    def execute(self, sql: str, *, filepath: str | None = None) -> bool:
        self.executed.append((sql, filepath))
        return self.ok

    def last_error(self) -> str:
        return self.error_msg

    def commit(self) -> None:
        self.commits += 1

    def rollback(self) -> None:
        self.rollbacks += 1

    def close(self) -> None:
        pass


def test_list_sql_files_non_recursive(tmp_path: Path):
    (tmp_path / "a.sql").write_text("-- a")
    (tmp_path / "b.sql").write_text("-- b")
    (tmp_path / "c.txt").write_text("noop")
    sub = tmp_path / "sub"
    sub.mkdir()
    (sub / "z.sql").write_text("-- z")

    flat = list_sql_files(str(tmp_path), recursive=False)
    assert [Path(p).name for p in flat] == ["a.sql", "b.sql"]


def test_list_sql_files_single_file(tmp_path: Path):
    """sql_dir sources may be a file (init.sql); listing must not skip it."""
    p = tmp_path / "init.sql"
    p.write_text("-- init", encoding="utf-8")
    assert list_sql_files(str(p)) == [str(p)]


def test_list_sql_files_recursive(tmp_path: Path):
    (tmp_path / "a.sql").write_text("-- a")
    (tmp_path / "sub").mkdir()
    (tmp_path / "sub" / "z.sql").write_text("-- z")
    rec = list_sql_files(str(tmp_path), recursive=True)
    names = [Path(p).name for p in rec]
    assert "a.sql" in names and "z.sql" in names


def test_execute_file_subs_and_commits(tmp_path: Path):
    p = tmp_path / "s.sql"
    p.write_text("INSERT INTO SCHEMA_NAME.t VALUES (SRID_VALUE);", encoding="utf-8")
    conn = _RecConn()
    fx = execute_file(conn, str(p), {"SCHEMA_NAME": "ws_x", "SRID_VALUE": "25831"}, commit=True)
    assert fx.ok
    assert fx.duration_ms >= 0
    assert conn.commits == 1
    sent, _ = conn.executed[0]
    assert sent == "INSERT INTO ws_x.t VALUES (25831);"


def test_execute_file_schema_srid_alias(tmp_path: Path):
    p = tmp_path / "geom.sql"
    p.write_text(
        "CREATE TABLE t (g geometry(Point,SCHEMA_SRID));",
        encoding="utf-8",
    )
    conn = _RecConn()
    fx = execute_file(
        conn, str(p), {"SCHEMA_SRID": "25831", "SRID_VALUE": "25831"}, commit=True
    )
    assert fx.ok
    sent, _ = conn.executed[0]
    assert sent == "CREATE TABLE t (g geometry(Point,25831));"


def test_execute_file_returns_error_on_failure(tmp_path: Path):
    p = tmp_path / "s.sql"
    p.write_text("BROKEN", encoding="utf-8")
    conn = _RecConn(ok=False, error_msg="bad")
    fx = execute_file(conn, str(p), {})
    assert not fx.ok
    assert fx.error == "bad"


def test_execute_file_missing_path():
    fx = execute_file(_RecConn(), "/tmp/does-not-exist.sql", {})
    assert not fx.ok and "not found" in fx.error


def test_execute_function_call_wraps_payload_as_jsonb():
    conn = _RecConn()
    fx = execute_function_call(
        conn, "ws.gw_fct_admin_schema_lastprocess", {"a": 1, "b": "x"}
    )
    assert fx.ok
    assert fx.duration_ms >= 0
    sent, _ = conn.executed[0]
    assert sent.startswith("SELECT ws.gw_fct_admin_schema_lastprocess(")
    assert '"a": 1' in sent and '"b": "x"' in sent


def test_execute_inline_simple():
    conn = _RecConn()
    fx = execute_inline(conn, "DROP SCHEMA IF EXISTS x CASCADE;", label="drop", commit=True)
    assert fx.ok and conn.commits == 1
    assert fx.duration_ms >= 0


def test_execute_file_records_duration_with_slow_conn(tmp_path: Path):
    import time

    class _SlowConn(_RecConn):
        def execute(self, sql: str, *, filepath: str | None = None) -> bool:
            time.sleep(0.02)
            return super().execute(sql, filepath=filepath)

    p = tmp_path / "s.sql"
    p.write_text("SELECT 1;", encoding="utf-8")
    fx = execute_file(_SlowConn(), str(p), {})
    assert fx.ok
    assert fx.duration_ms >= 15
