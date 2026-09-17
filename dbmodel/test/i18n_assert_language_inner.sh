#!/usr/bin/env bash
# CI i18n lane: assert ws_trans/ud_trans sys_version.language after bootstrap.
# Usage: i18n_assert_language_inner.sh [expected_language]
set -euo pipefail

EXPECTED="${1:-${LANGUAGE:-no_TR}}"

for schema in ws_trans ud_trans; do
  lang="$(psql "$GW_CONN" -At -c "SELECT language FROM ${schema}.sys_version LIMIT 1")"
  echo "${schema}.sys_version.language=${lang}"
  if [[ "$lang" != "$EXPECTED" ]]; then
    echo "::error::Expected ${schema} language ${EXPECTED}, got ${lang}" >&2
    exit 1
  fi
done
