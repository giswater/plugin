"""am, cm, audit smoke builds."""

from __future__ import annotations

import os

import pytest

from giswater_admin.engine import BuildParams, SchemaBuilder, drop_schema, load_manifest


REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
DBMODEL = os.path.join(REPO_ROOT, "dbmodel")


@pytest.fixture()
def parent_ws_for_am(adapter, temp_schema_name):
    """ws parent for am tests (am SQL references PARENT_SCHEMA.ve_*)."""
    ws = f"{temp_schema_name}_ws"
    manifest = load_manifest(os.path.join(DBMODEL, "manifests", "ws.yaml"))
    params = BuildParams(
        schema_name=ws, srid="25831",
        plugin_version="4.9.0", profile="empty",
        sql_root=DBMODEL,
    )
    try:
        r = SchemaBuilder(adapter, manifest, params).run()
        assert r.ok, f"ws build: {r.first_failure()}"
        adapter.commit()
        yield ws
    finally:
        drop_schema(adapter, ws, cascade=True, commit=True)


@pytest.fixture()
def parent_ud_for_am(adapter, temp_schema_name):
    """UD parent for AM integration and dual-parent tests."""
    ud = f"{temp_schema_name}_ud"
    manifest = load_manifest(os.path.join(DBMODEL, "manifests", "ud.yaml"))
    params = BuildParams(
        schema_name=ud, srid="25831",
        plugin_version="4.18.0", profile="empty",
        sql_root=DBMODEL,
    )
    try:
        result = SchemaBuilder(adapter, manifest, params).run()
        assert result.ok, f"ud build: {result.first_failure()}"
        adapter.commit()
        yield ud
    finally:
        drop_schema(adapter, ud, cascade=True, commit=True)


def test_am_empty(adapter, temp_schema_name, parent_ws_for_am):
    manifest = load_manifest(os.path.join(DBMODEL, "manifests", "am.yaml"))
    create_params = BuildParams(
        schema_name=temp_schema_name, srid="25831",
        plugin_version="4.9.0", profile="empty",
        sql_root=DBMODEL,
    )
    integrate_params = BuildParams(
        schema_name=temp_schema_name, srid="25831",
        plugin_version="4.9.0", profile="integrate",
        parent_schema=parent_ws_for_am, parent_type="ws",
        sql_root=DBMODEL,
    )
    try:
        r1 = SchemaBuilder(adapter, manifest, create_params).run()
        assert r1.ok, f"am create: {r1.first_failure()}"
        adapter.commit()
        r2 = SchemaBuilder(adapter, manifest, integrate_params).run()
        assert r2.ok, f"am integrate: {r2.first_failure()}"
        adapter.commit()
    finally:
        drop_schema(adapter, temp_schema_name, cascade=True, commit=True)


def test_am_integrates_ws_and_ud_together(
    adapter, temp_schema_name, parent_ws_for_am, parent_ud_for_am
):
    manifest = load_manifest(os.path.join(DBMODEL, "manifests", "am.yaml"))
    create_params = BuildParams(
        schema_name=temp_schema_name, srid="25831",
        plugin_version="4.18.0", profile="empty",
        sql_root=DBMODEL,
    )
    try:
        result = SchemaBuilder(adapter, manifest, create_params).run()
        assert result.ok, f"am create: {result.first_failure()}"
        adapter.commit()
        for parent_schema, parent_type in (
            (parent_ws_for_am, "ws"),
            (parent_ud_for_am, "ud"),
        ):
            params = BuildParams(
                schema_name=temp_schema_name, srid="25831",
                plugin_version="4.18.0", profile="integrate",
                parent_schema=parent_schema, parent_type=parent_type,
                sql_root=DBMODEL,
            )
            result = SchemaBuilder(adapter, manifest, params).run()
            assert result.ok, f"am integrate {parent_type}: {result.first_failure()}"
            adapter.commit()

        with adapter.raw.cursor() as cur:
            cur.execute(
                "SELECT to_regclass(%s), to_regclass(%s), to_regclass(%s)",
                (
                    f"{temp_schema_name}.v_asset_ud_arc_input",
                    f"{temp_schema_name}.v_asset_ud_node_input",
                    f"{temp_schema_name}.v_ud_node_am",
                ),
            )
            assert all(cur.fetchone())
            cur.execute(
                f'SELECT count(DISTINCT project_type) FROM "{temp_schema_name}".config_catalog_def'
            )
            assert cur.fetchone()[0] == 2
    finally:
        drop_schema(adapter, temp_schema_name, cascade=True, commit=True)


