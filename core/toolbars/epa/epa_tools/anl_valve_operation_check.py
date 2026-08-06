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

from ....threads.valve_operation_check import GwValveOperationCheck
from ....ui.ui_manager import ValveOperationCheckUi
from .....libs import tools_db, tools_os, tools_qgis, tools_qt
from ....utils import tools_gw


class ValveOperationCheck:
    def __init__(self):
        pass

    def clicked_event(self):
        # TODO: Add a link to example file in wiki
        self.dlg_voc = ValveOperationCheckUi(self)
        dlg = self.dlg_voc
        tools_gw.load_settings(dlg)
        self._load_user_values()

        self._set_signals()

        tools_gw.disable_tab_log(dlg)
        tools_gw.open_dialog(dlg, dlg_name="valve_operation_check")

    def _execute_process(self):
        try:
            tools_os.get_dep("wntr")
        except ImportError:
            msg = "Python package 'wntr' is not installed. Please install it using pip or the 'qpip' QGIS plugin."
            tools_qgis.show_critical(msg)
            return

        dlg = self.dlg_voc

        if not self._validate_inputs():
            return
        if not self._ovewrite_existing_files(self.output_folder, self.file_name):
            return
        self._save_user_values()
        title = "Valve Operation Check"
        self.thread = GwValveOperationCheck(
            title,
            self.network,
            self.config,
            self.output_folder,
            self.file_name,
        )

        # Timer
        self.t0 = time()
        self.timer = QTimer()
        self.timer.timeout.connect(self._on_timer_timeout)
        self.timer.start(500)
        dlg.rejected.connect(self.timer.stop)

        # Button Cancel behavior
        dlg.btn_cancel.clicked.disconnect()
        dlg.btn_cancel.clicked.connect(self.thread.cancel)

        self.thread.taskCompleted.connect(partial(self._on_task_end))
        self.thread.taskTerminated.connect(partial(self._on_task_end))
        QgsApplication.taskManager().addTask(self.thread)

    def _get_file_dialog(self, widget):
        """ Check if selected file exists. Set default value if necessary """

        tools_qt.get_open_file_path(self.dlg_voc, widget, "", "Selected file", str(Path.home()))

    def _get_scenarios_from_db(self):
        sql = """
            select arc_id, addparam
            from anl_arc
            where fid = 493 and cur_user = current_user
            """
        rows = tools_db.get_rows(sql)
        if rows is None:
            return {}

        scenarios = {}
        for arc_id, addparam_str in rows:
            addparam = json.loads(addparam_str)
            name = addparam["scenario"]
            status = addparam["valve_status"]

            if name == "base":
                msg = "A scenario cannot be named 'base'."
                raise ValueError(tools_qt.tr(msg))

            if name not in scenarios:
                scenarios[name] = {}
                scenarios[name]["name"] = name
                scenarios[name]["open"] = []
                scenarios[name]["closed"] = []

            if status.lower() == "open":
                scenarios[name]["open"].append(arc_id)
            elif status.lower() == "closed":
                scenarios[name]["closed"].append(arc_id)
            else:
                msg = "Incorrect valve status ({0}) for arc {1}."
                msg_params = (status, arc_id)
                raise ValueError(tools_qt.tr(msg, list_params=msg_params))

        return scenarios

    def _load_user_values(self):
        self._user_values("load")

    def _on_task_end(self):
        dlg = self.dlg_voc
        dlg.btn_cancel.clicked.disconnect()
        dlg.btn_cancel.clicked.connect(dlg.reject)
        # dlg.btn_ok.setEnabled(True)
        self.timer.stop()
        self._on_timer_timeout()
        dlg.progress_bar.setValue(100)

    def _on_timer_timeout(self):
        dlg = self.dlg_voc

        # Update timer
        elapsed_time = time() - self.t0
        text = str(datetime.timedelta(seconds=round(elapsed_time)))
        dlg.lbl_timer.setText(text)

        # Update log
        message = self.thread.log
        if self.thread.isCanceled() and self.thread.isActive():
            message += "\nCanceling task..."
        tools_gw.fill_tab_log(
            dlg,
            {"info": {"values": [{"message": message}]}},
            close=False,
            call_set_tabs_enabled=False,
        )
        dlg.tab_log_txt_infolog.verticalScrollBar().setValue(
            dlg.tab_log_txt_infolog.verticalScrollBar().maximum()
        )

        # Update progress bar
        dlg.progress_bar.setValue(
            math.floor(self.thread.cur_scenario / self.thread.total_scenarios * 100)
        )

    def _ovewrite_existing_files(self, folder, file_name):
        prefix = f"{folder}/{file_name}"

        def exists(sufix):
            return Path(prefix + sufix).exists()
        sufixes = ["-report.csv", "-nodes.csv", "-arcs.csv", ".in"]
        sufixes_that_exist = list(filter(exists, sufixes))

        if len(sufixes_that_exist) == 1:
            file = f"{file_name}{sufixes_that_exist[0]}"
            msg = "The file {0} already exists. Do you want to overwrite it?"
            msg_params = (file,)
            return tools_qt.show_question(msg, msg_params=msg_params)

        elif len(sufixes_that_exist) > 1:
            file_names = [f'"{file_name}{sufix}"' for sufix in sufixes_that_exist]
            all_files = ", ".join(file_names)
            msg = "The files {0} already exist. Do you want to overwrite them?"
            msg_params = (all_files,)
            return tools_qt.show_question(msg, msg_params=msg_params)

        return True

    def _save_user_values(self):
        self._user_values("save")

    def _set_signals(self):
        dlg = self.dlg_voc
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
            "rdb_scenarios_config",
            "rdb_scenarios_database",
        ]

        for widget in txt_widgets:
            if action == "load":
                value = tools_gw.get_config_parser(
                    "valve_operation_check",
                    widget,
                    "user",
                    "session",
                )
                tools_qt.set_widget_text(self.dlg_voc, widget, value)
            elif action == "save":
                value = tools_qt.get_text(self.dlg_voc, widget, False, False)
                value = value.replace("%", "%%")
                tools_gw.set_config_parser(
                    "valve_operation_check",
                    widget,
                    value,
                )

        for widget_name in checkable_widgets:
            widget = self.dlg_voc.findChild(QWidget, widget_name)
            if action == "load":
                value = tools_gw.get_config_parser(
                    "valve_operation_check",
                    widget_name,
                    "user",
                    "session",
                )
                widget.setChecked(value == "True")
            elif action == "save":
                value = widget.isChecked()
                tools_gw.set_config_parser(
                    "valve_operation_check",
                    widget_name,
                    f"{value}",
                )

    def _validate_inputs(self):
        from wntr.network import WaterNetworkModel

        dlg = self.dlg_voc

        input_file = dlg.data_inp_input_file.toPlainText()
        if not input_file or not Path(input_file).exists():
            msg = "You should select an input INP file!"
            tools_qt.show_info_box(msg)
            return False

        try:
            network = WaterNetworkModel(input_file)
        except Exception as e:
            msg = "INP file couldn't be imported:\n{0}"
            msg_params = (str(e),)
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return False

        config_file = dlg.data_config_file.toPlainText()
        if not config_file or not Path(config_file).exists():
            msg = "You should select an config file!"
            tools_qt.show_info_box(msg)
            return False

        try:
            config = ConfigVOC(config_file)
        except Exception as e:
            msg = "Configuration file couldn't be imported:\n{0}"
            msg_params = (str(e),)
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return False

        if self.dlg_voc.rdb_scenarios_config.isChecked():
            if len(config.scenarios) == 0:
                msg = "The [SCENARIOS] section of the configuration file is empty."
                tools_qt.show_info_box(msg)
                return False
        else:
            config.scenarios = self._get_scenarios_from_db()
            if len(config.scenarios) == 0:
                msg = "There is no data in table anl_arc for fid=493 and current user."
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

        self.network = network
        self.config = config
        self.output_folder = output_folder
        self.file_name = file_name
        return True


