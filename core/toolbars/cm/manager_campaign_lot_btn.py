"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from .campaign import Campaign
from .lot import AddNewLot
from .workorder import Workorder
from ..dialog import GwAction
from qgis.PyQt.QtWidgets import QAction, QMenu, QActionGroup
from functools import partial
from ....libs import tools_qt, tools_db
from ...utils import tools_gw


class GwManageCampaignLotButton(GwAction):
    """ Button 87: Campaign Management """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):
        super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.campaign_manager = Campaign(icon_path, action_name, text, toolbar, action_group)
        self.new_lot = AddNewLot(icon_path, action_name, text, toolbar, action_group)
        self.workorder_manager = Workorder(icon_path, action_name, text, toolbar, action_group)

        self.actions = [tools_qt.tr('Manage Campaign'), tools_qt.tr('Manage Lot'), tools_qt.tr('Manage Workorder')]

        # Conditionally remove menu options based on user role
        cm_roles = tools_gw.get_cm_user_role()
        is_cm_admin = tools_db.check_role_user('role_addon_cm_admin')
        if cm_roles:
            cm_role_list = list(cm_roles)
            if 'role_addon_cm_edit' in cm_role_list:
                self.actions.remove(tools_qt.tr('Manage Lot'))
        if not is_cm_admin:
            self.actions.remove(tools_qt.tr('Manage Campaign'))

        # Create a menu and add all the actions
        self.menu = QMenu()
        self.menu.setObjectName("GW_manage_campaign_lot")
        self._fill_action_menu()

        if toolbar is not None:
            self.action.setMenu(self.menu)
            toolbar.addAction(self.action)

    def _fill_action_menu(self):
        """ Fill action menu """
        actions = self.menu.actions()
        for action in actions:
            action.disconnect()
            self.menu.removeAction(action)
            del action

        ag = QActionGroup(self.iface.mainWindow())

        for action in self.actions:
            obj_action = QAction(f"{action}", ag)
            self.menu.addAction(obj_action)
            obj_action.triggered.connect(partial(self.clicked_event, action))

    def clicked_event(self, selected_action):
        """ Open the correct campaign dialog based on user selection """
        if selected_action == tools_qt.tr('Manage Campaign'):
            self.campaign_manager.campaign_manager()
        elif selected_action == tools_qt.tr('Manage Lot'):
            self.new_lot.lot_manager()
        elif selected_action == tools_qt.tr('Manage Workorder'):
            self.workorder_manager.workorder_manager()

