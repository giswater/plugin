"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: latin-1 -*-
import json
import os
import re
import urllib.parse as parse
import webbrowser
import traceback
from typing import Union
from functools import partial
from qgis.core import QgsEditFormConfig

from qgis.PyQt.sip import isdeleted

from qgis.PyQt.QtCore import pyqtSignal, QDate, QObject, Qt, QRegularExpression, QDateTime
from qgis.PyQt.QtGui import QColor, QStandardItem, QStandardItemModel, QCursor
from qgis.PyQt.QtWidgets import QAction, QCheckBox, QComboBox, QCompleter, QDoubleSpinBox, \
    QGridLayout, QLabel, QLineEdit, QListWidget, QListWidgetItem, QPushButton, QSizePolicy, \
    QSpinBox, QSpacerItem, QTableView, QTabWidget, QWidget, QTextEdit, QRadioButton, QToolBox, \
    QMenu, QToolButton, QTableWidget, QDialog, QHeaderView
from qgis.core import QgsApplication, QgsMapToPixel, QgsVectorLayer, QgsExpression, QgsFeatureRequest, \
    QgsPointXY, QgsProject, QgsFeature, QgsGeometry, Qgis
from qgis.gui import QgsDateTimeEdit, QgsMapToolEmitPoint, QgsCollapsibleGroupBox

from ..shared.catalog import GwCatalog
from .dimensioning import GwDimensioning
from ..toolbars.edit.element_manager_btn import GwElementManagerButton
from .visit_gallery import GwVisitGallery
from .visit import GwVisit
from .workcat import GwWorkcat
from ..utils import tools_gw, tools_backend_calls
from ..threads.toggle_valve_state import GwToggleValveTask
from ..toolbars.epa.dscenario_manager_btn import GwDscenarioManagerButton

from ..utils.snap_manager import GwSnapManager
from ..ui.ui_manager import GwInfoGenericUi, GwInfoFeatureUi, GwVisitEventFullUi, GwMainWindow, GwVisitDocumentUi, \
    GwInfoCrossectUi, GwInterpolate, GwPsectorUi
# WARNING: DO NOT REMOVE THESE IMPORTS, THEY ARE USED BY EPA ACTIONS
# noinspection PyUnresolvedReferences
from ..ui.ui_manager import GwInfoEpaUi  # noqa: F401
from ... import global_vars
from ...libs import lib_vars, tools_qgis, tools_qt, tools_log, tools_db, tools_os
from ...libs.tools_qt import GwHyperLinkLineEdit, GwEditDialog
from .audit import GwAudit

global is_inserting  # noqa: F824
is_inserting = False


