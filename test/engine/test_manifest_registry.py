"""Tests for manifest-driven kind discovery."""

from __future__ import annotations

import os

import pytest

from giswater_admin.engine.manifest import load_manifest
from giswater_admin.engine.manifest_registry import (
    addon_kinds,
    all_kinds,
    integrate_profile,
    kind_update_roots,
    load_kind_manifest,
    update_kind_order,
)


@pytest.fixture
def dbmodel_path() -> str:
    root = os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "..", "dbmodel")
    )
    if not os.path.isdir(root):
        pytest.skip("dbmodel tree not available")
    return root


def test_all_kinds_includes_publi(dbmodel_path: str) -> None:
    kinds = all_kinds(dbmodel_path)
    assert "publi" in kinds
    assert "ws" in kinds
    assert "utils" in kinds


def test_addon_kinds_excludes_main(dbmodel_path: str) -> None:
    addons = addon_kinds(dbmodel_path)
    assert "publi" in addons
    assert "ws" not in addons
    assert "ud" not in addons


def test_publi_update_root(dbmodel_path: str) -> None:
    roots = kind_update_roots(dbmodel_path, "publi")
    assert roots == [os.path.join(dbmodel_path, "schemas", "addon", "publi", "updates")]


def test_update_order_includes_publi(dbmodel_path: str) -> None:
    order = update_kind_order(dbmodel_path)
    assert "publi" in order
    assert order.index("publi") < order.index("ws")


def test_integrate_profile_utils_style(dbmodel_path: str) -> None:
    manifest = load_kind_manifest(dbmodel_path, "utils")
    assert integrate_profile(manifest, "ws") == "integrate_ws"
    assert integrate_profile(manifest, "ud") == "integrate_ud"


def test_integrate_profile_cibs_style(dbmodel_path: str) -> None:
    manifest = load_manifest(os.path.join(dbmodel_path, "manifests", "cibs.yaml"))
    assert integrate_profile(manifest, "ws") == "integrate"


def test_integrate_profile_publi_style_when_present(dbmodel_path: str) -> None:
    manifest = load_kind_manifest(dbmodel_path, "publi")
    # integrate profiles are commented out in the manifest today
    assert integrate_profile(manifest, "ws") is None


def test_cmms_kind_order_and_integrate(dbmodel_path: str) -> None:
    assert "cmms" in all_kinds(dbmodel_path)
    assert "cmms" in addon_kinds(dbmodel_path)
    order = update_kind_order(dbmodel_path)
    assert order.index("ud") < order.index("cmms") < order.index("cm")
    roots = kind_update_roots(dbmodel_path, "cmms")
    assert roots == [os.path.join(dbmodel_path, "schemas", "addon", "cmms", "updates")]
    manifest = load_kind_manifest(dbmodel_path, "cmms")
    assert integrate_profile(manifest, "ws") == "integrate"
    assert integrate_profile(manifest, "ud") == "integrate"
