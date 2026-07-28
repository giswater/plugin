"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import copy
import json
from functools import partial

from qgis.PyQt.QtWidgets import QLineEdit
from qgis.PyQt.sip import isdeleted
from qgis.core import QgsExpression
from qgis.gui import QgsMapToolEmitPoint

from ..ui.ui_manager import GwScadaGraphUi
from ..utils import tools_gw
from ..utils.snap_manager import GwSnapManager
from ... import global_vars
from ...libs import tools_qt, tools_qgis, tools_db

_SIGNAL_GROUP = 'scada_graph'
_GRAPH_LAYER_NAMES = ('om_graph',)
_GRAPH_TABLE_NAMES = ('om_scada_graph', 've_om_scada_graph')


class GwScadaGraph:

    def __init__(self, parent_widget=None):
        self.parent_widget = parent_widget
        self.iface = global_vars.iface
        self.canvas = global_vars.canvas
        self.dlg = None
        self.snapper_manager = None
        self.vertex_marker = None
        self.emit_point = None
        self.layer_node = None
        self._pick_target = None
        self._node_widgets = {}

    def run(self):
        """ Open scada graph dialog """

        if self.dlg is not None and not isdeleted(self.dlg):
            self.dlg.show()
            self.dlg.raise_()
            self.dlg.activateWindow()
            return

        form = {"formName": "scada_graph", "formType": "scada_graph"}
        body = {"client": {"cur_user": tools_db.current_user}, "form": form}
        json_result = tools_gw.execute_procedure('gw_fct_get_dialog', body)
        if not json_result or json_result.get('status') != 'Accepted':
            tools_qgis.show_warning("Failed to load scada graph dialog.")
            return

        self.dlg = GwScadaGraphUi(self.parent_widget)
        tools_gw.load_settings(self.dlg)
        tools_gw.manage_dlg_widgets(self, self.dlg, self._prepare_dialog_json(json_result))
        self._cache_node_widgets()
        self._init_snapping()
        self.dlg.rejected.connect(partial(self._on_dialog_closed, self.dlg))
        tools_gw.open_dialog(self.dlg, dlg_name='scada_graph', title=tools_qt.tr('Scada graph'))

    def _prepare_dialog_json(self, json_result):
        """ Copy button icons from widgetcontrols into stylesheet """

        result = copy.deepcopy(json_result)
        for field in result.get('body', {}).get('data', {}).get('fields') or []:
            if not field or field.get('hidden'):
                continue
            if field.get('widgettype') != 'button':
                continue
            stylesheet = field.get('stylesheet') or {}
            widgetcontrols = field.get('widgetcontrols') or {}
            if widgetcontrols.get('icon') and not stylesheet.get('icon'):
                field['stylesheet'] = {'icon': widgetcontrols['icon']}
            if not field.get('value') and not (field.get('stylesheet') or {}).get('icon'):
                fallback = widgetcontrols.get('text') or field.get('label') or ''
                if fallback:
                    field['value'] = fallback
        return result

    def _cache_node_widgets(self):
        self._node_widgets = {}
        for name in ('object_1', 'object_2'):
            widget = self._find_widget(self.dlg, name)
            if widget is not None:
                self._node_widgets[name] = widget

    def _init_snapping(self):
        self.snapper_manager = GwSnapManager(self.iface)
        self.vertex_marker = self.snapper_manager.vertex_marker
        self.layer_node = tools_qgis.get_layer_by_tablename('ve_node', show_warning_=False)

    def _find_widget(self, dialog, name):
        for wname in (f'tab_none_{name}', name):
            widget = dialog.findChild(QLineEdit, wname)
            if widget is not None:
                return widget
        return None

    def _get_node_ids(self, dialog):
        object_1 = tools_qt.get_text(
            dialog, self._find_widget(dialog, 'object_1'), return_string_null=False)
        object_2 = tools_qt.get_text(
            dialog, self._find_widget(dialog, 'object_2'), return_string_null=False)
        if not object_1 or not object_2:
            tools_qt.show_info_box(tools_qt.tr('object_1 and object_2 are required.'))
            return None, None
        if not str(object_1).isdigit() or not str(object_2).isdigit():
            tools_qt.show_info_box(tools_qt.tr('object_1 and object_2 must be numeric node ids.'))
            return None, None
        if str(object_1) == str(object_2):
            tools_qt.show_info_box(tools_qt.tr('object_1 and object_2 must be different.'))
            return None, None
        return int(object_1), int(object_2)

    def _set_picked_node(self, target, node_id):
        text = str(node_id).strip()
        if not text or text.upper() == 'NULL':
            return
        widget = self._find_node_widget(target)
        if widget is None:
            return
        widget.blockSignals(True)
        widget.setText(text)
        widget.blockSignals(False)
        widget.update()
        self.dlg.raise_()
        self.dlg.activateWindow()

    def _find_node_widget(self, name):
        widget = self._node_widgets.get(name)
        if widget is not None and not isdeleted(widget):
            return widget
        widget = self._find_widget(self.dlg, name)
        if widget is not None:
            self._node_widgets[name] = widget
        return widget

    def accept(self, dialog):
        """ Insert edge via gw_fct_scada_graph_build and refresh map """

        node1, node2 = self._get_node_ids(dialog)
        if node1 is None:
            return

        params = f'"object_1":{node1}, "object_2":{node2}'
        body = tools_gw.create_body(extras=f'"parameters":{{{params}}}')
        json_result = tools_gw.execute_procedure('gw_fct_scada_graph_build', body)
        if not json_result or json_result.get('status') != 'Accepted':
            return

        edge_id = (json_result.get('body') or {}).get('data', {}).get('edgeId')
        if edge_id is None:
            return
        self._refresh_graph_on_map(edge_id, dialog)

    def _ensure_graph_layer(self):
        """ Load om_graph layer in QGIS project """

        for name in _GRAPH_LAYER_NAMES:
            candidate = tools_qgis.get_layer_by_layername(name, log_info=False)
            if candidate:
                tools_qgis.set_layer_visible(candidate)
                return candidate
        for tablename in _GRAPH_TABLE_NAMES:
            layer = tools_qgis.get_layer_by_tablename(tablename, show_warning_=False)
            if layer:
                tools_qgis.set_layer_visible(layer)
                return layer
        tools_gw.add_layer_database(
            'om_scada_graph', the_geom='the_geom', field_id='edge_id',
            alias='om_graph', group='OM', sub_group='Scada')
        layer = tools_qgis.get_layer_by_layername('om_graph', log_info=False)
        if layer:
            tools_qgis.set_layer_visible(layer)
            return layer
        return tools_qgis.get_layer_by_tablename('om_scada_graph', show_warning_=False)

    def _refresh_graph_on_map(self, edge_id, dialog=None):
        """ Reload layer, select edge and zoom """

        layer = self._ensure_graph_layer()
        if not layer:
            tools_qgis.show_warning(
                tools_qt.tr('Scada graph saved in DB but om_graph layer could not be loaded.'),
                dialog=dialog)
            return
        layer.dataProvider().reloadData()
        layer.triggerRepaint()
        layer.removeSelection()
        expr_obj = QgsExpression(f'"edge_id" = {edge_id}')
        tools_qgis.select_features_by_expr(layer, expr_obj)
        tools_gw.zoom_to_feature_by_id('om_scada_graph', 'edge_id', edge_id)
        self.canvas.refresh()
        tools_qgis.show_info(
            tools_qt.tr('Scada graph edge created'),
            parameter=str(edge_id),
            dialog=dialog)

    def activate_snapping(self, target, dialog):
        if self.layer_node is None:
            tools_qgis.show_warning(tools_qt.tr('Node layer not found in the project.'))
            return
        self._disconnect_snapping()
        self._pick_target = target
        self.snapper_manager.set_vertex_marker(self.vertex_marker, icon_type=4)
        self.emit_point = QgsMapToolEmitPoint(self.canvas)
        self.canvas.setMapTool(self.emit_point)
        self.iface.setActiveLayer(self.layer_node)
        tools_gw.connect_signal(self.canvas.xyCoordinates, self._mouse_move,
                                _SIGNAL_GROUP, 'xyCoordinates_mouse_move')
        tools_gw.connect_signal(self.emit_point.canvasClicked, self._snapping_node,
                                _SIGNAL_GROUP, 'canvasClicked_snapping_node')
        self.emit_point.canvasReleaseEvent = lambda e: self.iface.actionPan().trigger()

    def _mouse_move(self, point):
        event_point = self.snapper_manager.get_event_point(point=point)
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if result.isValid() and self.snapper_manager.get_snapped_layer(result) == self.layer_node:
            self.snapper_manager.add_marker(result, self.vertex_marker)
            return
        self.vertex_marker.hide()

    def _snapping_node(self, point, button=None):
        if button is not None and button != 1:
            return
        event_point = self.snapper_manager.get_event_point(point=point)
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if not result.isValid() or self.snapper_manager.get_snapped_layer(result) != self.layer_node:
            return
        if not self._pick_target:
            return
        node_id = self.snapper_manager.get_snapped_feature(result).attribute('node_id')
        self._set_picked_node(self._pick_target, node_id)
        tools_qgis.show_info(tools_qt.tr('Node selected'), parameter=str(node_id))
        self._disconnect_snapping()

    def _disconnect_snapping(self):
        if self.emit_point is not None:
            tools_qgis.disconnect_snapping(False, self.emit_point, self.vertex_marker)
        tools_gw.disconnect_signal(_SIGNAL_GROUP)
        self._pick_target = None

    def _on_dialog_closed(self, dlg):
        self._disconnect_snapping()
        tools_gw.save_settings(dlg)
        self.dlg = None


def pick_node(**kwargs):
    func_params = kwargs.get('func_params') or {}
    if isinstance(func_params, str):
        try:
            func_params = json.loads(func_params.replace("'", '"'))
        except (json.JSONDecodeError, TypeError):
            func_params = {}
    target = func_params.get('target')
    if not target:
        return
    kwargs['class'].activate_snapping(target, kwargs['dialog'])


def accept(**kwargs):
    kwargs['class'].accept(kwargs['dialog'])


def close(**kwargs):
    class_obj = kwargs['class']
    class_obj._disconnect_snapping()
    tools_gw.save_settings(kwargs['dialog'])
    tools_gw.close_dialog(kwargs['dialog'])
    class_obj.dlg = None
