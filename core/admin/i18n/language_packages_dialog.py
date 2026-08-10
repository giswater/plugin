"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

Local language-package management dialog and shared locale-table UI base.

Also hosts ``GwDownloadLanguageTask``, used only by this dialog.
"""
# -*- coding: utf-8 -*-
from functools import partial
import urllib.error

from qgis.core import QgsApplication
from qgis.PyQt.QtCore import QEvent, Qt, pyqtSignal
from qgis.PyQt.QtGui import QStandardItem, QStandardItemModel
from qgis.PyQt.QtWidgets import (
    QHeaderView, QAbstractItemView,
)

from ...ui.ui_manager import GwI18NManageLanguagesUi
from ...utils import tools_gw
from ....libs import lib_vars, tools_qt
from .multilang_seed_sql import normalize_language_folder
from . import language_shared_functions as i18n_service
from ...threads.task import GwTask


_LOCALE_COLUMNS = ("Active", "Locale", "Name")
_COL_ACTIVE = 0
_COL_LOCALE = 1
_COL_NAME = 2
_COL_VERSION = 3


class GwDownloadLanguageTask(GwTask):
    """Download one locale's plugin translation files off the network."""

    task_finished = pyqtSignal(bool, str, str, str)  # ok, locale, schema, error

    def __init__(self, locale: str, *, use_latest: bool = False):
        super().__init__(f"Download language files for {locale}")
        self.use_aux_conn = False
        self.locale = locale
        self.use_latest = use_latest
        self.failed_schema = None
        self.error = None

    def run(self) -> bool:
        super().run()
        try:
            if self.isCanceled():
                return False

            self.setProgress(10)
            ok, schema, error = i18n_service.download_language_files(
                self.locale,
                use_latest=self.use_latest,
                available_versions=i18n_service.get_available_versions(),
            )
            if not ok:
                self.failed_schema = schema
                self.error = error or "Could not download language files"
                return False

            self.setProgress(100)
            return True
        except Exception as exc:
            self.exception = exc
            return False

    def finished(self, result: bool) -> None:
        super().finished(result)
        self.setProgress(100)
        self.task_finished.emit(
            bool(result),
            self.locale,
            self.failed_schema or "",
            self.error or "",
        )


