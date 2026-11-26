"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from .campaign import Campaign
from ..dialog import GwAction
from qgis.PyQt.QtCore import QPoint
from qgis.PyQt.QtWidgets import QAction, QMenu, QActionGroup, QWidget
from functools import partial
from ....libs import tools_qt, tools_db
from ...utils import tools_gw
import json


class GwAddCampaignButton(GwAction):
    """ Button 84: Add new campaign """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):
        super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.new_campaign = Campaign(icon_path, action_name, text, toolbar, action_group)

        # Check user role
        roles = tools_gw.get_cm_user_role()
        is_cm_edit_role = roles and 'role_addon_cm_edit' in list(roles)

        if is_cm_edit_role:
            # For 'role_addon_cm_edit', the button directly creates an 'inventory' campaign
            self.action.triggered.connect(lambda: self.clicked_event(tools_qt.tr("Inventory")))
            if toolbar is not None:
                toolbar.addAction(self.action)
            return

        # Fetch and parse the campaign type configuration from the database for other roles
        config_query = "SELECT value FROM cm.config_param_system WHERE parameter = 'admin_campaign_type'"
        config_result = tools_db.get_row(config_query)

        show_review = True
        show_visit = True

        if config_result and config_result['value']:
            try:
                config = json.loads(config_result['value'])
                show_review = config.get('campaignReview', 'true').lower() == 'true'
                show_visit = config.get('campaignVisit', 'true').lower() == 'true'
            except (json.JSONDecodeError, KeyError):
                # Fallback to default if JSON is malformed
                pass

        # If both are false, default to showing only Review
        if not show_review and not show_visit:
            show_review = True

        # Conditional logic for button creation
        if show_review and show_visit:
            # Both are true: create a dropdown menu
            self.actions = [tools_qt.tr('Review'), tools_qt.tr('Visit')]
            self.menu = QMenu()
            self.menu.setObjectName("GW_create_campaign")
            self._fill_action_menu()

            if toolbar is not None:
                self.action.setMenu(self.menu)
                toolbar.addAction(self.action)
        else:
            self.menu = None
            # Only one is true: create a simple button
            if show_review:
                self.action.triggered.connect(partial(self.clicked_event, tools_qt.tr("Review")))
            elif show_visit:
                self.action.triggered.connect(partial(self.clicked_event, tools_qt.tr("Visit")))

            if toolbar is not None:
                toolbar.addAction(self.action)

    def _fill_action_menu(self):
        """ Fill action menu """
        if self.menu is None:
            return

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

        # Handle direct campaign creation (for simple buttons or menu selections)
        if selected_action in (tools_qt.tr("Review"), tools_qt.tr("Visit"), tools_qt.tr("Inventory")):
            if self.menu is not None:
                self.menu.setProperty("last_selection", selected_action.lower())

            # Create the campaign
            if selected_action == tools_qt.tr("Review"):
                self.new_campaign.create_campaign(dialog_type="review")
            elif selected_action == tools_qt.tr("Visit"):
                self.new_campaign.create_campaign(dialog_type="visit")
            elif selected_action == tools_qt.tr("Inventory"):
                self.new_campaign.create_campaign(dialog_type="inventory")
            return

        # Handle button click when menu is present
        if self.menu is not None:
            last_selection = self.menu.property('last_selection')
            if last_selection is not None:
                self.new_campaign.create_campaign(dialog_type=last_selection)
            else:
                if hasattr(self.action, 'associatedObjects'):
                    button = QWidget(self.action.associatedObjects()[1])
                elif hasattr(self.action, 'associatedWidgets'):
                    button = self.action.associatedWidgets()[1]
                menu_point = button.mapToGlobal(QPoint(0, button.height()))
                self.menu.popup(menu_point)
