"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import configparser
import os
import re

from functools import partial
from time import time
from datetime import timedelta

from qgis.core import QgsApplication
from qgis.PyQt.QtCore import QPoint, QRegularExpression, QTimer
from qgis.PyQt.QtGui import QIntValidator, QRegularExpressionValidator
from qgis.PyQt.QtWidgets import (
    QMenu,
    QAction,
    QActionGroup,
    QWidget,
)


from .... import global_vars

from ....libs import tools_qgis, tools_os, tools_qt, lib_vars, tools_db
from ...utils import tools_gw
from ..dialog import GwAction

from .priority_btn import CalculatePriority
from ...threads.assignation import GwAssignation
from ...ui.ui_manager import GwAssignationUi


class GwAmBreakageButton(GwAction):
    """Button 73: Breakage button
    Dropdown with two options: 'Incremental load' and 'Assigning'"""

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.iface = global_vars.iface

        self.icon_path = icon_path
        self.action_name = action_name
        self.text = text
        self.toolbar = toolbar
        self.action_group = action_group

        # Menu labels
        title = "Breakdown Assignation"
        self.txt_assignation = tools_qt.tr(title)
        title = "Priority Calculation (Global)"
        self.txt_priority = tools_qt.tr(title)

        # Create a menu and add all the actions
        self.menu = QMenu()
        self.menu.setObjectName("AM_breakage_tools")
        self._fill_action_menu()

        if toolbar and self.action:
            self.action.setMenu(self.menu)
            toolbar.addAction(self.action)

        # Assignation variables
        self.dlg_assignation = None

    def clicked_event(self):
        if self.action:
            if hasattr(self.action, 'associatedObjects'):
                button = QWidget(self.action.associatedObjects()[1])
            elif hasattr(self.action, 'associatedWidgets'):
                button = self.action.associatedWidgets()[1]
            menu_point = button.mapToGlobal(QPoint(0, button.height()))
            self.menu.exec(menu_point)

    def _fill_action_menu(self):
        """Fill action menu"""

        # Remove all previous actions from the menu
        for action in self.menu.actions():
            self.menu.removeAction(action)
            action.deleteLater()  # Ensure the action is properly deleted

        # Create a new QActionGroup to prevent persistent references
        self.ag = QActionGroup(self.iface.mainWindow())

        # Avoid adding duplicate actions by checking existing ones
        actions = [
            self.txt_assignation,
            self.txt_priority,
        ]

        existing_actions = {a.text() for a in self.menu.actions()}  # Get current action texts
        for action in actions:
            if str(action) not in existing_actions:  # Check if it already exists
                obj_action = QAction(f"{action}", self.ag)
                self.menu.addAction(obj_action)
                obj_action.triggered.connect(partial(self._get_selected_action, action))

    def _get_selected_action(self, name):
        """Gets selected action"""

        if name == self.txt_assignation:
            self.assignation()
        elif name == self.txt_priority:
            self.priority_config()
        else:
            msg = "No action found"
            tools_qgis.show_warning(msg, parameter=name)

    def priority_config(self):
        calculate_priority = CalculatePriority(type="GLOBAL")
        calculate_priority.clicked_event()

    def assignation(self):

        self.dlg_assignation = GwAssignationUi(self)
        dlg = self.dlg_assignation
        tools_gw.load_settings(dlg)
        dlg.executing = False

        # Manage form
        self._assignation_user_values("load")

        # Hidden widgets
        self._manage_hidden_form_leaks()

        int_validator = QIntValidator(0, 9999999)
        dlg.txt_buffer.setValidator(int_validator)
        dlg.txt_years.setValidator(int_validator)
        dlg.txt_years.setEnabled(not dlg.chk_all_leaks.isChecked())
        dlg.txt_max_distance.setValidator(int_validator)
        dlg.txt_cluster_length.setValidator(int_validator)

        range_validator = QRegularExpressionValidator(
            QRegularExpression(r"\d+(\.\d*)?-\d+(\.\d*)?")
        )
        dlg.txt_diameter_range.setValidator(range_validator)
        dlg.txt_diameter_range.setEnabled(dlg.chk_diameter.isChecked())

        dlg.txt_builtdate_range.setValidator(int_validator)
        dlg.txt_builtdate_range.setEnabled(dlg.chk_builtdate.isChecked())

        # Disable tab log
        tools_gw.disable_tab_log(dlg)
        dlg.progressBar.hide()

        self._set_assignation_signals()

        # Open the dialog
        tools_gw.open_dialog(self.dlg_assignation, dlg_name="assignation")

    def _manage_hidden_form_leaks(self):

        status = True
        try:
            # Read the config file
            config = configparser.ConfigParser()

            # Check variable
            if not lib_vars.plugin_dir:
                return

            config_path = os.path.join(
                lib_vars.plugin_dir, f"config{os.sep}giswater.config"
            )

            if not os.path.exists(config_path):
                msg = ("Configuration file not found, please make sure it is located in the correct directory "
                       "and try again: {0}")
                msg_params = (config_path,)
                print(tools_qt.tr(msg, list_params=msg_params))
                return

            config.read(config_path)

            # Get configuration parameters
            if (
                tools_os.set_boolean(config.get("dialog_leaks", "show_check_material"))
                is not True
            ):
                self.dlg_assignation.lbl_material.setVisible(False)
                self.dlg_assignation.chk_material.setChecked(False)
                self.dlg_assignation.chk_material.setVisible(False)
            if (
                tools_os.set_boolean(config.get("dialog_leaks", "show_check_diameter"))
                is not True
            ):
                self.dlg_assignation.lbl_diameter.setVisible(False)
                self.dlg_assignation.chk_diameter.setChecked(False)
                self.dlg_assignation.chk_diameter.setVisible(False)
                self.dlg_assignation.txt_diameter_range.setVisible(False)

        except Exception as e:
            print("read_config_file error %s" % e)
            status = False

        return status

    def _assignation_user_values(self, action):
        txt_widgets = [
            "txt_buffer",
            "txt_years",
            "txt_max_distance",
            "txt_cluster_length",
            "txt_diameter_range",
            "txt_builtdate_range",
        ]
        chk_widgets = ["chk_all_leaks", "chk_material", "chk_diameter", "chk_builtdate"]

        for widget in txt_widgets:
            if action == "load":
                value = tools_gw.get_config_parser(
                    "assignation",
                    widget,
                    "user",
                    "session"
                )
                tools_qt.set_widget_text(self.dlg_assignation, widget, value)
                if not self.dlg_assignation.txt_buffer.text():
                    self.dlg_assignation.txt_buffer.setText("50")
                if not self.dlg_assignation.txt_diameter_range.text():
                    self.dlg_assignation.txt_diameter_range.setText("0.5-2")
            elif action == "save":
                value = tools_qt.get_text(self.dlg_assignation, widget, False, False)
                value = value.replace("%", "%%")
                tools_gw.set_config_parser(
                    "assignation",
                    widget,
                    value
                )
        for widget in chk_widgets:
            if action == "load":
                value = tools_gw.get_config_parser(
                    "assignation",
                    widget,
                    "user",
                    "session"
                )
                tools_qt.set_checked(self.dlg_assignation, widget, value)
            elif action == "save":
                value = tools_qt.is_checked(self.dlg_assignation, widget)
                tools_gw.set_config_parser(
                    "assignation",
                    widget,
                    value
                )

    def _set_assignation_signals(self):
        dlg = self.dlg_assignation

        dlg.chk_all_leaks.toggled.connect(lambda x: dlg.txt_years.setEnabled(not x))
        dlg.chk_diameter.toggled.connect(dlg.txt_diameter_range.setEnabled)
        dlg.chk_builtdate.toggled.connect(dlg.txt_builtdate_range.setEnabled)
        dlg.buttonBox.accepted.disconnect()
        dlg.buttonBox.accepted.connect(self._execute_assignation)
        dlg.rejected.connect(partial(self._assignation_user_values, "save"))
        dlg.rejected.connect(partial(tools_gw.close_dialog, dlg))

    def _execute_assignation(self):
        dlg = self.dlg_assignation

        inputs = self._validate_assignation_input()
        if not inputs:
            return
        use_material = dlg.chk_material.isChecked()
        (
            buffer,
            years,
            max_distance,
            cluster_length,
            diameter_range,
            builtdate_range,
        ) = inputs

        msg = "This task may take some time to complete, do you want to proceed?"
        if not tools_qt.show_question(msg):
            return

        title = "Breakdown Assignation"
        self.thread = GwAssignation(
            tools_qt.tr(title),
            buffer,
            years,
            max_distance,
            cluster_length,
            use_material,
            diameter_range,
            builtdate_range,
        )
        t = self.thread
        t.taskCompleted.connect(self._assignation_ended)
        t.taskTerminated.connect(self._assignation_ended)

        # Set timer
        self.t0 = time()
        self.timer = QTimer()
        self.timer.timeout.connect(partial(self._update_timer, dlg.lbl_timer))
        self.timer.start(250)

        # Log behavior
        t.report.connect(
            partial(tools_gw.fill_tab_log, dlg, reset_text=False, close=False)
        )

        # Progress bar behavior
        dlg.progressBar.show()
        t.progressChanged.connect(lambda value: dlg.progressBar.setValue(int(value)))

        # Button OK behavior
        ok = dlg.buttonBox.StandardButton.Ok
        dlg.buttonBox.button(ok).setEnabled(False)

        # Button Cancel behavior
        dlg.buttonBox.rejected.disconnect()
        dlg.buttonBox.rejected.connect(partial(self._cancel_thread, dlg))

        dlg.executing = True
        QgsApplication.taskManager().addTask(t)

    def _validate_assignation_input(self):
        dlg = self.dlg_assignation

        try:
            buffer = int(dlg.txt_buffer.text())
        except ValueError:
            msg = "Invalid buffer value. Please enter an valid integer."
            tools_qt.show_info_box(msg)
            return

        if buffer > 1000:
            msg = "Invalid buffer value. Please enter an integer less than 1000."
            tools_qt.show_info_box(msg)
            return

        if dlg.chk_all_leaks.isChecked():
            years = None
        else:
            try:
                years = int(dlg.txt_years.text())
            except ValueError:
                msg = "Please enter a valid integer for the number of years."
                tools_qt.show_info_box(msg)
                return

        try:
            max_distance = int(dlg.txt_max_distance.text())
        except ValueError:
            msg = "Please enter a valid integer for the maximum distance."
            tools_qt.show_info_box(msg)
            return

        try:
            cluster_length = int(dlg.txt_cluster_length.text())
        except ValueError:
            msg = "Please enter a valid integer for the cluster length."
            tools_qt.show_info_box(msg)
            return

        if dlg.chk_diameter.isChecked():
            diameter_range_string = dlg.txt_diameter_range.text()
            if not re.fullmatch(r"\d+(\.\d*)?-\d+(\.\d*)?", diameter_range_string):
                msg = (
                    "Please enter the diameter range in this format: "
                    "[minimum factor]-[maximum factor]. "
                    "For example, 0.75-1.5"
                )
                tools_qt.show_info_box(msg)
                return
            diameter_range = tuple(float(x) for x in diameter_range_string.split("-"))
        else:
            diameter_range = None

        if dlg.chk_builtdate.isChecked():
            try:
                builtdate_range = int(dlg.txt_builtdate_range.text())
            except ValueError:
                msg = "Please enter a valid integer for the built date range."
                tools_qt.show_info_box(msg)
                return
        else:
            builtdate_range = None

        return (
            buffer,
            years,
            max_distance,
            cluster_length,
            diameter_range,
            builtdate_range,
        )

    def _update_timer(self, widget):
        elapsed_time = time() - self.t0
        text = str(timedelta(seconds=round(elapsed_time)))
        widget.setText(text)

    def _cancel_thread(self, dlg):
        self.thread.cancel()
        tools_gw.fill_tab_log(
            dlg,
            {"info": {"values": [{"message": tools_qt.tr("Canceling task...")}]}},
            reset_text=False,
            close=False,
        )

    def _assignation_ended(self):
        dlg = self.dlg_assignation
        cancel = dlg.buttonBox.StandardButton.Cancel
        dlg.buttonBox.removeButton(dlg.buttonBox.button(cancel))
        close = dlg.buttonBox.StandardButton.Close
        dlg.buttonBox.addButton(close)
        dlg.buttonBox.rejected.disconnect()
        dlg.buttonBox.rejected.connect(dlg.reject)
        dlg.executing = False
        self.timer.stop()

        try:
            # Update symbology of layers currently loaded in the project
            target_layers = []
            sql = "SELECT id, addparam FROM sys_table WHERE source = 'am' AND addparam ->> 'refreshSymbology' = 'true'"
            rows = tools_db.get_rows(sql)
            for row in rows:
                target_layer = tools_qgis.get_layer_by_tablename(row[0], schema_name="am")
                if target_layer is None:
                    continue
                target_layers.append((target_layer, row[1]))

            if len(target_layers) > 0:
                msg = "Do you want to update the symbology of the layers currently loaded in the project?"
                title = "Update AM Layers Symbology"
                result = tools_qt.show_question(msg, title, force_action=True)
                if result:
                    for layer, addparam in target_layers:
                        tools_gw.refresh_categorized_layer_symbology_classes(layer, addparam)
        except Exception:
            pass
