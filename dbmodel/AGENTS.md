# AGENTS.md — dbmodel

PostgreSQL data model for Giswater. Read the root [AGENTS.md](../AGENTS.md) first for repo-wide context.

Most Giswater business logic lives here, not in Python. The plugin sends JSON to a `gw_fct_*` function and renders whatever JSON comes back, so behaviour changes usually mean editing SQL in this folder.

Authoritative companion docs, kept in sync with this one: [info.txt](info.txt) (SQL change rules), [README.md](README.md) (architecture and build), [MAINTENANCE.md](MAINTENANCE.md), [BREAKING-CHANGES-GUIDE.md](BREAKING-CHANGES-GUIDE.md).

## Layout

```
dbmodel/
  manifests/          YAML build pipelines: ws, ud, utils, am, cm, audit, cibs, multilang, publi
  schemas/
    main/             Network project schemas
      common/         SQL loaded into BOTH ws and ud. NOT a PG schema by itself
      ws/             Water supply specific
      ud/             Urban drainage specific
    addon/            Satellite schemas: utils, am, cm, audit, cibs, multilang, publi
  test/               pgTAP suites + Docker harness
  docker/             Postgres and runner images used by the tests
  tools/              Admin utilities and one-off migrations
  corporate/          Client overlays, outside every manifest
  dev/                Legacy and experimental SQL, not built
```

Everything under `corporate/` and `dev/` is dead weight for a normal task; never load it and never "fix" it.

### Inside a network schema (`schemas/main/{common,ws,ud}`)

```
base/
  init.sql          bootstrap, roles, extensions (common only)
  fct/              one file per function      -> gw_fct_*
  ftrg/             one file per trigger function -> gw_trg_*
  schema_model/     base DDL, ws/ud only, seven numbered files:
                      01_ddl_basic  02_ddl_pkey  03_ddlview  04_dml
                      05_fkey       06_index     07_trg
updates/
  <M>/<m>/<p>/
    patch.sql       all SQL for that version bump, one file per scope
    changelog.txt
catalog/<locale>/   cat_feature.sql, locale feature naming for empty projects
sample/{user,inv,dev}/
final_pass/
  config_form_fields/
  config_form_tableview/
  i18n/<locale>/
```

### Inside an addon (`schemas/addon/<kind>`)

Same shape plus `integration/` holding the parent-link SQL, split into `common/` and `ws/` or `ud/` hooks. Addons walk a single `updates/` tree; there is no common/type split.

## Where a change goes

This is the part agents get wrong most often.

| Change | Destination |
|---|---|
| Function or trigger function body | Edit the original in `base/fct/` or `base/ftrg/`. One definition, one file. Version differences go inside the body with `IF`, not in a patch |
| New table, column, index, constraint, rule, trigger | `updates/<M>/<m>/<p>/patch.sql` in the correct scope |
| View change | `updates/.../patch.sql` with `CREATE OR REPLACE VIEW`. Never edit `schema_model/03_ddlview_*.sql` for a bump |
| DML / seed data | `updates/.../patch.sql`, using `ON CONFLICT (pk) DO NOTHING` on system tables |
| Locale feature names | `schemas/main/{ws,ud}/catalog/<locale>/cat_feature.sql` |
| UI strings and form i18n | `final_pass/i18n/<locale>/` |

Rules that are non-negotiable ([info.txt](info.txt)):

- **Never modify `schema_model/` for a version bump.** It is the bootstrap of a fresh schema; existing installations never re-run it.
- `DROP` on tables and sequences is **forbidden**. Deprecate instead: `UPDATE audit_cat_table SET isdeprectaded = TRUE` (also `audit_cat_function`, `audit_cat_sequence`).
- `DROP CASCADE` on views is forbidden. Plain `DROP` is allowed if documented in `changelog.txt`.
- Constraints and triggers in patches: `DROP ... IF EXISTS ... CASCADE` before recreating.
- Tables and sequences in patches: `CREATE TABLE|SEQUENCE IF NOT EXISTS`.
- New fields go through the helper, not raw `ALTER TABLE`:

