# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.16.0] - 2026-07-24

### Added

- Add force reconnect parameter to `gw_fct_setlinktonetwork` function.
- Integrate `hydraulic_engine` in Go2Epa for WS (EPANET) execute and result import; UD and missing package keep the classic EPA path.
- Allow Execute EPA on Linux for WS when `hydraulic_engine` is installed; keep it Windows-only for UD.
- Require Execute EPA when Import results is selected in Go2Epa.
- Add `inp_report_onlymaxmin_values` EPA option to store only max/min results when importing with hydraulic_engine.
- Add `hydraulic_engine` dependency to `requirements.txt`.

### Fixed

- Fix blank multilingual projects: respect locale `cat_feature.active` and keep MULTI-CREATE `config_form_fields` (skip sample CFF wipe in empty profile).
- Fix `gw_fct_mincut_minsector` and `gw_fct_setmincut` functions to count hydrometers correctly.
- Fix selector performance on large projects: optimize `vf_node`/`vf_arc`/`vf_connec`/`vf_element`/`vf_link` filters and stop probing `ve_node` inside `gw_fct_setselectors` (check-all exploitations was multi-second).
- Fix `vf_element` view to use `COALESCE(pp.state, e.state)` instead of `e.state` with plan_psector_x_node.
- Fix `admin_catalog` to check if audit schema is fully installed.
- Fix `update` to use the correct language from `sys_version` table.
- Fix `gw_fct_create_querytables` and `gw_fct_manage_temp_tables` functions to create indexes on the geometry columns.

## [4.15.4] - 2026-07-21

### Fixed

- Fix admin dialog: refresh Project Schema list after a connection error.
- Fix admin dialog: list all WS/UD schemas on the active connection.

## [4.15.3] - 2026-07-17

### Fixed

- Fix `tools_db.ensure_service_auth` to get correct credentials from `pg_service.conf`.
- Fix config_form_fields `dv_querytext` to use `vf_hydrometer` and `hydro_customer_code` instead of `v_rtc_hydrometer` and `hydrometer_customer_code`.

## [4.15.2] - 2026-07-16

### Fixed

- Fix `gw_fct_setnodefromarc` function to return the correct error message with `gw_fct_exception_others` function.
- Fix admin dialog: do not show ghost schemas in parentheses when switching connections or after delete; restore selection only if the schema exists on the current connection.
- Fix admin dialog: persist last selected schema per connection instead of globally.
- Fix admin dialog: refresh schema list and project info when switching connections (ignore stale async load results).
- Fix admin dialog: avoid `TypeError` and missing-table warnings when a deleted or invalid schema is still selected.
- Fix admin dialog: show PostgreSQL/PostGIS/pgRouting versions for the active connection even when the server version is incompatible.
- Fix admin dialog: pg_service connections without user/password in `pg_service.conf` now prompt credentials via QGIS (same as Browser) instead of failing with `fe_sendauth`.

## [4.15.1] - 2026-07-15

### Fixed

- Fix `gw_trg_edit_inp_gully` trigger to use `gully_method` instead of `method`.
- Fix `gw_trg_edit_inp_node` trigger to use `gully_method` instead of `method`.
- Fix `gw_trg_edit_node` trigger to use `gully_method` instead of `method`.
- Fix `gw_fct_setmincut` use DISTINCT ON to avoid duplicate records in `om_mincut_valve`.
- Fix check if column `addparam` exists in `sys_version` table.

### Changed
- Refactor `v_om_mincut_initpoint`: now uses a JOIN instead of a LEFT JOIN with `selector_mincut_result` and removes the check for `id > 0`.

## [4.15.0] - 2026-07-13

### Added

- Add unique index on `link` table to enforce feature_id and feature_type uniqueness when state is 1 and feature_id is not null.
- New validation message for invalid or missing QGIS project CRS (EPSG) on pg2epa INP export.
- New validation message for `sys_code` not null and `sys_code_autofill` activated.