class GwInfo(QObject):

    # :var signal_activate: emitted from def cancel_snapping_tool(self, dialog, action) in order to re-start CadInfo
    signal_activate = pyqtSignal()

    def __init__(self, tab_type):

        super().__init__()

        self.iface = global_vars.iface
        self.settings = global_vars.giswater_settings
        self.plugin_dir = lib_vars.plugin_dir
        self.canvas = global_vars.canvas
        self.schema_name = lib_vars.schema_name

        self.new_feature_id = None
        self.layer_new_feature = None
        self.tab_type = tab_type
        self.connected = False
        self.rubber_band = tools_gw.create_rubberband(self.canvas, "point")
        self.snapper_manager = GwSnapManager(self.iface)
        self.vertex_marker = self.snapper_manager.vertex_marker
        self.snapper_manager.set_snapping_layers()
        self.conf_supp = None
        self.prev_action = None

        # Setting lists
        self.rel_ids = []
        self.rel_list_ids = {'arc': [], 'node': [], 'connec': [], 'link': [], 'gully': [], 'element': []}
        self.rel_layers = {'arc': [], 'node': [], 'connec': [], 'link': [], 'gully': [], 'element': []}
        self.rel_layers['arc'] = tools_gw.get_layers_from_feature_type('arc')
        self.rel_layers['node'] = tools_gw.get_layers_from_feature_type('node')
        self.rel_layers['connec'] = tools_gw.get_layers_from_feature_type('connec')
        self.rel_layers['link'] = tools_gw.get_layers_from_feature_type('link')
        self.rel_layers['element'] = tools_gw.get_layers_from_feature_type('element')
        if global_vars.project_type == 'ud':
            self.rel_layers['gully'] = tools_gw.get_layers_from_feature_type('gully')
        self.rel_feature_type = None
        self.excluded_layers = ["ve_arc", "ve_node", "ve_connec", "ve_element", "ve_gully", "ve_link"]
        self.point_xy = {"x": None, "y": None}

    def get_info_from_coordinates(self, point, tab_type):
        return self.open_form(point=point, tab_type=tab_type)

    def get_info_from_id(self, table_name, feature_id, tab_type=None, is_add_schema=None):
        return self.open_form(table_name=table_name, feature_id=feature_id, tab_type=tab_type, is_add_schema=is_add_schema)

    def open_form(self, point=None, table_name=None, feature_id=None, feature_cat=None, new_feature_id=None, linked_feature=None,
                  layer_new_feature=None, tab_type=None, new_feature=None, is_docker=True, is_add_schema=False, connect_signal=None):
        """
        :param point: point where use clicked
        :param table_name: table where do sql query
        :param feature_id: id of feature to do info
        :return:
        """
        try:
            # Manage tab signal
            self.tab_epa_loaded = False
            self.tab_element_loaded = False
            self.tab_relations_loaded = False
            self.tab_features_loaded = False
            self.tab_connections_loaded = False
            self.tab_hydrometer_loaded = False
            self.tab_hydrometer_val_loaded = False
            self.tab_visit_loaded = False
            self.tab_event_loaded = False
            self.tab_document_loaded = False
            self.tab_rpt_loaded = False
            self.tab_plan_loaded = False
            self.dlg_is_destroyed = False
            self.layer = None
            self.feature = None
            self.my_json = {}
            self.my_json_epa = {}
            self.tab_type = tab_type
            self.visible_tabs = {}
            self.epa_complet_result = None
            self.inserted_feature = False

            # Get project variables
            qgis_project_add_schema = lib_vars.project_vars['add_schema']
            qgis_project_main_schema = lib_vars.project_vars['main_schema']
            qgis_project_role = lib_vars.project_vars['project_role']

            self.new_feature = new_feature

            # Check for query layer and/or bad layer
            if not tools_qgis.check_query_layer(self.iface.activeLayer()) or self.iface.activeLayer() is None or \
                    type(self.iface.activeLayer()) is not QgsVectorLayer:
                active_layer = ""
            else:
                active_layer = tools_qgis.get_layer_source_table_name(self.iface.activeLayer())

            # Used by action_interpolate
            last_click = self.canvas.mouseLastXY()
            self.last_point = QgsMapToPixel.toMapCoordinates(
                self.canvas.getCoordinateTransform(), last_click.x(), last_click.y())

            extras = ""
            if tab_type == 'inp':
                extras = '"toolBar":"epa"'
            elif tab_type == 'data':
                extras = '"toolBar":"basic"'

            function_name = None
            body = None
            # Insert new feature
            if (point and feature_cat) or new_feature_id:
                self.feature_cat = feature_cat
                self.new_feature_id = new_feature_id
                self.layer_new_feature = layer_new_feature
                self.iface.actionPan().trigger()
                feature = f'"tableName":"{feature_cat.child_layer.lower()}"'
                if point:
                    extras += f', "coordinates":{{{point}}}'
                body = tools_gw.create_body(feature=feature, extras=extras)
                function_name = 'gw_fct_getfeatureinsert'

            # Click over canvas
            elif point:
                visible_layer = tools_qgis.get_visible_layers(as_str_list=True)
                scale_zoom = self.iface.mapCanvas().scale()
                extras += f', "activeLayer":"{active_layer}"'
                extras += f', "visibleLayers":{visible_layer}'
                extras += f', "mainSchema":"{qgis_project_main_schema}"'
                extras += f', "addSchema":"{qgis_project_add_schema}"'
                extras += f', "projecRole":"{qgis_project_role}"'
                extras += f', "coordinates":{{"xcoord":{point.x()},"ycoord":{point.y()}, "zoomRatio":{scale_zoom}}}'
                body = tools_gw.create_body(extras=extras)
                function_name = 'gw_fct_getinfofromcoordinates'

            # Comes from QPushButtons node1 or node2 from custom form or RightButton
            elif feature_id:
                if is_add_schema:
                    add_schema = lib_vars.project_vars['add_schema']
                    extras = f'"addSchema":"{add_schema}"'
                else:
                    extras = '"addSchema":""'
                feature = f'"tableName":"{table_name}", "id":"{feature_id}"'
                body = tools_gw.create_body(feature=feature, extras=extras)
                function_name = 'gw_fct_getinfofromid'

            if function_name is None:
                return False, None

            tools_qgis.set_cursor_wait()
            json_result = tools_gw.execute_procedure(function_name, body, rubber_band=self.rubber_band)
            tools_qgis.restore_cursor()

            if json_result in (None, False):
                return False, None

            # Manage status failed
            if json_result['status'] == 'Failed' or not json_result.get('body', {}).get('form'):
                level = 1
                if 'level' in json_result['message']:
                    level = int(json_result['message']['level'])
                msg = "Execution of {0} failed."
                msg_params = (function_name,)
                if 'text' in json_result['message']:
                    msg = json_result['message']['text']
                    msg_params = None
                level = Qgis.MessageLevel(level)
                tools_qgis.show_message(msg, level, msg_params=msg_params)
                return False, None

            self.complet_result = json_result
            try:
                template = self.complet_result['body']['form']['template']
            except Exception as e:
                tools_log.log_info(str(e))
                return False, None

            if template == 'info_generic':
                result, dialog = self._open_generic_form(self.complet_result)
                # Fill self.my_json for new qgis_feature
                if feature_cat is not None:
                    self._manage_new_feature(self.complet_result, dialog)
                return result, dialog

            elif template == 'dimensioning':
                self.lyr_dim = tools_qgis.get_layer_by_tablename("ve_dimensions", show_warning_=True)
                if self.lyr_dim:
                    self.dimensioning = GwDimensioning()
                    feature_id = self.complet_result['body']['feature']['id']
                    result, dialog = self.dimensioning.open_dimensioning_form(None, self.lyr_dim, self.complet_result,
                        feature_id, self.rubber_band)
                    return result, dialog

            elif template == 'info_feature':
                sub_tag = None
                if feature_cat:
                    if feature_cat.feature_type.lower() == 'arc':
                        sub_tag = 'arc'
                    else:
                        sub_tag = 'node'

                # Comes from QPushButtons node1 or node2
                if feature_id and self.complet_result['body']['feature']['geometry']:
                    x1 = self.complet_result['body']['feature']['geometry']['x']
                    y1 = self.complet_result['body']['feature']['geometry']['y']

                    if x1 and y1:
                        current_extent = global_vars.canvas.extent()
                        feature_point = QgsPointXY(x1, y1)

                        if not current_extent.contains(feature_point):
                            global_vars.canvas.setCenter(feature_point)
                            global_vars.canvas.refresh()

                feature_id = self.complet_result['body']['feature']['id']
                if linked_feature:
                    linked_feature['element_id'] = str(feature_id)
                result, dialog = self._open_custom_form(feature_id, self.complet_result, tab_type, sub_tag, is_docker,
                    new_feature=new_feature, connect_signal=connect_signal, linked_feature=linked_feature)
                if feature_cat is not None:
                    self._manage_new_feature(self.complet_result, dialog)
                return result, dialog

            elif template == 'visit':
                visit_id = self.complet_result['body']['feature']['id']
                manage_visit = GwVisit()
                manage_visit.get_visit(visit_id=visit_id, tag='info')
                dlg_add_visit = manage_visit.get_visit_dialog()
                dlg_add_visit.rejected.connect(lambda: tools_gw.reset_rubberband(self.rubber_band))
                return self.complet_result, dlg_add_visit

            elif template == 'element':
                element_id = self.complet_result['body']['feature']['id']
                manage_element = GwElementManagerButton()
                manage_element.get_element(new_element_id=False, selected_object_id=element_id)
                dlg_add_element = manage_element.get_element_dialog()
                dlg_add_element.rejected.connect(lambda: tools_gw.reset_rubberband(self.rubber_band))
                return self.complet_result, dlg_add_element

            else:
                msg = "Template not managed: {0}"
                msg = (template,)
                tools_log.log_warning(msg, msg_params=msg_params)
                return False, None

        except Exception as e:
            msg = "Exception in info"
            tools_qgis.show_warning(msg, parameter=e)
            msg = str(traceback.format_exc())
            tools_log.log_error(msg)
            self._disconnect_signals()  # Disconnect signals
            tools_qgis.restore_cursor()  # Restore overridden cursor
            return False, None

    """ FUNCTIONS ASSOCIATED TO BUTTONS FROM POSTGRES"""

    def add_feature(self, feature_cat, action=None, connect_signal=None, linked_feature=None):
        """ Button 21, 22: Add 'node', 'arc', 'connec' or 'element' """

        global is_inserting  # noqa: F824
        if is_inserting:
            msg = "You cannot insert more than one feature at the same time, finish editing the previous feature"
            tools_qgis.show_message(msg)
            return

        self.prev_action = action
        keep_active = tools_gw.get_config_parser('user_edit_tricks', 'keep_maptool_active', "user", "init")
        keep_active = tools_os.set_boolean(keep_active, False)
        if not keep_active:
            self.prev_action = None
        tools_gw.connect_signal(self.iface.actionAddFeature().toggled, self._action_is_checked,
                                'info', 'add_feature_actionAddFeature_toggled_action_is_checked')
        self.feature_cat = feature_cat
        # self.info_layer must be global because apparently the disconnect signal is not disconnected correctly if
        # parameters are passed to it
        self.info_layer = tools_qgis.get_layer_by_tablename(feature_cat.parent_layer)

        # Order liked_feature
        if self.info_layer and (feature_cat.feature_class == 'GENELEM' or linked_feature):
            tools_gw.disconnect_signal('info', 'add_feature_featureAdded_open_new_feature')

            config = self.info_layer.editFormConfig()
            self.conf_supp = config.suppress()
            config.setSuppress(QgsEditFormConfig.FeatureFormSuppress.SuppressOn)
            self.info_layer.setEditFormConfig(config)
            self.iface.setActiveLayer(self.info_layer)
            self.info_layer.startEditing()

            # Connect signal with feature_id
            tools_gw.connect_signal(self.info_layer.featureAdded, partial(self._open_new_feature, connect_signal=connect_signal, linked_feature=linked_feature),
                                    'info', 'add_feature_featureAdded_open_new_feature')
            # Create a new feature with the given feature_id
            feature = QgsFeature(self.info_layer.fields())
            self.info_layer.addFeature(feature)

        elif self.info_layer:
            # The user selects a feature (for example junction) to insert, but before clicking on the canvas he
            # realizes that he has made a mistake and selects another feature, without this two features would
            # be inserted. This disconnect signal avoids it
            tools_gw.disconnect_signal('info', 'add_feature_featureAdded_open_new_feature')

            config = self.info_layer.editFormConfig()
            self.conf_supp = config.suppress()
            config.setSuppress(QgsEditFormConfig.FeatureFormSuppress.SuppressOn)
            self.info_layer.setEditFormConfig(config)
            self.iface.setActiveLayer(self.info_layer)
            self.info_layer.startEditing()
            self.iface.actionAddFeature().trigger()
            tools_gw.connect_signal(self.info_layer.featureAdded, partial(self._open_new_feature, connect_signal=connect_signal, linked_feature=linked_feature),
                                    'info', 'add_feature_featureAdded_open_new_feature')
        else:
            msg = "Layer not found"
            tools_qgis.show_warning(msg, parameter=feature_cat.parent_layer)

    """ FUNCTIONS RELATED WITH TAB PLAN """

    def get_snapped_feature_id(self, dialog, action, layer_name, option, widget_name, child_type):
        """ Snap feature and set a value into dialog """

        layer = tools_qgis.get_layer_by_tablename(layer_name)
        if not layer:
            action.setChecked(False)
            return
        if widget_name is not None:
            widget = dialog.findChild(QWidget, widget_name)
            if widget is None:
                action.setChecked(False)
                msg = "Widget: {0} not in form."
                msg_params = (widget_name,)
                tools_qgis.show_message(msg, dialog=dialog, msg_params=msg_params)
                return
        # Block the signals of de dialog so that the key ESC does not close it
        dialog.blockSignals(True)

        # Set signals
        tools_gw.disconnect_signal('info_snapping', 'get_snapped_feature_id_xyCoordinates_mouse_moved')
        tools_gw.connect_signal(self.canvas.xyCoordinates, partial(self._mouse_moved, layer),
                                'info_snapping', 'get_snapped_feature_id_xyCoordinates_mouse_moved')

        tools_gw.disconnect_signal('info_snapping', 'get_snapped_feature_id_ep_canvasClicked_get_id')
        emit_point = QgsMapToolEmitPoint(self.canvas)
        self.canvas.setMapTool(emit_point)
        tools_gw.connect_signal(emit_point.canvasClicked, partial(self._get_id, dialog, action, option, emit_point, child_type, widget_name),
                                'info_snapping', 'get_snapped_feature_id_ep_canvasClicked_get_id')

    # region private functions

    def _get_feature_insert(self, point, feature_cat, new_feature_id, layer_new_feature, tab_type, new_feature, connect_signal=None,
                            linked_feature=None):
        return self.open_form(point=point, feature_cat=feature_cat, new_feature_id=new_feature_id,
                              layer_new_feature=layer_new_feature, tab_type=tab_type, new_feature=new_feature,
                              connect_signal=connect_signal, linked_feature=linked_feature)

    def _manage_new_feature(self, complet_result, dialog):

        result = complet_result['body']['data']
        for field in result['fields']:
            if 'hidden' in field and field['hidden']:
                continue
            if 'layoutname' in field and field['layoutname'] in ('lyt_none', 'lyt_buttons'):
                continue
            if field.get('tabname') not in ('tab_data', 'tab_none'):
                continue
            if field['widgettype'] in ('spacer', 'label'):
                continue

            widget = dialog.findChild(QWidget, field['widgetname'])
            value = None
            if type(widget) in (QLineEdit, QPushButton, QSpinBox, QDoubleSpinBox):
                value = tools_qt.get_text(dialog, widget, return_string_null=False)
            elif isinstance(widget, QComboBox):
                value = tools_qt.get_combo_value(dialog, widget, 0)
            elif type(widget) is QCheckBox:
                value = tools_qt.is_checked(dialog, widget)
            elif isinstance(widget, QgsDateTimeEdit):
                value = tools_qt.get_calendar_date(dialog, widget)
            else:
                if widget is None:
                    msg = "Widget {0} is not configured or have a bad config"
                    msg_params = (field['columnname'],)
                    tools_qgis.show_message(msg, dialog=dialog, msg_params=msg_params)
            if str(value) not in ('', None, -1, "None") and widget.property('columnname'):
                if str(widget.property('columnname')) != 'sector_id' and str(value) == '-1':
                    continue
                if widget.property('saveValue') is None:
                    self.my_json[str(widget.property('columnname'))] = str(value)

        tools_log.log_info(str(self.my_json))

    def _open_generic_form(self, complet_result):

        tools_gw.draw_by_json(complet_result, self.rubber_band)
        # Dialog
        self.dlg_generic = GwInfoGenericUi(self)
        tools_gw.load_settings(self.dlg_generic)
        result = tools_gw.build_dialog_info(self.dlg_generic, complet_result, self.my_json, tab_name="tab_none",
                                            enable_actions=True, is_inserting=False)
        # Set variables
        self._get_features(complet_result)
        layer = self.layer
        fid = self.feature_id = complet_result['body']['feature']['id']
        new_feature = False
        can_edit = tools_os.set_boolean(tools_db.check_role_user('role_edit'))
        if layer:
            if layer.isEditable() and can_edit:
                tools_gw.enable_all(self.dlg_generic, complet_result['body']['data'])
            else:
                tools_gw.enable_widgets(self.dlg_generic, complet_result['body']['data'], False)

        # Manage actions
        self.action_edit = self.dlg_generic.findChild(QAction, "actionEdit")
        tools_gw.add_icon(self.action_edit, "101")

        try:
            for tab in complet_result['body']['form']['visibleTabs']:
                self.visible_tabs[tab['tabName']] = tab
        except (KeyError, TypeError):
            pass

        is_enabled = False
        try:
            is_enabled = complet_result['body']['feature']['permissions']['isEditable']
        except (KeyError, TypeError):
            try:
                is_enabled = complet_result['body']['data']['editable']
            except (KeyError, TypeError):
                pass
        finally:
            self.action_edit.setEnabled(is_enabled)
        self.action_edit.triggered.connect(partial(self._manage_edition, self.dlg_generic, self.action_edit, fid, new_feature, generic=True))
        if layer:
            self.action_edit.setChecked(layer.isEditable() and can_edit)

        # Signals
        self.dlg_generic.btn_accept.clicked.connect(partial(
            self._accept_from_btn, self.dlg_generic, self.action_edit, new_feature, self.my_json, complet_result, True
        ))
        self.dlg_generic.btn_close.clicked.connect(partial(tools_gw.close_dialog, self.dlg_generic))
        self.dlg_generic.key_escape.connect(partial(tools_gw.close_dialog, self.dlg_generic))
        self.dlg_generic.dlg_closed.connect(partial(tools_gw.close_dialog, self.dlg_generic))

        # Disable button accept for info on generic form
        self.dlg_generic.btn_accept.setEnabled(can_edit)

        self.dlg_generic.dlg_closed.connect(self.rubber_band.reset)
        self.dlg_generic.dlg_closed.connect(self._roll_back)
        self.dlg_generic.dlg_closed.connect(self._disconnect_signals)
        tools_gw.open_dialog(self.dlg_generic, dlg_name='info_generic')

        return result, self.dlg_generic

    def _open_custom_form(self, feature_id, complet_result, tab_type=None, sub_tag=None, is_docker=True, new_feature=None, connect_signal=None,
                          linked_feature=None):
        """
        Opens a custom form
            :param feature_id: the id of the node that will populate the form (Integer)
            :param complet_result: The JSON used to create/populate the form (JSON)
            :param tab_type:
            :param sub_tag:
            :param is_docker: Whether the form is docker or not (Boolean)
            :param new_feature: Whether the form will create a new feature or not (Boolean)
            :return: self.complt_result, self.dlg_cf
        """
        # Dialog
        self.dlg_cf = GwInfoFeatureUi(self, sub_tag)
        tools_gw.load_settings(self.dlg_cf)

        # Get widget controls
        self._get_widget_controls(new_feature)

        self._get_features(complet_result)
        if self.layer is None:
            msg = "Layer not found"
            tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=self.table_parent)
            return False, self.dlg_cf

        # If in the get_json function we have received a rubberband, it is not necessary to redraw it.
        # But if it has not been received, it is drawn
        # Using variable exist_rb for check if alredy exist rubberband
        try:
            # noinspection PyUnusedLocal
            exist_rb = complet_result['body']['returnManager']['style']['ruberband']  # noqa: F841
        except KeyError:
            tools_gw.draw_by_json(complet_result, self.rubber_band)

        # Remove unused tabs
        tabs_to_show = []

        # Get field id name and feature id
        self.field_id = str(complet_result['body']['feature']['idName'])
        self.feature_id = complet_result['body']['feature']['id']

        # Get the start point and end point of the feature
        list_points = None
        if new_feature:
            list_points = tools_qgis.get_points_from_geometry(self.layer, new_feature)
        else:
            try:
                list_points = (f'"x1": {complet_result["body"]["feature"]["geometry"]["x"]}, '
                               f'"y1": {complet_result["body"]["feature"]["geometry"]["y"]}')
            except Exception:
                pass

        for tab in complet_result['body']['form']['visibleTabs']:
            self.visible_tabs[tab['tabName']] = tab

        for tab in self.visible_tabs:
            tabs_to_show.append(self.visible_tabs[tab]['tabName'])

        # Reorder tabs
        tab_order = {}
        for tab in self.visible_tabs.values():
            tab_order[tab['tabName']] = tab['orderby']

        for tab_name, tab_index in sorted(tab_order.items(), key=lambda item: item[1]):
            old_position = tools_qt.get_tab_index_by_tab_name(self.tab_main, tab_name)
            new_position = tab_index
            self.tab_main.tabBar().moveTab(old_position, new_position)

        for x in range(self.tab_main.count() - 1, -1, -1):
            tab_name = self.tab_main.widget(x).objectName()
            try:
                self.tab_main.setTabText(x, self.visible_tabs[tab_name]['tabLabel'])
                self.tab_main.setTabToolTip(x, self.visible_tabs[tab_name]['tooltip'])
            except Exception:
                pass
            if tab_name not in tabs_to_show:
                tools_qt.remove_tab(self.tab_main, tab_name)
            elif new_feature and tab_name != 'tab_data':
                tools_qt.enable_tab_by_tab_name(self.tab_main, tab_name, False)

        # Actions
        self._get_actions()

        try:
            is_enabled = complet_result['body']['feature']['permissions']['isEditable']
            self.action_edit.setEnabled(is_enabled)
        except Exception:
            pass

        # Add icons to actions & buttons
        self._manage_icons()

        result = self._get_feature_type(complet_result)
        # Build and populate all the widgets
        self._manage_dlg_widgets(complet_result, result, new_feature)
        # Disable tab EPA if epa_type is undefined
        self.epa_type = tools_qt.get_text(self.dlg_cf, 'tab_data_epa_type')
        if tools_qt.get_text(self.dlg_cf, self.epa_type).lower() == 'undefined':
            tools_qt.enable_tab_by_tab_name(self.tab_main, 'tab_epa', False)

        # Connect actions' signals
        dlg_cf, fid = self._manage_actions_signals(complet_result, list_points, new_feature, tab_type, result)

        self._show_actions(self.dlg_cf, 'tab_data')
        if self.new_feature_id is not None and self.feature_type not in ('element'):
            self._enable_action(self.dlg_cf, "actionCentered", False)
            self._enable_action(self.dlg_cf, "actionSetToArc", False)

        btn_cancel = self.dlg_cf.findChild(QPushButton, 'btn_cancel')
        btn_accept = self.dlg_cf.findChild(QPushButton, 'btn_accept')
        try:
            title = f"{complet_result['body']['form']['headerText']}"
        except KeyError:
            title = f"{complet_result['body']['feature']['childType']}"
        except Exception:
            title = "Info"

        # Connect dialog signals
        if lib_vars.session_vars['dialog_docker'] and is_docker and lib_vars.session_vars['info_docker']:
            # Delete last form from memory
            last_info = lib_vars.session_vars['dialog_docker'].findChild(GwMainWindow, 'dlg_info_feature')
            if last_info:
                last_info.setParent(None)
                del last_info

            tools_gw.docker_dialog(dlg_cf, dlg_name='info_feature', title='info_feature')
            lib_vars.session_vars['dialog_docker'].widget().dlg_closed.connect(self._manage_docker_close)
            lib_vars.session_vars['dialog_docker'].setWindowTitle(title)
            btn_cancel.clicked.connect(self._manage_docker_close)

            # For new features created after a previous feature (docker dialog stays open), enable edit mode
            is_new_feature = new_feature is not None
            if is_new_feature and self.layer:
                # Check if the layer has any features (indicating previous inserts)
                feature_count = self.layer.featureCount()
                # If there are features and this is a new feature, enable edit mode
                if feature_count > 0:
                    can_edit = tools_os.set_boolean(tools_db.check_role_user('role_edit'))
                    if can_edit:
                        if not self.layer.isEditable():
                            self.layer.startEditing()
                        self.action_edit.setChecked(True)

            # Hide Accept button in Docker mode - use Apply instead
            if btn_accept:
                btn_accept.hide()

        else:
            dlg_cf.dlg_closed.connect(self._roll_back)
            dlg_cf.dlg_closed.connect(lambda: tools_gw.reset_rubberband(self.rubber_band))
            dlg_cf.dlg_closed.connect(self._remove_layer_selection)
            dlg_cf.dlg_closed.connect(partial(tools_gw.save_settings, dlg_cf))
            dlg_cf.dlg_closed.connect(self._reset_my_json)
            dlg_cf.dlg_closed.connect(self._manage_prev_action)
            dlg_cf.key_escape.connect(partial(tools_gw.close_dialog, dlg_cf))
            btn_cancel.clicked.connect(partial(self._manage_info_close, dlg_cf))
            self.dlg_cf.btn_apply.clicked.connect(partial(self._apply_from_btn, dlg_cf, self.action_edit, feature_id, new_feature,
                                                          False, from_apply=True, linked_feature=linked_feature))
            btn_accept.clicked.connect(
            partial(self._accept_from_btn, dlg_cf, self.action_edit, new_feature, self.my_json, complet_result, False, linked_feature=linked_feature))
            dlg_cf.key_enter.connect(
            partial(self._accept_from_btn, dlg_cf, self.action_edit, new_feature, self.my_json, complet_result, False, linked_feature=linked_feature))
            # Open dialog
            tools_gw.open_dialog(self.dlg_cf, dlg_name='info_feature')
            self.dlg_cf.setWindowTitle(title)

        # Check if audit schema exists
        sql = "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'audit'"
        rows = tools_db.get_rows(sql, log_info=False, commit=False)

        # Check if audit is active
        schema_actived = tools_gw.get_config_parser('toolbars_add', 'audit_active', 'user', 'init', False)
        schema_actived = tools_os.set_boolean(schema_actived, False)

        self.action_audit.setVisible(rows is not None and schema_actived)

        if rows and schema_actived:
            self._enable_action(dlg_cf, self.action_audit, True)
        if connect_signal:
            for signal in connect_signal:
                func_name = signal.func.__name__
                if func_name == "add_object":
                    signal_kwargs = signal.keywords
                    signal_kwargs['complet_result_info'] = complet_result

                self.dlg_cf.dlg_closed.connect(signal)
                self.dlg_cf.btn_apply.clicked.connect(signal)

        return self.complet_result, self.dlg_cf

    def _get_widget_controls(self, new_feature):
        """ Sets class variables for most widgets """

        self.tab_main = self.dlg_cf.findChild(QTabWidget, "tab_main")
        self.tab_main.currentChanged.connect(partial(self._tab_activation, self.dlg_cf))

    def _get_features(self, complet_result):

        # Get table name
        self.tablename = complet_result['body']['feature']['tableName']
        # Get feature type (Junction, manhole, valve, fountain...)
        self.feature_type = complet_result['body']['feature']['childType']
        # Get tableParent and select layer
        self.table_parent = str(complet_result['body']['feature']['tableParent'])
        schema_name = str(complet_result['body']['feature']['schemaName'])
        self.layer = tools_qgis.get_layer_by_tablename(self.table_parent, False, False, schema_name)

    def _get_actions(self):
        """ Sets class variables for actions """

        self.action_edit = self.dlg_cf.findChild(QAction, "actionEdit")
        self.action_copy_paste = self.dlg_cf.findChild(QAction, "actionCopyPaste")
        self.action_rotation = self.dlg_cf.findChild(QAction, "actionRotation")
        self.action_catalog = self.dlg_cf.findChild(QAction, "actionCatalog")
        self.action_workcat = self.dlg_cf.findChild(QAction, "actionWorkcat")
        self.action_mapzone = self.dlg_cf.findChild(QAction, "actionMapZone")
        self.action_set_to_arc = self.dlg_cf.findChild(QAction, "actionSetToArc")
        self.action_get_arc_id = self.dlg_cf.findChild(QAction, "actionGetArcId")
        self.action_get_parent_id = self.dlg_cf.findChild(QAction, "actionGetParentId")
        self.action_centered = self.dlg_cf.findChild(QAction, "actionCentered")
        self.action_link = self.dlg_cf.findChild(QAction, "actionLink")
        self.action_help = self.dlg_cf.findChild(QAction, "actionHelp")
        self.action_interpolate = self.dlg_cf.findChild(QAction, "actionInterpolate")
        self.action_section = self.dlg_cf.findChild(QAction, "actionSection")
        self.action_orifice = self.dlg_cf.findChild(QAction, "actionOrifice")
        self.action_outlet = self.dlg_cf.findChild(QAction, "actionOutlet")
        self.action_weir = self.dlg_cf.findChild(QAction, "actionWeir")
        self.action_demand = self.dlg_cf.findChild(QAction, "actionDemand")
        self.action_audit = self.dlg_cf.findChild(QAction, "actionAudit")
        self.action_set_geom = self.dlg_cf.findChild(QAction, "actionSetGeom")

    def _manage_icons(self):
        """ Adds icons to actions and buttons """

        # Set actions icon
        tools_gw.add_icon(self.action_edit, "101")
        tools_gw.add_icon(self.action_copy_paste, "106")
        tools_gw.add_icon(self.action_rotation, "110")
        tools_gw.add_icon(self.action_catalog, "152")
        tools_gw.add_icon(self.action_workcat, "150")
        tools_gw.add_icon(self.action_mapzone, "158")
        tools_gw.add_icon(self.action_set_to_arc, "157")
        tools_gw.add_icon(self.action_get_arc_id, "155")
        tools_gw.add_icon(self.action_get_parent_id, "156")
        tools_gw.add_icon(self.action_centered, "104")
        tools_gw.add_icon(self.action_link, "173")
        tools_gw.add_icon(self.action_section, "154")
        tools_gw.add_icon(self.action_help, "130")
        tools_gw.add_icon(self.action_interpolate, "151")
        tools_gw.add_icon(self.action_orifice, "159")
        tools_gw.add_icon(self.action_outlet, "160")
        tools_gw.add_icon(self.action_weir, "162")
        tools_gw.add_icon(self.action_demand, "163")
        tools_gw.add_icon(self.action_audit, "177")
        tools_gw.add_icon(self.action_set_geom, "133")

    def _manage_dlg_widgets(self, complet_result, result, new_feature, reload_epa=False, tab='tab_data'):
        """ Creates and populates all the widgets """

        layout_orientations = {}
        old_widget_pos = 0
        layout_list = []
        prev_layout = ""
        widget_dict = {'text': 'lineedit', 'typeahead': 'lineedit', 'textarea': 'textarea', 'combo': 'combobox',
                       'check': 'checkbox', 'datetime': 'dateedit', 'hyperlink': 'hyperlink', 'spinbox': 'spinbox',
                       'doublespinbox': 'spinbox', 'multiple_option': 'multiple_option', 'multiple_checkbox': 'multiple_checkbox'}

        for layout_name, layout_info in complet_result['body']['form']['layouts'].items():
            orientation = layout_info.get('lytOrientation')
            if orientation:
                layout_orientations[layout_name] = orientation

        current_layout = ""
        for field in complet_result['body']['data']['fields']:

            if field.get('hidden'):
                continue
            if tab != field.get('tabname'):
                continue
            if field.get('widgetcontrols') and field['widgetcontrols'].get('hiddenWhenNull') \
                    and field.get('value') in (None, ''):
                continue
            label, widget = tools_gw.set_widgets(self.dlg_cf, complet_result, field, self.tablename, self)
            if widget is None:
                continue

            # Create connections
            if field['widgettype'] not in ('tableview', 'vspacer', 'list', 'hspacer', 'button', 'label'):
                if field['widgettype'] == 'hyperlink':
                    if type(widget) is GwHyperLinkLineEdit:
                        widget = getattr(self, f"_set_auto_update_{widget_dict[field['widgettype']]}")(field, self.dlg_cf, widget, new_feature)
                else:
                    widget = getattr(self, f"_set_auto_update_{widget_dict[field['widgettype']]}")(field, self.dlg_cf, widget, new_feature)

            layout = self.dlg_cf.findChild(QGridLayout, field['layoutname'])
            if layout is not None:
                orientation = layout_orientations.get(layout.objectName(), "vertical")
                layout.setProperty('lytOrientation', orientation)
                if layout.objectName() != prev_layout:
                    prev_layout = layout.objectName()
                # Take the QGridLayout with the intention of adding a QSpacerItem later
                if layout not in layout_list and layout.objectName() in ('lyt_data_1', 'lyt_data_2', 'lyt_data_3',
                                                                         'lyt_epa_data_1', 'lyt_epa_data_2'):
                    layout_list.append(layout)

                if field['layoutname'] is None:
                    msg = "The field layoutname is not configured for"
                    param = f"formname:{self.tablename}, columnname:{field['columnname']}"
                    tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=param, dialog=self.dlg_cf)
                    continue
                if field['layoutorder'] is None:
                    param = f"formname:{self.tablename}, columnname:{field['columnname']}"
                    continue

                # The data tab is somewhat special (it has 2 columns)
                if 'lyt_data' in layout.objectName() or 'lyt_epa_data' in layout.objectName():
                    tools_gw.add_widget(self.dlg_cf, field, label, widget)

                if current_layout != field['layoutname']:
                    current_layout = field['layoutname']
                    old_widget_pos = field['layoutorder']
                else:
                    old_widget_pos = field['layoutorder'] + 1

                # Populate dialog widgets using lytOrientation field
                tools_gw.add_widget_combined(self.dlg_cf, field, label, widget, old_widget_pos)

            elif field['layoutname'] != 'lyt_none':
                msg = "The field layoutname is not configured for"
                param = f"formname:{self.tablename}, columnname:{field['columnname']}"
                tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=param, dialog=self.dlg_cf)
        # Add a QSpacerItem into each QGridLayout of the list
        for layout in layout_list:
            vertical_spacer1 = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
            spacer_row = layout.rowCount()
            layout.addItem(vertical_spacer1, spacer_row, 0, 1, 2)
            layout.setRowStretch(spacer_row, 1)

        # Manage dscenario sub-tab from epa tab
        try:
            lyt_dscenario = self.dlg_cf.findChild(QGridLayout, "lyt_epa_dsc_3")
            epa_toolbox = self.dlg_cf.findChild(QToolBox, "epa_toolbox")
            if lyt_dscenario.count() == 0:
                epa_toolbox.setItemEnabled(1, False)
            else:
                epa_toolbox.setItemEnabled(1, True)
        except Exception:
            pass

        if reload_epa:
            return
        # Manage combo parents and children:
        for field in result['fields']:
            if field['isparent']:
                if field['widgettype'] == 'combo':
                    widget = self.dlg_cf.findChild(QComboBox, field['widgetname'])
                    if widget is not None:
                        widget.currentIndexChanged.connect(partial(
                            self._get_combo_child, self.dlg_cf, widget, self.feature_type,
                            self.tablename, self.field_id))

    def _manage_actions_signals(self, complet_result, list_points, new_feature, tab_type, result):
        """ Connects signals to the actions """

        # Set variables
        id_name = complet_result['body']['feature']['idName']
        self.filter = str(id_name) + " = '" + str(self.feature_id) + "'"
        dlg_cf = self.dlg_cf
        layer = self.layer
        fid = self.feature_id
        can_edit = tools_os.set_boolean(tools_db.check_role_user('role_edit'))
        if layer:
            if layer.isEditable() and can_edit:
                tools_gw.enable_all(dlg_cf, complet_result['body']['data'])
            else:
                tools_gw.enable_widgets(dlg_cf, complet_result['body']['data'], False)

        # We assign the function to a global variable,
        # since as it receives parameters we will not be able to disconnect the signals
        self.fct_block_action_edit = lambda: self._block_action_edit(dlg_cf, self.action_edit, result, layer, fid,
                                                                     self.my_json, new_feature)
        self.fct_start_editing = lambda: self._start_editing(dlg_cf, self.action_edit, complet_result['body']['data'], layer)
        self.fct_stop_editing = lambda: self._stop_editing(dlg_cf, self.action_edit, layer, fid, self.my_json, new_feature)
        self._connect_signals()

        self._enable_actions(dlg_cf, layer.isEditable() and can_edit)

        self.action_edit.setChecked(layer.isEditable() and can_edit)
        child_type = complet_result['body']['feature']['childType']

        # Actions signals
        self.action_edit.triggered.connect(partial(self._manage_edition, dlg_cf, self.action_edit, fid, new_feature, generic=False))
        self.dlg_cf.btn_apply.clicked.connect(partial(self._manage_edition, dlg_cf, self.action_edit, fid, new_feature, False, from_apply=True))
        self.action_catalog.triggered.connect(partial(self._open_catalog, tab_type, self.feature_type, child_type))
        self.action_workcat.triggered.connect(partial(GwWorkcat(self.iface, self.canvas).create_workcat))
        self.action_mapzone.triggered.connect(
            partial(self._get_catalog, 'new_mapzone', self.tablename, child_type, self.feature_id, list_points,
                    id_name))
        self.action_set_to_arc.triggered.connect(
            partial(self.get_snapped_feature_id, dlg_cf, self.action_set_to_arc, 've_arc', 'set_to_arc', 'tab_data_to_arc',
                    child_type))
        self.action_get_arc_id.triggered.connect(
            partial(self.get_snapped_feature_id, dlg_cf, self.action_get_arc_id, 've_arc', 'arc', 'tab_data_arc_id',
                    child_type))
        self.action_get_parent_id.triggered.connect(
            partial(self.get_snapped_feature_id, dlg_cf, self.action_get_parent_id, 've_node', 'node',
                    'tab_data_parent_id', child_type))
        self.action_centered.triggered.connect(partial(self._manage_action_centered, self.canvas, self.layer))
        self.action_copy_paste.triggered.connect(
            partial(self._manage_action_copy_paste, self.dlg_cf, self.feature_type, tab_type))
        self.action_rotation.triggered.connect(partial(self._change_hemisphere, self.dlg_cf, self.action_rotation))
        self.action_link.triggered.connect(partial(self.action_open_link))
        self.action_section.triggered.connect(partial(self._open_section_form))
        self.action_help.triggered.connect(partial(self._open_help, self.feature_type))
        self.ep = QgsMapToolEmitPoint(self.canvas)
        self.action_interpolate.triggered.connect(partial(self._activate_snapping, complet_result, self.ep))
        self.action_set_geom.triggered.connect(self._get_point_xy)

        # EPA Actions
        self.action_orifice.triggered.connect(partial(self._open_orifice_dlg))
        self.action_outlet.triggered.connect(partial(self._open_outlet_dlg))
        self.action_weir.triggered.connect(partial(self._open_weir_dlg))
        if global_vars.project_type == 'ws':
            self.action_demand.triggered.connect(partial(self._open_demand_dlg))
        elif global_vars.project_type == 'ud':
            self.action_demand.triggered.connect(partial(self._open_dwf_dlg))

        # Disable action edit if user can't edit
        if not can_edit:
            self.action_edit.setChecked(False)
            self.action_edit.setEnabled(False)

        # AUDIT Action
        self.action_audit.triggered.connect(partial(self._open_audit_manager))

        return dlg_cf, fid

    def _open_orifice_dlg(self):
        # kwargs
        func_params = {"ui": "GwInfoEpaUi", "uiName": "info_epa",
                       "tableviews": [
                        {"tbl": "tbl", "view": "inp_flwreg_orifice", "add_view": "ve_inp_flwreg_orifice", "pk": "nodarc_id", "add_dlg_title": "Orifice - Base"},
                        {"tbl": "tbl_dscenario", "view": "inp_dscenario_flwreg_orifice", "add_view": "ve_inp_dscenario_flwreg_orifice", "pk": ["dscenario_id", "nodarc_id"], "add_dlg_title": "Orifice - Dscenario"}
                       ]}
        kwargs = {"complet_result": self.complet_result, "class": self, "func_params": func_params}
        open_epa_dlg("Orifice", **kwargs)

    def _open_outlet_dlg(self):
        # kwargs
        func_params = {"ui": "GwInfoEpaUi", "uiName": "info_epa",
                       "tableviews": [
                        {"tbl": "tbl", "view": "inp_flwreg_outlet", "add_view": "ve_inp_flwreg_outlet", "pk": "nodarc_id", "add_dlg_title": "Outlet - Base"},
                        {"tbl": "tbl_dscenario", "view": "inp_dscenario_flwreg_outlet", "add_view": "ve_inp_dscenario_flwreg_outlet", "pk": ["dscenario_id", "nodarc_id"], "add_dlg_title": "Outlet - Dscenario"}
                       ]}
        kwargs = {"complet_result": self.complet_result, "class": self, "func_params": func_params}
        open_epa_dlg("Outlet", **kwargs)

    def _open_weir_dlg(self):
        # kwargs
        func_params = {"ui": "GwInfoEpaUi", "uiName": "info_epa",
                       "tableviews": [
                        {"tbl": "tbl", "view": "inp_flwreg_weir", "add_view": "ve_inp_flwreg_weir", "pk": "nodarc_id", "add_dlg_title": "Weir - Base"},
                        {"tbl": "tbl_dscenario", "view": "inp_dscenario_flwreg_weir", "add_view": "ve_inp_dscenario_flwreg_weir", "pk": ["dscenario_id", "nodarc_id"], "add_dlg_title": "Weir - Dscenario"}
                       ]}
        kwargs = {"complet_result": self.complet_result, "class": self, "func_params": func_params}
        open_epa_dlg("Weir", **kwargs)

    def _open_demand_dlg(self):
        # kwargs
        func_params = {"ui": "GwInfoEpaUi", "uiName": "info_epa",
                       "tableviews": [
                        {"tbl": "tbl_dscenario", "view": "inp_dscenario_demand", "add_view": "ve_inp_dscenario_demand", "id_name": "feature_id", "pk": ["dscenario_id", "feature_id"], "add_dlg_title": "Demand - Dscenario"}
                       ]}
        kwargs = {"complet_result": self.complet_result, "class": self, "func_params": func_params}
        open_epa_dlg("Demand", **kwargs)

    def _open_dwf_dlg(self):
        # kwargs
        func_params = {"ui": "GwInfoEpaUi", "uiName": "info_epa",
                       "tableviews": [
                        {"tbl": "tbl_dwf", "view": "inp_dwf", "pk": ["node_id", "dwfscenario_id"], "add_view": "ve_inp_dwf", "add_dlg_title": "DWF"},
                        {"tbl": "tbl_inflows", "view": "inp_dscenario_inflows", "pk": ["dscenario_id", "node_id", "order_id"], "add_view": "ve_inp_dscenario_inflows", "add_dlg_title": "INFLOWS - Dscenario"}
                       ]}
        kwargs = {"complet_result": self.complet_result, "class": self, "func_params": func_params}
        open_epa_dlg("DWF & INFLOWS", **kwargs)

    def action_open_link(self):
        """ Manage def open_file from action 'Open Link' """

        try:
            widget_list = self.dlg_cf.findChildren(tools_qt.GwHyperLinkLabel)
            for widget in widget_list:
                path = widget.text()
                status, message = tools_os.open_file(path)
                if status is False and message is not None:
                    tools_qgis.show_warning(message, parameter=path, dialog=self.dlg_cf)
        except Exception:
            pass

    def _get_feature_type(self, complet_result):
        """ Get feature type as feature_type (node, arc, connec, gully) """

        self.feature_type = str(complet_result['body']['feature']['featureType'])
        if str(self.feature_type) in ('', '[]'):
            if 'feature_cat' in globals():
                parent_layer = self.feature_cat.parent_layer
            else:
                parent_layer = str(complet_result['body']['feature']['tableParent'])
            sql = f"SELECT lower(feature_type) FROM cat_feature WHERE parent_layer = '{parent_layer}' LIMIT 1"
            result = tools_db.get_row(sql)
            if result:
                self.feature_type = result[0]
        result = complet_result['body']['data']
        return result

    def _open_help(self, feature_type):
        """ Open help file with selected @project_type and @feature_type """

        # Get locale of QGIS application
        locale = tools_qgis.get_locale_schema()
        project_type = tools_gw.get_project_type()
        png_folder = os.path.join(lib_vars.plugin_dir, f'resources{os.sep}png')

        # Try with current locale
        png_path = os.path.join(png_folder, f"{project_type}_{feature_type}_{locale}.png")
        if os.path.exists(png_path):
            os.system(png_path)
            return

        # If locale starts with 'es', try with es_ES
        if locale.startswith('es'):
            png_path = os.path.join(png_folder, f"{project_type}_{feature_type}_es_ES.png")
            if os.path.exists(png_path):
                os.system(png_path)
                return

        # Try with en_US as fallback
        png_path = os.path.join(png_folder, f"{project_type}_{feature_type}_en_US.png")
        if os.path.exists(png_path):
            os.system(png_path)
            return

        # If no help file found, show warning
        message = "No help file found"
        tools_qgis.show_warning(message, parameter=png_path)

    def _block_action_edit(self, dialog, action_edit, result, layer, fid, my_json, new_feature):

        current_layer = self.iface.activeLayer()

        if self.new_feature_id is not None and current_layer == layer:
            self.iface.mainWindow().findChild(QAction, 'mActionToggleEditing').blockSignals(True)
            save = self._stop_editing(dialog, action_edit, layer, fid, my_json, new_feature)
            self.iface.mainWindow().findChild(QAction, 'mActionToggleEditing').blockSignals(False)
            if save and not self.iface.mainWindow().findChild(QAction, 'mActionToggleEditing').isChecked():
                self.iface.mainWindow().findChild(QAction, 'mActionToggleEditing').trigger()

        if self.connected is False:
            self._connect_signals()

    def _connect_signals(self):

        if not self.connected:
            tools_gw.connect_signal(self.layer.editingStarted, self.fct_start_editing,
                                    'info', 'connect_signals_layer_editingStarted_fct_start_editing')
            action_toggle_editing = self.iface.mainWindow().findChild(QAction, 'mActionToggleEditing')
            if action_toggle_editing:
                tools_gw.connect_signal(action_toggle_editing.triggered, self.fct_block_action_edit,
                                        'info', 'connect_signals_action_toggle_editing_triggered_fct_block_action_edit')
            self.connected = True

    def _disconnect_signals(self):

        try:
            tools_gw.disconnect_signal('info', 'connect_signals_layer_editingStarted_fct_start_editing')
        except Exception:
            pass

        try:
            # This signal isn't connected atm, might need to change the name depending on where it's connected
            tools_gw.disconnect_signal('info', 'connect_signals_layer_editingStopped_fct_stop_editing')
        except Exception:
            pass

        try:
            tools_gw.disconnect_signal('info', 'connect_signals_action_toggle_editing_triggered_fct_block_action_edit')
        except Exception:
            pass

        try:
            tools_gw.disconnect_signal('info', 'add_feature_featureAdded_open_new_feature')
        except Exception:
            pass

        try:
            tools_gw.disconnect_signal('info_snapping')
        except Exception:
            pass

        try:
            global_vars.canvas.setMapTool(self.previous_map_tool)
        except Exception:
            pass

        try:
            self.rubber_band.reset()
        except Exception:
            pass

        self.connected = False
        global is_inserting  # noqa: F824
        is_inserting = False

    def _activate_snapping(self, complet_result, ep, refresh_dialog=False):

        self.rb_interpolate = []
        self.interpolate_result = None
        self.last_rb = None
        tools_gw.reset_rubberband(self.rubber_band)

        if refresh_dialog is False:
            dlg_interpolate = GwInterpolate(self)
            tools_gw.load_settings(dlg_interpolate)
        else:
            dlg_interpolate = refresh_dialog

        self.ep = ep

        # Manage QRadioButton interpolate/extrapolate
        rb_name = tools_gw.get_config_parser("btn_info", "rb_action_interpolate", "user", "session")
        self.last_rb = rb_name
        rb_widget = dlg_interpolate.findChild(QRadioButton, rb_name)
        rb_widget.setChecked(True)

        self.msg_infolog = ('Interpolate tool.\n'
               'To modify columns (top_elev, ymax, elev among others) to be interpolated set variable '
               'edit_node_interpolate on table config_param_user')
        tools_qt.set_widget_text(dlg_interpolate, dlg_interpolate.tab_log_txt_infolog, self.msg_infolog)

        self.msg_text = "Please, use the cursor to select two nodes to proceed with the interpolation\nNode1: \nNode2:"
        dlg_interpolate.lbl_text.setText(self.msg_text)

        if refresh_dialog is False:
            # Disable tab log
            tools_gw.disable_tab_log(dlg_interpolate)

            dlg_interpolate.btn_accept.clicked.connect(partial(self._chek_for_existing_values, dlg_interpolate))
            dlg_interpolate.btn_close.clicked.connect(partial(tools_gw.close_dialog, dlg_interpolate))
            dlg_interpolate.rejected.connect(partial(tools_gw.save_settings, dlg_interpolate))
            dlg_interpolate.rejected.connect(partial(self._manage_interpolate_rejected))
            dlg_interpolate.rb_interpolate.clicked.connect(partial(self._change_rb_type, dlg_interpolate, dlg_interpolate.rb_interpolate, complet_result, ep))
            dlg_interpolate.rb_extrapolate.clicked.connect(partial(self._change_rb_type, dlg_interpolate, dlg_interpolate.rb_extrapolate, complet_result, ep))
            dlg_interpolate.btn_accept.setEnabled(False)

            tools_gw.open_dialog(dlg_interpolate, dlg_name='dialog_text')

        # Set circle vertex marker
        self.snapper_manager.set_vertex_marker(self.vertex_marker, icon_type=4)
        self.vertex_marker.show()

        global_vars.canvas.setMapTool(self.ep)
        # We redraw the selected feature because self.canvas.setMapTool(emit_point) erases it
        tools_gw.draw_by_json(complet_result, self.rubber_band, None, False)

        # Store user snapping configuration
        self.previous_snapping = self.snapper_manager.get_snapping_options()

        self.layer_node = tools_qgis.get_layer_by_tablename("ve_node")
        global_vars.iface.setActiveLayer(self.layer_node)

        self.node1 = None
        self.node2 = None

        tools_gw.connect_signal(global_vars.canvas.xyCoordinates, partial(self._mouse_move),
                                'info_snapping', 'activate_snapping_xyCoordinates_mouse_move')
        tools_gw.connect_signal(ep.canvasClicked, partial(self._snapping_node, dlg_interpolate),
                                'info_snapping', 'activate_snapping_ep_canvasClicked_snapping_node')

    def _manage_interpolate_rejected(self):

        tools_gw.disconnect_signal('info_snapping', 'activate_snapping_xyCoordinates_mouse_move')
        tools_gw.disconnect_signal('info_snapping', 'activate_snapping_ep_canvasClicked_snapping_node')
        self._remove_interpolate_rb()
        self.vertex_marker.hide()
        self.iface.actionPan().trigger()

    def _change_rb_type(self, dialog, widget, complet_result, ep):
        """ Function to manage radioButton interpolate/extrapolate"""

        if widget.objectName() != self.last_rb:
            self.last_rb = widget.objectName()
            tools_gw.set_config_parser("btn_info", "rb_action_interpolate", f"{widget.objectName()}")
            self._manage_interpolate_rejected()
            self._activate_snapping(complet_result, ep, refresh_dialog=dialog)

    def _snapping_node(self, dlg_interpolate, point, button):
        """ Get id of selected nodes (node1 and node2) """

        if button == 2:
            self._dlg_destroyed(self.layer)
            return

        # Get coordinates
        event_point = self.snapper_manager.get_event_point(point=point)
        if not event_point:
            return

        # Snapping
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if result.isValid():
            layer = self.snapper_manager.get_snapped_layer(result)
            # Check feature
            if layer == self.layer_node:
                snapped_feat = self.snapper_manager.get_snapped_feature(result)
                element_id = snapped_feat.attribute('node_id')
                msg = "Selected node"
                rb = tools_gw.create_rubberband(global_vars.canvas, "point")
                if self.node1 is None:
                    self.node1 = str(element_id)
                    tools_qgis.draw_point(QgsPointXY(result.point()), rb, color=QColor(0, 150, 55, 100), width=10)
                    self.rb_interpolate.append(rb)
                    dlg_interpolate.lbl_text.setText(f"Node1: {self.node1}\nNode2:")
                    tools_qgis.show_message(msg, message_level=Qgis.MessageLevel.Info, parameter=self.node1)
                    dlg_interpolate.btn_accept.setEnabled(False)
                elif self.node1 != str(element_id):
                    self.node2 = str(element_id)
                    tools_qgis.draw_point(QgsPointXY(result.point()), rb, color=QColor(0, 150, 55, 100), width=10)
                    self.rb_interpolate.append(rb)
                    dlg_interpolate.lbl_text.setText(f"Node1: {self.node1}\nNode2: {self.node2}")
                    tools_qgis.show_message(msg, message_level=Qgis.MessageLevel.Info, parameter=self.node2)
                    dlg_interpolate.btn_accept.setEnabled(True)

        if self.node1 and self.node2:

            # Get checkbox extrapolate value from dialog
            rb_extrapolate = dlg_interpolate.findChild(QRadioButton, 'rb_extrapolate')

            action_dict = {True: 'EXTRAPOLATE', False: 'INTERPOLATE'}

            tools_gw.disconnect_signal('info_snapping', 'activate_snapping_xyCoordinates_mouse_move')
            tools_gw.disconnect_signal('info_snapping', 'activate_snapping_ep_canvasClicked_snapping_node')

            global_vars.iface.setActiveLayer(self.layer)
            self.vertex_marker.hide()
            extras = '"parameters":{'
            extras += f'"action":"{action_dict[rb_extrapolate.isChecked()]}", '
            extras += f'"x":{self.last_point[0]}, '
            extras += f'"y":{self.last_point[1]}, '
            extras += f'"node1":"{self.node1}", '
            extras += f'"node2":"{self.node2}"}}'
            body = tools_gw.create_body(extras=extras)
            self.interpolate_result = tools_gw.execute_procedure('gw_fct_node_interpolate', body)
            if not self.interpolate_result or self.interpolate_result['status'] == 'Failed':
                return False
            tools_gw.fill_tab_log(dlg_interpolate, self.interpolate_result['body']['data'], close=False)

            self.iface.actionPan().trigger()

    def _chek_for_existing_values(self, dlg_interpolate):

        text = False
        for k, v in self.interpolate_result['body']['data']['fields'][0].items():
            widget = self.dlg_cf.findChild(QWidget, k)
            if widget and len(v) > 0:
                text = tools_qt.get_text(self.dlg_cf, widget, False, False)
                if text:
                    msg = "Do you want to overwrite custom values?"
                    title = "Overwrite values"
                    answer = tools_qt.show_question(msg, title)
                    if answer:
                        self._set_values(dlg_interpolate)
                    break
        if not text:
            self._set_values(dlg_interpolate)

    def _set_values(self, dlg_interpolate):

        # Set values tu info form
        for k, v in self.interpolate_result['body']['data']['fields'][0].items():
            widget = self.dlg_cf.findChild(QWidget, k)
            if widget and len(v) > 0:
                widget.setStyleSheet(None)
                tools_qt.set_widget_text(self.dlg_cf, widget, f'{v}')
                widget.editingFinished.emit()
        tools_gw.close_dialog(dlg_interpolate)

    def _dlg_destroyed(self, layer=None, vertex=None):

        self.dlg_is_destroyed = True
        if layer is not None:
            global_vars.iface.setActiveLayer(layer)
        if vertex is not None:
            global_vars.iface.mapCanvas().scene().removeItem(vertex)
        else:
            if hasattr(self, 'vertex_marker'):
                if self.vertex_marker is not None:
                    global_vars.iface.mapCanvas().scene().removeItem(self.vertex_marker)
        try:
            global_vars.canvas.xyCoordinates.disconnect()
        except Exception:
            pass

    def _remove_interpolate_rb(self):

        # Remove the circumferences made by the interpolate
        for rb in self.rb_interpolate:
            global_vars.iface.mapCanvas().scene().removeItem(rb)

    def _mouse_move(self, point):

        # Get clicked point
        event_point = self.snapper_manager.get_event_point(point=point)

        # Snapping
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if result.isValid():
            layer = self.snapper_manager.get_snapped_layer(result)
            if layer == self.layer_node:
                self.snapper_manager.add_marker(result, self.vertex_marker)
        else:
            self.vertex_marker.hide()

    def _change_hemisphere(self, dialog, action):

        # Set map tool emit point and signals
        tools_gw.disconnect_signal('info_snapping', 'change_hemisphere_ep_canvasClicked_action_rotation_canvas_clicked')
        emit_point = QgsMapToolEmitPoint(global_vars.canvas)
        self.previous_map_tool = global_vars.canvas.mapTool()
        global_vars.canvas.setMapTool(emit_point)
        tools_gw.connect_signal(emit_point.canvasClicked, partial(self._action_rotation_canvas_clicked, dialog, action, emit_point),
                                'info_snapping', 'change_hemisphere_ep_canvasClicked_action_rotation_canvas_clicked')

    def _action_rotation_canvas_clicked(self, dialog, action, emit_point, point, btn):

        if btn == Qt.MouseButton.RightButton:
            global_vars.canvas.setMapTool(self.previous_map_tool)
            return

        existing_point_x = None
        existing_point_y = None
        viewname = tools_qgis.get_layer_source_table_name(self.layer)
        sql = (f"SELECT ST_X(the_geom), ST_Y(the_geom)"
               f" FROM {viewname}"
               f" WHERE node_id = '{self.feature_id}'")
        row = tools_db.get_row(sql)

        if row:
            existing_point_x = row[0]
            existing_point_y = row[1]

        if existing_point_x:
            sql = (f"UPDATE node"
                   f" SET hemisphere = (SELECT degrees(ST_Azimuth(ST_Point({existing_point_x}, {existing_point_y}), "
                   f" ST_Point({point.x()}, {point.y()}))))"
                   f" WHERE node_id = '{self.feature_id}'")
            status = tools_db.execute_sql(sql)
            if not status:
                global_vars.canvas.setMapTool(self.previous_map_tool)
                return

        sql = (f"SELECT rotation FROM node "
               f" WHERE node_id = '{self.feature_id}'")
        row = tools_db.get_row(sql)
        if row:
            tools_qt.set_widget_text(dialog, "tab_data_rotation", str(row[0]))

        sql = (f"SELECT degrees(ST_Azimuth(ST_Point({existing_point_x}, {existing_point_y}),"
               f" ST_Point({point.x()}, {point.y()})))")
        row = tools_db.get_row(sql)
        if row:
            tools_qt.set_widget_text(dialog, "tab_data_hemisphere", str(row[0]))
            message = "Hemisphere of the node has been updated. Value is"
            tools_qgis.show_info(message, parameter=str(row[0]))

        # Disable Rotation
        action_widget = dialog.findChild(QAction, "actionRotation")
        if action_widget:
            action_widget.setChecked(False)
        tools_gw.disconnect_signal('info_snapping', 'change_hemisphere_ep_canvasClicked_action_rotation_canvas_clicked')

    def _manage_action_copy_paste(self, dialog, feature_type, tab_type=None):
        """ Copy some fields from snapped feature to current feature """

        # Set map tool emit point and signals
        tools_gw.disconnect_signal('info_snapping', 'manage_action_copy_paste_ep_canvasClicked')
        emit_point = QgsMapToolEmitPoint(global_vars.canvas)
        global_vars.canvas.setMapTool(emit_point)
        tools_gw.disconnect_signal('info_snapping', 'manage_action_copy_paste_xyCoordinates_mouse_move')
        tools_gw.connect_signal(global_vars.canvas.xyCoordinates, self._manage_action_copy_paste_mouse_move,
                                'info_snapping', 'manage_action_copy_paste_xyCoordinates_mouse_move')
        tools_gw.connect_signal(emit_point.canvasClicked, partial(self._manage_action_copy_paste_canvas_clicked, dialog, tab_type, emit_point),
                                'info_snapping', 'manage_action_copy_paste_ep_canvasClicked')

        self.feature_type = feature_type

        # Store user snapping configuration
        self.previous_snapping = self.snapper_manager.get_snapping_options()

        # Set snapping
        # layer = global_vars.iface.activeLayer() TODO: Remove this line if not needed

        if feature_type == 'node':
            self.snapper_manager.set_vertex_marker(self.vertex_marker, icon_type=4)

    def _manage_action_copy_paste_mouse_move(self, point):
        """ Slot function when mouse is moved in the canvas.
            Add marker if any feature is snapped
        """

        # Hide marker and get coordinates
        self.vertex_marker.hide()
        event_point = self.snapper_manager.get_event_point(point=point)

        # Snapping
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if not result.isValid():
            return

        # Add marker to snapped feature
        self.snapper_manager.add_marker(result, self.vertex_marker)

    def _manage_action_copy_paste_canvas_clicked(self, dialog, tab_type, emit_point, point, btn):
        """ Slot function when canvas is clicked """

        if btn == Qt.MouseButton.RightButton:
            self._manage_disable_copy_paste(dialog, emit_point)
            return

        # Get clicked point
        event_point = self.snapper_manager.get_event_point(point=point)

        # Snapping
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if not result.isValid():
            self._manage_disable_copy_paste(dialog, emit_point)
            return

        layer = global_vars.iface.activeLayer()
        layername = layer.name()

        # Get the point. Leave selection
        snapped_feature = self.snapper_manager.get_snapped_feature(result, True)
        snapped_feature_attr = snapped_feature.attributes()

        aux = f'"{self.feature_type}_id" = '
        aux += f"'{self.feature_id}'"
        expr = QgsExpression(aux)
        if expr.hasParserError():
            message = "Expression Error"
            tools_qgis.show_warning(message, parameter=expr.parserErrorString())
            self._manage_disable_copy_paste(dialog, emit_point)
            return

        fields = layer.dataProvider().fields()
        layer.startEditing()
        it = layer.getFeatures(QgsFeatureRequest(expr))
        feature_list = [i for i in it]
        if not feature_list:
            self._manage_disable_copy_paste(dialog, emit_point)
            return

        # Select only first element of the feature list
        feature = feature_list[0]
        feature_id = feature.attribute(str(self.feature_type) + '_id')
        msg = (f'''{tools_qt.tr('Selected snapped feature_id to copy values from')}: {snapped_feature_attr[0]}\n'''
               f'''{tools_qt.tr('Do you want to copy its values to the current node?')}\n\n''')
        # Replace id because we don't have to copy it!
        snapped_feature_attr[0] = feature_id
        snapped_feature_attr_aux = []
        fields_aux = []

        # Iterate over all fields and copy only specific ones
        for i in range(0, len(fields)):
            if fields[i].name() == 'sector_id' or fields[i].name() == 'dma_id' or fields[i].name() == 'expl_id' \
                    or fields[i].name() == 'state' or fields[i].name() == 'state_type' \
                    or fields[i].name() == layername + '_workcat_id' or fields[i].name() == layername + '_builtdate' \
                    or fields[i].name() == 'verified' or fields[i].name() == str(self.feature_type) + 'cat_id':
                snapped_feature_attr_aux.append(snapped_feature_attr[i])
                fields_aux.append(fields[i].name())
            if global_vars.project_type == 'ud':
                if fields[i].name() == str(self.feature_type) + '_type':
                    snapped_feature_attr_aux.append(snapped_feature_attr[i])
                    fields_aux.append(fields[i].name())

        for i in range(0, len(fields_aux)):
            msg += f"{fields_aux[i]}: {snapped_feature_attr_aux[i]}\n"

        # Ask confirmation question showing fields that will be copied
        title = "Update records"
        answer = tools_qt.show_question(msg, title, None)
        if answer:
            for i in range(0, len(fields)):
                for x in range(0, len(fields_aux)):
                    if fields[i].name() == fields_aux[x]:
                        layer.changeAttributeValue(feature.id(), i, snapped_feature_attr_aux[x])

            layer.commitChanges()

            # dialog.refreshFeature()
            for i in range(0, len(fields_aux)):
                widget = dialog.findChild(QWidget, tab_type + "_" + fields_aux[i])
                if tools_qt.get_widget_type(dialog, widget) is QLineEdit:
                    tools_qt.set_widget_text(dialog, widget, str(snapped_feature_attr_aux[i]))
                elif isinstance(tools_qt.get_widget_type(dialog, widget), QComboBox):
                    tools_qt.set_combo_value(widget, str(snapped_feature_attr_aux[i]), 0)

        self._manage_disable_copy_paste(dialog, emit_point)

    def _manage_disable_copy_paste(self, dialog, emit_point):
        """ Disable actionCopyPaste and set action 'Identify' """

        action_widget = dialog.findChild(QAction, "actionCopyPaste")
        if action_widget:
            action_widget.setChecked(False)

        try:
            self.vertex_marker.hide()
            tools_gw.disconnect_signal('info_snapping', 'manage_action_copy_paste_xyCoordinates_mouse_move')
            tools_gw.disconnect_signal('info_snapping', 'manage_action_copy_paste_ep_canvasClicked')
        except Exception:
            pass

    def _manage_docker_close(self):

        self._roll_back()
        tools_gw.reset_rubberband(self.rubber_band)
        self._remove_layer_selection()
        lib_vars.session_vars['dialog_docker'].widget().dlg_closed.disconnect()
        self._reset_my_json()
        tools_gw.close_docker()

    def _remove_layer_selection(self):

        try:
            self.layer.removeSelection()
        except RuntimeError:
            pass

    def _manage_info_close(self, dialog):

        self._roll_back()
        tools_gw.reset_rubberband(self.rubber_band)
        tools_gw.save_settings(dialog)
        tools_gw.close_dialog(dialog)

    def _get_feature(self, tab_type):
        """ Get current QgsFeature """

        expr_filter = f"{self.field_id} = '{self.feature_id}'"
        self.feature = tools_qgis.get_feature_by_expr(self.layer, expr_filter)
        return self.feature

    def _manage_action_centered(self, canvas, layer):
        """ Center map to current feature """

        if not self.feature:
            self._get_feature(self.tab_type)
        layer.selectByIds([self.feature.id()])
        canvas.zoomToSelected(layer)

    def _get_last_value(self, dialog, generic=False):

        if generic:
            widgets = dialog.findChildren(QWidget)
            for widget in widgets:
                if widget.hasFocus():
                    # Use get_values for proper combo handling (gets ID instead of text)
                    tools_gw.get_values(dialog, widget, self.my_json, ignore_editability=True)
                    widget.clearFocus()
        else:
            try:
                # Widgets in ('lyt_top_1', 'lyt_bot_1', 'lyt_bot_2')
                other_widgets = []
                for field in self.complet_result['body']['data']['fields']:
                    if field['layoutname'] in ('lyt_top_1', 'lyt_bot_1', 'lyt_bot_2'):
                        widget = dialog.findChild(QWidget, field['widgetname'])
                        if widget:
                            other_widgets.append(widget)
                # Widgets in tab_data
                widgets = dialog.tab_data.findChildren(QWidget)
                widgets.extend(other_widgets)
                for widget in widgets:
                    if widget.hasFocus():
                        # Use get_values for proper combo handling (gets ID instead of text)
                        tools_gw.get_values(dialog, widget, self.my_json, ignore_editability=True)
                        widget.clearFocus()
                # Widgets in tab_epa
                widgets = dialog.tab_epa.findChildren(QWidget)
                widgets.extend(other_widgets)
                for widget in widgets:
                    if widget.hasFocus():
                        # Use get_values for proper combo handling (gets ID instead of text)
                        tools_gw.get_values(dialog, widget, self.my_json_epa, ignore_editability=True)
                        widget.clearFocus()
            except RuntimeError:
                pass

    def _apply_from_btn(self, dialog, action_edit, fid, new_feature=None, generic=False, from_apply=False, linked_feature=None):
        """ Manage apply button from info dialog """

        self._manage_edition(dialog, action_edit, fid, new_feature, generic, from_apply)

        if linked_feature:
            self._manage_linked_feature(linked_feature)

    def _manage_edition(self, dialog, action_edit, fid, new_feature=None, generic=False, from_apply=False):

        # With the editing QAction we need to collect the last modified value (self.get_last_value()),
        # since the "editingFinished" signals of the widgets are not detected.
        # Therefore whenever the cursor enters a widget, it will ask if we want to save changes
        if not action_edit.isChecked() or from_apply:
            self._get_last_value(dialog, generic)
            if str(self.my_json) == '{}' and str(self.my_json_epa) == '{}':
                tools_qt.set_action_checked(action_edit, False)
                tools_gw.enable_widgets(dialog, self.complet_result['body']['data'], False)
                if self.epa_complet_result:
                    tools_gw.enable_widgets(dialog, self.epa_complet_result['body']['data'], False)
                self._enable_actions(dialog, False)
                return
            save = self._ask_for_save(action_edit, fid)
            accepted = False
            if save:
                accepted = self._manage_accept(dialog, action_edit, new_feature, self.my_json, False, generic)
            elif self.new_feature_id is not None:
                if lib_vars.session_vars['dialog_docker'] and lib_vars.session_vars['info_docker']:
                    self._manage_docker_close()
                else:
                    tools_gw.close_dialog(dialog)
            if new_feature:
                for tab in self.visible_tabs:
                    tools_qt.enable_tab_by_tab_name(self.tab_main, self.visible_tabs[tab]['tabName'], True)
            if save and accepted:
                self._reload_epa_tab(dialog)
                self._reset_my_json()
            if from_apply:
                action_edit.setChecked(True)
                tools_gw.enable_all(dialog, self.complet_result['body']['data'], from_apply=True)
                if self.epa_complet_result:
                    tools_gw.enable_all(dialog, self.epa_complet_result['body']['data'], from_apply=True)
        else:
            tools_qt.set_action_checked(action_edit, True)
            tools_gw.enable_all(dialog, self.complet_result['body']['data'])
            if self.epa_complet_result:
                tools_gw.enable_all(dialog, self.epa_complet_result['body']['data'])
            self._enable_actions(dialog, True)

    def _accept_from_btn(self, dialog, action_edit, new_feature, my_json, last_json, generic=False, linked_feature=None):
        if not action_edit.isChecked():
            tools_gw.close_dialog(dialog)
            return

        status = self._manage_accept(dialog, action_edit, new_feature, my_json, True, generic)
        if status:
            self._reset_my_json()

        if linked_feature:
            self._manage_linked_feature(linked_feature)

    def _manage_accept(self, dialog, action_edit, new_feature, my_json, close_dlg, generic=False):

        self._get_last_value(dialog, generic)
        if not self._merge_epa_type_on_accept(dialog, my_json, new_feature):
            return False
        status = self._accept(dialog, self.complet_result, my_json, close_dlg=close_dlg, new_feature=new_feature, generic=generic)
        if status:  # Commit succesfull and dialog keep opened
            tools_qt.set_action_checked(action_edit, False)
            tools_gw.enable_widgets(dialog, self.complet_result['body']['data'], False)
            if self.epa_complet_result:
                tools_gw.enable_widgets(dialog, self.epa_complet_result['body']['data'], False)
            self._enable_actions(dialog, False)
        return status

    def _stop_editing(self, dialog, action_edit, layer, fid, my_json, new_feature=None):

        if (my_json == '' or str(my_json) == '{}') and (self.my_json_epa == '' or str(self.my_json_epa) == '{}'):
            QgsProject.instance().blockSignals(True)
            tools_qt.set_action_checked(action_edit, False)
            tools_gw.enable_widgets(dialog, self.complet_result['body']['data'], False)
            if self.epa_complet_result:
                tools_gw.enable_widgets(dialog, self.epa_complet_result['body']['data'], False)
            self._enable_actions(dialog, False)
            QgsProject.instance().blockSignals(False)
        else:
            save = self._ask_for_save(action_edit, fid)
            if save:
                self._reset_my_json()
                accepted = self._manage_accept(dialog, action_edit, new_feature, my_json, False)
                if accepted:
                    self._reset_my_json()

            return save

    def _manage_linked_feature(self, linked_feature):
        """ Manage linked feature after accept action """
        if linked_feature.get('table_name'):
            sql = f"SELECT * FROM {linked_feature['table_name']} WHERE {linked_feature['columnname']} = '{linked_feature['element_id']}'"
            linked = tools_db.get_row(sql)
            if not linked:
                element_widget = linked_feature['dialog'].tab_elements.findChild(QWidget, 'tab_elements_element_id')
                insert_widget = linked_feature['dialog'].tab_elements.findChild(QPushButton, 'tab_elements_insert_element')
                if element_widget and insert_widget:
                    element_widget.setText(linked_feature.get('element_id', ''))
                    insert_widget.click()
                    element_widget.setText('')
            else:
                _reload_table(**linked_feature)

    def _start_editing(self, dialog, action_edit, result, layer):

        QgsProject.instance().blockSignals(True)
        self.iface.setActiveLayer(layer)
        tools_qt.set_action_checked(action_edit, True)
        tools_gw.enable_all(dialog, self.complet_result['body']['data'])
        if self.epa_complet_result:
            tools_gw.enable_all(dialog, self.epa_complet_result['body']['data'])
        self._enable_actions(dialog, True)
        layer.startEditing()
        QgsProject.instance().blockSignals(False)

    def _ask_for_save(self, action_edit, fid):

        msg = tools_qt.tr('Are you sure to save this feature?')
        title = tools_qt.tr("Save feature")
        answer = tools_qt.show_question(msg, title, None, parameter=fid)
        if not answer:
            tools_qt.set_action_checked(action_edit, True)
            return False
        return True

    def _roll_back(self):
        """ Discard changes in current layer """
        self._disconnect_signals()
        try:
            self.iface.actionRollbackEdits().trigger()
        except TypeError:
            pass

        try:
            self.layer_new_feature.rollBack()
        except AttributeError:
            pass
        except RuntimeError:
            pass

        try:
            self.layer.rollBack()
        except AttributeError:
            pass
        except RuntimeError:
            pass

    def _open_section_form(self):

        dlg_sections = GwInfoCrossectUi(self)
        tools_gw.load_settings(dlg_sections)

        # Set dialog not resizable
        dlg_sections.setFixedSize(757, 462)

        feature = '"id":"' + self.feature_id + '"'
        body = tools_gw.create_body(feature=feature)
        json_result = tools_gw.execute_procedure('gw_fct_getinfocrossection', body)
        if not json_result or json_result['status'] == 'Failed':
            return False

        # Set values into QLineEdits
        for field in json_result['body']['data']['fields']:
            widget = dlg_sections.findChild(QLineEdit, field['columnname'])
            if widget:
                if 'value' in field:
                    tools_qt.set_widget_text(dlg_sections, widget, field['value'])

        dlg_sections.btn_close.clicked.connect(partial(tools_gw.close_dialog, dlg_sections))

        # Open the dialog first
        tools_gw.open_dialog(dlg_sections, dlg_name='info_crossect')

        img = json_result['body']['data']['shapepng']
        tools_qt.add_image(dlg_sections, 'lbl_section_image', f"{self.plugin_dir}{os.sep}resources{os.sep}png{os.sep}{img}")

        # Hide conduit and trench calculation fields
        widgets_to_hide = ['lbl_cost_bulk', 'bulk', 'lbl_cost_area', 'area', 'lbl_cost_excav', 'm3mlexc',
                          'lbl_cost_fill', 'm3mlfill', 'lbl_cost_exc', 'm3mlexcess', 'lbl_cost_trench', 'm2mltrenchl']
        for widget_name in widgets_to_hide:
            widget = dlg_sections.findChild(QWidget, widget_name)
            if widget:
                widget.setVisible(False)

    def _accept(self, dialog, complet_result, _json, p_widget=None, clear_json=False, close_dlg=True, new_feature=None, generic=False):
        """
        :param dialog:
        :param complet_result:
        :param _json:
        :param p_widget:
        :param clear_json:
        :param close_dlg:
        :return: (boolean)
        """

        # QgsProject.instance().blockSignals(True)
        # It's not necessary to block signals because the code isn't changing snapping configuration anymore.

        # Check if C++ object has been deleted
        if isdeleted(dialog):
            return False

        after_insert = False

        # Tab data
        p_table_id = complet_result['body']['feature']['tableName']
        id_name = complet_result['body']['feature']['idName']
        newfeature_id = complet_result['body']['feature']['id']
        list_mandatory = []
        skip_mandatory = bool(_json) and set(_json.keys()) == {'epa_type'}
        # Manage autoupdate and mandatory widgets
        fields_reload = self._manage_autoupdate_and_mandatory_widgets(dialog, complet_result, p_widget, list_mandatory)

        if list_mandatory and not skip_mandatory:
            msg = "Some mandatory values are missing. Please check the widgets marked in red."
            tools_qgis.show_warning(msg, dialog=dialog)
            tools_qt.set_action_checked("actionEdit", True, dialog)
            return False

        # Manage tab data
        if _json != '' and str(_json) != '{}':

            # If we create a new feature
            if self.new_feature_id is not None:
                if new_feature is False:
                    new_feature = tools_qt.get_feature_by_id(self.layer, self.new_feature_id)
                new_feature.setAttribute(id_name, newfeature_id)

                # Get the geometry from the feature
                if new_feature and new_feature.hasGeometry():
                    _json['the_geom'] = new_feature.geometry().asWkt()

                epa_type = tools_qt.get_text(dialog, 'tab_data_epa_type')
                if epa_type != 'null':
                    _json['epa_type'] = epa_type

                self.new_feature_id = None
                self._enable_action(dialog, "actionCentered", True)
                self._enable_action(dialog, "actionAudit", True)
                self._enable_action(dialog, "actionSetToArc", True)
                global is_inserting  # noqa: F824
                is_inserting = False

                if self.new_feature.attribute(id_name) is not None:
                    feature = f'"id":"{self.new_feature.attribute(id_name)}", '
                else:
                    feature = f'"id":"{self.feature_id}", '

            # If we make an info
            else:
                feature = f'"id":"{self.feature_id}", '

            feature += f'"tableName":"{p_table_id}", '
            feature += f' "featureType":"{self.feature_type}" '
            extras = f'"fields":{json.dumps(_json)}, "reload":"{fields_reload}"'
            body = tools_gw.create_body(feature=feature, extras=extras)

            # Get utils_graphanalytics_automatic_trigger param
            row = tools_gw.get_config_value("utils_graphanalytics_automatic_trigger", table='config_param_system')
            thread = row[0] if row else None
            if thread:
                thread = json.loads(thread)
                thread = tools_os.set_boolean(thread['status'], default=False)
                if 'closed' not in _json:
                    thread = False
            epa_type_changed = False
            new_epa_type_value = None
            if 'epa_type' in _json:
                epa_type_changed = True
                new_epa_type_value = _json.get('epa_type')

            json_result = tools_gw.execute_procedure('gw_fct_setfields', body)
            if not json_result:
                return False

            if clear_json:
                _json.clear()

            if "Failed" in json_result['status']:
                msg = json_result['message']['text']
                if msg is None:
                    msg = tools_qt.tr('Feature not upserted')
                msg_level = json_result['message']['level']
                if msg_level is None:
                    msg_level = 2
                msg_level = Qgis.MessageLevel(msg_level)
                tools_qgis.show_message(msg, message_level=msg_level, dialog=dialog)
                return False

            if "Accepted" in json_result['status']:
                msg = json_result['message']['text']
                if msg is None:
                    msg = tools_qt.tr('Feature upserted')
                msg_level = json_result['message']['level']
                if msg_level is None:
                    msg_level = 1
                msg_level = Qgis.MessageLevel(msg_level)
                tools_qgis.show_message(msg, message_level=msg_level, dialog=dialog)
                self._reload_fields(dialog, json_result, p_widget)
                if epa_type_changed:
                    self.epa_type = str(new_epa_type_value)
                    self._reload_epa_tab(dialog)

                # Update geometry field (if user have selected a point)
                if self.point_xy['x'] is not None:
                    self._update_geom(p_table_id, id_name, newfeature_id)

                if thread:
                    # If param is true show question and create thread
                    msg = "You closed a valve, this will modify the current mapzones and it may take a little bit of time."
                    if lib_vars.user_level['level'] in ('1', '2'):
                        msg = ("You closed a valve, this will modify the current mapzones and it may take a little bit of time."
                              "Would you like to continue?")
                        answer = tools_qt.show_question(msg)
                    else:
                        tools_qgis.show_info(msg)
                        answer = True

                    if answer:
                        params = {"body": body}
                        self.valve_thread = GwToggleValveTask("Update mapzones", params)
                        QgsApplication.taskManager().addTask(self.valve_thread)
                        QgsApplication.taskManager().triggerTask(self.valve_thread)

        # Tab EPA
        if not generic and self.my_json_epa != '' and str(self.my_json_epa) != '{}':
            feature = f'"id":"{self.feature_id}", '
            epa_type = tools_qt.get_text(dialog, 'tab_data_epa_type').lower()
            epa_table_id = 've_epa_' + epa_type
            if global_vars.project_type == 'ws' and self.feature_type == 'connec' and epa_type == 'junction':
                epa_table_id = 've_epa_connec'
            my_json = json.dumps(self.my_json_epa)
            if self.feature_type.lower() == 'link':
                feature += '"tableName":"ve_epa_link", '
            else:
                feature += f'"tableName":"{epa_table_id}", '
            feature += f' "featureType":"{self.feature_type}" '
            extras = f'"fields":{my_json}, "afterInsert":"{after_insert}"'
            body = tools_gw.create_body(feature=feature, extras=extras)
            json_result = tools_gw.execute_procedure('gw_fct_setfields', body)
            self._reset_my_json_epa()
            if not json_result or "Failed" in json_result['status']:
                return False

        # Force a map refresh
        tools_qgis.refresh_map_canvas()  # First refresh all the layers
        global_vars.iface.mapCanvas().refresh()  # Then refresh the map view itself
        # Refresh psector's relations tables
        tools_gw.execute_class_function(GwPsectorUi, '_refresh_tables_relations')

        if close_dlg:
            if lib_vars.session_vars['dialog_docker'] and dialog == lib_vars.session_vars['dialog_docker'].widget():
                self._manage_docker_close()
            else:
                tools_gw.close_dialog(dialog)
            return None

        return True

    def _manage_autoupdate_and_mandatory_widgets(self, dialog, complet_result, p_widget, list_mandatory):
        fields_reload = ""
        for field in complet_result['body']['data']['fields']:
            if field.get('hidden', False):
                continue

            if p_widget and (field['widgetname'] == p_widget.objectName()):
                if field['widgetcontrols'] and 'autoupdateReloadFields' in field['widgetcontrols']:
                    fields_reload = field['widgetcontrols']['autoupdateReloadFields']

            if field['ismandatory']:
                widget = dialog.findChild(QWidget, field['widgetname'])
                widget.setStyleSheet(None)
                value = tools_qt.get_text(dialog, widget)
                if value in ('null', None, ''):
                    widget.setStyleSheet("border: 1px solid red")
                    list_mandatory.append(field['widgetname'])
        return fields_reload

    def _manage_prev_action(self):
        if self.prev_action:
            self.prev_action.action.trigger()

    def _enable_actions(self, dialog, enabled):
        """ Enable actions according if layer is editable or not """

        try:
            actions_list = dialog.findChildren(QAction)
            static_actions = ('actionEdit', 'actionCentered', 'actionLink', 'actionHelp',
                              'actionSection', 'actionOrifice', 'actionOutlet', 'actionWeir', 'actionDemand')

            for action in actions_list:
                if action.objectName() not in static_actions and action.objectName() != 'actionAudit':
                    self._enable_action(dialog, action, enabled)

            # When we are inserting we want the activation of QAction to be governed by the database,
            # when we are editing, it will govern the editing state of the layer.
            global is_inserting  # noqa: F824
            if not is_inserting:
                return

            # Get index of selected tab
            index_tab = self.tab_main.currentIndex()
            tab_name = self.tab_main.widget(index_tab).objectName()

            if 'visibleTabs' not in self.complet_result['body']['form']:
                return
            for tab in self.visible_tabs:
                if self.visible_tabs[tab]['tabName'] == tab_name:
                    if self.visible_tabs[tab]['tabactions'] is not None:
                        for act in self.visible_tabs[tab]['tabactions']:
                            action = dialog.findChild(QAction, act['actionName'])
                            if action is not None and action.objectName() not in static_actions and action.objectName() != 'actionAudit':
                                action.setEnabled(not act['disabled'])

        except RuntimeError:
            pass

    def _enable_action(self, dialog, action, enabled):

        if type(action) is str:
            action = dialog.findChild(QAction, action)
        if not action:
            return
        action.setEnabled(enabled)

    def _check_datatype_validator(self, dialog, widget, btn):
        """
        functions called in ->  getattr(tools_gw, f"check_{widget.property('datatype')}")(value, widget, btn)
            def check_integer(self, value, widget, btn_accept)
            def check_double(self, value, widget, btn_accept)
        """

        value = tools_qt.get_text(dialog, widget, return_string_null=False)
        try:
            getattr(self, f"_check_{widget.property('datatype')}")(value, widget, btn)
        except AttributeError:
            """ If the function called by getattr don't exist raise this exception """

    def _check_double(self, value, widget, btn_accept):
        """ Check if the value is double or not.
            This function is called in def check_datatype_validator(self, value, widget, btn)
            getattr(self, f"check_{widget.property('datatype')}")(value, widget, btn)
        """

        if value is None or bool(re.search(r"^\d*$", value)) or bool(re.search(r"^\d+\.\d+$", value)):
            widget.setStyleSheet(None)
            btn_accept.setEnabled(True)
        else:
            widget.setStyleSheet("border: 1px solid red")
            btn_accept.setEnabled(False)

    def _check_integer(self, value, widget, btn_accept):
        """ Check if the value is an integer or not.
            This function is called in def check_datatype_validator(self, value, widget, btn)
            getattr(self, f"check_{widget.property('datatype')}")(value, widget, btn)
        """

        if value is None or bool(re.search(r"^\d*$", value)):
            widget.setStyleSheet(None)
            btn_accept.setEnabled(True)
        else:
            widget.setStyleSheet("border: 1px solid red")
            btn_accept.setEnabled(False)

    def _check_min_max_value(self, dialog, widget, btn_accept):

        value = tools_qt.get_text(dialog, widget, return_string_null=False)
        try:
            if value and ((widget.property('minValue') and float(value) < float(widget.property('minValue')))
                    or (widget.property('maxValue') and float(value) > float(widget.property('maxValue')))):
                widget.setStyleSheet("border: 1px solid red")
                btn_accept.setEnabled(False)
            else:
                widget.setStyleSheet(None)
                btn_accept.setEnabled(True)
        except ValueError:
            widget.setStyleSheet("border: 1px solid red")
            btn_accept.setEnabled(False)

    def _check_tab_data(self, field):
        """ Check if current tab name is tab_data """

        if field.get('tabname') != 'tab_data':
            return False
        return True

    def _clean_my_json(self, widget):
        """ Delete keys if exist, when widget is autoupdate """

        try:
            self.my_json.pop(str(widget.property('columnname')), None)
        except KeyError:
            pass

    def _reset_my_json(self, reset_epa=True):
        """ Clear the my_json dictionary """

        self.my_json.clear()
        if reset_epa:
            self._reset_my_json_epa()

    def _reset_my_json_epa(self):
        """ Clear the my_json_epa dictionary """
        self.my_json_epa.clear()

    def _set_auto_update_lineedit(self, field, dialog, widget, new_feature=None):

        if widget.property('isfilter'):
            return widget
        if widget.property('widgetcontrols') is not None and 'saveValue' in widget.property('widgetcontrols'):
            if widget.property('widgetcontrols')['saveValue'] is False:
                return widget

        if self._check_tab_data(field):  # Tab data
            # "and field['widgettype'] != 'typeahead'" It is necessary so that the textchanged signal of the typeahead
            # does not jump, making it lose focus, which will cause the accept function to jump sent invalid parameters
            if field['isautoupdate'] and self.new_feature_id is None and field['widgettype'] != 'typeahead':
                _json = {}
                widget.editingFinished.connect(partial(self._clean_my_json, widget))
                widget.editingFinished.connect(partial(tools_gw.get_values, dialog, widget, _json))
                widget.editingFinished.connect(partial(self._accept_auto_update, dialog, self.complet_result, _json, widget, True, False, new_feature=new_feature))
            else:
                widget.editingFinished.connect(partial(tools_gw.get_values, dialog, widget, self.my_json))
        else:  # Other tabs
            widget.editingFinished.connect(partial(tools_gw.get_values, dialog, widget, self.my_json_epa))
            # TODO: Make autoupdate widgets work
        widget.textChanged.connect(partial(self._enabled_accept, dialog))
        widget.textChanged.connect(partial(self._check_min_max_value, dialog, widget, dialog.btn_accept))
        widget.textChanged.connect(partial(self._check_datatype_validator, dialog, widget, dialog.btn_accept))

        return widget

    def _confirm_epa_type_change(self, dialog, new_feature=None):
        """ Ask permission and confirmation before changing epa_type """

        if new_feature is not None:
            return True

        can_edit = tools_os.set_boolean(tools_db.check_role_user('role_epa'))
        if not can_edit:
            message = "You are not enabled to modify this {0} widget"
            msg_params = ("epa_type",)
            title = "Change epa_type"
            tools_qt.show_info_box(message, title, msg_params=msg_params)
            return False

        msg = ("You are going to change the epa_type. With this operation you will lose information about "
               "current epa_type values of this object. Would you like to continue?")
        title = "Change epa_type"
        if tools_qt.show_question(msg, title):
            return True

        widget_epatype = dialog.findChild(QComboBox, 'tab_data_epa_type')
        if widget_epatype:
            widget_epatype.blockSignals(True)
            tools_qt.set_combo_value(widget_epatype, self.epa_type, 1)
            widget_epatype.blockSignals(False)
        return False

    def _merge_epa_type_on_accept(self, dialog, my_json, new_feature=None):
        """ Include pending epa_type combo value when Accept is used """

        if 'epa_type' in my_json:
            return True

        widget = dialog.findChild(QComboBox, 'tab_data_epa_type')
        if widget is None:
            return True

        pending = {}
        tools_gw.get_values(dialog, widget, pending, ignore_editability=True)
        new_value = pending.get('epa_type')
        if new_value in (None, '') or str(new_value).lower() == str(self.epa_type or '').lower():
            return True

        if not self._confirm_epa_type_change(dialog, new_feature):
            return False

        my_json['epa_type'] = str(new_value)
        return True

    def _accept_auto_update(self, dialog, complet_result, _json, p_widget=None, clear_json=False, close_dlg=True, new_feature=None, generic=False):
        """
        :param dialog:
        :param complet_result:
        :param _json:
        :param p_widget:
        :param clear_json:
        :param close_dlg:
        :return: (boolean)
        """

        if _json.get('epa_type') and not self._confirm_epa_type_change(dialog, new_feature):
            return False

        # Call accept fct
        return self._accept(dialog, complet_result, _json, p_widget, clear_json, close_dlg, new_feature, generic)

    def _set_auto_update_textarea(self, field, dialog, widget, new_feature):

        if widget.property('isfilter'):
            return widget
        if widget.property('widgetcontrols') is not None and 'saveValue' in widget.property('widgetcontrols'):
            if widget.property('widgetcontrols')['saveValue'] is False:
                return widget

        if self._check_tab_data(field):  # Tab data
            # "and field['widgettype'] != 'typeahead'" It is necessary so that the textchanged signal of the typeahead
            # does not jump, making it lose focus, which will cause the accept function to jump sent invalid parameters
            if field['isautoupdate'] and self.new_feature_id is None and field['widgettype'] != 'typeahead':
                _json = {}
                widget.textChanged.connect(partial(self._clean_my_json, widget))
                widget.textChanged.connect(partial(tools_gw.get_values, dialog, widget, _json))
                widget.textChanged.connect(partial(self._accept_auto_update, dialog, self.complet_result, _json, widget, True, False, new_feature))
            else:
                widget.textChanged.connect(partial(tools_gw.get_values, dialog, widget, self.my_json))
        else:  # Other tabs
            widget.textChanged.connect(partial(tools_gw.get_values, dialog, widget, self.my_json_epa))
            # TODO: Make autoupdate widgets work
        widget.textChanged.connect(partial(self._enabled_accept, dialog))
        widget.textChanged.connect(partial(self._check_min_max_value, dialog, widget, dialog.btn_accept))
        widget.textChanged.connect(partial(self._check_datatype_validator, dialog, widget, dialog.btn_accept))

        return widget

    def _set_auto_update_hyperlink(self, field, dialog, widget, new_feature=None):

        if self._check_tab_data(field):
            widget.editingFinished.connect(partial(tools_gw.get_values, dialog, widget, self.my_json))

        return widget

    def _reload_fields(self, dialog, result, p_widget):
        """
        :param dialog: QDialog where find and set widgets
        :param result: row with info (json)
        :param p_widget: Widget that has changed
        """

        if not p_widget:
            return

        changed_color = "#3ED396"
        # Restore QLineEdit stylesheet
        widget_list = dialog.tab_data.findChildren(QLineEdit)
        for widget in widget_list:
            is_readonly = widget.isReadOnly()
            if is_readonly:
                widget.setStyleSheet("QLineEdit {background: rgb(244, 244, 244); color: rgb(100, 100, 100)}")
            else:
                widget.setStyleSheet(None)

        # Restore QPushButton stylesheet
        widget_list = dialog.tab_data.findChildren(QPushButton)
        for widget in widget_list:
            widget.setStyleSheet(None)

        # Restore widget stylesheet
        for field in result['body']['data']['fields']:
            widget = dialog.findChild(QLineEdit, f'{field["widgetname"]}')
            if widget is None:
                widget = dialog.findChild(QPushButton, f'{field["widgetname"]}')
            if widget:
                cur_value = tools_qt.get_text(dialog, widget, return_string_null=False)
                value = field["value"]
                if str(cur_value) != str(value):
                    widget.setText(value)
                    if not isinstance(widget, QPushButton):
                        widget.setStyleSheet(f"border: 2px solid {changed_color}")
                    else:
                        changed_color = "#EB9438"
                    if getattr(widget, 'isReadOnly', False):
                        widget.setStyleSheet(f"QLineEdit {{background: rgb(244, 244, 244); color: rgb(100, 100, 100); "
                                             f"border: 2px solid {changed_color}}}")

            elif "message" in field:
                level = field['message']['level'] if 'level' in field['message'] else 0
                level = Qgis.MessageLevel(level)
                tools_qgis.show_message(field['message']['text'], level)

    def _enabled_accept(self, dialog):
        dialog.btn_accept.setEnabled(True)

    def _reload_epa_tab(self, dialog):
        epa_type = tools_qt.get_text(dialog, 'tab_data_epa_type')
        # call getinfofromid
        if not epa_type or epa_type.lower() in ('undefined') or (epa_type.lower() == 'null' and self.feature_type.lower() != 'link'):
            tools_qt.enable_tab_by_tab_name(self.tab_main, 'tab_epa', False)
            return

        tablename = 've_epa_' + epa_type.lower()
        if global_vars.project_type == 'ws' and self.feature_type == 'connec' and epa_type.lower() == 'junction':
            tablename = 've_epa_connec'
        if self.feature_type.lower() == 'link':
            feature = f'"tableName":"ve_epa_link", "id":"{self.feature_id}", "epaType": "link"'
        else:
            feature = f'"tableName":"{tablename}", "id":"{self.feature_id}", "epaType": "{epa_type}"'
        body = tools_gw.create_body(feature=feature)
        function_name = 'gw_fct_getinfofromid'
        complet_result = tools_gw.execute_procedure(function_name, body)
        self.epa_complet_result = complet_result
        if complet_result:
            if complet_result['body']['form'].get('visibleTabs'):
                for tab in complet_result['body']['form']['visibleTabs']:
                    if tab['tabName'] == 'tab_epa':
                        self.visible_tabs[tab['tabName']] = tab
                self._show_actions(self.dlg_cf, self.tab_main.currentWidget().objectName())
            for lyt in dialog.findChildren(QGridLayout, QRegularExpression('lyt_epa')):
                i = 0
                while i < lyt.count():
                    item = lyt.itemAt(i)
                    widget = item.widget()
                    if widget:
                        widget.deleteLater()
                    else:  # for QSpacerItems
                        lyt.removeItem(item)
                    i += 1
            self._manage_dlg_widgets(complet_result, {}, False, reload_epa=True, tab='tab_epa')
            tools_qt.enable_tab_by_tab_name(self.tab_main, 'tab_epa', True)
            if self.action_edit.isChecked():
                tools_gw.enable_all(dialog, complet_result['body']['data'])
            else:
                tools_gw.enable_widgets(dialog, complet_result['body']['data'], False)
            self._reset_my_json_epa()
            dialog.show()

    def _set_auto_update_combobox(self, field, dialog, widget, new_feature):

        if widget.property('isfilter'):
            return widget
        if widget.property('widgetcontrols') is not None and 'saveValue' in widget.property('widgetcontrols'):
            if widget.property('widgetcontrols')['saveValue'] is False:
                return widget
        widget.currentIndexChanged.connect(partial(self._handle_combobox_change, widget, dialog, field))

        return widget

    def _set_auto_update_dateedit(self, field, dialog, widget, new_feature):

        if widget.property('isfilter'):
            return widget
        if widget.property('widgetcontrols') is not None and 'saveValue' in widget.property('widgetcontrols'):
            if widget.property('widgetcontrols')['saveValue'] is False:
                return widget

        if self._check_tab_data(field):  # Tab data
            if field['isautoupdate'] and self.new_feature_id is None:
                _json = {}
                widget.valueChanged.connect(partial(self._clean_my_json, widget))
                widget.valueChanged.connect(partial(tools_gw.get_values, dialog, widget, _json))
                widget.valueChanged.connect(partial(
                    self._accept, dialog, self.complet_result, _json, None, True, False, new_feature))
            else:
                widget.valueChanged.connect(partial(tools_gw.get_values, dialog, widget, self.my_json))
        else:  # Other tabs
            widget.valueChanged.connect(partial(tools_gw.get_values, dialog, widget, self.my_json_epa))
            # TODO: Make autoupdate widgets work

        return widget

    def _set_auto_update_spinbox(self, field, dialog, widget, new_feature):

        if widget.property('isfilter'):
            return widget
        if widget.property('widgetcontrols') is not None and 'saveValue' in widget.property('widgetcontrols'):
            if widget.property('widgetcontrols')['saveValue'] is False:
                return widget

        if self._check_tab_data(field):  # Tab data
            if field['isautoupdate'] and self.new_feature_id is None:
                _json = {}
                widget.valueChanged.connect(partial(self._clean_my_json, widget))
                widget.valueChanged.connect(partial(tools_gw.get_values, dialog, widget, _json))
                widget.valueChanged.connect(partial(
                    self._accept, dialog, self.complet_result, _json, None, True, False, new_feature))
            else:
                widget.valueChanged.connect(partial(tools_gw.get_values, dialog, widget, self.my_json))
        else:  # Other tabs
            widget.valueChanged.connect(partial(tools_gw.get_values, dialog, widget, self.my_json_epa))
            # TODO: Make autoupdate widgets work

        return widget

    def _set_auto_update_multiple_option(self, field, dialog, widget, new_feature):

        if widget.property('isfilter'):
            return widget
        if widget.property('widgetcontrols') is not None and 'saveValue' in widget.property('widgetcontrols'):
            if widget.property('widgetcontrols')['saveValue'] is False:
                return widget
        if self._check_tab_data(field):
            if field['isautoupdate'] and self.new_feature_id is None:
                _json = {}
                widget.findChild(QListWidget).model().rowsRemoved.connect(partial(self._clean_my_json, widget))
                widget.findChild(QListWidget).model().rowsInserted.connect(partial(self._clean_my_json, widget))

                widget.findChild(QListWidget).model().rowsRemoved.connect(partial(tools_gw.get_values, dialog, widget, _json))
                widget.findChild(QListWidget).model().rowsInserted.connect(partial(tools_gw.get_values, dialog, widget, _json))

                widget.findChild(QListWidget).model().rowsRemoved.connect(partial(self._accept, dialog, self.complet_result, _json, None, True, False, new_feature))
                widget.findChild(QListWidget).model().rowsInserted.connect(partial(self._accept, dialog, self.complet_result, _json, None, True, False, new_feature))
            else:
                widget.findChild(QListWidget).model().rowsRemoved.connect(partial(tools_gw.get_values, dialog, widget, self.my_json))
                widget.findChild(QListWidget).model().rowsInserted.connect(partial(tools_gw.get_values, dialog, widget, self.my_json))
        else:  # Other tabs
            widget.findChild(QListWidget).model().rowsRemoved.connect(partial(tools_gw.get_values, dialog, widget, self.my_json_epa))
            widget.findChild(QListWidget).model().rowsInserted.connect(partial(tools_gw.get_values, dialog, widget, self.my_json_epa))
        return widget

    def _set_auto_update_multiple_checkbox(self, field, dialog, widget, new_feature):

        if widget.property('isfilter'):
            return widget
        if widget.property('widgetcontrols') is not None and 'saveValue' in widget.property('widgetcontrols'):
            if widget.property('widgetcontrols')['saveValue'] is False:
                return widget
        if self._check_tab_data(field):
            if field['isautoupdate'] and self.new_feature_id is None:
                _json = {}
                widget.itemChanged.connect(partial(self._clean_my_json, widget))

                widget.itemChanged.connect(partial(tools_gw.get_values, dialog, widget, _json))

                widget.itemChanged.connect(partial(self._accept, dialog, self.complet_result, _json, None, True, False, new_feature))
            else:
                widget.itemChanged.connect(partial(tools_gw.get_values, dialog, widget, self.my_json))
        else:  # Other tabs
            widget.itemChanged.connect(partial(tools_gw.get_values, dialog, widget, self.my_json_epa))
        return widget

    def _set_auto_update_checkbox(self, field, dialog, widget, new_feature):

        if widget.property('isfilter'):
            return widget
        if widget.property('widgetcontrols') is not None and 'saveValue' in widget.property('widgetcontrols'):
            if widget.property('widgetcontrols')['saveValue'] is False:
                return widget

        if self._check_tab_data(field):  # Tab data
            if field['isautoupdate'] and self.new_feature_id is None:
                _json = {}
                widget.stateChanged.connect(partial(self._clean_my_json, widget))
                widget.stateChanged.connect(partial(tools_gw.get_values, dialog, widget, _json))
                widget.stateChanged.connect(partial(
                    self._accept, dialog, self.complet_result, _json, None, True, False, new_feature))
            else:
                widget.stateChanged.connect(partial(tools_gw.get_values, dialog, widget, self.my_json))
        else:  # Other tabs
            widget.stateChanged.connect(partial(tools_gw.get_values, dialog, widget, self.my_json_epa))
            # TODO: Make autoupdate widgets work
        return widget

    def _handle_combobox_change(self, widget, dialog, field):
        _json = {}
        if self._check_tab_data(field):  # Tab data
            if field['isautoupdate'] and self.new_feature_id is None:
                self._clean_my_json(widget)
                tools_gw.get_values(dialog, widget, _json)
                self._accept_auto_update(dialog, self.complet_result, _json, widget, True, False,
                                         new_feature=self.new_feature_id)
            else:
                tools_gw.get_values(dialog, widget, self.my_json)
        else:  # Other tabs
            tools_gw.get_values(dialog, widget, self.my_json_epa)
            # TODO: Make autoupdate widgets work for other tabs as well

    def run_settopology(self, widget, **kwargs):
        """ Sets node_1/2 from lineedit & converts widget into button if function run successfully """

        dialog = kwargs['dialog']
        field = kwargs['field']
        complet_result = kwargs['complet_result']
        feature_id = complet_result['body']['feature']['id']
        text = tools_qt.get_text(dialog, widget, return_string_null=True)

        feature = f'"id": "{feature_id}"'
        extras = f'"fields":{{"{widget.property("columnname")}":"{text}"}}'
        body = tools_gw.create_body(feature=feature, extras=extras)
        json_response = tools_gw.execute_procedure('gw_fct_settopology', body)
        if json_response and json_response['status'] != "Failed":
            # Refresh canvas & send a message
            tools_qgis.refresh_map_canvas()
            tools_qgis.show_info(tools_qt.tr("Node set correctly"), dialog=dialog)

            # Delete lineedit
            widget.deleteLater()
            # Create button with field from kwargs and value from {text}
            kwargs['field']['value'] = f"{text}"
            new_widget = tools_gw._manage_button(**kwargs)
            if new_widget is None:
                return
            # Add button to layout
            layout = self.dlg_cf.findChild(QGridLayout, field['layoutname'])
            if layout is not None:
                layout.addWidget(new_widget, int(field['layoutorder']), 2)
            return
        tools_qgis.show_warning(tools_qt.tr("Error setting node"), dialog=dialog)

    def _open_catalog(self, tab_type, feature_type, child_type):

        self.catalog = GwCatalog()
        widget = f'tab_{tab_type}_{self.feature_type}cat_id'
        self.catalog.open_catalog(self.dlg_cf, widget, feature_type, child_type)

    def _open_audit_manager(self):
        self.audit = GwAudit()
        self.audit.open_audit_manager(self.feature_id, self.tablename)

    def _show_actions(self, dialog, tab_name, enable_actions=True):
        """
        Hide all actions and show actions for the corresponding tab
            :param tab_name: corresponding tab
        """

        actions_list = dialog.findChildren(QAction)
        for action in actions_list:
            if not action.objectName() or action.objectName() == 'actionAudit':
                continue
            action.setVisible(False)

        if not self.visible_tabs:
            return

        for tab in self.visible_tabs:
            if self.visible_tabs[tab]['tabName'] == tab_name:
                if self.visible_tabs[tab]['tabactions'] is not None:
                    for act in self.visible_tabs[tab]['tabactions']:
                        action = dialog.findChild(QAction, act['actionName'])
                        if action is not None and act['actionName'] != "actionAudit":
                            if 'actionTooltip' in act:
                                action.setToolTip(tools_qt.tr(act['actionTooltip']))
                            action.setVisible(True)

        if enable_actions:
            self._enable_actions(dialog, self.action_edit.isChecked())

    """ MANAGE TABS """

    def _tab_activation(self, dialog):
        """ Call functions depend on tab selection """

        # Get index of selected tab
        index_tab = self.tab_main.currentIndex()
        tab_name = self.tab_main.widget(index_tab).objectName()
        self._show_actions(dialog, tab_name)

        # Tab 'Elements'
        if self.tab_main.widget(index_tab).objectName() == 'tab_elements' and not self.tab_element_loaded:
            # Save grb_frelem_dscenario state
            # FIXME: the intended behavior is to have it be collapsed the first time, but then save the state
            grb_dscenario = self.dlg_cf.findChild(QgsCollapsibleGroupBox, 'grb_frelem_dscenario')
            if grb_dscenario is not None:
                grb_dscenario_state = grb_dscenario.isCollapsed()
                grb_dscenario.setCollapsed(False)
            # Populate widgets
            self._manage_dlg_widgets(self.complet_result, self.complet_result['body']['data'], False, tab='tab_elements')
            self._manage_dscenario_elements_tabs()
            # Init tab
            filter_fields = f'"{self.field_id}":{{"value":"{self.feature_id}","filterSign":"="}}'
            self._init_tab(self.complet_result, filter_fields)
            # Restore grb_frelem_dscenario state
            if grb_dscenario is not None:
                grb_dscenario.setCollapsed(grb_dscenario_state)
            self.tab_element_loaded = True
        # Tab 'EPA'
        elif self.tab_main.widget(index_tab).objectName() == 'tab_epa' and not self.tab_epa_loaded:
            self._reload_epa_tab(dialog)
            filter_fields = f'"{self.field_id}":{{"value":"{self.feature_id}","filterSign":"="}}'
            self._init_tab(self.complet_result, filter_fields)
            self.tab_epa_loaded = True
        # Tab 'Relations'
        elif self.tab_main.widget(index_tab).objectName() == 'tab_relations' and not self.tab_relations_loaded:
            self._manage_dlg_widgets(self.complet_result, self.complet_result['body']['data'], False, tab='tab_relations')
            filter_fields = f'"{self.field_id}":{{"value":"{self.feature_id}","filterSign":"="}}'
            self._init_tab(self.complet_result, filter_fields)
            self.tab_relations_loaded = True
        # Tab 'Features'
        elif self.tab_main.widget(index_tab).objectName() == 'tab_features' and not self.tab_features_loaded:
            self._manage_dlg_widgets(self.complet_result, self.complet_result['body']['data'], False, tab='tab_features')
            filter_fields = f'"{self.field_id}":{{"value":"{self.feature_id}","filterSign":"="}}'
            self._init_tab(self.complet_result, filter_fields)
            tab_feature = dialog.tab_main.findChild(QTabWidget, 'tab_feature')
            tab_feature.currentChanged.connect(partial(tools_gw.get_signal_change_tab, dialog, self.excluded_layers, 'tab_features_feature_id', 've_'))
            if global_vars.project_type == 'ws':
                tools_qt.remove_tab(tab_feature, 'tab_gully')
            tools_gw.get_signal_change_tab(dialog, self.excluded_layers, 'tab_features_feature_id')
            self.tab_features_loaded = True
        # Tab 'Connections'
        elif self.tab_main.widget(index_tab).objectName() == 'tab_connections' and not self.tab_connections_loaded:
            self._manage_dlg_widgets(self.complet_result, self.complet_result['body']['data'], False, tab='tab_connections')
            filter_fields = f'"{self.field_id}":{{"value":"{self.feature_id}","filterSign":"="}}'
            self._init_tab(self.complet_result, filter_fields)
            self.tab_connections_loaded = True
        # Tab 'Hydrometer'
        elif self.tab_main.widget(index_tab).objectName() == 'tab_hydrometer' and not self.tab_hydrometer_loaded:
            self._manage_dlg_widgets(self.complet_result, self.complet_result['body']['data'], False, tab='tab_hydrometer')
            filter_fields = f'"feature_id":{{"value":"{self.feature_id}","filterSign":"="}}'
            self._init_tab(self.complet_result, filter_fields, id_name="feature_id")
            self.tab_hydrometer_loaded = True
        # Tab 'Hydrometer values'
        elif self.tab_main.widget(index_tab).objectName() == 'tab_hydrometer_val' and not self.tab_hydrometer_val_loaded:
            self._manage_dlg_widgets(self.complet_result, self.complet_result['body']['data'], False, tab='tab_hydrometer_val')
            filter_fields = f'"feature_id":{{"value":"{self.feature_id}","filterSign":"="}}'
            self._init_tab(self.complet_result, filter_fields, id_name="feature_id")
            self.tab_hydrometer_val_loaded = True
        # Tab 'Visit'
        elif self.tab_main.widget(index_tab).objectName() == 'tab_visit' and not self.tab_visit_loaded:
            self._manage_dlg_widgets(self.complet_result, self.complet_result['body']['data'], False, tab='tab_visit')
            filter_fields = f'"{self.field_id}":{{"value":"{self.feature_id}","filterSign":"="}}'
            self._init_tab(self.complet_result, filter_fields)
            cmb_visit_class = self.dlg_cf.findChild(QComboBox, 'tab_visit_visit_class')
            sql = (f"select distinct(class_id) from v_ui_om_visit_x_{self.feature_type} where {self.field_id} = '{self.feature_id}' ")
            rows = tools_db.get_rows(sql)
            if rows is None:
                rows = []
            rows_int = [set(int(x) for x in row if x is not None) for row in rows]
            if cmb_visit_class is not None:
                index_to_remove = []
                for i in range(cmb_visit_class.count() - 1, -1, -1):
                    item_data = cmb_visit_class.itemData(i)
                    if not item_data or item_data[0] in ('', None):
                        continue
                    visit_class_id = int(item_data[0])
                    if not any(visit_class_id in row for row in rows_int):
                        index_to_remove.append(i)
                for i in index_to_remove:
                    cmb_visit_class.removeItem(i)

                current_index = cmb_visit_class.currentIndex()
                cmb_visit_class.currentIndexChanged.emit(current_index)

            # Manage btn_open_gallery
            btn_open_gallery = self.dlg_cf.findChild(QPushButton, 'tab_visit_open_gallery')
            tbl_visits = self.dlg_cf.findChild(QTableView, 'tab_visit_tbl_visits')
            if tbl_visits is None:
                tables = self.tab_main.widget(index_tab).findChildren(QTableView)
                tbl_visits = tables[0] if tables else None

            if btn_open_gallery is not None and tbl_visits is not None and tbl_visits.selectionModel() is not None:
                btn_open_gallery.setEnabled(False)
                tbl_visits.selectionModel().selectionChanged.connect(
                    partial(self._manage_gallery_status, tbl_visits, btn_open_gallery))

            self.tab_visit_loaded = True
        # Tab 'Event'
        elif self.tab_main.widget(index_tab).objectName() == 'tab_event':
            if not self.tab_event_loaded:
                self._manage_dlg_widgets(self.complet_result, self.complet_result['body']['data'], False, tab='tab_event')
                filter_fields = f'"{self.field_id}":{{"value":"{self.feature_id}","filterSign":"="}}'
                self._init_tab(self.complet_result, filter_fields)
                self.tab_event_loaded = True
            else:
                for widget in self.dlg_cf.findChildren(QWidget):
                    if isinstance(widget, tools_gw.CustomQgsDateTimeEdit):
                        self.force_enable_clear_button(widget)
        # Tab 'Documents'
        elif self.tab_main.widget(index_tab).objectName() == 'tab_documents':
            if not self.tab_document_loaded:
                self._manage_dlg_widgets(self.complet_result, self.complet_result['body']['data'], False, tab='tab_documents')
                filter_fields = f'"{self.field_id}":{{"value":"{self.feature_id}","filterSign":"="}}'
                self._init_tab(self.complet_result, filter_fields)
                self.tab_document_loaded = True
            else:
                for widget in self.dlg_cf.findChildren(QWidget):
                    if isinstance(widget, tools_gw.CustomQgsDateTimeEdit):
                        self.force_enable_clear_button(widget)
        # Tab 'Plan'
        elif self.tab_main.widget(index_tab).objectName() == 'tab_plan' and not self.tab_plan_loaded:
            self._fill_tab_plan(self.complet_result)
            self.tab_plan_loaded = True

    def _manage_dscenario_elements_tabs(self):
        """ Manage dscenario elements tabs """

        if global_vars.project_type == 'ud':
            # Disable dscenario tabs
            tab_widget = self.dlg_cf.findChild(QTabWidget, 'tab_frelem_dscenario')
            tab_widget.setTabVisible(4, False)
            tab_widget.setTabEnabled(4, False)
            tab_widget.setTabVisible(5, False)
            tab_widget.setTabEnabled(5, False)
        elif global_vars.project_type == 'ws':
            # Disable dscenario tabs
            tab_widget = self.dlg_cf.findChild(QTabWidget, 'tab_frelem_dscenario')
            for i in [0, 1, 3]:
                tab_widget.setTabVisible(i, False)
                tab_widget.setTabEnabled(i, False)

        # Create double click event for dscenario tables
        tableviews = self.dlg_cf.findChildren(QTableView, QRegularExpression('tbl_frelem_dsc_'))
        for tableview in tableviews:
            tableview.doubleClicked.connect(partial(self._open_dscenario_element, self.dlg_cf, tableview))

    def _open_dscenario_element(self, dlg_cf, tableview):
        """ Open dscenario element """
        # Create double click event for dscenario tables
        dscenario_manager_btn = GwDscenarioManagerButton('', None, None, None, None)
        # Get first column value from the selected row
        selected_list = tableview.selectionModel().selectedRows()
        if len(selected_list) == 0:
            msg = "Any record selected"
            tools_qgis.show_warning(msg, dialog=dlg_cf)
            return
        index = selected_list[0]
        row = index.row()
        col_idx = tools_qt.get_col_index_by_col_name(tableview, 'dscenario_id')
        dscenario_id_value = index.sibling(row, col_idx).data()
        dscenario_manager_btn.selected_dscenario_id = int(dscenario_id_value)
        dscenario_manager_btn.manage_update(
            dlg_cf,
            tableview,
            on_close=partial(_reload_table, dialog=dlg_cf, complet_result=self.complet_result)
        )

    def force_enable_clear_button(self, widget):
        # Always ensure nulls are allowed
        if hasattr(widget, "setAllowNull"):
            widget.setAllowNull(True)

        if widget.dateTime() == QDateTime():
            widget.displayNull(True)
        else:
            widget.displayNull(False)

        # Force clear button to be active
        for btn in widget.findChildren(QToolButton):
            btn.setEnabled(True)
            btn.raise_()
            try:
                btn.clicked.disconnect()
            except Exception:
                pass
            btn.clicked.connect(widget.clear)

        if hasattr(widget, "valueChanged"):
            try:
                widget.valueChanged.disconnect()
            except Exception:
                pass
            widget.valueChanged.connect(partial(self.force_enable_clear_button, widget))

    def _manage_gallery_status(self, tbl_visits, btn_open_gallery):

        selected_indexes = tbl_visits.selectionModel().selectedRows()

        if selected_indexes:
            row = selected_indexes[0].row()
            column_photo = tbl_visits.model().columnCount() - 1
            index = tbl_visits.model().index(row, column_photo)
            value = tbl_visits.model().data(index, Qt.ItemDataRole.DisplayRole)
            btn_open_gallery.setEnabled(value in [True, "True", 1, "1"])
        else:
            btn_open_gallery.setEnabled(False)

    def _init_tab(self, complet_result, filter_fields='', id_name=None):

        index_tab = self.tab_main.currentIndex()
        list_tables = self.tab_main.widget(index_tab).findChildren(QTableView)
        complet_list = []
        for table in list_tables:
            widgetname = table.objectName()
            columnname = table.property('columnname')
            if columnname is None:
                msg = f"widget {widgetname} in tab {self.tab_main.widget(index_tab).objectName()} has not columnname and cant be configured"
                tools_qgis.show_info(msg, 3)
                continue
            linkedobject = table.property('linkedobject')
            if linkedobject is None:
                return
            complet_list, widget_list = self._fill_tbl(complet_result, self.dlg_cf, widgetname, linkedobject, filter_fields, id_name)
            if complet_list is False:
                return False
            tools_gw.set_filter_listeners(complet_result, self.dlg_cf, widget_list, columnname, widgetname, self.feature_id)

    def _fill_tbl(self, complet_result, dialog, widgetname, linkedobject, filter_fields, id_name=None):
        """ Put filter widgets into layout and set headers into QTableView """

        index_tab = self.tab_main.currentIndex()
        tab_name = self.tab_main.widget(index_tab).objectName().replace('tab_', "")
        complet_list = self._get_list(complet_result, '', tab_name, filter_fields, widgetname, 'form_feature', linkedobject, id_name)

        if complet_list is False:
            return False, False

        # Get headers from complet_list
        headers = complet_list['body']['form']['headers']

        data = complet_list['body']['data']
        fields = data['fields']
        if 'hidden' in data and data['hidden']:
            return False, False

        widget = self.dlg_cf.findChild(QTableView, widgetname)
        if widget is None:
            return False, False
        widget = tools_gw.add_tableview_header(widget, fields, headers)
        widget = tools_gw.fill_tableview_rows(widget, fields)
        tools_qt.set_tableview_config(widget, edit_triggers=QTableView.EditTrigger.DoubleClicked, section_resize_mode=QHeaderView.ResizeMode.Interactive)
        widget: QWidget = tools_gw.set_tablemodel_config(dialog, widget, linkedobject, Qt.SortOrder.DescendingOrder)
        if 'tab_epa' in widgetname:
            widget.doubleClicked.connect(partial(epa_tbl_doubleClicked, widget, self.dlg_cf))
            model = widget.model()
            tbl_upsert = widget.property('widgetcontrols').get('tableUpsert')
            setattr(self, f"my_json_{tbl_upsert}", {})

            # get view addparam
            addparam = None
            sql = f"SELECT addparam FROM sys_table WHERE id = '{tbl_upsert}'"
            row = tools_db.get_row(sql)
            if row:
                addparam = row[0]
                if addparam:
                    addparam = addparam.get('pkey')
            model.dataChanged.connect(partial(tbl_data_changed, self, tbl_upsert, widget, model, addparam))
            dialog.btn_accept.clicked.connect(partial(save_tbl_changes, tbl_upsert, self, dialog, addparam))

        # Populate custom context menu
        widget.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        widget.customContextMenuRequested.connect(partial(tools_gw._show_context_menu, widget, self.tab_main.widget(index_tab)))

        widget_list = []
        widget_list.extend(self.tab_main.widget(index_tab).findChildren(QComboBox, QRegularExpression(f"{tab_name}_")))
        widget_list.extend(self.tab_main.widget(index_tab).findChildren(QTableView, QRegularExpression(f"{tab_name}_")))
        widget_list.extend(self.tab_main.widget(index_tab).findChildren(QLineEdit, QRegularExpression(f"{tab_name}_")))
        widget_list.extend(self.tab_main.widget(index_tab).findChildren(QgsDateTimeEdit, QRegularExpression(f"{tab_name}_")))
        return complet_list, widget_list

    def _set_filter_listeners(self, complet_result, dialog, widget_list, columnname, widgetname):
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
            widgetfunction = False
            func_params = None
            if widget.property('widgetfunction') is not None and 'functionName' in widget.property('widgetfunction'):
                widgetfunction = widget.property('widgetfunction')['functionName']
                func_params = widget.property('widgetfunction').get('parameters')
            if widgetfunction is False:
                continue

            field_id = None
            if func_params is not None:
                field_id = func_params.get('field_id')

            linkedobject = ""
            if widget.property('linkedobject') is not None:
                linkedobject = widget.property('linkedobject')

            kwargs = {"complet_result": complet_result, "model": model, "dialog": dialog, "linkedobject": linkedobject,
                      "columnname": columnname, "widget": widget, "widgetname": widgetname, "widget_list": widget_list,
                      "feature_id": self.feature_id, "func_params": func_params, "field_id": field_id}
            if type(widget) is QLineEdit:
                widget.textChanged.connect(partial(getattr(tools_backend_calls, widgetfunction), **kwargs))
            elif isinstance(widget, QComboBox):
                widget.currentIndexChanged.connect(partial(getattr(tools_backend_calls, widgetfunction), **kwargs))
            elif isinstance(widget, QgsDateTimeEdit):
                widget.dateChanged.connect(partial(getattr(tools_backend_calls, widgetfunction), **kwargs))
                widget.setDate(QDate.currentDate())

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

    def _get_list(self, complet_result, form_name='', tab_name='', filter_fields='', widgetname='', formtype='', linkedobject='', id_name=None):

        if id_name is None:
            id_name = complet_result['body']['feature']['idName']

        if filter_fields:
            filter_fields = f'"{id_name}":{{"value":"{self.feature_id}","filterSign":"="}}, {filter_fields}'
        else:
            filter_fields = f'"{id_name}":{{"value":"{self.feature_id}","filterSign":"="}}'
        extras = f'"tableName":"{linkedobject}"'
        body = tools_gw.create_body(filter_fields=filter_fields, extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_getlist', body)
        if json_result is None or json_result['status'] == 'Failed':
            return False
        complet_list = json_result
        if not complet_list:
            return False

        return complet_list

    """ FUNCTIONS RELATED WITH TAB PLAN """

    def _fill_tab_plan(self, complet_result):

        plan_layout = self.dlg_cf.findChild(QGridLayout, 'lyt_plan_1')

        if self.feature_type == 'arc' or self.feature_type == 'node':
            index_tab = self.tab_main.currentIndex()
            tab_name = self.tab_main.widget(index_tab).objectName()
            form = f'"tabName":"{tab_name}"'
            feature = f'"featureType":"{complet_result["body"]["feature"]["featureType"]}", '
            feature += f'"tableName":"{self.tablename}", '
            feature += f'"idName":"{self.field_id}", '
            feature += f'"id":"{self.feature_id}"'
            body = tools_gw.create_body(form, feature, filter_fields='')
            json_result = tools_gw.execute_procedure('gw_fct_getinfoplan', body)
            if not json_result or json_result['status'] == 'Failed':
                return False

            result = json_result['body']['data']
            if 'fields' not in result:
                msg = "No listValues for"
                tools_qgis.show_message(msg, Qgis.MessageLevel.Critical, parameter=json_result['body']['data'])
            else:
                for field in json_result['body']['data']['fields']:
                    label = QLabel()
                    if field['widgettype'] == 'divider':
                        for x in range(0, 2):
                            line = tools_gw.add_frame(field, x)
                            plan_layout.addWidget(line, field['layoutorder'], x)
                    else:
                        label = QLabel()
                        label.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)
                        label.setObjectName('lbl_' + field['label'])
                        label.setText(field['label'].capitalize())
                        if 'tooltip' in field:
                            label.setToolTip(field['tooltip'])
                        else:
                            label.setToolTip(field['label'].capitalize())

                    if field['widgettype'] == 'label':
                        widget = self._add_label(field)
                        widget.setAlignment(Qt.AlignmentFlag.AlignRight)
                        label.setWordWrap(True)
                        plan_layout.addWidget(label, field['layoutorder'], 0)
                        plan_layout.addWidget(widget, field['layoutorder'], 1)

                plan_vertical_spacer = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
                plan_layout.addItem(plan_vertical_spacer)

    def _add_label(self, field):
        """ Add widgets QLineEdit type """

        widget = QLabel()
        widget.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)
        widget.setObjectName(field['widgetname'])
        if 'columnname' in field:
            widget.setProperty('columnname', field['columnname'])
        if 'value' in field:
            widget.setText(field['value'])

        return widget

    def _get_catalog(self, form_name, table_name, feature_type, feature_id, list_points, id_name):

        form = f'"formName":"{form_name}", "tabName":"data", "editable":"TRUE"'
        feature = f'"tableName":"{table_name}", "featureId":"{feature_id}", "feature_type":"{feature_type}"'
        extras = f'"coordinates":{{{list_points}}}'
        body = tools_gw.create_body(form, feature, extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_getcatalog', body)
        if json_result is None:
            return

        dlg_generic = GwInfoGenericUi(self)
        tools_gw.load_settings(dlg_generic)

        # Set signals
        dlg_generic.btn_close.clicked.connect(partial(tools_gw.close_dialog, dlg_generic))
        dlg_generic.dlg_closed.connect(partial(tools_gw.close_dialog, dlg_generic))
        dlg_generic.btn_accept.clicked.connect(partial(self._set_catalog, dlg_generic, form_name, table_name, feature_id, id_name))

        tools_gw.build_dialog_info(dlg_generic, json_result, my_json=None, tab_name="tab_none",
                                    enable_actions=True, is_inserting=False)
        # Open dialog
        dlg_generic.setWindowTitle(f"{(form_name.lower()).capitalize().replace('_', ' ')}")
        tools_gw.open_dialog(dlg_generic, dlg_name='info_generic')

    def _set_catalog(self, dialog, form_name, table_name, feature_id, id_name):
        """ Insert table 'cat_work'. Add cat_work """

        # Manage mandatory fields
        missing_mandatory = False
        widgets = dialog.findChildren(QWidget)
        for widget in widgets:
            widget.setStyleSheet(None)
            # Check mandatory fields
            value = tools_qt.get_text(dialog, widget, False, False)
            if widget.property('ismandatory') and value in (None, ''):
                missing_mandatory = True
                tools_qt.set_stylesheet(widget, "border: 2px solid red")
        if missing_mandatory:
            message = "Mandatory field is missing. Please, set a value"
            tools_qgis.show_warning(message)
            return

        # Form handling so that the user cannot change values until the process is finished
        self.dlg_cf.setEnabled(False)

        # Get widgets values
        values = {}
        for widget in widgets:
            if widget.property('columnname') in (None, ''):
                continue
            values = tools_gw.get_values(dialog, widget, values, ignore_editability=True)
        fields = json.dumps(values)

        # Call gw_fct_setcatalog
        fields = f'"fields":{fields}'
        form = f'"formName":"{form_name}"'
        feature = f'"tableName":"{table_name}", "id":"{feature_id}", "idName":"{id_name}"'
        body = tools_gw.create_body(form, feature, extras=fields)
        result = tools_gw.execute_procedure('gw_fct_setcatalog', body)
        if result['status'] != 'Accepted':
            return

        # Set new value to the corresponding widget
        for field in result['body']['data']['fields']:
            widget = self.dlg_cf.findChild(QWidget, field['widgetname'])
            if widget.property('typeahead'):
                tools_qt.set_completer_object(QCompleter(), QStandardItemModel(), widget, field['comboIds'])
                tools_qt.set_widget_text(self.dlg_cf, widget, field['selectedId'])
                self.my_json[str(widget.property('columnname'))] = field['selectedId']
            elif isinstance(widget, QComboBox):
                widget = tools_gw.fill_combo(widget, field)
                widget.setProperty('selectedId', field['selectedId'])
                self.my_json[str(widget.property('columnname'))] = field['selectedId']

        self._enable_buttons()
        tools_gw.close_dialog(dialog)

    def _enable_buttons(self):
        self.dlg_cf.setEnabled(True)

    def _mouse_moved(self, layer, point):
        """ Mouse motion detection """

        # Set active layer
        self.iface.setActiveLayer(layer)
        layer_name = tools_qgis.get_layer_source_table_name(layer)

        # Get clicked point
        self.vertex_marker.hide()
        event_point = self.snapper_manager.get_event_point(point=point)

        # Snapping
        result = self.snapper_manager.snap_to_current_layer(event_point)
        if result.isValid():
            layer = self.snapper_manager.get_snapped_layer(result)
            # Check feature
            viewname = tools_qgis.get_layer_source_table_name(layer)
            if viewname == layer_name:
                self.snapper_manager.add_marker(result, self.vertex_marker)

    def _get_id(self, dialog, action, option, emit_point, child_type, widget_name, point, event):
        """ Get selected attribute from snapped feature """

        # @options{'key':['att to get from snapped feature', 'widget name destination']}
        options = {
                    'arc': ['arc_id', 'tab_data_arc_id'],
                    'node': ['node_id', 'tab_data_parent_id'],
                    'set_to_arc': ['arc_id', '_set_to_arc'],
                    'set_to_arc_simple': ['arc_id', '_set_to_arc']
                   }

        if event == Qt.MouseButton.RightButton:
            self._cancel_snapping_tool(dialog, action)
            return

        try:
            # Refresh all layers to avoid selecting old deleted features
            global_vars.canvas.refreshAllLayers()
            # Get coordinates
            event_point = self.snapper_manager.get_event_point(point=point)
            # Snapping
            result = self.snapper_manager.snap_to_current_layer(event_point)
            if not result.isValid():
                return
            # Get the point. Leave selection
            snapped_feat = self.snapper_manager.get_snapped_feature(result)
            feat_id = snapped_feat.attribute(f'{options[option][0]}')
            if option in ('arc', 'node'):
                widget = dialog.findChild(QWidget, f"{options[option][1]}")
                widget.setFocus()
                tools_qt.set_widget_text(dialog, widget, str(feat_id))
                if str(feat_id) not in ('', None, -1, "None") and widget.property('columnname'):
                        self.my_json[str(widget.property('columnname'))] = str(feat_id)
            elif option == 'set_to_arc':
                # functions called in -> getattr(self, options[option][0])(feat_id, child_type)
                #       def _set_to_arc(self, dialog, feat_id, child_type, widget_name, simple=False)
                getattr(self, options[option][1])(dialog, feat_id, child_type, widget_name)
            elif option == 'set_to_arc_simple':
                # functions called in -> getattr(self, options[option][0])(feat_id, child_type)
                #       def _set_to_arc(self, dialog, feat_id, child_type, widget_name, simple=False)
                getattr(self, options[option][1])(dialog, feat_id, child_type, widget_name, simple=True)
        except Exception as e:
            tools_qgis.show_warning(tools_qt.tr("Exception in info (def _get_id)"), parameter=e)
        finally:
            self._cancel_snapping_tool(dialog, action)

    def _set_to_arc(self, dialog, feat_id, child_type, widget_name, simple=False):
        """
        Function called in def get_id(self, dialog, action, option, point, event):
            getattr(self, options[option][1])(feat_id, child_type)

            :param feat_id: Id of the snapped feature
            :param child_type: Feature type context.
            :param simple: If True, only updates the label without backend calls.
        """
        if not simple:

            # Standard mode: Perform backend call and update the dialog
            w_dma_id = self.dlg_cf.findChild(QWidget, 'tab_data_dma_id')
            if isinstance(w_dma_id, QComboBox):
                dma_id = tools_qt.get_combo_value(self.dlg_cf, w_dma_id)
            else:
                dma_id = tools_qt.get_text(self.dlg_cf, w_dma_id)

            w_presszone_id = self.dlg_cf.findChild(QComboBox, 'tab_data_presszone_id')
            presszone_id = tools_qt.get_combo_value(self.dlg_cf, w_presszone_id)
            w_sector_id = self.dlg_cf.findChild(QComboBox, 'tab_data_sector_id')
            sector_id = tools_qt.get_combo_value(self.dlg_cf, w_sector_id)
            w_dqa_id = self.dlg_cf.findChild(QComboBox, 'tab_data_dqa_id')
            dqa_id = tools_qt.get_combo_value(self.dlg_cf, w_dqa_id)
            if dqa_id == -1:
                dqa_id = "null"

            feature = f'"featureType":"{child_type}", "id":"{self.feature_id}"'
            extras = (f'"arcId":"{feat_id}", "dmaId":"{dma_id}", "presszoneId":"{presszone_id}", "sectorId":"{sector_id}", '
                      f'"dqaId":"{dqa_id}"')
            body = tools_gw.create_body(feature=feature, extras=extras)
            json_result = tools_gw.execute_procedure('gw_fct_settoarc', body)
            if json_result is None:
                return

            if 'status' not in json_result or json_result['status'] != 'Accepted':
                return
            if json_result['message']:
                level = 1
                if 'level' in json_result['message']:
                    level = int(json_result['message']['level'])
                    msg = json_result['message']['text']
                tools_qgis.show_message(msg, level)

            # Refresh tab epa
            epa_type = tools_qt.get_text(self.dlg_cf, 'tab_data_epa_type')
            if epa_type and epa_type.lower() in ('valve', 'shortpipe', 'pump'):
                self._reload_epa_tab(self.dlg_cf)

        # Refresh to_arc and emit editingFinished signal
        widget = dialog.findChild(QWidget, widget_name)
        if widget:
            tools_qt.set_widget_text(dialog, widget, str(feat_id))
            if hasattr(widget, "editingFinished"):
                widget.setReadOnly(False)
                widget.editingFinished.emit()  # Emit signal to indicate value has changed
        else:
            tools_qgis.show_warning(f"Widget '{widget_name}' not found in the dialog.")

    def _cancel_snapping_tool(self, dialog, action):

        tools_qgis.disconnect_snapping(False, None, self.vertex_marker)
        tools_gw.disconnect_signal('info_snapping')
        dialog.blockSignals(False)
        action.setChecked(False)
        self.signal_activate.emit()

    """ FUNCTIONS ASSOCIATED TO BUTTONS FROM POSTGRES"""

    def _action_is_checked(self):
        """ Recover snapping options when action add feature is un-checked """

        if not self.iface.actionAddFeature().isChecked():
            tools_gw.disconnect_signal('info', 'add_feature_actionAddFeature_toggled_action_is_checked')

    def _open_new_feature(self, feature_id, connect_signal=None, linked_feature=None):
        """
        :param feature_id: Parameter sent by the featureAdded method itself
        :return:
        """

        tools_gw.disconnect_signal('info', 'add_feature_featureAdded_open_new_feature')
        feature = tools_qt.get_feature_by_id(self.info_layer, feature_id)
        if (linked_feature and linked_feature.get('geometry')):
            geom = QgsGeometry.fromWkt(linked_feature.get('geometry', {}).get("st_astext"))
            if geom:
                feature.setGeometry(geom)
        geom = feature.geometry()
        list_points = None
        try:
            if self.info_layer.geometryType() == 0:
                points = geom.asPoint()
                list_points = f'"x1":{points.x()}, "y1":{points.y()}'
            elif self.info_layer.geometryType() in (1, 2):
                points = geom.asPolyline()
                init_point = points[0]
                last_point = points[-1]
                list_points = f'"x1":{init_point.x()}, "y1":{init_point.y()}'
                list_points += f', "x2":{last_point.x()}, "y2":{last_point.y()}'
            else:
                msg = "NO FEATURE TYPE DEFINED"
                tools_log.log_info(msg)
        except Exception:
            pass

        tools_gw.init_docker()
        global is_inserting  # noqa: F824
        is_inserting = True

        self.info_feature = GwInfo('data')
        self.info_feature.prev_action = self.prev_action
        result, dialog = self.info_feature._get_feature_insert(point=list_points, feature_cat=self.feature_cat,
                                                               new_feature_id=feature_id, new_feature=feature,
                                                               layer_new_feature=self.info_layer, tab_type='data',
                                                               connect_signal=connect_signal, linked_feature=linked_feature)

        # Restore user value (Settings/Options/Digitizing/Suppress attribute from pop-up after feature creation)
        config = self.info_layer.editFormConfig()
        config.setSuppress(self.conf_supp)
        self.info_layer.setEditFormConfig(config)
        if not result:
            self.info_layer.deleteFeature(feature.id())
            self.iface.actionRollbackEdits().trigger()
            is_inserting = False

    def _get_combo_child(self, dialog, widget, feature_type, tablename, field_id):
        """
        Find QComboBox child and populate it
            :param dialog: QDialog
            :param widget: QComboBox parent
            :param feature_type: PIPE, ARC, JUNCTION, VALVE...
            :param tablename: view of DB
            :param field_id: Field id of tablename
            :return: False if failed
        """

        combo_parent = widget.property('columnname')
        combo_id = tools_qt.get_combo_value(dialog, widget)

        feature = f'"featureType":"{feature_type}", '
        feature += f'"tableName":"{tablename}", '
        feature += f'"idName":"{field_id}"'
        extras = f'"comboParent":"{combo_parent}", "comboId":"{combo_id}"'
        body = tools_gw.create_body(feature=feature, extras=extras)
        result = tools_gw.execute_procedure('gw_fct_getchilds', body)
        if not result or result['status'] == 'Failed':
            return False

        for combo_child in result['body']['data']:
            if combo_child is not None:
                tools_gw.manage_combo_child(dialog, widget, combo_child)

    def _get_point_xy(self):
        """ Capture point XY from the canvas """
        self.snapper_manager.add_point(self.vertex_marker)
        self.point_xy = self.snapper_manager.point_xy

    def _update_geom(self, table_id, id_name, newfeature_id):
        """ Update geometry field """

        srid = lib_vars.data_epsg
        sql = (f"UPDATE {table_id}"
               f" SET the_geom = ST_SetSRID(ST_MakePoint({self.point_xy['x']},{self.point_xy['y']}), {srid})"
               f" WHERE {id_name} = {newfeature_id}")
        tools_db.execute_sql(sql)

    # endregion
# region Static functions used by the widgets in the custom form


def get_list(table_name, id_name=None, filter=None):
    """ Mount and execute the query for gw_fct_getlist """

    filter_fields = '"limit": -1'
    if id_name and filter:
        filter_fields += f', "{id_name}": {{"filterSign":"=", "value":"{filter}"}}'
    extras = f'"tableName":"{table_name}"'
    body = tools_gw.create_body(filter_fields=filter_fields, extras=extras)    
    json_result = tools_gw.execute_procedure('gw_fct_getlist', body)
    if json_result is None or json_result['status'] == 'Failed':
        return False
    complet_list = json_result
    if not complet_list:
        return False

    return complet_list


def fill_tbl(complet_list, tbl, info, view, dlg):
    if complet_list is False:
        return False, False

    # get view addparam
    addparam = None
    sql = f"SELECT addparam FROM sys_table WHERE id = '{view}'"
    row = tools_db.get_row(sql)
    if row:
        addparam = row[0]
        if addparam:
            addparam = addparam.get('pkey')

    setattr(info, f"my_json_{view}", {})
    # headers
    headers = complet_list['body']['form'].get('headers')
    non_editable_columns = []
    if headers:
        model = tbl.model()
        if model is None:
            model = QStandardItemModel()

        # Related by Qtable
        model.clear()
        tbl.setModel(model)
        tbl.horizontalHeader().setStretchLastSection(True)
        # Non-editable columns
        non_editable_columns = [item['header'] for item in headers if item.get('editable') is False]

    # values
    data = complet_list['body']['data']
    headers = complet_list['body']['form'].get('headers')
    fields = data['fields']
    if data.get('hidden'):
        return False
    model = tbl.model()
    if model is None:
        model = QStandardItemModel()
        tbl.setModel(model)
    model.removeRows(0, model.rowCount())

    if fields:
        tbl = tools_gw.add_tableview_header(tbl, fields, headers)
        tbl = tools_gw.fill_tableview_rows(tbl, fields)
    tools_qt.set_tableview_config(tbl)
    model.dataChanged.connect(partial(tbl_data_changed, info, view, tbl, model, addparam))

    try:
        tbl.doubleClicked.disconnect()
    except Exception:
        pass
    tbl.doubleClicked.connect(partial(epa_tbl_doubleClicked, tbl, dlg))
    # editability
    tbl.model().flags = lambda index: epa_tbl_flags(index, model, non_editable_columns)


def epa_tbl_doubleClicked(tbl, dlg):

    if 'tab_epa' in tbl.objectName():
        dlg.findChild(QPushButton, 'tab_epa_edit_dscenario').click()
    elif 'dscenario' in tbl.objectName():
        dlg.findChild(QPushButton, 'btn_edit_dscenario').click()
    elif 'tbl_dwf' in tbl.objectName():
        dlg.findChild(QPushButton, 'btn_edit_dwf').click()
    elif 'tbl_inflows' in tbl.objectName():
        dlg.findChild(QPushButton, 'btn_edit_inflows').click()
    else:
        dlg.findChild(QPushButton, 'btn_edit_base').click()


def epa_tbl_flags(index, model, non_editable_columns=None):

    column_name = model.headerData(index.column(), Qt.Orientation.Horizontal, Qt.ItemDataRole.DisplayRole)
    if non_editable_columns and column_name in non_editable_columns:
        flags = Qt.ItemFlag.ItemIsSelectable | Qt.ItemFlag.ItemIsEnabled
        return flags

    return QStandardItemModel.flags(model, index)

# region Tab epa


def open_epa_dlg(windowtitle, **kwargs):
    # Get variables
    complet_result = kwargs['complet_result']
    info = kwargs['class']
    func_params = kwargs['func_params']
    ui = func_params['ui']
    ui_name = func_params['uiName']
    tableviews = func_params['tableviews']
    widgets = func_params.get('widgets')
    widgets_tablename = func_params.get('widgetsTablename')
    widgets_table_pk = func_params.get('widgetsTablePk')

    feature_id = complet_result['body']['feature']['id']
    id_name = complet_result['body']['feature']['idName']

    # Build dlg
    info.dlg = globals()[ui](info)
    tools_gw.load_settings(info.dlg)
    info.dlg.setWindowTitle(windowtitle)

    if windowtitle == "DWF & INFLOWS":
        pages = ["page_base", "page_dscenario"]
        remove_toolbox_page(info.dlg.toolBox, pages)
        info.dlg.repaint()
    elif windowtitle == "Demand":
        pages = ["page_base", "page_dwf", "page_inflows"]
        remove_toolbox_page(info.dlg.toolBox, pages)
        info.dlg.repaint()
    else:
        pages = ["page_dwf", "page_inflows"]
        remove_toolbox_page(info.dlg.toolBox, pages)
        info.dlg.repaint()

    # Fill widgets
    if widgets and widgets_tablename:
        fields = str(widgets).replace('[', '').replace(']', '').replace('\'', '')
        sql = f"SELECT {fields} FROM {widgets_tablename} WHERE {id_name} = '{feature_id}'"
        row = tools_db.get_row(sql)
        if row:
            setattr(info, f"my_json_{widgets_tablename}", {})
            for i, widget in enumerate(widgets):
                # lineedits
                w = info.dlg.findChild(QLineEdit, widget)
                if w is None:
                    continue
                tools_qt.set_widget_text(info.dlg, w, row[i])
                w.editingFinished.connect(partial(tools_gw.get_values, info.dlg, w, getattr(info, f"my_json_{widgets_tablename}")))
                w.editingFinished.connect(partial(_manage_accept_btn, info, widgets_tablename))
        info.dlg.btn_accept.clicked.connect(partial(save_widgets_changes, widgets_tablename, info, info.dlg, widgets_table_pk))
    # Fill tableviews
    for tableview in tableviews:
        tbl = tableview['tbl']
        tbl = info.dlg.findChild(QTableView, tbl)
        if not tbl:
            continue
        view = tableview['view']
        add_view = tableview.get('add_view', view)
        add_dlg_title = tableview.get('add_dlg_title', f"{add_view} - Base")
        pk = tableview.get('pk')
        if not pk:
            pk = id_name
        id_name = tableview.get('id_name', id_name)

        complet_list = get_list(view, id_name, feature_id)
        fill_tbl(complet_list, tbl, info, view, info.dlg)
        tools_gw.set_tablemodel_config(info.dlg, tbl, view, schema_name=info.schema_name)
        info.dlg.btn_accept.clicked.connect(partial(save_tbl_changes, view, info, info.dlg, pk))

        # Add & Delete buttons
        if 'dscenario' in view and 'inflows' not in view:
            btn_add_dscenario = info.dlg.findChild(QPushButton, 'btn_add_dscenario')
            if btn_add_dscenario:
                tools_gw.add_icon(btn_add_dscenario, '113')
                btn_add_dscenario.clicked.connect(partial(add_row_epa, tbl, view, add_view, pk, info.dlg, add_dlg_title, "INSERT", **kwargs))
            btn_delete_dscenario = info.dlg.findChild(QPushButton, 'btn_delete_dscenario')
            if btn_delete_dscenario:
                tools_gw.add_icon(btn_delete_dscenario, '114')
                btn_delete_dscenario.clicked.connect(partial(delete_tbl_row, tbl, view, pk, info.dlg, **kwargs))
            btn_edit_dscenario = info.dlg.findChild(QPushButton, 'btn_edit_dscenario')
            if btn_edit_dscenario:
                tools_gw.add_icon(btn_edit_dscenario, '101')
                btn_edit_dscenario.clicked.connect(partial(edit_row_epa, tbl, view, add_view, pk, info.dlg, add_dlg_title, **kwargs))
        elif 'dwf' in view:
            btn_add_dwf = info.dlg.findChild(QPushButton, 'btn_add_dwf')
            if btn_add_dwf:
                tools_gw.add_icon(btn_add_dwf, '113')
                btn_add_dwf.clicked.connect(partial(add_row_epa, tbl, view, add_view, pk, info.dlg, add_dlg_title, "INSERT", **kwargs))
            btn_edit_dwf = info.dlg.findChild(QPushButton, 'btn_edit_dwf')
            if btn_edit_dwf:
                tools_gw.add_icon(btn_edit_dwf, '101')
                btn_edit_dwf.clicked.connect(partial(edit_row_epa, tbl, view, add_view, pk, info.dlg, add_dlg_title, **kwargs))
            btn_delete_dwf = info.dlg.findChild(QPushButton, 'btn_delete_dwf')
            if btn_delete_dwf:
                tools_gw.add_icon(btn_delete_dwf, '114')
                btn_delete_dwf.clicked.connect(partial(delete_tbl_row, tbl, view, pk, info.dlg, tablename=tableview['tbl'], tableview=tableview['view'], id_name=id_name, feature_id=feature_id, **kwargs))
        elif 'inflows' in view:
            btn_add_inflows = info.dlg.findChild(QPushButton, 'btn_add_inflows')
            if btn_add_inflows:
                tools_gw.add_icon(btn_add_inflows, '113')
                btn_add_inflows.clicked.connect(partial(add_row_epa, tbl, view, add_view, pk, info.dlg, add_dlg_title, "INSERT", **kwargs))
            btn_edit_inflows = info.dlg.findChild(QPushButton, 'btn_edit_inflows')
            if btn_edit_inflows:
                tools_gw.add_icon(btn_edit_inflows, '101')
                btn_edit_inflows.clicked.connect(partial(edit_row_epa, tbl, view, add_view, pk, info.dlg, add_dlg_title, **kwargs))
            btn_delete_inflows = info.dlg.findChild(QPushButton, 'btn_delete_inflows')
            if btn_delete_inflows:
                tools_gw.add_icon(btn_delete_inflows, '114')
                btn_delete_inflows.clicked.connect(partial(delete_tbl_row, tbl, view, pk, info.dlg, tablename=tableview['tbl'], tableview=tableview['view'], id_name=id_name, feature_id=feature_id, **kwargs))
        else:
            btn_add_base = info.dlg.findChild(QPushButton, 'btn_add_base')
            if btn_add_base:
                tools_gw.add_icon(btn_add_base, '113')
                btn_add_base.clicked.connect(partial(add_row_epa, tbl, view, add_view, pk, info.dlg, add_dlg_title, "INSERT", **kwargs))
            btn_edit_base = info.dlg.findChild(QPushButton, 'btn_edit_base')
            if btn_edit_base:
                tools_gw.add_icon(btn_edit_base, '101')
                btn_edit_base.clicked.connect(partial(edit_row_epa, tbl, view, add_view, pk, info.dlg, add_dlg_title, **kwargs))
            btn_delete_base = info.dlg.findChild(QPushButton, 'btn_delete_base')
            if btn_delete_base:
                tools_gw.add_icon(btn_delete_base, '114')
                btn_delete_base.clicked.connect(partial(delete_tbl_row, tbl, view, pk, info.dlg, tablename=tableview['tbl'], tableview=tableview['view'], id_name=id_name, feature_id=feature_id, **kwargs))

        # Populate custom context menu
        tbl.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        tbl.customContextMenuRequested.connect(partial(_show_context_menu, tbl, tableview))

    info.dlg.btn_cancel.clicked.connect(partial(tools_gw.close_dialog, info.dlg, True))
    info.dlg.finished.connect(partial(tools_gw.save_settings, info.dlg))
    # Open dlg
    tools_gw.open_dialog(info.dlg, dlg_name=ui_name)


def _show_context_menu(qtableview, tableview):
        """ Show custom context menu """

        menu = QMenu(qtableview)
        if 'dscenario' in tableview['view'] and 'inflows' not in tableview['view']:
            action_delete = QAction("Delete dscenario", qtableview)
            action_delete.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_delete_dscenario"))
            menu.addAction(action_delete)

            action_edit = QAction("Edit dscenario", qtableview)
            action_edit.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_edit_dscenario"))
            menu.addAction(action_edit)
        elif 'dwf' in tableview['view']:
            action_delete = QAction("Delete dwf", qtableview)
            action_delete.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_delete_dwf"))
            menu.addAction(action_delete)

            action_edit = QAction("Edit dwf", qtableview)
            action_edit.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_edit_dwf"))
            menu.addAction(action_edit)
        elif 'inflows' in tableview['view']:
            action_delete = QAction("Delete inflows", qtableview)
            action_delete.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_delete_inflows"))
            menu.addAction(action_delete)

            action_edit = QAction("Edit inflows", qtableview)
            action_edit.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_edit_inflows"))
            menu.addAction(action_edit)
        else:
            action_delete = QAction("Delete base", qtableview)
            action_delete.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_delete_base"))
            menu.addAction(action_delete)

            action_edit = QAction("Edit base", qtableview)
            action_edit.triggered.connect(partial(tools_gw._force_button_click, qtableview.window(), QPushButton, "btn_edit_base"))
            menu.addAction(action_edit)

        menu.exec(QCursor.pos())


def remove_toolbox_page(toolbox, pages):
    for page in pages:
        toolbox.widget(tools_qt.get_page_index_by_page_name(toolbox, page)).deleteLater()
        toolbox.removeItem(tools_qt.get_page_index_by_page_name(toolbox, page))


def edit_row_epa(tbl, view, tablename, pkey, dlg, dlg_title, **kwargs):
    # Get selected row
    selected_list = tbl.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message, dialog=dlg)
        return

    values = []
    if pkey:
        if not isinstance(pkey, list):
            pkey = [pkey]
        values = []
        for index in selected_list:
            value = {}
            for pk in pkey:
                col_idx = tools_qt.get_col_index_by_col_name(tbl, pk)
                if col_idx is None:
                    col_idx = 0
                value[pk] = index.sibling(index.row(), col_idx).data()
            if value:
                values.append(value)

    kwargs['values'] = values
    add_row_epa(tbl, view, tablename, pkey, dlg, dlg_title, "UPDATE", **kwargs)


