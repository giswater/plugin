"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import os
import sys
import subprocess
import webbrowser

from functools import partial
from qgis.PyQt.QtCore import QDate, QRegularExpression, Qt
from qgis.PyQt.QtGui import QStandardItemModel
from qgis.PyQt.QtWidgets import QComboBox, QDateEdit, QLineEdit, QTableView, QWidget, QDoubleSpinBox, QSpinBox, QMenu
from qgis.core import QgsEditorWidgetSetup, QgsFieldConstraints, QgsLayerTreeLayer, QgsVectorLayer
from qgis.gui import QgsDateTimeEdit

from ... import global_vars
from ..shared.document import GwDocument
from ..shared.info import GwInfo
from ..shared.visit import GwVisit
from ..utils import tools_gw
from ...libs import lib_vars, tools_qgis, tools_qt, tools_log, tools_os, tools_db
from .selection_mode import GwSelectionMode


from ..shared.mincut_tools import filter_by_days, filter_by_dates


def add_object(**kwargs):
    """
    Open form of selected element of the @qtable??
        function called in module tools_gw: def add_button(module=sys.modules[__name__], **kwargs):
        at lines:   widget.clicked.connect(partial(getattr(module, function_name), **kwargs))
    """
    dialog = kwargs['dialog']
    button = kwargs['widget']
    index_tab = dialog.tab_main.currentIndex()
    tab_name = dialog.tab_main.widget(index_tab).objectName()
    func_params = kwargs['func_params']
    complet_result = kwargs['complet_result']
    feature_type = complet_result['body']['feature']['featureType']
    feature_id = complet_result['body']['feature']['id']
    field_id = str(complet_result['body']['feature']['idName'])
    qtable_name = func_params['targetwidget']
    qtable = tools_qt.get_widget(dialog, f"{qtable_name}")
    filter_sign = '='
    id_name = 'id'
    if button.property('widgetcontrols') is not None and 'filterSign' in button.property('widgetcontrols'):
        if button.property('widgetcontrols')['filterSign'] is not None:
            filter_sign = button.property('widgetcontrols')['filterSign']

    # Get values from dialog
    if 'sourcewidget' in func_params:
        object_id = tools_qt.get_text(dialog, f"{func_params['sourcewidget']}")
        if object_id == 'null':
            msg = "You need to insert data"
            tools_qgis.show_warning(msg, parameter=func_params['sourcewidget'])
            return
    # Special case for documents: get the document ID using the name
    if qtable_name == 'tbl_document' or 'doc' in tab_name:
        sql = f"SELECT id FROM doc WHERE name = '{object_id}'"
        row = tools_db.get_row(sql, log_sql=True)
        if not row:
            msg = "Document name not found"
            tools_qgis.show_warning(msg, parameter=object_id)
            return
        # Use the found document ID
        object_id = row['id']
    elif qtable_name == 'tbl_element' or 'element' in tab_name:
        id_name = 'element_id'

    # Check if this object exists
    if 'sourceview' in func_params:
        view_object = f"v_ui_{func_params['sourceview']}"
        tablename = func_params['sourceview'] + "_x_" + feature_type
    else:
        view_object = func_params['sourcetable']

    sql = ("SELECT * FROM " + view_object + ""
           f" WHERE {id_name} = '{object_id}'")
    row = tools_db.get_row(sql, log_sql=True)
    if not row:
        msg = "Object id not found"
        tools_qgis.show_warning(msg, parameter=object_id)
        return

    # Check if this object is already associated to current feature
    if qtable_name == 'tbl_document' or 'doc' in tab_name:
        field_object_id = 'doc_id'
    elif qtable_name == 'tbl_element' or 'element' in tab_name:
        field_object_id = 'element_id'
    else:
        field_object_id = dialog.findChild(QWidget, func_params['sourcewidget']).property('columnname')

    sql = ("SELECT * FROM " + str(tablename) + ""
           " WHERE " + str(field_id) + " = '" + str(feature_id) + "'"
           " AND " + str(field_object_id) + " = '" + str(object_id) + "'")
    row = tools_db.get_row(sql, log_info=False)
    # If object already exist show warning message
    if row:
        msg = "Object already associated with this feature"
        tools_qgis.show_warning(msg)
    # If object not exist perform an INSERT
    else:
        sql = ("INSERT INTO " + tablename + " "
               "(" + str(field_object_id) + ", " + str(field_id) + ")"
               " VALUES ('" + str(object_id) + "', '" + str(feature_id) + "');")
        tools_db.execute_sql(sql, log_sql=False)
        if qtable.objectName() == 'tbl_document':
            date_to = dialog.tab_main.findChild(QDateEdit, 'date_document_to')
            if date_to:
                current_date = QDate.currentDate()
                date_to.setDate(current_date)

        linkedobject = ""
        if qtable.property('linkedobject') is not None:
            linkedobject = qtable.property('linkedobject')

        filter_fields = f'"{field_id}":{{"value":"{feature_id}","filterSign":"{filter_sign}"}}'
        fill_tbl(complet_result, dialog, qtable.objectName(), linkedobject, filter_fields)


