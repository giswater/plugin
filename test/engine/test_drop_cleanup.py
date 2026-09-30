"""drop_schema issues cmms link cleanup and still drops if cleanup errors."""

from __future__ import annotations

from giswater_admin.engine.builder import drop_schema


class _FakeConn:
    def __init__(self, fail_marker: str = "") -> None:
        self.sql: list[str] = []
        self.fail_marker = fail_marker
        self.commits = 0
        self.rollbacks = 0

    def execute(self, sql: str, *, filepath: str | None = None) -> bool:
        self.sql.append(sql)
        if self.fail_marker and self.fail_marker in sql:
            return False
        return True

    def last_error(self) -> str:
        return "cleanup failed" if self.fail_marker else ""

    def commit(self) -> None:
        self.commits += 1

    def rollback(self) -> None:
        self.rollbacks += 1

    def close(self) -> None:
        pass


def _labels(sqls: list[str]) -> list[str]:
    out = []
    for sql in sqls:
        if "gw_drop_pre" in sql:
            out.append("pre")
        elif sql.strip().startswith("DROP SCHEMA"):
            out.append("drop")
        elif "gw_drop_post" in sql:
            out.append("post")
        elif "SET ROLE role_system" in sql:
            out.append("set_role")
        elif sql.strip() == "RESET ROLE;":
            out.append("reset")
    return out


def test_drop_runs_unlink_then_drop_then_remove_satellite() -> None:
    conn = _FakeConn()
    fx = drop_schema(conn, "cmms", cascade=True, commit=True)
    assert fx.ok
    assert fx.notes == ""
    assert conn.commits == 1
    labels = _labels(conn.sql)
    assert labels.index("pre") < labels.index("drop") < labels.index("post")
    pre = next(sql for sql in conn.sql if "gw_drop_pre" in sql)
    post = next(sql for sql in conn.sql if "gw_drop_post" in sql)
    assert "gw_fct_cmms_unlink_parent" in pre
    assert "removeSatellite" in post
    assert labels[-1] == "reset"


def test_drop_succeeds_when_pre_cleanup_errors() -> None:
    conn = _FakeConn(fail_marker="gw_drop_pre")
    fx = drop_schema(conn, "ws_demo", cascade=True, commit=True)
    assert fx.ok
    assert "cleanup failed" in fx.notes
    labels = _labels(conn.sql)
    assert "drop" in labels
    assert conn.rollbacks >= 1
    assert conn.commits == 1


def test_drop_succeeds_when_post_cleanup_errors() -> None:
    conn = _FakeConn(fail_marker="gw_drop_post")
    fx = drop_schema(conn, "cmms", cascade=True, commit=True)
    assert fx.ok
    assert "cleanup failed" in fx.notes
    drops = [sql for sql in conn.sql if sql.strip().startswith("DROP SCHEMA")]
    assert len(drops) == 2
    assert conn.commits == 1
