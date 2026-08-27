"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

from ...utils import tools_gw


def get_am_project_type():
    """WS|UD of the loaded parent schema. AM results are scoped to this kind."""
    project_type = (tools_gw.get_project_type() or "ws").strip().upper()
    if project_type not in ("WS", "UD"):
        return "WS"
    return project_type


def am_prefix(project_type=None):
    """ws|ud table prefix for the loaded (or given) parent kind."""
    pt = (project_type or get_am_project_type() or "WS").upper()
    return "ud" if pt == "UD" else "ws"


def am_names(project_type=None, asset_type="ARC"):
    """Work-table / overlay / TOC view names for one AM asset class."""
    at = (asset_type or "ARC").upper()
    prefix = "ws" if at == "LINK" else am_prefix(project_type)
    key = at.lower()
    return {
        "ext": f"ext_{prefix}_{key}_asset",
        "input": f"{prefix}_{key}_input",
        "engine_wm": f"{prefix}_{key}_engine_wm",
        "engine_sh": "ws_arc_engine_sh" if prefix == "ws" and key == "arc" else None,
        "output": f"{prefix}_{key}_output",
        "v_input": f"v_asset_{prefix}_{key}_input",
        "v_output": f"v_asset_{prefix}_{key}_output",
        "v_output_compare": f"v_asset_{prefix}_{key}_output_compare",
        "v_corporate": f"v_asset_{prefix}_{key}_corporate",
    }


def am_selector_layers(project_type=None):
    """Result-selector layers currently loaded for this parent kind."""
    prefix = am_prefix(project_type)
    layers = [
        f"v_asset_{prefix}_arc_output",
        f"v_asset_{prefix}_arc_output_compare",
        f"v_asset_{prefix}_node_output",
        f"v_asset_{prefix}_node_output_compare",
        f"v_asset_{prefix}_arc_corporate",
        f"v_asset_{prefix}_node_corporate",
    ]
    if prefix == "ws":
        layers.extend(
            (
                "v_asset_ws_link_output",
                "v_asset_ws_link_output_compare",
                "v_asset_ws_link_corporate",
            )
        )
    return layers