def delete_object(**kwargs):
    """ Delete selected objects (elements or documents) of the @widget
         function called in module tools_gw: def add_button(module=sys.modules[__name__], **kwargs):
        at lines:   widget.clicked.connect(partial(getattr(module, function_name), **kwargs))
    """
    dialog = kwargs['dialog']

    func_params = kwargs['func_params']
    complet_result = kwargs['complet_result']
    qtable_name = func_params['targetwidget']

    check_for_frelem = False

    if qtable_name == 'tab_features_tbl_element':
        feature_type = tools_gw.get_signal_change_tab(dialog)
        tablename = f"v_ui_{func_params['sourceview']}_x_{feature_type}"
        qtable_name = f"{qtable_name}_x_{feature_type}"
    elif 'featureType' in complet_result['body']['feature']:
        feature_type = complet_result['body']['feature']['featureType']
        tablename = f"v_ui_{func_params['sourceview']}_x_{feature_type}"
        check_for_frelem = True if qtable_name == 'tab_elements_tbl_elements' else False
    else:
        tablename = f"v_ui_{func_params['sourceview']}"
    qtable: QTableView = tools_qt.get_widget(dialog, f"{qtable_name}")

    # Get selected rows
    selected_list = qtable.selectionModel().selectedRows()
    if len(selected_list) == 0:
        msg = "Any record selected"
        tools_qgis.show_warning(msg)
        return

    inf_text = ""
    list_object_id = ""
    row_index = ""
    list_id = ""
    frelem_ids = []
    for i in range(0, len(selected_list)):
        index = selected_list[i]
        row = index.row()
        column_index = tools_qt.get_col_index_by_col_name(qtable, func_params['columnfind'])
        object_id = index.sibling(row, column_index).data()
        id_ = index.sibling(row, column_index).data()

        inf_text += str(object_id) + ", "
        list_id += f"'{str(id_)}', "
        # ist_id += str(id_) + ", "
        list_object_id = list_object_id + str(object_id) + ", "
        row_index += str(row + 1) + ", "

        if check_for_frelem:
            column_index = tools_qt.get_col_index_by_col_name(qtable, 'feature_class')
            feature_class = index.sibling(row, column_index).data()
            if feature_class == 'FRELEM':
                frelem_ids.append(object_id)

    list_object_id = list_object_id[:-2]
    list_id = list_id[:-2]
    message = "Are you sure you want to delete these records?"
    if frelem_ids:
        message += f"\nWARNING: Some of these records are FRELEM ({', '.join(frelem_ids)}). "
        message += "This will not only remove the relation, but delete them entirely."
    title = "Delete records"
    answer = tools_qt.show_question(message, title, list_object_id)
    if answer:
        sql = f"DELETE FROM {tablename} WHERE {func_params['columnfind']}::text IN ({list_id})"
        tools_db.execute_sql(sql, log_sql=False)
        if frelem_ids:
            frelem_ids_str = str(frelem_ids)[1:-1]
            sql = f"DELETE FROM v_ui_element WHERE element_id::text IN ({frelem_ids_str})"
            tools_db.execute_sql(sql, log_sql=False)
        _reload_table(**kwargs)


def open_visit_manager(**kwargs):
    complet_result = kwargs['complet_result']
    feature_type = complet_result['body']['feature']['featureType']
    feature_id = complet_result['body']['feature']['id']

    manage_visit = GwVisit()
    manage_visit.manage_visits(feature_type, feature_id)


def open_visit(**kwargs):
    dialog = kwargs['dialog']
    complet_result = kwargs['complet_result']
    func_params = kwargs['func_params']
    feature_type = complet_result['body']['feature']['featureType']
    feature_id = complet_result['body']['feature']['id']
    qtable = kwargs['qtable'] if 'qtable' in kwargs else tools_qt.get_widget(dialog, f"{func_params['targetwidget']}")
    if qtable is None or qtable.selectionModel() is None:
        return

    # Get selected rows
    selected_list = qtable.selectionModel().selectedRows()
    if len(selected_list) == 0:
        msg = "Any record selected"
        tools_qgis.show_warning(msg)
        return
    elif len(selected_list) > 1:
        msg = "Select just one visit"
        tools_qgis.show_warning(msg)
        return

    # Get document path (can be relative or absolute)
    index = selected_list[0]
    row = index.row()
    column_index = tools_qt.get_col_index_by_col_name(qtable, func_params['columnfind'])
    visit_id = index.sibling(row, column_index).data()

    manage_visit = GwVisit()
    manage_visit.get_visit(visit_id, feature_type, feature_id)


def manage_document(doc_id, **kwargs):
    """ Function called in class tools_gw.add_button(...) -->
        widget.clicked.connect(partial(getattr(self, function_name), **kwargs))
        Function called by: columnname ='btn_doc_new' """
    feature = None
    complet_result = kwargs['complet_result']
    feature_type = complet_result['body']['feature']['featureType']
    feature_id = complet_result['body']['feature']['id']
    field_id = str(complet_result['body']['feature']['idName'])
    table_parent = str(complet_result['body']['feature']['tableParent'])
    schema_name = str(complet_result['body']['feature']['schemaName'])

    # When click button 'new_element' element id is the signal emited by the button
    if doc_id is False:
        layer = tools_qgis.get_layer_by_tablename(table_parent, False, False, schema_name)
        if layer:
            expr_filter = f"{field_id} = '{feature_id}'"
            feature = tools_qgis.get_feature_by_expr(layer, expr_filter)

    doc = GwDocument()
    doc.get_document(feature=feature, feature_type=feature_type)
    # If document exist
    if doc_id:
        tools_qt.set_widget_text(doc.dlg_add_doc, "doc_id", doc_id)
        doc.dlg_add_doc.btn_accept.clicked.connect(partial(_reload_table, **kwargs))
    # If we are creating a new element
    else:
        doc.dlg_add_doc.btn_accept.clicked.connect(partial(_manage_document_new, doc, **kwargs))


def manage_visit_class(**kwargs):
    """ 
    """

    info = kwargs['class']
    complet_result = kwargs['complet_result']
    dialog = kwargs['dialog']
    columnname = kwargs['columnname']
    widget = kwargs['widget']
    feature_id = complet_result['body']['feature']['id']
    field_id = str(complet_result['body']['feature']['idName'])

    # Get visit class
    current_visit_class = tools_gw.get_values(dialog, widget)
    if current_visit_class[columnname] in (None, -1, '-1', ''):
        return
    # Get table name
    sql = (f"SELECT ui_tablename FROM config_visit_class where id = {current_visit_class[columnname]}")
    ui_tablename = tools_db.get_row(sql)
    if ui_tablename in (None, []):
        return
    table_view = dialog.tab_main.currentWidget().findChildren(QTableView)
    if table_view in (None, []):
        return
    table_view = table_view[0]
    # Manage parameters
    extras = f'"tableName":"{ui_tablename[0]}"'
    filter_fields = f'"{field_id}": {{"filterSign":"=", "value":"{feature_id}"}}'
    body = tools_gw.create_body(filter_fields=filter_fields, extras=extras)
    # Execute procedure
    json_result = tools_gw.execute_procedure('gw_fct_getlist', body)
    if json_result is None or json_result['status'] == 'Failed':
        widget.removeItem(widget.currentIndex())
        return False

    complet_list = json_result
    if not complet_list:
        widget.removeItem(widget.currentIndex())
        return False

    if complet_list is False:
        widget.removeItem(widget.currentIndex())
        return False, False

    headers = complet_list['body']['form'].get('headers')
    data = complet_list['body']['data']
    fields = data['fields']
    if data.get('hidden'):
        return

    visible_fields = [field for field in fields if not field.get('hidden')]
    model = table_view.model()
    if model is None:
        model = QStandardItemModel()
        table_view.setModel(model)
    if not visible_fields:
        model.removeRows(0, model.rowCount())
        return

    model.clear()
    table_view = tools_gw.add_tableview_header(table_view, visible_fields, headers)
    table_view = tools_gw.fill_tableview_rows(table_view, visible_fields)
    tools_qt.set_tableview_config(table_view)

    # Get tab's widgets
    widget_list = []
    tab_name = info.tab_main.currentWidget().objectName().replace('tab_', "")
    widget_list.extend(info.tab_main.currentWidget().findChildren(QComboBox, QRegularExpression(f"{tab_name}_")))
    widget_list.extend(info.tab_main.currentWidget().findChildren(QTableView, QRegularExpression(f"{tab_name}_")))
    widget_list.extend(info.tab_main.currentWidget().findChildren(QLineEdit, QRegularExpression(f"{tab_name}_")))
    widget_list.extend(info.tab_main.currentWidget().findChildren(QgsDateTimeEdit, QRegularExpression(f"{tab_name}_")))
    # Set filter listeners
    tools_gw.set_filter_listeners(complet_result, info.dlg_cf, widget_list, columnname, ui_tablename[0], info.feature_id)


