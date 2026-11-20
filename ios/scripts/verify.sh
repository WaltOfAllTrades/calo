#!/bin/bash
# verify.sh: the one gate for ios/. Nothing merges unless this exits 0 (architecture §5, code-standards 12).
#
#   protected files -> boundaries -> lint -> xcodegen -> build -> unit tests -> UI tests -> result checks
#
# Exits non-zero on: a protected file changed, a layering violation, a lint error, a build error, any
# failed, skipped or "expected failure" test, zero tests run, or a drop in the number of tests or
# assertions since the last green run (.verify/last-green.txt).
#
# Run from anywhere:            ios/scripts/verify.sh
# Another simulator:            SIM_NAME="iPhone 17e" ios/scripts/verify.sh
# Walt only, after reading the diff (a test, the spec or this script was changed on purpose):
#                               ALLOW_PROTECTED_CHANGES=1 ios/scripts/verify.sh
#
# This file is read-only to the build loop once on main. A failing check means the code is wrong or
# the spec needs Walt; it never means "edit the gate".
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd -P)"                      # …/Calo/ios
PREFIX="ios/"                         # paths relative to the repository root, for git show
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

SCHEME="Calo"
PROJECT="Calo.xcodeproj"
SIM_NAME="${SIM_NAME:-iPhone 17}"
IPAD_SIM_NAME="${IPAD_SIM_NAME:-iPad mini (A20 Pro)}"
DEST="platform=iOS Simulator,name=${SIM_NAME}"
DERIVED=".derivedData"
RESULTS="build/results"
LAST_GREEN=".verify/last-green.txt"
GREEN_STAMP=".verify/green-stamp"
UNIT_TARGETS=(DesignSystemTests CaloKitTests CalcKitTests CaloAppTests)
UI_TARGETS=(CaloUITests)
FEATURE_FILES=(spec/calo/features.json spec/calculator/features.json)

# 8 GB RAM: one xcodebuild job at a time, one simulator, no parallel test clones.
XCB=(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DEST"
     -derivedDataPath "$DERIVED" -parallel-testing-enabled NO -quiet)

step() { printf '\n==> %s\n' "$*"; }
fail() { printf '\nverify.sh: FAILED: %s\n' "$*" >&2; rm -f "$GREEN_STAMP"; exit 1; }
pretty() { if command -v xcbeautify >/dev/null; then xcbeautify --quiet; else cat; fi; }

# Curata may be building in another session. Two xcodebuilds at once exhaust 8 GB, so wait for the
# other one (up to 20 minutes) instead of starting beside it or killing it.
wait_for_other_builds() {
  local waited=0
  while pgrep -x xcodebuild >/dev/null 2>&1; do
    if [ "$waited" -eq 0 ]; then echo "    another xcodebuild is running; waiting for it"; fi
    sleep 10; waited=$((waited + 10))
    if [ "$waited" -ge 1200 ]; then echo "    waited 20 minutes; going ahead"; break; fi
  done
  return 0
}

# A fingerprint of every file under ios/ that can affect the result (prose is left out, so writing the
# log after a green run does not undo it). scripts/pass-feature.sh compares it so a `passes` flag can
# only flip for the exact tree that went green.
tree_fingerprint() {
  git ls-files -z -co --exclude-standard -- . ':!spec/*/features.json' ':!.verify' ':!*.md' ':!research' \
    | xargs -0 shasum -a 256 2>/dev/null | shasum -a 256 | cut -d' ' -f1
}

rm -f "$GREEN_STAMP"

# ---------------------------------------------------------------------------------------------
PROTECTED=(Tests UITests spec scripts/verify.sh scripts/pass-feature.sh scripts/hooks
           .swiftlint.yml .swiftformat .verify/last-green.txt)
step "1/8 Protected files (${PROTECTED[*]})"
# New files are fine (tests are written first); changing or deleting one that is already on main is not.
# Protection starts when the guard itself is on main: the skeleton features create the tests and this
# script, so the branch that introduces the guard is not judged by it.
BASE="$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main 2>/dev/null || true)"
if [ -z "$BASE" ] || ! git cat-file -e "$BASE:${PREFIX}scripts/hooks/protect-paths.sh" 2>/dev/null; then
  echo "    not enforced yet: the guard is not on main (this is the branch that adds it)"