def add_row_epa(tbl, view, tablename, pkey, dlg, dlg_title, force_action, **kwargs):

    # Get variables
    complet_result = kwargs['complet_result']
    info = kwargs['class']
    my_json = getattr(info, f"my_json_{view}")
    if my_json:
        msg = ("You are trying to add/remove a record from the table, with changes to the current records."
                  "If you continue, the changes will be discarded without saving. Do you want to continue?")
        title = "Info Message"
        answer = tools_qt.show_question(msg, title, force_action=True)
        if not answer:
            return
    feature_id = complet_result['body']['feature']['id']

    feature = f'"tableName":"{tablename}", "isEpa": true'
    if force_action == "UPDATE":
        values = kwargs['values']
        id_str = ', '.join([str(value) for value in values[0].values()])
        feature += f', "id": "{id_str}"'
    body = tools_gw.create_body(feature=feature)
    json_result = tools_gw.execute_procedure('gw_fct_getinfofromid', body)
    if json_result is None or json_result['status'] == 'Failed':
        return
    result = json_result

    if 'form' in json_result['body'] and 'visibleTabs' in json_result['body']['form']:
        for tab in json_result['body']['form']['visibleTabs']:
            info.visible_tabs[tab['tabName']] = tab

    # Build dlg
    info.add_dlg = GwInfoGenericUi(info)
    tools_gw.load_settings(info.add_dlg)
    info.my_json_add = {}
    tools_gw.build_dialog_info(info.add_dlg, result, my_json=info.my_json_add, tab_name="tab_none", enable_actions=True, is_inserting=False)

    # Populate node_id/feature_id
    tools_qt.set_widget_text(info.add_dlg, f'tab_none_{info.feature_type}_id', feature_id)
    tools_qt.set_widget_text(info.add_dlg, 'tab_none_feature_id', feature_id)
    layout = info.add_dlg.findChild(QGridLayout, 'lyt_main_1')
    tools_qt.set_selected_item(info.add_dlg, 'tab_none_feature_type', f"{info.feature_type.upper()}")
    tools_qt.set_widget_enabled(info.add_dlg, 'tab_none_feature_type', False)

    cmb_nodarc_id = info.add_dlg.findChild(QComboBox, 'tab_none_nodarc_id')
    aux_view = view.replace("dscenario_", "")
    if cmb_nodarc_id is not None:
        sql = (f"SELECT nodarc_id as id, nodarc_id as idval FROM {aux_view}"
               f" WHERE {info.feature_type}_id = '{feature_id}'")
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(cmb_nodarc_id, rows)
    cmb_order_id = info.add_dlg.findChild(QComboBox, 'tab_none_order_id')
    if cmb_order_id is not None:
        sql = (f"SELECT order_id as id, order_id::text as idval FROM {aux_view}"
               f" WHERE {info.feature_type}_id = '{feature_id}'")
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(cmb_order_id, rows)

    # Get every widget in the layout
    widgets = []
    for row in range(layout.rowCount()):
        for column in range(layout.columnCount()):
            item = layout.itemAtPosition(row, column)
            if item is not None:
                widget = item.widget()
                if widget is not None and type(widget) is not QLabel:
                    widgets.append(widget)
    # Get all widget's values
    for widget in widgets:
        tools_gw.get_values(info.add_dlg, widget, info.my_json_add, ignore_editability=True)
    # Remove Nones from info.my_json_add
    keys_to_remove = []
    for key, value in info.my_json_add.items():
        if value is None:
            keys_to_remove.append(key)
    for key in keys_to_remove:
        del info.my_json_add[key]

    # Signals
    info.add_dlg.btn_close.clicked.connect(partial(tools_gw.close_dialog, info.add_dlg))
    info.add_dlg.dlg_closed.connect(partial(tools_gw.close_dialog, info.add_dlg))
    info.add_dlg.dlg_closed.connect(partial(refresh_epa_tbl, tbl, dlg, **kwargs))
    info.add_dlg.btn_accept.clicked.connect(partial(accept_add_dlg, info.add_dlg, tablename, pkey, feature_id, info.my_json_add, result, info, force_action))

    # Open dlg
    tools_gw.open_dialog(info.add_dlg, dlg_name='info_generic', title=dlg_title)

    # Setup "Set to Arc" action
    action_set_to_arc = info.add_dlg.findChild(QAction, "actionSetToArc")
    tools_gw.add_icon(action_set_to_arc, "157")

    action_set_to_arc.triggered.connect(
        partial(info.get_snapped_feature_id, info.add_dlg, action_set_to_arc, 've_arc', 'set_to_arc_simple', 'tab_none_to_arc',
                None))