def open_selected_path(**kwargs):
    """ Open selected path of the @widget
        function called in module tools_gw: def add_tableview(complet_result, field, module=sys.modules[__name__])
        at lines:   widget.doubleClicked.connect(partial(getattr(module, function_name), **kwargs))
    """
    func_params = kwargs['func_params']
    qtable = kwargs['qtable'] if 'qtable' in kwargs else tools_qt.get_widget(kwargs['dialog'], f"{func_params['targetwidget']}")
    path = None

    # Get selected rows
    selected_list = qtable.selectionModel().selectedRows()
    if len(selected_list) == 0:
        msg = "Any record selected"
        tools_qgis.show_warning(msg)
        return
    elif len(selected_list) > 1:
        msg = "Select just one document"
        tools_qgis.show_warning(msg)
        return

    # Get document path (can be relative or absolute)
    index = selected_list[0]
    row = index.row()
    column_index = tools_qt.get_col_index_by_col_name(qtable, func_params['columnfind'])
    # row==0 is falsy, column_index==4 is truthy, so the condition fails if row==0.
    if row is not None and column_index is not None:
        path = index.sibling(row, column_index).data()

    # Check if file exist
    if path is not None and os.path.exists(path):
        # Open the document
        if sys.platform == "win32":
            os.startfile(path)
        else:
            opener = "open" if sys.platform == "darwin" else "xdg-open"
            subprocess.call([opener, path])
    elif path is not None:
        webbrowser.open(path)
    else:
        msg = "File path not found"
        tools_qgis.show_warning(msg, dialog=kwargs['dialog'])


def filter_table(**kwargs):
    """
         Function called in module GwInfo: def _set_filter_listeners(self, complet_result, dialog, widget_list, columnname, widgetname)
         at lines:  widget.textChanged.connect(partial(getattr(tools_backend_calls, widgetfunction), **kwargs))
                    widget.currentIndexChanged.connect(partial(getattr(tools_backend_calls, widgetfunction), **kwargs))

         Might be called in tools_gw also: def set_filter_listeners(complet_result, dialog, widget_list, columnname, widgetname, feature_id=None)
         at lines:  widget.textChanged.connect(partial(getattr(module, function_name), **kwargs))
                    widget.currentIndexChanged.connect(partial(getattr(module, function_name), **kwargs))
                    widget.dateChanged.connect(partial(getattr(module, function_name), **kwargs))
                    widget.valueChanged.connect(partial(getattr(module, function_name), **kwargs))
     """

    complet_result = kwargs['complet_result']
    model = kwargs['model']
    dialog = kwargs['dialog']
    widget_list = kwargs['widget_list']
    widgetname = kwargs['widgetname']
    linkedobject = kwargs['linkedobject']
    feature_id = kwargs['feature_id']
    func_params = kwargs.get('func_params')

    if not linkedobject:
        linkedobject = widgetname

    field_id = func_params.get('field_id')
    if field_id is None and complet_result['body'].get('feature'):
        field_id = str(complet_result['body']['feature']['idName'])
    if feature_id is None and complet_result['body'].get('feature'):
        feature_id = complet_result['body']['feature']['id']
    filter_fields = f'"{field_id}":{{"value":"{feature_id}","filterSign":"="}}, '
    filter_fields = get_filter_qtableview(dialog, widget_list, complet_result, filter_fields)
    complet_list = _get_list(complet_result, filter_fields, linkedobject, feature_id, id_name=field_id)
    if complet_list is False:
        return False
    # for field in complet_list['body']['data']['fields']:
    qtable = dialog.findChild(QTableView, widgetname)
    if qtable is None:
        qtable = dialog.findChild(QTableView, func_params.get('targetwidget'))
    if qtable:
        data = complet_list['body']['data']
        headers = complet_list['body']['form'].get('headers')
        fields = data['fields']
        if data.get('hidden'):
            return False
        if not fields:
            model.removeRows(0, model.rowCount())
            return complet_list
        model.clear()
        tools_gw.add_tableview_header(qtable, fields, headers)
        tools_gw.fill_tableview_rows(qtable, fields)
        tools_gw.set_tablemodel_config(dialog, qtable, linkedobject, Qt.SortOrder.DescendingOrder)
        tools_qt.set_tableview_config(qtable)

    return complet_list


def filter_table_mincut(**kwargs):
    """
         Function called in module GwInfo: def _set_filter_listeners(self, complet_result, dialog, widget_list, columnname, widgetname)
         at lines:  widget.textChanged.connect(partial(getattr(tools_backend_calls, widgetfunction), **kwargs))
                    widget.currentIndexChanged.connect(partial(getattr(tools_backend_calls, widgetfunction), **kwargs))
     """

    complet_result = kwargs['complet_result']
    model = kwargs['model']
    dialog = kwargs['dialog']
    widget_list = kwargs['widget_list']
    widgetname = kwargs['widgetname']
    linkedobject = kwargs['linkedobject']
    feature_id = kwargs['feature_id']
    func_params = kwargs['func_params']

    filter_fields = get_filter_qtableview_mincut(dialog, widget_list, func_params)
    complet_list = _get_list(complet_result, filter_fields, linkedobject, feature_id)
    if complet_list is False:
        return False
    data = complet_list['body']['data']
    headers = complet_list['body']['form'].get('headers')
    fields = data['fields']
    if data.get('hidden'):
        return False
    qtable = dialog.findChild(QTableView, widgetname)
    if qtable:
        if not fields:
            model.removeRows(0, model.rowCount())
            return complet_list
        model.clear()
        tools_gw.add_tableview_header(qtable, fields, headers)
        tools_gw.fill_tableview_rows(qtable, fields)
        tools_gw.set_tablemodel_config(dialog, qtable, widgetname, Qt.SortOrder.DescendingOrder)
        tools_qt.set_tableview_config(qtable)

    return complet_list


