"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from datetime import datetime
from functools import partial

from qgis.PyQt.QtCore import QDate, Qt
from qgis.PyQt.QtWidgets import QMenu, QAction, QActionGroup, QComboBox

from ..maptool import GwMaptool
from ...ui.ui_manager import GwFeatureReplaceUi, GwInfoWorkcatUi, GwPsectorUi
from ...shared.catalog import GwCatalog
from ...utils import tools_gw
from ....libs import tools_qt, tools_log, tools_qgis, tools_db, tools_os
from .... import global_vars


class GwFeatureReplaceButton(GwMaptool):
    """ Button 26: Replace feature
    User select one feature. Execute SQL function: 'gw_fct_setfeaturereplace' """

    def __init__(self, icon_path, action_name, text, toolbar, action_group, icon_type=1, actions=None, list_tables=None):

        super().__init__(icon_path, action_name, text, toolbar, action_group, icon_type)
        self.current_date = QDate.currentDate().toString('yyyy-MM-dd')
        self.project_type = global_vars.project_type
        self.feature_type = None
        self.geom_view = None
        self.cat_table = None
        self.feature_edit_type = None
        self.feature_type_cat = None
        self.feature_cat_id = None
        self.feature_id = None
        self.actions = actions
        if not self.actions:
            self.actions = [['ARC', tools_qt.tr('ARC'), ['operative', 'plan']], ['NODE', tools_qt.tr('NODE'), ['operative']], ['CONNEC', tools_qt.tr('CONNEC'), ['operative']]]
        if global_vars.project_type in ('UD', 'ud'):
            self.actions.append(['GULLY', tools_qt.tr('GULLY'), ['operative']])
        self.list_tables = list_tables
        if not self.list_tables:
            self.list_tables = ['ve_arc', 've_node', 've_connec', 've_gully']

        # Create a menu and add all the actions
        if toolbar is not None:
            toolbar.removeAction(self.action)

        self.menu = QMenu()
        self.menu.setObjectName("GW_replace_menu")
        self._fill_action_menu()

        if toolbar is not None:
            self.action.setMenu(self.menu)
            toolbar.addAction(self.action)

        # Connect menu aboutToShow signal to update menu
        self.menu.aboutToShow.connect(self._fill_action_menu)

    # region QgsMapTools inherited
    """ QgsMapTools inherited event functions """

    def activate(self):

        # Check action. It works if is selected from toolbar. Not working if is selected from menu or shortcut keys
        if hasattr(self.action, "setChecked"):
            self.action.setChecked(True)

        # Store user snapping configuration
        self.previous_snapping = self.snapper_manager.get_snapping_options()

        # Set snapping to 'node', 'connec' and 'gully'
        self.snapper_manager.set_snapping_layers()

        if global_vars.psignals is not None and global_vars.psignals['psector_active']:
            # Set active layer to 've_arc'
            last_feature_type = "ARC"
        else:
            # Get last feature type selected
            last_feature_type = tools_gw.get_config_parser("btn_feature_replace", "last_feature_type", "user", "session")
            if last_feature_type is None:
                last_feature_type = "NODE"

        # Manage active layer
        self._set_active_layer(last_feature_type)
        layer = self.iface.activeLayer()

        tablename = tools_qgis.get_layer_source_table_name(layer)
        if tablename not in self.list_tables:
            self._set_active_layer(last_feature_type)

        # Change cursor
        self.canvas.setCursor(self.cursor)

        # Show help message when action is activated
        if self.show_help:
            msg = "Click on feature to replace it with a new one. You can select other layer to snap a different feature type."
            tools_qgis.show_info(msg)

    def canvasMoveEvent(self, event):

        # Hide marker and get coordinates
        self.vertex_marker.hide()
        event_point = self.snapper_manager.get_event_point(event)

        # Snapping layers 've_'
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if result.isValid():
            layer = self.snapper_manager.get_snapped_layer(result)
            tablename = tools_qgis.get_layer_source_table_name(layer)
            if tablename and 've' in tablename:
                self.snapper_manager.add_marker(result, self.vertex_marker)

    def canvasReleaseEvent(self, event):

        if event.button() == Qt.MouseButton.RightButton:
            self.cancel_map_tool()
            return

        # Get snapped feature
        event_point = self.snapper_manager.get_event_point(event)
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if not result.isValid():
            return

        snapped_feat = self.snapper_manager.get_snapped_feature(result)
        if snapped_feat is None:
            return

        layer = self.snapper_manager.get_snapped_layer(result)
        tablename = tools_qgis.get_layer_source_table_name(layer)
        if tablename and 've' in tablename:
            if tablename == 've_node':
                self.feature_type = 'node'
            elif tablename == 've_connec':
                self.feature_type = 'connec'
            elif tablename == 've_gully':
                self.feature_type = 'gully'
            elif tablename == 've_arc':
                self.feature_type = 'arc'

            self.geom_view = tablename
            self.cat_table = f'cat_{self.feature_type}'
            self.feature_edit_type = f'{self.feature_type}_type'
            self.feature_type_cat = f'{self.feature_type}_type'
            self.feature_cat_id = f'{self.feature_type}cat_id'
            self.feature_id = snapped_feat.attribute(f'{self.feature_type}_id')
            self.feature_class = snapped_feat.attribute('sys_type')
            self._init_replace_feature_form(snapped_feat)

    # endregion

    # region private functions

    def _fill_action_menu(self):
        """ Fill action menu """

        # disconnect and remove previuos signals and actions
        actions = self.menu.actions()
        for action in actions:
            action.disconnect()
            self.menu.removeAction(action)
            del action
        ag = QActionGroup(self.iface.mainWindow())

        current_mode = 'plan' if global_vars.psignals is not None and global_vars.psignals['psector_active'] else 'operative'

        for action_id, action_name, action_modes in self.actions:
            if current_mode not in action_modes:
                continue
            obj_action = QAction(f"{action_name}", ag)
            self.menu.addAction(obj_action)
            obj_action.triggered.connect(partial(super().clicked_event))
            obj_action.triggered.connect(partial(self._set_active_layer, action_id))
            obj_action.triggered.connect(partial(tools_gw.set_config_parser, section="btn_feature_replace",
                                                 parameter="last_feature_type", value=action_id, comment=None))

    def _set_active_layer(self, name):
        """ Sets the active layer according to the name parameter (ARC, NODE, CONNEC, GULLY) """

        tablename = f"ve_{name.lower()}"
        layer = tools_qgis.get_layer_by_tablename(tablename)
        if layer:
            self.iface.setActiveLayer(layer)
            self.current_layer = layer

    def _manage_dates(self, date_value):
        """ Manage dates """

        date_result = None
        try:
            date_result = str(date_value)
            date_result = date_result.replace("-", "/")
            date_result = datetime.strptime(date_result, '%Y/%m/%d')
        except Exception as e:
            tools_log.log_warning(str(e))
        finally:
            return date_result

    def _init_replace_feature_form(self, feature):

        # Create the dialog and signals
        self.dlg_replace = GwFeatureReplaceUi(self)
        tools_gw.load_settings(self.dlg_replace)
        tools_gw.add_icon(self.dlg_replace.btn_new_workcat, "150")
        tools_gw.add_icon(self.dlg_replace.btn_catalog, "152")

        sql = "SELECT id, id as idval FROM cat_work ORDER BY id"
        rows = tools_db.get_rows(sql)
        if rows:
            tools_qt.fill_combo_values(self.dlg_replace.workcat_id_end, rows)
            tools_qt.set_autocompleter(self.dlg_replace.workcat_id_end)

        row = tools_gw.get_config_value('edit_workcat_vdefault')
        if row:
            edit_workcat_vdefault = self.dlg_replace.workcat_id_end.findText(row[0])
            self.dlg_replace.workcat_id_end.setCurrentIndex(edit_workcat_vdefault)

        row = tools_gw.get_config_value('edit_enddate_vdefault')
        if row:
            self.enddate_aux = self._manage_dates(row[0]).date()
        else:
            work_id = tools_qt.get_text(self.dlg_replace, self.dlg_replace.workcat_id_end)
            sql = f"SELECT builtdate FROM cat_work WHERE id = '{work_id}'"
            row = tools_db.get_row(sql)
            current_date = self._manage_dates(self.current_date)
            if row and row[0]:
                builtdate = self._manage_dates(row[0])
                if builtdate != 'null' and builtdate:
                    self.enddate_aux = builtdate.date()
                else:
                    self.enddate_aux = current_date.date()
            else:
                self.enddate_aux = current_date.date()

        self.dlg_replace.enddate.setDate(self.enddate_aux)

        # Avoid to replace obsolete or planified features
        valid_states = [0, 2]
        if feature.attribute('state') in valid_states:
            msg_params = None
            if feature.attribute('state') == 0:
                msg = "Current feature has state '{0}'. Therefore it is not replaceable"
                state = 'OBSOLETE'
                msg_params = (state,)
            elif feature.attribute('state') == 2:
                msg = "Planified features cannot be replaced"
            tools_qt.show_info_box(msg, "Info", msg_params=msg_params if msg_params is not None else None)
            return

        if self.project_type == 'ud':
            feature_type_new = tools_qt.get_text(self.dlg_replace, "feature_type_new")
            if feature_type_new:
                sql = None
                if self.feature_type in ('node', 'connec', 'gully'):
                    sql = (f"SELECT DISTINCT(id), id as idval "
                           f"FROM {self.cat_table} "
                           f"WHERE {self.feature_type}_type = '{feature_type_new}' or {self.feature_type}_type IS NULL "
                           f"ORDER BY id")
                if sql:
                    rows = tools_db.get_rows(sql)
                    tools_qt.fill_combo_values(self.dlg_replace.new_featurecat_id, rows)

        keep_epa_values = tools_gw.get_config_parser('btn_feature_replace', 'keep_epa_values', "user", "session")
        tools_qt.set_checked(self.dlg_replace, 'keep_epa_values', tools_os.set_boolean(keep_epa_values))

        keep_asset_id = tools_gw.get_config_parser('btn_feature_replace', 'chk_keep_asset_id', "user", "session")
        tools_qt.set_checked(self.dlg_replace, 'chk_keep_asset_id', tools_os.set_boolean(keep_asset_id))

        # Keep customer code only for connec or node with feature class netwjoin and Set default value "True" for keep sys code and keep customer code
        if self.feature_type == 'connec' or (self.feature_type == 'node' and self.feature_class.lower() == 'netwjoin'):
            tools_qt.set_checked(self.dlg_replace, 'chk_keep_customer_code', True)
        else:
            self.dlg_replace.lbl_keep_customer_code.setVisible(False)
            self.dlg_replace.chk_keep_customer_code.setVisible(False)
        tools_qt.set_checked(self.dlg_replace, 'chk_keep_sys_code', True)

        self.dlg_replace.feature_type_new.currentIndexChanged.connect(self._edit_change_elem_type_get_value)
        self.dlg_replace.btn_catalog.clicked.connect(partial(self._open_catalog, self.feature_type))
        self.dlg_replace.workcat_id_end.currentIndexChanged.connect(self._update_date)

        # Get feature type from current feature
        feature_type = feature.attribute(self.feature_edit_type)
        self.dlg_replace.feature_type.setText(feature_type)

        # Fill 1st combo boxes-new system feature type
        sql = (f"SELECT DISTINCT(id), id "
               f"FROM cat_feature "
               f"WHERE lower(feature_type) = '{self.feature_type}' AND active is True "
               f"ORDER BY id")
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_replace.feature_type_new, rows)
        tools_qt.set_combo_value(self.dlg_replace.feature_type_new, feature_type, 0)

        # Fill catalog_id combo box
        self._edit_change_elem_type_get_value(self.dlg_replace.feature_type_new.currentIndex())

        # Get current featurecat_id
        current_featurecat_id = feature.attribute(self.feature_cat_id)
        tools_qt.set_widget_text(self.dlg_replace, self.dlg_replace.current_featurecat_id, current_featurecat_id)

        # Disable tab log
        tools_gw.disable_tab_log(self.dlg_replace)

        # Manage plan widgets
        self._manage_plan_widgets()

        # Set buttons signals
        self.dlg_replace.btn_new_workcat.clicked.connect(partial(self._new_workcat))
        self.dlg_replace.btn_accept.clicked.connect(partial(self._replace_feature, self.dlg_replace))
        self.dlg_replace.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_replace))

        # Open dialog
        tools_gw.open_dialog(self.dlg_replace, dlg_name='feature_replace')

    def _open_catalog(self, feature_type):

        # Get feature_type
        child_type = tools_qt.get_text(self.dlg_replace, self.dlg_replace.feature_type_new)
        if child_type == 'null':
            msg = "New feature type is null. Please, select a valid value."
            tools_qt.show_info_box(msg, "Info")
            return

        self.catalog = GwCatalog()
        self.catalog.open_catalog(self.dlg_replace, 'new_featurecat_id', feature_type, child_type)

    def _update_date(self):

        row = tools_gw.get_config_value('edit_enddate_vdefault')
        if row:
            self.enddate_aux = self._manage_dates(row[0]).date()
        else:
            work_id = tools_qt.get_text(self.dlg_replace, self.dlg_replace.workcat_id_end)
            sql = f"SELECT builtdate FROM cat_work WHERE id = '{work_id}'"
            row = tools_db.get_row(sql)
            current_date = self._manage_dates(self.current_date)
            if row and row[0]:
                builtdate = self._manage_dates(row[0])
                if builtdate != 'null' and builtdate:
                    self.enddate_aux = builtdate.date()
                else:
                    self.enddate_aux = current_date.date()
            else:
                self.enddate_aux = current_date.date()

        self.dlg_replace.enddate.setDate(self.enddate_aux)

    def _new_workcat(self):

        self.dlg_new_workcat = GwInfoWorkcatUi(self)

        tools_gw.load_settings(self.dlg_new_workcat)
        tools_qt.set_calendar(self.dlg_new_workcat, self.dlg_new_workcat.builtdate, None, True)
        table_object = "cat_work"
        tools_gw.set_completer_object(self.dlg_new_workcat, "cat_work")

        # Set signals
        self.dlg_new_workcat.btn_accept.clicked.connect(partial(self._manage_new_workcat_accept, table_object))
        self.dlg_new_workcat.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_new_workcat))

        # Open dialog
        tools_gw.open_dialog(self.dlg_new_workcat, dlg_name='info_workcat')

    def _manage_new_workcat_accept(self, table_object):
        """ Insert table 'cat_work'. Add cat_work """

        # Get values from dialog
        values = ""
        fields = ""
        cat_work_id = tools_qt.get_text(self.dlg_new_workcat, self.dlg_new_workcat.cat_work_id)
        if cat_work_id != "null":
            fields += 'id, '
            values += ("'" + str(cat_work_id) + "', ")
        descript = tools_qt.get_text(self.dlg_new_workcat, "descript")
        if descript != "null":
            fields += 'descript, '
            values += ("'" + str(descript) + "', ")
        link = tools_qt.get_text(self.dlg_new_workcat, "link")
        if link != "null":
            fields += 'link, '
            values += ("'" + str(link) + "', ")
        workid_key_1 = tools_qt.get_text(self.dlg_new_workcat, "workid_key_1")
        if workid_key_1 != "null":
            fields += 'workid_key1, '
            values += ("'" + str(workid_key_1) + "', ")
        workid_key_2 = tools_qt.get_text(self.dlg_new_workcat, "workid_key_2")
        if workid_key_2 != "null":
            fields += 'workid_key2, '
            values += ("'" + str(workid_key_2) + "', ")
        builtdate = self.dlg_new_workcat.builtdate.dateTime().toString('yyyy-MM-dd')
        if builtdate != "null":
            fields += 'builtdate, '
            values += ("'" + str(builtdate) + "', ")

        if values != "":
            fields = fields[:-2]
            values = values[:-2]
            if cat_work_id == 'null':
                msg = "Work_id field is empty"
                tools_qt.show_info_box(msg, "Warning")
            else:
                # Check if this element already exists
                sql = f"SELECT DISTINCT(id) FROM {table_object} WHERE id = '{cat_work_id}'"
                row = tools_db.get_row(sql, log_info=False)
                if row is None:
                    sql = f"INSERT INTO cat_work ({fields}) VALUES ({values})"
                    tools_db.execute_sql(sql)

                    sql = "SELECT id, id as idval FROM cat_work ORDER BY id"
                    rows = tools_db.get_rows(sql)
                    if rows:
                        tools_qt.fill_combo_values(self.dlg_replace.workcat_id_end, rows)
                        current_index = self.dlg_replace.workcat_id_end.findText(str(cat_work_id))
                        self.dlg_replace.workcat_id_end.setCurrentIndex(current_index)

                    tools_gw.close_dialog(self.dlg_new_workcat)
                else:
                    msg = "This Workcat is already exist"
                    tools_qt.show_info_box(msg, "Warning")

    def _replace_feature(self, dialog):

        self.workcat_id_end_aux = tools_qt.get_text(dialog, dialog.workcat_id_end)
        self.enddate_aux = dialog.enddate.date().toString('yyyy-MM-dd')
        feature_type_new = tools_qt.get_text(dialog, dialog.feature_type_new)
        new_featurecat_id = tools_qt.get_text(self.dlg_replace, self.dlg_replace.config.findChild(QComboBox, 'new_featurecat_id'))
        keep_epa_values = tools_qt.is_checked(self.dlg_replace, 'keep_epa_values')
        keep_asset_id = tools_qt.is_checked(self.dlg_replace, 'chk_keep_asset_id')
        description = tools_qt.get_text(self.dlg_replace, 'description')
        tools_gw.set_config_parser('btn_feature_replace', 'keep_epa_values', str(tools_os.set_boolean(keep_epa_values)), "user", "session")
        tools_gw.set_config_parser('btn_feature_replace', 'chk_keep_asset_id', str(tools_os.set_boolean(keep_asset_id)), "user", "session")

        # Check null values
        if feature_type_new in (None, 'null'):
            msg = "Mandatory field is missing. Please, set a value for field"
            tools_qgis.show_warning(msg, parameter="'New feature type'", dialog=dialog)
            return

        if new_featurecat_id in (None, 'null'):
            msg = "Mandatory field is missing. Please, set a value for field"
            tools_qgis.show_warning(msg, parameter="'Catalog id'", dialog=dialog)
            return

        # Ask question before executing
        if global_vars.psignals is not None and global_vars.psignals.get('psector_active'):
            msg = ("Are you sure you want to replace selected feature with a new one?")
        else:
            msg = ("Are you sure you want to replace selected feature with a new one?\n "
                    "If you have different addfields in your feature, they will be deleted.")
        title = "Replace feature"
        answer = tools_qt.show_question(msg, title)
        if answer:
            # Check if psector is active
            if global_vars.psignals is not None and global_vars.psignals['psector_active']:
                feature = f'"featureType":"ARC", "ids":["{self.feature_id}"]'
                extras = f'"catalog":"{new_featurecat_id}"'
                extras += f', "description":"{description}"'
                body = tools_gw.create_body(feature=feature, extras=extras)
                complet_result = tools_gw.execute_procedure('gw_fct_setfeaturereplaceplan', body)
            else:
                # Get function input parameters
                feature = f'"type":"{self.feature_type}"'
                extras = f'"old_feature_id":"{self.feature_id}"'
                extras += f', "feature_type_new":"{feature_type_new}"'
                extras += f', "featurecat_id":"{new_featurecat_id}"'
                if self.workcat_id_end_aux not in (None, 'null', ''):
                    extras += f', "workcat_id_end":"{self.workcat_id_end_aux}"'
                extras += f', "enddate":"{self.enddate_aux}"'
                extras += f', "keep_elements":"{tools_qt.is_checked(dialog, "keep_elements")}"'
                extras += f', "keep_epa_values":"{tools_qt.is_checked(dialog, "keep_epa_values")}"'
                extras += f', "keep_asset_id":"{tools_qt.is_checked(dialog, "chk_keep_asset_id")}"'
                extras += f', "keep_sys_code":"{tools_qt.is_checked(dialog, "chk_keep_sys_code")}"'
                if self.feature_type == 'connec':
                    extras += f', "keep_customer_code":"{tools_qt.is_checked(dialog, "chk_keep_customer_code")}"'
                body = tools_gw.create_body(feature=feature, extras=extras)

                # Execute SQL function and show result to the user
                complet_result = tools_gw.execute_procedure('gw_fct_setfeaturereplace', body)

            if not complet_result or complet_result['status'] == "Failed":
                msg = "Error replacing feature"
                tools_qgis.show_warning(msg)
                return

            # Fill tab 'Info log' and show message
            if complet_result and complet_result['status'] == "Accepted":
                tools_gw.fill_tab_log(self.dlg_replace, complet_result['body']['data'])
                msg = "Feature replaced successfully"
                tools_qgis.show_info(msg)

            # Refresh canvas
            self.refresh_map_canvas()
            for table in self.list_tables:
                tools_qgis.set_layer_index(table)

            # Disable ok button at the end of process
            self.dlg_replace.btn_accept.setEnabled(False)

            # Refresh psector's relations tables
            tools_gw.execute_class_function(GwPsectorUi, '_refresh_tables_relations')

            # Check in init config file if user wants to keep map tool active or not
            self.manage_active_maptool()

    def _edit_change_elem_type_get_value(self, index):
        """ Just select item to 'real' combo 'new_featurecat_id' (that is hidden) """

        if index == -1:
            return

        # Get selected value from 2nd combobox
        feature_type_new = tools_qt.get_text(self.dlg_replace, "feature_type_new")

        # When value is selected, enabled 3rd combo box
        if feature_type_new == 'null':
            return

        sql = ""
        if self.project_type == 'ws':
            # Fill 3rd combo_box-catalog_id
            tools_qt.set_widget_enabled(self.dlg_replace, self.dlg_replace.new_featurecat_id, True)
            sql = (f"SELECT DISTINCT(id), id as idval "
                   f"FROM {self.cat_table} "
                   f"WHERE {self.feature_type_cat} = '{feature_type_new}' AND (active IS TRUE OR active IS NULL)"
                   f"ORDER BY id")

        elif self.project_type == 'ud':
            sql = (f"SELECT DISTINCT(id), id as idval "
                   f"FROM {self.cat_table} "
                   f"WHERE {self.feature_type}_type = '{feature_type_new}' or {self.feature_type}_type IS NULL "
                   f"AND (active IS TRUE OR active IS NULL) "
                   f"ORDER BY id")

        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_replace.new_featurecat_id, rows)
        
        # Set default value
        default_value = tools_gw.get_config_value(f"feat_{feature_type_new.lower()}_vdefault")
        default_value = default_value[0] if default_value[0] else default_value
        if default_value and default_value[0] and default_value[0] is not None:
            tools_qt.set_combo_value(self.dlg_replace.new_featurecat_id, default_value, 0)
        tools_qt.set_autocompleter(self.dlg_replace.new_featurecat_id)

    def _manage_plan_widgets(self):
        if global_vars.psignals is not None and global_vars.psignals['psector_active']:
            # Hide unused widgets for plan
            self.dlg_replace.grb_end_parameters.setVisible(False)
            self.dlg_replace.lbl_feature_type.setVisible(False)
            self.dlg_replace.feature_type.setVisible(False)
            self.dlg_replace.lbl_new_feature_type.setVisible(False)
            self.dlg_replace.feature_type_new.setVisible(False)
            self.dlg_replace.lbl_keep_elements.setVisible(False)
            self.dlg_replace.keep_elements.setVisible(False)
            self.dlg_replace.lbl_keep_epa_values.setVisible(False)
            self.dlg_replace.keep_epa_values.setVisible(False)
            self.dlg_replace.lbl_keep_asset_id.setVisible(False)
            self.dlg_replace.chk_keep_asset_id.setVisible(False)
            self.dlg_replace.lbl_keep_sys_code.setVisible(False)
            self.dlg_replace.chk_keep_sys_code.setVisible(False)
            self.dlg_replace.lbl_keep_customer_code.setVisible(False)
            self.dlg_replace.chk_keep_customer_code.setVisible(False)
        else:
            self.dlg_replace.lbl_description.setVisible(False)
            self.dlg_replace.description.setVisible(False)

    # endregion