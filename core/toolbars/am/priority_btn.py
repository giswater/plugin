"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from datetime import date, timedelta
from functools import partial
from pathlib import Path
from time import time
import configparser
import os

from qgis.core import QgsApplication
from qgis.PyQt.QtCore import QTimer, Qt
from qgis.PyQt.QtWidgets import (
    QLabel,
    QMenu,
    QAbstractItemView,
    QHeaderView,
    QTableView,
    QTableWidget,
    QTableWidgetItem,
)
from qgis.PyQt.QtGui import QIcon
from qgis.PyQt.QtSql import QSqlTableModel

from .... import global_vars

from ....libs import lib_vars, tools_qgis, tools_db, tools_qt
from ...utils import tools_gw
from ..dialog import GwAction


from ...ui.ui_manager import GwPriorityUi
from ...threads.calculatepriority import GwCalculatePriority


class GwConfigCatalogButton:
    def __init__(self, data, key="arccat_id"):
        self._data = {}
        for entry in sorted(data, key=lambda i: i["dnom"]):
            if key in self._data:
                raise ValueError(
                    f"Key ({key}) is not unique in the config catalog."
                )
            self._data[entry[key]] = entry

    def arccat_ids(self):
        return [x["arccat_id"] for x in self._data.values()]

    def diameters(self):
        return [x["dnom"] for x in self._data.values()]

    def fill_table_widget(self, table_widget):
        headers = [
            "Arccat_id",
            tools_qt.tr("Diameter"),
            tools_qt.tr("Replacement cost"),
            tools_qt.tr("Repair cost"),
            tools_qt.tr("Compliance Grade"),
            tools_qt.tr("Material"),
        ]
        table_widget.setColumnCount(len(headers))
        table_widget.setHorizontalHeaderLabels(headers)
        for r, row in enumerate(self._data.values()):
            table_widget.insertRow(r)
            table_widget.setItem(r, 0, QTableWidgetItem(row["arccat_id"]))
            table_widget.setItem(r, 1, QTableWidgetItem(str(row["dnom"])))
            table_widget.setItem(r, 2, QTableWidgetItem(str(row["cost_constr"])))
            table_widget.setItem(r, 3, QTableWidgetItem(str(row["cost_repmain"])))
            table_widget.setItem(r, 4, QTableWidgetItem(str(row["compliance"])))
            table_widget.setItem(r, 5, QTableWidgetItem(str(row["matcat_id"])))

    def get_compliance(self, key):
        return self._data[key]["compliance"]

    def get_cost_constr(self, key):
        return self._data[key]["cost_constr"]

    def get_cost_repmain(self, key):
        return self._data[key]["cost_repmain"]

    def has_key(self, key):
        return key in self._data

    def max_diameter(self):
        return max(x["dnom"] for x in self._data.values())

    def save(self, result_id):
        sql = f"""
            delete from am.config_catalog where result_id = {result_id};
            insert into am.config_catalog
                (result_id, arccat_id, dnom, cost_constr, cost_repmain, compliance)
            values
        """
        for value in self._data.values():
            sql += f"""
                ({result_id},
                '{value["arccat_id"]}',
                {value["dnom"]},
                {value["cost_constr"]},
                {value["cost_repmain"]},
                {value["compliance"]}),
            """
        sql = sql.strip()[:-1]
        tools_db.execute_sql(sql)


def configcatalog_from_tablewidget(table_widget, key="arccat_id"):
    data = []
    for r in range(table_widget.rowCount()):
        data.append(
            {
                "arccat_id": table_widget.item(r, 0).text(),
                "dnom": float(table_widget.item(r, 1).text()),
                "cost_constr": float(table_widget.item(r, 2).text()),
                "cost_repmain": float(table_widget.item(r, 3).text()),
                "compliance": int(table_widget.item(r, 4).text()),
                "matcat_id": table_widget.item(r, 5).text(),
            }
        )
    return GwConfigCatalogButton(data, key)


class ConfigMaterial:
    def __init__(self, data, unknown_material):
        # order the dict by material
        self._data = {k: data[k] for k in sorted(data.keys())}
        self._unknown_material = unknown_material

    def fill_table_widget(self, table_widget):
        headers = [
            tools_qt.tr("Material"),
            tools_qt.tr("Prob. of Failure"),
            tools_qt.tr("Max. Longevity"),
            tools_qt.tr("Med. Longevity"),
            tools_qt.tr("Min. Longevity"),
            tools_qt.tr("Default Built Date"),
            tools_qt.tr("Compliance Grade"),
        ]
        columns = [
            "material",
            "pleak",
            "age_max",
            "age_med",
            "age_min",
            "builtdate_vdef",
            "compliance",
        ]
        table_widget.setColumnCount(len(headers))
        table_widget.setHorizontalHeaderLabels(headers)
        for r, row in enumerate(self._data.values()):
            table_widget.insertRow(r)
            for c, column in enumerate(columns):
                table_widget.setItem(r, c, QTableWidgetItem(str(row[column])))

    def get_age(self, material, pression):
        if pression < 50:
            return self._get_attr(material, "age_max")
        elif pression < 75:
            return self._get_attr(material, "age_med")
        else:
            return self._get_attr(material, "age_min")

    def get_compliance(self, material):
        return self._get_attr(material, "compliance")

    def get_default_builtdate(self, material):
        return self._get_attr(material, "builtdate_vdef")

    def get_pleak(self, material):
        return self._get_attr(material, "pleak")

    def has_material(self, material):
        return material in self._data

    def materials(self):
        return self._data.keys()

    def save(self, result_id):
        sql = f"""
            delete from am.config_material where result_id = {result_id};
            insert into am.config_material
                (result_id, material, pleak,
                age_max, age_med, age_min,
                builtdate_vdef, compliance)
            values
        """
        for value in self._data.values():
            sql += f"""
                ({result_id},
                '{value["material"]}',
                {value["pleak"]},
                {value["age_max"]},
                {value["age_med"]},
                {value["age_min"]},
                {value["builtdate_vdef"]},
                {value["compliance"]}),
            """
        sql = sql.strip()[:-1]
        tools_db.execute_sql(sql)

    def _get_attr(self, material, attribute):
        if material in self._data:
            return self._data[material][attribute]
        return self._data[self._unknown_material][attribute]


