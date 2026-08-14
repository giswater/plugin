"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from qgis.PyQt.QtCore import pyqtSignal
from qgis.core import Qgis, QgsEditFormConfig, QgsProject
from qgis.utils import iface

from .task import GwTask
from ..utils import tools_gw
from ...libs import tools_log, tools_qgis, tools_qt, tools_db


class GwProjectLayersConfig(GwTask):
    """ This shows how to subclass QgsTask """

    fake_progress = pyqtSignal()

    def __init__(self, description, params):

        super().__init__(description)
        self.exception = None
        self.message = None
        self.available_layers = None
        self.project_type = params['project_type']
        self.schema_name = params['schema_name']
        self.qgis_project_infotype = params['qgis_project_infotype']
        self.db_layers = params['db_layers']
        self.body = None
        self.json_result = None
        self.vr_errors = None
        self.vr_missing = None
        self.vr_layers_to_add = None
        self.vr_layer_by_table = None

    def run(self):

        super().run()
        self.setProgress(0)
        self.vr_errors = set()
        self.vr_missing = set()
        self.vr_layers_to_add = set()
        self.vr_layer_by_table = {}
        tools_qgis.refresh_value_relation_target_tables(aux_conn=self.aux_conn, is_thread=True)
        self._get_layers_to_config()
        self._set_layer_config(self.available_layers)
        self.setProgress(100)

        return True

    def finished(self, result):

        super().finished(result)

        sql = "SELECT gw_fct_getinfofromid("
        if self.body:
            sql += f"{self.body}"
        sql += ");"
        tools_gw.manage_json_response(self.json_result, sql, None)

        # Recreate VR lookups on the main thread (worker QgsVectorLayer is not a usable TOC layer)
        if self.vr_layers_to_add:
            for old_layer in self.vr_layers_to_add:
                table = old_layer.customProperty("gw_id") or tools_qgis.get_layer_source_table_name(old_layer)
                old_id = old_layer.id()
                new_layer = tools_gw.load_layer_in_hidden_group(table, '', add_to_toc=True)
                if new_layer and new_layer.isValid():
                    tools_qgis.rebind_value_relation_layer(old_id, new_layer)
                else:
                    gw_id = table or old_layer.name()
                    tools_qgis.add_layer_to_toc(
                        old_layer, group="HIDDEN", create_groups=True, custom_properties={"gw_id": gw_id})
                    tools_qgis.set_layer_visible(old_layer, recursive=False, visible=False)

            tools_gw.hide_group_from_toc('HIDDEN')
            hidden_group = QgsProject.instance().layerTreeRoot().findGroup('HIDDEN')
            if hidden_group:
                hidden_group.setItemVisibilityChecked(False)

        # Select the layer called 've_node'
        layer = tools_qgis.get_layer_by_tablename('ve_node')
        if layer:
            iface.setActiveLayer(layer)

        # If user cancel task
        if self.isCanceled():
            return

        if result:
            if self.exception:
                if self.message:
                    tools_log.log_warning(str(self.message))
            return

        # If sql function return null
        if result is False:
            msg = "Task failed: {0}. This is probably a DB error, check postgres function '{1}'."
            msg_params = (self.description(), "gw_fct_getinfofromid",)
            tools_log.log_warning(msg, msg_params=msg_params)

        if self.exception:
            msg = "Task aborted: {0}."
            msg_params = (self.description(),)
            tools_log.log_info(msg, msg_params=msg_params)
            msg = "Exception: {0}."
            msg_params = (self.exception,)
            tools_log.log_warning(msg, msg_params=msg_params)

    # region private functions

    def _get_layers_to_config(self):
        """ Get available layers to be configured """

        self.available_layers = [layer[0] for layer in self.db_layers]

        self._set_form_suppress(self.available_layers)
        project_schema = str(self.schema_name or "").replace('"', "").lower()
        all_layers_toc = tools_qgis.get_project_layers()
        for layer in all_layers_toc:
            schema = tools_qgis.get_layer_schema(layer)
            if not schema:
                schema = (tools_qgis.get_layer_source(layer).get("schema") or "")
            if str(schema).replace('"', "").lower() != project_schema:
                continue
            table_name = tools_qgis.get_layer_source_table_name(layer) or layer.customProperty("gw_id")
            if table_name and table_name not in self.available_layers:
                self.available_layers.append(table_name)

    def _set_form_suppress(self, layers_list):
        """ Set form suppress on "Hide form on add feature (global settings) """

        for layer_name in layers_list:
            layer = tools_qgis.get_layer_by_tablename(layer_name)
            if layer is None:
                continue
            config = layer.editFormConfig()
            if Qgis.QGIS_VERSION_INT >= 33200:
                config.setSuppress(QgsEditFormConfig.FeatureFormSuppress.SuppressOn)
            else:
                config.setSuppress(1)
            layer.setEditFormConfig(config)

    def _set_layer_config(self, layers):
        """ Set layer fields configured according to client configuration.
            At the moment manage:
                Column names as alias, combos as ValueMap, typeahead as textedit"""

        # Check only once if function 'gw_fct_getinfofromid' exists
        row = tools_db.check_function('gw_fct_getinfofromid', aux_conn=self.aux_conn, is_thread=True)
        if row in (None, ''):
            msg = "Function not found in database: {0}"
            msg_params = ("gw_fct_getinfofromid",)
            tools_log.log_warning(msg, msg_params=msg_params)
            return False

        msg_failed = ""
        msg_key = ""
        total_layers = len(layers)
        layer_number = 0
        for layer_name in layers:

            if self.isCanceled():
                return False

            layer = tools_qgis.get_layer_by_tablename(layer_name)
            if not layer:
                layer = tools_qgis.get_layer(custom_properties={"gw_id": layer_name})
            if not layer:
                continue

            layer_number = layer_number + 1
            self.setProgress((layer_number * 100) / total_layers)

            feature = f'"tableName":"{layer_name}", "isLayer":true'
            self.body = tools_gw.create_body(feature=feature)
            self.json_result = tools_gw.execute_procedure('gw_fct_getinfofromid', self.body, aux_conn=self.aux_conn,
                                                          is_thread=True, check_function=False)
            if not self.json_result or 'status' not in self.json_result or self.json_result['status'] == 'Failed' \
                    or 'body' not in self.json_result or 'data' not in self.json_result.get('body', {}):
                payload = {'body': {'data': {'fields': []}}}
            else:
                payload = self.json_result

            tools_gw.config_layer_attributes(payload, layer, layer_name, thread=self)

        if msg_failed != "":
            title = "Execute failed."
            tools_qt.show_exception_message(title, msg_failed)

        if msg_key != "":
            title = "Key on returned json from ddbb is missed."
            tools_qt.show_exception_message(title, msg_key)

    # endregion
