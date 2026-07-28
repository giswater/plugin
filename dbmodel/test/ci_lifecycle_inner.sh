#!/usr/bin/env bash
# CI lifecycle lanes (profiles smoke, updates, satellite pgTAP, network pgTAP).
# Usage: ci_lifecycle_inner.sh profiles-smoke|i18n-bootstrap|update-isolated|pgtap-satellites|pgtap-network
set -euo pipefail

MODE="${1:?Usage: ci_lifecycle_inner.sh profiles-smoke|i18n-bootstrap|update-isolated|pgtap-satellites|pgtap-network}"

_TEST_ROOT="${GW_TEST_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck source=_env_inner.sh
source "${_TEST_ROOT}/_env_inner.sh" ws

export CONN="${GW_CONN}"
export GW_E2E_DBMODEL="${DBMODEL_DIR}"

# shellcheck source=../../scripts/gw_e2e_common.sh
source "${REPO_ROOT}/scripts/gw_e2e_common.sh"
gw_e2e_setup_gw "${REPO_ROOT}"

gw() {
  python3 -m giswater_admin "$@" \
    --dbmodel-path "${DBMODEL_DIR}" \
    --conn "${GW_CONN}" \
    ${GW_ADMIN_FLAGS[@]+"${GW_ADMIN_FLAGS[@]}"}
}

eval "$(python3 "${_TEST_ROOT}/e2e_versions.py")"

create_main_profile() {
  local ptype="$1"
  local profile="$2"
  local schema="ci_${ptype}_${profile}"

  echo ""
  echo "=== create ${ptype} profile=${profile} schema=${schema} ==="
  gw schema main drop --name "$schema" --yes --cascade --conn "$CONN" >/dev/null 2>&1 || true
  gw schema main create \
    --type "$ptype" \
    --name "$schema" \
    --profile "$profile" \
    --srid 25831 \
    --lang en_US \
    --version "$TARGET_VER" \
    --conn "$CONN"
  gw_e2e_assert_sys_version "$schema" "$TARGET_VER"
}

case "${MODE}" in
  profiles-smoke)
    echo "=== db init ==="
    gw db init --conn "$CONN"
    for ptype in ws ud; do
      for profile in empty inventory; do
        create_main_profile "$ptype" "$profile"
      done
    done
    echo "profiles-smoke done."
    ;;

  i18n-bootstrap)
    export PARENT_PROFILE="${GW_PARENT_PROFILE:-sample}"
    export SATELLITES="${GW_SATELLITES:-}"
    export WS="${WS:-ws}"
    export UD="${UD:-ud}"
    export LANGUAGE="${LANGUAGE:-no_TR}"
    echo "=== i18n bootstrap (ws+ud profile=${PARENT_PROFILE}, satellites=${SATELLITES}, language=${LANGUAGE}) ==="
    bash "${REPO_ROOT}/scripts/gw_e2e_addons_integrate.sh"
    echo "i18n-bootstrap done."
    ;;

  update-isolated)
    export E2E_UPDATE_PROFILE="${E2E_UPDATE_PROFILE:-sample}"
    bash "${REPO_ROOT}/scripts/gw_e2e_update_isolated.sh"
    ;;

  pgtap-satellites)
    bash "${_TEST_ROOT}/bootstrap_parents_inner.sh"
    for kind in utils cibs; do
      bash "${_TEST_ROOT}/bootstrap_addon_inner.sh" "${kind}"
      TEST_GROUPS=all bash "${_TEST_ROOT}/prove_inner.sh" "${kind}"
    done
    echo "pgtap-satellites done."
    ;;

  pgtap-network)
    export GW_PARENT_PROFILE="${GW_PARENT_PROFILE:-sample}"
    for net in network_ws network_ud; do
      bash "${_TEST_ROOT}/bootstrap_network_inner.sh" "${net}"
      TEST_GROUPS=all bash "${_TEST_ROOT}/prove_inner.sh" "${net}"
    done
    echo "pgtap-network done."
    ;;

  *)
    echo "unknown mode: ${MODE}" >&2
    exit 1
    ;;
esac