def test_am_upgrade_migrates_legacy_ud_identifiers(adapter, temp_schema_name):
    """The 4.18 update converts legacy integer IDs without losing dependent view metadata."""
    manifest = load_manifest(os.path.join(DBMODEL, "manifests", "am.yaml"))
    create_params = BuildParams(
        schema_name=temp_schema_name, srid="25831",
        plugin_version="4.17.0", profile="empty",
        sql_root=DBMODEL,
    )
    identifier_columns = (
        ("ud_arc_input", "arc_id"),
        ("ud_arc_engine_wm", "arc_id"),
        ("ud_arc_output", "arc_id"),
        ("ud_arc_pathology", "arc_id"),
        ("ud_node_input", "node_id"),
        ("ud_node_engine_wm", "node_id"),
        ("ud_node_output", "node_id"),
        ("ud_node_pathology", "node_id"),
        ("ud_breakdown", "feature_id"),
    )
    try:
        result = SchemaBuilder(adapter, manifest, create_params).run()
        assert result.ok, f"am create-at-4.17: {result.first_failure()}"
        adapter.commit()

        with adapter.raw.cursor() as cur:
            for view_name in (
                "v_asset_ud_arc_output", "v_asset_ud_arc_output_compare",
                "v_asset_ud_arc_corporate", "v_asset_ud_node_output",
                "v_asset_ud_node_output_compare", "v_asset_ud_node_corporate",
            ):
                cur.execute(f'DROP VIEW "{temp_schema_name}".{view_name}')
            for table_name, column_name in identifier_columns:
                cur.execute(
                    f'ALTER TABLE "{temp_schema_name}".{table_name} '
                    f'ALTER COLUMN {column_name} TYPE integer USING {column_name}::integer'
                )
            cur.execute(
                f'CREATE VIEW "{temp_schema_name}".test_ud_id_migration AS '
                f'SELECT arc_id, age FROM "{temp_schema_name}".ud_arc_input'
            )
            cur.execute(
                f'CREATE RULE test_ud_id_migration_update AS '
                f'ON UPDATE TO "{temp_schema_name}".test_ud_id_migration DO INSTEAD '
                f'UPDATE "{temp_schema_name}".ud_arc_input '
                f'SET age = NEW.age WHERE arc_id = OLD.arc_id'
            )
            cur.execute(
                f'GRANT SELECT ON "{temp_schema_name}".test_ud_id_migration TO role_basic'
            )
        adapter.commit()

        upgrade_params = BuildParams(
            schema_name=temp_schema_name, srid="25831",
            plugin_version="4.18.0", project_version="4.17.0",
            run_mode="upgrade", profile="update",
            sql_root=DBMODEL,
        )
        result = SchemaBuilder(adapter, manifest, upgrade_params).run()
        assert result.ok, f"am upgrade-to-4.18: {result.first_failure()}"
        adapter.commit()

        with adapter.raw.cursor() as cur:
            cur.execute(
                """
                SELECT count(*)
                FROM information_schema.columns
                WHERE table_schema = %s
                  AND (table_name, column_name) IN (
                    ('ud_arc_input', 'arc_id'),
                    ('ud_arc_engine_wm', 'arc_id'),
                    ('ud_arc_output', 'arc_id'),
                    ('ud_arc_pathology', 'arc_id'),
                    ('ud_node_input', 'node_id'),
                    ('ud_node_engine_wm', 'node_id'),
                    ('ud_node_output', 'node_id'),
                    ('ud_node_pathology', 'node_id'),
                    ('ud_breakdown', 'feature_id')
                  )
                  AND data_type = 'character varying'
                  AND character_maximum_length = 16
                """,
                (temp_schema_name,),
            )
            assert cur.fetchone()[0] == len(identifier_columns)
            cur.execute(
                "SELECT to_regclass(%s), "
                "EXISTS (SELECT 1 FROM pg_rules WHERE schemaname = %s "
                "AND tablename = 'test_ud_id_migration' "
                "AND rulename = 'test_ud_id_migration_update'), "
                "has_table_privilege('role_basic', %s, 'SELECT')",
                (
                    f"{temp_schema_name}.test_ud_id_migration",
                    temp_schema_name,
                    f"{temp_schema_name}.test_ud_id_migration",
                ),
            )
            view_regclass, has_rule, has_select = cur.fetchone()
            assert view_regclass is not None
            assert has_rule is True
            assert has_select is True
    finally:
        drop_schema(adapter, temp_schema_name, cascade=True, commit=True)