### Changed

- Change `dataquality_obs` type to text[] in `arc`, `node`, `connec`, `link`, and `element` tables.
- Change `edit_sys_code_autofill` variable to accept new values: `uuid`, `code`, `none`.

### Fixed

- Fix schema integration of `cibs` and `utils`.
- Change wmeter_number type to text in ext_hydrometer table.
- Fix `gw_fct_settoarc` so setting `to_arc` no longer auto-adds the node to mapzone's `graphconfig`, it only updates `toArc` when the node is already configured as `nodeParent` (avoids duplicate mapzone delimiters after arc divide). 
- Fix `dqaId` parameter parsing (`dqaId` was incorrectly read from `presszoneId`).
- Fix `gw_fct_setsearch` function to improve `sys_query_text_add` functionality.
- Fix `gw_fct_setnodefromarc` function to return the correct error message.
- Fix `gw_trg_edit_<feature>` triggers to set the correct state in the polygon table.
- Fix `gw_trg_edit_psector` trigger to set the correct state in the polygon table.

## [4.14.5] - 2026-06-25

### Fixed

- Fix `get_major_version` function on `tools_qgis` to return the correct major version.

## [4.14.4] - 2026-06-19

### Fixed

- Fix `gw_fct_setselectors` and `gw_fct_getselectors` functions using cat_manager configuration.

## [4.14.3] - 2026-06-15

### Fixed

- Fix `add_demand_check`, initialize cur_step correctly.

## [4.14.2] - 2026-06-12

### Fixed

- Fix `gw_fct_graphanalytics_mapzones_v1` function to set `expl_visibility` and `expl_id` in mapzones expl_ids.

## [4.14.1] - 2026-06-11

### Fixed

- Fix `config_form_fields` `dv_querytext` to use `ve_exploitation` instead of `vf_exploitation` for `macroexpl_id` filter column.
- Enable and require `sector_id` and `muni_id` on netscenario mapzone forms `plan_netscenario_dma` and `plan_netscenario_presszone`.
- Fix netscenario mapzone Create/Update in `mapzone_manager` to upsert into `plan_netscenario_*` (not operative `ve_*`) and refresh the netscenario table after accept.
- Fix `gw_fct_graphanalytics_mapzones_v1` function to filter by `expl_id` in the graphconfig.
- Fix `gw_fct_graphanalytics_mapzones_v1` function to use `expl_visibility` with `expl_id` in the views.
- Add missing `cur_user` filter to `config_param_user` queries for `epa_dscenario_percent_hydro_threshold` parameter.
- Fix netscenario views to use `vf_exploitation` to filter with permissions.

## [4.14.0] - 2026-06-10

### Added

- Add "Filter by selector" checkbox to mapzone manager to toggle between exploitation-permission scope and user selector scope.
- Persist mapzone manager "Filter by selector" checkbox state per user session (defaults to checked on first open).
- Add `vf_exploitation` view (based on `cat_manager` and `admin_exploitation_x_user`).
- Add `v_ui_*_sel` mapzone views for selector-based filtering (`selector_sector`, `selector_macrosector`, `selector_expl`).
- New tests for `vf_exploitation` view and mapzones `_sel` views.

### Changed

- Refactor mapzone `v_ui_*` views to filter by `vf_exploitation` instead of inline selector filters.
- Improve `gw_fct_graphanalytics_manage_temporary` now uses the new `vf_exploitation` view to filter with permissions.

### Fixed

- Fix `gw_fct_getprofilevalues` function to use the correct columns for ud and ws.

## [4.13.1] - 2026-06-04

### Fixed

- Fix `graphanalytics_mapzones` function by adding `mapzone_type` filter to graph delete queries in order to avoid deleting graph records belonging to other mapzone types stored in the same table.
- Fix `cibs`.`cat_hydrometer_category` table by changing the id type to int4 and add foreign key constraint for cat_period_id in hydrometer_period table.
- Fix `graphanalytics_mapzones` mapzones for ud can also be in SelfConflict, fix small bugs.
- Fix `graphanalytics_omunit` function by resetting `omunit_id` to 0 when the referenced omunit no longer exists.

