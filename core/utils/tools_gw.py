"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import configparser
import inspect
import io
import json
import os
import random
import re
import shutil
import sys
import sqlite3
import webbrowser
import xml.etree.ElementTree as ET

from typing import Literal, Dict, Optional, Union, Any, List, Tuple
from qgis.PyQt.sip import isdeleted
from osgeo import gdal

from collections import OrderedDict
from functools import partial
from datetime import datetime

from qgis.PyQt.QtCore import Qt, QStringListModel, QVariant, QDate, QSettings, QLocale, QRegularExpression, \
    QItemSelectionModel, QTimer
from qgis.PyQt.QtGui import QCursor, QPixmap, QColor, QStandardItemModel, QIcon, QStandardItem, \
    QIntValidator, QDoubleValidator, QRegularExpressionValidator, QPalette
from qgis.PyQt.QtSql import QSqlTableModel
from qgis.PyQt.QtWidgets import QSpacerItem, QSizePolicy, QLineEdit, QLabel, QComboBox, QGridLayout, QTabWidget, \
    QCompleter, QPushButton, QTableView, QFrame, QCheckBox, QDoubleSpinBox, QSpinBox, QDateEdit, QTextEdit, \
    QToolButton, QWidget, QApplication, QMenu, QAction, QDialog, QListWidget, QListWidgetItem, QAbstractScrollArea, \
    QVBoxLayout, QHeaderView
from qgis.core import Qgis, QgsProject, QgsPointXY, QgsVectorLayer, QgsField, QgsFeature, QgsSymbol, \
    QgsFeatureRequest, QgsSimpleFillSymbolLayer, QgsRendererCategory, QgsCategorizedSymbolRenderer, \
    QgsCoordinateTransform, QgsCoordinateReferenceSystem, QgsVectorFileWriter, QgsCoordinateTransformContext, \
    QgsFieldConstraints, QgsEditorWidgetSetup, QgsRasterLayer, QgsGeometry, QgsExpression, QgsRectangle, \
    QgsEditFormConfig, QgsSymbolLayer, QgsProperty, QgsSimpleLineSymbolLayer, QgsSimpleMarkerSymbolLayer, QgsStyle, \
    QgsDataSourceUri
from qgis.gui import QgsDateTimeEdit, QgsRubberBand, QgsExpressionSelectionDialog

from ..models.cat_feature import GwCatFeature
from ..ui.dialog import GwDialog
from ..ui.main_window import GwMainWindow
from ..ui.docker import GwDocker
from ..ui.ui_manager import GwSelectorUi, GwPsectorManagerUi
from . import tools_backend_calls
from ..load_project_menu import GwMenuLoad
from ..utils.select_manager import GwSelectManager
from ... import global_vars
from ...libs import lib_vars, tools_qgis, tools_qt, tools_log, tools_os, tools_db
from ...libs.tools_qt import GwHyperLinkLabel, GwHyperLinkLineEdit
from .selection_mode import GwSelectionMode
from .select_manager import GwSelectionType

# These imports are for the add_{widget} functions (modules need to be imported in order to find it by its name)
# noinspection PyUnresolvedReferences
from ..shared import info, mincut_tools  # noqa: F401
from ..shared.selector import GwSelector  # noqa: F401
from ..toolbars.edit import featuretype_change_btn  # noqa: F401
from ..toolbars.epa import go2epa_selector_btn  # noqa: F401
from ..shared import psector  # noqa: F401
from ..shared import audit  # noqa: F401
from ..toolbars.utilities import snapshot_view  # noqa: F401
from ..shared import profile as profile_interpolation, scada_graph  # noqa: F401
from ..toolbars.edit import connect_link_btn  # noqa: F401
from ..toolbars.cm import lot, campaign  # noqa: F401
from ..toolbars.toc.layerstyle_change_btn import apply_styles_to_layers

QgsGeometryType = Literal['line', 'point', 'polygon']

geom_types_dict: Dict = {
    "line": Qgis.GeometryType.Line,
    "point": Qgis.GeometryType.Point,
    "polygon": Qgis.GeometryType.Polygon
}


class ThemeManager:
    """Theme-aware colors and reusable stylesheet helpers."""

    @classmethod
    def _get_palette(cls, widget=None):
        app = QApplication.instance()
        if app is None:
            return None
        return widget.palette() if widget is not None else app.palette()

    @classmethod
    def is_dark_mode(cls, widget=None):
        palette = cls._get_palette(widget)
        if palette is None:
            return False
        window_color = palette.color(QPalette.ColorRole.Window)
        text_color = palette.color(QPalette.ColorRole.WindowText)
        return window_color.lightness() < text_color.lightness()

    @classmethod
    def color(cls, role, widget=None, fallback="#ffffff"):
        palette = cls._get_palette(widget)
        if palette is None:
            return fallback
        return palette.color(role).name()

    @classmethod
    def alternate_base_color(cls, widget=None):
        palette = cls._get_palette(widget)
        if palette is None:
            return "#2c2a2a" if cls.is_dark_mode(widget) else "#e9e7e3"

        base_color = palette.color(QPalette.ColorRole.Base)
        alt_color = base_color.lighter(150) if cls.is_dark_mode(widget) else base_color.darker(104)

        return alt_color.name()

    @classmethod
    def selector_colors(cls, widget=None):
        is_dark = cls.is_dark_mode(widget)
        fallback_color = "#ffffff" if is_dark else "#000000"
        base = cls.color(QPalette.ColorRole.Base, widget=widget, fallback=fallback_color)
        alt = cls.alternate_base_color(widget=widget)
        if cls.is_dark_mode(widget):
            return alt, base
        return base, alt


def _get_geom_type(geometry_type: QgsGeometryType = None):

    default_geom_type = Qgis.GeometryType.Line

    geom_type = geom_types_dict.get(geometry_type, default_geom_type)
    return geom_type


def normalize_label(label: str, add_colon: bool = False) -> str:
    """
    Normalize label: underscores to spaces, trim, capitalize first char, handle colon.
    """
    if not isinstance(label, str):
        return ""
    normalized = label.replace('_', ' ').strip()
    if normalized:
        normalized = normalized[:1].upper() + normalized[1:]
    if add_colon:
        normalized = normalized.rstrip(':') + ':'
    else:
        normalized = normalized.rstrip(':').rstrip()
    return normalized


def parse_context_levels(context_value: Any) -> List[str]:
    """
    Parse a layer context and return ordered menu levels.
    """

    if not context_value:
        return []

    context = context_value
    if isinstance(context, str):
        try:
            context = json.loads(context)
        except Exception:
            return []

    if not isinstance(context, dict):
        return []

    # Legacy payload where layer_menu contains the real context
    layer_menu = context.get("layer_menu")
    if layer_menu:
        if isinstance(layer_menu, str):
            try:
                context = json.loads(layer_menu)
            except Exception:
                return []
        elif isinstance(layer_menu, dict):
            context = layer_menu

    levels = context.get(tools_qt.tr('levels')) or context.get('levels') or []
    if not levels:
        level_1 = context.get('level_1')
        level_2 = context.get('level_2')
        level_3 = context.get('level_3')
        levels = [level_1, level_2]
        if level_3:
            levels.append(level_3)

    return [level for level in levels if level]


def get_context_menu_levels(context_value: Any) -> Tuple[Optional[str], Optional[str], Optional[str]]:
    """
    Return safe context menu levels (level_1, level_2, level_3).

    level_1 and level_2 are mandatory for menu construction.
    level_3 is optional and can be None.
    """

    levels = parse_context_levels(context_value)
    if len(levels) < 2:
        return None, None, None

    level_1 = levels[0]
    level_2 = levels[1]
    level_3 = levels[2] if len(levels) > 2 else None
    return level_1, level_2, level_3


def load_settings(dialog, plugin='core'):
    """ Load user UI settings related with dialog position and size """

    # Get user UI config file
    try:
        x = get_config_parser('dialogs_position', f"{dialog.objectName()}_x", "user", "session", plugin=plugin)
        y = get_config_parser('dialogs_position', f"{dialog.objectName()}_y", "user", "session", plugin=plugin)
        width = get_config_parser('dialogs_dimension', f"{dialog.objectName()}_width", "user", "session", plugin=plugin)
        height = get_config_parser('dialogs_dimension', f"{dialog.objectName()}_height", "user", "session", plugin=plugin)

        # Size can be restored on every platform
        if None not in (width, height):
            dialog.resize(int(width), int(height))

        # Wayland forbids clients from setting their own absolute position: leave placement to the compositor
        if None in (x, y) or QApplication.platformName() == 'wayland':
            return

        x, y = int(x), int(y)
        screens = QApplication.screens()
        # Bounding rectangle of all monitors (cross-platform replacement for the Windows virtual screen metrics)
        virtual_geom = QApplication.primaryScreen().virtualGeometry()

        # On a single monitor, negative coords mean the saved position is off-screen, so keep current position
        if (x < 0 or y < 0) and len(screens) == 1:
            return

        # Clamp so the dialog doesn't end up beyond the virtual desktop
        if x > virtual_geom.right():
            x = virtual_geom.right() - dialog.width()
        if y > virtual_geom.bottom():
            y = virtual_geom.bottom()
        dialog.move(x, y)
    except Exception:
        pass


def save_settings(dialog, plugin='core'):
    """ Save user UI related with dialog position and size """

    # Ensure that 'plugin' parameter isn't being populated with int from signal
    try:
        plugin = int(plugin)
        plugin = 'core'
    except ValueError:
        pass

    try:
        geometry = dialog.geometry()
        w, h = geometry.width(), geometry.height()
        set_config_parser('dialogs_dimension', f"{dialog.objectName()}_width", f"{w}", plugin=plugin)
        set_config_parser('dialogs_dimension', f"{dialog.objectName()}_height", f"{h}", plugin=plugin)

        # Wayland reports the absolute position as (0, 0): don't overwrite valid stored values with garbage
        if QApplication.platformName() == 'wayland':
            return

        frame_geometry = dialog.frameGeometry()
        x, y = frame_geometry.x(), frame_geometry.y()
        set_config_parser('dialogs_position', f"{dialog.objectName()}_x", f"{x}", plugin=plugin)
        set_config_parser('dialogs_position', f"{dialog.objectName()}_y", f"{y}", plugin=plugin)
    except Exception:
        pass


def initialize_parsers():
    """ Initialize parsers of configuration files: init, session, giswater, user_params """

    success = True
    for config in global_vars.list_configs:
        filepath, parser = _get_parser_from_filename(config)
        global_vars.configs[config][0] = filepath
        global_vars.configs[config][1] = parser
        if parser is None and config != 'dev':  # dev.config file might or might not exist
            success = False
    return success


def get_config_parser(section: str, parameter: str, config_type, file_name, prefix=True, get_comment=False,
                      chk_user_params=True, get_none=False, force_reload=False, plugin='core') -> str:
    """ Load a simple parser value """

    if config_type not in ("user", "project"):
        msg = "{0}: Reference {1} = '{2}' it is not managed"
        msg_params = ("get_config_parser", "config_type", config_type)
        tools_log.log_warning(msg, msg_params=msg_params)
        return None

    # Get configuration filepath and parser object
    path = global_vars.configs[file_name][0]
    parser = global_vars.configs[file_name][1]

    if plugin != 'core':
        path = f"{tools_os.get_datadir()}{os.sep}{plugin}{os.sep}core{os.sep}config{os.sep}{file_name}.config"
        parser = None
        chk_user_params = False

    # Needed to avoid errors with giswater plugins
    if path is None:
        msg = "{0}: Config file is not set"
        msg_params = ("get_config_parser",)
        tools_log.log_warning(msg, msg_params=msg_params)
        return None

    value = None
    raw_parameter = parameter
    try:
        if parser is None:
            if plugin == 'core':
                msg = "Creating parser for file: {0}"
                msg_params = (path,)
                tools_log.log_info(msg, msg_params=msg_params)
            parser = configparser.ConfigParser(comment_prefixes=";", allow_no_value=True, strict=False)
            parser.read(path)

        # If project has already been loaded and filename is 'init' or 'session', always read and parse file
        if force_reload or (global_vars.project_loaded and file_name in ('init', 'session')):
            parser = configparser.ConfigParser(comment_prefixes=";", allow_no_value=True, strict=False)
            parser.read(path)

        if config_type == 'user' and prefix and global_vars.project_type is not None:
            parameter = f"{global_vars.project_type}_{parameter}"

        if not parser.has_section(section) or not parser.has_option(section, parameter):
            if chk_user_params and config_type in "user":
                value = _check_user_params(section, raw_parameter, file_name, prefix=prefix)
                set_config_parser(section, raw_parameter, value, config_type, file_name, prefix=prefix, chk_user_params=False)
        else:
            value = parser[section][parameter]

        # If there is a value and you don't want to get the comment, it only gets the value part
        if value is not None and not get_comment:
            value = value.split('#')[0].strip()

        if not get_none and _is_empty_config_value(value):
            value = None

        # Check if the parameter exists in the inventory, if not creates it
        if chk_user_params and config_type in "user":
            _check_user_params(section, raw_parameter, file_name, prefix)
    except Exception as e:
        msg = "{0} exception [{1}]: {2}"
        msg_params = ("get_config_parser", type(e).__name__, e)
        tools_log.log_warning(msg, msg_params=msg_params)

    return value


def set_config_parser(section: str, parameter: str, value: str = None, config_type="user", file_name="session",
                      comment=None, prefix=True, chk_user_params=True, plugin='core'):
    """ Save simple parser value """

    if config_type not in ("user", "project"):
        msg = "{0}: Reference {1} = '{2}' it is not managed"
        msg_params = ("set_config_parser", "config_type", config_type)
        tools_log.log_warning(msg, msg_params=msg_params)
        return None

    # Get configuration filepath and parser object
    path = global_vars.configs[file_name][0]

    if plugin != 'core':
        path = f"{tools_os.get_datadir()}{os.sep}{plugin}{os.sep}core{os.sep}config{os.sep}{file_name}.config"
        chk_user_params = False

    try:

        parser = configparser.ConfigParser(comment_prefixes=";", allow_no_value=True, strict=False)
        parser.read(path)

        raw_parameter = parameter
        if config_type == 'user' and prefix and global_vars.project_type is not None:
            parameter = f"{global_vars.project_type}_{parameter}"

        # Check if section exists in file
        if section not in parser:
            parser.add_section(section)

        # Cast to str because parser only allow strings
        value = f"{value}"
        if value is not None:
            # Add the comment to the value if there is one
            if comment is not None:
                value += f" #{comment}"
            # If the previous value had an inline comment, don't remove it
            else:
                # get_none=True: keep "None #comment" so inline comments survive rewrites
                prev = get_config_parser(section, parameter, config_type, file_name, False, True, False,
                                         get_none=True)
                if prev is not None and "#" in str(prev):
                    value += f" #{str(prev).split('#', 1)[1]}"
            parser.set(section, parameter, value)
            # Check if the parameter exists in the inventory, if not creates it
            if chk_user_params and config_type in "user":
                _check_user_params(section, raw_parameter, file_name, prefix)
        else:
            parser.set(section, parameter)  # This is just for writing comments

        if not _write_config_parser(path, parser):
            return

    except Exception as e:
        msg = "{0} exception [{1}]: {2}"
        msg_params = ("set_config_parser", type(e).__name__, e)
        tools_log.log_warning(msg, msg_params=msg_params)
        return


def save_current_tab(dialog, tab_widget, selector_name):
    """
    Save the name of current tab used by the user into QSettings()
        :param dialog: QDialog
        :param tab_widget: QTabWidget
        :param selector_name: Name of the selector (String)
    """

    try:
        index = tab_widget.currentIndex()
        tab = tab_widget.widget(index)
        if tab:
            tab_name = tab.objectName()
            dlg_name = dialog.objectName()
            set_config_parser('dialogs_tab', f"{dlg_name}_{selector_name}", f"{tab_name}")
    except Exception:
        pass


def add_btn_help(dlg):
    """ Create and add btn_help in all dialogs """
    if tools_qt.get_widget(dlg, 'btn_help') is not None:
        return

    btn_help_translation = tools_qt.tr("btn_help", "common", default="Help")
    btn_help = QPushButton(btn_help_translation)
    btn_help.setObjectName("btn_help")
    btn_help.setToolTip(btn_help_translation)
    dlg.lyt_buttons.addWidget(btn_help, 0, dlg.lyt_buttons.columnCount())

    # Get formtype, formname & tabname
    context = dlg.property('context')
    uiname = dlg.property('uiname')

    btn_help.clicked.connect(partial(open_help_link, context, uiname, dlg))


def open_help_link(context, uiname, dlg=None):
    """ Opens the help link for the given dialog, or a default link if not found. """

    # Base URL for the documentation
    domain = get_config_value('help_domain', table='config_param_system')
    if domain is None:
        domain = "https://docs.giswater.org"
    else:
        domain = domain[0]

    language = "es_CR"  # TODO: get dynamic language when documentation is ready

    # Always use 'latest' to avoid errors when plugin version is diferent than docs
    base_url = f"{domain}/latest/{language}/docs/giswater/for-users"

    uiname = uiname.replace("_", "-").replace(" ", "-").lower() + ".html"  # sanitize uiname

    tabname = 'tab_none'
    tab_widgets = dlg.findChildren(QTabWidget)
    if tab_widgets:
        tab_widget = tab_widgets[0]
        index_tab = tab_widget.currentIndex()
        tabname = tab_widget.widget(index_tab).objectName()

    # Construct the path dynamically
    if uiname:
        if uiname == 'info-feature.html':
            feature = dlg.windowTitle().split(' ')[0]
            sql = f"SELECT feature_type FROM {lib_vars.schema_name}.cat_feature WHERE id = '{feature}'"
            print(sql)
            feature_type = tools_db.get_rows(sql)[0]['feature_type']
            if tabname.lower() == 'tab_data':
                file_path = f"{base_url}/dialogs/info_feature/{global_vars.project_type.lower()}/{feature_type.lower()}/{feature.lower()}/tab_data.html"
            elif tabname.lower() == 'tab_epa':
                file_path = f"{base_url}/dialogs/info_feature/{global_vars.project_type.lower()}/{feature_type.lower()}/{feature.lower()}/tab_epa.html"
            else:
                file_path = f"{base_url}/dialogs/info_feature/{tabname.lower()}.html"
        else:
            file_path = f"{base_url}/dialogs/{uiname}"
            if tabname != 'tab_none':
                file_path += f"#{tabname}"  # Append tabname as an anchor if provided
    else:
        # Fallback to the general manual link if context and uiname are missing
        file_path = f"{base_url}/index.html"

    print(file_path)
    tools_os.open_file(file_path)


def open_dialog(dlg, dlg_name=None, stay_on_top=False, title=None, hide_config_widgets=False, plugin_dir=lib_vars.plugin_dir, plugin_name=lib_vars.plugin_name):
    """ Open dialog """
    # Check database connection before opening dialog
    if dlg_name not in ('admin_credentials', 'admin', 'load_menu') and not check_db_connection():
        tools_qgis.show_warning("Database connection is not available")
        return

    # Manage translate
    if dlg_name:
        tools_qt._translate_form(dlg_name, dlg)

    # Set window title
    if title is not None:
        dlg.setWindowTitle(title)

    # Manage stay on top, maximize/minimize button and information button
    flags = Qt.WindowType.WindowCloseButtonHint | Qt.WindowType.WindowMinMaxButtonsHint | Qt.WindowType.Window

    if stay_on_top:
        flags |= Qt.WindowType.WindowStaysOnTopHint

    dlg.setWindowFlags(flags)
    if issubclass(type(dlg), GwDialog):
        dlg.setModal(False)

    if hide_config_widgets:
        hide_widgets_form(dlg, dlg_name)

    # Hide the message bar initially
    try:
        dlg.messageBar().hide()
    except AttributeError:
        pass

    # Create btn_help
    add_btn_help(dlg)

    # Show dialog
    dlg.show()
    # Open dialog
    if issubclass(type(dlg), GwDialog):
        dlg.open()
    elif issubclass(type(dlg), GwMainWindow):
        dlg.show()
    else:
        dlg.show()


def close_dialog(dlg, delete_dlg=True, plugin='core'):
    """ Close dialog """

    if dlg is None or isdeleted(dlg):
        return

    try:
        save_settings(dlg, plugin=plugin)
    except RuntimeError:
        pass

    lib_vars.session_vars['last_focus'] = None

    try:
        dlg.close()
    except RuntimeError:
        pass

    if delete_dlg:
        try:
            dlg.deleteLater()
        except RuntimeError:
            pass


def focus_open_dialog(dlg, alert: bool = True) -> bool:
    """Bring an already-open dialog to the front and alert the user."""
    if dlg is None or isdeleted(dlg):
        return False

    app = QApplication.instance()
    if app is not None and alert:
        app.beep()
        alert_fn = getattr(app, 'alert', None)
        if callable(alert_fn):
            alert_fn(dlg)

    try:
        dlg.raise_()
        dlg.activateWindow()
    except RuntimeError:
        return False
    return True


def connect_signal(obj, pfunc, section, signal_name):
    """
    Connects a signal like this -> obj.connect(pfunc) and stores it in global_vars.active_signals
    :param obj: the object to which the signal will be connected
    :param pfunc: the partial object containing the function to connect and the arguments if needed
    :param section: the name of the parent category
    :param signal_name: the name of the signal. Should be {functionname}_{obj}_{pfunc} like -> {replace_arc}_{xyCoordinates}_{mouse_move_arc}
    :return: the signal. If failed to connect it will return None
    """

    if section not in global_vars.active_signals:
        global_vars.active_signals[section] = {}
    # If the signal is already connected, don't reconnect it, just return it.
    if signal_name in global_vars.active_signals[section]:
        _, signal, _ = global_vars.active_signals[section][signal_name]
        return signal
    # Try to connect signal and save it in the dict
    try:
        signal = obj.connect(pfunc)
        global_vars.active_signals[section][signal_name] = (obj, signal, pfunc)
        return signal
    except Exception:
        pass
    return None


def disconnect_signal(section, signal_name=None, pop=True):
    """
    Disconnects a signal
        :param section: the name of the parent category
        :param signal_name: the name of the signal
        :param pop: should always be True, if False it won't remove the signal from the dict.
        :return: 2 things -> (object which had the signal connected, partial function that was connected with the signal)
                 (None, None) if it couldn't find the signal
    """

    if section not in global_vars.active_signals:
        return None, None

    if signal_name is None:
        old_signals = []
        for signal in global_vars.active_signals[section]:
            old_signals.append(disconnect_signal(section, signal, False))
        for signal in old_signals:
            global_vars.active_signals[section].pop(signal, None)
    if signal_name not in global_vars.active_signals[section]:
        return None, None

    obj, signal, pfunc = global_vars.active_signals[section][signal_name]
    try:
        obj.disconnect(signal)
    except Exception:
        pass
    finally:
        if pop:
            global_vars.active_signals[section].pop(signal_name, None)
            return obj, pfunc
        return signal_name


def reconnect_signal(section, signal_name):
    """
    Disconnects and reconnects a signal
        :param section: the name of the parent category
        :param signal_name: the name of the signal
        :return: True if successfully reconnected, False otherwise (bool)
    """

    obj, pfunc = disconnect_signal(section, signal_name)  # Disconnect the signal
    if obj is not None and pfunc is not None:
        connect_signal(obj, pfunc, section, signal_name)  # Reconnect it
        return True
    return False


def create_body(form='', feature='', filter_fields='', extras=None, list_feature=None, body=None) -> str:
    """ Create and return parameters as body to functions"""

    info_types = {'full': 1}
    plugin_version, message = tools_qgis.get_plugin_version()
    info_type = info_types.get(lib_vars.project_vars['info_type'])
    lang = QSettings().value('locale/globalLocale', QLocale().name())

    if body:
        body.setdefault('client', {"device": 4, "lang": lang, "version": f'"{plugin_version}"'})
        body["client"].setdefault('device', 4)
        body["client"].setdefault('lang', lang)
        if info_type is not None:
            body['client'].setdefault('infoType', info_type)
        if lib_vars.project_epsg is not None:
            body['client'].setdefault('epsg', lib_vars.project_epsg)
        body.setdefault('form', {})
        body.setdefault('feature', {})
        body.setdefault('data', {})
        body["data"].setdefault("filterFields", {})
        body["data"].setdefault("pafeInfo", {})
        str_body = f"$${json.dumps(body)}$$"
    else:
        client = f'$${{"client":{{"device":4, "lang":"{lang}", "version":"{plugin_version}"'
        if info_type is not None:
            client += f', "infoType":{info_type}'
        if lib_vars.project_epsg is not None:
            client += f', "epsg":{lib_vars.project_epsg}'
        client += '}, '

        form = f'"form":{{{form}}}, '
        if list_feature:
            feature = f'"feature":{feature}, '
        else:
            feature = f'"feature":{{{feature}}}, '
        filter_fields = f'"filterFields":{{{filter_fields}}}'
        page_info = '"pageInfo":{}'
        data = f'"data":{{{filter_fields}, {page_info}'
        if extras is not None:
            data += ', ' + extras
        data += '}}$$'
        str_body = "" + client + form + feature + data

    return str_body


def refresh_legend():
    """ This function solves the bug generated by changing the type of feature.
    Mysteriously this bug is solved by checking and unchecking the categorization of the tables.
    """

    layers = [tools_qgis.get_layer_by_tablename('ve_node'),
              tools_qgis.get_layer_by_tablename('ve_connec'),
              tools_qgis.get_layer_by_tablename('ve_gully')]

    for layer in layers:
        if layer:
            ltl = QgsProject.instance().layerTreeRoot().findLayer(layer.id())
            ltm = global_vars.iface.layerTreeView().model()
            legend_nodes = ltm.layerLegendNodes(ltl)
            for ln in legend_nodes:
                current_state = ln.data(Qt.ItemDataRole.CheckStateRole)
                ln.setData(Qt.CheckState.Unchecked, Qt.ItemDataRole.CheckStateRole)
                ln.setData(Qt.CheckState.Checked, Qt.ItemDataRole.CheckStateRole)
                ln.setData(current_state, Qt.ItemDataRole.CheckStateRole)


def get_cursor_multiple_selection():
    """ Set cursor for multiple selection """

    path_cursor = os.path.join(lib_vars.plugin_dir, f"icons{os.sep}dialogs", '153.png')
    if os.path.exists(path_cursor):
        cursor = QCursor(QPixmap(path_cursor))
    else:
        cursor = QCursor(Qt.CursorShape.ArrowCursor)

    return cursor


def hide_parent_layers(excluded_layers=[]):
    """ Hide generic layers """

    layers_changed = {}
    list_layers = ["ve_arc", "ve_node", "ve_connec", "ve_man_frelem", "ve_man_genelem", "ve_link", "ve_element"]
    if global_vars.project_type == 'ud':
        list_layers.append("ve_gully")

    for layer_name in list_layers:
        layer = tools_qgis.get_layer_by_tablename(layer_name)
        if layer and layer_name not in excluded_layers:
            layers_changed[layer] = tools_qgis.is_layer_visible(layer)
            tools_qgis.set_layer_visible(layer)

    return layers_changed


def draw_by_json(complet_result, rubber_band, margin=None, reset_rb=True, color=QColor(255, 0, 0, 100), width=3):

    try:
        if complet_result['body']['feature']['geometry'] is None:
            return
        if complet_result['body']['feature']['geometry']['st_astext'] is None:
            return
    except KeyError:
        return

    list_coord = re.search(r'\((.*)\)', str(complet_result['body']['feature']['geometry']['st_astext']))
    max_x, max_y, min_x, min_y = tools_qgis.get_max_rectangle_from_coords(list_coord)

    # Parse the WKT string to extract the geometry type and coordinates
    wkt_string = complet_result['body']['feature']['geometry']['st_astext']

    if reset_rb:
        reset_rubberband(rubber_band)
    draw_wkt_geometry(wkt_string, rubber_band, color, width)

    if margin is not None:
        tools_qgis.zoom_to_rectangle(max_x, max_y, min_x, min_y, margin, change_crs=False)


def draw_wkt_geometry(wkt_string, rubber_band, color, width):
    match = re.match(r'^(\w+)\((.*)\)$', wkt_string)
    if not match:
        msg = "Invalid WKT string"
        param = f'Error in draw_by_json(), wkt={wkt_string}'
        tools_qgis.show_warning(msg, parameter=param)
    geometry_type = match.group(1)
    coordinates = match.group(2)

    # Draw the geometry based on its type
    if geometry_type == 'POINT':
        x, y = [float(c) for c in coordinates.split()]
        point = QgsPointXY(x, y)
        tools_qgis.draw_point(point, rubber_band, color, width, reset_rb=False)
    elif geometry_type == 'LINESTRING':
        points = [QgsPointXY(float(x), float(y)) for x, y in (c.split() for c in coordinates.split(','))]
        tools_qgis.draw_polyline(points, rubber_band, color, width, reset_rb=False)
    elif geometry_type == 'POLYGON':
        # TODO: accept polygons with inner rings
        rings = QgsGeometry.fromWkt(wkt_string).asPolygon()
        rings = [QgsPointXY(x, y) for x, y in rings[0]]
        tools_qgis.draw_polygon(rings, rubber_band, color, width)
    elif geometry_type == 'GEOMETRYCOLLECTION':
        # Extract the individual geometries from the collection
        # NOTE: will only work if all geometries have the same geometry type
        geometries = re.findall(r'(\w+)\((.*?)\)', coordinates)
        for geometry_type, geometry_coords in geometries:
            geometry_wkt = f'{geometry_type.upper()}({geometry_coords})'
            draw_wkt_geometry(geometry_wkt, rubber_band, color, width)
    elif geometry_type == 'MULTIPOLYGON':
        geometries = re.findall(r'\(\((.*?)\)\)', coordinates)
        for geometry_coords in geometries:
            geometry_wkt = f'POLYGON(({geometry_coords}))'
            draw_wkt_geometry(geometry_wkt, rubber_band, color, width)
    else:
        msg = "Unsuported geometry type"
        tools_qgis.show_warning(msg, parameter=geometry_type)


def enable_feature_type(dialog, widget_name='tbl_relation', ids=None, widget_table=None):
    feature_type = tools_qt.get_widget(dialog, 'feature_type')
    if widget_table is None:
        widget_table = tools_qt.get_widget(dialog, widget_name)
    if feature_type is not None and widget_table is not None:
        if len(ids) > 0:
            feature_type.setEnabled(False)
        else:
            feature_type.setEnabled(True)


def reset_feature_list():
    """ Reset list of selected records """

    ids = []
    list_ids = {'arc': [], 'node': [], 'connec': [], 'gully': [], 'element': [], 'link': []}

    return ids, list_ids


def get_signal_change_tab(dialog, excluded_layers=[], feature_id_widget_name: Optional[str] = None, view_prefix='ve_'):
    """ Set feature_type and layer depending selected tab """

    tab_idx = dialog.tab_feature.currentIndex()
    tab_name = {'tab_arc': 'arc', 'tab_node': 'node', 'tab_connec': 'connec', 'tab_gully': 'gully',
                'tab_elem': 'element', 'tab_link': 'link'}

    feature_type = tab_name.get(dialog.tab_feature.widget(tab_idx).objectName(), 'arc')
    hide_parent_layers(excluded_layers=excluded_layers)
    viewname = f"{view_prefix}{feature_type}"

    field_id = feature_type
    if feature_type == "element":
        viewname = ["ve_man_frelem", "ve_man_genelem", "ve_element"]
        field_id = ["element", "element", "element"]

    # Adding auto-completion to a QLineEdit
    if isinstance(feature_id_widget_name, str):
        feature_id = dialog.findChild(QLineEdit, feature_id_widget_name)
    else:
        feature_id = dialog.findChild(QLineEdit, 'feature_id')

    if feature_id:
        set_completer_widget(viewname, feature_id, field_id, add_id=True)

    global_vars.iface.actionPan().trigger()
    return feature_type


def set_completer_feature_id(widget, feature_type, viewname):
    """ Set autocomplete of widget 'feature_id'
        getting id's from selected @viewname
    """

    if feature_type == '':
        return

    # Adding auto-completion to a QLineEdit
    completer = QCompleter()
    completer.setCaseSensitivity(Qt.CaseSensitivity.CaseInsensitive)
    widget.setCompleter(completer)
    model = QStringListModel()
    sql = (f"SELECT {feature_type}_id"
           f" FROM {lib_vars.schema_name}.{viewname}")
    row = tools_db.get_rows(sql)
    if row:
        for i in range(0, len(row)):
            aux = row[i]
            row[i] = str(aux[0])
        model.setStringList(row)
        completer.setModel(model)


def add_layer_database(tablename=None, the_geom="the_geom", field_id="id", group="GW Layers", sub_group=None, alias=None, sub_sub_group=None, schema=None,
                        visibility=None, auth_id=None, extent=None, passwd=None, create_project=False, force_create_group=False, properties=None):
    """
    Put selected layer into TOC
        :param tablename: Postgres table name (String)
        :param the_geom: Geometry field of the table (String)
        :param field_id: Field id of the table (String)
        :param child_layers: List of layers (StringList)
        :param group: Name of the group that will be created in the toc (String)
        :param alias: Alias of the layer (String)
        :param sub_sub_group: Sub-sub-group of the layer (String)
        :param schema: Schema of the layer (String)
        :param visibility: Visibility of the layer (Boolean)
        :param auth_id: Auth ID of the layer (String)
        :param extent: Extent of the layer (QgsRectangle)
    """

    tablename_og = tablename
    schema_name = tools_db.dao_db_credentials['schema'].replace('"', '') if schema is None else schema

    auth_id = tools_db.get_srid("ext_arc_asset" if schema_name == "am" else "ve_node", schema_name) if auth_id is None else auth_id
    extent = _get_extent_parameters(schema_name, "ext_arc_asset" if schema_name == "am" else "node") if extent is None else extent

    field_id = field_id.replace(" ", "")
    uri, status = tools_db.get_uri(tablename, the_geom, schema_name)
    if status is False:
        uri.setDataSource(schema_name, f'{tablename}', '', None, field_id)
    else:
        uri.setDataSource(schema_name, f'{tablename}', the_geom, None, field_id)

    if passwd is not None:
        uri.setPassword(passwd)

    if force_create_group:
        create_groups = True
    else:
        create_groups = get_config_parser("system", "force_create_qgis_group_layer", "user", "init", prefix=False)
        create_groups = tools_os.set_boolean(create_groups, default=False)

    if sub_group:
        sub_group = sub_group.capitalize()
    if sub_sub_group:
        sub_sub_group = sub_sub_group.capitalize()

    if the_geom == "rast":
        connString = f"PG: dbname={tools_db.dao_db_credentials['db']} host={tools_db.dao_db_credentials['host']} " \
                     f"user={tools_db.dao_db_credentials['user']} password={tools_db.dao_db_credentials['password']} " \
                     f"port={tools_db.dao_db_credentials['port']} mode=2 schema={tools_db.dao_db_credentials['schema']} " \
                     f"column={the_geom} table={tablename}"
        if alias:
            tablename = alias
        layer = QgsRasterLayer(connString, tablename)
        tools_qgis.add_layer_to_toc(layer, group, sub_group, create_groups=create_groups, custom_properties={"gw_id": tablename_og})

    else:
        if alias:
            tablename = alias
        layer = QgsVectorLayer(uri.uri(), f'{tablename}', 'postgres')
        tools_qgis.add_layer_to_toc(layer, group, sub_group, create_groups=create_groups, sub_sub_group=sub_sub_group, custom_properties={"gw_id": tablename_og})

        # Apply styles to layer
        if schema_name != 'cm':
            set_layer_styles(tablename_og, layer, schema_name if schema_name != "am" else None)
            # Get addparam from sys_table
            sql = f"SELECT addparam FROM sys_table WHERE id = '{tablename_og}'"
            row = tools_db.get_row(sql)
            if row:
                addparam = row[0]
                if addparam and addparam.get('refreshSymbology'):
                    renderer = layer.renderer()
                    if isinstance(renderer, QgsCategorizedSymbolRenderer):
                        refresh_categorized_layer_symbology_classes(layer, addparam)

        if not create_project:
            if tablename and schema != 'am' and schema != 'cm':
                # Set layer config
                feature = '"tableName":"' + str(tablename_og) + '", "isLayer":true'
                extras = '"infoType":"' + str(lib_vars.project_vars['info_type']) + '"'
                body = create_body(feature=feature, extras=extras)
                json_result = execute_procedure('gw_fct_getinfofromid', body, schema_name=schema_name)
                config_layer_attributes(json_result, layer, alias)

    if visibility is not None:
        if visibility is False:
            tools_qgis.set_layer_visible(layer, recursive=False, visible=False)

    if the_geom is not None and the_geom != 'None':
        layer.setCrs(QgsCoordinateReferenceSystem(auth_id))
    if layer.crs().isValid() is False:
        layer.setCrs(QgsCoordinateReferenceSystem(f"EPSG:{auth_id}"))

    if extent is not None:
        layer.setExtent(extent)

    if properties is not None:
        for prop, value in properties.items():
            if prop == 'hiddenForm' and value == 'true':
                cfg = layer.editFormConfig()
                cfg.setSuppress(QgsEditFormConfig.FeatureFormSuppress.SuppressOn)
                layer.setEditFormConfig(cfg)

    # Apply mapzone styling if this is a mapzone layer
    mapzone_tables = ['presszone', 'dma', 'sector', 'dqa', 'minsector', 've_presszone', 've_dma', 've_sector', 've_dqa', 've_minsector', 've_minsector_mincut']
    if any(mapzone_table in tablename_og.lower() for mapzone_table in mapzone_tables):
        set_style_mapzones(schema_name)

    if create_project is False:
        global_vars.iface.mapCanvas().refresh()