else
  changed="$(git diff --name-status --no-renames --relative "$BASE" -- "${PROTECTED[@]}" \
    | awk -F'\t' '$1 != "A" { print $2 }')"
  offenders=""
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    if [ "$path" = ".verify/last-green.txt" ]; then
      continue   # step 8 compares against main's copy, so it can only go up
    elif [[ " ${FEATURE_FILES[*]} " == *" $path "* ]]; then
      # The one sanctioned change inside spec/: a `passes` flag going false -> true, and only
      # for a feature whose dependsOn all pass.
      [ -f "$path" ] || fail "$path is missing"
      before="$(git show "$BASE:${PREFIX}$path" | jq -S 'del(.features[].passes)')" || fail "cannot read $path on main"
      after="$(jq -S 'del(.features[].passes)' "$path")" || fail "$path is not valid JSON"
      undepended="$(jq -r '
        (.features | map({key: .id, value: .passes}) | from_entries) as $passes
        | [.features[] | select(.passes == true) | select(any(.dependsOn[]; $passes[.] != true)) | .id]
        | join(" ")' "$path")"
      unflipped="$(jq -r --slurpfile old <(git show "$BASE:${PREFIX}$path") \
        '[.features[] | select(.passes == false) | .id] as $now
         | [$old[0].features[] | select(.passes == true) | .id] as $was
         | ($was - ($was - $now)) | join(" ")' "$path")"
      if [ "$before" != "$after" ] || [ -n "$unflipped" ] || [ -n "$undepended" ]; then offenders+="$path "; fi
    else
      offenders+="$path "
    fi
  done <<< "$changed"
  if [ -n "$offenders" ]; then
    if [ "${ALLOW_PROTECTED_CHANGES:-0}" = "1" ]; then
      echo "    ALLOW_PROTECTED_CHANGES=1: accepting changes to: $offenders"
    else
      fail "protected files changed since main: $offenders(tests are not edited to pass; the spec is Walt's)"
    fi
  fi
fi

