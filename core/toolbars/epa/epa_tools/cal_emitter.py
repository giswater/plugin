"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import os
from time import time
from datetime import timedelta
from pathlib import Path
from qgis.PyQt.sip import isdeleted

from functools import partial

from qgis.PyQt.QtWidgets import QTabWidget, QLabel
from qgis.PyQt.QtCore import QTimer
from qgis.core import QgsApplication

from ....ui.ui_manager import EmitterCalibrationUi


from ....threads.emitter_calibration_execute import EmitterCalibrationExecute

from .....libs import tools_db, tools_os, tools_qgis, tools_qt
from ....utils import tools_gw


class EmitterCalibration:
    def __init__(self):

        self.network = None
        self.results = None
        self.method = "linear"
        self.delete_extra_points = False
        self.timer = None

    def clicked_event(self):

        # Initial dialog
        self.dlg_vol_cal = EmitterCalibrationUi(self)
        dlg = self.dlg_vol_cal
        tools_gw.load_settings(self.dlg_vol_cal)

        # Disable tab log
        qtabwidget = self.dlg_vol_cal.findChild(QTabWidget, "mainTab")
        if qtabwidget is not None:
            qtabwidget.setTabEnabled(qtabwidget.count() - 1, False)

        # Listeners
        self.dlg_vol_cal.btn_push_inp_input_file.clicked.connect(
            partial(self._select_file_inp)
        )
        self.dlg_vol_cal.btn_push_output_folder.clicked.connect(
            partial(tools_qt.get_folder_path, dlg, dlg.data_output_folder)
        )
        self.dlg_vol_cal.btn_push_config_file.clicked.connect(
            partial(self._select_config_file)
        )
        self.dlg_vol_cal.btn_accept.clicked.connect(partial(self._execute_process))
        self.dlg_vol_cal.btn_close.clicked.connect(
            partial(tools_gw.close_dialog, self.dlg_vol_cal)
        )
        self.dlg_vol_cal.rejected.connect(
            partial(tools_gw.close_dialog, self.dlg_vol_cal)
        )

        # Load values
        self._load_values()

        # Open dialog
        tools_gw.open_dialog(self.dlg_vol_cal, dlg_name='epatools_emitter_calibration')

    def _execute_process(self):

        try:
            tools_os.get_dep("wntr")
        except ImportError:
            tools_qgis.show_critical(
                "Python package 'wntr' is not installed. "
                "Please install it using pip or the 'qpip' QGIS plugin."
            )
            return

        self._get_form_values()

        if not self._check_inputs():
            return

        if not self._ovewrite_existing_files(self.output_folder, self.file_name):
            return

        self._save_values()

        # Step 1: generate config object
        self.config = ConfigEC(self.config_file, self.input_file)

        self._adjust_patterns()

        # Step 2: Run EPANET iterations to find emitter coefficient

        # Create timer
        self.t0 = time()
        if self.timer:
            self.timer.stop()
            del self.timer
        self.timer = QTimer()
        self.timer.timeout.connect(
            partial(self._calculate_elapsed_time, self.dlg_vol_cal)
        )
        self.timer.start(1000)
        self.vol_cal_task = EmitterCalibrationExecute(
            "Iterations execute",
            self.network,
            self.results,
            self.config,
            self.output_folder,
            self.file_name,
            self.timer,
        )
        QgsApplication.taskManager().addTask(self.vol_cal_task)
        QgsApplication.taskManager().triggerTask(self.vol_cal_task)
        self.vol_cal_task.task_finished.connect(partial(self._fill_tab_log))

    def _get_form_values(self):

        self.input_file = tools_qt.get_text(
            self.dlg_vol_cal, self.dlg_vol_cal.data_inp_input_file
        )
        self.output_folder = tools_qt.get_text(
            self.dlg_vol_cal, self.dlg_vol_cal.data_output_folder
        )
        self.file_name = tools_qt.get_text(
            self.dlg_vol_cal, self.dlg_vol_cal.txt_filename
        )

        self.config_file = tools_qt.get_text(
            self.dlg_vol_cal, self.dlg_vol_cal.data_config_file
        )

    def _check_inputs(self):
        from wntr.network import WaterNetworkModel
        from wntr.sim import EpanetSimulator

        valid = True
        # INPUT FILE
        if not os.path.exists(self.input_file):
            print("Input file doesn't exist")
            tools_qt.set_stylesheet(self.dlg_vol_cal.data_inp_input_file)
            valid = False
        else:
            tools_qt.set_stylesheet(self.dlg_vol_cal.data_inp_input_file, style="")
            # Create & run network
            self.network = WaterNetworkModel(self.input_file)

            self.sim = EpanetSimulator(self.network)
            self.results = self.sim.run_sim()

        # OUTPUT FILE
        if not self.output_folder:
            print("Output folder doesn't exist")
            tools_qt.set_stylesheet(self.dlg_vol_cal.data_output_folder)
            valid = False
        if not self.file_name:
            print("Output folder doesn't exist")
            tools_qt.set_stylesheet(self.dlg_vol_cal.txt_filename)
            valid = False

        # CONFIG FILE
        if not os.path.exists(self.config_file):
            print("Configuration file doesn't exist")
            tools_qt.set_stylesheet(self.dlg_vol_cal.data_config_file)
            valid = False

        return valid

    def _ovewrite_existing_files(self, folder, file_name):
        prefix = f"{folder}/{file_name}"

        def exists(sufix):
            return Path(prefix + sufix).exists()
        sufixes = [".inp"]
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

    def _adjust_patterns(self):
        from wntr.sim import EpanetSimulator

        # Get patterns in use for this config
        dmas = {junction["dma_id"] for junction in self.config.junctions.values()}
        patterns = {
            dma["pattern_id"]: {
                "name": dma["pattern_id"],
                "dma": dma["dma_id"],
                "efficiency": float(dma["efficiency"]),
                "pattern": [],
            }
            for dma in self.config.dmas.values()
            if dma["dma_id"] in dmas
        }

        if all(pattern in self.network.pattern_name_list for pattern in patterns):
            # Get pattern values from .inp file
            for p_name, p in patterns.items():
                p["pattern"] = self.network.get_pattern(p_name).multipliers.tolist()
        else:
            # Get pattern values from DB
            for row in tools_db.get_rows(
                f"""
                SELECT *
                FROM inp_pattern_value
                WHERE pattern_id in ('{"','".join(patterns)}')
                ORDER BY id
                """
            ):
                pattern_name = row["pattern_id"]
                factors = patterns[pattern_name]["pattern"]
                for i, factor in enumerate(row):
                    if i in (0, 1):
                        continue
                    if factor is not None:
                        factors.append(factor)

        # Apply adjust to patterns
        for p in patterns.values():
            avg = float(sum(p["pattern"]) / len(p["pattern"]))
            eff = p["efficiency"]
            loss = 1 - eff
            p["adjusted_pattern"] = [
                (float(factor) - avg * loss) / eff for factor in p["pattern"]
            ]

        # Add patterns to network junctions
        patterns_by_dma = {x["dma"]: x["name"] for x in patterns.values()}
        for p in patterns.values():
            if p["name"] in self.network.pattern_name_list:
                pattern = self.network.get_pattern(p["name"])
                pattern.multipliers = p["adjusted_pattern"]
            else:
                self.network.add_pattern(p["name"], pattern=p["adjusted_pattern"])

        for j_name, j in self.network.junctions():
            if j_name not in self.config.junctions:
                continue
            j_dma = self.config.junctions[j_name]["dma_id"]
            if j_dma not in patterns_by_dma:
                continue
            for demand in j.demand_timeseries_list:
                demand.pattern_name = patterns_by_dma[j_dma]

        # Update results
        self.sim = EpanetSimulator(self.network)
        self.results = self.sim.run_sim()

    def _fill_tab_log(self, signal):

        if signal[1]:
            qtabwidget = self.dlg_vol_cal.findChild(QTabWidget, "mainTab")
            if qtabwidget is not None:
                qtabwidget.setTabEnabled(qtabwidget.count() - 1, True)
                if qtabwidget is not None:
                    qtabwidget.setCurrentIndex(qtabwidget.count() - 1)
            tools_qt.set_widget_text(self.dlg_vol_cal, "tab_log_txt_infolog", signal[1] + "\n")

    def _select_file_inp(self):
        """Select INP file"""

        tools_qt.get_open_file_path(self.dlg_vol_cal, "data_inp_input_file", "*.inp", "Select INP file")

    def _select_config_file(self):
        """Select config file"""

        tools_qt.get_open_file_path(self.dlg_vol_cal, "data_config_file", "*.in", "Select .in file")

    def _save_values(self):
        tools_gw.set_config_parser(
            "epatools_emitter_calibration",
            "input_file",
            self.input_file,
            "user",
            "session",
        )
        tools_gw.set_config_parser(
            "epatools_emitter_calibration",
            "output_folder",
            self.output_folder,
            "user",
            "session",
        )
        tools_gw.set_config_parser(
            "epatools_emitter_calibration",
            "file_name",
            self.file_name,
            "user",
            "session",
        )

        tools_gw.set_config_parser(
            "epatools_emitter_calibration",
            "config_file",
            self.config_file,
            "user",
            "session",
        )

    def _load_values(self):

        # INPUT FILE
        input_file = tools_gw.get_config_parser(
            "epatools_emitter_calibration",
            "input_file",
            "user",
            "session",
        )
        if input_file is not None:
            tools_qt.set_widget_text(
                self.dlg_vol_cal, "data_inp_input_file", input_file
            )

        # OUTPUT FILE
        output_folder = tools_gw.get_config_parser(
            "epatools_emitter_calibration",
            "output_folder",
            "user",
            "session",
        )
        if output_folder is not None:
            tools_qt.set_widget_text(
                self.dlg_vol_cal, "data_output_folder", output_folder
            )
        # OUTPUT FILE
        file_name = tools_gw.get_config_parser(
            "epatools_emitter_calibration",
            "file_name",
            "user",
            "session",
        )
        if file_name is not None:
            tools_qt.set_widget_text(self.dlg_vol_cal, "txt_filename", file_name)

        # CONFIG FILE
        config_file = tools_gw.get_config_parser(
            "epatools_emitter_calibration",
            "config_file",
            "user",
            "session",
        )
        if config_file is not None:
            tools_qt.set_widget_text(self.dlg_vol_cal, "data_config_file", config_file)

    def _calculate_elapsed_time(self, dialog):

        tf = time()  # Final time
        td = tf - self.t0  # Delta time
        self._update_time_elapsed(
            f"Exec. time: {timedelta(seconds=round(td))} for Dma: {self.vol_cal_task.current_dma} on Step: {self.vol_cal_task.current_trial}",
            dialog,
        )

    def _update_time_elapsed(self, text, dialog):

        if isdeleted(dialog):
            self.timer.stop()
            return

        lbl_time = dialog.findChild(QLabel, "lbl_time")
        lbl_time.setText(text)