### Removed

- Remove default value for `dataquality_obs` columns.

## [4.13.0] - 2026-06-03

### Added

- Add new key `sys_limit` to `config_param_system` to set the limit of the search results, modify the `gw_fct_getsearch` function to use the new key, default to 10.
- Add new columns `dataquality` and `dataquality_obs` to the `node, arc, connec, link, element and gully` tables.
- Add new column `turns_count` to the `man_valve` table.

### Changed

- Ignore TCV valves on `sys_fprocess` process 368.

### Fixed

- Update messages for arcs without start/final nodes.
- Update `gw_fct_admin_manage_fields` function to use the correct schema name and table name.

## [4.12.0] - 2026-06-01

### Added

- **Manage Schemas** dialog (`GwManageSchemasDialog`): single UI to inventory network anchors and manage satellite schemas (utils, cibs, AM, CM, audit) with contextual actions, fixed geometry, and refresh after admin load.
- Connection selector and read-only **system info** panel in Manage Schemas (PostgreSQL / PostGIS / PgRouting versions and missing extensions); switch DB connection without closing the dialog (`reload_connection_for_manage_schemas`).
- Rename and delete actions for network (WS/UD) schemas from Manage Schemas, wired to existing admin rename/delete flows.
- `_admin_catalog` module and `AdminLoadTask`: fast `pg_catalog` inventory (schemas with `sys_version`, aux flags, pending updates) instead of repeated `information_schema` round-trips.
- `GwSchemaBuilderTask`: generic `QgsTask` around `giswater_admin.engine.SchemaBuilder`, replacing legacy per-schema create threads (`project_schema_*_create`).
- New **`cibs`** schema and manifest; `sys_version` on cibs; WS/UD integration SQL and admin actions to create, update, adapt, and copy hydrometer data from a selected network parent.
- Hydrometer model refresh (4.12.0): `ext_hydrometer_period`, `v_`/`ve_` hydrometer views, editable `ve_hydrometer_period`, and `v_cat_*` catalogue views; sample dumps and forms updated.
- AM/CM manifests and parent-schema creation stubs from Manage Schemas (WS-only AM).
- pgTAP tests for UD link views (`ve_link`, `ve_link_vlink`, `ve_link_pipelink`).
- CI/dbmodel: PostGIS matrix, Docker/Podman test runner, parallel `pg_prove`, and stricter SQL folder validation in `sql_runner`.
- libs: `show_warning_box`, configurable DB connection timeout, and message boxes that respect `message_parent` (modal child of admin dialogs).
- Add column `is_twin` and `parent_id` to `rpt_cat_result`
- Add column `vnom` to `man_tank`
- Recreate triggers for `pol` tables

### Changed

- Manage Schemas CM panel: Create/Integrate/Sample/QGIS actions replace the old `admin_cm_create` launcher dialog. schemas grouped under `dbmodel/schemas/main` and `addons`; network updates consolidated into `patch.sql` per version (drop separate `ddl`/`dml`/`ddlview`/`trg` files for new bumps).
- Admin: utils/cibs/audit flows consolidated; schema SQL paths point at `main/`; build logs list SQL files only; progress/time labels on schema builder tasks.
- Hydrometers: rename `ext_rtc_hydrometer` → `ext_hydrometer`, `ext_rtc_hydrometer_data` → `ext_hydrometer_period`; `sum` → `billed_volume`; form/list queries use `v_`/`ve_` views; `ext_cat_hydrometer_category` id type integer.
- SCADA tables: `ext_rtc_scada` / `ext_rtc_scada_x_data` naming aligned across imports, functions, and tests.
- `ws_gw_fct_create_dscenario_from_crm`: joins and `hydrometer_id` references updated for the new hydrometer tables (no `pattern_id`).
- Manage Schemas: cibs adapt/copy pass the selected network schema directly (no `dlg_readsql.cmb_cibs` workaround); info messages use `show_info_box` when opened from the dialog.
- Mapzone type columns (`sector_type`, `drainzone_type`, `omzone_type`, `dwfzone_type`) widened to `varchar(30)` in tests and patches.

