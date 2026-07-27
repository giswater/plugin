"""
Manage Multilang schema languages dialog.

Lists plugin-active locales and seeds/deletes translations in the multilang schema.
"""
# -*- coding: utf-8 -*-
from functools import partial
import os

from qgis.core import QgsApplication

from ..utils import tools_gw
from ...giswater_admin.engine import BuildParams
from ...libs import lib_vars, tools_db, tools_qt
from ..threads.multilang_schema_task import GwMultilangSchemaTask
from .i18n_baseline_seed import (
    fetch_seeded_language_ids,
    language_baselines_exist,
    normalize_language_folder,
    normalize_language_id,
)
from .i18n_languages import GwI18NLocalesTableBase


class GwI18NMultilangLanguagesDialog(GwI18NLocalesTableBase):
    """Seed/update/delete multilang DB translations for installed locales."""

    def __init__(self, parent_manager, parent=None):
        super().__init__(parent_manager, parent=parent)
        self._pending_update = False

    def closeEvent(self, event):
        if getattr(self, "_busy_locales", None):
            event.ignore()
            return
        super().closeEvent(event)

    def init_dialog(self):
        """Constructor."""
        tools_gw.load_settings(self)
        self.chk_download_latest.setVisible(False)
        self._setup_table()
        self.load_locales()
        self._apply_filter()
        self._set_signals()
        self._update_action_buttons()
        tools_gw.open_dialog(self, dlg_name='admin_i18n_multilang_languages')

    def _set_signals(self) -> None:
        self.txt_filter.textChanged.connect(partial(self._apply_filter))
        selection = self.tbl_locales.selectionModel()
        if selection is not None:
            selection.selectionChanged.connect(partial(self._update_action_buttons))
        self.btn_close.clicked.connect(partial(tools_gw.close_dialog, self))
        self.btn_delete.clicked.connect(partial(self._on_delete))
        self.btn_download.clicked.connect(partial(self._on_download))
        self.btn_update.clicked.connect(partial(self._on_update))
        self.tbl_locales.doubleClicked.connect(partial(self._on_double_click))

    def _sql_root(self) -> str:
        admin = getattr(self._manager, "admin", None)
        sql_dir = getattr(admin, "sql_dir", None) if admin is not None else None
        if sql_dir:
            return str(sql_dir)
        return os.path.join(lib_vars.plugin_dir, "dbmodel")

    def _update_action_buttons(self) -> None:
        active, locale = self._selected_locale_active()
        language = self._selected_language()
        if active is None:
            self.lbl_language.setText("Select a language to manage")
            self.btn_download.setVisible(False)
            self.btn_update.setVisible(False)
            self.btn_delete.setVisible(False)
            return

        self.lbl_language.setText(f"Language: {language}")

        if locale.lower() == "en_us":
            self.btn_download.setVisible(False)
            self.btn_update.setVisible(True)
            self.btn_delete.setVisible(False)
            return

        self.btn_download.setVisible(not active)
        self.btn_update.setVisible(active)
        self.btn_delete.setVisible(active)

    def _refresh_parent_multilang_combo(self) -> None:
        refresh = getattr(self._manager, "_populate_language_combo", None)
        if refresh:
            refresh(mode="multilang")

    def _on_download(self) -> None:
        locale = self._selected_locale()
        if not locale:
            msg = "Select a locale"
            tools_qt.show_info_box(msg)
            return
        self._action_seed(locale)

    def _on_update(self) -> None:
        locale = self._selected_locale()
        if not locale:
            msg = "Select a locale"
            tools_qt.show_info_box(msg)
            return

        msg = "Do you want to update multilang translations for ({0})?"
        title = "Update multilang translations?"
        if not tools_qt.show_question(msg, title, msg_params=(locale,)):
            return

        self.lbl_downloading.setText(
            tools_qt.tr("Updating multilang translations for ({0})...", list_params=(locale,))
        )
        self._action_seed(locale, force=True, is_update=True)

    def _on_delete(self) -> None:
        locale = self._selected_locale()
        if not locale:
            msg = "Select a locale"
            tools_qt.show_info_box(msg)
            return
        self._action_delete(locale)

    def _on_double_click(self) -> None:
        locale = self._selected_locale()
        if not locale:
            return
        active, _ = self._selected_locale_active()
        if not active and locale.lower() != "en_us":
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

        status, cursor = tools_gw.create_sqlite_conn("config")
        if not status or cursor is None:
            msg = "Config database file not found"
            tools_qt.show_info_box(msg)
            return

        cursor.execute(
            "SELECT locale, name, active_multilang, version FROM locales "
            "WHERE id IN ("
            "  SELECT MIN(id) FROM locales "
            "  WHERE active = 1 OR lower(locale) = 'en_us' "
            "  GROUP BY locale"
            ") ORDER BY name"
        )
        db_rows = cursor.fetchall()
        sql_root = self._sql_root()
        seeded_ids = self._seeded_language_ids()
        active_sync: list[tuple[int, str]] = []

        for locale, name, active_multilang, version in db_rows:
            # Bundled en_US is always available; other locales need local baseline SQL.
            if locale.lower() != "en_us" and not language_baselines_exist(sql_root, locale):
                continue

            display_name = name or locale
            lang_id = normalize_language_id(locale)
            if seeded_ids is None:
                active = bool(active_multilang)
            else:
                active = lang_id in seeded_ids or locale.lower() == "en_us"
                if bool(active_multilang) != active:
                    active_sync.append((1 if active else 0, locale))
            if locale.lower() == "en_us":
                active = True
            self.possible_locales.append((locale, display_name, active, version))

        # Ensure en_US is listed even if missing from sqlite.
        if not any(loc.lower() == "en_us" for loc, *_ in self.possible_locales):
            self.possible_locales.insert(0, ("en_US", "English (United States)", True, None))

        if active_sync:
            cursor.executemany(
                "UPDATE locales SET active_multilang = ? WHERE locale = ?",
                active_sync,
            )
        cursor.connection.commit()

    def _set_locale_active(
        self,
        locale: str,
        active: bool,
        version: str | None = None,
    ) -> bool:
        status, cursor = tools_gw.create_sqlite_conn("config")
        if not status or cursor is None:
            msg = "Config database file not found"
            tools_qt.show_info_box(msg)
            return False
        cursor.execute("SELECT 1 FROM locales WHERE locale = ?", (locale,))
        if cursor.fetchone():
            cursor.execute(
                "UPDATE locales SET active_multilang = ? WHERE locale = ?",
                (1 if active else 0, locale),
            )
        else:
            name = locale
            for loc, locale_name, _active, _version in self.possible_locales:
                if loc == locale:
                    name = locale_name
                    break
            cursor.execute(
                "INSERT INTO locales (locale, name, active, version, active_multilang) "
                "VALUES (?, ?, 0, NULL, ?) "
                "ON CONFLICT (locale) DO UPDATE SET "
                "name = excluded.name, active = excluded.active, "
                "version = excluded.version, active_multilang = excluded.active_multilang",
                (locale, name, 1 if active else 0),
            )
        cursor.connection.commit()
        return True

    def _update_locale_state(self, locale: str, active: bool, version: str | None) -> None:
        for index, (loc, name, _active, _prev_version) in enumerate(self.possible_locales):
            if loc == locale:
                keep_version = version if version is not None else _prev_version
                if not active:
                    keep_version = _prev_version
                self.possible_locales[index] = (loc, name, active, keep_version)
                break
        self._apply_filter()

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
            msg_params = (folder,)
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return

        self._busy_locales.add(locale)
        self.setEnabled(False)
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
        if locale.lower() == "en_us":
            msg = "The base language (en_US) cannot be deleted."
            tools_qt.show_info_box(msg)
            return

        msg = "Delete multilang translations for ({0})?"
        title = "Delete multilang translations"
        if not force and not tools_qt.show_question(msg, title, msg_params=(locale,)):
            return

        self._busy_locales.add(locale)
        self.setEnabled(False)
        msg = "Delete multilang translations for ({0})?"
        msg_params = (locale,)
        self.lbl_downloading.setText(
            tools_qt.tr(msg, list_params=msg_params)
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
        msg = "Delete multilang translations for ({0})?"
        msg_params = (locale,)
        desc = tools_qt.tr(msg, list_params=msg_params)
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
        self._busy_locales.discard(locale)
        self.setEnabled(True)
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
        self._refresh_parent_multilang_combo()
        if not force:
            msg = "Multilang translations seeded and locale activated ({0})."
            msg_params = (locale,)
            tools_qt.show_info_box(msg, msg_params=msg_params)
        elif was_update:
            msg = "Multilang translations updated ({0})."
            msg_params = (locale,)
            tools_qt.show_info_box(msg, msg_params=msg_params)

    def _on_delete_finished(self, force, ok, locale, error):
        self.lbl_downloading.setText("")
        self._busy_locales.discard(locale)
        self.setEnabled(True)

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
            msg_params = (locale,)
            tools_qt.show_info_box(msg, msg_params=msg_params)
