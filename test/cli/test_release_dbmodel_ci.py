"""Tests for dbmodel CI verification SHA selection."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pytest

SCRIPTS = Path(__file__).resolve().parents[2] / "scripts"
sys.path.insert(0, str(SCRIPTS))

from release_lib import (  # noqa: E402
    resolve_dbmodel_ci_verification_sha,
)


def _git(cwd: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=cwd,
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


@pytest.fixture
def repo(tmp_path: Path) -> Path:
    root = tmp_path / "repo"
    root.mkdir()
    _git(root, "init")
    _git(root, "config", "user.email", "test@example.com")
    _git(root, "config", "user.name", "Test User")

    (root / "dbmodel").mkdir()
    (root / "dbmodel" / "schema.sql").write_text("v1\n", encoding="utf-8")
    (root / "CHANGELOG.md").write_text("# Changelog\n", encoding="utf-8")
    _git(root, "add", ".")
    _git(root, "commit", "-m", "initial")
    _git(root, "tag", "v1.0.0")
    return root


def test_verifies_push_tip_not_intermediate_dbmodel_commit(repo: Path) -> None:
    (repo / "dbmodel" / "schema.sql").write_text("v2\n", encoding="utf-8")
    _git(repo, "add", "dbmodel/schema.sql")
    _git(repo, "commit", "-m", "fix(dbmodel): change schema")
    dbmodel_sha = _git(repo, "rev-parse", "HEAD")

    (repo / "core.py").write_text("print('admin')\n", encoding="utf-8")
    _git(repo, "add", "core.py")
    _git(repo, "commit", "-m", "fix(admin): unrelated change")
    push_tip = _git(repo, "rev-parse", "HEAD")

    assert push_tip != dbmodel_sha
    assert (
        resolve_dbmodel_ci_verification_sha(
            repo, since_tag="v1.0.0", end=push_tip
        )
        == push_tip
    )


def test_skips_release_metadata_commit_on_top(repo: Path) -> None:
    (repo / "dbmodel" / "schema.sql").write_text("v2\n", encoding="utf-8")
    _git(repo, "add", "dbmodel/schema.sql")
    _git(repo, "commit", "-m", "fix(dbmodel): change schema")

    (repo / "core.py").write_text("print('admin')\n", encoding="utf-8")
    _git(repo, "add", "core.py")
    _git(repo, "commit", "-m", "fix(admin): unrelated change")
    push_tip = _git(repo, "rev-parse", "HEAD")

    (repo / "CHANGELOG.md").write_text("# Changelog\n\n## [1.0.1]\n", encoding="utf-8")
    _git(repo, "add", "CHANGELOG.md")
    _git(repo, "commit", "-m", "chore(release): prepare 1.0.1")
    release_sha = _git(repo, "rev-parse", "HEAD")

    assert (
        resolve_dbmodel_ci_verification_sha(
            repo, since_tag="v1.0.0", end=release_sha
        )
        == push_tip
    )
