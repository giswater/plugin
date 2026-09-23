"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import json
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
            self._restore_main_search_path()
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
                self._show_rename_success()
            elif not self.isCanceled():
                self._show_rename_failed()
            if self.timer:
                self.timer.stop()
            self.admin.error_count = 0
            self.setProgress(100)
            # After renaming, select the new schema in the combo box of admin_btn, if available.
            # This assumes admin_btn has dlg_readsql and a project_schema_name combo.
            try:
                tools_qt.set_combo_value(self.admin.dlg_readsql.project_schema_name, self.new_schema_name, 0, add_new=False)
            except Exception as exc:
                # Log but do not block rename completion
                msg = "Could not set schema combo after rename: {0}"
                msg_params = (exc,)
                tools_log.log_warning(msg, msg_params=msg_params)
 
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
        # get_aux_conn() inherits the shared search_path. ALTER SCHEMA fails
        # while this session (or the QGIS dao) still has the schema there.
        if not self._exec(conn, "SET search_path TO public"):
            return False
        if not self._exec(conn, "SET ROLE role_system"):
            return False
        if not self._exec(conn, f'ALTER SCHEMA {schema} RENAME TO {new_schema_name}'):
            return False
        if self.isCanceled():
            return False
        # Function bodies keep the old schema name: quoted identifiers,
        # string literals, and unquoted names inside EXECUTE
        # 'SET search_path = oldname, public'. Rewrite them in place.
        if not self._rewrite_function_schema_names(conn, schema, new_schema_name):
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
        ok = tools_db.execute_sql(
            sql, commit=False, is_thread=True, show_exception=False, aux_conn=conn,
        )
        if ok:
            return True
        err = lib_vars.session_vars.get('last_error')
        self.db_exception = (err, sql, None)
        msg = "Rename schema SQL failed"
        tools_log.log_warning(msg, parameter=str(err))
        return False

    def _rewrite_function_schema_names(self, conn, schema, new_schema_name):
        """Replace the old schema name inside function sources after ALTER SCHEMA.

        Covers "name", 'name', name.qual, and the unquoted name in
        EXECUTE 'SET search_path = name, public'.
        """
        sql = f"""
        DO $rename$
        DECLARE
        rec record;
        src text;
        funcdef text;
        BEGIN
        FOR rec IN
            SELECT p.oid
            FROM pg_proc p
            JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname = '{new_schema_name}'
            AND p.prokind IN ('f', 'p')
        LOOP
            src := pg_get_functiondef(rec.oid);
            funcdef := regexp_replace(
            src,
            '(?<![[:alnum:]_]){schema}(?![[:alnum:]_])',
            '{new_schema_name}',
            'g'
            );
            IF funcdef = src THEN
            CONTINUE;
            END IF;
            EXECUTE funcdef;
        END LOOP;
        END
        $rename$;
        """
        return self._exec(conn, sql)

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

    def _show_rename_success(self):
        msg = "Process finished successfully"
        tools_qgis.show_info(msg, parameter="Rename schema")

    def _show_rename_failed(self):
        err = None
        if self.db_exception and self.db_exception[0]:
            err = self.db_exception[0]
        elif self.exception:
            err = self.exception
        if err:
            err_text = str(err)
            if 'being accessed' in err_text.lower():
                msg = (
                    "Rename schema failed: another session is using this schema. "
                    "Close the QGIS project (and any other clients) and try again. {0}"
                )
            else:
                msg = "Rename schema failed: {0}"
            msg_params = (err,)
            tools_qgis.show_warning(msg, msg_params=msg_params)
            return
        msg = "Rename schema failed"
        tools_qgis.show_warning(msg)

    def _restore_main_search_path(self):
        """finished() runs on the main thread; restore or retarget the shared session."""
        if tools_db.dao is None:
            return
        previous = getattr(tools_db.dao, 'set_search_path', None)
        old = str(self.params.get('schema') or '')
        if self.status and previous and old and old in previous:
            tools_db.set_search_path(str(self.new_schema_name))
            return
        if self.status and not previous:
            tools_db.set_search_path(str(self.new_schema_name))
            return
        if previous:
            tools_db.execute_sql(previous, commit=True)

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
