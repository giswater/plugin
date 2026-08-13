"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial

from qgis.PyQt.QtCore import QRect, Qt, QPoint
from qgis.PyQt.QtGui import QColor
from qgis.PyQt.QtWidgets import QApplication, QActionGroup, QWidget, QAction, QMenu
from qgis.core import QgsVectorLayer, QgsRectangle, QgsApplication, QgsFeatureRequest
from qgis.gui import QgsMapToolEmitPoint, QgsVertexMarker

from ....libs import lib_vars, tools_qgis, tools_qt, tools_db
from ...utils import tools_gw
from ...utils.snap_manager import GwSnapManager
from ...threads.connect_link import GwConnectLink
from ...ui.ui_manager import GwConnectLinkUi
from ..maptool import GwMaptool


class GwConnectLinkButton(GwMaptool):
    """ Button 27: Connect Link
    User select connections from layer 'connec'
    Execute SQL function: 'gw_fct_setlinktonetwork ' """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.dragging = False
        self.select_rect = QRect()
        self.project_type = tools_gw.get_project_type()

        # Initialize arc selection variables for map tools
        self.emit_point = None
        self.vertex_marker = None
        self.snapper_manager = None
        self.layer_arc = None

        # Initialize rubber bands
        self.rubber_band_line = tools_gw.create_rubberband(self.canvas)

        # Initialize user click marker (separate from snapping vertex_marker)
        self.user_click_marker = QgsVertexMarker(self.canvas)
        self.user_click_marker.setColor(QColor(255, 0, 0))
        self.user_click_marker.setIconSize(15)
        self.user_click_marker.setIconType(QgsVertexMarker.IconType.ICON_CROSS)
        self.user_click_marker.setPenWidth(3)

        # Check project type
        if self.project_type != 'ws':
            # Create a dropdown menu
            self.menu = QMenu()

            # Fill the menu
            self._fill_action_menu()

            # Add menu to toolbar
            if toolbar is not None and self.action is not None:
                self.action.setMenu(self.menu)
                toolbar.addAction(self.action)

    # region MAIN METHODS

    def clicked_event(self):
        """ Event when button is clicked """

        # If a last selection exists (persisted in config), open that dialog directly
        last_ft = tools_gw.get_config_parser('btn_connect_link', 'last_feature_type', "user", "session")
        if last_ft not in (None, 'None', ''):
            self.feature_type = str(last_ft)
            self.open_dlg()
            return

        # Otherwise pop the menu below the button (like utilities/element)
        try:
            if hasattr(self.action, 'associatedObjects'):
                button = QWidget(self.action.associatedObjects()[1])
            elif hasattr(self.action, 'associatedWidgets'):
                button = self.action.associatedWidgets()[1]
            menu_point = button.mapToGlobal(QPoint(0, button.height()))
            self.menu.popup(menu_point)
        except Exception:
            if self.project_type == 'ws':
                self.feature_type = 'connec'
                self.open_dlg()

    def open_dlg(self):
        """ Main function to open 'Connect to network' dialog """

        # Create form and body
        form = {"formName": "generic", "formType": f"link_to_{self.feature_type}"}
        body = {"client": {"cur_user": tools_db.current_user}, "form": form}

        # Execute procedure
        json_result = tools_gw.execute_procedure('gw_fct_get_dialog', body)

        # Create dialog
        self.dlg_connect_link = GwConnectLinkUi(self)
        tools_gw.load_settings(self.dlg_connect_link)
        tools_gw.manage_dlg_widgets(self, self.dlg_connect_link, json_result)

        # Get dynamic widgets
        self.txt_id = self.dlg_connect_link.findChild(QWidget, "tab_none_id")
        self.pipe_diameter = self.dlg_connect_link.findChild(QWidget, "tab_none_pipe_diameter")
        self.max_distance = self.dlg_connect_link.findChild(QWidget, "tab_none_max_distance")
        self.tbl_ids = self.dlg_connect_link.findChild(QWidget, "tab_none_tbl_ids")

        pipe_diameter_value = tools_gw.get_config_parser(f'btn_connect_link_to_{self.feature_type}', 'pipe_diameter', "user", "session")
        max_distance_value = tools_gw.get_config_parser(f'btn_connect_link_to_{self.feature_type}', 'max_distance', "user", "session")
        linkcat_id_value = tools_gw.get_config_parser(f'btn_connect_link_to_{self.feature_type}', 'linkcat_id', "user", "session")

        if pipe_diameter_value not in (None, 'None', ''):
            tools_qt.set_widget_text(self.dlg_connect_link, "tab_none_pipe_diameter", pipe_diameter_value)
        if max_distance_value not in (None, 'None', ''):
            tools_qt.set_widget_text(self.dlg_connect_link, "tab_none_max_distance", max_distance_value)
        if linkcat_id_value not in (None, 'None', ''):
            tools_qt.set_widget_text(self.dlg_connect_link, "tab_none_linkcat", linkcat_id_value)

        # Add headers to table
        tools_gw.add_tableview_header(self.tbl_ids, json_headers=[{'header': f'{self.feature_type}_id'}])

        # Connect cleanup signals when dialog is rejected (same pattern as psector)
        self.dlg_connect_link.rejected.connect(self._cleanup_and_close)
        self.dlg_connect_link.rejected.connect(lambda: close(**{'class': self, 'dialog': self.dlg_connect_link}))

        # Open dialog (gully overrides i18n title "Connect to network")
        if self.feature_type == 'gully':
            title = "Gully to network"
            tools_gw.open_dialog(self.dlg_connect_link, 'connect_link', title=title)
            title = "Gullies"
            gb = self.dlg_connect_link.findChild(QWidget, "groupBox_2")
            if gb:
                gb.setTitle(tools_qt.tr(title))
        else:
            tools_gw.open_dialog(self.dlg_connect_link, 'connect_link')

        # Setup "Set to arc" button dropdown menu immediately (same as psector)
        self._setup_set_to_arc_button()

        # Ensure arc field is read-only (database config may not work)
        self._make_arc_field_readonly()

    def _setup_set_to_arc_button(self):
        """ Setup set to arc button with dropdown menu (same as psector) """
        btn_set_to_arc = self.dlg_connect_link.findChild(QWidget, "tab_none_btn_set_to_arc")

        if not btn_set_to_arc:
            return

        # Initialize selected arcs list for multiple selection
        self.selected_arcs = []

        # Create dropdown menu (always available)
        values = [[0, "Set closest point (multiple)"], [1, "Set user click (single)"]]
        set_to_arc_menu = QMenu()
        for value in values:
            idx = value[0]
            label = value[1]
            action = set_to_arc_menu.addAction(f"{label}")
            action.triggered.connect(partial(self._set_to_arc, idx))

        btn_set_to_arc.setMenu(set_to_arc_menu)

        # When clicking the main button, run last selection if present; otherwise open the menu
        try:
            btn_set_to_arc.clicked.disconnect()
        except Exception:
            pass
        btn_set_to_arc.clicked.connect(partial(self._btn_set_to_arc_clicked, btn_set_to_arc))

        # Set initial button state
        self._update_set_to_arc_button_state()

    def _btn_set_to_arc_clicked(self, btn):
        # Always open the dropdown menu; do not reuse last selection
        try:
            if hasattr(btn, 'showMenu'):
                btn.showMenu()
        except Exception:
            pass

    def _make_arc_field_readonly(self):
        """ Make arc field read-only (fallback if database config doesn't work) """
        txt_arc_id = self.dlg_connect_link.findChild(QWidget, "tab_none_arc_id")
        if txt_arc_id and hasattr(txt_arc_id, 'setReadOnly'):
            txt_arc_id.setReadOnly(True)

    def _update_set_to_arc_button_state(self):
        """ Update "Set to arc" button enabled state based on connec table content """
        btn_set_to_arc = self.dlg_connect_link.findChild(QWidget, "tab_none_btn_set_to_arc")
        btn_expr_arc = self.dlg_connect_link.findChild(QWidget, "tab_none_btn_expr_arc")

        if hasattr(self, 'tbl_ids') and self.tbl_ids:
            model = self.tbl_ids.model()
            has_connecs = model and model.rowCount() > 0

            if btn_set_to_arc:
                btn_set_to_arc.setEnabled(has_connecs)
            if btn_expr_arc:
                btn_expr_arc.setEnabled(has_connecs)

    def _cleanup_and_close(self):
        """ Cleanup all visual elements when dialog is closed (same pattern as psector) """

        # Reset rubber bands (clear red highlighting)
        if hasattr(self, 'rubber_band_line') and self.rubber_band_line:
            tools_gw.reset_rubberband(self.rubber_band_line)

        # Clear vertex markers
        if hasattr(self, 'vertex_marker') and self.vertex_marker and hasattr(self.vertex_marker, 'hide'):
            self.vertex_marker.hide()

        # Clear user click marker
        if hasattr(self, 'user_click_marker') and self.user_click_marker:
            self.user_click_marker.hide()

        # Clear any user click point
        if hasattr(self, 'user_click_point'):
            self.user_click_point = None

        # Clear temp_table entries
        tools_db.execute_sql("DELETE FROM temp_table WHERE fid = 485 AND cur_user = current_user;")

        # Reset snapping if needed
        if (hasattr(self, 'snapper_manager') and self.snapper_manager and
            hasattr(self, 'emit_point') and self.emit_point and
            hasattr(self, 'vertex_marker')):
            tools_qgis.disconnect_snapping(True, self.emit_point, self.vertex_marker)

    def fill_tbl_ids(self, layer):
        """ Fill table with selected features """

        # Initialize field variable
        field = {"value": []}

        # Loop througth canvas selected features
        for connec_feature in layer.selectedFeatures():

            # Build object with feature selected
            selected_feature = {f"{self.feature_type}_id": connec_feature.attribute(f"{self.feature_type}_id")}

            # Add built object to the list
            field["value"].append(selected_feature)

        # Clear previous table rows
        self.tbl_ids.model().removeRows(0, self.tbl_ids.model().rowCount())

        # Fill table with selected features
        tools_gw.fill_tableview_rows(self.tbl_ids, field['value'])

        # Update "Set to arc" button state after adding connecs
        self._update_set_to_arc_button_state()

    def _fill_action_menu(self):
        """Fill the dropdown menu with actions (runtime memory of last selection)."""

        # Disconnect and remove previous actions
        for action in self.menu.actions():
            try:
                action.disconnect()
            except Exception:
                pass
            self.menu.removeAction(action)

        ag = QActionGroup(self.iface.mainWindow())
        entries = ((tools_qt.tr('Connec to network'), 'connec'),
                   (tools_qt.tr('Gully to network'), 'gully'))
        for label, feature_type in entries:
            act = QAction(label, ag)
            self.menu.addAction(act)
            act.triggered.connect(partial(self._open_connect_dialog, feature_type))
            act.triggered.connect(partial(self._save_last_main_selection, feature_type))

    def _save_last_main_selection(self, feature_type):
        # Persist last selected feature type using config (like select_manager)
        tools_gw.set_config_parser('btn_connect_link', 'last_feature_type', feature_type)

    def _open_connect_dialog(self, feature_type):
        self.feature_type = feature_type
        self.open_dlg()

    # endregion

    # region MAP TOOL EVENTS

    def activate(self):
        """ Activate map tool """

        # Rubber band
        tools_gw.reset_rubberband(self.rubber_band)

        # Initialize snapper manager if not already done
        if not hasattr(self, 'snapper_manager') or self.snapper_manager is None:
            self.snapper_manager = GwSnapManager(self.iface)

        # Store user snapping configuration
        self.previous_snapping = self.snapper_manager.get_snapping_options()

        # Change cursor
        cursor = tools_gw.get_cursor_multiple_selection()
        self.canvas.setCursor(cursor)

        # Show help message when action is activated
        if self.show_help:
            msg = ("Select connecs or gullies with qgis tool and use right click to connect them with network. "
                      "CTRL + SHIFT over selection to remove it")
            tools_qgis.show_info(msg, duration=9)

    def canvasMoveEvent(self, event):
        """ With left click the digitizing is finished """

        if event.buttons() == Qt.MouseButton.LeftButton:

            if not self.dragging:
                self.dragging = True
                self.select_rect.setTopLeft(event.pos())

            self.select_rect.setBottomRight(event.pos())
            self._set_rubber_band()

    def canvasPressEvent(self, event):

        self.select_rect.setRect(0, 0, 0, 0)
        tools_gw.reset_rubberband(self.rubber_band, "polygon")

    def canvasReleaseEvent(self, event):
        """ With left click the digitizing is finished """

        # Manage if task is already running
        if hasattr(self, 'connect_link_task') and self.connect_link_task is not None:
            try:
                if self.connect_link_task.isActive():
                    msg = "Connect link task is already active!"
                    tools_qgis.show_warning(msg)
                    return
            except RuntimeError:
                pass

        if event.button() == Qt.MouseButton.LeftButton:

            # Set valid values for rectangle's width and height
            if self.select_rect.width() == 1:
                self.select_rect.setLeft(self.select_rect.left() + 1)

            if self.select_rect.height() == 1:
                self.select_rect.setBottom(self.select_rect.bottom() + 1)

            self._set_rubber_band()
            self._select_multiple_features(self.selected_rectangle)
            self.dragging = False

            # Refresh map canvas
            tools_gw.reset_rubberband(self.rubber_band)

            # Force reload dataProvider of layer
            tools_qgis.set_layer_index('ve_link')
            tools_qgis.set_layer_index('ve_vnode')

    def manage_result(self, result):

        if result and result['status'] != 'Failed':
            tools_gw.fill_tab_log(self.dlg_connect_link, result['body']['data'])
        else:
            tools_gw.manage_json_exception(result)

        # Recover dialog values
        self._save_dlg_values()

        # Remove selection from layers
        tools_gw.remove_selection()

        # Refresh map canvas
        tools_gw.reset_rubberband(self.rubber_band)
        self.refresh_map_canvas()
        self.iface.actionPan().trigger()

        # Force reload dataProvider of layer
        tools_qgis.set_layer_index('ve_link')
        tools_qgis.set_layer_index('ve_vnode')

    # endregion

    # region private functions

    def _set_rubber_band(self):

        # Coordinates transform
        transform = self.canvas.getCoordinateTransform()

        # Coordinates
        ll = transform.toMapCoordinates(self.select_rect.left(), self.select_rect.bottom())
        lr = transform.toMapCoordinates(self.select_rect.right(), self.select_rect.bottom())
        ul = transform.toMapCoordinates(self.select_rect.left(), self.select_rect.top())
        ur = transform.toMapCoordinates(self.select_rect.right(), self.select_rect.top())

        # Rubber band
        tools_gw.reset_rubberband(self.rubber_band, "polygon")
        self.rubber_band.addPoint(ll, False)
        self.rubber_band.addPoint(lr, False)
        self.rubber_band.addPoint(ur, False)
        self.rubber_band.addPoint(ul, False)
        self.rubber_band.addPoint(ll, True)

        self.selected_rectangle = QgsRectangle(ll, ur)

    def _select_multiple_features(self, select_geometry):
        """ Select multiple features on canvas """

        # TODO: Create button add_forced_arcs and manage selection with arcs

        # Get pressed keys on keyboard
        key = QApplication.keyboardModifiers()

        # Set behaviour depending of the pressed keys on keyboard
        behaviour = QgsVectorLayer.SelectBehavior.RemoveFromSelection if key == (Qt.KeyboardModifier.ControlModifier | Qt.KeyboardModifier.ShiftModifier) else QgsVectorLayer.SelectBehavior.AddToSelection

        # Get current feature layer (connec/gully)
        layer = tools_qgis.get_layer_by_tablename(f've_{self.feature_type}')

        # Check if layer exists
        if layer:

            # Select/Unselect features of the selected geometry
            layer.selectByRect(select_geometry, behaviour)

            # Refresh table
            self.fill_tbl_ids(layer)

    def _selection_init(self):
        """ Initialize selection mode """

        self.iface.actionSelect().trigger()

    def _selection_end(self):
        """ Process selected features """

        # Get current feature layer (connec/gully)
        layer = tools_qgis.get_layer_by_tablename(f've_{self.feature_type}')

        # Refresh table
        self.fill_tbl_ids(layer)
        self.iface.actionPan().trigger()

    def _selection_end_arc(self):
        """ Process selected arc features """
        layer = self.iface.activeLayer()
        if not layer:
            return

        selected_features = layer.selectedFeatures()
        if not selected_features:
            return

        # Extract arc IDs from selected features
        selected_arc_ids = [str(feature.attribute('arc_id')) for feature in selected_features]

        # Update arc line edit field directly (same as mapzone forceClosed)
        txt_arc_id = self.dlg_connect_link.findChild(QWidget, "tab_none_arc_id")
        if txt_arc_id and hasattr(txt_arc_id, 'setText'):
            arc_text = ', '.join(selected_arc_ids)
            txt_arc_id.setText(arc_text)

        # Clean up
        self.iface.actionPan().trigger()

    def _highlight_all_selected_arcs(self):
        """ Highlight all selected arcs in red """
        # Always reset existing rubber band first
        tools_gw.reset_rubberband(self.rubber_band_line)

        # If no arcs selected, just clear and return
        if not hasattr(self, 'selected_arcs') or not self.selected_arcs:
            return

        # Get arc layer and highlight all selected arcs
        layer = tools_qgis.get_layer_by_tablename('ve_arc')
        if layer:
            for arc_id in self.selected_arcs:
                feature = tools_qt.get_feature_by_id(layer, arc_id, 'arc_id')
                if feature:
                    try:
                        geometry = feature.geometry()
                        self.rubber_band_line.addGeometry(geometry, None)
                    except AttributeError:
                        pass

        # Set styling and show
        self.rubber_band_line.setColor(QColor(255, 0, 0, 100))
        self.rubber_band_line.setWidth(5)
        self.rubber_band_line.show()

    def _save_dlg_values(self):
        """ Save dialog values """

        pipe_diameter_value = self.pipe_diameter.text()
        max_distance_value = self.max_distance.text()
        linkcat_id_value = tools_qt.get_combo_value(self.dlg_connect_link, "tab_none_linkcat")

        tools_gw.set_config_parser(f'btn_connect_link_to_{self.feature_type}', 'pipe_diameter', pipe_diameter_value)
        tools_gw.set_config_parser(f'btn_connect_link_to_{self.feature_type}', 'max_distance', max_distance_value)
        tools_gw.set_config_parser(f'btn_connect_link_to_{self.feature_type}', 'linkcat_id', linkcat_id_value)

    def _set_to_arc(self, idx):
        """ Handle 'Set to arc' button clicks - allows user to set exact connection point on arc """

        if hasattr(self, 'emit_point') and self.emit_point is not None:
            tools_gw.disconnect_signal('connect_link', 'set_to_arc_ep_canvasClicked_set_arc_id')
            tools_gw.disconnect_signal('connect_link', 'set_to_arc_xyCoordinates_mouse_move_arc')

        self.emit_point = QgsMapToolEmitPoint(self.canvas)
        self.canvas.setMapTool(self.emit_point)
        self.snapper_manager = GwSnapManager(self.iface)
        self.snapper = self.snapper_manager.get_snapper()
        self.layer_arc = tools_qgis.get_layer_by_tablename("ve_arc")

        # Vertex marker
        self.vertex_marker = self.snapper_manager.vertex_marker

        # Store user snapping configuration
        self.previous_snapping = self.snapper_manager.get_snapping_options()

        # Show instruction message for multiple selection mode
        if idx == 0:  # "Set closest point (multiple)"
            message = "Click on arcs to select them. Use Alt+click to unselect selected arcs."
            title = "Connect to network"
            tools_qgis.show_info(message, title=title)

        # Set signals
        tools_gw.connect_signal(self.canvas.xyCoordinates, self._mouse_move_arc, 'connect_link',
                                'set_to_arc_xyCoordinates_mouse_move_arc')
        tools_gw.connect_signal(self.emit_point.canvasClicked, partial(self._set_arc_id, idx),
                                'connect_link', 'set_to_arc_ep_canvasClicked_set_arc_id')

    # endregion

    # region ARC SELECTION METHODS

    def _mouse_move_arc(self, point):
        """ Mouse move event for arc snapping (same as psector) """
        if not self.layer_arc or not self.snapper_manager:
            return

        # Set active layer
        self.iface.setActiveLayer(self.layer_arc)

        # Get clicked point and add marker
        if self.vertex_marker:
            self.vertex_marker.hide()
        event_point = self.snapper_manager.get_event_point(point=point)
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if result.isValid():
            self.snapper_manager.add_marker(result, self.vertex_marker)

    def _set_arc_id(self, idx, point, event):
        """ Set arc id from map click (same as psector) """

        # Manage right click
        if event == 2:
            tools_qgis.disconnect_snapping(True, self.emit_point, self.vertex_marker)
            tools_qgis.disconnect_signal_selection_changed()
            return

        # Get the point
        event_point = self.snapper_manager.get_event_point(point=point)
        self.arc_id = None

        # Snap point
        result = self.snapper_manager.snap_to_current_layer(event_point)

        if result.isValid():
            # Check feature
            layer = self.snapper_manager.get_snapped_layer(result)
            if layer == self.layer_arc:
                # Get the point
                snapped_feat = self.snapper_manager.get_snapped_feature(result)
                self.arc_id = snapped_feat.attribute('arc_id')

                # Set highlight like in psector (without zoom)
                feature = tools_qt.get_feature_by_id(layer, self.arc_id, 'arc_id')
                try:
                    geometry = feature.geometry()
                    if hasattr(self, 'rubber_band_line'):
                        # Reset first, then add geometry (avoids zoom that setToGeometry causes)
                        tools_gw.reset_rubberband(self.rubber_band_line)
                        self.rubber_band_line.addGeometry(geometry, None)
                        self.rubber_band_line.setColor(QColor(255, 0, 0, 100))
                        self.rubber_band_line.setWidth(5)
                        self.rubber_band_line.show()
                except AttributeError:
                    pass

        if self.arc_id is None:
            return

        # Handle clicked point based on mode
        if idx == 0:  # "Set closest point (multiple)"
            # Clear any previous user click point to ensure closest point behavior
            self.user_click_point = None

            # Check for Alt+click to unselect
            alt_pressed = QApplication.keyboardModifiers() & Qt.KeyboardModifier.AltModifier

            if alt_pressed:
                # Alt+click only works on already selected arcs
                if self.arc_id in self.selected_arcs:
                    # Alt+click on selected arc - remove it
                    self.selected_arcs.remove(self.arc_id)
                else:
                    # Alt+click on unselected arc - do nothing
                    return
            elif self.arc_id not in self.selected_arcs:
                # Normal click on unselected arc - add it
                self.selected_arcs.append(self.arc_id)
            else:
                # Normal click on already selected arc - do nothing
                return

            # Update display with all selected arcs
            txt_arc_id = self.dlg_connect_link.findChild(QWidget, "tab_none_arc_id")
            if txt_arc_id and hasattr(txt_arc_id, 'setText'):
                if self.selected_arcs:
                    arc_text = ', '.join(map(str, self.selected_arcs))
                    txt_arc_id.setText(arc_text)
                else:
                    txt_arc_id.setText('')

            # Highlight all selected arcs
            self._highlight_all_selected_arcs()

            return  # Stay in selection mode

        elif idx == 1:  # "Set user click (single)"
            # Clear multiple selection for single mode
            self.selected_arcs = [self.arc_id]

            # Get the snapped point (where connection will actually be made)
            snapped_point = self.snapper_manager.get_snapped_point(result)

            # Store the snapped point in class variable for later use in accept()
            self.user_click_point = snapped_point

            # Add a cross marker at the snapped point (same location as pink vertex marker)
            if hasattr(self, 'user_click_marker') and self.user_click_marker:
                self.user_click_marker.setCenter(snapped_point)
                self.user_click_marker.show()

            # Set single arc id in field
            txt_arc_id = self.dlg_connect_link.findChild(QWidget, "tab_none_arc_id")
            if txt_arc_id and hasattr(txt_arc_id, 'setText'):
                txt_arc_id.setText(str(self.arc_id))

        # Disconnect and restore snapping (only for single mode, without panning)
        tools_gw.disconnect_signal('connect_link', 'set_to_arc_ep_canvasClicked_set_arc_id')
        tools_gw.disconnect_signal('connect_link', 'set_to_arc_xyCoordinates_mouse_move_arc')
        tools_qgis.disconnect_snapping(False, self.emit_point, self.vertex_marker)

    # endregion


