"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import os

from qgis.PyQt import uic, QtCore
from qgis.PyQt.QtGui import QIcon
from qgis.PyQt.QtWidgets import QAction, QLineEdit

from ...libs import lib_vars
from ...libs.ui.ui_manager import DialogTextUi
from .dialog import GwDialog
from .main_window import GwMainWindow

# region private functions


def _get_ui_class(ui_file_name, subfolder='shared'):
    """ Get UI Python class from @ui_file_name """

    # Folder that contains UI files
    if subfolder in ('basic', 'edit', 'epa', 'om', 'plan', 'utilities', 'toc', 'am', 'cm'):
        ui_folder_path = os.path.dirname(__file__) + os.sep + 'toolbars' + os.sep + subfolder
    else:
        ui_folder_path = os.path.dirname(__file__) + os.sep + subfolder

    ui_file_path = os.path.abspath(os.path.join(ui_folder_path, ui_file_name))
    return uic.loadUiType(ui_file_path)[0]


# endregion

# The CONTEXT and UINAME parameters are used to dynamically construct help URLs for dialogs.
# - If both CONTEXT and UINAME are provided, they are appended to the base URL as /dialogs/{CONTEXT}/{UINAME}.
# - If not provided, the function falls back to a default URL for the general manual.
# This ensures predictable and flexible behavior for btn_help links.

# region BASIC
CONTEXT = "basic"

UINAME = "info_crossect"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwInfoCrossectUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "info_feature"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwInfoFeatureUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME

    def __init__(self, class_obj, sub_tag):
        super().__init__(class_obj)


UINAME = "info_epa"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwInfoEpaUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "search_workcat"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwSearchWorkcatUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME
# endregion


# region OM
CONTEXT = "om"

UINAME = "mincut"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwMincutUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME

    def __init__(self, class_obj):
        self.closeMainWin = False
        self.mincutCanceled = True
        super().__init__(class_obj)


UINAME = "mincut_connec"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwMincutConnecUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "mincut_hydrometer"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwMincutHydrometerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "mincut_composer"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwMincutComposerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "mincut_manager"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwMincutManagerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "mincut_end"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwMincutEndUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "profile"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwProfileUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "profile_list"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwProfilesListUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "selector_date"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwSelectorDateUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME
# endregion


# region EDIT
CONTEXT = "edit"

UINAME = "arc_fusion"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwArcFusionUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "auxcircle"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAuxCircleUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "auxpoint"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAuxPointUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "dimensioning"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwDimensioningUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "doc"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwDocUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "doc_manager"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwDocManagerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "element_manager"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwElementManagerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "feature_delete"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwFeatureDeleteUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "feature_end"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwFeatureEndUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "feature_end_connec"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwFeatureEndConnecUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "feature_replace"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwFeatureReplaceUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "featuretype_change"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwFeatureTypeChangeUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "connect_link"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwConnectLinkUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME

# endregion


# region EPA
CONTEXT = "epa"

