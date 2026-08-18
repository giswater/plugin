"""End-to-end SchemaBuilder behaviour with a fake connection + tmp dbmodel."""

from __future__ import annotations

import os
import re
from pathlib import Path

import pytest

from giswater_admin.engine.builder import BuildParams, SchemaBuilder
from giswater_admin.engine.cancel import CancelToken
from giswater_admin.engine.manifest import Manifest, Phase, Profile, Step, load_manifest


class _RecConn:
    def __init__(self, fail_on: str = "") -> None:
        self.fail_on = fail_on
        self.executed: list[str] = []
        self.commits = 0
        self.rollbacks = 0
        self._err = ""

    def execute(self, sql: str, *, filepath: str | None = None) -> bool:
        if self.fail_on and self.fail_on in (filepath or sql):
            self._err = f"forced failure on {self.fail_on}"
            return False
        self.executed.append(filepath or sql[:40])
        return True

    def last_error(self) -> str:
        return self._err

    def commit(self) -> None:
        self.commits += 1

    def rollback(self) -> None:
        self.rollbacks += 1

    def close(self) -> None:
        pass


def _seed(root: Path) -> None:
    """Tiny synthetic dbmodel."""
    (root / "init.sql").write_text("-- init SCHEMA_NAME", encoding="utf-8")
    (root / "ws" / "fct").mkdir(parents=True)
    (root / "ws" / "fct" / "01.sql").write_text("-- one\nSELECT 'SCHEMA_NAME';", encoding="utf-8")
    (root / "ws" / "fct" / "02.sql").write_text("-- two", encoding="utf-8")
    (root / "updates" / "4" / "9" / "0" / "ws").mkdir(parents=True)
    (root / "updates" / "4" / "9" / "0" / "ws" / "ddl.sql").write_text("-- update", encoding="utf-8")
    (root / "final_pass" / "ws" / "i18n" / "en_US").mkdir(parents=True)
    (root / "final_pass" / "ws" / "i18n" / "en_US" / "en_US.sql").write_text("-- en", encoding="utf-8")
    (root / "final_pass" / "ws" / "i18n" / "es_ES").mkdir(parents=True)
    (root / "final_pass" / "ws" / "i18n" / "es_ES" / "es_ES.sql").write_text("-- es", encoding="utf-8")


def _manifest() -> Manifest:
    return Manifest(
        kind="ws",
        engine_version=1,
        substitutions={},
        phases=(
            Phase(id="load_base", type="sql_dir",
                  steps=(Step(source="init.sql"), Step(source="ws/fct"),)),
            Phase(id="updates", type="version_walk", root="updates",
                  subdirs=("ws",), range={"mode": "{{ run_mode }}"}),
            Phase(id="final_pass", type="sql_dir",
                  steps=(Step(
                      source="final_pass/ws/i18n/{{ locale }}",
                      fallback_source="final_pass/ws/i18n/en_US",
                  ),)),
        ),
        profiles={"empty": Profile(name="empty",
                                    phases=("load_base", "updates", "final_pass"))},
    )


def test_runs_all_phases_successfully(tmp_path: Path):
    _seed(tmp_path)
    conn = _RecConn()
    params = BuildParams(
        schema_name="ws_demo", srid="25831", sql_root=str(tmp_path),
        plugin_version="4.9.0", profile="empty",
    )
    result = SchemaBuilder(conn, _manifest(), params).run()
    assert result.ok
    assert [pr.phase_id for pr in result.phases] == ["load_base", "updates", "final_pass"]
    assert len(conn.executed) == 6  # init + load_base (2) + RESET ROLE + update + final_pass


def test_locale_fallback_used_when_locale_folder_missing(tmp_path: Path):
    _seed(tmp_path)
    conn = _RecConn()
    params = BuildParams(
        schema_name="ws_demo", sql_root=str(tmp_path),
        plugin_version="4.9.0", profile="empty",
        locale="zz_ZZ",  # nonexistent
    )
    result = SchemaBuilder(conn, _manifest(), params).run()
    assert result.ok
    fp = next(pr for pr in result.phases if pr.phase_id == "final_pass")
    assert any("en_US" in fx.path for fx in fp.files)


def test_no_tr_skips_i18n_fallback(tmp_path: Path):
    _seed(tmp_path)
    conn = _RecConn()
    params = BuildParams(
        schema_name="ws_demo", sql_root=str(tmp_path),
        plugin_version="4.9.0", profile="empty",
        locale="no_TR",
    )
    result = SchemaBuilder(conn, _manifest(), params).run()
    assert result.ok
    fp = next(pr for pr in result.phases if pr.phase_id == "final_pass")
    assert fp.files == []


