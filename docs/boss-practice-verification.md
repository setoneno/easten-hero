# Boss practice input fix — 2026-10-10

The previous F9 shortcut conflicted with Godot 4.7's embedded-game Pause (F9). Editor suspension stops physics/idle frames while still rendering and processing input, explaining the scene switching but both actors stopping. The earlier standalone CLI test did not exercise this editor shortcut and only checked the scene/state, so it missed the problem.

Reference: [Godot 4.7 game embedding, Pause (F9)](https://docs.godotengine.org/en/4.7/tutorials/editor/game_embedding.html#pause-f9).

## Fix and run

- Removed F9 as a game shortcut. B now starts/retries boss practice.
- Added a bottom-right Boss practice (B) button; in practice it reads Retry boss (B).
- Both entry points use the same guarded deferred scene transition.
- Stop any suspended run with F8, start again with F5, click the game view and press B or click the practice button. Confirm ROUND 5 / 5 and boss HP; WASD/arrows move and Space/LMB throw. R retries after victory/defeat; B/button start a fresh practice run.
- Normal F5 remains Round 1. F6 on the selected boss_test scene remains supported.

## Files and checks

Updated scripts/game_over_ui.gd, scripts/boss_test.gd, scenes/main.tscn, tests/boss_practice_verify.gd and README.md. Notion records the cause, correction and pending user check.

Normal-render boss practice test: PASS, 0 failures, exit 0; docs/boss-practice-error.log empty. It now holds actual S input to verify player displacement, observes boss pursuit displacement, holds Space to verify actual throws and waits for charge timers to advance. It also checks B switching, test preset/HUD, victory/R retry, defeat/B retry and the practice button's signal route.

Phase 4 and Phase 10 headless regression tests pass. The user's Godot embedded-game operation after the change remains to be confirmed; the corrected movement test uses a standalone normal-render game. No editor settings or suspension state were changed. Phase 10 and Ver 1.0 remain user-confirmation pending.