UINAME = "go2epa"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwGo2EpaUI(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "go2epa_selector"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwGo2EpaSelectorUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "go2epa_manager"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwEpaManagerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "go2epa_options"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwGo2EpaOptionsUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "dscenario_manager"
FROM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwDscenarioManagerUi(GwDialog, FROM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "nonvisual_curve"
FROM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwNonVisualCurveUi(GwDialog, FROM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "nonvisual_controls"
FROM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwNonVisualControlsUi(GwDialog, FROM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "nonvisual_manager"
FROM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwNonVisualManagerUi(GwDialog, FROM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "nonvisual_pattern_ud"
FROM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwNonVisualPatternUDUi(GwDialog, FROM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "nonvisual_pattern_ws"
FROM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwNonVisualPatternWSUi(GwDialog, FROM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "nonvisual_print"
FROM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwNonVisualPrint(GwDialog, FROM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "nonvisual_roughness"
FROM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwNonVisualRoughnessUi(GwDialog, FROM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "nonvisual_rules"
FROM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwNonVisualRulesUi(GwDialog, FROM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "nonvisual_timeseries"
FROM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwNonVisualTimeseriesUi(GwDialog, FROM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "nonvisual_lids"
FROM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwNonVisualLidsUi(GwDialog, FROM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "inp_parsing"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwInpParsingUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "inp_config_import"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwInpConfigImportUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


FORM_CLASS = _get_ui_class('epatools_add_demand_check.ui', 'epa')


class AddDemandCheckUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "epatools_recursive_go2epa"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class RecursiveEpaUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "epatools_emitter_calibration"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class EmitterCalibrationUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "epatools_quantized_demands"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class QuantizedDemandsUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "epatools_static_calibration"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class StaticCalibrationUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "epatools_valve_operation_check"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class ValveOperationCheckUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "go2iber"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwGo2IberUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME

# endregion


# region PLAN
CONTEXT = "plan"

UINAME = "psector"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwPsectorUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "psector_duplicate"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwPsectorDuplicateUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "psector_manager"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwPsectorManagerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "psector_rapport"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwPsectorRapportUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "psector_repair"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwPsectorRepairUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "netscenario_manager"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwNetscenarioManagerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "netscenario"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwNetscenarioUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME

# endregion


# region UTILITIES
CONTEXT = "utilities"

UINAME = "config"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwConfigUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "csv"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwCsvUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "epa_export"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class EpaExportUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "print"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwPrintUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "toolbox_reports"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwToolboxReportsUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "check_project"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwProjectCheckUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "workspace_manager"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwWorkspaceManagerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "workspace_create"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwCreateWorkspaceUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "mapzone_manager"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwMapzoneManagerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "style_manager"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwStyleManagerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "style"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwStyleUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "style_update_category"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwUpdateStyleGroupUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "toolbox"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwToolboxUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "toolbox_tool"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwToolboxManagerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "mapzone_config"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwMapzoneConfigUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "massive_composer"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwCompPagesUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "workcat_manager"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwWorkcatManagerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "snapshot_view"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwSnapshotViewUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "profile_interpolation"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwProfileInterpolationUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "scada_graph"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwScadaGraphUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME

# endregion


# region CM
CONTEXT = "cm"

UINAME = "add_lot"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class AddLotUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "lot_management"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class LotManagementUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "resources_management"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class ResourcesManagementUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "team_create"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class TeamCreateUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "add_campaign_review"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class AddCampaignReviewUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "add_campaign_visit"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class AddCampaignVisitUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "add_campaign_inventory"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class AddCampaignInventoryUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "campaign_management"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class CampaignManagementUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "workorder_management"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class WorkorderManagementUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "add_workorder"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class WorkorderAddUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "check_project_cm"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class CheckProjectCmUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME

# endregion

# region TOC
# endregion


# region ADMIN
CONTEXT = "admin"

UINAME = "admin_addfields"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAdminFieldsUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "admin_credentials"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwCredentialsUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME

    def __init__(self, class_obj=None, subtag=None):

        super().__init__(class_obj, subtag)
        self.txt_pass.setClearButtonEnabled(True)
        icon_path = os.path.dirname(__file__) + os.sep + '..' + os.sep + '..' + os.sep + 'icons' + os.sep + 'dialogs' + os.sep + '142.png'
        self.action = QAction("show")
        if os.path.exists(icon_path):
            icon = QIcon(icon_path)
            self.action = QAction(icon, "show")
        self.txt_pass.addAction(self.action, QLineEdit.ActionPosition.TrailingPosition)

    def show_pass(self):

        icon_path = ""
        text = ""
        if self.txt_pass.echoMode() == 0:
            self.txt_pass.setEchoMode(QLineEdit.EchoMode.Password)
            icon_path = os.path.dirname(
                __file__) + os.sep + '..' + os.sep + '..' + os.sep + 'icons' + os.sep + 'dialogs' + os.sep + '142.png'
            text = "Show password"
        elif self.txt_pass.echoMode() == 2:
            self.txt_pass.setEchoMode(QLineEdit.EchoMode.Normal)
            icon_path = os.path.dirname(
                __file__) + os.sep + '..' + os.sep + '..' + os.sep + 'icons' + os.sep + 'dialogs' + os.sep + '141.png'
            text = "Hide password"
        if os.path.exists(icon_path):
            icon = QIcon(icon_path)
            self.action.setIcon(icon)
            self.action.setText(text)


UINAME = "admin_dbproject"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAdminDbProjectUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "admin_translation"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAdminTranslationUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME

    def __init__(self, class_obj=None, subtag=None):

        super().__init__(class_obj, subtag)
        self.txt_pass.setClearButtonEnabled(True)
        icon_path = os.path.dirname(__file__) + os.sep + '..' + os.sep + '..' + os.sep + 'icons' + os.sep + 'dialogs' + os.sep + '142.png'
        self.action = QAction("show")
        if os.path.exists(icon_path):
            icon = QIcon(icon_path)
            self.action = QAction(icon, "show")
        self.action.triggered.connect(self.show_pass)
        self.txt_pass.addAction(self.action, QLineEdit.ActionPosition.TrailingPosition)

    def show_pass(self):

        icon_path = ""
        text = ""
        if self.txt_pass.echoMode() == 0:
            self.txt_pass.setEchoMode(QLineEdit.EchoMode.Password)
            icon_path = os.path.dirname(__file__) + os.sep + '..' + os.sep + '..' + os.sep + 'icons' + os.sep + 'dialogs' + os.sep + '142.png'
            text = "Show password"
        elif self.txt_pass.echoMode() == 2:
            self.txt_pass.setEchoMode(QLineEdit.EchoMode.Normal)
            icon_path = os.path.dirname(__file__) + os.sep + '..' + os.sep + '..' + os.sep + 'icons' + os.sep + 'dialogs' + os.sep + '141.png'
            text = "Hide password"
        if os.path.exists(icon_path):
            icon = QIcon(icon_path)
            self.action.setIcon(icon)
            self.action.setText(text)


UINAME = "admin_markdown_generator"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAdminMarkdownGeneratorUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "admin_i18n_hot_update"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAdminI18NHotUpdateUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "admin_i18n_languages"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwI18NManageLanguagesUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "admin_i18n_manager"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwSchemaI18NManagerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME

    def __init__(self, class_obj=None, subtag=None):
        super().__init__(class_obj, subtag)
        self.txt_pass.setClearButtonEnabled(True)
        icon_path = os.path.dirname(__file__) + os.sep + '..' + os.sep + '..' + os.sep + 'icons' + os.sep + 'dialogs' + os.sep + '142.png'
        self.action = QAction("show")
        if os.path.exists(icon_path):
            icon = QIcon(icon_path)
            self.action = QAction(icon, "show")
        self.action.triggered.connect(self.show_pass)
        self.txt_pass.addAction(self.action, QLineEdit.ActionPosition.TrailingPosition)

    def show_pass(self):
        icon_path = ""
        text = ""
        if self.txt_pass.echoMode() == 0:
            self.txt_pass.setEchoMode(QLineEdit.EchoMode.Password)
            icon_path = os.path.dirname(__file__) + os.sep + '..' + os.sep + '..' + os.sep + 'icons' + os.sep + 'dialogs' + os.sep + '142.png'
            text = "Show password"
        elif self.txt_pass.echoMode() == 2:
            self.txt_pass.setEchoMode(QLineEdit.EchoMode.Normal)
            icon_path = os.path.dirname(__file__) + os.sep + '..' + os.sep + '..' + os.sep + 'icons' + os.sep + 'dialogs' + os.sep + '141.png'
            text = "Hide password"
        if os.path.exists(icon_path):
            icon = QIcon(icon_path)
            self.action.setIcon(icon)
            self.action.setText(text)


UINAME = "admin_import_osm"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAdminImportOsmUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "admin_gisproject"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAdminGisProjectUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "admin_projectinfo"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAdminProjectInfoUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "admin_renameproj"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAdminRenameProjUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "admin"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAdminUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME
    dlg_closed = QtCore.pyqtSignal()


UINAME = "admin_visitclass"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAdminVisitClassUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "admin_visitparam"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAdminVisitParamUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "admin_cm_create"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAdminCmCreateUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "admin_manage_schemas"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAdminManageSchemasUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME

# endregion


# region Menu
CONTEXT = "menu"

UINAME = "load_menu"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwLoadMenuUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME
# endregion


# region SHARED
CONTEXT = "shared"

UINAME = "dscenario"
FROM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwDscenarioUi(GwDialog, FROM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "visit_event_full"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwVisitEventFullUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "visit_gallery"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwGalleryUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "visit_gallery_zoom"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwGalleryZoomUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


class GwDialogShowInfoUi(DialogTextUi):
    def __init__(self, class_obj=None, subtag=None):
        icon_folder = f"{lib_vars.plugin_dir}{os.sep}icons"
        icon_path = f"{icon_folder}{os.sep}dialogs{os.sep}136.png"
        giswater_icon = QIcon(icon_path)
        super().__init__(icon=giswater_icon)


UINAME = "info_catalog"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwInfoCatalogUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "audit_manager"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAuditManagerUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "audit"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAuditUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "info_generic"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwInfoGenericUi(GwMainWindow, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "info_workcat"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwInfoWorkcatUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "selector"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwSelectorUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "visit"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwVisitUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "visit_document"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwVisitDocumentUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "visit_event_rehab"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwVisitEventRehabUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "visit_event"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwVisitEventUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "visit_manager"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwVisitManagerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "interpolate"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwInterpolate(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "replace_in_file"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwReplaceInFileUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


# endregion

# region am
CONTEXT = "am"

UINAME = "result_selector"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwResultSelectorUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "assignation"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwAssignationUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "priority"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwPriorityUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME
    # def closeEvent(self, event):
    #     if self.executing:
    #         event.ignore()
    #     else:
    #         event.accept()


UINAME = "priority_manager"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwPriorityManagerUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME


UINAME = "status_selector"
FORM_CLASS = _get_ui_class(f'{UINAME}.ui', f'{CONTEXT}')


class GwStatusSelectorUi(GwDialog, FORM_CLASS):
    CONTEXT = CONTEXT
    UINAME = UINAME
# endregion
