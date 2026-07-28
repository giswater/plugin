"""
Discover schema kinds and CLI behavior from ``dbmodel/manifests/*.yaml``.

Adding a satellite schema should only require:
  - ``dbmodel/manifests/<kind>.yaml``
  - SQL under ``dbmodel/schemas/addon/<kind>/``

No Python changes needed for the common case (empty / update / integrate profiles).
"""

from __future__ import annotations

import os
from functools import lru_cache

from .manifest import Manifest, ManifestError, load_manifest

MAIN_KINDS = frozenset({"ws", "ud"})

# Lockstep network update order (lower runs first). Unknown addons use ``_UNKNOWN_ADDON_ORDER``.
_DEFAULT_UPDATE_ORDER: dict[str, int] = {
    "multilang": 5,
    "utils": 10,
    "cibs": 20,
    "ws": 30,
    "ud": 40,
    "am": 50,
    "cm": 60,
    "audit": 70,
}
_UNKNOWN_ADDON_ORDER = 25

_NEW_PROJECT_PROFILES = frozenset({"empty", "bootstrap", "structure", "full", "sample"})

_CREATE_PROFILE_BY_KIND: dict[str, dict[str, str]] = {
    "am": {"empty": "empty", "sample": "sample"},
}

_CREATE_DEFAULT_PROFILE: dict[str, str] = {
    "audit": "empty",
    "cm": "bootstrap",
}


def is_main_kind(kind: str) -> bool:
    return kind.lower() in MAIN_KINDS


def is_addon_kind(kind: str) -> bool:
    normalized = kind.lower()
    return bool(normalized) and normalized not in MAIN_KINDS


def _abs_dbmodel(dbmodel_path: str) -> str:
    return os.path.abspath(dbmodel_path)


def list_manifest_files(dbmodel_path: str) -> list[str]:
    root = os.path.join(dbmodel_path, "manifests")
    if not os.path.isdir(root):
        return []
    return sorted(
        os.path.join(root, fn)
        for fn in os.listdir(root)
        if fn.endswith((".yaml", ".yml"))
    )


@lru_cache(maxsize=32)
def _kind_index(dbmodel_path: str) -> dict[str, str]:
    index: dict[str, str] = {}
    for path in list_manifest_files(dbmodel_path):
        try:
            manifest = load_manifest(path)
        except ManifestError:
            continue
        index[manifest.kind.lower()] = path
    return index


def manifest_path_for(dbmodel_path: str, kind: str) -> str | None:
    return _kind_index(_abs_dbmodel(dbmodel_path)).get(kind.lower())


def load_kind_manifest(dbmodel_path: str, kind: str) -> Manifest:
    path = manifest_path_for(dbmodel_path, kind)
    if not path:
        raise ManifestError(
            f"No manifest for kind '{kind}' under {os.path.join(dbmodel_path, 'manifests')}. "
            f"Known: {sorted(all_kinds(dbmodel_path))}"
        )
    return load_manifest(path)


def all_kinds(dbmodel_path: str) -> tuple[str, ...]:
    return tuple(sorted(_kind_index(_abs_dbmodel(dbmodel_path))))


def main_kinds(dbmodel_path: str) -> tuple[str, ...]:
    return tuple(k for k in all_kinds(dbmodel_path) if is_main_kind(k))


def addon_kinds(dbmodel_path: str) -> tuple[str, ...]:
    return tuple(k for k in all_kinds(dbmodel_path) if is_addon_kind(k))


def addon_updates_root(dbmodel_path: str, kind: str) -> str:
    return os.path.join(dbmodel_path, "schemas", "addon", kind.lower(), "updates")


def kind_update_roots(dbmodel_path: str, kind: str) -> list[str]:
    from .changelog import network_update_roots

    k = kind.lower()
    if k in MAIN_KINDS:
        return network_update_roots(dbmodel_path, k)
    return [addon_updates_root(dbmodel_path, k)]


def update_kind_order(dbmodel_path: str) -> tuple[str, ...]:
    kinds = all_kinds(dbmodel_path)
    if not kinds:
        return (
            "utils",
            "cibs",
            "ws",
            "ud",
            "am",
            "cm",
            "audit",
        )
    order: dict[str, int] = {}
    for kind in kinds:
        order[kind] = _DEFAULT_UPDATE_ORDER.get(kind, _UNKNOWN_ADDON_ORDER)
    return tuple(sorted(kinds, key=lambda k: (order[k], k)))


