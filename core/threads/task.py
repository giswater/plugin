"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from qgis.PyQt.QtCore import pyqtSignal, QObject
from qgis.core import QgsTask
from qgis.utils import iface

from ...libs import lib_vars, tools_log, tools_db


class GwTask(QgsTask, QObject):
    """ This shows how to subclass QgsTask """

    fake_progress = pyqtSignal()

    def __init__(self, description, duration=0):

        QObject.__init__(self)
        super().__init__(description, QgsTask.Flag.CanCancel)
        self.exception = None
        self.duration = duration
        self.aux_conn = None
        self.use_aux_conn = True
        # Must not touch iface/QActions in run() — QgsTask runs on a worker thread;
        # on macOS, QAction.setEnabled from a worker triggers AppKit asserts via QMenu/Cocoa.
        iface.actionOpenProject().setEnabled(False)
        iface.actionNewProject().setEnabled(False)

    def run(self) -> bool:

        lib_vars.session_vars['threads'].append(self)

        if self.use_aux_conn:
            self.aux_conn = tools_db.dao.get_aux_conn()

        msg = "Started task {0}"
        msg_params = (self.description(),)
        tools_log.log_info(msg, msg_params=msg_params)
        return True

    def finished(self, result):

        try:
            lib_vars.session_vars['threads'].remove(self)
        except ValueError:
            pass
        tools_db.dao.delete_aux_con(self.aux_conn)
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

    def cancel(self):

        if self.aux_conn is None:
            msg = "Task '{0}' was cancelled"
            msg_params = (self.description(),)
            tools_log.log_info(msg, msg_params=msg_params)
            super().cancel()
            return
        pid = self.aux_conn.get_backend_pid()
        if isinstance(pid, int):
            result = tools_db.cancel_pid(pid)
            if result['last_error'] is not None:
                tools_log.log_warning(result['last_error'])
            tools_db.dao.rollback(self.aux_conn)
        msg = "Task '{0}' was cancelled"
        msg_params = (self.description(),)
        tools_log.log_info(msg, msg_params=msg_params)
        super().cancel()