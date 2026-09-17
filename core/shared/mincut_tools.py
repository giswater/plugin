"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import datetime
import json
from functools import partial

from qgis.PyQt.QtCore import Qt, QRegularExpression
from qgis.PyQt.QtWidgets import QComboBox, QGridLayout, QLabel, QLineEdit, QSizePolicy, \
    QSpinBox, QSpacerItem, QTableView
from qgis.gui import QgsDateTimeEdit
from qgis.core import Qgis

from ..utils import tools_backend_calls

from ..shared.selector import GwSelector
from ..ui.ui_manager import GwSelectorUi, GwMincutUi
from ..utils import tools_gw
from ... import global_vars
from ...libs import lib_vars, tools_qgis, tools_qt, tools_db, tools_os


class GwMincutTools:

    def __init__(self, mincut):

        self.mincut = mincut
        self.canvas = global_vars.canvas
        self.plugin_dir = lib_vars.plugin_dir
        self.schema_name = lib_vars.schema_name
        self.settings = global_vars.giswater_settings

        self.rubber_band = tools_gw.create_rubberband(self.canvas, "point")

    def set_dialog(self, dialog):
        self.dlg_mincut_man = dialog
        function_name = 'gw_fct_getmincut_manager'
        body = tools_gw.create_body()
        json_result = tools_gw.execute_procedure(function_name, body, rubber_band=self.rubber_band)

        if json_result in (None, False):
            return False, None

        # Manage status failed
        if json_result['status'] == 'Failed' or ('results' in json_result and json_result['results'] <= 0):
            level = 1
            if 'level' in json_result['message']:
                level = int(json_result['message']['level'])
            msg = "Execution of {0} failed."
            msg_params = (function_name,)
            if 'text' in json_result['message']:
                msg = json_result['message']['text']
                msg_params = None
            level = Qgis.MessageLevel(level)
            tools_qgis.show_message(msg, level, msg_params=msg_params)
            return False, None

        self.complet_result = json_result
        tools_gw.load_settings(self.dlg_mincut_man)

        self._manage_dlg_widgets(self.complet_result)
        self.load_tableviews(self.complet_result)

        self.tbl_mincut_edit = self.dlg_mincut_man.findChild(QTableView, "tab_none_tbl_mincut_edit")
        tools_gw.open_dialog(self.dlg_mincut_man, dlg_name='mincut_manager')

        # Populate custom context menu
        self.tbl_mincut_edit.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.tbl_mincut_edit.customContextMenuRequested.connect(partial(tools_gw._show_context_menu, self.tbl_mincut_edit, self.dlg_mincut_man))

    def load_tableviews(self, complet_result, filter_fields=''):
        list_tables = self.dlg_mincut_man.findChildren(QTableView)
        complet_list = []
        for table in list_tables:
            widgetname = table.objectName()
            columnname = table.property('columnname')
            if columnname is None:
                msg = "widget {0} in tab {1} has not columnname and cant be configured"
                msg_params = (widgetname, self.dlg_mincut_man.objectName())
                tools_qgis.show_info(msg, 3, msg_params=msg_params)
                continue
            linkedobject = table.property('linkedobject')
            complet_list, widget_list = tools_gw.fill_tbl(complet_result, self.dlg_mincut_man, columnname, linkedobject,
                                                      filter_fields)
            if complet_list is False:
                return False
            tools_gw.set_filter_listeners(complet_result, self.dlg_mincut_man, widget_list, columnname, widgetname)

    # region private functions

    def _manage_dlg_widgets(self, complet_result):
        """ Creates and populates all the widgets """

        layout_list = []
        widget_offset = 0
        prev_layout = ""
        for field in complet_result['body']['data']['fields']:
            if 'hidden' in field and field['hidden']:
                continue
            self.tablename = 'mincut_manager'
            label, widget = tools_gw.set_widgets(self.dlg_mincut_man, complet_result, field, self.tablename, self)
            if widget is None:
                continue

            layout = self.dlg_mincut_man.findChild(QGridLayout, field['layoutname'])
            if layout is not None:
                if layout.objectName() != prev_layout:
                    widget_offset = 0
                    prev_layout = layout.objectName()

                if field['layoutorder'] is None:
                    msg = "The field layoutorder is not configured for"
                    param = f"formname:{self.tablename}, columnname:{field['columnname']}"
                    tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=param, dialog=self.dlg_mincut_man)
                    continue

                # Manage widget and label positions
                label_pos = field['widgetcontrols']['labelPosition'] if (
                            'widgetcontrols' in field and field['widgetcontrols'] and 'labelPosition' in field[
                             'widgetcontrols']) else None
                widget_pos = field['layoutorder'] + widget_offset

                # The data tab is somewhat special (it has 2 columns)
                if 'lyt_data' in layout.objectName():
                    tools_gw.add_widget(self.dlg_mincut_man, field, label, widget)
                # If the widget has a label
                elif label:
                    # If it has a labelPosition configured
                    if label_pos is not None:
                        if label_pos == 'top':
                            layout.addWidget(label, 0, widget_pos)
                            if type(widget) is QSpacerItem:
                                layout.addItem(widget, 1, widget_pos)
                            else:
                                layout.addWidget(widget, 1, widget_pos)
                        elif label_pos == 'left':
                            layout.addWidget(label, 0, widget_pos)
                            if type(widget) is QSpacerItem:
                                layout.addItem(widget, 0, widget_pos + 1)
                            else:
                                layout.addWidget(widget, 0, widget_pos + 1)
                            widget_offset += 1
                        else:
                            if type(widget) is QSpacerItem:
                                layout.addItem(widget, 0, widget_pos)
                            else:
                                layout.addWidget(widget, 0, widget_pos)
                    # If widget has label but labelPosition is not configured (put it on the left by default)
                    else:
                        layout.addWidget(label, 0, widget_pos)
                        if type(widget) is QSpacerItem:
                            layout.addItem(widget, 0, widget_pos + 1)
                        else:
                            layout.addWidget(widget, 0, widget_pos + 1)
                # If the widget has no label
                else:
                    if type(widget) is QSpacerItem:
                        layout.addItem(widget, 0, widget_pos)
                    elif field['layoutname'] == 'lyt_mincut_mng_1':
                        layout.addWidget(widget, 1, widget_pos)
                    else:
                        layout.addWidget(widget, 0, widget_pos)

            elif field['layoutname'] != 'lyt_none':
                msg = "The field layoutname is not configured for"
                param = f"formname:{self.tablename}, columnname:{field['columnname']}"
                tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=param, dialog=self.dlg_mincut_man)
        # Add a QSpacerItem into each QGridLayout of the list
        for layout in layout_list:
            vertical_spacer1 = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
            layout.addItem(vertical_spacer1)


