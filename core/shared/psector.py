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
import re
import sys
from typing import Union, Optional
from collections import OrderedDict
from functools import partial
from qgis.PyQt.sip import isdeleted

from qgis.PyQt.QtCore import Qt, QItemSelectionModel
from qgis.PyQt.QtGui import QIntValidator, QKeySequence, QColor, QCursor, QStandardItemModel, QPixmap
from qgis.PyQt.QtSql import QSqlTableModel, QSqlRecord
from qgis.PyQt.QtWidgets import QAbstractItemView, QAction, QCheckBox, QComboBox, QDateEdit, QLabel, \
    QLineEdit, QTableView, QWidget, QDoubleSpinBox, QTextEdit, QPushButton, QGridLayout, QMenu, QHeaderView
from qgis.core import QgsLayoutExporter, QgsProject, QgsRectangle, QgsPointXY, QgsGeometry, QgsMapLayer, Qgis, \
    QgsLayoutItemLabel
from qgis.gui import QgsMapToolEmitPoint, QgsDateTimeEdit

from .document import GwDocument, global_vars
from ..toolbars.utilities.toolbox_btn import GwToolBoxButton
from ..shared.psector_duplicate import GwPsectorDuplicate
from ..ui.ui_manager import GwPsectorUi, GwPsectorRapportUi, GwPsectorManagerUi, GwPsectorRepairUi
from ..utils import tools_gw
from ...libs import lib_vars, tools_db, tools_qgis, tools_qt, tools_log, tools_os
from ...global_vars import GwFeatureTypes
from ..utils.selection_mode import GwSelectionMode
from ..utils.selection_widget import GwSelectionWidget


