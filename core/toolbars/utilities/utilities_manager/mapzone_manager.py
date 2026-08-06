"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import json
import copy

from functools import partial
from qgis.PyQt.sip import isdeleted

from qgis.PyQt.QtGui import QCursor, QColor
from qgis.PyQt.QtCore import Qt, QDateTime
from qgis.PyQt.QtWidgets import QAction, QMenu, QTableView, QAbstractItemView, QGridLayout, QLabel, QWidget, QComboBox, QPushButton, QHeaderView, QListWidget, QLineEdit, QCheckBox, QTabWidget
from qgis.PyQt.QtSql import QSqlTableModel
from qgis.core import QgsVectorLayer, QgsLineSymbol, QgsRendererCategory, QgsDateTimeRange, Qgis, QgsCategorizedSymbolRenderer, QgsTemporalNavigationObject, QgsInterval

from qgis.gui import QgsMapToolEmitPoint

from ..toolbox_btn import GwToolBoxButton
from ....ui.ui_manager import GwMapzoneManagerUi, GwMapzoneConfigUi, GwInfoGenericUi
from ....utils.snap_manager import GwSnapManager
from ....utils import tools_gw
from ..... import global_vars
from .....libs import lib_vars, tools_qgis, tools_qt, tools_db, tools_os


class GwMapzoneManager:

    def __init__(self):
        """ Class to control 'Add element' of toolbar 'edit' """

        self.plugin_dir = lib_vars.plugin_dir
        self.iface = global_vars.iface
        self.schema_name = lib_vars.schema_name
        self.canvas = global_vars.canvas

        self.snapper_manager = GwSnapManager(self.iface)
        self.snapper_manager.set_snapping_layers()
        self.vertex_marker = self.snapper_manager.vertex_marker
        self.rubber_band = tools_gw.create_rubberband(global_vars.canvas)

        self.feature_types = ['sector_id', 'dma_id', 'presszone_id', 'dqa_id', 'drainzone_id']
        self.mapzone_mng_dlg = None
        self.netscenario_id = None

        # to enable btn_execute and btn_flood, the mapzone type must be enabled in config_param_system table -> utils_graphanalytics_status

        self.flood_enabled_mapzones = ["sector", "dma", "dqa", "presszone", "dwfzone", "supplyzone"]
        self.macromapzone_types = ["macrosector", "macrodma", "macrodqa", "macroomzone"]
        self.readonly_mapzone_tabs = ["crmzone"]

        # The -901 is transformed to user selected exploitation in the mapzones analysis
        self.user_selected_exploitation = '-901'
        self._flood_enabled_by_tab = {}
        self._dynamic_dialog_result = None

    def manage_mapzones(self):
        """Open mapzone manager with dynamic widgets and Python signal wiring."""

        # Create dialog
        self.mapzone_mng_dlg = GwMapzoneManagerUi(self)
        tools_gw.load_settings(self.mapzone_mng_dlg)
        if not self._setup_dynamic_dialog():
            msg = "Mapzone manager dynamic config not found."
            tools_qgis.show_warning(msg)
            return

        if not self._load_main_tabs():
            return

        # Icons come from config_form_fields.stylesheet.icon
        self.mapzone_mng_dlg.btn_flood.setEnabled(False)

        # Restore state
        self._restore_show_inactive_state()
        self._restore_filter_selector_state()
        self._restore_last_tab()

        # Keep only lifecycle/non-config-driven signals in Python.
        self.mapzone_mng_dlg.main_tab.currentChanged.connect(partial(self._manage_current_changed))
        self.mapzone_mng_dlg.finished.connect(partial(tools_gw.reset_rubberband, self.rubber_band, None))
        self.mapzone_mng_dlg.finished.connect(partial(tools_gw.close_dialog, self.mapzone_mng_dlg, True))
        self.mapzone_mng_dlg.finished.connect(partial(self._on_dialog_closed))
        self.mapzone_mng_dlg.chk_active.stateChanged.connect(self._save_show_inactive_state)
        self.mapzone_mng_dlg.finished.connect(partial(tools_gw.save_current_tab, self.mapzone_mng_dlg, self.mapzone_mng_dlg.main_tab, 'mapzone_manager'))
        self.mapzone_mng_dlg.chk_active.stateChanged.connect(partial(self._filter_active, self.mapzone_mng_dlg))
        if self.mapzone_mng_dlg.chk_filter_selector is not None:
            self.mapzone_mng_dlg.chk_filter_selector.stateChanged.connect(
                partial(self._on_filter_selector_changed, self.mapzone_mng_dlg))
            self.mapzone_mng_dlg.chk_filter_selector.stateChanged.connect(
                self._save_filter_selector_state)

        self._manage_current_changed()
        self.mapzone_mng_dlg.main_tab.currentChanged.connect(partial(self._filter_active, self.mapzone_mng_dlg, None))

        tools_gw.open_dialog(self.mapzone_mng_dlg, 'mapzone_manager')

    def _setup_dynamic_dialog(self):
        """Load and bind dynamic widgets for mapzone manager (strict mode)."""

        json_result = self._load_dynamic_dialog_config()
        if not json_result:
            return False
        self._dynamic_dialog_result = json_result
        setattr(tools_gw, 'mapzone_manager', self)
        
        try:
            self._manage_dlg_widgets(json_result)
            self._bind_dynamic_widgets()
            self._connect_dynamic_widget_signals(json_result)
        except Exception:
            self._clear_dynamic_module_reference()
            raise
        required_widgets = {
            'txt_name': self.mapzone_mng_dlg.txt_name,
            'chk_active': self.mapzone_mng_dlg.chk_active,
            'main_tab': self.mapzone_mng_dlg.main_tab,
            'btn_flood': self.mapzone_mng_dlg.btn_flood,
            'btn_execute': self.mapzone_mng_dlg.btn_execute,
            'btn_config': self.mapzone_mng_dlg.btn_config,
            'btn_toggle_active': self.mapzone_mng_dlg.btn_toggle_active,
            'btn_create': self.mapzone_mng_dlg.btn_create,
            'btn_update': self.mapzone_mng_dlg.btn_update,
            'btn_delete': self.mapzone_mng_dlg.btn_delete,
            'btn_cancel': self.mapzone_mng_dlg.btn_cancel,
        }
        missing = [name for name, widget in required_widgets.items() if widget is None]
        if missing:
            msg = "Mapzone dynamic widgets not found: {0}"
            msg_params = (", ".join(missing),)
            tools_qgis.show_warning(msg, msg_params=msg_params, dialog=self.mapzone_mng_dlg)
            self._clear_dynamic_module_reference()
            return False
        return True

    def _load_dynamic_dialog_config(self):
        """Populate mapzone manager dialog from config_form_fields using gw_fct_get_dialog."""

        form = {"formName": "mapzone_manager", "formType": "form_mapzone"}
        body = {"client": {"cur_user": tools_db.current_user}, "form": form}
        json_result = tools_gw.execute_procedure('gw_fct_get_dialog', body)
        if not json_result or json_result.get('status') != 'Accepted':
            return None
        if not json_result.get('body', {}).get('data', {}).get('fields'):
            return None
        return json_result

    def _manage_dlg_widgets(self, complet_result):
        """Create dynamic widgets using shared tools_gw pipeline plus mapzone-only gaps."""

        normalized_result = copy.deepcopy(complet_result)
        fields = normalized_result.get('body', {}).get('data', {}).get('fields') or []
        layouts = normalized_result.get('body', {}).get('form', {}).get('layouts', {}) or {}
        layout_orientations = {
            layout_name: (layout_info or {}).get('lytOrientation')
            for layout_name, layout_info in layouts.items()
            if (layout_info or {}).get('lytOrientation')
        }
        tabwidget_fields = []

        for field in fields:
            if field is None or field.get('hidden'):
                continue

            if field.get('layoutorder') is None:
                msg = "The field layoutorder is not configured for"
                param = f"formname:mapzone_manager, columnname:{field.get('columnname')}"
                tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=param, dialog=self.mapzone_mng_dlg)
                field['hidden'] = True
                continue

            # Keep manager buttons as QPushButton (avoid _manage_button topology fallback).
            if field.get('widgettype') == 'button':
                stylesheet = field.get('stylesheet') or {}
                if not field.get('value') and stylesheet.get('icon') is None:
                    fallback_text = (field.get('widgetcontrols') or {}).get('text') or field.get('label') or ''
                    field['value'] = fallback_text

            # tools_gw.set_widgets currently skips tabwidget; inject it after generic build.
            if field.get('widgettype') == 'tabwidget':
                tabwidget_fields.append(field)

        tools_gw.manage_dlg_widgets(self, self.mapzone_mng_dlg, normalized_result)

        for field in tabwidget_fields:
            widget_name = field.get('widgetname') or f"{field.get('tabname', 'tab_none')}_{field.get('columnname', 'main_tab')}"
            if self.mapzone_mng_dlg.findChild(QTabWidget, widget_name) is not None:
                continue

            layout = self.mapzone_mng_dlg.findChild(QGridLayout, field.get('layoutname'))
            if layout is None:
                continue

            orientation = layout_orientations.get(layout.objectName(), "vertical")
            layout.setProperty('lytOrientation', orientation)

            widget = QTabWidget(self.mapzone_mng_dlg)
            widget.setObjectName(widget_name)
            if field.get('columnname'):
                widget.setProperty('columnname', field['columnname'])
            if 'iseditable' in field:
                widget.setEnabled(bool(field['iseditable']))

            tools_gw.add_widget_combined(self.mapzone_mng_dlg, field, None, widget, 0)

    def _bind_widget(self, widget_type, *columnnames):
        """Find a dynamic widget by prefixed or plain objectName."""
        widget = None
        for columnname in columnnames:
            widget = self.mapzone_mng_dlg.findChild(widget_type, f"tab_none_{columnname}")
            if widget is None:
                widget = self.mapzone_mng_dlg.findChild(widget_type, columnname)
            if widget is not None:
                break
        return widget

    def _get_dynamic_fields(self, complet_result=None):
        result = complet_result
        if result is None:
            result = self._dynamic_dialog_result
        if result is None:
            return []

        body = result.get('body')
        if not isinstance(body, dict):
            return []

        data = body.get('data')
        if not isinstance(data, dict):
            return []

        fields = data.get('fields')
        if not isinstance(fields, list):
            return []

        return fields

    def _find_field_by_columnnames(self, columnnames, complet_result=None):
        fields = self._get_dynamic_fields(complet_result)
        for field in fields:
            if field is None:
                continue
            if field.get('columnname') in columnnames:
                return field
        return None

    def _get_tabwidget_field(self):
        """Return the first visible tabwidget field from dynamic dialog data."""
        fields = self._get_dynamic_fields()
        for field in fields:
            if field is None:
                continue
            if field.get('hidden'):
                continue
            if field.get('widgettype') == 'tabwidget':
                return field
        return None

    def _bind_dynamic_widgets(self):
        """Bind dynamic widgets using the same explicit pattern used elsewhere."""
        # Keep legacy alias while DB is being normalized to txt_name.
        txt_field = self._find_field_by_columnnames(("txt_name",))
        txt_column = (txt_field or {}).get('columnname')
        self.mapzone_mng_dlg.txt_name = self._bind_widget(QLineEdit, txt_column) if txt_column else None
        self.mapzone_mng_dlg.chk_active = self._bind_widget(QCheckBox, "chk_active")
        self.mapzone_mng_dlg.chk_filter_selector = self._bind_widget(QCheckBox, "chk_filter_selector")
        tabwidget_field = self._get_tabwidget_field()
        tabwidget_column = (tabwidget_field or {}).get('columnname')
        self.mapzone_mng_dlg.main_tab = self._bind_widget(QTabWidget, tabwidget_column) if tabwidget_column else None
        self.mapzone_mng_dlg.btn_flood = self._bind_widget(QPushButton, "btn_flood")
        self.mapzone_mng_dlg.btn_execute = self._bind_widget(QPushButton, "btn_execute")
        self.mapzone_mng_dlg.btn_config = self._bind_widget(QPushButton, "btn_config")
        self.mapzone_mng_dlg.btn_toggle_active = self._bind_widget(QPushButton, "btn_toggle_active")
        self.mapzone_mng_dlg.btn_create = self._bind_widget(QPushButton, "btn_create")
        self.mapzone_mng_dlg.btn_update = self._bind_widget(QPushButton, "btn_update")
        self.mapzone_mng_dlg.btn_delete = self._bind_widget(QPushButton, "btn_delete")
        self.mapzone_mng_dlg.btn_cancel = self._bind_widget(QPushButton, "btn_cancel")

    def _connect_dynamic_widget_signals(self, complet_result):
        """Connect widget signals from DB metadata when handler belongs to this manager."""
        txt_field = self._find_field_by_columnnames(("txt_name"), complet_result)
        if txt_field is None or self.mapzone_mng_dlg.txt_name is None:
            return

        widgetfunction = txt_field.get('widgetfunction')
        if not isinstance(widgetfunction, dict):
            return

        module_name = widgetfunction.get('module')
        function_name = widgetfunction.get('functionName')
        if not function_name:
            return
        if module_name and module_name != 'mapzone_manager':
            return

        handler = getattr(self, function_name, None)
        if callable(handler):
            self.mapzone_mng_dlg.txt_name.textChanged.connect(partial(handler))

    def _use_selector_filter(self):
        """Return True when table data must come from selector-based v_ui_*_sel views."""
        chk = getattr(self.mapzone_mng_dlg, 'chk_filter_selector', None)
        if chk is None or isdeleted(chk):
            return False
        return chk.isChecked()

    def _get_mapzone_type(self, widget=None):
        """Resolve mapzone type (sector, dma, ...) from the current or given tab widget."""
        if widget is None:
            if self.mapzone_mng_dlg is None or isdeleted(self.mapzone_mng_dlg):
                return None
            widget = self.mapzone_mng_dlg.main_tab.currentWidget()
        if widget is None or isdeleted(widget):
            return None

        mapzone_type = widget.property('mapzone_type')
        if mapzone_type:
            return mapzone_type

        object_name = widget.objectName() or ''
        if object_name.startswith('v_ui_'):
            return object_name.replace('v_ui_', '', 1).replace('_sel', '').replace('_cat', '')
        if object_name.startswith('tbl_v_ui_'):
            return object_name.replace('tbl_v_ui_', '', 1).replace('_sel', '').replace('_cat', '')
        if object_name.startswith('tbl_plan_netscenario_'):
            return object_name.replace('tbl_plan_netscenario_', '', 1)
        return object_name.split('_')[-1]

    def _get_mapzone_view(self, mapzone_type=None):
        """Return v_ui_* view used to populate the manager table."""
        if mapzone_type is None:
            mapzone_type = self._get_mapzone_type()
        if not mapzone_type:
            return None
        suffix = '_sel' if self._use_selector_filter() else ''
        return f'v_ui_{mapzone_type}{suffix}'

    def _get_mapzone_edit_view(self, mapzone_type=None):
        """Return ve_* or plan_netscenario_* view used for CRUD operations."""
        mapzone_type = mapzone_type or self._get_mapzone_type()
        if not mapzone_type:
            return None
        if self.netscenario_id is not None:
            return f'plan_netscenario_{mapzone_type}'
        return f've_{mapzone_type}'

    def _load_main_tabs(self):
        """Create dynamic manager tabs (table views) for project mapzone types."""
        if self.mapzone_mng_dlg.main_tab is None:
            return False

        self.mapzone_mng_dlg.main_tab.clear()
        tabs_config = []
        tabwidget_field = self._get_tabwidget_field()
        if tabwidget_field:
            tabwidget_column = tabwidget_field.get('columnname')
            tabs_key = f"tabs_{tabwidget_column}" if tabwidget_column else None
            if tabs_key:
                tabs_config = tabwidget_field.get(tabs_key) or []

        tabs = []
        for tab_cfg in tabs_config:
            if not isinstance(tab_cfg, dict):
                continue
            tab_name = tab_cfg.get('tabName') or tab_cfg.get('tabname')
            if not tab_name:
                continue
            mapzone_type = tab_name.replace('tab_', '', 1)
            tabs.append((mapzone_type, tab_cfg.get('tabLabel') or mapzone_type.capitalize()))

        if not tabs:
            msg = "Mapzone manager tabs not configured in DB."
            tools_qgis.show_warning(msg, dialog=self.mapzone_mng_dlg)
            return False

        for mapzone_type, tab_label in tabs:
            qtableview = QTableView()
            qtableview.setProperty('mapzone_type', mapzone_type)
            qtableview.setObjectName(f'v_ui_{mapzone_type}')
            qtableview.clicked.connect(partial(self._manage_highlight, qtableview))
            qtableview.doubleClicked.connect(partial(self.manage_update, self.mapzone_mng_dlg, qtableview, None))
            qtableview.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
            qtableview.customContextMenuRequested.connect(partial(self._show_context_menu, qtableview))
            self.mapzone_mng_dlg.main_tab.addTab(qtableview, tab_label)
        return self.mapzone_mng_dlg.main_tab.count() > 0

    def _manage_highlight(self, qtableview, index):
        """ Creates rubberband to indicate which feature is selected """

        tools_gw.reset_rubberband(self.rubber_band)
        table = self._get_mapzone_view(qtableview.property('mapzone_type'))
        feature_type = 'feature_id'

        for x in self.feature_types:
            col_idx = tools_qt.get_col_index_by_col_name(qtableview, x)
            if col_idx is not None and col_idx is not False:
                feature_type = x
                break
        if feature_type != 'feature_id':
            table = f"v_ui_{feature_type.split('_')[0]}"
        tools_qgis.highlight_feature_by_id(qtableview, table, feature_type, self.rubber_band, 5, index)

    def _txt_name_changed(self, text):
        show_inactive = self.mapzone_mng_dlg.chk_active.isChecked()
        mapzone_type = self.mapzone_mng_dlg.main_tab.tabText(self.mapzone_mng_dlg.main_tab.currentIndex()).lower()
        expr = f"(name ilike '%{text}%' or code ilike '%{text}%' or {mapzone_type}_id::text ilike '%{text}%')"
        if not show_inactive:
            expr += " and active is true"
        self._fill_mapzone_table(expr=expr)

    def _manage_current_changed(self, clear_text=True):
        """ Manages tab changes """
        if self.mapzone_mng_dlg is None or isdeleted(self.mapzone_mng_dlg):
            return
        if self.mapzone_mng_dlg.main_tab.currentWidget() is None:
            return
        # Get the state of the "show inactive" checkbox
        show_inactive = self.mapzone_mng_dlg.chk_active.isChecked()

        # Reset rubberband
        tools_gw.reset_rubberband(self.rubber_band)

        # Build the filter expression based on the state of the "show inactive" checkbox
        expr = "" if show_inactive else "active is true"

        # Fill current table
        self._fill_mapzone_table(expr=expr)

        mapzone_type = self.mapzone_mng_dlg.main_tab.tabText(self.mapzone_mng_dlg.main_tab.currentIndex()).lower()
        if self._is_readonly_mapzone(self.mapzone_mng_dlg, mapzone_type):
            self.mapzone_mng_dlg.btn_execute.setEnabled(False)
            self.mapzone_mng_dlg.btn_flood.setEnabled(False)
            self.mapzone_mng_dlg.btn_config.setEnabled(False)
            self.mapzone_mng_dlg.btn_toggle_active.setEnabled(False)
            self.mapzone_mng_dlg.btn_create.setEnabled(False)
            self.mapzone_mng_dlg.btn_update.setEnabled(False)
            self.mapzone_mng_dlg.btn_delete.setEnabled(False)
            return

        self.mapzone_mng_dlg.btn_toggle_active.setEnabled(True)
        self.mapzone_mng_dlg.btn_create.setEnabled(True)
        self.mapzone_mng_dlg.btn_update.setEnabled(True)
        self.mapzone_mng_dlg.btn_delete.setEnabled(True)

        # Enable/Disable config button on macrodma and macrosector
        list_tabs_no_config = []
        list_tabs_no_config.append(tools_qt.get_tab_index_by_tab_name(self.mapzone_mng_dlg.main_tab, 'v_ui_macrodma'))
        list_tabs_no_config.append(tools_qt.get_tab_index_by_tab_name(self.mapzone_mng_dlg.main_tab, 'v_ui_macrosector'))
        if self.mapzone_mng_dlg.main_tab.currentIndex() in list_tabs_no_config:
            self.mapzone_mng_dlg.btn_config.setEnabled(False)
        else:
            self.mapzone_mng_dlg.btn_config.setEnabled(True)

        is_enabled_from_config = self._get_mapzone_enabled_status_from_config(mapzone_type)
        self.mapzone_mng_dlg.btn_execute.setEnabled(is_enabled_from_config)
        can_enable_flood = is_enabled_from_config and mapzone_type in self.flood_enabled_mapzones
        self.mapzone_mng_dlg.btn_flood.setEnabled(can_enable_flood and self._flood_enabled_by_tab.get(mapzone_type, False))

        # Refresh txt_feature_id
        if clear_text:
            tools_qt.set_widget_text(self.mapzone_mng_dlg, self.mapzone_mng_dlg.txt_name, '')
        else:
            self.mapzone_mng_dlg.txt_name.textChanged.emit(self.mapzone_mng_dlg.txt_name.text())

    def _is_readonly_mapzone(self, dialog=None, mapzone_type=None):
        if dialog is None:
            dialog = self.mapzone_mng_dlg
        if mapzone_type is None:
            mapzone_type = dialog.main_tab.tabText(dialog.main_tab.currentIndex()).lower()
        return mapzone_type in self.readonly_mapzone_tabs

    def _get_mapzone_enabled_status_from_config(self, mapzone_type):
        """
        Returns execution status for a mapzone type from utils_graphanalytics_status.
        Missing/malformed values are treated as disabled.
        """
        row = tools_gw.get_config_value(
            parameter='utils_graphanalytics_status',
            columns='value::text',
            table='config_param_system',
            log_info=False
        )
        if not row or row[0] is None:
            return False

        try:
            data = json.loads(row[0]) if isinstance(row[0], str) else row[0]
        except (TypeError, ValueError):
            return False

        if not isinstance(data, dict):
            return False

        key = mapzone_type.upper()
        return bool(data.get(key, False))

    def _fill_mapzone_table(self, set_edit_triggers=QTableView.EditTrigger.NoEditTriggers, expr=None):
        """ Fill mapzone table with data from its corresponding table """
        # Manage exception if dialog is closed
        if self.mapzone_mng_dlg is None or isdeleted(self.mapzone_mng_dlg):
            return
        current_widget = self.mapzone_mng_dlg.main_tab.currentWidget()
        if current_widget is None:
            return

        mapzone_type = self._get_mapzone_type(current_widget)
        view_name = self._get_mapzone_view(mapzone_type)
        if not view_name:
            return

        self.table_name = view_name
        widget = current_widget

        if self.schema_name not in self.table_name:
            self.table_name = self.schema_name + "." + self.table_name

        # Set model
        model = QSqlTableModel(db=lib_vars.qgis_db_credentials)
        model.setTable(self.table_name)
        model.setEditStrategy(QSqlTableModel.EditStrategy.OnFieldChange)
        model.setSort(0, Qt.SortOrder.AscendingOrder)
        model.select()

        # Check for errors
        if model.lastError().isValid():
            if 'Unable to find table' in model.lastError().text():
                tools_db.reset_qsqldatabase_connection(self.mapzone_mng_dlg)
            else:
                tools_qgis.show_warning(model.lastError().text(), dialog=self.mapzone_mng_dlg)
            return

        # Attach model to table view
        if expr:
            widget.setModel(model)
            widget.model().setFilter(expr)
        else:
            widget.setModel(model)
        widget.setSortingEnabled(True)

        # Set widget & model properties
        tools_qt.set_tableview_config(widget, selection=QAbstractItemView.SelectionBehavior.SelectRows, edit_triggers=set_edit_triggers,
                                      section_resize_mode=QHeaderView.ResizeMode.Interactive)
        tools_gw.set_tablemodel_config(self.mapzone_mng_dlg, widget, f"{self.table_name[len(f'{self.schema_name}.'):]}")

        # Hide unwanted columns
        col_idx = tools_qt.get_col_index_by_col_name(widget, 'dscenario_id')
        if col_idx not in (None, False):
            widget.setColumnHidden(col_idx, True)

        geom_col_idx = tools_qt.get_col_index_by_col_name(widget, 'the_geom')
        if geom_col_idx not in (None, False):
            widget.setColumnHidden(geom_col_idx, True)

        # Sort the table
        model.sort(0, Qt.SortOrder.AscendingOrder)

    def _is_show_inactive_checked(self, dialog=None, state=None):
        """Return True only when checkbox state is explicitly Checked."""
        if dialog is None:
            dialog = self.mapzone_mng_dlg
        if dialog is None or isdeleted(dialog) or dialog.chk_active is None:
            return False

        if state is None:
            state = dialog.chk_active.checkState()

        if isinstance(state, bool):
            return state

        checked_value = int(Qt.CheckState.Checked)
        try:
            return int(state) == checked_value
        except (TypeError, ValueError):
            return dialog.chk_active.isChecked()

    def _on_filter_selector_changed(self, dialog, state=None):
        """Reload current tab using selector or cat_manager view."""
        if dialog is None or isdeleted(dialog):
            return
        self._manage_current_changed(clear_text=False)

    def _filter_active(self, dialog, active):
        """ Filters manager table by active """

        widget_table = dialog.main_tab.currentWidget()

        show_inactive = self._is_show_inactive_checked(dialog, active)
        mapzone_type = self.mapzone_mng_dlg.main_tab.tabText(self.mapzone_mng_dlg.main_tab.currentIndex()).lower()

        search_text = dialog.txt_name.text()
        expr = "" if show_inactive else "active is true"

        if search_text:
            if expr:
                expr += " and "
            expr = f"(name ilike '%{search_text}%' or code ilike '%{search_text}%' or {mapzone_type}_id::text ilike '%{search_text}%')"

        # Refresh model with selected filter
        widget_table.model().setFilter(expr)
        widget_table.model().select()

    def _open_mapzones_analysis(self, *args, **kwargs):
        """ Opens the toolbox 'mapzones_analysis' with the current type of mapzone set """
        mapzone_name = self.mapzone_mng_dlg.main_tab.tabText(self.mapzone_mng_dlg.main_tab.currentIndex()).lower()
        if self._is_readonly_mapzone(self.mapzone_mng_dlg, mapzone_name):
            return

        # Execute toolbox function
        toolbox_btn = GwToolBoxButton(None, None, None, None, None)
        macromapzone_function_id: int = 3482
        mapzone_function_id: int = 2768
        function_id: int = macromapzone_function_id if mapzone_name in self.macromapzone_types else mapzone_function_id

        # Connect signals - refresh table when dialog is closed
        connect = [self._refresh_mapzone_table_on_close]

        dlg_functions = toolbox_btn.open_function_by_id(function_id, use_aux_conn=False, connect_signal=connect)

        # Set mapzone type in combo graphClass
        mapzone_type = self.mapzone_mng_dlg.main_tab.tabText(self.mapzone_mng_dlg.main_tab.currentIndex())
        tools_qt.set_combo_value(dlg_functions.findChild(QComboBox, 'graphClass'), f"{mapzone_type.upper()}", 0)
        tools_qt.set_widget_enabled(dlg_functions, 'graphClass', False)

        # Connect btn 'Run' to enable btn_flood when pressed
        run_button = dlg_functions.findChild(QPushButton, 'btn_run')
        enable_flood = mapzone_name in self.flood_enabled_mapzones
        if run_button and self.mapzone_mng_dlg.btn_flood and enable_flood:
            run_button.clicked.connect(partial(self._enable_flood_for_tab, mapzone_name))

    def _enable_flood_for_tab(self, mapzone_name):
        """Enable flood button only for the current mapzone tab."""
        if mapzone_name not in self.flood_enabled_mapzones:
            return
        self._flood_enabled_by_tab[mapzone_name] = True
        self.mapzone_mng_dlg.btn_flood.setEnabled(True)

    def _refresh_mapzone_table_on_close(self, result_ignored=None):
        """ Refreshes the table when the dialog is closed, ignoring the result signal. """
        if self.mapzone_mng_dlg is None or isdeleted(self.mapzone_mng_dlg):
            return
        show_inactive = self.mapzone_mng_dlg.chk_active.isChecked()
        expr = "" if show_inactive else "active is true"
        self._fill_mapzone_table(expr=expr)

    def _handle_flood_analysis_click(self, *args, **kwargs):
        """Handle flood button click based on user settings."""
        if self._is_readonly_mapzone(self.mapzone_mng_dlg):
            return
        qgis_mapzone_inundation_from_arc = tools_gw.get_config_value('qgis_mapzone_inundation_from_arc', table='config_param_system')

        if qgis_mapzone_inundation_from_arc and qgis_mapzone_inundation_from_arc[0] == 'true':
            self._start_flood_analysis_from_arc()
        else:
            self._open_flood_analysis()

    def _start_flood_analysis_from_arc(self):
        """Enable arc selection before running inundation analysis."""
        layer = tools_qgis.get_layer_by_tablename('ve_arc', show_warning_=True)
        if not layer:
            msg = "Arc layer not found. Cannot start inundation from arc."
            tools_qgis.show_warning(msg, dialog=self.mapzone_mng_dlg)
            return

        self.layer_arc = layer
        tools_qgis.set_layer_visible(layer)
        self.iface.setActiveLayer(layer)

        tools_gw.disconnect_signal('mapzone_manager_snapping')
        self.emit_point = QgsMapToolEmitPoint(self.canvas)
        self.canvas.setMapTool(self.emit_point)

        tools_gw.connect_signal(self.canvas.xyCoordinates, partial(self._mouse_moved, layer),
                                'mapzone_manager_snapping', 'flood_from_arc_xyCoordinates_mouse_moved')
        tools_gw.connect_signal(self.emit_point.canvasClicked,
                                partial(self._identify_arc_and_run_flood_analysis, self.mapzone_mng_dlg),
                                'mapzone_manager_snapping', 'flood_from_arc_ep_canvasClicked')

        msg = "Select an arc to start inundation analysis."
        tools_qgis.show_info(msg, dialog=self.mapzone_mng_dlg)

    def _identify_arc_and_run_flood_analysis(self, dialog, point, event):
        """Identify the arc at the selected point and run flood analysis."""
        if event == Qt.MouseButton.RightButton:
            self._cancel_snapping_tool(dialog, None)
            self.iface.actionPan().trigger()
            return

        event_point = self.snapper_manager.get_event_point(point=point)
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if not result.isValid():
            msg = "No valid snapping result. Please select a valid arc."
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        snapped_feature = self.snapper_manager.get_snapped_feature(result)
        arc_id = snapped_feature.attribute('arc_id')
        if not arc_id:
            msg = "No arc ID found at the snapped location."
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        try:
            geometry = snapped_feature.geometry()
            self.rubber_band.setToGeometry(geometry, None)
            self.rubber_band.setColor(QColor(255, 0, 0, 100))
            self.rubber_band.setWidth(5)
            self.rubber_band.show()
        except AttributeError:
            msg = "Unable to highlight the snapped arc."
            tools_qgis.show_warning(msg, dialog=dialog)

        msg = "Flood analysis will start from arc ID"
        tools_qgis.show_info(msg, dialog=dialog, parameter=arc_id)
        self.selected_arc_id = arc_id

        self._open_flood_analysis(selected_arc_id=arc_id)

        try:
            self.layer_arc.removeSelection()
        except AttributeError:
            pass

        tools_qgis.disconnect_snapping(True, self.emit_point, self.vertex_marker)
        tools_qgis.disconnect_signal_selection_changed()
        tools_gw.disconnect_signal('mapzone_manager_snapping')

    def _open_flood_analysis(self, selected_arc_id=None):
        """Opens the toolbox 'flood_analysis' and runs the SQL function to create the temporal layer."""
        mapzone_name = self.mapzone_mng_dlg.main_tab.tabText(self.mapzone_mng_dlg.main_tab.currentIndex()).lower()

        # Call gw_fct_getgraphinundation
        extras_params = f'"mapzone": "{mapzone_name}"'
        if selected_arc_id is not None:
            extras_params += f', "selected_arc_id": "{selected_arc_id}"'
        extras = f'"parameters":{{{extras_params}}}'
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_getgraphinundation', body)
        if not json_result or json_result.get('status') != 'Accepted':
            msg = "No valid data received from the SQL function."
            tools_qgis.show_warning(msg, dialog=self.mapzone_mng_dlg)
            return
        line_data = json_result.get('body', {}).get('data', {}).get('line')
        if not line_data:
            msg = "No valid line data received from the SQL function."
            tools_qgis.show_warning(msg, dialog=self.mapzone_mng_dlg)
            return

        line_layers = line_data if isinstance(line_data, list) else [line_data]

        # Extract mapzone_ids with data from json_result
        valid_mapzone_ids = set()
        for layer_data in line_layers:
            features = (layer_data or {}).get('features', [])
            if features is not None:
                for feature in features:
                    properties = feature.get('properties', {})
                    mapzone_id = properties.get('mapzone_id')
                    if mapzone_id is not None:
                        valid_mapzone_ids.add(mapzone_id)
        # Add the flooding data to temporal layer(s)
        vlayer_list = []
        for layer_data in line_layers:
            layer_name = (layer_data or {}).get('layerName')
            if not layer_name:
                continue
            vlayer = tools_qgis.get_layer_by_layername(layer_name)
            if not vlayer or not vlayer.isValid():
                continue
            # Apply styling only to valid mapzones
            self._setup_temporal_layer(vlayer)
            vlayer_list.append(vlayer)

        if vlayer_list:
            msg = "Temporal layer created successfully."
            tools_qgis.show_success(msg, dialog=self.mapzone_mng_dlg)
            tools_qgis.zoom_to_layer(vlayer_list[0])
        else:
            msg = "Failed to retrieve the temporal layer"
            tools_qgis.show_warning(msg, dialog=self.mapzone_mng_dlg)

    def _setup_temporal_layer(self, vlayer: QgsVectorLayer):
        """Sets the temporal properties for the layer, specifically using the timestep field."""

        if vlayer.isValid():
            temporal_properties = vlayer.temporalProperties()

            if 'timestep' in [field.name() for field in vlayer.fields()]:

                temporal_properties.setStartField('timestep')
                temporal_properties.setEndField('timestep')

                # Set mode to Single Field with Date/Time
                temporal_properties.setMode(Qgis.VectorTemporalMode.FeatureDateTimeInstantFromField)

                # Activate temporal properties and accumulate features over time
                temporal_properties.setIsActive(True)
                temporal_properties.setAccumulateFeatures(True)

                vlayer.triggerRepaint()

                self._activate_temporal_controller(vlayer)

    def _apply_styles_to_layer(self, vlayer, mapzones, valid_mapzone_ids):
        """Applies styles to the layer based on the mapzone styles retrieved, filtering only those with data in valid_mapzone_ids."""

        categories = []
        valid_mapzone_ids_str = {str(mapzone_id) for mapzone_id in valid_mapzone_ids if mapzone_id is not None}

        for mapzone in mapzones:
            try:
                transparency = float(mapzone.get('transparency', 1.0))
            except (TypeError, ValueError):
                transparency = 1.0

            values = mapzone.get('values', [])

            # Only include values that match the `mapzone_id`s present in valid_mapzone_ids
            filtered_values = [
                value for value in values
                if str(value.get('id')) in valid_mapzone_ids_str
            ]
            if not filtered_values:
                continue

            # Process each filtered value to apply styling
            for value in filtered_values:
                mapzone_id = value.get('id')
                color_str = value.get('stylesheet', {}).get('featureColor', '0,0,0')
                r, g, b = map(int, color_str.split(','))

                # Create color with full opacity
                color = QColor(r, g, b)
                color.setAlphaF(transparency)

                # Create a line symbol with a visible stroke width and solid style
                symbol = QgsLineSymbol.createSimple({'line_style': 'solid', 'width': '2', 'color': color.name()})

                # Apply categorized style to the layer. In this case each unique mapzone_id will have a different color
                category = QgsRendererCategory(mapzone_id, symbol, str(mapzone_id))
                categories.append(category)

        # Sort categories by mapzone_id in ascending order
        categories = sorted(categories, key=lambda x: int(x.label()))

        # Apply categorized renderer if there are valid categories
        if categories:
            renderer = QgsCategorizedSymbolRenderer("mapzone_id", categories)
            vlayer.setRenderer(renderer)

            # Force refresh to apply style
            vlayer.triggerRepaint()
            self.iface.layerTreeView().refreshLayerSymbology(vlayer.id())
            self.iface.mapCanvas().refreshAllLayers()
        else:
            return

    def _activate_temporal_controller(self, vlayer: QgsVectorLayer):
        """Activates the Temporal Controller with animated temporal navigation."""

        # Get the temporal controller from the QGIS project
        temporal_controller = self.iface.mapCanvas().temporalController()
        if not temporal_controller:
            return

        # Check if the layer has active temporal properties
        temporal_properties = vlayer.temporalProperties()
        if not temporal_properties.isActive():
            return

        # Close the temporal controller tab if it's open
        action = self.iface.mainWindow().findChild(QAction, 'mActionTemporalController')
        if action.isChecked():
            action.trigger()

        # Extract temporal values and set temporal extents
        start_field = temporal_properties.startField()
        field_index = vlayer.fields().indexOf(start_field)
        features = vlayer.getFeatures()

        # Extract temporal values
        temporal_values = []
        for feature in features:
            value = feature.attribute(field_index)
            if isinstance(value, QDateTime):
                temporal_values.append(value)
            elif isinstance(value, str):
                parsed_value = QDateTime.fromString(value, Qt.DateFormat.ISODate)
                if parsed_value.isValid():
                    temporal_values.append(parsed_value)

        if not temporal_values:
            return

        # Set temporal extents in the temporal controller
        min_time = min(temporal_values).addSecs(-1)
        max_time = max(temporal_values).addSecs(1)
        temporal_controller.setTemporalExtents(QgsDateTimeRange(min_time, max_time))

        # Set frame duration using QgsInterval for 1 second
        frame_duration = QgsInterval(1)  # 1-second duration
        temporal_controller.setFrameDuration(frame_duration)
        temporal_controller.setFramesPerSecond(1.0)

        # Set navigation mode to Animated for dynamic playback
        temporal_controller.setNavigationMode(QgsTemporalNavigationObject.NavigationMode.Animated)

        action = self.iface.mainWindow().findChild(QAction, 'mActionTemporalController')
        action.trigger()

    def _identify_node_and_run_flood_analysis(self, dialog, point, event):
        """Identify the node at the selected point, retrieve node_id, and run flood analysis."""

        # Manage right click
        if event == Qt.MouseButton.RightButton:
            self._cancel_snapping_tool(dialog, None)
            return

        # Get the event point (convert point to QgsPointXY)
        event_point = self.snapper_manager.get_event_point(point=point)

        # Ensure that the snapper returned a valid result
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if not result.isValid():
            msg = "No valid snapping result. Please select a valid point."
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        # Get the snapped feature and ensure it's from the correct layer (node layer)
        snapped_feature = self.snapper_manager.get_snapped_feature(result)

        # Extract node information from the snapped feature
        node_id = snapped_feature.attribute('node_id')

        # Check that node_id is valid
        if not node_id:
            msg = "No node ID found at the snapped location."
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        # Highlight the snapped feature (like you do with the arc highlighting)
        try:
            geometry = snapped_feature.geometry()
            self.rubber_band.setToGeometry(geometry, None)
            self.rubber_band.setColor(QColor(255, 0, 0, 100))
            self.rubber_band.setWidth(5)
            self.rubber_band.show()
        except AttributeError:
            msg = "Unable to highlight the snapped node."
            tools_qgis.show_warning(msg, dialog=dialog)

        # Show the node ID in a message box
        msg = "Flood analysis will start from node ID"
        param = node_id
        tools_qgis.show_info(msg, dialog=dialog, parameter=param)
        self.selected_node_id = node_id

        # Retrieve graphClass and exploitation from the dialog or set defaults
        graph_class = self.mapzone_mng_dlg.main_tab.tabText(self.mapzone_mng_dlg.main_tab.currentIndex()).lower()

        # Run mapzones analysis function
        self._run_mapzones_analysis(graph_class, self.user_selected_exploitation)

        # Call the existing flood analysis function
        self._open_flood_analysis()

        # Clear the selection after processing
        self.layer_node.removeSelection()

        tools_qgis.disconnect_snapping(True, self.emit_point, self.vertex_marker)
        tools_qgis.disconnect_signal_selection_changed()

    def _on_dialog_closed(self):
        """Ensure snapping is deactivated and Pan tool is set when dialog closes."""
        self._clear_dynamic_module_reference()
        self._cancel_snapping_tool(self.mapzone_mng_dlg, None)
        self.iface.actionPan().trigger()

    def _clear_dynamic_module_reference(self):
        """Remove temporary tools_gw module alias for this manager instance."""
        if getattr(tools_gw, 'mapzone_manager', None) is self:
            delattr(tools_gw, 'mapzone_manager')

    def _run_mapzones_analysis(self, graph_class, exploitation):
        """Executes the mapzones analysis with only the required parameters."""

        # Convert graph_class to uppercase
        graph_class_upper = graph_class.upper()

        # Create the JSON body directly with the "parameters" key
        body = tools_gw.create_body(
            extras=(
                f'"parameters":{{"graphClass":"{graph_class_upper}", '
                f'"exploitation":"{exploitation}"}}'
            )
        )

        # Execute the procedure
        result = tools_gw.execute_procedure('gw_fct_graphanalytics_mapzones_advanced', body)

        # Check if a valid result was returned
        if not result or result.get('status') != 'Accepted':
            msg = "Failed to execute the mapzones analysis."
            tools_qgis.show_warning(msg)
        else:
            msg = "Mapzones analysis completed successfully."
            tools_qgis.show_info(msg)

        # TODO: Implement flood analysis starting from this node ID in the future

    # region config button

    def manage_config(self, dialog=None, tableview=None, *args, **kwargs):
        """ Dialog from config button """
        if dialog is None:
            dialog = self.mapzone_mng_dlg
        if self._is_readonly_mapzone(dialog):
            return

        # Get selected row
        if tableview is None:
            tableview = dialog.main_tab.currentWidget()
        selected_list = tableview.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        # Get selected mapzone data
        index = tableview.selectionModel().currentIndex()
        self.mapzone_type = self._get_mapzone_type(tableview)
        col_idx = tools_qt.get_col_index_by_col_name(tableview, f'{self.mapzone_type}_id')
        self.mapzone_id = index.sibling(index.row(), col_idx).data()
        col_idx = tools_qt.get_col_index_by_col_name(tableview, 'name')
        if col_idx is None:
            col_idx = tools_qt.get_col_index_by_col_name(tableview, f'{self.mapzone_type}_name')
        mapzone_name = index.sibling(index.row(), col_idx).data()
        col_idx = tools_qt.get_col_index_by_col_name(tableview, 'graphconfig')
        graphconfig = index.sibling(index.row(), col_idx).data()

        # Build dialog
        self.config_dlg = GwMapzoneConfigUi(self)
        tools_gw.load_settings(self.config_dlg)

        # Button icons
        tools_gw.add_icon(self.config_dlg.btn_snapping_nodeParent, "137")
        tools_gw.add_icon(self.config_dlg.btn_snapping_toArc, "137")
        tools_gw.add_icon(self.config_dlg.btn_snapping_forceClosed, "137")
        tools_gw.add_icon(self.config_dlg.btn_snapping_ignore, "137")
        tools_gw.add_icon(self.config_dlg.btn_expr_nodeParent, "178")
        tools_gw.add_icon(self.config_dlg.btn_expr_toArc, "178")
        tools_gw.add_icon(self.config_dlg.btn_expr_forceClosed, "178")
        tools_gw.add_icon(self.config_dlg.btn_expr_ignore, "178")

        # Set variables
        self._reset_config_vars()

        # Fill preview
        if graphconfig:
            tools_qt.set_widget_text(self.config_dlg, 'txt_preview', graphconfig)

        # Connect signals
        self.child_type = None
        # nodeParent
        self.config_dlg.btn_snapping_nodeParent.clicked.connect(
            partial(self.get_snapped_feature_id, self.config_dlg, self.config_dlg.btn_snapping_nodeParent,
                    've_node', 'nodeParent', None,
                    self.child_type))
        self.config_dlg.btn_expr_nodeParent.clicked.connect(
            partial(self._select_with_expression_dialog, self.config_dlg, 'nodeParent'))
        self.config_dlg.txt_nodeParent.textEdited.connect(partial(self._txt_node_parent_finished))
        # toArc
        self.config_dlg.btn_snapping_toArc.clicked.connect(
            partial(self.get_snapped_feature_id, self.config_dlg, self.config_dlg.btn_snapping_toArc, 've_arc',
                    'toArc', None,
                    self.child_type))
        self.config_dlg.btn_expr_toArc.clicked.connect(
            partial(self._select_with_expression_dialog, self.config_dlg, 'toArc'))
        self.config_dlg.btn_add_nodeParent.clicked.connect(
            partial(self._add_node_parent, self.config_dlg)
        )
        self.config_dlg.btn_remove_nodeParent.clicked.connect(
            partial(self._remove_node_parent, self.config_dlg)
        )
        # Force closed
        # Set variables based on project type
        layer = 've_node' if global_vars.project_type == 'ws' else 've_arc'

        self.config_dlg.btn_snapping_forceClosed.clicked.connect(
            partial(self.get_snapped_feature_id, self.config_dlg, self.config_dlg.btn_snapping_forceClosed,
                    layer, 'forceClosed', None,
                    self.child_type))
        self.config_dlg.btn_expr_forceClosed.clicked.connect(
            partial(self._select_with_expression_dialog, self.config_dlg, 'forceClosed'))
        self.config_dlg.btn_add_forceClosed.clicked.connect(
            partial(self._add_force_closed, self.config_dlg)
        )
        self.config_dlg.btn_remove_forceClosed.clicked.connect(
            partial(self._remove_force_closed, self.config_dlg)
        )
        # Ignore
        # Set variables based on project type
        layer = 've_node' if global_vars.project_type == 'ws' else 've_arc'

        self.config_dlg.btn_snapping_ignore.clicked.connect(
            partial(self.get_snapped_feature_id, self.config_dlg, self.config_dlg.btn_snapping_ignore,
                    layer, 'ignore', None, self.child_type))
        self.config_dlg.btn_expr_ignore.clicked.connect(
            partial(self._select_with_expression_dialog, self.config_dlg, 'ignore'))
        self.config_dlg.btn_add_ignore.clicked.connect(
            partial(self._add_ignore, self.config_dlg)
        )
        self.config_dlg.btn_remove_ignore.clicked.connect(
            partial(self._remove_ignore, self.config_dlg)
        )
        # Preview
        self.config_dlg.btn_clear_preview.clicked.connect(partial(self._clear_preview, self.config_dlg))
        # Dialog buttons
        self.config_dlg.btn_accept.clicked.connect(partial(self._accept_config, self.config_dlg))
        self.config_dlg.btn_cancel.clicked.connect(self.config_dlg.reject)
        self.config_dlg.finished.connect(partial(self._config_dlg_finished, self.config_dlg))

        # Enable/disable certain widgets
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_snapping_nodeParent, True)
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_snapping_toArc, False)
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_expr_toArc, False)
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_add_nodeParent, False)
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_remove_nodeParent, False)

        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_snapping_forceClosed, True)
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_add_forceClosed, False)
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_remove_forceClosed, False)

        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_clear_preview, True)

        # Hide widgets for UD projects
        if global_vars.project_type == 'ud':
            tools_qt.set_widget_visible(self.config_dlg, self.config_dlg.lbl_toArc, False)
            tools_qt.set_widget_visible(self.config_dlg, self.config_dlg.btn_snapping_toArc, False)
            tools_qt.set_widget_visible(self.config_dlg, self.config_dlg.btn_expr_toArc, False)
            tools_qt.set_widget_visible(self.config_dlg, self.config_dlg.txt_toArc, False)

        # Open dialog
        title = "Mapzone config - {0}"
        title_params = (mapzone_name,)
        if self.netscenario_id is not None:
            title = "Mapzone config - {0} (Netscenario {1})"
            title_params = (mapzone_name, self.netscenario_id)
        tools_gw.open_dialog(self.config_dlg, 'mapzone_config', title=title, title_params=title_params)

    def _config_dlg_finished(self, dialog):

        self._cancel_snapping_tool(dialog, None)
        self.iface.actionPan().trigger()
        tools_gw.close_dialog(dialog)

    def _reset_config_vars(self, mode=0):
        """
        Reset config variables

            :param mode: which variables to reset {0: all, 1: nodeParent (& toArc), 2: toArc, 3: forceClosed}
        """

        if mode in (0, 1):
            self.node_parent = None
            tools_qt.set_widget_text(self.config_dlg, 'txt_nodeParent', '')
            tools_qt.set_widget_enabled(self.config_dlg, 'btn_snapping_toArc', False)
            tools_qt.set_widget_enabled(self.config_dlg, 'btn_expr_toArc', False)
            tools_qt.set_widget_enabled(self.config_dlg, 'btn_add_nodeParent', False)
            tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_remove_nodeParent, False)
        if mode in (0, 1, 2):
            self.to_arc_list = set()
            tools_qt.set_widget_text(self.config_dlg, 'txt_toArc', '')
        if mode in (0, 3):
            self.force_closed_list = set()
            tools_qt.set_widget_text(self.config_dlg, 'txt_forceClosed', '')
            tools_qt.set_widget_enabled(self.config_dlg, 'btn_add_forceClosed', False)
            tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_remove_forceClosed, False)
        if mode in (0, 4):
            self.ignore_list = set()
            tools_qt.set_widget_text(self.config_dlg, 'txt_ignore', '')
            tools_qt.set_widget_enabled(self.config_dlg, 'btn_add_ignore', False)
            tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_remove_ignore, False)

    def get_snapped_feature_id(self, dialog, action, layer_name, option, widget_name, child_type):
        """ Snap feature and set a value into dialog """

        layer = tools_qgis.get_layer_by_tablename(layer_name)
        if not layer:
            action.setChecked(False)
            return

        self.vertex_marker = self.snapper_manager.vertex_marker

        # Set signals
        tools_gw.disconnect_signal('mapzone_manager_snapping', 'get_snapped_feature_id_xyCoordinates_mouse_moved')
        tools_gw.connect_signal(self.canvas.xyCoordinates, partial(self._mouse_moved, layer),
                                'mapzone_manager_snapping', 'get_snapped_feature_id_xyCoordinates_mouse_moved')

        tools_gw.disconnect_signal('mapzone_manager_snapping', 'get_snapped_feature_id_ep_canvasClicked_get_id')
        emit_point = QgsMapToolEmitPoint(self.canvas)
        self.canvas.setMapTool(emit_point)
        tools_gw.connect_signal(emit_point.canvasClicked,
                                partial(self._get_id, dialog, action, option, emit_point, child_type),
                                'mapzone_manager_snapping', 'get_snapped_feature_id_ep_canvasClicked_get_id')

    def _show_context_menu(self, qtableview):
        """ Show custom context menu """
        tab_name = self._get_mapzone_type(qtableview)
        if self._is_readonly_mapzone(tab_name):
            return
        menu = QMenu(qtableview)

        title = "Update"
        action_update = QAction(tools_qt.tr(title), qtableview)
        action_update.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_update"))
        menu.addAction(action_update)

        title = "Delete"
        action_delete = QAction(tools_qt.tr(title), qtableview)
        action_delete.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_delete"))
        menu.addAction(action_delete)

        title = "Toggle Active"
        action_toggle_active = QAction(tools_qt.tr(title), qtableview)
        action_toggle_active.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_toggle_active"))
        menu.addAction(action_toggle_active)

        title = "Config"
        action_config = QAction(tools_qt.tr(title), qtableview)
        action_config.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_config"))
        menu.addAction(action_config)

        menu.exec(QCursor.pos())

    def _mouse_moved(self, layer, point):
        """ Mouse motion detection """

        # Set active layer
        self.iface.setActiveLayer(layer)
        layer_name = tools_qgis.get_layer_source_table_name(layer)

        # Get clicked point
        self.vertex_marker.hide()
        event_point = self.snapper_manager.get_event_point(point=point)

        # Snapping
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if result.isValid():
            layer = self.snapper_manager.get_snapped_layer(result)
            # Check feature
            viewname = tools_qgis.get_layer_source_table_name(layer)
            if viewname == layer_name:
                self.snapper_manager.add_marker(result, self.vertex_marker)

    def _get_id(self, dialog, action, option, emit_point, child_type, point, event):
        """ Get selected attribute from snapped feature """

        # @options{'key':['att to get from snapped feature', 'function to call']}
        # Set ID field based on project type for forceClosed and ignore
        force_closed_id_field = 'node_id' if global_vars.project_type == 'ws' else 'arc_id'
        ignore_id_field = 'node_id' if global_vars.project_type == 'ws' else 'arc_id'

        options = {'nodeParent': ['node_id', '_set_node_parent'], 'toArc': ['arc_id', '_set_to_arc'],
                   'forceClosed': [force_closed_id_field, '_set_force_closed'], 'ignore': [ignore_id_field, '_set_ignore']}

        if event == Qt.MouseButton.RightButton:
            self._cancel_snapping_tool(dialog, action)
            return

        try:
            # Refresh all layers to avoid selecting old deleted features
            global_vars.canvas.refreshAllLayers()
            # Get coordinates
            event_point = self.snapper_manager.get_event_point(point=point)
            # Snapping
            result = self.snapper_manager.snap_to_current_layer(event_point)
            if not result.isValid():
                return
            # Get the point. Leave selection
            snapped_feat = self.snapper_manager.get_snapped_feature(result)
            feat_id = snapped_feat.attribute(f'{options[option][0]}')
            getattr(self, options[option][1])(feat_id)
        except Exception as e:
            msg = "Exception in info (def _get_id)"
            tools_qgis.show_warning(msg, parameter=e)
        finally:
            if option == 'nodeParent':
                self._cancel_snapping_tool(dialog, action)

    def _txt_node_parent_finished(self, text):
        self._set_node_parent(text, False)

    def _set_node_parent(self, feat_id, set_text=True):
        """
        Function called in def _get_id(self, dialog, action, option, point, event):
            getattr(self, options[option][1])(feat_id)

            :param feat_id: Id of the snapped feature
        """

        self.node_parent = feat_id

        if set_text:
            tools_qt.set_widget_text(self.config_dlg, 'txt_nodeParent', f"{feat_id}")
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_snapping_toArc, bool(feat_id))
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_expr_toArc, bool(feat_id))
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_remove_nodeParent, bool(feat_id))
        if global_vars.project_type == 'ud':
            tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_add_nodeParent, bool(feat_id))

        self._reset_config_vars(2 if bool(feat_id) else 1)

    def _set_to_arc(self, feat_id):
        """
        Function called in def _get_id(self, dialog, action, option, point, event):
            getattr(self, options[option][1])(feat_id)

            :param feat_id: Id of the snapped feature
        """

        # Set variable, set widget text and enable add button

        self.to_arc_list.add(feat_id)
        to_arc_list_aux = [int(to_arc) for to_arc in self.to_arc_list]
        tools_qt.set_widget_text(self.config_dlg, 'txt_toArc', f"{to_arc_list_aux}")
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_add_nodeParent, True)
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_remove_nodeParent, True)

    def _set_force_closed(self, feat_id):
        """
        Function called in def _get_id(self, dialog, action, option, point, event):
            getattr(self, options[option][1])(feat_id)

            :param feat_id: Id of the snapped feature
        """

        # Set variable, set widget text and enable add button

        self.force_closed_list.add(feat_id)
        force_closed_list_aux = [int(force_closed) for force_closed in self.force_closed_list]
        tools_qt.set_widget_text(self.config_dlg, 'txt_forceClosed', f"{force_closed_list_aux}")
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_add_forceClosed, True)
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_remove_forceClosed, True)

    def _set_ignore(self, feat_id):
        """
        Function called in def _get_id(self, dialog, action, option, point, event):
            getattr(self, options[option][1])(feat_id)

            :param feat_id: Id of the snapped feature
        """
        # Set variable, set widget text and enable add button
        self.ignore_list.add(feat_id)
        ignore_list_aux = [int(ignore) for ignore in self.ignore_list]
        tools_qt.set_widget_text(self.config_dlg, 'txt_ignore', f"{ignore_list_aux}")
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_add_ignore, True)
        tools_qt.set_widget_enabled(self.config_dlg, self.config_dlg.btn_remove_ignore, True)

    def _add_node_parent(self, dialog):
        """ ADD button for nodeParent """

        node_parent_id = self.node_parent
        to_arc_list = json.dumps(list(self.to_arc_list))
        preview = tools_qt.get_text(dialog, 'txt_preview')
        parameters = f'"action": "ADD", "configZone": "{self.mapzone_type}", "mapzoneId": "{self.mapzone_id}", ' \
                     f'"nodeParent": "{node_parent_id}", "toArc": {to_arc_list}'
        if self.netscenario_id is not None:
            parameters += f', "netscenarioId": {self.netscenario_id}'
        if preview:
            parameters += f', "config": {preview}'
        extras = f'"parameters": {{{parameters}}}'
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_config_mapzones', body)
        if json_result is None:
            return

        if 'status' in json_result and json_result['status'] == 'Accepted':
            if json_result['message']:
                level = 1
                if 'level' in json_result['message']:
                    level = int(json_result['message']['level'])
                    msg = json_result['message']['text']
                level = Qgis.MessageLevel(level)
                tools_qgis.show_message(msg, level, dialog=dialog)

            preview = json_result['body']['data'].get('preview')
            if preview:
                tools_qt.set_widget_text(dialog, 'txt_preview', json.dumps(preview))

            self._cancel_snapping_tool(dialog, dialog.btn_add_nodeParent)
            self._reset_config_vars(1)

    def _remove_node_parent(self, dialog):
        """ REMOVE button for nodeParent """

        node_parent_id = self.node_parent
        preview = tools_qt.get_text(dialog, 'txt_preview')

        parameters = f'"action": "REMOVE", "configZone": "{self.mapzone_type}", "mapzoneId": "{self.mapzone_id}", ' \
                     f'"nodeParent": "{node_parent_id}"'
        if self.netscenario_id is not None:
            parameters += f', "netscenarioId": {self.netscenario_id}'
        if preview:
            parameters += f', "config": {preview}'
        extras = f'"parameters": {{{parameters}}}'
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_config_mapzones', body)
        if json_result is None:
            return

        if 'status' in json_result and json_result['status'] == 'Accepted':
            if json_result['message']:
                level = 1
                if 'level' in json_result['message']:
                    level = int(json_result['message']['level'])
                    msg = json_result['message']['text']
                level = Qgis.MessageLevel(level)
                tools_qgis.show_message(msg, level, dialog=dialog)

            preview = json_result['body']['data'].get('preview')
            if preview:
                tools_qt.set_widget_text(dialog, 'txt_preview', json.dumps(preview))

            self._cancel_snapping_tool(dialog, dialog.btn_remove_nodeParent)
            self._reset_config_vars(1)

    def _add_force_closed(self, dialog):
        """ ADD button for forceClosed """

        force_closed_list = json.dumps(list(self.force_closed_list))
        preview = tools_qt.get_text(dialog, 'txt_preview')

        parameters = f'"action": "ADD", "configZone": "{self.mapzone_type}", "mapzoneId": "{self.mapzone_id}", ' \
                     f'"forceClosed": {force_closed_list}'
        if self.netscenario_id is not None:
            parameters += f', "netscenarioId": {self.netscenario_id}'
        if preview:
            parameters += f', "config": {preview}'
        extras = f'"parameters": {{{parameters}}}'
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_config_mapzones', body)
        if json_result is None:
            return

        if 'status' in json_result and json_result['status'] == 'Accepted':
            if json_result['message']:
                level = 1
                if 'level' in json_result['message']:
                    level = int(json_result['message']['level'])
                    msg = json_result['message']['text']
                level = Qgis.MessageLevel(level)
                tools_qgis.show_message(msg, level, dialog=dialog)

            preview = json_result['body']['data'].get('preview')
            if preview:
                tools_qt.set_widget_text(dialog, 'txt_preview', json.dumps(preview))

            self._cancel_snapping_tool(dialog, dialog.btn_add_forceClosed)
            self._reset_config_vars(3)

    def _remove_force_closed(self, dialog):
        """ ADD button for forceClosed """

        force_closed_list = json.dumps(list(self.force_closed_list))
        preview = tools_qt.get_text(dialog, 'txt_preview')

        parameters = f'"action": "REMOVE", "configZone": "{self.mapzone_type}", "mapzoneId": "{self.mapzone_id}", ' \
                     f'"forceClosed": {force_closed_list}'
        if self.netscenario_id is not None:
            parameters += f', "netscenarioId": {self.netscenario_id}'
        if preview:
            parameters += f', "config": {preview}'
        extras = f'"parameters": {{{parameters}}}'
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_config_mapzones', body)
        if json_result is None:
            return

        if 'status' in json_result and json_result['status'] == 'Accepted':
            if json_result['message']:
                level = 1
                if 'level' in json_result['message']:
                    level = int(json_result['message']['level'])
                    msg = json_result['message']['text']
                level = Qgis.MessageLevel(level)
                tools_qgis.show_message(msg, level, dialog=dialog)

            preview = json_result['body']['data'].get('preview')
            if preview:
                tools_qt.set_widget_text(dialog, 'txt_preview', json.dumps(preview))

            self._cancel_snapping_tool(dialog, dialog.btn_add_forceClosed)
            self._reset_config_vars(3)

    def _add_ignore(self, dialog):
        """ ADD button for ignore """

        ignore_list = json.dumps(list(self.ignore_list))
        preview = tools_qt.get_text(dialog, 'txt_preview')

        parameters = f'"action": "ADD", "configZone": "{self.mapzone_type}", "mapzoneId": "{self.mapzone_id}", ' \
                     f'"ignore": {ignore_list}'
        if self.netscenario_id is not None:
            parameters += f', "netscenarioId": {self.netscenario_id}'
        if preview:
            parameters += f', "config": {preview}'
        extras = f'"parameters": {{{parameters}}}'
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_config_mapzones', body)
        if json_result is None:
            return

        if 'status' in json_result and json_result['status'] == 'Accepted':
            if json_result['message']:
                level = 1
                if 'level' in json_result['message']:
                    level = int(json_result['message']['level'])
                    msg = json_result['message']['text']
                level = Qgis.MessageLevel(level)
                tools_qgis.show_message(msg, level, dialog=dialog)

            preview = json_result['body']['data'].get('preview')
            if preview:
                tools_qt.set_widget_text(dialog, 'txt_preview', json.dumps(preview))

            self._cancel_snapping_tool(dialog, dialog.btn_add_ignore)
            self._reset_config_vars(4)

    def _remove_ignore(self, dialog):
        """ REMOVE button for ignore """

        ignore_list = json.dumps(list(self.ignore_list))
        preview = tools_qt.get_text(dialog, 'txt_preview')

        parameters = f'"action": "REMOVE", "configZone": "{self.mapzone_type}", "mapzoneId": "{self.mapzone_id}", ' \
                     f'"ignore": {ignore_list}'
        if self.netscenario_id is not None:
            parameters += f', "netscenarioId": {self.netscenario_id}'
        if preview:
            parameters += f', "config": {preview}'
        extras = f'"parameters": {{{parameters}}}'
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_config_mapzones', body)
        if json_result is None:
            return

        if 'status' in json_result and json_result['status'] == 'Accepted':
            if json_result['message']:
                level = 1
                if 'level' in json_result['message']:
                    level = int(json_result['message']['level'])
                    msg = json_result['message']['text']
                level = Qgis.MessageLevel(level)
                tools_qgis.show_message(msg, level, dialog=dialog)

            preview = json_result['body']['data'].get('preview')
            if preview:
                tools_qt.set_widget_text(dialog, 'txt_preview', json.dumps(preview))

            self._cancel_snapping_tool(dialog, dialog.btn_remove_ignore)
            self._reset_config_vars(4)

    def _clear_preview(self, dialog):
        """ Set preview textbox to '' """

        tools_qt.set_widget_text(dialog, 'txt_preview', '')

    def _accept_config(self, dialog):
        """ Accept button for config dialog """

        preview = tools_qt.get_text(dialog, 'txt_preview')

        if not preview:
            return
        parameters = f'"action": "UPDATE", "configZone": "{self.mapzone_type}", "mapzoneId": "{self.mapzone_id}", ' \
                     f'"config": {preview}'
        if self.netscenario_id is not None:
            parameters += f', "netscenarioId": {self.netscenario_id}'
        extras = f'"parameters": {{{parameters}}}'
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_config_mapzones', body)
        if not json_result or 'status' not in json_result:
            msg = "Failed to get a valid response from gw_fct_config_mapzones."
            tools_qgis.show_message(msg, level=Qgis.MessageLevel.Critical)
            return

        if 'status' in json_result and json_result['status'] == 'Accepted':
            if json_result['message']:
                level = 1
                if 'level' in json_result['message']:
                    level = int(json_result['message']['level'])
                    msg = json_result['message']['text']
                level = Qgis.MessageLevel(level)
                tools_qgis.show_message(msg, level)

            if global_vars.project_type != 'ud':
                self._get_graph_config()
            self._reset_config_vars(0)
            tools_gw.close_dialog(dialog)
            self._manage_current_changed()

    def _get_graph_config(self):
        context = "OPERATIVE" if self.netscenario_id is None else "NETSCENARIO"
        extras = f'"context":"{context}", "mapzone": "{self.mapzone_type}", "mapzoneId": "{self.mapzone_id}"'
        if self.netscenario_id is not None:
            extras += f', "netscenarioId": {self.netscenario_id}'
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_getgraphconfig', body)
        if json_result is None:
            return

    def _cancel_snapping_tool(self, dialog, action):
        """Cancel snapping tool and reset the state."""

        # Disconnect snapping and signals
        tools_qgis.disconnect_snapping(False, None, self.vertex_marker)
        tools_gw.disconnect_signal('mapzone_manager_snapping')

        # Hide markers or cross cursor
        if hasattr(self, 'vertex_marker') and self.vertex_marker:
            self.vertex_marker.hide()

        # Unblock signals for dialog
        dialog.blockSignals(False)
        if action:
            action.setChecked(False)

        # self.signal_activate.emit()

    def _select_with_expression_dialog(self, dialog, option):
        """Select features by expression for mapzone config"""

        # Get current layer and feature type
        layer_name = 've_node'  # Default to node layer
        if option == 'toArc':
            layer_name = 've_arc'
        self.feature_type = layer_name.split('_')[-1]
        layer = tools_qgis.get_layer_by_tablename(layer_name)
        if not layer:
            return

        # Set active layer
        self.iface.setActiveLayer(layer)
        tools_qgis.set_layer_visible(layer)

        # Show expression dialog
        tools_gw.select_with_expression_dialog_custom(
            self,
            dialog,
            None,  # No table object needed for expression selection
            layer_name,
            self._selection_init,
            partial(self._selection_end, option)
        )

    def _selection_init(self):
        """Initialize selection mode"""
        self.iface.actionSelect().trigger()

    def _selection_end(self, option):
        """Process selected features and update the corresponding line edit"""
        layer = self.iface.activeLayer()
        if not layer:
            return

        selected_features = layer.selectedFeatures()
        if not selected_features:
            return

        # Get the appropriate field name based on the option
        field_name = 'node_id'
        if option == 'toArc':
            field_name = 'arc_id'

        # Extract IDs from selected features
        selected_ids = [str(feature.attribute(field_name)) for feature in selected_features]

        # Update the appropriate line edit based on the option
        if option == 'nodeParent':
            self._set_node_parent(selected_ids[0] if selected_ids else None)
        elif option == 'toArc':
            for arc_id in selected_ids:
                self._set_to_arc(arc_id)
        elif option == 'forceClosed':
            for feat_id in selected_ids:
                self._set_force_closed(feat_id)
        elif option == 'ignore':
            for feat_id in selected_ids:
                self._set_ignore(feat_id)

        # Clean up
        tools_gw.disconnect_signal('mapzone_manager_snapping')
        tools_gw.remove_selection()
        tools_gw.reset_rubberband(self.rubber_band)
        self.iface.actionPan().trigger()

    def _manage_toggle_active(self, *args, **kwargs):
        if self._is_readonly_mapzone():
            return
        # Get selected row
        tableview = self.mapzone_mng_dlg.main_tab.currentWidget()
        view = self._get_mapzone_edit_view()
        selected_list = tableview.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.mapzone_mng_dlg)
            return

        # Get selected mapzone data
        for index in selected_list:
            mapzone_id = index.sibling(index.row(), 0).data()
            active = index.sibling(index.row(), tools_qt.get_col_index_by_col_name(tableview, 'active')).data()
            active = tools_os.set_boolean(active)
            field_id = tableview.model().headerData(0, Qt.Orientation.Horizontal)

            sql = f"UPDATE {view} SET active = {str(not active).lower()} WHERE {field_id}::text = '{mapzone_id}'"
            tools_db.execute_sql(sql)

        # Refresh tableview
        self._manage_current_changed(clear_text=False)

    def manage_create(self, dialog=None, tableview=None, on_close=None, *args, **kwargs):
        if dialog is None:
            dialog = self.mapzone_mng_dlg
        if self._is_readonly_mapzone(dialog):
            return
        if tableview is None:
            tableview = dialog.main_tab.currentWidget()
        mapzone_type = self._get_mapzone_type(tableview)
        if not mapzone_type:
            return
        tablename = self._get_mapzone_edit_view(mapzone_type)
        if not tablename:
            return

        col_name = f"{mapzone_type}_id"
        col_idx = tools_qt.get_col_index_by_col_name(tableview, col_name)
        if col_idx in (None, False):
            field_id = tableview.model().headerData(0, Qt.Orientation.Horizontal)
        else:
            field_id = tableview.model().headerData(col_idx, Qt.Orientation.Horizontal)
        if field_id:
            field_id = str(field_id).lower()

        # Execute getinfofromid
        feature = f'"tableName":"{tablename}"'
        body = tools_gw.create_body(feature=feature)
        json_result = tools_gw.execute_procedure('gw_fct_getinfofromid', body)
        if json_result is None or json_result['status'] == 'Failed':
            return
        result = json_result

        title = "New {0}"
        title_params = (mapzone_type.capitalize(),)
        dlg_title = tools_qt.tr(title, list_params=title_params)

        self._build_generic_info(dlg_title, result, tablename, field_id, force_action="INSERT", on_close=on_close)

    def manage_update(self, dialog=None, tableview=None, on_close=None, *args, **kwargs):
        if dialog is None:
            dialog = self.mapzone_mng_dlg
        if self._is_readonly_mapzone(dialog):
            return
        # Get selected row
        if tableview is None:
            tableview = dialog.main_tab.currentWidget()
        mapzone_type = self._get_mapzone_type(tableview)
        tablename = self._get_mapzone_edit_view(mapzone_type)
        selected_list = tableview.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        # Get selected mapzone data
        index = tableview.selectionModel().currentIndex()
        col_name = f"{mapzone_type}_id"
        if col_name == 'valve_id':
            col_name = 'node_id'
        col_idx = tools_qt.get_col_index_by_col_name(tableview, col_name)

        mapzone_id = index.sibling(index.row(), col_idx).data()
        field_id = tableview.model().headerData(col_idx, Qt.Orientation.Horizontal).lower()

        # Execute getinfofromid
        _id = f"{mapzone_id}"
        if self.netscenario_id is not None:
            _id = f"{self.netscenario_id}, {mapzone_id}"
        feature = f'"tableName":"{tablename}", "id": "{_id}"'
        body = tools_gw.create_body(feature=feature)
        json_result = tools_gw.execute_procedure('gw_fct_getinfofromid', body)
        if json_result is None or json_result['status'] == 'Failed':
            return
        result = json_result

        title = "Update {0} ({1})"
        title_params = (mapzone_type.capitalize(), mapzone_id)
        dlg_title = tools_qt.tr(title, list_params=title_params)

        self._build_generic_info(dlg_title, result, tablename, field_id, force_action="UPDATE", on_close=on_close)

    def _manage_delete(self, *args, **kwargs):
        if self._is_readonly_mapzone(self.mapzone_mng_dlg):
            return
        # Get selected row
        tableview = self.mapzone_mng_dlg.main_tab.currentWidget()
        view = self._get_mapzone_edit_view()
        selected_list = tableview.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.mapzone_mng_dlg)
            return

        # Get selected mapzone data
        field_id = tableview.model().headerData(0, Qt.Orientation.Horizontal)
        mapzone_ids = [index.sibling(index.row(), 0).data() for index in selected_list]

        record_labels = []
        for index in selected_list:
            mapzone_id = index.sibling(index.row(), 0).data()
            mapzone_name = index.sibling(index.row(), 1).data()
            label = mapzone_name if mapzone_name not in (None, "", "NULL") else str(mapzone_id)
            record_labels.append(label)

        msg = "Are you sure you want to delete these records?"
        title = "Delete records"
        answer = tools_qt.show_question(msg, title, record_labels, force_action=True)
        if answer:
            # Build WHERE IN clause for SQL
            where_clause = f"{field_id} IN ({', '.join(map(str, mapzone_ids))})"

            # Construct SQL DELETE statement
            sql = f"DELETE FROM {view} WHERE {where_clause}"
            tools_db.execute_sql(sql)

            # Refresh tableview
            self._manage_current_changed()

    def _build_generic_info(self, dlg_title, result, tablename, field_id, force_action=None, on_close=None):
        # Build dlg

        self.add_dlg = GwInfoGenericUi(self)
        tools_gw.load_settings(self.add_dlg)
        self.my_json_add = {}

        # Aplicar la lògica de posicions millorada
        layout_positions = {}

        # Ordenar els camps per layoutorder abans de construir el diàleg
        if 'body' in result and 'data' in result['body'] and 'fields' in result['body']['data']:
            sorted_fields = sorted(result['body']['data']['fields'],
                                    key=lambda x: x.get('layoutorder', 0))
            result['body']['data']['fields'] = sorted_fields

        # Construir el diàleg amb la versió millorada
        tools_gw.build_dialog_info(self.add_dlg, result, my_json=self.my_json_add, layout_positions=layout_positions, tab_name='tab_none')

        layout = self.add_dlg.findChild(QGridLayout, 'lyt_main_1')
        self.add_dlg.actionEdit.setVisible(False)

        # Disable widgets if updating
        if force_action == "UPDATE":
            tools_qt.set_widget_enabled(self.add_dlg, f'tab_none_{field_id}', False)

        # Populate netscenario_id
        if self.netscenario_id is not None:
            tools_qt.set_widget_text(self.add_dlg, 'tab_none_netscenario_id', self.netscenario_id)
            tools_qt.set_widget_enabled(self.add_dlg, 'tab_none_netscenario_id', False)
            tools_qt.set_checked(self.add_dlg, 'tab_none_active', True)
            field_id = ['netscenario_id', field_id]

        # Get every widget in the layout
        widgets = []
        for row in range(layout.rowCount()):
            for column in range(layout.columnCount()):
                item = layout.itemAtPosition(row, column)
                if item is not None:
                    widget = item.widget()
                    if widget is not None and not isinstance(widget, QLabel):
                        widgets.append(widget)

        # Get all widget's values
        for widget in widgets:
            object_name = widget.objectName()
            tools_gw.get_values(self.add_dlg, widget, self.my_json_add, ignore_editability=True)

            if object_name == 'tab_none_created_at':
                value = widget.text()
                if value is not None and 'T' in value and '.' in value:
                    widget.setText(value.split('.')[0].replace('T', ' - ') + '.' + value.split('.')[1][0:2])
            if object_name == 'tab_none_updated_at':
                value = widget.text()
                if value is not None and 'T' in value and '.' in value:
                    widget.setText(value.split('.')[0].replace('T', ' - ') + '.' + value.split('.')[1][0:2])

        # Remove Nones from self.my_json_add
        keys_to_remove = []
        for key, value in self.my_json_add.items():
            if value is None:
                keys_to_remove.append(key)
        for key in keys_to_remove:
            del self.my_json_add[key]

        # Signals
        self.add_dlg.btn_close.clicked.connect(partial(tools_gw.close_dialog, self.add_dlg))
        self.add_dlg.dlg_closed.connect(partial(tools_gw.close_dialog, self.add_dlg))
        self.add_dlg.dlg_closed.connect(self._manage_current_changed)
        if on_close:
            self.add_dlg.dlg_closed.connect(on_close)
        self.add_dlg.btn_accept.clicked.connect(
            partial(self._accept_add_dlg, self.add_dlg, tablename, field_id, None, self.my_json_add, result, force_action, on_close))

        # Open dlg
        tools_gw.open_dialog(self.add_dlg, dlg_name='info_generic', title=dlg_title)

    def _accept_add_dlg(self, dialog, tablename, pkey, feature_id, my_json, complet_result, force_action, on_close=None):

        if not my_json:
            return

        list_mandatory = []
        list_filter = []

        for field in complet_result['body']['data']['fields']:
            if field['ismandatory']:
                if field['widgettype'] == 'multiple_option':
                    widget = dialog.findChild(QWidget, field['widgetname'])
                    if widget:
                        widget = widget.findChild(QListWidget, field['widgetname'])
                else:
                    widget = dialog.findChild(QWidget, field['widgetname'])
                if widget is None:
                    continue
                widget.setStyleSheet(None)
                value = tools_qt.get_widget_value(dialog, widget)
                if value in ('null', None, '', []):
                    widget.setStyleSheet("border: 1px solid red")
                    list_mandatory.append(field['widgetname'])
                else:
                    elem = [field['columnname'], value]
                    list_filter.append(elem)

        if list_mandatory:
            msg = "Some mandatory values are missing. Please check the widgets marked in red."
            tools_qgis.show_warning(msg, dialog=dialog)
            tools_qt.set_action_checked("actionEdit", True, dialog)
            return False

        fields = json.dumps(my_json)
        id_val = ""
        if pkey:
            if not isinstance(pkey, list):
                pkey = [pkey]
            for pk in pkey:
                results = pk.split(',')
                for result in results:
                    widget_name = f"tab_none_{result}"
                    value = tools_qt.get_widget_value(dialog, widget_name)
                    id_val += f"{value}, "
            id_val = id_val[:-2]
        # if id_val in (None, '', 'None'):
        #     id_val = feature_id
        feature = f'"id":"{id_val}", '
        feature += f'"tableName":"{tablename}"'
        extras = f'"fields":{fields}'
        if force_action:
            extras += f', "force_action":"{force_action}"'
        body = tools_gw.create_body(feature=feature, extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_upsertfields', body)
        if json_result and json_result.get('status') == 'Accepted':
            tools_gw.close_dialog(dialog)
            if on_close:
                on_close()
            return

        msg = "Error"
        tools_qgis.show_warning(msg, parameter=json_result, dialog=dialog)

    def _restore_last_tab(self):
        """Restores the last active tab for the current project type."""
        try:
            # Get the last active tab from configuration using existing tools_gw functions
            dlg_name = self.mapzone_mng_dlg.objectName()
            last_active_tab_name = tools_gw.get_config_parser('dialogs_tab', f"{dlg_name}_mapzone_manager", 'user', 'session')

            if last_active_tab_name:
                # Find the tab index by name
                for i in range(self.mapzone_mng_dlg.main_tab.count()):
                    if self.mapzone_mng_dlg.main_tab.widget(i).objectName() == last_active_tab_name:
                        self.mapzone_mng_dlg.main_tab.setCurrentIndex(i)
                        # Refresh table data after restoring tab
                        self._manage_current_changed()
                        break
        except Exception:
            pass

    def _restore_show_inactive_state(self):
        """ Restores the show inactive checkbox state """

        show_inactive = tools_gw.get_config_parser("dialogs", "mapzone_manager_show_inactive", "user", "session")
        if show_inactive is not None:
            is_checked = tools_os.set_boolean(show_inactive, default=False)
            self.mapzone_mng_dlg.chk_active.setChecked(is_checked)

    def _save_show_inactive_state(self):
        """ Saves the current show inactive checkbox state """

        is_checked = self.mapzone_mng_dlg.chk_active.isChecked()
        tools_gw.set_config_parser("dialogs", "mapzone_manager_show_inactive", str(is_checked), "user", "session")

    def _restore_filter_selector_state(self):
        """Restore filter-by-selector checkbox from last session choice."""

        chk = getattr(self.mapzone_mng_dlg, 'chk_filter_selector', None)
        if chk is None or isdeleted(chk):
            return

        filter_selector = tools_gw.get_config_parser(
            "dialogs", "mapzone_manager_filter_selector", "user", "session")
        if filter_selector is not None:
            chk.setChecked(tools_os.set_boolean(filter_selector, default=True))

    def _save_filter_selector_state(self):
        """Persist filter-by-selector checkbox state for next dialog open."""

        chk = getattr(self.mapzone_mng_dlg, 'chk_filter_selector', None)
        if chk is None or isdeleted(chk):
            return

        tools_gw.set_config_parser(
            "dialogs",
            "mapzone_manager_filter_selector",
            str(chk.isChecked()),
            "user",
            "session",
        )
