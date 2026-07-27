<div align="center">
	<h1>Giswater DB Model</h1>
	<a href="https://github.com/giswater/giswater_dbmodel"><img alt="Giswater Dbmodel Badge" src="https://img.shields.io/badge/GISWATER-DBMODEL-blue?style=for-the-badge&logo=postgresql&logoColor=ffffff"></a>
	<a href="./LICENSE"><img alt="LICENSE" src="https://img.shields.io/github/license/giswater/giswater_dbmodel?style=for-the-badge"></a>
</div>

PostgreSQL schema definitions, versioned update patches, and pgTAP tests for Giswater. Builds are driven by YAML manifests and the headless CLI [`giswater_admin`](../giswater_admin/README.md) (same engine as the QGIS plugin).

**See also:** [giswater-admin CLI reference](../giswater_admin/README.md)

## Table of Contents

1. [Schema architecture](#schema-architecture)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [Testing](#testing)
5. [Deployment](#deployment)
6. [Wiki](#wiki)
7. [FAQ](#faqs)
8. [Repositories](#repositories)
9. [Versioning](#versioning)
10. [License](#license)
11. [Acknowledgements](#acknowledgements)

---

## Schema architecture

Giswater uses **project schemas** (`ws`, `ud`) plus **satellite schemas** (`utils`, `am`, `cm`, `audit`, `cibs`). The `dbmodel/` tree separates **orchestration** (manifests) from **SQL sources** (`schemas/`). Folders under `schemas/main/common/` are not a database schema—they are SQL applied **into** both `ws` and `ud` project schemas.

### Repository layout

```
dbmodel/
├── manifests/              # YAML: phases + profiles per kind (ws, ud, utils, …)
├── schemas/
│   ├── main/               # Network project schemas (ws, ud)
│   │   ├── common/         # Shared SQL → loaded into ws AND ud (not a PG schema)
│   │   ├── ws/             # Water-supply–specific SQL
│   │   └── ud/             # Sewerage-specific SQL
│   └── addon/              # Satellite schemas
│       ├── utils/
│       ├── am/
│       ├── cm/
│       ├── audit/
│       └── cibs/
├── corporate/              # Optional corporate/custom overlays (outside manifests)
└── test/                   # pgTAP sources + Docker harness
```

Each **main** project folder (`ws/`, `ud/`) typically contains:

| Subfolder | Role |
|-----------|------|
| `base/` | Bootstrap SQL: `fct/`, `ftrg/`, `schema_model/` (common also has `init.sql`) |
| `updates/` | Semver patches (`M/m/p/patch.sql`) |
| `sample/` | Optional seed data (`user/`, `inv/`, `dev/`) |
| `catalog/` | Locale-specific feature catalog (`<locale>/cat_feature.sql`) |
| `final_pass/` | Form fields + i18n (locale folders) |

Each **addon** kind follows a similar pattern: `base/`, `integration/` (parent-link SQL), `updates/`, and optional `sample/` or `i18n/`.

### Schemas vs folders

| PostgreSQL schema | Type | Base folder | Updates (semver `M/m/p`) |
|-------------------|------|-------------|---------------------------|
| `ws` | project | [`schemas/main/ws/`](./schemas/main/ws/) | `schemas/main/common/updates/` **then** `schemas/main/ws/updates/` (interleaved per version) |
| `ud` | project | [`schemas/main/ud/`](./schemas/main/ud/) | `schemas/main/common/updates/` **then** `schemas/main/ud/updates/` |
| `utils` | satellite | [`schemas/addon/utils/`](./schemas/addon/utils/) | `schemas/addon/utils/updates/` |
| `am` | satellite | [`schemas/addon/am/`](./schemas/addon/am/) | `schemas/addon/am/updates/` |
| `cm` | satellite | [`schemas/addon/cm/`](./schemas/addon/cm/) | `schemas/addon/cm/updates/` |
| `audit` | satellite | [`schemas/addon/audit/`](./schemas/addon/audit/) | `schemas/addon/audit/updates/`; bootstrap via `structure` / `activate` profiles |
| `cibs` | satellite | [`schemas/addon/cibs/`](./schemas/addon/cibs/) | `schemas/addon/cibs/updates/` |

[`schemas/main/common/`](./schemas/main/common/) — functions, triggers, and shared update patches used by **both** `ws` and `ud`.  
[`schemas/main/{ws,ud}/sample/`](./schemas/main/ws/sample/) — Seed scripts (`user/`, `inv/`, `dev/`) referenced by optional manifest phases.

### How manifests drive a build

```mermaid
sequenceDiagram
  participant CLI as giswater_admin_create
  participant M as manifests/ws.yaml
  participant B as SchemaBuilder
  participant SQL as schemas/main
  CLI->>M: profile=empty|sample|inventory|...
  M->>B: ordered phases
  B->>SQL: sql_dir / version_walk / sql_function
```

Example **ws** pipeline ([`manifests/ws.yaml`](./manifests/ws.yaml)):

| Phase | Type | What runs |
|-------|------|-----------|
| `load_base` | `sql_dir` | `common/base/init.sql`, `common/base/fct`, `common/base/ftrg`, then `ws/base/fct`, `ws/base/ftrg`, `ws/base/schema_model` |
| `updates` | `version_walk` | For each version ≤ `--plugin-version`: **common** patches, then **ws** patches |
| `load_catalog` | `sql_dir` | `catalog/{{ locale }}` (fallback `en_US`) — feature naming conventions |
| `lastprocess` | `sql_function` | `gw_fct_admin_schema_lastprocess` (child views, permissions, metadata) |
| `load_sample` | `sql_dir` (optional) | `schemas/main/ws/sample/user` |
| `final_pass` | `sql_dir` | Form fields + i18n (`{{ locale }}`, fallback `en_US`) |

**Upgrade profile** (`update`): `reload_fct_ftrg` → `updates` (only `project_version < v <= plugin_version`) → `lastprocess_upgrade`.

### Phase types (engine)

Defined in [`giswater_admin/engine/manifest.py`](../giswater_admin/engine/manifest.py):

| Type | Purpose |
|------|---------|
| `sql_dir` | All `*.sql` in listed paths (alphabetical; `recursive` optional) |
| `version_walk` | Semver folders under `updates/`; `roots:` lists multiple trees (ws/ud) |
| `sql_function` | `SELECT schema.fn($${JSON}$$)` |
| `sql_file` | Single file + optional `fallback_source` |
| `sql_inline` | Literal SQL in YAML |

### Template substitutions

| Layer | Tokens | Example |
|-------|--------|---------|
| File content | `SCHEMA_NAME`, `SRID_VALUE`, `AUX_SCHEMA_NAME`, `PARENT_SCHEMA` (cm) | Replaced in every `.sql` file |
| Manifest YAML | `{{ schema_name }}`, `{{ plugin_version }}`, `{{ locale }}`, … | From `BuildParams.as_ctx()` |

Authors can use either layer depending on the file.

### Network harmony: common + ws/ud

```mermaid
flowchart LR
  subgraph load_base [load_base]
    Cbase[common/base init fct ftrg]
    K[ws or ud base fct ftrg schema_model]
    Cbase --> K
  end
  subgraph updates [updates per version]
    Cu[common/updates/M/m/p]
    Ku[ws or ud/updates/M/m/p]
    Cu --> Ku
  end
  subgraph finish [post-updates]
    LP[lastprocess]
    FP[final_pass]
  end
  load_base --> updates
  updates --> LP
  LP --> FP
```

- **One codebase, two project schemas:** shared logic lives in `common/`; type-specific pieces in `ws/` or `ud/`.
- **Version order:** for each `M.m.p`, the engine applies **all** `common` SQL for that version, then **all** `ws` or `ud` SQL for that version, before moving to the next version.
- **`lastprocess`:** server-side bookkeeping (child views, role grants batched at end of MULTI-CREATE, sequences, mapzone defaults).
- **`sample/`:** only when the manifest profile includes `load_sample`, `load_inv`, or `load_dev`. Lives under each project type (`schemas/main/ws/sample/`, `schemas/main/ud/sample/`), like `final_pass/`.

### Version walk rules

Filtered using `sys_version.giswater` (`project_version`) and CLI `--plugin-version`:

| `run_mode` | Patches applied |
|------------|-----------------|
| `new_project` | Every patch with `v <= plugin_version` |
| `upgrade` | Patches with `project_version < v <= plugin_version` |

**Satellite** schemas (utils, am, cm, audit, cibs): one updates root per kind:

```
schemas/addon/<kind>/updates/<major>/<minor>/<patch>/patch.sql
```

**Update patches** for new version bumps use a single `patch.sql` per scope (replacing the legacy split across `ddl.sql`, `dml.sql`, `ddlview.sql`, `trg.sql`, …). Older consolidated history may still appear as large `patch.sql` files from the migration.

**Changelogs** sit beside each version folder (`changelog.txt`). Network schemas use up to three scopes per version: `schemas/main/common/updates/<M>/<m>/<p>/` (shared), plus `ws/updates/...` or `ud/updates/...` for type-specific changes. Prefer bullets only (`- change description`); legacy headers (`M.m.p` + asterisks) still parse. The plugin **Manage Schemas** dialog and `giswater_admin update --check` merge scopes via `giswater_admin.engine.changelog`. Historical unified `dbmodel/updates/` content was consolidated under `schemas/main/common/updates/<v>/`.

### AM legacy patches

`am` once used calendar folders `am/updates/<YYYY-MM>/`. Historical SQL was collapsed into `schemas/addon/am/updates/0/0/0/` with date-prefixed filenames. New patches use normal semver folders.

### AM layout (WS-only parent link)

| Path | Role |
|------|------|
| `schemas/addon/am/base/` | Core `am` DDL + `fct/` (incl. version register) |
| `schemas/addon/am/integration/ws/` | **Only** WS integration (`integration.sql`, `sample.sql`) |
| `schemas/addon/am/integration/common/fct/` | Trigger functions installed on the parent WS schema |
| `schemas/addon/am/final_pass/i18n/` | Locale folders (fallback `en_US`) |
| `schemas/addon/am/sample/user/` | Optional am-side sample (leaks, …) |

AM is a **singleton** satellite: one `am` schema per database, linked to **one WS parent** (parent type from `sys_version.project_type`, not schema name). Create and integrate are separate steps (Manage Schemas or CLI).

```bash
gw schema addon create --type am --profile empty --conn "$CONN"
gw schema addon create --type am --profile sample --conn "$CONN"
gw schema addon integrate --type am --parent <ws_schema> --conn "$CONN"
gw schema addon integrate --type am --profile sample --parent <ws_schema> --conn "$CONN"
```

### CM layout (parent-linked)

| Path | Role |
|------|------|
| `schemas/addon/cm/base/` | Core `cm` DDL + `fct/` + `ftrg/` |
| `schemas/addon/cm/integration/common/` | Shared parent-link SQL |
| `schemas/addon/cm/integration/ws` \| `ud/` | Type-specific integration hooks |
| `schemas/addon/cm/final_pass/i18n/` | Locale folders (fallback `en_US`) |
| `schemas/addon/cm/sample/` | Optional seed catalogues |

Prerequisite: parent `ws` or `ud` project already created. CLI: `create --kind cm --parent-schema <parent> [--parent-type ws|ud]`.

### Satellite schemas (utils, am, cm, audit, cibs)

| Kind | Create requirements |
|------|---------------------|
| **utils** | Standalone create; integrate each parent with `--ws-schema` / `--ud-schema` |
| **am** | Create (`empty`\|`sample`); integrate WS parent separately; singleton |
| **cm** | `--parent-schema` + `--parent-type ws\|ud` |
| **audit** | `structure` profile once; `activate` per parent project |
| **cibs** | Standalone create; `integrate` profile wires parent ws/ud |

pgTAP bootstrap uses `create --profile sample` on `ws` or `ud` — see [Testing](#testing).

---

## Requirements

| Component | Notes |
|-----------|--------|
| **PostgreSQL** | **16, 17, or 18** (aligned with CI and Docker images). |
| **PostGIS / pgRouting** | Server packages matching PG major; created via [`giswater_admin init-db`](../giswater_admin/README.md#init-db). |
| **Python 3.9+** | For CLI and test harness (`PyYAML`, `psycopg2-binary`). |
| **Docker** | For local pgTAP runs (see [Testing](#testing)). |
| **QGIS** | Frontend only (not required for CLI or db tests). |

---

## Installation

Giswater is client–server: backend (PostgreSQL + schemas) and frontend (QGIS plugin).

### Backend

1. Install PostgreSQL 16–18 with PostGIS and pgRouting on the **server**.
2. Create an empty database.
3. From the plugin repo root:

```bash
pip install -r giswater_admin/requirements.txt
export CONN='postgresql://user:pass@127.0.0.1:5432/mydb'
python3 -m giswater_admin init-db --conn "$CONN"
python3 -m giswater_admin create --kind ws --schema ws_demo --srid 25831 --profile empty --conn "$CONN"
```

Extensions created by `init-db`: `postgis`, `postgis_raster`, `tablefunc`, `pgrouting`, `unaccent`.

### Frontend

- QGIS LTR, Giswater plugin, EPANET/SWMM as needed (EPA tools mainly on Windows).

---

## Testing

pgTAP tests run in Docker: a `postgres` service plus a `runner` container that calls `giswater_admin` and `pg_prove`. No host PostgreSQL port is required by default.

### Prerequisites

- [ ] **Docker Desktop** (or Docker Engine) running — `docker info` must succeed.
- [ ] **bash** (macOS, Linux, WSL). Same script everywhere; only pitfall is CRLF on `*.sh` if an editor saves Windows line endings.
- [ ] Run from **plugin repo root** or `dbmodel/`.
- [ ] On **Apple Silicon**, images are `linux/amd64` (emulation); first `PG_MAJOR` build can take several minutes.

### Quick start

```bash
# From plugin repo root (recommended)
./dbmodel/test/run_tests.sh ws          # PostgreSQL 16 (default)
PG_MAJOR=17 ./dbmodel/test/run_tests.sh ws
PG_MAJOR=18 ./dbmodel/test/run_tests.sh ud

# From dbmodel/
./test/run_tests.sh ws
```

`PG_MAJOR=18` uses PostGIS **3.6**; 16 and 17 use **3.5**.

### CI (PostgreSQL Tests)

On every PR/push touching `dbmodel/**`, GitHub Actions runs **21 checks** (6 lanes × PG 16/17/18):

| Lane | What |
|------|------|
| pgTAP ws / ud | `--profile sample` + full pgTAP |
| profiles empty+inventory | create smoke ws+ud |
| update isolated | penúltimo→último patch ws+ud |
| pgTAP satellites | utils + cibs standalone |
| pgTAP network | integrated sample + network pgTAP |

Release (`prepare_*_release.py --execute`) calls `scripts/verify_dbmodel_ci_checks.sh` before tagging. Plugin release also runs network lockstep via Actions.

### Network E2E (manual)

CLI lifecycle tests (release gate: isolated upgrade + network lockstep; optional profiles/addons) and satellite pgTAP:

```bash
./dbmodel/test/run_e2e.sh update_all       # release gate suite
./dbmodel/test/run_satellite_tests.sh cibs # pgTAP on cibs schema
./dbmodel/test/run_satellite_tests.sh network_ws
```

See [giswater_admin README — Network E2E](../giswater_admin/README.md#network-e2e-optional--release-gate).

### Environment variables

| Variable | Default | Effect |
|----------|---------|--------|
| `PG_MAJOR` | `16` | Postgres image / client major (`16`, `17`, `18`) |
| `POSTGIS_VERSION` | `3.5` (`3.6` for PG 18) | PostGIS image tag |
| `TEST_GROUPS` | `all` | `schema`, `security`, `function`, `data`, `performance`, or `all` |
| `PG_PROVE_JOBS` | `4` | Parallelism; **forced to `1`** for `function` and `data` groups (schema mutations) |
| `GW_VERBOSE` | — | Passes `-v` to `giswater_admin` |
| `GW_DEBUG` | — | Passes `-d` |
| `GW_TIMING` | — | Passes `--timing` |
| `GW_TIMING_TOP` | — | `--timing-top` |
| `GW_TIMING_THRESHOLD_MS` | — | `--timing-threshold-ms` |
| `GW_TIMING_DETAIL` | — | `--timing-detail` |
| `GW_CLEAN` | — | Remove Docker volumes on exit |
| `GW_DUMP_PATH` | — | After success, write `pg_dump` to this path |
| `GW_SCHEMA_DUMP` | — | Restore path for CI-style restore jobs |

### Local workflow

```mermaid
flowchart LR
  subgraph host [Host]
    R[run_tests.sh]
  end
  subgraph compose [Docker network]
    PG[postgres gw-ci]
    RUN[runner]
    R --> RUN
    RUN --> PG
  end
  subgraph inner [run_tests_inner.sh]
    B[bootstrap_inner.sh]
    P[prove_inner.sh]
    B --> P
  end
  RUN --> inner
```

**Bootstrap** (`bootstrap_inner.sh`):

1. `giswater_admin init-db`
2. `drop` + `create --profile sample` → schema `ws_40` or `ud_40`
3. `replace_vars.py` → copies `test/ws` or `test/ud` to `test/.run/{ws,ud}/` (only placeholders `SCHEMA_NAME`, `SRID_VALUE` resolved; **sources never modified**)

**Prove** (`prove_inner.sh`): runs pgTAP for one `TEST_GROUPS` value against the staging tree.

```bash
TEST_GROUPS=function ./dbmodel/test/run_tests.sh ws
GW_CLEAN=1 ./dbmodel/test/run_tests.sh ws
GW_VERBOSE=1 GW_TIMING=1 GW_TIMING_TOP=50 PG_MAJOR=17 ./dbmodel/test/run_tests.sh ws
GW_DEBUG=1 ./dbmodel/test/run_tests.sh ws
```

Inside Docker, Postgres is always `127.0.0.1:5432` on the compose network. A warning about host port **55432** refers to a possible legacy local cluster; tests do not use it unless you opt into debug compose.

### Troubleshooting

| Symptom | Action |
|---------|--------|
| `env: 'bash\r'` or `set: pipefail: invalid option` | Windows CRLF on `test/*.sh`. Host: `sed -i 's/\r$//' dbmodel/test/*.sh`. Runner strips `\r` in-container — **rebuild** after pull: `docker compose -f docker-compose.test.yml build runner` |
| `500 Internal Server Error` on `docker.sock/_ping` | Start or restart Docker Desktop; wait until `docker info` works |
| Stale volume / odd failures | `GW_CLEAN=1 ./dbmodel/test/run_tests.sh ws` |
| `schema ws_40 already exists` | Bootstrap drops first; if stuck, `GW_CLEAN=1` |
| Deadlocks in function tests | `prove_inner.sh` uses `-j 1` for FUNCTION/DATA by design |

### CI workflow (`.github/workflows/test-db.yml`)

```mermaid
flowchart LR
  PM[pgtap-main 6] --> Art[schema dump artifact]
  PS[profiles-smoke 3]
  UI[update-isolated 3]
  SAT[pgtap-satellites 3]
  NET[pgtap-network 3]
  PM --> Pub[publish-gw-db main/tags]
```

| Job | Matrix | Steps |
|-----|--------|-------|
| `pgtap-main` | `ws/ud` × PG 16/17/18 (6) | bootstrap sample → pgTAP all groups → dump → artifact |
| `profiles-smoke` | PG 16/17/18 (3) | empty + inventory create ws/ud |
| `update-isolated` | PG 16/17/18 (3) | isolated ws/ud upgrade (`latest released → metadata.txt`) |
| `pgtap-satellites` | PG 16/17/18 (3) | **after main lanes** — ws_40+ud_40 then utils/cibs pgTAP |
| `pgtap-network` | PG 16/17/18 (3) | **after satellites** — integrated sample network pgTAP |
| `publish-gw-db` | ws/ud × PG (6, main/tags) | Build `ghcr.io/giswater/gw-db:…` from pgtap-main dump |

**21 checks** on PR (5 lanes × 3 PG + 6 pgTAP project splits). Each pgTAP job runs all test groups in one step (`TEST_GROUPS=all`).

`workflow_dispatch` inputs: `lane` (all or one lane), `pg_version`, `build_image`.

### Test harness files

| File | Role |
|------|------|
| [`test/run_tests.sh`](./test/run_tests.sh) | Host: `docker compose` orchestration |
| [`test/run_tests_inner.sh`](./test/run_tests_inner.sh) | Container: bootstrap → all groups → optional dump |
| [`test/bootstrap_inner.sh`](./test/bootstrap_inner.sh) | `init-db` + `create --profile sample` + `replace_vars` |
| [`test/ci_lifecycle_inner.sh`](./test/ci_lifecycle_inner.sh) | CI lanes: profiles, update, satellites, network |
| [`test/bootstrap_parents_inner.sh`](./test/bootstrap_parents_inner.sh) | `db init` + ws_40/ud_40 parents (before addons) |
| [`test/bootstrap_addon_inner.sh`](./test/bootstrap_addon_inner.sh) | addon create (requires parents) + `replace_vars` |
| [`test/restore_inner.sh`](./test/restore_inner.sh) | `init-db` + roles + `pg_restore` from `GW_SCHEMA_DUMP` |
| [`test/prove_inner.sh`](./test/prove_inner.sh) | One `TEST_GROUPS`; `-j 1` for function/data |
| [`test/dump_schema.sh`](./test/dump_schema.sh) | `pg_dump -n {schema}` |
| [`test/replace_vars.py`](./test/replace_vars.py) | Staging copy for pgTAP |
| [`test/e2e_versions.py`](./test/e2e_versions.py) | E2E upgrade path: `PLUGIN_VER` (CHANGELOG latest release) → `TARGET_VER` (`metadata.txt`) |
| [`test/plugin_version.py`](./test/plugin_version.py) | Max semver folder under `schemas/main/*/updates/` (pgTAP bootstrap) |
| [`test/diagnose_db.sh`](./test/diagnose_db.sh) | Optional host `psql` via debug compose |

E2E upgrade versions (same semantics as `gw schema main update` without `--version`):

```bash
python3 dbmodel/test/e2e_versions.py
# TARGET_VER=4.15.0
# PLUGIN_VER=4.14.4
```

Max update folder semver (pgTAP bootstrap):

```bash
python3 dbmodel/test/plugin_version.py
```

### Optional: host psql against test DB

```bash
cd dbmodel
docker compose -f docker-compose.test.yml -f docker-compose.debug.yml up -d postgres
GW_PUBLISH_PORT=15432 ./test/diagnose_db.sh
```

Published images: `ghcr.io/giswater/gw-db:main-pg16-ws` (and `ud`, PG 17/18).

### Tutorials

1. [Install plugin](https://www.youtube.com/watch?v=EwDRoHY2qAk&list=PLQ-seRm9Djl4hxWuHidqYayHEk_wsKyko&index=4)
2. [Setup connection](https://www.youtube.com/watch?v=LJGCUrqa0es&list=PLQ-seRm9Djl4hxWuHidqYayHEk_wsKyko&index=3)
3. [Create DB schema example](https://www.youtube.com/watch?v=nR3PBtfGi9k&list=PLQ-seRm9Djl4hxWuHidqYayHEk_wsKyko&index=2)
4. [Create QGIS project](https://www.youtube.com/watch?v=RwFumKKTB2k&list=PLQ-seRm9Djl4hxWuHidqYayHEk_wsKyko&index=1)

---

## Deployment

### Prerequisites

- PostgreSQL access with privileges to create schemas, roles, and extensions (superuser or equivalent for `init-db`).

### Mandatory project setup

- Catalogs: materials, node, arc.
- Map zones: macroexploitation, municipality, sector, dma, etc.

- [Start from scratch](https://github.com/giswater/plugin/wiki/Start-from-Scratch:-Installing-Giswater-and-steps-to-create-an-empty-project)
- [Configuration guide](https://github.com/giswater/plugin/wiki/Config)

---

## Wiki

[ Giswater Wiki](https://github.com/giswater/plugin/wiki)

---

## FAQs

[FAQs](https://github.com/giswater/plugin/wiki/FAQs)

---

## Repositories

- **Docs**: [Giswater Docs](https://github.com/giswater/docs)
- **QGIS Plugin**: [Giswater QGIS Plugin](https://github.com/giswater/plugin)
- **Database Model**: [Giswater DB Model](https://github.com/giswater/giswater_dbmodel)
- **CLI (in plugin repo)**: [giswater_admin/README.md](../giswater_admin/README.md)

---

## Versioning

Giswater uses **Major**, **Minor**, and **Patch** (Build) releases:

- **Major**: architectural changes (may break compatibility)
- **Minor**: features and fixes (backward compatible)
- **Patch**: small fixes

SQL patches under `schemas/main/*/updates/<M>/<m>/<p>/` and `schemas/addon/*/updates/<M>/<m>/<p>/` follow plugin semver caps via `--plugin-version`.

---

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE).

---

## Acknowledgements

Special thanks to the following partners for their contributions:

- GITS-BarcelonaTech University
- Aigües de Mataró
- Aigües de Girona
- Aigües de Blanes
- Aigües del Prat
- Aigües de Vic
- Aigües de Castellbisbal
- Aigües de Banyoles
- Figueres de Serveis, S.A
- Prodaisa
- Sabemsa
- Consorci Aigües de Tarragona
