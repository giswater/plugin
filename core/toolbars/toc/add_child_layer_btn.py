"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial

from qgis.core import QgsProject
from qgis.PyQt.QtCore import QPoint
from qgis.PyQt.QtWidgets import QMenu, QCheckBox, QWidgetAction
from qgis.PyQt.QtGui import QCursor

from ..dialog import GwAction
from ...utils import tools_gw
from ....libs import tools_qgis, tools_qt, tools_db


class GwAddChildLayerButton(GwAction):
    """ Button 71: Add child layer """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        super().__init__(icon_path, action_name, text, toolbar, action_group)

    def clicked_event(self):

        self._add_child_layer()

    # region private functions

    def _add_child_layer(self):

        # Create main menu and get cursor click position
        main_menu = QMenu()
        cursor = QCursor()
        x = cursor.pos().x()
        y = cursor.pos().y()
        click_point = QPoint(x + 5, y + 5)

        # Layers already in TOC outside HIDDEN count as user-loaded
        layer_list = []

        for layer in QgsProject.instance().mapLayers().values():
            if tools_qgis.is_layer_under_group(layer, "HIDDEN"):
                continue
            if layer.customProperty("gw_id") is not None:
                layer_list.append(layer.customProperty("gw_id"))
            else:
                layer_list.append(tools_qgis.get_layer_source_table_name(layer))

        body = tools_gw.create_body()
        json_result = tools_gw.execute_procedure('gw_fct_getaddlayervalues', body)
        if not json_result or json_result['status'] == 'Failed':
            return False

        dict_menu = {}
        load_all_text = "Load all     "

        for field in json_result['body']['data']['fields']:
            if field['context'] is not None:
                level_1, level_2, level_3 = tools_gw.get_context_menu_levels(field['context'])
                if not level_1 or not level_2:
                    continue

                provider_config = field['providerConfig'] if field.get('providerConfig', None) is not None else None

                # Check if schema exists for am and cm
                if level_1 == "AM" or level_1 == "CM":
                    if tools_db.get_row(f"SELECT 1 FROM information_schema.schemata WHERE schema_name = '{level_1.lower()}'") is None:
                        # Skip group if schema does not exist
                        continue

                if level_1 not in dict_menu:
                    menu_level_1 = main_menu.addMenu(f"{level_1}")
                    dict_menu[level_1] = menu_level_1
                if f"{level_1}_{level_2}" not in dict_menu:
                    menu_level_2 = dict_menu[level_1].addMenu(f"{level_2}")
                    dict_menu[f"{level_1}_{level_2}"] = menu_level_2
                if level_3 and f"{level_1}_{level_2}_{level_3}" not in dict_menu:
                    menu_level_3 = dict_menu[f"{level_1}_{level_2}"].addMenu(f"{level_3}")
                    dict_menu[f"{level_1}_{level_2}_{level_3}"] = menu_level_3

                alias = field['layerName'] if field['layerName'] is not None else field['tableName']
                alias = f"{alias}     "
                if level_3 is not None:
                    menu = dict_menu[f"{level_1}_{level_2}_{level_3}"]
                    if f"{level_1}_{level_2}_{level_3}_load_all" not in dict_menu:
                        # LEVEL 3 - LOAD ALL
                        widget = QCheckBox()
                        widget.setText(load_all_text)
                        widget.setStyleSheet("margin: 5px 5px 5px 8px;")
                        widgetAction = QWidgetAction(menu)
                        widgetAction.setDefaultWidget(widget)
                        widgetAction.defaultWidget().stateChanged.connect(partial(self._manage_load_all, menu))
                        menu.addAction(widgetAction)
                        dict_menu[f"{level_1}_{level_2}_{level_3}_load_all"] = True
                    # LEVEL 3 - LAYER
                    widget = QCheckBox()
                    widget.setText(alias)
                    widgetAction = QWidgetAction(menu)
                    widgetAction.setDefaultWidget(widget)
                    menu.addAction(widgetAction)
                else:
                    menu = dict_menu[f"{level_1}_{level_2}"]
                    if f"{level_1}_{level_2}_load_all" not in dict_menu:
                        # LEVEL 2 - LOAD ALL
                        widget = QCheckBox()
                        widget.setText(load_all_text)
                        widget.setStyleSheet("margin: 5px 5px 5px 8px;")
                        widgetAction = QWidgetAction(menu)
                        widgetAction.setDefaultWidget(widget)
                        widgetAction.defaultWidget().stateChanged.connect(partial(self._manage_load_all, menu))
                        menu.addAction(widgetAction)
                        dict_menu[f"{level_1}_{level_2}_load_all"] = True
                    # LEVEL 2 - LAYER
                    widget = QCheckBox()
                    widget.setText(alias)
                    widgetAction = QWidgetAction(menu)
                    widgetAction.setDefaultWidget(widget)
                    menu.addAction(widgetAction)

                if f"{field['tableName']}" in layer_list:
                    widget.setChecked(True)
                widget.setStyleSheet("margin: 5px 5px 5px 8px;")

                layer_name = field['tableName']
                if field['geomField'] == "None":
                    the_geom = None
                else:
                    the_geom = field['geomField']
                geom_field = field['tableId']
                # If layer is configured but it doesn't exist in schema, ignore it
                if geom_field is None and provider_config is None:
                    continue
                geom_field = geom_field.replace(" ", "") if geom_field is not None else None
                group = level_1
                sub_group = level_2
                sub_sub_group = level_3
                widgetAction.defaultWidget().stateChanged.connect(
                    partial(self._check_action_ischecked, layer_name, the_geom, geom_field, group, sub_group,
                            sub_sub_group, alias.strip(), provider_config=provider_config))

        main_menu.exec(click_point)

    def _manage_load_all(self, menu, state=None):

        if state == 2:
            for child in menu.actions():
                if not child.isChecked():
                    child.defaultWidget().setChecked(True)

    def _check_action_ischecked(self, tablename, the_geom=None, field_id=None, group=None,
                                sub_group=None, sub_sub_group=None, alias=None, state=None,
                                provider_config=None):
        """ Control if user check or uncheck action menu, then add or remove layer from toc
        :param tablename: Postgres table name (String)
        :param the_geom: Geometry field of the table (String)
        :param field_id: Field id of the table (String)
        :param child_layers: List of layers (StringList)
        :param group: Name of the group that will be created in the toc (String)
        :param is_checked: This parameter is sent by the action itself with the trigger (Bool)
        """

        if state == 2:
            layer = tools_qgis.get_layer(custom_properties={"gw_id": tablename}, tablename=tablename)
            if layer is not None and tools_qgis.is_layer_under_group(layer, "HIDDEN"):
                if the_geom:
                    tools_qgis.set_layer_geometry_column(layer, the_geom, field_id)
                    tools_gw.set_layer_styles(tablename, layer, None)
                tools_qgis.move_layer_to_group(layer, group, sub_group, sub_sub_group)
                tools_qgis.set_layer_visible(layer, recursive=True, visible=True)
            elif layer is None:
                schema = None
                if group == "AM" or group == "CM":
                    schema = "am" if group == "AM" else "cm"
                if provider_config:
                    tools_gw.add_layer_provider(tablename, provider_config, group, sub_group, alias=alias, sub_sub_group=sub_sub_group, schema=schema)
                else:
                    tools_gw.add_layer_database(tablename, the_geom, field_id, group, sub_group, alias=alias, sub_sub_group=sub_sub_group, schema=schema)
        elif state == 0:
            layer = tools_qgis.get_layer(custom_properties={"gw_id": tablename}, tablename=tablename)
            if layer is None:
                return
            if tools_qgis.layer_is_value_relation_target(layer):
                tools_qgis.move_layer_to_group(layer, "HIDDEN")
                tools_qgis.set_layer_visible(layer, recursive=False, visible=False)
                tools_gw.hide_group_from_toc("HIDDEN")
                hidden_group = QgsProject.instance().layerTreeRoot().findGroup("HIDDEN")
                if hidden_group:
                    hidden_group.setItemVisibilityChecked(False)
                return
            msg = "Remove layer from project?"
            title = "Warning"
            answer = tools_qt.show_question(msg, title, parameter=f"'{layer.name()}'", force_action=True)
            if answer:
                tools_qgis.remove_layer(custom_properties={"gw_id": tablename}, tablename=tablename, group_name=group, sub_group=sub_group)

    # endregion
