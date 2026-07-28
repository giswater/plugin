"""Tests for dbmodel/test/e2e_versions.py."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
E2E_VERSIONS = REPO / "dbmodel" / "test" / "e2e_versions.py"


def _load_e2e_versions():
    spec = importlib.util.spec_from_file_location("e2e_versions", E2E_VERSIONS)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_e2e_versions_script_emits_shell_assignments() -> None:
    result = subprocess.run(
        [sys.executable, str(E2E_VERSIONS)],
        capture_output=True,
        text=True,
        check=False,
        cwd=REPO,
    )
    assert result.returncode == 0, result.stderr
    lines = dict(
        line.split("=", 1) for line in result.stdout.strip().splitlines() if "=" in line
    )
    assert "TARGET_VER" in lines
    assert "PLUGIN_VER" in lines


def test_resolve_e2e_versions_matches_metadata_and_changelog() -> None:
    scripts = str(REPO / "scripts")
    if scripts not in sys.path:
        sys.path.insert(0, scripts)

    from giswater_admin.install.config import read_metadata_version
    from release_lib import parse_version, release_versions_from_headings

    module = _load_e2e_versions()
    plugin, target = module.resolve_e2e_versions(REPO)

    metadata = read_metadata_version(REPO)
    assert metadata
    assert target == metadata

    changelog = (REPO / "CHANGELOG.md").read_text(encoding="utf-8")
    released = release_versions_from_headings(changelog)
    assert released

    target_v = parse_version(target)
    latest_v = released[0]
    target_key = (target_v.major, target_v.minor, target_v.patch)
    latest_key = (latest_v.major, latest_v.minor, latest_v.patch)

    if target_key > latest_key:
        assert plugin == latest_v.text
    else:
        assert len(released) >= 2
        assert plugin == released[1].text

    plugin_v = parse_version(plugin)
    assert (plugin_v.major, plugin_v.minor, plugin_v.patch) <= (
        target_v.major,
        target_v.minor,
        target_v.patch,
    )
