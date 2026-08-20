"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import webbrowser
import json
from functools import partial
from osgeo import gdal
from qgis.PyQt.sip import isdeleted

from qgis.PyQt.QtGui import QStandardItemModel, QCursor
from qgis.PyQt.QtWidgets import QAbstractItemView, QTableView, QAction, QMenu, QPushButton, QHeaderView
from qgis.PyQt.QtCore import pyqtSignal, QObject, Qt

from ..utils import tools_gw
from ..utils.selection_mode import GwSelectionMode
from ..ui.ui_manager import GwDocUi, GwDocManagerUi
from ... import global_vars
from ..utils.snap_manager import GwSnapManager
from ...libs import lib_vars, tools_qt, tools_db, tools_qgis, tools_os


class GwDocument(QObject):
    doc_added = pyqtSignal()

    def __init__(self, single_tool=True):
        """ Class to control action 'Add document' of toolbar 'edit' """

        QObject.__init__(self)
        # parameter to set if the document manager is working as
        # single tool or integrated in another tool
        self.single_tool_mode = single_tool
        self.previous_dialog = None
        self.iface = global_vars.iface
        self.snapper_manager = GwSnapManager(self.iface)
        self.vertex_marker = self.snapper_manager.vertex_marker
        self.canvas = global_vars.canvas
        self.schema_name = lib_vars.schema_name
        self.files_path = []
        self.project_type = tools_gw.get_project_type()
        self.doc_tables = ["doc_x_node", "doc_x_arc", "doc_x_connec", "doc_x_link", "doc_x_gully", "doc_x_workcat", "doc_x_psector", "doc_x_visit", "doc_x_element"]
        self.point_xy = {"x": None, "y": None}
        self.is_new = False

    def get_document(self, tablename=None, qtable=None, item_id=None, feature=None, feature_type=None, row=None, list_tabs=None, doc_tables=None):
        """ Button 31: Add document """

        self.rubber_band = tools_gw.create_rubberband(self.canvas)
        # Create the dialog and signals
        self.dlg_add_doc = GwDocUi(self)
        tools_gw.load_settings(self.dlg_add_doc)
        self.doc_id = None
        self.doc_name = None
        self.files_path = []

        # Capture the current layer to return it at the end of the operation
        cur_active_layer = self.iface.activeLayer()

        widget_list = self.dlg_add_doc.findChildren(QTableView)
        for widget in widget_list:
            tools_qt.set_tableview_config(widget)

        # Get layers of every feature_type

        # Setting lists
        self.rel_ids = []
        self.rel_list_ids = {'arc': [], 'node': [], 'connec': [], 'link': [], 'gully': [], 'element': []}
        self.rel_layers = {'arc': [], 'node': [], 'connec': [], 'link': [], 'gully': [], 'element': []}
        self.rel_layers['arc'] = tools_gw.get_layers_from_feature_type('arc')
        self.rel_layers['node'] = tools_gw.get_layers_from_feature_type('node')
        self.rel_layers['connec'] = tools_gw.get_layers_from_feature_type('connec')
        self.rel_layers['link'] = tools_gw.get_layers_from_feature_type('link')
        self.rel_layers['element'] = tools_gw.get_layers_from_feature_type('element')

        # Add manager element layers (ve_man_frelem, ve_man_genelem) if they exist
        for layer_name in ['ve_man_frelem', 've_man_genelem']:
            layer = tools_qgis.get_layer_by_tablename(layer_name)
            if layer and layer not in self.rel_layers['element']:
                self.rel_layers['element'].append(layer)

        if self.project_type == 'ud':
            self.rel_layers['gully'] = tools_gw.get_layers_from_feature_type('gully')

        params = ['arc', 'node', 'connec', 'gully', 'link', 'element']
        if list_tabs:
            for i in params:
                if i not in list_tabs:
                    tools_qt.remove_tab(self.dlg_add_doc.tab_feature, f'tab_{i}')

        # Remove 'gully' if not 'UD'
        if self.project_type != 'ud':
            tools_qt.remove_tab(self.dlg_add_doc.tab_feature, 'tab_gully')

        if doc_tables:
            self.doc_tables = doc_tables
        # Remove all previous selections
        if self.single_tool_mode:
            self.rel_layers = tools_gw.remove_selection(True, layers=self.rel_layers)

        if feature is not None:
            layer = self.rel_layers[feature_type][0]
            layer.selectByIds([feature.id()])

        # Set icons
        tools_gw.add_icon(self.dlg_add_doc.btn_add_geom, "133")
        tools_gw.add_icon(self.dlg_add_doc.btn_insert, "111")
        tools_gw.add_icon(self.dlg_add_doc.btn_insert_workcat, "111")
        tools_gw.add_icon(self.dlg_add_doc.btn_insert_psector, "111")
        tools_gw.add_icon(self.dlg_add_doc.btn_insert_visit, "111")
        tools_gw.add_icon(self.dlg_add_doc.btn_delete, "112")
        tools_gw.add_icon(self.dlg_add_doc.btn_delete_workcat, "112")
        tools_gw.add_icon(self.dlg_add_doc.btn_delete_psector, "112")
        tools_gw.add_icon(self.dlg_add_doc.btn_delete_visit, "112")
        tools_gw.add_icon(self.dlg_add_doc.btn_snapping, "137")
        tools_gw.add_icon(self.dlg_add_doc.btn_expr_select, "178")

        # Fill combo boxes
        self._fill_combo_doc_type(self.dlg_add_doc.doc_type)

        # If document exists
        if item_id and row:
            self.is_new = False
            # Enable tabs
            for n in range(1, 5):
                self.dlg_add_doc.tabWidget.setTabEnabled(n, True)

            self._fill_dialog_document(self.dlg_add_doc, "doc", None, doc_id=item_id)
            self._activate_relations()
            self._fill_table_doc_workcat()
            self._fill_table_doc_psector()
            self._fill_table_doc_visit()
        # If document is new
        else:
            self.is_new = True
            # Disable tabs
            for n in range(1, 5):
                self.dlg_add_doc.tabWidget.setTabEnabled(n, False)

            tools_qt.set_calendar(self.dlg_add_doc, 'date', None)

        # Adding auto-completion to a QLineEdit
        table_object = "doc"
        tools_gw.set_completer_object(self.dlg_add_doc, table_object, field_id="name")

        # Adding auto-completion to a QLineEdit for default feature
        if feature_type is None:
            feature_type = "arc"
        viewname = f"ve_{feature_type}"
        tools_gw.set_completer_widget(viewname, self.dlg_add_doc.feature_id, str(feature_type) + "_id")

        # Config Workcat
        tools_gw.set_completer_widget("cat_work", self.dlg_add_doc.feature_id_workcat, "id")

        self.dlg_add_doc.btn_insert_workcat.clicked.connect(partial(self._insert_workcat, self.dlg_add_doc))
        self.dlg_add_doc.btn_delete_workcat.clicked.connect(partial(self._delete_workcat, self.dlg_add_doc))
        self.dlg_add_doc.feature_id_workcat.textChanged.connect(
            partial(tools_gw.set_completer_object, self.dlg_add_doc, "workcat"))

        # Config Psector
        tools_gw.set_completer_widget("plan_psector", self.dlg_add_doc.feature_id_psector, "name")

        self.dlg_add_doc.btn_insert_psector.clicked.connect(partial(self._insert_psector, self.dlg_add_doc))
        self.dlg_add_doc.btn_delete_psector.clicked.connect(partial(self._delete_psector, self.dlg_add_doc))
        self.dlg_add_doc.feature_id_psector.textChanged.connect(
            partial(tools_gw.set_completer_object, self.dlg_add_doc, "psector"))

        # Config Visit
        tools_gw.set_completer_widget("om_visit", self.dlg_add_doc.feature_id_visit, "id")

        self.dlg_add_doc.btn_insert_visit.clicked.connect(partial(self._insert_visit, self.dlg_add_doc))
        self.dlg_add_doc.btn_delete_visit.clicked.connect(partial(self._delete_visit, self.dlg_add_doc))
        self.dlg_add_doc.feature_id_visit.textChanged.connect(
            partial(tools_gw.set_completer_object, self.dlg_add_doc, "visit"))

        # Set signals
        self.excluded_layers = ["ve_arc", "ve_node", "ve_connec", "ve_man_frelem", "ve_gully",
                                "ve_man_genelem", "ve_link", "ve_element"]
        layers_visibility = tools_gw.get_parent_layers_visibility()

        # Dialog
        self.dlg_add_doc.rejected.connect(lambda: tools_gw.reset_rubberband(self.rubber_band))
        self.dlg_add_doc.rejected.connect(partial(tools_gw.restore_parent_layers_visibility, layers_visibility))
        self.dlg_add_doc.rejected.connect(
            lambda: setattr(self, 'layers', tools_gw.manage_close(self.dlg_add_doc, table_object, cur_active_layer, self.single_tool_mode, self.rel_layers))
        )
        # Widgets
        self.dlg_add_doc.doc_name.textChanged.connect(partial(self._check_doc_exists))
        self.dlg_add_doc.doc_type.currentIndexChanged.connect(self._activate_relations)
        self.dlg_add_doc.btn_path_url.clicked.connect(partial(self._open_web_browser, self.dlg_add_doc, "path"))
        self.dlg_add_doc.btn_path_doc.clicked.connect(
            lambda: setattr(self, 'files_path', self._get_file_dialog(self.dlg_add_doc, "path"))
        )
        self.dlg_add_doc.btn_add_geom.clicked.connect(self._get_point_xy)
        # Dialog buttons
        self.dlg_add_doc.btn_accept.clicked.connect(
            partial(self._manage_document_accept, table_object, tablename, qtable, item_id, True)
        )
        self.dlg_add_doc.btn_cancel.clicked.connect(
            lambda: setattr(self, 'layers', tools_gw.manage_close(self.dlg_add_doc, table_object, cur_active_layer, self.single_tool_mode, self.rel_layers))
        )
        self.dlg_add_doc.btn_apply.clicked.connect(
            partial(self._manage_document_accept, table_object, tablename, qtable, item_id, False)
        )
        # Tab relations
        self.dlg_add_doc.tab_feature.currentChanged.connect(self._on_tab_changed)
        self.dlg_add_doc.btn_insert.clicked.connect(
            partial(tools_gw.insert_feature, self, self.dlg_add_doc, table_object, GwSelectionMode.DEFAULT, False, None, None))
        self.dlg_add_doc.btn_delete.clicked.connect(
            partial(tools_gw.delete_records, self, self.dlg_add_doc, table_object, GwSelectionMode.DEFAULT, None, None))
        self.dlg_add_doc.btn_snapping.clicked.connect(
            partial(tools_gw.selection_init, self, self.dlg_add_doc, table_object, GwSelectionMode.DEFAULT))
        self.dlg_add_doc.btn_expr_select.clicked.connect(
            partial(tools_gw.select_with_expression_dialog, self, self.dlg_add_doc, table_object, GwSelectionMode.DEFAULT)
        )

        self.dlg_add_doc.tbl_doc_x_arc.clicked.connect(partial(tools_qgis.highlight_feature_by_id,
                                                               self.dlg_add_doc.tbl_doc_x_arc, "ve_arc", "arc_id", self.rubber_band, 5))
        self.dlg_add_doc.tbl_doc_x_node.clicked.connect(partial(tools_qgis.highlight_feature_by_id,
                                                                self.dlg_add_doc.tbl_doc_x_node, "ve_node", "node_id", self.rubber_band, 10))
        self.dlg_add_doc.tbl_doc_x_connec.clicked.connect(partial(tools_qgis.highlight_feature_by_id,
                                                                  self.dlg_add_doc.tbl_doc_x_connec, "ve_connec", "connec_id", self.rubber_band, 10))
        self.dlg_add_doc.tbl_doc_x_gully.clicked.connect(partial(tools_qgis.highlight_feature_by_id,
                                                                 self.dlg_add_doc.tbl_doc_x_gully, "ve_gully", "gully_id", self.rubber_band, 10))
        self.dlg_add_doc.tbl_doc_x_link.clicked.connect(partial(tools_qgis.highlight_feature_by_id,
                                                                 self.dlg_add_doc.tbl_doc_x_link, "ve_link", "link_id", self.rubber_band, 10))
        self.dlg_add_doc.tbl_doc_x_element.clicked.connect(partial(tools_qgis.highlight_feature_by_id,
                                                                 self.dlg_add_doc.tbl_doc_x_element, "ve_element", "element_id", self.rubber_band, 10))
        if feature:
            self.dlg_add_doc.tabWidget.currentChanged.connect(
                partial(self._fill_table_doc, self.dlg_add_doc, feature_type, feature[feature_type + "_id"]))

        # Set default tab 'arc'
        self.dlg_add_doc.tab_feature.setCurrentIndex(0)
        self.rel_feature_type = "arc"
        tools_gw.get_signal_change_tab(self.dlg_add_doc, self.excluded_layers)

        # Open the dialog
        tools_gw.open_dialog(self.dlg_add_doc, dlg_name='doc')

        return self.dlg_add_doc

    def _on_tab_changed(self):
        """ Update rel_feature_type when tab changes """
        # Get current tab's feature type
        self.rel_feature_type = tools_gw.get_signal_change_tab(self.dlg_add_doc, self.excluded_layers)

    def _fill_table_doc_workcat(self):
        expr_filter = f"name = '{self.doc_name}'"
        table_name = "v_ui_doc_x_workcat"

        tools_qt.fill_table(self.dlg_add_doc.tbl_doc_x_workcat, table_name, expr_filter)
        tools_gw.set_tablemodel_config(self.dlg_add_doc, self.dlg_add_doc.tbl_doc_x_workcat, table_name)

    def _insert_workcat(self, dialog):
        """Associate an existing workcat with the current document, ensuring no duplicates and clearing the input field"""
        workcat_id = tools_qt.get_text(dialog, "feature_id_workcat")

        if workcat_id == 'null':
            msg = "You need to enter a workcat id"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        sql = f"INSERT INTO doc_x_workcat (doc_id, workcat_id) VALUES ({self.doc_id}, '{workcat_id}')"
        result = tools_db.execute_sql(sql)

        if result:
            dialog.feature_id_workcat.clear()
            self._fill_table_doc_workcat()

    def _delete_workcat(self, dialog):
        """Delete the selected workcat from the document"""
        qtable = dialog.tbl_doc_x_workcat
        # Get selected rows
        if qtable.selectionModel() is None:
            msg = "No workcat values"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        selected_list = qtable.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        col_idx = tools_qt.get_col_index_by_col_name(qtable, "workcat_id")
        workcat_ids = []
        for row in selected_list:
            workcat_id = qtable.model().index(row.row(), col_idx).data()
            workcat_ids.append(workcat_id)

        inf_text = ", ".join(workcat_ids)
        msg = "Are you sure you want to delete these records?"
        title = "Delete records"
        answer = tools_qt.show_question(msg, title, inf_text)

        if not answer:
            return

        for workcat_id in workcat_ids:
            sql = f"DELETE FROM doc_x_workcat WHERE doc_id = {self.doc_id} AND workcat_id = '{workcat_id}'"
            tools_db.execute_sql(sql)

        self._fill_table_doc_workcat()

    def _fill_table_doc_psector(self):
        expr_filter = f"doc_name = '{self.doc_name}'"
        table_name = "v_ui_doc_x_psector"

        tools_qt.fill_table(self.dlg_add_doc.tbl_doc_x_psector, table_name, expr_filter)
        tools_gw.set_tablemodel_config(self.dlg_add_doc, self.dlg_add_doc.tbl_doc_x_psector, table_name)

    def _insert_psector(self, dialog):
        """Associate an existing psector with the current document, ensuring no duplicates and clearing the input field"""
        psector_name = tools_qt.get_text(dialog, "feature_id_psector")

        if psector_name == 'null' or not psector_name:
            msg = "You need to enter a psector name"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        sql = f"SELECT psector_id FROM plan_psector WHERE name = '{psector_name}'"
        row = tools_db.get_row(sql)
        if not row:
            msg = "Psector name not found"
            tools_qgis.show_warning(msg, dialog=dialog)
            return
        psector_id = row[0]

        sql = f"INSERT INTO doc_x_psector (doc_id, psector_id) VALUES ({self.doc_id}, '{psector_id}')"
        result = tools_db.execute_sql(sql)

        if result:
            dialog.feature_id_psector.clear()
            self._fill_table_doc_psector()

    def _delete_psector(self, dialog):
        """Delete the selected psector from the document"""
        qtable = dialog.tbl_doc_x_psector

        # Get selected rows
        if qtable.selectionModel() is None:
            msg = "No psector values"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        selected_list = qtable.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        col_idx = tools_qt.get_col_index_by_col_name(qtable, "psector_name")
        psector_names = []
        psector_ids = []
        for row in selected_list:
            psector_name = qtable.model().index(row.row(), col_idx).data()
            psector_names.append(psector_name)

        for psector_name in psector_names:
            sql = f"SELECT psector_id FROM plan_psector WHERE name = '{psector_name}'"
            row = tools_db.get_row(sql)
            if row:
                psector_ids.append(row[0])

        if not psector_ids:
            msg = "No valid psector IDs found"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        inf_text = ", ".join(map(str, psector_names))
        msg = "Are you sure you want to delete these records?"
        title = "Delete records"
        answer = tools_qt.show_question(msg, title, inf_text)

        if not answer:
            return

        for psector_id in psector_ids:
            sql = f"DELETE FROM doc_x_psector WHERE doc_id = {self.doc_id} AND psector_id = '{psector_id}'"
            tools_db.execute_sql(sql)

        self._fill_table_doc_psector()

    def _fill_table_doc_visit(self):
        expr_filter = f"doc_name = '{self.doc_name}'"
        table_name = "v_ui_doc_x_visit"

        tools_qt.fill_table(self.dlg_add_doc.tbl_doc_x_visit, table_name, expr_filter)
        tools_gw.set_tablemodel_config(self.dlg_add_doc, self.dlg_add_doc.tbl_doc_x_visit, table_name)

    def _insert_visit(self, dialog):
        """Associate an existing visit with the current document, ensuring no duplicates and clearing the input field"""
        visit_id = tools_qt.get_text(dialog, "feature_id_visit")

        if visit_id == 'null' or not visit_id:
            msg = "You need to enter a visit ID"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        sql = f"INSERT INTO doc_x_visit (doc_id, visit_id) VALUES ({self.doc_id}, '{visit_id}')"
        result = tools_db.execute_sql(sql)

        if result:
            dialog.feature_id_visit.clear()
            self._fill_table_doc_visit()

    def _delete_visit(self, dialog):
        """Delete the selected visit from the document"""
        qtable = dialog.tbl_doc_x_visit

        # Get selected rows
        if qtable.selectionModel() is None:
            msg = "No visit values"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        selected_list = qtable.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        col_idx = tools_qt.get_col_index_by_col_name(qtable, "visit_id")
        visit_ids = []
        for row in selected_list:
            visit_id = qtable.model().index(row.row(), col_idx).data()
            visit_ids.append(visit_id)

        inf_text = ", ".join(map(str, visit_ids))
        msg = "Are you sure you want to delete these records?"
        title = "Delete records"
        answer = tools_qt.show_question(msg, title, inf_text)

        if not answer:
            return

        for visit_id in visit_ids:
            sql = f"DELETE FROM doc_x_visit WHERE doc_id = {self.doc_id} AND visit_id = '{visit_id}'"
            tools_db.execute_sql(sql)

        self._fill_table_doc_visit()

    def _get_existing_doc_names(self):
        """ list of existing names """
        sql = "SELECT name FROM doc ORDER BY name;"
        rows = tools_db.get_rows(sql)
        return [row['name'] for row in rows if 'name' in row]

    def manage_documents(self):
        """ Button 32: Edit document """

        # Create the dialog
        self.dlg_man = GwDocManagerUi(self)
        self.dlg_man.setProperty('class_obj', self)
        tools_gw.load_settings(self.dlg_man)
        tools_qt.set_tableview_config(self.dlg_man.tbl_document, section_resize_mode=QHeaderView.ResizeMode.Interactive)
        tools_qt.set_tableview_config(self.dlg_man.tbl_document)

        # Adding auto-completion to a QLineEdit
        table_object = "doc"
        tools_gw.set_completer_object(self.dlg_man, table_object, field_id="name")

        # Populate custom context menu
        self.dlg_man.tbl_document.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.dlg_man.tbl_document.customContextMenuRequested.connect(partial(self._show_context_menu, self.dlg_man.tbl_document))

        status = self._fill_table()
        if not status:
            return False, False

        # Set signals
        self.dlg_man.doc_name.textChanged.connect(self._fill_table)
        self.dlg_man.tbl_document.doubleClicked.connect(
            partial(self._open_selected_object_document, self.dlg_man, self.dlg_man.tbl_document, table_object))
        self.dlg_man.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_man))
        self.dlg_man.rejected.connect(partial(tools_gw.close_dialog, self.dlg_man))
        self.dlg_man.btn_delete.clicked.connect(self._handle_delete)
        self.dlg_man.btn_create.clicked.connect(partial(self.open_document_dialog))

        # Open form
        tools_gw.open_dialog(self.dlg_man, dlg_name='doc_manager')

    def _show_context_menu(self, qtableview, pos):
        """ Show custom context menu """
        menu = QMenu(qtableview)

        action_open = QAction("Open", qtableview)
        action_open.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QTableView, qtableview.objectName(), pos))
        menu.addAction(action_open)

        action_delete = QAction("Delete", qtableview)
        action_delete.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_delete"))
        menu.addAction(action_delete)

        menu.exec(QCursor.pos())

    def _handle_delete(self):
        tools_gw.delete_selected_rows(self.dlg_man.tbl_document, "doc", "name", 1)
        self._refresh_manager_table()

    def _fill_table(self, filter_text=None):
        # Set a model with selected filter. Attach that model to selected table
        view = "v_ui_doc"
        if filter_text is None:
            filter_text = ""
        complet_list = tools_gw.get_list(view, filter_name=filter_text, id_field="name")
        if complet_list is False:
            return False
        data = complet_list['body']['data']
        headers = complet_list['body']['form'].get('headers')
        fields = data['fields']
        if data.get('hidden'):
            return False
        model = self.dlg_man.tbl_document.model()
        if model is None:
            model = QStandardItemModel()
            self.dlg_man.tbl_document.setModel(model)
        model.removeRows(0, model.rowCount())

        if fields:
            self.dlg_man.tbl_document = tools_gw.add_tableview_header(self.dlg_man.tbl_document, fields, headers)
            self.dlg_man.tbl_document = tools_gw.fill_tableview_rows(self.dlg_man.tbl_document, fields)
        tools_gw.set_tablemodel_config(self.dlg_man, self.dlg_man.tbl_document, 'v_ui_doc', Qt.SortOrder.AscendingOrder)
        tools_qt.set_tableview_config(self.dlg_man.tbl_document, section_resize_mode=QHeaderView.ResizeMode.Interactive)

        return True

    # region private functions

    def open_document_dialog(self):
        self.get_document()

    def _refresh_manager_table(self):
        """ Refresh the manager table """
        try:
            if getattr(self, 'dlg_man', None):
                # Use the existing _fill_table method to refresh the table
                self._fill_table()
        except Exception as e:
            print(f"Error refreshing manager table: {e}")

    def _fill_combo_doc_type(self, widget):
        """ Executes query and fill combo box """

        sql = ("SELECT id, idval"
               " FROM v_edit_typevalue"
               " WHERE typevalue = 'doc_type'"
               " ORDER BY id;")
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(widget, rows, add_empty=True)
        doctype_vdefault = tools_gw.get_config_value('edit_doctype_vdefault')
        if doctype_vdefault:
            tools_qt.set_combo_value(widget, doctype_vdefault[0], 0)
            self._activate_relations()

    def _activate_relations(self):
        """ Force user to set doc_id and doc_type """

        doc_type = tools_qt.get_combo_value(self.dlg_add_doc, self.dlg_add_doc.doc_type)

        if doc_type in (None, '', 'null'):
            self.dlg_add_doc.tabWidget.setTabEnabled(1, False)
        else:
            self.dlg_add_doc.tabWidget.setTabEnabled(1, True)

    def _activate_tabs(self, activate):

        # Enable tabs
        for n in range(2, 5):
            self.dlg_add_doc.tabWidget.setTabEnabled(n, activate)

    def _fill_table_doc(self, dialog, feature_type, feature_id):
        widget = "tbl_doc_x_" + feature_type
        widget = dialog.findChild(QTableView, widget)
        widget.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        expr_filter = f"{feature_type}_id = '{feature_id}'"

        # Set model of selected widget
        table_name = f"ve_{feature_type}"
        message = tools_qt.fill_table(widget, f"{self.schema_name}.{table_name}", expr_filter)
        if message:
            tools_qgis.show_warning(message)
        tools_gw.set_tablemodel_config(dialog, widget, table_name)

    def _manage_document_accept(self, table_object, tablename=None, qtable=None, item_id=None, close_dlg=True):
        """ Insert or update table 'document'. Add document to selected feature """

        # Get values from dialog
        name = tools_qt.get_text(self.dlg_add_doc, "doc_name", False, False)
        doc_type = tools_qt.get_combo_value(self.dlg_add_doc, self.dlg_add_doc.doc_type)
        date = tools_qt.get_calendar_date(self.dlg_add_doc, "date", datetime_format="yyyy/MM/dd")
        path = tools_qt.get_text(self.dlg_add_doc, "path", return_string_null=False)
        observ = tools_qt.get_text(self.dlg_add_doc, "observ", False, False)

        # Get SRID
        srid = lib_vars.data_epsg

        # Prepare the_geom value
        the_geom = None
        if self.point_xy["x"] is not None and self.point_xy["y"] is not None:
            the_geom = f"ST_SetSRID(ST_MakePoint({self.point_xy['x']},{self.point_xy['y']}), {srid})"

        # Check if this document already exists
        if item_id is None:
            item_id = self.doc_id
        row = None
        if item_id is not None:
            sql = f"SELECT DISTINCT(id) FROM {table_object} WHERE id = '{item_id}'"
            row = tools_db.get_row(sql, log_info=False)
        
        # If document not exists perform an INSERT
        if row is None and self.is_new:
            if len(self.files_path) <= 1:
                sql, doc_id = self._insert_doc_sql(doc_type, observ, date, path, the_geom, name)
                if doc_id is None:
                    return
            else:
                msg = ("You have selected multiple documents. In this case, name will be a sequential number for "
                       "all selected documents and your name won't be used.")
                title = "Add document"
                answer = tools_qt.show_question(msg, title)
                if answer:
                    for k, file in enumerate(self.files_path):
                        n = k + 1
                        temp_name = f"{name}_{n}"
                        sql, doc_id = self._insert_doc_sql(doc_type, observ, date, file, the_geom, temp_name)
        else:
            doc_id = row['id']
            if len(self.files_path) <= 1:
                sql = self._update_doc_sql(doc_type, observ, date, doc_id, path, the_geom, name)
            else:
                msg = ("You have selected multiple documents. In this case, name will be a sequential number for "
                       "all selected documents and your name won't be used.")
                title = "Add document"
                answer = tools_qt.show_question(msg, title)
                if answer:
                    for k, file in enumerate(self.files_path):
                        n = k + 1
                        temp_name = f"{name}_{n}"
                        sql, doc_id = self._insert_doc_sql(doc_type, observ, date, file, the_geom, temp_name)
        self._update_doc_tables(sql, doc_id, table_object, tablename, item_id, qtable, name, close_dlg=close_dlg)
        self.doc_added.emit()

        # Clear the_geom after use
        self.point_xy = {"x": None, "y": None}

        # Refresh manager table
        tools_gw.execute_class_function(GwDocManagerUi, '_refresh_manager_table')

    def _insert_doc_sql(self, doc_type, observ, date, path, the_geom, name):
        fields = "doc_type, path, observ, date, name"
        values = f"'{doc_type}', '{path}', '{observ}', '{date}', '{name}'"
        if the_geom:
            fields += ", the_geom"
            values += f", {the_geom}"
        sql = (f"INSERT INTO doc ({fields}) "
               f"VALUES ({values}) RETURNING id;")
        new_doc_id = tools_db.execute_returning(sql)
        sql = ""
        if new_doc_id is False:
            return None, None
        doc_id = str(new_doc_id[0])
        return sql, doc_id

    def _update_doc_sql(self, doc_type, observ, date, doc_id, path, the_geom, name):
        sql = (f"UPDATE doc "
               f"SET doc_type = '{doc_type}', observ = '{observ}', path = '{path}', date = '{date}', name = '{name}'")
        if the_geom:
            sql += f", the_geom = {the_geom}"
        sql += f" WHERE id = {doc_id};"
        return sql

    def _update_doc_tables(self, sql, doc_id, table_object, tablename, item_id, qtable, doc_name, close_dlg=True):

        if sql is not None and sql != "":
            tools_db.execute_sql(sql)

        arc_ids = self.rel_list_ids.get('arc')
        node_ids = self.rel_list_ids.get('node')
        connec_ids = self.rel_list_ids.get('connec')
        link_ids = self.rel_list_ids.get('link')
        workcat_ids = self._get_associated_workcat_ids()
        psector_ids = self._get_associated_psector_ids()
        visit_ids = self._get_associated_visit_ids()
        gully_ids = self.rel_list_ids.get('gully')
        element_ids = self.rel_list_ids.get('element')

        data = {
            'arc': arc_ids,
            'node': node_ids,
            'connec': connec_ids,
            'link': link_ids,
            'workcat': workcat_ids,
            'psector': psector_ids,
            'visit': visit_ids,
            'element': element_ids
        }
        if self.project_type == 'ud':
            data['gully'] = gully_ids
        parameters = {
            'project_type': self.project_type,
            'object_id': doc_id,
            'table_name': 'doc',
            'data': data
        }

        # Create request body with parameters
        extras = f'"parameters":{json.dumps(parameters)}'
        body = tools_gw.create_body(extras=extras)
        # Execute function
        json_result = tools_gw.execute_procedure('gw_fct_manage_relations', body, self.schema_name, log_sql=True)

        if json_result['status'] == 'Accepted':
            self.doc_id = doc_id
            self.doc_name = doc_name
            self.is_new = False
            self._activate_tabs(True)
            if close_dlg:
                tools_gw.manage_close(self.dlg_add_doc, table_object, None, self.single_tool_mode, self.rel_layers)
            else:
                msg = "Values saved successfully."
                tools_qgis.show_info(msg, dialog=self.dlg_add_doc)

        # Update the associated table
        if tablename:
            sql = (f"INSERT INTO doc_x_{tablename} (doc_id, {tablename}_id) "
                   f" VALUES({doc_id}, '{item_id}')")
            tools_db.execute_sql(sql)
            expr = f"{tablename}_id = '{item_id}'"
            if tablename == 'psector':
                expr = f"""psector_name = (SELECT name FROM "{lib_vars.schema_name}".plan_psector WHERE psector_id = '{item_id}')"""
            message = tools_qt.fill_table(qtable, f"{self.schema_name}.v_ui_doc_x_{tablename}", expr)
            if message:
                tools_qgis.show_warning(message)
            tools_gw.set_tablemodel_config(self.dlg_add_doc, qtable, f"v_ui_doc_x_{tablename}")

    def _get_associated_workcat_ids(self, doc_id=None):
        """Get workcat_ids linked to documento"""
        if doc_id is None:
            doc_id = self.doc_id
        if doc_id is None:
            return []
        sql = f"SELECT workcat_id FROM doc_x_workcat WHERE doc_id = {doc_id}"
        rows = tools_db.get_rows(sql)
        if not rows:
            return []
        return [row['workcat_id'] for row in rows if 'workcat_id' in row]

    def _get_associated_psector_ids(self, doc_id=None):
        """Get psector_ids linked to documento"""
        if doc_id is None:
            doc_id = self.doc_id
        if doc_id is None:
            return []
        sql = f"SELECT psector_id FROM doc_x_psector WHERE doc_id = {doc_id}"
        rows = tools_db.get_rows(sql)
        if not rows:
            return []
        return [row['psector_id'] for row in rows if 'psector_id' in row]

    def _get_associated_visit_ids(self, doc_id=None):
        """Get visit_ids linked to the document"""
        if doc_id is None:
            doc_id = self.doc_id
        if doc_id is None:
            return []
        sql = f"SELECT visit_id FROM doc_x_visit WHERE doc_id = {doc_id}"
        rows = tools_db.get_rows(sql)
        if not rows:
            return []
        return [row['visit_id'] for row in rows if 'visit_id' in row]

    def _check_doc_exists(self, name=""):
        sql = f"SELECT name FROM doc WHERE name = '{name}'"
        row = tools_db.get_row(sql, log_info=False)
        if row:
            self.dlg_add_doc.btn_accept.setEnabled(False)
            tools_qt.set_stylesheet(self.dlg_add_doc.doc_name)
            self.dlg_add_doc.doc_name.setToolTip("Document name already exists")
            return
        self.dlg_add_doc.btn_accept.setEnabled(True)
        tools_qt.set_stylesheet(self.dlg_add_doc.doc_name, style="")
        self.dlg_add_doc.doc_name.setToolTip("")

    def _open_selected_object_document(self, dialog, widget, table_object):

        # Check if there is a dlg_doc already open
        if hasattr(self, 'dlg_add_doc') and not isdeleted(self.dlg_add_doc) and self.dlg_add_doc.isVisible():
            return

        selected_list = widget.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dialog)
            return

        row = selected_list[0].row()

        # Get object_id from selected row
        field_object_id = "id"
        id_col_idx = tools_qt.get_col_index_by_col_name(widget, field_object_id)
        selected_object_id = widget.model().item(row, id_col_idx).text()

        # Close this dialog and open selected object
        keep_open_form = tools_gw.get_config_parser('dialogs_actions', 'doc_manager_keep_open', "user", "init",
                                                    prefix=True)
        if tools_os.set_boolean(keep_open_form, False) is not True:
            dialog.close()

        # Assuming 'row' is the QStandardItemModel row data
        self.get_document(row=widget.model().item(row, 0), item_id=selected_object_id)

    def _open_web_browser(self, dialog, widget=None):
        """ Display url using the default browser """

        if widget is not None:
            url = tools_qt.get_text(dialog, widget)
            if url == 'null':
                url = 'http://www.giswater.org'
        else:
            url = 'http://www.giswater.org'

        webbrowser.open(url)

    def _get_point_xy(self):
        """ Capture point XY from the canvas """
        self.snapper_manager.add_point(self.vertex_marker)
        self.point_xy = self.snapper_manager.point_xy

    def _get_file_dialog(self, dialog, widget):
        """ Get file dialog """
        files_path = tools_qt.get_open_files_path("Select files", "All (*.*)")

        file_text = ""
        if len(files_path) == 1:
            file_text += f"{files_path[0]}"
        else:
            for file in files_path:
                file_text += f"{file}\n\n"
        if files_path:
            tools_qt.set_widget_text(dialog, widget, str("\n\n".join(files_path)))
            self.files_path = files_path
            self.point_xy = {"x": None, "y": None}
            for file in files_path:
                if file.lower().endswith(('.tif', '.tiff', '.jpg', '.jpeg', '.png')):
                    gps_coordinates = self.get_geolocation_gdal(files_path[0])
                    if gps_coordinates:
                        self.point_xy = {"x": gps_coordinates[0], "y": gps_coordinates[1]}
                        break

        return files_path

    def _fill_dialog_document(self, dialog, table_object, single_tool_mode=None, doc_id=None):

        # Reset list of selected records
        self.rel_ids, self.rel_list_ids = tools_gw.reset_feature_list()

        list_feature_type = ['arc', 'node', 'connec', 'element', 'link']
        if global_vars.project_type == 'ud':
            list_feature_type.append('gully')

        object_name = tools_qt.get_text(dialog, table_object + "_name")
        filter_str = f"name = '{object_name}'"
        if object_name in (None, "", "null"):
            filter_str = f"id = {doc_id}"
        # Check if we already have data with selected object_id
        sql = (f"SELECT * "
               f" FROM {table_object}"
               f" WHERE {filter_str}")
        row = tools_db.get_row(sql, log_info=False)

        # Fill input widgets with data of the @row
        tools_qt.set_widget_text(dialog, "doc_name", row["name"])
        tools_qt.set_widget_text(dialog, "doc_type", row["doc_type"])
        tools_qt.set_calendar(dialog, "date", row["date"])
        tools_qt.set_widget_text(dialog, "observ", row["observ"])
        tools_qt.set_widget_text(dialog, "path", row["path"])

        self.doc_id = doc_id
        self.doc_name = row["name"]

        # Check related @feature_type
        for feature_type in list_feature_type:
            tools_gw.get_rows_by_feature_type(self, dialog, table_object, feature_type, feature_id=doc_id, feature_idname="doc_id")

    def convert_to_degrees(self, value):
        """ Convert GPS coordinates stored in EXIF to degrees """
        d = float(value[0])
        m = float(value[1])
        s = float(value[2])
        return d + (m / 60.0) + (s / 3600.0)

    def get_geolocation_gdal(self, file_path: str):
        """ Extract geolocation metadata from an image file using GDAL """

        dataset = gdal.Open(file_path)
        if not dataset:
            return None

        metadata = dataset.GetMetadata()
        if not metadata:
            return None

        lat = metadata.get("EXIF_GPSLatitude")
        lat_ref = metadata.get("EXIF_GPSLatitudeRef")
        lon = metadata.get("EXIF_GPSLongitude")
        lon_ref = metadata.get("EXIF_GPSLongitudeRef")
        epsg = lib_vars.data_epsg

        if lat and lon and lat_ref and lon_ref:
            lat_values = lat.strip("()").split()
            lon_values = lon.strip("()").split()
            lat_values = [v.strip("(),") for v in lat_values]
            lon_values = [v.strip("(),") for v in lon_values]

            lat = self.convert_to_degrees(lat_values)
            if lat_ref != "N":
                lat = -lat
            lon = self.convert_to_degrees(lon_values)
            if lon_ref != "E":
                lon = -lon

            try:
                pyproj = tools_os.get_dep("pyproj")
                CRS = pyproj.CRS
                Transformer = pyproj.Transformer
            except ImportError:
                tools_qgis.show_critical(
                    "Python package 'pyproj' is not installed. "
                    "Please install it using pip or the 'qpip' QGIS plugin."
                )
                return None

            # Perform coordinate transformation
            crs_in = CRS.from_epsg(4326)
            crs_out = CRS.from_epsg(epsg)
            transformer = Transformer.from_crs(crs_in, crs_out, always_xy=True)
            x, y = transformer.transform(lon, lat)

            return x, y

    # endregion
