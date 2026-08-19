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
    QGridLayout,
    QLabel,
    QMenu,
    QAbstractItemView,
    QHeaderView,
    QTableView,
    QTableWidget,
    QTableWidgetItem,
    QCheckBox,
)
from qgis.PyQt.QtGui import QIcon, QFont
from qgis.PyQt.QtSql import QSqlTableModel

from .... import global_vars

from ....libs import lib_vars, tools_qgis, tools_db, tools_qt
from ...utils import tools_gw
from ..dialog import GwAction


from ...ui.ui_manager import GwPriorityUi
from ...threads.calculatepriority import GwCalculatePriority
from .result_selector_btn import set_am_selector_result


class GwConfigCatalogButton:
    """ARC: key=arccat_id → am.config_catalog; NODE: key=nodecat_id → am.config_nodecatalog."""

    def __init__(self, data, key="arccat_id", save_table="config_catalog"):
        """ Build catalog config index keyed by arccat_id or nodecat_id """
        self._key = key
        self._save_table = save_table
        self._data = {}
        for entry in sorted(
            data or [],
            key=lambda i: (
                i.get("dnom") is None,
                i.get("dnom") if i.get("dnom") is not None else 0,
                str(i.get(key) or ""),
            ),
        ):
            entry_key = entry.get(key)
            if entry_key in self._data:
                raise ValueError(
                    f"Key ({key}) is not unique in the config catalog."
                )
            self._data[entry_key] = entry

    def arccat_ids(self):
        """ Return list of arccat_id values in catalog config """
        return [x["arccat_id"] for x in self._data.values() if x.get("arccat_id")]

    def catalog_ids(self):
        """ Return list of catalog keys """
        return list(self._data.keys())

    def diameters(self):
        """ Return list of nominal diameters in catalog config """
        return [x["dnom"] for x in self._data.values()]

    def fill_table_widget(self, table_widget):
        """ Fill catalog table widget from in-memory config """
        id_header = {
            "nodecat_id": "Nodecat_id",
            "linkcat_id": "Linkcat_id",
        }.get(self._key, "Arccat_id")
        if self._key == "linkcat_id":
            cost_headers = [tools_qt.tr("Fixed cost"), tools_qt.tr("Pipe cost (€/m)")]
        else:
            cost_headers = [tools_qt.tr("Renewal cost"), tools_qt.tr("Repair cost")]
        headers = [
            id_header,
            tools_qt.tr("Diameter"),
            *cost_headers,
            tools_qt.tr("Compliance Grade"),
            tools_qt.tr("Material"),
        ]
        if self._key == "linkcat_id":
            headers.extend([tools_qt.tr("Surface"), tools_qt.tr("Default length (m)")])
        table_widget.setRowCount(0)
        table_widget.setColumnCount(len(headers))
        table_widget.setHorizontalHeaderLabels(headers)
        for r, row in enumerate(self._data.values()):
            table_widget.insertRow(r)
            table_widget.setItem(r, 0, QTableWidgetItem(str(row.get(self._key) or "")))
            table_widget.setItem(r, 1, QTableWidgetItem(str(row.get("dnom"))))
            table_widget.setItem(r, 2, QTableWidgetItem(str(row.get("cost_constr"))))
            table_widget.setItem(r, 3, QTableWidgetItem(str(row.get("cost_repmain"))))
            table_widget.setItem(r, 4, QTableWidgetItem(str(row.get("compliance"))))
            table_widget.setItem(r, 5, QTableWidgetItem(str(row.get("matcat_id") or "")))
            if self._key == "linkcat_id":
                table_widget.setItem(r, 6, QTableWidgetItem(str(row.get("surface_type") or "")))
                table_widget.setItem(r, 7, QTableWidgetItem(str(row.get("default_length") or "")))

    def get_compliance(self, key):
        """ Return compliance grade for the catalog key """
        return self._data[key]["compliance"]

    def get_cost_constr(self, key):
        """ Return replacement construction cost for the catalog key """
        return self._data[key]["cost_constr"]

    def get_cost_repmain(self, key):
        """ Return repair maintenance cost for the catalog key """
        return self._data[key]["cost_repmain"]

    def get_default_length(self, key):
        """ODT default_length when geometry length is null."""
        return self._data[key].get("default_length")

    def get_surface_type(self, key):
        """ODT surface_type catalog classifier."""
        return self._data[key].get("surface_type")

    def has_key(self, key):
        """ Return whether the catalog key exists """
        return key in self._data

    def max_diameter(self):
        """ Return maximum nominal diameter in catalog config """
        values = [x["dnom"] for x in self._data.values() if x.get("dnom") is not None]
        return max(values) if values else 0

    def save(self, result_id):
        """ Persist catalog config rows for the result_id """
        if not self._data:
            tools_db.execute_sql(
                f"delete from am.{self._save_table} where result_id = {result_id};"
            )
            return
        extra_cols = ""
        if self._key == "linkcat_id":
            extra_cols = ", surface_type, default_length"
        sql = f"""
            delete from am.{self._save_table} where result_id = {result_id};
            insert into am.{self._save_table}
                (result_id, {self._key}, dnom, cost_constr, cost_repmain, compliance{extra_cols})
            values
        """
        for value in self._data.values():
            dnom = value.get("dnom")
            dnom_sql = "NULL" if dnom is None or dnom == "" or dnom == "None" else dnom
            extra_vals = ""
            if self._key == "linkcat_id":
                surface = value.get("surface_type")
                surface_sql = (
                    "NULL" if not surface or surface in ("None", "NULL")
                    else f"'{str(surface).replace(chr(39), chr(39)+chr(39))}'"
                )
                dlen = value.get("default_length")
                dlen_sql = "NULL" if dlen in (None, "", "None", "NULL") else dlen
                extra_vals = f", {surface_sql}, {dlen_sql}"
            sql += f"""
                ({result_id},
                '{value[self._key]}',
                {dnom_sql},
                {value["cost_constr"]},
                {value["cost_repmain"]},
                {value["compliance"]}{extra_vals}),
            """
        sql = sql.strip()[:-1]
        tools_db.execute_sql(sql)


def configcatalog_from_tablewidget(table_widget, key="arccat_id", save_table="config_catalog"):
    """ Build GwConfigCatalogButton from catalog table widget rows """
    data = []
    for r in range(table_widget.rowCount()):
        dnom_text = table_widget.item(r, 1).text()
        try:
            dnom = float(dnom_text) if dnom_text not in ("", "None", "NULL") else None
        except ValueError:
            dnom = None
        row = {
            key: table_widget.item(r, 0).text(),
            "dnom": dnom,
            "cost_constr": float(table_widget.item(r, 2).text()),
            "cost_repmain": float(table_widget.item(r, 3).text()),
            "compliance": int(table_widget.item(r, 4).text()),
            "matcat_id": table_widget.item(r, 5).text(),
        }
        if key == "linkcat_id" and table_widget.columnCount() > 7:
            surf_item = table_widget.item(r, 6)
            dlen_item = table_widget.item(r, 7)
            row["surface_type"] = surf_item.text() if surf_item and surf_item.text() not in ("", "None") else None
            try:
                row["default_length"] = (
                    float(dlen_item.text())
                    if dlen_item and dlen_item.text() not in ("", "None", "NULL")
                    else None
                )
            except (ValueError, AttributeError):
                row["default_length"] = None
        data.append(row)
    return GwConfigCatalogButton(data, key, save_table=save_table)


