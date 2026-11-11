"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial

from qgis.PyQt.QtCore import Qt
from qgis.PyQt.QtWidgets import QMenu, QAction, QActionGroup
from qgis.core import QgsMapToPixel
from qgis.gui import QgsVertexMarker

from ..maptool import GwMaptool
from ...ui.ui_manager import GwDialogShowInfoUi, GwPsectorUi
from ...utils import tools_audit, tools_gw
from ....libs import lib_vars, tools_qt, tools_qgis, tools_db, tools_os


class GwArcDivideButton(GwMaptool):
    """ Button 23: Divide arc
    Execute SQL function: 'gw_fct_node2arc' """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        super().__init__(icon_path, action_name, text, toolbar, action_group)

       # Create a menu and add all the actions
        if toolbar is not None:
            toolbar.removeAction(self.action)

        # selected_action = 1: DRAG-DROP
        # selected_action = 2: SELECT
        self.selected_action = 1
        self.menu = QMenu()
        self.menu.setObjectName("GW_replace_menu")
        self._fill_action_menu()

        if toolbar is not None:
            self.action.setMenu(self.menu)
            toolbar.addAction(self.action)

        value = tools_gw.get_config_parser('user_edit_tricks', 'keep_maptool_active', "user", "init",
                                           prefix=True)
        self.keep_maptool_active = tools_os.set_boolean(value, False)

    # region QgsMapTools inherited
    """ QgsMapTool inherited event functions """

    def activate(self):
        """ Called when set as currently active map tool """

        tools_audit.trace('arc_divide')
        # Check action. It works if is selected from toolbar. Not working if is selected from menu or shortcut keys
        if hasattr(self.action, "setChecked"):
            self.action.setChecked(True)
        else:
            self.selected_action = tools_gw.get_config_parser("btn_arc_divide", "last_action", "user", "session")

        # Store user snapping configuration
        self.previous_snapping = self.snapper_manager.get_snapping_options()

        # Get active layer
        self.active_layer = self.iface.activeLayer()

        # Set active layer to 've_node'
        self.layer_node = tools_qgis.get_layer_by_tablename("ve_node")
        self.iface.setActiveLayer(self.layer_node)

        # Get layer to 've_arc'
        self.layer_arc = tools_qgis.get_layer_by_tablename("ve_arc")

        # Set the mapTool's parent cursor
        self.canvas.setCursor(self.cursor)

        # Reset
        self.reset()

        self.vertex_marker.setIconType(QgsVertexMarker.IconType.ICON_CIRCLE)

        # Show help message when action is activated
        if self.show_help:
            msg = "Click on disconnected node, move the pointer to the desired location on pipe to break it"
            tools_qgis.show_info(msg)

    def deactivate(self):
        """ Called when map tool is being deactivated """

        super().deactivate()

        self.layer_arc.removeSelection()

        # Restore previous active layer
        try:
            if self.active_layer:
                self.iface.setActiveLayer(self.active_layer)
        except RuntimeError:
            pass

        self.refresh_map_canvas()

        self.reset()

    def canvasMoveEvent(self, event):
        """ Mouse movement event """

        self._move_event(event)

    def canvasReleaseEvent(self, event):

        self._release_event(event)

    # endregion

    # region private functions

    def _fill_action_menu(self):
        """ Fill action menu """

        # disconnect and remove previuos signals and actions
        actions = self.menu.actions()
        for action in actions:
            action.disconnect()
            self.menu.removeAction(action)
            del action
        ag = QActionGroup(self.iface.mainWindow())

        actions = [tools_qt.tr('DRAG-DROP'), tools_qt.tr('SELECT')]
        for action in actions:
            obj_action = QAction(f"{action}", ag)
            self.menu.addAction(obj_action)
            obj_action.triggered.connect(partial(super().clicked_event))
            obj_action.triggered.connect(partial(self._get_selected_action, action))

    def _get_selected_action(self, name):
        """ Gets selected action """

        if name == tools_qt.tr('DRAG-DROP'):
            self.selected_action = 1
        else:
            self.selected_action = 2

        tools_gw.set_config_parser("btn_arc_divide", "last_action", self.selected_action, "user", "session")

    def _move_event(self, event):

        # Hide marker and get coordinates
        self.vertex_marker.hide()
        x = event.pos().x()
        y = event.pos().y()
        event_point = self.snapper_manager.get_event_point(event)

        # First step: Any node selected -> Snap to node
        if self.snapped_feat is None:
            self._move_event_snap_to_node(event_point, x, y)

        # Second step: After a node is selected -> Snap to arc (only action "DRAG-DROP")
        else:
            if self.selected_action == 1:
                self._move_event_snap_to_arc(event_point, x, y)

    def _move_event_snap_to_node(self, event_point, x, y):
        """ Snap to node. First step: Any node selected """

        # Make sure active layer is 've_node'
        cur_layer = self.iface.activeLayer()
        if cur_layer != self.layer_node:
            self.iface.setActiveLayer(self.layer_node)

        # Snapping
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if result.isValid():
            # Get the point and add marker on it
            point = self.snapper_manager.add_marker(result, self.vertex_marker)
        else:
            point = QgsMapToPixel.toMapCoordinates(self.canvas.getCoordinateTransform(), x, y)

        # Set a new point to go on with
        if self.selected_action == 1:
            self.rubber_band.movePoint(point)

    def _move_event_snap_to_arc(self, event_point, x, y):
        """ Snap to arc. Second step: After a node is selected """

        # Make sure active layer is 've_arc'
        cur_layer = self.iface.activeLayer()
        if cur_layer != self.layer_arc:
            self.iface.setActiveLayer(self.layer_arc)

        # Snapping
        result = self.snapper_manager.snap_to_current_layer(event_point)

        # if result and result[0].snappedVertexNr == -1:
        if result.isValid():
            layer = self.snapper_manager.get_snapped_layer(result)
            feature_id = self.snapper_manager.get_snapped_feature_id(result)
            point = self.snapper_manager.add_marker(result, self.vertex_marker, QgsVertexMarker.IconType.ICON_CROSS)
            # Select the arc
            layer.removeSelection()
            layer.select([feature_id])
        else:
            # Bring the rubberband to the cursor i.e. the clicked point
            point = QgsMapToPixel.toMapCoordinates(self.canvas.getCoordinateTransform(), x, y)

        self.rubber_band.movePoint(point)

    def _move_node(self, node_id, point):
        """ Move selected node to the current point """

        # Update node geometry
        the_geom = f"ST_GeomFromText('POINT({point.x()} {point.y()})', {lib_vars.data_epsg})"
        sql = (f"UPDATE node SET the_geom = {the_geom} "
               f"WHERE node_id = '{node_id}'")
        status = tools_db.execute_sql(sql, log_sql=True)

        if status:
            feature_id = f'"id":["{node_id}"]'
            body = tools_gw.create_body(feature=feature_id)
            result = tools_gw.execute_procedure('gw_fct_setarcdivide', body)
            if result and result['status'] == 'Accepted':
                log = tools_gw.get_config_parser("user_edit_tricks", "arc_divide_disable_showlog", 'user', 'init')
                if not tools_os.set_boolean(log, False):
                    self.dlg_info = GwDialogShowInfoUi(self, 'arc_divide')
                    tools_gw.load_settings(self.dlg_info)
                    tools_gw.fill_tab_log(self.dlg_info, result['body']['data'], False, True, 1)
                    self.dlg_info.finished.connect(partial(tools_gw.save_settings, self.dlg_info))
                    tools_gw.open_dialog(self.dlg_info, dlg_name='arc_divide')
        else:
            msg = "Move node: Error updating geometry"
            tools_qgis.show_warning(msg)

        # Check in init config file if user wants to keep map tool active or not
        self.cancel_map_tool()
        if self.keep_maptool_active:
            self.clicked_event()

    def _release_event(self, event):

        if event.button() == Qt.MouseButton.RightButton:
            self.cancel_map_tool()
            return

        event_point = self.snapper_manager.get_event_point(event)

        # Snap to node
        if self.snapped_feat is None:
            self._release_event_snap_to_node(event_point)
            if int(self.selected_action) == 2:
                is_valid, answer = self._release_event_snap_to_arc(event_point)
                if not is_valid:
                    msg = "Current node is not located over an arc. Please, select option 'DRAG-DROP'"
                    tools_qgis.show_info(msg)
                    self.cancel_map_tool()
                    if self.keep_maptool_active:
                        self.clicked_event()
                    return
                if not answer:
                    self.cancel_map_tool()
                    if self.keep_maptool_active:
                        self.clicked_event()

        # Snap to arc
        else:
            if self.selected_action == 1:
                self._release_event_snap_to_arc(event_point)

    def _release_event_snap_to_node(self, event_point):

        result = self.snapper_manager.snap_to_current_layer(event_point)
        if not result.isValid():
            return

        self.snapped_feat = self.snapper_manager.get_snapped_feature(result)
        point = self.snapper_manager.get_snapped_point(result)

        # Hide marker
        self.vertex_marker.hide()

        # Set a new point to go on with
        self.rubber_band.addPoint(point)

        # Add arc snapping
        self.iface.setActiveLayer(self.layer_arc)

    def _release_event_snap_to_arc(self, event_point):

        result = self.snapper_manager.snap_to_current_layer(event_point)
        if not result.isValid():
            return False, False

        layer = self.snapper_manager.get_snapped_layer(result)
        point = self.snapper_manager.get_snapped_point(result)
        point = self.toLayerCoordinates(layer, point)

        # Get selected feature (at this moment it will have one and only one)
        node_id = self.snapped_feat.attribute('node_id')

        # Move selected node to the released point
        answer = True
        ask = tools_gw.get_config_parser("user_edit_tricks", "arc_divide_disable_prev_warning", 'user', 'init')
        if not tools_os.set_boolean(ask, False):
            # Show message before executing
            msg = ("The procedure will delete features on database unless it is a node that doesn't divide arcs.\n"
                       "Please ensure that features has no undelete value on true.\n"
                       "On the other hand you must know that traceability table will storage precedent information.")
            title = "Info"
            answer = tools_qt.show_question(msg, title)
        if answer:
            self._move_node(node_id, point)
            tools_qgis.set_layer_index('ve_arc')
            tools_qgis.set_layer_index('ve_connec')
            tools_qgis.set_layer_index('ve_gully')
            tools_qgis.set_layer_index('ve_node')
            self.iface.mapCanvas().refresh()

            # Refresh psector's relations tables
            tools_gw.execute_class_function(GwPsectorUi, '_refresh_tables_relations')

        return True, answer

    # endregion