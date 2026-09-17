"""Download and cache dbmodel trees from published plugin releases."""

from __future__ import annotations

import re
import tempfile
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

from .config import cache_dir, release_dbmodel_dir

_VERSION_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")
_GITHUB_REPO = "giswater/plugin"
_DBMODEL_MARKER = "dbmodel/manifests/ws.yaml"


def parse_version(version: str) -> tuple[int, int, int] | None:
    m = _VERSION_RE.match(version.strip())
    if not m:
        return None
    return int(m.group(1)), int(m.group(2)), int(m.group(3))


def version_str(version: tuple[int, int, int]) -> str:
    return f"{version[0]}.{version[1]}.{version[2]}"


def zip_url(base_url: str, version: tuple[int, int, int]) -> str:
    major, minor, patch = version
    base = base_url.rstrip("/")
    return f"{base}/{major}/{minor}/{patch}/giswater.zip"


def github_release_zip_url(version: str) -> str:
    return f"https://github.com/{_GITHUB_REPO}/releases/download/v{version}/giswater.zip"


def github_tag_archive_url(version: str) -> str:
    return f"https://github.com/{_GITHUB_REPO}/archive/refs/tags/v{version}.zip"


def install_zip_urls(base_url: str, version: str) -> list[str]:
    parsed = parse_version(version)
    if parsed is None:
        raise RuntimeError(f"Invalid version {version!r}; expected X.Y.Z")
    return [
        zip_url(base_url, parsed),
        github_release_zip_url(version),
        github_tag_archive_url(version),
    ]


def pointer_url(base_url: str, major: int) -> str:
    base = base_url.rstrip("/")
    return f"{base}/{major}/giswater.xml"


def fetch_text(url: str, *, timeout: float = 120.0) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": "giswater-cli"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read().decode("utf-8")


def parse_plugin_xml_version(xml_text: str) -> str | None:
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError:
        return None
    for plugin in root.findall(".//pyqgis_plugin"):
        version = plugin.attrib.get("version")
        if version:
            return version.strip()
    return None


def parse_plugin_xml_download_url(xml_text: str) -> str | None:
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError:
        return None
    for tag in ("download_url", "download-url"):
        node = root.find(f".//{tag}")
        if node is not None and node.text:
            return node.text.strip()
    return None


def fetch_latest_version(base_url: str, *, major: int = 4) -> str:
    url = pointer_url(base_url, major)
    try:
        xml_text = fetch_text(url)
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"Could not fetch latest version from {url}: HTTP {e.code}") from e
    except urllib.error.URLError as e:
        raise RuntimeError(f"Could not fetch latest version from {url}: {e.reason}") from e
    version = parse_plugin_xml_version(xml_text)
    if not version:
        raise RuntimeError(f"No version found in plugin XML at {url}")
    if parse_version(version) is None:
        raise RuntimeError(f"Invalid version in plugin XML at {url}: {version!r}")
    return version


def download_bytes(url: str, *, timeout: float = 300.0) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "giswater-cli"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read()


def dbmodel_zip_prefix(names: list[str]) -> str:
    """Return the zip folder that contains ``dbmodel/manifests/ws.yaml``."""
    for name in names:
        if name.endswith(_DBMODEL_MARKER) and not name.endswith("/"):
            return name[: -len("manifests/ws.yaml")]
    raise RuntimeError(
        "ZIP does not contain dbmodel/manifests/ws.yaml "
        "(tried plugin ZIP and GitHub tag archive layouts)"
    )


def extract_dbmodel_from_zip(zip_bytes: bytes, dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".zip", delete=False) as tmp:
        tmp.write(zip_bytes)
        tmp_path = tmp.name
    try:
        with zipfile.ZipFile(tmp_path) as zf:
            prefix = dbmodel_zip_prefix(zf.namelist())
            for name in zf.namelist():
                if not name.startswith(prefix) or name.endswith("/"):
                    continue
                rel = name[len(prefix):]
                target = dest / rel
                target.parent.mkdir(parents=True, exist_ok=True)
                with zf.open(name) as src, target.open("wb") as dst:
                    dst.write(src.read())
    finally:
        Path(tmp_path).unlink(missing_ok=True)


def install_release(
    version: str,
    *,
    base_url: str,
    force: bool = False,
) -> Path:
    parsed = parse_version(version)
    if parsed is None:
        raise RuntimeError(f"Invalid version {version!r}; expected X.Y.Z")

    dest = release_dbmodel_dir(version)
    marker = dest / "manifests" / "ws.yaml"
    if marker.is_file() and not force:
        return dest

    errors: list[str] = []
    payload: bytes | None = None
    for url in install_zip_urls(base_url, version):
        try:
            payload = download_bytes(url)
            break
        except urllib.error.HTTPError as e:
            errors.append(f"{url}: HTTP {e.code}")
        except urllib.error.URLError as e:
            errors.append(f"{url}: {e.reason}")
    if payload is None:
        detail = "; ".join(errors) if errors else "no URLs"
        raise RuntimeError(f"Could not download dbmodel {version} ({detail})")

    if dest.exists() and force:
        import shutil

        shutil.rmtree(dest)
    extract_dbmodel_from_zip(payload, dest)
    if not marker.is_file():
        raise RuntimeError(f"Extracted dbmodel at {dest} is missing manifests/ws.yaml")
    cache_dir().mkdir(parents=True, exist_ok=True)
    return dest


def install_latest(
    *,
    base_url: str,
    major: int = 4,
    force: bool = False,
) -> tuple[str, Path]:
    version = fetch_latest_version(base_url, major=major)
    path = install_release(version, base_url=base_url, force=force)
    return version, path
