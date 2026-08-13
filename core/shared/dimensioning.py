"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: latin-1 -*-
from functools import partial

from qgis.PyQt.QtCore import Qt, QTimer
from qgis.PyQt.QtWidgets import QWidget, QAction, QCheckBox, QComboBox, QCompleter, QGridLayout, QLabel, QLineEdit, \
    QSizePolicy, QSpacerItem
from qgis.core import QgsPointXY
from qgis.gui import QgsMapToolEmitPoint, QgsMapTip, QgsVertexMarker

from ..utils import tools_gw
from ..ui.ui_manager import GwDimensioningUi
from ..utils.snap_manager import GwSnapManager
from ... import global_vars
from ...libs import lib_vars, tools_qgis, tools_qt


class GwDimensioning:

    def __init__(self):

        self.iface = global_vars.iface
        self.settings = global_vars.giswater_settings
        self.plugin_dir = lib_vars.plugin_dir
        self.canvas = global_vars.canvas
        self.points = None
        self.snapper_manager = GwSnapManager(self.iface)
        self.vertex_marker = self.snapper_manager.vertex_marker
        self.vertex_marker.setIconType(QgsVertexMarker.IconType.ICON_CIRCLE)

    def open_dimensioning_form(self, qgis_feature=None, layer=None, db_return=None, fid=None, rubber_band=None):

        self.dlg_dim = GwDimensioningUi(self)
        tools_gw.load_settings(self.dlg_dim)

        self.user_current_layer = self.iface.activeLayer()
        # Set layers dimensions, node and connec
        self.layer_dimensions = tools_qgis.get_layer_by_tablename("ve_dimensions")
        self.layer_node = tools_qgis.get_layer_by_tablename("ve_node")
        self.layer_arc = tools_qgis.get_layer_by_tablename("ve_arc")
        self.layer_connec = tools_qgis.get_layer_by_tablename("ve_connec")
        self.layer_gully = tools_qgis.get_layer_by_tablename("ve_gully")

        feature = None
        if qgis_feature is None:
            features = self.layer_dimensions.getFeatures()
            for feature in features:
                if feature['id'] == fid:
                    return feature
            qgis_feature = feature

        # qgis_feature = self.get_feature_by_id(self.layer_dimensions, fid, 'id')

        # when function is called from new feature
        if db_return is None:
            rubber_band = tools_gw.create_rubberband(self.canvas, "point")
            extras = f'"coordinates":{{{self.points}}}'
            body = tools_gw.create_body(extras=extras)
            json_result = tools_gw.execute_procedure('gw_fct_getdimensioning', body)
            if json_result is None or json_result['status'] == 'Failed':
                return False
            db_return = json_result

            # get id from db response
            self.fid = int(db_return['body']['feature']['id']) + 1
        else:
            self.fid = int(db_return['body']['feature']['id'])
        # ACTION SIGNALS
        action_edit = self.dlg_dim.findChild(QAction, "actionEdit")
        action_edit.setChecked(layer.isEditable())
        action_edit.triggered.connect(partial(self._manage_edition, action_edit, qgis_feature, layer))
        tools_gw.add_icon(action_edit, "101")

        action_snapping = self.dlg_dim.findChild(QAction, "actionSnapping")
        action_snapping.triggered.connect(partial(self._snapping, action_snapping))
        tools_gw.add_icon(action_snapping, "103")

        action_orientation = self.dlg_dim.findChild(QAction, "actionOrientation")
        action_orientation.triggered.connect(partial(self._orientation, action_orientation))
        tools_gw.add_icon(action_orientation, "133")

        # LAYER SIGNALS
        tools_gw.connect_signal(self.layer_dimensions.editingStarted,
                                partial(tools_gw.enable_all, self.dlg_dim, db_return['body']['data']),
                                'dimensioning', 'open_dimensioning_form_layer_dimensions_editingStarted_enable_all')
        tools_gw.connect_signal(self.layer_dimensions.editingStopped,
                                partial(tools_gw.enable_widgets, self.dlg_dim, db_return['body']['data'], False),
                                'dimensioning', 'open_dimensioning_form_layer_dimensions_editingStopped_enable_widgets')

        # WIDGETS SIGNALS
        self.dlg_dim.btn_accept.clicked.connect(
            partial(self._save_dimensioning, qgis_feature, layer, True))
        self.dlg_dim.btn_cancel.clicked.connect(partial(self._cancel_dimensioning, action_snapping, action_orientation))
        self.dlg_dim.key_escape.connect(partial(tools_gw.close_dialog, self.dlg_dim))
        self.dlg_dim.dlg_closed.connect(partial(self._cancel_dimensioning, action_snapping, action_orientation))
        self.dlg_dim.dlg_closed.connect(partial(tools_gw.save_settings, self.dlg_dim))
        self.dlg_dim.dlg_closed.connect(rubber_band.reset)
        self.dlg_dim.dlg_closed.connect(self.layer_node.removeSelection)
        if self.layer_arc:
            self.dlg_dim.dlg_closed.connect(self.layer_arc.removeSelection)
        if self.layer_gully:
            self.dlg_dim.dlg_closed.connect(self.layer_gully.removeSelection)
        if self.layer_connec:
            self.dlg_dim.dlg_closed.connect(self.layer_connec.removeSelection)

        self._create_map_tips()

        layout_list = []
        for field in db_return['body']['data']['fields']:
            if field.get('hidden'):
                continue

            label, widget = self._set_widgets(self.dlg_dim, db_return, field)

            if widget.objectName() == 'id':
                tools_qt.set_widget_text(self.dlg_dim, widget, self.fid)
            layout = self.dlg_dim.findChild(QGridLayout, field['layoutname'])

            # Profilactic issue to prevent missed layouts againts db response and form
            if layout is not None:
                # Take the QGridLayout with the intention of adding a QSpacerItem later
                if layout not in layout_list and layout.objectName() not in ('lyt_top_1', 'lyt_bot_1', 'lyt_bot_2'):
                    layout_list.append(layout)
                    # Add widgets into layout
                    layout.addWidget(label, 0, field['layoutorder'])
                    layout.addWidget(widget, 1, field['layoutorder'])

                # If field is on top or bottom layout the position is horitzontal no vertical
                if field['layoutname'] in ('lyt_top_1', 'lyt_bot_1', 'lyt_bot_2'):
                    layout.addWidget(label, 0, field['layoutorder'])
                    layout.addWidget(widget, 1, field['layoutorder'])
                else:
                    tools_gw.add_widget(self.dlg_dim, field, label, widget)

        # Add a QSpacerItem into each QGridLayout of the list
        for layout in layout_list:
            vertical_spacer1 = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
            layout.addItem(vertical_spacer1)

        if self.layer_dimensions:
            self.iface.setActiveLayer(self.layer_dimensions)
            if self.layer_dimensions.isEditable():
                tools_gw.enable_all(self.dlg_dim, db_return['body']['data'])
            else:
                tools_gw.enable_widgets(self.dlg_dim, db_return['body']['data'], False)

        tools_qt.hide_void_groupbox(self.dlg_dim)
        self.iface.actionPan().trigger()

        self.dlg_dim.findChild(QWidget, "feature_id").textChanged.connect(partial(self._feature_id_changed, self.dlg_dim))

        tools_gw.open_dialog(self.dlg_dim, dlg_name='dimensioning')
        return False, False

    # region private functions

    def _feature_id_changed(self, dialog, text: str) -> None:
        feature_type = dialog.findChild(QComboBox, "feature_type")
        text = int(text) if text.isdigit() else None
        if not text:
            feature_type.setCurrentText('')
            return

        layer_feature_map = {
            self.layer_node: 'NODE',
            self.layer_arc: 'ARC',
            self.layer_connec: 'CONNEC',
            self.layer_gully: 'GULLY'
        }

        for layer, feature_type_text in layer_feature_map.items():
            if layer:
                if layer.getFeature(text).isValid():
                    feature_type.setCurrentText(feature_type_text)
                    return
                else:
                    feature_type.setCurrentText('')

    def _cancel_dimensioning(self, action_snapping, action_orientation):

        self.iface.actionRollbackEdits().trigger()
        if action_snapping.isChecked():
            action_snapping.trigger()
        if action_orientation.isChecked():
            action_orientation.trigger()
        tools_qgis.restore_user_layer('ve_node', self.user_current_layer)
        tools_gw.disconnect_signal('dimensioning')
        tools_gw.close_dialog(self.dlg_dim)

    def _save_dimensioning(self, qgis_feature, layer, close_dlg=True):

        # Upsert feature into db
        layer.updateFeature(qgis_feature)
        layer.commitChanges()

        # Create body
        fields = ''
        list_widgets = self.dlg_dim.findChildren(QLineEdit)
        for widget in list_widgets:
            widget_name = widget.property('columnname')
            widget_value = tools_qt.get_text(self.dlg_dim, widget)
            if widget_value == 'null':
                continue
            fields += f'"{widget_name}":"{widget_value}", '

        list_widgets = self.dlg_dim.findChildren(QCheckBox)
        for widget in list_widgets:
            widget_name = widget.property('columnname')
            widget_value = f'"{tools_qt.is_checked(self.dlg_dim, widget)}"'
            if widget_value in ('null', '""'):
                continue
            fields += f'"{widget_name}":{widget_value},'

        list_widgets = self.dlg_dim.findChildren(QComboBox)
        for widget in list_widgets:
            widget_name = widget.property('columnname')
            widget_value = f'"{tools_qt.get_combo_value(self.dlg_dim, widget)}"'
            if widget_value in ('null', '""', '"-1"'):
                continue
            fields += f'"{widget_name}":{widget_value},'

        # remove last character (,) from fields
        fields = fields[:-1]

        feature = '"tableName":"ve_dimensions", '
        feature += f'"id":"{self.fid}"'
        extras = f'"fields":{{{fields}}}'
        body = tools_gw.create_body(feature=feature, extras=extras)
        tools_gw.execute_procedure('gw_fct_setdimensioning', body)

        # Close dialog
        if close_dlg:
            tools_gw.close_dialog(self.dlg_dim)

    def _deactivate_signals(self, action, emit_point=None):

        self.vertex_marker.hide()
        try:
            self.canvas.xyCoordinates.disconnect()
        except TypeError:
            pass

        try:
            emit_point.canvasClicked.disconnect()
        except TypeError:
            pass

        if not action.isChecked():
            action.setChecked(False)
            return True

        return False

    def _manage_edition(self, action, qgis_feature, layer):

        if action.isChecked():
            self.layer_dimensions.startEditing()
        else:
            # ask if want to save changes
            # if so: self.layer_dimensions.commitChanges()
            # else: self.layer_dimensions.rollBack()
            msg = 'Are you sure to save this feature?'
            title = "Save feature"
            answer = tools_qt.show_question(msg, title, None)
            if not answer:
                tools_qt.set_action_checked(action, True)
                return
            self._save_dimensioning(qgis_feature, layer, close_dlg=False)

    def _snapping(self, action):

        # Set active layer and set signals
        tools_gw.disconnect_signal('dimensioning', 'snapping_ep_canvasClicked_click_button_snapping')
        tools_gw.disconnect_signal('dimensioning', 'snapping_xyCoordinates_mouse_move')
        emit_point = QgsMapToolEmitPoint(self.canvas)
        self.canvas.setMapTool(emit_point)
        if self._deactivate_signals(action, emit_point):
            return

        self.snapper_manager.remove_marker(self.vertex_marker)
        self.previous_snapping = self.snapper_manager.get_snapping_options()
        self.snapper_manager.set_snapping_layers()

        self.dlg_dim.actionOrientation.setChecked(False)
        self.iface.setActiveLayer(self.layer_node)
        self.iface.setActiveLayer(self.layer_arc)
        self.iface.setActiveLayer(self.layer_connec)
        self.iface.setActiveLayer(self.layer_gully)
        tools_gw.connect_signal(self.canvas.xyCoordinates, self._mouse_move,
                                'dimensioning', 'snapping_xyCoordinates_mouse_move')
        tools_gw.connect_signal(emit_point.canvasClicked, partial(self._click_button_snapping, action, emit_point),
                                'dimensioning', 'snapping_ep_canvasClicked_click_button_snapping')

    def _mouse_move(self, point):

        # Hide marker and get coordinates
        self.vertex_marker.hide()
        event_point = self.snapper_manager.get_event_point(point=point)

        # Snapping
        result = self.snapper_manager.snap_to_project_config_layers(event_point)
        if result.isValid():
            layer = self.snapper_manager.get_snapped_layer(result)
            # Check feature
            if layer == self.layer_node or layer == self.layer_connec or layer == self.layer_arc or layer == self.layer_gully:
                self.snapper_manager.add_marker(result, self.vertex_marker)

    def _click_button_snapping(self, action, emit_point, point, btn):

        if not self.layer_dimensions:
            return

        if btn == Qt.MouseButton.RightButton:
            if btn == Qt.MouseButton.RightButton:
                action.setChecked(False)
                tools_gw.disconnect_signal('dimensioning', 'snapping_ep_canvasClicked_click_button_snapping')
                tools_gw.disconnect_signal('dimensioning', 'snapping_xyCoordinates_mouse_move')
                self._deactivate_signals(action, emit_point)
                return

        layer = self.layer_dimensions
        self.iface.setActiveLayer(layer)

        # Get coordinates
        event_point = self.snapper_manager.get_event_point(point=point)

        # Snapping
        result = self.snapper_manager.snap_to_project_config_layers(event_point)
        if result.isValid():

            layer = self.snapper_manager.get_snapped_layer(result)
            # Check feature
            if layer == self.layer_node:
                feat_type = 'node'
            elif layer == self.layer_connec:
                feat_type = 'connec'
            elif layer == self.layer_arc:
                feat_type = 'arc'
            elif layer == self.layer_gully:
                feat_type = 'gully'
            else:
                return

            if self.layer_node:
                self.layer_node.removeSelection()
            if self.layer_arc:
                self.layer_arc.removeSelection()
            if self.layer_connec:
                self.layer_connec.removeSelection()
            if self.layer_gully:
                self.layer_gully.removeSelection()

            # Get the point
            snapped_feat = self.snapper_manager.get_snapped_feature(result)
            feature_id = self.snapper_manager.get_snapped_feature_id(result)
            element_id = snapped_feat.attribute(feat_type + '_id')

            # Leave selection
            layer.select([feature_id])

            # Get depth of the feature
            fieldname = None
            self.project_type = tools_gw.get_project_type()
            if self.project_type == 'ws':
                fieldname = "depth"
            elif self.project_type == 'ud' and feat_type == 'node':
                fieldname = "ymax"
            elif self.project_type == 'ud' and feat_type == 'connec':
                fieldname = "connec_depth"

            if fieldname is None:
                return

            depth = snapped_feat.attribute(fieldname)
            if depth in ('', None, 0, '0', 'NULL'):
                tools_qt.set_widget_text(self.dlg_dim, "depth", None)
            else:
                tools_qt.set_widget_text(self.dlg_dim, "depth", depth)
            tools_qt.set_widget_text(self.dlg_dim, "feature_id", element_id)
            tools_qt.set_widget_text(self.dlg_dim, "feature_type", feat_type.upper())

            tools_gw.disconnect_signal('dimensioning', 'snapping_ep_canvasClicked_click_button_snapping')
            tools_gw.disconnect_signal('dimensioning', 'snapping_xyCoordinates_mouse_move')
            self._deactivate_signals(action, emit_point)
            action.setChecked(False)

    def _orientation(self, action):

        tools_gw.disconnect_signal('dimensioning', 'orientation_ep_canvasClicked_click_button_orientation')
        tools_gw.disconnect_signal('dimensioning', 'orientation_xyCoordinates_canvas_move_event')
        emit_point = QgsMapToolEmitPoint(self.canvas)
        self.canvas.setMapTool(emit_point)
        if self._deactivate_signals(action, emit_point):
            return

        self.snapper_manager.remove_marker(self.vertex_marker)
        self.previous_snapping = self.snapper_manager.get_snapping_options()
        self.snapper_manager.set_snapping_layers()

        self.dlg_dim.actionSnapping.setChecked(False)
        tools_gw.connect_signal(self.canvas.xyCoordinates, self._canvas_move_event,
                                'dimensioning', 'orientation_xyCoordinates_canvas_move_event')
        tools_gw.connect_signal(emit_point.canvasClicked, partial(self._click_button_orientation, action, emit_point),
                                'dimensioning', 'orientation_ep_canvasClicked_click_button_orientation')

    def _canvas_move_event(self, point):

        # Get clicked point
        self.vertex_marker.hide()
        event_point = self.snapper_manager.get_event_point(point=point)
        result = self.snapper_manager.snap_to_project_config_layers(event_point)
        if self.snapper_manager.result_is_valid():
            self.snapper_manager.add_marker(result, self.vertex_marker)

    def _click_button_orientation(self, action, emit_point, point, btn):

        if not self.layer_dimensions:
            return

        if btn == Qt.MouseButton.RightButton:
            action.setChecked(False)
            tools_gw.disconnect_signal('dimensioning', 'orientation_ep_canvasClicked_click_button_orientation')
            tools_gw.disconnect_signal('dimensioning', 'orientation_xyCoordinates_canvas_move_event')
            self._deactivate_signals(action, emit_point)
            return

        self.x_symbol = self.dlg_dim.findChild(QLineEdit, "x_symbol")
        self.x_symbol.setText(str(int(point.x())))
        self.y_symbol = self.dlg_dim.findChild(QLineEdit, "y_symbol")
        self.y_symbol.setText(str(int(point.y())))

        tools_gw.disconnect_signal('dimensioning', 'orientation_ep_canvasClicked_click_button_orientation')
        tools_gw.disconnect_signal('dimensioning', 'orientation_xyCoordinates_canvas_move_event')
        self._deactivate_signals(action, emit_point)
        action.setChecked(False)

    def _create_map_tips(self):
        """ Create MapTips on the map """

        row = tools_gw.get_config_value('qgis_dim_tooltip')
        if not row or row[0].lower() != 'true':
            return

        tools_gw.disconnect_signal('dimensioning', 'create_map_tips_timer_map_tips_timeout_show_map_tip')
        self.timer_map_tips = QTimer(self.canvas)
        self.map_tip_node = QgsMapTip()
        self.map_tip_connec = QgsMapTip()

        tools_gw.connect_signal(self.canvas.xyCoordinates, self._map_tip_changed,
                                'dimensioning', 'create_map_tips_xyCoordinates_map_tip_changed')
        tools_gw.connect_signal(self.timer_map_tips.timeout, self._show_map_tip,
                                'dimensioning', 'create_map_tips_timer_map_tips_timeout_show_map_tip')

        tools_gw.disconnect_signal('dimensioning', 'create_map_tips_timer_map_tips_clear_timeout_clear_map_tip')
        self.timer_map_tips_clear = QTimer(self.canvas)
        tools_gw.connect_signal(self.timer_map_tips_clear.timeout, self._clear_map_tip,
                                'dimensioning', 'create_map_tips_timer_map_tips_clear_timeout_clear_map_tip')

    def _map_tip_changed(self, point):
        """ SLOT. Initialize the Timer to show MapTips on the map """

        if self.canvas.underMouse():
            self.last_map_position = QgsPointXY(point.x(), point.y())
            self.map_tip_node.clear(self.canvas)
            self.map_tip_connec.clear(self.canvas)
            self.timer_map_tips.start(100)

    def _show_map_tip(self):
        """ Show MapTips on the map """

        self.timer_map_tips.stop()
        if self.canvas.underMouse():
            point_qgs = self.last_map_position
            point_qt = self.canvas.mouseLastXY()
            if self.layer_node:
                self.map_tip_node.showMapTip(self.layer_node, point_qgs, point_qt, self.canvas)
            if self.layer_connec:
                self.map_tip_connec.showMapTip(self.layer_connec, point_qgs, point_qt, self.canvas)
            if self.layer_arc:
                self.map_tip_arc.showMapTip(self.layer_arc, point_qgs, point_qt, self.canvas)
            if self.layer_gully:
                self.map_tip_gully.showMapTip(self.layer_gully, point_qgs, point_qt, self.canvas)
            self.timer_map_tips_clear.start(1000)

    def _clear_map_tip(self):
        """ Clear MapTips """

        self.timer_map_tips_clear.stop()
        self.map_tip_node.clear(self.canvas)
        self.map_tip_connec.clear(self.canvas)

    def _set_widgets(self, dialog, db_return, field):

        widget = None
        label = None
        if field['label']:
            label = QLabel()
            label.setObjectName('lbl_' + field['widgetname'])
            label.setText(field['label'].capitalize())
            stylesheet = field.get('stylesheet')
            if stylesheet and 'label' in stylesheet:
                label = tools_gw.set_stylesheet(field, label)
            tooltip = field.get('tooltip')
            if tooltip:
                label.setToolTip(tooltip)
            else:
                label.setToolTip(field['label'].capitalize())
        if field['widgettype'] == 'text' or field['widgettype'] == 'typeahead':
            completer = QCompleter()
            widget = tools_gw.add_lineedit(field)
            widget = tools_gw.set_widget_size(widget, field)
            widget = tools_gw.set_data_type(field, widget)
            if field['widgettype'] == 'typeahead':
                widget = tools_gw.set_typeahead(field, dialog, widget, completer)
        elif field['widgettype'] == 'combo':
            widget = tools_gw.add_combo(field)
            widget = tools_gw.set_widget_size(widget, field)
        elif field['widgettype'] == 'check':
            kwargs = {"dialog": dialog, "field": field}
            widget = tools_gw.add_checkbox(**kwargs)
        elif field['widgettype'] == 'datetime':
            widget = tools_gw.add_calendar(dialog, field)
        elif field['widgettype'] == 'button':
            kwargs = {"dialog": dialog, "field": field}
            widget = tools_gw.add_button(**kwargs)
            widget = tools_gw.set_widget_size(widget, field)
        elif field['widgettype'] == 'hyperlink':
            widget = tools_gw.add_hyperlink(field)
            widget = tools_gw.set_widget_size(widget, field)
        elif field['widgettype'] == 'hspacer':
            widget = tools_qt.add_horizontal_spacer()
        elif field['widgettype'] == 'vspacer':
            widget = tools_qt.add_verticalspacer()
        elif field['widgettype'] == 'textarea':
            widget = tools_gw.add_textarea(field)
        elif field['widgettype'] in 'spinbox':
            kwargs = {"dialog": dialog, "field": field}
            widget = tools_gw.add_spinbox(**kwargs)
        elif field['widgettype'] == 'tableview':
            widget = tools_gw.add_tableview(db_return, field, dialog)
            widget = tools_gw.add_tableview_header(widget, field)
            widget = tools_gw.fill_tableview_rows(widget, field)
            widget = tools_gw.set_tablemodel_config(dialog, widget, field['widgetname'], sort_order=Qt.SortOrder.DescendingOrder)
            tools_qt.set_tableview_config(widget)
        widget.setObjectName(widget.property('columnname'))

        return label, widget

    # endregion
