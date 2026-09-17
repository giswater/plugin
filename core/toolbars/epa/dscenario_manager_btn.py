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
from qgis.PyQt.QtGui import QRegularExpressionValidator, QStandardItemModel, QCursor, QKeySequence
from qgis.PyQt.QtSql import QSqlTableModel
from qgis.PyQt.QtCore import Qt, QRegularExpression, QPoint
from qgis.PyQt.QtWidgets import QTableView, QAbstractItemView, QMenu, QCheckBox, QWidgetAction, QComboBox, QAction, \
    QShortcut, QApplication, QWidget, QLabel, QGridLayout, QToolButton, QPushButton, QHeaderView
from qgis.PyQt.QtWidgets import QLineEdit

from ..dialog import GwAction
from ..utilities.toolbox_btn import GwToolBoxButton
from ...shared.nonvisual import GwNonVisual
from ...ui.ui_manager import GwDscenarioManagerUi, GwDscenarioUi, GwInfoGenericUi
from ...utils import tools_gw
from ...models.item_delegates import ReadOnlyDelegate, EditableDelegate
from .... import global_vars
from ....libs import lib_vars, tools_qgis, tools_qt, tools_db, tools_os


class GwDscenarioManagerButton(GwAction):
    """ Button 45: Dscenario manager """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.feature_type = 'node'
        self.feature_types = ['element_id', 'node_id', 'arc_id', 'feature_id', 'connec_id', 'nodarc_id', 'rg_id', 'poll_id', 'sector_id', 'lidco_id', 'pattern_id']
        self.filter_dict = {"inp_dscenario_controls": {"filter_table": "ve_sector", "feature_type": "sector"},
                            "inp_dscenario_rules": {"filter_table": "ve_sector", "feature_type": "sector"},
                            "inp_dscenario_demand": {"filter_table": ["ve_inp_junction", "ve_inp_connec"], "feature_type": ["node", "connec"]},
                            "inp_dscenario_raingage": {"filter_table": "ve_raingage", "feature_type": "rg"},
                            # DISABLED:
                            # "inp_dscenario_lids": {"filter_table": "ve_inp_dscenario_lids", "feature_type": "lidco"},
                            # "inp_dscenario_inflows": {"filter_table": "ve_inp_inflows", "feature_type": "node"},
                            # "inp_dscenario_treatment": {"filter_table": "ve_inp_treatment", "feature_type": "node"},
                            # "inp_dscenario_flwreg_pump": {"filter_table": "ve_inp_pump", "feature_type": "arc"},
                            # "inp_dscenario_flwreg_weir": {"filter_table": "ve_inp_weir", "feature_type": "arc"},
                            # "inp_dscenario_flwreg_orifice": {"filter_table": "ve_inp_orifice", "feature_type": "arc"},
                            # "inp_dscenario_flwreg_outlet": {"filter_table": "ve_inp_outlet", "feature_type": "arc"},
                            # "inp_dscenario_inflows_poll": {"filter_table": "ve_inp_inflows_poll", "feature_type": "poll"},
                            }
        self.filter_disabled = ["inp_dscenario_lids", "inp_dscenario_inflows", "inp_dscenario_treatment",
                                "inp_dscenario_flwreg_pump", "inp_dscenario_flwreg_weir", "inp_dscenario_flwreg_orifice",
                                "inp_dscenario_flwreg_outlet", "inp_dscenario_inflows_poll",  # "inp_dscenario_pump_additional"
                                ]
        self.dict_ids = {'ve_cat_hydrology': 'name', 've_cat_dwf': 'idval', 've_cat_dscenario': 'name'}
        self.rubber_band = tools_gw.create_rubberband(global_vars.canvas)

        if self.project_type == 'ud':

            self.views_dict = {'ve_cat_hydrology': 'hydrology_id', 've_cat_dwf': 'id',
                               've_cat_dscenario': 'dscenario_id'}
            self.menu = QMenu()
            self.menu.setObjectName("GW_dsenario_menu")
            self._fill_dscenario_menu()

            self.menu.aboutToShow.connect(self._fill_dscenario_menu)

            if toolbar is not None:
                self.action.setMenu(self.menu)
                toolbar.addAction(self.action)
        else:
            self.views_dict = {'ve_cat_dscenario': 'dscenario_id'}

    def clicked_event(self):

        if self.project_type == 'ws':
            self._open_dscenario_manager()
        elif self.project_type == 'ud':
            if self.menu.property('last_selection') is not None:
                getattr(self, self.menu.property('last_selection'))()
                return
            if hasattr(self.action, 'associatedObjects'):
                button = QWidget(self.action.associatedObjects()[1])
            elif hasattr(self.action, 'associatedWidgets'):
                button = self.action.associatedWidgets()[1]
            menu_point = button.mapToGlobal(QPoint(0, button.height()))
            self.menu.popup(menu_point)

    # region dscenario manager

    def _fill_dscenario_menu(self):
        """ Fill add arc menu """

        # disconnect and remove previuos signals and actions
        actions = self.menu.actions()
        for action in actions:
            action.disconnect()
            self.menu.removeAction(action)
            del action
        action_group = self.action.property('action_group')

        buttons = [[tools_qt.tr('Dscenario manager'), '_open_dscenario_manager'], [tools_qt.tr('Hydrology scenario manager'), '_open_hydrology_manager'],
                   [tools_qt.tr('DWF scenario manager'), '_open_dwf_manager']]

        for button in buttons:
            button_name = button[0]
            button_function = button[1]
            obj_action = QAction(str(button_name), action_group)
            obj_action.setObjectName(button_name)
            obj_action.setProperty('action_group', action_group)
            self.menu.addAction(obj_action)
            obj_action.triggered.connect(partial(getattr(self, button_function)))
            obj_action.triggered.connect(partial(self._save_last_selection, self.menu, button_function))

    def _save_last_selection(self, menu, button_function):
        menu.setProperty("last_selection", button_function)

    def _open_hydrology_manager(self):
        """"""
        # Main dialog
        self.dlg_hydrology_manager = GwDscenarioManagerUi(self)
        tools_gw.load_settings(self.dlg_hydrology_manager)

        tools_gw.add_icon(self.dlg_hydrology_manager.btn_toc, "164")

        # Manage btn create
        self._manage_btn_create(self.dlg_hydrology_manager, 've_cat_hydrology', scenario_type="hydrology")

        # Apply filter validator
        self.filter_name = self.dlg_hydrology_manager.findChild(QLineEdit, 'txt_name')
        reg_exp = QRegularExpression(r'([^"\'\\\\])*')  # Don't allow " or ' or \ because it breaks the query
        self.filter_name.setValidator(QRegularExpressionValidator(reg_exp))

        # Checkbox show inactive
        self.chk_active = self.dlg_hydrology_manager.chk_active

        # Set default scenario name
        name_value = tools_gw.get_config_value('inp_options_hydrology_current')
        if name_value and name_value[0]:
            name_value = tools_db.get_row(f'SELECT "name" FROM ve_cat_hydrology WHERE hydrology_id = {name_value[0]}')
            if name_value and name_value[0] is not None:
                tools_qt.set_widget_text(self.dlg_hydrology_manager, 'lbl_vdefault_dscenario', name_value[0])

        # Fill table
        self.tbl_dscenario = self.dlg_hydrology_manager.findChild(QTableView, 'tbl_dscenario')
        self._fill_manager_table('ve_cat_hydrology', dialog=self.dlg_hydrology_manager, scenario_type="hydrology")

        # Populate custom context menu
        self.dlg_hydrology_manager.tbl_dscenario.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.dlg_hydrology_manager.tbl_dscenario.customContextMenuRequested.connect(partial(self._show_context_menu, self.dlg_hydrology_manager.tbl_dscenario))

        # Connect main dialog signals
        self.dlg_hydrology_manager.btn_toc.clicked.connect(partial(self._manage_add_layers, 've_cat_hydrology', 'Catalogs'))
        self.dlg_hydrology_manager.txt_name.textChanged.connect(partial(self._fill_manager_table,
                                                                        've_cat_hydrology', None,
                                                                        dialog=self.dlg_hydrology_manager,
                                                                        scenario_type="hydrology"))
        self.dlg_hydrology_manager.btn_duplicate.clicked.connect(partial(self._duplicate_selected_dscenario,
                                                self.dlg_hydrology_manager, 've_cat_hydrology', 3294, 'hydrology', 'hydrology_id'))
        self.dlg_hydrology_manager.btn_toolbox.clicked.connect(partial(self._open_toolbox_function, 3100,
                                                                       've_cat_hydrology', dialog=self.dlg_hydrology_manager, scenario_type="hydrology"))
        self.dlg_hydrology_manager.btn_update.clicked.connect(partial(self._manage_properties,
                                                self.dlg_hydrology_manager, 've_cat_hydrology', True, column_name='hydrology_id'))
        self.dlg_hydrology_manager.btn_delete.clicked.connect(partial(self._delete_selected_dscenario,
                                                self.dlg_hydrology_manager, 've_cat_hydrology', scenario_type="hydrology", column_name="hydrology_id", current_config_param='inp_options_hydrology_current'))
        self.dlg_hydrology_manager.btn_delete.clicked.connect(partial(tools_gw.refresh_selectors))
        self.dlg_hydrology_manager.btn_toggle_active.clicked.connect(partial(self._manage_toggle_active,
                                                self.dlg_hydrology_manager, self.tbl_dscenario, 've_cat_hydrology', 'inp_options_hydrology_current', scenario_type="hydrology"))
        self.dlg_hydrology_manager.chk_active.stateChanged.connect(
            partial(self._fill_manager_table, 've_cat_hydrology',
                    dialog=self.dlg_hydrology_manager,
                    scenario_type="hydrology"))

        self.dlg_hydrology_manager.btn_update_dscenario.clicked.connect(
            partial(self.update_current_scenario, self.dlg_hydrology_manager, qtbl=self.tbl_dscenario,
                    scenario_type="hydrology", col_id_name="hydrology_id", view_name="ve_cat_hydrology",))

        self.tbl_dscenario.doubleClicked.connect(partial(self._manage_properties, self.dlg_hydrology_manager, 've_cat_hydrology', column_name='hydrology_id'))

        self.dlg_hydrology_manager.btn_cancel.clicked.connect(
            partial(tools_gw.close_dialog, self.dlg_hydrology_manager))
        self.dlg_hydrology_manager.finished.connect(partial(tools_gw.save_settings, self.dlg_hydrology_manager))
        self.dlg_hydrology_manager.finished.connect(partial(self.save_user_values))

        # Open dialog
        tools_gw.open_dialog(self.dlg_hydrology_manager, 'dscenario_manager')
        self.dlg_hydrology_manager.setWindowTitle(tools_qt.tr('Hydrology scenario'))

    def _open_dwf_manager(self):
        """"""
        # Main dialog
        self.dlg_dwf_manager = GwDscenarioManagerUi(self)
        tools_gw.load_settings(self.dlg_dwf_manager)

        tools_gw.add_icon(self.dlg_dwf_manager.btn_toc, "164")

        # Manage btn create
        self._manage_btn_create(self.dlg_dwf_manager, 've_cat_dwf', scenario_type="dwf")

        # Apply filter validator
        self.filter_name = self.dlg_dwf_manager.findChild(QLineEdit, 'txt_name')
        reg_exp = QRegularExpression(r'([^"\'\\\\])*')  # Don't allow " or ' or \ because it breaks the query
        self.filter_name.setValidator(QRegularExpressionValidator(reg_exp))

        # Checkbox show inactive
        self.chk_active = self.dlg_dwf_manager.chk_active

        # Set default scenario name
        name_value = tools_gw.get_config_value('inp_options_dwfscenario_current')
        if name_value[0]:
            name_value = tools_db.get_row(f'SELECT idval FROM ve_cat_dwf WHERE id = {name_value[0]}')
            tools_qt.set_widget_text(self.dlg_dwf_manager, 'lbl_vdefault_dscenario', name_value[0])

        # Fill table
        self.tbl_dscenario = self.dlg_dwf_manager.findChild(QTableView, 'tbl_dscenario')
        self._fill_manager_table('ve_cat_dwf', dialog=self.dlg_dwf_manager, scenario_type="dwf")

        # Populate custom context menu
        self.dlg_dwf_manager.tbl_dscenario.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.dlg_dwf_manager.tbl_dscenario.customContextMenuRequested.connect(partial(self._show_context_menu, self.dlg_dwf_manager.tbl_dscenario))

        # Connect main dialog signals
        self.dlg_dwf_manager.btn_toc.clicked.connect(partial(self._manage_add_layers, 've_cat_dwf', 'Catalogs'))
        self.dlg_dwf_manager.txt_name.textChanged.connect(partial(self._fill_manager_table,
                                                                  've_cat_dwf', None,
                                                                  dialog=self.dlg_dwf_manager,
                                                                  scenario_type="dwf"))
        self.dlg_dwf_manager.btn_duplicate.clicked.connect(partial(self._duplicate_selected_dscenario,
                                                self.dlg_dwf_manager, 've_cat_dwf', 3296, 'dwf', 'id'))
        self.dlg_dwf_manager.btn_toolbox.clicked.connect(partial(self._open_toolbox_function, 3102,
                                                                 've_cat_dwf', dialog=self.dlg_dwf_manager, scenario_type="dwf"))
        self.dlg_dwf_manager.btn_update.clicked.connect(partial(self._manage_properties,
                                                self.dlg_dwf_manager, 've_cat_dwf', True, column_name='id'))
        self.dlg_dwf_manager.btn_delete.clicked.connect(partial(self._delete_selected_dscenario,
                                                self.dlg_dwf_manager, 've_cat_dwf', scenario_type="dwf", column_name="id", current_config_param='inp_options_dwfscenario_current'))
        self.dlg_dwf_manager.btn_delete.clicked.connect(partial(tools_gw.refresh_selectors))
        self.dlg_dwf_manager.btn_toggle_active.clicked.connect(partial(self._manage_toggle_active,
                                                self.dlg_dwf_manager, self.tbl_dscenario, 've_cat_dwf', 'inp_options_dwfscenario_current', scenario_type="dwf"))
        self.dlg_dwf_manager.chk_active.stateChanged.connect(
            partial(self._fill_manager_table, 've_cat_dwf',
                    dialog=self.dlg_dwf_manager,
                    scenario_type="dwf"))

        self.dlg_dwf_manager.btn_update_dscenario.clicked.connect(
            partial(self.update_current_scenario, self.dlg_dwf_manager, qtbl=self.tbl_dscenario, scenario_type="dwf",
                    col_id_name="id", view_name="ve_cat_dwf"))

        self.tbl_dscenario.doubleClicked.connect(partial(self._manage_properties, self.dlg_dwf_manager, 've_cat_dwf', column_name='id'))

        self.dlg_dwf_manager.btn_cancel.clicked.connect(
            partial(tools_gw.close_dialog, self.dlg_dwf_manager))
        self.dlg_dwf_manager.finished.connect(partial(tools_gw.save_settings, self.dlg_dwf_manager))
        self.dlg_dwf_manager.finished.connect(partial(self.save_user_values))

        # Open dialog
        tools_gw.open_dialog(self.dlg_dwf_manager, 'dscenario_manager')
        self.dlg_dwf_manager.setWindowTitle(tools_qt.tr('DWF scenario manager'))

    def _open_dscenario_manager(self):
        """ Open dscenario manager """

        # Main dialog
        self.dlg_dscenario_manager = GwDscenarioManagerUi(self)
        tools_gw.load_settings(self.dlg_dscenario_manager)

        tools_gw.add_icon(self.dlg_dscenario_manager.btn_toc, "164")

        # Manage btn create
        self._manage_btn_create(self.dlg_dscenario_manager, 've_cat_dscenario')

        # Apply filter validator
        self.filter_name = self.dlg_dscenario_manager.findChild(QLineEdit, 'txt_name')
        reg_exp = QRegularExpression(r'([^"\'\\\\])*')  # Don't allow " or ' or \ because it breaks the query
        self.filter_name.setValidator(QRegularExpressionValidator(reg_exp))

        # Checkbox show inactive
        self.chk_active = self.dlg_dscenario_manager.chk_active

        # Fill table
        self.tbl_dscenario = self.dlg_dscenario_manager.findChild(QTableView, 'tbl_dscenario')

        self._fill_manager_table('ve_cat_dscenario', dialog=self.dlg_dscenario_manager)

        # CheckBox filter
        self.filter_active = self.dlg_dscenario_manager.findChild(QCheckBox, 'chk_active')

        # Make specific widgets invisible
        self.dlg_dscenario_manager.findChild(QWidget, 'btn_update_dscenario').setVisible(False)
        self.dlg_dscenario_manager.findChild(QWidget, 'lbl_vdefault_dscenario').setVisible(False)

        # Populate custom context menu
        self.dlg_dscenario_manager.tbl_dscenario.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.dlg_dscenario_manager.tbl_dscenario.customContextMenuRequested.connect(partial(self._show_context_menu, self.dlg_dscenario_manager.tbl_dscenario))

        # Connect main dialog signals
        self.dlg_dscenario_manager.txt_name.textChanged.connect(partial(self._fill_manager_table,
                                                                        've_cat_dscenario', None, dialog=self.dlg_dscenario_manager))
        self.dlg_dscenario_manager.btn_toc.clicked.connect(partial(self._manage_add_layers, 've_inp_dscenario', 'Dscenario'))
        self.dlg_dscenario_manager.btn_duplicate.clicked.connect(partial(self._duplicate_selected_dscenario,
                                                self.dlg_dscenario_manager, 've_cat_dscenario', 3156, 'dscenario', 'dscenario_id'))
        self.dlg_dscenario_manager.btn_toolbox.clicked.connect(partial(self._open_toolbox_function, 3042,
                                                                       've_cat_dscenario', dialog=self.dlg_dscenario_manager, scenario_type='dscenario'))
        self.dlg_dscenario_manager.btn_update.clicked.connect(partial(self._manage_properties,
                                                self.dlg_dscenario_manager, 've_cat_dscenario', True, column_name='dscenario_id'))
        self.dlg_dscenario_manager.btn_delete.clicked.connect(partial(self._delete_selected_dscenario,
                                                self.dlg_dscenario_manager, 've_cat_dscenario', column_name='dscenario_id'))
        self.dlg_dscenario_manager.btn_delete.clicked.connect(partial(tools_gw.refresh_selectors))
        self.dlg_dscenario_manager.btn_toggle_active.clicked.connect(partial(self._manage_toggle_active,
                                                self.dlg_dscenario_manager, self.tbl_dscenario, 've_cat_dscenario'))
        self.tbl_dscenario.doubleClicked.connect(self._open_dscenario)
        self.dlg_dscenario_manager.chk_active.stateChanged.connect(partial(self._fill_manager_table, 've_cat_dscenario', dialog=self.dlg_dscenario_manager))

        self.dlg_dscenario_manager.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_dscenario_manager))
        self.dlg_dscenario_manager.finished.connect(partial(tools_gw.save_settings, self.dlg_dscenario_manager))
        self.dlg_dscenario_manager.finished.connect(partial(self.save_user_values))

        # Open dialog
        tools_gw.open_dialog(self.dlg_dscenario_manager, 'dscenario_manager')
        self.dlg_dscenario_manager.setWindowTitle(tools_qt.tr('Dscenario manager'))

    def _show_context_menu(self, qtableview, pos):
        """ Show custom context menu """
        menu = QMenu(qtableview)

        action_open = QAction("Open", self.tbl_dscenario)
        action_open.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QTableView, qtableview.objectName(), pos))
        menu.addAction(action_open)

        if qtableview.objectName() in ('ve_cat_hydrology', 've_cat_dwf'):
            action_toggle = QAction("Current dscenario", qtableview)
            action_toggle.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_update_dscenario"))
            menu.addAction(action_toggle)

        action_toggle = QAction("Toggle active", qtableview)
        action_toggle.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_toggle_active"))
        menu.addAction(action_toggle)

        action_duplicate = QAction("Duplicate", qtableview)
        action_duplicate.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_duplicate"))
        menu.addAction(action_duplicate)

        action_update = QAction("Update", qtableview)
        action_update.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_update"))
        menu.addAction(action_update)

        action_toolbox = QAction("Toolbox", qtableview)
        action_toolbox.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_toolbox"))
        menu.addAction(action_toolbox)

        action_delete = QAction("Delete", qtableview)
        action_delete.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_delete"))
        menu.addAction(action_delete)

        menu.exec(QCursor.pos())

    def _manage_toggle_active(self, dialog, tableview, view, parameter=None, scenario_type=None):
        """ Toggle the active state of selected items in the current table. """

        # Get selected row
        if tableview is None and view is None:
            tableview = dialog.main_tab.currentWidget()
            view = tableview.objectName().replace('tbl_', '')

        selected_list = tableview.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        for index in selected_list:

            col_idx = tools_qt.get_col_index_by_col_name(tableview, self.views_dict[view])
            if not col_idx:
                col_idx = 0

            scenario_id = index.sibling(index.row(), col_idx).data()
            active = index.sibling(index.row(), tools_qt.get_col_index_by_col_name(tableview, 'active')).data()
            active = tools_os.set_boolean(active)

            if parameter and tools_gw.get_config_value(parameter) and active and str(tools_gw.get_config_value(parameter)[0]) == str(scenario_id):
                msg = "Cannot set inactive a current scenario. Please update current first."
                tools_qgis.show_warning(msg, dialog=dialog)
                return
            sql = f"UPDATE {view} SET active = {str(not active).lower()} WHERE {self.views_dict[view]} = {scenario_id}"

            tools_db.execute_sql(sql, log_sql=True)

        # Refresh tableview
        self._fill_manager_table(view, dialog=dialog, scenario_type=scenario_type)

    def save_user_values(self):
        pass

    def update_current_scenario(self, dialog, qtbl, scenario_type, col_id_name, view_name):
        """ Sets the selected scenario as current if it is active, based on scenario type """

        # Get selected rows in the table
        selected_list = qtbl.selectionModel().selectedRows()

        # Check if any row is selected
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        # Get the first selected row and retrieve scenario_id and active status
        row = selected_list[0].row()
        model = qtbl.model()
        col_id = tools_qt.get_col_index_by_col_name(qtbl, col_id_name)
        col_active = tools_qt.get_col_index_by_col_name(qtbl, 'active')

        # Access the data using the model's index method
        scenario_id = model.index(row, col_id).data()
        active = model.index(row, col_active).data()

        # Verify that the selected scenario is active
        if not tools_os.set_boolean(active):
            msg = "Cannot set the current {0} scenario of an inactive scenario. Please activate it first."
            msg_params = (scenario_type,)
            tools_qgis.show_warning(msg, dialog=dialog, msg_params=msg_params)
            return

        # Prepare the JSON body for gw_fct_set_toggle_current
        extras = f'"type": "{scenario_type}", "id": "{scenario_id}"'
        body = tools_gw.create_body(extras=extras)

        # Execute the stored procedure
        result = tools_gw.execute_procedure("gw_fct_set_toggle_current", body)

        # Check if the stored procedure returned a successful status
        if result.get("status") == "Accepted":
            # Refresh the table view and set the label for the current scenario
            self._set_label_current_dscenario_type(dialog, result=result)
        else:
            # If the procedure fails, show a warning
            msg = "Failed to set {0} scenario"
            msg_params = (scenario_type,)
            tools_qgis.show_warning(msg, dialog=dialog, msg_params=msg_params)

        # Re-open the dialog
        tools_gw.open_dialog(dialog, dlg_name='dscenario_manager')

    def _set_label_current_dscenario_type(self, dialog, scenario_type=None, from_open_dialog=False, result=None):
        """
        Sets the label for the current scenario by retrieving its name.

        If `from_open_dialog` is True, the function calls `gw_fct_set_toggle_current`
        to retrieve the name based on `scenario_type` only. Otherwise, it
        uses the provided `result`.
        """
        # If called from open dialog, retrieve the current scenario without updating config_param_user
        if from_open_dialog:
            # Prepare the JSON body to get the current scenario of the given type
            extras = f'"type": "{scenario_type}"'
            body = tools_gw.create_body(extras=extras)

            # Execute the stored procedure to retrieve the current scenario information
            result = tools_gw.execute_procedure("gw_fct_set_toggle_current", body)

            # Check if the stored procedure returned a successful status
            if result.get("status") != "Accepted":
                print("Failed to retrieve current scenario name")
                return
        try:
            name_value = result["body"]["data"]["name"]
            tools_qt.set_widget_text(dialog, 'lbl_vdefault_dscenario', name_value)
        except KeyError:
            print("Error: 'name' field is missing in the result.")

    def _get_list(self, table_name='ve_cat_dscenario', filter_name="", filter_id=None, filter_active=None):
        """ Mount and execute the query for gw_fct_getlist """

        id_field = self.dict_ids.get(table_name)
        extras = f'"tableName":"{table_name}"'
        filter_fields = f'"limit": -1, "{id_field}": {{"filterSign":"ILIKE", "value":"{filter_name}"}}'
        if filter_id is not None:
            filter_fields += f', "dscenario_id": {{"filterSign":"=", "value":"{filter_id}"}}'
        if not filter_active:
            filter_fields += ', "active": {"filterSign":"=", "value":"true"}'
        body = tools_gw.create_body(filter_fields=filter_fields, extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_getlist', body)
        if json_result is None or json_result['status'] == 'Failed':
            return False
        complet_list = json_result
        if not complet_list:
            return False

        return complet_list

    def _fill_manager_table(self, view, filter_active=None, filter_name="", dialog=None, scenario_type=None):
        """ Fill dscenario manager table and optionally update current label. """

        filter_active = 'true' if filter_active == 2 else self.chk_active.isChecked()
        if filter_name == "":
            filter_name = self.filter_name.text()
        complet_list = self._get_list(view, filter_name, filter_active=filter_active)

        if complet_list is False:
            return False, False
        data = complet_list['body']['data']
        headers = complet_list['body']['form'].get('headers')
        fields = data['fields']
        if data.get('hidden'):
            return False, False

        model = self.tbl_dscenario.model()
        if model is None:
            model = QStandardItemModel()
            self.tbl_dscenario.setModel(model)
        model.removeRows(0, model.rowCount())

        if fields:
            self.tbl_dscenario = tools_gw.add_tableview_header(self.tbl_dscenario, fields, headers)
            self.tbl_dscenario = tools_gw.fill_tableview_rows(self.tbl_dscenario, fields)
        tools_gw.set_tablemodel_config(dialog, self.tbl_dscenario, 've_cat_dscenario', Qt.SortOrder.DescendingOrder)
        tools_qt.set_tableview_config(self.tbl_dscenario)
        # Optionally set current scenario label if context provided
        if dialog is not None and dialog.findChild(QWidget, 'lbl_vdefault_dscenario').isVisible() and scenario_type is not None:
            self._set_label_current_dscenario_type(dialog, scenario_type=scenario_type, from_open_dialog=True)
        return complet_list

    def _manage_btn_create(self, dialog, view, scenario_type=None):
        """ Fill btn_create QMenu """

        # Functions
        toolbox_table = "v_config_toolbox"
        if not tools_gw._relation_exists(lib_vars.schema_name, toolbox_table):
            toolbox_table = "config_toolbox"
        sql = f"SELECT id, alias FROM {toolbox_table} WHERE "

        if global_vars.project_type == 'ws':
            sql += "id IN (3134, 3110, 3112, 3108, 3158)"
        if global_vars.project_type == 'ud':
            if view == 've_cat_hydrology':
                sql += "id IN (3290)"
            elif view == 've_cat_dwf':
                sql += "id IN (3292)"
            elif view == 've_cat_dscenario':
                sql += "id IN (3134, 3118)"

        sql += " AND active"
        rows = tools_db.get_rows(sql)
        # Create and populate QMenu
        create_menu = QMenu()
        for value in rows:
            num = value[0]
            label = value[1]
            action = create_menu.addAction(f"{label}")
            action.triggered.connect(partial(self._open_toolbox_function, num, view, label=label, dialog=dialog, scenario_type=scenario_type))

        dialog.btn_create.setMenu(create_menu)

    def _open_toolbox_function(self, function, view, signal=None, connect=None, label=None, dialog=None, scenario_type=None):
        """
        Execute currently selected function from combobox and dynamically append additional logic
        for specific scenarios without removing defaults.
        """

        dscenario_functions = [3134, 3110, 3112, 3108, 3158, 3118]

        if function == 3290 and label == 'Create hydrology scenario values':
            aux_params = '{"aux_fct": 3100}'
        elif function == 3292 and label == 'Create dwf scenario values':
            aux_params = '{"aux_fct": 3102}'
        else:
            aux_params = "null"

        toolbox_btn = GwToolBoxButton(None, None, None, None, None)

        # Default connections
        default_connect = [partial(self._fill_manager_table, view, dialog=dialog, scenario_type=scenario_type),
                           partial(tools_gw.refresh_selectors)]

        # Merge connect with defaults
        if connect is None:
            connect = default_connect
        else:
            if not isinstance(connect, list):
                connect = [connect]
            connect = default_connect + connect

        # Append logic dynamically for specific functions
        if function == 3292:
            connect.append(partial(tools_gw.configure_layers_from_table_name, "dwf_id"))
        if function == 3290:
            connect.append(partial(tools_gw.configure_layers_from_table_name, "hydrology_id"))
        if function in dscenario_functions:
            connect.append(partial(tools_gw.configure_layers_from_table_name, "dscenario"))

        # Execute the toolbox function with the updated connect list
        dlg_functions = toolbox_btn.open_function_by_id(function, connect_signal=connect, aux_params=aux_params)

        if function in (3100, 3102):  # hydrology & dwf scenarios
            if function == 3100:
                column_name = "hydrology_id"
            elif function == 3102:
                column_name = "dwf_id"
            selected_list = self.tbl_dscenario.selectionModel().selectedRows()
            if len(selected_list) == 0:
                return

            # Get selected scenario id
            index = self.tbl_dscenario.selectionModel().currentIndex()
            col_idx = tools_qt.get_col_index_by_col_name(self.tbl_dscenario, column_name)
            value = index.sibling(index.row(), col_idx).data()
            tools_qt.set_combo_value(dlg_functions.findChild(QComboBox, 'target'), f"{value}", 0)
        return dlg_functions

    def _duplicate_selected_dscenario(self, dialog, view, fct_id, scenario_type, column_name):
        """ Duplicates the selected dscenario """

        # Get selected row
        selected_list = self.tbl_dscenario.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        # Get selected dscenario id
        index = self.tbl_dscenario.selectionModel().currentIndex()
        col_idx = tools_qt.get_col_index_by_col_name(self.tbl_dscenario, column_name)
        value = index.sibling(index.row(), col_idx).data()

        # Execute toolbox function
        dlg_functions = self._open_toolbox_function(fct_id, view, dialog=dialog, scenario_type=scenario_type)
        # Set dscenario_id in combo copyFrom
        tools_qt.set_combo_value(dlg_functions.findChild(QComboBox, 'copyFrom'), f"{value}", 0)
        tools_qt.set_widget_enabled(dlg_functions, 'copyFrom', False)

    def _delete_selected_dscenario(self, dialog, view, scenario_type=None, column_name=None, current_config_param=None):
        """ Deletes the selected dscenario """

        # Get selected row
        selected_list = self.tbl_dscenario.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        # Get selected id
        col_idx = tools_qt.get_col_index_by_col_name(self.tbl_dscenario, column_name)
        values = [index.sibling(index.row(), col_idx).data() for index in selected_list]

        # Do not allow deleting the current scenario
        if current_config_param:
            current_value = tools_gw.get_config_value(current_config_param)
            if current_value and current_value[0] is not None:
                current_id = str(current_value[0])
                if current_id in [str(v) for v in values]:
                    msg = "Cannot delete the current scenario. Please set another scenario as current first."
                    tools_qgis.show_warning(msg, dialog=dialog)
                    return

        msg = ("CAUTION! Deleting a dscenario will delete data from features related to the dscenario.\n"
                  "Are you sure you want to delete these records?")
        title = "Delete records"
        answer = tools_qt.show_question(msg, title, values, force_action=True)
        if answer:
            # Build WHERE IN clause for SQL
            where_clause = f"{self.views_dict[view]} IN ({', '.join(map(str, values))})"

            # Construct SQL DELETE statement
            sql = f"DELETE FROM {view} WHERE {where_clause}"
            tools_db.execute_sql(sql)

            # Refresh the table
            self._fill_manager_table(view, dialog=dialog, scenario_type=scenario_type)

    # endregion

    # region dscenario

    def _open_dscenario(self, index):
        """ Create custom dialog for selected dscenario and fill initial table """

        # Check if there are selected rows
        selected_list = self.tbl_dscenario.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_dscenario_manager)
            return

        # Get selected dscenario_id
        row = index.row()
        column_index = tools_qt.get_col_index_by_col_name(self.tbl_dscenario, 'dscenario_id')
        self.selected_dscenario_id = index.sibling(row, column_index).data()
        column_index = tools_qt.get_col_index_by_col_name(self.tbl_dscenario, 'dscenario_type')
        self.selected_dscenario_type = index.sibling(row, column_index).data()

        # Create dialog
        self.dlg_dscenario = GwDscenarioUi(self)
        tools_gw.load_settings(self.dlg_dscenario)

        # Add icons
        tools_gw.add_icon(self.dlg_dscenario.btn_insert, "111")
        tools_gw.add_icon(self.dlg_dscenario.btn_delete, "112")
        tools_gw.add_icon(self.dlg_dscenario.btn_toc, "164")
        tools_gw.add_icon(self.dlg_dscenario.btn_snapping, "137")
        tools_gw.add_icon(self.dlg_dscenario.btn_expr_select, "178")

        default_tab_idx = 0
        # Select all dscenario views
        sql = f"SELECT table_name FROM INFORMATION_SCHEMA.tables WHERE table_schema = '{lib_vars.schema_name}' " \
              f"AND table_name LIKE 'inp_dscenario%' AND table_name <> 'inp_dscenario_pattern_value'" \
              f"ORDER BY table_name;"
        rows = tools_db.get_rows(sql)
        if rows:
            views = [x[0] for x in rows]
            for view in views:
                qtableview = QTableView()
                qtableview.setObjectName(f"tbl_{view}")
                qtableview.clicked.connect(partial(self._manage_highlight, qtableview, view))
                tab_idx = self.dlg_dscenario.main_tab.addTab(qtableview, f"{view.split('_')[-1].capitalize()}")
                self.dlg_dscenario.main_tab.widget(tab_idx).setObjectName(view)
                # Manage editability
                qtableview.doubleClicked.connect(partial(self.manage_update, self.dlg_dscenario, qtableview))
                if view.split('_')[-1].upper() == self.selected_dscenario_type:
                    default_tab_idx = tab_idx

        self.dlg_dscenario.main_tab.setCurrentIndex(default_tab_idx)

        # Connect signals
        self.dlg_dscenario.btn_properties.clicked.connect(partial(self._manage_properties, self.dlg_dscenario_manager, 've_cat_dscenario', column_name='dscenario_id'))
        self.dlg_dscenario.btn_toc.clicked.connect(partial(self._manage_add_layers, 've_inp_dscenario', 'Dscenario'))
        self.dlg_dscenario.btn_insert.clicked.connect(partial(self._manage_insert))
        self.dlg_dscenario.btn_delete.clicked.connect(partial(self._manage_delete))
        self.dlg_dscenario.btn_snapping.toggled.connect(partial(self._manage_btn_snapping))
        self.dlg_dscenario.btn_expr_select.clicked.connect(partial(self._select_with_expression_dialog))
        self.dlg_dscenario.main_tab.currentChanged.connect(partial(self._manage_current_changed))
        self.dlg_dscenario.btn_accept.clicked.connect(self.dlg_dscenario.accept)
        self.dlg_dscenario.btn_close.clicked.connect(self.dlg_dscenario.reject)
        self.dlg_dscenario.finished.connect(self._selection_end)
        self.dlg_dscenario.finished.connect(partial(tools_gw.close_dialog, self.dlg_dscenario, True))

        self._manage_current_changed()

        sql = f"SELECT name FROM ve_cat_dscenario WHERE dscenario_id = {self.selected_dscenario_id}"
        row = tools_db.get_row(sql)
        dscenario_name = row[0]
        title = f"Dscenario {self.selected_dscenario_id} - {dscenario_name}"
        tools_gw.open_dialog(self.dlg_dscenario, 'dscenario', title=f"{title}")

    def _paste_dscenario_demand_custom_menu(self, tbl):
        menu = QMenu(tbl)
        action_paste = QAction("Paste")
        action_paste.triggered.connect(partial(self._paste_dscenario_demand_values, tbl))

        menu.addAction(action_paste)

        menu.exec(QCursor.pos())

    def _paste_dscenario_demand_values(self, tableview):
        text = QApplication.clipboard().text()
        rows = text.split("\n")
        model = tableview.model()

        for row in rows:
            if not row:
                continue

            values = row.split("\t")

            # Check if the number of values matches the number of columns
            if len(values) != model.columnCount() - 2:
                continue

            feature_id = values[0]  # Assuming feature_id is the first column
            values = values[1:]  # Exclude feature_id from the values

            # Insert a new feature using _manage_paste_dscenario_demand_values
            self._manage_paste_dscenario_demand_values(feature_id, values)

        model.submitAll()
        model.select()
        tableview.update()

    def _manage_paste_dscenario_demand_values(self, feature_id, values):
        """ Insert feature to dscenario via copy paste """

        if feature_id == '':
            msg = "Feature_id is mandatory."
            tools_qgis.show_warning(msg, dialog=self.dlg_dscenario)
            return
        self.dlg_dscenario.txt_feature_id.setStyleSheet(None)
        tableview = self.dlg_dscenario.main_tab.currentWidget()
        view = tableview.objectName()

        sql = f"SELECT DISTINCT column_name, ordinal_position FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '{self.table_name[len(f'{self.schema_name}.'):]}' ORDER BY ordinal_position;"
        rows = tools_db.get_rows(sql)

        # FIELDS
        columns = [row[0] for row in rows]
        columns_str = ', '.join(columns[1:])  # Excluding 'id'

        # VALUES
        values_str = ', '.join(
            [f"'{self.selected_dscenario_id}'", f"'{feature_id}'"] + [f"'{value}'" for value in values])

        sql = f"INSERT INTO ve_{view} ({columns_str}) VALUES ({values_str});"
        tools_db.execute_sql(sql)

        # Refresh tableview
        self._fill_dscenario_table()

    def _fill_dscenario_table(self, set_edit_triggers=QTableView.EditTrigger.NoEditTriggers, expr=None):
        """ Fill dscenario table with data from its corresponding table """

        # Manage exception if dialog is closed
        if not hasattr(self, 'dlg_dscenario') or isdeleted(self.dlg_dscenario):
            return

        self.table_name = f"{self.dlg_dscenario.main_tab.currentWidget().objectName()}"
        widget = self.dlg_dscenario.main_tab.currentWidget()

        if self.schema_name not in self.table_name:
            self.table_name = self.schema_name + "." + self.table_name

        # Set model
        model = QSqlTableModel(db=lib_vars.qgis_db_credentials)
        model.setTable(self.table_name)
        model.setFilter(f"dscenario_id = {self.selected_dscenario_id}")
        model.setEditStrategy(QSqlTableModel.EditStrategy.OnFieldChange)
        model.setSort(0, Qt.SortOrder.AscendingOrder)
        model.select()
        # Set item delegates
        readonly_delegate = ReadOnlyDelegate(widget)
        widget.setItemDelegateForColumn(0, readonly_delegate)
        widget.setItemDelegateForColumn(1, readonly_delegate)
        editable_delegate = EditableDelegate(widget)
        for x in range(2, model.columnCount()):
            widget.setItemDelegateForColumn(x, editable_delegate)

        # Check for errors
        if model.lastError().isValid():
            if 'Unable to find table' in model.lastError().text():
                tools_db.reset_qsqldatabase_connection(self.dlg_dscenario)
            else:
                tools_qgis.show_warning(model.lastError().text(), dialog=self.dlg_dscenario)
            tools_qgis.show_warning(model.lastError().text(), dialog=self.dlg_dscenario)
        # Attach model to table view
        if expr:
            widget.setModel(model)
            widget.model().setFilter(expr)
        else:
            widget.setModel(model)
        widget.setSortingEnabled(True)

        # Set widget & model properties
        tools_qt.set_tableview_config(widget, selection=QAbstractItemView.SelectionBehavior.SelectRows, edit_triggers=set_edit_triggers, section_resize_mode=QHeaderView.ResizeMode.Interactive)
        tools_gw.set_tablemodel_config(self.dlg_dscenario, widget, f"{self.table_name[len(f'{self.schema_name}.'):]}")

        # Hide unwanted columns
        col_idx = tools_qt.get_col_index_by_col_name(widget, 'dscenario_id')
        if col_idx not in (None, False):
            widget.setColumnHidden(col_idx, True)

        geom_col_idx = tools_qt.get_col_index_by_col_name(widget, 'the_geom')
        if geom_col_idx not in (None, False):
            widget.setColumnHidden(geom_col_idx, True)

        # Sort the table by feature id
        model.sort(1, Qt.SortOrder.AscendingOrder)

        # Clear txt_feature_id
        self.dlg_dscenario.txt_feature_id.setText('')

    def _manage_current_changed(self):
        """ Manages tab changes """

        if not hasattr(self, 'dlg_dscenario') or isdeleted(self.dlg_dscenario):
            return

        # Fill current table
        self._fill_dscenario_table()

        # Refresh txt_feature_id
        tools_qt.set_widget_text(self.dlg_dscenario, self.dlg_dscenario.txt_feature_id, '')
        self.dlg_dscenario.txt_feature_id.setStyleSheet(None)

        # Manage insert typeahead
        # Get index of selected tab
        index_tab = self.dlg_dscenario.main_tab.currentIndex()
        tab_name = self.dlg_dscenario.main_tab.widget(index_tab).objectName()
        enable = tab_name not in self.filter_disabled

        # Populate typeahead
        if enable:
            self._manage_feature_type()
            table_name = f"ve_{tab_name.replace('dscenario_', '')}"
            feature_type = self.feature_type
            if self.filter_dict.get(tab_name):
                table_name = self.filter_dict[tab_name]['filter_table']
                feature_type = self.filter_dict[tab_name]['feature_type']
            add_id = not (feature_type == "id")
            if feature_type == "id":
                feature_type = "concat(node_id, ' (order_id ', order_id, ')')"
            tools_gw.set_completer_widget(table_name, self.dlg_dscenario.txt_feature_id, feature_type, add_id=add_id, filter_mode='contains')

        tableview = self.dlg_dscenario.main_tab.currentWidget()

        self.dlg_dscenario.btn_snapping.setMenu(None)
        self.dlg_dscenario.btn_snapping.setPopupMode(QToolButton.ToolButtonPopupMode.DelayedPopup)
        if tableview.objectName() == "inp_dscenario_demand" and self.project_type == 'ws':
            # Create main menu and get cursor click position
            btn_menu = QMenu()

            action_node = btn_menu.addAction("NODE")
            action_node.triggered.connect(partial(self._set_active_layer, action_node, 've_node'))
            action_connec = btn_menu.addAction("CONNEC")
            action_connec.triggered.connect(partial(self._set_active_layer, action_connec, 've_connec'))
            self.dlg_dscenario.btn_snapping.setMenu(btn_menu)
            self.dlg_dscenario.btn_snapping.setPopupMode(QToolButton.ToolButtonPopupMode.MenuButtonPopup)

            # Populate custom context menu
            tableview.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
            tableview.customContextMenuRequested.connect(partial(self._paste_dscenario_demand_custom_menu, tableview))

            # Copy values from clipboard only in dscenario demand in ws projects
            paste_shortcut = QShortcut(QKeySequence.StandardKey.Paste, self.dlg_dscenario.main_tab)
            paste_shortcut.activated.connect(partial(self._paste_dscenario_demand_values, tableview))

        # Deactivate btn_snapping functionality
        self._selection_end()

        # Enable/disable filter & buttons
        self._enable_widgets(enable, tableview)

    def _enable_widgets(self, enable, tableview):
        """  """

        tools_qt.set_widget_enabled(self.dlg_dscenario, 'txt_feature_id', enable)
        tools_qt.set_widget_enabled(self.dlg_dscenario, 'btn_insert', enable)
        tools_qt.set_widget_enabled(self.dlg_dscenario, 'btn_delete', enable)
        tools_qt.set_widget_enabled(self.dlg_dscenario, 'btn_snapping', enable)
        tools_qt.set_widget_enabled(self.dlg_dscenario, 'btn_expr_select', enable)

        if tableview.objectName() in ("inp_dscenario_controls", "inp_dscenario_rules"):
            tools_qt.set_widget_enabled(self.dlg_dscenario, 'txt_feature_id', False)
            tools_qt.set_widget_enabled(self.dlg_dscenario, 'btn_snapping', False)
            tools_qt.set_widget_enabled(self.dlg_dscenario, 'btn_expr_select', False)
        if tableview.objectName() == "inp_dscenario_pattern":
            tools_qt.set_widget_enabled(self.dlg_dscenario, 'btn_snapping', False)
            tools_qt.set_widget_enabled(self.dlg_dscenario, 'btn_expr_select', False)

    def _manage_feature_type(self):
        """ Manages current tableview feature type (node, arc, nodarc, etc.) """

        tableview = self.dlg_dscenario.main_tab.currentWidget()
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

        table = view.replace("_dscenario", "")
        feature_type = 'feature_id'

        for x in self.feature_types:
            col_idx = tools_qt.get_col_index_by_col_name(qtableview, x)
            if col_idx not in (None, False):
                feature_type = x
                break
        if feature_type != 'feature_id':
            table = f"ve_{feature_type.split('_')[0]}"
        tools_qgis.highlight_feature_by_id(qtableview, table, feature_type, self.rubber_band, 5, index)

    def manage_update(self, dialog, tableview, on_close=None):
        # Get selected row
        if tableview is None:
            tableview = dialog.main_tab.currentWidget()

        obj_name = tableview.objectName()
        frelem_name = None
        if obj_name.startswith('tab_elements_tbl_frelem_dsc_'):
            frelem_name = obj_name.replace('tab_elements_tbl_frelem_dsc_', '')

        if frelem_name:
            tablename = f'inp_dscenario_fr{frelem_name}'
        else:
            tablename = obj_name.replace('tbl_', '')

        selected_list = tableview.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        # Get selected mapzone data
        index = tableview.selectionModel().currentIndex()
        col_name = 'feature_id'
        col_idx = None

        if tablename in ('inp_dscenario_controls', 'inp_dscenario_rules', 'inp_dscenario_demand'):
            col_name = 'id'
            col_idx = tools_qt.get_col_index_by_col_name(tableview, col_name)
        else:
            for x in self.feature_types:
                col_idx = tools_qt.get_col_index_by_col_name(tableview, x)
                if col_idx not in (None, False):
                    col_name = x
                    break

        feature_id = index.sibling(index.row(), col_idx).data()
        # Ensure dscenario_id is set when coming from Info's frelem lists
        if self.selected_dscenario_id is None:
            try:
                col_idx_ds = tools_qt.get_col_index_by_col_name(tableview, 'dscenario_id')
                if col_idx_ds not in (None, False):
                    self.selected_dscenario_id = index.sibling(index.row(), col_idx_ds).data()
            except Exception:
                pass
        field_id = tableview.model().headerData(col_idx, Qt.Orientation.Horizontal).lower().replace(' ', '_')

        if tablename == "inp_dscenario_controls":
            return self._manage_upsert_controls(feature_id)
        elif tablename == "inp_dscenario_rules":
            return self._manage_upsert_rules(feature_id)
        elif tablename == "inp_dscenario_pattern":
            return self._manage_upsert_pattern(feature_id)

        # Execute getinfofromid
        _id = f"{feature_id}"
        if self.selected_dscenario_id is not None and col_name != 'id':
            _id = f"{self.selected_dscenario_id}, {feature_id}"
            if tablename == "inp_dscenario_pump_additional":
                col_idx = tools_qt.get_col_index_by_col_name(tableview, 'order_id')
                order_id = index.sibling(index.row(), col_idx).data()
                _id += f", {order_id}"
        feature = f'"tableName":"{tablename}", "id": "{_id}"'
        body = tools_gw.create_body(feature=feature)
        json_result = tools_gw.execute_procedure('gw_fct_getinfofromid', body)
        if json_result is None or json_result['status'] == 'Failed':
            return
        result = json_result

        dlg_title = f"Update {tablename.split('_')[-1].capitalize()} ({feature_id})"

        self._build_generic_info(dlg_title, result, tablename, field_id, force_action="UPDATE")
        # If a callback is provided, refresh external context (e.g., Info dialog tables) on close
        if on_close and getattr(self, 'add_dlg', None) is not None:
            try:
                self.add_dlg.dlg_closed.connect(on_close)
            except Exception:
                pass

    def _manage_properties(self, dialog, view, feature_id=None, column_name=None):
        tablename = view
        pkey = self.views_dict[view]

        # Check if there are selected rows
        selected_list = self.tbl_dscenario.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        if feature_id is None:
            feature_id = self.selected_dscenario_id
        else:
            # Get selected netscenario id
            index = self.tbl_dscenario.selectionModel().currentIndex()
            col_idx = tools_qt.get_col_index_by_col_name(self.tbl_dscenario, column_name)
            feature_id = index.sibling(index.row(), col_idx).data()
            self.selected_dscenario_id = feature_id
            if feature_id is None:
                msg = "Any record selected"
                tools_qgis.show_warning(msg, dialog=dialog)
                return

        feature = f'"tableName":"{tablename}", "id":"{feature_id}"'
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
        disabled_widgets = [self.views_dict[view], 'log']
        for widget in disabled_widgets:
            widget_name = f"tab_none_{widget}"
            tools_qt.set_widget_enabled(self.props_dlg, widget_name, False)
        self.props_dlg.actionEdit.setVisible(False)

        # Signals
        self.props_dlg.btn_close.clicked.connect(partial(tools_gw.close_dialog, self.props_dlg))
        self.props_dlg.dlg_closed.connect(partial(tools_gw.close_dialog, self.props_dlg))
        self.props_dlg.btn_accept.clicked.connect(partial(self._accept_props_dlg, self.props_dlg, tablename, pkey,
                                                          self.selected_dscenario_id, self.my_json_add, dialog))

        # Open dlg
        title = f"Properties for Dscenario: {self.selected_dscenario_id}"
        tools_gw.open_dialog(self.props_dlg, dlg_name='info_generic', title=title)

    def _accept_props_dlg(self, dialog, tablename, pkey, feature_id, my_json, main_dialog=None):
        """ Accept the properties dialog """

        if not my_json:
            return

        fields = json.dumps(my_json)
        id_val = ""
        if pkey:
            if not isinstance(pkey, list):
                pkey = [pkey]
            for pk in pkey:
                widget_name = f"tab_none_{pk}"
                value = tools_qt.get_widget_value(dialog, widget_name)
                id_val += f"{value}, "
            id_val = id_val[:-2]
        if not id_val:
            id_val = feature_id

        feature = f'"id":"{id_val}", '
        feature += f'"tableName":"{tablename}"'
        extras = f'"fields":{fields}'
        body = tools_gw.create_body(feature=feature, extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_upsertfields', body)
        if json_result and json_result.get('status') == 'Accepted':
            tools_gw.close_dialog(dialog)
            # Refresh tableview
            self._fill_manager_table(tablename, dialog=main_dialog)
            return
        msg = "Error"
        tools_qgis.show_warning(msg, parameter=json_result, dialog=dialog)

    def _manage_add_layers(self, table_name, sub_group):
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
              f"AND f_table_name LIKE '{table_name}%';"
        rows = tools_db.get_rows(sql)

        if rows:
            geom_layers = [row[0] for row in rows]

        # Get layers to add
        lyr_filter = f"{table_name}%"
        sql = f"SELECT id, alias, addparam FROM sys_table WHERE id LIKE '{lyr_filter}' AND alias IS NOT NULL ORDER BY alias ASC"
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
                    alias = tablename.replace('ve_inp_dscenario_', '').replace('_', ' ').capitalize()
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
                    partial(self._check_action_ischecked, tablename, the_geom, pk, -1, alias.strip(), sub_group))

        main_menu.exec(click_point)

    def _check_action_ischecked(self, tablename, the_geom, pk, style_id, alias, sub_group, state):
        """ Control if user check or uncheck action menu, then add or remove layer from toc
        :param tablename: Postgres table name (String)
        :param pk: Field id of the table (String)
        :param style_id: Id of the style we want to load (integer or String)
        :param state: This parameter is sent by the action itself with the trigger (Bool)
        """

        if state == 2:
            layer = tools_qgis.get_layer_by_tablename(tablename)
            if layer is None:
                tools_gw.add_layer_database(tablename, the_geom=the_geom, field_id=pk, group="EPA", sub_group=sub_group, alias=alias)
        elif state == 0:
            layer = tools_qgis.get_layer_by_tablename(tablename)
            if layer is not None:
                msg = "Remove layer from project?"
                answer = tools_qt.show_question(msg, "Warning", parameter=f"'{layer.name()}'", force_action=True)
                if answer:
                    tools_qgis.remove_layer(custom_properties={"gw_id": tablename}, group_name="EPA", sub_group=sub_group)

    def _manage_load_all(self, menu, state=None):

        if state == 2:
            for child in menu.actions():
                if not child.isChecked():
                    child.defaultWidget().setChecked(True)

    def _manage_insert(self):
        """ Insert feature to dscenario via the button """

        tableview = self.dlg_dscenario.main_tab.currentWidget()
        view = tableview.objectName()
        if view == "inp_dscenario_controls":
            return self._manage_upsert_controls()
        elif view == "inp_dscenario_rules":
            return self._manage_upsert_rules()
        elif view == "inp_dscenario_demand":
            return self._manage_insert_demand(view)

        if self.dlg_dscenario.txt_feature_id.text() == '':
            msg = "Feature_id is mandatory."
            self.dlg_dscenario.txt_feature_id.setStyleSheet("border: 1px solid red")
            tools_qgis.show_warning(msg, dialog=self.dlg_dscenario)
            return
        self.dlg_dscenario.txt_feature_id.setStyleSheet(None)

        if view == "inp_dscenario_pump_additional":
            return self._manage_insert_pump_additional(view)

        sql = f"SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS " \
              f"WHERE TABLE_SCHEMA = '{lib_vars.schema_name}' AND TABLE_NAME = '{self.table_name[len(f'{self.schema_name}.'):]}' " \
              f"ORDER BY ordinal_position;"
        rows = tools_db.get_rows(sql)
        if not rows:
            return

        sql = f"INSERT INTO ve_{view} VALUES ({self.selected_dscenario_id}, '{self.dlg_dscenario.txt_feature_id.text()}');"
        tools_db.execute_sql(sql)

        # Refresh tableview
        self._fill_dscenario_table()

    def _manage_insert_pump_additional(self, view):
        full_text = self.dlg_dscenario.txt_feature_id.text()
        split_text = full_text.replace('(', '').replace(')', '').split(' order_id ')
        node_id, order_id = split_text
        sql = f"INSERT INTO ve_{view} VALUES ({self.selected_dscenario_id}, '{node_id}', '{order_id}');"
        tools_db.execute_sql(sql)

        # Refresh tableview
        self._fill_dscenario_table()

    def _manage_insert_demand(self, view):
        sql = f"INSERT INTO ve_{view} (dscenario_id, feature_id) VALUES ({self.selected_dscenario_id}, '{self.dlg_dscenario.txt_feature_id.text()}');"
        tools_db.execute_sql(sql)

        # Refresh tableview
        self._fill_dscenario_table()

    def _manage_upsert_controls(self, control_id=None):

        nonvisual = GwNonVisual()
        nonvisual.get_controls(control_id=control_id, dscenario_id=self.selected_dscenario_id)
        nonvisual.dialog.rejected.connect(self._fill_dscenario_table)

    def _manage_upsert_rules(self, rule_id=None):

        nonvisual = GwNonVisual()
        nonvisual.get_rules(rule_id=rule_id, dscenario_id=self.selected_dscenario_id)
        nonvisual.dialog.rejected.connect(self._fill_dscenario_table)

    def _manage_upsert_pattern(self, pattern_id=None):

        nonvisual = GwNonVisual()
        nonvisual.get_patterns(pattern_id=pattern_id, dscenario_id=self.selected_dscenario_id)
        nonvisual.dialog.rejected.connect(self._fill_dscenario_table)

    def _manage_delete(self):
        """ Delete features from dscenario via the button """

        tableview = self.dlg_dscenario.main_tab.currentWidget()
        # Get selected row
        selected_list = tableview.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_dscenario)
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
                sql = f"DELETE FROM {view} WHERE dscenario_id = {self.selected_dscenario_id} AND {feature_type} = '{value}'"
                tools_db.execute_sql(sql)

            # Refresh tableview
            self._fill_dscenario_table()

    def _manage_btn_snapping(self, checked: bool):

        if checked:
            self._manage_select()
        else:
            self._selection_end()

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
        view_name = self.dlg_dscenario.main_tab.currentWidget().objectName()
        layer_name = 've_' + self.feature_type
        if view_name != 'inp_dscenario_demand':
            if self.feature_type == 'nodarc':
                layer_name = view_name.replace("dscenario_", "")
            layer = tools_qgis.get_layer_by_tablename(layer_name)
            self.iface.setActiveLayer(layer)
            tools_qgis.set_layer_visible(layer)

        self._selection_init()

    def _set_active_layer(self, action: QAction, layer_name: str):
        self.dlg_dscenario.btn_snapping.setChecked(False)
        layer = tools_qgis.get_layer_by_tablename(layer_name)
        self.iface.setActiveLayer(layer)
        tools_qgis.set_layer_visible(layer)
        self.dlg_dscenario.btn_snapping.setChecked(True)

    def _selection_init(self):
        """ Set canvas map tool to selection """

        tools_gw.disconnect_signal('dscenario_snapping')
        self.iface.actionSelect().trigger()
        self.connect_signal_selection_changed()

    def connect_signal_selection_changed(self):
        """ Connect signal selectionChanged """

        tools_gw.connect_signal(global_vars.canvas.selectionChanged, partial(self._manage_selection),
                                'dscenario_snapping', 'connect_signal_selection_changed_selectionChanged_manage_selection')

    def _manage_selection(self):
        """ Slot function for signal 'canvas.selectionChanged' """

        # Get feature_type and feature_id
        layer = self.iface.activeLayer()
        feature_type = self.feature_type
        field_id = feature_type + "_id"
        tableview = self.dlg_dscenario.main_tab.currentWidget()
        view = tableview.objectName()

        # Iterate over layer
        if layer.selectedFeatureCount() > 0:
            selected_ids = []
            # Get selected features of the layer
            features = layer.selectedFeatures()
            for feature in features:
                # Append 'feature_id' into the list
                if view == 'inp_dscenario_demand':
                    try:
                        selected_ids.append(feature.attribute(field_id))
                    except KeyError:
                        selected_ids.append(feature.attribute('connec_id'))
                        feature_type = 'connec'
                else:
                    selected_ids.append(feature.attribute(field_id))

            if selected_ids:
                inserted = {f'{feature_type}': []}
                for f in selected_ids:
                    sql = f"INSERT INTO {view}"
                    if view == 'inp_dscenario_demand':
                        sql = f"INSERT INTO ve_{view}"
                        sql += " (dscenario_id, feature_id)"
                    sql += f" VALUES ({self.selected_dscenario_id}, '{f}');"
                    result = tools_db.execute_sql(sql, log_sql=False, log_error=False, show_exception=False)
                    if result:
                        inserted[f'{feature_type}'].append(f)
                self._fill_dscenario_table()

                self.dlg_dscenario.btn_snapping.setChecked(False)

                # Just select the inserted features
                tools_gw.get_expression_filter(feature_type, inserted, {f"{feature_type}": [layer]})

    def _selection_end(self):
        """ Stop selection mode """

        tools_gw.disconnect_signal('dscenario_snapping')
        tools_gw.remove_selection()
        tools_gw.reset_rubberband(self.rubber_band)
        self.iface.actionPan().trigger()

    def _select_with_expression_dialog(self):
        """Select features by expression for dscenario"""

        # Get current layer and feature type
        self._manage_feature_type()
        view_name = self.dlg_dscenario.main_tab.currentWidget().objectName()
        layer_name = 've_' + self.feature_type

        if view_name != 'inp_dscenario_demand':
            if self.feature_type == 'nodarc':
                layer_name = view_name.replace("dscenario_", "")

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
            self.dlg_dscenario,
            self.dlg_dscenario.main_tab.currentWidget(),
            layer_name,
            self._selection_init,
            self._selection_end
        )

    def _build_generic_info(self, dlg_title, result, tablename, field_id, force_action=None):
        # Build dlg
        self.add_dlg = GwInfoGenericUi(self)
        tools_gw.load_settings(self.add_dlg)
        self.my_json_add = {}
        tools_gw.build_dialog_info(self.add_dlg, result, my_json=self.my_json_add)
        layout = self.add_dlg.findChild(QGridLayout, 'lyt_main_1')
        self.add_dlg.actionEdit.setVisible(False)
        # Disable widgets if updating
        if force_action == "UPDATE":
            tools_qt.set_widget_enabled(self.add_dlg, f'tab_none_{field_id}', False)  # sector_id/dma_id/...
        # Populate dscenario_id
        if self.selected_dscenario_id is not None:
            cmb_dscenario_id = self.add_dlg.findChild(QComboBox, 'tab_none_dscenario_id')
            tools_qt.set_combo_value(cmb_dscenario_id, self.selected_dscenario_id, 0)
            tools_qt.set_widget_enabled(self.add_dlg, 'tab_none_dscenario_id', False)
            # tools_qt.set_checked(self.add_dlg, 'tab_none_active', True)
            field_id = ['dscenario_id', field_id]
            if tablename == "inp_dscenario_pump_additional":
                field_id.append('order_id')
        if tablename in ('inp_dscenario_controls', 'inp_dscenario_rules', 'inp_dscenario_demand'):
            field_id = 'id'

        # Get every widget in the layout
        widgets = []
        for row in range(layout.rowCount()):
            for column in range(layout.columnCount()):
                item = layout.itemAtPosition(row, column)
                if item is not None:
                    widget = item.widget()
                    if widget is not None and type(widget) is not QLabel:
                        widgets.append(widget)
        # Get all widget's values
        for widget in widgets:
            tools_gw.get_values(self.add_dlg, widget, self.my_json_add, ignore_editability=True)
        # Remove Nones from self.my_json_add
        keys_to_remove = []
        for key, value in self.my_json_add.items():
            if value is None:
                keys_to_remove.append(key)
        for key in keys_to_remove:
            del self.my_json_add[key]
        # Signals
        self.add_dlg.btn_close.clicked.connect(partial(tools_gw.close_dialog, self.add_dlg))
        self.add_dlg.dlg_closed.connect(partial(tools_gw.close_dialog, self.add_dlg))
        self.add_dlg.dlg_closed.connect(self._manage_current_changed)
        self.add_dlg.btn_accept.clicked.connect(
            partial(self._accept_add_dlg, self.add_dlg, tablename, field_id, None, self.my_json_add, result, force_action))
        # Open dlg
        tools_gw.open_dialog(self.add_dlg, dlg_name='info_generic', title=dlg_title)

    def _accept_add_dlg(self, dialog, tablename, pkey, feature_id, my_json, complet_result, force_action):
        if not my_json:
            return

        list_mandatory = []
        list_filter = []

        for field in complet_result['body']['data']['fields']:
            if field['ismandatory']:
                widget = dialog.findChild(QWidget, field['widgetname'])
                if not widget:
                    continue
                widget.setStyleSheet(None)
                value = tools_qt.get_text(dialog, widget)
                if value in ('null', None, ''):
                    widget.setStyleSheet("border: 1px solid red")
                    list_mandatory.append(field['widgetname'])
                else:
                    elem = [field['columnname'], value]
                    list_filter.append(elem)

        if list_mandatory:
            msg = "Some mandatory values are missing. Please check the widgets marked in red."
            tools_qgis.show_warning(msg, dialog=dialog)
            tools_qt.set_action_checked("actionEdit", True, dialog)
            return False

        fields = json.dumps(my_json)
        id_val = ""
        if pkey:
            if not isinstance(pkey, list):
                pkey = [pkey]
            for pk in pkey:
                results = pk.split(',')
                for result in results:
                    widget_name = f"tab_none_{result}"
                    value = tools_qt.get_widget_value(dialog, widget_name)
                    id_val += f"{value}, "
            id_val = id_val[:-2]
        if id_val in (None, '', 'None'):
            id_val = complet_result['body']['feature']['id']
        feature = f'"id":"{id_val}", '
        feature += f'"tableName":"{tablename}"'
        extras = f'"fields":{fields}'
        if force_action:
            extras += f', "force_action":"{force_action}"'
        body = tools_gw.create_body(feature=feature, extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_upsertfields', body)
        if json_result and json_result.get('status') == 'Accepted':
            tools_gw.close_dialog(dialog)
            return

        msg = "Error"
        tools_qgis.show_warning(msg, parameter=json_result, dialog=dialog)

    # endregion
