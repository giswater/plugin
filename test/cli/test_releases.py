"""Tests for release download helpers (offline)."""

from __future__ import annotations

import io
import urllib.error
import zipfile

from giswater_admin.install import releases


def test_parse_version() -> None:
    assert releases.parse_version("4.9.0") == (4, 9, 0)
    assert releases.parse_version("bad") is None


def test_parse_plugin_xml_version() -> None:
    xml = """<?xml version="1.0"?>
    <plugins>
      <pyqgis_plugin name="giswater" version="4.9.0">
        <download_url>https://example.org/giswater.zip</download_url>
      </pyqgis_plugin>
    </plugins>"""
    assert releases.parse_plugin_xml_version(xml) == "4.9.0"
    assert releases.parse_plugin_xml_download_url(xml) == "https://example.org/giswater.zip"


def test_extract_dbmodel_from_zip(tmp_path) -> None:
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as zf:
        zf.writestr("giswater/dbmodel/manifests/ws.yaml", "kind: ws\n")
        zf.writestr("giswater/dbmodel/schemas/main/common/base/init.sql", "SELECT 1;\n")
    dest = tmp_path / "dbmodel"
    releases.extract_dbmodel_from_zip(buf.getvalue(), dest)
    assert (dest / "manifests" / "ws.yaml").is_file()
    assert (dest / "schemas" / "main" / "common" / "base" / "init.sql").is_file()


def test_zip_url() -> None:
    assert (
        releases.zip_url("https://download.giswater.org/plugin", (4, 8, 2))
        == "https://download.giswater.org/plugin/4/8/2/giswater.zip"
    )


def test_install_zip_urls_order() -> None:
    urls = releases.install_zip_urls("https://download.giswater.org/plugin", "4.17.0")
    assert urls == [
        "https://download.giswater.org/plugin/4/17/0/giswater.zip",
        "https://github.com/giswater/plugin/releases/download/v4.17.0/giswater.zip",
        "https://github.com/giswater/plugin/archive/refs/tags/v4.17.0.zip",
    ]


def test_extract_dbmodel_from_github_tag_archive(tmp_path) -> None:
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as zf:
        zf.writestr("plugin-4.17.0/dbmodel/manifests/ws.yaml", "kind: ws\n")
        zf.writestr("plugin-4.17.0/README.md", "nope\n")
    dest = tmp_path / "dbmodel"
    releases.extract_dbmodel_from_zip(buf.getvalue(), dest)
    assert (dest / "manifests" / "ws.yaml").is_file()
    assert not (dest / "README.md").exists()


def test_install_release_falls_back_after_404(tmp_path, monkeypatch) -> None:
    plugin_zip = io.BytesIO()
    with zipfile.ZipFile(plugin_zip, "w") as zf:
        zf.writestr("plugin-4.17.0/dbmodel/manifests/ws.yaml", "kind: ws\n")

    calls: list[str] = []

    def fake_download(url: str, *, timeout: float = 300.0) -> bytes:
        calls.append(url)
        if "download.giswater.org" in url or "releases/download" in url:
            raise urllib.error.HTTPError(url, 404, "Not Found", hdrs=None, fp=None)
        return plugin_zip.getvalue()

    monkeypatch.setattr(releases, "release_dbmodel_dir", lambda version: tmp_path / version)
    monkeypatch.setattr(releases, "cache_dir", lambda: tmp_path)
    monkeypatch.setattr(releases, "download_bytes", fake_download)
    dest = releases.install_release("4.17.0", base_url="https://download.giswater.org/plugin")
    assert (dest / "manifests" / "ws.yaml").is_file()
    assert len(calls) == 3