def add_layer_provider(gw_id: str, cfg, group="GW Layers", sub_group=None, alias=None, sub_sub_group=None,
                        schema=None, visibility=None, force_create_group=False):
    """
    Put selected layer into TOC from provider configuration
        :param gw_id: Giswater ID (String)
        :param cfg: Provider configuration (dict)
        :param group: Name of the group that will be created in the toc (String)
        :param sub_group: Sub-group of the layer (String)
        :param alias: Alias of the layer (String)
        :param sub_sub_group: Sub-sub-group of the layer (String)
        :param schema: Schema of the layer (String)
        :param visibility: Visibility of the layer (Boolean)
        :param force_create_group: Force create group (Boolean)
    """
    schema_name = tools_db.dao_db_credentials['schema'].replace('"', '') if schema is None else schema
    gw_id_og = gw_id

    provider = cfg["provider"]
    layer_type = cfg["layer_type"]

    uri = build_uri(gw_id, provider, cfg)
    if uri is None:
        return

    if alias:
        gw_id = alias

    if layer_type == "raster":
        layer = QgsRasterLayer(uri, gw_id, provider)

    elif layer_type == "vector":
        layer = QgsVectorLayer(uri, gw_id, provider)

    else:
        msg = f"Unsupported layer_type: {layer_type}"
        tools_qgis.show_warning(msg)
        return

    if not layer.isValid():
        msg = f"Invalid layer:\nprovider={provider}\nuri={uri}"
        tools_qgis.show_warning(msg)
        return

    if force_create_group:
        create_groups = True
    else:
        create_groups = get_config_parser("system", "force_create_qgis_group_layer", "user", "init", prefix=False)
        create_groups = tools_os.set_boolean(create_groups, default=False)

    if sub_group:
        sub_group = sub_group.capitalize()
    if sub_sub_group:
        sub_sub_group = sub_sub_group.capitalize()

    tools_qgis.add_layer_to_toc(layer, group, sub_group, create_groups=create_groups, sub_sub_group=sub_sub_group, custom_properties={"gw_id": gw_id_og})

    # Apply styles to layer
    set_layer_styles(gw_id_og, layer, schema_name)
    # Get addparam from sys_table
    sql = f"SELECT addparam FROM sys_table WHERE id = '{gw_id_og}'"
    row = tools_db.get_row(sql)
    if row:
        addparam = row[0]
        if addparam and addparam.get('refreshSymbology'):
            renderer = layer.renderer()
            if isinstance(renderer, QgsCategorizedSymbolRenderer):
                refresh_categorized_layer_symbology_classes(layer, addparam)

    if visibility is not None:
        if visibility is False:
            tools_qgis.set_layer_visible(layer, recursive=False, visible=False)


def build_uri(gw_id: str, provider: str, cfg: dict) -> Optional[str]:

    # direct override
    raw_uri = cfg.get("raw_uri")
    if raw_uri:
        return raw_uri

    builders = {
        "wms": partial(build_network_uri, encoding="query"),
        "wfs": partial(build_network_uri, encoding="query"),
        "xyz": partial(build_network_uri, encoding="query"),
        "oapif": partial(build_network_uri, encoding="qgis"),
        "geojson": partial(build_geojson_uri, gw_id=gw_id)
    }

    builder = builders.get(provider)

    if not builder:
        msg = f"No URI builder for provider: {provider}"
        tools_qgis.show_warning(msg)
        return None

    return builder(cfg)


def build_geojson_uri(gw_id: str, cfg: dict) -> Optional[str]:
    """
    Build a GeoJSON URI from a provider configuration
        :param gw_id: Giswater ID (String)
        :param cfg: Provider configuration (dict)
        :return: URI (String)

    Example of supported format:

    {
        "provider": "geojson",
        "source": {
            "path": "/tmp/test.geojson"
        }
    }

    {
        "provider": "geojson",
        "source": {
            "url": "https://server/data.geojson"
        }
    }

    {
        "provider": "geojson",
        "source": {
            "geojson": {...}
        }
    }
    """

    source = cfg.get("source", {})

    # local file
    if "path" in source:
        return source["path"]

    # remote URL
    if "url" in source:
        return source["url"]

    # inline geojson object
    if "geojson" in source:

        geojson_data = source["geojson"]

        geojson_str = json.dumps(geojson_data)

        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        file_name = f"{gw_id}_{timestamp}"

        vsipath = f"/vsimem/{file_name}.geojson"

        gdal.FileFromMemBuffer(
            vsipath,
            geojson_str.encode("utf-8")
        )

        return vsipath

    return None


def build_network_uri(cfg: dict, encoding: str = "query") -> str:
    """
    Build a network URI from a provider configuration.

    This function normalizes a configuration dictionary into either:
    - a plain query-string style URI (encoding="query")
    - a QGIS-style URI using QgsDataSourceUri (encoding="qgis")

    :param cfg: Provider configuration dictionary.
    :param encoding: Output encoding format:
        - "query": returns a simple key=value&key=value string
        - "qgis": returns a QGIS-encoded URI using QgsDataSourceUri
    :return: URI string

    Examples of supported formats:

    WMS:
    {
        "source": {
            "url": "https://example.com/wms"
        },
        "provider": "wms",
        "layer_type": "raster",
        "uri_params": {
            "format": "image/png",
            "layers": "example_layer",
            "styles": "",
            "dpiMode": 7,
            "featureCount": 10,
            "contextualWMSLegend": "0"
        }
    }

    OAPIF (OGC API Features):
    {
        "source": {
            "url": "https://example.com/oapif"
        },
        "provider": "oapif",
        "layer_type": "vector",
        "uri_params": {
            "srsname": "OGC:CRS84",
            "version": "auto",
            "typename": "example_collection",
            "pagingEnabled": "default",
            "restrictToRequestBBOX": "1",
            "preferCoordinatesForWfsT11": "false"
        }
    }
    """

    source = cfg.get("source", {})
    uri_params = cfg.get("uri_params", {}).copy()
    network = cfg.get("network", {})

    # merge source
    uri_params.update(source)

    # custom headers
    headers = network.get("headers", {})
    if headers:

        header_string = "&".join(
            f"{k}:{v}"
            for k, v in headers.items()
        )

        uri_params["http-header"] = header_string

    uri = QgsDataSourceUri()

    if encoding == "query":
        return "&".join(
            f"{k}={v}"
            for k, v in uri_params.items()
        )

    if encoding == "qgis":
        uri = QgsDataSourceUri()

        for key, value in uri_params.items():
            uri.setParam(key, value)

        return uri.uri(False)

    raise ValueError(
        f"Unsupported URI encoding: {encoding}"
    )


def refresh_categorized_layer_symbology_classes(layer, addparam=None):
    """
    Refresh categorized symbology classes of a layer
        :param layer: Layer to refresh (QgsVectorLayer)
        :param addparam: Addparams of the layer (dict)
    """

    field_name = addparam.get('symbolField')

    renderer = layer.renderer()

    # Symbology type must be categorized
    if (renderer is None or renderer.type() != 'categorizedSymbol') and field_name:
        # Create categorized symbol renderer
        renderer = QgsCategorizedSymbolRenderer(field_name, [])
        layer.setRenderer(renderer)
        # Set color ramp to default (Spectral)
        style = QgsStyle().defaultStyle()
        spectral = style.colorRamp('Spectral')
        renderer.setSourceColorRamp(spectral.clone())

    field_name = renderer.classAttribute()
    if not field_name:
        return

    # Lookup the field index
    fni = layer.fields().indexFromName(field_name)
    if fni == -1:
        return

    # Get existing symbology sources
    src_symbol = renderer.sourceSymbol()
    if src_symbol is None:
        # Try to get symbol from first class
        try:
            classes = renderer.categories()
            if classes:
                src_symbol = classes[0].symbol()
            else:
                src_symbol = QgsSymbol.defaultSymbol(layer.geometryType())
        except Exception as e:
            print(f"Error getting source symbol: {e}")
            src_symbol = QgsSymbol.defaultSymbol(layer.geometryType())

    # Set solid line style to the source symbol
    src_symbol = src_symbol.clone()
    sl = src_symbol.symbolLayer(0)
    if isinstance(sl, QgsSimpleLineSymbolLayer):
        sl.setPenStyle(Qt.PenStyle.SolidLine)

    # Configure dnom symbol if it exists
    if addparam:
        dnom_symbol = addparam.get('dnomSymbol')
        if dnom_symbol not in layer.fields().names():
            dnom_symbol = None
    if dnom_symbol and src_symbol.symbolLayerCount() > 0:
        sl = src_symbol.symbolLayer(0)
        # Support only layers with width (line symbols)
        if sl and hasattr(sl, "setDataDefinedProperty"):
            expression = f'case when {dnom_symbol} is not null then -4.862 + 0.977 * ln("{dnom_symbol}" + 159.243) else 0.25 end'
            sl.setDataDefinedProperty(
                QgsSymbolLayer.Property.PropertyStrokeWidth,
                QgsProperty.fromExpression(expression)
            )

    src_color_ramp = renderer.sourceColorRamp()

    # Get unique values of the field
    unique_vals = list(layer.uniqueValues(fni))

    # Create new categories
    new_cats = QgsCategorizedSymbolRenderer.createCategories(
        values=unique_vals,
        symbol=src_symbol.clone(),
        layer=layer,
        fieldName=field_name
    )

    # Filter out NULL values
    new_cats_true = []
    for cat in list(new_cats):
        if cat.value() is not None:
            new_cats_true.append(cat)
    # Order by value
    new_cats_true.sort(key=lambda x: x.value())

    # Create a new renderer
    new_renderer = QgsCategorizedSymbolRenderer(field_name, new_cats_true)

    if src_color_ramp:
        new_renderer.updateColorRamp(src_color_ramp.clone())

    all_others = addparam.get('allOthers')
    if all_others is None:
        all_others = True
    all_others_name = addparam.get('allOthersName')
    if all_others_name is None:
        all_others_name = "All Others"

    if all_others:
        # Add "all others" category
        all_others_symbol = src_symbol.clone()
        s = all_others_symbol.symbolLayer(0)
        if isinstance(s, QgsSimpleLineSymbolLayer):
            s.setPenStyle(Qt.PenStyle.DashLine)
            s.setColor(QColor("red"))
        elif isinstance(s, QgsSimpleMarkerSymbolLayer):
            s.setColor(QColor("red"))
        elif isinstance(s, QgsSimpleFillSymbolLayer):
            s.setFillColor(QColor("red"))
        all_others_cat = QgsRendererCategory(None, all_others_symbol, all_others_name)
        new_renderer.addCategory(all_others_cat)

    # Replace renderer entirely
    layer.setRenderer(new_renderer)
    layer.triggerRepaint()


def hide_layer_from_toc(layer):
    """Hide layer from the QGIS layer tree view.

    Args:
        layer: Layer to hide
    """
    if layer is None:
        return

    root = QgsProject.instance().layerTreeRoot()
    if root is None:
        return

    ltv = global_vars.iface.layerTreeView()
    if ltv is None:
        return

    tools_qgis.hide_node_from_treeview(root.findLayer(layer.id()), root, ltv)


def hide_group_from_toc(group):
    """Hide group from the QGIS layer tree view.
    Args:
        group: Group to hide. Can be QgsMapLayer objects or .
    """
    if group is None:
        return

    root = QgsProject.instance().layerTreeRoot()
    if root is None:
        return

    ltv = global_vars.iface.layerTreeView()
    if ltv is None:
        return

    tools_qgis.hide_node_from_treeview(root.findGroup(group), root, ltv)


def validate_qml(qml_content):
    if not qml_content:
        return False, "QML is empty!"
    qml_content_no_spaces = qml_content.replace("\n", "").replace("\t", "")
    try:
        root = ET.fromstring(qml_content_no_spaces)  # noqa: F841
        return True, None
    except ET.ParseError as e:
        return False, str(e)


def set_layer_styles(tablename, layer, schema_name):
    # Save current layer custom properties and remove them to avoid QML overwrite them
    custom_properties = {}
    layer_custom_properties = layer.customPropertyKeys()
    for cp_key in layer_custom_properties:
        custom_properties[cp_key] = layer.customProperty(cp_key)

    body = f'$${{"data":{{"layername":"{tablename}"}}}}$$'
    json_return = execute_procedure('gw_fct_getstyle', body, schema_name=schema_name)
    if json_return is None or json_return['status'] == 'Failed':
        return
    if 'styles' in json_return['body']:
        for style_name, qml in json_return['body']['styles'].items():

            if qml is None:
                continue
            valid_qml, error_message = validate_qml(qml)
            if not valid_qml:
                msg = "The QML file is invalid."
                tools_qgis.show_warning(msg, parameter=error_message)
            else:
                style_manager = layer.styleManager()

                default_style_name = tools_qt.tr('default', context_name='QgsMapLayerStyleManager')
                # add style with new name
                style_manager.renameStyle(default_style_name, style_name)
                # set new style as current
                style_manager.setCurrentStyle(style_name)
                tools_qgis.create_qml(layer, qml)

    # Restore actual custom properties
    for cp_key, cp_value in custom_properties.items():
        layer.setCustomProperty(cp_key, cp_value)


def add_layer_temp(dialog, data, layer_name, force_tab=True, reset_text=True, tab_idx=1, del_old_layers=True,
                   group='GW Temporal Layers', call_set_tabs_enabled=True, close=True):
    """
    Add QgsVectorLayer into TOC
        :param dialog: Dialog where to find the tab to be displayed and the textedit to be filled (QDialog or QMainWindow)
        :param data: Json with information
        :param layer_name: Name that will be given to the layer (String)
        :param force_tab: Boolean that tells us if we want to show the tab or not (bool)
        :param reset_text: It allows us to delete the text from the Qtexedit log, or add text below (bool)
        :param tab_idx: Log tab index (int)
        :param del_old_layers: Delete layers added in previous operations (bool)
        :param group: Name of the group to which we want to add the layer (String)
        :param call_set_tabs_enabled: set all tabs, except the last, enabled or disabled (bool).
        :param close: Manage buttons accept, cancel, close...  in function def fill_tab_log(...) (bool).
        :return: Dictionary with text as result of previuos data (String), and list of layers added (QgsVectorLayer).
    """

    text_result = None
    temp_layers_added = []
    srid = lib_vars.data_epsg
    i = 0
    for k, v in list(data.items()):
        if str(k) == "info":
            text_result, change_tab = fill_tab_log(dialog, data, force_tab, reset_text, tab_idx, call_set_tabs_enabled, close)
        elif k in ('point', 'line', 'polygon'):
            if 'features' not in data[k]:
                continue
            if data[k]['features'] is None or len(data[k]['features']) == 0:
                continue

            aux_layer_name = layer_name
            try:
                if not layer_name:
                    aux_layer_name = data[k]['layerName']
            except KeyError:
                aux_layer_name = str(k)

            if del_old_layers:
                tools_qgis.remove_layer(custom_properties={"gw_id": aux_layer_name}, group_name=group)

            # Use GeoJSON approach like manage_json_return
            geojson_str = json.dumps(data[k])
            timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
            file_name = f"{aux_layer_name}_{timestamp}"
            vsipath = f"/vsimem/{file_name}.geojson"
            gdal.FileFromMemBuffer(vsipath, geojson_str)
            v_layer = QgsVectorLayer(vsipath, aux_layer_name, 'ogr')

            # Set CRS if not valid
            if not v_layer.crs().isValid():
                v_layer.setCrs(QgsCoordinateReferenceSystem(f'EPSG:{srid}'))
            v_layer.updateExtents()

            # Get geometry type from layer (like manage_json_return)
            geometry_type = v_layer.geometryType()

            # Add layer to project and group
            tools_qgis.add_layer_to_toc(v_layer, group=group, create_groups=True, custom_properties={"gw_id": aux_layer_name})

            # Increase iterator
            i = i + 1

            # Apply styling
            qml_path = data[k].get('qmlPath')
            category_field = data[k].get('category_field')
            if qml_path:
                tools_qgis.load_qml(v_layer, qml_path)
            elif category_field:
                cat_field = data[k]['category_field']
                size = data[k].get('size', default=2)
                color_values = {'NEW': QColor(0, 255, 0), 'DUPLICATED': QColor(255, 0, 0),
                                'EXISTS': QColor(240, 150, 0)}
                tools_qgis.set_layer_categoryze(v_layer, cat_field, size, color_values)
            else:
                if geometry_type == Qgis.GeometryType.Point:
                    v_layer.renderer().symbol().setSize(3.5)
                    v_layer.renderer().symbol().setColor(QColor("red"))
                elif geometry_type == Qgis.GeometryType.Line:
                    v_layer.renderer().symbol().setWidth(1.5)
                    v_layer.renderer().symbol().setColor(QColor("red"))
                v_layer.renderer().symbol().setOpacity(0.7)
            temp_layers_added.append(v_layer)
            global_vars.iface.layerTreeView().refreshLayerSymbology(v_layer.id())

    return {'text_result': text_result, 'temp_layers_added': temp_layers_added}


def configure_layers_from_table_name(table_name):
    """
    Configure layers based on the provided table name, dynamically fetching the relevant tables
    and applying configurations.

    Args:
        table_name (str): The name of the table list to be processed.

    Returns:
        bool: True if all layers configured successfully, False if any errors occurred.
    """
    # Define table groups dynamically
    table_groups = {
        "curve_id": [
            "ve_inp_pump", "ve_inp_pump_additional", "ve_inp_virtualpump", "ve_inp_virtualvalve",
            "ve_inp_inlet", "ve_inp_tank", "ve_inp_flgreg_outlet", "ve_inp_outlet",
            "ve_inp_flgreg_pump", "ve_inp_outfall", "ve_inp_storage"
        ],
        "curve_id_dscenario": [
            "ve_inp_dscenario_pump", "ve_inp_dscenario_pump_additional", "ve_inp_dscenario_virtualpump",
            "ve_inp_dscenario_virtualvalve", "ve_inp_dscenario_inlet", "ve_inp_dscenario_tank",
            "ve_inp_dscenario_flgreg_outlet", "ve_inp_dscenario_outlet", "ve_inp_dscenario_flgreg_pump",
            "ve_inp_dscenario_outfall", "ve_inp_dscenario_storage"
        ],
        "pattern_id": [
            "ve_inp_pump", "ve_inp_pump_additional", "ve_inp_virtualpump", "ve_inp_reservoir",
            "ve_inp_demand", "ve_inp_junction", "ve_inp_inlet", "ve_inp_tank", "ve_inp_inflows",
            "ve_inp_inflows_poll", "ve_inp_dwf"
        ],
        "pattern_id_dscenario": [
            "ve_inp_dscenario_pump", "ve_inp_dscenario_pump_additional", "ve_inp_dscenario_virtualpump",
            "ve_inp_dscenario_reservoir", "ve_inp_dscenario_demand", "ve_inp_dscenario_junction",
            "ve_inp_dscenario_inlet", "ve_inp_dscenario_tank", "ve_inp_dscenario_inflows",
            "ve_inp_dscenario_inflows_poll"
        ],
        "timeseries": [
            "ve_inp_inflows", "ve_inp_outfall", "ve_inp_raingage"
        ],
        "timeseries_dscenario": [
            "ve_inp_dscenario_inflows", "ve_inp_dscenario_outfall", "ve_inp_dscenario_raingage"
        ],
        "lids_dscenario": [
            "ve_inp_dscenario_lid_usage"
        ],
        "hydrology_id": [
            "ve_inp_subcatchment"
        ],
        "dwf_id": [
            "ve_inp_dwf"
        ]
    }

    # Dynamically collect all 'dscenario' tables if 'table_name' is 'dscenario'
    if table_name == "dscenario":
        tables = []
        for key, table_list in table_groups.items():
            if "dscenario" in key:
                tables.extend(table_list)

    # Dynamically collect all 'curve' tables if 'table_name' is 'curve'
    elif table_name == "curve":
        tables = []
        for key, table_list in table_groups.items():
            if "curve" in key:
                tables.extend(table_list)

    # Dynamically collect all 'pattern' tables if 'table_name' is 'pattern'
    elif table_name == "pattern":
        tables = []
        for key, table_list in table_groups.items():
            if "pattern" in key:
                tables.extend(table_list)

    # Dynamically collect all 'timeseries' tables if 'table_name' is 'timeseries'
    elif table_name == "timeseries":
        tables = []
        for key, table_list in table_groups.items():
            if "timeseries" in key:
                tables.extend(table_list)

    else:
        # Validate if the table_name exists in the table_groups
        if table_name not in table_groups:
            msg = "Invalid {0} '{1}' provided. No configuration performed."
            msg_params = ("table_name", table_name)
            tools_log.log_info(msg, msg_params=msg_params)
            return False
        tables = table_groups[table_name]

    failed_layers = []

    for table in tables:
        # Retrieve the layer object for the table
        layer = tools_qgis.get_layer_by_tablename(table)
        if not layer:
            failed_layers.append(table)
            continue

        # Prepare feature for the API call
        feature = f'"tableName":"{table}"'
        body = create_body(feature=feature)

        # Execute the procedure
        json_result = execute_procedure("gw_fct_getinfofromid", body)

        # Validate the result
        if not json_result or json_result.get("status") != "Accepted":
            msg = "Failed to configure layer '{0}'. Skipping..."
            msg_params = (table,)
            tools_log.log_info(msg, msg_params=msg_params)
            failed_layers.append(table)
            continue

        # Configure the layer attributes
        try:
            config_layer_attributes(json_result, layer, table)
        except Exception:
            failed_layers.append(table)
            continue

    # Handle failed layers
    if failed_layers:
        return False

    return True


def config_layer_attributes(json_result, layer, layer_name, thread=None):

    for field in json_result['body']['data']['fields']:
        valuemap_values = {}

        # Get column index
        field_index = layer.fields().indexFromName(field['columnname'])

        if field_index == -1:
            continue

        # Hide selected fields according table config_form_fields.hidden
        if 'hidden' in field:
            config = layer.attributeTableConfig()
            columns = config.columns()
            for column in columns:
                if column.name == str(field['columnname']):
                    column.hidden = field['hidden']
                    break
            config.setColumns(columns)
            layer.setAttributeTableConfig(config)

        # Set alias column
        if field['label']:
            norm_label = normalize_label(field['label'], add_colon=False)
            layer.setFieldAlias(field_index, norm_label)

        # widgetcontrols
        widgetcontrols = field.get('widgetcontrols')
        if widgetcontrols:
            if widgetcontrols.get('setQgisConstraints') is True:
                layer.setFieldConstraint(field_index, QgsFieldConstraints.Constraint.ConstraintNotNull,
                                         QgsFieldConstraints.ConstraintStrength.ConstraintStrengthSoft)
                layer.setFieldConstraint(field_index, QgsFieldConstraints.Constraint.ConstraintUnique,
                                         QgsFieldConstraints.ConstraintStrength.ConstraintStrengthHard)

        if field.get('ismandatory') is True:
            layer.setFieldConstraint(field_index, QgsFieldConstraints.Constraint.ConstraintNotNull,
                                     QgsFieldConstraints.ConstraintStrength.ConstraintStrengthHard)
        else:
            layer.setFieldConstraint(field_index, QgsFieldConstraints.Constraint.ConstraintNotNull,
                                     QgsFieldConstraints.ConstraintStrength.ConstraintStrengthSoft)

        # Manage editability
        # Get layer config
        config = layer.editFormConfig()
        try:
            # Set field editability
            config.setReadOnly(field_index, not field['iseditable'])
        except KeyError:
            pass
        finally:
            # Set layer config
            layer.setEditFormConfig(config)

        # delete old values on ValueMap
        editor_widget_setup = QgsEditorWidgetSetup('ValueMap', {'map': valuemap_values})
        layer.setEditorWidgetSetup(field_index, editor_widget_setup)

        # Manage ValueRelation configuration
        use_vr = 'widgetcontrols' in field and field['widgetcontrols'] \
                 and 'valueRelation' in field['widgetcontrols'] and field['widgetcontrols']['valueRelation']

        if use_vr:
            value_relation = field['widgetcontrols']['valueRelation']
            try:
                vr_layer = value_relation.get('layer', '')
                layer_obj = tools_qgis.get_layer_by_tablename(vr_layer)
                if layer_obj is None:
                    add_to_toc = thread is None
                    layer_obj = load_layer_in_hidden_group(vr_layer, value_relation.get('keyColumn', ''), add_to_toc=add_to_toc)
                    if thread:
                        if layer_obj.name() not in [layer.name() for layer in thread.vr_layers_to_add]:
                            thread.vr_layers_to_add.add(layer_obj)

                if layer_obj is None:
                    raise Exception(f"Layer '{vr_layer}' not found")

                vr_layer = layer_obj.id()  # Get layer id
                # Get required keys with safe defaults
                vr_key_column = value_relation.get('keyColumn', 'id')  # Get 'Key' with default
                vr_value_column = value_relation.get('valueColumn', 'idval')  # Get 'Value' with default
                vr_allow_nullvalue = tools_os.set_boolean(value_relation.get('nullValue'), False)
                vr_filter_expression = value_relation.get('filterExpression', '')  # Get 'FilterExpression' with default
                if vr_filter_expression is None:
                    vr_filter_expression = ''
                vr_allow_multi = tools_os.set_boolean(value_relation.get('allowMulti'), False)
                vr_use_completer = tools_os.set_boolean(value_relation.get('useCompleter'), False)
                try:
                    vr_nof_columns = int(value_relation.get('nofColumns', 1))
                except (ValueError, TypeError):
                    vr_nof_columns = 1

                # Create and apply ValueRelation config
                editor_widget_setup = QgsEditorWidgetSetup('ValueRelation', {'Layer': str(vr_layer),
                                                                             'Key': str(vr_key_column),
                                                                             'Value': str(vr_value_column),
                                                                             'AllowNull': vr_allow_nullvalue,
                                                                             'FilterExpression': str(vr_filter_expression),
                                                                             'AllowMulti': vr_allow_multi,
                                                                             'UseCompleter': vr_use_completer,
                                                                             'NofColumns': vr_nof_columns})
                layer.setEditorWidgetSetup(field_index, editor_widget_setup)

            except Exception as e:
                msg = "Failed to set ValueRelation for field '{0}': {1}"
                msg_params = (field.get('columnname'), e)
                tools_log.log_warning(msg, msg_params=msg_params)
                if thread:
                    thread.exception = e
                    thread.vr_errors.add(layer_name)
                    if 'layer' in value_relation:
                        thread.vr_missing.add(value_relation['layer'])
                    thread.message = f"ValueRelation for {thread.vr_errors} switched to ValueMap because " \
                                        f"layers {thread.vr_missing} are not present on QGIS project"

        if not use_vr:
            # Manage new values in ValueMap
            if field['widgettype'] == 'combo':
                if 'comboIds' in field:
                    # Set values
                    for i in range(0, len(field['comboIds'])):
                        valuemap_values[field['comboNames'][i]] = field['comboIds'][i]
                # Set values into valueMap
                editor_widget_setup = QgsEditorWidgetSetup('ValueMap', {'map': valuemap_values})
                layer.setEditorWidgetSetup(field_index, editor_widget_setup)
            elif field['widgettype'] == 'check':
                config = {'CheckedState': 'true', 'UncheckedState': 'false'}
                editor_widget_setup = QgsEditorWidgetSetup('CheckBox', config)
                layer.setEditorWidgetSetup(field_index, editor_widget_setup)
            elif field['widgettype'] == 'datetime':
                config = {'allow_null': True,
                          'calendar_popup': True,
                          'display_format': 'yyyy-MM-dd',
                          'field_format': 'yyyy-MM-dd',
                          'field_iso_format': False}
                editor_widget_setup = QgsEditorWidgetSetup('DateTime', config)
                layer.setEditorWidgetSetup(field_index, editor_widget_setup)
            elif field['widgettype'] == 'textarea':
                editor_widget_setup = QgsEditorWidgetSetup('TextEdit', {'IsMultiline': 'True'})
                layer.setEditorWidgetSetup(field_index, editor_widget_setup)
            elif field['widgettype'] == 'list':
                editor_widget_setup = QgsEditorWidgetSetup('List', {})
                layer.setEditorWidgetSetup(field_index, editor_widget_setup)
            else:
                editor_widget_setup = QgsEditorWidgetSetup('TextEdit', {'IsMultiline': 'False'})
                layer.setEditorWidgetSetup(field_index, editor_widget_setup)

        # multiline: key comes from widgecontrol but it's used here in order to set false when key is missing
        if field['widgettype'] == 'text':
            if field['widgetcontrols'] and 'setMultiline' in field['widgetcontrols']:
                editor_widget_setup = QgsEditorWidgetSetup('TextEdit',
                                                           {'IsMultiline': field['widgetcontrols']['setMultiline']})
            else:
                editor_widget_setup = QgsEditorWidgetSetup('TextEdit', {'IsMultiline': False})
            layer.setEditorWidgetSetup(field_index, editor_widget_setup)

    for field in layer.fields():
        if field.name() not in [field_json['columnname'] for field_json in json_result['body']['data']['fields']]:
            field_index = layer.fields().indexFromName(field.name())
            layer.setFieldAlias(field_index, normalize_label(field.name(), add_colon=False))


def load_missing_layers(filter, group="GW Layers", sub_group=None):
    """ Adds any missing Mincut layers to TOC """

    sql = f"SELECT id, alias, addparam FROM sys_table " \
          f"WHERE id LIKE '{filter}' AND alias IS NOT NULL " \
          f"ORDER BY orderby DESC"
    rows = tools_db.get_rows(sql)
    if rows:
        for tablename, alias, addparam in rows:
            lyr = tools_qgis.get_layer_by_tablename(tablename)
            if not lyr:
                the_geom = 'the_geom'
                if addparam and addparam.get('geom'):
                    the_geom = addparam.get('geom')
                add_layer_database(tablename, the_geom=the_geom, alias=alias, group=group, sub_group=sub_group)


def load_layer_in_hidden_group(layer_name, key_column, add_to_toc=True):
    """ Load a layer into the 'Hidden' group """
    # Resolve schema and table name
    if '.' in layer_name:
        schema, table = layer_name.split('.', 1)
    else:
        schema = lib_vars.schema_name
        table = layer_name

    uri, _ = tools_db.get_uri(tablename=table)
    if uri:
        uri.setDataSource(schema, table, None, "", key_column)
        layer = QgsVectorLayer(uri.uri(False), layer_name, "postgres")
        if layer.isValid():
            if add_to_toc:
                tools_qgis.add_layer_to_toc(layer, group="HIDDEN", create_groups=True, custom_properties={"gw_id": table})
            return layer

    # Select the layer called 've_node'
    layer = tools_qgis.get_layer_by_tablename('ve_node')
    if layer:
        global_vars.iface.setActiveLayer(layer)

    return tools_qgis.get_layer_by_tablename(layer_name)


def fill_tab_log(dialog, data, force_tab=True, reset_text=True, tab_idx=1, call_set_tabs_enabled=True, close=True, end="\n"):
    """
    Populate txt_infolog QTextEdit widget
        :param dialog: QDialog
        :param data: Json
        :param force_tab: Force show tab (bool)
        :param reset_text: Reset(or not) text for each iteration (bool)
        :param tab_idx: index of tab to force (int)
        :param call_set_tabs_enabled: set all tabs, except the last, enabled or disabled (bool)
        :param close: Manage buttons accept, cancel, close... (bool)
        :return: Text received from data (String)
    """

    change_tab = False
    text = tools_qt.get_text(dialog, 'tab_log_txt_infolog', return_string_null=False)
    if text is None:
        text = ""

    if reset_text:
        text = ""
    if 'info' in data and 'values' in data['info']:
        for item in data['info']['values']:
            if 'message' in item:
                if item['message'] is not None:
                    text += str(item['message']) + end
                    if force_tab:
                        change_tab = True
                else:
                    text += end

    tools_qt.set_widget_text(dialog, 'tab_log_txt_infolog', text + end)
    infolog_widget = dialog.findChild(QTextEdit, 'tab_log_txt_infolog')
    if infolog_widget:
        infolog_widget.setReadOnly(True)
    qtabwidget = dialog.findChild(QTabWidget, 'mainTab')
    if qtabwidget is not None:
        qtabwidget.setTabEnabled(qtabwidget.count() - 1, True)
        if change_tab and qtabwidget is not None:
            qtabwidget.setCurrentIndex(tab_idx)
        if call_set_tabs_enabled:
            set_tabs_enabled(dialog)
    if close:
        try:
            dialog.btn_accept.disconnect()
            dialog.btn_accept.hide()
        except Exception:
            pass

        try:
            if hasattr(dialog, 'btn_cancel'):
                dialog.btn_cancel.disconnect()
                dialog.btn_cancel.setText(tools_qt.tr("Close"))
                dialog.btn_cancel.clicked.connect(lambda: dialog.close())
            if hasattr(dialog, 'btn_close'):
                dialog.btn_close.disconnect()
                dialog.btn_close.setText(tools_qt.tr("Close"))
                dialog.btn_close.clicked.connect(lambda: dialog.close())
        except AttributeError:
            # Control if btn_cancel exist
            pass

    return text, change_tab


def disable_tab_log(dialog):
    qtabwidget = dialog.findChild(QTabWidget, 'mainTab')
    if qtabwidget and qtabwidget.widget(qtabwidget.count() - 1).objectName() in ('tab_info', 'tab_infolog', 'tab_loginfo', 'tab_info_log', 'tab_log'):
        qtabwidget.setTabEnabled(qtabwidget.count() - 1, False)


def fill_layer_temp(virtual_layer, data, layer_type, counter, group='GW Temporal Layers', sort_val=None):
    """
    :param virtual_layer: Memory QgsVectorLayer (QgsVectorLayer)
    :param data: Json
    :param layer_type: point, line, polygon...(String)
    :param counter: control if json have values (int)
    :param group: group to which we want to add the layer (string)
    :return:
    """

    attributes_map = {
        int: QVariant.Int,
        float: QVariant.Double,
        bool: QVariant.Bool,
        list: QVariant.StringList,
        str: QVariant.String,
    }
    prov = virtual_layer.dataProvider()
    # Enter editing mode
    virtual_layer.startEditing()

    # Add headers to layer
    if counter > 0:
        for key, value in list(data[layer_type]['features'][0]['properties'].items()):
            if key == 'the_geom':
                continue
            prov.addAttributes([QgsField(str(key), attributes_map.get(type(value), QVariant.String))])

    for feature in data[layer_type]['features']:
        geometry = tools_qgis.get_geometry_from_json(feature)
        if not geometry:
            continue
        attributes = []
        fet = QgsFeature()
        fet.setGeometry(geometry)
        for key, value in feature['properties'].items():
            if key == 'the_geom':
                continue
            attributes.append(value)

        fet.setAttributes(attributes)
        prov.addFeatures([fet])

    # Commit changes
    virtual_layer.commitChanges()
    tools_qgis.add_layer_to_toc(virtual_layer, group=group, create_groups=True, custom_properties={"gw_id": virtual_layer.name()})


def enable_widgets(dialog, result, enable):

    try:
        widget_list = dialog.findChildren(QWidget)
        for widget in widget_list:
            if widget.property('isfilter'):
                continue
            for field in result['fields']:
                if widget.property('columnname') == field['columnname']:
                    # If it's not the main tab we want the widgets to be enabled
                    if field.get('layoutname') is not None and not any(substring in field['layoutname'] for substring in ['main', 'data', 'top', 'bot']):
                        continue
                    if type(widget) in (QDoubleSpinBox, QLineEdit, QSpinBox, QTextEdit, GwHyperLinkLineEdit):
                        set_widget_readonly(widget, not enable)
                    elif isinstance(widget, (QComboBox, QgsDateTimeEdit, QCheckBox)):
                        widget.setEnabled(enable)
                        widget.setStyleSheet("QWidget {color: rgb(110, 110, 110)}")
                    elif type(widget) is QPushButton:
                        # Manage the clickability of the buttons according to the configuration
                        # in the table config_form_fields simultaneously with the edition,
                        # but giving preference to the configuration when iseditable is True
                        if not field['iseditable']:
                            widget.setEnabled(field['iseditable'])
                    elif type(widget) is QListWidget:
                        widget.setEnabled(enable)
                    break

    except RuntimeError:
        pass


