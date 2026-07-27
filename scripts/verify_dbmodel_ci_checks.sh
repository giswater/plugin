#!/usr/bin/env bash
# Verify PostgreSQL Tests workflow jobs passed on a commit SHA.
#
# Usage:
#   verify_dbmodel_ci_checks.sh --sha abc123
#   verify_dbmodel_ci_checks.sh --tag v4.15.0 --wait
#   verify_dbmodel_ci_checks.sh --tag cli-v0.2.0 --cli-release
#
# Requires: gh (authenticated) or GITHUB_TOKEN + git for --tag resolution.
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-giswater/plugin}"
CLI_RELEASE=false
WAIT=false
TIMEOUT_SECONDS=1200
POLL_SECONDS=15
SHA=""
TAG=""

usage() {
  sed -n '2,8p' "$0"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sha) SHA="${2:?}"; shift 2 ;;
    --tag) TAG="${2:?}"; shift 2 ;;
    --cli-release) CLI_RELEASE=true; shift ;;
    --wait) WAIT=true; shift ;;
    --timeout-seconds) TIMEOUT_SECONDS="${2:?}"; shift 2 ;;
    --poll-seconds) POLL_SECONDS="${2:?}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "unknown arg: $1" >&2; usage ;;
  esac
done

if [[ -z "${SHA}" && -z "${TAG}" ]]; then
  echo "error: pass --sha or --tag" >&2
  exit 1
fi
if ! [[ "${TIMEOUT_SECONDS}" =~ ^[0-9]+$ && "${POLL_SECONDS}" =~ ^[1-9][0-9]*$ ]]; then
  echo "error: timeout must be non-negative and poll interval must be positive" >&2
  exit 1
fi

if [[ -z "${SHA}" ]]; then
  if git rev-parse --verify "${TAG}^{commit}" >/dev/null 2>&1; then
    SHA="$(git rev-parse "${TAG}^{commit}")"
  else
    SHA="$(gh api "repos/${REPO}/git/ref/tags/${TAG}" --jq '.object.sha')"
    obj_type="$(gh api "repos/${REPO}/git/ref/tags/${TAG}" --jq '.object.type')"
    if [[ "${obj_type}" == "tag" ]]; then
      SHA="$(gh api "repos/${REPO}/git/tags/${SHA}" --jq '.object.sha')"
    fi
  fi
fi

echo "==> verify dbmodel CI checks on ${SHA} (repo ${REPO})"

if [[ "${CLI_RELEASE}" == true ]]; then
  prev_tag=""
  if [[ -n "${TAG}" ]]; then
    prev_tag="$(git describe --tags --abbrev=0 "${TAG}^" 2>/dev/null || true)"
    diff_end="${SHA}"
  else
    prev_tag="$(git describe --tags --abbrev=0 2>/dev/null || true)"
    diff_end="HEAD"
  fi
  if [[ -n "${prev_tag}" ]] && git diff --quiet "${prev_tag}" "${diff_end}" -- dbmodel/ 2>/dev/null; then
    echo "dbmodel/ unchanged since ${prev_tag}; skipping dbmodel CI verify for CLI release"
    exit 0
  fi
fi

REQUIRED_CHECKS=(
  "pgTAP ws (PG 16)"
  "pgTAP ws (PG 17)"
  "pgTAP ws (PG 18)"
  "pgTAP ud (PG 16)"
  "pgTAP ud (PG 17)"
  "pgTAP ud (PG 18)"
  "profiles empty+inventory (PG 16)"
  "profiles empty+inventory (PG 17)"
  "profiles empty+inventory (PG 18)"
  "update isolated (PG 16)"
  "update isolated (PG 17)"
  "update isolated (PG 18)"
  "pgTAP satellites (PG 16)"
  "pgTAP satellites (PG 17)"
  "pgTAP satellites (PG 18)"
  "pgTAP network (PG 16)"
  "pgTAP network (PG 17)"
  "pgTAP network (PG 18)"
)

started_at="${SECONDS}"

while true; do
  CHECK_LINES=()
  while IFS= read -r line; do
    CHECK_LINES+=("${line}")
  done < <(
    gh api "repos/${REPO}/commits/${SHA}/check-runs?per_page=100" --paginate \
      --jq '.check_runs[] | "\(.name)\t\(.status)\t\(.conclusion // "")"'
  )

  succeeded=0
  pending=0
  missing=0
  failed=0
  PROBLEM_LINES=()

  for required in "${REQUIRED_CHECKS[@]}"; do
    found=false
    has_success=false
    has_pending=false
    terminal_conclusions=""

    for line in "${CHECK_LINES[@]}"; do
      IFS=$'\t' read -r name status conclusion <<< "${line}"
      [[ "${name}" == "${required}" ]] || continue
      found=true

      if [[ "${status}" == "completed" && "${conclusion}" == "success" ]]; then
        has_success=true
      elif [[ "${status}" != "completed" ]]; then
        has_pending=true
      else
        terminal_conclusions="${terminal_conclusions:+${terminal_conclusions},}${conclusion:-unknown}"
      fi
    done

    if [[ "${has_success}" == true ]]; then
      succeeded=$((succeeded + 1))
    elif [[ "${has_pending}" == true ]]; then
      pending=$((pending + 1))
      PROBLEM_LINES+=("PENDING: ${required}")
    elif [[ "${found}" == false ]]; then
      missing=$((missing + 1))
      PROBLEM_LINES+=("MISSING: ${required}")
    else
      failed=$((failed + 1))
      PROBLEM_LINES+=("FAILED:  ${required} (${terminal_conclusions})")
    fi
  done

  if [[ "${succeeded}" -eq "${#REQUIRED_CHECKS[@]}" ]]; then
    echo "All ${#REQUIRED_CHECKS[@]} dbmodel CI checks passed on ${SHA}."
    exit 0
  fi

  elapsed=$((SECONDS - started_at))
  if [[ "${failed}" -gt 0 || "${WAIT}" != true || "${elapsed}" -ge "${TIMEOUT_SECONDS}" ]]; then
    printf '%s\n' "${PROBLEM_LINES[@]}"
    echo ""
    if [[ "${elapsed}" -ge "${TIMEOUT_SECONDS}" && "${WAIT}" == true ]]; then
      echo "error: timed out waiting for dbmodel CI checks after ${elapsed}s" >&2
    fi
    echo "error: dbmodel CI checks not green (success=${succeeded}, pending=${pending}, missing=${missing}, failed=${failed})" >&2
    exit 1
  fi

  echo "Waiting for dbmodel CI checks: success=${succeeded}, pending=${pending}, missing=${missing} (elapsed=${elapsed}s)"
  sleep "${POLL_SECONDS}"
done
