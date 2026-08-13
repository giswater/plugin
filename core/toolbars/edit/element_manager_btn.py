"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial

from qgis.PyQt.QtCore import Qt
from qgis.PyQt.QtWidgets import QTableView, QGridLayout
from qgis.core import Qgis

from ...utils import tools_gw
from ...ui.ui_manager import GwElementManagerUi
from ....libs import tools_qgis
from ..dialog import GwAction


class GwElementManagerButton(GwAction):
    """ Button 34: Element Manager """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):
        super().__init__(icon_path, action_name, text, toolbar, action_group)

    def clicked_event(self):
        """ Button 34: Edit element   
            Fetches form configuration, dynamically populates widgets, and opens the dialog."""

        # Define the form type and create the body
        form_type = "form_element"
        body = tools_gw.create_body(form=f'"formName":"element_manager","formType":"{form_type}"')

        # Fetch dialog configuration from the database
        json_result = tools_gw.execute_procedure('gw_fct_get_dialog', body)

        # Check for a valid result
        if not json_result or json_result.get("status") != "Accepted":
            msg = "Failed to fetch dialog configuration"
            tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=json_result)
            return
        self.complet_result = json_result

        # Store the dialog as an instance variable to prevent garbage collection
        self.dlg_mng = GwElementManagerUi(self)
        tools_gw.load_settings(self.dlg_mng)

        # Populate the dialog with fields
        self._populate_dynamic_widgets(self.dlg_mng, json_result)
        self.load_tableviews(self.complet_result)

        # Open the dialog
        tools_gw.open_dialog(self.dlg_mng, dlg_name='element_manager')

    def _populate_dynamic_widgets(self, dialog, complet_result):
        """Creates and populates all widgets dynamically into the dialog layout."""

        # Retrieve the tablename from the JSON response if available
        tablename = complet_result['body']['form'].get('tableName', 'default_table')
        old_widget_pos = 0
        layout_orientations = {}
        layout_list = []
        prev_layout = ""

        for layout_name, layout_info in complet_result['body']['form']['layouts'].items():
            orientation = layout_info.get('lytOrientation')
            if orientation:
                layout_orientations[layout_name] = orientation

        current_layout = ""
        previous_label = False

        # Loop through fields and add them to the appropriate layouts
        for field in complet_result['body']['data']['fields']:
            # Skip hidden fields
            if field.get('hidden'):
                continue

            # Pass required parameters (dialog, result, field, tablename, class_info)
            label, widget = tools_gw.set_widgets(dialog, complet_result, field, tablename, self)

            if widget is None:
                continue

            layout = self.dlg_mng.findChild(QGridLayout, field['layoutname'])
            if layout is not None:
                orientation = layout_orientations.get(layout.objectName(), "vertical")
                layout.setProperty('lytOrientation', orientation)
                if layout.objectName() != prev_layout:
                    prev_layout = layout.objectName()
                # Take the QGridLayout with the intention of adding a QSpacerItem later
                if layout not in layout_list and layout.objectName() in ('lyt_buttons', 'lyt_element_mng_1', 'lyt_element_mng_2'):
                    layout_list.append(layout)

                if field['layoutorder'] is None:
                    msg = "The field layoutorder is not configured for"
                    param = f"formname:form_element, columnname:{field['columnname']}"
                    tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=param, dialog=self.dlg_mng)
                    continue

                if current_layout != field['layoutname']:
                    current_layout = field['layoutname']
                    old_widget_pos = field['layoutorder']
                elif previous_label:
                    # If the previous widget was a label, adjust the position of the new widget
                    old_widget_pos = field['layoutorder']

                # Populate dialog widgets using lytOrientation field
                tools_gw.add_widget_combined(self.dlg_mng, field, label, widget, old_widget_pos)

                # Check if label is not None
                previous_label = label is not None

            elif field['layoutname'] != 'lyt_none':
                msg = "The field layoutname is not configured for"
                param = f"formname:form_element, columnname:{field['columnname']}"
                tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=param, dialog=self.dlg_mng)

            if isinstance(widget, QTableView):
                # Populate custom context menu
                widget.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
                widget.customContextMenuRequested.connect(partial(tools_gw._show_context_menu, widget, dialog))

    def load_tableviews(self, complet_result):
        list_tables = self.dlg_mng.findChildren(QTableView)
        complet_list = []
        for table in list_tables:
            widgetname = table.objectName()
            columnname = table.property('columnname')
            if columnname is None:
                msg = "widget {0} has not columnname and cant be configured"
                msg_params = (widgetname,)
                tools_qgis.show_info(msg, 3, msg_params=msg_params)
                continue
            linkedobject = table.property('linkedobject')
            complet_list, widget_list = tools_gw.fill_tbl(complet_result, self.dlg_mng, widgetname, linkedobject, '')
            if complet_list is False:
                return False
            tools_gw.set_filter_listeners(complet_result, self.dlg_mng, widget_list, columnname, widgetname)
