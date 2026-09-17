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
from datetime import timedelta
from time import time
from concurrent.futures import ThreadPoolExecutor

from qgis.PyQt.QtCore import pyqtSignal
from qgis.core import QgsTask

from .task import GwTask
from ... import global_vars
from ...libs import tools_qt, tools_db, tools_log, lib_vars
from ..utils import tools_gw


class GwRecursiveEpa(GwTask):
    time_changed = pyqtSignal(str)
    task_finished = pyqtSignal()
    change_btn_accept = pyqtSignal(bool)

    def __init__(self, description, prefix, path, settings, plugin_dir):

        super().__init__(description, QgsTask.Flag.CanCancel)
        self.prefix = prefix
        self.path = path
        self.settings = settings
        self.fid = 140
        self.plugin_dir = lib_vars.plugin_dir
        self.stop = False
        self.t0 = 0
        self.total_objects = 0
        self.file_pairs = []
        self.max_threads = 4
        self.initialize_variables()

    def initialize_variables(self):

        self.exception = None
        self.error_msg = None
        self.error_msg_params = None
        self.message = None
        self.common_msg = ""
        self.function_failed = False
        self.complet_result = None
        self.function_name = None
        self.rpt_result = None
        self.file_rpt = None
        self.files_exported = []
        global_vars.project_type = tools_gw.get_project_type()

    def run(self):

        self.change_btn_accept.emit(True)
        self.export_subcatch = self.settings.value("options/export_subcatch")
        max_threads = self.settings.value("options/max_threads")
        try:
            self.max_threads = int(max_threads)
        except ValueError:
            msg = "Tried to set {0} to '{1}' but it's not an integer. Defaulting to 4 threads."
            msg_params = ("max_threads", max_threads,)
            tools_log.log_warning(msg, msg_params=msg_params)

        # Get queries and lists
        lists1, lists2, lists3, queries1, queries2, queries3 = self._get_queries_and_lists()

        # Calculate total number of objects in all lists
        self.total_objects = len([item for sublist in lists1 for item in sublist])
        if lists2:
            self.total_objects *= len([item for sublist in lists2 for item in sublist])
        if lists3:
            self.total_objects *= len([item for sublist in lists3 for item in sublist])

        # ================================
        # Execute fct_pg2epa_main
        # ================================
        try:
            self.t0 = time()  # Initial time
            self.cur_idx = 0
            # For each query in `list1` section
            for idx1, query1 in enumerate(queries1):  # Get the `query{i}` parameter (`list1` section)
                list1 = lists1[idx1]  # Get the `list{i}` parameter (`list1` section)
                # For each object in the `list{i}` parameter (`list1` section)
                for l1o in list1:
                    query = query1.replace("$list1object", l1o)  # Replace `$list1object` for actual `list{i}` object
                    tools_db.execute_sql(query, is_thread=True)  # Execute `query{i}` from `list1` section
                    if self.stop or lib_vars.session_vars['last_error']:
                        return False
                    if not queries2 or not lists2:
                        self.run_go2epa(l1o)
                        continue
                    # Process `list2` section
                    for idx2, query2 in enumerate(queries2):  # Get the `query{i}` parameter (`list2` section)
                        list2 = lists2[idx2]  # Get the `list{i}` parameter (`list2` section)
                        # For each object in the `list{i}` parameter (`list2` section)
                        for l2o in list2:
                            query = query2.replace("$list2object", l2o)  # Replace `$list2object` for actual `list{i}` object
                            tools_db.execute_sql(query, is_thread=True)  # Execute `query{i}` from `list2` section
                            if self.stop or lib_vars.session_vars['last_error']:
                                return False
                            if not queries3 or not lists3:
                                self.run_go2epa(l1o, l2o)
                                continue
                            # Process `list3` section
                            for idx3, query3 in enumerate(queries3):  # Get the `query{i}` parameter (`list3` section)
                                list3 = lists3[idx3]  # Execute `query{i}` from `list3` section
                                # For each object in the `list{i}` parameter (`list2` section)
                                for l3o in list3:
                                    query = query3.replace("$list3object", l3o)  # Replace `$list3object` for actual `list{i}` object
                                    tools_db.execute_sql(query, is_thread=True)  # Execute `query{i}` from `list3` section
                                    self.run_go2epa(l1o, l2o, l3o)
                                    if self.stop or lib_vars.session_vars['last_error']:
                                        return False

        except Exception as e:
            self.exception = e
            return False

        # ================================
        # Execute epa software & import rpt(s)
        # ================================
        try:
            self.execute_multi_epa()
            self.import_rpt()
        except Exception as e:
            self.exception = e
            return False

        return True

    def _get_queries_and_lists(self):
        # list1
        queries1 = []
        lists1 = []
        for i in range(1, 20):
            query = self.settings.value(f"list1/query{i}")
            list_str = self.settings.value(f"list1/list{i}")
            if not query or not list_str:
                break
            queries1.append(query)
            if not issubclass(type(list_str), list):
                list_str = [list_str]
            lists1.append(list_str)
        # list2
        queries2 = []
        lists2 = []
        for i in range(1, 20):
            query = self.settings.value(f"list2/query{i}")
            list_str = self.settings.value(f"list2/list{i}")
            if not query or not list_str:
                break
            queries2.append(query)
            if not issubclass(type(list_str), list):
                list_str = [list_str]
            lists2.append(list_str)
        # list3
        queries3 = []
        lists3 = []
        for i in range(1, 20):
            query = self.settings.value(f"list3/query{i}")
            list_str = self.settings.value(f"list3/list{i}")
            if not query or not list_str:
                break
            queries3.append(query)
            if not issubclass(type(list_str), list):
                list_str = [list_str]
            lists3.append(list_str)
        return lists1, lists2, lists3, queries1, queries2, queries3

    def run_go2epa(self, l1o=None, l2o=None, l3o=None):
        self.cur_idx += 1
        resultname = f"{self.prefix}"
        if l3o:
            resultname += f"-{l3o}"
        if l2o:
            resultname += f"-{l2o}"
        if l1o:
            resultname += f"-{l1o}"
        self.files_exported.append(resultname)
        inpfilename = f"{self.path}{os.sep}{resultname}.inp"
        rptfilename = f"{self.path}{os.sep}{resultname}.rpt"
        self.execute_go2epa(resultname, inpfilename, rptfilename)
        self.file_pairs.append((resultname, inpfilename, rptfilename))
        self._calculate_remaining_time(self.t0)
        self.t0 = time()

    def finished(self, result):

        super().finished(result)
        self.task_finished.emit()
        self.change_btn_accept.emit(False)

        self._close_file()
        if self.files_exported:
            msg = "The process has been executed. Files generated:"
            tools_qt.show_info_box(msg, inf_text=self.files_exported)
        if self.isCanceled():
            return

        # If PostgreSQL function returned null
        if self.complet_result is None:
            msg = "Database returned null. Check postgres function '{0}'"
            msg_params = (self.function_name,)
            tools_log.log_warning(msg, msg_params=msg_params)

        if self.function_failed:
            if self.json_result is None or not self.json_result:
                msg = "Function failed finished"
                msg_params = (self.function_name,)
                tools_log.log_warning(msg, msg_params=msg_params)
            if self.complet_result:
                if 'status' in self.complet_result:
                    if "Failed" in self.complet_result['status']:
                        tools_gw.manage_json_exception(self.complet_result)
            if self.rpt_result:
                if 'status' in self.rpt_result:
                    if "Failed" in self.rpt_result['status']:
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
        self.stop_task()
        super().cancel()

    def stop_task(self):
        self.stop = True

    def _calculate_remaining_time(self, t0):
        tf = time()  # Final time
        td = tf - t0  # Delta time
        time_remaining = td * (self.total_objects - self.cur_idx)  # Delta time * remaining pages
        msg = "Remaining: {0} ({1}/{2})"
        msg_params = (timedelta(seconds=round(time_remaining)), self.cur_idx, self.total_objects)
        self.time_changed.emit(tools_qt.tr(msg, list_params=msg_params))

    def execute_go2epa(self, resultname, inpfilename, rptfilename):

        # Execute pg2epa
        status = self._exec_function_pg2epa(resultname)
        tools_db.dao.reset_db()
        if not status:
            self.function_name = 'gw_fct_pg2epa_main'
            return False

        # Export inp
        status = self._export_inp(inpfilename, rptfilename)

        return status

    # region pg2epa
    def _exec_function_pg2epa(self, resultname):

        self.json_result = None
        status = False
        self.setProgress(0)

        extras = f'"resultId":"{resultname}"'
        if global_vars.project_type == 'ud':
            extras += f', "dumpSubcatch":"{self.export_subcatch}"'

        for i in range(1, 8):
            self.body = tools_gw.create_body(extras=extras + f', "step": {i}')
            msg = "Task 'Go2Epa' execute procedure '{1}' step {2} with parameters: '{1}', '{3}', '{4}', '{5}', '{6}'"
            msg_params = ("gw_fct_pg2epa_main", i, self.body, "log_sql=True", f"aux_conn={self.aux_conn}",
                          "is_thread=True",)
            tools_log.log_info(msg, msg_params=msg_params)
            json_result = tools_gw.execute_procedure('gw_fct_pg2epa_main', self.body, log_sql=True,
                                                     aux_conn=self.aux_conn, is_thread=True)
            if i == 6:
                self.json_result = json_result
                self.complet_result = json_result
            if self.isCanceled():
                return False

        # Manage json result
        if self.json_result is None or not self.json_result:
            self.function_failed = True
        elif 'status' in self.json_result:
            if self.json_result['status'] == 'Failed':
                tools_log.log_warning(self.json_result)
                self.function_failed = True
            else:
                status = True
        if self.isCanceled():
            return False

        return status
    # endregion

    # region export inp
    def _export_inp(self, inpfilename, rptfilename):

        if self.isCanceled():
            return False

        msg = "Export INP file into PostgreSQL"
        tools_log.log_info(msg)

        # Get values from complet_result['body']['file'] and insert into INP file
        if 'file' not in self.complet_result['body']:
            return False

        self.file_inp = inpfilename
        self.file_rpt = rptfilename
        if self.file_inp == "null":
            message = "You have to set this parameter"
            self.error_msg = "{0}: INP file"
            self.error_msg_params = (message,)
            return False

        self._fill_inp_file(self.file_inp, self.complet_result['body']['file'])
        self.message = self.complet_result['message']['text']
        self.common_msg += tools_qt.tr("Export INP finished. ")

        return True

    def _fill_inp_file(self, folder_path=None, all_rows=None):

        msg = "Write inp file........: {0}"
        msg_params = (folder_path,)
        tools_log.log_info(msg, msg_params=msg_params)

        # Generate generic INP file
        file_inp = open(folder_path, "w")
        read = True
        for row in all_rows:
            # Use regexp to check which targets to read (everyone except GULLY)
            if bool(re.match(r'\[(.*?)\]', row['text'])) and \
                    ('GULLY' in row['text'] or 'LINK' in row['text'] or
                     'GRATE' in row['text'] or 'LXSECTIONS' in row['text']):
                read = False
            elif bool(re.match(r'\[(.*?)\]', row['text'])):
                read = True
            if 'text' in row and row['text'] is not None and read:
                line = row['text'].rstrip() + "\n"
                file_inp.write(line)

        self._close_file(file_inp)

        networkmode = tools_gw.get_config_value('inp_options_networkmode')
        if global_vars.project_type == 'ud' and networkmode and networkmode[0] == "2":

            # Replace extension .inp
            aditional_path = folder_path.replace('.inp', '.gul')
            aditional_file = open(aditional_path, "w")
            read = True
            save_file = False
            for row in all_rows:
                # Use regexp to check which targets to read (only TITLE and aditional target)
                if bool(re.match(r'\[(.*?)\]', row['text'])) and \
                        ('TITLE' in row['text'] or 'GULLY' in row['text'] or 'LINK' in row['text'] or
                         'GRATE' in row['text'] or 'LXSECTIONS' in row['text']):
                    read = True
                    if 'GULLY' in row['text'] or 'LINK' in row['text'] or \
                       'GRATE' in row['text'] or 'LXSECTIONS' in row['text']:
                        save_file = True
                elif bool(re.match(r'\[(.*?)\]', row['text'])):
                    read = False
                if 'text' in row and row['text'] is not None and read:
                    line = row['text'].rstrip() + "\n"
                    aditional_file.write(line)

            self._close_file(aditional_file)

            if save_file is False:
                os.remove(aditional_path)

    def _close_file(self, file=None):

        if file is None:
            file = self.file_rpt

        try:
            if file:
                file.close()
                del file
        except Exception:
            pass
    # endregion

    # region execute epa
    def execute_multi_epa(self):

        if self.isCanceled():
            return False

        msg = "Execute EPA software"
        tools_log.log_info(msg)

        # Set file to execute
        opener = None
        if global_vars.project_type in 'ws':
            opener = f"{self.plugin_dir}{os.sep}resources{os.sep}epa{os.sep}epanet{os.sep}epanet.exe"
        elif global_vars.project_type in 'ud':
            opener = f"{self.plugin_dir}{os.sep}resources{os.sep}epa{os.sep}swmm{os.sep}swmm5.exe"

        if opener is None:
            return False

        if not os.path.exists(opener):
            self.error_msg = "File not found: {0}"
            self.error_msg_params = (opener,)
            return False

        files_errors = []
        for result_name, file_inp, file_rpt in self.file_pairs:
            msg = "INP file not found"
            if file_inp is not None:
                if not os.path.exists(file_inp):
                    self.error_msg = "{0}: {1}"
                    self.error_msg_params = (msg, file_inp,)
                    files_errors.append(file_inp)
            else:
                self.error_msg = "{0}: {1}"
                self.error_msg_params = (msg, file_inp,)
        # Using ThreadPoolExecutor to manage concurrent subprocesses
        with ThreadPoolExecutor(max_workers=self.max_threads) as executor:
            # Submitting subprocesses for each file_inp/file_rpt pair
            subprocesses = [executor.submit(self._execute_epa, opener, file_inp, file_rpt)
                            for _, file_inp, file_rpt in self.file_pairs if file_inp not in files_errors]

            # Wait for all subprocesses to complete
            for subproc in subprocesses:
                subproc.result()  # Wait for completion

        self.common_msg += tools_qt.tr("EPA model finished. ")

        return True

    def _execute_epa(self, opener, file_inp, file_rpt):
        subprocess.call([opener, file_inp, file_rpt], shell=False)

    # endregion

    # region import rpt
    def import_rpt(self):
        for result_name, file_inp, file_rpt in self.file_pairs:
            self._import_rpt(result_name, file_rpt)

    def _import_rpt(self, result_name, file_rpt):
        """ Import result file """

        msg = "Import rpt file........: {0}"
        msg_params = (file_rpt,)
        tools_log.log_info(msg, msg_params=msg_params)

        self.rpt_result = None
        self.json_rpt = None
        status = False
        try:
            # Call import function
            status = self._read_rpt_file(file_rpt)
            if not status:
                return False
            msg = "Task 'Go2Epa' execute function 'def _exec_import_function'"
            msg_params = ("def _exec_import_function",)
            tools_log.log_info(msg, msg_params=msg_params)
            status = self._exec_import_function(result_name)
        except Exception as e:
            self.error_msg = str(e)
        finally:
            return status

    def _read_rpt_file(self, file_path=None):

        self.file_rpt = open(file_path, "r+")
        full_file = self.file_rpt.readlines()
        progress = 0

        # Create dict with sources
        sql = f"SELECT tablename, target FROM config_fprocess WHERE fid = {self.fid};"
        rows = tools_db.get_rows(sql, is_thread=True, aux_conn=self.aux_conn)
        sources = {}
        for row in rows:
            json_elem = row[1].replace('{', '').replace('}', '')
            item = json_elem.split(',')
            for i in item:
                sources[i.strip()] = row[0].strip()

        # While we don't find a match with the target, target and col40 must be null
        target = "null"
        col40 = "null"
        json_rpt = ""
        # noinspection PyUnusedLocal
        row_count = sum(1 for rows in full_file)

        for line_number, row in enumerate(full_file):

            if self.isCanceled():
                self._close_file()
                del full_file
                return False

            progress += 1
            if '**' in row or '--' in row:
                continue

            if global_vars.project_type == 'ud' and '>50' in row:
                row = row.replace('>50', '50')

            row = row.rstrip()
            dirty_list = row.split(' ')

            # Clean unused items
            for x in range(len(dirty_list) - 1, -1, -1):
                if dirty_list[x] == '':
                    dirty_list.pop(x)

            sp_n = []
            if len(dirty_list) > 0:
                for x in range(0, len(dirty_list)):
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

                    elif bool(re.search(r'(\d\..*\.\d)', str(dirty_list[x]))):
                        if 'Version' not in dirty_list and 'VERSION' not in dirty_list:
                            msg = "Error near line {0} -> {1}"
                            msg_params = (line_number + 1, dirty_list,)
                            tools_log.log_info(msg, msg_params=msg_params)
                            message = ("The rpt file is not valid to import. "
                                       "Because columns on rpt file are overlaped, it seems you need to improve your simulation. "
                                       "Please ckeck and fix it before continue. \n"
                                       "{0}")
                            self.error_msg = message
                            error_near = f"{tools_qt.tr('Error near line')} {line_number + 1} -> {dirty_list}"
                            self.error_msg_params = (error_near,)
                            self._close_file()
                            del full_file
                            return False
                    elif bool(re.search('>50', str(dirty_list[x]))):
                        msg = "Error near line {0} -> {1}"
                        msg_params = (line_number + 1, dirty_list,)
                        tools_log.log_info(msg, msg_params=msg_params)
                        message = ("The rpt file is not valid to import. "
                                   "Because velocity has not numeric value (>50), it seems you need to improve your simulation. "
                                   "Please ckeck and fix it before continue. \n"
                                   "{0}")
                        self.error_msg = message
                        error_near = f"{tools_qt.tr('Error near line')} {line_number + 1} -> {dirty_list}"
                        self.error_msg_params = (error_near,)
                        self._close_file()
                        del full_file
                        return False
                    else:
                        sp_n.append(dirty_list[x])

            # Find strings into dict and set target column
            for k, v in sources.items():
                try:
                    if k in (f'{sp_n[0]} {sp_n[1]}', f'{sp_n[0]}'):
                        target = "'" + v + "'"
                        _time = re.compile('^([012]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$')
                        if _time.search(sp_n[3]):
                            col40 = "'" + sp_n[3] + "'"
                except IndexError:
                    pass
                except Exception as e:
                    tools_log.log_info(type(e).__name__)

            if len(sp_n) > 0:
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

            # Update progress bar
            if progress % 1000 == 0:
                self.setProgress((line_number * 100) / row_count)

        # Manage JSON
        json_rpt = '[' + str(json_rpt[:-2]) + ']'
        self.json_rpt = json_rpt

        self.json_rpt = self.json_rpt.replace("\\", "/")
        self._close_file()
        del full_file

        return True

    def _exec_import_function(self, result_name):
        """ Call function gw_fct_rpt2pg_main """

        extras = f'"resultId":"{result_name}"'
        if self.json_rpt:
            extras += f', "file": {self.json_rpt}'
        for i in range(1, 3):
            self.body = tools_gw.create_body(extras=extras + f', "step": {i}')
            self.json_result = tools_gw.execute_procedure('gw_fct_rpt2pg_main', self.body,
                                                          aux_conn=self.aux_conn, is_thread=True)
            self.rpt_result = self.json_result
            if self.json_result is None or not self.json_result:
                self.function_failed = True
                return False

            if 'status' in self.json_result and self.json_result['status'] == 'Failed':
                tools_log.log_warning(self.json_result)
                self.function_failed = True
                return False

        # final message
        self.common_msg += tools_qt.tr("Import RPT file finished.")

        return True

    # endregion
