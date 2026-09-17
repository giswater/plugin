"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from qgis.PyQt.QtCore import Qt, pyqtSignal

from .task import GwTask
from ...libs import tools_qt, tools_db
from qgis.PyQt.sip import isdeleted


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

        if hasattr(self.admin, 'dlg_readsql_rename') and not isdeleted(self.admin.dlg_readsql_rename) and self.admin.dlg_readsql_rename.isVisible():
            # Manage buttons & other dlg-related widgets
            self.admin.dlg_readsql_rename.schema_rename_copy.setEnabled(False)                        
            # Disable dlg_readsql_rename buttons
            self.admin.dlg_readsql_rename.btn_accept.hide()
            self.admin.dlg_readsql_rename.btn_cancel.setEnabled(False)
            try:
                self.admin.dlg_readsql_rename.key_escape.disconnect()
            except TypeError:
                pass

            # Disable red 'X' from dlg_readsql_rename
            self.admin.dlg_readsql_rename.setWindowFlag(Qt.WindowType.WindowCloseButtonHint, False)
            self.admin.dlg_readsql_rename.show()

    def run(self):
        super().run()        
        
        schema = self.params.get('schema')
        self.new_schema_name = self.params.get('new_schema_name')

        status = False
        tools_db.execute_sql("SET ROLE role_system", commit=False, is_thread=True)
        try:
            sql = f'ALTER SCHEMA {schema} RENAME TO {self.new_schema_name}'
            status = tools_db.execute_sql(sql, commit=False, is_thread=True)
            if status:
                # Reload fcts
                self.admin._reload_fct_ftrg()
                if self.isCanceled():
                    return True
                # Call fct gw_fct_admin_rename_fixviews
                sql = ('SELECT ' + str(self.new_schema_name) + '.gw_fct_admin_rename_fixviews($${"data":{"currentSchemaName":"'
                       + self.new_schema_name + '","oldSchemaName":"' + str(schema) + '"}}$$)::text')
                tools_db.execute_sql(sql, commit=False, is_thread=True)
                # Execute last_process
                self.admin.execute_last_process(schema_name=self.new_schema_name, locale=True, schema_type=self.admin.project_type)

            # Show message
            status = (self.admin.error_count == 0)
            if status:
                tools_db.dao.commit()
            else:
                tools_db.dao.rollback()
        finally:
            tools_db.execute_sql("RESET ROLE", commit=False, is_thread=True)

        # Reset count error variable to 0
        self.admin.error_count = 0
        self.status = status
        return status

    def finished(self, result):
        super().finished(result)

        if self.isCanceled():
            self.task_finished.emit()

        if hasattr(self.admin, 'dlg_readsql_rename') and not isdeleted(self.admin.dlg_readsql_rename) and self.admin.dlg_readsql_rename.isVisible():
            # Enable dlg_readsql_show_info buttons
            self.admin.dlg_readsql_rename.btn_cancel.setEnabled(True)
            # Enable red 'X' from dlg_readsql_show_info
            self.admin.dlg_readsql_rename.setWindowFlag(Qt.WindowType.WindowCloseButtonHint, True)
            self.admin.dlg_readsql_rename.show()

        if self.status:
            self.admin._refresh_admin_catalog_cache()
            self.admin._populate_data_schema_name(self.admin.cmb_project_type)
            tools_qt.set_widget_text(self.admin.dlg_readsql, self.admin.dlg_readsql.project_schema_name, str(self.new_schema_name))

            # Set info project
            self.admin._set_info_project()
            refresh = getattr(self.admin, '_manage_schemas_refresh', None)
            if refresh:
                refresh()
            if hasattr(self.admin, 'dlg_readsql_rename') and not isdeleted(self.admin.dlg_readsql_rename) and self.admin.dlg_readsql_rename.isVisible():
                self.admin._close_dialog_admin(self.admin.dlg_readsql_rename)

        self.task_finished.emit()

        if self.timer:
            self.timer.stop()

        # Reset count error variable to 0
        self.admin.error_count = 0

        self.setProgress(100)