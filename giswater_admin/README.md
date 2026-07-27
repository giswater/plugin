# giswater-admin

Headless CLI and engine for the Giswater database schema lifecycle (create, upgrade, drop, inspect). It reads the same YAML manifests under `dbmodel/manifests/` and runs the same `SchemaBuilder` as the QGIS plugin (`GwSchemaBuilderTask` + `QtDbAdapter`), so automation, CI, and the desktop UI do not diverge on SQL execution logic.

**See also:** [dbmodel README — Schema architecture](../dbmodel/README.md#schema-architecture) · [dbmodel README — Testing](../dbmodel/README.md#testing)

## Table of contents

1. [Overview](#overview)
2. [Where to run it](#where-to-run-it)
3. [Architecture](#architecture)
4. [Install](#install)
5. [Connection](#connection)
6. [Invocation rules](#invocation-rules)
7. [Global options](#global-options)
8. [Commands reference](#commands-reference)
9. [Kinds and manifest profiles](#kinds-and-manifest-profiles)
10. [Timing and output](#timing-and-output)
11. [QGIS integration](#qgis-integration)
12. [Unit tests](#unit-tests)
13. [Extending the model](#extending-the-model)
14. [Keeping docs in sync](#keeping-docs-in-sync)

---

## Overview

| Layer | Path | Role |
|-------|------|------|
| CLI entry | `giswater_admin/cli/` | Argument parsing, dispatch, context |
| Commands | `giswater_admin/commands/` | Subcommand handlers (`create`, `dbmodel`, …) |
| Install | `giswater_admin/install/` | User config, dbmodel cache, release downloads |
| Engine | `giswater_admin/engine/` | `SchemaBuilder`, manifests, SQL runner (shared with QGIS) |
| Shared I/O | `conn.py`, `output.py`, `log_format.py` | Connection, stdout/stderr formatting |

Legacy shims at package root (`paths.py`, `user_config.py`, `releases.py`) re-export from `install/` for backward compatibility.

| Piece | Role |
|-------|------|
| `cli/parser/` | Subcommand registration split by domain |
| `cli/context.py` | Resolve dbmodel path and schema version before dispatch |
| `cli/main.py` | `main()` entrypoint |
| `dbmodel/manifests/*.yaml` | Phase graphs per schema kind |
| `dbmodel/schemas/` | SQL sources (DDL, functions, updates, samples) |

Typical flow for a new database:

1. Create an empty PostgreSQL database (outside this CLI).
2. `db init` — cluster extensions once per database.
3. `schema main create` / `schema addon create` — build project and satellite schemas.
4. `schema addon integrate` — wire satellites into ws/ud parents.
5. `network show` — inspect topology; `network update` — lockstep upgrade.

---

## Where to run it

| Context | Command |
|---------|---------|
| **Global CLI (recommended)** | `gw create …` after `pipx install giswater-cli` |
| Plugin repo checkout | `python3 -m giswater_admin …` or `gw …` with dev dbmodel |
| Custom dbmodel tree | `gw create … --dbmodel-path /path/to/dbmodel` |
| CI / Docker tests | See [dbmodel testing](../dbmodel/README.md#testing) |
| QGIS | N/A (in-process) | `GwSchemaBuilderTask` — no subprocess |

**Requirements:** Python 3.9+, PostgreSQL with PostGIS/pgRouting on the **server**.

**dbmodel resolution order** (when `--dbmodel-path` is omitted):

1. `--dbmodel-path`
2. `GW_DBMODEL_PATH` environment variable
3. User config with `source: dev` (`gw dbmodel use dev …`)
4. Sibling `dbmodel/` in a plugin repo checkout (overrides stale release cache)
5. Release cache (`gw dbmodel install …`)

If nothing matches, run `gw dbmodel install latest` or `gw dbmodel use dev --root /path/to/repo`.

---

## Architecture

```mermaid
flowchart TB
  subgraph hosts [Execution contexts]
    CLI["gw / python -m giswater_admin"]
    QGIS["GwSchemaBuilderTask + QtDbAdapter"]
    CI["dbmodel/test/bootstrap_inner.sh"]
  end
  subgraph engine [giswater_admin/engine]
    Manifest["manifests/*.yaml"]
    Builder["SchemaBuilder"]
    Runner["sql_runner"]
  end
  subgraph dbmodel_tree [dbmodel/]
    Schemas["schemas/..."]
    Updates["updates M/m/p"]
  end
  PG[(PostgreSQL)]
  CLI --> Builder
  QGIS --> Builder
  CI --> CLI
  Builder --> Manifest
  Builder --> Runner
  Runner --> Schemas
  Runner --> Updates
  Runner --> PG
```

**Phase types** (declared in manifests, implemented in `engine/manifest.py`):

| Type | Behavior |
|------|----------|
| `sql_dir` | Run every `*.sql` in listed folders (optional `recursive`) |
| `version_walk` | Walk `updates/<M>/<m>/<p>/` semver-ordered; `roots:` for ws/ud (common then kind) |
| `sql_function` | `SELECT schema.fn($${JSON}$$)` (e.g. `lastprocess`) |
| `sql_file` | Single file with optional `fallback_source` |
| `sql_inline` | Literal SQL in YAML |

---

## Install

### Global CLI (Windows / Linux / macOS)

Install [pipx](https://pipx.pypa.io/) once, then install the CLI package:

```bash
# macOS
brew install pipx && pipx ensurepath

# Windows / Linux (if pipx is not installed yet)
python3 -m pip install --user pipx
python3 -m pipx ensurepath

# All platforms
pipx install giswater-cli
```

Download a published dbmodel (from the same plugin ZIP used by QGIS):

```bash
gw dbmodel install latest --set-active
gw version
```

Typical first run:

```bash
gw db init --conn "postgresql://user:pass@127.0.0.1:5432/mydb"
gw schema main create --type ws --name demo --profile empty --conn "postgresql://user:pass@127.0.0.1:5432/mydb"
```

**Development without a release** (use your local checkout):

```bash
gw dbmodel use dev --root /path/to/plugin
gw schema main create --type ws --name test_dev --conn "$CONN" --check
```

Config and cache locations:

| OS | Config | Release cache |
|----|--------|---------------|
| Linux / macOS | `~/.config/giswater/config.yaml` | `~/.local/share/giswater/releases/` |
| Windows | `%APPDATA%/giswater/config.yaml` | `%LOCALAPPDATA%/giswater/releases/` |

### From the plugin repository (contributors)

```bash
cd /path/to/plugin
python3 -m pip install -e .
# or legacy:
python3 -m pip install -r giswater_admin/requirements.txt
```

Optional virtualenv:

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -e .
```

**OS packages (server side)** — names vary by distro; install PostGIS and pgRouting for your PostgreSQL major version:

- Debian/Ubuntu: `postgresql-16-postgis-3`, `postgresql-16-pgrouting`, …
- macOS (Homebrew): `postgresql@16`, `postgis`
- Windows: PostGIS/pgRouting matching your PostgreSQL installer

Verify:

```bash
gw --help
# or
python3 -m giswater_admin --help
```

### dbmodel management commands

| Command | Purpose |
|---------|---------|
| `gw dbmodel install latest` | Download plugin ZIP and cache `dbmodel/` |
| `gw dbmodel install 4.9.0` | Install a specific release |
| `gw dbmodel list` | Cached versions + remote latest |
| `gw dbmodel use latest` | Activate latest cached/remote version |
| `gw dbmodel use dev --root PATH` | Use `PATH/dbmodel` from a checkout |
| `gw config get` / `gw config set KEY VALUE` | Persistent settings (`dbmodel.*`, `database.conn`, `database.config`, …) |

---

## Versioning

Two independent version numbers:

| Version | Example | Meaning |
|---------|---------|---------|
| **CLI** (`gw version` → `cli`) | `0.1.0` | The `giswater-cli` tool: commands, fixes, packaging. Bump with [`scripts/bump_cli_version.py`](../scripts/bump_cli_version.py). |
| **Schema / dbmodel** (`gw version` → `dbmodel-version`) | `4.15.0` | Giswater release whose SQL and `updates/` patches are applied. Comes from the active dbmodel, not from the CLI version. |

A single CLI release can create or upgrade schemas for any installed dbmodel version:

```bash
gw dbmodel install 4.14.0 && gw dbmodel use 4.14.0
gw create --kind ws --schema legacy --conn "$CONN"

gw dbmodel install 4.16.0 && gw dbmodel use 4.16.0
gw create --kind ws --schema current --conn "$CONN"
```

Use `--plugin-version X.Y.Z` to override the schema release when auto-detection is not possible (e.g. a custom `--dbmodel-path` without `metadata.txt`).

### CLI releases (`cli-v*`)

The CLI is released **independently** from the QGIS plugin:

| Event | Tag example | Publishes |
|-------|-------------|-----------|
| Plugin Giswater | `v4.16.0` | `giswater.zip` + dbmodel (see repo `release-plugin.yml`) |
| CLI `gw` | `cli-v0.1.0` | PyPI `giswater-cli` + wheel on GitHub Release |

Maintain [`giswater_admin/CHANGELOG.md`](CHANGELOG.md) (Keep a Changelog format) before each release.

**First release (`0.1.0`)** — document changes under `## [Unreleased]`, then:

```bash
python3 scripts/prepare_cli_release.py 0.1.0 --create-github-release
python3 scripts/prepare_cli_release.py 0.1.0 --execute --create-github-release
```

(`pyproject.toml` and `giswater_admin/__version__.py` must already be `0.1.0`.)

**Subsequent releases** (e.g. `0.2.0`):

```bash
pip install ruff   # required: prepare_cli_release runs ruff before tagging
python3 scripts/bump_cli_version.py 0.2.0
# Add changes under ## [Unreleased] in giswater_admin/CHANGELOG.md
python3 scripts/prepare_cli_release.py 0.2.0 --create-github-release
python3 scripts/prepare_cli_release.py 0.2.0 --execute --create-github-release
```

`prepare_cli_release.py` runs `ruff check giswater_admin scripts` (see repo `ruff.toml`) before creating the tag or GitHub release. Fix lint issues first; the script aborts on failure.

When the GitHub Release is published, CI (`.github/workflows/release-cli.yml`) runs tests, validates versions, builds `dist/*`, publishes to PyPI via OIDC (Trusted Publisher, environment `pypi`), and attaches wheels to the release.

**One-time PyPI setup:** register a pending publisher at https://pypi.org/manage/account/publishing/ with project `giswater-cli`, owner `giswater`, repository `plugin`, workflow `release-cli.yml`, environment `pypi`. Create the matching `pypi` environment in GitHub repo settings.

Users install the tool once (`pipx install giswater-cli`) and refresh schema SQL with `gw dbmodel install` when a new plugin version ships.

### Testing locally

```bash
cd /path/to/plugin
python3 -m pip install -e .

# Ensure gw is on PATH (macOS user install example)
export PATH="$HOME/Library/Python/3.9/bin:$PATH"

gw version
python3 -m pytest test/cli/ -q

# Offline schema plan (no DB)
gw create --kind ws --schema test --profile empty --check \
  --conn "postgresql://user@127.0.0.1:5432/mydb"
```

### Network E2E (manual / release lockstep)

Per-commit dbmodel validation runs in **PostgreSQL Tests** (21 checks: sample pgTAP, profiles, updates, satellites, network). **Release** verifies those checks on the tag SHA; plugin releases also run **network lockstep** (`update_network`, PG 18).

**Local (direct, needs Postgres + `CONN`):**

```bash
export CONN='postgresql://postgres:postgres@127.0.0.1:5432/gw_db'
chmod +x scripts/gw_e2e_*.sh scripts/gw_bootstrap_network.sh

./scripts/gw_e2e_profiles.sh              # ws/ud × empty|sample|inventory
./scripts/gw_e2e_update_isolated.sh       # ws + ud solo @ FROM→TO
SATELLITES=utils,cibs ./scripts/gw_e2e_addons_integrate.sh
./scripts/gw_e2e_network_update.sh        # guards + lockstep
./scripts/gw_e2e_update_all.sh            # full release suite
```

**Local (Docker, same stack as CI):**

```bash
./dbmodel/test/run_e2e.sh update_all
./dbmodel/test/run_e2e.sh profiles
PG_MAJOR=17 ./dbmodel/test/run_e2e.sh update_network

# Satellite pgTAP (phase 2)
./dbmodel/test/run_satellite_tests.sh utils
./dbmodel/test/run_satellite_tests.sh network_ws
```

**CI:** GitHub Actions → *PostgreSQL Tests* on every PR/push touching `dbmodel/**` (21 jobs). *Network E2E (Giswater)* is manual (`workflow_dispatch`) for ad-hoc scenarios. Release workflows verify CI checks instead of re-running the full matrix.

| Scenario | Script / input |
|----------|----------------|
| `profiles` | ws/ud × empty, sample, inventory |
| `update_isolated` | `schema main update` on ws and ud alone |
| `addons` | utils+cibs create + integrate (`SATELLITES` env) |
| `update_network` | blocked single updates + `network update` |
| `update_all` | `update_isolated` + `update_network` (release gate) |

Env: `SATELLITES=utils,cibs`, `PARENT_PROFILE=empty|sample|inventory`, `PLUGIN_VER` / `TARGET_VER` (default: last two semver patches).

---

## Connection

Resolution order (first match wins):

1. `--conn` — `postgresql://user:pass@host:port/dbname` (or `postgres://…`)
2. `--config` — YAML with `host`, `port`, `user`, `password`, `dbname`, and/or `service`
3. User config — `gw config set database.conn …` or `database.config /path/to/conn.yaml`
4. Environment — `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`, `PGSERVICE`

**Persist a default connection** (no `--conn` on every command):

```bash
gw config set database.conn "postgresql://gisadmin:secret@127.0.0.1:5432/giswater_cli"
gw schema list

# or point at a separate YAML (keeps passwords out of config.yaml)
gw config set database.config /path/conn.yaml
gw config set database.conn null   # clear URL
```

**Superuser:** mutating commands (`db init`, `schema` create/integrate/update/drop, `network update`, and `--check` with a live connection) require a PostgreSQL **superuser**. Read-only commands (`schema list`, `network show`) work with any role that can `SELECT` Giswater schemas and `pg_catalog`.

### Linux / macOS

```bash
export CONN='postgresql://gisadmin:secret@127.0.0.1:5432/giswater_cli'
python3 -m giswater_admin status --conn "$CONN"
```

### Windows (PowerShell)

```powershell
$env:CONN = "postgresql://gisadmin:secret@127.0.0.1:5432/giswater_cli"
py -3 -m giswater_admin status --conn $env:CONN
```

### Config file

```yaml
host: 127.0.0.1
port: 5432
user: gisadmin
password: secret
dbname: giswater_cli
```

```bash
python3 -m giswater_admin status --config /path/conn.yaml
```

**`--check`:** many subcommands only print the plan or SQL and do not write to the database. `db init --check` does not require a connection.

---

## Invocation rules

Global options are on the **parent parser of each subcommand**. They must appear **after** the subcommand name:

```bash
# Correct
python3 -m giswater_admin schema main create --type ws --name demo --profile empty --json

# Wrong (root parser does not define --json)
python3 -m giswater_admin --json create ...
```

---

## Global options

Available on subcommands that include the shared parent parser (`schema …`, `network …`, `db init`, legacy aliases, `manifest list|validate`).

| Option | Description |
|--------|-------------|
| `--json` | Single JSON object on **stdout** (for `jq`, CI, scripts). |
| `--quiet` | Suppress info-level progress on stderr; errors/warnings remain. |
| `-v` / `--verbose` | One aligned line per executed SQL path on stderr. |
| `-d` / `--debug` | Like `-v` plus `DEBUG` logs with SQL previews. |
| `--timing` | `── Done … ──` summary (per phase + slowest files). With `-v`, adds ms per file. |
| `--timing-threshold-ms N` | With `-v --timing`, only log files with duration ≥ N ms. |
| `--timing-top K` | Number of slowest files in summary (default: 20). |
| `--timing-detail` | With `--json --timing`, include full per-file list in the JSON payload. |
| `--dbmodel-path DIR` | Root of the dbmodel tree (default: sibling `dbmodel/` in the plugin repo). |

**Connection group** (where applicable):

| Option | Description |
|--------|-------------|
| `--conn` | PostgreSQL URL. |
| `--config` | Path to connection YAML. |

---

## Commands reference

Base syntax:

```text
python3 -m giswater_admin <subcommand> [subcommand options] [global options]
```

Exit codes: **0** success, **1** failure (parse, I/O, PostgreSQL, SQL, invalid plan).

### Command tree

```text
gw db init
gw schema main   create | update | drop
gw schema addon  create | integrate | update | drop
gw project       create
gw network       show | update
```

Legacy aliases (`create`, `update`, `drop`, `status`, `init-db`, `update-network`, `audit …`) still work but print a deprecation warning to stderr and are hidden from `--help`.

| Old | New |
|-----|-----|
| `gw create --kind ws --schema x` | `gw schema main create --type ws --name x` |
| `gw update --schema ws` | `gw schema main update --name ws` |
| `gw status` | `gw network show --flat` |
| `gw init-db` | `gw db init` |
| `gw update-network` | `gw network update` |
| `gw audit structure` | `gw schema addon create --type audit` |
| `gw audit activate --schema ws` | `gw schema addon integrate --type audit --parent ws` |

Use `--version X.Y.Z` everywhere (replaces `--plugin-version` / `--to-version`).

---

### `db init`

Creates extensions in order: `postgis` → `postgis_raster` → `tablefunc` → `pgrouting` → `unaccent` (optional `postgres_fdw` with `--with-fdw`). Run **once per database** before the first schema create.

| Option | Description |
|--------|-------------|
| `--with-fdw` | Also `CREATE EXTENSION postgres_fdw`. |
| `--with-pgtap` | Also `CREATE EXTENSION pgtap` (for dbmodel tests). |
| `--continue-on-error` | Try all extensions after a failure (default: stop on first error). |
| `--check` | Print SQL only; no connection required. |
| `--conn` / `--config` | Connection (optional with `--check`). |

```bash
gw db init --conn "$CONN"
gw db init --conn "$CONN" --with-fdw --with-pgtap
```

---

### `schema main`

ws/ud project schemas.

#### `schema main create`

| Option | Description |
|--------|-------------|
| `--type` | **Required.** `ws` \| `ud` |
| `--name` | Schema name (default: same as `--type`, e.g. `ws`). |
| `--profile` | `empty` \| `sample` \| `inventory` (maps to manifest `empty`, `sample_full`, `sample_inv`). |
| `--lang` | Locale folder (default `en_US`). |
| `--srid` | EPSG code (default `25831`). |
| `--version` | Giswater schema release X.Y.Z (default: from active dbmodel). |
| `--check` | Plan only. |
| `--conn` / `--config` | Connection. |

```bash
gw schema main create --type ws --name ws1 --profile sample --lang es_ES --conn "$CONN"
gw schema main create --type ud --profile empty --conn "$CONN"
```

#### `schema main update`

Upgrades one isolated ws/ud schema. **Blocked** if the schema belongs to an interconnected network (use `network update`). **Downgrades forbidden.**

| Option | Description |
|--------|-------------|
| `--name` | **Required.** Existing schema. |
| `--version` | Target version (default: active dbmodel). |
| `--check` | Plan only. |
| `--conn` / `--config` | Connection. |

```bash
gw schema main update --name ws1 --version 4.16.0 --conn "$CONN"
```

#### `schema main drop`

| Option | Description |
|--------|-------------|
| `--name` | **Required.** |
| `--yes` | **Required** to execute. |
| `--cascade` | `DROP SCHEMA … CASCADE`. |
| `--check` | SQL only. |

---

### `schema addon`

Shared satellite schemas (`utils`, `cibs`, `cm`, `am`, `audit`).

#### `schema addon create`

Bootstrap a standalone addon (no parent wiring yet).

```bash
gw schema addon create --type utils --conn "$CONN"
gw schema addon create --type cibs --name cibs --conn "$CONN"
gw schema addon create --type audit --conn "$CONN"
```

#### `schema addon integrate`

Wire an addon into one ws/ud parent. Run once per parent (e.g. integrate utils with `ws`, then again with `ud`).

| Option | Description |
|--------|-------------|
| `--type` | **Required.** `utils` \| `cibs` \| `cm` \| `am` \| `audit` |
| `--parent` | **Required.** Parent ws or ud schema name. |
| `--name` | Addon schema name (default: same as `--type`). |

```bash
gw schema addon integrate --type utils --parent ws --conn "$CONN"
gw schema addon integrate --type cibs --parent ud --conn "$CONN"
gw schema addon integrate --type audit --parent ws --conn "$CONN"
```

#### `schema addon update`

Upgrades a **standalone** addon only. If integrated in a network → use `network update`. Downgrades forbidden.

```bash
gw schema addon update --type cibs --version 4.16.0 --conn "$CONN"
```

#### `schema addon drop`

```bash
gw schema addon drop --type utils --yes --cascade --conn "$CONN"
```

#### `schema list`

Read-only inventory of schemas with `sys_version`. No superuser required.

| Option | Description |
|--------|-------------|
| `--tier` | `all` (default), `main` (ws/ud), or `addon` (utils, cibs, am, cm, audit). |
| `--type` | Repeatable filter: `ws`, `ud`, `utils`, `cibs`, `am`, `cm`, `audit`. |
| `--conn` / `--config` | Connection. |
| `--json` | Machine-readable output. |

```bash
gw schema list --conn "$CONN"
gw schema list --conn "$CONN" --tier main
gw schema list --conn "$CONN" --tier addon --type cibs --json
```

---

### `project create`

Creates a `.qgs` file from the layer metadata and styles stored in an existing
ws/ud schema. This command requires a QGIS installation with PyQGIS. The CLI
auto-detects the QGIS Python on macOS, Linux and Windows; set `QGIS_PYTHON`
only when detection fails or you need a specific install.

| Option | Description |
|--------|-------------|
| `--schema` | **Required.** Existing main schema. |
| `--type` | **Required.** `ws` \| `ud`; must match `sys_version.project_type`. |
| `--out` | **Required.** Output directory. |
| `--name` | Filename without `.qgs` (default: schema name). |
| `--export-passwd` | Store the database password in layer URIs. |
| `--force` | Overwrite an existing file. |
| `--conn` / `--config` | Connection. |

```bash
# Optional override when auto-detect is wrong:
#   macOS:   export QGIS_PYTHON=/Applications/QGIS-LTR.app/Contents/MacOS/python
#   Linux:   export QGIS_PYTHON=/usr/bin/python3   # needs python3-qgis
#   Windows: set QGIS_PYTHON=C:\OSGeo4W\bin\python-qgis.bat
gw project create --schema ws --type ws --out ./qgs --force --conn "$CONN"
```

---

### `network show`

Scans the whole database (all schemas with `sys_version`) and shows the interconnected Giswater network: ws/ud networks, shared satellites, integration links, version skew, and unlinked schemas.

| Option | Description |
|--------|-------------|
| `--flat` | Deprecated; use `schema list` instead. |
| `--schema` | Optional. Focus on the cluster containing this schema. |
| `--conn` / `--config` | Connection. |

```bash
gw network show --conn "$CONN"
gw network show --flat --conn "$CONN" --json
```

---

### `network update`

Lockstep upgrade of the discovered network. For each semver folder (e.g. 4.16.0), runs `utils → cibs → ws → ud → …` before advancing. **Downgrades forbidden** (target must be ≥ every member version).

| Option | Description |
|--------|-------------|
| `--version` | Target version (default: active dbmodel). |
| `--locale` | Default `en_US`. |
| `--check` | Print lockstep plan only. |
| `--conn` / `--config` | Connection. |

```bash
gw network update --version 4.16.0 --conn "$CONN" --check
gw network update --version 4.16.0 --conn "$CONN"
```

**E2E smoke** (linked network @ FROM, lockstep upgrade @ TO — see [Network E2E](#network-e2e-optional--release-gate)):

```bash
export CONN='postgresql://user@host:port/giswater_admin_cli'
chmod +x scripts/gw_e2e_*.sh scripts/gw_bootstrap_network.sh
./scripts/gw_e2e_network_update.sh
# or full release suite:
./scripts/gw_e2e_update_all.sh
```

Fixtures under `dbmodel/schemas/**/updates/4/16/0/` (`gw_lockstep_*`) validate cross-schema ordering.

---

### Legacy commands (deprecated)

The following still work with stderr warnings:

- **`create`** — use `schema main create` or `schema addon create` / `integrate`
- **`update`** — use `schema main update` or `schema addon update`
- **`drop`** — use `schema main drop` or `schema addon drop`
- **`status`** — use `network show --flat`
- **`init-db`** — use `db init`
- **`update-network`** — use `network update`
- **`audit structure|activate|drop`** — use `schema addon create|integrate|drop --type audit`

See the migration table at the top of this section.

---

### `manifest`

#### `manifest list`

Lists YAML files under `--dbmodel-path/manifests/`.

```bash
python3 -m giswater_admin manifest list
python3 -m giswater_admin manifest list --dbmodel-path ./dbmodel --json
```

#### `manifest validate`

Validates a manifest file.

| Argument | Description |
|----------|-------------|
| `path` | Path to `<kind>.yaml` |

```bash
python3 -m giswater_admin manifest validate dbmodel/manifests/ws.yaml
python3 -m giswater_admin manifest validate dbmodel/manifests/ws.yaml --json
```

---

### End-to-end example (ws + ud + utils)

```bash
set -e
export CONN='postgresql://gisadmin:secret@127.0.0.1:5432/giswater_cli'

gw db init --conn "$CONN"
gw schema main create --type ws --name ws_test --profile sample --conn "$CONN"
gw schema main create --type ud --name ud_test --profile sample --conn "$CONN"
gw schema addon create --type am --profile empty --conn "$CONN"
gw schema addon create --type am --profile sample --conn "$CONN"
gw schema addon integrate --type am --parent ws_test --conn "$CONN"
gw schema addon integrate --type am --profile sample --parent ws_test --conn "$CONN"
gw network show --flat --conn "$CONN" --json | python3 -m json.tool
```

---

## Kinds and manifest profiles

| `kind` | Typical profiles | Notes |
|--------|------------------|-------|
| **ws** | `empty`, `sample_full`, `sample_inv`, `dev`, `update` | Water supply. Updates: `schemas/main/common/updates` then `schemas/main/ws/updates`. |
| **ud** | same as ws | Sewerage. Updates: common then `schemas/main/ud/updates`. |
| **utils** | `empty`, `integrate_ws`, `integrate_ud`, `copy_data`, `update` | Standalone create; integrate ws/ud separately; version in `utils.sys_version`. |
| **am** | `empty`, `sample`, `integrate`, `integrate_sample`, `update` | WS parent only; singleton; create then integrate |
| **cm** | `bootstrap`, `integrate`, `update` | Bootstrap standalone, then `schema addon integrate --parent …` |
| **audit** | `empty`, `integrate`, `update` | Same flow as other addons via `schema addon create|integrate`. |

**ws/ud profiles** (from [manifests/ws.yaml](../dbmodel/manifests/ws.yaml)):

| Profile | Phases (summary) |
|---------|------------------|
| `empty` | `load_base` → `updates` → `lastprocess` → `final_pass` |
| `sample_full` | … → `load_sample` → `final_pass` (CLI `--profile sample`; pgTAP bootstrap) |
| `sample_inv` | … → `load_sample` → `load_inv` → `final_pass` |
| `dev` | … → `load_dev` → `final_pass` |
| `update` | `reload_fct_ftrg` → `updates` → `lastprocess_upgrade` |

Details and folder layout: [dbmodel README — Schema architecture](../dbmodel/README.md#schema-architecture).

---

## Timing and output

| Stream | Content |
|--------|---------|
| **stdout** | Final result (YAML or JSON with `--json`). |
| **stderr** | Progress (`log_format.py`), warnings, errors; `-v`/`-d` add per-file lines. |

Example stderr with `-v --timing`:

```text
── Schema build: ws / gw_ws_test  profile=empty  v4.9.0 ──
[581/723]  phase  updates
[581/723]   1.2s  ws/updates/4/2/0/dml.sql
── Done  10.4s  723 files ──
  updates              7.1s  (612 files, 68.0%)
Slowest:
   3241ms  updates  ws/updates/4/2/0/dml.sql
```

Paths are shortened using `--dbmodel-path` as the root prefix.

```bash
# Slow SQL files during create
python3 -m giswater_admin create --kind ws --schema gw_ws_test --profile empty \
  --timing --timing-top 30 -v --timing-threshold-ms 30 \
  --conn "$CONN" 2>&1 | tee /tmp/gw_create_timing.log

# JSON timing for jq
python3 -m giswater_admin create --kind ws --schema gw_ws_test --profile empty \
  --timing --timing-detail --json --conn "$CONN" 2>/dev/null | \
  jq '.timing.slowest_by_phase.updates[:20]'
```

Timing is **per SQL file** only (not per PL/pgSQL function step).

---

## QGIS integration

The plugin builds `BuildParams`, runs `SchemaBuilder` in `core/threads/schema_builder_task.py` via `QtDbAdapter`, and can show the same formatted progress in the **Giswater PY** log. After a build, `summarize_build()` from `engine/timing_report.py` feeds the create-project dialog timing label.

---

## Unit tests

No Docker required:

```bash
# From plugin repo root
python3 -m pytest test/cli test/engine -v
```

Optional smoke tests against a real cluster (skipped without `PGSERVICE` / `PGDATABASE`):

```bash
PGSERVICE=localhost_giswater python3 -m pytest test/engine/smoke -v
```

Database integration tests: [dbmodel/README.md#testing](../dbmodel/README.md#testing).

---

## Extending the model

1. Add or edit `dbmodel/manifests/<kind>.yaml`.
2. For a new `kind`, register it in `giswater_admin/cli.py` (`--kind` choices and command validation if needed).
3. Validate: `python3 -m giswater_admin manifest validate dbmodel/manifests/<kind>.yaml`.

Supported phase types: `sql_dir`, `version_walk` (`root:` or `roots:`), `sql_file`, `sql_function`, `sql_inline`. `dir_walk` is deprecated.

---

## Keeping docs in sync

When you add or change CLI flags, update **both** `giswater_admin/cli.py` and this README (global options + affected subcommand tables). A future improvement could dump `argparse` help in CI; that is not automated yet.
