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

from i18n_api_client import TranslationsApiClient, resolve_setting

DEFAULT_TS_NAME = "giswater"
ZIP_MAGIC = b"PK"


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


def normalize_lang(lang: str) -> str:
    return lang.strip().lower().replace("-", "_")


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
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    base_url = (resolve_setting(args.base_url, "TRANSLATIONS_API_URL") or "").strip()
    user = (resolve_setting(args.user, "TRANSLATIONS_API_USER", "") or "").strip()
    password = (resolve_setting(args.password, "TRANSLATIONS_API_PASSWORD", "") or "").strip()
    ts_name = resolve_setting(args.ts_name, "TS_NAME", DEFAULT_TS_NAME) or DEFAULT_TS_NAME
    languages_raw = resolve_setting(args.languages, "LANG_CODE", None)
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
            if languages is None or args.languages_json_out:
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
