"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial
import json
from typing import Any, Dict, List, Optional

from qgis.PyQt.QtCore import QDate, Qt, QModelIndex, QStringListModel
from qgis.core import QgsExpression
from qgis.PyQt.QtGui import QFont, QStandardItem, QStandardItemModel
from qgis.PyQt.QtWidgets import (QAbstractItemView, QActionGroup, QCheckBox,
                                 QComboBox, QCompleter, QDateEdit, QDialog,
                                 QDialogButtonBox, QHBoxLayout, QLabel,
                                 QLineEdit, QTableView, QTableWidgetItem,
                                 QTextEdit, QToolBar, QVBoxLayout, QWidget)

from ...ui.ui_manager import AddLotUi, LotManagementUi, ResourcesManagementUi, TeamCreateUi

from .... import global_vars
from ....libs import lib_vars, tools_db, tools_qgis, tools_qt, tools_os
from ...utils import tools_gw
from ...utils.selection_mode import GwSelectionMode
from ...utils.selection_widget import GwSelectionWidget


class AddNewLot:

    def __init__(self, icon_path: str, action_name: str, text: str, toolbar: QToolBar, action_group: QActionGroup):
        """ Class to control 'Add basic visit' of toolbar 'edit' """

        self.ids: List[Any] = []
        self.canvas = global_vars.canvas
        self.rb_red = tools_gw.create_rubberband(self.canvas)
        self.rb_red.setColor(Qt.GlobalColor.darkRed)
        self.rb_red.setIconSize(20)
        self.rb_list: List[Any] = []
        self.schema_parent = lib_vars.schema_name
        # self.cm_schema = lib_vars.project_vars['cm_schema']
        self.lot_date_format = 'yyyy-MM-dd'
        self.max_id = 0
        self.signal_selectionChanged = False
        self.param_options: Optional[Any] = None
        self.plugin_name = 'Giswater'
        self.plugin_dir = lib_vars.plugin_dir
        self.schemaname = lib_vars.schema_name
        self.iface = global_vars.iface
        self.dict_tables: Optional[Dict[str, Any]] = None
        self.lot_saved = False
        self.is_new_lot = True
        self.lot_id: Optional[int] = None
        self.dlg_lot: Optional[AddLotUi] = None

    def manage_lot(self, lot_id: Optional[int] = None, is_new: bool = True):
        """Open the AddLot dialog and load dynamic fields from gw_fct_cm_getlot."""

        self.lot_id = lot_id
        self.rubber_band = tools_gw.create_rubberband(self.canvas)
        self.is_new_lot = is_new
        self.lot_id_value = None
        self.ids = []
        self.rb_list = []
        self.rel_feature_type = 'arc'
        self.signal_selectionChanged = False
        self.cmb_position = 17
        self.srid = lib_vars.data_epsg

        if is_new:
            self.is_new_lot = True
            self.lot_saved = False
        else:
            self.is_new_lot = False
            self.lot_saved = True

        self.rel_list_ids = {ft: [] for ft in ['arc', 'node', 'connec', 'gully', 'link']}
        self.excluded_layers = [f"ve_{ft}" for ft in self.rel_list_ids]

        self.rel_layers = {ft: tools_gw.get_layers_from_feature_type(ft) for ft in ['arc', 'node', 'connec', 'link']}
        if tools_gw.get_project_type() == 'ud':
            self.rel_layers['gully'] = tools_gw.get_layers_from_feature_type('gully')

        # Create dialog and load base settings
        self.dlg_lot = AddLotUi(self)
        tools_gw.load_settings(self.dlg_lot)

        # Load dynamic form and apply fields
        self.load_lot_dialog(lot_id)

        # Hide Visits tab
        index = self.dlg_lot.tab_widget.indexOf(self.dlg_lot.VisitsTab)
        if index > -1:
            self.dlg_lot.tab_widget.removeTab(index)

        # Use findChild with the widget's objectName for a reliable connection.
        campaign_combo = self.dlg_lot.findChild(QComboBox, "tab_data_campaign_id")
        if campaign_combo:
            campaign_combo.currentIndexChanged.connect(self._on_campaign_changed)
            # Initial population when the dialog opens
            self._on_campaign_changed()
            # Clear initial data cache after first run
            self.initial_lot_data = {}
        else:
            pass

        # Reference key widgets
        self.user_name = self.dlg_lot.findChild(QLineEdit, "user_name")

        if self.lot_id_value:
            widget = self.get_widget_by_columnname(self.dlg_lot, "lot_id")
            if widget:
                widget.setText(str(self.lot_id_value))

        # Fill workorder part (custom logic)
        self.fill_workorder_fields()

        if lot_id:
            self._load_lot_relations(lot_id)
            self.enable_feature_tabs_by_campaign(lot_id)
            self._check_and_disable_campaign_combo()

        if tools_gw.get_project_type() == 'ws':
            tools_qt.enable_tab_by_tab_name(self.dlg_lot.tab_widget, 'LoadsTab', False)

        # Icon buttons
        tools_gw.add_icon(self.dlg_lot.btn_insert, '111')
        tools_gw.add_icon(self.dlg_lot.btn_delete, '112')

        # Create a widget and layout to hold the buttons
        self.corner_widget = QWidget()
        layout = QHBoxLayout(self.corner_widget)
        layout.setContentsMargins(0, 1, 0, 0)

        # self.btn_show_on_top_relations.clicked.connect(self._show_selection_on_top_relations)

        # self.btn_zoom_to_selection_relations.clicked.connect(self._zoom_to_selection_relations)

        self.dlg_lot.tab_feature.setCornerWidget(self.corner_widget)

        # Cancel / Accept
        self.dlg_lot.btn_cancel.clicked.connect(self.dlg_lot.reject)
        self.dlg_lot.rejected.connect(self.manage_rejected)
        self.dlg_lot.rejected.connect(self.reset_rb_list)
        self.dlg_lot.btn_accept.clicked.connect(self.save_lot)
        self.dlg_lot.rejected.connect(self._on_dialog_rejected)

        # Tab logic
        name_widget = self.get_widget_by_columnname(self.dlg_lot, "name")
        if name_widget:
            name_widget.textChanged.connect(self._check_enable_tab_relations)
            self._check_enable_tab_relations()

        if tools_gw.get_project_type() == 'ws':
            index = self.dlg_lot.tab_feature.indexOf(self.dlg_lot.tab_gully)
            if index != -1:
                self.dlg_lot.tab_feature.removeTab(index)

        self.dlg_lot.tab_widget.currentChanged.connect(self._on_tab_change)
        self.dlg_lot.tab_feature.currentChanged.connect(self._on_tab_feature_changed)
        self.dlg_lot.tab_feature.currentChanged.connect(self._update_completer_and_relations)

        # Relation feature buttons
        self.dlg_lot.btn_insert.clicked.connect(self._insert_related_feature)
        self.dlg_lot.btn_delete.clicked.connect(self._delete_related_records)

        self_variables = {"selection_mode": GwSelectionMode.LOT, "invert_selection": True, "zoom_to_selection": True, "selection_on_top": True}
        general_variables = {"class_object": self, "dialog": self.dlg_lot, "table_object": "lot"}
        used_tools = ["rectangle", "polygon", "freehand", "circle"]
        menu_variables = {"used_tools": used_tools, "callback": self._init_snapping_selection, "callback_later": self._refresh_relations_table}
        highlight_variables = {"callback_values": self.callback_values}
        expression_selection = {"callback_later": self._select_by_expression}
        selection_widget = GwSelectionWidget(self_variables, general_variables, menu_variables, highlight_variables, expression_selection)
        self.selection_widget = selection_widget
        self.dlg_lot.lyt_selection.addWidget(selection_widget, 0)

        # Always set multi-row and full row selection for relation tables, both on create and edit
        relation_table_names = [
            "tbl_campaign_lot_x_arc",
            "tbl_campaign_lot_x_node",
            "tbl_campaign_lot_x_connec",
            "tbl_campaign_lot_x_link"
        ]
        if tools_gw.get_project_type() == 'ud':
            relation_table_names.append("tbl_campaign_lot_x_gully")

        for table_name in relation_table_names:
            view = getattr(self.dlg_lot, table_name, None)
            if view:
                tools_qt.set_tableview_config(view, sorting_enabled=True)
                view.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
                view.setSelectionMode(QAbstractItemView.SelectionMode.ExtendedSelection)  # or SingleSelection
                view.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)

        # Open dialog
        tools_gw.open_dialog(self.dlg_lot, dlg_name="add_lot")

    def callback_values(self):
        """Return callback values for selection widget operations."""
        return (self, self.dlg_lot, "lot")

    def _on_campaign_changed(self):
        """
        Handles all UI updates when the campaign selection changes.
        - Populates and updates exploitation and sector combo boxes based on the campaign's organization.
        - Updates the team combo box with valid teams for the campaign.
        """
        campaign_combo = self.dlg_lot.findChild(QComboBox, "tab_data_campaign_id")
        team_combo = self.dlg_lot.findChild(QComboBox, "tab_data_team_id")
        expl_combo = self.dlg_lot.findChild(QComboBox, "tab_data_expl_id")
        sector_combo = self.dlg_lot.findChild(QComboBox, "tab_data_sector_id")
        org_assigned_widget = self.dlg_lot.findChild(QLineEdit, "tab_data_organization_assigned")

        if not all([campaign_combo, team_combo, expl_combo, sector_combo]):
            return

        # Clear and disable dependent widgets initially
        expl_combo.clear()
        expl_combo.setEnabled(False)
        sector_combo.clear()
        sector_combo.setEnabled(False)
        team_combo.clear()
        if org_assigned_widget:
            org_assigned_widget.clear()
            org_assigned_widget.setEnabled(False)

        campaign_id = campaign_combo.currentData()

        if not campaign_id:
            return

        # Fetch all campaign-related data in one go
        body = {"p_campaign_id": campaign_id}
        response = tools_gw.execute_procedure("gw_fct_cm_getteam", body, schema_name="cm", check_function=False)

        if isinstance(response, str):
            response = json.loads(response)

        if not response or response.get("status") != "Accepted":
            return

        response_body = response.get("body", {})

        # Populate Organization
        if org_assigned_widget:
            org_name = response_body.get("organization_name")
            if org_name:
                org_assigned_widget.setText(org_name)

        # Populate Teams
        teams = response_body.get("data", [])
        if teams:
            team_combo.blockSignals(True)
            for team in teams:
                team_combo.addItem(str(team['idval']), team['id'])
            # Restore the lot's original team_id if it exists
            if self.initial_lot_data.get("team_id"):
                self.set_widget_value(team_combo, self.initial_lot_data["team_id"])
            team_combo.blockSignals(False)

        # Get campaign details for expl and sector
        campaign_details_sql = f"SELECT organization_id, expl_id, sector_id FROM cm.om_campaign WHERE campaign_id = {campaign_id}"
        campaign_data = tools_db.get_row(campaign_details_sql)

        if not campaign_data or campaign_data.get('organization_id') is None:
            return

        org_id = campaign_data['organization_id']

        allowed_ids_sql = f"SELECT expl_id, sector_id FROM cm.cat_organization WHERE organization_id = {org_id}"
        allowed_ids_data = tools_db.get_row(allowed_ids_sql)

        allowed_expl_ids = allowed_ids_data.get('expl_id') if allowed_ids_data else None
        allowed_sector_ids = allowed_ids_data.get('sector_id') if allowed_ids_data else None

        # Populate exploitation combo
        sql_expl = f"SELECT expl_id, name FROM {self.schema_parent}.exploitation"
        if allowed_expl_ids:
            sql_expl += f" WHERE expl_id = ANY(ARRAY{allowed_expl_ids})"
        elif isinstance(allowed_expl_ids, list):
            sql_expl += " WHERE 1=0"
        sql_expl += " ORDER BY name"
        rows_expl = tools_db.get_rows(sql_expl)
        if rows_expl:
            tools_qt.fill_combo_values(expl_combo, rows_expl, index_to_show=1, add_empty=False)
            expl_combo.setEnabled(True)
            # Restore the lot's original expl_id if it exists
            if self.initial_lot_data.get("expl_id"):
                self.set_widget_value(expl_combo, self.initial_lot_data["expl_id"])

        # Populate sector combo
        sql_sector = f"SELECT sector_id, name FROM {self.schema_parent}.sector"
        if allowed_sector_ids:
            sql_sector += f" WHERE sector_id = ANY(ARRAY{allowed_sector_ids})"
        elif isinstance(allowed_sector_ids, list):
            sql_sector += " WHERE 1=0"
        sql_sector += " ORDER BY name"
        rows_sector = tools_db.get_rows(sql_sector)
        if rows_sector:
            tools_qt.fill_combo_values(sector_combo, rows_sector, index_to_show=1, add_empty=False)
            sector_combo.setEnabled(True)
            # Restore the lot's original sector_id if it exists
            if self.initial_lot_data.get("sector_id"):
                self.set_widget_value(sector_combo, self.initial_lot_data["sector_id"])

        # Set pre-selected values from campaign
        campaign_expl_id = campaign_data.get('expl_id')
        if campaign_expl_id is not None:
            self.set_widget_value(expl_combo, campaign_expl_id)
            expl_combo.setEnabled(False)

        campaign_sector_id = campaign_data.get('sector_id')
        if campaign_sector_id is not None:
            self.set_widget_value(sector_combo, campaign_sector_id)
            sector_combo.setEnabled(False)

        # Update relations tab enable/disable based on campaign relations
        self._check_enable_tab_relations()

    def load_lot_dialog(self, lot_id: Optional[int]):
        """Dynamically load and populate lot dialog using gw_fct_cm_getlot"""

        p_data: Dict[str, Any] = {
            "feature": {"tableName": "om_campaign_lot", "idName": "lot_id"},
            "data": {}
        }
        if lot_id:
            p_data["feature"]["id"] = lot_id

        response = tools_gw.execute_procedure("gw_fct_cm_getlot", p_data, schema_name="cm")
        if not response or response.get("status") != "Accepted":
            msg = tools_qt.tr("Failed to load lot form.", context_name="cm")
            tools_qgis.show_warning(msg)
            return

        form_fields = response["body"]["data"].get("fields", [])
        self.fields_form = form_fields
        self.lot_id_value = response["body"].get("feature", {}).get("id")

        # Cache original selected IDs from the server response for the initial load
        self.initial_lot_data = {}
        if not self.is_new_lot:
            for field in form_fields:
                if field.get("columnname") in ["team_id", "expl_id", "sector_id"]:
                    self.initial_lot_data[field.get("columnname")] = field.get("selectedId")

        for field in form_fields:
            widget = self.create_widget_from_field(field)
            if not widget:
                continue

            # Prioritize selectedId for combos, otherwise use value
            if isinstance(widget, QComboBox) and "selectedId" in field:
                self.set_widget_value(widget, field["selectedId"])
            elif "value" in field:
                self.set_widget_value(widget, field["value"])
            if "columnname" in field:
                widget.setProperty("columnname", field["columnname"])
            if "widgetname" in field:
                widget.setObjectName(field["widgetname"])

            label = QLabel(field["label"]) if field.get("label") else None
            tools_gw.add_widget(self.dlg_lot, field, label, widget)

    def create_widget_from_field(self, field: Dict[str, Any]) -> Optional[QWidget]:
        """Create a Qt widget based on field metadata"""
        wtype = field.get("widgettype", "text")
        iseditable = field.get("iseditable", True)

        def create_line_edit():
            widget = QLineEdit()
            if not iseditable:
                widget.setEnabled(False)
            return widget

        def create_text_area():
            widget = QTextEdit()
            if not iseditable:
                widget.setReadOnly(True)
            return widget

        def create_datetime_edit():
            widget = QDateEdit()
            widget.setCalendarPopup(True)
            widget.setDisplayFormat("MM/dd/yyyy")
            value = field.get("value")
            date = QDate.fromString(value, "yyyy-MM-dd") if value else QDate.currentDate()
            widget.setDate(date if date.isValid() else QDate.currentDate())
            if not iseditable:
                widget.setEnabled(False)
            return widget

        def create_check_box():
            widget = QCheckBox()
            if not iseditable:
                widget.setEnabled(False)
            return widget

        def create_combo_box():
            widget = QComboBox()
            ids = field.get("comboIds", [])
            names = field.get("comboNames", [])
            for i, name in enumerate(names):
                widget.addItem(name, ids[i] if i < len(ids) else name)
            if not iseditable:
                widget.setEnabled(False)
            return widget

        widget_map = {
            "text": create_line_edit,
            "textarea": create_text_area,
            "datetime": create_datetime_edit,
            "check": create_check_box,
            "combo": create_combo_box,
        }

        creation_func = widget_map.get(wtype)
        return creation_func() if creation_func else None

    def _on_tab_feature_changed(self) -> None:
        """Handle feature tab change events."""
        # Update self.rel_feature_type just like in Campaign
        self.rel_feature_type = tools_gw.get_signal_change_tab(self.dlg_lot, self.excluded_layers)

    def enable_feature_tabs_by_campaign(self, lot_id: int):
        """Enable or disable feature tabs based on campaign relations."""
        row = tools_db.get_row(f"SELECT campaign_id FROM cm.om_campaign_lot WHERE lot_id = {lot_id}")
        campaign_id = row[0] if row else None
        if not campaign_id:
            return

        feature_types = ['arc', 'node', 'connec', 'link']
        if tools_gw.get_project_type() == 'ud':
            feature_types.append('gully')

        for feature in feature_types:
            count_row = tools_db.get_row(
                f"SELECT COUNT(*) FROM cm.om_campaign_x_{feature} WHERE campaign_id = '{campaign_id}'")
            count = count_row[0] if count_row else 0
            tab_widget = getattr(self.dlg_lot, f"tab_{feature}", None)  # adjust to your widget naming
            if tab_widget:
                idx = self.dlg_lot.tab_feature.indexOf(tab_widget)
                self.dlg_lot.tab_feature.setTabEnabled(idx, count > 0)

    def _load_lot_relations(self, lot_id: int):
        """
        Load related elements into lot relation tabs for the given ID.
        Includes 'gully' only if project type is UD.
        """
        features = ["arc", "node", "connec", "link"]
        if tools_gw.get_project_type() == 'ud':
            features.append("gully")

        for feature in features:
            table_widget_name = f"tbl_campaign_lot_x_{feature}"
            view = getattr(self.dlg_lot, table_widget_name, None)
            if view:
                db_table = f"om_campaign_lot_x_{feature}"
                sql = (
                    f"SELECT * FROM cm.{db_table} "
                    f"WHERE lot_id = {lot_id} "
                    f"ORDER BY id"
                )
                self.populate_tableview(view, sql)

        # Bind table selection to selectByIds via _select_layers_from_table
        for feature in features:
            table_widget_name = f"tbl_campaign_lot_x_{feature}"
            view = getattr(self.dlg_lot, table_widget_name, None)
            if view and view.selectionModel():
                tools_gw.connect_signal(
                    view.selectionModel().selectionChanged,
                    partial(self._select_layers_from_table, feature, view),
                    'lot', f"lot_select_layers_{feature}"
                )

    def get_widget_by_columnname(self, dialog: QWidget, columnname: str) -> Optional[QWidget]:
        """Find a widget in a dialog by its 'columnname' property."""
        for widget in dialog.findChildren(QWidget):
            if widget.property("columnname") == columnname:
                return widget
        return None

    def set_widget_value(self, widget: QWidget, value: Any):
        """Sets the widget value from JSON."""
        if value is None:
            return

        if isinstance(widget, QLineEdit):
            widget.setText(str(value))
        elif isinstance(widget, QTextEdit):
            widget.setPlainText(str(value))
        elif isinstance(widget, QDateEdit):
            date = QDate.fromString(value, "yyyy-MM-dd")
            if date.isValid():
                widget.setDate(date)
        elif isinstance(widget, QCheckBox):
            widget.setChecked(str(value).lower() in ["true", "1"])
        elif isinstance(widget, QComboBox):
            target_id_to_find = None
            try:
                # Ensure we are searching for an integer or string ID
                target_id_to_find = value
            except (ValueError, TypeError):
                pass  # If it's not a number, we can't match it to the list's ID

            if target_id_to_find is not None:
                for i in range(widget.count()):
                    item_data = widget.itemData(i)
                    # Handle cases where itemData is a list like [2, 'expl_02']
                    if isinstance(item_data, (list, tuple)) and item_data:
                        # Compare as strings for safety
                        if str(item_data[0]) == str(target_id_to_find):
                            widget.setCurrentIndex(i)
                            return  # Exit after finding the correct item
                    # Also handle simple data types
                    elif str(item_data) == str(target_id_to_find):
                        widget.setCurrentIndex(i)
                        return

            # If we couldn't find it by data, fall back to a simple text search as a last resort.
            # This handles cases where the data might not be a list.
            fallback_index = widget.findText(str(value))
            if fallback_index > -1:
                widget.setCurrentIndex(fallback_index)

    def _check_enable_tab_relations(self) -> None:
        name_widget = self.get_widget_by_columnname(self.dlg_lot, "name")
        name_ok = bool(name_widget.text().strip()) if name_widget else False

        campaign_combo = self.dlg_lot.findChild(QComboBox, "tab_data_campaign_id")
        campaign_id = campaign_combo.currentData() if campaign_combo else None

        has_relations = False
        if campaign_id:
            features = ["arc", "node", "connec", "link"]
            if tools_gw.get_project_type() == 'ud':
                features.append("gully")
            for feature in features:
                sql = f"SELECT 1 FROM cm.om_campaign_x_{feature} WHERE campaign_id = {campaign_id} LIMIT 1"
                if tools_db.get_row(sql):
                    has_relations = True
                    break

        enable = name_ok and has_relations
        self.dlg_lot.tab_widget.setTabEnabled(self.dlg_lot.tab_widget.indexOf(self.dlg_lot.RelationsTab), enable)

    def _on_tab_change(self, index: int):
        tab = self.dlg_lot.tab_widget.widget(index)
        if tab.objectName() == "RelationsTab":
            # Ensure lot exists before using relations
            if self.is_new_lot and not self.lot_saved:
                self.save_lot(from_change_tab=True)
                self.lot_saved = True  # Only block repeated auto-saves
                self.enable_feature_tabs_by_campaign(self.lot_id)
            # Always prepare the feature ID completer when entering Relations
            try:
                self._update_feature_completer_lot(self.dlg_lot)
            except Exception:
                pass

    def populate_cmb_team(self) -> None:
        """ Fill ComboBox cmb_assigned_to """

        sql = ("SELECT DISTINCT(cat_team.team_id), teamname "
               "FROM cm.cat_team WHERE active is True ORDER BY teamname")
        rows = tools_db.get_rows(sql, commit=True)

        if rows:
            cmb_assigned_to = self.dlg_lot.findChild(QComboBox, "cmb_assigned_to")
            if cmb_assigned_to:
                tools_qt.fill_combo_values(cmb_assigned_to, rows)
        else:
            self.dlg_lot.cmb_assigned_to.clear()

    def update_workorder_fields(self) -> None:
        """Fetch workorder info from DB and populate dynamic form fields."""

        cmb_ot = self.dlg_lot.findChild(QComboBox, "tab_data_wo")
        if not cmb_ot:
            return

        workorder_id = cmb_ot.currentData()
        if not workorder_id:
            return

        # Ejecutar SELECT
        sql = f"""
            SELECT workorder_class, workorder_id, workorder_type, workorder_class, address, serie,  observ
            FROM cm.workorder
            WHERE workorder_id = '{workorder_id}'
        """
        row = tools_db.get_row(sql)
        if not row:
            return

        # Asignar valores a campos del formulario
        mapping = {
            "tab_data_workorder_type": row["workorder_type"],
            "tab_data_workorder_class": row["workorder_class"],
            "tab_data_address": row["address"],
            "tab_data_observ": row["observ"],
        }

        for name, val in mapping.items():
            widget = self.dlg_lot.findChild(QWidget, name)
            if widget:
                self.set_widget_value(widget, val)

    def fill_workorder_fields(self) -> None:
        """ Fill combo boxes of the form """

        # Fill ComboBox cmb_assigned_to
        self.populate_cmb_team()
        # OT Combo is now filled
        cmb_ot = self.dlg_lot.findChild(QComboBox, "tab_data_wo")
        if cmb_ot:
            cmb_ot.currentIndexChanged.connect(self.update_workorder_fields)
            self.update_workorder_fields()  # call once immediately

    def save_lot(self, from_change_tab: bool = False) -> Optional[bool]:
        """Save lot using gw_fct_cm_setlot (dynamic form logic) with mandatory field validation."""

        fields = {}
        list_mandatory = []

        for field in self.fields_form:
            column = field.get("columnname")
            widget = self.dlg_lot.findChild(QWidget, field.get("widgetname"))
            if not widget:
                continue

            widget.setStyleSheet("")

            value = None
            if isinstance(widget, QComboBox):
                value = widget.currentData()
            elif isinstance(widget, QDateEdit):
                value = widget.date().toString("yyyy-MM-dd") if widget.date().isValid() else None
            else:
                value = tools_qt.get_widget_value(self.dlg_lot, widget)

            fields[column] = value

            if field.get("ismandatory", False) and not value:
                widget.setStyleSheet("border: 1px solid red")
                list_mandatory.append(field.get("widgetname"))

        # Post-process fields to extract the integer ID from list values
        expl_val = fields.get("expl_id")
        if isinstance(expl_val, (list, tuple)) and expl_val:
            fields['expl_id'] = expl_val[0]

        sector_val = fields.get("sector_id")
        if isinstance(sector_val, (list, tuple)) and sector_val:
            fields['sector_id'] = sector_val[0]

        if list_mandatory:
            msg = tools_qt.tr("Some mandatory fields are missing. Please fill the required fields (marked in red).", context_name="cm")
            tools_qgis.show_warning(
                msg,
                dialog=self.dlg_lot
            )
            return False

        feature_id = fields.get("lot_id")

        body = {
            "feature": {
                "tableName": "om_campaign_lot",
                "idName": "lot_id",
                "id": feature_id
            },
            "data": {
                "fields": fields
            }
        }

        result = tools_gw.execute_procedure("gw_fct_cm_setlot", body, schema_name="cm")

        if result and result.get("status") == "Accepted":
            self.lot_id = result["body"]["feature"]["id"]
            self.is_new_lot = False

            self._cleanup_map_selection()
            if not from_change_tab:
                self.dlg_lot.accept()
            tools_gw.refresh_selectors(is_cm=True)
        else:
            msg = tools_qt.tr("Error saving lot.", context_name="cm")
            tools_qgis.show_warning(msg)

    def reset_rb_list(self, rb_list: Optional[List[Any]] = None):
        """Resets the main rubber band and clears all rubber band selections in the provided list,
        effectively removing any current feature highlights from the canvas."""
        # Use self.rb_list if no list is provided, for direct calls
        rb_list_to_reset = rb_list if rb_list is not None else self.rb_list
        self.rb_red.reset()
        for rb in rb_list_to_reset:
            rb.reset()

    def manage_rejected(self):
        """Handles the cancellation or rejection of changes by disconnecting selection signals,
        clearing any active feature selections, saving user settings, switching the tool to pan mode, and closing the current dialog."""
        self._cleanup_map_selection()
        tools_gw.save_settings(self.dlg_lot)
        self.iface.actionPan().trigger()
        tools_gw.close_dialog(self.dlg_lot)

    def _on_dialog_rejected(self):
        """Handles cleanup when the dialog is rejected."""
        self._cleanup_map_selection()

    def _cleanup_map_selection(self):
        """Clean up map selections and disconnect signals."""
        tools_qgis.disconnect_signal_selection_changed()
        tools_gw.reset_rubberband(self.rubber_band)
        tools_gw.remove_selection(True, layers=self.rel_layers)
        tools_gw.disconnect_signal('lot')
        tools_qgis.force_refresh_map_canvas()

    def _refresh_relations_table(self):
        """Callback to refresh relations and apply table config if first insert."""
        if self.lot_id:
            # Check if this was the first insert by checking if table was empty before
            current_tab = self.dlg_lot.tab_feature.currentWidget()
            if current_tab:
                feature_type = current_tab.objectName().replace('tab_', '')
                table_widget_name = f"tbl_campaign_lot_x_{feature_type}"
                table_view = getattr(self.dlg_lot, table_widget_name, None)

                if table_view and table_view.model():
                    # If table has exactly 1 row now, it means it was the first insert
                    if table_view.model().rowCount() == 1:
                        self._apply_table_config_for_feature(table_view, feature_type)
                    return

            # If we can't determine or table is empty, reload relations
            self._load_lot_relations(self.lot_id)

    def _apply_table_config_for_feature(self, table_view, feature_type):
        """Apply table configuration for a specific feature type."""
        table_name = f"om_campaign_lot_x_{feature_type}"
        dialog_ref = self.dlg_lot_man if hasattr(self, 'dlg_lot_man') else self.dlg_lot
        tools_gw.set_tablemodel_config(dialog_ref, table_view, table_name, schema_name="cm")

    def _update_completer_and_relations(self):
        """Helper to update both the feature completer and the relations table."""
        self._update_feature_completer_lot(self.dlg_lot)
        if self.lot_id:
            self._load_lot_relations(self.lot_id)

    def _insert_related_feature(self):
        """Handles the 'insert feature' button click action."""
        tools_gw.insert_feature(self, self.dlg_lot, "lot", GwSelectionMode.LOT, False, None, None,
                                refresh_callback=self._refresh_relations_table)
        self._update_feature_completer_lot(self.dlg_lot)
        self._check_and_disable_campaign_combo()

    def _delete_related_records(self):
        """Handles the 'delete records' button click action."""
        tools_gw.delete_records(self, self.dlg_lot, "lot", GwSelectionMode.LOT, None, None, None,
                                refresh_callback=self._refresh_relations_table)
        self._update_feature_completer_lot(self.dlg_lot)
        self._check_and_disable_campaign_combo()

    def _init_snapping_selection(self):
        """Handles the 'snapping selection' button click action."""
        self._update_feature_completer_lot(self.dlg_lot)

    def _select_by_expression(self):
        """Handle the 'select with expression' button click action."""
        self._update_feature_completer_lot(self.dlg_lot)

    def populate_tableview(self, qtable: QTableView, query: str, columns: Optional[List[str]] = None):
        """Populate a QTableView with the results of a SQL query."""

        data = tools_db.get_rows(query)
        if not data:
            qtable.setModel(QStandardItemModel())  # Clear view
            return

        # Auto-detect column names if not provided
        if not columns:
            columns = list(data[0].keys())

        model = QStandardItemModel(len(data), len(columns))
        model.setHorizontalHeaderLabels(columns)

        for row_idx, row in enumerate(data):
            for col_idx, col_name in enumerate(columns):
                value = str(row.get(col_name, ''))
                model.setItem(row_idx, col_idx, QStandardItem(value))

        qtable.setModel(model)

        # Determine table configuration based on widget name
        widget_name = qtable.objectName()
        if "tbl_campaign_lot_x_" in widget_name:
            # Extract feature type from widget name (e.g., "tbl_campaign_lot_x_arc" -> "arc")
            feature_type = widget_name.replace("tbl_campaign_lot_x_", "")
            table_name = f"om_campaign_lot_x_{feature_type}"
        elif "tbl_lots" in widget_name:
            # For lot manager table
            table_name = "v_ui_lot"
        else:
            # Default fallback
            table_name = "v_ui_lot"

        tools_gw.set_tablemodel_config(self.dlg_lot_man if hasattr(self, 'dlg_lot_man') else self.dlg_lot, qtable, table_name, schema_name="cm")

    def get_current_user(self) -> Optional[Dict[str, Any]]:
        """
        Gets the current user's complete data, including role and organization,
        from the CM schema.
        """
        if not tools_db.check_schema('cm'):
            return None

        username = tools_db.get_current_user()
        sql = f"""
            SELECT
                u.user_id,
                u.username,
                u.team_id,
                t.organization_id AS org_id,
                t.role_id AS role
            FROM cm.cat_user AS u
            JOIN cm.cat_team AS t ON u.team_id = t.team_id
            WHERE u.username = '{username}'
        """
        return tools_db.get_row(sql)

    def lot_manager(self):
        """Entry point for opening the Lot Manager dialog (Button 75)."""

        self.dlg_lot_man = LotManagementUi(self)
        tools_gw.load_settings(self.dlg_lot_man)

        self.dlg_lot_man.tbl_lots.setEditTriggers(QTableView.EditTrigger.NoEditTriggers)
        self.dlg_lot_man.tbl_lots.setSelectionBehavior(QTableView.SelectionBehavior.SelectRows)

        # Fill combo values for lot date_filter_type combo
        date_types = [['real_startdate', tools_qt.tr("Start date", context_name="cm")],
                      ['real_enddate', tools_qt.tr("End date", context_name="cm")],
                      ['startdate', tools_qt.tr("Planned start date", context_name="cm")],
                      ['enddate', tools_qt.tr("Planned end date", context_name="cm")]]
        tools_qt.fill_combo_values(self.dlg_lot_man.cmb_date_filter_type, date_types, 1, sort_combo=False)

        # Fill combo values for lot status (based on sys_typevalue table)
        sql = "SELECT id, idval FROM cm.sys_typevalue WHERE typevalue = 'lot_status' ORDER BY id"
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_lot_man.cmb_estat, rows, index_to_show=1, add_empty=True)

        self.init_filters()
        self.load_lots_into_manager()

        self.dlg_lot_man.btn_cancel.clicked.connect(self.dlg_lot_man.reject)
        self.dlg_lot_man.date_event_from.dateChanged.connect(self.filter_lot)
        self.dlg_lot_man.date_event_to.dateChanged.connect(self.filter_lot)
        self.dlg_lot_man.cmb_date_filter_type.currentIndexChanged.connect(self.filter_lot)
        self.dlg_lot_man.chk_show_nulls.stateChanged.connect(self.filter_lot)
        self.dlg_lot_man.txt_lot_name.textChanged.connect(self.filter_lot)
        self.dlg_lot_man.cmb_estat.currentIndexChanged.connect(self.filter_lot)
        self.dlg_lot_man.btn_open.clicked.connect(self.open_lot)
        self.dlg_lot_man.tbl_lots.doubleClicked.connect(self.open_lot)
        self.dlg_lot_man.btn_delete.clicked.connect(self.delete_lot)

        tools_gw.open_dialog(self.dlg_lot_man, dlg_name="lot_management")

    def load_lots_into_manager(self):
        """Load campaign data into the campaign management table"""
        if not hasattr(self.dlg_lot_man, "tbl_lots"):
            return
        self.filter_lot()

    def init_filters(self):
        current_date = QDate.currentDate()

        where_clause = ""
        # Guard privilege for org filter
        user_info = None
        try:
            username = tools_db.get_current_user()
            sql = f"""
                SELECT t.role_id, t.organization_id
                FROM cm.cat_user u
                JOIN cm.cat_team t ON u.team_id = t.team_id
                WHERE u.username = '{username}'
            """
            user_info = tools_db.get_row(sql, is_admin=True)
        except Exception:
            user_info = None

        if user_info:
            role = user_info[0]
            org_id = user_info[1]
            if role not in ('role_cm_admin'):
                if org_id is not None:
                    where_clause = f" WHERE campaign_name IN (SELECT name FROM cm.om_campaign WHERE organization_id = {org_id})"

        sql = f'SELECT MIN(startdate), MAX(startdate) FROM cm.v_ui_campaign_lot{where_clause}'
        row = tools_db.get_rows(sql)

        if row and row[0] and row[0][0] is not None:
            self.dlg_lot_man.date_event_from.setDate(row[0][0])
            self.dlg_lot_man.date_event_to.setDate(row[0][1])
        else:
            self.dlg_lot_man.date_event_from.setDate(current_date)
            self.dlg_lot_man.date_event_to.setDate(current_date)

    def filter_lot(self):
        """Filter lot records based on date range and date type."""
        filters = []

        # Directly query the cm schema to get user's role and organization
        user_info = None
        try:
            username = tools_db.get_current_user()
            sql = f"""
                SELECT t.role_id, t.organization_id
                FROM cm.cat_user u
                JOIN cm.cat_team t ON u.team_id = t.team_id
                WHERE u.username = '{username}'
            """
            user_info = tools_db.get_row(sql, is_admin=True)
        except Exception:
            user_info = None

        if user_info:
            role = user_info[0]
            org_id = user_info[1]
            if role not in ('role_cm_admin'):
                if org_id is not None:
                    filters.append(f"campaign_name IN (SELECT name FROM cm.om_campaign WHERE organization_id = {org_id})")

        # get value to now column filter (startdate, enddate, real_startdate, real_enddate)
        date_type = tools_qt.get_combo_value(self.dlg_lot_man, self.dlg_lot_man.cmb_date_filter_type, 0)
        if date_type and date_type != -1:
            # get dates
            date_from = self.dlg_lot_man.date_event_from.date()
            date_to = self.dlg_lot_man.date_event_to.date()

            # start date end date logic
            if date_from > date_to:
                self.dlg_lot_man.date_event_to.setDate(date_from)
                date_to = date_from

            interval = f"'{date_from.toString('yyyy-MM-dd')} 00:00:00' AND '{date_to.toString('yyyy-MM-dd')} 23:59:59'"
            date_filter = f"({date_type} BETWEEN {interval}"

            # show nulls if checked
            if hasattr(self.dlg_lot_man, "chk_show_nulls") and self.dlg_lot_man.chk_show_nulls.isChecked():
                date_filter += f" OR {date_type} IS NULL)"
            else:
                date_filter += ")"

            filters.append(date_filter)

        # filter by name logic
        name_value = self.dlg_lot_man.txt_lot_name.text().strip()
        if name_value:
            filters.append(f"name ILIKE '%{name_value}%'")

        # filter by status
        status_value = tools_qt.get_combo_value(self.dlg_lot_man, self.dlg_lot_man.cmb_estat, 0)
        if status_value:
            filters.append(f"status = '{status_value}'")

        # build and execute full query
        where_clause = " AND ".join(filters)
        query = "SELECT * FROM cm.v_ui_campaign_lot"
        if where_clause:
            query += f" WHERE {where_clause}"
        query += " ORDER BY lot_id DESC"
        self.populate_tableview(self.dlg_lot_man.tbl_lots, query)

    def open_lot(self, index: Optional[QModelIndex] = None):
        """Open selected lot in edit mode, from button or double click."""

        if index and index.isValid():
            model = index.model()
            row = index.row()
            id_index = model.index(row, 0)
            lot_ids = [model.data(id_index)]
        else:
            selected = self.dlg_lot_man.tbl_lots.selectionModel().selectedRows()
            if not selected:
                msg = tools_qt.tr("Please select a lot to open.", context_name="cm")
                tools_qgis.show_warning(msg, dialog=self.dlg_lot_man)
                return
            lot_ids = [index.data() for index in selected]

        for lot_id in lot_ids:
            try:
                lot_id = int(lot_id)
                if lot_id > 0:
                    self.manage_lot(lot_id=lot_id, is_new=False)
            except (ValueError, TypeError):
                msg = tools_qt.tr("Invalid lot ID.", context_name="cm")
                tools_qgis.show_warning(msg)

    def delete_lot(self):
        """Delete selected lot(s) with confirmation."""

        selected = self.dlg_lot_man.tbl_lots.selectionModel().selectedRows()
        if not selected:
            msg = tools_qt.tr("Select a lot to delete.", context_name="cm")
            tools_qgis.show_warning(msg, dialog=self.dlg_lot_man)
            return
        msg = tools_qt.tr("Are you sure you want to delete {0} lot(s)?", context_name="cm")
        msg_params = (len(selected),)
        if not tools_qt.show_question(msg, msg_params=msg_params, title=tools_qt.tr("Delete Lot(s)", context_name="cm")):
            return
        deleted = 0
        for index in selected:
            lot_id = index.data()
            if not str(lot_id).isdigit():
                continue
            for table in ['arc', 'node', 'connec', 'gully', 'link']:
                # Check if the table exists before executing the update
                table_name = f"cm.om_campaign_lot_x_{table}"
                check_table_sql = (
                    f"SELECT to_regclass('{table_name}') IS NOT NULL AS exists"
                )
                res = tools_db.get_row(check_table_sql)
                if res and (res.get('exists') if isinstance(res, dict) else res[0]):
                    sql = f"UPDATE {table_name} SET action = 4 WHERE lot_id = {lot_id}"
                    tools_db.execute_sql(sql)
            sql = f"DELETE FROM cm.om_campaign_lot WHERE lot_id = {lot_id}"
            if tools_db.execute_sql(sql):
                deleted += 1
        msg = tools_qt.tr("{0} lot(s) deleted.", context_name="cm")
        msg_params = (deleted,)
        tools_qgis.show_info(msg, msg_params=msg_params, dialog=self.dlg_lot_man)
        tools_gw.refresh_selectors(is_cm=True)
        self.filter_lot()

    def _select_layers_from_table(self, feature: str, view: QTableView, *args):
        """Select current table rows on map layers (Campaign-like yellow selection)."""
        try:
            model = view.model()
            sel = view.selectionModel()
            if not model or not sel:
                return
            id_col = f"{feature}_id"
            col_idx = tools_qt.get_col_index_by_col_name(view, id_col)
            if col_idx is None or col_idx == -1:
                return
            ids = []
            for idx in sel.selectedRows():
                try:
                    ids.append(str(model.index(idx.row(), col_idx).data()))
                except Exception:
                    continue
            if not ids:
                return
            if feature not in self.rel_layers or not self.rel_layers.get(feature):
                self.rel_layers[feature] = tools_gw.get_layers_from_feature_type(feature)
            layers = self.rel_layers.get(feature) or []
            if not layers:
                return
            expr = QgsExpression(f"{id_col} IN ({','.join(ids)})")
            tools_qgis.select_features_by_ids(feature, expr, self.rel_layers)
        except Exception:
            pass

    def _update_feature_completer_lot(self, dlg: QDialog):
        """Update the feature completer for lot based on current tab and lot restrictions."""
        # Identify the current tab and derive feature info
        tab_widget = dlg.tab_feature.currentWidget()
        if not tab_widget:
            return

        feature = tab_widget.objectName().replace('tab_', '')
        if not feature:
            return

        # Get the allowed IDs for this lot and feature
        lot_id = self.lot_id_value
        if not lot_id:
            return

        # Set up per-keystroke typeahead (prefix, LIMIT 100) against campaign-linked IDs only
        feature_id_lineedit = dlg.findChild(QLineEdit, "feature_id")
        if feature_id_lineedit:
            # Reuse one model/completer
            if not hasattr(self, '_lot_feature_model') or self._lot_feature_model is None:
                self._lot_feature_model = QStringListModel(dlg)
            if not hasattr(self, '_lot_feature_completer') or self._lot_feature_completer is None:
                self._lot_feature_completer = QCompleter(self._lot_feature_model, dlg)
                self._lot_feature_completer.setCaseSensitivity(Qt.CaseSensitivity.CaseInsensitive)
                self._lot_feature_completer.setCompletionMode(QCompleter.CompletionMode.PopupCompletion)
                feature_id_lineedit.setCompleter(self._lot_feature_completer)

            try:
                feature_id_lineedit.textEdited.disconnect()
            except Exception:
                pass
            feature_id_lineedit.textEdited.connect(partial(self._lot_feature_typeahead, dlg, feature, lot_id))

    def _lot_feature_typeahead(self, dlg: QDialog, feature: str, lot_id: int, text: str = ''):
        """Typeahead for lot: search only among features attached to the selected campaign.

        SQL uses campaign_id derived from lot and filters by id prefix with LIMIT 100.
        """
        if not text or len(text) < 1:
            # Clear to avoid massive preload
            if hasattr(self, '_lot_feature_model') and self._lot_feature_model is not None:
                self._lot_feature_model.setStringList([])
            return

        # Resolve campaign
        row = tools_db.get_row(f"SELECT campaign_id FROM cm.om_campaign_lot WHERE lot_id = {lot_id}")
        campaign_id = row[0] if row else None
        if not campaign_id:
            if hasattr(self, '_lot_feature_model') and self._lot_feature_model is not None:
                self._lot_feature_model.setStringList([])
            return

        id_col = f"{feature}_id"
        safe = str(text).replace("'", "''")
        sql = (
            f"SELECT {id_col}::text AS val "
            f"FROM cm.om_campaign_x_{feature} "
            f"WHERE campaign_id = {campaign_id} "
            f"  AND {id_col}::text ILIKE '{safe}%' "
            f"ORDER BY {id_col} LIMIT 100"
        )
        rows = tools_db.get_rows(sql)
        values = [r.get('val') for r in (rows or []) if r.get('val')]
        if hasattr(self, '_lot_feature_model') and self._lot_feature_model is not None:
            self._lot_feature_model.setStringList(values)
            try:
                if self.dlg_lot and self.dlg_lot.feature_id and self.dlg_lot.feature_id.completer():
                    self.dlg_lot.feature_id.completer().complete()
            except Exception:
                pass

    def get_allowed_features_for_lot(self, lot_id: int, feature_type: str) -> Optional[List[Any]]:
        """Return list of allowed feature IDs for the lot's campaign and feature tab."""
        if not feature_type or feature_type not in ['arc', 'node', 'connec', 'gully', 'link']:
            return None

        try:
            # Get campaign from lot with validation
            row = tools_db.get_row(f"SELECT campaign_id FROM cm.om_campaign_lot WHERE lot_id = {lot_id}")
            if not row or not row[0]:
                return None

            campaign_id = row[0]
            id_column = f"{feature_type}_id"

            # Get all feature IDs from the campaign for this feature type
            sql = f"""
                SELECT {id_column}::text AS {id_column}
                FROM cm.om_campaign_x_{feature_type}
                WHERE campaign_id = {campaign_id}
                ORDER BY {id_column}
            """
            rows = tools_db.get_rows(sql)
            result = [row[id_column] for row in (rows or []) if row.get(id_column)]
            return result
        except Exception:
            return None

    def resources_management(self):
        """Manages resources by coordinating the loading, display, and updates of resource-related information
        (such as teams and vehicles) within the application's UI.
        """

        # Get user information
        user_data = self.get_current_user()

        # Chek data
        if not user_data:
            return

        self.user_data = user_data

        # Create the dialog
        self.dlg_resources_man = ResourcesManagementUi(self)
        tools_gw.load_settings(self.dlg_resources_man)

        # Create tables dictionary
        self.dict_tables = {
            "cat_organization": {
                "query": "SELECT organization_id::text, code, orgname, descript, active::text FROM cm.cat_organization",
                "idname": "organization_id",
                "widget": tools_qt.get_widget(self.dlg_resources_man, "tbl_organizations")
            },
            "cat_team": {
                "query": "SELECT team_id::text, co.orgname, ct.code, teamname, ct.descript, ct.active::text, role_id" +
                         " FROM cm.cat_team ct INNER JOIN cm.cat_organization co ON co.organization_id = ct.organization_id",
                "idname": "team_id",
                "widget": tools_qt.get_widget(self.dlg_resources_man, "tbl_teams")
            },
            "cat_user": {
                "query": "SELECT user_id::text, COALESCE(ct.teamname, 'No team') as teamname, COALESCE(ct.code, '') as code, username, cu.active::text" +
                         " FROM cm.cat_user cu LEFT JOIN cm.cat_team ct ON cu.team_id = ct.team_id",
                "idname": "user_id",
                "widget": tools_qt.get_widget(self.dlg_resources_man, "tbl_users"),
                "cmbParent": tools_qt.get_widget(self.dlg_resources_man, "cmb_team")
            }
        }

        # Init variables
        self.org_id = None
        self.team_id = None
        self.user_id = None
        self.tab_organizations = 0
        self.tab_campaign = 3

        # Populate combos
        # Create sql query to get all teams
        sql = "SELECT team_id AS id, teamname AS idval FROM cm.cat_team"

        # Check if user is superadmin
        if self.user_data["role"] == "role_cm_admin":

            # Create list of tables
            tables = ["cat_organization", "cat_team", "cat_user"]

            # Fill tables
            for table in tables:
                self._populate_resource_tableview(table)

            # Setup campaign selector tab (cm.selector_campaign)
            self._setup_campaign_selector_tab()

            # Set signals for manage organizations
            self.dlg_resources_man.txt_orgname.textChanged.connect(partial(self.txt_org_name_changed))
        else:

            # Remove tab campaign
            self.dlg_resources_man.tab_main.removeTab(self.tab_campaign)

            # Remove tab organizations
            self.dlg_resources_man.tab_main.removeTab(self.tab_organizations)

            # Filter teams table by the user organization selected
            self.filter_teams_by_name()

            # Filter teams combo
            sql += f" WHERE organization_id = {self.user_data['org_id']}"

            # Create sql filter and populate table
            sql_filter = f"WHERE (ct.team_id = any(SELECT team_id FROM cm.cat_team WHERE organization_id = {self.user_data['org_id']}) OR cu.team_id IS NULL)"
            self._populate_resource_tableview("cat_user", sql_filter)

        # Fill teams combo
        rows = tools_db.get_rows(sql)
        if rows:
            tools_qt.fill_combo_values(self.dlg_resources_man.cmb_team, rows, 1, add_empty=True)

        # Set signals for tables
        self.dict_tables["cat_team"]["widget"].doubleClicked.connect(partial(self.selected_row, "cat_team"))
        self.dict_tables["cat_user"]["widget"].doubleClicked.connect(partial(self.selected_row, "cat_user"))

        # Set signals for manage teams
        self.dlg_resources_man.btn_team_create.clicked.connect(partial(self.open_create_team))
        self.dlg_resources_man.btn_team_update.clicked.connect(partial(self.open_create_team, True))
        self.dlg_resources_man.btn_team_delete.clicked.connect(partial(self.delete_registers, "cat_team"))
        # Toggle active on teams
        if hasattr(self.dlg_resources_man, 'btn_team_toggle_active'):
            self.dlg_resources_man.btn_team_toggle_active.clicked.connect(partial(self.toggle_active_records, "cat_team"))
        self.dlg_resources_man.txt_teams.textChanged.connect(partial(self.filter_teams_by_name))

        # Set signals for manage users (only team filtering, no user management buttons in UI)
        self.dlg_resources_man.cmb_team.currentIndexChanged.connect(partial(self.filter_users_table))
        if hasattr(self.dlg_resources_man, 'btn_assign_team'):
            self.dlg_resources_man.btn_assign_team.setVisible(False)
        self.dlg_resources_man.btn_change_team.clicked.connect(partial(self.change_team_for_user))
        self.dlg_resources_man.btn_remove_team.clicked.connect(partial(self.remove_team_from_user))
        # Toggle active on users
        if hasattr(self.dlg_resources_man, 'btn_user_toggle_active'):
            self.dlg_resources_man.btn_user_toggle_active.clicked.connect(partial(self.toggle_active_records, "cat_user"))

        self.dlg_resources_man.btn_close.clicked.connect(self._close_resources_management)

        dlg_rm = self.dlg_resources_man
        dlg_rm.closeEvent = lambda ev, d=dlg_rm: self._resources_management_close_event(d, ev)

        # Open form
        tools_gw.open_dialog(self.dlg_resources_man, "resources_management")

    def _close_resources_management(self):
        dlg = self.dlg_resources_man
        if not self._confirm_discard_campaign_selector_if_dirty(dlg):
            return
        dlg._campaign_selector_force_close = True
        tools_gw.close_dialog(dlg)

    def _resources_management_close_event(self, dlg, event):
        if getattr(dlg, "_campaign_selector_force_close", False):
            dlg._campaign_selector_force_close = False
            QDialog.closeEvent(dlg, event)
            return
        if not self._confirm_discard_campaign_selector_if_dirty(dlg):
            event.ignore()
            return
        QDialog.closeEvent(dlg, event)

    def _confirm_discard_campaign_selector_if_dirty(self, dlg) -> bool:
        if not hasattr(dlg, "_selector_original_rows"):
            return True
        if not self._campaign_selector_is_dirty(dlg):
            return True
        msg = tools_qt.tr(
            "You have unsaved changes in the campaign selector. Close without saving?",
            context_name="cm",
        )
        return tools_qt.show_question(
            msg, tools_qt.tr("Confirm", context_name="cm"), buttons=["Yes", "No"]
        )

    def _get_campaign_selector_row_values(self, dlg, row_idx):
        """Return (cur_user_username, campaign_id_int_or_None) for tbl_campaign row."""
        tbl = dlg.tbl_campaign
        item = tbl.item(row_idx, 0)
        cur_user = None
        if item:
            data = item.data(Qt.ItemDataRole.UserRole)
            cur_user = data if data not in (None, "") else None
            if cur_user is None and item.text():
                cur_user = item.text()
        combo_c = tbl.cellWidget(row_idx, 1)
        campaign_raw = tools_qt.get_combo_value(dlg, combo_c, 0) if combo_c else None
        try:
            campaign_id = (
                int(campaign_raw) if campaign_raw not in (None, "", -1, "-1") else None
            )
        except (TypeError, ValueError):
            campaign_id = None
        return cur_user, campaign_id

    @staticmethod
    def _norm_campaign_selector_user(u):
        if u is None or str(u).strip() == "":
            return None
        return str(u).strip()

    @staticmethod
    def _norm_campaign_selector_campaign(c):
        if c in (None, "", -1, "-1"):
            return None
        try:
            return int(c)
        except (TypeError, ValueError):
            return None

    def _campaign_selector_is_dirty(self, dlg) -> bool:
        if not hasattr(dlg, "tbl_campaign"):
            return False
        if not hasattr(dlg, "_selector_original_rows"):
            return False
        tbl = dlg.tbl_campaign
        originals = getattr(dlg, "_selector_row_originals", [])
        original_set = getattr(dlg, "_selector_original_rows", set())
        if tbl.rowCount() != len(originals):
            return True
        complete_pairs = []
        for row_idx in range(tbl.rowCount()):
            cur_user, campaign_id = self._get_campaign_selector_row_values(dlg, row_idx)
            nu = self._norm_campaign_selector_user(cur_user)
            nc = self._norm_campaign_selector_campaign(campaign_id)
            has_u = nu is not None
            has_c = nc is not None
            if has_u ^ has_c:
                return True
            ou, oc = originals[row_idx]
            nou = self._norm_campaign_selector_user(ou)
            noc = self._norm_campaign_selector_campaign(oc)
            if (nu, nc) != (nou, noc):
                return True
            if has_u and has_c:
                complete_pairs.append((nu, nc))
        if len(complete_pairs) != len(set(complete_pairs)):
            return True
        return set(complete_pairs) != original_set

    def _setup_campaign_selector_tab(self):
        """Setup campaign selector tab: tbl_campaign, cmb_user, cmb_campaign, btn_campaign_add/remove/accept."""
        dlg = self.dlg_resources_man
        if not hasattr(dlg, 'tbl_campaign'):
            return
        organization_id = 3

        sql_users = (
            "SELECT user_id as id, username as idval "
            "FROM cm.cat_user "
            "LEFT JOIN cm.cat_team ON cat_user.team_id = cat_team.team_id "
            f"WHERE cat_team.organization_id = {organization_id} "
            "ORDER BY username"
        )
        user_rows = tools_db.get_rows(sql_users)
        tools_qt.fill_combo_values(dlg.cmb_user, user_rows, index_to_show=1, add_empty=True)

        sql_campaigns = (
            "SELECT campaign_id as id, name as idval "
            "FROM cm.om_campaign "
            "WHERE status IN (3, 4, 6, 8, 9) "
            "ORDER BY name"
        )
        campaign_rows = tools_db.get_rows(sql_campaigns)
        tools_qt.fill_combo_values(dlg.cmb_campaign, campaign_rows, index_to_show=1, add_empty=True)

        dlg._campaign_selector_user_rows = user_rows
        dlg._campaign_selector_campaign_rows = campaign_rows
        self._populate_campaign_selector_table(dlg, user_rows, campaign_rows)
        self._filter_campaign_selector_table(dlg)
        dlg.btn_campaign_add.clicked.connect(
            partial(self._add_campaign_selector_row, dlg, user_rows, campaign_rows)
        )
        dlg.btn_campaign_remove.clicked.connect(partial(self._delete_campaign_selector_rows, dlg))
        dlg.cmb_user.currentIndexChanged.connect(partial(self._filter_campaign_selector_table, dlg))
        dlg.cmb_campaign.currentIndexChanged.connect(partial(self._filter_campaign_selector_table, dlg))
        dlg.btn_campaign_save.clicked.connect(partial(self._save_campaign_selector_table, dlg))
        tools_gw.add_icon(dlg.btn_campaign_add, "111")
        tools_gw.add_icon(dlg.btn_campaign_remove, "112")

    def _populate_campaign_selector_table(self, dlg, user_rows, campaign_rows):
        """Populate tbl_campaign with cm.selector_campaign rows; user col text, campaign col QComboBox."""
        tbl = dlg.tbl_campaign
        tbl.setSortingEnabled(False)
        tbl.setColumnCount(2)
        tbl.setHorizontalHeaderLabels([tools_qt.tr("User", context_name="cm"), tools_qt.tr("Campaign", context_name="cm")])

        usernames = [r[1] if not isinstance(r, dict) else r.get('idval') for r in (user_rows or [])]
        campaign_ids = [r[0] if not isinstance(r, dict) else r.get('id') for r in (campaign_rows or [])]
        if not usernames or not campaign_ids:
            selector_rows = []
        else:
            sql = (
                "SELECT cur_user, campaign_id FROM cm.selector_campaign "
                "WHERE cur_user = ANY(%s) AND campaign_id = ANY(%s) "
                "ORDER BY cur_user, campaign_id"
            )
            selector_rows = tools_db.get_rows(sql, params=(usernames, campaign_ids)) or []
        tbl.setRowCount(len(selector_rows))

        dlg._selector_row_originals = []
        for row_idx, row in enumerate(selector_rows):
            cur_user = row['cur_user'] if isinstance(row, dict) else row[0]
            campaign_id = row['campaign_id'] if isinstance(row, dict) else row[1]
            nu = self._norm_campaign_selector_user(cur_user)
            nc = self._norm_campaign_selector_campaign(campaign_id)
            item_user = QTableWidgetItem(nu or "")
            item_user.setData(Qt.ItemDataRole.UserRole, nu)
            item_user.setFlags(
                Qt.ItemFlag.ItemIsSelectable | Qt.ItemFlag.ItemIsEnabled
            )
            tbl.setItem(row_idx, 0, item_user)
            combo_campaign = QComboBox()
            tools_qt.fill_combo_values(combo_campaign, campaign_rows, index_to_show=1, add_empty=True)
            tools_qt.set_combo_value(combo_campaign, campaign_id, 0)
            combo_campaign.currentIndexChanged.connect(partial(self._update_campaign_selector_row_bold, dlg, row_idx))
            tbl.setCellWidget(row_idx, 1, combo_campaign)
            dlg._selector_row_originals.append((nu, nc))

        dlg._selector_original_rows = {
            (
                self._norm_campaign_selector_user(
                    row['cur_user'] if isinstance(row, dict) else row[0]
                ),
                self._norm_campaign_selector_campaign(
                    row['campaign_id'] if isinstance(row, dict) else row[1]
                ),
            )
            for row in selector_rows
        }

    def _update_campaign_selector_row_bold(self, dlg, row_idx):
        """Bold user cell and campaign combo if row differs from original."""
        originals = getattr(dlg, '_selector_row_originals', [])
        if row_idx >= len(originals):
            return
        tbl = dlg.tbl_campaign
        item_u = tbl.item(row_idx, 0)
        combo_c = tbl.cellWidget(row_idx, 1)
        if not item_u or not combo_c:
            return
        orig_user, orig_campaign = originals[row_idx]
        cur_user, cur_campaign_int = self._get_campaign_selector_row_values(dlg, row_idx)
        nu = self._norm_campaign_selector_user(cur_user)
        nou = self._norm_campaign_selector_user(orig_user)
        nc = self._norm_campaign_selector_campaign(cur_campaign_int)
        noc = self._norm_campaign_selector_campaign(orig_campaign)
        changed = (nu, nc) != (nou, noc)
        font = QFont()
        font.setBold(changed)
        item_u.setFont(font)
        combo_c.setFont(font)

    def _filter_campaign_selector_table(self, dlg):
        """Show/hide rows based on cmb_user and cmb_campaign filter."""
        tbl = dlg.tbl_campaign
        filter_user = tools_qt.get_combo_value(dlg, dlg.cmb_user, 1)
        if filter_user in (None, "", -1, "-1"):
            nf = None
        else:
            nf = self._norm_campaign_selector_user(filter_user)
        filter_campaign = tools_qt.get_combo_value(dlg, dlg.cmb_campaign, 0)
        for row_idx in range(tbl.rowCount()):
            row_user, row_campaign = self._get_campaign_selector_row_values(dlg, row_idx)
            nu = self._norm_campaign_selector_user(row_user)
            match_user = nf is None or nu == nf
            match_campaign = filter_campaign in (None, "", -1, "-1") or (
                row_campaign is not None
                and str(row_campaign) == str(filter_campaign)
            )
            tbl.setRowHidden(row_idx, not (match_user and match_campaign))

    def _add_campaign_selector_row(self, dlg, user_rows, campaign_rows):
        """Append a new row; user from cmb_user (text), campaign from cmb_campaign if set.
        If no cmb_user or cmb_campaign is set, show a warning and do not add a row."""
        sel_user = tools_qt.get_combo_value(dlg, dlg.cmb_user, 1)
        sel_campaign = tools_qt.get_combo_value(dlg, dlg.cmb_campaign, 0)
        if sel_user in (None, "", -1, "-1") or sel_campaign in (None, "", -1, "-1"):
            msg = tools_qt.tr(
                "Please select both a user and a campaign before adding a row.",
                context_name="cm",
            )
            tools_qgis.show_warning(msg, dialog=dlg)
            return
        tbl = dlg.tbl_campaign
        row_idx = tbl.rowCount()
        tbl.insertRow(row_idx)
        user_disp = str(sel_user).strip()
        item_user = QTableWidgetItem(user_disp)
        item_user.setData(Qt.ItemDataRole.UserRole, user_disp or None)
        item_user.setFlags(
            Qt.ItemFlag.ItemIsSelectable | Qt.ItemFlag.ItemIsEnabled
        )
        tbl.setItem(row_idx, 0, item_user)
        combo_campaign = QComboBox()
        tools_qt.fill_combo_values(combo_campaign, campaign_rows, index_to_show=1, add_empty=True)
        tools_qt.set_combo_value(combo_campaign, sel_campaign, 0)
        combo_campaign.currentIndexChanged.connect(partial(self._update_campaign_selector_row_bold, dlg, row_idx))
        tbl.setCellWidget(row_idx, 1, combo_campaign)
        dlg._selector_row_originals.append((None, None))
        self._update_campaign_selector_row_bold(dlg, row_idx)
        self._filter_campaign_selector_table(dlg)

    def _delete_campaign_selector_rows(self, dlg):
        """Remove selected rows from tbl_campaign."""
        tbl = dlg.tbl_campaign
        originals = getattr(dlg, '_selector_row_originals', [])
        for idx in sorted(tbl.selectionModel().selectedRows(), key=lambda i: i.row(), reverse=True):
            row = idx.row()
            if row < len(originals):
                dlg._selector_row_originals.pop(row)
            tbl.removeRow(row)

    def _save_campaign_selector_table(self, dlg):
        """Persist tbl_campaign changes to cm.selector_campaign and cm.selector_lot."""
        tbl = dlg.tbl_campaign
        complete_list = []
        for row_idx in range(tbl.rowCount()):
            cur_user, campaign_id = self._get_campaign_selector_row_values(dlg, row_idx)
            nu = self._norm_campaign_selector_user(cur_user)
            nc = self._norm_campaign_selector_campaign(campaign_id)
            if nu is None or nc is None:
                continue
            complete_list.append((nu, nc))
        if len(complete_list) != len(set(complete_list)):
            msg = tools_qt.tr(
                "Duplicate user and campaign pairs are not allowed. Remove duplicates before saving.",
                context_name="cm",
            )
            tools_qgis.show_warning(msg, dialog=dlg)
            return
        current = set(complete_list)

        original = getattr(dlg, '_selector_original_rows', set())
        to_insert = current - original
        to_delete = original - current

        if not to_insert and not to_delete:
            msg = tools_qt.tr("No changes to save.", context_name="cm")
            tools_qgis.show_info(msg, dialog=dlg)
            return

        campaign_names = {}
        for r in getattr(dlg, '_campaign_selector_campaign_rows', []) or []:
            cid = r[0] if not isinstance(r, dict) else r.get('id')
            cname = r[1] if not isinstance(r, dict) else r.get('idval')
            campaign_names[cid] = cname or str(cid)
        lines = []
        if to_delete:
            lines.append(tools_qt.tr("To remove:", context_name="cm"))
            for cur_user, campaign_id in sorted(to_delete, key=lambda x: (x[0], x[1])):
                cname = campaign_names.get(campaign_id, str(campaign_id))
                lines.append(f"  - {cur_user} / {cname}")
        if to_insert:
            lines.append(tools_qt.tr("To add:", context_name="cm"))
            for cur_user, campaign_id in sorted(to_insert, key=lambda x: (x[0], x[1])):
                cname = campaign_names.get(campaign_id, str(campaign_id))
                lines.append(f"  - {cur_user} / {cname}")
        inf_text = "\n".join(lines)
        msg = tools_qt.tr("Save these changes to campaign selector?", context_name="cm")
        if not tools_qt.show_question(msg, tools_qt.tr("Confirm", context_name="cm"), inf_text=inf_text, force_action=True, buttons=["Save", "Cancel"]):
            return

        for cur_user, campaign_id in to_delete:
            sql = tools_db.dao.mogrify(
                "DELETE FROM cm.selector_campaign WHERE cur_user = %s AND campaign_id = %s",
                (cur_user, campaign_id)
            )
            tools_db.execute_sql(sql)
            sql = tools_db.dao.mogrify(
                "DELETE FROM cm.selector_lot WHERE cur_user = %s AND lot_id IN "
                "(SELECT lot_id FROM cm.om_campaign_lot WHERE campaign_id = %s)",
                (cur_user, campaign_id)
            )
            tools_db.execute_sql(sql)

        for cur_user, campaign_id in to_insert:
            sql = tools_db.dao.mogrify(
                "INSERT INTO cm.selector_campaign (cur_user, campaign_id) VALUES (%s, %s) "
                "ON CONFLICT (cur_user, campaign_id) DO NOTHING",
                (cur_user, campaign_id),
            )
            tools_db.execute_sql(sql)
            sql = tools_db.dao.mogrify(
                "INSERT INTO cm.selector_lot (cur_user, lot_id) "
                "SELECT %s, lot_id FROM cm.om_campaign_lot WHERE campaign_id = %s "
                "ON CONFLICT (cur_user, lot_id) DO NOTHING",
                (cur_user, campaign_id),
            )
            tools_db.execute_sql(sql)

        dlg._selector_original_rows = current
        # Sync row originals and reset bold
        dlg._selector_row_originals = []
        for row_idx in range(tbl.rowCount()):
            item_u = tbl.item(row_idx, 0)
            combo_c = tbl.cellWidget(row_idx, 1)
            cur_user, campaign_id = self._get_campaign_selector_row_values(dlg, row_idx)
            nu = self._norm_campaign_selector_user(cur_user)
            nc = self._norm_campaign_selector_campaign(campaign_id)
            dlg._selector_row_originals.append((nu, nc))
            if item_u:
                font = item_u.font()
                font.setBold(False)
                item_u.setFont(font)
            if combo_c:
                font = combo_c.font()
                font.setBold(False)
                combo_c.setFont(font)
        msg = tools_qt.tr("Changes saved.", context_name="cm")
        tools_qgis.show_info(msg, dialog=dlg)

    def txt_org_name_changed(self):
        """ Filter table by organization id """

        org_name = tools_qt.get_text(self.dlg_resources_man, "txt_orgname")
        sql_filter = f"WHERE orgname ILIKE '%{org_name}%'" if org_name and org_name.strip() else None
        self._populate_resource_tableview("cat_organization", sql_filter)

    def filter_teams_by_name(self):
        """ Filter teams table by team name """

        team_name = tools_qt.get_text(self.dlg_resources_man, "txt_teams")

        # Build sql filtering by team name and organization
        if team_name and team_name.strip():
            # Filter by team name
            if self.user_data["role"] != "role_cm_admin":
                # For non-admin users, also filter by organization
                sql_filter = f"WHERE ct.teamname ILIKE '%{team_name}%' AND co.organization_id = {self.user_data['org_id']}"
            else:
                # For admin users, only filter by team name
                sql_filter = f"WHERE ct.teamname ILIKE '%{team_name}%'"
        else:
            # No team name filter - show all teams for admin, or organization teams for non-admin
            if self.user_data["role"] != "role_cm_admin":
                sql_filter = f"WHERE co.organization_id = {self.user_data['org_id']}"
            else:
                sql_filter = None  # Show all teams for admin

        # Refresh table
        self._populate_resource_tableview("cat_team", sql_filter)

    def filter_users_table(self):
        """ Filter table by user name """

        # Get selected team id from combo
        team_id = tools_qt.get_combo_value(self.dlg_resources_man, "cmb_team")

        # Build sql filtering by the selected team
        if team_id and team_id != '' and team_id != -1:
            # When a team is selected, show users from that team AND users with no team
            # This allows assigning users without teams to the selected team
            sql_filter = f"WHERE (ct.team_id = {team_id} OR cu.team_id IS NULL)"
        else:
            # Show all users (including those without teams) for the current organization
            if self.user_data["role"] != "role_cm_admin":
                # For non-admin users, show users from their organization's teams or users without teams
                sql_filter = f"WHERE (ct.team_id = any(SELECT team_id FROM cm.cat_team WHERE organization_id = {self.user_data['org_id']}) OR cu.team_id IS NULL)"
            else:
                # For admin users, show all users
                sql_filter = None

        # Refresh table
        self._populate_resource_tableview("cat_user", sql_filter)

    def assign_team_to_user(self):
        """ Assign a team to selected user(s) """

        # Get selected user IDs
        selected_ids = self.get_selected_ids("cat_user")
        if not selected_ids:
            msg = tools_qt.tr("Please select at least one user to assign a team.", context_name="cm")
            tools_qgis.show_warning(msg)
            return

        # Get selected team from combo
        team_id = tools_qt.get_combo_value(self.dlg_resources_man, "cmb_team")
        if not team_id or team_id == -1:
            msg = tools_qt.tr("Please select a team to assign.", context_name="cm")
            tools_qgis.show_warning(msg)
            return

        # Get team name for confirmation
        team_name = tools_qt.get_combo_value(self.dlg_resources_man, "cmb_team", 1)  # Get the team name
        if not team_name or team_name == -1:
            msg = tools_qt.tr("Please select a valid team to assign.", context_name="cm")
            tools_qgis.show_warning(msg)
            return

        # Confirm the action
        user_count = len(selected_ids)
        msg = tools_qt.tr("Are you sure you want to assign team '{0}' to {1} selected user(s)?", context_name="cm")
        msg_params = (team_name, user_count)
        answer = tools_qt.show_question(msg, msg_params=msg_params, title=tools_qt.tr("Assign Team", context_name="cm"))
        if not answer:
            return

        # Update users with the selected team
        ids_str = ",".join(selected_ids)
        sql = f"UPDATE cm.cat_user SET team_id = {team_id} WHERE user_id IN ({ids_str})"

        try:
            tools_db.execute_sql(sql)
            msg = tools_qt.tr("Successfully assigned team '{0}' to {1} user(s).", context_name="cm")
            msg_params = (team_name, user_count)
            tools_qgis.show_info(msg, msg_params=msg_params)

            # Refresh the users table
            self.filter_users_table()
        except Exception as e:
            msg = tools_qt.tr("Error assigning team: {0}", context_name="cm")
            msg_params = (str(e),)
            tools_qgis.show_warning(msg, msg_params=msg_params)

    def change_team_for_user(self):
        """ Change team for selected user(s) """

        # Get selected user IDs
        selected_ids = self.get_selected_ids("cat_user")
        if not selected_ids:
            msg = tools_qt.tr("Seleccione al menos un usuario para cambiar de equipo.", context_name="cm")
            tools_qgis.show_warning(msg)
            return

        # Build team list from combo (already filtered by role/org)
        team_combo = self.dlg_resources_man.cmb_team
        teams = []
        for i in range(team_combo.count()):
            record = team_combo.itemData(i)
            if not record or len(record) < 2:
                continue
            team_id, team_name = record[0], record[1]
            if team_id in ("", None):
                continue
            teams.append((team_id, team_name))

        if not teams:
            msg = tools_qt.tr("No hay equipos disponibles para cambiar.", context_name="cm")
            tools_qgis.show_warning(msg)
            return

        title = tools_qt.tr("Cambiar Equipo", context_name="cm")
        label_text = tools_qt.tr("Seleccione nuevo equipo:", context_name="cm")

        dlg = QDialog(self.dlg_resources_man)
        dlg.setWindowTitle(title)
        layout = QVBoxLayout(dlg)
        layout.addWidget(QLabel(label_text))

        cmb_team = QComboBox(dlg)
        for team_id, team_name in teams:
            cmb_team.addItem(str(team_name), team_id)
        layout.addWidget(cmb_team)

        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel, dlg)
        buttons.accepted.connect(dlg.accept)
        buttons.rejected.connect(dlg.reject)
        layout.addWidget(buttons)

        if dlg.exec() != QDialog.DialogCode.Accepted:
            return

        team_id = cmb_team.currentData()
        team_name = cmb_team.currentText()

        # Confirm the action
        user_count = len(selected_ids)
        msg = tools_qt.tr("¿Está seguro de que desea cambiar al equipo '{0}' para {1} usuario(s) seleccionado(s)?", context_name="cm")
        msg_params = (team_name, user_count)
        answer = tools_qt.show_question(msg, msg_params=msg_params, title=title)
        if not answer:
            return

        # Update users with the selected team
        ids_str = ",".join(selected_ids)
        sql = f"UPDATE cm.cat_user SET team_id = {team_id} WHERE user_id IN ({ids_str})"

        try:
            tools_db.execute_sql(sql)
            msg = tools_qt.tr("Se cambió correctamente al equipo '{0}' para {1} usuario(s).", context_name="cm")
            msg_params = (team_name, user_count)
            tools_qgis.show_info(msg, msg_params=msg_params)

            # Refresh the users table
            self.filter_users_table()
        except Exception as e:
            msg = tools_qt.tr("Error al cambiar el equipo: {0}", context_name="cm")
            msg_params = (str(e),)
            tools_qgis.show_warning(msg, msg_params=msg_params)

    def remove_team_from_user(self):
        """ Remove team assignment from selected user(s) """

        # Get selected user IDs
        selected_ids = self.get_selected_ids("cat_user")
        if not selected_ids:
            msg = tools_qt.tr("Please select at least one user to remove team assignment.", context_name="cm")
            tools_qgis.show_warning(msg)
            return

        # Confirm the action
        user_count = len(selected_ids)
        msg = tools_qt.tr("Are you sure you want to remove team assignment from {0} selected user(s)?", context_name="cm")
        msg_params = (user_count,)
        answer = tools_qt.show_question(msg, msg_params=msg_params, title=tools_qt.tr("Remove Team Assignment", context_name="cm"))
        if not answer:
            return

        # Update users to remove team assignment
        ids_str = ",".join(selected_ids)
        sql = f"UPDATE cm.cat_user SET team_id = NULL WHERE user_id IN ({ids_str})"

        try:
            tools_db.execute_sql(sql)
            msg = tools_qt.tr("Successfully removed team assignment from {0} user(s).", context_name="cm")
            msg_params = (user_count,)
            tools_qgis.show_info(msg, msg_params=msg_params)

            # Refresh the users table
            self.filter_users_table()
        except Exception as e:
            msg = tools_qt.tr("Error removing team assignment: {0}", context_name="cm")
            msg_params = (str(e),)
            tools_qgis.show_warning(msg, msg_params=msg_params)

    def _populate_resource_tableview(self, table_name: str, sql_filter: Optional[str] = None):
        """Populate a QTableView with the results of a SQL query."""

        # Get QTableView
        table = self.dict_tables[table_name]["widget"]

        # Get query to populate
        query = self.dict_tables[table_name]["query"]

        # Check sql filter
        if sql_filter is not None:
            query += f" {sql_filter}"
        elif 'cmbParent' in self.dict_tables[table_name]:
            # Reset combo parent
            cmb_parent = self.dict_tables[table_name]["cmbParent"]
            tools_qt.set_combo_value(cmb_parent, '', 1)

        # Get data from query
        data = tools_db.get_rows(f"{query} ORDER BY {self.dict_tables[table_name]['idname']}:: INTEGER")

        # Check data
        if not data:
            table.setModel(QStandardItemModel())  # Clear view
            return

        # Get column headers
        columns = list(data[0].keys())

        # Create model for table
        model = QStandardItemModel(len(data), len(columns))
        model.setHorizontalHeaderLabels(columns)

        # Set table parameters
        table.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        table.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        table.setSortingEnabled(True)

        # Populate table view
        for row_idx, row in enumerate(data):
            for col_idx, col_name in enumerate(columns):
                if col_name in row:
                    value = row[col_name]
                    model.setItem(row_idx, col_idx, QStandardItem(value))

        # Apply model to table
        table.setModel(model)
        tools_gw.set_tablemodel_config(self.dlg_resources_man, table, table_name, schema_name="cm")

    def selected_row(self, tablename: str):
        """ Handle double click selected row """

        # Call open_create function depending of the table name
        if tablename == "cat_team":
            self.open_create_team(True)
        else:
            self.open_create_user(True)

    def toggle_active_records(self, tablename: str):
        """Toggle active state for selected rows in resources tables (teams/users)."""
        if tablename not in ("cat_team", "cat_user"):
            return
        table = self.dict_tables[tablename]["widget"]
        idname = self.dict_tables[tablename]["idname"]
        selected = table.selectionModel().selectedRows()
        if not selected:
            msg = tools_qt.tr("No records selected", context_name="cm")
            tools_qgis.show_warning(msg, dialog=self.dlg_resources_man)
            return
        # Determine column indexes
        model = table.model()
        active_col = tools_qt.get_col_index_by_col_name(table, 'active')
        if active_col is None or active_col == -1:
            # Fallback: try to find by header text
            for i in range(model.columnCount()):
                if str(model.headerData(i, Qt.Orientation.Horizontal)).lower() == 'active':
                    active_col = i
                    break
        id_col = 0  # id is first column in our population logic

        ids = []
        toggles = []
        for index in selected:
            row = index.row()
            row_id = model.index(row, id_col).data()
            current_active = model.index(row, active_col).data() if active_col is not None and active_col != -1 else None
            current_active_bool = tools_os.set_boolean(current_active) if current_active is not None else False
            ids.append(row_id)
            toggles.append(not current_active_bool)

        # Build SQL: update each selected id
        sql_statements = []
        for row_id, new_state in zip(ids, toggles):
            sql_statements.append(f"UPDATE cm.{tablename} SET active = {str(new_state).lower()} WHERE {idname}::text = '{row_id}'")
        if not sql_statements:
            return
        sql = ";".join(sql_statements)
        try:
            tools_db.execute_sql(sql, commit=True)
        except Exception as e:
            msg = tools_qt.tr("Error toggling state: {0}", context_name="cm")
            msg_params = (str(e),)
            tools_qgis.show_warning(msg, msg_params=msg_params, dialog=self.dlg_resources_man)
            return

        # Refresh table according to role and tablename
        if self.user_data["role"] == "role_cm_admin":
            self._populate_resource_tableview(tablename)
        else:
            if tablename == "cat_team":
                self.filter_teams_by_name()
            elif tablename == "cat_user":
                self.filter_users_table()

    def delete_registers(self, tablename: str):
        """ Delete selected registers from the table."""

        # Get idname
        idname = self.dict_tables[tablename]["idname"]

        # Get values to delete
        values = self.get_selected_ids(tablename)
        if not values:
            return

        # Build ids
        ids = ",".join(str(v) for v in values)

        # If deleting users, get their login names first to also drop the DB user
        login_names_to_drop = []
        if tablename == "cat_user":
            login_names_rows = tools_db.get_rows(f"SELECT username FROM cm.cat_user WHERE {idname} IN ({ids})", is_thread=True)
            if login_names_rows:
                login_names_to_drop = [row[0] for row in login_names_rows if row and row[0]]

        # Create message for the question
        msg = f'''{tools_qt.tr("Are you sure you want to delete these records:", context_name="cm")} ({ids})?'''
        if tablename == "cat_user" and login_names_to_drop:
            msg += f"\\n{tools_qt.tr('This will also delete the database user(s):', context_name='cm')} {', '.join(login_names_to_drop)}"
        title = tools_qt.tr("Delete records", context_name="cm")
        answer = tools_qt.show_question(msg, title=title)

        # Check answer
        if answer:
            # Delete records from the application table first
            if tools_db.execute_sql(f"DELETE FROM cm.{tablename} WHERE {idname} IN ({str(ids)})"):
                # If it was a user, also drop the database user
                if tablename == "cat_user":
                    for login_name in login_names_to_drop:
                        if not tools_db.execute_sql(f'DROP USER IF EXISTS "{login_name}"', commit=True):
                            msg = "Failed to drop database user '{0}'. It may need to be removed manually."
                            msg_params = (login_name,)
                            tools_qgis.show_warning(msg, msg_params=msg_params)
            else:
                msg = "Failed to delete records from {0}."
                msg_params = (tablename,)
                tools_qgis.show_warning(msg, msg_params=msg_params)

            # Chek user role
            if self.user_data["role"] == "role_cm_admin":
                # Reload table without filtering
                self._populate_resource_tableview(tablename)
            else:
                if tablename == "cat_team":
                    self.filter_teams_by_name()
                elif tablename == "cat_user":
                    # Create sql filter and populate table
                    sql_filter = f"WHERE ct.team_id = any(SELECT team_id FROM cm.cat_team WHERE organization_id = {self.user_data['org_id']})"
                    self._populate_resource_tableview(tablename, sql_filter)

    def open_create_team(self, is_update: Optional[bool] = False):
        """ Open dialog to create or update team """

        # Define the form type and create the body
        form_type = "team_create"
        body = tools_gw.create_body(form=f'"formName":"generic","formType":"{form_type}"')

        # Get dialog configuration from database
        json_result = tools_gw.execute_procedure('gw_fct_cm_get_dialog', body, schema_name="cm")

        if not json_result or 'body' not in json_result or 'data' not in json_result['body']:
            msg = tools_qt.tr("Failed to load team creation dialog configuration. Please check database configuration.", context_name="cm")
            tools_qgis.show_warning(msg)
            return

        # Create and open dialog
        self.dlg_create_team = TeamCreateUi(self)
        tools_gw.load_settings(self.dlg_create_team)

        try:
            tools_gw.manage_dlg_widgets(self, self.dlg_create_team, json_result)
        except Exception as e:
            msg = tools_qt.tr("Error creating dynamic dialog: {0}", context_name="cm")
            msg_params = (str(e),)
            tools_qgis.show_warning(msg, msg_params=msg_params)
            return

        if is_update:
            # Get selected id from table
            selected_ids = self.get_selected_ids("cat_team")
            if not selected_ids:
                return

            self.team_id = selected_ids[0]  # Get first selected id

            # Get object_id from selected row
            sql = f"SELECT teamname, descript, active, code, organization_id, role_id FROM cm.cat_team WHERE team_id = '{self.team_id}'"

            rows = tools_db.get_rows(sql)
            if rows:
                row = rows[0]
                tools_qt.set_widget_text(self.dlg_create_team, "tab_none_name", row[0])
                tools_qt.set_widget_text(self.dlg_create_team, "tab_none_descript", row[1])
                if len(row) > 2:
                    tools_qt.set_checked(self.dlg_create_team, "tab_none_active", row[2])
                    tools_qt.set_widget_text(self.dlg_create_team, "tab_none_code", row[3])
                    # Find and populate organization combo
                    cmb_org = self.dlg_create_team.findChild(QComboBox, "tab_none_org_id")
                    if cmb_org:
                        tools_qt.set_combo_value(cmb_org, row[4], 0, False)
                    # Find and populate role combo
                    cmb_role = self.dlg_create_team.findChild(QComboBox, "tab_none_role_id")
                    if cmb_role and len(row) > 5:
                        tools_qt.set_combo_value(cmb_role, row[5], 0, False)

        # Connect buttons to functions
        self.dlg_create_team.btn_accept.clicked.connect(partial(upsert_team, dialog=self.dlg_create_team, class_obj=self))
        self.dlg_create_team.btn_cancel.clicked.connect(partial(close, dialog=self.dlg_create_team))

        tools_gw.open_dialog(self.dlg_create_team, "create_team")

    def get_selected_ids(self, tablename: str) -> List[str]:
        """Get selected ids from QTableView."""

        qtable = self.dict_tables[tablename]["widget"]

        model = qtable.model()
        selection_model = qtable.selectionModel()
        selected_rows = selection_model.selectedRows()

        values = []
        for index in selected_rows:
            row = index.row()
            item = model.item(row, 0)  # Get the first column value (id)
            if item:
                values.append(item.text())

        if not values:
            msg = tools_qt.tr("No records selected", context_name="cm")
            tools_qgis.show_warning(msg)

        return values

    def _check_and_disable_campaign_combo(self):
        """Disable campaign combo if any relations exist."""
        if not self.lot_id:
            return

        features = ["arc", "node", "connec", "link"]
        if tools_gw.get_project_type() == 'ud':
            features.append("gully")

        has_relations = False
        for feature in features:
            db_table = f"om_campaign_lot_x_{feature}"
            sql = f"SELECT 1 FROM cm.{db_table} WHERE lot_id = {self.lot_id} LIMIT 1"
            if tools_db.get_row(sql):
                has_relations = True
                break

        if has_relations:
            campaign_combo = self.dlg_lot.findChild(QComboBox, "tab_data_campaign_id")
            if campaign_combo:
                campaign_combo.setEnabled(False)


