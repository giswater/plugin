# Inventory: the trunk features

The asset register. Everything else in the schema hangs off these tables.

## The features

| Table | Geometry | What it is |
|---|---|---|
| `node` | Point | Every point element of the network: valves, hydrants, junctions, tanks, manholes, outfalls. **Digitise nodes first** |
| `arc` | LineString | Every conduit. **Must run between two nodes**, and a node splits the arcs it sits on |
| `connec` | Point | Service connections: the link between the network and a building or fountain. Not on the network itself |
| `gully` | Point | ud only. Gullies / inlets, off to the side of the network |
| `link` | LineString | The graphical tie from a `connec` or `gully` to the network |
| `element` | Point | Objects not on the network. Two classes: `GENELEM` → `man_genelem`, `FRELEM` → `man_frelem` (flow regulators, they do have `epa_type`) |
| `polygon` | MultiPolygon | The polygon half of a double-geometry feature |

## Parent, child, and view

The pattern that explains most of the schema. A hydrant is three objects:

```
node                     the trunk row. Every column shared by all node types
man_hydrant              only what a hydrant has: fire_code, valve, communication, geom1, geom2
ve_node_hydrant          the editable view joining the two, for the hydrant form and layer
```

`cat_feature` is the registry that wires it together. One row per feature type. Live ws 4.18:

```sql
-- cat_feature: id, feature_class, feature_type, parent_layer, child_layer
('CHECK_VALVE',    'VALVE',    'NODE',    've_node',    've_node_check_valve')
('PIPE',           'PIPE',     'ARC',     've_arc',     've_arc_pipe')
('VARC',           'VARC',     'ARC',     've_arc',     've_arc_varc')
('WJOIN',          'WJOIN',    'CONNEC',  've_connec',  've_connec_wjoin')
('PIPELINK',       'PIPELINK', 'LINK',    've_link',    've_link_pipelink')
('VLINK',          'VLINK',    'LINK',    've_link',    've_link_vlink')
('ECOVER',         'GENELEM',  'ELEMENT', 've_element', 've_element_ecover')
('EPUMP',          'FRELEM',   'ELEMENT', 've_element', 've_element_epump')
```

Three names, do not mix them:

| Column | What it is | Example |
|---|---|---|
| `cat_feature.id` | Feature type (what the user picks) | `CHECK_VALVE`, `PIPE`, `VARC` |
| `cat_feature.feature_type` | Which trunk table | `NODE`, `ARC`, `CONNEC`, `LINK`, `ELEMENT` (ud: `GULLY`) |
| `cat_feature.feature_class` | Which `man_*` table, via **`sys_feature_class.man_table`** | `VALVE` → `man_valve`, `GENELEM` → `man_genelem` |

Not `'man_' || lower(feature_class)` — ELEMENT is why: every cover/step is `GENELEM` → `man_genelem`, every pump/valve/meter element is `FRELEM` → `man_frelem`. Many feature types share one `man_` table (every valve subtype stores columns in `man_valve`). `sys_feature_class` is the closed list (`id, type, epa_default, man_table`). `sys_feature_type` is `ARC | CONNEC | ELEMENT | LINK | NODE` (ud adds `GULLY`).

**Virtual feature types are the same pattern.** `VARC` is `feature_type = ARC`, same as `PIPE`: row in `arc`, child `man_varc`, view `ve_arc_varc`. Domain meaning: topological filler where no physical pipe exists (across a tank, through a polygon). Same for `VCONNEC`, `VLINK`, and ud `VGULLY`. They are catalog rows, not extra tables.

The one that is *not* a feature type is **vnode**: the point where a link meets a pipe, materialised only during export/analysis (`temp_node`). No `vnode` table, not in `cat_feature`, not in `sys_feature_type`.

`child_layer` is authoritative for the view name; `gw_fct_admin_manage_child_views` generates the view from it. Never hand-write a `ve_*` view. `parent_layer` is the parent editing view (`ve_node`, `ve_arc`, ...), which is also the QGIS layer.