def open_rpt_result(**kwargs):
    """
    Open form of selected element of the @qtable??
        function called in module tools_gw: def add_tableview(complet_result, field, module=sys.modules[__name__])
        at lines:   widget.doubleClicked.connect(partial(getattr(module, function_name), **kwargs))
    """

    qtable = kwargs['qtable']
    complet_list = kwargs['complet_result']
    func_params = kwargs['func_params']
    # Get selected rows
    selected_list = qtable.selectionModel().selectedRows()
    if len(selected_list) == 0:
        msg = "Any record selected"
        tools_qgis.show_warning(msg)
        return

    index = selected_list[0]
    row = index.row()
    table_name = complet_list['body']['feature']['tableName']
    column_index = tools_qt.get_col_index_by_col_name(qtable, func_params['columnfind'])
    feature_id = index.sibling(row, column_index).data()
    info_feature = GwInfo('tab_data')
    complet_result, dialog = info_feature.open_form(table_name=table_name, feature_id=feature_id, tab_type='tab_data')

    if not complet_result:
        msg = "FAIL {0}"
        msg_params = ("open_rpt_result",)
        tools_log.log_info(msg, msg_params=msg_params)
        return


def set_layer_index(**kwargs):
    """ Force reload dataProvider of layer """
    """ Function called in def wait_notifications(...) -->  getattr(self, function_name)(**params) """

    # Get list of layer names
    layers_name_list = kwargs['tableName']
    if not layers_name_list:
        return
    if type(layers_name_list) is str:
        tools_qgis.set_layer_index(layers_name_list)
    if type(layers_name_list) is list:
        for layer_name in layers_name_list:
            tools_qgis.set_layer_index(layer_name)


def get_info_node(**kwargs):
    """ Function called in class tools_gw.add_button(...) -->
            widget.clicked.connect(partial(getattr(self, function_name), **kwargs)) """

    dialog = kwargs['dialog']
    widget = kwargs['widget']

    feature_id = tools_qt.get_text(dialog, widget)
    if widget.property('value') not in (None, ''):
        feature_id = widget.property('value')
    custom_form = GwInfo('tab_data')
    complet_result, dialog = custom_form.open_form(table_name='ve_node', feature_id=feature_id,
                                                       tab_type='tab_data', is_docker=False)
    if not complet_result:
        msg = "FAIL {0}"
        msg_params = ("open_node",)
        tools_log.log_info(msg, msg_params=msg_params)
        return


def set_style_mapzones(**kwargs):
    """ A bridge function to call tools_gw->set_style_mapzones """
    """ Function called in def get_actions_from_json(...) --> getattr(tools_backend_calls, f"{function_name}")(**params) """

    tools_gw.set_style_mapzones()


def get_graph_config(**kwargs):
    """ A function to call gw_fct_getgraphconfig """
    """ Function called in def get_actions_from_json(...) --> getattr(tools_backend_calls, f"{function_name}")(**params) """

    json_result = kwargs.get('json_result')
    if not json_result or json_result.get('status') != "Accepted":
        msg = "Function {0} error: {1} from last function is invalid"
        msg_params = ("get_graph_config", "json_result")
        tools_log.log_warning(msg, msg_params=msg_params)
        return

    has_conflicts = json_result['body']['data'].get('hasConflicts')
    if has_conflicts is None or has_conflicts:
        return

    netscenario_id = json_result['body']['data'].get('netscenarioId')
    context = "NETSCENARIO" if netscenario_id is not None and netscenario_id != '-1' else "OPERATIVE"
    mapzone_type = json_result['body']['data'].get('graphClass')
    if not mapzone_type:
        msg = "Function {0} error: missing key {1}"
        msg_params = ("get_graph_config", "graphClass")
        tools_log.log_warning(msg, msg_params=msg_params)
        return
    extras = f'"context":"{context}", "mapzone": "{mapzone_type}"'
    body = tools_gw.create_body(extras=extras)
    json_result = tools_gw.execute_procedure('gw_fct_getgraphconfig', body)
    if json_result is None:
        msg = "Function {0} error: {1} returned null"
        msg_params = ("get_graph_config", "gw_fct_getgraphconfig")
        tools_log.log_warning(msg, msg_params=msg_params)
        return


def add_query_layer(**kwargs):
    """ Create and add a QueryLayer to ToC """
    """ Function called in def get_actions_from_json(...) --> getattr(tools_backend_calls, f"{function_name}")(**params) """

    query = kwargs.get('query')
    layer_name = kwargs.get('layerName', default='QueryLayer')
    group = kwargs.get('group', default='GW Layers')

    uri = tools_db.get_uri()

    querytext = f"(SELECT row_number() over () AS _uid_,* FROM ({query}) AS query_table)"
    pk = '_uid_'

    uri.setDataSource("", querytext, None, "", pk)
    vlayer = QgsVectorLayer(uri.uri(False), f'{layer_name}', "postgres")

    if vlayer.isValid():
        tools_qgis.add_layer_to_toc(vlayer, group, custom_properties={"gw_id": layer_name})


