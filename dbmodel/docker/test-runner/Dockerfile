FROM python:3.11-slim-bookworm

# Match postgresql-client major to the postgres service (pg_dump/pg_restore version check).
# PGDG key is vendored (B97B 0AFC AA1A 47F0 44F2 44A0 7FCC 7D46 ACCC 4CF8).
# www.postgresql.org truncates that download from GitHub runners (curl 18/56).
ARG PG_MAJOR=16
COPY docker/test-runner/pgdg-ACCC4CF8.asc /tmp/pgdg-ACCC4CF8.asc
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       gnupg \
       lsb-release \
       libtap-parser-sourcehandler-pgtap-perl \
    && gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg /tmp/pgdg-ACCC4CF8.asc \
    && rm -f /tmp/pgdg-ACCC4CF8.asc \
    && echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
       > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends "postgresql-client-${PG_MAJOR}" \
    && rm -rf /var/lib/apt/lists/*

COPY docker/test-runner/gw_bash.sh /usr/local/lib/gw-test/gw_bash.sh
COPY docker/test-runner/entrypoint.sh /usr/local/bin/gw-test-entrypoint
RUN chmod +x /usr/local/bin/gw-test-entrypoint

WORKDIR /workspace
