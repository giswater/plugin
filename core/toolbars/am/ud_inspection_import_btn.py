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
        msg = "Inspection files (*.xml *.csv *.txt *.dat)"
        path, _ = QFileDialog.getOpenFileName(None, tools_qt.tr(title), "", tools_qt.tr(msg))
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
        values = {"ARC": [], "NODE": []}
        skipped = 0
        for row in rows:
            severity = row.get("severity")
            if severity is None or not 1 <= int(severity) <= 5 or row.get("asset_id") is None:
                skipped += 1
                continue
            code = str(row.get("code") or "").upper().replace("'", "''")
            if not code:
                skipped += 1
                continue
            found = tools_db.get_row(
                f"SELECT pathology_id FROM am.ud_cat_pathology WHERE upper(code) = '{code}' AND active IS TRUE"
            )
            if not found:
                skipped += 1
                continue
            feature_type = "NODE" if row.get("feature_type") == "NODE" else "ARC"
            parent_table = feature_type.lower()
            id_col = f"{parent_table}_id"
            asset_id = self._sql_text(row["asset_id"])
            exists = tools_db.get_row(
                f"SELECT 1 FROM {parent_table} WHERE {id_col} = {asset_id}",
                log_info=False,
            )
            if not exists:
                skipped += 1
                continue
            values[feature_type].append(
                f"""({asset_id}, {int(found[0])}, {self._sql_num(row.get('inspection_id'))},
                    {self._sql_num(row.get('pk_start'))}, {self._sql_num(row.get('pk_end'))},
                    {self._sql_num(row.get('pk'))}, {self._sql_num(row.get('clock_start'))},
                    {self._sql_num(row.get('clock_end'))}, {int(severity)},
                    {self._sql_text(row.get('observation'))}, {self._sql_text(row.get('inspection_date'))})"""
            )

        statements = []
        for feature_type, table in (("ARC", "ud_arc_pathology"), ("NODE", "ud_node_pathology")):
            if not values[feature_type]:
                continue
            id_col = "arc_id" if feature_type == "ARC" else "node_id"
            statements.append(
                f"""INSERT INTO am.{table} (
                    {id_col}, pathology_id, inspection_id, pk_start, pk_end, pk,
                    clock_start, clock_end, severity, observation, inspection_date
                ) VALUES {','.join(values[feature_type])}"""
            )
        inserted = sum(len(batch) for batch in values.values())
        if statements and not tools_db.execute_sql(";\n".join(statements), show_exception=False):
            return 0, skipped + inserted
        return inserted, skipped