def add(**kwargs):
    """ Add button clicked event """

    # Get class
    this = kwargs['class']

    # Get selected id
    selected_id = tools_qt.get_combo_value(this.dlg_connect_link, "tab_none_id")

    # Check if selected id is not empty
    if selected_id is None or selected_id == '':
        message = "Please select a feature to add"
        title = "Connect to network"
        tools_qgis.show_warning(message, title=title)
        return

    # Create expression filter
    expr_filter = f"{this.feature_type}_id = '{selected_id}'"
    is_valid, expr = tools_qt.check_expression_filter(expr_filter)

    # Get layer from feature
    layer = tools_qgis.get_layer_by_tablename(f've_{this.feature_type}')

    # Check if layer exists and expression is valid
    if layer and is_valid:

        # Get all selected features in canvas + the new current selected feature
        features = layer.selectedFeatures() + list(layer.getFeatures(QgsFeatureRequest(expr)))
        id_list = [feature.id() for feature in features]

        # Show selected ids in canvas
        layer.selectByIds(id_list)

    # Refresh table
    this.fill_tbl_ids(layer)


def remove(**kwargs):
    """ Remove button clicked event - Remove selected rows from table """

    # Get class
    this = kwargs['class']

    try:
        # Get the table model and selection model
        model = this.tbl_ids.model()
        selection_model = this.tbl_ids.selectionModel()

        if not model or not selection_model:
            return

        # Get selected rows
        selected_rows = selection_model.selectedRows()

        if not selected_rows:
            message = "Please select rows to remove from the table"
            title = "Connect to network"
            tools_qgis.show_warning(message, title=title)
            return

        # Get IDs from selected rows
        selected_ids = []
        for index in selected_rows:
            item = model.item(index.row(), 0)  # Get the first column
            if item and item.text():
                selected_ids.append(item.text())

        if not selected_ids:
            return

        # Remove selected rows from the model
        # We need to remove rows in reverse order to avoid index issues
        rows_to_remove = sorted([index.row() for index in selected_rows], reverse=True)
        for row in rows_to_remove:
            model.removeRow(row)

        # Clear any selection in the combo box
        tools_qt.set_widget_text(this.dlg_connect_link, "tab_none_id", "")

        # Update "Set to arc" button state after removing connecs
        this._update_set_to_arc_button_state()

        # Update canvas selection to show only remaining items in the table
        layer = tools_qgis.get_layer_by_tablename(f've_{this.feature_type}')
        if layer:
            # Get remaining IDs from the table
            remaining_ids = []
            for row in range(model.rowCount()):
                item = model.item(row, 0)
                if item and item.text():
                    remaining_ids.append(int(item.text()))

            # Clear current selection and select only remaining features
            layer.removeSelection()
            if remaining_ids:
                # Create expression to select remaining features
                expr_filter = f"{this.feature_type}_id IN ({','.join(map(str, remaining_ids))})"
                is_valid, expr = tools_qt.check_expression_filter(expr_filter)
                if is_valid:
                    layer.selectByExpression(expr_filter)  # Use expr_filter (string) instead of expr (QgsExpression)

            # Refresh the layer to show updated selection
            layer.triggerRepaint()

        # Show success message
        removed_count = len(selected_ids)
        msg = "{0} item(s) removed from the list: {1}"
        msg_params = (removed_count, ", ".join(selected_ids))
        tools_qgis.show_info(msg, msg_params=msg_params)

    except Exception as e:
        msg = "Error removing items: {0}"
        msg_params = (e,)
        tools_qgis.show_warning(msg, msg_params=msg_params)
        msg = "Error in remove function: {0}"
        msg_params = (e,)
        tools_gw.log_info(msg, msg_params=msg_params)


