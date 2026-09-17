"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial

from ...shared.document import global_vars
from qgis.PyQt.QtCore import Qt, QDate

from ..maptool import GwMaptool
from ...ui.ui_manager import GwArcFusionUi, GwPsectorUi
from ...utils import tools_gw
from ....libs import tools_qt, tools_db, tools_qgis, tools_os


class GwArcFusionButton(GwMaptool):
    """ Button 24: Fusion arc
    User select one node. Execute SQL function: 'gw_fct_delete_node' """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        super().__init__(icon_path, action_name, text, toolbar, action_group)

    # region QgsMapTools inherited
    """ QgsMapTools inherited event functions """

    def activate(self):

        # Check button
        if hasattr(self.action, "setChecked"):
            self.action.setChecked(True)

        # Store user snapping configuration
        self.previous_snapping = self.snapper_manager.get_snapping_options()

        # Set active layer to 've_node'
        self.layer_node = tools_qgis.get_layer_by_tablename("ve_node")
        self.iface.setActiveLayer(self.layer_node)

        # Change cursor
        self.canvas.setCursor(self.cursor)

        # Show help message when action is activated
        if self.show_help:
            msg = "Click on node, that joins two pipes, in order to remove it and merge pipes"
            tools_qgis.show_info(msg)

    def canvasReleaseEvent(self, event):

        self._get_arc_fusion(event)

    # endregion

    # region private functions

    def _fusion_arc(self):

        catalog = tools_qt.get_text(self.dlg_fusion, self.dlg_fusion.cmb_new_cat)
        if catalog in (None, 'null'):
            msg = "Mandatory field is missing. Please, set a value for field"
            tools_qgis.show_warning(msg, parameter="'Catalog id'", dialog=self.dlg_fusion)
            return
        asset_id = tools_qt.get_text(self.dlg_fusion, self.dlg_fusion.txt_new_asset)

        # Build diff fields warning message
        catalog_arc1 = tools_qt.get_text(self.dlg_fusion, self.dlg_fusion.txt_arc1cat)
        catalog_arc2 = tools_qt.get_text(self.dlg_fusion, self.dlg_fusion.txt_arc2cat)
        asset_arc1 = tools_qt.get_text(self.dlg_fusion, self.dlg_fusion.txt_arc1asset)
        asset_arc2 = tools_qt.get_text(self.dlg_fusion, self.dlg_fusion.txt_arc2asset)
        diff_fields = []
        if catalog_arc1 != catalog_arc2:
            txt = ("Catalog:\n"
                f"  Arc 1: {catalog_arc1} {'(SELECTED)' if catalog_arc1 == catalog else ''}\n"
                f"  Arc 2: {catalog_arc2} {'(SELECTED)' if catalog_arc2 == catalog else ''}"
            )
            if catalog_arc1 != catalog and catalog_arc2 != catalog:
                txt += f"\n  SELECTED: {catalog}"
            diff_fields.append(txt)

        if asset_arc1 != asset_arc2:
            txt = ("Asset:\n"
                f"  Arc 1: {'None' if asset_arc1 == 'null' else asset_arc1} {'(SELECTED)' if asset_arc1 == asset_id else ''}\n"
                f"  Arc 2: {'None' if asset_arc2 == 'null' else asset_arc2} {'(SELECTED)' if asset_arc2 == asset_id else ''}"
            )
            if asset_arc1 != asset_id and asset_arc2 != asset_id:
                txt += f"\n  SELECTED: {asset_id}"
            diff_fields.append(txt)

        if diff_fields:
            msg = (
                "The following fields differ between the selected arcs. "
                "You are about to merge them using the selected values.\n\n"
                "{0}\n\nDo you want to continue?"
            )
            msg_params = ('\n\n'.join(diff_fields),)
            answer = tools_qt.show_question(msg, title="Arc Fusion", msg_params=msg_params)
            if not answer:
                return

        # Build SQL function input parameters
        state_type = tools_qt.get_combo_value(self.dlg_fusion, "cmb_statetype")
        action_mode = self.dlg_fusion.cmb_nodeaction.currentIndex()
        plan_mode = global_vars.psignals['psector_active']
        if plan_mode:
            action_mode = 1
        workcat_id_end = self.dlg_fusion.workcat_id_end.currentText()
        enddate = self.dlg_fusion.enddate.date()
        enddate_str = enddate.toString('yyyy-MM-dd')
        feature_id = f'"id":["{self.node_id}"]'
        extras = f'"enddate":"{enddate_str}"'
        if workcat_id_end not in (None, 'null', ''):
            extras += f', "workcatId":"{workcat_id_end}"'
        if self.psector_id:
            extras += f', "psectorId": "{self.psector_id}"'
        extras += f', "plan_mode": {str(plan_mode).lower()}'
        if action_mode is not None:
            extras += f', "action_mode": {action_mode}'
            if action_mode == 1 and state_type is not None:
                if state_type != "":
                    extras += f', "state_type": {state_type}'
                else:
                    extras += ', "state_type": null'
        if catalog not in (None, 'null', ''):
            extras += f', "arccat_id":"{catalog}"'
        if asset_id not in (None, 'null', ''):
            extras += f', "asset_id":"{asset_id}"'
        body = tools_gw.create_body(feature=feature_id, extras=extras)
        # Execute SQL function and show result to the user
        complet_result = tools_gw.execute_procedure('gw_fct_setarcfusion', body)
        if not complet_result or complet_result['status'] == "Failed":
            msg = "Error fusing arcs"
            tools_qgis.show_warning(msg)
            return

        text_result = None
        log = tools_gw.get_config_parser("user_edit_tricks", "arc_fusion_disable_showlog", 'user', 'init')
        if not tools_os.set_boolean(log, False):
            text_result, change_tab = tools_gw.fill_tab_log(self.dlg_fusion, complet_result['body']['data'], True, True, 1)

        self._save_dlg_values()

        if not text_result:
            tools_gw.close_dialog(self.dlg_fusion)

        self.refresh_map_canvas()
        self.iface.mapCanvas().refresh()

        # Refresh psector's relations tables
        tools_gw.execute_class_function(GwPsectorUi, '_refresh_tables_relations')

        # Check in init config file if user wants to keep map tool active or not
        self.manage_active_maptool()

    def _get_arc_fusion(self, event):

        if event.button() == Qt.MouseButton.RightButton:
            self.cancel_map_tool()
            return

        # Get coordinates
        event_point = self.snapper_manager.get_event_point(event)

        # Snapping
        snapped_feat = None
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if result.isValid():
            snapped_feat = self.snapper_manager.get_snapped_feature(result)

        if snapped_feat:

            self.node_id = snapped_feat.attribute('node_id')
            self.node_state = snapped_feat.attribute('state')
            self.psector_id = None
            # If the node has state 0 (obsolete) don't open arc fusion dlg
            if self.node_state is not None and self.node_state == 0:
                msg = "The node is obsolete, this tool doesn't work with obsolete nodes."
                title = "Arc fusion"
                tools_qgis.show_warning(msg, title=title)
                return

            self.open_arc_fusion_dlg()

    def open_arc_fusion_dlg(self):
        self.dlg_fusion = GwArcFusionUi(self)
        tools_gw.load_settings(self.dlg_fusion)

        # Fill ComboBox cmb_nodeaction
        rows = [[0, tools_qt.tr('KEEP OPERATIVE')], [1, tools_qt.tr('DOWNGRADE NODE')], [2, tools_qt.tr('REMOVE NODE')]]
        tools_qt.fill_combo_values(self.dlg_fusion.cmb_nodeaction, rows, sort_by=0)
        node_action = tools_gw.get_config_parser("btn_arc_fusion", "cmb_nodeaction", "user", "session")
        if node_action not in (None, 'None', ''):
            tools_qt.set_widget_text(self.dlg_fusion, "cmb_nodeaction", node_action)

        # Fill ComboBox workcat_id_end
        sql = "SELECT id, id as idval FROM cat_work ORDER BY id"
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_fusion.workcat_id_end, rows)

        # Fill ComboBox cmb_statetype
        sql = "SELECT id, name as idval FROM v_value_state_type WHERE id IS NOT NULL AND state = 0"
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_fusion.cmb_statetype, rows)
        state_type = tools_gw.get_config_parser("btn_arc_fusion", "cmb_statetype", "user", "session")
        if state_type not in (None, 'None', ''):
            tools_qt.set_widget_text(self.dlg_fusion, "cmb_statetype", state_type)

        # Set QDateEdit to current date
        current_date = QDate.currentDate()
        tools_qt.set_calendar(self.dlg_fusion, "enddate", current_date)

        valid_states = [0]
        # If the node has state 2 (planified) only allow remove node
        if global_vars.psignals['psector_active']:
            self.psector_id = global_vars.psignals['psector_id']
            if self.node_state is not None and self.node_state == 2:
                node_psector_id = int(self._get_feature_psector_id(self.node_id, 'node'))
                current_psector_id = int(global_vars.psignals['psector_id'])
                node_psector_name = None
                current_psector_name = None
                row = tools_db.get_row(f"SELECT name FROM v_plan_psector WHERE psector_id = {node_psector_id}")
                if row:
                    node_psector_name = row[0]
                row = tools_db.get_row(f"SELECT name FROM v_plan_psector WHERE psector_id = {current_psector_id}")
                if row:
                    current_psector_name = row[0]
                if node_psector_id != current_psector_id:
                    msg = "The selected node is planified in another psector.\nNode psector: {0}\nCurrent psector: {1}"
                    msg_params = (node_psector_name, current_psector_name,)
                    tools_qt.show_info_box(msg, title="Info", msg_params=msg_params)
                    return
                self.dlg_fusion.cmb_nodeaction.setCurrentIndex(2)
                self.dlg_fusion.cmb_nodeaction.setEnabled(False)
                tools_qt.set_stylesheet(self.dlg_fusion.cmb_nodeaction, style="color: black")
        else:
            self.psector_id = None
            valid_states = [0, 2]
        if self.node_state in valid_states:
            msg_params = None
            if self.node_state == 0:
                msg = "Current feature has state '{0}'. Therefore it is not fusionable"
                state = 'OBSOLETE'
                msg_params = (state,)
            elif self.node_state == 2:
                msg = "Current feature is planified. You should activate plan mode to work with it."
            tools_qt.show_info_box(msg, "Info", msg_params=msg_params if msg_params is not None else None)
            return

        # Disable some widgets
        if self.dlg_fusion.cmb_nodeaction.currentIndex() != 1:
            self.dlg_fusion.enddate.setEnabled(False)
            self.dlg_fusion.workcat_id_end.setEnabled(False)
            self.dlg_fusion.cmb_statetype.setEnabled(False)

        # Set read only to some widgets
        self.dlg_fusion.txt_arc1asset.setReadOnly(True)
        self.dlg_fusion.txt_arc2asset.setReadOnly(True)

        # Build catalog and asset widgets
        if not self._build_catalog_asset_widgets():
            return

        # Manage plan widgets
        self._manage_plan_widgets()

        # Disable tab log
        tools_gw.disable_tab_log(self.dlg_fusion)

        # Set signals
        self.dlg_fusion.cmb_nodeaction.currentIndexChanged.connect(partial(self._manage_nodeaction))
        self.dlg_fusion.btn_accept.clicked.connect(self._fusion_arc)
        self.dlg_fusion.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_fusion))
        self.dlg_fusion.rejected.connect(partial(tools_gw.close_dialog, self.dlg_fusion))

        tools_gw.open_dialog(self.dlg_fusion, dlg_name='arc_fusion')

    def _build_catalog_asset_widgets(self):
        """ Build catalog and asset widgets """

        # Get arc catalogs
        sql = "SELECT id, id as idval FROM cat_arc"
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_fusion.cmb_new_cat, rows)
        tools_qt.set_autocompleter(self.dlg_fusion.cmb_new_cat)

        sql = f"""
            SELECT arccat_id::text 
            FROM ve_arc 
            WHERE node_1 = {self.node_id} OR node_2 = {self.node_id}
            GROUP BY arccat_id 
            HAVING COUNT(*) = 2
            LIMIT 1
        """
        row = tools_db.get_row(sql)
        if row:
            tools_qt.set_selected_item(self.dlg_fusion, self.dlg_fusion.cmb_new_cat, row[0])

        # Get linked arcs to the selected node
        sql = f"SELECT arc_id, arccat_id, asset_id FROM ve_arc WHERE node_1 = {self.node_id} OR node_2 = {self.node_id}"
        rows = tools_db.get_rows(sql)
        if not rows or len(rows) != 2:
            msg = "The selected node should have exactly two linked arcs."
            tools_qt.show_info_box(msg, title="Info")
            return False
        else:
            tools_qt.set_widget_text(self.dlg_fusion, "txt_arc1cat", rows[0][1])
            tools_qt.set_widget_text(self.dlg_fusion, "txt_arc2cat", rows[1][1])
            tools_qt.set_widget_text(self.dlg_fusion, "txt_arc1asset", rows[0][2])
            tools_qt.set_widget_text(self.dlg_fusion, "txt_arc2asset", rows[1][2])
            tools_qt.set_stylesheet(self.dlg_fusion.txt_arc1asset, style="background: rgb(242, 242, 242); color: rgb(110, 110, 110)")
            tools_qt.set_stylesheet(self.dlg_fusion.txt_arc2asset, style="background: rgb(242, 242, 242); color: rgb(110, 110, 110)")
        return True

    def _manage_nodeaction(self, index):

        if index == 1:
            self.dlg_fusion.enddate.setEnabled(True)
            self.dlg_fusion.workcat_id_end.setEnabled(True)
            self.dlg_fusion.cmb_statetype.setEnabled(True)
        else:
            self.dlg_fusion.enddate.setEnabled(False)
            self.dlg_fusion.workcat_id_end.setEnabled(False)
            self.dlg_fusion.cmb_statetype.setEnabled(False)

    def _manage_plan_widgets(self):
        """ Manage plan widgets """

        if global_vars.psignals and global_vars.psignals['psector_active']:
            self.dlg_fusion.lbl_nodeaction.setVisible(False)
            self.dlg_fusion.cmb_nodeaction.setVisible(False)
            self.dlg_fusion.lbl_enddate.setVisible(False)
            self.dlg_fusion.enddate.setVisible(False)
            self.dlg_fusion.lbl_workcat_id_end.setVisible(False)
            self.dlg_fusion.workcat_id_end.setVisible(False)
            self.dlg_fusion.lbl_statetype.setVisible(False)
            self.dlg_fusion.cmb_statetype.setVisible(False)

    def _save_dlg_values(self):

        # Save combo 'Node action'
        node_action = tools_qt.get_text(self.dlg_fusion, "cmb_nodeaction")
        if node_action:
            tools_gw.set_config_parser("btn_arc_fusion", "cmb_nodeaction", node_action)

        # Save combo 'State type'
        state_type = tools_qt.get_text(self.dlg_fusion, "cmb_statetype")
        if state_type:
            tools_gw.set_config_parser("btn_arc_fusion", "cmb_statetype", state_type)

    def _get_feature_psector_id(self, feature_id, feature_type):
        """ Get psector_id from a feature """

        table_name = f"plan_psector_x_{feature_type}"
        sql = f"""
            SELECT psector_id 
            FROM {table_name} 
            WHERE {feature_type}_id = '{feature_id}' 
            AND state = 1  -- operative feature
            AND psector_id IN (
                SELECT psector_id 
                FROM selector_psector 
                WHERE cur_user = current_user
            )
        """

        row = tools_db.get_row(sql)
        return row[0] if row else None

    # endregion