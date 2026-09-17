"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial

from qgis.PyQt.QtCore import QPoint
from qgis.PyQt.QtGui import QColor
from qgis.core import QgsProject, QgsPointXY, QgsPointLocator, QgsFeatureRequest
from qgis.gui import QgsVertexMarker, QgsMapCanvas, QgsMapToolEmitPoint

from ... import global_vars
from ...libs import tools_qgis
from . import tools_gw


class GwSnapManager(object):

    def __init__(self, iface):

        self.iface = iface
        self.canvas = self.iface.mapCanvas()
        self.previous_snapping = None
        self.is_valid = False
        self.point_xy = {"x": None, "y": None}

        # Snapper
        self.snapping_config = self.get_snapping_options()
        self.snapper = self.get_snapper()

        # Set default vertex marker
        color = QColor(255, 100, 255)
        self.vertex_marker = QgsVertexMarker(self.canvas)
        self.vertex_marker.setIconType(QgsVertexMarker.IconType.ICON_CROSS)
        self.vertex_marker.setColor(color)
        self.vertex_marker.setIconSize(15)
        self.vertex_marker.setPenWidth(3)
        global_vars.snappers.append(self)

    def set_snapping_layers(self):
        """ Set main snapping layers """

        self.layer_arc = tools_qgis.get_layer_by_tablename('ve_arc')
        self.layer_connec = tools_qgis.get_layer_by_tablename('ve_connec')
        self.layer_gully = tools_qgis.get_layer_by_tablename('ve_gully')
        self.layer_node = tools_qgis.get_layer_by_tablename('ve_node')

    def get_snapping_options(self):
        """ Function that collects all the snapping options """

        global_snapping_config = QgsProject.instance().snappingConfig()
        return global_snapping_config

    def get_snapper(self):
        """ Return snapper """

        snapper = QgsMapCanvas.snappingUtils(self.canvas)
        return snapper

    def snap_to_current_layer(self, event_point, vertex_marker=None, layer=None, locator_type=None):

        self.is_valid = False
        if event_point is None:
            return None, None

        if layer is not None:
            self.iface.setActiveLayer(layer)
            self.snapper.setCurrentLayer(layer)
        if locator_type is None:
            locator_type = QgsPointLocator.Type.All

        result = self.snapper.snapToCurrentLayer(event_point, locator_type)
        if vertex_marker:
            if result.isValid():
                # Get the point and add marker on it
                point = QgsPointXY(result.point())
                vertex_marker.setCenter(point)
                vertex_marker.show()

        self.is_valid = result.isValid()
        return result

    def snap_to_project_config_layers(self, event_point, vertex_marker=None) -> QgsPointLocator.Match:

        self.is_valid = False
        if event_point is None:
            return None, None

        result = self.snapper.snapToMap(event_point)
        if vertex_marker:
            if result.isValid():
                # Get the point and add marker on it
                point = QgsPointXY(result.point())
                vertex_marker.setCenter(point)
                vertex_marker.show()

        self.is_valid = result.isValid()
        return result

    def add_marker(self, result, vertex_marker=None, icon_type=None):

        if not result.isValid():
            return None

        if vertex_marker is None:
            vertex_marker = self.vertex_marker

        point = result.point()
        if icon_type:
            vertex_marker.setIconType(icon_type)
        vertex_marker.setCenter(point)
        vertex_marker.show()

        return point

    def remove_marker(self, vertex_marker=None):

        if vertex_marker is None:
            vertex_marker = self.vertex_marker

        vertex_marker.hide()

    def get_event_point(self, event=None, point=None):
        """ Get point """

        event_point = None
        x = None
        y = None
        try:
            if event:
                x = event.pos().x()
                y = event.pos().y()
            if point:
                map_point = self.canvas.getCoordinateTransform().transform(point)
                x = map_point.x()
                y = map_point.y()
            event_point = QPoint(int(x), int(y))
        except Exception:
            pass
        finally:
            return event_point

    def get_snapped_layer(self, result) -> QgsPointLocator.Match:

        layer = None
        if result.isValid():
            layer = result.layer()

        return layer

    def get_snapped_point(self, result):

        point = None
        if result.isValid():
            point = QgsPointXY(result.point())

        return point

    def get_snapped_feature_id(self, result):

        feature_id = None
        if result.isValid():
            feature_id = result.featureId()

        return feature_id

    def get_snapped_feature(self, result, select_feature=False):

        if not result.isValid():
            return None

        snapped_feat = None
        try:
            layer = result.layer()
            feature_id = result.featureId()
            feature_request = QgsFeatureRequest().setFilterFid(feature_id)
            snapped_feat = next(layer.getFeatures(feature_request))
            if select_feature and snapped_feat:
                self._select_snapped_feature(result, feature_id)
        except Exception:
            pass
        finally:
            return snapped_feat

    def result_is_valid(self):
        return self.is_valid

    def add_point(self, vertex_marker):
        """ Create the appropriate map tool and connect to the corresponding signal """

        active_layer = global_vars.iface.activeLayer()
        if active_layer is None:
            active_layer = tools_qgis.get_layer_by_tablename('sys_version')
            global_vars.iface.setActiveLayer(active_layer)

        # Snapper
        tools_gw.disconnect_signal('snap_managers', f'{hash(self)}_ep_canvasClicked_get_xy')
        emit_point = QgsMapToolEmitPoint(global_vars.canvas)
        global_vars.canvas.setMapTool(emit_point)
        tools_gw.connect_signal(global_vars.canvas.xyCoordinates, partial(self._get_mouse_move, vertex_marker),
                                'snap_managers', f'{hash(self)}_xyCoordinates_get_mouse_move')
        tools_gw.connect_signal(emit_point.canvasClicked, partial(self._get_xy, vertex_marker, emit_point),
                                'snap_managers', f'{hash(self)}_ep_canvasClicked_get_xy')

    def set_vertex_marker(self, vertex_marker, icon_type=1, color_type=0, icon_size=15, pen_width=3):

        # Vertex marker
        icons = {0: QgsVertexMarker.IconType.ICON_NONE, 1: QgsVertexMarker.IconType.ICON_CROSS, 2: QgsVertexMarker.IconType.ICON_X,
                 3: QgsVertexMarker.IconType.ICON_BOX, 4: QgsVertexMarker.IconType.ICON_CIRCLE}
        colors = {0: QColor(255, 100, 255), 1: QColor(0, 255, 0), 2: QColor(0, 255, 0),
                  3: QColor(255, 0, 0), 4: QColor(0, 0, 255)}

        vertex_marker.setIconType(icons[icon_type])
        vertex_marker.setColor(colors[color_type])
        vertex_marker.setIconSize(icon_size)
        vertex_marker.setPenWidth(pen_width)

    # region private functions

    def _get_mouse_move(self, vertex_marker, point):

        # Hide marker and get coordinates
        vertex_marker.hide()
        event_point = self.get_event_point(point=point)

        # Snapping
        result = self.snap_to_project_config_layers(event_point)
        if result.isValid():
            self.add_marker(result, vertex_marker)
        else:
            vertex_marker.hide()

    def _get_xy(self, vertex_marker, emit_point, point):
        """ Get coordinates of selected point """

        event_point = self.get_event_point(point=point)
        result = self.snap_to_project_config_layers(event_point)
        # Get snapped point only if snapping is valid
        if result.isValid():
            point = self.get_snapped_point(result)

        # Setting x, y coordinates from point
        self.point_xy['x'] = point.x()
        self.point_xy['y'] = point.y()

        msg = "Geometry has been added!"
        tools_qgis.show_info(msg)
        tools_gw.disconnect_signal('snap_managers', f'{hash(self)}_ep_canvasClicked_get_xy')
        tools_gw.disconnect_signal('snap_managers', f'{hash(self)}_xyCoordinates_get_mouse_move')
        global_vars.iface.mapCanvas().refreshAllLayers()
        vertex_marker.hide()

    def _select_snapped_feature(self, result, feature_id):

        if not result.isValid():
            return

        layer = result.layer()
        layer.select([feature_id])

    # endregion