def close_mincut_manager(**kwargs):
    """ Function called in class tools_gw.add_button(...) -->
            widget.clicked.connect(partial(getattr(self, function_name), **kwargs)) """
    dialog = kwargs['dialog']
    tools_gw.close_dialog(dialog)


def mincut_selector(**kwargs):
    """ Manage mincut selector """
    dialog = kwargs['dialog']
    class_obj = kwargs['class']
    qtable = dialog.findChild(QTableView, "tab_none_tbl_mincut_edit")
    field_id = "id"
    model = qtable.model()
    selected_mincuts = []
    column_id = tools_qt.get_col_index_by_col_name(qtable, field_id)

    for x in range(0, model.rowCount()):
        index = model.index(x, column_id)
        value = model.data(index)
        selected_mincuts.append(int(value))

    if len(selected_mincuts) == 0:
        msg = "There are no visible mincuts in the table. Try a different filter or make one"
        tools_qgis.show_message(msg, dialog=dialog)
        return
    selector_values = "selector_mincut"
    aux_params = f'"ids":{json.dumps(selected_mincuts)}'
    min_selector = GwSelector()

    dlg_selector = GwSelectorUi(class_obj)
    tools_gw.load_settings(dlg_selector)
    current_tab = tools_gw.get_config_parser('dialogs_tab', "dlg_selector_mincut", "user", "session")
    dlg_selector.btn_close.clicked.connect(partial(tools_gw.close_dialog, dlg_selector))
    dlg_selector.rejected.connect(partial(tools_gw.save_settings, dlg_selector))
    dlg_selector.rejected.connect(
        partial(tools_gw.save_current_tab, dlg_selector, dlg_selector.main_tab, 'mincut'))

    min_selector.get_selector(dlg_selector, selector_values, current_tab=current_tab, aux_params=aux_params)

    tools_gw.open_dialog(dlg_selector, dlg_name='selector')


