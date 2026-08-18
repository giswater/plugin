"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
import os
from datetime import timedelta
from functools import partial
from time import time

from qgis.core import QgsApplication
from qgis.PyQt.QtCore import QTimer

from ....threads.static_calibration import GwStaticCalibration
from ....ui.ui_manager import StaticCalibrationUi
from .....libs import tools_qt, tools_db
from ....utils import tools_gw


class StaticCalibration:
    def __init__(self):
        pass

    def clicked_event(self):
        self.dlg_epa = StaticCalibrationUi(self)
        dlg = self.dlg_epa
        tools_gw.load_settings(dlg)

        sql = "select name, dscenario_id from ve_cat_dscenario where active is true"
        if tools_db.dao.conn.closed:
            tools_db.dao.init_db()
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(dlg.cmb_dscenario, rows)

        self._load_user_values()

        self._set_signals()

        tools_gw.disable_tab_log(dlg)

        tools_gw.open_dialog(dlg, dlg_name="static_calibration")

    def _ovewrite_existing_files(self, folder, file_name):
        prefix = f"{folder}/{file_name}"
        inp_file = prefix + ".inp"
        inp_exists = os.path.exists(inp_file)
        csv_file = prefix + ".csv"
        csv_exists = os.path.exists(csv_file)
        
        if inp_exists and csv_exists:
            msg = 'The files "{0}.inp" and "{1}.csv" already exist. Do you want to overwrite them?'
            msg_params = (file_name, file_name,)
            return tools_qt.show_question(msg, msg_params=msg_params)
        elif inp_exists:
            msg = 'The file "{0}.inp" already exists. Do you want to overwrite it?'
            msg_params = (file_name, file_name,)
            return tools_qt.show_question(msg, msg_params=msg_params)
        elif csv_exists:
            msg = 'The file "{0}.csv" already exists. Do you want to overwrite it?'
            msg_params = (file_name,)
            return tools_qt.show_question(msg, msg_params=msg_params)

        return True

    def _execute_process(self):
        inputs = self._validate_inputs()
        if not inputs:
            return
        input_file, config, output_folder, file_name = inputs

        if not self._ovewrite_existing_files(output_folder, file_name):
            return

        dlg = self.dlg_epa
        tools_gw.disable_tab_log(dlg)
        dlg.tab_log_txt_infolog.setText("")
        dlg.progress_bar.show()

        title = "Static Calibration"
        self.thread = GwStaticCalibration(
            tools_qt.tr(title),
            input_file,
            config,
            output_folder,
            file_name,
        )
        t = self.thread
        t.status.connect(self._log_status)
        t.ended.connect(tools_qt.show_info_box)
        t.report.connect(self._log_report)

        # Set timer
        self.t0 = time()
        self.timer = QTimer()
        self.timer.timeout.connect(partial(self._update_timer, dlg.lbl_timer))
        self.timer.start(250)
        t.ended.connect(self.timer.stop)

        dlg.btn_save_dscenario.setEnabled(False)

        # Button OK behavior
        dlg.btn_ok.setEnabled(False)
        t.taskTerminated.connect(partial(dlg.btn_ok.setEnabled, True))
        t.ended.connect(
            partial(dlg.mainTab.currentChanged.connect, self._set_ok_disabled)
        )
        dlg.mainTab.currentChanged.disconnect()

        # Button Cancel behavior
        dlg.btn_cancel.clicked.disconnect()
        dlg.btn_cancel.clicked.connect(t.cancel)
        title = "Canceling task..."
        dlg.btn_cancel.clicked.connect(
            partial(self._log_status, {"message": tools_qt.tr(title)})
        )
        t.ended.connect(partial(dlg.btn_cancel.clicked.connect, dlg.reject))
        t.ended.connect(lambda txt: self._log_status({"message": txt}))

        QgsApplication.taskManager().addTask(self.thread)

    def _log_report(self, report_obj):
        self.report = report_obj
        txt = ""
        for section, items in report_obj.items():
            if items:
                txt += f"[{section}]\n"
                columns = [[key] for key in items[0].keys()]
                for item in items:
                    for index, value in enumerate(item.values()):
                        columns[index].append(str(value))
                for column in columns:
                    length = len(max(column, key=len))
                    for index, string in enumerate(column):
                        column[index] = string.ljust(length)
                for line in zip(*columns):
                    txt += " ".join(line)
                    txt += "\n"
                txt += "\n"

        dlg = self.dlg_epa
        dlg.tab_log_txt_infolog.setText(txt)
        dlg.progress_bar.hide()
        index = dlg.mainTab.indexOf(dlg.tab_infolog)
        dlg.mainTab.setTabEnabled(index, True)
        dlg.mainTab.setCurrentIndex(index)

        dlg.btn_save_dscenario.setEnabled(True)

    def _log_status(self, status):
        dlg = self.dlg_epa
        tools_gw.fill_tab_log(
            dlg,
            {"info": {"values": [status]}},
            reset_text=False,
            close=False,
            call_set_tabs_enabled=False,
        )

        if "step" in status:
            if status["step"] == "first":
                dlg.progress_bar.setValue(0)
            elif status["step"] == "last":
                dlg.progress_bar.setValue(95)
            elif "steps" in status:
                dlg.progress_bar.setValue(90 / status["steps"] * status["step"])

    def _get_file_dialog(self, widget):
        """Get file dialog"""

        tools_qt.get_open_file_path(self.dlg_epa, widget, "", "Select file", str(os.path.expanduser("~")))

    def _load_user_values(self):
        self._user_values("load")

    def _save2dscenario(self):
        dscenario_name, dscenario_id = self.dlg_epa.cmb_dscenario.currentData()
        msg = ('Do you want to save changes to dscenario "{0}"?\n'
                "This operation cannot be undone.\n\n"
                "(Please note that any changes made to node elevations cannot be saved to dscenarios.)")
        msg_params = (dscenario_name,)
        if not tools_qt.show_question(msg, msg_params=msg_params):
            return

        sql = ""

        # Saving pipes
        if self.report["pipes"]:
            sql += (
                "insert into inp_dscenario_pipe"
                + "(dscenario_id,arc_id,minorloss,roughness,dint) values "
            )
            for pipe in self.report["pipes"]:
                sql += f"({dscenario_id},{pipe['arc_id']},{pipe['minorloss']},{pipe['roughness']},{pipe['dint']}),"
            sql = (
                sql[:-1]
                + "on conflict(dscenario_id, arc_id) do update set "
                + "minorloss=excluded.minorloss, roughness=excluded.roughness,"
                + "dint=excluded.dint;"
            )

        # Saving pumps
        if self.report["pumps"]:
            sql += "insert into inp_dscenario_pump(dscenario_id,node_id,power,curve_id) values "
            for pump in self.report["pumps"]:
                sql += f"({dscenario_id},{pump['node_id']},{pump['power']},null),"
            sql = (
                sql[:-1]
                + "on conflict(dscenario_id, node_id) do update set "
                + "power=excluded.power, curve_id=excluded.curve_id;"
            )

        # Saving valves
        if self.report["valves"]:
            sql += (
                "insert into inp_dscenario_valve"
                + "(dscenario_id,node_id,valve_type,pressure,flow,coef_loss,status) values "
            )
            for valve in self.report["valves"]:
                pressure = (
                    valve["setting"]
                    if valve["valve_type"] in ("PRV", "PSV", "PBV")
                    else "null"
                )
                flow = valve["setting"] if valve["valve_type"] == "FCV" else "null"
                coef_loss = valve["setting"] if valve["valve_type"] == "TCV" else "null"
                status = str(valve["status"]).upper()
                sql += (
                    f"({dscenario_id},{valve['node_id']},'{valve['valve_type']}',"
                    + f"{pressure},{flow},{coef_loss},'{status}'),"
                )
            sql = (
                sql[:-1]
                + "on conflict(dscenario_id, node_id) do update set "
                + "valve_type=excluded.valve_type, pressure=excluded.pressure, "
                + "flow=excluded.flow, coef_loss=excluded.coef_loss, "
                + "status=excluded.status;"
            )

        # Saving virtualvalves
        if self.report["virtualvalves"]:
            sql += (
                "insert into inp_dscenario_virtualvalve"
                + "(dscenario_id,arc_id,valve_type,pressure,flow,coef_loss,status) values "
            )
            for valve in self.report["virtualvalves"]:
                pressure = (
                    valve["setting"]
                    if valve["valve_type"] in ("PRV", "PSV", "PBV")
                    else "null"
                )
                flow = valve["setting"] if valve["valve_type"] == "FCV" else "null"
                coef_loss = valve["setting"] if valve["valve_type"] == "TCV" else "null"
                status = str(valve["status"]).upper()
                sql += (
                    f"({dscenario_id},{valve['arc_id']},'{valve['valve_type']}',"
                    + f"{pressure},{flow},{coef_loss},'{status}'),"
                )
            sql = (
                sql[:-1]
                + "on conflict(dscenario_id, arc_id) do update set "
                + "valve_type=excluded.valve_type, pressure=excluded.pressure, "
                + "flow=excluded.flow, coef_loss=excluded.coef_loss, "
                + "status=excluded.status;"
            )

        if tools_db.dao.conn.closed:
            tools_db.dao.init_db()
        if tools_db.execute_sql(sql):
            msg = 'Changes applied to "{0}" successfully.'
            msg_params = (dscenario_name,)
            tools_qt.show_info_box(msg, msg_params=msg_params)

    def _save_user_values(self):
        self._user_values("save")

    def _set_ok_disabled(self, tab_index):
        """Set OK button disabled if not in the first tab (0)"""
        self.dlg_epa.btn_ok.setEnabled(not tab_index)

    def _set_signals(self):
        dlg = self.dlg_epa

        # Execution signals
        dlg.btn_ok.clicked.connect(self._execute_process)

        # Closing signals
        dlg.btn_cancel.clicked.connect(dlg.reject)
        dlg.rejected.connect(partial(self._save_user_values))
        dlg.rejected.connect(partial(tools_gw.close_dialog, dlg))

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

        # Save changes to dscenario
        dlg.btn_save_dscenario.clicked.connect(self._save2dscenario)

        # Disable OK button when first tab is not the current
        dlg.mainTab.currentChanged.connect(self._set_ok_disabled)

    def _update_timer(self, widget):
        elapsed_time = time() - self.t0
        text = str(timedelta(seconds=round(elapsed_time)))
        widget.setText(text)

    def _user_values(self, action):
        widgets = [
            "data_inp_input_file",
            "data_config_file",
            "data_output_folder",
            "txt_filename",
            "cmb_dscenario",
        ]
        for widget in widgets:
            if action == "load":
                value = tools_gw.get_config_parser(
                    "static_calibration",
                    widget,
                    "user",
                    "session",
                )
                tools_qt.set_widget_text(self.dlg_epa, widget, value)
            elif action == "save":
                value = tools_qt.get_text(self.dlg_epa, widget, False, False)
                value = value.replace("%", "%%")
                tools_gw.set_config_parser(
                    "static_calibration",
                    widget,
                    value,
                )

    def _validate_inputs(self):
        dlg = self.dlg_epa

        input_file = dlg.data_inp_input_file.toPlainText()
        if not input_file:
            msg = "You should select an input INP file!"
            tools_qt.show_info_box(msg)
            return

        config_file = dlg.data_config_file.toPlainText()
        if not config_file:
            msg = "You should select a config file!"
            tools_qt.show_info_box(msg)
            return
        elif not os.path.exists(config_file):
            msg = '"{0}" does not exist. Please select a valid config file.'
            msg_params = (config_file,)
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return

        try:
            config = ConfigSC(config_file)
        except Exception as e:
            msg = "Configuration file couldn't be imported:\n{0}"
            msg_params = (str(e),)
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return

        output_folder = dlg.data_output_folder.toPlainText()
        if not output_folder:
            msg = "You should select an output folder!"
            tools_qt.show_info_box(msg)
            return
        elif not os.path.exists(output_folder):
            msg = '"{0}" does not exist. Please select a valid folder.'
            msg_params = (output_folder,)
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return

        file_name = dlg.txt_filename.text()
        if not file_name:
            msg = "You should inform a file name!"
            tools_qt.show_info_box(msg)
            return

        return input_file, config, output_folder, file_name


