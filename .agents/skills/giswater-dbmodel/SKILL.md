---
name: giswater-dbmodel
description: Explains the meaning of the Giswater PostgreSQL data model - trunk feature tables (node, arc, connec, gully, link), the man_/cat_/sys_/config_/selector_ table families, the ve_/v_ui_ view families, catalogs, mapzones, state topology, and how to look up a table or column reliably. Use when working with any dbmodel table, view or gw_fct_ function, when asked what a table or column is for, where a value comes from, which table to join, or how ws and ud differ.
---

# Giswater dbmodel: what the data means

`dbmodel/AGENTS.md` says where SQL goes. This says what it means.

A ws schema has ~300 tables and ~250 views; ud has ~350 and ~350. Nobody memorises that. What you memorise is the naming system and the ten tables at the centre; everything else you look up. This file is the decoder plus the lookup procedure. Areas in depth:

| Read | For |
|---|---|
| [inventory.md](inventory.md) | Trunk features, `man_*` children, states, workcat, topology rules |
| [catalogs.md](catalogs.md) | `cat_feature*` vs `cat_node`/`cat_arc`, `cat_material`, what must be filled first |
| [mapzones.md](mapzones.md) | `exploitation`, `sector`, `dma`, `presszone`, `dqa`, `supplyzone`, `omzone`, `minsector`, `drainzone`, `dwfzone`, `crmzone` |

These files are a decoder, not a reference. The live schema wins. Worked example: `v_edit_node` was renamed to `ve_node` in `4/2/0` and the back-compat alias dropped in `4/17/0`. Any text that still says `v_edit_node` is stale. Confirm a name against a live schema (Postgres MCP `get_object_details` / `information_schema`) before trusting it.

## The eight blocks

