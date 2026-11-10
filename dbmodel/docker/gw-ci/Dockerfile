# CI/local Postgres: PostGIS + pgrouting + pgTAP (empty DB; schema via giswater_admin).
# Base image is linux/amd64 only; compose sets platform (Apple Silicon runs via emulation).
ARG PG_MAJOR=16
ARG POSTGIS_VERSION=3.5
FROM --platform=linux/amd64 postgis/postgis:${PG_MAJOR}-${POSTGIS_VERSION}

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
# gw_db is created via POSTGRES_DB in docker-compose.test.yml (do not add init scripts
# that use psql -h localhost here: during entrypoint init only the Unix socket is up).
