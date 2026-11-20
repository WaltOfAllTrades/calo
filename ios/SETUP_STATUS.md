# SETUP_STATUS — Calo iOS (morning briefing)

_Last updated 2026-11-20 ~07:10 by the overnight session. Resume point at the bottom._

## State
- Branch `ios`, folder `ios/`. First commit `3f9f62f` holds the spec, the skeleton, the Calo port, the
  calculator engine with all nine functions and screens, and the Experiments switch. Nothing on `main` yet.
- Unit tests: 109 green (DesignSystem 6, CaloKit 18, CalcKit 61, app logic 24). UI tests: 20 written, being
  made green when this was written (see PROGRESS.md for the last run).
- Gate: `ios/scripts/verify.sh` (also runs the iPad launch smoke). Features: `ios/spec/calo/features.json`
  (C-001…C-050) and `ios/spec/calculator/features.json` (K-010…K-050); flags flip only after a green gate.

## To get it on your phone
```bash
ios/scripts/refresh-device.sh
```
Phone unlocked, Developer Mode on. First install registers the App ID `com.waltofalltrades.calo`. The install
opens as Calo; Settings → Experiments → Open as → Calculator switches (takes effect when the sheet closes).

## Decisions you may want to overrule (all logged in PROGRESS.md)
- GRDB for Calo's storage (not SwiftData). Calo follows the system appearance (web app was dark only).
- Calo deviations from the web app: no dead "Reports" button; zero-only entries not logged; swipe to delete,
  tap to edit; Settings is a sheet; enter clears the keypad before the write (the web order) and restores on failure.
- Calculator entry: the inch mark separates whole inches from a fraction (`5 ′ 3 ″ 1 ⁄ 2` → `5′ 3-1⁄2″`), as on
  the Construction Master. A bare number added to a length is inches (mm in metric) and the line shows it.
- Calculator default look is `Glass`; `Tape`, `Daylight` and `Blueprint` are in Settings → Look.
- Accessibility audits run without the contrast rule on glass screens (your Curata call) and without the
  Dynamic Type rule on the two keypad screens, because the spec caps key labels at the accessibility1 size.

## One thing I could not do (needs you)
The auto-mode classifier refused to let me write `.claude/settings.json` at the repo root, which registers
the edit-protection hook. The gate still catches protected-file changes at merge time. If you want the
in-editor block too, create `.claude/settings.json` with:
```json
{ "hooks": { "PreToolUse": [ { "matcher": "Edit|Write|MultiEdit|NotebookEdit",
  "hooks": [ { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/ios/scripts/hooks/protect-paths.sh" } ] } ] } }
```

## Resume point
Read `PROGRESS.md` (today), run `ios/scripts/verify.sh`, fix what is red, then `ios/scripts/pass-feature.sh`
for every feature whose acceptance holds, open the PR from `ios` to `main`, merge it.