def enable_all(dialog, result, from_apply=False):

    try:
        widget_list = dialog.findChildren(QWidget)
        for widget in widget_list:
            if widget.property('keepDisbled'):
                continue
            for field in result['fields']:
                if widget.property('columnname') == field['columnname']:
                    if type(widget) in (QDoubleSpinBox, QLineEdit, QSpinBox, QTextEdit, GwHyperLinkLineEdit):
                        set_widget_readonly(widget, not field['iseditable'], from_apply=from_apply)
                    elif isinstance(widget, (QComboBox, QgsDateTimeEdit)):
                        widget.setEnabled(field['iseditable'])
                        if not from_apply:
                            widget.setStyleSheet(None)
                        widget.setFocusPolicy(Qt.FocusPolicy.StrongFocus if field['iseditable'] else Qt.FocusPolicy.NoFocus)

                    elif type(widget) in (QCheckBox, QPushButton):
                        widget.setEnabled(field['iseditable'])
                        widget.setFocusPolicy(Qt.FocusPolicy.StrongFocus if field['iseditable'] else Qt.FocusPolicy.NoFocus)
                    elif type(widget) is QListWidget:
                        widget.setEnabled(field['iseditable'])
    except RuntimeError:
        pass


def set_stylesheet(field, widget, wtype='label'):

    if field.get('stylesheet') is not None:
        if wtype in field['stylesheet']:
            widget.setStyleSheet("QWidget{" + field['stylesheet'][wtype] + "}")
    return widget


def delete_selected_rows(widget, table_object, field_object_id=None, col_idx=0):
    """ Delete selected objects of the table (by object_id) """

    # Get selected rows
    selected_list = widget.selectionModel().selectedRows()
    if len(selected_list) == 0:
        msg = "Any record selected"
        tools_qgis.show_warning(msg)
        return

    inf_text = ""
    list_id = ""
    if field_object_id is None:
        field_object_id = "id"

    model = widget.model()
    if isinstance(model, QStandardItemModel):
        idx = tools_qt.get_col_index_by_col_name(widget, field_object_id)
        if idx is None:
            idx = col_idx

    for i in range(0, len(selected_list)):
        row = selected_list[i].row()
        if isinstance(model, QStandardItemModel):
            id_ = model.item(row, idx).text()
        else:
            id_ = model.record(row).value(str(field_object_id))
        inf_text += f"{id_}, "
        list_id += f"'{id_}', "
    inf_text = inf_text[:-2]
    list_id = list_id[:-2]
    message = "Are you sure you want to delete these records?"
    title = "Delete records"
    answer = tools_qt.show_question(message, title, inf_text)
    if answer:
        sql = (f"DELETE FROM {table_object} "
               f"WHERE {field_object_id} IN ({list_id})")
        tools_db.execute_sql(sql)
        if hasattr(widget.model(), 'select'):
            widget.model().select()  # Refresh if it's a QSqlTableModel


def set_tabs_enabled(dialog, hide_btn_accept=True, change_btn_cancel=True):
    """ Disable all tabs in the dialog except the log one and change the state of the buttons
    :param dialog: Dialog where tabs are disabled (QDialog)
    :return:
    """

    qtabwidget = dialog.findChild(QTabWidget, 'mainTab')
    for x in range(0, qtabwidget.count() - 1):
        qtabwidget.widget(x).setEnabled(False)
    qtabwidget.setTabEnabled(qtabwidget.count() - 1, True)

    btn_accept = dialog.findChild(QPushButton, 'btn_accept')
    if btn_accept is None:
        btn_accept = dialog.findChild(QPushButton, 'tab_none_btn_accept')
    if btn_accept and hide_btn_accept:
        btn_accept.hide()

    btn_cancel = dialog.findChild(QPushButton, 'btn_cancel')
    if btn_cancel and change_btn_cancel:
        msg = "Close"
        tools_qt.set_widget_text(dialog, btn_accept, msg)


def set_style_mapzones(schema_name: Union[str, None] = None) -> bool:
    """ Puts the received styles, in the received layers in the json sent by the gw_fct_getstylemapzones function """

    extras = '"mapzones":""'
    body = create_body(extras=extras)

    if schema_name is None:
        schema_name = lib_vars.schema_name

    json_return = execute_procedure('gw_fct_getstylemapzones', body, schema_name=schema_name)
    if not json_return or json_return['status'] == 'Failed':
        return False

    for mapzone in json_return['body']['data']['mapzones']:

        # Loop for each mapzone returned on json
        lyr = tools_qgis.get_layer_by_tablename(mapzone['layer'])
        categories = []
        try:
            mode = mapzone['mode']
        except KeyError:  # backwards compatibility for database < 3.6.007
            mode = mapzone['status']

        if mode == 'Disable' or lyr is None:
            continue

        # Loop for each id returned on json
        for id in mapzone['values']:
            # initialize the default symbol for this geometry type
            symbol = QgsSymbol.defaultSymbol(lyr.geometryType())
            if symbol is None:
                continue
            try:
                symbol.setOpacity(float(mapzone['transparency']))
            except KeyError:  # backwards compatibility for database < 3.5.030
                symbol.setOpacity(float(mapzone['opacity']))

            # Setting simp
            R = random.randint(0, 255)
            G = random.randint(0, 255)
            B = random.randint(0, 255)
            if mode == 'Stylesheet':
                try:
                    R = id['stylesheet']['color'][0]
                    G = id['stylesheet']['color'][1]
                    B = id['stylesheet']['color'][2]
                except (TypeError, KeyError):
                    R = random.randint(0, 255)
                    G = random.randint(0, 255)
                    B = random.randint(0, 255)

            elif mode == 'Random':
                R = random.randint(0, 255)
                G = random.randint(0, 255)
                B = random.randint(0, 255)

            # Setting sytle
            layer_style = {'color': '{}, {}, {}'.format(int(R), int(G), int(B))}
            symbol_layer = QgsSimpleFillSymbolLayer.create(layer_style)

            if symbol_layer is not None:
                symbol.changeSymbolLayer(0, symbol_layer)
            category = QgsRendererCategory(id['id'], symbol, str(id['id']))
            categories.append(category)

        # Add a category for any other value not categorized
        symbol = QgsSymbol.defaultSymbol(lyr.geometryType())
        if symbol is None:
            continue
        try:
            symbol.setOpacity(float(mapzone['transparency']))
        except KeyError:  # backwards compatibility for database < 3.5.030
            symbol.setOpacity(float(mapzone['opacity']))
        layer_style = {'color': '{}, {}, {}'.format(int(random.randint(0, 255)), int(random.randint(0, 255)), int(random.randint(0, 255)))}
        symbol_layer = QgsSimpleFillSymbolLayer.create(layer_style)
        if symbol_layer is not None:
            symbol.changeSymbolLayer(0, symbol_layer)
        category = QgsRendererCategory('', symbol, '')
        categories.append(category)

        # apply symbol to layer renderer
        lyr.setRenderer(QgsCategorizedSymbolRenderer(mapzone['idname'], categories))

        # repaint layer
        lyr.triggerRepaint()
    return True


def manage_feature_cat():
    """ Manage records from table 'cat_feature' """

    # Dictionary to keep every record of table 'cat_feature'
    # Key: field tablename
    # Value: Object of the class SysFeatureCat
    feature_cat = {}

    body = create_body()
    result = execute_procedure('gw_fct_getcatfeaturevalues', body)
    if not result:
        return None

    msg = tools_qt.tr("Field child_layer of id: ")
    for value in result['body']['data']['values']:
        tablename = value['child_layer']
        if not tablename:
            msg += f"{value['id']}, "
            continue
        elem = GwCatFeature(value['id'], value['feature_class'], value['feature_type'], value['shortcut_key'],
                            value['parent_layer'], value['child_layer'])

        feature_cat[tablename] = elem

    feature_cat = OrderedDict(sorted(feature_cat.items(), key=lambda t: t[0]))

    if msg != tools_qt.tr("Field child_layer of id: "):
        msg = "{0} is not defined in table cat_feature"
        msg_params = (msg, )
        tools_qgis.show_warning(msg, msg_params=msg_params)

    return feature_cat


def build_dialog_info(dialog, result, my_json=None, layout_positions=None, tab_name=None, enable_actions=True, is_inserting=False):
    """
    Builds the dialog and configures fields and actions dynamically based on the provided result.
    Handles tab-specific action visibility and configurations.
    """
    fields = result['body']['data']
    if 'fields' not in fields:
        return
    grid_layout = dialog.findChild(QGridLayout, 'lyt_main_1')

    # Inicialitzar layout_positions si no es proporciona
    if layout_positions is None:
        layout_positions = {}

    for order, field in enumerate(fields["fields"]):
        if field.get('hidden'):
            continue

        label = QLabel()
        label.setObjectName('lbl_' + field['label'])
        label.setText(field['label'].capitalize())

        if 'tooltip' in field:
            label.setToolTip(field['tooltip'])
        else:
            label.setToolTip(field['label'].capitalize())

        widget = None
        if field['widgettype'] in ('text', 'textline', 'list') or field['widgettype'] == 'typeahead':
            completer = QCompleter()
            widget = add_lineedit(field)
            widget = set_widget_size(widget, field)
            widget = set_data_type(field, widget)
            if field['widgettype'] == 'typeahead':
                widget = set_typeahead(field, dialog, widget, completer)
            widget.editingFinished.connect(partial(get_values, dialog, widget, my_json))
        elif field['widgettype'] == 'datetime':
            widget = add_calendar(dialog, field)
            widget.valueChanged.connect(partial(get_values, dialog, widget, my_json))
        elif field['widgettype'] == 'hyperlink':
            widget = add_hyperlink(field)
        elif field['widgettype'] == 'textarea':
            widget = add_textarea(field)
            widget.textChanged.connect(partial(get_values, dialog, widget, my_json))
        elif field['widgettype'] in ('combo', 'combobox'):
            widget = add_combo(field)
            widget.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
            widget.currentIndexChanged.connect(partial(get_values, dialog, widget, my_json))
        elif field['widgettype'] in ('check', 'checkbox'):
            kwargs = {"dialog": dialog, "field": field}
            widget = add_checkbox(**kwargs)
            widget.stateChanged.connect(partial(get_values, dialog, widget, my_json))
        elif field['widgettype'] == 'button':
            kwargs = {"dialog": dialog, "field": field}
            widget = add_button(**kwargs)
        elif field['widgettype'] == 'multiple_checkbox':
            kwargs = {"dialog": dialog, "field": field}
            widget = add_multiple_checkbox(**kwargs)
            widget.itemChanged.connect(partial(get_values, dialog, widget, my_json))
            label.setAlignment(Qt.AlignmentFlag.AlignTop)
        elif field['widgettype'] == 'multiple_option':
            # Create completer for autocomplete functionality
            completer = QCompleter()

            # Create and configure the line edit widget
            widget = add_lineedit(field)
            widget = set_widget_size(widget, field)
            widget = set_data_type(field, widget)
            widget = set_typeahead(field, dialog, widget, completer)

            # Create filtered value relation widget
            kwargs = {"dialog": dialog, "field": field}
            widget = add_multiple_option(**kwargs)

            # Connect list widget signals to update values when rows change
            widget.findChild(QListWidget).model().rowsRemoved.connect(partial(get_values, dialog, widget, my_json))
            widget.findChild(QListWidget).model().rowsInserted.connect(partial(get_values, dialog, widget, my_json))

            # Align label to top since this widget can grow vertically
            label.setAlignment(Qt.AlignmentFlag.AlignTop)

        if 'ismandatory' in field and widget is not None:
            if field['widgettype'] == 'multiple_option':
                widget.findChild(QListWidget).setProperty('ismandatory', field['ismandatory'])
            else:
                widget.setProperty('ismandatory', field['ismandatory'])

        # Gestió de posicions millorada - mantenir la lògica original però amb millores
        if 'layoutorder' in field and field['layoutorder'] is not None:
            order = field['layoutorder']

        # Aplicar la lògica de posicions no repetides
        layout_name = 'lyt_main_1'
        if layout_positions is not None:
            if layout_name not in layout_positions:
                layout_positions[layout_name] = set()

            widget_pos = order
            while widget_pos in layout_positions[layout_name]:
                widget_pos += 1

            layout_positions[layout_name].add(widget_pos)
            order = widget_pos

        grid_layout.addWidget(label, order, 0)
        grid_layout.addWidget(widget, order, 1)

    vertical_spacer1 = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
    spacer_row = grid_layout.rowCount()
    grid_layout.addItem(vertical_spacer1, spacer_row, 0, 1, 2)
    grid_layout.setRowStretch(spacer_row, 1)

    # Handle actions dynamically based on tab_name
    form_config = result['body'].get('form', {})
    visible_tabs = form_config.get('visibleTabs', [])  # Retrieve tab-specific visibility
    actions_list = dialog.findChildren(QAction)

    # Hide all actions by default
    for action in actions_list:
        if not action.objectName():
            continue
        action.setVisible(False)

    # Configure actions based on the tab_name
    # Configure actions based on the tab_name
    for tab in visible_tabs:
        if tab['tabName'] == tab_name and 'tabactions' in tab:
            if tab['tabactions']:  # Ensure tabactions is not None
                for act in tab['tabactions']:
                    action = dialog.findChild(QAction, act['actionName'])
                    if action:
                        action.setVisible(True)
                        if 'actionTooltip' in act:
                            action.setToolTip(tools_qt.tr(act['actionTooltip']))

    # Enable/Disable actions based on global and static rules
    static_actions = ('actionEdit', 'actionCentered', 'actionLink', 'actionHelp',
                      'actionSection', 'actionOrifice', 'actionOutlet', 'actionPump', 'actionWeir', 'actionDemand')

    for action in actions_list:
        if action.objectName() not in static_actions:
            if is_inserting:
                # For inserting, follow database configuration
                for tab in visible_tabs:
                    if tab['tabName'] == tab_name and 'tabactions' in tab:
                        for act in tab['tabactions']:
                            if action.objectName() == act['actionName']:
                                action.setEnabled(not act.get('disabled', False))
            else:
                # For editing, enable/disable based on editable state
                action.setEnabled(enable_actions)

    return result


def build_dialog_options(dialog, row, pos, _json, temp_layers_added=None, module=sys.modules[__name__]):

    try:
        fields = row[pos]
    except Exception:
        fields = row
    field_id = ''
    if 'fields' in fields:
        field_id = 'fields'
    elif fields.get('return_type') not in ('', None):
        field_id = 'return_type'

    if field_id == '':
        return

    if fields[field_id] is not None:
        for field in fields[field_id]:

            check_parameters(field)

            if field['label']:
                lbl = QLabel()
                lbl.setObjectName('lbl' + field['widgetname'])
                lbl.setText(field['label'])
                lbl.setMinimumSize(160, 0)
                lbl.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Preferred)
                if 'tooltip' in field:
                    lbl.setToolTip(field['tooltip'])

                widget = None
                if field['widgettype'] == 'text' or field['widgettype'] == 'linetext' or field['widgettype'] == 'list':
                    widget = QLineEdit()
                    if 'isMandatory' in field:
                        widget.setProperty('ismandatory', field['isMandatory'])
                    else:
                        widget.setProperty('ismandatory', False)
                    if field.get('value') is not None:
                        widget.setText(field['value'])
                        widget.setProperty('value', field['value'])
                    widgetcontrols = field.get('widgetcontrols')
                    if widgetcontrols and widgetcontrols.get('regexpControl') is not None:
                        pass
                    widget.editingFinished.connect(partial(get_dialog_changed_values, dialog, None, widget, field, _json))
                    widget.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
                    datatype = field.get('datatype')
                    if datatype == 'int':
                        widget.setValidator(QIntValidator())
                    elif datatype == 'float':
                        widget.setValidator(QDoubleValidator())
                elif field['widgettype'] == 'combo':
                    widget = add_combo(field)
                    if field.get('parentname') and field.get('filterquery'):
                        widget.setProperty('parentname', field['parentname'])
                        widget.setProperty('filterquery', field['filterquery'])
                    widget.currentIndexChanged.connect(partial(get_dialog_changed_values, dialog, None, widget, field, _json))
                    signal = field.get('signal')
                    if signal:
                        widget.currentIndexChanged.connect(partial(getattr(module, signal), dialog))
                        getattr(module, signal)(dialog)
                    widget.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
                elif field['widgettype'] == 'check':
                    widget = QCheckBox()
                    if field.get('value') is not None:
                        widget.setChecked(tools_os.set_boolean(field['value']))
                        widget.setProperty('value', field['value'])
                    widget.stateChanged.connect(partial(get_dialog_changed_values, dialog, None, widget, field, _json))
                    widget.setSizePolicy(QSizePolicy.Policy.Fixed, QSizePolicy.Policy.Fixed)
                elif field['widgettype'] == 'datetime':
                    widget = CustomQgsDateTimeEdit()
                    widget.setAllowNull(True)
                    widget.setCalendarPopup(True)
                    widget.setDisplayFormat('yyyy/MM/dd')
                    if lib_vars.date_format in ("dd/MM/yyyy", "dd-MM-yyyy", "yyyy/MM/dd", "yyyy-MM-dd"):
                        widget.setDisplayFormat(lib_vars.date_format)
                    widget.clear()  # Set the date to NULL initially
                    if field.get('value') is not None:
                        date = QDate.fromString(field['value'].replace('/', '-'), 'yyyy-MM-dd')
                        widget.setProperty('value', field['value'].replace('/', '-'))
                        widget.setDate(date)
                    widget.valueChanged.connect(partial(get_dialog_changed_values, dialog, None, widget, field, _json))
                    widget.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
                elif field['widgettype'] == 'spinbox':
                    widget = QDoubleSpinBox()
                    widgetcontrols = field.get('widgetcontrols')
                    if widgetcontrols:
                        spinboxDecimals = widgetcontrols.get('spinboxDecimals')
                        if spinboxDecimals is not None:
                            widget.setDecimals(spinboxDecimals)
                        maximumNumber = widgetcontrols.get('maximumNumber')
                        if maximumNumber is not None:
                            widget.setMaximum(maximumNumber)
                    if field.get('value') is not None:
                        value = float(str(field['value']))
                        widget.setValue(value)
                        widget.setProperty('value', field['value'])
                    widget.valueChanged.connect(partial(get_dialog_changed_values, dialog, None, widget, field, _json))
                    widget.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
                elif field['widgettype'] == 'button':
                    kwargs = {"dialog": dialog, "field": field, "temp_layers_added": temp_layers_added}
                    widget = add_button(**kwargs)
                    widget = set_widget_size(widget, field)

                if widget is None:
                    continue

                # Set editable/readonly
                iseditable = field.get('iseditable')
                if type(widget) in (QLineEdit, QDoubleSpinBox):
                    if iseditable in (False, "False"):
                        set_widget_readonly(widget, True)
                    if type(widget) is QLineEdit:
                        if 'placeholder' in field:
                            widget.setPlaceholderText(field['placeholder'])
                elif isinstance(widget, (QComboBox, QCheckBox)):
                    if iseditable in (False, "False"):
                        widget.setEnabled(False)
                widget.setObjectName(field['widgetname'])
                if iseditable is not None and type(widget) not in (QLineEdit, QDoubleSpinBox):
                    widget.setEnabled(bool(iseditable))

                add_widget(dialog, field, lbl, widget)


def check_parameters(field):
    """ Check that all the parameters necessary to mount the form are correct """

    msg = ""
    if 'widgettype' not in field:
        msg += tools_qt.tr("widgettype not found. ")

    if 'widgetname' not in field:
        msg += tools_qt.tr("widgetname not found. ")

    if field.get('widgettype') not in ('text', 'linetext', 'combo', 'check', 'datetime', 'spinbox', 'button', 'list'):
        msg += tools_qt.tr("widgettype is wrongly configured. Needs to be in ")
        msg += "('text', 'linetext', 'combo', 'check', 'datetime', 'spinbox', 'button', 'list')"

    if 'layoutorder' not in field:
        msg += tools_qt.tr("layoutorder not found. ")

    if msg != "":
        tools_qgis.show_warning(msg)


def add_widget(dialog, field, lbl, widget):
    """ Insert widget into layout """
    layout = dialog.findChild(QGridLayout, field['layoutname'])
    if layout in (None, 'null', 'NULL', 'Null'):
        return
    orientation = layout.property('lytOrientation')
    if orientation == 'horizontal':
        row = 0
        col = int(field['layoutorder'])
    else:  # default vertical
        row = int(field['layoutorder'])
        col = 0
    if lbl is None:
        col = row
        row = 0
    elif not isinstance(widget, QTableView):
        layout.addWidget(lbl, row, col)
        col = 1
    if type(widget) is QSpacerItem:
        layout.addItem(widget, row, col)
    else:
        layout.addWidget(widget, row, col)
    if lbl is not None:
        layout.setColumnStretch(col, 1)


def add_widget_combined(dialog, field, label, widget, pos_offset):
    """ Insert widget into layout based on orientation and label position """

    layout = dialog.findChild(QGridLayout, field['layoutname'])
    if layout in (None, 'null', 'NULL', 'Null'):
        return
    orientation = layout.property('lytOrientation')
    widget_pos = int(field.get('layoutorder', 0))
    row, col = (0, widget_pos + pos_offset) if orientation == "horizontal" else (widget_pos + pos_offset, 0)

    label_pos = field['widgetcontrols']['labelPosition'] if (
                            'widgetcontrols' in field and field['widgetcontrols'] and 'labelPosition' in field['widgetcontrols']) else None

    if label:
        if orientation == "horizontal":
            if label_pos == 'top':
                layout.addWidget(label, row, col)
                row += 1
            else:
                layout.addWidget(label, row, col)
                col += 1
        else:
            if label_pos == 'top':
                layout.addWidget(label, row, col)
                row += 1
            else:
                layout.addWidget(label, row, col)
                col += 1
            layout.setColumnStretch(col, 1)
        pos_offset += 1

    if isinstance(widget, QSpacerItem):
        layout.addItem(widget, row, col)
        layout.setColumnStretch(col, 1)
    else:
        layout.addWidget(widget, row, col)

    if label and orientation == "horizontal":
        layout.setColumnStretch(col, 1)

    return pos_offset


def get_dialog_changed_values(dialog, chk, widget, field, list, value=None):

    elem = {}
    if type(widget) is QLineEdit:
        value = tools_qt.get_text(dialog, widget, return_string_null=False)
    elif isinstance(widget, QComboBox):
        value = tools_qt.get_combo_value(dialog, widget, 0)
    elif type(widget) is QCheckBox:
        value = tools_qt.is_checked(dialog, widget)
    elif type(widget) is QDateEdit:
        value = tools_qt.get_calendar_date(dialog, widget)

    # When the QDoubleSpinbox contains decimals, for example 2,0001 when collecting the value, the spinbox itself sends
    # 2.0000999999, as in reality we only want, maximum 4 decimal places, we round up, thus fixing this small failure
    # of the widget
    if type(widget) in (QSpinBox, QDoubleSpinBox):
        value = round(value, 4)

    elem['widget'] = str(widget.objectName())
    elem['value'] = value
    if chk is not None:
        if chk.isChecked():
            elem['chk'] = str(chk.objectName())
            elem['isChecked'] = str(tools_qt.is_checked(dialog, chk))

    if 'sys_role_id' in field:
        elem['sys_role_id'] = str(field['sys_role_id'])

    # Search for the widget and remove it if it's in the list
    idx_del = None
    for i in range(len(list)):
        if list[i]['widget'] == elem['widget']:
            idx_del = i
            break
    if idx_del is not None:
        list.pop(idx_del)

    list.append(elem)


def add_button(**kwargs):
    """
    :param dialog: (QDialog)
    :param field: Part of json where find info (Json)
    :param temp_layers_added: List of layers added to the toc
    :param module: Module where find 'function_name', if 'function_name' is not in this module
    :return: (QWidget)
    functions called in -> widget.clicked.connect(partial(getattr(module, function_name), **kwargs)) atm:
        module = tools_backend_calls -> def add_object(**kwargs)
        module = tools_backend_calls -> def delete_object(**kwargs):
        module = tools_backend_calls -> def manage_document(doc_id, **kwargs):
        module = tools_backend_calls -> def manage_element(element_id, **kwargs):
        module = tools_backend_calls -> def open_selected_element(**kwargs):
        module = featuretype_change_button -> def btn_accept_featuretype_change(**kwargs):
    """

    field = kwargs['field']
    module = tools_backend_calls
    widget = QPushButton()
    widget.setObjectName(field['widgetname'])
    if 'columnname' in field:
        widget.setProperty('columnname', field['columnname'])
    if 'value' in field:
        txt = field['value']
        if field.get('valueLabel'):
            txt = field.get('valueLabel')
        widget.setText(txt)
        widget.setProperty('value', field['value'])
    if 'widgetcontrols' in field and field['widgetcontrols']:
        widget.setProperty('widgetcontrols', field['widgetcontrols'])
        txt = field['widgetcontrols'].get('text')
        if txt:
            widget.setText(txt)
    if 'tooltip' in field:
        widget.setToolTip(field['tooltip'])

    widget.resize(widget.sizeHint().width(), widget.sizeHint().height())
    function_name = None
    real_name = widget.objectName()
    if 'tab_data_' in widget.objectName():
        real_name = widget.objectName()[9:len(widget.objectName())]

    if field['stylesheet'] is not None and 'icon' in field['stylesheet']:
        icon = field['stylesheet']['icon']
        add_icon(widget, f'{icon}')

    func_params = ""

    if not field.get('widgetfunction'):
        return widget

    if 'module' in field['widgetfunction']:
        module = globals()[field['widgetfunction']['module']]
    function_name = field['widgetfunction'].get('functionName')
    if function_name is not None:
        exist = tools_os.check_python_function(module, function_name)
        if not exist:
            msg = "widget {0} has associated function {1}, but {2} not exist"
            msg_params = (real_name, function_name, function_name,)
            tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, msg_params=msg_params)
            return widget
        if 'parameters' in field['widgetfunction']:
            func_params = field['widgetfunction']['parameters']

    kwargs['widget'] = widget
    kwargs['message_level'] = 1
    kwargs['function_name'] = function_name
    kwargs['func_params'] = func_params
    if function_name:
        widget.clicked.connect(partial(getattr(module, function_name), **kwargs))
    return widget


def add_spinbox(**kwargs):
    field = kwargs['field']
    widget = None
    if field['widgettype'] == 'spinbox':
        widget = QSpinBox()
    elif field['widgettype'] == 'doubleSpinbox':
        widget = QDoubleSpinBox()
        if field.get('widgetcontrols') and 'spinboxDecimals' in field['widgetcontrols']:
            widget.setDecimals(field['widgetcontrols']['spinboxDecimals'])

    if 'min' in field['widgetcontrols']['maxMinValues']:
        widget.setMinimum(field['widgetcontrols']['maxMinValues']['min'])
    if 'max' in field['widgetcontrols']['maxMinValues']:
        widget.setMaximum(field['widgetcontrols']['maxMinValues']['max'])

    widget.setObjectName(field['widgetname'])
    if 'widgetcontrols' in field and field['widgetcontrols']:
        widget.setProperty('widgetcontrols', field['widgetcontrols'])
    if 'columnname' in field:
        widget.setProperty('columnname', field['columnname'])
    if 'value' in field:
        if field['widgettype'] == 'spinbox' and field['value'] != "":
            widget.setValue(int(field['value']))
        elif field['widgettype'] == 'doubleSpinbox' and field['value'] != "":
            widget.setValue(float(field['value']))
    if 'iseditable' in field:
        set_widget_readonly(widget, not field['iseditable'])

    return widget


def get_values(dialog, widget, _json=None, ignore_editability=False):

    value = None

    if type(widget) in (QDoubleSpinBox, QLineEdit, QSpinBox, QTextEdit, GwHyperLinkLineEdit):
        if widget.isReadOnly() and not ignore_editability:
            return _json
        if isinstance(widget, QLineEdit):
            selected_id = widget.property("selected_id")
            if selected_id is not None:
                value = selected_id  # Use selected_id for saving
            else:
                value = tools_qt.get_text(dialog, widget, return_string_null=False)
        else:
            value = tools_qt.get_text(dialog, widget, return_string_null=False)
    elif isinstance(widget, QComboBox):
        if not widget.isEnabled() and not ignore_editability:
            return _json
        value = tools_qt.get_combo_value(dialog, widget, 0)
    elif type(widget) is QCheckBox:
        if not widget.isEnabled() and not ignore_editability:
            return _json
        value = tools_qt.is_checked(dialog, widget)
        if value is not None:
            value = str(value).lower()
    elif isinstance(widget, QgsDateTimeEdit):
        if not widget.isEnabled() and not ignore_editability:
            return _json
        value = tools_qt.get_calendar_date(dialog, widget)
    elif isinstance(widget, QListWidget):
        if not widget.isEnabled() and not ignore_editability:
            return _json
        value = []
        for i in range(widget.count()):
            if widget.item(i).checkState() == Qt.CheckState.Checked:
                v = widget.item(i).data(Qt.ItemDataRole.UserRole)
                try:
                    v = int(v)
                except ValueError:
                    pass
                value.append(v)
    elif isinstance(widget, QWidget):
        # Handle filtered value relation widgets
        if widget.property('widgettype') == 'multiple_option':
            # Get the list widget child that contains the actual values
            widget = widget.findChild(QListWidget)

            # Return early if widget is disabled and we're not ignoring editability
            if not widget.isEnabled() and not ignore_editability:
                return _json

            # Build list of selected values
            value = []
            for i in range(widget.count()):
                # Get the data stored in UserRole for each item
                v = widget.item(i).data(Qt.ItemDataRole.UserRole)
                # Try to convert to integer if possible
                try:
                    v = int(v)
                except ValueError:
                    pass
                value.append(v)

    key = str(widget.property('columnname')) if widget.property('columnname') else widget.objectName()
    if key == '' or key is None:
        return _json

    if _json is None:
        _json = {}

    if str(value) == '' or value is None:
        _json[key] = None
    else:
        _json[key] = str(value)
    return _json


def add_checkbox(**kwargs):
    dialog = kwargs.get('dialog')
    field = kwargs.get('field')
    class_info = kwargs.get('class')
    connect_signal = kwargs.get('connectsignal')

    widget = QCheckBox()
    widget.setObjectName(field['widgetname'])
    if field.get('value') in ("t", "true", True):
        widget.setChecked(True)
    if 'widgetcontrols' in field and field['widgetcontrols']:
        widget.setProperty('widgetcontrols', field['widgetcontrols'])
        if field['widgetcontrols'].get('tristate') in ("t", "true", True):
            widget.setTristate(field['widgetcontrols'].get('tristate'))
            if field.get('value') == "":
                widget.setCheckState(1)
    widget.setProperty('columnname', field['columnname'])
    if 'iseditable' in field:
        widget.setEnabled(field['iseditable'])

    if connect_signal is not None and connect_signal is False:
        return widget

    if field.get('widgetfunction'):
        if 'module' in field['widgetfunction']:
            module = globals()[field['widgetfunction']['module']]
        function_name = field['widgetfunction'].get('functionName')
        if function_name is not None:
            if function_name:
                exist = tools_os.check_python_function(module, function_name)
                if not exist:
                    msg = "widget {0} has associated function {1}, but {2} not exist"
                    msg_params = (field['widgetname'], function_name, function_name,)
                    tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, msg_params=msg_params)
                    return widget
            else:
                msg = "Parameter functionName is null for check"
                tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=widget.objectName())

    func_params = ""

    if 'widgetfunction' in field and field['widgetfunction'] and 'functionName' in field['widgetfunction']:
        function_name = field['widgetfunction']['functionName']

        exist = tools_os.check_python_function(module, function_name)
        if not exist:
            msg = "widget {0} has associated function {1}, but {2} not exist"
            msg_params = (field['widgetname'], function_name, function_name,)
            tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, msg_params=msg_params)
            return widget
        if 'parameters' in field['widgetfunction']:
            func_params = field['widgetfunction']['parameters']
    else:
        return widget

    kwargs['widget'] = widget
    kwargs['message_level'] = 1
    kwargs['function_name'] = function_name
    kwargs['func_params'] = func_params
    if function_name:
        widget.stateChanged.connect(partial(getattr(module, function_name), **kwargs))
    else:
        widget.stateChanged.connect(partial(get_values, dialog, widget, class_info.my_json))
    return widget


def add_textarea(field):
    """ Add widgets QTextEdit type """

    widget = QTextEdit()
    widget.setObjectName(field['widgetname'])
    if 'widgetcontrols' in field and field['widgetcontrols']:
        widget.setProperty('widgetcontrols', field['widgetcontrols'])
    if 'columnname' in field:
        widget.setProperty('columnname', field['columnname'])
    if 'value' in field:
        widget.setText(field['value'])
        widget.setProperty('value', field['value'])

    if 'iseditable' in field:
        set_widget_readonly(widget, not field['iseditable'])

    return widget


def add_hyperlink(field):
    """
    functions called in -> widget.clicked.connect(partial(getattr(tools_backend_calls, func_name), widget))
        module = tools_backend_calls -> def open_url(self, widget)

    """

    is_editable = field.get('iseditable')
    if is_editable:
        widget = GwHyperLinkLineEdit()
    else:
        widget = GwHyperLinkLabel()
    widget.setObjectName(field['widgetname'])
    if 'widgetcontrols' in field and field['widgetcontrols']:
        widget.setProperty('widgetcontrols', field['widgetcontrols'])
    if 'columnname' in field:
        widget.setProperty('columnname', field['columnname'])
    if 'value' in field:
        widget.setText(field['value'])
        widget.setProperty('value', field['value'])
    widget.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
    widget.resize(widget.sizeHint().width(), widget.sizeHint().height())
    func_name = None
    real_name = widget.objectName()
    if 'data_' in widget.objectName():
        real_name = widget.objectName()[5:len(widget.objectName())]
    if 'widgetfunction' in field:
        func_name = field['widgetfunction'].get('functionName')
        if func_name is not None:
            if func_name:
                exist = tools_os.check_python_function(tools_backend_calls, func_name)
                if not exist:
                    msg = "widget {0} have associated function {1}, but {2} not exist"
                    msg_params = (real_name, func_name, func_name,)
                    tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, msg_params=msg_params)
                    return widget
            else:
                msg = "Parameter widgetfunction is null for widget hyperlink"
                tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=real_name)
        else:
            tools_log.log_info(field['widgetfunction'])
    else:
        msg = "Parameter widgetfunction not found for widget type hyperlink"
        tools_qgis.show_message(msg, Qgis.MessageLevel.Critical)

    if func_name is not None:
        # Call function-->func_name(widget) or def no_function_associated(self, widget=None, message_level=1)
        widget.clicked.connect(partial(getattr(tools_backend_calls, func_name), widget))

    return widget


def add_calendar(dlg, fld, **kwargs):

    module = tools_backend_calls
    widget = CustomQgsDateTimeEdit()
    widget.setObjectName(fld['widgetname'])
    if 'widgetcontrols' in fld and fld['widgetcontrols']:
        widget.setProperty('widgetcontrols', fld['widgetcontrols'])
    if 'columnname' in fld:
        widget.setProperty('columnname', fld['columnname'])
    widget.setAllowNull(True)
    widget.setCalendarPopup(True)
    widget.setDisplayFormat('dd/MM/yyyy')
    if fld.get('value') not in ('', None, 'null'):
        date = QDate.fromString(fld['value'].replace('/', '-'), 'yyyy-MM-dd')
        tools_qt.set_calendar(dlg, widget, date)
    else:
        widget.clear()

    real_name = widget.objectName()

    function_name = None
    func_params = ""
    if 'widgetfunction' in fld:
        if 'module' in fld['widgetfunction']:
            module = globals()[fld['widgetfunction']['module']]
        if 'functionName' in fld['widgetfunction']:
            if fld['widgetfunction']['functionName']:
                function_name = fld['widgetfunction']['functionName']
                exist = tools_os.check_python_function(module, function_name)
                if not exist:
                    msg = "widget {0} have associated function {1}, but {2} not exist"
                    msg_params = (real_name, function_name, function_name,)
                    tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, msg_params=msg_params)
                    return widget
                if 'parameters' in fld['widgetfunction']:
                    func_params = fld['widgetfunction']['parameters']
            else:
                msg = "Parameter button_function is null for button"
                tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=widget.objectName())

    kwargs['widget'] = widget
    kwargs['message_level'] = 1
    kwargs['function_name'] = function_name
    kwargs['func_params'] = func_params
    # if function_name:
    #     widget.dateChanged.connect(partial(getattr(module, function_name), **kwargs))

    btn_calendar = widget.findChild(QToolButton)
    btn_calendar.clicked.connect(partial(tools_qt.set_calendar_empty, widget))

    return widget


def set_typeahead(field, dialog, widget, completer, feature_id=None):

    # Check for the second behavior: 'comboIds' and 'comboNames' are required
    if 'comboIds' in field and 'comboNames' in field:
        # Populate completer rows from comboIds and comboNames
        rows = list(zip(field.get('comboIds', []), field.get('comboNames', [])))
        tools_qt.set_completer_rows(widget, rows)
        return widget

    # Check for the first behavior: 'queryText' and 'queryTextFilter' are required
    if field.get('queryText') is not None and 'queryTextFilter' in field:
        # Typeahead with queryText and queryTextFilter
        widget.setProperty('typeahead', True)
        model = QStandardItemModel()
        widget.textEdited.connect(partial(fill_typeahead, completer, model, field, dialog, widget, feature_id))
        return widget

    # If none of the conditions are met, log or display an appropriate message
    msg = "Typeahead '{0}' doesn't have neither a queryText nor comboIds/comboNames."
    msg_params = (field.get('columnname'),)
    tools_qgis.show_critical(msg, msg_params=msg_params)
    return widget


