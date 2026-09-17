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
    ensure_multilang_tables_ddl,
    multilang_view_functions_ddl,
)


def _sql_root() -> str:
    plugin_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(plugin_dir, "dbmodel")


class TestMultilangSeedSql(unittest.TestCase):

    def test_target_table_mapping(self):
        self.assertEqual(len(MULTILANG_UI_TABLES), 23)
        self.assertIn("value_state", MULTILANG_UI_TABLES)
        self.assertIn("value_state_type", MULTILANG_UI_TABLES)
        self.assertIn("plan_price", MULTILANG_UI_TABLES)
        self.assertIn("sys_style", MULTILANG_UI_TABLES)
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
        self.assertEqual(BASELINE_TO_MULTILANG_TABLE["dbconfig_typevalue"], "config_typevalue")
        self.assertEqual(BASELINE_TO_MULTILANG_TABLE["dbtypevalue"], "typevalue")
        self.assertEqual(
            BASELINE_TO_MULTILANG_TABLE["dbconfig_visit_parameter"],
            "config_visit_parameter",
        )
        self.assertEqual(BASELINE_TO_MULTILANG_TABLE["dbplan_price"], "plan_price")
        self.assertEqual(BASELINE_TO_MULTILANG_TABLE["dbstyle"], "sys_style")
        self.assertEqual(BASELINE_TO_MULTILANG_TABLE["dbconfig_toolbox"], "config_toolbox")
        self.assertEqual(BASELINE_TO_MULTILANG_TABLE["dbconfig_report"], "config_report")
        self.assertEqual(
            BASELINE_TO_MULTILANG_TABLE["dbconfig_report_query"],
            "config_report_query",
        )
        self.assertEqual(BASELINE_TO_MULTILANG_TABLE["dbjson"], "config_json")
        self.assertEqual(
            BASELINE_TO_MULTILANG_TABLE["dbconfig_form_tableview"],
            "config_form_tableview",
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
        self.assertIn("INSERT INTO multilang.config_typevalue", joined)
        self.assertIn("INSERT INTO multilang.typevalue", joined)
        self.assertIn("INSERT INTO multilang.config_visit_parameter", joined)
        self.assertIn("INSERT INTO multilang.plan_price", joined)
        self.assertIn("INSERT INTO multilang.config_toolbox", joined)
        self.assertIn("INSERT INTO multilang.config_report", joined)
        self.assertIn("INSERT INTO multilang.config_report_query", joined)
        self.assertIn("INSERT INTO multilang.config_json", joined)
        self.assertIn("INSERT INTO multilang.config_form_tableview", joined)
        self.assertIn("INSERT INTO multilang.config_csv", joined)
        self.assertIn("INSERT INTO multilang.sys_label", joined)
        self.assertIn("INSERT INTO multilang.value_state", joined)
        self.assertIn("INSERT INTO multilang.value_state_type", joined)
        self.assertIn("INSERT INTO multilang.sys_style", joined)
        self.assertNotIn("INSERT INTO multilang.dbparam_user", joined)
        self.assertNotIn("INSERT INTO multilang.dbjson", joined)
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
        self.assertIn("config_typevalue", tables)
        self.assertIn("typevalue", tables)
        self.assertIn("config_visit_parameter", tables)
        self.assertIn("plan_price", tables)
        self.assertIn("config_toolbox", tables)
        self.assertIn("config_report", tables)
        self.assertIn("config_report_query", tables)
        self.assertIn("config_json", tables)
        json_hints = {
            row.values.get("hint")
            for row in rows
            if row.table == "config_json"
        }
        self.assertTrue(json_hints & {"filterparam", "inputparams"})
        self.assertIn("config_form_tableview", tables)
        self.assertIn("config_csv", tables)
        self.assertIn("value_state", tables)
        self.assertIn("value_state_type", tables)
        self.assertIn("sys_style", tables)


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


    def test_parse_dbconfig_form_tableview_maps_objectname_and_alias(self):
        sql = """
        UPDATE config_form_tableview AS t SET alias = v.alias FROM (
            VALUES
            ('cat_work', 'active', 'Active')
        ) AS v(objectname, columnname, alias)
        WHERE t.objectname = v.objectname AND t.columnname = v.columnname;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows(
            "dbconfig_form_tableview",
            blocks,
            project_type="ws",
        )
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].table, "config_form_tableview")
        self.assertEqual(rows[0].values["source"], "cat_work")
        self.assertEqual(rows[0].values["columnname"], "active")
        self.assertEqual(rows[0].values["al"], "Active")

        inserts = build_insert_sql("config_form_tableview", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.config_form_tableview", inserts[0])


    def test_parse_dbjson_maps_filterparam_to_config_json(self):
        sql = """
        UPDATE config_report AS t SET filterparam = v.text::json FROM (
            VALUES
            (100, '[{"label":"Exploitation:"}]')
        ) AS v(id, text)
        WHERE t.id = v.id;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows("dbjson", blocks, project_type="ws")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].table, "config_json")
        self.assertEqual(rows[0].values["source"], "100")
        self.assertEqual(rows[0].values["hint"], "filterparam")
        self.assertEqual(rows[0].values["context"], "config_report")
        self.assertEqual(rows[0].values["text"], '[{"label":"Exploitation:"}]')

        inserts = build_insert_sql("config_json", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.config_json", inserts[0])
        self.assertIn('"text"', inserts[0])
        self.assertIn("'[{\"label\":\"Exploitation:\"}]'::json", inserts[0])


    def test_parse_dbconfig_report_maps_alias(self):
        sql = """
        UPDATE config_report AS t SET alias = v.alias, descript = v.descript FROM (
            VALUES
            (100, 'Pipe length by Exploitation and Catalog', NULL)
        ) AS v(id, alias, descript)
        WHERE t.id = v.id;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows("dbconfig_report", blocks, project_type="ws")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].table, "config_report")
        self.assertEqual(rows[0].values["source"], "100")
        self.assertEqual(rows[0].values["al"], "Pipe length by Exploitation and Catalog")
        self.assertIsNone(rows[0].values["ds"])

        inserts = build_insert_sql("config_report", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.config_report", inserts[0])


    def test_parse_dbconfig_report_query_maps_query_text(self):
        sql = """
        UPDATE config_report AS t SET query_text = v.text FROM (
            VALUES
            (102, 'SELECT w.exploitation as "Exploitation", w.dma as "Dma" FROM v_om_waterbalance w')
        ) AS v(id, text)
        WHERE t.id = v.id;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows("dbconfig_report_query", blocks, project_type="ws")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].table, "config_report_query")
        self.assertEqual(rows[0].values["source"], "102")
        self.assertEqual(rows[0].values["hint"], "query_text")
        self.assertEqual(rows[0].values["context"], "config_report")
        self.assertIn('as "Exploitation"', rows[0].values["text"])

        inserts = build_insert_sql("config_report_query", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.config_report_query", inserts[0])
        self.assertIn('"text"', inserts[0])
        self.assertNotIn("'::json", inserts[0])


    def test_parse_dbconfig_toolbox_maps_alias(self):
        sql = """
        UPDATE config_toolbox AS t SET alias = v.alias, observ = v.observ FROM (
            VALUES
            (2102, 'Check arcs without node start/end', NULL)
        ) AS v(id, alias, observ)
        WHERE t.id = v.id;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows("dbconfig_toolbox", blocks, project_type="ws")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].table, "config_toolbox")
        self.assertEqual(rows[0].values["source"], "2102")
        self.assertEqual(rows[0].values["al"], "Check arcs without node start/end")
        self.assertIsNone(rows[0].values["ob"])

        inserts = build_insert_sql("config_toolbox", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.config_toolbox", inserts[0])


    def test_parse_dbconfig_typevalue_maps_idval_to_tt(self):
        sql = """
        UPDATE config_typevalue AS t SET idval = v.idval FROM (
            VALUES
            ('13', 'sys_table_context', '["INVENTORY", "NETWORK", "ARC"]'),
            ('vspacer', 'device_typevalue', 'vspacer')
        ) AS v(source, formname, idval)
        WHERE t.id = v.source AND t.typevalue = v.formname;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows(
            "dbconfig_typevalue",
            blocks,
            project_type="ud",
        )
        self.assertEqual(len(rows), 2)
        by_source = {row.values["source"]: row for row in rows}
        self.assertEqual(by_source["13"].table, "config_typevalue")
        self.assertEqual(by_source["13"].values["formname"], "sys_table_context")
        self.assertEqual(by_source["13"].values["tt"], '["INVENTORY", "NETWORK", "ARC"]')
        self.assertEqual(by_source["vspacer"].values["formname"], "device_typevalue")
        self.assertEqual(by_source["vspacer"].values["tt"], "vspacer")

        inserts = build_insert_sql("config_typevalue", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.config_typevalue", inserts[0])
        self.assertNotIn("NULL", inserts[0].split("VALUES", 1)[1])

    def test_load_ud_dbconfig_typevalue_sets_formname_and_source(self):
        rows = [
            row for row in rows_for_project_type(
                load_baseline_rows_for_project_type(_sql_root(), "ud"), "ud",
            )
            if row.table == "config_typevalue"
        ]
        self.assertGreater(len(rows), 0)
        vspacer = next(
            (
                row for row in rows
                if row.values.get("source") == "vspacer"
                and row.values.get("tt") == "vspacer"
            ),
            None,
        )
        self.assertIsNotNone(vspacer)
        self.assertIsNotNone(vspacer.values.get("formname"))
        self.assertTrue(all(
            row.values.get("formname") and row.values.get("source")
            for row in rows
        ))



    def test_parse_dbplan_price_maps_descript_text_and_price(self):
        sql = """
        UPDATE plan_price AS t SET descript = v.descript, text = v.text,
            price = REPLACE(v.price, ',', '.')::numeric FROM (
            VALUES
            ('A_FC110_PN10', 'Polyethylene tube', 'Long descript', '20.0900'),
            ('N_ENDLINE', 'Cavity plug', 'Cavity plug', NULL)
        ) AS v(id, descript, text, price)
        WHERE t.id = v.id;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows("dbplan_price", blocks, project_type="ws")
        self.assertEqual(len(rows), 2)
        by_source = {row.values["source"]: row for row in rows}

        tube = by_source["A_FC110_PN10"]
        self.assertEqual(tube.table, "plan_price")
        self.assertEqual(tube.values["context"], "plan_price")
        self.assertEqual(tube.values["ds"], "Polyethylene tube")
        self.assertEqual(tube.values["tx"], "Long descript")
        self.assertEqual(tube.values["pr"], "20.0900")

        plug = by_source["N_ENDLINE"]
        self.assertEqual(plug.values["ds"], "Cavity plug")
        self.assertEqual(plug.values["tx"], "Cavity plug")
        self.assertIsNone(plug.values["pr"])

        inserts = build_insert_sql("plan_price", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.plan_price", inserts[0])
        self.assertIn(" ds ", inserts[0])
        self.assertIn(" tx ", inserts[0])
        self.assertIn(" pr ", inserts[0])


    def test_parse_dbplan_price_skips_rows_missing_source(self):
        sql = """
        UPDATE plan_price AS t SET descript = v.descript FROM (
            VALUES
            (NULL, 'Missing id'),
            ('N_ENDLINE', 'Cavity plug')
        ) AS v(id, descript)
        WHERE t.id = v.id;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows("dbplan_price", blocks, project_type="ws")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].values["source"], "N_ENDLINE")

    def test_parse_dbstyle_maps_stylevalue_blob(self):
        sql = """
        UPDATE sys_style AS t
        SET stylevalue = v.stylevalue
        FROM (
            VALUES
            ('101', 've_node', '<qgis><rule label="JUNCTION"/></qgis>'),
            ('101', 've_arc', '<qgis><rule label="PIPE"/></qgis>')
        ) AS v(styleconfig_id, layername, stylevalue)
        WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows("dbstyle", blocks, project_type="ws")
        self.assertEqual(len(rows), 2)
        by_layer = {row.values["layername"]: row for row in rows}

        first = by_layer["ve_node"]
        self.assertEqual(first.table, "sys_style")
        self.assertEqual(first.values["context"], "sys_style")
        self.assertEqual(first.values["source"], "101")
        self.assertEqual(first.values["tx"], '<qgis><rule label="JUNCTION"/></qgis>')
        self.assertNotIn("hint", first.values)

        second = by_layer["ve_arc"]
        self.assertEqual(second.values["tx"], '<qgis><rule label="PIPE"/></qgis>')

        inserts = build_insert_sql("sys_style", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.sys_style", inserts[0])
        self.assertIn('"source"', inserts[0])
        self.assertIn(" tx)", inserts[0])
        self.assertIn("layername", inserts[0])
        self.assertIn("'ve_node'", inserts[0])
        self.assertIn("JUNCTION", inserts[0])

    def test_parse_dbstyle_skips_rows_missing_identity(self):
        sql = """
        UPDATE sys_style AS t
        SET stylevalue = v.stylevalue
        FROM (
            VALUES
            (NULL, 've_arc', '<qgis/>'),
            ('101', NULL, '<qgis/>'),
            ('101', 've_arc', '<qgis><rule label="PIPE"/></qgis>')
        ) AS v(styleconfig_id, layername, stylevalue)
        WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows("dbstyle", blocks, project_type="ws")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].values["source"], "101")
        self.assertEqual(rows[0].values["layername"], "ve_arc")
        self.assertIn("<qgis>", rows[0].values["tx"])

    def test_parse_dbstyle_real_es_es_baseline(self):
        path = os.path.join(
            _sql_root(), "schemas", "main", "ws", "final_pass", "i18n", "es_ES",
            "dbstyle.sql",
        )
        if not os.path.isfile(path):
            self.skipTest("es_ES dbstyle.sql is not bundled")
        with open(path, encoding="utf-8") as handle:
            sql = handle.read()
        blocks = parse_update_blocks(sql)
        self.assertGreaterEqual(len(blocks), 1)
        rows = blocks_to_multilang_rows("dbstyle", blocks, project_type="ws")
        self.assertGreater(len(rows), 0)
        first = rows[0]
        self.assertEqual(first.table, "sys_style")
        self.assertTrue(first.values.get("source"))
        self.assertTrue(first.values.get("layername"))
        self.assertIn("<qgis", first.values.get("tx") or "")

    def test_load_ws_english_value_state_and_sys_style(self):
        rows = rows_for_project_type(
            load_baseline_rows_for_project_type(_sql_root(), "ws"), "ws",
        )
        states = {
            row.values.get("source"): row.values.get("na")
            for row in rows if row.table == "value_state"
        }
        self.assertEqual(states.get("1"), "OPERATIVE")
        self.assertEqual(states.get("0"), "OBSOLETE")
        self.assertEqual(states.get("2"), "PLANIFIED")

        state_types = {
            row.values.get("source"): row.values.get("na")
            for row in rows if row.table == "value_state_type"
        }
        self.assertEqual(state_types.get("2"), "OPERATIVE")
        self.assertEqual(state_types.get("1"), "OBSOLETE")

        styles = [row for row in rows if row.table == "sys_style"]
        self.assertGreater(len(styles), 0)
        first = styles[0]
        self.assertTrue(first.values.get("source"))
        self.assertTrue(first.values.get("layername"))
        self.assertIn("<qgis", first.values.get("tx") or "")
        self.assertIn("Proposed to close", first.values.get("tx") or "")

    def test_parse_dbconfig_visit_parameter_maps_descript_to_ds(self):
        sql = """
        UPDATE config_visit_parameter AS t SET descript = v.descript FROM (
            VALUES
            ('clean_node', 'Clean of node')
        ) AS v(id, descript)
        WHERE t.id = v.id;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows(
            "dbconfig_visit_parameter",
            blocks,
            project_type="ws",
        )
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].table, "config_visit_parameter")
        self.assertEqual(rows[0].values["context"], "config_visit_parameter")
        self.assertEqual(rows[0].values["source"], "clean_node")
        self.assertEqual(rows[0].values["ds"], "Clean of node")

        inserts = build_insert_sql("config_visit_parameter", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.config_visit_parameter", inserts[0])
        self.assertIn(" ds ", inserts[0])


    def test_parse_dbtypevalue_keeps_context_from_update_header(self):
        sql = """
        UPDATE edit_typevalue AS t SET idval = v.idval, descript = v.descript FROM (
            VALUES
            ('0', 'value_verified', 'TO REVIEW', NULL)
        ) AS v(id, typevalue, idval, descript)
        WHERE t.id = v.id AND t.typevalue = v.typevalue;

        UPDATE om_typevalue AS t SET idval = v.idval, descript = v.descript FROM (
            VALUES
            ('1', 'visit_status', 'Planned', NULL)
        ) AS v(id, typevalue, idval, descript)
        WHERE t.id = v.id AND t.typevalue = v.typevalue;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows("dbtypevalue", blocks, project_type="ws")
        self.assertEqual(len(rows), 2)
        by_context = {row.values["context"]: row for row in rows}

        self.assertEqual(by_context["edit_typevalue"].table, "typevalue")
        self.assertEqual(by_context["edit_typevalue"].values["typevalue"], "value_verified")
        self.assertEqual(by_context["edit_typevalue"].values["source"], "0")
        self.assertEqual(by_context["edit_typevalue"].values["vl"], "TO REVIEW")

        self.assertEqual(by_context["om_typevalue"].values["typevalue"], "visit_status")
        self.assertEqual(by_context["om_typevalue"].values["source"], "1")
        self.assertEqual(by_context["om_typevalue"].values["vl"], "Planned")

        inserts = build_insert_sql("typevalue", rows)
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.typevalue", inserts[0])


    def test_parse_dbtypevalue_skips_rows_missing_typevalue_or_source(self):
        sql = """
        UPDATE edit_typevalue AS t SET idval = v.idval FROM (
            VALUES
            ('0', NULL, 'TO REVIEW'),
            (NULL, 'value_verified', 'TO REVIEW'),
            ('1', 'value_verified', 'VERIFIED')
        ) AS v(id, typevalue, idval)
        WHERE t.id = v.id AND t.typevalue = v.typevalue;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows("dbtypevalue", blocks, project_type="ws")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].values["source"], "1")
        self.assertEqual(rows[0].values["typevalue"], "value_verified")


    def test_load_cm_baseline_rows_includes_typevalue_only(self):
        template = load_baseline_rows_for_project_type(_sql_root(), "cm")
        rows = rows_for_project_type(template, "cm")
        tables = {row.table for row in rows}
        self.assertIn("typevalue", tables)
        self.assertNotIn("config_visit_parameter", tables)
        contexts = {
            row.values.get("context")
            for row in rows
            if row.table == "typevalue"
        }
        self.assertEqual(contexts, {"sys_typevalue"})



    def test_parse_dbbasic_tables_routes_by_update_context(self):
        sql = """
        UPDATE config_param_system AS t SET value = v.value FROM (
            VALUES
            ('admin_currency', '{"id":"EUR", "descript":"EURO"}')
        ) AS v(parameter, value)
        WHERE t.parameter = v.parameter;

        UPDATE value_state AS t SET name = v.name, observ = v.observ FROM (
            VALUES
            (1, 'OPERATIVE', NULL)
        ) AS v(id, name, observ)
        WHERE t.id = v.id;

        UPDATE value_state_type AS t SET name = v.name FROM (
            VALUES
            (2, 'OPERATIVE')
        ) AS v(id, name)
        WHERE t.id = v.id;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows("dbbasic_tables", blocks, project_type="ws")
        by_table = {row.table: row for row in rows}
        self.assertEqual(set(by_table), {"config_param_system", "value_state", "value_state_type"})

        currency = by_table["config_param_system"]
        self.assertEqual(currency.values["source"], "admin_currency")
        self.assertEqual(currency.values["vl"], '{"id":"EUR", "descript":"EURO"}')
        self.assertEqual(currency.values["context"], "config_param_system")

        state = by_table["value_state"]
        self.assertEqual(state.values["source"], "1")
        self.assertEqual(state.values["na"], "OPERATIVE")
        self.assertIsNone(state.values["ob"])

        state_type = by_table["value_state_type"]
        self.assertEqual(state_type.values["source"], "2")
        self.assertEqual(state_type.values["na"], "OPERATIVE")

        inserts = build_insert_sql("value_state", [state])
        self.assertEqual(len(inserts), 1)
        self.assertIn("INSERT INTO multilang.value_state", inserts[0])


    def test_parse_dbbasic_tables_skips_unknown_contexts(self):
        sql = """
        UPDATE value_status AS t SET idval = v.idval FROM (
            VALUES
            ('CANCELED', 'CANCELED')
        ) AS v(id, idval)
        WHERE t.id = v.id;
        """
        blocks = parse_update_blocks(sql)
        rows = blocks_to_multilang_rows("dbbasic_tables", blocks, project_type="am")
        self.assertEqual(rows, [])


    def test_load_ws_admin_currency_keeps_label_and_value(self):
        rows = [
            row for row in rows_for_project_type(
                load_baseline_rows_for_project_type(_sql_root(), "ws"), "ws",
            )
            if row.table == "config_param_system"
            and row.values.get("source") == "admin_currency"
        ]
        self.assertGreaterEqual(len(rows), 1)
        self.assertTrue(any(row.values.get("lb") == "System currency:" for row in rows))
        inserts = build_insert_sql("config_param_system", rows)
        self.assertEqual(len(inserts), 1)
        self.assertEqual(inserts[0].count("'admin_currency'"), 1)
        self.assertIn(" lb ", inserts[0])
        self.assertIn("System currency:", inserts[0])

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
        self.assertIn("COALESCE(ml.tt, t.idval)", ddl)
        self.assertIn("COALESCE(ml.vl, t.idval)", ddl)
        self.assertIn("config_typevalue", ddl)
        self.assertIn("config_visit_parameter", ddl)
        self.assertIn("edit_typevalue", ddl)
        self.assertIn("value_state", ddl)
        self.assertIn("value_state_type", ddl)
        self.assertIn("plan_price", ddl)
        self.assertIn("COALESCE(ml.vl, t.value)", ddl)
        self.assertIn("COALESCE(ml.na, t.name)", ddl)
        self.assertIn("COALESCE(ml.tx, t.\"text\")", ddl)
        self.assertIn("replace(ml.pr, '','', ''.'')::numeric", ddl)
        self.assertIn("v_price_compost", ddl)
        self.assertIn("COALESCE(ml.ds, t.descript)", ddl)
        self.assertIn("CREATE OR REPLACE VIEW", ddl)
        self.assertIn("sys_style", ddl)
        self.assertIn("COALESCE(ml.tx, t.stylevalue)", ddl)
        self.assertIn("COALESCE(mlq.text, t.query_text)", ddl)
        self.assertIn("config_report_query", ddl)
        self.assertNotIn("gw_fct_apply_style_labels", ddl)

    def test_ensure_multilang_tables_ddl_creates_config_typevalue(self):
        ddl = ensure_multilang_tables_ddl()
        self.assertIn("CREATE TABLE IF NOT EXISTS multilang.config_typevalue", ddl)
        self.assertIn("formname text NOT NULL", ddl)
        self.assertIn("CREATE TABLE IF NOT EXISTS multilang.typevalue", ddl)
        self.assertIn("CREATE TABLE IF NOT EXISTS multilang.config_visit_parameter", ddl)
        self.assertIn("ADD COLUMN IF NOT EXISTS vl text NULL", ddl)
        self.assertIn("CREATE TABLE IF NOT EXISTS multilang.value_state", ddl)
        self.assertIn("CREATE TABLE IF NOT EXISTS multilang.value_state_type", ddl)
        self.assertIn("CREATE TABLE IF NOT EXISTS multilang.plan_price", ddl)
        self.assertIn("CREATE TABLE IF NOT EXISTS multilang.sys_style", ddl)
        self.assertIn("CREATE TABLE IF NOT EXISTS multilang.config_report_query", ddl)
        self.assertIn("tx text NULL", ddl)
        self.assertIn("DROP TABLE multilang.sys_style", ddl)
        self.assertIn("typevalue text NOT NULL", ddl)


if __name__ == "__main__":
    unittest.main()