class GwI18NLocalesTableBase(GwI18NManageLanguagesUi):
    """Shared locale table, filter, selection, busy-lock and action-button helpers."""

    def __init__(self, parent_manager, parent=None):
        super().__init__(parent_manager, parent=parent)
        self._manager = parent_manager
        self.possible_locales: list[tuple[str, str, bool, str | None]] = []
        self._busy_locales = set()
        self._advanced_user = None

        columns = list(_LOCALE_COLUMNS)
        if self._is_advanced_user():
            columns.append("Version")
            self._col_version = len(columns) - 1
        else:
            self._col_version = None

        self._locales_model = QStandardItemModel(0, len(columns), self)
        self._locales_model.setHorizontalHeaderLabels(columns)

    def _is_advanced_user(self) -> bool:
        if self._advanced_user is not None:
            return self._advanced_user

        allowed_levels = lib_vars.user_level.get('showadminadvanced')
        if allowed_levels is None:
            allowed_levels = tools_gw.get_config_parser(
                'user_level', 'showadminadvanced', "user", "init", False,
            )
            lib_vars.user_level['showadminadvanced'] = allowed_levels

        user_level = lib_vars.user_level.get('level')
        if user_level in (None, "None"):
            user_level = tools_gw.get_config_parser('user_level', 'level', "user", "init", False)
            lib_vars.user_level['level'] = user_level

        if not allowed_levels or user_level in (None, "None"):
            self._advanced_user = False
        else:
            self._advanced_user = str(user_level) in str(allowed_levels)
        return self._advanced_user

    def _selected_text(self, column: int) -> str:
        selection = self.tbl_locales.selectionModel()
        if selection is None:
            return ""
        indexes = selection.selectedRows(column)
        if not indexes:
            return ""
        item = self._locales_model.item(indexes[0].row(), column)
        return item.text() if item else ""

    def _selected_locale(self) -> str:
        return self._selected_text(_COL_LOCALE)

    def _selected_language(self) -> str:
        return self._selected_text(_COL_NAME)

    def _require_selected_locale(self) -> str:
        locale = self._selected_locale()
        if not locale:
            msg = "Select a locale"
            tools_qt.show_info_box(msg)
        return locale

    def _selected_locale_active(self) -> tuple[bool | None, str | None]:
        locale = self._selected_locale()
        if not locale:
            return None, None
        for loc, _name, active, _version in self.possible_locales:
            if loc == locale:
                return active, locale
        return False, None

    def _setup_table(self) -> None:
        self.tbl_locales.setModel(self._locales_model)
        self.tbl_locales.setAlternatingRowColors(True)
        self.tbl_locales.setSortingEnabled(True)
        self.tbl_locales.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        self.tbl_locales.verticalHeader().setVisible(False)

        header = self.tbl_locales.horizontalHeader()
        header.setStretchLastSection(False)
        header.setSectionResizeMode(_COL_ACTIVE, QHeaderView.ResizeMode.ResizeToContents)
        header.setSectionResizeMode(_COL_LOCALE, QHeaderView.ResizeMode.ResizeToContents)
        header.setSectionResizeMode(_COL_NAME, QHeaderView.ResizeMode.Stretch)
        if self._col_version is not None:
            header.setSectionResizeMode(_COL_VERSION, QHeaderView.ResizeMode.ResizeToContents)
            header.resizeSection(_COL_VERSION, 72)
        header.setMinimumSectionSize(48)
        self.tbl_locales.viewport().installEventFilter(self)

    def eventFilter(self, watched, event):
        if watched is self.tbl_locales.viewport():
            if (
                event.type() == QEvent.Type.MouseButtonPress
                and event.button() == Qt.MouseButton.LeftButton
            ):
                index = self.tbl_locales.indexAt(event.pos())
                if index.isValid():
                    selection = self.tbl_locales.selectionModel()
                    if selection is not None and selection.isSelected(index):
                        selection.clearSelection()
                        return True
        return super().eventFilter(watched, event)

    def _connect_common_signals(self) -> None:
        self.txt_filter.textChanged.connect(partial(self._apply_filter))
        selection = self.tbl_locales.selectionModel()
        if selection is not None:
            selection.selectionChanged.connect(partial(self._update_action_buttons))
        self.btn_close.clicked.connect(partial(tools_gw.close_dialog, self))
        self.btn_delete.clicked.connect(partial(self._on_delete))
        self.btn_download.clicked.connect(partial(self._on_download))
        self.btn_update.clicked.connect(partial(self._on_update))
        self.tbl_locales.doubleClicked.connect(partial(self._on_double_click))

    def closeEvent(self, event):
        if self._busy_locales:
            event.ignore()
            return
        super().closeEvent(event)

    def _begin_busy(self, locale: str) -> bool:
        if locale in self._busy_locales:
            return False
        self._busy_locales.add(locale)
        self.setEnabled(False)
        return True

    def _end_busy(self, locale: str) -> None:
        self._busy_locales.discard(locale)
        self.setEnabled(True)

    def _run_locale_action(self, locale: str, action) -> None:
        if not self._begin_busy(locale):
            return
        try:
            action()
        finally:
            self._end_busy(locale)

    def _hide_action_buttons(self) -> None:
        self.btn_download.setVisible(False)
        self.btn_update.setVisible(False)
        self.btn_delete.setVisible(False)

    def _is_dialog_offline(self) -> bool:
        return False

    def _update_action_buttons(self) -> None:
        active, locale = self._selected_locale_active()
        language = self._selected_language()
        if active is None:
            msg = "Select a language to manage"
            self.lbl_language.setText(tools_qt.tr(msg))
            self._hide_action_buttons()
            return

        msg = "Language: {0}"
        msg_params = (language,)
        self.lbl_language.setText(tools_qt.tr(msg, list_params=msg_params))

        if self._is_dialog_offline():
            self._hide_action_buttons()
            return

        if i18n_service.is_no_translation_locale(locale):
            self.btn_download.setVisible(False)
            self.btn_update.setVisible(True)
            self.btn_delete.setVisible(False)
            return

        self.btn_download.setVisible(not active)
        self.btn_update.setVisible(active)
        self.btn_delete.setVisible(active)

    def _apply_filter(self, *_args) -> None:
        needle = tools_qt.get_text(self, self.txt_filter, return_string_null=False).strip().lower()
        self._locales_model.removeRows(0, self._locales_model.rowCount())
        item_flags = Qt.ItemFlag.ItemIsEnabled | Qt.ItemFlag.ItemIsSelectable
        for locale, name, active, version in self.possible_locales:
            if needle and needle not in locale.lower() and needle not in name.lower():
                continue
            cells = [
                QStandardItem("✓" if active else ""),
                QStandardItem(locale),
                QStandardItem(name),
            ]
            cells[0].setTextAlignment(Qt.AlignmentFlag.AlignCenter)
            for item in cells:
                item.setFlags(item_flags)
            if self._col_version is not None:
                version_item = QStandardItem(version or "")
                version_item.setFlags(item_flags)
                cells.append(version_item)
            self._locales_model.appendRow(cells)
        self._update_action_buttons()

    def _update_locale_state(self, locale: str, active: bool, version: str | None) -> None:
        for index, (loc, name, _active, _prev_version) in enumerate(self.possible_locales):
            if loc == locale:
                keep_version = version if version is not None else _prev_version
                self.possible_locales[index] = (loc, name, active, keep_version)
                break
        self._apply_filter()

    def _locale_display_name(self, locale: str) -> str:
        for loc, locale_name, _active, _version in self.possible_locales:
            if loc == locale:
                return locale_name
        return locale

    def _on_download(self) -> None:
        raise NotImplementedError

    def _on_update(self) -> None:
        raise NotImplementedError

    def _on_delete(self) -> None:
        raise NotImplementedError

    def _on_double_click(self) -> None:
        raise NotImplementedError


