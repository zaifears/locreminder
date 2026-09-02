#!/usr/bin/env bash
#
# Works out how far LocReminder's F-Droid submission has got and writes a
# shields.io endpoint badge describing it.
#
# Usage: fdroid-status.sh <package-id> <gitlab-project> <merge-request-iid> <output-json-path>
# Requires: curl and jq.
set -euo pipefail

PACKAGE_ID="$1"
GITLAB_PROJECT="$2"
MR_IID="$3"
OUT="$4"

write_badge() {
  mkdir -p "$(dirname "$OUT")"
  printf '{"schemaVersion":1,"label":"F-Droid","message":"%s","color":"%s"}\n' "$1" "$2" > "$OUT"
  echo "F-Droid status: $1"
}

# If the F-Droid API is unreachable the submission's actual state has not
# changed, so leave whatever badge is already committed rather than guessing.
bail() {
  echo "::warning::F-Droid status check: $1"
  exit 0
}

# Once the app is in the index this is the only check that matters, and it
# stays true forever after, so it is checked first.
fdroid_status=$(curl -sS --max-time 30 -o /dev/null -w '%{http_code}' \
  "https://f-droid.org/api/v1/packages/$PACKAGE_ID" || echo "000")
if [ "$fdroid_status" = "200" ]; then
  write_badge "available" "brightgreen"
  exit 0
fi
[ "$fdroid_status" = "404" ] || bail "packages API returned HTTP $fdroid_status"

mr_json=$(curl -sS --max-time 30 \
  "https://gitlab.com/api/v4/projects/${GITLAB_PROJECT//\//%2F}/merge_requests/$MR_IID")
command -v jq >/dev/null || bail "jq is not installed"
echo "$mr_json" | jq -e '.state' >/dev/null 2>&1 || bail "unexpected GitLab API response"

state=$(echo "$mr_json" | jq -r '.state')
pipeline_status=$(echo "$mr_json" | jq -r '.pipeline.status // empty')
has_review_label=$(echo "$mr_json" | jq -e '.labels // [] | index("review-requested")' >/dev/null 2>&1 && echo yes || echo no)

case "$state" in
  merged)
    write_badge "merged, awaiting build" "blue"
    ;;
  closed)
    write_badge "submission closed" "red"
    ;;
  opened)
    if [ "$pipeline_status" = "failed" ]; then
      write_badge "build checks failing" "red"
    elif [ "$has_review_label" = "yes" ]; then
      write_badge "in review" "orange"
    else
      write_badge "submitted" "yellow"
    fi
    ;;
  *)
    bail "unrecognised merge request state: $state"
    ;;
esac
