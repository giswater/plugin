"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import os
from functools import partial

from qgis.core import QgsProject, QgsApplication, QgsSnappingUtils, QgsVectorLayer, QgsEditFormConfig, QgsAttributeEditorContainer, \
                    QgsAttributeEditorField, QgsEditorWidgetSetup, Qgis
from qgis.PyQt.QtCore import QObject, Qt, QEvent
from qgis.PyQt.QtWidgets import QToolBar, QActionGroup, QDockWidget, QApplication, QDialog, QComboBox, QPushButton, QMenu, QAction

from .models.plugin_toolbar import GwPluginToolbar
from .toolbars import buttons
from .utils import tools_gw
from .threads.project_layers_config import GwProjectLayersConfig
from .threads.project_check import GwProjectCheckTask
from .shared.psector import GwPsector
from .shared.search import GwSearchLocatorFilter
from .. import global_vars
from ..libs import lib_vars, tools_qgis, tools_log, tools_db, tools_qt, tools_os


class GwLoadProject(QObject):

    def __init__(self):
        """ Class to manage layers. Refactor code from main.py """

        super().__init__()
        self.iface = global_vars.iface
        self.plugin_toolbars = {}
        self.buttons_to_hide = []
        self.buttons = {}
        self.is_role_cm_edit = False
        self.manage_new_psector = None
        self.selected_psector_id: int | None = None
        self.gw_locator_filter = None

    def project_read(self, show_warning=True, main=None):
        """ Function executed when a user opens a QGIS project (*.qgs) """

        global_vars.project_loaded = False
        if show_warning:
            msg = "Project read started"
            tools_log.log_info(msg)

        self._get_user_variables()
        # Get variables from qgis project
        self._get_project_variables()

        # Check if loaded project is valid for Giswater
        if not self._check_project(show_warning):
            return False

        # Force commit before opening project and set new database connection
        if not self._check_database_connection(show_warning):
            return

        # Get SRID from table node
        lib_vars.data_epsg = tools_db.get_srid('ve_node', lib_vars.schema_name)

        # Manage schema name
        tools_db.get_current_user()
        layer_source = tools_qgis.get_layer_source(self.layer_node)
        schema_name = layer_source['schema']
        if schema_name:
            lib_vars.schema_name = schema_name.replace('"', '')

        # Set PostgreSQL parameter 'search_path'
        tools_db.set_search_path(layer_source['schema'])

        # Get water software from table 'sys_version'
        global_vars.project_type = tools_gw.get_project_type()
        if global_vars.project_type is None:
            return

        # Check if loaded project is ud or ws
        if not self._check_project_type():
            return

        # Removes all deprecated variables defined at giswater.config
        tools_gw.remove_deprecated_config_vars()

        project_role = lib_vars.project_vars.get('project_role')
        lib_vars.project_vars['project_role'] = tools_gw.get_role_permissions(project_role)

        # Check if user has config files 'init' and 'session' and its parameters
        tools_gw.user_params_to_userconfig()

        # Check for developers options
        value = tools_gw.get_config_parser('log', 'log_sql', "user", "init", False)
        tools_qgis.user_parameters['log_sql'] = value
        value = tools_gw.get_config_parser('system', 'show_message_durations', "user", "init", False)
        tools_qgis.user_parameters['show_message_durations'] = value

        # Manage locale and corresponding 'i18n' file
        lib_vars.plugin_name = tools_qgis.get_plugin_metadata('name', 'giswater', lib_vars.plugin_dir)
        tools_qt._add_translator(True)

        # Check if schema exists
        schema_exists = tools_db.check_schema(lib_vars.schema_name)
        if not schema_exists:
            msg = "Selected schema not found"
            tools_qgis.show_warning(msg, parameter=lib_vars.schema_name)

        # Check that there are no layers (ve_node) with the same view name, coming from different schemes
        status = self._check_layers_from_distinct_schema()
        if status is False:
            return

        # Connect project save / new project
        try:
            tools_gw.connect_signal(self.iface.newProjectCreated, main._project_new,
                                    'main', 'newProjectCreated')
            tools_gw.connect_signal(self.iface.actionSaveProject().triggered, self._save_toolbars_position,
                                    'main', 'actionSaveProject_save_toolbars_position')
        except AttributeError:
            pass

        # Create menu
        tools_gw.create_giswater_menu(True)
        self._register_locator_filter()

        # Manage actions of the different plugin_toolbars
        self._manage_toolbars()

        # Manage "btn_updateall" from attribute table
        self._manage_attribute_table()

        # call dynamic mapzones repaint
        tools_gw.set_style_mapzones()

        # Check roles of this user to show or hide toolbars
        self._check_user_roles()

        # Create Psector status bar
        self._create_psector_status_bar()

        # Check parameter 'force_tab_expl'
        force_tab_expl = tools_gw.get_config_parser('system', 'force_tab_expl', 'user', 'init', prefix=False)
        if tools_os.set_boolean(force_tab_expl, False):
            self._force_tab_exploitation()

        # Set lib_vars.project_epsg
        lib_vars.project_epsg = tools_qgis.get_epsg()
        tools_gw.connect_signal(QgsProject.instance().crsChanged, tools_gw.set_epsg,
                                'load_project', 'project_read_crsChanged_set_epsg')
        global_vars.project_loaded = True

        # Set indexing strategy for snapping so that it uses less memory if possible
        self.iface.mapCanvas().snappingUtils().setIndexingStrategy(QgsSnappingUtils.IndexingStrategy.IndexHybrid)

        # Activate snapping
        tools_qgis.set_project_snapping_settings(enabled=True)

        # Manage versions of Giswater and PostgreSQL
        plugin_version = tools_qgis.get_plugin_metadata('version', 0, lib_vars.plugin_dir)
        project_version = tools_gw.get_project_version(schema_name)

        # Compare major.minor versions
        try:
            plugin_version_l = str(plugin_version).split('.')
            project_version_l = str(project_version).split('.')
            plugin_major_minor = f'{plugin_version_l[0]}.{plugin_version_l[1]}'
            project_major_minor = f'{project_version_l[0]}.{project_version_l[1]}'

            if plugin_major_minor == project_major_minor:
                msg = "Project read finished"
                tools_log.log_info(msg)
            else:
                msg = ("Project read finished with different versions on plugin metadata ({0}) and "
                      "PostgreSQL sys_version table ({1}).")
                msg_params = (plugin_version, project_version,)
                tools_log.log_warning(msg, msg_params=msg_params)
                tools_qgis.show_warning(msg, msg_params=msg_params)
        except Exception:
            msg = "Project read finished"
            tools_log.log_info(msg)

        # Reset dialogs position
        tools_gw.reset_position_dialog()

        # Manage compatibility version of Giswater
        self._check_version_compatibility()

        # Call gw_fct_setcheckproject and create GwProjectLayersConfig thread
        self._config_layers()

        # Apply campaign form configuration
        self._apply_campaign_form_config()

    # region private functions

    def _save_toolbars_position(self):
        # Get all QToolBar from qgis iface
        widget_list = self.iface.mainWindow().findChildren(QToolBar)
        own_toolbars = []

        # Get list with own QToolBars
        for w in widget_list:
            if w.property('gw_name'):
                own_toolbars.append(w)

        # Order list of toolbar in function of X position
        own_toolbars = sorted(own_toolbars, key=lambda k: k.x())
        if len(own_toolbars) == 0 or (len(own_toolbars) == 1 and own_toolbars[0].property('gw_name') == 'toc') or \
                global_vars.project_type is None:
            return

        # Set 'toolbars_order' parameter on 'toolbars_position' section on init.config user file (found in user path)
        sorted_toolbar_ids = [tb.property('gw_name') for tb in own_toolbars]
        sorted_toolbar_ids = ",".join(sorted_toolbar_ids)
        tools_gw.set_config_parser('toolbars_position', 'toolbars_order', str(sorted_toolbar_ids), "user", "init")

    def _register_locator_filter(self):
        if self.gw_locator_filter is not None:
            return
        if not hasattr(self.iface, 'registerLocatorFilter'):
            return
        try:
            self.gw_locator_filter = GwSearchLocatorFilter()
            self.iface.registerLocatorFilter(self.gw_locator_filter)
        except Exception as e:
            self.gw_locator_filter = None
            tools_log.log_warning(str(e))

    def unregister_locator_filter(self):
        if self.gw_locator_filter is None:
            return
        if not hasattr(self.iface, 'deregisterLocatorFilter'):
            self.gw_locator_filter = None
            return
        try:
            self.iface.deregisterLocatorFilter(self.gw_locator_filter)
        except Exception as e:
            tools_log.log_warning(str(e))
        self.gw_locator_filter = None

    def _check_version_compatibility(self):

        # Get PostgreSQL versions
        postgresql_version = tools_db.get_pg_version()
        pgrouting_version = tools_db.get_pgrouting_version()

        # Get version compatiblity from metadata.txt
        minorPgVersion = tools_qgis.get_plugin_metadata('minorPgVersion', '9.5', lib_vars.plugin_dir).replace('.', '')
        majorPgVersion = tools_qgis.get_plugin_metadata('majorPgVersion', '11.99', lib_vars.plugin_dir).replace('.', '')
        minorPgrVersion = tools_qgis.get_plugin_metadata('minorPgrVersion', '3.8.0', lib_vars.plugin_dir).replace('.', '')

        url_wiki = "https://github.com/giswater/plugin/wiki/Version-compatibility"
        if postgresql_version is not None and minorPgVersion is not None and majorPgVersion is not None:
            if int(postgresql_version) < int(minorPgVersion) or int(postgresql_version) > int(majorPgVersion):
                msg = "PostgreSQL version is not compatible with Giswater. Please check wiki"
                tools_qgis.show_message_link(msg, url_wiki, message_level=Qgis.MessageLevel.Warning, btn_text="Open wiki")
        if pgrouting_version is not None and minorPgrVersion is not None:
            if int(str(pgrouting_version).replace('.', '')) < int(minorPgrVersion):
                msg = "pgRouting version is not compatible with Giswater. Please check wiki"
                tools_qgis.show_message_link(msg, url_wiki, message_level=Qgis.MessageLevel.Warning, btn_text="Open wiki")

    def _get_project_variables(self):
        """ Manage QGIS project variables """

        lib_vars.project_vars = {}
        lib_vars.project_vars['info_type'] = tools_qgis.get_project_variable('gwInfoType')
        lib_vars.project_vars['add_schema'] = tools_qgis.get_project_variable('gwAddSchema')
        lib_vars.project_vars['main_schema'] = tools_qgis.get_project_variable('gwMainSchema')
        lib_vars.project_vars['cm_schema'] = tools_qgis.get_project_variable('gwCmSchema')
        lib_vars.project_vars['project_role'] = tools_qgis.get_project_variable('gwProjectRole')
        lib_vars.project_vars['project_type'] = tools_qgis.get_project_variable('gwProjectType')
        lib_vars.project_vars['store_credentials'] = tools_qgis.get_project_variable('gwStoreCredentials')
        lib_vars.project_vars['current_style'] = tools_qgis.get_project_variable('gwCurrentStyle')

    def _get_user_variables(self):
        """ Get config related with user variables """

        lib_vars.user_level['level'] = tools_gw.get_config_parser('user_level', 'level', "user", "init", False)
        lib_vars.user_level['showquestion'] = tools_gw.get_config_parser('user_level', 'showquestion', "user", "init", False)
        lib_vars.user_level['showsnapmessage'] = tools_gw.get_config_parser('user_level', 'showsnapmessage', "user", "init", False)
        lib_vars.user_level['showselectmessage'] = tools_gw.get_config_parser('user_level', 'showselectmessage', "user", "init", False)
        lib_vars.user_level['showadminadvanced'] = tools_gw.get_config_parser('user_level', 'showadminadvanced', "user", "init", False)
        lib_vars.date_format = tools_gw.get_config_parser('system', 'date_format', "user", "init", False)

    def _check_project(self, show_warning):
        """ Check if loaded project is valid for Giswater """

        # Check if table 've_node' is loaded
        self.layer_node = tools_qgis.get_layer_by_tablename("ve_node")
        layer_arc = tools_qgis.get_layer_by_tablename("ve_arc")
        if (self.layer_node, layer_arc) == (None, None):  # If no gw layers are present
            return False

        # Check missing layers
        missing_layers = {}
        if self.layer_node is None:
            missing_layers['ve_node'] = True
        if layer_arc is None:
            missing_layers['ve_arc'] = True

        # Show message if layers are missing
        if missing_layers:
            if show_warning:
                title = "Giswater plugin cannot be loaded"
                msg = f"QGIS project seems to be a Giswater project, but layer(s) {0} are missing"
                msg_params = ([k for k, v in missing_layers.items()],)
                tools_qgis.show_warning(msg, 20, title=title, msg_params=msg_params)
            return False

        return True

    def _check_project_type(self):
        """ Check if loaded project is valid for Giswater """
        # Check if table 've_node' is loaded
        if global_vars.project_type not in ('ws', 'ud'):
            return False

        addparam = tools_gw.get_sysversion_addparam()
        if addparam:
            add_type = addparam.get("type")
            if add_type and add_type.lower() not in ("ws", "ud"):
                global_vars.project_loaded = True
                return False

        return True

    def _check_database_connection(self, show_warning, force_commit=False):
        """ Set new database connection. If force_commit=True then force commit before opening project """

        try:
            if tools_db.dao and force_commit:
                msg = "Force commit"
                tools_log.log_info(msg)
                tools_db.dao.commit()
        except Exception as e:
            tools_log.log_info(str(e))
        finally:
            self.connection_status, not_version, layer_source = tools_db.set_database_connection()
            if not self.connection_status or not_version:
                message = lib_vars.session_vars['last_error']
                if show_warning:
                    if message:
                        tools_qgis.show_warning(message, 15)
                    tools_log.log_warning(str(layer_source))
                return False

            return True

    def _check_layers_from_distinct_schema(self):
        """
            Checks if there are duplicate layers in any of the defined schemas from project_vars.

            :returns: False if there are duplicate layers and project_vars main_schema or add_schema
            haven't been set.
        """

        layers = tools_qgis.get_project_layers()
        repeated_layers = {}
        for layer in layers:
            layer_toc_name = tools_qgis.get_layer_source_table_name(layer)
            if layer_toc_name == 've_node':
                layer_source = tools_qgis.get_layer_source(layer)
                repeated_layers[layer_source['schema'].replace('"', '')] = 've_node'

        if len(repeated_layers) > 1:
            if lib_vars.project_vars['main_schema'] in (None, '', 'null', 'NULL') \
                    or lib_vars.project_vars['add_schema'] in (None, '', 'null', 'NULL'):
                msg = ("QGIS project has more than one {0} layer coming from different schemas. "
                      "If you are looking to manage two schemas, it is mandatory to define which is the master and "
                      "which isn't. To do this, you need to configure the QGIS project setting this project's "
                      "variables: {1} and {2}.")
                msg_params = ("ve_node", "gwMainSchema", "gwAddSchema")
                tools_qt.show_info_box(msg, msg_params=msg_params)
                return False

            # If there are layers with a different schema, the one that the user has in the project variable
            # 'gwMainSchema' is taken as the schema_name.
            if lib_vars.project_vars['main_schema'] not in (None, 'NULL', ''):
                lib_vars.schema_name = lib_vars.project_vars['main_schema']

        return True

    def _get_buttons_to_hide(self):
        """ Get all buttons to hide """

        buttons_to_hide = None
        try:
            row = tools_gw.get_config_parser('toolbars_hidebuttons', 'buttons_to_hide', "user", "init")
            if not row or row in (None, 'None'):
                return None

            buttons_to_hide = [int(x) for x in row.split(',')]

        except Exception as e:
            msg = "{0}: {1}"
            msg_params = (type(e).__name__, str(e),)
            tools_log.log_warning(msg, msg_params=msg_params)
        finally:
            return buttons_to_hide

    def _manage_toolbars(self):
        """ Manage actions of the custom plugin toolbars """

        # Dynamically get list of toolbars from config file
        toolbar_names = tools_gw.get_config_parser('toolbars', 'list_toolbars', "project", "giswater")
        if toolbar_names in (None, 'None'):
            msg = "Parameter '{0}' is None"
            msg_params = ("toolbar_names",)
            tools_log.log_info(msg, msg_params=msg_params)
            return

        toolbars_order = tools_gw.get_user_config_or_default('init', 'toolbars_position', 'toolbars_order')

        if toolbars_order in (None, 'None'):
            msg = "Parameter '{0}' is None"
            msg_params = ("toolbars_order",)
            tools_log.log_info(msg, msg_params=msg_params)
            return

        # Call each of the functions that configure the toolbars 'def toolbar_xxxxx(self, toolbar_id, x=0, y=0):'
        toolbars_order_list = toolbars_order.replace(' ', '').split(',')
        config_was_updated = False

        # Check for optional toolbars
        for toolbar_id in ('am', 'cm'):
            is_active = tools_gw.get_config_parser('toolbars_add', f'{toolbar_id}_active', 'user', 'init', False)
            if tools_os.set_boolean(is_active, False):
                if toolbar_id not in toolbars_order_list:
                    toolbars_order_list.append(toolbar_id)
                    config_was_updated = True

        if config_was_updated:
            new_toolbars_order = ",".join(toolbars_order_list)
            tools_gw.set_config_parser('toolbars_position', 'toolbars_order', new_toolbars_order, "user", "init")

        for tb in toolbars_order_list:
            self._create_toolbar(tb)

        # Manage action group of every toolbar
        icon_folder = f"{lib_vars.plugin_dir}{os.sep}icons{os.sep}toolbars{os.sep}"
        parent = self.iface.mainWindow()
        for plugin_toolbar in list(self.plugin_toolbars.values()):
            ag = QActionGroup(parent)
            ag.setProperty('gw_name', 'gw_QActionGroup')
            for index_action in plugin_toolbar.list_actions:
                successful = False
                attempt = 0
                while not successful and attempt < 10:
                    button_def = tools_gw.get_config_parser('buttons_def', str(index_action), "project", "giswater")
                    if button_def not in (None, 'None'):
                        # Check if the class associated to the button definition exists
                        if hasattr(buttons, button_def):
                            text = tools_qt.tr(f'{button_def}')
                            icon_path = f"{icon_folder}{os.sep}{plugin_toolbar.toolbar_id}{os.sep}{index_action}.png"
                            button_class = getattr(buttons, button_def)
                            button = button_class(icon_path, button_def, text, plugin_toolbar.toolbar, ag)
                            self.buttons[index_action] = button
                        successful = True
                    attempt = attempt + 1

        # Disable buttons which are project type exclusive
        project_exclude = None
        successful = False
        attempt = 0
        while not successful and attempt < 10:
            project_exclude = tools_gw.get_config_parser('project_exclude', global_vars.project_type, "project", "giswater")
            if project_exclude not in (None, "None"):
                successful = True
            attempt = attempt + 1

        if project_exclude not in (None, 'None'):
            project_exclude = project_exclude.replace(' ', '').split(',')
            for index in project_exclude:
                self._hide_button(index)

        # Hide buttons from buttons_to_hide
        buttons_to_hide = self._get_buttons_to_hide()
        if buttons_to_hide:
            for button_id in buttons_to_hide:
                self._hide_button(button_id)

        # Disable and hide all plugin_toolbars and actions
        self._enable_toolbars(False)

        # Enable toolbars: 'basic', 'utilities', 'toc'
        self._enable_toolbar("basic")
        self._enable_toolbar("utilities")
        self._enable_toolbar("toc")
        self._enable_toolbar("am")
        self._enable_toolbar("cm")

        # Check if audit exists
        sql = "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'audit'"
        rows = tools_db.get_rows(sql, commit=False)

        # Check if schema is actived
        schema_actived = tools_gw.get_config_parser('toolbars_add', 'audit_active', 'user', 'init', False)
        schema_actived = tools_os.set_boolean(schema_actived, False)

        if rows is None or schema_actived is False:
            self._hide_button(68)

    def _create_toolbar(self, toolbar_id):
        """Create and register a toolbar, with special CM/AM schema checks."""

        # Load toolbar actions from your config
        list_actions = tools_gw.get_config_parser(
            'toolbars', str(toolbar_id), "project", "giswater"
        )
        if list_actions in (None, 'None'):
            return

        list_actions = list_actions.replace(' ', '').split(',')
        if not isinstance(list_actions, list):
            list_actions = [list_actions]
        if toolbar_id == "basic":
            list_actions = [action for action in list_actions if action != "03"]

        # Prepare toolbar object
        toolbar_name = tools_qt.tr(f'toolbar_{toolbar_id}_name')
        plugin_toolbar = GwPluginToolbar(toolbar_id, toolbar_name, True)

        # Special case: ToC lives in the Layers panel
        if toolbar_id == "toc":
            plugin_toolbar.toolbar = (
                self.iface
                .mainWindow()
                .findChild(QDockWidget, 'Layers')
                .findChildren(QToolBar)[0]
            )

        # CM & AM both need schema‐existence checks
        elif toolbar_id in ("cm", "am"):
            schema_to_check = toolbar_id

            # If CM, read the JSON‐stored schema name
            if toolbar_id == "cm":
                rows = tools_db.get_rows(
                    "SELECT (value::json)->> 'schemaName' AS schemaName "
                    "FROM config_param_system "
                    "WHERE parameter = 'admin_schema_cm'",
                )
                if rows and rows[0] and rows[0][0]:
                    schema_to_check = rows[0][0].strip()
                else:
                    schema_to_check = None

            # Only proceed if we got a non‐empty schema name
            if schema_to_check:
                # Check that schema exists in Postgres
                exists = tools_db.get_rows(
                    f"SELECT 1 FROM information_schema.schemata WHERE schema_name = '{schema_to_check}'")

                flag = tools_gw.get_config_parser(
                    'toolbars_add',
                    f'{toolbar_id}_active',
                    'user',
                    'init',
                    False
                )
                active = tools_os.set_boolean(flag, False)

                if exists and active:
                    plugin_toolbar.toolbar = self.iface.addToolBar(toolbar_name)

        # All other toolbars just get created normally
        else:
            plugin_toolbar.toolbar = self.iface.addToolBar(toolbar_name)

        # Finalize: register and optionally hide/disable immediately
        if getattr(plugin_toolbar, 'toolbar', None):
            plugin_toolbar.toolbar.setObjectName(toolbar_name)
            plugin_toolbar.toolbar.setProperty('gw_name', toolbar_id)
            plugin_toolbar.list_actions = list_actions
            self.plugin_toolbars[toolbar_id] = plugin_toolbar
            self._enable_toolbar(toolbar_id)

    def _create_psector_status_bar(self):
        """Create Psector status bar with play/pause button and psector combobox."""
        # Check if Masterplan (plan) toolbar is loaded
        plan_toolbar = self.plugin_toolbars.get('plan')
        if not plan_toolbar or not plan_toolbar.toolbar:
            return

        statusbar = self.iface.mainWindow().statusBar()

        # Initialize psector manager
        self.manage_new_psector = GwPsector()

        # Play/pause button
        self.playpause_button = QPushButton()
        tools_gw.add_icon(self.playpause_button, "73", f"toolbars{os.sep}status")
        self.playpause_button.setProperty('psector_active', False)
        self.playpause_button.clicked.connect(self._playpause_btn_clicked)
        statusbar.insertPermanentWidget(0, self.playpause_button)

        # Psector combobox
        self.cmb_psector = QComboBox()
        self.cmb_psector.setMinimumWidth(200)
        self.cmb_psector.setMaximumWidth(200)
        self.cmb_psector.setMaxVisibleItems(15)
        tools_gw.fill_cmb_psector_id(self.cmb_psector)

        # Configure scroll bar to always show when needed
        self.cmb_psector.view().setVerticalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOn)

        # Overwrite showPopup for upward popup
        original_show_popup = self.cmb_psector.showPopup

        def show_popup_upward():
            original_show_popup()
            view = self.cmb_psector.view()
            popup = view.window()
            rect = self.cmb_psector.rect()
            global_pos = self.cmb_psector.mapToGlobal(rect.topLeft())

            # Calculate popup height based on maxVisibleItems
            item_height = view.sizeHintForRow(0) if self.cmb_psector.count() > 0 else 24
            max_visible = self.cmb_psector.maxVisibleItems()
            visible_count = min(self.cmb_psector.count(), max_visible)
            popup_height = visible_count * item_height + 4  # +4 for border

            # Position popup above the combo box
            popup.move(global_pos.x(), global_pos.y() - popup_height)
            popup.resize(self.cmb_psector.width(), popup_height)
        self.cmb_psector.showPopup = show_popup_upward

        statusbar.insertPermanentWidget(1, self.cmb_psector)

        # Add right-click context menu to combobox popup
        self.cmb_psector.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.cmb_psector.customContextMenuRequested.connect(self._cmb_psector_context_menu_closed)
        self.cmb_psector.view().viewport().installEventFilter(self)

        # Register these widgets globally if needed
        global_vars.psignals['widgets'] = [self.playpause_button, self.cmb_psector]

    def eventFilter(self, obj, event):
        """Filter events to handle right-click on combo box popup."""
        if not hasattr(self, 'cmb_psector') or self.cmb_psector is None:
            return super().eventFilter(obj, event)

        try:
            if obj == self.cmb_psector.view().viewport():
                if event.type() == QEvent.Type.MouseButtonPress and event.button() == Qt.MouseButton.RightButton:
                    view = self.cmb_psector.view()
                    index = view.indexAt(event.pos())
                    if index.isValid():
                        self.selected_psector_id = self.cmb_psector.model().data(index, Qt.ItemDataRole.UserRole)
                    global_pos = obj.mapToGlobal(event.pos())
                    self._cmb_psector_context_menu(global_pos)
                    return True
        except RuntimeError:
            # Object has been deleted
            return super().eventFilter(obj, event)

        return super().eventFilter(obj, event)

    def _cmb_psector_context_menu_closed(self, pos):
        """Context menu for cmb_psector when menu requested (closed popup)."""
        idx = self.cmb_psector.currentIndex()
        if idx >= 0:
            self.selected_psector_id = self.cmb_psector.itemData(idx, Qt.ItemDataRole.UserRole)
        self._show_psector_menu(self.cmb_psector.mapToGlobal(pos))

    def _cmb_psector_context_menu(self, pos):
        """Context menu for cmb_psector when open (from eventFilter)."""
        self._show_psector_menu(pos)

    def _show_psector_menu(self, global_pos):
        """Composes and shows the psector context menu at the given global position."""
        menu = QMenu(self.cmb_psector)
        act_zoom = QAction("Zoom to psector", self.cmb_psector)
        act_open = QAction("Open psector", self.cmb_psector)
        act_zoom.triggered.connect(lambda: self._execute_menu_action("zoom"))
        act_open.triggered.connect(lambda: self._execute_menu_action("open"))
        menu.addAction(act_zoom)
        menu.addAction(act_open)
        action = menu.exec(global_pos)
        if action:
            self.cmb_psector.hidePopup()

    def _execute_menu_action(self, action_type):
        """Execute the selected action from the context menu."""
        self.cmb_psector.hidePopup()
        psector_id = self.selected_psector_id if not isinstance(self.selected_psector_id, (tuple, list)) else self.selected_psector_id[0]
        if not psector_id:
            return
        if action_type == "zoom":
            self.manage_new_psector.zoom_to_psector(psector_id)
        elif action_type == "open":
            self.manage_new_psector.get_psector(psector_id)

    def _playpause_btn_clicked(self):
        """ Manage psector play/pause """
        tools_gw.set_psector_mode_enabled()

    def _manage_snapping_layers(self):
        """ Manage snapping of layers """

        tools_qgis.manage_snapping_layer('ve_arc', snapping_type=2)
        tools_qgis.manage_snapping_layer('ve_connec', snapping_type=0)
        tools_qgis.manage_snapping_layer('ve_node', snapping_type=0)
        tools_qgis.manage_snapping_layer('ve_gully', snapping_type=0)

    def _check_user_roles(self):
        """ Check user roles and show/hide toolbars """
        self.is_role_cm_edit = False

        # Check cm role and adjust CM toolbar if necessary
        cm_role = tools_gw.get_cm_user_role()
        is_cm_admin = tools_db.check_role_user('role_cm_admin')
        if cm_role:
            cm_role_list = list(cm_role)
            if 'role_cm_edit' in cm_role_list:
                self.is_role_cm_edit = True
                # Hide buttons not wanted for role_cm_edit
                self._hide_button('86', True)  # GwAddLotButton
                self._hide_button('87', True)  # GwLotResourceManagementButton

        if not is_cm_admin:
            # Hide buttons not wanted for non-admin CM roles (DB role check)
            self._hide_button('84', True)  # GwAddCampaignButton
            # Button 87 (GwManageCampaignLotButton) menu option "Manage Campaign"

        # Let the standard project role logic run for everyone
        project_role = lib_vars.project_vars.get('project_role')

        if project_role == 'role_basic':
            return

        elif project_role == 'role_om':
            self._enable_toolbar("om")
            return

        elif project_role == 'role_edit':
            self._enable_toolbar("om")
            self._enable_toolbar("edit")

        elif project_role == 'role_epa':
            self._enable_toolbar("om")
            self._enable_toolbar("edit")
            self._enable_toolbar("epa")

        elif project_role == 'role_plan' or project_role == 'role_admin' or project_role == 'role_system':
            self._enable_toolbar("om")
            self._enable_toolbar("edit")
            self._enable_toolbar("epa")
            self._enable_toolbar("plan")

    def _config_layers(self):
        """ Call gw_fct_setcheckproject and create GwProjectLayersConfig thread """

        status, result = self._manage_layers()
        if not status:
            return False
        if result:
            variables = result['body'].get('variables')
            if variables:
                setQgisLayers = variables.get('setQgisLayers')
                if setQgisLayers in (False, 'False', 'false'):
                    return

        # Set project layers with gw_fct_getinfofromid: This process takes time for user
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
        # Set background task 'ConfigLayerFields'
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

        return True

    def _manage_layers(self):
        """ Get references to project main layers """

        # Check if we have any layer loaded
        layers = tools_qgis.get_project_layers()
        if len(layers) == 0:
            return False

        if global_vars.project_type in ('ws', 'ud'):
            QApplication.setOverrideCursor(Qt.CursorShape.ArrowCursor)
            self.check_project = GwProjectCheckTask()

            # check project
            status, result = self.check_project.fill_check_project_table(layers, "true")
            try:
                variables = result['body'].get('variables')
                if variables:
                    guided_map = variables.get('useGuideMap')
                    if guided_map:
                        msg = "{0}"
                        msg_params = ("manage_guided_map",)
                        tools_log.log_info(msg, msg_params=msg_params)
                        self._manage_guided_map()
            except Exception as e:
                tools_log.log_info(str(e))
            finally:
                QApplication.restoreOverrideCursor()
                return status, result

        return True

    def _manage_guided_map(self):
        """ Guide map works using v_municipality """

        self.layer_muni = tools_qgis.get_layer_by_tablename('v_municipality')
        if self.layer_muni is None:
            return

        self.iface.setActiveLayer(self.layer_muni)
        tools_qgis.set_layer_visible(self.layer_muni)
        self.layer_muni.selectAll()
        self.layer_muni.removeSelection()
        self.iface.actionSelect().trigger()
        tools_gw.connect_signal(self.iface.mapCanvas().selectionChanged, self._selection_changed,
                                'load_project', 'manage_guided_map_mapCanvas_selectionChanged_selection_changed')
        cursor = tools_gw.get_cursor_multiple_selection()
        if cursor:
            self.iface.mapCanvas().setCursor(cursor)

    def _selection_changed(self):
        """ Get selected muni_id and execute function setselectors """

        muni_id = None
        features = self.layer_muni.getSelectedFeatures()
        for feature in features:
            muni_id = feature["muni_id"]
            msg = "Selected {0}"
            msg_params = ("muni_id",)
            tools_log.log_info(msg, parameter=muni_id, msg_params=msg_params)
            break

        tools_gw.disconnect_signal('load_project', 'manage_guided_map_mapCanvas_selectionChanged_selection_changed')
        self.iface.actionZoomToSelected().trigger()
        self.layer_muni.removeSelection()

        if muni_id is None:
            return

        extras = f'"selectorType":"explfrommuni", "id":{muni_id}, "value":true, "isAlone":true, '
        extras += f'"addSchema":"{lib_vars.project_vars["add_schema"]}"'
        body = tools_gw.create_body(extras=extras)
        complet_result = tools_gw.execute_procedure('gw_fct_setselectors', body)
        if complet_result:
            self.iface.mapCanvas().refreshAllLayers()
            self.layer_muni.triggerRepaint()
            self.iface.actionPan().trigger()
            # Zoom to feature
            try:
                x1 = complet_result['body']['data']['geometry']['x1']
                y1 = complet_result['body']['data']['geometry']['y1']
                x2 = complet_result['body']['data']['geometry']['x2']
                y2 = complet_result['body']['data']['geometry']['y2']
                if x1 is not None:
                    tools_qgis.zoom_to_rectangle(x1, y1, x2, y2, margin=0)
            except KeyError:
                pass
            tools_gw.set_style_mapzones()

    def _enable_toolbars(self, visible=True):
        """ Enable/disable all plugin toolbars from QGIS GUI """

        # Enable/Disable actions
        self._enable_all_buttons(visible)
        try:
            for plugin_toolbar in list(self.plugin_toolbars.values()):
                if plugin_toolbar.enabled:
                    plugin_toolbar.toolbar.setVisible(visible)
        except Exception as e:
            tools_log.log_warning(str(e))

    def _enable_all_buttons(self, enable=True):
        """ Utility to enable/disable all buttons """

        for index in self.buttons.keys():
            self._enable_button(index, enable)

    def _enable_button(self, button_id, enable=True):
        """ Enable/disable selected button """

        key = str(button_id).zfill(2)
        if key in self.buttons:
            self.buttons[key].action.setEnabled(enable)

    def _hide_button(self, button_id, hide=True):
        """ Enable/disable selected action """

        key = str(button_id).zfill(2)
        if key in self.buttons:
            self.buttons[key].action.setVisible(not hide)

    def _enable_toolbar(self, toolbar_id, enable=True):
        """ Enable/Disable toolbar. Normally because user has no permission """

        if toolbar_id in self.plugin_toolbars:
            plugin_toolbar = self.plugin_toolbars[toolbar_id]
            plugin_toolbar.toolbar.setVisible(enable)
            for index_action in plugin_toolbar.list_actions:
                self._enable_button(index_action, enable)

    def _force_tab_exploitation(self):
        """ Select tab 'tab_exploitation' in dialog 'dlg_selector_basic' """

        tools_gw.set_config_parser("dialogs_tab", "dlg_selector_basic", "tab_exploitation", "user", "session")

    def _manage_attribute_table(self):
        """ If configured, disable button "Update all" from attribute table """

        disable = tools_gw.get_config_parser('system', 'disable_updateall_attributetable', "user", "init", prefix=False)
        if tools_os.set_boolean(disable, False):
            tools_gw.connect_signal(QApplication.instance().focusChanged, self._manage_focus_changed,
                                    'load_project', 'manage_attribute_table_focusChanged')

    def _manage_focus_changed(self, old, new):
        """ Disable button "Update all" of QGIS attribute table dialog. Parameters are passed by the signal itself. """

        if new is None or not hasattr(new, 'window'):
            return

        table_dialog = new.window()
        # Check if focused widget's window is a QgsAttributeTableDialog
        if isinstance(table_dialog, QDialog) and table_dialog.objectName().startswith('QgsAttributeTableDialog'):
            try:
                # Look for the button "Update all"
                for widget in table_dialog.children():
                    if widget.objectName() == 'mUpdateExpressionBox':
                        widget_btn_updateall = None
                        for subwidget in widget.children():
                            if subwidget.objectName() == 'mRunFieldCalc':  # This is for the button itself
                                widget_btn_updateall = subwidget
                                tools_qt.set_widget_enabled(None, widget_btn_updateall, False)
                            if subwidget.objectName() == 'mUpdateExpressionText':  # This is the expression text field
                                try:
                                    subwidget.fieldChanged.disconnect()
                                except Exception:
                                    pass
                                # When you type something in the expression text field, the button "Update all" is
                                # enabled. This will disable it again.
                                subwidget.fieldChanged.connect(partial(
                                    tools_qt.set_widget_enabled, None, widget_btn_updateall, False))
                        break
            except IndexError:
                pass

    # region Campaign form config

    def _apply_campaign_form_config(self):
        """
        Applies custom form configurations from the cm_form_config table to project layers.
        """

        if not tools_db.check_schema('cm'):
            return

        # Require USAGE on cm; avoid error popups
        has_usage = tools_db.get_row(
            "SELECT has_schema_privilege(current_user, 'cm', 'USAGE')",
            is_admin=True,
        )
        if not has_usage or not has_usage[0]:
            return

        sql = "SELECT campaign_id FROM cm.selector_campaign WHERE cur_user = current_user LIMIT 1"
        rows = tools_db.get_rows(sql, is_thread=True)
        campaign_id = rows[0][0] if rows else None

        if not campaign_id:
            return

        sql = (
            "SELECT layer_name, field_name, field_order, is_hidden "
            "FROM cm.cm_form_config "
            f"WHERE {campaign_id} = ANY(campaign_ids) "
            "ORDER BY layer_name, field_order"
        )
        try:
            config_rows = tools_db.get_rows(sql)
        except Exception:
            # The table might not exist in older versions
            return

        if not config_rows:
            return

        # Group configuration by layer
        configs_by_layer = {}
        for layer_name, field_name, field_order, is_hidden in config_rows:
            configs_by_layer.setdefault(layer_name, []).append(
                {"field": field_name, "hidden": bool(is_hidden)}
            )

        for layer_name, cfg_fields in configs_by_layer.items():
            layer = tools_qgis.get_layer_by_tablename(layer_name)
            if layer and isinstance(layer, QgsVectorLayer):
                self._configure_layer_form(layer, cfg_fields)

    def _configure_layer_form(self, layer, cfg_fields):
        """
        Applies a given form configuration to a single QgsVectorLayer.
        """

        # Build order list: configured first, then the rest
        configured_map = {f["field"]: f for f in cfg_fields}
        configured_order = [f["field"] for f in cfg_fields]
        all_fields = [f.name() for f in layer.fields()]
        final_order = configured_order + [f for f in all_fields if f not in configured_map]

        # Put form in Drag&Drop mode and clear previous layout
        form_cfg = layer.editFormConfig()
        form_cfg.setLayout(QgsEditFormConfig.EditorLayout.TabLayout)
        form_cfg.clearTabs()

        # Main container
        main_tab = QgsAttributeEditorContainer(form_cfg.invisibleRootContainer())
        main_tab.setName("General")

        for fname in final_order:
            idx = layer.fields().indexOf(fname)
            if idx < 0:
                continue

            # Hidden
            hidden = fname in configured_map and configured_map[fname]["hidden"]
            if hidden:
                # Mark widget as Hidden and don't add it to the container
                layer.setEditorWidgetSetup(idx, QgsEditorWidgetSetup("Hidden", {}))
                continue
            else:
                # Ensure it's not left Hidden from a previous run
                current = layer.editorWidgetSetup(idx)
                if current.type() == "Hidden":
                    layer.setEditorWidgetSetup(idx, QgsEditorWidgetSetup("", {}))

            # Add visible field to the container in the desired order
            main_tab.addChildElement(QgsAttributeEditorField(fname, idx, main_tab))

        # Register container and apply
        form_cfg.addTab(main_tab)
        layer.setEditFormConfig(form_cfg)

    # endregion
