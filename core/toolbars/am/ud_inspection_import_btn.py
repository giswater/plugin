"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

from qgis.PyQt.QtWidgets import QFileDialog, QMenu

from .... import global_vars
from ....libs import tools_db, tools_qt
from ..dialog import GwAction
from .importers.generic_une_importer import GenericUneImporter
from .importers.sewdef_importer import SewdefImporter
from .importers.wincan_importer import WincanImporter


class GwUdInspectionImportButton(GwAction):
    """Button 90: import UD CCTV observations into am.ud_*_pathology."""

    def __init__(self, icon_path, action_name, text, toolbar, action_group):
        super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.iface = global_vars.iface
        title = "Import WinCan"
        self.txt_wincan = tools_qt.tr(title)
        title = "Import SEWDEF"
        self.txt_sewdef = tools_qt.tr(title)
        title = "Import UNE CSV"
        self.txt_une = tools_qt.tr(title)
        if toolbar is not None:
            toolbar.removeAction(self.action)
            self.menu = QMenu()
            self.menu.setObjectName("AM_ud_inspection_import")
            self.menu.addAction(self.txt_wincan, lambda: self._import("wincan"))
            self.menu.addAction(self.txt_sewdef, lambda: self._import("sewdef"))
            self.menu.addAction(self.txt_une, lambda: self._import("une"))
            self.action.setMenu(self.menu)
            toolbar.addAction(self.action)

    def clicked_event(self):
        if self.action.menu():
            self.action.menu().exec(self.iface.mapCanvas().mapToGlobal(self.iface.mapCanvas().rect().center()))

    def _import(self, kind):
        title = "Select inspection file"
        path, _ = QFileDialog.getOpenFileName(None, tools_qt.tr(title), "", "Inspection (*.xml *.csv *.txt *.dat)")
        if not path:
            return
        parsers = {"wincan": WincanImporter, "sewdef": SewdefImporter, "une": GenericUneImporter}
        try:
            rows = parsers[kind]().parse(path)
        except Exception as exc:
            msg = "Could not read the inspection file: {0}"
            tools_qt.show_info_box(msg, msg_params=(exc,))
            return
        inserted, skipped = self._insert_rows(rows)
        msg = "Imported {0} observations. Skipped {1}."
        tools_qt.show_info_box(msg, msg_params=(inserted, skipped))

    def _sql_num(self, value):
        if value is None:
            return "NULL"
        return str(value)

    def _sql_text(self, value):
        if value is None:
            return "NULL"
        return "'" + str(value).replace("'", "''") + "'"

    def _insert_rows(self, rows):
        inserted = 0
        skipped = 0
        for row in rows:
            severity = row.get("severity")
            if severity is None or not 1 <= int(severity) <= 5 or row.get("asset_id") is None:
                skipped += 1
                continue
            code = row["code"].replace("'", "''")
            found = tools_db.get_row(
                f"SELECT pathology_id FROM am.ud_cat_pathology WHERE upper(code) = '{code}' AND active IS TRUE"
            )
            if not found:
                skipped += 1
                continue
            table = "ud_node_pathology" if row["feature_type"] == "NODE" else "ud_arc_pathology"
            id_col = "node_id" if row["feature_type"] == "NODE" else "arc_id"
            sql = f"""
                INSERT INTO am.{table} (
                    {id_col}, pathology_id, inspection_id, pk_start, pk_end, pk,
                    clock_start, clock_end, severity, observation, inspection_date
                ) VALUES (
                    {int(row['asset_id'])}, {int(found[0])}, {self._sql_num(row.get('inspection_id'))},
                    {self._sql_num(row.get('pk_start'))}, {self._sql_num(row.get('pk_end'))},
                    {self._sql_num(row.get('pk'))}, {self._sql_num(row.get('clock_start'))},
                    {self._sql_num(row.get('clock_end'))}, {int(severity)},
                    {self._sql_text(row.get('observation'))}, {self._sql_text(row.get('inspection_date'))}
                )
            """
            if tools_db.execute_sql(sql, show_exception=False) is False:
                skipped += 1
            else:
                inserted += 1
        return inserted, skipped
