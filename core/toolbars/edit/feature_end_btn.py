"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from datetime import datetime
from functools import partial

from qgis.PyQt.QtCore import QDate, QStringListModel
from qgis.PyQt.QtSql import QSqlTableModel
from qgis.PyQt.QtWidgets import QAbstractItemView, QTableView, QCompleter
from qgis.core import QgsExpression, QgsFeatureRequest

from ..dialog import GwAction
from ...ui.ui_manager import GwFeatureEndUi, GwInfoWorkcatUi, GwFeatureEndConnecUi
from ...utils import tools_gw
from ...utils.selection_mode import GwSelectionMode
from ....libs import lib_vars, tools_qgis, tools_qt, tools_log, tools_db


class GwFeatureEndButton(GwAction):
    """ Button 28: End feature """

    def __init__(self, icon_path, action_name, text, toolbar, action_group, list_tabs=None, feature_type=None):

        super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.list_tabs = list_tabs
        self.rel_feature_type = feature_type

    def clicked_event(self):

        # Get layers of every feature_type

        # Setting lists
        self.rel_ids = []
        self.rel_list_ids = {}
        self.rel_list_ids['arc'] = []
        self.rel_list_ids['node'] = []
        self.rel_list_ids['connec'] = []
        self.rel_list_ids['gully'] = []
        self.rel_list_ids['element'] = []
        self.rel_list_ids['link'] = []

        # Setting layers
        self.rel_layers = {}
        self.rel_layers['arc'] = []
        self.rel_layers['node'] = []
        self.rel_layers['connec'] = []
        self.rel_layers['gully'] = []
        self.rel_layers['element'] = []
        self.rel_layers['link'] = []

        self.rel_layers['arc'] = tools_gw.get_layers_from_feature_type('arc')
        self.rel_layers['node'] = tools_gw.get_layers_from_feature_type('node')
        self.rel_layers['connec'] = tools_gw.get_layers_from_feature_type('connec')
        self.rel_layers['element'] = [tools_qgis.get_layer_by_tablename('ve_man_genelem'), tools_qgis.get_layer_by_tablename('ve_man_frelem')]
        self.rel_layers['link'] = [tools_qgis.get_layer_by_tablename('ve_link')]

        self.rel_layers = tools_gw.remove_selection(True, layers=self.rel_layers)

        self.rubber_band = tools_gw.create_rubberband(self.canvas)

        self.selected_list = []

        # Create the dialog and signals
        self.dlg_work_end = GwFeatureEndUi(self)
        tools_gw.load_settings(self.dlg_work_end)
        self._set_edit_arc_downgrade_force('True')

        # Capture the current layer to return it at the end of the operation
        self.cur_active_layer = self.iface.activeLayer()

        widget_list = self.dlg_work_end.findChildren(QTableView)
        for widget in widget_list:
            tools_qt.set_tableview_config(widget)

        # Remove tabs
        params = ['arc', 'node', 'connec', 'gully', 'element', 'link']
        if self.list_tabs:
            for i in params:
                if i not in self.list_tabs:
                    tools_qt.remove_tab(self.dlg_work_end.tab_feature, f'tab_{i}')
        else:
            # Remove 'gully' if not 'UD'
            self.project_type = tools_gw.get_project_type()
            if self.project_type != 'ud':
                tools_qt.remove_tab(self.dlg_work_end.tab_feature, 'tab_gully')
            else:
                self.rel_layers['gully'] = tools_gw.get_layers_from_feature_type('gully')

        # Set icons
        tools_gw.add_icon(self.dlg_work_end.btn_insert, "111")
        tools_gw.add_icon(self.dlg_work_end.btn_delete, "112")
        tools_gw.add_icon(self.dlg_work_end.btn_snapping, "137")
        tools_gw.add_icon(self.dlg_work_end.btn_expr_select, "178")
        tools_gw.add_icon(self.dlg_work_end.btn_new_workcat, "150")

        # Adding auto-completion to a QLineEdit
        self.table_object = "cat_work"
        tools_gw.set_completer_object(self.dlg_work_end, self.table_object)

        # Set signals
        excluded_layers = ["ve_arc", "ve_node", "ve_connec", "ve_man_frelem", "ve_man_genelem", "ve_gully", "ve_link"]
        self.excluded_layers = excluded_layers
        layers_visibility = tools_gw.get_parent_layers_visibility()
        self.dlg_work_end.rejected.connect(partial(tools_gw.restore_parent_layers_visibility, layers_visibility))
        self.dlg_work_end.rejected.connect(lambda: tools_gw.reset_rubberband(self.rubber_band))
        self.dlg_work_end.btn_accept.clicked.connect(partial(self._end_feature))
        self.dlg_work_end.btn_cancel.clicked.connect(partial(self._manage_close, self.dlg_work_end, True, False))
        self.dlg_work_end.rejected.connect(partial(self._manage_close, self.dlg_work_end, True, True))
        self.dlg_work_end.workcat_id_end.editTextChanged.connect(partial(self._fill_workids))
        self.dlg_work_end.btn_new_workcat.clicked.connect(partial(self._new_workcat))

        self.dlg_work_end.btn_insert.clicked.connect(
            partial(tools_gw.insert_feature, self, self.dlg_work_end, self.table_object, GwSelectionMode.FEATURE_END, False, None, None))
        self.dlg_work_end.btn_delete.clicked.connect(
            partial(tools_gw.delete_records, self, self.dlg_work_end, self.table_object, GwSelectionMode.FEATURE_END, None, None))
        self.dlg_work_end.btn_snapping.clicked.connect(
            partial(tools_gw.selection_init, self, self.dlg_work_end, self.table_object, GwSelectionMode.FEATURE_END))
        self.dlg_work_end.btn_expr_select.clicked.connect(
            partial(tools_gw.select_with_expression_dialog, self, self.dlg_work_end, self.table_object, GwSelectionMode.FEATURE_END))

        self.dlg_work_end.workcat_id_end.activated.connect(partial(self._fill_workids))

        self.dlg_work_end.tbl_cat_work_x_arc.clicked.connect(partial(tools_qgis.highlight_feature_by_id,
                                                                     self.dlg_work_end.tbl_cat_work_x_arc, "ve_arc", "arc_id", self.rubber_band, 5))
        self.dlg_work_end.tbl_cat_work_x_node.clicked.connect(partial(tools_qgis.highlight_feature_by_id,
                                                                      self.dlg_work_end.tbl_cat_work_x_node, "ve_node", "node_id", self.rubber_band, 10))
        self.dlg_work_end.tbl_cat_work_x_connec.clicked.connect(partial(tools_qgis.highlight_feature_by_id,
                                                                        self.dlg_work_end.tbl_cat_work_x_connec, "ve_connec", "connec_id", self.rubber_band, 10))
        self.dlg_work_end.tbl_cat_work_x_gully.clicked.connect(partial(tools_qgis.highlight_feature_by_id,
                                                                       self.dlg_work_end.tbl_cat_work_x_gully, "ve_gully", "gully_id", self.rubber_band, 10))
        self.dlg_work_end.tbl_cat_work_x_element.clicked.connect(partial(tools_qgis.highlight_feature_by_id,
                                                                         self.dlg_work_end.tbl_cat_work_x_element, "v_ui_element", "element_id", self.rubber_band, 10))
        self.dlg_work_end.tbl_cat_work_x_link.clicked.connect(partial(tools_qgis.highlight_feature_by_id,
                                                                         self.dlg_work_end.tbl_cat_work_x_link, "ve_link", "link_id", self.rubber_band, 10))
        self.dlg_work_end.tab_feature.currentChanged.connect(
            partial(lambda: setattr(self, 'rel_feature_type', tools_gw.get_signal_change_tab(self.dlg_work_end, excluded_layers))))

        tools_gw.disable_tab_log(self.dlg_work_end)

        # Set values
        self._fill_fields()

        # Adding auto-completion to a QLineEdit for default feature
        if self.rel_feature_type is None:
            self.rel_feature_type = "arc"
        if self.rel_feature_type == 'element':
            viewname = "v_ui_element"
        else:
            viewname = f"ve_{self.rel_feature_type}"
        tools_gw.set_completer_widget(viewname, self.dlg_work_end.feature_id, str(self.rel_feature_type + "_id"))

        # Set default tab 'arc'
        self.dlg_work_end.tab_feature.setCurrentIndex(0)
        tools_gw.get_signal_change_tab(self.dlg_work_end, excluded_layers)

        # Open dialog
        tools_gw.open_dialog(self.dlg_work_end, dlg_name='feature_end')

    # region private functions

    def _set_edit_arc_downgrade_force(self, value):

        # Update (or insert) on config_param_user the value of edit_arc_downgrade_force to true
        row = tools_gw.get_config_value('edit_arc_downgrade_force')
        if row:
            sql = ("UPDATE config_param_user "
                   f"SET value = '{value}' "
                   "WHERE parameter = 'edit_arc_downgrade_force' AND cur_user=current_user")
            tools_db.execute_sql(sql)
        else:
            sql = ("INSERT INTO config_param_user (parameter, value, cur_user) "
                   f"VALUES ('edit_arc_downgrade_force', '{value}', current_user)")
            tools_db.execute_sql(sql)

    def _fill_fields(self):
        """ Fill dates and combos cat_work/state type end """

        sql = 'SELECT id as id, name as idval FROM value_state_type WHERE id IS NOT NULL AND state = 0'
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_work_end.cmb_statetype_end, rows)
        row = tools_gw.get_config_value('edit_statetype_0_vdefault')
        if row:
            tools_qt.set_combo_value(self.dlg_work_end.cmb_statetype_end, row[0], 0)
        row = tools_gw.get_config_value('edit_enddate_vdefault')

        if row:
            enddate = self._manage_dates(row[0]).date()
            self.dlg_work_end.enddate.setDate(enddate)
        else:
            enddate = QDate.currentDate()
        tools_qt.set_calendar(self.dlg_work_end, "enddate", enddate)

        sql = "SELECT id, id as idval FROM cat_work"
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_work_end.workcat_id_end, rows)
        tools_qt.set_autocompleter(self.dlg_work_end.workcat_id_end)
        row = tools_gw.get_config_value('edit_workcat_end_vdefault')
        if row:
            tools_qt.set_widget_text(self.dlg_work_end, self.dlg_work_end.workcat_id_end, row[0])

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

    def _fill_workids(self):
        """ Auto fill workid """

        workcat_id = tools_qt.get_text(self.dlg_work_end, self.dlg_work_end.workcat_id_end)
        if not workcat_id:
            return
        sql = (f"SELECT builtdate "
               f"FROM cat_work "
               f"WHERE id = '{workcat_id}'")
        row = tools_db.get_row(sql)
        if row:
            tools_qt.set_calendar(self.dlg_work_end, self.dlg_work_end.builtdate, row['builtdate'], False)
        else:
            tools_qt.set_calendar(self.dlg_work_end, self.dlg_work_end.builtdate, None, False)

    def _set_list_selected_id(self, qtable):

        self.selected_list = []
        selected_list = qtable.model()

        if selected_list is None:
            return

        for x in range(0, selected_list.rowCount()):
            index = selected_list.index(x, 0)
            id_ = selected_list.data(index)
            self.selected_list.append(id_)

    def _end_feature(self, force_downgrade=False):
        """ Get elements from all the tables and update his data """

        # Setting values
        self.workcat_id_end = tools_qt.get_text(self.dlg_work_end, self.dlg_work_end.workcat_id_end)
        self.statetype_id_end = tools_qt.get_combo_value(self.dlg_work_end, self.dlg_work_end.cmb_statetype_end, 0)
        self.enddate = tools_qt.get_calendar_date(self.dlg_work_end, self.dlg_work_end.enddate)
        self.workcatdate = tools_qt.get_calendar_date(self.dlg_work_end, self.dlg_work_end.builtdate)

        self._set_list_selected_id(self.dlg_work_end.tbl_cat_work_x_arc)

        row = None
        if len(self.selected_list) > 0:
            ids = tuple(self.selected_list)

            # When converting it into a tuple, if it only has one element, remove the "," that is added at the end
            if len(self.selected_list) == 1:
                ids = f"{tuple(self.selected_list)}"[:-2] + ")"

            sql = (f"SELECT * FROM v_ui_arc_x_relations "
                   f"WHERE arc_id IN {ids} AND arc_state = '1'")
            row = tools_db.get_row(sql)

        if row and force_downgrade is False:
            self.dlg_work = GwFeatureEndConnecUi(self)
            tools_gw.load_settings(self.dlg_work)

            self.dlg_work.btn_cancel.clicked.connect(partial(self._close_dialog_workcat_list, self.dlg_work))
            self.dlg_work.btn_accept.clicked.connect(self._check_downgrade)
            self._set_completer()

            table_relations = "v_ui_arc_x_relations"
            self.dlg_work.arc_id.textChanged.connect(
                partial(self._filter_by_id, self.dlg_work.tbl_arc_x_relations, self.dlg_work.arc_id, table_relations))

            self.tbl_arc_x_relations = self.dlg_work.findChild(QTableView, "tbl_arc_x_relations")
            self.tbl_arc_x_relations.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)

            filter_ = ""
            for row in self.selected_list:
                filter_ += f"arc_id = '{row}' OR "
            filter_ = filter_[:-3] + ""
            filter_ += " AND arc_state = '1' "
            filter_ += " AND feature_state = 1 "

            tools_qt.fill_table(self.tbl_arc_x_relations, table_relations, filter_)
            tools_gw.set_tablemodel_config(self.dlg_work, self.tbl_arc_x_relations, table_relations)
            self.tbl_arc_x_relations.doubleClicked.connect(
                partial(self._open_selected_object, self.tbl_arc_x_relations))
            self.tbl_arc_x_relations.clicked.connect(
                partial(tools_qgis.highlight_feature_by_id, self.tbl_arc_x_relations, 've_connec', 'connec_id',
                        self.rubber_band, 10, table_field='feature_id'))
            if str(self.project_type) == 'ud':
                self.tbl_arc_x_relations.clicked.connect(
                    partial(tools_qgis.highlight_feature_by_id, self.tbl_arc_x_relations, 've_gully', 'gully_id',
                            self.rubber_band, 10, table_field='feature_id'))

            tools_gw.open_dialog(self.dlg_work, dlg_name='feature_end_connec')

        else:
            # Update tablename of every feature_type
            feature_body_list = ""

            # Manage link
            self._set_list_selected_id(self.dlg_work_end.tbl_cat_work_x_link)
            feature_body = self._manage_feature_body("link")
            if feature_body:
                feature_body_list += f"{feature_body}, "

            # Manage element
            self._set_list_selected_id(self.dlg_work_end.tbl_cat_work_x_element)
            feature_body = self._manage_feature_body("element")
            if feature_body:
                feature_body_list += f"{feature_body}, "

            # Manage connec
            self._set_list_selected_id(self.dlg_work_end.tbl_cat_work_x_connec)
            feature_body = self._manage_feature_body("connec")
            if feature_body:
                feature_body_list += f"{feature_body}, "

            # Manage arc
            self._set_list_selected_id(self.dlg_work_end.tbl_cat_work_x_arc)
            feature_body = self._manage_feature_body("arc")
            if feature_body:
                feature_body_list += f"{feature_body}, "

            # Manage node
            self._set_list_selected_id(self.dlg_work_end.tbl_cat_work_x_node)
            feature_body = self._manage_feature_body("node")
            if feature_body:
                feature_body_list += f"{feature_body}, "

            # Manage gully
            if str(self.project_type) == 'ud':
                self._set_list_selected_id(self.dlg_work_end.tbl_cat_work_x_gully)
                feature_body = self._manage_feature_body("gully")
                if feature_body:
                    feature_body_list += f"{feature_body}, "

            feature_body_list = "[" + feature_body_list[:-2] + "]"

            self._update_feature_type(feature_body_list)

    def _manage_feature_body(self, feature_type):

        if len(self.selected_list) == 0:
            return False

        id_list = ""
        for id_ in self.selected_list:
            id_list += f'"{id_}", '
        id_list = "[" + id_list[:-2] + "]"

        feature_body = f'{{"featureType":"{feature_type}", "featureId":{id_list}}}'

        return feature_body

    def _update_feature_type(self, feature, list_feature=True):
        """ Get elements from @feature_type and update his corresponding table """

        extras = f'"state_type":"{self.statetype_id_end}", '
        extras += f'"enddate":"{self.enddate}", "workcat_date":"{self.workcatdate}"'
        if self.workcat_id_end not in (None, 'null', ''):
            extras += f', "workcat_id_end":"{self.workcat_id_end}"'
        body = tools_gw.create_body(feature=feature, extras=extras, list_feature=list_feature)

        result = tools_gw.execute_procedure('gw_fct_setendfeature', body)
        if result:
            tools_gw.fill_tab_log(self.dlg_work_end, result['body']['data'], tab_idx=2)

    def _open_selected_object(self, widget):
        """ Open object form with selected record of the table """

        selected_list = widget.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_work)
            return

        row = selected_list[0].row()
        feature_id = widget.model().record(row).value("arc_id")

        self._open_arc_form(feature_id)

    def _open_arc_form(self, arc_id):
        """ Open form corresponding to start or end node of the current arc """

        # Get sys_feature_cat.id from cat_feature.id
        sql = (f"SELECT sys_type"
               f" FROM ve_arc"
               f" WHERE arc_id = '{arc_id}'")
        row = tools_db.get_row(sql)
        if not row:
            return

        arc_table = "ve_arc"
        layer_arc = tools_qgis.get_layer_by_tablename(arc_table)

        aux = "\"arc_id\" = "
        aux += f"'{arc_id}'"
        expr = QgsExpression(aux)
        if expr.hasParserError():
            msg = "Expression Error"
            tools_qgis.show_warning(msg, parameter=expr.parserErrorString(), dialog=self.dlg_work)
            return

        id_list = None
        if layer_arc:
            # Get a featureIterator from this expression:
            it = layer_arc.getFeatures(QgsFeatureRequest(expr))
            id_list = [i for i in it]
            if id_list:
                self.iface.openFeatureForm(layer_arc, id_list[0])

        # Zoom to object
        if id_list:
            canvas = self.iface.mapCanvas()
            layer_arc.selectByIds([id_list[0].id()])
            canvas.zoomToSelected(layer_arc)
            canvas.zoomIn()

    def _check_downgrade(self):

        msg = "Are you sure you want to disconnect this elements?"
        title = "Disconnect elements"
        answer = tools_qt.show_question(msg, title)
        if not answer:
            return

        self.dlg_work.close()
        self._end_feature(force_downgrade=True)

    def _set_completer(self):
        """ Set autocompleters of the form """

        # Adding auto-completion to a QLineEdit - visit_id
        completer = QCompleter()
        self.dlg_work.arc_id.setCompleter(completer)
        model = QStringListModel()

        # Convert integers to strings for the QStringListModel
        string_list = [str(item) for item in self.selected_list]
        model.setStringList(string_list)
        completer.setModel(model)

    def _filter_by_id(self, table, widget_txt, tablename):

        id_ = tools_qt.get_text(self.dlg_work, widget_txt)
        if id_ != 'null':
            expr = f" arc_id = '{id_}'"
            # Refresh model with selected filter
            table.model().setFilter(expr)
            table.model().select()
        else:
            self._fill_table_relations(table, self.schema_name + "." + tablename)

    def _fill_table_relations(self, widget, table_name):
        """ Set a model with selected filter. Attach that model to selected table """

        if self.schema_name not in table_name:
            table_name = self.schema_name + "." + table_name

        filter_ = ""
        for row in self.selected_list:
            filter_ += f"arc_id = '{row}' OR "
        filter_ = filter_[:-3] + ""
        filter_ += " AND arc_state = '1' "

        # Set model
        model = QSqlTableModel(db=lib_vars.qgis_db_credentials)
        model.setTable(table_name)
        model.setEditStrategy(QSqlTableModel.EditStrategy.OnManualSubmit)
        model.setFilter(filter_)
        model.select()

        # Check for errors
        if model.lastError().isValid():
            if 'Unable to find table' in model.lastError().text():
                tools_db.reset_qsqldatabase_connection(self.dlg_work)
            else:
                tools_qgis.show_warning(model.lastError().text(), dialog=self.dlg_work)

        # Attach model to table view
        widget.setModel(model)
        widget.show()
        tools_gw.set_tablemodel_config(self.dlg_work, widget, table_name[len(f"{self.schema_name}."):])

    def _close_dialog_workcat_list(self, dlg=None):
        """ Close dialog """

        tools_gw.close_dialog(dlg)
        tools_gw.open_dialog(self.dlg_work_end, dlg_name='feature_end')

    def _manage_close(self, dialog, force_downgrade=False, show_warning=False):
        """ Close dialog and disconnect snapping """

        tools_gw.close_dialog(dialog)
        tools_qgis.disconnect_snapping()
        tools_qgis.disconnect_signal_selection_changed()
        self._set_edit_arc_downgrade_force('False')
        tools_gw.remove_selection(True, layers=self.rel_layers)
        self.canvas.refresh()

    def _new_workcat(self):

        self.dlg_new_workcat = GwInfoWorkcatUi(self)
        tools_gw.load_settings(self.dlg_new_workcat)

        tools_qt.set_calendar(self.dlg_new_workcat, self.dlg_new_workcat.builtdate, None, True)
        table_object = "cat_work"
        tools_gw.set_completer_widget(table_object, self.dlg_new_workcat.cat_work_id, 'id')

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
            values += f"'{cat_work_id}', "
        link = tools_qt.get_text(self.dlg_new_workcat, "link")
        if link != "null":
            fields += 'link, '
            values += f"'{link}', "
        workid_key_1 = tools_qt.get_text(self.dlg_new_workcat, "workid_key_1")
        if workid_key_1 != "null":
            fields += 'workid_key1, '
            values += f"'{workid_key_1}', "
        workid_key_2 = tools_qt.get_text(self.dlg_new_workcat, "workid_key_2")
        if workid_key_2 != "null":
            fields += 'workid_key2, '
            values += f"'{workid_key_2}', "
        builtdate = self.dlg_new_workcat.builtdate.dateTime().toString('yyyy-MM-dd')

        if builtdate != "null":
            fields += 'builtdate, '
            values += f"'{builtdate}', "

        if values == "":
            return

        fields = fields[:-2]
        values = values[:-2]
        if cat_work_id == 'null':
            msg = "Work_id field is empty"
            tools_qt.show_info_box(msg, "Warning")
        else:
            # Check if this element already exists
            sql = (f"SELECT DISTINCT(id)"
                   f" FROM {table_object}"
                   f" WHERE id = '{cat_work_id}'")
            row = tools_db.get_row(sql, log_info=False)
            if row is None:
                sql = f"INSERT INTO cat_work ({fields}) VALUES ({values})"
                tools_db.execute_sql(sql)
                sql = "SELECT id, id as idval FROM cat_work ORDER BY id"
                rows = tools_db.get_rows(sql)
                if rows:
                    tools_qt.fill_combo_values(self.dlg_work_end.workcat_id_end, rows)
                    aux = self.dlg_work_end.workcat_id_end.findText(str(cat_work_id))
                    self.dlg_work_end.workcat_id_end.setCurrentIndex(aux)

                tools_gw.close_dialog(self.dlg_new_workcat)

            else:
                msg = "This Workcat already exist"
                title = "Warning"
                tools_qt.show_info_box(msg, title)

    # endregion
