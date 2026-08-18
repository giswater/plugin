"""
Manifest model + YAML loader.

A manifest describes one schema kind (``ws``, ``ud``, ``utils``, ``am``,
``cm``, ``audit``). It is YAML — the only external dep is PyYAML. The
loader does light validation (required fields, known phase types, known
profile phases) and returns frozen dataclasses, so the rest of the
engine never has to touch raw dicts.

Phase types supported:

- ``sql_dir``      run every ``*.sql`` in a folder (recursive=opt-in)
- ``version_walk`` walk ``updates/M/m/p/<sub>`` semver-ordered
- ``dir_walk``     walk alphabetically-ordered subfolders (am date dirs)
- ``sql_file``     single file, optional fallback path
- ``sql_function`` SELECT schema.fn($${...JSON...}$$)
- ``sql_inline``   literal inline SQL string
"""

from __future__ import annotations

import logging
import os
import warnings
from dataclasses import dataclass, field
from typing import Any, Mapping, Sequence

try:
    import yaml  # type: ignore[import-untyped]
except ImportError as e:  # pragma: no cover - import guard
    raise ImportError(
        "PyYAML is required by giswater_admin.engine.manifest. "
        "Install with `python3 -m pip install pyyaml`."
    ) from e

logger = logging.getLogger(__name__)


_PHASE_TYPES = {
    "sql_dir",
    "version_walk",
    "dir_walk",  # deprecated: superseded by version_walk (M/m/p)
    "sql_file",
    "sql_function",
    "sql_inline",
}

_DEPRECATED_PHASE_TYPES = {"dir_walk"}


class ManifestError(ValueError):
    """Raised on malformed manifests."""


@dataclass(frozen=True)
class Step:
    """One source spec inside an ``sql_dir`` / ``sql_file`` phase.

    ``shared_source``: extra folder merged by basename (shared < fallback <
    locale). Locales only need the files they translate.
    """

    source: str
    recursive: bool = False
    fallback_source: str = ""
    shared_source: str = ""
    schema_override: str = ""
    aux_override: str = ""


@dataclass(frozen=True)
class Phase:
    id: str
    type: str
    description: str = ""
    optional: bool = False
    steps: Sequence[Step] = field(default_factory=tuple)
    # version_walk / dir_walk
    root: str = ""
    roots: Sequence[str] = field(default_factory=tuple)
    subdirs: Sequence[str] = field(default_factory=tuple)
    range: Mapping[str, Any] = field(default_factory=dict)
    # sql_function
    function: str = ""
    payload: Mapping[str, Any] = field(default_factory=dict)
    # sql_inline
    sql: str = ""


@dataclass(frozen=True)
class Profile:
    name: str
    phases: tuple[str, ...]


@dataclass(frozen=True)
class Manifest:
    kind: str
    engine_version: int
    substitutions: Mapping[str, str]
    phases: tuple[Phase, ...]
    profiles: Mapping[str, Profile]
    path: str = ""

    def phase(self, phase_id: str) -> Phase:
        for p in self.phases:
            if p.id == phase_id:
                return p
        raise ManifestError(f"Phase '{phase_id}' not declared in manifest '{self.kind}'.")

    def profile(self, name: str) -> tuple[str, ...]:
        if name not in self.profiles:
            raise ManifestError(
                f"Profile '{name}' not declared in manifest '{self.kind}'. "
                f"Known: {sorted(self.profiles)}"
            )
        return self.profiles[name].phases