class ConfigEC:
    def __init__(self, config_file, inpfile):
        self.options = {}
        self.dmas = {}
        self.junctions = {}
        self.emitters = {}
        self._parse_file(config_file)

        required_options = [
            "default_efficiency",
            "default_emitter",
            "accuracy",
            "trials",
        ]
        for option in required_options:
            if option not in self.options:
                msg = "{0} not found in [OPTIONS] section."
                msg_params = (option,)
                raise ValueError(tools_qt.tr(msg, list_params=msg_params))

        self._get_junctions_dmas(inpfile)
        self._get_emitters_coefficients(inpfile)

    def _get_emitters_coefficients(self, inpfile):
        from wntr.network import WaterNetworkModel
        wn = WaterNetworkModel(inpfile)
        len_by_node = {}

        for _, pipe in wn.pipes():
            if pipe.start_node_name not in len_by_node:
                len_by_node[pipe.start_node_name] = 0
            if pipe.end_node_name not in len_by_node:
                len_by_node[pipe.end_node_name] = 0

            len_by_node[pipe.start_node_name] += pipe.length
            len_by_node[pipe.end_node_name] += pipe.length

        for node_id, length in len_by_node.items():
            self.emitters[node_id] = {"coefficient": length / 10000, "node_id": node_id}

    def _get_junctions_dmas(self, inpfile):
        with open(inpfile) as file:
            section = None
            for line in file:
                if line[0] == ";":
                    continue

                tokens = line.split()
                if len(tokens) == 0:
                    continue
                elif len(tokens) == 1 and tokens[0].lower() == "[junctions]":
                    section = "junctions"
                elif section != "junctions":
                    continue
                elif len(tokens) == 1 and tokens[0][0] == "[":
                    section = tokens[0][1:-1]
                else:
                    node_id = tokens[0]
                    dma_index = None
                    for i, token in enumerate(tokens):
                        if token[0] == ";":
                            dma_index = i + 1
                            break
                    if dma_index is not None:
                        dma_id = tokens[dma_index]
                        self.junctions[node_id] = {"dma_id": dma_id, "node_id": node_id}

    def _parse_file(self, config_file):
        with open(config_file) as file:
            section = ""
            for line in file:
                tokens = self._strip_comments(line).split()
                if len(tokens) == 0:
                    continue
                elif len(tokens) == 1 and tokens[0][0] == "[":
                    section = tokens[0][1:-1].lower()
                elif section == "options":
                    self._process_option(tokens)
                elif section == "dmas":
                    self._process_dma(tokens)

    def _process_option(self, tokens):
        option = tokens[0].lower()
        if option in ["trials"]:
            self.options[option] = int(tokens[1])
        elif option in ["default_efficiency", "default_emitter", "accuracy"]:
            self.options[option] = float(tokens[1])

    def _process_dma(self, tokens):
        dma_id, efficiency, pattern_id = tokens

        self.dmas[dma_id] = {
            "dma_id": dma_id,
            "efficiency": float(efficiency),
            "pattern_id": pattern_id,
        }

    def _strip_comments(self, str):
        index = str.find(";")
        return str if index == -1 else str[:index]