class ConfigMaterial:
    def __init__(self, data, unknown_material):
        """ Build material config index sorted by material id """
        # order the dict by material
        self._data = {k: data[k] for k in sorted(data.keys())}
        self._unknown_material = unknown_material

    def fill_table_widget(self, table_widget):
        """ Fill material table widget from in-memory config """
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
        table_widget.setRowCount(0)
        table_widget.setColumnCount(len(headers))
        table_widget.setHorizontalHeaderLabels(headers)
        for r, row in enumerate(self._data.values()):
            table_widget.insertRow(r)
            for c, column in enumerate(columns):
                table_widget.setItem(r, c, QTableWidgetItem(str(row[column])))

    def get_age(self, material, pression):
        """ Return expected useful life for material and pressure """
        if pression < 50:
            return self._get_attr(material, "age_max")
        elif pression < 75:
            return self._get_attr(material, "age_med")
        else:
            return self._get_attr(material, "age_min")

    def get_compliance(self, material):
        """ Return compliance grade for the material """
        return self._get_attr(material, "compliance")

    def get_default_builtdate(self, material):
        """ Return default built date for the material """
        return self._get_attr(material, "builtdate_vdef")

    def get_pleak(self, material):
        """ Return probability of failure for the material """
        return self._get_attr(material, "pleak")

    def has_material(self, material):
        """ Return whether the material exists in config """
        return material in self._data

    def materials(self):
        """ Return configured material identifiers """
        return self._data.keys()

    def save(self, result_id):
        """ Persist material config rows for the result_id """
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
        """ Return material attribute or unknown-material fallback """
        if material in self._data:
            return self._data[material][attribute]
        return self._data[self._unknown_material][attribute]


def configmaterial_from_sql(sql, unknown_material):
    """ Build ConfigMaterial from SQL query rows """
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
    """ Build ConfigMaterial from material table widget rows """
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
        """ Initialise selection priority toolbar action """
        super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.iface = global_vars.iface

        self.icon_path = icon_path
        self.action_name = action_name
        self.text = text
        self.toolbar = toolbar
        self.action_group = action_group

    def clicked_event(self):
        """ Open selection priority calculation dialog """
        calculate_priority = CalculatePriority(type="SELECTION")
        calculate_priority.clicked_event()