def delete_mincut(**kwargs):
    """ Delete selected elements of the table (by id) """
    dialog = kwargs['dialog']
    widget = dialog.findChild(QTableView, "tab_none_tbl_mincut_edit")
    table_name = "om_mincut"
    column_id = "id"
    complet_result = kwargs['complet_result']
    # Get selected rows
    selected_list = widget.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message, dialog=dialog)
        return
    inf_text = ""
    list_id = ""
    for i in selected_list:
        row = i.row()
        id_ = i.sibling(row, 0).data()
        inf_text += f"{id_}, "
        list_id += f"'{id_}', "
    inf_text = inf_text[:-2]
    list_id = list_id[:-2]
    msg = "Are you sure you want to delete these mincuts?"
    title = "Delete mincut"

    # Check for mincuts not allowed to be deleted
    row = tools_gw.get_config_value('om_mincut_settings', table='config_param_system')
    om_mincut_settings = row[0] if row else None
    if om_mincut_settings:
        om_mincut_settings = json.loads(om_mincut_settings)
    if (om_mincut_settings is None or not om_mincut_settings.get('deleteUsers') or om_mincut_settings['deleteUsers'] == 'creator'):
        sql = (f"SELECT * FROM {table_name}"
            f" WHERE {column_id} IN ({list_id}) AND (anl_user != current_user OR mincut_state != 0)")
        rows = tools_db.execute_returning(sql, show_exception=False)
        if rows:
            msg = ("You can't delete these mincuts because they aren't planified \n"
                    "or they were created by another user:")
            tools_qt.show_info_box(msg, title, inf_text)
            return

    answer = tools_qt.show_question(msg, title, inf_text)
    if answer:
        sql = (f"DELETE FROM {table_name}"
               f" WHERE {column_id} IN ({list_id})")
        tools_db.execute_sql(sql)
        _reload_table(dialog, complet_result)
        layer = tools_qgis.get_layer_by_tablename('v_om_mincut_node')
        if layer is not None:
            layer.triggerRepaint()
        layer = tools_qgis.get_layer_by_tablename('v_om_mincut_connec')
        if layer is not None:
            layer.triggerRepaint()
        layer = tools_qgis.get_layer_by_tablename('v_om_mincut_arc')
        if layer is not None:
            layer.triggerRepaint()
        layer = tools_qgis.get_layer_by_tablename('v_om_mincut_valve')
        if layer is not None:
            layer.triggerRepaint()
        layer = tools_qgis.get_layer_by_tablename('v_om_mincut')
        if layer is not None:
            layer.triggerRepaint()
        layer = tools_qgis.get_layer_by_tablename('v_om_mincut_hydrometer')
        if layer is not None:
            layer.triggerRepaint()


def _reload_table(dialog, complet_result):
    """ Get inserted element_id and add it to current feature """

    tab_name = 'main'
    list_tables = dialog.findChildren(QTableView)

    widget_list = []
    widget_list.extend(dialog.findChildren(QComboBox, QRegularExpression(f"{tab_name}_")))
    widget_list.extend(dialog.findChildren(QTableView, QRegularExpression(f"{tab_name}_")))
    widget_list.extend(dialog.findChildren(QLineEdit, QRegularExpression(f"{tab_name}_")))
    for table in list_tables:
        widgetname = table.objectName()
        columnname = table.property('columnname')
        if columnname is None:
            msg = "widget {0} has not columnname and cant be configured"
            msg_params = (widgetname,)
            tools_qgis.show_info(msg, 1, msg_params=msg_params)
            continue
        # Get value from filter widgets
        filter_fields = tools_backend_calls.get_filter_qtableview_mincut(dialog, widget_list, complet_result)
        linkedobject = table.property('linkedobject')
        complet_list, widget_list = tools_backend_calls.fill_tbl(complet_result, dialog, widgetname, linkedobject, filter_fields)
        if complet_list is False:
            return False


