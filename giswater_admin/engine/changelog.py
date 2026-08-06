"""
Read and merge dbmodel update changelogs (common + ws/ud).

Qt-free: safe for giswater_admin CLI and QGIS plugin admin.
"""

from __future__ import annotations

import os
import re
from dataclasses import dataclass, field
from typing import Iterator, Mapping, Sequence

from .builder import _parse_version

CHANGELOG_NAME = "changelog.txt"
_SCOPE_ORDER = ("common", "ws", "ud")
_DEFAULT_SECTION_LABELS = {"common": "Common", "ws": "WS", "ud": "UD"}
_VERSION_LINE = re.compile(r"^\d+\.\d+\.\d+")


@dataclass(frozen=True)
class VersionChangelog:
    version: tuple[int, int, int]
    sections: Mapping[str, Sequence[str]] = field(default_factory=dict)

    @property
    def version_text(self) -> str:
        return ".".join(str(x) for x in self.version)


def network_update_roots(sql_root: str, kind: str) -> list[str]:
    """Return absolute update roots: common first, then ws or ud."""
    k = (kind or "").strip().lower()
    if k not in ("ws", "ud"):
        raise ValueError(f"network changelog kind must be 'ws' or 'ud', got: {kind!r}")
    base = os.path.join(sql_root, "schemas", "main")
    return [
        os.path.join(base, "common", "updates"),
        os.path.join(base, k, "updates"),
    ]


def iter_semver_under(root: str) -> Iterator[tuple[int, int, int]]:
    """Yield semver tuples for each M/m/p folder under *root*."""
    if not os.path.isdir(root):
        return
    for major_name in os.listdir(root):
        major_path = os.path.join(root, major_name)
        if not (major_name.isdigit() and os.path.isdir(major_path)):
            continue
        for minor_name in os.listdir(major_path):
            minor_path = os.path.join(major_path, minor_name)
            if not (minor_name.isdigit() and os.path.isdir(minor_path)):
                continue
            for patch_name in os.listdir(minor_path):
                patch_path = os.path.join(minor_path, patch_name)
                if not (patch_name.isdigit() and os.path.isdir(patch_path)):
                    continue
                yield int(major_name), int(minor_name), int(patch_name)


def collect_pending_versions(
    roots: Sequence[str],
    project_version: str,
    plugin_version: str,
) -> list[tuple[int, int, int]]:
    """Union of versions under *roots* with upgrade filter: project < v <= plugin."""
    project_v = _parse_version(project_version)
    plugin_v = _parse_version(plugin_version)
    found: set[tuple[int, int, int]] = set()
    for root in roots:
        for v in iter_semver_under(root):
            if project_v < v <= plugin_v:
                found.add(v)
    return sorted(found)


def parse_changelog_text(text: str) -> list[str]:
    """Extract bullet lines from legacy or bullets-only changelog content."""
    bullets: list[str] = []
    seen: set[str] = set()
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.replace("*", "").strip() == "":
            continue
        if _VERSION_LINE.match(line):
            continue
        if line.startswith("- "):
            bullet = line
        elif line.startswith("-"):
            bullet = "- " + line[1:].lstrip()
        else:
            continue
        if bullet not in seen:
            seen.add(bullet)
            bullets.append(bullet)
    return bullets


def parse_changelog_file(path: str) -> list[str]:
    if not os.path.isfile(path):
        return []
    try:
        with open(path, encoding="utf-8") as f:
            return parse_changelog_text(f.read())
    except OSError:
        return []


def version_folder(root: str, version: tuple[int, int, int]) -> str:
    major, minor, patch = version
    return os.path.join(root, str(major), str(minor), str(patch))


def read_version_sections(
    sql_root: str,
    kind: str,
    version: tuple[int, int, int],
) -> dict[str, list[str]]:
    """Read bullets per scope (common, ws/ud) for one version."""
    roots = network_update_roots(sql_root, kind)
    scopes = ("common", kind.lower())
    out: dict[str, list[str]] = {}
    for scope, root in zip(scopes, roots):
        folder = version_folder(root, version)
        if not os.path.isdir(folder):
            continue
        path = os.path.join(folder, CHANGELOG_NAME)
        bullets = parse_changelog_file(path)
        if bullets:
            out[scope] = bullets
    return out


def collect_upgrade_changelogs(
    sql_root: str,
    kind: str,
    project_version: str,
    plugin_version: str,
) -> list[VersionChangelog]:
    """All pending version changelogs for a network schema upgrade."""
    roots = network_update_roots(sql_root, kind)
    versions = collect_pending_versions(roots, project_version, plugin_version)
    result: list[VersionChangelog] = []
    for v in versions:
        sections = read_version_sections(sql_root, kind, v)
        if sections:
            result.append(VersionChangelog(version=v, sections=sections))
    return result


def _format_version_block(
    version: tuple[int, int, int],
    sections: Mapping[str, Sequence[str]],
    section_labels: Mapping[str, str],
) -> str:
    lines = [
        ".".join(str(x) for x in version),
        "*************",
    ]
    for scope in _SCOPE_ORDER:
        bullets = sections.get(scope)
        if not bullets:
            continue
        label = section_labels.get(scope, _DEFAULT_SECTION_LABELS.get(scope, scope))
        if len(sections) > 1:
            lines.append(f"--- {label} ---")
        lines.extend(bullets)
    return "\n".join(lines)


def format_upgrade_changelog(
    sql_root: str,
    kind: str,
    project_version: str,
    plugin_version: str,
    *,
    section_labels: Mapping[str, str] | None = None,
) -> str:
    """Plain-text changelog for all pending upgrade versions."""
    labels = dict(_DEFAULT_SECTION_LABELS)
    if section_labels:
        labels.update(section_labels)
    blocks: list[str] = []
    for entry in collect_upgrade_changelogs(
        sql_root, kind, project_version, plugin_version
    ):
        blocks.append(_format_version_block(entry.version, entry.sections, labels))
    return "\n\n".join(blocks) if blocks else ""


def changelog_versions_as_dicts(
    sql_root: str,
    kind: str,
    project_version: str,
    plugin_version: str,
) -> list[dict]:
    """JSON-serializable changelog list for CLI --check."""
    return [
        {
            "version": e.version_text,
            "sections": {k: list(v) for k, v in e.sections.items()},
        }
        for e in collect_upgrade_changelogs(sql_root, kind, project_version, plugin_version)
    ]
