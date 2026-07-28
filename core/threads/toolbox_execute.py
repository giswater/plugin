"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from qgis.PyQt.QtWidgets import QComboBox, QCheckBox, QDoubleSpinBox, QSpinBox, QWidget, QLineEdit
from qgis.PyQt.QtCore import pyqtSignal
from qgis.gui import QgsDateTimeEdit

from .task import GwTask
from ..utils import tools_gw
from ...libs import lib_vars, tools_log, tools_qt, tools_qgis


class GwToolBoxTask(GwTask):
    """ This shows how to subclass QgsTask """

    fake_progress = pyqtSignal()

    def __init__(self, toolbox, description, dialog, combo, result, timer=None, aux_params="null"):

        super().__init__(description)
        self.toolbox = toolbox
        self.dialog = dialog
        self.combo = combo
        self.result = result
        self.body = None
        self.json_result = None
        self.exception = None
        self.function_name = None
        self.timer = timer
        self.aux_params = aux_params
        self.schema_name = None

    def run(self):

        super().run()
        extras = ''
        feature_field = ''

        self.function_name = self.result.get("functionname")
        try:
            if self.result.get('source') == 'cm':
                self.schema_name = 'cm'
            else:
                self.schema_name = None
        except Exception:
            pass

        if self.function_name is not None:
            self.toolbox.save_settings_values(self.dialog, self.function_name)
            self.toolbox.save_parametric_values(self.dialog, self.function_name)
        else:
            return False

        if self.result['functionparams'].get('featureType'):
            layer = None

            layer_name = tools_qt.get_combo_value(self.dialog, self.combo, 1)
            if layer_name != -1:
                layer = self.toolbox.set_selected_layer(self.dialog, self.combo)
                if not layer:
                    return False

            selection_mode = self.toolbox.rbt_checked['widget']
            extras += f'"selectionMode":"{selection_mode}",'
            # Check selection mode and get (or not get) all feature id
            open_char = '['
            close_char = ']'
            pks = tools_qgis.get_primary_key(layer)
            if pks:
                pks = pks.split(",")
                if len(pks) > 1:
                    open_char = '{'
                    close_char = '}'
            feature_id_list = f'"id":{open_char}'
            if (selection_mode == 'wholeSelection') or (selection_mode == 'previousSelection' and layer is None):
                feature_id_list += close_char
            elif selection_mode == 'previousSelection' and layer is not None:
                features = layer.selectedFeatures()
                if len(pks) > 1:
                    for pk in pks:
                        feature_id_list += f'"{pk}":[ '
                        for feature in features:
                            feature_id = feature.attribute(pk)
                            feature_id_list += f'"{feature_id}", '
                        if len(features) > 0:
                            feature_id_list = feature_id_list[:-2] + '], '
                else:
                    for feature in features:
                        feature_id = feature.attribute(pks[0])
                        feature_id_list += f'"{feature_id}", '
                if len(features) > 0:
                    feature_id_list = feature_id_list[:-2] + close_char
                else:
                    feature_id_list += close_char
            if layer_name != -1:
                feature_field = f'"tableName":"{layer_name}", '
                feature_type = tools_qt.get_combo_value(self.dialog, self.dialog.cmb_feature_type, 0)
                feature_field += f'"featureType":"{feature_type}", '
            feature_field += feature_id_list

        widget_list = self.dialog.grb_parameters.findChildren(QWidget)
        widget_is_void = False
        extras += '"parameters":{'

        if self.result.get('fields') is not None:
            for field in self.result.get('fields'):
                widget = self.dialog.findChild(QWidget, field['widgetname'])
                param_name = widget.objectName()
                if type(widget) in (QLineEdit,):
                    widget.setStyleSheet(None)
                    value = tools_qt.get_text(self.dialog, widget, False, False)
                    extras += f'"{param_name}":"{value}", '.replace('""', 'null')
                    if value == '' and widget.property('ismandatory'):
                        widget_is_void = True
                        widget.setStyleSheet("border: 1px solid red")
                elif type(widget) in (QSpinBox, QDoubleSpinBox):
                    value = tools_qt.get_text(self.dialog, widget, False, False)
                    if value == '':
                        value = 0
                    extras += f'"{param_name}":"{value}", '
                elif isinstance(widget, QComboBox):
                    value = tools_qt.get_combo_value(self.dialog, widget, 0)
                    if value not in (None, ''):
                        extras += f'"{param_name}":"{value}", '
                elif type(widget) in (QCheckBox,):
                    value = tools_qt.is_checked(self.dialog, widget)
                    extras += f'"{param_name}":"{str(value).lower()}", '
                elif isinstance(widget, QgsDateTimeEdit):
                    value = tools_qt.get_calendar_date(self.dialog, widget)
                    if value == "" or value is None:
                        extras += f'"{param_name}":null, '
                    else:
                        extras += f'"{param_name}":"{value}", '

        if widget_is_void:
            msg = "This parameter is mandatory. Please, set a value"
            tools_log.log_info(msg, parameter='')
            return False

        if len(widget_list) > 0:
            extras = extras[:-2]
        extras += '}'
        if self.aux_params is False:
            self.aux_params = "null"
        extras += f', "aux_params":{self.aux_params}'
        self.body = tools_gw.create_body(feature=feature_field, extras=extras)
        msg = "Task '{0}' execute procedure '{1}' with parameters: '{2}', '{3}', '{4}'"
        msg_params = ("Toolbox execute", self.function_name, self.body, 
                      f"aux_conn={self.aux_conn}", "is_thread=True")
        tools_log.log_info(msg, msg_params=msg_params)
        self.json_result = tools_gw.execute_procedure(self.function_name, self.body,
                                                      aux_conn=self.aux_conn, is_thread=True, schema_name=self.schema_name)

        if self.isCanceled():
            return False
        if not self.json_result or self.json_result is None:
            return False
        if self.json_result['status'] == 'Failed':
            return False

        return True

    def finished(self, result):

        super().finished(result)

        sql = f"SELECT {self.function_name}("
        if self.body:
            sql += f"{self.body}"
        sql += ");"
        msg = "Task '{0}' manage json response with parameters: '{1}', '{2}', '{3}'"
        msg_params = ("Toolbox execute", self.json_result, sql, "None")
        tools_log.log_info(msg, msg_params=msg_params)
        tools_gw.manage_json_response(self.json_result, sql, None)

        self.dialog.btn_cancel.hide()
        self.dialog.btn_close.show()
        self.dialog.progressBar.setVisible(False)
        if self.timer:
            self.timer.stop()
        if self.isCanceled():
            return

        if result is False and self.exception is not None:
            msg = f'''<b>{tools_qt.tr('key')}: </b>{self.exception}<br>'''
            msg += f'''<b>{tools_qt.tr('key container')}: </b>'body/data/ <br>'''
            msg += f'''<b>{tools_qt.tr('Python file')}: </b>{__name__} <br>'''
            msg += f'''<b>{tools_qt.tr('Python function')}:</b> {self.__class__.__name__} <br>'''
            title = "Key on returned json from ddbb is missed."
            tools_qt.show_exception_message(title, msg)
        # If database fail
        elif result is False and lib_vars.session_vars['last_error_msg'] is not None:
            tools_qt.show_exception_message(msg=lib_vars.session_vars['last_error_msg'])
        elif result:
            tools_gw.fill_tab_log(self.dialog, self.json_result['body']['data'], True, True, 1, False, False)
            self.dialog.btn_run.setEnabled(False)
        elif self.json_result:
            tools_gw.manage_json_exception(self.json_result)
        # If sql function return null
        elif result is False:
            msg = "Database returned null. Check postgres function '{0}'"
            msg_params = ("gw_fct_getinfofromid",)
            tools_log.log_warning(msg, msg_params=msg_params)

    def cancel(self):

        self.toolbox.remove_layers()

        if self.timer:
            self.timer.stop()

        super().cancel()
