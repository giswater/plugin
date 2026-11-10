"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

import platform
import os

from qgis.PyQt.QtCore import pyqtSignal
from qgis.PyQt.QtWidgets import QCheckBox
from qgis.core import Qgis

from ...threads.task import GwTask
from ...utils import tools_gw
from ....libs import lib_vars, tools_qgis, tools_log, tools_os, tools_qt


class GwProjectCheckCMTask(GwTask):
    """
    Task to check project health in the background for Campaign Management.
    It executes a database function and passes the result back.
    """
    task_started = pyqtSignal()
    task_finished = pyqtSignal()

    def __init__(self, description, params=None):
        super().__init__(description)
        self.params = params if params else {}
        self.dialog = self.params.get('dialog')
        self.log_widget = self.params.get('log_widget')
        self.result_data = None

    def run(self):
        """
        Executes the main task.
        """
        super().run()
        self.task_started.emit()
        try:
            # Prepare the data and execute the database function to check the project.
            # Use hardcoded parameters based on user's working SQL call.
            project_type = "cm"
            function_fid = 0

            campaign_id = self.params.get("campaign_id")
            lot_id = self.params.get("lot_id")
            check_management_configs = self.params.get("check_management_configs", False)
            # Always perform data-related checks
            check_data_related = self.params.get("check_data_related", True)

            # Async combos store [id, idval]. An unselected lot is ['', ''], not None.
            campaign_id = self._json_id(campaign_id)
            lot_id = self._json_id(lot_id)

            extras = (
                f'"parameters": {{'
                f'"functionFid": {function_fid}, "project_type": "{project_type}", '
                f'"campaignId": {campaign_id}, '
                f'"lotId": {lot_id}, '
                f'"checkManagementConfigs": {str(check_management_configs).lower()}, '
                f'"checkDataRelated": {str(check_data_related).lower()}'
                f'}}'
            )
            body = tools_gw.create_body(extras=extras)
            self.result_data = tools_gw.execute_procedure('gw_fct_cm_setcheckproject', body, schema_name='cm', is_thread=True, aux_conn=self.aux_conn)
            if self.result_data and self.result_data.get('status') == 'Accepted':
                return True
            return False
        except Exception as e:
            msg = "EXCEPTION: {0}, {1}"
            msg_params = (type(e).__name__, str(e),)
            tools_log.log_warning(msg, msg_params=msg_params)
            return False

    def finished(self, result):
        """
        Handles the task completion.
        """

        super().finished(result)

        self.dialog.progressBar.setVisible(False)
        if self.isCanceled():
            self.setProgress(100)
            return

        # Handle exception
        if self.exception is not None:
            msg = f'''<b>{tools_qt.tr('key')}: </b>{self.exception}<br>'''
            msg += f'''<b>{tools_qt.tr('key container')}: </b>'body/data/ <br>'''
            msg += f'''<b>{tools_qt.tr('Python file')}: </b>{__name__} <br>'''
            msg += f'''<b>{tools_qt.tr('Python function')}:</b> {self.__class__.__name__} <br>'''
            title = "Key on returned json from ddbb is missed."
            tools_qt.show_exception_message(title, msg)
            return

        # Show dialog with audit check project result
        if not self.result_data:
            msg = "Check project did not return a result"
            tools_qgis.show_warning(msg, dialog=self.dialog, context_name="cm")
            self.setProgress(100)
            return
        self._show_check_project_result(self.result_data)

        self.setProgress(100)

    # TODO: Remove this function
    def fill_check_project_table(self, layers, init_project):
        """ Fill table 'audit_check_project' table with layers data """

        fields = '"fields":[  '
        for layer in layers:
            if layer is None:
                continue
            if not tools_qgis.check_query_layer(layer):
                continue
            if layer.providerType() != 'postgres':
                continue
            layer_source = tools_qgis.get_layer_source(layer)
            if layer_source['schema'] is None:
                continue
            layer_source['schema'] = layer_source['schema'].replace('"', '')
            if layer_source.get('schema') != lib_vars.schema_name:
                continue

            schema_name = layer_source['schema']
            if schema_name is not None:
                schema_name = schema_name.replace('"', '')
                table_name = layer_source['table']
                db_name = layer_source['db']
                host_name = layer_source['host']
                table_user = layer_source['user']
                fields += f'{{"table_schema":"{schema_name}", '
                fields += f'"table_id":"{table_name}", '
                fields += f'"table_dbname":"{db_name}", '
                fields += f'"table_host":"{host_name}", '
                fields += '"fid":101, '
                fields += f'"table_user":"{table_user}"}}, '
        fields = fields[:-2] + ']'
        # Execute function 'gw_fct_cm_setcheckproject'
        self.result = self._execute_check_project_function(init_project, fields)

        return True, self.result

    # region private functions

    # TODO: Remove this function
    def _execute_check_project_function(self, init_project, fields_to_insert):
        """ Execute function 'gw_fct_cm_setcheckproject' with checkbox selections passed from project_check_btn.py """
        # Retrieve checkbox values from params
        show_versions = self.params.get("show_versions", False)
        show_qgis_project = self.params.get("show_qgis_project", False)

        # Get project variables
        add_schema = lib_vars.project_vars['add_schema']
        main_schema = lib_vars.project_vars['main_schema']
        project_role = lib_vars.project_vars['project_role']
        info_type = lib_vars.project_vars['info_type']
        project_type = lib_vars.project_vars['project_type']

        plugin_version, message = tools_qgis.get_plugin_version()
        if plugin_version is None:
            if message:
                tools_qgis.show_warning(message)

        # Get log folder size
        log_folder_volume = 0
        if lib_vars.user_folder_dir:
            log_folder = f"{lib_vars.user_folder_dir}{os.sep}core{os.sep}log"
            size = tools_os.get_folder_size(log_folder)
            log_folder_volume = f"{round(size / (1024 * 1024), 2)} MB"

        extras = f'"version":"{plugin_version}"'
        extras += ', "fid":101'
        extras += f', "initProject":{init_project}'
        extras += f', "addSchema":"{add_schema}"'
        extras += f', "mainSchema":"{main_schema}"'
        extras += f', "projecRole":"{project_role}"'
        extras += f', "infoType":"{info_type}"'
        extras += f', "logFolderVolume":"{log_folder_volume}"'
        extras += f', "projectType":"{project_type}"'
        extras += f', "qgisVersion":"{Qgis.QGIS_VERSION}"'
        extras += f', "osVersion":"{platform.system()} {platform.release()}"'
        extras += f', {fields_to_insert}'
        if show_versions or show_qgis_project:
            extras += f', "parameters": {{"showVersions": {str(show_versions).lower()}, "showQgisProject": {str(show_qgis_project).lower()}}}'

        # Execute procedure
        body = tools_gw.create_body(extras=extras)
        result = tools_gw.execute_procedure('gw_fct_cm_setcheckproject', body, is_thread=True, aux_conn=self.aux_conn)
        try:
            if not result or result['body']['variables'].get('hideForm'):
                return result
        except KeyError as e:
            msg = "EXCEPTION: {0}, {1}"
            msg_params = (type(e).__name__, e,)
            tools_log.log_warning(msg, msg_params=msg_params)
            return result

        return result

    @staticmethod
    def _json_id(value):
        """JSON scalar for a combo id. Blank async-combo rows become null."""
        if isinstance(value, (list, tuple)):
            value = value[0] if value else None
        if value is None:
            return "null"
        if isinstance(value, str) and value.strip().lower() in ("", "none", "null"):
            return "null"
        return value

    def _show_check_project_result(self, result):
        """ Show dialog with audit check project results """

        # Handle failed results
        if not result:
            return False
        if result.get('status') == 'Failed':
            tools_gw.manage_json_exception(result)
            return False

        tools_gw.manage_json_response(result, None, None)

        # Call `fill_tab_log()` directly, no need to store variables
        tools_gw.fill_tab_log(self.dialog, result['body']['data'], reset_text=False)

    def _add_selected_layers(self, dialog, m_layers):
        """ Receive a list of layers, look for the checks associated with each layer and if they are checked,
            load the corresponding layer and put styles
        :param dialog: Dialog where to look for QCheckBox (QDialog)
        :param m_layers: List with the information of the missing layers (list)[{...}, {...}, {...}, ...]
        :return:
        """

        for layer_info in m_layers:
            if layer_info == {}:
                continue

            check = dialog.findChild(QCheckBox, layer_info['layer'])
            if check.isChecked():
                geom_field = layer_info['geom_field']
                pkey_field = layer_info['pkey_field']
                group = layer_info['group_layer'] if layer_info['group_layer'] is not None else 'GW Layers'
                style_id = layer_info['style_id']

                tools_gw.add_layer_database(layer_info['layer'], geom_field, pkey_field, group=group)
                layer = None
                qml = None
                if style_id is not None:
                    layer = tools_qgis.get_layer_by_tablename(layer_info['layer'])
                    if layer:
                        extras = f'"style_id":"{style_id}"'
                        body = tools_gw.create_body(extras=extras)
                        style = tools_gw.execute_procedure('gw_fct_cm_getstyle', body, is_thread=True)
                        if not style or style['status'] == 'Failed':
                            return
                        if 'styles' in style['body']:
                            if 'style' in style['body']['styles']:
                                qml = style['body']['styles']['style']
                            tools_qgis.create_qml(layer, qml)
                tools_qgis.set_layer_visible(layer)

        tools_gw.close_dialog(self.dialog)

    # endregion
