"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import os
import sys

from qgis.PyQt import QtCore
from qgis.PyQt.QtWidgets import QDialog, QShortcut, QWidget, QSizePolicy, QVBoxLayout
from qgis.PyQt.QtGui import QKeySequence, QIcon

from qgis.gui import QgsMessageBar
from qgis.utils import iface

from ... import global_vars
from ..utils import tools_gw
from ...libs import lib_vars


class GwDialog(QDialog):

    key_escape = QtCore.pyqtSignal()

    def __init__(self, class_obj, subtag=None, parent=None):

        # If parent is not null the dialog is integrated into parent
        if sys.platform == 'darwin':
            super().__init__()
        else:
            super().__init__(iface.mainWindow())
        self.setupUi(self)

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

        # Create message bar
        try:
            content_widget = QWidget()
            content_widget.setLayout(self.layout())

            outer_layout = QVBoxLayout(self)
            outer_layout.setContentsMargins(0, 0, 0, 0)
            outer_layout.setSpacing(0)

            self._messageBar = QgsMessageBar()
            self._messageBar.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
            self._messageBar.setMaximumHeight(35)

            outer_layout.addWidget(self._messageBar)
            outer_layout.addWidget(content_widget)
        except Exception as e:
            print("Exception in GwDialog:", e)
            self._messageBar = global_vars.iface.messageBar()

        # Connect the help shortcut
        action_help_shortcut = tools_gw.get_config_parser("actions_shortcuts", "shortcut_help", "user", "init", prefix=False)
        sh = QShortcut(QKeySequence(f"{action_help_shortcut}"), self)
        sh.activated.connect(tools_gw.open_dlg_help)
        # Set window icon
        icon_folder = f"{lib_vars.plugin_dir}{os.sep}icons"
        icon_path = f"{icon_folder}{os.sep}dialogs{os.sep}136.png"
        giswater_icon = QIcon(icon_path)
        self.setWindowIcon(giswater_icon)
        # Enable event filter
        self.installEventFilter(self)

    def eventFilter(self, object, event):
        if hasattr(self, "subtag") and self.subtag is not None:
            tag = f'{self.objectName()}_{self.subtag}'
        else:
            tag = str(self.objectName())

        if event.type() == QtCore.QEvent.Type.ActivationChange and self.isActiveWindow():
            lib_vars.session_vars['last_focus'] = tag
            return True
        return False

    def keyPressEvent(self, event):

        try:
            if event.key() == QtCore.Qt.Key.Key_Escape:
                self.key_escape.emit()
                return super().keyPressEvent(event)
        except RuntimeError:
            # Multiples signals are emited when we use key_scape in order to close dialog
            pass

    def messageBar(self):
        return self._messageBar