def test_missing_es_locale_uses_es_ES_i18n(tmp_path: Path):
    _seed(tmp_path)
    conn = _RecConn()
    params = BuildParams(
        schema_name="ws_demo", sql_root=str(tmp_path),
        plugin_version="4.9.0", profile="empty",
        locale="es_CR",
    )
    result = SchemaBuilder(conn, _manifest(), params).run()
    assert result.ok
    fp = next(pr for pr in result.phases if pr.phase_id == "final_pass")
    assert any("es_ES" in fx.path.replace("\\", "/") for fx in fp.files)
    assert not any("es_CR" in fx.path.replace("\\", "/") for fx in fp.files)


def test_stops_on_first_failure(tmp_path: Path):
    _seed(tmp_path)
    conn = _RecConn(fail_on="01.sql")
    params = BuildParams(
        schema_name="ws_demo", sql_root=str(tmp_path),
        plugin_version="4.9.0", profile="empty",
    )
    result = SchemaBuilder(conn, _manifest(), params).run()
    assert not result.ok
    assert len(result.phases) == 1  # bailed out before updates/final_pass
    fail = result.first_failure()
    assert fail is not None and "01.sql" in fail.path


def test_cancel_token_stops_engine(tmp_path: Path):
    _seed(tmp_path)
    conn = _RecConn()
    token = CancelToken()
    token.cancel()
    params = BuildParams(
        schema_name="ws_demo", sql_root=str(tmp_path),
        plugin_version="4.9.0", profile="empty",
        cancel_token=token,
    )
    result = SchemaBuilder(conn, _manifest(), params).run()
    assert result.cancelled
    assert not result.ok


def test_substitutions_applied_in_file_content(tmp_path: Path):
    _seed(tmp_path)
    conn = _RecConn()

    # Spy on what arrives at execute().
    sent_payloads: list[str] = []
    original = conn.execute
    def spy(sql, *, filepath=None):
        sent_payloads.append(sql)
        return original(sql, filepath=filepath)
    conn.execute = spy  # type: ignore[method-assign]

    params = BuildParams(
        schema_name="ws_real", srid="3857", sql_root=str(tmp_path),
        plugin_version="4.9.0", profile="empty",
    )
    SchemaBuilder(conn, _manifest(), params).run()
    assert any("ws_real" in p for p in sent_payloads)


def test_utils_integrate_ud_uses_parent_schema_for_sql(tmp_path: Path, dbmodel_path: Path):
    """Integration SQL must run against the ud parent, not the utils satellite schema."""
    from giswater_admin.engine.templating import apply_subs

    manifest_path = os.path.join(dbmodel_path, "manifests", "utils.yaml")
    if not os.path.isfile(manifest_path):
        return

    manifest = load_manifest(manifest_path)
    step = manifest.phase("integrate_utils_ud").steps[0]
    params = BuildParams(
        schema_name="utils",
        ud_schema="ud_parent",
        parent_schema="ud_parent",
        sql_root=dbmodel_path,
        plugin_version="4.12.0",
        profile="integrate_ud",
    )
    subs = SchemaBuilder(_RecConn(), manifest, params)._step_subs(step)
    assert subs["SCHEMA_NAME"] == "ud_parent"

    params_ud_only = BuildParams(
        schema_name="utils",
        ud_schema="ud_only",
        register_parent_schema="ud_only",
        sql_root=dbmodel_path,
        plugin_version="4.12.0",
        profile="integrate_ud",
    )
    assert params_ud_only.base_subs()["SCHEMA_NAME"] == "ud_only"

    sql_path = os.path.join(dbmodel_path, step.source)
    with open(sql_path, encoding="utf-8") as f:
        sql = apply_subs(f.read(), subs)
    assert 'SET search_path = "ud_parent"' in sql
    assert "ALTER TABLE node DROP CONSTRAINT node_district_id_fkey;" in sql


def _sample_overlay_manifest() -> Manifest:
    return Manifest(
        kind="ws",
        engine_version=1,
        substitutions={},
        phases=(
            Phase(
                id="load_sample",
                type="sql_dir",
                steps=(
                    Step(
                        source="sample/user/{{ locale }}",
                        fallback_source="sample/user/en_US",
                        shared_source="sample/user",
                    ),
                ),
            ),
        ),
        profiles={"sample": Profile(name="sample", phases=("load_sample",))},
    )


def _seed_sample_overlay(root: Path) -> None:
    user = root / "sample" / "user"
    user.mkdir(parents=True)
    for name in ("01", "04", "05", "07", "08"):
        (user / f"{name}.sql").write_text(f"-- shared {name}", encoding="utf-8")
    es = user / "es_ES"
    es.mkdir()
    (es / "02.sql").write_text("-- es 02", encoding="utf-8")
    (es / "07.sql").write_text("-- es 07", encoding="utf-8")
    (user / "en_US").mkdir()
    (user / "en_US" / "02.sql").write_text("-- en 02", encoding="utf-8")
    (user / "ca_ES").mkdir()
    (user / "ca_ES" / "02.sql").write_text("-- ca 02", encoding="utf-8")


