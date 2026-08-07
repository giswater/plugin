"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial

from qgis.PyQt.QtCore import Qt, QItemSelectionModel, QRegularExpression
from qgis.PyQt.QtGui import QRegularExpressionValidator
from qgis.PyQt.QtSql import QSqlRelation, QSqlRelationalTableModel
from qgis.PyQt.QtWidgets import QAbstractItemView, QLineEdit, QTableView

from .priority_btn import CalculatePriority
from ...ui.ui_manager import GwPriorityManagerUi, GwStatusSelectorUi

from ....libs import lib_vars, tools_db, tools_qt, tools_qgis
from ...utils import tools_gw
from ..dialog import GwAction

from .... import global_vars


class GwResultManagerButton(GwAction):
    """AM Results Manager — layout/flow aligned with Workspace manager."""

    def __init__(self, icon_path, action_name, text, toolbar, action_group):
        """ Initialise toolbar action for AM result manager """
        super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.iface = global_vars.iface

        self.icon_path = icon_path
        self.action_name = action_name
        self.text = text
        self.toolbar = toolbar
        self.action_group = action_group

    def clicked_event(self):
        """ Open priority result manager dialog """
        self.open_manager()

    def open_manager(self):
        """ Build and open priority manager (workspace-manager pattern). """
        self.dlg_priority_manager = GwPriorityManagerUi(self)
        tools_gw.load_settings(self.dlg_priority_manager)

        dlg = self.dlg_priority_manager
        self.filter_name = dlg.findChild(QLineEdit, "txt_name")
        reg_exp = QRegularExpression(r'([^"\'\\\\])*')
        self.filter_name.setValidator(QRegularExpressionValidator(reg_exp))

        self.tbl_results = dlg.findChild(QTableView, "tbl_results")

        # Fill combo filters
        rows = tools_db.get_rows("SELECT id, idval FROM am.value_result_type")
        tools_qt.fill_combo_values(dlg.cmb_type, rows, 1, add_empty=True)

        rows = tools_db.get_rows(
            f"SELECT expl_id, name FROM {lib_vars.schema_name}.exploitation"
        )
        tools_qt.fill_combo_values(dlg.cmb_expl, rows, 1, add_empty=True)

        rows = tools_db.get_rows("SELECT id, idval FROM am.value_status")
        tools_qt.fill_combo_values(dlg.cmb_status, rows, 1, add_empty=True)

        # Fill results table
        self._fill_table()

        rows = tools_db.get_rows(
            """
            select columnname, alias
            from am.config_form_tableview
            where objectname = 'cat_result'
            """
        )
        if not rows:
            return

        self.headers = {row["columnname"]: row["alias"] for row in rows}
        self.headers["value_result_type_idval_2"] = self.headers.get(
            "result_type", "Type"
        )
        self.headers["name"] = self.headers.get("expl_id", "Explotation")
        self.headers["idval"] = self.headers.get("status", "Status")

        model = self.tbl_results.model()
        if model:
            for col_idx in range(model.columnCount()):
                field_name = model.record().fieldName(col_idx)
                if field_name in self.headers:
                    model.setHeaderData(
                        col_idx, Qt.Orientation.Horizontal, self.headers[field_name]
                    )

        # Status / type maps for actions
        self._value_status = {}
        rows = tools_db.get_rows("select id, idval from am.value_status")
        if not rows:
            return
        for id_, idval in rows:
            self._value_status[idval] = id_

        self._value_result_type = {}
        rows = tools_db.get_rows("select id, idval from am.value_result_type")
        if not rows:
            return
        for id_, idval in rows:
            self._value_result_type[idval] = id_

        self._set_signals()
        tools_gw.open_dialog(dlg, dlg_name="priority_manager")

    def _fill_table(self):
        """Attach relational model and apply workspace-style table config."""
        dlg = self.dlg_priority_manager
        self._set_sql_model(
            dlg,
            self.tbl_results,
            "am.cat_result",
            [
                (2, "am.value_result_type", "id", "idval"),
                (5, f"{lib_vars.schema_name}.exploitation", "expl_id", "name"),
                (10, "am.value_status", "id", "idval"),
            ],
        )
        tools_gw.set_tablemodel_config(
            dlg, self.tbl_results, "cat_result", schema_name="am"
        )
        tools_qt.set_tableview_config(
            self.tbl_results,
            selection_mode=QAbstractItemView.SelectionMode.SingleSelection,
        )
        self._filter_table()

    def _fill_info(self, selected, deselected):
        """Fill Info panel from selection (workspace selectionChanged pattern)."""
        dlg = self.dlg_priority_manager
        cols = selected.indexes()
        if not cols:
            if deselected.indexes():
                self.tbl_results.selectionModel().select(
                    deselected, QItemSelectionModel.SelectionFlag.Select
                )
                return
            tools_qt.set_widget_text(dlg, "tab_log_txt_infolog", "")
            self._manage_btn_action()
            return

        row = cols[0].row()
        record = self.tbl_results.model().record(row)
        txt = ""
        for i in range(len(record)):
            if not record.value(i):
                continue
            field_name = record.fieldName(i)
            value = record.value(i)
            label = self.headers.get(field_name) or field_name
            txt += f"<b>{label}:</b><br>"
            if field_name == "report":
                txt += value.replace("\n", "<br>") + "<br><br>"
            elif field_name == "tstamp":
                txt += value.toString() + "<br><br>"
            else:
                txt += f"{value}<br><br>"

        tools_qt.set_widget_text(dlg, "tab_log_txt_infolog", txt)
        self._manage_btn_action()

    def _manage_btn_action(self):
        """ Enable action buttons according to selected result status """
        dlg = self.dlg_priority_manager
        selected_list = self.tbl_results.selectionModel().selectedRows()

        if len(selected_list) == 0:
            dlg.btn_delete.setEnabled(False)
            dlg.btn_status.setEnabled(False)
            dlg.btn_duplicate.setEnabled(False)
            dlg.btn_edit.setEnabled(False)
            dlg.btn_corporate.setEnabled(False)
            return

        row = selected_list[0].row()
        status_i18n = self.tbl_results.model().record(row).value(10)
        status = self._value_status.get(status_i18n, "")

        if status == "FINISHED":
            dlg.btn_corporate.setEnabled(True)
            dlg.btn_edit.setEnabled(False)
            dlg.btn_duplicate.setEnabled(True)
            dlg.btn_status.setEnabled(False)
            dlg.btn_delete.setEnabled(False)
        elif status == "ON PLANNING":
            dlg.btn_corporate.setEnabled(True)
            dlg.btn_edit.setEnabled(True)
            dlg.btn_duplicate.setEnabled(True)
            dlg.btn_status.setEnabled(True)
            dlg.btn_delete.setEnabled(False)
        else:
            dlg.btn_corporate.setEnabled(False)
            dlg.btn_edit.setEnabled(False)
            dlg.btn_duplicate.setEnabled(False)
            dlg.btn_status.setEnabled(True)
            dlg.btn_delete.setEnabled(True)

    def _filter_table(self):
        """ Apply name + combo filters to cat_result table model """
        dlg = self.dlg_priority_manager
        name = self.filter_name.text().strip() if self.filter_name else ""
        result_type = tools_qt.get_combo_value(dlg, dlg.cmb_type, 0)
        expl_id = tools_qt.get_combo_value(dlg, dlg.cmb_expl, 0)
        status = tools_qt.get_combo_value(dlg, dlg.cmb_status, 0)

        expr = "result_id is NOT NULL"
        if name:
            safe = name.replace("'", "''")
            expr += f" AND result_name ILIKE '%{safe}%'"
        if result_type:
            expr += f" AND result_type ILIKE '%{result_type}%'"
        if expl_id:
            expr += f" AND am.cat_result.expl_id = {expl_id}"
        if status:
            expr += f" AND status::text ILIKE '%{status}%'"

        model = self.tbl_results.model()
        if model:
            model.setFilter(expr)
            model.select()

    def _delete_result(self):
        """ Delete selected result when status is CANCELED """
        selected_list = self.tbl_results.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_priority_manager)
            return

        row = selected_list[0].row()
        result_id = self.tbl_results.model().record(row).value("result_id")
        result_row = tools_db.get_row(
            f"""
            SELECT result_name, status
            FROM am.cat_result
            WHERE result_id = {result_id}
            """
        )
        if not result_row:
            return
        result_name, status = result_row
        if status != "CANCELED":
            msg = "The result cannot be deleted"
            info = "You can only delete results with the status 'CANCELED'."
            tools_qt.show_info_box(
                msg, inf_text=info, parameter=f"{result_id}-{result_name}"
            )
            return

        msg = "Are you sure you want to delete these records?"
        title = "Delete records"
        if tools_qt.show_question(msg, title, f"{result_id}-{result_name}"):
            tools_db.execute_sql(
                f"DELETE FROM am.cat_result WHERE result_id = {result_id}"
            )
            self.tbl_results.model().select()
            tools_qt.set_widget_text(self.dlg_priority_manager, "tab_log_txt_infolog", "")

    def _dlg_status_accept(self, result_id):
        """ Update result status from status selector dialog """
        new_status = tools_qt.get_combo_value(self.dlg_status, "cmb_status")
        tools_db.execute_sql(
            f"""
            UPDATE am.cat_result
            SET status = '{new_status}'
            WHERE result_id = {result_id}
            """
        )
        self.dlg_status.close()
        self.tbl_results.model().select()

    def _edit_result(self, index=None):
        """ Open priority dialog in edit mode for selected result """
        dlg = self.dlg_priority_manager
        selected_list = self.tbl_results.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dlg)
            return

        row = selected_list[0].row()
        record = self.tbl_results.model().record(row)
        result_id = record.value("result_id")
        result_type_i18n = record.value(2)
        status = self._value_status.get(record.value(10), "")
        if status != "ON PLANNING":
            return

        if not result_type_i18n:
            tools_qgis.show_warning(
                tools_qt.tr("Please select a result with not empty type"), dialog=dlg
            )
            return
        result_type = self._value_result_type[result_type_i18n]

        calculate_priority = CalculatePriority(
            type=result_type, mode="edit", result_id=result_id
        )
        calculate_priority.clicked_event()

    def _duplicate_result(self):
        """ Open priority dialog in duplicate mode for selected result """
        dlg = self.dlg_priority_manager
        selected_list = self.tbl_results.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dlg)
            return

        row = selected_list[0].row()
        result_id = self.tbl_results.model().record(row).value("result_id")
        result_type_i18n = self.tbl_results.model().record(row).value(2)

        if not result_type_i18n:
            tools_qgis.show_warning(
                tools_qt.tr("Please select a result with not empty type"), dialog=dlg
            )
            return

        result_type = self._value_result_type[result_type_i18n]
        calculate_priority = CalculatePriority(
            type=result_type, mode="duplicate", result_id=result_id
        )
        calculate_priority.clicked_event()

    def _set_sql_model(
        self,
        dialog,
        widget,
        table_name,
        relations=None,
        set_edit_triggers=QTableView.EditTrigger.NoEditTriggers,
        expr=None,
    ):
        """Set a relational SQL model on the table (AM data source)."""
        relations = relations or []
        try:
            model = QSqlRelationalTableModel(db=lib_vars.qgis_db_credentials)
            model.setTable(table_name)
            model.setJoinMode(QSqlRelationalTableModel.JoinMode.LeftJoin)
            for column, table, key, value in relations:
                model.setRelation(column, QSqlRelation(table, key, value))
            model.setEditStrategy(QSqlRelationalTableModel.EditStrategy.OnManualSubmit)
            model.setSort(0, Qt.SortOrder.AscendingOrder)
            model.select()

            widget.setEditTriggers(set_edit_triggers)
            widget.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)

            if model.lastError().isValid():
                print(f"ERROR -> {model.lastError().text()}")

            if expr:
                widget.setModel(model)
                widget.model().setFilter(expr)
            else:
                widget.setModel(model)
        except Exception as e:
            print(f"EXCEPTION -> {e}")

    def _open_status_selector(self):
        """ Open dialog to change status of selected result """
        selected_list = self.tbl_results.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_priority_manager)
            return

        row = selected_list[0].row()
        result_id = self.tbl_results.model().record(row).value("result_id")
        result_row = tools_db.get_row(
            f"""
            SELECT result_id, result_name, status
            FROM am.cat_result
            WHERE result_id = {result_id}
            """
        )
        if not result_row:
            return

        result_id, result_name, status = result_row
        if status == "FINISHED":
            msg = "You cannot change the status of a result with status 'FINISHED'."
            tools_qt.show_info_box(msg)
            return

        self.dlg_status = GwStatusSelectorUi(self)
        self.dlg_status.lbl_result.setText(f"{result_id}: {result_name}")
        rows = tools_db.get_rows("SELECT id, idval FROM am.value_status")
        tools_qt.fill_combo_values(self.dlg_status.cmb_status, rows, 1)
        tools_qt.set_combo_value(self.dlg_status.cmb_status, status, 0, add_new=False)
        self.dlg_status.btn_accept.clicked.connect(
            partial(self._dlg_status_accept, result_id)
        )
        self.dlg_status.btn_cancel.clicked.connect(self.dlg_status.reject)

        tools_gw.open_dialog(self.dlg_status, dlg_name="status_selector")

    def _set_corporate(self):
        """ Toggle corporate flag and resolve exploitation conflicts """
        selected_list = self.tbl_results.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_priority_manager)
            return

        row_index = selected_list[0].row()
        row = self.tbl_results.model().record(row_index)
        result_id = row.value("result_id")
        iscorporate = row.value("iscorporate")

        if iscorporate:
            tools_db.execute_sql(
                f"""
                UPDATE am.cat_result
                SET iscorporate = FALSE
                WHERE result_id = {result_id}
                """
            )
            self.tbl_results.model().select()
            self._update_symbology()
            return

        asset_type = row.value("asset_type") or "ARC"
        if asset_type == "NODE":
            output_table = "am.node_output"
            corporate_view = "am.v_asset_node_corporate"
        else:
            output_table = "am.arc_output"
            corporate_view = "am.v_asset_arc_corporate"

        sql = (
            f"SELECT DISTINCT expl_id FROM {output_table} WHERE result_id={result_id}"
        )
        rows = tools_db.get_rows(sql)
        result_expl = {r[0] for r in rows} if rows else set()

        sql = f"SELECT DISTINCT result_id, expl_id FROM {corporate_view}"
        rows = tools_db.get_rows(sql)
        corporate_expl = {}
        if rows:
            for result, expl in rows:
                corporate_expl.setdefault(result, set()).add(expl)

        conflict_results = [
            result
            for result, exploitations in corporate_expl.items()
            if not result_expl.isdisjoint(exploitations)
        ]

        if not conflict_results:
            tools_db.execute_sql(
                f"""
                UPDATE am.cat_result
                SET iscorporate = TRUE
                WHERE result_id = {result_id}
                """
            )
            self.tbl_results.model().select()
            self._update_symbology()
            return

        conflict_results_str = ", ".join(str(x) for x in conflict_results)
        msg = (
            "To make the result id {0} corporate, is necessary to make not corporate "
            "the following result ids: {1}. Do you want to proceed?"
        )
        msg_params = (result_id, conflict_results_str)
        if not tools_qt.show_question(msg, msg_params=msg_params):
            return

        tools_db.execute_sql(
            f"""
            UPDATE am.cat_result
            SET iscorporate = FALSE
            WHERE result_id IN ({conflict_results_str});

            UPDATE am.cat_result
            SET iscorporate = TRUE
            WHERE result_id = {result_id};
            """
        )
        self.tbl_results.model().select()
        self._update_symbology()

    def _update_symbology(self):
        """ Offer to refresh AM layer symbology after corporate change """
        try:
            if not lib_vars.schema_name:
                return
            target_layers = []
            sql = (
                f"SELECT id, addparam FROM {lib_vars.schema_name}.sys_table "
                "WHERE source = 'am' AND addparam ->> 'refreshSymbology' = 'true'"
            )
            rows = tools_db.get_rows(sql) or []
            for row in rows:
                target_layer = tools_qgis.get_layer_by_tablename(
                    row[0], schema_name="am"
                )
                if target_layer is None:
                    continue
                target_layers.append((target_layer, row[1]))

            if target_layers:
                result = tools_qt.show_question(
                    "Do you want to update the symbology of the layers currently "
                    "loaded in the project?",
                    "Update AM Layers Symbology",
                    force_action=True,
                )
                if result:
                    for layer, addparam in target_layers:
                        tools_gw.refresh_categorized_layer_symbology_classes(
                            layer, addparam
                        )
        except Exception:
            pass

    def _set_signals(self):
        """ Connect manager dialog signals (workspace-style). """
        dlg = self.dlg_priority_manager

        self.filter_name.textChanged.connect(partial(self._filter_table))
        dlg.cmb_type.currentIndexChanged.connect(partial(self._filter_table))
        dlg.cmb_expl.currentIndexChanged.connect(partial(self._filter_table))
        dlg.cmb_status.currentIndexChanged.connect(partial(self._filter_table))

        dlg.btn_corporate.clicked.connect(self._set_corporate)
        dlg.btn_edit.clicked.connect(partial(self._edit_result))
        dlg.btn_duplicate.clicked.connect(self._duplicate_result)
        dlg.btn_status.clicked.connect(self._open_status_selector)
        dlg.btn_delete.clicked.connect(self._delete_result)
        dlg.btn_close.clicked.connect(partial(tools_gw.close_dialog, dlg))
        dlg.rejected.connect(partial(tools_gw.save_settings, dlg))

        self.tbl_results.doubleClicked.connect(partial(self._edit_result))
        selection_model = self.tbl_results.selectionModel()
        selection_model.selectionChanged.connect(partial(self._fill_info))
