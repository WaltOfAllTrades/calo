# Calo — edge cases (decided)

| Id | Case | Handling |
|---|---|---|
| E-C01 | Enter tapped while a log write is in flight | Second tap is ignored and the error line shows `error.busy` (web behaviour). |
| E-C02 | Log write throws | Error line shows `error.failed`; buffer, fields and intent are left as they were so the user can retry. |
| E-C03 | Buffer is only zeros ("0", "00", "000") | Enter clears the buffer and resets the intent; nothing is stored (deviation 2). |
| E-C04 | Buffer would exceed 5 characters | The key is ignored, including a bonus key or "00" that would push it past 5 (web: `next.length > 5 → return`). |
| E-C05 | Empty buffer, Enter | Nothing happens; intent unchanged (web: `if (!buffer) return`). |
| E-C06 | Remaining goes negative | Shown with a leading U+2212, digits still roll. |
| E-C07 | Midnight passes while the app is open | `DayWindow` changes: header date updates, dash recomputes to 0 / target, the log screen (if open) shows the new day. A timer scheduled for the next midnight plus 50 ms, re-armed on each fire and on foreground. |
| E-C08 | Time zone or clock changes | On foreground, recompute `DayWindow` from `now`; entries keep their stored `createdAt`. |
| E-C09 | Daily target field left empty or non-numeric | Value unchanged (web: NaN check). Values above 99999 are clamped by the field's range. |
| E-C10 | Edit entry with non-integer calories | Save does nothing (web behaviour); the sheet stays open. |
| E-C11 | Both detail fields hidden | The details group is removed from layout; the dash grows (web `has-details` class). |
| E-C12 | Clear daily log armed, then the sheet is closed | Disarms; nothing deleted. Armed state also disarms after `Motion.armTimeout`. |
| E-C13 | Clear daily log when today's entries were deleted in the log screen meanwhile | Deletes whatever today's window holds now (possibly nothing); shows `settings.clear.done`. |
| E-C14 | Database cannot be opened at launch | The main screen shows with the error line `error.failed` on first enter; the app does not crash. Logged with OSLog. |
| E-C15 | Very large Dynamic Type | Keypad labels cap at `.accessibility1`; the dash shrinks before the keypad; nothing scrolls on 375×667. |
| E-C16 | Rapid key taps | Each tap applies in order on the main actor; the buffer rules hold. |
