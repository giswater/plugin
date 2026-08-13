"""Tests for version downgrade guards."""

from __future__ import annotations

from pathlib import Path

from giswater_admin.engine.builder import BuildParams, SchemaBuilder
from giswater_admin.engine.manifest import Manifest, Phase, Profile, Step
from giswater_admin.engine.schema_catalog import NetworkGraph, NetworkNode
from giswater_admin.engine.version_guard import (
    assert_network_no_downgrade,
    assert_no_downgrade,
    version_compare,
)


def test_assert_no_downgrade_blocks():
    assert assert_no_downgrade("4.16.0", "4.15.0", label="schema 'ws'") is not None
    assert assert_no_downgrade("4.16.0", "4.16.0", label="x") is None
    assert assert_no_downgrade("4.16.0", "4.17.0", label="x") is None


def test_assert_no_downgrade_lexicographic_trap_4_15_vs_4_9_2():
    """'4.9.2' > '4.15' as strings, but semver must treat 4.15 as newer."""
    assert "4.9.2" > "4.15"  # trap still true for raw strings
    assert version_compare("4.15", "4.9.2") < 0
    assert version_compare("4.15.0", "4.9.2") < 0
    err = assert_no_downgrade("4.15", "4.9.2", label="schema 'ws'")
    assert err is not None
    assert "4.9.2" in err and "4.15" in err
    assert assert_no_downgrade("4.9.2", "4.15.0", label="x") is None


def test_assert_network_no_downgrade_blocks():
    graph = NetworkGraph(
        anchor="",
        nodes=[
            NetworkNode(schema="ws", kind="ws", version="4.16.0"),
            NetworkNode(schema="utils", kind="utils", version="4.16.0"),
        ],
        edges=[],
    )
    assert assert_network_no_downgrade(graph, "4.15.0") is not None
    assert assert_network_no_downgrade(graph, "4.17.0") is None


def test_assert_network_no_downgrade_4_15_vs_4_9_2():
    graph = NetworkGraph(
        anchor="",
        nodes=[
            NetworkNode(schema="ws", kind="ws", version="4.15.0"),
            NetworkNode(schema="utils", kind="utils", version="4.15"),
        ],
        edges=[],
    )
    err = assert_network_no_downgrade(graph, "4.9.2")
    assert err is not None
    assert "ws@4.15.0" in err
    assert "utils@4.15" in err


class _NoExecConn:
    """Fail the test if any SQL would run after a downgrade block."""

    def __init__(self) -> None:
        self.executed: list[str] = []

    def execute(self, sql: str, *, filepath: str | None = None) -> bool:
        self.executed.append(filepath or sql[:40])
        raise AssertionError("SchemaBuilder must not execute SQL on downgrade")

    def last_error(self) -> str:
        return ""

    def commit(self) -> None:
        pass

    def rollback(self) -> None:
        pass

    def close(self) -> None:
        pass


def _update_manifest() -> Manifest:
    return Manifest(
        kind="ws",
        engine_version=1,
        substitutions={},
        phases=(
            Phase(
                id="reload_fct_ftrg",
                type="sql_dir",
                steps=(Step(source="ws/fct"),),
            ),
        ),
        profiles={
            "update": Profile(name="update", phases=("reload_fct_ftrg",)),
        },
    )


def test_schema_builder_refuses_downgrade_4_15_to_4_9_2(tmp_path: Path):
    (tmp_path / "ws" / "fct").mkdir(parents=True)
    (tmp_path / "ws" / "fct" / "01.sql").write_text("-- should never run", encoding="utf-8")
    conn = _NoExecConn()
    params = BuildParams(
        schema_name="ws_demo",
        sql_root=str(tmp_path),
        plugin_version="4.9.2",
        project_version="4.15.0",
        run_mode="upgrade",
        profile="update",
    )
    result = SchemaBuilder(conn, _update_manifest(), params).run()
    assert not result.ok
    assert result.phases[0].phase_id == "version_guard"
    failure = result.first_failure()
    assert failure is not None
    assert "cannot downgrade" in failure.error
    assert "4.9.2" in failure.error
    assert conn.executed == []


def test_schema_builder_allows_equal_or_forward_upgrade(tmp_path: Path):
    (tmp_path / "ws" / "fct").mkdir(parents=True)
    (tmp_path / "ws" / "fct" / "01.sql").write_text("-- ok", encoding="utf-8")

    class _RecConn(_NoExecConn):
        def execute(self, sql: str, *, filepath: str | None = None) -> bool:
            self.executed.append(filepath or sql[:40])
            return True

    conn = _RecConn()
    params = BuildParams(
        schema_name="ws_demo",
        sql_root=str(tmp_path),
        plugin_version="4.16.0",
        project_version="4.15.0",
        run_mode="upgrade",
        profile="update",
    )
    result = SchemaBuilder(conn, _update_manifest(), params).run()
    assert result.ok
    assert any("01.sql" in p for p in conn.executed)
