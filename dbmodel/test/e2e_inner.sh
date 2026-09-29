#!/usr/bin/env bash
# Docker/CI E2E dispatcher (sources _env_inner.sh, gw shim, runs scripts/*).
# Usage: e2e_inner.sh <scenario>
#   profiles | addons | update_isolated | update_network | update_all | satellites
set -euo pipefail

SCENARIO="${1:?Usage: e2e_inner.sh profiles|addons|update_isolated|update_network|update_all|satellites}"

_TEST_ROOT="${GW_TEST_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck source=_env_inner.sh
source "${_TEST_ROOT}/_env_inner.sh" ws

export CONN="${GW_CONN}"
export GW_E2E_DBMODEL="${DBMODEL_DIR}"
export SATELLITES="${SATELLITES:-utils,cibs}"
export PARENT_PROFILE="${PARENT_PROFILE:-empty}"
export E2E_TYPES="${E2E_TYPES:-ws,ud}"
export E2E_PROFILES="${E2E_PROFILES:-empty,sample,inventory}"

# shellcheck source=../../scripts/gw_e2e_common.sh
source "${REPO_ROOT}/scripts/gw_e2e_common.sh"
gw_e2e_setup_gw "${REPO_ROOT}"

export GW_E2E_DBMODEL="${GW_E2E_DBMODEL:-${REPO_ROOT}/dbmodel}"

gw() {
  python3 -m giswater_admin "$@" \
    --dbmodel-path "${DBMODEL_DIR}" \
    --conn "${GW_CONN}" \
    ${GW_ADMIN_FLAGS[@]+"${GW_ADMIN_FLAGS[@]}"}
}

SCRIPTS="${REPO_ROOT}/scripts"

case "${SCENARIO}" in
  profiles)
    bash "${SCRIPTS}/gw_e2e_profiles.sh"
    ;;
  addons)
    bash "${SCRIPTS}/gw_e2e_addons_integrate.sh"
    ;;
  update_isolated)
    bash "${SCRIPTS}/gw_e2e_update_isolated.sh"
    ;;
  update_network)
    bash "${SCRIPTS}/gw_e2e_network_update.sh"
    ;;
  update_all)
    bash "${SCRIPTS}/gw_e2e_update_all.sh"
    ;;
  satellites)
    bash "${SCRIPTS}/gw_e2e_satellites.sh"
    ;;
  pgtap_addon)
    bash "${_TEST_ROOT}/bootstrap_parents_inner.sh"
    bash "${_TEST_ROOT}/bootstrap_addon_inner.sh" "${2:?utils|cibs|cmms}"
    bash "${_TEST_ROOT}/prove_inner.sh" "${2}"
    ;;
  pgtap_network)
    bash "${_TEST_ROOT}/bootstrap_network_inner.sh" "${2:?network_ws|network_ud}"
    bash "${_TEST_ROOT}/prove_inner.sh" "${2}"
    ;;
  *)
    echo "unknown scenario: ${SCENARIO}" >&2
    exit 1
    ;;
esac

if [[ "${GW_E2E_DROP:-}" == "1" && "${SCENARIO}" != "update_all" ]]; then
  SATELLITES="${SATELLITES}" bash "${SCRIPTS}/gw_bootstrap_network.sh" --drop || true
fi
