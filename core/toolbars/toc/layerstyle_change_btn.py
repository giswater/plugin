"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial

from typing import List, Tuple
from qgis.PyQt.QtCore import QObject, QPoint
from qgis.PyQt.QtWidgets import QMenu, QAction
from qgis.PyQt.QtGui import QCursor
from qgis.core import QgsMapLayerStyle
from ..dialog import GwAction
from ...utils import tools_gw
from ....libs import tools_qgis, tools_db, lib_vars


def get_contexts_params() -> List[Tuple[int, str]]:

    # TODO: manage roles
    sql = """
    SELECT id, idval, addparam
        FROM config_style
    WHERE is_templayer = false AND active = true
    """
    rows = tools_db.get_rows(sql)

    if not rows:
        return []

    # Process rows to extract the order and sort them accordingly
    processed_rows = []
    for row in rows:
        id, idval, addparam = row
        order_by = 999  # Default order if not specified
        if addparam:
            try:
                order_by = addparam.get("orderBy", 999)
            except Exception:
                pass

        processed_rows.append((id, idval, order_by))

    # Sort the rows by order_by
    processed_rows.sort(key=lambda x: x[2])

    return [(row[0], row[1]) for row in processed_rows]


def get_styles_for_context(styleconfig_id: int) -> List[Tuple[str, str]]:
    """Fetch styles from the sys_style table for a given context."""

    sql = f"SELECT layername, stylevalue FROM v_sys_style WHERE styleconfig_id = {styleconfig_id}"
    rows = tools_db.get_rows(sql)
    return [(row[0], row[1]) for row in rows] if rows else []


def apply_styles_to_layers(styleconfig_id: int, style_name: str, force_refresh: bool = False) -> None:
    """Apply styles to layers based on the selected context."""

    styles = get_styles_for_context(styleconfig_id)
    for layername, qml in styles:
        layer = tools_qgis.get_layer_by_tablename(layername)
        if layer:
            valid_qml, error_message = tools_gw.validate_qml(qml)
            if not valid_qml:
                msg = "The QML file is invalid"
                tools_qgis.show_warning(msg, parameter=error_message, title=style_name)
            else:
                style_manager = layer.styleManager()

                if (style_manager is None or style_manager.currentStyle() == style_name) and not force_refresh:
                    continue

                # Set the style or add it if it doesn't exist
                if not style_manager.setCurrentStyle(style_name) or force_refresh:
                    style = QgsMapLayerStyle()
                    style.readFromLayer(layer)
                    style_manager.addStyle(style_name, style)
                    style_manager.setCurrentStyle(style_name)
                    tools_qgis.create_qml(layer, qml)


class GwLayerStyleChangeButton(GwAction):
    """Button 72: Switch layers' styles"""

    def __init__(self, icon_path: str, action_name: str, text: str, toolbar: QObject, action_group: QObject):
        super().__init__(icon_path, action_name, text, toolbar, action_group)

    def clicked_event(self) -> None:
        """Show the menu directly when the button is clicked."""

        self.menu: QMenu = QMenu()
        self._populate_menu()
        cursor = QCursor()
        x = cursor.pos().x()
        y = cursor.pos().y()
        click_point = QPoint(x + 5, y + 5)
        self.menu.exec(click_point)

    def _populate_menu(self) -> None:
        """Populate the menu with available contexts."""

        # contexts = get_available_contexts()
        contexts_params = get_contexts_params()
        for styleconfig_id, style_name in contexts_params:
            action: QAction = QAction(style_name, self.menu)
            action.triggered.connect(partial(self._apply_context, styleconfig_id, style_name))
            self.menu.addAction(action)

        # Add "Refresh all" option to menu that will update all layer styles 
        # by re-applying them from the current QGIS layer styles
        self.menu.addSeparator()
        action = QAction("Refresh all", self.menu)
        action.triggered.connect(partial(tools_gw.refresh_all_styles))
        self.menu.addAction(action)

    def _apply_context(self, styleconfig_id: int, style_name: str) -> None:
        """Apply styles for the selected context."""

        apply_styles_to_layers(styleconfig_id, style_name)
        lib_vars.project_vars['current_style'] = f"{styleconfig_id}"
        tools_qgis.set_project_variable('gwCurrentStyle', f"{styleconfig_id}")
        msg = "Applied styles for context"
        param = style_name
        tools_qgis.show_info(msg, parameter=param)