"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import json

from functools import partial

from qgis.PyQt.QtCore import Qt, QDate, QRegularExpression
from qgis.PyQt.QtWidgets import QAbstractItemView, QTableView, QDialog, QAction, QMenu, QPushButton, QHeaderView
from qgis.PyQt.QtGui import QRegularExpressionValidator, QStandardItemModel, QCursor

from ..dialog import GwAction
from ...ui.ui_manager import GwEpaManagerUi
from ...utils import tools_gw
from ....libs import tools_qt, tools_db, tools_qgis, tools_os, lib_vars
from ....libs.tools_qt import GwEditDialog


class GwGo2EpaManagerButton(GwAction):
    """ Button 43: Go2epa maanger """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        super().__init__(icon_path, action_name, text, toolbar, action_group)

    def clicked_event(self):

        self._manage_go2epa()

    # region private functions

    def _manage_go2epa(self):

        # Create the dialog
        self.dlg_manager = GwEpaManagerUi(self)
        tools_gw.load_settings(self.dlg_manager)

        # Manage widgets
        reg_exp = QRegularExpression(r"^[A-Za-z0-9_]{1,16}$")
        self.dlg_manager.txt_result_id.setValidator(QRegularExpressionValidator(reg_exp))
        self.dlg_manager.tab_log_txt_infolog.setReadOnly(True)
        self.dlg_manager.btn_toggle_corporate.setEnabled(False)
        self.dlg_manager.btn_archive.setEnabled(False)

        # Populate filter widgets
        self._populate_filters()

        # Fill table view
        self.dlg_manager.tbl_rpt_cat_result.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self._fill_manager_table()

        # Populate custom context menu
        self.dlg_manager.tbl_rpt_cat_result.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.dlg_manager.tbl_rpt_cat_result.customContextMenuRequested.connect(partial(self._show_context_menu, self.dlg_manager.tbl_rpt_cat_result))

        # Set signals
        self.dlg_manager.btn_edit.clicked.connect(partial(self._manage_edit_row, self.dlg_manager, self.dlg_manager.tbl_rpt_cat_result))
        self.dlg_manager.btn_show_inp_data.clicked.connect(partial(self._show_inp_data, self.dlg_manager, self.dlg_manager.tbl_rpt_cat_result))
        self.dlg_manager.btn_archive.clicked.connect(partial(self._toggle_rpt_archived, self.dlg_manager.tbl_rpt_cat_result,
                                                              'result_id'))
        self.dlg_manager.btn_toggle_corporate.clicked.connect(partial(self._epa2data, self.dlg_manager.tbl_rpt_cat_result,
                                                              'result_id'))
        self.dlg_manager.btn_delete.clicked.connect(partial(self._multi_rows_delete, self.dlg_manager.tbl_rpt_cat_result,
                                                            'v_ui_rpt_cat_result', 'result_id'))
        selection_model = self.dlg_manager.tbl_rpt_cat_result.selectionModel()
        selection_model.selectionChanged.connect(partial(self._fill_txt_infolog))
        selection_model.selectionChanged.connect(partial(self._enable_buttons))
        self.dlg_manager.btn_close.clicked.connect(partial(tools_gw.close_dialog, self.dlg_manager))
        self.dlg_manager.rejected.connect(partial(tools_gw.close_dialog, self.dlg_manager))
        self.dlg_manager.txt_result_id.textChanged.connect(partial(self._fill_manager_table))
        self.dlg_manager.cmb_status.currentIndexChanged.connect(partial(self._fill_manager_table))
        self.dlg_manager.cmb_network_type.currentIndexChanged.connect(partial(self._fill_manager_table))
        self.dlg_manager.cmb_expl.currentIndexChanged.connect(partial(self._fill_manager_table))
        self.dlg_manager.date_exec_from.dateChanged.connect(partial(self._fill_manager_table))
        self.dlg_manager.chk_corporate.stateChanged.connect(partial(self._fill_manager_table))
        self.dlg_manager.chk_archived.stateChanged.connect(partial(self._fill_manager_table))

        # Open form
        tools_gw.open_dialog(self.dlg_manager, dlg_name='go2epa_manager')

    def _populate_filters(self):
        """ Populate filter combo boxes and initialize exec date from. """

        rows = tools_db.get_rows(
            "SELECT id, idval FROM inp_typevalue WHERE typevalue = 'inp_result_status' ORDER BY id"
        )
        tools_qt.fill_combo_values(self.dlg_manager.cmb_status, rows, add_empty=True)

        rows = tools_db.get_rows(
            "SELECT id, idval FROM inp_typevalue WHERE typevalue = 'inp_options_networkmode' ORDER BY id"
        )
        tools_qt.fill_combo_values(self.dlg_manager.cmb_network_type, rows, add_empty=True)

        rows = tools_db.get_rows(
            "SELECT expl_id, name FROM ve_exploitation WHERE expl_id > 0 ORDER BY name"
        )
        tools_qt.fill_combo_values(self.dlg_manager.cmb_expl, rows, add_empty=True)
        tools_qt.set_autocompleter(self.dlg_manager.cmb_expl)

        row = tools_db.get_row("SELECT MIN(exec_date)::date FROM v_ui_rpt_cat_result")
        min_date = row[0] if row and row[0] else QDate.currentDate()
        self.dlg_manager.date_exec_from.setCalendarPopup(True)
        self.dlg_manager.date_exec_from.setDisplayFormat('dd/MM/yyyy')
        if lib_vars.date_format in ("dd/MM/yyyy", "dd-MM-yyyy", "yyyy/MM/dd", "yyyy-MM-dd"):
            self.dlg_manager.date_exec_from.setDisplayFormat(lib_vars.date_format)
        self.dlg_manager.date_exec_from.blockSignals(True)
        self.dlg_manager.date_exec_from.setDate(min_date)
        self.dlg_manager.date_exec_from.blockSignals(False)

    def _show_context_menu(self, qtableview):
        """ Show custom context menu """
        menu = QMenu(qtableview)

        action_edit = QAction("Edit", qtableview)
        action_edit.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_edit"))
        menu.addAction(action_edit)

        action_show_inp_data = QAction("Show inp data", qtableview)
        action_show_inp_data.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_show_inp_data"))
        menu.addAction(action_show_inp_data)

        action_toggle_active = QAction("Toggle active", qtableview)
        action_toggle_active.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_archive"))
        action_toggle_active.setEnabled(qtableview.window().btn_archive.isEnabled())
        menu.addAction(action_toggle_active)

        action_set_corporate = QAction("Set corporate", qtableview)
        action_set_corporate.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_toggle_corporate"))
        action_set_corporate.setEnabled(qtableview.window().btn_toggle_corporate.isEnabled())
        menu.addAction(action_set_corporate)

        action_delete = QAction("Delete", qtableview)
        action_delete.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_delete"))
        menu.addAction(action_delete)

        menu.exec(QCursor.pos())

    def _fill_manager_table(self, *args):
        """ Fill EPA result manager table from v_ui_rpt_cat_result """

        complet_list = self._get_list("v_ui_rpt_cat_result")

        if complet_list is False:
            return False, False
        data = complet_list['body']['data']
        headers = complet_list['body']['form'].get('headers')
        fields = data['fields']
        if data.get('hidden'):
            return False, False
        model = self.dlg_manager.tbl_rpt_cat_result.model()
        if model is None:
            model = QStandardItemModel()
            self.dlg_manager.tbl_rpt_cat_result.setModel(model)
        model.removeRows(0, model.rowCount())

        if fields:
            self.dlg_manager.tbl_rpt_cat_result = tools_gw.add_tableview_header(self.dlg_manager.tbl_rpt_cat_result, fields, headers)
            self.dlg_manager.tbl_rpt_cat_result = tools_gw.fill_tableview_rows(self.dlg_manager.tbl_rpt_cat_result, fields)

        tools_gw.set_tablemodel_config(self.dlg_manager, self.dlg_manager.tbl_rpt_cat_result, 'v_ui_rpt_cat_result')
        tools_qt.set_tableview_config(self.dlg_manager.tbl_rpt_cat_result, edit_triggers=QTableView.EditTrigger.NoEditTriggers, section_resize_mode=QHeaderView.ResizeMode.Interactive)

        return complet_list

    def _get_list(self, table_name='v_ui_rpt_cat_result'):
        """ Mount and execute the query for gw_fct_getlist using dialog filters """

        extras = f'"tableName":"{table_name}"'
        filter_fields = '"limit": -1'

        result_id = tools_qt.get_text(self.dlg_manager, self.dlg_manager.txt_result_id, False, False)
        if result_id and result_id != 'null':
            filter_fields += f', "result_id": {{"filterSign":"ILIKE", "value":"{result_id}"}}'

        status = tools_qt.get_combo_value(self.dlg_manager, self.dlg_manager.cmb_status, 1)
        if status not in (None, '', -1):
            filter_fields += f', "status": {{"filterSign":"=", "value":"{status}"}}'

        network_type = tools_qt.get_combo_value(self.dlg_manager, self.dlg_manager.cmb_network_type, 1)
        if network_type not in (None, '', -1):
            filter_fields += f', "network_type": {{"filterSign":"=", "value":"{network_type}"}}'

        expl_id = tools_qt.get_combo_value(self.dlg_manager, self.dlg_manager.cmb_expl, 0)
        if expl_id not in (None, '', -1):
            filter_fields += (
                f', "expl_id": {{"filterSign":"@>", "filterType":"int4[]", "value":"{{{expl_id}}}"}}'
            )

        exec_date = tools_qt.get_calendar_date(
            self.dlg_manager, self.dlg_manager.date_exec_from, date_format='dd-MM-yyyy'
        )
        if exec_date:
            filter_fields += (
                f', "exec_date": {{"filterSign":">=", "filterType":"timestamp", "value":"{exec_date}"}}'
            )

        if tools_qt.is_checked(self.dlg_manager, self.dlg_manager.chk_corporate):
            filter_fields += ', "iscorporate": {"filterSign":"=", "value":"true"}'

        if tools_qt.is_checked(self.dlg_manager, self.dlg_manager.chk_archived):
            filter_fields += ', "status": {"filterSign":"=", "value":"ARCHIVED"}'

        body = tools_gw.create_body(filter_fields=filter_fields, extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_getlist', body)
        if json_result is None or json_result['status'] == 'Failed':
            return False
        complet_list = json_result
        if not complet_list:
            return False

        return complet_list

    def _update_data(self, result_id, columnname, value):

        sql = f"""UPDATE v_ui_rpt_cat_result SET "{columnname}" = $${value}$$ WHERE result_id = '{result_id}';"""
        result = tools_db.execute_sql(sql, log_sql=True)
        if result:
            self._fill_manager_table()

    def _fill_txt_infolog(self, selected):
        """
        Fill txt_infolog from epa_result_manager form with current data selected for columns:
            'export_options'
            'network_stats'
            'inp_options'
        """

        # Get id of selected row
        row = selected.indexes()
        if not row:
            tools_qt.set_widget_text(self.dlg_manager, 'tab_log_txt_infolog', '')
            return

        msg = ""

        try:
            # Get column index for column addparam
            col_ind = tools_qt.get_col_index_by_col_name(self.dlg_manager.tbl_rpt_cat_result, 'addparam')
            addparam = json.loads(f'{row[col_ind].data()}')

            # Construct custom message with addparam keys
            if not addparam:
                raise

            msg += "<b>Properties: </b> <br>"
            corporate_last_dates = addparam['corporateLastDates']
            if corporate_last_dates:
                corporate_start = corporate_last_dates.get('start')
                corporate_end = corporate_last_dates.get('end')
                if corporate_start and corporate_end:
                    msg += f"Corporate from {corporate_start} to {corporate_end}"
                elif corporate_start and not corporate_end:
                    msg += f"Corporate since {corporate_start}"
                elif not corporate_start and corporate_end:
                    msg += f"Corporate until {corporate_end}"
                msg += " <br>"
        except Exception:
            pass

        try:
            # Get column index for column export_options
            col_ind = tools_qt.get_col_index_by_col_name(self.dlg_manager.tbl_rpt_cat_result, 'export_options')
            export_options = json.loads(f'{row[col_ind].data()}')

            # Construct message with all data rows
            if msg:
                msg += " <br> "
            msg += "<b>Export Options: </b> <br>"
            for text in export_options:
                msg += f"{text} : {export_options[text]} <br>"
        except Exception:
            pass

        try:
            # Get column index for column network_stats
            col_ind = tools_qt.get_col_index_by_col_name(self.dlg_manager.tbl_rpt_cat_result, 'network_stats')
            network_stats = json.loads(f'{row[col_ind].data()}')
            if msg:
                msg += " <br> "
            msg += "<b>Network Status: </b> <br>"
            for text in network_stats:
                msg += f"{text} : {network_stats[text]} <br>"
        except Exception:
            pass

        try:
            # Get column index for column inp_options
            col_ind = tools_qt.get_col_index_by_col_name(self.dlg_manager.tbl_rpt_cat_result, 'inp_options')
            inp_options = json.loads(f'{row[col_ind].data()}')
            if msg:
                msg += " <br> "
            msg += f"<b>{tools_qt.tr('Inp Options')}: </b> <br>"
            for text in inp_options:
                msg += f"{text} : {inp_options[text]} <br>"
        except Exception:
            pass

        # Set message text into widget
        tools_qt.set_widget_text(self.dlg_manager, 'tab_log_txt_infolog', msg)

    def _enable_buttons(self, selected):
        set_corporate_enabled, archive_enabled = True, True
        selected_rows = self.dlg_manager.tbl_rpt_cat_result.selectionModel().selectedRows()
        last_status = None
        for idx, index in enumerate(selected_rows):
            is_corporate = None
            # set corporate
            col_idx = tools_qt.get_col_index_by_col_name(self.dlg_manager.tbl_rpt_cat_result, 'rpt_stats')
            row = index.row()
            status = index.sibling(row, col_idx).data()
            if not status:
                set_corporate_enabled = False

            col_idx = tools_qt.get_col_index_by_col_name(self.dlg_manager.tbl_rpt_cat_result, 'iscorporate')
            if col_idx is not None:
                row = index.row()
                is_corporate = index.sibling(row, col_idx).data()

            # toggle archive
            col_idx = tools_qt.get_col_index_by_col_name(self.dlg_manager.tbl_rpt_cat_result, 'status')
            status = index.sibling(row, col_idx).data()
            if last_status is None:
                last_status = status
            if is_corporate is None:
                if status == 'PARTIAL' or status != last_status or tools_os.set_boolean(is_corporate, False):
                    archive_enabled = False
            last_status = status

        if not selected_rows or len(selected_rows) > 1:
            set_corporate_enabled, archive_enabled = False, False
        self.dlg_manager.btn_toggle_corporate.setEnabled(set_corporate_enabled)
        self.dlg_manager.btn_archive.setEnabled(archive_enabled)

    def _fill_combo_result_id(self):

        sql = "SELECT result_id FROM v_ui_rpt_cat_result ORDER BY result_id"
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_manager.txt_result_id, rows, add_empty=True)

    def _filter_by_result_id(self):

        table = self.dlg_manager.tbl_rpt_cat_result
        widget_txt = self.dlg_manager.txt_result_id
        tablename = 'v_ui_rpt_cat_result'
        result_id = tools_qt.get_text(self.dlg_manager, widget_txt)
        if result_id != 'null':
            expr = f" result_id ILIKE '%{result_id}%'"
            # Refresh model with selected filter
            table.model().setFilter(expr)
            table.model().select()
        else:
            message = tools_qt.fill_table(table, tablename)
            if message:
                tools_qgis.show_warning(message)

    def _multi_rows_delete(self, widget, table_name, column_id):
        """ Delete selected elements of the table
        :param QTableView widget: origin
        :param table_name: table origin
        :param column_id: Refers to the id of the source table
        """

        # Get selected rows
        selected_list = widget.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_manager)
            return

        inf_text = ""
        list_id = ""
        for i in range(0, len(selected_list)):
            row = selected_list[i].row()
            col = tools_qt.get_col_index_by_col_name(widget, str(column_id))
            id_ = widget.model().index(row, col).data()
            inf_text += f"{id_}, "
            list_id += f"'{id_}', "
        inf_text = inf_text[:-2]
        list_id = list_id[:-2]
        msg = "Are you sure you want to delete these records?"
        title = "Delete records"
        answer = tools_qt.show_question(msg, title, inf_text)
        if answer:
            sql = f"DELETE FROM {table_name}"
            sql += f" WHERE {column_id} IN ({list_id})"
            tools_db.execute_sql(sql)
            self._fill_manager_table()

    def _toggle_rpt_archived(self, widget, column_id):
        """ Call gw_fct_set_rpt_archived with selected result_id
                :param QTableView widget: origin
                :param table_name: table origin
                :param column_id: Refers to the id of the source table
                """

        # Get selected rows
        selected_list = widget.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_manager)
            return

        row = selected_list[0].row()
        col = tools_qt.get_col_index_by_col_name(widget, str(column_id))
        result_id = widget.model().index(row, col).data()
        col = tools_qt.get_col_index_by_col_name(widget, "status")
        status = widget.model().index(row, col).data()

        # check corporate
        action = 'RESTORE' if status == 'ARCHIVED' else 'ARCHIVE'
        extras = f'"result_id":"{result_id}", "action": "{action}"'
        body = tools_gw.create_body(extras=extras)
        result = tools_gw.execute_procedure('gw_fct_set_rpt_archived', body)

        if not result or result.get('status') != 'Accepted':
            msg = "gw_fct_set_rpt_archived execution failed. See logs for more details..."
            tools_qgis.show_warning(msg, dialog=self.dlg_manager)
            return

        msg = "Set rpt archived execution successful."
        tools_qgis.show_info(msg, dialog=self.dlg_manager)
        # Refresh table
        self._fill_manager_table()

    def _epa2data(self, widget, column_id):
        """ Delete selected elements of the table
            :param QTableView widget: origin
            :param table_name: table origin
            :param column_id: Refers to the id of the source table
        """

        # Get selected rows
        selected_list = widget.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_manager)
            return

        msg = ("You are going to make this result corporate. From now on the result values will appear on feature form. "
                "Do you want to continue?")

        answer = tools_qt.show_question(msg)
        if not answer:
            return

        result_id = ""
        set_corporate = True
        for i in range(0, len(selected_list)):
            row = selected_list[i].row()
            col = tools_qt.get_col_index_by_col_name(widget, str(column_id))
            result_id = widget.model().index(row, col).data()
            col = tools_qt.get_col_index_by_col_name(widget, "iscorporate")
            set_corporate = widget.model().index(row, col).data()
        set_corporate = not tools_os.set_boolean(set_corporate, False)
        parameter = {"data": {"resultId": result_id, "isCorporate": str(set_corporate).lower()}}
        result = tools_gw.execute_procedure('gw_fct_epa2data', parameter)

        if not result or result.get('status') != 'Accepted':
            msg = "Epa2data execution failed. See logs for more details..."
            tools_qgis.show_warning(msg, dialog=self.dlg_manager)
            return
        elif result['message'].get('level') == 2:
            tools_qgis.show_warning(result['message']['text'], dialog=self.dlg_manager)
            return

        tools_qgis.show_info(result['message']['text'], dialog=self.dlg_manager)

        # Refresh table
        self._fill_manager_table()

    def _manage_edit_row(self, dialog, widget):

        # Get selected rows
        selected_list = widget.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_manager)
            return
        index = selected_list[0]

        columnname = "descript"
        column = tools_qt.get_col_index_by_col_name(widget, columnname)
        row = index.row()
        model = widget.model()
        value = model.item(row, column).text()
        header = model.headerData(column, Qt.Orientation.Horizontal)
        result_id = model.data(model.index(row, 0))

        edit_dialog = GwEditDialog(dialog, title=f"Edit {header}", label_text=f"Set new '{header}' value for result '{result_id}':",
                                widget_type="QTextEdit", initial_value=value)
        if edit_dialog.exec() == QDialog.DialogCode.Accepted:
            new_value = edit_dialog.get_value()
            self._update_data(result_id, columnname, new_value)

    def _show_inp_data(self, dialog, widget):
        # Get selected rows
        selected_list = widget.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_manager)
            return

        result_ids = []
        for index in selected_list:
            result_id = widget.model().data(widget.model().index(index.row(), 0))
            result_ids.append(result_id)

        if not result_ids:
            return

        input_param = {
            "result_ids": result_ids
        }
        result_ids_json = f"'{json.dumps(input_param)}'::json"
        json_result = tools_gw.execute_procedure(
            function_name="gw_fct_getinpdata",
            parameters=result_ids_json,
            schema_name=f"{lib_vars.schema_name}",
            commit=False
        )

        if not json_result or 'status' not in json_result or json_result['status'] == 'Failed':
            msg = "Failed to retrieve GeoJSON data."
            tools_qgis.show_warning(msg, dialog=self.dlg_manager)
            return

        # Zoom layer arc if exists
        arc_layer = tools_qgis.get_layer_by_layername("Rpt INP Arc")
        if arc_layer:
            tools_qgis.zoom_to_layer(arc_layer)

        msg = "Data retrieved and displayed successfully."
        tools_qgis.show_info(msg, dialog=self.dlg_manager)

    # endregion
