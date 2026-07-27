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
                  steps=(Step(source="ws/fct"),)),
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
    assert len(conn.executed) == 5  # load_base (2) + RESET ROLE + update + final_pass


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
