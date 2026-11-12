"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

from qgis.PyQt.QtWidgets import QGridLayout, QLabel, QLineEdit, QTextEdit, QWidget

from .....libs import tools_qt, tools_qgis
from ....ui.ui_manager import GwFeatureEditRequestUi, GwFeatureEditRequestManagerUi
from ....utils import tools_gw


class GwFeatureEditRequestManager:

    def manage_review(self):
        """Open the review list. The dialog comes from config_form_fields via gw_fct_get_dialog."""

        body = tools_gw.create_body(form='"formName":"review_manager","formType":"form_review"')
        json_result = tools_gw.execute_procedure('gw_fct_get_dialog', body)
        if not json_result or json_result.get('status') != 'Accepted':
            msg = "Failed to fetch dialog configuration"
            tools_qgis.show_warning(msg)
            return

        self.complet_result = json_result
        self.dlg = GwFeatureEditRequestManagerUi(self)
        tools_gw.load_settings(self.dlg)
        tools_gw.manage_dlg_widgets(self, self.dlg, json_result)
        tools_gw.load_tableviews(self.dlg, json_result)
        # set_filter_listeners forces date filters to today. Reviews are not limited to today.
        self._clear_date_filters()
        tools_gw.open_dialog(self.dlg, dlg_name='feature_edit_request_manager')

    def _open_review(self, review_id):
        """Open one review: current value, proposed widget, annotation."""

        body = tools_gw.create_body(body={"data": {"action": "GET", "id": int(review_id)}})
        result = tools_gw.execute_procedure('gw_fct_manage_feature_edit_request', body)
        if not result or result.get('status') != 'Accepted':
            msg = "Failed to open the review"
            tools_qgis.show_warning(msg, parameter=_result_detail(result), dialog=self.dlg)
            return

        data = result.get('body', {}).get('data', {})
        review = data.get('review') or {}
        fields = data.get('fields') or []
        status = _review_status(review)

        self.review_id = int(review_id)
        self._proposed = []
        self.dlg_feature = GwFeatureEditRequestUi(self)
        tools_gw.load_settings(self.dlg_feature)
        self._fill_header(review)
        self._fill_fields(result, fields, status)

        if review.get('review_annotation'):
            self.dlg_feature.txt_review_annotation.setPlainText(str(review.get('review_annotation')))
        if status != 0:
            self.dlg_feature.btn_accept.setEnabled(False)
            self.dlg_feature.btn_reject.setEnabled(False)
            self.dlg_feature.txt_review_annotation.setReadOnly(True)

        self.dlg_feature.btn_accept.clicked.connect(lambda: self._apply('ACCEPT'))
        self.dlg_feature.btn_reject.clicked.connect(lambda: self._apply('REJECT'))
        self.dlg_feature.btn_close.clicked.connect(lambda: tools_gw.close_dialog(self.dlg_feature))
        tools_gw.open_dialog(self.dlg_feature, dlg_name='feature_edit_request')

    def _fill_header(self, review):
        parts = [str(review.get('table_name') or ''), str(review.get('table_id') or '')]
        if review.get('feature_type'):
            parts.append(str(review.get('feature_type')))
        text = " ".join(part for part in parts if part)
        if review.get('feature_code'):
            text = "{0} ({1})".format(text, review.get('feature_code'))
        self.dlg_feature.lbl_feature.setText(text)
        self.dlg_feature.lbl_field_user.setText(str(review.get('field_user') or ''))
        self.dlg_feature.lbl_field_date.setText(str(review.get('field_date') or ''))
        self.dlg_feature.lbl_field_annotation.setText(str(review.get('field_annotation') or ''))

    def _fill_fields(self, result, fields, status):
        layout = self.dlg_feature.findChild(QGridLayout, 'lyt_review_fields')
        if status == 1:
            title = "Proposed"
            header_left = QLabel(tools_qt.tr(title))
            title = "Applied"
            header_right = QLabel(tools_qt.tr(title))
        else:
            title = "Current"
            header_left = QLabel(tools_qt.tr(title))
            title = "Proposed"
            header_right = QLabel(tools_qt.tr(title))
        header_left.setStyleSheet("font-weight: bold;")
        header_right.setStyleSheet("font-weight: bold;")
        layout.addWidget(header_left, 0, 1)
        layout.addWidget(header_right, 0, 2)

        for row, field in enumerate(fields, start=1):
            if not field or not field.get('columnname'):
                continue
            if status == 1:
                left_field = _value_field(field, field.get('value'), 'proposed_')
                right_field = _value_field(field, field.get('appliedValue'), '')
            else:
                left_field = _value_field(field, field.get('currentValue'), 'current_')
                right_field = field
            label, right = tools_gw.set_widgets(self.dlg_feature, result, right_field, None, self)
            _, left = tools_gw.set_widgets(self.dlg_feature, result, left_field, None, self)
            _lock_widget(left)
            if status != 0:
                _lock_widget(right)
            if label is not None:
                layout.addWidget(label, row, 0)
            if left is not None:
                layout.addWidget(left, row, 1)
            if right is not None:
                layout.addWidget(right, row, 2)
                self._proposed.append(right)

        layout.addItem(tools_qt.add_verticalspacer(), layout.rowCount(), 0)

    def _apply(self, action):
        fields = {}
        if action == 'ACCEPT':
            for widget in self._proposed:
                got = tools_gw.get_values(self.dlg_feature, widget, fields)
                if got is not None:
                    fields = got
        annotation = self.dlg_feature.txt_review_annotation.toPlainText()
        body = tools_gw.create_body(body={
            "data": {
                "action": action,
                "id": self.review_id,
                "annotation": annotation,
                "fields": fields,
            }
        })
        result = tools_gw.execute_procedure('gw_fct_manage_feature_edit_request', body)
        if not result or result.get('status') != 'Accepted':
            msg = "Failed to save the review"
            tools_qgis.show_warning(msg, parameter=_result_detail(result), dialog=self.dlg_feature)
            return

        if action == 'ACCEPT':
            msg = "Review accepted"
        else:
            msg = "Review rejected"
        tools_qgis.show_info(msg)
        tools_gw.close_dialog(self.dlg_feature)
        self._reload_table()

    def _reload_table(self):
        status = self.dlg.findChild(QWidget, 'tab_none_status')
        if status is not None and hasattr(status, 'currentIndexChanged'):
            status.currentIndexChanged.emit(status.currentIndex())
            return
        tools_gw.load_tableviews(self.dlg, self.complet_result)

    def _clear_date_filters(self):
        for name in ('tab_none_date_from', 'tab_none_date_to'):
            widget = self.dlg.findChild(QWidget, name)
            if widget is not None and hasattr(widget, 'clear'):
                widget.clear()