def accept(**kwargs):
    """ Accept button clicked event """

    # Get class
    this = kwargs['class']

    # Clear any previous temp_table entries for fid 485 (user click points)
    sql_clear = "DELETE FROM temp_table WHERE fid = 485;"
    tools_db.execute_sql(sql_clear)

    # Get selected linkcat
    this.linkcat = tools_qt.get_combo_value(this.dlg_connect_link, "tab_none_linkcat")

    # Check input values
    if this.linkcat == '':
        message = "Please fill link catalog field in the dialog"
        title = "Connect to network"
        tools_qgis.show_warning(message, title=title, dialog=this.dlg_connect_link)
        return

    # Get arc layer
    layer_arc = tools_qgis.get_layer_by_tablename('ve_arc')

    # Get selected arcs from the class variable or field
    selected_arcs = []

    # First, check if we have multiple arcs selected via "Set closest point (multiple)"
    if hasattr(this, 'selected_arcs') and this.selected_arcs:
        selected_arcs = this.selected_arcs
    else:
        # Fallback: try to get arc from the arc selection field
        txt_arc_id = this.dlg_connect_link.findChild(QWidget, "tab_none_arc_id")
        arc_id_from_field = txt_arc_id.text() if txt_arc_id and hasattr(txt_arc_id, 'text') else None

        if arc_id_from_field:
            # Handle comma-separated arc IDs
            arc_ids = [arc.strip() for arc in arc_id_from_field.split(',') if arc.strip()]
            selected_arcs = arc_ids
        else:
            # Final fallback: check if there are arcs selected on the map
            if layer_arc and layer_arc.selectedFeatureCount() > 0:
                selected_arc_feature = layer_arc.selectedFeatures()[0]  # Use the first selected arc
                selected_arcs = [str(selected_arc_feature.attribute("arc_id"))]

    # Initialize an empty list
    this.ids = []
    model = this.tbl_ids.model()

    # Check if table is empty
    if model.rowCount() == 0:
        message = "Please select a feature to add"
        title = "Connect to network"
        tools_qgis.show_warning(message, title=title, dialog=this.dlg_connect_link)
        return

    # Loop throught table rows
    for row in range(model.rowCount()):
        item = model.item(row, 0)  # Get the row and the first column (0)
        if item is not None:
            this.ids.append(int(item.text()))

    # Insert temp_table point if user click was used
    if hasattr(this, 'user_click_point') and this.user_click_point:
        point = this.user_click_point
        the_geom = f"ST_GeomFromText('POINT({point.x()} {point.y()})', {lib_vars.data_epsg})"
        sql_insert = f"INSERT INTO temp_table (fid, geom_point, cur_user) VALUES (485, {the_geom}, current_user);"
        tools_db.execute_sql(sql_insert)

    # Create connect link task
    title = "Connect link"
    this.connect_link_task = GwConnectLink(tools_qt.tr(title), this, this.feature_type, selected_arcs=selected_arcs)

    # Add and trigger the task
    QgsApplication.taskManager().addTask(this.connect_link_task)
    QgsApplication.taskManager().triggerTask(this.connect_link_task)

    # Remove selection from layers before canceling map tool
    tools_gw.remove_selection()

    # Cancel map tool if no features are selected or the layer is not visible
    this.cancel_map_tool()


