# Calo — tests

What `scripts/verify.sh` runs and the build must keep green. Swift Testing unless marked UI. Tests live under
`Tests/` and `UITests/` and are read-only to the loop once on `main`.

## CaloKit (`Tests/CaloKitTests`)
- `EntryTests`: `signedCalories` for add and subtract; name and details trimmed; empty strings stored, not nil.
- `DayWindowTests`: window for a pinned `now` in a pinned zone; the moment before midnight is today, midnight is tomorrow; DST days.
- `SettingsTests`: defaults; decoding with missing and unknown keys; round trip; target range.
- `LogStoreTests` (serialized, in-memory GRDB and memory store through the same protocol): add → today's rows;
  rows outside the window excluded; totals = sum; update changes `updatedAt`; delete; clearToday leaves other days.
- `MigrationTests`: v1 applies to an empty database; schema has the `entry` table and its `createdAt` index.

## App logic (`Tests/CaloAppTests`, hosted)
- `KeypadModelTests`: append; 5-character cap incl. "00" and bonus keys (E-C04); backspace; clear; intent switch; enter
  with empty buffer is a no-op (E-C05); enter with zeros is a no-op that clears (E-C03); enter emits value with the
  intent then resets to add and clears; busy guard (E-C01); failure keeps state (E-C02).
- `DashModelTests`: logged and remaining from a seeded store; negative remaining; refresh after add; rollover recompute (E-C07).
- `NoLiteralStringsLint`: no literal in `Text(`/`Label(` under `App/Features/Calo`; one date formatter.
- `ExperimentsRoutingTests`: `openAs` defaults to Calo; the root picks the product from the stored value.

## UI (XCUITest, iPhone 17, `-calo.uitest` → memory store, `now` pinned to 2026-11-20 10:00 local, seeded entries)
- `logsAnEntry`: tap 2, 5, 0, Enter → logged increases by 250, remaining decreases, buffer empty, intent ADD.
- `subtractsAnEntry`: tap −, 1, 0, 0, Enter → logged decreases by 100; intent back to ADD.
- `bufferCap`: 80, 80, 80 → buffer "8080" (third ignored per E-C04 would make 6), C clears.
- `settingsFieldsAndTarget`: toggle Show log name on → Item field visible; set target 1500 → remaining recomputes.
- `todayLogEditDelete`: open Today's Log, tap a row, change calories, Save → row updates; swipe delete → row gone; empty state after deleting all.
- `clearDailyLogTwoTap`: Clear → "Tap to confirm removal" → tap → "Daily log cleared" → dash shows 0 / target.
- `aboutPage`: text present.
- `accessibilityAudit`: `performAccessibilityAudit(for: .all.subtracting(.contrast))` on Main, Settings, Log.
- `iPadLaunchSmoke`: launches on an iPad simulator without crashing (compatibility mode).
