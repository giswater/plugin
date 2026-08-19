---
name: giswater-cli
description: >
  Run giswater-cli (`gw` / python3 -m giswater_admin) to create, update, drop,
  and integrate Giswater schemas (ws, ud, addons) on currently available Postgres
  MCP servers, then verify with MCP. Use when the user mentions gw, giswater-cli,
  schema create, schema main, schema addon, db init, network update, or MCP postgres.
---

# giswater-cli

Headless Giswater schema lifecycle. Same `SchemaBuilder` as the QGIS plugin.

Canonical docs: [giswater_admin/README.md](../../../giswater_admin/README.md).
Command cheat sheet: [commands.md](commands.md).

## Hard rules

- **Mutate via CLI only.** Shell + `gw` (or `python3 -m giswater_admin`). Never `CREATE SCHEMA` / replay dbmodel SQL through MCP `execute_sql`.
- **Only ready MCP Postgres servers.** `GetMcpTools` pattern `postgres` → `serverStatus: ready`. Ignore other `mcp.json` entries.
- **Flags after the subcommand.** `--json`, `--conn`, `--dbmodel-path`, `-v` belong on `schema main create …`, not on `gw` itself.
- **New command tree only.** `schema main create`, `db init`, `network update`. No legacy aliases (`create --kind`, `init-db`, `status`).
- Mutating schema commands need a PostgreSQL **superuser** or membership in **role_system**. `db init` still needs a superuser. Drop requires `--yes`. Isolated `schema main update` is blocked on networked schemas → `network update`. No downgrades.
- **Non-dev DBs:** confirm with the user before create/update/drop unless the dbname is an obvious local playground (`giswater`, `giswater_dev`, `lab`). Treat named/production MCP databases as client data.
- Never echo passwords. Pass `--conn` only as a Shell env var.

## Conn resolution

1. `GetMcpTools` with pattern `postgres`. Use the server the user named, or ask if more than one is ready.
2. Read `~/.cursor/mcp.json`. Map MCP id `user-<serverName>` → `mcpServers.<serverName>`. URI is `env.DATABASE_URI` or the last `args` string starting with `postgresql://`.
3. Example of the mapping (fictional — never copy real client names or passwords into this skill):

   | MCP id | mcp.json key | host:port | dbname |
   |--------|--------------|-----------|--------|
   | `user-postgres-dev` | `postgres-dev` | `localhost:5432` | `giswater_dev` |
   | `user-postgres-lab` | `postgres-lab` | `localhost:5432` | `lab` |

4. In this checkout, always pass `--dbmodel-path <repo>/dbmodel` so the local tree wins over a stale release cache.

## Invocation

Prefer `gw` if on PATH; otherwise `python3 -m giswater_admin` from the plugin repo.

```bash
CONN='<uri from mcp.json>'   # do not print
gw version
python3 -m giswater_admin db init --conn "$CONN"
python3 -m giswater_admin schema main create --type ws --name demo --profile empty \
  --dbmodel-path <repo>/dbmodel \
  --conn "$CONN"
```

Schema create can take several minutes. Start Shell `block_until_ms` at ~120000 and raise if still running. Use `--check` first for updates/drops.

## Workflow

1. Discover ready MCP Postgres servers.
2. Resolve `--conn` + `--dbmodel-path`.
3. Inspect: `gw schema list --json --conn "$CONN"` and/or MCP `list_schemas`.
4. Execute the requested step ([commands.md](commands.md)).
5. Verify on the **same** MCP server: `list_schemas`, then `execute_sql`:

```sql
SELECT schema_name, giswater, project_type, language, epsg
FROM <schema>.sys_version;
```

6. Report schema name, kind, version, MCP server, and network links (`gw network show --json`).

`list_objects` / `get_object_details` only if the user asks what’s inside the schema.

`project create` (needs QGIS/PyQGIS) only if the user asks for a `.qgs` file.