def cancel_mincut(**kwargs):

    dialog = kwargs['dialog']
    table = dialog.findChild(QTableView, "tab_none_tbl_mincut_edit")
    selected_list = table.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message, dialog=dialog)
        return
    inf_text = ""
    list_id = ""
    for i in selected_list:
        row = i.row()
        id_ = i.sibling(row, 0).data()
        inf_text += f"{id_}, "
        list_id += f"'{id_}', "
    inf_text = inf_text[:-2]
    list_id = list_id[:-2]
    msg = "Are you sure you want to cancel these mincuts?"
    title = "Cancel mincuts"
    answer = tools_qt.show_question(msg, title, inf_text)
    if answer:
        sql = (f"UPDATE om_mincut SET mincut_state = 3 "
               f" WHERE id::text IN ({list_id})")
        tools_db.execute_sql(sql, log_sql=False)
        _reload_table(dialog, kwargs['complet_result'])


def check_filter_days(**kwargs):
    dialog = kwargs['dialog']
    spinbox = dialog.findChild(QSpinBox, "tab_none_spm_next_days")
    if spinbox.isEnabled():
        spinbox.setEnabled(False)
        spinbox.valueChanged.emit(0)
    else:
        spinbox.setEnabled(True)
        spinbox.valueChanged.emit(spinbox.value())


def filter_by_days(dialog, widget):
    widgetcontrols = widget.property('widgetcontrols')
    filter_sign = widgetcontrols.get('filterSign')
    filter_type = widgetcontrols.get('filterType')

    spinbox = dialog.findChild(QSpinBox, "tab_none_spm_next_days")

    date_from = datetime.datetime.now()
    days_added = spinbox.text()
    date_to = datetime.datetime.now()
    date_to += datetime.timedelta(days=int(days_added))

    # If the date_to is less than the date_from, you have to exchange them or the interval will not work
    if date_to < date_from:
        aux = date_from
        date_from = date_to
        date_to = aux

    format_low = '%Y-%m-%d 00:00:00.000'
    format_high = '%Y-%m-%d 23:59:59.999'
    interval = f"{date_from.strftime(format_low)}\'::timestamp AND \'{date_to.strftime(format_high)}"

    filter_fields = f'"forecast_start":{{"value":"{interval}","filterSign":"{filter_sign}","filterType":"{filter_type}"}}, '
    return filter_fields


def open_mincut(**kwargs):
    """ Open mincut form with selected record of the table """
    dialog = kwargs['dialog']
    class_obj = kwargs['class']
    mincut = kwargs['class'].mincut
    table = kwargs['qtable']

    dlg_mincut = GwMincutUi(class_obj)
    tools_gw.load_missing_layers('v_om_mincut%', "OM", "Mincut")
    selected_list = table.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message, dialog=dialog)
        return

    row = selected_list[0].row()

    # Get mincut_id from selected row
    column = tools_qt.get_col_index_by_col_name(table, "id")

    result_mincut_id = selected_list[0].sibling(row, column).data()

    # Close this dialog and open selected mincut
    keep_open_form = tools_gw.get_config_parser('dialogs_actions', 'mincut_manager_keep_open', "user", "init",
                                                prefix=True)
    if tools_os.set_boolean(keep_open_form, False) is not True:
        tools_gw.close_dialog(dialog)
    mincut.is_new = False
    mincut.set_dialog(dlg_mincut)
    mincut.init_mincut_form()
    mincut.load_mincut(result_mincut_id)
    tools_qt._translate_form('mincut', dlg_mincut)
    mincut.manage_docker()
    mincut.set_visible_mincut_layers(True)


