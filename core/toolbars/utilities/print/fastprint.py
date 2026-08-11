"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import json
import re
from functools import partial

from qgis.PyQt.QtGui import QRegularExpressionValidator
from qgis.PyQt.QtCore import QRegularExpression
from qgis.PyQt.QtPrintSupport import QPrinter, QPrintDialog
from qgis.PyQt.QtWidgets import QDialog, QLabel, QLineEdit
from qgis.core import QgsLayoutItemMap, QgsPrintLayout, QgsLayoutItemLabel, QgsLayoutExporter

from ....ui.ui_manager import GwPrintUi
from ....utils import tools_gw
from ..... import global_vars
from .....libs import tools_qgis, tools_qt


class GwFastprint:
    """ Action 65a: Fast print """

    def __init__(self):
        self.iface = global_vars.iface
        self.canvas = global_vars.canvas

        self.destroyed = False
        self.printer = None
        self.rubber_band = None
        self.my_json = {}

    def open_print(self):

        self.destroyed = False
        self.printer = None
        self.rubber_band = tools_gw.create_rubberband(self.canvas)
        self.my_json = {}

        composers_list = tools_qgis.get_composer()
        if composers_list == '"{}"':
            msg = "No composers found."
            tools_qt.show_info_box(msg, "Info")
            return

        self.initial_rotation = self.canvas.rotation()

        self.dlg_composer = GwPrintUi(self)
        tools_gw.load_settings(self.dlg_composer)

        # Create and populate dialog
        extras = '"composers":' + str(composers_list)
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_getprint', body)
        if not json_result or json_result['status'] == 'Failed':
            return False

        if json_result['formTabs']:
            fields = json_result['formTabs'][0]
            # This dialog is created from config_form_fieds
            # where formname == 'print' and formtype == 'utils'
            # At the moment, u can set column widgetfunction with 'gw_fct_setprint' or open_composer
            self._create_dialog(self.dlg_composer, fields)
        tools_qt.hide_void_groupbox(self.dlg_composer)
        # Set current values from canvas
        rotation = self.canvas.rotation()
        scale = int(self.canvas.scale())
        # 'tab_none' + '_' +  <widgetname>
        w_rotation = self.dlg_composer.findChild(QLineEdit, "tab_none_rotation")
        if w_rotation:
            w_rotation.editingFinished.connect(partial(self._set_rotation, w_rotation))
            tools_qt.set_widget_text(self.dlg_composer, w_rotation, rotation)

        w_scale = self.dlg_composer.findChild(QLineEdit, "tab_none_scale")
        if w_scale:
            w_scale.editingFinished.connect(partial(self._set_scale, w_scale))
            reg_exp = QRegularExpression(r"\d{0,8}[\r]?")
            w_scale.setValidator(QRegularExpressionValidator(reg_exp))
            tools_qt.set_widget_text(self.dlg_composer, w_scale, scale)
        self.my_json['rotation'] = rotation
        self.my_json['scale'] = scale

        # Signals
        self.dlg_composer.btn_print.clicked.connect(partial(self.__print, self.dlg_composer))
        self.dlg_composer.btn_preview.clicked.connect(partial(self._preview, self.dlg_composer, True))
        self.dlg_composer.btn_close.clicked.connect(partial(tools_gw.close_dialog, self.dlg_composer))
        self.dlg_composer.btn_close.clicked.connect(partial(tools_gw.save_settings, self.dlg_composer))
        self.dlg_composer.btn_close.clicked.connect(self._destructor)
        self.dlg_composer.rejected.connect(partial(tools_gw.save_settings, self.dlg_composer))
        self.dlg_composer.rejected.connect(self._destructor)

        self._check_whidget_exist(self.dlg_composer)
        self._load_composer_values(self.dlg_composer)

        tools_gw.open_dialog(self.dlg_composer, dlg_name='fastprint')

        # Control if no have composers
        if composers_list != '"{}"':
            self._accept(self.dlg_composer, self.my_json)
            tools_gw.connect_signal(self.canvas.extentsChanged, partial(self._accept, self.dlg_composer, self.my_json),
                                    'print', 'open_print_extentsChanged_accept')
        else:
            self.dlg_composer.btn_print.setEnabled(False)
            self.dlg_composer.btn_preview.setEnabled(False)

    def _create_dialog(self, dialog, fields):

        for field in fields['fields']:
            label, widget = self._set_widgets_into_composer(dialog, field, self.my_json)
            tools_gw.add_widget(dialog, field, label, widget)
            tools_gw.get_values(dialog, widget, self.my_json)

    def _set_rotation(self, widget):
        """ Set rotation to mapCanvas """
        self.canvas.setRotation(float(widget.text()))

    def _set_scale(self, widget):
        """ Set zoomScale to mapCanvas """
        self.canvas.zoomScale(float(widget.text()))

    def __print(self, dialog):

        if not self.printer:
            self.printer = QPrinter()
        self._preview(dialog, False)
        selected_com = self._get_current_composer()
        if selected_com is None:
            return

        printdialog = QPrintDialog(self.printer)
        if printdialog.exec() != QDialog.DialogCode.Accepted:
            return

        actual_printer = QgsLayoutExporter(selected_com)
        # The correct instruction for python3 is:
        # success = actual_printer.print(self.printer, QgsLayoutExporter.PrintExportSettings())
        # but python2 produces an error in the word 'print' at actual_printer.print(...),
        # then we need to create a fake to cheat python2
        print_ = getattr(actual_printer, 'print')
        print_(self.printer, QgsLayoutExporter.PrintExportSettings())

    def _preview(self, dialog, show):
        """ Export values from widgets(only QLineEdit) into dialog, to selected composer
                if composer.widget.id == dialog.widget.property('columnname')
        """

        selected_com = self._get_current_composer()
        widget_list = dialog.findChildren(QLineEdit)

        for widget in widget_list:
            item = selected_com.itemById(widget.property('columnname'))
            if type(item) is QgsLayoutItemLabel:
                item.setText(str(widget.text()))
                item.refresh()
        if show:
            self._open_composer(dialog)

    def _destructor(self):
        self.canvas.setRotation(self.initial_rotation)
        tools_gw.disconnect_signal('print')
        self.destroyed = True
        if self.rubber_band:
            self.canvas.scene().removeItem(self.rubber_band)
            self.rubber_band = None

    def _check_whidget_exist(self, dialog):
        """ Check if widget exist in composer """

        selected_com = self._get_current_composer()
        widget_list = dialog.grb_option_values.findChildren(QLineEdit)
        for widget in widget_list:
            item = selected_com.itemById(widget.property('columnname'))
            if type(item) is not QgsLayoutItemLabel or item is None:
                widget.clear()
                widget.setStyleSheet("border: 1px solid red")
                msg = "Widget '{0}' not found in the composer"
                msg_params = (widget.property('columnname'),)
                widget.setPlaceholderText(tools_qt.tr(msg, list_params=msg_params))
            elif type(item) is QgsLayoutItemLabel and item is not None:
                widget.setStyleSheet(None)

    def _load_composer_values(self, dialog):
        """ Load values from composer into form dialog """

        selected_com = self._get_current_composer()
        widget_list = dialog.grb_option_values.findChildren(QLineEdit)

        if selected_com is not None:
            for widget in widget_list:
                item = selected_com.itemById(widget.property('columnname'))
                if type(item) is QgsLayoutItemLabel:
                    widget.setText(str(item.text()))

    def _accept(self, dialog, my_json):

        if self.destroyed:
            return

        if my_json == '' or str(my_json) == '{}':
            tools_gw.close_dialog(dialog)
            return False

        composer_templates = []
        active_composers = tools_qgis.get_composers_list()
        for composer in active_composers:
            if not isinstance(composer, QgsPrintLayout):
                continue
            composer_map = []
            composer_template = {'ComposerTemplate': composer.name()}
            index = 0
            for item in composer.items():
                cur_map = {}
                if isinstance(item, QgsLayoutItemMap):
                    cur_map['width'] = item.rect().width()
                    cur_map['height'] = item.rect().height()
                    cur_map['name'] = item.displayName()
                    cur_map['index'] = index
                    composer_map.append(cur_map)
                    composer_template['ComposerMap'] = composer_map
                    index += 1
            composer_templates.append(composer_template)
            my_json['ComposerTemplates'] = composer_templates

        composer_name = my_json['composer']
        rotation = my_json['rotation']
        scale = my_json['scale']
        extent = self.canvas.extent()

        p1 = {'xcoord': extent.xMinimum(), 'ycoord': extent.yMinimum()}
        p2 = {'xcoord': extent.xMaximum(), 'ycoord': extent.yMaximum()}
        ext = {'p1': p1, 'p2': p2}
        my_json['extent'] = ext

        my_json = json.dumps(my_json)
        client = '"client":{"device":4, "infoType":1, "lang":"ES"}, '
        form = '"form":{''}, '
        feature = '"feature":{''}, '
        data = '"data":' + str(my_json)
        body = "$${" + client + form + feature + data + "}$$"
        json_result = tools_gw.execute_procedure('gw_fct_setprint', body)
        if not json_result or json_result['status'] == 'Failed':
            return False

        result = json_result['data']
        self._draw_rectangle(result, self.rubber_band)
        map_index = json_result['data']['mapIndex']

        maps = []
        active_composers = tools_qgis.get_composers_list()
        for composer in active_composers:
            maps = []
            if composer.name() == composer_name:
                for item in composer.items():
                    if isinstance(item, QgsLayoutItemMap):
                        maps.append(item)
                break

        if len(maps) > 0:
            if rotation is None or rotation == 0:
                rotation = self.canvas.rotation()
            if scale is None or scale == 0:
                scale = self.canvas.scale()
            self.canvas.setRotation(float(rotation))
            maps[map_index].zoomToExtent(self.canvas.extent())
            maps[map_index].setScale(float(scale))
            maps[map_index].setMapRotation(float(rotation))

        return True

    def _set_widgets_into_composer(self, dialog, field, my_json=None):
        """
        functions called in -> widget.currentIndexChanged.connect(partial(getattr(self, function_name), dialog, my_json))
            def set_print(self, dialog, my_json)
        """

        widget = None
        label = None
        if field['label']:
            label = QLabel()
            label.setObjectName('lbl_' + field['widgetname'])
            label.setText(field['label'].capitalize())
            if field.get('stylesheet') is not None and 'label' in field['stylesheet']:
                label = tools_gw.set_stylesheet(field, label)
            if 'tooltip' in field:
                label.setToolTip(field['tooltip'])
            else:
                label.setToolTip(field['label'].capitalize())
        if field['widgettype'] == 'text' or field['widgettype'] == 'typeahead':
            widget = tools_gw.add_lineedit(field)
            widget = tools_gw.set_widget_size(widget, field)
            widget = tools_gw.set_data_type(field, widget)
            widget.editingFinished.connect(partial(tools_gw.get_values, dialog, widget, my_json))
            widget.returnPressed.connect(partial(tools_gw.get_values, dialog, widget, my_json))
        elif field['widgettype'] == 'combo':
            widget = tools_gw.add_combo(field, ignore_function=True)
            widget = tools_gw.set_widget_size(widget, field)
            widget.currentIndexChanged.connect(partial(tools_gw.get_values, dialog, widget, my_json))
            if 'widgetfunction' in field:
                if field['widgetfunction'].get('functionName') is not None:
                    function_name = field['widgetfunction']['functionName']
                    widget.currentIndexChanged.connect(partial(getattr(self, function_name), dialog, my_json))

        return label, widget

    def _get_current_composer(self):
        """ Get composer selected in QComboBox """

        selected_com = None
        active_composers = tools_qgis.get_composers_list()
        for composer in active_composers:
            if composer.name() == self.my_json['composer']:
                selected_com = composer
                break

        return selected_com

    def _open_composer(self, dialog):
        """ Open selected composer and load values from composer into form dialog """

        selected_com = self._get_current_composer()
        if selected_com is not None:
            self.iface.openLayoutDesigner(layout=selected_com)

        self._load_composer_values(dialog)

    def set_print(self, dialog, my_json):
        """ Function called in def _set_widgets_into_composer(...) -->
            widget.currentIndexChanged.connect(partial(getattr(self, function_name), dialog, my_json)) """

        if my_json['composer'] != '-1':
            self._check_whidget_exist(self.dlg_composer)
            self._load_composer_values(dialog)
            self._accept(dialog, my_json)

    def _draw_rectangle(self, result, rubber_band):
        """ Draw lines based on geometry """

        if result['geometry'] is None:
            return

        list_coord = re.search(r'\((.*)\)', str(result['geometry']['st_astext']))
        points = tools_qgis.get_geometry_vertex(list_coord)
        tools_qgis.draw_polyline(points, rubber_band)

    # endregion