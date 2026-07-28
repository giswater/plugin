#!/usr/bin/env bash
# E2E: isolated ws and ud schema upgrades (no linked network).
#
# Create @ PLUGIN_VER uses the published release dbmodel (gw dbmodel install),
# not dev checkout + --version (which only caps updates/ but still loads dev
# functions and sample SQL). Upgrade -> TARGET_VER uses dev dbmodel from the repo.
#
# Usage:
#   export CONN='postgresql://...'
#   ./scripts/gw_e2e_update_isolated.sh
#   PLUGIN_VER=4.14.0 TARGET_VER=4.15.0 ./scripts/gw_e2e_update_isolated.sh

set -euo pipefail

CONN="${CONN:?Set CONN to a postgresql URL}"
E2E_TYPES="${E2E_TYPES:-ws,ud}"
E2E_UPDATE_PROFILE="${E2E_UPDATE_PROFILE:-sample}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=gw_e2e_common.sh
source "${SCRIPT_DIR}/gw_e2e_common.sh"

REPO="$(gw_e2e_repo_root)"
gw_e2e_setup_gw "${REPO}"
gw_e2e_resolve_versions

gw_e2e_install_release_dbmodel "${PLUGIN_VER}"
PLUGIN_DBMODEL="$(gw_e2e_release_dbmodel_path "${PLUGIN_VER}")"

echo "=== db init ==="
gw db init --conn "$CONN"
echo "=== upgrade path ${PLUGIN_VER} -> ${TARGET_VER} ==="
echo "create dbmodel: ${PLUGIN_DBMODEL}"
echo "update dbmodel: ${GW_E2E_DBMODEL}"

IFS=',' read -ra TYPES <<< "${E2E_TYPES}"
for ptype in "${TYPES[@]}"; do
  schema="e2e_upd_${ptype}"
  echo ""
  echo "=== ${ptype}: create @ ${PLUGIN_VER} (release dbmodel) ==="
  gw_e2e_gw_dbmodel "${PLUGIN_DBMODEL}" schema main drop --name "$schema" --yes --cascade >/dev/null 2>&1 || true
  gw_e2e_gw_dbmodel "${PLUGIN_DBMODEL}" schema main create \
    --type "$ptype" \
    --name "$schema" \
    --profile "$E2E_UPDATE_PROFILE" \
    --version "$PLUGIN_VER"

  gw_e2e_assert_sys_version "$schema" "$PLUGIN_VER"

  echo "=== ${ptype}: update -> ${TARGET_VER} (dev dbmodel) ==="
  gw schema main update --name "$schema" --version "$TARGET_VER" --conn "$CONN"
  gw_e2e_assert_sys_version "$schema" "$TARGET_VER"
done

echo ""
echo "E2E update isolated done."
