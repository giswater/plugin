"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from qgis.PyQt.QtCore import pyqtSignal

from .task import GwTask
from ..utils import tools_gw
from ...libs import tools_db, tools_qt, tools_log, lib_vars
from qgis.utils import iface


class GwAutoMincutTask(GwTask):

    task_finished = pyqtSignal(list)

    def __init__(self, description, mincut_class, element_id, action="mincutNetwork", timer=None):

        super().__init__(description)
        self.mincut_class = mincut_class
        self.element_id = element_id
        self.mincut_action = action
        self.exception = None
        self.timer = timer
        self.body = None
        self.complet_result = None
        # Don't create our own aux_conn, use the mincut cursor instead
        self.use_aux_conn = False

    def run(self):
        """ Automatic mincut: Execute function 'gw_fct_mincut' """

        super().run()

        try:
            real_mincut_id = tools_qt.get_text(self.mincut_class.dlg_mincut, 'result_mincut_id')
            if self.mincut_class.is_new:
                self.mincut_class.set_id_val()
                self.mincut_class.is_new = False
                sql = ("INSERT INTO om_mincut (mincut_state)"
                       " VALUES (4) RETURNING id;")
                new_mincut_id = tools_db.execute_returning(sql, is_thread=True)
                if new_mincut_id[0] < 1:
                    real_mincut_id = 1
                    sql = (f"UPDATE om_mincut SET(id) = (1) "
                           f"WHERE id = {new_mincut_id[0]};")
                    tools_db.execute_sql(sql, is_thread=True)
                else:
                    real_mincut_id = new_mincut_id[0]

            tools_qt.set_widget_text(self.mincut_class.dlg_mincut, 'result_mincut_id', real_mincut_id)
            use_planified = tools_qt.is_checked(self.mincut_class.dlg_mincut, 'chk_use_planified')

            mincut_result_type = tools_qt.get_combo_value(self.mincut_class.dlg_mincut, self.mincut_class.dlg_mincut.type, 0)

            date_start_predict = self.mincut_class.dlg_mincut.cbx_date_start_predict.date()
            time_start_predict = self.mincut_class.dlg_mincut.cbx_hours_start_predict.time()
            forecast_start_predict = date_start_predict.toString(
                'yyyy-MM-dd') + " " + time_start_predict.toString('HH:mm:ss')

            # Get prediction date - end
            date_end_predict = self.mincut_class.dlg_mincut.cbx_date_end_predict.date()
            time_end_predict = self.mincut_class.dlg_mincut.cbx_hours_end_predict.time()
            forecast_end_predict = date_end_predict.toString('yyyy-MM-dd') + " " + time_end_predict.toString('HH:mm:ss')

            extras = (f'"action":"{self.mincut_action}", "mincutId":"{real_mincut_id}", "arcId":"{self.element_id}", '
                      f'"usePsectors":"{use_planified}", "mincutType":"{mincut_result_type}", '
                      f'"forecastStart":"{forecast_start_predict}", '
                      f'"forecastEnd":"{forecast_end_predict}"')
            self.body = tools_gw.create_body(extras=extras)
            msg = "Task 'Mincut execute' execute procedure '{0}' with parameters: '{1}', '{2}', '{3}'"
            msg_params = ("gw_fct_setmincut", self.body, "using mincut cursor", "is_thread=True",)
            tools_log.log_info(msg, msg_params=msg_params)
            # Use the mincut cursor to execute setmincut so temporal tables are visible
            self.complet_result = self.mincut_class._execute_setmincut_with_cursor(self.body, commit=True)
            if self.isCanceled():
                return False
            if not self.complet_result or self.complet_result['status'] == 'Failed':
                return False

            self.mincut_class._reset_form_has_changes()

            return True

        except KeyError as e:
            self.exception = e
            return False

    def cancel(self):
        """ Cancel task - use mincut cursor connection instead of aux_conn """
        
        # Use mincut cursor connection if available
        if hasattr(self.mincut_class, 'mincut_aux_conn') and self.mincut_class.mincut_aux_conn:
            try:
                pid = self.mincut_class.mincut_aux_conn.get_backend_pid()
                if isinstance(pid, int):
                    result = tools_db.cancel_pid(pid)
                    if result['last_error'] is not None:
                        tools_log.log_warning(result['last_error'])
                    tools_db.dao.rollback(self.mincut_class.mincut_aux_conn)
            except Exception as e:
                msg = "Error canceling mincut task: {0}"
                msg_params = (e,)
                tools_log.log_warning(msg, msg_params=msg_params)
        
        msg = "Task '{0}' was cancelled"
        msg_params = (self.description(),)
        tools_log.log_info(msg, msg_params=msg_params)
        super().cancel()

    def finished(self, result):

        # Call parent finished but skip aux_conn cleanup since we use mincut cursor
        # We need to manually do the cleanup that parent does, except aux_conn deletion
        try:
            lib_vars.session_vars['threads'].remove(self)
        except ValueError:
            pass
        # Don't delete aux_conn - we're using mincut cursor instead
        iface.actionOpenProject().setEnabled(True)
        iface.actionNewProject().setEnabled(True)
        if result:
            msg = "Task '{0}' completed"
            msg_params = (self.description(),)
            tools_log.log_info(msg, msg_params=msg_params)
        else:
            if self.exception is None:
                msg = "Task '{0}' not successful but without exception"
                msg_params = (self.description(),)
                tools_log.log_info(msg, msg_params=msg_params)
            else:
                msg = "Task '{0}' Exception: {1}"
                msg_params = (self.description(), self.exception,)
                tools_log.log_info(msg, msg_params=msg_params)

        # Build SQL and manage json response (body/complet_result already initialized in __init__)
        sql = "SELECT gw_fct_setmincut("
        if self.body:
            sql += f"{self.body}"
        sql += ");"
        msg = "Task 'Mincut execute' manage json response with parameters: '{0}', '{1}', '{2}'"
        msg_params = (self.complet_result, sql, "None",)
        tools_log.log_info(msg, msg_params=msg_params)
        if self.complet_result:
            tools_gw.manage_json_response(self.complet_result, sql, None)

        if self.timer:
            self.timer.stop()
        # If user cancel task
        if self.isCanceled():
            self.task_finished.emit([False, self.complet_result])

        # If sql function return null
        elif self.complet_result is None:
            self.task_finished.emit([False, self.complet_result])
            msg = "Error. Database returned null. Check postgres function '{0}'"
            msg_params = ("gw_fct_setmincut",)
            tools_log.log_warning(msg, msg_params=msg_params)

        # Handle python exception
        elif self.exception is not None:
            msg = (
                "<b>Key: </b>{0}<br>"
                "<b>Key container: </b>body/data/ <br>"
                "<b>Python file: </b>{1} <br>"
                "<b>Python function:</b> {2} <br>"
            )
            msg_params = (self.exception, __name__, self.__class__.__name__)
            title = "Key on returned json from ddbb is missed."
            tools_qt.show_exception_message(title, msg, msg_params=msg_params)
            self.task_finished.emit([False, self.complet_result])

        # Task finished but postgres function failed
        elif self.complet_result.get('status') == 'Failed':
            self.task_finished.emit([False, self.complet_result])
            tools_gw.manage_json_exception(self.complet_result)

        # Task finished with Accepted result
        elif 'mincutOverlap' in self.complet_result or self.complet_result.get('status') == 'Accepted':
            self.task_finished.emit([True, self.complet_result])