The [official conceptual model](https://docs.giswater.org/master/en/docs/giswater/for-admins/logic-dbmodel/logic-dbmodel.html) splits the schema into functional blocks. Use these names when you talk about the model. Its two figures are swapped (the one captioned WS is UD and vice versa); trust the table list in a live schema over the pictures.

- **Core** — the topological features, their catalogs, and the mapzones. ws: node/arc/connec. ud: node/arc/connec/gully. Hydrology for SWMM lives in `inp_subcatchment`, not a `subcatchment` table.
- **Object-specific data** — the `man_*` child tables, one per feature class.
- **Management and permissions** — roles, users, exploitation grants (`config_user_x_expl`).
- **Documents** — `doc` and its bridges.
- **O&M** — visits, mincut, profiles, water balance, rehabilitation results.
- **Interoperability** — SCADA, CRM, hydrometer links. Present in **both** project types, not ws-only (the official page is wrong on this).
- **Mathematical modeling** — everything feeding EPANET/SWMM and everything coming back.
- **Other** — audit, analysis, review, scratch, archives.

## Prefix decoder

Read a table name and you know its block, its lifetime and whether you may write to it.

| Prefix | Meaning |
|---|---|
| *(none)* | Trunk features and mapzones: `node`, `arc`, `connec`, `gully`, `link`, `polygon`, `element`, `exploitation`, `sector`, `dma`, `presszone`, `dqa`, `minsector`, `drainzone`, `dwfzone`, `supplyzone`, `omzone`, `omunit`, `crmzone`, `macro*` |
| `cat_` | Catalogs. User-maintained reference data, target of every `*cat_id` FK |
| `man_` | Object-specific columns for one feature class. `man_hydrant`, `man_pipe`, `man_genelem` |
| `sys_` | System registries. Structural, not user data. `sys_feature_type`, `sys_feature_class`, `sys_feature_epa_type`, `sys_table`, `sys_addfields`, `sys_version`, `sys_fprocess` |
| `config_` | Behaviour and form configuration. Shipped with defaults, sometimes customised |
| `selector_` | Per-user visibility filters, keyed by `cur_user`. This is why two users see different features in the same layer |
| `value_` | Closed domains: `value_state`, `value_state_type` |
| `inp_` | EPANET/SWMM input data |
| `rpt_` | Simulation results, imported back from the RPT file |
| `archived_` | Archived copies of `rpt_*` (and similar) after `*_gw_fct_set_rpt_archived` |
| `om_` | Operations and maintenance |
| `plan_` | Planning: psectors, prices, reconstruction and rehabilitation results, netscenarios |
| `anl_` | Output of analysis and check functions. Rewritten on every run |
| `review_` | Staging and review queues for imported or edited features |
| `audit_` | Audit trails: `audit_log_data`, `audit_arc_traceability`, `audit_check_data`, `audit_fid_log` |
| `ext_` | Data owned by an external system: addresses, municipalities, hydrometers, rasters, SCADA |
| `crm_`, `rtc_` | Commercial and real-time interoperability |
| `temp_` | Per-process scratch. Contents are meaningless between runs; never read as state |
| `doc_x_*`, `element_x_*`, `om_visit_x_*` | N:M bridges, named `<a>_x_<b>` |
| `_leading_underscore` | **Deprecated.** `gw_fct_admin_schema_lastprocess` drops every `_`-prefixed table and a hardcoded list of `_` columns when a new project is built. Never write to one; never resurrect one. Live evidence: ud still has `_fluid_type`, `_connec_arccat_id`, `_pol_id_` on some trunks |

## View decoder

Views are not a convenience layer here, they are the API. QGIS almost never loads a table directly.

`v_edit_*` is gone. It was renamed to `ve_*` in `4/2/0` (`ALTER VIEW v_edit_node RENAME TO ve_node`, plus a DML pass over `sys_table`, `sys_style`, `cat_feature.parent_layer` and `config_form_fields.formname`). The last back-compat alias `v_edit_arc` was dropped in `4/17/0`. A live 4.18 schema keeps a single leftover: `v_edit_typevalue`. Persistent `vi_*` INP-section views were dropped in `4/0/0`. There is no `v_state_*` family.

| Pattern | Purpose |
|---|---|
| `ve_<x>` | The editable, selector-filtered layer. **This is what the QGIS project loads.** `ve_node`, `ve_arc`, `ve_dma`, `ve_presszone`, `ve_plan_psector` |
| `ve_<featuretype>_<catfeature>` | One per feature type, trunk joined to its `man_*` table: `ve_node_hydrant`, `ve_arc_pipe`, `ve_connec_tap`. Generated by `gw_fct_admin_manage_child_views`, so never hand-edit them |
| `ve_inp_<x>` | Editable INP-model layers: `ve_inp_junction`, `ve_inp_pipe`, `ve_inp_dscenario_demand` |
| `ve_epa_<x>` | EPA-type editing views, including flow regulators: `ve_epa_valve`, `ve_epa_frpump` |
| `v_ui_<x>` | Feeds a tab or table widget of an info form: `v_ui_element_x_node`, `v_ui_om_visit` |
| `vi_t_<x>` | **Session temp views**, created inside `*_gw_fct_pg2epa_export_inp`. One per INP section (`vi_t_junctions`, `vi_t_pipes`). Not persistent. The exporter walks `config_fprocess WHERE fid = 141` (`tablename` = the `vi_t_*` view, `target` = the `[SECTION]` header) |
| `v_rpt_`, `v_om_`, `v_plan_`, `v_anl_`, `v_ext_` | Presentation views over the matching table family |
| `vu_<x>` | Views onto the `utils` addon schema (shared cartography). Absent from a bare main schema |
| `vp_basic_<x>` | Published/`publi` addon views. Absent from a bare main schema |

Consequence worth internalising: if a feature is missing from a QGIS layer, suspect `selector_expl`, `selector_state` or `selector_sector` before you suspect the data.

## Trunk tables and their column families

`node`, `arc`, `connec` and `gully` are near-identical by design. Learn the families once:

```
identity        node_id (from urn_id_seq), code, sys_code, uuid, asset_id,
                feature_type -> sys_feature_type
catalog         nodecat_id -> cat_node        arccat_id -> cat_arc        conneccat_id -> cat_connec
state           state -> value_state (0|1|2), state_type -> value_state_type
mapzone         expl_id, sector_id, dma_id, omzone_id, minsector_id, muni_id, district_id
                expl_visibility integer[]   (replaces the old expl_id2)
                ws only: presszone_id, dqa_id, supplyzone_id ; connec also crmzone_id
                ud only: dwfzone_id, omunit_id, drainzone_outfall, dwfzone_outfall
                         (drainzone_id is computed on ve_*, it is not a trunk column)
classification  function_type, category_type, fluid_type, location_type
                (each a composite FK to man_type_* on (<type>, feature_type))
management      workcat_id, workcat_id_end, workcat_id_plan, ownercat_id,
                builtdate, enddate, verified, om_state, conserv_state
address         muni_id, postcode, streetaxis_id, postnumber, postcomplement
                and a second set (streetaxis2_id, ...) for corner locations
model           epa_type, CHECK-constrained and different in every table
quality         dataquality, dataquality_obs text[], uncertain, datasource, lock_level
presentation    the_geom, rotation, label_x, label_y, label_rotation, label_quadrant,
                publish, inventory, is_scadamap
audit           created_at, created_by, updated_at, updated_by
```

Elevation is the one family that is genuinely different, and it is **not** `elevation` on either side: ws uses `top_elev`, `custom_top_elev`, `depth`; ud uses `top_elev`, `custom_top_elev`, `ymax`, `elev` plus `custom_elev`. In `common/` SQL, branch on `sys_version.project_type` rather than assuming one side's column names.

## Invariants

Break one of these and the topology triggers reject the write, or worse, accept it and corrupt the graph.

1. **State is a closed set of three.** `0` obsolete, `1` operative, `2` planned. Never invent a fourth. Substates live in `state_type`, which carries `state`, `is_operative` and `is_doable` and is the flag the functions actually test.
2. **`epa_type` is CHECK-constrained per table and per project type.** Read `sys_feature_epa_type` (and the table CHECK) rather than guessing. Live values:

```
ws node:     JUNCTION RESERVOIR TANK INLET UNDEFINED SHORTPIPE VALVE PUMP
ws arc:      PIPE UNDEFINED VIRTUALPUMP VIRTUALVALVE
ws connec:   JUNCTION UNDEFINED
ws element:  FRPUMP FRVALVE FRSHORTPIPE UNDEFINED
ud node:     JUNCTION STORAGE DIVIDER OUTFALL NETGULLY INLET UNDEFINED     [ud 4.17]
ud arc:      CONDUIT WEIR ORIFICE VIRTUAL PUMP OUTLET UNDEFINED             [ud 4.17]
ud element:  FRPUMP FRWEIR FRORIFICE FROUTLET UNDEFINED                     [ud 4.17]
```

   `PUMP-IMPORTINP` / `VALVE-IMPORTINP` do not exist. Flow regulators are `element.epa_type`, not a node type.

3. **An operative arc has `node_1` and `node_2`, and nodes split arcs.** Whether a node type splits is `cat_feature_node.isarcdivide`; how many arcs it may carry is `num_arcs`.
4. **A `link` belongs to its input feature and only touches its output feature.** It inherits exploitation and state from the connec/gully upstream, dies with it, and writes `arc_id` back into it. Moving the link's end vertex to another pipe rewrites that `arc_id`.
5. **`_`-prefixed means dead.** Do not read it, write it, or preserve it.

## How to get the correct information

The failure mode in this schema is a plausible-sounding column that does not exist. Work down this list and stop at the first answer.

**1. The live database.** Postgres MCP servers are configured (`user-postgres-17`, `user-postgres-18`, ...). `get_object_details` on a table, or:

```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'ws' AND table_name = 'node' ORDER BY ordinal_position;
```

Also use it for the domains, which are data rather than DDL:

```sql
SELECT id, state, name, is_operative, is_doable FROM ws.value_state_type ORDER BY id;
```

**2. The DDL plus every patch, when there is no live schema.** `SCHEMA_NAME` and `SRID_VALUE` are template placeholders.

```bash
D=dbmodel/schemas/main/ws/base/schema_model
rg -n 'CREATE TABLE node \(' -A80 $D/01_ddl_basic_schema_model.sql   # columns + CHECKs
rg -n 'ALTER TABLE ONLY node$' -A3 $D/05_fkey_schema_model.sql       # what it points at
rg -n 'REFERENCES cat_node\(id\)' -B1 $D/05_fkey_schema_model.sql    # what points at it
rg -n 'presszone_id' $D/01_ddl_basic_schema_model.sql                # who owns a column
```

**`schema_model/` is not the current shape of the schema.** It is the bootstrap snapshot at the start of the version walk; the real shape is that DDL plus every `updates/<M>/<m>/<p>/patch.sql` applied in order, and patches rename things. Three live examples: `sys_feature_cat` was renamed to `sys_feature_class` and `cat_feature.system_id` to `cat_feature.feature_class` in `common/updates/4/0/0/patch.sql`; `v_edit_*` became `ve_*` in `4/2/0`; `cat_feature.abrevation` became `abbreviation` in `4/17/0`. So a name you find only in `01_ddl_basic` may not exist in any real database. Always cross-check:

```bash
rg -n 'RENAME|ADD COLUMN|DROP COLUMN' dbmodel/schemas/main/{common,ws}/updates/*/*/*/patch.sql | rg cat_feature
```

Same caveat for views: `03_ddlview_schema_model.sql` gives you the original body, but a later patch may have replaced it with `CREATE OR REPLACE VIEW`. Prefer `pg_get_viewdef` on a live schema.

**3. The schema describing itself.** Much of the documentation is in the data:

```sql
SELECT id, alias, descript FROM ws.sys_table WHERE id LIKE 'man_%';
SELECT columnname, label, tooltip, datatype, widgettype
FROM ws.config_form_fields WHERE formname = 've_node_hydrant';
SELECT parameter, value, descript FROM ws.config_param_system WHERE parameter LIKE 'edit_mapzones%';
```

**4. The `/*EXAMPLE*/` block.** Every `gw_fct_*` file opens with a runnable call. Reading it beats reading the body, and running it beats both.

```bash
sed -n '1,40p' dbmodel/schemas/main/common/base/fct/gw_fct_getinfofromid.sql
```

**5. The official docs**, for vocabulary and concepts. The pages that actually have content: [data model](https://docs.giswater.org/master/en/docs/giswater/for-users/user-manual/data-model-giswater.html), [planning sectors](https://docs.giswater.org/master/en/docs/giswater/for-users/user-manual/planning-sectors.html), [netscenarios](https://docs.giswater.org/master/en/docs/giswater/for-users/user-manual/netscenarios.html), [map zones](https://docs.giswater.org/master/en/docs/giswater/for-users/map-zones/zonas-mapa.html). `fisic-dbmodel`, `system-variables`, `interoperability` and most admin-protocol pages are empty stubs — do not cite them as authority. When a doc name disagrees with a live schema, the schema wins.

One more trap: `dbmodel/schemas/main/{common,ws,ud}/functions/` is a stale hand-maintained mirror of `base/fct` and `base/ftrg`. Manifests load only `base/fct` and `base/ftrg` (`dbmodel/manifests/ws.yaml`). The two trees already differ. Never read `functions/`, never cite it.
