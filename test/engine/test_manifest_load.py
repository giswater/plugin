"""Manifest YAML parsing + validation."""

from __future__ import annotations

import textwrap
from pathlib import Path

import pytest

from giswater_admin.engine.manifest import ManifestError, load_manifest


def _write(tmp_path: Path, body: str) -> str:
    p = tmp_path / "m.yaml"
    p.write_text(textwrap.dedent(body), encoding="utf-8")
    return str(p)


def test_loads_minimal_manifest(tmp_path: Path):
    path = _write(
        tmp_path,
        """
        kind: ws
        engine_version: 1
        substitutions:
          FOO: bar
        phases:
          - id: load_base
            type: sql_dir
            steps:
              - { source: "ws/fct", shared_source: "ws" }
        profiles:
          empty: { phases: [load_base] }
        """,
    )
    m = load_manifest(path)
    assert m.kind == "ws"
    assert m.engine_version == 1
    assert m.substitutions == {"FOO": "bar"}
    assert len(m.phases) == 1
    assert m.phase("load_base").steps[0].source == "ws/fct"
    assert m.phase("load_base").steps[0].shared_source == "ws"
    assert m.profile("empty") == ("load_base",)


def test_rejects_missing_kind(tmp_path: Path):
    path = _write(
        tmp_path,
        """
        phases:
          - id: x
            type: sql_dir
        profiles:
          empty: { phases: [x] }
        """,
    )
    with pytest.raises(ManifestError):
        load_manifest(path)


def test_rejects_unknown_phase_type(tmp_path: Path):
    path = _write(
        tmp_path,
        """
        kind: ws
        phases:
          - id: x
            type: nope
        profiles:
          empty: { phases: [x] }
        """,
    )
    with pytest.raises(ManifestError):
        load_manifest(path)


def test_rejects_profile_referencing_unknown_phase(tmp_path: Path):
    path = _write(
        tmp_path,
        """
        kind: ws
        phases:
          - id: a
            type: sql_dir
        profiles:
          bad: { phases: [a, missing] }
        """,
    )
    with pytest.raises(ManifestError):
        load_manifest(path)


def test_unknown_profile_raises(tmp_path: Path):
    path = _write(
        tmp_path,
        """
        kind: ws
        phases:
          - id: a
            type: sql_inline
            sql: "SELECT 1"
        profiles:
          ok: { phases: [a] }
        """,
    )
    m = load_manifest(path)
    with pytest.raises(ManifestError):
        m.profile("missing")