def infer_parents_on_update(kind: str) -> bool:
    return kind.lower() in ("utils", "ws", "ud")


def integrate_profile(manifest: Manifest, parent_type: str) -> str | None:
    profiles = set(manifest.profiles.keys())
    pt = parent_type.lower()
    if f"integrate_{pt}" in profiles:
        return f"integrate_{pt}"
    for name in profiles:
        if name.startswith("integrate") and name.endswith(f"_{pt}"):
            return name
    if "integrate" in profiles:
        return "integrate"
    if "activate" in profiles:
        return "activate"
    return None


def supports_integrate(manifest: Manifest) -> bool:
    for pt in ("ws", "ud"):
        if integrate_profile(manifest, pt) is not None:
            return True
    return False


def resolve_create_profile(kind: str, cli_profile: str | None) -> str:
    k = kind.lower()
    profile = (cli_profile or "empty").strip() or "empty"
    if k in _CREATE_DEFAULT_PROFILE and profile == "empty":
        return _CREATE_DEFAULT_PROFILE[k]
    if k == "audit":
        return "empty"
    aliases = _CREATE_PROFILE_BY_KIND.get(k)
    if aliases and profile in aliases:
        return aliases[profile]
    return profile


def resolve_integrate_cli_profile(kind: str, cli_profile: str | None) -> str | None:
    """Map ``schema addon integrate --profile`` for kinds with extra integrate modes (am)."""
    k = kind.lower()
    profile = (cli_profile or "empty").strip() or "empty"
    if k == "am":
        mapping = {"empty": "integrate", "sample": "integrate_sample"}
        return mapping.get(profile)
    return None


def register_context(
    profile: str,
    *,
    ws_schema: str = "",
    ud_schema: str = "",
    parent_schema: str = "",
    parent_type: str = "",
) -> dict[str, str]:
    register_is_new = "true" if profile in _NEW_PROJECT_PROFILES else "false"
    infer_parents = (
        "true"
        if profile == "update" or profile.startswith("integrate") or profile == "activate"
        else "false"
    )

    register_parent = ""
    resolved_parent_type = parent_type

    if profile == "integrate_ws" or profile.endswith("_ws"):
        register_parent = ws_schema or parent_schema
        resolved_parent_type = "ws"
    elif profile == "integrate_ud" or profile.endswith("_ud"):
        register_parent = ud_schema or parent_schema
        resolved_parent_type = "ud"
    elif profile in ("integrate", "activate", "integrate_sample") or (
        profile.startswith("integrate_")
        and not profile.endswith(("_ws", "_ud"))
    ):
        register_parent = parent_schema

    return {
        "register_is_new": register_is_new,
        "infer_parents_from_config": infer_parents,
        "register_parent_schema": register_parent,
        "parent_type": resolved_parent_type,
    }


def integration_parent_types(dbmodel_path: str, kind: str) -> tuple[str, ...]:
    root = os.path.join(dbmodel_path, "schemas", "addon", kind.lower(), "integration")
    if not os.path.isdir(root):
        return ()
    found: list[str] = []
    for entry in sorted(os.listdir(root)):
        folder = os.path.join(root, entry)
        if os.path.isdir(folder) and os.path.isfile(os.path.join(folder, "integration.sql")):
            found.append(entry.lower())
    return tuple(found)


def integration_sql_exists(dbmodel_path: str, kind: str, parent_type: str) -> bool:
    if not parent_type:
        return False
    path = os.path.join(
        dbmodel_path,
        "schemas",
        "addon",
        kind.lower(),
        "integration",
        parent_type.lower(),
        "integration.sql",
    )
    return os.path.isfile(path)


def profile_needs_parent(profile: str) -> bool:
    return profile.startswith("integrate") or profile == "activate"


def default_schema_name(kind: str) -> str:
    return kind.lower()


__all__ = [
    "MAIN_KINDS",
    "addon_kinds",
    "addon_updates_root",
    "all_kinds",
    "default_schema_name",
    "infer_parents_on_update",
    "integrate_profile",
    "integration_parent_types",
    "integration_sql_exists",
    "is_addon_kind",
    "is_main_kind",
    "kind_update_roots",
    "load_kind_manifest",
    "main_kinds",
    "manifest_path_for",
    "profile_needs_parent",
    "register_context",
    "resolve_create_profile",
    "resolve_integrate_cli_profile",
    "supports_integrate",
    "update_kind_order",
]