def refresh_epa_tbl(tblview, dlg, **kwargs):
    # Get variables
    complet_result = kwargs['complet_result']
    info = kwargs['class']
    func_params = kwargs['func_params']
    tableviews = func_params['tableviews']

    feature_id = complet_result['body']['feature']['id']
    id_name = complet_result['body']['feature']['idName']

    # Fill tableviews
    for tableview in tableviews:
        tbl = tableview['tbl']
        tbl = dlg.findChild(QTableView, tbl)
        if not tbl:
            continue
        if tbl != tblview:
            continue
        id_name = tableview.get('id_name', id_name)
        if dlg == info.dlg_cf:
            view = tbl.property('linkedobject')
        else:
            view = tableview['view']
        complet_list = get_list(view, id_name, feature_id)
        fill_tbl(complet_list, tbl, info, view, dlg)
        tools_gw.set_tablemodel_config(dlg, tbl, view, schema_name=info.schema_name)


def reload_tbl_dscenario(info, tablename, tableview, id_name, feature_id):
    tbl_name = tablename.replace("tbl", "tbl_dscenario")
    view = tableview.replace("inp", "inp_dscenario")
    tbl = info.dlg.findChild(QTableView, tbl_name)

    if tbl is not None:
        complet_list = get_list(view, id_name, feature_id)
        fill_tbl(complet_list, tbl, info, view, info.dlg)