### Removed

- Deprecated `ext_cat_hydrometer_category_x_pattern` table and related tests.
- Legacy admin threads: `project_schema_create`, `project_schema_utils_create`, `project_schema_cm_create`, `project_schema_audit_create`, `project_schema_asset_create`, `project_schema_update`.
- Standalone cibs “copy data” button from the main admin UI (copy remains available from Manage Schemas).
- Obsolete dbmodel per-version changelog/SQL trees under old `updates/` layout (superseded by `schemas/main/.../updates`).

### Fixed

- `gw_fct_anl_arc_*` pgTAP tests: drop leftover temp tables between cases.
- UD schema tests and link view definitions after hydrometer / structure refactors.
- WS schema tests after hydrometer catalogue and view renames.
- `om_mincut_hydrometer` FK targets `ext_hydrometer`; mincut hydrometer views rebuilt on `v_hydrometer` / `v_hydrometer_period`.
- Plugin/schema path resolution (`plugin_version`, cibs integration SQL, manifests).

## [4.11.2] - 2026-05-29

### Fixed

- Improve UD checks in getvisit and setvisit
- Update mincut selector config in `config_param_system` (`basic_selector_tab_mincut`): add `typeaheadFilter` so filter in web works.
- Rename columns in `tbl_mincut_manager` tableview: `expl_id` to `exploitation`, `muni_id` to `municipality`.
- Fix `gw_fct_setselectors`: use `selector_municipality` (muni) instead of `selector_sector` to update selector_expl.
- `gw_fct_setmincut`: set `expl_id` from arc and `macroexpl_id` from exploitation on `om_mincut`.
- Fix visit dialog: unify `parameter_id` combo fill logic and refresh it after visit load and on Event tab entry.

## [4.11.1] - 2026-05-27

### Fixed

- Update reference function id for gw_fct_anl_node_topological_consistency.
- `gw_fct_graphanalytics_omunit` function to disable `edit_disable_arc_fkarray` when updating omunits.
- Optimize `gw_trg_array_fk_array_table`: pg_catalog type lookup and global `edit_disable_arc_fkarray` bypass.
- Fix function id references in `sys_function` and `config_function` tables.

## [4.11.0] - 2026-05-26

### Added

- Algorithm to calculate omunits and macroomunits `gw_fct_graphanalytics_omunit`.
- `has_access` column to `node` table.
- `ve_omunit` and `ve_macroomunit` views with edit triggers.
- New function `gw_fct_admin_manage_view_dependencies` to manage view dependencies.

### Removed

- `sector_id` and `muni_id` from `exploitation` table.
- `psector_status` typevalue `4` (EXECUTED).

### Fixed

- `gw_trg_edit_psector` trigger to set obsolete features where psector_x_* state is 0 before setting on service features.
- `gw_fct_graphanalytics_mapzones_v1` check if there are any nodes/arcs in the graphconfig that are not in the operative network (only for connected networks).
- `config_form_fields` `dv_querytext` for `muni_id` in `mincut` form to use correct alias.
- `visit` insert correctly the records on `om_visit_x_*` tables.
- correct signal for rejected visit dialog.
- recreate the triggers for the mapzones when the utility scheme is activated.
- fix visit dialog to show the correct features when the dialog is accepted.
- fix update of omunit and macroomunit geometry type to multipolygon.
- add `work_order`, `forecast_start`, and `forecast_end` columns to `temp_t_mincut` table.
- Improve performance of `gw_fct_getinfofromcoordinates` function.

