"""Multi-root ``version_walk`` interleaving (used by network ws/ud).

With ``roots: [common/updates, ws/updates]`` the engine takes the union of
all versions present in either root, sorts by semver, and for each version
yields the patch_paths in declared root order (skipping roots that lack the
version). This preserves the per-version interleaving that the old
``subdirs: [common, ws]`` layout provided, even though common and ws now
live in separate sibling trees.
"""

from __future__ import annotations

from pathlib import Path

from giswater_admin.engine.builder import BuildParams, SchemaBuilder
from giswater_admin.engine.manifest import Manifest, Phase, Profile


def _write(p: Path, content: str = "SELECT 1;") -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")


def _multi_root_manifest() -> Manifest:
    return Manifest(
        kind="ws",
        engine_version=1,
        substitutions={},
        phases=(
            Phase(
                id="updates",
                type="version_walk",
                roots=("common/updates", "ws/updates"),
                range={"mode": "{{ run_mode }}"},
            ),
        ),
        profiles={"u": Profile(name="u", phases=("updates",))},
    )


class _FakeConn:
    def __init__(self) -> None:
        self.executed: list[str] = []

    def execute(self, sql, *, filepath=None):
        self.executed.append(filepath or "")
        return True

    def last_error(self): return ""
    def commit(self): pass
    def rollback(self): pass
    def close(self): pass


def test_multi_root_union_of_versions(tmp_path: Path):
    # common has 3.6.1 and 4.0.0; ws has 4.0.0 and 4.9.0; union should
    # be {3.6.1, 4.0.0, 4.9.0}. count == 4 files total.
    _write(tmp_path / "common" / "updates" / "3" / "6" / "1" / "a.sql")
    _write(tmp_path / "common" / "updates" / "4" / "0" / "0" / "b.sql")
    _write(tmp_path / "ws" / "updates" / "4" / "0" / "0" / "c.sql")
    _write(tmp_path / "ws" / "updates" / "4" / "9" / "0" / "d.sql")

    params = BuildParams(
        schema_name="ws_demo", sql_root=str(tmp_path),
        plugin_version="4.9.0", project_version="0.0.0",
        run_mode="new_project", profile="u",
    )
    b = SchemaBuilder(_FakeConn(), _multi_root_manifest(), params)
    [(_phase, count)] = b.plan()
    assert count == 4


def test_multi_root_per_version_order_common_first(tmp_path: Path):
    """For a given version both roots present, common is executed first."""
    _write(tmp_path / "common" / "updates" / "4" / "0" / "0" / "10_common.sql")
    _write(tmp_path / "ws" / "updates" / "4" / "0" / "0" / "20_ws.sql")
    _write(tmp_path / "common" / "updates" / "4" / "1" / "0" / "30_common.sql")
    _write(tmp_path / "ws" / "updates" / "4" / "1" / "0" / "40_ws.sql")

    params = BuildParams(
        schema_name="ws_demo", sql_root=str(tmp_path),
        plugin_version="4.9.0", project_version="0.0.0",
        run_mode="new_project", profile="u",
    )
    conn = _FakeConn()
    b = SchemaBuilder(conn, _multi_root_manifest(), params)
    b.run()

    executed = [Path(p).name for p in conn.executed if p]
    assert executed == ["10_common.sql", "20_ws.sql", "30_common.sql", "40_ws.sql"]


def test_multi_root_missing_in_one_root(tmp_path: Path):
    """Version present only in ws (not common) still runs, only ws patch."""
    _write(tmp_path / "common" / "updates" / "4" / "0" / "0" / "c.sql")
    _write(tmp_path / "ws" / "updates" / "4" / "1" / "0" / "ws_only.sql")

    params = BuildParams(
        schema_name="ws_demo", sql_root=str(tmp_path),
        plugin_version="4.9.0", project_version="0.0.0",
        run_mode="new_project", profile="u",
    )
    conn = _FakeConn()
    b = SchemaBuilder(conn, _multi_root_manifest(), params)
    b.run()
    executed = [Path(p).name for p in conn.executed if p]
    assert executed == ["c.sql", "ws_only.sql"]


def test_multi_root_upgrade_range_filters_union(tmp_path: Path):
    _write(tmp_path / "common" / "updates" / "4" / "0" / "0" / "a.sql")
    _write(tmp_path / "common" / "updates" / "4" / "8" / "0" / "b.sql")
    _write(tmp_path / "ws" / "updates" / "4" / "8" / "0" / "c.sql")
    _write(tmp_path / "ws" / "updates" / "4" / "9" / "0" / "d.sql")
    _write(tmp_path / "ws" / "updates" / "5" / "0" / "0" / "ignored.sql")

    params = BuildParams(
        schema_name="ws_demo", sql_root=str(tmp_path),
        plugin_version="4.9.0", project_version="4.0.0",
        run_mode="upgrade", profile="u",
    )
    b = SchemaBuilder(_FakeConn(), _multi_root_manifest(), params)
    [(_phase, count)] = b.plan()
    # strictly > 4.0.0 and <= 4.9.0 -> 4.8.0 (common+ws=2) + 4.9.0 (ws=1) = 3
    assert count == 3


def test_root_and_roots_mutually_exclusive(tmp_path: Path):
    """Manifest loader rejects both ``root`` and ``roots`` declared."""
    import pytest
    from giswater_admin.engine.manifest import ManifestError, load_manifest

    p = tmp_path / "bad.yaml"
    p.write_text(
        "kind: ws\n"
        "phases:\n"
        "  - id: u\n"
        "    type: version_walk\n"
        "    root: updates\n"
        "    roots: [a, b]\n"
        "profiles:\n"
        "  default:\n"
        "    phases: [u]\n",
        encoding="utf-8",
    )
    with pytest.raises(ManifestError, match="mutually exclusive"):
        load_manifest(str(p))


def test_upgrade_step_applies_single_version(tmp_path: Path):
    _write(tmp_path / "common" / "updates" / "4" / "15" / "0" / "skip.sql")
    _write(tmp_path / "common" / "updates" / "4" / "16" / "0" / "apply.sql")
    _write(tmp_path / "ws" / "updates" / "4" / "16" / "0" / "ws.sql")

    params = BuildParams(
        schema_name="ws_demo",
        sql_root=str(tmp_path),
        plugin_version="4.16.0",
        project_version="4.15.0",
        run_mode="upgrade_step",
        profile="u",
    )
    conn = _FakeConn()
    SchemaBuilder(conn, _multi_root_manifest(), params).run()
    executed = [Path(p).name for p in conn.executed if p]
    assert executed == ["apply.sql", "ws.sql"]
