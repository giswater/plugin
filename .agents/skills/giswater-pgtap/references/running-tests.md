# Running pgTAP Tests

## Prerequisites

- PostgreSQL with extensions: `postgis`, `pgrouting`, `postgis_raster`, `postgis_topology`, `pgtap`
- Python + `psycopg2` (`pip install -r dbmodel/test/requirements.txt`)
- DB: `gw_db`, user: `postgres`, password: `postgres`

## Test categories (per project type)

| Category | Path | Run group flag |
|----------|------|---------------|
| Schema | `test/<pt>/schema/` | `schema` |
| Security | `test/<pt>/security/` | `security` |
| Function | `test/<pt>/function/` | `function` |
| Data | `test/<pt>/data/` | `data` |
| Performance | `test/<pt>/performance/` | `performance` |

`<pt>` = `ud` or `ws`

## Step-by-step: fresh DB + run tests

```bash
# 1. From dbmodel/ directory
cd dbmodel/

# 2. Create & setup DB (one time)
psql -h localhost -p 55432 -U postgres -c "CREATE DATABASE gw_db;"
psql -h localhost -p 55432 -U postgres -d gw_db -c "CREATE EXTENSION postgis;"
psql -h localhost -p 55432 -U postgres -d gw_db -c "CREATE EXTENSION pgrouting;"
psql -h localhost -p 55432 -U postgres -d gw_db -c "CREATE EXTENSION postgis_raster;"
psql -h localhost -p 55432 -U postgres -d gw_db -c "CREATE EXTENSION postgis_topology;"
psql -h localhost -p 55432 -U postgres -d gw_db -c "CREATE EXTENSION pgtap;"

# 3. Replace schema placeholder (SCHEMA_NAME → ud_40)
python test/replace_vars.py ud   # or ws

# 4. Build schema + load sample data
python test/execute_sql_files.py ud   # or ws

# 5. Run tests
pg_prove -h localhost -p 55432 -U postgres -d gw_db test/ud/function/*.sql
pg_prove -h localhost -p 55432 -U postgres -d gw_db test/ud/security/*.sql
```

## Run single test file

```bash
pg_prove -h localhost -p 55432 -U postgres -d gw_db test/ud/function/test_gw_fct_getconfig.sql
```

## Run with psql (debug mode — see raw TAP output)

```bash
psql -h localhost -p 55432 -U postgres -d gw_db -f test/ud/function/test_gw_fct_getconfig.sql
```

## pg_prove useful flags

```bash
pg_prove --verbose    # show individual test names
pg_prove --failures   # show only failures
pg_prove --timer      # show timing per file
```

## Docker DB (pre-built image from CI)

```bash
# Pull pre-built DB image (has schema + sample data already)
docker pull ghcr.io/giswater/gw-db:main-pg17-ud

docker run -d \
  --name gw-db-ud \
  -p 55432:5432 \
  -e POSTGRES_PASSWORD=postgres \
  ghcr.io/giswater/gw-db:main-pg17-ud

# Then run tests directly (no schema setup needed)
pg_prove -h localhost -p 55432 -U postgres -d gw_db test/ud/function/*.sql
```

## Variables substituted by replace_vars.py

| Placeholder | Replaced with |
|-------------|--------------|
| `SCHEMA_NAME` | `<project_type>_40` (e.g. `ud_40`) |
| `SRID_VALUE` | `25831` |

## CI ports

| PG version | UD port | WS port |
|------------|---------|---------|
| 16 | 55434 | 55436 |
| 17 | 55435 | 55437 |

## Environment variables

| Var | Default | Override |
|-----|---------|---------|
| `PGPASSWORD` | `postgres` | `export PGPASSWORD=mypass` |
| `PORT` | `55432` | `export PORT=55434` |