def configmaterial_from_sql(sql, unknown_material):
    rows = tools_db.get_rows(sql)
    data = {}
    if rows:
        for row in rows:
            data[row["material"]] = {
                "material": row["material"],
                "pleak": row["pleak"],
                "age_max": row["age_max"],
                "age_med": row["age_med"],
                "age_min": row["age_min"],
                "builtdate_vdef": row["builtdate_vdef"],
                "compliance": row["compliance"],
            }
    return ConfigMaterial(data, unknown_material)


def configmaterial_from_tablewidget(table_widget, unknown_material):
    data = {}
    for r in range(table_widget.rowCount()):
        data[table_widget.item(r, 0).text()] = {
            "material": table_widget.item(r, 0).text(),
            "pleak": float(table_widget.item(r, 1).text()),
            "age_max": int(table_widget.item(r, 2).text()),
            "age_med": int(table_widget.item(r, 3).text()),
            "age_min": int(table_widget.item(r, 4).text()),
            "builtdate_vdef": int(table_widget.item(r, 5).text()),
            "compliance": int(table_widget.item(r, 6).text()),
        }
    return ConfigMaterial(data, unknown_material)


class GwAmPriorityButton(GwAction):
    """Button 2: Selection & priority calculation button
    Select features and calculate priorities"""

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.iface = global_vars.iface

        self.icon_path = icon_path
        self.action_name = action_name
        self.text = text
        self.toolbar = toolbar
        self.action_group = action_group

    def clicked_event(self):
        calculate_priority = CalculatePriority(type="SELECTION")
        calculate_priority.clicked_event()


class CalculatePriorityConfig:
    def __init__(self, type):
        try:
            if type == "GLOBAL":
                dialog_type = "dialog_priority_global"
            elif type == "SELECTION":
                dialog_type = "dialog_priority_selection"
            else:
                raise ValueError(
                    tools_qt.tr(
                        "Invalid value for type of priority dialog. "
                        "Please pass either 'GLOBAL' or 'SELECTION'. "
                        "Value passed:"
                    )
                    + f" '{self.type}'."
                )

            # Read the config file
            config = configparser.ConfigParser()
            config_path = os.path.join(
                lib_vars.plugin_dir, f"config{os.sep}giswater.config"
            )

            if not os.path.exists(config_path):
                print(f"Config file not found: {config_path}")
                return

            config.read(config_path)

            self.method = config.get("general", "engine_method")
            self.unknown_material = config.get("general", "unknown_material")
            self.show_budget = config.getboolean(dialog_type, "show_budget")
            self.show_target_year = config.getboolean(dialog_type, "show_target_year")
            self.show_selection = config.getboolean(dialog_type, "show_selection")
            self.show_maptool = config.getboolean(dialog_type, "show_maptool")
            self.show_diameter = config.getboolean(dialog_type, "show_diameter")
            self.show_material = config.getboolean(dialog_type, "show_material")
            self.show_exploitation = config.getboolean(dialog_type, "show_exploitation")
            self.show_presszone = config.getboolean(dialog_type, "show_presszone")
            self.show_ivi_button = config.getboolean(dialog_type, "show_ivi_button")
            self.show_config = config.getboolean(dialog_type, "show_config")
            self.show_config_catalog = config.getboolean(
                dialog_type, "show_config_catalog"
            )
            self.show_config_material = config.getboolean(
                dialog_type, "show_config_material"
            )
            self.show_config_engine = config.getboolean(
                dialog_type, "show_config_engine"
            )
            self.show_save2file = config.getboolean(dialog_type, "show_save2file")

        except Exception as e:
            print("read_config_file error %s" % e)


