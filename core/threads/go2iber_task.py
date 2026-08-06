"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import os
import importlib
import json

from qgis.PyQt.QtCore import pyqtSignal
from qgis.PyQt.QtWidgets import QTextEdit
from qgis.core import QgsVectorLayer, QgsProject
from qgis.PyQt.QtCore import QDate

from .epa_file_manager import GwEpaFileManager
from ..utils import tools_gw
from ...libs import lib_vars, tools_log, tools_qt, tools_qgis, tools_db
from .task import GwTask
from datetime import datetime


class GwGo2IberTask(GwTask):
    """ This shows how to subclass QgsTask """

    fake_progress = pyqtSignal()
    step_completed = pyqtSignal(dict, str)

    def __init__(self, description, go2iber, timer=None):

        super().__init__(description)
        self.go2iber = go2iber
        self.json_result = None
        self.rpt_result = None
        self.fid = 140
        self.function_name = None
        self.timer = timer
        self.initialize_variables()
        self.set_variables_from_go2iber()
        self.ig_execute_model = importlib.import_module('.execute_model', package=f'{self.ibergis_folder}.core.threads')
        self.ig_feedback_class = importlib.import_module('.feedback', package=f'{self.ibergis_folder}.core.utils')
        self.cur_process = None
        self.cur_text = None
        self.ig_feedback = None

    def initialize_variables(self):

        self.exception = None
        self.error_msg = None
        self.message = None
        self.common_msg = ""
        self.function_failed = False
        self.complet_result = None
        self.replaced_velocities = False

    def set_variables_from_go2iber(self):
        """ Set variables from object Go2Iber """

        self.dlg_go2iber = self.go2iber.dlg_go2iber
        self.result_name = self.go2iber.result_name
        self.folder_path = self.go2iber.folder_path
        self.ibergis_folder = self.go2iber.ibergis_folder

    def run(self):

        super().run()

        msg = "GO2IBER - Work in progress"
        self.step_completed.emit({"message": {"level": 1, "text": tools_qt.tr(msg)}}, "\n")
        self.step_completed.emit({"message": {"level": 1, "text": "--------------------------"}}, "\n")

        self.initialize_variables()
        # TODO:
        # - Generate INP file with Giswater (go2iber)
        self.go2epa_task = GwEpaFileManager("Go2Epa", self.dlg_go2iber, network_mode=2)
        self.go2epa_task.go2epa_export_inp = True
        self.go2epa_task.go2epa_execute_epa = False
        self.go2epa_task.go2epa_import_result = False
        self.go2epa_task.export_subcatch = False
        self.go2epa_task.result_name = self.result_name
        self.go2epa_task.file_inp = self.folder_path + os.sep + "Iber_SWMM.inp"
        self.go2epa_task.file_rpt = self.folder_path + os.sep + "Iber_SWMM.rpt"
        # Create folders path
        os.makedirs(self.folder_path, exist_ok=True)
        self.go2epa_task.main_process()

        pgully_geojson = tools_gw.execute_procedure('gw_fct_pg2iber_pgully', aux_conn=self.aux_conn, is_thread=True)
        geojson_str: str = json.dumps(pgully_geojson['body']['data']['result'])
        if geojson_str:
            pgully_layer: QgsVectorLayer = QgsVectorLayer(geojson_str, 'pgully', 'ogr')
        else:
            pgully_layer = None

        # - Execute model with IBERGIS plugin
        params = {
            "dialog": self.dlg_go2iber,
            "folder_path": self.folder_path,
            "do_generate_inp": False,
            "do_export": True,
            "do_run": True,
            "do_import": True,
            "do_write_inlets": False,
            "pinlet_layer": pgully_layer,
            "iber_tmax": self._get_tmax_from_options(),
            "generate_results_gpkg": False
        }
        self.ig_feedback = self.ig_feedback_class.Feedback()
        self.ig_execute_model = self.ig_execute_model.DrExecuteModel("Execute IberGIS Model", params, self.ig_feedback)
        self.ig_execute_model.progress_changed.connect(self._progress_changed)
        self.ig_feedback.progressChanged.connect(self._progress_changed)
        # Show tab log
        tools_gw.set_tabs_enabled(self.dlg_go2iber)
        self.dlg_go2iber.mainTab.setCurrentIndex(1)
        self.ig_execute_model.run()

        # - Import results to IBERGIS mainly, but rpt to Giswater
        # import rpt to Giswater
        self.go2epa_task.go2epa_export_inp = False
        self.go2epa_task.go2epa_execute_epa = False
        self.go2epa_task.go2epa_import_result = True
        self.go2epa_task.main_process()

        status = True

        return status

    def _progress_changed(self, process, progress, text, new_line):
        # Progress bar
        if progress is not None:
            self.dlg_go2iber.progress_bar.setValue(progress)

        # TextEdit log
        txt_infolog = self.dlg_go2iber.findChild(QTextEdit, 'tab_log_txt_infolog')
        cur_text = tools_qt.get_text(self.dlg_go2iber, txt_infolog, return_string_null=False)
        if process and process != self.cur_process:
            cur_text = f"{cur_text}\n" \
                       f"--------------------\n" \
                       f"{process}\n" \
                       f"--------------------\n\n"
            self.cur_process = process
            self.cur_text = None

        if self.cur_text:
            cur_text = self.cur_text

        end_line = '\n' if new_line else ''
        if text:
            txt_infolog.setText(f"{cur_text}{text}{end_line}")
        else:
            txt_infolog.setText(f"{cur_text}{end_line}")
        txt_infolog.show()
        # Scroll to the bottom
        scrollbar = txt_infolog.verticalScrollBar()
        scrollbar.setValue(scrollbar.maximum())

    def finished(self, result):

        super().finished(result)

        self.dlg_go2iber.btn_cancel.setEnabled(False)
        self.dlg_go2iber.btn_accept.setEnabled(True)

        if not self.isCanceled() and result:
            relative_path = os.path.relpath(self.folder_path, QgsProject.instance().absolutePath())
            tools_qgis.set_project_variable('project_results_folder', relative_path)
            self.ig_execute_model._import_results()
            self.ig_execute_model._delete_raster_results()

        if self.timer:
            self.timer.stop()
        if self.isCanceled():
            return

        if self.function_failed:
            if self.json_result is None or not self.json_result:
                msg = "Function failed finished"
                tools_log.log_warning(msg)
            if self.complet_result:
                if self.complet_result.get('status') == "Failed":
                    tools_gw.manage_json_exception(self.complet_result)
            if self.rpt_result:
                if "Failed" in self.rpt_result.get('status'):
                    tools_gw.manage_json_exception(self.rpt_result)

        if self.error_msg:
            title = "Task aborted - {0}"
            title_params = (self.description(),)
            tools_qt.show_info_box(self.error_msg, title=title, title_params=title_params)
            return

        if self.exception:
            title = "Task aborted - {0}"
            title_params = (self.description(),)
            tools_qt.show_info_box(self.exception, title=title, title_params=title_params)
            raise self.exception

        # If Database exception, show dialog after task has finished
        if lib_vars.session_vars['last_error']:
            tools_qt.show_exception_message(msg=lib_vars.session_vars['last_error_msg'])

    def cancel(self):
        msg = "Task canceled - {0}"
        msg_params = (self.description(),)
        tools_qgis.show_info(msg, msg_params=msg_params)
        self._close_file()
        super().cancel()

    def _get_tmax_from_options(self) -> int:
        """ Update the tmax field based on SWMM options """

        # Get values
        sql = "SELECT value FROM config_param_user WHERE parameter in ('inp_options_start_time', 'inp_options_end_time', 'inp_options_start_date', 'inp_options_end_date') ORDER BY parameter"
        rows = tools_db.get_rows(sql, is_thread=True)
        if rows:
            end_date_str = rows[0]['value']
            end_time_str = rows[1]['value']
            start_date_str = rows[2]['value']
            start_time_str = rows[3]['value']

        # Parse time strings (HH:MM:SS, HH:MM)
        def parse_time(time_str: str) -> tuple[int, int, int]:
            """Parse time string and return (hours, minutes, seconds)"""
            if not time_str or time_str.strip() == "":
                return 0, 0, 0

            time_parts = time_str.strip().split(':')
            if len(time_parts) == 2:
                # Format: HH:MM
                hours = int(time_parts[0])
                minutes = int(time_parts[1])
                seconds = 0
            elif len(time_parts) == 3:
                # Format: HH:MM:SS
                hours = int(time_parts[0])
                minutes = int(time_parts[1])
                seconds = int(time_parts[2])
            else:
                return 0, 0, 0

            return hours, minutes, seconds

        # Parse dates and times
        if start_date_str and end_date_str:
            # Parse date strings (dd/MM/yyyy) into QDate objects
            start_date_obj = QDate.fromString(start_date_str, 'dd/MM/yyyy')
            end_date_obj = QDate.fromString(end_date_str, 'dd/MM/yyyy')

            if start_date_obj.isValid() and end_date_obj.isValid():
                start_h, start_m, start_s = parse_time(start_time_str)
                end_h, end_m, end_s = parse_time(end_time_str)

                # Create datetime objects
                start_datetime = datetime.combine(start_date_obj.toPyDate(), datetime.min.time().replace(
                    hour=start_h, minute=start_m, second=start_s
                ))
                end_datetime = datetime.combine(end_date_obj.toPyDate(), datetime.min.time().replace(
                    hour=end_h, minute=end_m, second=end_s
                ))

                # Calculate time difference
                time_diff = end_datetime - start_datetime
                seconds = int(time_diff.total_seconds())

                return seconds

        return 0
