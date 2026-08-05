"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial
from typing import Optional, List, Any, Dict, Union

from qgis.PyQt.QtCore import QDate, QModelIndex, QStringListModel, Qt
from qgis.PyQt.QtGui import QStandardItemModel, QStandardItem
from qgis.PyQt.QtWidgets import QLineEdit, QDateEdit, QCheckBox, QComboBox, QWidget, QLabel, QTextEdit, QCompleter, \
    QTableView, QToolBar, QActionGroup, QDialog
from .... import global_vars
from ....libs import tools_qt, tools_db, tools_qgis, lib_vars
from ...utils import tools_gw
from ...utils.selection_mode import GwSelectionMode
from ...ui.ui_manager import AddCampaignReviewUi, AddCampaignVisitUi, CampaignManagementUi, AddCampaignInventoryUi
from ...shared.selector import GwSelector
from ...utils.selection_widget import GwSelectionWidget


class Campaign:
    """Handles campaign creation, management, and database operations"""

    # Constants for campaign types
    CAMPAIGN_TYPE_REVIEW = 1
    CAMPAIGN_TYPE_VISIT = 2
    CAMPAIGN_TYPE_INVENTORY = 3

    # Valid feature types for campaigns
    VALID_FEATURE_TYPES = ['arc', 'node', 'connec', 'gully', 'link']

    # Maximum results for typeahead
    MAX_TYPEAHEAD_RESULTS = 100

    def __init__(self, icon_path: str, action_name: str, text: str, toolbar: QToolBar, action_group: QActionGroup):
        self.visitclass_combo: Optional[QComboBox] = None
        self.reviewclass_combo: Optional[QComboBox] = None
        self.iface = global_vars.iface
        self.campaign_date_format = 'yyyy-MM-dd'
        self.schema_parent = lib_vars.schema_name
        self.project_type = tools_gw.get_project_type()
        self.dialog: Optional[QDialog] = None
        self.campaign_type: Optional[int] = None
        self.campaign_id: Optional[int] = None
        self.canvas = global_vars.canvas
        self.campaign_saved = False
        self.is_new_campaign = True

    def create_campaign(self, campaign_id: Optional[int] = None, is_new: bool = True, dialog_type: str = "review"):
        """ Entry point for campaign creation or editing """

        self.load_campaign_dialog(campaign_id=campaign_id, mode=dialog_type)

    def campaign_manager(self):
        """ Opens the campaign management interface """

        self.manager_dialog = CampaignManagementUi(self)
        tools_gw.load_settings(self.manager_dialog)

        # Privilege guard: quietly exit if user has no CM access
        try:
            if not tools_db.check_schema('cm'):
                return
            has_usage = tools_db.get_row(
                "SELECT has_schema_privilege(current_user, 'cm', 'USAGE')",
                is_admin=True,
            )
            if not has_usage or not has_usage[0]:
                return
        except Exception:
            return
        self.load_campaigns_into_manager()

        self.manager_dialog.tbl_campaign.setEditTriggers(QTableView.EditTrigger.NoEditTriggers)
        self.manager_dialog.tbl_campaign.setSelectionBehavior(QTableView.SelectionBehavior.SelectRows)

        # Populate combo date type (planned dates first, then real dates)
        rows = [
            ['startdate', tools_qt.tr('Start date', 'cm')],
            ['enddate', tools_qt.tr('End date', 'cm')],
            ['real_startdate', tools_qt.tr('Real start date', 'cm')],
            ['real_enddate', tools_qt.tr('Real end date', 'cm')]
        ]
        tools_qt.fill_combo_values(self.manager_dialog.campaign_cmb_date_filter_type, rows, 1, sort_combo=False)
        # Default to planned Start date
        try:
            self.manager_dialog.campaign_cmb_date_filter_type.setCurrentIndex(0)
        except Exception:
            pass

        # Fill combo values for campaign status (based on sys_typevalue table)
        sql = "SELECT id, idval FROM cm.sys_typevalue WHERE typevalue = 'campaign_status' ORDER BY id"
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.manager_dialog.campaign_cmb_state, rows, index_to_show=1, add_empty=True)

        # Set filter events
        self.manager_dialog.btn_cancel.clicked.connect(self.manager_dialog.reject)
        self.manager_dialog.campaign_cmb_state.currentIndexChanged.connect(self.filter_campaigns)
        self.manager_dialog.campaign_cmb_state.currentIndexChanged.connect(self.filter_campaigns)
        self.manager_dialog.date_event_from.dateChanged.connect(self.filter_campaigns)
        self.manager_dialog.date_event_to.dateChanged.connect(self.filter_campaigns)
        self.manager_dialog.campaign_cmb_date_filter_type.currentIndexChanged.connect(self.filter_campaigns)
        self.manager_dialog.campaign_chk_show_nulls.stateChanged.connect(self.filter_campaigns)
        self.manager_dialog.campaign_cmb_date_filter_type.currentIndexChanged.connect(self.manage_date_filter)
        self.manager_dialog.tbl_campaign.doubleClicked.connect(self.open_campaign)
        self.manager_dialog.campaign_btn_delete.clicked.connect(self.delete_selected_campaign)
        self.manager_dialog.campaign_btn_open.clicked.connect(self.open_campaign)
        self.manager_dialog.campaign_btn_child.clicked.connect(self.create_child_campaign)

        self.manage_date_filter()
        tools_gw.open_dialog(self.manager_dialog, dlg_name="campaign_management")

    def open_campaign_selector(self):
        """ Open the campaign-specific selector when the button is clicked """
        selector_type = "selector_campaign"

        # Check user role
        cm_roles = tools_gw.get_cm_user_role()
        show_lot = not (cm_roles and 'role_cm_edit' in list(cm_roles))

        # Show form in docker
        tools_gw.init_docker('qgis_form_docker')
        selector = GwSelector()
        selector.open_selector(selector_type, show_lot_tab=show_lot)

    def load_campaign_dialog(self, campaign_id: Optional[int] = None, mode: str = "review", parent: Optional[QWidget] = None):
        """
        Load and initialize the campaign dialog.

        - Creates and sets up the form dynamically based on response from `gw_fct_cm_getcampaign`.
        - Initializes rubberbands and layer lists.
        - Loads campaign relations if editing an existing campaign.
        - Sets icons, connections, tab visibility (e.g. hides gully tab for 'ws' projects), and widget behaviors.
        - Applies reviewclass logic and sets up snapping/highlight connections for relation tabs.

        :param campaign_id: ID of the campaign to load. If None, creates a new campaign.
        :param mode: Type of campaign dialog to load. Options: 'review', 'visit'.
        :param parent: The parent widget for the dialog.
        """
        self.campaign_id = campaign_id
        self._relations_loaded = False

        # In the edit_typevalue or another cm.edit_typevalue
        # INSERT INTO edit_typevalue (typevalue, id, idval, descript, addparam) VALUES('cm_campaing_type', '1', 'Review', NULL, NULL);
        # INSERT INTO edit_typevalue (typevalue, id, idval, descript, addparam) VALUES('cm_campaing_type', '2', 'Visit', NULL, NULL);
        # same with status and status in x_feature

        # Setting lists
        self.rubber_band = tools_gw.create_rubberband(self.canvas)
        self.ids = []
        self.rel_list_ids = {'arc': [], 'node': [], 'connec': [], 'gully': [], 'link': []}
        self.rel_layers = {'arc': [], 'node': [], 'connec': [], 'gully': [], 'link': []}
        self.rel_layers['arc'] = tools_gw.get_layers_from_feature_type('arc')
        self.rel_layers['node'] = tools_gw.get_layers_from_feature_type('node')
        self.rel_layers['connec'] = tools_gw.get_layers_from_feature_type('connec')
        if self.project_type == 'ud':
            self.rel_layers['gully'] = tools_gw.get_layers_from_feature_type('gully')
        self.rel_layers['link'] = tools_gw.get_layers_from_feature_type('link')
        self.excluded_layers = [
            "ve_arc", "ve_node", "ve_connec",
            "ve_gully", "ve_link"
        ]

        modes = {"review": 1, "visit": 2, "inventory": 3}
        self.campaign_type = modes.get(mode, 1)

        body = {
            "feature": {
                "tableName": "om_campaign",
                "idName": "campaign_id",
                "campaign_mode": mode
            }
        }
        if campaign_id:
            body["feature"]["id"] = campaign_id
        p_data = tools_gw.create_body(body=body)
        self.is_new_campaign = campaign_id is None
        self.campaign_saved = False

        response = tools_gw.execute_procedure("gw_fct_cm_getcampaign", p_data, schema_name="cm")
        if not response or response.get("status") != "Accepted":
            msg = tools_qt.tr("Failed to load campaign form.", context_name="cm")
            tools_qgis.show_warning(msg)
            return

        form_fields = response["body"]["data"].get("fields", [])
        self.fields_form = form_fields

        dialog_map = {
            "review": AddCampaignReviewUi,
            "visit": AddCampaignVisitUi,
            "inventory": AddCampaignInventoryUi
        }
        dialog_class = dialog_map.get(mode)
        if not dialog_class:
            msg = tools_qt.tr("Invalid campaign mode", context_name="cm")
            tools_qgis.show_warning(f"{msg}: {mode}")
            return
        self.dialog = dialog_class(self)
        if parent:
            self.dialog.setParent(parent)

        # Pre-calculate saved values before any widgets are manipulated
        saved_dependent_values = {}
        for field in form_fields:
            if field.get("columnname") in ["expl_id", "sector_id"]:
                value = field.get("selectedId", field.get("value"))
                if value is not None:
                    saved_dependent_values[field["columnname"]] = value

        # When open from campaign manager
        if campaign_id:
            widget = self.get_widget_by_columnname(self.dialog, "campaign_id")
            if widget:
                widget.setText(str(campaign_id))
                widget.setProperty("columnname", "campaign_id")
                widget.setObjectName("campaign_id")

        tools_gw.load_settings(self.dialog)

        # Hide gully tab if project_type is 'ws'
        if self.project_type == 'ws':
            index = self.dialog.tab_feature.indexOf(self.dialog.tab_gully)
            if index != -1:
                self.dialog.tab_feature.removeTab(index)

        # Build widgets dynamically
        for field in form_fields:
            widget = self.create_widget_from_field(field, response)
            if not widget:
                continue

            # Block signals on the controlling widget to prevent premature updates
            if field.get("columnname") == "organization_id":
                widget.blockSignals(True)

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
            tools_gw.add_widget(self.dialog, field, label, widget)

        # Manually trigger the update now that all widgets are created, then unblock signals
        organization_widget = self.get_widget_by_columnname(self.dialog, "organization_id")
        if organization_widget:
            update_expl_sector_combos(
                dialog=self.dialog,
                widget=organization_widget,
                saved_values=saved_dependent_values
            )
            organization_widget.blockSignals(False)

        expl_widget = self.get_widget_by_columnname(self.dialog, "expl_id")
        if expl_widget:
            expl_widget.currentIndexChanged.connect(
                lambda: update_sector_combo(self.dialog)
            )

        self._apply_child_campaign_field_locks()

        if campaign_id:
            self._check_and_disable_class_combos()

        tools_gw.add_icon(self.dialog.btn_insert, '111')
        tools_gw.add_icon(self.dialog.btn_delete, '112')

        self.dialog.rejected.connect(self._on_dialog_rejected)

        self.dialog.btn_cancel.clicked.connect(self.dialog.reject)
        self.dialog.btn_accept.clicked.connect(self.save_campaign)
        self.dialog.tab_widget.currentChanged.connect(self._on_tab_change)

        # Enable tab relations if name has value
        name_widget = self.get_widget_by_columnname(self.dialog, "name")
        if name_widget:
            name_widget.textChanged.connect(self._check_enable_tab_relations)

        # Refresh the manager table when campaign dialog closes (if it was opened from manager)
        if isinstance(self.dialog.parent(), CampaignManagementUi):
            self.dialog.finished.connect(self.filter_campaigns)

        # Code logic to deal with the review/visit combo change to load tabs in relations
        self.reviewclass_combo = self.get_widget_by_columnname(self.dialog, "reviewclass_id")
        self.visitclass_combo = self.get_widget_by_columnname(self.dialog, "visitclass_id")
        for combo in (self.reviewclass_combo, self.visitclass_combo):
            if isinstance(combo, QComboBox):
                # Connect to handler passing the combo itself
                combo.currentIndexChanged.connect(partial(self._on_class_changed, combo))
                combo.currentIndexChanged.connect(partial(self._update_feature_completer, self.dialog))
                # Init tabs without persisting (avoid accidental setcampaign on open)
                self._on_class_changed(combo, save=False)

        self.setup_tab_relations()
        self._check_enable_tab_relations()

        # For inventory campaigns, enable all tabs from the start
        if self.campaign_type == 3:
            self._manage_tabs_enabled([])  # Pass empty list, the method will handle inventory case

        self._update_feature_completer(self.dialog)

        for table_name in [
            "tbl_campaign_x_arc",
            "tbl_campaign_x_node",
            "tbl_campaign_x_connec",
            "tbl_campaign_x_gully",
            "tbl_campaign_x_link",
        ]:
            view = getattr(self.dialog, table_name, None)
            if view:
                tools_qt.set_tableview_config(view)

        tools_gw.open_dialog(self.dialog, dlg_name="add_campaign")

        # Wire selectionChanged
        try:
            if hasattr(self.dialog, 'tbl_campaign_x_arc') and self.dialog.tbl_campaign_x_arc.selectionModel():
                self.dialog.tbl_campaign_x_arc.selectionModel().selectionChanged.connect(partial(
                    tools_qgis.highlight_features_by_id, self.dialog.tbl_campaign_x_arc, "ve_arc", "arc_id", self.rubber_band, 5))
            if hasattr(self.dialog, 'tbl_campaign_x_node') and self.dialog.tbl_campaign_x_node.selectionModel():
                self.dialog.tbl_campaign_x_node.selectionModel().selectionChanged.connect(partial(
                    tools_qgis.highlight_features_by_id, self.dialog.tbl_campaign_x_node, "ve_node", "node_id", self.rubber_band, 10))
            if hasattr(self.dialog, 'tbl_campaign_x_connec') and self.dialog.tbl_campaign_x_connec.selectionModel():
                self.dialog.tbl_campaign_x_connec.selectionModel().selectionChanged.connect(partial(
                    tools_qgis.highlight_features_by_id, self.dialog.tbl_campaign_x_connec, "ve_connec", "connec_id", self.rubber_band, 10))
            if hasattr(self.dialog, 'tbl_campaign_x_link') and self.dialog.tbl_campaign_x_link.selectionModel():
                self.dialog.tbl_campaign_x_link.selectionModel().selectionChanged.connect(partial(
                    tools_qgis.highlight_features_by_id, self.dialog.tbl_campaign_x_link, "ve_link", "link_id", self.rubber_band, 10))
            if self.project_type == 'ud' and hasattr(self.dialog, 'tbl_campaign_x_gully') and self.dialog.tbl_campaign_x_gully.selectionModel():
                self.dialog.tbl_campaign_x_gully.selectionModel().selectionChanged.connect(partial(
                    tools_qgis.highlight_features_by_id, self.dialog.tbl_campaign_x_gully, "ve_gully", "gully_id", self.rubber_band, 10))
        except Exception:
            pass

    def _on_dialog_rejected(self):
        """Clean up resources when the dialog is rejected."""
        self._cleanup_map_selection()

    def _load_campaign_relations(self, campaign_id: int):
        """
        Load related elements into campaign relation tabs for the given ID.
        Uses the generic loader to bind a QSqlTableModel per feature table,
        so table selections map directly to DB field names for actions like delete.
        """
        features = ["arc", "node", "connec", "link"]
        if self.project_type == 'ud':
            features.append("gully")

        for feature in features:
            try:
                tools_gw.load_tableview_campaign(self.dialog, feature, campaign_id, self.rel_layers)
            except Exception:
                # Fallback to old path if needed
                table_prefix = "om_campaign_inventory_x_" if self.campaign_type == 3 else "om_campaign_x_"
                table_widget_name = f"tbl_campaign_x_{feature}"
                view = getattr(self.dialog, table_widget_name, None)
                if view:
                    db_table = f"cm.{table_prefix}{feature}"
                    sql = (
                        f"SELECT * FROM {db_table} "
                        f"WHERE campaign_id = {campaign_id} "
                        f"ORDER BY id"
                    )
                    self.populate_tableview(view, sql)

        self._relations_loaded = True

    def create_widget_from_field(self, field: Dict[str, Any], response: Dict[str, Any]) -> Optional[QWidget]:
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
            kwargs = {
                "field": field, "dialog": self.dialog,
                "complet_result": response, "class_info": self
            }
            return tools_gw.add_combo(**kwargs)

        widget_map = {
            "text": create_line_edit,
            "textarea": create_text_area,
            "datetime": create_datetime_edit,
            "check": create_check_box,
            "combo": create_combo_box
        }

        creation_func = widget_map.get(wtype)
        return creation_func() if creation_func else None

    def set_widget_value(self, widget: QWidget, value: Any):
        """Sets the widget value from JSON"""
        if value is None:
            return

        if isinstance(widget, QLineEdit):
            widget.setText(str(value))
        elif isinstance(widget, QTextEdit):
            widget.setPlainText(str(value))
        elif isinstance(widget, QDateEdit):
            if value:
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

    def _on_tab_change(self, index: int):
        """Handle tab change events in the campaign dialog."""
        tab = self.dialog.tab_widget.widget(index)
        if not tab or tab.objectName() != "tab_relations":
            return

        # New campaigns must be persisted before relating features
        if self.is_new_campaign and not self.campaign_saved:
            if self.save_campaign(from_tab_change=True) is False:
                return

        # Lazy-load relation tables on first visit
        if self.campaign_id and not self._relations_loaded:
            self._load_campaign_relations(self.campaign_id)

    def save_campaign(self, from_tab_change: bool = False) -> Optional[bool]:
        """Save campaign data to the database. Updates ID and resets map on success."""

        fields_dict = self.extract_campaign_fields(self.dialog, as_dict=True)

        # For inventory campaigns, inventoryclass_id is special.
        # It should not be saved in om_campaign table but passed as an extra param.
        inventory_class_id = None
        if self.campaign_type == 3 and 'inventoryclass_id' in fields_dict:
            inventory_class_id = fields_dict.pop('inventoryclass_id')

        fields_str = ", ".join([f'"{k}":{v}' for k, v in fields_dict.items()])
        extras = f'"fields":{{{fields_str}}}, "campaign_type":{self.campaign_type}'
        if inventory_class_id:
            extras += f', "inventoryclass_id":{inventory_class_id}'

        body = tools_gw.create_body(feature='"tableName":"om_campaign", "idName":"campaign_id"', extras=extras)

        # Check mandatory fields
        list_mandatory = []
        for field in self.fields_form:
            if field.get('hidden', False):
                continue

            if field.get('ismandatory', False):
                widget = self.dialog.findChild(QWidget, field.get('widgetname'))
                if widget:
                    widget.setStyleSheet(None)  # Reset style first
                    value = tools_qt.get_text(self.dialog, widget)
                    if value in ('null', None, ''):
                        widget.setStyleSheet("border: 1px solid red")
                        list_mandatory.append(field['widgetname'])

        if list_mandatory:
            msg = tools_qt.tr("Some mandatory values are missing. Please check the widgets marked in red.", context_name="cm")
            tools_qgis.show_warning(msg, dialog=self.dialog)
            return False

        result = tools_gw.execute_procedure("gw_fct_cm_setcampaign", body, schema_name="cm")

        if result.get("status") == "Accepted":
            msg = tools_qt.tr("Campaign saved successfully.", context_name="cm")
            tools_qgis.show_info(msg, dialog=self.dialog)
            self.campaign_saved = True
            self.is_new_campaign = False
            self._cleanup_map_selection()

            # Ensure selector_campaign docker reflects the new/updated campaign immediately
            try:
                tools_gw.refresh_selectors(is_cm=True)
            except Exception:
                pass

            # Update campaign ID in the dialog
            campaign_id = result.get("body", {}).get("campaign_id")
            self.campaign_id = campaign_id
            if campaign_id:
                id_field = self.dialog.findChild(QLineEdit, "campaign_id")
                if id_field:
                    id_field.setText(str(campaign_id))

            # Reload manager table only if from manager
            if hasattr(self, 'manager_dialog') and self.manager_dialog:
                self.filter_campaigns()

            if not from_tab_change:
                self.dialog.accept()

        else:
            msg = tools_qt.tr("Failed to save campaign", context_name="cm")
            tools_qgis.show_warning(result.get("message", msg))

    def _cleanup_map_selection(self):
        """Clean up map selections and disconnect signals."""
        tools_qgis.disconnect_signal_selection_changed()
        tools_gw.reset_rubberband(self.rubber_band)
        tools_gw.remove_selection(True, layers=self.rel_layers)
        tools_qgis.force_refresh_map_canvas()

    def _refresh_relations_table(self):
        """Callback to refresh relations and apply table config if first insert."""
        if self.campaign_id:
            # Check if this was the first insert by checking if table was empty before
            current_tab = self.dialog.tab_feature.currentWidget()
            if not current_tab:
                return

            feature_type = current_tab.objectName().replace('tab_', '')
            table_widget_name = f"tbl_campaign_x_{feature_type}"
            table_view = getattr(self.dialog, table_widget_name, None)

            if table_view and table_view.model():
                # If table has exactly 1 row now, it means it was the first insert
                if table_view.model().rowCount() == 1:
                    self._apply_table_config_for_feature(table_view, feature_type)
                return

            # If we can't determine or table is empty, reload relations
            self._load_campaign_relations(self.campaign_id)

    def _apply_table_config_for_feature(self, table_view, feature_type):
        """Apply table configuration for a specific feature type."""
        table_name = f"om_campaign_x_{feature_type}"
        dialog_ref = self.manager_dialog if hasattr(self, 'manager_dialog') else self.dialog
        tools_gw.set_tablemodel_config(dialog_ref, table_view, table_name, schema_name="cm")

    def _get_checkbox_value_as_string(self, dialog: QDialog, widget: QCheckBox) -> str:
        """Helper to get QCheckBox value as a lowercase string ('true'/'false')."""
        return str(tools_qt.is_checked(dialog, widget)).lower()

    def extract_campaign_fields(self, dialog: QDialog, as_dict: bool = False) -> Union[Dict, str]:
        """Build a JSON string or dictionary of field values from the campaign dialog"""
        fields = {}

        # Mappings from widget types to their value getters and properties
        widget_configs = {
            QLineEdit: {'getter': tools_qt.get_text, 'quote': True},
            QTextEdit: {'getter': tools_qt.get_text, 'quote': True},
            QDateEdit: {'getter': tools_qt.get_calendar_date, 'quote': True},
            QComboBox: {'getter': tools_qt.get_combo_value, 'quote': True, 'invalid': ['null', '', '-1']},
            QCheckBox: {'getter': self._get_checkbox_value_as_string, 'quote': False, 'invalid': ['null', '""']}
        }

        for widget_class, config in widget_configs.items():
            getter = config['getter']
            for widget in dialog.findChildren(widget_class):
                colname = widget.property('columnname')
                if not colname:
                    continue

                value = getter(dialog, widget)

                if 'invalid' in config and value in config['invalid']:
                    continue

                if value not in ('null', None, ''):
                    # For combo boxes, the value might be a list; we take the first element (the ID)
                    if isinstance(value, (list, tuple)) and value:
                        value = value[0]

                    fields[colname] = f'"{value}"' if config['quote'] else str(value)

        if as_dict:
            return fields

        return ", ".join([f'"{k}":{v}' for k, v in fields.items()])

    def setup_tab_relations(self):
        """Setup the relations tab with event handlers and selection widgets."""
        # self.dialog.tab_relations.setCurrentIndex(0)
        self.rel_feature_type = tools_gw.get_signal_change_tab(self.dialog)
        self.rubber_band = tools_gw.create_rubberband(self.canvas)
        table_object = "campaign_inventory" if self.campaign_type == 3 else "campaign"
        tools_gw.get_signal_change_tab(self.dialog)

        self.dialog.tab_feature.currentChanged.connect(self._on_tab_feature_changed)

        self.dialog.tab_feature.currentChanged.connect(
            partial(self._update_feature_completer, self.dialog)
        )

        self.dialog.btn_insert.clicked.connect(
            partial(tools_gw.insert_feature, self, self.dialog, table_object, GwSelectionMode.CAMPAIGN, True, None, None, self._refresh_relations_table)
        )
        self.dialog.btn_insert.clicked.connect(
            partial(self._update_feature_completer, self.dialog)
        )
        self.dialog.btn_insert.clicked.connect(self._check_and_disable_class_combos)

        self.dialog.btn_delete.clicked.connect(
            partial(tools_gw.delete_records, self, self.dialog, table_object, GwSelectionMode.CAMPAIGN, None, None, None, self._refresh_relations_table)
        )
        self.dialog.btn_delete.clicked.connect(
            partial(self._update_feature_completer, self.dialog)
        )
        self.dialog.btn_delete.clicked.connect(self._check_and_disable_class_combos)

        # Create menu for btn_snapping
        self_variables = {"selection_mode": GwSelectionMode.CAMPAIGN, "invert_selection": True, "zoom_to_selection": True, "selection_on_top": True}
        general_variables = {"class_object": self, "dialog": self.dialog, "table_object": "campaign"}
        used_tools = ["rectangle", "polygon", "freehand", "circle", "point"]
        menu_variables = {"used_tools": used_tools, "callback_later": self._refresh_relations_table}
        highlight_variables = {"callback_values": self.callback_values}
        expression_selection = {"callback_later": self._update_feature_completer, "callback_later_values": self.callback_values_later}
        selection_widget = GwSelectionWidget(self_variables, general_variables, menu_variables, highlight_variables, expression_selection=expression_selection)
        self.dialog.lyt_selection.addWidget(selection_widget, 0)

    def callback_values(self):
        """Return callback values for selection widget operations."""
        return self, self.dialog, "campaign"

    def callback_values_later(self):
        """Return callback values for later execution in selection operations."""
        return {"dlg": self.dialog}

    def _check_and_disable_class_combos(self):
        """Disable review/visit class combos if any relations exist."""
        if not self.campaign_id:
            return

        table_prefix = "om_campaign_inventory_x_" if self.campaign_type == 3 else "om_campaign_x_"
        features = ["arc", "node", "connec", "link"]
        if self.project_type == 'ud':
            features.append("gully")

        has_relations = False
        for feature in features:
            db_table = f"{table_prefix}{feature}"
            sql = f"SELECT 1 FROM cm.{db_table} WHERE campaign_id = {self.campaign_id} LIMIT 1"
            if tools_db.get_row(sql):
                has_relations = True
                break

        if has_relations:
            if self.reviewclass_combo:
                self.reviewclass_combo.setEnabled(False)
            if self.visitclass_combo:
                self.visitclass_combo.setEnabled(False)

    def _on_tab_feature_changed(self):
        """Handle feature tab change events."""
        self.rel_feature_type = tools_gw.get_signal_change_tab(self.dialog, self.excluded_layers)

    def get_widget_by_columnname(self, dialog: QDialog, columnname: str) -> Optional[QWidget]:
        """Find a widget in the dialog by its columnname property."""
        for widget in dialog.findChildren(QWidget):
            if widget.property("columnname") == columnname:
                return widget
        return None

    def _check_enable_tab_relations(self):
        """Enable or disable the relations tab based on campaign name."""
        name_widget = self.get_widget_by_columnname(self.dialog, "name")
        if not name_widget:
            return

        enable = bool(name_widget.text().strip())
        self.dialog.tab_widget.setTabEnabled(self.dialog.tab_widget.indexOf(self.dialog.tab_relations), enable)

    def _update_feature_completer(self, dlg: QDialog):
        """Update the feature completer based on current tab and campaign restrictions."""
        tab_widget = dlg.tab_feature.currentWidget()
        if not tab_widget:
            return

        feature = tab_widget.objectName().replace('tab_', '')
        if not feature:
            return

        # Build allowed subtype list for CURRENT feature (can be empty = no restriction)
        allowed_types = self._get_allowed_types_for_feature(feature)

        # Initialize completer infrastructure if needed
        self._ensure_completer_infrastructure(dlg)

        # Rewire textEdited to our typeahead (no timers; reuse completer/model like set_typeahead)
        self._connect_typeahead_handler(dlg, feature, allowed_types)

    def _get_allowed_types_for_feature(self, feature: str) -> List[str]:
        """Get allowed feature types based on campaign type and selected class."""
        allowed_types = []
        if self.campaign_type == 1:
            reviewclass_id = tools_qt.get_combo_value(self.dialog, self.reviewclass_combo)
            if reviewclass_id:
                allowed_types = self.get_allowed_feature_subtypes(feature, reviewclass_id)
        elif self.campaign_type == 2:
            visitclass_id = tools_qt.get_combo_value(self.dialog, self.visitclass_combo)
            if visitclass_id:
                allowed_types = self.get_allowed_feature_subtypes_visit(visitclass_id)
        # inventory: allowed_types stays []
        return allowed_types

    def _ensure_completer_infrastructure(self, dlg: QDialog):
        """Ensure completer model and completer are properly initialized."""
        if not hasattr(self, '_feature_id_model') or self._feature_id_model is None:
            self._feature_id_model = QStringListModel(dlg)

        if not hasattr(self, '_feature_id_completer') or self._feature_id_completer is None:
            self._feature_id_completer = QCompleter(self._feature_id_model, dlg)
            self._feature_id_completer.setCaseSensitivity(Qt.CaseSensitivity.CaseInsensitive)
            self._feature_id_completer.setCompletionMode(QCompleter.CompletionMode.PopupCompletion)
            dlg.feature_id.setCompleter(self._feature_id_completer)

    def _connect_typeahead_handler(self, dlg: QDialog, feature: str, allowed_types: List[str]):
        """Connect the typeahead handler to the feature ID line edit."""
        try:
            dlg.feature_id.textEdited.disconnect()
        except Exception:
            pass
        dlg.feature_id.textEdited.connect(partial(self._feature_id_typeahead, dlg, feature, allowed_types))

    def _feature_id_typeahead(self, dlg: QDialog, feature: str, allowed_types: List[str], text: str = ''):
        """Query server on each keystroke and feed the completer with up to 100 items."""
        value_list = []
        if text and len(text) >= 1:
            # Get all allowed feature IDs using the same logic as map selection
            allowed_feature_ids = self.get_allowed_features_for_campaign(feature)

            if allowed_feature_ids:
                # Filter by text input from the allowed IDs with case-insensitive matching
                safe = str(text).replace("'", "''")
                matching_ids = [fid for fid in allowed_feature_ids if str(fid).lower().startswith(safe.lower())]
                value_list = matching_ids[:self.MAX_TYPEAHEAD_RESULTS]  # Limit to max results
            else:
                # If no restrictions, use the original logic with improved SQL
                value_list = self._get_unrestricted_features(feature, text)

        # Force our completer to be the one that works
        if hasattr(self, '_feature_id_model') and self._feature_id_model is not None:
            self._update_completer_model(dlg, value_list, text)

    def _get_unrestricted_features(self, feature: str, text: str) -> List[str]:
        """Get features when no restrictions are applied (inventory campaigns or 'ALL' review class)."""
        id_column = f"{feature}_id"
        safe = str(text).replace("'", "''")
        base_sql = f"SELECT p.{id_column}::text AS val FROM {self.schema_parent}.{feature} p"
        where_sql = f" WHERE p.{id_column}::text ILIKE '{safe}%'"
        sql = base_sql + where_sql + f" ORDER BY p.{id_column} LIMIT {self.MAX_TYPEAHEAD_RESULTS}"
        rows = tools_db.get_rows(sql)
        return [r.get('val') for r in (rows or []) if r.get('val')]

    def _update_completer_model(self, dlg: QDialog, value_list: List[str], text: str):
        """Update the completer model with filtered data and trigger completion."""
        # Clear any existing completer and force ours
        dlg.feature_id.setCompleter(None)

        # Set our model with the filtered data
        self._feature_id_model.setStringList(value_list)

        # Reattach our completer
        dlg.feature_id.setCompleter(self._feature_id_completer)

        # Only show popup when there is user text and some results
        if text and value_list:
            try:
                dlg.feature_id.completer().complete()
            except Exception:
                pass

    def get_allowed_features_for_campaign(self, feature: str) -> Optional[List[Any]]:
        """Return list of allowed feature IDs for current campaign and feature tab.

        If campaign type is inventory (3), returns None to indicate no restriction.
        """
        if not feature or feature not in self.VALID_FEATURE_TYPES:
            return None

        id_column = f"{feature}_id"

        # Inventory: no restriction
        if self.campaign_type == self.CAMPAIGN_TYPE_INVENTORY:
            return None

        allowed_types: List[str] = []
        if self.campaign_type == self.CAMPAIGN_TYPE_REVIEW:
            reviewclass_id = tools_qt.get_combo_value(self.dialog, self.reviewclass_combo)
            if not reviewclass_id:
                return None
            allowed_types = self.get_allowed_feature_subtypes(feature, reviewclass_id)
        elif self.campaign_type == self.CAMPAIGN_TYPE_VISIT:
            visitclass_id = tools_qt.get_combo_value(self.dialog, self.visitclass_combo)
            if not visitclass_id:
                return None
            allowed_types = self.get_allowed_feature_subtypes_visit(visitclass_id)

        if not allowed_types:
            return None

        try:
            allowed_types_str = ", ".join([f"'{t}'" for t in allowed_types])
            sql = f"""
                SELECT p.{id_column}::text AS {id_column}
                FROM {self.schema_parent}.{feature} p
                JOIN {self.schema_parent}.cat_{feature} c
                  ON p.{feature}cat_id = c.id
                WHERE c.{feature}_type IN ({allowed_types_str})
            """
            rows = tools_db.get_rows(sql)
            result = [row[id_column] for row in (rows or []) if row.get(id_column)]
            return result
        except Exception:
            # Return None if there's any database error
            return None

    def _on_class_changed(self, sender: Optional[QComboBox] = None, *args, save: bool = True):
        """Apply review/visit class tab rules. Persist only on real user changes (save=True)."""
        # If sender is not passed, try get it from signal
        if sender is None:
            sender = self.dialog.sender()

        if not isinstance(sender, QComboBox):
            return

        combo_data = sender.currentData()
        if not combo_data:
            return

        selected_id = combo_data[0] if isinstance(combo_data, (list, tuple)) else combo_data
        if not str(selected_id).isdigit():
            return

        # Determine which table to query
        if sender == self.reviewclass_combo:
            feature_types = self.get_allowed_feature_types_for_reviewclass(selected_id)
            # If the selected class is the 'ALL' class, switch to the first tab.
            if self._is_reviewclass_for_all(selected_id):
                self.dialog.tab_feature.setCurrentIndex(0)

        elif sender == self.visitclass_combo:
            feature_types = self.get_allowed_feature_types_from_visitclass("om_visitclass", selected_id)
        else:
            return

        if save and self.campaign_id:
            self.save_campaign(True)  # from_tab_change=True => silent (doesn't close dialog)

        self._manage_tabs_enabled(feature_types)

    def get_allowed_feature_subtypes_visit(self, visitclass_id: int) -> List[str]:
        """
        Returns a list of feature_type strings from cm.om_visitclass
        for the given visitclass_id.
        """
        # guard: ensure we have a valid integer
        try:
            vc_id = int(visitclass_id)
        except (ValueError, TypeError):
            return []

        sql = f"""
            SELECT feature_type
              FROM cm.om_visitclass
             WHERE id = {vc_id}
        """
        rows = tools_db.get_rows(sql)
        # pull out non-null values
        if rows:
            return [r["feature_type"] for r in rows if r.get("feature_type")]
        return []

    def get_allowed_feature_subtypes(self, feature: str, reviewclass_id: int) -> List[str]:
        """
        Get allowed subtypes (e.g., TANK, PR_BREAK_VALVE) based on reviewclass_id.
        If the class is linked to 'ALL', it returns an empty list to enable all selections.
        """
        # First, check if this review class is linked to an 'ALL' object.
        if self._is_reviewclass_for_all(reviewclass_id):
            return []

        # For a specific review class, get all linked subtypes.
        # This list is used to filter the feature selector.
        sql = f"""
            SELECT DISTINCT r.object_id
            FROM cm.om_reviewclass_x_object r
            JOIN {self.schema_parent}.cat_feature f ON r.object_id = f.id
            WHERE r.reviewclass_id = {reviewclass_id}
        """
        rows = tools_db.get_rows(sql)
        result = [r["object_id"] for r in rows or []]
        return result

    def get_allowed_feature_types_for_reviewclass(self, reviewclass_id: int) -> List[str]:
        """
        Query om_reviewclass_x_object to get allowed feature types.
        Has special handling for a class linked to an 'ALL' object_id.
        """
        # First, check if the linked object is 'ALL'.
        if self._is_reviewclass_for_all(reviewclass_id):
            # If 'ALL' is found, get all distinct feature types from the catalog.
            all_features_sql = f"SELECT DISTINCT feature_type FROM {self.schema_parent}.cat_feature WHERE feature_type IS NOT NULL"
            rows = tools_db.get_rows(all_features_sql)
            return [r['feature_type'] for r in rows or []]

        # For a specific (non-ALL) review class, get only the linked feature types.
        sql = f"""
            SELECT DISTINCT f.feature_type
            FROM cm.om_reviewclass_x_object r
            JOIN {self.schema_parent}.cat_feature f ON r.object_id = f.id
            WHERE r.reviewclass_id = {reviewclass_id}
        """
        rows = tools_db.get_rows(sql)
        return [r["feature_type"] for r in rows or []]

    def get_allowed_feature_types_from_visitclass(self, table_name: str, visitclass_id: int) -> List[str]:
        """Function to get feature types directly from om_visitclass table."""
        sql = f"""
                SELECT DISTINCT
                    f.feature_type,
                    f.feature_class
                FROM cm.{table_name} v
                JOIN {self.schema_parent}.cat_feature f
                  ON v.feature_type = f.id
                WHERE v.id = {visitclass_id}
            """
        rows = tools_db.get_rows(sql)
        return [r["feature_type"].lower() for r in rows if r.get("feature_type")]

    def _is_reviewclass_for_all(self, reviewclass_id: int) -> bool:
        """Check if a reviewclass is linked to the 'ALL' object."""
        try:
            reviewclass_id = int(reviewclass_id)
        except (ValueError, TypeError):
            return False

        sql = f"SELECT 1 FROM cm.om_reviewclass_x_object WHERE reviewclass_id = {reviewclass_id} AND upper(object_id) = 'ALL' LIMIT 1"
        return tools_db.get_row(sql) is not None

    def _manage_tabs_enabled(self, feature_types: List[str]):
        """ Enable or disable relation tabs depending on allowed feature types (e.g., ['node', 'arc']). """

        tab_widget = self.dialog.tab_feature

        # For inventory campaigns (type 3), enable all tabs
        if self.campaign_type == 3:
            for i in range(tab_widget.count()):
                tab_widget.setTabEnabled(i, True)
            return

        # For review/visit campaigns, apply feature type restrictions
        # Normalize all feature types to lowercase for comparison
        normalized = {ft.lower() for ft in feature_types}

        for i in range(tab_widget.count()):
            widget = tab_widget.widget(i)
            if not widget:
                continue

            object_name = widget.objectName()
            tab_type = object_name.replace("tab_", "")
            enabled = tab_type in normalized
            tab_widget.setTabEnabled(i, enabled)

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
        if "tbl_campaign_x_" in widget_name:
            # Extract feature type from widget name (e.g., "tbl_campaign_x_arc" -> "arc")
            feature_type = widget_name.replace("tbl_campaign_x_", "")
            table_name = f"om_campaign_x_{feature_type}"
        else:
            # Default for campaign manager table
            table_name = "v_ui_campaign"

        tools_gw.set_tablemodel_config(self.manager_dialog if hasattr(self, 'manager_dialog') else self.dialog, qtable, table_name, schema_name="cm")

    # Campaign manager
    def load_campaigns_into_manager(self):
        """Load campaign data into the campaign management table"""
        if not hasattr(self.manager_dialog, "tbl_campaign"):
            return
        self.filter_campaigns()

    def manage_date_filter(self):
        """Update date filters based on selected field (e.g., real_startdate)"""

        field = tools_qt.get_combo_value(self.manager_dialog, self.manager_dialog.campaign_cmb_date_filter_type, 0)

        if not field:
            return

        sql = f"""
            SELECT
                COALESCE(MIN({field})::date, current_date) AS min_date,
                COALESCE(MAX({field})::date, current_date) AS max_date
            FROM cm.om_campaign
            WHERE {field} IS NOT NULL
        """
        result = tools_db.get_row(sql, is_admin=True)

        if result:
            # psycopg2 DictRow supports key access; fallback for tuple
            min_date = result.get("min_date") if hasattr(result, 'get') else result[0]
            max_date = result.get("max_date") if hasattr(result, 'get') else result[1]

            if min_date:
                self.manager_dialog.date_event_from.setDate(min_date)
            if max_date:
                self.manager_dialog.date_event_to.setDate(max_date)

    def filter_campaigns(self):
        """Filter om_campaign based on status and date"""

        filters = []

        # Directly query the cm schema to get user's role and organization
        # Guard org filter with privileges and suppress popups
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
                    filters.append(f"organization_id = {org_id}")

        # State
        status_row = self.manager_dialog.campaign_cmb_state.currentData()
        if status_row and status_row[0]:
            filters.append(f"status = {status_row[0]}")

        # Date
        date_type = tools_qt.get_combo_value(self.manager_dialog, self.manager_dialog.campaign_cmb_date_filter_type, 0)
        if date_type and date_type != -1:
            # Range of dates
            date_from = self.manager_dialog.date_event_from.date()
            date_to = self.manager_dialog.date_event_to.date()

            # Auto-correct date range
            if date_from > date_to:
                self.manager_dialog.date_event_to.setDate(date_from)
                date_to = date_from  # Update variable too

            # Ensure forward-compatible format and inclusive range
            date_format_low = 'yyyy-MM-dd 00:00:00'
            date_format_high = 'yyyy-MM-dd 23:59:59'

            interval = f"'{date_from.toString(date_format_low)}' AND '{date_to.toString(date_format_high)}'"
            date_filter = f"({date_type} BETWEEN {interval}"

            # Show null
            if self.manager_dialog.campaign_chk_show_nulls.isChecked():
                date_filter += f" OR {date_type} IS NULL)"
            else:
                date_filter += ")"

            filters.append(date_filter)

        # Build SQL
        where_clause = " AND ".join(filters)
        query = "SELECT * FROM cm.v_ui_campaign"
        if where_clause:
            query += f" WHERE {where_clause}"
        query += " ORDER BY campaign_id DESC"
        self.populate_tableview(self.manager_dialog.tbl_campaign, query)

    def delete_selected_campaign(self):
        """Delete the selected campaign"""
        selected = self.manager_dialog.tbl_campaign.selectionModel().selectedRows()
        if not selected:
            msg = tools_qt.tr("Select a campaign to delete.", context_name="cm")
            tools_qgis.show_warning(msg, dialog=self.manager_dialog)
            return

        index = selected[0]
        campaign_id = index.data()
        if not str(campaign_id).isdigit():
            msg = tools_qt.tr("Invalid campaign ID.", context_name="cm")
            tools_qgis.show_warning(msg, dialog=self.manager_dialog)
            return

        # Confirm deletion
        count = len(selected)

        msg = tools_qt.tr("Are you sure you want to delete {0} campaign(s)?", context_name="cm")
        msg_params = (count,)
        if not tools_qt.show_question(msg, msg_params=msg_params):
            return

        success = 0
        for index in selected:
            campaign_id = index.data()
            if not str(campaign_id).isdigit():
                continue
            sql = f"DELETE FROM cm.om_campaign WHERE campaign_id = {campaign_id}"
            if tools_db.execute_sql(sql):
                success += 1
        msg = tools_qt.tr("{0} campaign(s) deleted.", context_name="cm")
        msg_params = (count,)
        tools_qgis.show_info(msg, msg_params=msg_params, dialog=self.manager_dialog)
        tools_gw.refresh_selectors(is_cm=True)
        self.filter_campaigns()

    def _apply_child_campaign_field_locks(self):
        """Lock parent_id always; if set, only startdate/enddate/descript/status stay editable."""
        parent_widget = self.get_widget_by_columnname(self.dialog, "parent_id")
        if not parent_widget:
            return

        if isinstance(parent_widget, QLineEdit):
            parent_widget.setReadOnly(True)
        parent_widget.setEnabled(False)

        parent_val = tools_qt.get_text(self.dialog, parent_widget)
        if parent_val in (None, "", "null", "None"):
            return

        editable_columns = {"startdate", "enddate", "descript", "status"}
        for field in self.fields_form:
            columnname = field.get("columnname")
            if not columnname or columnname == "parent_id" or columnname in editable_columns:
                continue
            widget = self.get_widget_by_columnname(self.dialog, columnname)
            if not widget:
                continue
            if isinstance(widget, (QLineEdit, QTextEdit)):
                widget.setReadOnly(True)
            widget.setEnabled(False)

    def create_child_campaign(self):
        """Validate parent via DB, create child campaign, and open its dialog."""
        selected = self.manager_dialog.tbl_campaign.selectionModel().selectedRows()
        if not selected:
            msg = "Select a campaign to create a child campaign."
            tools_qgis.show_warning(msg, dialog=self.manager_dialog)
            return

        index = selected[0]
        parent_id = index.data()
        if not str(parent_id).isdigit():
            msg = "Invalid campaign ID"
            tools_qgis.show_warning(msg, dialog=self.manager_dialog)
            return

        parent_id = int(parent_id)
        result = tools_gw.execute_procedure(
            "gw_fct_create_child_campaign", parent_id, schema_name="cm"
        )

        if not result or result.get("status") != "Accepted":
            db_message = result.get("message") if result else None
            if isinstance(db_message, dict):
                db_message = db_message.get("text")
            if db_message:
                msg = "{0}"
                msg_params = (db_message,)
                tools_qgis.show_warning(msg, msg_params=msg_params, dialog=self.manager_dialog)
            else:
                msg = "Failed to create child campaign"
                tools_qgis.show_warning(msg, dialog=self.manager_dialog)
            return

        child_id = result.get("body", {}).get("campaign_id")
        if not child_id:
            msg = "Failed to create child campaign"
            tools_qgis.show_warning(msg, dialog=self.manager_dialog)
            return

        try:
            tools_gw.refresh_selectors(is_cm=True)
        except Exception:
            pass
        self.filter_campaigns()

        self.load_campaign_dialog(int(child_id), parent=self.manager_dialog)

    def open_campaign(self, index: Optional[QModelIndex] = None):
        """Open campaign from the clicked index safely (double click handler or button handler)."""

        # If called by double click, index is passed
        if index and hasattr(index, "isValid") and index.isValid():
            model = index.model()
            row = index.row()
            id_index = model.index(row, 0)
            campaign_ids = [model.data(id_index)]

        # If called by button, no index → get selected row
        else:
            selected = self.manager_dialog.tbl_campaign.selectionModel().selectedRows()
            if not selected:
                msg = tools_qt.tr("No campaign selected.", context_name="cm")
                tools_qgis.show_warning(msg, dialog=self.manager_dialog)
                return

            campaign_ids = [index.data() for index in selected]

        for campaign_id in campaign_ids:
            try:
                campaign_id = int(campaign_id)
                if campaign_id > 0:
                    self.load_campaign_dialog(campaign_id, parent=self.manager_dialog)
                    self._check_and_disable_class_combos()
            except (ValueError, TypeError):
                msg = tools_qt.tr("Invalid campaign ID.", context_name="cm")
                tools_qgis.show_warning(msg)


