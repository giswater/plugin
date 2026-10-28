"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

from qgis.PyQt.QtWidgets import QGridLayout, QLabel, QLineEdit, QTextEdit, QWidget

from .....libs import tools_qt, tools_qgis
from ....ui.ui_manager import GwReviewFeatureUi, GwReviewManagerUi
from ....utils import tools_gw


class GwReviewManager:

    def manage_review(self):
        """Open the review list. The dialog comes from config_form_fields via gw_fct_get_dialog."""

        body = tools_gw.create_body(form='"formName":"review_manager","formType":"form_review"')
        json_result = tools_gw.execute_procedure('gw_fct_get_dialog', body)
        if not json_result or json_result.get('status') != 'Accepted':
            msg = "Failed to fetch dialog configuration"
            tools_qgis.show_warning(msg)
            return

        self.complet_result = json_result
        self.dlg = GwReviewManagerUi(self)
        tools_gw.load_settings(self.dlg)
        tools_gw.manage_dlg_widgets(self, self.dlg, json_result)
        tools_gw.load_tableviews(self.dlg, json_result)
        # set_filter_listeners forces date filters to today. Reviews are not limited to today.
        self._clear_date_filters()
        tools_gw.open_dialog(self.dlg, dlg_name='review_manager')

    def _open_review(self, review_id):
        """Open one review: current value, proposed widget, annotation."""

        body = tools_gw.create_body(body={"data": {"action": "GET", "id": int(review_id)}})
        result = tools_gw.execute_procedure('gw_fct_manage_review_feature', body)
        if not result or result.get('status') != 'Accepted':
            msg = "Failed to open the review"
            tools_qgis.show_warning(msg, parameter=_result_detail(result), dialog=self.dlg)
            return

        data = result.get('body', {}).get('data', {})
        review = data.get('review') or {}
        fields = data.get('fields') or []
        pending = review.get('status') in (0, '0', None)

        self.review_id = int(review_id)
        self._proposed = []
        self.dlg_feature = GwReviewFeatureUi(self)
        tools_gw.load_settings(self.dlg_feature)
        self._fill_header(review)
        self._fill_fields(result, fields, pending)

        if review.get('review_annotation'):
            self.dlg_feature.txt_review_annotation.setPlainText(str(review.get('review_annotation')))
        if not pending:
            self.dlg_feature.btn_accept.setEnabled(False)
            self.dlg_feature.btn_reject.setEnabled(False)
            self.dlg_feature.txt_review_annotation.setReadOnly(True)

        self.dlg_feature.btn_accept.clicked.connect(lambda: self._apply('ACCEPT'))
        self.dlg_feature.btn_reject.clicked.connect(lambda: self._apply('REJECT'))
        self.dlg_feature.btn_close.clicked.connect(lambda: tools_gw.close_dialog(self.dlg_feature))
        tools_gw.open_dialog(self.dlg_feature, dlg_name='review_feature')

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

    def _fill_fields(self, result, fields, pending):
        layout = self.dlg_feature.findChild(QGridLayout, 'lyt_review_fields')
        title = "Current"
        header_current = QLabel(tools_qt.tr(title))
        header_current.setStyleSheet("font-weight: bold;")
        title = "Proposed"
        header_proposed = QLabel(tools_qt.tr(title))
        header_proposed.setStyleSheet("font-weight: bold;")
        layout.addWidget(header_current, 0, 1)
        layout.addWidget(header_proposed, 0, 2)

        for row, field in enumerate(fields, start=1):
            if not field or not field.get('columnname'):
                continue
            label, proposed = tools_gw.set_widgets(self.dlg_feature, result, field, None, self)
            current_field = dict(field)
            current_value = field.get('currentValue')
            if current_value is None:
                current_value = ''
            current_field['value'] = current_value
            current_field['selectedId'] = current_value
            current_field['columnname'] = 'current_{0}'.format(field['columnname'])
            current_field['widgetname'] = 'current_{0}'.format(field['columnname'])
            _, current = tools_gw.set_widgets(self.dlg_feature, result, current_field, None, self)
            _lock_widget(current)
            if not pending:
                _lock_widget(proposed)
            if label is not None:
                layout.addWidget(label, row, 0)
            if current is not None:
                layout.addWidget(current, row, 1)
            if proposed is not None:
                layout.addWidget(proposed, row, 2)
                self._proposed.append(proposed)

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
        result = tools_gw.execute_procedure('gw_fct_manage_review_feature', body)
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
