"""Tests for copying init.config from a previous Giswater user folder."""

import importlib.util
from pathlib import Path

_MODULE_PATH = Path(__file__).resolve().parents[2] / "core" / "utils" / "user_config_import.py"
_spec = importlib.util.spec_from_file_location("user_config_import", _MODULE_PATH)
assert _spec is not None and _spec.loader is not None
user_config_import = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(user_config_import)


def _write_init(root, version, content, legacy=False):
    if legacy:
        path = root / version / "config" / "init.config"
    else:
        path = root / version / "core" / "config" / "init.config"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return path


def test_parse_folder_version():
    assert user_config_import.parse_folder_version("4.18") == (4, 18)
    assert user_config_import.parse_folder_version("4.9") == (4, 9)
    assert user_config_import.parse_folder_version("4.18.0") is None
    assert user_config_import.parse_folder_version("backup") is None


def test_copies_from_previous_into_empty_current(tmp_path):
    source = _write_init(tmp_path, "4.17", "[toolbars_add]\ncm_active = True\n")
    current = tmp_path / "4.18"

    copied = user_config_import.import_previous_init(str(current))

    dest = current / "core" / "config" / "init.config"
    assert copied == str(source)
    assert dest.read_text(encoding="utf-8") == "[toolbars_add]\ncm_active = True\n"
    assert not dest.with_name("init.config.tmp").exists()


def test_prefers_newest_older_version(tmp_path):
    _write_init(tmp_path, "4.9", "[s]\nk = old\n")
    _write_init(tmp_path, "4.16", "[s]\nk = middle\n")
    newest = _write_init(tmp_path, "4.17", "[s]\nk = newest\n")

    copied = user_config_import.import_previous_init(str(tmp_path / "4.18"))

    dest = tmp_path / "4.18" / "core" / "config" / "init.config"
    assert copied == str(newest)
    assert dest.read_text(encoding="utf-8") == "[s]\nk = newest\n"


def test_skips_nonempty_current_init(tmp_path):
    _write_init(tmp_path, "4.17", "from-previous\n")
    current = _write_init(tmp_path, "4.18", "already-set\n")

    copied = user_config_import.import_previous_init(str(tmp_path / "4.18"))

    assert copied is None
    assert current.read_text(encoding="utf-8") == "already-set\n"


def test_skips_empty_previous_and_uses_next_older(tmp_path):
    empty = _write_init(tmp_path, "4.17", "")
    assert empty.stat().st_size == 0
    older = _write_init(tmp_path, "4.16", "[s]\nk = kept\n")

    copied = user_config_import.import_previous_init(str(tmp_path / "4.18"))

    dest = tmp_path / "4.18" / "core" / "config" / "init.config"
    assert copied == str(older)
    assert dest.read_text(encoding="utf-8") == "[s]\nk = kept\n"


def test_uses_legacy_config_path(tmp_path):
    source = _write_init(tmp_path, "3.5", "[s]\nk = legacy\n", legacy=True)

    copied = user_config_import.import_previous_init(str(tmp_path / "4.18"))

    dest = tmp_path / "4.18" / "core" / "config" / "init.config"
    assert copied == str(source)
    assert dest.read_text(encoding="utf-8") == "[s]\nk = legacy\n"


def test_skips_unparseable_and_uses_next_older(tmp_path):
    _write_init(tmp_path, "4.17", "cm_active = True\n")
    older = _write_init(tmp_path, "4.16", "[toolbars_add]\ncm_active = True\n")

    copied = user_config_import.import_previous_init(str(tmp_path / "4.18"))

    dest = tmp_path / "4.18" / "core" / "config" / "init.config"
    assert copied == str(older)
    assert dest.read_text(encoding="utf-8") == "[toolbars_add]\ncm_active = True\n"


def test_broken_core_falls_through_to_legacy(tmp_path):
    _write_init(tmp_path, "3.5", "cm_active = True\n")
    source = _write_init(tmp_path, "3.5", "[toolbars_add]\ncm_active = True\n", legacy=True)

    copied = user_config_import.import_previous_init(str(tmp_path / "4.18"))

    dest = tmp_path / "4.18" / "core" / "config" / "init.config"
    assert copied == str(source)
    assert dest.read_text(encoding="utf-8") == "[toolbars_add]\ncm_active = True\n"


def test_no_siblings_leaves_destination_untouched(tmp_path):
    current = tmp_path / "4.18"

    copied = user_config_import.import_previous_init(str(current))

    assert copied is None
    assert not (current / "core" / "config" / "init.config").exists()
