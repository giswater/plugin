"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import json
import os
import re

from qgis.PyQt.QtCore import Qt, pyqtSignal
from qgis.PyQt.sip import isdeleted

from .task import GwTask
from ...libs import lib_vars, tools_db, tools_log, tools_qgis, tools_qt

_SCHEMA_NAME_RE = re.compile(r'^[a-z0-9_]+$')


class GwRenameSchemaTask(GwTask):

    task_finished = pyqtSignal()

    def __init__(self, admin, description, params, timer=None):
        super().__init__(description)
        self.admin = admin
        self.params = params
        self.dict_folders_process = {}
        self.db_exception = (None, None, None)  # error, sql, filepath
        self.status = False
        self.timer = timer

        dlg = self._rename_dialog()
        if dlg is None:
            return

        # Manage buttons & other dlg-related widgets
        dlg.schema_rename_copy.setEnabled(False)
        # Disable dlg_readsql_rename buttons
        dlg.btn_accept.hide()
        dlg.btn_cancel.setEnabled(False)
        try:
            dlg.key_escape.disconnect()
        except TypeError:
            pass

        # Disable red 'X' from dlg_readsql_rename
        dlg.setWindowFlag(Qt.WindowType.WindowCloseButtonHint, False)
        dlg.show()

    def run(self):
        super().run()

        schema = self.params.get('schema')
        self.new_schema_name = self.params.get('new_schema_name')
        status = False
        try:
            status = self._rename_on_aux_conn(schema, self.new_schema_name)
        except Exception as exc:
            self.exception = exc
            msg = "Rename schema exception: {0}"
            msg_params = (exc,)
            tools_log.log_warning(msg, msg_params=msg_params)
            status = False
        finally:
            if not status:
                self._rollback_aux()
        self.status = status
        return status

    def finished(self, result):
        super().finished(result)

        try:
            if self.status:
                self._refresh_after_rename()
        except Exception as exc:
            msg = "Rename schema refresh failed: {0}"
            msg_params = (exc,)
            tools_log.log_warning(msg, msg_params=msg_params)
        finally:
            self._restore_rename_dialog()
            if self.status:
                self._close_rename_dialog()
            elif not self.isCanceled():
                msg = "Rename schema failed"
                tools_qgis.show_warning(msg)
            if self.timer:
                self.timer.stop()
            self.admin.error_count = 0
            self.setProgress(100)
            self.task_finished.emit()

    def _rename_on_aux_conn(self, schema, new_schema_name):
        """ALTER + fixviews + lastprocess on the worker connection. One commit."""
        if self.aux_conn is None or tools_db.dao is None:
            msg = "Rename schema has no worker connection"
            tools_log.log_warning(msg)
            return False
        if not _SCHEMA_NAME_RE.match(str(schema or '')) or not _SCHEMA_NAME_RE.match(str(new_schema_name or '')):
            msg = "Rename schema rejected invalid schema name"
            tools_log.log_warning(msg, parameter=f"{schema} -> {new_schema_name}")
            return False

        conn = self.aux_conn
        if not self._exec(conn, "SET ROLE role_system"):
            return False
        if not self._exec(conn, f'ALTER SCHEMA {schema} RENAME TO {new_schema_name}'):
            return False
        if self.isCanceled():
            return False
        # Function bodies keep SET search_path = "<old name>". Recreate them in
        # this transaction (base/fct, not the legacy common/fct tree) before
        # fixviews and lastprocess. Do not call _reload_fct_ftrg: it commits
        # the shared connection and opens a dialog from this worker.
        if self._is_network_schema() and not self._reload_base_functions(conn, new_schema_name):
            return False
        if self.isCanceled():
            return False
        if self._is_network_schema():
            if not self._exec(conn, self._fixviews_sql(schema, new_schema_name)):
                return False
            if self.isCanceled():
                return False
            if not self._exec(conn, self._lastprocess_sql(new_schema_name)):
                return False
        if not self._exec(conn, "RESET ROLE"):
            return False
        tools_db.dao.commit(aux_conn=conn)
        return True

    def _is_network_schema(self):
        return str(self.params.get('project_type') or '').lower() in ('ws', 'ud')

    def _exec(self, conn, sql):
        return tools_db.execute_sql(
            sql, commit=False, is_thread=True, show_exception=False, aux_conn=conn,
        )

    def _reload_base_functions(self, conn, new_schema_name):
        sql_dir = getattr(self.admin, 'sql_dir', '') or ''
        project_type = str(self.params.get('project_type') or '').lower()
        epsg = str(self.params.get('project_epsg') or '25831')
        folders = [
            os.path.join(sql_dir, 'schemas', 'main', 'common', 'base', 'fct'),
            os.path.join(sql_dir, 'schemas', 'main', 'common', 'base', 'ftrg'),
            os.path.join(sql_dir, 'schemas', 'main', project_type, 'base', 'fct'),
            os.path.join(sql_dir, 'schemas', 'main', project_type, 'base', 'ftrg'),
        ]
        for folder in folders:
            if not os.path.isdir(folder):
                msg = "Rename schema folder not found"
                tools_log.log_warning(msg, parameter=folder)
                return False
            for name in sorted(os.listdir(folder)):
                if not name.endswith('.sql') or name.startswith('.'):
                    continue
                path = os.path.join(folder, name)
                with open(path, 'r', encoding='utf8') as handle:
                    sql = handle.read().replace('SCHEMA_NAME', new_schema_name).replace('SRID_VALUE', epsg)
                if not self._exec(conn, sql):
                    self.db_exception = (lib_vars.session_vars.get('last_error'), sql, path)
                    msg = "Rename schema failed reloading {0}"
                    msg_params = (path,)
                    tools_log.log_warning(msg, msg_params=msg_params)
                    return False
                if self.isCanceled():
                    return False
        return True

    def _fixviews_sql(self, schema, new_schema_name):
        payload = json.dumps({
            "data": {
                "currentSchemaName": new_schema_name,
                "oldSchemaName": schema,
            }
        })
        return f"SELECT {new_schema_name}.gw_fct_admin_rename_fixviews($${payload}$$)"

    def _lastprocess_sql(self, new_schema_name):
        project_type = str(self.params.get('project_type') or '').upper()
        gw_version = str(self.params.get('project_version') or '')
        epsg = str(self.params.get('project_epsg') or '25831')
        locale = str(self.params.get('locale') or 'en_US')
        payload = json.dumps({
            "client": {"device": 4, "lang": locale},
            "data": {
                "isNewProject": "FALSE",
                "gwVersion": gw_version,
                "projectType": project_type,
                "epsg": epsg,
            },
        })
        return f"SELECT {new_schema_name}.gw_fct_admin_schema_lastprocess($${payload}$$)"

    def _rollback_aux(self):
        if self.aux_conn is None or tools_db.dao is None:
            return
        tools_db.dao.rollback(aux_conn=self.aux_conn)

    def _refresh_after_rename(self):
        self.admin._refresh_admin_catalog_cache()
        self.admin._populate_data_schema_name()
        dlg = getattr(self.admin, 'dlg_readsql', None)
        if dlg is not None and not isdeleted(dlg):
            tools_qt.set_widget_text(dlg, dlg.project_schema_name, str(self.new_schema_name))
        self.admin._set_info_project()
        refresh = getattr(self.admin, '_manage_schemas_refresh', None)
        if refresh:
            refresh()

    def _rename_dialog(self):
        dlg = getattr(self.admin, 'dlg_readsql_rename', None)
        if dlg is None:
            return None
        try:
            if isdeleted(dlg) or not dlg.isVisible():
                return None
        except RuntimeError:
            return None
        return dlg

    def _restore_rename_dialog(self):
        dlg = self._rename_dialog()
        if dlg is None:
            return
        dlg.schema_rename_copy.setEnabled(True)
        dlg.btn_accept.show()
        dlg.btn_cancel.setEnabled(True)
        dlg.setWindowFlag(Qt.WindowType.WindowCloseButtonHint, True)
        dlg.show()

    def _close_rename_dialog(self):
        dlg = self._rename_dialog()
        if dlg is None:
            return
        self.admin._close_dialog_admin(dlg)
