#!/usr/bin/env bash
# CI i18n lane: run i18n_searcher.py against bootstrapped origin schemas.
# Usage: I18N_VERSION=4.6.0 i18n_searcher_inner.sh
set -euo pipefail

: "${TRANSLATIONS_API_URL:?Set TRANSLATIONS_API_URL}"
: "${TRANSLATIONS_API_USER:?Set TRANSLATIONS_API_USER}"
: "${TRANSLATIONS_API_PASSWORD:?Set TRANSLATIONS_API_PASSWORD}"
: "${GW_CONN:?Set GW_CONN}"

VERSION="${I18N_VERSION:-}"
if [[ -z "$VERSION" && -f /workspace/metadata.txt ]]; then
  VERSION="$(awk -F= '/^version=/{print $2; exit}' /workspace/metadata.txt)"
fi

pip install -q requests psycopg2-binary

args=(
  --base-url "$TRANSLATIONS_API_URL"
  --user "$TRANSLATIONS_API_USER"
  --password "$TRANSLATIONS_API_PASSWORD"
  --origin-conn "$GW_CONN"
  --project-types ws,ud
  --origin-schemas ws=ws_trans,ud=ud_trans
  --repo-root /workspace
  --json-out /workspace/artifacts/i18n/detections.json
)
if [[ -n "$VERSION" ]]; then
  args+=(--version "$VERSION")
fi

python3 /workspace/scripts/i18n_searcher.py "${args[@]}"
