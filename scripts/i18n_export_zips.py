#!/usr/bin/env python3
"""Download translation ZIP exports from the translations API for CI workflows.

Authentication uses a cookie session obtained from::

  POST {base_url}/api/auth/sign-in/username
  {"username": "...", "password": "..."}
  POST {base_url}/api/auth/log-out

Example::

  python scripts/i18n_export_zips.py \\
    --base-url "$TRANSLATIONS_API_URL" \\
    --user "$TRANSLATIONS_API_USER" \\
    --password "$TRANSLATIONS_API_PASSWORD" \\
    --languages es_cr,es_es \\
    --output-dir ./artifacts

Environment variables override defaults when CLI flags are omitted:
  TRANSLATIONS_API_URL, TRANSLATIONS_API_USER, TRANSLATIONS_API_PASSWORD,
  LANG_CODE (comma-separated), TS_NAME.
"""

from __future__ import annotations

import argparse
import json
import sys
import urllib.parse
from pathlib import Path
from typing import Any

from i18n_api_client import TranslationsApiClient, resolve_setting

DEFAULT_TS_NAME = "giswater"
DEFAULT_STATS_PATH = "/api/stats"
DEFAULT_README_TEMPLATE = Path(__file__).resolve().parent / "templates" / "translations_readme.md"
STATS_PLACEHOLDER = "{{TRANSLATION_STATS}}"
BAR_WIDTH = 20
ZIP_MAGIC = b"PK"

# Regional code in locale ≠ ISO2 flag PNG used by About (icons/flags).
FLAG_OVERRIDES = {
    "ca_ES": "CAT",
    "de_GE": "DE",
    "ja_JA": "JP",
}


def fetch_languages_dict(api: TranslationsApiClient) -> dict[str, str]:
    payload = api.get_json("/api/languages")
    if not isinstance(payload, dict):
        raise RuntimeError("Unexpected languages payload from /api/languages: expected object")

    languages = {
        str(locale).strip().lower(): str(name)
        for locale, name in payload.items()
        if str(locale).strip()
    }
    if not languages:
        raise RuntimeError("No languages returned from /api/languages")
    return languages


def fetch_stats_by_lang(api: TranslationsApiClient, path: str = DEFAULT_STATS_PATH) -> dict[str, dict[str, Any]]:
    payload = api.get_json(path)
    if not isinstance(payload, dict):
        raise RuntimeError(f"Unexpected stats payload from {path}: expected object")

    by_lang = payload.get("byLang")
    if not isinstance(by_lang, dict):
        raise RuntimeError(f"Unexpected stats payload from {path}: missing byLang object")

    result: dict[str, dict[str, Any]] = {}
    for locale, row in by_lang.items():
        key = normalize_lang(str(locale))
        if not key or not isinstance(row, dict):
            continue
        result[key] = row
    return result


def normalize_lang(lang: str) -> str:
    return lang.strip().lower().replace("-", "_")


def display_locale(lang: str) -> str:
    """Normalize API locale (es_es) to About catalog form (es_ES)."""
    key = normalize_lang(lang)
    parts = key.split("_", 1)
    if len(parts) != 2 or not parts[0] or not parts[1]:
        return key
    return f"{parts[0]}_{parts[1].upper()}"


def flag_for_locale(locale: str) -> str:
    if locale in FLAG_OVERRIDES:
        return FLAG_OVERRIDES[locale]
    parts = locale.split("_", 1)
    if len(parts) == 2 and parts[1]:
        return parts[1].upper()
    return locale.upper()[:2]


def percent_from_stats_row(row: dict[str, Any] | None) -> float | None:
    if row is None:
        return None
    value = row.get("percent")
    if value is None or value == "":
        return None
    try:
        return round(float(value), 2)
    except (TypeError, ValueError):
        return None


