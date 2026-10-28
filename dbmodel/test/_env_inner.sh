# Shared runner environment (source from other test/*.sh scripts).
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/_env_inner.sh" ws
set -euo pipefail

PROJECT="${1:-${PROJECT:?set PROJECT or pass as first argument}}"
case "${PROJECT}" in
  ws|ud) SCHEMA="${PROJECT}_40" ;;
  utils|cibs|cmms) SCHEMA="${PROJECT}" ;;
  network_ws) SCHEMA="ws_40" ;;
  network_ud) SCHEMA="ud_40" ;;
  *)
    echo "error: unknown PROJECT=${PROJECT} (ws|ud|utils|cibs|cmms|network_ws|network_ud)" >&2
    exit 1
    ;;
esac
TEST_GROUPS="${TEST_GROUPS:-all}"
PG_PROVE_JOBS="${PG_PROVE_JOBS:-4}"
GW_CONN="${GW_CONN:-postgresql://postgres:postgres@127.0.0.1:5432/gw_db}"

SCRIPT_DIR="${GW_TEST_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
DBMODEL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${DBMODEL_DIR}/.." && pwd)"
STAGING_MARKER="${SCRIPT_DIR}/.run/.staging_${PROJECT}"

export PYTHONPATH="${REPO_ROOT}${PYTHONPATH:+:${PYTHONPATH}}"
export PGPASSWORD=postgres
export PROJECT SCHEMA TEST_GROUPS PG_PROVE_JOBS GW_CONN SCRIPT_DIR DBMODEL_DIR REPO_ROOT

cd "${DBMODEL_DIR}"

python3 -m pip install -q -r "${REPO_ROOT}/giswater_admin/requirements.txt"

GW_PLUGIN_VERSION="$(python3 "${SCRIPT_DIR}/plugin_version.py")"
export GW_PLUGIN_VERSION

GW_ADMIN_FLAGS=()
[[ -n "${GW_VERBOSE:-}" ]] && GW_ADMIN_FLAGS+=(-v)
[[ -n "${GW_DEBUG:-}" ]] && GW_ADMIN_FLAGS+=(-d)
[[ -n "${GW_TIMING:-}" ]] && GW_ADMIN_FLAGS+=(--timing)
[[ -n "${GW_TIMING_TOP:-}" ]] && GW_ADMIN_FLAGS+=(--timing-top "${GW_TIMING_TOP}")
[[ -n "${GW_TIMING_THRESHOLD_MS:-}" ]] && GW_ADMIN_FLAGS+=(--timing-threshold-ms "${GW_TIMING_THRESHOLD_MS}")
[[ -n "${GW_TIMING_DETAIL:-}" ]] && GW_ADMIN_FLAGS+=(--timing-detail)
export GW_ADMIN_FLAGS

gw_psql() {
  psql -h 127.0.0.1 -p 5432 -U postgres -v ON_ERROR_STOP=1 "$@"
}

echo "==> plugin-version ${GW_PLUGIN_VERSION}"
echo "==> database gw_db via ${GW_CONN}"
if [[ ${#GW_ADMIN_FLAGS[@]} -gt 0 ]]; then
  echo "==> giswater_admin flags: ${GW_ADMIN_FLAGS[*]}"
fi
