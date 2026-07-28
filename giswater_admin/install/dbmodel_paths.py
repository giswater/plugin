"""Resolve dbmodel directory paths for the ``gw`` CLI."""

from __future__ import annotations

import os
from pathlib import Path

from .config import list_cached_versions, load_config, release_dbmodel_dir

PACKAGE_DIR = Path(__file__).resolve().parents[1]
REPO_ROOT = PACKAGE_DIR.parent
DEV_DBMODEL = REPO_ROOT / "dbmodel"
ENV_DBMODEL = "GW_DBMODEL_PATH"


def _is_valid_dbmodel(path: str | os.PathLike[str]) -> bool:
    return (Path(path) / "manifests" / "ws.yaml").is_file()


def _repo_dev_dbmodel() -> str | None:
    if _is_valid_dbmodel(DEV_DBMODEL):
        return str(DEV_DBMODEL)
    return None


def _from_config() -> str | None:
    cfg = load_config()
    dbmodel = cfg.get("dbmodel") or {}
    source = dbmodel.get("source") or "release"

    if source == "dev":
        dev_root = dbmodel.get("dev_root")
        if not dev_root:
            return None
        candidate = Path(dev_root) / "dbmodel"
        if _is_valid_dbmodel(candidate):
            return str(candidate)
        return None

    version = dbmodel.get("version")
    if not version:
        cached = list_cached_versions()
        if cached:
            version = cached[-1]
        else:
            return None
    candidate = release_dbmodel_dir(str(version))
    if _is_valid_dbmodel(candidate):
        return str(candidate)
    return None


def resolve_dbmodel_path(explicit: str | None) -> str:
    """
    Resolve the dbmodel root directory.

    Priority:
      1. explicit ``--dbmodel-path``
      2. ``GW_DBMODEL_PATH`` environment variable
      3. user config with ``source: dev`` (``gw dbmodel use dev``)
      4. sibling ``dbmodel/`` in a plugin repo checkout (local dev)
      5. user config release cache (``gw dbmodel install``)
    """
    if explicit:
        path = os.path.abspath(explicit)
        if not _is_valid_dbmodel(path):
            raise RuntimeError(
                f"Invalid dbmodel path (missing manifests/ws.yaml): {path}"
            )
        return path

    env_path = os.environ.get(ENV_DBMODEL)
    if env_path:
        path = os.path.abspath(env_path)
        if not _is_valid_dbmodel(path):
            raise RuntimeError(
                f"Invalid {ENV_DBMODEL} (missing manifests/ws.yaml): {path}"
            )
        return path

    dbmodel_cfg = (load_config().get("dbmodel") or {})
    if dbmodel_cfg.get("source") == "dev":
        configured_dev = _from_config()
        if configured_dev:
            return configured_dev

    repo_dev = _repo_dev_dbmodel()
    if repo_dev:
        return repo_dev

    configured = _from_config()
    if configured:
        return configured

    raise RuntimeError(_bootstrap_message())


def _bootstrap_message() -> str:
    return (
        "No dbmodel found. Run one of:\n"
        "  gw dbmodel install latest\n"
        "  gw dbmodel use dev --root /path/to/plugin\n"
        "  gw schema main create ... --dbmodel-path /path/to/dbmodel\n"
        f"Or set {ENV_DBMODEL} to a dbmodel directory."
    )