def snapping(**kwargs):
    """ Accept button clicked event """

    GwMaptool.clicked_event(kwargs['class'])


def close(**kwargs):
    """ Close button clicked event """

    # Get class
    this = kwargs['class']

    # Remove selection from layers before canceling map tool
    tools_gw.remove_selection()

    # Cancel map tool
    this.cancel_map_tool()

    # Close dialog
    tools_gw.close_dialog(kwargs['dialog'])


def filter_expression(**kwargs):
    """Select features by expression for connec table"""

    # Get class
    this = kwargs['class']

    # Get current layer and feature type
    layer_name = f've_{this.feature_type}'

    layer = tools_qgis.get_layer_by_tablename(layer_name)
    if not layer:
        return

    # Set active layer
    this.iface.setActiveLayer(layer)
    tools_qgis.set_layer_visible(layer)

    # Show expression dialog
    tools_gw.select_with_expression_dialog_custom(
        this,
        this.dlg_connect_link,
        None,  # No table object needed for expression selection
        layer_name,
        this._selection_init,
        this._selection_end
    )


def filter_expression_arc(**kwargs):
    """Select arc features by expression for arc field"""

    # Get class
    this = kwargs['class']

    # Get arc layer
    layer_name = 've_arc'
    layer = tools_qgis.get_layer_by_tablename(layer_name)
    if not layer:
        return

    # Set active layer
    this.iface.setActiveLayer(layer)
    tools_qgis.set_layer_visible(layer)

    # Temporarily change feature_type to 'arc' for correct dialog title and layer
    original_feature_type = this.feature_type
    this.feature_type = 'arc'

    # Show expression dialog for arc field
    tools_gw.select_with_expression_dialog_custom(
        this,
        this.dlg_connect_link,
        None,  # No table object needed for arc field
        layer_name,
        this._selection_init,
        this._selection_end_arc
    )

    # Restore original feature_type
    this.feature_type = original_feature_type