```sql
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"config_web_fields",
  "column":"table_type", "dataType":"text"}}$$);
```

### Scope: common vs ws vs ud

For version `M.m.p` the engine applies, per version, in order:

1. `schemas/main/common/updates/M/m/p/patch.sql`
2. `schemas/main/{ws|ud}/updates/M/m/p/patch.sql`

A single logical change often needs **both**: the shared part in `common`, the type-specific part in `ws` and `ud`. Each scope carries its own `changelog.txt`; the Manage Schemas dialog and `gw schema main update --check` merge them for display.

`changelog.txt` format: one bullet per line starting with `- `, and an issue reference is mandatory. Open a GitHub issue if none exists.

## The `functions/` mirror

`schemas/main/common/functions/fct` and `.../functions/ftrg` (and the same under `ws/` and `ud/`) duplicate `base/fct` and `base/ftrg` file for file — 231 files on each side for common.

**`base/` is authoritative.** No manifest references `functions/` (verified across every file in `manifests/`) and no Python reads it. It is a legacy mirror that is currently kept in sync by hand.

If you edit a function, edit `base/`. Mirror the change into `functions/` only to keep the trees identical; never treat `functions/` as the source of truth, and never let the two diverge. This duplication is a known wart and a candidate for removal.

## Function contract

Every API function follows the same shape:

```sql
--FUNCTION CODE: 2796

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_getselectors(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
```

- **Header comment** carries the function code, matching the row in `config_function`. `gw_fct_json_create_return()` uses it to attach `returnManager`, `layerManager` and `actions` to the response.
- **Example block** right after `AS $function$`: every function file documents at least one runnable call in a `/*example ... */` comment. Keep it working and update it when the payload changes; it is the fastest way to test by hand.

Input keys, all optional except `data` in practice:

```sql
SELECT SCHEMA_NAME.gw_fct_getselectors($${
  "client":{"device":4, "lang":"en_US", "infoType":1, "epsg":SRID_VALUE},
  "form":{"currentTab":"tab_exploitation"},
  "feature":{},
  "data":{"filterFields":{}, "pageInfo":{}, "selectorType":"selector_basic", "filterText":""}
}$$);
```

Read them with `p_data->'data'->>'selectorType'` or `json_extract_path_text(p_data, 'data', 'action')`.

Success returns go through the wrapper, with the function code as second argument:

```sql
RETURN gw_fct_json_create_return(('{"status":"Accepted", "version":"'||v_version||'"'||
    ',"body":{"message":'||v_message||
    ',"form":{...}'||
    ',"feature":{}'||
    ',"data":{...}}'||
  '}')::json, 2796, null, null, v_action::json);
```

Failures return a flat object from the `EXCEPTION WHEN OTHERS` block:

```sql
RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'version', v_version,
  'SQLSTATE', SQLSTATE, 'MSGERR', (v_msgerr::json ->> 'MSGERR'))::json;
```

The Python side keys off `status`, so a function that raises without this block surfaces as an opaque crash in QGIS.

## Build-time placeholders

SQL files are templates. The runner substitutes before execution:

| Placeholder | Replaced with |
|---|---|
| `SCHEMA_NAME` | target schema (`ws_40`, `mydemo`, ...) |
| `SRID_VALUE` | project SRID |
| `AUX_SCHEMA_NAME` | auxiliary schema |
| `PARENT_SCHEMA` | parent schema when integrating an addon |

Never hardcode a schema name or SRID, including in the example comments.

## Manifests

[manifests/ws.yaml](manifests/ws.yaml) drives the whole build; the phases execute in file order:

