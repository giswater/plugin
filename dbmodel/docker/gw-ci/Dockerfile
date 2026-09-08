# CI/local Postgres: PostGIS + pgrouting + pgTAP (empty DB; schema via giswater_admin).
# Base image is linux/amd64 only; compose sets platform (Apple Silicon runs via emulation).
ARG PG_MAJOR=16
ARG POSTGIS_VERSION=3.5
FROM --platform=linux/amd64 postgis/postgis:${PG_MAJOR}-${POSTGIS_VERSION}

# Check-Valid-Until=false: bullseye-security InRelease can lag Valid-Until and break apt
# update in CI (exit 100) even when packages are fine.
RUN apt-get -o Acquire::Check-Valid-Until=false update \
    && apt-get install -y --no-install-recommends \
       postgresql-${PG_MAJOR}-pgrouting \
       postgresql-${PG_MAJOR}-pgtap \
    && rm -rf /var/lib/apt/lists/*
# gw_db is created via POSTGRES_DB in docker-compose.test.yml (do not add init scripts
# that use psql -h localhost here: during entrypoint init only the Unix socket is up).