# ---------------------------------------------------------------------------------------------
step "2/8 Package boundaries (architecture §2, code-standards 16)"
imports() {
  grep -rnE --include='*.swift' --exclude-dir=.build \
    '^[[:space:]]*(@[A-Za-z_]+(\([^)]*\))?[[:space:]]+)*((public|internal|private|package|fileprivate)[[:space:]]+)?import[[:space:]]+' \
    "$@" 2>/dev/null \
    | sed -E -e 's|//.*$||' \
      -e 's/^([^:]+):[0-9]+:[^"]*[[:<:]]import[[:space:]]+((struct|class|enum|protocol|func|var|let|typealias)[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*).*/\1	\4/' \
    || true
}
violations=""
may_import_only() {
  local dir="$1"; shift
  if [ ! -d "$dir" ]; then violations+="  $dir does not exist (its boundary cannot be checked)"$'\n'; return 0; fi
  local allowed=" $* " line module
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    module="${line##*	}"
    case "$allowed" in *" $module "*) ;; *) violations+="  ${line%%	*} imports $module (allowed: $*)"$'\n' ;; esac
  done <<< "$(imports "$dir")"
}
must_not_import() {
  local dir="$1" module="$2" why="$3" line
  [ -d "$dir" ] || return 0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    [ "${line##*	}" = "$module" ] && violations+="  ${line%%	*} imports $module ($why)"$'\n'
  done <<< "$(imports "$dir")"
  return 0
}
only_under() {
  local module="$1" dir="$2" line
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    [ "${line##*	}" = "$module" ] || continue
    case "${line%%	*}" in "$dir"/*) ;; *) violations+="  ${line%%	*} imports $module (only $dir may)"$'\n' ;; esac
  done <<< "$(imports App Packages)"
}
may_import_only Packages/CalcKit/Sources Foundation OSLog
may_import_only Packages/CaloKit/Sources Foundation GRDB OSLog
may_import_only Packages/DesignSystem/Sources Foundation SwiftUI
only_under GRDB Packages/CaloKit
must_not_import App/Features/Calo CalcKit "the two products share nothing but DesignSystem"
must_not_import App/Features/Calculator CaloKit "the two products share nothing but DesignSystem"
must_not_import Packages/CaloKit/Sources CalcKit "code-standards 16"
must_not_import Packages/CalcKit/Sources CaloKit "code-standards 16"
if [ -n "$violations" ]; then fail "layering violations:"$'\n'"$violations"; fi
echo "    ok"

# ---------------------------------------------------------------------------------------------
step "3/8 Lint (swiftlint --strict, swiftformat --lint)"
swiftlint lint --strict --quiet || fail "swiftlint"
swiftformat --lint . --quiet || fail "swiftformat"

step "4/8 Generate project (xcodegen)"
xcodegen generate --quiet || fail "xcodegen"

rm -rf "$RESULTS"; mkdir -p "$RESULTS" .verify

step "5/8 Build for testing ($SIM_NAME)"
wait_for_other_builds
"${XCB[@]}" build-for-testing 2>&1 | pretty || fail "build"

show_failures() {
  [ -d "$1" ] || return 0
  xcrun xcresulttool get test-results summary --path "$1" 2>/dev/null \
    | jq -r '.testFailures[]? | "    FAILED \(.targetName // "") \(.testName): \(.failureText)"' 2>/dev/null || true
}
only_testing() { local t; for t in "$@"; do printf -- '-only-testing:%s ' "$t"; done; }

step "6/8 Unit tests (Swift Testing): ${UNIT_TARGETS[*]}"
wait_for_other_builds
# shellcheck disable=SC2046
"${XCB[@]}" test-without-building $(only_testing "${UNIT_TARGETS[@]}") \
  -resultBundlePath "$RESULTS/unit.xcresult" 2>&1 | pretty \
  || { show_failures "$RESULTS/unit.xcresult"; fail "unit tests"; }

step "7/8 UI tests (XCUITest): ${UI_TARGETS[*]}"
wait_for_other_builds
# shellcheck disable=SC2046
"${XCB[@]}" test-without-building $(only_testing "${UI_TARGETS[@]}") \
  -resultBundlePath "$RESULTS/ui.xcresult" 2>&1 | pretty \
  || { show_failures "$RESULTS/ui.xcresult"; fail "UI tests"; }

step "7b/8 iPad compatibility launch smoke ($IPAD_SIM_NAME; architecture §6)"
wait_for_other_builds
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "platform=iOS Simulator,name=${IPAD_SIM_NAME}" \
  -derivedDataPath "$DERIVED" -parallel-testing-enabled NO -quiet build-for-testing 2>&1 | pretty || fail "iPad build"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "platform=iOS Simulator,name=${IPAD_SIM_NAME}" \
  -derivedDataPath "$DERIVED" -parallel-testing-enabled NO -quiet test-without-building \
  -only-testing:CaloUITests/LaunchSmokeUITests -resultBundlePath "$RESULTS/ipad.xcresult" 2>&1 | pretty \
  || { show_failures "$RESULTS/ipad.xcresult"; fail "iPad launch smoke"; }
xcrun simctl shutdown all >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------------------------
step "8/8 Result checks (nothing skipped, nothing dropped)"
total_tests=0
for bundle in unit ui ipad; do
  summary="$(xcrun xcresulttool get test-results summary --path "$RESULTS/$bundle.xcresult")" \
    || fail "cannot read $bundle.xcresult"
  read -r total passed failed skipped expected <<< "$(jq -r \
    '[.totalTestCount, .passedTests, .failedTests, .skippedTests, .expectedFailures] | map(. // 0) | @tsv' \
    <<< "$summary")"
  echo "    $bundle: $total run, $passed passed, $failed failed, $skipped skipped, $expected expected failures"
  [ "$total" -gt 0 ] || fail "$bundle: no tests ran"
  [ "$failed" -eq 0 ] || fail "$bundle: $failed failed"
  [ "$skipped" -eq 0 ] || fail "$bundle: $skipped skipped (a skipped test is a failure here)"
  [ "$expected" -eq 0 ] || fail "$bundle: $expected expected failures (withKnownIssue / XCTExpectFailure hide a failure)"
  [ "$passed" -eq "$total" ] || fail "$bundle: $passed of $total passed"
  total_tests=$((total_tests + total))
done

assertions="$( (grep -rhE --include='*.swift' -v '^[[:space:]]*//' Tests UITests 2>/dev/null || true) \
  | (grep -oE '#expect\(|#require\(|XCTAssert[A-Za-z]*\(|XCTFail\(|XCTUnwrap\(' || true) | wc -l | tr -d ' ')"
echo "    $total_tests tests, $assertions assertions"
baseline=""
if [ -n "$BASE" ] && git cat-file -e "$BASE:${PREFIX}$LAST_GREEN" 2>/dev/null; then
  baseline="$(git show "$BASE:${PREFIX}$LAST_GREEN")"
elif [ -f "$LAST_GREEN" ]; then
  baseline="$(cat "$LAST_GREEN")"
fi
if [ -n "$baseline" ]; then
  last_tests="$(sed -n 's/^tests=//p' <<< "$baseline")"; last_assertions="$(sed -n 's/^assertions=//p' <<< "$baseline")"
  [ "$total_tests" -ge "${last_tests:-0}" ] \
    || fail "test count dropped: $total_tests now, $last_tests at the last green run"
  [ "$assertions" -ge "${last_assertions:-0}" ] \
    || fail "assertion count dropped: $assertions now, $last_assertions at the last green run"
fi
printf 'tests=%s\nassertions=%s\n' "$total_tests" "$assertions" > "$LAST_GREEN"
tree_fingerprint > "$GREEN_STAMP"

step "verify.sh: ALL PASSED ($total_tests tests, $assertions assertions)"
