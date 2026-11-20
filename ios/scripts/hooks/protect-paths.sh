#!/bin/bash
# PreToolUse hook (Edit, Write, MultiEdit, NotebookEdit). Register it in the repository's
# .claude/settings.json (see SETUP_STATUS.md; the agent may not write that file itself).
#
# Why: code-standards 12, "tests are not edited to pass". The build loop may ADD tests but may not
# change one that is already on main, and may not touch the spec or the gate at all.
#
#   ios/spec/**                        always blocked (flip `passes` with scripts/pass-feature.sh)
#   ios/Tests/**, ios/UITests/**       blocked once the file exists on main; new files are allowed
#   the gate and its settings          blocked once on main: ios/scripts/verify.sh, ios/scripts/pass-feature.sh,
#                                      ios/scripts/hooks/**, ios/.swiftlint.yml, ios/.swiftformat,
#                                      ios/.verify/last-green.txt, .claude/settings.json
#
# Exit 2 blocks the tool call and shows stderr to the agent. Shell commands are not seen by this hook;
# scripts/verify.sh step 1 catches those at the gate.
set -u

input="$(cat)"
file="$(printf '%s' "$input" | /usr/bin/jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)"
[ -z "$file" ] && exit 0

case "$file" in /*) ;; *) file="$PWD/$file" ;; esac
normalized=""
old_ifs="$IFS"; IFS=/
for part in $file; do
  case "$part" in
    '' | .) ;;
    ..) normalized="${normalized%/*}" ;;
    *) normalized="$normalized/$part" ;;
  esac
done
IFS="$old_ifs"
[ -z "$normalized" ] && exit 0

dir="$(dirname "$normalized")"
while [ ! -d "$dir" ] && [ "$dir" != "/" ]; do dir="$(dirname "$dir")"; done
real_dir="$(cd "$dir" && pwd -P)" || exit 0
abs="$real_dir${normalized#"$dir"}"

root="$(git -C "$real_dir" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -f "$root/ios/spec/README.md" ] || exit 0   # not a Calo checkout
case "$abs" in "$root"/*) rel="${abs#"$root"/}" ;; *) exit 0 ;; esac
rel_lower="$(printf '%s' "$rel" | tr '[:upper:]' '[:lower:]')"

on_main() {
  local ref
  for ref in origin/main main; do
    if git -C "$root" ls-tree -r --name-only "$ref" 2>/dev/null | grep -qixF -- "$1"; then return 0; fi
  done
  return 1
}
guard_is_live() { on_main "ios/scripts/hooks/protect-paths.sh"; }
deny() {
  echo "Blocked by ios/scripts/hooks/protect-paths.sh: $rel" >&2
  echo "$1" >&2
  exit 2
}

case "$rel_lower" in
  ios/spec/*)
    deny "ios/spec/ is the spec and only Walt changes it. To record a passing feature run ios/scripts/pass-feature.sh <id>. If the spec looks wrong, log it in ios/PROGRESS.md and ask Walt."
    ;;
  ios/scripts/verify.sh | ios/scripts/pass-feature.sh | ios/scripts/hooks/* | .claude/settings.json | ios/.swiftlint.yml | ios/.swiftformat | ios/.verify/last-green.txt)
    if guard_is_live && on_main "$rel"; then
      deny "The gate and its settings are read-only to the build loop (code-standards 12)."
    fi
    ;;
  ios/tests/* | ios/uitests/*)
    if guard_is_live && on_main "$rel"; then
      deny "This test is already on main, and tests are not edited to pass (code-standards 12). Fix the code, add a new test file, or log the disagreement in ios/PROGRESS.md for Walt."
    fi
    ;;
esac
exit 0