def refresh_attribute_table(**kwargs):
    """ Set layer fields configured according to client configuration.
        At the moment manage:
            Column names as alias, combos and typeahead as ValueMap"""
    """ Function called in def wait_notifications(...) -->  getattr(self, function_name)(**params) """

    # Get list of layer names
    layers_name_list = kwargs['tableName']
    if not layers_name_list:
        return

    for layer_name in layers_name_list:
        layer = tools_qgis.get_layer_by_tablename(layer_name)
        if not layer:
            msg = "Layer {0} does not found, therefore, not configured"
            msg_params = (layer_name,)
            tools_log.log_info(msg, msg_params=msg_params)
            continue

        # Get sys variale
        qgis_project_infotype = lib_vars.project_vars['info_type']

        feature = '"tableName":"' + str(layer_name) + '", "id":"", "isLayer":true'
        extras = f'"infoType":"{qgis_project_infotype}"'
        body = tools_gw.create_body(feature=feature, extras=extras)
        result = tools_gw.execute_procedure('gw_fct_getinfofromid', body)
        if not result:
            continue
        for field in result['body']['data']['fields']:
            _values = {}
            # Get column index
            field_idx = layer.fields().indexFromName(field['columnname'])

            # Hide selected fields according table config_form_fields.hidden
            if 'hidden' in field:
                kwargs = {"layer": layer, "field": field['columnname'], "hidden": field['hidden']}
                set_column_visibility(**kwargs)

            # Set multiline fields according table config_form_fields.widgetcontrols['setMultiline']
            if field['widgetcontrols'] is not None and field['widgetcontrols'].get('setMultiline'):
                kwargs = {"layer": layer, "field": field, "fieldIndex": field_idx}
                set_column_multiline(**kwargs)
            # Set alias column
            if field['label']:
                layer.setFieldAlias(field_idx, field['label'])

            # Set field constraints
            if field['widgetcontrols'] and 'setQgisConstraints' in field['widgetcontrols']:
                if field['widgetcontrols']['setQgisConstraints'] is True:
                    layer.setFieldConstraint(field_idx, QgsFieldConstraints.Constraint.ConstraintNotNull,
                                             QgsFieldConstraints.ConstraintStrength.ConstraintStrengthSoft)
                    layer.setFieldConstraint(field_idx, QgsFieldConstraints.Constraint.ConstraintUnique,
                                             QgsFieldConstraints.ConstraintStrength.ConstraintStrengthHard)

            # Manage editability
            kwargs = {"layer": layer, "field": field, "fieldIndex": field_idx}
            set_read_only(**kwargs)

            # Manage fields
            if field['widgettype'] == 'combo':
                if 'comboIds' in field:
                    for i in range(0, len(field['comboIds'])):
                        _values[field['comboNames'][i]] = field['comboIds'][i]
                # Set values into valueMap
                editor_widget_setup = QgsEditorWidgetSetup('ValueMap', {'map': _values})
                layer.setEditorWidgetSetup(field_idx, editor_widget_setup)
            elif field['widgettype'] == 'check':
                config = {'CheckedState': 'true', 'UncheckedState': 'false'}
                editor_widget_setup = QgsEditorWidgetSetup('CheckBox', config)
                layer.setEditorWidgetSetup(field_idx, editor_widget_setup)
            elif field['widgettype'] == 'datetime':
                config = {'allow_null': True,
                          'calendar_popup': True,
                          'display_format': 'yyyy-MM-dd',
                          'field_format': 'yyyy-MM-dd',
                          'field_iso_format': False}
                editor_widget_setup = QgsEditorWidgetSetup('DateTime', config)
                layer.setEditorWidgetSetup(field_idx, editor_widget_setup)


def refresh_canvas(**kwargs):
    """ Function called in def wait_notifications(...) -->  getattr(self, function_name)(**params) """

    # Note: canvas.refreshAllLayers() mysteriously that leaves the layers broken
    # self.canvas.refreshAllLayers()
    # Get list of layer names
    try:
        layers_name_list = kwargs['tableName']
        if not layers_name_list:
            return
        if type(layers_name_list) is str:
            layer = tools_qgis.get_layer_by_tablename(layers_name_list)
            layer.triggerRepaint()
        elif type(layers_name_list) is list:
            for layer_name in layers_name_list:
                tools_qgis.set_layer_index(layer_name)
    except Exception:
        all_layers = tools_qgis.get_project_layers()
        for layer in all_layers:
            layer.triggerRepaint()


def set_column_visibility(**kwargs):
    """ Hide selected fields according table config_form_fields.hidden """

    try:
        layer = kwargs["layer"]
        if type(layer) is str:
            layer = tools_qgis.get_layer_by_tablename(layer)
        col_name = kwargs["field"]
        hidden = kwargs["hidden"]
    except Exception as e:
        msg = "{0} --> {1} --> {2}"
        msg_params = (kwargs, type(e).__name__, e)
        tools_log.log_info(msg, msg_params=msg_params)
        return

    config = layer.attributeTableConfig()
    columns = config.columns()
    for column in columns:
        if column.name == str(col_name):
            column.hidden = hidden
            break
    config.setColumns(columns)
    layer.setAttributeTableConfig(config)


def set_column_multiline(**kwargs):
    """ Set multiline selected fields according table config_form_fields.widgetcontrols['setMultiline'] """

    try:
        field = kwargs["field"]
        layer = kwargs["layer"]
        if type(layer) is str:
            layer = tools_qgis.get_layer_by_tablename(layer)
        field_index = kwargs["fieldIndex"]
    except Exception as e:
        msg = "{0} --> {1}"
        msg_params = (type(e).__name__, e)
        tools_log.log_info(msg, msg_params=msg_params)
        return

    if field['widgettype'] == 'text':
        if field['widgetcontrols'] and field['widgetcontrols'].get('setMultiline'):
            editor_widget_setup = QgsEditorWidgetSetup(
                'TextEdit', {'IsMultiline': field['widgetcontrols']['setMultiline']})
            layer.setEditorWidgetSetup(field_index, editor_widget_setup)


def set_read_only(**kwargs):
    """ Set field readOnly according to client configuration into config_form_fields (field 'iseditable') """

    try:
        field = kwargs["field"]
        layer = kwargs["layer"]
        if type(layer) is str:
            layer = tools_qgis.get_layer_by_tablename(layer)
        field_index = kwargs["fieldIndex"]
    except Exception as e:
        msg = "{0} --> {1}"
        msg_params = (type(e).__name__, e)
        tools_log.log_info(msg, msg_params=msg_params)
        return
    # Get layer config
    config = layer.editFormConfig()
    try:
        # Set field editability
        config.setReadOnly(field_index, not field['iseditable'])
    except KeyError:
        # Control if key 'iseditable' not exist
        pass
    finally:
        # Set layer config
        layer.setEditFormConfig(config)


def load_qml(**kwargs):
    """ Apply QML style located in @qml_path in @layer
    :param kwargs:{"layerName": "ve_arc", "qmlPath": "C:\\xxxx\\xxxx\\xxxx\\qml_file.qml"}
    :return: Boolean value
    """

    # Get layer
    layer = tools_qgis.get_layer_by_tablename(kwargs['layerName']) if 'layerName' in kwargs else None
    if layer is None:
        return False

    # Get qml path
    qml_path = kwargs.get('qmlPath')

    if not os.path.exists(qml_path):
        msg = "File not found"
        tools_log.log_warning(msg, parameter=qml_path)
        return False

    if not qml_path.endswith(".qml"):
        msg = "File extension not valid"
        tools_log.log_warning(msg, parameter=qml_path)
        return False

    layer.loadNamedStyle(qml_path)
    layer.triggerRepaint()

    return True