def build_translations_catalog(
    languages: dict[str, str],
    by_lang: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    """Merge /api/languages + /api/stats into About's translations.json shape."""
    locales = set(languages) | set(by_lang) | {"en_us"}
    catalog: list[dict[str, Any]] = []
    for key in sorted(locales):
        locale = display_locale(key)
        if key == "en_us":
            percent: float | None = 100.0
        else:
            percent = percent_from_stats_row(by_lang.get(key))
        catalog.append(
            {
                "locale": locale,
                "flag": flag_for_locale(locale),
                "name": languages.get(key) or locale,
                "percent": percent,
            }
        )
    return catalog


def write_translations_json(path: Path, catalog: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {path} ({len(catalog)} language(s))")


def percent_rank(entry: dict[str, Any]) -> int:
    """Match About: missing percent sorts last; otherwise round to int."""
    value = entry.get("percent")
    if value is None or value == "":
        return -1
    try:
        return int(round(float(value)))
    except (TypeError, ValueError):
        return -1


def sort_catalog_for_stats(catalog: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return sorted(
        catalog,
        key=lambda entry: (-percent_rank(entry), (entry.get("name") or "").lower()),
    )


def coerce_percent(value: Any) -> float | None:
    if value is None or value == "":
        return None
    try:
        return max(0.0, min(100.0, round(float(value), 2)))
    except (TypeError, ValueError):
        return None


def coverage_bar(percent: float, width: int = BAR_WIDTH) -> str:
    filled = int(round(percent / 100.0 * width))
    filled = max(0, min(width, filled))
    return ("█" * filled) + ("░" * (width - filled))


def format_percent_label(percent: float) -> str:
    return f"{percent:.2f}%"


def format_percent_number(percent: float) -> str:
    if percent == int(percent):
        return str(int(percent))
    return f"{percent:.2f}"


def _escape_md_cell(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", " ").strip()


def _mermaid_axis_label(locale: str) -> str:
    cleaned = locale.replace('"', "").replace("`", "").replace("\n", " ").strip()
    return f'"{cleaned}"'


def render_coverage_table(catalog: list[dict[str, Any]]) -> str:
    lines = [
        "| Locale | Language | Coverage |",
        "| --- | --- | --- |",
    ]
    for entry in catalog:
        locale = _escape_md_cell(str(entry.get("locale") or ""))
        name = _escape_md_cell(str(entry.get("name") or locale))
        percent = coerce_percent(entry.get("percent"))
        if percent is None:
            coverage = "—"
        else:
            coverage = f"`{coverage_bar(percent)}` {format_percent_label(percent)}"
        lines.append(f"| {locale} | {name} | {coverage} |")
    return "\n".join(lines)


def render_coverage_mermaid(catalog: list[dict[str, Any]]) -> str:
    labels: list[str] = []
    values: list[str] = []
    for entry in catalog:
        percent = coerce_percent(entry.get("percent"))
        if percent is None:
            continue
        locale = str(entry.get("locale") or "").strip()
        if not locale:
            continue
        labels.append(_mermaid_axis_label(locale))
        values.append(format_percent_number(percent))
    if not labels:
        return ""
    return "\n".join(
        [
            "```mermaid",
            "xychart-beta",
            '    title "Translation coverage (%)"',
            f"    x-axis [{', '.join(labels)}]",
            '    y-axis "%" 0 --> 100',
            f"    bar [{', '.join(values)}]",
            "```",
        ]
    )


def render_coverage_markdown(catalog: list[dict[str, Any]]) -> str:
    rows = sort_catalog_for_stats(catalog)
    parts = [render_coverage_table(rows)]
    chart = render_coverage_mermaid(rows)
    if chart:
        parts.extend(["", chart])
    return "\n".join(parts) + "\n"


def write_translations_readme(
    path: Path,
    catalog: list[dict[str, Any]],
    template_path: Path,
) -> None:
    template = template_path.read_text(encoding="utf-8")
    if STATS_PLACEHOLDER not in template:
        raise ValueError(f"README template {template_path} is missing {STATS_PLACEHOLDER}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        template.replace(STATS_PLACEHOLDER, render_coverage_markdown(catalog).rstrip("\n")),
        encoding="utf-8",
    )
    print(f"Wrote {path} ({len(catalog)} language(s))")


def zip_filename(lang: str) -> str:
    return f"translations_{normalize_lang(lang)}.zip"


def build_export_path(lang: str, ts_name: str) -> str:
    query = urllib.parse.urlencode({"ts_name": ts_name})
    return f"/api/translations/{normalize_lang(lang)}/export/zip?{query}"


def download_zip(
    api: TranslationsApiClient,
    lang: str,
    ts_name: str,
    output_dir: Path,
) -> Path:
    path = build_export_path(lang, ts_name)
    url = f"{api.base_url}{path}"
    print(f"GET {url}")

    body = api.get_bytes(path, accept="application/zip, application/octet-stream, */*")
    if not body.startswith(ZIP_MAGIC):
        raise RuntimeError(
            f"Response for {lang} is not a ZIP archive (missing PK header). "
            f"Received {len(body)} byte(s)."
        )

    output_dir.mkdir(parents=True, exist_ok=True)
    target = output_dir / zip_filename(lang)
    target.write_bytes(body)
    print(f"Wrote {target} ({len(body)} bytes)")
    return target


def parse_languages(raw: str | None) -> list[str] | None:
    if raw is None or raw.strip() == "" or raw.strip().lower() == "all":
        return None
    langs = [normalize_lang(part) for part in raw.split(",") if part.strip()]
    if not langs:
        raise ValueError("No valid language codes provided.")
    return langs


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Download translation ZIP files from the translations API.",
    )
    parser.add_argument("--base-url", default=None, help="Translations API base URL")
    parser.add_argument("--user", default=None, help="API username")
    parser.add_argument("--password", default=None, help="API password")
    parser.add_argument(
        "--languages",
        default=None,
        help="Comma-separated language codes, or 'all' to fetch from /api/languages",
    )
    parser.add_argument("--ts-name", default=None, help=f"TS base name (default: {DEFAULT_TS_NAME})")
    parser.add_argument("--output-dir", default="artifacts/i18n", help="Directory for ZIP files")
    parser.add_argument(
        "--languages-json-out",
        default=None,
        help="Optional path to write languages.json from /api/languages",
    )
    parser.add_argument(
        "--translations-json-out",
        default=None,
        help="Optional path to write About catalog translations.json from /api/stats",
    )
    parser.add_argument(
        "--readme-out",
        default=None,
        help="Optional path to write translations README with coverage from /api/stats",
    )
    parser.add_argument(
        "--readme-template",
        default=None,
        help="README template with {{TRANSLATION_STATS}} "
        f"(default: {DEFAULT_README_TEMPLATE})",
    )
    parser.add_argument(
        "--stats-path",
        default=None,
        help=f"Stats API path (default: {DEFAULT_STATS_PATH})",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    base_url = (resolve_setting(args.base_url, "TRANSLATIONS_API_URL") or "").strip()
    user = (resolve_setting(args.user, "TRANSLATIONS_API_USER", "") or "").strip()
    password = (resolve_setting(args.password, "TRANSLATIONS_API_PASSWORD", "") or "").strip()
    ts_name = resolve_setting(args.ts_name, "TS_NAME", DEFAULT_TS_NAME) or DEFAULT_TS_NAME
    languages_raw = resolve_setting(args.languages, "LANG_CODE", None)
    stats_path = (
        resolve_setting(args.stats_path, "TRANSLATIONS_STATS_PATH", DEFAULT_STATS_PATH)
        or DEFAULT_STATS_PATH
    )
    output_dir = Path(args.output_dir)

    if not base_url:
        print(
            "Error: missing API base URL. Set TRANSLATIONS_API_URL or pass --base-url.",
            file=sys.stderr,
        )
        return 1

    try:
        with TranslationsApiClient(base_url, user, password) as api:
            languages = parse_languages(languages_raw)
            languages_dict: dict[str, str] | None = None
            need_catalog = bool(args.translations_json_out or args.readme_out)
            need_languages = (
                languages is None
                or args.languages_json_out
                or need_catalog
            )
            if need_languages:
                print("Fetching language list from API...")
                languages_dict = fetch_languages_dict(api)

            if args.languages_json_out:
                languages_json_path = Path(args.languages_json_out)
                languages_json_path.parent.mkdir(parents=True, exist_ok=True)
                languages_json_path.write_text(
                    json.dumps(languages_dict, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8",
                )
                print(f"Wrote {languages_json_path} ({len(languages_dict)} language(s))")

            if need_catalog:
                print(f"Fetching translation stats from {stats_path}...")
                by_lang = fetch_stats_by_lang(api, stats_path)
                catalog = build_translations_catalog(languages_dict or {}, by_lang)
                if args.translations_json_out:
                    write_translations_json(Path(args.translations_json_out), catalog)
                if args.readme_out:
                    template_path = (
                        Path(args.readme_template)
                        if args.readme_template
                        else DEFAULT_README_TEMPLATE
                    )
                    write_translations_readme(Path(args.readme_out), catalog, template_path)

            if languages is None:
                languages = sorted(languages_dict.keys())
                print(f"Languages: {', '.join(languages)}")

            failures = 0
            downloaded: list[Path] = []
            for lang in languages:
                try:
                    downloaded.append(download_zip(api, lang, ts_name, output_dir))
                except RuntimeError as exc:
                    print(f"Error exporting {lang}: {exc}", file=sys.stderr)
                    failures += 1

            if downloaded:
                print(f"Downloaded {len(downloaded)} ZIP file(s) to {output_dir.resolve()}")

            if failures > 0:
                print(f"Failed to export {failures} language(s).", file=sys.stderr)
                return 1

            api.log_out()
        return 0
    except (RuntimeError, ValueError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
