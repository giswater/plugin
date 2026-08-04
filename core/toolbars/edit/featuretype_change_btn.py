"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial

from qgis.PyQt.QtCore import Qt
from qgis.PyQt.QtWidgets import QMenu, QAction, QActionGroup, QGridLayout
from qgis.core import QgsFeatureRequest

from ..maptool import GwMaptool
from ...shared.catalog import GwCatalog
from ...shared.info import GwInfo
from ...ui.ui_manager import GwFeatureTypeChangeUi
from ...utils import tools_gw
from ....libs import tools_qgis, tools_qt
from .... import global_vars


class GwFeatureTypeChangeButton(GwMaptool):
    """ Button 25: Change feature type
    User select from drop-down button feature type: ARC, NODE, CONNEC.
    Snap to this feature type is activated.
    User selects a feature of that type from the map.
    A form is opened showing current feature_type.type and combos to replace it
    """

    def __init__(self, icon_path, action_name, text, toolbar, action_group, icon_type=1, actions=None, list_tables=None):

        super().__init__(icon_path, action_name, text, toolbar, action_group, icon_type)
        self.project_type = None
        self.feature_type = None
        self.tablename = None
        self.cat_table = None
        self.feature_edit_type = None
        self.feature_type_cat = None
        self.feature_id = None
        self.actions = actions
        if not self.actions:
            self.actions = [['ARC', tools_qt.tr('ARC')], ['NODE', tools_qt.tr('NODE')], ['CONNEC', tools_qt.tr('CONNEC')]]
        self.list_tables = list_tables
        if not self.list_tables:
            self.list_tables = ['ve_arc', 've_node', 've_connec', 've_gully']

        # Create a menu and add all the actions
        if toolbar is not None:
            toolbar.removeAction(self.action)

        self.menu = QMenu()
        self.menu.setObjectName("GW_change_menu")
        self._fill_change_menu()

        if toolbar is not None:
            self.action.setMenu(self.menu)
            toolbar.addAction(self.action)

    # region QgsMapTools inherited
    """ QgsMapTools inherited event functions """

    def activate(self):

        self.project_type = tools_gw.get_project_type()

        # Check action. It works if is selected from toolbar. Not working if is selected from menu or shortcut keys
        if hasattr(self.action, "setChecked"):
            self.action.setChecked(True)

        # Store user snapping configuration
        self.previous_snapping = self.snapper_manager.get_snapping_options()

        # Set snapping to 'node', 'connec' and 'gully'
        self.snapper_manager.set_snapping_layers()

        # Manage last feature type selected
        last_feature_type = tools_gw.get_config_parser("btn_featuretype_change", "last_feature_type", "user", "session")
        if last_feature_type is None:
            last_feature_type = "NODE"

        # Manage active layer
        self._set_active_layer(last_feature_type)
        layer = self.iface.activeLayer()
        tablename = tools_qgis.get_layer_source_table_name(layer)
        if tablename not in self.list_tables:
            self._set_active_layer(last_feature_type)

        # Change cursor
        self.canvas.setCursor(self.cursor)

        # Show help message when action is activated
        if self.show_help:
            msg = "Click on the object to change its class"
            tools_qgis.show_info(msg)

    def canvasMoveEvent(self, event):

        # Hide marker and get coordinates
        self.vertex_marker.hide()
        event_point = self.snapper_manager.get_event_point(event)

        # Snapping layers 've_'
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if result.isValid():
            layer = self.snapper_manager.get_snapped_layer(result)
            tablename = tools_qgis.get_layer_source_table_name(layer)
            if tablename and 've' in tablename:
                self.snapper_manager.add_marker(result, self.vertex_marker)

    def canvasReleaseEvent(self, event):

        self._featuretype_change(event)

    # endregion

    # region private functions

    def _fill_change_menu(self):
        """ Fill change feature type menu """

        # disconnect and remove previuos signals and actions
        actions = self.menu.actions()
        for action in actions:
            action.disconnect()
            self.menu.removeAction(action)
            del action
        ag = QActionGroup(self.iface.mainWindow())

        if global_vars.project_type.lower() == 'ud':
            self.actions.append(['GULLY', tools_qt.tr('GULLY')])

        for action_id, action_name in self.actions:
            obj_action = QAction(f"{action_name}", ag)
            self.menu.addAction(obj_action)
            obj_action.triggered.connect(partial(super().clicked_event))
            obj_action.triggered.connect(partial(self._set_active_layer, action_id))
            obj_action.triggered.connect(partial(tools_gw.set_config_parser, section="btn_featuretype_change",
                                                 parameter="last_feature_type", value=action_id, comment=None))

    def _set_active_layer(self, name):
        """ Sets the active layer according to the name parameter (ARC, NODE, CONNEC, GULLY) """

        layers = {"ARC": "ve_arc", "NODE": "ve_node",
                  "CONNEC": "ve_connec", "GULLY": "ve_gully"}
        tablename = layers.get(name.upper())
        self.current_layer = tools_qgis.get_layer_by_tablename(tablename)
        self.iface.setActiveLayer(self.current_layer)

    def _open_custom_form(self, layer, expr):
        """ Open custom from selected layer """

        it = layer.getFeatures(QgsFeatureRequest(expr))
        features = [i for i in it]
        if features[0]:
            self.customForm = GwInfo('data')
            self.customForm.user_current_layer = self.current_layer
            feature_id = features[0][f"{self.feature_type}_id"]
            complet_result, dialog = self.customForm.get_info_from_id(self.tablename, feature_id, 'data')
            if not complet_result:
                return

            dialog.dlg_closed.connect(partial(tools_qgis.restore_user_layer, self.tablename))

    def _open_dialog(self):
        """ Open Feature Change Dialog dynamic """

        feature = f'"tableName":"{self.tablename}", "id":"{self.feature_id}"'
        body = tools_gw.create_body(feature=feature)
        json_result = tools_gw.execute_procedure('gw_fct_getchangefeaturetype', body)
        self.dlg_change = GwFeatureTypeChangeUi(self)
        tools_gw.load_settings(self.dlg_change)
        self._manage_dlg_widgets(self.dlg_change, json_result)
        tools_gw.open_dialog(self.dlg_change, 'featuretype_change')

    def _manage_dlg_widgets(self, dialog, complet_result):
        """ Creates and populates all the widgets, preserving original layout logic while ensuring two-column alignment """

        layout_orientations = {}
        old_widget_pos = 0
        # Define a fixed width for labels to ensure alignment
        label_fixed_width = 100

        # Retrieve layout orientations from the JSON response if provided
        for layout_name, layout_info in complet_result['body']['form']['layouts'].items():
            orientation = layout_info.get('lytOrientation')
            if orientation:
                layout_orientations[layout_name] = orientation

        # Loop through fields to add them to the appropriate layout
        for field in complet_result['body']['data']['fields']:
            # Skip hidden fields based on conditions
            if field.get('hidden'):
                continue

            # Create label and widget
            label, widget = tools_gw.set_widgets(dialog, complet_result, field, self.tablename, self)
            if widget is None:
                continue

            # Check if the label is valid before applying size adjustments
            if label is not None:
                label.setFixedWidth(label_fixed_width)

            # Find the layout for the current field based on layoutname
            layout = dialog.findChild(QGridLayout, field['layoutname'])
            if layout is None:
                continue

            # Apply layout orientation if specified in JSON
            orientation = layout_orientations.get(layout.objectName(), "vertical")
            layout.setProperty('lytOrientation', orientation)

            # Adjust alignment for the Catalog id label
            if field['columnname'] == "featurecat_id":
                # Add the label and combo box (Catalog ID) with the button
                layout.addWidget(label, field['layoutorder'] - 1, 0)
                layout.addWidget(widget, field['layoutorder'] - 1, 1)
            else:
                # Use add_widget_combined for other fields
                old_widget_pos = tools_gw.add_widget_combined(dialog, field, label, widget, old_widget_pos)

            # Apply consistent column stretch across all layouts
            layout.setColumnStretch(0, 1)  # Label column stretch (keep this compact)
            layout.setColumnStretch(1, 3)  # Widget column stretch for sufficient space

    def _featuretype_change(self, event):

        if event.button() == Qt.MouseButton.RightButton:
            self.cancel_map_tool()
            return

        # Get snapped feature
        event_point = self.snapper_manager.get_event_point(event)
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if not result.isValid():
            return

        snapped_feat = self.snapper_manager.get_snapped_feature(result)
        if snapped_feat is None:
            return

        layer = self.snapper_manager.get_snapped_layer(result)
        tablename = tools_qgis.get_layer_source_table_name(layer)
        if tablename and 've' in tablename:
            if tablename == 've_node':
                self.feature_type = 'node'
            elif tablename == 've_connec':
                self.feature_type = 'connec'
            elif tablename == 've_gully':
                self.feature_type = 'gully'
            elif tablename == 've_arc':
                self.feature_type = 'arc'

        self.tablename = tablename
        self.cat_table = f'cat_{self.feature_type}'
        self.feature_edit_type = f'{self.feature_type}_type'
        self.feature_type_cat = f'{self.feature_type}type_id'
        self.feature_id = snapped_feat.attribute(f'{self.feature_type}_id')
        self._open_dialog()
    # endregion


