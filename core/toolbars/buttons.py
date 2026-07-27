"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# flake8: noqa: F401
# -*- coding: utf-8 -*-

# Basic: 01, 02
from .basic.info_btn import GwInfoButton  # noqa: F401
from .basic.selector_btn import GwSelectorButton  # noqa: F401

# Om: 11, 12, 13, 14, 15, 16, 17, 18
from .om.mincut_btn import GwMincutButton  # noqa: F401
from .om.mincut_manager_btn import GwMincutManagerButton  # noqa: F401
from .om.flow_trace_btn import GwFlowTraceButton  # noqa: F401
from .om.flow_exit_btn import GwFlowExitButton  # noqa: F401
from .om.profile_btn import GwProfileButton  # noqa: F401
from .om.visit_btn import GwVisitButton  # noqa: F401
from .om.visit_manager_btn import GwVisitManagerButton  # noqa: F401
from .om.date_selector_btn import GwDateSelectorButton  # noqa: F401

# Edit: 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36
from .edit.point_add_btn import GwPointAddButton  # noqa: F401
from .edit.arc_add_btn import GwArcAddButton  # noqa: F401
from .edit.arc_divide_btn import GwArcDivideButton  # noqa: F401
from .edit.arc_fusion_btn import GwArcFusionButton  # noqa: F401
from .edit.featuretype_change_btn import GwFeatureTypeChangeButton  # noqa: F401
from .edit.feature_replace_btn import GwFeatureReplaceButton  # noqa: F401
from .edit.connect_link_btn import GwConnectLinkButton  # noqa: F401
from .edit.feature_end_btn import GwFeatureEndButton  # noqa: F401
from .edit.feature_delete_btn import GwFeatureDeleteButton  # noqa: F401
from .edit.dimensioning_btn import GwDimensioningButton  # noqa: F401
from .edit.document_btn import GwDocumentButton  # noqa: F401
from .edit.document_manager_btn import GwDocumentManagerButton  # noqa: F401
from .edit.element_btn import GwElementButton  # noqa: F401
from .edit.element_manager_btn import GwElementManagerButton  # noqa: F401
from .edit.aux_circle_add_btn import GwAuxCircleAddButton  # noqa: F401
from .edit.aux_point_add_btn import GwAuxPointAddButton  # noqa: F401

# Epa: 41, 42, 43, 44, 45, 46
from .epa.nonvisual_manager_btn import GwNonVisualManagerButton  # noqa: F401
from .epa.go2epa_btn import GwGo2EpaButton  # noqa: F401
from .epa.go2epa_manager_btn import GwGo2EpaManagerButton  # noqa: F401
from .epa.go2epa_selector_btn import GwGo2EpaSelectorButton  # noqa: F401
from .epa.dscenario_manager_btn import GwDscenarioManagerButton  # noqa: F401
from .epa.epa_tools_btn import GwEpaTools  # noqa: F401

# Plan: 51, 52, 53
from .plan.psector_btn import GwPsectorButton  # noqa: F401
from .plan.psector_manager_btn import GwPsectorManagerButton  # noqa: F401
from .plan.netscenario_manager_btn import GwNetscenarioManagerButton  # noqa: F401

# Utilities: 61, 62, 63, 64, 65, 66, 67, 68, 69
from .utilities.utils_manager_btn import GwUtilsManagerButton  # noqa: F401
from .utilities.config_btn import GwConfigButton  # noqa: F401
from .utilities.toolbox_btn import GwToolBoxButton  # noqa: F401
from .utilities.utilities_manager.workspace_manager import GwWorkspaceManagerButton  # noqa: F401
from .utilities.print_btn import GwPrintButton  # noqa: F401
from .utilities.file_transfer_btn import GwFileTransferButton  # noqa: F401
from .utilities.project_check_btn import GwProjectCheckButton  # noqa: F401
from .utilities.network_utilities import GwNetworkUtilitiesButton  # noqa: F401
from .utilities.snapshot_view import GwSnapshotViewButton  # noqa: F401

# ToC: 71, 72
from .toc.add_child_layer_btn import GwAddChildLayerButton  # noqa: F401
from .toc.layerstyle_change_btn import GwLayerStyleChangeButton  # noqa: F401

# am: 80, 81, 82, 83
from .am.breakage_btn import GwAmBreakageButton  # noqa: F401
from .am.priority_btn import GwAmPriorityButton  # noqa: F401
from .am.result_manager_btn import GwResultManagerButton  # noqa: F401
from .am.result_selector_btn import GwResultSelectorButton  # noqa: F401

# cm 84, 85, 86, 87, 88, 89
from .cm.add_campaign_btn import GwAddCampaignButton  # noqa: F401
from .cm.manager_campaign_lot_btn import GwManageCampaignLotButton  # noqa: F401
from .cm.add_lot_btn import GwAddLotButton  # noqa: F401
from .cm.resources_lot_btn import GwLotResourceManagementButton  # noqa: F401
from .cm.selector_campaign_btn import GwSelectorCampaignButton  # noqa: F401
from .cm.check_cm_project_btn import GwCheckCMProjectButton  # noqa: F401