def fill_typeahead(completer, model, field, dialog, widget, feature_id=None):
    """ Set autocomplete of widget @table_object + "_id"
        getting id's from selected @table_object.
        WARNING: Each QLineEdit needs their own QCompleter and their own QStringListModel!!!
    """

    if not widget:
        return

    # Detect the active tab
    active_tab_name = ""
    tab_widget = dialog.findChild(QTabWidget)
    if tab_widget:
        active_tab_name = tab_widget.tabText(tab_widget.currentIndex())

    # Custom logic for the "Doc" tab
    if active_tab_name == "Doc":
        search_text = tools_qt.get_text(dialog, widget)
        query = f"SELECT name as id, name as idval FROM doc WHERE name ILIKE '%{search_text}%'"
        rows = tools_db.get_rows(query)

        if not rows:
            # Handle the case when no matching documents are found
            print("No matching documents found.")
            list_items = {}
        else:
            list_items = {row['id']: row['idval'] for row in rows}

        tools_qt.set_completer_object(completer, model, widget, list_items)
        return

    parent_id = ""
    if 'parentId' in field:
        parent_id = field["parentId"]

    # Get parentValue from widget or from feature_id if parentWidget not configured
    if dialog.findChild(QWidget, "tab_data_" + str(parent_id)):
        parent_value = tools_qt.get_text(dialog, "tab_data_" + str(parent_id))
    else:
        parent_value = feature_id

    extras = f'"queryText":"{field["queryText"]}"'
    extras += f', "queryTextFilter":"{field["queryTextFilter"]}"'
    extras += f', "parentId":"{parent_id}"'
    extras += f', "parentValue":"{parent_value}"'
    extras += f', "textToSearch":"{tools_qt.get_text(dialog, widget)}"'
    body = create_body(extras=extras)
    complet_list = execute_procedure('gw_fct_gettypeahead', body)
    if not complet_list or complet_list['status'] == 'Failed':
        return False

    tools_qt.set_completer_object(completer, model, widget, complet_list['body']['data'])


def set_data_type(field, widget):

    widget.setProperty('datatype', field['datatype'])
    return widget


def set_widget_size(widget, field):

    if field.get('widgetcontrols') and field['widgetcontrols'].get('widgetdim'):
        widget.setMaximumWidth(field['widgetcontrols']['widgetdim'])
        widget.setMinimumWidth(field['widgetcontrols']['widgetdim'])

    return widget


def set_widget_readonly(widget, readonly, from_apply=False):

    if type(widget) not in (QDoubleSpinBox, QLineEdit, QSpinBox, QTextEdit, GwHyperLinkLineEdit):
        return widget

    widget.setEnabled(True)
    widget.setReadOnly(readonly)
    if isinstance(widget, (QSpinBox, QDoubleSpinBox)) and widget.lineEdit():
        widget.lineEdit().setEnabled(True)

    if readonly:
        widget.setFocusPolicy(Qt.FocusPolicy.ClickFocus)
        widget.setStyleSheet("QWidget { background: rgb(242, 242, 242); color: rgb(110, 110, 110)}")
        if type(widget) is GwHyperLinkLineEdit:
            widget.setStyleSheet("QLineEdit { background: rgb(242, 242, 242); color:blue; text-decoration: underline; border: none;}")
    else:
        widget.setFocusPolicy(Qt.FocusPolicy.StrongFocus)
        if not from_apply:
            widget.setStyleSheet(None)

    return widget


def add_lineedit(field):
    """ Add widgets QLineEdit type """

    widget = QLineEdit()
    widget.setObjectName(field['widgetname'])

    if field.get('columnname') == 'password':
        widget.setEchoMode(QLineEdit.EchoMode.Password)
        widget.setClearButtonEnabled(True)

        # Add toggle password visibility action
        action = QAction(widget)
        action.setIcon(QIcon(os.path.join(lib_vars.plugin_dir, "icons", "dialogs", "142.png")))
        action.setCheckable(True)
        action.triggered.connect(partial(toggle_visibility, widget, action))
        widget.addAction(action, QLineEdit.ActionPosition.TrailingPosition)

    if 'widgetcontrols' in field and field['widgetcontrols']:
        widget.setProperty('widgetcontrols', field['widgetcontrols'])
    if 'columnname' in field:
        widget.setProperty('columnname', field['columnname'])
    if 'placeholder' in field:
        widget.setPlaceholderText(field['placeholder'])
    if 'value' in field:
        widget.setText(field['value'])
        widget.setProperty('value', field['value'])
    if 'tooltip' in field:
        widget.setToolTip(field['tooltip'])
    if 'iseditable' in field:
        set_widget_readonly(widget, not field['iseditable'])
    return widget


def toggle_visibility(widget, action, checked):
    if checked:
        widget.setEchoMode(QLineEdit.EchoMode.Normal)
        action.setIcon(QIcon(os.path.join(lib_vars.plugin_dir, "icons", "dialogs", "141.png")))
    else:
        widget.setEchoMode(QLineEdit.EchoMode.Password)
        action.setIcon(QIcon(os.path.join(lib_vars.plugin_dir, "icons", "dialogs", "142.png")))


def add_tableview(complet_result, field, dialog, module=sys.modules[__name__], class_self=None):
    """
    Add widgets QTableView type.
        Function called in -> widget.doubleClicked.connect(partial(getattr(module, function_name), **kwargs))
            module = tools_backend_calls open_selected_path(**kwargs):
            module = tools_backend_calls open_selected_element(**kwargs):

    """
    widget = QTableView()
    widget.setObjectName(field['widgetname'])
    widget.setSortingEnabled(True)

    if 'widgetcontrols' in field and field['widgetcontrols']:
        widget.setProperty('widgetcontrols', field['widgetcontrols'])
    if 'columnname' in field and field['columnname']:
        widget.setProperty('columnname', field['columnname'])
    if 'linkedobject' in field and field['linkedobject']:
        widget.setProperty('linkedobject', field['linkedobject'])

    function_name = 'no_function_asociated'
    real_name = widget.objectName()
    func_params = ""
    if 'data_' in widget.objectName():
        real_name = widget.objectName()[5:len(widget.objectName())]
    if 'widgetfunction' in field:
        if field['widgetfunction'].get('functionName') is not None:
            function_name = field['widgetfunction']['functionName']
            if 'module' in field['widgetfunction']:
                module = globals()[field['widgetfunction']['module']]
            exist = tools_os.check_python_function(module, function_name)
            if not exist:
                msg = "widget {0} have associated function {1}, but {2} not exist"
                msg_params = (real_name, function_name, function_name,)
                tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, msg_params=msg_params)
                return widget
            if 'parameters' in field['widgetfunction']:
                func_params = field['widgetfunction']['parameters']

    # noinspection PyUnresolvedReferences
    if function_name and function_name not in ('', 'None', 'no_function_asociated'):
        kwargs = {"qtable": widget, "func_params": func_params, "complet_result": complet_result, "dialog": dialog, "class": class_self}
        widget.doubleClicked.connect(partial(getattr(module, function_name), **kwargs))

    return widget


def add_frame(field, x=None):

    widget = QFrame()
    widget.setObjectName(f"{field['widgetname']}_{x}")
    if 'widgetcontrols' in field and field['widgetcontrols']:
        widget.setProperty('widgetcontrols', field['widgetcontrols'])
    if 'columnname' in field:
        widget.setProperty('columnname', field['columnname'])

    widget.setFrameShape(QFrame.Shape.HLine)
    widget.setFrameShadow(QFrame.Shadow.Sunken)

    return widget


def add_combo(field, dialog=None, complet_result=None, ignore_function=False, class_info=None):
    widget = CustomQComboBox()

    widget.setObjectName(field['widgetname'])
    if 'widgetcontrols' in field and field['widgetcontrols']:
        widget.setProperty('widgetcontrols', field['widgetcontrols'])
    if 'columnname' in field:
        widget.setProperty('columnname', field['columnname'])
    widget = fill_combo(widget, field)
    if 'selectedId' in field:
        widget.setProperty('selectedId', field['selectedId'])
    else:
        widget.setProperty('selectedId', None)
    if 'iseditable' in field:
        widget.setEnabled(bool(field['iseditable']))
        if not field['iseditable']:
            widget.setStyleSheet("QComboBox { background: rgb(242, 242, 242); color: rgb(100, 100, 100)}")

    if not ignore_function and 'widgetfunction' in field and field['widgetfunction']:
        widgetfunction = field['widgetfunction']
        functions = None
        if isinstance(widgetfunction, list):
            functions = widgetfunction
        else:
            if 'isfilter' in field and field['isfilter']:
                return widget
            functions = [widgetfunction]
        for f in functions:
            if 'isFilter' in f and f['isFilter']:
                continue
            columnname = field['columnname']
            parameters = f.get('parameters')

            kwargs = {"complet_result": complet_result, "dialog": dialog, "columnname": columnname, "widget": widget,
                      "func_params": parameters, "class": class_info}
            if 'module' in f:
                module = globals()[f['module']]
            else:
                module = tools_backend_calls
            function_name = f.get('functionName')
            if function_name is not None:
                if function_name:
                    exist = tools_os.check_python_function(module, function_name)
                    if not exist:
                        msg = "widget {0} has associated function {1}, but {2} not exist"
                        msg_params = (widget.property('widgetname'), function_name, function_name,)
                        tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, msg_params=msg_params)
                        return widget
                else:
                    msg = "Parameter functionName is null for button"
                    tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=widget.objectName())
            widget.currentIndexChanged.connect(partial(getattr(module, function_name), **kwargs))

    return widget


def add_multiple_option(field, dialog=None, complet_result=None, ignore_function=False, class_info=None):
    """Creates a filtered value relation widget with type-ahead search functionality.

    Args:
        field (dict): Field configuration containing widget properties
        dialog (QDialog, optional): Parent dialog. Defaults to None.
        complet_result (dict, optional): Additional completion data. Defaults to None.
        ignore_function (bool, optional): Whether to ignore widget functions. Defaults to False.
        class_info (dict, optional): Class information. Defaults to None.

    Returns:
        QWidget: Container widget with search box and filtered list
    """
    # Create list widget to show selected values
    widget = QListWidget()
    widget.setObjectName(field['widgetname'])

    # Setup type-ahead search with completer
    completer = QCompleter()
    type_ahead = add_lineedit(field)
    type_ahead.setPlaceholderText(tools_qt.tr("Type to search..."))

    # Configure completer with model and connect signals
    if completer:
        model = QStandardItemModel()
        completer.activated.connect(partial(add_item_multiple_option, completer, widget, type_ahead))
        make_list_multiple_option(completer, model, type_ahead, field, widget)
        type_ahead.textChanged.connect(partial(make_list_multiple_option, completer, model, type_ahead, field, widget))

    # Set widget properties from field config
    if 'widgetcontrols' in field and field['widgetcontrols']:
        widget.setProperty('widgetcontrols', field['widgetcontrols'])
    if 'columnname' in field:
        widget.setProperty('columnname', field['columnname'])

    # Fill widget with initial values and connect double-click to delete
    widget = fill_multiple_option(widget, field)
    widget.itemDoubleClicked.connect(partial(delete_item_on_doubleclick, widget))

    # Set selected ID property
    if 'selectedId' in field:
        widget.setProperty('selectedId', field['selectedId'])
    else:
        widget.setProperty('selectedId', None)

    # Configure editability
    if 'iseditable' in field:
        widget.setEnabled(bool(field['iseditable']))
        type_ahead.setEnabled(bool(field['iseditable']))

    # Create layout to hold both widgets
    layout = QVBoxLayout()
    layout.setContentsMargins(0, 0, 0, 0)
    layout.setSpacing(2)

    # Add type_ahead and widget to layout
    layout.addWidget(type_ahead)
    layout.addWidget(widget)

    # Create container widget to hold layout
    container = QWidget()
    container.setObjectName(field['widgetname'])
    container.setProperty('widgettype', 'multiple_option')
    container.setLayout(layout)

    return container


def make_list_multiple_option(completer, model, widget, field, list_widget):
    """
    Populate completer suggestions for multiple_option fields.
    IMPORTANT: do not refresh model while the completer popup is visible, or the first click is eaten.
    """

    # If user is selecting from popup, do not rebuild suggestions
    if completer.popup().isVisible():
        return

    # Also avoid running while we are programmatically changing text during add()
    if widget.property("_gw_setting_from_completer"):
        return

    value = widget.text()
    if not value:
        return

    result = None
    if field.get("queryText") and value is not None:
        if field.get("queryTextFilter"):
            sql = f"{field['queryText']} {field['queryTextFilter']}::text ilike '%{str(value)}%';"
        else:
            sql = f"{field['queryText']};"
        result = tools_db.get_rows(sql)

    if not result:
        return False

    existing_items = {list_widget.item(i).text() for i in range(list_widget.count())}

    display_list = []
    for data in result:
        if data[1] not in existing_items:
            display_list.append({"id": data[0], "idval": data[1]})

    tools_qt.set_completer_object(
        completer, model, widget,
        sorted(display_list, key=lambda x: x["idval"])
    )


def get_sequence_next_preview(seq_name: str, schema: str = None) -> int:
    """
    Returns a NON-reserving preview of the next sequence value.
    IMPORTANT: Not guaranteed under concurrency (other sessions may consume nextval()).
    """
    seq_ref = f'{schema}.{seq_name}' if schema else seq_name

    # increment_by is NOT a column in a sequence relation; only last_value/is_called are.
    sql = f"SELECT last_value, is_called FROM {seq_ref}"
    row = tools_db.get_row(sql)

    if not row:
        return 1

    # row can be tuple or dict-like depending on tools_db implementation
    try:
        last_value = int(row[0])
        is_called = bool(row[1])
    except Exception:
        last_value = int(row.get('last_value', 0))
        is_called = bool(row.get('is_called', False))

    next_id = last_value if not is_called else (last_value + 1)
    return max(next_id, 1)


def add_item_multiple_option(completer, widget, typeahead):
    """Add selected item from completer popup to QListWidget

    Args:
        completer (QCompleter): The completer containing selected item
        widget (QListWidget): The list widget to add item to
    """
    # Get currently selected row in completer popup
    row = completer.popup().currentIndex().row()
    if row == -1:  # No row selected
        return

    # Get key and display value from selected completer item
    _key = completer.completionModel().index(row, 0).data(Qt.ItemDataRole.UserRole)
    value = completer.completionModel().index(row, 0).data()

    # Create and configure new list widget item
    item = QListWidgetItem()
    item.setText(value)  # Set display text
    if _key:
        item.setData(Qt.ItemDataRole.UserRole, _key)  # Store key in user role
    widget.addItem(item)  # Add item to list widget

    typeahead.setText('')


def fill_multiple_option(widget, field, index_to_show=1, index_to_compare=0):
    """Fills a QListWidget with filtered value relation items.

    Args:
        widget (QListWidget): The list widget to populate
        field (dict): Dictionary containing field configuration and data
        index_to_show (int): Index of value to show in widget (default: 1)
        index_to_compare (int): Index to use for comparison (default: 0)

    Returns:
        QListWidget: The populated widget
    """

    # Clear widget contents while blocking signals to prevent unwanted triggers
    widget.blockSignals(True)
    widget.clear()
    widget.blockSignals(False)

    # Handle selected values if field has selectedId
    if 'selectedId' in field and field['selectedId'] is not None and field['selectedId'] != '':
        selected_values = []

        # Process combo IDs and names if both are present
        if 'comboIds' in field and 'comboNames' in field:
            combo_ids = field['comboIds']
            combo_names = field['comboNames']
            selected_id = field['selectedId']

            # Parse selected_id from JSON string to handle both single values and lists
            selected_id = json.loads(selected_id)

            # Handle list of selected IDs
            if isinstance(selected_id, list):
                for sid in selected_id:
                    if str(sid) in combo_ids:
                        idx = combo_ids.index(str(sid))
                        selected_values.append((combo_ids[idx], combo_names[idx]))
            # Handle single selected ID
            else:
                if selected_id in combo_ids:
                    idx = combo_ids.index(selected_id)
                    selected_values.append((combo_ids[idx], combo_names[idx]))

        # Update widget with selected values
        set_multiple_option_value(widget, selected_values)

    # Configure widget size policy to adjust to contents
    widget.setSizeAdjustPolicy(QAbstractScrollArea.SizeAdjustPolicy.AdjustToContents)
    return widget


def add_multiple_checkbox(field, dialog=None, complet_result=None, ignore_function=False, class_info=None):
    widget = QListWidget()

    widget.setObjectName(field['columnname'])
    if 'widgetcontrols' in field and field['widgetcontrols']:
        widget.setProperty('widgetcontrols', field['widgetcontrols'])
    if 'columnname' in field:
        widget.setProperty('columnname', field['columnname'])
    widget = fill_multiple_checkbox(widget, field)
    if 'selectedId' in field:
        widget.setProperty('selectedId', field['selectedId'])
    else:
        widget.setProperty('selectedId', None)
    if 'iseditable' in field:
        widget.setEnabled(bool(field['iseditable']))

    if not ignore_function and 'widgetfunction' in field and field['widgetfunction']:
        widgetfunction = field['widgetfunction']
        functions = None
        if isinstance(widgetfunction, list):
            functions = widgetfunction
        else:
            if 'isfilter' in field and field['isfilter']:
                return widget
            functions = [widgetfunction]
        for f in functions:
            if 'isFilter' in f and f['isFilter']:
                continue
            columnname = field['columnname']
            parameters = f.get('parameters')

            kwargs = {"complet_result": complet_result, "dialog": dialog, "columnname": columnname, "widget": widget,
                      "func_params": parameters, "class": class_info}
            if 'module' in f:
                module = globals()[f['module']]
            else:
                module = tools_backend_calls
            function_name = f.get('functionName')
            if function_name is not None:
                if function_name:
                    exist = tools_os.check_python_function(module, function_name)
                    if not exist:
                        msg = "widget {0} has associated function {1}, but {2} not exist"
                        msg_params = (widget.property('widgetname'), function_name, function_name,)
                        tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, msg_params=msg_params)
                        return widget
                else:
                    msg = "Parameter functionName is null for button"
                    tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=widget.objectName())
            widget.currentIndexChanged.connect(partial(getattr(module, function_name), **kwargs))

    return widget


def fill_multiple_checkbox(widget, field, index_to_show=1, index_to_compare=0):
    # check if index_to_show is in widgetcontrols, then assign new value
    if field.get('widgetcontrols') and 'index_to_show' in field.get('widgetcontrols'):
        index_to_show = field.get('widgetcontrols')['index_to_show']
    # Generate list of items to add into combo
    widget.blockSignals(True)
    widget.clear()
    widget.blockSignals(False)
    combolist = []
    combo_ids = field.get('comboIds')
    combo_names = field.get('comboNames')

    if 'comboIds' in field and 'comboNames' in field:
        if tools_os.set_boolean(field.get('isNullValue'), False):
            combolist.append(['', ''])
        for i in range(0, len(field['comboIds'])):
            elem = [combo_ids[i], combo_names[i]]
            combolist.append(elem)
    else:
        msg = "key 'comboIds' or/and comboNames not found WHERE widgetname='{0}' AND widgettype='{1}'"
        msg_params = (field['widgetname'], field['widgettype'],)
        tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, msg_params=msg_params)
    # Populate combo
    for record in combolist:
        item = QListWidgetItem()
        item.setText(record[index_to_show])
        item.setData(Qt.ItemDataRole.UserRole, record[index_to_compare])
        item.setFlags(item.flags() | Qt.ItemFlag.ItemIsUserCheckable)  # make it checkable
        item.setCheckState(Qt.CheckState.Unchecked)  # start unchecked
        widget.addItem(item)
    if 'selectedId' in field:
        set_multiple_checkbox_value(widget, field['selectedId'])
    # Set size policy for QListWidget - use setSizeAdjustPolicy instead
    widget.setSizeAdjustPolicy(QAbstractScrollArea.SizeAdjustPolicy.AdjustToContents)
    return widget


def set_multiple_option_value(listwidget, value):
    """
    Sets values in a filtered value relation list widget.

    Args:
        listwidget (QListWidget): The list widget to populate
        value (list): List of tuples containing (id, display_value) pairs to add

    Returns:
        bool: Always returns False

    The function takes a list widget and populates it with items from the value parameter.
    Each item shows the display value and stores the ID in the UserRole data.
    """
    # Return early if either widget or value is None
    if listwidget is None or value is None:
        return False

    # Add each value pair as a new item
    for id, val in value:
        item = QListWidgetItem()
        item.setText(val)  # Set display text
        item.setData(Qt.ItemDataRole.UserRole, id)  # Store ID in user role

        listwidget.addItem(item)
    return False


def delete_item_on_doubleclick(listwidget, item):
    """
    Deletes an item from a list widget when double-clicked.

    Args:
        listwidget (QListWidget): The list widget containing the item
        item (QListWidgetItem): The item to delete

    The function removes the specified item from the list widget if both parameters
    are valid and the item exists in the widget.
    """
    # Only proceed if we have valid widget and item
    if item is not None and listwidget is not None:
        row = listwidget.row(item)

    # Remove item if row is valid
    if row >= 0:
        listwidget.takeItem(row)


def set_multiple_checkbox_value(listwidget, value, add_new=True):
    """
    Set text to combobox populate with more than 1 item for row
        :param combo: QComboBox widget to manage
        :param value: element to show
        :param index: index to compare
        :param add_new: if True it will add the value even if it's not in the combo
    """

    if listwidget is None:
        return False
    try:
        value = json.loads(str(value))
    except Exception:
        return
    for i in range(0, listwidget.count()):
        elem = listwidget.item(i)
        for j in range(len(value)):
            if str(value[j]) == str(elem.data(Qt.ItemDataRole.UserRole)):
                listwidget.item(i).setCheckState(Qt.CheckState.Checked)

    # Add new value if @value not in combo
    if add_new and value not in ("", None, 'None', 'none', '-1', -1):
        for val in value:
            found = False
            for i in range(listwidget.count()):
                if str(val) == str(listwidget.item(i).data(Qt.ItemDataRole.UserRole)):
                    found = True
                    break

            if not found:
                item = QListWidgetItem()
                item.setText(f"({val})")
                item.setData(Qt.ItemDataRole.UserRole, val)
                item.setFlags(item.flags() | Qt.ItemFlag.ItemIsUserCheckable)
                item.setCheckState(Qt.CheckState.Checked)
                listwidget.addItem(item)
    return False


def fill_combo(widget, field, index_to_show=1, index_to_compare=0):
    # check if index_to_show is in widgetcontrols, then assign new value
    if field.get('widgetcontrols') and 'index_to_show' in field.get('widgetcontrols'):
        index_to_show = field.get('widgetcontrols')['index_to_show']
    # Generate list of items to add into combo
    widget.blockSignals(True)
    widget.clear()
    widget.blockSignals(False)
    combolist = []
    combo_ids = field.get('comboIds')
    combo_names = field.get('comboNames')

    if 'comboIds' in field and 'comboNames' in field:
        if tools_os.set_boolean(field.get('isNullValue'), False):
            combolist.append(['', ''])
        for i in range(0, len(field['comboIds'])):
            elem = [combo_ids[i], combo_names[i]]
            combolist.append(elem)
    else:
        msg = "key 'comboIds' or/and comboNames not found WHERE widgetname='{0}' AND widgettype='{1}'"
        msg_params = (field['widgetname'], field['widgettype'],)
        tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, msg_params=msg_params)
    # Populate combo
    for record in combolist:
        widget.addItem(record[index_to_show], record)
    if 'selectedId' in field:
        tools_qt.set_combo_value(widget, field['selectedId'], index_to_compare)
    return widget


def fill_combo_child(dialog, combo_child):

    if 'widgetname' in combo_child:
        child = dialog.findChild(QComboBox, str(combo_child['widgetname']))
        if child is not None:
            fill_combo(child, combo_child)


def manage_combo_child(dialog, combo_parent, combo_child):

    if 'widgetname' in combo_child:
        child = dialog.findChild(QComboBox, str(combo_child['widgetname']))

        if child:
            child.setEnabled(True)

            fill_combo_child(dialog, combo_child)
            if 'widgetcontrols' not in combo_child or not combo_child['widgetcontrols'] or \
                    'enableWhenParent' not in combo_child['widgetcontrols']:
                return

            combo_value = tools_qt.get_combo_value(dialog, combo_parent, 0)
            if (str(combo_value) in str(combo_child['widgetcontrols']['enableWhenParent'])) \
                    and (combo_value not in (None, '')):
                # The keepDisbled property is used to keep the edition enabled or disabled,
                # when we activate the layer and call the "enable_all" function
                child.setProperty('keepDisbled', False)
                child.setEnabled(True)
            else:
                child.setProperty('keepDisbled', True)
                child.setEnabled(False)


def fill_child(dialog, widget, action, feature_type=''):

    combo_parent = widget.objectName()
    combo_id = tools_qt.get_combo_value(dialog, widget)
    # TODO cambiar por gw_fct_getchilds then unified with get_child if posible
    json_result = execute_procedure('gw_fct_getcombochilds', f"'{action}' ,'' ,'' ,'{combo_parent}', '{combo_id}','{feature_type}'")
    if json_result is None:
        return

    for combo_child in json_result['fields']:
        if combo_child is not None:
            fill_combo_child(dialog, combo_child)


def get_expression_filter(feature_type, list_ids=None, layers=None):
    """ Set an expression filter with the contents of the list.
        Set a model with selected filter. Attach that model to selected table
    """

    list_ids = list_ids[feature_type]
    if len(list_ids) == 0:
        return None

    field_id = feature_type + "_id"

    # Set expression filter with features in the list
    expr_filter = field_id + " IN ("
    for i in range(len(list_ids)):
        expr_filter += f"'{list_ids[i]}', "
    expr_filter = expr_filter[:-2] + ")"

    # Check expression
    (is_valid, expr) = tools_qt.check_expression_filter(expr_filter)
    if not is_valid:
        return None

    # Select features of layers applying @expr
    # tools_qgis.select_features_by_ids(feature_type, expr, layers=layers)

    return expr_filter


def get_actions_from_json(json_result, sql):
    """
    Manage options for layers (active, visible, zoom and indexing)
    :param json_result: Json result of a query (Json)
    :param sql: query executed (String)
    :return: None
    """

    try:
        actions = json_result['body']['python_actions']
    except KeyError:
        return
    try:
        for action in actions:
            try:
                function_name = action['funcName']
                params = action['params']
                params['json_result'] = json_result
                getattr(tools_backend_calls, f"{function_name}")(**params)
            except AttributeError as e:
                # If function_name not exist as python function
                msg = "Exception error: {0}"
                msg_params = (e,)
                tools_log.log_warning(msg, msg_params=msg_params)
            except Exception as e:
                msg = "{0}: {1}"
                msg_params = (type(e).__name__, e,)
                tools_log.log_debug(msg, msg_params=msg_params)
    except Exception as e:
        msg = "{0}: {1}"
        msg_params = (type(e).__name__, e,)
        tools_qt.manage_exception(None, msg, sql, lib_vars.schema_name, msg_params=msg_params)


def exec_pg_function(function_name, parameters=None, commit=True, schema_name=None, log_sql=False, rubber_band=None,
        aux_conn=None, is_thread=False, check_function=True):
    """ Manage execution of database function @function_name
        If execution failed, execute it again up to the value indicated in parameter 'exec_procedure_max_retries'
    """

    # Define dictionary with results
    dict_result = {}
    status = False
    function_failed = False
    json_result = None
    complet_result = None

    attempt = 0
    while json_result is None and attempt < global_vars.exec_procedure_max_retries:
        attempt += 1
        if attempt == 1:
            msg = "Starting process..."
            tools_log.log_info(msg)
        else:
            msg = "Retrieving process ({0}/{1})..."
            msg_params = (attempt, global_vars.exec_procedure_max_retries)
            tools_log.log_info(msg, msg_params=msg_params)
        json_result = execute_procedure(function_name, parameters, schema_name, commit, log_sql, rubber_band, aux_conn,
            is_thread, check_function)
        complet_result = json_result
        if json_result is None or not json_result:
            function_failed = True
        elif 'status' in json_result:
            if json_result['status'] == 'Failed':
                tools_log.log_warning(json_result)
                function_failed = True
            else:
                status = True
            break

    dict_result['status'] = status
    dict_result['function_failed'] = function_failed
    dict_result['json_result'] = json_result
    dict_result['complet_result'] = complet_result

    return dict_result


def execute_procedure(function_name, parameters=None, schema_name=None, commit=True, log_sql=True, rubber_band=None,
        aux_conn=None, is_thread=False, check_function=True):
    """ Manage execution database function
    :param function_name: Name of function to call (text)
    :param parameters: Parameters for function (json) or (query parameters)
    :param commit: Commit sql (bool)
    :param log_sql: Show query in qgis log (bool)
    :param aux_conn: Auxiliar connection to database used by threads (psycopg2.connection)
    :return: Response of the function executed (json)
    """

    if aux_conn is None and not is_thread:
        check_db_connection()

    # Check if function exists
    if check_function:
        row = tools_db.check_function(function_name, schema_name, commit, aux_conn=aux_conn, is_thread=is_thread)
        if row in (None, ''):
            msg = "Function not found in database"
            if not is_thread:
                tools_qgis.show_warning(msg, parameter=function_name)
            tools_log.log_warning(msg)
            return None

    # Manage schema_name and parameters
    if schema_name:
        sql = f"SELECT {schema_name}.{function_name}("
    elif schema_name is None and lib_vars.schema_name:
        sql = f"SELECT {lib_vars.schema_name}.{function_name}("
    else:
        sql = f"SELECT {function_name}("
    if type(parameters) is dict:
        parameters_dict = parameters
        parameters = create_body(body=parameters)
    if parameters:
        sql += f"{parameters}"
    sql += ");"

    # Get log_sql for developers
    dev_log_sql = get_config_parser('log', 'log_sql', "user", "init", False)
    if dev_log_sql in ("True", "False"):
        log_sql = tools_os.set_boolean(dev_log_sql)

    # Execute database function
    row = tools_db.get_row(sql, commit=commit, log_sql=log_sql, aux_conn=aux_conn, is_thread=is_thread)
    if not row or not row[0]:
        msg = "Function error: {0}"
        msg_params = (function_name,)
        tools_log.log_warning(msg, msg_params=msg_params)
        tools_log.log_warning(sql)
        return None

    # Get json result
    json_result = row[0]
    if log_sql:
        title = "SERVER RESPONSE"
        tools_log.log_db(json_result, header=title)

    # All functions called from python should return 'status', if not, something has probably failed in postrgres
    if 'status' not in json_result:
        manage_json_exception(json_result, sql, is_thread=is_thread)
        return False

    # If failed, manage exception
    if json_result.get('status') == 'Failed':
        manage_json_exception(json_result, sql, is_thread=is_thread)
        return json_result

    try:
        if json_result["body"]["feature"]["geometry"] and lib_vars.data_epsg != lib_vars.project_epsg:
            json_result = manage_json_geometry(json_result)
    except Exception:
        pass

    if not is_thread:
        manage_json_response(json_result, sql, rubber_band)

    try:
        if not isinstance(json_result['body']['data'], dict):
            raise KeyError
        answer = tools_qt.show_question(json_result['body']['data']['question']['message'])
        if not answer:
            cancel_action = json_result['body']['data']['question'].get('cancel_action')
            if cancel_action is not None:
                parameters_dict['data'] = {}
                parameters_dict['data'][cancel_action] = True
            else:
                return {"status": "Accepted", "message": {"level": 1, "text": "Action canceled"}}
        else:
            accept_action = json_result['body']['data']['question'].get('accept_action')
            if accept_action:
                parameters_dict['data'][accept_action] = True
        parameters = create_body(body=parameters_dict)
        execute_procedure('gw_fct_epa2data', parameters)
    except KeyError:
        pass
    return json_result


def manage_json_geometry(json_result):

    # Set QgsCoordinateReferenceSystem
    data_epsg = QgsCoordinateReferenceSystem(str(lib_vars.data_epsg))
    project_epsg = QgsCoordinateReferenceSystem(str(lib_vars.project_epsg))

    tform = QgsCoordinateTransform(data_epsg, project_epsg, QgsProject.instance())

    list_coord = re.search(r'\((.*)\)', str(json_result['body']['feature']['geometry']['st_astext']))
    points = tools_qgis.get_geometry_vertex(list_coord)

    for point in points:
        if str(lib_vars.data_epsg) == '2052' and str(lib_vars.project_epsg) == '102566':
            clear_list = list_coord.group(1)
            updated_list = list_coord.group(1).replace('-', '').replace(' ', ' -')
            json_result['body']['feature']['geometry']['st_astext'] = json_result['body']['feature']['geometry']['st_astext'].replace(clear_list, updated_list)
        elif str(lib_vars.data_epsg) != str(lib_vars.project_epsg):
            new_coords = tform.transform(point)
            json_result['body']['feature']['geometry']['st_astext'] = json_result['body']['feature']['geometry']['st_astext'].replace(str(point.x()), str(new_coords.x()))
            json_result['body']['feature']['geometry']['st_astext'] = json_result['body']['feature']['geometry']['st_astext'].replace(str(point.y()), str(new_coords.y()))

    return json_result


def manage_json_response(complet_result, sql=None, rubber_band=None):

    if complet_result not in (None, False):
        try:
            manage_json_return(complet_result, sql, rubber_band)
            manage_layer_manager(complet_result)
            get_actions_from_json(complet_result, sql)
        except Exception:
            pass


def manage_json_exception(json_result, sql=None, stack_level=2, stack_level_increase=0, is_thread=False):
    """ Manage exception in JSON database queries and show information to the user """

    try:

        if 'message' in json_result:
            level = 1
            if 'level' in json_result['message']:
                level = int(json_result['message']['level'])
            if 'text' in json_result['message']:
                msg = json_result['message']['text']
            else:
                msg = json_result['message']

            # Show exception message only if we are not in a task process
            if len(lib_vars.session_vars['threads']) == 0:
                level = Qgis.MessageLevel(level)
                if 'SQLCONTEXT' in json_result:
                    tools_qgis.show_message(msg, level, sqlcontext=json_result['SQLCONTEXT'])
                else:
                    tools_qgis.show_message(msg, level)
            else:
                tools_log.log_info(msg)

        else:

            stack_level += stack_level_increase
            if stack_level >= len(inspect.stack()):
                stack_level = len(inspect.stack()) - 1
            module_path = inspect.stack()[stack_level][1]
            file_name = tools_os.get_relative_path(module_path, 2)
            function_line = inspect.stack()[stack_level][2]
            function_name = inspect.stack()[stack_level][3]

            # Set exception message details
            title = "Database execution failed"
            msg = ""
            msg += f'''{tools_qt.tr('File name')}: {file_name}\n'''
            msg += f'''{tools_qt.tr('Function name')}: {function_name}\n'''
            msg += f'''{tools_qt.tr('Line number')}: {function_line}\n'''
            if 'SQLERR' in json_result:
                msg += f'''{tools_qt.tr('Detail')}: {json_result['SQLERR']}\n'''
            elif 'NOSQLERR' in json_result:
                msg += f'''{tools_qt.tr('Detail')}: {json_result['NOSQLERR']}\n'''
            if 'SQLCONTEXT' in json_result:
                msg += f'''{tools_qt.tr('Context')}: {json_result['SQLCONTEXT']}\n'''
            if sql:
                msg += f"SQL: {sql}\n"
            if 'MSGERR' in json_result:
                msg += f'''{tools_qt.tr('Message error')}: {json_result['MSGERR']}'''
            lib_vars.session_vars['last_error_msg'] = msg

            if is_thread:
                return

            tools_log.log_warning(msg, stack_level_increase=2)
            # Show exception message only if we are not in a task process
            if len(lib_vars.session_vars['threads']) == 0:
                tools_qt.show_exception_message(title, msg)

    except Exception:
        title = "Unhandled Error"
        msg = "Unhandled Error"
        tools_qt.manage_exception(title)


