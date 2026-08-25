"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

Manage Multilang schema languages dialog.

Lists plugin-active locales and seeds/deletes translations in the multilang schema.
"""
# -*- coding: utf-8 -*-
from functools import partial
import os

from qgis.core import QgsApplication

from ...utils import tools_gw
from ....giswater_admin.engine import BuildParams
from ....libs import lib_vars, tools_db, tools_qt
from ...threads.multilang_schema_task import GwMultilangSchemaTask
from .multilang_seed_sql import (
    fetch_seeded_language_ids,
    language_baselines_exist,
    normalize_language_folder,
    normalize_language_id,
)
from .language_packages_dialog import GwI18NLocalesTableBase
from . import language_shared_functions as i18n_service


class GwI18NMultilangLanguagesDialog(GwI18NLocalesTableBase):
    """Seed/update/delete multilang DB translations for installed locales."""

    def __init__(self, parent_manager, parent=None):
        super().__init__(parent_manager, parent=parent)
        self._pending_update = False

    def init_dialog(self):
        """Constructor."""
        tools_gw.load_settings(self)
        self.chk_download_latest.setVisible(False)
        self._setup_table()
        self.load_locales()
        self._apply_filter()
        self._connect_common_signals()
        self._update_action_buttons()
        tools_gw.open_dialog(self, dlg_name='admin_i18n_multilang_languages')
        msg = "Apply to Multilang"
        self.btn_download.setText(tools_qt.tr(msg))

    def _sql_root(self) -> str:
        admin = getattr(self._manager, "admin", None)
        sql_dir = getattr(admin, "sql_dir", None) if admin is not None else None
        if sql_dir:
            return str(sql_dir)
        return os.path.join(lib_vars.plugin_dir, "dbmodel")

    def _refresh_parent_multilang_combo(self, locale: str | None = None) -> None:
        refresh = getattr(self._manager, "_populate_language_combo", None)
        if refresh:
            kwargs = {"mode": "multilang"}
            if locale:
                kwargs["preferred_locale"] = locale
            refresh(**kwargs)

    def _on_download(self) -> None:
        locale = self._require_selected_locale()
        if not locale:
            return
        self._action_seed(locale)

    def _on_update(self) -> None:
        locale = self._require_selected_locale()
        if not locale:
            return

        msg = "Do you want to update multilang translations for ({0})?"
        title = "Update multilang translations?"
        if not tools_qt.show_question(msg, title, msg_params=(locale,)):
            return

        msg = "Updating multilang translations for ({0})..."
        self.lbl_downloading.setText(
            tools_qt.tr(msg, list_params=(locale,))
        )
        self._action_seed(locale, force=True, is_update=True)

    def _on_delete(self) -> None:
        locale = self._require_selected_locale()
        if not locale:
            return
        self._action_delete(locale)

    def _on_double_click(self) -> None:
        locale = self._selected_locale()
        if not locale:
            return
        active, _ = self._selected_locale_active()
        if not active and normalize_language_id(locale) != "en_us":
            self._on_download()

    def _seeded_language_ids(self) -> set[str] | None:
        """Return seeded lang ids from multilang.cat_language, or None if unavailable."""
        try:
            if not tools_db.check_schema("multilang"):
                return None
        except Exception:
            return None

        def _fetcher(sql: str, params=None):
            return tools_db.get_rows(sql)

        try:
            return fetch_seeded_language_ids(_fetcher)
        except Exception:
            return None

    def load_locales(self) -> None:
        """List only languages already downloaded for the plugin (locales.active = 1)."""
        self.possible_locales = []

        db_rows = i18n_service.list_plugin_locales_for_multilang()
        if db_rows is None:
            msg = "Config database file not found"
            tools_qt.show_info_box(msg)
            return

        sql_root = self._sql_root()
        seeded_ids = self._seeded_language_ids()
        active_sync: list[tuple[int, str]] = []

        for locale, name, active_multilang, version in db_rows:
            # Bundled en_US is always available; other locales need local baseline SQL.
            is_en_us = normalize_language_id(locale) == "en_us"
            if not is_en_us and not language_baselines_exist(sql_root, locale):
                continue

            display_name = name or locale
            lang_id = normalize_language_id(locale)
            if seeded_ids is None:
                active = bool(active_multilang)
            else:
                active = lang_id in seeded_ids or is_en_us
                if bool(active_multilang) != active:
                    active_sync.append((1 if active else 0, locale))
            if is_en_us:
                active = True
            self.possible_locales.append((locale, display_name, active, version))

        # Ensure en_US is listed even if missing from sqlite.
        if not any(normalize_language_id(loc) == "en_us" for loc, *_ in self.possible_locales):
            self.possible_locales.insert(0, ("en_US", "English (United States)", True, None))

        if active_sync:
            i18n_service.update_active_multilang_flags(active_sync)

    def _set_locale_active(
        self,
        locale: str,
        active: bool,
        version: str | None = None,
    ) -> bool:
        del version  # Multilang flag has no package version column update.
        ok = i18n_service.set_locale_active_multilang(
            locale, active, name=self._locale_display_name(locale),
        )
        if not ok:
            msg = "Config database file not found"
            tools_qt.show_info_box(msg)
        return ok

    def _action_seed(
        self,
        locale: str,
        *,
        force: bool = False,
        is_update: bool = False,
    ) -> None:
        if locale in self._busy_locales:
            return

        if not force and not is_update:
            msg = "Do you want to seed multilang translations for ({0})?"
            title = "Seed multilang translations?"
            if not tools_qt.show_question(msg, title, msg_params=(locale,)):
                return

        sql_root = self._sql_root()
        if not language_baselines_exist(sql_root, locale):
            folder = normalize_language_folder(locale)
            msg = "No local i18n baseline SQL found for ({0}). Download plugin language files first."
            tools_qt.show_info_box(msg, msg_params=(folder,))
            return

        if not self._begin_busy(locale):
            return
        if is_update:
            msg = "Updating multilang translations for ({0})..."
        else:
            msg = "Seeding multilang translations for ({0})..."
        self.lbl_downloading.setText(tools_qt.tr(msg, list_params=(locale,)))
        self._pending_update = is_update

        admin = getattr(self._manager, "admin", None)
        params = BuildParams(
            schema_name="multilang",
            locale=normalize_language_folder(locale),
            sql_root=sql_root,
            plugin_version=str(getattr(admin, "plugin_version", "0.0.0") or "0.0.0"),
            srid=str(getattr(admin, "project_epsg", None) or "25831"),
        )
        if is_update:
            msg = "Update multilang translations for ({0})"
        else:
            msg = "Seed multilang translations for ({0})"
        desc = tools_qt.tr(msg, list_params=(locale,))
        task = GwMultilangSchemaTask(
            admin,
            params,
            description=desc,
            language_action="seed",
            locale=locale,
        )
        task.task_finished.connect(partial(self._on_seed_finished, force))
        self._language_task = task
        QgsApplication.taskManager().addTask(task)
        QgsApplication.taskManager().triggerTask(task)

    def _action_delete(self, locale: str, force: bool = False) -> None:
        if locale in self._busy_locales:
            return
        if normalize_language_id(locale) == "en_us":
            msg = "The base language (en_US) cannot be deleted."
            tools_qt.show_info_box(msg)
            return

        if not force:
            usages = i18n_service.find_locale_usages(locale, include_multilang=False)
            if usages:
                msg = "Language ({0}) is in use and cannot be deleted. Used by: {1}"
                tools_qt.show_warning_box(msg, msg_params=(locale, ", ".join(usages)))
                return

        msg = "Delete multilang translations for ({0})?"
        title = "Delete multilang translations"
        if not force and not tools_qt.show_question(msg, title, msg_params=(locale,)):
            return

        if not self._begin_busy(locale):
            return
        msg = "Deleting multilang translations for ({0})..."
        self.lbl_downloading.setText(
            tools_qt.tr(msg, list_params=(locale,))
        )
        self._pending_update = False

        admin = getattr(self._manager, "admin", None)
        params = BuildParams(
            schema_name="multilang",
            locale=normalize_language_folder(locale),
            sql_root=self._sql_root(),
            plugin_version=str(getattr(admin, "plugin_version", "0.0.0") or "0.0.0"),
            srid=str(getattr(admin, "project_epsg", None) or "25831"),
        )
        msg = "Delete multilang translations for ({0})"
        desc = tools_qt.tr(msg, list_params=(locale,))
        task = GwMultilangSchemaTask(
            admin,
            params,
            description=desc,
            language_action="delete",
            locale=locale,
        )
        task.task_finished.connect(partial(self._on_delete_finished, force))
        self._language_task = task
        QgsApplication.taskManager().addTask(task)
        QgsApplication.taskManager().triggerTask(task)

    def _on_seed_finished(self, force, ok, locale, error):
        self.lbl_downloading.setText("")
        self._end_busy(locale)
        was_update = self._pending_update
        self._pending_update = False

        if not ok:
            msg = "Could not seed multilang translations ({0}): {1}"
            msg_params = (locale, error or "unknown error")
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return

        if not self._set_locale_active(locale, True):
            return
        self._update_locale_state(locale, active=True, version=None)
        self._refresh_parent_multilang_combo(locale)
        if not force:
            msg = "Multilang translations seeded and locale activated ({0})."
            tools_qt.show_info_box(msg, msg_params=(locale,))
        elif was_update:
            msg = "Multilang translations updated ({0})."
            tools_qt.show_info_box(msg, msg_params=(locale,))

    def _on_delete_finished(self, force, ok, locale, error):
        self.lbl_downloading.setText("")
        self._end_busy(locale)

        if not ok:
            msg = "Could not delete multilang translations ({0}): {1}"
            msg_params = (locale, error or "unknown error")
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return

        if not self._set_locale_active(locale, False):
            return
        self._update_locale_state(locale, active=False, version=None)
        self._refresh_parent_multilang_combo()
        if not force:
            msg = "Multilang translations deleted and locale deactivated ({0})."
            tools_qt.show_info_box(msg, msg_params=(locale,))