def test_am_create_sample(adapter, temp_schema_name):
    manifest = load_manifest(os.path.join(DBMODEL, "manifests", "am.yaml"))
    params = BuildParams(
        schema_name=temp_schema_name, srid="25831",
        plugin_version="4.9.0", profile="sample",
        sql_root=DBMODEL,
    )
    try:
        result = SchemaBuilder(adapter, manifest, params).run()
        assert result.ok, f"am sample create: {result.first_failure()}"
        adapter.commit()
        load_user = next(p for p in result.phases if p.phase_id == "load_sample_user")
        assert len(load_user.files) >= 1
    finally:
        drop_schema(adapter, temp_schema_name, cascade=True, commit=True)


def test_am_update_replays_no_legacy_patches(adapter, temp_schema_name, parent_ws_for_am):
    """
    Create am pretending to be at 4.0.0, then upgrade to 4.9.0. The
    legacy date-collapsed patch at updates/0/0/0/am/ MUST NOT be
    replayed (it was already applied at create time).
    """
    manifest = load_manifest(os.path.join(DBMODEL, "manifests", "am.yaml"))
    create_params = BuildParams(
        schema_name=temp_schema_name, srid="25831",
        plugin_version="4.0.0", profile="empty",
        sql_root=DBMODEL,
    )
    try:
        r1 = SchemaBuilder(adapter, manifest, create_params).run()
        assert r1.ok, f"am create-at-4.0.0: {r1.first_failure()}"
        adapter.commit()

        integrate_params = BuildParams(
            schema_name=temp_schema_name, srid="25831",
            plugin_version="4.0.0", profile="integrate",
            parent_schema=parent_ws_for_am, parent_type="ws",
            sql_root=DBMODEL,
        )
        r_int = SchemaBuilder(adapter, manifest, integrate_params).run()
        assert r_int.ok, f"am integrate-at-4.0.0: {r_int.first_failure()}"
        adapter.commit()

        upgrade_params = BuildParams(
            schema_name=temp_schema_name, srid="0",
            plugin_version="4.9.0", project_version="4.0.0",
            run_mode="upgrade", profile="update",
            parent_schema=parent_ws_for_am, parent_type="ws",
            sql_root=DBMODEL,
        )
        r2 = SchemaBuilder(adapter, manifest, upgrade_params).run()
        assert r2.ok, f"am upgrade-to-4.9.0: {r2.first_failure()}"
        adapter.commit()

        # The legacy 0/0/0 bucket is <= project_version 4.0.0, so the
        # upgrade phase should pick up zero files (no semver patches
        # between 4.0.0 exclusive and 4.9.0 inclusive exist yet).
        load_updates = next(p for p in r2.phases if p.phase_id == "load_updates")
        assert len(load_updates.files) == 0, (
            "am upgrade should not replay legacy 0/0/0 patches: "
            f"executed {[f.path for f in load_updates.files]}"
        )
    finally:
        drop_schema(adapter, temp_schema_name, cascade=True, commit=True)


