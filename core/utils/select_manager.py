"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import math
from enum import Enum
from typing import Optional
from qgis.PyQt.QtCore import QEvent
from qgis.PyQt.QtGui import QColor
from qgis.PyQt.QtWidgets import QApplication
from qgis.PyQt.QtCore import Qt
from qgis.core import (QgsPointXY, QgsRectangle, QgsGeometry, QgsWkbTypes, QgsVectorLayer,
                    QgsFeature, QgsFeatureRequest)
from qgis.gui import QgsMapTool, QgsVertexMarker, QgsMapCanvas, QgisInterface
from qgis.PyQt.QtWidgets import QDialog

from ..utils import tools_gw
from ... import global_vars
from ...libs import tools_qgis, tools_qt, tools_os
from ..utils.snap_manager import GwSnapManager
from .selection_mode import GwSelectionMode


class GwSelectionType(Enum):
    """Enum for different selection types"""
    RECTANGLE = "rectangle"
    POLYGON = "polygon"
    CIRCLE = "circle"
    FREEHAND = "freehand"
    POINT = "point"  # Single point selection mode
    DEFAULT = "rectangle"  # Default to rectangle for backward compatibility


class GwSelectionBehavior(Enum):
    """Enum for different selection behaviors"""
    REMOVE = "remove"  # Remove from current selection (Ctrl+Shift)
    ADD = "add"       # Add to current selection (Ctrl)
    REPLACE = "replace"  # Replace current selection (no modifiers)
    DEFAULT = "replace"  # Default behavior when no modifiers are pressed


