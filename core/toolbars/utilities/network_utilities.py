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

from .... import global_vars
from ..dialog import GwAction
from ....libs import tools_qt, lib_vars
from ...utils import tools_gw
from ...shared.mincut import GwMincut
from ...shared.profile import GwProfileInterpolation
from ...shared.scada_graph import GwScadaGraph

_ROLE_HIERARCHY = (
    'role_basic',
    'role_om',
    'role_edit',
    'role_epa',
    'role_plan',
    'role_admin',
    'role_system',
)

_NETWORK_UTILS = (
    ('Profile interpolation', '_profile_interpolation', 'role_edit', ('ud',)),
    ('Mincut inspector', '_mincut_inspector', 'role_basic', ('ws',)),
    ('Scada graph', '_scada_graph', 'role_edit', ('ws',)),
)


class GwNetworkUtilitiesButton(GwAction):
    """ Button 69: Network utilities """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        super().__init__(icon_path, action_name, text, toolbar, action_group)

        if toolbar is not None:
            toolbar.removeAction(self.action)

        self.menu = QMenu()
        self.menu.setObjectName("GW_network_utilities_menu")
        self._fill_utils_menu()

        self.menu.aboutToShow.connect(self._fill_utils_menu)

        if toolbar is not None:
            self.action.setMenu(self.menu)
            toolbar.addAction(self.action)

        self._profile_interp = GwProfileInterpolation(self)
        self._scada_graph_tool = GwScadaGraph(self)

    def clicked_event(self):
        """ Show menu or rerun last selected tool """

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

    def _normalize_role(self, role):
        role = (role or 'role_basic').lower()
        if not role.startswith('role_'):
            role = f'role_{role}'
        return role

    def _user_has_min_role(self, min_role):
        user_role = tools_gw.get_role_permissions(lib_vars.project_vars.get('project_role'))
        min_role = self._normalize_role(min_role)
        try:
            return _ROLE_HIERARCHY.index(user_role) >= _ROLE_HIERARCHY.index(min_role)
        except ValueError:
            return False

    def _is_tool_visible(self, min_role, project_types):
        if global_vars.project_type not in project_types:
            return False
        return self._user_has_min_role(min_role)

    def _fill_utils_menu(self):
        """ Fill network utilities menu """

        actions = self.menu.actions()
        for action in actions:
            action.disconnect()
            self.menu.removeAction(action)
            del action
        action_group = self.action.property('action_group')

        for label, button_function, min_role, project_types in _NETWORK_UTILS:
            if not self._is_tool_visible(min_role, project_types):
                continue

            button_name = tools_qt.tr(label)
            obj_action = QAction(str(button_name), action_group)
            obj_action.setObjectName(button_name)
            obj_action.setProperty('action_group', action_group)
            self.menu.addAction(obj_action)
            obj_action.triggered.connect(partial(getattr(self, button_function)))
            obj_action.triggered.connect(partial(self._save_last_selection, self.menu, button_function))

        self.action.setEnabled(bool(self.menu.actions()))

    def _profile_interpolation(self):
        self._profile_interp.run()

    def _mincut_inspector(self):
        if not hasattr(self, '_mincut'):
            self._mincut = GwMincut()
        self._mincut.start_offline_mincut()

    def _scada_graph(self):
        self._scada_graph_tool.run()
