# Catalogs

Reference tables with predefined values. Every `*cat_id` and `*_type` column on a feature is a foreign key into one of these, which is how Giswater keeps attribute data consistent: a value that is not in the catalog cannot be entered.

There are two tiers, and conflating them is the most common mistake here.

## Tier 1: the feature-type registry

Answers *what kind of thing is this*, and drives the UI and the topology.

```
cat_feature                      one row per feature type
  id                             the feature type: 'PIPE', 'VARC', 'HYDRANT', 'CHECK_VALVE'
  feature_type                   which trunk table: NODE | ARC | CONNEC | GULLY | ELEMENT | LINK
  feature_class                  which man_ table, looked up in sys_feature_class.man_table
                                 VARC is feature_type ARC, same as PIPE; VCONNEC, VLINK, ud VGULLY likewise
  parent_layer / child_layer     've_node' / 've_node_check_valve'
  shortcut_key                   keyboard shortcut for the insert tool
  active, code_autofill, custom_code_autofill, addparam, abbreviation,
  descript, link_path, inventory_vdefault

cat_feature_node                 the NODE-specific half of the registry, id -> cat_feature.id
  epa_default, num_arcs, isarcdivide, graph_delimiter (text[]),
  choose_hemisphere, isprofilesurface, double_geom
  ud also: isexitupperintro                                       [ud 4.17]
cat_feature_arc                  epa_default
cat_feature_connec               epa_default, double_geom
cat_feature_gully                epa_default, double_geom         (ud)
cat_feature_link                 epa_default (and link-specific flags)
cat_feature_element              epa_default (GENELEM / FRELEM live here)

sys_feature_class                the closed list of legal feature_class values
                                 (id, type, epa_default, man_table)
sys_feature_type                 ARC | CONNEC | ELEMENT | LINK | NODE  (ud adds GULLY)
sys_feature_epa_type             (id, feature_type, epa_table, descript, active)
                                 maps each epa_type to its inp_* table
```

Note the renames if you are reading `schema_model/`: `cat_feature.system_id` became `feature_class` and `sys_feature_cat` became `sys_feature_class` in `common/updates/4/0/0/patch.sql`; `config` became `addparam` in `3/6/11`; `abrevation` became `abbreviation` in `4/17/0`; `parent_layer` `v_edit_*` became `ve_*` in `4/2/0`.

The columns that change behaviour rather than description:

- `epa_default` — the `epa_type` a new feature of this type gets. CHECK-constrained to the same domain as the trunk table's `epa_type`. The registry `sys_feature_epa_type` maps each value to its `inp_*` table.
- `isarcdivide` — whether inserting this node type splits the arc beneath it.
- `num_arcs` — how many arcs may meet at this node type.
- `graph_delimiter` — **text[]**, not a scalar. Values seen live: `{NONE}`, `{MINSECTOR}`, `{PRESSZONE}`, `{DQA}`, `{DMA}`, `{SECTOR}`, and combinations such as `{SECTOR,DMA,PRESSZONE}`. Which mapzone boundaries this node type closes. See [mapzones.md](mapzones.md).
- `double_geom` — `{"activated":false,"value":1}`, enables the paired polygon.

## Tier 2: the physical catalogs

Answers *which exact product is installed*. Target of `nodecat_id`, `arccat_id`, `conneccat_id`, `elementcat_id`, `gullycat_id`, `linkcat_id`.

```
cat_node      id, node_type -> cat_feature_node, matcat_id, pnom, dnom, dint, dext,
              shape, brand_id, model_id, svg, estimated_depth, cost, cost_unit, acoeff,
              ischange, code, active, label          (ud: geom1..geom3, estimated_y; no pnom/dnom)
cat_arc       id, arc_type -> cat_feature_arc, matcat_id, pnom, dnom, dint, dext, shape,
              z1, z2, width, area, estimated_depth, cost, m2bottom_cost, m3protec_cost,
              connect_cost, acoeff, brand_id, model_id
              (ud: geom1..geom8, tsect_id, curve_id instead of pnom/dnom)
cat_connec    id, connec_type -> cat_feature_connec, matcat_id, ...
cat_element   id, element_type -> cat_feature_element, matcat_id, geometry, geom1, geom2,
              isdoublegeom, brand, model, type, svg, code, active
cat_gully     id, gully_type -> cat_feature_gully, matcat_id, length, width, ymax,
              efficiency, ...                                            (ud)
cat_link      id, link_type -> cat_feature_link, matcat_id, pnom, dnom, dint, dext, cost, ...
```

