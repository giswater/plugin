"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial

from qgis.PyQt.QtCore import Qt
from qgis.PyQt.QtGui import QPixmap
from qgis.PyQt.QtWidgets import QLabel, QTableView

from ..ui.ui_manager import GwCmmsInfoUi
from ..utils import tools_gw
from ...libs import tools_db, tools_qt


def open_visit(qtable, feature_id):
    """ Open the read-only dialog of the visit selected in @qtable. """

    visit_id = _selected_value(qtable, 'visit_id')
    dlg, _ = _build_dialog('cmms_visit', 'v_ui_cmms_visit', 'visit_id, feature_id', f'{visit_id}, {feature_id}')
    if dlg is None:
        return

    filter_fields = (f'"visit_id":{{"value":"{visit_id}","filterSign":"="}}, '
                     f'"feature_id":{{"value":"{feature_id}","filterSign":"="}}')
    tools_gw.fill_tbl(dlg.complet_result, dlg, 'tbl_attachment', 'v_ui_cmms_attachment', filter_fields)
    tbl = dlg.findChild(QTableView, 'tab_none_tbl_attachment')
    if tbl is not None:
        tools_gw.set_tablemodel_config(dlg, tbl, 'v_ui_cmms_attachment')
        tools_qt.set_tableview_config(tbl)
        tbl.setMinimumHeight(160)
    tools_gw.open_dialog(dlg, dlg_name='cmms_info', title='Visit')


def open_attachment(qtable):
    """ Open the read-only dialog of the attachment selected in @qtable. """

    attachment_id = _selected_value(qtable, 'attachment_id')
    dlg, values = _build_dialog('cmms_attachment', 'v_ui_cmms_attachment', 'attachment_id', attachment_id)
    if dlg is None:
        return

    pixmap = QPixmap(values.get('thumbnail_path') or '')
    if pixmap.isNull():
        pixmap = QPixmap(values.get('path') or '')
    if not pixmap.isNull():
        lbl_preview = QLabel()
        lbl_preview.setAlignment(Qt.AlignmentFlag.AlignCenter)
        lbl_preview.setPixmap(pixmap.scaled(
            400, 400, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation))
        dlg.lyt_cmms_main.addWidget(lbl_preview, dlg.lyt_cmms_main.rowCount(), 0, 1, -1)
    tools_gw.open_dialog(dlg, dlg_name='cmms_info', title='Attachment')


def _build_dialog(form_type, table_name, idname, id_value):
    """ Build a dialog from config_form_fields, filled with the row of @table_name. """

    form = {"formName": "generic", "formType": form_type, "tableName": table_name, "idname": idname, "id": id_value}
    body = {"client": {"cur_user": tools_db.current_user}, "form": form}
    json_result = tools_gw.execute_procedure('gw_fct_get_dialog', body)
    if not json_result or json_result.get('status') != 'Accepted':
        return None, None

    dlg = GwCmmsInfoUi(None)
    dlg.complet_result = json_result
    tools_gw.load_settings(dlg)
    tools_gw.manage_dlg_widgets(None, dlg, json_result)
    dlg.btn_close.clicked.connect(partial(tools_gw.close_dialog, dlg))
    dlg.rejected.connect(partial(tools_gw.close_dialog, dlg))
    values = {field['columnname']: field.get('value') for field in json_result['body']['data']['fields']}
    return dlg, values


def _selected_value(qtable, column):
    """ Value of @column on the current row of @qtable. """

    index = qtable.currentIndex()
    column_index = tools_qt.get_col_index_by_col_name(qtable, column)
    return index.sibling(index.row(), column_index).data()