def delete_tbl_row(tbl, view, pkey, dlg, tablename=None, tableview=None, id_name=None, feature_id=None, **kwargs):
    # Get variables
    info = kwargs['class']

    my_json = getattr(info, f"my_json_{view}")
    if my_json:
        msg = ("You are trying to add/remove a record from the table, with changes to the current records."
                  "If you continue, the changes will be discarded without saving. Do you want to continue?")
        title = "Info Message"
        answer = tools_qt.show_question(msg, title, force_action=True)
        if not answer:
            return

    # Get selected row
    selected_list = tbl.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message, dialog=dlg)
        return

    values = []
    if pkey:
        if not isinstance(pkey, list):
            pkey = [pkey]
        values = []
        for index in selected_list:
            value = {}
            for pk in pkey:
                col_idx = tools_qt.get_col_index_by_col_name(tbl, pk)
                if col_idx is None:
                    col_idx = 0
                value[pk] = index.sibling(index.row(), col_idx).data()
            if value:
                values.append(value)

    msg = "Are you sure you want to delete these records?"
    title = "Delete records"
    answer = tools_qt.show_question(msg, title, values, force_action=True)
    if answer:
        for value in values:
            conditions = []
            for key, val in value.items():
                condition = f"{key} = '{val}'"
                conditions.append(condition)
            condition_str = " AND ".join(conditions)
            sql = f"DELETE FROM {view} WHERE {condition_str}"
            tools_db.execute_sql(sql)
            try:
                info.dlg.btn_accept.setEnabled(True)
                info.inserted_feature = True
            except (AttributeError, RuntimeError):
                pass
        # Refresh tableview
        refresh_epa_tbl(tbl, dlg, **kwargs)
        if 'dscenario' not in view:
            reload_tbl_dscenario(info, tablename, tableview, id_name, feature_id)