**This is where the two tiers connect, and it differs between project types.** Both now use `cat_node.node_type` / `cat_arc.arc_type` / `cat_connec.connec_type` (the old `nodetype_id` / `arctype_id` / `connectype_id` names are gone). Both trunks carry `feature_type` (NODE/ARC/...). The remaining difference:

```
ws:  node has no node_type column.
     node.nodecat_id -> cat_node.node_type -> cat_feature_node.id -> cat_feature.id
ud:  node.node_type  -> cat_feature_node.id  (direct)
     and also node.nodecat_id -> cat_node, plus node.matcat_id on the trunk row itself
```

If you write a query that reads `node.node_type` it works on ud and fails on ws. In `common/` SQL, resolve the type through the catalog or branch on `sys_version.project_type`.

## Materials and shapes

One material catalog, referenced by every `matcat_id`:

```
cat_material         id, descript, feature_type, featurecat_id, n, link, active, family
cat_mat_roughness    matcat_id, period_id, init_age, end_age, roughness   (ws only)
cat_arc_shape        id, epa, image, descript      the EPA cross-section name
cat_node_shape                                    (ud)
cat_brand            id, descript, featurecat_id
cat_brand_model      id, catbrand_id, featurecat_id
```

`cat_mat_roughness` is the one with logic in it: roughness as a function of material and pipe age, used to age a hydraulic model rather than assume a constant. `gw_fct_admin_transfer_cat_material` migrates material values between the old inline columns and `cat_material`.

## Management catalogs

```
cat_work       id, descript, workid_key1, workid_key2, builtdate, workcost
               target of workcat_id, workcat_id_end, workcat_id_plan
cat_owner      who owns the asset
cat_manager    id, idval, expl_id, sector_id, username
cat_users      id, name, context, sys_role, external
cat_workspace  id, name, config, cur_user, private, iseditable
cat_pavement   thickness, m2_cost           -> plan_arc_x_pavement, arc.pavcat_id
cat_soil       y_param, b, trenchlining, m3exc_cost, m3fill_cost, m2trenchl_cost
```

`cat_pavement` and `cat_soil` carry unit costs, so they feed the psector budget (`plan_price*`), not just the description.

## Modelling catalogs

```
cat_dscenario       id, name, dscenario_type, parent_id, expl_id     demand/loading scenarios
cat_dwf             dry weather flow scenarios                        (ud)
cat_hydrology       hydrology_id, name, infiltration, expl_id         (ud)
ext_cat_period      start_date, end_date, period_seconds, period_type, period_year
ext_cat_hydrometer  hydrometer_type, class, ulmc, voltman_flow, dnom  (interoperability)
```

`ext_cat_period` is the time axis for consumption and water balance, so `ext_` here means "the billing system owns these periods", not "unimportant".

## What must be filled before anything works

An empty project is not usable until the catalogs are populated. Minimum viable set:

1. `cat_material` — materials, because the object catalogs reference them.
2. `cat_node` and `cat_arc` — you cannot insert a node or an arc without one.
3. `cat_connec` (and ud `cat_gully`, `cat_link`) once you digitise connections, gullies or links.

`cat_feature*` ships populated with the standard feature types; a new project loads localised names from `schemas/main/{ws,ud}/catalog/<locale>/cat_feature.sql`, with `en_US` as fallback.

Everything else is optional but constrains data once populated, since the FKs are `ON DELETE RESTRICT`: you cannot delete a catalog row that a feature still points at.

## Functions

| Function | Does |
|---|---|
| `gw_fct_getcatalog` | Returns the filtered catalog list for an insert or a combo, respecting feature type and exploitation |
| `gw_fct_setcatalog` | Upserts a catalog row from the dialog |
| `gw_fct_getcatfeaturevalues` | Feature-type values for the insert dialog |
| `gw_fct_import_catalog`, `gw_fct_import_cat_feature`, `gw_fct_import_cat_period` | CSV imports |
| `gw_fct_admin_transfer_cat_material` | Material migration |
| `gw_fct_getchangefeaturetype` / `gw_fct_setchangefeaturetype` | Move a feature to another feature type, which means moving its row between `man_` tables |

Editing a catalog from QGIS goes through `ve_cat_feature_node`, `ve_cat_feature_arc`, `ve_cat_feature_connec`, `ve_cat_feature_gully`, `ve_cat_feature_element` and `ve_cat_feature_link`. There are no `v_edit_cat_feature_*` views.
