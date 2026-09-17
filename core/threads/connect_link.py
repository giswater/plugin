"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import json

from qgis.PyQt.QtCore import Qt
from qgis.PyQt.QtWidgets import QListWidget, QWidget

from .task import GwTask
from ..utils import tools_gw
from ...libs import tools_log, tools_qt, tools_db, lib_vars
from ..shared.psector import GwPsectorUi
from ... import global_vars


class GwConnectLink(GwTask):

    def __init__(self, description, connect_link_class, element_type, selected_arcs=None, selected_nodes=None,
                 extra_filters=None, force_reconnect=False, force_node=False,
                 pipe_diameter=None, max_distance=None, linkcat_id=None):

        super().__init__(description)
        self.connect_link_class = connect_link_class
        self.element_type = element_type
        self.selected_arcs = selected_arcs or []
        self.selected_nodes = selected_nodes or []
        self.extra_filters = extra_filters or {}
        self.force_reconnect = force_reconnect
        self.force_node = force_node
        self.pipe_diameter = pipe_diameter
        self.max_distance = max_distance
        self.linkcat_id = linkcat_id
        self.json_result = None

    def run(self):

        super().run()

        try:
            msg = "Task 'Connect link' execute function '{0}' with parameters: '{1}', '{2}'"
            msg_params = ("_link_selected_features", self.element_type,
                          f"selected_arcs={self.selected_arcs}, selected_nodes={self.selected_nodes}",)
            tools_log.log_info(msg, msg_params=msg_params)
            result = self._link_selected_features(self.element_type, self.selected_arcs, self.selected_nodes)
            self.connect_link_class.cancel_map_tool()
            return result
        except KeyError as e:
            self.exception = e
            return False

    def finished(self, result):
        super().finished(result)
        msg = "Task 'Connect link' execute function '{0}' from '{1}' with parameters: '{2}'"
        msg_params = ("manage_result", "connect_link_buttom.py", self.element_type,)
        tools_log.log_info(msg, msg_params=msg_params)
        self.connect_link_class.manage_result(self.json_result)

        # Refresh psector's relations tables
        tools_gw.execute_class_function(GwPsectorUi, '_refresh_tables_relations')

    def _link_selected_features(self, feature_type, selected_arcs=None, selected_nodes=None):
        """ Link selected @feature_type to the pipe """
        # Use individual processing for multiple connecs in "Set user click" mode
        user_click_with_multiple = (
            self._check_user_click_mode() and
            len(self.connect_link_class.ids) > 1
        )

        if user_click_with_multiple:
            return self._link_features_individually(feature_type, selected_arcs, selected_nodes)
        else:
            return self._link_features_batch(feature_type, selected_arcs, selected_nodes)

    def _check_user_click_mode(self):
        """ Check if user click mode is active by looking for temp_table entry """
        sql = "SELECT COUNT(*) FROM temp_table WHERE fid = 485 AND cur_user = current_user;"
        result = tools_db.get_row(sql, is_thread=True)
        return result and result[0] > 0

    def _append_node_extras(self, extras, selected_nodes=None):
        """ Append forceNode / forcedNodes to the procedure extras JSON """
        force_node = 'true' if self.force_node else 'false'
        extras += f', "forceNode":{force_node}'
        if selected_nodes:
            nodes_str_list = [f'"{str(node)}"' for node in selected_nodes]
            nodes_json = ', '.join(nodes_str_list)
            extras += f', "forcedNodes":[{nodes_json}]'
        extras = self._append_extra_filters(extras)
        return extras

    def _append_extra_filters(self, extras):
        """ Append extraFilters collected on the GUI thread """
        if self.extra_filters:
            extras += f', "extraFilters":{json.dumps(self.extra_filters)}'
        return extras

    @staticmethod
    def collect_extra_filters(dlg, fields):
        """ Read Extra filters widgets on the GUI thread; skip empty / null values """
        filters = {}
        fields = fields or []
        empty = (None, '', 'null', 'NULL', -1, '-1')
        for field in fields:
            col = field.get('columnname')
            wtype = field.get('widgettype')
            widgetname = field.get('widgetname') or f"tab_none_{col}"
            widget = dlg.findChild(QWidget, widgetname)
            if not col or widget is None:
                continue
            if wtype == 'multiple_option':
                list_widget = widget.findChild(QListWidget)
                if not list_widget:
                    continue
                values = []
                for i in range(list_widget.count()):
                    v = list_widget.item(i).data(Qt.ItemDataRole.UserRole)
                    if v not in empty:
                        values.append(v)
                if values:
                    filters[col] = values
            elif wtype == 'combo':
                try:
                    value = tools_qt.get_combo_value(dlg, widget, 0)
                except (TypeError, IndexError):
                    continue
                if value in empty:
                    continue
                filters[col] = value
            else:
                value = tools_qt.get_text(dlg, widget, return_string_null=False)
                if value not in empty:
                    filters[col] = value
        return filters

    def _json_quoted_or_null(self, value):
        return 'null' if not value else f'"{value}"'

    def _link_features_individually(self, feature_type, selected_arcs=None, selected_nodes=None):
        """ 
        Process each feature individually (for user click mode)
        This method handles multiple connecs when "Set user click" is used.
        Each connec needs its own database call with the exact clicked point.
        """
        # Get the user click point from temp_table
        sql = "SELECT ST_AsText(geom_point) FROM temp_table WHERE fid = 485 AND cur_user = current_user;"
        result = tools_db.get_row(sql, is_thread=True)
        user_point_wkt = result[0] if result else None

        success_count = 0
        last_result = None

        # Process each connec individually
        for connec_id in self.connect_link_class.ids:
            # Re-insert temp_table entry for each connec
            if user_point_wkt:
                sql_clear = "DELETE FROM temp_table WHERE fid = 485 AND cur_user = current_user;"
                tools_db.execute_sql(sql_clear, is_thread=True)
                sql_insert = f"INSERT INTO temp_table (fid, geom_point, cur_user) VALUES (485, ST_GeomFromText('{user_point_wkt}', {lib_vars.data_epsg}), current_user);"
                tools_db.execute_sql(sql_insert, is_thread=True)

            # Process single connec
            feature_id = f'"id":[{connec_id}]'

            pipe_diameter = self._json_quoted_or_null(self.pipe_diameter)
            max_distance = self._json_quoted_or_null(self.max_distance)
            linkcat_id = self.linkcat_id if self.linkcat_id is not None else ''
            force_reconnect = 'true' if self.force_reconnect else 'false'

            extras = (
                f'"feature_type":"{feature_type.upper()}",'
                f'"pipeDiameter":{pipe_diameter},'
                f'"maxDistance":{max_distance},'
                f'"linkcatId":"{linkcat_id}",'
                f'"forceReconnect":{force_reconnect}'
            )
            extras = self._append_node_extras(extras, selected_nodes)

            if selected_arcs:
                # Convert list to proper JSON array format for forcedArcs
                arcs_str_list = [f'"{str(arc)}"' for arc in selected_arcs]
                arcs_json = ', '.join(arcs_str_list)
                extras += f', "forcedArcs":[{arcs_json}]'

            # Check if psector mode is active and add psector_id
            psector_active = global_vars.psignals.get('psector_active', False)
            psector_id = global_vars.psignals.get('psector_id', None)
            if psector_active and psector_id:
                extras += f', "psectorId":"{psector_id}"'

            body = tools_gw.create_body(feature=feature_id, extras=extras)

            # Execute SQL function for this connec
            result = tools_gw.execute_procedure('gw_fct_setlinktonetwork', body, aux_conn=self.aux_conn, is_thread=True)

            if result and result.get('status') == 'Accepted':
                success_count += 1
                last_result = result  # Keep the last successful result

        # Use the last successful result, or create a failure result if none succeeded
        if last_result:
            self.json_result = last_result
        else:
            self.json_result = {'status': 'Failed', 'message': {'level': 1, 'text': 'No connecs processed successfully'}}

        return success_count > 0

    def _link_features_batch(self, feature_type, selected_arcs=None, selected_nodes=None):
        """ 
        Process all features in batch (normal mode)
        This is the standard processing mode - faster for multiple connecs
        when using "Set closest point" or single connec operations.
        """
        # Get selected features from layers of selected @feature_type
        feature_id = f'"id":{self.connect_link_class.ids}'

        pipe_diameter = self._json_quoted_or_null(self.pipe_diameter)
        max_distance = self._json_quoted_or_null(self.max_distance)
        linkcat_id = self.linkcat_id if self.linkcat_id is not None else ''
        force_reconnect = 'true' if self.force_reconnect else 'false'

        extras = (
            f'"feature_type":"{feature_type.upper()}",'
            f'"pipeDiameter":{pipe_diameter},'
            f'"maxDistance":{max_distance},'
            f'"linkcatId":"{linkcat_id}",'
            f'"forceReconnect":{force_reconnect}'
        )
        extras = self._append_node_extras(extras, selected_nodes)

        if selected_arcs:
            # Convert list to proper JSON array format for forcedArcs
            arcs_str_list = [f'"{str(arc)}"' for arc in selected_arcs]
            arcs_json = ', '.join(arcs_str_list)
            extras += f', "forcedArcs":[{arcs_json}]'

        # Check if psector mode is active and add psector_id
        psector_active = global_vars.psignals.get('psector_active', False)
        psector_id = global_vars.psignals.get('psector_id', None)
        if psector_active and psector_id:
            extras += f', "psectorId":"{psector_id}"'

        body = tools_gw.create_body(feature=feature_id, extras=extras)

        # Execute SQL function and show result to the user
        msg = "Task 'Connect link' execute procedure '{0}' with parameters: '{1}', '{2}', '{3}'"
        msg_params = ("gw_fct_setlinktonetwork", body, f"aux_conn={self.aux_conn}", "is_thread=True",)
        tools_log.log_info(msg, msg_params=msg_params)
        self.json_result = tools_gw.execute_procedure('gw_fct_setlinktonetwork', body, aux_conn=self.aux_conn, is_thread=True)

        return self.json_result is not None and self.json_result.get('status') == 'Accepted'