def filter_by_dates(dialog, widget):

    widgetname = widget.objectName()
    widgetcontrols = widget.property('widgetcontrols')
    filter_sign = widgetcontrols.get('filterSign')
    state_combo = dialog.findChild(QComboBox, "tab_none_state")
    date_from = dialog.findChild(QgsDateTimeEdit, "tab_none_date_from")
    date_to = dialog.findChild(QgsDateTimeEdit, "tab_none_date_to")

    options = {
         0: {"widget_text_from": "Date from: forecast_start", "widget_text_to": "Date to: forecast_end", "column_from": "forecast_start", "column_to": "forecast_end"},
         1: {"widget_text_from": "Date from: exec_start", "widget_text_to": "Date to: exec_end", "column_from": "exec_start", "column_to": None},
         2: {"widget_text_from": "Date from: exec_start", "widget_text_to": "Date to: exec_end", "column_from": "exec_start", "column_to": None},
         3: {"widget_text_from": "Date from: received_date", "widget_text_to": "Date to: received_date", "column_from": "received_date", "column_to": None}
    }

    state_id = tools_qt.get_combo_value(dialog, state_combo, 0)

    # Get selected dates
    visit_start = date_from.date()
    visit_end = date_to.date()
    date_from = visit_start.toString('yyyyMMdd 00:00:00')
    date_to = visit_end.toString('yyyyMMdd 23:59:59')
    if date_from > date_to:
        message = "Selected date interval is not valid"
        tools_qgis.show_warning(message, dialog=dialog)
        return ''

    # Create interval dates
    value = tools_qt.get_calendar_date(dialog, widget, date_format='yyyy-MM-dd')
    if int(state_id) in (0, 1, 2, 3):
        if options[int(state_id)]['column_to'] is not None:
            if widgetname == 'tab_none_date_from':
                filter_fields = f'"{options[int(state_id)]["column_from"]}":{{"value":"{value}","filterSign":"{filter_sign}"}}, '
            else:
                filter_fields = f'"{options[int(state_id)]["column_to"]}":{{"value":"{value}","filterSign":"{filter_sign}"}}, '
        else:
            filter_fields = f'"{options[int(state_id)]["column_from"]}":{{"value":"{value}","filterSign":"{filter_sign}"}}, '
    else:
        filter_fields = ''

    return filter_fields


def combo_tweaks(**kwargs):
    state_combo = kwargs['widget']
    dialog = kwargs['dialog']
    date_from = dialog.findChild(QgsDateTimeEdit, "tab_none_date_from")
    date_to = dialog.findChild(QgsDateTimeEdit, "tab_none_date_to")
    lbl_date_from = dialog.findChild(QLabel, "lbl_tab_none_date_from")
    lbl_date_to = dialog.findChild(QLabel, "lbl_tab_none_date_to")

    options = {
        0: {"widget_text_from": "Date from: forecast_start", "widget_text_to": "Date to: forecast_end",
            "column_from": "forecast_start", "column_to": "forecast_end"},
        1: {"widget_text_from": "Date from: exec_start", "widget_text_to": "Date to: exec_end",
            "column_from": "exec_start", "column_to": None},
        2: {"widget_text_from": "Date from: exec_start", "widget_text_to": "Date to: exec_end",
            "column_from": "exec_start", "column_to": None},
        3: {"widget_text_from": "Date from: received_date", "widget_text_to": "Date to: received_date",
            "column_from": "received_date", "column_to": None}
    }

    state_id = tools_qt.get_combo_value(dialog, state_combo, 0)
    if state_id == '':
        date_from.setEnabled(False)
        date_to.setEnabled(False)
        msg = "Date from:"
        tools_qt.set_widget_text(dialog, lbl_date_from, msg)
        msg = "Date to:"
        tools_qt.set_widget_text(dialog, lbl_date_to, msg)
    else:
        date_from.setEnabled(True)
        date_to.setEnabled(True)

        if int(state_id) in (0, 1, 2, 3):
            tools_qt.set_widget_text(dialog, lbl_date_from, options[int(state_id)]['widget_text_from'])
            tools_qt.set_widget_text(dialog, lbl_date_to, options[int(state_id)]['widget_text_to'])
        else:
            msg = "Date from:"
            tools_qt.set_widget_text(dialog, lbl_date_from, msg)
            msg = "Date to:"
            tools_qt.set_widget_text(dialog, lbl_date_to, msg)