def btn_cancel_featuretype_change(**kwargs):
    """ Close form """

    dialog = kwargs["dialog"]
    tools_gw.close_dialog(dialog)


def btn_accept_featuretype_change(**kwargs):
    """ Update current type of feature and save changes in database """

    class_obj = kwargs["class"]
    dialog = kwargs["dialog"]

    project_type = tools_gw.get_project_type()
    feature_type_new = tools_qt.get_combo_value(dialog, "tab_none_feature_type_new", 1)
    featurecat_id = tools_qt.get_widget_value(dialog, "tab_none_featurecat_id")

    if featurecat_id.startswith('(') and featurecat_id.endswith(')'):
        msg = "Error replacing feature. Chose a valid catalog."
        tools_qgis.show_warning(msg)
        return
    fluid_type = tools_qt.get_combo_value(dialog, 'tab_none_fluid_type', 1)
    if fluid_type is None:
        fluid_type = 'null'
    location_type = tools_qt.get_combo_value(dialog, 'tab_none_location_type', 1)
    if location_type is None:
        location_type = 'null'
    category_type = tools_qt.get_combo_value(dialog, 'tab_none_category_type', 1)
    if category_type is None:
        category_type = 'null'
    function_type = tools_qt.get_combo_value(dialog, 'tab_none_function_type', 1)
    if function_type is None:
        function_type = 'null'

    if feature_type_new != "null":

        if (featurecat_id != "null" and featurecat_id is not None and project_type == 'ws') or (
                project_type == 'ud'):

            # Get function input parameters
            feature = f'"type":"{class_obj.feature_type}"'
            extras = f'"feature_id":"{class_obj.feature_id}"'
            extras += f', "feature_type_new":"{feature_type_new}"'
            extras += f', "featurecat_id":"{featurecat_id}"'
            extras += f', "fluid_type":"{fluid_type}"'
            extras += f', "location_type":"{location_type}"'
            extras += f', "category_type":"{category_type}"'
            extras += f', "function_type":"{function_type}"'

            body = tools_gw.create_body(feature=feature, extras=extras)

            # Execute SQL function and show result to the user
            complet_result = tools_gw.execute_procedure('gw_fct_setchangefeaturetype', body)
            if not complet_result:
                msg = "Error replacing feature"
                tools_qgis.show_warning(msg)
                # Check in init config file if user wants to keep map tool active or not
                class_obj.manage_active_maptool()
                tools_gw.close_dialog(dialog)
                return

            if "Accepted" in complet_result['status']:
                msg = complet_result['message']['text']
                if msg is None:
                    msg = 'Replace feature done successfully'
                tools_qgis.show_info(msg)
            elif "Failed" in complet_result['status']:
                return

            tools_gw.set_config_parser("btn_featuretype_change", "feature_type_new", feature_type_new)
            tools_gw.set_config_parser("btn_featuretype_change", "featurecat_id", featurecat_id)

        else:
            msg = "Field catalog_id required!"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

    else:
        msg = "Feature has not been updated because no catalog has been selected"
        tools_qgis.show_warning(msg)

    # Close form
    tools_gw.close_dialog(dialog)

    # Refresh map canvas
    class_obj.refresh_map_canvas()

    # Check if the expression is valid
    expr_filter = f"{class_obj.feature_type}_id = '{class_obj.feature_id}'"
    (is_valid, expr) = tools_qt.check_expression_filter(expr_filter)  # @UnusedVariable
    if not is_valid:
        return

    # Check in init config file if user wants to keep map tool active or not
    class_obj.manage_active_maptool()


