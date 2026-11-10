#!/usr/bin/env bash
# Bootstrap addon schema for pgTAP (utils or cibs). Requires ws_40 + ud_40 parents
# (run bootstrap_parents_inner.sh first).
set -euo pipefail

# shellcheck source=_env_inner.sh
_TEST_ROOT="${GW_TEST_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
source "${_TEST_ROOT}/_env_inner.sh" "${1:?Usage: bootstrap_addon_inner.sh utils|cibs|cmms}"

export CONN="${GW_CONN}"

gw() {
  python3 -m giswater_admin "$@" \
    --dbmodel-path "${DBMODEL_DIR}" \
    --conn "${GW_CONN}" \
    ${GW_ADMIN_FLAGS[@]+"${GW_ADMIN_FLAGS[@]}"}
}

for parent in ws_40 ud_40; do
  if ! psql "${GW_CONN}" -tA -v ON_ERROR_STOP=1 \
      -c "SELECT 1 FROM information_schema.schemata WHERE schema_name = '${parent}'" | grep -q 1; then
    echo "error: parent schema ${parent} missing; run bootstrap_parents_inner.sh first" >&2
    exit 1
  fi
done

echo "==> drop addon schema ${SCHEMA}"
gw schema addon drop --type "${PROJECT}" --name "${SCHEMA}" --yes --cascade \
  --conn "${GW_CONN}" >/dev/null 2>&1 || true

echo "==> schema addon create --type ${PROJECT} --name ${SCHEMA}"
gw schema addon create \
  --type "${PROJECT}" \
  --name "${SCHEMA}" \
  --profile empty \
  --version "${GW_PLUGIN_VERSION}" \
  --conn "${GW_CONN}"

echo "==> replace_vars (staging under test/.run/)"
TEST_STAGING="$(python3 "${SCRIPT_DIR}/replace_vars.py" "${PROJECT}")"
mkdir -p "$(dirname "${STAGING_MARKER}")"
echo "${TEST_STAGING}" > "${STAGING_MARKER}"
echo "==> test staging: ${TEST_STAGING}"
