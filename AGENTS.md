# AGENTS.md

Giswater: a QGIS plugin (Python, 4.17.0), a PostgreSQL data model (`dbmodel/`) and a headless CLI (`giswater_admin/`, `giswater-cli` 0.4.3), in one repo.

Two facts that decide where a fix belongs:

- The plugin is thin. Most business logic lives in PostgreSQL `gw_fct_*` functions that speak JSON in / JSON out. When a feature misbehaves, the fix is more often in `dbmodel/` than in Python.
- The plugin and the CLI share one schema-build engine: `giswater_admin/engine/` driven from `core/threads/schema_builder_task.py` (QGIS) or the CLI. Engine changes must be checked on both paths.

Area guides, read when you work there: [dbmodel/AGENTS.md](dbmodel/AGENTS.md) (SQL model, patches, pgTAP) and [giswater_admin/AGENTS.md](giswater_admin/AGENTS.md) (the `gw` CLI).

## Hard rules

- **Never open your own DB connection.** Use `tools_gw.execute_procedure(fn_name, body)` ([core/utils/tools_gw.py](core/utils/tools_gw.py)) for the JSON API, or `tools_db.get_row/get_rows/execute_sql` for raw SQL.
- **DB calls inside a `QgsTask`/worker must pass `aux_conn` and `is_thread=True`.** Reusing the shared `dao` from a thread crashes QGIS. Enforced by `test/scripts/check_thread_db_calls.py` in pre-commit and CI.
- **Do not edit `libs/`.** It is a git submodule; changes need a PR in `giswater/libs` plus a pointer bump here.
- **Do not edit, lint or reformat `packages/`.** Vendored third-party code.
- **Every user-visible string must be translatable.** Use `tools_qgis.show_info/show_warning/show_critical` or `tools_qt.tr(...)`, never bare literals. See [.agents/skills/giswater-python-messages/SKILL.md](.agents/skills/giswater-python-messages/SKILL.md).
- **The public surface is additive-only within 4.x** (`libs/`, `tools_gw.py`, button ids, shared dialogs, globals, config keys, Qt signals). Deprecate with `# DEPRECATED #<issue>` + `DeprecationWarning`; removals wait for 5.0. See [BREAKING-CHANGES-GUIDE.md](BREAKING-CHANGES-GUIDE.md).
- **Target Python 3.9 and both Qt5 and Qt6**, QGIS >= 3.34.5. No 3.10+ syntax.

## Commands

```bash
flake8 .                                              # lint, exactly as CI
pre-commit run --all-files                            # autoflake, autopep8, flake8, thread check
ruff check giswater_admin scripts                     # CLI release gate
python3 -m pytest test/cli test/engine -q             # unit tests, no QGIS, no DB
PGSERVICE=... python3 -m pytest test/engine/smoke -v   # needs live Postgres
./dbmodel/test/run_tests.sh ws                        # pgTAP, needs Docker
python3 -m pip install -e . && gw --help              # dev install of the CLI
```

Line length 120, max complexity 40. `dbmodel`, `test`, `i18n`, `icons` and `packages` are excluded from every Python linter; `dbmodel/` has its own CI (`.github/workflows/test-db.yml`, PostgreSQL 16/17/18).

## Layout

Non-obvious entries only:

| Path | What it is |
|---|---|
| `main.py`, `global_vars.py` | Plugin lifecycle and session globals; `__init__.py` is the QGIS factory |
| `core/utils/tools_gw.py` | Main API surface: DB calls, dialogs, config, signals |
| `core/ui/ui_manager.py` | Single registry of every `.ui` file and its `Gw<Name>Ui` wrapper |
| `core/shared/` | Big reusable features (info forms, mincut, psector, search) |
| `core/threads/` | `QgsTask` workers |
| `libs/` | Submodule: `tools_db`, `tools_qt`, `tools_qgis`, `tools_log`, `tools_os`, `tools_pgdao` |
| `packages/` | Vendored deps installed via QPIP |
| `config/giswater.config` | Toolbar and button registry, system settings |
| `resources/` | EPANET/SWMM binaries, QGIS templates, examples |
| `scripts/` | Release, deploy, E2E and i18n tooling |

## Conventions

Classes are `Gw`-prefixed (`GwLoadProject`), UI wrappers are `Gw<Name>Ui`, toolbar buttons live in `<name>_btn.py`, utility modules are `tools_*`, private members take a leading underscore. DB objects are `gw_fct_*` (functions) and `gw_trg_*` (trigger functions). Session state is split: `global_vars.*` for the plugin, `lib_vars.*` for the `libs/` submodule.

Two flows are config-driven rather than coded, so grepping for a class name will not find them:

- **Toolbars.** [config/giswater.config](config/giswater.config) maps numeric ids in `[toolbars]` to classes in `[buttons_def]`, resolved against [core/toolbars/buttons.py](core/toolbars/buttons.py). A new button needs all four: a `<name>_btn.py`, a re-export in `buttons.py`, ids in both config sections, and `icons/toolbars/<group>/NN.png`. `[project_exclude]` hides it per `ws`/`ud`.
- **Dynamic forms.** Many dialogs are described by the database (`gw_fct_getinfofromid`, `gw_fct_get_dialog`) and rendered by `core/shared/info.py`. Adding a field there means editing SQL config tables, not Python.

Signals must be registered with `tools_gw.connect_signal(obj, pfunc, section, name)` and torn down with `disconnect_signal`, otherwise `unload()` leaks them. Cross-thread UI updates go through `GwSignalManager`, never direct.

## Git

Conventional Commits (`type(scope): subject`); see [CONTRIBUTING.md](CONTRIBUTING.md). CI listens on `main`, `release/**`, `feature/**`, `fix/**`, `refactor/**`.

Two independent release tracks: tag `vX.Y.Z` ships the plugin, `cli-vX.Y.Z` ships the CLI to PyPI. Changelogs in Keep a Changelog format, plugin in [CHANGELOG.md](CHANGELOG.md), CLI in [giswater_admin/CHANGELOG.md](giswater_admin/CHANGELOG.md). The plugin major version is the DB epoch: plugin 4.x pairs with dbmodel 4.x.

Deliberately gitignored, do not commit: every translation except `en_US` (`i18n/giswater_*.{ts,qm}` and `**/final_pass/i18n/*/*.sql`), `resources/gis/locales.sqlite`, and `config/dev.config` (use it for local overrides instead of editing `giswater.config`). Shell scripts are pinned to LF by [.gitattributes](.gitattributes); breaking that breaks WSL.