class CalculatePriority:
    def __init__(self, type="GLOBAL", mode="new", result_id=None):
        if mode == "new":
            self.result = {
                "id": None,
                "name": None,
                "type": type,
                "descript": None,
                "expl_id": None,
                "budget": None,
                "target_year": None,
                "status": None,
                "presszone_id": None,
                "material_id": None,
                "features": None,
                "dnom": None,
            }
        else:
            if not result_id:
                raise ValueError(f"For mode '{mode}', an result_id must be informed.")
            self.result = tools_db.get_row(
                f"""
                SELECT result_id AS id,
                    result_name AS name,
                    result_type AS type,
                    descript,
                    expl_id,
                    budget,
                    target_year,
                    status,
                    presszone_id,
                    material_id,
                    features,
                    dnom
                FROM am.cat_result
                WHERE result_id = {result_id}
                """
            )
        self.type = type if mode == "new" else self.result["type"]
        self.mode = mode
        self.layer_to_work = "v_asset_arc_input"
        self.rel_layers = {}
        self.rel_layers["arc"] = []
        self.excluded_layers = []
        self.list_ids = {}
        self.config = CalculatePriorityConfig(type)
        self.total_weight = {}

        # Priority variables
        self.dlg_priority = None

    def clicked_event(self):
        self.dlg_priority = GwPriorityUi(self)
        dlg = self.dlg_priority
        dlg.setWindowTitle(dlg.windowTitle() + f" ({tools_qt.tr(self.type)})")

        tools_gw.disable_tab_log(self.dlg_priority)

        tools_gw.add_icon(self.dlg_priority.btn_snapping, "137")

        tools_gw.add_icon(self.dlg_priority.btn_add_catalog, "111")
        tools_gw.add_icon(self.dlg_priority.btn_add_material, "111")

        tools_gw.add_icon(self.dlg_priority.btn_remove_catalog, "112")
        tools_gw.add_icon(self.dlg_priority.btn_remove_material, "112")

        # Manage form

        # Hidden widgets
        self._manage_hidden_form()

        # Manage selection group
        self.dlg_priority.btn_snapping.clicked.connect(partial(self._snap_clicked))

        # Manage attributes group
        self._manage_attr()

        # Define tableviews
        self.qtbl_catalog = self.dlg_priority.findChild(QTableWidget, "tbl_catalog")
        self.qtbl_catalog.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.qtbl_catalog.setSortingEnabled(True)
        if self.mode == "new":
            sql = "select d.*, cat_arc.matcat_id from am.config_catalog_def d JOIN cat_arc ON d.arccat_id = cat_arc.id"
        else:
            sql = f"select d.*, cat_arc.matcat_id from am.config_catalog_def d JOIN cat_arc ON d.arccat_id = cat_arc.id where d.id = {self.result['id']}"
        key = "arccat_id"

        try:
            configcatalog = GwConfigCatalogButton(tools_db.get_rows(sql), key)
        except ValueError as e:
            tools_qgis.show_warning(str(e))
            return None
        configcatalog.fill_table_widget(self.qtbl_catalog)
        self.qtbl_catalog.horizontalHeader().setSectionResizeMode(
            QHeaderView.ResizeMode.Stretch
        )
        if self.config.method == "WM":
            self.qtbl_catalog.hideColumn(1)
            self.qtbl_catalog.hideColumn(3)

        self.qtbl_material = self.dlg_priority.findChild(QTableWidget, "tbl_material")
        self.qtbl_material.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        if self.mode == "new":
            sql = "select * from am.config_material_def"
        else:
            sql = f"select * from am.config_material where result_id = {self.result['id']}"
        configmaterial = configmaterial_from_sql(sql, self.config.unknown_material)
        configmaterial.fill_table_widget(self.qtbl_material)
        self.qtbl_material.horizontalHeader().setSectionResizeMode(
            QHeaderView.ResizeMode.Stretch
        )
        if self.config.method == "SH":
            self.qtbl_material.hideColumn(1)
            self.qtbl_material.hideColumn(2)
            self.qtbl_material.hideColumn(3)
            self.qtbl_material.hideColumn(4)
            self.qtbl_material.hideColumn(5)

        self._fill_engine_options()
        self._set_signals()

        self.dlg_priority.executing = False

        self.dlg_priority.btn_again.setVisible(False)
        # Open the dialog
        tools_gw.open_dialog(self.dlg_priority, dlg_name="priority")

    def _add_total(self, lyt):
        lbl = QLabel()
        lbl.setText(tools_qt.tr("Total"))
        value = QLabel()
        position_config = {"layoutname": lyt, "layoutorder": 100}
        tools_gw.add_widget(self.dlg_priority, position_config, lbl, value)
        setattr(self.dlg_priority, f"total_{lyt}", value)
        self._update_total_weight(lyt)

    def _calculate_ended(self):
        dlg = self.dlg_priority

        dlg.btn_again.setVisible(True)

        # Check if thread is finished wuih success
        if hasattr(self.thread, "df"):
            # Button OK behavior
            msg = "Next"
            tools_qt.set_widget_text(dlg, dlg.btn_again, msg)
            dlg.btn_save2file.setEnabled(True)
        else:
            dlg.progressBar.setValue(100)
            msg = "Try again"
            tools_qt.set_widget_text(dlg, dlg.btn_again, msg)
        dlg.executing = False
        self.timer.stop()

        try:
            # Update symbology of layers currently loaded in the project
            if not lib_vars.schema_name:
                return
            target_layers = []
            sql = (
                f"SELECT id, addparam FROM {lib_vars.schema_name}.sys_table "
                "WHERE source = 'am' AND addparam ->> 'refreshSymbology' = 'true'"
            )
            rows = tools_db.get_rows(sql) or []
            for row in rows:
                target_layer = tools_qgis.get_layer_by_tablename(row[0], schema_name="am")
                if target_layer is None:
                    continue
                target_layers.append((target_layer, row[1]))

            if len(target_layers) > 0:
                result = tools_qt.show_question("Do you want to update the symbology of the layers currently loaded in the project?", "Update AM Layers Symbology", force_action=True)
                if result:
                    for layer, addparam in target_layers:
                        tools_gw.refresh_categorized_layer_symbology_classes(layer, addparam)
        except Exception:
            pass

    def _cancel_thread(self, dlg):
        self.thread.cancel()
        tools_gw.fill_tab_log(
            dlg,
            {"info": {"values": [{"message": tools_qt.tr("Canceling task...")}]}},
            reset_text=False,
            close=False,
        )

    def _fill_engine_options(self):
        dlg = self.dlg_priority

        self.config_engine_fields = []
        if self.mode == "new":
            rows = tools_db.get_rows(
                f"""
                select parameter,
                    value,
                    descript,
                    layoutname,
                    layoutorder,
                    label,
                    datatype,
                    widgettype
                from am.config_engine_def
                where method = '{self.config.method}'
                """
            )
        else:
            rows = tools_db.get_rows(
                f"""
                select c.parameter,
                    c.value,
                    d.descript,
                    d.layoutname,
                    d.layoutorder,
                    d.label,
                    d.datatype,
                    d.widgettype
                from am.config_engine as c
                join am.config_engine_def as d using (parameter)
                where c.result_id = {self.result["id"]}
                and d.method = '{self.config.method}'
                """
            )

        if rows:
            for row in rows:
                self.config_engine_fields.append(
                    {
                        "widgetname": row["parameter"],
                        "value": row[1],
                        "tooltip": row[2],
                        "layoutname": row[3],
                        "layoutorder": row[4],
                        "label": row[5],
                        "datatype": row[6],
                        "widgettype": row[7],
                        "isMandatory": True,
                    }
                )
        tools_gw.build_dialog_options(
            dlg, [{"fields": self.config_engine_fields}], 0, []
        )

        if self.config.method == "SH":
            dlg.grb_engine_1.setTitle(tools_qt.tr("Shamir-Howard parameters"))
            dlg.grb_engine_2.setTitle(tools_qt.tr("Weights"))
            self._add_total("lyt_engine_2")
        elif self.config.method == "WM":
            dlg.grb_engine_1.setTitle(tools_qt.tr("First iteration"))
            dlg.grb_engine_2.setTitle(tools_qt.tr("Second iteration"))
            self._add_total("lyt_engine_1")
            self._add_total("lyt_engine_2")

    def _get_weight_widgets(self, lyt):
        def is_weight(x):
            return x["layoutname"] == lyt
        fields = filter(is_weight, self.config_engine_fields)
        return [tools_qt.get_widget(self.dlg_priority, x["widgetname"]) for x in fields]

    def _manage_hidden_form(self):

        if self.config.show_budget is not True and not self.result["budget"]:
            self.dlg_priority.lbl_budget.setVisible(False)
            self.dlg_priority.txt_budget.setVisible(False)
        if self.config.show_target_year is not True and not self.result["target_year"]:
            self.dlg_priority.lbl_year.setVisible(False)
            self.dlg_priority.txt_year.setVisible(False)
        if (
            self.config.show_selection is not True
            and not self.result["features"]
            and not self.result["dnom"]
            and not self.result["material_id"]
            and not self.result["expl_id"]
            and not self.result["presszone_id"]
        ):
            self.dlg_priority.grb_selection.setVisible(False)
        else:
            if self.config.show_maptool is not True and not self.result["features"]:
                self.dlg_priority.btn_snapping.setVisible(False)
            if self.config.show_diameter is not True and not self.result["dnom"]:
                self.dlg_priority.lbl_dnom.setVisible(False)
                self.dlg_priority.cmb_dnom.setVisible(False)
            if self.config.show_material is not True and not self.result["material_id"]:
                self.dlg_priority.lbl_material.setVisible(False)
                self.dlg_priority.cmb_material.setVisible(False)
            # Hide Explotation filter if there's arcs without expl_id
            null_expl = tools_db.get_row(
                "SELECT 1 FROM am.ext_arc_asset WHERE expl_id IS NULL"
            )
            if not self.result["expl_id"] and (
                self.config.show_exploitation is not True or null_expl
            ):
                self.dlg_priority.lbl_expl_selection.setVisible(False)
                self.dlg_priority.cmb_expl_selection.setVisible(False)
            # Hide Presszone filter if there's arcs without presszone_id
            null_presszone = tools_db.get_row(
                "SELECT 1 FROM am.ext_arc_asset WHERE presszone_id IS NULL"
            )
            if not self.result["presszone_id"] and (
                self.config.show_presszone is not True or null_presszone
            ):
                self.dlg_priority.lbl_presszone.setVisible(False)
                self.dlg_priority.cmb_presszone.setVisible(False)
        if self.config.show_config is not True:
            self.dlg_priority.grb_global.setVisible(False)
        else:
            if self.config.show_config_catalog is not True:
                self.dlg_priority.tab_widget.tab_diameter.setVisible(False)
            if self.config.show_config_material is not True:
                self.dlg_priority.tab_widget.tab_material.setVisible(False)
            if self.config.show_config_engine is not True:
                self.dlg_priority.tab_widget.tab_engine.setVisible(False)
        if self.config.show_save2file is not True:
           self.dlg_priority.btn_save2file.setVisible(False)

        # Manage form when is edit
        if self.mode == "edit":
            self.dlg_priority.txt_result_id.setEnabled(False)

    def _manage_calculate(self):
        dlg = self.dlg_priority
        tools_qt.set_widget_text(dlg, 'tab_log_txt_infolog', '')
        inputs = self._validate_inputs()
        if not inputs:
            return

        (
            result_name,
            result_description,
            status,
            features,
            exploitation,
            presszone,
            diameter,
            material,
            budget,
            target_year,
            config_catalog,
            config_material,
            config_engine,
        ) = inputs

        filter_list = []
        if features:
            filter_list.append(f"""arc_id in ('{"','".join(features)}')""")
        if exploitation:
            filter_list.append(f"expl_id = {exploitation}")
        if presszone:
            filter_list.append(f"presszone_id = '{presszone}'")
        if diameter:
            filter_list.append(f"dnom = '{diameter}'")
        if material:
            filter_list.append(f"matcat_id = '{material}'")
        filters = f"where {' and '.join(filter_list)}" if filter_list else ""

        data_checks = tools_db.get_rows(
            f"""
            with assets as (
                select * from am.ext_arc_asset {filters}),
            list_invalid_arccat_ids as (
                select count(*), coalesce(arccat_id, 'NULL')
                from assets
                where arccat_id is null 
                    or arccat_id not in ('{"','".join(config_catalog.arccat_ids())}')
                group by arccat_id
                order by arccat_id),
            invalid_arccat_ids as (
                select 'invalid_arccat_ids' as check,
                    sum(count) as qtd,
                    string_agg(coalesce, ', ') as list
                from list_invalid_arccat_ids),
            list_invalid_diameters as (
                select count(*), coalesce(dnom::text, 'NULL')
                from assets
                where dnom is null 
                    or dnom::numeric <= 0
                    or dnom::numeric > {config_catalog.max_diameter()}
                group by dnom
                order by dnom),
            invalid_diameters as (
                select 'invalid_diameters' as check,
                    sum(count) as qtd,
                    string_agg(coalesce, ', ') as list
                from list_invalid_diameters),
            list_invalid_materials as (
                select count(*), coalesce(matcat_id, 'NULL')
                from assets
                where matcat_id not in ('{"','".join(config_material.materials())}')
                    or matcat_id = '{self.config.unknown_material}'
                    or matcat_id is null
                group by matcat_id
                order by matcat_id),
            invalid_materials as (
                select 'invalid_materials', sum(count), string_agg(coalesce, ', ')
                from list_invalid_materials),
            null_pressures as (
                select 'null_pressures' as check,
                    count(*) as qtd,
                    null as list
                from assets
                where press1 is null and press2 is null)
            select * from invalid_arccat_ids
            union all
            select * from invalid_diameters
            union all
            select * from invalid_materials
            union all
            select * from null_pressures
            """
        )

        for row in data_checks:
            if not row["qtd"]:
                continue
            if row["check"] == "invalid_arccat_ids" and self.config.method == "WM":
                msg = ("Pipes with invalid arccat_ids: {0}.\nInvalid arccat_ids: {1}.\n\n"
                        "An arccat_id is considered invalid if it is not listed in the catalog configuration table. "
                        "As a result, these pipes will NOT be assigned a priority value.\n\n"
                        "Do you want to proceed?")
                msg_params = (row["qtd"], row["list"],)
                if not tools_qt.show_question(msg, force_action=True, msg_params=msg_params):
                    return
            elif row["check"] == "invalid_diameters" and self.config.method == "SH":
                msg = ("Pipes with invalid diameters: {0}.\nInvalid diameters: {1}.\n\n"
                        "A diameter value is considered invalid if it is zero, negative, NULL "
                        "or greater than the maximum diameter in the configuration table. "
                        "As a result, these pipes will NOT be assigned a priority value.\n\n"
                        "Do you want to proceed?")
                msg_params = (row["qtd"], row["list"],)
                if not tools_qt.show_question(msg, force_action=True, msg_params=msg_params):
                    return
            elif row["check"] == "invalid_materials":
                main_msg = tools_qt.tr(
                    "A material is considered invalid if it is not listed in the material configuration table."
                )
                main_msg += " "
                if config_material.has_material(self.config.unknown_material):
                    msg_line = ("As a result, the material of these pipes will be treated "
                                "as the configured unknown material, {0}.")
                    msg_params = (self.config.unknown_material,)
                    main_msg += tools_qt.tr(msg_line, list_params=msg_params)
                else:
                    msg_line = ("These pipes will NOT be assigned a priority value "
                                "as the configured unknown material, {0}, "
                                "is not listed in the configuration tab for materials.")
                    msg_params = (self.config.unknown_material,)
                    main_msg += tools_qt.tr(msg_line, list_params=msg_params)
                msg = (
                    tools_qt.tr("Pipes with invalid materials: {0}.", list_params=(row["qtd"]))
                    + "\n"
                    + tools_qt.tr("Invalid materials: {0}.", list_params=(row["list"]))
                    + "\n\n"
                    + main_msg
                    + "\n\n"
                    + tools_qt.tr("Do you want to proceed?")
                )
                if not tools_qt.show_question(msg, force_action=True):
                    return
            elif row["check"] == "null_pressures" and self.config.method == "WM":
                msg = ("Pipes with invalid pressures: {0}.\n"
                        "These pipes have no pressure information for their nodes. "
                        "This will result in them receiving the maximum longevity value for their material, "
                        "which may affect the final priority value.\n\n"
                        "Do you want to proceed?")
                msg_params = (row["qtd"],)
                if not tools_qt.show_question(msg, force_action=True, msg_params=msg_params):
                    return

        self.thread = GwCalculatePriority(
            tools_qt.tr("Calculate Priority"),
            self.type,
            result_name,
            result_description,
            status,
            features,
            exploitation,
            presszone,
            diameter,
            material,
            budget,
            target_year,
            config_catalog,
            config_material,
            config_engine,
        )
        t = self.thread
        t.taskCompleted.connect(self._calculate_ended)
        t.taskTerminated.connect(self._calculate_ended)

        # Set timer
        self.t0 = time()
        self.timer = QTimer()
        self.timer.timeout.connect(partial(self._update_timer, dlg.lbl_timer))
        self.timer.start(250)

        # Log behavior
        t.report.connect(
            partial(tools_gw.fill_tab_log, dlg, reset_text=False, close=False)
        )

        # Progress bar behavior
        t.progressChanged.connect(lambda value: dlg.progressBar.setValue(int(value)))

        # dlg.executing = True
        QgsApplication.taskManager().addTask(t)

    # region Selection

    def _snap_clicked(self):
        """Set canvas map tool to an instance of class 'GwSelectManager'"""
        self.rel_feature_type = "arc"
        layer = tools_qgis.get_layer_by_tablename(self.layer_to_work)
        self.rel_layers["arc"].append(layer)

        # Remove all previous selections
        self.rel_layers = tools_gw.remove_selection(True, layers=self.rel_layers)

        # In case of "duplicate" or "edit", load result selection
        if self.result["features"]:
            select_fid = []
            self.list_ids["arc"] = []
            for feature in layer.getFeatures():
                if feature["arc_id"] in self.result["features"]:
                    select_fid.append(feature.id())
                    self.list_ids["arc"].append(feature["arc_id"])
            layer.select(select_fid)

        if layer is None:
            # show warning
            tools_qgis.show_warning("For select on canvas is mandatory to load v_asset_arc_input layer", dialog=self.dlg_priority)
            return
        tools_gw.selection_init(self, self.dlg_priority, self.layer_to_work)

    def old_manage_btn_snapping(self):
        """Fill btn_snapping QMenu"""

        # Functions
        icons_folder = os.path.join(
            lib_vars.plugin_dir, f"icons{os.sep}dialogs{os.sep}svg"
        )

        values = [
            [
                0,
                "Select Feature(s)",
                os.path.join(icons_folder, "mActionSelectRectangle.svg"),
            ],
            [
                1,
                "Select Features by Polygon",
                os.path.join(icons_folder, "mActionSelectPolygon.svg"),
            ],
            [
                2,
                "Select Features by Freehand",
                os.path.join(icons_folder, "mActionSelectRadius.svg"),
            ],
            [
                3,
                "Select Features by Radius",
                os.path.join(icons_folder, "mActionSelectRadius.svg"),
            ],
        ]

        # Create and populate QMenu
        select_menu = QMenu()
        for value in values:
            num = value[0]
            label = value[1]
            icon = QIcon(value[2])
            action = select_menu.addAction(icon, f"{label}")
            action.triggered.connect(partial(self._trigger_action_select, num))

        self.dlg_priority.btn_snapping.setMenu(select_menu)

    def _trigger_action_select(self, num):

        # Set active layer
        layer = tools_qgis.get_layer_by_tablename(self.layer_to_work)
        self.iface.setActiveLayer(layer)

        if num == 0:
            self.iface.actionSelect().trigger()
        elif num == 1:
            self.iface.actionSelectPolygon().trigger()
        elif num == 2:
            self.iface.actionSelectFreehand().trigger()
        elif num == 3:
            self.iface.actionSelectRadius().trigger()

    def _selection_init(self):
        """Set canvas map tool to an instance of class 'GwSelectManager'"""

        # tools_gw.disconnect_signal('feature_delete')
        self.iface.actionSelect().trigger()
        # self.connect_signal_selection_changed()

    # endregion

    def _save2file(self):
        if not hasattr(self.thread, "df"):
            return

        file_path = tools_qt.get_save_file_path(self.dlg_priority, '', "*.xlsx", "Save file")
        fp = Path(file_path)
        self.thread.df.to_excel(file_path)

        msg = "{0} successfully saved."
        msg_params = (fp.name,)
        tools_qt.show_info_box(msg, msg_params=msg_params)

    def _set_signals(self):
        dlg = self.dlg_priority
        dlg.btn_accept.clicked.connect(self._manage_calculate)
        dlg.btn_again.clicked.connect(self._go_first_tab)
        dlg.btn_close.clicked.connect(self.close_dlg)
        dlg.rejected.connect(self.close_dlg)
        dlg.btn_save2file.clicked.connect(self._save2file)
        dlg.cmb_expl_selection.currentIndexChanged.connect(partial(self._load_presszone))
        dlg.cmb_presszone.currentIndexChanged.connect(partial(self._load_diameter))
        dlg.cmb_dnom.currentIndexChanged.connect(partial(self._load_material))
        dlg.btn_add_catalog.clicked.connect(
            partial(self._manage_qtw_row, dlg, dlg.tbl_catalog, "add")
        )
        dlg.btn_remove_catalog.clicked.connect(
            partial(self._manage_qtw_row, dlg, dlg.tbl_catalog, "remove")
        )
        dlg.btn_add_material.clicked.connect(
            partial(self._manage_qtw_row, dlg, dlg.tbl_material, "add")
        )
        dlg.btn_remove_material.clicked.connect(
            partial(self._manage_qtw_row, dlg, dlg.tbl_material, "remove")
        )

        if self.config.method == "WM":
            for widget in self._get_weight_widgets("lyt_engine_1"):
                widget.textChanged.connect(
                    partial(self._update_total_weight, "lyt_engine_1")
                )

        for widget in self._get_weight_widgets("lyt_engine_2"):
            widget.textChanged.connect(
                partial(self._update_total_weight, "lyt_engine_2")
            )

    def close_dlg(self):
        """ Close dialog """
        tools_qgis.disconnect_signal_selection_changed()
        tools_gw.remove_selection(True, layers=self.rel_layers)
        tools_gw.close_dialog(self.dlg_priority)

    def _go_first_tab(self):
        # Reset tab
        dlg = self.dlg_priority
        tools_gw.disable_tab_log(dlg)

        # Enable first tab
        dlg.mainTab.setTabEnabled(0, True)

        # Reset buttons
        dlg.btn_accept.setVisible(True)
        dlg.btn_again.setVisible(False)

    def _manage_qtw_row(self, dialog, widget, action):
        if action == "add":
            row_count = widget.rowCount()
            widget.insertRow(row_count)
            widget.setCurrentCell(row_count, 0)
        elif action == "remove":
            selected_row = widget.currentRow()
            if selected_row != -1:
                widget.removeRow(selected_row)

    def _update_timer(self, widget):
        elapsed_time = time() - self.t0
        text = str(timedelta(seconds=round(elapsed_time)))
        widget.setText(text)

    def _update_total_weight(self, lyt):
        label = getattr(self.dlg_priority, f"total_{lyt}", None)
        if not label:
            return
        try:
            total = 0
            for widget in self._get_weight_widgets(lyt):
                total += float(widget.text())
            self.total_weight[lyt] = total
            label.setText(str(round(self.total_weight[lyt], 2)))
        except Exception:
            self.total_weight[lyt] = None
            label.setText("Error")

    def _validate_inputs(self):
        dlg = self.dlg_priority

        result_name = dlg.txt_result_id.text()
        if not result_name:
            msg = "Please provide a result name."
            tools_qt.show_info_box(msg)
            return
        if self.mode != "edit" and tools_db.get_row(
            f"""
            select * from am.cat_result
            where result_name = '{result_name}'
            """
        ):
            msg = "This result name already exists"
            info = "Please choose a different name."
            tools_qt.show_info_box(
                msg,
                title="Info",
                inf_text=info,
                parameter=result_name,
            )
            return

        result_description = self.dlg_priority.txt_descript.text()
        status = tools_qt.get_combo_value(dlg, dlg.cmb_status)

        features = None
        try:
            layer = tools_qgis.get_layer_by_tablename(self.layer_to_work)
            if layer is not None and layer.selectedFeatureCount() > 0:
                features = layer.selectedFeatures()
                features = [str(feature.id()) for feature in features]
        except Exception:
            pass

        exploitation = tools_qt.get_combo_value(dlg, "cmb_expl_selection") or None
        presszone = tools_qt.get_combo_value(dlg, "cmb_presszone")
        diameter = tools_qt.get_combo_value(dlg, "cmb_dnom") or None
        diameter = f"{diameter:g}" if diameter else None
        material = tools_qt.get_combo_value(dlg, "cmb_material") or None

        try:
            budget = float(dlg.txt_budget.text())
        except ValueError:
            if self.config.method == "SH":
                budget = None
            else:
                msg = "Please enter a valid number for the budget."
                tools_qt.show_info_box(msg)
                return

        target_year = dlg.txt_year.text() or None
        if self.config.method == "WM" and not target_year or not target_year.isdigit():
            msg = "Please enter a valid target year."
            tools_qt.show_info_box(msg)
            return
        target_year = int(target_year)
        if target_year <= date.today().year or target_year > date.today().year + 100:
            msg = "The target year must be between {0} and {1}."
            msg_params = (date.today().year + 1, date.today().year + 100,)
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return
        try:
            key = "arccat_id"
            config_catalog = configcatalog_from_tablewidget(self.qtbl_catalog, key)
        except ValueError as e:
            tools_qt.show_info_box(e)
            return

        try:
            config_material = configmaterial_from_tablewidget(
                self.qtbl_material, self.config.unknown_material
            )
        except ValueError as e:
            tools_qt.show_info_box(e)
            return

        if any(round(total, 5) != 1 for total in self.total_weight.values()):
            msg = "The sum of weights must equal 1. Please adjust the values accordingly."
            tools_qt.show_info_box(msg)
            return
        config_engine = {}
        for field in self.config_engine_fields:
            widget_name = field["widgetname"]
            try:
                config_engine[widget_name] = float(
                    tools_qt.get_widget(dlg, widget_name).text()
                )
            except Exception:
                msg = "Invalid value for field"
                info = "Please enter a valid number."
                tools_qt.show_info_box(
                    msg,
                    inf_text=info,
                    parameter=field["label"],
                )
                return

        return (
            result_name,
            result_description,
            status,
            features,
            exploitation,
            presszone,
            diameter,
            material,
            budget,
            target_year,
            config_catalog,
            config_material,
            config_engine,
        )

    # region Attribute

    def _manage_attr(self):

        dlg = self.dlg_priority

        # Combo status
        rows = tools_db.get_rows("SELECT id, idval FROM am.value_status")
        tools_qt.fill_combo_values(dlg.cmb_status, rows, 1)
        tools_qt.set_combo_value(dlg.cmb_status, "ON PLANNING", 0, add_new=False)
        tools_qt.set_combo_item_select_unselectable(
            dlg.cmb_status, list_id=["FINISHED"]
        )

        # Text result_id
        tools_qt.set_widget_text(dlg, dlg.txt_result_id, self.result["name"])

        # Text descript
        tools_qt.set_widget_text(dlg, dlg.txt_descript, self.result["descript"])

        # Combo exploitation
        sql = f"""
            SELECT DISTINCT(expl.expl_id) as id, expl.name as idval 
            FROM {lib_vars.schema_name}.exploitation expl 
            INNER JOIN am.ext_arc_asset ext ON expl.expl_id = ext.expl_id;
            """

        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(dlg.cmb_expl_selection, rows, 1, add_empty=True)
        tools_qt.set_combo_value(
            dlg.cmb_expl_selection,
            dlg.cmb_expl_selection.itemText(0),
            0,
            add_new=False,
        )

        # Load presszone combo
        self._load_presszone()

        # Text budget
        tools_qt.set_widget_text(dlg, dlg.txt_budget, self.result["budget"])

        # Text horizon year
        tools_qt.set_widget_text(dlg, dlg.txt_year, self.result["budget"])

    # endregion

    def _load_presszone(self):
        dlg = self.dlg_priority
        exploitation = tools_qt.get_combo_value(dlg, "cmb_expl_selection")
        if exploitation == "":
            tools_qt.fill_combo_values(dlg.cmb_presszone, None, 1, combo_clear=True)
            tools_qt.fill_combo_values(dlg.cmb_dnom, None, 1, combo_clear=True)
            tools_qt.fill_combo_values(dlg.cmb_material, None, 1, combo_clear=True)
            return
        sql = f"""           
            SELECT DISTINCT ON (ext.presszone_id) 
                ext.presszone_id AS id, 
                CONCAT(ext.presszone_id, ' - ', pres.name) AS idval
            FROM {lib_vars.schema_name}.presszone pres 
            INNER JOIN am.ext_arc_asset ext 
                ON ext.expl_id = ANY(pres.expl_id)
            WHERE ext.expl_id = {exploitation} 
            ORDER BY ext.presszone_id;
            """
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(dlg.cmb_presszone, rows, 1, add_empty=True)

        self._load_diameter()

    def _load_diameter(self):
        dlg = self.dlg_priority
        presszone = tools_qt.get_combo_value(dlg, "cmb_presszone")
        exploitation = tools_qt.get_combo_value(dlg, "cmb_expl_selection")
        if presszone == "":
            tools_qt.fill_combo_values(dlg.cmb_dnom, None, 1, combo_clear=True)
            tools_qt.fill_combo_values(dlg.cmb_material, None, 1, combo_clear=True)
            return
        sql = f"""
            SELECT distinct(dnom::float) AS id, dnom as idval 
            FROM am.ext_arc_asset WHERE presszone_id = '{presszone}' 
            AND expl_id = {exploitation}
            AND dnom is not null ORDER BY id;
            """
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(dlg.cmb_dnom, rows, 1, add_empty=True)

        self._load_material()

    def _load_material(self):
        dlg = self.dlg_priority
        presszone = tools_qt.get_combo_value(dlg, "cmb_presszone")
        exploitation = tools_qt.get_combo_value(dlg, "cmb_expl_selection")
        dnom = tools_qt.get_combo_value(dlg, "cmb_dnom")

        if dnom == "":
            tools_qt.fill_combo_values(dlg.cmb_material, None, 1, combo_clear=True)
            return

        sql = f"""
            SELECT distinct(matcat_id) AS id, matcat_id as idval 
            FROM am.ext_arc_asset WHERE presszone_id = '{presszone}' 
            AND expl_id = {exploitation} AND dnom::float ={dnom} ORDER BY id;
            """
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(dlg.cmb_material, rows, 1, add_empty=True)

    def _fill_table(
        self,
        dialog,
        widget,
        table_name,
        hidde=False,
        set_edit_triggers=QTableView.EditTrigger.NoEditTriggers,
        expr=None,
    ):
        """Set a model with selected filter.
        Attach that model to selected table
        @setEditStrategy:
        0: OnFieldChange
        1: OnRowChange
        2: OnManualSubmit
        """
        try:

            # Set model
            model = QSqlTableModel(db=lib_vars.qgis_db_credentials)
            model.setTable(table_name)
            model.setEditStrategy(QSqlTableModel.EditStrategy.OnManualSubmit)
            model.setSort(0, Qt.SortOrder.AscendingOrder)
            model.select()

            # When change some field we need to refresh Qtableview and filter by psector_id
            # model.dataChanged.connect(partial(self._refresh_table, dialog, widget))
            widget.setEditTriggers(set_edit_triggers)

            # Check for errors
            if model.lastError().isValid():
                print(f"ERROR -> {model.lastError().text()}")

            # Attach model to table view
            if expr:
                widget.setModel(model)
                widget.model().setFilter(expr)
            else:
                widget.setModel(model)

            if hidde:
                self.refresh_table(dialog, widget)
        except Exception as e:
            print(f"EXCEPTION -> {e}")
