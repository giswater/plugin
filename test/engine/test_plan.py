"""End-to-end planner: real dbmodel manifests should produce a stable plan."""

from __future__ import annotations

import os

import pytest

from giswater_admin.engine.builder import BuildParams, SchemaBuilder
from giswater_admin.engine.manifest import load_manifest


class _FakeConn:
    def execute(self, sql, *, filepath=None): return True
    def last_error(self): return ""
    def commit(self): pass
    def rollback(self): pass
    def close(self): pass


def _manifest(manifests_path: str, kind: str):
    p = os.path.join(manifests_path, f"{kind}.yaml")
    if not os.path.isfile(p):
        pytest.skip(f"manifest not present yet: {p}")
    return load_manifest(p)


@pytest.mark.parametrize("kind,profile", [
    ("ws", "empty"),
    ("ws", "sample_full"),
    ("ud", "empty"),
    ("utils", "empty"),
    ("am", "empty"),
    ("cm", "empty"),
    ("audit", "structure"),
])
def test_plan_produces_positive_file_count(manifests_path, dbmodel_path, kind, profile):
    manifest = _manifest(manifests_path, kind)
    if profile not in manifest.profiles:
        pytest.skip(f"profile {profile} not declared for {kind}")
    params = BuildParams(
        schema_name=f"{kind}_demo",
        srid="25831",
        sql_root=dbmodel_path,
        plugin_version="4.9.0",
        profile=profile,
        ws_schema="ws_demo",
        ud_schema="ud_demo",
        parent_schema="ws_demo",
        parent_type="ws",
    )
    b = SchemaBuilder(_FakeConn(), manifest, params)
    plan = b.plan()
    total = sum(c for _, c in plan)
    # At minimum: every kind should resolve at least one phase with files.
    # (audit/structure should hit ~4 files; ws/empty hundreds; cm/empty dozens.)
    assert total > 0, f"plan for {kind}/{profile} was empty: {plan}"


@pytest.mark.parametrize("kind", ["ws", "ud"])
def test_update_step_reloads_fct_ftrg_before_patches(manifests_path, dbmodel_path, kind):
    """Lockstep network update must reload base fct/ftrg until functions live in patches."""
    manifest = _manifest(manifests_path, kind)
    params = BuildParams(
        schema_name=f"{kind}_demo",
        srid="25831",
        sql_root=dbmodel_path,
        plugin_version="4.17.0",
        project_version="4.16.0",
        run_mode="upgrade_step",
        profile="update_step",
    )
    plan = SchemaBuilder(_FakeConn(), manifest, params).plan()
    ids = [phase.id for phase, _ in plan]
    assert ids == ["reload_fct_ftrg", "updates", "register_version"]
    reload_count = next(count for phase, count in plan if phase.id == "reload_fct_ftrg")
    updates_count = next(count for phase, count in plan if phase.id == "updates")
    assert reload_count > 0, "update_step must plan base fct/ftrg files"
    assert updates_count > 0, "update_step must plan the 4.17.0 patches"


@pytest.mark.parametrize("kind", [
    "ws", "ud", "utils", "cibs", "am", "cm", "audit", "publi", "multilang",
])
def test_lockstep_profiles_declared(manifests_path, kind):
    """Network lockstep needs update_step + version_bump on every updatable kind."""
    manifest = _manifest(manifests_path, kind)
    if "update" not in manifest.profiles:
        pytest.skip(f"{kind} has no update profile")
    assert "update_step" in manifest.profiles, f"{kind} missing update_step"
    assert "version_bump" in manifest.profiles, f"{kind} missing version_bump"
    assert manifest.profiles["version_bump"].phases == ("register_version",)

