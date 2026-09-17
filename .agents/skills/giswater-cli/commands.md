# giswater-cli commands

Source of truth: [giswater_admin/README.md](../../../giswater_admin/README.md).
Parser: [giswater_admin/cli/parser/](../../../giswater_admin/cli/parser/).

Global flags go **after** the subcommand. Exit 0 success, 1 failure.

```text
gw db init
gw schema main   create | update | drop
gw schema addon  create | integrate | update | drop
gw schema list
gw network       show | update
gw project       create
gw dbmodel       install | list | use | status
gw manifest      list | validate
gw version
gw config        get | set
```

## db init

Once per database, before the first schema create. Superuser only. Installs extensions (`postgis` → `postgis_raster` → `tablefunc` → `pgrouting` → `unaccent`), creates Giswater roles if missing, and `GRANT CREATE ON DATABASE` to `role_system`.

| Flag | Notes |
|------|-------|
| `--with-fdw` | Also `postgres_fdw` |
| `--with-pgtap` | Also `pgtap` (tests) |
| `--continue-on-error` | Try remaining extensions after a failure |
| `--check` | Print SQL only; no connection required |

`--with-pgtap` / `--with-fdw` only if asked.

```bash
gw db init --conn "$CONN"
```

## schema main (ws / ud)

| Flag | Notes |
|------|-------|
| `--type` | Required on create: `ws` \| `ud` |
| `--name` | Schema name (create default: same as `--type`) |
| `--profile` | `empty` \| `sample` \| `inventory` \| `dev` (create; default `empty`) |
| `--lang` | Locale folder (default `en_US`) |
| `--srid` | EPSG (default `25831`) |
| `--version` | Schema release X.Y.Z (default: active dbmodel) |
| `--check` | Plan only |

```bash
gw schema main create --type ws --name ws1 --profile sample --lang es_ES --conn "$CONN"
gw schema main create --type ud --profile empty --conn "$CONN"
gw schema main update --name ws1 --version 4.16.0 --conn "$CONN" --check
gw schema main update --name ws1 --version 4.16.0 --conn "$CONN"
gw schema main drop --name ws1 --yes --cascade --conn "$CONN"
```

Isolated `update` is **blocked** if the schema belongs to a network → `network update`. Downgrades forbidden. Drop requires `--yes`; add `--cascade` when objects remain.

## schema addon

Typical kinds: `utils`, `cibs`, `cm`, `am`, `audit`. Any manifest under `dbmodel/manifests/` except `ws`/`ud` (also `publi`, `multilang`). `am` is WS-parent only, singleton.

Flow: **create** (standalone) then **integrate** once per parent.

```bash
gw schema addon create --type utils --conn "$CONN"
gw schema addon create --type am --profile sample --conn "$CONN"
gw schema addon integrate --type utils --parent ws1 --conn "$CONN"
gw schema addon integrate --type am --profile sample --parent ws1 --conn "$CONN"
gw schema addon update --type cibs --version 4.16.0 --conn "$CONN"
gw schema addon drop --type utils --yes --cascade --conn "$CONN"
```

`--profile empty|sample|inventory` matters for `am` (sample seeds parent catalogs); ignored for most other addons. Standalone `update` only; if integrated → `network update`.

## schema list

Read-only. No superuser / role_system required.

```bash
gw schema list --conn "$CONN" --json
gw schema list --conn "$CONN" --tier main
gw schema list --conn "$CONN" --tier addon --type cibs --json
```

`--tier`: `all` (default), `main` (ws/ud), `addon`. `--type` is repeatable.

## network

```bash
gw network show --conn "$CONN" --json
gw network show --schema ws1 --conn "$CONN"
gw network update --version 4.16.0 --conn "$CONN" --check
gw network update --version 4.16.0 --conn "$CONN"
```

Lockstep per semver folder: `utils → cibs → ws → ud → …`. Target must be ≥ every member version.

## Typical full stack

```bash
gw db init --conn "$CONN"
gw schema main create --type ws --name ws_test --profile sample --conn "$CONN"
gw schema main create --type ud --name ud_test --profile sample --conn "$CONN"
gw schema addon create --type utils --conn "$CONN"
gw schema addon integrate --type utils --parent ws_test --conn "$CONN"
gw schema addon integrate --type utils --parent ud_test --conn "$CONN"
gw network show --conn "$CONN" --json
```

## dbmodel / version

Two versions: **CLI** (`gw version` → `cli`) vs **schema** (`dbmodel-version`). In this checkout, prefer `--dbmodel-path <repo>/dbmodel` over `dbmodel use`.

```bash
gw version
gw dbmodel list --json
gw dbmodel use dev --root <repo>
gw dbmodel install latest --set-active
```

## project create

Only if the user asks for a `.qgs`. Needs QGIS/PyQGIS (`QGIS_PYTHON` if auto-detect fails).

```bash
gw project create --schema ws1 --type ws --out ./qgs --force --conn "$CONN"
```

## Do not use

| Old | Use instead |
|-----|-------------|
| `gw create --kind ws --schema x` | `gw schema main create --type ws --name x` |
| `gw update --schema ws` | `gw schema main update --name ws` |
| `gw status` | `gw network show` or `gw schema list` |
| `gw init-db` | `gw db init` |
| `gw update-network` | `gw network update` |
| `gw audit structure\|activate` | `gw schema addon create\|integrate --type audit` |
