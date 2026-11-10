"""Tests for lockstep network update planning."""

from __future__ import annotations

from pathlib import Path

from giswater_admin.engine.manifest import Manifest, Profile
from giswater_admin.engine.network_update import (
    has_patch_at_version,
    plan_lockstep,
    resolve_lockstep_profile,
)
from giswater_admin.engine.schema_catalog import NetworkGraph, NetworkNode


def _write_patch(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("SELECT 1;", encoding="utf-8")


def test_has_patch_at_version_detects_fixture_roots(tmp_path: Path):
    dbmodel = tmp_path / "dbmodel"
    _write_patch(
        dbmodel / "schemas" / "addon" / "utils" / "updates" / "4" / "16" / "0" / "patch.sql"
    )
    _write_patch(
        dbmodel / "schemas" / "main" / "common" / "updates" / "4" / "16" / "0" / "patch.sql"
    )
    _write_patch(
        dbmodel / "schemas" / "main" / "ws" / "updates" / "4" / "16" / "0" / "patch.sql"
    )
    assert has_patch_at_version(str(dbmodel), "utils", (4, 16, 0))
    assert has_patch_at_version(str(dbmodel), "ws", (4, 16, 0))


def test_plan_lockstep_orders_kinds_and_versions(tmp_path: Path):
    dbmodel = tmp_path / "dbmodel"
    for rel in (
        "schemas/addon/utils/updates/4/16/0/patch.sql",
        "schemas/addon/cibs/updates/4/16/0/patch.sql",
        "schemas/main/common/updates/4/16/0/patch.sql",
        "schemas/main/ws/updates/4/16/0/patch.sql",
        "schemas/main/ud/updates/4/16/0/patch.sql",
    ):
        _write_patch(dbmodel / rel)

    graph = NetworkGraph(
        anchor="ws",
        nodes=[
            NetworkNode("ws", "ws", "4.15.0"),
            NetworkNode("ud", "ud", "4.15.0"),
            NetworkNode("utils", "utils", "4.15.0"),
            NetworkNode("cibs", "cibs", "4.15.0"),
        ],
        edges=[],
    )
    steps = plan_lockstep(graph, str(dbmodel), "4.16.0")
    assert len(steps) == 4
    assert [step.kind for step in steps] == ["utils", "cibs", "ws", "ud"]
    assert all(step.target_version == "4.16.0" for step in steps)
    assert all(step.action == "upgrade" for step in steps)


def _manifest(profiles: dict[str, tuple[str, ...]]) -> Manifest:
    return Manifest(
        kind="am",
        engine_version=1,
        substitutions={},
        phases=(),
        profiles={name: Profile(name, phases) for name, phases in profiles.items()},
    )


def test_resolve_lockstep_profile_uses_dedicated_profiles():
    manifest = _manifest({
        "update": ("load_updates", "register_version"),
        "update_step": ("load_updates", "register_version"),
        "version_bump": ("register_version",),
    })
    assert resolve_lockstep_profile(manifest, "upgrade") == "update_step"
    assert resolve_lockstep_profile(manifest, "bump") == "version_bump"


def test_resolve_lockstep_profile_falls_back_to_update():
    manifest = _manifest({"update": ("load_updates", "register_version")})
    assert resolve_lockstep_profile(manifest, "upgrade") == "update"
    assert resolve_lockstep_profile(manifest, "bump") == "update"
