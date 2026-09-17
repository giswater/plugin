#!/usr/bin/env bash
# Bootstrap a full Giswater network from scratch:
#   db init (superuser) → ws + ud → satellites → integrate → network show
#
# Two connections:
#   CONN_SUPER  PostgreSQL superuser — db init only (extensions, roles,
#               GRANT CREATE ON DATABASE … TO role_system)
#   CONN        login in role_system — schema create / integrate / drop / show
#
# If CONN_SUPER is unset, db init uses CONN (CI / single superuser).
#
# Usage (split roles):
#   export CONN_SUPER='postgresql://postgres:…@host:port/dbname'
#   export CONN='postgresql://gis_system:…@host:port/dbname'
#   ./scripts/gw_bootstrap_network.sh --init-only    # superuser
#   ./scripts/gw_bootstrap_network.sh --skip-init    # role_system
#   # or one shot with both env vars:
#   ./scripts/gw_bootstrap_network.sh
#
# Usage (one superuser, same as before):
#   export CONN='postgresql://postgres:…@host:port/dbname'
#   ./scripts/gw_bootstrap_network.sh
#
# Options:
#   --check       plan only (passes --check to gw)
#   --drop        drop network + satellite schemas (uses CONN)
#   --init-only   only gw db init (CONN_SUPER)
#   --skip-init   skip db init; schema phases only (CONN)
#
# Schema names (override via env):
#   WS=ws UD=ud UTILS=utils CIBS=cibs CM=cm AM=am AUDIT=audit
#
# Locale for ws/ud schema create (sys_version.language):
#   LANGUAGE=no_TR
# Satellites (comma-separated kinds):
#   SATELLITES=utils,cibs,cm,am,audit
# Parent create profile for ws/ud:
#   PARENT_PROFILE=empty|sample|inventory

set -euo pipefail

WS="${WS:-ws}"
UD="${UD:-ud}"
UTILS="${UTILS:-utils}"
CIBS="${CIBS:-cibs}"
CM="${CM:-cm}"
AM="${AM:-am}"
AUDIT="${AUDIT:-audit}"
PARENT_PROFILE="${PARENT_PROFILE:-empty}"
# Set-but-empty means "no satellites" (i18n lane); only unset falls back to the default.
SATELLITES="${SATELLITES-utils,cibs}"
LANGUAGE="${LANGUAGE:-}"

MAIN_LANG=()
if [[ -n "$LANGUAGE" ]]; then
  MAIN_LANG=(--lang "$LANGUAGE")
fi

CHECK=""
DROP=""
INIT_ONLY=""
SKIP_INIT=""

for arg in "$@"; do
  case "$arg" in
    --check) CHECK="--check" ;;
    --drop) DROP=1 ;;
    --init-only) INIT_ONLY=1 ;;
    --skip-init) SKIP_INIT=1 ;;
    -h|--help)
      sed -n '2,38p' "$0"
      exit 0
      ;;
    *) echo "Unknown arg: $arg (try --help)" >&2; exit 1 ;;
  esac
done

if [[ -n "$INIT_ONLY" && -n "$SKIP_INIT" ]]; then
  echo "Cannot combine --init-only and --skip-init" >&2
  exit 1
fi
if [[ -n "$INIT_ONLY" && -n "$DROP" ]]; then
  echo "Cannot combine --init-only and --drop" >&2
  exit 1
fi

CONN="${CONN:-}"
CONN_SUPER="${CONN_SUPER:-}"

if [[ -n "$INIT_ONLY" ]]; then
  CONN_SUPER="${CONN_SUPER:-${CONN:?export CONN_SUPER (superuser) or CONN}}"
elif [[ -n "$DROP" || -n "$SKIP_INIT" ]]; then
  CONN="${CONN:?export CONN='postgresql://role_system_login@host:port/dbname'}"
else
  CONN="${CONN:?export CONN='postgresql://role_system_login@host:port/dbname'}"
  CONN_SUPER="${CONN_SUPER:-$CONN}"
fi
export CONN CONN_SUPER

IFS=',' read -ra SATELLITES_CREATE <<< "${SATELLITES}"

declare -A SATELLITE_NAME=(
  [utils]="$UTILS"
  [cibs]="$CIBS"
  [cm]="$CM"
  [am]="$AM"
  [audit]="$AUDIT"
)

PARENTS=("$WS" "$UD")

if [[ -z "${PLUGIN_VER:-}" ]]; then
  _repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  eval "$(python3 "${_repo_root}/dbmodel/test/e2e_versions.py")"
  # Default: create at current dev (TARGET_VER). Upgrade E2E sets PLUGIN_VER explicitly.
  PLUGIN_VER="${TARGET_VER}"
