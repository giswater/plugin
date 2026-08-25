"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import json
import os
import csv
import re
from qgis.PyQt.sip import isdeleted
from time import time
from datetime import datetime, timedelta
from functools import partial

from qgis.PyQt.QtCore import Qt, QDate, QStringListModel, QTime, QDateTime, QTimer
from qgis.PyQt.QtWidgets import QAbstractItemView, QAction, QCompleter, QLineEdit, \
    QTableView, QTabWidget, QTextEdit, QLabel
from qgis.PyQt.QtXml import QDomDocument
from qgis.core import QgsApplication, QgsFeatureRequest, QgsPrintLayout, QgsProject, QgsReadWriteContext, \
    QgsVectorLayer, Qgis, QgsPointXY
from qgis.gui import QgsMapToolEmitPoint

from .mincut_tools import GwMincutTools
from ..threads.auto_mincut_execute import GwAutoMincutTask
from ..utils import tools_gw
from ..utils.snap_manager import GwSnapManager
from ..utils.selection_mode import GwSelectionMode
from ..ui.ui_manager import GwMincutComposerUi, GwMincutConnecUi, GwMincutEndUi, GwMincutHydrometerUi
from ... import global_vars
from ...libs import lib_vars, tools_qt, tools_qgis, tools_log, tools_db


