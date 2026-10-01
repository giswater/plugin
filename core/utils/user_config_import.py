"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import configparser
import os
import re
import shutil
from typing import List, Optional, Tuple

_VERSION_DIR = re.compile(r"^(\d+)\.(\d+)$")


def parse_folder_version(name: str) -> Optional[Tuple[int, int]]:
    """Parse a user-folder name like '4.18' into (4, 18)."""
    match = _VERSION_DIR.match(name)
    if not match:
        return None
    return int(match.group(1)), int(match.group(2))


def _make_config_parser():
    """Same options as tools_gw._make_config_parser. Kept here so this module stays free of QGIS."""
    return configparser.ConfigParser(comment_prefixes=";", allow_no_value=True, strict=False)


def _is_nonempty_file(path: str) -> bool:
    try:
        return os.path.isfile(path) and os.path.getsize(path) > 0
    except OSError:
        return False


def _can_parse_init(path: str) -> bool:
    """True when ConfigParser can read the file. A bad file must not stop startup."""
    parser = _make_config_parser()
    try:
        return len(parser.read(path)) > 0
    except Exception:
        return False


def _init_config_candidates(version_dir: str) -> Tuple[str, str]:
    """Current layout first, then the pre-3.5 config folder."""
    return (
        os.path.join(version_dir, "core", "config", "init.config"),
        os.path.join(version_dir, "config", "init.config"),
    )


def _usable_init(version_dir: str) -> Optional[str]:
    for path in _init_config_candidates(version_dir):
        if _is_nonempty_file(path) and _can_parse_init(path):
            return path
    return None


def _older_version_dirs(giswater_root: str, current_version: Tuple[int, int]) -> List[Tuple[Tuple[int, int], str]]:
    found = []
    for name in os.listdir(giswater_root):
        version = parse_folder_version(name)
        if version is None or version >= current_version:
            continue
        version_dir = os.path.join(giswater_root, name)
        if os.path.isdir(version_dir):
            found.append((version, version_dir))
    found.sort(reverse=True)
    return found


def _replace_init(source: str, dest: str) -> None:
    """Copy via init.config.tmp, then replace. A failed write must not leave a partial init.config."""
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    tmp = dest + ".tmp"
    try:
        shutil.copy2(source, tmp)
        os.replace(tmp, dest)
    except Exception:
        if os.path.exists(tmp):
            try:
                os.remove(tmp)
            except OSError:
                pass
        raise


def import_previous_init(user_folder_dir: str) -> Optional[str]:
    """Copy init.config from the newest older version folder.

    ``user_folder_dir`` is the version root (``.../Giswater/4.18``), not ``core``.
    Copies only when the current ``core/config/init.config`` is missing or zero bytes.
    Skips empty or unparseable sources and tries the next candidate.
    Returns the source path when a file was copied, otherwise None.
    """
    if not user_folder_dir:
        return None

    user_folder_dir = os.path.abspath(user_folder_dir)
    current_version = parse_folder_version(os.path.basename(user_folder_dir))
    if current_version is None:
        return None

    dest = os.path.join(user_folder_dir, "core", "config", "init.config")
    if _is_nonempty_file(dest):
        return None

    giswater_root = os.path.dirname(user_folder_dir)
    if not os.path.isdir(giswater_root):
        return None

    source = None
    for _, version_dir in _older_version_dirs(giswater_root, current_version):
        source = _usable_init(version_dir)
        if source is not None:
            break
    if source is None:
        return None

    _replace_init(source, dest)
    return source