## [4.10.1] - 2026-05-20

### Fixed

- `config_form_fields` `dv_querytext` for `muni_id` in `mincut` form to use correct alias.
- `visit` insert correctly the records on `om_visit_x_*` tables.
- correct signal for rejected visit dialog.
- recreate the triggers for the mapzones when the utility scheme is activated.
- fix visit dialog to show the correct features when the dialog is accepted.
- fix update of omunit and macroomunit geometry type to multipolygon.
- add `work_order`, `forecast_start`, and `forecast_end` columns to `temp_t_mincut` table.

## [4.10.0] - 2026-05-18

### Added

- stable `gw_id` custom map layer property when adding layers to the TOC so lookup and removal do not rely on the layer display name alone.
- `add_layer_provider` with URI builders (WMS, WFS, OAPIF, XYZ, GeoJSON) for loading non-PostGIS layers from `providerConfig`.
- `gw_fct_getaddlayervalues`: return `providerConfig` from `sys_table` for add-layer value lists.
- Add `basic_search_v2_tab_visit` in config_param_system for web and desktop search

### Changed

- child-layer menu, temporal and snapshot layers, mincut/psector overlap layers, EPA dscenario/netscenario removal, Go2Iber imports, ValueRelation layers in HIDDEN, and backend query layers updated for the new TOC APIs.
- Profile algorithm: now accept mid features (arcs) in addition to nodes.

## [4.9.1] - 2026-05-18

### Fixed

- Fix functions and triggers to use `v_raster_dem` instead of `ext_raster_dem`.
- Fix mincut offline result layer names and styles.
- Align mincut plan address fields in `config_form_fields` (`muni_id`, `streetaxis_id`, `postnumber` on `lyt_plan_address`).
- Update mincut default JSON in `config_param_system` add `forecast_start/end`.
- Set default list sorting for `tbl_mincut_manager` in `config_form_list` (device 5).
- Fix mincut snapping and related signals on mincut buttons.

## [4.9.0] - 2026-05-14

### Added

- New dscenario pattern and pattern value tables (`inp_dscenario_pattern`, `inp_dscenario_pattern_value`).
- New typevalue for dscenario type: CALIBRATION.
- New visibility tables `node_x_sector_visibility`, `node_x_municipality_visibility`, `element_x_sector_visibility`, `element_x_municipality_visibility`.
- New trigger `gw_trg_update_element_mapzones` to update mapzone columns on `element`.
- `has_treatment` column on UD `node`, `connec`, and `gully` tables, related triggers, and `ve_node`, `ve_connec`, and `ve_gully` views.
- `drainzone_outfall` calculation and updates to `dwfzone_outfall` in graph analytics mapzones.
- `v_recalculate_macromapzones` parameter and related macro mapzone logic in `gw_fct_graphanalytics_mapzones`.
- Temporary table and view for element management inside graph analytics.
- Drainzone handling in graph analytics extended so `addfields` / `addparam.drainzone` receive aggregated results where applicable.
- `provider_config` column on `sys_table` plus related catalogue checks.
- View `v_type_street` and updated `config_form_fields` references for street types.
- CSO overflow mapping table for storm overflow workflows.

### Changed

- Config toolbox: SQL input parameters for graph class and exploitation options.
- `sys_style`: improved line symbology for fluid types.
- Municipality assignment for nodes when several municipalities lie nearby (selection logic refined).
- Upstream/downstream analysis: traverse network regardless of `is_operative` on elements.
- `fct_cm_check_progress`: exposes percentage of executed nodes per campaign.
- Network mincut: streamlined SQL queries and address autofill usable from web and desktop.
- Multiple SQL functions: `sector_id` conditions normalized for clearer integrity rules.
- i18n: labels, tooltips, and descriptions (graph tools, exploitation, and general wording).
- Optional dependencies resolved via `tools_os.get_dep` instead of bare imports.

