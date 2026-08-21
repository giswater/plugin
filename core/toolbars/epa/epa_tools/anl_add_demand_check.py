"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""

import datetime
import json
import math
from functools import partial
from pathlib import Path
from time import time

from qgis.core import QgsApplication
from qgis.PyQt.QtCore import QTimer
from qgis.PyQt.QtWidgets import QWidget

from ....threads.add_demand_check import GwAddDemandCheck
from ....ui.ui_manager import AddDemandCheckUi
from .....libs import tools_qt, tools_db
from ....utils import tools_gw


class AddDemandCheck:
    def __init__(self):
        self.results = {}

    def clicked_event(self):
        self.dlg_adc = AddDemandCheckUi(self)
        dlg = self.dlg_adc

        tools_gw.load_settings(dlg)
        self._load_user_values()

        # TODO: Select test suites: simple, double, pairs

        self._set_signals()

        tools_gw.disable_tab_log(dlg)
        tools_gw.open_dialog(dlg, dlg_name="epatools_add_demand_check")

    def _check_for_partial_file(self):
        partial_file = Path(self.output_folder) / f"{self.file_name}-partial.json"
        if not partial_file.exists():
            return
        msg = "There is a partially completed file for this folder/file name. Would you like to resume the process?"
        continue_process = tools_qt.show_question(msg)
        if continue_process:
            with open(partial_file) as file:
                self.results = json.load(file)

    def _execute_process(self):
        if not self._validate_inputs():
            return
        if not self._ovewrite_existing_files(self.output_folder, self.file_name):
            return
        self._check_for_partial_file()
        self._save_user_values()
        self.thread = GwAddDemandCheck(
            "Additional Demand Check",
            self.input_file,
            self.config,
            self.output_folder,
            self.file_name,
            self.results,
        )
        t = self.thread
        dlg = self.dlg_adc

        # Button Cancel behavior
        dlg.btn_cancel.clicked.disconnect()
        dlg.btn_cancel.clicked.connect(t.cancel)

        # Button OK bahavior
        dlg.btn_ok.setEnabled(False)

        # Timer
        self.t0 = time()
        self.timer = QTimer()
        self.timer.timeout.connect(self._on_timer_timeout)
        self.timer.start(500)
        self.dlg_adc.rejected.connect(self.timer.stop)

        t.taskCompleted.connect(partial(self._on_task_completed))
        t.taskTerminated.connect(partial(self._on_task_terminated))
        QgsApplication.taskManager().addTask(self.thread)

    def _get_file_dialog(self, widget):
        # Get current file path

        tools_qt.get_open_file_path(self.dlg_adc, widget)

    def _get_nodes_from_db(self):
        sql = """
            select node_id, addparam
            from anl_node
            where fid = 491 and cur_user = current_user
            """

        rows = tools_db.get_rows(sql)
        if not rows:
            return {}

        nodes = {}
        for node_id, addparam_str in rows:
            addparam = json.loads(addparam_str)
            demand = addparam["requiredDemand"]
            pressure = addparam["requiredPressure"]

            if node_id in nodes:
                msg = "Node {0} duplicated in config file."
                msg_params = (node_id,)
                raise ValueError(tools_qt.tr(msg, list_params=msg_params))

            nodes[node_id] = {
                "name": node_id,
                "requiredDemand": demand,
                "requiredPressure": pressure,
            }

        return nodes

    def _load_user_values(self):
        self._user_values("load")

    def _on_task_completed(self):
        self._on_task_end()
        message = self.thread.cur_step + "\n\nTask completed!"
        tools_gw.fill_tab_log(
            self.dlg_adc,
            {"info": {"values": [{"message": message}]}},
            close=False,
            call_set_tabs_enabled=False,
        )

    def _on_task_end(self):
        dlg = self.dlg_adc
        dlg.btn_cancel.clicked.disconnect()
        dlg.btn_cancel.clicked.connect(dlg.reject)
        dlg.btn_ok.setEnabled(True)
        self.timer.stop()
        dlg.progress_bar.setValue(100)

    def _on_task_terminated(self):
        self._on_task_end()
        message = self.thread.cur_step + "\n\nTask terminated (canceled or failed)."
        tools_gw.fill_tab_log(
            self.dlg_adc,
            {"info": {"values": [{"message": message}]}},
            close=False,
            call_set_tabs_enabled=False,
        )

    def _on_timer_timeout(self):
        dlg = self.dlg_adc
        t = self.thread

        # Update timer
        elapsed_time = time() - self.t0
        text = str(datetime.timedelta(seconds=round(elapsed_time)))
        dlg.lbl_timer.setText(text)

        # Update log
        tools_gw.fill_tab_log(
            dlg,
            {"info": {"values": [{"message": t.cur_step}]}},
            close=False,
            call_set_tabs_enabled=False,
        )

        # Update progress bar
        dlg.progress_bar.setValue(
            math.floor(t.executed_simulations / t.total_simulations * 100)
        )

    def _ovewrite_existing_files(self, folder, file_name):
        prefix = f"{folder}/{file_name}"
        in_file = prefix + ".in"
        in_exists = Path(in_file).exists()
        csv_file = prefix + ".csv"
        csv_exists = Path(csv_file).exists()

        if in_exists and csv_exists:
            msg = 'The files "{0}.in" and "{1}.csv" already exist. Do you want to overwrite them?'
            msg_params = (file_name, file_name,)
            return tools_qt.show_question(msg, msg_params=msg_params)
        elif in_exists:
            msg = 'The file "{0}.in" already exists. Do you want to overwrite it?'
            msg_params = (file_name, file_name,)
            return tools_qt.show_question(msg, msg_params=msg_params)
        elif csv_exists:
            msg = 'The file "{0}.csv" already exists. Do you want to overwrite it?'
            msg_params = (file_name,)
            return tools_qt.show_question(msg, msg_params=msg_params)

        return True

    def _save_user_values(self):
        self._user_values("save")

    def _set_signals(self):
        dlg = self.dlg_adc
        dlg.btn_ok.clicked.connect(self._execute_process)
        dlg.btn_cancel.clicked.connect(dlg.reject)

        # Files and folders signals
        dlg.btn_push_inp_input_file.clicked.connect(
            partial(self._get_file_dialog, dlg.data_inp_input_file)
        )
        dlg.btn_push_config_file.clicked.connect(
            partial(self._get_file_dialog, dlg.data_config_file)
        )
        dlg.btn_push_output_folder.clicked.connect(
            partial(tools_qt.get_folder_path, dlg, dlg.data_output_folder)
        )

    def _user_values(self, action):
        txt_widgets = [
            "data_inp_input_file",
            "data_config_file",
            "data_output_folder",
            "txt_filename",
        ]
        checkable_widgets = [
            "rdb_nodes_config",
            "rdb_nodes_database",
        ]

        for widget in txt_widgets:
            if action == "load":
                value = tools_gw.get_config_parser(
                    "epatools_add_demand_check",
                    widget,
                    "user",
                    "session",
                )
                tools_qt.set_widget_text(self.dlg_adc, widget, value)
            elif action == "save":
                value = tools_qt.get_text(self.dlg_adc, widget, False, False)
                value = value.replace("%", "%%")
                tools_gw.set_config_parser(
                    "epatools_add_demand_check",
                    widget,
                    value,
                )

        for widget_name in checkable_widgets:
            widget = self.dlg_adc.findChild(QWidget, widget_name)
            if action == "load":
                value = tools_gw.get_config_parser(
                    "epatools_add_demand_check",
                    widget_name,
                    "user",
                    "session",
                )
                widget.setChecked(value == "True")
            elif action == "save":
                value = widget.isChecked()
                tools_gw.set_config_parser(
                    "epatools_add_demand_check",
                    widget_name,
                    f"{value}",
                )

    def _validate_inputs(self):
        dlg = self.dlg_adc

        input_file = dlg.data_inp_input_file.toPlainText()
        if not input_file or not Path(input_file).exists():
            msg = "You should select an input INP file!"
            tools_qt.show_info_box(msg)
            return False

        config_file = dlg.data_config_file.toPlainText()
        if not config_file or not Path(config_file).exists():
            msg = "You should select an config file!"
            tools_qt.show_info_box(msg)
            return False

        try:
            config = ConfigADC(config_file)
        except Exception as e:
            msg = "Configuration file couldn't be imported:\n{0}"
            msg_params = (str(e),)
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return False

        if dlg.rdb_nodes_config.isChecked():
            if len(config.junctions) == 0:
                msg = "The [JUNCTIONS] section of the configuration file is empty."
                tools_qt.show_info_box(msg)
                return False
        else:
            config.junctions = self._get_nodes_from_db()
            if len(config.junctions) == 0:
                msg = "There is no data in table anl_arc for fid=491 and current user."
                tools_qt.show_info_box(msg)
                return False

        output_folder = dlg.data_output_folder.toPlainText()
        if not output_folder:
            msg = "You should select an output folder!"
            tools_qt.show_info_box(msg)
            return False
        elif not Path(output_folder).exists():
            msg = '"{0}" does not exist. Please select a valid folder.'
            msg_params = (output_folder,)
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return False

        file_name = dlg.txt_filename.text()
        if not file_name:
            msg = "You should inform a file name!"
            tools_qt.show_info_box(msg)
            return False

        self.input_file = input_file
        self.config = config
        self.output_folder = output_folder
        self.file_name = file_name
        return True


