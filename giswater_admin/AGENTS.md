# AGENTS.md — giswater_admin

`giswater-cli`, the headless CLI (`gw`) and schema-build engine. Read the root [AGENTS.md](../AGENTS.md) first for repo-wide context.

[README.md](README.md) is the full user-facing reference: every command, every flag, install instructions, connection resolution, timing output. This file covers what an agent needs in order to change the code safely. Do not duplicate the README here; when you add a flag, update the README.

## The one thing that matters

The CLI and the QGIS plugin run **the same engine**. `engine/builder.py` (`SchemaBuilder`) is driven by the CLI through `adapters/psycopg2_adapter.py` and by QGIS through `core/threads/schema_builder_task.py` with a Qt adapter. Anything you change in `engine/` changes what happens when a user clicks Manage Schemas in QGIS.

Consequence: engine changes need verification on both paths, and psycopg2 must never leak into engine code. The engine talks to an adapter interface, not to a driver.

## Module layout

| Path | Role |
|---|---|
| `cli/main.py` | `main()` entry point |
| `cli/parser/` | Subcommand registration split by domain: `db.py`, `schema_group.py`, `network.py`, `project.py`, `manifest.py`, `meta.py`, `global_.py` (shared parent parser) |
| `cli/context.py` | Resolves the dbmodel path and schema version before dispatch |
| `commands/` | One handler per command: `init_db`, `create`, `update`, `drop`, `schema_cmd`, `network`, `update_network`, `project_cmd`, `dbmodel`, `config`, `manifest`, `version` |
| `engine/builder.py` | `SchemaBuilder`, the phase executor |
| `engine/manifest.py`, `manifest_registry.py` | Manifest parsing and phase types |
| `engine/sql_runner.py` | Executes SQL files, applies templating |
| `engine/templating.py` | `SCHEMA_NAME`, `SRID_VALUE`, `AUX_SCHEMA_NAME`, `PARENT_SCHEMA` substitution |
| `engine/version_guard.py` | Blocks downgrades and isolated updates of networked schemas |
| `engine/network_update.py` | Lockstep upgrade across an interconnected network |
| `engine/schema_catalog.py` | Discovery of schemas via `sys_version` |
| `engine/changelog.py`, `timing_report.py`, `cancel.py` | Changelog merge, timing summary, cancellation |
| `engine/qgs_runner.py` | `.qgs` generation, needs PyQGIS out of process |
| `install/` | User config (`config.py`), dbmodel path resolution (`dbmodel_paths.py`), release download (`releases.py`), version detection (`schema_version.py`) |
| `adapters/psycopg2_adapter.py` | The CLI's DB adapter |
| `conn.py`, `output.py`, `log_format.py`, `paths.py`, `user_config.py`, `releases.py` | Shared I/O; the last three are back-compat shims re-exporting from `install/` |

Note the README still refers to a single `giswater_admin/cli.py`; the parser has since been split into the `cli/parser/` package. Register new flags there.

## Entry points

```toml
[project.scripts]
gw = "giswater_admin.cli:main"
```

Also `python3 -m giswater_admin` via `__main__.py`. Dev install:

```bash
python3 -m pip install -e .
gw --help
```

Version lives in exactly two places that must agree: [pyproject.toml](../pyproject.toml) and [__version__.py](__version__.py). `scripts/bump_cli_version.py` updates both; never edit one by hand.

## Command tree

```text
gw db init
gw schema main   create | update | drop
gw schema addon  create | integrate | update | drop
gw schema list
gw project       create
gw network       show | update
gw dbmodel       install | list | use | status
gw config        get | set
gw manifest      list | validate
gw version
```

Legacy aliases (`create`, `update`, `drop`, `status`, `init-db`, `update-network`, `audit ...`) still work, print a deprecation warning on stderr and are hidden from `--help`. Keep them working; they are used by scripts in the wild.

Two invocation rules that trip people up:

- Global options live on the **subcommand's parent parser**, so they must come after the subcommand name. `gw --json schema list` fails; `gw schema list --json` works.
- `--version X.Y.Z` is the current spelling everywhere; `--plugin-version` and `--to-version` are legacy.

