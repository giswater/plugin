#!/usr/bin/env python3
"""Resolve PLUGIN_VER (create) and TARGET_VER (upgrade) for E2E update tests."""

from __future__ import annotations

import sys
from pathlib import Path


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def _ensure_import_paths() -> Path:
    root = _repo_root()
    for path in (root, root / "scripts"):
        text = str(path)
        if text not in sys.path:
            sys.path.insert(0, text)
    return root


def resolve_e2e_versions(repo_root: Path | None = None) -> tuple[str, str]:
    """Return (plugin_ver, target_ver) for isolated upgrade E2E tests."""
    from giswater_admin.install.config import read_metadata_version
    from release_lib import ReleaseError, parse_version, release_versions_from_headings

    root = repo_root or _repo_root()
    target = read_metadata_version(root)
    if not target:
        raise ReleaseError(f"metadata.txt has no version= under {root}")

    changelog_path = root / "CHANGELOG.md"
    if not changelog_path.is_file():
        raise ReleaseError(f"CHANGELOG.md not found under {root}")

    released = release_versions_from_headings(
        changelog_path.read_text(encoding="utf-8")
    )
    if not released:
        raise ReleaseError("CHANGELOG.md has no released versions")

    target_v = parse_version(target)
    latest_v = released[0]
    target_key = (target_v.major, target_v.minor, target_v.patch)
    latest_key = (latest_v.major, latest_v.minor, latest_v.patch)

    if target_key > latest_key:
        plugin = latest_v.text
    else:
        if len(released) < 2:
            raise ReleaseError(
                "CHANGELOG.md needs at least two released versions when "
                f"metadata ({target}) is not ahead of latest release ({latest_v.text})"
            )
        plugin = released[1].text

    return plugin, target


def main() -> int:
    try:
        _ensure_import_paths()
        plugin, target = resolve_e2e_versions()
    except Exception as exc:  # noqa: BLE001 - CLI entrypoint
        print(f"error: {exc}", file=sys.stderr)
        return 1

    print(f"TARGET_VER={target}")
    print(f"PLUGIN_VER={plugin}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