def upsert_team(**kwargs: Any):
    """ Create or update team """

    dlg = kwargs["dialog"]
    this = kwargs["class_obj"]
    team_id = this.team_id

    # Get input values from visible fields
    name = tools_qt.get_text(dlg, "tab_none_name")
    descript = tools_qt.get_text(dlg, "tab_none_descript")
    code = tools_qt.get_text(dlg, "tab_none_code")
    active = tools_qt.get_widget_value(dlg, "tab_none_active")

    # Set default values automatically
    org_id = this.user_data['org_id']  # Current user's organization
    role_id = "role_cm_field"  # Default role

    # Set default values if empty
    if not descript or not descript.strip():
        descript = ""
    if not code or not code.strip():
        code = ""

    # Validate input values
    if not name or not name.strip() or not org_id:
        msg = tools_qt.tr("Missing required fields", context_name="cm")
        tools_qt.show_info_box(msg, tools_qt.tr("Info", context_name="cm"))
        return

    # Validate if name already exists
    sql_name_exists = f"SELECT * FROM cm.cat_team WHERE teamname = '{str(name)}'"

    if not team_id:
        sql = f"INSERT INTO cm.cat_team (teamname, descript, active, organization_id, code, role_id) \
                VALUES ('{name}', '{descript}', {active}, '{org_id}', '{code}', '{role_id}')"
    else:
        sql_name_exists += f" AND team_id != {team_id}"
        sql = f"UPDATE cm.cat_team SET teamname = '{name}', descript = '{descript}', active = {active}, \
                code = '{code}', role_id = '{role_id}', organization_id = '{org_id}' WHERE team_id = {team_id}"
        this.team_id = None

    rows = tools_db.get_rows(sql_name_exists)
    if rows:
        msg = tools_qt.tr("The team name already exists", context_name="cm")
        tools_qt.show_info_box(msg, tools_qt.tr("Info", context_name="cm"), parameter=str(name))
        return

    # Execute SQL
    status = tools_db.execute_sql(sql, commit=True)

    if not status:
        msg = tools_qt.tr("Error creating or updating team", context_name="cm")
        tools_qgis.show_warning(msg, parameter=str(name))
        return

    # Close dialog
    tools_gw.close_dialog(dlg)

    # Chek user role
    if this.user_data["role"] == "role_cm_admin":
        # Reload table without filtering
        this._populate_resource_tableview("cat_team")
    else:
        # Filter teams table by the user organization selected
        this.filter_teams_by_name()


def close(**kwargs: Any):
    """ Close dialog """
    tools_gw.close_dialog(kwargs["dialog"])
