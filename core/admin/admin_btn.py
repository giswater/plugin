"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import json
import os
import re
import sys
from datetime import datetime
from functools import partial
from qgis.PyQt.sip import isdeleted
from time import time
from typing import Union

from qgis.PyQt.QtCore import QSettings, Qt, QTimer
from qgis.PyQt.QtGui import QPixmap
from qgis.PyQt.QtSql import QSqlTableModel, QSqlQueryModel
from qgis.PyQt.QtWidgets import QRadioButton, QAbstractItemView, QTextEdit, \
    QLineEdit, QWidget, QComboBox, QLabel, QCheckBox, QScrollArea, QSpinBox, QAbstractButton, \
    QHeaderView, QListView, QFrame, QScrollBar, QDoubleSpinBox, QPlainTextEdit, QGroupBox, QTableView, QDockWidget, \
    QGridLayout, QTabWidget, QDialog
from qgis.core import QgsProject, QgsApplication, QgsMessageLog, Qgis
from qgis.gui import QgsDateTimeEdit
from qgis.utils import reloadPlugin

from .gis_file_create import GwGisFileCreate
from ..threads.task import GwTask
from ..ui.ui_manager import GwAdminUi, GwAdminDbProjectUi, GwAdminRenameProjUi, GwAdminProjectInfoUi, \
    GwAdminFieldsUi, GwCredentialsUi, GwReplaceInFileUi, \
    GwAdminMarkdownGeneratorUi  # noqa: F401
    
from .i18n.language_packages_dialog import GwI18NManageLanguagesDialog
from .i18n import language_shared_functions as i18n_service

from ..utils import tools_gw
from ... import global_vars
from .markdown_generator import GwAdminMarkdownGenerator
from .i18n.hot_update_dialog import GwAdminI18NHotUpdate
from .import_osm import GwImportOsm
from ...libs import lib_vars, tools_qt, tools_qgis, tools_log, tools_db, tools_os
from ..ui.docker import GwDocker
from ..threads.schema_builder_task import GwSchemaBuilderTask, load_kind_manifest
from ..threads.multilang_schema_task import GwMultilangSchemaTask
from ..threads.project_schema_copy import GwCopySchemaTask
from ..threads.project_schema_rename import GwRenameSchemaTask
from ..threads.project_schema_vacuum import GwVacuumSchemaTask
from ..threads.admin_load_task import GwAdminLoadTask, AdminLoadResult, READ_EXTENSIONS
from ...giswater_admin.engine import (
    BuildParams,
    drop_schema as engine_drop_schema,
    format_upgrade_changelog,
    graph_has_linked_dependents,
    plan_lockstep,
    resolve_network_graph,
)
from ...giswater_admin.engine.network_update import LockstepStep
from ...giswater_admin.engine.version_guard import (
    assert_network_no_downgrade,
    assert_no_downgrade,
)
from ...giswater_admin.log_format import format_elapsed_mmss, format_lbl_time_status
from ._qt_db_adapter import QtDbAdapter
from . import _admin_catalog as admin_catalog


def _admin_version_tuple(version) -> tuple:
    """Major.minor.patch as ints for ordering; pad to 3 (same as engine _parse_version)."""
    parts = str(version or "0.0.0").split(".")
    nums = []
    for p in parts[:3]:
        try:
            nums.append(int(p))
        except ValueError:
            nums.append(0)
    while len(nums) < 3:
        nums.append(0)
    return tuple(nums)


_GIS_FORM_WIDGETS = (
    'txt_gis_file', 'txt_gis_folder', 'btn_gis_folder', 'chk_export_passwd', 'btn_gis_create',
)

_SCHEMA_CRUD_BUTTONS = (
    'btn_schema_create', 'btn_info', 'btn_schema_rename', 'btn_delete', 'btn_copy',
)

# Admin lbl_status_text sources (i18n context "giswater", i18n/giswater_*.ts)
_ADMIN_SCHEMA_OUTDATED_MESSAGE = "(Schema version is lower than plugin version, please update schema)"
_ADMIN_PLUGIN_OUTDATED_MESSAGE = "(Schema version is higher than plugin version, please update plugin)"
_ADMIN_SCHEMA_OUTDATED_NONADMIN_MESSAGE = (
    "(Schema version is lower than plugin version. Please contact your administrator to update the schema)"
)
_ADMIN_PLUGIN_OUTDATED_NONADMIN_MESSAGE = (
    "(Schema version is higher than plugin version. Please contact your administrator to update the plugin)"
)
_ADMIN_PERMISSION_MESSAGE = (
    "(You don't have permissions to administrate project schemas. Please contact your administrator)"
)
_ADMIN_EXTENSION_ERROR_MESSAGE = (
    "(Unable to create one extension. Packages must be installed, consult your administrator)"
)


def _admin_connection_ignore_widgets():
    return [
        'cmb_connection', 'project_schema_name', 'btn_close', 'btn_help',
        *_GIS_FORM_WIDGETS,
    ]


