ARG PG_MAJOR=16
ARG POSTGIS_VERSION=3.5
FROM postgis/postgis:${PG_MAJOR}-${POSTGIS_VERSION}
# POSTGIS_VERSION: 3.5 for PG 16/17, 3.6 for PG 18

ARG GW_DUMP=gw_ws.dump
ARG GW_GLOBALS=gw_ws.globals.sql
# bullseye-pgdg left apt.postgresql.org at the end of September 2026.
# PG 16/17 images are still Debian bullseye; PG 18 (trixie) stays on apt.postgresql.org.
# Check-Valid-Until=false: archived InRelease dates and bullseye-security can lag
# Valid-Until and break apt update in CI (exit 100) even when packages are fine.
RUN if grep -Rqs 'bullseye-pgdg' /etc/apt 2>/dev/null; then \
      find /etc/apt -type f \( -name '*.list' -o -name '*.sources' -o -name 'sources.list' \) \
        -exec sed -i '/bullseye-pgdg/s|apt\.postgresql\.org|apt-archive.postgresql.org|g' {} +; \
    fi \
    && apt-get -o Acquire::Check-Valid-Until=false update \
    && apt-get install -y --no-install-recommends \
       postgresql-${PG_MAJOR}-pgrouting \
       postgresql-${PG_MAJOR}-pgtap \
    && rm -rf /var/lib/apt/lists/*
COPY ${GW_DUMP} /docker-entrypoint-initdb.d/10-gw_db.dump
COPY docker/gw-db/restore.sh /docker-entrypoint-initdb.d/20-restore.sh
