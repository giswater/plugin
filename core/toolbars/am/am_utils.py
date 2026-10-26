"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

from ....libs import tools_db
from ...utils import tools_gw

# 4.18 renamed inventory views to v_ext_* and editable inputs to ve_asset_*.
# Integration SQL still creates the old names, and a second parent link used to
# replay that rename on views the first parent had just created.
_VIEW_RENAMES = {
    "ext_ws_arc_asset": "v_ext_ws_arc_asset",
    "ext_ws_node_asset": "v_ext_ws_node_asset",
    "ext_ws_link_asset": "v_ext_ws_link_asset",
    "ext_ud_arc_asset": "v_ext_ud_arc_asset",
    "ext_ud_node_asset": "v_ext_ud_node_asset",
    "v_asset_ws_arc_input": "ve_asset_ws_arc_input",
    "v_asset_ws_node_input": "ve_asset_ws_node_input",
    "v_asset_ws_link_input": "ve_asset_ws_link_input",
    "v_asset_ud_arc_input": "ve_asset_ud_arc_input",
    "v_asset_ud_node_input": "ve_asset_ud_node_input",
}
_relation_cache = {}


def preload_am_relations():
    """Resolve renamed AM views once, on the main thread, before a QgsTask runs."""
    if _relation_cache.get("__loaded__") or tools_db.dao is None:
        return
    for logical, renamed in _VIEW_RENAMES.items():
        physical = renamed if tools_db.check_view(renamed, "am") else logical
        _relation_cache[logical] = physical
        _relation_cache[renamed] = physical
    _relation_cache["__loaded__"] = True


def am_relation(name):
    """Physical AM view. Prefers the 4.18 name when that view exists."""
    if not _relation_cache.get("__loaded__"):
        preload_am_relations()
    return _relation_cache.get(name, name)


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
    ext = am_relation(f"ext_{prefix}_{key}_asset")
    v_input = am_relation(f"v_asset_{prefix}_{key}_input")
    return {
        "ext": ext,
        "input": f"{prefix}_{key}_input",
        "engine_wm": f"{prefix}_{key}_engine_wm",
        "engine_sh": "ws_arc_engine_sh" if prefix == "ws" and key == "arc" else None,
        "output": f"{prefix}_{key}_output",
        "v_input": v_input,
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
