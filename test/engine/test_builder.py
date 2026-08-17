"""End-to-end SchemaBuilder behaviour with a fake connection + tmp dbmodel."""

from __future__ import annotations

from pathlib import Path

from giswater_admin.engine.builder import BuildParams, SchemaBuilder
from giswater_admin.engine.cancel import CancelToken
from giswater_admin.engine.manifest import Manifest, Phase, Profile, Step


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


def test_no_tr_skips_locale_fallback(tmp_path: Path):
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
    from giswater_admin.engine.manifest import load_manifest
    from giswater_admin.engine.templating import apply_subs
    import os

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


def test_shared_source_merges_locale_and_parent_by_basename(tmp_path: Path):
    _seed_sample_overlay(tmp_path)
    order = ["01.sql", "02.sql", "04.sql", "05.sql", "07.sql", "08.sql"]

    es = _overlay_parents(tmp_path, "es_ES")
    assert list(es) == order
    assert es["02.sql"] == "es_ES" and es["07.sql"] == "es_ES"

    ca = _overlay_parents(tmp_path, "ca_ES")
    assert list(ca) == order
    assert ca["02.sql"] == "ca_ES" and ca["07.sql"] == "user"

    en = _overlay_parents(tmp_path, "en_US")
    assert en["02.sql"] == "en_US" and en["07.sql"] == "user"

    missing = _overlay_parents(tmp_path, "zz_ZZ")
    assert missing["02.sql"] == "en_US" and missing["07.sql"] == "user"

    cr = _overlay_parents(tmp_path, "es_CR")
    assert cr["02.sql"] == "es_ES" and cr["07.sql"] == "es_ES"
    assert "es_CR" not in "".join(cr.values())

    cr_dir = tmp_path / "sample" / "user" / "es_CR"
    cr_dir.mkdir()
    (cr_dir / "02.sql").write_text("-- cr 02", encoding="utf-8")
    cr_exists = _overlay_parents(tmp_path, "es_CR")
    assert cr_exists["02.sql"] == "es_CR" and cr_exists["07.sql"] == "user"


def test_progress_reports_resolved_path_not_wanted_locale(tmp_path: Path):
    """es_CR without a folder must log es_ES paths, not the wanted es_CR path."""
    _seed_sample_overlay(tmp_path)
    labels: list[str] = []

    def cb(seen: int, total: int, label: str, fx=None) -> None:
        shown = fx.path if fx is not None and getattr(fx, "path", None) else label
        if shown.endswith(".sql"):
            labels.append(shown.replace("\\", "/"))

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
