#!/usr/bin/env bash
# E2E: multi-addon create + integrate + asserts.
#
# Usage:
#   export CONN='postgresql://...'
#   SATELLITES=utils,cibs ./scripts/gw_e2e_addons_integrate.sh
#   SATELLITES=utils,cibs,cm,am,audit ./scripts/gw_e2e_addons_integrate.sh

set -euo pipefail

CONN="${CONN:?Set CONN to a postgresql URL}"
WS="${WS:-ws}"
UD="${UD:-ud}"
SATELLITES="${SATELLITES:-utils,cibs}"
PARENT_PROFILE="${PARENT_PROFILE:-empty}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=gw_e2e_common.sh
source "${SCRIPT_DIR}/gw_e2e_common.sh"

REPO="$(gw_e2e_repo_root)"
gw_e2e_setup_gw "${REPO}"
gw_e2e_resolve_versions
export GW_E2E_DBMODEL="${GW_E2E_DBMODEL:-${REPO}/dbmodel}"

export WS UD SATELLITES PARENT_PROFILE TARGET_VER LANGUAGE
unset PLUGIN_VER

run_drop=true
for arg in "$@"; do
  case "$arg" in
    --check|--drop) run_drop=false ;;
  esac
done
if [[ "$run_drop" == true ]]; then
  SATELLITES="${SATELLITES}" PARENT_PROFILE="${PARENT_PROFILE}" WS="${WS}" UD="${UD}" \
    "$SCRIPT_DIR/gw_bootstrap_network.sh" --drop >/dev/null 2>&1 || true
fi

"$SCRIPT_DIR/gw_bootstrap_network.sh" "$@"

for arg in "$@"; do
  case "$arg" in
    --check|--drop) exit 0 ;;
  esac
done

echo "=== Assert satellite schemas ==="
IFS=',' read -ra KINDS <<< "${SATELLITES}"
for kind in "${KINDS[@]}"; do
  kind="${kind// /}"
  [[ -z "$kind" ]] && continue
  schema="${kind}"
  case "$kind" in
    utils) schema="${UTILS:-utils}" ;;
    cibs) schema="${CIBS:-cibs}" ;;
    cm) schema="${CM:-cm}" ;;
    am) schema="${AM:-am}" ;;
    audit) schema="${AUDIT:-audit}" ;;
  esac
  psql "$CONN" -v ON_ERROR_STOP=1 -c \
    "SELECT 1 FROM information_schema.schemata WHERE schema_name = '${schema}'" | grep -q 1
  gw_e2e_assert_sys_version "$schema" "${TARGET_VER}"
done

echo "=== Post-steps (cibs flags + role permissions) ==="
if [[ ",${SATELLITES}," == *",cibs,"* ]]; then
  psql "$CONN" -v ON_ERROR_STOP=1 <<SQL
SELECT ${WS}.gw_fct_admin_role_permissions();
UPDATE ${WS}.config_param_system SET value = 'true' WHERE parameter = 'admin_cibs_schema';
SELECT ${UD}.gw_fct_admin_role_permissions();
UPDATE ${UD}.config_param_system SET value = 'true' WHERE parameter = 'admin_cibs_schema';
SQL
fi

echo "=== Network topology ==="
gw network show --conn "$CONN"

echo "E2E addons integrate done."
