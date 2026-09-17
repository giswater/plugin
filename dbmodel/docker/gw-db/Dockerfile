ARG PG_MAJOR=16
ARG POSTGIS_VERSION=3.5
FROM postgis/postgis:${PG_MAJOR}-${POSTGIS_VERSION}
# POSTGIS_VERSION: 3.5 for PG 16/17, 3.6 for PG 18

ARG GW_DUMP=gw_ws.dump
ARG GW_GLOBALS=gw_ws.globals.sql
# Check-Valid-Until=false: bullseye-security InRelease can lag Valid-Until and break apt
# update in CI (exit 100) even when packages are fine.
RUN apt-get -o Acquire::Check-Valid-Until=false update \
    && apt-get install -y --no-install-recommends \
       postgresql-${PG_MAJOR}-pgrouting \
       postgresql-${PG_MAJOR}-pgtap \
    && rm -rf /var/lib/apt/lists/*
COPY ${GW_DUMP} /docker-entrypoint-initdb.d/10-gw_db.dump
COPY docker/gw-db/restore.sh /docker-entrypoint-initdb.d/20-restore.sh