### Fixed

- `inp_dscenario_demand`: move `id` column to first position for stable column ordering.
- Composer: logo image path resolution.
- `gw_fct_graphanalytics_mapzones_v1`: drainzone insert/update; correct `expl_id[]`, `muni_id[]`, `sector_id[]` arrays for mapzones; ignore `sector_id = 0` when aggregating sectors; create `temp_pgr_mapzone_graph` only when running graphanalytics mapzones.
- Graph analytics visibility: WS/UD compatibility for `node_x_sector_visibility`-related flows.
- `gw_fct_getfeatureupsert`: default value handling for filter combo widgets when updating features in Info.
- `gw_fct_cm_setcheckproject`: GeoJSON payload handling for check results.
- `gw_fct_cm_check_data_context`: expanded checks and clearer error texts; QC output limited to rows with `status = 1` and `action <> 3`.
- `gw_fct_pg2epa_check_network`: `sector_id` and `dma_id` behaviour on disconnected networks.
- `gw_fct_pg2epa_export` WS dscenario path: tank parameters updated correctly on inlet links.
- `gw_fct_getsearch`: optional JSON key to target a specific layer in the search call.
- `gw_fct_setelevfromdem`: propagate detailed errors back to the client on failure.
- `om_check_data`: use catalogued `t_tables` instead of ad hoc target tables.
- Asset Manager: insert into `sys_version` uses schema SRID (`SCHEMA_SRID`) for EPSG.
- `gw_fct_getprofilevalues`: cast JSON `descript` through text for stable typing.
- Lot/campaign selectors: `ON CONFLICT` handling for campaign/lot selectors to avoid duplicate key failures.
- `inp_subcatchment`: enforce foreign keys referencing municipality where defined in utils/tablect DDL.
- `temp_anl_arc` / `temp_anl_node`: drop redundant duplicate index DDL where the index already existed.

## [4.8.4] - 2026-05-07

### Fixed

- Improve composer warning handling and correct coverage.
- Fix ve_plan_psector and v_plan_psector references.
- Fix hardcoded logo.png path.
- Improve psector manager performance.
- Fix psector other_prices tab bug with ',' and '.' as decimal separator.
- Fix problem with psector pca calculation.
- Fix dscenario manager to check columns from views instead of tables.

### Changed

- Performance profiling in get_psector method when open existing one.
- References from `ve_plan_psector` to `v_plan_psector` in `sys_table` and `sys_style` tables.

### Removed

- Deprecated code on psector manager to improve performance.
- Hide pump additional tab in dscenario manager.

## [4.8.3] - 2026-05-05

### Fixed

- Fix `config_param_system` update epa_automatic_man2graph_values value

## [4.8.2] - 2026-04-20

### Changed

- Removed dependency on chardet.

## [4.8.1] - 2026-04-07

### Added

- This changelog file
- New indexes on `anl_*` tables.

### Fixed

- `gw_trg_arc_node_values` trigger on ws schemas.
- `gw_fct_graphanalytics_macromapzones` streamline temporary table management.
- `gw_fct_pg2epa_export_inp` add alias for emitter_coeff.
- `gw_fct_graphanalytics_mapzones_v1` function.
- Performance of dscenario views for ws and ud
- `gw_trg_gully_proximity`, `gw_trg_connec_proximity` triggers to use `ve_gully` and `ve_connec` tables instead of `gully` and `connec` tables.
- `gw_fct_getfeatureupsert` function to use `ve_node`, `ve_connec` and `ve_gully` tables instead of `node`, `connec` and `gully` tables.
- Recreated `ve_connec` and `ve_gully` views.
- Improved `inp_family` table and `result_families` function.
- `gw_fct_setfeaturereplaceplan` function.
- `ud_gw_trg_topocontrol_node` trigger.
- `ud_gw_trg_topocontrol_arc` trigger.
- `gw_fct_psector_merge` function.
- `ud_pg2epa` now export undefined nodes connected to not undefined arcs.