def _overlay_parents(root: Path, locale: str) -> dict[str, str]:
    builder = SchemaBuilder(
        _RecConn(),
        _sample_overlay_manifest(),
        BuildParams(
            schema_name="ws_demo", sql_root=str(root),
            plugin_version="4.9.0", profile="sample", locale=locale,
        ),
    )
    files = builder._files_for_step(builder.manifest.phase("load_sample").steps[0])
    return {Path(p).name: Path(p).parent.name for p in files}


_SAMPLE_ORDER = ["01.sql", "02.sql", "04.sql", "05.sql", "07.sql", "08.sql"]


@pytest.mark.parametrize(
    "locale, file_02, file_07",
    [
        ("es_ES", "es_ES", "es_ES"),
        ("ca_ES", "ca_ES", "user"),
        ("en_US", "en_US", "user"),
        ("zz_ZZ", "en_US", "user"),
        ("es_CR", "es_ES", "es_ES"),
        ("es_MX", "es_ES", "es_ES"),
        ("no_TR", "en_US", "user"),
    ],
)
def test_sample_overlay_resolves_locale(tmp_path: Path, locale: str, file_02: str, file_07: str):
    """Existing folders win; missing es_* → es_ES; anything else → en_US.

    no_TR skips i18n fallback only; sample still uses en_US.
    """
    _seed_sample_overlay(tmp_path)
    got = _overlay_parents(tmp_path, locale)
    assert list(got) == _SAMPLE_ORDER
    assert got["01.sql"] == "user"
    assert got["02.sql"] == file_02
    assert got["07.sql"] == file_07


def test_sample_overlay_uses_es_CR_folder_when_present(tmp_path: Path):
    _seed_sample_overlay(tmp_path)
    cr_dir = tmp_path / "sample" / "user" / "es_CR"
    cr_dir.mkdir()
    (cr_dir / "02.sql").write_text("-- cr 02", encoding="utf-8")
    got = _overlay_parents(tmp_path, "es_CR")
    assert list(got) == _SAMPLE_ORDER
    assert got["02.sql"] == "es_CR" and got["07.sql"] == "user"


def test_progress_label_is_the_file_that_ran(tmp_path: Path):
    """Log path is the resolved file (es_ES fallback), not the wanted es_CR folder."""
    _seed_sample_overlay(tmp_path)
    labels: list[str] = []

    def cb(seen: int, total: int, label: str, fx=None) -> None:
        if fx is not None and getattr(fx, "path", None):
            assert label == fx.path
        if str(label).endswith(".sql"):
            labels.append(str(label).replace("\\", "/"))

    SchemaBuilder(
        _RecConn(),
        _sample_overlay_manifest(),
        BuildParams(
            schema_name="ws_demo", sql_root=str(tmp_path),
            plugin_version="4.9.0", profile="sample", locale="es_CR",
        ),
        progress_cb=cb,
    ).run()
    assert labels
    assert any("/es_ES/" in p for p in labels)
    assert all("/es_CR/" not in p for p in labels)


def _real_builder(dbmodel_path: str, kind: str, locale: str, profile: str = "sample_full") -> SchemaBuilder:
    return SchemaBuilder(
        _RecConn(),
        load_manifest(os.path.join(dbmodel_path, "manifests", f"{kind}.yaml")),
        BuildParams(
            schema_name=f"{kind}_demo",
            sql_root=dbmodel_path,
            plugin_version="4.15.0",
            profile=profile,
            locale=locale,
        ),
    )


@pytest.mark.parametrize("kind", ["ws", "ud"])
def test_real_load_sample_step_declares_overlay(dbmodel_path: str, kind: str):
    step = load_manifest(os.path.join(dbmodel_path, "manifests", f"{kind}.yaml")).phase(
        "load_sample"
    ).steps[0]
    assert "{{ locale }}" in step.source
    assert step.fallback_source.endswith("en_US")
    assert step.shared_source.endswith("sample/user")


_LOCALE_DIR = re.compile(r"^[a-z]{2}_[A-Z]{2}$")
_SAMPLE_NUM = re.compile(r"_(\d+)_")


def _sql_files(folder: Path) -> list[Path]:
    if not folder.is_dir():
        return []
    return sorted(p for p in folder.iterdir() if p.is_file() and p.suffix.lower() == ".sql")


def _sample_numbers(folder: Path) -> set[str]:
    nums: set[str] = set()
    for path in _sql_files(folder):
        match = _SAMPLE_NUM.search(path.name)
        assert match, f"{path.name} in {folder} has no _NNN_ sample number"
        nums.add(match.group(1))
    return nums


