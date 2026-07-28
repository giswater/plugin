"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import os
import json
# TODO: Check this - do not delete this import for the moment
from ..utils import tools_gw  # noqa: F401
from ... import global_vars
from ...libs import tools_log, tools_qt, tools_db, tools_qgis, lib_vars
from qgis.core import QgsProject, QgsCoordinateReferenceSystem, QgsLayerTreeLayer, QgsLayerTreeGroup


class GwGisFileCreate:

    def __init__(self, plugin_dir):

        self.plugin_dir = plugin_dir
        self.layer_source = None
        self.srid = None

    def gis_project_database(self, folder_path=None, filename=None, project_type='ws', schema='ws_sample',
                             export_passwd=False, roletype='admin', layer_source=None, layer_project_type=None,
                             is_cm=False, force_overwrite=False, headless=False):

        # Get locale of QGIS application
        locale = tools_qgis.get_locale()

        # Get folder
        gis_extension = "qgs"
        gis_folder = self.plugin_dir + os.sep + "resources" + os.sep + "templates" + os.sep + "qgisproject"
        gis_locale_path = gis_folder + os.sep + locale

        # Manage default parameters
        if folder_path is None:
            folder_path = gis_locale_path

        if filename is None:
            filename = schema

        if not os.path.exists(folder_path):
            os.makedirs(folder_path)

        # Get database parameters from layer source
        self.layer_source = layer_source
        if self.layer_source is None:
            status, self.layer_source = self._get_database_parameters(schema)
            if not status:
                return False, None

        # Set QGS file path
        qgs_path = folder_path + os.sep + filename + "." + gis_extension
        if os.path.exists(qgs_path) and not force_overwrite:
            msg = "Do you want to overwrite file?"
            title = "Overwrite file"
            answer = tools_qt.show_question(msg, title, force_action=True)
            if not answer:
                return False, qgs_path

        # Create destination file from template file
        msg = "Creating GIS file... {0}"
        msg_params = (qgs_path)
        tools_log.log_info(msg, msg_params=msg_params)

        # Create project
        project = QgsProject.instance()
        QgsProject.instance().clear()

        root = project.layerTreeRoot()
        auth_id = self._replace_spatial_parameters(self.layer_source['srid'])

        # Set lib_vars.project_vars['store_credentials'] BEFORE creating layers
        lib_vars.project_vars['store_credentials'] = f"{export_passwd}"

        # Get project layers
        extras = f'"project_type":"{layer_project_type}", "is_cm":{str(is_cm).lower()}'
        body = tools_gw.create_body(extras=extras)
        layers = tools_gw.execute_procedure('gw_fct_get_project_layers', body, schema_name=schema)
        if layers:
            for layer in layers['body']['data']['layers']:
                template = layer.get('project_template')
                addparam = layer.get('addparam')
                properties = addparam.get('layerProp', None) if addparam is not None else None
                provider_config = layer.get('providerConfig')
                if not template:
                    continue

                if provider_config is None and layer.get('tableId') is None and layer.get('geomField') == 'None':
                    continue

                depth = template.get('levels_to_read')
                if layer.get('context') is not None:
                    context = json.loads(layer['context'])
                    levels = context.get(tools_qt.tr('levels')) or context.get('levels')
                    if levels is not None:
                        level = root
                        for i in range(0, depth):
                            if levels[i] is not None:
                                old_level = level.findGroup(levels[i])
                                if old_level is None:
                                    old_level = level.insertGroup(0, levels[i])
                                level = old_level
                    rectangle = tools_gw._get_extent_parameters(schema)
                    group = levels[0]
                    sub_group = levels[1] if len(levels) > 1 else None
                    sub_sub_group = levels[2] if len(levels) > 2 else None
                    if provider_config:
                        tools_gw.add_layer_provider(
                            layer['tableName'], provider_config, group, sub_group,
                            alias=layer['layerName'], sub_sub_group=sub_sub_group,
                            schema=layer['tableSchema'], visibility=template.get('visibility'),
                            force_create_group=False)
                    else:
                        tools_gw.add_layer_database(
                            layer['tableName'], layer['geomField'], layer['tableId'], group, sub_group,
                            alias=layer['layerName'], sub_sub_group=sub_sub_group, schema=layer['tableSchema'],
                            visibility=template.get('visibility'), auth_id=auth_id, extent=rectangle,
                            passwd=self.layer_source['password'] if export_passwd else None,
                            create_project=True, force_create_group=False, properties=properties)

        # Hide hidden group
        hidden_group = root.findGroup('HIDDEN')
        if hidden_group is not None:
            if not headless:
                tools_gw.hide_group_from_toc('HIDDEN')
            hidden_group.setItemVisibilityChecked(False)

        # Set project CRS
        project.setCrs(QgsCoordinateReferenceSystem(auth_id))

        # Set project variables
        project = self._set_project_vars(
            project, export_passwd, schema=schema, project_type=project_type, roletype=roletype
        )

        # Collapse all layers
        layers = root.findLayers()
        for layer in layers:
            if isinstance(layer, QgsLayerTreeLayer):
                layer.setExpanded(False)

        # Collapse all groups
        groups = root.findGroups()
        for group in groups:
            if isinstance(group, QgsLayerTreeGroup):
                group.setExpanded(False)

        # Set default project snapping settings
        if headless:
            self._set_project_snapping_settings(project)
        else:
            tools_qgis.set_project_snapping_settings()

        # Set camera position on ve_node
        if not headless and global_vars.iface is not None:
            global_vars.iface.mapCanvas().setExtent(tools_gw._get_extent_parameters(schema))

        # Save project
        try:
            if not project.write(qgs_path):
                raise IOError("QgsProject.write returned false")
            msg = "GIS file generated successfully"
            if not headless:
                tools_qgis.show_info(msg, parameter=qgs_path)
            return True, qgs_path
        except IOError:
            msg = "File cannot be created. Check if it is already opened"
            if not headless:
                tools_qgis.show_warning(msg, parameter=qgs_path)
            return False, qgs_path

    # region private functions

    def _get_database_parameters(self, schema):
        """ Get database parameters from layer source """

        layer_source, not_version = tools_db.get_layer_source_from_credentials('prefer')
        if layer_source is None:
            msg = "Error getting database parameters"
            tools_qgis.show_warning(msg)
            return False, None
        else:
            layer_source['srid'] = tools_db.get_srid('ve_node', schema)
            return True, layer_source

    def _replace_spatial_parameters(self, srid):

        sql = (f"SELECT 2104 as srs_id, srid, auth_name || ':' || auth_srid as auth_id "
               f"FROM spatial_ref_sys "
               f"WHERE srid = '{srid}'")
        row = tools_db.get_row(sql)

        if row:
            return row[2]

        return None

    def _set_project_vars(self, project, export_passwd, schema=None, project_type=None, roletype='admin'):

        project_type = project_type or tools_gw.get_project_type(schema)
        project_role = roletype if str(roletype).startswith('role_') else f'role_{roletype}'
        project.setCustomVariables({
            'gwAddSchema': '',
            'gwInfoType': 'full',
            'gwMainSchema': schema or '',
            'gwProjectRole': project_role,
            'gwProjectType': project_type,
            'gwStoreCredentials': f"{export_passwd}",
            'svg_path': os.path.join(self.plugin_dir, 'svg'),
        })

        return project

    @staticmethod
    def _set_project_snapping_settings(project):
        """Set the defaults without requiring a QGIS map canvas."""
        from qgis.core import Qgis, QgsSnappingConfig, QgsTolerance

        cfg = project.snappingConfig()
        cfg.setEnabled(True)
        cfg.setMode(QgsSnappingConfig.SnappingMode.AllLayers)
        cfg.setTolerance(15.0)
        cfg.setUnits(QgsTolerance.UnitType.Pixels)
        types = Qgis.SnappingType.Vertex | Qgis.SnappingType.Segment
        cfg.setTypeFlag(Qgis.SnappingTypes(types))
        project.setSnappingConfig(cfg)

    # endregion
