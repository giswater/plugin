"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

i18n file generator: reads the ``i18n`` PostgreSQL schema and writes
``.ts``/``.qm`` files and ``.sql`` patches into the plugin tree.

File layout
-----------
1. Constants and table catalog
2. Utilities (files, JSON, ordering)
3. Translation resolution and form JSON
4. GwI18NGenerator — Qt dialog and orchestration
   · UI and option persistence
   · Export run (Translate button)
   · Database connection
   · Qt export (.ts)
   · SQL export
"""
# -*- coding: utf-8 -*-
import io
import os
import re
import shutil
import subprocess
from functools import partial
import json
from collections import defaultdict
from xml.sax.saxutils import escape as xml_escape

import psycopg2
import psycopg2.extras

from ..ui.ui_manager import GwAdminTranslationUi
from ..utils import tools_gw
from ...libs import lib_vars, tools_qt, tools_log

from qgis.PyQt.QtWidgets import QApplication


# =============================================================================
# 1. CONSTANTS
# =============================================================================

SCHEMA_I18N = "multilang"
PYDIALOG_ORDER_BY = "dialog_name, source, toolbar_name, id"

ROW_SORT_COLUMNS = (
    "source_code", "project_type", "context",
    "feature_type", "formname", "formtype", "tabname",
    "source", "columnname", "typevalue", "parameter", "method",
    "layername", "hint", "id",
)

JSON_COLUMN_BY_CONTEXT = {
    "config_report": "filterparam",
    "config_toolbox": "inputparams",
    "config_form_fields": "widgetcontrols",
}

_MAIN_WS_UD_TABLES = (
    "dbparam_user", "dbconfig_param_system", "dbconfig_form_fields", "dbconfig_typevalue",
    "dbfprocess", "dbmessage", "dbconfig_csv", "dbconfig_form_tabs", "dbconfig_report",
    "dbconfig_toolbox", "dbfunction", "dblabel", "dbtypevalue", "dbconfig_form_tableview",
    "dbconfig_visit_parameter", "dbtable", "dbconfig_form_fields_feat", "dbplan_price", "dbstyle",
    "su_basic_tables", "dbjson", "dbconfig_form_fields_json",
)

# base columns, i18n column prefixes (lb, ms, …), ORDER BY
TABLE_SPECS = {
    "dbconfig_form_fields": (
        ["source", "formname", "formtype", "tabname", "project_type", "context", "source_code", "lb_en_us", "tt_en_us"],
        ["lb", "tt"],
        ["source_code", "project_type", "context", "formname", "formtype", "tabname", "source", "id"],
    ),
    "dbparam_user": (
        ["source", "project_type", "context", "source_code", "lb_en_us", "tt_en_us"],
        ["lb", "tt"],
        ["source_code", "project_type", "context", "source", "id"],
    ),
    "dbconfig_param_system": (
        ["source", "project_type", "context", "source_code", "lb_en_us", "tt_en_us"],
        ["lb", "tt"],
        ["source_code", "project_type", "context", "source", "id"],
    ),
    "dbconfig_typevalue": (
        ["source", "formname", "project_type", "context", "source_code", "tt_en_us"],
        ["tt"],
        ["source_code", "project_type", "context", "formname", "source", "id"],
    ),
    "dbmessage": (
        ["source", "project_type", "context", "ms_en_us", "ht_en_us"],
        ["ms", "ht"],
        ["source_code", "project_type", "context", "source", "id"],
    ),
    "dbfprocess": (
        ["project_type", "context", "source", "ex_en_us", "in_en_us", "na_en_us"],
        ["ex", "in", "na"],
        ["source_code", "project_type", "context", "source", "id"],
    ),
    "dbconfig_csv": (
        ["source", "project_type", "context", "al_en_us", "ds_en_us"],
        ["al", "ds"],
        ["source_code", "project_type", "context", "source", "id"],
    ),
    "dbconfig_form_tabs": (
        ["formname", "source", "project_type", "context", "lb_en_us", "tt_en_us"],
        ["lb", "tt"],
        ["source_code", "project_type", "context", "formname", "source", "id"],
    ),
    "dbconfig_report": (
        ["source", "project_type", "context", "al_en_us", "ds_en_us"],
        ["al", "ds"],
        ["source_code", "project_type", "context", "source", "id"],
    ),
    "dbconfig_toolbox": (
        ["source", "project_type", "context", "al_en_us", "ob_en_us"],
        ["al", "ob"],
        ["source_code", "project_type", "context", "source", "id"],
    ),
    "dbfunction": (
        ["source", "project_type", "context", "ds_en_us"],
        ["ds"],
        ["source_code", "project_type", "context", "source", "id"],
    ),
    "dbtypevalue": (
        ["source", "project_type", "context", "typevalue", "vl_en_us", "ds_en_us"],
        ["vl", "ds"],
        ["source_code", "project_type", "context", "typevalue", "source", "id"],
    ),
    "dbconfig_form_tableview": (
        ["source", "columnname", "project_type", "context", "al_en_us"],
        ["al"],
        ["source_code", "project_type", "context", "columnname", "source", "id"],
    ),
    "dbjson": (
        ["source", "project_type", "context", "hint", "text", "lb_en_us"],
        ["lb"],
        ["source_code", "project_type", "context", "source", "hint"],
    ),
    "dbconfig_form_fields_json": (
        ["source", "formname", "formtype", "tabname", "project_type", "context", "source_code", "hint", "text", "lb_en_us"],
        ["lb"],
        ["source_code", "project_type", "context", "formname", "formtype", "tabname", "source", "id"],
    ),
    "dbconfig_form_fields_feat": (
        ["feature_type", "source", "formtype", "tabname", "project_type", "context", "source_code", "lb_en_us", "tt_en_us"],
        ["lb", "tt"],
        ["source_code", "project_type", "context", "formtype", "tabname", "source", "id"],
    ),
    "dbtable": (
        ["source", "project_type", "context", "al_en_us", "ds_en_us"],
        ["al", "ds"],
        ["source_code", "project_type", "context", "source", "id"],
    ),
    "dblabel": (
        ["source", "project_type", "context", "vl_en_us"],
        ["vl"],
        ["source_code", "project_type", "context", "source", "id"],
    ),
    "su_basic_tables": (
        ["source", "project_type", "context", "na_en_us", "ob_en_us"],
        ["na", "ob"],
        ["source_code", "project_type", "context", "source", "id"],
    ),
    "su_feature": (
        ["project_type", "context", "feature_class", "feature_type", "lb_en_us", "ds_en_us"],
        ["lb", "ds"],
        ["source_code", "project_type", "context", "feature_class", "feature_type", "lb_en_us", "id"],
    ),
    "dbconfig_engine": (
        ["project_type", "context", "parameter", "method", "lb_en_us", "ds_en_us", "pl_en_us"],
        ["lb", "ds", "pl"],
        ["source_code", "project_type", "context", "parameter", "method", "id"],
    ),
    "dbplan_price": (
        ["source", "project_type", "context", "ds_en_us", "tx_en_us", "pr_en_us"],
        ["ds", "tx", "pr"],
        ["source_code", "project_type", "context", "source"],
    ),
    "dbconfig_visit_parameter": (
        ["source", "project_type", "context", "ds_en_us"],
        ["ds"],
        ["source_code", "project_type", "context", "source", "id"],
    ),
    "dbstyle": (
        ["CAST(source AS INTEGER)", "layername", "project_type", "context", "org_text", "hint", "lb_en_us"],
        ["lb"],
        ["source_code", "context", "layername", "source", "hint"],
    ),
}


# =============================================================================
# 2. FILE UTILITIES AND ORDERING
# =============================================================================

class WriteStats:
    """Counts files written vs skipped because content was unchanged."""

    def __init__(self):
        self.written = 0
        self.unchanged = 0

    def reset(self):
        self.written = 0
        self.unchanged = 0

    def record(self, changed: bool):
        if changed:
            self.written += 1
        else:
            self.unchanged += 1


def _normalize_newlines(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n")


def _canonical_json(obj) -> str:
    return json.dumps(obj, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def _json_for_sql(obj) -> str:
    if isinstance(obj, str):
        obj = json.loads(obj)
    return _canonical_json(obj).replace("'", "''")


def _to_sortable(value):
    if value is None:
        return ""
    if isinstance(value, (dict, list)):
        return json.dumps(value, sort_keys=True, ensure_ascii=False)
    return str(value)


def _row_sort_key(row) -> tuple:
    return tuple(_to_sortable(row.get(col)) for col in ROW_SORT_COLUMNS)


def _atomic_write_if_changed(path: str, content: str, encoding: str = "utf-8") -> bool:
    content = _normalize_newlines(content)
    if os.path.isfile(path):
        try:
            with open(path, "r", encoding=encoding) as fh:
                if _normalize_newlines(fh.read()) == content:
                    return False
        except OSError as exc:
            tools_log.log_warning(f"Could not read {path} for compare: {exc}")

    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    tmp_path = f"{path}.tmp"
    try:
        with open(tmp_path, "w", encoding=encoding, newline="\n") as fh:
            fh.write(content)
        os.replace(tmp_path, path)
        return True
    except OSError:
        if os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except OSError:
                pass
        raise


def _xml_escape_text(value) -> str:
    if value is None:
        return ""
    return xml_escape(str(value), {'"': "&quot;", "'": "&apos;"})


def _sql_literal(value) -> str:
    if not value:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def _sanitize_sql_text(literal: str) -> str:
    if literal and literal != "NULL" and "\n" in literal:
        return literal.replace('"', "''").replace("\r", "").replace("\n", " ")
    return literal


# =============================================================================
# 3. TRANSLATION AND JSON
# =============================================================================

def _resolve_translation(row, key, fallback_en, lower_lang, use_relative_langs, return_source=False):
    """Unified fallback chain for SQL, TS, styles, and JSON."""
    row = dict(row)
    val = row.get(key) or row.get(f"auto_{key}")
    if val:
        return val

    if use_relative_langs:
        parts = key.split("_")
        if len(parts) >= 3:
            prefix = f"{parts[0]}_{parts[1]}_"
            candidates = []
            for col, text in row.items():
                if not text or col in (key, f"auto_{key}"):
                    continue
                if col.startswith(prefix):
                    candidates.append((1, text))
                elif col.startswith(f"auto_{prefix}"):
                    candidates.append((2, text))
            if candidates:
                candidates.sort(key=lambda item: item[0])
                return candidates[0][1]

    val = row.get(fallback_en)
    if val:
        return val
    if return_source:
        return row.get("source")
    return None


def _replace_json_translations(json_data, default_text, key_hint, translated):
    if ", " in default_text and key_hint == "comboNames":
        default_list = default_text.split(", ")
        translated_list = translated.split(", ")
        for item in json_data:
            if isinstance(item, dict) and key_hint in item:
                if set(default_list).intersection(item["comboNames"]):
                    item["comboNames"] = [
                        t if d in default_list else d
                        for d, t in zip(default_list, translated_list)
                    ]
    elif isinstance(json_data, dict):
        for key_name, value in json_data.items():
            if key_name == key_hint and value == default_text:
                json_data[key_name] = translated
    elif isinstance(json_data, list):
        for i, item in enumerate(json_data or []):
            json_data[i] = _replace_json_translations(item, default_text, key_hint, translated)
    else:
        tools_log.log_error("Unexpected json_data structure!")
    return json_data


# =============================================================================
# 4. UI AND ORCHESTRATION
# =============================================================================

class GwI18NGenerator:

    def __init__(self):
        self.plugin_dir = lib_vars.plugin_dir
        self.schema_name = lib_vars.schema_name
        self.multiple_languages = False
        self.language = None
        self.lower_lang = None
        self.languages = []
        self.schema_i18n = SCHEMA_I18N
        self.last_error = None
        self.path_dic = None
        self.dlg_qm = None
        self.project_type = None
        self._column_cache = {}
        self._write_stats = WriteStats()
        self.conn_i18n = None
        self.cursor_i18n = None

    # --- UI ---

    def init_dialog(self):
        """Open dialog and wire signals."""

        self.dlg_qm = GwAdminTranslationUi(self)
        tools_gw.load_settings(self.dlg_qm)

        self._load_user_values()

        self.dlg_qm.btn_translate.setEnabled(False)
        # Mysteriously without the partial the function check_connection is not called
        self.dlg_qm.btn_connection.clicked.connect(partial(self._check_connection))
        self.dlg_qm.btn_translate.clicked.connect(self._check_translate_options)
        self.dlg_qm.btn_close.clicked.connect(partial(tools_gw.close_dialog, self.dlg_qm))
        self.dlg_qm.rejected.connect(self._save_user_values)
        self.dlg_qm.rejected.connect(self._close_db)
        tools_gw.open_dialog(self.dlg_qm, dlg_name='admin_translation')

    def pass_schema_info(self, schema_info, schema_name):
        self.project_epsg = schema_info['project_epsg']
        self.project_version = schema_info['project_version']
        self.project_language = schema_info['project_language']
        self.schema_name = schema_name

    # region private functions

    def _check_connection(self):
        """Connect to PostgreSQL and load languages."""

        self.dlg_qm.cmb_language.clear()
        self.dlg_qm.lbl_info.clear()
        self._close_db()
        host = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_host)
        port = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_port)
        db = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_db)
        user = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_user)
        password = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_pass)
        status = self._init_db(host, port, db, user, password)

        if not status:
            self.dlg_qm.btn_translate.setEnabled(False)
            tools_qt.set_widget_text(self.dlg_qm, 'lbl_info', self.last_error)
            return
        self._populate_cmb_language()

    def _populate_cmb_language(self):
        """ Populate combo with languages values """

        self.dlg_qm.btn_translate.setEnabled(True)
        host = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_host)
        msg = 'Connected to {0}'
        msg_params = (host,)
        tools_qt.set_widget_text(self.dlg_qm, 'lbl_info', msg, msg_params)
        sql = f"SELECT id, idval FROM {SCHEMA_I18N}.cat_language"
        rows = self._get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_qm.cmb_language, rows)
        language = tools_gw.get_config_parser('i18n_generator', 'qm_lang_language', "user", "init", False)

        tools_qt.set_combo_value(self.dlg_qm.cmb_language, language, 0)

    # --- Export (Translate button) ---

    def _check_translate_options(self):
        """Run export for selected language(s) and checkboxes."""

        self.dlg_qm.lbl_info.clear()
        self._column_cache = {}
        self._write_stats.reset()
        msg = ''
        self.language = tools_qt.get_combo_value(self.dlg_qm, self.dlg_qm.cmb_language, 0)
        self.schema_i18n = SCHEMA_I18N
        py_msg = tools_qt.is_checked(self.dlg_qm, self.dlg_qm.chk_py_msg)
        error_langs = {"python": [], "db": {}}
        canceled_langs = {"python": [], "db": {}}
        translated_langs = {"python": [], "db": []}
        type_db_file_translated = []

        if self.language == 'All':
            sql = f"SELECT id FROM {self.schema_i18n}.cat_language WHERE idval != 'no_TR' and idval != 'All' and idval != 'pl_PL'"
            lang_rows = self._get_rows(sql) or []
            if self._i18n_query_failed("cat_language"):
                return
            self.languages = [language['id'] for language in lang_rows]
            self.multiple_languages = True
        else:
            self.languages = [self.language]

        # Create the translation files and see which where successful, which failed and which were canceled
        for self.language in self.languages:
            self.lower_lang = self.language.lower()
            if self.language != 'no_TR':
                if py_msg:
                    status_py_msg = self._create_py_files()
                    if status_py_msg is True:
                        translated_langs['python'].append(self.language)
                    elif status_py_msg is False:
                        error_langs['python'].append(self.language)
                    elif status_py_msg is None:
                        canceled_langs['python'].append(self.language)
                else:
                    canceled_langs['python'].append(self.language)

            self._create_path_dic()
            for type_db_file in self.path_dic:
                if tools_qt.is_checked(self.dlg_qm, self.path_dic[type_db_file]['checkbox']):
                    status_all_db_msg, text_error = self._create_all_db_files(self.path_dic[type_db_file]["path"], type_db_file)
                    if status_all_db_msg is True:
                        if self.language not in translated_langs['db']:
                            translated_langs['db'].append(self.language)
                    elif status_all_db_msg is False:
                        if type_db_file not in error_langs['db']:
                            error_langs['db'][type_db_file] = {self.language: []}
                        if self.language not in error_langs['db'][type_db_file]:
                            error_langs['db'][type_db_file][self.language] = []
                        error_langs['db'][type_db_file][self.language].append(text_error)
                    elif status_all_db_msg is None:
                        if type_db_file not in canceled_langs['db']:
                            canceled_langs['db'][type_db_file] = {self.language: []}
                        if self.language not in canceled_langs['db'][type_db_file]:
                            canceled_langs['db'][type_db_file][self.language] = []
                        canceled_langs['db'][type_db_file][self.language].append(text_error)
                    if type_db_file not in type_db_file_translated:
                        type_db_file_translated.append(type_db_file)

        # Write a message with the results
        if py_msg:
            if error_langs['python']:
                msg += f'''{tools_qt.tr('Python translation failed:')} {", ".join(error_langs['python'])}\n'''
            if canceled_langs['python']:
                msg += f'''{tools_qt.tr('Python translation canceled:')} {", ".join(canceled_langs['python'])}\n'''
            if translated_langs['python']:
                msg += f'''{tools_qt.tr('Python translation successful:')} {", ".join(translated_langs['python'])}\n'''

        if type_db_file_translated:
            for type_db_file in type_db_file_translated:
                msg += f'''{tools_qt.tr('Schemas translated:')} {type_db_file}\n'''
                if error_langs['db'] and type_db_file in error_langs['db'] and error_langs['db'][type_db_file]:
                    text = '\n'.join(f"\t\t{lang}: {', '.join(msg)}" for lang, msg in error_langs['db'][type_db_file].items())
                    msg += f'''\t{tools_qt.tr('Database translation failed:')}{text}\n'''
                if canceled_langs['db'] and type_db_file in canceled_langs['db'] and canceled_langs['db'][type_db_file]:
                    text = '\n'.join(f"\t\t{lang}: {', '.join(msg)}" for lang, msg in canceled_langs['db'][type_db_file].items())
                    msg += f'''\t{tools_qt.tr('Database translation canceled:')}{text}\n'''
                if translated_langs['db']:
                    msg += f'''\t{tools_qt.tr('Database translation successful:')} {", ".join(translated_langs['db'])}\n'''

        if self._write_stats.written or self._write_stats.unchanged:
            msg += (
                f"{tools_qt.tr('Files written:')} {self._write_stats.written}, "
                f"{tools_qt.tr('unchanged:')} {self._write_stats.unchanged}\n"
            )

        if msg != '':
            tools_qt.set_widget_text(self.dlg_qm, 'lbl_info', msg)

    def _use_relative_langs(self) -> bool:
        return tools_qt.is_checked(self.dlg_qm, self.dlg_qm.chk_relative_langs)

    def _get_translation(self, row, key, fallback_en, return_source=False):
        return _resolve_translation(
            row, key, fallback_en, self.lower_lang, self._use_relative_langs(), return_source
        )

    def _write_file_if_changed(self, path: str, content: str) -> bool:
        changed = _atomic_write_if_changed(path, content)
        self._write_stats.record(changed)
        return changed

    # --- i18n DB catalog (dynamic columns) ---

    def _get_matching_columns(self, table, key):
        """ Get columns matching the language of the key """

        if table not in self._column_cache:
            sql = (f"SELECT column_name FROM information_schema.columns "
                   f"WHERE table_schema = '{self.schema_i18n}' AND table_name = '{table}' "
                   f"ORDER BY column_name")
            rows = self._get_rows(sql, commit=False)
            self._column_cache[table] = [row['column_name'] for row in rows] if rows else []

        columns = self._column_cache[table]
        parts = key.split('_')
        if len(parts) < 2:
            return []

        prefix = f"{parts[0]}_{parts[1]}_"

        extra_cols = []
        if columns:
            for name in columns:
                if name.startswith(prefix) and name != key:
                    extra_cols.append(name)
                    extra_cols.append(f"auto_{name}")
                    extra_cols.append(f"va_auto_{name}")

        return extra_cols

    def _generate_lang_columns(self, table: str, prefixes: list[str]) -> list[str]:
        """ Generate language columns list for given prefixes """

        lang_columns = []
        extra_cols = []
        for prefix in prefixes:
            key = f"{prefix}_{self.lower_lang}"
            lang_columns.extend([key, f"auto_{key}", f"va_auto_{key}"])
            extra_cols.extend(self._get_matching_columns(table, key))
        
        lang_columns.extend(extra_cols)
        return lang_columns

    def _pydialog_order_by(self) -> str:
        """ORDER BY clause adapted to columns present in i18n.pydialog."""
        if "pydialog" not in self._column_cache:
            self._get_matching_columns("pydialog", "lb_en_us")
        columns = set(self._column_cache.get("pydialog") or [])
        parts = [col for col in ("dialog_name", "source", "toolbar_name", "id") if col in columns]
        return ", ".join(parts) if parts else "dialog_name, source"

    def _i18n_query_failed(self, sql: str) -> bool:
        if not self.last_error:
            return False
        tools_log.log_warning(f"i18n SQL failed: {self.last_error}", parameter=sql)
        if self.dlg_qm:
            tools_qt.set_widget_text(self.dlg_qm, "lbl_info", f"{self.last_error}")
        return True

    # --- Qt export (.ts) ---

    def _deduplicate_py_dialogs(self, py_dialogs):
        """
        Merge duplicate pydialog rows (same dialog_name + source, different toolbar_name).
        Keeps the newest row and fills empty translation columns from older duplicates.
        """
        if not py_dialogs:
            return []
        groups = {}
        order = []
        for row in py_dialogs:
            key = (row['dialog_name'], row['source'])
            if key not in groups:
                groups[key] = []
                order.append(key)
            groups[key].append(dict(row))

        result = []
        skip_cols = {'dialog_name', 'source', 'toolbar_name', 'id'}
        for key in order:
            rows = groups[key]
            if len(rows) == 1:
                result.append(rows[0])
                continue

            merged = dict(rows[-1])
            for row in rows[:-1]:
                for col, val in row.items():
                    if col in skip_cols:
                        continue
                    if val and not merged.get(col):
                        merged[col] = val

            tools_log.log_info(
                f"Merged {len(rows)} pydialog rows for dialog={key[0]!r} source={key[1]!r}"
            )
            result.append(merged)
        return result

    def _create_py_files(self):
        """Build giswater_{lang}.ts and run lrelease only when the .ts file changed."""
        key_label = f"lb_{self.lower_lang}"
        key_tooltip = f"tt_{self.lower_lang}"
        key_message = f"ms_{self.lower_lang}"
        sch = SCHEMA_I18N
        order_by = self._pydialog_order_by()

        if self.lower_lang == "en_us":
            py_messages = self._get_rows(f"SELECT source, ms_en_us FROM {sch}.pymessage ORDER BY source;")
            if self._i18n_query_failed("pymessage"):
                return False
            py_toolbars = self._get_rows(f"SELECT source, lb_en_us FROM {sch}.pytoolbar ORDER BY source;")
            if self._i18n_query_failed("pytoolbar"):
                return False
            sql = (f"SELECT dialog_name, source, lb_en_us, tt_en_us FROM {sch}.pydialog "
                   f"ORDER BY {order_by};")
            py_dialogs = self._deduplicate_py_dialogs(self._get_rows(sql))
            if self._i18n_query_failed("pydialog"):
                return False
        else:
            extra_ms = self._get_matching_columns("pymessage", key_message)
            extra_ms_str = ", " + ", ".join(extra_ms) if extra_ms else ""
            py_messages = self._get_rows(
                f"SELECT source, ms_en_us, {key_message}, auto_{key_message}{extra_ms_str} "
                f"FROM {sch}.pymessage ORDER BY source;"
            )
            if self._i18n_query_failed("pymessage"):
                return False
            extra_lb = self._get_matching_columns("pytoolbar", key_label)
            extra_lb_str = ", " + ", ".join(extra_lb) if extra_lb else ""
            py_toolbars = self._get_rows(
                f"SELECT source, lb_en_us, {key_label}, auto_{key_label}{extra_lb_str} "
                f"FROM {sch}.pytoolbar ORDER BY source;"
            )
            if self._i18n_query_failed("pytoolbar"):
                return False
            extra_dlg_lb = self._get_matching_columns("pydialog", key_label)
            extra_dlg_lb_str = ", " + ", ".join(extra_dlg_lb) if extra_dlg_lb else ""
            extra_dlg_tt = self._get_matching_columns("pydialog", key_tooltip)
            extra_dlg_tt_str = ", " + ", ".join(extra_dlg_tt) if extra_dlg_tt else ""
            sql = (
                f"SELECT dialog_name, source, lb_en_us, {key_label}, auto_{key_label}{extra_dlg_lb_str}, "
                f"tt_en_us, {key_tooltip}, auto_{key_tooltip}{extra_dlg_tt_str} "
                f"FROM {sch}.pydialog ORDER BY {order_by};"
            )
            py_dialogs = self._deduplicate_py_dialogs(self._get_rows(sql))
            if self._i18n_query_failed("pydialog"):
                return False

        ts_path = os.path.join(self.plugin_dir, "i18n", f"giswater_{self.language}.ts")
        if os.path.exists(ts_path) and not self.multiple_languages:
            if not tools_qt.show_question(
                "Are you sure you want to overwrite this file?",
                "Overwrite",
                parameter=f"\n\n{ts_path}",
            ):
                return None

        out = io.StringIO()
        out.write('<?xml version="1.0" encoding="utf-8"?>\n<!DOCTYPE TS>\n')
        out.write(f'<TS version="2.0" language="{self.language}">\n')
        out.write("\t<!-- TOOLBARS AND ACTIONS -->\n\t<context>\n\t\t<name>giswater</name>\n")
        for row in py_toolbars:
            tr = self._get_translation(dict(row), key_label, "lb_en_us", return_source=True)
            out.write(f"\t\t<message>\n\t\t\t<source>{_xml_escape_text(row['source'])}</source>\n")
            out.write(f"\t\t\t<translation>{_xml_escape_text(tr)}</translation>\n\t\t</message>\n")
        out.write("\t\t<!-- PYTHON MESSAGES -->\n")
        for row in py_messages:
            tr = self._get_translation(dict(row), key_message, "ms_en_us", return_source=True)
            out.write(f"\t\t<message>\n\t\t\t<source>{_xml_escape_text(row['source'])}</source>\n")
            out.write(f"\t\t\t<translation>{_xml_escape_text(tr)}</translation>\n\t\t</message>\n")
        out.write("\t</context>\n\n\t<!-- UI TRANSLATION -->\n")

        name = None
        block = ""
        for row in py_dialogs:
            if name and name != row["dialog_name"]:
                out.write(block + "\t</context>\n")
                block = ""
            if name != row["dialog_name"]:
                name = row["dialog_name"]
                block = f"\t<context>\n\t\t<name>{_xml_escape_text(name)}</name>\n"
                title = self._get_title(py_dialogs, name, key_label)
                if title:
                    block += (
                        "\t\t<message>\n\t\t\t<source>title</source>\n"
                        f"\t\t\t<translation>{_xml_escape_text(title)}</translation>\n\t\t</message>\n"
                    )
            tr = self._get_translation(dict(row), key_label, "lb_en_us", return_source=True)
            block += (
                f"\t\t<message>\n\t\t\t<source>{_xml_escape_text(row['source'])}</source>\n"
                f"\t\t\t<translation>{_xml_escape_text(tr)}</translation>\n\t\t</message>\n"
            )
            tip_key = f"tooltip_{row['source']}"
            tr = self._get_translation(dict(row), key_tooltip, "tt_en_us", return_source=True)
            block += (
                f"\t\t<message>\n\t\t\t<source>{_xml_escape_text(tip_key)}</source>\n"
                f"\t\t\t<translation>{_xml_escape_text(tr)}</translation>\n\t\t</message>\n"
            )
        out.write(block + "\t</context>\n</TS>\n\n")

        try:
            changed = self._write_file_if_changed(ts_path, out.getvalue())
        except OSError as exc:
            tools_log.log_warning(f"Error writing TS file: {exc}")
            return False

        if not changed:
            tools_log.log_info(f"TS unchanged, skipping lrelease: {ts_path}")
            return True

        lrelease = shutil.which("lrelease")
        if not lrelease:
            bundled = os.path.join(self.plugin_dir, "resources", "i18n", "lrelease.exe")
            if os.path.isfile(bundled):
                lrelease = bundled
        if not lrelease:
            tools_log.log_warning("lrelease not found; .ts written but .qm not generated")
            return True
        try:
            proc = subprocess.run([lrelease, ts_path], capture_output=True, text=True)
            if proc.returncode == 0:
                return True
            tools_log.log_warning(f"lrelease failed: {proc.stderr}")
            return False
        except Exception as exc:
            tools_log.log_warning(f"Error running lrelease: {exc}")
            return False

    def _get_title(self, py_dialogs, name, key_label):
        """ Return title's according language """

        title = None
        for py in py_dialogs:
            if py['source'] == f'dlg_{name}':
                return self._get_translation(dict(py), key_label, 'lb_en_us', return_source=True)
        return title

    # endregion
    # region Database files

    # --- SQL export ---

    def _create_all_db_files(self, cfg_path, file_type):
        """Build one .sql patch file per i18n table in the language folder."""

        self.project_type = self.path_dic[file_type]["project_type"][0]
        text_error = ""

        if os.path.exists(cfg_path) and not self.multiple_languages:
            if not tools_qt.show_question(
                "Are you sure you want to overwrite this folder?",
                "Overwrite",
                parameter=f"\n\n{cfg_path}",
            ):
                return None, "Translation canceled"
        else:
            os.makedirs(cfg_path, exist_ok=True)

        if self.language == 'no_TR':
            return True, f"{file_type}, not translated"

        for dbtable in self.path_dic[file_type]['tables']:
            file_path = cfg_path + f"{dbtable}.sql"
            buffer = io.StringIO()
            buffer.write(self._build_sql_header(file_path, file_type))

            result = self._get_table_values(dbtable)
            if not isinstance(result, tuple) or len(result) != 2:
                return False, f"Invalid return format from _get_table_values for: {dbtable}"

            rows, columns = result
            if not rows:
                tools_log.log_warning("No rows found in: {0}, skipping file.", msg_params=(dbtable,))
                continue

            if "json" in dbtable:
                text_error += self._write_dbjson_values(rows, buffer, file_type)
            elif dbtable == "dbstyle":
                self._write_dbstyle_values(rows, buffer, file_type)
            else:
                self._write_table_values(rows, columns, dbtable, buffer, file_type)

            buffer.write(self._build_sql_footer(file_path))
            try:
                self._write_file_if_changed(file_path, buffer.getvalue())
            except OSError as exc:
                return False, f"Error writing {dbtable}.sql: {exc}"

        return (False, text_error) if text_error else (True, "")

    def _get_table_values(self, table):
        """ Get table values """

        # Update the part the of the program in process
        self.dlg_qm.lbl_info.clear()
        msg = "{0} ({1}) - {2} - Updating {3}..."
        msg_params = (self.language, f"{self.languages.index(self.language) + 1}/{len(self.languages)}", self.project_type, table)
        tools_qt.set_widget_text(self.dlg_qm, 'lbl_info', msg, msg_params)
        QApplication.processEvents()
        spec = TABLE_SPECS.get(table)
        if not spec:
            tools_log.log_error("Unknown i18n table: {0}", msg_params=(table,))
            return False, []
        columns, lang_prefixes, order_by = spec
        lang_columns = self._generate_lang_columns(table, lang_prefixes)

        # Make the query
        sql = ""
        try:
            if self.lower_lang == 'en_us':
                sql = (f"SELECT {', '.join(columns)} "
                f"FROM {self.schema_i18n}.{table} "
                f"ORDER BY {', '.join(order_by)};")
            else:
                sql = (f"SELECT {', '.join(columns)}, {', '.join(lang_columns)} "
                f"FROM {self.schema_i18n}.{table} "
                f"ORDER BY {', '.join(order_by)};")
            rows = self._get_rows(sql)
        except Exception as e:
            msg = "Error getting table values: {0}"
            msg_params = (e,)
            tools_log.log_error(msg, msg_params=msg_params)
            return False, columns

        # Return the corresponding information
        if not rows:
            return False, False
        return rows, columns

    def _write_table_values(self, rows, columns, table, buffer, file_type):
        """Append UPDATE … FROM (VALUES …) blocks to the buffer."""

        values_by_context = {}
        forenames = [col.split("_")[0] for col in columns if col.endswith("en_us")]

        for row in rows:
            if row['project_type'] not in self.path_dic[file_type]["project_type"]:
                continue

            texts = []
            for forename in forenames:
                key = f'{forename}_{self.lower_lang}'
                fallback_en = f'{forename}_en_us'
                value = self._get_translation(row, key, fallback_en)

                if (not value or value == row.get('source')) and forename == 'tt' and table in [
                        "dbconfig_form_fields", "dbconfig_param_system",
                        "dbparam_user", "dbconfig_form_fields_feat"]:
                    value = row.get('lb_en_us') or value

                if not value:
                    texts.append('NULL')
                else:
                    texts.append("'" + value.replace("'", "''") + "'")

            for i, text in enumerate(texts):
                if "\n" in texts[i] and texts[i] is not None:
                    texts[i] = self._replace_invalid_characters(texts[i])

            context = row['context']
            if context not in values_by_context:
                values_by_context[context] = []

            values_by_context[context].append((row, texts))

        for context in sorted(values_by_context.keys(), key=_to_sortable):
            data = sorted(values_by_context[context], key=lambda item: _row_sort_key(item[0]))
            if 'dbconfig_form_fields' in table:
                if 'feat' in table:
                    values_str = ""
                    k = 0
                    feature_types = ['ARC', 'CONNEC', 'NODE', 'GULLY', 'LINK', 'ELEMENT']
                    for row, txt in data:
                        for feature_type in feature_types:
                            if row['feature_type'] == feature_type:
                                if k != 0:
                                    values_str += ",\n"
                                values_str += f"('{row['source']}', '%_{row['feature_type'].lower()}%', '{row['formtype'].lower()}', '{row['tabname']}', {txt[0]}, {txt[1]})"
                                k = 1
                                break
                    buffer.write(f"UPDATE {context} AS t SET label = v.label, tooltip = v.tooltip FROM (\n\tVALUES\n\t{values_str}\n) AS v(columnname, formname, formtype, tabname, label, tooltip)\nWHERE t.columnname = v.columnname AND t.formname LIKE v.formname AND t.formtype = v.formtype AND t.tabname = v.tabname;\n\n")
                else:
                    values_str = ",\n    ".join([f"('{row['source']}', '{row['formname']}', '{row['formtype']}', '{row['tabname']}', {txt[0]}, {txt[1]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET label = v.label, tooltip = v.tooltip FROM (\n\tVALUES\n\t{values_str}\n) AS v(columnname, formname, formtype, tabname, label, tooltip)\nWHERE t.columnname = v.columnname AND t.formname = v.formname AND t.formtype = v.formtype AND t.tabname = v.tabname;\n\n")

            elif "dbparam_user" in table:
                    values_str = ",\n    ".join([f"('{row['source']}', {txt[0]}, {txt[1]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET label = v.label, descript = v.descript FROM (\n\tVALUES\n\t{values_str}\n) AS v(id, label, descript)\nWHERE t.id = v.id;\n\n")

            elif "dbconfig_param_system" in table:
                    values_str = ",\n    ".join([f"('{row['source']}', {txt[0]}, {txt[1]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET label = v.label, descript = v.descript FROM (\n\tVALUES\n\t{values_str}\n) AS v(parameter, label, descript)\nWHERE t.parameter = v.parameter;\n\n")

            elif 'dbconfig_typevalue' in table:
                    values_str = ",\n    ".join([f"('{row['source']}', '{row['formname']}', {txt[0]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET idval = v.idval FROM (\n\tVALUES\n\t{values_str}\n) AS v(source, formname, idval)\nWHERE t.id = v.source AND t.typevalue = v.formname;\n\n")

            elif "dbmessage" in table:
                    values_str = ",\n    ".join([f"({row['source']}, {txt[0]}, {txt[1]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET error_message = v.error_message, hint_message = v.hint_message FROM (\n\tVALUES\n\t{values_str}\n) AS v(id, error_message, hint_message)\nWHERE t.id = v.id;\n\n")

            elif "dbfprocess" in table:
                    values_str = ",\n    ".join([f"({row['source']}, {txt[0]}, {txt[1]}, {txt[2]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET except_msg = v.except_msg, info_msg = v.info_msg, fprocess_name = v.fprocess_name FROM (\n\tVALUES\n\t{values_str}\n) AS v(fid, except_msg, info_msg, fprocess_name)\nWHERE t.fid = v.fid;\n\n")

            elif "dbconfig_csv" in table:
                    values_str = ",\n    ".join([f"({row['source']}, {txt[0]}, {txt[1]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET alias = v.alias, descript = v.descript FROM (\n\tVALUES\n\t{values_str}\n) AS v(fid, alias, descript)\nWHERE t.fid = v.fid;\n\n")

            elif "dbconfig_toolbox" in table:
                    values_str = ",\n    ".join([f"({row['source']}, {txt[0]}, {txt[1]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET alias = v.alias, observ = v.observ FROM (\n\tVALUES\n\t{values_str}\n) AS v(id, alias, observ)\nWHERE t.id = v.id;\n\n")

            elif "dbconfig_report" in table:
                    values_str = ",\n    ".join([f"({row['source']}, {txt[0]}, {txt[1]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET alias = v.alias, descript = v.descript FROM (\n\tVALUES\n\t{values_str}\n) AS v(id, alias, descript)\nWHERE t.id = v.id;\n\n")

            elif "dbtypevalue" in table:
                    values_str = ",\n    ".join([f"('{row['source']}', '{row['typevalue']}', {txt[0]}, {txt[1]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET idval = v.idval, descript = v.descript FROM (\n\tVALUES\n\t{values_str}\n) AS v(id, typevalue, idval, descript)\nWHERE t.id = v.id AND t.typevalue = v.typevalue;\n\n")

            elif "dbtable" in table:
                    values_str = ""
                    if file_type == "cm":
                        values_str = ",\n    ".join([f"('%_{row['source']}', {txt[0]}, {txt[1]})" for row, txt in data if row['source'] != '0'])
                    else:
                        values_str = ",\n    ".join([f"('{row['source']}', {txt[0]}, {txt[1]})" for row, txt in data if row])
                    buffer.write(f"UPDATE {context} AS t SET alias = v.alias, descript = v.descript FROM (\n\tVALUES\n\t{values_str}\n) AS v(id, alias, descript)\nWHERE t.id = v.id;\n\n")

            elif "su_basic_tables" in table:
                    if file_type == "am":
                        values_str = ",\n    ".join([f"('{row['source']}', {txt[0]})" for row, txt in data])
                        buffer.write(f"UPDATE {context} AS t SET idval = v.idval FROM (\n\tVALUES\n\t{values_str}\n) AS v(id, idval)\nWHERE t.id = v.id;\n\n")

                    elif context == "value_state_type":
                        values_str = ",\n    ".join([f"({row['source']}, {txt[0]})" for row, txt in data])
                        buffer.write(f"UPDATE {context} AS t SET name = v.name FROM (\n\tVALUES\n\t{values_str}\n) AS v(id, name)\nWHERE t.id = v.id;\n\n")

                    elif context == "value_state":
                        values_str = ",\n    ".join([f"({row['source']}, {txt[0]}, {txt[1]})" for row, txt in data])
                        buffer.write(f"UPDATE {context} AS t SET name = v.name, observ = v.observ FROM (\n\tVALUES\n\t{values_str}\n) AS v(id, name, observ)\nWHERE t.id = v.id;\n\n")

                    elif context == "config_param_system":
                        values_str = ",\n    ".join([f"('{row['source']}', {txt[0]})" for row, txt in data])
                        buffer.write(f"UPDATE {context} AS t SET value = v.value FROM (\n\tVALUES\n\t{values_str}\n) AS v(parameter, value)\nWHERE t.parameter = v.parameter;\n\n")
                    
            elif "dbfunction" in table:
                    values_str = ",\n    ".join([f"({row['source']}, {txt[0]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET descript = v.descript FROM (\n\tVALUES\n\t{values_str}\n) AS v(id, descript)\nWHERE t.id = v.id;\n\n")

            elif "dbconfig_form_tabs" in table:
                    values_str = ",\n    ".join([f"('{row['formname']}', '{row['source']}', {txt[0]}, {txt[1]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET label = v.label, tooltip = v.tooltip FROM (\n\tVALUES\n\t{values_str}\n) AS v(formname, tabname, label, tooltip)\nWHERE t.formname = v.formname AND t.tabname = v.tabname;\n\n")

            elif "dbconfig_form_tableview" in table:
                    values_str = ",\n    ".join([f"('{row['source']}', '{row['columnname']}', {txt[0]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET alias = v.alias FROM (\n\tVALUES\n\t{values_str}\n) AS v(objectname, columnname, alias)\nWHERE t.objectname = v.objectname AND t.columnname = v.columnname;\n\n")

            elif "su_feature" in table:
                    values_str = ",\n    ".join([f"('{row['lb_en_us']}', '{row['feature_class']}', '{row['feature_type']}', {txt[0]}, {txt[1]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET id = v.idval, descript = v.descript FROM (\n\tVALUES\n\t{values_str}\n) AS v(lb_en_us, feature_class, feature_type, idval, descript)\nWHERE t.id = v.lb_en_us AND t.feature_class = v.feature_class AND t.feature_type = v.feature_type;\n\n")

            elif "dblabel" in table:
                    values_str = ",\n    ".join([f"({row['source']}, {txt[0]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET idval = v.idval FROM (\n\tVALUES\n\t{values_str}\n) AS v(id, idval)\nWHERE t.id = v.id;\n\n")

            elif "dbconfig_visit_parameter" in table:
                    values_str = ",\n    ".join([f"('{row['source']}', {txt[0]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET descript = v.descript FROM (\n\tVALUES\n\t{values_str}\n) AS v(id, descript)\nWHERE t.id = v.id;\n\n")

            elif "dbconfig_engine" in table:
                    values_str = ",\n    ".join([f"('{row['parameter']}', '{row['method']}', {txt[0]}, {txt[1]}, {txt[2]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET label = v.label, descript = v.descript, placeholder = v.placeholder FROM (\n\tVALUES\n\t{values_str}\n) AS v(parameter, method, label, descript, placeholder)\nWHERE t.parameter = v.parameter AND t.method = v.method;\n\n")

            elif "dbplan_price" in table:
                    values_str = ",\n    ".join([f"('{row['source']}', {txt[0]}, {txt[1]}, {txt[2]})" for row, txt in data])
                    buffer.write(f"UPDATE {context} AS t SET descript = v.descript, text = v.text, price = REPLACE(v.price, ',', '.')::numeric FROM (\n\tVALUES\n\t{values_str}\n) AS v(id, descript, text, price)\nWHERE t.id = v.id;\n\n")           

    # endregion
    # region Generate from Json

    def _write_dbjson_values(self, rows, buffer, file_type):
        values_by_context = {}

        updates = {}
        for row in rows:
            if row['project_type'] not in self.path_dic[file_type]["project_type"]:
                continue
            text = _json_for_sql(row["text"])
            # Set key depending on context
            if row["context"] == "config_form_fields":
                key = (row["source"], row["context"], text, row["formname"], row["formtype"], row["tabname"])
            else:
                key = (row["source"], row["context"], text)
            updates.setdefault(key, []).append(row)

        for key in sorted(updates.keys(), key=lambda item: tuple(_to_sortable(value) for value in item)):
            related_rows = updates[key]
            # Unpack key
            source, context, original_text, *extra = key
            # Correct column based on context
            column = JSON_COLUMN_BY_CONTEXT.get(context)
            if not column:
                tools_log.log_error("Unknown context: {0}, skipping.", msg_params=(context,))
                continue

            text_json = json.loads(original_text.replace("''", "'"))
            # Translate fields
            for row in related_rows:
                key_hint = row["hint"].rsplit('_', 1)[0]
                default_text = row.get("lb_en_us", "")
                
                translated = self._get_translation(row, f"lb_{self.lower_lang}", "lb_en_us")

                text_json = _replace_json_translations(text_json, default_text, key_hint, translated)

            # Encode new JSON safely
            new_text = _json_for_sql(text_json)

            # Save the result grouped by context and column
            if context not in values_by_context:
                values_by_context[context] = []

            values_by_context[context].append((source, related_rows[0], new_text, column))  # <-- also store the column

        for context in sorted(values_by_context.keys(), key=_to_sortable):
            data = sorted(values_by_context[context], key=lambda item: _row_sort_key(item[1]))
            # Assume all entries in this context share the same column
            column = data[0][3]

            if context == "config_form_fields":
                values_str = ",\n    ".join([
                    f"('{row['source']}', '{row['formname']}', '{row['formtype']}', '{row['tabname']}', '{txt}')"
                    for source, row, txt, col in data
                ])
                buffer.write(
                    f"UPDATE {context} AS t SET {column} = v.text::json FROM (\n\tVALUES\n\t{values_str}\n) "
                    f"AS v(columnname, formname, formtype, tabname, text)\n"
                    f"WHERE t.columnname = v.columnname AND t.formname = v.formname "
                    f"AND t.formtype = v.formtype AND t.tabname = v.tabname;\n\n"
                )
            else:
                values_str = ",\n    ".join([
                    f"({source}, '{txt}')"
                    for source, row, txt, col in data
                ])
                buffer.write(
                    f"UPDATE {context} AS t SET {column} = v.text::json FROM (\n\tVALUES\n\t{values_str}\n) "
                    f"AS v(id, text)\nWHERE t.id = v.id;\n\n"
                )

        return ""
    # endregion
    # region Write dbstyle values

    def _write_dbstyle_values(self, rows, buffer, file_type):
        updates = defaultdict(list)

        for row in rows:
            if row['project_type'] not in self.path_dic[file_type]["project_type"]:
                continue
            
            key = (row["source"], row["layername"], row["context"], row["org_text"].replace("'", "''"))
            updates[key].append(row)

        for key in sorted(updates.keys(), key=lambda item: tuple(_to_sortable(value) for value in item)):
            related_rows = updates[key]
            source, layername, context, stylevalue = key
            new_stylevalue = stylevalue
            do_style_update = False

            for row in related_rows:
                default_text = row.get("lb_en_us", "")
                translated = self._get_translation(row, f"lb_{self.lower_lang}", "lb_en_us")

                if not default_text or not translated or default_text == translated:
                    continue
                
                # Replace exact label string: label="Original" -> label="Translated"
                if translated != default_text:
                    escaped_default = default_text.replace("'", "''")
                    escaped_translated = translated.replace("'", "''")
                    old_str = f'label="{escaped_default}"'
                    new_str = f'label="{escaped_translated}"'
                    
                    # Simple string replacement is robust for this purpose
                    new_stylevalue = new_stylevalue.replace(old_str, new_str)
                    do_style_update = True

            if do_style_update:
                values_str = ",\n\t".join([f"('{source}', '{layername}', '{new_stylevalue}')"])
                buffer.write(
                    f"UPDATE {context} AS t\nSET stylevalue = v.stylevalue\nFROM (\n\tVALUES\n\t"
                    f"{values_str}\n) AS v(styleconfig_id, layername, stylevalue)\n"
                    f"WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;\n\n"
                )
        return ""
    # endregion
    # region Extra functions

    def _build_sql_header(self, path, file_type):
        header = (
            "/*\nThis file is part of Giswater\n"
            "The program is free software: you can redistribute it and/or modify it under the terms of the GNU "
            "General Public License as published by the Free Software Foundation, either version 3 of the "
            "License, or (at your option) any later version.\n*/\n\n\n"
        )
        if file_type in ("i18n_ws", "i18n_ud", "i18n_utils") and "no_tr.sql" not in path.lower():
            header += "SET search_path = SCHEMA_NAME, public, pg_catalog;\n"
            if "config_form_fields" in path:
                header += (
                    "UPDATE config_param_system SET value = FALSE "
                    "WHERE parameter = 'admin_config_control_trigger';\n\n"
                )
        elif file_type == "am":
            header += "SET search_path = am, public;\n"
        elif file_type == "cm":
            header += "SET search_path = cm, public, public;\n"
        if self.language.lower() == "no_tr":
            header += "SELECT 1;"
        return header

    def _build_sql_footer(self, path):
        if "config_form_fields" in path:
            return (
                "UPDATE config_param_system SET value = TRUE "
                "WHERE parameter = 'admin_config_control_trigger';\n"
            )
        return ""

    # --- Option persistence ---

    def _save_user_values(self):
        """ Save selected user values """

        host = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_host, return_string_null=False)
        port = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_port, return_string_null=False)
        db = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_db, return_string_null=False)
        user = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_user, return_string_null=False)
        py_msg = tools_qt.is_checked(self.dlg_qm, self.dlg_qm.chk_py_msg)
        i18n_msg = tools_qt.is_checked(self.dlg_qm, self.dlg_qm.chk_i18n_files)
        relative_langs = tools_qt.is_checked(self.dlg_qm, self.dlg_qm.chk_relative_langs)

        tools_gw.set_config_parser('i18n_generator', 'txt_host', f"{host}", "user", "session", prefix=False)
        tools_gw.set_config_parser('i18n_generator', 'txt_port', f"{port}", "user", "session", prefix=False)
        tools_gw.set_config_parser('i18n_generator', 'txt_db', f"{db}", "user", "session", prefix=False)
        tools_gw.set_config_parser('i18n_generator', 'txt_user', f"{user}", "user", "session", prefix=False)
        tools_gw.set_config_parser('i18n_generator', 'chk_py_msg', f"{py_msg}", "user", "session", prefix=False)
        tools_gw.set_config_parser('i18n_generator', 'chk_i18n_files', f"{i18n_msg}", "user", "session", prefix=False)
        tools_gw.set_config_parser('i18n_generator', 'chk_relative_langs', f"{relative_langs}", "user", "session", prefix=False)

    def _load_user_values(self):
        """
        Load last selected user values
            :return: Dictionary with values
        """

        host = tools_gw.get_config_parser('i18n_generator', 'txt_host', "user", "session", False)
        port = tools_gw.get_config_parser('i18n_generator', 'txt_port', "user", "session", False)
        db = tools_gw.get_config_parser('i18n_generator', 'txt_db', "user", "session", False)
        user = tools_gw.get_config_parser('i18n_generator', 'txt_user', "user", "session", False)
        py_msg = tools_gw.get_config_parser('i18n_generator', 'chk_py_msg', "user", "session", False)
        i18n_msg = tools_gw.get_config_parser('i18n_generator', 'chk_i18n_files', "user", "session", False)
        relative_langs = tools_gw.get_config_parser('i18n_generator', 'chk_relative_langs', "user", "session", False)

        tools_qt.set_widget_text(self.dlg_qm, 'txt_host', host)
        tools_qt.set_widget_text(self.dlg_qm, 'txt_port', port)
        tools_qt.set_widget_text(self.dlg_qm, 'txt_db', db)
        tools_qt.set_widget_text(self.dlg_qm, 'txt_user', user)
        tools_qt.set_checked(self.dlg_qm, self.dlg_qm.chk_py_msg, py_msg)
        tools_qt.set_checked(self.dlg_qm, self.dlg_qm.chk_i18n_files, i18n_msg)
        tools_qt.set_checked(self.dlg_qm, self.dlg_qm.chk_relative_langs, relative_langs)

    # --- Database connection ---

    def _init_db(self, host, port, db, user, password):
        """ Initializes database connection """

        try:
            self.conn_i18n = psycopg2.connect(database=db, user=user, port=port, password=password, host=host)
            self.cursor_i18n = self.conn_i18n.cursor(cursor_factory=psycopg2.extras.DictCursor)
            status = True
        except psycopg2.DatabaseError as e:
            self.last_error = e
            status = False

        return status

    def _close_db(self):
        """ Close database connection """

        try:
            status = True
            if self.cursor_i18n:
                self.cursor_i18n.close()
            if self.conn_i18n:
                self.conn_i18n.close()
            del self.cursor_i18n
            del self.conn_i18n
        except Exception as e:
            self.last_error = e
            status = False

        return status

    def _commit(self):
        """ Commit current database transaction """
        self.conn_i18n.commit()

    def _rollback(self):
        """ Rollback current database transaction """
        self.conn_i18n.rollback()

    def _get_rows(self, sql, commit=False):
        """ Get multiple rows from selected query """

        self.last_error = None
        rows = None
        try:
            self.cursor_i18n.execute(sql)
            rows = self.cursor_i18n.fetchall()
            if commit:
                self._commit()
        except Exception as e:
            self.last_error = e
            if commit:
                self._rollback()
            rows = []
        return rows

    def _replace_invalid_characters(self, param):
        """
        This function replaces the characters that break JSON messages
         (", new line, etc.)
            :param param: The text to fix (String)
        """
        param = param.replace("\"", "''")
        param = param.replace("\r", "")
        param = param.replace("\n", " ")

        return param

    def _replace_invalid_quotation_marks(self, param):
        """
        This function replaces the characters that break JSON messages
         (')
            :param param: The text to fix (String)
        """
        param = re.sub(r"(?<!')'(?!')", "''", param)

        return param

    def _create_path_dic(self):

        self.path_dic = {
            "i18n_ws": {
                "path": f"{self.plugin_dir}{os.sep}dbmodel{os.sep}schemas{os.sep}main{os.sep}ws{os.sep}final_pass{os.sep}i18n{os.sep}{self.language}{os.sep}",
                "name": f"{self.language}.sql",
                "project_type": ["ws", "utils"],
                "checkbox": self.dlg_qm.chk_i18n_files,
                "tables": list(_MAIN_WS_UD_TABLES),
            },
            "i18n_ud": {
                "path": f"{self.plugin_dir}{os.sep}dbmodel{os.sep}schemas{os.sep}main{os.sep}ud{os.sep}final_pass{os.sep}i18n{os.sep}{self.language}{os.sep}",
                "name": f"{self.language}.sql",
                "project_type": ["ud", "utils"],
                "checkbox": self.dlg_qm.chk_i18n_files,
                "tables": list(_MAIN_WS_UD_TABLES),
            },
            "am": {
                "path": f"{self.plugin_dir}{os.sep}dbmodel{os.sep}schemas{os.sep}addon{os.sep}am{os.sep}final_pass{os.sep}i18n{os.sep}{self.language}{os.sep}",
                "name": f"{self.language}.sql",
                "project_type": ["am"],
                "checkbox": self.dlg_qm.chk_am_files,
                "tables": ["dbconfig_engine", "dbconfig_form_tableview", "su_basic_tables"]
            },
            "cm": {
                "path": f"{self.plugin_dir}{os.sep}dbmodel{os.sep}schemas{os.sep}addon{os.sep}cm{os.sep}final_pass{os.sep}i18n{os.sep}{self.language}{os.sep}",
                "name": f"{self.language}.sql",
                "project_type": ["cm"],
                "checkbox": self.dlg_qm.chk_cm_files,
                "tables": ["dbconfig_form_fields", "dbconfig_form_tabs", "dbconfig_param_system",
                             "dbtypevalue", "dbconfig_form_fields_json", "dbtable", "dbconfig_form_tableview", "dbfprocess"]
            }
        }

    # endregion
