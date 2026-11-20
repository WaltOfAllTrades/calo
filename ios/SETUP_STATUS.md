# SETUP_STATUS — Calo iOS (briefing)

_Last updated 2026-11-20 ~11:00. Resume point and the next-session prompt at the bottom._
_Full breakdown of this run: `docs/REPORT-2026-11-20.md`. Running log: `PROGRESS.md`._

## State
- Repo `WaltOfAllTrades/calo` (public), local clone `~/Developer/Calo`. The web app at the root and its
  GitHub Pages deploy from `main` are untouched. Everything native lives in `ios/`.
- Branch `ios`: `3f9f62f` (spec, skeleton, first cut), `a50ead8` (review fixes, entry convention,
  accessibility, UI tests), `13083b0` (Construction Master parity, original Calo keys, Classic keys),
  then the docs/feature-flip commit (`pass-feature.sh` fixed to read `dependsOn` across both feature files).
  **Gate green on `13083b0` at 11:30: 163 tests, 765 assertions**, rerun on the script fix before the flips.
  All 32 features pass. Merged to `main` by PR (report §9).
- Two products in one install (`com.waltofalltrades.calo`): **Calo** (the web app, native, your keypad
  design) and the **construction calculator** (16 functions, exact fraction engine, tape, memory, five
  looks). Settings → Experiments → Open as switches between them. They share `DesignSystem` only.
- Tests: 142 unit (668 expectations), 20 UI with accessibility audits, iPad launch smoke. Every formula is
  tested against the Construction Master Pro user guide's worked examples.

## To get it on your phone
```bash
ios/scripts/refresh-device.sh
```
Phone unlocked, Developer Mode on. The first install registers the App ID (one of your 10 per 7 days) and
the free profile lasts 7 days; rerun the script to renew.

## Decisions you may want to overrule (all in PROGRESS.md, summarised in the report §7)
- GRDB for Calo's storage; Calo follows the system appearance (the web app was dark only).
- Calo deviations from the web app: no dead "Reports" button; zero-only entries not logged; swipe to delete,
  tap to edit; Settings is a sheet; Enter clears the keypad before the write and restores on failure.
- Calculator entry: the inch mark separates whole inches from a fraction (`5 ′ 3 ″ 1 ⁄ 2` → `5′ 3-1⁄2″`).
  A bare number added to a length is inches (mm in metric) and the line shows it.
- Accessibility audits run without the contrast rule on glass screens (your Curata call), without the
  Dynamic Type rule on the two keypad screens (the spec caps key labels), and with the Calo settings sheet
  raised to full height. The header date is one width, not three (clipped-text rule).
- Still out, by choice (SPEC "Do not build"): paint, tile, decking and fence estimators; per-unit cost beyond
  board feet; "Constant" fraction mode; Jobber-style sixteenths entry.

## One thing I could not do (needs you)
The auto-mode classifier refused to let me write `.claude/settings.json` at the repo root (it registers the
edit-protection hook). The gate still catches protected-file changes at merge time. To add the in-editor
block, create `.claude/settings.json` with:
```json
{ "hooks": { "PreToolUse": [ { "matcher": "Edit|Write|MultiEdit|NotebookEdit",
  "hooks": [ { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/ios/scripts/hooks/protect-paths.sh" } ] } ] } }
```

## Working on a shared Mac
One simulator, one `xcodebuild`. If another session is building, queue the gate behind it:
```bash
cd ~/Developer/Calo/ios && (nohup bash -c 'while pgrep -x xcodebuild >/dev/null; do sleep 20; done; sleep 30; ./scripts/verify.sh' > .verify/run.log 2>&1 &)
```
Never kill another session's `xcodebuild`; our 08:33 run was killed that way from outside.

## Resume point
If PROGRESS.md's last entry says the gate was green and `main` carries the merge: start the next session
with the prompt below. If it says red: fix, rerun `ios/scripts/verify.sh`, then flip, PR, merge.

## Prompt for the next session (paste as is, start it in `~/Developer/Calo`)
```text
Calo (~/Developer/Calo), the iOS work in ios/. Read ios/SETUP_STATUS.md, ios/docs/REPORT-2026-11-20.md,
then ios/PROGRESS.md (today, bottom) and ios/CLAUDE.md. main carries the ios merge: two native products in
one install (Calo and the construction calculator), every feature in ios/spec/*/features.json passes, the
gate ios/scripts/verify.sh is green. GOAL.md is the assignment of record; ios/spec/ is the spec.

Goal for this session: get both apps on my iPhone and walk them with me, then fix what I find.
1. Run ios/scripts/refresh-device.sh (phone unlocked, Developer Mode on). First install registers the App ID.
   Report the profile expiry it prints.
2. Walk me through a test script, one step per message, waiting for my report after each:
   Calo: log an amount with + and −, bonus keys, 00, backspace, item and details fields on and off, the dash
   and remaining after a target change, Today's Log (edit, swipe to delete), clear daily log, About, light
   and dark. Calculator (Experiments → Open as): type 5 ′ 3 ″ 1 ⁄ 2 + 2 ′ 9 ″ 3 ⁄ 4 =, cycle the unit and
   precision chips, hold a key for help, tape reuse, memory, each of the 16 functions with its worked
   example from ios/spec/calculator/formulas.md, each of the five looks, Settings.
   Things XCUITest could not prove and I must confirm by hand: the keys feel like real keys (Calo original,
   calculator Classic), the 375×667 layout fits without scrolling, VoiceOver reads the dash and the result.
3. Anything that feels wrong: fix it on a feature/<id>-<slug> branch off main, adversarial review before a
   significant commit, ios/scripts/verify.sh green, PR, merge it yourself. UI decisions I make on the phone
   win over the spec; log each in ios/PROGRESS.md and, since the spec is mine, propose the spec edit text.
4. Keep a running list of what I decide (the picks already owed are in ios/SETUP_STATUS.md under
   "Decisions you may want to overrule").
Fixed values stay fixed (bundle ID com.waltofalltrades.calo, team Z3W92U6PBC, free tier, no paid
capabilities). One simulator and one xcodebuild at a time; if another session is building, queue behind it
(SETUP_STATUS.md → Working on a shared Mac). Decide and log; ask me only about fixed signing values and
spec changes.
```