def manage_json_return(json_result, sql, rubber_band=None, i=None):  # noqa: C901
    """
    Manage options for layers (active, visible, zoom and indexing)
    :param json_result: Json result of a query (Json)
    :param sql: query executed (String)
    :return: None
    """

    try:
        return_manager = json_result['body']['returnManager']
    except KeyError:
        return_manager = {
            "style": {
                "point": {
                    "style": "unique", "values": {
                        "width": 3, "color": [255, 1, 1], "transparency": 0.5
                    }
                },
                "line": {
                    "style": "unique", "values": {
                        "width": 3, "color": [255, 1, 1], "transparency": 0.5
                    }
                },
                "polygon": {
                    "style": "unique", "values": {
                        "width": 3, "color": [255, 1, 1], "transparency": 0.5
                    }
                }
            }
        }

    try:
        margin = None
        opacity = 100
        i = 0

        if 'zoom' in return_manager and 'margin' in return_manager['zoom']:
            margin = return_manager['zoom']['margin']

        if 'style' in return_manager and 'ruberband' in return_manager['style']:
            width = 3
            color = QColor(255, 0, 0, 125)
            if 'transparency' in return_manager['style']['ruberband']:
                opacity = return_manager['style']['ruberband']['transparency'] * 255
            if 'color' in return_manager['style']['ruberband']:
                color = return_manager['style']['ruberband']['color']
                color = QColor(int(color[0]), int(color[1]), int(color[2]), int(opacity))
            if 'width' in return_manager['style']['ruberband']:
                width = return_manager['style']['ruberband']['width']
            draw_by_json(json_result, rubber_band, margin, color=color, width=width)

        else:
            if not json_result or not json_result.get('body'):
                return
            if not json_result['body'].get('data') or type(json_result['body'].get('data')) is list:
                return
            lista = []
            for group in list(json_result['body']['data'].items()):
                if group[0].lower() in ('point', 'line', 'polygon'):
                    if type(group[1]) is not list:
                            lista.append(group)
                    else:
                        for layer in group[1]:
                            lista.append((group[0], layer))

            for key, value in lista:
                # Remove the layer if it exists
                layer_name = f'{key}'
                if value.get('layerName'):
                    layer_name = value['layerName']
                tools_qgis.remove_layer(custom_properties={"gw_id": layer_name}, group_name='GW Temporal Layers')

                if 'features' not in value:
                    continue
                if value['features'] is None or len(value['features']) == 0:
                    continue

                # Get values for create and populate layer
                geojson_str = json.dumps(value)
                timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
                file_name = f"{layer_name}_{timestamp}"
                vsipath = f"/vsimem/{file_name}.geojson"
                gdal.FileFromMemBuffer(vsipath, geojson_str)
                v_layer = QgsVectorLayer(vsipath, layer_name, 'ogr')
                if not v_layer.crs().isValid():
                    v_layer.setCrs(QgsCoordinateReferenceSystem('EPSG:4326'))
                v_layer.updateExtents()
                geometry_type = v_layer.geometryType()
                tools_qgis.add_layer_to_toc(v_layer, group='GW Temporal Layers', create_groups=True, custom_properties={"gw_id": layer_name})

                # Increase iterator
                i = i + 1

                # Get values for set layer style
                opacity = 100

                style_type = return_manager['style']

                if return_manager['style'].get(layer_name):
                    return_manager_style = style_type[layer_name]
                else:
                    return_manager_style = style_type[key]

                if 'style' in return_manager and 'values' in return_manager_style:
                    if 'transparency' in return_manager_style['values']:
                        opacity = return_manager_style['values']['transparency']
                if return_manager_style['style'] == 'categorized':
                    if 'transparency' in return_manager_style:
                        opacity = return_manager_style['transparency']
                    color_values = {}
                    for item in return_manager_style.get('values', []):
                        color = QColor(item['color'][0], item['color'][1], item['color'][2], int(opacity * 255))
                        color_values[item['id']] = {
                            'color': color,
                            'legend_id': item.get('legend_id')
                        }
                    cat_field = str(return_manager_style['field'])
                    size = return_manager_style['width'] if return_manager_style.get('width') else 2
                    tools_qgis.set_layer_categoryze(v_layer, cat_field, size, color_values, opacity=int(opacity * 255))

                elif return_manager_style['style'] == 'random':
                    size = style_type['width'] if style_type.get('width') else 2
                    if geometry_type == 'Point':
                        v_layer.renderer().symbol().setSize(size)
                    elif geometry_type in ('Polygon', 'Multipolygon'):
                        pass
                    else:
                        v_layer.renderer().symbol().setWidth(size)
                    v_layer.renderer().symbol().setOpacity(opacity)

                elif return_manager_style['style'] == 'qml':
                    # Save current layer custom properties and remove them to avoid QML overwrite them
                    custom_properties = {}
                    layer_custom_properties = v_layer.customPropertyKeys()
                    for cp_key in layer_custom_properties:
                        custom_properties[cp_key] = v_layer.customProperty(cp_key)

                    style_id = return_manager_style['id']
                    extras = f'"style_id":"{style_id}", "layername":"{layer_name}"'
                    body = create_body(extras=extras)
                    style = execute_procedure('gw_fct_getstyle', body)
                    if not style.get('body').get('styles'):
                        extras = f'"style_id":"{style_id}", "layername":"{key}"'
                        body = create_body(extras=extras)
                        style = execute_procedure('gw_fct_getstyle', body)
                    if style is None or style.get('status') == 'Failed':
                        return
                    if 'styles' in style['body']:
                        for style_name, qml in style['body']['styles'].items():
                            if qml is None:
                                continue

                            valid_qml, error_message = validate_qml(qml)
                            if not valid_qml:
                                msg = "The QML file is invalid."
                                tools_qgis.show_warning(msg, parameter=error_message)
                            else:
                                style_manager = v_layer.styleManager()

                                default_style_name = tools_qt.tr('default', context_name='QgsMapLayerStyleManager')
                                # add style with new name
                                style_manager.renameStyle(default_style_name, style_name)
                                # set new style as current
                                style_manager.setCurrentStyle(style_name)
                                tools_qgis.create_qml(v_layer, qml)

                    # Restore actual custom properties
                    for cp_key, cp_value in custom_properties.items():
                        v_layer.setCustomProperty(cp_key, cp_value)

                elif return_manager_style['style'] == 'unique':
                    color = return_manager_style['values']['color']
                    size = style_type['width'] if style_type.get('width') else 2
                    color = QColor(color[0], color[1], color[2])
                    if key == 'point':
                        v_layer.renderer().symbol().setSize(size)
                    elif key == 'line':
                        v_layer.renderer().symbol().setWidth(size)
                    elif key == 'polygon':
                        pass
                    v_layer.renderer().symbol().setColor(color)
                    v_layer.renderer().symbol().setOpacity(opacity)

                global_vars.iface.layerTreeView().refreshLayerSymbology(v_layer.id())
                if margin:
                    tools_qgis.set_margin(v_layer, margin)

    except Exception as e:
        msg = "{0}: {1}"
        msg_params = (type(e).__name__, e,)
        tools_qt.manage_exception(None, msg, sql, lib_vars.schema_name, msg_params=msg_params)
    finally:
        # Clean any broken temporal layers (left with no data)
        tools_qgis.clean_layer_group_from_toc('GW Temporal Layers')


def get_rows_by_feature_type(class_object, dialog, table_object, feature_type, feature_id=None, feature_idname=None,
                             expr_filter=None, table_separator="_x_", columns_to_show=None):
    """ Get records of @feature_type associated to selected @table_object """

    if feature_id is None:
        feature_id = tools_qt.get_text(dialog, table_object + "_id")

    if feature_idname is None:
        feature_idname = f"{table_object}_id"

    table_relation = table_object + table_separator + feature_type
    widget_name = "tbl_" + table_relation

    # If feature_id is None or 'null', try to get the value of a specific tableview column
    if feature_id is None or feature_id == 'null':
        # Try to get feature_id from the selected row in the relevant tableview
        widget = tools_qt.get_widget(dialog, widget_name)
        if widget:
            selected_rows = widget.selectionModel().selectedRows() if widget.selectionModel() else []
            if selected_rows:
                selected_row_index = selected_rows[0]
                model = widget.model()
                if model:
                    # Try to get the column index by the expected id column
                    col_index = tools_qt.get_col_index_by_col_name(widget, f"{feature_type}_id")
                    if col_index != -1:
                        feature_id = model.data(model.index(selected_row_index.row(), col_index))

    exists = tools_db.check_table(table_relation)
    if not exists:
        exists = tools_db.check_view(table_relation)
        if not exists:
            msg = "Not found: {0}"
            msg_params = (table_relation,)
            tools_log.log_info(msg, msg_params=msg_params)
            return

    if expr_filter is None:
        sql = (f"SELECT {feature_type}_id "
            f"FROM {table_relation} "
            f"WHERE {feature_idname} = '{feature_id}'")
        rows = tools_db.get_rows(sql, log_info=False)
        if rows:
            for row in rows:
                class_object.rel_list_ids[feature_type].append(str(row[0]))
                class_object.rel_ids.append(str(row[0]))
        expr_filter = get_expression_filter(feature_type, class_object.rel_list_ids, class_object.rel_layers)

    table_name = f"{class_object.schema_name}.{feature_type}"
    tools_qt.set_table_model(dialog, widget_name, table_name, expr_filter, columns_to_show)


def load_tableview_feature_end(class_object, dialog, table_object, feature_type, feature_id=None, feature_idname=None, expr_filter=None):
    """ Reload QtableView """

    if feature_id is None:
        feature_id = tools_qt.get_text(dialog, table_object + "_id")

    if feature_idname is None:
        feature_idname = f"{feature_type}_id"

    if feature_type == 'element':
        table_relation = "v_ui_element"
    else:
        table_relation = f"ve_{feature_type}"
    widget_name = f"tbl_{table_object}_x_{feature_type}"

    exists = tools_db.check_table(table_relation)
    if not exists:
        exists = tools_db.check_view(table_relation)
    if not exists:
        tools_log.log_info(f"Not found: {table_relation}")
        return

    if expr_filter is None:
        expr_filter = get_expression_filter(feature_type, class_object.rel_list_ids, class_object.rel_layers)

    table_name = f"{class_object.schema_name}.{feature_type}"
    columns_to_show = [f"{feature_type}_id", "code", "sys_code", f"{feature_type}_type", "sector_id", "state", "state_type", "expl_id", "descript"]
    tools_qt.set_table_model(dialog, widget_name, table_name, expr_filter, columns_to_show)


def get_project_type(schemaname=None):
    """ Get project type from table 'sys_version' """

    project_type = None
    if schemaname is None and lib_vars.schema_name is None:
        return None
    elif schemaname in (None, 'null', ''):
        schemaname = lib_vars.schema_name

    tablename = "sys_version"
    exists = tools_db.check_table(tablename, schemaname)
    if not exists:
        msg = "Table not found"
        tools_qgis.show_warning(msg, parameter=tablename)
        return None

    sql = f"SELECT lower(project_type) FROM {schemaname}.{tablename} ORDER BY id DESC LIMIT 1"
    row = tools_db.get_row(sql)
    if row:
        project_type = row[0]

    return project_type


def get_project_info(schemaname=None, order_direction="DESC"):
    """ Get project information from table 'sys_version' """

    project_info_dict = None
    if schemaname is None and lib_vars.schema_name is None:
        return None
    elif schemaname in (None, 'null', ''):
        schemaname = lib_vars.schema_name

    tablename = "sys_version"
    exists = tools_db.check_table(tablename, schemaname)
    if not exists:
        msg = "Table not found"
        tools_qgis.show_warning(msg, parameter=tablename)
        return None

    has_addparam = tools_db.check_column(tablename, 'addparam', schemaname)
    creation_profile_sql = (
        "addparam -> 'environment' ->> 'creation_profile'"
        if has_addparam else "NULL"
    )
    sql = (f"SELECT lower(project_type), epsg, giswater, language, date, "
           f"{creation_profile_sql} "
           f"FROM {schemaname}.{tablename} "
           f"ORDER BY id {order_direction} LIMIT 1")
    row = tools_db.get_row(sql)
    if row:
        project_info_dict = {'project_type': row[0],
                             'project_epsg': row[1],
                             'project_version': row[2],
                             'project_language': row[3],
                             'project_date': row[4],
                             'creation_profile': row[5],
                             }

    return project_info_dict


def get_layers_from_feature_type(feature_type):
    """ Get layers of the group @feature_type """

    list_items = []
    sql = (f"SELECT child_layer "
           f"FROM {lib_vars.schema_name}.cat_feature "
           f"WHERE upper(feature_type) = '{feature_type.upper()}' "
           f"UNION SELECT DISTINCT parent_layer "
           f"FROM {lib_vars.schema_name}.cat_feature "
           f"WHERE upper(feature_type) = '{feature_type.upper()}';")
    rows = tools_db.get_rows(sql)
    if rows:
        for row in rows:
            layer = tools_qgis.get_layer_by_tablename(row[0])
            if layer:
                list_items.append(layer)

    return list_items


def get_role_permissions(qgis_project_role):

    role_admin = False
    role_plan = False
    role_edit = False
    role_om = False
    role_epa = False
    role_basic = False

    role_system = tools_db.check_role_user("role_system")
    if not role_system:
        role_admin = tools_db.check_role_user("role_admin")
        if not role_admin:
            role_plan = tools_db.check_role_user("role_plan")
            if not role_plan:
                role_epa = tools_db.check_role_user("role_epa")
                if not role_epa:
                    role_edit = tools_db.check_role_user("role_edit")
                    if not role_edit:
                        role_om = tools_db.check_role_user("role_om")
                        if not role_om:
                            role_basic = tools_db.check_role_user("role_basic")

    if role_basic or qgis_project_role == 'role_basic':
        return 'role_basic'
    elif role_om or qgis_project_role == 'role_om':
        return 'role_om'
    elif role_edit or qgis_project_role == 'role_edit':
        return 'role_edit'
    elif role_epa or qgis_project_role == 'role_epa':
        return 'role_epa'
    elif role_plan or qgis_project_role == 'role_plan':
        return 'role_plan'
    elif role_admin or qgis_project_role == 'role_admin':
        return 'role_admin'
    elif role_system or qgis_project_role == 'role_system':
        return 'role_system'
    else:
        return 'role_basic'


def get_config_value(parameter='', columns='value', table='config_param_user', sql_added=None, log_info=True, schema_name=None):

    if schema_name is None:
        schema_name = lib_vars.schema_name

    if not check_db_connection():
        return None
    if not tools_db.check_table(table):
        msg = "Table not found: {0}"
        msg_params = (table,)
        tools_log.log_warning(msg, msg_params=msg_params)
        return None

    sql = f"SELECT {columns} FROM {table} WHERE parameter = '{parameter}' "
    if sql_added:
        sql += sql_added
    if table == 'config_param_user':
        sql += " AND cur_user = current_user"
    sql += ";"
    row = tools_db.get_row(sql, log_info=log_info)
    return row


def parse_currency(value_str, currency_config=None):
    """
    Parse a formatted currency string back to a float.

    Args:
        value_str: Formatted currency string like "€1.000.000,25" or "$1,000,000.25"
        currency_config: Dict with currency config. If None, fetches from DB.

    Returns:
        Float value
    """

    if currency_config is None:
        try:
            row = get_config_value(parameter='admin_currency', columns='value::text', table='config_param_system')
            if row:
                currency_config = json.loads(row[0])
        except Exception:
            currency_config = {"symbol": "$", "separator": ",", "decimals": True}

    # Remove all currency symbols and spaces
    cleaned = str(value_str).strip()
    for symbol in ['€', '$', '₡', '£', '¥', ' ']:
        cleaned = cleaned.replace(symbol, '')

    # Get separator config
    thousands_sep = currency_config.get('separator', ',')
    decimal_sep = ',' if thousands_sep == '.' else '.'

    # Remove thousands separator and replace decimal separator with dot
    cleaned = cleaned.replace(thousands_sep, '')
    cleaned = cleaned.replace(decimal_sep, '.')

    try:
        return float(cleaned)
    except (ValueError, TypeError):
        return 0.0


def format_currency(value, currency_config=None, with_symbol=True):
    """
    Format a number as currency using admin_currency configuration.

    Args:
        value: The numeric value to format
        currency_config: Dict with currency config. If None, fetches from DB.
                        Expected keys: symbol, separator, decimals

    Returns:
        Formatted string like "₡1,000,000.25" or "€1.000.000,25"

    Examples:
        {"symbol":"$", "separator":",", "decimals":true} -> $1,000,000.25
        {"symbol":"€", "separator":".", "decimals":true} -> €1.000.000,25
        {"symbol":"₡", "separator":",", "decimals":false} -> ₡1,000,000
    """

    if currency_config is None:
        try:
            row = get_config_value(parameter='admin_currency', columns='value::text', table='config_param_system')
            if row:
                currency_config = json.loads(row[0])
        except Exception:
            # Fallback to default
            currency_config = {"symbol": "$", "separator": ",", "decimals": True}

    # Extract config
    symbol = currency_config.get('symbol', '$')
    thousands_sep = currency_config.get('separator', ',')
    show_decimals = currency_config.get('decimals', True)

    # Determine decimal separator (opposite of thousands separator)
    decimal_sep = ',' if thousands_sep == '.' else '.'

    # Convert to float
    try:
        num_value = float(value)
    except (ValueError, TypeError):
        return f"{symbol}0"

    # Format the number
    if show_decimals:
        # Split into integer and decimal parts
        int_part = int(abs(num_value))
        decimal_part = abs(num_value) - int_part

        # Format integer part with thousands separator
        int_str = f"{int_part:,}".replace(',', thousands_sep)

        # Format decimal part (always 2 decimal places)
        decimal_str = f"{decimal_part:.2f}"[2:]  # Get digits after "0."

        # Combine
        formatted = f"{'-' if num_value < 0 else ''}{int_str}{decimal_sep}{decimal_str}"
    else:
        # No decimals, round to integer
        int_value = int(round(num_value))
        formatted = f"{int_value:,}".replace(',', thousands_sep)
        if num_value < 0 and not formatted.startswith('-'):
            formatted = '-' + formatted

    return f"{symbol}{formatted}" if with_symbol else formatted


def manage_layer_manager(json_result, sql=None):
    """
    Manage options for layers (active, visible, zoom and indexing)
    :param json_result: Json result of a query (Json)
    :param sql: query executed (String)
    :return: None
    """

    try:
        layermanager = json_result['body']['layerManager']
    except KeyError:
        return

    try:

        # force visible and in case of does not exits, load it
        if 'visible' in layermanager:
            for lyr in layermanager['visible']:
                layer_name = [key for key in lyr][0]
                layer = tools_qgis.get_layer_by_tablename(layer_name)
                if layer is None:
                    the_geom = lyr[layer_name]['geom_field']
                    field_id = lyr[layer_name]['pkey_field']
                    if lyr[layer_name]['group_layer'] is not None:
                        group = lyr[layer_name]['group_layer']
                    else:
                        group = "GW Layers"
                    add_layer_database(layer_name, the_geom, field_id, group=group, alias=lyr.get(layer_name).get('alias'))
                tools_qgis.set_layer_visible(layer)

        # force reload dataProvider in order to reindex.
        if 'index' in layermanager:
            for lyr in layermanager['index']:
                layer_name = [key for key in lyr][0]
                layer = tools_qgis.get_layer_by_tablename(layer_name)
                if layer:
                    tools_qgis.set_layer_index(layer)

        # Set active
        if 'active' in layermanager:
            layer = tools_qgis.get_layer_by_tablename(layermanager['active'])
            if layer:
                global_vars.iface.setActiveLayer(layer)

        # Set zoom to extent with a margin
        if 'zoom' in layermanager:
            layer = tools_qgis.get_layer_by_tablename(layermanager['zoom']['layer'])
            if layer:
                prev_layer = global_vars.iface.activeLayer()
                global_vars.iface.setActiveLayer(layer)
                global_vars.iface.zoomToActiveLayer()
                margin = layermanager['zoom']['margin']
                tools_qgis.set_margin(layer, margin)
                if prev_layer:
                    global_vars.iface.setActiveLayer(prev_layer)

    except Exception as e:
        msg = "{0}: {1}"
        msg_params = (type(e).__name__, e,)
        tools_qt.manage_exception(None, msg, sql, lib_vars.schema_name, msg_params=msg_params)


def zoom_to_feature_by_id(tablename: str, idname: str, _id, margin: float = 15):
    """ Zoom to feature by id or list of ids """

    layer = tools_qgis.get_layer_by_tablename(tablename)
    if not layer:
        return

    if isinstance(_id, list):
        expr_filter = f"""{idname} IN ({', '.join([f"'{i}'" for i in _id])})"""
    else:
        expr_filter = f"{idname} = '{_id}'"

    request = QgsFeatureRequest().setFilterExpression(expr_filter)
    features = layer.getFeatures(request)

    bbox = None
    for feature in features:
        if bbox is None:
            bbox = feature.geometry().boundingBox()
        else:
            bbox.combineExtentWith(feature.geometry().boundingBox())

    if bbox:
        tools_qgis.zoom_to_rectangle(bbox.xMinimum() - margin, bbox.yMinimum() - margin, bbox.xMaximum() + margin, bbox.yMaximum() + margin)


def selection_init(class_object, dialog, table_object, selection_mode: GwSelectionMode = GwSelectionMode.DEFAULT,
                   tool_type="rectangle"):
    """ Set canvas map tool to an instance of selection tool based on tool_type """
    try:
        class_object.rel_feature_type = get_signal_change_tab(dialog, excluded_layers=class_object.excluded_layers)
    except AttributeError as e:
        # In case the dialog has no tab
        tools_log.log_info(f"selection_init: {e}")
    if class_object.rel_feature_type in ('all', None):
        class_object.rel_feature_type = 'arc'

    # Campaign-only: when multiple relation tabs are enabled, select across all enabled types
    try:
        if selection_mode in (GwSelectionMode.CAMPAIGN, GwSelectionMode.EXPRESSION_CAMPAIGN):
            types_all = ["arc", "node", "connec", "link"]
            try:
                if getattr(class_object, 'project_type', '').lower() == 'ud':
                    types_all.append("gully")
            except Exception:
                pass

            enabled_types = []
            tab_feature = getattr(dialog, 'tab_feature', None)
            for ft in types_all:
                tab = getattr(dialog, f"tab_{ft}", None)
                if tab_feature is None or tab is None:
                    continue
                idx = tab_feature.indexOf(tab)
                if idx != -1 and tab_feature.isTabEnabled(idx):
                    enabled_types.append(ft)

            if len(enabled_types) > 1:
                class_object.rel_feature_type = 'all'
                class_object.multi_enabled_types = enabled_types
    except Exception:
        pass

    # Choose selection tool based on tool_type
    try:
        selection_type_enum = GwSelectionType(tool_type)
    except ValueError:
        selection_type_enum = GwSelectionType.DEFAULT

    select_manager = GwSelectManager(class_object, table_object, dialog, selection_mode, selection_type=selection_type_enum)

    global_vars.canvas.setMapTool(select_manager)
    if selection_type_enum == GwSelectionType.POINT:
        cursor = QCursor(Qt.CursorShape.CrossCursor)
    else:
        cursor = get_cursor_multiple_selection()
    global_vars.canvas.setCursor(cursor)


def select_with_expression_dialog(class_object, dialog, table_object, selection_mode=None):
    """Select features by expression"""

    if selection_mode is None:
        selection_mode = GwSelectionMode.EXPRESSION

    # Get the current feature type
    class_object.rel_feature_type = get_signal_change_tab(dialog)
    # Connect the signal selection changed
    connect_signal_selection_changed(class_object, dialog, table_object, selection_mode)
    # Show the expression dialog
    show_expression_dialog(class_object.rel_feature_type, dialog, table_object)
    # Disconnect the signal selection changed
    tools_qgis.disconnect_signal_selection_changed()


def select_with_expression_dialog_custom(class_object, dialog, table_object, layer_name, activation_function, deactivation_function):
    """Select features by expression with custom activation and deactivation functions"""

    # Execute activation function
    activation_function()

    # Show dialog
    if show_expression_dialog(class_object.feature_type, dialog, table_object) in (QDialog.DialogCode.Accepted, QDialog.DialogCode.Rejected):
        # Execute deactivation function
        deactivation_function()


def get_expected_table_name(class_object, table_object, selection_mode):
    if selection_mode in (GwSelectionMode.LOT, GwSelectionMode.EXPRESSION_LOT):
        expected_table_name = f"tbl_campaign_{table_object}_x_{class_object.rel_feature_type}"
    elif selection_mode == GwSelectionMode.MINCUT_CONNEC:
        expected_table_name = f"tbl_{table_object}_{class_object.rel_feature_type}"
    else:
        expected_table_name = f"tbl_{table_object}_x_{class_object.rel_feature_type}"

    return expected_table_name


def find_parent_tab(widget):
    """Find the parent QTabWidget of a given widget"""
    current = widget
    while current is not None:
        if isinstance(current, QTabWidget):
            return current
        current = current.parent()
    return None


def _filter_ids_by_context(class_object, selection_mode: GwSelectionMode, feature_type: str, candidate_ids: list[str]) -> list[str]:
    """Filter candidate ids according to the current selection context (LOT/CAMPAIGN).

    Keeps logic centralized and returns a new filtered list of string ids.
    """
    ids = [str(i) for i in (candidate_ids or [])]

    # LOT filter: only ids allowed by the campaign linked to the lot
    if selection_mode in (GwSelectionMode.LOT, GwSelectionMode.EXPRESSION_LOT):
        try:
            lot_id = getattr(class_object, 'lot_id', None) or getattr(class_object, 'lot_id_value', None)
        except Exception:
            lot_id = None
        if lot_id and hasattr(class_object, 'get_allowed_features_for_lot'):
            try:
                allowed = class_object.get_allowed_features_for_lot(int(lot_id), feature_type) or []
                allowed_set = set(map(str, allowed))
                return [i for i in ids if i in allowed_set]
            except Exception:
                return ids

    # CAMPAIGN filter: allowed ids according to review/visit class restrictions
    if selection_mode in (GwSelectionMode.CAMPAIGN, GwSelectionMode.EXPRESSION_CAMPAIGN) \
       and hasattr(class_object, 'get_allowed_features_for_campaign'):
        try:
            allowed = class_object.get_allowed_features_for_campaign(feature_type)
            if isinstance(allowed, list):
                allowed_set = set(map(str, allowed))
                return [i for i in ids if i in allowed_set]
        except Exception:
            return ids

    return ids


def _campaign_multi_tab_shortcut(class_object, dialog, table_object, selection_mode) -> bool:
    """Return True if handled Campaign multi-tab insert directly here.

    This isolates the Campaign multi-tab early-exit logic to keep
    selection_changed below simpler for flake8 C901.
    """
    if selection_mode not in (GwSelectionMode.CAMPAIGN, GwSelectionMode.EXPRESSION_CAMPAIGN):
        return False

    try:
        multi_enabled = 0
        tab_feature = getattr(dialog, 'tab_feature', None)
        for ft in ("arc", "node", "connec", "link", "gully"):
            tab = getattr(dialog, f"tab_{ft}", None)
            if tab_feature and tab is not None:
                idx = tab_feature.indexOf(tab)
                if idx != -1 and tab_feature.isTabEnabled(idx):
                    multi_enabled += 1
        if multi_enabled < 2:
            return False

        if getattr(class_object, '_pending_multi_insert', False):
            return True

        try:
            class_object._pending_multi_insert = True
            QTimer.singleShot(0, partial(_campaign_multi_insert_processing, class_object, dialog, table_object, selection_mode))
        except Exception:
            _campaign_multi_insert_processing(class_object, dialog, table_object, selection_mode)
        return True
    except Exception:
        return False


def selection_changed(class_object, dialog, table_object, selection_mode: GwSelectionMode = GwSelectionMode.DEFAULT, lazy_widget=None, lazy_init_function=None):
    """Handles selections from the map while keeping stored table values and allowing new selections from snapping."""

    if selection_mode != GwSelectionMode.EXPRESSION:
        tools_qgis.disconnect_signal_selection_changed()

    field_id = f"{class_object.rel_feature_type}_id"

    # Campaign-only early path extracted for readability
    if _campaign_multi_tab_shortcut(class_object, dialog, table_object, selection_mode):
        return

    if selection_mode in (GwSelectionMode.LOT, GwSelectionMode.EXPRESSION_LOT):
        expected_table_name = f"tbl_campaign_{table_object}_x_{class_object.rel_feature_type}"
    elif selection_mode == GwSelectionMode.MINCUT_CONNEC:
        expected_table_name = f"tbl_{table_object}_{class_object.rel_feature_type}"
    else:
        expected_table_name = f"tbl_{table_object}_x_{class_object.rel_feature_type}"

    # Retrieve the correct table widget

    # Find all matching table widgets and get the first one if any exist
    table_widgets = dialog.findChildren(QTableView, QRegularExpression(f"{expected_table_name}$"))
    if not table_widgets:
        return
    table_widget = table_widgets[0]
    table_widget.blockSignals(True)

    model = table_widget.model()
    selection_model = table_widget.selectionModel()

    # Handle cases where the table is empty
    table_ids = []
    if model:
        table_ids = [
            str(get_model_index(table_widget, row, field_id)) for row in range(model.rowCount())
        ]
    table_ids_original = table_ids.copy()

    # Ensure dictionary and list exist for storing feature IDs per feature type
    if not hasattr(class_object, "rel_list_ids"):
        class_object.rel_list_ids = {}
    if class_object.rel_feature_type not in class_object.rel_list_ids:
        class_object.rel_list_ids[class_object.rel_feature_type] = []
    # Store current table feature IDs
    if table_ids:
        class_object.rel_list_ids[class_object.rel_feature_type] = table_ids
    elif not class_object.rel_list_ids[class_object.rel_feature_type]:
        class_object.rel_list_ids[class_object.rel_feature_type] = []
    # Collect selected features from the map - OPTIMIZED DATABASE APPROACH FOR ALL MODES
    selected_ids = []
    # Process map selection with filtering and database queries
    selected_ids = _process_map_selection(class_object, selection_mode, field_id)

    # Ensure selections are added even if the table was initially empty
    if not table_ids_original and selected_ids:
        class_object.rel_list_ids[class_object.rel_feature_type] = selected_ids

    # Skip redundant filtering - already applied in database query
    # Only apply final filter for non-database contexts (like EXPRESSION mode)
    feature_type = class_object.rel_feature_type
    if selection_mode not in (GwSelectionMode.CAMPAIGN, GwSelectionMode.LOT, GwSelectionMode.EXPRESSION_CAMPAIGN, GwSelectionMode.EXPRESSION_LOT):
        class_object.rel_list_ids[feature_type] = _filter_ids_by_context(
            class_object, selection_mode, feature_type, class_object.rel_list_ids.get(feature_type, []))
        selected_ids = _filter_ids_by_context(class_object, selection_mode, feature_type, selected_ids)

    # Use set for fast membership checking - O(1) instead of O(n)
    table_ids_set = set(table_ids_original)
    ids_to_insert = [id for id in class_object.rel_list_ids[class_object.rel_feature_type] if id not in table_ids_set]

    do_insert = False
    if ids_to_insert:
        # Show confirmation dialog with filtered features
        if len(ids_to_insert) <= 50:
            msg = "Do you want to insert the selected features? {0}"
            msg_params = (", ".join(ids_to_insert), )
        else:
            msg = "Do you want to insert {0} selected features? (First 50: {1} ...)"
            msg_params = (len(ids_to_insert), ", ".join(ids_to_insert[:50]))
        do_insert = tools_qt.show_question(msg, msg_params=msg_params)
    else:
        # No new ids to insert: show info message and clear selection
        msg_params = None
        if selected_ids:
            # Features were selected but already exist in table
            msg = "No new features to insert. All selected features already exist in the table."
        else:
            # No features of this type were found in the selection
            # Get the actual tab name for display
            tab_name = class_object.rel_feature_type
            if hasattr(dialog, 'tab_feature'):
                tab_idx = dialog.tab_feature.currentIndex()
                tab_name = dialog.tab_feature.tabText(tab_idx)
            msg = "No features found in the selection for {0}."
            msg_params = (tab_name, )
        tools_qgis.show_info(msg, dialog=dialog, msg_params=msg_params)
        remove_selection(layers=class_object.rel_layers)

    # If user closes/cancels the confirmation, just clear canvas selection
    if not do_insert:
        remove_selection(layers=class_object.rel_layers)

    # Prevent UI interference while updating the table
    expr_filter = f'"{field_id}" IN (' + ", ".join(f"'{i}'" for i in class_object.rel_list_ids[class_object.rel_feature_type]) + ")"
    if selection_mode == GwSelectionMode.PSECTOR and do_insert:
        psector_id = tools_qt.get_text(dialog, "tab_general_psector_id")
        _insert_feature(dialog, psector_id, 'psector', class_object.rel_feature_type, ids_to_insert)
        if class_object.rel_feature_type in ('connec', 'gully'):
            # Insert again with state = 1
            _insert_feature(dialog, psector_id, 'psector', class_object.rel_feature_type, ids_to_insert, extra_cols='{"state": 1}')
        load_tableview_psector(dialog, class_object.rel_feature_type)
        set_model_signals(class_object)
        remove_selection()
    elif selection_mode == GwSelectionMode.PSECTOR and not do_insert:
        remove_selection()
    elif selection_mode in (GwSelectionMode.CAMPAIGN, GwSelectionMode.EXPRESSION_CAMPAIGN) and do_insert:
        _insert_feature(dialog, class_object.campaign_id, 'campaign', class_object.rel_feature_type, ids_to_insert)
        load_tableview_campaign(dialog, class_object.rel_feature_type, class_object.campaign_id, class_object.rel_layers)
    elif selection_mode in (GwSelectionMode.LOT, GwSelectionMode.EXPRESSION_LOT) and do_insert:
        _insert_feature(dialog, class_object.lot_id, 'lot', class_object.rel_feature_type, ids_to_insert)
        load_tableview_lot(dialog, class_object.rel_feature_type, class_object.lot_id, class_object.rel_layers)
    elif selection_mode == GwSelectionMode.ELEMENT and do_insert:
        _insert_feature(dialog, class_object.feature_id, 'element', class_object.rel_feature_type, ids_to_insert)
        load_tableview_element(dialog, class_object.feature_id, class_object.rel_feature_type)
    elif selection_mode == GwSelectionMode.FEATURE_END and do_insert:
        load_tableview_feature_end(class_object, dialog, table_object, class_object.rel_feature_type, expr_filter=expr_filter)
        tools_qt.set_lazy_init(table_object, lazy_widget=lazy_widget, lazy_init_function=lazy_init_function)
    elif selection_mode == GwSelectionMode.VISIT and do_insert:
        _insert_feature(dialog, class_object.visit_id.text(), 'visit', class_object.rel_feature_type, ids_to_insert)
        load_tableview_visit(dialog, class_object.visit_id.text(), class_object.rel_feature_type)
    elif selection_mode == GwSelectionMode.MINCUT_CONNEC and do_insert:
        get_rows_by_feature_type(class_object, dialog, table_object, class_object.rel_feature_type, expr_filter=expr_filter, table_separator="_")
        tools_qt.set_lazy_init(table_object, lazy_widget=lazy_widget, lazy_init_function=lazy_init_function)
    elif do_insert:
        columns_to_show = [f"{class_object.rel_feature_type}_id", "code", "sys_code", f"{class_object.rel_feature_type}_type", "sector_id", "state", "state_type", "expl_id", "descript"]
        get_rows_by_feature_type(class_object, dialog, table_object, class_object.rel_feature_type, expr_filter=expr_filter, columns_to_show=columns_to_show)
        tools_qt.set_lazy_init(table_object, lazy_widget=lazy_widget, lazy_init_function=lazy_init_function)

    enable_feature_type(dialog, widget_table=table_object, ids=class_object.rel_list_ids[class_object.rel_feature_type])

    table_widget.blockSignals(False)

    # Ensure selection of rows in the table based on the selected feature IDs from the map
    model = table_widget.model()
    selection_model = table_widget.selectionModel()
    if model and selection_model and selected_ids:
        # Skip row selection for very large datasets to avoid performance issues
        row_count = model.rowCount()
        if row_count <= 5000:
            selection_model.clearSelection()

            # Convert to set for faster lookup
            selected_ids_set = set(selected_ids)

            for row in range(row_count):
                model_index = get_model_index(table_widget, row, field_id)
                row_value = str(model_index)
                if row_value in selected_ids_set:
                    column_index = model.fieldIndex(field_id)
                    index = model.index(row, column_index)
                    selection_model.select(index, QItemSelectionModel.SelectionFlag.Select | QItemSelectionModel.SelectionFlag.Rows)

    # Safely check and call callback if it exists
    if hasattr(class_object, 'callback_later_selection') and class_object.callback_later_selection:
        class_object.callback_later_selection()

    # Safely check highlight method
    if hasattr(class_object, 'highlight_method_active') and class_object.highlight_method_active:
        class_object.highlight_features_method(class_object, dialog, table_object)


