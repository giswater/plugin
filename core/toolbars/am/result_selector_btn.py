"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

from ....libs import tools_db, tools_qgis, tools_qt, lib_vars
from ...utils import tools_gw
from ..dialog import GwAction

from .... import global_vars

from ...ui.ui_manager import GwResultSelectorUi


def set_am_selector_result(result_id, selector="main"):
    """Activate one result without clearing other asset_type selections.

    selector_result_* PK is (cur_user, result_id), so ARC and NODE can both be
    active. Only replace the previous selection of the same cat_result.asset_type.
    """
    if result_id in (None, ""):
        return
    result_id = int(result_id)
    table = "selector_result_main" if selector == "main" else "selector_result_compare"
    tools_db.execute_sql(
        f"""
        DELETE FROM am.{table} s
        USING am.cat_result c
        WHERE s.cur_user = current_user
          AND s.result_id = c.result_id
          AND c.asset_type = (
              SELECT COALESCE(asset_type, 'ARC')
              FROM am.cat_result
              WHERE result_id = {result_id}
          );
        INSERT INTO am.{table} (result_id, cur_user)
        VALUES ({result_id}, current_user)
        ON CONFLICT (cur_user, result_id) DO NOTHING;
        """
    )


class GwResultSelectorButton(GwAction):
    def __init__(self, icon_path, action_name, text, toolbar, action_group):
        """ Initialise toolbar action for AM result selector """
        super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.iface = global_vars.iface

        self.icon_path = icon_path
        self.action_name = action_name
        self.text = text
        self.toolbar = toolbar
        self.action_group = action_group

    def clicked_event(self):
        """ Open result selector dialog and load combo values """
        self.dlg_result_selector = GwResultSelectorUi(self)
        if not self._fill_combos():
            return
        self._update_descriptions()
        self._set_signals()
        tools_gw.open_dialog(self.dlg_result_selector, dlg_name="result_selector")

    def _fill_combos(self):
        """ Fill main and compare result combos from cat_result """
        dlg = self.dlg_result_selector
        # idval includes asset_type so ARC/NODE are distinguishable in one combo
        results = tools_db.get_rows(
            """
            SELECT result_id AS id,
                   result_name || ' [' || COALESCE(asset_type, 'ARC') || ']' AS idval,
                   descript,
                   COALESCE(asset_type, 'ARC') AS asset_type
            FROM am.cat_result
            ORDER BY asset_type, result_name
            """
        )
        if not results:
            msg = "There are no results available to display."
            tools_qt.show_info_box(msg)
            return False

        # Combo result_main — prefer showing ARC if both features are active
        tools_qt.fill_combo_values(dlg.cmb_result_main, results, 1, sort_by=1)
        selected_main = tools_db.get_row(
            """
            SELECT s.result_id
            FROM am.selector_result_main s
            JOIN am.cat_result c ON c.result_id = s.result_id
            WHERE s.cur_user = current_user
            ORDER BY c.asset_type
            LIMIT 1
            """
        )
        if selected_main:
            tools_qt.set_combo_value(
                dlg.cmb_result_main, str(selected_main[0]), 0, add_new=False
            )

        # Combo result_compare
        tools_qt.fill_combo_values(dlg.cmb_result_compare, results, 1, sort_by=1)
        selected_compare = tools_db.get_row(
            """
            SELECT s.result_id
            FROM am.selector_result_compare s
            JOIN am.cat_result c ON c.result_id = s.result_id
            WHERE s.cur_user = current_user
            ORDER BY c.asset_type
            LIMIT 1
            """
        )
        if selected_compare:
            tools_qt.set_combo_value(
                dlg.cmb_result_compare, str(selected_compare[0]), 0, add_new=False
            )

        return True

    def _save_selection(self):
        """ Persist user result selection and refresh layer symbology """
        dlg = self.dlg_result_selector
        result_main = tools_qt.get_combo_value(dlg, dlg.cmb_result_main)
        result_compare = tools_qt.get_combo_value(dlg, dlg.cmb_result_compare)
        # Replace only same asset_type — keep the other feature's selection on the map
        set_am_selector_result(result_main, "main")
        set_am_selector_result(result_compare, "compare")
        dlg.close()
        for layer_name in (
            "v_asset_arc_output",
            "v_asset_arc_output_compare",
            "v_asset_node_output",
            "v_asset_node_output_compare",
            "v_asset_link_output",
            "v_asset_link_output_compare",
        ):
            layer = tools_qgis.get_layer_by_tablename(layer_name, schema_name="am")
            if layer:
                layer.dataProvider().reloadData()
                layer.triggerRepaint()

        try:
            # Update symbology of layers currently loaded in the project
            if not lib_vars.schema_name:
                return
            target_layers = []
            sql = (
                f"SELECT id, addparam FROM {lib_vars.schema_name}.sys_table "
                "WHERE source = 'am' AND addparam ->> 'refreshSymbology' = 'true'"
            )
            rows = tools_db.get_rows(sql) or []
            for row in rows:
                target_layer = tools_qgis.get_layer_by_tablename(row[0], schema_name="am")
                if target_layer is None:
                    continue
                target_layers.append((target_layer, row[1]))

            if len(target_layers) > 0:
                result = tools_qt.show_question("Do you want to update the symbology of the layers currently loaded in the project?", "Update AM Layers Symbology", force_action=True)
                if result:
                    for layer, addparam in target_layers:
                        tools_gw.refresh_categorized_layer_symbology_classes(layer, addparam)
        except Exception:
            pass

    def _set_signals(self):
        """ Connect result selector dialog widget signals """
        dlg = self.dlg_result_selector
        dlg.btn_cancel.clicked.connect(dlg.reject)
        dlg.btn_accept.clicked.connect(self._save_selection)
        dlg.cmb_result_main.currentIndexChanged.connect(self._update_descriptions)
        dlg.cmb_result_compare.currentIndexChanged.connect(self._update_descriptions)

    def _update_descriptions(self):
        """ Update description text fields from combo selection """
        dlg = self.dlg_result_selector
        desc_main = tools_qt.get_combo_value(dlg, dlg.cmb_result_main, 2)
        asset_main = tools_qt.get_combo_value(dlg, dlg.cmb_result_main, 3)
        active_main = tools_db.get_rows(
            """
            SELECT c.result_name || ' [' || COALESCE(c.asset_type, 'ARC') || ']'
            FROM am.selector_result_main s
            JOIN am.cat_result c ON c.result_id = s.result_id
            WHERE s.cur_user = current_user
            ORDER BY c.asset_type
            """
        ) or []
        active_txt = ", ".join(r[0] for r in active_main) if active_main else "-"
        main_txt = desc_main or ""
        if asset_main:
            main_txt = f"[{asset_main}] {main_txt}".strip()
        main_txt = f"{main_txt}\n\n{tools_qt.tr('Active on map')}: {active_txt}".strip()
        dlg.txt_result_main_desc.setText(main_txt)

        desc_compare = tools_qt.get_combo_value(dlg, dlg.cmb_result_compare, 2)
        asset_compare = tools_qt.get_combo_value(dlg, dlg.cmb_result_compare, 3)
        compare_txt = desc_compare or ""
        if asset_compare:
            compare_txt = f"[{asset_compare}] {compare_txt}".strip()
        dlg.txt_result_compare_desc.setText(compare_txt)
