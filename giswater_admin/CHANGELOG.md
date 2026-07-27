# Changelog

All notable changes to the giswater-cli package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-07-23

### Added

- `gw project create` — generate QGIS `.qgs` projects from an existing ws/ud schema via headless PyQGIS (`qgs_runner`), with cross-platform QGIS Python discovery (`QGIS_PYTHON` override supported).

### Fixed

- Schema upgrade failing with `must be owner of function` during `reload_fct_ftrg` when update patches redefined functions as the installer superuser.
- Headless/CLI project generation using `ws`/`ud` as `project_type` for `gw_fct_get_project_layers` (must use `config_typevalue` idval, usually `Basic`), which produced empty `.qgs` files.
- Headless project TOC nesting feature-type groups under `NETWORK`; align with Admin (`force_create_group=False`, layers directly under `NETWORK`).

## [0.3.0] - 2026-06-19

### Added

- **Manifest-driven schema kinds** (`engine/manifest_registry.py`): addon/main kinds, update paths, integrate profiles, and `register_version` context are discovered from `dbmodel/manifests/*.yaml` instead of hardcoded Python lists.
- New satellite schemas (e.g. `publi`) work with `gw schema addon create|integrate|update|drop` as soon as a manifest and SQL tree exist — no CLI code changes required.

### Changed

- `gw schema addon --type` accepts any kind listed by `gw manifest list` (no fixed `choices=` whitelist).
- `schema_catalog` treats any non-`ws`/`ud` `project_type` as an addon for network discovery and inventory.
- `network update` resolves addon patch roots via convention `schemas/addon/{kind}/updates` and orders kinds from manifests (unknown addons default between `cibs` and `ws`).
- `create` derives integrate/register behavior from manifest profile names (`integrate_ws`, `integrate_ud`, `integrate`, `activate`, …) instead of per-kind `if` branches.
- `prepare_cli_release.py` runs `ruff check` on `giswater_admin/` and `scripts/` before tagging or publishing.

### Fixed

- Lockstep network updates when the dbmodel tree has SQL patches but no manifest files (tests / minimal fixtures).

## [0.2.0] - 2026-06-19

### Added

- Persistent database connection in user config: `gw config set database.conn URL` or `database.config /path/to/conn.yaml` (used when `--conn` / `--config` are omitted).

## [0.1.1] - 2026-06-18

### Fixed

- Schema builds failing on legacy update patches that use `DISABLE TRIGGER ALL` when the manifest profile skips `reload_fct_ftrg` (e.g. `ci`, `empty`): reset the database role to the installer after `load_base` so `updates` and `load_sample` run as superuser.

### Added

- `ci` and `dev` as valid `--profile` choices for `gw schema main create`.

## [0.1.0] - 2026-06-18

### Added

- PyPI package `giswater-cli` with `gw` console entrypoint (Python 3.9+).
- Headless schema engine shared with the QGIS plugin (`SchemaBuilder`, YAML manifests under `dbmodel/manifests/`).
- `gw db init` — install PostGIS, pgRouting and required PostgreSQL extensions per database.
- `gw schema main create|update|drop` — ws/ud project schemas with manifest profiles (`empty`, `test`, `demo`, …).
- `gw schema addon create|integrate|update|drop` — satellite schemas (utils, cibs, audit, …) and parent wiring.
- `gw schema list` — list schemas configured in the active dbmodel.
- `gw network show|update` — inspect linked topology and run lockstep network upgrades.
- `gw dbmodel install|list|use|status` — download, cache and switch Giswater SQL releases from plugin ZIPs.
- `gw config get|set` — persistent user settings (`~/.config/giswater/config.yaml` or `%APPDATA%/giswater/`).
- `gw manifest validate|list` — validate and enumerate manifest YAML files.
- `gw version` — report CLI package version and active dbmodel/schema version.
- Dbmodel resolution via `--dbmodel-path`, `GW_DBMODEL_PATH`, user config, or sibling checkout (`gw dbmodel use dev`).
- Offline `--check` mode to print the SQL execution plan without connecting to PostgreSQL.
- Timing reports and structured log output for automation and CI.
- Legacy command aliases (`create`, `update`, `drop`, `status`, `init-db`, `update-network`, `audit …`) with stderr deprecation warnings.

[unreleased]: https://github.com/giswater/plugin/compare/cli-v0.4.0...main
[0.4.0]: https://github.com/giswater/plugin/compare/cli-v0.3.0...cli-v0.4.0
[0.3.0]: https://github.com/giswater/plugin/compare/cli-v0.2.0...cli-v0.3.0
[0.2.0]: https://github.com/giswater/plugin/compare/cli-v0.1.1...cli-v0.2.0
[0.1.1]: https://github.com/giswater/plugin/compare/cli-v0.1.0...cli-v0.1.1
[0.1.0]: https://github.com/giswater/plugin/releases/tag/cli-v0.1.0