def _process_map_selection(class_object, selection_mode, field_id):
    """Process map selection with filtering logic and database queries"""
    if not class_object.rel_layers:
        return []

    # Get selected feature IDs from QGIS (instant - no attribute loading)
    selected_fids = []
    for layer in class_object.rel_layers[class_object.rel_feature_type]:
        if layer.selectedFeatureCount() > 0:
            selected_fids.extend(layer.selectedFeatureIds())

    if not selected_fids:
        return []

    # Apply filtering logic early to get only allowed features for highlighting
    # This ensures the map selection only highlights features that can actually be inserted
    filtered_fids = _filter_ids_by_context(class_object, selection_mode, class_object.rel_feature_type, selected_fids)

    # Convert filtered string IDs back to QGIS feature IDs for map selection
    if filtered_fids:
        # Get the layer to work with
        layer = class_object.rel_layers[class_object.rel_feature_type][0]

        # Find QGIS feature IDs that correspond to the filtered database feature IDs
        field_idx = layer.fields().indexOf(f"{class_object.rel_feature_type}_id")
        if field_idx != -1:
            # Get all features to find matching QGIS feature IDs
            request = QgsFeatureRequest().setFlags(QgsFeatureRequest.Flag.NoGeometry).setSubsetOfAttributes([field_idx])
            matching_qgis_fids = []

            for feature in layer.getFeatures(request):
                feature_id = str(feature.attribute(field_idx))
                if feature_id in filtered_fids:
                    matching_qgis_fids.append(feature.id())

            # Clear selection and re-select only the filtered features
            layer.removeSelection()
            if matching_qgis_fids:
                layer.select(matching_qgis_fids)

    # Use original selected_fids for processing (filtering will be applied in SQL)
    # Get context-specific filter for SQL
    where_clause = ""
    if selection_mode in (GwSelectionMode.CAMPAIGN, GwSelectionMode.EXPRESSION_CAMPAIGN):
        if hasattr(class_object, 'get_allowed_features_for_campaign'):
            try:
                allowed = class_object.get_allowed_features_for_campaign(class_object.rel_feature_type)
                if isinstance(allowed, list) and allowed:
                    allowed_str = ','.join(f"'{aid}'" for aid in allowed)
                    where_clause = f"AND {field_id} IN ({allowed_str})"
            except Exception:
                pass
    elif selection_mode in (GwSelectionMode.LOT, GwSelectionMode.EXPRESSION_LOT):
        try:
            lot_id = getattr(class_object, 'lot_id', None) or getattr(class_object, 'lot_id_value', None)
        except Exception:
            lot_id = None
        if lot_id and hasattr(class_object, 'get_allowed_features_for_lot'):
            try:
                allowed = class_object.get_allowed_features_for_lot(int(lot_id), class_object.rel_feature_type)
                if isinstance(allowed, list) and allowed:
                    allowed_str = ','.join(f"'{aid}'" for aid in allowed)
                    where_clause = f"AND {field_id} IN ({allowed_str})"
            except Exception:
                pass
    elif selection_mode == GwSelectionMode.PSECTOR:
        where_clause = "AND state <> 0"
    # For all other modes no additional filtering
    # Query each layer separately to handle multi-layer feature types (like elements with ve_man_frelem + ve_man_genelem)
    selected_ids = []
    existing_ids_set = set(class_object.rel_list_ids[class_object.rel_feature_type])

    try:
        for layer in class_object.rel_layers[class_object.rel_feature_type]:
            if layer.selectedFeatureCount() == 0:
                continue

            # Get layer-specific selected feature IDs
            layer_selected_fids = layer.selectedFeatureIds()
            if not layer_selected_fids:
                continue

            # Get table name and schema using GisWater utilities
            table_name = tools_qgis.get_layer_source_table_name(layer)
            schema_name = tools_qgis.get_layer_schema(layer)
            pk_field = tools_qgis.get_primary_key(layer)

            # Construct full table name
            if table_name and schema_name:
                full_table_name = f"{schema_name}.{table_name}"
            elif table_name:
                full_table_name = table_name
            else:
                # Fallback to standard naming if extraction fails
                schema_name = tools_db.dao_db_credentials['schema'].replace('"', '') if tools_db.dao_db_credentials.get('schema') else 'ws'
                full_table_name = f"{schema_name}.v_edit_{class_object.rel_feature_type}"

            # Use field_id as fallback for primary key
            if not pk_field:
                pk_field = field_id

            # Query database directly for this layer
            fid_str = ','.join(map(str, layer_selected_fids))
            sql = f"""
                SELECT {field_id}::text
                FROM {full_table_name}
                WHERE {pk_field} IN ({fid_str})
                {where_clause}
            """

            rows = tools_db.get_rows(sql)
            if rows:
                layer_selected_ids = [row[field_id] for row in rows if row.get(field_id)]

                # Add to selected_ids and class object list
                for selected_id in layer_selected_ids:
                    if selected_id not in existing_ids_set:
                        selected_ids.append(selected_id)
                        class_object.rel_list_ids[class_object.rel_feature_type].append(selected_id)
                        existing_ids_set.add(selected_id)
    except Exception:
        # Fallback to original method if database query fails
        for layer in class_object.rel_layers[class_object.rel_feature_type]:
            if layer.selectedFeatureCount() > 0:
                field_idx = layer.fields().indexOf(field_id)
                if field_idx == -1:
                    continue
                request = QgsFeatureRequest().setFilterFids(layer.selectedFeatureIds()).setFlags(QgsFeatureRequest.Flag.NoGeometry).setSubsetOfAttributes([field_idx])
                for feature in layer.getFeatures(request):
                    selected_id = str(feature.attribute(field_idx))
                    if selected_id:
                        selected_ids.append(selected_id)
                        if selected_id not in class_object.rel_list_ids[class_object.rel_feature_type]:
                            class_object.rel_list_ids[class_object.rel_feature_type].append(selected_id)

    return selected_ids


def _get_enabled_types(dialog) -> list:
    enabled = []
    tab_feature = getattr(dialog, 'tab_feature', None)
    for ft in ("arc", "node", "connec", "link", "gully"):
        tab = getattr(dialog, f"tab_{ft}", None)
        if tab_feature and tab is not None:
            idx = tab_feature.indexOf(tab)
            if idx != -1 and tab_feature.isTabEnabled(idx):
                enabled.append(ft)
    return enabled


def _collect_ids_to_insert(class_object, dialog, table_object, selection_mode, enabled_types) -> dict:
    per_type = {}
    for ft in enabled_types:
        field = f"{ft}_id"
        table_ids = []
        try:
            widget = tools_qt.get_widget(dialog, f"tbl_{table_object}_x_{ft}")
            model = widget.model() if widget and hasattr(widget, 'model') else None
            if model:
                table_ids = [str(get_model_index(widget, row, field)) for row in range(model.rowCount())]
        except Exception:
            table_ids = []

        selected = []
        for layer in (class_object.rel_layers or {}).get(ft, []) or []:
            if layer and layer.selectedFeatureCount() > 0:
                for feature in layer.selectedFeatures():
                    sid = str(feature.attribute(field))
                    if sid and sid not in selected:
                        selected.append(sid)
        if not selected:
            continue
        try:
            selected = _filter_ids_by_context(class_object, selection_mode, ft, selected)
        except Exception:
            pass

        to_insert = [sid for sid in selected if sid and (sid not in table_ids)]
        if to_insert:
            per_type[ft] = to_insert
    return per_type


def _highlight_map_for_inserts(class_object, per_type_ids):
    try:
        remove_selection(layers=class_object.rel_layers)
        for ft, ids_list in per_type_ids.items():
            if not ids_list:
                continue
            id_col = f"{ft}_id"
            expr = QgsExpression(f"{id_col} IN ({','.join(str(i) for i in ids_list)})")
            tools_qgis.select_features_by_ids(ft, expr, class_object.rel_layers)
    except Exception:
        pass


def _confirm_multi_insert(per_type_ids) -> bool:
    try:
        lines = []
        for ft, ids_list in per_type_ids.items():
            preview = ", ".join(ids_list[:10])
            if len(ids_list) > 10:
                preview += ", ..."
            lines.append(f"{ft}: {len(ids_list)} [{preview}]")
        msg = "Do you want to insert the selected features?\n{0}"
        return bool(tools_qt.show_question(msg, msg_params=("\n".join(lines),)))
    except Exception:
        return True


def _select_rows_in_tables(dialog, ft, ids_list):
    try:
        qtable = tools_qt.get_widget(dialog, f"tbl_campaign_x_{ft}")
        if qtable and qtable.model() and qtable.selectionModel():
            id_col_name = f"{ft}_id"
            id_col_idx = tools_qt.get_col_index_by_col_name(qtable, id_col_name)
            if id_col_idx is not None:
                sel_model = qtable.selectionModel()
                sel_model.clearSelection()
                ids_set = set(map(str, ids_list))

                row_count = qtable.model().rowCount()

                for row in range(row_count):
                    val = str(qtable.model().index(row, id_col_idx).data())
                    if val in ids_set:
                        index = qtable.model().index(row, id_col_idx)
                        sel_model.select(index, QItemSelectionModel.SelectionFlag.Select | QItemSelectionModel.SelectionFlag.Rows)
    except Exception:
        pass


def _campaign_multi_insert_processing(class_object, dialog, table_object, selection_mode):
    """Process Campaign multi-tab insert using existing helpers; split into small steps."""
    try:
        # Clear pending flag now that we are running
        try:
            if getattr(class_object, '_pending_multi_insert', False):
                class_object._pending_multi_insert = False
        except Exception:
            pass

        enabled_types = _get_enabled_types(dialog)
        per_type = _collect_ids_to_insert(class_object, dialog, table_object, selection_mode, enabled_types)

        if not per_type:
            # No features found in selection for any enabled tab
            enabled_types_str = ", ".join(enabled_types) if enabled_types else "any feature type"
            msg = "No features found in the selection for the enabled tabs ({0})."
            tools_qgis.show_info(msg, parameter=enabled_types_str, dialog=dialog)
            remove_selection(layers=class_object.rel_layers)
            return

        _highlight_map_for_inserts(class_object, per_type)

        if not _confirm_multi_insert(per_type):
            remove_selection(layers=class_object.rel_layers)
            return

        for ft, ids_list in per_type.items():
            _insert_feature(dialog, class_object.campaign_id, 'campaign', ft, ids_list)
            load_tableview_campaign(dialog, ft, class_object.campaign_id, class_object.rel_layers)
            _select_rows_in_tables(dialog, ft, ids_list)

        if hasattr(class_object, 'callback_later_selection') and class_object.callback_later_selection:
            try:
                class_object.callback_later_selection()
            except Exception:
                pass
    except Exception:
        try:
            remove_selection(layers=class_object.rel_layers)
        except Exception:
            pass


def select_ids_in_table(class_object, dialog, table_object, ids_to_select):
    """Select IDs in table"""
    widget_table, feature_type = class_object.get_expected_table(class_object, dialog, table_object)
    if not widget_table or not widget_table.model() or not feature_type:
        return

    expr_filter = QgsExpression(f"{feature_type}_id IN ({','.join(f'{i}' for i in ids_to_select)})")
    tools_qgis.select_features_by_ids(feature_type, expr_filter, class_object.rel_layers)


def get_model_index(widget, row, field_name):
    column_index = tools_qt.get_col_index_by_col_name(widget, field_name)

    if column_index is not None and widget.model() is not None:
        return widget.model().index(row, column_index).data()
    else:
        return None


def set_model_signals(class_object):

    class_object.rubber_band_point.reset()
    class_object.rubber_band_op.reset()
    class_object.rubber_band_line.reset()
    class_object.rubber_band_rectangle.reset()

    # Refresh table models to show newly added features
    try:
        if class_object.qtbl_connec.model():
            class_object.qtbl_connec.model().select()
    except Exception:
        pass

    # Set selectionModel signals
    class_object.qtbl_arc.selectionModel().selectionChanged.connect(partial(
        class_object._highlight_features_by_id, class_object.qtbl_arc, "ve_arc", "arc_id", class_object.rubber_band_point, 10, state_value=1
    ))
    class_object.qtbl_arc.selectionModel().selectionChanged.connect(partial(
        class_object._highlight_features_by_id, class_object.qtbl_arc, "arc", "arc_id", class_object.rubber_band_op, 10, state_value=0
    ))

    class_object.qtbl_node.selectionModel().selectionChanged.connect(partial(
        class_object._highlight_features_by_id, class_object.qtbl_node, "ve_node", "node_id", class_object.rubber_band_point, 5, state_value=1
    ))
    class_object.qtbl_node.selectionModel().selectionChanged.connect(partial(
        class_object._highlight_features_by_id, class_object.qtbl_node, "node", "node_id", class_object.rubber_band_op, 5, state_value=0
    ))

    class_object.qtbl_connec.selectionModel().selectionChanged.connect(partial(
        class_object._highlight_features_by_id, class_object.qtbl_connec, "ve_connec", "connec_id", class_object.rubber_band_point, 5, state_value=1
    ))
    class_object.qtbl_connec.selectionModel().selectionChanged.connect(partial(
        class_object._highlight_features_by_id, class_object.qtbl_connec, "connec", "connec_id", class_object.rubber_band_op, 5, state_value=0
    ))
    class_object.qtbl_connec.selectionModel().selectionChanged.connect(partial(
        class_object._manage_tab_feature_buttons
    ))

    if class_object.project_type.upper() == 'UD':
        class_object.qtbl_gully.selectionModel().selectionChanged.connect(partial(
            class_object._highlight_features_by_id, class_object.qtbl_gully, "ve_gully", "gully_id", class_object.rubber_band_point, 5, state_value=1
        ))
        class_object.qtbl_gully.selectionModel().selectionChanged.connect(partial(
            class_object._highlight_features_by_id, class_object.qtbl_gully, "gully", "gully_id", class_object.rubber_band_op, 5, state_value=0
        ))
        class_object.qtbl_gully.selectionModel().selectionChanged.connect(partial(
            class_object._manage_tab_feature_buttons
        ))


def show_expression_dialog(feature_type, dialog, table_object):
    """ Show expression builder dialog """

    # Open a dialog with a QgsExpressionBuilderWidget in it
    tablename = f"ve_{feature_type}"
    layer = tools_qgis.get_layer_by_tablename(tablename)
    start_text = None
    dlg = QgsExpressionSelectionDialog(layer, start_text, dialog)
    return dlg.exec()


def insert_feature(class_object, dialog, table_object, selection_mode: GwSelectionMode = GwSelectionMode.DEFAULT,
                   remove_ids=True, lazy_widget=None, lazy_init_function=None, refresh_callback=None, target_widget=None):
    """ Select feature with entered id. Set a model with selected filter.
        Attach that model to selected table
    """

    tools_qgis.disconnect_signal_selection_changed()
    feature_type = get_signal_change_tab(dialog)

    # Initialize the list for the specific feature type if it doesn't exist
    if feature_type not in class_object.rel_list_ids:
        class_object.rel_list_ids[feature_type] = []

    # Clear the temporary ids list when switching tabs or as needed
    if remove_ids:
        class_object.rel_ids = []

    field_id = f"{feature_type}_id"
    if target_widget:
        feature_id = tools_qt.get_text(dialog, target_widget)
    else:
        feature_id = tools_qt.get_text(dialog, "feature_id")
    expr_filter = f"{field_id} = '{feature_id}'"

    # Check expression
    (is_valid, expr) = tools_qt.check_expression_filter(expr_filter)
    if not is_valid:
        return None

    # Select features of layers applying @expr
    tools_qgis.select_features_by_ids(feature_type, expr, layers=class_object.rel_layers)

    if feature_id == 'null':
        msg = "You need to enter a feature id"
        tools_qt.tools_qgis.show_warning(msg, dialog=dialog)
        return

    # Temporarily store IDs to be added for this feature type
    selected_ids = []
    for layer in class_object.rel_layers[feature_type]:
        if layer.selectedFeatureCount() > 0:
            # Get selected features of the layer
            features = layer.selectedFeatures()
            for feature in features:
                # Append 'feature_id' into the list
                selected_id = feature.attribute(field_id)
                if selected_id not in selected_ids:
                    selected_ids.append(selected_id)
    # TODO: Check this. Cast to int?
    if int(feature_id) not in selected_ids:
        selected_ids.append(str(feature_id))
    # Append the new IDs to the existing list, ensuring no duplicates
    class_object.rel_list_ids[feature_type] = list(set(class_object.rel_list_ids[feature_type] + selected_ids))

    # Generate expression filter for the IDs
    if class_object.rel_list_ids[feature_type]:
        expr_filter = f'"{field_id}" IN ('
        for i in range(len(class_object.rel_list_ids[feature_type])):
            expr_filter += f"'{class_object.rel_list_ids[feature_type][i]}', "
        expr_filter = expr_filter[:-2] + ")"
    else:
        expr_filter = f'"{field_id}" IN (NULL)'

    # Check expression
    (is_valid, expr) = tools_qt.check_expression_filter(expr_filter)
    if not is_valid:
        return

    # Select features with previous filter
    # Build a list of feature id's and select them
    for layer in class_object.rel_layers[feature_type]:
        it = layer.getFeatures(QgsFeatureRequest(expr))
        id_list = [i.id() for i in it]
        if len(id_list) > 0:
            layer.selectByIds(id_list)

    # Reload contents of table 'tbl_xxx_xxx_@feature_type'
    if selection_mode == GwSelectionMode.PSECTOR:
        psector_id = tools_qt.get_text(dialog, "tab_general_psector_id")
        _insert_feature(dialog, psector_id, 'psector', feature_type, selected_ids)
        load_tableview_psector(dialog, feature_type)
        layers = remove_selection(True, class_object.rel_layers)
        class_object.rel_layers = layers
        set_model_signals(class_object)
    elif selection_mode == GwSelectionMode.CAMPAIGN:
        _insert_feature(dialog, class_object.campaign_id, 'campaign', feature_type, selected_ids)
        layers = remove_selection(True, class_object.rel_layers)
        class_object.rel_layers = layers
        load_tableview_campaign(dialog, feature_type, class_object.campaign_id, class_object.rel_layers)

    elif selection_mode == GwSelectionMode.LOT:
        _insert_feature(dialog, class_object.lot_id, 'lot', feature_type, selected_ids)
        layers = remove_selection(True, class_object.rel_layers)
        class_object.rel_layers = layers
        load_tableview_lot(dialog, feature_type, class_object.lot_id, class_object.rel_layers)
    elif selection_mode == GwSelectionMode.FEATURE_END:
        load_tableview_feature_end(class_object, dialog, table_object, feature_type, expr_filter=expr_filter)
        tools_qt.set_lazy_init(table_object, lazy_widget=lazy_widget, lazy_init_function=lazy_init_function)
    elif selection_mode == GwSelectionMode.ELEMENT:
        _insert_feature(dialog, class_object.feature_id, 'element', feature_type, selected_ids)
        load_tableview_element(dialog, class_object.feature_id, feature_type)
    elif selection_mode == GwSelectionMode.VISIT:
        _insert_feature(dialog, class_object.visit_id.text(), 'visit', class_object.rel_feature_type, selected_ids)
        load_tableview_visit(dialog, class_object.visit_id.text(), feature_type)
    elif selection_mode == GwSelectionMode.MINCUT_CONNEC:
        get_rows_by_feature_type(class_object, dialog, table_object, class_object.rel_feature_type, expr_filter=expr_filter, table_separator="_")
        tools_qt.set_lazy_init(table_object, lazy_widget=lazy_widget, lazy_init_function=lazy_init_function)
    else:
        columns_to_show = [f"{feature_type}_id", "code", "sys_code", f"{feature_type}_type", "sector_id", "state", "state_type", "expl_id", "descript"]
        get_rows_by_feature_type(class_object, dialog, table_object, feature_type, expr_filter=expr_filter, columns_to_show=columns_to_show)
        tools_qt.set_lazy_init(table_object, lazy_widget=lazy_widget, lazy_init_function=lazy_init_function)

    enable_feature_type(dialog, table_object, ids=class_object.rel_list_ids[feature_type])

    # Clear the feature_id text field
    tools_qt.set_widget_text(dialog, "feature_id", "")

    if refresh_callback:
        refresh_callback()


def remove_selection(remove_groups=True, layers=None):
    """ Removes selection from layers.
    :param remove_groups: Remove groups of layers (bool)
    :param layers: Dictionary of layers to remove selection from (optional)
    :return: Dictionary of layers with removed selection
    """

    list_layers = ["ve_arc", "ve_node", "ve_connec", "ve_man_frelem", "ve_man_genelem", "ve_link"]
    if global_vars.project_type == 'ud':
        list_layers.append("ve_gully")

    for layer_name in list_layers:
        layer = tools_qgis.get_layer_by_tablename(layer_name)
        if layer:
            layer.removeSelection()

    if remove_groups and layers is not None:
        for key, elems in layers.items():
            for layer in layers[key]:
                if layer:
                    layer.removeSelection()

    global_vars.canvas.refresh()

    return layers


def connect_signal_selection_changed(class_object, dialog, table_object, selection_mode: GwSelectionMode = GwSelectionMode.DEFAULT):
    """ Connect signal selectionChanged """

    try:
        global_vars.canvas.selectionChanged.connect(
            partial(selection_changed, class_object, dialog, table_object, selection_mode))
    except Exception as e:
        msg = "{0}: {1}"
        msg_params = ("connect_signal_selection_changed", e,)
        tools_log.log_info(msg, msg_params=msg_params)


def docker_dialog(dialog, dlg_name=None, title=None):

    positions = {8: Qt.DockWidgetArea.BottomDockWidgetArea, 4: Qt.DockWidgetArea.TopDockWidgetArea,
                 2: Qt.DockWidgetArea.RightDockWidgetArea, 1: Qt.DockWidgetArea.LeftDockWidgetArea}

    # If a previous guard set a block, skip attaching this dialog
    if lib_vars.session_vars.get('block_next_form_attach'):
        lib_vars.session_vars['block_next_form_attach'] = False
        try:
            dialog.close()
        except Exception:
            pass
        return

    # Ensure docker exists
    if not lib_vars.session_vars.get('dialog_docker'):
        lib_vars.session_vars['dialog_docker'] = GwDocker()
        lib_vars.session_vars['dialog_docker'].dlg_closed.connect(partial(close_docker, option_name='position'))
        manage_docker_options()

    try:
        docker = lib_vars.session_vars['dialog_docker']

        # Set new widget
        docker.setWindowTitle(dialog.windowTitle())
        docker.setWidget(dialog)
        docker.setWindowFlags(Qt.WindowType.WindowContextHelpButtonHint)

        # Create btn_help
        add_btn_help(dialog)
        dialog.messageBar().hide()
        global_vars.iface.addDockWidget(positions[docker.position], docker)

        if dlg_name:
            tools_qt._translate_form(dlg_name, dialog)
        if title:
            docker.setWindowTitle(tools_qt.tr(f'dlg_{title}', context_name=dlg_name))

    except RuntimeError as e:
        msg = "{0}: {1}"
        msg_params = (type(e).__name__, e,)
        tools_log.log_warning(msg, msg_params=msg_params)


def _check_mincut_state_4_replacement(docker):
    """
    Check if opening a mincut over another mincut in state 4 ("On Planning").
    If so, ask user for confirmation and cleanup the old mincut if accepted.
    Returns True if the operation should be blocked (user declined).
    """
    if not docker or isdeleted(docker):
        return False

    try:
        widget = docker.widget()
    except RuntimeError:
        return False

    if not widget or isdeleted(widget) or widget.objectName() != 'dlg_mincut':
        return False

    # Get mincut ID from the current widget (not from mincut object, which may already point to new mincut)
    try:
        rid_widget = widget.findChild(QLineEdit, 'result_mincut_id')
        rid_text = rid_widget.text() if rid_widget else None
    except Exception:
        return False

    if not rid_text or rid_text in ('', 'null'):
        return False

    # Check if mincut exists in DB and is in state 4
    try:
        row = tools_db.get_row(f"SELECT mincut_state FROM om_mincut WHERE id = '{rid_text}'", log_info=False)
        db_state = (row.get('mincut_state') if isinstance(row, dict) else row[0]) if row else None

        if str(db_state) != '4':
            return False

        # Ask user if they want to cancel the existing mincut
        if not tools_qt.show_question(
            "The mincut will be canceled, are you sure?",
            title="Cancel mincut",
            force_action=True
        ):
            # User declined: block new mincut
            return True

        # User accepted: cleanup the old mincut before opening new one
        class_obj = widget.property('class_obj')
        old_mincut = getattr(class_obj, 'mincut', None) if class_obj else None
        if old_mincut:
            old_mincut._mincut_cleanup_only(rid_text)

        return False
    except Exception:
        return False


def init_docker(docker_param='qgis_info_docker'):
    """ Get user config parameter @docker_param """

    lib_vars.session_vars['info_docker'] = True
    # Show info or form in docker?
    row = get_config_value(docker_param)
    if not row:
        lib_vars.session_vars['dialog_docker'] = None
        lib_vars.session_vars['docker_type'] = None
        return None
    value = row[0].lower()

    # Check if docker has dialog of type 'form' or 'main'
    if docker_param == 'qgis_info_docker':
        if lib_vars.session_vars['dialog_docker']:
            if lib_vars.session_vars['docker_type']:
                if lib_vars.session_vars['docker_type'] != 'qgis_info_docker':
                    lib_vars.session_vars['info_docker'] = False
                    return None

    if value == 'true':
        # Check if we're trying to open a mincut over another mincut in state 4
        if docker_param == 'qgis_form_docker':
            docker = lib_vars.session_vars.get('dialog_docker')
            if _check_mincut_state_4_replacement(docker):
                # User declined to cancel existing mincut, block the new one
                lib_vars.session_vars['block_next_form_attach'] = True
                return docker
        # Don't close docker if it already exists and is the same type - just reuse it
        if not lib_vars.session_vars.get('dialog_docker') or lib_vars.session_vars.get('docker_type') != docker_param:
            close_docker()
            lib_vars.session_vars['dialog_docker'] = GwDocker()
            lib_vars.session_vars['dialog_docker'].dlg_closed.connect(partial(close_docker, option_name='position'))
            manage_docker_options()
        lib_vars.session_vars['docker_type'] = docker_param
    else:
        lib_vars.session_vars['dialog_docker'] = None
        lib_vars.session_vars['docker_type'] = None

    return lib_vars.session_vars['dialog_docker']


def close_docker(option_name='position'):
    """ Save QDockWidget position (1=Left, 2=Right, 4=Top, 8=Bottom),
        remove from iface and del class
    """

    try:
        if lib_vars.session_vars['dialog_docker']:
            if not lib_vars.session_vars['dialog_docker'].isFloating():
                docker_pos = global_vars.iface.mainWindow().dockWidgetArea(lib_vars.session_vars['dialog_docker'])
                widget = lib_vars.session_vars['dialog_docker'].widget()
                if widget:
                    widget.close()
                    del widget
                    lib_vars.session_vars['dialog_docker'].setWidget(None)
                    lib_vars.session_vars['docker_type'] = None
                    set_config_parser('docker', option_name, f'{docker_pos}')
                global_vars.iface.removeDockWidget(lib_vars.session_vars['dialog_docker'])
                lib_vars.session_vars['dialog_docker'] = None
    except AttributeError:
        lib_vars.session_vars['docker_type'] = None
        lib_vars.session_vars['dialog_docker'] = None


def manage_docker_options(option_name='position'):
    """ Check if user want dock the dialog or not """

    # Load last docker position
    try:
        # Docker positions: 1=Left, 2=Right, 4=Top, 8=Bottom
        pos = int(get_config_parser('docker', option_name, "user", "session"))
        lib_vars.session_vars['dialog_docker'].position = 2
        if pos in (1, 2, 4, 8):
            lib_vars.session_vars['dialog_docker'].position = pos
    except Exception:
        lib_vars.session_vars['dialog_docker'].position = 2


def set_tablemodel_config(dialog, widget, table_name, sort_order=Qt.SortOrder.AscendingOrder, schema_name=None):
    """ Configuration of tables. Set visibility and width of columns """

    widget = tools_qt.get_widget(dialog, widget)
    if not widget or isdeleted(widget):
        return widget

    if schema_name is not None:
        config_table = f"{schema_name}.config_form_tableview"
    else:
        config_table = f"{lib_vars.schema_name}.config_form_tableview"

    # Set width and alias of visible columns
    columns_to_delete = []
    sql = (f"SELECT columnname, columnindex, width, alias, visible, style"
           f" FROM {config_table}"
           f" WHERE objectname = '{table_name}'"
           f" ORDER BY columnindex")
    rows = tools_db.get_rows(sql)

    if not rows:
        return widget

    # Create a dictionary to store the desired column positions
    column_order = {}
    for row in rows:
        column_order[row['columnname']] = row['columnindex']

    # Clear columns_dict
    widget.setProperty('columns', None)

    # Reorder columns in the widget according to columnindex
    header = widget.horizontalHeader()
    for i, (column_name, column_index) in enumerate(sorted(column_order.items(), key=lambda item: item[1])):
        col_idx = tools_qt.get_col_index_by_col_name(widget, column_name)
        if col_idx is not None:
            current_visual_index = header.visualIndex(col_idx)
            if current_visual_index != i:
                header.moveSection(current_visual_index, i)

    columns_dict: Dict[str, str] = {}
    for row in rows:
        col_idx = tools_qt.get_col_index_by_col_name(widget, row['columnname'])
        if col_idx is None:
            continue
        columns_dict[str(row['alias'] if row['alias'] else row['columnname'])] = str(row['columnname'])
        if not row['visible']:
            columns_to_delete.append(col_idx)
        else:
            style = row.get('style')
            if style:
                stretch = style.get('stretch')
                if stretch is not None:
                    stretch = QHeaderView.ResizeMode.Stretch if stretch else QHeaderView.ResizeMode.Interactive
                    widget.horizontalHeader().setSectionResizeMode(col_idx, stretch)
            width = row['width']
            if width is None:
                width = 100
            widget.setColumnWidth(col_idx, width)
            if row['alias'] is not None:
                widget.model().setHeaderData(col_idx, Qt.Orientation.Horizontal, row['alias'])
    widget.setProperty('columns', columns_dict)
    # Set order
    if isinstance(widget.model(), QStandardItemModel) is False:
        widget.model().setSort(0, sort_order)
        widget.model().select()
    # Delete columns
    for column in columns_to_delete:
        if column is not None:
            widget.hideColumn(column)

    return widget


def add_icon(widget, icon, folder="dialogs"):
    """ Set @icon to selected @widget """

    # Get icons folder
    icons_folder = os.path.join(lib_vars.plugin_dir, f"icons{os.sep}{folder}")
    icon_path = os.path.join(icons_folder, str(icon) + ".png")
    if not os.path.exists(icon_path):
        icon_path = os.path.join(icons_folder, str(icon) + ".svg")

    if os.path.exists(icon_path):
        widget.setIcon(QIcon(icon_path))
        if type(widget) is QPushButton:
            widget.setProperty('has_icon', True)
        return QIcon(icon_path)
    else:
        msg = "File not found"
        tools_log.log_info(msg, parameter=icon_path)
        return False


def get_icon(icon, folder="dialogs", log_info=True):
    # Get icons folder
    icons_folder = os.path.join(lib_vars.plugin_dir, f"icons{os.sep}{folder}")
    icon_path = os.path.join(icons_folder, str(icon) + ".png")

    if os.path.exists(icon_path):
        return QIcon(icon_path)
    else:
        if log_info:
            msg = "File not found"
            tools_log.log_info(msg, parameter=icon_path)
        return None


def add_tableview_header(widget: QWidget, fields: Optional[List[Dict[str, Any]]] = [], json_headers: Optional[list] = []) -> QWidget:

    model = widget.model()
    if model is None:
        model = QStandardItemModel()

    # Related by Qtable
    model.clear()
    widget.setModel(model)
    widget.horizontalHeader().setStretchLastSection(True)
    try:
        # Get headers
        headers = []

        if fields:
            for x in fields[0]:
                headers.append(x)

        # If there are not rows in tableview, set headers from json_headers
        if len(headers) == 0 and json_headers:
            for header in json_headers:
                headers.append(header['header'])

        # Set headers
        model.setHorizontalHeaderLabels(headers)
    except Exception:
        # if field['value'][0] is None
        pass

    return widget


def fill_tableview_rows(widget, fields: List[Dict[str, Any]]):
    if not fields:
        return widget
    model = widget.model()

    for item in fields:
        row = []
        for value in item.values():
            if value is None:
                value = ""
            if issubclass(type(value), dict):
                value = json.dumps(value)
            row.append(QStandardItem(str(value)))
        if len(row) > 0:
            model.appendRow(row)

    return widget


def set_calendar_from_user_param(dialog, widget, table_name, value, parameter):
    """ Executes query and set QDateEdit """

    sql = (f"SELECT {value} FROM {table_name}"
           f" WHERE parameter = '{parameter}' AND cur_user = current_user")
    row = tools_db.get_row(sql)
    if row and row[0]:
        date = QDate.fromString(row[0].replace('/', '-'), 'yyyy-MM-dd')
    else:
        date = QDate.currentDate()
    tools_qt.set_calendar(dialog, widget, date)


def load_tablename(dialog, table_object, feature_type, expr_filter):
    """ Reload @widget with contents of @tablename applying selected @expr_filter """

    widget_name = None
    if type(table_object) is str:
        widget_name = f"tbl_{table_object}_x_{feature_type}"
        widget = tools_qt.get_widget(dialog, widget_name)
        if not widget:
            message = "Widget not found"
            tools_log.log_info(message, parameter=widget_name)
            return None

    elif type(table_object) is QTableView:
        widget = table_object
    else:
        msg = "{0} is not a table name or {1}"
        msg_params = ("Table_object", "QTableView")
        tools_log.log_info(msg, msg_params=msg_params)
        return None

    table_name = f"{feature_type}"

    expr = tools_qt.set_table_model(dialog, widget, table_name, expr_filter)
    if widget_name is not None:
        set_tablemodel_config(dialog, widget_name, table_name)

    return expr


def load_tableview_psector(dialog, feature_type):
    """ Reload QtableView """

    value = tools_qt.get_text(dialog, "tab_general_psector_id")
    expr = f"psector_id = '{value}'"
    qtable = tools_qt.get_widget(dialog, f'tbl_psector_x_{feature_type}')
    tablename = qtable.property('tablename')
    message = tools_qt.fill_table(qtable, f"{tablename}", expr, QSqlTableModel.EditStrategy.OnFieldChange)
    if message:
        tools_qgis.show_warning(message)
    set_tablemodel_config(dialog, qtable, f"{tablename}")
    tools_qgis.refresh_map_canvas()


def load_tableview_element(dialog, feature_id, rel_feature_type):
    """ Reload QtableView """

    expr = f"element_id = '{feature_id}'"
    qtable = tools_qt.get_widget(dialog, f'tab_features_tbl_element_x_{rel_feature_type}')
    tablename = f'v_ui_element_x_{rel_feature_type}'
    message = tools_qt.fill_table(qtable, f"{tablename}", expr, QSqlTableModel.EditStrategy.OnFieldChange)
    if message:
        tools_qgis.show_warning(message)
    tableview = f'tbl_element_x_{rel_feature_type}'
    set_tablemodel_config(dialog, qtable, f"{tableview}")
    tools_qgis.refresh_map_canvas()


def load_tableview_visit(dialog, feature_id, rel_feature_type):
    """ Reload QtableView """

    expr = f"visit_id = '{feature_id}'"
    qtable = tools_qt.get_widget(dialog, f'tbl_visit_x_{rel_feature_type}')
    tablename = f'om_visit_x_{rel_feature_type}'
    message = tools_qt.fill_table(qtable, f"{tablename}", expr, QSqlTableModel.EditStrategy.OnFieldChange)
    if message:
        tools_qgis.show_warning(message)
    tableview = f'tbl_visit_x_{rel_feature_type}'
    set_tablemodel_config(dialog, qtable, f"{tableview}")
    tools_qgis.refresh_map_canvas()


def set_completer_object(dialog, tablename, field_id="id"):
    """ Set autocomplete of widget @table_object + "_id"
        getting id's from selected @table_object

        TODO: Refactor. It should have this params: (dialog, widget, tablename, field_id="id")
            The widget might not be called '@table_object + "_id"'
    """

    widget_name = tablename + "_id"
    if tablename == "ve_element":  # TODO: remove this when refactored
        widget_name = "element_id"

    widget = tools_qt.get_widget(dialog, widget_name)
    if not widget:
        return

    set_completer_widget(tablename, widget, field_id)


def set_completer_widget(tablename, widget, field_id, add_id=False,
                         filter_mode: tools_qt.QtMatchFlag = 'starts'):
    """ Set autocomplete of widget @table_object + "_id"
        getting id's from selected @table_object
    """

    if not widget:
        return
    if type(tablename) is list and type(field_id) is list:
        return set_multi_completer_widget(tablename, widget, field_id, add_id=add_id)
    if add_id:
        field_id += '_id'

    sql = (f"SELECT ({field_id})"
           f" FROM {lib_vars.schema_name}.{tablename}"
           f" ORDER BY {field_id}")
    rows = tools_db.get_rows(sql)
    tools_qt.set_completer_rows(widget, rows, filter_mode=filter_mode)


def set_multi_completer_widget(tablenames: list, widget, fields_id: list, add_id=False):
    """ Set autocomplete of widget @table_object + "_id"
        getting id's from selected @table_object
    """

    if not widget:
        return

    sql = ""
    idx = 0
    for tablename in tablenames:
        field_id = fields_id[idx]
        if add_id:
            field_id += '_id'
        if sql != "":
            sql += " UNION "
        sql += (f"SELECT DISTINCT({field_id}) as a"
                f" FROM {tablename}")
        idx += 1
    sql += " ORDER BY a"

    rows = tools_db.get_rows(sql)
    tools_qt.set_completer_rows(widget, rows)


def set_dates_from_to(widget_from, widget_to, table_name, field_from, field_to, max_back_date=None, max_fwd_date=None):
    """
    Builds query to populate @widget_from & @widget_to dates
        :param widget_from:
        :param widget_to:
        :param table_name:
        :param field_from:
        :param field_to:
        :param max_back_date: a PostgreSQL valid interval (eg. '1 year')
        :param max_fwd_date: a PostgreSQL valid interval (eg. '1 year')
    """

    min_sql = f"MIN(LEAST({field_from}, {field_to}))"
    max_sql = f"MAX(GREATEST({field_from}, {field_to}))"
    if max_back_date:
        min_sql = f"GREATEST({min_sql}, now() - interval '{max_back_date}')"
    if max_fwd_date:
        max_sql = f"LEAST({max_sql}, now() + interval '{max_fwd_date}')"

    sql = f"SELECT {min_sql}, {max_sql} FROM {table_name}"
    row = tools_db.get_row(sql)
    current_date = QDate.currentDate()
    if row:
        if row[0]:
            widget_from.setDate(row[0])
        else:
            widget_from.setDate(current_date)
        if row[1]:
            widget_to.setDate(row[1])
        else:
            widget_to.setDate(current_date)


