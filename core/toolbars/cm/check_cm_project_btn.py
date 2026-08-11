"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from .project_check_cm import GwProjectCheckCMTask
from ..dialog import GwAction

from qgis.PyQt.QtWidgets import QLabel, QTabWidget, QWidget, QTextEdit, QComboBox
from qgis.core import QgsApplication

from ...utils import tools_gw
from ....libs import tools_qgis, tools_qt, tools_db
from ...ui.ui_manager import CheckProjectCmUi


class GwCheckCMProjectButton(GwAction):
    """ Button 89: Check Project CM """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):
        super().__init__(icon_path, action_name, text, toolbar, action_group)

    def clicked_event(self):
        self._open_check_project()

    # region private functions

    def _open_check_project(self):
        """Fetches form configuration, dynamically populates widgets, and opens the dialog."""

        # Define the form type and create the body
        form_type = "check_project_cm"
        body = tools_gw.create_body(form=f'"formName":"generic","formType":"{form_type}"')

        # Fetch dialog configuration from the database
        json_result = tools_gw.execute_procedure('gw_fct_cm_get_dialog', body, schema_name='cm')

        # Check for a valid result
        if not json_result or json_result.get("status") != "Accepted":
            msg = "Failed to fetch dialog configuration"
            tools_qgis.show_warning(msg, dialog=self.dialog if hasattr(self, 'dialog') else None, context_name="cm")
            return

        # Store the dialog as an instance variable to prevent garbage collection
        self.dialog = CheckProjectCmUi(self)
        tools_gw.load_settings(self.dialog)

        # Populate the dialog with fields
        tools_gw.populate_dynamic_widgets(self.dialog, json_result, self)

        # Find widgets
        self.campaign_combo = self.dialog.findChild(QComboBox, "tab_data_campaign")
        self.lot_combo = self.dialog.findChild(QComboBox, "tab_data_lot")

        campagin_combo_value = tools_gw.get_config_parser('check_project_cm', 'campaign_combo', "user", "session")
        lot_combo_value = tools_gw.get_config_parser('check_project_cm', 'lot_combo', "user", "session")

        if campagin_combo_value not in (None, 'None', ''):
            tools_qt.set_combo_value(self.campaign_combo, campagin_combo_value, 0)
        if lot_combo_value not in (None, 'None', ''):
            tools_qt.set_combo_value(self.lot_combo, lot_combo_value, 0)

        # Set listeners
        self.dialog.btn_accept.clicked.connect(self._on_accept_clicked)
        if self.campaign_combo:
            self.campaign_combo.currentIndexChanged.connect(self._on_campaign_changed)

        # Initial population of the lot combo
        self._on_campaign_changed()

        # Disable the "Log" tab initially
        tools_gw.disable_tab_log(self.dialog)

        # Hide progress bar and timer label initially
        self.dialog.progressBar.setVisible(False)
        lbl_time = self.dialog.findChild(QLabel, "lbl_time")
        if lbl_time:
            lbl_time.setVisible(False)

        # Open the dialog
        tools_gw.open_dialog(self.dialog, dlg_name=form_type)

    def _on_campaign_changed(self):
        """Populates the lot combo based on the selected campaign."""
        if not self.campaign_combo or not self.lot_combo:
            return

        # Block signals to prevent unwanted events while we modify the combo
        self.lot_combo.blockSignals(True)

        try:
            self.lot_combo.clear()
            self.lot_combo.addItem("", None)  # Always add an empty option first

            current_data = self.campaign_combo.currentData()
            if not current_data:
                return  # No campaign selected, lot combo should just have the empty option

            # currentData is a list [id, name], we only need the id
            campaign_id = current_data[0]
            if not campaign_id:
                return  # The selected campaign has no ID, so nothing to do

            # Fetch lots for the selected campaign
            query = f"SELECT lot_id AS id, name AS idval FROM cm.om_campaign_lot WHERE campaign_id = {campaign_id} ORDER BY name"
            result = tools_db.get_rows(query)

            # Populate the lot combo box with results
            if result:
                for row in result:
                    self.lot_combo.addItem(str(row['idval']), row['id'])
        finally:
            # Always unblock signals when we are done
            self.lot_combo.blockSignals(False)

    def _on_accept_clicked(self):
        """Handles the Accept button click event and starts the project check task."""
        self._start_project_check()

    def _start_project_check(self):
        """Re-executes the project check process after Accept is pressed."""

        # Manage if task is already running
        if hasattr(self, 'project_check_task') and self.project_check_task is not None:
            try:
                if self.project_check_task.isActive():
                    message = "Project check task is already active!"
                    tools_qgis.show_warning(message)
                    return
            except RuntimeError:
                pass

        # Retrieve layers in the same order as listed in TOC
        layers = tools_qgis.get_project_layers()

        # Find the log widget and pass it directly to the task for reliability
        log_widget = self.dialog.findChild(QTextEdit, "tab_log_txt_infolog")

        campaign_id = tools_qt.get_combo_value(self.dialog, "tab_data_campaign", index=0)
        lot_id = tools_qt.get_combo_value(self.dialog, "tab_data_lot", index=-1)
        check_management_configs = self.dialog.chk_manage_config.isChecked()
        # Always perform data-related checks
        check_data_related = True

        # Set parameters and re-run the project check task.
        params = {"layers": layers, "init_project": "false", "dialog": self.dialog,
                  "log_widget": log_widget, "campaign_id": campaign_id, "lot_id": lot_id,
                  "check_management_configs": check_management_configs, "check_data_related": check_data_related}

        # Save dialog values
        self._save_dlg_values()

        self.project_check_task = GwProjectCheckCMTask('check_project_cm', params)

        # Connect task signals to UI updates
        self.project_check_task.task_started.connect(self._on_task_started)
        self.project_check_task.task_finished.connect(self._on_task_finished)

        QgsApplication.taskManager().addTask(self.project_check_task)

    def _on_task_started(self):
        """Disables controls and shows progress indicators when the task starts."""
        self.dialog.btn_accept.setEnabled(False)

        # Find the QTabWidget and the specific tab to switch to
        tab_widget = self.dialog.findChild(QTabWidget, "mainTab")
        log_tab = self.dialog.findChild(QWidget, "tab_log")
        if tab_widget and log_tab:
            tab_widget.setCurrentWidget(log_tab)

        tools_qt.enable_tab_by_tab_name(self.dialog.mainTab, "tab_data", False)
        self.dialog.progressBar.setVisible(True)
        self.dialog.lbl_time.setVisible(True)

    def _on_task_finished(self):
        """Enables controls and hides progress indicators when the task is complete."""
        self.dialog.btn_accept.setEnabled(True)
        tools_qt.enable_tab_by_tab_name(self.dialog.mainTab, "tab_data", True)
        self.dialog.progressBar.setVisible(False)
        self.dialog.lbl_time.setVisible(False)

    def _save_dlg_values(self):
        """ Save dialog values """

        campaign_combo = tools_qt.get_combo_value(self.dialog, "tab_data_campaign", index=0)
        lot_combo = tools_qt.get_combo_value(self.dialog, "tab_data_lot", index=-1)

        tools_gw.set_config_parser('check_project_cm', 'campaign_combo', campaign_combo)
        tools_gw.set_config_parser('check_project_cm', 'lot_combo', lot_combo)

    # endregion

