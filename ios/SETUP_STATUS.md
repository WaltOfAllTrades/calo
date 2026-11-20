# SETUP_STATUS — Calo iOS (morning briefing)

_Last updated 2026-11-20 05:40 by the overnight session. Resume point at the bottom._

## State
- Branch `ios`, folder `ios/`. Skeleton in progress: spec written for Calo; calculator spec waits on the
  feature research. Nothing merged to `main` yet.
- Gate: `ios/scripts/verify.sh`. Features: `ios/spec/calo/features.json`, `ios/spec/calculator/features.json`.

## To get it on your phone
```bash
ios/scripts/refresh-device.sh
```
Phone unlocked, Developer Mode on. First install registers the App ID `com.waltofalltrades.calo`.

## One thing I could not do (needs you)
The auto-mode classifier refused to let me write `.claude/settings.json` at the repo root, which is what
registers the edit-protection hook. The gate still catches protected-file changes at merge time. If you want
the in-editor block too, create `.claude/settings.json` with:
```json
{ "hooks": { "PreToolUse": [ { "matcher": "Edit|Write|MultiEdit|NotebookEdit",
  "hooks": [ { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/ios/scripts/hooks/protect-paths.sh" } ] } ] } }
```

## Resume point
Read `PROGRESS.md` (today), then pick the first unpassed feature in `spec/calo/features.json`.
