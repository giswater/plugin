# Mapzones

Polygonal areas that partition the network for management. Every trunk feature carries a foreign key to each mapzone it falls in, so a mapzone is both a geometry and an attribute. They can be drawn by hand or, more usually, computed from the graph.

The source of truth for *which* zones exist in a schema is `config_mapzones` (`id, abbreviation, descript, fid, code_autofill, active, is_dynamic, custom_code_autofill`). `is_dynamic` is whether `gw_fct_graphanalytics_mapzones` may rewrite the zone; `fid` is the process id that owns the trace.

Live rows:

| id | ws | ud | is_dynamic | fid |
|---|---|---|---|---|
| SECTOR / MACROSECTOR | yes | yes | true | 130 / — |
| DMA / MACRODMA | yes | yes | true | 145 / — |
| DQA / MACRODQA | yes | — | true | 144 / — |
| PRESSZONE | yes | — | true | 146 |
| SUPPLYZONE | yes | — | true | 712 |
| OMZONE / MACROOMZONE | yes | yes | true | — |
| CRMZONE / MACROCRMZONE | yes (inactive in sample) | — | false | — |
| DRAINZONE | — | yes | false | 481 |
| DWFZONE | — | yes | true | 481 |

`exploitation` / `macroexploitation` and the administrative `ext_*` tables are **not** in `config_mapzones`. They are management / cartographic entities, not computed graph zones.

## What each one means

