# Shared helpers for gw E2E scripts (source, do not execute).
# Requires CONN when running gw/psql helpers.

gw_e2e_repo_root() {
  local here="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
  here="$(cd "$(dirname "${here}")/.." && pwd)"
  echo "${here}"
}

gw_e2e_resolve_versions() {
  local repo dbmodel
  repo="$(gw_e2e_repo_root)"
  dbmodel="${repo}/dbmodel"
  if [[ -n "${PLUGIN_VER:-}" && -n "${TARGET_VER:-}" ]]; then
    return 0
  fi
  eval "$(python3 "${dbmodel}/test/e2e_versions.py")"
  export PLUGIN_VER TARGET_VER
}

# Cached release tree: ~/.config/giswater-cli/.../<version>/dbmodel
gw_e2e_release_dbmodel_path() {
  local version="${1:?version required}"
  python3 -c "from giswater_admin.install.config import release_dbmodel_dir; print(release_dbmodel_dir('${version}'))"
}

gw_e2e_install_release_dbmodel() {
  local version="${1:?version required}"
  echo "=== install release dbmodel ${version} ==="
  python3 -m giswater_admin dbmodel install "${version}" \
    ${GW_ADMIN_FLAGS[@]+"${GW_ADMIN_FLAGS[@]}"}
}

# Run gw with an explicit dbmodel root (create @ PLUGIN_VER uses release cache, not dev).
gw_e2e_gw_dbmodel() {
  local dbmodel_path="${1:?dbmodel path required}"
  shift
  python3 -m giswater_admin "$@" \
    --dbmodel-path "${dbmodel_path}" \
    --conn "${CONN}" \
    ${GW_ADMIN_FLAGS[@]+"${GW_ADMIN_FLAGS[@]}"}
}

gw_e2e_setup_gw() {
  local repo="${1:?}"
  export GW_E2E_REPO="${repo}"
  export GW_E2E_DBMODEL="${repo}/dbmodel"
  export CONN="${CONN:-${GW_CONN:-}}"
  export PYTHONPATH="${repo}${PYTHONPATH:+:${PYTHONPATH}}"
  export PGPASSWORD="${PGPASSWORD:-postgres}"

  gw() {
    python3 -m giswater_admin "$@" \
      --dbmodel-path "${GW_E2E_DBMODEL}" \
      --conn "${CONN}" \
      ${GW_ADMIN_FLAGS[@]+"${GW_ADMIN_FLAGS[@]}"}
  }
}

gw_e2e_assert_sys_version() {
  local schema="$1"
  local expected="$2"
  local got
  got="$(psql "$CONN" -tA -v ON_ERROR_STOP=1 \
    -c "SELECT giswater FROM \"${schema}\".sys_version ORDER BY id DESC LIMIT 1")"
  if [[ "${got}" != "${expected}" ]]; then
    echo "assert failed: ${schema}.sys_version expected ${expected}, got ${got}" >&2
    return 1
  fi
  echo "ok: ${schema}.sys_version = ${expected}"
}

gw_e2e_assert_table_rows() {
  local schema="$1"
  local table="$2"
  local min_rows="${3:-1}"
  local count
  count="$(psql "$CONN" -tA -v ON_ERROR_STOP=1 \
    -c "SELECT COUNT(*) FROM \"${schema}\".\"${table}\"")"
  if [[ "${count}" -lt "${min_rows}" ]]; then
    echo "assert failed: ${schema}.${table} expected >= ${min_rows} rows, got ${count}" >&2
    return 1
  fi
  echo "ok: ${schema}.${table} rows=${count}"
}

gw_e2e_run_guards() {
  local ws="${WS:-ws}"
  echo "=== Guard: isolated schema update must fail in linked network ==="
  if gw schema main update --name "$ws" --conn "$CONN" 2>/dev/null; then
    echo "expected gw schema main update --name ${ws} to fail" >&2
    return 1
  fi
  if gw schema addon update --type utils --conn "$CONN" 2>/dev/null; then
    echo "expected gw schema addon update --type utils to fail" >&2
    return 1
  fi
  echo "guard ok (blocked)"
}
