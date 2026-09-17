"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial
from qgis.PyQt.sip import isdeleted
import json

from qgis.core import QgsProject
from qgis.PyQt.QtGui import QRegularExpressionValidator, QStandardItemModel, QCursor
from qgis.PyQt.QtSql import QSqlTableModel
from qgis.PyQt.QtCore import Qt, QRegularExpression, QPoint
from qgis.PyQt.QtWidgets import QTableView, QAbstractItemView, QMenu, QCheckBox, QWidgetAction, QComboBox, QAction, QPushButton, QHeaderView
from qgis.PyQt.QtWidgets import QLineEdit

from ..dialog import GwAction
from ..utilities.toolbox_btn import GwToolBoxButton
from ..utilities.utilities_manager.mapzone_manager import GwMapzoneManager
from ...ui.ui_manager import GwNetscenarioManagerUi, GwNetscenarioUi, GwInfoGenericUi
from ...utils import tools_gw
from .... import global_vars
from ....libs import lib_vars, tools_qgis, tools_qt, tools_db, tools_os


class GwNetscenarioManagerButton(GwAction):
    """ Button 53: Netscenario manager """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.feature_type = 'node'
        self.feature_types = ['node_id', 'arc_id', 'feature_id', 'connec_id', 'dma_id', 'presszone_id']
        self.filter_dict = {"plan_netscenario_arc": {"filter_table": "ve_arc", "feature_type": "arc"},
                            "plan_netscenario_node": {"filter_table": "ve_node", "feature_type": "node"},
                            "plan_netscenario_connec": {"filter_table": "ve_inp_connec", "feature_type": "connec"},
                            "ve_plan_netscenario_dma": {"filter_table": "ve_dma", "feature_type": "dma"},
                            "ve_plan_netscenario_presszone": {"filter_table": "ve_presszone", "feature_type": "presszone"},
                            "plan_netscenario_valve": {"filter_table": "man_valve", "feature_type": "node"},
                            }
        self.filter_disabled = []
        self.rubber_band = tools_gw.create_rubberband(global_vars.canvas)

    def clicked_event(self):
        self._open_netscenario_manager()

    def _open_netscenario_manager(self):
        """ Open netscenario manager """

        # Main dialog
        self.dlg_netscenario_manager = GwNetscenarioManagerUi(self)
        tools_gw.load_settings(self.dlg_netscenario_manager)

        tools_gw.add_icon(self.dlg_netscenario_manager.btn_toc, "164")
        tools_gw.add_icon(self.dlg_netscenario_manager.btn_execute, "169")

        # Manage btn create
        self._manage_btn_create()

        # Apply filter validator
        self.filter_name = self.dlg_netscenario_manager.findChild(QLineEdit, 'txt_name')
        reg_exp = QRegularExpression(r'([^"\'\\\\$]|\\$(?!\\$))*')  # Don't allow " or ' or \ or $$ because it breaks the query
        self.filter_name.setValidator(QRegularExpressionValidator(reg_exp))

        # Fill table
        self.tbl_netscenario = self.dlg_netscenario_manager.findChild(QTableView, 'tbl_netscenario')
        self._fill_manager_table()
        self._set_label_current_netscenario(self.dlg_netscenario_manager, from_open_dialog=True)

        # Populate custom context menu
        self.dlg_netscenario_manager.tbl_netscenario.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.dlg_netscenario_manager.tbl_netscenario.customContextMenuRequested.connect(partial(self._show_context_menu_right_click, self.dlg_netscenario_manager.findChild(QTableView, 'tbl_netscenario')))

        # Connect main dialog signals
        self.dlg_netscenario_manager.txt_name.textChanged.connect(partial(self._fill_manager_table))
        self.dlg_netscenario_manager.btn_toc.clicked.connect(partial(self._manage_add_layers))
        self.dlg_netscenario_manager.btn_duplicate.clicked.connect(partial(self._duplicate_selected_netscenario))
        self.dlg_netscenario_manager.btn_update.clicked.connect(partial(self._manage_properties))
        self.dlg_netscenario_manager.btn_execute.clicked.connect(partial(self._execute_selected_netscenario))
        self.dlg_netscenario_manager.btn_delete.clicked.connect(partial(self._delete_selected_netscenario))
        self.dlg_netscenario_manager.btn_delete.clicked.connect(partial(tools_gw.refresh_selectors))
        self.tbl_netscenario.doubleClicked.connect(self._open_netscenario)
        self.dlg_netscenario_manager.btn_update_netscenario.clicked.connect(
            partial(self._update_current_netscenario, self.dlg_netscenario_manager, self.tbl_netscenario))

        self.dlg_netscenario_manager.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_netscenario_manager))
        self.dlg_netscenario_manager.finished.connect(partial(tools_gw.save_settings, self.dlg_netscenario_manager))
        self.dlg_netscenario_manager.finished.connect(partial(self.save_user_values))

        self.dlg_netscenario_manager.chk_active.stateChanged.connect(partial(self._fill_manager_table))
        self.dlg_netscenario_manager.btn_toggle_active.clicked.connect(partial(self._manage_toggle_active,
            self.tbl_netscenario, 'plan_netscenario', is_manager=True))

        # Open dialog
        tools_gw.open_dialog(self.dlg_netscenario_manager, 'netscenario_manager')

    def _show_context_menu_right_click(self, qtableview, pos):
        """ Show custom context menu """
        menu = QMenu(qtableview)

        action_open = QAction("Open", qtableview)
        action_open.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QTableView, qtableview.objectName(), pos))
        menu.addAction(action_open)

        action_current = QAction("Current netscenario", qtableview)
        action_current.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_update_netscenario"))
        menu.addAction(action_current)

        action_toggle = QAction("Toggle active", qtableview)
        action_toggle.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_toggle_active"))
        menu.addAction(action_toggle)

        action_execute = QAction("Execute", qtableview)
        action_execute.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_execute"))
        menu.addAction(action_execute)

        action_duplicate = QAction("Duplicate", qtableview)
        action_duplicate.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_duplicate"))
        menu.addAction(action_duplicate)

        action_update = QAction("Update", qtableview)
        action_update.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_update"))
        menu.addAction(action_update)

        action_delete = QAction("Delete", qtableview)
        action_delete.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_delete"))
        menu.addAction(action_delete)

        menu.exec(QCursor.pos())

    def _filter_table(self, dialog, table, widget_txt, widget_chk, tablename):

        result_select = tools_qt.get_text(dialog, widget_txt)
        inactive_select = widget_chk.isChecked()

        expr = ""

        if not inactive_select:
            expr += " active is true"

        if result_select != 'null':
            if expr != "":
                expr += " AND "
            expr += f" name ILIKE '%{result_select}%'"
        if expr != "":
            # Refresh model with selected filter
            table.model().setFilter(expr)
            table.model().select()
        else:
            self.fill_table(dialog, table, tablename)

    def _update_current_netscenario(self, dialog, qtbl):
        """ Update the current netscenario if it is active and refresh label """

        # Get selected rows in the table
        selected_list = qtbl.selectionModel().selectedRows()

        # Ensure a row is selected
        if not selected_list:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        # Get ID and active status of the first selected row
        row = selected_list[0].row()
        model = qtbl.model()
        col_id = tools_qt.get_col_index_by_col_name(qtbl, 'netscenario_id')
        col_active = tools_qt.get_col_index_by_col_name(qtbl, 'active')
        netscenario_id = model.index(row, col_id).data()
        active = model.index(row, col_active).data()

        # Check if the current netscenario is already set, and skip toggle if so
        row_current_netscenario = tools_gw.get_config_value('plan_netscenario_current')
        if row_current_netscenario and row_current_netscenario[0] == netscenario_id:
            return

        # Check if the netscenario is active
        if not active:
            msg = "Cannot set the current netscenario of an inactive scenario. Please activate it first."
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        # Prepare JSON body for gw_fct_set_toggle_current
        extras = f'"type": "netscenario", "id": "{netscenario_id}"'
        body = tools_gw.create_body(extras=extras)
        result = tools_gw.execute_procedure("gw_fct_set_toggle_current", body)

        # Check if update was successful and refresh label
        if result.get("status") == "Accepted":
            # Refresh the label with the latest netscenario data
            self._set_label_current_netscenario(dialog, result=result)
        else:
            msg = "Failed to set netscenario"
            tools_qgis.show_warning(msg, dialog=dialog)

        # Re-open the dialog to reflect the changes
        tools_gw.open_dialog(dialog, dlg_name='netscenario_manager')

    def _set_label_current_netscenario(self, dialog, from_open_dialog=False, result=None):
        """Set label for the current netscenario."""

        # Fetch the current netscenario if called from open dialog
        if from_open_dialog:
            extras = '"type": "netscenario"'
            body = tools_gw.create_body(extras=extras)
            result = tools_gw.execute_procedure("gw_fct_set_toggle_current", body)

            if not result or result.get("status") != "Accepted":
                print("Failed to retrieve current netscenario name")
                return

        # Ensure result has the necessary data
        try:
            # Extract name and netscenario_id from the result
            name_value = result["body"]["data"]["name"]
            netscenario_id = result["body"]["data"]["netscenario_id"]  # noqa: F841

            # Set the label text
            tools_qt.set_widget_text(dialog, 'lbl_vdefault_netscenario', name_value)

        except (KeyError, TypeError) as e:
            print(f"Error accessing netscenario data: {e}")
            return

    # region netscenario manager

    def save_user_values(self):
        pass

    def _get_list(self, table_name='v_ui_plan_netscenario', filter_name="", filter_id=None, chk_active=False):
        """ Mount and execute the query for gw_fct_getlist """

        extras = f'"tableName":"{table_name}"'
        filter_fields = f'"limit": -1, "name": {{"filterSign":"ILIKE", "value":"{filter_name}"}}'
        if filter_id is not None:
            filter_fields += f', "netscenario_id": {{"filterSign":"=", "value":"{filter_id}"}}'
        if chk_active is False:
            filter_fields += ', "active": {"filterSign":"=", "value":true}'

        body = tools_gw.create_body(filter_fields=filter_fields, extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_getlist', body)
        if json_result is None or json_result['status'] == 'Failed':
            return False
        complet_list = json_result
        if not complet_list:
            return False

        return complet_list

    def _fill_manager_table(self):
        """ Fill netscenario manager table with data from v_ui_plan_netscenario """

        filter_name = self.filter_name.text()
        chk_active = self.dlg_netscenario_manager.chk_active.isChecked()

        complet_list = self._get_list("v_ui_plan_netscenario", filter_name, chk_active=chk_active)

        if complet_list is False:
            return False, False
        data = complet_list['body']['data']
        headers = complet_list['body']['form'].get('headers')
        fields = data['fields']
        if data.get('hidden'):
            return False, False
        model = self.tbl_netscenario.model()
        if model is None:
            model = QStandardItemModel()
            self.tbl_netscenario.setModel(model)
        model.removeRows(0, model.rowCount())

        if fields:
            self.tbl_netscenario = tools_gw.add_tableview_header(self.tbl_netscenario, fields, headers)
            self.tbl_netscenario = tools_gw.fill_tableview_rows(self.tbl_netscenario, fields)
        tools_gw.set_tablemodel_config(self.dlg_netscenario_manager, self.tbl_netscenario, 'v_ui_plan_netscenario', Qt.SortOrder.DescendingOrder)
        tools_qt.set_tableview_config(self.tbl_netscenario)

        return complet_list

    def _manage_btn_create(self):
        """ Fill btn_create QMenu """

        # Functions
        values = [[3260, "Create empty Netscenario"], [3262, "Create Netscenario from ToC"]]

        # Create and populate QMenu
        create_menu = QMenu()
        for value in values:
            num = value[0]
            label = value[1]
            action = create_menu.addAction(f"{label}")
            action.triggered.connect(partial(self._open_toolbox_function, num))

        self.dlg_netscenario_manager.btn_create.setMenu(create_menu)

    def _open_toolbox_function(self, function, signal=None, connect=None):
        """ Execute currently selected function from combobox """

        toolbox_btn = GwToolBoxButton(None, None, None, None, None)
        if connect is None:
            connect = [partial(self._fill_manager_table), partial(tools_gw.refresh_selectors)]
        else:
            if type(connect) is not list:
                connect = [connect]
        dlg_functions = toolbox_btn.open_function_by_id(function, connect_signal=connect)
        return dlg_functions

    def _duplicate_selected_netscenario(self):
        """ Duplicates the selected netscenario """

        # Get selected row
        selected_list = self.tbl_netscenario.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_netscenario_manager)
            return

        # Get selected netscenario id
        index = self.tbl_netscenario.selectionModel().currentIndex()
        col_idx = tools_qt.get_col_index_by_col_name(self.tbl_netscenario, 'netscenario_id')
        value = index.sibling(index.row(), col_idx).data()

        # Execute toolbox function
        dlg_functions = self._open_toolbox_function(3264)
        # Set netscenario_id in combo copyFrom
        tools_qt.set_combo_value(dlg_functions.findChild(QComboBox, 'copyFrom'), f"{value}", 0)
        tools_qt.set_widget_enabled(dlg_functions, 'copyFrom', False)

    def _execute_selected_netscenario(self):
        """ Executes the selected netscenario """
        # Get selected row
        selected_list = self.tbl_netscenario.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_netscenario_manager)
            return

        # Get selected netscenario id
        index = self.tbl_netscenario.selectionModel().currentIndex()
        netscenario_col_idx = tools_qt.get_col_index_by_col_name(self.tbl_netscenario, 'netscenario_id')
        exploitation_col_idx = tools_qt.get_col_index_by_col_name(self.tbl_netscenario, 'expl_id')
        netscenario_value = index.sibling(index.row(), netscenario_col_idx).data()
        exploitation_value = index.sibling(index.row(), exploitation_col_idx).data()

        # Execute toolbox function
        connect = [
            partial(self._update_current_netscenario, self.dlg_netscenario_manager, self.tbl_netscenario),
            partial(self._fill_manager_table),
            partial(tools_gw.refresh_selectors)
        ]
        dlg_functions = self._open_toolbox_function(3256, connect=connect)
        # Set netscenario_id in combo netscenario
        tools_qt.set_combo_value(dlg_functions.findChild(QComboBox, 'netscenario'), f"{netscenario_value}", 0)
        tools_qt.set_widget_enabled(dlg_functions, 'netscenario', False)
        tools_qt.set_combo_value(dlg_functions.findChild(QComboBox, 'exploitation'), f"{exploitation_value}", 0)
        tools_qt.set_widget_enabled(dlg_functions, 'exploitation', False)

    def _delete_selected_netscenario(self):
        """ Deletes the selected netscenario """

        # Get selected row
        selected_list = self.tbl_netscenario.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_netscenario_manager)
            return

        # Get selected netscenario ids
        col_idx = tools_qt.get_col_index_by_col_name(self.tbl_netscenario, 'netscenario_id')
        values = [index.sibling(index.row(), col_idx).data() for index in selected_list]

        msg = ("CAUTION! Deleting a netscenario will delete data from features related to the netscenario.\n"
                  "Are you sure you want to delete these records?")
        title = "Delete records"
        answer = tools_qt.show_question(msg, title, values, force_action=True)
        if answer:
            # Build WHERE IN clause for SQL
            where_clause = f"netscenario_id IN ({', '.join(map(str, values))})"

            # Construct SQL DELETE statement
            sql = f"DELETE FROM plan_netscenario WHERE {where_clause}"
            tools_db.execute_sql(sql)

            # Refresh the tableview
            self._fill_manager_table()

    # endregion

    # region netscenario

    def _open_netscenario(self, index):
        """ Create custom dialog for selected netscenario and fill initial table """

        # Check if there are selected rows
        selected_list = self.tbl_netscenario.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_netscenario_manager)
            return

        # Get selected netscenario_id
        row = index.row()
        column_index = tools_qt.get_col_index_by_col_name(self.tbl_netscenario, 'netscenario_id')
        self.selected_netscenario_id = index.sibling(row, column_index).data()
        column_index = tools_qt.get_col_index_by_col_name(self.tbl_netscenario, 'netscenario_type')
        self.selected_netscenario_type = index.sibling(row, column_index).data()

        # Create dialog
        self.dlg_netscenario = GwNetscenarioUi(self)
        tools_gw.load_settings(self.dlg_netscenario)

        # Add icons
        tools_gw.add_icon(self.dlg_netscenario.btn_insert, "111")
        # tools_gw.add_icon(self.dlg_netscenario.btn_delete, "112")
        tools_gw.add_icon(self.dlg_netscenario.btn_snapping, "137")
        tools_gw.add_icon(self.dlg_netscenario.btn_expr_select, "178")

        default_tab_idx = 0
        # Select all netscenario views
        sql = f"SELECT table_name FROM INFORMATION_SCHEMA.tables WHERE table_schema = '{lib_vars.schema_name}' " \
              f"AND table_name IN ('plan_netscenario_arc', 'plan_netscenario_node', 'plan_netscenario_connec', 'plan_netscenario_{self.selected_netscenario_type.lower()}', 'plan_netscenario_valve') " \
              f"ORDER BY array_position(ARRAY['plan_netscenario_arc', 'plan_netscenario_node', 'plan_netscenario_connec'], table_name::text);"
        rows = tools_db.get_rows(sql)
        if rows:
            views = [x[0] for x in rows]
            for view in views:
                qtableview = QTableView()
                qtableview.setObjectName(f"tbl_{view}")
                qtableview.clicked.connect(partial(self._manage_highlight, qtableview, view))
                tab_idx = self.dlg_netscenario.main_tab.addTab(qtableview, f"{view.split('_')[-1].capitalize()}")
                self.dlg_netscenario.main_tab.widget(tab_idx).setObjectName(view)
                if view not in ('plan_netscenario_arc', 'plan_netscenario_node', 'plan_netscenario_connec', 'plan_netscenario_valve'):
                    qtableview.doubleClicked.connect(partial(self._manage_update))
                if view.split('_')[-1].upper() == self.selected_netscenario_type:
                    default_tab_idx = tab_idx

        self.dlg_netscenario.main_tab.setCurrentIndex(default_tab_idx)

        # Connect signals
        self.dlg_netscenario.btn_config.clicked.connect(partial(self._manage_config))
        self.dlg_netscenario.btn_toggle_active.clicked.connect(partial(self._manage_toggle_active, None, None, False))
        self.dlg_netscenario.btn_toggle_closed.clicked.connect(partial(self._manage_toggle_closed))
        self.dlg_netscenario.btn_create.clicked.connect(partial(self._manage_create))
        self.dlg_netscenario.btn_update.clicked.connect(partial(self._manage_update))
        self.dlg_netscenario.btn_insert.clicked.connect(partial(self._manage_insert, None))
        self.dlg_netscenario.btn_delete.clicked.connect(partial(self._manage_delete))
        self.dlg_netscenario.btn_snapping.clicked.connect(partial(self._manage_select))
        self.dlg_netscenario.btn_expr_select.clicked.connect(partial(self._select_with_expression_dialog))
        self.dlg_netscenario.main_tab.currentChanged.connect(partial(self._manage_current_changed))
        self.dlg_netscenario.finished.connect(self._selection_end)
        self.dlg_netscenario.finished.connect(partial(tools_gw.close_dialog, self.dlg_netscenario, True))

        self._manage_current_changed()

        sql = f"SELECT name FROM plan_netscenario WHERE netscenario_id = {self.selected_netscenario_id}"
        row = tools_db.get_row(sql)
        netscenario_name = row[0]
        title = f"Netscenario {self.selected_netscenario_id} - {netscenario_name}"
        tools_gw.open_dialog(self.dlg_netscenario, 'netscenario', title=f"{title}")

    def _fill_netscenario_table(self, set_edit_triggers=QTableView.EditTrigger.NoEditTriggers, expr=None):
        """ Fill netscenario table with data from its corresponding table """

        # Manage exception if dialog is closed
        if isdeleted(self.dlg_netscenario):
            return

        self.table_name = f"{self.dlg_netscenario.main_tab.currentWidget().objectName()}"
        widget = self.dlg_netscenario.main_tab.currentWidget()
        netscenario_type = self.selected_netscenario_type.lower()

        if self.schema_name not in self.table_name:
            self.table_name = self.schema_name + "." + self.table_name

        # Set model
        model = QSqlTableModel(db=lib_vars.qgis_db_credentials)
        model.setTable(self.table_name)
        filter_str = f"netscenario_id = {self.selected_netscenario_id}"
        if 'valve' not in self.table_name:
            filter_str += f" AND {netscenario_type}_id::text NOT IN ('-1', '0')"
        model.setFilter(filter_str)
        model.setEditStrategy(QSqlTableModel.EditStrategy.OnFieldChange)
        model.setSort(0, Qt.SortOrder.AscendingOrder)
        model.select()

        # Check for errors
        if model.lastError().isValid():
            if 'Unable to find table' in model.lastError().text():
                tools_db.reset_qsqldatabase_connection(self.dlg_netscenario)
            else:
                tools_qgis.show_warning(model.lastError().text(), dialog=self.dlg_netscenario)
        # Attach model to table view
        if expr:
            widget.setModel(model)
            widget.model().setFilter(expr)
        else:
            widget.setModel(model)
        widget.setSortingEnabled(True)

        # Set widget & model properties
        tools_qt.set_tableview_config(widget, selection=QAbstractItemView.SelectionBehavior.SelectRows, edit_triggers=set_edit_triggers, section_resize_mode=QHeaderView.ResizeMode.Interactive)
        tools_gw.set_tablemodel_config(self.dlg_netscenario, widget, f"{self.table_name[len(f'{self.schema_name}.'):]}")

        # Hide unwanted columns
        col_idx = tools_qt.get_col_index_by_col_name(widget, 'netscenario_id')
        if col_idx not in (None, False):
            widget.setColumnHidden(col_idx, True)

        geom_col_idx = tools_qt.get_col_index_by_col_name(widget, 'the_geom')
        if geom_col_idx not in (None, False):
            widget.setColumnHidden(geom_col_idx, True)

        # Sort the table by feature id
        model.sort(1, Qt.SortOrder.AscendingOrder)

    def _manage_current_changed(self):
        """ Manages tab changes """

        # Fill current table
        self._fill_netscenario_table()

        # Refresh cmb_feature_id
        tools_qt.set_combo_value(self.dlg_netscenario.cmb_feature_id, '', 0, False)

        # Manage insert typeahead
        # Get index of selected tab
        index_tab = self.dlg_netscenario.main_tab.currentIndex()
        tab_name = self.dlg_netscenario.main_tab.widget(index_tab).objectName()
        enable = tab_name not in self.filter_disabled

        # Populate typeahead
        if enable:
            self._manage_feature_type()
            table_name = f"ve_{tab_name.replace('plan_netscenario_', '').replace('ve_', '')}"
            feature_type = self.feature_type
            if self.filter_dict.get(tab_name):
                table_name = self.filter_dict[tab_name]['filter_table']
                feature_type = self.filter_dict[tab_name]['feature_type']
            sql = f"SELECT DISTINCT({feature_type}_id::text) as id, {feature_type}_id::text as idval" \
                  f" FROM {table_name}" \
                  f" WHERE {feature_type}_id::text NOT IN ('-1', '0')" \
                  f" ORDER BY id"
            rows = tools_db.get_rows(sql)
            tools_qt.fill_combo_values(self.dlg_netscenario.cmb_feature_id, rows, add_empty=True)

        # Deactivate btn_snapping functionality
        self._selection_end()

        # Enable/disable filter & buttons
        self._enable_widgets(enable)

    def _enable_widgets(self, enable):
        """  """

        # Get index of selected tab
        index_tab = self.dlg_netscenario.main_tab.currentIndex()
        tab_name = self.dlg_netscenario.main_tab.widget(index_tab).objectName()

        widget_names = ['cmb_feature_id', 'btn_insert', 'btn_delete', 'btn_snapping', 'btn_expr_select', 'btn_config', 'btn_create', 'btn_update', 'btn_toggle_active']

        for name in widget_names:
            tools_qt.set_widget_enabled(self.dlg_netscenario, name, enable)

        disabled_widgets = {
            'plan_netscenario_arc': ['cmb_feature_id', 'btn_insert', 'btn_delete', 'btn_snapping', 'btn_expr_select', 'btn_config', 'btn_create', 'btn_update', 'btn_toggle_active'],
            'plan_netscenario_node': ['cmb_feature_id', 'btn_insert', 'btn_delete', 'btn_snapping', 'btn_expr_select', 'btn_config', 'btn_create', 'btn_update', 'btn_toggle_active'],
            'plan_netscenario_connec': ['cmb_feature_id', 'btn_insert', 'btn_delete', 'btn_snapping', 'btn_expr_select', 'btn_config', 'btn_create', 'btn_update', 'btn_toggle_active'],
            'plan_netscenario_valve': ['btn_config', 'btn_create', 'btn_update', 'btn_toggle_active']
        }
        if tab_name in disabled_widgets:
            for name in disabled_widgets[tab_name]:
                tools_qt.set_widget_enabled(self.dlg_netscenario, name, False)

        if tab_name == 'plan_netscenario_valve':
            tools_qt.set_widget_visible(self.dlg_netscenario, 'btn_toggle_active', False)
            tools_qt.set_widget_visible(self.dlg_netscenario, 'btn_toggle_closed', True)
            msg = "Node id:"
            tools_qt.set_widget_text(self.dlg_netscenario, 'lbl_mapzone_id', msg)
        else:
            tools_qt.set_widget_visible(self.dlg_netscenario, 'btn_toggle_active', True)
            tools_qt.set_widget_visible(self.dlg_netscenario, 'btn_toggle_closed', False)
            msg = "{0} id:"
            msg_params = (self.selected_netscenario_type.capitalize(),)
            tools_qt.set_widget_text(self.dlg_netscenario, 'lbl_mapzone_id', msg, msg_params)

    def _manage_feature_type(self):
        """ Manages current tableview feature type (node, arc, nodarc, etc.) """

        tableview = self.dlg_netscenario.main_tab.currentWidget()
        self.feature_type = 'node'
        feature_type = 'feature_id'

        for x in self.feature_types:
            col_idx = tools_qt.get_col_index_by_col_name(tableview, x)
            if col_idx not in (None, False):
                feature_type = x
                break

        if feature_type != 'feature_id':
            self.feature_type = feature_type.split('_')[0]

    def _manage_highlight(self, qtableview, view, index):
        """ Creates rubberband to indicate which feature is selected """

        feature_type = 'feature_id'

        for x in self.feature_types:
            col_idx = tools_qt.get_col_index_by_col_name(qtableview, x)
            if col_idx not in (None, False):
                feature_type = x
                break

        table = f"ve_{view}"
        tools_qgis.highlight_feature_by_id(qtableview, table, feature_type, self.rubber_band, 5, index)

    def _manage_config(self):
        self.mapzone_manager = GwMapzoneManager()
        self.mapzone_manager.netscenario_id = self.selected_netscenario_id
        self.mapzone_manager.manage_config(self.dlg_netscenario)
        try:
            self.mapzone_manager.config_dlg.finished.connect(partial(self._manage_current_changed))
        except Exception:
            pass

    def _manage_create(self):
        self.mapzone_manager = GwMapzoneManager()
        self.mapzone_manager.netscenario_id = self.selected_netscenario_id
        self.mapzone_manager.manage_create(
            self.dlg_netscenario, on_close=partial(self._manage_current_changed))

    def _manage_update(self):
        self.mapzone_manager = GwMapzoneManager()
        self.mapzone_manager.netscenario_id = self.selected_netscenario_id
        self.mapzone_manager.manage_update(
            self.dlg_netscenario, on_close=partial(self._manage_current_changed))

    def _manage_toggle_active(self, tableview, view, is_manager):

        # Get selected row
        if tableview is None and view is None:
            tableview = self.dlg_netscenario.main_tab.currentWidget()
            view = tableview.objectName().replace('tbl_', '')

        selected_list = tableview.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_netscenario_manager)
            return

        for index in selected_list:

            col_idx = tools_qt.get_col_index_by_col_name(tableview, 'netscenario_id')
            netscenario_id = index.sibling(index.row(), col_idx).data()
            active = index.sibling(index.row(), tools_qt.get_col_index_by_col_name(tableview, 'active')).data()
            active = tools_os.set_boolean(active)

            sql = f"UPDATE {view} SET active = {str(not active).lower()} WHERE netscenario_id = {netscenario_id}"

            if not is_manager:
                # Get selected mapzone data
                col_idx = tools_qt.get_col_index_by_col_name(tableview, f'{self.selected_netscenario_type.lower()}_id')
                field_id = tools_gw.get_model_column_name(tableview, col_idx)
                mapzone_id = index.sibling(index.row(), col_idx).data()

                if field_id == 'presszone_id':
                    sql += f" AND {field_id} = '{mapzone_id}'"
                else:
                    sql += f" AND {field_id} = {mapzone_id}"

            tools_db.execute_sql(sql, log_sql=True)

        # Refresh tableview
        if is_manager:
            self._fill_manager_table()
        else:
            self._manage_current_changed()

    def _manage_toggle_closed(self):
        # Get selected row
        tableview = self.dlg_netscenario.main_tab.currentWidget()
        view = tableview.objectName().replace('tbl_', '')
        selected_list = tableview.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_netscenario)
            return

        # Get selected mapzone data
        index = tableview.selectionModel().currentIndex()
        col_idx = tools_qt.get_col_index_by_col_name(tableview, 'netscenario_id')
        netscenario_id = index.sibling(index.row(), col_idx).data()
        col_idx = tools_qt.get_col_index_by_col_name(tableview, 'node_id')
        node_id = index.sibling(index.row(), col_idx).data()
        closed = index.sibling(index.row(), tools_qt.get_col_index_by_col_name(tableview, 'closed')).data()
        closed = tools_os.set_boolean(closed)

        sql = f"UPDATE {view} SET closed = {str(not closed).lower()} WHERE netscenario_id = {netscenario_id} AND node_id = '{node_id}'"
        tools_db.execute_sql(sql, log_sql=True)

        # Refresh tableview
        self._manage_current_changed()

    def _manage_properties(self):

        # Get selected row
        selected_list = self.tbl_netscenario.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_netscenario_manager)
            return

        # Get selected netscenario id
        index = self.tbl_netscenario.selectionModel().currentIndex()
        col_idx = tools_qt.get_col_index_by_col_name(self.tbl_netscenario, 'netscenario_id')
        selected_netscenario_id = index.sibling(index.row(), col_idx).data()
        # TODO: Remove these lines if not needed
        # col_idx = tools_qt.get_col_index_by_col_name(self.tbl_netscenario, 'netscenario_type')
        # selected_netscenario_type = index.sibling(index.row(), col_idx).data()
        tablename = "plan_netscenario"
        pkey = "netscenario_id"

        feature = f'"tableName":"{tablename}", "id":"{selected_netscenario_id}"'
        body = tools_gw.create_body(feature=feature)
        json_result = tools_gw.execute_procedure('gw_fct_getinfofromid', body)
        if json_result is None or json_result['status'] == 'Failed':
            return
        result = json_result

        # Build dlg
        self.props_dlg = GwInfoGenericUi(self)
        tools_gw.load_settings(self.props_dlg)
        self.my_json_add = {}
        tools_gw.build_dialog_info(self.props_dlg, result, my_json=self.my_json_add)
        # Disable widgets
        disabled_widgets = ['netscenario_id', 'log']
        for widget in disabled_widgets:
            widget_name = f"tab_none_{widget}"
            tools_qt.set_widget_enabled(self.props_dlg, widget_name, False)
        self.props_dlg.actionEdit.setVisible(False)

        # Signals
        self.props_dlg.btn_close.clicked.connect(partial(tools_gw.close_dialog, self.props_dlg))
        self.props_dlg.dlg_closed.connect(partial(tools_gw.close_dialog, self.props_dlg))
        self.props_dlg.btn_accept.clicked.connect(partial(self._accept_props_dlg, self.props_dlg, tablename, pkey,
                                                          selected_netscenario_id, self.my_json_add))

        # Open dlg
        tools_gw.open_dialog(self.props_dlg, dlg_name='info_generic')

    def _accept_props_dlg(self, dialog, tablename, pkey, feature_id, my_json):
        if not my_json:
            return

        fields = json.dumps(my_json)
        id_val = feature_id

        feature = f'"id":"{id_val}", '
        feature += f'"tableName":"{tablename}"'
        extras = f'"fields":{fields}'
        body = tools_gw.create_body(feature=feature, extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_upsertfields', body)
        if json_result and json_result.get('status') == 'Accepted':
            tools_gw.close_dialog(dialog)
            # Refresh tableview
            self._fill_manager_table()
            return
        msg = "Error"
        tools_qgis.show_warning(msg, parameter=json_result, dialog=dialog)

    def _manage_add_layers(self):
        """ Opens menu to add/remove layers to ToC """

        # Create main menu and get cursor click position
        main_menu = QMenu()
        cursor = QCursor()
        x = cursor.pos().x()
        y = cursor.pos().y()
        click_point = QPoint(x + 5, y + 5)

        layer_list = []
        for layer in QgsProject.instance().mapLayers().values():
            layer_list.append(tools_qgis.get_layer_source_table_name(layer))

        geom_layers = []
        sql = f"SELECT f_table_name FROM geometry_columns WHERE f_table_schema = '{lib_vars.schema_name}' " \
              f"AND f_table_name LIKE '%plan_netscenario%';"
        rows = tools_db.get_rows(sql)
        if rows:
            geom_layers = [row[0] for row in rows]

        # Get layers to add
        lyr_filter = "%plan_netscenario_%"
        sql = f"SELECT id, alias, addparam FROM sys_table WHERE id LIKE '{lyr_filter}' AND alias IS NOT NULL"
        rows = tools_db.get_rows(sql)
        if rows:
            # LOAD ALL
            widget = QCheckBox()
            widget.setText("Load all")
            widget.setStyleSheet("margin: 5px 5px 5px 8px;")
            widgetAction = QWidgetAction(main_menu)
            widgetAction.setDefaultWidget(widget)
            widgetAction.defaultWidget().stateChanged.connect(partial(self._manage_load_all, main_menu))
            main_menu.addAction(widgetAction)

            # LAYERS
            for tablename, alias, addparam in rows:
                # Manage alias
                if not alias:
                    alias = tablename.replace('plan_netscenario_', '').replace('_', ' ').capitalize()
                # Manage pkey
                pk = "id"
                if addparam:
                    pk = addparam.get('pkey').replace(' ', '')
                # Manage the_geom
                the_geom = None
                if tablename in geom_layers:
                    the_geom = "the_geom"

                # Create CheckBox
                widget = QCheckBox()
                widget.setText(alias)
                widgetAction = QWidgetAction(main_menu)
                widgetAction.setDefaultWidget(widget)
                main_menu.addAction(widgetAction)

                # Set checked if layer exists
                if f"{tablename}" in layer_list:
                    widget.setChecked(True)
                widget.setStyleSheet("margin: 5px 5px 5px 8px;")

                widgetAction.defaultWidget().stateChanged.connect(
                    partial(self._check_action_ischecked, tablename, the_geom, pk, -1, alias.strip()))

        main_menu.exec(click_point)

    def _check_action_ischecked(self, tablename, the_geom, pk, style_id, alias, state):
        """ Control if user check or uncheck action menu, then add or remove layer from toc
        :param tablename: Postgres table name (String)
        :param pk: Field id of the table (String)
        :param style_id: Id of the style we want to load (integer or String)
        :param state: This parameter is sent by the action itself with the trigger (Bool)
        """

        if state == 2:
            layer = tools_qgis.get_layer_by_tablename(tablename)
            if layer is None:
                tools_gw.add_layer_database(tablename, the_geom=the_geom, field_id=pk, group="MASTERPLAN", sub_group="Netscenario", alias=alias)
        elif state == 0:
            layer = tools_qgis.get_layer_by_tablename(tablename)
            if layer is not None:
                msg = "Remove layer from project?"
                title = "Warning"
                answer = tools_qt.show_question(msg, title, parameter=f"'{layer.name()}'", force_action=True)
                if answer:
                    tools_qgis.remove_layer(custom_properties={"gw_id": tablename}, group_name="MASTERPLAN", sub_group="Netscenario")

    def _manage_load_all(self, menu, state=None):

        if state == 2:
            for child in menu.actions():
                if not child.isChecked():
                    child.defaultWidget().setChecked(True)

    def _manage_insert(self, p_feature_id=None):
        """ Insert feature to netscenario via the button """

        feature_id = p_feature_id if p_feature_id is not None else self.dlg_netscenario.cmb_feature_id.lineEdit().text()
        if feature_id == '':
            msg = "Feature_id is mandatory."
            self.dlg_netscenario.cmb_feature_id.setStyleSheet("border: 1px solid red")
            tools_qgis.show_warning(msg, dialog=self.dlg_netscenario)
            return
        self.dlg_netscenario.cmb_feature_id.setStyleSheet(None)
        tableview = self.dlg_netscenario.main_tab.currentWidget()
        view = tableview.objectName()

        if view == 'plan_netscenario_dma':
            sql = f"SELECT name, pattern_id, graphconfig, the_geom, active FROM dma WHERE dma_id = '{feature_id}';"
            row = tools_db.get_row(sql)
            if not row:
                msg = "This dma doesn't exist"
                self.dlg_netscenario.cmb_feature_id.setStyleSheet("border: 1px solid red")
                tools_qgis.show_warning(msg, parameter=feature_id, dialog=self.dlg_netscenario)
                return
            dma_name = row[0]
            pattern_id = row[1]
            graphconfig = json.dumps(row[2])
            the_geom = row[3]
            active = str(row[4]).lower()
            sql = f"INSERT INTO ve_{view} (netscenario_id, name, pattern_id, graphconfig, the_geom, active) " \
                  f"VALUES ({self.selected_netscenario_id}, '{dma_name}', '{pattern_id}', $${graphconfig}$$, $${the_geom}$$, {active});"
            result = tools_db.execute_sql(sql)
        elif view == 'plan_netscenario_presszone':
            sql = f"SELECT name, head, graphconfig, the_geom, active FROM presszone WHERE presszone_id = '{feature_id}';"
            row = tools_db.get_row(sql)
            if not row:
                msg = "This presszone doesn't exist"
                self.dlg_netscenario.cmb_feature_id.setStyleSheet("border: 1px solid red")
                tools_qgis.show_warning(msg, parameter=feature_id, dialog=self.dlg_netscenario)
                return
            presszone_name = row[0]
            head = row[1]
            head_sql = "NULL" if head is None else f"'{head}'"
            graphconfig = json.dumps(row[2])
            the_geom = row[3]
            active = str(row[4]).lower()
            sql = f"INSERT INTO ve_{view} (netscenario_id, name, head, graphconfig, the_geom, active) " \
                  f"VALUES ({self.selected_netscenario_id}, '{presszone_name}', {head_sql}, $${graphconfig}$$, $${the_geom}$$, {active});"
            result = tools_db.execute_sql(sql)
        else:
            sql = f"INSERT INTO {view} VALUES ({self.selected_netscenario_id}, '{feature_id}');"
            result = tools_db.execute_sql(sql, show_exception=False)

        if p_feature_id is None:
            # Refresh tableview
            self._fill_netscenario_table()
        return result

    def _manage_delete(self):
        """ Delete features from netscenario via the button """

        tableview = self.dlg_netscenario.main_tab.currentWidget()
        # Get selected row
        selected_list = tableview.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_netscenario)
            return

        # Get selected feature_id
        view = tableview.objectName()
        col_idx = -1
        feature_type = 'feature_id'

        for x in self.feature_types:
            col_idx = tools_qt.get_col_index_by_col_name(tableview, x)
            if col_idx not in (None, False):
                feature_type = x
                break

        values = []
        for index in selected_list:
            values.append(index.sibling(index.row(), col_idx).data())

        msg = "Are you sure you want to delete these records?"
        title = "Delete records"
        answer = tools_qt.show_question(msg, title, values)
        if answer:
            for value in values:
                sql = f"DELETE FROM {view} WHERE netscenario_id = {self.selected_netscenario_id} AND {feature_type} = '{value}'"
                tools_db.execute_sql(sql)

            # Refresh tableview
            self._fill_netscenario_table()

    def _manage_select(self):
        """ Button snapping """

        self._manage_feature_type()

        # Get current layer and remove selection
        try:
            current_layer = self.iface.activeLayer()
            current_layer.removeSelection()
        except AttributeError:
            pass

        # Set active layer
        view_name = self.dlg_netscenario.main_tab.currentWidget().objectName()
        layer_name = 've_' + self.feature_type
        if self.feature_type == 'nodarc':
            layer_name = view_name.replace("netscenario_", "")
        layer = tools_qgis.get_layer_by_tablename(layer_name)
        self.iface.setActiveLayer(layer)
        tools_qgis.set_layer_visible(layer)

        # Clear feature id field
        #

        self._selection_init()
        # tools_gw.selection_init(self, self.dlg_netscenario, tableview)

    def _selection_init(self):
        """ Set canvas map tool to selection """

        tools_gw.disconnect_signal('netscenario_snapping')
        self.iface.actionSelect().trigger()
        self.connect_signal_selection_changed()

    def connect_signal_selection_changed(self):
        """ Connect signal selectionChanged """

        tools_gw.connect_signal(global_vars.canvas.selectionChanged, partial(self._manage_selection),
                                'netscenario_snapping', 'connect_signal_selection_changed_selectionChanged_manage_selection')

    def _manage_selection(self):
        """ Slot function for signal 'canvas.selectionChanged' """

        # Get feature_type and feature_id
        layer = self.iface.activeLayer()
        field_id = self.feature_type + "_id"

        # Iterate over layer
        if layer.selectedFeatureCount() > 0:
            selected_ids = []
            # Get selected features of the layer
            features = layer.selectedFeatures()
            for feature in features:
                # Append 'feature_id' into the list
                selected_ids.append(feature.attribute(field_id))

            if selected_ids:
                inserted = {f'{self.feature_type}': []}
                for f in selected_ids:
                    result = self._manage_insert(f)
                    if result:
                        inserted[f'{self.feature_type}'].append(f)
                self._fill_netscenario_table()

                self._selection_end()
                # Just select the inserted features
                tools_gw.get_expression_filter(self.feature_type, inserted, {f"{self.feature_type}": [layer]})

    def _selection_end(self):
        """ Stop selection mode """

        tools_gw.disconnect_signal('netscenario_snapping')
        tools_gw.remove_selection()
        tools_gw.reset_rubberband(self.rubber_band)
        self.iface.actionPan().trigger()

    def _select_with_expression_dialog(self):
        """Select features by expression for netscenario"""

        # Get current layer and feature type
        self._manage_feature_type()
        view_name = self.dlg_netscenario.main_tab.currentWidget().objectName()
        layer_name = 've_' + self.feature_type
        if self.feature_type == 'nodarc':
            layer_name = view_name.replace("netscenario_", "")

        # Get the layer
        layer = tools_qgis.get_layer_by_tablename(layer_name)
        if not layer:
            return

        # Set active layer
        self.iface.setActiveLayer(layer)
        tools_qgis.set_layer_visible(layer)

        # Show expression dialog
        tools_gw.select_with_expression_dialog_custom(
            self,
            self.dlg_netscenario,
            self.dlg_netscenario.main_tab.currentWidget(),
            layer_name,
            self._selection_init,
            self._selection_end
        )

    # endregion
