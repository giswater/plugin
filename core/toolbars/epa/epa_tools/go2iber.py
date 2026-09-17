"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import importlib
import os
from datetime import timedelta
from functools import partial
from time import time

from qgis.core import QgsApplication, QgsVectorLayer
from qgis.PyQt.QtCore import QTimer
from qgis.PyQt.QtWidgets import (
    QLabel,
)
from qgis.PyQt.sip import isdeleted
from qgis.core import QgsProject
from pathlib import Path

from ....ui.ui_manager import GwGo2IberUi
from ....threads.go2iber_task import GwGo2IberTask
from ....utils import tools_gw
from .....libs import tools_db, tools_qgis, tools_qt


CREATE_NEW = "Create new"
TESTING_MODE = False


class Go2Iber:
    """Button 47: Go2Iber"""

    def __init__(self) -> None:
        self.ibergis_folder = tools_qgis.get_plugin_folder("IberGIS")
        self.ig_options_class = importlib.import_module('.options', package=f'{self.ibergis_folder}.core.shared') if self.ibergis_folder else None
        self.ig_tools_db = importlib.import_module('.tools_db', package=f'{self.ibergis_folder}.lib') if self.ibergis_folder else None

    def clicked_event(self) -> None:
        """Start the Import INP workflow"""

        self.dlg_go2iber = GwGo2IberUi(self)
        tools_gw.load_settings(self.dlg_go2iber)
        if self.ig_options_class is None:
            msg = "IBERGIS plugin not found"
            tools_qgis.show_warning(msg)
            return

        # Fill user values
        self._fill_user_values()

        # Fill mesh combo
        sql = "SELECT id,name as idval FROM cat_file"
        rows = self.ig_tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_go2iber.cmb_mesh, rows, 1)

        # Connect signals
        self.dlg_go2iber.btn_path.clicked.connect(partial(tools_qt.get_folder_path, self.dlg_go2iber, self.dlg_go2iber.txt_path))
        self.dlg_go2iber.btn_swmm_options.clicked.connect(partial(self._btn_swmm_options_clicked))
        self.dlg_go2iber.btn_iber_options.clicked.connect(partial(self._btn_iber_options_clicked))
        self.dlg_go2iber.btn_accept.clicked.connect(partial(self._btn_accept_clicked))
        self.dlg_go2iber.btn_cancel.clicked.connect(partial(self._btn_cancel_clicked))

        # Open dialog
        tools_gw.open_dialog(self.dlg_go2iber, dlg_name='go2iber')

    def _btn_swmm_options_clicked(self):
        # tools_gw.execute_class_function(GwGo2EpaUI, '_go2epa_options')
        from ..go2epa_btn import GwGo2EpaButton
        self.go2epa_btn = GwGo2EpaButton(None, None, None, None, None)
        self.go2epa_btn._go2epa_options()

    def _btn_iber_options_clicked(self):
        if self.ig_options_class is None:
            msg = "IBERGIS plugin not found"
            tools_qgis.show_warning(msg)
            return
        self.ig_options = self.ig_options_class.DrOptions(tabs_to_show=["tab_main", "tab_rpt_iber", "tab_plugins"])
        self.ig_options.open_options_dlg()

    def _btn_accept_clicked(self):
        """ Save INP, RPT and result name"""

        # Set network mode to 2
        form = '"formName":"epaoptions"'
        my_json = '[{"widget": "inp_options_networkmode", "value": "2"}]'
        extras = f'"fields":{my_json}'
        body = tools_gw.create_body(form=form, extras=extras)
        tools_gw.execute_procedure('gw_fct_setconfig', body)

        # Manage if task is already running
        if hasattr(self, 'go2iber_task') and self.go2iber_task is not None:
            try:
                if self.go2iber_task.isActive():
                    msg = "Go2Iber task is already active!"
                    tools_qgis.show_warning(msg)
                    return
            except RuntimeError:
                pass

        mesh = tools_qt.get_combo_value(self.dlg_go2iber, 'cmb_mesh', 1)
        if mesh is None or mesh == "" or mesh == -1:
            msg = "You need to have a mesh"
            tools_qgis.show_warning(msg)
            return

        # Save user values
        self._save_user_values()

        self.dlg_go2iber.tab_log_txt_infolog.clear()
        self.dlg_go2iber.txt_result_name.setStyleSheet(None)
        self.dlg_go2iber.txt_path.setStyleSheet(None)
        status = self._check_fields()
        if status is False:
            return

        # Get widgets values
        self.result_name = tools_qt.get_text(self.dlg_go2iber, self.dlg_go2iber.txt_result_name, False, False)
        self.folder_path = tools_qt.get_text(self.dlg_go2iber, self.dlg_go2iber.txt_path)

        # Check for sector selector
        sql = "SELECT sector_id FROM selector_sector WHERE sector_id > 0 LIMIT 1"
        row = tools_db.get_row(sql)
        if row is None:
            msg = "You need to select some sector"
            tools_qt.show_info_box(msg)
            return

        self.dlg_go2iber.btn_accept.setEnabled(False)
        self.dlg_go2iber.btn_cancel.setEnabled(True)

        # Create timer
        self.t0 = time()
        self.timer = QTimer()
        self.timer.timeout.connect(partial(self._calculate_elapsed_time, self.dlg_go2iber))
        self.timer.start(1000)

        # Set background task 'Go2Iber'
        description = "Go2Iber"
        # TODO: Thread that
        #         - Generate INP file with Giswater (go2iber)
        #         - Execute model with IBERGIS plugin
        #         - Import results to IBERGIS mainly, but rpt to Giswater
        self.go2iber_task = GwGo2IberTask(description, self, timer=self.timer)
        # self.go2iber_task.step_completed.connect(self.step_completed)
        QgsApplication.taskManager().addTask(self.go2iber_task)
        QgsApplication.taskManager().triggerTask(self.go2iber_task)

    def _btn_cancel_clicked(self):

        tools_gw.close_dialog(self.dlg_go2iber)

    def _save_user_values(self):
        """ Save dialog widgets' values """

        txt_result_name = f"{tools_qt.get_text(self.dlg_go2iber, 'txt_result_name', return_string_null=False)}"
        tools_gw.set_config_parser('btn_go2iber', 'go2iber_result_name', f"{txt_result_name}")
        txt_path = f"{tools_qt.get_text(self.dlg_go2iber, 'txt_path', return_string_null=False)}"
        tools_gw.set_config_parser('btn_go2iber', 'go2iber_path', f"{txt_path}")

    def _fill_user_values(self):
        """ Fill dialog widgets' values """
        txt_result_name = tools_gw.get_config_parser('btn_go2iber', 'go2iber_result_name', 'user', 'session')
        if txt_result_name:
            tools_qt.set_widget_text(self.dlg_go2iber, 'txt_result_name', txt_result_name)
        txt_path = tools_gw.get_config_parser('btn_go2iber', 'go2iber_path', 'user', 'session')
        if txt_path:
            tools_qt.set_widget_text(self.dlg_go2iber, 'txt_path', txt_path)

    def _check_fields(self):

        folder_path = tools_qt.get_text(self.dlg_go2iber, self.dlg_go2iber.txt_path)
        result_name = tools_qt.get_text(self.dlg_go2iber, self.dlg_go2iber.txt_result_name, False, False)

        # Check if at least one process is selected
        # export_checked = tools_qt.is_checked(self.dlg_go2iber, self.dlg_go2iber.chk_export)
        # exec_checked = tools_qt.is_checked(self.dlg_go2iber, self.dlg_go2iber.chk_exec)
        # import_result_checked = tools_qt.is_checked(self.dlg_go2iber, self.dlg_go2iber.chk_import_result)

        # if not export_checked and not exec_checked and not import_result_checked:
        #     msg = "You need to select at least one process"
        #     tools_qt.show_info_box(msg, title="go2iber")
        #     return False

        # Control result name
        if result_name == '':
            self.dlg_go2iber.txt_result_name.setStyleSheet("border: 1px solid red")
            msg = "This parameter is mandatory. Please, set a value"
            title = "Result name"
            tools_qt.show_details(msg, title, inf_text=None)
            return False

        # Control folder path
        if folder_path == '':
            self.dlg_go2iber.txt_path.setStyleSheet("border: 1px solid red")
            msg = "This parameter is mandatory. Please, set a value"
            title = "Folder path"
            tools_qt.show_details(msg, title, inf_text=None)
            return False

        self.dlg_go2iber.txt_result_name.setStyleSheet(None)

        sql = (f"SELECT result_id FROM rpt_cat_result "
               f"WHERE result_id = '{result_name}' LIMIT 1")
        row = tools_db.get_row(sql)
        if row:
            msg = "Result name already exists, do you want overwrite?"
            title = "Alert"
            answer = tools_qt.show_question(msg, title)
            if not answer:
                return False

        return True

    def _calculate_elapsed_time(self, dialog):

        tf = time()  # Final time
        td = tf - self.t0  # Delta time
        msg = "Exec. time: {0}"
        msg_params = (timedelta(seconds=round(td)),)
        self._update_time_elapsed(tools_qt.tr(msg, list_params=msg_params), dialog)

    def _update_time_elapsed(self, text, dialog):

        if isdeleted(dialog):
            self.timer.stop()
            return

        lbl_time = dialog.findChild(QLabel, 'lbl_time')
        lbl_time.setText(text)

    def check_ibergis_project(self) -> bool:
        gpkg_path = tools_qgis.get_project_variable('project_gpkg_path')
        if not gpkg_path or not os.path.exists(f"{QgsProject.instance().absolutePath()}{os.sep}{gpkg_path}"):
            return False
        return True

    def load_project(self, file_path: Path) -> bool:
        """ Load IberGIS project """

        import_layers = {
            'MESH': ['ground', 'roof', 'mesh_anchor_lines', 'mesh_anchor_points'],
            'IBER': ['culvert', 'bridge', 'boundary_conditions', 'hyetograph']
        }

        plugin_folder = tools_qgis.find_plugin_path("ibergis")
        for group_name, layers in import_layers.items():
            for layer_name in layers:
                layer = QgsVectorLayer(f"{file_path}|layername={layer_name}", layer_name.capitalize().replace("_", " "), "ogr")
                qml_name = layer_name + '.qml'
                qml_path = f"{plugin_folder}{os.sep}resources{os.sep}templates{os.sep}{qml_name}"
                if not os.path.exists(qml_path):
                    msg = "QML file {0} not found"
                    msg_params = (qml_path,)
                    tools_qgis.show_warning(msg, msg_params=msg_params)
                else:
                    layer.loadNamedStyle(qml_path)
                tools_qgis.add_layer_to_toc(layer, group=f'IBERGIS - {os.path.basename(file_path)}', sub_group=group_name, create_groups=True, custom_properties={"gw_id": layer_name})

        # Save project path
        relative_path = os.path.relpath(file_path, QgsProject.instance().absolutePath())
        tools_qgis.set_project_variable('project_gpkg_path', relative_path)

        # Reload plugin
        import qgis.utils
        plugin_name = tools_qgis.get_plugin_folder('IberGIS')
        if plugin_name not in qgis.utils.plugins:
            qgis.utils.loadPlugin(plugin_name)
        else:
            qgis.utils.reloadPlugin(plugin_name)

        return True