def update_expl_sector_combos(**kwargs: Any):
    """
    Update exploitation and sector combos based on organization.
    This function is designed to be called from a widgetfunction.
    """
    dialog = kwargs.get('dialog')
    parent_widget = kwargs.get('widget')
    saved_values = kwargs.get('saved_values', {})

    try:
        # Find child widgets by their object name
        expl_widget = dialog.findChild(QComboBox, 'tab_data_expl_id')

        # Get data from the currently selected item in the parent combo
        current_index = parent_widget.currentIndex()
        current_data = parent_widget.itemData(current_index) if current_index != -1 else None

        organization_id = None
        if current_data and isinstance(current_data, list) and len(current_data) > 0:
            organization_id = current_data[0]

        expl_ids = None

        # If a valid organization is selected, get its specific expl_id and sector_id lists from the database
        if organization_id:
            org_data_sql = f"SELECT expl_id FROM cm.cat_organization WHERE organization_id = {organization_id}"
            org_data_row = tools_db.get_row(org_data_sql)
            if org_data_row:
                expl_ids = org_data_row.get('expl_id')

        schema = lib_vars.schema_name

        # --- Update exploitation combo ---
        if expl_widget:
            current_expl_data = expl_widget.currentData()
            sql_expl = f"SELECT expl_id, name FROM {schema}.exploitation"
            if expl_ids is not None:
                if expl_ids:
                    sql_expl += f" WHERE expl_id = ANY(ARRAY{expl_ids})"
                else:
                    sql_expl += " WHERE 1=0"
            sql_expl += " ORDER BY name"

            rows_expl = tools_db.get_rows(sql_expl)
            tools_qt.fill_combo_values(expl_widget, rows_expl, add_empty=True)

            # Manually set the value from saved_values after populating
            saved_expl_id = saved_values.get('expl_id')
            if saved_expl_id is not None:
                # Create a temporary Campaign object to access the robust set_widget_value
                temp_campaign_instance = Campaign(None, None, None, None, None)
                temp_campaign_instance.set_widget_value(expl_widget, saved_expl_id)
            elif current_expl_data:
                index = expl_widget.findData(current_expl_data)
                if index > -1:
                    expl_widget.setCurrentIndex(index)

        # --- Update sector combo ---
        update_sector_combo(dialog, saved_values)

    except Exception as e:
        msg = tools_qt.tr("CRITICAL ERROR in update_expl_sector_combos", context_name="cm")
        tools_qgis.show_warning(f"{msg}: {e}", dialog=dialog)