def accept_add_dlg(dialog, tablename, pkey, feature_id, my_json, complet_result, info, force_action):

    if not my_json:
        return

    list_mandatory = []
    list_filter = []

    for field in complet_result['body']['data']['fields']:
        if field['ismandatory']:
            widget = dialog.findChild(QWidget, field['widgetname'])
            if not widget:
                continue
            widget.setStyleSheet(None)
            value = tools_qt.get_text(dialog, widget)
            if value in ('null', None, ''):
                widget.setStyleSheet("border: 1px solid red")
                list_mandatory.append(field['widgetname'])
            else:
                elem = [field['columnname'], value]
                list_filter.append(elem)

    if list_mandatory:
        msg = "Some mandatory values are missing. Please check the widgets marked in red."
        tools_qgis.show_warning(msg, dialog=dialog)
        tools_qt.set_action_checked("actionEdit", True, dialog)
        return False

    fields = json.dumps(my_json)
    id_val = ""
    if pkey:
        if not isinstance(pkey, list):
            pkey = [pkey]
        for pk in pkey:
            widget_name = f"tab_none_{pk}"
            value = tools_qt.get_widget_value(dialog, widget_name)
            id_val += f"{value}, "
        id_val = id_val[:-2]
    if id_val in (None, '', 'None'):
        id_val = feature_id

    feature = f'"id":"{id_val}", '
    feature += f'"tableName":"{tablename}"'
    extras = f'"fields":{fields}, "force_action":"{force_action}"'
    body = tools_gw.create_body(feature=feature, extras=extras)
    json_result = tools_gw.execute_procedure('gw_fct_upsertfields', body)
    if json_result and json_result.get('status') == 'Accepted':
        tools_gw.close_dialog(dialog)
        try:
            info.dlg.btn_accept.setEnabled(True)
            info.inserted_feature = True
        except (AttributeError, RuntimeError):
            pass
        return

    tools_qgis.show_warning(tools_qt.tr('Error'), parameter=json_result, dialog=dialog)


