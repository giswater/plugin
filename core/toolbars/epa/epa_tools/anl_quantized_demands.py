"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
import datetime
from functools import partial
from pathlib import Path
from time import time

from qgis.core import QgsApplication
from qgis.PyQt.QtCore import QTimer

from ....threads.quantized_demands import GwQuantizedDemands
from ....ui.ui_manager import QuantizedDemandsUi
from .....libs import tools_qt
from ....utils import tools_gw


class QuantizedDemands:
    def __init__(self):
        self.message = ""

    def clicked_event(self):

        self.dlg_epa = QuantizedDemandsUi(self)
        dlg = self.dlg_epa
        tools_gw.load_settings(self.dlg_epa)

        # Load user values
        widgets = [
            "data_inp_input_file",
            "data_config_file",
            "data_output_folder",
            "txt_filename",
        ]
        for widget in widgets:
            value = tools_gw.get_config_parser(
                "epatools_quantized_demands",
                widget,
                "user",
                "session",
            )
            tools_qt.set_widget_text(self.dlg_epa, widget, value)

        # Set signals
        self.dlg_epa.btn_ok.clicked.connect(self._execute_quantized_demands)
        self.dlg_epa.btn_cancel.clicked.connect(self.dlg_epa.reject)

        self.dlg_epa.btn_push_inp_input_file.clicked.connect(
            partial(self._get_file_dialog, self.dlg_epa.data_inp_input_file)
        )

        dlg.btn_push_config_file.clicked.connect(
            partial(self._get_file_dialog, dlg.data_config_file)
        )
        dlg.btn_push_output_folder.clicked.connect(
            partial(tools_qt.get_folder_path, dlg, dlg.data_output_folder)
        )

        self.dlg_epa.rejected.connect(partial(self._save_user_values, self.dlg_epa))
        self.dlg_epa.rejected.connect(partial(tools_gw.close_dialog, self.dlg_epa))

        tools_gw.disable_tab_log(dlg)
        tools_gw.open_dialog(self.dlg_epa, dlg_name="epatools_quantized_demands")

    def _execute_quantized_demands(self):
        if not self._validate_inputs():
            return
        if not self._ovewrite_existing_files(self.output_folder, self.file_name):
            return

        self.dlg_epa.btn_ok.setEnabled(False)
        self.dlg_epa.btn_cancel.clicked.disconnect()
        title = "Quantized Demands"
        self.quantized_demands = GwQuantizedDemands(
            title,
            self.input_file,
            self.config,
            self.output_folder,
            self.file_name,
        )
        self.dlg_epa.btn_cancel.clicked.connect(self.quantized_demands.cancel)
        self.quantized_demands.status.connect(self._manage_messages)
        self.quantized_demands.ended.connect(self._manage_messages)
        self.quantized_demands.ended.connect(
            partial(self.dlg_epa.btn_ok.setEnabled, True)
        )
        self.quantized_demands.ended.connect(
            partial(self.dlg_epa.btn_cancel.clicked.connect, self.dlg_epa.reject)
        )

        # Timer
        self.t0 = time()
        self.timer = QTimer()
        self.timer.timeout.connect(self._on_timer_timeout)
        self.timer.start(500)
        self.dlg_epa.rejected.connect(self.timer.stop)
        self.quantized_demands.ended.connect(self.timer.stop)

        QgsApplication.taskManager().addTask(self.quantized_demands)

    def _get_file_dialog(self, widget):
        """Get file dialog"""

        tools_qt.get_open_file_path(self.dlg_epa, widget, message="Select file")

    def _manage_messages(self, message):
        self.message += message
        self.message += "\n\n"

        tools_gw.fill_tab_log(
            self.dlg_epa,
            {"info": {"values": [{"message": self.message}]}},
            close=False,
            call_set_tabs_enabled=False,
        )

    def _on_timer_timeout(self):
        elapsed_time = time() - self.t0
        text = str(datetime.timedelta(seconds=round(elapsed_time)))
        self.dlg_epa.lbl_timer.setText(text)

    def _ovewrite_existing_files(self, folder, file_name):
        prefix = f"{folder}/{file_name}"

        def exists(sufix):
            return Path(prefix + sufix).exists()
        sufixes = [".inp", ".csv"]
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

    def _save_user_values(self, dialog):
        """Save last user values"""
        text_widgets = [
            "data_inp_input_file",
            "data_config_file",
            "data_output_folder",
            "txt_filename",
        ]
        for widget in text_widgets:
            value = tools_qt.get_text(dialog, widget, False, False)
            tools_gw.set_config_parser(
                "epatools_quantized_demands",
                widget,
                f"{value}",
            )

    def _validate_inputs(self):
        dlg = self.dlg_epa

        # Input INP file
        input_file = self.dlg_epa.data_inp_input_file.toPlainText()
        if not input_file:
            msg = "You should select an input INP file!"
            tools_qt.show_info_box(msg)
            return False

        # Config file
        config_file = dlg.data_config_file.toPlainText()
        if not config_file or not Path(config_file).exists():
            msg = "You should select an config file!"
            tools_qt.show_info_box(msg)
            return False

        try:
            config = ConfigQD(config_file)
        except Exception as e:
            msg = "Configuration file couldn't be imported:\n{0}"
            msg_params = (str(e),)
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return False

        # Output
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


