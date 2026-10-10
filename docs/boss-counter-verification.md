# Phase 10 — immediate attacks and counter window (2026-10-10)

The user requested removal of attack warnings and a limited damage window starting at the boss's attack. This remains Phase 10; user playtest and final difficulty confirmation are pending.

## Behavior

- Removed arrow and naginata windup states, warning lines and warning fans. Arrows launch immediately; the naginata damages at swing start. Its short visible fan represents the actual swing.
- Each arrow volley or naginata swing opens a 0.6-second damage window, including missed or terrain-blocked swings. FinalBoss's exported Damage Window can tune this duration.
- Incoming player damage is accepted only during this window. Sword impact time decides acceptance, regardless of when the sword was thrown. Outside it, GUARD feedback appears without losing HP; inside it, OPEN shows remaining time and the boss has a warm tint. Multiple hits within the window are allowed.
- Gameplay pause freezes the window and prevents damage. Existing movement, arrow collision, fan angle/range/terrain checks, defeat priority and behind-scenery transparency remain.

## Changed files

- scripts/final_boss.gd: immediate attack states, timed vulnerability, guarded damage and feedback.
- tests/phase_10_verify.gd: actual attack opening, expiry, pause, sword impact timing and immediate attack regression checks.
- tests/boss_practice_verify.gd: updated victory fixture and isolated live input/timer checks.
- README.md: current Run / Verify and tuning instructions.
- docs/boss-revision-verification.md: historical report pointer; this report, logs and updated preview images.

## Verification

Godot 4.7.2 on Windows, Compatibility renderer.

- Phase 10 integration, headless and normal renderer: PASS, zero failures, exit 0.
- Boss practice integration, normal renderer: PASS, zero failures, exit 0.
- Normal-render stderr logs are empty; new verification logs contain no ERROR, WARNING or FAIL. git diff --check passed.
- Verified guarded real sword impacts, accepted impacts after opening, rejected impacts after closing, real window expiry, pause freezing, immediate arrows/swing, attack geometry and terrain, movement/occlusion, practice controls and victory/death behavior.
- Viewed phase-10-counter-open-preview.png and phase-10-counter-guard-preview.png for OPEN/GUARD appearance.

Evidence: boss-counter-headless.log, boss-counter-render.log, boss-counter-render-error.log, boss-counter-practice.log and boss-counter-practice-error.log.

## User verification pending

Stop the existing run with F8, start with F5, focus the game and press B (or use the Boss practice button). Check that attacks have no advance warnings, damage outside OPEN is guarded, and counterattacks during the 0.6-second window feel appropriate. Human reaction difficulty and preferred window duration are unconfirmed. No further phase was started.