def tbl_data_changed(info, view, tbl, model, addparam, index):

    # Get view pk
    ids = ''
    if addparam:
        for pk in addparam.split(','):
            col = tools_qt.get_col_index_by_col_name(tbl, pk.strip())
            if col is not False:
                ids += f"{model.index(index.row(), col).data()}, "
        ids = ids.strip(', ')
    else:
        ids = f"{model.index(index.row(), 0).data()}"

    if ids not in getattr(info, f"my_json_{view}"):
        getattr(info, f"my_json_{view}")[ids] = {}

    # Get edited cell
    fieldname = model.headerData(index.column(), Qt.Orientation.Horizontal)
    field = index.data()

    # Fill my_json
    if str(field) == '' or field is None:
        getattr(info, f"my_json_{view}")[ids][fieldname] = None
    else:
        getattr(info, f"my_json_{view}")[ids][fieldname] = str(field)

    # Enable btn_accept
    try:
        info.dlg.btn_accept.setEnabled(True)
    except (AttributeError, RuntimeError):
        pass


def save_tbl_changes(table_name, info, dialog, pk):

    my_json = getattr(info, f"my_json_{table_name}")
    list_rows = []
    status = True
    if info.inserted_feature and not my_json:
        info.inserted_feature = False
        tools_gw.close_dialog(dialog)
        return
    elif not my_json:
        return

    # For each edited row
    for k, v in my_json.items():

        fields = json.dumps(v)
        if not fields:
            continue
        feature = f'"id":"{k}"'
        if pk and type(pk) is not list and ',' not in pk:
            feature += f', "idName":"{pk}"'
        feature += f', "tableName":"{table_name}"'
        extras = f'"fields":{fields}, "force_action":"UPDATE"'
        body = tools_gw.create_body(feature=feature, extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_upsertfields', body)
        if json_result and json_result.get('status') != 'Accepted':
            status = False
            list_rows.append(k)
    if status:
        tools_gw.close_dialog(dialog)
    else:
        msg = tools_qt.tr('There are some error in the records with id')
        tools_qgis.show_warning(msg, parameter=list_rows, dialog=dialog)


def save_widgets_changes(table_name, info, dialog, pk):
    my_json = getattr(info, f"my_json_{table_name}")
    status = True
    if info.inserted_feature and not my_json:
        info.inserted_feature = False
        tools_gw.close_dialog(dialog)
        return
    elif not my_json:
        return

    fields = json.dumps(my_json)
    if not fields:
        return
    id_ = tools_qt.get_text(dialog, pk)
    feature = f'"id":"{id_}"'
    if pk and type(pk) is not list:
        feature += f', "idName":"{pk}"'
    feature += f', "tableName":"{table_name}"'
    extras = f'"fields":{fields}, "force_action":"UPDATE"'
    body = tools_gw.create_body(feature=feature, extras=extras)
    json_result = tools_gw.execute_procedure('gw_fct_upsertfields', body)
    if json_result and json_result.get('status') != 'Accepted':
        status = False

    if status:
        tools_gw.close_dialog(dialog)
    else:
        msg = tools_qt.tr('There are some error in the records with id')
        tools_qgis.show_warning(msg, parameter=id_, dialog=dialog)


def _manage_accept_btn(info, tablename):
    my_json = getattr(info, f"my_json_{tablename}")
    if not my_json:
        return
    try:
        info.dlg.btn_accept.setEnabled(True)
    except (AttributeError, RuntimeError):
        pass


def add_to_dscenario(**kwargs):

    func_params = kwargs['func_params']
    dialog = kwargs['dialog']
    info = kwargs['class']
    tbl = tools_qt.get_widget(dialog, func_params.get('targetwidget'))
    tablename = func_params.get('tablename')
    dlg_title = func_params.get('add_dlg_title')
    pkey = func_params.get('pkey')
    if dlg_title:
        dlg_title = f"{dlg_title} - Dscenario"
    else:
        dlg_title = f"{tablename} - Dscenario"

    my_json = getattr(info, f"my_json_{tablename}")
    if my_json:
        msg = ("You are trying to add/remove a record from the table, with changes to the current records. "
              "If you continue, the changes will be discarded without saving. Do you want to continue?")
        answer = tools_qt.show_question(msg, "Info Message", force_action=True)
        if not answer:
            return

    setattr(info, f"my_json_{tablename}", {})

    add_row_epa(tbl, tablename, tablename, pkey, dialog, dlg_title, "INSERT", **kwargs)


def remove_from_dscenario(**kwargs):
    func_params = kwargs['func_params']
    dialog = kwargs['dialog']
    info = kwargs['class']
    tbl = tools_qt.get_widget(dialog, func_params.get('targetwidget'))
    tablename = func_params.get('tablename')
    pkey = func_params.get('pkey')

    my_json = getattr(info, f"my_json_{tablename}")
    if my_json:
        msg = "You are trying to add/remove a record from the table, with changes to the current records. If you continue, the changes will be discarded without saving. Do you want to continue?"
        answer = tools_qt.show_question(msg, "Info Message", force_action=True)
        if not answer:
            return

    setattr(info, f"my_json_{tablename}", {})

    delete_tbl_row(tbl, tablename, pkey, dialog, **kwargs)


def edit_dscenario(**kwargs):
    func_params = kwargs['func_params']
    dialog = kwargs['dialog']
    info = kwargs['class']
    tbl = tools_qt.get_widget(dialog, func_params.get('targetwidget'))
    tablename = func_params.get('tablename')
    view = tablename
    pkey = func_params.get('pkey')
    dlg_title = f"Edit {tablename}"

    my_json = getattr(info, f"my_json_{tablename}")
    if my_json:
        msg = ("You are trying to add/remove a record from the table, with changes to the current records. "
                  "If you continue, the changes will be discarded without saving. Do you want to continue?")
        answer = tools_qt.show_question(msg, "Info Message", force_action=True)
        if not answer:
            return

    setattr(info, f"my_json_{tablename}", {})

    edit_row_epa(tbl, view, tablename, pkey, dialog, dlg_title, **kwargs)

# endregion

# region Tab element


def open_selected_element(**kwargs):
    """
    Open form of selected element of the @qtable??
        function called in module tools_gw: def add_tableview(complet_result, field, module=sys.modules[__name__])
        at lines:   widget.doubleClicked.connect(partial(getattr(module, function_name), **kwargs))
    """
    func_params = kwargs['func_params']
    qtable = kwargs['qtable'] if 'qtable' in kwargs else tools_qt.get_widget(kwargs['dialog'], f"{func_params['targetwidget']}")
    # Get selected rows
    selected_list = qtable.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message)
        return

    index = selected_list[0]
    row = index.row()
    column_index = tools_qt.get_col_index_by_col_name(qtable, func_params['columnfind'])
    element_id = index.sibling(row, column_index).data()

    # Open selected element
    manage_element(element_id, **kwargs)


