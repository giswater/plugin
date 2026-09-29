#!/usr/bin/env bash
# Host orchestrator for satellite pgTAP (standalone or integrated network).
# Usage: ./test/run_satellite_tests.sh utils|cibs|cmms|network_ws|network_ud
set -euo pipefail

PROJECT="${1:?Usage: $0 utils|cibs|cmms|network_ws|network_ud}"
PG_MAJOR="${PG_MAJOR:-18}"
TEST_GROUPS="${TEST_GROUPS:-schema}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DBMODEL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

case "${PG_MAJOR}" in
  18) POSTGIS_VERSION="${POSTGIS_VERSION:-3.6}" ;;
  *)  POSTGIS_VERSION="${POSTGIS_VERSION:-3.5}" ;;
esac

export PG_MAJOR POSTGIS_VERSION TEST_GROUPS
export SATELLITES="${SATELLITES:-utils,cibs}"
export PARENT_PROFILE="${PARENT_PROFILE:-empty}"

cd "${DBMODEL_DIR}"
chmod +x "${SCRIPT_DIR}"/*.sh
chmod +x "${DBMODEL_DIR}/../scripts"/*.sh 2>/dev/null || true

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
elif command -v podman >/dev/null 2>&1 && podman compose version >/dev/null 2>&1; then
  COMPOSE=(podman compose)
else
  echo "ERROR: need docker compose or podman compose" >&2
  exit 1
fi

compose() { "${COMPOSE[@]}" -f docker-compose.test.yml "$@"; }

compose build postgres runner
compose up -d postgres --wait 2>/dev/null || compose up -d postgres

EXIT_CODE=0
case "${PROJECT}" in
  utils|cibs|cmms)
    compose run --rm -T runner bash /workspace/dbmodel/test/e2e_inner.sh pgtap_addon "${PROJECT}" || EXIT_CODE=$?
    ;;
  network_ws|network_ud)
    compose run --rm -T runner bash /workspace/dbmodel/test/e2e_inner.sh pgtap_network "${PROJECT}" || EXIT_CODE=$?
    ;;
  *)
    echo "unknown project ${PROJECT}" >&2
    exit 1
    ;;
esac

compose stop postgres >/dev/null 2>&1 || true
exit "${EXIT_CODE}"