### Removed

- Losses dscenario.

## [4.8.0] - 2026-03-17

### Added

- Tab `supplyzone` on mapzone manager.

### Fixed

- Getting style for some layers.
- QGIS crash with toolbox processes.
- QGIS project creation.
- Various CM bug fixes.

### Changed

- Refactor `getlist` and tableviews header with alias management.
- QGIS maximum version to 4.0.

## [4.7.1] - 2026-02-24

### Fixed

- Make some user parameters mandatory (`sys_param_user`).
- Mapzone checks on mapzones.

## [4.7.0] - 2026-01-30

### Added

- New EPA export result families.
- Mapzones checks before execution.
- New checks on `pg2epa` export.
- Load temporal layers when getting profile values.

### Fixed

- Topology fields and various UD/WS analysis routines.
- Graph inundation and profile values retrieval.

### Changed

- Refactor UD topology fields and related views.
- Update psector/mincut logic to use `pgr_linegraph` and new algorithms.

## [4.6.0] - 2025-12-18

### Added

- Update submodules and database logic for new CI and tests.

## [4.5.4] - 2025-11-12

### Fixed

- Multiple triggers and functions related to config control, proximity, connectivity and plan psector logic.
- `config_form_fields` to use the correct `dv_query_text` on `man_type_*` columns.
- Deleting psectors with `to_arc` property.
- Various EPA export and topology control routines (`pg2epa`, `setfeaturereplace`, `setendfeature`, `topocontrol_arc`, etc.).

## [4.5.3] - 2025-10-28

### Fixed

- Translation of `cat_arc.area` for `es_CR`.
- `admin_currency` translation.
- `config_fprocess` to add `rpt_arc_stats` and `rpt_node_stats` entries.
- `pg2epa` network check to use `-2` as `dma_id` for undefined values.

## [4.5.2] - 2025-10-27

### Fixed

- Widget type compatibility and UI checks.
- Psector topology validation and error handling.
- Psector translations, initproject, `config_form_fields` for dma and canvas refresh.

## [4.5.1] - 2025-10-23

### Fixed

- GwPlan application when a psector is current.
- Psignals on psector manager and play/pause button.
- Psector merge, duplicate and topology when duplicated nodes are found.
- Adding connecs into a psector without `arc_id`.
- Several rows on `sys_message` and selector_psector clarity.
- Log order on `audit_check_data`.

### Removed

- Legacy `chk_enable_all` behavior.
- Deleting from `selector_psector` when psector is set to inactive.

## [4.5.0] - 2025-10-20

### Added

- New CM toolbar for campaigns, lots, organizations, teams and users with role-based permissions.
- New AM toolbar for priority calculation, breakage analysis and result management.
- New translation logic and i18n overhaul.
- Psector mode toggle in status bar with context menu.
- Go2IBER integration (DAT/RPT support).
- Import EPANET/SWMM with save-to-psector.
- New selection-by-expression tools and unified selection logic.
- New elements managers (`ve_genelem`, `ve_frelem`) and non-visual managers enhancements.
- Markdown generator for documentation.
- Hidden form logic for feature creation.
- PgRouting version compatibility check on project load.
- GitHub workflow templates and flake8 CI for Python compatibility checks.

### Fixed

- Project creation for `es_CR` and other locales with malformed JSON.
- Psector toggling and table relation refresh.
- Mincut conflicts deletion and result selector updates.
- EPANET import (time options, diameters, catalogs).
- SWMM import (flow regulators, trigger enabling).
- Selection tools snapping precision and map/table interaction.
- macOS dialogs that blocked the main QGIS window.
- Feature replace catalogs and arc snapping in psector mode.
- Info docker double-click and cross-section image display.
- Signal/thread handling for psector, CM and selection tools.

### Changed

