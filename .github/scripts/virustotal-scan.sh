#!/usr/bin/env bash
#
# Scans a file with VirusTotal and writes a summary to $GITHUB_OUTPUT.
#
# Usage: virustotal-scan.sh <path-to-file>
# Requires: VT_API_KEY in the environment, plus curl and jq.
#
# Deliberately does not fail the build on a low detection count. Android
# packages that ask for background location and run foreground services draw
# false positives from a handful of the weaker engines, and a release that is
# actually fine should not be blocked at 3am by one of them. A high count is
# different — that is what a compromised dependency or a tampered artifact
# would look like — so that still stops the release.
set -euo pipefail

FILE="$1"
API="https://www.virustotal.com/api/v3"
FAIL_THRESHOLD="${VT_FAIL_THRESHOLD:-5}"

emit() { echo "$1=$2" >> "${GITHUB_OUTPUT:-/dev/stdout}"; }

# Anything that stops us learning the verdict is reported, not fatal: the scan
# is a transparency measure layered on top of the release, not a gate the
# release depends on.
bail() {
  echo "::warning::VirusTotal: $1"
  emit status "unavailable"
  emit message "$1"
  # Say plainly that the scan did not happen. Silence would read as a pass.
  emit release_note "**VirusTotal:** scan unavailable for this build ($1)."
  exit 0
}

command -v jq >/dev/null || bail "jq is not installed"
[ -n "${VT_API_KEY:-}" ] || bail "VT_API_KEY is not set"
[ -f "$FILE" ] || bail "no such file: $FILE"

SHA256=$(sha256sum "$FILE" | cut -d' ' -f1)
emit sha256 "$SHA256"
emit permalink "https://www.virustotal.com/gui/file/$SHA256"
emit release_note "**VirusTotal:** scan pending. \`SHA-256: $SHA256\`"
echo "SHA-256: $SHA256"

vt_get() { curl -sS --max-time 60 -H "x-apikey: $VT_API_KEY" "$API/$1"; }

# VirusTotal keys reports by content hash, so an identical file that has been
# submitted before — by anyone — already has a verdict and needs no upload.
report=$(vt_get "files/$SHA256")
if ! echo "$report" | jq -e '.data.attributes.last_analysis_stats' >/dev/null 2>&1; then
  echo "Not previously seen by VirusTotal; uploading ($(du -h "$FILE" | cut -f1))."

  # The plain /files endpoint rejects anything over 32MB, and this APK is
  # comfortably past that, so a one-shot upload URL is required.
  upload_url=$(vt_get "files/upload_url" | jq -r '.data // empty')
  [ -n "$upload_url" ] || bail "could not obtain an upload URL (quota or key problem?)"

  analysis_id=$(curl -sS --max-time 900 -X POST "$upload_url" \
    -H "x-apikey: $VT_API_KEY" \
    -F "file=@$FILE" | jq -r '.data.id // empty')
  [ -n "$analysis_id" ] || bail "upload failed"

  echo "Uploaded. Waiting for $(echo "$analysis_id" | cut -c1-24)… to finish."
  # ~10 minutes at 25s intervals. Well inside the 4-requests-per-minute
  # allowance on a free key, with room for the calls made above.
  for _ in $(seq 1 24); do
    sleep 25
    state=$(vt_get "analyses/$analysis_id" | jq -r '.data.attributes.status // empty')
    echo "  status: ${state:-unknown}"
    [ "$state" = "completed" ] && break
  done
  [ "${state:-}" = "completed" ] || bail "analysis did not complete in time; see $SHA256 on virustotal.com"

  report=$(vt_get "files/$SHA256")
fi

stats=$(echo "$report" | jq '.data.attributes.last_analysis_stats')
malicious=$(echo "$stats"  | jq -r '.malicious  // 0')
suspicious=$(echo "$stats" | jq -r '.suspicious // 0')
harmless=$(echo "$stats"   | jq -r '.harmless   // 0')
undetected=$(echo "$stats" | jq -r '.undetected // 0')
total=$(( malicious + suspicious + harmless + undetected ))
flagged=$(( malicious + suspicious ))

echo "Detections: $flagged of $total engines"
emit detections "$flagged"
emit total "$total"
emit status "completed"
emit message "$flagged/$total"
emit release_note "**VirusTotal:** $flagged of $total engines flagged this build — [full report](https://www.virustotal.com/gui/file/$SHA256) · \`SHA-256: $SHA256\`"

if [ "$flagged" -gt 0 ]; then
  echo "Engines reporting something:"
  echo "$report" | jq -r '
    .data.attributes.last_analysis_results
    | to_entries[]
    | select(.value.category == "malicious" or .value.category == "suspicious")
    | "  \(.key): \(.value.result)"'
fi

if [ "$flagged" -ge "$FAIL_THRESHOLD" ]; then
  echo "::error::$flagged engines flagged this build (threshold $FAIL_THRESHOLD). Refusing to publish."
  exit 1
fi
