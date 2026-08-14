"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

Hot-update dialog: apply downloaded translation SQL to a project schema.

Also hosts the Multilang tab that sets the per-schema multilang language
preference when the multilang satellite schema exists.
"""
# -*- coding: utf-8 -*-
import os
import re
from functools import partial

from qgis.PyQt.QtCore import QEvent, QObject, Qt, QTimer
from qgis.PyQt.QtGui import QStandardItem, QStandardItemModel
from qgis.PyQt.QtWidgets import (
    QListWidget, QCompleter, QLineEdit, QVBoxLayout, QWidget,
    QHeaderView, QSizePolicy, QScrollArea,
)

from ...ui.ui_manager import GwAdminI18NHotUpdateUi
from ...utils import tools_gw
from qgis.PyQt.sip import isdeleted
from ....libs import lib_vars, tools_qt, tools_db, tools_os, tools_qgis
from .. import _admin_catalog as admin_catalog
from .language_shared_functions import I18N_SCHEMAS
from . import language_shared_functions as i18n_service
from .language_packages_dialog import GwI18NManageLanguagesDialog
from .multilang_languages_dialog import GwI18NMultilangLanguagesDialog
from .multilang_seed_sql import build_change_lang_sql, normalize_language_folder


_SCHEMA_COLUMNS = ("Schema", "Kind", "Version", "Language", "Created", "Last update")
_COL_SCHEMA = 0
_COL_KIND = 1
_COL_VERSION = 2
_COL_LANGUAGE = 3
_COL_CREATED = 4
_COL_UPDATED = 5
_TRANSLATABLE_KINDS = frozenset({"WS", "UD", "AM", "CM"})
_MAX_VISIBLE_SCHEMA_ROWS = 5
_NETWORK_DBTABLES = [
    "dbparam_user", "dbconfig_param_system", "dbconfig_form_fields", "dbconfig_typevalue",
    "dbfprocess", "dbmessage", "dbconfig_csv", "dbconfig_form_tabs", "dbconfig_report",
    "dbconfig_toolbox", "dbfunction", "dblabel", "dbtypevalue", "dbconfig_form_fields_feat",
    "dbconfig_form_tableview", "dbconfig_visit_parameter", "dbtable", "dbplan_price", "dbstyle",
    "su_basic_tables", "dbjson", "dbconfig_form_fields_json", "dbconfig_form_fields_query",
]
_TAB_DATA_LINE_RE = re.compile(r",\s*'tab_data'\s*,")
_FORM_FIELDS_SQL = frozenset({
    "dbconfig_form_fields.sql",
    "dbconfig_form_fields_feat.sql",
    "dbconfig_form_fields_json.sql",
    "dbconfig_form_fields_query.sql",
})
_HOT_UPDATE_TAB_INDEX = 0
_MULTILANG_TAB_INDEX = 1


class GwAdminI18NHotUpdate:

    def __init__(self, admin_btn):
        self.admin = admin_btn
        self._active_connection = ""
        self._selected_schema = ""
        self._inventory_rows: list[dict] = []
        self._schema_model = None
        self._tables_project_type = "ws"
        self._i18n_password = ""
        self.dlg_qm = None
        self._scroll_area = None
        self._scroll_content = None
        self._tab_heights: dict[int, int] = {}
        self._last_tab_index: int | None = None
        self.dev_commit = None

    def init_dialog(self):
        """Constructor"""

        self.dlg_qm = GwAdminI18NHotUpdateUi(self)
        self._setup_status_label()
        self._schema_model = QStandardItemModel(0, len(_SCHEMA_COLUMNS), self.dlg_qm)
        self._schema_model.setHorizontalHeaderLabels(list(_SCHEMA_COLUMNS))
        tools_gw.load_settings(self.dlg_qm)
        self.dev_commit = tools_gw.get_config_parser(
            'system', 'force_commit', "user", "init", prefix=True,
        )

        self.dbtables_dic = self.tables_dic()
        self._setup_connection()
        self._setup_schema_table()
        self._set_signals()
        self._setup_tables_filter()
        self._refresh_schema_table()
        self._populate_language_combo(mode="hot_update", first_insert=True)
        self._populate_language_combo(mode="multilang")
        self._last_tab_index = self.dlg_qm.tab_update_type.currentIndex()
        self.admin._manage_schemas_update_system_info = self._update_system_info
        self.dlg_qm.finished.connect(self._clear_admin_callbacks)
        tools_gw.open_dialog(self.dlg_qm, dlg_name='admin_i18n_hot_update')
        # Fit after show/layout — same as tab change — so sizeHint includes the filter.
        QTimer.singleShot(0, self._apply_dialog_height)

    def _set_signals(self):
        self.dlg_qm.btn_update.clicked.connect(partial(self._run_update))
        self.dlg_qm.btn_close.clicked.connect(partial(tools_gw.close_dialog, self.dlg_qm))
        self.dlg_qm.btn_manage_language_hot_update.clicked.connect(partial(self._open_manage_language_hot_update))
        self.dlg_qm.btn_manage_language_multilang.clicked.connect(partial(self._open_manage_language_multilang))
        self.dlg_qm.btn_refresh.clicked.connect(partial(self._refresh_schema_table))
        self.dlg_qm.cmb_connection.currentIndexChanged.connect(partial(self._on_connection_changed))
        self.dlg_qm.cmb_language_hot_update.currentIndexChanged.connect(partial(self._save_language_selection, 
                                                                            self.dlg_qm.cmb_language_hot_update))
        self.dlg_qm.cmb_language_multilang.currentIndexChanged.connect(partial(self._save_language_selection, 
                                                                            self.dlg_qm.cmb_language_multilang))
        self.dlg_qm.tab_update_type.currentChanged.connect(partial(self._on_tab_changed))
        self.dlg_qm.btn_apply.clicked.connect(partial(self._apply_multilang))

    def _setup_status_label(self) -> None:
        self.dlg_qm.lbl_info.setWordWrap(False)
        self.dlg_qm.lbl_info.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)

    def _setup_connection(self) -> None:
        self.admin._populate_combo_connections()
        if self.admin.list_connections:
            tools_qt.fill_combo_values(
                self.dlg_qm.cmb_connection, self.admin.list_connections,
            )
        current = ""
        if getattr(self.admin, "cmb_connection", None) is not None:
            current = tools_qt.get_text(
                self.admin.dlg_readsql,
                self.admin.cmb_connection,
                return_string_null=False,
            )
        if not current:
            current = self.admin._get_last_connection() or ""
        if current:
            tools_qt.set_combo_value(self.dlg_qm.cmb_connection, current, 1)
        self._active_connection = current
        schema = ""
        get_schema = getattr(self.admin, "_get_selected_schema_name", None)
        if get_schema:
            schema = get_schema() or ""
        if not schema:
            schema = str(getattr(lib_vars, "schema_name", "") or "")
        self._selected_schema = schema
        self._update_system_info()

    def _format_system_info(self) -> str:
        result = getattr(self.admin, "_admin_catalog_cache", None)
        pg = self.admin.postgresql_version or "?"
        postgis = self.admin.postgis_version or "?"
        pgrouting = self.admin.pgrouting_version or "?"
        lines = [
            f"{tools_qt.tr('PostgreSQL version')}: {pg}",
            f"{tools_qt.tr('PostGis version')}: {postgis}",
            f"{tools_qt.tr('PgRouting version')}: {pgrouting}",
        ]
        if result and getattr(result, "extensions_present", None):
            missing = sorted(
                name for name, present in result.extensions_present.items() if not present
            )
            if missing:
                lines.append(
                    f"{tools_qt.tr('Missing extensions')}: {', '.join(missing)}"
                )
        return "\n".join(lines)

    def _update_system_info(self) -> None:
        self.dlg_qm.txt_system_info.setPlainText(self._format_system_info())

    def _multilang_schema_exists(self) -> bool:
        if not tools_db.dao:
            return False
        return admin_catalog.schema_exists("multilang")

    def _update_multilang_tab_visibility(self) -> None:
        """Show Multilang tab only when the multilang schema exists on the connection."""
        tab_widget = self.dlg_qm.tab_update_type
        multilang_exists = self._multilang_schema_exists()

        tab_widget.blockSignals(True)
        try:
            tab_widget.setTabVisible(_MULTILANG_TAB_INDEX, multilang_exists)
            tab_widget.tabBar().setVisible(multilang_exists)
            if not multilang_exists and tab_widget.currentIndex() != _HOT_UPDATE_TAB_INDEX:
                tab_widget.setCurrentIndex(_HOT_UPDATE_TAB_INDEX)
                self._last_tab_index = _HOT_UPDATE_TAB_INDEX
        finally:
            tab_widget.blockSignals(False)

        self._change_action_buttons_visibility()

    def _on_connection_changed(self) -> None:
        connection_name = tools_qt.get_text(
            self.dlg_qm, self.dlg_qm.cmb_connection, return_string_null=False,
        )
        if not connection_name or connection_name == self._active_connection:
            return
        previous = self._active_connection
        self.dlg_qm.setEnabled(False)
        try:
            if not self.admin.reload_connection_for_manage_schemas(connection_name):
                if previous:
                    self.dlg_qm.cmb_connection.blockSignals(True)
                    tools_qt.set_combo_value(self.dlg_qm.cmb_connection, previous, 1)
                    self.dlg_qm.cmb_connection.blockSignals(False)
                return
            self._active_connection = connection_name
            self._selected_schema = ""
            self.dlg_qm.tbl_schemas.clearSelection()
            self._update_system_info()
            self._refresh_schema_table()
        finally:
            self.dlg_qm.setEnabled(True)

    def _ensure_dialog_scroll(self) -> None:
        if self._scroll_area is not None:
            return

        main_layout = self.dlg_qm.verticalLayout
        scroll_area = QScrollArea(self.dlg_qm)
        scroll_area.setWidgetResizable(True)
        scroll_area.setFrameShape(QScrollArea.Shape.NoFrame)
        scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        scroll_area.setVerticalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAsNeeded)
        scroll_area.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)

        content = QWidget()
        content_layout = QVBoxLayout(content)
        content_layout.setContentsMargins(0, 0, 0, 0)
        content_layout.setSpacing(main_layout.spacing())

        while main_layout.count() > 1:
            item = main_layout.takeAt(0)
            if item.widget():
                content_layout.addWidget(item.widget())
            elif item.layout():
                content_layout.addLayout(item.layout())
            elif item.spacerItem():
                content_layout.addItem(item.spacerItem())

        scroll_area.setWidget(content)
        main_layout.insertWidget(0, scroll_area, 1)

        self._scroll_area = scroll_area
        self._scroll_content = content

    def _on_tab_changed(self, index: int) -> None:
        if self._last_tab_index is not None:
            self._tab_heights[self._last_tab_index] = self.dlg_qm.height()
        self._last_tab_index = index
        self._change_action_buttons_visibility()
        if index == _MULTILANG_TAB_INDEX:
            self._refresh_lbl_multilang_language()
        QTimer.singleShot(0, partial(self._apply_dialog_height, prefer_cached=True))

    def _apply_tab_heights(self, tab_index: int | None = None) -> None:
        """Make QTabWidget height follow the active tab content only."""
        tab_widget = self.dlg_qm.tab_update_type
        if tab_index is None:
            tab_index = tab_widget.currentIndex()
        for index in range(tab_widget.count()):
            page = tab_widget.widget(index)
            if index == tab_index:
                page.setSizePolicy(
                    QSizePolicy.Policy.Preferred, QSizePolicy.Policy.Preferred,
                )
            else:
                page.setSizePolicy(
                    QSizePolicy.Policy.Ignored, QSizePolicy.Policy.Ignored,
                )
            page.updateGeometry()
        tab_widget.updateGeometry()

    def _tab_content_height(self, tab_index: int | None = None) -> int:
        tab_widget = self.dlg_qm.tab_update_type
        if tab_index is None:
            tab_index = tab_widget.currentIndex()
        page = tab_widget.widget(tab_index)
        self._apply_tab_heights(tab_index)
        tab_bar_h = 0
        if tab_widget.tabBar().isVisible():
            tab_bar_h = tab_widget.tabBar().sizeHint().height()
        return tab_bar_h + page.sizeHint().height()

    def _content_preferred_height(self, tab_index: int | None = None) -> int:
        layout = self.dlg_qm.verticalLayout
        spacing = layout.spacing()
        return (
            self.dlg_qm.grb_connection.sizeHint().height()
            + spacing
            + self.dlg_qm.grb_schemas.sizeHint().height()
            + spacing
            + self._tab_content_height(tab_index)
        )

    def _fit_dialog_geometry(self, *, prefer_cached: bool = False) -> None:
        """Resize dialog to fit content; optionally restore a tab's remembered height."""
        layout = self.dlg_qm.verticalLayout
        margins = layout.contentsMargins()
        footer_h = self.dlg_qm.lyt_buttons.sizeHint().height()
        current = self.dlg_qm.tab_update_type.currentIndex()

        computed = (
            self._content_preferred_height(current)
            + footer_h
            + margins.top()
            + margins.bottom()
            + layout.spacing()
        )
        computed = max(computed, self.dlg_qm.minimumHeight())

        cached = self._tab_heights.get(current)
        if prefer_cached and cached is not None:
            height = cached
        else:
            height = computed
            self._tab_heights[current] = height

        tab_h = self._tab_content_height(current)
        tab_widget = self.dlg_qm.tab_update_type
        tab_widget.setSizePolicy(QSizePolicy.Policy.Preferred, QSizePolicy.Policy.Fixed)
        tab_widget.setFixedHeight(tab_h)

        width = self.dlg_qm.width()
        self.dlg_qm.setMaximumSize(16777215, 16777215)
        self.dlg_qm.resize(width, height)
        self.dlg_qm.setMaximumHeight(computed)

    def _apply_dialog_height(self, *, prefer_cached: bool = False) -> None:
        self._ensure_dialog_scroll()
        self._fit_dialog_geometry(prefer_cached=prefer_cached)

    def _change_action_buttons_visibility(self) -> None:
        tab_widget = self.dlg_qm.tab_update_type
        on_multilang_tab = (
            tab_widget.currentIndex() == _MULTILANG_TAB_INDEX
            and tab_widget.isTabVisible(_MULTILANG_TAB_INDEX)
        )
        self.dlg_qm.btn_apply.setVisible(on_multilang_tab)
        self.dlg_qm.btn_update.setVisible(not on_multilang_tab)

    def _refresh_lbl_multilang_language(self) -> None:
        language = self._fetch_multilang_language()
        msg = "Multilang language currently used: {0}."
        msg_params = (language.upper(),)
        if language:
            tools_qt.set_widget_text(self.dlg_qm, 'lbl_multilang_language', tools_qt.tr(msg, list_params=msg_params))
        else:
            msg = "Select a schema to see the Multilang language currently used."
            tools_qt.set_widget_text(self.dlg_qm, 'lbl_multilang_language', tools_qt.tr(msg))

    def _select_language_from_table(self, schema_name: str = "") -> str:
        """Return the Language column from the selected schema table row."""
        selection = self.dlg_qm.tbl_schemas.selectionModel()
        if selection is not None:
            indexes = selection.selectedRows()
            if indexes:
                item = self._schema_model.item(indexes[0].row(), _COL_LANGUAGE)
                if item and item.text():
                    return str(item.text())
        if schema_name:
            return self._fetch_schema_language(schema_name)
        return ""

    def _fetch_multilang_language(self) -> str:
        if not tools_db.dao:
            return ""
        schema_name = self._selected_schema_name()

        if not schema_name:
            return ""

        # Display name for the schema's default language (locales.sqlite).
        default_language = self._select_language_from_table(schema_name)
        status, cursor = tools_gw.create_sqlite_conn("locales")
        if status and cursor is not None and default_language:
            cursor.execute(
                "SELECT name FROM locales WHERE locale = ?",
                (default_language,),
            )
            row = cursor.fetchone()
            default_language = str(row[0]) if row and row[0] else default_language

        schema_value = schema_name.replace("'", "''")
        pg_cursor = tools_db.dao.get_cursor()
        sql = f"""SELECT idval
                FROM multilang.cat_language
                WHERE id = (
                    SELECT lower(btrim(value))
                    FROM {schema_value}.config_param_user
                    WHERE parameter = 'multilang_language'
                      AND cur_user = CURRENT_USER
                      AND value IS NOT NULL
                      AND lower(btrim(value)) <> 'default'
                );"""
        pg_cursor.execute(sql)
        row = pg_cursor.fetchone()
        return str(row[0]) if row and row[0] else default_language

    def select_initial_schema(self) -> None:
        if self._selected_schema:
            for row in range(self._schema_model.rowCount()):
                item = self._schema_model.item(row, _COL_SCHEMA)
                if item and item.text() == self._selected_schema:
                    self.dlg_qm.tbl_schemas.selectRow(row)
                    self.dlg_qm.tbl_schemas.scrollTo(self.dlg_qm.tbl_schemas.model().index(row, 0))
                    return
        else:
            self.dlg_qm.tbl_schemas.selectRow(0)

    def _setup_schema_table(self) -> None:
        self.dlg_qm.tbl_schemas.setModel(self._schema_model)
        self.dlg_qm.tbl_schemas.setAlternatingRowColors(True)
        self.dlg_qm.tbl_schemas.setSortingEnabled(True)
        self.dlg_qm.tbl_schemas.verticalHeader().setVisible(False)
        self.dlg_qm.tbl_schemas.setVerticalScrollBarPolicy(
            Qt.ScrollBarPolicy.ScrollBarAsNeeded,
        )
        header = self.dlg_qm.tbl_schemas.horizontalHeader()
        header.setStretchLastSection(False)
        header.setSectionResizeMode(_COL_SCHEMA, QHeaderView.ResizeMode.Stretch)
        for col in (_COL_KIND, _COL_VERSION, _COL_LANGUAGE, _COL_CREATED, _COL_UPDATED):
            header.setSectionResizeMode(col, QHeaderView.ResizeMode.ResizeToContents)
        header.setMinimumSectionSize(48)
        selection = self.dlg_qm.tbl_schemas.selectionModel()
        self.select_initial_schema()
        if selection is not None:
            selection.selectionChanged.connect(partial(self._on_schema_selection_changed))
        self._apply_schema_table_height()
        self._update_schema_label()

    def _clear_admin_callbacks(self, *_args) -> None:
        if getattr(self.admin, "_manage_schemas_update_system_info", None) is self._update_system_info:
            self.admin._manage_schemas_update_system_info = None
        if getattr(self.admin, "dlg_i18n_hot_update", None) is self.dlg_qm:
            self.admin.dlg_i18n_hot_update = None

    def _apply_schema_table_height(self) -> None:
        """Cap the schema table to five visible rows; scroll when there are more."""
        table = self.dlg_qm.tbl_schemas
        row_h = table.verticalHeader().defaultSectionSize()
        visible_rows = _MAX_VISIBLE_SCHEMA_ROWS
        if self._schema_model.rowCount() > 0:
            visible_rows = min(self._schema_model.rowCount(), _MAX_VISIBLE_SCHEMA_ROWS)
            row_h = max(row_h, table.rowHeight(0))
        header_h = table.horizontalHeader().height()
        if header_h <= 0:
            header_h = table.fontMetrics().height() + 10
        frame = table.frameWidth() * 2
        height = header_h + row_h * visible_rows + frame
        table.setFixedHeight(height)
        table.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
        self.dlg_qm.grb_schemas.setSizePolicy(
            QSizePolicy.Policy.Preferred, QSizePolicy.Policy.Fixed,
        )

    def _setup_tables_filter(self) -> None:
        widget = QListWidget()
        list_height = 60
        widget.setObjectName('list_widget')
        widget.setFixedHeight(list_height)
        widget.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)

        completer = QCompleter()
        type_ahead = QLineEdit()
        msg = "Type to search..."
        type_ahead.setPlaceholderText(tools_qt.tr(msg))
        type_ahead.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)

        model = QStandardItemModel()
        completer.activated.connect(
            partial(tools_gw.add_item_multiple_option, completer, widget, type_ahead),
        )
        self.make_list_multiple_option(completer, model, type_ahead, widget)
        type_ahead.textChanged.connect(
            partial(self.make_list_multiple_option, completer, model, type_ahead, widget),
        )
        widget.itemDoubleClicked.connect(partial(tools_gw.delete_item_on_doubleclick, widget))
        widget.model().rowsInserted.connect(partial(self.update_selected_table_dic))

        filter_widget = self.dlg_qm.wgt_tables_filter
        # Clear any designer min/max height so line edit + list are not clipped.
        filter_widget.setMinimumHeight(0)
        filter_widget.setMaximumHeight(16777215)
        filter_widget.setSizePolicy(
            QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed,
        )
        filter_layout = filter_widget.layout()
        if filter_layout is None:
            filter_layout = QVBoxLayout(filter_widget)
            filter_layout.setContentsMargins(0, 0, 0, 0)
            filter_layout.setSpacing(2)
        filter_layout.addWidget(type_ahead)
        filter_layout.addWidget(widget)
        needed_h = (
            type_ahead.sizeHint().height()
            + filter_layout.spacing()
            + list_height
        )
        filter_widget.setFixedHeight(needed_h)
        filter_widget.updateGeometry()

    def _combo_current_locale(self, cmb_language) -> str | None:
        if cmb_language is None or cmb_language.count() <= 0:
            return None
        value = tools_qt.get_combo_value(self.dlg_qm, cmb_language, 0)
        if value in (-1, None, "", "None"):
            return None
        return str(value)

    def _resolve_language_combo_selection(
        self,
        *,
        previous: str | None,
        available_locales: set[str],
    ) -> str | None:
        """Keep current selection when still valid; otherwise QGIS locale, then en_US."""
        if previous and previous not in (-1, "None"):
            previous_norm = normalize_language_folder(str(previous))
            if previous_norm in available_locales:
                return previous_norm
            for locale in available_locales:
                if normalize_language_folder(locale) == previous_norm:
                    return locale
        saved = tools_gw.get_config_parser(
            'i18n_generator', 'qm_lang_language', "user", "session", False,
        )
        if saved:
            saved_norm = normalize_language_folder(str(saved))
            if saved_norm in available_locales:
                return saved_norm
        for candidate in (
            normalize_language_folder(tools_qgis.get_locale()),
            "en_US",
        ):
            if candidate in available_locales:
                return candidate
        return None

    def _populate_language_combo(
        self,
        *,
        mode: str,
        first_insert: bool = False,
        preferred_locale: str | None = None,
    ) -> None:
        if mode == "multilang":
            cmb_language = self.dlg_qm.cmb_language_multilang
            flag = "active_multilang"
            insert_default = True
        else:
            cmb_language = self.dlg_qm.cmb_language_hot_update
            flag = "active"
            insert_default = False

        previous = self._combo_current_locale(cmb_language)
        if preferred_locale:
            previous = normalize_language_folder(preferred_locale)
        elif first_insert and mode != "multilang":
            schema_lang = self._select_language_from_table(self._selected_schema)
            if schema_lang:
                previous = normalize_language_folder(schema_lang)

        language = None
        cmb_language.blockSignals(True)
        try:
            cmb_language.clear()
            rows_raw = i18n_service.list_locales_for_combo(flag=flag)
            if rows_raw is None:
                msg = "Config database file not found"
                tools_qt.set_widget_text(self.dlg_qm, 'lbl_info', msg)
                return
            rows = [[locale, name] for locale, name in rows_raw]
            if not rows:
                msg = "No active locales configured"
                tools_qt.set_widget_text(self.dlg_qm, 'lbl_info', msg)
                return
            if insert_default:
                rows.insert(0, ("Default", "Default"))
            tools_qt.fill_combo_values(cmb_language, rows)

            available_locales = {locale for locale, _name in rows}
            language = self._resolve_language_combo_selection(
                previous=previous,
                available_locales=available_locales,
            )
            if language:
                tools_qt.set_combo_value(cmb_language, language, 0, add_new=False)
        finally:
            cmb_language.blockSignals(False)
        if language and (preferred_locale or first_insert):
            self._save_language_selection(cmb_language)

    def _save_language_selection(self, cmb_language, *_args) -> None:
        language = tools_qt.get_combo_value(self.dlg_qm, cmb_language, 0)
        if language:
            tools_gw.set_config_parser(
                'i18n_generator', 'qm_lang_language', f"{language}",
                "user", "session", prefix=False,
            )

    def _refresh_schema_table(self) -> None:
        previous_schema = self._selected_schema
        self.dlg_qm.btn_refresh.setEnabled(False)
        try:
            update_info = getattr(self.admin, "_manage_schemas_update_system_info", None)
            if update_info:
                update_info()
            else:
                self._update_system_info()
            self.dlg_qm.tbl_schemas.setSortingEnabled(False)
            selection = self.dlg_qm.tbl_schemas.selectionModel()
            if selection is not None:
                selection.blockSignals(True)
            try:
                self._schema_model.removeRows(0, self._schema_model.rowCount())
                self._inventory_rows = admin_catalog.fetch_schema_inventory()
                for row in self._inventory_rows:
                    if row.get("kind") not in _TRANSLATABLE_KINDS:
                        continue
                    language = self._fetch_schema_language(str(row.get("schema") or ""))
                    values = (
                        row.get("schema", ""),
                        row.get("kind", ""),
                        row.get("version", ""),
                        language,
                        row.get("date_created", ""),
                        row.get("date_updated", ""),
                    )
                    items = []
                    for value in values:
                        item = QStandardItem(str(value or ""))
                        item.setEditable(False)
                        items.append(item)
                    self._schema_model.appendRow(items)
            finally:
                if selection is not None:
                    selection.blockSignals(False)
            self.dlg_qm.tbl_schemas.setSortingEnabled(True)
            self._apply_schema_table_height()
            self._update_multilang_tab_visibility()
            self._apply_dialog_height()
            if previous_schema:
                self._select_schema_row(previous_schema)
            if not self._selected_schema_name():
                self.select_initial_schema()
            self._update_schema_label()
        finally:
            self.dlg_qm.btn_refresh.setEnabled(True)

    def _fetch_schema_language(self, schema_name: str) -> str:
        if not schema_name or not tools_db.dao:
            return ""
        sql = (
            f"SELECT language FROM {schema_name}.sys_version "
            "ORDER BY id DESC LIMIT 1"
        )
        row = tools_db.get_row(sql, commit=self.dev_commit)
        if row and row[0]:
            return str(row[0])
        return ""

    def _select_schema_row(self, schema_name: str) -> None:
        for row_idx in range(self._schema_model.rowCount()):
            item = self._schema_model.item(row_idx, _COL_SCHEMA)
            if item and item.text() == schema_name:
                self.dlg_qm.tbl_schemas.selectRow(row_idx)
                self._selected_schema = schema_name
                self._update_schema_label()
                return

    def _update_schema_label(self) -> None:
        schema_name = self._selected_schema_name()
        if not schema_name:
            msg = "Schema: select a row below"
            self.dlg_qm.lbl_schema_selection.setText(tools_qt.tr(msg))
            return
        msg = "Schema: {0}"
        msg_params = (schema_name,)
        self.dlg_qm.lbl_schema_selection.setText(
            tools_qt.tr(msg, list_params=msg_params),
        )

    def _selected_schema_name(self) -> str:
        selection = self.dlg_qm.tbl_schemas.selectionModel()
        if selection is None:
            return ""
        indexes = selection.selectedRows()
        if not indexes:
            return ""
        item = self._schema_model.item(indexes[0].row(), _COL_SCHEMA)
        return item.text() if item else ""

    def _on_schema_selection_changed(self, *_args) -> None:
        self._selected_schema = self._selected_schema_name()
        self._update_schema_label()
        row = admin_catalog.find_inventory_row(
            self._inventory_rows, schema=self._selected_schema,
        )
        if not row:
            return
        kind = str(row.get("kind") or "").lower()
        if kind in self.dbtables_dic or kind in I18N_SCHEMAS:
            self._ensure_dbtables_dic(kind)
            self._tables_project_type = kind

        index = self.dlg_qm.tab_update_type.currentIndex()
        if index == _MULTILANG_TAB_INDEX:
            self._refresh_lbl_multilang_language()

    def _open_manage_language_multilang(self) -> None:
        dlg = getattr(self, 'dlg_multilang_languages', None)
        if dlg is not None and not isdeleted(dlg) and dlg.isVisible():
            tools_gw.focus_open_dialog(dlg)
            return

        dlg = GwI18NMultilangLanguagesDialog(self)
        dlg.init_dialog()
        self.dlg_multilang_languages = dlg

    def _open_manage_language_hot_update(self) -> None:
        dlg = getattr(self, 'dlg_i18n_languages', None)
        if dlg is not None and not isdeleted(dlg) and dlg.isVisible():
            tools_gw.focus_open_dialog(dlg)
            return

        dlg = GwI18NManageLanguagesDialog(self, parent=self.dlg_qm)
        dlg.init_dialog()
        self.dlg_i18n_languages = dlg

    def _selected_schema_row(self) -> dict | None:
        schema_name = self._selected_schema_name()
        if not schema_name:
            return None
        return admin_catalog.find_inventory_row(self._inventory_rows, schema=schema_name)

    def _apply_multilang(self):
        if not self._multilang_schema_exists():
            msg = "Multilang schema is not available on this connection."
            tools_qt.show_info_box(tools_qt.tr(msg))
            return

        row = self._selected_schema_row()
        if not row:
            msg = "Select a schema"
            tools_qt.show_info_box(msg)
            return

        self._save_language_selection(self.dlg_qm.cmb_language_multilang)
        language = tools_qt.get_combo_value(self.dlg_qm, self.dlg_qm.cmb_language_multilang, 0)
        if not language:
            msg = "Select a language"
            tools_qt.show_info_box(msg)
            return

        is_default = str(language).strip().lower() == "default"

        kind = str(row.get("kind") or "").upper()
        schema_name = str(row.get("schema") or "")
        if kind not in _TRANSLATABLE_KINDS:
            msg = "{0}: unsupported type {1}"
            msg_params = (row.get("schema") or "", kind or "?")
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return

        msg = "Apply Multilang translation ({0}) to schema ({1})?"
        title = "Update Multilang translation?"
        msg_params = (language, schema_name)
        if not tools_qt.show_question(msg, title, msg_params=msg_params):
            return

        from .multilang_seed_sql import build_multilang_user_preference_sql

        query = build_multilang_user_preference_sql(
            schema_name,
            language,
            is_default=is_default,
        )

        try:
            cursor = tools_db.dao.get_cursor()
            cursor.execute(query)
            tools_db.dao.commit()
            msg = "{0}: Multilang language preference updated to {1}."
            msg_params = (schema_name, language)
        except Exception as e:
            tools_db.dao.rollback()
            msg = "{0}: Failed to update Multilang language preference: {1}"
            msg_params = (schema_name, str(e))
        finally:
            tools_qt.set_widget_text(self.dlg_qm, 'lbl_info', msg, msg_params=msg_params)
            tools_qt.show_info_box(msg, msg_params=msg_params)
            self._refresh_schema_table()

    def _run_update(self):
        """Apply locally downloaded i18n SQL files to the selected schema."""

        row = self._selected_schema_row()
        if not row:
            msg = "Select a schema"
            tools_qt.show_info_box(msg)
            return

        self._save_language_selection(self.dlg_qm.cmb_language_hot_update)
        self.language = tools_qt.get_combo_value(self.dlg_qm, self.dlg_qm.cmb_language_hot_update, 0)
        if not self.language:
            msg = "Select a language"
            tools_qt.show_info_box(msg)
            return

        kind = str(row.get("kind") or "").upper()
        schema_name = str(row.get("schema") or "")
        if kind not in _TRANSLATABLE_KINDS:
            msg = "{0}: unsupported type {1}"
            msg_params = (schema_name, kind or "?")
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return

        if not self._local_language_files_exist(self.language, kind.lower()):
            msg = "No local SQL files found for language ({0}). Download them first."
            tools_qt.show_info_box(msg, msg_params=(self.language,))
            return

        msg = "Apply translation ({0}) to schema ({1}) using local SQL files?"
        title = "Update translation?"
        msg_params = (self.language, schema_name)
        if not tools_qt.show_question(msg, title, msg_params=msg_params):
            return

        self.cursor_dest = tools_db.dao.get_cursor()
        self.add_tab_data = tools_qt.is_checked(self.dlg_qm, self.dlg_qm.chk_add_tab_data)
        self.project_type = kind.lower()
        self.schema = schema_name
        self._tables_project_type = self.project_type

        self.dlg_qm.setEnabled(False)
        try:
            status_cfg_msg, schema_errors = self._apply_local_sql_files()
            if status_cfg_msg is True:
                self._change_lang(False)
                msg = "{0}: Database translation successful to {1}."
                msg_params = (schema_name, self.language)
            elif status_cfg_msg is False:
                msg = "{0}: Database translation failed."
                msg_params = (schema_name,)
            else:
                msg = "{0}: Database translation canceled."
                msg_params = (schema_name,)
            if schema_errors:
                msg_params = (tools_qt.tr(msg, list_params=msg_params), ', '.join(schema_errors))
                msg = "{0}: Errors: {1}"
        finally:
            self.dlg_qm.setEnabled(True)

        tools_qt.set_widget_text(self.dlg_qm, 'lbl_info', msg, msg_params=msg_params)
        tools_qt.show_info_box(msg, msg_params=msg_params)
        self._refresh_schema_table()

    def make_list_multiple_option(self, completer, model, widget, list_widget):
        if widget is None:
            widget = self.dlg_qm.findChild(QLineEdit)
        if list_widget is None:
            list_widget = self.dlg_qm.findChild(QListWidget, 'list_widget')
        if not widget or not self.dbtables_dic:
            return

        project_type = self._tables_project_type
        if project_type not in self.dbtables_dic:
            project_type = "ws"
        value = widget.text()
        display_list = []
        selected = [list_widget.item(i).text() for i in range(list_widget.count())]
        for table in self.dbtables_dic[project_type]['dbtables']:
            if value and value not in table:
                continue
            if table in selected:
                continue
            display_list.append({"id": table, "idval": table})
        tools_qt.set_completer_object(
            completer, model, widget, sorted(display_list, key=lambda x: x["idval"]),
        )

    def _local_language_files_exist(self, locale: str, kind: str) -> bool:
        folder = _local_i18n_dir(kind, locale)
        if not folder or not os.path.isdir(folder):
            return False
        return any(name.endswith('.sql') for name in os.listdir(folder))

    def _discover_dbtables(self, kind: str, locale: str) -> list[str]:
        i18n_dir = _local_i18n_dir(kind, locale)
        if not i18n_dir or not os.path.isdir(i18n_dir):
            return []
        return sorted(
            os.path.splitext(name)[0]
            for name in os.listdir(i18n_dir)
            if name.endswith('.sql')
        )

    def _ensure_dbtables_dic(self, kind: str) -> None:
        if kind in self.dbtables_dic:
            return
        locale = tools_qt.get_combo_value(self.dlg_qm, self.dlg_qm.cmb_language_hot_update, 0) or "en_US"
        tables = self._discover_dbtables(kind, locale)
        if tables:
            self.dbtables_dic[kind] = {
                "dbtables": tables,
                "project_type": [kind],
            }

    def _resolve_dbtables(self) -> list[str]:
        use_selected = tools_qt.is_checked(self.dlg_qm, self.dlg_qm.chk_use_selected_tables)
        discovered = set(self._discover_dbtables(self.project_type, self.language))

        if use_selected and getattr(self, 'selected_dbtables_dic', None):
            selected = self.selected_dbtables_dic.get(
                self.project_type, {},
            ).get('dbtables')
            if selected:
                return [
                    table for table in selected
                    if table in discovered
                ]

        self._ensure_dbtables_dic(self.project_type)
        preferred = []
        if self.project_type in self.dbtables_dic:
            preferred = self.dbtables_dic[self.project_type]['dbtables']
        elif discovered:
            preferred = sorted(discovered)

        ordered = [table for table in preferred if table in discovered]
        extras = sorted(discovered.difference(ordered))
        return ordered + extras

    @staticmethod
    def _sql_schema_name(schema_name: str) -> str:
        name = str(schema_name or "").replace('"', '').strip()
        if not name:
            return name
        if re.fullmatch(r"[a-z_][a-z0-9_]*", name):
            return name
        escaped = name.replace('"', '""')
        return f'"{escaped}"'

    @staticmethod
    def _last_db_error() -> str:
        err = lib_vars.session_vars.get("last_error")
        if err is None:
            return ""
        pgerror = getattr(err, "pgerror", None)
        if pgerror:
            return str(pgerror).strip()
        diag = getattr(err, "diag", None)
        if diag is not None and getattr(diag, "message_primary", None):
            return str(diag.message_primary).strip()
        return str(err).strip()

    def _apply_local_sql_files(self):
        """Read downloaded .sql files and apply them to the selected schema."""

        dbtables = self._resolve_dbtables()
        if not dbtables:
            folder = _local_i18n_dir(self.project_type, self.language)
            return False, [folder or self.project_type]

        messages = []
        i18n_dir = _local_i18n_dir(self.project_type, self.language)
        if not i18n_dir or not os.path.isdir(i18n_dir):
            messages.append(i18n_dir or self.project_type)
            return False, messages

        for dbtable in dbtables:
            sql_path = os.path.join(i18n_dir, f"{dbtable}.sql")
            if not os.path.isfile(sql_path):
                continue

            msg = "Updating {0}..."
            msg_params = (f"{self.schema}/{dbtable}",)
            tools_qt.set_widget_text(self.dlg_qm, 'lbl_info', msg, msg_params=msg_params)
            ok, error = self._execute_local_sql_file(sql_path, self.schema)
            if not ok:
                detail = error or os.path.basename(sql_path)
                msg = "{0}.sql: {1}"
                msg_params = (dbtable, detail)
                messages.append(tools_qt.tr(msg, list_params=msg_params))
                if not tools_os.set_boolean(self.dev_commit, False):
                    break

        if messages:
            return False, messages
        return True, None

    def _execute_local_sql_file(self, filepath: str, schema_name: str) -> tuple[bool, str]:
        return _execute_i18n_sql_file(
            filepath,
            schema_name,
            add_tab_data=self.add_tab_data,
            dev_commit=self.dev_commit,
        )

    @staticmethod
    def _strip_tab_data_rows(sql: str) -> str:
        """Remove config_form_fields rows for tab_data when the option is unchecked."""
        cleaned_lines = []
        for line in sql.splitlines():
            if _TAB_DATA_LINE_RE.search(line):
                continue
            cleaned_lines.append(line)
        cleaned = "\n".join(cleaned_lines)
        cleaned = re.sub(r",(\s*)\)", r"\1)", cleaned)
        return cleaned

    def _change_lang(self, multilang_exists: bool | None = None) -> None:

        if multilang_exists is None:
            multilang_exists = bool(tools_db.check_schema("multilang"))

        project_type = None
        row = self._selected_schema_row()
        if row:
            project_type = str(row.get("kind") or "").strip().lower() or None
        if not project_type:
            project_type = str(getattr(self, "project_type", "") or "").strip().lower() or None

        query = build_change_lang_sql(
            self.schema,
            self.language,
            multilang_exists=multilang_exists,
            project_type=project_type,
            sql_schema_name=self._sql_schema_name(self.schema),
        )
        try:
            self.cursor_dest.execute(query)
            tools_db.dao.commit()
            tools_qt._add_translator(True)
        except Exception:
            tools_db.dao.rollback()

    def update_selected_table_dic(self):
        if not hasattr(self, 'dlg_qm'):
            return
        list_widget = self.dlg_qm.findChild(QListWidget, 'list_widget')
        org_tables_dic = self.tables_dic()
        if list_widget:
            self.selected_tables = [list_widget.item(i).text() for i in range(list_widget.count())]
            self.selected_dbtables_dic = {
                "ws": {
                    "dbtables": [table for table in self.selected_tables if table in org_tables_dic["ws"]["dbtables"]],
                    "project_type": ["ws", "utils"]
                },
                "ud": {
                    "dbtables": [table for table in self.selected_tables if table in org_tables_dic["ud"]["dbtables"]],
                    "project_type": ["ud", "utils"]
                },
                "am": {
                    "dbtables": [table for table in self.selected_tables if table in org_tables_dic["am"]["dbtables"]],
                    "project_type": ["am"]
                },
                "cm": {
                    "dbtables": [table for table in self.selected_tables if table in org_tables_dic["cm"]["dbtables"]],
                    "project_type": ["cm"]
                },
            }

    @staticmethod
    def tables_dic():
        return {
            "ws": {
                "dbtables": list(_NETWORK_DBTABLES),
                "project_type": ["ws", "utils"],
            },
            "ud": {
                "dbtables": list(_NETWORK_DBTABLES),
                "project_type": ["ud", "utils"],
            },
            "am": {
                "dbtables": ["dbconfig_engine", "dbconfig_form_tableview", "su_basic_tables"],
                "project_type": ["am"]
            },
            "cm": {
                "dbtables": ["dbconfig_form_fields", "dbconfig_form_tabs", "dbconfig_param_system",
                             "dbtypevalue", "dbtable", "dbconfig_form_tableview", "dbfprocess",
                             "dbconfig_form_fields_json", "dbconfig_form_fields_query"],
                "project_type": ["cm"]
            },
        }