def load_manifest(path: str) -> Manifest:
    """Parse a YAML manifest, validate, return a :class:`Manifest`."""
    if not os.path.isfile(path):
        raise ManifestError(f"Manifest not found: {path}")

    with open(path, "r", encoding="utf-8") as f:
        raw = yaml.safe_load(f) or {}

    if not isinstance(raw, dict):
        raise ManifestError(f"Manifest root must be a mapping: {path}")

    kind = raw.get("kind")
    if not kind or not isinstance(kind, str):
        raise ManifestError(f"Manifest 'kind' is required and must be a string: {path}")

    engine_version = int(raw.get("engine_version", 1))
    substitutions = raw.get("substitutions") or {}
    if not isinstance(substitutions, dict):
        raise ManifestError(f"Manifest 'substitutions' must be a mapping: {path}")

    phases_raw = raw.get("phases") or []
    if not isinstance(phases_raw, list) or not phases_raw:
        raise ManifestError(f"Manifest 'phases' must be a non-empty list: {path}")
    phases = tuple(_parse_phase(p, path) for p in phases_raw)
    phase_ids = {p.id for p in phases}

    profiles_raw = raw.get("profiles") or {}
    if not isinstance(profiles_raw, dict) or not profiles_raw:
        raise ManifestError(f"Manifest 'profiles' must be a non-empty mapping: {path}")

    profiles: dict[str, Profile] = {}
    for name, body in profiles_raw.items():
        if not isinstance(body, dict) or "phases" not in body:
            raise ManifestError(
                f"Manifest profile '{name}' must declare a 'phases' list: {path}"
            )
        plist = body["phases"]
        if not isinstance(plist, list) or not all(isinstance(x, str) for x in plist):
            raise ManifestError(
                f"Manifest profile '{name}' phases must be a list of strings: {path}"
            )
        for pid in plist:
            if pid not in phase_ids:
                raise ManifestError(
                    f"Manifest profile '{name}' references unknown phase '{pid}': {path}"
                )
        profiles[name] = Profile(name=name, phases=tuple(plist))

    return Manifest(
        kind=kind,
        engine_version=engine_version,
        substitutions=dict(substitutions),
        phases=phases,
        profiles=profiles,
        path=path,
    )


def _parse_phase(raw: Any, path: str) -> Phase:
    if not isinstance(raw, dict):
        raise ManifestError(f"Phase entry must be a mapping: {path}")
    pid = raw.get("id")
    ptype = raw.get("type")
    if not pid or not isinstance(pid, str):
        raise ManifestError(f"Phase 'id' missing or not a string: {raw} in {path}")
    if ptype not in _PHASE_TYPES:
        raise ManifestError(
            f"Phase '{pid}' has unsupported type '{ptype}'. "
            f"Known: {sorted(_PHASE_TYPES)} ({path})"
        )
    if ptype in _DEPRECATED_PHASE_TYPES:
        msg = (
            f"Phase '{pid}' uses deprecated type '{ptype}' in {path}. "
            "Migrate to 'version_walk' (semver M/m/p folders); "
            "'dir_walk' will be removed in a future release."
        )
        logger.warning(msg)
        warnings.warn(msg, DeprecationWarning, stacklevel=3)

    steps_raw = raw.get("steps") or []
    if not isinstance(steps_raw, list):
        raise ManifestError(f"Phase '{pid}' steps must be a list: {path}")
    steps = tuple(_parse_step(s, pid, path) for s in steps_raw)

    root_raw = raw.get("root", "")
    roots_raw = raw.get("roots", []) or []
    if not isinstance(roots_raw, list) or not all(isinstance(r, str) for r in roots_raw):
        raise ManifestError(f"Phase '{pid}' 'roots' must be a list of strings: {path}")
    if root_raw and roots_raw:
        raise ManifestError(
            f"Phase '{pid}' declares both 'root' and 'roots' (mutually exclusive): {path}"
        )

    return Phase(
        id=pid,
        type=ptype,
        description=str(raw.get("description", "")),
        optional=bool(raw.get("optional", False)),
        steps=steps,
        root=str(root_raw),
        roots=tuple(roots_raw),
        subdirs=tuple(raw.get("subdirs", []) or []),
        range=dict(raw.get("range", {}) or {}),
        function=str(raw.get("function", "")),
        payload=dict(raw.get("payload", {}) or {}),
        sql=str(raw.get("sql", "")),
    )


def _parse_step(raw: Any, phase_id: str, path: str) -> Step:
    if not isinstance(raw, dict):
        raise ManifestError(f"Step in phase '{phase_id}' must be a mapping: {path}")
    src = raw.get("source")
    if not src or not isinstance(src, str):
        raise ManifestError(
            f"Step in phase '{phase_id}' is missing 'source' (str): {raw} in {path}"
        )
    return Step(
        source=src,
        recursive=bool(raw.get("recursive", False)),
        fallback_source=str(raw.get("fallback_source", "")),
        shared_source=str(raw.get("shared_source", "")),
        schema_override=str(raw.get("schema_override", "")),
        aux_override=str(raw.get("aux_override", "")),
    )
