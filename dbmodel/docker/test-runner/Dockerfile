FROM python:3.11-slim-bookworm

# Match postgresql-client major to the postgres service (pg_dump/pg_restore version check).
ARG PG_MAJOR=16
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       gnupg \
       lsb-release \
       libtap-parser-sourcehandler-pgtap-perl \
    && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
       | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
       > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends "postgresql-client-${PG_MAJOR}" \
    && rm -rf /var/lib/apt/lists/*

COPY docker/test-runner/gw_bash.sh /usr/local/lib/gw-test/gw_bash.sh
COPY docker/test-runner/entrypoint.sh /usr/local/bin/gw-test-entrypoint
RUN chmod +x /usr/local/bin/gw-test-entrypoint

WORKDIR /workspace