class ConfigSC:
    def __init__(self, config_file):
        self.options = {}
        self.scenarios = {}
        self._parse_file(config_file)

        required_options = ["accuracy", "trials"]
        for option in required_options:
            if option not in self.options:
                msg = "{0} not found in [OPTIONS] section."
                msg_params = (option,)
                raise ValueError(tools_qt.tr(msg, list_params=msg_params))

        required_scenario_options = [
            "target_parameter",
            "target_id",
            "target_val",
            "calibration_mode",
            "features",
        ]
        for scenario in self.scenarios.values():
            for option in required_scenario_options:
                if option not in scenario:
                    msg = "{0} not found in {1} scenario."
                    msg_params = (option, scenario['name'])
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
        if tokens[0].lower() == "accuracy":
            self.options["accuracy"] = float(tokens[1])
        if tokens[0].lower() == "trials":
            self.options["trials"] = int(tokens[1])

    def _process_scenario(self, tokens):
        name, option, *values = tokens
        option = option.lower()

        if name not in self.scenarios:
            self.scenarios[name] = {}
            self.scenarios[name]["name"] = name
            self.scenarios[name]["brackets"] = {}

        str_options = ["target_parameter", "target_id", "calibration_mode"]
        float_options = ["target_val"]
        list_str_options = ["features"]
        brackets_options = [
            "dint_multiplier",
            "minorloss_km",
            "power",
            "roughness",
            "setting",
            "elevation_offset",
        ]

        if option in str_options:
            self.scenarios[name][option] = values[0]
        elif option in float_options:
            self.scenarios[name][option] = float(values[0])
        elif option in list_str_options:
            self.scenarios[name][option] = values
        elif option in brackets_options:
            if len(values) != 2:
                msg = "Option '{0}' in scenario {1} must have 2 values."
                msg_params = (option, name)
                raise ValueError(tools_qt.tr(msg, list_params=msg_params))
            self.scenarios[name]["brackets"][option] = [float(x) for x in values]
        else:
            msg = "Incorrect option ({0}) for scenario {1}."
            msg_params = (option, name)
            raise ValueError(tools_qt.tr(msg, list_params=msg_params))

    def _strip_comments(self, str):
        index = str.find(";")
        return str if index == -1 else str[:index]
