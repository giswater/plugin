"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import csv
import json
import os
from functools import partial

from qgis.PyQt.QtGui import QStandardItem, QStandardItemModel, QIcon
from qgis.PyQt.QtWidgets import QAction, QMenu, QActionGroup, QWidget, QFileDialog
from qgis.PyQt.QtCore import QPoint
from qgis.core import Qgis
from ..dialog import GwAction
from ...ui.ui_manager import GwCsvUi, EpaExportUi
from ...utils import tools_gw
from ....libs import lib_vars, tools_qt, tools_log, tools_db, tools_qgis, tools_os
from .... import global_vars
from ..epa.epa_tools.import_epanet import GwImportEpanet
from ..epa.epa_tools.import_swmm import GwImportSwmm


class GwFileTransferButton(GwAction):
    """ Button 66: File Transfer """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        super().__init__(icon_path, action_name, text, toolbar, action_group)
        title = "File Transfer"
        self.action.setText(tools_qt.tr(title))

        # First add the menu before adding it to the toolbar
        if toolbar is not None:
            toolbar.removeAction(self.action)

        self.menu = QMenu()
        self.menu.setObjectName("GW_import_export_menu")
        self.menu.setProperty("last_selection", tools_gw.get_config_parser(
            'btn_file_transfer', 'last_selection', 'user', 'session', prefix=False
        ))
        self._fill_import_export_menu()

        self.menu.aboutToShow.connect(self._fill_import_export_menu)

        if toolbar is not None:
            self.action.setMenu(self.menu)
            toolbar.addAction(self.action)

    def clicked_event(self):

        if self.menu.property('last_selection') is not None:
            getattr(self, self.menu.property('last_selection'))()
            return
        if hasattr(self.action, 'associatedObjects'):
            button = QWidget(self.action.associatedObjects()[1])
        elif hasattr(self.action, 'associatedWidgets'):
            button = self.action.associatedWidgets()[1]
        menu_point = button.mapToGlobal(QPoint(0, button.height()))
        self.menu.popup(menu_point)

    # region private functions

    def _fill_import_export_menu(self):
        """ Fill import/export menu with CSV actions """

        # Clear existing menu items
        actions = self.menu.actions()
        for action in actions:
            action.disconnect()
            self.menu.removeAction(action)
            del action
        ag = QActionGroup(self.iface.mainWindow())

        import_menu = self.menu.addMenu(tools_qt.tr("Import"))
        export_menu = self.menu.addMenu(tools_qt.tr("Export"))  # noqa: F841

        # Define menu actions
        menu_actions = [
            # Import section
            (import_menu, ('ud', 'ws'), tools_qt.tr('Import CSV'), QIcon(f"{lib_vars.plugin_dir}{os.sep}icons{os.sep}toolbars{os.sep}utilities{os.sep}66_1.png")),
            (import_menu, ('ud', 'ws'), tools_qt.tr('Import INP file'), QIcon(f"{lib_vars.plugin_dir}{os.sep}icons{os.sep}toolbars{os.sep}epa{os.sep}22.png")),
            (export_menu, ('ws'), tools_qt.tr('Export EPA result families'), None)
        ]
        # Add actions to menu
        for menu, types, action, icon in menu_actions:
            if global_vars.project_type in types:
                if icon:
                    obj_action = QAction(icon, f"{action}", ag)
                else:
                    obj_action = QAction(f"{action}", ag)
                menu.addAction(obj_action)
                obj_action.triggered.connect(partial(self._get_selected_action, action))

        # Remove menu if it is empty
        # for menu in self.menu.findChildren(QMenu):
        #     if not len(menu.actions()):
        #         menu.menuAction().setParent(None)

    def _get_selected_action(self, name):
        """ Gets selected action """

        if name == tools_qt.tr('Import CSV'):
            self._save_last_selection(self.menu, '_open_csv')
            self._open_csv()
        elif name == tools_qt.tr('Import INP file'):
            self._save_last_selection(self.menu, '_open_import_inp')
            if global_vars.project_type == 'ws':
                import_inp = GwImportEpanet()
                import_inp.clicked_event()
                return
            if global_vars.project_type == 'ud':
                import_inp = GwImportSwmm()
                import_inp.clicked_event()
                return
        elif name == tools_qt.tr('Export EPA result families'):
            self._save_last_selection(self.menu, '_export_epa_result_families')
            self._export_epa_result_families()

    def _save_last_selection(self, menu, button_function):
        menu.setProperty("last_selection", button_function)
        tools_gw.set_config_parser('btn_file_transfer', 'last_selection', button_function, prefix=False)

    def _open_import_inp(self):
        if global_vars.project_type == 'ws':
            import_inp = GwImportEpanet()
            import_inp.clicked_event()
            return
        if global_vars.project_type == 'ud':
            import_inp = GwImportSwmm()
            import_inp.clicked_event()

    def save_settings_values(self):
        """ Save QGIS settings related with csv options """

        tools_gw.set_config_parser('btn_csv2pg', 'cmb_import_type',
                                   f"{tools_qt.get_combo_value(self.dlg_csv, 'cmb_import_type', 0)}")
        tools_gw.set_config_parser('btn_csv2pg', 'txt_import', tools_qt.get_text(self.dlg_csv, 'txt_import'))
        tools_gw.set_config_parser('btn_csv2pg', 'txt_file_csv', tools_qt.get_text(self.dlg_csv, 'txt_file_csv'))
        tools_gw.set_config_parser('btn_csv2pg', 'cmb_unicode_list', tools_qt.get_text(self.dlg_csv, 'cmb_unicode_list'))
        tools_gw.set_config_parser('btn_csv2pg', 'chk_ignore_header', f"{self.dlg_csv.chk_ignore_header.isChecked()}")
        tools_gw.set_config_parser('btn_csv2pg', 'rb_semicolon', f"{self.dlg_csv.rb_semicolon.isChecked()}")
        tools_gw.set_config_parser('btn_csv2pg', 'rb_space', f"{self.dlg_csv.rb_space.isChecked()}")
        tools_gw.set_config_parser('btn_csv2pg', 'rb_dec_comma', f"{self.dlg_csv.rb_dec_comma.isChecked()}")
        tools_gw.set_config_parser('btn_csv2pg', 'rb_dec_period', f"{self.dlg_csv.rb_dec_period.isChecked()}")

    # region private functions

    def _export_epa_result_families(self):
        # Use dialog from ui_manager as for other dialogs (mimicking approach from _open_csv)
        dlg_epa = EpaExportUi(self)
        tools_gw.load_settings(dlg_epa)

        # Fill combo from db
        sql = "SELECT result_id FROM rpt_cat_result ORDER BY exec_date DESC"
        results = tools_db.get_rows(sql)
        dlg_epa.cmb_result_id.clear()
        if results:
            for row in results:
                result_id = row[0] if isinstance(row, (tuple, list)) else row
                dlg_epa.cmb_result_id.addItem(str(result_id))
        else:
            # No EPA results found, show message and close dialog
            msg = "No EPA results found. You must first simulate with Go2Epa."
            tools_qgis.show_warning(msg)
            tools_gw.close_dialog(dlg_epa)
            return

        self._load_export_epa_settings(dlg_epa)

        # Connect browse signal
        dlg_epa.btn_browse.clicked.connect(
            lambda: self._browse_export_path_epa(dlg_epa)
        )

        dlg_epa.btn_cancel.clicked.connect(lambda: tools_gw.close_dialog(dlg_epa))
        dlg_epa.rejected.connect(lambda: tools_gw.close_dialog(dlg_epa))
        dlg_epa.btn_accept.clicked.connect(partial(self._do_export_epa_families, dlg_epa))

        tools_gw.open_dialog(dlg_epa, dlg_name='epa_result_export')

    def _browse_export_path_epa(self, dlg):
        file_path, _ = QFileDialog.getSaveFileName(
            dlg,
            tools_qt.tr("Select Export File"),
            "",
            tools_qt.tr("JSON Files (*.json);;All Files (*)")
        )
        if file_path:
            if not file_path.lower().endswith('.json'):
                file_path += ".json"
            dlg.edit_path.setText(file_path)
            self._save_export_epa_settings(dlg)

    def _do_export_epa_families(self, dlg):
        result_id = dlg.cmb_result_id.currentText()
        file_path = dlg.edit_path.text().strip()
        
        if not result_id or not file_path:
            msg = "Please select a result and an export path."
            tools_qgis.show_warning(msg, dialog=dlg)
            return
        tools_gw.close_dialog(dlg)

        sql = f"SELECT gw_fct_get_epa_result_families('{result_id}')"
        row = tools_db.get_row(sql)
        if not row or not row[0]:
            msg = "No results returned from the database."
            tools_qgis.show_warning(msg)
            return

        json_result = row[0]
        # Parse JSON if it's a string
        if isinstance(json_result, str):
            try:
                json_result = json.loads(json_result)
            except json.JSONDecodeError:
                msg = "Failed to parse JSON result from database."
                tools_qgis.show_warning(msg)
                return
        
        # Extract only the features array from body.data.features
        if isinstance(json_result, dict):
            body = json_result.get('body', {})
            if isinstance(body, dict):
                data = body.get('data', {})
        # Write only the features array to the file
        try:
            indent = 2 if dlg.chk_format_json.isChecked() else None
            with open(file_path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=indent)
            msg = "EPA Result Families exported successfully:\n{0}"
            msg_params = (file_path,)
            tools_qgis.show_info(msg, msg_params=msg_params)
            self._save_export_epa_settings(dlg)
        except Exception as e:
            msg = "Failed to write export file:\n{0}"
            msg_params = (str(e),)
            tools_qgis.show_warning(msg, msg_params=msg_params)

    def _load_export_epa_settings(self, dlg):
        result_id = tools_gw.get_config_parser('btn_export_epa_families', 'result_id', 'user', 'session', False)
        export_path = tools_gw.get_config_parser('btn_export_epa_families', 'export_path', 'user', 'session', False)
        json_format = tools_gw.get_config_parser('btn_export_epa_families', 'json_format', 'user', 'session', False)

        if result_id:
            tools_qt.set_combo_value(dlg.cmb_result_id, result_id, 0, add_new=False)
        if export_path:
            dlg.edit_path.setText(export_path)
        if json_format is not None:
            dlg.chk_format_json.setChecked(tools_os.set_boolean(json_format))

    def _save_export_epa_settings(self, dlg):
        tools_gw.set_config_parser(
            'btn_export_epa_families', 'result_id', dlg.cmb_result_id.currentText(), prefix=False
        )
        tools_gw.set_config_parser(
            'btn_export_epa_families', 'export_path', dlg.edit_path.text().strip(), prefix=False
        )
        tools_gw.set_config_parser(
            'btn_export_epa_families', 'json_format', f'{dlg.chk_format_json.isChecked()}', prefix=False
        )

    def _open_csv(self):

        self.func_name = None
        self.dlg_csv = GwCsvUi(self)
        tools_gw.load_settings(self.dlg_csv)

        temp_tablename = 'temp_csv'
        tools_qt.fill_combo_unicodes(self.dlg_csv.cmb_unicode_list)
        csv_table = "v_config_csv"
        if not tools_gw._relation_exists(lib_vars.schema_name, csv_table):
            csv_table = "config_csv"
        self._populate_combos(self.dlg_csv.cmb_import_type, 'fid',
                             f'alias, {csv_table}.descript, functionname, orderby', csv_table)

        self.dlg_csv.lbl_info.setWordWrap(True)
        tools_qt.set_widget_text(self.dlg_csv, self.dlg_csv.cmb_unicode_list, 'utf8')
        self.dlg_csv.rb_comma.setChecked(False)
        self.dlg_csv.rb_semicolon.setChecked(True)
        self.dlg_csv.rb_space.setChecked(False)

        # Signals
        self.dlg_csv.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_csv))
        self.dlg_csv.rejected.connect(partial(tools_gw.close_dialog, self.dlg_csv))
        self.dlg_csv.btn_accept.clicked.connect(partial(self._write_csv, self.dlg_csv, temp_tablename))
        self.dlg_csv.cmb_import_type.currentIndexChanged.connect(partial(self._update_info, self.dlg_csv))
        self.dlg_csv.cmb_import_type.currentIndexChanged.connect(partial(self._get_function_name))
        self.dlg_csv.btn_file_csv.clicked.connect(partial(self._select_file_csv))
        self.dlg_csv.cmb_unicode_list.currentIndexChanged.connect(partial(self._preview_csv, self.dlg_csv))
        self.dlg_csv.chk_ignore_header.clicked.connect(partial(self._preview_csv, self.dlg_csv))
        self.dlg_csv.rb_comma.clicked.connect(partial(self._preview_csv, self.dlg_csv))
        self.dlg_csv.rb_semicolon.clicked.connect(partial(self._preview_csv, self.dlg_csv))
        self.dlg_csv.rb_space.clicked.connect(partial(self._preview_csv, self.dlg_csv))
        self._get_function_name()
        self._load_settings_values()

        if str(tools_qt.get_text(self.dlg_csv, self.dlg_csv.txt_file_csv)) != 'null':
            self._preview_csv(self.dlg_csv)
        self.dlg_csv.line.setVisible(False)
        self.dlg_csv.progressBar.setVisible(False)

        # Disable tab log
        tools_gw.disable_tab_log(self.dlg_csv)

        # Open dialog
        tools_gw.open_dialog(self.dlg_csv, dlg_name='csv')

        # Finally set label info
        self._update_info(self.dlg_csv)

    def _populate_combos(self, combo, field_id, fields, table_name):

        # Get role
        roles_dict = {"role_basic": "'role_basic'",
                      "role_om": "'role_basic', 'role_om'",
                      "role_edit": "'role_basic', 'role_om', 'role_edit'",
                      "role_epa": "'role_basic', 'role_om', 'role_edit', 'role_epa'",
                      "role_plan": "'role_basic', 'role_om', 'role_edit', 'role_epa', 'role_plan'",
                      "role_admin": "'role_basic', 'role_om', 'role_edit', 'role_epa', 'role_plan', 'role_admin'",
                      "role_system": "'role_basic', 'role_om', 'role_edit', 'role_epa', 'role_plan', 'role_admin', 'role_system'"}

        sql = (f"SELECT DISTINCT({field_id}), {fields}"
               f" FROM {table_name}"
               f" JOIN sys_function ON function_name =  functionname"
               f" WHERE sys_role IN ({roles_dict[lib_vars.project_vars['project_role']]}) AND active is True ORDER BY orderby")

        rows = tools_db.get_rows(sql)
        if not rows:
            message = "You do not have permission to execute this application"
            self.dlg_csv.lbl_info.setText(tools_qt.tr(message))
            self.dlg_csv.lbl_info.setStyleSheet("QLabel{color: red;}")

            self.dlg_csv.cmb_import_type.setEnabled(False)
            self.dlg_csv.txt_import.setEnabled(False)
            self.dlg_csv.txt_file_csv.setEnabled(False)
            self.dlg_csv.cmb_unicode_list.setEnabled(False)
            self.dlg_csv.rb_comma.setEnabled(False)
            self.dlg_csv.rb_semicolon.setEnabled(False)
            self.dlg_csv.rb_space.setEnabled(False)
            self.dlg_csv.btn_file_csv.setEnabled(False)
            self.dlg_csv.tbl_csv.setEnabled(False)
            self.dlg_csv.btn_accept.setEnabled(False)
        else:
            tools_qt.fill_combo_values(combo, rows, True, True, 1)
            self._update_info(self.dlg_csv)

    def _write_csv(self, dialog, temp_tablename):
        """ Write csv in postgres and call gw_fct_utils_csv2pg function """

        self.save_settings_values()
        insert_status = True
        if not self._validate_params(dialog):
            return

        fid_aux = tools_qt.get_combo_value(dialog, dialog.cmb_import_type, 0)
        self._delete_table_csv(temp_tablename, fid_aux)
        path = tools_qt.get_text(dialog, dialog.txt_file_csv)
        label_aux = tools_qt.get_text(dialog, dialog.txt_import, return_string_null=False)
        delimiter = self._get_delimiter(dialog)
        _unicode = tools_qt.get_text(dialog, dialog.cmb_unicode_list)

        try:
            with open(path, 'r', encoding=_unicode) as csvfile:
                insert_status = self._insert_into_db(dialog, csvfile, delimiter, _unicode)
                csvfile.close()
                del csvfile
        except Exception as e:
            msg = "EXCEPTION"
            param = str(e)
            tools_qgis.show_warning(msg, dialog=dialog, parameter=param)

        if insert_status is False:
            return

        extras = f'"importParam":"{label_aux}"'
        extras += f', "fid":"{fid_aux}"'
        body = tools_gw.create_body(extras=extras)

        result = tools_gw.execute_procedure(self.func_name, body)
        if not result:
            return
        else:
            if result['status'] == "Accepted":
                tools_gw.fill_tab_log(dialog, result['body']['data'], close=False)
                self.dlg_csv.btn_cancel.setText(tools_qt.tr("Close"))
            message = result.get('message')
            if message:
                msg = message.get('text')
                tools_qt.show_info_box(msg)

    def _update_info(self, dialog):
        """ Update the tag according to item selected from cmb_import_type """
        try:
            dialog.lbl_info.setText(tools_qt.get_combo_value(self.dlg_csv, self.dlg_csv.cmb_import_type, 2))
        except Exception as e:
            tools_log.log_warning(str(e))

    def _get_function_name(self):

        try:
            self.func_name = tools_qt.get_combo_value(self.dlg_csv, self.dlg_csv.cmb_import_type, 3)
            tools_log.log_info(str(self.func_name))
        except Exception as e:
            tools_log.log_warning(str(e))

    def _select_file_csv(self):
        """ Select CSV file """

        tools_qt.get_open_file_path(self.dlg_csv, 'txt_file_csv', '*.csv', "Select CSV file")
        self.save_settings_values()
        self._preview_csv(self.dlg_csv)

    def _preview_csv(self, dialog):
        """ Show current file in QTableView acorrding to selected delimiter and unicode """

        path = self._get_path(dialog)
        if path is None:
            return

        delimiter = self._get_delimiter(dialog)
        model = QStandardItemModel()
        _unicode = tools_qt.get_text(dialog, dialog.cmb_unicode_list)
        _ignoreheader = dialog.chk_ignore_header.isChecked()
        dialog.tbl_csv.setModel(model)
        dialog.tbl_csv.horizontalHeader().setStretchLastSection(True)

        try:
            with open(path, "r", encoding=_unicode) as file_input:
                self._read_csv_file(model, file_input, delimiter, _unicode, _ignoreheader)
        except Exception as e:
            tools_qgis.show_warning(str(e), dialog=dialog)

    def _load_settings_values(self):
        """ Load QGIS settings related with csv options """

        value = tools_gw.get_config_parser('btn_csv2pg', 'cmb_import_type', "user", "session")
        tools_qt.set_combo_value(self.dlg_csv.cmb_import_type, value, 0, add_new=False)

        value = tools_gw.get_config_parser('btn_csv2pg', 'txt_import', "user", "session")
        tools_qt.set_widget_text(self.dlg_csv, self.dlg_csv.txt_import, value)

        value = tools_gw.get_config_parser('btn_csv2pg', 'txt_file_csv', "user", "session")
        tools_qt.set_widget_text(self.dlg_csv, self.dlg_csv.txt_file_csv, value)

        unicode = tools_gw.get_config_parser('btn_csv2pg', 'cmb_unicode_list', "user", "session")
        if not unicode:
            unicode = 'latin1'
        tools_qt.set_widget_text(self.dlg_csv, self.dlg_csv.cmb_unicode_list, unicode)

        if tools_gw.get_config_parser('btn_csv2pg', 'chk_ignore_header', "user", "session") == 'True':
            self.dlg_csv.chk_ignore_header.setChecked(True)

        if tools_gw.get_config_parser('btn_csv2pg', 'rb_semicolon', "user", "session") == 'True':
            self.dlg_csv.rb_semicolon.setChecked(True)
        elif tools_gw.get_config_parser('btn_csv2pg', 'rb_space', "user", "session") == 'True':
            self.dlg_csv.rb_space.setChecked(True)
        else:
            self.dlg_csv.rb_comma.setChecked(True)

        if tools_gw.get_config_parser('btn_csv2pg', 'rb_dec_comma', "user", "session") == 'True':
            self.dlg_csv.rb_dec_comma.setChecked(True)
        elif tools_gw.get_config_parser('btn_csv2pg', 'rb_dec_period', "user", "session") == 'True':
            self.dlg_csv.rb_dec_period.setChecked(True)

    def _validate_params(self, dialog):
        """ Validate if params are valids """

        path = self._get_path(dialog)
        self._preview_csv(dialog)
        if path is None or path == 'null':
            return False
        return True

    def _delete_table_csv(self, temp_tablename, fid_aux):
        """ Delete records from temp_csv for current user and selected cat """

        sql = (f"DELETE FROM {temp_tablename} "
               f"WHERE fid = '{fid_aux}' AND cur_user = current_user")
        tools_db.execute_sql(sql)

    def _get_delimiter(self, dialog):

        delimiter = ';'
        if dialog.rb_semicolon.isChecked():
            delimiter = ';'
        elif dialog.rb_comma.isChecked():
            delimiter = ','
        elif dialog.rb_space.isChecked():
            delimiter = ' '
        return delimiter

    def _insert_into_db(self, dialog, csvfile, delimiter, _unicode):

        progress = 0
        dialog.line.setVisible(True)
        dialog.progressBar.setVisible(True)
        dialog.progressBar.setValue(int(progress))
        # Counts rows in csvfile, using var "row_count" to do progressbar
        # noinspection PyUnusedLocal
        row_count = sum(1 for rows in csvfile)
        if row_count > 20:
            row_count -= 20  # -20 for see 100% complete progress
        dialog.progressBar.setMaximum(100)
        csvfile.seek(0)  # Position the cursor at position 0 of the file
        reader = csv.reader(csvfile, delimiter=delimiter,)
        fid_aux = tools_qt.get_combo_value(dialog, dialog.cmb_import_type, 0)
        ignoreheader = dialog.chk_ignore_header.isChecked()
        fields = []
        cont = 1
        for row in reader:
            field = {'fid': fid_aux}
            if tools_os.set_boolean(ignoreheader) is True:
                ignoreheader = False
                continue

            for x in range(0, len(row)):
                value = row[x].strip().replace("\n", "")
                field[f"csv{x + 1}"] = f"{value}" if value else None
            fields.append(field)
            cont += 1
            progress = (100 * cont) / row_count
            dialog.progressBar.setValue(int(progress))
        dialog.progressBar.setValue(100)
        if not fields:
            return False

        decimal_sep = "null"
        if dialog.rb_dec_comma.isChecked():
            decimal_sep = '","'
        elif dialog.rb_dec_period.isChecked():
            decimal_sep = '"."'

        values = f'"separator": {decimal_sep}, "values":{(json.dumps(fields, ensure_ascii=False).encode(_unicode)).decode()}'
        body = tools_gw.create_body(extras=values)
        result = tools_gw.execute_procedure('gw_fct_setcsv', body)

        if result and result.get('status') == 'Accepted':
            return True

        return False

    def _get_path(self, dialog):
        """ Take the file path if exist. AND if not exit ask it """

        path = tools_qt.get_text(dialog, dialog.txt_file_csv)
        if path is None or path == 'null' or not os.path.exists(path):
            msg = "Please choose a valid path"
            tools_qgis.show_message(msg, message_level=Qgis.MessageLevel.Info, dialog=dialog)
            return None
        if path.find('.csv') == -1:
            msg = "Please choose a csv file"
            tools_qgis.show_message(msg, message_level=Qgis.MessageLevel.Info, dialog=dialog)
            return None

        return path

    def _read_csv_file(self, model, file_input, delimiter, _unicode, _ignoreheader):

        rows = csv.reader(file_input, delimiter=delimiter)
        for row in rows:
            if tools_os.set_boolean(_ignoreheader) is True:
                _ignoreheader = False
                continue
            unicode_row = [x for x in row]
            items = [QStandardItem(field) for field in unicode_row]
            model.appendRow(items)

    def _get_rolenames(self):
        """ Get list of rolenames of current user """

        sql = ("SELECT rolname FROM pg_roles "
               " WHERE pg_has_role(current_user, oid, 'member')")
        rows = tools_db.get_rows(sql)
        if not rows:
            return None

        roles = "("
        for i in range(0, len(rows)):
            roles += "'" + str(rows[i][0]) + "', "
        roles = roles[:-2]
        roles += ")"

        return roles

    # endregion