#!/usr/bin/env bash
set -euo pipefail

EXTRACT_ONLY=0
BRANCH_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --extract-only)
      EXTRACT_ONLY=1
      shift
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [[ -n "${BRANCH_NAME}" ]]; then
        echo "Only one branch name argument is supported" >&2
        exit 1
      fi
      BRANCH_NAME="$1"
      shift
      ;;
  esac
done

if [[ -z "${BRANCH_NAME}" ]]; then
  BRANCH_NAME="$(git branch --show-current)"
fi

if [[ -z "${BRANCH_NAME}" ]]; then
  echo "Could not determine branch name" >&2
  exit 1
fi

extract_candidates() {
  local branch="$1"
  printf '%s' "${branch}" |
    cut -c1-120 |
    grep -oE '[A-Za-z][A-Za-z0-9]+-[0-9]+' |
    awk '!seen[toupper($0)]++ { print toupper($0) }'
}

CANDIDATES=()
while IFS= read -r candidate; do
  CANDIDATES+=("${candidate}")
done < <(extract_candidates "${BRANCH_NAME}")

if [[ "${#CANDIDATES[@]}" -eq 0 ]]; then
  jq -n --arg branch "${BRANCH_NAME}" \
    '{branch: $branch, candidates: [], issue: null, error: "No issue key candidate found in branch name"}'
  exit 2
fi

if [[ "${EXTRACT_ONLY}" -eq 1 ]]; then
  CANDIDATES_JSON="$(printf '%s\n' "${CANDIDATES[@]}" | jq -R . | jq -s .)"
  jq -n \
    --arg branch "${BRANCH_NAME}" \
    --argjson candidates "${CANDIDATES_JSON}" \
    '{branch: $branch, candidates: $candidates}'
  exit 0
fi

AUTH_HEADER="${AUTH_HEADER:-}"
read_auth_header_from_config() {
  local config_path="$1"
  local header=""

  header="$(sed -n 's/^AUTH_HEADER = \"\\(.*\\)\"/\\1/p' "${config_path}" | head -n 1)"
  if [[ -n "${header}" ]]; then
    printf '%s' "${header}"
    return 0
  fi

  header="$(
    sed -n '/^\[mcp_servers\.youtrack\.env\]/,/^\[/ s/^AUTH_HEADER = \"\(.*\)\"/\1/p' "${config_path}" |
      head -n 1
  )"
  printf '%s' "${header}"
}

if [[ -z "${AUTH_HEADER}" ]]; then
  CONFIG_PATH="${HOME}/.codex/config.toml"
  if [[ ! -f "${CONFIG_PATH}" ]]; then
    echo "Missing config file: ${CONFIG_PATH}" >&2
    exit 1
  fi

  AUTH_HEADER="$(read_auth_header_from_config "${CONFIG_PATH}")"
  if [[ -z "${AUTH_HEADER}" ]]; then
    echo "Missing AUTH_HEADER environment variable and ${CONFIG_PATH} entry" >&2
    exit 1
  fi
fi

FIELDS='idReadable,summary,description,project(shortName,name),customFields(name,value(name,text,fullName,login))'
FOUND_ISSUE_JSON=""
RESOLVED_CANDIDATE=""

for candidate in "${CANDIDATES[@]}"; do
  RESPONSE="$(
    curl -sS -G -H "Authorization: ${AUTH_HEADER}" \
      --data-urlencode "query=${candidate}" \
      --data-urlencode "fields=${FIELDS}" \
      --data-urlencode '$top=10' \
      "https://eslite.youtrack.cloud/api/issues"
  )"

  MATCHED="$(
    printf '%s' "${RESPONSE}" |
      jq -c --arg candidate "${candidate}" 'map(select(.idReadable == $candidate)) | .[0] // empty'
  )"

  if [[ -n "${MATCHED}" ]]; then
    FOUND_ISSUE_JSON="${MATCHED}"
    RESOLVED_CANDIDATE="${candidate}"
    break
  fi
done

if [[ -z "${FOUND_ISSUE_JSON}" ]]; then
  CANDIDATES_JSON="$(printf '%s\n' "${CANDIDATES[@]}" | jq -R . | jq -s .)"
  jq -n \
    --arg branch "${BRANCH_NAME}" \
    --argjson candidates "${CANDIDATES_JSON}" \
    '{branch: $branch, candidates: $candidates, issue: null, error: "No candidate resolved in YouTrack"}'
  exit 3
fi

CANDIDATES_JSON="$(printf '%s\n' "${CANDIDATES[@]}" | jq -R . | jq -s .)"
ISSUE_JSON="$(
  printf '%s' "${FOUND_ISSUE_JSON}" |
    jq '
      . as $issue |
      {
        id: $issue.idReadable,
        summary: $issue.summary,
        description: ($issue.description // ""),
        project: ($issue.project // null),
        customFields: (
          ($issue.customFields // []) |
          map({
            key: .name,
            value: (
              if .value == null then null
              elif (.value | type) == "array" then (.value | map(.name // .text // .fullName // .login))
              elif (.value | type) == "object" then (.value.name // .value.text // .value.fullName // .value.login // .value)
              else .value
              end
            )
          }) |
          from_entries
        )
      }
    '
)"

jq -n \
  --arg branch "${BRANCH_NAME}" \
  --arg resolvedCandidate "${RESOLVED_CANDIDATE}" \
  --argjson candidates "${CANDIDATES_JSON}" \
  --argjson issue "${ISSUE_JSON}" \
  '{
    branch: $branch,
    candidates: $candidates,
    resolvedCandidate: $resolvedCandidate,
    issue: $issue
  }'
