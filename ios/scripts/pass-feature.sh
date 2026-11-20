#!/bin/bash
# pass-feature.sh C-0xx|K-0xx [...]: flip `passes` to true in the matching spec features.json.
#
# spec/ is read-only to the build loop, with this one exception: a feature's `passes` flag goes
# false -> true after scripts/verify.sh exits 0. This script is that door, and it is deliberately narrow:
#   - it refuses unless verify.sh went green on exactly the files that are here now
#   - it refuses unless every `dependsOn` already passes
#   - it changes the word `false` to `true` on that entry's line and nothing else
set -euo pipefail
cd "$(dirname "$0")/.."

[ "$#" -ge 1 ] || { echo "usage: $0 C-0xx|K-0xx [...]" >&2; exit 64; }
STAMP=".verify/green-stamp"

# Must match tree_fingerprint in scripts/verify.sh.
fingerprint() {
  git ls-files -z -co --exclude-standard -- . ':!spec/*/features.json' ':!.verify' ':!*.md' ':!research' \
    | xargs -0 shasum -a 256 2>/dev/null | shasum -a 256 | cut -d' ' -f1
}
[ -f "$STAMP" ] || { echo "No green verify.sh run recorded. Run ./scripts/verify.sh first." >&2; exit 1; }
if [ "$(cat "$STAMP")" != "$(fingerprint)" ]; then
  echo "Files changed since the last green verify.sh run. Run ./scripts/verify.sh again." >&2
  exit 1
fi

for id in "$@"; do
  case "$id" in
    C-*) FILE="spec/calo/features.json" ;;
    K-*) FILE="spec/calculator/features.json" ;;
    *) echo "$id: ids start with C- (Calo) or K- (calculator)" >&2; exit 1 ;;
  esac
  state="$(jq -r --arg id "$id" '.features[] | select(.id == $id) | .passes' "$FILE")"
  [ -n "$state" ] || { echo "$id: no such feature in $FILE" >&2; exit 1; }
  [ "$state" = "false" ] || { echo "$id: already passes"; continue; }
  blocked="$(jq -r --arg id "$id" '
    (.features | map({key: .id, value: .passes}) | from_entries) as $passes
    | .features[] | select(.id == $id) | .dependsOn | map(select($passes[.] != true)) | join(" ")' "$FILE")"
  [ -z "$blocked" ] || { echo "$id: depends on features that do not pass yet: $blocked" >&2; exit 1; }

  before="$(jq -S 'del(.features[].passes)' "$FILE")"
  backup="$(mktemp)"; cp "$FILE" "$backup"
  awk -v id="\"id\": \"$id\"" '
    index($0, id) { inside = 1 }
    inside && /"passes": false/ { sub(/"passes": false/, "\"passes\": true"); inside = 0 }
    { print }' "$FILE" > "$FILE.tmp"
  mv "$FILE.tmp" "$FILE"
  after="$(jq -S 'del(.features[].passes)' "$FILE")"
  now="$(jq -r --arg id "$id" '.features[] | select(.id == $id) | .passes' "$FILE")"
  if [ "$before" != "$after" ] || [ "$now" != "true" ]; then
    cp "$backup" "$FILE"; rm -f "$backup"
    echo "$id: the edit did not land cleanly; $FILE restored" >&2
    exit 1
  fi
  rm -f "$backup"
  echo "$id: passes"
done
