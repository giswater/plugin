"""SchemaBuilder role_system session handling."""

from __future__ import annotations

from pathlib import Path

from giswater_admin.engine.builder import BuildParams, SchemaBuilder
from giswater_admin.engine.manifest import Manifest, Phase, Profile, Step


class _SqlCaptureConn:
    def __init__(self) -> None:
        self.sql: list[str] = []

    def execute(self, sql: str, *, filepath: str | None = None) -> bool:
        self.sql.append(sql)
        return True

    def last_error(self) -> str:
        return ""

    def commit(self) -> None:
        pass

    def rollback(self) -> None:
        pass

    def close(self) -> None:
        pass


def _seed(root: Path) -> None:
    (root / "base").mkdir(parents=True)
    (root / "base" / "init.sql").write_text(
        "RESET ROLE;\n-- init\nSET ROLE role_system;\n",
        encoding="utf-8",
    )
    (root / "reload").mkdir(parents=True)
    (root / "reload" / "fn.sql").write_text("-- reload fn", encoding="utf-8")
    (root / "updates" / "4" / "15" / "0" / "ws").mkdir(parents=True)
    (root / "updates" / "4" / "15" / "0" / "ws" / "patch.sql").write_text(
        "-- update patch", encoding="utf-8"
    )
    (root / "sample").mkdir(parents=True)
    (root / "sample" / "data.sql").write_text("-- sample", encoding="utf-8")


def _manifest() -> Manifest:
    return Manifest(
        kind="ws",
        engine_version=1,
        substitutions={},
        phases=(
            Phase(id="load_base", type="sql_dir", steps=(Step(source="base"),)),
            Phase(id="reload_fct_ftrg", type="sql_dir", steps=(Step(source="reload"),)),
            Phase(
                id="updates",
                type="version_walk",
                root="updates",
                subdirs=("ws",),
                range={"mode": "{{ run_mode }}"},
            ),
            Phase(id="load_sample", type="sql_dir", steps=(Step(source="sample"),)),
            Phase(id="final_pass", type="sql_dir", steps=(Step(source="sample"),)),
        ),
        profiles={
            "sample_full": Profile(
                name="sample_full",
                phases=("load_base", "reload_fct_ftrg", "updates", "load_sample", "final_pass"),
            ),
        },
    )


def test_load_base_runs_as_installer_init_sql_sets_role(tmp_path: Path):
    _seed(tmp_path)
    conn = _SqlCaptureConn()
    params = BuildParams(
        schema_name="ws_demo",
        sql_root=str(tmp_path),
        plugin_version="4.15.0",
        profile="sample_full",
    )
    result = SchemaBuilder(conn, _manifest(), params).run()
    assert result.ok

    joined = "\n".join(conn.sql)
    init_pos = joined.index("-- init")
    reload_pos = joined.index("-- reload fn")
    assert joined.count("SET ROLE role_system") == 1
    # init.sql opens with RESET; load_base ends with another RESET after init's SET ROLE.
    assert joined.count("RESET ROLE") == 2
    # load_base runs as installer then role_system via init.sql; reload_fct_ftrg runs as installer.
    assert init_pos < joined.index("SET ROLE role_system") < reload_pos
    # updates/load_sample need superuser (DISABLE TRIGGER ALL in legacy patches)
    assert "-- update patch" in joined
    update_pos = joined.index("-- update patch")
    reset_pos = joined.rindex("RESET ROLE", 0, update_pos)
    assert update_pos > reset_pos
    assert "SET ROLE role_system" not in joined[update_pos:]
