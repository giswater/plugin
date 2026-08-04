"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import os
import re
import subprocess
import psycopg2
import json

from qgis.PyQt.QtCore import pyqtSignal
from qgis.core import QgsProject

from ..utils import tools_gw
from ... import global_vars
from ...libs import lib_vars, tools_log, tools_qt, tools_db, tools_qgis, tools_os
from .task import GwTask


class GwEpaFileManager(GwTask):
    """ This shows how to subclass QgsTask """

    # Relative weights for active phases (scaled to 0-100 at runtime)
    WEIGHT_PG2EPA = 20
    WEIGHT_EXPORT = 5
    WEIGHT_EPA = 55
    WEIGHT_IMPORT = 20

    fake_progress = pyqtSignal()
    step_completed = pyqtSignal(dict, str)

    def __init__(self, description, go2epa, timer=None, network_mode=None):

        super().__init__(description)
        self.go2epa = go2epa
        self.json_result = None
        self.rpt_result = None
        self.fid = 140
        self.function_name = None
        self.timer = timer
        self.network_mode = network_mode
        self.initialize_variables()
        self.set_variables_from_go2epa()
        self.active_epa_layers = False

    def initialize_variables(self):

        self.exception = None
        self.error_msg = None
        self.error_msg_params = None
        self.message = None
        self.common_msg = ""
        self.function_failed = False
        self.complet_result = None
        self.replaced_velocities = False

    def set_variables_from_go2epa(self):
        """ Set variables from object Go2Epa """

        self.dlg_go2epa = getattr(self.go2epa, 'dlg_go2epa', None)
        self.result_name = getattr(self.go2epa, 'result_name', None)
        self.file_inp = getattr(self.go2epa, 'file_inp', None)
        self.file_rpt = getattr(self.go2epa, 'file_rpt', None)
        self.go2epa_export_inp = getattr(self.go2epa, 'export_inp', None)
        self.go2epa_execute_epa = getattr(self.go2epa, 'exec_epa', None)
        self.go2epa_import_result = getattr(self.go2epa, 'import_result', None)
        self.export_subcatch = getattr(self.go2epa, 'export_subcatch', True)

    def run(self):

        super().run()

        self.step_completed.emit({"message": {"level": 1, "text": "GO2EPA - Work in progress"}}, "\n")
        self.step_completed.emit({"message": {"level": 1, "text": "-------------------------"}}, "\n")

        self.initialize_variables()

        status = self.main_process()

        return status

    def main_process(self) -> bool:
        self._init_progress_ranges()

        status = True
        msg = "Task 'Go2Epa' execute function '{0}'"
        if self.go2epa_export_inp or self.go2epa_execute_epa:
            msg_params = ("_exec_function_pg2epa",)
            tools_log.log_info(msg, msg_params=msg_params)
            status = self._exec_function_pg2epa()
            if not status:
                self.function_name = 'gw_fct_pg2epa_main'
                return False

        if self.go2epa_export_inp:
            msg_params = ("_export_inp",)
            tools_log.log_info(msg, msg_params=msg_params)
            status = self._export_inp()

        # Prefer hydraulic_engine for WS (EPANET) and UD (SWMM); fall back to classic EPA
        if status:
            if self.go2epa_execute_epa or self.go2epa_import_result:
                has_hydraulic_engine = self._init_hydraulic_engine()
                runner = None

            if self.go2epa_execute_epa:
                if has_hydraulic_engine:
                    msg_params = ("_execute_epa_with_hydraulic_engine",)
                    tools_log.log_info(msg, msg_params=msg_params)
                    runner = self._execute_epa_with_hydraulic_engine()
                    if runner is None:
                        status = False
                else:
                    msg_params = ("_execute_epa",)
                    tools_log.log_info(msg, msg_params=msg_params)
                    status = self._execute_epa()

            if self.go2epa_import_result:
                message = "Task '{0}' execute function '{1}'"
                msg_params = ('Go2Epa', 'def _import_rpt')
                tools_log.log_info(message, msg_params=msg_params)
                if has_hydraulic_engine and runner is not None:
                    msg_params = ("_import_rpt_with_hydraulic_engine",)
                    tools_log.log_info(msg, msg_params=msg_params)
                    status = self._import_rpt_with_hydraulic_engine(runner)
                else:
                    msg_params = ("_import_rpt",)
                    tools_log.log_info(msg, msg_params=msg_params)
                    self.function_name = 'gw_fct_rpt2pg_main'
                    status = self._import_rpt()

        return status

    def finished(self, result):

        super().finished(result)

        if self.dlg_go2epa is not None:
            self.dlg_go2epa.btn_cancel.setEnabled(False)
            self.dlg_go2epa.btn_accept.setEnabled(True)

        self._close_file()
        if self.timer:
            self.timer.stop()
        if self.isCanceled():
            return

        # If PostgreSQL function returned null
        if (self.go2epa_export_inp or self.go2epa_execute_epa) and self.complet_result is None:
            msg = "Database returned null. Check postgres function '{0}'"
            msg_params = (self.function_name,)
            tools_log.log_warning(msg, msg_params=msg_params)

        elif result:

            # If EPA layers are active, load them and make them visible
            if self.active_epa_layers:
                # Load EPA layers before making them visible
                self._load_epa_layers()

                # Activate EPA layers in TOC
                project = QgsProject.instance()

                # Get EPA group from layer tree
                root = project.layerTreeRoot()
                epa_group = root.findGroup('EPA')

                # Make EPA group and all child layers visible if group exists
                if epa_group:
                    epa_group.setItemVisibilityChecked(True)
                    for layer in epa_group.findLayers():
                        tools_qgis.set_layer_visible(layer.layer())

            msg = "Task 'Go2Epa' execute function '{0}' from '{1}'"
            if self.go2epa_export_inp and self.complet_result:
                if self.complet_result.get('status') == "Accepted":
                    body = self.complet_result.get('body') or {}
                    data = body.get('data') if isinstance(body, dict) else None
                    if data:
                        msg_params = ("add_layer_temp", "tools_gw.py",)
                        tools_log.log_info(msg, msg_params=msg_params)
                        tools_gw.add_layer_temp(self.dlg_go2epa, data,
                                                None, True, True, 1, True, close=False,
                                                call_set_tabs_enabled=False)

            if self.go2epa_import_result and self.rpt_result:
                if self.rpt_result.get('status') == "Accepted":
                    body = self.rpt_result.get('body') or {}
                    data = body.get('data') if isinstance(body, dict) else None
                    if data:
                        msg_params = ("add_layer_temp", "tools_gw.py",)
                        tools_log.log_info(msg, msg_params=msg_params)
                        tools_gw.add_layer_temp(self.dlg_go2epa, data,
                                                None, True, True, 1, True, close=False,
                                                call_set_tabs_enabled=False)
                    if self.message is None:
                        self.message = (self.rpt_result.get('message') or {}).get('text')
            sql = f"SELECT {self.function_name}("
            if self.body:
                sql += f"{self.body}"
            sql += ");"
            msg = "Task '{0}' manage json response"
            msg_params = ('Go2Epa',)
            tools_log.log_info(msg, msg_params=msg_params)
            tools_gw.manage_json_response(self.complet_result, sql, None)

            replace = tools_gw.get_config_parser('btn_go2epa', 'force_import_velocity_higher_50ms', "user", "init",
                                                 prefix=False)
            if tools_os.set_boolean(replace, default=False) and self.replaced_velocities:
                msg = ("There were velocities >50 in the rpt file. You have activated the option to force the import "
                      "so they have been set to 50.")
                tools_qt.show_info_box(msg)

            if self.common_msg != "":
                tools_qgis.show_info(self.common_msg)
            if self.message is not None:
                tools_log.log_info(self.message)
            self.go2epa.check_result_id()
            return

        if self.function_failed:
            if self.json_result is None or not self.json_result:
                msg = "Function failed finished"
                tools_log.log_warning(msg)
            if self.complet_result:
                if self.complet_result.get('status') == "Failed":
                    tools_gw.manage_json_exception(self.complet_result)
            if self.rpt_result:
                status = self.rpt_result.get('status') or ''
                if "Failed" in status:
                    tools_gw.manage_json_exception(self.rpt_result)

        if self.error_msg:
            title = "Task aborted - {0}"
            title_params = (self.description(),)
            tools_qt.show_info_box(self.error_msg, title=title, title_params=title_params, msg_params=self.error_msg_params)
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

    # region private functions

    def _close_file(self, file=None):

        if file is None:
            file = self.file_rpt

        try:
            if file:
                file.close()
                del file
        except Exception:
            pass

    def _init_progress_ranges(self):
        """Build 0-100 ranges from active phases, keeping relative weights."""
        phases = []
        if self.go2epa_export_inp or self.go2epa_execute_epa:
            phases.append(('pg2epa', self.WEIGHT_PG2EPA))
        if self.go2epa_export_inp:
            phases.append(('export', self.WEIGHT_EXPORT))
        if self.go2epa_execute_epa:
            phases.append(('epa', self.WEIGHT_EPA))
        if self.go2epa_import_result:
            phases.append(('import', self.WEIGHT_IMPORT))

        total = sum(weight for _, weight in phases) or 1
        cursor = 0.0
        ranges = {}
        for name, weight in phases:
            span = 100.0 * weight / total
            ranges[name] = (cursor, cursor + span)
            cursor += span

        # Instance ranges used by existing _set_progress calls
        self.PG2EPA_START, self.PG2EPA_END = ranges.get('pg2epa', (0, 0))
        self.EXPORT_START, self.EXPORT_END = ranges.get('export', (0, 0))
        self.EPA_START, self.EPA_END = ranges.get('epa', (0, 0))
        self.IMPORT_START, self.IMPORT_END = ranges.get('import', (0, 0))

    def _set_progress(self, start, end, local_percent=100):
        """Map a phase-local percent (0-100) into the global task progress bar."""
        local_percent = max(0, min(100, float(local_percent)))
        self.setProgress(start + (end - start) * local_percent / 100.0)

    def _exec_function_pg2epa(self):

        self.json_result = None
        status = False
        self._set_progress(self.PG2EPA_START, self.PG2EPA_END, 0)

        extras = f'"resultId":"{self.result_name}"'
        if global_vars.project_type == 'ud':
            extras += f', "dumpSubcatch":"{self.export_subcatch}"'

        # 7 steps
        main_json_result = None
        for step in range(1, 8):
            self.body = tools_gw.create_body(extras=(extras + f', "step": {step}'))
            msg = "Task 'Go2Epa' execute procedure '{0}' step {1}"
            msg_params = ("gw_fct_pg2epa_main", step,)
            tools_log.log_info(msg, msg_params=msg_params)
            json_result = tools_gw.execute_procedure('gw_fct_pg2epa_main', self.body,
                                                     aux_conn=self.aux_conn, is_thread=True)
            if step == 6:
                main_json_result = json_result
            if self.isCanceled() or json_result is None:
                return False
            self.step_completed.emit(json_result, "\n")
            self._set_progress(self.PG2EPA_START, self.PG2EPA_END, step / 7 * 100)
            if json_result.get('status') == 'Failed':
                tools_log.log_warning(json_result)
                self.function_failed = True
                self.step_completed.emit({"message": {"level": 1, "text": "EXECUTION FAILED! Check logs for more information"}}, "\n")
                return False

        json_result = main_json_result
        self.json_result = json_result
        self.complet_result = json_result
        if json_result is None or not json_result:
            self.function_failed = True
        elif 'status' in json_result:
            if json_result['status'] == 'Failed':
                tools_log.log_warning(json_result)
                self.function_failed = True
            else:
                status = True
        if self.isCanceled():
            return False

        return status

    def _export_inp(self):

        if self.isCanceled():
            return False

        msg = "Export INP file into PostgreSQL"
        tools_log.log_info(msg)

        # Get values from complet_result['body']['file'] and insert into INP file
        body = (self.complet_result or {}).get('body') or {}
        if 'file' not in body:
            return False

        msg = "Task '{0}' execute function '{1}'"
        msg_params = ("Go2Epa", "_fill_inp_file",)
        tools_log.log_info(msg, msg_params=msg_params)
        self._fill_inp_file(self.file_inp, body['file'])
        self.message = (self.complet_result.get('message') or {}).get('text')
        msg = "Export INP finished. "
        self.common_msg += tools_qt.tr(msg)

        self._set_progress(self.EXPORT_START, self.EXPORT_END)
        return True

    def _fill_inp_file(self, folder_path=None, all_rows=None):

        msg = "Write inp file........: {0}"
        msg_params = (folder_path,)
        tools_log.log_info(msg, msg_params=msg_params)

        # Generate generic INP file
        file_inp = open(folder_path, "w", errors='replace')
        read = True
        for row in all_rows:
            # Use regexp to check which targets to read (everyone except GULLY)
            if bool(re.match(r'\[(.*?)\]', row['text'])) and \
                    ('GULLY' in row['text'] or 'LINK' in row['text'] or
                     'GRATE' in row['text'] or 'LXSECTIONS' in row['text']):
                read = False
            elif bool(re.match(r'\[(.*?)\]', row['text'])):
                read = True
            if row.get('text') is not None and read:
                line = row['text'].rstrip() + "\n"
                file_inp.write(line)

        self._close_file(file_inp)

        # Save INP file into database
        with open(folder_path, "rb") as file_inp:
            file_binary = file_inp.read()

        sql = f"UPDATE rpt_cat_result SET inp_file = {psycopg2.Binary(file_binary)} WHERE result_id = '{self.result_name}';"
        tools_db.execute_sql(sql, log_sql=True, is_thread=True)

        networkmode = self.network_mode
        if global_vars.project_type == 'ud' and networkmode and networkmode == 2:

            # Replace extension .inp
            aditional_path = folder_path.replace('.inp', '_inlet_info.dat')
            aditional_file = open(aditional_path, "w", errors='replace')
            read = True
            save_file = False
            for row in all_rows:
                # Use regexp to check which targets to read (only TITLE and aditional target)
                if bool(re.match(r'\[(.*?)\]', row['text'])) and \
                        ('GULLY' in row['text'] or 'LINK' in row['text'] or
                         'GRATE' in row['text'] or 'LXSECTIONS' in row['text']):

                    read = True
                    if 'GULLY' in row['text'] or 'LINK' in row['text'] or \
                       'GRATE' in row['text'] or 'LXSECTIONS' in row['text']:
                        save_file = True
                elif bool(re.match(r'\[(.*?)\]', row['text'])):
                    read = False

                if row.get('text') is not None and read:

                    line = row['text'].rstrip() + "\n"

                    if not bool(re.match(r';;-(.*?)', row['text'])) and not bool(re.match(r'\[(.*?)', row['text'])):
                        line = re.sub(';;', '', line)
                        line = re.sub(' +', ' ', line)
                        aditional_file.write(line)

            self._close_file(aditional_file)

            if save_file is False:
                os.remove(aditional_path)

    def _execute_epa(self):

        if self.isCanceled():
            return False

        msg = "Execute EPA software"
        tools_log.log_info(msg)
        self.step_completed.emit({"message": {"level": 1, "text": "Execute EPA software......"}}, "")

        msg = "INP file not found"
        if self.file_inp is not None:
            if not os.path.exists(self.file_inp):
                self.error_msg = "{0}: {1}"
                self.error_msg_params = (msg, self.file_inp,)
                return False
        else:
            self.error_msg = "{0}: {1}"
            self.error_msg_params = (msg, self.file_inp,)
            return False

        # Set file to execute
        opener = None
        if global_vars.project_type in 'ws':
            opener = f"{lib_vars.plugin_dir}{os.sep}resources{os.sep}epa{os.sep}epanet{os.sep}epanet.exe"
        elif global_vars.project_type in 'ud':
            opener = f"{lib_vars.plugin_dir}{os.sep}resources{os.sep}epa{os.sep}swmm{os.sep}swmm5.exe"

        if opener is None:
            return False

        if not os.path.exists(opener):
            self.error_msg = "File not found: {0}"
            self.error_msg_params = (opener,)
            return False

        subprocess.call([opener, self.file_inp, self.file_rpt], shell=False)
        self._set_progress(self.EPA_START, self.EPA_END)
        self.common_msg += "EPA model finished. "
        self.step_completed.emit({"message": {"level": 1, "text": "EPA model finished."}}, "\n")

        return True

    def _init_hydraulic_engine(self) -> bool:
        """Try to import hydraulic_engine. Returns True if the package is available."""
        try:
            from importlib.util import find_spec
            from hydraulic_engine.utils import tools_log as he_tools_log
            has_hydraulic_engine = find_spec("hydraulic_engine") is not None
            if has_hydraulic_engine:
                he_tools_log.set_logger("hydraulic_engine", min_log_level=10)
                msg = "Hydraulic engine imported successfully"
                tools_log.log_info(msg)
            else:
                msg = "Hydraulic engine not imported. Using default EPA software."
                tools_log.log_info(msg)
            return has_hydraulic_engine
        except ImportError:
            msg = "Hydraulic engine not imported. Using default EPA software."
            tools_log.log_info(msg)
            return False

    def _on_epa_progress(self, progress: int, message: str):
        self._set_progress(self.EPA_START, self.EPA_END, progress)
        self.step_completed.emit(
            {"message": {"level": 1, "text": f"EPA [{progress}%] {message}"}},
            "\n",
        )

    def _on_epa_step(self, _en_data, _step_count):
        """Continue hydraulic steps unless the QgsTask was canceled."""
        return not self.isCanceled()

    def _create_hydraulic_runner(self, he):
        """Create EPANET or SWMM runner according to project type (hydraulic-engine >= 0.7)."""
        file_sidecar = None
        if self.file_rpt and self.file_rpt != "null":
            root, _ = os.path.splitext(self.file_rpt)
            file_sidecar = root

        if global_vars.project_type == 'ws':
            return he.epanet.EpanetRunner(
                inp_path=self.file_inp,
                rpt_path=self.file_rpt,
                bin_path=f"{file_sidecar}.bin" if file_sidecar else None,
                progress_callback=self._on_epa_progress,
            )
        if global_vars.project_type == 'ud':
            return he.swmm.SwmmRunner(
                inp_path=self.file_inp,
                rpt_path=self.file_rpt,
                out_path=f"{file_sidecar}.out" if file_sidecar else None,
                progress_callback=self._on_epa_progress,
            )
        return None

    def _execute_epa_with_hydraulic_engine(self):
        """Execute EPA (EPANET/SWMM) using hydraulic_engine."""

        import hydraulic_engine as he

        if self.isCanceled():
            return None

        tools_log.log_info("Execute EPA software (hydraulic_engine)")
        self.step_completed.emit({"message": {"level": 1, "text": "Execute EPA software......\n\n"}}, "")

        if self.file_rpt == "null":
            message = "You have to set this parameter"
            self.error_msg = f"{message}: RPT file"
            return None

        msg = "INP file not found"
        if self.file_inp is not None:
            if not os.path.exists(self.file_inp):
                self.error_msg = "{0}: {1}"
                self.error_msg_params = (msg, self.file_inp,)
                return None
        else:
            self.error_msg = "{0}: {1}"
            self.error_msg_params = (msg, self.file_inp,)
            return None

        try:
            runner = self._create_hydraulic_runner(he)
            if runner is None:
                msg = "Unsupported project type for hydraulic engine: {0}"
                msg_params = (global_vars.project_type,)
                self.error_msg = tools_qt.tr(msg, msg_params=msg_params)
                return None

            results = runner.run(step_callback=self._on_epa_step)
            if self.isCanceled() or (
                results is not None
                and results.status == he.utils.enums.RunStatus.CANCELLED
            ):
                return None
            if results is None:
                msg = "Error executing EPA software"
                self.error_msg = msg
                return None
            if results.status == he.utils.enums.RunStatus.ERROR:
                detail = "; ".join(results.errors) if results.errors else "unknown error"
                msg = "Error executing EPA software: {0}"
                msg_params = (detail,)
                self.error_msg = tools_qt.tr(msg, msg_params=msg_params)
                return None
        except Exception as e:
            msg = "Error executing EPA software: {0}"
            msg_params = (e,)
            self.error_msg = tools_qt.tr(msg, msg_params=msg_params)
            return None

        self.common_msg += "EPA model finished. "
        self.step_completed.emit({"message": {"level": 1, "text": "EPA model finished."}}, "\n")
        self._set_progress(self.EPA_START, self.EPA_END)

        return runner

    def _load_epa_layers(self):
        """ Load EPA layers if they are not already loaded """

        # Get EPA layers from database
        body = tools_gw.create_body()
        json_result = tools_gw.execute_procedure('gw_fct_getaddlayervalues', body, is_thread=True)
        if not json_result or json_result['status'] == 'Failed':
            return False

        # Get current loaded layers
        layer_list = []
        for layer in QgsProject.instance().mapLayers().values():
            layer_list.append(tools_qgis.get_layer_source_table_name(layer))

        # Load EPA layers that are not already loaded
        for field in json_result['body']['data']['fields']:
            if field['context'] is not None:
                context = json.loads(field['context'])
                levels = context.get(tools_qt.tr('levels')) or context.get('levels')

                # Check if this is an EPA RESULTS layer

                context = tools_db.get_row("SELECT idval FROM config_typevalue WHERE id = (SELECT context FROM sys_table WHERE id ilike 'v_rpt_arc%' AND context IS NOT NULL LIMIT 1);", is_thread=True)
                if not context or not context[0]:
                    msg = "Could not load EPA Results layers"
                    tools_qgis.show_message(msg)
                    return False
                context = json.loads(context[0])
                if len(levels) > 1 and levels[0] == context[0] and levels[1] == context[1]:
                    tablename = field['tableName']

                    # Check if layer is not already loaded
                    if tablename not in layer_list:
                        layer_name = tablename
                        the_geom = field['geomField'] if field['geomField'] != "None" else None
                        geom_field = field['tableId']

                        if geom_field:
                            geom_field = geom_field.replace(" ", "")
                            group = levels[0]
                            sub_group = levels[1]
                            alias = field['layerName'] if field['layerName'] is not None else field['tableName']

                            tools_gw.add_layer_database(layer_name, the_geom, geom_field, group, sub_group,
                                                      alias=alias, force_create_group=True)

        return True

    def _import_rpt(self):
        """ Import result file """

        msg = "Import rpt file........: {0}"
        msg_params = (self.file_rpt,)
        tools_log.log_info(msg, msg_params=msg_params)

        self.rpt_result = None
        self.json_rpt = None
        status = False
        try:
            # Call import function
            msg = "Task '{0}' execute function '{1}'"
            msg_params = ("Go2Epa", "_read_rpt_file",)
            tools_log.log_info(msg, msg_params=msg_params)
            status = self._read_rpt_file(self.file_rpt)
            if not status:
                return False
            msg_params = ("Go2Epa", "_exec_import_function",)
            tools_log.log_info(msg, msg_params=msg_params)
            status = self._exec_import_function()
            self.active_epa_layers = True
        except Exception as e:
            self.error_msg = str(e)
        finally:
            return status

    def _build_hydraulic_db_connection(self, he):
        """Build a hydraulic_engine PG connection from the active Giswater DAO/credentials."""
        gw_dao = tools_db.dao
        creds = tools_db.dao_db_credentials or {}
        if gw_dao is None and not creds:
            return None

        host = getattr(gw_dao, 'host', None) or creds.get('host') or 'localhost'
        port = getattr(gw_dao, 'port', None) or creds.get('port') or 5432
        dbname = getattr(gw_dao, 'dbname', None) or creds.get('db') or ''
        user = getattr(gw_dao, 'user', None) or creds.get('user') or ''
        password = getattr(gw_dao, 'password', None)
        if password is None:
            password = creds.get('password') or ''

        return he.create_pg_connection(
            host=host,
            port=port,
            dbname=dbname,
            user=user,
            password=password,
            schema=lib_vars.schema_name,
        )

    def _import_rpt_with_hydraulic_engine(self, runner):
        """Import simulation results with hydraulic_engine (WS/UD, >= 0.7)."""

        import hydraulic_engine as he

        msg = "Import simulation results........: {0}"
        msg_params = (self.file_rpt,)
        tools_log.log_info(msg, msg_params=msg_params)

        try:
            row = tools_gw.get_config_value("inp_report_onlymaxmin_values")
            only_extrema = row is not None and row[0] == 'true'

            msg = "Import simulation results into database"
            tools_log.log_info(msg)
            dao = self._build_hydraulic_db_connection(he)
            if dao is None:
                msg = "No database connection available for hydraulic engine export"
                self.error_msg = msg
                return False

            self._set_progress(self.IMPORT_START, self.IMPORT_END, 0)

            # only_extrema is EPANET-only (hydraulic-engine >= 0.5); SWMM export has no such kwarg
            export_kwargs = {
                'to': he.ExportDataSource.DATABASE,
                'result_id': self.result_name,
                'client': dao,
                'round_decimals': 4,
            }
            if global_vars.project_type == 'ws':
                export_kwargs['only_extrema'] = only_extrema

            status = runner.export_result(**export_kwargs)
            if not status:
                msg = "Error importing simulation results into database"
                self.error_msg = msg
                return False

            msg = "Import simulation results finished"
            tools_log.log_info(msg)

            # gw_fct_rpt2pg_log expects temp_audit_check_data to exist;
            # normally created by gw_fct_rpt2pg_main, which the hydraulic engine path bypasses
            parameters = f"'{self.result_name}', " + " '" + '{"status":"Accepted"}' + "'::json"
            rows = tools_gw.execute_procedure('gw_fct_rpt2pg_log', parameters=parameters, is_thread=True)
            if rows:
                self.rpt_result = rows
                # message may be explicitly null in JSON → .get("message", {}) still returns None
                self.message = (rows.get("message") or {}).get("text")
            else:
                self.rpt_result = {
                    "status": "Accepted",
                    "message": {"level": 1, "text": "Import simulation results finished"},
                }
                self.message = self.rpt_result["message"]["text"]
            self.active_epa_layers = True
            msg = "Import RPT file finished. "
            self.common_msg += tools_qt.tr(msg)
            self._set_progress(self.IMPORT_START, self.IMPORT_END)
            return True
        except Exception as e:
            self.error_msg = str(e)
            return False
        finally:
            try:
                he.close_connection()
            except Exception:
                pass

    def _read_rpt_file(self, file_path: str = None):
        """
        Parse an EPANET/SWMM RPT text file and build a JSON-serializable row list string.

        Behavior overview:
        - Reads the RPT file line by line and tokenizes each line into columns `col1..colN`.
        - Resolves a "target" table for each line using `config_fprocess.target` mappings for the current `fid`.
        - Extracts a time string (HH:MM:SS) into a special `col40` when present.
        - Produces `self.json_rpt` as a JSON array string with entries like:
          {"target":"'<table>'", "col40":"'<HH:MM:SS>'", "col1":"<val>", ...}
          Note: values that appear as "''" are converted to `null`.

        Special handling:
        - If the config variable `force_import_velocity_higher_50ms` is set, any literal ">50" is coerced to "50".
          Otherwise, encountering ">50" aborts with an error (velocity must be numeric).
        - Detects overlapped numeric columns (e.g., numbers containing two dots) and aborts with a guidance message,
          unless the line is part of version/input headers.
        - Attempts to split tokens that contain a minus sign glued to numbers (e.g., "123-45") into separate pieces.

        Side effects:
        - Sets `self.json_rpt` with the built JSON array string (consumed by `_exec_import_function`).
        - Sets `self.error_msg` and `self.error_msg_params` on failure.
        - Advances progress via `self.setProgress` and respects cancellation with `self.isCanceled`.

        Returns:
        - True on success, False if parsing is cancelled or an unrecoverable format error is detected.
        """

        # Read normalization flag: optionally coerce literal ">50" velocities to numeric "50"
        replace = tools_gw.get_config_parser('btn_go2epa', 'force_import_velocity_higher_50ms', "user", "init", prefix=False)
        replace = tools_os.set_boolean(replace, default=False)

        # Open file and load all lines (we keep the file handle to close it later)
        self.file_rpt = open(file_path, "r+", errors='replace')
        full_file = self.file_rpt.readlines()
        progress = 0

        # Build a map of tokens -> target table using `config_fprocess.target` for this process (`fid`)
        # The `target` column is stored like a JSON-ish list of strings. We flatten it here into a dict.
        sql = f"SELECT tablename, target FROM config_fprocess WHERE fid = {self.fid} ORDER BY orderby;"
        rows = tools_db.get_rows(sql, is_thread=True)
        sources = {}
        for row in rows:
            json_elem = row[1].replace('{', '').replace('}', '')
            item = json_elem.split(',')
            for i in item:
                sources[i.strip()] = row[0].strip()

        # Initialize default fields. Until we match a source token, `target` and `col40` remain "null".
        target = "null"
        col40 = "null"
        json_rpt = ""
        # noinspection PyUnusedLocal
        row_count = sum(1 for rows in full_file)

        for line_number, row in enumerate(full_file):

            # Abort gracefully if the task is cancelled
            if self.isCanceled():
                self._close_file()
                del full_file
                return False

            progress += 1
            # Skip comments/separators commonly used in EPANET/SWMM reports
            if '**' in row or '--' in row:
                continue

            # Normalize velocity literal if allowed by config; otherwise it will be treated as an error later
            if replace and '>50' in row:
                row = row.replace('>50', '50')

            row = row.rstrip()
            dirty_list = row.split(' ')

            # Compact multiple spaces into a clean list of tokens
            for x in range(len(dirty_list) - 1, -1, -1):
                if dirty_list[x] == '':
                    dirty_list.pop(x)

            sp_n = []
            if len(dirty_list) > 0:
                for x in range(0, len(dirty_list)):
                    # Split tokens that look like numbers glued with minus signs (e.g., "123-45...")
                    if bool(re.search(r'[0-9][-]\d{1,2}[.]]*', str(dirty_list[x]))):
                        last_index = 0
                        for i, c in enumerate(dirty_list[x]):
                            if "-" == c:
                                json_elem = dirty_list[x][last_index:i]
                                last_index = i
                                sp_n.append(json_elem)

                        # noinspection PyUnboundLocalVariable
                        json_elem = dirty_list[x][last_index:i]
                        sp_n.append(json_elem)

                    # Detect overlapped numeric columns (two dots in the same token), which indicates broken alignment
                    elif bool(re.search(r'(\d\..*\.\d)', str(dirty_list[x]))):
                        if not any(item in dirty_list for item in ['Version', 'VERSION', 'Input', 'INPUT']):
                            msg = "Error near line {0} -> {1}"
                            msg_params = (line_number + 1, dirty_list,)
                            tools_log.log_info(msg, msg_params=msg_params)
                            message = ("The rpt file is not valid to import. "
                                        "Because columns on rpt file are overlapped, it seems you need to improve your simulation. "
                                        "Please check and fix it before continuing.\n"
                                        "{0}")
                            self.error_msg = message
                            error_near = f"{tools_qt.tr('Error near line')} {line_number + 1} -> {dirty_list}"
                            self.error_msg_params = (error_near,)
                            self._close_file()
                            del full_file
                            return False
                    # Velocity reported as ">50" is invalid unless normalization is enabled above
                    elif bool(re.search('>50', str(dirty_list[x]))):
                        msg = "Error near line {0} -> {1}"
                        msg_params = (line_number + 1, dirty_list,)
                        tools_log.log_info(msg, msg_params=msg_params)
                        message = ("The rpt file is not valid to import. "
                                    "Because velocity has not numeric value (>50), it seems you need to improve your simulation. "
                                    "Please ckeck and fix it before continue. \n"
                                    "Note: You can force the import by activating the variable '{0}' on the {1} file. \n"
                                    "{2}")
                        self.error_msg = message
                        error_near = f"{tools_qt.tr('Error near line')} {line_number + 1} -> {dirty_list}"
                        self.error_msg_params = ("force_import_velocity_higher_50ms", "init.config", error_near,)
                        self._close_file()
                        del full_file
                        return False
                    else:
                        sp_n.append(dirty_list[x])

            # Try to resolve the `target` table from the first tokens of the line
            for k, v in sources.items():
                try:
                    if k in (f'{sp_n[0]} {sp_n[1]}', f'{sp_n[0]}'):
                        target = "'" + v + "'"
                        _time = re.compile('^([012]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$')
                        if len(sp_n) > 3 and _time.search(sp_n[3]):
                            col40 = "'" + sp_n[3] + "'"
                except IndexError:
                    pass
                except Exception as e:
                    tools_log.log_info(type(e).__name__)

            if len(sp_n) > 0:
                # Assemble a JSON object string for this line: target/col40 + dynamic col1..colN
                json_elem = f'"target": "{target}", "col40": "{col40}", '
                for x in range(0, len(sp_n)):
                    json_elem += f'"col{x + 1}":'
                    if "''" not in sp_n[x]:
                        value = '"' + sp_n[x].strip().replace("\n", "") + '", '
                        value = value.replace("''", "null")
                    else:
                        value = 'null, '
                    json_elem += value

                json_elem = '{' + str(json_elem[:-2]) + '}, '
                json_rpt += json_elem

            # Update progress bar every ~1000 lines
            if progress % 1000 == 0:
                self._set_progress(
                    self.IMPORT_START,
                    self.IMPORT_END,
                    (line_number * 100) / row_count,
                )

        # Manage JSON
        # Finalize the JSON array string (strip the trailing comma+space added during the loop)
        json_rpt = '[' + str(json_rpt[:-2]) + ']'
        self.json_rpt = json_rpt

        self._close_file()
        del full_file

        return True

    def _exec_import_function(self):
        """ Call function gw_fct_rpt2pg_main """

        for step in range(1, 3):
            extras = f'"step":"{step}", "resultId":"{self.result_name}"'
            if step == 1 and self.json_rpt:
                extras += f', "file": {self.json_rpt}'
            self.body = tools_gw.create_body(extras=extras)
            self.json_result = tools_gw.execute_procedure('gw_fct_rpt2pg_main', self.body,
                                                          aux_conn=self.aux_conn, is_thread=True)
            self.rpt_result = self.json_result
            if self.json_result is None or not self.json_result:
                self.function_failed = True
                return False

            if self.json_result.get('status') == 'Failed':
                tools_log.log_warning(self.json_result)
                self.function_failed = True
                return False
            self.step_completed.emit(self.json_result, "\n")
        # final message
        msg = "Import RPT file finished."
        self.common_msg += tools_qt.tr(msg)
        self._set_progress(self.IMPORT_START, self.IMPORT_END)

        return True

    # endregion
