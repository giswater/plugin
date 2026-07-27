"""
UI-independent language package resolution, download, and installed-state tracking.

Used by the Manage Languages dialog and by automatic post-connection provisioning.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import tempfile
import urllib.error
import urllib.request
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Iterable, Optional

from ...libs import tools_qt
from .i18n_baseline_seed import (
    TRANSLATABLE_PROJECT_TYPES,
    normalize_language_folder,
    normalize_language_id,
)

TRANSLATIONS_REPO_URL = "https://github.com/giswater/translations/raw/main"
TRANSLATIONS_GITHUB_TREE_URL = (
    "https://api.github.com/repos/Giswater/translations/git/trees/main?recursive=1"
)
_VERSION_FOLDER_RE = re.compile(r"^(\d+)/(\d+)/(\d+)$")

I18N_SCHEMAS = {
    "ws": "schemas/main/ws/final_pass/i18n",
    "ud": "schemas/main/ud/final_pass/i18n",
    "am": "schemas/addon/am/final_pass/i18n",
    "cm": "schemas/addon/cm/final_pass/i18n",
    "python": "i18n",
}
TS_NAME = "giswater"

# Locales that do not require downloaded translation packages.
_NO_DOWNLOAD_LOCALES = frozenset({"en_us", "no_tr"})

RowFetcher = Callable[[str, Optional[list]], Optional[list[tuple]]]

_available_versions_cache: list[str] | None = None


@dataclass
class LocaleRequirement:
    """One locale needed for a connected database, with its highest required version."""

    locale: str
    version: str
    sources: list[str] = field(default_factory=list)


@dataclass
class ProvisionResult:
    """Aggregate result of ensuring language packages for a connection."""

    downloaded: list[str] = field(default_factory=list)
    skipped: list[str] = field(default_factory=list)
    failed: list[tuple[str, str]] = field(default_factory=list)
    requirements: list[LocaleRequirement] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        return not self.failed

    @property
    def needed_work(self) -> bool:
        return bool(self.downloaded or self.failed)


def is_no_translation_locale(locale: str | None) -> bool:
    """True for built-in locales that never need downloaded translation files."""
    if not locale:
        return False
    return normalize_language_id(locale) in _NO_DOWNLOAD_LOCALES


def parse_semver(version: str | None) -> tuple[int, int, int] | None:
    if not version:
        return None
    text = str(version).strip().lstrip("v")
    if text.lower() == "latest":
        return None
    parts = text.split(".")
    if len(parts) != 3 or not all(part.isdigit() for part in parts):
        return None
    return tuple(int(part) for part in parts)  # type: ignore[return-value]


def format_version(version: tuple[int, int, int]) -> str:
    return ".".join(str(part) for part in version)


def version_to_path(version: str) -> str:
    parsed = parse_semver(version)
    if parsed is None:
        return "latest"
    return "/".join(str(part) for part in parsed)


def version_path_to_label(path: str) -> str:
    if path == "latest":
        return "latest"
    return path.replace("/", ".")


def compare_versions(left: str | None, right: str | None) -> int:
    """Return -1/0/1 for left < / == / > right. Non-semver 'latest' is treated as highest."""
    if (left or "").lower() == "latest" and (right or "").lower() == "latest":
        return 0
    if (left or "").lower() == "latest":
        return 1
    if (right or "").lower() == "latest":
        return -1
    left_key = parse_semver(left)
    right_key = parse_semver(right)
    if left_key is None and right_key is None:
        return 0
    if left_key is None:
        return -1
    if right_key is None:
        return 1
    if left_key < right_key:
        return -1
    if left_key > right_key:
        return 1
    return 0


def max_version(versions: Iterable[str | None]) -> str | None:
    best: str | None = None
    for version in versions:
        if not version:
            continue
        if best is None or compare_versions(version, best) > 0:
            best = str(version)
    return best


def _fetch_json(endpoint: str) -> dict | list | None:
    request = urllib.request.Request(endpoint, method="GET")
    request.add_header("Accept", "application/json")
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = json.loads(response.read().decode())
    except (urllib.error.URLError, urllib.error.HTTPError, OSError, json.JSONDecodeError):
        return None
    return payload


def _parse_versions_payload(payload: dict | list | None) -> list[str]:
    if isinstance(payload, list):
        versions = [str(item) for item in payload if parse_semver(str(item))]
    elif isinstance(payload, dict):
        versions = [
            str(item)
            for item in payload.get("versions", [])
            if parse_semver(str(item))
        ]
    else:
        return []
    return sort_versions(versions)


def sort_versions(versions: list[str]) -> list[str]:
    parsed = [
        (parse_semver(version), version)
        for version in versions
        if parse_semver(version) is not None
    ]
    parsed.sort(key=lambda item: item[0])
    return [version for _key, version in parsed]


def fetch_available_versions() -> list[str]:
    endpoint = f"{TRANSLATIONS_REPO_URL.rstrip('/')}/versions.json"
    versions = _parse_versions_payload(_fetch_json(endpoint))
    if versions:
        return versions

    payload = _fetch_json(TRANSLATIONS_GITHUB_TREE_URL)
    if not isinstance(payload, dict):
        return []

    discovered: set[str] = set()
    for entry in payload.get("tree", []):
        if entry.get("type") != "tree":
            continue
        match = _VERSION_FOLDER_RE.match(str(entry.get("path", "")))
        if not match:
            continue
        discovered.add(".".join(match.groups()))
    return sort_versions(sorted(discovered))


def get_available_versions(*, refresh: bool = False) -> list[str]:
    global _available_versions_cache
    if refresh or _available_versions_cache is None:
        _available_versions_cache = fetch_available_versions()
    return _available_versions_cache


def resolve_translation_version_path(
    user_version: str | None,
    available_versions: list[str] | None = None,
) -> str:
    """Pick the translations folder (``major/minor/patch`` or ``latest``)."""
    versions = available_versions if available_versions is not None else get_available_versions()
    user = parse_semver(user_version)

    if user is None or not versions:
        if user_version:
            return version_to_path(user_version)
        return "latest"

    user_label = format_version(user)
    parsed_versions = [
        (parse_semver(version), version)
        for version in versions
        if parse_semver(version) is not None
    ]
    parsed_versions.sort(key=lambda item: item[0])
    if not parsed_versions:
        return version_to_path(user_version or "")

    available_labels = [version for _key, version in parsed_versions]
    if user_label in available_labels:
        return version_to_path(user_label)

    highest = parsed_versions[-1][0]
    if user > highest:
        return "latest"

    for version_key, version_label in parsed_versions:
        if version_key >= user:
            return version_to_path(version_label)

    return "latest"


def translation_version_label(
    user_version: str | None = None,
    *,
    use_latest: bool = False,
    available_versions: list[str] | None = None,
) -> str:
    if use_latest:
        return "latest"
    version = user_version
    if version is None:
        from ...libs import tools_qgis
        version, _ = tools_qgis.get_plugin_version()
    path = resolve_translation_version_path(version, available_versions)
    return version_path_to_label(path)


def plugin_dir() -> Path:
    from ...libs import lib_vars
    return Path(lib_vars.plugin_dir).resolve()


def dbmodel_dir() -> str:
    from ...libs import lib_vars
    return os.path.join(lib_vars.plugin_dir, "dbmodel")


def language_files_exist(
    locale: str,
    *,
    cleanup_incomplete: bool = True,
) -> bool:
    """True when local .ts and schema i18n SQL folders exist for the locale."""
    if locale.lower() == "en_us":
        return True

    from ...libs import lib_vars

    folder = normalize_language_folder(locale)
    ts_path = os.path.join(lib_vars.plugin_dir, "i18n", f"{TS_NAME}_{folder}.ts")
    if not os.path.isfile(ts_path):
        return False
    for schema_key, schema_path in I18N_SCHEMAS.items():
        if schema_key == "python":
            continue
        path = os.path.join(dbmodel_dir(), schema_path, folder)
        if not os.path.isdir(path) or not any(name.endswith(".sql") for name in os.listdir(path)):
            if cleanup_incomplete:
                delete_language_files(locale)
            return False
    return True


def language_package_paths(locale: str) -> tuple[Path, ...]:
    """Return every on-disk artifact installed for a downloaded locale."""
    folder = normalize_language_folder(locale)
    root = plugin_dir()
    paths = [
        root / "i18n" / f"{TS_NAME}_{folder}.ts",
        root / "i18n" / f"{TS_NAME}_{folder}.qm",
    ]
    paths.extend(
        root / "dbmodel" / schema_path / folder
        for schema_key, schema_path in I18N_SCHEMAS.items()
        if schema_key != "python"
    )
    return tuple(paths)


def delete_language_files(locale: str) -> tuple[bool, str | None]:
    removed = False
    try:
        for path in language_package_paths(locale):
            if path.is_dir():
                shutil.rmtree(path)
                removed = True
            elif path.is_file():
                path.unlink()
                removed = True
        remaining = [str(path) for path in language_package_paths(locale) if path.exists()]
        if remaining:
            msg = "could not remove: {0}"
            msg_params = (', '.join(remaining),)
            return False, tools_qt.tr(msg, msg_params=msg_params)
        if not removed:
            return False, "no local language folders found"
        return True, None
    except OSError as exc:
        return False, str(exc)


def translation_zip_url(
    locale: str,
    *,
    user_version: str | None = None,
    use_latest: bool = False,
    available_versions: list[str] | None = None,
) -> str:
    filename = f"translations_{normalize_language_id(locale)}.zip"
    base = TRANSLATIONS_REPO_URL.rstrip("/")
    if use_latest:
        version_path = "latest"
    else:
        version = user_version
        if version is None:
            from ...libs import tools_qgis
            version, _ = tools_qgis.get_plugin_version()
        version_path = resolve_translation_version_path(version, available_versions)
    return f"{base}/{version_path}/{filename}"


def fetch_language_zip(
    locale: str,
    *,
    user_version: str | None = None,
    use_latest: bool = False,
    available_versions: list[str] | None = None,
) -> tuple[bytes | None, str | None]:
    url = translation_zip_url(
        locale,
        user_version=user_version,
        use_latest=use_latest,
        available_versions=available_versions,
    )
    request = urllib.request.Request(url, method="GET")
    request.add_header("Accept", "application/zip, application/octet-stream, */*")
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            body = response.read()
        if not body.startswith(b"PK"):
            msg = "Response from {0} is not a ZIP archive"
            msg_params = (url,)
            return None, tools_qt.tr(msg, msg_params=msg_params)
        return body, None
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            msg = "Not found: {0}"
            msg_params = (url,)
            return None, tools_qt.tr(msg, msg_params=msg_params)
        detail = exc.read().decode(errors="replace")
        return None, f"HTTP {exc.code}: {detail}"
    except (urllib.error.URLError, OSError) as exc:
        return None, str(exc)


def extract_language_zip(zip_data: bytes) -> tuple[bool, str | None]:
    target_root = plugin_dir()
    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            zip_path = Path(tmpdir) / "translations.zip"
            zip_path.write_bytes(zip_data)
            with zipfile.ZipFile(zip_path) as archive:
                for member in archive.namelist():
                    if member.endswith("/"):
                        continue
                    target = (target_root / member).resolve()
                    if not str(target).startswith(str(target_root)):
                        msg = "Unsafe path in ZIP archive: {0}"
                        msg_params = (member,)
                        return False, tools_qt.tr(msg, msg_params=msg_params)
                archive.extractall(target_root)
    except (zipfile.BadZipFile, OSError) as exc:
        return False, str(exc)

    manifest_path = target_root / "manifest.json"
    if manifest_path.exists():
        try:
            manifest_path.unlink()
        except OSError as exc:
            msg = "Could not delete manifest.json: {0}"
            msg_params = (str(exc),)
            return False, tools_qt.tr(msg, msg_params=msg_params)
    return True, None


def download_language_files(
    locale: str,
    *,
    user_version: str | None = None,
    use_latest: bool = False,
    available_versions: list[str] | None = None,
) -> tuple[bool, str | None, str | None]:
    """Download and extract language files. Returns (ok, failed_schema, error)."""
    zip_data, error = fetch_language_zip(
        locale,
        user_version=user_version,
        use_latest=use_latest,
        available_versions=available_versions,
    )
    if error or not zip_data:
        msg = "Empty response"
        return False, "zip", error or tools_qt.tr(msg)
    ok, error = extract_language_zip(zip_data)
    if not ok:
        msg = "Could not extract language files"
        return False, "zip", error or tools_qt.tr(msg)
    return True, None, None


def get_installed_locale_meta(locale: str) -> tuple[bool, str | None]:
    """Return (active, version) from the config SQLite ``locales`` table."""
    from ..utils import tools_gw

    status, cursor = tools_gw.create_sqlite_conn("config")
    if not status or cursor is None:
        return False, None
    cursor.execute(
        "SELECT active, version FROM locales WHERE locale = ? "
        "ORDER BY id LIMIT 1",
        (normalize_language_folder(locale),),
    )
    row = cursor.fetchone()
    if not row:
        # Try lowercase id form used by some rows.
        cursor.execute(
            "SELECT active, version FROM locales WHERE lower(locale) = ? "
            "ORDER BY id LIMIT 1",
            (normalize_language_id(locale),),
        )
        row = cursor.fetchone()
    if not row:
        return False, None
    return bool(row[0]), (str(row[1]) if row[1] else None)


def set_locale_active(
    locale: str,
    active: bool,
    version: str | None = None,
    *,
    name: str | None = None,
) -> bool:
    from ..utils import tools_gw

    status, cursor = tools_gw.create_sqlite_conn("config")
    if not status or cursor is None:
        return False
    folder = normalize_language_folder(locale)
    cursor.execute("SELECT 1 FROM locales WHERE locale = ?", (folder,))
    if cursor.fetchone():
        if version is not None:
            cursor.execute(
                "UPDATE locales SET active = ?, version = ? WHERE locale = ?",
                (1 if active else 0, version, folder),
            )
        elif not active:
            cursor.execute(
                "UPDATE locales SET active = ?, version = NULL WHERE locale = ?",
                (0, folder),
            )
        else:
            cursor.execute(
                "UPDATE locales SET active = ? WHERE locale = ?",
                (1, folder),
            )
    else:
        cursor.execute(
            """INSERT INTO locales (locale, name, active, version, active_multilang)
               VALUES (?, ?, ?, ?, 0)
               ON CONFLICT (locale) DO UPDATE SET
                 name = excluded.name,
                 active = excluded.active,
                 version = excluded.version,
                 active_multilang = excluded.active_multilang""",
            (folder, name or folder, 1 if active else 0, version),
        )
    cursor.connection.commit()
    return True


def locale_likely_needs_download(locale: str, required_version: str | None) -> bool:
    """
    Lightweight check without contacting the translations repository.

    Used on the UI thread to decide whether to start a provision task.
    """
    if locale.lower() == "en_us":
        return False
    if not language_files_exist(locale, cleanup_incomplete=False):
        return True
    _active, installed = get_installed_locale_meta(locale)
    if not installed:
        return True
    return compare_versions(installed, required_version) < 0


def locale_needs_download(
    locale: str,
    required_version: str | None,
    *,
    available_versions: list[str] | None = None,
) -> bool:
    """True when local files are missing or the installed package is older than required."""
    if locale.lower() == "en_us":
        return False
    if not language_files_exist(locale):
        return True

    _active, installed = get_installed_locale_meta(locale)
    if not installed:
        return True

    required_label = translation_version_label(
        required_version,
        available_versions=available_versions,
    )
    if installed.lower() == required_label.lower():
        return False
    # Shared package: keep when installed already satisfies the required DB version
    # and the resolved repository label.
    if (
        compare_versions(installed, required_version) >= 0
        and compare_versions(installed, required_label) >= 0
    ):
        return False
    return True


def collect_locale_requirements(
    schema_rows: Iterable[dict[str, Any]],
    multilang_languages: Iterable[str] | None = None,
) -> list[LocaleRequirement]:
    """
    Build per-locale requirements from schema language/version rows.

    When multiple schemas need the same locale, the highest version wins.
    Multilang operative languages inherit the highest version seen across schemas
    (or the plugin version when no schema version is available).
    """
    by_locale: dict[str, LocaleRequirement] = {}

    def _add(locale_raw: str | None, version: str | None, source: str) -> None:
        if not locale_raw or is_no_translation_locale(locale_raw):
            return
        folder = normalize_language_folder(locale_raw)
        if not folder:
            return
        key = normalize_language_id(folder)
        existing = by_locale.get(key)
        if existing is None:
            by_locale[key] = LocaleRequirement(
                locale=folder,
                version=str(version or "") or "0.0.0",
                sources=[source],
            )
            return
        if version and compare_versions(version, existing.version) > 0:
            existing.version = str(version)
        if source not in existing.sources:
            existing.sources.append(source)

    for row in schema_rows or ():
        kind = str(row.get("kind") or "").strip().lower()
        if kind and kind not in TRANSLATABLE_PROJECT_TYPES:
            continue
        language = row.get("language")
        if is_no_translation_locale(str(language) if language else None):
            continue
        version = row.get("version") or row.get("giswater")
        schema = str(row.get("schema") or kind or "?")
        _add(str(language) if language else None, str(version) if version else None, schema)

    highest_schema_version = max_version(req.version for req in by_locale.values())
    if highest_schema_version is None:
        try:
            from ...libs import tools_qgis
            plugin_version, _ = tools_qgis.get_plugin_version()
            highest_schema_version = plugin_version
        except Exception:
            highest_schema_version = "0.0.0"

    for lang in multilang_languages or ():
        _add(
            lang,
            highest_schema_version,
            "multilang",
        )

    return sorted(by_locale.values(), key=lambda item: item.locale.lower())


def locales_to_download(
    requirements: Iterable[LocaleRequirement],
    *,
    available_versions: list[str] | None = None,
) -> list[LocaleRequirement]:
    return [
        req
        for req in requirements
        if locale_needs_download(
            req.locale,
            req.version,
            available_versions=available_versions,
        )
    ]


def provision_language_packages(
    requirements: Iterable[LocaleRequirement],
    *,
    available_versions: list[str] | None = None,
    progress_cb: Callable[[int, int, str], None] | None = None,
) -> ProvisionResult:
    """
    Download missing/outdated locales for the highest required version each.

    Failures are collected; successful downloads update SQLite locale metadata.
    """
    req_list = list(requirements)
    result = ProvisionResult(requirements=req_list)
    versions = available_versions if available_versions is not None else get_available_versions()
    pending = locales_to_download(req_list, available_versions=versions)
    total = len(pending)

    for index, req in enumerate(pending):
        if progress_cb:
            progress_cb(index, total, req.locale)
        ok, _schema, error = download_language_files(
            req.locale,
            user_version=req.version,
            available_versions=versions,
        )
        if not ok:
            msg = "Unknown error"
            result.failed.append((req.locale, error or tools_qt.tr(msg)))
            continue
        label = translation_version_label(req.version, available_versions=versions)
        if not set_locale_active(req.locale, True, version=label):
            msg = "Could not update locale metadata"
            result.failed.append((req.locale, tools_qt.tr(msg)))
            continue
        result.downloaded.append(req.locale)

    for req in req_list:
        if req.locale in result.downloaded:
            continue
        if any(locale == req.locale for locale, _ in result.failed):
            continue
        result.skipped.append(req.locale)

    if progress_cb and total:
        progress_cb(total, total, "")
    return result


def fetch_languages() -> dict[str, str]:
    """Fetch locale -> display name map from the translations repository."""
    endpoint = f"{TRANSLATIONS_REPO_URL.rstrip('/')}/latest/languages.json"
    payload = _fetch_json(endpoint)
    if not isinstance(payload, dict):
        msg = "Unexpected languages payload from ({0})"
        msg_params = (endpoint,)
        raise ValueError(tools_qt.tr(msg, list_params=msg_params))
    return {str(locale): str(name) for locale, name in payload.items()}


def reconcile_downloaded_locales(
    locales: dict[str, str],
) -> dict[str, tuple[str, str | None]] | None:
    """Sync SQLite ``locales.active`` with on-disk packages; return installed map.

    Returns ``None`` when the config database is unavailable.
    """
    from ..utils import tools_gw

    downloaded_locales: dict[str, tuple[str, str | None]] = {}
    status, cursor = tools_gw.create_sqlite_conn("config")
    if not status or cursor is None:
        return None

    cursor.execute("SELECT locale, name, active, version FROM locales")
    db_locales = {
        locale: (name, active, version)
        for locale, name, active, version in cursor.fetchall()
    }

    for locale, name in locales.items():
        if language_files_exist(locale):
            db_name, db_active, version = db_locales.get(locale, (name, 0, None))
            downloaded_locales[locale] = (db_name or name, version)
            if locale in db_locales:
                if not db_active:
                    cursor.execute("UPDATE locales SET active = 1 WHERE locale = ?", (locale,))
            else:
                cursor.execute(
                    """INSERT INTO locales (locale, name, active, version, active_multilang)
                       VALUES (?, ?, 1, ?, 0)
                       ON CONFLICT (locale) DO UPDATE SET
                         name = excluded.name,
                         active = excluded.active,
                         version = excluded.version,
                         active_multilang = excluded.active_multilang""",
                    (locale, name, version),
                )
        elif locale in db_locales and db_locales[locale][1]:
            cursor.execute(
                "UPDATE locales SET active = 0, version = NULL WHERE locale = ?",
                (locale,),
            )
    cursor.connection.commit()
    return downloaded_locales
