"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import configparser
import os
from functools import partial

from qgis.PyQt.sip import isdeleted
from qgis.PyQt.QtCore import QObject, Qt
from qgis.PyQt.QtGui import QIcon, QKeySequence
from qgis.PyQt.QtWidgets import QMenu, QPushButton, QTreeWidget, QTreeWidgetItem, QHeaderView
from qgis.core import QgsApplication

from .admin.i18n.i18n_languages import GwI18NManageLanguagesDialog
from .ui.ui_manager import GwLoadMenuUi
from .utils import tools_gw
from .. import global_vars
from ..libs import lib_vars, tools_qt, tools_qgis, tools_os, tools_db
from .threads.project_layers_config import GwProjectLayersConfig


class GwMenuLoad(QObject):

    def __init__(self):
        """ Class to manage layers. Refactor code from main.py """

        super().__init__()
        self.iface = global_vars.iface

    def read_menu(self, project_loaded):
        """  """

        actions = self.iface.mainWindow().menuBar().actions()
        last_action = actions[-1]

        self.main_menu = QMenu("&Giswater", self.iface.mainWindow().menuBar())
        self.main_menu.setObjectName("Giswater")
        self._language_menu_added = False

        icon_folder = f"{lib_vars.plugin_dir}{os.sep}icons"
        icon_path = f"{icon_folder}{os.sep}toolbars{os.sep}utilities{os.sep}99.png"
        config_icon = QIcon(icon_path)

        # region Actions
        actions_menu = QMenu(tools_qt.tr("Actions"), self.iface.mainWindow().menuBar())
        actions_menu.setIcon(config_icon)
        self.main_menu.addMenu(actions_menu)

        if project_loaded:
            # Action 'Get help'
            action_help = actions_menu.addAction(tools_qt.tr("Get help"))
            action_help_shortcut = tools_gw.get_config_parser("actions_shortcuts", "shortcut_help", "user", "init", prefix=False)
            if not action_help_shortcut:
                tools_gw.set_config_parser("actions_shortcuts", "shortcut_help", f"{action_help_shortcut}", "user", "init",
                                           prefix=False)
            action_help.setShortcut(QKeySequence(f"{action_help_shortcut}"))
            action_help.triggered.connect(tools_gw.open_dlg_help)

        # Action 'Reset dialogs'
        action_reset_dialogs = actions_menu.addAction(tools_qt.tr("Reset dialogs"))
        action_reset_dialogs.triggered.connect(self._reset_position_dialog)

        if project_loaded:
            # Action 'Reset plugin
            action_reset_plugin = actions_menu.addAction(tools_qt.tr("Reset plugin"))
            action_reset_plugin_shortcut = tools_gw.get_config_parser("actions_shortcuts", "shortcut_reset_plugin",
                "user", "init", prefix=False)
            if not action_reset_plugin_shortcut:
                tools_gw.set_config_parser("actions_shortcuts", "shortcut_reset_plugin",
                    f"{action_reset_plugin_shortcut}", "user", "init", prefix=False)
            action_reset_plugin.setShortcut(QKeySequence(f"{action_reset_plugin_shortcut}"))
            action_reset_plugin.triggered.connect(self._reset_plugin)

        # Action 'Toggle Log DB'
        action_set_log_sql = actions_menu.addAction(tools_qt.tr("Toggle Log DB"))
        log_sql_shortcut = tools_gw.get_config_parser("actions_shortcuts", "shortcut_toggle_log_db", "user", "init", prefix=False)
        if not log_sql_shortcut:
            tools_gw.set_config_parser("actions_shortcuts", "shortcut_toggle_log_db", f"{log_sql_shortcut}", "user",
                "init", prefix=False)
        action_set_log_sql.setShortcut(QKeySequence(f"{log_sql_shortcut}"))
        action_set_log_sql.triggered.connect(self._set_log_sql)
        # endregion

        # region Open plugin folder
        if lib_vars.plugin_dir:
            icon_path = f"{icon_folder}{os.sep}dialogs{os.sep}108.png"
            folder_icon = QIcon(icon_path)
            action_open_plugin_path = self.main_menu.addAction(tools_qt.tr("Open plugin folder"))
            action_open_plugin_path.setIcon(folder_icon)
            action_open_plugin_path.triggered.connect(self._open_plugin_path)
        # endregion

        # region Advanced
        action_manage_file = self.main_menu.addAction(tools_qt.tr("Advanced"))
        action_manage_file.triggered.connect(self._open_manage_file)
        icon_path = f"{icon_folder}{os.sep}dialogs{os.sep}105.png"
        folder_icon = QIcon(icon_path)
        action_manage_file.setIcon(folder_icon)
        # endregion

        # region Open user folder
        if lib_vars.user_folder_dir:
            log_folder = f"{lib_vars.user_folder_dir}{os.sep}core{os.sep}log"
            size = tools_os.get_folder_size(log_folder)
            log_folder_volume = f"{round(size / (1024 * 1024), 2)} MB"
            icon_path = f"{icon_folder}{os.sep}dialogs{os.sep}102.png"
            folder_icon = QIcon(icon_path)
            open_user_folder = tools_qt.tr("Open user folder")
            action_open_path = self.main_menu.addAction(f"{open_user_folder} ({log_folder_volume})")
            action_open_path.setIcon(folder_icon)
            action_open_path.triggered.connect(self._open_config_path)
        # endregion

        # region Language
        if project_loaded:
            self._add_language_menu()
        # endregion

        self.iface.mainWindow().menuBar().insertMenu(last_action, self.main_menu)

    def _clicked_event(self, action_function):

        action_function.clicked_event()

    def _translate(self, message):
        """ Calls on tools_qt to translate parameter message """

        return tools_qt.tr(message)

    # region private functions

    def _open_language_dialog(self):
        """Open language management dialog."""
        dlg = getattr(self, 'dlg_i18n_languages', None)
        if dlg is not None and not isdeleted(dlg) and dlg.isVisible():
            tools_gw.focus_open_dialog(dlg)
            return

        dlg = GwI18NManageLanguagesDialog(self)
        dlg.init_dialog()
        self.dlg_i18n_languages = dlg

    def _add_language_menu(self):
        """Add language menu to main menu when a database connection is active."""
        if getattr(self, '_language_menu_added', False):
            return
        if not getattr(self, 'main_menu', None):
            return
        if not tools_gw.check_db_connection():
            return

        icon_folder = f"{lib_vars.plugin_dir}{os.sep}icons"
        icon_path = f"{icon_folder}{os.sep}dialogs{os.sep}184.svg"
        language_icon = QIcon(icon_path)
        title = "Language"
        action_language = self.main_menu.addAction(tools_qt.tr(title))
        action_language.setIcon(language_icon)
        action_language.triggered.connect(self._open_language_dialog)
        self._language_menu_added = True

    def _open_config_path(self):
        """ Opens the OS-specific Config directory """

        path = os.path.realpath(lib_vars.user_folder_dir)
        status, message = tools_os.open_file(path)
        if status is False and message is not None:
            tools_qgis.show_warning(message, parameter=path)

    def _open_plugin_path(self):
        """ Opens the OS-specific Plugin directory """

        path = os.path.realpath(lib_vars.plugin_dir)
        status, message = tools_os.open_file(path)
        if status is False and message is not None:
            tools_qgis.show_warning(message, parameter=path)

    def _open_manage_file(self):
        """ Manage files dialog:: """

        tools_qgis.set_cursor_wait()
        self.dlg_manage_menu = GwLoadMenuUi(self)
        tools_gw.load_settings(self.dlg_manage_menu)

        # Manage widgets
        self.tree_config_files = self.dlg_manage_menu.findChild(QTreeWidget, 'tree_config_files')
        self.btn_close = self.dlg_manage_menu.findChild(QPushButton, 'btn_close')

        # Fill table_config_files
        self._fill_tbl_config_files()

        # Listeners
        self.btn_close.clicked.connect(partial(self.dlg_manage_menu.reject))
        self.dlg_manage_menu.rejected.connect(partial(tools_gw.close_dialog, self.dlg_manage_menu))

        tools_qgis.restore_cursor()

        msg = ("Changes on this page are dangerous and can break Giswater plugin in various ways. \n"
                  "You will need to restart QGIS or reload Giswater plugin to apply changes. Do you want continue?")
        title = "Advanced Menu"
        answer = tools_qt.show_question(msg, title)
        if not answer:
            return

        # Resize columns
        header = self.tree_config_files.header()
        header.setSectionResizeMode(QHeaderView.ResizeMode.ResizeToContents)

        # Open dialog
        tools_gw.open_dialog(self.dlg_manage_menu, dlg_name='load_menu', title="Advanced Menu", skip_db_check=True)

    def _reset_position_dialog(self):
        """ Reset position dialog x/y """
        tools_gw.reset_position_dialog(True)

    def _fill_tbl_config_files(self):
        """ Fills a UI table with the local list of values variable. """

        self.tree_config_files.resize(500, 200)
        self.tree_config_files.setColumnCount(4)
        self.tree_config_files.setHeaderLabels(["Section", "Parameter", "Value", "Description"])
        self.tree_config_files.itemDoubleClicked.connect(partial(self._double_click_event))
        self.tree_config_files.itemChanged.connect(partial(self._set_config_value))

        path = f"{lib_vars.user_folder_dir}{os.sep}core{os.sep}config"
        files = [f for f in os.listdir(path) if os.path.isfile(os.path.join(path, f)) and f != 'user_params.config'
                 and '.bak' not in f]
        for file in files:
            item = QTreeWidgetItem([f"{file}"])

            project_types = tools_gw.get_config_parser('system', 'project_types', "project", "giswater")
            parser = configparser.ConfigParser(comment_prefixes=';', allow_no_value=True, strict=False)
            parser.read(f"{lib_vars.user_folder_dir}{os.sep}core{os.sep}config{os.sep}{file}")

            # For each section we create a sub-item and add all the parameters to that sub-item
            for section in parser.sections():
                subitem = QTreeWidgetItem([f"{section}"])
                item.addChild(subitem)
                for parameter in parser[section]:
                    if parameter[0:2] in project_types and global_vars.project_type != parameter[0:2]:
                        continue
                    value = parser[section][parameter]
                    values = {}
                    values["Section"] = ""
                    values["Parameter"] = parameter
                    values["Value"] = value.split("#")[0].strip() if value is not None and "#" in value else value
                    values["Description"] = value.split("#")[1].strip() if value is not None and "#" in value else ""
                    if value is None:
                        values["Value"] = ""

                    item_child = QTreeWidgetItem([f"{values['Section']}",
                                                  f"{values['Parameter']}",
                                                  f"{values['Value']}",
                                                  f"{values['Description']}"])
                    subitem.addChild(item_child)

            self.tree_config_files.addTopLevelItem(item)

        # Sort items on QTreeWidget
        for index in range(self.tree_config_files.topLevelItemCount()):
            # Obtain the actual top-level item
            top_level_item = self.tree_config_files.topLevelItem(index)
            # Sort
            top_level_item.sortChildren(0, Qt.SortOrder.AscendingOrder)

    def _set_config_value(self, item, column):

        if column == 2:
            file_name = item.parent().parent().text(0).replace(".config", "")
            section = item.parent().text(0)
            parameter = item.text(1)
            value = item.text(2)
            if value == '':
                value = "None"
            tools_gw.set_config_parser(section, parameter, value, file_name=file_name, prefix=False, chk_user_params=False)

    def _double_click_event(self, item, column):

        tmp = item.flags()
        if column == 2 and item.text(2):
            item.setFlags(tmp | Qt.ItemFlag.ItemIsEditable)

    def _set_log_sql(self):

        log_sql = tools_gw.get_config_parser("log", "log_sql", "user", "init", False, get_none=True)
        if log_sql in ("False", "None"):
            msg = "Variable log_sql from user config file has been enabled."
            tools_gw.set_config_parser("log", "log_sql", "True", file_name="init", prefix=False)
        else:
            msg = "Variable log_sql from user config file has been disabled."
            tools_gw.set_config_parser("log", "log_sql", "None", file_name="init", prefix=False)

        tools_qgis.show_info(msg)

    def _reset_plugin(self):
        """ Called in reset plugin action """

        self._reset_snapping_managers()
        self._reset_all_rubberbands()
        tools_qgis.restore_cursor()  # Restore cursor in case it's stuck with an overridden one
        self.iface.actionPan().trigger()  # Force actionPan action
        self._reload_layers()  # Execute GwProjectLayersConfig thread

    def _reload_layers(self):
        """ Reloads all the layers """

        # Manage if task is already running
        if hasattr(self, 'task_get_layers') and self.task_get_layers is not None:
            try:
                if self.task_get_layers.isActive():
                    msg = "{0} task is already active!"
                    msg_params = ("ConfigLayerFields")
                    tools_qgis.show_warning(msg, msg_params=msg_params)
                    return
            except RuntimeError:
                pass

        schema_name = lib_vars.schema_name.replace('"', '')
        sql = (f"SELECT DISTINCT(parent_layer) FROM cat_feature "
               f"UNION "
               f"SELECT DISTINCT(child_layer) FROM cat_feature "
               f"WHERE child_layer IN ("
               f"     SELECT table_name FROM information_schema.tables"
               f"     WHERE table_schema = '{schema_name}')")
        rows = tools_db.get_rows(sql)
        description = "ConfigLayerFields"
        params = {"project_type": global_vars.project_type, "schema_name": lib_vars.schema_name, "db_layers": rows,
                  "qgis_project_infotype": lib_vars.project_vars['info_type']}
        self.task_get_layers = GwProjectLayersConfig(description, params)
        QgsApplication.taskManager().addTask(self.task_get_layers)
        QgsApplication.taskManager().triggerTask(self.task_get_layers)

    def _reset_snapping_managers(self):
        """ Deactivates all snapping managers """

        for i in range(0, len(global_vars.snappers)):
            global_vars.snappers[i].vertex_marker.hide()

    def _reset_all_rubberbands(self):
        """ Resets all active rubber bands """

        for i in range(0, len(global_vars.active_rubberbands)):
            global_vars.active_rubberbands[0].reset()
            global_vars.active_rubberbands.pop(0)

    # endregion