The [map-zones page](https://docs.giswater.org/master/en/docs/giswater/for-users/map-zones/zonas-mapa.html) is the official grouping (administrative / operational / commercial / functional). Several of its entries are empty stubs; the live tables are:

- **`exploitation`** — the top-level scope. Almost everything is filtered by `expl_id`, permissions are granted per exploitation (`config_user_x_expl`), and `selector_expl` decides what a user sees. Parent: `macroexploitation` (no geometry of its own). Mandatory; a default row ships with the schema.
- **`sector` / `macrosector`** — the operational division. Visibility: `selector_sector` / `selector_macrosector`.
- **`dma` / `macrodma`** — district metered area, the unit of water balance. Carries `minc`, `maxc`, `effc`, `avg_press`, `pattern_id`. Feeds `om_waterbalance`. Header is a meter; bounded by closed meters/valves.
- **`presszone`** — pressure zone, with `head`. Text primary key (`presszone_id varchar`), unlike the integer-keyed zones.
- **`dqa` / `macrodqa`** — district quality area, sectioned by sampling and quality sensors.
- **`supplyzone`** — supply zone (ws). Own table, `supplyzone_id` on the trunk. Has `graphconfig`, `pattern_id`, `avg_press`, `parent_id`.
- **`omzone` / `macroomzone`** — operations-and-maintenance zone, both project types. `omzone_id` on the trunk.
- **`omunit` / `macroomunit`** — ud only. Linear OM unit between `node_1` and `node_2`, not a polygon. `omunit_id` on ud trunks. [ud 4.17]
- **`minsector` / `macrominsector`** — the smallest isolatable piece of network, bounded by valves. Not user-drawn: computed, and it caches `num_border`, `num_connec`, `num_hydro`, `length`. Underpins mincut (`om_mincut*`). Not a `config_mapzones` row; computed by `ws_gw_fct_graphanalytics_minsector`.
- **`drainzone`** — ud drainage catchment, everything upstream of one or more outfall nodes. **Not assigned via a `drainzone_id` column on the trunk.** The trunk stores `drainzone_outfall`; `drainzone_id` is computed on `ve_*`. `is_dynamic = false`. [ud 4.17]
- **`dwfzone`** — ud dry-weather-flow zone. Trunk has both `dwfzone_id` and `dwfzone_outfall`. Child of `drainzone_id` on the zone table itself. [ud 4.17]
- **`crmzone` / `macrocrmzone`** — commercial zone, ws, joined from `connec.crmzone_id`. Inactive in the sample (`config_mapzones.active = false`).

Administrative cartography lives in the `ext_` family, not as Giswater mapzones:

```
ext_region, ext_province, ext_region_x_province, ext_municipality, ext_district
```

`muni_id` on a feature → `ext_municipality`. `district_id` → `ext_district JOIN ext_municipality USING (muni_id)`. Selectors: `selector_municipality`.

Trunk columns, so you know what you may join:

```
all:      expl_id, expl_visibility integer[], sector_id, dma_id, omzone_id, minsector_id, muni_id, district_id
ws only:  presszone_id, dqa_id, supplyzone_id ; connec also crmzone_id
ud only:  dwfzone_id, omunit_id, drainzone_outfall, dwfzone_outfall
          (drainzone_id is on ve_*, not on node/arc/connec/gully)
```

`expl_visibility integer[]` is how a feature on a boundary is visible in more than one exploitation.

## Automatic calculation

The point of mapzones in Giswater is that you compute them by tracing the graph from a head node, rather than drawing polygons. Configuration lives in three places.

**1. `graphconfig` on the zone table.** Every dynamic zone table (`sector`, `dma`, `dqa`, `presszone`, `supplyzone`, `omzone`, `drainzone`, `dwfzone`) has a json column:

```json
{"use": [{"nodeParent": "<header node id>", "toArc": ["<arc leaving the header>"]}],
 "ignore": [],
 "forceClosed": ["<node forced closed, used as a stopper when there is no valve>"]}
```

`nodeParent` is the header (one or several nodes); `toArc` is the flow direction out of the header; `ignore` prunes nodes from the trace; `forceClosed` treats a node as a closed valve.

**2. `cat_feature_node.graph_delimiter`.** **text[]**, not a scalar. Values seen live: `{NONE}`, `{MINSECTOR}`, `{PRESSZONE}`, `{DQA}`, `{DMA}`, `{SECTOR}`, and combinations such as `{SECTOR,DMA,PRESSZONE}`. A tank set to `{SECTOR}` terminates a sector trace. Closing valves for mincut must have `{MINSECTOR}`.

**3. `config_graph_*` (ws).** `config_graph_mincut` (`node_id, parameters, active`) — supply nodes for mincut; high-network arcs are tagged in `parameters` as `inletArc`. `config_graph_checkvalve` (`node_id`, `to_arc`).

Then run it:

```sql
SELECT gw_fct_graphanalytics_mapzones('{"data":{"parameters":{
  "graphClass":"PRESSZONE", "exploitation":[1,2], "commitChanges":true,
  "updateMapZone":2, "geomParamUpdate":15, "usePlanPsector":false}}}');
```

`graphClass` picks the zone: `SECTOR`, `DMA`, `DQA`, `PRESSZONE`, `SUPPLYZONE`, `OMZONE`, `MINSECTOR`, `DRAINZONE`, `DWFZONE`. `updateMapZone` controls how much gets written, `geomParamUpdate` is the buffer used to rebuild the polygon (`None` / `Concave Polygon` / `Pipe Buffer` / `Plot & Pipe Buffer` / `Link & Pipe Buffer`), `usePlanPsector` includes planned features, `forceOpen`/`forceClosed` override valve status for one run, and `commitChanges: false` gives you a preview.

| Function | Does |
|---|---|
| `gw_fct_graphanalytics_mapzones` | The main trace, one mapzone class at a time |
| `gw_fct_graphanalytics_mapzones_advanced` | Same with extra parameters (`floodOnlyMapzone`, `valueForDisconnected`) |
| `gw_fct_graphanalytics_macromapzones` | Aggregates zones into their `macro*` parent |
| `gw_fct_config_mapzones` | Reads and writes the `graphconfig` from the Mapzone configuration dialog (`configZone`, `action: PREVIEW`, `nodeParent`, `toArc`) |
| `gw_fct_setmapzoneconfig` | Applies a configuration change |
| `gw_fct_graphanalytics_flowtrace` | Upstream/downstream trace, not tied to a zone |
| `ws_gw_fct_graphanalytics_minsector`, `ws_gw_fct_graphanalytics_mapzones_config`, `ws_gw_fct_graphanalytics_mapzones_plan`, `ws_gw_fct_graphanalytics_check_data` | ws specifics |
| `ud_gw_fct_graphanalytics_upstream` / `_downstream` / `_omunit` / `_treatment_type` / `_fluid_type` | ud specifics |
| `gw_fct_graphanalytics_manage_temporary` | Sets up and tears down the `temp_anlgraph` scratch |
| `ws_gw_fct_setmapzonestrigger` | Recomputes zones when a valve is opened or closed |

`minsector_graph` (`node_id`, `node_type`, `minsector_1`, `minsector_2`) is the adjacency between minsectors, the graph the mincut engine walks.

## System variables

All in `config_param_system`:

| Parameter | Effect |
|---|---|
| `utils_graphanalytics_status` | Per-zone on/off switch for dynamic mapzones: `{"DMA": false, "DQA": false, "SECTOR": false, "MINSECTOR": false, "PRESSZONE": false, "checkData": "NONE"}` |
| `utils_graphanalytics_vdefault` | Default `updateMapZone` and `geomParamUpdate` per zone |
| `utils_graphanalytics_automatic_trigger` | Recompute automatically when valve status changes |
| `utils_graphanalytics_automatic_config` | Fill graph configuration from `graph_delimiter` |
| `utils_graphanalytics_style` | `Random`, `Stylesheet` or `Disable` symbology. Forced to `Disable` on new projects by `gw_fct_admin_schema_lastprocess` |
| `utils_graphanalytics_custom_geometry_constructor` | Override the SQL that rebuilds the zone polygon |
| `edit_mapzones_automatic_insert` | Create the mapzone row when a new node names one: `{"SECTOR":false, "DMA":false, ...}` |
| `edit_mapzones_set_lastupdate` | Touch `updated_at` on features the trace rewrites |
| `basic_selector_mapzone_relation` | `{"sectorfromexpl":"false","explfromsector":"false"}` — cascade one selector from another |

## Visibility and styling

A mapzone is also a visibility mechanism. `selector_expl` and `selector_sector` are per-user (`cur_user`) and are what the `ve_*` views filter on, so an empty selector means an empty layer. That is almost always the explanation for "my features disappeared". Also `selector_macroexpl`, `selector_macrosector`, `selector_municipality`, `selector_network`.

Each zone table has a `stylesheet` json used by `gw_fct_getstylemapzones` to colour the network by zone, and `active` to retire a zone without deleting it (the FKs are `ON DELETE RESTRICT`, so you cannot delete one that features still reference). Editing layers: `ve_exploitation`, `ve_sector`, `ve_dma`, `ve_presszone`, `ve_dqa`, `ve_supplyzone`, `ve_omzone`, `ve_minsector`, `ve_drainzone`, `ve_dwfzone`.
