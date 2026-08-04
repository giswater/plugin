"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from functools import partial

from qgis.PyQt.QtCore import pyqtSignal, QObject
from qgis.core import Qgis

from ..ui.ui_manager import GwPsectorDuplicateUi
from ..utils import tools_gw
from ...libs import tools_qt, tools_db, tools_qgis


class GwPsectorDuplicate(QObject):

    is_duplicated = pyqtSignal()

    def __init__(self):
        """ Class to control 'Workcat end' of toolbar 'edit' """

        super().__init__()

    def manage_duplicate_psector(self, psector_id=None):

        # Create the dialog and signals
        self.dlg_duplicate_psector = GwPsectorDuplicateUi(self)
        tools_gw.load_settings(self.dlg_duplicate_psector)

        # Populate combo duplicate psector
        sql = "SELECT psector_id, name FROM plan_psector"
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.dlg_duplicate_psector.duplicate_psector, rows)

        # Set QComboBox with selected psector
        tools_qt.set_combo_value(self.dlg_duplicate_psector.duplicate_psector, str(psector_id), 0)

        # Disable tab log
        tools_gw.disable_tab_log(self.dlg_duplicate_psector)

        # Set listeners
        self.dlg_duplicate_psector.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, self.dlg_duplicate_psector))
        self.dlg_duplicate_psector.btn_accept.clicked.connect(partial(self._duplicate_psector))

        # Open dialog
        tools_gw.open_dialog(self.dlg_duplicate_psector, dlg_name='psector_duplicate')

    # region private functions

    def _duplicate_psector(self):

        id_psector = tools_qt.get_combo_value(self.dlg_duplicate_psector, self.dlg_duplicate_psector.duplicate_psector, 0)
        new_psector_name = tools_qt.get_text(self.dlg_duplicate_psector, self.dlg_duplicate_psector.new_psector_name)

        sql = ("UPDATE config_param_user "
                "SET value = True "
                "WHERE parameter = 'plan_psector_disable_checktopology_trigger' AND cur_user=current_user")
        tools_db.execute_sql(sql)

        # Create body
        feature = '"type":"PSECTOR"'
        extras = f'"psector_id":"{id_psector}", "new_psector_name":"{new_psector_name}"'
        body = tools_gw.create_body(feature=feature, extras=extras)
        body = body.replace('""', 'null')
        complet_result = tools_gw.execute_procedure('gw_fct_psector_duplicate', body)

        sql = ("UPDATE config_param_user "
                "SET value = False "
                "WHERE parameter = 'plan_psector_disable_checktopology_trigger' AND cur_user=current_user")
        tools_db.execute_sql(sql)

        if not complet_result or complet_result['status'] == 'Failed':
            msg = 'Function gw_fct_psector_duplicate executed with no result'
            tools_qgis.show_message(msg, Qgis.MessageLevel.Success, dialog=self.dlg_duplicate_psector)
            return

        # Populate tab info
        change_tab = False
        data = complet_result['body']['data']
        for k, v in list(data.items()):
            if str(k) == "info":
                text, change_tab = tools_gw.fill_tab_log(self.dlg_duplicate_psector, data)

        # Close dialog
        if not change_tab:
            tools_gw.close_dialog(self.dlg_duplicate_psector)
        else:
            tools_qt.get_widget(self.dlg_duplicate_psector, self.dlg_duplicate_psector.btn_accept).setEnabled(False)
            self.dlg_duplicate_psector.setWindowTitle('SUCCESS IN DUPLICATING PSECTOR')

        self.is_duplicated.emit()

    # endregion