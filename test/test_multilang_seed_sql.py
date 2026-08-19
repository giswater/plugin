"""Tests for multilang baseline SQL parsing and row conversion."""

from __future__ import annotations

import os
import unittest

from core.admin.i18n.multilang_seed_sql import (
    BASELINE_TO_MULTILANG_TABLE,
    MULTILANG_UI_TABLES,
    MultilangRow,
    baseline_needs_reseed,
    blocks_to_multilang_rows,
    build_insert_sql,
    compute_baseline_fingerprint,
    delete_project_type_seed_sql,
    load_baseline_rows_for_project_type,
    parse_sql_value_tuple,
    parse_stored_seeded_project_types,
    parse_update_blocks,
    rows_for_project_type,
    seed_sql_for_project_types,
    seeded_project_types_out_of_sync,
    split_value_tuples,
    translatable_project_types_with_baseline,
    multilang_view_functions_ddl,
)


def _sql_root() -> str:
    plugin_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(plugin_dir, "dbmodel")


class TestMultilangSeedSql(unittest.TestCase):

    def test_target_table_mapping(self):
        self.assertEqual(len(MULTILANG_UI_TABLES), 11)
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
        self.assertEqual(BASELINE_TO_MULTILANG_TABLE["dbconfig_csv"], "config_csv")
        self.assertEqual(BASELINE_TO_MULTILANG_TABLE["dblabel"], "sys_label")

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
            project_type="ws",
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
            project_type="ws",
        )
        self.assertEqual(rows[0].table, "sys_fprocess")
        self.assertEqual(rows[0].values["in"], "info text")

        inserts = build_insert_sql("sys_fprocess", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn('"in"', inserts[0])
        self.assertIn('EXCLUDED."in"', inserts[0])

    def test_build_insert_sql_dedupes_sys_message_conflict_keys(self):
        duplicate_key = {
            "project_type": "ws",
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

    def test_seed_sql_for_project_types_uses_ui_tables_only(self):
        results = seed_sql_for_project_types(_sql_root(), ["ws"])
        self.assertEqual(len(results), 1)
        project_type, statements = results[0]
        self.assertEqual(project_type, "ws")
        self.assertGreater(len(statements), 0)
        joined = "\n".join(statements)
        self.assertIn("INSERT INTO multilang.config_form_fields", joined)
        self.assertIn("INSERT INTO multilang.config_csv", joined)
        self.assertIn("INSERT INTO multilang.sys_label", joined)
        self.assertNotIn("INSERT INTO multilang.dbparam_user", joined)
        self.assertNotIn("INSERT INTO multilang.dbjson", joined)
        for statement in statements:
            target = statement.split("INSERT INTO multilang.", 1)[1].split(" ", 1)[0]
            self.assertIn(target, MULTILANG_UI_TABLES)

    def test_parse_dbconfig_form_fields_feat_keeps_pattern_formname(self):
        sql = """
        UPDATE config_form_fields AS t SET label = v.label, tooltip = v.tooltip,
            placeholder = v.placeholder FROM (
            VALUES
            ('diameter', '%_arc%', 'form_feature', 'tab_data', 'Diameter:', 'Pipe diameter', 'e.g. 110')
        ) AS v(columnname, formname, formtype, tabname, label, tooltip, placeholder)
        WHERE t.columnname = v.columnname;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows(
            "dbconfig_form_fields_feat",
            blocks,
            project_type="ws",
        )
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].table, "config_form_fields")
        self.assertEqual(rows[0].values["source"], "diameter")
        self.assertEqual(rows[0].values["formname"], "%_arc%")
        self.assertEqual(rows[0].values["formtype"], "form_feature")
        self.assertEqual(rows[0].values["tabname"], "tab_data")
        self.assertEqual(rows[0].values["lb"], "Diameter:")
        self.assertEqual(rows[0].values["tt"], "Pipe diameter")
        self.assertEqual(rows[0].values["pl"], "e.g. 110")

        inserts = build_insert_sql("config_form_fields", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.config_form_fields", inserts[0])
        self.assertIn(" pl ", inserts[0])
        self.assertIn("'e.g. 110'", inserts[0])

    def test_parse_dbconfig_form_fields_maps_placeholder_to_pl(self):
        sql = """
        UPDATE config_form_fields AS t SET label = v.label, tooltip = v.tooltip,
            placeholder = v.placeholder FROM (
            VALUES
            ('resultId', 'generic', 'go2epa', 'tab_data', 'Result Name:', 'Name for the EPA result', 'Enter result name...')
        ) AS v(columnname, formname, formtype, tabname, label, tooltip, placeholder)
        WHERE t.columnname = v.columnname;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows(
            "dbconfig_form_fields",
            blocks,
            project_type="ws",
        )
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].table, "config_form_fields")
        self.assertEqual(rows[0].values["source"], "resultId")
        self.assertEqual(rows[0].values["lb"], "Result Name:")
        self.assertEqual(rows[0].values["tt"], "Name for the EPA result")
        self.assertEqual(rows[0].values["pl"], "Enter result name...")

        inserts = build_insert_sql("config_form_fields", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn(" pl ", inserts[0])
        self.assertIn("EXCLUDED.pl", inserts[0])
        self.assertIn("'Enter result name...'", inserts[0])

    def test_load_baseline_rows_includes_feat_form_field_patterns(self):
        template = load_baseline_rows_for_project_type(_sql_root(), "ws")
        rows = rows_for_project_type(template, "ws")
        feat_rows = [
            row for row in rows
            if row.table == "config_form_fields"
            and row.values.get("formname") == "%_arc%"
            and row.values.get("formtype") == "form_feature"
            and row.values.get("tabname") == "tab_data"
        ]
        self.assertTrue(feat_rows)
        self.assertTrue(any("pl" in row.values for row in feat_rows))

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
            project_type="ws",
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
        template = load_baseline_rows_for_project_type(_sql_root(), "ws")
        rows = rows_for_project_type(template, "ws")
        json_rows = [
            row for row in rows
            if row.table == "config_form_fields_json"
            and row.values.get("source") == "btn_accept"
            and row.values.get("formname") == "arc"
            and row.values.get("hint") == "widgetcontrols"
        ]
        self.assertTrue(json_rows)

    def test_seeded_project_types_out_of_sync(self):
        self.assertFalse(seeded_project_types_out_of_sync({"ws"}, {"ws"}))
        self.assertTrue(seeded_project_types_out_of_sync({"ws", "ud"}, {"ws"}))

    def test_parse_stored_seeded_project_types(self):
        payload = {"seeded_project_types": ["ws", "ud"]}
        self.assertEqual(parse_stored_seeded_project_types(payload), {"ws", "ud"})
        # Backward-compatible key.
        legacy = {"seeded_schemas": ["ws_0630", "ud_demo"]}
        self.assertEqual(
            parse_stored_seeded_project_types(legacy),
            {"ws_0630", "ud_demo"},
        )

    def test_translatable_project_types_with_baseline(self):
        names = translatable_project_types_with_baseline(_sql_root())
        self.assertIn("ws", names)
        self.assertIn("ud", names)
        self.assertNotIn("audit", names)

    def test_delete_project_type_seed_sql(self):
        statements = delete_project_type_seed_sql(["ws"])
        self.assertEqual(len(statements), len(MULTILANG_UI_TABLES))
        self.assertTrue(all("DELETE FROM multilang." in sql for sql in statements))
        self.assertTrue(all("project_type = 'ws'" in sql for sql in statements))
        self.assertTrue(any("DELETE FROM multilang.config_form_fields" in sql for sql in statements))

    def test_seed_sql_uses_project_type_baseline(self):
        sql_root = _sql_root()
        ws_rows = rows_for_project_type(
            load_baseline_rows_for_project_type(sql_root, "ws"), "ws",
        )
        ud_rows = rows_for_project_type(
            load_baseline_rows_for_project_type(sql_root, "ud"), "ud",
        )
        self.assertGreater(len(ws_rows), 0)
        self.assertGreater(len(ud_rows), 0)

        ws_param = {row.values["source"] for row in ws_rows if row.table == "sys_param_user"}
        ud_param = {row.values["source"] for row in ud_rows if row.table == "sys_param_user"}
        self.assertNotEqual(ws_param, ud_param)

        audit_results = seed_sql_for_project_types(sql_root, ["audit"])
        self.assertEqual(audit_results[0][1], [])
        ws_results = seed_sql_for_project_types(sql_root, ["ws"])
        self.assertGreater(len(ws_results[0][1]), 0)

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
            project_type="ud",
        )
        self.assertEqual(rows, [])

    def test_parse_dblabel_maps_idval_to_vl(self):
        sql = """
        UPDATE sys_label AS t SET idval = v.idval FROM (
            VALUES
            (1001, 'INFO')
        ) AS v(id, idval)
        WHERE t.id = v.id;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows("dblabel", blocks, project_type="ws")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].table, "sys_label")
        self.assertEqual(rows[0].values["source"], "1001")
        self.assertEqual(rows[0].values["vl"], "INFO")
        self.assertEqual(rows[0].values["context"], "sys_label")

        inserts = build_insert_sql("sys_label", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.sys_label", inserts[0])
        self.assertIn(" vl ", inserts[0])


    def test_load_baseline_rows_includes_new_ui_tables(self):
        template = load_baseline_rows_for_project_type(_sql_root(), "ws")
        rows = rows_for_project_type(template, "ws")
        tables = {row.table for row in rows}
        self.assertIn("sys_label", tables)
        self.assertIn("config_csv", tables)


    def test_parse_dbconfig_csv_maps_alias_and_descript(self):
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
            project_type="ud",
        )
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].table, "config_csv")
        self.assertEqual(rows[0].values["source"], "385")
        self.assertEqual(rows[0].values["al"], "Import inp timeseries")
        self.assertEqual(rows[0].values["ds"], "Function to assist")

        inserts = build_insert_sql("config_csv", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.config_csv", inserts[0])


    def test_baseline_fingerprint_stable(self):
        sql_root = _sql_root()
        fp1 = compute_baseline_fingerprint(sql_root)
        fp2 = compute_baseline_fingerprint(sql_root)
        self.assertEqual(fp1, fp2)
        self.assertFalse(baseline_needs_reseed(sql_root, fp1))
        self.assertTrue(baseline_needs_reseed(sql_root, None))
        self.assertTrue(baseline_needs_reseed(sql_root, "stale-fingerprint"))


    def test_view_functions_ddl_drops_before_create(self):
        ddl = multilang_view_functions_ddl()
        self.assertIn("DROP VIEW IF EXISTS", ddl)
        self.assertIn("CREATE VIEW", ddl)
        self.assertIn("gw_fct_admin_manage_multilang_views", ddl)
        self.assertIn("COALESCE(ml.al, t.alias)", ddl)
        self.assertNotIn("CREATE OR REPLACE VIEW", ddl)


if __name__ == "__main__":
    unittest.main()