class GwMincut:

    def __init__(self):

        self.iface = global_vars.iface
        self.canvas = global_vars.canvas
        self.plugin_dir = lib_vars.plugin_dir
        self.settings = global_vars.giswater_settings
        self.schema_name = lib_vars.schema_name
        self.timer = None
        self.form_has_changed = False
        self.original_values = {}

        # Create separate class to manage 'actionConfig'
        self.mincut_tools = GwMincutTools(self)

        # Get layers of node, arc, connec group
        self.node_group = []
        self.rel_layers = dict()
        self.layers_connec = None
        self.arc_group = []
        self.hydro_list = []
        self.deleted_list = []
        self.ids = []
        self.rel_list_ids = {'arc': [], 'node': [], 'connec': [], 'gully': [], 'element': []}
        self.excluded_layers = []

        # Serialize data of mincut states
        self.states = {}
        self._set_states()
        self.current_state = None
        self.is_new = True
        self.previous_snapping = None
        self.emit_point = None
        self.vertex_marker = None
        self.snapper_manager = None
        self.mincut_mode = 'network'

        # Other variables
        self.col1 = "feature_customer_code"
        self.col2 = "hydro_customer_code"
        self.lbl1 = "Connec customer code:"
        self.lbl2 = "Hydrometer customer code:"

        # Cursor management for setmincut function
        self.mincut_aux_conn = None
        self.mincut_cursor = None
        self.search_rubber_band = tools_gw.create_rubberband(self.canvas)
        self.geom_by_source = {"street": {}, "postnumber": {}}

    def reset_mincut_canvas_snapping(self, action_pan=False):
        """Disconnect mincut map-tool snapping and sync tools_gw signal registry.

        disconnect_snapping() clears every xyCoordinates connection on the canvas; if
        active_signals still lists mincut / mincut_offline, connect_signal() will skip
        reconnecting and preview snapping never comes back.
        """
        tools_qgis.disconnect_snapping(action_pan, self.emit_point, self.vertex_marker)
        tools_gw.disconnect_signal('mincut_offline')
        tools_gw.disconnect_signal('mincut')

    def manage_mincuts(self, dialog):
        """ Button 12: Mincut management """

        self.action = "manage_mincuts"
        self.mincut_tools.set_dialog(dialog)

    def load_mincut(self, result_mincut_id):
        """ Load selected mincut """

        self.is_new = False
        # Force fill form mincut
        self.result_mincut_id.setText(str(result_mincut_id))
        sql = (f"SELECT om_mincut.*, cat_users.name AS assigned_to_name,"
               f" om_mincut.streetaxis_id AS street_name"
               f" FROM om_mincut"
               f" INNER JOIN cat_users ON cat_users.id = om_mincut.assigned_to"
               f" WHERE om_mincut.id = '{result_mincut_id}'")
        row = tools_db.get_row(sql)
        if not row:
            self._enable_widgets('0')
            return

        # Get mincut state name
        mincut_state_name = ''
        if row['mincut_state'] in self.states:
            mincut_state_name = self.states[row['mincut_state']]

        # Get mincut class
        if row['mincut_class']:
            self.mincut_class = row['mincut_class']

        tools_qt.set_widget_text(self.dlg_mincut, self.dlg_mincut.work_order, row['work_order'])
        tools_qt.set_combo_value(self.dlg_mincut.type, row['mincut_type'], 0)
        tools_qt.set_combo_value(self.dlg_mincut.cause, row['anl_cause'], 0)
        tools_qt.set_widget_text(self.dlg_mincut, self.dlg_mincut.state, mincut_state_name)
        extras = f'"mincutId":"{result_mincut_id}"'
        body = tools_gw.create_body(extras=extras)
        result = tools_gw.execute_procedure('gw_fct_getmincut', body)
        if result and result['status'] == 'Accepted':
            tools_gw.add_layer_temp(self.dlg_mincut, result['body']['data'], None, False, call_set_tabs_enabled=False, close=False)

        # Manage dates
        self._open_mincut_manage_dates(row)

        tools_qt.set_widget_text(self.dlg_mincut, "pred_description", row['anl_descript'])
        tools_qt.set_widget_text(self.dlg_mincut, "real_description", row['exec_descript'])
        tools_qt.set_widget_text(self.dlg_mincut, "txt_chlorine", row['chlorine'])
        tools_qt.set_widget_text(self.dlg_mincut, "txt_turbidity", row['turbidity'])
        tools_qt.set_widget_text(self.dlg_mincut, "distance", row['exec_from_plot'])
        tools_qt.set_widget_text(self.dlg_mincut, "depth", row['exec_depth'])
        tools_qt.set_checked(self.dlg_mincut, "appropiate", row['exec_appropiate'])
        tools_qt.set_widget_text(self.dlg_mincut, "txt_equipment_code", row['equipment_code'])
        tools_qt.set_widget_text(self.dlg_mincut, "txt_reagent_lot", row['reagent_lot'])

        # Manage assigend_to combo
        index = self.dlg_mincut.assigned_to.findText(row['assigned_to_name'])
        if index == -1:
            sql = (f"SELECT id, name "
                   f"FROM cat_users WHERE name = '{row['assigned_to_name']}'"
                   f"ORDER BY name")

            rows = tools_db.get_rows(sql)
            tools_qt.fill_combo_values(self.dlg_mincut.assigned_to, rows, combo_clear=False)

        tools_qt.set_widget_text(self.dlg_mincut, "assigned_to", row['assigned_to_name'])

        self._sync_address_widgets_from_mincut(result_mincut_id)

        # Update table 'selector_mincut_result'
        self._update_result_selector(result_mincut_id)
        tools_qgis.refresh_map_canvas()
        self.current_state = str(row['mincut_state'])

        expr_filter = f"result_id={result_mincut_id}"
        tools_qt.set_tableview_config(self.dlg_mincut.tbl_hydro)
        message = tools_qt.fill_table(self.dlg_mincut.tbl_hydro, 'v_om_mincut_hydrometer', expr_filter=expr_filter)
        if message:
            tools_qgis.show_warning(message)
        tools_gw.set_tablemodel_config(self.dlg_mincut, self.dlg_mincut.tbl_hydro, 'v_om_mincut_hydrometer')

        self._store_original_values()
        self._connect_change_signals()

        # Depend of mincut_state and mincut_clase desable/enable widgets
        # Current_state == '0': Planified
        if self.current_state == '0':
            self.dlg_mincut.work_order.setDisabled(False)
            # Group Details
            self.dlg_mincut.type.setDisabled(False)
            self.dlg_mincut.cause.setDisabled(False)
            self.dlg_mincut.cbx_recieved_day.setDisabled(False)
            self.dlg_mincut.cbx_recieved_time.setDisabled(False)
            self.dlg_mincut.txt_chlorine.setDisabled(False)
            self.dlg_mincut.txt_turbidity.setDisabled(False)
            self.dlg_mincut.txt_equipment_code.setDisabled(False)
            self.dlg_mincut.txt_reagent_lot.setDisabled(False)
            # Group Prediction
            self.dlg_mincut.cbx_date_start_predict.setDisabled(False)
            self.dlg_mincut.cbx_hours_start_predict.setDisabled(False)
            self.dlg_mincut.cbx_date_end_predict.setDisabled(False)
            self.dlg_mincut.cbx_hours_end_predict.setDisabled(False)
            self.dlg_mincut.assigned_to.setDisabled(False)
            self.dlg_mincut.pred_description.setDisabled(False)
            # Group Real Details
            self.dlg_mincut.cbx_date_start.setDisabled(True)
            self.dlg_mincut.cbx_hours_start.setDisabled(True)
            self.dlg_mincut.cbx_date_end.setDisabled(True)
            self.dlg_mincut.cbx_hours_end.setDisabled(True)
            self.dlg_mincut.distance.setDisabled(True)
            self.dlg_mincut.depth.setDisabled(True)
            self.dlg_mincut.appropiate.setDisabled(True)
            self.dlg_mincut.real_description.setDisabled(True)
            self.dlg_mincut.btn_start.setDisabled(False)
            self.dlg_mincut.btn_end.setDisabled(True)
            self.dlg_mincut.txt_chlorine.setDisabled(True)
            self.dlg_mincut.txt_turbidity.setDisabled(True)
            self.dlg_mincut.txt_equipment_code.setDisabled(True)
            self.dlg_mincut.txt_reagent_lot.setDisabled(True)
            # Actions
            if self.mincut_class == 1:
                self.action_mincut.setDisabled(False)
                self.action_refresh_mincut.setDisabled(False)
                self.action_custom_mincut.setDisabled(False)
                self.action_change_valve_status.setDisabled(False)
                self.action_add_connec.setDisabled(True)
                self.action_add_hydrometer.setDisabled(True)
            if self.mincut_class == 2:
                self.action_mincut.setDisabled(True)
                self.action_refresh_mincut.setDisabled(True)
                self.action_custom_mincut.setDisabled(True)
                self.action_change_valve_status.setDisabled(True)
                self.action_add_connec.setDisabled(False)
                self.action_add_hydrometer.setDisabled(True)
            if self.mincut_class == 3:
                self.action_mincut.setDisabled(True)
                self.action_refresh_mincut.setDisabled(True)
                self.action_custom_mincut.setDisabled(True)
                self.action_change_valve_status.setDisabled(True)
                self.action_add_connec.setDisabled(True)
                self.action_add_hydrometer.setDisabled(False)
            if self.mincut_class is None:
                self.action_mincut.setDisabled(False)
                self.action_refresh_mincut.setDisabled(True)
                self.action_custom_mincut.setDisabled(True)
                self.action_change_valve_status.setDisabled(True)
                self.action_add_connec.setDisabled(False)
                self.action_add_hydrometer.setDisabled(False)

        # Current_state == '1': In progress
        elif self.current_state == '1':

            self.dlg_mincut.work_order.setDisabled(True)
            # Group Details
            self.dlg_mincut.type.setDisabled(True)
            self.dlg_mincut.cause.setDisabled(True)
            self.dlg_mincut.cbx_recieved_day.setDisabled(True)
            self.dlg_mincut.cbx_recieved_time.setDisabled(True)
            self.dlg_mincut.txt_chlorine.setDisabled(True)
            self.dlg_mincut.txt_turbidity.setDisabled(True)
            self.dlg_mincut.txt_equipment_code.setDisabled(True)
            self.dlg_mincut.txt_reagent_lot.setDisabled(True)
            # Group Prediction dates
            self.dlg_mincut.cbx_date_start_predict.setDisabled(True)
            self.dlg_mincut.cbx_hours_start_predict.setDisabled(True)
            self.dlg_mincut.cbx_date_end_predict.setDisabled(True)
            self.dlg_mincut.cbx_hours_end_predict.setDisabled(True)
            self.dlg_mincut.assigned_to.setDisabled(True)
            self.dlg_mincut.pred_description.setDisabled(True)
            # Group Real dates
            self.dlg_mincut.cbx_date_start.setDisabled(False)
            self.dlg_mincut.cbx_hours_start.setDisabled(False)
            self.dlg_mincut.cbx_date_end.setDisabled(True)
            self.dlg_mincut.cbx_hours_end.setDisabled(True)
            self.dlg_mincut.distance.setDisabled(False)
            self.dlg_mincut.depth.setDisabled(False)
            self.dlg_mincut.appropiate.setDisabled(False)
            self.dlg_mincut.real_description.setDisabled(False)
            self.dlg_mincut.btn_start.setDisabled(True)
            self.dlg_mincut.btn_end.setDisabled(False)
            self.dlg_mincut.txt_chlorine.setDisabled(False)
            self.dlg_mincut.txt_turbidity.setDisabled(False)
            self.dlg_mincut.txt_equipment_code.setDisabled(False)
            self.dlg_mincut.txt_reagent_lot.setDisabled(False)
            # Actions
            self.action_mincut.setDisabled(True)
            self.action_refresh_mincut.setDisabled(True)
            self.action_custom_mincut.setDisabled(True)
            self.action_change_valve_status.setDisabled(True)
            self.action_add_connec.setDisabled(True)
            self.action_add_hydrometer.setDisabled(True)

        # Current_state == '2': Finished, '3':Canceled
        elif self.current_state in ('2', '3'):
            self.dlg_mincut.work_order.setDisabled(True)
            # Group Details
            self.dlg_mincut.type.setDisabled(True)
            self.dlg_mincut.cause.setDisabled(True)
            self.dlg_mincut.cbx_recieved_day.setDisabled(True)
            self.dlg_mincut.cbx_recieved_time.setDisabled(True)
            # Group Prediction dates
            self.dlg_mincut.cbx_date_start_predict.setDisabled(True)
            self.dlg_mincut.cbx_hours_start_predict.setDisabled(True)
            self.dlg_mincut.cbx_date_end_predict.setDisabled(True)
            self.dlg_mincut.cbx_hours_end_predict.setDisabled(True)
            self.dlg_mincut.assigned_to.setDisabled(True)
            self.dlg_mincut.pred_description.setDisabled(True)
            # Group Real dates
            self.dlg_mincut.cbx_date_start.setDisabled(True)
            self.dlg_mincut.cbx_hours_start.setDisabled(True)
            self.dlg_mincut.cbx_date_end.setDisabled(True)
            self.dlg_mincut.cbx_hours_end.setDisabled(True)
            self.dlg_mincut.distance.setDisabled(True)
            self.dlg_mincut.depth.setDisabled(True)
            self.dlg_mincut.appropiate.setDisabled(True)
            self.dlg_mincut.real_description.setDisabled(True)
            self.dlg_mincut.btn_start.setDisabled(True)
            self.dlg_mincut.btn_end.setDisabled(True)
            self.dlg_mincut.txt_chlorine.setDisabled(True)
            self.dlg_mincut.txt_turbidity.setDisabled(True)
            self.dlg_mincut.txt_equipment_code.setDisabled(True)
            self.dlg_mincut.txt_reagent_lot.setDisabled(True)
            # Actions
            self.action_mincut.setDisabled(True)
            self.action_refresh_mincut.setDisabled(True)
            self.action_custom_mincut.setDisabled(True)
            self.action_change_valve_status.setDisabled(True)
            self.action_add_connec.setDisabled(True)
            self.action_add_hydrometer.setDisabled(True)

        # Common Actions
        self.action_mincut_composer.setDisabled(False)
        self.action_export_hydro_csv.setDisabled(False)

        return row

    def connect_signal_selection_changed(self, option):
        """ Connect signal selectionChanged """

        try:
            if option == "mincut_connec":
                tools_gw.connect_signal(global_vars.canvas.selectionChanged, partial(self._snapping_selection_connec),
                                        'mincut_selection_changed', 'connect_signal_selection_changed_canvas_selectionChanged_snapping_selection_connec')
            elif option == "mincut_hydro":
                tools_gw.connect_signal(global_vars.canvas.selectionChanged, partial(self._snapping_selection_hydro),
                                        'mincut_selection_changed', 'connect_signal_selection_changed_canvas_selectionChanged_snapping_selection_hydro')
        except Exception:
            pass

    def set_dialog(self, dialog):
        self.dlg_mincut = dialog

    def init_mincut_form(self):
        """ Custom form initial configuration """

        # Drop temporary tables when form is initialized
        extras = '"action":"DROP", "fct_name":"MINCUT"'
        body = tools_gw.create_body(extras=extras)
        result = tools_gw.execute_procedure('gw_fct_graphanalytics_manage_temporary', body)
        if not result or result['status'] == 'Failed':
            return

        # Create auxiliary connection and cursor for setmincut function
        self._create_mincut_cursor()

        # Setting lists
        self.mincut_class = 1
        self.user_current_layer = self.iface.activeLayer()
        self._init_mincut_canvas()
        tools_qgis.remove_layer(custom_properties={"gw_id": 'Overlap affected arcs'}, group_name='GW Temporal Layers')
        tools_qgis.remove_layer(custom_properties={"gw_id": 'Other mincuts which overlaps'}, group_name='GW Temporal Layers')
        tools_qgis.remove_layer(custom_properties={"gw_id": 'Overlap affected connecs'}, group_name='GW Temporal Layers')

        tools_gw.load_settings(self.dlg_mincut)
        self.dlg_mincut.btn_cancel_task.hide()
        self.dlg_mincut.btn_cancel.show()

        # Disable tab log
        tools_gw.disable_tab_log(self.dlg_mincut)

        self.result_mincut_id = self.dlg_mincut.findChild(QLineEdit, "result_mincut_id")
        self.state = self.dlg_mincut.findChild(QLineEdit, "state")
        self.work_order = self.dlg_mincut.findChild(QLineEdit, "work_order")
        self.pred_description = self.dlg_mincut.findChild(QTextEdit, "pred_description")
        self.real_description = self.dlg_mincut.findChild(QTextEdit, "real_description")
        self.distance = self.dlg_mincut.findChild(QLineEdit, "distance")
        self.depth = self.dlg_mincut.findChild(QLineEdit, "depth")
        self.chlorine = self.dlg_mincut.findChild(QLineEdit, "chlorine")
        self.turbidity = self.dlg_mincut.findChild(QLineEdit, "turbidity")

        self.municipality = self.dlg_mincut.findChild(QLineEdit, "cmb_municipality")
        self.street = self.dlg_mincut.findChild(QLineEdit, "txt_street")
        self.number = self.dlg_mincut.findChild(QLineEdit, "txt_postnumber")

        tools_qt.double_validator(self.distance, 0, 9999999, 3)
        tools_qt.double_validator(self.depth, 0, 9999999, 3)
        tools_qt.set_widget_text(self.dlg_mincut, self.dlg_mincut.txt_exec_user, tools_db.current_user)

        # Fill ComboBox type
        sql = ("SELECT id, descript "
               "FROM om_mincut_cat_type "
               "ORDER BY id")
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_mincut.type, rows)

        # Fill ComboBox cause
        sql = ("SELECT id, idval "
               "FROM v_om_typevalue WHERE typevalue = 'mincut_cause' "
               "ORDER BY id")
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_mincut.cause, rows)

        # Fill ComboBox assigned_to
        sql = ("SELECT id, name "
               "FROM cat_users WHERE active is not False "
               "ORDER BY name")
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_mincut.assigned_to, rows)

        # Manage search widgets
        self._manage_search_widgets(self.dlg_mincut)

        # Toolbar actions
        action = self.dlg_mincut.findChild(QAction, "actionMincut")
        action.triggered.connect(self._auto_mincut)
        tools_gw.add_icon(action, "126")
        self.action_mincut = action

        action = self.dlg_mincut.findChild(QAction, "actionRefreshMincut")
        action.triggered.connect(self._refresh_mincut)
        tools_gw.add_icon(action, "125")
        self.action_refresh_mincut = action

        action = self.dlg_mincut.findChild(QAction, "actionCustomMincut")
        action.triggered.connect(partial(self._custom_mincut, action))
        tools_gw.add_icon(action, "123")
        self.action_custom_mincut = action

        action = self.dlg_mincut.findChild(QAction, "actionChangeValveStatus")
        action.triggered.connect(partial(self._change_valve_status, action))
        tools_gw.add_icon(action, "124")
        self.action_change_valve_status = action

        action = self.dlg_mincut.findChild(QAction, "actionAddConnec")
        action.triggered.connect(self._add_connec)
        tools_gw.add_icon(action, "121")
        self.action_add_connec = action

        action = self.dlg_mincut.findChild(QAction, "actionAddHydrometer")
        action.triggered.connect(self._add_hydrometer)
        tools_gw.add_icon(action, "122")
        self.action_add_hydrometer = action

        action = self.dlg_mincut.findChild(QAction, "actionComposer")
        action.triggered.connect(self._mincut_composer)
        tools_gw.add_icon(action, "148")
        self.action_mincut_composer = action

        action = self.dlg_mincut.findChild(QAction, "actionExportHydroCsv")
        action.triggered.connect(self._export_hydro_csv)
        tools_gw.add_icon(action, "132")
        self.action_export_hydro_csv = action

        # Set shortcut keys
        self.dlg_mincut.key_escape.connect(partial(tools_gw.close_dialog, self.dlg_mincut))

        # Show future id of mincut
        if self.is_new:
            self.set_id_val()

        # Set state name
        if self.states != {}:
            tools_qt.set_widget_text(self.dlg_mincut, self.dlg_mincut.state, str(self.states[0]))

        self.current_state = 0
        self.sql_connec = ""
        self.sql_hydro = ""

        self._refresh_tab_hydro()

        self._load_widgets_values()

    def _manage_search_widgets(self, dialog):
        """ Manage search widgets """

        # Fill ComboBox municipality
        sql = ("SELECT muni_id, name "
               "FROM v_municipality "
               "WHERE active is True and muni_id > 0 "
               "ORDER BY name")
        rows = tools_db.get_rows(sql)

        tools_qt.fill_combo_values(dialog.cmb_municipality, rows)

        # Connect signals to load street and postnumbers
        dialog.cmb_municipality.currentIndexChanged.connect(partial(self._load_street, dialog, dialog.cmb_municipality))
        dialog.txt_street.textChanged.connect(partial(self._load_postnumbers, dialog, dialog.txt_street))

        # Emit current index to load street and postnumbers
        dialog.cmb_municipality.currentIndexChanged.emit(dialog.cmb_municipality.currentIndex())

    def set_id_val(self):
        next_id = tools_gw.get_sequence_next_preview(
        seq_name='om_mincut_seq',
        schema=self.schema_name.replace('"', '')
        )
        tools_qt.set_widget_text(self.dlg_mincut, self.dlg_mincut.result_mincut_id, str(next_id))

    def get_mincut(self):
        """ Button 11: Mincut """

        self.is_new = True
        self.init_mincut_form()
        try:
            # mark as not saved until user accepts
            self.dlg_mincut.setProperty('saved', False)
        except Exception:
            pass
        self.action = "get_mincut"

        # Get current date. Set all QDateEdit to current date
        date_start = QDate.currentDate()
        tools_qt.set_calendar(self.dlg_mincut, "cbx_date_start", date_start)
        tools_qt.set_calendar(self.dlg_mincut, "cbx_date_end", date_start)
        tools_qt.set_calendar(self.dlg_mincut, "cbx_recieved_day", date_start)
        tools_qt.set_calendar(self.dlg_mincut, "cbx_date_start_predict", date_start)
        tools_qt.set_calendar(self.dlg_mincut, "cbx_date_end_predict", date_start)

        # Get current time
        current_time = QTime.currentTime()
        self.dlg_mincut.cbx_recieved_time.setTime(current_time)
        self.dlg_mincut.cbx_hours_start_predict.setTime(current_time)
        self.dlg_mincut.cbx_hours_end_predict.setTime(current_time)

        # Enable/Disable widget depending state
        self._enable_widgets('0')

        # Disabled button accept from mincut form
        self.dlg_mincut.btn_accept.setEnabled(False)

        self._store_original_values()
        self._connect_change_signals()

        # Show form in docker?
        self.manage_docker()

    def start_offline_mincut(self):
        """Start offline mincut snapping directly on arc layer."""

        self.reset_mincut_canvas_snapping(action_pan=False)
        self.mincut_mode = 'offline'
        self.user_current_layer = self.iface.activeLayer()
        self.emit_point = QgsMapToolEmitPoint(self.canvas)
        self.canvas.setMapTool(self.emit_point)
        self.snapper_manager = GwSnapManager(self.iface)
        self.snapper = self.snapper_manager.get_snapper()
        self.vertex_marker = self.snapper_manager.vertex_marker

        self._init_mincut_canvas()

        msg = "Select the arc to perform a visual execution"
        tools_qgis.show_info(msg)

        tools_gw.connect_signal(self.canvas.xyCoordinates, self._mouse_move_node_arc, 'mincut_offline',
                                'offline_mincut_xyCoordinates_mouse_move_node_arc')
        tools_gw.connect_signal(self.emit_point.canvasClicked, self._offline_mincut_snapping, 'mincut_offline',
                                'offline_mincut_ep_canvasClicked_offline_mincut_snapping')

    def _restore_active_layer_after_offline_mincut(self):
        """Restore the previously active layer if it still exists."""

        if self.user_current_layer is None or isdeleted(self.user_current_layer):
            return

        try:
            self.iface.setActiveLayer(self.user_current_layer)
        except RuntimeError:
            pass

    def manage_docker(self):

        tools_gw.init_docker('qgis_form_docker')
        if lib_vars.session_vars['dialog_docker']:
            tools_gw.docker_dialog(self.dlg_mincut, 'mincut', 'mincut')
        else:
            tools_gw.open_dialog(self.dlg_mincut, 'mincut')

        self._set_signals()

    def set_visible_mincut_layers(self, zoom=False):
        """ Set visible mincut result layers """

        layer_zoomed = None
        layer = tools_qgis.get_layer_by_tablename("v_om_mincut_valve")
        if layer:
            tools_qgis.set_layer_visible(layer)

        layer = tools_qgis.get_layer_by_tablename("v_om_mincut_arc")
        if layer:
            tools_qgis.set_layer_visible(layer)

        layer = tools_qgis.get_layer_by_tablename("v_om_mincut_connec")
        if layer:
            tools_qgis.set_layer_visible(layer)
            if layer.featureCount() > 0:
                layer_zoomed = layer

        layer = tools_qgis.get_layer_by_tablename("v_om_mincut_node")
        if layer:
            tools_qgis.set_layer_visible(layer)
            if layer.featureCount() > 0:
                layer_zoomed = layer

        if zoom and layer_zoomed is not None:
            # Refresh extension of layer
            layer_zoomed.updateExtents()
            # Zoom to executed mincut
            self.iface.setActiveLayer(layer_zoomed)
            self.iface.zoomToActiveLayer()

    # region private functions

    def _load_widgets_values(self):

        chk_use_planified = tools_gw.get_config_parser('dlg_mincut', 'chk_use_planified', "user", "session")
        type = tools_gw.get_config_parser('dlg_mincut', 'type', "user", "session")
        cause = tools_gw.get_config_parser('dlg_mincut', 'cause', "user", "session")

        if chk_use_planified is not None:
            tools_qt.set_checked(self.dlg_mincut, 'chk_use_planified', chk_use_planified)
        if type is not None:
            tools_qt.set_widget_text(self.dlg_mincut, 'type', type)
        if cause is not None:
            tools_qt.set_widget_text(self.dlg_mincut, 'cause', cause)

    def _save_widgets_values(self):

        chk_use_planified = tools_qt.is_checked(self.dlg_mincut, 'chk_use_planified')
        type = tools_qt.get_text(self.dlg_mincut, 'type')
        cause = tools_qt.get_text(self.dlg_mincut, 'cause')

        tools_gw.set_config_parser('dlg_mincut', 'chk_use_planified', f"{chk_use_planified}")
        tools_gw.set_config_parser('dlg_mincut', 'type', f"{type}")
        tools_gw.set_config_parser('dlg_mincut', 'cause', f"{cause}")

    def _load_street(self, dialog, filter_widget):
        """Load street typeahead values filtered by selected municipality."""

        tools_qt.set_widget_text(dialog, dialog.txt_street, "")
        self.muni_id = tools_qt.get_combo_value(dialog, filter_widget, 0)
        if self.muni_id in (None, "", "-1", -1):
            self.geom_by_source["street"] = {}
            tools_qt.set_completer_rows(dialog.txt_street, [])
            return

        sql = (f"SELECT name, ST_AsText(ST_Simplify(ST_Collect(the_geom), 0)) "
               f"FROM ve_streetaxis "
               f"WHERE muni_id = '{self.muni_id}' "
               f"GROUP BY name "
               f"ORDER BY name")
        rows = tools_db.get_rows(sql)
        tools_qt.set_completer_rows(dialog.txt_street, rows, "contains")
        self.geom_by_source["street"] = {row[0]: row[1] for row in rows or [] if row and row[0]}
        completer = dialog.txt_street.completer()
        if completer:
            completer.activated.connect(partial(self._zoom_to_geom_text, "street"))

    def _load_postnumbers(self, dialog, filter_widget):
        """Load postnumbers typeahead values filtered by selected street."""

        tools_qt.set_widget_text(dialog, dialog.txt_postnumber, "")
        self.street = tools_qt.get_text(dialog, filter_widget)
        if self.street in (None, "", "-1", -1):
            self.geom_by_source["postnumber"] = {}
            tools_qt.set_completer_rows(dialog.txt_postnumber, [])
            return

        sql = (f"SELECT postnumber, ST_AsText(ST_Simplify(ST_Collect(the_geom), 0)) "
               f"FROM ve_address "
               f"WHERE name = '{self.street}' "
               f"GROUP BY postnumber "
               f"ORDER BY postnumber")
        rows = tools_db.get_rows(sql)
        tools_qt.set_completer_rows(dialog.txt_postnumber, rows)
        self.geom_by_source["postnumber"] = {row[0]: row[1] for row in rows or [] if row and row[0]}
        completer = dialog.txt_postnumber.completer()
        if completer:
            completer.activated.connect(partial(self._zoom_to_geom_text, "postnumber"))

    def _sync_address_widgets_from_mincut(self, result_mincut_id):
        """Load address from om_mincut and reflect it in address widgets."""

        if result_mincut_id in (None, "", "-1"):
            return

        sql = (
            f"SELECT muni_id, postnumber, streetaxis_id AS street_name "
            f"FROM om_mincut "
            f"WHERE id = '{result_mincut_id}'"
        )
        row = tools_db.get_row(sql)
        if not row:
            return

        muni_id = row.get("muni_id")
        street_name = row.get("street_name")
        postnumber = row.get("postnumber")

        if muni_id not in (None, "", "-1", -1):
            tools_qt.set_combo_value(self.dlg_mincut.cmb_municipality, muni_id, 0)
        if street_name not in (None, ""):
            tools_qt.set_widget_text(self.dlg_mincut, self.dlg_mincut.txt_street, street_name)
        if postnumber not in (None, ""):
            tools_qt.set_widget_text(self.dlg_mincut, self.dlg_mincut.txt_postnumber, postnumber)

    def _zoom_to_geom_text(self, source, result):
        """Zoom to geometry represented as WKT text."""
        if not result:
            return
        geom = self.geom_by_source.get(source, {}).get(result)
        if not geom:
            return
        list_coord = re.search(r'\((.*)\)', str(geom))
        if not list_coord:
            return
        max_x, max_y, min_x, min_y = tools_qgis.get_max_rectangle_from_coords(list_coord)
        # For POINT geometries bbox has zero size; expand extent before zoom.
        if max_x == min_x and max_y == min_y:
            delta = 10
            tools_qgis.zoom_to_rectangle(max_x + delta, max_y + delta, min_x - delta, min_y - delta, 0)
            tools_qgis.draw_point(
                QgsPointXY(float(max_x), float(max_y)),
                self.search_rubber_band
            )
            return
        else:
            tools_qgis.zoom_to_rectangle(max_x, max_y, min_x, min_y, 1)

    def _set_states(self):
        """ Serialize data of mincut states """

        sql = ("SELECT id, idval "
               "FROM v_om_typevalue WHERE typevalue = 'mincut_state' "
               "ORDER BY id")
        rows = tools_db.get_rows(sql)
        if rows:
            for row in rows:
                if 'idval' in row:
                    self.states[int(row['id'])] = row['idval']

    def _init_mincut_canvas(self):

        self.rel_list_ids['connec'] = []
        self.hydro_list = []
        self.deleted_list = []

        # Refresh canvas, remove all old selections
        self._remove_selection()

        # Parametrize list of layers
        self.rel_layers['connec'] = tools_gw.get_layers_from_feature_type('connec')
        self.layers_connec = self.rel_layers['connec']
        self.layer_arc = tools_qgis.get_layer_by_tablename("ve_arc")

        # Set active and current layer
        self.iface.setActiveLayer(self.layer_arc)
        self.current_layer = self.layer_arc

    def _set_signals(self):

        if lib_vars.session_vars['dialog_docker']:
            self.dlg_mincut.dlg_closed.connect(partial(tools_gw.close_docker, option_name='position'))

        self.dlg_mincut.btn_cancel_task.clicked.connect(self._cancel_task)
        self.dlg_mincut.btn_accept.clicked.connect(partial(self._accept_save_data, self.dlg_mincut))
        self.dlg_mincut.btn_cancel.clicked.connect(self._mincut_close)
        self.dlg_mincut.dlg_closed.connect(self._mincut_close)
        self.dlg_mincut.btn_start.clicked.connect(self._real_start)
        self.dlg_mincut.btn_end.clicked.connect(self._real_end)

        self.dlg_mincut.cbx_date_start_predict.dateChanged.connect(partial(
            self._check_dates_coherence, self.dlg_mincut.cbx_date_start_predict, self.dlg_mincut.cbx_date_end_predict,
            self.dlg_mincut.cbx_hours_start_predict, self.dlg_mincut.cbx_hours_end_predict))
        self.dlg_mincut.cbx_date_end_predict.dateChanged.connect(partial(
            self._check_dates_coherence, self.dlg_mincut.cbx_date_start_predict, self.dlg_mincut.cbx_date_end_predict,
            self.dlg_mincut.cbx_hours_start_predict, self.dlg_mincut.cbx_hours_end_predict))

        self.dlg_mincut.cbx_date_start.dateChanged.connect(partial(
            self._check_dates_coherence, self.dlg_mincut.cbx_date_start, self.dlg_mincut.cbx_date_end,
            self.dlg_mincut.cbx_hours_start, self.dlg_mincut.cbx_hours_end))
        self.dlg_mincut.cbx_date_end.dateChanged.connect(partial(
            self._check_dates_coherence, self.dlg_mincut.cbx_date_start, self.dlg_mincut.cbx_date_end,
            self.dlg_mincut.cbx_hours_start, self.dlg_mincut.cbx_hours_end))

        self.action_mincut.toggled.connect(partial(self.manage_checked, self.action_mincut))
        self.action_custom_mincut.toggled.connect(partial(self.manage_checked, self.action_custom_mincut))
        self.action_change_valve_status.toggled.connect(partial(self.manage_checked, self.action_change_valve_status))

    def manage_checked(self, action):

        if action.objectName() == "actionMincut" and action.isChecked():
            self.action_custom_mincut.setChecked(False)
            self.action_change_valve_status.setChecked(False)
        elif action.objectName() == "actionCustomMincut" and action.isChecked():
            self.action_mincut.setChecked(False)
            self.action_change_valve_status.setChecked(False)
        elif action.objectName() == "actionChangeValveStatus" and action.isChecked():
            self.action_mincut.setChecked(False)
            self.action_custom_mincut.setChecked(False)

    def _refresh_tab_hydro(self):

        result_mincut_id = tools_qt.get_text(self.dlg_mincut, self.dlg_mincut.result_mincut_id)
        expr_filter = f"result_id={result_mincut_id}"
        tools_qt.set_tableview_config(self.dlg_mincut.tbl_hydro, edit_triggers=QTableView.EditTrigger.DoubleClicked)
        message = tools_qt.fill_table(self.dlg_mincut.tbl_hydro, 'v_om_mincut_hydrometer', expr_filter=expr_filter)
        if message:
            tools_qgis.show_warning(message)
        tools_gw.set_tablemodel_config(self.dlg_mincut, self.dlg_mincut.tbl_hydro, 'v_om_mincut_hydrometer')

    def _check_dates_coherence(self, date_from, date_to, time_from, time_to):
        """
        Chek if date_to.date() is >= than date_from.date()
            :param date_from: QDateEdit.date from
            :param date_to: QDateEdit.date to
            :param time_from: QDateEdit to get date in order to set widget_to_set
            :param time_to: QDateEdit to set coherence date
        """

        d_from = datetime(date_from.date().year(), date_from.date().month(), date_from.date().day(),
                          time_from.time().hour(), time_from.time().minute())
        d_to = datetime(date_to.date().year(), date_to.date().month(), date_to.date().day(),
                        time_to.time().hour(), time_to.time().minute())

        if d_from > d_to:
            date_to.setDate(date_from.date())
            time_to.setTime(time_from.time())

    def _mincut_cleanup_only(self, result_mincut_id):
        """ Perform mincut cleanup without closing the dialog (for state 4 replacement) """

        # Restore user layer
        tools_qgis.restore_user_layer('ve_node', self.user_current_layer)

        # Remove selections
        self._remove_selection()

        # Reset rubber band
        tools_qgis.reset_rubber_band(self.search_rubber_band)

        # Disconnect snapping
        self.reset_mincut_canvas_snapping(action_pan=True)

        # Delete from DB (including conflicts)
        mincut_conflict_state = 5
        sql = (
            f"WITH groups_conflict AS ("
            f"    SELECT DISTINCT id FROM om_mincut_conflict WHERE mincut_id = {result_mincut_id}"
            f"),"
            f"mincuts_to_delete AS ("
            f"    SELECT omc.mincut_id "
            f"    FROM om_mincut_conflict omc "
            f"    JOIN om_mincut om ON om.id = omc.mincut_id "
            f"    WHERE om.mincut_state = {mincut_conflict_state} "
            f"    AND omc.id IN (SELECT id FROM groups_conflict)"
            f") "
            f"DELETE FROM om_mincut WHERE id IN (SELECT mincut_id FROM mincuts_to_delete);"
        )
        tools_db.execute_sql(sql)
        sql = (
            f"WITH groups_conflict AS ("
            f"    SELECT DISTINCT id FROM om_mincut_conflict WHERE mincut_id = {result_mincut_id}"
            f") "
            f"DELETE FROM om_mincut_conflict "
            f"WHERE id IN (SELECT id FROM groups_conflict);"
        )
        tools_db.execute_sql(sql)
        sql = f"DELETE FROM om_mincut WHERE id = {result_mincut_id};"
        tools_db.execute_sql(sql)

        # Refresh map
        self._remove_selection()
        tools_qgis.refresh_map_canvas()

    def _mincut_close(self):

        if lib_vars.session_vars['dialog_docker'] and lib_vars.session_vars['dialog_docker'].isFloating():
            widget = lib_vars.session_vars['dialog_docker'].widget()
            if widget:
                widget.close()
                del widget
                global_vars.iface.removeDockWidget(lib_vars.session_vars['dialog_docker'])
                lib_vars.session_vars['docker_type'] = None
        else:
            tools_qgis.restore_user_layer('ve_node', self.user_current_layer)
            self._remove_selection()
            tools_qgis.reset_rubber_band(self.search_rubber_band)

            # If client don't touch nothing just rejected dialog or press cancel
            if not self.dlg_mincut.closeMainWin and self.dlg_mincut.mincutCanceled:
                tools_gw.close_dialog(self.dlg_mincut)
                # Close cursor and auxiliary connection
                self._close_mincut_cursor()
                return

            self.dlg_mincut.closeMainWin = True
            self.dlg_mincut.mincutCanceled = True

            # If id exists in database on btn_cancel delete
            if self.action == "get_mincut":
                result_mincut_id = self.dlg_mincut.result_mincut_id.text()
                sql = (f"SELECT id FROM om_mincut"
                       f" WHERE id = {result_mincut_id}")
                row = tools_db.get_row(sql)
                if row:
                    # Use the cleanup method to delete from DB
                    self._mincut_cleanup_only(result_mincut_id)
                    self._update_result_selector()
                    msg = "Mincut canceled!"
                    tools_qgis.show_info(msg)

            # Rollback transaction
            else:
                tools_db.dao.rollback()

            # Close dialog, save dialog position, and disconnect snapping
            tools_gw.close_dialog(self.dlg_mincut)

            self.reset_mincut_canvas_snapping(action_pan=True)
            self._remove_selection()
            tools_qgis.refresh_map_canvas()

            # Close cursor and auxiliary connection
            self._close_mincut_cursor()

    def _real_start(self):

        # Run fct like 'Refresh mincut' but with action="mincutStart"
        self._refresh_mincut(action="mincutStart")

        date_start = QDate.currentDate()
        time_start = QTime.currentTime()
        self.dlg_mincut.cbx_date_start.setDate(date_start)
        self.dlg_mincut.cbx_hours_start.setTime(time_start)
        self.dlg_mincut.cbx_date_end.setDate(date_start)
        self.dlg_mincut.cbx_hours_end.setTime(time_start)
        self.dlg_mincut.btn_end.setEnabled(True)
        self.dlg_mincut.distance.setEnabled(True)
        self.dlg_mincut.depth.setEnabled(True)
        self.dlg_mincut.real_description.setEnabled(True)
        self.dlg_mincut.txt_chlorine.setEnabled(True)
        self.dlg_mincut.txt_turbidity.setEnabled(True)
        self.dlg_mincut.txt_equipment_code.setEnabled(True)
        self.dlg_mincut.txt_reagent_lot.setEnabled(True)

        # Set state to 'In Progress'
        tools_qt.set_widget_text(self.dlg_mincut, self.dlg_mincut.state, str(self.states[1]))
        self.current_state = 1

        # Enable/Disable widget depending state
        self._enable_widgets('1')

    def _real_end(self):

        # Create the dialog and signals
        self.dlg_fin = GwMincutEndUi(self)
        tools_gw.load_settings(self.dlg_fin)

        mincut = tools_qt.get_text(self.dlg_mincut, self.dlg_mincut.result_mincut_id)
        tools_qt.set_widget_text(self.dlg_fin, self.dlg_fin.mincut, mincut)
        work_order = tools_qt.get_text(self.dlg_mincut, self.dlg_mincut.work_order)
        if str(work_order) != 'null':
            tools_qt.set_widget_text(self.dlg_fin, self.dlg_fin.work_order, work_order)

        # Manage search widgets
        self._manage_search_widgets(self.dlg_fin)

        # Get values from mincut dialog
        muni_id = tools_qt.get_combo_value(self.dlg_mincut, self.dlg_mincut.cmb_municipality, 0)
        street = tools_qt.get_text(self.dlg_mincut, self.dlg_mincut.txt_street, return_string_null=False)
        postnumber = tools_qt.get_text(self.dlg_mincut, self.dlg_mincut.txt_postnumber, return_string_null=False)

        # Set values to search widgets
        if muni_id and muni_id not in (None, ""):
            tools_qt.set_combo_value(self.dlg_fin.cmb_municipality, muni_id, 0)
        if street and street not in (None, ""):
            tools_qt.set_widget_text(self.dlg_fin, self.dlg_fin.txt_street, street)
        if postnumber and postnumber not in (None, ""):
            tools_qt.set_widget_text(self.dlg_fin, self.dlg_fin.txt_postnumber, postnumber)

        # Fill ComboBox exec_user
        sql = ("SELECT name as id, name as idval "
               "FROM cat_users "
               "ORDER BY name")
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_fin.exec_user, rows)
        assigned_to = tools_qt.get_combo_value(self.dlg_mincut, self.dlg_mincut.assigned_to, 1)
        tools_qt.set_widget_text(self.dlg_fin, "exec_user", str(assigned_to))

        date_start = self.dlg_mincut.cbx_date_start.date()
        time_start = self.dlg_mincut.cbx_hours_start.time()
        self.dlg_fin.cbx_date_start_fin.setDate(date_start)
        self.dlg_fin.cbx_hours_start_fin.setTime(time_start)
        date_end = self.dlg_mincut.cbx_date_end.date()
        time_end = self.dlg_mincut.cbx_hours_end.time()
        self.dlg_fin.cbx_date_end_fin.setDate(date_end)
        self.dlg_fin.cbx_hours_end_fin.setTime(time_end)

        # Set state to 'Finished'
        tools_qt.set_widget_text(self.dlg_mincut, self.dlg_mincut.state, str(self.states[2]))
        self.current_state = 2

        # Enable/Disable widget depending state
        self._enable_widgets('2')

        # Set signals
        self.dlg_fin.btn_accept.clicked.connect(self._real_end_accept)
        self.dlg_fin.btn_accept.clicked.connect(partial(self._accept_save_data, self.dlg_fin))
        self.dlg_fin.btn_cancel.clicked.connect(self._real_end_cancel)
        self.dlg_fin.btn_set_real_location.clicked.connect(self._set_real_location)

        # Open the dialog
        tools_gw.open_dialog(self.dlg_fin, dlg_name='mincut_end')

    def _set_real_location(self):

        self.reset_mincut_canvas_snapping(action_pan=False)
        self.snapper_manager = GwSnapManager(self.iface)
        self.emit_point = QgsMapToolEmitPoint(self.canvas)
        self.canvas.setMapTool(self.emit_point)

        # Vertex marker
        self.vertex_marker = self.snapper_manager.vertex_marker

        # Activate snapping of node and arcs
        tools_gw.connect_signal(self.canvas.xyCoordinates, self._mouse_move_node_arc,
                                'mincut', 'real_end_xyCoordinates_mouse_move_node_arc')
        tools_gw.connect_signal(self.emit_point.canvasClicked, self._snapping_node_arc_real_location,
                                'mincut', 'real_end_ep_canvasClicked_snapping_node_arc_real_location')

    def _accept_save_data(self, dialog):
        """ Slot function button 'Accept' """

        tools_gw.save_settings(self.dlg_mincut)
        mincut_result_state = self.current_state

        # Manage 'address'
        municipality = tools_qt.get_combo_value(dialog, dialog.cmb_municipality)
        street = tools_qt.get_text(dialog, dialog.txt_street, return_string_null=False)
        postnumber = tools_qt.get_text(dialog, dialog.txt_postnumber, return_string_null=False)

        mincut_result_type = tools_qt.get_combo_value(self.dlg_mincut, self.dlg_mincut.type, 0)
        anl_cause = tools_qt.get_combo_value(self.dlg_mincut, self.dlg_mincut.cause, 0)
        work_order = self.dlg_mincut.work_order.text()

        anl_descript = tools_qt.get_text(self.dlg_mincut, "pred_description", return_string_null=False)
        exec_from_plot = str(self.dlg_mincut.distance.text())
        exec_depth = str(self.dlg_mincut.depth.text())
        exec_descript = tools_qt.get_text(self.dlg_mincut, "real_description", return_string_null=False)
        exec_user = tools_qt.get_text(self.dlg_mincut, "exec_user", return_string_null=False)

        # chlorine and turbidity
        chlorine = tools_qt.get_text(self.dlg_mincut, "txt_chlorine", return_string_null=False)
        turbidity = tools_qt.get_text(self.dlg_mincut, "txt_turbidity", return_string_null=False)
        equipment_code = tools_qt.get_text(self.dlg_mincut, "txt_equipment_code", return_string_null=False)
        reagent_lot = tools_qt.get_text(self.dlg_mincut, "txt_reagent_lot", return_string_null=False)

        # Get prediction date - start
        date_start_predict = self.dlg_mincut.cbx_date_start_predict.date()
        time_start_predict = self.dlg_mincut.cbx_hours_start_predict.time()
        forecast_start_predict = date_start_predict.toString(
            'yyyy-MM-dd') + " " + time_start_predict.toString('HH:mm:ss')

        # Get prediction date - end
        date_end_predict = self.dlg_mincut.cbx_date_end_predict.date()
        time_end_predict = self.dlg_mincut.cbx_hours_end_predict.time()
        forecast_end_predict = date_end_predict.toString('yyyy-MM-dd') + " " + time_end_predict.toString('HH:mm:ss')

        if forecast_start_predict > forecast_end_predict:
            message = "The start date must be before the end date"
            tools_qgis.show_warning(message)
            return

        # Get real date - start
        date_start_real = self.dlg_mincut.cbx_date_start.date()
        time_start_real = self.dlg_mincut.cbx_hours_start.time()
        forecast_start_real = date_start_real.toString('yyyy-MM-dd') + " " + time_start_real.toString('HH:mm:ss')

        # Get real date - end
        date_end_real = self.dlg_mincut.cbx_date_end.date()
        time_end_real = self.dlg_mincut.cbx_hours_end.time()
        forecast_end_real = date_end_real.toString('yyyy-MM-dd') + " " + time_end_real.toString('HH:mm:ss')

        if forecast_start_real > forecast_end_real:
            message = "The start date real must be before the end date real"
            tools_qgis.show_warning(message)
            return

        # Check data
        received_day = self.dlg_mincut.cbx_recieved_day.date()
        received_time = self.dlg_mincut.cbx_recieved_time.time()
        received_date = received_day.toString('yyyy-MM-dd') + " " + received_time.toString('HH:mm:ss')

        assigned_to = tools_qt.get_combo_value(self.dlg_mincut, self.dlg_mincut.assigned_to, 0)
        cur_user = tools_db.current_user
        appropiate_status = tools_qt.is_checked(self.dlg_mincut, "appropiate")

        check_data = [str(mincut_result_state), str(anl_cause), str(received_date),
                      str(forecast_start_predict), str(forecast_end_predict)]
        for data in check_data:
            if data == '':
                message = "Mandatory field is missing. Please, set a value"
                tools_qgis.show_warning(message)
                return

        if self.is_new:
            self.set_id_val()
            self.is_new = False

        # Check if id exist in table 'om_mincut'
        result_mincut_id = self.dlg_mincut.result_mincut_id.text()
        sql = (f"SELECT id FROM om_mincut "
               f"WHERE id = '{result_mincut_id}';")
        rows = tools_db.get_rows(sql)

        # If not found Insert just its 'id'
        sql = ""
        if not rows:
            sql = (f"INSERT INTO om_mincut (id) "
                   f"VALUES ('{result_mincut_id}');\n")

        # Update all the fields
        sql += (f"UPDATE om_mincut"
                f" SET mincut_state = '{mincut_result_state}',"
                f" mincut_type = '{mincut_result_type}', anl_cause = '{anl_cause}',"
                f" anl_tstamp = '{received_date}', received_date = '{received_date}',"
                f" forecast_start = '{forecast_start_predict}', forecast_end = '{forecast_end_predict}',"
                f" assigned_to = '{assigned_to}', exec_appropiate = '{appropiate_status}'")

        # Manage fields 'work_order' and 'anl_descript'
        if work_order != "":
            sql += f", work_order = $${work_order}$$"
        if anl_descript != "":
            sql += f", anl_descript = $${anl_descript}$$ "

        # Manage fields 'chlorine' and 'turbidity'
        if chlorine != "":
            sql += f", chlorine = $${chlorine}$$"
        if turbidity != "":
            sql += f", turbidity = $${turbidity}$$"

        # Manage fields 'equipment_code' and 'reagent_lot'
        if equipment_code != "":
            sql += f", equipment_code = $${equipment_code}$$"
        if reagent_lot != "":
            sql += f", reagent_lot = $${reagent_lot}$$"

        # Manage address
        if municipality != -1:
            sql += f", muni_id = '{municipality}'"
        if street not in (None, "", "null"):
            sql += f", streetaxis_id = $${street}$$"
        if postnumber:
            sql += f", postnumber = '{postnumber}'"

        # If state 'In Progress' or 'Finished'
        if mincut_result_state == 1 or mincut_result_state == 2:

            sql += f", exec_start = '{forecast_start_real}'"

            if mincut_result_state == 2:
                sql += f", exec_end = '{forecast_end_real}'"
            if exec_from_plot != '':
                sql += f", exec_from_plot = '{exec_from_plot}'"
            if exec_depth != '':
                sql += f",  exec_depth = '{exec_depth}'"
            if exec_descript != '':
                sql += f", exec_descript = $${exec_descript}$$"
            if exec_user != '':
                sql += f", exec_user = '{exec_user}'"
            else:
                sql += f", exec_user = '{cur_user}'"

        sql += f" WHERE id = '{result_mincut_id}';\n"

        # Check if any 'connec' or 'hydro' associated
        if self.sql_connec != "":
            sql += self.sql_connec

        if self.sql_hydro != "":
            sql += self.sql_hydro

        status = tools_db.execute_sql(sql, log_error=True)
        if status:
            message = "Values has been updated"
            tools_qgis.show_info(message)
            self._update_result_selector(result_mincut_id)
        else:
            message = "Error updating element in table, you need to review data"
            tools_qgis.show_warning(message)

        # Close dialog and disconnect snapping
        self.reset_mincut_canvas_snapping(action_pan=True)
        sql = (f"SELECT mincut_state, mincut_class FROM om_mincut "
               f" WHERE id = '{result_mincut_id}'")
        row = tools_db.get_row(sql)
        if not row:
            return

        use_planified = tools_qt.is_checked(self.dlg_mincut, 'chk_use_planified')
        result_mincut_id_text = self.dlg_mincut.result_mincut_id.text()
        extras = f'"action":"mincutAccept", "mincutClass":{self.mincut_class}, '
        extras += f'"mincutId":"{result_mincut_id_text}", "usePsectors":"{use_planified}"'
        body = tools_gw.create_body(extras=extras)
        result = self._execute_setmincut_with_cursor(body)
        if not result or result['status'] == 'Failed':
            return

        self._mincut_ok(result)
        self.form_has_changes = False
        try:
            # mark as saved so external guards can skip confirmation
            self.dlg_mincut.setProperty('saved', True)
        except Exception:
            pass

        self._save_widgets_values()
        self.iface.actionPan().trigger()
        self._remove_selection()

    def _create_mincut_cursor(self):
        """ Create auxiliary connection and cursor for setmincut function """

        try:
            # Close existing cursor and connection if they exist
            self._close_mincut_cursor()

            # Create new auxiliary connection
            self.mincut_aux_conn = tools_db.dao.get_aux_conn()
            if not self.mincut_aux_conn:
                return

            # Get cursor from the connection
            self.mincut_cursor = tools_db.dao.get_cursor(self.mincut_aux_conn)
            if self.mincut_cursor and tools_db.dao.set_search_path:
                # Set search path if configured
                self.mincut_cursor.execute(tools_db.dao.set_search_path)
        except Exception as e:
            msg = "Error creating mincut cursor: {0}"
            msg_params = (str(e),)
            tools_log.log_warning(msg, msg_params=msg_params)
            self._close_mincut_cursor()

    def _close_mincut_cursor(self):
        """ Close cursor and auxiliary connection for setmincut function """

        try:
            if self.mincut_cursor:
                self.mincut_cursor.close()
                self.mincut_cursor = None
            if self.mincut_aux_conn:
                tools_db.dao.delete_aux_con(self.mincut_aux_conn)
                self.mincut_aux_conn = None
        except Exception as e:
            msg = "Error closing mincut cursor: {0}"
            msg_params = (str(e),)
            tools_log.log_warning(msg, msg_params=msg_params)

    def _execute_setmincut_with_cursor(self, body, commit=True):
        """ Execute gw_fct_setmincut function using the stored cursor """

        if not self.mincut_cursor or not self.mincut_aux_conn:
            tools_log.log_warning("Mincut cursor not available, using regular execution")
            return tools_gw.execute_procedure('gw_fct_setmincut', body, commit=commit)

        try:
            # Build SQL similar to execute_procedure
            schema_name = lib_vars.schema_name
            if schema_name:
                sql = f"SELECT {schema_name}.gw_fct_setmincut("
            else:
                sql = "SELECT gw_fct_setmincut("

            if body:
                sql += f"{body}"
            sql += ");"

            # Log SQL if enabled (similar to execute_procedure)
            if sql:
                tools_log.log_db(sql, bold='b', stack_level_increase=2)

            # Execute using the stored cursor
            self.mincut_cursor.execute(sql)
            row = self.mincut_cursor.fetchone()

            if commit:
                self.mincut_aux_conn.commit()

            if not row or not row[0]:
                msg = "Function error: gw_fct_setmincut"
                tools_log.log_warning(msg)
                tools_log.log_warning(sql)
                return None

            json_result = row[0]

            # Log SQL if enabled
            if tools_gw.get_config_parser('log', 'log_sql', "user", "init", False) == "True":
                title = "SERVER RESPONSE"
                tools_log.log_db(json_result, header=title)

            if 'status' not in json_result:
                tools_gw.manage_json_exception(json_result, sql, is_thread=False)
                return False

            # If failed, manage exception (but don't rollback - commit already happened)
            if json_result.get('status') == 'Failed':
                tools_gw.manage_json_exception(json_result, sql, is_thread=False)
                return json_result

            # Manage geometry transformation if needed
            try:
                if json_result.get("body", {}).get("feature", {}).get("geometry") and lib_vars.data_epsg != lib_vars.project_epsg:
                    json_result = tools_gw.manage_json_geometry(json_result)
            except Exception:
                pass

            tools_gw.manage_json_response(json_result, sql, None)
            return json_result

        except Exception as e:
            msg = "Error executing setmincut with cursor: {0}"
            msg_params = (str(e),)
            tools_log.log_warning(msg, msg_params=msg_params)
            sql_error = sql if 'sql' in locals() else 'N/A'
            msg = "SQL: {0}"
            msg_params = (sql_error,)
            tools_log.log_warning(msg, msg_params=msg_params)
            if commit:
                try:
                    self.mincut_aux_conn.rollback()
                except Exception:
                    pass
            # Fallback to regular execution
            return tools_gw.execute_procedure('gw_fct_setmincut', body, commit=commit)

    def _mincut_ok(self, result):

        # Manage result and force tab log
        tools_gw.fill_tab_log(self.dlg_mincut, result['body']['data'], True, True, tab_idx=3)

        # Set tabs enabled(True/False)
        qtabwidget = self.dlg_mincut.findChild(QTabWidget, 'mainTab')
        qtabwidget.widget(0).setEnabled(False)  # Tab plan
        qtabwidget.widget(1).setEnabled(True)   # Tab Exec
        qtabwidget.widget(2).setEnabled(True)   # Tab hydro
        qtabwidget.widget(3).setEnabled(True)   # Tab Log

        self.dlg_mincut.closeMainWin = False
        self.dlg_mincut.mincutCanceled = True

        if self.mincut_class == 1:
            try:
                bbox = result['body']['data']['geometry']['bbox']
            except KeyError:
                bbox = None
            if bbox:
                x1, y1, x2, y2 = bbox.get('x1'), bbox.get('y1'), bbox.get('x2'), bbox.get('y2')
                if None in (x1, y1, x2, y2):
                    message = "Error on create auto mincut, you need to review data"
                    tools_qgis.show_warning(message)
                    tools_qgis.restore_cursor()
                    return
                tools_qgis.zoom_to_rectangle(x1, y1, x2, y2, margin=0)

        self.dlg_mincut.btn_accept.hide()
        title = "Close"
        self.dlg_mincut.btn_cancel.setText(tools_qt.tr(title))
        self.action_add_connec.setEnabled(False)
        self.action_add_hydrometer.setEnabled(False)
        self.dlg_mincut.btn_cancel.disconnect()
        self.dlg_mincut.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_mincut))
        self.dlg_mincut.btn_cancel.clicked.connect(partial(tools_qgis.restore_user_layer, 've_node', self.user_current_layer))
        self.dlg_mincut.btn_cancel.clicked.connect(partial(self._remove_selection))
        self.dlg_mincut.btn_cancel.clicked.connect(partial(tools_qgis.reset_rubber_band, self.search_rubber_band))
        self._refresh_tab_hydro()

        self.action_mincut.setEnabled(False)
        self.action_refresh_mincut.setEnabled(False)
        self.action_custom_mincut.setEnabled(False)
        self.action_change_valve_status.setEnabled(False)
        self.action_export_hydro_csv.setEnabled(True)

    def _update_result_selector(self, result_mincut_id: int = None, commit: bool = True) -> None:
        """ Update table 'selector_mincut_result' """

        mincut_conflict_state = 5
        conflict_group_id = None

        sql = (
            "DELETE FROM selector_mincut_result WHERE cur_user = current_user;"
        )
        if result_mincut_id:
            row = tools_db.get_row(f"SELECT id FROM om_mincut_conflict WHERE mincut_id = {result_mincut_id}")
            conflict_group_id = row[0] if row is not None else ''
            sql += (
                f"\nINSERT INTO selector_mincut_result (result_id, cur_user, result_type) VALUES"
                f" ({result_mincut_id}, current_user, 'current') ON CONFLICT (result_id, cur_user) DO NOTHING;"
            )
        if conflict_group_id:
            sql += (
                f"\nINSERT INTO selector_mincut_result (result_id, cur_user, result_type)"
                f" SELECT omc.mincut_id, current_user, 'conflict' "
                f" FROM om_mincut_conflict omc"
                f" JOIN om_mincut om ON om.id = omc.mincut_id"
                f" WHERE omc.id = '{conflict_group_id}'"
                f" AND omc.mincut_id <> {result_mincut_id}"
                f" AND om.mincut_state <> {mincut_conflict_state}"
                f" ON CONFLICT (result_id, cur_user) DO NOTHING;"
                f"\nINSERT INTO selector_mincut_result (result_id, cur_user, result_type)"
                f" SELECT omc.mincut_id, current_user, 'affected' "
                f" FROM om_mincut_conflict omc"
                f" JOIN om_mincut om ON om.id = omc.mincut_id"
                f" WHERE omc.id = '{conflict_group_id}'"
                f" AND omc.mincut_id <> {result_mincut_id}"
                f" AND om.mincut_state = {mincut_conflict_state}"
                f" ON CONFLICT (result_id, cur_user) DO NOTHING;"
            )
        status = tools_db.execute_sql(sql, commit)

        if not status:
            message = "Error updating table"
            tools_qgis.show_warning(message, parameter='selector_mincut_result')

    def _real_end_accept(self):

        # Get end_date and end_hour from mincut_end dialog
        exec_start_day = self.dlg_fin.cbx_date_start_fin.date()
        exec_start_time = self.dlg_fin.cbx_hours_start_fin.time()
        exec_end_day = self.dlg_fin.cbx_date_end_fin.date()
        exec_end_time = self.dlg_fin.cbx_hours_end_fin.time()

        # Set new values in mincut dialog also
        self.dlg_mincut.cbx_date_start.setDate(exec_start_day)
        self.dlg_mincut.cbx_hours_start.setTime(exec_start_time)
        self.dlg_mincut.cbx_date_end.setDate(exec_end_day)
        self.dlg_mincut.cbx_hours_end.setTime(exec_end_time)
        tools_qt.set_widget_text(self.dlg_mincut, self.dlg_mincut.work_order, str(self.dlg_fin.work_order.text()))
        exec_user = tools_qt.get_text(self.dlg_fin, self.dlg_fin.exec_user)
        tools_qt.set_combo_value(self.dlg_mincut.assigned_to, exec_user, 1)

        self.dlg_fin.close()

    def _real_end_cancel(self):

        # Return to state 'In Progress'
        tools_qt.set_widget_text(self.dlg_mincut, self.dlg_mincut.state, str(self.states[1]))
        self._enable_widgets('1')

        self.dlg_fin.close()

    def _add_connec(self):
        """ B3-121: Connec selector """

        self.mincut_class = 2
        self.dlg_mincut.closeMainWin = True
        self.dlg_mincut.canceled = False
        result_mincut_id_text = self.dlg_mincut.result_mincut_id.text()

        # Check if id exist in om_mincut
        sql = (f"SELECT id FROM om_mincut"
               f" WHERE id = '{result_mincut_id_text}';")
        exist_id = tools_db.get_row(sql)
        if not exist_id:
            sql = (f"INSERT INTO om_mincut (id, mincut_class) "
                   f" VALUES ('{result_mincut_id_text}', 2);")
            tools_db.execute_sql(sql)
            self.is_new = False

        # Disable Auto, Custom, Hydrometer
        self.action_mincut.setDisabled(True)
        self.action_refresh_mincut.setDisabled(True)
        self.action_custom_mincut.setDisabled(True)
        self.action_change_valve_status.setDisabled(True)
        self.action_add_hydrometer.setDisabled(True)

        # Set dialog add_connec
        self.dlg_connec = GwMincutConnecUi(self)
        title = "Connec management"
        self.dlg_connec.setWindowTitle(tools_qt.tr(title))
        tools_gw.load_settings(self.dlg_connec)
        self.dlg_connec.tbl_om_mincut_connec.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        # Set icons
        tools_gw.add_icon(self.dlg_connec.btn_insert, "111")
        tools_gw.add_icon(self.dlg_connec.btn_delete, "112")
        tools_gw.add_icon(self.dlg_connec.btn_snapping, "137")

        # Set signals
        self.dlg_connec.btn_insert.clicked.connect(partial(self._insert_connec))
        self.dlg_connec.btn_delete.clicked.connect(partial(self._delete_records_connec))
        self.dlg_connec.btn_snapping.clicked.connect(self._snapping_init_connec)
        self.dlg_connec.btn_accept.clicked.connect(partial(self._accept_connec, self.dlg_connec, "connec"))
        self.dlg_connec.rejected.connect(partial(tools_gw.close_dialog, self.dlg_connec))
        self.dlg_connec.rejected.connect(partial(tools_qgis.disconnect_signal_selection_changed))

        # Enabled button accept from mincut form
        self.dlg_mincut.btn_accept.setEnabled(True)

        # Set autocompleter for 'customer_code'
        self._set_completer_customer_code(self.dlg_connec.connec_id)

        # On opening form check if result_id already exist in om_mincut_connec
        # if exist show data in form / show selection!!!
        if exist_id:
            # Read selection and reload table
            self._select_features_connec()
        self._snapping_selection_connec()
        for layer in self.layers_connec:
            layer.dataProvider().reloadData()

        tools_gw.open_dialog(self.dlg_connec, dlg_name='mincut_connec')

    def _set_completer_customer_code(self, widget, set_signal=False):
        """ Set autocompleter for 'customer_code' """

        # Get list of 'customer_code'
        sql = f"SELECT DISTINCT({self.col1}) FROM ve_connec"
        rows = tools_db.get_rows(sql)
        values = []
        if rows:
            for row in rows:
                values.append(str(row[0]))

        # Adding auto-completion to a QLineEdit
        self.completer = QCompleter()
        widget.setCompleter(self.completer)
        model = QStringListModel()
        model.setStringList(values)
        self.completer.setModel(model)

        if set_signal:
            # noinspection PyUnresolvedReferences
            self.completer.activated.connect(self._auto_fill_hydro_id)

    def _snapping_init_connec(self):
        """ Snap connec """
        self.rel_feature_type = 'connec'

        tools_gw.selection_init(self, self.dlg_connec, 'om_mincut', GwSelectionMode.MINCUT_CONNEC)

    def _snapping_selection_hydro(self):
        """ Snap to connec layers to add its hydrometers """

        self.rel_list_ids['connec'] = []

        for layer in self.layers_connec:
            if layer.selectedFeatureCount() > 0:
                # Get selected features of the layer
                features = layer.selectedFeatures()
                # Get id from all selected features
                for feature in features:
                    connec_id = feature.attribute("connec_id")
                    # Add element
                    if connec_id in self.rel_list_ids['connec']:
                        msg = "Feature already in the list"
                        tools_qt.show_info_box(msg, parameter=connec_id)
                        return
                    else:
                        self.rel_list_ids['connec'].append(str(connec_id))

        # Set 'expr_filter' with features that are in the list
        expr_filter = "\"connec_id\" IN ("
        for i in range(len(self.rel_list_ids['connec'])):
            expr_filter += f"'{self.rel_list_ids['connec'][i]}', "
        expr_filter = expr_filter[:-2] + ")"
        if len(self.rel_list_ids['connec']) == 0:
            expr_filter = "\"connec_id\" =''"
        # Check expression
        (is_valid, expr) = tools_qt.check_expression_filter(expr_filter)  # @UnusedVariable
        if not is_valid:
            return

        self._reload_table_hydro(expr_filter)

    def _snapping_selection_connec(self):
        """ Snap to connec layers """

        self.rel_list_ids['connec'] = []

        for layer in self.layers_connec:
            if layer.selectedFeatureCount() > 0:
                # Get selected features of the layer
                features = layer.selectedFeatures()
                # Get id from all selected features
                for feature in features:
                    connec_id = feature.attribute("connec_id")
                    # Add element
                    if connec_id not in self.rel_list_ids['connec']:
                        self.rel_list_ids['connec'].append(str(connec_id))

        expr_filter = None
        if len(self.rel_list_ids['connec']) > 0:
            # Set 'expr_filter' with features that are in the list
            expr_filter = "\"connec_id\" IN ("
            for i in range(len(self.rel_list_ids['connec'])):
                expr_filter += f"'{self.rel_list_ids['connec'][i]}', "
            expr_filter = expr_filter[:-2] + ")"
            if len(self.rel_list_ids['connec']) == 0:
                expr_filter = "\"connec_id\" =''"
            # Check expression
            (is_valid, expr) = tools_qt.check_expression_filter(expr_filter)  # @UnusedVariable
            if not is_valid:
                return

        self._reload_table_connec(expr_filter)

    def _add_hydrometer(self):
        """ B4-122: Hydrometer selector """

        self.mincut_class = 3
        self.dlg_mincut.closeMainWin = True
        self.dlg_mincut.canceled = False
        self.rel_list_ids['connec'] = []
        result_mincut_id_text = self.dlg_mincut.result_mincut_id.text()

        # Get hydrometer filter columns
        row = tools_gw.get_config_value('om_mincut_hydrometer_filter', table='config_param_system')
        if row:
            values = json.loads(row[0])
            self.col1 = values['field1']
            self.col2 = values['field2']
            self.lbl1 = values['label1']
            self.lbl2 = values['label2']

        # Check if id exist in table 'om_mincut'
        sql = (f"SELECT id FROM om_mincut"
               f" WHERE id = '{result_mincut_id_text}';")
        exist_id = tools_db.get_row(sql)
        if not exist_id:
            sql = (f"INSERT INTO om_mincut (id, mincut_class)"
                   f" VALUES ('{result_mincut_id_text}', 3);")
            tools_db.execute_sql(sql)
            self.is_new = False

        # On inserting work order
        self.action_mincut.setDisabled(True)
        self.action_refresh_mincut.setDisabled(True)
        self.action_custom_mincut.setDisabled(True)
        self.action_change_valve_status.setDisabled(True)
        self.action_add_connec.setDisabled(True)

        # Set dialog MincutHydrometer
        self.dlg_hydro = GwMincutHydrometerUi(self)
        tools_gw.load_settings(self.dlg_hydro)
        title = "Hydrometer management"
        self.dlg_hydro.setWindowTitle(tools_qt.tr(title))
        self.dlg_hydro.tbl_hydro.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)

        # Set icons
        tools_gw.add_icon(self.dlg_hydro.btn_insert, "111")
        tools_gw.add_icon(self.dlg_hydro.btn_delete, "112")

        # Set labels
        self.dlg_hydro.lbl_ccc.setText(self.lbl1)
        self.dlg_hydro.lbl_hcc.setText(self.lbl2)

        # Set signals
        self.dlg_hydro.btn_insert.clicked.connect(partial(self._insert_hydro))
        self.dlg_hydro.btn_delete.clicked.connect(partial(self._delete_records_hydro))
        self.dlg_hydro.btn_accept.clicked.connect(partial(self._accept_hydro, self.dlg_hydro, "hydrometer"))

        # Enabled button accept from mincut form
        self.dlg_mincut.btn_accept.setEnabled(True)

        # Set autocompleter for 'customer_code'
        self._set_completer_customer_code(self.dlg_hydro.customer_code_connec, True)

        # Set signal to reach selected value from QCompleter
        if exist_id:
            # Read selection and reload table
            self._select_features_hydro()

        tools_gw.open_dialog(self.dlg_hydro, 'mincut_hydrometer')

    def _auto_fill_hydro_id(self):

        # Adding auto-completion to a QLineEdit - hydrometer_id
        self.completer_hydro = QCompleter()
        self.dlg_hydro.hydrometer_cc.setCompleter(self.completer_hydro)
        model = QStringListModel()

        # Get 'connec_id' from 'customer_code'
        customer_code = str(self.dlg_hydro.customer_code_connec.text())
        connec_id = self._get_connec_id_from_customer_code(customer_code)
        if connec_id is None:
            return

        # Get 'hydrometers' related with this 'connec'
        sql = (f"SELECT DISTINCT(h.{self.col2})"
               f" FROM vf_hydrometer h"
               f" JOIN connec c ON c.customer_code::text = h.feature_customer_code::text"
               f" WHERE c.connec_id = '{connec_id}'")
        rows = tools_db.get_rows(sql)
        values = []
        if rows:
            for row in rows:
                values.append(str(row[0]))

        model.setStringList(values)
        self.completer_hydro.setModel(model)

    def _insert_hydro(self):
        """ Select feature with entered id. Set a model with selected filter.
            Attach that model to selected table
        """

        # Check if user entered hydrometer_id
        hydrometer_cc = tools_qt.get_text(self.dlg_hydro, self.dlg_hydro.hydrometer_cc)
        if hydrometer_cc == "null":
            msg = "You need to enter hydrometer_id"
            tools_qt.show_info_box(msg)
            return

        # Show message if element is already in the list
        if hydrometer_cc in self.hydro_list:
            msg = "Selected element already in the list"
            tools_qt.show_info_box(msg, parameter=hydrometer_cc)
            return

        # Check if hydrometer_id belongs to any 'connec_id'
        sql = (f"SELECT hydrometer_id FROM vf_hydrometer"
               f" WHERE {self.col2} = '{hydrometer_cc}'")
        row = tools_db.get_row(sql)
        if not row:
            msg = "Selected hydrometer_id not found"
            tools_qt.show_info_box(msg, parameter=hydrometer_cc)
            return

        if row[0] in self.hydro_list:
            msg = "Selected element already in the list"
            tools_qt.show_info_box(msg, parameter=hydrometer_cc)
            return

        # Set expression filter with 'hydro_list'
        if row[0] in self.deleted_list:
            self.deleted_list.remove(row[0])
        self.hydro_list.append(row[0])
        expr_filter = "\"hydrometer_id\" IN ("
        for i in range(len(self.hydro_list)):
            expr_filter += f"'{self.hydro_list[i]}', "
        expr_filter = expr_filter[:-2] + ")"

        # Reload table
        self._reload_table_hydro(expr_filter)

    def _select_features_group_layers(self, expr):
        """ Select features of the layers filtering by @expr """

        # Iterate over all layers of type 'connec'
        # Select features and them to 'connec_list'
        for layer in self.layers_connec:
            it = layer.getFeatures(QgsFeatureRequest(expr))
            # Build a list of feature id's from the previous result
            id_list = [i.id() for i in it]
            # Select features with these id's
            layer.selectByIds(id_list)
            if layer.selectedFeatureCount() > 0:
                # Get selected features of the layer
                features = layer.selectedFeatures()
                for feature in features:
                    connec_id = feature.attribute("connec_id")
                    # Check if 'connec_id' is already in 'connec_list'
                    if connec_id not in self.rel_list_ids['connec']:
                        self.rel_list_ids['connec'].append(str(connec_id))

    def _select_features_connec(self):
        """ Select features of 'connec' of selected mincut """

        # Set 'expr_filter' of connecs related with current mincut
        result_mincut_id = tools_qt.get_text(self.dlg_mincut, self.dlg_mincut.result_mincut_id)
        sql = (f"SELECT connec_id FROM om_mincut_connec"
               f" WHERE result_id = {result_mincut_id}")
        rows = tools_db.get_rows(sql)

        expr_filter = "\"connec_id\" IN ("
        if rows:
            for row in rows:
                if row[0] not in self.rel_list_ids['connec'] and row[0] not in self.deleted_list:
                    self.rel_list_ids['connec'].append(str(row[0]))

        if self.rel_list_ids['connec']:
            for connec_id in self.rel_list_ids['connec']:
                expr_filter += f"'{connec_id}', "
            expr_filter = expr_filter[:-2] + ")"
            if len(self.rel_list_ids['connec']) == 0:
                expr_filter = "\"connec_id\" =''"
            # Check expression
            (is_valid, expr) = tools_qt.check_expression_filter(expr_filter)
            if not is_valid:
                return

            # Select features of the layers filtering by @expr
            self._select_features_group_layers(expr)

            # Reload table
            self._reload_table_connec(expr_filter)

    def _select_features_hydro(self):

        self.rel_list_ids['connec'] = []

        # Set 'expr_filter' of connecs related with current mincut
        result_mincut_id = tools_qt.get_text(self.dlg_hydro, self.result_mincut_id)
        sql = (f"SELECT DISTINCT(connec_id) FROM v_hydrometer AS rtc"
               f" JOIN connec ON connec.customer_code::text = rtc.feature_customer_code::text"
               f" INNER JOIN om_mincut_hydrometer AS anl"
               f" ON anl.hydrometer_id = rtc.hydrometer_id"
               f" WHERE result_id = {result_mincut_id}")
        rows = tools_db.get_rows(sql)
        if rows:
            expr_filter = "\"connec_id\" IN ("
            for row in rows:
                expr_filter += f"'{row[0]}', "
            expr_filter = expr_filter[:-2] + ")"
            if len(self.rel_list_ids['connec']) == 0:
                expr_filter = "\"connec_id\" =''"
            # Check expression
            (is_valid, expr) = tools_qt.check_expression_filter(expr_filter)
            if not is_valid:
                return

            # Select features of the layers filtering by @expr
            self._select_features_group_layers(expr)

        # Get list of 'hydrometer_id' belonging to current result_mincut
        result_mincut_id = tools_qt.get_text(self.dlg_hydro, self.result_mincut_id)
        sql = (f"SELECT hydrometer_id FROM om_mincut_hydrometer"
               f" WHERE result_id = {result_mincut_id}")
        rows = tools_db.get_rows(sql)

        expr_filter = "\"hydrometer_id\" IN ("
        if rows:
            for row in rows:
                if row[0] not in self.hydro_list:
                    self.hydro_list.append(row[0])
        for hyd in self.deleted_list:
            if hyd in self.hydro_list:
                self.hydro_list.remove(hyd)
        for hyd in self.hydro_list:
            expr_filter += f"'{hyd}', "

        expr_filter = expr_filter[:-2] + ")"
        if len(self.hydro_list) == 0:
            expr_filter = "\"hydrometer_id\" =''"
        # Reload contents of table 'hydro' with expr_filter
        self._reload_table_hydro(expr_filter)

    def _insert_connec(self):
        """ Select feature with entered id. Set a model with selected filter.
            Attach that model to selected table
        """

        tools_qgis.disconnect_signal_selection_changed()
        tools_gw.disconnect_signal('mincut_selection_changed')

        # Get 'connec_id' from selected 'customer_code'
        customer_code = tools_qt.get_text(self.dlg_connec, self.dlg_connec.connec_id)
        if customer_code == 'null':
            msg = "You need to enter a customer code"
            tools_qt.show_info_box(msg)
            return

        connec_id = self._get_connec_id_from_customer_code(customer_code)
        if connec_id is None:
            return

        # Iterate over all layers
        for layer in self.layers_connec:
            if layer.selectedFeatureCount() > 0:
                # Get selected features of the layer
                features = layer.selectedFeatures()
                for feature in features:
                    # Append 'connec_id' into 'connec_list'
                    selected_id = feature.attribute("connec_id")
                    if selected_id not in self.rel_list_ids['connec']:
                        self.rel_list_ids['connec'].append(str(selected_id))

        # Show message if element is already in the list
        if connec_id in self.rel_list_ids['connec']:
            msg = "Selected element already in the list"
            tools_qt.show_info_box(msg, parameter=connec_id)
            return

        # If feature id doesn't exist in list -> add
        self.rel_list_ids['connec'].append(str(connec_id))

        expr_filter = None
        if len(self.rel_list_ids['connec']) > 0:

            # Set expression filter with 'connec_list'
            expr_filter = "\"connec_id\" IN ("
            for i in range(len(self.rel_list_ids['connec'])):
                expr_filter += f"'{self.rel_list_ids['connec'][i]}', "
            expr_filter = expr_filter[:-2] + ")"
            if len(self.rel_list_ids['connec']) == 0:
                expr_filter = "\"connec_id\" =''"
            # Check expression
            (is_valid, expr) = tools_qt.check_expression_filter(expr_filter)
            if not is_valid:
                return

            # Select features with previous filter
            for layer in self.layers_connec:
                # Build a list of feature id's and select them
                it = layer.getFeatures(QgsFeatureRequest(expr))
                id_list = [i.id() for i in it]
                layer.selectByIds(id_list)

        # Reload contents of table 'connec'
        self._reload_table_connec(expr_filter)

        self.connect_signal_selection_changed("mincut_connec")

    def _get_connec_id_from_customer_code(self, customer_code):
        """ Get 'connec_id' from @customer_code """

        sql = (f"SELECT connec_id FROM ve_connec"
               f" WHERE {self.col1} = '{customer_code}'")
        row = tools_db.get_row(sql)
        if not row:
            msg = "Any connec_id found with this customer_code"
            tools_qt.show_info_box(msg, parameter=customer_code)
            return None
        else:
            return str(row[0])

    def _reload_table_connec(self, expr_filter=None):
        """ Reload contents of table 'connec' with selected @expr_filter """
        expr = tools_qt.set_table_model(self.dlg_connec, 'tbl_om_mincut_connec', "connec", expr_filter)
        tools_gw.set_tablemodel_config(self.dlg_connec, 'tbl_om_mincut_connec', 've_connec')
        return expr

    def _reload_table_hydro(self, expr_filter=None):
        """ Reload contents of table 'hydro' """

        expr = tools_qt.set_table_model(self.dlg_hydro, "tbl_hydro", "vf_hydrometer", expr_filter)
        tools_gw.set_tablemodel_config(self.dlg_hydro, "tbl_hydro", 'vf_hydrometer')
        return expr

    def _delete_records_connec(self):
        """ Delete selected rows of the table """

        tools_qgis.disconnect_signal_selection_changed()
        tools_gw.disconnect_signal('mincut_selection_changed')

        # Get selected rows
        widget = self.dlg_connec.tbl_om_mincut_connec
        selected_list = widget.selectionModel().selectedRows()
        if len(selected_list) == 0:
            message = "Any record selected"
            tools_qgis.show_warning(message, dialog=self.dlg_connec)
            return

        del_id = []
        inf_text = ""
        for i in range(0, len(selected_list)):
            row = selected_list[i].row()
            # Id to delete
            id_feature = widget.model().record(row).value("connec_id")
            del_id.append(id_feature)
            # Id to ask
            customer_code = widget.model().record(row).value(f"{self.col1}")
            inf_text += str(customer_code) + ", "
        inf_text = inf_text[:-2]
        msg = "Are you sure you want to delete these records?"
        title = "Delete records"
        answer = tools_qt.show_question(msg, title, inf_text)
        if not answer:
            return

        for el in del_id:
            self.deleted_list.append(el)
            self.rel_list_ids['connec'].remove(str(el))

        # Select features which are in the list
        expr_filter = "\"connec_id\" IN ("
        for i in range(len(self.rel_list_ids['connec'])):
            expr_filter += f"'{self.rel_list_ids['connec'][i]}', "
        expr_filter = expr_filter[:-2] + ")"

        if len(self.rel_list_ids['connec']) == 0:
            expr_filter = "connec_id=''"

        # Update model of the widget with selected expr_filter
        expr = self._reload_table_connec(expr_filter)

        # Reload selection
        for layer in self.layers_connec:
            # Build a list of feature id's and select them
            it = layer.getFeatures(QgsFeatureRequest(expr))
            id_list = [i.id() for i in it]
            layer.selectByIds(id_list)

        self.connect_signal_selection_changed("mincut_connec")

    def _delete_records_hydro(self):
        """ Delete selected rows of the table """

        # Get selected rows
        widget = self.dlg_hydro.tbl_hydro
        selected_list = widget.selectionModel().selectedRows()
        if len(selected_list) == 0:
            message = "Any record selected"
            tools_qgis.show_warning(message, dialog=self.dlg_hydro)
            return

        del_id = []
        inf_text = ""
        for i in range(0, len(selected_list)):
            row = selected_list[i].row()
            id_feature = widget.model().record(row).value(f"{self.col2}")
            hydro_id = widget.model().record(row).value("hydrometer_id")
            inf_text += str(id_feature) + ", "
            del_id.append(hydro_id)
        inf_text = inf_text[:-2]
        msg = "Are you sure you want to delete these records?"
        title = "Delete records"
        answer = tools_qt.show_question(msg, title, inf_text)
        if not answer:
            return

        for el in del_id:
            self.hydro_list.remove(el)
            if el not in self.deleted_list:
                self.deleted_list.append(el)

        # Select features that are in the list
        expr_filter = "\"hydrometer_id\" IN ("
        for i in range(len(self.hydro_list)):
            expr_filter += f"'{self.hydro_list[i]}', "
        expr_filter = expr_filter[:-2] + ")"

        if len(self.hydro_list) == 0:
            expr_filter = "hydrometer_id=''"

        # Update model of the widget with selected expr_filter
        self._reload_table_hydro(expr_filter)

        self.connect_signal_selection_changed("mincut_hydro")

    def _accept_connec(self, dlg, element):
        """ Slot function widget 'btn_accept' of 'connec' dialog
            Insert into table 'om_mincut_connec' values of current mincut
        """

        result_mincut_id = tools_qt.get_text(dlg, self.dlg_mincut.result_mincut_id)
        if result_mincut_id == 'null':
            return

        sql = (f"DELETE FROM om_mincut_{element}"
               f" WHERE result_id = {result_mincut_id};\n")
        sql += (f"DELETE FROM om_mincut_hydrometer"
               f" WHERE result_id = {result_mincut_id};\n")
        for element_id in self.rel_list_ids['connec']:
            sql += (f"INSERT INTO om_mincut_{element}"
                    f" (result_id, {element}_id) "
                    f" VALUES ('{result_mincut_id}', '{element_id}');\n")
            # Get hydrometer_id of selected connec
            sql2 = (f"SELECT h.hydrometer_id FROM vf_hydrometer h"
                    f" JOIN connec c ON c.customer_code::text = h.feature_customer_code::text"
                    f" WHERE c.connec_id = '{element_id}'")
            rows = tools_db.get_rows(sql2)
            if rows:
                for row in rows:
                    # Hydrometers associated to selected connec inserted to the table om_mincut_hydrometer
                    sql += (f"INSERT INTO om_mincut_hydrometer"
                            f" (result_id, hydrometer_id) "
                            f" VALUES ('{result_mincut_id}', '{row[0]}');\n")

        self.sql_connec = sql
        self.dlg_mincut.btn_start.setDisabled(False)
        tools_gw.close_dialog(self.dlg_connec)

    def _accept_hydro(self, dlg, element):
        """ Slot function widget 'btn_accept' of 'hydrometer' dialog
            Insert into table 'om_mincut_hydrometer' values of current mincut
        """

        result_mincut_id = tools_qt.get_text(dlg, self.dlg_mincut.result_mincut_id)
        if result_mincut_id == 'null':
            return

        sql = (f"DELETE FROM om_mincut_{element}"
               f" WHERE result_id = {result_mincut_id};\n")
        for element_id in self.hydro_list:
            sql += (f"INSERT INTO om_mincut_{element}"
                    f" (result_id, {element}_id) "
                    f" VALUES ('{result_mincut_id}', '{element_id}');\n")

        self.sql_hydro = sql
        self.dlg_mincut.btn_start.setDisabled(False)
        tools_gw.close_dialog(self.dlg_hydro)

    def _auto_mincut(self, is_checked):
        """ B1-126: Automatic mincut analysis """

        if is_checked is False:
            self.reset_mincut_canvas_snapping(action_pan=False)
            # Recover snapping options, refresh canvas & set visible layers
            return

        self.reset_mincut_canvas_snapping(action_pan=False)

        self.mincut_class = 1
        self.emit_point = QgsMapToolEmitPoint(self.canvas)
        self.canvas.setMapTool(self.emit_point)
        self.snapper_manager = GwSnapManager(self.iface)
        self.snapper = self.snapper_manager.get_snapper()

        self._init_mincut_canvas()
        self.dlg_mincut.closeMainWin = True
        self.dlg_mincut.canceled = False

        # Vertex marker
        self.vertex_marker = self.snapper_manager.vertex_marker

        # On inserting work order
        self.action_add_connec.setDisabled(True)
        self.action_add_hydrometer.setDisabled(True)

        # Store user snapping configuration
        self.previous_snapping = self.snapper_manager.get_snapping_options()

        # Set signals
        tools_gw.connect_signal(self.canvas.xyCoordinates, self._mouse_move_node_arc, 'mincut',
                                'auto_mincut_xyCoordinates_mouse_move_node_arc')
        tools_gw.connect_signal(self.emit_point.canvasClicked, self._auto_mincut_snapping,
                                'mincut', 'auto_mincut_ep_canvasClicked_auto_mincut_snapping')

    def _export_hydro_csv(self):
        """ : Export Hydro Csv """

        result_mincut_id = tools_qt.get_text(self.dlg_mincut, "result_mincut_id")

        folder_path = tools_qt.get_save_file_path(
            self.dlg_mincut, '', '*.csv', 'Save as',
            os.path.expanduser("~/Documents" if os.name == 'nt' else "~"),
            f'{result_mincut_id}_{datetime.now().strftime("%d%m%Y")}'
        )

        if not folder_path:
            return
        # Export to csv
        if folder_path.find('.csv') == -1:
            folder_path += '.csv'

        if self.dlg_mincut.tbl_hydro:
            model = self.dlg_mincut.tbl_hydro.model()
        else:
            return

        # Convert qtable values into list
        all_rows = []
        headers = []
        for i in range(0, model.columnCount()):
            headers.append(str(model.headerData(i, Qt.Orientation.Horizontal)))
        all_rows.append(headers)
        for rows in range(0, model.rowCount()):
            row = []
            for col in range(0, model.columnCount()):
                row.append(str(model.data(model.index(rows, col))))
            all_rows.append(row)

        # Write list into csv file
        try:
            with open(folder_path, "w") as output:
                writer = csv.writer(output, lineterminator='\n')
                writer.writerows(all_rows)
            tools_gw.set_config_parser('btn_search', 'search_csv_path', f"{tools_qt.get_text(self.dlg_mincut, 'txt_path')}")
            message = "The csv file has been successfully exported"
            tools_qgis.show_info(message, dialog=self.dlg_mincut)

        except Exception:
            msg = "File path doesn't exist or you dont have permission or file is opened"
            tools_qgis.show_warning(msg, dialog=self.dlg_mincut)

    def _mouse_move_node_arc(self, point):

        if not self.layer_arc:
            return

        # Set active layer
        self.iface.setActiveLayer(self.layer_arc)

        # Get clicked point and add marker
        self.vertex_marker.hide()
        event_point = self.snapper_manager.get_event_point(point=point)
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if result.isValid():
            self.snapper_manager.add_marker(result, self.vertex_marker)

    def _auto_mincut_snapping(self, point, btn):
        """ Automatic mincut: Snapping to 'node' and 'arc' layers """

        # Manage if task is already running
        if hasattr(self, 'mincut_task') and self.mincut_task is not None:
            try:
                if self.mincut_task.isActive():
                    message = "Mincut task is already active!"
                    tools_qgis.show_warning(message)
                    return
            except RuntimeError:
                pass

        if btn == Qt.MouseButton.RightButton:
            self.action_mincut.setChecked(False)
            self.reset_mincut_canvas_snapping(action_pan=False)
            return

        # Get coordinates
        event_point = self.snapper_manager.get_event_point(point=point)

        # Set active and current layer
        self.layer_arc = tools_qgis.get_layer_by_tablename("ve_arc")
        self.iface.setActiveLayer(self.layer_arc)
        self.current_layer = self.layer_arc

        # Snapping
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if not result.isValid():
            return

        # Check feature
        elem_type = None
        layer = self.snapper_manager.get_snapped_layer(result)
        if layer == self.layer_arc:
            elem_type = 'arc'

        if elem_type:
            # Get the point. Leave selection
            snapped_feat = self.snapper_manager.get_snapped_feature(result)
            feature_id = self.snapper_manager.get_snapped_feature_id(result)
            snapped_point = self.snapper_manager.get_snapped_point(result)
            element_id = snapped_feat.attribute(f'{elem_type}_id')
            layer.select([feature_id])

            # Network mincut mode: ensure that Mincut layers are loaded
            tools_gw.load_missing_layers('v_om_mincut%', "OM", "Mincut")
            self._start_network_mincut_task(snapped_point, elem_type, element_id)

    def _offline_mincut_snapping(self, point, btn):
        """Offline mincut snapping on arc layer without opening the mincut dialog."""

        if btn == Qt.MouseButton.RightButton:
            self.reset_mincut_canvas_snapping(action_pan=False)
            self._remove_selection()
            self._restore_active_layer_after_offline_mincut()
            self.iface.actionPan().trigger()
            return

        event_point = self.snapper_manager.get_event_point(point=point)

        self.layer_arc = tools_qgis.get_layer_by_tablename("ve_arc")
        self.iface.setActiveLayer(self.layer_arc)
        self.current_layer = self.layer_arc

        result = self.snapper_manager.snap_to_current_layer(event_point)
        if not result.isValid():
            return

        layer = self.snapper_manager.get_snapped_layer(result)
        if layer != self.layer_arc:
            return

        snapped_feat = self.snapper_manager.get_snapped_feature(result)
        feature_id = self.snapper_manager.get_snapped_feature_id(result)
        element_id = snapped_feat.attribute('arc_id')
        layer.select([feature_id])

        self._offline_mincut_execute(element_id)

        self.reset_mincut_canvas_snapping(action_pan=False)
        self._remove_selection()
        self._restore_active_layer_after_offline_mincut()
        self.iface.actionPan().trigger()

    def _start_network_mincut_task(self, snapped_point, elem_type, element_id):
        """Start the regular asynchronous mincut task."""

        self.dlg_mincut.btn_cancel_task.show()
        self.dlg_mincut.btn_cancel.hide()

        self.t0 = time()
        if self.timer:
            self.timer.stop()
            del self.timer
        self.timer = QTimer()
        self.timer.timeout.connect(partial(self._calculate_elapsed_time, self.dlg_mincut))
        self.timer.start(1000)

        self.mincut_task = GwAutoMincutTask("Mincut execute", self, element_id, timer=self.timer)
        QgsApplication.taskManager().addTask(self.mincut_task)
        QgsApplication.taskManager().triggerTask(self.mincut_task)
        self.mincut_task.task_finished.connect(partial(self._mincut_task_finished, snapped_point, elem_type, element_id))

    def _offline_mincut_execute(self, arc_id):
        """Offline mincut: arc snap -> gw_fct_getmincutminsector(arcId)."""

        extras = f'"parameters":{{"arcId":"{arc_id}"}}'
        body = tools_gw.create_body(extras=extras)
        result = tools_gw.execute_procedure('gw_fct_getmincutminsector', body)

        if not result or result.get('status') == 'Failed':
            msg = "Offline mincut failed (gw_fct_getmincutminsector)"
            tools_qgis.show_warning(msg)
            return None

        # Optional UX: show returned message text (if any).
        message = result.get('message')
        if isinstance(message, dict) and message.get('text'):
            tools_qgis.show_message(message.get('text'), Qgis.MessageLevel(message.get('level', 1)))

        return result

    def _enable_post_mincut_actions(self):
        """Enable action set after mincut execution."""

        self.dlg_mincut.btn_start.setDisabled(False)
        self.action_mincut.setDisabled(False)
        self.action_refresh_mincut.setDisabled(False)
        self.action_custom_mincut.setDisabled(False)
        self.action_change_valve_status.setDisabled(False)
        self.action_add_connec.setDisabled(True)
        self.action_add_hydrometer.setDisabled(True)
        self.action_mincut_composer.setDisabled(False)

    def _cancel_task(self):
        """ Cancel GwAutoMincutTask """

        self.action_mincut.setChecked(False)
        self.reset_mincut_canvas_snapping(action_pan=False)
        self.mincut_task.cancel()

    # noinspection PyUnusedLocal
    def _snapping_node_arc_real_location(self, point, btn):

        # Get coordinates
        event_point = self.snapper_manager.get_event_point(point=point)

        result_mincut_id_text = self.dlg_mincut.result_mincut_id.text()
        srid = lib_vars.data_epsg

        sql = (f"UPDATE om_mincut"
               f" SET exec_the_geom = ST_SetSRID(ST_Point({point.x()}, {point.y()}), {srid})"
               f" WHERE id = '{result_mincut_id_text}'")
        status = tools_db.execute_sql(sql)
        if status:
            message = "Real location has been updated"
            tools_qgis.show_info(message)

        # Snapping
        result = self.snapper_manager.snap_to_project_config_layers(event_point)

        self.reset_mincut_canvas_snapping(action_pan=False)
        self.iface.actionPan().trigger()

        if not result.isValid():
            return

        layer = self.snapper_manager.get_snapped_layer(result)

        # Check feature
        layers_arc = tools_gw.get_layers_from_feature_type('arc')
        self.layernames_arc = []
        for layer in layers_arc:
            self.layernames_arc.append(layer.name())

        element_type = layer.name()
        if element_type in self.layernames_arc:
            self.snapper_manager.get_snapped_feature(result, True)

    def _mincut_task_finished(self, snapped_point, elem_type, element_id, signal):

        try:
            self.dlg_mincut.btn_cancel_task.hide()
            self.dlg_mincut.btn_cancel.show()
        except Exception:
            pass

        if not signal[0]:
            try:
                # If user open other docker form before mincut end, the second form force close mincut form
                self.action_mincut.setChecked(False)
            except Exception:
                pass
            return False

        if signal[1]:
            complet_result = signal[1]
            real_mincut_id = tools_qt.get_text(self.dlg_mincut, self.dlg_mincut.result_mincut_id)
            mincutOverlap = complet_result.get('mincutOverlap')
            if mincutOverlap not in (None, ""):
                msg = "Mincut done, but has conflict and overlaps with"
                tools_qt.show_info_box(msg, parameter=mincutOverlap)
            else:
                msg = complet_result.get('message')
                if not msg:
                    msg = "Mincut done successfully"
                    tools_qgis.show_message(msg, Qgis.MessageLevel.Success)
                else:
                    tools_qgis.show_message(msg.get('text'), Qgis.MessageLevel(msg.get('level')))

            # Zoom to rectangle (zoom to mincut)
            try:
                bbox = complet_result['body']['data']['geometry']['bbox']
            except KeyError:
                bbox = None

            if bbox:
                x1, y1, x2, y2 = bbox.get('x1'), bbox.get('y1'), bbox.get('x2'), bbox.get('y2')
                if None in (x1, y1, x2, y2):
                    message = "Error on create auto mincut, you need to review data"
                    tools_qgis.show_warning(message)
                    tools_qgis.restore_cursor()
                    self.action_mincut.setChecked(False)
                    return

                tools_qgis.zoom_to_rectangle(x1, y1, x2, y2, margin=0)

            sql = (f"UPDATE om_mincut"
                   f" SET mincut_class = 1, "
                   f" anl_the_geom = ST_SetSRID(ST_Point({snapped_point.x()}, "
                   f"{snapped_point.y()}), {lib_vars.data_epsg}),"
                   f" anl_user = current_user, anl_feature_type = '{elem_type.upper()}',"
                   f" anl_feature_id = {element_id}"
                   f" WHERE id = '{real_mincut_id}'")
            status = tools_db.execute_sql(sql)
            if not status:
                message = "Error updating element in table, you need to review data"
                tools_qgis.show_warning(message)
                tools_qgis.restore_cursor()
                self.action_mincut.setChecked(False)
                return

            self._sync_address_widgets_from_mincut(real_mincut_id)

            # Enable button CustomMincut, ChangeValveStatus and button Start
            self._enable_post_mincut_actions()

            # Update table 'selector_mincut_result'
            self._update_result_selector(real_mincut_id)

            # Refresh map canvas
            tools_qgis.refresh_map_canvas()

        # Disconnect snapping and related signals
        self.reset_mincut_canvas_snapping(action_pan=False)
        self.set_visible_mincut_layers()
        self._remove_selection()
        self.action_mincut.setChecked(False)
        self.iface.actionPan().trigger()

        # Enabled button accept from mincut form
        self.dlg_mincut.btn_accept.setEnabled(True)

    def _refresh_mincut(self, triggered=None, action="mincutRefresh", zoom=True):
        """ B2-125: Refresh current mincut """

        # Manage if task is already running
        if hasattr(self, 'mincut_task') and self.mincut_task is not None:
            try:
                if self.mincut_task.isActive():
                    message = "Mincut task is already active!"
                    tools_qgis.show_warning(message)
                    return
            except RuntimeError:
                pass

        # Uncheck actions
        self.action_mincut.setChecked(False)
        self.action_custom_mincut.setChecked(False)
        self.action_change_valve_status.setChecked(False)

        # Get elemet_id from current mincut
        result_mincut_id = self.dlg_mincut.result_mincut_id.text()
        sql = f"SELECT anl_feature_id FROM om_mincut WHERE id = {result_mincut_id}"
        row = tools_db.get_row(sql)
        if row:
            # Create task to manage Mincut execution
            element_id = row['anl_feature_id']
            self.dlg_mincut.btn_cancel_task.show()
            self.dlg_mincut.btn_cancel.hide()

            # Create timer
            self.t0 = time()
            if self.timer:
                self.timer.stop()
                del self.timer
            self.timer = QTimer()
            self.timer.timeout.connect(partial(self._calculate_elapsed_time, self.dlg_mincut))
            self.timer.start(1000)

            message = "Mincut execute"
            self.mincut_task = GwAutoMincutTask(message, self, element_id, action=action, timer=self.timer)
            QgsApplication.taskManager().addTask(self.mincut_task)
            QgsApplication.taskManager().triggerTask(self.mincut_task)
            self.mincut_task.task_finished.connect(partial(self._refresh_mincut_finished, zoom))

    def _refresh_mincut_finished(self, zoom, signal):

        try:
            self.dlg_mincut.btn_cancel_task.hide()
            self.dlg_mincut.btn_cancel.show()
        except Exception:
            pass

        if not signal[0]:
            return False

        if signal[1]:
            complet_result = signal[1]
            try:
                has_overlap = complet_result['body']['data']['hasOverlap']
            except KeyError:
                has_overlap = False

            if has_overlap:
                msg = "Mincut done, but has conflict and overlaps with other mincuts"
                tools_qt.show_info_box(msg)
            else:
                msg = complet_result.get('message')
                if not msg:
                    msg = "Mincut done successfully"
                    tools_qgis.show_message(msg, Qgis.MessageLevel.Success)
                else:
                    tools_qgis.show_message(msg.get('text'), Qgis.MessageLevel(msg.get('level')))

            # Zoom to rectangle (zoom to mincut)
            try:
                bbox = complet_result['body']['data']['geometry']['bbox']
            except KeyError:
                bbox = None

            if bbox and zoom:
                x1, y1, x2, y2 = bbox.get('x1'), bbox.get('y1'), bbox.get('x2'), bbox.get('y2')
                if None in (x1, y1, x2, y2):
                    message = "Error on create auto mincut, you need to review data"
                    tools_qgis.show_warning(message)
                    tools_qgis.restore_cursor()
                    return

                tools_qgis.zoom_to_rectangle(x1, y1, x2, y2, margin=0)

            # Refresh map canvas
            tools_qgis.refresh_map_canvas()

        # Disconnect snapping and related signals
        self.reset_mincut_canvas_snapping(action_pan=False)
        self.set_visible_mincut_layers()
        self._remove_selection()

    def _custom_mincut(self, action, is_checked):
        """ B2-123: Custom mincut analysis. Working just with valve layer """

        # Declare snapper_manager and emit_point
        self.emit_point = QgsMapToolEmitPoint(self.canvas)
        self.canvas.setMapTool(self.emit_point)
        self.snapper_manager = GwSnapManager(self.iface)
        self.snapper = self.snapper_manager.get_snapper()

        if is_checked is False:
            self.reset_mincut_canvas_snapping(action_pan=False)
            # Recover snapping options, refresh canvas & set visible layers
            return

        # Disconnect other snapping and signals in case wrong user clicks
        self.reset_mincut_canvas_snapping(action_pan=False)

        # Set vertex marker propierties
        self.vertex_marker = self.snapper_manager.vertex_marker

        # Set active and current layer
        self.layer = tools_qgis.get_layer_by_tablename("v_om_mincut_valve")
        self.iface.setActiveLayer(self.layer)
        self.current_layer = self.layer

        # Waiting for signals
        tools_gw.connect_signal(self.canvas.xyCoordinates, self._mouse_move_valve, 'mincut',
                                'custom_mincut_xyCoordinates_mouse_move_valve')
        tools_gw.connect_signal(self.emit_point.canvasClicked, partial(self._custom_mincut_snapping, action),
                                'mincut', 'custom_mincut_ep_canvasClicked_custom_mincut_snapping')

    def _mouse_move_valve(self, point):
        """ Waiting for valves when mouse is moved"""

        # Get clicked point and add marker
        event_point = self.snapper_manager.get_event_point(point=point)
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if result.isValid():
            self.snapper_manager.add_marker(result, self.vertex_marker)

    # noinspection PyUnusedLocal
    def _custom_mincut_snapping(self, action, point, btn):
        """ Custom mincut snapping function """

        if btn == Qt.MouseButton.RightButton:
            self.action_custom_mincut.setChecked(False)
            self.action_change_valve_status.setChecked(False)
            self.reset_mincut_canvas_snapping(action_pan=True)
            global_vars.iface.actionPan().trigger()
            return

        # Get clicked point
        event_point = self.snapper_manager.get_event_point(point=point)
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if result.isValid():
            # Get the point. Leave selection
            snapped_feat = self.snapper_manager.get_snapped_feature(result, True)
            element_id = snapped_feat.attribute('node_id')
            if action.objectName() == "actionCustomMincut":
                self._custom_mincut_execute(element_id)
            elif action.objectName() == "actionChangeValveStatus":
                self._change_valve_status_execute(element_id)
            tools_qgis.refresh_map_canvas(True)
            self.set_visible_mincut_layers()
            self._remove_selection()
            if action.objectName() == "actionCustomMincut":
                action.setChecked(False)

    def _custom_mincut_execute(self, elem_id):
        """ Custom mincut. Execute function 'gw_fct_setmincut' with action 'mincutValveUnaccess' """

        # Change cursor to 'WaitCursor'
        tools_qgis.set_cursor_wait()

        use_planified = tools_qt.is_checked(self.dlg_mincut, 'chk_use_planified')
        result_mincut_id = tools_qt.get_text(self.dlg_mincut, "result_mincut_id")

        mincut_result_type = tools_qt.get_combo_value(self.dlg_mincut, self.dlg_mincut.type, 0)
        forecast_start_predict = self.dlg_mincut.cbx_date_start_predict.date().toString('yyyy-MM-dd') + " " + self.dlg_mincut.cbx_hours_start_predict.time().toString('HH:mm:ss')
        forecast_end_predict = self.dlg_mincut.cbx_date_end_predict.date().toString('yyyy-MM-dd') + " " + self.dlg_mincut.cbx_hours_end_predict.time().toString('HH:mm:ss')

        if result_mincut_id != 'null':
            extras = (f'"action":"mincutValveUnaccess", "nodeId":{elem_id}, "mincutId":"{result_mincut_id}", "usePsectors":"{use_planified}", '
                      f'"mincutType":"{mincut_result_type}", "forecastStart":"{forecast_start_predict}", '
                      f'"forecastEnd":"{forecast_end_predict}"')
            body = tools_gw.create_body(extras=extras)
            result = self._execute_setmincut_with_cursor(body)

            if result is not None and result['status'] == 'Accepted' and result['message']:
                level = int(result['message']['level']) if 'level' in result['message'] else 1
                msg = result['message']['text']
                level = Qgis.MessageLevel(level)
                tools_qgis.show_message(msg, level)

        # Disconnect snapping and related signals
        self.reset_mincut_canvas_snapping(action_pan=False)

    def _remove_selection(self):
        """ Remove selected features of all layers """

        for layer in self.canvas.layers():
            if type(layer) is QgsVectorLayer:
                layer.removeSelection()
        self.canvas.refresh()

        for a in self.iface.attributesToolBar().actions():
            if a.objectName() == 'mActionDeselectAll':
                a.trigger()
                break

    def _open_mincut_manage_dates(self, row):
        """ Management of null values in fields of type date """

        self._manage_date(row['anl_tstamp'], "cbx_recieved_day", "cbx_recieved_time")
        self._manage_date(row['forecast_start'], "cbx_date_start_predict", "cbx_hours_start_predict")
        self._manage_date(row['forecast_end'], "cbx_date_end_predict", "cbx_hours_end_predict")
        self._manage_date(row['exec_start'], "cbx_date_start", "cbx_hours_start")
        self._manage_date(row['exec_end'], "cbx_date_end", "cbx_hours_end")

    def _manage_date(self, date_value, widget_date, widget_time):
        """ Manage date of current field """

        if date_value in ('', None):
            date_value = QDateTime.currentDateTime().toString('yyyy-MM-dd HH:mm:ss')

        date_time = (str(date_value))
        date = str(date_time.split()[0])
        time = str(date_time.split()[1])
        if date:
            date = date.replace('/', '-')
        qt_date = QDate.fromString(date, 'yyyy-MM-dd')
        qt_time = QTime.fromString(time, 'h:mm:ss')
        tools_qt.set_calendar(self.dlg_mincut, widget_date, qt_date)
        tools_qt.set_time(self.dlg_mincut, widget_time, qt_time)

    def _mincut_composer(self):
        """ Open Composer """

        # Check if path exist
        template_folder = ""
        row = tools_gw.get_config_value('qgis_composers_folderpath')
        if row:
            template_folder = row[0]

        try:
            template_files = os.listdir(template_folder)
        except FileNotFoundError:
            msg = "Your composer's path is bad configured. Please, modify it and try again."
            tools_qgis.show_message(msg, Qgis.MessageLevel.Warning)
            return

        # Set dialog add_connec
        self.dlg_comp = GwMincutComposerUi(self)
        tools_gw.load_settings(self.dlg_comp)

        # Fill ComboBox cbx_template with templates *.qpt
        self.files_qpt = [i for i in template_files if i.endswith('.qpt')]
        self.dlg_comp.cbx_template.clear()
        self.dlg_comp.cbx_template.addItem('')
        for template in self.files_qpt:
            self.dlg_comp.cbx_template.addItem(str(template))

        # Set signals
        self.dlg_comp.btn_ok.clicked.connect(self._open_composer)
        self.dlg_comp.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_comp))
        self.dlg_comp.rejected.connect(partial(tools_gw.close_dialog, self.dlg_comp))
        self.dlg_comp.cbx_template.currentIndexChanged.connect(self._set_template)

        # Open dialog
        tools_gw.open_dialog(self.dlg_comp, dlg_name='mincut_composer')

    def _set_template(self):

        template = self.dlg_comp.cbx_template.currentText()
        self.template = template[:-4]

    def _open_composer(self):

        # Check if template is selected
        if str(self.dlg_comp.cbx_template.currentText()) == "":
            message = "You need to select a template"
            tools_qgis.show_warning(message, dialog=self.dlg_comp)
            return

        # Check if template file exists
        template_path = ""
        row = tools_gw.get_config_value('qgis_composers_folderpath')
        if row:
            template_path = row[0] + f'{os.sep}{self.template}.qpt'

        if not os.path.exists(template_path):
            message = "File not found"
            tools_qgis.show_warning(message, parameter=template_path, dialog=self.dlg_comp)
            return

        # Check if composer exist
        composers = tools_qgis.get_composers_list()
        index = tools_qgis.get_composer_index(str(self.template))

        # Composer not found
        if index == len(composers):

            # Create new composer with template selected in combobox(self.template)
            template_file = open(template_path, 'rt')
            template_content = template_file.read()
            template_file.close()
            document = QDomDocument()
            document.setContent(template_content)
            project = QgsProject.instance()
            comp_view = QgsPrintLayout(project)
            comp_view.loadFromTemplate(document, QgsReadWriteContext())
            # Set name AFTER loading template (template may have its own name)
            comp_view.setName(str(self.template))
            layout_manager = project.layoutManager()
            layout_manager.addLayout(comp_view)

            # Get layout from manager to ensure correct ownership
            comp_view = layout_manager.layoutByName(str(self.template))
            if comp_view is None:
                # Fallback: try to get the last added layout
                layouts = layout_manager.layouts()
                if layouts:
                    comp_view = layouts[-1]
                    # Update name if it's different
                    if comp_view.name() != str(self.template):
                        comp_view.setName(str(self.template))
                else:
                    msg = "Failed to create layout from template"
                    tools_qgis.show_warning(msg, dialog=self.dlg_comp)
                    return

        else:
            comp_view = composers[index]

        # Manage mincut layout
        self._manage_mincut_layout(comp_view)

    def _manage_mincut_layout(self, layout):
        """ Manage mincut layout """

        if layout is None:
            msg = "Layout not found"
            tools_log.log_warning(msg)
            return

        title = self.dlg_comp.title.text()
        try:
            rotation = float(self.dlg_comp.rotation.text())
        except ValueError:
            rotation = 0

        # Show layout
        self.iface.openLayoutDesigner(layout)

        # Zoom map to extent, rotation, title
        missing_items = []
        map_item = layout.itemById('Mapa')
        if map_item is not None:
            map_item.zoomToExtent(self.canvas.extent())
            map_item.setMapRotation(rotation)
        else:
            missing_items.append("Mapa")
            msg = "Map item 'Mapa' not found in template. Template may be empty or use different item IDs."
            tools_log.log_warning(msg)

        profile_title = layout.itemById('title')
        if profile_title is not None:
            profile_title.setText(str(title))
        else:
            missing_items.append("title")
            msg = "Title item 'title' not found in template. Template may be empty or use different item IDs."
            tools_log.log_warning(msg)

        # Show user-friendly message if items are missing
        if missing_items:
            items_list = ", ".join(missing_items)
            msg = ("The template '{0}' is missing some expected items: {1}. "
                   "The layout will open, but these features won't be automatically configured. "
                   "Make sure your template includes items with IDs: 'Mapa' (for the map) and 'title' (for the title).")
            msg_params = (self.template, items_list)
            tools_qgis.show_info(msg, msg_params=msg_params)

        # Refresh items
        layout.refresh()
        layout.updateBounds()

    def _enable_widgets(self, state):
        """ Enable/Disable widget depending @state """

        # Planified
        if state == '0':

            self.dlg_mincut.work_order.setDisabled(False)
            # Group Address
            self.dlg_mincut.cmb_municipality.setDisabled(False)
            self.dlg_mincut.txt_street.setDisabled(False)
            self.dlg_mincut.txt_postnumber.setDisabled(False)
            # Group Details
            self.dlg_mincut.type.setDisabled(False)
            self.dlg_mincut.cause.setDisabled(False)
            self.dlg_mincut.cbx_recieved_day.setDisabled(False)
            self.dlg_mincut.cbx_recieved_time.setDisabled(False)
            # Group Prediction
            self.dlg_mincut.cbx_date_start_predict.setDisabled(False)
            self.dlg_mincut.cbx_hours_start_predict.setDisabled(False)
            self.dlg_mincut.cbx_date_end_predict.setDisabled(False)
            self.dlg_mincut.cbx_hours_end_predict.setDisabled(False)
            self.dlg_mincut.assigned_to.setDisabled(False)
            self.dlg_mincut.pred_description.setDisabled(False)
            # Group Real Details
            self.dlg_mincut.cbx_date_start.setDisabled(True)
            self.dlg_mincut.cbx_hours_start.setDisabled(True)
            self.dlg_mincut.cbx_date_end.setDisabled(True)
            self.dlg_mincut.cbx_hours_end.setDisabled(True)
            self.dlg_mincut.distance.setDisabled(True)
            self.dlg_mincut.depth.setDisabled(True)
            self.dlg_mincut.appropiate.setDisabled(True)
            self.dlg_mincut.real_description.setDisabled(True)
            self.dlg_mincut.btn_start.setDisabled(True)
            self.dlg_mincut.btn_end.setDisabled(True)
            self.dlg_mincut.txt_chlorine.setDisabled(True)
            self.dlg_mincut.txt_turbidity.setDisabled(True)
            self.dlg_mincut.txt_equipment_code.setDisabled(True)
            self.dlg_mincut.txt_reagent_lot.setDisabled(True)
            # Actions
            self.action_mincut.setDisabled(False)
            self.action_refresh_mincut.setDisabled(True)
            self.action_custom_mincut.setDisabled(True)
            self.action_change_valve_status.setDisabled(True)
            self.action_add_connec.setDisabled(True)
            self.action_add_hydrometer.setDisabled(True)

        # In Progess
        elif state == '1':

            self.dlg_mincut.work_order.setDisabled(True)
            # Group Address
            self.dlg_mincut.cmb_municipality.setDisabled(True)
            self.dlg_mincut.txt_street.setDisabled(True)
            self.dlg_mincut.txt_postnumber.setDisabled(True)
            # Group Details
            self.dlg_mincut.type.setDisabled(True)
            self.dlg_mincut.cause.setDisabled(True)
            self.dlg_mincut.cbx_recieved_day.setDisabled(True)
            self.dlg_mincut.cbx_recieved_time.setDisabled(True)
            # Group Prediction dates
            self.dlg_mincut.cbx_date_start_predict.setDisabled(True)
            self.dlg_mincut.cbx_hours_start_predict.setDisabled(True)
            self.dlg_mincut.cbx_date_end_predict.setDisabled(True)
            self.dlg_mincut.cbx_hours_end_predict.setDisabled(True)
            self.dlg_mincut.assigned_to.setDisabled(True)
            self.dlg_mincut.pred_description.setDisabled(True)
            # Group Real dates
            self.dlg_mincut.cbx_date_start.setDisabled(False)
            self.dlg_mincut.cbx_hours_start.setDisabled(False)
            self.dlg_mincut.cbx_date_end.setDisabled(False)
            self.dlg_mincut.cbx_hours_end.setDisabled(False)
            self.dlg_mincut.distance.setDisabled(False)
            self.dlg_mincut.depth.setDisabled(False)
            self.dlg_mincut.appropiate.setDisabled(False)
            self.dlg_mincut.real_description.setDisabled(False)
            self.dlg_mincut.btn_start.setDisabled(True)
            self.dlg_mincut.btn_end.setDisabled(False)
            self.dlg_mincut.txt_chlorine.setDisabled(False)
            self.dlg_mincut.txt_turbidity.setDisabled(False)
            self.dlg_mincut.txt_equipment_code.setDisabled(False)
            self.dlg_mincut.txt_reagent_lot.setDisabled(False)
            # Actions
            self.action_mincut.setDisabled(True)
            self.action_refresh_mincut.setDisabled(True)
            self.action_custom_mincut.setDisabled(True)
            self.action_change_valve_status.setDisabled(True)
            self.action_add_connec.setDisabled(True)
            self.action_add_hydrometer.setDisabled(True)

        # Finished
        elif state == '2':

            self.dlg_mincut.work_order.setDisabled(True)
            # Group Address
            self.dlg_mincut.cmb_municipality.setDisabled(True)
            self.dlg_mincut.txt_street.setDisabled(True)
            self.dlg_mincut.txt_postnumber.setDisabled(True)
            # Group Details
            self.dlg_mincut.type.setDisabled(True)
            self.dlg_mincut.cause.setDisabled(True)
            self.dlg_mincut.cbx_recieved_day.setDisabled(True)
            self.dlg_mincut.cbx_recieved_time.setDisabled(True)
            # Group Prediction dates
            self.dlg_mincut.cbx_date_start_predict.setDisabled(True)
            self.dlg_mincut.cbx_hours_start_predict.setDisabled(True)
            self.dlg_mincut.cbx_date_end_predict.setDisabled(True)
            self.dlg_mincut.cbx_hours_end_predict.setDisabled(True)
            self.dlg_mincut.assigned_to.setDisabled(True)
            self.dlg_mincut.pred_description.setDisabled(True)
            # Group Real dates
            self.dlg_mincut.cbx_date_start.setDisabled(True)
            self.dlg_mincut.cbx_hours_start.setDisabled(True)
            self.dlg_mincut.cbx_date_end.setDisabled(True)
            self.dlg_mincut.cbx_hours_end.setDisabled(True)
            self.dlg_mincut.distance.setDisabled(True)
            self.dlg_mincut.depth.setDisabled(True)
            self.dlg_mincut.appropiate.setDisabled(True)
            self.dlg_mincut.real_description.setDisabled(True)
            self.dlg_mincut.btn_start.setDisabled(True)
            self.dlg_mincut.btn_end.setDisabled(True)
            self.dlg_mincut.txt_chlorine.setDisabled(True)
            self.dlg_mincut.txt_turbidity.setDisabled(True)
            self.dlg_mincut.txt_equipment_code.setDisabled(True)
            self.dlg_mincut.txt_reagent_lot.setDisabled(True)
            # Actions
            self.action_mincut.setDisabled(True)
            self.action_refresh_mincut.setDisabled(True)
            self.action_custom_mincut.setDisabled(True)
            self.action_change_valve_status.setDisabled(True)
            self.action_add_connec.setDisabled(True)
            self.action_add_hydrometer.setDisabled(True)

    def _change_valve_status(self, action, is_checked):
        """ Change status of selected valve. Execute function gw_fct_setchangevalvestatus """

        if is_checked is False:
            self.reset_mincut_canvas_snapping(action_pan=False)
            # Recover snapping options, refresh canvas & set visible layers
            return

        self.reset_mincut_canvas_snapping(action_pan=False)

        # Declare snapper_manager and emit_point
        self.emit_point = QgsMapToolEmitPoint(self.canvas)
        self.canvas.setMapTool(self.emit_point)
        self.snapper_manager = GwSnapManager(self.iface)
        self.snapper = self.snapper_manager.get_snapper()

        # Set vertex marker properties
        self.vertex_marker = self.snapper_manager.vertex_marker

        # Set active and current layer
        self.layer = tools_qgis.get_layer_by_tablename("v_om_mincut_valve")
        self.iface.setActiveLayer(self.layer)
        self.current_layer = self.layer

        # Waiting for signals
        tools_gw.connect_signal(self.canvas.xyCoordinates, self._mouse_move_valve, 'mincut',
                                'change_valve_status_xyCoordinates_mouse_move_valve')
        tools_gw.connect_signal(self.emit_point.canvasClicked, partial(self._custom_mincut_snapping, action),
                                'mincut', 'change_valve_status_ep_canvasClicked_custom_mincut_snapping')

    def _change_valve_status_execute(self, elem_id):
        """ Execute function 'setmincut' """

        use_planified = tools_qt.is_checked(self.dlg_mincut, 'chk_use_planified')
        result_mincut_id = tools_qt.get_text(self.dlg_mincut, "result_mincut_id")

        mincut_result_type = tools_qt.get_combo_value(self.dlg_mincut, self.dlg_mincut.type, 0)
        forecast_start_predict = self.dlg_mincut.cbx_date_start_predict.date().toString('yyyy-MM-dd') + " " + self.dlg_mincut.cbx_hours_start_predict.time().toString('HH:mm:ss')
        forecast_end_predict = self.dlg_mincut.cbx_date_end_predict.date().toString('yyyy-MM-dd') + " " + self.dlg_mincut.cbx_hours_end_predict.time().toString('HH:mm:ss')

        if result_mincut_id != 'null':
            extras = (f'"action":"mincutChangeValveStatus", "nodeId":{elem_id}, "mincutId":"{result_mincut_id}", "usePsectors":"{use_planified}", '
                      f'"mincutType":"{mincut_result_type}", "forecastStart":"{forecast_start_predict}", '
                      f'"forecastEnd":"{forecast_end_predict}"')
            body = tools_gw.create_body(extras=extras)
            result = self._execute_setmincut_with_cursor(body)

            if result is not None and result['status'] == 'Accepted' and result['message']:
                level = int(result['message']['level']) if 'level' in result['message'] else 1
                msg = result['message']['text']
                level = Qgis.MessageLevel(level)
                tools_qgis.show_message(msg, level)

    def _calculate_elapsed_time(self, dialog):

        tf = time()  # Final time
        td = tf - self.t0  # Delta time
        message = "Exec. time: {0}"
        msg_params = (timedelta(seconds=round(td)),)
        self._update_time_elapsed(tools_qt.tr(message, list_params=msg_params), dialog)

    def _update_time_elapsed(self, text, dialog):

        if isdeleted(dialog):
            self.timer.stop()
            return

        lbl_time = dialog.findChild(QLabel, 'lbl_time')
        lbl_time.setText(text)

    def _store_original_values(self):
        """Store original values of widgets"""
        self.original_values = {
            'type': tools_qt.get_combo_value(self.dlg_mincut, self.dlg_mincut.type, 0),
            'date_start_predict': self.dlg_mincut.cbx_date_start_predict.date(),
            'time_start_predict': self.dlg_mincut.cbx_hours_start_predict.time(),
            'date_end_predict': self.dlg_mincut.cbx_date_end_predict.date(),
            'time_end_predict': self.dlg_mincut.cbx_hours_end_predict.time(),
        }
        self.form_has_changes = False

    def _connect_change_signals(self):
        """Connect signals to detect changes"""
        self.dlg_mincut.type.currentIndexChanged.connect(self._on_form_changed)
        self.dlg_mincut.cbx_date_start_predict.dateChanged.connect(self._on_form_changed)
        self.dlg_mincut.cbx_hours_start_predict.timeChanged.connect(self._on_form_changed)
        self.dlg_mincut.cbx_date_end_predict.dateChanged.connect(self._on_form_changed)
        self.dlg_mincut.cbx_hours_end_predict.timeChanged.connect(self._on_form_changed)

    def _on_form_changed(self):
        """Mark that the form has changed and block accept"""
        self.form_has_changes = True
        self.dlg_mincut.btn_accept.setEnabled(False)
        msg = "You need to reexecute the mincut"
        self.dlg_mincut.btn_accept.setToolTip(tools_qt.tr(msg))

    def _reset_form_has_changes(self):
        """Reset form has changes"""
        self.form_has_changes = False
        self.dlg_mincut.btn_accept.setEnabled(True)
        self.dlg_mincut.btn_accept.setStyleSheet("")
        msg = "Accept"
        self.dlg_mincut.btn_accept.setToolTip(tools_qt.tr(msg))

    # endregion