## Conventions

- **`--check` is the safe default for agents.** It prints the plan or SQL without touching the database. `db init --check` does not even need a connection. Use it before any real run.
- **stdout is the result, stderr is progress.** With `--json`, stdout carries exactly one JSON object; anything informational must go to stderr through `output.py` / `log_format.py`. Never `print()` progress to stdout.
- Exit codes: `0` success, `1` any failure (parse, I/O, PostgreSQL, SQL, invalid plan).
- Connection resolution order: `--conn`, `--config`, user config, then `PG*` environment variables. Do not add a fifth path.
- Privileges: `db init` needs a superuser; mutating schema commands accept a superuser or a member of `role_system`; `schema list` and `network show` are read-only and need neither.
- Downgrades are forbidden, and an isolated `schema main update` on a networked schema is blocked in favour of `network update`. Those guards live in `engine/version_guard.py` and are load-bearing; do not weaken them to make a test pass.

## dbmodel resolution

When `--dbmodel-path` is omitted, `install/dbmodel_paths.py` resolves in order: the flag, `GW_DBMODEL_PATH`, user config with `source: dev`, a sibling `dbmodel/` in a plugin checkout, then the release cache. Working from this repo, pin it explicitly:

```bash
gw dbmodel use dev --root /path/to/giswater_qgis_plugin
```

Config lives at `~/.config/giswater/config.yaml` (`%APPDATA%/giswater/` on Windows), cache at `~/.local/share/giswater/releases/`.

## Adding a command or flag

1. Add or extend the parser in `cli/parser/<domain>.py`; shared flags belong in `global_.py`.
2. Add the handler in `commands/`.
3. If it touches the build, change `engine/` and check the QGIS path in `core/threads/schema_builder_task.py`.
4. New manifest phase type: implement it in `engine/manifest.py` and validate with `gw manifest validate dbmodel/manifests/ws.yaml`. Supported types are `sql_dir`, `version_walk`, `sql_file`, `sql_function`, `sql_inline`; `dir_walk` is deprecated.
5. Update [README.md](README.md) tables and add a `[Unreleased]` entry in [CHANGELOG.md](CHANGELOG.md).

## Tests

```bash
python3 -m pytest test/cli test/engine -v                          # no DB, no Docker
PGSERVICE=localhost_giswater python3 -m pytest test/engine/smoke -v  # needs Postgres
ruff check giswater_admin scripts                                  # release gate
```

`test/cli/` covers parsing, connection config, dbmodel paths, releases and schema version; `test/engine/` covers the builder, manifests, SQL runner, network update and version walk. Fixtures `repo_root`, `dbmodel_path` and `manifests_path` come from `test/engine/conftest.py`. Smoke tests skip themselves unless `PGSERVICE` or `PGDATABASE` is set.

End-to-end shell suites against a live Postgres live in `scripts/gw_e2e_*.sh`, or in Docker via `dbmodel/test/run_e2e.sh`.

## Release

Independent of the plugin: tag `cli-vX.Y.Z`, not `vX.Y.Z`.

```bash
python3 scripts/bump_cli_version.py 0.4.4
# write the changes under ## [Unreleased] in giswater_admin/CHANGELOG.md
python3 scripts/prepare_cli_release.py 0.4.4 --create-github-release            # dry run
python3 scripts/prepare_cli_release.py 0.4.4 --execute --create-github-release
```

`prepare_cli_release.py` runs `ruff check giswater_admin scripts` first and aborts on lint failures. Publishing the GitHub Release triggers `.github/workflows/release-cli.yml`, which runs the tests, builds the wheel and pushes to PyPI via OIDC.

The CLI version and the schema version are unrelated: one CLI build can create or upgrade schemas for any installed dbmodel release. `gw version` prints both.

## See also

- [dbmodel/AGENTS.md](../dbmodel/AGENTS.md) — what the SQL sources look like and where changes go.
- [.claude/skills/giswater-cli/SKILL.md](../.claude/skills/giswater-cli/SKILL.md) — running the CLI against Postgres MCP servers and verifying the result.