class ConfigQD:
    def __init__(self, config_file):
        self.options = {}
        self.input_flows = {}
        self._flow_list = []
        self._flow_list_unit = None
        self._flow_list_timestep = None
        self._parse_file(config_file)

        required_options = ["model_timestep"]
        for option in required_options:
            if option not in self.options:
                msg = "{0} not found in [OPTIONS] section."
                msg_params = (option,)
                tools_qt.show_info_box(msg, msg_params=msg_params)
                raise ValueError(tools_qt.tr(msg, list_params=msg_params))

    def _convert2lps(self, value, unit):
        convert_from = {
            "LPS": lambda x: x,
            "LPM": lambda x: x / 60,
            "CMH": lambda x: x * 1000 / 60 / 60,
            "CMD": lambda x: x * 1000 / 24 / 60 / 60,
        }
        return convert_from[unit](value)

    def _convert2seconds(self, value, unit):
        convert_from = {
            "seconds": lambda x: x,
            "minutes": lambda x: x * 60,
            "hours": lambda x: x * 60 * 60,
        }
        return convert_from[unit.lower()](value)

    def _parse_file(self, config_file):
        with open(config_file) as file:
            section = ""
            for line in file:
                tokens = self._strip_comments(line).split()
                if len(tokens) == 0:
                    continue
                elif len(tokens) == 1 and tokens[0].lower() == "[options]":
                    section = "options"
                elif len(tokens) == 1 and tokens[0].lower() == "[inputflows]":
                    section = "input flows"
                elif section == "options":
                    self._process_option(tokens)
                elif section == "input flows":
                    self._process_input_flows(tokens)

        if not self._flow_list:
            msg = "Values for input flows not informed."
            raise ValueError(tools_qt.tr(msg))
        if self._flow_list_unit is None:
            msg = "Unit for values of input flows not informed."
            raise ValueError(tools_qt.tr(msg))
        if self._flow_list_timestep is None:
            msg = "Timestep for input flows not informed."
            raise ValueError(tools_qt.tr(msg))

        self.input_flows["values"] = [
            self._convert2lps(x, self._flow_list_unit) for x in self._flow_list
        ]
        self.input_flows["timestep"] = self._flow_list_timestep

    def _process_leak_flow(self, tokens):
        value = float(tokens[1])
        unit = tokens[2].upper()
        self.options["leak_flow"] = self._convert2lps(value, unit)

    def _process_model_timestep(self, tokens):
        value = int(tokens[1])
        unit = tokens[2].lower()
        self.options["model_timestep"] = self._convert2seconds(value, unit)

    def _process_option(self, tokens):
        first_token = tokens[0].lower()

        options = {
            "leak_flow": self._process_leak_flow,
            "model_timestep": self._process_model_timestep,
            "volume_distribution": self._process_volume_distribution,
        }

        if first_token in options:
            options[first_token](tokens)

    def _process_input_flows(self, tokens):
        first_token = tokens[0].lower()

        if first_token == "values":
            _, *values = tokens
            self._flow_list += list(map(float, values))
        elif first_token == "unit":
            self._flow_list_unit = tokens[1].upper()
        elif first_token == "timestep":
            value = int(tokens[1])
            ts_unit = tokens[2].lower()
            self._flow_list_timestep = self._convert2seconds(value, ts_unit)

    def _process_volume_distribution(self, tokens):
        value = tokens[1].lower()
        if value in ("simple", "hourly"):
            self.options["volume_distribution"] = value
        else:
            msg = "Value_distribution must be SIMPLE or HOURLY."
            raise ValueError(tools_qt.tr(msg))

    def _strip_comments(self, str):
        index = str.find(";")
        return str if index == -1 else str[:index]