def open_url(widget):
    """ Function called in def add_hyperlink(field): -->
        widget.clicked.connect(partial(getattr(tools_backend_calls, func_name), widget)) """

    status, message = tools_os.open_file(widget.text())
    if status is False and message is not None:
        tools_qgis.show_warning(message, parameter=widget.text())


def fill_tbl(complet_result, dialog, widgetname, linkedobject, filter_fields):
    """ Put filter widgets into layout and set headers into QTableView """
    no_tabs = False
    try:
        index_tab = dialog.tab_main.currentIndex()
        tab_name = dialog.tab_main.widget(index_tab).objectName()
    except Exception:
        tab_name = 'main'
        no_tabs = True
    complet_list = _get_list(complet_result, filter_fields, linkedobject)
    if complet_list is False:
        return False, False

    headers = complet_list['body']['form'].get('headers')

    data = complet_list['body']['data']
    fields = data['fields']
    if data.get('hidden'):
        return False, False
    widget = dialog.findChild(QTableView, widgetname)
    if widget is None:
        return False, False

    widget = tools_gw.add_tableview_header(widget, fields, headers)
    widget = tools_gw.fill_tableview_rows(widget, fields)
    widget = tools_gw.set_tablemodel_config(dialog, widget, linkedobject, Qt.SortOrder.DescendingOrder)
    tools_qt.set_tableview_config(widget)

    widget_list = []
    if no_tabs:
        widget_list.extend(dialog.findChildren(QComboBox, QRegularExpression(f"{tab_name}_")))
        widget_list.extend(dialog.findChildren(QTableView, QRegularExpression(f"{tab_name}_")))
        widget_list.extend(dialog.findChildren(QLineEdit, QRegularExpression(f"{tab_name}_")))
    else:
        widget_list.extend(dialog.tab_main.widget(index_tab).findChildren(QComboBox, QRegularExpression(f"{tab_name}_")))
        widget_list.extend(dialog.tab_main.widget(index_tab).findChildren(QTableView, QRegularExpression(f"{tab_name}_")))
        widget_list.extend(dialog.tab_main.widget(index_tab).findChildren(QLineEdit, QRegularExpression(f"{tab_name}_")))
    return complet_list, widget_list


def get_filter_qtableview(dialog, widget_list, complet_result, filter_fields=''):

    for widget in widget_list:
        if widget.property('isfilter'):
            columnname = widget.property('columnname')
            if widget.property('widgetfunction'):
                if widget.property('widgetfunction')['parameters'] \
                        and 'columnfind' in widget.property('widgetfunction')['parameters']:
                    columnname = widget.property('widgetfunction')['parameters']['columnfind']
            filter_sign = "ILIKE"
            column_id = 0
            if widget.property('widgetcontrols') is not None and 'filterSign' in widget.property('widgetcontrols'):
                if widget.property('widgetcontrols')['filterSign'] is not None:
                    filter_sign = widget.property('widgetcontrols')['filterSign']
            if widget.property('widgetcontrols') is not None and 'columnId' in widget.property('widgetcontrols'):
                if widget.property('widgetcontrols')['columnId'] is not None:
                    column_id = widget.property('widgetcontrols')['columnId']
            if isinstance(widget, QComboBox):
                value = tools_qt.get_combo_value(dialog, widget, column_id)
                if value == -1:
                    value = None
            elif isinstance(widget, QgsDateTimeEdit):
                value = tools_qt.get_calendar_date(dialog, widget, date_format='yyyy-MM-dd')
            else:
                value = tools_qt.get_text(dialog, widget, False, False)

            if not value:
                continue

            filter_fields += f'"{columnname}":{{"value":"{value}","filterSign":"{filter_sign}"}}, '

    if filter_fields != "":
        filter_fields = filter_fields[:-2]

    return filter_fields


def get_filter_qtableview_mincut(dialog, widget_list, func_params, filter_fields=''):

    for widget in widget_list:
        if widget.property('isfilter'):
            functions = None
            if widget.property('widgetfunction') is not None:
                widgetfunction = widget.property('widgetfunction')
                if isinstance(widgetfunction, list):
                    functions = widgetfunction
                else:
                    functions = [widgetfunction]

                for f in functions:
                    if 'isFilter' in f and f['isFilter']:
                        continue
                    columnname = widget.property('columnname')
                    parameters = f['parameters']
                    filter_sign = "ILIKE"
                    column_id = 0

                    if 'columnfind' in parameters:
                        columnname = parameters['columnfind']

                    if widget.property('widgetcontrols') is not None and 'filterSign' in widget.property('widgetcontrols'):
                        if widget.property('widgetcontrols')['filterSign'] is not None:
                            filter_sign = widget.property('widgetcontrols')['filterSign']
                    if widget.property('widgetcontrols') is not None and 'columnId' in widget.property('widgetcontrols'):
                        if widget.property('widgetcontrols')['columnId'] is not None:
                            column_id = widget.property('widgetcontrols')['columnId']
                    if isinstance(widget, QComboBox):
                        value = tools_qt.get_combo_value(dialog, widget, column_id)
                        if value == -1:
                            value = None
                    elif isinstance(widget, QgsDateTimeEdit):
                        value = tools_qt.get_calendar_date(dialog, widget, date_format='yyyy-MM-dd')
                    else:
                        value = tools_qt.get_text(dialog, widget, False, False)

                    if value in (None, ''):
                        continue

                    if isinstance(widget, (QDoubleSpinBox, QSpinBox, QgsDateTimeEdit)):
                        if not widget.isEnabled():
                            continue

                    if widget.objectName() == "tab_none_spm_next_days":
                        filter_fields += filter_by_days(dialog, widget)
                    elif isinstance(widget, QgsDateTimeEdit):
                        filter_fields += filter_by_dates(dialog, widget)
                    else:
                        filter_fields += f'"{columnname}":{{"value":"{value}","filterSign":"{filter_sign}"}}, '

    if filter_fields != "":
        filter_fields = filter_fields[:-2]

    return filter_fields


