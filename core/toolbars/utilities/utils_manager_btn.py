"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

from functools import partial

from qgis.PyQt.QtCore import QPoint
from qgis.PyQt.QtWidgets import QAction, QMenu, QWidget

from .utilities_manager.style_manager import GwStyleManager
from .utilities_manager.review_manager import GwReviewManager
from .... import global_vars
from ..dialog import GwAction
from .utilities_manager.mapzone_manager import GwMapzoneManager
from ...shared.info import GwInfo
from ...shared.workcat import GwWorkcat
from ....libs import tools_qt, lib_vars
from ...utils import tools_gw


class GwUtilsManagerButton(GwAction):
    """ Button 61: Utils manager """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        super().__init__(icon_path, action_name, text, toolbar, action_group)

        # First add the menu before adding it to the toolbar
        if toolbar is not None:
            toolbar.removeAction(self.action)

        self.info_feature = GwInfo('data')

        self.menu = QMenu()
        self.menu.setObjectName("GW_utils_menu")
        self._fill_utils_menu()

        self.menu.aboutToShow.connect(self._fill_utils_menu)

        if toolbar is not None:
            self.action.setMenu(self.menu)
            toolbar.addAction(self.action)

    def clicked_event(self):

        if self.menu.property('last_selection') is not None:
            getattr(self, self.menu.property('last_selection'))()
            return
        if hasattr(self.action, 'associatedObjects'):
            button = QWidget(self.action.associatedObjects()[1])
        elif hasattr(self.action, 'associatedWidgets'):
            button = self.action.associatedWidgets()[1]
        menu_point = button.mapToGlobal(QPoint(0, button.height()))
        self.menu.popup(menu_point)

    def _save_last_selection(self, menu, button_function):
        menu.setProperty("last_selection", button_function)

    # region private functions

    def _fill_utils_menu(self):
        """ Fill add arc menu """

        # disconnect and remove previuos signals and actions
        actions = self.menu.actions()
        for action in actions:
            action.disconnect()
            self.menu.removeAction(action)
            del action
        action_group = self.action.property('action_group')

        buttons = [[tools_qt.tr('Mapzones manager'), '_mapzones_manager'],
                    [tools_qt.tr('Workcat manager'), '_workcat_manager']]
        role = tools_gw.get_role_permissions(lib_vars.project_vars.get('project_role'))
        if role in ('role_plan', 'role_admin', 'role_system'):
            buttons.append(['Style manager', '_style_manager'])
        title = "Review manager"
        if role not in ('role_basic', 'role_om'):
            buttons.append([title, '_review_manager'])
        for button in buttons:
            button_name = button[0]
            button_function = button[1]
            obj_action = QAction(str(tools_qt.tr(button_name)), action_group)
            obj_action.setObjectName(button_name)
            obj_action.setProperty('action_group', action_group)
            # if f"{feature_cat.shortcut_key}" not in global_vars.shortcut_keys:
            #     obj_action.setShortcut(QKeySequence(str(feature_cat.shortcut_key)))
            # try:
            #     obj_action.setShortcutVisibleInContextMenu(True)
            # except Exception:
            #     pass
            self.menu.addAction(obj_action)
            obj_action.triggered.connect(partial(getattr(self, button_function)))
            obj_action.triggered.connect(partial(self._save_last_selection, self.menu, button_function))

    # region mapzone manager functions

    def _mapzones_manager(self):

        self.mapzones_manager = GwMapzoneManager()
        self.mapzones_manager.manage_mapzones()
    # endregion

    # region workcat manager functions

    def _workcat_manager(self):
        self.workcat = GwWorkcat(global_vars.iface, global_vars.canvas)
        self.workcat.manage_workcats()
    # endregion

    # region style manager functions

    def _style_manager(self):
        self.style = GwStyleManager()
        self.style.manage_styles()

    # endregion

    # region review manager functions

    def _review_manager(self):
        self.review = GwReviewManager()
        self.review.manage_review()

    # endregion