def _local_i18n_dir(kind: str, locale: str) -> str:
    schema_path = I18N_SCHEMAS.get(kind)
    if not schema_path:
        return ""
    folder = normalize_language_folder(locale)
    return os.path.join(str(i18n_service.dbmodel_dir()), schema_path, folder)


def _execute_i18n_sql_file(
    filepath: str,
    schema_name: str,
    *,
    add_tab_data: bool,
    dev_commit,
) -> tuple[bool, str]:
    try:
        with open(filepath, encoding='utf-8') as handle:
            sql = handle.read()
    except OSError as exc:
        return False, str(exc)

    sql_schema = GwAdminI18NHotUpdate._sql_schema_name(schema_name)
    sql = sql.replace("SCHEMA_NAME", sql_schema)
    if not add_tab_data and os.path.basename(filepath) in _FORM_FIELDS_SQL:
        sql = GwAdminI18NHotUpdate._strip_tab_data_rows(sql)

    if not sql.strip():
        return True, ""

    ok = tools_db.execute_sql(
        sql,
        filepath=filepath,
        commit=dev_commit,
        is_thread=True,
        show_exception=False,
    )
    if ok:
        return True, ""
    return False, GwAdminI18NHotUpdate._last_db_error() or os.path.basename(filepath)


def apply_schema_hot_update(
    schema_name: str,
    language: str,
    kind: str,
    *,
    add_tab_data: bool = True,
    dev_commit=None,
) -> tuple[bool, list[str] | None]:
    """Apply all local i18n SQL files for language/kind to a schema, then change_lang."""
    kind = str(kind or "").strip().lower()
    i18n_dir = _local_i18n_dir(kind, language)
    if not i18n_dir or not os.path.isdir(i18n_dir):
        return False, [i18n_dir or kind]

    discovered = {
        os.path.splitext(name)[0]
        for name in os.listdir(i18n_dir)
        if name.endswith('.sql')
    }
    if not discovered:
        return False, [i18n_dir]

    preferred = GwAdminI18NHotUpdate.tables_dic().get(kind, {}).get("dbtables", [])
    dbtables = [table for table in preferred if table in discovered]
    dbtables.extend(sorted(discovered.difference(dbtables)))

    messages = []
    for dbtable in dbtables:
        sql_path = os.path.join(i18n_dir, f"{dbtable}.sql")
        if not os.path.isfile(sql_path):
            continue
        ok, error = _execute_i18n_sql_file(
            sql_path, schema_name, add_tab_data=add_tab_data, dev_commit=dev_commit,
        )
        if not ok:
            detail = error or os.path.basename(sql_path)
            msg = "{0}.sql: {1}"
            msg_params = (dbtable, detail)
            messages.append(tools_qt.tr(msg, list_params=msg_params))
            if not tools_os.set_boolean(dev_commit, False):
                break

    if messages:
        return False, messages

    query = build_change_lang_sql(
        schema_name,
        language,
        multilang_exists=False,
        project_type=kind,
        sql_schema_name=GwAdminI18NHotUpdate._sql_schema_name(schema_name),
    )
    try:
        cursor = tools_db.dao.get_cursor()
        cursor.execute(query)
        tools_db.dao.commit()
        tools_qt._add_translator(True)
    except Exception:
        tools_db.dao.rollback()

    return True, None