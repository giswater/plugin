#!/usr/bin/env bash
# E2E: ws/ud × empty|sample|inventory profile creates.
#
# Usage:
#   export CONN='postgresql://...'
#   ./scripts/gw_e2e_profiles.sh
#   E2E_TYPES=ws E2E_PROFILES=empty,sample ./scripts/gw_e2e_profiles.sh

set -euo pipefail

CONN="${CONN:?Set CONN to a postgresql URL}"
E2E_TYPES="${E2E_TYPES:-ws,ud}"
E2E_PROFILES="${E2E_PROFILES:-empty,sample,inventory}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=gw_e2e_common.sh
source "${SCRIPT_DIR}/gw_e2e_common.sh"

REPO="$(gw_e2e_repo_root)"
gw_e2e_setup_gw "${REPO}"

eval "$(python3 "${REPO}/dbmodel/test/e2e_versions.py")"

IFS=',' read -ra TYPES <<< "${E2E_TYPES}"
IFS=',' read -ra PROFILES <<< "${E2E_PROFILES}"

echo "=== db init ==="
gw db init --conn "$CONN"

for ptype in "${TYPES[@]}"; do
  for profile in "${PROFILES[@]}"; do
    schema="e2e_${ptype}_${profile}"
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

    case "${profile}" in
      sample)
        if [[ "$ptype" == "ws" ]]; then
          gw_e2e_assert_table_rows "$schema" node 1
        else
          gw_e2e_assert_table_rows "$schema" node 1
        fi
        ;;
      inventory)
        gw_e2e_assert_table_rows "$schema" node 1
        ;;
      empty)
        ;;
      *)
        echo "unknown profile ${profile}" >&2
        exit 1
        ;;
    esac
  done
done

echo ""
echo "E2E profiles done."