class GwI18NManageLanguagesDialog(GwI18NLocalesTableBase):
    """Manage downloaded plugin language packages (GitHub ZIP files)."""

    def closeEvent(self, event):
        if self._busy_locales:
            event.ignore()
            return
        self._save_download_options()
        super(GwI18NLocalesTableBase, self).closeEvent(event)

    def init_dialog(self):
        """Constructor."""
        tools_gw.load_settings(self)
        self._offline = False
        self._setup_table()
        self._setup_download_options()
        self.load_locales()
        self._apply_filter()
        self._set_signals()
        self._update_action_buttons()
        tools_gw.open_dialog(self, dlg_name='admin_i18n_languages')

    def _set_signals(self) -> None:
        self._connect_common_signals()
        if self._is_advanced_user():
            self.chk_download_latest.stateChanged.connect(partial(self._save_download_options))

    def _setup_download_options(self) -> None:
        advanced = self._is_advanced_user()
        self.chk_download_latest.setVisible(advanced)
        if not advanced:
            return
        value = tools_gw.get_config_parser(
            'i18n_languages', 'chk_download_latest', "user", "init", False,
        )
        if value is not None:
            tools_qt.set_checked(self, 'chk_download_latest', value)

    def _save_download_options(self, *_args) -> None:
        if not self._is_advanced_user():
            return
        checked = tools_qt.is_checked(self, 'chk_download_latest')
        tools_gw.set_config_parser(
            'i18n_languages', 'chk_download_latest', f"{checked}",
            "user", "init", prefix=False,
        )

    def _use_latest_translation(self) -> bool:
        return (
            self._is_advanced_user()
            and self.chk_download_latest.isVisible()
            and tools_qt.is_checked(self, 'chk_download_latest')
        )

    def _is_dialog_offline(self) -> bool:
        return bool(getattr(self, "_offline", False))

    def _refresh_manager_language_combos(self) -> None:
        if hasattr(self._manager, "_populate_language_combo"):
            self._manager._populate_language_combo(mode="hot_update")
        if hasattr(self._manager, "_populate_language_combo_create_project"):
            self._manager._populate_language_combo_create_project()

    def _on_download(self) -> None:
        locale = self._require_selected_locale()
        if not locale:
            msg = "Select a language"
            tools_qt.show_info_box(msg)
            return
        self._action_download(locale)

    def _on_update(self) -> None:
        locale = self._require_selected_locale()
        if not locale:
            msg = "Select a language"
            tools_qt.show_info_box(msg)
            return

        msg = "Do you want to update local language files for ({0})?"
        title = "Update language files?"
        msg_params = (locale,)
        if not tools_qt.show_question(msg, title, msg_params=msg_params):
            return

        msg = "Updating language files for ({0})..."
        msg_params = (locale,)
        self.lbl_downloading.setText(tools_qt.tr(msg, list_params=msg_params))

        self._action_delete(locale, force=True)
        self._action_download(locale, force=True)

    def _on_delete(self) -> None:
        locale = self._require_selected_locale()
        if not locale:
            msg = "Select a language"
            tools_qt.show_info_box(msg)
            return
        self._action_delete(locale)

    def _on_double_click(self) -> None:
        locale = self._selected_locale()
        if not locale:
            return
        if not i18n_service.language_files_exist(locale):
            self._on_download()

    def load_locales(self) -> None:
        self.possible_locales = []
        self._offline = False

        api_names: dict[str, str] = {}
        try:
            languages = i18n_service.fetch_languages()
            if isinstance(languages, dict):
                for locale, name in languages.items():
                    folder = normalize_language_folder(locale)
                    if folder:
                        api_names[folder] = name
        except (urllib.error.URLError, urllib.error.HTTPError, OSError, ValueError):
            self._offline = True

        downloaded_locales = i18n_service.reconcile_downloaded_locales(api_names)
        if downloaded_locales is None:
            msg = "Config database file not found"
            tools_qt.show_info_box(msg)
            return

        for locale, (name, version) in downloaded_locales.items():
            self.possible_locales.append((locale, name, True, version))

        for locale, name in api_names.items():
            if locale not in downloaded_locales:
                self.possible_locales.append((locale, name, False, None))

        if self._offline:
            msg = (
                "Could not reach the translations server. "
                "Showing downloaded languages only."
            )
            tools_qt.show_warning_box(msg)

    def _set_locale_active(
        self,
        locale: str,
        active: bool,
        version: str | None = None,
    ) -> bool:
        ok = i18n_service.set_locale_active(
            locale, active, version=version, name=self._locale_display_name(locale),
        )
        if not ok:
            msg = "Config database file not found"
            tools_qt.show_info_box(msg)
        return ok

    def _action_download(self, locale: str, force: bool = False) -> None:
        if locale in self._busy_locales:
            return
        msg = "Do you want to download local language files for ({0})?"
        title = "Download language files?"
        msg_params = (locale,)
        if not force and not tools_qt.show_question(msg, title, msg_params=msg_params):
            return

        if not self._begin_busy(locale):
            return
        msg = "Downloading language files for ({0})..."
        msg_params = (locale,)
        self.lbl_downloading.setText(tools_qt.tr(msg, list_params=msg_params))

        task = GwDownloadLanguageTask(locale, use_latest=self._use_latest_translation())
        task.task_finished.connect(partial(self._on_download_finished, force))
        self._download_task = task
        QgsApplication.taskManager().addTask(task)

    def _action_delete(self, locale: str, force: bool = False) -> None:
        def _delete() -> None:
            if not force:
                usages = i18n_service.find_locale_usages(locale)
                if usages:
                    msg = "Language ({0}) is in use and cannot be deleted. Used by: {1}"
                    msg_params = (locale, ", ".join(usages))
                    tools_qt.show_warning_box(msg, msg_params=msg_params)
                    return
            msg = "Do you want to delete local language files for ({0})?"
            msg_params = (locale,)
            title = "Delete language files?"
            if not force and not tools_qt.show_question(msg, title, msg_params=msg_params):
                return
            ok, error = i18n_service.delete_language_files(locale)
            if not ok:
                msg = "Could not delete language files ({0}): {1}"
                msg_params = (locale, error or "unknown error")
                tools_qt.show_info_box(msg, msg_params=msg_params)
                return

            if not force:
                if not self._set_locale_active(locale, False):
                    return
                self._update_locale_state(locale, active=False, version=None)
                self._refresh_manager_language_combos()
                msg = "Language files deleted and locale deactivated ({0})."
                msg_params = (locale,)
                tools_qt.show_info_box(msg, msg_params=msg_params)

        self._run_locale_action(locale, _delete)

    def _on_download_finished(self, force, ok, locale, schema, error):
        self.lbl_downloading.setText("")
        self._end_busy(locale)

        if not ok:
            msg = "Could not download language files ({0}): {1}"
            msg_params = (locale, error or "unknown error")
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return

        version = i18n_service.translation_version_label(
            use_latest=self._use_latest_translation(),
            available_versions=i18n_service.get_available_versions(),
        )
        if not self._set_locale_active(locale, True, version=version):
            return
        self._update_locale_state(locale, active=True, version=version)
        self._refresh_manager_language_combos()

        if not force:
            msg = "Language files downloaded and locale activated ({0})."
            msg_params = (locale,)
            tools_qt.show_info_box(msg, msg_params=msg_params)
        else:
            msg = "Language files updated and locale activated ({0})."
            msg_params = (locale,)
            tools_qt.show_info_box(msg, msg_params=msg_params)