def open_review(**kwargs):
    """Double click on the review list. Wired from the tablewidget widgetfunction."""

    qtable = kwargs.get('qtable')
    if qtable is None:
        return
    selected = qtable.selectionModel().selectedRows()
    if len(selected) == 0:
        msg = "Any record selected"
        tools_qgis.show_warning(msg)
        return
    func_params = kwargs.get('func_params') or {}
    columnname = func_params.get('columnfind') or 'id'
    col_idx = tools_qt.get_col_index_by_col_name(qtable, columnname)
    if col_idx is None:
        col_idx = 0
    review_id = qtable.model().index(selected[0].row(), col_idx).data()
    kwargs['class']._open_review(review_id)


def _review_status(review):
    try:
        return int(review.get('status'))
    except (TypeError, ValueError):
        return 0


def _value_field(field, value, prefix):
    """Copy of a form field showing @value. @prefix keeps the widget name off the editable column."""

    cloned = dict(field)
    if value is None:
        value = ''
    cloned['value'] = value
    cloned['selectedId'] = value
    if prefix:
        cloned['columnname'] = '{0}{1}'.format(prefix, field['columnname'])
        cloned['widgetname'] = '{0}{1}'.format(prefix, field['columnname'])
    return cloned


def _lock_widget(widget):
    if widget is None:
        return
    if isinstance(widget, (QLineEdit, QTextEdit)):
        tools_gw.set_widget_readonly(widget, True)
        return
    widget.setEnabled(False)


def _result_detail(result):
    if not isinstance(result, dict):
        return None
    detail = result.get('NOSQLERR') or result.get('message')
    if isinstance(detail, dict):
        detail = detail.get('text')
    return detail