class GwPsector:

    OPERATIVE_COLOR = QColor(255, 144, 2, 125)
    OBSOLETE_COLOR = QColor(140, 197, 229, 200)

    def __init__(self):
        """ Class to control 'New Psector' of toolbar 'master' """

        self.iface = global_vars.iface
        self.canvas = global_vars.canvas
        self.schema_name = lib_vars.schema_name
        self.rubber_band_point = tools_gw.create_rubberband(self.canvas)
        self.rubber_band_line = tools_gw.create_rubberband(self.canvas)
        self.rubber_band_rectangle = tools_gw.create_rubberband(self.canvas)
        self.rubber_band_op = tools_gw.create_rubberband(self.canvas)
        self.emit_point = None
        self.vertex_marker = None
        self.dict_to_update = {}
        self.my_json = {}
        self.feature_geoms = {}
        self.tablename_psector_x_arc = "plan_psector_x_arc"
        self.tablename_psector_x_node = "plan_psector_x_node"
        self.tablename_psector_x_connec = "plan_psector_x_connec"
        self.tablename_psector_x_gully = "plan_psector_x_gully"
        self.no_editable_fields = ['state', 'psector_id', 'link_id', 'arc_id', 'node_id', 'connec_id',
                                'gully_id', 'id', '_link_geom_', '_userdefined_geom_', 'insert_user', 'insert_tstamp']

        self.qtbl_node = None
        self.qtbl_arc = None
        self.qtbl_connec = None
        self.qtbl_gully = None

        self.previous_map_tool = self.canvas.mapTool()
        self.project_type = tools_gw.get_project_type()
        # Initialize icon folder and pixmaps lazily when needed
        self.icon_folder = None
        self.psector_with_current = None
        self.psector_without_current = None

        # Initialize variable to control editability of psector form
        self.psector_editable = False

    def get_psector(self, psector_id=None, list_coord=None):
        """ Buttons 51 and 52: New psector """

        self.sys_currency = OrderedDict([("symbol", "$"), ("separator", ","), ("decimals", True)])
        row = tools_gw.get_config_value(parameter='admin_currency', columns='value::text', table='v_config_param_system')
        if row:
            try:
                self.sys_currency = json.loads(row[0], object_pairs_hook=OrderedDict)
            except (TypeError, ValueError):
                pass

        # Create the dialog and signals
        self.dlg_plan_psector = GwPsectorUi(self)
        tools_gw.load_settings(self.dlg_plan_psector)

        # Manage btn toggle
        self._manage_btn_toggle(self.dlg_plan_psector)

        widget_list = self.dlg_plan_psector.findChildren(QTableView)
        for widget in widget_list:
            tools_qt.set_tableview_config(widget)

        # Get layers of every feature_type
        self.list_elemets = {}
        self.dict_to_update = {}

        # Get layers of every feature_type

        # Setting lists
        self.rel_ids = []
        self.rel_list_ids = {}
        self.rel_list_ids['arc'] = []
        self.rel_list_ids['node'] = []
        self.rel_list_ids['connec'] = []
        self.rel_list_ids['gully'] = []
        self.rel_list_ids['element'] = []

        # Setting layers
        self.rel_layers = {}
        self.rel_layers['gully'] = []
        self.rel_layers['element'] = []
        self.rel_layers['arc'] = tools_gw.get_layers_from_feature_type('arc')
        self.rel_layers['node'] = tools_gw.get_layers_from_feature_type('node')
        self.rel_layers['connec'] = tools_gw.get_layers_from_feature_type('connec')
        if self.project_type.upper() == 'UD':
            self.rel_layers['gully'] = tools_gw.get_layers_from_feature_type('gully')
        else:
            tools_qt.remove_tab(self.dlg_plan_psector.tab_feature, 'tab_gully')

        self.update = False  # if false: insert; if true: update

        self.rel_feature_type = "arc"

        # Remove all previous selections
        self.rel_layers = tools_gw.remove_selection(True, layers=self.rel_layers)

        # Set icons
        tools_gw.add_icon(self.dlg_plan_psector.btn_insert, "111")
        tools_gw.add_icon(self.dlg_plan_psector.btn_delete, "112")
        tools_gw.add_icon(self.dlg_plan_psector.btn_toggle, "101")
        tools_gw.add_icon(self.dlg_plan_psector.btn_doc_insert, "111")
        tools_gw.add_icon(self.dlg_plan_psector.btn_doc_delete, "112")
        tools_gw.add_icon(self.dlg_plan_psector.btn_doc_new, "117")
        tools_gw.add_icon(self.dlg_plan_psector.btn_open_doc, "170")

        table_object = "psector"

        # tab Additional info
        num_value = self.dlg_plan_psector.findChild(QLineEdit, "num_value")
        num_value.setValidator(QIntValidator())

        # Manage other_price tab variables
        self.price_loaded = False
        self.header_exist = None
        self.load_signals = False
        self._relations_tab_feature_initialized = False
        self._selection_widget_loaded = False
        self._doc_completer_loaded = False

        # tab Bugdet
        gexpenses = self.dlg_plan_psector.findChild(QLineEdit, "gexpenses")
        tools_qt.double_validator(gexpenses, min_=0)
        vat = self.dlg_plan_psector.findChild(QLineEdit, "vat")
        tools_qt.double_validator(vat, min_=0)
        other = self.dlg_plan_psector.findChild(QLineEdit, "other")
        tools_qt.double_validator(other, min_=0)

        # Tables
        # tab Elements
        self.qtbl_arc: QTableView = self.dlg_plan_psector.findChild(QTableView, "tbl_psector_x_arc")
        self.qtbl_arc.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.qtbl_node: QTableView = self.dlg_plan_psector.findChild(QTableView, "tbl_psector_x_node")
        self.qtbl_node.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.qtbl_connec: QTableView = self.dlg_plan_psector.findChild(QTableView, "tbl_psector_x_connec")
        self.qtbl_connec.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        if self.project_type.upper() == 'UD':
            self.qtbl_gully: QTableView = self.dlg_plan_psector.findChild(QTableView, "tbl_psector_x_gully")
            self.qtbl_gully.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        all_rows = self.dlg_plan_psector.findChild(QTableView, "all_rows")
        all_rows.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        all_rows.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.ResizeToContents)

        # if a row is selected from mg_psector_mangement(button 62 or button 61)
        # if psector_id contains "1" or "0" python takes it as boolean, if it is True, it means that it does not
        # contain a value and therefore it is a new one. We convert that value to 0 since no id will be 0 in this way
        # if psector_id has a value other than 0, it is that the sector already exists and we want to do an update.
        if isinstance(psector_id, bool):
            psector_id = 0

        # tab 'Document'
        self.doc_id = self.dlg_plan_psector.findChild(QLineEdit, "doc_id")
        self.tbl_document = self.dlg_plan_psector.findChild(QTableView, "tbl_document")

        # Fill tables tbl_arc_plan, tbl_node_plan, tbl_v_plan/om_other_x_psector with selected filter

        expr = " psector_id = " + str(psector_id)

        # tbl_psector_x_arc
        self.fill_table(self.dlg_plan_psector, self.qtbl_arc, self.tablename_psector_x_arc,
                        set_edit_triggers=QTableView.EditTrigger.DoubleClicked, expr=expr, feature_type="arc", field_id="arc_id")
        tools_gw.set_tablemodel_config(self.dlg_plan_psector, self.qtbl_arc, self.tablename_psector_x_arc)
        self.qtbl_arc.setProperty('tablename', self.tablename_psector_x_arc)
        self.qtbl_arc.model().flags = lambda index: self.flags(index, self.qtbl_arc.model())

        self._manage_selection_changed_signals(GwFeatureTypes.ARC)

        # tbl_psector_x_node
        self.fill_table(self.dlg_plan_psector, self.qtbl_node, self.tablename_psector_x_node,
                        set_edit_triggers=QTableView.EditTrigger.DoubleClicked, expr=expr, feature_type="node", field_id="node_id")
        tools_gw.set_tablemodel_config(self.dlg_plan_psector, self.qtbl_node, self.tablename_psector_x_node)
        self.qtbl_node.setProperty('tablename', self.tablename_psector_x_node)
        self.qtbl_node.model().flags = lambda index: self.flags(index, self.qtbl_node.model())

        self._manage_selection_changed_signals(GwFeatureTypes.NODE)

        # tbl_psector_x_connec
        self.fill_table(self.dlg_plan_psector, self.qtbl_connec, self.tablename_psector_x_connec,
                        set_edit_triggers=QTableView.EditTrigger.DoubleClicked, expr=expr, feature_type="connec", field_id="connec_id")
        tools_gw.set_tablemodel_config(self.dlg_plan_psector, self.qtbl_connec, self.tablename_psector_x_connec)
        self.qtbl_connec.setProperty('tablename', self.tablename_psector_x_connec)
        self.qtbl_connec.model().flags = lambda index: self.flags(index, self.qtbl_connec.model(), table_specific_editable=['arc_id'])

        self._manage_selection_changed_signals(GwFeatureTypes.CONNEC)

        # tbl_psector_x_gully
        if self.project_type.upper() == 'UD':
            self.fill_table(self.dlg_plan_psector, self.qtbl_gully, self.tablename_psector_x_gully,
                            set_edit_triggers=QTableView.EditTrigger.DoubleClicked, expr=expr, feature_type="gully", field_id="gully_id")
            tools_gw.set_tablemodel_config(self.dlg_plan_psector, self.qtbl_gully, self.tablename_psector_x_gully)
            self.qtbl_gully.setProperty('tablename', self.tablename_psector_x_gully)
            self.qtbl_gully.model().flags = lambda index: self.flags(index, self.qtbl_gully.model())

            self._manage_selection_changed_signals(GwFeatureTypes.GULLY)

        self.set_tabs_enabled(psector_id is not None)
        self.enable_buttons(psector_id is not None)

        if psector_id is not None:
            # Load existing psector data and populate form
            self.load_psector(self.dlg_plan_psector, psector_id, list_coord=None, form_opened=True)

        # Exclude the layer ve_element for adding relations
        self.excluded_layers = ['ve_element']

        # Set signals
        self.excluded_layers_tab_feature = ["ve_arc", "ve_node", "ve_connec", "ve_element", "ve_gully",
                           "ve_element"]
        layers_visibility = tools_gw.get_parent_layers_visibility()
        self.dlg_plan_psector.rejected.connect(partial(tools_gw.restore_parent_layers_visibility, layers_visibility))
        kwargs = {"class": self}
        self.dlg_plan_psector.rejected.connect(partial(close_dlg, **kwargs))
        self.dlg_plan_psector.tabwidget.currentChanged.connect(partial(self.check_tab_position))
        self.dlg_plan_psector.tabwidget.currentChanged.connect(partial(self._reset_snapping))

        if hasattr(self, 'dlg_psector_mng'):
            self.dlg_plan_psector.rejected.connect(partial(self._filter_table, self.dlg_psector_mng, self.qtbl_psm, self.dlg_psector_mng.txt_name, self.dlg_psector_mng.chk_active, self.dlg_psector_mng.chk_archived, 'v_ui_plan_psector'))

        self.lbl_descript = self.dlg_plan_psector.findChild(QLabel, "lbl_descript")
        self.dlg_plan_psector.all_rows.clicked.connect(partial(self.show_description))

        self.dlg_plan_psector.btn_delete.setShortcut(QKeySequence(Qt.Key.Key_Delete))

        # Reset snapping when any button is clicked
        for button in self.dlg_plan_psector.findChildren(QPushButton):
            button.clicked.connect(partial(self._reset_snapping))

        self.dlg_plan_psector.btn_insert.clicked.connect(
            partial(tools_gw.insert_feature, self, self.dlg_plan_psector, table_object, GwSelectionMode.PSECTOR, True, None, None))
        self.dlg_plan_psector.btn_delete.clicked.connect(
            partial(tools_gw.delete_records, self, self.dlg_plan_psector, table_object, GwSelectionMode.PSECTOR, None, None, "state"))
        self.dlg_plan_psector.btn_delete.clicked.connect(
            partial(tools_gw.set_model_signals, self))
        self.dlg_plan_psector.btn_reports.clicked.connect(partial(self.open_dlg_reports))
        self.dlg_plan_psector.tab_feature.currentChanged.connect(
            partial(tools_gw.get_signal_change_tab, self.dlg_plan_psector, self.excluded_layers_tab_feature, view_prefix='vf_'))
        self.dlg_plan_psector.tab_feature.currentChanged.connect(
            partial(tools_qgis.disconnect_snapping, False, self.emit_point, self.vertex_marker))
        self.dlg_plan_psector.tab_feature.currentChanged.connect(
            partial(self._manage_tab_feature_buttons))

        self.dlg_plan_psector.gexpenses.editingFinished.connect(partial(self.calculate_percents, 'plan_psector', 'gexpenses'))
        self.dlg_plan_psector.vat.editingFinished.connect(partial(self.calculate_percents, 'plan_psector', 'vat'))
        self.dlg_plan_psector.other.editingFinished.connect(partial(self.calculate_percents, 'plan_psector', 'other'))

        self.dlg_plan_psector.btn_doc_insert.clicked.connect(self.document_insert)
        self.dlg_plan_psector.btn_doc_delete.clicked.connect(partial(tools_gw.delete_selected_rows, self.tbl_document, 'doc_x_psector', 'doc_id'))
        self.dlg_plan_psector.btn_doc_new.clicked.connect(partial(self.manage_document, self.tbl_document))
        self.dlg_plan_psector.btn_open_doc.clicked.connect(partial(tools_qt.document_open, self.tbl_document, 'path'))

        if psector_id is not None:
            sql = (f"SELECT other, gexpenses, vat, active "
                   f"FROM plan_psector "
                   f"WHERE psector_id = '{psector_id}'")
            row = tools_db.get_row(sql)

            other = 0
            gexpenses = 0
            vat = 0
            active = False
            if row:
                other = float(row[0]) if row[0] is not None else 0
                gexpenses = float(row[1]) if row[1] is not None else 0
                vat = float(row[2]) if row[2] is not None else 0
                active = row[3] if row[3] is not None else False

            tools_qt.set_widget_text(self.dlg_plan_psector, self.dlg_plan_psector.other, other)
            tools_qt.set_widget_text(self.dlg_plan_psector, self.dlg_plan_psector.gexpenses, gexpenses)
            tools_qt.set_widget_text(self.dlg_plan_psector, self.dlg_plan_psector.vat, vat)
            tools_qt.set_widget_text(self.dlg_plan_psector, 'tab_general_active', active)

            currency_labels = (
                'cur_total_node', 'cur_total_arc', 'cur_total_other', 'cur_pem', 'cur_pec_pem',
                'cur_pec', 'cur_pecvat_pem', 'cur_pec_vat', 'cur_pca_pecvat', 'cur_pca'
            )
            currency_symbol = self.sys_currency.get('symbol', '')
            for label in currency_labels:
                tools_qt.set_widget_text(self.dlg_plan_psector, label, currency_symbol)

        widget_to_ignore = ('btn_accept', 'btn_cancel', 'btn_reports', 'btn_open_doc')
        restriction = ('role_basic', 'role_om', 'role_epa', 'role_om')
        self.set_restriction_by_role(self.dlg_plan_psector, widget_to_ignore, restriction)

        # Connect selectionChanged signal to select features in relations tables when selecting them on the canvas
        global_vars.canvas.selectionChanged.connect(partial(self._manage_selection_changed))

        # Open dialog
        user = tools_db.current_user
        form = {"formName": "generic", "formType": "psector"}

        if psector_id is not None:
            form["id"] = psector_id
            form["idname"] = "psector_id"
            form["tableName"] = "plan_psector"

        # db fct to get dialog
        body = {"client": {"cur_user": user}, "form": form}
        json_result = tools_gw.execute_procedure('gw_fct_get_dialog', body)

        # manage widgets
        tools_gw.manage_dlg_widgets(self, self.dlg_plan_psector, json_result)

        # set window title
        if psector_id is not None:
            psector_name = tools_qt.get_text(self.dlg_plan_psector, "tab_general_name")
            title = "Plan psector - {0} ({1})"
            msg_params = (psector_name, psector_id)
            self.dlg_plan_psector.setWindowTitle(tools_qt.tr(title, list_params=msg_params))

        # get widgets from general tab
        widget_list = self.dlg_plan_psector.tab_general.findChildren(QWidget)
        for widget in widget_list:
            if (psector_id is None and widget.objectName() != "tab_general_psector_id") or (psector_id is not None and widget.objectName() not in ("tab_general_psector_id", "tab_general_name")):
                # Set editable/readonly
                if type(widget) in (QLineEdit, QTextEdit):
                    widget.setReadOnly(False)
                elif isinstance(widget, QComboBox):
                    widget.setEnabled(True)
                widget.setStyleSheet(None)

        # get widgets from additional_info tab
        add_info_widgets = self.dlg_plan_psector.tab_additional_info.findChildren(QWidget)
        widget_list.extend(add_info_widgets)

        # fill my_json when field change
        for widget in widget_list:
            if type(widget) is QLineEdit and widget.objectName() != 'qt_spinbox_lineedit':
                widget.editingFinished.connect(partial(tools_gw.get_values, self.dlg_plan_psector, widget, self.my_json))
            elif isinstance(widget, QComboBox):
                widget.currentIndexChanged.connect(partial(tools_gw.get_values, self.dlg_plan_psector, widget, self.my_json))
            elif type(widget) is QCheckBox:
                widget.stateChanged.connect(partial(tools_gw.get_values, self.dlg_plan_psector, widget, self.my_json))
            elif type(widget) is QTextEdit:
                widget.textChanged.connect(partial(tools_gw.get_values, self.dlg_plan_psector, widget, self.my_json))
            elif isinstance(widget, QgsDateTimeEdit):
                widget.dateChanged.connect(partial(tools_gw.get_values, self.dlg_plan_psector, widget, self.my_json))

        if psector_id is None:
            tools_qt.set_widget_text(self.dlg_plan_psector, 'tab_general_active', True)

            next_id = tools_gw.get_sequence_next_preview(
                seq_name='plan_psector_id_seq',
                schema=self.schema_name.replace('"', '')
            )
            tools_qt.set_widget_text(self.dlg_plan_psector, 'tab_general_psector_id', str(next_id))

        self.dlg_plan_psector.findChild(QLineEdit, "tab_general_name").textChanged.connect(partial(self.psector_name_changed))

        # Set psector editability based on current and archived status
        if psector_id is not None:
            sql = f"SELECT archived FROM v_ui_plan_psector WHERE psector_id = {psector_id}"
            row = tools_db.get_row(sql)
            archived = row[0] if row else False
            cur_psector = tools_gw.get_config_value('plan_psector_current')
            is_current = cur_psector and cur_psector[0] is not None and int(cur_psector[0]) == psector_id
            if archived is True:
                self.psector_editable = False
            elif is_current:
                self.psector_editable = True
            else:
                self.psector_editable = False
        else:
            # New psector, always editable
            self.psector_editable = True

        # Manage psector editability
        self._manage_psector_editability(psector_id)

        # Open dialog
        tools_gw.open_dialog(self.dlg_plan_psector, dlg_name='plan_psector')

    def load_psector(self, dialog, psector_id, list_coord=None, form_opened=False):
        """
        Loads data for an existing psector into the dialog.

        Args:
            dialog (QDialog): Dialog to populate with psector data
            psector_id (int): ID of psector to load
            list_coord (list, optional): List of coordinates for psector extent. Defaults to None.
            form_opened (bool, optional): Whether form is being opened. Defaults to False.
        """
        sql = (f"SELECT psector_id, name, psector_type, expl_id, priority, descript, text1, text2, "
                   f"text3, text4, text5, text6, num_value, observ, atlas_id, scale, rotation, active, ext_code, status, workcat_id, parent_id"
                   f" FROM plan_psector "
                   f"WHERE psector_id = {psector_id}")
        row = tools_db.get_row(sql)

        if not row:
            return

        # Check if expl_id already exists in expl_selector
        sql = ("SELECT DISTINCT(expl_id, cur_user)"
                " FROM selector_expl"
                f" WHERE expl_id = '{row['expl_id']}' AND cur_user = current_user")
        exist = tools_db.get_row(sql)
        if exist is None:
            sql = ("INSERT INTO selector_expl (expl_id, cur_user) "
                    f" VALUES ({str(row['expl_id'])}, current_user)"
                    f" ON CONFLICT DO NOTHING;")
            tools_db.execute_sql(sql)
            msg = "Your exploitation selector has been updated"
            tools_qgis.show_warning(msg, 1, dialog=dialog)

        if form_opened:
            self.fill_widget(dialog, "text3", row)
            self.fill_widget(dialog, "text4", row)
            self.fill_widget(dialog, "text5", row)
            self.fill_widget(dialog, "text6", row)
            self.fill_widget(dialog, "num_value", row)

            self.update = True

            dialog.rejected.connect(self.rubber_band_point.reset)

        self.zoom_to_psector(psector_id, list_coord)

        # Force refresh of selector docker to reflect any value changes
        tools_gw.refresh_selectors()

        if form_opened:
            self.tbl_document.doubleClicked.connect(partial(tools_qt.document_open, self.tbl_document, 'path'))

    def zoom_to_psector(self, psector_id: int, list_coord: Union[None, list[float]] = None):
        """ Zoom to psector """
        if not list_coord:

            sql = f"SELECT st_astext(st_envelope(the_geom)) FROM ve_plan_psector WHERE psector_id = {psector_id}"
            row = tools_db.get_row(sql)
            if row[0]:
                list_coord = re.search(r'\(\((.*)\)\)', str(row[0]))

        if list_coord:
            # Get canvas extend in order to create a QgsRectangle
            ext = self.canvas.extent()
            start_point = QgsPointXY(ext.xMinimum(), ext.yMaximum())
            end_point = QgsPointXY(ext.xMaximum(), ext.yMinimum())
            canvas_rec = QgsRectangle(start_point, end_point)
            canvas_width = ext.xMaximum() - ext.xMinimum()
            canvas_height = ext.yMaximum() - ext.yMinimum()

            points = tools_qgis.get_geometry_vertex(list_coord)
            polygon = QgsGeometry.fromPolygonXY([points])
            psector_rec = polygon.boundingBox()
            tools_gw.reset_rubberband(self.rubber_band_rectangle)
            rb_duration = tools_gw.get_config_parser("system", "show_psector_ruberband_duration", "user", "init", prefix=False)
            if rb_duration == "0":
                rb_duration = None
            tools_qgis.draw_polygon(points, self.rubber_band_rectangle, duration_time=rb_duration)

            # Manage Zoom to rectangle
            if not canvas_rec.intersects(psector_rec) or (psector_rec.width() < (canvas_width * 10) / 100 or psector_rec.height() < (canvas_height * 10) / 100):
                max_x, max_y, min_x, min_y = tools_qgis.get_max_rectangle_from_coords(list_coord)
                tools_qgis.zoom_to_rectangle(max_x, max_y, min_x, min_y, margin=50)
            else:
                tools_qgis.force_refresh_map_canvas()

    def psector_name_changed(self):
        """ Enable buttons and tabs when name is changed """

        psector_name = tools_qt.get_text(self.dlg_plan_psector, "tab_general_name")
        self.enable_buttons(psector_name != 'null' and not self.check_name(psector_name))
        self.set_tabs_enabled(psector_name != 'null' and not self.check_name(psector_name))

    def flags(self, index, model, editable_columns=None, table_specific_editable=None):

        column_name = model.headerData(index.column(), Qt.Orientation.Horizontal, Qt.ItemDataRole.DisplayRole)

        # Check if column is specifically allowed to be editable for this table
        if table_specific_editable and column_name in table_specific_editable:
            if isinstance(model, QSqlTableModel):
                return QSqlTableModel.flags(model, index)
            return QStandardItemModel.flags(model, index)

        # If column is in non-editable list, make it non-editable
        if column_name in self.no_editable_fields:
            return Qt.ItemFlag.ItemIsSelectable | Qt.ItemFlag.ItemIsEnabled

        if editable_columns and column_name not in editable_columns:
            flags = Qt.ItemFlag.ItemIsSelectable | Qt.ItemFlag.ItemIsEnabled
            return flags

        if isinstance(model, QSqlTableModel):
            return QSqlTableModel.flags(model, index)

        return QStandardItemModel.flags(model, index)

    def fill_widget(self, dialog, widget, row):

        if type(widget) is str:
            widget = dialog.findChild(QWidget, widget)
        if not widget:
            return
        key = widget.objectName()
        if key in row:
            if row[key] is not None:
                value = str(row[key])
                if type(widget) is QLineEdit or type(widget) is QTextEdit:
                    if value == 'None':
                        value = ""
                    widget.setText(value)
            else:
                widget.setText("")
        else:
            widget.setText("")

    def open_dlg_reports(self):

        default_file_name = tools_qt.get_text(self.dlg_plan_psector, "tab_general_name")

        self.dlg_psector_rapport = GwPsectorRapportUi(self)
        tools_gw.load_settings(self.dlg_psector_rapport)
        self._set_composer_warning('')

        tools_qt.set_widget_text(self.dlg_psector_rapport, 'txt_composer_path', default_file_name + " comp.pdf")
        tools_qt.set_widget_text(self.dlg_psector_rapport, 'txt_csv_detail_path', default_file_name + " prices detail.csv")
        tools_qt.set_widget_text(self.dlg_psector_rapport, 'txt_csv_path', default_file_name + " prices.csv")

        self.dlg_psector_rapport.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_psector_rapport))
        self.dlg_psector_rapport.btn_ok.clicked.connect(partial(self.generate_reports))
        self.dlg_psector_rapport.btn_path.clicked.connect(
            partial(tools_qt.get_folder_path, self.dlg_psector_rapport, self.dlg_psector_rapport.txt_path))

        value = tools_gw.get_config_parser('btn_psector', 'psector_rapport_path', "user", "session")
        tools_qt.set_widget_text(self.dlg_psector_rapport, self.dlg_psector_rapport.txt_path, value)
        value = tools_gw.get_config_parser('btn_psector', 'psector_rapport_chk_composer', "user", "session")
        tools_qt.set_checked(self.dlg_psector_rapport, self.dlg_psector_rapport.chk_composer, value)
        value = tools_gw.get_config_parser('btn_psector', 'psector_rapport_chk_csv_detail', "user", "session")
        tools_qt.set_checked(self.dlg_psector_rapport, self.dlg_psector_rapport.chk_csv_detail, value)
        value = tools_gw.get_config_parser('btn_psector', 'psector_rapport_chk_csv', "user", "session")
        tools_qt.set_checked(self.dlg_psector_rapport, self.dlg_psector_rapport.chk_csv, value)

        if tools_qt.get_text(self.dlg_psector_rapport, self.dlg_psector_rapport.txt_path) == 'null':
            if 'nt' in sys.builtin_module_names:
                plugin_dir = os.path.expanduser(r"~\Documents")
            else:
                plugin_dir = os.path.expanduser("~")
            tools_qt.set_widget_text(self.dlg_psector_rapport, self.dlg_psector_rapport.txt_path, plugin_dir)
        self.populate_cmb_templates()

        # Open dialog
        tools_gw.open_dialog(self.dlg_psector_rapport, dlg_name='psector_rapport')

    def populate_cmb_templates(self):

        index = 0
        records = []
        layout_manager = QgsProject.instance().layoutManager()
        layouts = layout_manager.layouts()  # QgsPrintLayout
        for layout in layouts:
            elem = [index, layout.name()]
            records.append(elem)
            index = index + 1

        if records in ([], None):
            # If no composer configured, disable composer pdf file widgets
            self.dlg_psector_rapport.chk_composer.setEnabled(False)
            self.dlg_psector_rapport.chk_composer.setChecked(False)
            self.dlg_psector_rapport.cmb_templates.setEnabled(False)
            self.dlg_psector_rapport.txt_composer_path.setEnabled(False)
            msg = "Composer disabled: no layouts available."
            self._set_composer_warning(msg)
            return
        else:
            # If composer configured, enable composer pdf file widgets
            self.dlg_psector_rapport.chk_composer.setEnabled(True)
            self.dlg_psector_rapport.cmb_templates.setEnabled(True)
            self.dlg_psector_rapport.txt_composer_path.setEnabled(True)
            tools_qt.fill_combo_values(self.dlg_psector_rapport.cmb_templates, records)

        if not hasattr(self, '_composer_template_signal_connected') or not self._composer_template_signal_connected:
            self.dlg_psector_rapport.cmb_templates.currentIndexChanged.connect(self._on_composer_template_changed)
            self.dlg_psector_rapport.chk_composer.stateChanged.connect(self._on_composer_checkbox_changed)
            self._composer_template_signal_connected = True

        row = tools_gw.get_config_value('composer_plan_vdefault')
        if row:
            tools_qt.set_combo_value(self.dlg_psector_rapport.cmb_templates, row[0])

        self._update_composer_status(initial=True)

    def _on_composer_template_changed(self, _index):
        self._update_composer_status()

    def _on_composer_checkbox_changed(self, state):
        if state:
            self._update_composer_status()
        else:
            self._set_composer_warning('')

    def _update_composer_status(self, initial=False):
        if not getattr(self.dlg_psector_rapport, 'chk_composer', None):
            return False

        composer_checked = tools_qt.is_checked(self.dlg_psector_rapport, 'chk_composer')
        if not composer_checked:
            self._set_composer_warning('')
            return False

        layout = self._validate_composer_layout()
        if layout is None:
            if composer_checked:
                self.dlg_psector_rapport.chk_composer.setChecked(False)
            return False

        self._set_composer_warning('')
        return True

    def _validate_composer_layout(self):

        layout_manager = QgsProject.instance().layoutManager()
        layout_name = tools_qt.get_text(self.dlg_psector_rapport, self.dlg_psector_rapport.cmb_templates)

        if not layout_name or layout_name in ('null', '-1'):
            msg = "Composer disabled: select a template."
            self._set_composer_warning(msg)
            return None

        layout = layout_manager.layoutByName(layout_name)

        if layout is None:
            msg = "Composer disabled: layout not found."
            self._set_composer_warning(msg)
            return None

        atlas = layout.atlas()
        coverage_layer = atlas.coverageLayer() if atlas else None

        if atlas is None or not atlas.enabled() or coverage_layer is None:
            msg = "Composer disabled: atlas must be enabled with coverage layer 'v_plan_psector'."
            self._set_composer_warning(msg)
            return None

        coverage_layer_table = (tools_qgis.get_layer_source_table_name(coverage_layer) or "").lower()
        if coverage_layer_table != "v_plan_psector":
            msg = "Composer disabled: atlas coverage layer must be 'v_plan_psector'."
            self._set_composer_warning(msg)
            return None

        total_text_items = 0
        for item in layout.items():
            if isinstance(item, QgsLayoutItemLabel):
                total_text_items += 1

        if total_text_items == 0:
            msg = "Composer disabled: file is empty."
            self._set_composer_warning(msg)
            return None

        return layout

    def _set_composer_warning(self, message=''):

        label = getattr(self.dlg_psector_rapport, 'lbl_composer_disabled', None)
        if not label:
            return

        label.setText(tools_qt.tr(message))
        label.setVisible(bool(message))
        if message:
            label.setStyleSheet('color: red')
        else:
            label.setStyleSheet('')

    def generate_reports(self):

        txt_path = f"{tools_qt.get_text(self.dlg_psector_rapport, 'txt_path')}"
        tools_gw.set_config_parser('btn_psector', 'psector_rapport_path', txt_path)
        chk_composer = tools_qt.is_checked(self.dlg_psector_rapport, 'chk_composer')
        tools_gw.set_config_parser('btn_psector', 'psector_rapport_chk_composer', f"{chk_composer}")
        chk_csv_detail = tools_qt.is_checked(self.dlg_psector_rapport, 'chk_csv_detail')
        tools_gw.set_config_parser('btn_psector', 'psector_rapport_chk_csv_detail', f"{chk_csv_detail}")
        chk_csv = tools_qt.is_checked(self.dlg_psector_rapport, 'chk_csv')
        tools_gw.set_config_parser('btn_psector', 'psector_rapport_chk_csv', f"{chk_csv}")

        folder_path = tools_qt.get_text(self.dlg_psector_rapport, self.dlg_psector_rapport.txt_path)
        if folder_path is None or folder_path == 'null' or not os.path.exists(folder_path):
            tools_qt.get_folder_path(self.dlg_psector_rapport.txt_path)
            folder_path = tools_qt.get_text(self.dlg_psector_rapport, self.dlg_psector_rapport.txt_path)

        if chk_composer is False and chk_csv is False and chk_csv_detail is False:
            msg = "You must choose at least one action"
            tools_qgis.show_warning(msg, dialog=self.dlg_psector_rapport)
            return

        # Generate Composer
        if chk_composer:
            if not self._update_composer_status():
                return
            file_name = tools_qt.get_text(self.dlg_psector_rapport, 'txt_composer_path')
            if file_name is None or file_name == 'null':
                msg = "File name is required"
                tools_qgis.show_warning(msg, dialog=self.dlg_plan_psector)
            if file_name.find('.pdf') is False:
                file_name += '.pdf'
            path = folder_path + '/' + file_name
            if not self.generate_composer(path):
                return

        # Generate csv detail
        if tools_qt.is_checked(self.dlg_psector_rapport, self.dlg_psector_rapport.chk_csv_detail):
            file_name = tools_qt.get_text(self.dlg_psector_rapport, 'txt_csv_detail_path')
            viewname = "v_plan_psector_budget_detail"
            if file_name is None or file_name == 'null':
                msg = "Price list detail csv file name is required"
                tools_qgis.show_warning(msg, dialog=self.dlg_plan_psector)
            if file_name.find('.csv') is False:
                file_name += '.csv'
            path = folder_path + '/' + file_name
            self.generate_csv(path, viewname)

        # Generate csv
        if tools_qt.is_checked(self.dlg_psector_rapport, self.dlg_psector_rapport.chk_csv):
            file_name = tools_qt.get_text(self.dlg_psector_rapport, 'txt_csv_path')
            viewname = "v_plan_psector_budget"
            if file_name is None or file_name == 'null':
                msg = "Price list csv file name is required"
                tools_qgis.show_warning(msg, dialog=self.dlg_plan_psector)
            if file_name.find('.csv') is False:
                file_name += '.csv'
            path = folder_path + '/' + file_name
            self.generate_csv(path, viewname)

        # Show success message
        msg = "Reports generated successfully"
        tools_qgis.show_info(msg, dialog=self.dlg_plan_psector)

        # Close dialog
        tools_gw.close_dialog(self.dlg_psector_rapport)

    def generate_composer(self, path=None, dry_run=False):

        layout = self._validate_composer_layout()
        if layout is None:
            return False

        if dry_run:
            return True

        # Filter atlas by the current psector_id
        atlas = layout.atlas()
        psector_id = tools_qt.get_text(self.dlg_plan_psector, 'tab_general_psector_id')
        previous_filter = atlas.filterExpression()
        if psector_id not in (None, 'null', ''):
            atlas.setFilterFeatures(True)
            atlas.setFilterExpression(f"psector_id = {psector_id}")

        # Since qgis 3.4 cant do .setAtlasMode(QgsComposition.PreviewAtlas)
        # then we need to force the opening of the layout designer, trigger the mActionAtlasPreview action and
        # close the layout designer again (finally sentence)
        designer = self.iface.openLayoutDesigner(layout)
        layout_view = designer.view()
        designer_window = layout_view.window()
        action = designer_window.findChild(QAction, 'mActionAtlasPreview')
        action.trigger()

        # Export to PDF file
        try:
            exporter = QgsLayoutExporter(layout)
            exporter.exportToPdf(path, QgsLayoutExporter.PdfExportSettings())
            if os.path.exists(path):
                msg = "Document PDF created in"
                tools_qgis.show_info(msg, parameter=path, dialog=self.dlg_plan_psector)
                status, message = tools_os.open_file(path)
                if status is False and message is not None:
                    tools_qgis.show_warning(message, parameter=path, dialog=self.dlg_plan_psector)
            else:
                msg = "Cannot create file, check if its open"
                tools_qgis.show_warning(msg, parameter=path, dialog=self.dlg_plan_psector)
        except Exception as e:
            tools_log.log_warning(str(e))
            msg = "Cannot create file, check if selected composer is the correct composer"
            tools_qgis.show_warning(msg, parameter=path, dialog=self.dlg_plan_psector)
            msg = "Composer disabled: export failed, check layout configuration."
            self._set_composer_warning(msg)
            return False
        finally:
            designer_window.close()
            # Restore previous atlas filter
            atlas.setFilterExpression(previous_filter)
            if not previous_filter:
                atlas.setFilterFeatures(False)

        return True

    def generate_csv(self, path, viewname):

        # Get columns name in order of the table
        sql = (f"SELECT column_name FROM information_schema.columns"
               f" WHERE table_name = '{viewname}'"
               f" AND table_schema = '" + self.schema_name.replace('"', '') + "'"
               " ORDER BY ordinal_position")
        rows = tools_db.get_rows(sql)
        columns = []

        if not rows or rows is None or rows == '':
            msg = "CSV not generated. Check fields from table or view"
            tools_qgis.show_warning(msg, parameter=viewname, dialog=self.dlg_plan_psector)
            return
        for i in range(0, len(rows)):
            column_name = rows[i]
            columns.append(str(column_name[0]))

        psector_id = f"{tools_qt.get_text(self.dlg_plan_psector, 'tab_general_psector_id')}"
        sql = f"SELECT * FROM {viewname} WHERE psector_id = '{psector_id}'"
        rows = tools_db.get_rows(sql)
        all_rows = []
        all_rows.append(columns)
        if not rows or rows is None or rows == '':
            return
        for i in rows:
            all_rows.append(i)

        with open(path, "w") as output:
            writer = csv.writer(output, lineterminator='\n')
            writer.writerows(all_rows)

    def populate_budget(self, dialog, psector_id):

        if psector_id is None or psector_id == 'null':
            return
        sql = ("SELECT DISTINCT(column_name) FROM information_schema.columns"
               " WHERE table_name = 'v_plan_psector'")
        rows = tools_db.get_rows(sql)
        columns = []
        for i in range(0, len(rows)):
            column_name = rows[i]
            columns.append(str(column_name[0]))

        # Get currency config
        currency_config = None
        try:
            row_currency = tools_gw.get_config_value(parameter='admin_currency', columns='value::text', table='v_config_param_system')
            if row_currency:
                currency_config = json.loads(row_currency[0])
        except Exception:
            pass

        sql = (f"SELECT total_arc, total_node, total_other, pem, pec, pec_vat, gexpenses, vat, other, pca"
               f" FROM v_plan_psector"
               f" WHERE psector_id = '{psector_id}'")
        row = tools_db.get_row(sql)
        if row:
            for column_name in columns:
                if column_name in row:
                    if row[column_name] is not None:
                        formatted_value = tools_gw.format_currency(row[column_name], currency_config, with_symbol=False)
                        tools_qt.set_widget_text(dialog, column_name, formatted_value)
                    else:
                        formatted_value = tools_gw.format_currency(0, currency_config, with_symbol=False)
                        tools_qt.set_widget_text(dialog, column_name, formatted_value)

        self.calc_pec_pem(dialog, currency_config)
        self.calc_pecvat_pec(dialog, currency_config)
        self.calc_pca_pecvat(dialog, currency_config)

    def calc_pec_pem(self, dialog, currency_config=None):

        if tools_qt.get_text(dialog, 'pec') not in ('null', None):
            pec = tools_gw.parse_currency(tools_qt.get_text(dialog, 'pec'), currency_config)
        else:
            pec = 0

        if tools_qt.get_text(dialog, 'pem') not in ('null', None):
            pem = tools_gw.parse_currency(tools_qt.get_text(dialog, 'pem'), currency_config)
        else:
            pem = 0

        res = tools_gw.format_currency(round(pec - pem, 2), currency_config, with_symbol=False)
        tools_qt.set_widget_text(dialog, 'pec_pem', res)

    def calc_pecvat_pec(self, dialog, currency_config=None):

        if tools_qt.get_text(dialog, 'pec_vat') not in ('null', None):
            pec_vat = tools_gw.parse_currency(tools_qt.get_text(dialog, 'pec_vat'), currency_config)
        else:
            pec_vat = 0

        if tools_qt.get_text(dialog, 'pec') not in ('null', None):
            pec = tools_gw.parse_currency(tools_qt.get_text(dialog, 'pec'), currency_config)
        else:
            pec = 0
        res = tools_gw.format_currency(round(pec_vat - pec, 2), currency_config, with_symbol=False)
        tools_qt.set_widget_text(dialog, 'pecvat_pem', res)

    def calc_pca_pecvat(self, dialog, currency_config=None):

        if tools_qt.get_text(dialog, 'pca') not in ('null', None):
            pca = tools_gw.parse_currency(tools_qt.get_text(dialog, 'pca'), currency_config)
        else:
            pca = 0

        if tools_qt.get_text(dialog, 'pec_vat') not in ('null', None):
            pec_vat = tools_gw.parse_currency(tools_qt.get_text(dialog, 'pec_vat'), currency_config)
        else:
            pec_vat = 0
        res = tools_gw.format_currency(round(pca - pec_vat, 2), currency_config, with_symbol=False)
        tools_qt.set_widget_text(dialog, 'pca_pecvat', res)

    def calculate_percents(self, tablename, field):

        field_value = f"{tools_qt.get_text(self.dlg_plan_psector, field)}"
        psector_id = tools_qt.get_text(self.dlg_plan_psector, "tab_general_psector_id")
        sql = f"UPDATE {tablename} SET {field} = '{field_value}' WHERE psector_id = '{psector_id}'"
        tools_db.execute_sql(sql)
        self.populate_budget(self.dlg_plan_psector, psector_id)

    def show_description(self):
        """ Show description of product plan/om _psector as label"""

        selected_list = self.dlg_plan_psector.all_rows.selectionModel().selectedRows()
        des = ""
        for i in range(0, len(selected_list)):
            row = selected_list[i].row()
            des = self.dlg_plan_psector.all_rows.model().record(row).value('descript')
        tools_qt.set_widget_text(self.dlg_plan_psector, self.lbl_descript, des)

    def set_tabs_enabled(self, enabled):

        self.dlg_plan_psector.tabwidget.setTabEnabled(1, enabled)
        self.dlg_plan_psector.tabwidget.setTabEnabled(2, enabled)
        self.dlg_plan_psector.tabwidget.setTabEnabled(3, enabled)
        self.dlg_plan_psector.tabwidget.setTabEnabled(4, enabled)
        self.dlg_plan_psector.tabwidget.setTabEnabled(5, enabled)

    def enable_buttons(self, enabled):
        self.dlg_plan_psector.btn_insert.setEnabled(enabled)
        self.dlg_plan_psector.btn_delete.setEnabled(enabled)
        widget_to_ignore = ('btn_accept', 'btn_cancel', 'btn_reports', 'btn_open_doc')
        restriction = ('role_basic', 'role_om', 'role_epa', 'role_om')
        self.set_restriction_by_role(self.dlg_plan_psector, widget_to_ignore, restriction)

    def check_tab_position(self):

        psector_id = tools_qt.get_text(self.dlg_plan_psector, 'tab_general_psector_id')

        if not self.update:
            result = self.insert_or_update_new_psector(from_tab_change=True)
            if result is False:
                self.dlg_plan_psector.tabwidget.blockSignals(True)
                self.dlg_plan_psector.tabwidget.setCurrentIndex(0)
                self.dlg_plan_psector.tabwidget.blockSignals(False)
                return

        self.psector_id = psector_id
        if self.dlg_plan_psector.tabwidget.currentIndex() == 2:
            if not self._relations_tab_feature_initialized:
                self.dlg_plan_psector.tab_feature.setCurrentIndex(0)
                tools_gw.get_signal_change_tab(
                    self.dlg_plan_psector,
                    self.excluded_layers_tab_feature,
                    view_prefix='vf_'
                )
                self._relations_tab_feature_initialized = True
            if not self._selection_widget_loaded:
                self_varibles = {"selection_mode": GwSelectionMode.PSECTOR, "method": "psector", "invert_selection": True, "zoom_to_selection": True, "selection_on_top": True}
                general_variables = {"class_object": self, "dialog": self.dlg_plan_psector, "table_object": "psector"}
                menu_variables = {"used_tools": ["rectangle", "polygon", "freehand"]}
                highlight_variables = {"callback_values": self.callback_values}
                selection_on_top_variables = {"callback_later": self.reset_relation_tables_signals}
                selection_widget = GwSelectionWidget(self_varibles, general_variables, menu_variables, highlight_variables=highlight_variables, selection_on_top_variables=selection_on_top_variables)
                self.dlg_plan_psector.lyt_selection.addWidget(selection_widget, 0)
                self._selection_widget_loaded = True
        elif self.dlg_plan_psector.tabwidget.currentIndex() == 3:
            tableleft = "v_price_compost"
            tableright = "ve_plan_psector_x_other"
            if not self.load_signals:
                self.price_selector(self.dlg_plan_psector, tableleft, tableright)
        elif self.dlg_plan_psector.tabwidget.currentIndex() == 4:
            self.populate_budget(self.dlg_plan_psector, psector_id)
        elif self.dlg_plan_psector.tabwidget.currentIndex() == 5:
            if not self._doc_completer_loaded:
                sql = "SELECT DISTINCT(name) FROM v_ui_doc ORDER BY name"
                list_items = tools_db.create_list_for_completer(sql)
                tools_qt.set_completer_lineedit(self.dlg_plan_psector.doc_id, list_items)
                self._doc_completer_loaded = True
            self.psector_name = self.dlg_plan_psector.findChild(QLineEdit, "tab_general_name").text()
            expr = f"psector_name = '{self.psector_name}'"
            message = tools_qt.fill_table(self.tbl_document, f"{self.schema_name}.v_ui_doc_x_psector", expr)
            tools_gw.set_tablemodel_config(self.dlg_plan_psector, self.tbl_document, "v_ui_doc_x_psector")
            if message:
                tools_qgis.show_warning(message, dialog=self.dlg_plan_psector)

        if psector_id is None or psector_id == 'null':
            return
        sql = f"SELECT other, gexpenses, vat  FROM plan_psector WHERE psector_id = '{psector_id}'"
        row = tools_db.get_row(sql)
        if row:
            tools_qt.set_widget_text(self.dlg_plan_psector, self.dlg_plan_psector.other, row[0])
            tools_qt.set_widget_text(self.dlg_plan_psector, self.dlg_plan_psector.gexpenses, row[1])
            tools_qt.set_widget_text(self.dlg_plan_psector, self.dlg_plan_psector.vat, row[2])

        widget_to_ignore = ('btn_accept', 'btn_cancel', 'btn_reports', 'btn_open_doc')
        restriction = ('role_basic', 'role_om', 'role_epa', 'role_om')
        self.set_restriction_by_role(self.dlg_plan_psector, widget_to_ignore, restriction)

    def set_restriction_by_role(self, dialog, widget_to_ignore, restriction):
        """
        Set all widget enabled(False) or readOnly(True) except those on the tuple
            :param dialog:
            :param widget_to_ignore: tuple = ('widgetname1', 'widgetname2', 'widgetname3', ...)
            :param restriction: roles that do not have access. tuple = ('role1', 'role1', 'role1', ...)
        """

        role = lib_vars.project_vars['project_role']
        role = tools_gw.get_role_permissions(role)
        if role in restriction:
            widget_list = dialog.findChildren(QWidget)
            for widget in widget_list:
                if widget.objectName() in widget_to_ignore:
                    continue
                # Set editable/readonly
                if type(widget) in (QLineEdit, QDoubleSpinBox, QTextEdit):
                    widget.setReadOnly(True)
                    widget.setStyleSheet("QWidget {background: rgb(242, 242, 242);color: rgb(100, 100, 100)}")
                elif type(widget) in (QCheckBox, QTableView, QPushButton) or isinstance(widget, QComboBox):
                    widget.setEnabled(False)

    def reset_model_psector(self, feature_type):
        """ Reset model of the widget """

        table_relation = "" + feature_type + "_plan"
        widget_name = "tbl_" + table_relation
        widget = tools_qt.get_widget(self.dlg_plan_psector, widget_name)
        if widget:
            widget.setModel(None)

    def check_name(self, psector_name):
        """ Check if name of new psector exist or not """

        sql = (f"SELECT name FROM plan_psector"
               f" WHERE name = '{psector_name}'")
        row = tools_db.get_row(sql)
        if row is None:
            return False
        return True

    def insert_or_update_new_psector(self, from_tab_change=False):
        """Main function to insert or update psector"""

        psector_name = tools_qt.get_text(self.dlg_plan_psector, "tab_general_name", return_string_null=False)
        if psector_name == "":
            msg = "Mandatory field is missing. Please, set a value"
            tools_qgis.show_warning(msg, parameter='Name', dialog=self.dlg_plan_psector)
            return False

        rotation = tools_qt.get_text(self.dlg_plan_psector, "tab_general_rotation", return_string_null=False)
        if rotation == "":
            tools_qt.set_widget_text(self.dlg_plan_psector, "tab_general_rotation", 0)

        if not self._validate_psector_fields():
            return False

        if not self._check_psector_name_availability(psector_name):
            return False

        columns = self._get_psector_columns()
        if columns is None:
            return False

        if not self._check_workcat_for_executed_status(psector_name):
            return False

        self._toggle_topology_trigger(enable=True)

        if self.update:
            self._update_psector()
        else:
            self._insert_psector(columns)

        self._toggle_topology_trigger(enable=False)

        if from_tab_change is False:
            tools_gw.refresh_selectors()
            tools_gw.close_dialog(self.dlg_plan_psector)

    def _validate_psector_fields(self) -> bool:
        """Validate numeric fields and parent_id"""

        errors = []
        scale = tools_qt.get_text(self.dlg_plan_psector, "tab_general_scale", return_string_null=False)
        atlas_id = tools_qt.get_text(self.dlg_plan_psector, "tab_general_atlas_id", return_string_null=False)
        parent_id = tools_qt.get_text(self.dlg_plan_psector, "tab_general_parent_id", return_string_null=False)
        rotation = tools_qt.get_text(self.dlg_plan_psector, "tab_general_rotation", return_string_null=False)

        if rotation != "":
            try:
                float(rotation)
            except ValueError:
                msg = "Rotation must be a number."
                errors.append(tools_qt.tr(msg))

        if scale != "":
            try:
                float(scale)
            except ValueError:
                msg = "Scale must be a number."
                errors.append(tools_qt.tr(msg))

        if atlas_id != "":
            try:
                int(atlas_id)
            except ValueError:
                msg = "Atlas ID must be an integer."
                errors.append(tools_qt.tr(msg))

        if parent_id != "":
            try:
                int(parent_id)
            except ValueError:
                msg = "Parent ID must be an integer."
                errors.append(tools_qt.tr(msg))

        if parent_id is not None and parent_id != "":
            if not self._validate_parent_id(parent_id):
                msg = "Parent ID does not exist."
                errors.append(tools_qt.tr(msg))

        if errors:
            msg = "Psector could not be updated because of the following errors: {0}"
            msg_params = (" ".join(errors),)
            tools_qgis.show_warning(msg, dialog=self.dlg_plan_psector, msg_params=msg_params)
            return False

        return True

    def _validate_parent_id(self, parent_id: str) -> bool:
        """Check if parent_id exists in ve_plan_psector"""

        try:
            parent_id_exists = tools_db.get_rows(
                f"SELECT 1 FROM ve_plan_psector WHERE psector_id = {parent_id} AND NOT archived"
            )
        except Exception:
            return False

        return parent_id_exists is not None and len(parent_id_exists) > 0

    def _check_psector_name_availability(self, psector_name: str) -> bool:
        """Check if psector name is available for new psector"""

        name_exist = self.check_name(psector_name)
        if name_exist and not self.update:
            msg = "The name is current in use"
            tools_qgis.show_warning(msg, dialog=self.dlg_plan_psector)
            return False
        return True

    def _get_psector_columns(self) -> Optional[list]:
        """Get columns from ve_plan_psector view"""

        viewname = "'ve_plan_psector'"
        sql = (f"SELECT column_name FROM information_schema.columns "
               f"WHERE table_name = {viewname} "
               f"AND table_schema = '" + self.schema_name.replace('"', '') + "' "
               "ORDER BY ordinal_position;")
        rows = tools_db.get_rows(sql)

        if not rows or rows is None or rows == '':
            msg = "Check fields from table or view"
            tools_qgis.show_warning(msg, parameter=viewname, dialog=self.dlg_plan_psector)
            return None

        columns = []
        for row in rows:
            columns.append(str(row[0]))
        return columns

    def _check_workcat_for_executed_status(self, psector_name: str) -> bool:
        """Check if workcat_id is set when psector status is Executed"""

        workcat_id = tools_qt.get_text(self.dlg_plan_psector, 'tab_general_workcat_id')
        status_id = tools_qt.get_combo_value(self.dlg_plan_psector, 'tab_general_status')

        if int(status_id) == 5 and workcat_id in (None, 'null', ''):
            msg = "Psector '{0}' has no workcat_id value set. Do you want to continue with the default value?"
            msg_params = (psector_name,)
            answer = tools_qt.show_question(msg, title='Psector', msg_params=msg_params)
            if answer is False:
                return False
        return True

    def _toggle_topology_trigger(self, enable: bool) -> None:
        """Enable or disable topology trigger"""

        value = 'True' if enable else 'False'
        sql = (f"UPDATE config_param_user "
               f"SET value = {value} "
               f"WHERE parameter = 'plan_psector_disable_checktopology_trigger' AND cur_user=current_user")
        tools_db.execute_sql(sql)

    def _update_psector(self) -> None:
        """Update existing psector"""

        psector_id = tools_qt.get_text(self.dlg_plan_psector, 'tab_general_psector_id')
        updates = ""

        for key, value in self.my_json.items():
            if value in (None, 'null', 'NULL', ''):
                updates += f"{key} = NULL, "
            else:
                value = str(value).replace("'", "''")
                updates += f"{key} = '{value}', "

        if updates:
            updates = updates[:-2]
            sql = f"UPDATE ve_plan_psector SET {updates} WHERE psector_id = {psector_id}"
            if tools_db.execute_sql(sql):
                msg = "Psector values updated successfully"
                tools_qgis.show_info(msg, dialog=self.dlg_plan_psector)

        self.my_json = {}

    def _insert_psector(self, columns: list) -> None:
        """Insert new psector"""

        if not columns:
            return

        sql = "INSERT INTO ve_plan_psector ("
        values = "VALUES("

        for column_name in columns:
            widget_name = f"tab_general_{column_name}"
            if tools_qt.get_widget(self.dlg_plan_psector, widget_name) is None:
                widget_name = column_name

            if widget_name == 'tab_general_psector_id':
                continue

            widget_value = self._get_widget_value_for_insert(widget_name)
            if widget_value is not None:
                sql += column_name + ", "
                values += widget_value + ", "

        sql = sql[:-2] + ") "
        values = values[:-2] + ")"
        sql += f"{values} RETURNING psector_id;"

        new_psector_id = tools_db.execute_returning(sql)
        if new_psector_id:
            self._configure_new_psector(new_psector_id[0])

    def _get_widget_value_for_insert(self, widget_name: str) -> Optional[str]:
        """Get widget value formatted for SQL INSERT"""

        widget = tools_qt.get_widget(self.dlg_plan_psector, widget_name)
        if widget is None:
            return None
        value = None
        if isinstance(widget, QCheckBox):
            value = str(tools_qt.is_checked(self.dlg_plan_psector, widget)).upper()
        elif isinstance(widget, (QDateEdit, tools_gw.CustomQgsDateTimeEdit)):
            value = widget.dateTime().toString('yyyy-MM-dd HH:mm:ss')
        elif isinstance(widget, (QComboBox, tools_gw.CustomQComboBox)):
            value = str(tools_qt.get_combo_value(self.dlg_plan_psector, widget))
        else:
            value = tools_qt.get_text(self.dlg_plan_psector, widget)

        if value in (None, 'null', 'NULL', ''):
            return "null"
        else:
            return f"$${value}$$"

    def _configure_new_psector(self, new_psector_id: int) -> None:
        """Configure dialog and settings after creating new psector"""

        self.dlg_plan_psector.findChild(QLineEdit, "tab_general_name").setEnabled(False)
        tools_qt.set_widget_text(self.dlg_plan_psector, "tab_general_psector_id", str(new_psector_id))

        cur_psector = tools_gw.get_config_value('plan_psector_current')
        if cur_psector is not None:
            sql = (f"UPDATE config_param_user "
                   f"SET value = '{new_psector_id}' "
                   f"WHERE parameter = 'plan_psector_current' "
                   f"AND cur_user=current_user;")
        else:
            sql = (f"INSERT INTO config_param_user (parameter, value, cur_user) "
                   f"VALUES ('plan_psector_current', '{new_psector_id}', current_user);")

        tools_db.execute_sql(sql)
        self.update = True
        self.dlg_plan_psector.tabwidget.setTabEnabled(1, True)

        if getattr(self, 'dlg_psector_mng', None) is not None:
            self.set_label_current_psector(self.dlg_psector_mng, scenario_type="psector", from_open_dialog=True)

        tools_gw.set_psector_mode_enabled(enable=True, psector_id=new_psector_id, do_call_fct=False, force_change=True)

    def check_topology_psector(self, psector_id=None, psector_name=None, from_toggle=False):

        if psector_id in (None, "null"):
            return False

        extras = f'"psectorId":"{psector_id}"'
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_checktopologypsector', body)
        if not json_result or 'body' not in json_result or 'data' not in json_result['body']:
            return False

        msg = ""
        if json_result['message']['level'] == 1:
            if from_toggle:
                message = "Unable to activate psector. "
                msg += tools_qt.tr(message)
            message = "There are some topological inconsistences on psector '{0}'. Would you like to see the log?"
            msg += tools_qt.tr(message)
            msg_params = (psector_name,)
            function = partial(self.show_psector_topoerror_log, json_result, psector_id)
            tools_qgis.show_message_function(msg, function, message_level=Qgis.MessageLevel.Warning, duration=0, text_params=msg_params, dialog=self.dlg_plan_psector)
            if from_toggle:
                return False

        return json_result

    def show_psector_topoerror_log(self, json_result, psector_id):

        # Remove message
        self.iface.messageBar().popWidget()

        # Create log dialog
        self.dlg_infolog = GwPsectorRepairUi(self)
        self.dlg_infolog.btn_repair.clicked.connect(partial(self.repair_psector, psector_id))
        self.dlg_infolog.btn_close.clicked.connect(partial(tools_gw.close_dialog, self.dlg_infolog, True))

        text, _ = tools_gw.fill_tab_log(self.dlg_infolog, json_result['body']['data'], close=False)
        tools_gw.open_dialog(self.dlg_infolog, dlg_name='psector_repair')

        # Draw log features on map
        tools_gw.manage_json_response(json_result)

    def repair_psector(self, psector_id):

        extras = f'"psectorId":"{psector_id}"'
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_setrepairpsector', body, is_thread=True)

        if not json_result or 'body' not in json_result or 'data' not in json_result['body']:
            return

        text, _ = tools_gw.fill_tab_log(self.dlg_infolog, json_result['body']['data'], close=False)

        tools_qt.set_widget_enabled(self.dlg_infolog, 'btn_repair', False)
        # Remove temporal layers
        tools_qgis.remove_layer(custom_properties={"gw_id": "line"}, group_name='GW Temporal Layers')
        tools_qgis.remove_layer(custom_properties={"gw_id": "point"}, group_name='GW Temporal Layers')
        tools_qgis.remove_layer(custom_properties={"gw_id": "polygon"}, group_name='GW Temporal Layers')
        tools_qgis.clean_layer_group_from_toc("GW Temporal Layers")

        # Refresh canvas
        tools_qgis.refresh_map_canvas()

    def price_selector(self, dialog, tableleft, tableright):

        self.load_signals = True

        # fill QTableView all_rows
        tbl_all_rows = dialog.findChild(QTableView, "all_rows")
        tbl_all_rows.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.fill_table(dialog, tbl_all_rows, tableleft)
        tools_gw.set_tablemodel_config(dialog, tbl_all_rows, tableleft)
        tbl_all_rows.horizontalHeader().setStretchLastSection(False)

        if not self.price_loaded:
            self.price_loaded = True
            self.count = -1
            psector_id = tools_qt.get_text(dialog, 'tab_general_psector_id')
            self._manage_widgets_price(dialog, tableright, psector_id, print_all_rows=True, print_headers=True)

        # Button select (Create new labels)
        dialog.btn_select.clicked.connect(
            partial(self.create_label, dialog, tbl_all_rows, 'id', tableright, "price_id"))
        tbl_all_rows.doubleClicked.connect(
            partial(self.create_label, dialog, tbl_all_rows, 'id', tableright, "price_id"))

        # Button unselect
        dialog.btn_remove.clicked.connect(
            partial(self.rows_unselector, dialog, tableright))
        dialog.btn_set_geom.clicked.connect(partial(self._manage_price_geom, dialog, tableright))

    def create_label(self, dialog, tbl_all_rows, id_ori, tableright, id_des):

        selected_list = tbl_all_rows.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return
        expl_id = []
        for i in range(0, len(selected_list)):
            row = selected_list[i].row()
            id_ = tbl_all_rows.model().record(row).value(id_ori)
            expl_id.append(id_)

        psector_id = tools_qt.get_text(dialog, 'tab_general_psector_id')

        for i in range(0, len(selected_list)):
            row = selected_list[i].row()
            values = ""
            values += f"'{psector_id}', "
            if tbl_all_rows.model().record(row).value('unit') not in (None, 'null', 'NULL'):
                values += f"'{tbl_all_rows.model().record(row).value('unit')}', "
            else:
                values += 'null, '
            if tbl_all_rows.model().record(row).value('id') not in (None, 'null', 'NULL'):
                values += f"'{tbl_all_rows.model().record(row).value('id')}', "
            else:
                values += 'null, '
            if tbl_all_rows.model().record(row).value('description') not in (None, 'null', 'NULL'):
                values += f"'{tbl_all_rows.model().record(row).value('description')}', "
            else:
                values += 'null, '
            if tbl_all_rows.model().record(row).value('price') not in (None, 'null', 'NULL'):
                values += f"'{tbl_all_rows.model().record(row).value('price')}', "
            else:
                values += 'null, '
            values = values[:len(values) - 2]
            # Check if expl_id already exists in expl_selector
            sql = (f"SELECT DISTINCT({id_des})"
                   f" FROM {tableright}"
                   f" WHERE {id_des} = '{expl_id[i]}'"
                   f" AND psector_id = '{psector_id}'")

            row = tools_db.get_row(sql)
            if row is not None:
                # if exist - show warning
                msg = "Id already selected"
                tools_qt.show_info_box(msg, "Info", parameter=str(expl_id[i]))
            else:
                sql = (f"INSERT INTO {tableright}"
                       f" (psector_id, unit, price_id, observ, price) "
                       f" VALUES ({values})")
                tools_db.execute_sql(sql)

        self._manage_widgets_price(dialog, tableright, psector_id, expl_id)

    def _manage_widgets_price(self, dialog, tableright, psector_id, print_all_rows=False, print_headers=True):

        layout = dialog.findChild(QGridLayout, 'lyt_price')

        for i in reversed(range(layout.count())):
            widget = layout.itemAt(i).widget()
            if widget:
                if 'widget_total' in widget.objectName():
                    widget.setObjectName(f"{widget.objectName().replace('widget_total', '_old')}")
                widget.deleteLater()
        self._add_price_widgets(dialog, tableright, psector_id, print_all_rows=print_all_rows, print_headers=print_headers)
        self._manage_buttons_price(dialog)

    def _add_price_widgets(self, dialog, tableright, psector_id, expl_id=[], editable_widgets=['measurement', 'observ'],
                           print_all_rows=False, print_headers=False):

        extras = (f'"tableName":"{tableright}", "psectorId":{psector_id}')
        body = tools_gw.create_body(extras=extras)
        complet_result = tools_gw.execute_procedure('gw_fct_getwidgetprices', body)

        if complet_result['total_other'] is not None:
            tools_qt.set_widget_text(dialog, 'lbl_total_count', complet_result['total_other'])

        if not complet_result or not complet_result.get('fields'):
            return

        if print_headers or self.header_exist is None:
            self.header_exist = True
            pos = 1
            self.count = self.count + 1
            for key in complet_result['fields'][0].keys():
                if key != 'id':
                    lbl = QLabel()
                    lbl.setObjectName(f"lbl_{key}_{self.count}")
                    lbl.setText(f"  {key}  ")

                    layout = dialog.findChild(QGridLayout, 'lyt_price')
                    layout.addWidget(lbl, self.count, pos)
                    layout.setColumnStretch(2, 1)
                    pos = pos + 1

        for field in complet_result['fields']:
            if field['price_id'] in expl_id or print_all_rows:
                self.count = self.count + 1
                pos = 0

                # Create check
                check = QCheckBox()
                check.setObjectName(f"{field['id']}")
                check.stateChanged.connect(partial(self._manage_buttons_price, dialog))

                layout = dialog.findChild(QGridLayout, 'lyt_price')
                layout.addWidget(check, self.count, pos)
                layout.setColumnStretch(2, 1)
                pos = pos + 1

                for key in complet_result['fields'][0].keys():
                    if key != 'id':
                        if key not in editable_widgets:
                            widget = QLabel()
                            widget.setObjectName(f"widget_{key}_{field['price_id']}")
                            widget.setText(f"  {field.get(key)}  ")
                        else:
                            widget = QLineEdit()
                            widget.setObjectName(f"widget_{key}_{field['price_id']}")
                            text = field.get(key) if field.get(key) is not None else ''
                            widget.setText(f"{text}")
                            widget.editingFinished.connect(partial(self._manage_updates_prices, widget, key, field['price_id']))
                            widget.editingFinished.connect(partial(self._manage_widgets_price, dialog, tableright, psector_id, print_all_rows=True))

                        layout = dialog.findChild(QGridLayout, 'lyt_price')
                        layout.addWidget(widget, self.count, pos)
                        layout.setColumnStretch(2, 1)
                        pos = pos + 1

    def _manage_updates_prices(self, widget, key, price_id):

        self.dict_to_update[f"widget_{key}_{price_id}"] = {"price_id": price_id, key: widget.text()}
        self._update_otherprice()

    def _update_otherprice(self):

        sql = ""
        _filter = ""
        if self.dict_to_update:
            for main_key in self.dict_to_update:
                sub_list = list(self.dict_to_update[main_key].keys())
                for sub_key in sub_list:
                    if sub_key == 'price_id':
                        _filter = self.dict_to_update[main_key][sub_key]
                    else:
                        sql += f"UPDATE ve_plan_psector_x_other SET {sub_key} = '{self.dict_to_update[main_key][sub_key]}' " \
                               f"WHERE psector_id = {self.psector_id} AND price_id = '{_filter}';\n"
            tools_db.execute_sql(sql)

    def _manage_widgets(self, dialog, lbl, widget, count, pos):

        layout = dialog.findChild(QGridLayout, 'lyt_price')

        layout.addWidget(lbl, count, pos)
        layout.addWidget(widget, count, pos + 1)
        layout.setColumnStretch(2, 1)

    def rows_unselector(self, dialog, tableright):

        query = (f"DELETE FROM {tableright}"
                 f" WHERE {tableright}.id = ")

        select_widgets = dialog.tab_other_prices.findChildren(QCheckBox)
        selected_ids = []
        count = 0
        for check in select_widgets:
            if check.isChecked():
                selected_ids.append(check.objectName())
            else:
                count = count + 1

        psector_id = tools_qt.get_text(dialog, 'tab_general_psector_id')
        for i in range(0, len(selected_ids)):
            sql = f"{query}'{selected_ids[i]}' AND psector_id = '{psector_id}'"
            tools_db.execute_sql(sql)

        self._manage_widgets_price(dialog, tableright, psector_id, print_all_rows=True, print_headers=True)

    def _manage_buttons_price(self, dialog):
        """ Get selected prices to enable/disable buttons """

        select_widgets = self.dlg_plan_psector.tab_other_prices.findChildren(QCheckBox)
        selected_ids = []
        count = 0
        for check in select_widgets:
            if check.isChecked():
                selected_ids.append(check.objectName())
            else:
                count = count + 1

        tools_qt.set_widget_enabled(self.dlg_plan_psector, 'btn_set_geom', False)
        tools_qt.set_widget_enabled(self.dlg_plan_psector, 'btn_remove', False)
        if len(selected_ids) == 1:
            tools_qt.set_widget_enabled(self.dlg_plan_psector, 'btn_set_geom', True)
        if len(selected_ids) >= 1:
            tools_qt.set_widget_enabled(self.dlg_plan_psector, 'btn_remove', True)

    def _manage_price_geom(self, dialog, tableright):

        if hasattr(self, 'emit_point') and self.emit_point is not None:
            tools_gw.disconnect_signal('psector', 'price_geom_ep_canvasClicked_set_price_geom')
        self.emit_point = QgsMapToolEmitPoint(self.canvas)
        self.canvas.setMapTool(self.emit_point)

        # Set signals
        tools_gw.connect_signal(self.emit_point.canvasClicked, partial(self._set_price_geom, dialog, tableright), 'psector',
                                'price_geom_ep_canvasClicked_set_price_geom')

    def _set_price_geom(self, dialog, tableright, point: QgsPointXY, button):
        """ Add clicked geom to the_geom column for selected prices """

        if button == Qt.MouseButton.RightButton or point is None:
            global_vars.canvas.setMapTool(self.previous_map_tool)
            return
        # Add clicked geom to the_geom column for selected prices
        # Get selected price
        select_widgets = dialog.tab_other_prices.findChildren(QCheckBox)
        selected_ids = []
        count = 0
        for check in select_widgets:
            if check.isChecked():
                selected_ids.append(check.objectName())
            else:
                count = count + 1
        if len(selected_ids) != 1:
            return
        # Set the_geom
        the_geom = f"ST_SetSRID(ST_Point({point.x()},{point.y()}), {lib_vars.project_epsg})"
        sql = f"UPDATE {tableright} SET the_geom = {the_geom} WHERE id = {selected_ids[0]};"
        status = tools_db.execute_sql(sql)
        if status:
            global_vars.canvas.setMapTool(self.previous_map_tool)
            msg = "Geometry set correctly."
            tools_qgis.show_info(msg, dialog=dialog)

    def query_like_widget_text(self, dialog, text_line, qtable, tableleft, tableright, field_id):
        """ Populate the QTableView by filtering through the QLineEdit """

        schema_name = self.schema_name.replace('"', '')
        psector_id = tools_qt.get_text(dialog, 'tab_general_psector_id')
        query = tools_qt.get_text(dialog, text_line).lower()
        if query == 'null':
            query = ""
        sql = (f"SELECT * FROM {schema_name}.{tableleft} WHERE LOWER ({field_id})"
               f" LIKE '%{query}%' AND {field_id} NOT IN (SELECT price_id FROM {schema_name}.{tableright}"
               f" WHERE psector_id = '{psector_id}')")
        tools_db.fill_table_by_query(qtable, sql)
        tools_gw.set_tablemodel_config(dialog, qtable, tableleft)

    def fill_table(self, dialog, widget, table_name, hidde=False, set_edit_triggers=QTableView.EditTrigger.NoEditTriggers,
                   expr=None, feature_type=None, field_id=None, refresh_table=True):
        """ Set a model with selected filter.
            Attach that model to selected table
            @setEditStrategy:
            0: OnFieldChange
            1: OnRowChange
            2: OnManualSubmit
        """

        # Manage exception if dialog is closed
        if isdeleted(dialog):
            return

        if self.schema_name not in table_name:
            table_name = self.schema_name + "." + table_name

        # Set model
        model = QSqlTableModel(db=lib_vars.qgis_db_credentials)
        model.setTable(table_name)
        model.setEditStrategy(QSqlTableModel.EditStrategy.OnFieldChange)
        model.setSort(0, Qt.SortOrder.AscendingOrder)
        model.select()

        # When change some field we need to refresh Qtableview and filter by psector_id
        # This works for both psector relations AND psector manager table
        model.beforeUpdate.connect(partial(self.manage_update_model_relations, model))
        # model.dataChanged.connect(partial(self.refresh_table, dialog, widget))
        widget.setEditTriggers(set_edit_triggers)

        # Check for errors
        if model.lastError().isValid():
            if 'Unable to find table' in model.lastError().text():
                tools_db.reset_qsqldatabase_connection(dialog)
            else:
                tools_qgis.show_warning(model.lastError().text(), dialog=dialog)
        # Attach model to table view
        if expr:
            widget.setModel(model)
            widget.model().setFilter(expr)
        else:
            widget.setModel(model)

        if hidde:
            self.refresh_table(dialog, widget)
        if feature_type is not None and field_id is not None:
            self._manage_features_geom(widget, feature_type, field_id)

        if self.tablename_psector_x_connec in table_name and refresh_table:
            self.fill_table(self.dlg_plan_psector, self.qtbl_connec, self.tablename_psector_x_connec,
                            set_edit_triggers=QTableView.EditTrigger.DoubleClicked, expr=expr, feature_type="connec",
                            field_id="connec_id", refresh_table=False)
        elif self.project_type == 'ud' and self.tablename_psector_x_gully in table_name and refresh_table:
            self.fill_table(self.dlg_plan_psector, self.qtbl_gully, self.tablename_psector_x_gully,
                            set_edit_triggers=QTableView.EditTrigger.DoubleClicked, expr=expr, feature_type="gully",
                            field_id="gully_id", refresh_table=False)

    def refresh_table(self, dialog, widget):
        """ Refresh qTableView """

        widget.selectAll()
        selected_list = widget.selectionModel().selectedRows()
        widget.clearSelection()
        for i in range(0, len(selected_list)):
            row = selected_list[i].row()
            if str(widget.model().record(row).value('tab_general_psector_id')) != tools_qt.get_text(dialog, 'tab_general_psector_id'):
                widget.hideRow(i)

    def manage_update_model_relations(self, model: QSqlTableModel, row: int, record: QSqlRecord):
        """
        Manage update model relations - INSERT if new, UPDATE if exists
        :param model: QSqlModel of QTableView
        :param row: index of updating row (passed by signal)
        :param record: QSqlRecord (passed by signal)
        """

        # Get the table name from the model
        table_name = model.tableName()
        if not table_name:
            return

        # Build column lists and values for UPSERT operation
        columns = []
        values = []
        update_clauses = []

        for column in range(model.columnCount()):
            column_name = model.headerData(column, Qt.Orientation.Horizontal, Qt.ItemDataRole.DisplayRole)
            if column_name:
                value = record.value(column_name)
                columns.append(column_name)

                if value in [None, 'None', 'null', 'Null', 'NULL', '']:
                    values.append('NULL')
                    if column_name not in self.no_editable_fields:
                        update_clauses.append(f"{column_name} = NULL")
                elif column_name == 'addparam':
                    values.append(f"'{str(value)}'::json")
                    if column_name not in self.no_editable_fields:
                        update_clauses.append(f"{column_name} = '{str(value)}'::json")
                elif column_name == 'insert_tstamp':
                    tstamp_str = value.toString("yyyy-MM-dd HH:mm:ss.zzz")
                    values.append(f"'{tstamp_str}'::timestamp")
                    if column_name not in self.no_editable_fields:
                        update_clauses.append(f"{column_name} = '{tstamp_str}'::timestamp")
                elif isinstance(value, str):
                    # Properly escape values to prevent SQL injection
                    escaped_value = str(value).replace("'", "''")
                    values.append(f"'{escaped_value}'")
                    # Only add to update clause if not in non-editable fields
                    if column_name not in self.no_editable_fields:
                        update_clauses.append(f"{column_name} = '{escaped_value}'")
                else:
                    values.append(str(value).upper())
                    if column_name not in self.no_editable_fields:
                        update_clauses.append(f"{column_name} = {str(value).upper()}")

        # Execute UPSERT operation if we have data
        if columns and values:
            # Try INSERT first, then UPDATE if conflict occurs
            # Using PostgreSQL's ON CONFLICT syntax for UPSERT
            columns_str = ', '.join(columns)
            values_str = ', '.join(values)
            update_str = ', '.join(update_clauses) if update_clauses else columns_str

            # Determine the primary key or unique constraint
            # Most psector tables use 'id' as primary key
            conflict_column = 'id'
            record_id = record.value('id')

            # If no ID, try to use a combination of psector_id and feature_id
            if not record_id:
                psector_id = record.value('psector_id')
                feature_id = None

                # Determine feature ID column based on table name
                if 'arc' in table_name:
                    feature_id = record.value('arc_id')
                    conflict_column = 'psector_id, arc_id'
                elif 'node' in table_name:
                    feature_id = record.value('node_id')
                    conflict_column = 'psector_id, node_id'
                elif 'connec' in table_name:
                    feature_id = record.value('connec_id')
                    conflict_column = 'psector_id, connec_id'
                elif 'gully' in table_name:
                    feature_id = record.value('gully_id')
                    conflict_column = 'psector_id, gully_id'

                if not (psector_id and feature_id):
                    return  # Cannot proceed without proper identifiers

            # Build the UPSERT SQL
            if update_clauses:
                sql = (f"INSERT INTO {table_name} ({columns_str}) "
                       f"VALUES ({values_str}) "
                       f"ON CONFLICT ({conflict_column}) "
                       f"DO UPDATE SET {update_str}")
            else:
                # If no updatable fields, just insert if not exists
                sql = (f"INSERT INTO {table_name} ({columns_str}) "
                       f"VALUES ({values_str}) "
                       f"ON CONFLICT ({conflict_column}) DO NOTHING")

            # Execute the UPSERT
            tools_db.execute_sql(sql)

        # Determine which table widget to refresh based on table name
        widget_to_refresh = None
        table_specific_editable = None
        qtbl_to_refresh = None
        if 'arc' in table_name:
            widget_to_refresh = self.qtbl_arc
            qtbl_to_refresh = self.qtbl_arc
        elif 'node' in table_name:
            widget_to_refresh = self.qtbl_node
            qtbl_to_refresh = self.qtbl_node
        elif 'connec' in table_name:
            widget_to_refresh = self.qtbl_connec
            table_specific_editable = ['arc_id']
            qtbl_to_refresh = self.qtbl_connec
        elif 'gully' in table_name:
            widget_to_refresh = self.qtbl_gully
            table_specific_editable = ['arc_id']
            qtbl_to_refresh = self.qtbl_gully
        # Refresh the appropriate table
        if widget_to_refresh:
            if not hasattr(self, 'psector_id'):
                self.psector_id = tools_qt.get_text(self.dlg_plan_psector, 'tab_general_psector_id')
            filter_ = f"psector_id = '{self.psector_id}'"
            self.fill_table(self.dlg_plan_psector, widget_to_refresh, table_name,
                            set_edit_triggers=QTableView.EditTrigger.DoubleClicked, expr=filter_)
            qtbl_to_refresh.model().flags = lambda index: self.flags(index, qtbl_to_refresh.model(), table_specific_editable=table_specific_editable)

        # Force a map refresh
        tools_qgis.force_refresh_map_canvas()

    def manage_update_state(self, model, row, record):
        """
        Manage new state of planned features.
            :param model: QSqlModel of QTableView
            :param row: index of updating row (passed by signal)
            :param record: QSqlRecord (passed by signal)
        """

        sql = (f"UPDATE {self.tablename_psector_x_connec} SET state = "
               f"{record.value('state')} WHERE id = '{record.value('id')}'")
        tools_db.execute_sql(sql)

        # self._refresh_tables_relations()
        filter_ = "psector_id = '" + str(self.psector_id) + "'"
        self.fill_table(self.dlg_plan_psector, self.qtbl_connec, self.tablename_psector_x_connec,
                        set_edit_triggers=QTableView.EditTrigger.DoubleClicked, expr=filter_)

        # Force a map refresh
        tools_qgis.force_refresh_map_canvas()

        # self.refresh_table(dialog, widget)

        # Get table name via current tab name (arc, node, connec or gully)
        # index_tab = self.dlg_plan_psector.tab_feature.currentIndex()
        # tab_name = self.dlg_plan_psector.tab_feature.tabText(index_tab)
        # table_name = tab_name.lower()
        #
        # # Get selected feature's state
        # feature_id = record.value(f'{table_name}_id')  # Get the id
        # sql = f"SELECT {table_name}.state FROM {table_name} WHERE {table_name}_id='{feature_id}';"
        # sql_row = tools_db.get_row(sql)
        # if sql_row:
        #     old_state = sql_row[0]  # Original state
        #     new_state = record.value('state')  # New state
        #     if old_state == 2 and new_state == 0:
        #         msg = "This value is mandatory for planned feature. If you are looking to unlink feature from this " \
        #               "psector please delete row. If delete is not allowed its because feature is only used on this " \
        #               "psector and needs to be removed from canvas"
        #         tools_qgis.show_warning(msg, dialog=self.dlg_plan_psector)
        #         model.revert()

    def document_insert(self):
        """ Insert a document related to the current visit """

        doc_name = self.doc_id.text()
        psector_id = str(self.psector_id)
        if not doc_name:
            msg = "You need to insert a document name"
            tools_qgis.show_warning(msg, dialog=self.dlg_plan_psector)
            return
        if not psector_id or psector_id == "null":
            msg = "You need to insert psector_id"
            tools_qgis.show_warning(msg, dialog=self.dlg_plan_psector)
            return

        # Get doc_id using doc_name
        sql = f"SELECT id FROM doc WHERE name = '{doc_name}'"
        row = tools_db.get_row(sql)
        if not row:
            msg = "Document name not found"
            tools_qgis.show_warning(msg, dialog=self.dlg_plan_psector)
            return

        doc_id = row['id']

        # Check if document already exist
        sql = (f"SELECT doc_id"
               f" FROM doc_x_psector"
               f" WHERE doc_id = '{doc_id}' AND psector_id = '{psector_id}'")
        row = tools_db.get_row(sql)
        if row:
            msg = "Document already exist"
            tools_qgis.show_warning(msg, dialog=self.dlg_plan_psector)
            return

        # Insert into new table
        sql = (f"INSERT INTO doc_x_psector (doc_id, psector_id)"
               f" VALUES ('{doc_id}', {psector_id})")
        status = tools_db.execute_sql(sql)
        if status:
            msg = "Document inserted successfully"
            tools_qgis.show_info(msg, dialog=self.dlg_plan_psector)

        self.doc_id.clear()
        self.dlg_plan_psector.tbl_document.model().select()

        # Refresh canvas
        tools_qgis.refresh_map_canvas()

    def manage_document(self, qtable):
        """ Access GUI to manage documents e.g Execute action of button 34 """

        psector_id = tools_qt.get_text(self.dlg_plan_psector, "tab_general_psector_id")
        manage_document = GwDocument(single_tool=False)
        dlg_docman = manage_document.get_document(tablename='psector', qtable=qtable, item_id=psector_id)
        dlg_docman.btn_accept.clicked.connect(partial(tools_gw.set_completer_object, dlg_docman, 'doc'))
        tools_qt.remove_tab(dlg_docman.tabWidget, 'tab_rel')

    def master_new_psector(self, psector_id=None):
        """ Button 51: New psector """
        self.get_psector(psector_id)

    def manage_psectors(self):
        """ Button 52: Psector management """

        # Create the dialog and signals
        self.dlg_psector_mng = GwPsectorManagerUi(self)

        tools_gw.load_settings(self.dlg_psector_mng)
        table_name = "v_ui_plan_psector"
        column_id = "psector_id"
        self._original_visibility_state = {}
        self._original_active_layer = None
        self._layer_was_loaded_by_filter = False

        # Tables
        self.qtbl_psm = self.dlg_psector_mng.findChild(QTableView, "tbl_psm")
        self.qtbl_psm.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        tools_qt.set_tableview_config(self.qtbl_psm, section_resize_mode=QHeaderView.ResizeMode.Interactive)

        # Populate custom context menu
        self.dlg_psector_mng.tbl_psm.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.dlg_psector_mng.tbl_psm.customContextMenuRequested.connect(partial(self._show_context_menu_right_click, self.dlg_psector_mng.tbl_psm))

        # Set signals
        self.dlg_psector_mng.chk_active.stateChanged.connect(partial(self._filter_table, self.dlg_psector_mng,
           self.qtbl_psm, self.dlg_psector_mng.txt_name, self.dlg_psector_mng.chk_active, self.dlg_psector_mng.chk_archived, table_name))

        self.dlg_psector_mng.chk_archived.stateChanged.connect(partial(self._filter_table, self.dlg_psector_mng,
           self.qtbl_psm, self.dlg_psector_mng.txt_name, self.dlg_psector_mng.chk_active, self.dlg_psector_mng.chk_archived, table_name))

        self.dlg_psector_mng.chk_filter_canvas.stateChanged.connect(self._toggle_canvas_filter)

        self.dlg_psector_mng.btn_cancel.clicked.connect(self._handle_dialog_close)
        self.dlg_psector_mng.btn_toggle_active.clicked.connect(partial(self.set_toggle_active, self.dlg_psector_mng, self.qtbl_psm))
        self.dlg_psector_mng.btn_restore.clicked.connect(partial(self.restore_psector, self.dlg_psector_mng, self.qtbl_psm))
        self.dlg_psector_mng.rejected.connect(self._handle_dialog_close)
        self.dlg_psector_mng.btn_delete.clicked.connect(partial(
            self.multi_rows_delete, self.dlg_psector_mng, self.qtbl_psm, table_name, column_id, 'lbl_vdefault_psector', 'psector'))
        self.dlg_psector_mng.btn_delete.clicked.connect(partial(tools_gw.refresh_selectors))
        self.dlg_psector_mng.btn_show.clicked.connect(self._show_psector)

        self.dlg_psector_mng.btn_update_psector.clicked.connect(
            partial(self.update_current_psector, self.dlg_psector_mng, qtbl=self.qtbl_psm, scenario_type="psector",
                col_id_name="psector_id"))

        self.dlg_psector_mng.btn_duplicate.clicked.connect(self.psector_duplicate)
        self.dlg_psector_mng.btn_merge.clicked.connect(self.psector_merge)
        self.dlg_psector_mng.txt_name.textChanged.connect(partial(
           self._filter_table, self.dlg_psector_mng, self.qtbl_psm, self.dlg_psector_mng.txt_name,
           self.dlg_psector_mng.chk_active, self.dlg_psector_mng.chk_archived, table_name))
        self.dlg_psector_mng.tbl_psm.doubleClicked.connect(partial(self.charge_psector, self.qtbl_psm))
        self.fill_table(self.dlg_psector_mng, self.qtbl_psm, table_name, expr=' active is True AND archived is False')
        self._filter_table(self.dlg_psector_mng, self.qtbl_psm, self.dlg_psector_mng.txt_name, self.dlg_psector_mng.chk_active, self.dlg_psector_mng.chk_archived, table_name)
        tools_gw.set_tablemodel_config(self.dlg_psector_mng, self.qtbl_psm, table_name)
        selection_model = self.qtbl_psm.selectionModel()
        selection_model.selectionChanged.connect(partial(self._fill_txt_infolog))
        self.set_label_current_psector(self.dlg_psector_mng, scenario_type="psector", from_open_dialog=True)

        if tools_gw.get_config_parser('btn_psector_manager', 'active_filter', 'user', 'session') == 'True':
            self.dlg_psector_mng.chk_active.setChecked(True)
        if tools_gw.get_config_parser('btn_psector_manager', 'archived_filter', 'user', 'session') == 'True':
            self.dlg_psector_mng.chk_archived.setChecked(True)

        # Open form
        tools_gw.open_dialog(self.dlg_psector_mng, dlg_name="psector_manager")
        self.dlg_psector_mng.btn_create.clicked.connect(partial(self.open_psector_dlg))

    def _show_context_menu_right_click(self, qtableview, pos):
        """ Show custom context menu """
        menu = QMenu(qtableview)

        title = "Open"
        action_open = QAction(tools_qt.tr(title), qtableview)
        action_open.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QTableView, qtableview.objectName(), pos))
        menu.addAction(action_open)

        title = "Psector actual"
        action_actual_psector = QAction(tools_qt.tr(title), qtableview)
        action_actual_psector.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_update_psector"))
        menu.addAction(action_actual_psector)

        title = "Show"
        action_show = QAction(tools_qt.tr(title), qtableview)
        action_show.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_show"))
        menu.addAction(action_show)

        title = "Toggle active"
        action_toggle_active = QAction(tools_qt.tr(title), qtableview)
        action_toggle_active.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_toggle_active"))
        menu.addAction(action_toggle_active)

        title = "Merge"
        action_merge = QAction(tools_qt.tr(title), qtableview)
        action_merge.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_merge"))
        menu.addAction(action_merge)

        title = "Duplicate"
        action_duplicate = QAction(tools_qt.tr(title), qtableview)
        action_duplicate.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_duplicate"))
        menu.addAction(action_duplicate)

        title = "Delete"
        action_delete = QAction(tools_qt.tr(title), qtableview)
        action_delete.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_delete"))
        menu.addAction(action_delete)

        menu.exec(QCursor.pos())

    def open_psector_dlg(self):
        self.get_psector()

    def set_toggle_active(self, dialog, qtbl_psm):

        sql = ""
        selector_updated = False
        selected_list = qtbl_psm.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return
        for i in range(0, len(selected_list)):
            row = selected_list[i].row()
            psector_id = qtbl_psm.model().record(row).value("psector_id")
            # psector_name = qtbl_psm.model().record(row).value("name")
            active = qtbl_psm.model().record(row).value("active")
            archived = qtbl_psm.model().record(row).value("archived")
            if archived is True:
                msg = "Cannot set the active state of archived psector {0}. Please unarchive it first."
                msg_params = (psector_id,)
                tools_qgis.show_warning(msg, dialog=dialog, msg_params=msg_params)
                return

            if active:
                sql += f"UPDATE plan_psector SET active = False WHERE psector_id = {psector_id};"
            else:
                sql = ("UPDATE config_param_user "
                        "SET value = True "
                        "WHERE parameter = 'plan_psector_disable_checktopology_trigger' AND cur_user=current_user")
                tools_db.execute_sql(sql)

                # Check topology
                # result = self.check_topology_psector(psector_id, psector_name, from_toggle=True)
                # if result is False:
                    # return

                sql = f"UPDATE plan_psector SET active = True WHERE psector_id = {psector_id};"
                tools_db.execute_sql(sql)

                sql = ("UPDATE config_param_user "
                        "SET value = False "
                        "WHERE parameter = 'plan_psector_disable_checktopology_trigger' AND cur_user=current_user")
                tools_db.execute_sql(sql)

        tools_db.execute_sql(sql)

        # Refresh table with both filters
        self._filter_table(dialog, dialog.tbl_psm, dialog.txt_name, dialog.chk_active, dialog.chk_archived, 'v_ui_plan_psector')

        # Load existing psector
        self.load_psector(dialog, psector_id)

        if selector_updated:
            tools_qgis.force_refresh_map_canvas()
            tools_gw.refresh_selectors()

    def restore_psector(self, dialog, qtbl_psm):
        """ Recover the selected archived psector """

        selected_list = qtbl_psm.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return
        row = selected_list[0].row()
        psector_id = qtbl_psm.model().record(row).value("psector_id")
        archived = qtbl_psm.model().record(row).value("archived")
        if archived is False:
            msg = "Psector is not archived"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        extras = f'"psectorId": "{psector_id}"'
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_plan_recover_archived', body)
        if not json_result or 'body' not in json_result or 'data' not in json_result['body'] or json_result.get('status') == 'Failed':
            return

        # Refresh the table to show updated status
        self._filter_table(dialog, qtbl_psm, dialog.txt_name, dialog.chk_active, dialog.chk_archived, 'v_ui_plan_psector')
        tools_gw.refresh_selectors()

    def update_current_psector(self, dialog, qtbl, scenario_type, col_id_name):
        """ Sets the selected psector as current if it is active """
        # Get selected rows in the table
        selected_list = qtbl.selectionModel().selectedRows()

        # Check if any row is selected
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        # Get the first selected row and retrieve psector_id and active status
        row = selected_list[0].row()
        model = qtbl.model()
        col_id = tools_qt.get_col_index_by_col_name(qtbl, col_id_name)
        col_parent_id = tools_qt.get_col_index_by_col_name(qtbl, 'parent_id')

        # Access the data using the model's index method
        scenario_id = model.index(row, col_id).data()
        parent_id = model.index(row, col_parent_id).data()

        # Prepare the JSON body for gw_fct_set_toggle_current
        extras = f'"type": "{scenario_type}", "id": "{scenario_id}"'
        body = tools_gw.create_body(extras=extras)

        # Execute the stored procedure
        result = tools_gw.execute_procedure("gw_fct_set_toggle_current", body)

        # Check if the stored procedure returned a successful status
        if result.get("status") == "Accepted":
            # Refresh the table view and set the label for the current psector
            self.set_label_current_psector(dialog, result=result)
        else:
            # If the procedure fails, show a warning
            msg = "Failed to set psector {0} as current"
            msg_params = (scenario_id,)
            tools_qgis.show_warning(msg, dialog=dialog, msg_params=msg_params)

        cur_psector = tools_gw.get_config_value('plan_psector_current')
        sql = f"DELETE FROM selector_psector WHERE psector_id = {scenario_id} AND cur_user = current_user; "
        if parent_id and parent_id is not None:
            sql += f"DELETE FROM selector_psector WHERE psector_id = {parent_id} AND cur_user = current_user; "
        if cur_psector and cur_psector[0] is not None:
            sql += f"INSERT INTO selector_psector (psector_id, cur_user) VALUES ({scenario_id}, current_user) ON CONFLICT (psector_id, cur_user) DO NOTHING;"
            if parent_id and parent_id is not None:
                sql += f"INSERT INTO selector_psector (psector_id, cur_user) VALUES ({parent_id}, current_user) ON CONFLICT (psector_id, cur_user) DO NOTHING;"
        tools_db.execute_sql(sql)

        # Load existing psector
        self.load_psector(dialog, scenario_id)

    def _filter_table(self, dialog, table, widget_txt, chk_active=None, chk_archived=None, tablename=None):

        result_select = tools_qt.get_text(dialog, widget_txt)

        # Get checkbox states safely
        try:
            active_checked = chk_active.isChecked()
            archive_checked = chk_archived.isChecked()
        except RuntimeError:
            return

        expr = ""

        # Handle archived and active filter
        if not archive_checked and not active_checked:
            expr += " archived is false and active is true"
        elif archive_checked and not active_checked:
            expr += " archived is true or active is true"
        elif active_checked and not archive_checked:
            expr += " (archived is false and active is false) or active is true"

        if result_select != 'null':
            if expr != "":
                expr += " AND "
            expr += f" name ILIKE '%{result_select}%'"
        if expr != "":
            # Refresh model with selected filter
            table.model().setFilter(expr)
            table.model().select()
        else:
            self.fill_table(dialog, table, tablename)

    def _toggle_canvas_filter(self):
        """
        Toggles the filter on or off based on checkbox state.
        Saves visibility state, connects/disconnects filter, and updates the table.
        """
        try:
            is_checked = self.dlg_psector_mng.chk_filter_canvas.isChecked()
        except RuntimeError:
            msg = "Please close all 'Psector manager' dialogs and try again"
            tools_qgis.show_warning(msg, dialog=self.dlg_psector_mng)
            return

        if is_checked:
            # Save initial visibility of target layer
            self._save_visibility_state('ve_plan_psector')

            # Ensure layer is loaded and visible
            self._enable_layers_for_filtering()

            # Connect filter to canvas updates
            self.canvas.mapCanvasRefreshed.connect(self._apply_canvas_filter)

            # Apply filter based on current canvas extent
            self._apply_canvas_filter()
        else:
            # Restore original visibility states
            self._restore_visibility_state()

            try:
                self.canvas.mapCanvasRefreshed.disconnect(self._apply_canvas_filter)
            except TypeError:
                pass  # Ignore if already disconnected

            # Apply filter to table
            self._filter_table(self.dlg_psector_mng, self.qtbl_psm, self.dlg_psector_mng.txt_name, self.dlg_psector_mng.chk_active, self.dlg_psector_mng.chk_archived, 'v_ui_plan_psector')

    def _apply_canvas_filter(self):
        """Filters the psector layer by the current map extent, updating visible features in the table."""

        # Get current map canvas extent
        canvas_extent = self.iface.mapCanvas().extent()
        # Retrieve the target layer
        psector_layer = tools_qgis.get_layer_by_tablename('ve_plan_psector')

        # Find features within the current extent
        visible_feature_ids = []
        for feature in psector_layer.getFeatures():
            if canvas_extent.intersects(feature.geometry().boundingBox()):
                visible_feature_ids.append(feature.id())
        self._update_psector_manager_table(visible_feature_ids)

    def _update_psector_manager_table(self, visible_ids):
        """Filters the table to show only features with IDs in `visible_ids`."""

        model = self.dlg_psector_mng.tbl_psm.model()

        if visible_ids:
            # Create a filter string for SQL that matches only the visible IDs
            id_list_str = ",".join(map(str, visible_ids))
            filter_expression = f"psector_id IN ({id_list_str})"
        else:
            # Set filter to an impossible condition to show nothing in the table
            filter_expression = "psector_id IN (NULL)"

        # Apply the filter to the model
        model.setFilter(filter_expression)

    def _enable_layers_for_filtering(self):
        """Ensures `ve_plan_psector` is loaded and visible in QGIS."""

        plan_layer = tools_qgis.get_layer_by_tablename('ve_plan_psector')
        if not plan_layer:
            # Load layer if not present in project
            self._load_layer_to_project('ve_plan_psector', "the_geom", "psector_id")
            # Reload reference after adding
            plan_layer = tools_qgis.get_layer_by_tablename('ve_plan_psector')
            self._layer_was_loaded_by_filter = True
        if plan_layer:
            self._activate_layer(plan_layer)

    def _load_layer_to_project(self, tablename, geom_field, field_id):
        """Loads a specified database layer yo load ve_plan_psector."""

        tools_gw.add_layer_database(tablename=tablename, the_geom=geom_field, field_id=field_id)

    def _activate_layer(self, layer):
        """Makes the layer and its parent groups visible and sets it as active."""

        root = self.iface.layerTreeCanvasBridge().rootGroup()
        layer_node = root.findLayer(layer.id())
        if layer_node:
            layer_node.setItemVisibilityChecked(True)  # Ensure layer is visible
            # Ensure visibility for parent groups up to root
            parent = layer_node.parent()
            while parent:
                parent.setItemVisibilityChecked(True)
                parent = parent.parent()
            self.iface.setActiveLayer(layer)  # Set as active layer in QGIS

    def _save_visibility_state(self, tablename):
        """Saves visibility of the layer and its parent groups, and the currently active layer."""

        # Save currently active layer
        self._original_active_layer = self.iface.activeLayer()

        layer = tools_qgis.get_layer_by_tablename(tablename)
        if layer:
            root = self.iface.layerTreeCanvasBridge().rootGroup()
            layer_node = root.findLayer(layer.id())
            if layer_node:
                # If layer was not visible, treat it like it was loaded by filter
                if not layer_node.isVisible():
                    self._layer_was_loaded_by_filter = True
                    return
                # Store visibility state
                while layer_node:
                    self._original_visibility_state[layer_node.name()] = layer_node.isVisible()
                    layer_node = layer_node.parent()

    def _restore_visibility_state(self):
        """Restores saved visibility state of layers and groups, and the previously active layer."""

        plan_layer = tools_qgis.get_layer_by_tablename('ve_plan_psector')
        was_loaded_by_filter = self._layer_was_loaded_by_filter

        # If layer was loaded by filter, hide it instead of restoring
        if was_loaded_by_filter:
            if plan_layer:
                root = self.iface.layerTreeCanvasBridge().rootGroup()
                layer_node = root.findLayer(plan_layer.id())
                if layer_node:
                    layer_node.setItemVisibilityChecked(False)
            self._layer_was_loaded_by_filter = False
        else:
            # Restore saved visibility states
            root = self.iface.layerTreeCanvasBridge().rootGroup()
            for name, is_visible in self._original_visibility_state.items():
                node = root.findGroup(name) or root.findLayer(name)
                if node:
                    node.setItemVisibilityChecked(is_visible)

        # Restore previously active layer (but not if it was ve_plan_psector and we just hid it)
        if self._original_active_layer:
            if plan_layer and self._original_active_layer == plan_layer and was_loaded_by_filter:
                # Don't restore ve_plan_psector as active if we just hid it
                pass
            else:
                self.iface.setActiveLayer(self._original_active_layer)

    def _handle_dialog_close(self):
        """
        Handles the dialog close event, ensuring the checkbox is unchecked
        and the filter is disabled if it was still active.
        """
        try:
            tools_gw.set_config_parser('btn_psector_manager', 'active_filter', self.dlg_psector_mng.chk_active.isChecked())
            tools_gw.set_config_parser('btn_psector_manager', 'archived_filter', self.dlg_psector_mng.chk_archived.isChecked())

            if self.dlg_psector_mng.chk_filter_canvas.isChecked():
                # Uncheck the checkbox and disable the filter
                self.dlg_psector_mng.chk_filter_canvas.setChecked(False)
                # Disable filter and restore visibility
                self._toggle_canvas_filter()

            # Accept the close event to allow the dialog to close
            tools_gw.close_dialog(self.dlg_psector_mng)
        except RuntimeError:
            pass

    def charge_psector(self, qtbl_psm):

        selected_list = qtbl_psm.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_psector_mng)
            return
        row = selected_list[0].row()
        active = qtbl_psm.model().record(row).value("active")
        psector_id = qtbl_psm.model().record(row).value("psector_id")
        archived = qtbl_psm.model().record(row).value("archived")
        cur_psector = tools_gw.get_config_value('plan_psector_current')
        keep_open_form = tools_gw.get_config_parser('dialogs_actions', 'psector_manager_keep_open', "user", "init", prefix=True)
        if tools_os.set_boolean(keep_open_form, False) is not True:
            self._handle_dialog_close()

        # Only current psectors are editable, archived psectors are never editable
        is_current = cur_psector and cur_psector[0] is not None and int(cur_psector[0]) == psector_id
        if archived is True:
            self.psector_editable = False
        elif is_current:
            self.psector_editable = True
        else:
            # Ask user if they want to set this psector as current
            msg = "Do you want to set this psector as current?"
            result = tools_qt.show_question(msg, title="Info", context_name="giswater", force_action=True,
                                           buttons=["Yes", "No"])
            if result:
                self.update_current_psector(self.dlg_psector_mng, qtbl=self.qtbl_psm, scenario_type="psector", col_id_name="psector_id")
                self.psector_editable = True
            else:
                self.psector_editable = False

        if active is True:
            # put psector on selector_psector
            sql = f"DELETE FROM selector_psector WHERE psector_id = {psector_id} AND cur_user = current_user;" \
                f"INSERT INTO selector_psector (psector_id, cur_user) VALUES ({psector_id}, current_user);"
            tools_db.execute_sql(sql)
        # Open form
        self.master_new_psector(psector_id)

        # Refresh canvas
        tools_qgis.refresh_map_canvas()

    def _show_psector(self):

        selected_rows = self.qtbl_psm.selectionModel().selectedRows()
        if len(selected_rows) == 0:
            msg = "No psector selected. Please select at least one."
            tools_qgis.show_warning(msg, dialog=self.dlg_psector_mng)
            return
        elif len(selected_rows) > 1:
            msg = "Multiple psectors selected. Please select only one."
            tools_qgis.show_warning(msg, dialog=self.dlg_psector_mng)
            return

        # Get selected psector_id from the first column (adjust index if needed)
        psector_id = selected_rows[0].data()

        # Call the SQL function to get the sector features
        extras = f'"psector_id":"{psector_id}"'
        body = tools_gw.create_body(extras=extras)
        result = tools_gw.execute_procedure('gw_fct_getpsectorfeatures', body)

        # Check for valid result
        if not result or result.get('status') != 'Accepted':
            msg = "Failed to retrieve sector features."
            tools_qgis.show_warning(msg, dialog=self.dlg_psector_mng)
            return

        # Load existing psector
        self.load_psector(self.dlg_psector_mng, psector_id)

        # The SQL procedure manage creating the temporal layers based on the returned features
        msg = "Psector features loaded successfully on the map."
        tools_qgis.show_success(msg, dialog=self.dlg_psector_mng)

    def multi_rows_delete(self, dialog, widget, table_name, column_id, label, action):
        """
        Delete selected elements of the table
            :param dialog: (QDialog)
            :param QTableView widget: origin
            :param table_name: table origin
            :param column_id: Refers to the id of the source table
        """
        # Get selected rows
        selected_list = widget.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return
        cur_psector = tools_gw.get_config_value('plan_psector_current')
        inf_text = ""
        list_id = ""
        for i in range(0, len(selected_list)):
            row = selected_list[i].row()
            id_ = widget.model().record(row).value(str(column_id))
            if cur_psector and cur_psector[0] is not None and (str(id_) == str(cur_psector[0])):
                msg = ("You are trying to delete your current psector. "
                        "Please, change your current psector before delete.")
                title = "Current psector"
                tools_qt.show_exception_message(title, msg)
                return
            inf_text += f'"{id_}", '
            list_id += f'"{id_}", '
        inf_text = inf_text[:-2]
        list_id = list_id[:-2]

        if action == 'psector':
            feature = f'"id":[{inf_text}], "featureType":"PSECTOR"'
            body = tools_gw.create_body(feature=feature)
            result = tools_gw.execute_procedure('gw_fct_getcheckdelete', body)
            if result is not None and result['status'] == "Accepted":
                if result['message']:
                    answer = tools_qt.show_question(result['message']['text'])
                    if answer:
                        feature += f', "tableName":"{table_name}", "idName":"{column_id}"'
                        body = tools_gw.create_body(feature=feature)
                        tools_gw.execute_procedure('gw_fct_setdelete', body)
                        tools_gw.fill_cmb_psector_id(global_vars.psignals['widgets'][1])

        elif action == 'price':
            msg = "Are you sure you want to delete these records?"
            answer = tools_qt.show_question(msg, "Delete records", inf_text)
            if answer:
                sql = "DELETE FROM selector_plan_result WHERE result_id in ("
                if list_id != '':
                    sql += f"{list_id}) AND cur_user = current_user;"
                    tools_db.execute_sql(sql)
                    tools_qt.set_widget_text(dialog, label, '')
                sql = (f"DELETE FROM {table_name}"
                       f" WHERE {column_id} IN ({list_id});")
                tools_db.execute_sql(sql)
        widget.model().select()

    def _show_context_menu(self, pos):
        """ Show custom context menu """
        menu = QMenu(self.tbl_om_result_cat)

        title = "Current Result"
        action_set_current = QAction(tools_qt.tr(title), self.tbl_om_result_cat)
        action_set_current.triggered.connect(partial(self.update_price_vdefault))
        menu.addAction(action_set_current)

        title = "Delete"
        action_delete = QAction(tools_qt.tr(title), self.tbl_om_result_cat)
        action_delete.triggered.connect(partial(self.delete_merm, self.dlg_merm))
        menu.addAction(action_delete)

        menu.exec(QCursor.pos())

    def update_price_vdefault(self):

        selected_list = self.dlg_merm.tbl_om_result_cat.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_merm)
            return
        row = selected_list[0].row()
        price_name = self.dlg_merm.tbl_om_result_cat.model().record(row).value("name")
        result_id = self.dlg_merm.tbl_om_result_cat.model().record(row).value("result_id")
        tools_qt.set_widget_text(self.dlg_merm, 'lbl_vdefault_price', price_name)
        sql = (f"DELETE FROM selector_plan_result WHERE current_user = cur_user;"
               f"\nINSERT INTO selector_plan_result (result_id, cur_user)"
               f" VALUES({result_id}, current_user);")
        status = tools_db.execute_sql(sql)
        if status:
            msg = "Values has been updated"
            tools_qgis.show_info(msg, dialog=self.dlg_merm)

        # Refresh canvas
        self.iface.mapCanvas().refreshAllLayers()

    def delete_merm(self, dialog):
        """ Delete selected row from 'manage_prices' dialog from selected tab """

        self.multi_rows_delete(dialog, dialog.tbl_om_result_cat, 'plan_result_cat',
                               'result_id', 'lbl_vdefault_price', 'price')

    def filter_merm(self, dialog, tablename):
        """ Filter rows from 'manage_prices' dialog from selected tab """

        self._filter_table(dialog, dialog.tbl_om_result_cat, dialog.txt_name, dialog.chk_active, dialog.chk_archived, tablename)

    def psector_merge(self):
        """ Merges the selected psectors """

        # Get selected row
        selected_list = self.qtbl_psm.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_psector_mng)
            return

        if len(selected_list) == 1:
            msg = "Merge requires at least 2 psectors to be selected"
            tools_qgis.show_info(msg, dialog=self.dlg_psector_mng)
            return

        for i in range(0, len(selected_list)):
            row = selected_list[i].row()
            archived = self.qtbl_psm.model().record(row).value("archived")
            id_feature = self.qtbl_psm.model().record(row).value("psector_id")
            if archived is True:
                msg = "Cannot merge archived psector {0}. Please unarchive it first."
                msg_params = (id_feature,)
                tools_qgis.show_warning(msg, dialog=self.dlg_psector_mng, msg_params=msg_params)
                return

        # Get selected dscenario id
        value = ""
        for i in range(0, len(selected_list)):
            row = selected_list[i].row()
            # Id to delete
            id_feature = self.qtbl_psm.model().record(row).value("psector_id")
            value += str(id_feature) + ", "
        value = value[:-2]

        # Execute toolbox function
        dlg_functions = self._open_toolbox_function(3284)
        # Set psector ids in txt psector_ids
        tools_qt.set_widget_text(dlg_functions, 'psector_ids', f"{value}")
        tools_qt.set_widget_enabled(dlg_functions, 'psector_ids', False)

    def psector_duplicate(self):
        """" Button 51: Duplicate psector """

        selected_list = self.qtbl_psm.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_psector_mng)
            return

        row = selected_list[0].row()
        psector_id = self.qtbl_psm.model().record(row).value("psector_id")
        # psector_name = self.qtbl_psm.model().record(row).value("name")
        archived = self.qtbl_psm.model().record(row).value("archived")
        if archived is True:
            msg = "Cannot duplicate archived psector {0}. Please unarchive it first."
            msg_params = (psector_id,)
            tools_qgis.show_warning(msg, dialog=self.dlg_psector_mng, msg_params=msg_params)
            return
        self.duplicate_psector = GwPsectorDuplicate()
        self.duplicate_psector.is_duplicated.connect(partial(self.fill_table, self.dlg_psector_mng, self.qtbl_psm, 'v_ui_plan_psector'))
        self.duplicate_psector.is_duplicated.connect(partial(self.set_label_current_psector, self.dlg_psector_mng, scenario_type="psector", from_open_dialog=True))
        # self.duplicate_psector.is_duplicated.connect(partial(self.check_topology_psector, psector_id, psector_name))
        self.duplicate_psector.is_duplicated.connect(partial(self.load_psector, self.duplicate_psector, psector_id))
        self.duplicate_psector.manage_duplicate_psector(psector_id)

    def set_label_current_psector(self, dialog, scenario_type=None, from_open_dialog=False, result=None):
        """
        Sets the label for the current psector scenario by retrieving its name.

        If `from_open_dialog` is True, the function calls `gw_fct_set_toggle_current`
        to retrieve the name based on `scenario_type` only. Otherwise, it
        uses the provided `result`.

        It also respects the selector settings using `gw_fct_getselectors`.
        """

        # Get current psector
        cur_psector = tools_gw.get_config_value('plan_psector_current')

        # If called from open dialog, retrieve the current psector without updating config_param_user
        if from_open_dialog:
            # Prepare the JSON body to get the current psector of the given type
            extras = f'"type": "{scenario_type}"'
            body = tools_gw.create_body(extras=extras)

            # Execute the stored procedure to retrieve the current psector information
            result = tools_gw.execute_procedure("gw_fct_set_toggle_current", body)
            if not result or result.get("status") != "Accepted":
                return

        # Extract and set the name from the result, regardless of how it was obtained
        try:
            # Retrieve the 'name' value from the result and set it on the dialog label
            name_value = result["body"]["data"]["name"]
            tools_qt.set_widget_text(dialog, 'lbl_vdefault_psector', name_value)

            # Retrieve the psector ID for use in the extras configuration
            psector_id = result["body"]["data"]["psector_id"]

            enabled = bool(cur_psector and cur_psector[0] is not None)

            if self.psector_with_current is None and lib_vars.plugin_dir:
                self.icon_folder = f"{lib_vars.plugin_dir}{os.sep}icons{os.sep}dialogs{os.sep}"
                self.psector_with_current = QPixmap(f"{self.icon_folder}140.png")
                self.psector_without_current = QPixmap(f"{self.icon_folder}138.png")
            if self.psector_with_current:
                if enabled:
                    dialog.lbl_status_current.setPixmap(self.psector_with_current)
                else:
                    dialog.lbl_status_current.setPixmap(self.psector_without_current)
            tools_gw.set_psector_mode_enabled(enable=enabled, psector_id=psector_id, do_call_fct=False, force_change=True)
        except KeyError:
            msg = "Error: '{0}' or '{1}' field is missing in the result."
            msg_params = ("name", "psector_id",)
            tools_log.log_warning(msg, msg_params)
            return

    def zoom_to_selected_features(self, layer, feature_type=None, zoom=None):
        """ Zoom to selected features of the @layer with @feature_type """

        if not layer:
            return

        global_vars.iface.setActiveLayer(layer)
        global_vars.iface.actionZoomToSelected().trigger()

        if feature_type and zoom:

            # Set scale = scale_zoom
            if feature_type in ('node', 'connec', 'gully'):
                scale = zoom

            # Set scale = max(current_scale, scale_zoom)
            elif feature_type == 'arc':
                scale = global_vars.iface.mapCanvas().scale()
                if int(scale) < int(zoom):
                    scale = zoom
            else:
                scale = 5000

            if zoom is not None:
                scale = zoom

            global_vars.iface.mapCanvas().zoomScale(float(scale))

    # region private functions

    def _fill_txt_infolog(self, selected):
        """
         Fill txt_infolog from epa_result_manager form with current data selected for columns:
             'name', 'priority', 'status', 'exploitation', 'type', 'descript', 'text1', 'text2', 'observ'
         """

        # Get id of selected row
        row = selected.indexes()
        if not row:
            return

        msg = ""

        cols = ['Name', 'Priority', 'Status', 'expl_id', 'Descript', 'text1', 'text2', 'Observ']

        for col in cols:
            # Get column index for column
            col_ind = tools_qt.get_col_index_by_col_name(self.qtbl_psm, f"{col.lower()}")
            text = f'{row[col_ind].data()}'
            msg += f"<b>{col}: </b><br>{text}<br><br>"

        # Set message text into widget
        tools_qt.set_widget_text(self.dlg_psector_mng, 'tab_log_txt_infolog', msg)

    def _refresh_tables_relations(self):
        # Refresh tableview tbl_psector_x_arc, tbl_psector_x_connec, tbl_psector_x_gully
        tools_gw.load_tableview_psector(self.dlg_plan_psector, 'arc')
        tools_gw.load_tableview_psector(self.dlg_plan_psector, 'node')
        tools_gw.load_tableview_psector(self.dlg_plan_psector, 'connec')
        if self.project_type.upper() == 'UD':
            tools_gw.load_tableview_psector(self.dlg_plan_psector, 'gully')
        tools_gw.set_tablemodel_config(self.dlg_plan_psector, "tbl_psector_x_arc", self.tablename_psector_x_arc)
        tools_gw.set_tablemodel_config(self.dlg_plan_psector, "tbl_psector_x_node", self.tablename_psector_x_node)
        tools_gw.set_tablemodel_config(self.dlg_plan_psector, "tbl_psector_x_connec", self.tablename_psector_x_connec)
        if self.project_type.upper() == 'UD':
            tools_gw.set_tablemodel_config(self.dlg_plan_psector, "tbl_psector_x_gully", self.tablename_psector_x_gully)
        self.reset_relation_tables_signals()

    def _check_layers_visible(self, layer_name, the_geom, field_id):
        """ Check layers visibility and add it if it is not in the toc """

        layer = tools_qgis.get_layer_by_tablename(layer_name)
        if layer is None:
            tools_gw.add_layer_database(layer_name, the_geom, field_id)
        if layer and QgsProject.instance().layerTreeRoot().findLayer(layer).isVisible() is False:
            tools_qgis.set_layer_visible(layer, True, True)

    def _manage_tab_feature_buttons(self):
        """ Update rel_feature_type when tab changes to ensure buttons work on all tabs """

        tab_idx = self.dlg_plan_psector.tab_feature.currentIndex()
        tab_name = {'tab_arc': 'arc', 'tab_node': 'node', 'tab_connec': 'connec', 'tab_gully': 'gully',
                    'tab_elem': 'element', 'tab_link': 'link'}
        self.rel_feature_type = tab_name.get(self.dlg_plan_psector.tab_feature.widget(tab_idx).objectName(), 'arc')

    def _reset_snapping(self):
        tools_qgis.disconnect_snapping(True, self.emit_point, self.vertex_marker)

    def _manage_btn_toggle(self, dialog):
        """ Fill btn_toggle QMenu """

        # Functions
        values = [[0, "Toggle doable"]]

        # Create and populate QMenu
        toggle_menu = QMenu()
        for value in values:
            idx = value[0]
            label = value[1]
            action = toggle_menu.addAction(f"{label}")
            action.triggered.connect(partial(self._toggle_feature_psector, dialog, idx))

        dialog.btn_toggle.setMenu(toggle_menu)

    def _toggle_feature_psector(self, dialog, idx):
        """ Delete features_id to table plan_@feature_type_x_psector"""

        tab_idx = dialog.tab_feature.currentIndex()
        feature_type = dialog.tab_feature.tabText(tab_idx).lower()
        qtbl_feature = dialog.findChild(QTableView, f"tbl_psector_x_{feature_type}")

        # Get psector_id from dialog (works for both new and existing psectors)
        selected_psector = tools_qt.get_text(dialog, 'tab_general_psector_id')
        if not selected_psector:
            msg = "Psector ID not found"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        list_tables = {'arc': self.tablename_psector_x_arc, 'node': self.tablename_psector_x_node,
                       'connec': self.tablename_psector_x_connec, 'gully': self.tablename_psector_x_gully}

        sql = ""
        selected_list = qtbl_feature.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_psector_mng)
            return

        if idx == 0:
            model = qtbl_feature.model()
            for i in range(0, len(selected_list)):
                row = selected_list[i].row()

                # Handle both QSqlTableModel and QStandardItemModel
                if isinstance(model, QSqlTableModel):
                    feature_id = model.record(row).value(f"{feature_type}_id")
                    state = model.record(row).value("state")
                    doable = model.record(row).value("doable")
                elif isinstance(model, QStandardItemModel):
                    feature_id_idx = model.index(row, tools_qt.get_col_index_by_col_name(qtbl_feature, f"{feature_type}_id"))
                    state_idx = model.index(row, tools_qt.get_col_index_by_col_name(qtbl_feature, "state"))
                    doable_idx = model.index(row, tools_qt.get_col_index_by_col_name(qtbl_feature, "doable"))
                    feature_id = model.data(feature_id_idx)
                    state = model.data(state_idx)
                    doable = model.data(doable_idx)
                else:
                    continue

                # Skip if we couldn't get required data
                if feature_id is None or state is None:
                    continue

                if doable:
                    sql += f"UPDATE {list_tables[feature_type]} SET doable = False WHERE {feature_type}_id = '{feature_id}' AND psector_id = {selected_psector} AND state = '{state}';"
                else:
                    sql += f"UPDATE {list_tables[feature_type]} SET doable = True WHERE {feature_type}_id = '{feature_id}' AND psector_id = {selected_psector} AND state = '{state}';"
        else:
            return

        if sql:
            tools_db.execute_sql(sql)
            tools_gw.load_tableview_psector(dialog, feature_type)
            tools_gw.set_model_signals(self)

    def _manage_features_geom(self, qtable, feature_type, field_id):
        tools_gw.reset_rubberband(self.rubber_band_op)
        ids = []
        table_model = qtable.model()
        for row_index in range(table_model.rowCount()):
            column_index = tools_qt.get_col_index_by_col_name(qtable, "state")
            if table_model.record(row_index).value(column_index) != 0:
                continue
            column_index = tools_qt.get_col_index_by_col_name(qtable, field_id)
            _id = table_model.record(row_index).value(column_index)
            ids.append(_id)

        if not ids:
            return
        ids_str = json.dumps(ids).replace('"', '')
        extras = f'"feature_type": "{feature_type}", "ids": "{ids_str}"'
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_getfeaturegeom', body)
        if not json_result or json_result.get("status") != "Accepted":
            return

        self.feature_geoms[feature_type] = json_result['body']['data']

    def _highlight_features_by_id(self, qtable, feature_type, field_id, rubber_band, width, state_value=1):
        """
        Highlight features by id based on their state

        Args:
            state_value: 1 = operative (orange), 0 = obsolete (light blue)
        """

        rubber_band.reset()

        # Define colors based on state
        color = self.OPERATIVE_COLOR if state_value == 1 else self.OBSOLETE_COLOR

        ids = []
        for _, index in enumerate(qtable.selectionModel().selectedRows()):
            row = index.row()

            # Filter by state
            column_index = tools_qt.get_col_index_by_col_name(qtable, "state")
            if index.sibling(row, column_index).data() != state_value:
                continue

            # Get the feature ID
            column_index = tools_qt.get_col_index_by_col_name(qtable, field_id)
            _id = index.sibling(row, column_index).data()
            ids.append(str(_id))

        if not ids:
            return

        # Get geometries from database
        ids_str = "','".join(ids)
        sql = f"SELECT {field_id}, ST_AsText(the_geom) as geom FROM {feature_type} WHERE {field_id} IN ('{ids_str}')"
        rows = tools_db.get_rows(sql)

        if not rows:
            return

        # Draw all selected features with the appropriate color
        for row in rows:
            _id, geom_text = row
            if geom_text:
                tools_qgis.draw_polyline(geom_text, rubber_band, color, width, reset_rb=False)

    def _open_toolbox_function(self, function, signal=None, connect=None):
        """ Execute currently selected function from combobox """

        toolbox_btn = GwToolBoxButton(None, None, None, None, None)
        if connect is None:
            connect = [partial(self.fill_table, self.dlg_psector_mng, self.qtbl_psm, 'v_ui_plan_psector'),
                       partial(tools_gw.refresh_selectors)]
        else:
            if type(connect) is not list:
                connect = [connect]
        dlg_functions = toolbox_btn.open_function_by_id(function, connect_signal=connect)
        return dlg_functions

    def _manage_selection_changed(self, layer: QgsMapLayer):

        try:
            if layer is None:
                return

            if layer.providerType() != 'postgres':
                return

            tablename = tools_qgis.get_layer_source_table_name(layer)
            if not tablename:
                return

            mapping_dict = {
                "ve_node": ("node_id", self.qtbl_node),
                "ve_arc": ("arc_id", self.qtbl_arc),
                "ve_connec": ("connec_id", self.qtbl_connec),
                "ve_gully": ("gully_id", self.qtbl_gully),
            }
            idname, tableview = mapping_dict[tablename]
            if layer.selectedFeatureCount() > 0:
                # Get selected features of the layer
                features = layer.selectedFeatures()
                feature_ids = [f"{feature.attribute(idname)}" for feature in features]

                # Select in table
                selection_model = tableview.selectionModel()

                # Clear previous selection
                selection_model.clearSelection()

                model = tableview.model()

                # Loop through the model rows to find matching feature_ids
                for row in range(model.rowCount()):
                    if isinstance(model, QSqlTableModel):
                        index = model.index(row, model.fieldIndex(idname))
                        feature_id = model.data(index)

                        index = model.index(row, model.fieldIndex("state"))
                        state = model.data(index)
                    elif isinstance(model, QStandardItemModel):
                        index = model.index(row, tools_qt.get_col_index_by_col_name(tableview, idname))
                        feature_id = model.data(index)

                        index = model.index(row, tools_qt.get_col_index_by_col_name(tableview, "state"))
                        state = model.data(index)
                    else:
                        continue

                    if f"{feature_id}" in feature_ids and f"{state}" == "1":
                        selection_model.select(index, (QItemSelectionModel.SelectionFlag.Select | QItemSelectionModel.SelectionFlag.Rows))
        except Exception as e:
            msg = "Error in _manage_selection_changed: {0}"
            msg_params = (e,)
            tools_log.log_warning(msg, msg_params=msg_params)

    def callback_values(self):
        return self, self.dlg_plan_psector, "psector"

    def reset_relation_tables_signals(self):
        """ Reset relation tables signals """

        self._manage_selection_changed_signals(GwFeatureTypes.ARC)
        self._manage_selection_changed_signals(GwFeatureTypes.NODE)
        self._manage_selection_changed_signals(GwFeatureTypes.CONNEC)
        self._manage_selection_changed_signals(GwFeatureTypes.GULLY)

    def _manage_psector_editability(self, psector_id):
        """ Manage psector form editability based on psector_editable variable """
        if hasattr(self, 'psector_editable') and not self.psector_editable and psector_id:
            # Disable all widgets in tabs other than General
            for tab_index in range(1, self.dlg_plan_psector.tabwidget.count()):
                tab_widget = self.dlg_plan_psector.tabwidget.widget(tab_index)
                if tab_widget:
                    tab_widget.setEnabled(True)

    def _manage_selection_changed_signals(self, feature_type: GwFeatureTypes, connect=True, disconnect=True):
        """
        Manage the selection changed signals for the tableview based on the feature type
        """
        tableview_map = {
            GwFeatureTypes.ARC: (self.qtbl_arc, "ve_arc", "arc_id", "arc", "arc_id", self.rubber_band_line, 10),
            GwFeatureTypes.NODE: (self.qtbl_node, "ve_node", "node_id", "node", "node_id", self.rubber_band_point, 5),
            GwFeatureTypes.CONNEC: (self.qtbl_connec, "ve_connec", "connec_id", "connec", "connec_id", self.rubber_band_point, 5),
            GwFeatureTypes.GULLY: (self.qtbl_gully, "ve_gully", "gully_id", "gully", "gully_id", self.rubber_band_point, 5),
        }
        tableview, tablename, feat_id, tablename_op, feat_id_op, rb, width = tableview_map.get(feature_type, (None, None, None, None, None, None, None))
        if tableview is None:
            return

        if disconnect:
            # Generic selection changed signal
            tools_gw.disconnect_signal('psector', f"highlight_features_by_id_{tablename}")
            tools_gw.disconnect_signal('psector', f"highlight_features_by_id_{tablename_op}_op")
            tools_gw.disconnect_signal('psector', f"manage_tab_feature_buttons_{tablename}")

        if not connect:
            return

        # Highlight operative features (state = 1)
        tools_gw.connect_signal(tableview.selectionModel().selectionChanged, partial(
            self._highlight_features_by_id, tableview, tablename, feat_id, rb, width, state_value=1
        ), 'psector', f"highlight_features_by_id_{tablename}")

        # Highlight obsolete features (state = 0)
        tools_gw.connect_signal(tableview.selectionModel().selectionChanged, partial(
            self._highlight_features_by_id, tableview, tablename_op, feat_id_op, self.rubber_band_op, width, state_value=0
        ), 'psector', f"highlight_features_by_id_{tablename_op}_op")

        # Flags are now handled globally during table initialization

    # endregion


