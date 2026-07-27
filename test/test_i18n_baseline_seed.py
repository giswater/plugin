"""Tests for i18n baseline SQL parsing and multilang row conversion."""

from __future__ import annotations

import os
import unittest

from core.admin.i18n_baseline_seed import (
    BASELINE_TO_MULTILANG_TABLE,
    MULTILANG_UI_TABLES,
    MultilangRow,
    _TABLE_CONFLICT_KEYS,
    _dedupe_rows_by_conflict_key,
    baseline_needs_reseed,
    blocks_to_multilang_rows,
    build_insert_sql,
    compute_baseline_fingerprint,
    delete_schema_seed_sql,
    load_baseline_rows,
    parse_sql_value_tuple,
    parse_stored_seeded_schemas,
    parse_update_blocks,
    seed_sql_for_schema,
    seeded_schemas_out_of_sync,
    split_value_tuples,
    translatable_schema_names_from_inventory,
)


class TestI18nBaselineSeed(unittest.TestCase):

    def test_target_table_mapping(self):
        self.assertEqual(len(MULTILANG_UI_TABLES), 9)
        self.assertEqual(
            BASELINE_TO_MULTILANG_TABLE["dbparam_user"],
            "sys_param_user",
        )
        self.assertEqual(
            BASELINE_TO_MULTILANG_TABLE["dbconfig_form_fields_feat"],
            "config_form_fields",
        )
        self.assertEqual(
            BASELINE_TO_MULTILANG_TABLE["dbconfig_form_fields_json"],
            "config_form_fields_json",
        )
        self.assertEqual(
            BASELINE_TO_MULTILANG_TABLE["dbfprocess"],
            "sys_fprocess",
        )

    def test_parse_sql_value_tuple_basic(self):
        values = parse_sql_value_tuple("(385, 'Import inp', NULL)")
        self.assertEqual(values, [385, "Import inp", None])

    def test_parse_sql_value_tuple_escaped_quote(self):
        values = parse_sql_value_tuple("('it''s', 'ok')")
        self.assertEqual(values, ["it's", "ok"])

    def test_split_value_tuples(self):
        blob = "(1, 'a'),\n(2, 'b, c')"
        tuples = split_value_tuples(blob)
        self.assertEqual(len(tuples), 2)
        self.assertEqual(parse_sql_value_tuple(tuples[1]), [2, "b, c"])

    def test_parse_dbparam_user_maps_descript_to_tt(self):
        sql = """
        UPDATE sys_param_user AS t SET label = v.label, descript = v.descript FROM (
            VALUES
            ('edit_state_vdefault', 'State:', 'Value of state parameter')
        ) AS v(id, label, descript)
        WHERE t.id = v.id;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows(
            "dbparam_user",
            blocks,
            schema_name="ws_0630",
        )
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].table, "sys_param_user")
        self.assertEqual(rows[0].values["source"], "edit_state_vdefault")
        self.assertEqual(rows[0].values["lb"], "State:")
        self.assertEqual(rows[0].values["tt"], "Value of state parameter")
        self.assertNotIn("ds", rows[0].values)

        inserts = build_insert_sql("sys_param_user", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.sys_param_user", inserts[0])
        self.assertIn(" tt ", inserts[0])
        self.assertNotIn(" ds ", inserts[0])

    def test_parse_dbfprocess_quotes_in_column(self):
        sql = """
        UPDATE sys_fprocess AS t SET except_msg = v.except_msg, info_msg = v.info_msg,
            fprocess_name = v.fprocess_name FROM (
            VALUES
            (107, 'except text', 'info text', 'Process name')
        ) AS v(fid, except_msg, info_msg, fprocess_name)
        WHERE t.fid = v.fid;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows(
            "dbfprocess",
            blocks,
            schema_name="ws_0630",
        )
        self.assertEqual(rows[0].table, "sys_fprocess")
        self.assertEqual(rows[0].values["in"], "info text")

        inserts = build_insert_sql("sys_fprocess", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn('"in"', inserts[0])
        self.assertIn('EXCLUDED."in"', inserts[0])

    def test_build_insert_sql_dedupes_sys_message_conflict_keys(self):
        duplicate_key = {
            "schema_name": "ws_0630",
            "context": "sys_message",
            "source": "42",
            "lang": "en_us",
        }
        rows = [
            MultilangRow(
                table="sys_message",
                values={**duplicate_key, "ms": "first"},
            ),
            MultilangRow(
                table="sys_message",
                values={**duplicate_key, "ms": "second"},
            ),
        ]
        inserts = build_insert_sql("sys_message", rows)
        self.assertEqual(len(inserts), 1)
        self.assertEqual(inserts[0].count("42"), 1)
        self.assertIn("'second'", inserts[0])
        self.assertNotIn("'first'", inserts[0])

    def test_seed_sql_for_schema_uses_ui_tables_only(self):
        plugin_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        sql_root = os.path.join(plugin_dir, "dbmodel")

        statements = seed_sql_for_schema(sql_root, "ws_0630", project_type="ws")
        self.assertGreater(len(statements), 0)
        joined = "\n".join(statements)
        self.assertIn("INSERT INTO multilang.config_form_fields", joined)
        self.assertNotIn("INSERT INTO multilang.dbparam_user", joined)
        self.assertNotIn("INSERT INTO multilang.dbjson", joined)
        for statement in statements:
            target = statement.split("INSERT INTO multilang.", 1)[1].split(" ", 1)[0]
            self.assertIn(target, MULTILANG_UI_TABLES)

    def test_parse_dbconfig_form_fields_feat_keeps_pattern_formname(self):
        sql = """
        UPDATE config_form_fields AS t SET label = v.label, tooltip = v.tooltip FROM (
            VALUES
            ('diameter', '%_arc%', 'form_feature', 'tab_data', 'Diameter:', 'Pipe diameter')
        ) AS v(columnname, formname, formtype, tabname, label, tooltip)
        WHERE t.columnname = v.columnname;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows(
            "dbconfig_form_fields_feat",
            blocks,
            schema_name="ws_demo",
        )
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].table, "config_form_fields")
        self.assertEqual(rows[0].values["source"], "diameter")
        self.assertEqual(rows[0].values["formname"], "%_arc%")
        self.assertEqual(rows[0].values["formtype"], "form_feature")
        self.assertEqual(rows[0].values["tabname"], "tab_data")
        self.assertEqual(rows[0].values["lb"], "Diameter:")
        self.assertEqual(rows[0].values["tt"], "Pipe diameter")

    def test_load_baseline_rows_includes_feat_form_field_patterns(self):
        plugin_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        sql_root = os.path.join(plugin_dir, "dbmodel")

        rows = load_baseline_rows(sql_root, schema_name="ws_demo", project_type="ws")
        feat_rows = [
            row for row in rows
            if row.table == "config_form_fields"
            and row.values.get("formname") == "%_arc%"
            and row.values.get("formtype") == "form_feature"
            and row.values.get("tabname") == "tab_data"
        ]
        self.assertTrue(feat_rows)

    def test_parse_dbconfig_form_fields_json_maps_to_json_table(self):
        sql = """
        UPDATE config_form_fields AS t SET widgetcontrols = v.text::json FROM (
            VALUES
            ('btn_accept', 'arc', 'form_feature', 'tab_none', '{"text":"Accept"}')
        ) AS v(columnname, formname, formtype, tabname, text)
        WHERE t.columnname = v.columnname;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows(
            "dbconfig_form_fields_json",
            blocks,
            schema_name="ws_demo",
        )
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].table, "config_form_fields_json")
        self.assertEqual(rows[0].values["source"], "btn_accept")
        self.assertEqual(rows[0].values["formname"], "arc")
        self.assertEqual(rows[0].values["hint"], "widgetcontrols")
        self.assertEqual(rows[0].values["text"], '{"text":"Accept"}')

        inserts = build_insert_sql("config_form_fields_json", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.config_form_fields_json", inserts[0])
        self.assertIn('"text"', inserts[0])
        self.assertIn("'{\"text\":\"Accept\"}'::json", inserts[0])

    def test_load_baseline_rows_includes_form_field_json(self):
        plugin_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        sql_root = os.path.join(plugin_dir, "dbmodel")

        rows = load_baseline_rows(sql_root, schema_name="ws_demo", project_type="ws")
        json_rows = [
            row for row in rows
            if row.table == "config_form_fields_json"
            and row.values.get("source") == "btn_accept"
            and row.values.get("formname") == "arc"
            and row.values.get("hint") == "widgetcontrols"
        ]
        self.assertTrue(json_rows)

    def test_seeded_schemas_out_of_sync(self):
        self.assertFalse(seeded_schemas_out_of_sync({"ws_a"}, {"ws_a"}))
        self.assertTrue(seeded_schemas_out_of_sync({"ws_a", "ud_b"}, {"ws_a"}))

    def test_parse_stored_seeded_schemas(self):
        payload = {"seeded_schemas": ["ws_0630", "ud_demo"]}
        self.assertEqual(parse_stored_seeded_schemas(payload), {"ws_0630", "ud_demo"})

    def test_translatable_schema_names_from_inventory(self):
        plugin_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        sql_root = os.path.join(plugin_dir, "dbmodel")
        inventory = [
            {"schema": "ws_0630", "kind": "WS"},
            {"schema": "cm", "kind": "CM"},
            {"schema": "multilang", "kind": "MULTILANG"},
            {"schema": "audit", "kind": "AUDIT"},
        ]
        satellite_schemas = frozenset({"multilang", "utils", "cibs", "audit"})
        names = translatable_schema_names_from_inventory(
            inventory,
            sql_root,
            satellite_schemas=satellite_schemas,
        )
        self.assertEqual(names, {"ws_0630", "cm"})

    def test_delete_schema_seed_sql(self):
        statements = delete_schema_seed_sql(["ws_old"])
        self.assertEqual(len(statements), len(MULTILANG_UI_TABLES))
        self.assertTrue(all("DELETE FROM multilang." in sql for sql in statements))
        self.assertTrue(all("schema_name = 'ws_old'" in sql for sql in statements))
        self.assertTrue(any("DELETE FROM multilang.config_form_fields" in sql for sql in statements))

    def test_seed_sql_uses_project_type_baseline(self):
        plugin_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        sql_root = os.path.join(plugin_dir, "dbmodel")

        ws_rows = load_baseline_rows(sql_root, schema_name="ws_demo", project_type="ws")
        ud_rows = load_baseline_rows(sql_root, schema_name="ws_demo", project_type="ud")
        self.assertGreater(len(ws_rows), 0)
        self.assertGreater(len(ud_rows), 0)

        ws_param = {row.values["source"] for row in ws_rows if row.table == "sys_param_user"}
        ud_param = {row.values["source"] for row in ud_rows if row.table == "sys_param_user"}
        self.assertNotEqual(ws_param, ud_param)

        self.assertEqual(seed_sql_for_schema(sql_root, "audit_demo", project_type="audit"), [])
        self.assertGreater(len(seed_sql_for_schema(sql_root, "ws_demo", project_type="ws")), 0)

    def test_out_of_scope_baseline_file_is_ignored(self):
        sql = """
        UPDATE config_csv AS t SET alias = v.alias, descript = v.descript FROM (
            VALUES
            (385, 'Import inp timeseries', 'Function to assist')
        ) AS v(fid, alias, descript)
        WHERE t.fid = v.fid;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows(
            "dbconfig_csv",
            blocks,
            schema_name="ud_demo",
        )
        self.assertEqual(rows, [])

    def test_baseline_fingerprint_stable(self):
        plugin_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        sql_root = os.path.join(plugin_dir, "dbmodel")
        fp1 = compute_baseline_fingerprint(sql_root)
        fp2 = compute_baseline_fingerprint(sql_root)
        self.assertEqual(fp1, fp2)
        self.assertFalse(baseline_needs_reseed(sql_root, fp1))
        self.assertTrue(baseline_needs_reseed(sql_root, None))
        self.assertTrue(baseline_needs_reseed(sql_root, "stale-fingerprint"))


if __name__ == "__main__":
    unittest.main()
