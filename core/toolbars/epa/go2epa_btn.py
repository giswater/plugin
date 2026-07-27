"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import os
import sys
import json

from functools import partial
from qgis.PyQt.sip import isdeleted
from time import time
from datetime import timedelta

from qgis.PyQt.QtCore import QStringListModel, Qt, QTimer, QRegularExpression, QPoint
from qgis.PyQt.QtWidgets import QWidget, QComboBox, QCompleter, QGroupBox, QSpacerItem, QSizePolicy, QGridLayout, QLabel, QTabWidget, QMenu, QAction, QActionGroup
from qgis.PyQt.QtGui import QIcon
from qgis.core import QgsApplication

from ...shared.selector import GwSelector
from ...threads.epa_file_manager import GwEpaFileManager
from ...utils import tools_gw
from ...ui.ui_manager import GwGo2EpaUI, GwSelectorUi, GwGo2EpaOptionsUi
from .... import global_vars
from ....libs import lib_vars, tools_qgis, tools_qt, tools_db
from ..dialog import GwAction
from .epa_tools.go2iber import Go2Iber


class GwGo2EpaButton(GwAction):
    """ Button 42: Go2epa """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        if icon_path is not None:
            super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.project_type = global_vars.project_type
        self.epa_options_list = []
        self.iface = global_vars.iface

        if self.project_type == 'ud' and tools_qgis.is_plugin_active('IberGIS'):
            # Create a menu and add all the actions
            self.menu = QMenu()
            self.menu.setObjectName("GW_epa_tools")
            self._fill_action_menu()

            if toolbar is not None:
                self.action.setMenu(self.menu)
                toolbar.addAction(self.action)

    def clicked_event(self):
        if self.project_type == 'ud' and tools_qgis.is_plugin_active('IberGIS'):
            if hasattr(self.action, 'associatedObjects'):
                button = QWidget(self.action.associatedObjects()[1])
            elif hasattr(self.action, 'associatedWidgets'):
                button = self.action.associatedWidgets()[1]
            menu_point = button.mapToGlobal(QPoint(0, button.height()))
            self.menu.exec(menu_point)
        else:
            self._open_go2epa()

    def _fill_action_menu(self):
        """ Fill action menu """

        # disconnect and remove previuos signals and actions
        actions = self.menu.actions()
        for action in actions:
            action.disconnect()
            self.menu.removeAction(action)
            del action
        ag = QActionGroup(self.iface.mainWindow())

        new_actions = [
            (self.menu, ('ud'), tools_qt.tr('Go2EPA'), None),
        ]

        # Add Go2Iber action if ibergis plugin is available
        if tools_qgis.is_plugin_active('IberGIS'):
            new_actions.append((self.menu, ('ud'), tools_qt.tr('Go2IBER'), QIcon(f"{lib_vars.plugin_dir}{os.sep}icons{os.sep}toolbars{os.sep}epa{os.sep}47.png")))

        for menu, types, action, icon in new_actions:
            if global_vars.project_type in types:
                if icon:
                    obj_action = QAction(icon, f"{action}", ag)
                else:
                    obj_action = QAction(f"{action}", ag)
                menu.addAction(obj_action)
                obj_action.triggered.connect(partial(self._get_selected_action, action))

        # Remove menu if it is empty
        for menu in self.menu.findChildren(QMenu):
            if not len(menu.actions()):
                menu.menuAction().setParent(None)

    def _get_selected_action(self, name):
        """ Gets selected action """

        if name == tools_qt.tr('Go2EPA'):
            self._open_go2epa()

        elif name == tools_qt.tr('Go2IBER'):
            go2iber = Go2Iber()
            if go2iber.check_ibergis_project():
                go2iber.clicked_event()
            else:
                msg = "You have to import a ibergis GPKG project first"
                tools_qgis.show_warning(msg)

    def check_result_id(self):
        """ Check if selected @result_id already exists """

        self.dlg_go2epa.txt_result_name.setStyleSheet(None)

    # region private functions

    def _open_go2epa(self):

        self._go2epa()

    def _go2epa(self):
        """ Button 42: Open form to set INP, RPT and project """

        # Show form in docker?
        tools_gw.init_docker('qgis_form_docker')

        # Create dialog
        self.dlg_go2epa = GwGo2EpaUI(self)
        tools_gw.load_settings(self.dlg_go2epa)
        self._load_user_values()
        if self.project_type in 'ws':
            self.dlg_go2epa.chk_export_subcatch.setVisible(False)

        # Set signals
        self._set_signals()
        self.dlg_go2epa.btn_cancel.setEnabled(False)

        # Disable tab log
        tools_gw.disable_tab_log(self.dlg_go2epa)

        # Set shortcut keys
        self.dlg_go2epa.key_escape.connect(partial(tools_gw.close_docker))

        self.dlg_go2epa.btn_hs_ds.clicked.connect(
            partial(self._sector_selection))

        # Execute EPA: Windows always; Linux only for WS (hydraulic_engine). UD needs native SWMM exe.
        try:
            from importlib.util import find_spec
            has_hydraulic_engine = find_spec("hydraulic_engine") is not None
        except ImportError:
            has_hydraulic_engine = False

        if sys.platform != "win32" and (not has_hydraulic_engine or self.project_type == "ud"):
            tools_qt.set_checked(self.dlg_go2epa, self.dlg_go2epa.chk_exec, False)
            self.dlg_go2epa.chk_exec.setEnabled(False)
            self.dlg_go2epa.chk_exec.setText('Execute EPA software (Runs only on Windows)')

        self._set_completer_result(self.dlg_go2epa.txt_result_name, 'v_ui_rpt_cat_result', 'result_id')
        self.check_result_id()
        if lib_vars.session_vars['dialog_docker']:
            tools_gw.docker_dialog(self.dlg_go2epa, dlg_name='go2epa', title='go2epa')
            self.dlg_go2epa.btn_close.clicked.disconnect()
            self.dlg_go2epa.btn_close.clicked.connect(partial(tools_gw.close_docker, option_name='position'))
        else:
            tools_gw.open_dialog(self.dlg_go2epa, dlg_name='go2epa')

    def _set_signals(self):

        self.dlg_go2epa.btn_cancel.clicked.connect(self._cancel_task)
        self.dlg_go2epa.txt_result_name.textChanged.connect(partial(self.check_result_id))
        self.dlg_go2epa.btn_file_inp.clicked.connect(self._go2epa_select_file_inp)
        self.dlg_go2epa.btn_file_rpt.clicked.connect(self._go2epa_select_file_rpt)
        self.dlg_go2epa.btn_accept.clicked.connect(self._go2epa_accept)
        self.dlg_go2epa.btn_close.clicked.connect(partial(tools_gw.close_dialog, self.dlg_go2epa))
        self.dlg_go2epa.rejected.connect(partial(tools_gw.close_dialog, self.dlg_go2epa))
        self.dlg_go2epa.btn_options.clicked.connect(self._go2epa_options)
        self.dlg_go2epa.mainTab.currentChanged.connect(partial(self._manage_btn_accept))

    def _manage_btn_accept(self, index):
        """
        Disable btn_accept when on tab info log and/or if go2epa_task is active
            :param index: tab index (passed by signal)
        """
        # Set network mode to 1
        if self.project_type == 'ud' and tools_qgis.is_plugin_active('IberGIS'):
            form = '"formName":"epaoptions"'
            my_json = '[{"widget": "inp_options_networkmode", "value": "1"}]'
            extras = f'"fields":{my_json}'
            body = tools_gw.create_body(form=form, extras=extras)
            tools_gw.execute_procedure('gw_fct_setconfig', body)

        if index == 1:
            self.dlg_go2epa.btn_accept.setEnabled(False)
        else:
            # Disable if task is active, enabled otherwise
            if hasattr(self, 'go2epa_task') and self.go2epa_task is not None:
                try:
                    if self.go2epa_task.isActive():
                        self.dlg_go2epa.btn_accept.setEnabled(False)
                        return
                except RuntimeError:
                    pass
            self.dlg_go2epa.btn_accept.setEnabled(True)

    def _check_inp_chk(self, file_inp):

        if file_inp is None:
            msg = "Select valid INP file"
            tools_qgis.show_warning(msg, parameter=str(file_inp))
            return False

        return True

    def _check_rpt(self):

        file_inp = tools_qt.get_text(self.dlg_go2epa, self.dlg_go2epa.txt_file_inp)
        file_rpt = tools_qt.get_text(self.dlg_go2epa, self.dlg_go2epa.txt_file_rpt)

        # Control execute epa software
        if tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_exec):
            if not self._check_inp_chk(file_inp):
                return False

            if file_rpt is None:
                msg = "Select valid RPT file"
                tools_qgis.show_warning(msg, parameter=str(file_rpt))
                return False

            if not tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_export):
                if not os.path.exists(file_inp):
                    msg = "File INP not found"
                    tools_qgis.show_warning(msg, parameter=str(file_inp))
                    return False

        return True

    def _check_fields(self):

        file_inp = tools_qt.get_text(self.dlg_go2epa, self.dlg_go2epa.txt_file_inp)
        file_rpt = tools_qt.get_text(self.dlg_go2epa, self.dlg_go2epa.txt_file_rpt)
        result_name = tools_qt.get_text(self.dlg_go2epa, self.dlg_go2epa.txt_result_name, False, False)

        # Check if at least one process is selected
        export_checked = tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_export)
        exec_checked = tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_exec)
        import_result_checked = tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_import_result)

        if not export_checked and not exec_checked and not import_result_checked:
            msg = "You need to select at least one process"
            title = "Go2Epa"
            tools_qt.show_info_box(msg, title)
            return False

        if import_result_checked and not exec_checked:
            msg = "Import results requires Execute EPA software"
            title = "Go2Epa"
            tools_qt.show_info_box(msg, title)
            return False

        # Control export INP
        if export_checked:
            if not self._check_inp_chk(file_inp):
                return False

        # Control execute epa software
        if not self._check_rpt():
            return False

        # Control import result
        if import_result_checked:
            if file_rpt is None:
                msg = "Select valid RPT file"
                tools_qgis.show_warning(msg, parameter=str(file_rpt))
                return False
            if not tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_exec):
                if not os.path.exists(file_rpt):
                    msg = "File RPT not found"
                    tools_qgis.show_warning(msg, parameter=str(file_rpt))
                    return False
            else:
                if not self._check_rpt():
                    return False

        # Control result name
        if result_name == '':
            self.dlg_go2epa.txt_result_name.setStyleSheet("border: 1px solid red")
            msg = "This parameter is mandatory. Please, set a value"
            title = "Rpt fail"
            tools_qt.show_details(msg, title, inf_text=None)
            return False

        self.dlg_go2epa.txt_result_name.setStyleSheet(None)

        sql = (f"SELECT result_id FROM rpt_cat_result "
               f"WHERE result_id = '{result_name}' LIMIT 1")
        row = tools_db.get_row(sql)
        if import_result_checked and not export_checked and not exec_checked:
            if not row:
                msg = "Result name not found. It's not possible to import RPT file into database"
                title = "Import RPT file"
                tools_qt.show_info_box(msg, title)
                return False
        else:
            if row:
                msg = "Result name already exists, do you want overwrite?"
                title = "Alert"
                answer = tools_qt.show_question(msg, title)
                if not answer:
                    return False

        return True

    def _load_user_values(self):
        """ Load QGIS settings related with file_manager """

        self.dlg_go2epa.txt_result_name.setMaxLength(16)
        self.result_name = tools_gw.get_config_parser('btn_go2epa', 'go2epa_RESULT_NAME', "user", "session")
        self.dlg_go2epa.txt_result_name.setText(self.result_name)
        self.file_inp = tools_gw.get_config_parser('btn_go2epa', 'go2epa_FILE_INP', "user", "session")
        self.dlg_go2epa.txt_file_inp.setText(self.file_inp)
        self.file_rpt = tools_gw.get_config_parser('btn_go2epa', 'go2epa_FILE_RPT', "user", "session")
        self.dlg_go2epa.txt_file_rpt.setText(self.file_rpt)

        value = tools_gw.get_config_parser('btn_go2epa', 'go2epa_chk_INP', "user", "session")
        tools_qt.set_checked(self.dlg_go2epa, self.dlg_go2epa.chk_export, value)
        value = tools_gw.get_config_parser('btn_go2epa', 'go2epa_chk_UD', "user", "session")
        tools_qt.set_checked(self.dlg_go2epa, self.dlg_go2epa.chk_export_subcatch, value)
        value = tools_gw.get_config_parser('btn_go2epa', 'go2epa_chk_EPA', "user", "session")
        tools_qt.set_checked(self.dlg_go2epa, self.dlg_go2epa.chk_exec, value)
        value = tools_gw.get_config_parser('btn_go2epa', 'go2epa_chk_RPT', "user", "session")
        tools_qt.set_checked(self.dlg_go2epa, self.dlg_go2epa.chk_import_result, value)

    def _save_user_values(self):
        """ Save QGIS settings related with file_manager """

        txt_result_name = f"{tools_qt.get_text(self.dlg_go2epa, 'txt_result_name', return_string_null=False)}"
        tools_gw.set_config_parser('btn_go2epa', 'go2epa_RESULT_NAME', f"{txt_result_name}")
        txt_file_inp = f"{tools_qt.get_text(self.dlg_go2epa, 'txt_file_inp', return_string_null=False)}"
        tools_gw.set_config_parser('btn_go2epa', 'go2epa_FILE_INP', f"{txt_file_inp}")
        txt_file_rpt = f"{tools_qt.get_text(self.dlg_go2epa, 'txt_file_rpt', return_string_null=False)}"
        tools_gw.set_config_parser('btn_go2epa', 'go2epa_FILE_RPT', f"{txt_file_rpt}")
        chk_export = f"{tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_export)}"
        tools_gw.set_config_parser('btn_go2epa', 'go2epa_chk_INP', f"{chk_export}")
        chk_export_subcatch = f"{tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_export_subcatch)}"
        tools_gw.set_config_parser('btn_go2epa', 'go2epa_chk_UD', f"{chk_export_subcatch}")
        chk_exec = f"{tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_exec)}"
        tools_gw.set_config_parser('btn_go2epa', 'go2epa_chk_EPA', f"{chk_exec}")
        chk_import_result = f"{tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_import_result)}"
        tools_gw.set_config_parser('btn_go2epa', 'go2epa_chk_RPT', f"{chk_import_result}")

    def _sector_selection(self):
        """ Load the tables in the selection form """

        # Get class Selector from selector.py
        go2epa_selector = GwSelector()

        # Create the dialog
        dlg_selector = GwSelectorUi(self)
        tools_gw.load_settings(dlg_selector)

        # Create the common signals
        go2epa_selector.get_selector(dlg_selector, '"selector_basic"', current_tab='tab_dscenario')
        tools_gw.save_current_tab(dlg_selector, dlg_selector.main_tab, 'basic')

        dlg_selector.findChild(QTabWidget, 'main_tab').currentChanged.connect(partial(
            tools_gw.save_current_tab, dlg_selector, dlg_selector.main_tab, 'basic'))

        # Open form
        if lib_vars.session_vars['dialog_docker']:
            # Set signals when have docker form
            dlg_selector.btn_close.clicked.connect(partial(tools_gw.docker_dialog, self.dlg_go2epa, dlg_name='selector', title='selector'))
            dlg_selector.btn_close.clicked.connect(partial(self._manage_form_settings, 'restore'))
            # Save widgets settings from go2epa form
            self._manage_form_settings('save')
            # Open form
            tools_gw.docker_dialog(dlg_selector, dlg_name='selector', title='selector')
        else:
            # Set signals when have not docker form
            dlg_selector.btn_close.clicked.connect(partial(tools_gw.close_dialog, dlg_selector))
            # Open form
            tools_gw.open_dialog(dlg_selector, dlg_name='selector')

    def _manage_form_settings(self, action):

        if action == 'save':
            # Get widgets form values
            self.txt_result_name = tools_qt.get_text(self.dlg_go2epa, self.dlg_go2epa.txt_result_name)
            self.chk_export = self.dlg_go2epa.chk_export.isChecked()
            self.chk_export_subcatch = self.dlg_go2epa.chk_export_subcatch.isChecked()
            self.txt_file_inp = tools_qt.get_text(self.dlg_go2epa, self.dlg_go2epa.txt_file_inp)
            self.chk_exec = self.dlg_go2epa.chk_exec.isChecked()
            self.txt_file_rpt = tools_qt.get_text(self.dlg_go2epa, self.dlg_go2epa.txt_file_rpt)
            self.chk_import_result = self.dlg_go2epa.chk_import_result.isChecked()
        elif action == 'restore':
            # Set widgets form values
            if self.txt_result_name is not 'null':
                tools_qt.set_widget_text(self.dlg_go2epa, self.dlg_go2epa.txt_result_name, self.txt_result_name)
            if self.chk_export is not 'null':
                tools_qt.set_widget_text(self.dlg_go2epa, self.dlg_go2epa.chk_export, self.chk_export)
            if self.chk_export_subcatch is not 'null':
                tools_qt.set_widget_text(self.dlg_go2epa, self.dlg_go2epa.chk_export_subcatch, self.chk_export_subcatch)
            if self.txt_file_inp is not 'null':
                tools_qt.set_widget_text(self.dlg_go2epa, self.dlg_go2epa.txt_file_inp, self.txt_file_inp)
            if self.chk_exec is not 'null':
                tools_qt.set_widget_text(self.dlg_go2epa, self.dlg_go2epa.chk_exec, self.chk_exec)
            if self.txt_file_rpt is not 'null':
                tools_qt.set_widget_text(self.dlg_go2epa, self.dlg_go2epa.txt_file_rpt, self.txt_file_rpt)
            if self.chk_import_result is not 'null':
                tools_qt.set_widget_text(self.dlg_go2epa, self.dlg_go2epa.chk_import_result, self.chk_import_result)

    def _go2epa_select_file_inp(self):
        """ Select INP file """

        message = "Select INP file"
        if tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_export):
            tools_qt.get_save_file_path(self.dlg_go2epa, self.dlg_go2epa.txt_file_inp, '*.inp', message)
        else:
            tools_qt.get_open_file_path(self.dlg_go2epa, self.dlg_go2epa.txt_file_inp, '*.inp', message)

    def _go2epa_select_file_rpt(self):
        """ Select RPT file """

        message = "Select RPT file"
        if tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_export):
            tools_qt.get_save_file_path(self.dlg_go2epa, self.dlg_go2epa.txt_file_rpt, '*.rpt', message)
        else:
            tools_qt.get_open_file_path(self.dlg_go2epa, self.dlg_go2epa.txt_file_rpt, '*.rpt', message)

    def _go2epa_accept(self):
        """ Save INP, RPT and result name"""

        # Manage if task is already running
        if hasattr(self, 'go2epa_task') and self.go2epa_task is not None:
            try:
                if self.go2epa_task.isActive():
                    message = "Go2Epa task is already active!"
                    tools_qgis.show_warning(message)
                    return
            except RuntimeError:
                pass

        # Check if import result is enabled and RPT file exists
        if tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_import_result) or tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_exec):
            file_rpt = tools_qt.get_text(self.dlg_go2epa, self.dlg_go2epa.txt_file_rpt)
            if not file_rpt or file_rpt == 'null':
                message = tools_qt.tr("RPT file path is required when importing results or executing EPA")
                tools_qgis.show_warning(message)
                return
        # Save user values
        self._save_user_values()

        self.dlg_go2epa.tab_log_txt_infolog.clear()
        self.dlg_go2epa.txt_file_rpt.setStyleSheet(None)
        status = self._check_fields()
        if status is False:
            return

        # Get widgets values
        self.result_name = tools_qt.get_text(self.dlg_go2epa, self.dlg_go2epa.txt_result_name, False, False)
        self.export_inp = tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_export)
        self.export_subcatch = tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_export_subcatch)
        self.file_inp = tools_qt.get_text(self.dlg_go2epa, self.dlg_go2epa.txt_file_inp)
        self.exec_epa = tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_exec)
        self.file_rpt = tools_qt.get_text(self.dlg_go2epa, self.dlg_go2epa.txt_file_rpt)
        self.import_result = tools_qt.is_checked(self.dlg_go2epa, self.dlg_go2epa.chk_import_result)

        # Check for sector selector
        if self.export_inp:
            sql = "SELECT sector_id FROM selector_sector WHERE sector_id > 0 LIMIT 1"
            row = tools_db.get_row(sql)
            if row is None:
                msg = "You need to select some sector"
                tools_qt.show_info_box(msg)
                return

        if self.export_inp and self.file_inp == "null":
            message = "You have to set this parameter: INP file"
            tools_qgis.show_warning(message, dialog=self.dlg_go2epa)
            return

        if self.exec_epa and self.file_rpt == "null":
            message = "You have to set this parameter"
            self.error_msg = "{0}: RPT file"
            self.error_msg_params = (message,)
            tools_qgis.show_warning(message, dialog=self.dlg_go2epa)
            return

        self.dlg_go2epa.btn_accept.setEnabled(False)
        self.dlg_go2epa.btn_cancel.setEnabled(True)

        # Create timer
        self.t0 = time()
        self.timer = QTimer()
        self.timer.timeout.connect(partial(self._calculate_elapsed_time, self.dlg_go2epa))
        self.timer.start(1000)

        # Set background task 'Go2Epa'
        description = "Go2Epa"
        self.go2epa_task = GwEpaFileManager(description, self, timer=self.timer, network_mode=1)
        self.go2epa_task.step_completed.connect(self.step_completed)
        QgsApplication.taskManager().addTask(self.go2epa_task)
        QgsApplication.taskManager().triggerTask(self.go2epa_task)

    def _cancel_task(self):

        if hasattr(self, 'go2epa_task'):
            self.go2epa_task.cancel()

    def step_completed(self, json_result, end="\n"):

        message = json_result.get('message')
        if message:
            data = {"info": {"values": [{"message": message.get('text')}]}}
            tools_gw.fill_tab_log(self.dlg_go2epa, data, reset_text=False, close=False, end=end, call_set_tabs_enabled=False)

    def _set_completer_result(self, widget, viewname, field_name):
        """ Set autocomplete of widget 'feature_id'
            getting id's from selected @viewname
        """

        # Adding auto-completion to a QLineEdit
        self.completer = QCompleter()
        self.completer.setCaseSensitivity(Qt.CaseSensitivity.CaseInsensitive)
        widget.setCompleter(self.completer)
        model = QStringListModel()

        sql = f"SELECT {field_name} FROM {viewname}"
        rows = tools_db.get_rows(sql)

        if rows:
            for i in range(0, len(rows)):
                aux = rows[i]
                rows[i] = str(aux[0])

            model.setStringList(rows)
            self.completer.setModel(model)

    def _refresh_go2epa_options(self, dialog):
        """ Refresh widgets into layouts on go2epa_options form """

        if dialog:
            for lyt in dialog.findChildren(QGridLayout, QRegularExpression('lyt_')):
                i = 0
                while i < lyt.count():
                    item = lyt.itemAt(i)
                    widget = item.widget()
                    if widget:
                        widget.deleteLater()
                    else:  # for QSpacerItems
                        lyt.removeItem(item)
                    i += 1

            form = '"formName":"epaoptions"'
            body = tools_gw.create_body(form=form)
            json_result = tools_gw.execute_procedure('gw_fct_getconfig', body)
            if not json_result or json_result['status'] == 'Failed':
                return False

            tools_gw.build_dialog_options(
                dialog, json_result['body']['form']['formTabs'], 0, self.epa_options_list)
            grbox_list = dialog.findChildren(QGroupBox)
            for grbox in grbox_list:
                widget_list = grbox.findChildren(QWidget)
                if len(widget_list) == 0:
                    grbox.setVisible(False)
                else:
                    layout_list = grbox.findChildren(QGridLayout)
                    for lyt in layout_list:
                        spacer = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
                        lyt.addItem(spacer)

    def _go2epa_options(self):
        """ Button 42: Open form to set INP, RPT and project """

        # Clear list
        self.epa_options_list = []

        # Create dialog
        self.dlg_go2epa_options = GwGo2EpaOptionsUi(self)
        tools_gw.load_settings(self.dlg_go2epa_options)
        self.dlg_go2epa_options.setProperty('GwGo2EpaButton', self)

        form = '"formName":"epaoptions"'
        body = tools_gw.create_body(form=form)
        json_result = tools_gw.execute_procedure('gw_fct_getconfig', body)
        if not json_result or json_result['status'] == 'Failed':
            return False

        tools_gw.build_dialog_options(
            self.dlg_go2epa_options, json_result['body']['form']['formTabs'], 0, self.epa_options_list)
        grbox_list = self.dlg_go2epa_options.findChildren(QGroupBox)
        for grbox in grbox_list:
            widget_list = grbox.findChildren(QWidget)
            if len(widget_list) == 0:
                grbox.setVisible(False)
            else:
                layout_list = grbox.findChildren(QGridLayout)
                for lyt in layout_list:
                    spacer = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
                    lyt.addItem(spacer)

        # Event on change from combo parent
        self._get_event_combo_parent(json_result)
        self.dlg_go2epa_options.btn_accept.clicked.connect(partial(self._update_values, self.epa_options_list))
        self.dlg_go2epa_options.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_go2epa_options))
        self.dlg_go2epa_options.rejected.connect(partial(tools_gw.close_dialog, self.dlg_go2epa_options))
        self.dlg_go2epa_options.findChild(QTabWidget, 'tabWidget').currentChanged.connect(partial(
            tools_gw.save_current_tab, self.dlg_go2epa_options, self.dlg_go2epa_options.tabWidget, 'main'))

        current_tab = tools_gw.get_config_parser('dialogs_tab', "dlg_go2epa_options_main", "user", "session")
        if current_tab:
            tab = self.dlg_go2epa_options.tabWidget.findChild(QWidget, current_tab)
            self.dlg_go2epa_options.tabWidget.setCurrentWidget(tab)
        tools_gw.open_dialog(self.dlg_go2epa_options, dlg_name='go2epa_options')

    def _update_values(self, _json):

        my_json = json.dumps(_json)
        form = '"formName":"epaoptions"'
        extras = f'"fields":{my_json}'
        body = tools_gw.create_body(form=form, extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_setconfig', body)
        if not json_result or json_result['status'] == 'Failed':
            return False

        # Refresh epa world view if is active and it has changed
        if any(widget['widget'] == 'inp_options_networkmode' for widget in _json):
            tools_qgis.force_refresh_map_canvas()

        msg = "Values has been updated"
        tools_qgis.show_info(msg)
        # Close dialog
        tools_gw.close_dialog(self.dlg_go2epa_options)

    def _get_event_combo_parent(self, complet_result):

        for field in complet_result['body']['form']['formTabs'][0]["fields"]:
            if field['isparent']:
                widget = self.dlg_go2epa_options.findChild(QComboBox, field['widgetname'])
                if widget:
                    widget.currentIndexChanged.connect(partial(self._fill_child, self.dlg_go2epa_options, widget))

    def _fill_child(self, dialog, widget):

        combo_parent = widget.objectName()
        combo_id = tools_qt.get_combo_value(dialog, widget)
        # TODO cambiar por gw_fct_getchilds then unified with tools_gw.get_child if posible
        json_result = tools_gw.execute_procedure('gw_fct_getcombochilds', f"'epaoptions', '', '', '{combo_parent}', '{combo_id}', ''")
        if not json_result or json_result['status'] == 'Failed':
            return False

        for combo_child in json_result['fields']:
            if combo_child is not None:
                tools_gw.manage_combo_child(dialog, widget, combo_child)

    def _calculate_elapsed_time(self, dialog):

        tf = time()  # Final time
        td = tf - self.t0  # Delta time
        self._update_time_elapsed(f"Exec. time: {timedelta(seconds=round(td))}", dialog)

    def _update_time_elapsed(self, text, dialog):

        if isdeleted(dialog):
            self.timer.stop()
            return

        lbl_time = dialog.findChild(QLabel, 'lbl_time')
        lbl_time.setText(text)

    # endregion