def update_sector_combo(dialog: QDialog, saved_values: Optional[Dict] = None):
    """
    Update sector combo based on selected exploitation and organization.
    """
    if saved_values is None:
        saved_values = {}

    # Check user role to determine if organization filter should be applied
    username = tools_db.get_current_user()
    sql_user = f"""
        SELECT t.role_id
        FROM cm.cat_user u
        JOIN cm.cat_team t ON u.team_id = t.team_id
        WHERE u.username = '{username}'
    """
    user_info = tools_db.get_row(sql_user)
    is_admin = user_info and user_info.get('role_id') == 'role_cm_admin'

    expl_widget = dialog.findChild(QComboBox, 'tab_data_expl_id')
    sector_widget = dialog.findChild(QComboBox, 'tab_data_sector_id')
    organization_widget = dialog.findChild(QComboBox, 'tab_data_organization_id')

    if not sector_widget:
        return

    # Get organization filter
    organization_id = None
    if organization_widget:
        org_data = organization_widget.currentData()
        if org_data and isinstance(org_data, list):
            organization_id = org_data[0]

    sector_ids = None
    if organization_id:
        org_data_sql = f"SELECT sector_id FROM cm.cat_organization WHERE organization_id = {organization_id}"
        org_data_row = tools_db.get_row(org_data_sql)
        if org_data_row:
            sector_ids = org_data_row.get('sector_id')

    # Get exploitation filter
    expl_id = None
    if expl_widget:
        expl_data = expl_widget.currentData()
        if expl_data and isinstance(expl_data, list):
            expl_id = expl_data[0]

    expl_id_int = None
    if expl_id is not None:
        try:
            expl_id_int = int(expl_id)
        except (TypeError, ValueError):
            expl_id_int = None

    schema = lib_vars.schema_name
    sql_sector = f"SELECT sector_id, name FROM {schema}.sector"

    filters = []
    # If an organization is selected, we must respect its sector configuration, unless user is admin.
    if organization_id and not is_admin:
        if sector_ids:  # If sector_ids is a non-empty list
            filters.append(f"sector_id = ANY(ARRAY{sector_ids})")
        else:  # If sector_ids is None or an empty list []
            filters.append("1=0")  # Effectively blocks all sectors for this organization

    if expl_id_int is not None:
        filters.append(f"{schema}.sector.expl_id @> ARRAY[{expl_id_int}]")
    else:
        # If no expl_id is selected or it is not numeric, no sectors should be shown
        filters.append("1=0")

    if filters:
        sql_sector += " WHERE " + " AND ".join(filters)

    sql_sector += " ORDER BY name"
    current_sector_data = sector_widget.currentData()
    rows_sector = tools_db.get_rows(sql_sector)
    tools_qt.fill_combo_values(sector_widget, rows_sector, add_empty=True)

    saved_sector_id = saved_values.get('sector_id')
    if saved_sector_id is not None:
        temp_campaign_instance = Campaign(None, None, None, None, None)
        temp_campaign_instance.set_widget_value(sector_widget, saved_sector_id)
    elif current_sector_data:
        index = sector_widget.findData(current_sector_data)
        if index > -1:
            sector_widget.setCurrentIndex(index)