- Massive refactor of `v_edit_*` views to `ve_*` prefix.
- Refactor of setfields logic to use database-side feature creation.
- Refactor of docker references and psector UI buttons.
- Consolidation of psector loading and signal management.
- Performance optimizations on selectors, table refresh and map rendering.
- SQL performance improvements for i18n, CM and EPA imports.
- Form change detection and caching improvements.
- Large-scale flake8 and typing standardization.

[unreleased]: https://github.com/giswater/plugin/compare/v4.16.0...main
[4.16.0]: https://github.com/giswater/plugin/compare/v4.15.4...v4.16.0
[4.15.4]: https://github.com/giswater/plugin/compare/v4.15.3...v4.15.4
[4.15.3]: https://github.com/giswater/plugin/compare/v4.15.2...v4.15.3
[4.15.2]: https://github.com/giswater/plugin/compare/v4.15.1...v4.15.2
[4.15.1]: https://github.com/giswater/plugin/compare/v4.15.0...v4.15.1
[4.15.0]: https://github.com/giswater/plugin/compare/v4.14.5...v4.15.0
[4.14.5]: https://github.com/giswater/plugin/compare/v4.14.4...v4.14.5
[4.14.4]: https://github.com/giswater/plugin/compare/v4.14.3...v4.14.4
[4.14.3]: https://github.com/giswater/plugin/compare/v4.14.2...v4.14.3
[4.14.2]: https://github.com/giswater/plugin/compare/v4.14.1...v4.14.2
[4.14.1]: https://github.com/giswater/plugin/compare/v4.14.0...v4.14.1
[4.14.0]: https://github.com/giswater/plugin/compare/v4.13.1...v4.14.0
[4.13.1]: https://github.com/giswater/plugin/compare/v4.13.0...v4.13.1
[4.13.0]: https://github.com/giswater/plugin/compare/v4.12.0...v4.13.0
[4.12.0]: https://github.com/giswater/plugin/compare/v4.11.2...v4.12.0
[4.11.2]: https://github.com/giswater/plugin/compare/v4.11.1...v4.11.2
[4.11.1]: https://github.com/giswater/plugin/compare/v4.11.0...v4.11.1
[4.11.0]: https://github.com/giswater/plugin/compare/v4.10.1...v4.11.0
[4.10.1]: https://github.com/giswater/plugin/compare/v4.10.0...v4.10.1
[4.10.0]: https://github.com/giswater/plugin/compare/v4.9.1...v4.10.0
[4.9.1]: https://github.com/giswater/plugin/compare/v4.9.0...v4.9.1
[4.9.0]: https://github.com/giswater/plugin/compare/v4.8.4...v4.9.0
[4.8.4]: https://github.com/giswater/plugin/compare/v4.8.3...v4.8.4
[4.8.3]: https://github.com/giswater/plugin/compare/v4.8.2...v4.8.3
[4.8.2]: https://github.com/giswater/plugin/compare/v4.8.1...v4.8.2
[4.8.1]: https://github.com/giswater/plugin/compare/v4.8.0...v4.8.1
[4.8.0]: https://github.com/giswater/plugin/compare/v4.7.1...v4.8.0
[4.7.1]: https://github.com/giswater/plugin/compare/v4.7.0...v4.7.1
[4.7.0]: https://github.com/giswater/plugin/compare/v4.6.0...v4.7.0
[4.6.0]: https://github.com/giswater/plugin/compare/v4.5.4...v4.6.0
[4.5.4]: https://github.com/giswater/plugin/compare/v4.5.3...v4.5.4
[4.5.3]: https://github.com/giswater/plugin/compare/v4.5.2...v4.5.3
[4.5.2]: https://github.com/giswater/plugin/compare/v4.5.1...v4.5.2
[4.5.1]: https://github.com/giswater/plugin/compare/v4.5.0...v4.5.1
[4.5.0]: https://github.com/giswater/plugin/releases/tag/v4.5.0
