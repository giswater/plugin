"""SRID resolution for addon create/integrate."""

from giswater_admin.commands._helpers import resolve_build_srid


def test_resolve_build_srid_explicit_wins() -> None:
    assert resolve_build_srid("32748", parent_epsg="25831", common_main_epsg="4326") == "32748"


def test_resolve_build_srid_parent_then_common() -> None:
    assert resolve_build_srid(None, parent_epsg="32748", common_main_epsg="25831") == "32748"
    assert resolve_build_srid(None, parent_epsg=None, common_main_epsg="32748") == "32748"


def test_resolve_build_srid_ignores_blank_and_zero() -> None:
    assert resolve_build_srid("0", parent_epsg="", common_main_epsg="32748") == "32748"
    assert resolve_build_srid(None, parent_epsg=None, common_main_epsg=None) == "25831"