Careful with a near-collision: `man_valve` is the base child table, while `man_node_check_valve` (pattern `man_<featuretype>_<catfeature>`) is an *addfields* table created on demand for user-defined columns. Different mechanisms, similar names.

## User-defined columns

Clients add fields without a schema patch:

- `sys_addfields` — the definition: `param_name`, `cat_feature_id`, `datatype_id`, `is_mandatory`, `iseditable`, `orderby`, `active`, and `feature_type` which is `ALL`, `NODE`, `ARC`, `CONNEC`, `GULLY`, `LINK` or `CHILD`.
- There is **no** `man_addfields_value` EAV table. Values live as real columns on the per-type addfields table `man_<featuretype>_<catfeature>`, created by `gw_fct_admin_manage_addfields`, which also registers the column in `config_form_fields`. If a form shows a column you cannot find in any DDL, look here first.

## States

Three states, no more ([official reference](https://docs.giswater.org/master/en/docs/giswater/for-users/user-manual/data-model-giswater.html#topology-of-states)):

```
value_state:  0 OBSOLETE    1 OPERATIVE    2 PLANIFIED
```

`state_type` refines them and is what the functions actually test, because it carries the behavioural flags. Live sample:

```sql
-- value_state_type: id, state, name, is_operative, is_doable
1   0  OBSOLETE           is_operative=false  is_doable=false
2   1  OPERATIVE          true   true
3   2  PLANIFIED          true   true
4   2  RECONSTRUCT        true   false
5   1  PROVISIONAL        false  true
99  2  FICTICIUS          true   false
100 2  OBSOLET-FICTICIUS  true   false
```

So "state 1" is not the same as "operative": a `PROVISIONAL` feature is state 1 with `is_operative = false`. When you filter, filter on the flag, not the number. `gw_fct_state_control` enforces the transitions.

Topological strictness follows state: obsolete features are unconstrained, operative features must be a clean graph, planned features live inside a psector (`plan_psector*`) and may legally overlap the operative network.

## Topology rules

**Arc-node.** Nodes split arcs. `cat_feature_node` controls the detail: `isarcdivide` decides whether inserting this node type breaks the arc under it, `num_arcs` caps how many arcs may meet, `choose_hemisphere` and `isprofilesurface` affect the insert dialog and the profile tool. Moving a node drags the arcs attached to it. The relevant functions are `gw_fct_setarcdivide`, `gw_fct_setarcfusion`, `gw_fct_setarcreverse`, `gw_fct_settopology`, `gw_fct_checknode`.

**Link-network.** A `link` has an input feature (`feature_id`, `feature_type` — the connec or gully) and an output feature (`exit_id`, `exit_type` — an arc, node, connec or gully). Direction matters:

- Upstream, the link *belongs to* its input feature: it takes exploitation and state from it, dies with it, and its length/diameter/material are attributes of the input feature, not of the link.
- Downstream, there is only topology: the link writes the arc it lands on into the input feature's `arc_id`. Move the end vertex to another pipe and that `arc_id` changes.

A new connec or gully starts unconnected. Connect via `gw_fct_linktonetwork` / `gw_fct_setlinktonetwork`, by drawing the link, or automatically through configuration. Repairs: `gw_fct_link_repair`, `gw_fct_connect_link_refactor`, `gw_fct_linkexitgenerator`.

**Double geometry.** Some feature types get a point *and* a polygon in `polygon` (`pol_id`, `feature_id`, `featurecat_id`, `sys_type`). Enabled per feature type by `cat_feature_{node,connec,gully}.double_geom`, a json `{"activated":false,"value":1}`. The polygon moves with the point, is replaced if you redraw it, cannot exist without a point inside it, and is deleted with the point. Officially: ws Tank, Register, Fountain; ud Storage, Chamber, Wwtp, Netgully, Gully.

## Management and traceability columns

The lifecycle of an asset is recorded on the trunk row itself:

- `workcat_id` -> `cat_work`, the work order that installed it. `workcat_id_end` the one that removed it, `workcat_id_plan` the planned one.
- `builtdate` / `enddate`, `ownercat_id` -> `cat_owner`.
- `verified`, `publish`, `inventory` — publication guards. Deletion is gated by `lock_level` (integer, domain in `edit_typevalue` / `value_lock_level`).
- `om_state`, `conserv_state` — operational / conservation state, string, independent of `state`.
- `asset_id`, `uuid`, `sys_code` — extra identifiers. `uuid` is a real uuid column.
- `dataquality` (integer), `dataquality_obs` (text[]), `uncertain`, `datasource` — data-quality flags.
- `expl_visibility integer[]` — extra exploitations that may see the feature. Replaces the old `expl_id2`.
- `is_scadamap` — whether the feature is published to a SCADA map.
- `function_type`, `category_type`, `fluid_type`, `location_type` — soft classification, each a **composite** FK to `man_type_function` / `man_type_category` / `man_type_fluid` / `man_type_location` on `(<type>, feature_type)`. That composite is why a value valid for a node is rejected on an arc.

`gw_fct_setendfeature` retires a feature; `gw_fct_setfeaturereplace` swaps one for another and keeps the history; `gw_fct_setdelete` / `gw_fct_setfeaturedelete` and `gw_fct_getcheckdelete` handle removal with its dependency check.

## Bridges

Uniform `<a>_x_<b>` shape, always with an `id` surrogate key:

```
doc_x_node, doc_x_arc, doc_x_connec, doc_x_gully, doc_x_link, doc_x_element,
doc_x_psector, doc_x_visit, doc_x_workcat
element_x_node, element_x_arc, element_x_connec, element_x_gully, element_x_link
om_visit_x_node, om_visit_x_arc, om_visit_x_connec, om_visit_x_gully, om_visit_x_link   (+ is_last)
plan_psector_x_node, plan_psector_x_arc, plan_psector_x_connec, plan_psector_x_gully
node_x_municipality_visibility, node_x_sector_visibility
element_x_municipality_visibility, element_x_sector_visibility
```

The matching `v_ui_*` view is what the info form's tab actually reads: `v_ui_element_x_node`, `v_ui_doc_x_node`, `v_ui_om_visit_x_node`.

## Analysis, review and audit

Three families that look similar and are not.

**`anl_*`** — output of the check and analysis functions (`anl_node`, `anl_arc`, `anl_connec`, `anl_gully`, `anl_polygon`, `anl_arc_x_node`, `anl_graphinundation`). Scoped by `fid` (the function id) and `cur_user`, rewritten on every run, and consumed by the toolbox result layers. Never treat as state. Producers include `gw_fct_anl_node_duplicated`, `gw_fct_anl_arc_no_startend_node`, `gw_fct_anl_node_orphan`, `gw_fct_anl_node_proximity`, plus the `*_gw_fct_anl_*` set per project type.

**`review_*`** — a staging area for field-collected or imported data awaiting validation: `review_node`, `review_arc`, `review_connec`, `review_gully` carry the proposed values plus `is_validated`, `field_checked`, `field_date`, `review_obs`. `review_audit_*` holds the old/new pairs for each reviewed column. Editable as `ve_review_*`.

**`audit_*`** — history and diagnostics. `audit_log_data` for row changes, `audit_arc_traceability` for the split/fuse chain of an arc, `audit_check_data` and `audit_check_project` for the results of `gw_fct_audit_schema_check` and `gw_fct_setcheckproject`, `audit_fid_log` for per-process log lines. `audit_check_data` is also the general-purpose log every admin function writes progress messages into, which makes it the first place to look when a build or a toolbox process failed.

Psector archival is the `archived` flag on `plan_psector_x_*` plus `plan_psector.status`, not a separate traceability table.

**`*_add`** — `node_add`, `arc_add`, `connec_add` (ws), `element_add` (ws) cache aggregated simulation results (min/max/avg pressure, demand, flow, velocity) per feature and `result_id`, so styling does not need to join `rpt_*`.

**`archived_rpt_*`** — copies of `rpt_*` after a result is archived. ws has `archived_rpt_arc`, `archived_rpt_node`, `archived_rpt_inp_*`, `archived_rpt_*_stats`, `archived_rpt_energy_usage`, `archived_rpt_hydraulic_status`.