def close_dlg(**kwargs):
    """ Close dialog and disconnect snapping """
    class_obj = kwargs["class"]
    try:
        # # Only check topology if psector is active and has an id
        # active = tools_qt.get_widget_value(class_obj.dlg_plan_psector, "tab_general_active")
        # if active:
        #     psector_id = tools_qt.get_text(class_obj.dlg_plan_psector, 'tab_general_psector_id')
        #     psector_name = tools_qt.get_text(class_obj.dlg_plan_psector, "tab_general_name", return_string_null=False)
        #     class_obj.check_topology_psector(psector_id, psector_name)

        tools_gw.reset_rubberband(class_obj.rubber_band_point)
        tools_gw.reset_rubberband(class_obj.rubber_band_line)
        tools_gw.reset_rubberband(class_obj.rubber_band_op)
        class_obj.my_json = {}
        if class_obj.iface.activeLayer():
            class_obj.iface.setActiveLayer(class_obj.iface.activeLayer())
        class_obj.rel_layers = tools_gw.remove_selection(True, layers=class_obj.rel_layers)
        class_obj.reset_model_psector("arc")
        class_obj.reset_model_psector("node")
        class_obj.reset_model_psector("connec")
        if class_obj.project_type.upper() == 'UD':
            class_obj.reset_model_psector("gully")
        class_obj.reset_model_psector("other")
        tools_qgis.disconnect_snapping()
        tools_gw.disconnect_signal('psector')
        tools_qgis.disconnect_signal_selection_changed()

        try:
            global_vars.canvas.selectionChanged.disconnect(partial(class_obj._manage_selection_changed))
        except (RuntimeError, TypeError):
            pass

        # Apply filters on tableview
        if hasattr(class_obj, 'dlg_psector_mng'):
            class_obj._filter_table(class_obj.dlg_psector_mng, class_obj.qtbl_psm, class_obj.dlg_psector_mng.txt_name, class_obj.dlg_psector_mng.chk_active, class_obj.dlg_psector_mng.chk_archived, 'v_ui_plan_psector')
        # Close dialog
        tools_gw.close_dialog(class_obj.dlg_plan_psector)
    except RuntimeError:
        pass


def accept(**kwargs):
    """ Accept button action """

    class_obj = kwargs["class"]
    class_obj.insert_or_update_new_psector()