class ConfigADC:
    def __init__(self, config_file):
        self.options = {}
        self.junctions = {}
        self._parse_file(config_file)

        required_options: list[str] = ["max_distance"]
        for option in required_options:
            if option not in self.options:
                msg = "{0} not found in [OPTIONS] section."
                msg_params = (option,)
                raise ValueError(tools_qt.tr(msg, list_params=msg_params))

    def _parse_file(self, config_file):
        with open(config_file) as file:
            section = ""
            for line in file:
                tokens = self._strip_comments(line).split()
                if len(tokens) == 0:
                    continue
                elif len(tokens) == 1 and tokens[0].lower() == "[options]":
                    section = "options"
                elif len(tokens) == 1 and tokens[0].lower() == "[junctions]":
                    section = "junctions"
                elif section == "options":
                    self._process_option(tokens)
                elif section == "junctions":
                    self._process_junction(tokens)

    def _process_option(self, tokens):
        if tokens[0].lower() == "max_distance":
            self.options["max_distance"] = float(tokens[1])

    def _process_junction(self, tokens):
        node = tokens[0]

        if len(tokens) != 3:
            msg = "Wrong number of parameters for node {0} in config file."
            msg_params = (node,)
            raise ValueError(tools_qt.tr(msg, list_params=msg_params))

        demand = float(tokens[1])
        pressure = float(tokens[2])

        if node in self.junctions:
            msg = "Node {0} duplicated in config file."
            msg_params = (node,)
            raise ValueError(tools_qt.tr(msg, list_params=msg_params))

        self.junctions[node] = {
            "name": node,
            "requiredDemand": demand,
            "requiredPressure": pressure,
        }

    def _strip_comments(self, line):
        index = line.find(";")
        return line if index == -1 else line[:index]
