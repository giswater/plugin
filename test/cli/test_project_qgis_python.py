"""Unit tests for cross-platform PyQGIS discovery helpers."""

from __future__ import annotations

import sys
from pathlib import Path

from giswater_admin.commands import project_cmd


def test_qgis_python_candidates_prefer_env(monkeypatch) -> None:
    monkeypatch.setenv("QGIS_PYTHON", "/custom/qgis/python")
    candidates = project_cmd._qgis_python_candidates()
    assert candidates[0] == "/custom/qgis/python"
    assert sys.executable in candidates


def test_platform_candidates_do_not_crash() -> None:
    # Smoke: path probing must be safe on the current OS without QGIS installed.
    found = project_cmd._platform_candidates()
    assert isinstance(found, list)
    for item in found:
        assert isinstance(item, str)


def test_windows_launcher_detection() -> None:
    assert project_cmd._is_windows_launcher(Path("C:/OSGeo4W/bin/python-qgis.bat")) is (
        sys.platform == "win32"
    )
    assert project_cmd._is_windows_launcher(Path("/usr/bin/python3")) is False