class GwAdminButton:

    def __init__(self):
        """ Class to control toolbar 'om_ws' """

        # Initialize instance attributes
        self.iface = global_vars.iface
        self.settings = global_vars.giswater_settings
        self.plugin_dir = lib_vars.plugin_dir
        self.schema_name = lib_vars.schema_name
        self.plugin_version, self.message = tools_qgis.get_plugin_version()
        self.canvas = global_vars.canvas
        self.project_type = None
        self.project_epsg = None
        self.dlg_readsql = None
        self.dlg_info = None
        self.dlg_readsql_create_project = None
        self.dlg_readsql_create_cm_project = None
        self.project_type_selected = None
        self.schema_type = None
        self.form_enabled = True
        self.lower_postgresql_version = int(tools_qgis.get_plugin_metadata('minorPgVersion', '9.5', lib_vars.plugin_dir)
                                            .replace('.', ''))
        self.upper_postgresql_version = int(tools_qgis.get_plugin_metadata('majorPgVersion', '14.99', lib_vars.plugin_dir)
                                            .replace('.', ''))
        self.total_sql_files = 0    # Total number of SQL files to process
        self.current_sql_file = 0   # Current number of SQL file
        self.progress_value = 0     # (current_sql_file / total_sql_files) * 100
        self.progress_ratio = 0.8   # Ratio to apply to 'progress_value'
        self.is_cm_project = False
        self.schema_build_progress_hint = ""
        self._schema_cache = {}
        self._admin_catalog_cache = None
        self._admin_load_task = None
        self._admin_loading = False
        self._extensions_checked = False
        self._cached_pg_versions = None

    def init_sql(self, set_database_connection=False, username=None, show_dialog=True):
        """ Button 100: Execute SQL. Info show info """

        default_connection = self._populate_combo_connections()
        self._load_connection_service_flag(default_connection)

        if self._needs_credentials_dialog(default_connection):
            self._create_credentials_form(set_connection=default_connection)
            return

        if set_database_connection:
            connection_status = True
        else:
            connection_status = lib_vars.session_vars['logged_status']

        if not connection_status and self.is_service:
            self.form_enabled = False

        self.icon_folder = f"{self.plugin_dir}{os.sep}icons{os.sep}dialogs{os.sep}"
        self.status_ok = QPixmap(f"{self.icon_folder}140.png")
        self.status_ko = QPixmap(f"{self.icon_folder}138.png")
        self.status_no_update = QPixmap(f"{self.icon_folder}139.png")

        self._init_show_database()
        self._info_show_database(
            connection_status=connection_status,
            username=username,
            show_dialog=show_dialog,
            connection_name=default_connection,
            try_set_connection=set_database_connection,
        )

    def create_project_data_other_schema(self, project, parent_schema=None, parent_type=None):
        """ Create other schema """

        self.other_project = project

        msg = "This process will take time (few minutes). Are you sure to continue?"
        title = "Create {0} schema"
        title_params = (project,)
        answer = tools_qt.show_question(msg, title=title, title_params=title_params)
        if not answer:
            return

        self.create_process(
            project,
            parent_schema=parent_schema,
            parent_type=parent_type,
        )

    def create_project_data_schema(self, project_name_schema=None, project_descript=None, project_type=None,
            project_srid=None, project_locale=None, is_test=False, exec_last_process=True, example_data=True):
        """"""

        # Get project parameters
        if project_name_schema is None or not project_name_schema:
            project_name_schema = tools_qt.get_text(self.dlg_readsql_create_project, 'project_name')
        if project_descript is None or not project_descript:
            project_descript = tools_qt.get_text(self.dlg_readsql_create_project, 'project_descript')
        if project_type is None:
            project_type = tools_qt.get_text(self.dlg_readsql_create_project, 'cmb_create_project_type')
        if project_srid is None:
            project_srid = tools_qt.get_text(self.dlg_readsql_create_project, 'srid_id')
        if project_locale is None:
            project_locale = tools_qt.get_combo_value(self.dlg_readsql_create_project, self.cmb_locale, 0)

        # Set class variables
        self.schema = project_name_schema
        self.descript = project_descript
        self.schema_type = project_type
        self.project_epsg = project_srid
        self.folder_final_pass = os.path.join(self.sql_dir, 'schemas', 'main', project_type, 'final_pass')
        self.folder_locale = os.path.join(self.folder_final_pass, 'i18n')

        # If the locale is no_TR, act as if it was en_US, but disable translation files
        self.locale = project_locale
        if self.locale == 'no_TR':
            self.project_epsg = '25831'
            project_srid = '25831'

        # Save in settings
        self._save_create_project_user_values()

        # Check if project name is valid
        if not self._check_project_name(project_name_schema, project_descript):
            return

        # Check if srid value is valid
        if self.last_srids is None:
            msg = "This SRID value does not exist on Postgres Database. Please select a diferent one."
            title = "Info"
            tools_qt.show_info_box(msg, title)
            return

        msg = "This process will take time (few minutes). Are you sure to continue?"
        title = "Create example"
        answer = tools_qt.show_question(msg, title)
        if not answer:
            return

        msg = "Create schema of type '{0}': '{1}'"
        msg_params = (project_type, project_name_schema,)
        tools_log.log_info(msg, msg_params=msg_params)

        if self.rdb_sample_full.isChecked() or self.rdb_sample_inv.isChecked():
            sample_locales = ('en_US', 'es_ES', 'ca_ES', 'es_CR', 'no_TR')
            locale_ok = self.locale in sample_locales
            srid_ok = str(self.project_epsg) == '25831'
            if not locale_ok or not srid_ok:
                msg = ("Sample projects are only allowed with locales en_US, es_ES, ca_ES or es_CR, and SRID 25831."
                       "\nDo you want to apply the required values and continue?")
                title = "Info Message"
                result = tools_qt.show_question(msg, title, force_action=True)
                if result:
                    if not srid_ok:
                        self.project_epsg = '25831'
                        project_srid = '25831'
                        tools_qt.set_widget_text(self.dlg_readsql_create_project, 'srid_id', '25831')
                    if not locale_ok:
                        self.locale = 'en_US'
                        project_locale = 'en_US'
                        self.folder_locale = os.path.join(self.folder_final_pass, 'i18n')
                        tools_qt.set_combo_value(self.cmb_locale, 'en_US', 0)
                else:
                    return

        params = {'is_test': is_test, 'project_type': project_type, 'exec_last_process': exec_last_process,
                  'project_name_schema': project_name_schema, 'project_locale': project_locale,
                  'project_srid': project_srid, 'example_data': example_data}

        if hasattr(self, 'task_rename_schema') and not isdeleted(self.task_rename_schema):
            self.task_rename_schema.task_finished.connect(partial(self.start_create_project_data_schema_task, project_name_schema, params, project_type))
        else:
            self.start_create_project_data_schema_task(project_name_schema, params, project_type)

    # ------------------------------------------------------------------
    # Engine bridges. Each of the following entry points builds a
    # `BuildParams`, picks the right manifest, and submits a single
    # `GwSchemaBuilderTask`. The legacy per-kind task classes have been
    # deleted in favour of this central path so the QGIS UI, the CLI,
    # and pytest all share one engine.
    # ------------------------------------------------------------------

    def _open_schema_build_message_log(self) -> None:
        """Show the Giswater PY log tab (same UX as schema update)."""
        message_log = self.iface.mainWindow().findChild(QDockWidget, 'MessageLog')
        if message_log is not None:
            message_log.setVisible(True)
        QgsMessageLog.logMessage(
            "",
            f"{lib_vars.plugin_name.capitalize()} PY",
            Qgis.MessageLevel.Info,
        )

    def _active_schema_build_task(self):
        """Return the running engine task, if any."""
        for attr in (
            "task_create_schema",
            "task_update_schema",
            "task_create_cm_schema",
            "task_create_cibs_schema",
        ):
            task = getattr(self, attr, None)
            if task is not None and not isdeleted(task):
                return task
        return None

    def _submit_builder(self, kind, params, *, description=None, on_done=None, dlg_for_timer=None):
        """Build manifest + task and queue it on the QGIS task manager."""
        self._open_schema_build_message_log()
        self.schema_build_progress_hint = ""
        self.error_count = 0
        self.t0 = time()
        self.timer = QTimer()
        if dlg_for_timer is not None:
            self.timer.timeout.connect(partial(self._calculate_elapsed_time, dlg_for_timer))
        self.timer.start(1000)

        manifest = load_kind_manifest(self.plugin_dir, kind)
        desc = description or f"Build {kind}:{params.schema_name}"
        task = GwSchemaBuilderTask(
            self, manifest, params,
            description=desc, timer=self.timer, on_done=on_done,
        )
        # Expose under the legacy attribute name so dialog code that probes
        # `hasattr(admin, 'task_create_schema')` still finds the active task.
        self.task_create_schema = task
        QgsApplication.taskManager().addTask(task)
        QgsApplication.taskManager().triggerTask(task)
        return task

    def start_create_project_data_schema_task(self, project_name_schema, params, project_type):
        """Build a ws/ud schema via the engine. `params` is the legacy dict."""
        self.schema = project_name_schema

        # Map legacy radio buttons → manifest profile.
        if self.rdb_sample_inv.isChecked() and params.get('example_data', True):
            profile = 'sample_inv'
        elif self.rdb_sample_full.isChecked() and params.get('example_data', True):
            profile = 'sample_full'
        else:
            profile = 'empty'

        bp = BuildParams(
            schema_name=project_name_schema,
            srid=str(params['project_srid']),
            locale=params['project_locale'],
            plugin_version=str(self.plugin_version),
            profile=profile,
            creation_profile={'empty': 'empty', 'sample_inv': 'inventory', 'sample_full': 'sample'}.get(profile, 'empty'),
            run_mode='new_project',
            db_user=getattr(self, 'username', '') or '',
            sql_root=self.sql_dir,
        )
        is_test = bool(params.get('is_test', False))
        on_done = partial(self._on_builder_done_ws_ud, project_name_schema, project_type, is_test)
        self._submit_builder(
            project_type, bp,
            description="Create schema",
            on_done=on_done,
            dlg_for_timer=self.dlg_readsql_create_project,
        )

    def _on_builder_done_ws_ud(self, project_name_schema, project_type, is_test, result):
        """Bridge engine result → existing manage_process_result behaviour."""
        if not result.ok:
            self.error_count += 1
        self.manage_process_result(project_name_schema, project_type, is_test=is_test)
        if result.ok and admin_catalog.schema_exists("multilang"):
            from .i18n.multilang_seed_sql import multilang_user_param_provision_sql

            tools_db.execute_sql(
                multilang_user_param_provision_sql(
                    enable=True,
                    schema_name=project_name_schema,
                )
            )

    def create_process(self, process_name="", parent_schema=None, parent_type=None):
        """
        am or audit lifecycle entry point.

        Translates the legacy `process_name` (`am`, `audit`,
        `audit_activation`) to a manifest kind + profile.
        """
        if process_name == "am":
            tools_qgis.show_warning(
                "Use Manage Schemas to create and integrate the am schema."
            )
            return
        elif process_name in ("audit", "audit_activation"):
            profile = "structure" if process_name == "audit" else "activate"
            schema_name = "audit"
            resolved_parent, resolved_type = self._resolve_parent_context(parent_schema, parent_type)
            parent_schema = "audit"
            parent_type = ""
            if process_name == "audit_activation":
                schema_name = resolved_parent or "audit"
                parent_schema = resolved_parent or "audit"
                parent_type = resolved_type
            register_is_new = "true" if profile == "structure" else "false"
            register_parent = "" if profile == "structure" else (resolved_parent or "")
            bp = BuildParams(
                schema_name=schema_name,
                srid=str(self.project_epsg or "25831"),
                locale=self.locale,
                plugin_version=str(self.plugin_version),
                profile=profile,
                run_mode="new_project" if profile == "structure" else "upgrade",
                parent_schema=parent_schema,
                parent_type=parent_type,
                register_is_new=register_is_new,
                register_parent_schema=register_parent,
                sql_root=self.sql_dir,
            )
            self._submit_builder("audit", bp,
                                 description=f"audit:{profile}",
                                 on_done=self._on_builder_done_other)

    def _on_builder_done_other(self, result):
        if not result.ok:
            self.error_count += 1
        self.manage_other_process_result()

    def _create_am_schema(self, profile: str = "empty") -> None:
        """Create the singleton am schema (no parent integration)."""
        msg = "This process will take time (few minutes). Are you sure to continue?"
        title = "Create am schema"
        if profile == "sample":
            title = "Create am schema with sample data"
        if not tools_qt.show_question(msg, title):
            return
        bp = BuildParams(
            schema_name="am",
            srid=str(self.project_epsg or "25831"),
            locale=self.locale,
            plugin_version=str(self.plugin_version),
            profile=profile,
            register_is_new="true",
            sql_root=self.sql_dir,
        )
        self._submit_builder(
            "am",
            bp,
            description=f"Create am ({profile})",
            on_done=self._on_builder_done_other,
        )

    def _integrate_am_schema(
        self,
        profile: str,
        parent_schema: str,
        parent_type: str,
    ) -> None:
        """Wire am into a WS parent schema."""
        msg = (
            "You are about to integrate AM with the following WS schema: {0}\n\n"
            "Are you sure you want to continue?"
        )
        msg_params = (parent_schema,)
        title = "Integrate am"
        if not tools_qt.show_question(msg, title, msg_params=msg_params):
            return
        bp = BuildParams(
            schema_name="am",
            srid=str(self.project_epsg or "25831"),
            locale=self.locale,
            plugin_version=str(self.plugin_version),
            profile=profile,
            parent_schema=parent_schema,
            parent_type=(parent_type or "ws").lower(),
            register_parent_schema=parent_schema,
            infer_parents_from_config="true",
            sql_root=self.sql_dir,
        )
        self._submit_builder(
            "am",
            bp,
            description=f"Integrate am ({profile})",
            on_done=self._on_builder_done_other,
        )

    def _run_create_cm_task(
        self,
        steps,
        process_name,
        *,
        parent_schema=None,
        parent_type=None,
        dlg_for_timer=None,
    ):
        """
        cm schema lifecycle entry point.

        `steps` is a legacy list like `['load_base_schema']` /
        `['load_parent_schema']` / `['load_example']`. We map it to a
        manifest profile and run the engine.
        """
        cm_schema = getattr(self, 'cm_schema_name', None) or self._get_cm_schema_name() or "cm"
        if parent_schema is None and getattr(self, 'dlg_readsql', None) is not None:
            parent_schema = self._get_selected_schema_name()
        parent_schema = parent_schema or ""
        if parent_type is None:
            parent_type = self.project_type_selected or ""
        if not parent_type and getattr(self, 'dlg_readsql', None) is not None:
            parent_type = self._get_selected_project_type()
        pt_norm = (parent_type or "").lower()
        if pt_norm and not os.path.isfile(
            os.path.join(
                self.sql_dir, "schemas", "addon", "cm", "integration", pt_norm, "integration.sql"
            )
        ):
            msg = (
                "cm schema is not supported for parent_type='{0}' in this dbmodel. "
                "Missing schemas/addon/cm/integration/{1}/integration.sql."
            )
            msg_params = (pt_norm, pt_norm)
            tools_qgis.show_message(msg, Qgis.MessageLevel.Warning, msg_params=msg_params)
            return

        # Map step list -> profile. The legacy task ran one step at a
        # time; in the manifest world we expose a profile for each.
        if steps == ['load_base_schema']:
            profile_phases = ['load_base_schema', 'load_locale', 'register_version']
        elif steps == ['load_parent_schema']:
            profile_phases = ['integrate_cm', 'register_version']
        elif steps == ['load_example']:
            profile_phases = ['load_sample', 'register_version']
        elif steps == ['load_locale']:
            profile_phases = ['load_locale']
        else:
            profile_phases = list(steps)

        # Inject an ad-hoc profile into the manifest so the engine can
        # dispatch the exact step list the dialog asked for. This avoids
        # forcing the manifest to declare a profile per legacy step.
        manifest = load_kind_manifest(self.plugin_dir, "cm")
        from ...giswater_admin.engine.manifest import Profile  # local import keeps top-level Qt-free
        profile_name = f"_ui_{'_'.join(profile_phases)}"
        manifest.profiles[profile_name] = Profile(name=profile_name,
                                                  phases=tuple(profile_phases))

        bp = BuildParams(
            schema_name=cm_schema,
            srid=str(self.project_epsg or "25831"),
            locale=self.locale,
            plugin_version=str(self.plugin_version),
            profile=profile_name,
            run_mode='new_project',
            parent_schema=parent_schema or "",
            parent_type=(parent_type or "").lower(),
            sql_root=self.sql_dir,
            db_name=self._get_current_db_name() or "",
        )

        self._open_schema_build_message_log()
        self.schema_build_progress_hint = ""
        self.error_count = 0
        self.cm_error_count = 0
        self.t0 = time()
        self.timer = QTimer()
        timer_dlg = (
            dlg_for_timer
            or getattr(self, '_manage_schemas_dlg', None)
            or self.dlg_readsql_create_cm_project
        )
        if timer_dlg is not None:
            self.timer.timeout.connect(partial(self._calculate_elapsed_time, timer_dlg))
        self.timer.start(1000)

        task = GwSchemaBuilderTask(
            self, manifest, bp,
            description=process_name.capitalize() if isinstance(process_name, str) else "cm",
            timer=self.timer,
            on_done=partial(self._on_builder_done_cm, process_name),
        )
        self.task_create_cm_schema = task
        QgsApplication.taskManager().addTask(task)
        QgsApplication.taskManager().triggerTask(task)

    def _on_builder_done_cm(self, process_name, result):
        if not result.ok:
            self.cm_error_count += 1
        self.manage_cm_process_result(process_name)

    def _run_create_cibs_task(
        self,
        profile,
        process_name,
        *,
        parent_schema="",
        parent_type="",
        on_done=None,
    ):
        """Run a cibs manifest profile via the schema builder engine."""
        if profile == "integrate":
            if not parent_schema or not parent_type:
                schema_info = self._get_cibs_schema_info()
                if schema_info is None:
                    msg = "Select a WS or UD schema for the cibs operation"
                    tools_qgis.show_message(msg, Qgis.MessageLevel.Warning)
                    return
                parent_schema, _, parent_type = schema_info
            pt_norm = (parent_type or "").lower()
            if pt_norm and not os.path.isfile(
                os.path.join(
                    self.sql_dir, "schemas", "addon", "cibs", "integration", pt_norm, "integration.sql"
                )
            ):
                msg = (
                    "cibs schema is not supported for parent_type='{0}' in this dbmodel. "
                    "Missing schemas/addon/cibs/integration/{1}/integration.sql."
                )
                msg_params = (pt_norm, pt_norm)
                tools_qgis.show_message(msg, Qgis.MessageLevel.Warning, msg_params=msg_params)
                return

        register_is_new = "true" if profile == "empty" else "false"
        infer_parents = "true" if profile in ("integrate", "update") else "false"
        register_parent = parent_schema if profile == "integrate" else ""

        bp = BuildParams(
            schema_name="cibs",
            srid=str(self.project_epsg or "25831"),
            locale=self.locale,
            plugin_version=str(self.plugin_version),
            profile=profile,
            run_mode="upgrade" if profile == "update" else "new_project",
            parent_schema=parent_schema or "",
            parent_type=(parent_type or "").lower(),
            register_is_new=register_is_new,
            infer_parents_from_config=infer_parents,
            register_parent_schema=register_parent,
            sql_root=self.sql_dir,
            db_name=self._get_current_db_name() or "",
        )

        callback = on_done if on_done is not None else partial(self._on_builder_done_cibs, process_name)
        task = self._submit_builder(
            "cibs",
            bp,
            description=process_name,
            on_done=callback,
        )
        self.task_create_cibs_schema = task

    def _on_builder_done_cibs(self, process_name, result):
        if not result.ok:
            self.error_count += 1
        elif process_name == 'Adapt schema to cibs':
            schema_name = getattr(self, 'cibs_project_name', None)
            if schema_name:
                if not admin_catalog.register_parent_satellite_enabled(schema_name, "cibs"):
                    self.error_count += 1
                sql = f"SELECT {schema_name}.gw_fct_admin_role_permissions();"
                tools_log.log_info("Task '{0}' execute sql: '{1}'",
                                   msg_params=("Adapt cibs schema", sql,))
                if not tools_db.execute_sql(sql):
                    self.error_count += 1
                else:
                    sql = (f"UPDATE {schema_name}.config_param_system "
                           f"SET value = 'true' WHERE parameter = 'admin_cibs_schema'")
                    tools_log.log_info("Task '{0}' execute sql: '{1}'",
                                       msg_params=("Adapt cibs schema", sql,))
                    if not tools_db.execute_sql(sql):
                        self.error_count += 1
        self.manage_process_result('cibs', 'cibs', is_cibs=True)

    def manage_process_result(self, project_name, project_type, is_test=False, is_utils=False, is_cibs=False, dlg=None):
        """"""

        status = (self.error_count == 0)
        self._manage_result_message(status, parameter="Create project")
        if status:
            tools_db.dao.commit()
            refresh = getattr(self, '_manage_schemas_refresh', None)
            if refresh:
                refresh()
            if is_utils is False and is_cibs is False:
                self._close_dialog_admin(self.dlg_readsql_create_project)
            if not is_test:
                self._refresh_admin_catalog_cache()
                self._populate_data_schema_name()
                self._manage_utils()
                if project_name is not None and is_utils is False and is_cibs is False:
                    tools_qt.set_combo_value(
                        self.dlg_readsql.project_schema_name, project_name, 0, add_new=False
                    )
                    self._sync_project_type_from_schema()
                    self._set_info_project()
        else:
            tools_db.dao.rollback()
            # Reset count error variable to 0
            self.error_count = 0
            tools_qt.show_exception_message(msg=lib_vars.session_vars['last_error_msg'])
            msg = "A rollback on schema will be done."
            tools_qgis.show_info(msg)
            if dlg:
                tools_gw.close_dialog(dlg)

    def manage_other_process_result(self):
        """"""

        status = (self.error_count == 0)
        self._manage_result_message(status)
        if status:
            tools_db.dao.commit()
            self._set_buttons_enabled()
            refresh = getattr(self, '_manage_schemas_refresh', None)
            if refresh:
                refresh()

        else:
            tools_db.dao.rollback()
            # Reset count error variable to 0
            self.error_count = 0
            tools_qt.show_exception_message(msg=lib_vars.session_vars['last_error_msg'])
            msg = "A rollback on schema will be done."
            tools_qgis.show_info(msg)

    def manage_cm_process_result(self, process_name):
        """"""

        status = (self.cm_error_count == 0)
        self._manage_result_message(status, parameter=f"CM Task: {process_name.capitalize()}")
        if status:
            tools_db.dao.commit()
            refresh = getattr(self, '_manage_schemas_refresh', None)
            if refresh:
                refresh()
        else:
            tools_db.dao.rollback()
            # Reset count error variable to 0
            self.cm_error_count = 0
            tools_qt.show_exception_message(msg=lib_vars.session_vars['last_error_msg'])
            msg = "A rollback on schema will be done."
            tools_qgis.show_info(msg)
            if self.dlg_readsql_create_cm_project:
                tools_gw.close_dialog(self.dlg_readsql_create_cm_project)

    def _cm_has_sample_data(self) -> bool:
        cm_schema = self._get_cm_schema_name() or "cm"
        has_team = bool(
            tools_db.get_rows(f"SELECT 1 FROM {cm_schema}.cat_team LIMIT 1")
        )
        has_org = bool(
            tools_db.get_rows(f"SELECT 1 FROM {cm_schema}.cat_organization LIMIT 1")
        )
        return has_team and has_org

    def _create_cm_schema(self):
        """Create the CM base schema (no parent link)."""
        name = 'cm'
        description = 'cm'

        tools_gw.set_config_parser('btn_admin', 'project_name_cm_schema', name, prefix=False)
        tools_gw.set_config_parser('btn_admin', 'cm_project_descript', description, prefix=False)

        if not self._check_project_name(name, description):
            return

        msg = "This process will take a few seconds. Are you sure to continue?"
        title = "Create base schema"
        if not tools_qt.show_question(msg, title):
            return

        self.cm_schema_name = name
        self.cm_schema_description = description
        self.base_schema_created = True
        self._run_create_cm_task(['load_base_schema'], 'Create cm base schema')

    def _integrate_cm(self, parent_schema=None, parent_type=None):
        """Link CM to the selected WS/UD parent schema."""
        parent_schema, parent_type = self._resolve_parent_context(parent_schema, parent_type)
        if not parent_schema:
            msg = "Select a WS or UD anchor in the network table."
            tools_qt.show_info_box(msg)
            return

        msg = (
            "You are about to perform this action aiming to the following schema: {0}\n\n"
            "Are you sure you want to continue?"
        )
        if not tools_qt.show_question(msg, "Link to parent schema", msg_params=(parent_schema,)):
            return

        self.project_type_selected = parent_type
        self.parent_schema_created = True
        self._run_create_cm_task(
            ['load_parent_schema'],
            'Link to parent schema',
            parent_schema=parent_schema,
            parent_type=parent_type,
        )

    def _load_cm_sample(self, parent_schema=None, parent_type=None):
        """Load CM example data for the selected parent schema."""
        parent_schema, parent_type = self._resolve_parent_context(parent_schema, parent_type)
        if not parent_schema:
            msg = "Select a WS or UD anchor in the network table."
            tools_qt.show_info_box(msg)
            return

        msg = (
            "You are about to perform this action aiming to the following schema: {0}\n\n"
            "Are you sure you want to continue?"
        )
        if not tools_qt.show_question(msg, "Load example data", msg_params=(parent_schema,)):
            return

        self.example_type = parent_type
        self.project_example_name = parent_schema
        self.project_type_selected = parent_type
        self._run_create_cm_task(
            ['load_example'],
            'Load example data',
            parent_schema=parent_schema,
            parent_type=parent_type,
        )

    def _set_cm_pschema_qgis(self):
        """Flag the next QGIS project creation as a CM project."""
        self.is_cm_project = True
        msg = "Layer of CM project will be added to the project when create"
        tools_qgis.show_info(msg)

    def _get_cm_schema_name(self):
        """
        Return the name of the first schema whose sys_version table
        exists and has project_type = 'cm', or None if no such schema.
        """
        # find all schemas that actually define a sys_version table
        return admin_catalog.find_cm_schema()

    def _vacuum_project_data_schema(self, verbose=False):
        """ Execute task to vacuum schema """
        description = "Vacuum schema"
        params = {'schema_name': self.schema_name, 'logs': True, 'verbose': verbose}

        self.task_vacuum_schema = GwVacuumSchemaTask(description, params)
        QgsApplication.taskManager().addTask(self.task_vacuum_schema)
        QgsApplication.taskManager().triggerTask(self.task_vacuum_schema)

    def execute_vacuum(self, ask_confirm=False, verbose=False):
        """ Ask confirmation to execute vacuum using a separate database connection """
        if ask_confirm:
            msg = "Are you sure to execute vacuum on selected schema?"
            title = "Warning"
            result = tools_qt.show_question(msg, title)
            if result is True:
                self._vacuum_project_data_schema(verbose=verbose)
                return True
            else:
                return False
        else:
            self._vacuum_project_data_schema(verbose=verbose)

        return True

    def cancel_task(self, task_name: str):
        if hasattr(self, task_name):
            task = getattr(self, task_name)
            if not isdeleted(task):
                task.cancel()

    def _resolve_update_kind(self) -> str:
        # Schema-backed type wins; never prefer stale project_type_selected
        # (e.g. after switching UD → WS in the schema combo, or create-project flips).
        kind = self._get_selected_project_type() or self.project_type
        return str(kind or 'ws').lower()

    def _resolve_parent_context(self, parent_schema=None, parent_type=None):
        if parent_schema:
            pt = parent_type
            if not pt:
                entry = admin_catalog._fetch_schema_sys_version_entry(str(parent_schema))
                pt = str(entry.get("kind") or "ws").lower()
            return str(parent_schema), str(pt or "ws").lower()
        schema_name = self._get_schema_name() or ""
        pt = self._get_selected_project_type() if schema_name else ""
        return schema_name, str(pt or "ws").lower()

    def _run_schema_upgrade(self, schema_name, project_type, on_done=None):
        """Upgrade a ws/ud schema in place via the engine."""
        row = tools_db.get_row(
            f"SELECT giswater, language, epsg FROM {schema_name}.sys_version "
            "ORDER BY id DESC LIMIT 1"
        )
        current_version = row[0] if row and row[0] else "0.0.0"
        err = assert_no_downgrade(
            str(current_version),
            str(self.plugin_version),
            label=f"schema '{schema_name}'",
        )
        if err:
            tools_qgis.show_warning(err)
            return
        bp = BuildParams(
            schema_name=schema_name,
            srid=str(row[2] if row and row[2] else self.project_epsg or "25831"),
            locale=str(row[1] if row and row[1] else self.locale),
            plugin_version=str(self.plugin_version),
            project_version=str(current_version),
            run_mode='upgrade',
            profile='update',
            sql_root=self.sql_dir,
        )
        callback = on_done if on_done is not None else self._on_builder_done_update
        self._submit_builder(
            project_type,
            bp,
            description=f"Update {schema_name}",
            on_done=callback,
        )

    def _run_lockstep_step(self, step: LockstepStep, on_done=None):
        """Run one lockstep network upgrade step via the engine."""
        profile = "update_step" if step.action == "upgrade" else "version_bump"
        row = tools_db.get_row(
            f"SELECT giswater, language, epsg FROM {step.schema}.sys_version "
            "ORDER BY id DESC LIMIT 1"
        )
        current_version = row[0] if row and row[0] else step.from_version
        bp = BuildParams(
            schema_name=step.schema,
            srid=str(row[2] if row and row[2] else self.project_epsg or "25831"),
            locale=str(row[1] if row and row[1] else self.locale),
            plugin_version=str(step.target_version),
            project_version=str(current_version or step.from_version),
            run_mode="upgrade_step" if step.action == "upgrade" else "upgrade",
            profile=profile,
            sql_root=self.sql_dir,
            infer_parents_from_config="true" if step.kind == "utils" else "false",
        )
        callback = on_done if on_done is not None else self._on_builder_done_update
        self._submit_builder(
            step.kind,
            bp,
            description=f"Update {step.schema} -> {step.target_version}",
            on_done=callback,
        )

    def _update_network(self, anchor_schema=None):
        """Sequentially update anchor WS/UD and linked satellites."""
        anchor = anchor_schema or self._get_schema_name() or ""
        if not anchor:
            tools_qgis.show_message(
                "Select a WS or UD parent schema.",
                Qgis.MessageLevel.Info,
            )
            return

        anchor_entry = admin_catalog._fetch_schema_sys_version_entry(anchor)
        anchor_kind = str(anchor_entry.get("kind") or "").upper()
        if anchor_kind not in ("WS", "UD"):
            tools_qgis.show_message(
                "Update network requires a WS or UD anchor schema.",
                Qgis.MessageLevel.Info,
            )
            return

        graph = resolve_network_graph(anchor, admin_catalog._tools_db_fetch)
        err = assert_network_no_downgrade(graph, str(self.plugin_version))
        if err:
            tools_qgis.show_warning(err)
            return

        plan = plan_lockstep(
            graph,
            self.sql_dir,
            str(self.plugin_version),
        )
        if not plan:
            tools_qgis.show_message(
                "Network is already up to date.",
                Qgis.MessageLevel.Info,
            )
            return

        summary = "\n".join(
            f"- {step.target_version}  {step.kind}  {step.schema}  "
            f"{step.action}  ({step.from_version})"
            for step in plan
        )
        if not tools_qt.show_question(
            f"Lockstep update the following steps?\n\n{summary}",
            "Update network",
        ):
            return

        self._update_plan_queue = plan
        self._open_schema_build_message_log()
        self.schema_build_progress_hint = ""
        self.error_count = 0
        self.t0 = time()
        self.timer = QTimer()
        self.timer.start(1000)
        self._run_update_plan_step(0)

    def _run_update_plan_step(self, index):
        queue = getattr(self, '_update_plan_queue', None) or []
        if index >= len(queue):
            self._finish_update_plan(success=True)
            return

        step = queue[index]
        on_done = partial(self._chain_update_done, index)
        if isinstance(step, LockstepStep):
            self._run_lockstep_step(step, on_done=on_done)
            return

        kind = str(step.get("kind") or "").lower()
        schema_name = str(step.get("schema") or "")
        parent_schema = step.get("parent_schema")
        parent_type = step.get("parent_type")

        if kind in ("ws", "ud"):
            self._run_schema_upgrade(schema_name, kind, on_done=on_done)
        elif kind == "utils":
            self._update_utils(on_done=on_done)
        elif kind == "cibs":
            self._update_cibs(on_done=on_done)
        elif kind == "am":
            self._update_asset(
                parent_schema=parent_schema,
                parent_type=parent_type,
                on_done=on_done,
            )
        elif kind == "cm":
            self._update_cm(
                parent_schema=parent_schema,
                parent_type=parent_type,
                cm_schema=schema_name,
                on_done=on_done,
            )
        elif kind == "audit":
            self._update_audit(on_done=on_done)
        elif kind == "multilang":
            self._update_i18n(on_done=on_done)
        else:
            tools_qgis.show_warning(
                "Unsupported schema kind in update plan.",
                parameter=kind,
            )
            self._finish_update_plan(success=False)

    def _chain_update_done(self, index, result):
        if self.timer is not None:
            try:
                self.timer.stop()
            except Exception:  # noqa: BLE001
                pass
        if not result.ok:
            self.error_count += 1
            tools_db.dao.rollback()
            self._manage_result_message(False, parameter="Update network")
            self._finish_update_plan(success=False)
            return

        tools_db.dao.commit()
        self._run_update_plan_step(index + 1)

    def _finish_update_plan(self, success=True):
        if self.timer is not None:
            try:
                self.timer.stop()
            except Exception:  # noqa: BLE001
                pass
        self._update_plan_queue = []
        if success:
            self._refresh_admin_catalog_cache()
            self._set_info_project()
            self._manage_result_message(True, parameter="Update network")
            refresh = getattr(self, '_manage_schemas_refresh', None)
            if refresh:
                refresh()
        self.error_count = 0

    # TODO: Rename this function => Update all versions from changelog file.
    def update(self, project_type=None):
        """Upgrade the currently-selected schema in place via the engine."""
        # QPushButton.clicked emits a bool; ignore it when wired directly.
        if isinstance(project_type, bool):
            project_type = None
        project_type = self._resolve_update_kind() if project_type is None else str(project_type).lower()
        if project_type not in ('ws', 'ud'):
            tools_qgis.show_warning(
                "Schema update is only supported for ws/ud project types.",
                parameter=project_type,
            )
            return

        schema_name = self._get_schema_name()
        if schema_name:
            graph = resolve_network_graph(schema_name, admin_catalog._tools_db_fetch)
            if graph_has_linked_dependents(graph, schema_name):
                peers = ", ".join(
                    sorted(
                        node.schema
                        for node in graph.nodes
                        if node.schema != schema_name
                    )
                )
                tools_qgis.show_warning(
                    "This schema is part of an interconnected network. "
                    "Use Update network instead.",
                    parameter=peers,
                )
                return

        current_for_guard = str(self.project_version or "0.0.0")
        if schema_name:
            row_guard = tools_db.get_row(
                f"SELECT giswater FROM {schema_name}.sys_version ORDER BY id DESC LIMIT 1"
            )
            if row_guard and row_guard[0]:
                current_for_guard = str(row_guard[0])
        err = assert_no_downgrade(
            current_for_guard,
            str(self.plugin_version),
            label=f"schema '{schema_name}'" if schema_name else "schema",
        )
        if err:
            tools_qgis.show_warning(err)
            return

        msg = "Are you sure to update the project schema to last version?"
        title = "Info"
        result = tools_qt.show_question(msg, title)
        if not result:
            return

        # Manage Log Messages panel and open tab Giswater PY
        message_log = self.iface.mainWindow().findChild(QDockWidget, 'MessageLog')
        message_log.setVisible(True)
        QgsMessageLog.logMessage("", f"{lib_vars.plugin_name.capitalize()} PY", Qgis.MessageLevel.Info)

        # Manage Log Messages in tab log
        main_tab = self.dlg_readsql_show_info.findChild(QTabWidget, 'mainTab')
        main_tab.setCurrentWidget(main_tab.findChild(QWidget, "tab_loginfo"))
        main_tab.setTabEnabled(main_tab.currentIndex(), True)
        self.infolog_updates = self.dlg_readsql_show_info.findChild(QTextEdit, 'tab_log_txt_infolog')
        self.infolog_updates.setReadOnly(True)
        self.message_infolog = ''
        self.infolog_updates.setText(self.message_infolog)

        schema_name = self._get_schema_name()
        self._update_from_version = str(self.project_version or '0.0.0')
        if schema_name:
            tools_db.execute_sql(
                f"DELETE FROM {schema_name}.audit_check_data "
                f"WHERE fid = 133 AND cur_user = current_user",
                commit=False,
            )

        row = tools_db.get_row(
            f"SELECT giswater, language, epsg FROM {schema_name}.sys_version "
            "ORDER BY id DESC LIMIT 1"
        ) if schema_name else None
        current_version = str(
            (row[0] if row and row[0] else None) or self.project_version or "0.0.0"
        )
        self._update_from_version = current_version

        self._refresh_update_dialog_state(running=True)
        bp = BuildParams(
            schema_name=schema_name,
            srid=str(row[2] if row and row[2] else self.project_epsg or "25831"),
            locale=str(row[1] if row and row[1] else self.locale),
            plugin_version=str(self.plugin_version),
            project_version=current_version,
            run_mode='upgrade',
            profile='update',
            sql_root=self.sql_dir,
        )

        self._open_schema_build_message_log()
        self.schema_build_progress_hint = ""
        self.error_count = 0
        self.t0 = time()
        self.timer = QTimer()
        self.timer.timeout.connect(partial(self._calculate_elapsed_time, self.dlg_readsql_show_info))
        self.timer.start(1000)

        manifest = load_kind_manifest(self.plugin_dir, project_type)
        task = GwSchemaBuilderTask(
            self, manifest, bp,
            description="Update schema",
            timer=self.timer,
            on_done=self._on_builder_done_update,
        )
        self.task_update_schema = task
        QgsApplication.taskManager().addTask(task)
        QgsApplication.taskManager().triggerTask(task)

    def _schema_needs_update(self) -> bool:
        return _admin_version_tuple(self.project_version) < _admin_version_tuple(self.plugin_version)

    def _refresh_update_dialog_state(self, *, running: bool = False, success: bool = False) -> None:
        dlg = getattr(self, 'dlg_readsql_show_info', None)
        if dlg is None or isdeleted(dlg):
            return

        dlg.btn_close.setEnabled(not running)
        if running:
            dlg.btn_update.hide()
            dlg.setWindowFlag(Qt.WindowType.WindowCloseButtonHint, False)
        elif success or not self._schema_needs_update():
            dlg.btn_update.hide()
            dlg.setWindowFlag(Qt.WindowType.WindowCloseButtonHint, True)
        else:
            dlg.btn_update.show()
            dlg.btn_update.setEnabled(True)
            dlg.setWindowFlag(Qt.WindowType.WindowCloseButtonHint, True)
        dlg.show()

    def _fill_update_log_tab(self, schema_name, result=None) -> None:
        """Populate Log tab after schema update (audit_check_data + version summary)."""
        dlg = getattr(self, 'dlg_readsql_show_info', None)
        if dlg is None or isdeleted(dlg):
            return

        lines: list[str] = []
        if schema_name and tools_db.check_table('audit_check_data', schema_name):
            rows = tools_db.get_rows(
                f"SELECT error_message FROM {schema_name}.audit_check_data "
                f"WHERE fid = 133 "
                f"ORDER BY criticity DESC, id ASC"
            )
            if rows:
                lines = [str(row[0]) for row in rows if row[0] is not None]

        if result is not None and result.ok:
            old_version = getattr(self, '_update_from_version', '') or str(self.project_version or '')
            new_version = str(self.plugin_version)
            info = tools_gw.get_project_info(schema_name) if schema_name else None
            if info and info.get('project_version'):
                new_version = str(info['project_version'])
            summary = (
                f"Project have been sucessfully updated from {old_version} "
                f"version to {new_version} version"
            )
            if not any('sucessfully updated' in line for line in lines):
                if lines:
                    lines.append('')
                lines.append(summary)
        elif result is not None and not result.ok:
            failure = result.first_failure()
            err = lib_vars.session_vars.get('last_error') or ''
            if failure is not None:
                err = err or failure.error or failure.path or ''
            if self.message_infolog:
                err = f"{self.message_infolog}\n{err}".strip()
            if err:
                lines = [str(err)]
        elif not lines and self.message_infolog:
            lines = [self.message_infolog]

        text = '\n'.join(lines)
        log_widget = dlg.findChild(QTextEdit, 'tab_log_txt_infolog')
        if log_widget is not None:
            log_widget.setReadOnly(True)
            log_widget.setPlainText(text)

        main_tab = dlg.findChild(QTabWidget, 'mainTab')
        log_tab = dlg.findChild(QWidget, 'tab_loginfo')
        if main_tab is not None and log_tab is not None:
            log_idx = main_tab.indexOf(log_tab)
            if log_idx >= 0:
                main_tab.setTabEnabled(log_idx, True)
                main_tab.setCurrentIndex(log_idx)

    def _on_builder_done_update(self, result):
        schema_name = self._get_schema_name()
        if self.timer is not None:
            try:
                self.timer.stop()
            except Exception:  # noqa: BLE001
                pass
        if getattr(self, 'dlg_readsql_show_info', None) is not None and not isdeleted(self.dlg_readsql_show_info):
            elapsed = format_elapsed_mmss(int(time() - self.t0))
            self._update_time_elapsed(
                f"{elapsed} | done" if result.ok else f"{elapsed} | failed",
                self.dlg_readsql_show_info,
            )

        if not result.ok:
            self.error_count += 1
            tools_db.dao.rollback()
            self._manage_result_message(False, parameter="Update schema")
            self._refresh_update_dialog_state(running=False, success=False)
            self._fill_update_log_tab(schema_name, result)
        else:
            tools_db.dao.commit()
            self._manage_result_message(True, parameter="Update schema")
            self._set_info_project()
            self._fill_update_log_tab(schema_name, result)
            self._refresh_update_dialog_state(running=False, success=True)
            if getattr(self, 'dlg_readsql_show_info', None) is not None and not isdeleted(self.dlg_readsql_show_info):
                self.message_update = ''
                self._read_info_version()
                info_updates = self.dlg_readsql_show_info.findChild(QTextEdit, 'info_updates')
                if info_updates is not None:
                    info_updates.setText(self.message_update)
                self._update_manage_ui()
        self.error_count = 0

    def init_dialog_create_project(self, project_type=None):
        """ Initialize dialog (only once) """

        self.dlg_readsql_create_project = GwAdminDbProjectUi(self)
        tools_gw.load_settings(self.dlg_readsql_create_project)
        self.dlg_readsql_create_project.btn_cancel_task.hide()

        # Find Widgets in form
        self.project_name = self.dlg_readsql_create_project.findChild(QLineEdit, 'project_name')
        self.project_descript = self.dlg_readsql_create_project.findChild(QLineEdit, 'project_descript')
        self.rdb_sample_inv = self.dlg_readsql_create_project.findChild(QRadioButton, 'rdb_sample_inv')
        self.rdb_sample_full = self.dlg_readsql_create_project.findChild(QRadioButton, 'rdb_sample_full')
        self.rdb_empty = self.dlg_readsql_create_project.findChild(QRadioButton, 'rdb_empty')

        # TODO: do and call listener for buton + table -> temp_csv

        # Manage SRID
        self._manage_srid()

        # Fill combo 'project_type'
        self.cmb_create_project_type = self.dlg_readsql_create_project.findChild(QComboBox, 'cmb_create_project_type')
        for aux in self.project_types:
            self.cmb_create_project_type.addItem(str(aux))

        if project_type:
            tools_qt.set_widget_text(self.dlg_readsql_create_project, self.cmb_create_project_type, project_type)
            self._change_project_type(self.cmb_create_project_type)

        # Get combo locale
        self.cmb_locale = self.dlg_readsql_create_project.findChild(QComboBox, 'cmb_locale')
        tools_gw.add_icon(self.dlg_readsql_create_project.btn_language, "184")
        msg = "Manage languages"
        self.dlg_readsql_create_project.btn_language.setToolTip(tools_qt.tr(msg))

        # Populate combo with all locales
        list_locale = self._select_active_locales()
        if global_vars.gw_dev_mode is True:
            list_locale.append(["no_TR", "Hardcoded (No translation)"])
        tools_qt.fill_combo_values(self.cmb_locale, list_locale)

        self._load_create_project_user_values()
        self._apply_dev_project_name()

        # Set shortcut keys
        self.dlg_readsql_create_project.key_escape.connect(
            partial(self._close_dialog_admin, self.dlg_readsql_create_project))

        # Get database connection name
        self.connection_name = str(tools_qt.get_text(self.dlg_readsql, self.cmb_connection))

        # Set signals
        self._set_signals_create_project()

    def _load_create_project_user_values(self):
        """Load last user values from session.config (same pattern as mincut _load_widgets_values)."""
        if self.dlg_readsql_create_project is None:
            return

        project_name = tools_gw.get_config_parser(
            'btn_admin', 'project_name_schema', "user", "session", False, force_reload=True)
        project_descript = tools_gw.get_config_parser(
            'btn_admin', 'project_descript', "user", "session", False, force_reload=True)
        create_schema_type = tools_gw.get_config_parser(
            'btn_admin', 'create_schema_type', "user", "session", False, force_reload=True)

        if project_name:
            self.project_name.setText(project_name)
        if project_descript:
            self.project_descript.setText(project_descript)

        if create_schema_type not in ('rdb_sample_inv', 'rdb_sample_full', 'rdb_empty'):
            create_schema_type = 'rdb_empty'
        for radio in (self.rdb_empty, self.rdb_sample_inv, self.rdb_sample_full):
            if radio is not None:
                radio.setChecked(radio.objectName() == create_schema_type)

        if self.cmb_locale is not None:
            locale = tools_gw.get_config_parser(
                'btn_admin', 'project_locale', 'user', 'session', False, force_reload=True)
            if locale:
                tools_qt.set_combo_value(self.cmb_locale, locale, 0, add_new=False)

    def _save_create_project_user_values(self):
        """Save form values to session.config (same pattern as mincut _save_widgets_values)."""
        if self.dlg_readsql_create_project is None:
            return

        project_name = tools_qt.get_text(self.dlg_readsql_create_project, 'project_name')
        project_descript = tools_qt.get_text(self.dlg_readsql_create_project, 'project_descript')
        if self.cmb_locale is not None:
            project_locale = tools_qt.get_combo_value(self.dlg_readsql_create_project, self.cmb_locale, 0)
        else:
            project_locale = None

        if self.rdb_sample_inv is not None and self.rdb_sample_inv.isChecked():
            create_schema_type = 'rdb_sample_inv'
        elif self.rdb_sample_full is not None and self.rdb_sample_full.isChecked():
            create_schema_type = 'rdb_sample_full'
        else:
            create_schema_type = 'rdb_empty'

        tools_gw.set_config_parser('btn_admin', 'project_name_schema', f'{project_name}', prefix=False)
        tools_gw.set_config_parser('btn_admin', 'project_descript', f'{project_descript}', prefix=False)
        if project_locale:
            tools_gw.set_config_parser('btn_admin', 'project_locale', f'{project_locale}', prefix=False)
        tools_gw.set_config_parser('btn_admin', 'create_schema_type', create_schema_type, prefix=False)

    def _dev_project_name_token_values(self):
        """Resolve tokens for developer auto project_name (snapshot now once)."""
        now = datetime.now()
        project_type = tools_qt.get_text(self.dlg_readsql_create_project, self.cmb_create_project_type)
        if not project_type or project_type == 'null':
            project_type = 'ws'

        if self.rdb_sample_inv is not None and self.rdb_sample_inv.isChecked():
            project_profile = 'inventory'
        elif self.rdb_sample_full is not None and self.rdb_sample_full.isChecked():
            project_profile = 'sample'
        else:
            project_profile = 'empty'

        version = re.sub(r'\D', '', str(self.plugin_version or ''))

        return {
            'project_type': project_type.lower(),
            'version': version,
            'project_profile': project_profile,
            'YYYYMMDD': now.strftime('%Y%m%d'),
            'YYYYMM': now.strftime('%Y%m'),
            'MMDD': now.strftime('%m%d'),
            'HHMM': now.strftime('%H%M'),
            'YYYY': now.strftime('%Y'),
            'MM': now.strftime('%m'),
            'DD': now.strftime('%d'),
        }

    def _build_dev_project_name(self):
        """Build project_name from init.btn_admin tokens + separator."""
        default_tokens = 'project_type,version,project_profile,YYYYMMDD,HHMM'
        # Read plugin user_params (gw_dev_mode) so each developer can edit their checkout
        tokens_raw = tools_gw.get_config_parser(
            'init.btn_admin', 'dev_project_name_tokens', "project", "user_params",
            prefix=False, chk_user_params=False, force_reload=True)
        separator = tools_gw.get_config_parser(
            'init.btn_admin', 'dev_project_name_separator', "project", "user_params",
            prefix=False, chk_user_params=False, force_reload=True)

        if not tokens_raw or tokens_raw in ('None', 'null'):
            tokens_raw = default_tokens
        if separator is None or separator in ('None', 'null'):
            separator = '_'
        # Schema names only allow [a-z0-9_]; coerce invalid separators to '_'
        if separator not in ('', '_'):
            separator = '_'

        token_values = self._dev_project_name_token_values()
        parts = []
        for token in tokens_raw.split(','):
            key = token.strip()
            if not key:
                continue
            value = token_values.get(key)
            if value:
                parts.append(value)

        return separator.join(parts) if parts else ''

    def _apply_dev_project_name(self):
        """Auto-fill project_name when GwDevMode is on."""
        if not global_vars.gw_dev_mode:
            return
        if self.project_name is None:
            return
        name = self._build_dev_project_name()
        if name:
            self.project_name.setText(name)

    # region private functions

    def _fill_table(self, qtable, table_name, model, expr_filter, edit_strategy=QSqlTableModel.EditStrategy.OnManualSubmit):
        """ Set a model with selected filter.
        Attach that model to selected table """

        schema_name = self._get_selected_schema_name()
        if schema_name not in table_name:
            table_name = schema_name + "." + table_name

        # Set model
        model.setTable(table_name)
        model.setEditStrategy(edit_strategy)
        if expr_filter is not None:
            model.setFilter(expr_filter)
        model.select()

        # Check for errors
        if model.lastError().isValid():
            if 'Unable to find table' in model.lastError().text():
                tools_db.reset_qsqldatabase_connection()
            else:
                message = model.lastError().text()
                tools_qgis.show_warning(message)
        # Attach model to table view
        qtable.setModel(model)

    def _populate_combo_connections(self):
        """ Fill the combo with the connections that exist in QGis """

        s = QSettings()
        s.beginGroup("PostgreSQL/connections")
        default_connection = s.value('selected')
        connections = s.childGroups()
        self.list_connections = []
        for con in connections:
            elem = [con, con]
            self.list_connections.append(elem)
        s.endGroup()

        return default_connection

    def _load_connection_service_flag(self, connection_name):
        settings = QSettings()
        settings.beginGroup(f"PostgreSQL/connections/{connection_name}")
        self.is_service = settings.value('service')
        settings.endGroup()

    def _needs_credentials_dialog(self, connection_name):
        """True when GwCredentialsUi should open (host-based connections only).

        pg_service connections prompt via QgsCredentials in ensure_service_auth,
        not through GwCredentialsUi.
        """
        if not connection_name:
            return True
        settings = QSettings()
        settings.beginGroup(f"PostgreSQL/connections/{connection_name}")
        service = settings.value('service')
        if service:
            settings.endGroup()
            return False
        host = settings.value('host')
        db = settings.value('database')
        user = settings.value('username')
        password = settings.value('password')
        settings.endGroup()
        if not host or not db:
            return True
        if not user:
            return True
        if password is None:
            return True
        return False

    def _prepare_connection_credentials(self, connection_name):
        """Resolve credentials; prompt QgsCredentials for pg_service without auth.

        Returns (ok, credentials).
        """
        credentials = self._get_connection_credentials(connection_name)
        if not credentials.get('service'):
            return True, credentials
        ok, credentials = tools_db.ensure_service_auth(credentials)
        return ok, credentials

    def _current_connection_name(self) -> str:
        if not hasattr(self, 'dlg_readsql') or not self.dlg_readsql:
            return ''
        if getattr(self, 'cmb_connection', None) is None:
            return ''
        return str(tools_qt.get_text(self.dlg_readsql, self.cmb_connection) or '')

    def _schema_session_key(self, connection_name=None) -> str:
        connection_name = connection_name or self._current_connection_name()
        if connection_name:
            return f'schema_name_{connection_name}'
        return 'schema_name'

    def _get_saved_schema_name(self, connection_name=None) -> str:
        key = self._schema_session_key(connection_name)
        saved = tools_gw.get_config_parser(
            'btn_admin', key, "user", "session", False, force_reload=True
        )
        if saved and saved not in ('null', 'None', 'none'):
            return str(saved)
        return ''

    def _clear_saved_schema_name(self, schema_name, connection_name=None):
        connection_name = connection_name or self._current_connection_name()
        key = self._schema_session_key(connection_name)
        saved = self._get_saved_schema_name(connection_name)
        if saved == schema_name:
            tools_gw.set_config_parser('btn_admin', key, 'null', prefix=False)
        # Clear legacy global key if it still points at the deleted schema
        legacy = tools_gw.get_config_parser(
            'btn_admin', 'schema_name', "user", "session", False, force_reload=True
        )
        if legacy == schema_name:
            tools_gw.set_config_parser('btn_admin', 'schema_name', 'null', prefix=False)

    def _get_connection_credentials(self, connection_name):
        credentials = {
            'db': None, 'schema': None, 'table': None, 'service': None,
            'host': None, 'port': None, 'user': None, 'password': None, 'sslmode': None,
        }
        settings = QSettings()
        settings.beginGroup(f"PostgreSQL/connections/{connection_name}")
        credentials['host'] = settings.value('host')
        if settings.value('host') in (None, ""):
            credentials['host'] = 'localhost'
        credentials['port'] = settings.value('port')
        credentials['db'] = settings.value('database')
        credentials['user'] = settings.value('username')
        credentials['password'] = settings.value('password')
        credentials['service'] = settings.value('service')
        sslmode_settings = settings.value('sslmode')
        try:
            sslmode_dict = {0: 'prefer', 1: 'disable', 3: 'require'}
            sslmode = sslmode_dict.get(sslmode_settings, 'prefer')
        except (TypeError, ValueError):
            sslmode = sslmode_settings or 'prefer'
        credentials['sslmode'] = sslmode
        settings.endGroup()
        return credentials

    def _cancel_admin_load_task(self):
        if getattr(self, '_admin_load_task', None) is not None:
            try:
                if not isdeleted(self._admin_load_task):
                    self._admin_load_task.cancel()
            except Exception:
                pass
            self._admin_load_task = None

    def _clear_project_schema_combo(self):
        if not hasattr(self, 'dlg_readsql') or not self.dlg_readsql:
            return
        combo = getattr(self.dlg_readsql, 'project_schema_name', None)
        if combo is None:
            return
        combo.blockSignals(True)
        combo.clear()
        combo.blockSignals(False)

    def _show_admin_loading_state(self):
        self._admin_loading = True
        ignore_widgets = _admin_connection_ignore_widgets()
        tools_qt.enable_dialog(self.dlg_readsql, False, ignore_widgets)
        self._clear_project_schema_combo()
        msg = "Connecting..."
        tools_qt.set_widget_text(self.dlg_readsql, 'lbl_status_text', tools_qt.tr(msg))
        tools_qt.set_widget_text(self.dlg_readsql, 'lbl_schema_name', '')

    def _apply_connection_failure(self, message, close_for_credentials=False, connection_name=None):
        self._admin_loading = False
        self.form_enabled = False
        if close_for_credentials and not self.is_service:
            self._close_dialog_admin(self.dlg_readsql)
            self._create_credentials_form(set_connection=connection_name)
            return
        ignore_widgets = _admin_connection_ignore_widgets()
        tools_qt.enable_dialog(self.dlg_readsql, False, ignore_widgets)
        self._clear_project_schema_combo()
        self.dlg_readsql.lbl_status.setPixmap(self.status_ko)
        tools_qt.set_widget_text(self.dlg_readsql, 'lbl_status_text', message)
        tools_qt.set_widget_text(self.dlg_readsql, 'lbl_schema_name', '')
        self.dlg_readsql.btn_gis_create.setEnabled(False)

    def _start_admin_load(self, connection_name, try_set_connection=False, show_dialog=False):
        self._admin_show_dialog = show_dialog
        self._cancel_admin_load_task()
        self._load_connection_service_flag(connection_name)

        if not show_dialog:
            self._start_admin_load_sync(connection_name)
            return

        cached = self._schema_cache.get(connection_name)
        if cached and cached.ok and lib_vars.session_vars.get('logged_status') and not try_set_connection:
            self._apply_admin_load_result(cached, connection_name)
            return

        self._show_admin_loading_state()
        self._extensions_checked = False
        self._cached_pg_versions = None
        self._admin_catalog_cache = None

        ok, credentials = self._prepare_connection_credentials(connection_name)
        if not ok:
            msg = "Connection Failed. Please, check connection parameters"
            err = lib_vars.session_vars.get('last_error') or tools_qt.tr(msg)
            if self.is_service and not tools_db.is_db_auth_error(err):
                if err:
                    msg = ("There is an error in the configuration of the pgservice file, "
                           "please check it or consult your administrator ({0})")
                    self._apply_connection_failure(tools_qt.tr(msg, list_params=(err,)))
                else:
                    msg = ("There is an error in the configuration of the pgservice file, "
                           "please check it or consult your administrator")
                    self._apply_connection_failure(tools_qt.tr(msg))
            else:
                self._apply_connection_failure(err)
            return

        description = f"Admin load ({connection_name})"
        task = GwAdminLoadTask(description, credentials, connection_name)
        task.bind_admin(self)
        self._admin_load_task = task
        self._pending_try_set_connection = try_set_connection
        QgsApplication.taskManager().addTask(task)

    def _build_admin_load_result_sync(self, connection_name) -> AdminLoadResult:
        result = AdminLoadResult(connection_name=connection_name)
        result.sys_version_schemas = admin_catalog.fetch_sys_version_schemas()
        result.aux_flags = admin_catalog.fetch_aux_schema_flags()
        row = tools_db.get_row("SELECT current_setting('server_version_num')", commit=False)
        if row:
            result.pg_version = str(row[0])
        ext_rows = tools_db.get_rows(
            "SELECT extname FROM pg_extension WHERE extname = ANY(%s)",
            commit=False,
            params=[list(READ_EXTENSIONS)],
        )
        installed = {str(r[0]) for r in ext_rows} if ext_rows else set()
        result.extensions_present = {name: name in installed for name in READ_EXTENSIONS}
        if result.extensions_present.get('postgis'):
            row = tools_db.get_row("SELECT postgis_lib_version()", commit=False)
            if row:
                result.postgis_version = str(row[0])
        if result.extensions_present.get('pgrouting'):
            row = tools_db.get_row("SELECT pgr_version()", commit=False)
            if row:
                result.pgrouting_version = str(row[0])
        result.ok = True
        return result

    def _refresh_admin_catalog_cache(self):
        connection_name = str(tools_qt.get_text(self.dlg_readsql, self.cmb_connection))
        self._invalidate_admin_schema_cache()
        result = self._build_admin_load_result_sync(connection_name)
        self._schema_cache[connection_name] = result
        self._admin_catalog_cache = result
        return result

    def reload_connection_for_manage_schemas(self, connection_name: str) -> bool:
        """Switch PostgreSQL connection while Manage schemas is open."""
        connection_name = str(connection_name or "").strip()
        if not connection_name:
            return False

        self._schema_cache.pop(connection_name, None)
        self._cached_pg_versions = None
        self._extensions_checked = False
        self._load_connection_service_flag(connection_name)

        ok, credentials = self._prepare_connection_credentials(connection_name)
        if not ok:
            msg = "Connection failed. Please, check connection parameters"
            err = lib_vars.session_vars.get("last_error") or tools_qt.tr(msg)
            tools_qt.show_info_box(err, "Info")
            return False

        if not tools_db.ping_database(credentials):
            err = lib_vars.session_vars.get("last_error") or ""
            if tools_db.is_db_auth_error(err):
                ok, credentials = tools_db.ensure_service_auth(credentials)
                if ok and tools_db.ping_database(credentials):
                    pass
                else:
                    msg = "Connection failed. Please, check connection parameters"
                    title = "Info"
                    tools_qt.show_info_box(err or msg, title)
                    return False
            else:
                msg = "Connection failed. Please, check connection parameters"
                title = "Info"
                tools_qt.show_info_box(msg, title)
                return False

        self.logged, credentials = tools_db.connect_to_database_credentials(
            credentials, max_attempts=0
        )
        if not self.logged:
            msg = "Connection failed. Please, check connection parameters"
            err = lib_vars.session_vars.get("last_error") or msg
            title = "Info"
            tools_qt.show_info_box(err, title)
            return False

        tools_db.dao_db_credentials = credentials
        lib_vars.session_vars["logged_status"] = True

        result = self._build_admin_load_result_sync(connection_name)
        self._schema_cache[connection_name] = result
        self._admin_catalog_cache = result
        self.postgresql_version = result.pg_version
        self.postgis_version = result.postgis_version
        self.pgrouting_version = result.pgrouting_version
        self._cached_pg_versions = {
            "pg": result.pg_version,
            "postgis": result.postgis_version,
            "pgrouting": result.pgrouting_version,
        }
        self.connection_name = connection_name
        self._set_last_connection(connection_name)
        self.username = self._get_user_connection(connection_name)

        if getattr(self, "cmb_connection", None) is not None:
            self.cmb_connection.blockSignals(True)
            tools_qt.set_combo_value(self.cmb_connection, connection_name, 1)
            self.cmb_connection.blockSignals(False)

        if getattr(self, "dlg_readsql", None) is not None:
            self.dlg_readsql.project_schema_name.blockSignals(True)
            self._populate_data_schema_name()
            self.dlg_readsql.project_schema_name.blockSignals(False)
            self._set_info_project()

        update_info = getattr(self, "_manage_schemas_update_system_info", None)
        if update_info:
            update_info()
        self._ensure_language_packages_for_connection(force=True)
        return True

    def _ensure_language_packages_for_connection(self, *, force: bool = False) -> None:
        """Start automatic language-file provisioning for the active DB connection."""
        try:
            from .i18n.auto_language_provision import ensure_language_packages_after_connection
            ensure_language_packages_after_connection(force=force)
        except Exception as exc:
            msg = "Automatic language provisioning failed to start: {0}"
            msg_params = (exc,)
            tools_log.log_warning(msg, msg_params=msg_params)
            self._i18n_provision_after_load = False

    def _start_admin_load_sync(self, connection_name):
        self._extensions_checked = False
        self._cached_pg_versions = None
        self._admin_catalog_cache = None
        ok, credentials = self._prepare_connection_credentials(connection_name)
        if not ok:
            return
        if not tools_db.ping_database(credentials):
            err = lib_vars.session_vars.get("last_error") or ""
            if tools_db.is_db_auth_error(err):
                ok, credentials = tools_db.ensure_service_auth(credentials)
                if not ok or not tools_db.ping_database(credentials):
                    return
            else:
                return
        self.logged, credentials = tools_db.connect_to_database_credentials(credentials, max_attempts=0)
        if not self.logged:
            return
        tools_db.dao_db_credentials = credentials
        lib_vars.session_vars['logged_status'] = True
        result = self._build_admin_load_result_sync(connection_name)
        self._schema_cache[connection_name] = result
        self._apply_admin_load_result(result, connection_name)

    def _on_admin_load_finished(self, result: AdminLoadResult, task_result: bool):
        connection_name = result.connection_name

        # Stale result from a previous connection: leave the active load alone
        current = self._current_connection_name()
        if connection_name and current and connection_name != current:
            tools_log.log_info(
                f"Ignoring stale admin load for '{connection_name}' (current: '{current}')"
            )
            return

        self._admin_load_task = None

        # Cancelled task: do not treat as connection failure
        if not task_result and not result.ok and not result.error:
            self._admin_loading = False
            return

        try:
            if not task_result or not result.ok:
                err = result.error or lib_vars.session_vars.get('last_error') or ''
                # Auth failure on pg_service: prompt and retry once on the main thread
                if self.is_service and tools_db.is_db_auth_error(err):
                    ok, credentials = self._prepare_connection_credentials(connection_name)
                    if ok and tools_db.ping_database(credentials):
                        self.logged, credentials = tools_db.connect_to_database_credentials(
                            credentials, max_attempts=0
                        )
                        if self.logged:
                            tools_db.dao_db_credentials = credentials
                            lib_vars.session_vars['logged_status'] = True
                            sync_result = self._build_admin_load_result_sync(connection_name)
                            self._schema_cache[connection_name] = sync_result
                            self._apply_admin_load_result(sync_result, connection_name)
                            return
                    msg = "Connection Failed. Please, check connection parameters"
                    self._apply_connection_failure(err or tools_qt.tr(msg))
                    return
                if self.is_service:
                    if err:
                        msg = ("There is an error in the configuration of the pgservice file, "
                               "please check it or consult your administrator ({0})")
                        msg_params = (err,)
                        self._apply_connection_failure(
                            tools_qt.tr(msg, list_params=msg_params)
                        )
                    else:
                        msg = ("There is an error in the configuration of the pgservice file, "
                               "please check it or consult your administrator")
                        self._apply_connection_failure(tools_qt.tr(msg))
                else:
                    if err:
                        msg = "Connection Failed. Please, check connection parameters ({0})"
                        msg_params = (err,)
                    else:
                        msg = "Connection Failed. Please, check connection parameters"
                        msg_params = None
                    tools_qgis.show_message(msg, Qgis.MessageLevel.Warning, msg_params=msg_params)
                    self._apply_connection_failure(
                        tools_qt.tr(msg, list_params=msg_params),
                        close_for_credentials=True, connection_name=connection_name
                    )
                return

            ok, credentials = self._prepare_connection_credentials(connection_name)
            if not ok:
                message = "Connection Failed. Please, check connection parameters"
                msg = lib_vars.session_vars.get('last_error') or tools_qt.tr(message)
                self._apply_connection_failure(msg)
                return
            self.logged, credentials = tools_db.connect_to_database_credentials(credentials, max_attempts=0)
            if not self.logged:
                message = "Connection Failed. Please, check connection parameters"
                msg = lib_vars.session_vars.get('last_error') or tools_qt.tr(message)
                if self.is_service and tools_db.is_db_auth_error(msg):
                    self._apply_connection_failure(msg)
                elif self.is_service:
                    self._apply_connection_failure(msg)
                else:
                    tools_qgis.show_message(msg, Qgis.MessageLevel.Warning)
                    self._apply_connection_failure(msg, close_for_credentials=True, connection_name=connection_name)
                return

            tools_db.dao_db_credentials = credentials
            lib_vars.session_vars['logged_status'] = True
            self._schema_cache[connection_name] = result
            self._apply_admin_load_result(result, connection_name)
        except Exception:
            self._admin_loading = False
            raise

    def _ensure_extensions_checked(self):
        if self._extensions_checked:
            return
        for ext in ('postgis', 'pgrouting', 'postgis_raster', 'tablefunc', 'unaccent', 'fuzzystrmatch', 'intarray'):
            tools_db.check_pg_extension(ext)
        self._extensions_checked = True
        if self._cached_pg_versions is not None:
            self._cached_pg_versions['postgis'] = tools_db.get_postgis_version()
            self._cached_pg_versions['pgrouting'] = tools_db.get_pgrouting_version()
            self.postgis_version = self._cached_pg_versions['postgis']
            self.pgrouting_version = self._cached_pg_versions['pgrouting']

    def _apply_admin_load_result(self, result: AdminLoadResult, connection_name):
        self._admin_catalog_cache = result
        self._admin_loading = False
        self.form_enabled = True
        self.connection_name = connection_name
        self.postgresql_version = result.pg_version
        self.postgis_version = result.postgis_version
        self.pgrouting_version = result.pgrouting_version
        self._cached_pg_versions = {
            'pg': result.pg_version,
            'postgis': result.postgis_version,
            'pgrouting': result.pgrouting_version,
        }

        self._set_last_connection(connection_name)
        self.username = self._get_user_connection(connection_name)

        # Restore widgets after a previous incompatible-PG / failure disable, then
        # let _finalize_admin_permissions_and_status selectively re-disable if needed.
        tools_qt.enable_dialog(self.dlg_readsql, True)

        self.dlg_readsql.project_schema_name.blockSignals(True)
        self._populate_data_schema_name()
        self.dlg_readsql.project_schema_name.blockSignals(False)

        self._ensure_extensions_checked()
        self._finalize_admin_permissions_and_status()
        self._set_info_project()
        self._update_admin_status_bar()
        self._update_manage_ui()
        self._manage_utils()
        self._set_buttons_enabled()
        self._init_gis_project_form()

        refresh = getattr(self, "_manage_schemas_refresh", None)
        if refresh:
            refresh()
        update_info = getattr(self, "_manage_schemas_update_system_info", None)
        if update_info:
            update_info()
        manage_cmb = getattr(self, "_manage_schemas_sync_connection", None)
        if manage_cmb:
            manage_cmb(connection_name)

        force = bool(getattr(self, "_i18n_provision_after_load", False))
        self._i18n_provision_after_load = False
        self._ensure_language_packages_for_connection(force=force)
        tools_gw.add_giswater_language_menu()

    def _finalize_admin_permissions_and_status(self):
        message = ''
        if not tools_db.check_role(self.username, is_admin=True) and not getattr(self, '_admin_show_dialog', False):
            msg = "User not found"
            tools_log.log_warning(msg, parameter=self.username)
            self.form_enabled = False

        if self.postgresql_version and int(self.postgresql_version) not in range(
                self.lower_postgresql_version, self.upper_postgresql_version) and self.form_enabled:
            message = "Incompatible version of PostgreSQL"
            self.form_enabled = False

        if not self._can_administer_schemas():
            message = _ADMIN_PERMISSION_MESSAGE
            self.form_enabled = False
        elif self.form_enabled:
            schema_name = self._get_selected_schema_name() or 'null'
            db_name = tools_db.dao_db_credentials.get('db') if tools_db.dao_db_credentials else ''
            if any(x in str(db_name) for x in ('.', ',')):
                message = "Database name contains special characters that are not supported"
                self.form_enabled = False
            elif schema_name == 'null':
                tools_qt.set_widget_text(self.dlg_readsql, self.dlg_readsql.lbl_schema_name, '')
            tools_qt.enable_dialog(self.dlg_readsql, True)

        if self.form_enabled is False and message and message != _ADMIN_PERMISSION_MESSAGE:
            self.dlg_readsql.lbl_status.setPixmap(self.status_ko)
            tools_qt.set_widget_text(self.dlg_readsql, 'lbl_status_text', message)
            tools_qt.set_widget_text(self.dlg_readsql, 'lbl_schema_name', '')
            ignore_widgets = _admin_connection_ignore_widgets()
            tools_qt.enable_dialog(self.dlg_readsql, False, ignore_widgets)

        self._update_advanced_tab_visibility()

    def _init_show_database(self):
        """ Initialization code of the form (to be executed only once) """

        # Get SQL folder and check if exists
        self.sql_dir = os.path.normpath(os.path.join(lib_vars.plugin_dir, 'dbmodel'))
        if not os.path.exists(self.sql_dir):
            msg = "SQL folder not found"
            tools_qgis.show_message(msg, parameter=self.sql_dir)
            return

        self.project_version = '0'

        # Get locale of QGIS application
        self.locale = tools_qgis.get_locale()

        # Declare all file variables
        self.file_pattern_ddl = "ddl"
        self.file_pattern_utils = "utils"
        self.file_pattern_i18n = "i18n"
        self.file_pattern_fct = "fct"
        self.file_pattern_ftrg = "ftrg"
        self.file_pattern_schema_model = "schema_model"

        # Declare all folders
        # Network schemas (ws/ud) live under schemas/main/<project_type>/
        if self.schema_name is not None and self.project_type is not None:
            self.folder_software = os.path.join(self.sql_dir, 'schemas', 'main', self.project_type)
        else:
            self.folder_software = ""

        self.folder_locale = os.path.join(self.sql_dir, self.file_pattern_i18n, self.locale)
        # 'common' replaces the legacy 'utils' shared-code folder for ws/ud.
        self.folder_common = os.path.join(self.sql_dir, 'schemas', 'main', 'common')
        # Upgrade changelog UI uses giswater_admin.engine.changelog
        # (common + ws|ud under schemas/main/*/updates).
        self.folder_updates = os.path.join(self.folder_common, 'updates')
        self.folder_sample = os.path.join(self.folder_software, 'sample')

        # Declare asset db folders
        self.sql_asset_dir = os.path.join(self.sql_dir, 'schemas', 'addon', 'am')
        self.folder_base = os.path.join(self.sql_asset_dir, 'base')
        self.folder_i18n = os.path.join(self.sql_asset_dir, self.file_pattern_i18n)
        self.folder_asset_updates = os.path.join(self.sql_asset_dir, 'updates')

        # Declare audit db folders
        self.sql_audit_dir = os.path.join(self.sql_dir, 'schemas', 'audit')
        self.folder_audit_structure = os.path.join(self.sql_audit_dir, 'structure')
        self.folder_audit_activate = os.path.join(self.sql_audit_dir, 'activate')

        # Declare cm db folders
        self.sql_cm_dir = os.path.join(self.sql_dir, 'schemas', 'cm')
        self.folder_cm_common = os.path.join(self.sql_cm_dir, "common")
        self.folder_cm_locale = os.path.join(self.sql_cm_dir, self.file_pattern_i18n, self.locale)
        self.folder_cm_base = os.path.join(self.sql_cm_dir, 'base')
        self.folder_cm_parent_schema = os.path.join(self.sql_cm_dir, 'parent_schema')
        self.folder_cm_sample = os.path.join(self.sql_cm_dir, 'sample')

        # Variable to commit changes even if schema creation fails
        self.dev_commit = tools_os.set_boolean(
            tools_gw.get_config_parser('system', 'force_commit', "user", "init", prefix=True),
            False
        )

        # Create dialog object
        self.dlg_readsql = GwAdminUi(self)
        tools_gw.load_settings(self.dlg_readsql)

        # DEPRECATED tab_dev — widgets/handlers kept for migration to another repo.
        # See: btn_create_utils, btn_update_utils, cmb_utils_ws/ud, btn_create_cibs,
        # btn_adapt_cibs, cmb_cibs, btn_create_qgis_template, btn_markdown_generator
        # (tab_dev in admin.ui).
        tools_qt.remove_tab(self.dlg_readsql.tab_main, "tab_dev")

        for _gb_name in ('groupBox_2', 'groupBox', 'groupBox_cibs'):
            _gb = self.dlg_readsql.findChild(QGroupBox, _gb_name)
            if _gb is not None:
                _gb.setVisible(False)

        self.project_types = tools_gw.get_config_parser('system', 'project_types', "project", "giswater", False,
                                                        force_reload=True)
        self.project_types = self.project_types.split(',')

        # Get widgets form
        self.cmb_connection = self.dlg_readsql.findChild(QComboBox, 'cmb_connection')
        self.lbl_schema_name = self.dlg_readsql.findChild(QLabel, 'lbl_schema_name')

        # Checkbox SCHEMA
        self.chk_schema_view = self.dlg_readsql.findChild(QCheckBox, 'chk_schema_view')
        self.software_version_info = self.dlg_readsql.findChild(QTextEdit, 'software_version_info')

        # Force reload to locale when opening admin dialog
        lib_vars.schema_name = None
        tools_qt._add_translator(True)

        # Set Listeners
        self._set_signals()

        # Set shortcut keys
        self.dlg_readsql.key_escape.connect(partial(tools_gw.close_dialog, self.dlg_readsql))

        self._update_advanced_tab_visibility()
        self._set_schema_crud_visible(False)

    def _set_signals(self):
        """ Set signals. Function has to be executed only once (during form initialization) """

        self.dlg_readsql.btn_close.clicked.connect(partial(self._close_dialog_admin, self.dlg_readsql))
        self.dlg_readsql.btn_schema_create.clicked.connect(partial(self._open_create_project))
        self.dlg_readsql.btn_custom_load_file.clicked.connect(
            partial(self._load_custom_sql_files, self.dlg_readsql, "custom_path_folder"))
        self.dlg_readsql.btn_reload_fct_ftrg.clicked.connect(partial(self._reload_fct_ftrg))
        self.dlg_readsql.btn_vacuum.clicked.connect(partial(self.execute_vacuum, True, True))
        self.dlg_readsql.btn_info.clicked.connect(partial(self._open_update_info))
        self.dlg_readsql.project_schema_name.currentIndexChanged.connect(partial(self._sync_project_type_from_schema))
        self.dlg_readsql.project_schema_name.currentIndexChanged.connect(partial(self._set_info_project))
        self.dlg_readsql.project_schema_name.currentIndexChanged.connect(partial(self._update_manage_ui))
        self.dlg_readsql.project_schema_name.currentIndexChanged.connect(partial(self._init_gis_project_form))
        self.dlg_readsql.project_schema_name.currentIndexChanged.connect(partial(self._set_buttons_enabled))
        self.dlg_readsql.project_schema_name.currentIndexChanged.connect(partial(self._update_admin_status_bar))
        self.dlg_readsql.btn_custom_select_file.clicked.connect(
            partial(tools_qt.get_folder_path, self.dlg_readsql, "custom_path_folder"))
        self.cmb_connection.currentIndexChanged.connect(partial(self._event_change_connection))
        self.dlg_readsql.btn_schema_rename.clicked.connect(partial(self._open_rename))
        self.dlg_readsql.btn_delete.clicked.connect(partial(self._delete_schema))
        self.dlg_readsql.btn_copy.clicked.connect(partial(self._copy_schema))
        self.dlg_readsql.btn_create_qgis_template.clicked.connect(partial(self._create_qgis_template))
        self.dlg_readsql.btn_gis_folder.clicked.connect(
            partial(tools_qt.get_folder_path, self.dlg_readsql, "txt_gis_folder"))
        self.dlg_readsql.btn_gis_create.clicked.connect(partial(self._gis_create_project))
        self.dlg_readsql.btn_manage_schemas.clicked.connect(partial(self._open_manage_schemas))
        self.dlg_readsql.dlg_closed.connect(partial(self._save_selection))
        self.dlg_readsql.dlg_closed.connect(partial(self._save_custom_sql_path, self.dlg_readsql))
        self.dlg_readsql.dlg_closed.connect(partial(self._close_dialog_admin, self.dlg_readsql))

        self.dlg_readsql.btn_create_utils.clicked.connect(partial(self._create_utils))
        self.dlg_readsql.btn_update_utils.clicked.connect(partial(self._update_utils))
        self.dlg_readsql.btn_create_cibs.clicked.connect(partial(self._create_cibs))
        self.dlg_readsql.btn_adapt_cibs.clicked.connect(partial(self._adapt_cibs))

        self.dlg_readsql.btn_create_field.clicked.connect(partial(self._open_manage_field, 'create'))
        self.dlg_readsql.btn_update_field.clicked.connect(partial(self._open_manage_field, 'update'))
        self.dlg_readsql.btn_delete_field.clicked.connect(partial(self._open_manage_field, 'delete'))
        self.dlg_readsql.btn_import_osm_streetaxis.clicked.connect(partial(self._import_osm))

        # Asset manage buttons
        self.dlg_readsql.btn_create_asset.clicked.connect(partial(self.create_project_data_other_schema, 'am'))
        self.dlg_readsql.btn_update_asset.clicked.connect(partial(self._update_asset))
        self.dlg_readsql.btn_delete_asset.clicked.connect(partial(self._delete_other_schema, 'am'))

        # Campaign manage buttons
        self.dlg_readsql.btn_create_cm.clicked.connect(partial(self._open_manage_schemas))
        self.dlg_readsql.btn_update_cm.clicked.connect(partial(self._update_cm))
        self.dlg_readsql.btn_delete_cm.clicked.connect(partial(self._delete_other_schema, 'cm'))

        # Audit buttons
        self.dlg_readsql.btn_create_audit.clicked.connect(partial(self.create_project_data_other_schema, 'audit'))
        self.dlg_readsql.btn_activate_audit.clicked.connect(partial(self._activate_audit, 'audit'))
        self.dlg_readsql.btn_reload_audit_triggers.clicked.connect(partial(self._reload_audit_triggers))
        self.dlg_readsql.btn_delete_audit.clicked.connect(partial(self._delete_other_schema, 'audit'))

        # i18n
        self.dlg_readsql.btn_manage_languages.clicked.connect(partial(self._manage_languages_hot_update))

        # Markdown generator
        self.dlg_readsql.btn_markdown_generator.clicked.connect(partial(self._markdown_generator))

    def _activate_audit(self, other_project, parent_schema=None, parent_type=None):
        """ Activate audit functionality """

        self.other_project = other_project
        if admin_catalog.schema_exists('audit'):
            msg = "This process will active snapshot. Are you sure to continue?"
            title = "Activate water netowrk snapshot"
            answer = tools_qt.show_question(msg, title)
            if not answer:
                return
            self.create_process(
                "audit_activation",
                parent_schema=parent_schema,
                parent_type=parent_type,
            )
        else:
            msg = "Schema audit not found, please create it first"
            tools_qgis.show_warning(msg)

    def _reload_audit_triggers(self, schema_name=None):
        """ Update audit triggers to start or stop auditing a table """

        schema_name = schema_name or self._get_schema_name()
        result = tools_gw.execute_procedure('gw_fct_update_audit_triggers', schema_name=schema_name)

        if result:
            msg = "Triggers updated successfully"
            tools_qgis.show_success(msg)

    def _markdown_generator(self):
        """ Initialize the markdown generator functionalities """

        qm_gen = GwAdminMarkdownGenerator()
        qm_gen.init_dialog()

    def _manage_languages_hot_update(self):
        """ Initialize the language functionalities """
        dlg = getattr(self, 'dlg_i18n_hot_update', None)
        if dlg is not None and not isdeleted(dlg) and dlg.isVisible():
            tools_gw.focus_open_dialog(dlg)
            return

        manager = GwAdminI18NHotUpdate(self)
        manager.init_dialog()
        self.dlg_i18n_hot_update = manager.dlg_qm

    def _import_osm(self):
        """ Initialize import osm streetaxis functionality """

        dlg_import_osm = GwImportOsm()
        dlg_import_osm.init_dialog(self._get_schema_name())

    def _info_show_database(self, connection_status=True, username=None, show_dialog=False,
                            connection_name=None, try_set_connection=False):
        """Prepare admin UI shell and load database metadata asynchronously."""

        self.message_update = ''
        self.error_count = 0
        self.schema = None
        self._admin_show_dialog = show_dialog

        last_connection = connection_name or self._get_last_connection()

        self.username = username
        if username in (None, False):
            self.username = self._get_user_connection(last_connection)

        self.dlg_readsql.lbl_status_text.setStyleSheet("QLabel {color:red;}")

        self.cmb_connection.blockSignals(True)
        self.dlg_readsql.project_schema_name.blockSignals(True)

        self._populate_combo_connections()
        if str(self.list_connections) != '[]':
            tools_qt.fill_combo_values(self.cmb_connection, self.list_connections)
        tools_qt.set_combo_value(self.cmb_connection, str(last_connection), 1)

        title = 'Giswater ({0})'
        title_params = (self.plugin_version,)
        self.dlg_readsql.setWindowTitle(tools_qt.tr(title, list_params=title_params))

        folder_path = tools_gw.get_config_parser(
            "btn_admin", "custom_sql_path", "user", "session", force_reload=True
        )
        tools_qt.set_widget_text(self.dlg_readsql, "custom_path_folder", folder_path)

        self.cmb_connection.blockSignals(False)
        self.dlg_readsql.project_schema_name.blockSignals(False)

        if show_dialog:
            self._manage_docker()

        if not connection_status and not self.is_service:
            msg = "Connection Failed. Please, check connection parameters"
            self._apply_connection_failure(
                tools_qt.tr(msg),
                close_for_credentials=True,
                connection_name=last_connection,
            )
            return

        # Service connections: always attempt load (may prompt QgsCredentials if
        # pg_service.conf omits user/password). Non-service already handled above.
        self._start_admin_load(
            last_connection,
            try_set_connection=try_set_connection or (self.is_service and not connection_status),
            show_dialog=show_dialog,
        )

    def _set_credentials(self, dialog, new_connection=False):
        """ Set connection parameters in settings """

        user_name = tools_qt.get_text(dialog, dialog.txt_user, False, False)
        password = tools_qt.get_text(dialog, dialog.txt_pass, False, False)
        settings = QSettings()
        settings.beginGroup("PostgreSQL/connections")
        default_connection = tools_qt.get_text(dialog, dialog.cmb_connection)
        settings.setValue('selected', default_connection)
        if new_connection:
            tools_db.set_database_connection()
        else:
            if default_connection:
                settings.endGroup()
                settings.beginGroup("PostgreSQL/connections/" + default_connection)
            settings.setValue('password', password)
            settings.setValue('username', user_name)
            settings.endGroup()

        self._close_dialog_admin(dialog)
        self.init_sql(True)

    def _gis_create_project(self):
        """Create a QGIS project from the inline form on the admin dialog."""

        schema_name = self._get_selected_schema_name()
        if not schema_name:
            msg = "In order to create a qgis project you have to create a schema first."
            tools_qt.show_info_box(msg)
            return

        gis_folder = tools_qt.get_text(self.dlg_readsql, 'txt_gis_folder')
        if gis_folder is None or gis_folder == 'null':
            msg = "GIS folder not set"
            tools_qgis.show_warning(msg)
            return

        tools_gw.set_config_parser('btn_admin', 'qgis_file_path', gis_folder, prefix=False)
        qgis_file_export = self.dlg_readsql.chk_export_passwd.isChecked()
        tools_gw.set_config_parser('btn_admin', 'qgis_file_export', qgis_file_export, prefix=False)

        gis_file = tools_qt.get_text(self.dlg_readsql, 'txt_gis_file')
        if gis_file is None or gis_file == 'null':
            msg = "GIS file name not set"
            tools_qgis.show_warning(msg)
            return

        project_type = self._get_selected_project_type() or 'ws'
        roletype = tools_qt.get_text(self.dlg_readsql, 'txt_roletype')
        export_passwd = tools_qt.is_checked(self.dlg_readsql, 'chk_export_passwd')

        if export_passwd and not self.is_service:
            msg = ("Credentials will be stored in the GIS project file as plain text, and will apply to "
                   "both existing and future layers. Do you want to proceed?")
            title = "Warning"
            answer = tools_qt.show_question(msg, title)
            if not answer:
                return

        layer_project_type = self._get_layer_project_type(schema_name)
        self._generate_qgis_project(
            gis_folder, gis_file, project_type, schema_name, export_passwd, roletype, layer_project_type
        )

    def _generate_qgis_project(
        self, gis_folder, gis_file, project_type, schema_name, export_passwd, roletype, layer_project_type
    ):
        """Generate QGIS project."""

        gis = GwGisFileCreate(self.plugin_dir)
        result, qgs_path = gis.gis_project_database(
            gis_folder, gis_file, project_type, schema_name, export_passwd,
            roletype, layer_project_type=layer_project_type, is_cm=self.is_cm_project,
        )

        if self.is_cm_project:
            self.is_cm_project = False

        self._close_dialog_admin(self.dlg_readsql)

        if result:
            self._open_project(qgs_path)

    def _get_layer_project_type(self, schema_name: str) -> str:
        rows = tools_db.execute_returning(
            f"SELECT id, idval FROM {schema_name}.config_typevalue WHERE typevalue = 'project_type'"
        )
        if not rows:
            return self._get_selected_project_type() or 'ws'
        try:
            result = {rows[i]: rows[i + 1] for i in range(0, len(rows), 2)}
        except Exception:
            return self._get_selected_project_type() or 'ws'
        if len(result) == 1:
            return str(next(iter(result.values())))
        return self._get_selected_project_type() or 'ws'

    def _init_gis_project_form(self):
        """Load inline GIS project form defaults from session and selected schema."""
        if not hasattr(self, 'dlg_readsql') or not self.dlg_readsql:
            return

        schema_name = self._get_selected_schema_name()
        if schema_name:
            tools_qt.set_widget_text(self.dlg_readsql, 'txt_gis_file', schema_name)

        qgis_file_path = tools_gw.get_config_parser(
            'btn_admin', 'qgis_file_path', "user", "session", prefix=False, force_reload=True
        )
        if qgis_file_path is None:
            qgis_file_path = os.path.expanduser("~")
        tools_qt.set_widget_text(self.dlg_readsql, 'txt_gis_folder', qgis_file_path)

        qgis_file_export = tools_gw.get_config_parser(
            'btn_admin', 'qgis_file_export', "user", "session", prefix=False, force_reload=True
        )
        self.dlg_readsql.chk_export_passwd.setChecked(tools_os.set_boolean(qgis_file_export, False))

        if getattr(self, 'is_service', False):
            self.dlg_readsql.lbl_export_user_pass.setVisible(False)
            self.dlg_readsql.chk_export_passwd.setVisible(False)

    def _open_project(self, qgs_path):
        """ Open a QGis project """

        project = QgsProject.instance()
        project.read(qgs_path)

        # Load Giswater plugin
        file_name = os.path.basename(self.plugin_dir)
        reloadPlugin(f"{file_name}")

    def _load_sql(self, path_folder: str, no_ct: bool = False, utils_schema_name: Union[str, None] = None, set_progress_bar: bool = False) -> bool:
        """
        Load SQL files from a given folder.

        :param path_folder: The path to the folder to load the SQL files from.
        :param no_ct: Whether to skip the CT processing.
        :param utils_schema_name: The name of the schema to use.
        :param set_progress_bar: Whether to set the progress bar.

        :return bool: True if all files were loaded successfully, False otherwise.
        """

        for (path, _, _) in os.walk(path_folder):
            status = self._execute_files(path, no_ct=no_ct, utils_schema_name=utils_schema_name,
                                         set_progress_bar=set_progress_bar)
            if not tools_os.set_boolean(status, False):
                return False

        return True

    """ Functions execute process """

    def _check_project_name(self, project_name, project_descript):
        """ Check if @project_name and @project_descript are is valid """

        sql = "SELECT word FROM pg_get_keywords() ORDER BY 1;"
        pg_keywords = tools_db.get_rows(sql, commit=False)

        # Check if project name is valid
        if project_name == 'null':
            msg = "The '{0}' field is required."
            msg_params = ("Project_name")
            tools_qt.show_info_box(msg, "Info", msg_params=msg_params)
            return False
        elif any(c.isupper() for c in project_name) is True:
            msg = "The project name can't have any upper-case characters"
            tools_qt.show_info_box(msg, "Info")
            return False
        elif (bool(re.match('^[a-z0-9_]*$', project_name))) is False:
            msg = "The project name has invalid character"
            tools_qt.show_info_box(msg, "Info")
            return False
        elif [project_name] in pg_keywords:
            msg = "The project name can't be a PostgreSQL reserved keyword"
            tools_qt.show_info_box(msg, "Info")
            return False

        if project_descript == 'null':
            msg = "The 'Description' field is required."
            tools_qt.show_info_box(msg, "Info")
            return False

        # Check is project name already exists
        rows = admin_catalog.schema_names_matching(f'%{project_name}%')

        available = True
        if rows:
            for schema_name in rows:
                if f"{project_name}" == f"{schema_name}":
                    available = False
                    break

        if available:
            return True

        list_schemas = [name for name in rows if f"{project_name}" in f"{name}"]
        new_name = self._bk_schema_name(list_schemas, f"{project_name}_bk_", 0)

        msg = "This 'Project_name' already exist. Do you want rename old schema to '{0}'"
        msg_params = (new_name,)
        result = tools_qt.show_question(msg, "Info", force_action=True, msg_params=msg_params)
        if result:
            self._rename_project_data_schema(str(project_name), str(new_name))
            return True
        else:
            return False

    def _bk_schema_name(self, list_schemas, project_name, i):
        """ Check for available bk schema name """

        if f"{project_name}{i}" not in list_schemas:
            return f"{project_name}{i}"
        else:
            return self._bk_schema_name(list_schemas, project_name, i + 1)

    def _rename_project_data_schema(self, schema, create_project=None):
        """"""
        if create_project is None:
            self.schema = tools_qt.get_text(self.dlg_readsql_rename, self.dlg_readsql_rename.schema_rename_copy)
            if str(self.schema) == str(schema):
                msg = "Please, select a diferent project name than current."
                tools_qt.show_info_box(msg, "Info")
                return
        else:
            self.schema = str(create_project)

        # Check if the new project name already exists
        if admin_catalog.schema_exists(str(self.schema)):
            msg = "This project name alredy exist."
            tools_qt.show_info_box(msg, "Info")
            return

        # Create timer
        self.t0 = time()
        self.timer = QTimer()
        if hasattr(self, 'dlg_readsql_rename') and not isdeleted(self.dlg_readsql_rename) and self.dlg_readsql_rename.isVisible():
            self.timer.timeout.connect(partial(self._calculate_elapsed_time, self.dlg_readsql_rename))
        self.timer.start(1000)

        # Set background task 'GwRenameSchemaTask'
        description = "Rename schema"
        params = {'schema': schema, 'new_schema_name': self.schema}
        self.task_rename_schema = GwRenameSchemaTask(self, description, params, timer=self.timer)
        QgsApplication.taskManager().addTask(self.task_rename_schema)
        QgsApplication.taskManager().triggerTask(self.task_rename_schema)

    def _load_custom_sql_files(self, dialog: QDialog, widget: QWidget) -> None:
        """
        Load custom SQL files from a given folder.

        :param dialog: The dialog to use.
        :param widget: The widget to use.

        :return bool: True if all files were loaded successfully, False otherwise.
        """

        folder_path = tools_qt.get_text(dialog, widget)
        if not isinstance(folder_path, str) or not folder_path:
            return

        self.task1 = GwTask('Manage schema')
        QgsApplication.taskManager().addTask(self.task1)
        self.task1.setProgress(50)
        self._load_sql(folder_path)
        self.task1.setProgress(100)

        status = (self.error_count == 0)
        self._manage_result_message(status, parameter="Load custom SQL files")
        if status:
            tools_db.dao.commit()
        else:
            tools_db.dao.rollback()

        # Reset count error variable to 0
        self.error_count = 0

    def _get_selected_schema_name(self) -> str:
        if not hasattr(self, 'dlg_readsql') or not self.dlg_readsql:
            return ''
        schema_name = tools_qt.get_combo_value(
            self.dlg_readsql, self.dlg_readsql.project_schema_name, 0
        )
        if not isinstance(schema_name, str) or not schema_name or schema_name == 'null':
            return ''
        return schema_name

    def _get_selected_project_type(self) -> str:
        """Return project type for the currently selected schema (catalog/sys_version).

        Must not short-circuit on stale self.project_type — that value lags until
        _set_info_project runs, and sync handlers fire before it.
        """
        schema_name = self._get_selected_schema_name()
        if not schema_name:
            return str(
                getattr(self, 'project_type', None)
                or getattr(self, 'project_type_selected', '')
                or ''
            ).lower()
        if self._admin_catalog_cache and self._admin_catalog_cache.sys_version_schemas:
            schemas = self._admin_catalog_cache.sys_version_schemas
        else:
            schemas = admin_catalog.fetch_sys_version_schemas()
        pt = admin_catalog.project_type_for_schema(schemas, schema_name)
        return str(
            pt
            or getattr(self, 'project_type', None)
            or getattr(self, 'project_type_selected', '')
            or ''
        ).lower()

    def _set_project_type_paths(self, project_type: str):
        self.project_type_selected = project_type
        self.folder_software = os.path.join(self.sql_dir, 'schemas', 'main', project_type)

    def _sync_project_type_from_schema(self):
        if getattr(self, '_admin_loading', False):
            return
        project_type = self._get_selected_project_type()
        if project_type:
            self._set_project_type_paths(project_type)

    def _can_administer_schemas(self) -> bool:
        """True for superuser, role_system member, or force_superuser override."""
        force_superuser = tools_gw.get_config_parser(
            'system', 'force_superuser', 'user', 'init', False, force_reload=True
        )
        if tools_os.set_boolean(force_superuser, False):
            return True
        conn_user = getattr(self, 'username', None) or tools_db.get_current_user()
        if not conn_user:
            return False
        return tools_db.check_super_user(conn_user) or tools_db.check_role_user(
            "role_system", conn_user
        )

    def _update_admin_status_bar(self):
        """Single source of truth for lbl_status / lbl_status_text."""
        if getattr(self, '_admin_loading', False) or not hasattr(self, 'dlg_readsql') or not self.dlg_readsql:
            return

        schema_name = self._get_selected_schema_name() or 'null'
        plugin_tuple = _admin_version_tuple(self.plugin_version)
        project_tuple = _admin_version_tuple(getattr(self, 'project_version', None) or '0')

        if self.postgresql_version is None or self.postgis_version is None or self.pgrouting_version is None:
            ignore_widgets = _admin_connection_ignore_widgets()
            tools_qt.enable_dialog(self.dlg_readsql, False, ignore_widgets)
            self.dlg_readsql.lbl_status.setPixmap(self.status_ko)
            msg = _ADMIN_EXTENSION_ERROR_MESSAGE
            tools_qt.set_widget_text(self.dlg_readsql, self.dlg_readsql.lbl_status_text, msg)
            tools_qt.set_widget_text(self.dlg_readsql, 'lbl_schema_name', '')
            return

        if not self._can_administer_schemas():
            if plugin_tuple > project_tuple:
                self.dlg_readsql.lbl_status.setPixmap(self.status_no_update)
                status_msg = _ADMIN_SCHEMA_OUTDATED_NONADMIN_MESSAGE
            elif plugin_tuple < project_tuple:
                self.dlg_readsql.lbl_status.setPixmap(self.status_no_update)
                status_msg = _ADMIN_PLUGIN_OUTDATED_NONADMIN_MESSAGE
            else:
                self.dlg_readsql.lbl_status.setPixmap(self.status_ok)
                status_msg = ''
            tools_qt.set_widget_text(self.dlg_readsql, self.dlg_readsql.lbl_status_text, status_msg)
            if schema_name != 'null':
                self.lbl_schema_name.setText(str(schema_name))
            return

        if not self.form_enabled:
            return

        if schema_name == 'null':
            tools_qt.set_widget_text(self.dlg_readsql, self.dlg_readsql.lbl_status_text, '')
            tools_qt.set_widget_text(self.dlg_readsql, self.dlg_readsql.lbl_schema_name, '')
            self.dlg_readsql.lbl_status.setPixmap(self.status_ok)
        elif plugin_tuple > project_tuple:
            self.dlg_readsql.lbl_status.setPixmap(self.status_no_update)
            tools_qt.set_widget_text(
                self.dlg_readsql, self.dlg_readsql.lbl_status_text, _ADMIN_SCHEMA_OUTDATED_MESSAGE
            )
        elif plugin_tuple < project_tuple:
            self.dlg_readsql.lbl_status.setPixmap(self.status_no_update)
            tools_qt.set_widget_text(
                self.dlg_readsql, self.dlg_readsql.lbl_status_text, _ADMIN_PLUGIN_OUTDATED_MESSAGE
            )
        else:
            self.dlg_readsql.lbl_status.setPixmap(self.status_ok)
            tools_qt.set_widget_text(self.dlg_readsql, self.dlg_readsql.lbl_status_text, '')

    def _should_show_advanced_tab(self) -> bool:
        allowed_levels = lib_vars.user_level.get('showadminadvanced')
        if allowed_levels is None:
            allowed_levels = tools_gw.get_config_parser('user_level', 'showadminadvanced', "user", "init", False)
            lib_vars.user_level['showadminadvanced'] = allowed_levels

        user_level = lib_vars.user_level.get('level')
        if user_level in (None, "None"):
            user_level = tools_gw.get_config_parser('user_level', 'level', "user", "init", False)
            lib_vars.user_level['level'] = user_level

        if not allowed_levels or user_level in (None, "None"):
            return False

        level_ok = str(user_level) in str(allowed_levels)
        return level_ok and self._can_administer_schemas()

    def _update_advanced_tab_visibility(self):
        if not hasattr(self, 'dlg_readsql') or not self.dlg_readsql:
            return
        tab_widget = self.dlg_readsql.tab_main
        visible = self._should_show_advanced_tab()
        for i in range(tab_widget.count()):
            if tab_widget.widget(i).objectName() == 'tab_advanced':
                tab_widget.setTabVisible(i, visible)
                break

    def _get_schema_name(self) -> str:
        """
        Get the schema name from the dialog.

        :return str: The schema name.
        """
        return self._get_selected_schema_name()

    def _load_fct_ftrg(self) -> bool:
        """
        Load fct and ftrg files from utils and software folders.

        :return bool: True if all files were loaded successfully, False otherwise.
        """

        folder = os.path.join(self.folder_common, self.file_pattern_fct)

        status = self._execute_files(folder)
        if not tools_os.set_boolean(status, False) and tools_os.set_boolean(self.dev_commit, False) is False:
            return False

        folder = os.path.join(self.folder_common, self.file_pattern_ftrg)
        status = self._execute_files(folder)
        if not tools_os.set_boolean(status, False) and tools_os.set_boolean(self.dev_commit, False) is False:
            return False

        folder = os.path.join(self.folder_software, self.file_pattern_fct)
        status = self._execute_files(folder)
        if not tools_os.set_boolean(status, False) and tools_os.set_boolean(self.dev_commit, False) is False:
            return False

        folder = os.path.join(self.folder_software, self.file_pattern_ftrg)
        status = self._execute_files(folder)
        if not tools_os.set_boolean(status, False) and tools_os.set_boolean(self.dev_commit, False) is False:
            return False

        return True

    """ Create new connection when change combo connections """

    def _event_change_connection(self):
        """Switch PostgreSQL connection and reload admin metadata asynchronously."""

        self._cached_pg_versions = None
        self._extensions_checked = False
        connection_name = str(tools_qt.get_text(self.dlg_readsql, self.cmb_connection))
        self.username = self._get_user_connection(connection_name)
        tools_db.current_user = None
        self._schema_cache.pop(connection_name, None)
        # Re-check language packages after the new connection finishes loading.
        self._i18n_provision_after_load = True
        self._start_admin_load(connection_name, try_set_connection=True, show_dialog=True)

    def _set_last_connection(self, connection_name):
        """"""

        settings = QSettings()
        settings.beginGroup("PostgreSQL/connections")
        settings.setValue('selected', connection_name)
        settings.endGroup()

    def _get_last_connection(self):
        """"""

        settings = QSettings()
        settings.beginGroup("PostgreSQL/connections")
        connection_name = settings.value('selected')
        settings.endGroup()
        return connection_name

    def _get_user_connection(self, connection_name):
        """"""

        connection_username = None
        settings = QSettings()
        if connection_name:
            settings.beginGroup(f"PostgreSQL/connections/{connection_name}")
            connection_username = settings.value('username')
            settings.endGroup()

        if connection_username is None or connection_username == "":
            connection_username = tools_db.get_current_user()

        return connection_username

    def _open_update_info(self):
        """"""

        # Create dialog
        self.dlg_readsql_show_info = GwAdminProjectInfoUi(self)
        tools_gw.load_settings(self.dlg_readsql_show_info)

        info_updates = self.dlg_readsql_show_info.findChild(QTextEdit, 'info_updates')
        self.message_update = ''

        self._read_info_version()

        info_updates.setText(self.message_update)

        # Disable tab log
        tools_gw.disable_tab_log(self.dlg_readsql_show_info)

        # Set listeners
        self.dlg_readsql_show_info.btn_close.clicked.connect(partial(self._close_dialog_admin, self.dlg_readsql_show_info))
        self.dlg_readsql_show_info.btn_update.clicked.connect(self.update)
        self._refresh_update_dialog_state(running=False)

        # Set shortcut keys
        self.dlg_readsql_show_info.key_escape.connect(partial(tools_gw.close_dialog, self.dlg_readsql_show_info))

        # Open dialog
        tools_gw.open_dialog(self.dlg_readsql_show_info, dlg_name='admin_projectinfo')

    def _read_info_version(self):
        """Load merged common + ws/ud changelogs for pending upgrade versions."""

        kind = self._resolve_update_kind()
        if kind not in ('ws', 'ud'):
            tools_log.log_warning(
                "Changelog preview only supported for ws/ud project types",
                parameter=kind,
            )
            return False

        section_labels = {
            'common': tools_qt.tr('Common'),
            'ws': tools_qt.tr('WS'),
            'ud': tools_qt.tr('UD'),
        }
        try:
            text = format_upgrade_changelog(
                self.sql_dir,
                kind,
                str(self.project_version or '0.0.0'),
                str(self.plugin_version),
                section_labels=section_labels,
            )
        except ValueError as e:
            tools_log.log_warning(str(e))
            return False

        if text:
            self.message_update = text if not self.message_update else self.message_update + '\n\n' + text
        return True

    def _invalidate_admin_schema_cache(self):
        if hasattr(self, 'cmb_connection') and self.cmb_connection:
            connection_name = str(tools_qt.get_text(self.dlg_readsql, self.cmb_connection))
            if connection_name and connection_name != 'null':
                self._schema_cache.pop(connection_name, None)
        self._admin_catalog_cache = None

    def _close_dialog_admin(self, dlg):
        """ Close dialog """
        self._cancel_admin_load_task()
        tools_gw.close_dialog(dlg, delete_dlg=False)
        self.schema = None

    def _update_locale(self):
        """"""
        # TODO: Check this!
        self.locale = tools_qt.get_combo_value(self.dlg_readsql, self.cmb_locale, 0)
        # Locale folder is normally derived from project_type via _set_paths();
        # this is a legacy reset used by _update_locale before any project_type
        # context exists, so we point at the project-type-agnostic common tree.
        self.folder_locale = os.path.join(self.sql_dir, 'schemas', 'main', 'common')

    def _open_language_dialog(self):
        """Open language dialog"""
        dlg = getattr(self, 'dlg_i18n_languages', None)
        if dlg is not None and not isdeleted(dlg) and dlg.isVisible():
            tools_gw.focus_open_dialog(dlg)
            return

        dlg = GwI18NManageLanguagesDialog(self, parent=self.dlg_readsql_create_project)
        dlg.init_dialog()
        self.dlg_i18n_languages = dlg

    def _populate_language_combo_create_project(self):
        """Populate language combo for create project"""
        self.cmb_locale.clear()
        rows_raw = i18n_service.list_locales_for_combo(flag="active")
        if rows_raw is None:
            msg = "Config database file not found"
            tools_qgis.show_warning(self.dlg_readsql_create_project, msg)
            return
        rows = [[locale, name] for locale, name in rows_raw]
        if not rows:
            msg = "No active locales configured"
            tools_qgis.show_warning(self.dlg_readsql_create_project, msg)
            return
        if global_vars.gw_dev_mode is True:
            rows.append(["no_TR", "Harcoded (No translation)"])
        tools_qt.fill_combo_values(self.cmb_locale, rows)
        language = tools_gw.get_config_parser(
            'i18n_generator', 'qm_lang_language', "user", "session", False,
        )
        if language:
            tools_qt.set_combo_value(self.cmb_locale, language, 0, add_new=False)

    def _populate_data_schema_name(self, widget=None):
        """Fill project schema combo from cached catalog or pg_catalog."""

        if getattr(self, '_admin_loading', False):
            return

        if self._admin_catalog_cache and self._admin_catalog_cache.sys_version_schemas:
            schemas = self._admin_catalog_cache.sys_version_schemas
        else:
            schemas = admin_catalog.fetch_sys_version_schemas()

        result_list = admin_catalog.combo_items_all_schemas(schemas)
        connection_name = self._current_connection_name()
        current_schema = self._get_selected_schema_name()
        if not current_schema:
            current_schema = self._get_saved_schema_name(connection_name)

        if not result_list:
            self.dlg_readsql.project_schema_name.clear()
            self._set_buttons_enabled()
            return

        tools_qt.fill_combo_values(self.dlg_readsql.project_schema_name, result_list)
        schema_names = {str(row[0]) for row in result_list}
        if current_schema and str(current_schema) in schema_names:
            tools_qt.set_combo_value(
                self.dlg_readsql.project_schema_name, current_schema, 0, add_new=False
            )
        self._sync_project_type_from_schema()
        self._set_buttons_enabled()

    def _manage_srid(self):
        """ Manage SRID configuration """

        self.filter_srid = self.dlg_readsql_create_project.findChild(QLineEdit, 'srid_id')
        tools_qt.set_widget_text(self.dlg_readsql_create_project, self.filter_srid, '25831')
        self.tbl_srid = self.dlg_readsql_create_project.findChild(QTableView, 'tbl_srid')
        self.tbl_srid.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.model_srid = QSqlQueryModel()
        self.tbl_srid.setModel(self.model_srid)
        self.tbl_srid.clicked.connect(partial(self._set_selected_srid))

    def _set_selected_srid(self):

        selected_list = self.tbl_srid.selectionModel().selectedRows()
        selected_row = selected_list[0].row()
        srid = self.tbl_srid.model().record(selected_row).value("SRID")
        tools_qt.set_widget_text(self.dlg_readsql_create_project, self.filter_srid, srid)

    def _filter_srid_changed(self):
        """"""

        filter_value = tools_qt.get_text(self.dlg_readsql_create_project, self.filter_srid)
        if filter_value == 'null':
            filter_value = ''
        sql = ("SELECT substr(srtext, 1, 6) as " + '"Type"' + ", srid as " + '"SRID"' + ", "
               "substr(split_part(srtext, ',', 1), 9) as " + '"Description"' + " "
               "FROM public.spatial_ref_sys "
               "WHERE CAST(srid AS TEXT) LIKE '" + str(filter_value))
        sql += "%'  AND  srtext ILIKE 'PROJCS%' ORDER BY substr(srtext, 1, 6), srid"
        self.last_srids = tools_db.get_rows(sql, commit=self.dev_commit)

        # Populate Table
        self.model_srid = QSqlQueryModel()
        self.model_srid.setQuery(sql, db=lib_vars.qgis_db_credentials)
        self._set_srid_headers(self.model_srid)
        self.tbl_srid.setModel(self.model_srid)
        self.tbl_srid.show()

    def _set_srid_headers(self, model):
        """ Translate the SRID table headers without renaming the query fields """

        msg = "Type"
        model.setHeaderData(0, Qt.Orientation.Horizontal, tools_qt.tr(msg))
        msg = "SRID"
        model.setHeaderData(1, Qt.Orientation.Horizontal, tools_qt.tr(msg))
        msg = "Description"
        model.setHeaderData(2, Qt.Orientation.Horizontal, tools_qt.tr(msg))

    def _set_info_project(self):
        """"""

        if getattr(self, '_admin_loading', False):
            return

        schema_name = self._get_selected_schema_name() or 'null'

        # Always refresh PG/PostGIS/pgRouting display for the current connection,
        # even when form_enabled is False (e.g. incompatible PostgreSQL version).
        if not hasattr(self, '_cached_pg_versions') or self._cached_pg_versions is None:
            if lib_vars.session_vars.get('logged_status'):
                self._cached_pg_versions = {
                    'pg': tools_db.get_pg_version(),
                    'postgis': tools_db.get_postgis_version(),
                    'pgrouting': tools_db.get_pgrouting_version(),
                }
                for ext in ('postgis_raster', 'tablefunc', 'unaccent', 'fuzzystrmatch', 'intarray'):
                    tools_db.check_pg_extension(ext)

        if self._cached_pg_versions is not None:
            self.postgresql_version = self._cached_pg_versions['pg']
            self.postgis_version = self._cached_pg_versions['postgis']
            self.pgrouting_version = self._cached_pg_versions['pgrouting']

        versions_msg = (
            f'{tools_qt.tr("PostgreSQL version")}: {self.postgresql_version}\n'
            f'{tools_qt.tr("PostGis version")}: {self.postgis_version}\n'
            f'{tools_qt.tr("PgRouting version")}: {self.pgrouting_version}\n \n'
        )

        if self.is_service and self.form_enabled is False:
            # Still show connection versions when the form is disabled (q8)
            if getattr(self, 'software_version_info', None) is not None:
                self.software_version_info.setText(versions_msg)
            title = 'Giswater ({0})'
            title_params = (self.plugin_version,)
            self.dlg_readsql.setWindowTitle(tools_qt.tr(title, list_params=title_params))
            return

        if schema_name == 'null':
            tools_qt.enable_tab_by_tab_name(self.dlg_readsql.tab_main, "others", False)
            self.software_version_info.setText(versions_msg)
            self.lbl_schema_name.setText('')
        else:
            first_dict_info = tools_gw.get_project_info(schema_name, order_direction="ASC")
            last_dict_info = tools_gw.get_project_info(schema_name)

            if not first_dict_info or not last_dict_info:
                # Schema gone / not a valid Giswater schema — treat like empty selection
                tools_qt.enable_tab_by_tab_name(self.dlg_readsql.tab_main, "others", False)
                self.software_version_info.setText(versions_msg)
                self.lbl_schema_name.setText('')
            else:
                self.project_type = last_dict_info['project_type']
                if self.project_type:
                    self._set_project_type_paths(str(self.project_type).lower())
                self.project_epsg = last_dict_info['project_epsg']
                self.project_version = last_dict_info['project_version']
                self.project_language = last_dict_info['project_language']
                project_date_create = first_dict_info['project_date'].strftime('%d-%m-%Y %H:%M:%S')
                project_date_update = last_dict_info['project_date'].strftime('%d-%m-%Y %H:%M:%S')
                if project_date_create == project_date_update:
                    project_date_update = ''
                creation_profile = first_dict_info.get('creation_profile') or last_dict_info.get('creation_profile')
                creation_profile_labels = {
                    'empty': tools_qt.tr("Empty data"),
                    'inventory': tools_qt.tr("Inventory Example"),
                    'sample': tools_qt.tr("Full Example"),
                }
                project_type_label = str(self.project_type or '').upper()
                profile_label = creation_profile_labels.get(
                    creation_profile, creation_profile or tools_qt.tr("Unknown")
                )
                msg = (
                    f'''{versions_msg}'''
                    f'''{tools_qt.tr("Schema name")}: {schema_name}\n'''
                    f'''{tools_qt.tr("Project type")}: {project_type_label}\n'''
                    f'''{tools_qt.tr("Profile")}: {profile_label}\n'''
                    f'''{tools_qt.tr("Version")}: {self.project_version}\n'''
                    f'''EPSG: {self.project_epsg}\n'''
                    f'''{tools_qt.tr("Language")}: {self.project_language}\n'''
                )
                if self._can_administer_schemas():
                    linked = admin_catalog.linked_satellites_for_parent(schema_name)
                    linked_label = linked if linked else tools_qt.tr("None")
                    msg += f'''{tools_qt.tr("Satellite schemas")}: {linked_label}\n'''
                msg += (
                    f'''{tools_qt.tr("Date of creation")}: {project_date_create}\n'''
                    f'''{tools_qt.tr("Date of last update")}: {project_date_update}\n'''
                )

                self.software_version_info.setText(msg)
                self.lbl_schema_name.setText(str(schema_name))
                self.schema_name = schema_name

        # Update windowTitle
        title = 'Giswater ({0})'
        title_params = (self.plugin_version,)
        self.dlg_readsql.setWindowTitle(tools_qt.tr(title, list_params=title_params))

    def _set_schema_crud_visible(self, visible: bool):
        for name in _SCHEMA_CRUD_BUTTONS:
            widget = getattr(self.dlg_readsql, name, None)
            if widget is not None:
                widget.setVisible(visible)

    def _process_folder(self, folderpath: str, filepattern: str = '') -> bool:
        """
        Process a folder and return True if the folder exists, False otherwise.

        :param folderpath: The path to the folder to process.
        :param filepattern: The pattern to use to filter the files.

        :return bool: True if the folder exists, False otherwise.
        """

        try:
            os.listdir(os.path.join(folderpath, filepattern))
            return True
        except Exception:
            return False

    def _reload_fct_ftrg(self) -> None:
        """
        Reload fct and ftrg files from utils and software folders.

        :return None:
        """

        self._load_fct_ftrg()
        status = (self.error_count == 0)
        if status:
            tools_db.dao.commit()
        else:
            msg = "Reload failed"
            title = "Error"
            tools_qt.show_info_box(msg, title=title)
            tools_db.dao.rollback()
            if hasattr(self, 'task_rename_schema'):
                self.task_rename_schema.cancel()

        # Reset count error variable to 0
        self.error_count = 0

    def _set_signals_create_project(self):
        """"""
        self.dlg_readsql_create_project.btn_cancel_task.clicked.connect(partial(self.cancel_task, 'task_create_schema'))
        self.dlg_readsql_create_project.btn_accept.clicked.connect(partial(self.create_project_data_schema))
        self.dlg_readsql_create_project.btn_close.clicked.connect(
            partial(self._close_dialog_admin, self.dlg_readsql_create_project))
        self.dlg_readsql_create_project.dlg_closed.connect(partial(self._save_create_project_user_values))
        self.cmb_create_project_type.currentIndexChanged.connect(
            partial(self._change_project_type, self.cmb_create_project_type))
        self.cmb_create_project_type.currentIndexChanged.connect(
            lambda _index=None: self._apply_dev_project_name())
        self.cmb_locale.currentIndexChanged.connect(partial(self._update_locale))
        self.dlg_readsql_create_project.btn_language.clicked.connect(partial(self._open_language_dialog))
        self.filter_srid.textChanged.connect(partial(self._filter_srid_changed))
        for radio in (self.rdb_empty, self.rdb_sample_inv, self.rdb_sample_full):
            if radio is not None:
                radio.toggled.connect(self._on_create_project_profile_toggled)

    def _on_create_project_profile_toggled(self, checked):
        """Regenerate developer project_name when data-source radio changes."""
        if checked:
            self._apply_dev_project_name()

    def _open_manage_schemas(self):
        from .manage_schemas_dlg import GwManageSchemasDialog

        dlg = getattr(self, '_manage_schemas_dlg', None)
        if dlg is not None and not isdeleted(dlg) and dlg.isVisible():
            tools_gw.focus_open_dialog(dlg)
            return

        dlg = GwManageSchemasDialog(self, parent=self.dlg_readsql)
        tools_gw.load_settings(dlg)
        dlg.apply_scroll_geometry()
        self._manage_schemas_refresh = dlg._refresh_inventory
        self._manage_schemas_update_system_info = dlg._update_system_info
        self._manage_schemas_sync_connection = dlg._sync_connection_combo
        self._manage_schemas_dlg = dlg
        lib_vars.session_vars["message_parent"] = dlg
        dlg.finished.connect(self._on_manage_schemas_closed)
        tools_gw.open_dialog(dlg, dlg_name='admin_manage_schemas')

    def _on_manage_schemas_closed(self, *_args):
        if lib_vars.session_vars.get("message_parent") is getattr(self, '_manage_schemas_dlg', None):
            lib_vars.session_vars["message_parent"] = None
        self._manage_schemas_refresh = None
        self._manage_schemas_update_system_info = None
        self._manage_schemas_sync_connection = None
        self._manage_schemas_dlg = None

    def _open_create_project(self):
        """"""

        # Create dialog and signals
        if self.dlg_readsql_create_project is None:
            self.init_dialog_create_project()

        self._load_create_project_user_values()
        self._filter_srid_changed()

        # Get project_type from selected schema
        project_type = self._get_selected_project_type() or 'ws'
        tools_qt.set_widget_text(self.dlg_readsql_create_project, self.cmb_create_project_type, project_type)
        self._set_project_type_paths(project_type)
        self.connection_name = str(tools_qt.get_text(self.dlg_readsql, self.cmb_connection))
        # Refresh after restore: session name is stale and combo may not change (no signal)
        self._apply_dev_project_name()

        self._update_time_elapsed("", self.dlg_readsql_create_project)

        # Open dialog
        title = "Create Project - {0}"
        title_params = (self.connection_name,)
        self.dlg_readsql_create_project.setWindowTitle(tools_qt.tr(title, list_params=title_params))
        tools_gw.open_dialog(self.dlg_readsql_create_project, dlg_name='admin_dbproject')

    def _open_create_cm_project(self):
        """Legacy entry point — CM actions live in Manage Schemas."""
        self._open_manage_schemas()

    def on_btn_create_base_clicked(self):
        self._create_cm_schema()

    def on_btn_create_parent_clicked(self):
        self._integrate_cm()

    def on_btn_create_example_clicked(self):
        self._load_cm_sample()

    def on_btn_pschema_qgis_file_clicked(self):
        self._set_cm_pschema_qgis()

    def _open_rename(self, schema_name=None, schema_version=None):
        """"""

        schema = schema_name or self._get_selected_schema_name()
        if not schema or schema == "null":
            msg = "Please, select a project to rename"
            tools_qt.show_info_box(msg, "Info")
            return

        project_version = schema_version or self.project_version

        # Open rename if schema is updated
        if _admin_version_tuple(self.plugin_version) != _admin_version_tuple(project_version):
            msg = "The schema version has to be updated to make rename"
            tools_qt.show_info_box(msg, "Info")
            return

        # Create dialog
        self.dlg_readsql_rename = GwAdminRenameProjUi(self)
        tools_gw.load_settings(self.dlg_readsql_rename)

        # Set listeners
        self.dlg_readsql_rename.btn_accept.clicked.connect(partial(self._rename_project_data_schema, schema, None))
        self.dlg_readsql_rename.btn_cancel.clicked.connect(partial(self._close_dialog_admin, self.dlg_readsql_rename))

        # Set shortcut keys
        self.dlg_readsql_rename.key_escape.connect(partial(tools_gw.close_dialog, self.dlg_readsql_rename))

        # Open dialog
        title = 'Rename project - {0}'
        title_params = (schema,)
        self.dlg_readsql_rename.setWindowTitle(tools_qt.tr(title, list_params=title_params))
        self.dlg_readsql_rename.schema_rename_copy.setText(schema)
        tools_gw.open_dialog(self.dlg_readsql_rename, dlg_name='admin_renameproj')

    def _execute_files(self, filedir, no_ct=False, utils_schema_name=None, set_progress_bar=False, aux_schema_name=None):
        """"""

        if not os.path.exists(filedir):
            msg = "Folder not found"
            tools_log.log_info(msg, parameter=filedir)
            return True
        # Skipping metadata folders for Mac OS
        if '.DS_Store' in filedir:
            return True
        msg = "Processing folder"
        tools_log.log_info(msg, parameter=filedir)
        filelist = sorted(os.listdir(filedir))
        status = True
        if utils_schema_name:
            schema_name = utils_schema_name
        elif self.schema is None:
            schema_name = self._get_selected_schema_name()
            schema_name = schema_name.replace('"', '')
        else:
            schema_name = self.schema.replace('"', '')
        if self.project_epsg:
            self.project_epsg = str(self.project_epsg).replace('"', '')
        else:
            msg = "There is no project selected or it is not valid. Please check the first tab..."
            tools_qgis.show_warning(msg)

        # Manage files
        for file in filelist:
            if ".sql" in file:
                if (no_ct is True and "tablect.sql" not in file) or no_ct is False:
                    tools_log.log_info(os.path.join(filedir, file))
                    self.current_sql_file += 1
                    status = self._read_execute_file(filedir, file, schema_name, self.project_epsg, set_progress_bar, aux_schema_name)
                    if not tools_os.set_boolean(status, False) and not tools_os.set_boolean(self.dev_commit, False):
                        return False

        return status

    def _read_execute_file(self, filedir, file, schema_name, project_epsg, set_progress_bar=False, aux_schema_name=None):
        """"""

        status = False
        f = None
        try:

            # Manage progress bar
            if set_progress_bar:
                if hasattr(self, 'task_create_schema') and not isdeleted(self.task_create_schema):
                    self.progress_value = int(float(self.current_sql_file / self.total_sql_files) * 100)
                    self.progress_value = int(self.progress_value * self.progress_ratio)
                    self.task_create_schema.set_progress(self.progress_value)

            if hasattr(self, 'task_create_schema') and not isdeleted(self.task_create_schema) and self.task_create_schema.isCanceled():
                return False

            filepath = os.path.join(filedir, file)
            f = open(filepath, 'r', encoding="utf8")
            if f:
                f_to_read = str(f.read())
                if aux_schema_name:
                    f_to_read = f_to_read.replace("AUX_SCHEMA_NAME", aux_schema_name)
                f_to_read = f_to_read.replace("SCHEMA_NAME", schema_name).replace("SRID_VALUE", project_epsg)

                status = tools_db.execute_sql(str(f_to_read), filepath=filepath, commit=self.dev_commit, is_thread=True)
                if tools_os.set_boolean(status, False) is False:
                    self.error_count = self.error_count + 1
                    msg = "{0} error {1}"
                    msg_params = ("_read_execute_file", filepath,)
                    tools_log.log_info(msg, msg_params=msg_params)
                    msg = "Message"
                    tools_log.log_info(msg, parameter=lib_vars.session_vars['last_error'])
                    self.message_infolog = f"_read_execute_file error {filepath}\nMessage: {lib_vars.session_vars['last_error']}"
                    if tools_os.set_boolean(self.dev_commit, False) is False:
                        tools_db.dao.rollback()

                    if hasattr(self, 'task_create_schema') and not isdeleted(self.task_create_schema):
                        self.task_create_schema.db_exception = (lib_vars.session_vars['last_error'], str(f_to_read), filepath)
                        self.task_create_schema.cancel()

                    return False

        except Exception as e:
            self.error_count = self.error_count + 1
            msg = "{0} exception: {1}"
            msg_params = ("_read_execute_file", file,)
            tools_log.log_info(msg, msg_params=msg_params)
            tools_log.log_info(str(e))
            self.message_infolog = f"_read_execute_file exception: {file}\n {str(e)}"
            if tools_os.set_boolean(self.dev_commit, False) is False:
                tools_db.dao.rollback()
            if hasattr(self, 'task_create_schema') and not isdeleted(self.task_create_schema):
                self.task_create_schema.cancel()
            status = False

        finally:
            if f:
                f.close()
            return status

    def _get_current_db_name(self):
        """
        Gets the database name from the currently selected connection in the admin dialog.
        """
        if not hasattr(self, 'dlg_readsql') or isdeleted(self.dlg_readsql):
            return None

        connection_name = tools_qt.get_text(self.dlg_readsql, self.dlg_readsql.cmb_connection)
        if not connection_name or connection_name == 'null':
            return None

        settings = QSettings()
        settings.beginGroup(f"PostgreSQL/connections/{connection_name}")

        # Check if using pg_service
        service_name = settings.value("service", "")
        if service_name:
            # Get database name from pg_service.conf
            credentials_service = tools_os.manage_pg_service(service_name)
            db_name = credentials_service.get('dbname', None) if credentials_service else None
        else:
            # Get database name from connection settings
            db_name = settings.value("database", "")

        settings.endGroup()
        return db_name if db_name else None

    def _copy_schema(self):
        """"""

        # Create dialog
        self.dlg_readsql_copy = GwAdminRenameProjUi(self)
        tools_gw.load_settings(self.dlg_readsql_copy)

        schema = self._get_selected_schema_name()

        # Set listeners
        self.dlg_readsql_copy.btn_accept.clicked.connect(partial(self._copy_project_start, schema))
        self.dlg_readsql_copy.btn_cancel.clicked.connect(partial(self._close_dialog_admin, self.dlg_readsql_copy))

        # Set shortcut keys
        self.dlg_readsql_copy.key_escape.connect(partial(tools_gw.close_dialog, self.dlg_readsql_copy))

        # Open dialog
        title = 'Copy project - {0}'
        title_params = (schema,)
        self.dlg_readsql_copy.setWindowTitle(tools_qt.tr(title, list_params=title_params))
        tools_gw.open_dialog(self.dlg_readsql_copy, dlg_name='admin_renameproj')

    def _copy_project_start(self, schema):
        """"""

        new_schema_name = tools_qt.get_text(self.dlg_readsql_copy, self.dlg_readsql_copy.schema_rename_copy)
        if admin_catalog.schema_exists(str(new_schema_name)):
            msg = "This project name alredy exist."
            tools_qt.show_info_box(msg, "Info")
            return

        # Create timer
        self.t0 = time()
        self.timer = QTimer()
        self.timer.timeout.connect(partial(self._calculate_elapsed_time, self.dlg_readsql_copy))
        self.timer.start(1000)

        # Set background task 'GwCopySchemaTask'
        description = "Copy schema"
        params = {'schema': schema}
        self.task_copy_schema = GwCopySchemaTask(self, description, params, timer=self.timer)
        QgsApplication.taskManager().addTask(self.task_copy_schema)
        QgsApplication.taskManager().triggerTask(self.task_copy_schema)

    def _delete_schema(self, schema_name=None):
        """"""

        project_name = schema_name or self._get_selected_schema_name()
        if project_name is None:
            msg = "Please, select a project to delete"
            tools_qt.show_info_box(msg, "Info")
            return

        sql = f"SELECT value FROM {project_name}.config_param_system WHERE parameter='admin_isproduction'"
        row = tools_db.get_row(sql)
        if row and tools_os.set_boolean(row[0], default=False):
            msg = "The schema '{0}' is being used in production! It can't be deleted."
            msg_params = (project_name,)
            tools_qt.show_info_box(msg, "Warning", msg_params=msg_params)
            return

        msg = "Are you sure you want delete schema '{0}'?"
        msg_params = (project_name,)
        title = "Info"
        result = tools_qt.show_question(msg, title, force_action=True, msg_params=msg_params)
        if result:
            fx = engine_drop_schema(QtDbAdapter(), project_name, cascade=True, commit=True)
            if fx.ok:
                msg = "Process finished successfully: Delete schema"
                tools_qt.show_info_box(msg, "Info")
                self._clear_saved_schema_name(project_name)
                self._refresh_admin_catalog_cache()
                self.dlg_readsql.project_schema_name.blockSignals(True)
                self._populate_data_schema_name()
                self.dlg_readsql.project_schema_name.blockSignals(False)
                self._manage_utils()
                self._set_info_project()
                refresh = getattr(self, '_manage_schemas_refresh', None)
                if refresh:
                    refresh()
            else:
                msg = "Delete schema failed: {0}"
                msg_params = (fx.error,)
                title = "Error"
                tools_qt.show_info_box(msg, title, msg_params=msg_params)

    def _delete_other_schema(self, schema):
        """ Delete other schema """

        msg = "Are you sure you want delete schema '{0}'?"
        msg_params = (schema,)
        result = tools_qt.show_question(msg, "Info", force_action=True, msg_params=msg_params)
        if result:
            if schema == "multilang":
                from .i18n.multilang_seed_sql import (
                    multilang_user_param_provision_sql,
                    multilang_view_functions_ddl,
                    multilang_views_provision_sql,
                    run_multilang_function_sql,
                )

                if not tools_db.execute_sql(
                    multilang_view_functions_ddl(), commit=True, show_exception=True
                ):
                    msg = "Multilang views rollback failed."
                    err = lib_vars.session_vars.get("last_error") or msg
                    tools_qt.show_info_box(err, "Error")
                    return

                # Recreate plain views before DROP so nothing still joins multilang.*
                _, views_ok = run_multilang_function_sql(
                    multilang_views_provision_sql(enable=False),
                    show_exception=True,
                )
                if not views_ok:
                    msg = "Multilang views rollback failed."
                    err = lib_vars.session_vars.get("last_error_msg") or (
                        lib_vars.session_vars.get("last_error") or msg
                    )
                    title = "Error"
                    tools_qt.show_info_box(err, title)
                    return

                _, params_ok = run_multilang_function_sql(
                    multilang_user_param_provision_sql(enable=False),
                    show_exception=True,
                )
                if not params_ok:
                    msg = "Multilang user parameter rollback failed."
                    err = lib_vars.session_vars.get("last_error_msg") or (
                        lib_vars.session_vars.get("last_error") or msg
                    )
                    title = "Error"
                    tools_qt.show_info_box(err, title)
                    return
            fx = engine_drop_schema(QtDbAdapter(), schema, cascade=True, commit=True)
            if fx.ok:
                msg = "Process finished successfully: Delete schema"
                tools_qt.show_info_box(msg, "Info")
                self._refresh_admin_catalog_cache()
                self._set_buttons_enabled()
                refresh = getattr(self, "_manage_schemas_refresh", None)
                if refresh:
                    refresh()
            else:
                title = "Error"
                msg = "Delete schema failed: {0}"
                msg_params = (fx.error,)
                tools_qt.show_info_box(msg, title, msg_params=msg_params)

    def _multilang_stored_seeded_schemas(self) -> set[str]:
        """Project types recorded at last multilang seed (prefer addparam)."""
        from .i18n.multilang_seed_sql import (
            fetch_seeded_project_types_from_multilang,
            parse_stored_seeded_project_types,
        )

        if not admin_catalog.schema_exists("multilang"):
            return set()

        row = tools_db.get_row(
            "SELECT addparam FROM multilang.sys_version ORDER BY id DESC LIMIT 1"
        )
        if row and row[0]:
            try:
                addparam = json.loads(row[0]) if isinstance(row[0], str) else row[0]
            except (TypeError, ValueError):
                addparam = None
            if isinstance(addparam, dict) and (
                "seeded_project_types" in addparam or "seeded_schemas" in addparam
            ):
                return parse_stored_seeded_project_types(addparam)

        # Legacy multilang schemas without seeded_project_types in addparam.
        return fetch_seeded_project_types_from_multilang(
            fetcher=admin_catalog._tools_db_fetch,
        )

    def _multilang_current_seed_targets(self, inventory_rows=None) -> set[str]:
        """Project types that should be present in multilang seed (ws/ud/am/cm)."""
        from .i18n.multilang_seed_sql import translatable_project_types_with_baseline

        return set(translatable_project_types_with_baseline(self.sql_dir))

    def _multilang_schemas_out_of_sync(self, inventory_rows=None) -> bool:
        """True when project types differ from the last multilang seed."""
        from .i18n.multilang_seed_sql import seeded_project_types_out_of_sync

        if not admin_catalog.schema_exists("multilang"):
            return False
        current = self._multilang_current_seed_targets(inventory_rows)
        stored = self._multilang_stored_seeded_schemas()
        return seeded_project_types_out_of_sync(current, stored)

    def _multilang_baseline_changed(self) -> bool:
        """True when bundled en_US baseline SQL differs from the last seed."""
        from .i18n.multilang_seed_sql import baseline_needs_reseed

        if not admin_catalog.schema_exists("multilang"):
            return False
        row = tools_db.get_row(
            "SELECT addparam FROM multilang.sys_version ORDER BY id DESC LIMIT 1"
        )
        stored = None
        if row and row[0]:
            try:
                addparam = json.loads(row[0]) if isinstance(row[0], str) else row[0]
                if isinstance(addparam, dict):
                    stored = addparam.get("seed_baseline_fingerprint")
            except (TypeError, ValueError):
                pass
        return baseline_needs_reseed(self.sql_dir, stored)

    def _build_replace_dlg(self, replace_json):

        # Build the dialog
        self.dlg_replace = GwReplaceInFileUi(self)
        self.dlg_replace.setWindowFlags(Qt.WindowType.WindowStaysOnTopHint)
        tools_gw.load_settings(self.dlg_replace)

        # Add a widget for each word to replace
        self._add_replace_widgets(replace_json)

        # Connect signals
        self.dlg_replace.btn_accept.clicked.connect(partial(self._dlg_replace_accept))
        self.dlg_replace.btn_cancel.clicked.connect(partial(self.dlg_replace.reject))
        self.dlg_replace.finished.connect(partial(tools_gw.save_settings, self.dlg_replace))

        resp = self.dlg_replace.exec()  # We do exec_() because we want the execution to stop until the dlg is closed
        if resp == 0:
            return False
        return True

    def _add_replace_widgets(self, replace_json):

        idx = 0
        for item in replace_json:
            for key in item:
                # Add section label
                section = key
                section_lbl = QLabel()
                section_lbl.setText(f"<b>{section}</b>")
                field = {"layoutname": 'lyt_replace', "layoutorder": idx}
                tools_gw.add_widget(self.dlg_replace, field, section_lbl, None)
                idx += 1
                for i in item[key]:
                    # Add widget label
                    lbl = QLabel()
                    lbl.setText(f"{i}")
                    # Add widget Line Edit
                    widget = QLineEdit()
                    widget.setObjectName(f"{i}")
                    field = {"layoutname": 'lyt_replace', "layoutorder": idx}

                    tools_gw.add_widget(self.dlg_replace, field, lbl, widget)
                    idx += 1
        # Add final vertical spacer
        spacer = tools_qt.add_verticalspacer()
        lyt_replace = self.dlg_replace.findChild(QGridLayout, 'lyt_replace')
        lyt_replace.addItem(spacer)

    def _dlg_replace_accept(self):

        dict_to_replace_unordered = {}
        for widget in self.dlg_replace.findChildren(QLineEdit):
            dict_to_replace_unordered[f'{widget.objectName()}'] = f'{widget.text()}'

        dict_to_replace = {}
        for k in sorted(dict_to_replace_unordered, key=len, reverse=True):
            dict_to_replace[k] = dict_to_replace_unordered[k]

        all_valid = True
        news = []
        for key in dict_to_replace:
            valid = True
            old = key
            new = dict_to_replace[key]
            if len(new) <= 0:
                # if the string is empty
                tools_qt.set_stylesheet(self.dlg_replace.findChild(QLineEdit, f'{old}'))
                self.dlg_replace.findChild(QLineEdit, f'{old}').setToolTip('Can\'t be empty')
                valid, all_valid = False, False
            elif len(new) > 16:
                # if the string is too long
                tools_qt.set_stylesheet(self.dlg_replace.findChild(QLineEdit, f'{old}'))
                self.dlg_replace.findChild(QLineEdit, f'{old}').setToolTip('Must have less than 16 characters')
                valid, all_valid = False, False
            elif new in news:
                # if the string is duplicated with other new strings
                tools_qt.set_stylesheet(self.dlg_replace.findChild(QLineEdit, f'{old}'))
                self.dlg_replace.findChild(QLineEdit, f'{old}').setToolTip('All new names should be unique')
                valid, all_valid = False, False
            else:
                # Search if the object already exists
                sql = f"SELECT count(csv1) FROM temp_csv WHERE csv1 ILIKE '{new}'"
                row = tools_db.get_row(sql, log_info=False, commit=False)
                if row and row[0] is not None:
                    try:
                        matches = int(row[0])
                        if matches > 0:
                            tools_qt.set_stylesheet(self.dlg_replace.findChild(QLineEdit, f'{old}'))
                            self.dlg_replace.findChild(QLineEdit, f'{old}').setToolTip('Another object has this name')
                            valid, all_valid = False, False
                    except Exception as e:
                        msg = "{0} --> {1}"
                        msg_params = (type(e).__name__, str(e,),)
                        tools_log.log_info(msg, msg_params=msg_params)
            if valid:
                news.append(new)
                tools_qt.set_stylesheet(self.dlg_replace.findChild(QLineEdit, f'{old}'), style="")
                self.dlg_replace.findChild(QLineEdit, f'{old}').setToolTip('')

        # If none of the new words are in the file
        if all_valid:
            msg = "This will modify your inp file, so a backup will be created.\nDo you want to proceed?"
            if not tools_qt.show_question(msg):
                return

            # Replace the words
            try:
                # Read the contents of the file
                with open(self.file_inp, 'r', encoding='utf-8') as file:
                    contents = file.read()
                # Save a backup of the file
                with open(f"{self.file_inp}.old", 'w', encoding='utf-8') as file:
                    file.write(contents)
                # Replace the words
                for key in dict_to_replace:
                    old = key
                    new = dict_to_replace[key]
                    contents = tools_os.ireplace(old, new, contents)
                # Write the file with new contents
                with open(f"{self.file_inp}", 'w', encoding='utf-8') as file:
                    file.write(contents)
            except Exception as e:
                msg = "Exception when replacing inp strings"
                tools_log.log_error(msg, parameter=str(e))
            del contents

            # Close the dlg
            self.dlg_replace.accept()

    def _create_qgis_template(self):
        """"""

        msg = ("Warning: Are you sure to continue?. This button will update your plugin qgis templates file replacing "
               "all strings defined on the config/dev.config file. Be sure your config file is OK before continue")
        result = tools_qt.show_question(msg)
        if result:
            # Get dev config file
            setting_file = os.path.join(self.plugin_dir, 'config', 'dev.config')
            if not os.path.exists(setting_file):
                msg = "File not found"
                tools_qgis.show_warning(msg, parameter=setting_file)
                return

            # Set plugin settings
            self.dev_settings = QSettings(setting_file, QSettings.Format.IniFormat)
            if hasattr(self.dev_settings, "setIniCodec"):
                self.dev_settings.setIniCodec(sys.getfilesystemencoding())

            # Get values
            self.folder_path = tools_gw.get_config_parser('system', 'folder_path', "project", "dev", False,
                                                          force_reload=True)

            self.text_replace_labels = tools_gw.get_config_parser('qgis_project_text_replace', 'labels', "project",
                                                                  "dev", False, force_reload=True)
            self.text_replace_labels = self.text_replace_labels.split(',')
            self.xml_set_labels = tools_gw.get_config_parser('qgis_project_xml_set', 'labels', "project", "dev", False,
                                                             force_reload=True)
            self.xml_set_labels = self.xml_set_labels.split(',')

            if not os.path.exists(self.folder_path):
                msg = "Folder not found"
                tools_qgis.show_warning(msg, parameter=self.folder_path)
                return

            # Set wait cursor
            self.task1 = GwTask('Manage schema')
            QgsApplication.taskManager().addTask(self.task1)
            self.task1.setProgress(50)

            # Start read files
            qgis_files = sorted(os.listdir(self.folder_path))
            for file in qgis_files:
                msg = "Reading file"
                tools_log.log_info(msg, parameter=file)
                # Open file for read
                f = open(self.folder_path + os.sep + file, 'r')
                if f:
                    f_to_read = str(f.read())

                    # Replace into template text
                    for text_replace in self.text_replace_labels:
                        text_replace = text_replace.replace(" ", "")
                        self.text_replace = tools_gw.get_config_parser('qgis_project_text_replace', text_replace,
                                                                       "project", "dev", False, force_reload=True)
                        self.text_replace = self.text_replace.split(',')
                        msg = "Replacing template text"
                        tools_log.log_info(msg, parameter=self.text_replace[1])
                        f_to_read = re.sub(str(self.text_replace[0]),
                                           str(self.text_replace[1]), f_to_read)

                    for text_replace in self.xml_set_labels:
                        text_replace = text_replace.replace(" ", "")
                        self.text_replace = tools_gw.get_config_parser('qgis_project_xml_set', text_replace, "project",
                                                                       "dev", False, force_reload=True)
                        self.text_replace = self.text_replace.split(',')
                        msg = "Replacing template text"
                        tools_log.log_info(msg, parameter=self.text_replace[1])
                        f_to_read = re.sub(str(self.text_replace[0]),
                                           str(self.text_replace[1]), f_to_read)

                    # Close file
                    f.close()

                    # Open file for write
                    f = open(self.folder_path + os.sep + file, 'w')
                    f.write(f_to_read)

                    # Close file
                    f.close()

            # Set arrow cursor
            self.task1.setProgress(100)

            # Finish proces
            msg = "The QGIS Projects templates was correctly created."
            tools_qt.show_info_box(msg, "Info")

    def _update_manage_ui(self):
        """"""

        schema_name = self._get_selected_schema_name()
        if schema_name in (None, 'null', ''):
            tools_qt.enable_tab_by_tab_name(self.dlg_readsql.tab_main, "others", False)
            return
        else:
            tools_qt.enable_tab_by_tab_name(self.dlg_readsql.tab_main, "others", True)

        # Control if schema_version is updated to 3.2
        if _admin_version_tuple(self.project_version) < _admin_version_tuple(self.plugin_version):
            tools_qt.get_widget(self.dlg_readsql, self.dlg_readsql.grb_manage_addfields).setEnabled(False)
            self.dlg_readsql.cmb_formname_fields.clear()
            return

        else:
            tools_qt.get_widget(self.dlg_readsql, self.dlg_readsql.grb_manage_addfields).setEnabled(True)

            if not tools_db.check_table('cat_feature', schema_name):
                msg = "Table not found: '{0}'"
                msg_params = ("cat_feature",)
                tools_log.log_warning(msg, msg_params=msg_params)
                return

            sql = (f"SELECT cat_feature.id, cat_feature.id "
                   f"FROM {schema_name}.cat_feature WHERE id <> 'LINK' "
                   f"AND active IS TRUE ORDER BY id")
            rows = tools_db.get_rows(sql, commit=self.dev_commit)

            tools_qt.fill_combo_values(self.dlg_readsql.cmb_formname_fields, rows)

    def _open_manage_field(self, action):
        """"""

        # Create the dialog and signals
        self.dlg_manage_fields = GwAdminFieldsUi(self)
        tools_gw.load_settings(self.dlg_manage_fields)
        self.model_update_table = None

        # Remove unused tabs
        for x in range(self.dlg_manage_fields.tab_add_fields.count() - 1, -1, -1):
            if str(self.dlg_manage_fields.tab_add_fields.widget(x).objectName()) not in (f'tab_{action}', 'tab_infolog'):
                tools_qt.remove_tab(
                    self.dlg_manage_fields.tab_add_fields, self.dlg_manage_fields.tab_add_fields.widget(x).objectName())

        form_name_fields = tools_qt.get_text(self.dlg_readsql, self.dlg_readsql.cmb_formname_fields)
        is_multi_addfield = tools_qt.is_checked(self.dlg_readsql, self.dlg_readsql.chk_add_fields_multi)

        title = ""
        title_params = None
        if action == 'create':
            if is_multi_addfield:
                title = 'Create multi field'
            else:
                title = 'Create field on "{0}"'
                title_params = (str(form_name_fields),)
            self._manage_create_field(form_name_fields, is_multi_addfield)
        elif action == 'update':
            if is_multi_addfield:
                title = 'Update multi field'
            else:
                title = 'Update field on "{0}"'
                title_params = (str(form_name_fields),)
            self._manage_update_field(self.dlg_manage_fields, form_name_fields, is_multi_addfield, tableview='ve_config_addfields')
        elif action == 'delete':
            if is_multi_addfield:
                title = 'Delete multi field'
            else:
                title = 'Delete field on "{0}"'
                title_params = (str(form_name_fields),)
            self._manage_delete_field(form_name_fields, is_multi_addfield)

        # Set listeners
        self.dlg_manage_fields.btn_accept.clicked.connect(
            partial(self._manage_accept, action, form_name_fields, is_multi_addfield))
        self.dlg_manage_fields.btn_cancel.clicked.connect(partial(self._close_dialog_admin, self.dlg_manage_fields))
        self.dlg_manage_fields.tbl_update.doubleClicked.connect(
            partial(self._update_selected_addfild, self.dlg_manage_fields.tbl_update, is_multi_addfield))
        self.dlg_manage_fields.btn_open.clicked.connect(
            partial(self._update_selected_addfild, self.dlg_manage_fields.tbl_update, is_multi_addfield))

        tools_gw.open_dialog(self.dlg_manage_fields, dlg_name='admin_addfields')
        self.dlg_manage_fields.setWindowTitle(tools_qt.tr(title, list_params=title_params))

    def _update_selected_addfild(self, widget, is_multi_addfield):
        """"""

        selected_list = widget.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg)
            return

        # Create the dialog and signals
        self._close_dialog_admin(self.dlg_manage_fields)
        self.dlg_manage_fields = GwAdminFieldsUi(self)
        tools_gw.load_settings(self.dlg_manage_fields)
        self.model_update_table = None

        form_name_fields = tools_qt.get_text(self.dlg_readsql, self.dlg_readsql.cmb_formname_fields)
        self.dlg_manage_fields.columnname.setEnabled(False)
        self.dlg_manage_fields.datatype.setEnabled(False)
        self.dlg_manage_fields.widgettype.setEnabled(False)

        # Set listeners
        self.dlg_manage_fields.btn_accept.clicked.connect(
            partial(self._manage_accept, 'update', form_name_fields))
        self.dlg_manage_fields.btn_cancel.clicked.connect(partial(self._manage_close_dlg, self.dlg_manage_fields))

        # Remove unused tabs
        for x in range(self.dlg_manage_fields.tab_add_fields.count() - 1, -1, -1):
            if str(self.dlg_manage_fields.tab_add_fields.widget(x).objectName()) not in (str('tab_create'), 'tab_infolog'):
                tools_qt.remove_tab(self.dlg_manage_fields.tab_add_fields,
                                               self.dlg_manage_fields.tab_add_fields.widget(x).objectName())

        title = None
        title_params = None
        if is_multi_addfield:
            title = 'Update multi field'
        else:
            title = 'Update field on "{0}"'
            title_params = (str(form_name_fields),)
        self.dlg_manage_fields.setWindowTitle(tools_qt.tr(title, list_params=title_params))
        self._manage_create_field(form_name_fields, is_multi_addfield)

        row = selected_list[0].row()

        for column in range(widget.model().columnCount()):
            index = widget.model().index(row, column)

            result = tools_qt.get_widget(self.dlg_manage_fields, str(widget.model().headerData(column, Qt.Orientation.Horizontal)))
            if result is None:
                continue

            value = str(widget.model().data(index))
            if value == 'NULL':
                value = None
            tools_qt.set_widget_text(self.dlg_manage_fields, result, str(value))

        tools_gw.open_dialog(self.dlg_manage_fields, dlg_name='admin_addfields')

    def _manage_create_field(self, form_name, is_multi_addfield):
        """"""

        schema_name = self._get_selected_schema_name()

        # Alter visibility on widget that is only for multicreate action
        self.dlg_manage_fields.lbl_multifeaturetype.setVisible(is_multi_addfield)
        self.dlg_manage_fields.featuretype.setVisible(is_multi_addfield)

        if is_multi_addfield:
             # Populate featuretype combo
            rows = [['ALL', 'ALL'], ['NODE', 'NODE'], ['ARC', 'ARC'], ['CONNEC', 'CONNEC']]
            if self.project_type == 'ud':
                rows += [['GULLY', 'GULLY']]
            tools_qt.fill_combo_values(self.dlg_manage_fields.featuretype, rows)

        # Populate widgettype combo
        sql = (f"SELECT DISTINCT(id), idval FROM {schema_name}.config_typevalue "
               f"WHERE typevalue = 'widgettype_typevalue' AND addparam->>'createAddfield' = 'TRUE'")
        rows = tools_db.get_rows(sql, commit=self.dev_commit)
        tools_qt.fill_combo_values(self.dlg_manage_fields.widgettype, rows)

        # Populate datatype combo
        sql = (f"SELECT id, idval FROM {schema_name}.config_typevalue "
               f"WHERE typevalue = 'datatype_typevalue' AND addparam->>'createAddfield' = 'TRUE'")
        rows = tools_db.get_rows(sql, commit=self.dev_commit)
        tools_qt.fill_combo_values(self.dlg_manage_fields.datatype, rows)

        # Populate layoutname combo
        sql = (f"SELECT id, idval FROM {schema_name}.config_typevalue "
               f"WHERE typevalue = 'layout_name_typevalue' AND addparam->>'createAddfield' = 'TRUE'")
        rows = tools_db.get_rows(sql, commit=self.dev_commit)
        tools_qt.fill_combo_values(self.dlg_manage_fields.layoutname, rows)

        # Set default value for formtype widget
        tools_qt.set_widget_text(self.dlg_manage_fields, self.dlg_manage_fields.formtype, 'feature')

    def _manage_update_field(self, dialog, form_name, is_multi_addfield, tableview):
        """"""

        if form_name is None:
            return

        schema_name = self._get_selected_schema_name()
        if schema_name is None:
            tools_qt.enable_tab_by_tab_name(self.dlg_readsql.tab_main, "others", False)
            return
        else:
            tools_qt.enable_tab_by_tab_name(self.dlg_readsql.tab_main, "others", True)

        # Populate table update
        qtable = dialog.findChild(QTableView, "tbl_update")
        self.model_update_table = QSqlTableModel(db=lib_vars.qgis_db_credentials)
        qtable.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        if is_multi_addfield:
            expr_filter = "cat_feature_id IS NULL"
        else:
            expr_filter = f"cat_feature_id = '{form_name}'"

        self._fill_table(qtable, tableview, self.model_update_table, expr_filter)
        tools_gw.set_tablemodel_config(dialog, qtable, tableview, schema_name=schema_name)

    def _manage_delete_field(self, form_name, is_multi_addfield):
        """"""

        schema_name = self._get_selected_schema_name()
        if schema_name is None:
            tools_qt.enable_tab_by_tab_name(self.dlg_readsql.tab_main, "others", False)
            return
        else:
            tools_qt.enable_tab_by_tab_name(self.dlg_readsql.tab_main, "others", True)

        # Populate widgettype combo
        if is_multi_addfield:
            sql = (f"SELECT DISTINCT(columnname), columnname "
                f"FROM {schema_name}.ve_config_addfields "
                f"WHERE cat_feature_id IS NULL")
        else:
            sql = (f"SELECT DISTINCT(columnname), columnname "
                    f"FROM {schema_name}.ve_config_addfields "
                    f"WHERE cat_feature_id = '{form_name}'")

        rows = tools_db.get_rows(sql, commit=self.dev_commit)
        tools_qt.fill_combo_values(self.dlg_manage_fields.cmb_fields, rows)

    def _manage_close_dlg(self, dlg_to_close):
        """"""

        self._close_dialog_admin(dlg_to_close)
        if dlg_to_close.objectName() == 'dlg_man_addfields':
            self._open_manage_field('update')

    def _manage_accept(self, action, form_name, is_multi=False):
        """"""

        schema_name = self._get_selected_schema_name()
        # save prev user value
        sql = f"SELECT value FROM {schema_name}.config_param_system WHERE parameter = 'admin_config_control_trigger'"
        row = tools_db.get_row(sql)
        config_trg_user_value = row[0] if row is not None else True
        # set admin_config_control_trigger to true to force config_form_fields trigger
        sql = (f"UPDATE {schema_name}.config_param_system "
               f"SET value = 'TRUE' "
               f"WHERE parameter = 'admin_config_control_trigger'")
        tools_db.execute_sql(sql)

        # Execute manage add fields function
        param_name = tools_qt.get_text(self.dlg_manage_fields, self.dlg_manage_fields.columnname)
        sql = (f"SELECT param_name FROM {schema_name}.sys_addfields "
               f"WHERE param_name = '{param_name}' AND cat_feature_id = '{form_name}' ")
        row = tools_db.get_row(sql)

        # Check feature type selected for multi addfields actions
        if is_multi:
            feature_type = tools_qt.get_selected_item(self.dlg_manage_fields, self.dlg_manage_fields.featuretype)

        if action == 'create':

            # Control mandatory widgets
            column_name = tools_qt.get_text(self.dlg_manage_fields, self.dlg_manage_fields.columnname)
            label = tools_qt.get_text(self.dlg_manage_fields, self.dlg_manage_fields.label)
            widget_type = tools_qt.get_text(self.dlg_manage_fields, self.dlg_manage_fields.widgettype)
            dv_query_text = tools_qt.get_text(self.dlg_manage_fields, self.dlg_manage_fields.dv_querytext)

            if column_name == 'null' or label == 'null':
                msg = "Column name and Label fields are mandatory. Please set correct value."
                tools_qt.show_info_box(msg, "Info")
                return

            elif row is not None:
                msg = "Column name already exists."
                tools_qt.show_info_box(msg, "Info")
                return

            elif widget_type == 'combo' and dv_query_text in ('null', None):
                msg = "Parameter 'Query text:' is mandatory for 'combo' widgets. Please set value."
                tools_qt.show_info_box(msg, "Info")
                return

            list_widgets = self.dlg_manage_fields.tab_create.findChildren(QWidget)

            _json = {}
            result_json = None
            for widget in list_widgets:
                if type(widget) not in (QScrollArea, QFrame, QWidget, QScrollBar, QLabel, QAbstractButton, QHeaderView, QListView, QGroupBox, QTableView) \
                        and widget.objectName() != 'qt_spinbox_lineedit':

                    value = None
                    if type(widget) in (QLineEdit, QSpinBox, QDoubleSpinBox):
                        value = tools_qt.get_text(self.dlg_manage_fields, widget, return_string_null=False)
                    elif isinstance(widget, QComboBox):
                        value = tools_qt.get_combo_value(self.dlg_manage_fields, widget, 0)
                    elif type(widget) is QCheckBox:
                        value = tools_qt.is_checked(self.dlg_manage_fields, widget)
                    elif isinstance(widget, QgsDateTimeEdit):
                        value = tools_qt.get_calendar_date(self.dlg_manage_fields, widget)
                    elif type(widget) is QPlainTextEdit:
                        value = widget.document().toPlainText()

                    if str(widget.objectName()) not in (None, 'null', '', ""):
                        _json[str(widget.objectName())] = value
                        result_json = json.dumps(_json)

            # Create body
            if is_multi:
                feature = '"featureType":"' + feature_type + '"'
            else:
                feature = '"catFeature":"' + form_name + '"'
            extras = '"action":"CREATE", "parameters":' + result_json + ''
            body = tools_gw.create_body(feature=feature, extras=extras)
            body = body.replace('""', 'null')

            # Execute manage add fields function
            json_result = tools_gw.execute_procedure('gw_fct_admin_manage_addfields', body, schema_name)
            if not json_result or json_result['status'] == 'Failed':
                # set admin_config_control_trigger with prev user value
                sql = (f"UPDATE {schema_name}.config_param_system "
                    f"SET value = '{config_trg_user_value}' "
                    f"WHERE parameter = 'admin_config_control_trigger'")
                tools_db.execute_sql(sql)
                return
            msg = "Field configured in 'config_form_fields'"
            self._manage_json_message(json_result, parameter=msg)

        elif action == 'update':

            list_widgets = self.dlg_manage_fields.tab_create.findChildren(QWidget)

            _json = {}
            result_json = None
            for widget in list_widgets:
                if type(widget) not in (
                        QScrollArea, QFrame, QWidget, QScrollBar, QLabel, QAbstractButton, QHeaderView, QListView, QGroupBox,
                        QTableView) and widget.objectName() != 'qt_spinbox_lineedit':

                    value = None
                    if type(widget) in (QLineEdit, QSpinBox, QDoubleSpinBox):
                        value = tools_qt.get_text(self.dlg_manage_fields, widget, return_string_null=False)
                    elif isinstance(widget, QComboBox):
                        value = tools_qt.get_combo_value(self.dlg_manage_fields, widget, 0)
                    elif type(widget) is QCheckBox:
                        value = tools_qt.is_checked(self.dlg_manage_fields, widget)
                    elif type(widget) is QgsDateTimeEdit:
                        value = tools_qt.get_calendar_date(self.dlg_manage_fields, widget)
                    elif type(widget) is QPlainTextEdit:
                        value = widget.document().toPlainText()

                    result_json = None
                    if str(widget.objectName()) not in (None, 'null', '', ""):
                        _json[str(widget.objectName())] = value
                        result_json = json.dumps(_json)

            # Create body
            if is_multi:
                feature = '"featureType":"' + feature_type + '"'
            else:
                feature = '"catFeature":"' + form_name + '"'
            extras = '"action":"UPDATE", "parameters":' + result_json + ''
            body = tools_gw.create_body(feature=feature, extras=extras)
            body = body.replace('""', 'null')

            # Execute manage add fields function
            json_result = tools_gw.execute_procedure('gw_fct_admin_manage_addfields', body, schema_name)
            msg = "Field update in 'config_form_fields'"
            self._manage_json_message(json_result, parameter=msg)
            if not json_result or json_result['status'] == 'Failed':
                return

        elif action == 'delete':

            field_value = tools_qt.get_text(self.dlg_manage_fields, self.dlg_manage_fields.cmb_fields)

            sql = (f"SELECT feature_type FROM {schema_name}.sys_addfields "
                f"WHERE param_name = '{field_value}'")
            feature_type = tools_db.get_row(sql)[0]

            # Create body
            if is_multi:
                feature = '"featureType":"' + feature_type + '"'
            else:
                feature = '"catFeature":"' + form_name + '"'
            extras = '"action":"DELETE", "parameters":{"columnname":"' + field_value + '"}'
            body = tools_gw.create_body(feature=feature, extras=extras)

            # Execute manage add fields function
            json_result = tools_gw.execute_procedure('gw_fct_admin_manage_addfields', body, schema_name)
            msg = "Delete function"
            self._manage_json_message(json_result, parameter=msg)

        # set admin_config_control_trigger with prev user value
        sql = (f"UPDATE {schema_name}.config_param_system "
               f"SET value = '{config_trg_user_value}' "
               f"WHERE parameter = 'admin_config_control_trigger'")
        tools_db.execute_sql(sql)

    def _change_project_type(self, widget):
        """Update SQL paths when project type changes (create-project dialog)."""

        project_type = tools_qt.get_text(self.dlg_readsql, widget)
        if project_type and project_type != 'null':
            self._set_project_type_paths(project_type)

    def _populate_functions_dlg(self, dialog, result):
        """"""

        status = False
        if len(result) != 0:
            dialog.setWindowTitle(result['alias'])
            dialog.txt_info.setText(str(result['descript']))
            self.function_list = []
            tools_gw.build_dialog_options(dialog, result, 0, self.function_list)
            status = True

        return status

    def _set_log_text(self, dialog, data):
        """"""

        for k, v in list(data.items()):
            if str(k) == "info":
                tools_gw.fill_tab_log(dialog, data)

    def _manage_result_message(self, status: bool, msg_ok: Union[str, None] = None, msg_error: Union[str, None] = None, parameter: Union[str, None] = None) -> None:
        """ 
        Manage message depending result @status 

        :param status: The status of the process.
        :param msg_ok: The message to show if the process finished successfully.
        :param msg_error: The message to show if the process finished with some errors.
        :param parameter: The parameter to show in the message.
        """

        if status:
            if msg_ok is None:
                msg = "Process finished successfully"
                msg_ok = msg
            if lib_vars.session_vars.get("message_parent"):
                tools_qt.show_info_box(msg_ok, "Info", parameter=parameter)
            else:
                tools_qgis.show_info(msg_ok, parameter=parameter)
        else:
            if msg_error is None:
                msg = "Process finished with some errors"
                msg_error = msg
            if lib_vars.session_vars.get("message_parent"):
                tools_qt.show_warning_box(msg_error, parameter=parameter)
            else:
                tools_qgis.show_warning(msg_error, parameter=parameter)

    def _manage_json_message(self, json_result, parameter=None, title=None):
        """ Manage message depending result @status """

        message = json_result.get('message')
        if message:

            level = message.get('level')
            if level is not None:
                level = int(level)
            else:
                level = 1
            msg = message.get('text')
            if msg is None:
                msg = "Key on returned json from ddbb is missed"
            level = Qgis.MessageLevel(level)
            tools_qgis.show_message(msg, level, parameter=parameter, title=title)

        data = json_result['body'].get('data')
        tools_gw.fill_tab_log(self.dlg_manage_fields, data)
        qtabwidget = self.dlg_manage_fields.findChild(QTabWidget, 'tab_add_fields')
        if qtabwidget is not None:
            # Remove unused tabs
            for x in range(qtabwidget.count() - 1, -1, -1):
                qtabwidget.setTabEnabled(x, False)
            qtabwidget.setTabEnabled(qtabwidget.count() - 1, True)
            qtabwidget.setCurrentIndex(qtabwidget.count() - 1)

    def _save_selection(self):
        """Persist last project schema per connection (avoids cross-connection ghosts)."""

        schema_name = self._get_selected_schema_name() or 'null'
        connection_name = self._current_connection_name()
        key = self._schema_session_key(connection_name)
        tools_gw.set_config_parser('btn_admin', key, f'{schema_name}', prefix=False)

    def _create_credentials_form(self, set_connection):
        """"""

        self.dlg_credentials = GwCredentialsUi(self)
        tools_gw.load_settings(self.dlg_credentials)
        if str(self.list_connections) != '[]':
            tools_qt.fill_combo_values(self.dlg_credentials.cmb_connection, self.list_connections)
        else:
            msg = ("You don't have any connection to PostGIS database configurated. "
                  "Check your QGIS data source manager and create at least one")
            tools_qt.show_info_box(msg, "Info")
            return

        tools_qt.set_widget_text(self.dlg_credentials, self.dlg_credentials.cmb_connection, str(set_connection))

        self.dlg_credentials.btn_accept.clicked.connect(partial(self._set_credentials, self.dlg_credentials))
        self.dlg_credentials.cmb_connection.currentIndexChanged.connect(
            partial(self._set_credentials, self.dlg_credentials, new_connection=True))

        sslmode_list = [['disable', 'disable'], ['allow', 'allow'], ['prefer', 'prefer'], ['require', 'require'],
                        ['verify - ca', 'verify - ca'], ['verify - full', 'verify - full']]
        tools_qt.fill_combo_values(self.dlg_credentials.cmb_sslmode, sslmode_list, 0)
        msg = 'prefer'
        tools_qt.set_widget_text(self.dlg_credentials, self.dlg_credentials.cmb_sslmode, msg)

        tools_gw.open_dialog(self.dlg_credentials, dlg_name='admin_credentials', skip_db_check=True)

    def _manage_user_params(self):
        """"""

        # Update variable composer_path on config_param_user
        folder_name = os.path.dirname(os.path.abspath(__file__))
        composers_path_vdef = os.path.normpath(os.path.normpath(folder_name + os.sep + os.pardir)) + os.sep + \
            'resources' + os.sep + 'templates' + os.sep + 'qgiscomposer' + os.sep + 'en_US'
        sql = (f"UPDATE {self.schema_name}.config_param_user "
               f"SET value = '{composers_path_vdef}' "
               f"WHERE parameter = 'qgis_composers_folderpath' AND cur_user = current_user")
        tools_db.execute_sql(sql, commit=self.dev_commit)

    def _select_active_locales(self):
        rows = i18n_service.list_locales_for_combo(flag="active")
        if rows is None:
            return []
        return list(rows)

    def _save_custom_sql_path(self, dialog):

        folder_path = tools_qt.get_text(dialog, "custom_path_folder")
        if folder_path == "null":
            folder_path = None
        tools_gw.set_config_parser("btn_admin", "custom_sql_path", f"{folder_path}", "user", "session")

    def _manage_docker(self):
        """ Puts the dialog in a docker, depending on the user configuration """

        try:
            tools_gw.close_docker('admin_position')
            lib_vars.session_vars['docker_type'] = 'qgis_form_docker'
            lib_vars.session_vars['dialog_docker'] = GwDocker(self)
            lib_vars.session_vars['dialog_docker'].dlg_closed.connect(partial(tools_gw.close_docker, 'admin_position'))
            tools_gw.manage_docker_options('admin_position')
            tools_gw.docker_dialog(self.dlg_readsql, dlg_name='admin')
            self.dlg_readsql.dlg_closed.connect(partial(tools_gw.close_docker, 'admin_position'))
            self._set_buttons_enabled()
        except Exception as e:
            tools_log.log_info(str(e))
            tools_gw.open_dialog(self.dlg_readsql, dlg_name='admin', skip_db_check=True)

    def _set_buttons_enabled(self):
        """Hide schema CRUD unless superuser or role_system; enable/disable when visible."""

        can_admin = self.form_enabled and self._can_administer_schemas()
        self._set_schema_crud_visible(can_admin)
        if not can_admin:
            return

        # Check schema name
        schema_name = self._get_selected_schema_name() or 'null'

        # Buttons delete, rename and copy schema
        self.dlg_readsql.btn_delete.setEnabled(schema_name != "null")
        self.dlg_readsql.btn_schema_rename.setEnabled(schema_name != "null")
        self.dlg_readsql.btn_copy.setEnabled(schema_name != "null")
        self.dlg_readsql.btn_schema_create.setEnabled(True)

        plugin_tuple = _admin_version_tuple(self.plugin_version)
        project_tuple = _admin_version_tuple(getattr(self, 'project_version', None) or '0')
        self.dlg_readsql.btn_info.setEnabled(plugin_tuple > project_tuple)

        project_type = self._get_selected_project_type()

        # Buttons to manage am / cm / audit (single catalog query when possible)
        if self._admin_catalog_cache and self._admin_catalog_cache.aux_flags:
            aux = self._admin_catalog_cache.aux_flags
        else:
            aux = admin_catalog.fetch_aux_schema_flags()
        am_exists = aux.get('am', False)
        cm_exists = aux.get('cm', False)
        audit_namespace = aux.get('audit', False)
        audit_full = admin_catalog.is_audit_fully_installed()

        self.dlg_readsql.btn_create_asset.setEnabled(
            project_type == "ws" and schema_name != "null" and not am_exists
        )
        msg = "Open Manage Schemas to create and integrate am"
        self.dlg_readsql.btn_create_asset.setToolTip(tools_qt.tr(msg))
        self.dlg_readsql.btn_update_asset.setEnabled(am_exists)
        self.dlg_readsql.btn_delete_asset.setEnabled(am_exists)

        self.dlg_readsql.btn_update_cm.setEnabled(cm_exists)

        self.dlg_readsql.btn_create_audit.setEnabled(schema_name != "null" and not audit_full)
        self.dlg_readsql.btn_activate_audit.setEnabled(schema_name != "null" and audit_full)
        self.dlg_readsql.btn_reload_audit_triggers.setEnabled(schema_name != "null" and audit_full)
        self.dlg_readsql.btn_delete_audit.setEnabled(audit_namespace)

    def _manage_utils(self):
        if self._admin_catalog_cache and self._admin_catalog_cache.sys_version_schemas:
            schemas = self._admin_catalog_cache.sys_version_schemas
        else:
            schemas = admin_catalog.fetch_sys_version_schemas()

        ws_result_list = admin_catalog.combo_items_for_project_type(schemas, 'ws')
        ud_result_list = admin_catalog.combo_items_for_project_type(schemas, 'ud')

        if not ws_result_list:
            self.dlg_readsql.cmb_utils_ws.clear()
        else:
            tools_qt.fill_combo_values(self.dlg_readsql.cmb_utils_ws, ws_result_list)

        if not ud_result_list:
            self.dlg_readsql.cmb_utils_ud.clear()
        else:
            tools_qt.fill_combo_values(self.dlg_readsql.cmb_utils_ud, ud_result_list)
        
        self._manage_cibs(ws_result_list, ud_result_list)

    def _manage_cibs(self, ws_result_list, ud_result_list):
        """Refresh cibs combo and button states."""

        cibs_result_list = ws_result_list + ud_result_list
        if not cibs_result_list:
            self.dlg_readsql.cmb_cibs.clear()
        else:
            tools_qt.fill_combo_values(self.dlg_readsql.cmb_cibs, cibs_result_list)

        self.dlg_readsql.btn_create_cibs.setEnabled(not admin_catalog.schema_exists("cibs"))
        self.dlg_readsql.btn_adapt_cibs.setEnabled(admin_catalog.schema_exists("cibs"))

    def _get_cibs_schema_info(self, schema_name=None):
        """Return selected schema name and sys_version row, or None if invalid."""

        if not schema_name:
            schema_name = tools_qt.get_text(
                self.dlg_readsql, self.dlg_readsql.cmb_cibs, return_string_null=False
            )
        if schema_name == "":
            return None

        sql = (f"SELECT giswater, language, epsg, project_type "
               f"FROM {schema_name}.sys_version ORDER BY id DESC LIMIT 1")
        row = tools_db.get_row(sql)
        if row is None:
            return None

        project_type = row[3].lower() if row[3] else None
        if project_type not in ('ws', 'ud'):
            return None

        return schema_name, row, project_type

    def _cibs_schema_exists(self):
        return admin_catalog.schema_exists("cibs")

    def _run_create_utils_task(
        self,
        profile,
        process_name,
        ws_schema='',
        ud_schema='',
        copy_source='',
        project_version='0.0.0',
        locale=None,
        srid=None,
        on_done=None,
    ):
        register_is_new = 'true' if profile == 'empty' else 'false'
        infer_parents = 'true' if profile == 'update' else 'false'
        integrate_parent_type = ''
        if profile == 'integrate_ws':
            integrate_parent_type = 'ws'
        elif profile == 'integrate_ud':
            integrate_parent_type = 'ud'
        register_parent = ws_schema if profile == 'integrate_ws' else (
            ud_schema if profile == 'integrate_ud' else ''
        )

        srid = str(srid or getattr(self, 'project_epsg', None) or '25831')
        locale = str(locale or self.locale)
        parent_schema = ws_schema or ud_schema
        if parent_schema and profile != 'update':
            row = tools_db.get_row(
                f"SELECT giswater, language, epsg FROM {parent_schema}.sys_version "
                "ORDER BY id DESC LIMIT 1"
            )
            if row:
                locale = str(row[1])
                srid = str(row[2])

        bp = BuildParams(
            schema_name='utils',
            srid=srid,
            locale=locale,
            plugin_version=str(self.plugin_version),
            project_version=str(project_version),
            profile=profile,
            run_mode='upgrade' if profile == 'update' else 'new_project',
            ws_schema=ws_schema or '',
            ud_schema=ud_schema or '',
            parent_schema=parent_schema or '',
            parent_type=integrate_parent_type,
            copy_source_schema=copy_source or '',
            register_is_new=register_is_new,
            infer_parents_from_config=infer_parents,
            register_parent_schema=register_parent,
            sql_root=self.sql_dir,
        )

        callback = on_done if on_done is not None else partial(self._on_builder_done_utils, 'utils')
        self._submit_builder(
            'utils', bp,
            description=process_name,
            on_done=callback,
        )

    def _create_utils(self):
        """Create the (singleton) utils satellite schema via the engine."""
        if admin_catalog.schema_exists('utils'):
            msg = "Schema Utils already exist."
            tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return
        self._run_create_utils_task('empty', 'Create utils schema')

    def _adapt_utils_ws(self, ws_schema=None):
        ws = ws_schema or tools_qt.get_text(
            self.dlg_readsql, self.dlg_readsql.cmb_utils_ws, return_string_null=False
        )
        if not ws:
            msg = "Select a WS schema to integrate."
            tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return
        if not admin_catalog.schema_exists('utils'):
            msg = "Utils schema does not exist. Create it first."
            tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return
        row = tools_db.get_row(f"SELECT {ws}.gw_fct_admin_satellite_enabled('utils')")
        if row and row[0] is True:
            msg = "Selected schema is already integrated with utils."
            tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return
        self._run_create_utils_task('integrate_ws', 'Integrate utils with WS', ws_schema=ws)

    def _adapt_utils_ud(self, ud_schema=None):
        ud = ud_schema or tools_qt.get_text(
            self.dlg_readsql, self.dlg_readsql.cmb_utils_ud, return_string_null=False
        )
        if not ud:
            msg = "Select a UD schema to integrate."
            tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return
        if not admin_catalog.schema_exists('utils'):
            msg = "Utils schema does not exist. Create it first."
            tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return
        row = tools_db.get_row(f"SELECT {ud}.gw_fct_admin_satellite_enabled('utils')")
        if row and row[0] is True:
            msg = "Selected schema is already integrated with utils."
            tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return
        self._run_create_utils_task('integrate_ud', 'Integrate utils with UD', ud_schema=ud)

    def _create_cibs(self):

        if self._cibs_schema_exists():
            msg = "Schema cibs already exists."
            tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return

        self._run_create_cibs_task('empty', 'Create cibs schema')

    def _adapt_cibs(self, parent_schema=None):

        schema_info = self._get_cibs_schema_info(schema_name=parent_schema)
        if schema_info is None:
            msg = "Select a WS or UD schema to adapt to cibs"
            if lib_vars.session_vars.get("message_parent"):
                tools_qt.show_info_box(msg, "Info")
            else:
                tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return

        self.cibs_project_name, self.cibs_project_result, self.cibs_project_type = schema_info

        if not self._cibs_schema_exists():
            msg = "Cibs schema does not exist. Create it first."
            if lib_vars.session_vars.get("message_parent"):
                tools_qt.show_info_box(msg, "Info")
            else:
                tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return

        sql = (f"SELECT value::boolean FROM {self.cibs_project_name}.config_param_system "
               f"WHERE parameter = 'admin_cibs_schema'")
        row = tools_db.get_row(sql)
        if row and row[0] is True:
            msg = "Selected schema is already adapted to cibs."
            if lib_vars.session_vars.get("message_parent"):
                tools_qt.show_info_box(msg, "Info")
            else:
                tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return

        schema_name = self.cibs_project_name
        msg = ("You are about to adapt schema '{0}' to cibs.\n\n"
               "Are you sure you want to continue?")
        msg_params = (schema_name,)
        title = "Adapt schema to cibs"
        answer = tools_qt.show_question(msg, title, msg_params=msg_params)

        if not answer:
            return

        self._run_create_cibs_task(
            'integrate',
            'Adapt schema to cibs',
            parent_schema=self.cibs_project_name,
            parent_type=self.cibs_project_type,
        )

    def _copy_cibs_data(self, parent_schema=None):

        schema_info = self._get_cibs_schema_info(schema_name=parent_schema)
        if schema_info is None:
            msg = "Select a WS or UD schema to copy data to cibs"
            if lib_vars.session_vars.get("message_parent"):
                tools_qt.show_info_box(msg, "Info")
            else:
                tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return

        self.cibs_project_name, self.cibs_project_result, self.cibs_project_type = schema_info

        if not self._cibs_schema_exists():
            msg = "cibs schema does not exist. Create it first."
            tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return

        sql = (f"SELECT value::boolean FROM {self.cibs_project_name}.config_param_system "
               f"WHERE parameter = 'admin_cibs_schema'")
        row = tools_db.get_row(sql)
        if row is None or row[0] is not True:
            msg = "Selected schema must be adapted to cibs before copying data"
            tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return

        self._run_create_cibs_task(['copy_data_cibs'], 'Copy data to cibs')

    def _update_utils(self, schema_name=None, on_done=None):
        """Run the utils 'update' profile in place."""
        row = tools_db.get_row(
            "SELECT giswater, language, epsg FROM utils.sys_version ORDER BY id DESC LIMIT 1"
        )
        current_version = row[0] if row and row[0] else "0.0.0"
        network_parents = admin_catalog.get_utils_network_parents()
        ws_list = network_parents.get("ws") or []
        ud_list = network_parents.get("ud") or []
        self._run_create_utils_task(
            'update',
            'Update utils schema',
            ws_schema=ws_list[0] if ws_list else '',
            ud_schema=ud_list[0] if ud_list else '',
            project_version=str(current_version),
            locale=str(row[1] if row and row[1] else self.locale),
            srid=str(row[2] if row and row[2] else self.project_epsg or "25831"),
            on_done=on_done,
        )

    def _create_i18n(self, manage_schemas_dlg=None):
        """Create multilang schema and seed en_US baseline translations."""
        if admin_catalog.schema_exists('multilang'):
            msg = "Schema multilang already exists."
            tools_qgis.show_message(msg, Qgis.MessageLevel.Info)
            return False
        from .i18n.multilang_seed_sql import invalidate_baseline_fingerprint_cache
        invalidate_baseline_fingerprint_cache(self.sql_dir)
        bp = BuildParams(
            schema_name='multilang',
            srid=str(self.project_epsg or "25831"),
            locale="en_US",
            plugin_version=str(self.plugin_version),
            profile='empty',
            register_is_new='true',
            sql_root=self.sql_dir,
        )
        self._submit_multilang_task(
            bp,
            description='Create multilang schema',
            on_done=partial[None](self._on_builder_done_other_update, 'multilang'),
            manage_schemas_dlg=manage_schemas_dlg,
        )
        return True

    def _submit_multilang_task(
        self,
        params,
        *,
        description=None,
        on_done=None,
        manage_schemas_dlg=None,
    ):
        """Queue multilang build + baseline seed on the QGIS task manager."""
        self._open_schema_build_message_log()
        self.schema_build_progress_hint = ""
        self.error_count = 0
        self.t0 = time()
        self.timer = QTimer()
        self.timer.start(1000)

        msg = "Create multilang schema"
        desc = description or tools_qt.tr(msg)
        task = GwMultilangSchemaTask(
            self,
            params,
            description=desc,
            timer=self.timer,
            on_done=on_done,
            manage_schemas_dlg=manage_schemas_dlg,
        )
        self.task_create_schema = task
        QgsApplication.taskManager().addTask(task)
        QgsApplication.taskManager().triggerTask(task)
        return task

    def _update_i18n(self, on_done=None, manage_schemas_dlg=None):
        """Run multilang schema update and re-seed baseline translations."""
        from .i18n.multilang_seed_sql import invalidate_baseline_fingerprint_cache
        invalidate_baseline_fingerprint_cache(self.sql_dir)
        row = tools_db.get_row(
            "SELECT giswater, language, epsg FROM multilang.sys_version "
            "ORDER BY id DESC LIMIT 1"
        )
        current_version = row[0] if row and row[0] else "0.0.0"
        bp = BuildParams(
            schema_name='multilang',
            srid=str(row[2] if row and row[2] else self.project_epsg or "25831"),
            locale=str(row[1] if row and row[1] else self.locale),
            plugin_version=str(self.plugin_version),
            project_version=str(current_version),
            profile='update',
            run_mode='upgrade',
            sql_root=self.sql_dir,
        )
        callback = on_done if on_done is not None else partial(self._on_builder_done_other_update, 'multilang')
        msg = "Update multilang schema"
        self._submit_multilang_task(
            bp,
            description=tools_qt.tr(msg),
            on_done=callback,
            manage_schemas_dlg=manage_schemas_dlg,
        )

    def _update_cibs(self, on_done=None):
        """Run the cibs 'update' profile in place."""
        row = tools_db.get_row(
            "SELECT giswater, language, epsg FROM cibs.sys_version ORDER BY id DESC LIMIT 1"
        )
        current_version = row[0] if row and row[0] else "0.0.0"
        bp = BuildParams(
            schema_name='cibs',
            srid=str(row[2] if row and row[2] else self.project_epsg or "25831"),
            locale=str(row[1] if row and row[1] else self.locale),
            plugin_version=str(self.plugin_version),
            project_version=str(current_version),
            profile='update',
            run_mode='upgrade',
            sql_root=self.sql_dir,
        )
        callback = on_done if on_done is not None else partial(self._on_builder_done_other_update, 'cibs')
        msg = "Update cibs schema"
        self._submit_builder(
            'cibs',
            bp,
            description=tools_qt.tr(msg),
            on_done=callback,
        )

    def _update_audit(self, on_done=None):
        """Run the audit 'update' profile in place."""
        row = tools_db.get_row(
            "SELECT giswater, language, epsg FROM audit.sys_version ORDER BY id DESC LIMIT 1"
        )
        current_version = row[0] if row and row[0] else "0.0.0"
        bp = BuildParams(
            schema_name='audit',
            srid=str(row[2] if row and row[2] else self.project_epsg or "25831"),
            locale=str(row[1] if row and row[1] else self.locale),
            plugin_version=str(self.plugin_version),
            project_version=str(current_version),
            profile='update',
            run_mode='upgrade',
            parent_schema='audit',
            parent_type='',
            register_is_new='false',
            sql_root=self.sql_dir,
        )
        callback = on_done if on_done is not None else partial(self._on_builder_done_other_update, 'audit')
        msg = "Update audit schema"
        self._submit_builder(
            'audit',
            bp,
            description=tools_qt.tr(msg),
            on_done=callback,
        )

    def _on_builder_done_utils(self, schema_name, result):
        if not result.ok:
            self.error_count += 1
        self.manage_process_result(schema_name, 'utils', is_utils=True)

    def _update_asset(self, parent_schema=None, parent_type=None, on_done=None):
        """Run the am 'update' profile in place (semver upgrade)."""
        row = tools_db.get_row(
            "SELECT giswater, language, epsg FROM am.sys_version ORDER BY id DESC LIMIT 1"
        )
        current_version = row[0] if row and row[0] else "0.0.0"

        parent_schema, parent_type = self._resolve_parent_context(parent_schema, parent_type)
        if not parent_schema:
            tools_qgis.show_warning(
                "Select the ws project schema linked to am before updating."
            )
            return

        bp = BuildParams(
            schema_name='am',
            srid=str(row[2] if row and row[2] else "0"),
            locale=str(row[1] if row and row[1] else self.locale),
            plugin_version=str(self.plugin_version),
            project_version=str(current_version),
            profile='update',
            run_mode='upgrade',
            parent_schema=parent_schema,
            parent_type=parent_type,
            sql_root=self.sql_dir,
        )
        callback = on_done if on_done is not None else partial(self._on_builder_done_other_update, 'am')
        msg = "Update am schema"
        self._submit_builder('am', bp,
                             description=tools_qt.tr(msg),
                             on_done=callback)

    def _update_cm(self, parent_schema=None, parent_type=None, cm_schema=None, on_done=None):
        """Run the cm 'update' profile in place (semver upgrade)."""
        cm_schema = cm_schema or admin_catalog.find_cm_schema() or "cm"
        row = tools_db.get_row(
            f"SELECT giswater, language, epsg FROM {cm_schema}.sys_version "
            "ORDER BY id DESC LIMIT 1"
        )
        current_version = row[0] if row and row[0] else "0.0.0"

        parent_schema, parent_type = self._resolve_parent_context(parent_schema, parent_type)

        bp = BuildParams(
            schema_name=cm_schema,
            srid=str(row[2] if row and row[2] else "0"),
            locale=str(row[1] if row and row[1] else self.locale),
            plugin_version=str(self.plugin_version),
            project_version=str(current_version),
            profile='update',
            run_mode='upgrade',
            parent_schema=parent_schema or "",
            parent_type=parent_type,
            sql_root=self.sql_dir,
        )
        callback = on_done if on_done is not None else partial(self._on_builder_done_other_update, 'cm')
        msg = "Update cm schema"
        self._submit_builder('cm', bp,
                             description=tools_qt.tr(msg),
                             on_done=callback)

    def _on_builder_done_other_update(self, schema_name, result):
        if not result.ok:
            self.error_count += 1
        self.manage_other_process_result()

    def _calculate_elapsed_time(self, dialog):

        elapsed_seconds = int(time() - self.t0)
        hint = getattr(self, "schema_build_progress_hint", "") or ""
        if hint:
            text = f"{format_elapsed_mmss(elapsed_seconds)} | {hint}"
        else:
            task = self._active_schema_build_task()
            if task is not None:
                label = getattr(task, "_last_progress_label", "") or ""
                sql_root = getattr(getattr(task, "params", None), "sql_root", "") or ""
                seen = getattr(self, "current_sql_file", 0)
                total = getattr(self, "total_sql_files", 0)
                text = format_lbl_time_status(
                    elapsed_seconds, seen, total, label, sql_root=sql_root
                )
            else:
                text = format_elapsed_mmss(elapsed_seconds)
        self._update_time_elapsed(text, dialog)

    def _update_time_elapsed(self, text, dialog):

        if isdeleted(dialog):
            self.timer.stop()
            return

        lbl_time = dialog.findChild(QLabel, 'lbl_time')
        if lbl_time is None:
            return
        lbl_time.setText(text)

    # endregion