class ConfigVOC:
    def __init__(self, config_file):
        self.options = {}
        self.scenarios = {}
        self._parse_file(config_file)

        required_options = [
            "base_demand_multiplier",
            "reference_pressure",
            "min_pressure",
            "scenario_results",
        ]
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
                elif len(tokens) == 1 and tokens[0].lower() == "[scenarios]":
                    section = "scenarios"
                elif section == "options":
                    self._process_option(tokens)
                elif section == "scenarios":
                    self._process_scenario(tokens)

    def _process_option(self, tokens):
        if tokens[0].lower() == "base_demand_multiplier":
            self.options["base_demand_multiplier"] = float(tokens[1])
        if tokens[0].lower() == "reference_pressure":
            self.options["reference_pressure"] = float(tokens[1])
        if tokens[0].lower() == "min_pressure":
            self.options["min_pressure"] = float(tokens[1])
        if tokens[0].lower() == "scenario_results":
            if tokens[1].lower() not in ["failed", "none", "all"]:
                message = "Invalid value for scenario_results in [OPTIONS] section."
                raise ValueError(message)
            self.options["scenario_results"] = tokens[1].lower()

    def _process_scenario(self, tokens):
        name, status, *valves = tokens

        if name == "base":
            msg = "A scenario cannot be named 'base'."
            raise ValueError(tools_qt.tr(msg))

        if name not in self.scenarios:
            self.scenarios[name] = {}
            self.scenarios[name]["name"] = name
            self.scenarios[name]["open"] = []
            self.scenarios[name]["closed"] = []

        if status.lower() == "open":
            self.scenarios[name]["open"] += valves
        elif status.lower() == "closed":
            self.scenarios[name]["closed"] += valves
        else:
            msg = "Incorrect valve status ({0}) for scenario {1}."
            msg_params = (status, name)
            raise ValueError(tools_qt.tr(msg, list_params=msg_params))

    def _strip_comments(self, str):
        index = str.find(";")
        return str if index == -1 else str[:index]