| Phase | Type | Does |
|---|---|---|
| `load_base` | `sql_dir` | `common/base/init.sql`, `common/base/{fct,ftrg}`, `ws/base/{fct,ftrg}`, `ws/base/schema_model` |
| `reload_fct_ftrg` | `sql_dir` | re-apply functions and triggers only; first phase of an upgrade |
| `updates` | `version_walk` | roots `common/updates` then `ws/updates`; `new_project` applies all `v <= plugin_version`, `upgrade` applies `project_version < v <= plugin_version` |
| `load_catalog` | `sql_dir` | `catalog/{{ locale }}` with `en_US` fallback |
| `lastprocess` | `sql_function` | `gw_fct_admin_schema_lastprocess`: grants from `audit_cat_*`, FKs against utils, drops deprecated objects (new projects only) |
| `load_sample` / `load_inv` / `load_dev` | `sql_dir` | optional seed profiles |
| `final_pass` | `sql_dir` | `config_form_fields`, `config_form_tableview`, `i18n/{{ locale }}` |

Adding a new SQL directory means adding a step to the manifest; a file that is not reachable from a manifest is simply never executed.

## Tests

pgTAP suites live in `test/<kind>/` (`ws`, `ud`, `utils`, `cibs`, `publi`, `network`), grouped into `schema/`, `function/`, `data/`, `security/`, `performance/`. `test/replace_vars.py` expands the placeholders into `test/.run/` before `pg_prove` runs.

```bash
./dbmodel/test/run_tests.sh ws                     # PostgreSQL 16 by default
PG_MAJOR=18 ./dbmodel/test/run_tests.sh ud
TEST_GROUPS=function ./dbmodel/test/run_tests.sh ws
GW_CLEAN=1 ./dbmodel/test/run_tests.sh ws          # drop volumes on exit

./dbmodel/test/run_e2e.sh update_all               # upgrade lifecycle
./dbmodel/test/run_satellite_tests.sh              # addon suites
```

Everything runs in Docker or Podman (`GW_COMPOSE=podman`); no host Postgres and no host port are used. CI is `.github/workflows/test-db.yml` on PostgreSQL 16, 17 and 18.

Test shape: `BEGIN` -> `SET search_path` -> `SELECT plan(N)` -> assertions -> `finish()` -> `ROLLBACK`. For function tests, assert on the JSON: `is((fn($json$...$json$)::json)->>'status', 'Accepted', '...')`. Details in [.claude/skills/giswater-pgtap/SKILL.md](../.claude/skills/giswater-pgtap/SKILL.md).

## i18n

- Network UI strings: `schemas/main/{ws,ud}/final_pass/i18n/<locale>/` (`dbmessage.sql`, `dblabel.sql`, `dbfunction.sql`, `dbtypevalue.sql`, `dbconfig_form_fields.sql`, ...). Addons: `schemas/addon/{cm,am,utils}/final_pass/i18n/`.
- Locales present: `en_US`, `es_ES`, `ca_ES`, `bg_BG`. **Only `en_US` is tracked in git**; the rest are generated and gitignored. Do not commit them.
- Do not edit `en_US` base strings in place for a version bump; add the change through `patch.sql` or the locale file as appropriate.
- The `multilang` addon ([manifests/multilang.yaml](manifests/multilang.yaml)) is a separate translations schema, not the same mechanism.

## Working with a live database

Use the CLI rather than raw psql when creating or upgrading schemas, so the manifest order is respected:

```bash
export CONN='postgresql://user:pass@127.0.0.1:5432/mydb'
gw dbmodel use dev --root /path/to/giswater_qgis_plugin
gw schema main create --type ws --name demo --profile empty --check --conn "$CONN"   # dry run
gw schema main create --type ws --name demo --profile empty --conn "$CONN"
```

`--check` plans without touching the database and is the safe default. See [giswater_admin/AGENTS.md](../giswater_admin/AGENTS.md) and [.claude/skills/giswater-cli/SKILL.md](../.claude/skills/giswater-cli/SKILL.md).