def open_selected_manager_item(**kwargs):
    """
    Open form of selected element of the @qtable??
        function called in module tools_gw: def add_tableview(complet_result, field, module=sys.modules[__name__])
        at lines:   widget.doubleClicked.connect(partial(getattr(module, function_name), **kwargs))
    """
    func_params = kwargs['func_params']
    qtable = kwargs['qtable'] if 'qtable' in kwargs else tools_qt.get_widget(kwargs['dialog'], f"{func_params['targetwidget']}")
    dialog = kwargs['dialog']
    feature_class = kwargs['class']
    table = func_params.get('sourcetable')
    complet_result = kwargs.get('complet_result')
    columnname = func_params.get('columnfind')
    connect = None
    linked_feature = None
    elem_manager = func_params.get('elem_manager')

    # Get selected rows
    selected_list = qtable.selectionModel().selectedRows()
    if len(selected_list) == 0:
        msg = "Any record selected"
        tools_qgis.show_warning(msg)
        return

    index = selected_list[0]
    row = index.row()
    column_index = tools_qt.get_col_index_by_col_name(qtable, func_params['columnfind'])
    if not elem_manager:
        linked_feature = {"table_name": table, "new_id": "", "dialog": dialog, "self": feature_class,
                        "complet_result": complet_result, "columnname": columnname}
    if table == 'v_ui_element':
        connect = [partial(reload_table_manager, **kwargs)]
    elif table == 'v_ui_element_x_arc':
        connect = [partial(add_object, **kwargs), partial(_reload_table, **kwargs)]

    if qtable.property('linkedobject') in ('v_ui_element', 'tbl_element_x_arc', 'tbl_element_x_node', 'tbl_element_x_connec', 'tbl_element_x_link', 'tbl_element_x_gully'):
        # Open selected element
        element_id = index.sibling(row, column_index).data()
        sql = f"SELECT concat('ve_', lower(feature_type), '_', lower(element_type)) from v_ui_element where element_id = '{element_id}' "
        table_name = tools_db.get_row(sql)
        info_feature = GwInfo('tab_data')
        complet_result, dialog = info_feature.open_form(table_name=table_name[0], feature_id=element_id, tab_type='data',
                                                        connect_signal=connect, linked_feature=linked_feature)
        if not complet_result:
            tools_log.log_info("FAIL open_selected_manager_item")
            return


def manage_element_menu(**kwargs):
    """ Function called in class tools_gw.add_button(...) -->
            widget.clicked.connect(partial(getattr(self, function_name), **kwargs)) """

    # Get widget from kwargs
    button = kwargs['widget']
    func_params = kwargs['func_params']
    table = func_params['sourcetable']
    connect = None
    if table == 'v_ui_element':
        connect = [partial(reload_table_manager, **kwargs)]
    elif table == 'v_ui_element_x_arc':
        connect = [partial(add_object, **kwargs), partial(_reload_table, **kwargs)]

    # Generate linked_feature
    linked_feature_geom = None
    linked_feature_no_geom = None
    is_linked = func_params['linked_feature']
    if is_linked:
        feature_class = kwargs['class']
        dialog = kwargs['dialog']
        complet_result = kwargs.get('complet_result')
        geometry = complet_result.get('body').get('feature').get('geometry')
        linked_feature_geom = {"table_name": table, "new_id": "", "dialog": dialog, "geometry": geometry,
                            "self": feature_class, "complet_result": complet_result,
                            "columnname": "element_id"}
        linked_feature_no_geom = {"table_name": table, "new_id": "", "dialog": dialog, "geometry": None,
                                "self": feature_class, "complet_result": complet_result,
                                "columnname": "element_id"}
    # Create menu for button
    btn_menu = QMenu()
    # Create info feature object for tab_data
    info_feature = GwInfo('tab_data')
    # Get list of different element types
    features_cat = tools_gw.manage_feature_cat()
    if features_cat is not None:
        # Get list of feature categories
        list_feature_cat = tools_os.get_values_from_dictionary(features_cat)
        # Add FRELEM type features first
        for feature_cat in list_feature_cat:
            if feature_cat.feature_class.upper() == 'FRELEM' and ('node' in table.lower() or not is_linked):
                action_frelem = btn_menu.addAction(feature_cat.id)
                action_frelem.triggered.connect(partial(info_feature.add_feature, feature_cat, connect_signal=connect,
                                                        linked_feature=linked_feature_geom))
        # Add separator between feature types
        btn_menu.addSeparator()
        # Get list again for GENELEM features
        list_feature_cat = tools_os.get_values_from_dictionary(features_cat)
        # Add GENELEM type features
        for feature_cat in list_feature_cat:
            if feature_cat.feature_class.upper() == 'GENELEM':
                action_genelem = btn_menu.addAction(feature_cat.id)
                action_genelem.triggered.connect(partial(info_feature.add_feature, feature_cat, connect_signal=connect,
                                                         linked_feature=linked_feature_no_geom))
    # Set and show menu on button
    button.setMenu(btn_menu)
    button.showMenu()


def delete_manager_item(**kwargs):
    """ Function called in class tools_gw.add_button(...) -->
            widget.clicked.connect(partial(getattr(self, function_name), **kwargs)) """

    dialog = kwargs['dialog']
    params = kwargs['func_params']
    table_widget = params['targetwidget']
    table = params['sourcetable']
    field_object_id = params.get('field_object_id', None)

    # Get QTableView, delete selected rows and reload the table
    table_widget = tools_qt.get_widget(dialog, f"{table_widget}")
    tools_gw.delete_selected_rows(table_widget, table, field_object_id)
    reload_table_manager(**kwargs)


def reload_table_manager(**kwargs):
    """ Reload table data """
    complet_result = kwargs['complet_result']
    dialog = kwargs['dialog']
    list_tables = dialog.findChildren(QTableView)
    tab_name = 'tab_none'
    filter_fields = ''

    widget_list = []
    widget_list.extend(dialog.findChildren(QComboBox, QRegularExpression(f"{tab_name}_")))
    widget_list.extend(dialog.findChildren(QTableView, QRegularExpression(f"{tab_name}_")))
    widget_list.extend(dialog.findChildren(QLineEdit, QRegularExpression(f"{tab_name}_")))

    for table in list_tables:
        widgetname = table.objectName()
        columnname = table.property('columnname')
        if columnname is None:
            msg = "widget {0} has not columnname and can't be configured"
            msg_params = (widgetname,)
            tools_qgis.show_info(msg, 1, msg_params=msg_params)
            continue

        linkedobject = table.property('linkedobject')
        filter_fields = get_filter_qtableview(dialog, widget_list, complet_result)
        # if func_params.get('columnfind') and tools_qt.get_text(dialog, widget, False, False) and widget.property('widgetcontrols')['filterSign']:
        #     filter_fields = f'"{func_params.get('columnfind')}":{{"value":"{tools_qt.get_text(dialog, widget, False, False)}","filterSign":"{widget.property('widgetcontrols')['filterSign']}"}}'
        complet_list, widget_list = fill_tbl(complet_result, dialog, widgetname, linkedobject, filter_fields)
        if complet_list is False:
            return False


