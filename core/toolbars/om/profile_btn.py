"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial

from qgis.PyQt.QtCore import QDate, QTimer
from qgis.PyQt.QtGui import QDoubleValidator
from qgis.PyQt.QtWidgets import QListWidgetItem, QLineEdit, QAction
from qgis.core import QgsFeatureRequest, QgsVectorLayer, QgsExpression, Qgis
from qgis.gui import QgsMapToolEmitPoint

from ..dialog import GwAction
from ...ui.ui_manager import GwProfileUi, GwProfilesListUi
from ...utils import tools_gw
from ...utils.snap_manager import GwSnapManager
from ....libs import lib_vars, tools_qgis, tools_qt
from ...shared.profile import GwProfile


class GwProfileButton(GwAction):
    """ Button 15: Profile """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        # Call ParentDialog constructor
        super().__init__(icon_path, action_name, text, toolbar, action_group)

        self.snapper_manager = GwSnapManager(self.iface)
        self.vertex_marker = self.snapper_manager.vertex_marker
        self.list_of_selected_nodes = []
        self.none_values = []
        self.add_points = False
        self.add_points_list = []
        self.profile = GwProfile()

    def clicked_event(self):

        self.action.setChecked(True)

        # Remove all selections on canvas
        self._remove_selection()

        # Set dialog
        self.dlg_draw_profile = GwProfileUi(self)
        tools_gw.load_settings(self.dlg_draw_profile)

        # Declare composer path widget
        self.composers_path = self.dlg_draw_profile.findChild(QLineEdit, "composers_path")

        # Set layers used for snapping
        self.layer_node = tools_qgis.get_layer_by_tablename('ve_node', show_warning_=False)
        self.layer_arc = tools_qgis.get_layer_by_tablename('ve_arc', show_warning_=False)

        # Toolbar actions
        action = self.dlg_draw_profile.findChild(QAction, "actionProfile")
        tools_gw.add_icon(action, "131")
        action.triggered.connect(partial(self._activate_add_points, False))
        action.triggered.connect(partial(self._activate_snapping_node))
        self.action_profile = action

        action = self.dlg_draw_profile.findChild(QAction, "actionAddPoint")
        tools_gw.add_icon(action, "111")
        action.triggered.connect(partial(self._activate_add_points, True))
        action.triggered.connect(partial(self._activate_snapping_node))
        self.action_add_point = action
        self.action_add_point.setDisabled(True)

        # Set validators
        self.dlg_draw_profile.txt_min_distance.setValidator(QDoubleValidator())

        # Triggers
        self.dlg_draw_profile.btn_draw_profile.clicked.connect(partial(self._get_profile))
        self.dlg_draw_profile.btn_save_profile.clicked.connect(self._save_profile)
        self.dlg_draw_profile.btn_load_profile.clicked.connect(self._open_profile)
        self.dlg_draw_profile.btn_clear_profile.clicked.connect(self._clear_profile)
        self.dlg_draw_profile.dlg_closed.connect(partial(tools_gw.save_settings, self.dlg_draw_profile))
        self.dlg_draw_profile.dlg_closed.connect(partial(self._remove_selection, actionpan=True))
        self.dlg_draw_profile.dlg_closed.connect(partial(self._reset_profile_variables))
        self.dlg_draw_profile.dlg_closed.connect(partial(tools_gw.disconnect_signal, 'profile'))

        # Set shortcut keys
        self.dlg_draw_profile.key_escape.connect(partial(tools_gw.close_dialog, self.dlg_draw_profile))

        # Set calendar date as today
        tools_qt.set_calendar(self.dlg_draw_profile, "date", None)

        # Set last parameters
        tools_qt.set_widget_text(self.dlg_draw_profile, self.dlg_draw_profile.txt_min_distance,
                                 tools_gw.get_config_parser('btn_profile', 'min_distance_profile', "user", "session"))
        tools_qt.set_widget_text(self.dlg_draw_profile, self.dlg_draw_profile.txt_title,
                                 tools_gw.get_config_parser('btn_profile', 'title_profile', "user", "session"))

        # Show form in docker
        tools_gw.init_docker('qgis_form_docker')
        if lib_vars.session_vars['dialog_docker']:
            tools_gw.docker_dialog(self.dlg_draw_profile, dlg_name='profile', title='profile')
        else:
            tools_gw.open_dialog(self.dlg_draw_profile, dlg_name='profile')

    def show_profile_for_nodes(self, init_node, end_node, links_distance=None):
        return self.profile.show_profile(init_node, end_node, links_distance=links_distance)

    # region private functions

    def _reset_profile_variables(self):

        self.initNode = None
        self.endNode = None
        self.first_node = True
        self.add_points = False
        self.add_points_list = []

    def _activate_add_points(self, activate=True):
        self.add_points = activate
        if not activate:
            self.add_points_list.clear()
            self.add_points_list = []
            self.endNode = None

    def _get_profile(self):

        if not GwProfile.check_matplotlib():
            return

        self.none_values = []

        # Get parameters
        links_distance = tools_qt.get_text(self.dlg_draw_profile, self.dlg_draw_profile.txt_min_distance, False, False)
        if links_distance in ("", "None", None):
            links_distance = 1

        # Create variable with all the content of the form
        extras = f'"initNode":"{self.initNode}", "endNode":"{self.endNode}", ' \
                 f'"linksDistance":{links_distance}, "scale":{{ "eh":1000, "ev":1000}}'
        if self.add_points_list:
            points_list = str(self.add_points_list).replace("'", "")
            extras += f', "midFeatures":{points_list}'

        body = tools_gw.create_body(extras=extras)

        # Execute query
        self.profile_json = tools_gw.execute_procedure('gw_fct_getprofilevalues', body)
        if self.profile_json is None or self.profile_json['status'] == 'Failed':
            return

        # Manage level and message from query result
        if self.profile_json['message']:
            level = int(self.profile_json['message']['level'])
            msg = self.profile_json['message']['text']
            level = Qgis.MessageLevel(level)
            tools_qgis.show_message(msg, level)
            if self.profile_json['message']['level'] != 3:
                return

        if not self.profile_json:
            return

        tools_gw.set_config_parser('btn_profile', 'min_distance_profile', f'{links_distance}')
        title = tools_qt.get_text(self.dlg_draw_profile, self.dlg_draw_profile.txt_title, False, False)
        tools_gw.set_config_parser('btn_profile', 'title_profile', f'{title}')

        self.profile.set_draw_context(self.initNode, self.endNode, dlg=self.dlg_draw_profile)
        self.profile.profile_json = self.profile_json
        self.profile.none_values = []
        self.profile.nodes = []
        self.profile.links = []
        data = self.profile_json['body']['data']
        self.profile.draw(data['arc'], data['node'], data['terrain'])
        self.profile.show_window()
        self.plot = self.profile.plot
        self.none_values = self.profile.none_values
        if self.none_values:
            msg = "There are missing values in these nodes:"
            tools_qt.show_info_box(msg, inf_text=self.none_values)

    def _save_profile(self):
        """ Save profile """

        profile_id = tools_qt.get_text(self.dlg_draw_profile, self.dlg_draw_profile.txt_profile_id)
        if profile_id in (None, 'null'):
            msg = "Profile name is mandatory."
            tools_qgis.show_warning(msg)
            return

        # Clear and populate list with new arcs
        list_arc = []
        n = self.dlg_draw_profile.tbl_list_arc.count()
        for i in range(n):
            list_arc.append(int(self.dlg_draw_profile.tbl_list_arc.item(i).text()))

        # Get values from profile form
        links_distance = tools_qt.get_text(self.dlg_draw_profile, self.dlg_draw_profile.txt_min_distance)
        if links_distance in ("", "None", None):
            links_distance = 1
        title = tools_qt.get_text(self.dlg_draw_profile, self.dlg_draw_profile.txt_title)
        date = tools_qt.get_calendar_date(self.dlg_draw_profile, self.dlg_draw_profile.date, date_format='dd/MM/yyyy')

        # Create variable with all the content of the form
        extras = f'"profile_id":"{profile_id}", "listArcs":"{list_arc}","initNode":"{self.initNode}", "midFeatures":"{self.add_points_list}", ' \
            f'"endNode":"{self.endNode}", ' \
            f'"linksDistance":{links_distance}, "scale":{{ "eh":1000, ' \
            f'"ev":1000}}, "title":"{title}", "date":"{date}"'
        body = tools_gw.create_body(extras=extras)
        result = tools_gw.execute_procedure('gw_fct_setprofile', body)
        if result is None or result['status'] == 'Failed':
            return
        message = f"{result['message']}"
        tools_qgis.show_info(message)

    def _open_profile(self):
        """ Open dialog profile_list.ui """

        self.dlg_load = GwProfilesListUi(self)
        tools_gw.load_settings(self.dlg_load)

        # Get profils on database
        body = tools_gw.create_body()
        result_profile = tools_gw.execute_procedure('gw_fct_getprofile', body)
        if not result_profile or result_profile['status'] == 'Failed':
            return
        message = f"{result_profile['message']}"
        tools_qgis.show_info(message)

        self.dlg_load.btn_open.clicked.connect(partial(self._load_profile, result_profile))
        self.dlg_load.btn_delete_profile.clicked.connect(partial(self._delete_profile))

        # Populate profile list
        for profile in result_profile['body']['data']:
            item_arc = QListWidgetItem(str(profile['profile_id']))
            self.dlg_load.tbl_profiles.addItem(item_arc)

        tools_gw.open_dialog(self.dlg_load, dlg_name='profile_list')

    def _load_profile(self, parameters):
        """ Open selected profile from dialog load_profiles.ui """

        selected_list = self.dlg_load.tbl_profiles.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg)
            return

        tools_gw.close_dialog(self.dlg_load)

        profile_id = self.dlg_load.tbl_profiles.currentItem().text()

        # Setting parameters on profile form
        self.dlg_draw_profile.btn_draw_profile.setEnabled(True)
        self.dlg_draw_profile.btn_save_profile.setEnabled(True)
        for profile in parameters['body']['data']:
            if profile['profile_id'] == profile_id:
                # Get data
                self.initNode = profile['values']['initNode']
                self.add_points_list = profile['values']['midFeatures']
                self.endNode = profile['values']['endNode']

                # Populate list arcs
                links_distance = profile.get('values').get('linksDistance')
                if links_distance in ("", "None", None):
                    links_distance = 1
                extras = f'"initNode":"{self.initNode}", "endNode":"{self.endNode}", ' \
                f'"linksDistance":{links_distance}, "scale":{{ "eh":1000, "ev":1000}}'
                if self.add_points_list:
                    points_list = str(self.add_points_list).replace("'", "")
                    extras += f', "midFeatures":{points_list}'
                body = tools_gw.create_body(extras=extras)
                result = tools_gw.execute_procedure('gw_fct_getprofilevalues', body)

                # Get arcs from profile
                expr_filter = "\"arc_id\" IN ("
                for arc in result['body']['data']['arc']:
                    expr_filter += f"'{arc['arc_id']}', "
                expr_filter = expr_filter[:-2] + ")"
                expr = QgsExpression(expr_filter)
                # Get a featureIterator from this expression:
                self.layer_arc = tools_qgis.get_layer_by_tablename("ve_arc")
                it = self.layer_arc.getFeatures(QgsFeatureRequest(expr))

                self.id_list = [i.id() for i in it]
                if not self.id_list:
                    msg = "Couldn't draw profile. You may need to select another exploitation."
                    tools_qgis.show_warning(msg)
                    return
                self.layer_arc.selectByIds(self.id_list)

                # Set data in dialog
                self.dlg_draw_profile.txt_profile_id.setText(str(profile_id))
                self.dlg_draw_profile.tbl_list_arc.clear()

                for arc in result['body']['data']['arc']:
                    item_arc = QListWidgetItem(str(arc['arc_id']))
                    self.dlg_draw_profile.tbl_list_arc.addItem(item_arc)
        
                self.dlg_draw_profile.txt_min_distance.setText(str(profile['values']['linksDistance']))

                self.dlg_draw_profile.txt_title.setText(str(profile['values']['title']))
                date = QDate.fromString(profile['values']['date'], 'dd-MM-yyyy')
                tools_qt.set_calendar(self.dlg_draw_profile, self.dlg_draw_profile.date, date)

                # Select features in map
                self._remove_selection()
                self.layer_arc.selectByIds(self.id_list)

                # Center shortest path in canvas - ZOOM SELECTION
                self.canvas.zoomToSelected(self.layer_arc)

    def _activate_snapping_node(self):

        if hasattr(self, "first_node"):
            self.snapper_manager.remove_marker()
        self.initNode = None if not hasattr(self, "initNode") else self.initNode
        self.endNode = None if not hasattr(self, "endNode") else self.endNode
        self.first_node = True if not hasattr(self, "first_node") else self.first_node

        if self.first_node is False and not self.add_points:
            msg = "First node already selected with id: {0}. Select second one."
            msg_params = (self.initNode)
            tools_qgis.show_info(msg, msg_params=msg_params)

        # Set vertex marker propierties
        self.snapper_manager.set_vertex_marker(self.vertex_marker, icon_type=4)

        # Create the appropriate map tool and connect the gotPoint() signal.
        if hasattr(self, "emit_point") and self.emit_point is not None:
            tools_gw.disconnect_signal('profile', 'ep_canvasClicked_snapping_node')
        self.emit_point = QgsMapToolEmitPoint(self.canvas)
        self.canvas.setMapTool(self.emit_point)
        self.snapper = self.snapper_manager.get_snapper()
        self.iface.setActiveLayer(self.layer_node)

        tools_gw.connect_signal(self.canvas.xyCoordinates, self._mouse_move,
                                'profile', 'activate_snapping_node_xyCoordinates_mouse_move')
        tools_gw.connect_signal(self.emit_point.canvasClicked, partial(self._snapping_node),
                                'profile', 'ep_canvasClicked_snapping_node')
        # To activate action pan and not move the canvas accidentally we have to override the canvasReleaseEvent.
        # The "e" is the QgsMapMouseEvent given by the function
        self.emit_point.canvasReleaseEvent = lambda e: self._action_pan()

    def _mouse_move(self, point):

        event_point = self.snapper_manager.get_event_point(point=point)

        # Snapping – always try node layer (active layer)
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if result.isValid() and self.snapper_manager.get_snapped_layer(result) == self.layer_node:
            self.snapper_manager.add_marker(result, self.vertex_marker)
            return

        # In add_points mode also accept arc layer as fallback
        if self.add_points and self.layer_arc:
            self.iface.setActiveLayer(self.layer_arc)
            result_arc = self.snapper_manager.snap_to_current_layer(event_point)
            self.iface.setActiveLayer(self.layer_node)
            if result_arc.isValid() and self.snapper_manager.get_snapped_layer(result_arc) == self.layer_arc:
                self.snapper_manager.add_marker(result_arc, self.vertex_marker)
                return

        self.vertex_marker.hide()

    def _snapping_node(self, point):   # @UnusedVariable

        # Get clicked point
        event_point = self.snapper_manager.get_event_point(point=point)

        # Snapping – always try node layer (active layer) first
        result = self.snapper_manager.snap_to_current_layer(event_point)
        snapped_node = result.isValid() and self.snapper_manager.get_snapped_layer(result) == self.layer_node

        # In add_points mode also try arc layer if node didn't snap
        snapped_arc = False
        if self.add_points and not snapped_node and self.layer_arc:
            self.iface.setActiveLayer(self.layer_arc)
            result = self.snapper_manager.snap_to_current_layer(event_point)
            self.iface.setActiveLayer(self.layer_node)
            snapped_arc = result.isValid() and self.snapper_manager.get_snapped_layer(result) == self.layer_arc

        if snapped_node or snapped_arc:
            snapped_feat = self.snapper_manager.get_snapped_feature(result)
            if snapped_node:
                element_id = snapped_feat.attribute('node_id')
            else:
                element_id = snapped_feat.attribute('arc_id')
            self.element_id = str(element_id)

            if self.first_node and not self.add_points:
                self.initNode = element_id
                self.first_node = False
                msg = "Node 1 selected"
                tools_qgis.show_info(msg, parameter=self.element_id)
            else:
                if self.element_id == str(self.initNode) or self.element_id == str(self.endNode) \
                        or self.element_id in [str(x) for x in self.add_points_list]:
                    msg = "Node already selected" if snapped_node else "Arc already selected"
                    param = element_id
                    tools_qgis.show_warning(msg, parameter=param)
                    if not self.add_points:
                        tools_qgis.disconnect_snapping(False, self.emit_point, self.vertex_marker)
                        tools_gw.disconnect_signal('profile')
                        self.dlg_draw_profile.btn_save_profile.setEnabled(False)
                        self.dlg_draw_profile.btn_draw_profile.setEnabled(False)
                        self.action_add_point.setDisabled(True)
                        # Clear old list arcs
                        self.dlg_draw_profile.tbl_list_arc.clear()

                        self._remove_selection()
                else:
                    if self.add_points:
                        self.add_points_list.append(element_id)
                        result = self._execute_profile_query()
                        if result is None:
                            self.add_points_list.pop()
                            return
                        updated = self._update_profile_ui(result, roll_back_on_error=True)
                        # Turn off snapping until user clicks add point again (reactivates picking)
                        if updated:
                            tools_qgis.disconnect_snapping(False, self.emit_point, self.vertex_marker)
                            tools_gw.disconnect_signal('profile')
                        # Stay in add_points mode so the user can keep adding mid-features
                    else:
                        self.endNode = element_id
                        tools_qgis.show_info("Node 2 selected", parameter=self.element_id)
                        # Defer DB + UI so messageBar paints (Qt handles paint after this event returns)
                        QTimer.singleShot(50, self._on_node2_selected_continue)

    def _on_node2_selected_continue(self):
        tools_qgis.disconnect_snapping(False, self.emit_point, self.vertex_marker)
        tools_gw.disconnect_signal('profile')
        self.dlg_draw_profile.btn_draw_profile.setEnabled(True)
        self.dlg_draw_profile.btn_save_profile.setEnabled(True)

        result = self._execute_profile_query()
        if result is None:
            return
        self._update_profile_ui(result, roll_back_on_error=False)
        self.action_add_point.setDisabled(False)

        # Next profile will be done from scratch
        self.first_node = True

    def _execute_profile_query(self):
        """ Build extras and call gw_fct_getprofilevalues. Returns the result dict or None on failure. """
        links_distance = tools_qt.get_text(self.dlg_draw_profile, self.dlg_draw_profile.txt_min_distance, False, False)
        if links_distance in ("", "None", None):
            links_distance = 1
        extras = (f'"initNode":"{self.initNode}", "endNode":"{self.endNode}", '
                  f'"linksDistance":{links_distance}, "scale":{{"eh":1000, "ev":1000}}')
        if self.add_points_list:
            points_list = str(self.add_points_list).replace("'", "")
            extras += f', "midFeatures":{points_list}'
        body = tools_gw.create_body(extras=extras)
        result = tools_gw.execute_procedure('gw_fct_getprofilevalues', body)
        if result is None or result['status'] == 'Failed':
            return None
        return result

    def _update_profile_ui(self, result, roll_back_on_error=False):
        """ Populate tbl_list_arc and highlight arcs from a gw_fct_getprofilevalues result. """
        if result['message']:
            level = int(result['message']['level'])
            msg = result['message']['text']
            tools_qgis.show_message(msg, Qgis.MessageLevel(level))
            if result['message']['level'] != 3:
                if roll_back_on_error and self.add_points_list:
                    self.add_points_list.pop()
                return False

        self._remove_selection()
        self.dlg_draw_profile.tbl_list_arc.clear()
        for arc in result['body']['data']['arc']:
            self.dlg_draw_profile.tbl_list_arc.addItem(QListWidgetItem(str(arc['arc_id'])))

        arc_ids = [arc['arc_id'] for arc in result['body']['data']['arc']]
        if arc_ids:
            expr_filter = '"arc_id" IN (' + ', '.join(f"'{a}'" for a in arc_ids) + ')'
            it = self.layer_arc.getFeatures(QgsFeatureRequest(QgsExpression(expr_filter)))
            self.id_list = [i.id() for i in it]
            self.layer_arc.selectByIds(self.id_list)
        return True

    def _action_pan(self):
        if self.first_node:
            # Set action pan
            self.iface.actionPan().trigger()

    def _clear_profile(self):
        """ Manage button clear profile and leave form empty """

        # Clear list of nodes and arcs
        self.list_of_selected_nodes = []
        self.list_of_selected_arcs = []
        self.arcs = []

        # Clear widgets
        self.dlg_draw_profile.tbl_list_arc.clear()
        self.dlg_draw_profile.txt_profile_id.clear()
        self.action_profile.setDisabled(False)
        self.action_add_point.setDisabled(True)
        self.dlg_draw_profile.btn_draw_profile.setEnabled(False)
        self.dlg_draw_profile.btn_save_profile.setEnabled(False)

        # Clear selection
        self._remove_selection()
        self._reset_profile_variables()

    def _delete_profile(self):
        """ Delete profile """

        selected_list = self.dlg_load.tbl_profiles.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg)
            return

        # Selected item from list
        profile_id = self.dlg_load.tbl_profiles.currentItem().text()

        extras = f'"profile_id":"{profile_id}", "action":"delete"'
        body = tools_gw.create_body(extras=extras)
        result = tools_gw.execute_procedure('gw_fct_setprofile', body)
        if result and 'message' in result:
            message = f"{result['message']}"
            tools_qgis.show_info(message)

        # Remove profile from list
        self.dlg_load.tbl_profiles.takeItem(self.dlg_load.tbl_profiles.row(self.dlg_load.tbl_profiles.currentItem()))

    def _remove_selection(self, actionpan=False):
        """ Remove selected features of all layers """

        for layer in self.canvas.layers():
            if type(layer) is QgsVectorLayer:
                layer.removeSelection()
        self.canvas.refresh()
        if actionpan:
            self.iface.actionPan().trigger()

    # endregion