def manage_element(element_id, **kwargs):
    """ Function called in class tools_gw.add_button(...) -->
            widget.clicked.connect(partial(getattr(self, function_name), **kwargs)) """

    feature = None
    complet_result = kwargs['complet_result']
    feature_type = complet_result['body']['feature']['featureType']
    feature_id = complet_result['body']['feature']['id']
    field_id = str(complet_result['body']['feature']['idName'])
    table_parent = str(complet_result['body']['feature']['tableParent'])
    schema_name = str(complet_result['body']['feature']['schemaName'])

    # When click button 'new_element' element id is the signal emited by the button
    if element_id is False:
        layer = tools_qgis.get_layer_by_tablename(table_parent, False, False, schema_name)
        if layer:
            expr_filter = f"{field_id} = '{feature_id}'"
            feature = tools_qgis.get_feature_by_expr(layer, expr_filter)

    elem = GwElementManagerButton()
    elem.get_element(True, feature, feature_type)

    # If element exist
    if element_id:
        tools_qt.set_widget_text(elem.dlg_add_element, "element_id", element_id)
        elem.dlg_add_element.btn_accept.clicked.connect(partial(_reload_table, **kwargs))
    # If we are creating a new element
    else:
        elem.dlg_add_element.btn_accept.clicked.connect(partial(_manage_element_new, elem, **kwargs))


def add_frelem_to_dscenario(**kwargs):
    """ Add frelem to dscenario """
    class_obj = kwargs['class']
    dialog = kwargs['dialog']
    func_params = kwargs['func_params']
    # Get element_id from tbl_elements
    qtable: Union[QTableView, QTableWidget, None] = kwargs['qtable'] if 'qtable' in kwargs else tools_qt.get_widget(dialog, f"{func_params['sourcewidget']}")
    if qtable is None:
        return

    node_id = class_obj.feature_id

    # Get selected rows
    selected_list = qtable.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message, dialog=dialog)
        return

    # Check if all selected rows are frelem
    for index in selected_list:
        row = index.row()
        column_index = tools_qt.get_col_index_by_col_name(qtable, 'feature_class')
        feature_class = index.sibling(row, column_index).data()
        if feature_class != 'FRELEM':
            message = "Only FRELEM can be added to dscenario"
            tools_qgis.show_warning(message, dialog=dialog)
            return

    # Ask user for dscenario_id
    title = "Choose dscenario"
    label_text = "Choose dscenario"
    options = []
    sql = "SELECT dscenario_id as id, name as idval FROM cat_dscenario"
    rows = tools_db.get_rows(sql)
    if not rows:
        rows = [('', '')]
    options = rows

    edit_dialog = GwEditDialog(dialog, title=title, label_text=label_text, widget_type="QComboBox", options=options)
    if edit_dialog.exec() == QDialog.DialogCode.Accepted:
        dscenario_id = edit_dialog.get_value()
        if dscenario_id is None:
            return

        # Process all selected rows
        for index in selected_list:
            row = index.row()
            column_index = tools_qt.get_col_index_by_col_name(qtable, func_params['columnfind'])
            element_id = index.sibling(row, column_index).data()

            # Get frelem epa_type
            sql = f"SELECT epa_type FROM ve_man_frelem WHERE element_id = '{element_id}'"
            row_data = tools_db.get_row(sql)
            if not row_data:
                continue
            epa_type = row_data[0]
            if epa_type == 'UNDEFINED':
                message = f"Epa type is not defined for element {element_id}"
                tools_qgis.show_warning(message, dialog=dialog)
                continue
            # Add frelem to dscenario
            sql = (f"INSERT INTO ve_inp_dscenario_{epa_type.lower()} (dscenario_id, element_id, node_id) "
                   f"VALUES ('{dscenario_id}', '{element_id}', '{node_id}')")
            tools_db.execute_sql(sql)

        _reload_table(**kwargs)
        # TODO: switch to tab_{epa_type}


def remove_frelem_from_dscenario(**kwargs):
    """ Remove frelem from dscenario """
    dialog = kwargs['dialog']
    func_params = kwargs['func_params']

    index_tab = dialog.tab_frelem_dscenario.currentIndex()
    tab_name = dialog.tab_frelem_dscenario.widget(index_tab).objectName()  # tab_orifice, tab_outlet, tab_pump, tab_weir
    frelem_name = tab_name.replace('tab_', '')
    qtable: Union[QTableView, QTableWidget, None] = dialog.tab_frelem_dscenario.widget(index_tab).findChild(QTableView, f"tab_elements_tbl_frelem_dsc_{frelem_name}")
    if qtable is None:
        return

    selected_list = qtable.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message, dialog=dialog)
        return

    columnfind = func_params.get('columnfind')
    where_clauses = []
    values = []
    for index in selected_list:
        row = index.row()
        where_clause = ""
        value = {}
        for column in columnfind:
            column_index = tools_qt.get_col_index_by_col_name(qtable, column)
            data = index.sibling(row, column_index).data()
            where_clause += f"{column} = '{data}' AND "
            value[column] = data
        where_clause = where_clause[:-4]
        where_clauses.append(where_clause)
        values.append(value)

    msg = "Are you sure you want to delete these records?"
    title = "Delete records"
    answer = tools_qt.show_question(msg, title, values, force_action=True)
    if not answer:
        return

    for where_clause in where_clauses:
        sql = f"DELETE FROM ve_inp_dscenario_fr{frelem_name} WHERE {where_clause}"
        tools_db.execute_sql(sql)
    _reload_table(**kwargs)


def _manage_element_new(elem, **kwargs):
    """ Get inserted element_id and add it to current feature """
    if elem.element_id is None:
        return

    dialog = kwargs['dialog']
    func_params = kwargs['func_params']
    tools_qt.set_widget_text(dialog, f"{func_params['sourcewidget']}", elem.element_id)
    tools_backend_calls.add_object(**kwargs)


def _reload_table(**kwargs):
    """ Get inserted element_id and add it to current feature """
    dialog = kwargs['dialog']
    index_tab = dialog.tab_main.currentIndex()
    tab_name = dialog.tab_main.widget(index_tab).objectName()

    list_tables = dialog.tab_main.widget(index_tab).findChildren(QTableView)
    complet_result = kwargs['complet_result']
    feature_id = complet_result['body']['feature']['id']
    field_id = str(complet_result['body']['feature']['idName'])
    widget_list = []
    widget_list.extend(dialog.tab_main.widget(index_tab).findChildren(QComboBox, QRegularExpression(f"{tab_name}_")))
    widget_list.extend(dialog.tab_main.widget(index_tab).findChildren(QTableView, QRegularExpression(f"{tab_name}_")))
    widget_list.extend(dialog.tab_main.widget(index_tab).findChildren(QLineEdit, QRegularExpression(f"{tab_name}_")))

    for table in list_tables:
        widgetname = table.objectName()
        columnname = table.property('columnname')
        if columnname is None:
            msg = "widget {0} in tab {1} has not columnname and can't be configured"
            msg_params = (widgetname, dialog.tab_main.widget(index_tab).objectName(),)
            tools_qgis.show_info(msg, 1, msg_params=msg_params)
            continue

        # Get value from filter widgets
        filter_fields = tools_backend_calls.get_filter_qtableview(dialog, widget_list, kwargs['complet_result'])

        # if tab dont have any filter widget
        if filter_fields in ('', None):
            filter_fields = f'"{field_id}":{{"value":"{feature_id}","filterSign":"="}}'

        linkedobject = table.property('linkedobject')
        complet_list, widget_list = tools_backend_calls.fill_tbl(complet_result, dialog, widgetname, linkedobject, filter_fields)
        if complet_list is False:
            return False

# endregion

# region Tab relation


def open_selected_feature(**kwargs):
    """
    Open selected feature from @qtable
        function called in -> def add_tableview(complet_result, field, dialog, module=sys.modules[__name__])
        at line: widget.doubleClicked.connect(partial(getattr(module, function_name), **kwargs))
    """
    qtable = kwargs['qtable']
    complet_list = kwargs['complet_result']
    func_params = kwargs['func_params']

    # Get selected rows
    selected_list = qtable.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message)
        return

    index = selected_list[0]
    row = index.row()
    column_index = tools_qt.get_col_index_by_col_name(qtable, func_params['columnfind'])
    feature_id = index.sibling(row, column_index).data()
    table_name = complet_list['body']['feature']['tableName']
    if 'tablefind' in func_params:
        column_index = tools_qt.get_col_index_by_col_name(qtable, func_params['tablefind'])
        table_name = index.sibling(row, column_index).data()
    info_feature = GwInfo('tab_data')
    complet_result, dialog = info_feature.open_form(table_name=table_name, feature_id=feature_id, tab_type='tab_data')
    if not complet_result:
        msg = "FAIL {0}"
        msg_params = ("open_selected_feature",)
        tools_log.log_info(msg, msg_params=msg_params)
        return

# endregion

# region Tab hydrometer


def open_selected_hydro(**kwargs):
    qtable = kwargs['qtable']

    selected_list = qtable.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message)
        return

    index = selected_list[0]
    row = index.row()

    table_name = 'v_ui_hydrometer'
    column_index = tools_qt.get_col_index_by_col_name(qtable, 'hydrometer_id')
    feature_id = index.sibling(row, column_index).data()

    # return
    info_feature = GwInfo('tab_data')
    complet_result, dialog = info_feature.open_form(table_name=table_name, feature_id=feature_id,
                                                    tab_type='tab_data')
    if not complet_result:
        msg = "FAIL {0}"
        msg_params = ("open_selected_hydro",)
        tools_log.log_info(msg, msg_params=msg_params)
        return


def open_hydro_url(**kwargs):
    func_params = kwargs['func_params']
    targetwidget = func_params['targetwidget']
    tbl_hydrometer = tools_qt.get_widget(kwargs['dialog'], f"{targetwidget}")

    selected_list = tbl_hydrometer.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message)
        return

    row = selected_list[0].row()
    url = tbl_hydrometer.model().record(row).value("hydrometer_link")
    if url != '':
        status, message = tools_os.open_file(url)
        if status is False and message is not None:
            tools_qgis.show_warning(message, parameter=url)

# endregion

# region Tab visit


def open_visit_files(**kwargs):
    func_params = kwargs['func_params']
    qtable = tools_qt.get_widget(kwargs['dialog'], f"{func_params.get('targetwidget')}")
    if qtable is None or qtable.selectionModel() is None:
        return

    # Get selected rows
    selected_list = qtable.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message)
        return

    index = selected_list[0]
    row = index.row()
    column_index = tools_qt.get_col_index_by_col_name(qtable, 'visit_id')
    visit_id = index.sibling(row, column_index).data()
    sql = (f"SELECT value FROM om_visit_event_photo"
           f" WHERE visit_id = '{visit_id}'")
    rows = tools_db.get_rows(sql)
    for path in rows:
        # Open selected document
        status, message = tools_os.open_file(path[0])
        if status is False and message is not None:
            tools_qgis.show_warning(message, parameter=path[0])

# endregion

# region Tab event


def new_visit(**kwargs):
    """ Call button 64: om_add_visit """

    dlg_cf = kwargs['dialog']
    feature_type = kwargs['complet_result']['body']['feature']['featureType']
    feature_id = kwargs['complet_result']['body']['feature']['id']

    # Get expl_id to save it on om_visit and show the geometry of visit
    expl_id = tools_qt.get_combo_value(dlg_cf, 'tab_data_expl_id', 0)
    if expl_id == -1:
        msg = "Widget expl_id not found"
        tools_qgis.show_warning(msg)
        return

    date_event_from = dlg_cf.tab_event.findChild(QgsDateTimeEdit, "tab_event_date_event_from")
    date_event_to = dlg_cf.tab_event.findChild(QgsDateTimeEdit, "tab_event_date_event_to")

    tbl_event_cf = dlg_cf.findChild(QTableView, "tab_event_tbl_event_cf")
    manage_visit = GwVisit()
    manage_visit.visit_added.connect(partial(_update_visit_table, feature_type, date_event_from, date_event_to, tbl_event_cf))
    # TODO: the following query fix a (for me) misterious bug
    # the DB connection is not available during manage_visit.manage_visit first call
    # so the workaroud is to do a unuseful query to have the dao active
    sql = "SELECT id FROM om_visit LIMIT 1;"
    tools_db.get_rows(sql)
    manage_visit.get_visit(feature_type=feature_type, feature_id=feature_id, expl_id=expl_id,
                           is_new_from_cf=True)


def _update_visit_table(feature_type, date_event_from, date_event_to, tbl_event_cf):
    """ Convenience fuction set as slot to update table after a Visit GUI close. """
    table_name = "v_ui_event_x_" + feature_type
    tools_gw.set_dates_from_to(date_event_from, date_event_to, table_name, 'visit_start', 'visit_end')


def open_visit_document(**kwargs):
    """ Open document of selected record of the table """

    # search visit_id in table (targetwidget, columnfind)
    class_obj = kwargs['class']
    func_params = kwargs['func_params']
    qtable = kwargs['qtable'] if 'qtable' in kwargs else tools_qt.get_widget(kwargs['dialog'], f"{func_params.get('targetwidget')}")
    # Get selected rows
    selected_list = qtable.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message)
        return

    index = selected_list[0]
    row = index.row()
    column_index = tools_qt.get_col_index_by_col_name(qtable, func_params['columnfind'])
    visit_id = index.sibling(row, column_index).data()

    # Get all documents for one visit
    sql = (f"SELECT doc_id FROM doc_x_visit"
           f" WHERE visit_id = '{visit_id}'")
    rows = tools_db.get_rows(sql)
    if not rows:
        return

    num_doc = len(rows)
    if num_doc == 1:
        # If just one document is attached directly open

        # Get path of selected document
        sql = (f"SELECT path"
               f" FROM v_ui_doc"
               f" WHERE id = '{rows[0][0]}'")
        row = tools_db.get_row(sql)
        if not row:
            return

        path = str(row[0])

        # Parse a URL into components
        url = parse.urlsplit(path)

        # Open selected document
        # Check if path is URL
        if url.scheme == "http" or url.scheme == "https":
            webbrowser.open(path)
        else:

            if not os.path.exists(path):
                message = "File not found"
                tools_qgis.show_warning(message, parameter=path)
            else:
                status, message = tools_os.open_file(path)
                if status is False and message is not None:
                    tools_qgis.show_warning(message, parameter=path)

    else:
        # If more then one document is attached open dialog with list of documents
        dlg_load_doc = GwVisitDocumentUi(class_obj)
        tools_gw.load_settings(dlg_load_doc)
        dlg_load_doc.rejected.connect(partial(tools_gw.close_dialog, dlg_load_doc))

        btn_open_doc = dlg_load_doc.findChild(QPushButton, "btn_open")
        tbl_list_doc = dlg_load_doc.findChild(QListWidget, "tbl_list_doc")
        lbl_visit_id = dlg_load_doc.findChild(QLineEdit, "visit_id")

        lbl_visit_id.setText(str(visit_id))
        btn_open_doc.clicked.connect(partial(open_selected_doc, tbl_list_doc))
        tbl_list_doc.itemDoubleClicked.connect(partial(open_selected_doc, tbl_list_doc))
        for row in rows:
            item_doc = QListWidgetItem(str(row[0]))
            tbl_list_doc.addItem(item_doc)

        tools_gw.open_dialog(dlg_load_doc, dlg_name='visit_document')


def open_selected_doc(tbl_list_doc):

    # Selected item from list
    if tbl_list_doc.currentItem() is None:
        msg = "No document selected."
        tools_qgis.show_message(msg, Qgis.MessageLevel.Warning)
        return

    selected_document = tbl_list_doc.currentItem().text()

    # Get path of selected document
    sql = (f"SELECT path FROM v_ui_doc"
           f" WHERE id = '{selected_document}'")
    row = tools_db.get_row(sql)
    if not row:
        return

    path = str(row[0])

    # Parse a URL into components
    url = parse.urlsplit(path)

    # Open selected document
    # Check if path is URL
    if url.scheme == "http" or url.scheme == "https":
        webbrowser.open(path)
    else:
        if not os.path.exists(path):
            message = "File not found"
            tools_qgis.show_warning(message, parameter=path)
        else:
            status, message = tools_os.open_file(path)
            if status is False and message is not None:
                tools_qgis.show_warning(message, parameter=path)


def open_gallery(**kwargs):
    """ Open gallery of selected record of the table """

    dialog = kwargs['dialog']
    func_params = kwargs['func_params']
    qtable = kwargs['qtable'] if 'qtable' in kwargs else tools_qt.get_widget(dialog, f"{func_params.get('targetwidget')}")

    # Get selected rows
    selected_list = qtable.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message)
        return

    index = selected_list[0]
    row = index.row()
    ids = {}
    i = 0
    for col in func_params['columnfind']:
        column_index = tools_qt.get_col_index_by_col_name(qtable, func_params['columnfind'][i])
        ids[col] = index.sibling(row, column_index).data()
        i += 1
    visit_id = ids['visit_id']
    event_id = ids['event_id']

    # Open Gallery
    gal = GwVisitGallery()
    gal.manage_gallery()
    gal.fill_gallery(visit_id, event_id)


def open_visit_event(**kwargs):
    """
    Open event of selected record of the table
        Function called in:
            def add_button(**kwargs) -> widget.clicked.connect(partial(getattr(module, function_name), **kwargs))
            def add_tableview(complet_result, field, dialog, module=sys.modules[__name__]) ->
                                        widget.doubleClicked.connect(partial(getattr(module, function_name), **kwargs))
    """
    class_obj = kwargs['class']
    dialog = kwargs['dialog']
    func_params = kwargs['func_params']
    qtable = kwargs['qtable'] if 'qtable' in kwargs else tools_qt.get_widget(dialog, f"{func_params.get('targetwidget')}")

    # Get selected rows
    selected_list = qtable.selectionModel().selectedRows()
    if len(selected_list) == 0:
        message = "Any record selected"
        tools_qgis.show_warning(message)
        return

    index = selected_list[0]
    row = index.row()
    ids = {}
    i = 0
    for col in func_params['columnfind']:
        column_index = tools_qt.get_col_index_by_col_name(qtable, func_params['columnfind'][i])
        ids[col] = index.sibling(row, column_index).data()
        i += 1
    visit_id = ids['visit_id']
    event_id = ids['event_id']

    # Open dialog event_standard
    dlg_event_full = GwVisitEventFullUi(class_obj)
    tools_gw.load_settings(dlg_event_full)
    dlg_event_full.rejected.connect(partial(tools_gw.close_dialog, dlg_event_full))
    # Get all data for one visit
    sql = (f"SELECT * FROM om_visit_event"
           f" WHERE id = '{event_id}' AND visit_id = '{visit_id}';")
    row = tools_db.get_row(sql)
    if not row:
        return

    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.id, row['id'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.event_code, row['event_code'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.visit_id, row['visit_id'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.position_id, row['position_id'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.position_value, row['position_value'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.parameter_id, row['parameter_id'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.value, row['value'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.value1, row['value1'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.value2, row['value2'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.geom1, row['geom1'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.geom2, row['geom2'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.geom3, row['geom3'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.xcoord, row['xcoord'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.ycoord, row['ycoord'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.compass, row['compass'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.tstamp, row['tstamp'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.text, row['text'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.index_val, row['index_val'])
    tools_qt.set_widget_text(dlg_event_full, dlg_event_full.is_last, row['is_last'])
    _populate_tbl_docs_x_event(dlg_event_full, visit_id, event_id)

    # Set all QLineEdit readOnly(True)

    widget_list = dlg_event_full.findChildren(QTextEdit)
    aux = dlg_event_full.findChildren(QLineEdit)
    for w in aux:
        widget_list.append(w)
    for widget in widget_list:
        widget.setReadOnly(True)
        widget.setStyleSheet("QWidget { background: rgb(242, 242, 242);"
                             " color: rgb(100, 100, 100)}")
    dlg_event_full.btn_close.clicked.connect(partial(tools_gw.close_dialog, dlg_event_full))
    dlg_event_full.tbl_docs_x_event.doubleClicked.connect(partial(_open_file, dlg_event_full))
    tools_qt.set_tableview_config(dlg_event_full.tbl_docs_x_event)
    tools_gw.open_dialog(dlg_event_full, 'visit_event_full')


def _populate_tbl_docs_x_event(dlg_event_full, visit_id, event_id):

    # Create and set model
    model = QStandardItemModel()
    dlg_event_full.tbl_docs_x_event.setModel(model)
    dlg_event_full.tbl_docs_x_event.horizontalHeader().setStretchLastSection(True)
    dlg_event_full.tbl_docs_x_event.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.ResizeToContents)
    # Get columns name and set headers of model with that
    columns_name = tools_db.get_columns_list('om_visit_event_photo')
    headers = []
    for x in columns_name:
        headers.append(x[0])
    headers = ['value', 'filetype', 'fextension']
    model.setHorizontalHeaderLabels(headers)

    # Get values in order to populate model
    sql = (f"SELECT value, filetype, fextension FROM om_visit_event_photo "
           f"WHERE visit_id='{visit_id}' AND event_id='{event_id}'")
    rows = tools_db.get_rows(sql)
    if rows is None:
        return

    for row in rows:
        item = []
        for value in row:
            if value is not None:
                if type(value) is not str:
                    item.append(QStandardItem(str(value)))
                else:
                    item.append(QStandardItem(value))
            else:
                item.append(QStandardItem(None))
        if len(row) > 0:
            model.appendRow(item)


def _open_file(dlg_event_full):

    # Get row index
    index = dlg_event_full.tbl_docs_x_event.selectionModel().selectedRows()[0]
    column_index = tools_qt.get_col_index_by_col_name(dlg_event_full.tbl_docs_x_event, 'value')
    path = index.sibling(index.row(), column_index).data()
    status, message = tools_os.open_file(path)
    if status is False and message is not None:
        tools_qgis.show_warning(message, parameter=path)

# endregion

# endregion