def close_manager(**kwargs):
    """ Function called in class tools_gw.add_button(...) -->
            widget.clicked.connect(partial(getattr(self, function_name), **kwargs)) """
    dialog = kwargs['dialog']
    tools_gw.close_dialog(dialog)

# region private functions


def _get_list(complet_result, filter_fields='', linkedobject='', feature_id='', id_name=''):

    # Manage id_name
    if id_name is None:
        try:
            id_name = complet_result['body']['feature']['idName']
        except KeyError:
            id_name = None
    # Parameters
    extras = f'"tableName":"{linkedobject}"'
    if id_name and feature_id:
        if filter_fields:
            filter_fields = f'"{id_name}":{{"value":"{feature_id}","filterSign":"="}}, {filter_fields}'
        else:
            filter_fields = f'"{id_name}":{{"value":"{feature_id}","filterSign":"="}}'
    # Create body
    body = tools_gw.create_body(filter_fields=filter_fields, extras=extras)
    # Execute procedure
    json_result = tools_gw.execute_procedure('gw_fct_getlist', body, log_sql=True)
    if json_result is None or json_result['status'] == 'Failed':
        return False
    complet_list = json_result
    if not complet_list:
        return False

    return complet_list


def _manage_document_new(doc, **kwargs):
    """ Get inserted doc_id and add it to current feature """

    if doc.doc_name is None:
        return
    dialog = kwargs['dialog']
    func_params = kwargs['func_params']

    tools_qt.set_widget_text(dialog, f"{func_params['sourcewidget']}", doc.doc_name)
    add_object(**kwargs)


def _reload_table(**kwargs):
    """ Get inserted element_id and add it to current feature """
    dialog = kwargs['dialog']
    no_tabs = False
    try:
        index_tab = dialog.tab_main.currentIndex()
        tab_name = dialog.tab_main.widget(index_tab).objectName()
        list_tables = dialog.tab_main.widget(index_tab).findChildren(QTableView)
    except Exception:
        no_tabs = True
        tab_name = 'main'
        list_tables = dialog.findChildren(QTableView)

    complet_result = kwargs['complet_result']
    feature_id = complet_result['body']['feature']['id']
    field_id = str(complet_result['body']['feature']['idName'])
    widget_list = []
    if no_tabs:
        widget_list.extend(dialog.findChildren(QComboBox, QRegularExpression(f"{tab_name}_")))
        widget_list.extend(dialog.findChildren(QTableView, QRegularExpression(f"{tab_name}_")))
        widget_list.extend(dialog.findChildren(QLineEdit, QRegularExpression(f"{tab_name}_")))
    else:
        widget_list.extend(dialog.tab_main.widget(index_tab).findChildren(QComboBox, QRegularExpression(f"{tab_name}_")))
        widget_list.extend(dialog.tab_main.widget(index_tab).findChildren(QTableView, QRegularExpression(f"{tab_name}_")))
        widget_list.extend(dialog.tab_main.widget(index_tab).findChildren(QLineEdit, QRegularExpression(f"{tab_name}_")))

    for table in list_tables:
        widgetname = table.objectName()
        columnname = table.property('columnname')
        if columnname is None:
            if no_tabs:
                msg = "widget {0} has not columnname and cant be configured"
                msg_params = (widgetname,)
            else:
                msg = "widget {0} in tab {1} has not columnname and cant be configured"
                msg_params = (widgetname, dialog.tab_main.widget(index_tab).objectName(),)
            tools_qgis.show_info(msg, 1, msg_params=msg_params)
            continue

        # Get value from filter widgets
        filter_fields = get_filter_qtableview(dialog, widget_list, kwargs['complet_result'])

        # if tab dont have any filter widget
        if filter_fields in ('', None):
            filter_fields = f'"{field_id}":{{"value":"{feature_id}","filterSign":"="}}'

        if no_tabs:
            filter_fields = ''
            widgetname = columnname
        linkedobject = table.property('linkedobject')
        complet_list, widget_list = fill_tbl(complet_result, dialog, widgetname, linkedobject, filter_fields)
        if complet_list is False:
            return False

# endregion


def get_selector(**kwargs):
    """
    Refreshes the selectors if the selector dialog is open

    Function connected -> global_vars.signal_manager.refresh_selectors.connect(tools_gw.refresh_selectors)
    """

    tab_name = kwargs.get('tab')
    global_vars.signal_manager.refresh_selectors.emit(tab_name)


def show_message(**kwargs):
    """
    Shows a message in the message bar.

    Function connected -> global_vars.signal_manager.show_message.connect(tools_qgis.show_message)
    """

    text = kwargs.get('text', default='No message found')
    level = kwargs.get('level', default=1)
    duration = kwargs.get('duration', default=10)

    global_vars.signal_manager.show_message.emit(text, level, duration)


def manage_duplicate_dscenario_copyfrom(dialog):
    """ Function called in def build_dialog_options(...) -->  getattr(module, signal)(dialog) """

    dscenario_id = tools_qt.get_combo_value(dialog, 'copyFrom')
    sql = f"SELECT descript, parent_id, dscenario_type, active, expl_id FROM ve_cat_dscenario WHERE dscenario_id = {dscenario_id}"
    row = tools_db.get_row(sql)

    if row:
        tools_qt.set_widget_text(dialog, 'name', "")
        tools_qt.set_widget_text(dialog, 'descript', row[0])
        tools_qt.set_widget_text(dialog, 'parent', row[1])
        tools_qt.set_widget_text(dialog, 'type', row[2])
        tools_qt.set_widget_text(dialog, 'active', row[3])
        tools_qt.set_combo_value(dialog.findChild(QComboBox, 'expl'), f"{row[4]}", 0)


def selection_init(**kwargs):
    """
    Initialize the selection.
    """
    tools_gw.selection_init(kwargs.get('class'), kwargs.get('dialog'), kwargs.get('class').feature_type, GwSelectionMode.ELEMENT)


def insert_feature(**kwargs):
    """
    Insert the selected records.
    """
    func_params = kwargs.get('func_params')
    target_widget = func_params.get('targetwidget')

    tools_gw.insert_feature(kwargs.get('class'), kwargs.get('dialog'), None, GwSelectionMode.ELEMENT, target_widget=target_widget)


# region unused functions atm

def get_all_layers(group, all_layers):

    for child in group.children():
        if isinstance(child, QgsLayerTreeLayer):
            all_layers.append(child.layer().name())
            child.layer().name()
        else:
            get_all_layers(child)

# endregion
