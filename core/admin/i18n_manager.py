"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import os
import re
import json
import psycopg2
import psycopg2.extras
from functools import partial
from itertools import product
import sys
from collections import defaultdict
from typing import List, Dict, Any


from ..ui.ui_manager import GwSchemaI18NManagerUi
from ..utils import tools_gw
from ...libs import lib_vars, tools_qt, tools_qgis, tools_db
from qgis.PyQt.QtWidgets import QApplication


class GwSchemaI18NManager:

    def __init__(self):
        self.plugin_dir = lib_vars.plugin_dir
        self.schema_name = lib_vars.schema_name
        self.project_type_selected = None
        self.no_beautify_keys = []
        self.primary_keys_no_project_type_i18n = []
        self.primary_keys_no_project_type_org = []
        self.values_en_us = []
        self.conflict_project_type = []
        self.schema_i18n = "multilang"
        self.delete_old_keys = False
        self.schemas = []
        self.all_schemas_org = []

    def init_dialog(self):
        """ Constructor """

        self.dlg_qm = GwSchemaI18NManagerUi(self)  # Initialize the UI
        tools_gw.load_settings(self.dlg_qm)
        self._load_user_values()  # keep values
        self.dev_commit = tools_gw.get_config_parser('system', 'force_commit', "user", "init", prefix=True)
        self.dlg_qm.btn_search.setEnabled(False)
        self._set_signals()  # Set all the signals to wait for response

        tools_gw.open_dialog(self.dlg_qm, dlg_name='admin_i18n_manager')

    def _set_signals(self):
        # Mysteriously without the partial the function check_connection is not called
        self.dlg_qm.btn_connection.clicked.connect(partial(self._check_connection))
        self.dlg_qm.btn_search.clicked.connect(self._update_i18n_datbase)
        self.dlg_qm.btn_close.clicked.connect(partial(tools_gw.close_dialog, self.dlg_qm))
        self.dlg_qm.btn_close.clicked.connect(partial(self._close_db_i18n))
        self.dlg_qm.btn_close.clicked.connect(partial(self._close_db_org))
        self.dlg_qm.rejected.connect(self._save_user_values)
        self.dlg_qm.rejected.connect(self._close_db_org)
        self.dlg_qm.rejected.connect(self._close_db_i18n)
        self.dlg_qm.chk_all.clicked.connect(self._check_all)

    def _check_all(self):
        if not tools_qt.is_checked(self.dlg_qm, self.dlg_qm.chk_all):
            return

        tools_qt.set_checked(self.dlg_qm, self.dlg_qm.chk_db_dialogs, True)
        tools_qt.set_checked(self.dlg_qm, self.dlg_qm.chk_am_dialogs, True)
        tools_qt.set_checked(self.dlg_qm, self.dlg_qm.chk_cm_dialogs, True)
        tools_qt.set_checked(self.dlg_qm, self.dlg_qm.chk_py_messages, True)
        tools_qt.set_checked(self.dlg_qm, self.dlg_qm.chk_py_dialogs, True)
        tools_qt.set_checked(self.dlg_qm, self.dlg_qm.chk_for_su_tables, True)

    def _load_user_values(self):
        """
        Load last selected user values
            :return: Dictionary with values
        """

        host = tools_gw.get_config_parser('i18n_generator', 'qm_lang_host', "user", "session", False)
        port = tools_gw.get_config_parser('i18n_generator', 'qm_lang_port', "user", "session", False)
        db = tools_gw.get_config_parser('i18n_generator', 'qm_lang_db', "user", "session", False)
        user = tools_gw.get_config_parser('i18n_generator', 'qm_lang_user', "user", "session", False)
        tools_qt.set_widget_text(self.dlg_qm, 'txt_host', host)
        tools_qt.set_widget_text(self.dlg_qm, 'txt_port', port)
        tools_qt.set_widget_text(self.dlg_qm, 'txt_db', db)
        tools_qt.set_widget_text(self.dlg_qm, 'txt_user', user)

    def _check_connection(self):
        """ Check connection to database """

        self.dlg_qm.lbl_info.clear()
        self._close_db_org()
        # Connection with origin db
        host_i18n = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_host)
        port_i18n = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_port)
        db_i18n = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_db)
        user_i18n = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_user)
        password_i18n = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_pass)
        status_i18n = self._init_db_i18n(host_i18n, port_i18n, db_i18n, user_i18n, password_i18n)
        status_org = self._init_db_org()

        # Send messages
        if not status_i18n:
            self.dlg_qm.btn_search.setEnabled(False)
            self.dlg_qm.lbl_info.clear()
            msg = "Error connecting to i18n database"
            tools_qt.show_info_box(msg)
            QApplication.processEvents()
            return
        elif host_i18n != '188.245.226.42' and port_i18n != '5432' and db_i18n != 'giswater':
            self.dlg_qm.btn_search.setEnabled(False)
            self.dlg_qm.lbl_info.clear()
            msg = "Error connecting to i18n dataabse"
            tools_qt.show_info_box(msg)
            QApplication.processEvents()
            return
        elif 'password authentication failed' in str(self.last_error):
            self.dlg_qm.btn_search.setEnabled(False)
            self.dlg_qm.lbl_info.clear()
            msg = "Incorrect user or password"
            tools_qt.show_info_box(msg)
            QApplication.processEvents()
            return
        else:
            self.dlg_qm.btn_search.setEnabled(True)
            self.dlg_qm.lbl_info.clear()
            msg = "Successful connection to {0} database"
            msg_params = (db_i18n,)
            tools_qt.set_widget_text(self.dlg_qm, 'lbl_info', msg, msg_params)
            QApplication.processEvents()

        if not status_org:
            self.dlg_qm.btn_search.setEnabled(False)
            self.dlg_qm.lbl_info.clear()
            msg = "Error connecting to origin database"
            tools_qt.show_info_box(msg)
            QApplication.processEvents()
            return
        elif 'password authentication failed' in str(self.last_error):
            self.dlg_qm.btn_search.setEnabled(False)
            self.dlg_qm.lbl_info.clear()
            msg = "Error connecting to origin database"
            tools_qt.show_info_box(msg)
            QApplication.processEvents()
            return

    def _init_db_i18n(self, host, port, db, user, password):
        """Initializes database connection"""

        try:
            self.conn_i18n = psycopg2.connect(database=db, user=user, port=port, password=password, host=host)
            self.cursor_i18n = self.conn_i18n.cursor(cursor_factory=psycopg2.extras.DictCursor)

            return True
        except psycopg2.DatabaseError as e:
            self.last_error = e
            return False

    def _init_db_org(self):
        """Initializes database connection"""

        try:
            self.conn_org = tools_db.dao
            self.cursor_org = tools_db.dao.get_cursor()
            return True
        except psycopg2.DatabaseError as e:
            self.last_error = e
            return False

    def _close_db_org(self):
        """ Close database connection """

        try:
            if self.cursor_org:
                self.cursor_org.close()
            if self.conn_org:
                self.conn_org.close()
            del self.cursor_org
            del self.conn_org
        except Exception as e:
            self.last_error = e

    def _close_db_i18n(self):
        """ Close database connection """
        try:
            if self.cursor_i18n:
                self.cursor_i18n.close()
            if self.conn_i18n:
                self.conn_i18n.close()
            del self.cursor_i18n
            del self.conn_i18n
        except Exception as e:
            self.last_error = e

    def _save_user_values(self):
        """ Save selected user values """

        host = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_host, return_string_null=False)
        port = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_port, return_string_null=False)
        db = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_db, return_string_null=False)
        user = tools_qt.get_text(self.dlg_qm, self.dlg_qm.txt_user, return_string_null=False)
        py_msg = False
        db_msg = False
        tools_gw.set_config_parser('i18n_generator', 'qm_lang_host', f"{host}", "user", "session", prefix=False)
        tools_gw.set_config_parser('i18n_generator', 'qm_lang_port', f"{port}", "user", "session", prefix=False)
        tools_gw.set_config_parser('i18n_generator', 'qm_lang_db', f"{db}", "user", "session", prefix=False)
        tools_gw.set_config_parser('i18n_generator', 'qm_lang_user', f"{user}", "user", "session", prefix=False)
        tools_gw.set_config_parser('i18n_generator', 'qm_lang_py_msg', f"{py_msg}", "user", "session", prefix=False)
        tools_gw.set_config_parser('i18n_generator', 'qm_lang_db_msg', f"{db_msg}", "user", "session", prefix=False)

    def pass_schema_info(self, schema_info):
        self.project_type = schema_info['project_type']
        self.project_epsg = schema_info['project_epsg']
        self.project_version = schema_info['project_version']

    # endregion
    def _update_i18n_datbase(self):
        """ Determine which part of the database update (ws, ud, am, pyhton...) """
        self.project_types = []
        self.schemas = []

        if tools_qt.is_checked(self.dlg_qm, self.dlg_qm.chk_db_dialogs):
            self.project_types.extend(["ws", "ud"])
        if tools_qt.is_checked(self.dlg_qm, self.dlg_qm.chk_am_dialogs):
            self.project_types.extend(["am"])
        if tools_qt.is_checked(self.dlg_qm, self.dlg_qm.chk_cm_dialogs):
            self.project_types.extend(["cm"])

        self.py_messages = tools_qt.is_checked(self.dlg_qm, self.dlg_qm.chk_py_messages)
        self.py_dialogs = tools_qt.is_checked(self.dlg_qm, self.dlg_qm.chk_py_dialogs)

        if self.project_types:
            self._update_db_tables()
            self.schemas.extend(self.all_schemas_org)

        if self.py_messages:
            self._update_py_messages()
            self.schemas.append("Python")

        if self.py_dialogs:
            self._update_py_dialogs()
            self.schemas.append("Dialogs")

        if self.schemas:
            self._update_cat_version()

        msg = "Process completed"
        tools_qt.set_widget_text(self.dlg_qm, 'lbl_info', msg)

    # region Missing DB Dialogs

    def _update_db_tables(self):
        """ Update the database tables (ws or ud or am or cm or su_tables)"""

        # Check for basic information
        self.check_for_su_tables = tools_qt.is_checked(self.dlg_qm, self.dlg_qm.chk_for_su_tables)
        major_version = tools_qgis.get_major_version(plugin_dir=self.plugin_dir).replace(".", "")
        text_error = ''
        no_repeat_table = []

        # Loop through the selected project types (ws, ud...)
        for self.project_type in self.project_types:
            # Get the tables to update
            tables_i18n, sutables_i18n = self.tables_dic(self.project_type)

            # Get the schema to update
            self.schema_org = self.project_type
            if self.project_type not in ["am", "cm"]:
                self.schema_org = f"{self.project_type}{major_version}_trans"

            if self.schema_org not in self.all_schemas_org:
                self.all_schemas_org.append(self.schema_org)

            # Check if the schema exists
            schema_exists = self._detect_schema(self.schema_org)
            if not schema_exists:
                msg = "The schema ({0}) does not exists"
                msg_params = (self.schema_org,)
                tools_qt.show_info_box(msg, msg_params=msg_params)
                return

            # Check if the su_tables are needed
            if self.check_for_su_tables:
                tables_i18n.extend(sutables_i18n)

            # Check if the languages are correct
            correct_lang = self._verify_lang()
            if not correct_lang:
                msg = "Incorrect languages, make sure to have the giswater project in english"
                tools_qt.show_info_box(msg)
                continue

            # Loop through the tables to update
            text_error += f'\n{self.project_type}:\n'
            self.dlg_qm.lbl_info.clear()
            for table_i18n in tables_i18n:
                table_i18n = f"{self.schema_i18n}.{table_i18n}"

                # Check if the table has already been determined as not existing
                if table_i18n not in no_repeat_table:
                    # Check if the table exists
                    table_exists = self.detect_table_func(table_i18n, self.cursor_i18n)
                    if not table_exists:
                        msg = "The table ({0}) does not exists"
                        msg_params = (table_i18n,)
                        tools_qt.show_info_box(msg, msg_params=msg_params)
                        no_repeat_table.append(table_i18n)

                    # Change the table layout
                    self._change_table_lyt(table_i18n.split(".")[1])

                    # Update the table
                    text_error += self._update_tables(table_i18n)

                    # check for all primary keys reapeted, but project_types
                    if self.project_type == 'ud':
                        text_error += self._rewrite_project_type(table_i18n)
                    self._vacuum_commit(table_i18n, self.conn_i18n, self.cursor_i18n)

        self.dlg_qm.lbl_info.clear()
        self.save_and_open_text_error(text_error)

    def _update_tables(self, table_i18n):
        """ Update the table """

        # Get the original table
        tables_org = self._find_table_org(table_i18n)

        # Loop through the original tables and act according to the type of data inside (declared in the name)
        # Set the query message
        query = ""
        for table_org in tables_org:
            table_exists = self.detect_table_func(f"{self.schema_org}.{table_org}", self.cursor_org)
            if not table_exists:
                msg = "The table ({0}) does not exists"
                msg_params = (table_i18n,)
                tools_qt.show_info_box(msg, msg_params=msg_params)
                return f"The table ({table_org}) does not exists\n"
            if "json" in table_i18n:
                query += self._json_update(table_i18n, table_org)
            elif "dbconfig_form_fields_feat" in table_i18n:
                query += self._dbconfig_form_fields_feat_update(table_i18n)
            else:
                query += self._update_any_table(table_i18n, table_org)

        # Determine the return message acording to the query message
        if query == '':
            text_return = f'{table_i18n.split(".")[1]}: 1- No update needed. '
        else:
            try:
                self.cursor_i18n.execute(query)
                self.conn_i18n.commit()
                text_return = f'{table_i18n.split(".")[1]}: 1- Succesfully updated table. '
            except Exception as e:
                self.conn_i18n.rollback()
                text_return = f"\nAn error occured while translating {table_i18n}: {e}\n"
        if self.project_type != 'ud':
            text_return += "\n"
        return text_return

    def _update_any_table(self, table_i18n, table_org):
        """Insert and update rows in a classical translation table."""

        # Get the rows to update
        diff_rows, columns_i18n, rows_org = self._rows_to_update(table_i18n, table_org)

        if not diff_rows and table_i18n != "multilang.dbstyle":
            return ""

        # Get the columns to insert
        columns_org = diff_rows[0].keys()
        columns_to_insert = ", ".join(columns_i18n)

        # Get the primary keys
        pk_columns = [col for col in columns_i18n if col not in self.values_en_us]
        if "su_feature" in table_i18n:
            pk_columns.append("lb_en_us")
        pk_columns_str = ", ".join(pk_columns)

        # Insert the rows
        query_insert = ""
        if diff_rows:
            for row in diff_rows:
                values = []
                update_values = []

                # Get the values to insert
                for col in columns_org:
                    val = row.get(col)
                    values.append("NULL" if val in [None, ''] else "'" + str(val).replace("'", "''") + "'")
                # Get the values to update
                for col in self.values_en_us:
                    update_values.append(f"{col} = EXCLUDED.{col}")

                # Get the query to insert
                values_str = ", ".join(values)
                update_values_str = ", ".join(update_values)
                query_insert += f"""INSERT INTO {table_i18n} ({columns_to_insert}) VALUES ({values_str})
                                ON CONFLICT ({pk_columns_str}) DO UPDATE SET {update_values_str};\n"""

        if table_i18n == "multilang.dbstyle":
            pk_column_org = ["styleconfig_id", "layername"]
            pk_column_i18n = ["source", "layername"]

            # Group rows_org by styleconfig_id to collect all valid hints per id
            hints_per_id = defaultdict(set)
            rows_per_id = {}
            for row in rows_org:
                sid = f"{row['layername']}_{row['styleconfig_id']}"
                hints_per_id[sid].add(row['hint'])
                rows_per_id[sid] = row  # Keep one row to access other columns if needed

            # Check each id
            for sid, valid_hints in hints_per_id.items():
                row = rows_per_id[sid]
                # Get existing hints from DB
                existing_hints = self.get_hints(table_i18n, row, pk_column_org, pk_column_i18n)

                # Calculate hints to delete
                hints_to_delete = existing_hints - valid_hints

                if hints_to_delete:
                    query_insert += self.get_hints(table_i18n, row, pk_column_org, pk_column_i18n, hints_to_delete)

        return query_insert

    def _get_columns_to_compare(self, table_i18n, table_org):
        """ Get the columns and rows to compare """

        # Set the columns and rows to compare
        # Columns_i18n (columns translation DB), Colums_org (columns original DB), names (colums to translate in original DB)
        if 'dbconfig_form_fields' in table_i18n:
            columns_i18n = ["formname", "formtype", "tabname", "source", "lb_en_us", "tt_en_us"]
            columns_org = ["formname", "formtype", "tabname", "columnname", "label", "tooltip"]

        elif 'dbparam_user' in table_i18n:
            columns_i18n = ["source", "lb_en_us", "tt_en_us"]
            columns_org = ["id", "label", "descript"]

        elif 'dbconfig_param_system' in table_i18n:
            columns_i18n = ["source", "lb_en_us", "tt_en_us"]
            columns_org = ["parameter", "label", "descript"]

        elif 'dbconfig_typevalue' in table_i18n:
            columns_i18n = ["formname", "source", "tt_en_us"]
            columns_org = ["typevalue", "id", "idval"]

        elif 'dblabel' in table_i18n:
            columns_i18n = ["CAST(source AS INTEGER) AS source", "vl_en_us"]
            columns_org = ["id", "idval"]

        elif 'dbmessage' in table_i18n:
            columns_i18n = ["CAST(source AS INTEGER) AS source", "ms_en_us", "ht_en_us"]
            columns_org = ["id", "error_message", "hint_message"]

        elif 'dbfprocess' in table_i18n:
            columns_i18n = ["CAST(source AS INTEGER) AS source", "ex_en_us", "in_en_us", "na_en_us"]
            columns_org = ["fid", "except_msg", "info_msg", "fprocess_name"]

        elif 'dbconfig_csv' in table_i18n:
            columns_i18n = ["CAST(source AS INTEGER) AS source", "al_en_us", "ds_en_us"]
            columns_org = ["fid", "alias", "descript"]

        elif 'dbconfig_form_tabs' in table_i18n:
            columns_i18n = ["formname", "source", "lb_en_us", "tt_en_us"]
            columns_org = ["formname", "tabname", "label", "tooltip"]

        elif 'dbconfig_report' in table_i18n:
            columns_i18n = ["CAST(source AS INTEGER) AS source", "al_en_us", "ds_en_us"]
            columns_org = ["id", "alias", "descript"]

        elif 'dbconfig_toolbox' in table_i18n:
            columns_i18n = ["CAST(source AS INTEGER) AS source", "al_en_us", "ob_en_us"]
            columns_org = ["id", "alias", "observ"]

        elif 'dbfunction' in table_i18n:
            columns_i18n = ["CAST(source AS INTEGER) AS source", "ds_en_us"]
            columns_org = ["id", "descript"]

        elif 'dbtypevalue' in table_i18n:
            columns_i18n = ["typevalue", "source", "vl_en_us", "ds_en_us"]
            columns_org = ["typevalue", "id", "idval", "descript"]

        elif 'dbconfig_form_tableview' in table_i18n:
            columns_i18n = ["columnname", "source", "al_en_us"]
            columns_org = ["columnname", "objectname", "alias"]

        elif 'dbtable' in table_i18n:
            columns_i18n = ["source", "ds_en_us", "al_en_us"]
            columns_org = ["id", "descript", "alias"]

        elif 'dbplan_price' in table_i18n:
            columns_i18n = ["source", "ds_en_us", "tx_en_us", "pr_en_us"]
            columns_org = ["id", "descript", "text", "price"]

        elif 'dbconfig_visit_parameter' in table_i18n:
            columns_i18n = ["source", "ds_en_us"]
            columns_org = ["id", "descript"]

        # Update the su_basic_tables table (It has a different format, more than one table_org)
        elif 'su_basic_tables' in table_i18n:
            columns_i18n = ["source", "na_en_us"]
            columns_org = ["id", "name"]
            if table_org == "value_state" and self.project_type in ["ud", "ws"]:
                columns_i18n.append("ob_en_us")
                columns_org = ["id", "name", "observ"]
            elif self.project_type == "am":
                columns_org = ["id", "idval"]

        elif 'su_feature' in table_i18n:
            columns_i18n = ["feature_class", "feature_type", "lb_en_us", "ds_en_us"]
            columns_org = ["feature_class", "feature_type", "id", "descript"]

        elif 'dbconfig_engine' in table_i18n:
            columns_i18n = ["parameter", "method", "lb_en_us", "ds_en_us", "pl_en_us"]
            columns_org = ["parameter", "method", "label", "descript", "placeholder"]

        elif 'dbstyle' in table_i18n:
            columns_i18n = ["source", "layername", "org_text", "hint", "lb_en_us"]
            columns_org = ["styleconfig_id", "layername", "stylevalue"]

        columns_i18n = columns_i18n + ["project_type", "source_code", "context"]

        return columns_i18n, columns_org

    # endregion
    # region functions to get the rows to update
    def _rows_to_update(self, table_i18n, table_org):
        """Get the rows to update."""

        self.primary_keys_no_project_type_i18n = []
        self.values_en_us = []
        self.conflict_project_type = []

        # Get the columns and rows to compare
        columns_i18n, columns_org = self._get_columns_to_compare(table_i18n, table_org)
        rows_i18n, rows_org = self._get_rows_to_compare(table_i18n, columns_i18n, columns_org, table_org)

        if table_i18n == "multilang.dbstyle":
            rows_org = self._get_dbstyle_rows(rows_org)
            self.values_en_us.extend(["org_text"])  # Important because we extract the en_us values from the org_text, so it is needed to control a correct behaivor
            columns_org.extend(["hint", "lb_en_us"])

        # Rewrite the columns to get the name. Also determine diferent kinds of columns useful in the future
        for i, column in enumerate(columns_i18n):
            if "CAST(" in column:
                columns_i18n[i] = column[5:].split(" ")[0]
            if column not in ["project_type"]:
                self.conflict_project_type.append(columns_i18n[i])
                if columns_i18n[i] in self.values_en_us:
                    continue
                elif "en_us" not in columns_i18n[i]:
                    self.primary_keys_no_project_type_i18n.append(columns_i18n[i])
                else:
                    self.values_en_us.append(columns_i18n[i])

        # Clean the rows i18n (remove None values and unify project_type)
        if rows_i18n:
            cleaned_i18n = []
            for i, row in enumerate(rows_i18n):
                clean_row = row.copy()
                for col in columns_i18n:
                    col_name = col
                    value = clean_row.get(col_name, '')
                    if value is None:
                        clean_row[col_name] = ''
                    if col_name == "project_type" and ((value == "utils" and self.project_type in ['ws', 'ud']) or value is None):
                        clean_row[col_name] = self.project_type
                    if self.project_type == "cm" and col_name == "source" and table_i18n == "dbtable":
                        values = value.split("_")
                        clean_row[col_name] = values[-2] + "_" + values[-1]
                cleaned_i18n.append(clean_row)
            rows_i18n = cleaned_i18n

        # Clean the rows org (add extra columns and remove None values)
        if rows_org:
            cleaned_org = []
            extra_columns = {"project_type": self.project_type, "source_code": "giswater", "context": table_org}
            for row in rows_org:
                clean_row = row.copy()
                for key, value in extra_columns.items():
                    columns_org.append(key)
                    clean_row[key] = value
                for col in columns_org:
                    value = clean_row.get(col, '')
                    if value is None:
                        clean_row[col] = ''
                    if self.project_type == "cm" and col == "id" and table_org == "sys_table":
                        values = value.split("_")
                        clean_row[col] = values[-2] + "_" + values[-1]
                cleaned_org.append(clean_row)
            rows_org = cleaned_org

        # Efficient diff using set of tuples
        diff_rows = self._set_operation_on_dict(rows_org, rows_i18n, op='-', compare='values')

        return diff_rows, columns_i18n, rows_org

    def _get_rows_to_compare(self, table_i18n, columns_i18n, columns_org, table_org):
        """ Get the rows to compare """

        # Create the query to get the rows from the i18n table
        columns = ", ".join(columns_i18n)
        query = f"SELECT {columns} FROM {table_i18n}"
        if self.project_type in ["cm", "am"]:
            query += f" WHERE project_type = '{self.project_type}' OR project_type = 'utils'"
        query += ";"
        rows_i18n = self._get_rows(query, self.cursor_i18n)

        # Create the query to get the rows from the original table
        columns = ", ".join(columns_org)
        query = f"SELECT {columns} FROM {self.schema_org}.{table_org};"
        rows_org = self._get_rows(query, self.cursor_org)

        return rows_i18n, rows_org

    # endregion
    # region Json

    def _json_update(self, table_i18n, table_org):
        """ Update the table with the json format """

        if table_i18n.split('.')[1] == "dbconfig_form_fields_json":
            self.conflict_project_type = ["source_code", "context", "formname", "formtype", "tabname", "source", "hint", "lb_en_us"]
            pk_column_org = ["formname", "formtype", "tabname", "columnname"]
            pk_column_i18n = ["formname", "formtype", "tabname", "source"]
        elif table_i18n.split('.')[1] == "dbjson":
            self.conflict_project_type = ["source_code", "context", "hint", "source", "lb_en_us"]
            pk_column_org = ["id"]
            pk_column_i18n = ["source"]

        self.primary_keys_no_project_type_i18n = [column for column in self.conflict_project_type if "en_us" not in column]
        self.values_en_us = [column for column in self.conflict_project_type if ("en_us" in column or column in ["text"])]

        # Set the column to update in the table_org (filterparam, inputparams, widgetcontrols)
        column = ""
        if table_org == 'config_report':
            column = "filterparam"
        elif table_org == 'config_toolbox':
            column = 'inputparams'
        elif table_org == 'config_form_fields':
            column = 'widgetcontrols'

        self.translatable_keys = ['label', 'tooltip', 'placeholder', 'text', 'comboNames', 'vdefault_value']
        
        # Build conditions to check if key is not found within the column text
        where_conditions = []
        for key in self.translatable_keys:
            where_conditions.append(f"""{column}::text ILIKE '%{key}":%'""")
        where_clause = " OR ".join(where_conditions) if where_conditions else "TRUE"

        query = f"""SELECT {', '.join(pk_column_org)}, {column} FROM {self.schema_org}.{table_org} WHERE {where_clause}"""
        rows_org = self._get_rows(query, self.cursor_org)

        # Prepare batch insert
        all_values = []
        all_hints_used = []
        
        for row in rows_org:
            if row[column] in [None, "", "None"]:
                continue
                
            # Cache the JSON dump
            text_json = json.dumps(row[column]).replace("'", "''")
            
            # Get all translatable strings at once
            datas = self.extract_and_update_strings(row[column])
            hints_used = set()
            
            # Process all strings in this row
            for i, data in enumerate(datas):
                for key, text in data.items():
                    if isinstance(text, list):
                        text = ", ".join(text)
                    elif not isinstance(text, str):
                        continue
                    
                    safe_text = text.replace("'", "''")
                    hint = f"{key}_{i}"
                    hints_used.add(f"'{hint}'")
                    
                    # Prepare values tuple
                    if "config_form_fields" in table_i18n:
                        values = (
                            'giswater',
                            self.project_type,
                            table_org,
                            row['formname'],
                            row['formtype'],
                            row['tabname'],
                            row['columnname'],
                            hint,
                            text_json,
                            safe_text
                        )
                    else:
                        values = (
                            'giswater',
                            self.project_type,
                            table_org,
                            hint,
                            text_json,
                            row['id'],
                            safe_text
                        )
                    all_values.append(values)
            
            # Store hints for later deletion
            hints_i18n = self.get_hints(table_i18n, row, pk_column_org, pk_column_i18n)
            hints_to_delete = hints_i18n - hints_used
            if hints_to_delete:
                all_hints_used.append((row, hints_to_delete))
        
        # Generate single batch insert query
        if "config_form_fields" in table_i18n:
            columns = ['source_code', 'project_type', 'context', 'formname', 'formtype', 'tabname', 'source', 'hint', 'text', 'lb_en_us']
            conflict_keys = ['source_code', 'project_type', 'context', 'formname', 'formtype', 'tabname', 'source', 'hint']
        else:
            columns = ['source_code', 'project_type', 'context', 'hint', 'text', 'source', 'lb_en_us']
            conflict_keys = ['source_code', 'project_type', 'context', 'hint', 'source']
        
        # Build the VALUES part with proper type casting
        values_parts = []
        for values in all_values:
            value_list = []
            for i, val in enumerate(values):
                if columns[i] == 'text':
                    value_list.append(f"'{val}'::jsonb")
                else:
                    value_list.append(f"'{val}'")
            values_parts.append(f"({', '.join(value_list)})")
            
        # Construct final query
        query = f"""
            INSERT INTO {table_i18n} ({', '.join(columns)})
            VALUES {', '.join(values_parts)}
            ON CONFLICT ({', '.join(conflict_keys)})
            DO UPDATE SET
                text = EXCLUDED.text,
                lb_en_us = EXCLUDED.lb_en_us;
        """
        
        # Add deletion queries for unused hints
        for row, hints_to_delete in all_hints_used:
            query += self.get_hints(table_i18n, row, pk_column_org, pk_column_i18n, hints_to_delete)

        print(query)
        return query

    def get_hints(self, table_i18n, row, pk_column_org, pk_column_i18n, hints_to_delete=None):
        """ Delete the rows that already exist in the table """
        where_conditions = ["source_code = 'giswater'", f"project_type = '{self.project_type}'", f"context = '{table_i18n.split('.')[1]}'"]
        for i, pk in enumerate(pk_column_org):
            if row.get(pk) is None:
                where_conditions.append(f"{pk} IS NULL")
            else:
                # Avoid nested f-string with both single and double quotes
                escaped_value = str(row[pk]).replace("'", "''")
                where_conditions.append(f"{pk_column_i18n[i]} = '{escaped_value}'")

        if hints_to_delete:
            # Make sure hints are properly quoted for SQL
            quoted_hints = [f"'{hint}'" for hint in hints_to_delete]
            where_conditions.append(f"hint IN ({','.join(quoted_hints)})")
            where_clause = " AND ".join(where_conditions)
            query_delete = f"""DELETE FROM {table_i18n} WHERE {where_clause};"""
            return query_delete
        
        where_clause = " AND ".join(where_conditions)
        query = f"""SELECT hint FROM {table_i18n} WHERE {where_clause};"""

        self.cursor_i18n.execute(query)
        hints_i18n = self.cursor_i18n.fetchall()
        hints_i18n_set = set([row[0] for row in hints_i18n])
        return hints_i18n_set

    # endregion

    # region Dbstyle

    def _get_dbstye_values(self, stylevalue) -> dict:
        """ Get the lines of the dbstyle """
        result = {}
        i = 1
        for line in stylevalue.split('\n'):
            match = re.search(r'rule.*label="([^"]*)"', line)
            if match:
                lb_en_us = match.group(1)
                result[f"label_{i}"] = lb_en_us
                i += 1
        return result

    def _get_dbstyle_rows(self, rows_org):
        """ Update the table with the dbstyle format """
        result = []

        for row in rows_org:
            value = self._get_dbstye_values(row['stylevalue'])
            if value:
                for hint, lb_en_us in value.items():
                    new_row = row.copy()
                    new_row['hint'] = hint
                    new_row['lb_en_us'] = lb_en_us
                    result.append(new_row)
                    
        return result

    # endregion
    # region Config_form_fields_feat

    def _dbconfig_form_fields_feat_update(self, table_i18n):
        """ Update the table with the config_form_fields_feat format. Use an sql type program to do it """

        self.conflict_project_type = ["feature_type", "source_code", "context", "formtype", "tabname", "source", "lb_en_us", "tt_en_us"]
        self.primary_keys_no_project_type_i18n = [column for column in self.conflict_project_type if "en_us" not in column]
        self.values_en_us = [column for column in self.conflict_project_type if ("en_us" in column or column in ["text", "hint"])]

        schema = table_i18n.split('.')[0]
        table_org = f"{schema}.dbconfig_form_fields"
        query = f"""
            INSERT INTO {table_i18n}
            select distinct on (feature_type, project_type, source) *
            FROM (
                SELECT 'ARC' AS feature_type, *
                FROM {table_org}
                WHERE formtype = 'form_feature' AND (formname LIKE 've_arc%' OR formname = 've_arc')

                UNION

                SELECT 'NODE', *
                FROM {table_org}
                WHERE formtype = 'form_feature' AND (formname LIKE 've_node%' OR formname = 've_node')

                UNION

                SELECT 'CONNEC', *
                FROM {table_org}
                WHERE formtype = 'form_feature' AND (formname LIKE 've_connec%' OR formname = 've_connec')

                UNION

                SELECT 'GULLY', *
                FROM {table_org}
                WHERE formtype = 'form_feature' AND (formname LIKE 've_gully%' OR formname = 've_gully')

                UNION

                SELECT 'ELEMENT', *
                FROM {table_org}
                WHERE formtype = 'form_feature' AND (formname LIKE 've_element%' OR formname = 've_element')

                UNION

                SELECT 'LINK', *
                FROM {table_org}
                WHERE formtype = 'form_feature' AND (formname LIKE 've_link%' OR formname = 've_link')

                UNION

                SELECT 'FLWREG', *
                FROM {table_org}
                WHERE formtype = 'form_feature' AND (formname LIKE 've_flwreg%' OR formname = 've_flwreg')
            ) AS unioned
            ON CONFLICT (feature_type, source_code, project_type, context, formtype, tabname, source)
            DO UPDATE SET
                lb_en_us = EXCLUDED.lb_en_us,
                tt_en_us = EXCLUDED.tt_en_us;

            delete from {table_org}  where formtype = 'form_feature' and (formname like 've_arc%' or formname in ('ve_arc'));

            delete from {table_org} where formtype = 'form_feature' and (formname like 've_node%' or formname in ('ve_node'));

            delete from {table_org} where formtype = 'form_feature' and (formname like 've_connec%' or formname in ('ve_connec'));

            delete from {table_org} where formtype = 'form_feature' and (formname like 've_gully%' or formname in ('ve_gully'));

            delete from {table_org} where formtype = 'form_feature' and (formname like 've_element%' or formname in ('ve_element'));

            delete from {table_org} where formtype = 'form_feature'and (formname like 've_link%' or formname in ('ve_link'));

            delete from {table_org} where formtype = 'form_feature'  and (formname like 've_flwreg%' or formname in ('ve_flwreg'));
        """
        return query

    # endregion
    # region Rewrite Project_type

    def _rewrite_project_type(self, table):
        """Rewrite the project_type to the correct value"""

        if 'dbstyle' in table:
            if 'org_text' in self.conflict_project_type:
                self.conflict_project_type.remove('org_text')
            if 'org_text' in self.values_en_us:
                self.values_en_us.remove('org_text')

        # Determine which rows that although they share primary keys but different project_type must not be converted to utils
        text = self._update_fake_utils(table)
        if text:
            return text

        # Get the duplicated rows
        query = self._get_duplicates_rows(table)
        try:
            self.cursor_i18n.execute(query)
            duplicated_rows = self.cursor_i18n.fetchall()
        except Exception as e:
            return f"Error getting dupplicates (Rename proj.type): {e}\n\n"

        if duplicated_rows:
            # Get rows to delete and rows to update
            delete_query, update_query = self._update_project_type(table, duplicated_rows)

            # Delete the rows
            try:
                self.cursor_i18n.execute(delete_query)
                self.conn_i18n.commit()
            except Exception as e:
                self.conn_i18n.rollback()
                return f"Error deleting repeated rows (Rename proj.type): {e}\n\n"

            # Update the rows
            try:
                self.cursor_i18n.execute(update_query)
                self.conn_i18n.commit()
            except Exception as e:
                self.conn_i18n.rollback()
                return f"Error updating project_type (Rename proj.type): {e}, {update_query}\n\n\n\n {delete_query}"
        else:
            return "No repeated rows found (Rename proj.type)\n"

        return "Rows updated succesfully (Rename proj.type)\n"

    def _update_fake_utils(self, table):
        """Update labels of old utils rows"""

        values_en_us_ud = []
        values_en_us_ws = []
        values_en_us_utils = []

        fake_pks_ud = self._get_fake_primary_keys(table, "ud")
        if fake_pks_ud:
            values_en_us_ud = self._get_values_en_us(table, fake_pks_ud, "ud")

        fake_pks_ws = self._get_fake_primary_keys(table, "ws")
        if fake_pks_ws:
            values_en_us_ws = self._get_values_en_us(table, fake_pks_ws, "ws")

        fake_pks_utils = self._get_fake_primary_keys(table, "utils")
        if fake_pks_utils:
            values_en_us_utils = self._get_values_en_us(table, fake_pks_utils, "utils")

        if values_en_us_ud or values_en_us_ws or values_en_us_utils:
            new_values_en_us = self._set_operation_on_dict(values_en_us_ud, values_en_us_ws, op='&')
            delete_values_en_us = self._set_operation_on_dict(values_en_us_ud, values_en_us_ws, op='^')
            values_utils_to_ud = self._set_operation_on_dict(values_en_us_ws, delete_values_en_us, op='&')
            values_utils_to_ws = self._set_operation_on_dict(values_en_us_ud, delete_values_en_us, op='&')

            if new_values_en_us:
               self._update_values_en_us(table, new_values_en_us)

            if values_utils_to_ws:
                self._update_utils_values(table, values_utils_to_ws, 'ws')

            if values_utils_to_ud:
                self._update_utils_values(table, values_utils_to_ud, 'ud')

            if delete_values_en_us:
               self._delete_fake_utils(table, delete_values_en_us)

    def _get_values_en_us(self, table, fake_pks, project_type):
        """Get the values of the en_us column using a single query"""

        if not fake_pks:
            return []

        pk_columns = self.primary_keys_no_project_type_i18n
        all_columns = self.values_en_us + pk_columns if project_type != 'utils' else pk_columns + ['project_type']
        columns = ", ".join(all_columns)

        value_tuples = []
        for row in fake_pks:
            values = []
            for col in pk_columns:
                if row[col] is None:
                    values.append(f"{col} IS NULL")
                elif row[col].startswith("[{'") and row[col].endswith("}]") or row[col].startswith("{'") and row[col].endswith("}"):
                    values.append(f"{col} = $${row[col]}$$")
                else:
                    values.append(f"{col} = '{row[col]}'")
            values.append(f"project_type = '{project_type}'")
            value_tuples.append(f"({' AND '.join(values)})")

        where_clause = " OR ".join(value_tuples)

        query = f"SELECT {columns} FROM {table} WHERE {where_clause};"

        # Execute single query
        rows = self._get_rows(query, self.cursor_i18n)

        return rows

    def _update_utils_values(self, table, rows_values_en_us, project_type):
        """Update the project_type values when two similar rows (ws and utils) no longer have the same en_us value"""

        # Build WHERE clause from existing values
        clause_sql = []
        for row in rows_values_en_us:
            text = []
            for column in self.primary_keys_no_project_type_i18n:
                if row[column] is None:
                    text.append(f"{column} IS NULL")
                else:
                    escaped_value = str(row[column]).replace("'", "''")
                    text.append(f"{column} = '{escaped_value}'")
            clause_sql.append(f"({' AND '.join(text)} AND project_type = 'utils')")

        where_clause = ' OR '.join(clause_sql)

        # Fetch full matching rows
        query = f"SELECT * FROM {table} WHERE {where_clause}"
        complete_rows = self._get_rows(query, self.cursor_i18n)

        if not complete_rows:
            return  # Nothing to update

        # Build INSERT statement
        values_sql = []
        columns = list(complete_rows[0].keys())  # assumes all rows have the same keys

        for row in complete_rows:
            row_values = []
            for col in columns:
                if col == 'project_type':
                    val = project_type
                else:
                    val = row.get(col)
                if val is None:
                    row_values.append("NULL")
                else:
                    if col == 'text':
                        # Handle JSON data properly
                        json_str = json.dumps(val).replace("'", "''")
                        row_values.append(f"'{json_str}'::jsonb")
                    else:
                        escaped_val = str(val).replace("'", "''")
                        row_values.append(f"'{escaped_val}'")
            values_sql.append(f"({', '.join(row_values)})")

        values_block = ',\n'.join(values_sql)
        query = f"INSERT INTO {table} ({', '.join(columns)}) VALUES {values_block} ON CONFLICT DO NOTHING"

        self.cursor_i18n.execute(query)
        self.conn_i18n.commit()

    def _update_values_en_us(self, table, rows_values_en_us):
        """Bulk update the values of the en_us columns for rows with project_type = 'utils' and matching primary keys, using a single optimized query."""
        if not rows_values_en_us:
            return

        # All columns to use in VALUES: primary keys + en_us columns
        pk_cols = self.primary_keys_no_project_type_i18n
        en_us_cols = self.values_en_us
        all_cols = pk_cols + en_us_cols

        # Build the VALUES part
        values_sql = []
        for row in rows_values_en_us:
            row_values = []
            for col in all_cols:
                val = row.get(col, None)
                if val is None:
                    row_values.append('NULL')
                else:
                    row_values.append("'" + str(val).replace("'", "''") + "'")
            values_sql.append(f"({', '.join(row_values)})")
        values_block = ',\n'.join(values_sql)

        # Build the SET clause
        set_clauses = [f"{col} = v.{col}" for col in en_us_cols]
        set_clause = ', '.join(set_clauses)

        # Build the join condition for primary keys
        join_conditions = [f"t.{col} = v.{col}" for col in pk_cols]
        join_condition = ' AND '.join(join_conditions)

        # Compose the full query
        query = f"""
            UPDATE {table} AS t
            SET {set_clause}
            FROM (
            VALUES {values_block}
            )AS v ({', '.join(all_cols)})
            WHERE t.project_type = 'utils' AND {join_condition};
        """
        self.cursor_i18n.execute(query)
        self.conn_i18n.commit()

    def _get_fake_primary_keys(self, table, project_type):
        columns = ",".join(self.primary_keys_no_project_type_i18n)
        in_project_type = project_type if project_type != 'utils' else "ws', 'ud"
        query = f"""
            SELECT {columns}
            FROM {table}
            WHERE TRIM(project_type) IN ('{in_project_type}', 'utils')
            GROUP BY {columns}
            HAVING
                COUNT(*) > 1
                AND SUM(CASE WHEN project_type = '{project_type}' THEN 1 ELSE 0 END) > 0
                AND SUM(CASE WHEN project_type = 'utils' THEN 1 ELSE 0 END) > 0;
        """
        duplicated_rows = self._get_rows(query, self.cursor_i18n)

        query = f"SELECT {columns} FROM {table} WHERE project_type = '{project_type}';"
        all_rows = self._get_rows(query, self.cursor_i18n)

        fake_rows = self._set_operation_on_dict(all_rows, duplicated_rows, op='&', compare='values')

        all_values = {tuple(row[col] for col in self.primary_keys_no_project_type_i18n) for row in all_rows}
        duplicated_values = {tuple(row[col] for col in self.primary_keys_no_project_type_i18n) for row in duplicated_rows}
        fake_values = all_values & duplicated_values
        fake_rows = [dict(zip(self.primary_keys_no_project_type_i18n, values)) for values in fake_values]

        return fake_rows

    def _get_duplicates_rows(self, table):
        """Get the duplicated rows"""
        columns = ",".join(self.conflict_project_type)
        query = f"""
            SELECT {columns}
            FROM {table}
            WHERE project_type IN ('ws', 'ud', 'utils')
            GROUP BY {columns}
            HAVING COUNT(*) > 1;
        """
        return query

    def _update_project_type(self, table, duplicated_rows):
        """Update the project_type to the correct value"""

        self._get_all_columns(table)
        pk_columns = []
        update_query = ""
        delete_query = ""
        for k, row in enumerate(duplicated_rows):
            text = []
            for column in self.conflict_project_type:
                if k == 0:
                    pk_columns.append(column)

                if row[column] is None:
                    text.append(f"{column} IS NULL")
                else:
                    text.append(f"{column} = '" + str(row[column]).replace("'", "''") + "'")

            where_clause = " AND ".join(text)
            pk_colums_str = ", ".join(pk_columns)

            delete_query += f"""
                WITH Ranked AS (SELECT ctid, ROW_NUMBER() OVER (PARTITION BY {pk_colums_str} ORDER BY lastupdate ASC) AS rn
                FROM {table} WHERE {where_clause})
                DELETE FROM {table} WHERE ctid IN (SELECT ctid FROM Ranked WHERE rn > 1);
                """

            update_query += f"""
                UPDATE {table} SET project_type = 'utils' WHERE {where_clause};\n
            """
        return delete_query, update_query

    def _delete_fake_utils(self, table, fake_rows):
        """Delete the fake utils rows"""

        delete_query = ""
        columns = self.primary_keys_no_project_type_i18n
        for k, row in enumerate(fake_rows):
            text = []
            for column in columns:
                if row[column] is None:
                    text.append(f"{column} IS NULL")
                else:
                    text.append(f"{column} = '" + str(row[column]).replace("'", "''") + "'")

            where_clause = " AND ".join(text)
            where_clause += " AND project_type = 'utils'"

            delete_query += f"""
                DELETE FROM {table} WHERE {where_clause};\n
                """
        try:
            self.cursor_i18n.execute(delete_query)
            self.conn_i18n.commit()
        except Exception:
            self.conn_i18n.rollback()

    # endregion

    # region python
    def _update_py_dialogs(self):
        """ Update the table with the python dialogs """

        # Make the user know what is being done
        self.project_type = "python"
        self._change_table_lyt("pydialog")

        # Find the files to search for messages
        path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
        files = self._find_files(path, ".ui")

        # Determine the key and find the messages
        processed_entries = {}  # Use a dictionary to store unique entries
        keys = ["<string>", "<widget", 'name=']
        avoid_keys = ["<action name="]
        for file in files:
            coincidencias = self._search_lines(file, keys[0])
            if coincidencias:
                for num_line, content in coincidencias:
                    dialog_name, toolbar_name, source = self._search_dialog_info(file, keys[1], keys[2], num_line, avoid_keys)
                    if source is False:
                        continue
                    pattern = r'>(.*?)<'
                    match = re.search(pattern, content)
                    if match:
                        message_text = match.group(1)
                        # Determine actual_source (which is stored in pydialog.source)
                        if source.startswith('dlg_') or source == dialog_name:
                            actual_source = f"dlg_{dialog_name}"
                        else:
                            actual_source = source
                        # Key for de-duplication and DB matching
                        db_key = (actual_source, dialog_name, toolbar_name)
                        processed_entries[db_key] = message_text

        # Add btn_help to messages
        help_db_key = ("btn_help", "common", "common")
        processed_entries[help_db_key] = "Help"

        # primary_keys_final should match the structure (actual_source, dialog_name, toolbar_name)
        primary_keys_final = list(processed_entries.keys())

        # Determine existing primary keys from the database
        primary_keys_org = []
        try:
            query = f"SELECT source, dialog_name, toolbar_name FROM {self.schema_i18n}.pydialog"
            self.cursor_i18n.execute(query)
            rows = self.cursor_i18n.fetchall()
            for row in rows:
                primary_keys_org.append((row["source"], row["dialog_name"], row["toolbar_name"]))
        except Exception as e:
            msg = tools_qt.tr("Error fetching existing primary keys: {0}")
            tools_qt.manage_exception_db(msg.format(e), query, pause_on_exception=True)

        # Delete removed widgets
        old_keys = set(primary_keys_org) - set(primary_keys_final)

        if old_keys and self.delete_old_keys:
            delete_values = []
            for actual_source, dialog_name, toolbar_name in old_keys:
                if actual_source == "dlg_admin":
                    continue
                # Escape single quotes
                esc_actual_source = actual_source.replace("'", "''")
                esc_dialog_name = dialog_name.replace("'", "''")
                esc_toolbar_name = toolbar_name.replace("'", "''")
                delete_values.append(f"(source = '{esc_actual_source}' AND dialog_name = '{esc_dialog_name}' AND toolbar_name = '{esc_toolbar_name}')")

            # Single delete query for all old keys
            if delete_values:  # Ensure there's something to delete
                delete_query = f"DELETE FROM {self.schema_i18n}.pydialog WHERE {' OR '.join(delete_values)}"
                try:
                    self.cursor_i18n.execute(delete_query)
                except Exception as e:
                    msg = tools_qt.tr("Error deleting rows: {0}")
                    tools_qt.manage_exception_db(msg.format(e), delete_query, pause_on_exception=True)

        # Update the table
        text_error = ""
        query_error = ""
        values_list = []
        # Iterate over de-duplicated entries
        for (actual_source, dialog_name, toolbar_name), message in processed_entries.items():
            # Escape single quotes
            esc_message = message.replace("'", "''")
            esc_dialog_name = dialog_name.replace("'", "''")
            esc_toolbar_name = toolbar_name.replace("'", "''")
            esc_actual_source = actual_source.replace("'", "''")

            values_list.append(
                f"('giswater', 'utils', '{esc_dialog_name}', '{esc_toolbar_name}', '{esc_actual_source}', '{esc_message}')"
            )

        if values_list:
            # Single upsert query with all values
            query = (
                "INSERT INTO {schema}.pydialog "
                "(source_code, project_type, dialog_name, toolbar_name, source, lb_en_us) "
                "VALUES {values} "
                "ON CONFLICT (source_code, project_type, dialog_name, toolbar_name, source) "
                "DO UPDATE SET lb_en_us = EXCLUDED.lb_en_us;"
            ).format(
                schema=self.schema_i18n,
                values=', '.join(values_list)
            )

            try:
                self.cursor_i18n.execute(query)
            except Exception as e:
                msg = tools_qt.tr("Error updating table: {0}\n")
                text_error += msg.format(e)
                query_error += query + '\n'

        if text_error:
            tools_qt.manage_exception_db(text_error, query_error, pause_on_exception=True)
        else:
            msg = "All dialogs updated correctly"
            tools_qt.show_info_box(msg)

        self.conn_i18n.commit()

    def _update_py_messages(self):
        """ Update the table with the python messages """

        self.project_type = "python"
        self._change_table_lyt("pymessage")
        path = os.path.abspath(
            os.path.join(os.path.dirname(__file__), "..", "..")
        )
        files = self._find_files(path, ".py")

        messages = []
        fields = ['message', 'msg', 'title']
        patterns = ['=', ' =', '= ', ' = ']
        quotes = ['"', "'", '(']

        # Generate all combinations
        keys = [f"{field}{pattern}{quote}" for field, pattern, quote in product(fields, patterns, quotes)]

        for file in files:
            for key in keys:
                coincidencias = self._search_lines(file, key)
                if coincidencias:
                    for num_line, content in coincidencias:
                        if "(" in key:
                            key = 'msg = "'
                        match = re.search(rf'{re.escape(key)}(.*?){key[-1]}', content)
                        if match:
                            message = self._search_for_lines(match.group(1))
                            messages.extend(message)

        # Determine existing primary keys from the database
        primary_keys_org = []
        try:
            self.cursor_i18n.execute(f"SELECT source FROM {self.schema_i18n}.pymessage")
            rows = self.cursor_i18n.fetchall()
            for row in rows:
                primary_keys_org.append(row["source"])
        except Exception as e:
            msg = "Error fetching existing primary keys: {0}"
            msg_params = (e,)
            title = "Error fetching existing primary keys"
            tools_qt.show_exception_message(title, msg, msg_params=msg_params)

        # Delete removed widgets
        primary_keys_org_set = set(primary_keys_org)
        primary_keys_final_set = set(messages)
        old_messages = primary_keys_org_set - primary_keys_final_set

        if old_messages:
            if self.delete_old_keys:
                for source in old_messages:
                    source = source.replace("'", "''")
                    query = f"DELETE FROM {self.schema_i18n}.pymessage WHERE source = '" + source + "';"
                    try:
                        self.cursor_i18n.execute(query)
                    except Exception as e:
                        msg = "Error deleting row: {0} - Query: {1}"
                        msg_params = (e, query,)
                        title = "Error deleting row"
                        tools_qt.show_exception_message(title, msg, msg_params=msg_params)

        # Insert new messages

        msg = ""
        msg_params = None
        new_messages = primary_keys_final_set - primary_keys_org_set
        if new_messages:
            for message in new_messages:
                message = message.replace("'", "''")
                query = (f"""INSERT INTO {self.schema_i18n}.pymessage (source_code, source, ms_en_us) """
                        f"""VALUES ('giswater', '{message}', '{message}') ON CONFLICT (source_code, source) """
                        f"""DO UPDATE SET ms_en_us = '{message}'""")

                try:
                    self.cursor_i18n.execute(query)
                except Exception:
                    msg += f"{tools_qt.tr('Error updating')}: {Exception}.\n"
                    break

        if len(msg) > 1:
            title = "Error updating messages"
            tools_qt.show_exception_message(title, msg)
        else:
            msg = "All messages updated correctly"
            tools_qt.show_info_box(msg)

        self.conn_i18n.commit()
    # endregion

    # region python functions
    def _search_for_lines(self, message):
        if '\\n' in message:
            return message.split('\\n')
        else:
            return [message]

    def _find_files(self, path, file_type):
        """ Find all files with the given file type in the given path """

        py_files = []
        for folder, subfolder, files in os.walk(path):
            if folder.split(os.sep) in ['packages', 'resources']:
                continue
            for file in files:
                if file.endswith(file_type):
                    file_path = os.path.join(folder, file)
                    py_files.append(file_path)

        return py_files

    def _search_lines(self, file, key, avoid_keys=None):
        """ Search for the lines with the key in the file """

        found_lines = []
        try:
            with open(file, "r", encoding="utf-8") as f:
                in_multiline = False
                full_text = ""

                for num_line, raw_line in enumerate(f):
                    line = raw_line.strip()

                    if in_multiline:
                        full_text += line
                        if line.endswith(")"):
                            found_lines = self._msg_multines_end(found_lines, full_text, num_line)
                            in_multiline = False
                        continue

                    if line.startswith(key):
                        if "(" not in key:
                            found_lines.append((num_line, line))
                        else:
                            if line.endswith(")"):
                                found_lines = self._msg_multines_end(found_lines, full_text, num_line)
                            else:
                                # Begin multi-line
                                in_multiline = True
                                full_text = line

        except FileNotFoundError:
            msg = "File not found: {0}"
            msg_params = (file,)
            title = "File not found"
            tools_qt.show_exception_message(title, msg, msg_params=msg_params)
        except Exception as e:
            msg = "Error reading file {0}: {1}"
            msg_params = (file, e,)
            title = "Error reading file"
            tools_qt.show_exception_message(title, msg, msg_params=msg_params)
        return found_lines

    def _msg_multines_end(self, found_lines, full_text, num_line):
        """ Extract the message from the multiline """

        matches = re.findall(r"(['\"])(.*?)\1", full_text)
        if matches:
            final_text = 'msg = "' + ''.join(m[1] for m in matches) + '"'
            found_lines.append((num_line, final_text))
        else:
            if full_text != "":
                msg = "Error: Could not extract message from line: {0}"
                msg_params = (full_text,)
                title = "Error finding string"
                tools_qt.show_exception_message(title, msg, msg_params=msg_params)
            found_lines.append((num_line, full_text.strip()))
        return found_lines

    def _search_dialog_info(self, file, key_row, key_text, num_line, avoid_keys=None):
        """ Search for the dialog info in the file """

        with open(file, "r", encoding="utf-8") as f:
            # Extract folder and file name (assuming the file path is used)
            toolbar_name = os.path.basename(os.path.dirname(file))
            dialog_name = os.path.basename(file)
            dialog_name = dialog_name.split(".")[0]

            # Read all lines into a list
            lines = f.readlines()

            # Search for the key in the file, starting from the given line
            while num_line >= 0 and key_row not in lines[num_line]:
                if avoid_keys and any(avoid_key in lines[num_line] for avoid_key in avoid_keys):
                    return dialog_name, toolbar_name, False
                num_line -= 1

            if num_line < 0:
                return None

            # Now extract the value between quotes using regex
            pattern = rf'{re.escape(key_text)}"(.*?)"'
            match = re.search(pattern, lines[num_line])

            if match:
                source = match.group(1)
            else:
                source = ""

            return dialog_name, toolbar_name, source

    # endregion

    # region cat_version
    def _update_cat_version(self):
        """ Update the cat_version table """
        for schema in self.schemas:
            if schema[0:2].lower() in ["ws", "ud", "am", "cm"]:
                table_org = f"{schema}.sys_version"
                self._update_cat_version_table(table_org)
            else:
                self._update_cat_version_python(schema)
        
            self._update_cat_lastupdate(schema)

    def _update_cat_version_table(self, table_org):
        """ Update the cat_version table """
        query = f"SELECT giswater, project_type FROM {table_org} ORDER BY id DESC LIMIT 1;"
        self.cursor_org.execute(query)
        rows = self.cursor_org.fetchall()
        version = rows[0]['giswater']
        schema = rows[0]['project_type']
        
        query = f"SELECT iterations FROM {self.schema_i18n}.cat_version WHERE project_type = '{schema}' AND version = '{version}' ORDER BY iterations DESC LIMIT 1;"
        self.cursor_i18n.execute(query)
        iteration = self.cursor_i18n.fetchone()
        if not iteration:
            query = f"INSERT INTO {self.schema_i18n}.cat_version (project_type, version, iterations, lastupdate) VALUES ('{schema}', '{version}', 1, now());"
        else:
            iteration = iteration[0] + 1
            query = f"UPDATE {self.schema_i18n}.cat_version SET iterations = {iteration}, lastupdate = now() WHERE project_type = '{schema}' AND version = '{version}';"
        
        try:
            self.cursor_i18n.execute(query)
        except Exception as e:
            tools_qt.manage_exception_db(e, query, pause_on_exception=True)
        self.conn_i18n.commit()

    def _update_cat_version_python(self, schema):
        """ Update the cat_version table """
        version = tools_qgis.get_plugin_version()[0]
        query = f"SELECT iterations FROM {self.schema_i18n}.cat_version WHERE project_type = '{schema}' AND version = '{version}' ORDER BY iterations DESC LIMIT 1;"
        self.cursor_i18n.execute(query)
        iteration = self.cursor_i18n.fetchone()
        if not iteration:
            query = f"INSERT INTO {self.schema_i18n}.cat_version (project_type, version, iterations, lastupdate) VALUES ('{schema}', '{version}', 1, now());"
        else:
            iteration = iteration[0] + 1
            query = f"UPDATE {self.schema_i18n}.cat_version SET iterations = {iteration}, lastupdate = now() WHERE project_type = '{schema}' AND version = '{version}';"

        try:
            self.cursor_i18n.execute(query)
        except Exception as e:
            tools_qt.manage_exception_db(e, query, pause_on_exception=True)
        self.conn_i18n.commit()

    def _update_cat_lastupdate(self, schema):
        """ Update the cat_lastupdate table """
        query = ""
        if schema[0:2].lower() in ["ws", "ud", "am", "cm"]:
            tables_i18n, sutables = self.tables_dic(schema[0:2].lower())
            if self.check_for_su_tables:
                tables_i18n.extend(sutables)
        elif schema.lower() == "dialogs":
            tables_i18n = ["pydialog", "pytoolbar"]
        elif schema.lower() == "python":
            tables_i18n = ["pymessages", "pytoolbar"]
        for table in tables_i18n:
            query += f"""UPDATE {self.schema_i18n}.cat_lastupdate SET lastupdate_en_us = now()
                         WHERE "table" = '{table.lower()}';\n"""
        self.cursor_i18n.execute(query)
        self.conn_i18n.commit()

    # endregion
    
    # region Global funcitons

    def _beautify_text(self, text):
        """
        Replace underscores with spaces and capitalize each word, preserving specific keywords from no_beautify_keys.
        """
        if not isinstance(text, str) or not text:
            return text

        # Only initialize keys if not already cached
        if not hasattr(self, 'no_beautify_keys'):
            self._no_beautify_keys()

        no_beautify_set = set(self.no_beautify_keys)

        # Precompiled regex for efficiency
        if not hasattr(self, '_no_beautify_regex'):
            sorted_keys = sorted(no_beautify_set, key=len, reverse=True)
            pattern = '|'.join(re.escape(k) for k in sorted_keys)
            self._no_beautify_regex = re.compile(f'({pattern})')

        parts = self._no_beautify_regex.split(text)

        result_parts = []
        capitalize_next = True
        for part in parts:
            if part in no_beautify_set:
                result_parts.append(part)
                capitalize_next = False
            elif part:
                processed = part.replace('_', ' ')
                if capitalize_next:
                    processed = processed[0].upper() + processed[1:] if processed else ''
                    capitalize_next = False
                result_parts.append(processed)

        result = ''.join(result_parts)
        return result

    def _detect_schema(self, schema_name):
        """ Detect if the schema exists """

        query = "SELECT schema_name FROM information_schema.schemata;"
        self.cursor_org.execute(query)
        schemas = self.cursor_org.fetchall()

        existing_schema = False
        for schema in schemas:
            # schema is a tuple like ('information_schema',) so you need to access the first element
            if schema[0] == schema_name:
                existing_schema = True
                break  # Exit the loop early once we find the schema

        return existing_schema

    def detect_table_func(self, table, cursor):
        """ Detect if the table exists """

        sql = f"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '{table.split('.')[0]}' AND table_name = '{table.split('.')[1]}';"
        cursor.execute(sql)
        result = cursor.fetchone()
        existing_table = result[0] > 0  # Check if count is greater than 0
        return existing_table

    def _find_table_org(self, table_i18n):
        """ Find the table in the original DB """

        # Create the query using table_i18n
        query = f'SELECT * FROM {table_i18n}'
        rows = self._get_rows(query, self.cursor_i18n)

        table_name = table_i18n.split(".")[1]
        tables_org = []
        # Process the table name based on its prefix
        if "dbtypevalue" in table_i18n:
            if self.project_type in ["am", "cm"]:
                tables_org = ["sys_typevalue"]
            if self.project_type in ["ws", "ud"]:
                tables_org = ["edit_typevalue", "plan_typevalue", "om_typevalue", "inp_typevalue"]
        elif "dbjson" in table_i18n:
            tables_org = ["config_report", "config_toolbox"]
        elif "dbplan_price" in table_i18n:
            tables_org = ["plan_price"]
        elif "dbstyle" in table_i18n:
            tables_org = ["sys_style"]
        elif "dbconfig_form_fields_json" in table_i18n or "dbconfig_form_fields_feat" in table_i18n:
            tables_org = ["config_form_fields"]
        elif "dbconfig_engine" in table_i18n:
            tables_org = ["config_engine", "config_engine_def"]
        elif table_name.startswith("dbconfig"):
            tables_org = [table_name[2:]]  # Get everything after the first two characters
        elif table_name.startswith("su_"):
            if self.project_type == "am":
                tables_org = ["value_result_type", "value_status"]
            if self.project_type in ["ws", "ud"]:
                if table_name == "su_feature":
                    tables_org = ["cat_feature"]
                else:
                    tables_org = ["value_state", "value_state_type"]
        else:
            tables_org = [f"sys_{table_name[2:]}"]  # Prepend "sys_" and get everything after the first two characters

        # If rows exist, retrieve 'context' from the first row
        seen_contexts = set(tables_org)
        for row in rows:
            context = row.get('context')
            row_project_type = row.get("project_type")
            if context not in seen_contexts and row_project_type == self.project_type:
                tables_org.append(context)
                seen_contexts.add(context)  # Use .get() to avoid KeyError if 'context' doesn't exist
        if tables_org is None:
            return None  # Or some fallback behavior
        return tables_org

    def _get_rows(self, sql, cursor):
        """ Get multiple rows from selected query """

        rows = None
        try:
            cursor.execute(sql)
            rows = cursor.fetchall()
        except Exception as e:
            tools_qt.manage_exception_db(e, sql, pause_on_exception=True)
        finally:
            return rows

    def _vacuum_commit(self, table, conn, cursor):
        """ Vacuum and commit the table """

        old_isolation_level = conn.isolation_level
        conn.set_isolation_level(0)
        cursor.execute(f"VACUUM FULL {table};")
        cursor.execute(f"ANALYZE {table};")
        conn.set_isolation_level(old_isolation_level)

    def _change_table_lyt(self, table):
        """ Change the label to inform the user about the table being processed """
        # Update the part the of the program in process
        self.dlg_qm.lbl_info.clear()
        msg = "From {0}, updating {1}..."
        msg_params = (self.project_type, table)
        tools_qt.set_widget_text(self.dlg_qm, 'lbl_info', msg, msg_params)
        QApplication.processEvents()

    def extract_and_update_strings(self, data):
        """Recursively extract and return list of dictionaries with translatable keys."""
        results = []

        def recurse(item):
            if isinstance(item, dict):
                entry = {}
                for key, value in item.items():
                    if key in self.translatable_keys:
                        if key == 'comboNames' and isinstance(value, list):
                            entry[key] = value
                        elif isinstance(value, str):
                            entry[key] = value
                    # Recurse into children
                    recurse(value)
                if entry:
                    results.append(entry)
            elif isinstance(item, list):
                for sub in item:
                    recurse(sub)

        recurse(data)
        return results

    def _verify_lang(self):
        """ Verify if the language is en_US """

        query = f"SELECT language from {self.schema_org}.sys_version"
        self.cursor_org.execute(query)
        language_org = self.cursor_org.fetchone()[0]
        if language_org not in ('en_US', 'no_TR'):
            return False
        return True

    def save_and_open_text_error(self, text_error, filename="i18n_error_log.txt"):
        # Save the text_error to a file in the user's home directory or temp directory
        file_path = os.path.join(os.path.expanduser("~"), filename)
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(text_error)
        # Open the file with the default text editor
        if sys.platform.startswith("win"):
            os.startfile(file_path)
        elif sys.platform.startswith("darwin"):
            os.system(f"open '{file_path}'")
        else:
            os.system(f"xdg-open '{file_path}'")

    def _is_subset_dict(self, d1: Dict[str, Any], d2: Dict[str, Any]) -> bool:
        return all(d1.get(k) == v for k, v in d2.items())

    def _unique_dicts(self, dicts: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        seen = set()
        result = []
        for d in dicts:
            t = tuple(sorted(d.items()))
            if t not in seen:
                seen.add(t)
                result.append(d)
        return result

    def _dict_to_comparable(self, d, mode):
        if mode == 'items':
            return tuple(d.items())
        elif mode == 'keys':
            return tuple(d.keys())
        elif mode == 'values':
            return tuple(d.values())
        else:
            raise ValueError(f"Unsupported compare mode: {mode}")

    def _set_operation_on_dict(self, rows1, rows2, op='&', compare='items'):
        """
        Perform set-like operations on lists of dictionaries, with optional partial matching.
        """
        set1 = set(self._dict_to_comparable(d, compare) for d in rows1)
        set2 = set(self._dict_to_comparable(d, compare) for d in rows2)

        if op == '&':
            result = set1 & set2
        elif op == '|':
            result = set1 | set2
        elif op == '-':
            result = set1 - set2
        elif op == '^':
            result = set1 ^ set2
        else:
            raise ValueError(f"Unsupported operation: {op}")

        if compare == 'items':
            return [dict(t) for t in result]
        elif compare == 'values':
            return [dict(zip(rows1[0].keys(), t)) for t in result]
        else:
            raise ValueError(f"Unsupported compare mode: {compare}")

    def _get_all_columns(self, table_i18n):
        """ Get all columns from the table """
        query = f"""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = '{table_i18n.split('.')[1]}'
            AND table_schema = '{table_i18n.split('.')[0]}'
            ORDER BY ordinal_position;"""
        self.cursor_i18n.execute(query)
        return [row[0] for row in self.cursor_i18n.fetchall()]

    def tables_dic(self, schema_type):
        """ Define the tables to be translated in a dictionary """
        dbtables_dic = {
            "ws": {
                "dbtables": ["dbparam_user", "dbconfig_param_system", "dbconfig_form_fields", "dbconfig_typevalue",
                    "dbfprocess", "dbmessage", "dbconfig_csv", "dbconfig_form_tabs", "dbconfig_report",
                    "dbconfig_toolbox", "dbfunction", "dbtypevalue", "dbconfig_form_tableview", "dbconfig_visit_parameter",
                    "dbtable", "dbconfig_form_fields_feat", "su_basic_tables", "dblabel", "dbplan_price", "dbjson",
                    "dbconfig_form_fields_json"],
                "sutables": ["su_basic_tables", "su_feature"]
            },
            "ud": {
                "dbtables": ["dbparam_user", "dbconfig_param_system", "dbconfig_form_fields", "dbconfig_typevalue",
                    "dbfprocess", "dbmessage", "dbconfig_csv", "dbconfig_form_tabs", "dbconfig_report",
                    "dbconfig_toolbox", "dbfunction", "dbtypevalue", "dbconfig_form_tableview", "dbconfig_visit_parameter",
                    "dbtable", "dbconfig_form_fields_feat", "su_basic_tables", "dblabel", "dbplan_price", "dbjson",
                    "dbconfig_form_fields_json"],
                "sutables": ["su_basic_tables", "su_feature"]
            },
            "am": {
                "dbtables": ["dbconfig_engine", "dbconfig_form_tableview", "su_basic_tables"],
                "sutables": []
            },
            "cm": {
                "dbtables": ["dbconfig_form_fields", "dbconfig_form_tabs", "dbconfig_param_system",
                             "dbtypevalue", "dbfprocess", "dbtable", "dbconfig_form_tableview", "dbconfig_form_fields_json"],
                "sutables": []
            },
        }
        return dbtables_dic[schema_type]['dbtables'], dbtables_dic[schema_type]['sutables']

    def _no_beautify_keys(self):
        """ Define the tables to be translated in a dictionary """
        try:
            query = f"SELECT table_name FROM information_schema.tables WHERE table_schema = '{self.schema_org}';"
            self.cursor_org.execute(query)
            table_names = self.cursor_org.fetchall()
            self.no_beautify_keys = [table_name[0] for table_name in table_names]
        except Exception:
            self.no_beautify_keys = []

    # endregion

    def _extra_messages_to_find():
        # writen to be detected by the automatical finder of pymessages
        message = "File name"
        message = "Function name"
        message = "Detail"
        message = "Context"
        message = "Message error"
        message = "Key"
        message = "Key container"
        message = "Python file"
        message = "Python function"
        message = "There have been errors translating:"
        message = "Database translation canceled."
        message = "Database translation failed."
        message = "Database translation successful to"
        message = "Do you want to copy its values to the current node?"
        message = "Selected snapped feature_id to copy values from"
        message = "Clicking an item will check/uncheck it. "
        message = "Checking any item will not uncheck any other item."
        message = "Checking any item will uncheck all other items unless Shift is pressed."
        message = "Checking any item will uncheck all other items."
        message = "This behaviour can be configured in the table 'config_param_system' (parameter = 'basic_selector"
        message = "Pipes with invalid arccat_ids: {0}."
        message = "Invalid arccat_ids: {0}."
        message = "Do you want to proceed?"
        message = ("An arccat_id is considered invalid if it is not listed in the catalog configuration table. "
                    "As a result, these pipes will NOT be assigned a priority value.")
        message = "Pipes with invalid diameters: {0}."
        message = "Invalid diameters: {1}."
        message = ("A diameter value is considered invalid if it is zero, negative, NULL "
                    "or greater than the maximum diameter in the configuration table. "
                    "As a result, these pipes will NOT be assigned a priority value.")
        message = "A material is considered invalid if it is not listed in the material configuration table."
        message = ("As a result, the material of these pipes will be treated "
                    "as the configured unknown material, {0}.")
        message = ("These pipes will NOT be assigned a priority value "
                    "as the configured unknown material, {1}, "
                    "is not listed in the configuration tab for materials.")
        message = "Pipes with invalid materials: {2}."
        message = "Invalid materials: {3}."
        message = "Field child_layer of id: "
        message = "is not defined in table cat_feature"
        message = "widgettype not found. "
        message = "layoutorder not found."
        message = "widgetname not found. "
        message = "widgettype is wrongly configured. Needs to be in "
        message = "Information about exception"
        message = "Error type"
        message = "Line number"
        message = "Description"
        message = "Schema name"
        message = "SQL"
        message = "SQL File"
        message = "Python translation successful"
        message = "Python translation failed"
        message = "Python translation canceled"
        message = "translation successful"
        message = "translation failed in table"
        message = "translation canceled"
        message = ('Interpolate tool.\n'
               'To modify columns (top_elev, ymax, elev among others) to be interpolated set variable '
               'edit_node_interpolate on table config_param_user')
        message = "Inp Options"
        message = "IMPORT INP"
        message = ("This wizard will help with the process of importing a network from a {0} INP "
                   "file into the Giswater database.")
        message = "There are multple tabs in order to configure all the necessary catalogs."
        message = ("The first tab is the 'Basic' tab, where you can select the exploitation, sector, "
                   "municipality, and other basic information.")
        message = ("The second tab is the 'Features' tab, where you can select the corresponding feature "
                   "classes for each type of feature on the network.")
        message = ("Here you can choose how the pumps and valves will be imported, either left as arcs "
                   "(virual arcs) or converted to nodes.")
        message = ("The third tab is the 'Materials' tab, where you can select the corresponding material "
                   "for each roughness value.")
        message = ("Here you can choose how the pumps, weirs, orifices, and outlets will be imported, either "
                   "left as arcs (virual arcs) or converted to flwreg.")
        message = ("The third tab is the 'Materials' tab, where you can select the corresponding roughness value "
                   "for each material.")
        message = ("The fourth tab is the 'Nodes' tab, where you can select the catalog for each type of node "
                   "on the network.")
        message = ("The fifth tab is the 'Arcs' tab, where you can select the catalog for each type of arc "
                   "on the network.")
        message = ("If you chose to import the flow regulators as flwreg objects, the sixth tab is where you "
                   "can select the catalog for each flow regulator (pumps, weirs, orifices, outlets) on the network.")
        message = "If not, you can ignore the tab."
        message = ("Once you have configured all the necessary catalogs, you can click on the 'Accept' button to "
                   "start the import process.")
        message = "It will then show the log of the process in the last tab."
        message = ("You can save the current configuration to a file and load it later, or load the last saved "
                   "configuration.")
        message = "If you have any questions, please contact the Giswater team via"
        message = "GitHub Issues"
        message = "or"
        message = "our website"
        message = "Export INP finished. "
        message = "Error near line"
        message = "EPA model finished. "
        message = "Import RPT file finished."
        message = "Are you sure you want to delete these records:"
        message = "This will also delete the database user(s):"
        message = "PostgreSQL version"
        message = "PostGis version"
        message = "PgRouting version"
        message = "Version"
        message = "Schema name"
        message = "Language"
        message = "Date of creation"
        message = "Date of last update"
        message = "Creation type"
        message = "In schema"
        message = "Dscenario manager"
        message = "Hydrology scenario manager"
        message = "DWF scenario manager"
        message = "Psector could not be updated because of the following errors: "
        return message