def manage_close(dialog, table_object, cur_active_layer=None, single_tool_mode=None, layers=None):
    """ Close dialog and disconnect snapping """

    tools_qgis.disconnect_snapping()
    tools_qgis.disconnect_signal_selection_changed()
    if cur_active_layer:
        global_vars.iface.setActiveLayer(cur_active_layer)
    # some tools can work differently if standalone or integrated in another tool
    if single_tool_mode is not None:
        layers = remove_selection(single_tool_mode, layers=layers)
    else:
        layers = remove_selection(True, layers=layers)

    list_feature_type = ['arc', 'node', 'connec', 'element', 'link']
    if global_vars.project_type == 'ud':
        list_feature_type.append('gully')
    for feature_type in list_feature_type:
        tools_qt.reset_model(dialog, table_object, feature_type)

    close_dialog(dialog)

    return layers


def delete_records(class_object, dialog, table_object, selection_mode: GwSelectionMode = GwSelectionMode.DEFAULT,
                   lazy_widget=None, lazy_init_function=None, extra_field=None, refresh_callback=None):
    """ Delete selected elements of the table """

    tools_qgis.disconnect_signal_selection_changed()
    feature_type = get_signal_change_tab(dialog)
    if type(table_object) is str:
        if selection_mode == GwSelectionMode.LOT:
            widget_name = f"tbl_campaign_{table_object}_x_{feature_type}"
        elif selection_mode == GwSelectionMode.ELEMENT:
            widget_name = f"{table_object}_x_{feature_type}"
        else:
            widget_name = f"tbl_{table_object}_x_{feature_type}"
        widget = tools_qt.get_widget(dialog, widget_name)
        if not widget:
            msg = "Widget not found"
            tools_qgis.show_warning(msg, parameter=widget_name)
            return
    elif type(table_object) is QTableView:
        widget = table_object
    else:
        msg = "{0} is not a table name or {1}"
        msg_params = ("Table_object", "QTableView")
        tools_log.log_info(msg, msg_params=msg_params)
        return

    # Control when QTableView is void or has no model
    try:
        # Get selected rows
        selected_list = widget.selectionModel().selectedRows()
    except AttributeError:
        selected_list = []

    if len(selected_list) == 0:
        msg = "Any record selected"
        tools_qt.tools_qgis.show_warning(msg, dialog=dialog)
        return

    if selection_mode == GwSelectionMode.PSECTOR:
        full_list = widget.model()
        for x in range(0, full_list.rowCount()):
            if hasattr(full_list, 'record'):
                class_object.rel_ids.append(full_list.record(x).value(f"{feature_type}_id"))
            else:
                # QStandardItemModel
                id_col = tools_qt.get_col_index_by_col_name(widget, f"{feature_type}_id")
                if id_col != -1:
                    class_object.rel_ids.append(full_list.data(full_list.index(x, id_col)))
    else:
        class_object.rel_ids = class_object.rel_list_ids[feature_type]

    field_id = feature_type + "_id"

    del_id, inf_text, list_id = _get_selected_record_info(widget, field_id, selection_mode, selected_list)
    if not del_id:
        return

    message = "Are you sure you want to delete these records?"
    title = "Delete records"
    answer = tools_qt.show_question(message, title, inf_text)
    if answer:
        for el in del_id:
            if el in class_object.rel_ids or str(el) in class_object.rel_ids:
                # Remove whichever format exists
                try:
                    class_object.rel_ids.remove(el)
                except ValueError:
                    class_object.rel_ids.remove(str(el))
    else:
        return

    expr_filter = None
    expr = None
    if len(class_object.rel_ids) > 0:
        # Set expression filter with features in the list
        expr_filter = f'"{field_id}" IN ('
        for i in range(len(class_object.rel_ids)):
            expr_filter += f"'{class_object.rel_ids[i]}', "
        expr_filter = expr_filter[:-2] + ")"

        # Check expression
        (is_valid, expr) = tools_qt.check_expression_filter(expr_filter)  # @UnusedVariable
        if not is_valid:
            return

    # Update model of the widget with selected expr_filter
    _perform_delete_and_refresh_view(class_object, dialog, table_object, feature_type, selection_mode, list_id,
                                     expr_filter, lazy_widget, lazy_init_function, extra_field, selected_list, widget)

    # Select features with previous filter
    # Build a list of feature id's and select them
    tools_qgis.select_features_by_ids(feature_type, expr, layers=class_object.rel_layers)

    # Reset rubberband
    if selection_mode == GwSelectionMode.PSECTOR:
        reset_rubberband(class_object.rubber_band_point)
        reset_rubberband(class_object.rubber_band_op)
        reset_rubberband(class_object.rubber_band_line)
        reset_rubberband(class_object.rubber_band_rectangle)
    else:
        reset_rubberband(class_object.rubber_band)

    if selection_mode == GwSelectionMode.PSECTOR:
        class_object.rel_layers = remove_selection(layers=class_object.rel_layers)

    # Update list
    class_object.rel_list_ids[feature_type] = class_object.rel_ids
    enable_feature_type(dialog, table_object, ids=class_object.rel_ids)
    if refresh_callback:
        refresh_callback()


def _get_selected_record_info(widget, field_id, selection_mode, selected_list):
    """
    From a widget, get information about selected records.
    Returns a tuple of (list of ids to delete, display text of ids, string list of ids for query).
    """
    del_id = []
    model = widget.model()

    if selection_mode in (GwSelectionMode.CAMPAIGN, GwSelectionMode.LOT):
        col_index = tools_qt.get_col_index_by_col_name(widget, field_id)
        if col_index is not None:
            for item in selected_list:
                row = item.row()
                if isinstance(model, tools_qt.QSqlTableModel):
                    id_feature = model.record(row).value(col_index)
                else:
                    id_feature = model.item(row, col_index).text()
                del_id.append(id_feature)
    else:
        for item in selected_list:
            row = item.row()
            if hasattr(model, 'record'):
                id_feature = model.record(row).value(field_id)
            else:
                # QStandardItemModel - find column by name
                col_index = tools_qt.get_col_index_by_col_name(widget, field_id)
                if col_index is not None:
                    id_feature = model.data(model.index(row, col_index))
                else:
                    continue
            del_id.append(id_feature)

    if not del_id:
        return [], "", ""

    inf_text = ", ".join(map(str, del_id))
    list_id = ", ".join(f"'{_id}'" for _id in del_id)

    return del_id, inf_text, list_id


def _perform_delete_and_refresh_view(class_object, dialog, table_object, feature_type, selection_mode, list_id, expr_filter,
                                     lazy_widget, lazy_init_function, extra_field, selected_list, widget):
    """Perform the delete operation and refresh the corresponding view."""
    if selection_mode == GwSelectionMode.PSECTOR:
        state = None
        if extra_field is not None and len(selected_list) == 1:
            model = widget.model()
            if hasattr(model, 'record'):
                state = model.record(selected_list[0].row()).value(extra_field)
            else:
                # QStandardItemModel
                col_index = tools_qt.get_col_index_by_col_name(widget, extra_field)
                if col_index is not None:
                    state = model.data(model.index(selected_list[0].row(), col_index))
        _delete_feature_psector(dialog, feature_type, list_id, state)
        load_tableview_psector(dialog, feature_type)
        set_model_signals(class_object)
    elif selection_mode == GwSelectionMode.CAMPAIGN:
        state = None
        if extra_field is not None and len(selected_list) == 1:
            # Special handling for Campaign manager's QStandardItemModel
            model = widget.model()
            col_index = tools_qt.get_col_index_by_col_name(widget, extra_field)
            if col_index is not None:
                if isinstance(model, tools_qt.QSqlTableModel):
                    state = model.record(selected_list[0].row()).value(col_index)
                else:
                    state = model.item(selected_list[0].row(), col_index).text()
        _delete_feature_campaign(dialog, feature_type, list_id, class_object.campaign_id, state)
        load_tableview_campaign(dialog, feature_type, class_object.campaign_id, class_object.rel_layers)

    elif selection_mode == GwSelectionMode.LOT:
        state = None
        if extra_field is not None and len(selected_list) == 1:
            # Special handling for Lot manager's QStandardItemModel
            model = widget.model()
            col_index = tools_qt.get_col_index_by_col_name(widget, extra_field)
            if col_index is not None:
                if isinstance(model, tools_qt.QSqlTableModel):
                    state = model.record(selected_list[0].row()).value(col_index)
                else:
                    state = model.item(selected_list[0].row(), col_index).text()
        _delete_feature_lot(dialog, feature_type, list_id, class_object.lot_id, state)
        load_tableview_lot(dialog, class_object.rel_feature_type, class_object.lot_id, class_object.rel_layers)
    elif selection_mode == GwSelectionMode.FEATURE_END:
        load_tableview_feature_end(class_object, dialog, table_object, class_object.rel_feature_type,
                                   expr_filter=expr_filter)
        tools_qt.set_lazy_init(table_object, lazy_widget=lazy_widget, lazy_init_function=lazy_init_function)
    elif selection_mode == GwSelectionMode.VISIT:
        delete_feature_visit(dialog, class_object.visit_id.text(), class_object.rel_feature_type, list_id=list_id)
        load_tableview_visit(dialog, class_object.visit_id.text(), class_object.rel_feature_type)
    else:
        columns_to_show = [f"{feature_type}_id", "code", "sys_code", f"{feature_type}_type", "sector_id", "state", "state_type", "expl_id", "descript"]
        get_rows_by_feature_type(class_object, dialog, table_object, feature_type, expr_filter=expr_filter, columns_to_show=columns_to_show)
        tools_qt.set_lazy_init(table_object, lazy_widget=lazy_widget, lazy_init_function=lazy_init_function)


def get_parent_layers_visibility():
    """ Get layer visibility to restore when dialog is closed
    :return: example: {<QgsMapLayer: 'Arc' (postgres)>: True, <QgsMapLayer: 'Node' (postgres)>: False,
                       <QgsMapLayer: 'Connec' (postgres)>: True, <QgsMapLayer: 'Element' (postgres)>: False}
    """

    layers_visibility = {}
    for layer_name in ["ve_arc", "ve_node", "ve_connec", "ve_man_frelem", "ve_man_genelem", "ve_gully", "ve_link"]:
        layer = tools_qgis.get_layer_by_tablename(layer_name)
        if layer:
            layers_visibility[layer] = tools_qgis.is_layer_visible(layer)

    return layers_visibility


def restore_parent_layers_visibility(layers):
    """ Receive a dictionary with the layer and if it has to be active or not
    :param layers: example: {<QgsMapLayer: 'Arc' (postgres)>: True, <QgsMapLayer: 'Node' (postgres)>: False,
                             <QgsMapLayer: 'Connec' (postgres)>: True, <QgsMapLayer: 'Element' (postgres)>: False}
    """

    for layer, visibility in layers.items():
        tools_qgis.set_layer_visible(layer, False, visibility)


def create_rubberband(canvas, geometry_type: QgsGeometryType = None):
    """ Creates a rubberband and adds it to the global list """

    geom_type = _get_geom_type(geometry_type)

    rb = QgsRubberBand(canvas, geom_type)
    global_vars.active_rubberbands.append(rb)
    return rb


def reset_rubberband(rb, geometry_type=None):
    """ Resets a rubberband and tries to remove it from the global list """

    if geometry_type:
        geom_type = _get_geom_type(geometry_type)
        rb.reset(geom_type)
    else:
        rb.reset()

    try:
        global_vars.active_rubberbands.remove(rb)
    except ValueError:
        pass


def set_epsg():

    epsg = tools_qgis.get_epsg()
    lib_vars.project_epsg = epsg


def refresh_selectors(is_cm: bool = False):
    """Refreshes the selector docker if it's open.

    If is_cm=True, refresh the specific selector of campaign manager.
    """

    # Get the selector UI if it's open
    windows = [x for x in QApplication.allWidgets() if getattr(x, "isVisible", False)
               and (issubclass(type(x), GwSelectorUi))]

    if windows:
        try:
            dialog = windows[0]
            selector = dialog.property('GwSelector')
            if is_cm:
                selector.open_selector(selector_type='selector_campaign', reload_dlg=dialog)
            else:
                selector.open_selector(reload_dlg=dialog)
        except Exception:
            pass


def _refresh_selector_map_layers():
    """Reload selector-driven layers and refresh the map canvas."""

    for layer_name in ('ve_arc', 've_node', 've_connec', 've_gully', 've_link', 've_plan_psector'):
        tools_qgis.set_layer_index(layer_name)
    tools_qgis.refresh_map_canvas()


def resync_map_after_db_reconnect():
    """Resync planned network / selector map state after the database reconnects."""

    try:
        if not global_vars.project_loaded or global_vars.iface is None:
            return

        psignals = global_vars.psignals or {}
        if psignals.get('psector_active'):
            psector_id = psignals.get('psector_id')
            if not psector_id:
                row = get_config_value('plan_psector_current', log_info=False)
                psector_id = row[0] if row else None
            if psector_id:
                set_psector_mode_enabled(
                    enable=True, psector_id=psector_id, do_call_fct=True, force_change=True
                )
                return

        _refresh_selector_map_layers()
    except Exception as e:
        msg = "Exception in resync_map_after_db_reconnect: {0}"
        tools_log.log_warning(msg, msg_params=(e,))


def check_db_connection():
    """Check DB connection (libs) and resync map when QGIS layers were stale after idle."""
    opened, reconnected = tools_db.check_db_connection()
    if opened and reconnected:
        resync_map_after_db_reconnect()
    return opened


def execute_class_function(dlg_class, func_name: str, kwargs: Optional[dict] = None):
    """
    Executes a class' function (if the corresponding dialog is open).
    kwargs can be a dictionary with the arguments to pass to the function.
    If the argument is a string starting with '__self__', it will be replaced with the corresponding attribute of the class_obj.
    (e.g. '__self__.dlg_psector_mng' will be replaced with self.dlg_psector_mng (self is the class_obj))
    """

    # Get the dialog if it's open
    windows = [x for x in QApplication.allWidgets() if getattr(x, "isVisible", False)
               and (issubclass(type(x), dlg_class))]

    if windows:
        try:
            if kwargs is None:
                kwargs = {}
            dialog = windows[0]
            class_obj = dialog.property('class_obj')
            for key, value in kwargs.items():
                if isinstance(value, str) and value.startswith('__self__'):
                    kwargs[key] = getattr(class_obj, value.split('.')[1])
            getattr(class_obj, func_name)(**kwargs)
        except Exception as e:
            msg = "Exception in {0} (executing {1} from {2}): {3}"
            msg_params = ("tools_gw.execute_class_function", func_name, dlg_class.__name__, e,)
            tools_log.log_debug(msg, msg_params=msg_params)


def open_dlg_help():
    """ Opens the help page for the last focused dialog """

    parser = configparser.ConfigParser(comment_prefixes=";", allow_no_value=True, strict=False)
    path = f"{lib_vars.plugin_dir}{os.sep}config{os.sep}giswater.config"
    if not os.path.exists(path):
        webbrowser.open_new_tab('https://giswater.gitbook.io/giswater-manual')
        return True

    try:
        parser.read(path)
        web_tag = parser.get('web_tag', lib_vars.session_vars['last_focus'])
        webbrowser.open_new_tab(f'https://giswater.gitbook.io/giswater-manual/{web_tag}')
    except Exception:
        webbrowser.open_new_tab('https://giswater.gitbook.io/giswater-manual')
    finally:
        return True


def set_psector_mode_enabled(enable: Optional[bool] = None, psector_id: Optional[int] = None, do_call_fct: bool = True, force_change: bool = False):
    """
    Set psector mode enabled/disabled and update UI elements accordingly.

    Args:
        enable (Optional[bool]): If True, enables psector mode. If False, disables it.
            If None, toggles current state.
        psector_id (Optional[int]): ID of psector to set. If None, uses psector from cmb_psector_id.
        do_call_fct (bool): If True, calls gw_fct_set_toggle_current procedure. Should be False if it was already called.
        force_change (bool): If True, forces UI update. Useful when called from another function.
    """

    # Check if psector widgets exist (plan toolbar must be loaded)
    psignals_widgets = global_vars.psignals['widgets']
    if not psignals_widgets or len(psignals_widgets) < 2:
        return

    # Manage play/pause button
    btn_psector_playpause = psignals_widgets[0]
    if btn_psector_playpause is not None:
        active = btn_psector_playpause.property('psector_active')
        if enable is None:
            enable = not active

    # Manage psector combo box
    cmb_changed = psector_id is not None
    cmb_psector_id = psignals_widgets[1]
    if psector_id is None and cmb_psector_id is not None:
        psector_id = tools_qt.get_combo_value(None, cmb_psector_id)

    # If cmb changed and psector mode is disabled
    if not force_change and cmb_changed and enable:
        return

    if not force_change and psector_id in (None, ""):
        return

    # If cmb changed and psector mode is enabled, don't change the buttons
    if force_change or not (cmb_changed and not enable):
        _change_plan_mode_buttons(enable=enable, psector_id=psector_id, update_cmb_psector_id=force_change, cmb_changed=cmb_changed)

    if do_call_fct:
        # Prepare the JSON body for gw_fct_set_toggle_current
        extras = f'"type": "psector", "id": "{psector_id}"'
        body = create_body(extras=extras)

        # Execute the stored procedure
        result_selector = execute_procedure("gw_fct_set_toggle_current", body)
        global_vars.psignals['psector_id'] = psector_id if enable or cmb_changed else None

        # Set selectors
        extras = f'"selectorType":"selector_basic", "tabName":"tab_psector", "id":"{psector_id}", "isAlone":"False", "value":"True", "addSchema":"NULL"'
        body = create_body(extras=extras)
        execute_procedure("gw_fct_setselectors", body)

        # Refresh selectors
        extras = '"selectorType":"selector_basic", "filterText":""'
        body = create_body(extras=extras)
        execute_procedure("gw_fct_getselectors", body)

        # Set label for current psector
        kwargs = {
            "dialog": "__self__.dlg_psector_mng",
            "result": result_selector
        }
        execute_class_function(GwPsectorManagerUi, "set_label_current_psector", kwargs)

        refresh_selectors()

    # Apply psector styles only when pressing the play/pause button
    if not cmb_changed or (force_change and enable != active):
        _manage_psector_layer_styles(enable)

    # Refresh map canvas
    tools_qgis.refresh_map_canvas()


def _manage_psector_layer_styles(enable: bool) -> None:
    """
    Manage layer styles when psector mode is toggled.

    Args:
        enable (bool): If True, saves current styles and applies psector styles.
            If False, restores previously saved styles.
    """

    disable_forced_style = get_config_value('plan_psector_disable_forced_style')
    # Only do this if the config value is set and is not disabled
    if disable_forced_style is not None and not tools_os.set_boolean(disable_forced_style[0], False):
        if enable:
            last_styles = {}
            project_layers = global_vars.iface.mapCanvas().layers()
            for lyr in project_layers:
                try:
                    style_manager = lyr.styleManager()
                    current_style = style_manager.currentStyle()
                    src_name = tools_qgis.get_layer_source_table_name(lyr)
                    last_styles[src_name] = current_style
                except Exception:
                    continue
            global_vars.psignals['last_styles'] = last_styles
            apply_styles_to_layers(110, "GwPlan")
        else:
            last_styles = global_vars.psignals['last_styles']
            for lyr in last_styles:
                layer = tools_qgis.get_layer_by_tablename(lyr)
                try:
                    style_manager = layer.styleManager()
                    style_manager.setCurrentStyle(last_styles[lyr])
                except Exception:
                    continue


def _change_plan_mode_buttons(enable, psector_id, update_cmb_psector_id=False, cmb_changed=False):
    """ Change plan mode buttons """

    psignals_widgets = global_vars.psignals['widgets']
    btn_psector_playpause = psignals_widgets[0]
    cmb_psector_id = psignals_widgets[1]

    # Update play/pause button
    btn_psector_playpause.setProperty('psector_active', enable)
    add_icon(btn_psector_playpause, "74" if enable else "73", f"toolbars{os.sep}status")
    # Update psector status information
    global_vars.psignals['psector_active'] = enable

    # Change 'edit' buttons icons
    if enable is not None and global_vars.load_project is not None:
        buttons = global_vars.load_project.buttons
        for key, button in buttons.items():  # NOTE: could be improved having a list with only the buttons to change
            if key in (None, 'None'):
                continue
            toolbar_id = button.gw_name
            icon_path = f"{key}p" if enable else f"{key}"
            icon = get_icon(icon_path, f"toolbars{os.sep}{toolbar_id}", log_info=False)
            if icon:
                button.action.setIcon(icon)

    # Update cmb_psector_id if needed
    if update_cmb_psector_id and cmb_psector_id is not None:
        fill_cmb_psector_id(cmb_psector_id, psector_id)
        global_vars.psignals['psector_id'] = psector_id if enable or cmb_changed else None


def fill_cmb_psector_id(cmb_psector_id, psector_id=None):
    """ Fill cmb_psector_id """
    sql = "SELECT psector_id as id, name as idval FROM v_ui_plan_psector WHERE archived = false ORDER BY id ASC"
    rows = tools_db.get_rows(sql)
    disconnect_signal("psignals", "fill_cmb_psector_id_currentIndexChanged_manage_psector_change")
    tools_qt.fill_combo_values(cmb_psector_id, rows)
    if psector_id is not None:
        tools_qt.set_combo_value(cmb_psector_id, psector_id, 0, add_new=False)
    connect_signal(cmb_psector_id.currentIndexChanged, partial(manage_psector_change, cmb_psector_id),
                   "psignals", "fill_cmb_psector_id_currentIndexChanged_manage_psector_change"
    )


def manage_psector_change(cmb_psector, index):
    """ Manage psector change """
    psector_id = tools_qt.get_combo_value(None, cmb_psector)
    set_psector_mode_enabled(psector_id=psector_id)


def create_sqlite_conn(file_name):
    """ Creates an sqlite connection to a file """

    status = False
    cursor = None
    try:
        db_path = f"{lib_vars.plugin_dir}{os.sep}resources{os.sep}gis{os.sep}{file_name}.sqlite"
        tools_log.log_info(db_path)
        if os.path.exists(db_path):
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            status = True
        else:
            msg = "Config database file not found"
            tools_log.log_warning(msg, parameter=db_path)
    except Exception as e:
        tools_log.log_warning(str(e))

    return status, cursor


def manage_user_config_folder(user_folder_dir):
    """ Check if user config folder exists. If not create empty files init.config and session.config """

    try:
        config_folder = f"{user_folder_dir}{os.sep}core{os.sep}config{os.sep}"
        if not os.path.exists(config_folder):
            msg = "Creating user config folder: {0}"
            msg_params = (config_folder,)
            tools_log.log_info(msg, msg_params=msg_params)
            os.makedirs(config_folder)

        # Check if config files exists. If not create them empty
        filepath = f"{config_folder}{os.sep}init.config"
        if not os.path.exists(filepath):
            open(filepath, 'a').close()
        filepath = f"{config_folder}{os.sep}session.config"
        if not os.path.exists(filepath):
            open(filepath, 'a').close()

    except Exception as e:
        msg = "{0}: {1}"
        msg_params = ("manage_user_config_folder", e,)
        tools_log.log_warning(msg, msg_params=msg_params)


def check_old_userconfig(user_folder_dir):
    """ Function to transfer user configuration from version 3.5.023 or older to new `.../core/` folder """

    # Move all files in old config folder to new core config folder
    old_folder_path = f"{user_folder_dir}{os.sep}config"
    if os.path.exists(old_folder_path):
        for file in os.listdir(old_folder_path):
            old = f"{old_folder_path}{os.sep}{file}"
            new = f"{user_folder_dir}{os.sep}core{os.sep}config{os.sep}{file}"
            if os.path.exists(new):
                os.remove(new)
            os.rename(old, new)
        os.removedirs(old_folder_path)

    # Remove old log folder
    old_folder_path = f"{user_folder_dir}{os.sep}log"
    if os.path.exists(old_folder_path):
        for file in os.listdir(old_folder_path):
            path = f"{old_folder_path}{os.sep}{file}"
            os.remove(path)
        os.removedirs(old_folder_path)


def _is_empty_config_value(value) -> bool:
    """ True when a config value is unset: missing, None, empty, or the literal 'None'. """
    if value is None:
        return True
    return str(value).split('#')[0].strip() in ('None', '')


def _split_inventory_section(section: str):
    """ Split 'init.toolbars_position' into ('init', 'toolbars_position'). """
    parts = section.split('.', 1)
    if len(parts) != 2:
        return None, None
    return parts[0], parts[1]


def _parse_inventory_key(inv_key: str):
    """
    Parse a key from user_params.config (inventory).
    Leading '_' means: default for ws_/ud_ prefixed keys in init/session.
    Returns (config_parameter, apply_project_prefix) or (None, False) for invalid keys.
    """
    if inv_key.startswith('#'):
        return None, False
    if inv_key.startswith('_'):
        return inv_key[1:], True
    return inv_key, False


def _inventory_key_for_user_param(parameter: str, prefix: bool) -> str:
    """ Map a runtime user-config parameter to its inventory key in user_params.config. """
    if prefix and global_vars.project_type is not None:
        if parameter.startswith('_'):
            return parameter
        return f"_{parameter}"
    return parameter


def get_user_config_or_default(file_name: str, section: str, parameter: str):
    """
    Read a user config value (init/session), falling back to user_params inventory defaults.
    Inventory lookup order: _parameter (generic), ws_parameter, ud_parameter.
    """
    value = get_config_parser(section, parameter, "user", file_name, prefix=True, get_none=False,
                              chk_user_params=False)
    if not _is_empty_config_value(value):
        return value

    inv_section = f"{file_name}.{section}"
    for inv_key in (f"_{parameter}", f"ws_{parameter}", f"ud_{parameter}"):
        default = get_config_parser(inv_section, inv_key, "project", "user_params", prefix=False,
                                    chk_user_params=False, get_none=False)
        if not _is_empty_config_value(default):
            return default
    return None


def user_params_to_userconfig():
    """ Seed init.config / session.config from user_params.config inventory defaults. """

    parser = global_vars.configs['user_params'][1]
    if parser is None:
        return

    try:
        for inv_section in parser.sections():
            file_name, section_name = _split_inventory_section(inv_section)
            if file_name is None:
                continue

            for inv_key in parser.options(inv_section):
                config_param, apply_prefix = _parse_inventory_key(inv_key)
                if config_param is None:
                    continue
                if apply_prefix and global_vars.project_type is None:
                    continue

                current = get_config_parser(section_name, config_param, "user", file_name,
                                            apply_prefix, True, False, True)

                if _is_empty_config_value(current):
                    default = get_config_parser(inv_section, inv_key, "project", "user_params",
                                                False, True, False, True)
                    if _is_empty_config_value(default):
                        continue
                    set_config_parser(section_name, config_param, default, "user", file_name,
                                      None, apply_prefix, False)
                else:
                    inv_value = get_config_parser(inv_section, inv_key, "project", "user_params",
                                                  False, True, False, True)
                    if inv_value and "#" not in current and "#" in inv_value:
                        comment = inv_value.split('#')[1]
                        set_config_parser(section_name, config_param, current.strip(), "user", file_name,
                                          comment, apply_prefix, False)
    except Exception:
        pass


def recreate_config_files():
    filenames = ['init', 'session']

    for filename in filenames:
        filepath = f"{lib_vars.user_folder_dir}{os.sep}core{os.sep}config{os.sep}{filename}.config"
        if os.path.exists(filepath):
            now = datetime.now()
            now = now.strftime("%d%m%Y-%H%M%S")
            bak_filename = f"{filepath}_{now}.bak"
            if os.path.exists(bak_filename):
                os.remove(bak_filename)
            os.rename(filepath, bak_filename)

    _restore_user_params_config()
    manage_user_config_folder(lib_vars.user_folder_dir)
    initialize_parsers()
    user_params_to_userconfig()


def _make_config_parser():
    """ Create a ConfigParser with Giswater config conventions. """
    return configparser.ConfigParser(comment_prefixes=";", allow_no_value=True, strict=False)


def _try_read_config_path(filepath):
    """ Read a config file; return parser on success or None if unreadable. """
    parser = _make_config_parser()
    try:
        parser.read(filepath)
        return parser
    except Exception:
        return None


def _write_config_parser(path, parser):
    """ Write parser to disk. For user_params, validate round-trip before persisting. """
    # Never mutate the plugin-bundled user_params template (GwDevMode reads from plugin_dir)
    if (global_vars.gw_dev_mode and path and lib_vars.plugin_dir
            and path.endswith(f"{os.sep}user_params.config")
            and os.path.normpath(path).startswith(os.path.normpath(lib_vars.plugin_dir))):
        msg = "{0}: Refusing to write plugin user_params.config while GwDevMode is enabled"
        msg_params = ("_write_config_parser",)
        tools_log.log_warning(msg, msg_params=msg_params)
        return False

    buffer = io.StringIO()
    parser.write(buffer)
    content = buffer.getvalue()

    if path.endswith(f"{os.sep}user_params.config"):
        test_parser = _make_config_parser()
        try:
            test_parser.read_file(io.StringIO(content))
        except Exception as e:
            msg = "{0}: Refusing to write invalid user_params.config [{1}]: {2}"
            msg_params = ("_write_config_parser", type(e).__name__, e)
            tools_log.log_warning(msg, msg_params=msg_params)
            return False

    with open(path, 'w') as configfile:
        configfile.write(content)
    return True


def _restore_user_params_config():
    """ Restore user_params.config from plugin template when the user copy is unreadable. """
    if global_vars.gw_dev_mode:
        return

    user_filepath = f"{lib_vars.user_folder_dir}{os.sep}core{os.sep}config{os.sep}user_params.config"
    src = f"{lib_vars.plugin_dir}{os.sep}config{os.sep}user_params.config"
    if not os.path.exists(src):
        return

    if os.path.exists(user_filepath) and _try_read_config_path(user_filepath) is not None:
        return

    if os.path.exists(user_filepath):
        now = datetime.now().strftime("%d%m%Y-%H%M%S")
        bak_filename = f"{user_filepath}_{now}.bak"
        if os.path.exists(bak_filename):
            os.remove(bak_filename)
        os.rename(user_filepath, bak_filename)

    os.makedirs(os.path.dirname(user_filepath), exist_ok=True)
    shutil.copyfile(src, user_filepath)


def remove_deprecated_config_vars():
    """ Removes all deprecated variables defined at giswater.config """

    if lib_vars.user_folder_dir is None:
        return

    init_parser = configparser.ConfigParser(comment_prefixes=";", allow_no_value=True, strict=False)
    session_parser = configparser.ConfigParser(comment_prefixes=";", allow_no_value=True, strict=False)
    path_folder = os.path.join(tools_os.get_datadir(), lib_vars.user_folder_dir)
    project_types = get_config_parser('system', 'project_types', "project", "giswater").split(',')

    # Remove deprecated sections for init
    path = f"{path_folder}{os.sep}core{os.sep}config{os.sep}init.config"
    if not os.path.exists(path):
        msg = "File not found: {0}"
        msg_params = (path,)
        tools_log.log_warning(msg, msg_params=msg_params)
        return

    try:
        init_parser.read(path)
        vars = get_config_parser('system', 'deprecated_section_init', "project", "giswater")
        if vars is not None:
            for var in vars.split(','):
                section = var.split('.')[0].strip()
                if not init_parser.has_section(section):
                    continue
                init_parser.remove_section(section)

        with open(path, 'w') as configfile:
            init_parser.write(configfile)
            configfile.close()
    except Exception:
        pass

    # Remove deprecated sections for session
    path = f"{path_folder}{os.sep}core{os.sep}config{os.sep}session.config"
    if not os.path.exists(path):
        msg = "File not found: {0}"
        msg_params = (path,)
        tools_log.log_warning(msg, msg_params=msg_params)
        return

    try:
        session_parser.read(path)
        vars = get_config_parser('system', 'deprecated_section_session', "project", "giswater")
        if vars is not None:
            for var in vars.split(','):
                section = var.split('.')[0].strip()
                if not session_parser.has_section(section):
                    continue
                session_parser.remove_section(section)

        with open(path, 'w') as configfile:
            session_parser.write(configfile)
            configfile.close()
    except Exception:
        pass

    # Remove deprecated vars for init
    path = f"{path_folder}{os.sep}core{os.sep}config{os.sep}init.config"
    if not os.path.exists(path):
        msg = "File not found: {0}"
        msg_params = (path,)
        tools_log.log_warning(msg, msg_params=msg_params)
        return

    try:
        init_parser.read(path)
        vars = get_config_parser('system', 'deprecated_vars_init', "project", "giswater")
        if vars is not None:
            for var in vars.split(','):
                section = var.split('.')[0].strip()
                if not init_parser.has_section(section):
                    continue
                option = var.split('.')[1].strip()
                if option.startswith('_'):
                    for proj in project_types:
                        init_parser.remove_option(section, f"{proj}{option}")
                else:
                    init_parser.remove_option(section, option)

        with open(path, 'w') as configfile:
            init_parser.write(configfile)
            configfile.close()
    except Exception:
        pass

    # Remove deprecated vars for session
    path = f"{path_folder}{os.sep}core{os.sep}config{os.sep}session.config"
    if not os.path.exists(path):
        msg = "File not found: {0}"
        msg_params = (path,)
        tools_log.log_warning(msg, msg_params=msg_params)
        return

    try:
        session_parser.read(path)
        vars = get_config_parser('system', 'deprecated_vars_session', "project", "giswater")
        if vars is not None:
            for var in vars.split(','):
                section = var.split('.')[0].strip()
                if not session_parser.has_section(section):
                    continue
                option = var.split('.')[1].strip()
                if option.startswith('_'):
                    for proj in project_types:
                        session_parser.remove_option(section, f"{proj}{option}")
                else:
                    session_parser.remove_option(section, option)

        with open(path, 'w') as configfile:
            session_parser.write(configfile)
            configfile.close()
    except Exception:
        pass


def hide_widgets_form(dialog, dlg_name):

    row = get_config_value(parameter=f'qgis_form_{dlg_name}_hidewidgets', columns='value::text', table='config_param_system')
    if row:
        widget_list = dialog.findChildren(QWidget)
        for widget in widget_list:
            if widget.objectName() and f'"{widget.objectName()}"' in row[0]:
                lbl_widget = dialog.findChild(QLabel, f"lbl_{widget.objectName()}")
                if lbl_widget:
                    lbl_widget.setVisible(False)
                widget.setVisible(False)


def get_project_version(schemaname=None):
    """ Get project version from table 'sys_version' """

    if schemaname in (None, 'null', ''):
        schemaname = lib_vars.schema_name

    project_version = None
    tablename = "sys_version"
    exists = tools_db.check_table(tablename, schemaname)
    if not exists:
        msg = "Table not found"
        tools_qgis.show_warning(msg, parameter=tablename)
        return None

    sql = f"SELECT giswater FROM {schemaname}.{tablename} ORDER BY id DESC LIMIT 1"
    row = tools_db.get_row(sql)
    if row:
        project_version = row[0]

    return project_version


def export_layers_to_gpkg(layers, path):
    """ This function is not used on Giswater Project at the moment. """

    uri = tools_db.get_uri()
    schema_name = tools_db.dao_db_credentials['schema'].replace('"', '')
    is_first = True
    options = QgsVectorFileWriter.SaveVectorOptions()
    options.driverName = "GPKG"

    for layer in layers:

        uri.setDataSource(schema_name, f"{layer['name']}", "the_geom", None, f"{layer['id']}")
        vlayer = QgsVectorLayer(uri.uri(), f"{layer['name']}", 'postgres')

        if is_first:
            options.layerName = vlayer.name()
            QgsVectorFileWriter.writeAsVectorFormatV2(vlayer, path, QgsCoordinateTransformContext(), options)
            is_first = False
        else:
            # switch mode to append layer instead of overwriting the file
            options.actionOnExistingFile = QgsVectorFileWriter.ActionOnExistingFile.CreateOrOverwriteLayer
            options.layerName = vlayer.name()
            QgsVectorFileWriter.writeAsVectorFormatV2(vlayer, path, QgsCoordinateTransformContext(), options)


def refresh_all_styles(dialog=None):
    """Refresh all styles in the database based on the current QGIS layer styles."""
    try:
        # Get all loaded layers in the project
        loaded_layers = global_vars.iface.mapCanvas().layers()
        set_styles = set()

        for layer in loaded_layers:
            style_manager = layer.styleManager()
            # Get all loaded styles in the layer
            available_styles = style_manager.styles()
            for style_name in available_styles:
                set_styles.add(style_name)

        for style in set_styles:
            sql_get_id = (
                f"SELECT id FROM {lib_vars.schema_name}.config_style "
                f"WHERE idval = '{style}';"
            )
            styleconfig_id = tools_db.get_row(sql_get_id)

            if styleconfig_id:
                # Apply the style with force_refresh=True
                apply_styles_to_layers(styleconfig_id[0], style, force_refresh=True)
            # TODO: show message of all refreshed styles
            # msg = f"Style '{style}' not found in database."
            # tools_qgis.show_warning(msg, dialog=self.style_mng_dlg)

        msg = "All layers have been successfully refreshed."
        tools_qgis.show_success(msg, dialog=dialog)

    except Exception as e:
        msg = "Database Error"
        param = str(e)
        tools_qgis.show_warning(msg, dialog=dialog, parameter=param)