class CalculatePriorityConfig:
    def __init__(self, type):
        """ Load priority dialog visibility flags from giswater.config """
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
        """ Initialise priority calculation state for new, edit or duplicate mode """
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
                "nodecat_id": None,
                "node_type": None,
                "asset_type": "ARC",
                "linked_arc_result_id": None,
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
                    dnom,
                    nodecat_id,
                    node_type,
                    asset_type,
                    linked_arc_result_id
                FROM am.cat_result
                WHERE result_id = {result_id}
                """
            )
        self.type = type if mode == "new" else self.result["type"]
        self.mode = mode
        self.asset_type = self.result.get("asset_type") or "ARC"
        self.layer_to_work = {
            "ARC": "v_asset_arc_input",
            "NODE": "v_asset_node_input",
            "LINK": "v_asset_link_input",
        }.get(self.asset_type, "v_asset_arc_input")
        self.rel_layers = {"arc": [], "node": [], "link": []}
        self.excluded_layers = []
        self.list_ids = {}
        self.config = CalculatePriorityConfig(type)
        self.total_weight = {}

        # Priority variables
        self.dlg_priority = None

    @property
    def _asset_table(self):
        """Name of the WS integration view backing the current asset_type."""
        return {
            "ARC": "ext_arc_asset",
            "NODE": "ext_node_asset",
            "LINK": "ext_link_asset",
        }.get(self.asset_type, "ext_arc_asset")

    def clicked_event(self):
        """ Open priority dialog and load catalog, material and engine tabs """
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

        self._fill_asset_type_combo()
        self._apply_asset_type_ui()

        # Hidden widgets
        self._manage_hidden_form()

        # Manage selection group
        self.dlg_priority.btn_snapping.clicked.connect(partial(self._snap_clicked))

        # Manage attributes group
        self._manage_attr()

        # Define tableviews (Catalog by asset_type; Material shared ARC/NODE)
        self.qtbl_catalog = self.dlg_priority.findChild(QTableWidget, "tbl_catalog")
        self.qtbl_material = self.dlg_priority.findChild(QTableWidget, "tbl_material")
        self.qtbl_catalog.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.qtbl_catalog.setSortingEnabled(True)
        if not self._load_catalog_table():
            return None

        self.qtbl_material.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self._load_material_table()

        self._fill_engine_options()
        self._load_arc_result_combo()
        # After combo restore (edit/duplicate): unlock Affected Arcs if ARC is linked
        self._sync_affected_arcs_widget()
        self._set_signals()

        self.dlg_priority.executing = False

        self.dlg_priority.btn_again.setVisible(False)
        # Open the dialog
        tools_gw.open_dialog(self.dlg_priority, dlg_name="priority")

    def _add_total(self, lyt):
        """ Add total weight label to engine parameter layout """
        lbl = QLabel()
        lbl.setText(tools_qt.tr("Total"))
        value = QLabel()
        position_config = {"layoutname": lyt, "layoutorder": 100}
        tools_gw.add_widget(self.dlg_priority, position_config, lbl, value)
        setattr(self.dlg_priority, f"total_{lyt}", value)
        self._update_total_weight(lyt)

    def _calculate_ended(self):
        """ Handle UI state when priority calculation task finishes """
        dlg = self.dlg_priority

        dlg.btn_again.setVisible(True)

        # Check if thread is finished wuih success
        if hasattr(self.thread, "df"):
            # Button OK behavior
            msg = "Next"
            tools_qt.set_widget_text(dlg, dlg.btn_again, msg)
            dlg.btn_save2file.setEnabled(True)
            dlg.progressBar.setValue(100)
            self._activate_result_and_refresh_symbology()
        else:
            dlg.progressBar.setValue(100)
            msg = "Try again"
            tools_qt.set_widget_text(dlg, dlg.btn_again, msg)
        dlg.executing = False
        self.timer.stop()

    def _activate_result_and_refresh_symbology(self):
        """ Point selectors at the new result, reload AM layers, rebuild year classes. """
        result_id = getattr(self.thread, "result_id", None)
        if result_id:
            # Keep the other feature's selection (ARC vs NODE) visible on the map
            set_am_selector_result(result_id, "main")

        for layer_name in (
            "v_asset_arc_output",
            "v_asset_arc_output_compare",
            "v_asset_node_output",
            "v_asset_node_output_compare",
            "v_asset_link_output",
            "v_asset_link_output_compare",
            "v_asset_arc_corporate",
            "v_asset_node_corporate",
        ):
            # AM layers live in schema am; set_layer_index() defaults to parent schema
            layer = tools_qgis.get_layer_by_tablename(layer_name, schema_name="am")
            if layer:
                layer.dataProvider().reloadData()
                layer.triggerRepaint()

        if not lib_vars.schema_name:
            return
        try:
            rows = tools_db.get_rows(
                f"SELECT id, addparam FROM {lib_vars.schema_name}.sys_table "
                "WHERE source = 'am' AND addparam ->> 'refreshSymbology' = 'true'"
            ) or []
            target_layers = []
            for row in rows:
                target_layer = tools_qgis.get_layer_by_tablename(row[0], schema_name="am")
                if target_layer is not None:
                    target_layers.append((target_layer, row[1]))
            if not target_layers:
                return
            if tools_qt.show_question(
                "Do you want to update the symbology of the layers currently loaded in the project?",
                "Update AM Layers Symbology",
                force_action=True,
            ):
                for layer, addparam in target_layers:
                    tools_gw.refresh_categorized_layer_symbology_classes(layer, addparam)
        except Exception:
            pass

    def _cancel_thread(self, dlg):
        """ Cancel running priority calculation task """
        self.thread.cancel()
        tools_gw.fill_tab_log(
            dlg,
            {"info": {"values": [{"message": tools_qt.tr("Canceling task...")}]}},
            reset_text=False,
            close=False,
        )

    def _fill_asset_type_combo(self):
        """ Fill asset type combo with ARC, NODE and LINK """
        dlg = self.dlg_priority
        rows = [
            ("ARC", tools_qt.tr("ARC")),
            ("NODE", tools_qt.tr("NODE")),
            ("LINK", tools_qt.tr("LINK")),
        ]
        tools_qt.fill_combo_values(dlg.cmb_asset_type, rows, 1)
        tools_qt.set_combo_value(dlg.cmb_asset_type, self.asset_type, 0, add_new=False)
        if self.mode != "new":
            # Switching asset_type on an existing result would orphan its input/config data
            dlg.cmb_asset_type.setEnabled(False)

    def _apply_asset_type_ui(self):
        """ Adjust selection labels and layer for asset type """
        dlg = self.dlg_priority
        is_node = self.asset_type == "NODE"
        is_link = self.asset_type == "LINK"
        self.layer_to_work = {
            "ARC": "v_asset_arc_input",
            "NODE": "v_asset_node_input",
            "LINK": "v_asset_link_input",
        }.get(self.asset_type, "v_asset_arc_input")
        if is_node:
            tools_qt.set_widget_text(dlg, dlg.lbl_dnom, tools_qt.tr("Node category:"))
            tools_qt.set_widget_text(dlg, dlg.lbl_material, tools_qt.tr("Node type:"))
        elif is_link:
            tools_qt.set_widget_text(dlg, dlg.lbl_dnom, tools_qt.tr("Link catalog:"))
            tools_qt.set_widget_text(dlg, dlg.lbl_material, tools_qt.tr("Material:"))
        else:
            tools_qt.set_widget_text(dlg, dlg.lbl_dnom, tools_qt.tr("Diameter:"))
            tools_qt.set_widget_text(dlg, dlg.lbl_material, tools_qt.tr("Material:"))
        # Features tab (node types) only for NODE; hide single node_type combo in Selection
        self._set_config_tab_visible("tab_features", is_node)
        self._set_arc_result_combo_visible()
        if is_node:
            dlg.lbl_material.setVisible(False)
            dlg.cmb_material.setVisible(False)
            self._load_node_types()
            if hasattr(dlg, "tab_features"):
                idx = dlg.tab_widget.indexOf(dlg.tab_features)
                if idx >= 0:
                    dlg.tab_widget.setCurrentIndex(idx)
        else:
            self._clear_node_type_widgets()
            dlg.lbl_material.setVisible(True)
            dlg.cmb_material.setVisible(True)
            if not is_link:
                tools_qt.set_widget_text(dlg, dlg.lbl_material, tools_qt.tr("Material:"))
            if hasattr(dlg, "cmb_arc_result") and not is_link:
                blocked = dlg.cmb_arc_result.blockSignals(True)
                dlg.cmb_arc_result.setCurrentIndex(0)
                dlg.cmb_arc_result.blockSignals(blocked)
                dlg.txt_year.setEnabled(True)

    def _selected_asset_ids(self):
        """Map selection as business IDs (link_id / arc_id / node_id), not Qgs fids."""
        id_field = {"ARC": "arc_id", "NODE": "node_id", "LINK": "link_id"}.get(
            self.asset_type, "arc_id"
        )
        layer = tools_qgis.get_layer_by_tablename(self.layer_to_work, schema_name="am")
        if layer is not None and layer.selectedFeatureCount() > 0:
            ids = []
            for feat in layer.selectedFeatures():
                val = feat[id_field]
                if val is not None:
                    ids.append(str(val))
            if ids:
                return ids
        feat_type = {"ARC": "arc", "NODE": "node", "LINK": "link"}.get(self.asset_type)
        stored = (self.list_ids or {}).get(feat_type) or (getattr(self, "rel_list_ids", {}) or {}).get(feat_type)
        if stored:
            return [str(x) for x in stored]
        return None

    def _catalog_config(self):
        """Return (sql, key, save_table) for the current asset_type / dialog mode."""
        # Qualify parent-schema catalogs: AM fns often SET search_path = am, public
        parent = lib_vars.schema_name
        if self.asset_type == "NODE":
            if self.mode == "new":
                sql = (
                    "select d.*, cat_node.matcat_id "
                    "from am.config_nodecatalog_def d "
                    f"JOIN {parent}.cat_node ON d.nodecat_id = cat_node.id"
                )
            else:
                sql = (
                    "select d.*, cat_node.matcat_id "
                    "from am.config_nodecatalog d "
                    f"JOIN {parent}.cat_node ON d.nodecat_id = cat_node.id "
                    f"where d.result_id = {self.result['id']}"
                )
            return sql, "nodecat_id", "config_nodecatalog"

        if self.asset_type == "LINK":
            if self.mode == "new":
                sql = (
                    "select d.*, cat_link.matcat_id "
                    "from am.config_linkcatalog_def d "
                    f"JOIN {parent}.cat_link ON d.linkcat_id = cat_link.id"
                )
            else:
                sql = (
                    "select d.*, cat_link.matcat_id "
                    "from am.config_linkcatalog d "
                    f"JOIN {parent}.cat_link ON d.linkcat_id = cat_link.id "
                    f"where d.result_id = {self.result['id']}"
                )
            return sql, "linkcat_id", "config_linkcatalog"

        if self.mode == "new":
            sql = (
                "select d.*, cat_arc.matcat_id "
                "from am.config_catalog_def d "
                f"JOIN {parent}.cat_arc ON d.arccat_id = cat_arc.id"
            )
        else:
            sql = (
                "select d.*, cat_arc.matcat_id "
                "from am.config_catalog d "
                f"JOIN {parent}.cat_arc ON d.arccat_id = cat_arc.id "
                f"where d.result_id = {self.result['id']}"
            )
        return sql, "arccat_id", "config_catalog"

    def _load_catalog_table(self):
        """Fill tbl_catalog from ARC or NODE config (mirrors sample/def → result snapshot)."""
        sql, key, save_table = self._catalog_config()
        try:
            configcatalog = GwConfigCatalogButton(
                tools_db.get_rows(sql) or [], key, save_table=save_table
            )
        except ValueError as e:
            tools_qgis.show_warning(str(e))
            return False
        configcatalog.fill_table_widget(self.qtbl_catalog)
        self.qtbl_catalog.horizontalHeader().setSectionResizeMode(
            QHeaderView.ResizeMode.Stretch
        )
        if self.config.method == "WM" and self.asset_type != "LINK":
            self.qtbl_catalog.hideColumn(1)
            self.qtbl_catalog.hideColumn(3)
        else:
            self.qtbl_catalog.showColumn(1)
            self.qtbl_catalog.showColumn(3)
        return True

    def _material_config_sql(self):
        """Material rows limited to cat_material.feature_type containing current asset_type.

        Always keep the configured unknown material so WM can fall back.
        """
        asset_type = self.asset_type or "ARC"
        unknown = (self.config.unknown_material or "").replace("'", "''")
        parent = lib_vars.schema_name
        if asset_type == "LINK":
            feature_filter = (
                f"('ARC' = ANY(m.feature_type) OR 'LINK' = ANY(m.feature_type) "
                f"OR m.feature_type IS NULL) OR d.material = '{unknown}'"
            )
        else:
            feature_filter = (
                f"(m.feature_type IS NOT NULL AND '{asset_type}' = ANY(m.feature_type))"
                f" OR d.material = '{unknown}'"
            )
        if self.mode == "new":
            return f"""
                select d.*
                from am.config_material_def d
                join {parent}.cat_material m on m.id = d.material
                where {feature_filter}
                order by d.material
            """
        return f"""
            select d.*
            from am.config_material d
            join {parent}.cat_material m on m.id = d.material
            where d.result_id = {self.result['id']}
              and ({feature_filter})
            order by d.material
        """

    def _load_material_table(self):
        """Fill tbl_material filtered by asset_type vs cat_material.feature_type."""
        sql = self._material_config_sql()
        configmaterial = configmaterial_from_sql(sql, self.config.unknown_material)
        configmaterial.fill_table_widget(self.qtbl_material)
        self.qtbl_material.horizontalHeader().setSectionResizeMode(
            QHeaderView.ResizeMode.Stretch
        )
        if self.config.method == "SH":
            for col in (1, 2, 3, 4, 5):
                self.qtbl_material.hideColumn(col)
        else:
            for col in (1, 2, 3, 4, 5):
                self.qtbl_material.showColumn(col)

    def _set_config_tab_visible(self, page_name, visible):
        """ Show or hide a config tab page """
        dlg = self.dlg_priority
        page = getattr(dlg, page_name, None)
        if page is None:
            return
        idx = dlg.tab_widget.indexOf(page)
        if idx >= 0:
            dlg.tab_widget.setTabVisible(idx, visible)

    def _clear_node_type_widgets(self):
        """Remove dynamically created node-type checkboxes."""
        dlg = self.dlg_priority
        layout = getattr(dlg, "lyt_node_types", None)
        if layout is None:
            return
        while layout.count():
            item = layout.takeAt(0)
            widget = item.widget()
            if widget is not None:
                # Do NOT setParent(None): that turns the widget into a top-level
                # window (empty QGIS popup with shadow) until deleteLater runs.
                widget.hide()
                widget.deleteLater()
        if hasattr(dlg, "lbl_features_count"):
            tools_qt.set_widget_text(
                dlg, dlg.lbl_features_count, tools_qt.tr("0 / 0 selected")
            )

    @staticmethod
    def _node_type_label(node_type):
        """Humanize DB id for display (AIR_VALVE → Air Valve)."""
        return str(node_type).replace("_", " ").title()

    def _iter_node_type_checks(self):
        """Yield QCheckBox widgets in the Features grid."""
        dlg = self.dlg_priority
        layout = getattr(dlg, "lyt_node_types", None)
        if layout is None:
            return
        for i in range(layout.count()):
            widget = layout.itemAt(i).widget()
            if isinstance(widget, QCheckBox):
                yield widget

    def _update_features_count(self):
        """Refresh 'n / total selected' label on Features tab."""
        dlg = self.dlg_priority
        if not hasattr(dlg, "lbl_features_count"):
            return
        checks = list(self._iter_node_type_checks())
        total = len(checks)
        selected = sum(1 for chk in checks if chk.isChecked())
        tools_qt.set_widget_text(
            dlg,
            dlg.lbl_features_count,
            tools_qt.tr("{0} / {1} selected").format(selected, total),
        )

    def _set_all_node_types(self, checked):
        """Select all / clear Features checkboxes."""
        for chk in self._iter_node_type_checks():
            chk.blockSignals(True)
            chk.setChecked(checked)
            chk.blockSignals(False)
        self._update_features_count()

    def _load_node_types(self):
        """Fill Features grid with node_types matching expl / presszone / nodecat."""
        dlg = self.dlg_priority
        if not hasattr(dlg, "lyt_node_types") or self.asset_type != "NODE":
            return

        previous_state = {
            chk.property("node_type"): chk.isChecked()
            for chk in self._iter_node_type_checks()
        }
        self._clear_node_type_widgets()
        layout = dlg.lyt_node_types

        filters = ["node_type IS NOT NULL"]
        exploitation = tools_qt.get_combo_value(dlg, "cmb_expl_selection") or None
        presszone = tools_qt.get_combo_value(dlg, "cmb_presszone") or None
        nodecat = tools_qt.get_combo_value(dlg, "cmb_dnom") or None
        if exploitation not in (None, ""):
            filters.append(f"expl_id = {exploitation}")
        if presszone not in (None, ""):
            pz = str(presszone).replace("'", "''")
            filters.append(f"presszone_id = '{pz}'")
        if nodecat not in (None, ""):
            nc = str(nodecat).replace("'", "''")
            filters.append(f"nodecat_id = '{nc}'")

        rows = tools_db.get_rows(
            f"""
            SELECT DISTINCT node_type
            FROM am.ext_node_asset
            WHERE {' AND '.join(filters)}
            ORDER BY node_type
            """
        ) or []

        saved = self.result.get("node_type")
        if isinstance(saved, str) and saved:
            saved = [x.strip() for x in saved.split(",") if x.strip()]
        elif not isinstance(saved, (list, tuple)):
            saved = None
        if saved is None and self.mode == "new":
            saved = self._node_types_user_values("load")

        n = len(rows)
        n_cols = min(3, max(1, n))
        for i, row in enumerate(rows):
            node_type = row[0]
            chk = QCheckBox(self._node_type_label(node_type))
            chk.setObjectName(f"chk_feature_{node_type}")
            chk.setProperty("node_type", node_type)
            chk.setToolTip(str(node_type))
            font = chk.font()
            font.setBold(False)
            font.setWeight(QFont.Weight.Normal)
            chk.setFont(font)
            if node_type in previous_state:
                chk.setChecked(previous_state[node_type])
            elif saved is not None:
                chk.setChecked(node_type in saved)
            else:
                chk.setChecked(True)
            chk.stateChanged.connect(self._update_features_count)
            layout.addWidget(chk, i // n_cols, i % n_cols, Qt.AlignmentFlag.AlignLeft)

        if n_cols >= 3:
            for col in range(n_cols):
                layout.setColumnStretch(col, 1)
        else:
            for col in range(n_cols):
                layout.setColumnStretch(col, 0)
            layout.setColumnStretch(n_cols, 1)
        layout.setAlignment(Qt.AlignmentFlag.AlignTop | Qt.AlignmentFlag.AlignLeft)

        # Scroll fills remaining tab space (undo any leftover fixed height)
        scroll = getattr(dlg, "scroll_node_types", None)
        if scroll is not None:
            scroll.setMinimumSize(0, 0)
            scroll.setMaximumSize(16777215, 16777215)
        features_lyt = getattr(dlg, "gridLayout_features", None)
        if features_lyt is not None:
            features_lyt.setRowStretch(0, 0)
            features_lyt.setRowStretch(1, 0)
            features_lyt.setRowStretch(2, 1)

        self._update_features_count()

    def _get_selected_node_types(self):
        """Return list of checked node type ids ([] if none / not NODE)."""
        if self.asset_type != "NODE" or not hasattr(self.dlg_priority, "lyt_node_types"):
            return None
        return [
            chk.property("node_type")
            for chk in self._iter_node_type_checks()
            if chk.isChecked()
        ]

    def _node_types_user_values(self, action):
        """Load/save Features tab checks in user session (same pattern as breakage assignation)."""
        section = "btn_am_priority"
        parameter = "node_types"
        if action == "save":
            if self.asset_type != "NODE":
                return
            checked = self._get_selected_node_types()
            if checked is None:
                return
            value = ",".join(checked)
            self.result["node_type"] = value if value else None
            tools_gw.set_config_parser(
                section, parameter, value.replace("%", "%%"), "user", "session"
            )
        elif action == "load":
            value = tools_gw.get_config_parser(section, parameter, "user", "session")
            if not value:
                return None
            return [x.strip() for x in str(value).split(",") if x.strip()]
        return None

    def _on_asset_type_changed(self):
        """ Reload config tables when asset type changes """
        self.asset_type = tools_qt.get_combo_value(self.dlg_priority, "cmb_asset_type") or "ARC"
        self._apply_asset_type_ui()
        self._load_catalog_table()
        self._load_material_table()
        self._clear_engine_layouts()
        self._fill_engine_options()
        self._connect_weight_signals()
        self._load_presszone()

    def _clear_engine_layouts(self):
        """Remove previously built engine-parameter widgets so _fill_engine_options can
        rebuild the panel from scratch for the newly selected asset_type."""
        dlg = self.dlg_priority
        for lyt_name in ("lyt_engine_1", "lyt_engine_2"):
            layout = dlg.findChild(QGridLayout, lyt_name)
            if layout is None:
                continue
            while layout.count():
                item = layout.takeAt(0)
                widget = item.widget()
                if widget is not None:
                    widget.setParent(None)
                    widget.deleteLater()
            total_attr = f"total_{lyt_name}"
            if hasattr(dlg, total_attr):
                delattr(dlg, total_attr)
        self.total_weight = {}

    def _connect_weight_signals(self):
        """ Connect weight field changes to total recalculation """
        if self.config.method == "WM":
            for widget in self._get_weight_widgets("lyt_engine_1"):
                widget.textChanged.connect(
                    partial(self._update_total_weight, "lyt_engine_1")
                )
        for widget in self._get_weight_widgets("lyt_engine_2"):
            widget.textChanged.connect(
                partial(self._update_total_weight, "lyt_engine_2")
            )

    def _fill_engine_options(self):
        """ Build engine parameter widgets from config_engine tables """
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
                and asset_type = '{self.asset_type}'
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
                and d.asset_type = '{self.asset_type}'
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

        self._sync_affected_arcs_widget()

    def _get_weight_widgets(self, lyt):
        """ Return engine weight input widgets for a layout """

        def is_weight(x):
            """ Return whether field belongs to the given engine layout """
            return x["layoutname"] == lyt

        fields = filter(is_weight, self.config_engine_fields)
        return [tools_qt.get_widget(self.dlg_priority, x["widgetname"]) for x in fields]

    def _sync_affected_arcs_widget(self):
        """Lock Affected Arcs / Parent arc selected weights to 0 when no linked ARC result."""
        dlg = self.dlg_priority
        if self.asset_type == "NODE":
            names = ("affected_arcs_1", "affected_arcs_2")
        elif self.asset_type == "LINK":
            names = ("parent_arc_selected_1", "parent_arc_selected_2")
        else:
            return
        widgets = [
            tools_qt.get_widget(dlg, name)
            for name in names
        ]
        widgets = [w for w in widgets if w is not None]
        if not widgets:
            return
        linked = self._get_linked_arc_result_id()
        if not linked:
            for widget in widgets:
                tools_qt.set_widget_text(dlg, widget, "0")
                widget.setEnabled(False)
        else:
            for widget in widgets:
                widget.setEnabled(True)

    def _manage_hidden_form(self):
        """ Show or hide priority dialog widgets per giswater.config """
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
            # Hide Explotation filter if there's assets without expl_id
            null_expl = tools_db.get_row(
                f"SELECT 1 FROM am.{self._asset_table} WHERE expl_id IS NULL"
            )
            if not self.result["expl_id"] and (
                self.config.show_exploitation is not True or null_expl
            ):
                self.dlg_priority.lbl_expl_selection.setVisible(False)
                self.dlg_priority.cmb_expl_selection.setVisible(False)
            # Hide Presszone filter if there's assets without presszone_id
            null_presszone = tools_db.get_row(
                f"SELECT 1 FROM am.{self._asset_table} WHERE presszone_id IS NULL"
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
                self._set_config_tab_visible("tab_catalog", False)
            if self.config.show_config_material is not True:
                self._set_config_tab_visible("tab_material", False)
            if self.config.show_config_engine is not True:
                self._set_config_tab_visible("tab_engine", False)
        if self.config.show_save2file is not True:
           self.dlg_priority.btn_save2file.setVisible(False)

        # Manage form when is edit
        if self.mode == "edit":
            self.dlg_priority.txt_result_id.setEnabled(False)

        self._set_arc_result_combo_visible()

    def _set_arc_result_combo_visible(self):
        """ Show ARC-result combo for NODE and LINK (parent arc plan). """
        dlg = self.dlg_priority
        if not hasattr(dlg, "cmb_arc_result"):
            return
        show = (
            self.asset_type in ("NODE", "LINK")
            and (self.config.show_budget is True or bool(self.result.get("budget")))
            and getattr(dlg, "grb_global", None) is not None
            and dlg.grb_global.isVisible()
        )
        dlg.lbl_arc_result.setVisible(show)
        dlg.cmb_arc_result.setVisible(show)

    def _manage_calculate(self):
        """ Validate inputs, run data checks and start calculation task """
        dlg = self.dlg_priority
        tools_qt.set_widget_text(dlg, 'tab_log_txt_infolog', '')

        if self.config.method == "SH" and self.asset_type in ("NODE", "LINK"):
            msg = "The Shamir-Howard method is not available for NODE or LINK assets."
            info = "Please select ARC asset type, or ask an administrator to configure the Weighted Method engine."
            tools_qt.show_info_box(msg, inf_text=info)
            return

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
            node_type,
            nodecat,
            budget,
            target_year,
            config_catalog,
            config_material,
            config_engine,
        ) = inputs

        if self.asset_type == "NODE":
            if not self._confirm_node_data_checks(
                features, exploitation, presszone, node_type, nodecat,
                config_catalog, config_material,
            ):
                return
            linked_arc_result_id = self._get_linked_arc_result_id()
            self._run_node_calculation(
                result_name, result_description, status, features, exploitation,
                presszone, node_type, nodecat, budget, target_year,
                config_catalog, config_material, config_engine,
                linked_arc_result_id=linked_arc_result_id,
            )
            return

        if self.asset_type == "LINK":
            linked_arc_result_id = self._get_linked_arc_result_id()
            if not linked_arc_result_id:
                tools_qt.show_info_box(
                    tools_qt.tr("No parent arc result selected."),
                    inf_text=tools_qt.tr(
                        "Parent arc selected criterion will contain no value."
                    ),
                )
            self._run_link_calculation(
                result_name, result_description, status, features, exploitation,
                presszone, material, nodecat, budget, target_year,
                config_catalog, config_material, config_engine,
                linked_arc_result_id=linked_arc_result_id,
            )
            return

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
                    or arccat_id not in ('{"','".join(config_catalog.catalog_ids())}')
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
            asset_type=self.asset_type,
        )
        self._start_thread()

    def _confirm_node_data_checks(
        self, features, exploitation, presszone, node_type, nodecat,
        config_catalog, config_material,
    ):
        """Mirror ARC catalog/material pre-checks for NODE assets."""
        filter_list = []
        if features:
            filter_list.append(f"""node_id in ('{"','".join(features)}')""")
        if exploitation:
            filter_list.append(f"expl_id = {exploitation}")
        if presszone:
            filter_list.append(f"presszone_id = '{presszone}'")
        if node_type:
            if isinstance(node_type, (list, tuple)):
                types = "','".join(str(t).replace("'", "''") for t in node_type)
                filter_list.append(f"node_type in ('{types}')")
            else:
                filter_list.append(f"node_type = '{node_type}'")
        if nodecat:
            filter_list.append(f"nodecat_id = '{nodecat}'")
        filters = f"where {' and '.join(filter_list)}" if filter_list else ""
        catalog_ids = "','".join(str(x) for x in config_catalog.catalog_ids())
        material_ids = "','".join(config_material.materials())

        data_checks = tools_db.get_rows(
            f"""
            with assets as (
                select * from am.ext_node_asset {filters}),
            list_invalid_nodecat_ids as (
                select count(*), coalesce(nodecat_id, 'NULL')
                from assets
                where nodecat_id is null
                    or nodecat_id not in ('{catalog_ids}')
                group by nodecat_id
                order by nodecat_id),
            invalid_nodecat_ids as (
                select 'invalid_nodecat_ids' as check,
                    sum(count) as qtd,
                    string_agg(coalesce, ', ') as list
                from list_invalid_nodecat_ids),
            list_invalid_materials as (
                select count(*), coalesce(matcat_id, 'NULL')
                from assets
                where matcat_id not in ('{material_ids}')
                    or matcat_id = '{self.config.unknown_material}'
                    or matcat_id is null
                group by matcat_id
                order by matcat_id),
            invalid_materials as (
                select 'invalid_materials' as check, sum(count) as qtd, string_agg(coalesce, ', ') as list
                from list_invalid_materials)
            select * from invalid_nodecat_ids
            union all
            select * from invalid_materials
            """
        ) or []

        for row in data_checks:
            if not row["qtd"]:
                continue
            if row["check"] == "invalid_nodecat_ids":
                msg = (
                    "Nodes with invalid nodecat_ids: {0}.\nInvalid nodecat_ids: {1}.\n\n"
                    "A nodecat_id is considered invalid if it is not listed in the catalog "
                    "configuration table. As a result, these nodes will NOT be assigned a "
                    "priority value.\n\nDo you want to proceed?"
                )
                if not tools_qt.show_question(
                    msg, force_action=True, msg_params=(row["qtd"], row["list"])
                ):
                    return False
            elif row["check"] == "invalid_materials":
                main_msg = tools_qt.tr(
                    "A material is considered invalid if it is not listed in the material configuration table."
                )
                main_msg += " "
                if config_material.has_material(self.config.unknown_material):
                    main_msg += tools_qt.tr(
                        "As a result, the material of these nodes will be treated "
                        "as the configured unknown material, {0}.",
                        list_params=(self.config.unknown_material,),
                    )
                else:
                    main_msg += tools_qt.tr(
                        "These nodes will NOT be assigned a priority value "
                        "as the configured unknown material, {0}, "
                        "is not listed in the configuration tab for materials.",
                        list_params=(self.config.unknown_material,),
                    )
                msg = (
                    tools_qt.tr("Nodes with invalid materials: {0}.", list_params=(row["qtd"]))
                    + "\n"
                    + tools_qt.tr("Invalid materials: {0}.", list_params=(row["list"]))
                    + "\n\n"
                    + main_msg
                    + "\n\n"
                    + tools_qt.tr("Do you want to proceed?")
                )
                if not tools_qt.show_question(msg, force_action=True):
                    return False
        return True

    def _get_linked_arc_result_id(self):
        """Selected ARC result_id from NODE combo, or None."""
        dlg = self.dlg_priority
        if not hasattr(dlg, "cmb_arc_result"):
            return None
        result_id = tools_qt.get_combo_value(dlg, dlg.cmb_arc_result)
        if not result_id:
            return None
        try:
            return int(result_id)
        except (TypeError, ValueError):
            return None

    def _run_node_calculation(
        self, result_name, result_description, status, features, exploitation,
        presszone, node_type, nodecat, budget, target_year,
        config_catalog, config_material, config_engine,
        linked_arc_result_id=None,
    ):
        """NODE WM: same Catalog/Material plumbing as ARC (nodecatalog + shared materials)."""
        self.thread = GwCalculatePriority(
            tools_qt.tr("Calculate Priority"),
            self.type,
            result_name,
            result_description,
            status,
            features,
            exploitation,
            presszone,
            None,
            None,
            budget,
            target_year,
            config_catalog,
            config_material,
            config_engine,
            asset_type=self.asset_type,
            node_type=node_type,
            nodecat=nodecat,
            linked_arc_result_id=linked_arc_result_id,
        )
        self._start_thread()

    def _run_link_calculation(
        self, result_name, result_description, status, features, exploitation,
        presszone, material, linkcat, budget, target_year,
        config_catalog, config_material, config_engine,
        linked_arc_result_id=None,
    ):
        """LINK WM: catalog costs + optional parent ARC result."""
        self.thread = GwCalculatePriority(
            tools_qt.tr("Calculate Priority"),
            self.type,
            result_name,
            result_description,
            status,
            features,
            exploitation,
            presszone,
            None,
            material,
            budget,
            target_year,
            config_catalog,
            config_material,
            config_engine,
            asset_type=self.asset_type,
            nodecat=linkcat,
            linked_arc_result_id=linked_arc_result_id,
        )
        self._start_thread()

    def _start_thread(self):
        """ Wire priority task signals and add QgsApplication task """
        dlg = self.dlg_priority
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
        self.rel_feature_type = {"ARC": "arc", "NODE": "node", "LINK": "link"}.get(
            self.asset_type, "arc"
        )
        id_field = {"ARC": "arc_id", "NODE": "node_id", "LINK": "link_id"}.get(
            self.asset_type, "arc_id"
        )
        layer = tools_qgis.get_layer_by_tablename(self.layer_to_work, schema_name="am")
        if layer is None:
            tools_qgis.show_warning(
                f"For select on canvas is mandatory to load {self.layer_to_work} layer",
                dialog=self.dlg_priority,
            )
            return

        layers = self.rel_layers.setdefault(self.rel_feature_type, [])
        if layer not in layers:
            layers.append(layer)

        # Remove all previous selections
        self.rel_layers = tools_gw.remove_selection(True, layers=self.rel_layers)

        # In case of "duplicate" or "edit", load result selection
        if self.result["features"]:
            saved = {str(x) for x in self.result["features"]}
            select_fid = []
            self.list_ids[self.rel_feature_type] = []
            for feature in layer.getFeatures():
                feat_id = feature[id_field]
                if feat_id is not None and str(feat_id) in saved:
                    select_fid.append(feature.id())
                    self.list_ids[self.rel_feature_type].append(str(feat_id))
            layer.select(select_fid)

        tools_gw.selection_init(self, self.dlg_priority, self.layer_to_work)
        self.rel_feature_type = {"ARC": "arc", "NODE": "node", "LINK": "link"}.get(
            self.asset_type, "arc"
        )

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
        """ Trigger QGIS canvas selection tool by mode index """

        # Set active layer
        layer = tools_qgis.get_layer_by_tablename(self.layer_to_work, schema_name="am")
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
        """ Export calculation dataframe to Excel file """
        if not hasattr(self.thread, "df"):
            return

        file_path = tools_qt.get_save_file_path(self.dlg_priority, '', "*.xlsx", "Save file")
        fp = Path(file_path)
        self.thread.df.to_excel(file_path)

        msg = "{0} successfully saved."
        msg_params = (fp.name,)
        tools_qt.show_info_box(msg, msg_params=msg_params)

    def _set_signals(self):
        """ Connect priority dialog widget signals """
        dlg = self.dlg_priority
        dlg.btn_accept.clicked.connect(self._manage_calculate)
        dlg.btn_again.clicked.connect(self._go_first_tab)
        dlg.btn_close.clicked.connect(self.close_dlg)
        dlg.rejected.connect(self.close_dlg)
        dlg.btn_save2file.clicked.connect(self._save2file)
        dlg.cmb_asset_type.currentIndexChanged.connect(partial(self._on_asset_type_changed))
        if hasattr(dlg, "cmb_arc_result"):
            dlg.cmb_arc_result.currentIndexChanged.connect(partial(self._on_arc_result_changed))
        dlg.cmb_expl_selection.currentIndexChanged.connect(partial(self._load_presszone))
        dlg.cmb_presszone.currentIndexChanged.connect(partial(self._load_diameter))
        dlg.cmb_dnom.currentIndexChanged.connect(partial(self._load_material))
        if hasattr(dlg, "btn_features_select_all"):
            dlg.btn_features_select_all.setAutoDefault(False)
            dlg.btn_features_select_all.setDefault(False)
            dlg.btn_features_clear.setAutoDefault(False)
            dlg.btn_features_clear.setDefault(False)
            dlg.btn_features_select_all.clicked.connect(partial(self._set_all_node_types, True))
            dlg.btn_features_clear.clicked.connect(partial(self._set_all_node_types, False))
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

        self._connect_weight_signals()

    def close_dlg(self):
        """ Close dialog """
        self._node_types_user_values("save")
        tools_qgis.disconnect_signal_selection_changed()
        tools_gw.remove_selection(True, layers=self.rel_layers)
        tools_gw.close_dialog(self.dlg_priority)

    def _go_first_tab(self):
        # Reset tab
        """ Reset dialog to first tab after calculation """
        dlg = self.dlg_priority
        tools_gw.disable_tab_log(dlg)

        # Enable first tab
        dlg.mainTab.setTabEnabled(0, True)

        # Reset buttons
        dlg.btn_accept.setVisible(True)
        dlg.btn_again.setVisible(False)

    def _manage_qtw_row(self, dialog, widget, action):
        """ Add or remove row in catalog or material table widget """
        if action == "add":
            row_count = widget.rowCount()
            widget.insertRow(row_count)
            widget.setCurrentCell(row_count, 0)
        elif action == "remove":
            selected_row = widget.currentRow()
            if selected_row != -1:
                widget.removeRow(selected_row)

    def _update_timer(self, widget):
        """ Update elapsed-time label during calculation task """
        elapsed_time = time() - self.t0
        text = str(timedelta(seconds=round(elapsed_time)))
        widget.setText(text)

    def _update_total_weight(self, lyt):
        """ Recalculate and display total weight for a layout """
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
        """ Validate dialog inputs and build config objects """
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
            features = self._selected_asset_ids()
        except Exception:
            pass

        exploitation = tools_qt.get_combo_value(dlg, "cmb_expl_selection") or None
        presszone = tools_qt.get_combo_value(dlg, "cmb_presszone")
        if self.asset_type == "ARC":
            diameter = tools_qt.get_combo_value(dlg, "cmb_dnom") or None
            diameter = f"{diameter:g}" if diameter else None
            material = tools_qt.get_combo_value(dlg, "cmb_material") or None
            node_type = None
            nodecat = None
        elif self.asset_type == "LINK":
            diameter = None
            material = tools_qt.get_combo_value(dlg, "cmb_material") or None
            node_type = None
            nodecat = tools_qt.get_combo_value(dlg, "cmb_dnom") or None
        else:
            diameter = None
            material = None
            # cmb_dnom = optional nodecat; node types from Features tab
            nodecat = tools_qt.get_combo_value(dlg, "cmb_dnom") or None
            node_type = self._get_selected_node_types()
            if not node_type:
                msg = "Please select at least one node type in the Features tab."
                tools_qt.show_info_box(msg)
                return
            # Persist selection even if dialog stays open after Run
            self._node_types_user_values("save")

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
            if self.asset_type == "NODE":
                config_catalog = configcatalog_from_tablewidget(
                    self.qtbl_catalog, "nodecat_id", save_table="config_nodecatalog"
                )
            elif self.asset_type == "LINK":
                config_catalog = configcatalog_from_tablewidget(
                    self.qtbl_catalog, "linkcat_id", save_table="config_linkcatalog"
                )
            else:
                config_catalog = configcatalog_from_tablewidget(
                    self.qtbl_catalog, "arccat_id", save_table="config_catalog"
                )
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
            node_type,
            nodecat,
            budget,
            target_year,
            config_catalog,
            config_material,
            config_engine,
        )

    # region Attribute

    def _manage_attr(self):
        """ Fill status, exploitation and selection attribute widgets """
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
            INNER JOIN am.{self._asset_table} ext ON expl.expl_id = ext.expl_id;
            """

        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(dlg.cmb_expl_selection, rows, 1, add_empty=True)
        if self.result.get("expl_id") not in (None, ""):
            tools_qt.set_combo_value(
                dlg.cmb_expl_selection, self.result["expl_id"], 0, add_new=False
            )
        else:
            tools_qt.set_combo_value(
                dlg.cmb_expl_selection,
                dlg.cmb_expl_selection.itemText(0),
                0,
                add_new=False,
            )

        # Load presszone combo (and NODE features list)
        self._load_presszone()

        if self.asset_type == "NODE" and self.result.get("presszone_id") not in (None, ""):
            cmb_pz = dlg.cmb_presszone
            blocked = cmb_pz.blockSignals(True)
            tools_qt.set_combo_value(
                cmb_pz, self.result["presszone_id"], 0, add_new=False
            )
            cmb_pz.blockSignals(blocked)
            self._load_diameter()
            if self.result.get("nodecat_id") not in (None, ""):
                cmb_dnom = dlg.cmb_dnom
                blocked = cmb_dnom.blockSignals(True)
                tools_qt.set_combo_value(
                    cmb_dnom, self.result["nodecat_id"], 0, add_new=False
                )
                cmb_dnom.blockSignals(blocked)
                self._load_material()
            self._schedule_load_node_types()

        if self.asset_type == "LINK" and self.result.get("presszone_id") not in (None, ""):
            cmb_pz = dlg.cmb_presszone
            blocked = cmb_pz.blockSignals(True)
            tools_qt.set_combo_value(
                cmb_pz, self.result["presszone_id"], 0, add_new=False
            )
            cmb_pz.blockSignals(blocked)
            self._load_diameter()
            if self.result.get("nodecat_id") not in (None, ""):
                cmb_dnom = dlg.cmb_dnom
                blocked = cmb_dnom.blockSignals(True)
                tools_qt.set_combo_value(
                    cmb_dnom, self.result["nodecat_id"], 0, add_new=False
                )
                cmb_dnom.blockSignals(blocked)
                self._load_material()
            if self.result.get("material_id") not in (None, ""):
                tools_qt.set_combo_value(
                    dlg.cmb_material, self.result["material_id"], 0, add_new=False
                )

        # Text budget
        tools_qt.set_widget_text(dlg, dlg.txt_budget, self.result["budget"])

        # Fill horizon year
        tools_qt.set_widget_text(dlg, dlg.txt_year, self.result["target_year"])

    def _load_arc_result_combo(self):
        """ Fill combo with finished ARC priority results (left of yearly budget). """
        dlg = self.dlg_priority
        if not hasattr(dlg, "cmb_arc_result"):
            return
        rows = tools_db.get_rows(
            """
            SELECT result_id AS id, result_name AS idval
            FROM am.cat_result
            WHERE COALESCE(asset_type, 'ARC') = 'ARC'
            ORDER BY result_name
            """
        )
        blocked = dlg.cmb_arc_result.blockSignals(True)
        tools_qt.fill_combo_values(
            dlg.cmb_arc_result, rows or None, 1, combo_clear=True, add_empty=True
        )
        linked = self.result.get("linked_arc_result_id")
        if linked and self.asset_type in ("NODE", "LINK"):
            tools_qt.set_combo_value(dlg.cmb_arc_result, str(linked), 0, add_new=False)
            dlg.txt_year.setEnabled(False)
        elif self.asset_type in ("NODE", "LINK"):
            dlg.txt_year.setEnabled(True)
        dlg.cmb_arc_result.blockSignals(blocked)

    def _on_arc_result_changed(self):
        """ Copy budget/horizon from ARC result; lock horizon while an ARC result is linked. """
        dlg = self.dlg_priority
        result_id = tools_qt.get_combo_value(dlg, dlg.cmb_arc_result)
        if not result_id:
            dlg.txt_year.setEnabled(True)
            self._sync_affected_arcs_widget()
            return
        try:
            result_id = int(result_id)
        except (TypeError, ValueError):
            dlg.txt_year.setEnabled(True)
            self._sync_affected_arcs_widget()
            return
        row = tools_db.get_row(
            f"""
            SELECT budget, target_year
            FROM am.cat_result
            WHERE result_id = {result_id}
              AND COALESCE(asset_type, 'ARC') = 'ARC'
            """
        )
        if not row:
            dlg.txt_year.setEnabled(True)
            self._sync_affected_arcs_widget()
            return
        budget = row["budget"] if not isinstance(row, (list, tuple)) else row[0]
        target_year = row["target_year"] if not isinstance(row, (list, tuple)) else row[1]
        if budget is not None:
            tools_qt.set_widget_text(dlg, dlg.txt_budget, budget)
        if target_year is not None:
            tools_qt.set_widget_text(dlg, dlg.txt_year, target_year)
        # Horizon must match the linked ARC plan (disabled = gray look)
        dlg.txt_year.setEnabled(False)
        self._sync_affected_arcs_widget()

    # endregion

    def _load_presszone(self):
        """ Fill presszone combo for selected exploitation """
        dlg = self.dlg_priority
        exploitation = tools_qt.get_combo_value(dlg, "cmb_expl_selection")
        if exploitation == "":
            tools_qt.fill_combo_values(dlg.cmb_presszone, None, 1, combo_clear=True)
            tools_qt.fill_combo_values(dlg.cmb_dnom, None, 1, combo_clear=True)
            tools_qt.fill_combo_values(dlg.cmb_material, None, 1, combo_clear=True)
            if self.asset_type == "NODE":
                self._schedule_load_node_types()
            return
        sql = f"""           
            SELECT DISTINCT ON (ext.presszone_id) 
                ext.presszone_id AS id, 
                CONCAT(ext.presszone_id, ' - ', pres.name) AS idval
            FROM {lib_vars.schema_name}.presszone pres 
            INNER JOIN am.{self._asset_table} ext 
                ON ext.expl_id = ANY(pres.expl_id)
            WHERE ext.expl_id = {exploitation} 
            ORDER BY ext.presszone_id;
            """
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(dlg.cmb_presszone, rows, 1, add_empty=True)

        self._load_diameter()
        # Features grid refreshed once from _load_diameter / _load_material

    def _load_diameter(self):
        """ Fill diameter or nodecat combo for selected presszone """
        dlg = self.dlg_priority
        presszone = tools_qt.get_combo_value(dlg, "cmb_presszone")
        exploitation = tools_qt.get_combo_value(dlg, "cmb_expl_selection")
        if presszone == "":
            tools_qt.fill_combo_values(dlg.cmb_dnom, None, 1, combo_clear=True)
            tools_qt.fill_combo_values(dlg.cmb_material, None, 1, combo_clear=True)
            if self.asset_type == "NODE":
                self._schedule_load_node_types()
            return
        if self.asset_type == "ARC":
            sql = f"""
                SELECT distinct(dnom::float) AS id, dnom as idval 
                FROM am.ext_arc_asset WHERE presszone_id = '{presszone}' 
                AND expl_id = {exploitation}
                AND dnom is not null ORDER BY id;
                """
        elif self.asset_type == "LINK":
            sql = f"""
                SELECT distinct(linkcat_id) AS id, linkcat_id as idval
                FROM am.ext_link_asset WHERE presszone_id = '{presszone}'
                AND expl_id = {exploitation}
                AND linkcat_id is not null ORDER BY id;
                """
        else:
            sql = f"""
                SELECT distinct(nodecat_id) AS id, nodecat_id as idval
                FROM am.ext_node_asset WHERE presszone_id = '{presszone}'
                AND expl_id = {exploitation}
                AND nodecat_id is not null ORDER BY id;
                """
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(dlg.cmb_dnom, rows, 1, add_empty=True)

        self._load_material()

    def _load_material(self):
        """ Fill material or node type combo for selected diameter """
        dlg = self.dlg_priority
        presszone = tools_qt.get_combo_value(dlg, "cmb_presszone")
        exploitation = tools_qt.get_combo_value(dlg, "cmb_expl_selection")
        dnom = tools_qt.get_combo_value(dlg, "cmb_dnom")

        if dnom == "":
            tools_qt.fill_combo_values(dlg.cmb_material, None, 1, combo_clear=True)
            if self.asset_type == "NODE":
                self._schedule_load_node_types()
            return

        if self.asset_type == "ARC":
            sql = f"""
                SELECT distinct(matcat_id) AS id, matcat_id as idval 
                FROM am.ext_arc_asset WHERE presszone_id = '{presszone}' 
                AND expl_id = {exploitation} AND dnom::float ={dnom} ORDER BY id;
                """
        elif self.asset_type == "LINK":
            sql = f"""
                SELECT distinct(matcat_id) AS id, matcat_id as idval
                FROM am.ext_link_asset WHERE presszone_id = '{presszone}'
                AND expl_id = {exploitation} AND linkcat_id = '{dnom}' ORDER BY id;
                """
        else:
            sql = f"""
                SELECT distinct(node_type) AS id, node_type as idval
                FROM am.ext_node_asset WHERE presszone_id = '{presszone}'
                AND expl_id = {exploitation} AND nodecat_id = '{dnom}' ORDER BY id;
                """
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(dlg.cmb_material, rows, 1, add_empty=True)
        if self.asset_type == "NODE":
            self._schedule_load_node_types()

    def _schedule_load_node_types(self):
        """Debounce Features grid rebuild so combo popups are not disrupted."""
        timer = getattr(self, "_node_types_timer", None)
        if timer is None:
            timer = QTimer(self.dlg_priority)
            timer.setSingleShot(True)
            timer.timeout.connect(self._load_node_types)
            self._node_types_timer = timer
        timer.start(0)

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
