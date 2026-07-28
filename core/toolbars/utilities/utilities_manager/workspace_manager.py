"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import json
import os
from functools import partial

from qgis.PyQt.QtGui import QRegularExpressionValidator, QStandardItemModel, QPixmap
from qgis.PyQt.QtCore import QRegularExpression, QItemSelectionModel
from qgis.PyQt.QtWidgets import QLineEdit, QPlainTextEdit, QCheckBox, QAbstractItemView, QTableView, QApplication
from qgis.core import Qgis

from ...dialog import GwAction
from ....ui.ui_manager import GwWorkspaceManagerUi, GwCreateWorkspaceUi, GwGo2EpaOptionsUi
from ....utils import tools_gw
from ..... import global_vars
from .....libs import lib_vars, tools_qgis, tools_qt, tools_db


class GwWorkspaceManagerButton(GwAction):
    """ Button 64: Workspace manager """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.icon_folder = None
        self.workspace_with_current = None
        self.workspace_without_current = None

    def clicked_event(self):

        self._open_workspace_manager()

    # region private functions

    def _open_workspace_manager(self):
        """ Open workspace manager """

        # Main dialog
        self.dlg_workspace_manager = GwWorkspaceManagerUi(self)
        tools_gw.load_settings(self.dlg_workspace_manager)

        self.filter_name = self.dlg_workspace_manager.findChild(QLineEdit, 'txt_name')
        reg_exp = QRegularExpression(r'([^"\'\\\\])*')  # Don't allow " or ' or \ because it breaks the query
        self.filter_name.setValidator(QRegularExpressionValidator(reg_exp))

        # Fill table
        self.tbl_wrkspcm = self.dlg_workspace_manager.findChild(QTableView, 'tbl_wrkspcm')
        self._fill_tbl()
        self._set_labels_current_workspace(dialog=self.dlg_workspace_manager)

        # Disable tab log
        tools_gw.disable_tab_log(self.dlg_workspace_manager)

        # Connect main dialog signals
        self.dlg_workspace_manager.txt_name.textChanged.connect(partial(self._fill_tbl))
        self.dlg_workspace_manager.btn_create.clicked.connect(partial(self._open_create_workspace_dlg))
        self.dlg_workspace_manager.btn_current.clicked.connect(partial(self._set_current_workspace))
        self.dlg_workspace_manager.btn_toggle_privacy.clicked.connect(partial(self._toggle_privacy_workspace))
        self.dlg_workspace_manager.btn_update.clicked.connect(partial(self._open_update_workspace_dlg))
        selection_model = self.dlg_workspace_manager.tbl_wrkspcm.selectionModel()
        selection_model.selectionChanged.connect(partial(self._fill_info))
        self.tbl_wrkspcm.doubleClicked.connect(partial(self._open_update_workspace_dlg))
        self.dlg_workspace_manager.btn_delete.clicked.connect(partial(self._delete_workspace))

        self.dlg_workspace_manager.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_workspace_manager))
        self.dlg_workspace_manager.rejected.connect(partial(tools_gw.save_settings, self.dlg_workspace_manager))

        # Open dialog
        tools_gw.open_dialog(self.dlg_workspace_manager, 'workspace_manager')

    def _open_update_workspace_dlg(self, index=None):

        # Create workspace dialog
        self.dlg_create_workspace = GwCreateWorkspaceUi(self)
        self.new_workspace_name = self.dlg_create_workspace.findChild(QLineEdit, 'txt_workspace_name')
        self.new_workspace_descript = self.dlg_create_workspace.findChild(QPlainTextEdit, 'txt_workspace_descript')
        self.new_workspace_chk = self.dlg_create_workspace.findChild(QCheckBox, 'chk_workspace_private')

        # Disable tab log
        tools_gw.disable_tab_log(self.dlg_create_workspace)

        # Connect create workspace dialog signals
        self.dlg_create_workspace.btn_accept.clicked.connect(partial(self._update_workspace))
        self.dlg_create_workspace.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_create_workspace))

        # Get selected row
        selected_list = self.tbl_wrkspcm.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_workspace_manager)
            return

        # Get selected workspace id
        index = self.tbl_wrkspcm.selectionModel().currentIndex()
        value = index.sibling(index.row(), 0).data()

        sql = (f"SELECT name, descript, private FROM cat_workspace WHERE id = {value}")
        row = tools_db.get_row(sql)

        tools_qt.set_widget_text(self.dlg_create_workspace, self.new_workspace_name, row['name'])
        tools_qt.set_widget_text(self.dlg_create_workspace, self.new_workspace_descript, row['descript'])
        tools_qt.set_checked(self.dlg_create_workspace, self.new_workspace_chk, row['private'])

        # Open the dialog
        tools_gw.open_dialog(self.dlg_create_workspace, 'workspace_create')

    def _open_create_workspace_dlg(self):

        # Create workspace dialog
        self.dlg_create_workspace = GwCreateWorkspaceUi(self)
        self.new_workspace_name = self.dlg_create_workspace.findChild(QLineEdit, 'txt_workspace_name')
        self.new_workspace_descript = self.dlg_create_workspace.findChild(QPlainTextEdit, 'txt_workspace_descript')
        self.new_workspace_chk = self.dlg_create_workspace.findChild(QCheckBox, 'chk_workspace_private')

        # Disable tab log
        tools_gw.disable_tab_log(self.dlg_create_workspace)

        # Connect create workspace dialog signals
        self.new_workspace_name.textChanged.connect(partial(self._check_exists))
        self.dlg_create_workspace.btn_accept.clicked.connect(partial(self._create_workspace))
        self.dlg_create_workspace.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_create_workspace))

        # Open the dialog
        tools_gw.open_dialog(self.dlg_create_workspace, 'workspace_create')

    def _get_list(self, table_name='v_ui_workspace', filter_name=""):
        """ Mount and execute the query for gw_fct_getlist """

        extras = f'"tableName":"{table_name}"'
        filter_fields = f'"limit": -1, "name": {{"filterSign":"ILIKE", "value":"{filter_name}"}}'
        body = tools_gw.create_body(filter_fields=filter_fields, extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_getlist', body)
        if json_result is None or json_result['status'] == 'Failed':
            return False
        complet_list = json_result
        if not complet_list:
            return False

        return complet_list

    def _fill_tbl(self, filter_name=""):
        """ Fill table with initial data into QTableView """

        complet_list = self._get_list("v_ui_workspace", filter_name)

        if complet_list is False:
            return False, False
        data = complet_list['body']['data']
        headers = complet_list['body']['form'].get('headers')
        fields = data['fields']
        if data.get('hidden'):
            return False
        model = self.tbl_wrkspcm.model()
        if model is None:
            model = QStandardItemModel()
            self.tbl_wrkspcm.setModel(model)
        model.removeRows(0, model.rowCount())

        if fields:
            self.tbl_wrkspcm = tools_gw.add_tableview_header(self.tbl_wrkspcm, fields, headers)
            self.tbl_wrkspcm = tools_gw.fill_tableview_rows(self.tbl_wrkspcm, fields)
        tools_gw.set_tablemodel_config(self.dlg_workspace_manager, self.tbl_wrkspcm, 'tbl_workspace_manager')
        tools_qt.set_tableview_config(self.tbl_wrkspcm, selection_mode=QAbstractItemView.SelectionMode.SingleSelection)

        return complet_list

    def _fill_info(self, selected, deselected):
        """
        Fill info text area with details from selected workspace.

        Note: The parameters come from the selectionChanged signal.
        """

        # Get id of selected workspace
        cols = selected.indexes()
        if not cols:
            if deselected.indexes():
                self.dlg_workspace_manager.tbl_wrkspcm.selectionModel().select(deselected, QItemSelectionModel.SelectionFlag.Select)
                return
            tools_qt.set_widget_text(self.dlg_workspace_manager, 'tab_log_txt_infolog', "")
            return
        col_ind = tools_qt.get_col_index_by_col_name(self.dlg_workspace_manager.tbl_wrkspcm, 'id')
        workspace_id = json.loads(cols[col_ind].data())

        action = "INFO"
        extras = f'"action":"{action}", "id":"{workspace_id}"'
        body = tools_gw.create_body(extras=extras)
        result = tools_gw.execute_procedure('gw_fct_workspacemanager', body)

        if result and result['status'] == "Accepted":
            tools_gw.fill_tab_log(self.dlg_workspace_manager, result['body']['data'],
                                  force_tab=False, call_set_tabs_enabled=False, close=False)

    def _create_workspace(self):
        """ Create a workspace """

        name = self.new_workspace_name.text()
        descript = self.new_workspace_descript.toPlainText()
        if descript == '':
            descript = 'null'
        else:
            descript = f'"{descript}"'
            descript = descript.replace("\n", "\\n")
        if len(name) == 0:
            tools_qt.set_stylesheet(self.new_workspace_name)
            return
        private = self.new_workspace_chk.isChecked()
        action = "CREATE"

        extras = f'"action":"{action}", "name":"{name}", "descript":{descript}, "private":"{private}"'
        body = tools_gw.create_body(extras=extras)
        result = tools_gw.execute_procedure('gw_fct_workspacemanager', body)

        if result and result['status'] == "Accepted":
            tools_gw.fill_tab_log(self.dlg_create_workspace, result['body']['data'])
            self._fill_tbl(self.filter_name.text())
            self._set_labels_current_workspace(dialog=self.dlg_workspace_manager)

    def _set_labels_current_workspace(self, dialog, result=None):
        """Set label for the current workspace."""

        # Prepare the JSON body to get the current workspace information
        extras = '"type": "workspace"'
        body = tools_gw.create_body(extras=extras)

        # Execute the stored procedure to retrieve the current workspace information
        result = tools_gw.execute_procedure("gw_fct_set_toggle_current", body)

        # Check if the stored procedure returned a successful status
        if result.get("status") != "Accepted":
            print("Failed to retrieve current workspace name")
            return

        try:
            name_value = result["body"]["data"]["name"]
            tools_qt.set_widget_text(dialog, 'lbl_vdefault_workspace', name_value)

            cur_workspace = tools_gw.get_config_value('utils_workspace_current')
            enabled = bool(cur_workspace and cur_workspace[0] is not None)

            if self.workspace_with_current is None and lib_vars.plugin_dir:
                self.icon_folder = f"{lib_vars.plugin_dir}{os.sep}icons{os.sep}dialogs{os.sep}"
                self.workspace_with_current = QPixmap(f"{self.icon_folder}140.png")
                self.workspace_without_current = QPixmap(f"{self.icon_folder}138.png")
            if self.workspace_with_current:
                if enabled:
                    dialog.lbl_status_current.setPixmap(self.workspace_with_current)
                else:
                    dialog.lbl_status_current.setPixmap(self.workspace_without_current)
        except KeyError:
            print("Error: 'name' field is missing in the result")

    def _set_current_workspace(self):
        """ Set the selected workspace as the current one """

        action = "CURRENT"

        # Get selected row
        selected_list = self.tbl_wrkspcm.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_workspace_manager)
            return

        # Get selected workspace id
        index = self.tbl_wrkspcm.selectionModel().currentIndex()
        value = index.sibling(index.row(), 0).data()

        extras = f'"action":"{action}", "id": "{value}"'
        body = tools_gw.create_body(extras=extras)
        result = tools_gw.execute_procedure('gw_fct_workspacemanager', body)

        if result and result.get('message') and result['message'].get('text'):
            msg = result["message"].get('text')
            tools_qgis.show_message(msg, Qgis.MessageLevel(result["message"].get('level')), dialog=self.dlg_workspace_manager)

        if result and result['status'] == "Accepted":
            # Set labels
            self._set_labels_current_workspace(dialog=self.dlg_workspace_manager)

            # Refresh all the layers
            tools_qgis.refresh_map_canvas()
            # Refresh the map view itself
            global_vars.iface.mapCanvas().refresh()

            # Zoom to layer
            layer = tools_qgis.get_layer_by_tablename('ve_inp_junction')
            if not layer:
                layer = tools_qgis.get_layer_by_tablename('ve_node')
            tools_qgis.zoom_to_layer(layer)

            # Refresh selector docker if open
            tools_gw.refresh_selectors()

            # Refresh go2epa options
            self._check_go2epa_options()

    def _check_go2epa_options(self, tab_name=None):
        """ Refreshes the selectors' UI if it's open """

        # Get the selector UI if it's open
        windows = [x for x in QApplication.allWidgets() if getattr(x, "isVisible", False)
                and (issubclass(type(x), GwGo2EpaOptionsUi))]
        if windows:
            try:
                dialog = windows[0]
                go2epa = dialog.property('GwGo2EpaButton')
                go2epa._refresh_go2epa_options(go2epa.dlg_go2epa_options)
            except Exception:
                pass

    def _toggle_privacy_workspace(self):
        """ Set the selected workspace as public/private """

        action = "TOGGLE"

        # Get selected row
        selected_list = self.tbl_wrkspcm.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_workspace_manager)
            return

        # Get selected workspace id
        index = self.tbl_wrkspcm.selectionModel().currentIndex()
        value = index.sibling(index.row(), 0).data()

        extras = f'"action":"{action}", "id": "{value}"'
        body = tools_gw.create_body(extras=extras)
        result = tools_gw.execute_procedure('gw_fct_workspacemanager', body)

        if result and result['status'] == "Accepted":
            message = result.get('message')
            if message:
                msg = message['text']
                tools_qgis.show_message(msg, Qgis.MessageLevel(message['level']), dialog=self.dlg_workspace_manager)
            self._fill_tbl(self.filter_name.text())

    def _update_workspace(self):
        """ Reset the values of the selected workspace """

        action = "UPDATE"

        # Get selected row
        selected_list = self.tbl_wrkspcm.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_workspace_manager)
            return

        # Get selected workspace id
        index = self.tbl_wrkspcm.selectionModel().currentIndex()
        value = index.sibling(index.row(), 0).data()

        name = self.new_workspace_name.text()
        descript = self.new_workspace_descript.toPlainText()
        if descript == '':
            descript = 'null'
        else:
            descript = f'"{descript}"'
            descript = descript.replace("\n", "\\n")
        if len(name) == 0:
            tools_qt.set_stylesheet(self.new_workspace_name)
            return
        private = self.new_workspace_chk.isChecked()

        msg = "Are you sure you want to override the configuration of this workspace?"
        title = "Update configuration"
        answer = tools_qt.show_question(msg, title, index.sibling(index.row(), 1).data())
        if answer:
            extras = f'"action":"{action}", "name":"{name}", "descript":{descript}, "private":"{private}", "id": "{value}"'
            body = tools_gw.create_body(extras=extras)
            result = tools_gw.execute_procedure('gw_fct_workspacemanager', body)

            if result and result['status'] == "Accepted":
                message = result.get('message')
                if message:
                    msg = message['text']
                    tools_qgis.show_message(msg, Qgis.MessageLevel(message['level']), dialog=self.dlg_workspace_manager)

                tools_gw.fill_tab_log(self.dlg_create_workspace, result['body']['data'])
                self._fill_tbl(self.filter_name.text())
                self._set_labels_current_workspace(dialog=self.dlg_workspace_manager)

    def _delete_workspace(self):
        """ Delete the selected workspace """

        action = "DELETE"

        # Get selected row
        selected_list = self.tbl_wrkspcm.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_workspace_manager)
            return

        # Get selected workspace id
        index = self.tbl_wrkspcm.selectionModel().currentIndex()
        value = index.sibling(index.row(), 0).data()

        msg = "Are you sure you want to delete these records?"
        sql = "SELECT value FROM config_param_user WHERE parameter='utils_workspace_current' AND cur_user = current_user"
        row = tools_db.get_row(sql)
        if row and row[0]:
            if row[0] == f'{value}':
                msg = ("WARNING: This will remove the 'utils_workspace_current' variable for your user!\n"
                        "Are you sure you want to delete these records?")

        title = "Delete records"
        answer = tools_qt.show_question(msg, title, index.sibling(index.row(), 1).data())
        if answer:
            extras = f'"action":"{action}", "id": "{value}"'
            body = tools_gw.create_body(extras=extras)
            result = tools_gw.execute_procedure('gw_fct_workspacemanager', body)

            if result and result['status'] == "Accepted":
                message = result.get('message')
                if message:
                    msg = message['text']
                    tools_qgis.show_message(msg, Qgis.MessageLevel(message['level']), dialog=self.dlg_workspace_manager)

            self._fill_tbl(self.filter_name.text())
            self._set_labels_current_workspace(dialog=self.dlg_workspace_manager)

    def _check_exists(self, name=""):
        sql = f"SELECT name FROM cat_workspace WHERE name = '{name}'"
        row = tools_db.get_row(sql, log_info=False)
        if row:
            self.dlg_create_workspace.btn_accept.setEnabled(False)
            tools_qt.set_stylesheet(self.new_workspace_name)
            self.new_workspace_name.setToolTip("Workspace already exists")
            return
        self.dlg_create_workspace.btn_accept.setEnabled(True)
        tools_qt.set_stylesheet(self.new_workspace_name, style="")
        self.new_workspace_name.setToolTip("")

    # endregion