# region compatibility QGIS version functions

def set_snapping_type(layer_settings, value):

    layer_settings.setTypeFlag(value)


def get_segment_flag(default_value):

    segment_flag = Qgis.SnappingType.Segment

    return segment_flag


def get_vertex_flag(default_value):

    vertex_flag = Qgis.SnappingType.Vertex

    return vertex_flag


def get_sysversion_addparam():
    """ Gets addparam field from table sys_version """

    if not tools_db.check_column('sys_version', 'addparam'):
        return None

    sql = "SELECT addparam FROM sys_version ORDER BY id DESC limit 1"
    row = tools_db.get_row(sql, is_admin=True)

    if row:
        return row[0]

    return None


def create_giswater_menu(project_loaded=False):
    """ Create Giswater menu """
    if global_vars.load_project_menu is None:
        global_vars.load_project_menu = GwMenuLoad()
    global_vars.load_project_menu.read_menu(project_loaded)


def unset_giswater_menu():
    """ Unset Giswater menu (when plugin is disabled or reloaded) """

    menu_giswater = global_vars.iface.mainWindow().menuBar().findChild(QMenu, "Giswater")
    if menu_giswater not in (None, "None"):
        menu_giswater.clear()  # I think it's good to clear the menu before deleting it, just in case
        menu_giswater.deleteLater()
        global_vars.load_project_menu = None


def reset_position_dialog(show_message=False, plugin='core', file_name='session'):
    """ Reset position dialog x/y """

    try:
        parser = configparser.ConfigParser(comment_prefixes=';', allow_no_value=True, strict=False)
        config_folder = f"{lib_vars.user_folder_dir}{os.sep}{plugin}{os.sep}config"

        if not os.path.exists(config_folder):
            os.makedirs(config_folder)
        path = f"{config_folder}{os.sep}{file_name}.config"
        parser.read(path)
        # Check if section exists in file
        if "dialogs_position" in parser:
            parser.remove_section("dialogs_position")

        msg = "Reset position form done successfully."
        if show_message:
            tools_qt.show_info_box(msg, "Info")

        with open(path, 'w') as configfile:
            parser.write(configfile)
            configfile.close()
    except Exception as e:
        msg = "{0} exception [{1}]: {2}"
        msg_params = ("reset_position_dialog", type(e).__name__, e,)
        tools_log.log_warning(msg, msg_params=msg_params)
        return

# endregion


# region private functions
def _insert_feature(dialog, relation_id, relation_type, feature_type, ids=None, extra_cols=None):
    """ Universal function to insert features into any relation table using generalized function """
    if not ids:
        return

    if not relation_id:
        msg = f"{relation_type.title()} ID is missing."
        tools_qgis.show_warning(msg)
        return

    # Toggle audit and topocontrol off during bulk insert for performance (only for campaign)
    audit_toggled = False
    topocontrol_toggled = False
    try:
        if relation_type == 'campaign':
            # Check if audit is enabled and temporarily disable it for performance
            cur_user = tools_db.get_current_user()
            audit_result = tools_db.get_row(f"SELECT value FROM config_param_user WHERE parameter = 'audit_function' AND cur_user = '{cur_user}'")

            if audit_result and audit_result[0] == 'true':
                audit_toggled = True
                tools_db.execute_sql(
                    f"""
                    INSERT INTO config_param_user (parameter, value, cur_user)
                    VALUES ('audit_function', 'false', '{cur_user}')
                    ON CONFLICT (parameter, cur_user) DO UPDATE SET value='false';
                    """
                )

            # Toggle topocontrol off during bulk insert for performance (only for arc/node)
            if tools_db.check_schema('cm') and feature_type in ('arc', 'node'):
                tools_db.execute_sql(
                    """
                    INSERT INTO cm.config_param_user(parameter, value, cur_user)
                    VALUES ('edit_disable_topocontrol','true', current_user)
                    ON CONFLICT (parameter, cur_user) DO UPDATE SET value='true';
                    """
                )
                topocontrol_toggled = True

        if ids:
            ids_array = "ARRAY[" + ",".join(str(id) for id in ids) + "]"
            parameters = f"{relation_id}, '{relation_type}', '{feature_type}', {ids_array}"
            if extra_cols:
                parameters += f", '{extra_cols}'"
            execute_procedure('gw_fct_manage_inserts_by_ids', parameters)

    finally:
        # Re-enable audit if it was disabled
        if audit_toggled:
            tools_db.execute_sql(
                f"""
                UPDATE config_param_user
                SET value='true'
                WHERE parameter='audit_function' AND cur_user='{cur_user}';
                """
            )

        # Re-enable topocontrol if it was disabled
        if topocontrol_toggled:
            tools_db.execute_sql(
                """
                UPDATE cm.config_param_user
                SET value='false'
                WHERE parameter='edit_disable_topocontrol' AND cur_user=current_user;
                """
            )


def load_tableview_campaign(dialog, feature_type, campaign_id, layers):
    """
    Reload QTableView for campaign_x_<feature_type> safely, avoiding recursive selectionChanged loop.
    """
    if not campaign_id:
        msg = "Campaign ID not found."
        tools_qgis.show_warning(msg)
        return

    class_object = dialog.parent()
    if getattr(class_object, "signal_selectionChanged", False):
        return  # Avoid recursion if triggered by selectionChanged
    class_object.signal_selectionChanged = True

    try:
        expr = f"campaign_id = '{campaign_id}'"
        qtable = tools_qt.get_widget(dialog, f'tbl_campaign_x_{feature_type}')
        tablename = qtable.property('tablename') or f"cm.om_campaign_x_{feature_type}"

        message = tools_qt.fill_table(qtable, f"{tablename}", expr, QSqlTableModel.EditStrategy.OnFieldChange, schema_name='cm')

        # Get ids from qtable (that will only mark the ones wanted in snapping)
        feature_id_column = f"{feature_type}_id"
        feature_ids = get_ids_from_qtable(qtable, feature_id_column)

        if feature_ids:
            expr = QgsExpression(f"{feature_id_column} IN ({','.join(feature_ids)})")
            tools_qgis.select_features_by_ids(feature_type, expr, layers=layers)

        if message:
            tools_qgis.show_warning(message)

        set_tablemodel_config(dialog, qtable, tablename)

    finally:
        class_object.signal_selectionChanged = False


def get_cm_user_role():
    """Get user's CM role only when user and DB have CM access.

    - Skip entirely if schema doesn't exist or user lacks USAGE on it.
    - Avoid UI error popups by using is_admin=True on low-level queries.
    - Prefer role-membership short-circuit to avoid touching CM tables when unnecessary.
    """

    # Check schema exists
    if not tools_db.check_schema('cm'):
        return None

    # Check current_user can use CM schema
    has_usage = tools_db.get_row(
        "SELECT has_schema_privilege(current_user, 'cm', 'USAGE')",
        is_admin=True,
    )
    if not has_usage or not has_usage[0]:
        return None

    # If user has no CM-related roles, skip table queries
    cm_roles = tools_db.get_row(
        """
        SELECT EXISTS (
            SELECT 1
            FROM pg_auth_members am
            JOIN pg_roles r_user ON am.member = r_user.oid
            JOIN pg_roles r_role ON am.roleid = r_role.oid
            WHERE r_user.rolname = current_user
              AND r_role.rolname ILIKE 'role_cm%%'
        )
        """,
        is_admin=True,
    )
    if not cm_roles or not cm_roles[0]:
        return None

    # Ensure SELECT on the two CM tables before querying
    can_sel_user = tools_db.get_row(
        "SELECT has_table_privilege(current_user, 'cm.cat_user', 'SELECT')",
        is_admin=True,
    )
    can_sel_team = tools_db.get_row(
        "SELECT has_table_privilege(current_user, 'cm.cat_team', 'SELECT')",
        is_admin=True,
    )
    if not can_sel_user or not can_sel_user[0] or not can_sel_team or not can_sel_team[0]:
        return None

    # Try with username first, fallback to loginname; suppress popups
    sql = (
        f"""
        SELECT t.role_id
        FROM cm.cat_user AS u
        JOIN cm.cat_team AS t ON u.team_id = t.team_id
        WHERE u.username = '{tools_db.get_current_user()}'
        """
    )
    result = tools_db.get_row(sql, is_admin=True)
    if result:
        return result

    sql = (
        f"""
        SELECT t.role_id
        FROM cm.cat_user AS u
        JOIN cm.cat_team AS t ON u.team_id = t.team_id
        WHERE u.loginname = '{tools_db.get_current_user()}'
        """
    )
    result = tools_db.get_row(sql, is_admin=True)
    return result if result else None


def get_ids_from_qtable(qtable, id_column):
    """ Get all IDs from a QTableView model for the given column """
    ids = []
    model = qtable.model()

    if model is None:
        return ids

    for row in range(model.rowCount()):
        index = model.index(row, model.fieldIndex(id_column))
        value = model.data(index)
        if value is not None:
            ids.append(str(value))

    return ids


def _delete_feature_campaign(dialog, feature_type, list_id, campaign_id, state=None):
    """ Delete features_id to table plan_@feature_type_x_psector"""
    widget = tools_qt.get_widget(dialog, f"tbl_campaign_x_{feature_type}")
    tablename = widget.property('tablename') or f"cm.om_campaign_x_{feature_type}"

    sql = (f"DELETE FROM {tablename} "
           f"WHERE {feature_type}_id IN ({list_id}) AND campaign_id = '{campaign_id}'")
    # Add state if needed
    if state is not None:
        sql += f""" AND "state" = '{state}'"""
    tools_db.execute_sql(sql)


def load_tableview_lot(dialog, feature_type, lot_id, layers, ids=None):
    """Reload QTableView for campaign_lot_x_<feature_type> safely, avoiding recursive selectionChanged loop."""

    if not lot_id:
        tools_qgis.show_warning("Lot ID not found.")
        return

    class_object = dialog.parent()
    if getattr(class_object, "signal_selectionChanged", False):
        return  # Avoid recursion if triggered by selectionChanged
    class_object.signal_selectionChanged = True

    try:
        expr = f"lot_id = '{lot_id}'"

        table_widget_name = f'tbl_campaign_lot_x_{feature_type}'
        qtable = tools_qt.get_widget(dialog, table_widget_name)

        tablename = qtable.property('tablename') or f"cm.om_campaign_lot_x_{feature_type}"
        message = tools_qt.fill_table(qtable, tablename, expr, QSqlTableModel.EditStrategy.OnFieldChange, schema_name='cm')

        # Get ids from qtable (used for selection in snapping)
        feature_id_column = f"{feature_type}_id"
        feature_ids = get_ids_from_qtable(qtable, feature_id_column)

        if feature_ids:
            expr = QgsExpression(f"{feature_id_column} IN ({','.join(feature_ids)})")
            tools_qgis.select_features_by_ids(feature_type, expr, layers=layers)

        if message:
            tools_qgis.show_warning(message)

        set_tablemodel_config(dialog, qtable, tablename)

    finally:
        class_object.signal_selectionChanged = False


def _delete_feature_lot(dialog, feature_type, list_id, lot_id, state=None):
    """ Delete features_id to table plan_@feature_type_x_psector"""
    widget = tools_qt.get_widget(dialog, f"tbl_campaign_lot_x_{feature_type}")
    tablename = widget.property('tablename') or f"cm.om_campaign_lot_x_{feature_type}"

    # Set action=4 so BEFORE DELETE trigger allows hard delete (vs soft-delete to action=3)
    sql = (f"UPDATE {tablename} SET action = 4 "
           f"WHERE {feature_type}_id IN ({list_id}) AND lot_id = '{lot_id}'")
    if state is not None:
        sql += f""" AND "state" = '{state}'"""
    tools_db.execute_sql(sql)

    sql = (f"DELETE FROM {tablename} "
           f"WHERE {feature_type}_id IN ({list_id}) AND lot_id = '{lot_id}'")
    # Add state if needed
    if state is not None:
        sql += f""" AND "state" = '{state}'"""
    tools_db.execute_sql(sql)


def delete_feature_visit(dialog, visit_id, rel_feature_type, list_id=None):
    """ Delete features_id to table tbl_visit_x_@rel_feature_type """
    sql = f"DELETE FROM om_visit_x_{rel_feature_type} WHERE visit_id = '{visit_id}'"
    if list_id is not None:
        sql += f" AND {rel_feature_type}_id in ({list_id})"
    tools_db.execute_sql(sql)


def _delete_feature_psector(dialog, feature_type, list_id, state=None):
    """ Delete features_id to table plan_@feature_type_x_psector"""

    widget = tools_qt.get_widget(dialog, f"tbl_psector_x_{feature_type}")
    tablename = widget.property('tablename')
    value = tools_qt.get_text(dialog, "tab_general_psector_id")

    sql = (f"DELETE FROM {tablename} "
           f"WHERE {feature_type}_id IN ({list_id}) AND psector_id = '{value}'")
    # Add state if needed
    if state is not None:
        sql += f""" AND "state" = '{state}'"""
    tools_db.execute_sql(sql)


def _check_user_params(section, parameter, file_name, prefix=False):
    """ Ensure parameter exists in user_params.config inventory; create it with None if missing.

    In GwDevMode the inventory is the plugin template — never auto-create keys there
    (would dirty the git checkout). Only seed missing keys in the user-folder copy.
    """

    if section == "i18n_generator" or parameter == "dev_commit":
        return

    inv_key = _inventory_key_for_user_param(parameter, prefix)
    inv_section = f"{file_name}.{section}"

    # get_none=True so "None #comment" is not treated as missing
    check_value = get_config_parser(inv_section, inv_key, "project", "user_params", False,
                                    get_comment=True, chk_user_params=False, get_none=True)

    if check_value is None:
        for typed_key in (f"ws_{inv_key.lstrip('_')}", f"ud_{inv_key.lstrip('_')}"):
            check_value = get_config_parser(inv_section, typed_key, "project", "user_params", False,
                                            get_comment=True, chk_user_params=False, get_none=True)
            if check_value is not None:
                break

    if check_value is None:
        if global_vars.gw_dev_mode:
            return None
        set_config_parser(inv_section, inv_key, None, "project", "user_params", prefix=False,
                          chk_user_params=False)
    else:
        return check_value


def _get_parser_from_filename(filename):
    """ Get parser of file @filename.config """

    if filename in ('init', 'session'):
        folder = f"{lib_vars.user_folder_dir}{os.sep}core"
    elif filename in ('dev', 'giswater'):
        folder = lib_vars.plugin_dir
    elif filename == 'user_params':
        folder = lib_vars.plugin_dir if global_vars.gw_dev_mode else f"{lib_vars.user_folder_dir}{os.sep}core"
    else:
        return None, None

    parser = _make_config_parser()
    filepath = f"{folder}{os.sep}config{os.sep}{filename}.config"
    if not os.path.exists(filepath):
        msg = "File not found: {0}"
        msg_params = (filepath,)
        tools_log.log_warning(msg, msg_params=msg_params)
        return filepath, None

    try:
        parser.read(filepath)
    except (configparser.DuplicateSectionError, configparser.DuplicateOptionError, configparser.ParsingError) as e:
        msg = "Error parsing file: {0}"
        msg_params = (filepath,)
        tools_qgis.show_critical(msg, parameter=e, msg_params=msg_params)
        return filepath, None
    except Exception as e:
        msg = "Error parsing file: {0}"
        msg_params = (filepath,)
        tools_qgis.show_critical(msg, parameter=e, msg_params=msg_params)
        return filepath, None

    return filepath, parser


def _get_extent_parameters(schema_name, table_name="node", geom_name="the_geom"):
    """ Get extent parameters for a given schema """

    rectangle = None
    sql = (f"SELECT ST_XMax(gometries) AS xmax, ST_XMin(gometries) AS xmin, "
            f"ST_YMax(gometries) AS ymax, ST_YMin(gometries) AS ymin "
            f"FROM "
            f"(SELECT ST_Collect({geom_name}) AS gometries FROM {schema_name}.{table_name}) AS foo")
    row = tools_db.get_row(sql)
    if row:
        xmin = row["xmin"]
        xmax = row["xmax"]
        ymin = row["ymin"]
        ymax = row["ymax"]

        rectangle = QgsRectangle(xmin or -1.555992, ymin or -1.000000, xmax or 1.555992, ymax or 1.000000)

    return rectangle


def fill_tbl(complet_result, dialog, widgetname, linkedobject, filter_fields):
    """ Put filter widgets into layout and set headers into QTableView """

    complet_list = _get_list(complet_result, filter_fields, linkedobject)
    tab_name = 'tab_none'
    if complet_list in (False, None):
        return False, False
    data = complet_list['body']['data']
    headers = complet_list['body']['form'].get('headers')
    fields = data['fields']

    if data.get('hidden'):
        return False, False
    short_name = f'{tab_name}_{widgetname}' if tab_name not in widgetname else widgetname
    widget = dialog.findChild(QTableView, short_name)
    if widget is None:
        return False, False
    widget = add_tableview_header(widget, fields, headers)
    widget = fill_tableview_rows(widget, fields)
    widget = set_tablemodel_config(dialog, widget, short_name, Qt.SortOrder.DescendingOrder)
    tools_qt.set_tableview_config(widget, edit_triggers=QTableView.EditTrigger.DoubleClicked)

    widget_list = []
    widget_list.extend(dialog.findChildren(QComboBox, QRegularExpression(f"{tab_name}_")))
    widget_list.extend(dialog.findChildren(QTableView, QRegularExpression(f"{tab_name}_")))
    widget_list.extend(dialog.findChildren(QLineEdit, QRegularExpression(f"{tab_name}_")))
    widget_list.extend(dialog.findChildren(QSpinBox, QRegularExpression(f"{tab_name}_")))
    widget_list.extend(
        dialog.findChildren(QgsDateTimeEdit, QRegularExpression(f"{tab_name}_")))
    return complet_list, widget_list


def _get_list(complet_result, filter_fields='', linkedobject=''):

    if linkedobject is None:
        return
    # Create body
    extras = f'"tableName":"{linkedobject}"'
    body = create_body(filter_fields=filter_fields, extras=extras)
    # Execute procedure
    json_result = execute_procedure('gw_fct_getlist', body)
    if json_result is None or json_result['status'] == 'Failed':
        return False
    complet_list = json_result
    if not complet_list:
        return False

    return complet_list


def get_list(table_name, filter_name="", filter_id=None, filter_active=None, id_field=None):
    if id_field is None:
        id_field = "id_val"

    extras = f'"tableName":"{table_name}"'
    filter_fields = f'"limit": -1, "{id_field}": {{"filterSign":"ILIKE", "value":"{filter_name}"}}'

    if filter_id is not None:
        filter_fields += f', "{id_field}": {{"filterSign":"=", "value":"{filter_id}"}}'

    if filter_active is not None:
        filter_fields += f', "active": {{"filterSign":"=", "value":"{filter_active}"}}'

    body = create_body(filter_fields=filter_fields, extras=extras)
    json_result = execute_procedure('gw_fct_getlist', body)

    if json_result is None or json_result['status'] == 'Failed':
        return False

    complet_list = json_result
    if not complet_list:
        return False

    return complet_list


def populate_dynamic_widgets(dialog, complet_result, class_info):
    """Creates and populates all widgets dynamically into the dialog layout."""

    # Retrieve the tablename from the JSON response if available
    tablename = complet_result['body']['form'].get('tableName', 'default_table')
    old_widget_pos = 0

    # Loop through fields and add them to the appropriate layouts
    for field in complet_result['body']['data']['fields']:
        # Skip hidden fields
        if field.get('hidden'):
            continue

        # Pass required parameters (dialog, result, field, tablename, class_info)
        label, widget = set_widgets(dialog, complet_result, field, tablename, class_info)

        if widget is None:
            continue

        # Add widgets to the layout
        old_widget_pos = add_widget_combined(dialog, field, label, widget, old_widget_pos)

# endregion


# region Info buttons
def set_filter_listeners(complet_result, dialog, widget_list, columnname, widgetname, feature_id=None):
    """
    functions called in -> widget.textChanged.connect(partial(getattr(tools_backend_calls, widgetfunction), **kwargs))
                        -> widget.currentIndexChanged.connect(partial(getattr(tools_backend_calls, widgetfunction), **kwargs))
       module = tools_backend_calls -> def open_rpt_result(**kwargs)
                                    -> def filter_table(self, **kwargs)
     """

    model = None
    for widget in widget_list:
        if type(widget) is QTableView:
            model = widget.model()

    # Emitting the text changed signal of a widget slows down the process, so instead of emitting a signal for each
    # widget, we will emit only the one of the last widget. This is enough for the correct filtering of the
    # QTableView and we gain in performance
    last_widget = None
    for widget in widget_list:
        if widget.property('isfilter') is not True:
            continue
        module = tools_backend_calls
        functions = None
        if widget.property('widgetfunction') is not None and isinstance(widget.property('widgetfunction'), list):
            functions = []
            for function in widget.property('widgetfunction'):
                widgetfunction = function['functionName']
                if 'isFilter' in function:
                    if function['isFilter']:
                        functions.append(function)

        if widget.property('widgetfunction') is not None and 'functionName' in widget.property('widgetfunction'):
            widgetfunction = widget.property('widgetfunction')['functionName']
            functions = [widget.property('widgetfunction')]
        if widgetfunction is False:
            continue

        linkedobject = ""
        if widget.property('linkedobject') is not None:
            linkedobject = widget.property('linkedobject')

        if feature_id is None:
            feature_id = ""

        if isinstance(widget.property('widgetfunction'), list):
            widgetfunction = widget.property('widgetfunction')
        else:
            widgetfunction = [widget.property('widgetfunction')]

        for i in range(len(functions)):
            kwargs = {"complet_result": complet_result, "model": model, "dialog": dialog, "linkedobject": linkedobject,
                      "columnname": columnname, "widget": widget, "widgetname": widgetname, "widget_list": widget_list,
                      "feature_id": feature_id, "func_params": functions[i]['parameters']}

            if functions[i] is not None:
                if 'module' in functions[i]:
                    module = globals()[functions[i]['module']]
                function_name = functions[i].get('functionName')
                if function_name is not None:
                    if function_name:
                        exist = tools_os.check_python_function(module, function_name)
                        if not exist:
                            msg = "widget {0} has associated function {1}, but {2} not exist"
                            msg_params = (widget.property('widgetname'), function_name, function_name,)
                            tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, msg_params=msg_params)
                            return widget
                    else:
                        msg = "Parameter functionName is null for button"
                        tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=widget.objectName())

            func_params = ""
            function_name = ""
            if widgetfunction[i] is not None and 'functionName' in widgetfunction[i]:
                function_name = widgetfunction[i]['functionName']

                exist = tools_os.check_python_function(module, function_name)
                if not exist:
                    msg = "widget {0} has associated function {1}, but {2} not exist"
                    msg_params = (widget.property('widgetname'), function_name, function_name,)
                    tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, msg_params=msg_params)
                    return widget
                if 'parameters' in widgetfunction[i]:
                    func_params = widgetfunction[i]['parameters']

            kwargs['widget'] = widget
            kwargs['message_level'] = 1
            kwargs['function_name'] = function_name
            kwargs['func_params'] = func_params
            if function_name:
                if type(widget) is QLineEdit:
                    widget.textChanged.connect(partial(getattr(module, function_name), **kwargs))
                elif isinstance(widget, QComboBox):
                    widget.currentIndexChanged.connect(partial(getattr(module, function_name), **kwargs))
                elif isinstance(widget, QgsDateTimeEdit):
                    widget.setDate(QDate.currentDate())
                    widget.dateChanged.connect(partial(getattr(module, function_name), **kwargs))
                elif type(widget) is QSpinBox:
                    widget.valueChanged.connect(partial(getattr(module, function_name), **kwargs))
                else:
                    continue

            last_widget = widget

    # Emit signal changed
    if last_widget is not None:
        if type(last_widget) is QLineEdit:
            text = tools_qt.get_text(dialog, last_widget, False, False)
            last_widget.textChanged.emit(text)
        elif isinstance(last_widget, QComboBox):
            last_widget.currentIndexChanged.emit(last_widget.currentIndex())


def manage_dlg_widgets(class_object, dialog, complet_result):
    """ Creates and populates all the widgets, preserving original layout logic while ensuring two-column alignment """

    layout_orientations = {}
    pos_offset = 0

    # Retrieve layout orientations from the JSON response if provided
    for layout_name, layout_info in complet_result['body']['form']['layouts'].items():
        orientation = layout_info.get('lytOrientation')
        if orientation:
            layout_orientations[layout_name] = orientation

    current_layout = ""

    # Loop through fields to add them to the appropriate layout
    for field in complet_result['body']['data']['fields']:
        # Avoid error when field is None
        if field is None:
            continue
        # Skip hidden fields based on conditions
        if field.get('hidden'):
            continue

        # Create label and widget
        label, widget = set_widgets(dialog, complet_result, field, None, class_object)
        if widget is None:
            continue

        # Find the layout for the current field based on layoutname
        layout = dialog.findChild(QGridLayout, field['layoutname'])
        if layout is None:
            continue

        # Apply layout orientation if specified in JSON
        orientation = layout_orientations.get(layout.objectName(), "vertical")
        layout.setProperty('lytOrientation', orientation)

        if current_layout != field['layoutname']:
            current_layout = field['layoutname']
            pos_offset = 0

        # Add widget into layout
        pos_offset = add_widget_combined(dialog, field, label, widget, pos_offset)


def set_widgets(dialog, complet_result, field, tablename, class_info):
    """
    functions called in -> widget = getattr(self, f"manage_{field['widgettype']}")(**kwargs)
        def _manage_text(**kwargs)
        def manage_typeahead(self, **kwargs)
        def manage_combo(self, **kwargs)
        def manage_check(self, **kwargs)
        def manage_datetime(self, **kwargs)
        def manage_button(self, **kwargs)
        def manage_hyperlink(self, **kwargs)
        def manage_hspacer(self, **kwargs)
        def manage_vspacer(self, **kwargs)
        def manage_textarea(self, **kwargs)
        def manage_spinbox(self, **kwargs)
        def manage_doubleSpinbox(self, **kwargs)
        def manage_tableview(self, **kwargs)
     """
    widget = None
    label = None

    # Skip widgets not supported
    widgettypes_not_supported = ["tabwidget", "divider"]
    if 'widgettype' in field and field['widgettype'] in widgettypes_not_supported:
        return label, widget

    if 'label' in field and field['label']:
        label = QLabel()
        label.setObjectName('lbl_' + field['widgetname'])
        label.setText(field['label'].capitalize())
        if 'stylesheet' in field and field['stylesheet'] is not None and 'label' in field['stylesheet']:
            label = set_stylesheet(field, label)
        if 'tooltip' in field:
            label.setToolTip(field['tooltip'])
        else:
            label.setToolTip(field['label'].capitalize())
        if 'widgetcontrols' in field and field['widgetcontrols'] is not None and 'labelSize' in field['widgetcontrols']:
            label.setFixedWidth(field['widgetcontrols']['labelSize'])

    if 'widgettype' in field and not field['widgettype']:
        msg = "The field widgettype is not configured for"
        param = f"formname:{tablename}, columnname:{field['columnname']}"
        tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=param, dialog=dialog)
        return label, widget

    if field['widgettype'] == 'label':
        return None, label  # Return the label as widget, and no label

    try:
        kwargs = {"dialog": dialog, "complet_result": complet_result, "field": field,
                  "class": class_info}
        widget = globals()[f"_manage_{field['widgettype']}"](**kwargs)
    except Exception as e:
        msg = "{0}: {1} Python function: tools_gw.set_widgets. WHERE columname='{2}' AND widgetname='{3}' AND widgettype='{4}'"
        msg_params = (type(e).__name__, e, field['columnname'], field['widgetname'], field['widgettype'],)
        tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, msg_params=msg_params)
        return label, widget

    try:
        widget.setProperty('isfilter', False)
        if 'isfilter' in field and field['isfilter'] is True:
            widget.setProperty('isfilter', True)

        widget.setProperty('widgetfunction', False)
        if 'widgetfunction' in field and field['widgetfunction'] is not None:
            widget.setProperty('widgetfunction', field['widgetfunction'])
        if 'linkedobject' in field and field['linkedobject']:
            widget.setProperty('linkedobject', field['linkedobject'])
        if field['widgetcontrols'] is not None and 'saveValue' in field['widgetcontrols']:
            if field['widgetcontrols']['saveValue'] is False:
                widget.setProperty('saveValue', False)
        if field['widgetcontrols'] is not None and 'isEnabled' in field['widgetcontrols']:
            if field['widgetcontrols']['isEnabled'] is False:
                if type(widget) in (QDoubleSpinBox, QLineEdit, QSpinBox, QTextEdit, GwHyperLinkLineEdit):
                    set_widget_readonly(widget, True)
                else:
                    widget.setEnabled(False)
    except Exception:
        # AttributeError: 'QSpacerItem' object has no attribute 'setProperty'
        pass

    return label, widget


def _manage_text(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
            widget = getattr(self, f"manage_{field['widgettype']}")(**kwargs)
    """

    field = kwargs['field']

    widget = add_lineedit(field)
    widget = set_widget_size(widget, field)
    widget = _set_min_max_values(widget, field)
    widget = _set_reg_exp(widget, field)
    widget = set_data_type(field, widget)
    widget = _set_max_length(widget, field)

    return widget


def _set_min_max_values(widget, field):
    """ Set max and min values allowed """

    if field['widgetcontrols'] and 'maxMinValues' in field['widgetcontrols']:
        if 'min' in field['widgetcontrols']['maxMinValues']:
            widget.setProperty('minValue', field['widgetcontrols']['maxMinValues']['min'])

    if field['widgetcontrols'] and 'maxMinValues' in field['widgetcontrols']:
        if 'max' in field['widgetcontrols']['maxMinValues']:
            widget.setProperty('maxValue', field['widgetcontrols']['maxMinValues']['max'])

    return widget


def _set_max_length(widget, field):
    """ Set max and min values allowed """

    if field['widgetcontrols'] and 'maxLength' in field['widgetcontrols']:
        if field['widgetcontrols']['maxLength'] is not None:
            widget.setProperty('maxLength', field['widgetcontrols']['maxLength'])

    return widget


def _set_reg_exp(widget, field):
    """ Set regular expression """

    if 'widgetcontrols' in field and field['widgetcontrols']:
        if field['widgetcontrols'] and 'regexpControl' in field['widgetcontrols']:
            if field['widgetcontrols']['regexpControl'] is not None:
                reg_exp = QRegularExpression(str(field['widgetcontrols']['regexpControl']))
                widget.setValidator(QRegularExpressionValidator(reg_exp))

    return widget


def _manage_typeahead(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
            widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
        """
    dialog = kwargs['dialog']
    field = kwargs['field']
    complet_result = kwargs['complet_result']
    if complet_result['body'].get('feature'):
        feature_id = complet_result['body']['feature'].get('id')
    else:
        feature_id = None
    completer = QCompleter()
    widget = _manage_text(**kwargs)
    widget = set_typeahead(field, dialog, widget, completer, feature_id)
    return widget


def _manage_combo(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
            widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
        """
    dialog = kwargs['dialog']
    field = kwargs['field']
    complet_result = kwargs['complet_result']
    class_info = kwargs['class']

    widget = add_combo(field, dialog, complet_result, class_info=class_info)
    widget = set_widget_size(widget, field)
    return widget


def _manage_multiple_checkbox(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
            widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
    """
    dialog = kwargs['dialog']
    complet_result = kwargs['complet_result']
    class_info = kwargs['class']
    field = kwargs['field']
    widget = add_multiple_checkbox(field, dialog, complet_result, class_info=class_info)
    return widget


def _manage_multiple_option(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
            widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
    """
    dialog = kwargs['dialog']
    complet_result = kwargs['complet_result']
    class_info = kwargs['class']
    field = kwargs['field']
    widget = add_multiple_option(field, dialog, complet_result, class_info=class_info)
    return widget


def _manage_check(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
            widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
    """

    widget = add_checkbox(**kwargs)
    return widget


def _manage_datetime(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
        widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
    """

    dialog = kwargs['dialog']
    field = kwargs['field']
    widget = add_calendar(dialog, field, **kwargs)
    return widget


def _manage_button(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
        widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
    """

    field = kwargs['field']
    stylesheet = field.get('stylesheet') or {}
    info_class = kwargs['class']
    # If button text is empty it's because node_1/2 is not present.
    # Then we create a QLineEdit to input a node to be connected.
    if not field.get('value') and stylesheet.get('icon') is None:
        widget = _manage_text(**kwargs)
        widget.editingFinished.connect(partial(info_class.run_settopology, widget, **kwargs))
        return widget
    widget = add_button(**kwargs)
    widget = set_widget_size(widget, field)
    return widget


def _manage_hyperlink(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
            widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
        """

    field = kwargs['field']
    widget = add_hyperlink(field)
    widget = set_widget_size(widget, field)
    return widget


def _manage_hspacer(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
        widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
    """

    widget = tools_qt.add_horizontal_spacer()
    return widget


def _manage_vspacer(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
        widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
    """

    widget = tools_qt.add_verticalspacer()
    return widget


def _manage_textarea(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
            widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
        """

    field = kwargs['field']
    widget = add_textarea(field)
    return widget


def _manage_spinbox(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
            widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
        """

    widget = add_spinbox(**kwargs)
    return widget


def _manage_doubleSpinbox(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
        widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
    """

    widget = add_spinbox(**kwargs)
    return widget


def _manage_list(self, **kwargs):
    _manage_tableview(**kwargs)


def _manage_tableview(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
        widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
    """
    complet_result = kwargs['complet_result']
    field = kwargs['field']
    dialog = kwargs['dialog']
    class_self = kwargs['class']
    module = tools_backend_calls
    widget = add_tableview(complet_result, field, dialog, module, class_self)
    widget = add_tableview_header(widget, field.get('value'))
    widget = fill_tableview_rows(widget, field.get('value'))
    tools_qt.set_tableview_config(widget)
    return widget


def _manage_tablewidget(**kwargs):
    """ This function is called in def set_widgets(self, dialog, complet_result, field, new_feature)
        widget = getattr(self, f"_manage_{field['widgettype']}")(**kwargs)
    """

    return _manage_tableview(**kwargs)


def _update_toolbar_button_icon(button_id, toolbar_id, file_name):
    """
    Update the icon for a specific toolbar button
    """
    try:

        # Access the button through global_vars
        if not global_vars.load_project or not hasattr(global_vars.load_project, 'buttons'):
            return False

        # Try both string and integer keys
        button = global_vars.load_project.buttons.get(str(button_id)) or global_vars.load_project.buttons.get(int(button_id))
        if not button or not hasattr(button, 'action'):
            return False

        # Define icon paths
        icon_folder = f"{lib_vars.plugin_dir}{os.sep}icons{os.sep}toolbars{os.sep}{toolbar_id}{os.sep}"
        icon_path = f"{icon_folder}{file_name}"

        # Update the button icon
        if os.path.exists(icon_path):
            new_icon = QIcon(icon_path)
            button.action.setIcon(new_icon)
            return True

    except Exception as e:
        # Log the error but don't break the functionality
        tools_log.log_info(f"Error updating button {button_id} icon: {str(e)}")
        return False

    return False


# endregion

# region Right Click TableView Menu


def _force_button_click(dlg, obj, name, pos):
    if obj == QTableView:
        tab = dlg.findChild(obj, name)
        tab.doubleClicked.emit(tab.indexAt(pos))
    else:
        dlg.findChild(obj, name).click()


def _show_context_menu(self, qtableview):
        """Show custom context menu"""

        menu = QMenu(qtableview)

        buttons = qtableview.window().findChildren(QPushButton)
        for btn in buttons:
            if btn.property('widgetcontrols') is not None:
                if btn.property('widgetcontrols').get('onContextMenu') is not None:
                    parents = list()
                    par = btn
                    while hasattr(par, 'objectName'):
                        parents.append(par.objectName())
                        par = par.parentWidget()
                    if qtableview.objectName() in parents:
                        action = QAction(btn.property('widgetcontrols').get('onContextMenu'), qtableview)
                        action.triggered.connect(partial(_force_button_click, qtableview.window(), QPushButton, btn.objectName()))
                        menu.addAction(action)

        menu.exec(QCursor.pos())

# endregion


# region Custom Classes

""" Custom classes to disable wheel scroll event when the widget is not fucused """


class CustomQComboBox(QComboBox):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.setFocusPolicy(Qt.FocusPolicy.StrongFocus)

    def wheelEvent(self, *args, **kwargs):
        if self.hasFocus():
            return QComboBox.wheelEvent(self, *args, **kwargs)
        else:
            return


class CustomQgsDateTimeEdit(QgsDateTimeEdit):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.setFocusPolicy(Qt.FocusPolicy.StrongFocus)

    def wheelEvent(self, *args, **kwargs):
        if self.hasFocus():
            return QgsDateTimeEdit.wheelEvent(self, *args, **kwargs)
        else:
            return

# endregion