fi

gw_cmd() {
  if declare -F gw >/dev/null 2>&1; then
    gw "$@"
  elif command -v gw >/dev/null 2>&1; then
    command gw "$@"
  else
    local extra=()
    if [[ -n "${GW_E2E_DBMODEL:-}" ]]; then
      extra+=(--dbmodel-path "${GW_E2E_DBMODEL}")
    elif [[ -n "${DBMODEL_DIR:-}" ]]; then
      extra+=(--dbmodel-path "${DBMODEL_DIR}")
    fi
    python3 -m giswater_admin "$@" "${extra[@]}" \
      ${GW_ADMIN_FLAGS[@]+"${GW_ADMIN_FLAGS[@]}"}
  fi
}

run() {
  echo ""
  echo ">>> gw $*"
  local extra=()
  case "$1" in
    schema)
      if [[ -n "$PLUGIN_VER" ]]; then
        extra+=(--version "$PLUGIN_VER")
      fi
      ;;
  esac
  gw_cmd "$@" "${extra[@]}" $CHECK
}

drop_schemas() {
  echo "=== drop network schemas ==="
  gw_cmd schema main drop --name "$WS" --yes --cascade --conn "$CONN" || true
  gw_cmd schema main drop --name "$UD" --yes --cascade --conn "$CONN" || true

  echo "=== drop satellite schemas ==="
  for kind in "${SATELLITES_CREATE[@]}"; do
    kind="${kind// /}"
    [[ -z "$kind" ]] && continue
    name="${SATELLITE_NAME[$kind]:-$kind}"
    gw_cmd schema addon drop --type "$kind" --name "$name" --yes --cascade --conn "$CONN" || true
  done

  echo "Dropped $WS $UD and satellites: ${SATELLITES_CREATE[*]}"
}

create_satellite() {
  local kind="$1"
  kind="${kind// /}"
  local name="${SATELLITE_NAME[$kind]:-$kind}"
  local extra=(--name "$name")

  case "$kind" in
    audit)
      extra+=(--profile empty)
      ;;
  esac

  run schema addon create --type "$kind" "${extra[@]}" --conn "$CONN"
}

integrate_satellite() {
  local kind="$1"
  local parent="$2"
  kind="${kind// /}"

  # am integrates with ws parent only
  if [[ "$kind" == "am" && "$parent" != "$WS" ]]; then
    echo "skip am integrate on ${parent} (ws only)"
    return 0
  fi

  case "$kind" in
    utils)
      run schema addon integrate --type utils --parent "$parent" --conn "$CONN"
      ;;
    audit)
      run schema addon integrate --type audit --parent "$parent" --profile integrate --conn "$CONN"
      ;;
    cibs|cm|am)
      run schema addon integrate --type "$kind" --parent "$parent" --conn "$CONN"
      ;;
    *)
      run schema addon integrate --type "$kind" --parent "$parent" --conn "$CONN"
      ;;
  esac
}

if [[ -n "$DROP" ]]; then
  drop_schemas
  exit 0
fi

if [[ -z "$SKIP_INIT" ]]; then
  echo "=== 1. PostgreSQL extensions (superuser) ==="
  run db init --conn "$CONN_SUPER"
  if [[ -n "$INIT_ONLY" ]]; then
    echo ""
    echo "db init done. Create schemas with CONN (role_system):"
    echo "  CONN=… ./scripts/gw_bootstrap_network.sh --skip-init"
    exit 0
  fi
else
  echo "=== 1. PostgreSQL extensions === skipped (--skip-init)"
fi

echo "=== 2. Network schemas (ws + ud) profile=${PARENT_PROFILE} lang=${LANGUAGE:-en_US} ==="
run schema main create --type ws --name "$WS" --profile "$PARENT_PROFILE" "${MAIN_LANG[@]}" --conn "$CONN"
run schema main create --type ud --name "$UD" --profile "$PARENT_PROFILE" "${MAIN_LANG[@]}" --conn "$CONN"

echo "=== 3. Satellite schemas (${SATELLITES}) ==="
for kind in "${SATELLITES_CREATE[@]}"; do
  kind="${kind// /}"
  [[ -z "$kind" ]] && continue
  create_satellite "$kind"
done

echo "=== 4. Integrate satellites with ws and ud ==="
for kind in "${SATELLITES_CREATE[@]}"; do
  kind="${kind// /}"
  [[ -z "$kind" ]] && continue
  for parent in "${PARENTS[@]}"; do
    integrate_satellite "$kind" "$parent"
  done
done

if [[ -z "$CHECK" ]]; then
  echo ""
  echo "=== 5. Network status ==="
  gw_cmd network show --conn "$CONN"
fi

echo ""
echo "Done."