class GwSelectManager(QgsMapTool):

    def __init__(self, class_object: object, table_object: Optional[str] = None, dialog: Optional['QDialog'] = None,
                 selection_mode: GwSelectionMode = GwSelectionMode.DEFAULT,
                 save_rectangle: bool = False, selection_type: GwSelectionType = GwSelectionType.DEFAULT) -> None:
        """
        Unified selection manager supporting multiple selection types
        Args:
            class_object: Class where we will look for @layers, @feature_type, @list_ids, etc
            table_object: Name of the table object
            dialog: Dialog widget for UI interaction
            selection_mode: Mode of selection behavior
            save_rectangle: Whether to save rectangle coordinates
            selection_type: Type of selection tool to use
        """
        self.class_object: object = class_object
        self.iface: 'QgisInterface' = global_vars.iface
        self.canvas: 'QgsMapCanvas' = global_vars.canvas
        self.table_object: Optional[str] = table_object
        self.dialog: Optional['QDialog'] = dialog
        self.selection_mode: GwSelectionMode = selection_mode
        self.save_rectangle: bool = save_rectangle
        self.selection_type: GwSelectionType = selection_type

        # Call superclass constructor and set current action
        QgsMapTool.__init__(self, self.canvas)

        self.snapper_manager = GwSnapManager(self.iface)
        self.snapper = self.snapper_manager.get_snapper()
        
        # Initialize rubber bands and vertex marker for different selection types
        self._init_rubber_bands()
        
        # Initialize vertex marker for snapping
        self.vertex_marker = QgsVertexMarker(self.canvas)
        self.vertex_marker.setIconType(QgsVertexMarker.IconType.ICON_CROSS)
        self.vertex_marker.setColor(QColor(255, 100, 255))
        self.vertex_marker.setIconSize(15)
        self.vertex_marker.setPenWidth(3)
        self.vertex_marker.hide()

        # Common properties
        self.selected_features = []
        self.feature_cache = {}  # Cache for storing features by layer and feature ID
        self._reset_selection()

    def _init_rubber_bands(self):
        """Initialize rubber bands based on selection type"""
        # Always use polygon type for rubber band to support filled rectangles
        self.rubber_band = tools_gw.create_rubberband(self.canvas, "polygon")

        self.rubber_band.setColor(QColor(255, 100, 255))
        self.rubber_band.setFillColor(QColor(254, 178, 76, 63))
        self.rubber_band.setWidth(2)

        # Additional rubber band for circle center marker
        if self.selection_type == GwSelectionType.CIRCLE:
            self.center_marker = tools_gw.create_rubberband(self.canvas, "point")
            self.center_marker.setColor(QColor(255, 0, 0))
            self.center_marker.setWidth(3)
            self.center_marker.setIconSize(8)

    # region QgsMapTools inherited
    """ QgsMapTools inherited event functions """

    def canvasPressEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton:
            point = self.toMapCoordinates(event.pos())

            if self.selection_type == GwSelectionType.POINT:
                self._handle_point_selection(event)
            elif self.selection_type in [GwSelectionType.RECTANGLE, GwSelectionType.DEFAULT]:
                self._handle_rectangle_press(point)
            elif self.selection_type == GwSelectionType.POLYGON:
                self._handle_polygon_press(point)
            elif self.selection_type == GwSelectionType.CIRCLE:
                self._handle_circle_press(point)
            elif self.selection_type == GwSelectionType.FREEHAND:
                self._handle_freehand_press(point)

        elif event.button() == Qt.MouseButton.RightButton:
            self._handle_right_click(event)

    def canvasReleaseEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton:
            if self.selection_type == GwSelectionType.POINT:
                # Point selection is handled in canvasPressEvent
                pass
            elif self.selection_type in [GwSelectionType.RECTANGLE, GwSelectionType.DEFAULT]:
                self._handle_rectangle_release(event)
            elif self.selection_type == GwSelectionType.CIRCLE:
                self._handle_circle_release(event)
            elif self.selection_type == GwSelectionType.FREEHAND:
                self._handle_freehand_release(event)
        else:
            self.rubber_band.hide()

    def canvasMoveEvent(self, event):
        point = self.toMapCoordinates(event.pos())

        if self.selection_type in [GwSelectionType.RECTANGLE, GwSelectionType.DEFAULT]:
            self._handle_rectangle_move(point)
        elif self.selection_type == GwSelectionType.POLYGON:
            self._handle_polygon_move(point)
        elif self.selection_type == GwSelectionType.CIRCLE:
            self._handle_circle_move(point)
        elif self.selection_type == GwSelectionType.FREEHAND:
            self._handle_freehand_move(event, point)
        elif self.selection_type == GwSelectionType.POINT:
            self._handle_point_move(event, point)

    def deactivate(self):
        self.rubber_band.hide()
        if hasattr(self, 'center_marker'):
            self.center_marker.hide()
        if hasattr(self.iface, 'statusBarIface'):
            self.iface.statusBarIface().clearMessage()
        QgsMapTool.deactivate(self)

    def activate(self):
        pass

    def keyPressEvent(self, event):
        """Handle keyboard input"""
        if event.key() == Qt.Key.Key_Escape:
            self._clear_drawing()
        elif event.key() in (Qt.Key.Key_Return, Qt.Key.Key_Enter):
            if self.selection_type == GwSelectionType.CIRCLE and hasattr(self, 'center_point') and self.center_point:
                self._finish_circle_selection(self.center_point, getattr(self, 'current_radius', 0))

    # endregion

    # region private functions

    def _get_cached_feature(self, layer: QgsVectorLayer, feature_id: int) -> Optional['QgsFeature']:
        """
        Get a feature from the cache or fetch it from the layer
        Args:
            layer: The QgsVectorLayer containing the feature
            feature_id: The ID of the feature to retrieve
        Returns:
            QgsFeature: The requested feature or None if not found
        """
        layer_id = layer.id()
        cache_key = f"{layer_id}_{feature_id}"
        
        if cache_key in self.feature_cache:
            return self.feature_cache[cache_key]
            
        # Get feature directly from layer using feature request
        feature_request = QgsFeatureRequest().setFilterFid(feature_id)
        try:
            feature = next(layer.getFeatures(feature_request))
            if feature:
                self.feature_cache[cache_key] = feature
                return feature
        except StopIteration:
            # Feature not found
            pass
            
        return None

    def _cache_feature(self, layer: QgsVectorLayer, feature: 'QgsFeature') -> None:
        """
        Add a feature to the cache
        Args:
            layer: The QgsVectorLayer containing the feature
            feature: The QgsFeature to cache
        """
        cache_key = f"{layer.id()}_{feature.id()}"
        self.feature_cache[cache_key] = feature

    def _clear_feature_cache(self) -> None:
        """Clear the feature cache"""
        self.feature_cache.clear()

    def _reset_selection(self):
        """Reset values for all selection types"""
        # Rectangle/Default
        self.start_point = None
        self.end_point = None
        self.is_emitting_point = False

        # Polygon
        self.points = []
        self.is_drawing = False

        # Circle
        self.center_point = None
        self.current_radius = 0

        # Freehand
        self.min_distance = 5.0

        # Clear feature cache
        self._clear_feature_cache()

        self._reset_rubber_band()

    def _clear_drawing(self):
        """Clear all drawing elements"""
        self.rubber_band.hide()
        if hasattr(self, 'center_marker'):
            self.center_marker.hide()
        self._reset_selection()

    def _reset_rubber_band(self):
        try:
            # Always use polygon type for rubber band
            tools_gw.reset_rubberband(self.rubber_band, "polygon")
        except Exception:
            pass

    # Rectangle selection handlers
    def _handle_rectangle_press(self, point):
        self.start_point = point
        self.end_point = self.start_point
        self.is_emitting_point = True
        self._show_rectangle(self.start_point, self.end_point)

    def _handle_rectangle_move(self, point):
        if not self.is_emitting_point:
            return
        self.end_point = point
        self._show_rectangle(self.start_point, self.end_point)

    def _handle_rectangle_release(self, event):
        self.is_emitting_point = False
        rectangle = self._get_rectangle()

        if self.save_rectangle and rectangle:
            xmin = rectangle.xMinimum()
            xmax = rectangle.xMaximum()
            ymin = rectangle.yMinimum()
            ymax = rectangle.yMaximum()
            tools_qt.set_widget_text(self.save_rectangle, "txt_coordinates", f"{xmin},{xmax},{ymin},{ymax} [EPSG:25831]")
            self.rubber_band.hide()
            return

        if event.button() != Qt.MouseButton.LeftButton:
            self.rubber_band.hide()
            return

        self._perform_selection(rectangle, event)

    def _show_rectangle(self, start_point, end_point):
        self._reset_rubber_band()
        if start_point.x() == end_point.x() or start_point.y() == end_point.y():
            return

        point1 = QgsPointXY(start_point.x(), start_point.y())
        point2 = QgsPointXY(start_point.x(), end_point.y())
        point3 = QgsPointXY(end_point.x(), end_point.y())
        point4 = QgsPointXY(end_point.x(), start_point.y())

        self.rubber_band.addPoint(point1, False)
        self.rubber_band.addPoint(point2, False)
        self.rubber_band.addPoint(point3, False)
        self.rubber_band.addPoint(point4, True)
        self.rubber_band.show()

    def _get_rectangle(self):
        if self.start_point is None or self.end_point is None:
            return None
        elif self.start_point.x() == self.end_point.x() or self.start_point.y() == self.end_point.y():
            return None
        return QgsRectangle(self.start_point, self.end_point)

    # Polygon selection handlers
    def _handle_polygon_press(self, point):
        self.points.append(point)
        self.is_drawing = True
        self._update_polygon()

    def _handle_polygon_move(self, point):
        if self.is_drawing and self.points:
            temp_points = self.points + [point]
            self._draw_polygon(temp_points)

    def _update_polygon(self):
        if len(self.points) >= 2:
            self._draw_polygon(self.points)

    def _draw_polygon(self, points):
        self.rubber_band.reset(QgsWkbTypes.GeometryType.PolygonGeometry)
        for i, point in enumerate(points):
            self.rubber_band.addPoint(point, i == len(points) - 1)
        self.rubber_band.show()

    # Circle selection handlers
    def _handle_circle_press(self, point):
        self.center_point = point
        if hasattr(self, 'center_marker'):
            self.center_marker.reset()
            self.center_marker.addPoint(self.center_point)
            self.center_marker.show()

    def _handle_circle_move(self, point):
        if self.center_point:
            self.current_radius = math.sqrt(
                (point.x() - self.center_point.x())**2 +
                (point.y() - self.center_point.y())**2
            )
            self._draw_circle(self.center_point, self.current_radius)

            if hasattr(self.iface, 'statusBarIface'):
                radius_text = f"Circle radius: {self.current_radius:.2f} map units - Click to confirm"
                self.iface.statusBarIface().showMessage(radius_text, 0)

    def _handle_circle_release(self, event):
        if self.center_point:
            current_point = self.toMapCoordinates(event.pos())
            self.current_radius = math.sqrt(
                (current_point.x() - self.center_point.x())**2 +
                (current_point.y() - self.center_point.y())**2
            )

            if self.current_radius > 0:
                self._finish_circle_selection(self.center_point, self.current_radius)
            else:
                self._clear_drawing()

    def _draw_circle(self, center, radius, segments=64):
        if radius <= 0:
            return

        self.rubber_band.reset(QgsWkbTypes.GeometryType.PolygonGeometry)

        points = []
        for i in range(segments):
            angle = 2 * math.pi * i / segments
            x = center.x() + radius * math.cos(angle)
            y = center.y() + radius * math.sin(angle)
            points.append(QgsPointXY(x, y))

        if points:
            circle_polygon = QgsGeometry.fromPolygonXY([points])
            self.rubber_band.setToGeometry(circle_polygon, None)

        self.rubber_band.show()

    def _finish_circle_selection(self, center, radius):
        if radius <= 0:
            self._clear_drawing()
            return

        circle_geom = QgsGeometry.fromPointXY(center).buffer(radius, 64)
        self._perform_geometry_selection(circle_geom)

        if hasattr(self.iface, 'statusBarIface'):
            result_text = f"Circle selection completed (radius: {radius:.2f})"
            self.iface.statusBarIface().showMessage(result_text, 3000)

        self._clear_drawing()

    # Freehand selection handlers
    def _handle_freehand_press(self, point):
        self.points = [point]
        self.is_drawing = True
        self.rubber_band.reset(QgsWkbTypes.GeometryType.PolygonGeometry)
        self.rubber_band.addPoint(point, False)
        self.rubber_band.show()

    def _handle_freehand_move(self, event, point):
        if self.is_drawing and self.points:
            last_point = self.points[-1]
            last_screen = self.toCanvasCoordinates(last_point)
            current_screen = event.pos()
            pixel_distance = ((current_screen.x() - last_screen.x())**2 +
                            (current_screen.y() - last_screen.y())**2)**0.5

            if pixel_distance >= self.min_distance:
                self.points.append(point)
                self._update_freehand_rubber_band()
    
    def _handle_point_move(self, event, point):
        """ Mouse move event for point selection with snapping to valid layers """
        if not self.snapper_manager:
            return

        # Hide marker initially
        if self.vertex_marker:
            self.vertex_marker.hide()
            
        # Get event point for snapping
        event_point = self.snapper_manager.get_event_point(point=point)
        if not event_point:
            return
            
        # Snap to project config layers to find any valid features
        result = self.snapper_manager.snap_to_project_config_layers(event_point)
        if result.isValid():
            # Check if the snapped layer is in our valid selection layers
            snapped_layer = self.snapper_manager.get_snapped_layer(result)
            if snapped_layer in self.class_object.rel_layers[self.class_object.rel_feature_type]:
                # Show vertex marker for valid features that can be selected
                self.snapper_manager.add_marker(result, self.vertex_marker)

    def _handle_freehand_release(self, event):
        if self.is_drawing:
            self.is_drawing = False

            if len(self.points) >= 3:
                self._update_freehand_rubber_band()
                self._finish_freehand_selection()
            else:
                self.rubber_band.hide()
                self.points = []

    def _update_freehand_rubber_band(self):
        if len(self.points) >= 2:
            self.rubber_band.reset(QgsWkbTypes.GeometryType.PolygonGeometry)
            for i, point in enumerate(self.points):
                self.rubber_band.addPoint(point, False)
            self.rubber_band.addPoint(self.points[0], True)
            self.rubber_band.show()

    def _finish_freehand_selection(self):
        if len(self.points) < 3:
            return

        polygon = QgsGeometry.fromPolygonXY([self.points])
        self._perform_geometry_selection(polygon)

        self.rubber_band.hide()
        self.points = []

    # Right click handler
    def _handle_point_selection(self, event):
        """Handle point selection mode - select features by clicking on them"""
        point = self.toMapCoordinates(event.pos())
        self._perform_selection(point, event)

    def _handle_right_click(self, event):
        if self.selection_type == GwSelectionType.POLYGON and len(self.points) >= 3:
            point = self.toMapCoordinates(event.pos())
            self.points.append(point)
            self._finish_polygon_selection()
        else:
            self._clear_drawing()

    def _finish_polygon_selection(self):
        if len(self.points) < 3:
            return

        polygon = QgsGeometry.fromPolygonXY([self.points])
        self._perform_geometry_selection(polygon)

        self.rubber_band.hide()
        self.points = []
        self.is_drawing = False

    # Common selection methods
    def _get_selection_behavior(self) -> GwSelectionBehavior:
        """
        Determine selection behavior based on keyboard modifiers
        Returns:
            GwSelectionBehavior: The selection behavior to use
        """
        ctrl_pressed = QApplication.keyboardModifiers() & Qt.KeyboardModifier.ControlModifier
        shift_pressed = QApplication.keyboardModifiers() & Qt.KeyboardModifier.ShiftModifier

        if ctrl_pressed and shift_pressed:
            return GwSelectionBehavior.REMOVE
        elif ctrl_pressed and not shift_pressed:
            return GwSelectionBehavior.ADD
        else:
            return GwSelectionBehavior.DEFAULT

    def _perform_selection(self, geometry=None, event=None):
        """Perform selection for rectangle or point selection"""
        selection_behavior = self._get_selection_behavior()

        tools_qgis.disconnect_signal_selection_changed()
        tools_gw.connect_signal_selection_changed(self.class_object, self.dialog, self.table_object, self.selection_mode)

        # Handle different geometry types
        if isinstance(geometry, QgsRectangle):
            # Rectangle selection
            selected_rectangle = None
            # Support multi-type selection when rel_feature_type == 'all'
            if getattr(self.class_object, 'rel_feature_type', None) == 'all':
                types_to_select = getattr(self.class_object, 'multi_enabled_types', None)
                if not types_to_select or len(types_to_select) <= 1:
                    types_to_select = [ft for ft, layers in self.class_object.rel_layers.items() if layers]
                layer_groups = []
                for ft in types_to_select:
                    layer_groups.extend(self.class_object.rel_layers.get(ft, []))
            else:
                layer_groups = self.class_object.rel_layers[self.class_object.rel_feature_type]

            # Block signals during selection to prevent premature processing
            for layer in layer_groups:
                layer.blockSignals(True)
            
            try:
                for layer in layer_groups:
                    if selected_rectangle is None:
                        selected_rectangle = self.canvas.mapSettings().mapToLayerCoordinates(layer, geometry)

                    if selection_behavior == GwSelectionBehavior.REMOVE:
                        layer.selectByRect(selected_rectangle, layer.RemoveFromSelection)
                    elif selection_behavior == GwSelectionBehavior.ADD:
                        layer.selectByRect(selected_rectangle, layer.AddToSelection)
                    else:  # GwSelectionBehavior.REPLACE or DEFAULT
                        layer.selectByRect(selected_rectangle, layer.SetSelection)
            finally:
                # Unblock signals after all layers are selected
                for layer in layer_groups:
                    if layer:
                        layer.blockSignals(False)
                # One signal is enough for the table. blockSignals also swallowed
                # repaintRequested, so every layer still has to be drawn.
                if layer_groups and layer_groups[0]:
                    layer_groups[0].selectionChanged.emit([], [], False)
                for layer in layer_groups:
                    if layer:
                        layer.triggerRepaint()
                self.canvas.refresh()
        elif isinstance(geometry, QgsPointXY) and event:
            # Point selection
            selection_success = self._perform_point_selection(event)
            self.vertex_marker.hide()
            if not selection_success:
                # If point selection failed, we might want to keep the tool active
                # for another attempt, depending on the failure reason
                self._check_keep_drawing()
                return
        elif geometry is None and event:
            # Legacy point selection (when called with rectangle=None)
            selection_success = self._perform_point_selection(event)
            self.vertex_marker.hide()
            if not selection_success:
                self._check_keep_drawing()
                return

        self.rubber_band.hide()
        self._check_keep_drawing()

    def _perform_geometry_selection(self, geometry):
        """Perform selection using geometry (for polygon, circle, freehand)"""
        # Check modifier keys
        ctrl_pressed = QApplication.keyboardModifiers() & Qt.KeyboardModifier.ControlModifier
        shift_pressed = QApplication.keyboardModifiers() & Qt.KeyboardModifier.ShiftModifier

        # Determine selection behavior:
        # Ctrl+Shift = Remove from selection
        # Ctrl only = Add to existing selection
        # No modifiers = Replace selection (clear previous and select new)
        if ctrl_pressed and shift_pressed:
            behavior = QgsVectorLayer.SelectBehavior.RemoveFromSelection
        elif ctrl_pressed and not shift_pressed:
            behavior = QgsVectorLayer.SelectBehavior.AddToSelection
        else:
            behavior = QgsVectorLayer.SelectBehavior.SetSelection

        tools_qgis.disconnect_signal_selection_changed()
        tools_gw.connect_signal_selection_changed(self.class_object, self.dialog, self.table_object, self.selection_mode)

        wkt = geometry.asWkt()

        # Support multi-type selection when rel_feature_type == 'all'
        if getattr(self.class_object, 'rel_feature_type', None) == 'all':
            types_to_select = getattr(self.class_object, 'multi_enabled_types', None)
            if not types_to_select or len(types_to_select) <= 1:
                types_to_select = [ft for ft, layers in self.class_object.rel_layers.items() if layers]
            layer_groups = []
            for ft in types_to_select:
                layer_groups.extend(self.class_object.rel_layers.get(ft, []))
        else:
            layer_groups = self.class_object.rel_layers[self.class_object.rel_feature_type]

        for layer in layer_groups:
            if not layer:
                continue
            layer.selectByExpression(f"intersects($geometry, geom_from_wkt('{wkt}'))", behavior)
            layer.triggerRepaint()
        self.canvas.refresh()

        self._check_keep_drawing()

    def _perform_point_selection(self, event: QEvent) -> bool:
        """
        Perform point-based selection on all relevant layers
        Args:
            event: The mouse event containing position information
            selection_behavior: The type of selection behavior to use
        Returns:
            bool: True if selection was successful, False otherwise
        """
        if not event:
            msg = "No event provided for point selection"
            tools_qgis.show_warning(msg, 2)
            return False

        try:
            event_point = self.snapper_manager.get_event_point(event)
            if event_point is None:
                msg = "Could not determine event point coordinates"
                tools_qgis.show_warning(msg, 2)
                return False

            result = self.snapper_manager.snap_to_project_config_layers(event_point)
            if not result.isValid():
                # No feature found at click location - not necessarily an error
                self.vertex_marker.hide()
                return False

            feature_id = self.snapper_manager.get_snapped_feature_id(result)
            if feature_id is None:
                msg = "Could not get feature ID from snapped point"
                tools_qgis.show_warning(msg, 2)
                return False

            # Get the snapped layer to verify it exists in our layer list
            snapped_layer = self.snapper_manager.get_snapped_layer(result)
            # Validate snapped layer against current selection scope (single or multi-type)
            if getattr(self.class_object, 'rel_feature_type', None) == 'all':
                types_to_select = getattr(self.class_object, 'multi_enabled_types', None)
                if not types_to_select or len(types_to_select) <= 1:
                    types_to_select = [ft for ft, layers in self.class_object.rel_layers.items() if layers]
                valid_layers = []
                for ft in types_to_select:
                    valid_layers.extend(self.class_object.rel_layers.get(ft, []))
                is_valid_layer = snapped_layer in valid_layers
            else:
                is_valid_layer = snapped_layer in self.class_object.rel_layers[self.class_object.rel_feature_type]

            if not is_valid_layer:
                msg = "Snapped feature is not in a valid layer"
                tools_qgis.show_warning(msg, 2)
                return False

            # Get and cache the feature
            feature = self._get_cached_feature(snapped_layer, feature_id)
            if not feature:
                msg = "Could not retrieve feature from layer"
                tools_qgis.show_warning(msg, 2)
                return False

            # Update vertex marker position
            point = self.snapper_manager.get_snapped_point(result)
            if point:
                self.vertex_marker.setCenter(point)
                self.vertex_marker.show()

            # Perform selection on all related layers
            selection_behavior = self._get_selection_behavior()
            
            # Convert behavior enum to QgsVectorLayer selection behavior
            if selection_behavior == GwSelectionBehavior.REMOVE:
                qgs_behavior = QgsVectorLayer.SelectBehavior.RemoveFromSelection
            elif selection_behavior == GwSelectionBehavior.ADD:
                qgs_behavior = QgsVectorLayer.SelectBehavior.AddToSelection
            else:  # GwSelectionBehavior.REPLACE or DEFAULT
                qgs_behavior = QgsVectorLayer.SelectBehavior.SetSelection
            
            wkt = QgsGeometry.fromPointXY(point).asWkt()
            # Apply selection in scope
            if getattr(self.class_object, 'rel_feature_type', None) == 'all':
                types_to_select = getattr(self.class_object, 'multi_enabled_types', None)
                if not types_to_select or len(types_to_select) <= 1:
                    types_to_select = [ft for ft, layers in self.class_object.rel_layers.items() if layers]
                layer_groups = []
                for ft in types_to_select:
                    layer_groups.extend(self.class_object.rel_layers.get(ft, []))
            else:
                layer_groups = self.class_object.rel_layers[self.class_object.rel_feature_type]

            for layer in layer_groups:
                layer.selectByExpression(f"intersects($geometry, geom_from_wkt('{wkt}'))", qgs_behavior)

            return True

        except Exception as e:
            msg = "Error during point selection: {0}"
            msg_params = (str(e), )
            tools_qgis.show_warning(msg, msg_params=msg_params)
            return False

    def _check_keep_drawing(self):
        """Check if we should keep the drawing tool active"""
        keep_drawing = tools_gw.get_config_parser('dialogs_actions', 'keep_drawing', "user", "init", prefix=False)
        keep_drawing = tools_os.set_boolean(keep_drawing, False)

        if keep_drawing:
            global_vars.canvas.setMapTool(GwSelectManager(
                self.class_object, self.table_object, self.dialog,
                self.selection_mode, self.save_rectangle, self.selection_type
            ))
            cursor = tools_gw.get_cursor_multiple_selection()
            global_vars.canvas.setCursor(cursor)

    # endregion