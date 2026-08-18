"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial
import tempfile

from ....ui.ui_manager import GwStyleManagerUi, GwStyleUi, GwUpdateStyleGroupUi
from ....utils import tools_gw
from .....libs import lib_vars, tools_db, tools_qgis, tools_qt
from ..... import global_vars

from qgis.PyQt.QtWidgets import QHeaderView, QMenu, QAction, QPushButton
from qgis.PyQt.QtCore import Qt
from qgis.PyQt.QtGui import QCursor
from qgis.core import Qgis


class GwStyleManager:

    def __init__(self):
        """Initializes the StyleManager with basic configurations."""
        self.plugin_dir = lib_vars.plugin_dir
        self.iface = global_vars.iface
        self.schema_name = lib_vars.schema_name
        self.style_mng_dlg = None

    def manage_styles(self):
        """Manages the user interface for style management."""
        self.style_mng_dlg = GwStyleManagerUi(self)
        tools_gw.load_settings(self.style_mng_dlg)

        # Add icons to the buttons
        tools_gw.add_icon(self.style_mng_dlg.btn_add_group, "111")
        tools_gw.add_icon(self.style_mng_dlg.btn_delete_group, "112")

        # Load layers and populate the menu
        layers_data = self._load_layers_with_geom()
        if layers_data:
            self._populate_layers_menu(layers_data)

        # Populate the combobox with style groups
        self.populate_stylegroup_combobox()
        self._load_styles()

        # Populate custom context menu
        self.style_mng_dlg.tbl_style.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.style_mng_dlg.tbl_style.customContextMenuRequested.connect(partial(self._show_context_menu, self.style_mng_dlg.tbl_style))

        # Connect signals to the corresponding methods
        self.style_mng_dlg.btn_add_group.clicked.connect(partial(self._add_style_group, self.style_mng_dlg))
        self.style_mng_dlg.btn_update_group.clicked.connect(partial(self._update_style_group, self.style_mng_dlg))
        self.style_mng_dlg.btn_delete_group.clicked.connect(self._delete_style_group)
        self.style_mng_dlg.cmb_stylegroup.currentIndexChanged.connect(self._filter_styles)
        self.style_mng_dlg.txt_style_name.textChanged.connect(self._filter_styles)

        # Connect signals to the style buttons
        self.style_mng_dlg.btn_delete_style.clicked.connect(self._delete_selected_styles)
        self.style_mng_dlg.btn_update_style.clicked.connect(self._update_selected_style)
        self.style_mng_dlg.btn_refresh_all.clicked.connect(partial(self._refresh_all_styles_mng, self.style_mng_dlg))

        self.style_mng_dlg.btn_close.clicked.connect(partial(tools_gw.close_dialog, self.style_mng_dlg, True, 'core'))

        # Open the style management dialog
        tools_gw.open_dialog(self.style_mng_dlg, 'style_manager')

    def _show_context_menu(self, qtableview):
        """ Show custom context menu """
        menu = QMenu(qtableview)

        action_update = QAction("Update style", qtableview)
        action_update.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_update_style"))
        menu.addAction(action_update)

        action_delete = QAction("Delete style", qtableview)
        action_delete.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_delete_style"))
        menu.addAction(action_delete)

        menu.exec(QCursor.pos())

    def populate_stylegroup_combobox(self):
        """Populates the style group combobox with data from the database."""
        contexts_params = self.get_contexts_params()

        self.style_mng_dlg.cmb_stylegroup.clear()
        self.style_mng_dlg.cmb_stylegroup.addItem("")

        for context_id, context_name in contexts_params:
            self.style_mng_dlg.cmb_stylegroup.addItem(context_name, context_id)

    def get_contexts_params(self):
        """Retrieves style context parameters from the database."""
        sql = """
        SELECT id, idval, addparam
            FROM config_style
        WHERE id != 0 AND (is_templayer = false OR is_templayer IS NULL)
        """
        rows = tools_db.get_rows(sql)

        if not rows:
            return []

        processed_rows = []
        for row in rows:
            id, idval, addparam = row
            order_by = 999
            if addparam:
                try:
                    order_by = addparam.get("orderBy", 999)
                except Exception:
                    pass

            processed_rows.append((id, idval, order_by))

        processed_rows.sort(key=lambda x: x[2])

        return [(row[0], row[1]) for row in processed_rows]

    def _load_sys_roles(self, dialog_create):
        """Load roles in combobox."""
        sql = "SELECT id FROM sys_role"
        roles = tools_db.get_rows(sql)
        dialog_create.sys_role.clear()
        for role in roles:
            dialog_create.sys_role.addItem(role[0])

    def _add_style_group(self, dialog):
        """Logic for adding a style group using the Qt Designer dialog."""
        dialog_create = GwStyleUi(self)
        tools_gw.load_settings(dialog_create)

        self._load_sys_roles(dialog_create)

        dialog_create.btn_add.clicked.connect(partial(self._handle_add_feature, dialog_create))
        dialog_create.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, dialog_create))
        dialog_create.feature_id.textChanged.connect(partial(self._check_style_exists, dialog_create))
        dialog_create.idval.textChanged.connect(partial(self._check_style_exists, dialog_create))

        tools_gw.open_dialog(dialog_create, dlg_name='create_style_group')

    def _handle_add_feature(self, dialog_create):
        """Handles the logic when the add button is clicked."""

        # Gather data from the dialog fields
        feature_id = dialog_create.feature_id.text()
        idval = dialog_create.idval.text()
        descript = dialog_create.descript.text()
        sys_role = dialog_create.sys_role.currentText()

        # Validate that the mandatory fields are not empty
        if not feature_id or not idval:
            msg = "Feature ID and Idval cannot be empty."
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg)
            return

        # Start building the SQL query
        sql = "INSERT INTO config_style (id, idval"

        # Initialize the values part with the mandatory fields
        values = f"'{feature_id}', '{idval}'"

        # Add optional fields if they are not empty
        if descript:
            sql += ", descript"
            values += f", '{descript}'"
        if sys_role:
            sql += ", sys_role"
            values += f", '{sys_role}'"

        # Close the fields section of the SQL query
        sql += f") VALUES ({values}) RETURNING id;"

        try:
            # Execute the SQL command and retrieve the new ID
            tools_db.execute_sql(sql)
            msg = "Feature added successfully!"
            tools_qgis.show_info(msg, dialog=self.style_mng_dlg)
            self.populate_stylegroup_combobox()
            dialog_create.accept()

        except Exception as e:
            msg = "Failed to add feature"
            param = str(e)
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg, parameter=param)

    def _filter_styles(self):
        """Applies a filter based on the text in the textbox and the selection in the combobox."""
        search_text = self.style_mng_dlg.txt_style_name.text().strip()
        selected_stylegroup_name = self.style_mng_dlg.cmb_stylegroup.currentText().strip()

        filter_str = ""

        if search_text:
            filter_str += f"layername LIKE '%{search_text}%'"

        if selected_stylegroup_name:
            if filter_str:
                filter_str += " AND "
            filter_str += f"category = '{selected_stylegroup_name}'"

        model = self.style_mng_dlg.tbl_style.model()
        if model is None:
            return
        model.setFilter(filter_str)
        model.select()

    def _load_styles(self):
        """Loads styles into the table based on the selected style group."""
        tools_qt.fill_table(self.style_mng_dlg.tbl_style, 'v_ui_style')

        model = self.style_mng_dlg.tbl_style.model()
        if model is not None and model.lastError().isValid():
            msg = "Database Error"
            param = model.lastError().text()
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg, parameter=param)
            return

        tools_gw.set_tablemodel_config(self.style_mng_dlg, self.style_mng_dlg.tbl_style, 'v_ui_style')
        tools_qt.set_tableview_config(
            self.style_mng_dlg.tbl_style,
            section_resize_mode=QHeaderView.ResizeMode.Interactive,
        )
        self._filter_styles()

    def _check_style_exists(self, dialog_create):
        feature_id_text = dialog_create.feature_id.text().strip()
        idval_text = dialog_create.idval.text().strip()
        color = "border: 1px solid red"
        has_error = False

        dialog_create.feature_id.setStyleSheet("")
        dialog_create.feature_id.setToolTip("")
        dialog_create.idval.setStyleSheet("")
        dialog_create.idval.setToolTip("")

        # Validates Feature ID if it's not empty
        if feature_id_text:
            try:
                feature_id = int(feature_id_text)
                sql_id = f"SELECT id FROM config_style WHERE id = '{feature_id}'"
                row_id = tools_db.get_row(sql_id, log_info=False)

                if row_id:
                    dialog_create.feature_id.setStyleSheet(color)
                    dialog_create.feature_id.setToolTip("Feature ID already exists")
                    has_error = True
            except ValueError:
                dialog_create.feature_id.setStyleSheet(color)
                dialog_create.feature_id.setToolTip("Feature ID must be an integer")
                has_error = True

        # Validates Idval if it's not empty
        if idval_text:
            sql_idval = f"SELECT idval FROM config_style WHERE idval = '{idval_text}'"
            row_idval = tools_db.get_row(sql_idval, log_info=False)

            if row_idval:
                dialog_create.idval.setStyleSheet(color)
                dialog_create.idval.setToolTip("Category already exists")
                has_error = True
            else:
                dialog_create.idval.setStyleSheet("")
                dialog_create.idval.setToolTip("")

        dialog_create.btn_add.setEnabled(not has_error)

    def _update_style_group(self, dialog):
        """Logic for updating a style group using the Qt Designer dialog."""
        selected_stylegroup_name = self.style_mng_dlg.cmb_stylegroup.currentText()

        if not selected_stylegroup_name:
            msg = "Please select a category to update."
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg)
            return

        dialog_update = GwUpdateStyleGroupUi(self)
        tools_gw.load_settings(dialog_update)

        dialog_update.btn_accept.clicked.connect(partial(self._handle_update_feature, dialog_update, selected_stylegroup_name))
        dialog_update.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, dialog_update))
        dialog_update.category_rename_copy.textChanged.connect(partial(self._check_style_group_exists, dialog_update))

        tools_gw.open_dialog(dialog_update, dlg_name='update_style_group')

    def _check_style_group_exists(self, dialog_update, idval=""):
        sql = f"SELECT idval FROM config_style WHERE idval = '{idval}'"
        row = tools_db.get_row(sql, log_info=False)
        if row:
            dialog_update.btn_accept.setEnabled(False)
            tools_qt.set_stylesheet(dialog_update.category_rename_copy)
            dialog_update.category_rename_copy.setToolTip(tools_qt.tr("Category name already exists"))
            return
        dialog_update.btn_accept.setEnabled(True)
        tools_qt.set_stylesheet(dialog_update.category_rename_copy, style="")
        dialog_update.category_rename_copy.setToolTip("")

    def _handle_update_feature(self, dialog_update, old_category_name):
        """Handles the logic when the add button is clicked."""

        # Gather data from the dialog fields
        new_category_name = dialog_update.category_rename_copy.text()

        # Validate that the mandatory fields are not empty
        if not new_category_name:
            msg = "Category name cannot be empty."
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg)
            return

        # Start building the SQL query
        sql = "UPDATE config_style SET idval = "

        # Initialize the values part with the mandatory fields
        new_name = f"'{new_category_name}'"
        old_name = f"'{old_category_name}'"

        # Close the fields section of the SQL query
        sql += f"{new_name} WHERE idval = {old_name};"

        try:
            # Execute the SQL command and retrieve the new ID
            tools_db.execute_sql(sql)
            msg = "Category updated successfully!"
            tools_qgis.show_info(msg, dialog=self.style_mng_dlg)
            self.populate_stylegroup_combobox()
            tools_gw.close_dialog(dialog_update)

        except Exception as e:
            msg = "Failed to update category"
            param = str(e)
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg, parameter=param)

    def _delete_style_group(self):
        """Logic for deleting a style group with cascade deletion."""
        selected_stylegroup_name = self.style_mng_dlg.cmb_stylegroup.currentText()

        if not selected_stylegroup_name:
            msg = "Please select a style group to delete."
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg)
            return

        msg = ("Are you sure you want to delete the style group '{0}'?\n\n"
                "This will also delete all related entries in the sys_style table."
                "Confirm Cascade Delete")
        msg_params = (selected_stylegroup_name,)
        confirm = tools_qt.show_question(msg, force_action=True, msg_params=msg_params)

        if not confirm:
            return

        try:
            sql_delete_related = f"DELETE FROM sys_style WHERE styleconfig_id = (SELECT id FROM config_style WHERE idval = '{selected_stylegroup_name}')"
            tools_db.execute_sql(sql_delete_related)

            sql_delete_group = f"DELETE FROM config_style WHERE idval = '{selected_stylegroup_name}'"
            tools_db.execute_sql(sql_delete_group)

            msg = "Style group '{0}' and related entries have been deleted."
            msg_params = (selected_stylegroup_name,)
            tools_qgis.show_info(msg, dialog=self.style_mng_dlg, msg_params=msg_params)
            self.populate_stylegroup_combobox()
            self._load_styles()

        except Exception as e:
            msg = "Failed to delete style group"
            param = str(e)
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg, parameter=param)

    # Functions for btn style top right of the dialog
    def _delete_selected_styles(self):
        """Logic for deleting the selected styles from the table."""
        selected_rows = self.style_mng_dlg.tbl_style.selectionModel().selectedRows()

        if len(selected_rows) == 0:
            msg = "Please select one or more styles to delete."
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg)
            return

        msg = "Are you sure you want to delete the selected styles?"
        title = "Confirm Deletion"
        confirm = tools_qt.show_question(msg, title, force_action=True)

        if not confirm:
            return

        try:
            model = self.style_mng_dlg.tbl_style.model()
            layername_col = tools_qt.get_col_index_by_col_name(self.style_mng_dlg.tbl_style, 'layername')
            category_col = tools_qt.get_col_index_by_col_name(self.style_mng_dlg.tbl_style, 'category')
            if layername_col is None or category_col is None:
                return

            for index in selected_rows:
                row = index.row()
                layername = model.data(model.index(row, layername_col))
                idval = model.data(model.index(row, category_col))

                sql_get_id = (
                    f"SELECT id FROM {lib_vars.schema_name}.config_style "
                    f"WHERE idval = '{idval}';"
                )
                row_result = tools_db.get_row(sql_get_id)

                if not row_result:
                    msg = "Could not find the corresponding ID for the selected style {0}."
                    msg_params = (idval,)
                    tools_qgis.show_warning(msg, dialog=self.style_mng_dlg, msg_params=msg_params)
                    continue

                styleconfig_id = row_result[0]

                # Delete the selected row from sys_style using the retrieved numeric `styleconfig_id`
                sql_delete_style = (
                    f"DELETE FROM {lib_vars.schema_name}.sys_style "
                    f"WHERE layername = '{layername}' AND styleconfig_id = {styleconfig_id};"
                )
                tools_db.execute_sql(sql_delete_style)

            msg = "Selected styles were successfully deleted."
            tools_qgis.show_info(msg, dialog=self.style_mng_dlg)
            self._load_styles()

        except Exception as e:
            msg = "Failed to delete styles"
            param = str(e)
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg, parameter=param)

    def _load_layers_with_geom(self):
        """Load layers with geometry for the Add Style button."""
        try:
            body = tools_gw.create_body()
            json_result = tools_gw.execute_procedure('gw_fct_getaddlayervalues', body)
            if not json_result or json_result['status'] != 'Accepted':
                msg = "Failed to load layers."
                tools_qgis.show_warning(msg, dialog=self.style_mng_dlg)
                return None

            return json_result['body']['data']['fields']

        except Exception as e:
            msg = "Failed to load layers"
            param = str(e)
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg, parameter=param)
            return None

    def _populate_layers_menu(self, layers):
        """Populate the Add Style button with layers grouped by context."""
        try:
            menu = QMenu(self.style_mng_dlg.btn_add_style)
            dict_menu = {}
            for layer in layers:
                # Filter only layers that have a geometry field
                if layer['geomField'] == "None" or not layer['geomField']:
                    continue  # Skip layers without a geometry field

                level_1, level_2, level_3 = tools_gw.get_context_menu_levels(layer.get('context'))
                if not level_1 or not level_2:
                    continue

                # Level 1 of the context
                if level_1 not in dict_menu:
                    menu_level_1 = menu.addMenu(f"{level_1}")
                    dict_menu[level_1] = menu_level_1

                # Level 2 of the context
                if f"{level_1}_{level_2}" not in dict_menu:
                    menu_level_2 = dict_menu[level_1].addMenu(f"{level_2}")
                    dict_menu[f"{level_1}_{level_2}"] = menu_level_2

                # Level 3 of the context
                if level_3 and f"{level_1}_{level_2}_{level_3}" not in dict_menu:
                    menu_level_3 = dict_menu[f"{level_1}_{level_2}"].addMenu(f"{level_3}")
                    dict_menu[f"{level_1}_{level_2}_{level_3}"] = menu_level_3

                alias = layer['layerName'] if layer['layerName'] is not None else layer['tableName']
                alias = f"{alias}     "

                # Add actions and submenus at the appropriate context level
                if level_3:
                    sub_menu = dict_menu[f"{level_1}_{level_2}_{level_3}"]
                else:
                    sub_menu = dict_menu[f"{level_1}_{level_2}"]

                action = QAction(alias, self.style_mng_dlg.btn_add_style)
                action.triggered.connect(partial(self._add_layer_style, layer['tableName'], layer['geomField']))
                sub_menu.addAction(action)
            # Assign the menu to the button
            self.style_mng_dlg.btn_add_style.setMenu(menu)

        except Exception as e:
            msg = "Failed to load layers"
            param = str(e)
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg, parameter=param)

    def _add_layer_style(self, table_name, geom_field):
        """Add a new style for the specified layer, copying from 'GwBasic' if available."""
        try:
            selected_stylegroup_name = self.style_mng_dlg.cmb_stylegroup.currentText().strip()

            if not selected_stylegroup_name:
                msg = "Please select a style group before adding a new style."
                tools_qgis.show_warning(msg, dialog=self.style_mng_dlg)
                return

            sql_get_id = (
                f"SELECT id FROM {lib_vars.schema_name}.config_style "
                f"WHERE idval = '{selected_stylegroup_name}';"
            )
            row_result = tools_db.get_row(sql_get_id)

            if not row_result:
                msg = "Could not find an ID for the style group '{0}'."
                msg_params = (selected_stylegroup_name,)
                tools_qgis.show_warning(msg, dialog=self.style_mng_dlg, msg_params=msg_params)
                return

            new_styleconfig_id = row_result[0]
            sql_check_exists = (
                f"SELECT COUNT(*) "
                f"FROM {lib_vars.schema_name}.sys_style "
                f"WHERE layername = '{table_name}' AND styleconfig_id = {new_styleconfig_id};"
            )
            style_exists = tools_db.get_row(sql_check_exists)[0] > 0

            if style_exists:
                msg = "A style already exists for the layer '{0}' in the selected style group."
                msg_params = (table_name,)
                tools_qgis.show_warning(msg, dialog=self.style_mng_dlg, msg_params=msg_params)
                return

            sql_gw_basic = (
                f"SELECT styletype, stylevalue, active "
                f"FROM {lib_vars.schema_name}.sys_style "
                f"WHERE layername = '{table_name}' AND styleconfig_id = ("
                f"SELECT id FROM {lib_vars.schema_name}.config_style WHERE idval = 'GwBasic'"
                f");"
            )
            existing_style = tools_db.get_row(sql_gw_basic)

            if existing_style:
                styletype, stylevalue, active = existing_style
                stylevalue_clean = stylevalue.replace("'", "''")
            else:
                styletype = 'qml'
                stylevalue_clean = ''
                active = True

            sql_insert_style = (
                f"INSERT INTO {lib_vars.schema_name}.sys_style "
                f"(layername, styleconfig_id, styletype, stylevalue, active) "
                f"VALUES ('{table_name}', {new_styleconfig_id}, '{styletype}', '{stylevalue_clean}', {active});"
            )

            tools_db.execute_sql(sql_insert_style)

            # Show success message
            msg = ("A new style has been added to '{0}' for the layer '{1}' "
                "using the 'GwBasic' style information.\n"
                "You can change it and use 'Update Style' to create a personalized version.")
            msg_params = (selected_stylegroup_name, table_name,)
            tools_qgis.show_message(msg, Qgis.MessageLevel.Success, dialog=self.style_mng_dlg, msg_params=msg_params)

            self._load_styles()

        except Exception as e:
            msg = "An error occurred while adding the style for layer '{0}':\n{1}"
            msg_params = (table_name, str(e),)
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg, msg_params=msg_params)

    def _update_selected_style(self):
        """Update the selected styles in the database with the current QGIS layer style."""
        selected_rows = self.style_mng_dlg.tbl_style.selectionModel().selectedRows()

        if not selected_rows:
            msg = "Please select one or more styles to update."
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg)
            return

        try:
            model = self.style_mng_dlg.tbl_style.model()
            layername_col = tools_qt.get_col_index_by_col_name(self.style_mng_dlg.tbl_style, 'layername')
            category_col = tools_qt.get_col_index_by_col_name(self.style_mng_dlg.tbl_style, 'category')
            if layername_col is None or category_col is None:
                return

            for index in selected_rows:
                layername = model.data(model.index(index.row(), layername_col))
                idval = model.data(model.index(index.row(), category_col))

                msg = ("Are you sure you want to update the style of {0} ({1}) with the symbology"
                        " of the layer in the project? \nYou are going to lose previous information!")
                msg_params = (layername, idval,)
                title = "Update Confirmation"
                reply = tools_qt.show_question(msg, title, force_action=True, msg_params=msg_params)
                if not reply:
                    continue

                layer = tools_qgis.get_layer_by_tablename(layername)
                if layer is None:
                    msg = "Layer '{0}' not found in QGIS."
                    msg_params = (layername,)
                    tools_qgis.show_warning(msg, dialog=self.style_mng_dlg, msg_params=msg_params)
                    continue

                style_value = ''
                with tempfile.NamedTemporaryFile(delete=False, suffix=".qml") as tmp_file:
                    layer.saveNamedStyle(tmp_file.name)
                    with open(tmp_file.name, 'r', encoding='utf-8') as file:
                        style_value = file.read()

                style_value = style_value.replace("'", "''")

                sql_get_id = (
                    f"SELECT id FROM {lib_vars.schema_name}.config_style "
                    f"WHERE idval = '{idval}';"
                )
                styleconfig_id = tools_db.get_row(sql_get_id)
                if not styleconfig_id:
                    msg = "Could not find config_style ID for idval '{0}'."
                    msg_params = (idval,)
                    tools_qgis.show_warning(msg, dialog=self.style_mng_dlg, msg_params=msg_params)
                    continue

                sql_update = (
                    f"UPDATE {lib_vars.schema_name}.sys_style "
                    f"SET stylevalue = '{style_value}' "
                    f"WHERE layername = '{layername}' AND styleconfig_id = {styleconfig_id[0]}"
                )
                tools_db.execute_sql(sql_update)

                msg = "Selected styles updated successfully!"
                tools_qgis.show_success(msg, dialog=self.style_mng_dlg)
                self._load_styles()

        except Exception as e:
            msg = "Failed to update styles"
            param = str(e)
            tools_qgis.show_warning(msg, dialog=self.style_mng_dlg, parameter=param)

    def _refresh_all_styles_mng(self, dialog):
        """ Refreshes all styles in the database and reloads the style table. """
        # Refresh all styles in the database
        tools_gw.refresh_all_styles(dialog)

        # Reload the style table to show updated data
        self._load_styles()