def test_audit_structure(adapter):
    manifest = load_manifest(os.path.join(DBMODEL, "manifests", "audit.yaml"))
    params = BuildParams(
        schema_name="audit", srid="25831",
        plugin_version="4.9.0", profile="structure",
        parent_schema="audit",
        sql_root=DBMODEL,
    )
    try:
        # `audit` schema is fixed-name; drop any stale one first.
        drop_schema(adapter, "audit", cascade=True, commit=True)
        result = SchemaBuilder(adapter, manifest, params).run()
        assert result.ok, f"audit structure: {result.first_failure()}"
        adapter.commit()
    finally:
        drop_schema(adapter, "audit", cascade=True, commit=True)


@pytest.fixture()
def parent_ws(adapter, temp_schema_name):
    """ws parent for cm tests."""
    ws = f"{temp_schema_name}_ws"
    manifest = load_manifest(os.path.join(DBMODEL, "manifests", "ws.yaml"))
    params = BuildParams(
        schema_name=ws, srid="25831",
        plugin_version="4.9.0", profile="empty",
        sql_root=DBMODEL,
    )
    try:
        r = SchemaBuilder(adapter, manifest, params).run()
        assert r.ok, f"ws build: {r.first_failure()}"
        adapter.commit()
        yield ws
    finally:
        drop_schema(adapter, ws, cascade=True, commit=True)


def test_cm_empty_attaches_to_ws_parent(adapter, parent_ws):
    cm_schema = f"{parent_ws}_cm"
    manifest = load_manifest(os.path.join(DBMODEL, "manifests", "cm.yaml"))
    params = BuildParams(
        schema_name=cm_schema, srid="25831",
        plugin_version="4.9.0", profile="empty",
        parent_schema=parent_ws, parent_type="ws",
        sql_root=DBMODEL,
    )
    try:
        result = SchemaBuilder(adapter, manifest, params).run()
        assert result.ok, f"cm build: {result.first_failure()}"
        adapter.commit()
    finally:
        drop_schema(adapter, cm_schema, cascade=True, commit=True)


def test_cm_update_profile_runs_walk_and_locale(adapter, parent_ws):
    """cm update profile should walk schemas/cm/updates/<v>/ then load locale."""
    cm_schema = f"{parent_ws}_cm"
    manifest = load_manifest(os.path.join(DBMODEL, "manifests", "cm.yaml"))
    create_params = BuildParams(
        schema_name=cm_schema, srid="25831",
        plugin_version="4.9.0", profile="empty",
        parent_schema=parent_ws, parent_type="ws",
        sql_root=DBMODEL,
    )
    try:
        r1 = SchemaBuilder(adapter, manifest, create_params).run()
        assert r1.ok, f"cm create: {r1.first_failure()}"
        adapter.commit()

        upgrade_params = BuildParams(
            schema_name=cm_schema, srid="0",
            plugin_version="4.9.0", project_version="4.8.0",
            run_mode="upgrade", profile="update",
            parent_schema=parent_ws, parent_type="ws",
            sql_root=DBMODEL,
        )
        r2 = SchemaBuilder(adapter, manifest, upgrade_params).run()
        assert r2.ok, f"cm update: {r2.first_failure()}"
        adapter.commit()

        phase_ids = [p.phase_id for p in r2.phases]
        assert "load_updates" in phase_ids
        assert "load_locale" in phase_ids
    finally:
        drop_schema(adapter, cm_schema, cascade=True, commit=True)
