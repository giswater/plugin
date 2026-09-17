"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

from qgis.PyQt import QtCore
from qgis.PyQt.QtWidgets import QDockWidget

from ...libs import lib_vars
from ..utils import tools_gw


class GwDocker(QDockWidget):
    dlg_closed = QtCore.pyqtSignal()

    def __init__(self, class_obj=None, subtag=None):

        super().__init__()

        # Check if CONTEXT and UINAME are defined and set properties accordingly
        context = getattr(self, 'CONTEXT', None)
        uiname = getattr(self, 'UINAME', None)

        if context and uiname:
            # Use provided CONTEXT and UINAME
            self.setProperty('context', context)
            self.setProperty('uiname', uiname)

        # Always set class_obj and subtag
        self.setProperty('class_obj', class_obj)
        self.subtag = subtag

        # TODO: Check try/catch. Strange error: "GwDocker object has no attribute 'setupUi"
        try:
            self.setupUi(self)
            tools_gw.upgrade_dialog_combos(self)
        except Exception:
            pass

    def closeEvent(self, event):

        self.dlg_closed.emit()
        return super().closeEvent(event)

    def event(self, event):

        if (event.type() == QtCore.QEvent.Type.WindowActivate or event.type() == QtCore.QEvent.Type.Show) \
                and self.isActiveWindow():
            if hasattr(self, "subtag") and self.subtag is not None:
                tag = f'{self.widget().objectName()}_{self.subtag}'
            else:
                tag = str(self.widget().objectName())
            lib_vars.session_vars['last_focus'] = tag
        return super().event(event)