def btn_catalog_featuretype_change(**kwargs):
    """ Open Catalog form """

    dialog = kwargs["dialog"]
    class_obj = kwargs["class"]

    # Get feature_type
    child_type = tools_qt.get_text(dialog, "tab_none_feature_type_new")
    if child_type == 'null':
        msg = "New feature type is null. Please, select a valid value"
        tools_qt.show_info_box(msg, "Info")
        return

    class_obj.catalog = GwCatalog()
    class_obj.catalog.open_catalog(dialog, 'tab_none_featurecat_id', class_obj.feature_type, child_type)


def cmb_new_featuretype_selection_changed(**kwargs):
    """ When new featuretype changes, catalog_id and related fields (fluid, location, etc.) update as well """

    dialog = kwargs["dialog"]
    cmb_new_feature_type = kwargs["widget"]
    class_obj = kwargs["class"]
    reload_fields = []

    # Fetch the new feature type
    feature_type_new = tools_qt.get_widget_value(dialog, cmb_new_feature_type)

    # Create body with only newFeatureCat in extras
    feature = f'"tableName":"{class_obj.tablename}", "id":"{class_obj.feature_id}"'
    extras = f'"newFeatureCat":"{feature_type_new}"'
    body = tools_gw.create_body(feature=feature, extras=extras)

    # Execute function to get additional data for fluid, location, category, and function types
    json_result = tools_gw.execute_procedure("gw_fct_getchangefeaturetype", body)

    for field in json_result['body']['data']['fields']:
        widgetcontrols = field.get('widgetcontrols')
        if widgetcontrols:
            reload_fields = widgetcontrols.get('reloadFields', [])

        if field.get('hidden') or (
            widgetcontrols and widgetcontrols.get('hiddenWhenNull') and field.get('value') in (None, '')
        ) or field['columnname'] not in reload_fields:
            continue

        if field['widgettype'] == 'combo':
            tools_gw.fill_combo(tools_qt.get_widget(dialog, field['widgetname']), field)
        if field['widgettype'] == 'typeahead':
            # Retrieve widget and selected value
            widget = tools_qt.get_widget(dialog, field['widgetname'])

            # Populate rows from comboIds and comboNames
            rows = list(zip(field.get('comboIds', []), field.get('comboNames', [])))
            tools_qt.set_completer_rows(widget, rows)

            for row in rows:
                if row[0] == field['value']:
                    tools_qt.set_widget_text(dialog, widget, field['value'])
                    continue
            tools_qt.set_widget_text(dialog, widget, f"({field['value']})")