@pytest.mark.parametrize("kind", ["ws", "ud"])
def test_real_sample_locale_folders_share_numbers_not_in_parent(dbmodel_path: str, kind: str):
    """Every locale folder must carry the same overlay numbers; those stay out of sample/user/.

    Today that is 003; later 008/009 or any other number — the test does not hardcode them.
    """
    user_dir = Path(dbmodel_path) / "schemas" / "main" / kind / "sample" / "user"
    locale_dirs = sorted(
        p for p in user_dir.iterdir() if p.is_dir() and _LOCALE_DIR.match(p.name)
    )
    assert locale_dirs, f"expected locale folders under {user_dir}"

    numbers_by_dir = {d.name: _sample_numbers(d) for d in locale_dirs}
    expected = numbers_by_dir[locale_dirs[0].name]
    assert expected, f"{locale_dirs[0].name} has no overlay SQL"
    for name, nums in numbers_by_dir.items():
        assert nums == expected, (
            f"{kind} locale {name} has numbers {sorted(nums)}, "
            f"expected {sorted(expected)} (all locale folders must have the same overlay numbers)"
        )

    overlap = expected & _sample_numbers(user_dir)
    assert not overlap, (
        f"{kind} overlay numbers {sorted(overlap)} are in locale folders and also in "
        f"sample/user/; translated files must not be duplicated in the shared parent"
    )


def _i18n_dir(dbmodel_path: str, kind: str, locale: str) -> Path:
    return Path(dbmodel_path) / "schemas" / "main" / kind / "final_pass" / "i18n" / locale


def _i18n_has_sql(dbmodel_path: str, kind: str, locale: str) -> bool:
    folder = _i18n_dir(dbmodel_path, kind, locale)
    return folder.is_dir() and any(folder.glob("*.sql"))


def _real_i18n_step(builder: SchemaBuilder):
    return next(s for s in builder.manifest.phase("final_pass_empty").steps if "i18n" in s.source)


@pytest.mark.parametrize("kind", ["ws", "ud"])
def test_real_i18n_missing_locale_uses_bundled_en_US(dbmodel_path: str, kind: str):
    """en_US i18n is the only locale committed in git; downloaded packs are optional."""
    assert _i18n_has_sql(dbmodel_path, kind, "en_US")
    builder = _real_builder(dbmodel_path, kind, "zz_ZZ", profile="empty")
    files = builder._files_for_step(_real_i18n_step(builder))
    assert files
    assert all("/en_US/" in p.replace("\\", "/") for p in files)
    assert all("/zz_ZZ/" not in p.replace("\\", "/") for p in files)


@pytest.mark.parametrize("kind", ["ws", "ud"])
def test_real_i18n_missing_es_locale_uses_es_ES_when_downloaded(dbmodel_path: str, kind: str):
    """es_* fallback needs es_ES on disk. Skip if that pack was never downloaded.

    Use es_MX (not es_CR): a downloaded es_CR folder would be used as-is.
    """
    if not _i18n_has_sql(dbmodel_path, kind, "es_ES"):
        pytest.skip("es_ES i18n SQL is not bundled; download it to exercise this fallback")
    builder = _real_builder(dbmodel_path, kind, "es_MX", profile="empty")
    files = builder._files_for_step(_real_i18n_step(builder))
    assert files
    assert all("/es_ES/" in p.replace("\\", "/") for p in files)
    assert all("/es_MX/" not in p.replace("\\", "/") for p in files)


@pytest.mark.parametrize("kind", ["ws", "ud"])
def test_real_i18n_no_tr_skips_fallback(dbmodel_path: str, kind: str):
    builder = _real_builder(dbmodel_path, kind, "no_TR", profile="empty")
    assert builder._files_for_step(_real_i18n_step(builder)) == []


@pytest.mark.parametrize("kind", ["ws", "ud"])
def test_sample_final_pass_skips_cff_clone_locale(dbmodel_path: str, kind: str):
    builder = _real_builder(dbmodel_path, kind, "en_US", profile="sample_full")
    cff = next(
        s for s in builder.manifest.phase("final_pass").steps
        if s.source.endswith("config_form_fields")
    )
    names = [os.path.basename(p) for p in builder._files_for_step(cff)]
    assert "99_cff_clone_locale.sql" not in names
    assert "00_cff_init.sql" in names
    assert "01_cff_base.sql" in names


@pytest.mark.parametrize("kind", ["ws", "ud"])
def test_empty_final_pass_runs_cff_clone_locale(dbmodel_path: str, kind: str):
    builder = _real_builder(dbmodel_path, kind, "en_US", profile="empty")
    names = [
        os.path.basename(p)
        for s in builder.manifest.phase("final_pass_empty").steps
        for p in builder._files_for_step(s)
    ]
    assert "99_cff_clone_locale.sql" in names
    assert "00_cff_init.sql" in names
    assert "01_cff_base.sql" in names
    assert "01_cff_arc.sql" not in names
