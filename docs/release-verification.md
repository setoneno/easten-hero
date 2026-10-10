# Ver 1.0 release polish — menu flow, pause and debug hiding (2026-10-10)

Same-round continue was confirmed by the user. This revision implements the next authoritative Notion section and awaits user playtest.

## Behavior and decisions

- F5/application startup opens TITLE with NEW GAME / CONTINUE / EXIT. Continue requires a validated saved checkpoint. NEW GAME starts Round 1 and replaces progress with its initial entry; no simulation starts behind the title.
- Game Over offers CONTINUE / TITLE / EXIT. Continue restores the existing round-entry checkpoint, including Round 5 before shrines and boss. Game Clear offers NEW GAME / TITLE / EXIT and waits for explicit selection. R remains an explicit continue/new-game shortcut on these result screens. On normal Round Clear, R returns to Title rather than silently resetting progress.
- Esc or the HUD PAUSE button opens RESUME / TITLE / EXIT. Esc also resumes this pause. Upgrade selection, round clear and game-over/clear cannot be bypassed with Esc. Simulation and feedback timers freeze, while menu input remains active. Title ends the attempt, removes its world and clears pause without discarding the checkpoint.
- Saves use versioned JSON at user://checkpoint.json. Round entries are persisted by temporary-file replacement. Title reloads from disk; missing/corrupt/unsupported data disables Continue. Only explicit NEW GAME resets progress, including that action selected from Game Clear. Title/Exit preserve the most recent entry, even after victory.
- Main's Debug Tools Enabled defaults off. Both that flag and OS.is_debug_build() are required for B / Boss practice and boss OPEN/GUARD/timer hints. Normal play retains boss HP, ordinary combat color feedback and other player-facing HUD information. GUARD debug popups are also hidden. Practice never writes the normal save.
- Standalone gameplay integration fixtures bypass title-managed persistence so they do not overwrite a player's save. New tests use separate filenames and clean their own files.

## Files

New: scenes/title.tscn, scripts/title.gd, scripts/menu_layout.gd, scripts/game_session.gd (and Godot UIDs), tests/release_flow_verify.gd, tests/menu_exit_verify.gd, tests/checkpoint_disk_verify.gd, this report and release-* logs/PNG evidence.

Updated: project.godot (entry/autoload), scripts/main.gd, scripts/game_over_ui.gd, scripts/game_feedback.gd, scripts/final_boss.gd, scripts/boss_test.gd, scenes/main.tscn, tests/boss_practice_verify.gd (explicit development flag) and README.md.

## Verification

Godot 4.7.2 / Windows / Compatibility renderer.

- Release-flow integration, headless and normal rendering: PASS, zero failures, exit0, stderr empty. Covers title/new/continue, disabled Continue without a save, rollback from Game Over, Game Clear menus, repeated world replacement, old actor/projectile cleanup, pause buttons and real Esc, frozen player/enemy/sword/arrow/boss/spawn/damage/protection/feedback timers, pause-state conflicts, default debug hiding and B rejection, and corrupt-save handling.
- Cross-process disk check: one process writes a Round 3 entry, then a separate process loads and restores its HP/growth/shrines. Both PASS, exit0, stderr empty.
- EXIT invoked through each actual title/pause/Game Over/Game Clear button in separate processes. All terminated with exit0 before the failure timeout; stderr empty.
- Headless continue, Phase 4/5/6/7/9/10, boss-practice and UI/display regressions all PASS, zero failures, exit0, stderr empty. Normal-render development practice also PASS.
- Normal configured application startup for 120 frames succeeds with no errors. Import succeeds; git diff --check passes. Final release-* logs contain no ERROR / WARNING / FAIL.
- Viewed release-title.png, release-pause.png, release-game-over.png and release-game-clear.png for readable menu layout. Development iterations corrected full-stretch anchor sizing and used JSON.parse() to reject corrupt data without emitting an Output error. Final logs supersede those iterations.

Commands (with the README's $godotExe):

    & $godotExe --path . --script res://tests/release_flow_verify.gd
    & $godotExe --headless --path . --script res://tests/checkpoint_disk_verify.gd -- write
    & $godotExe --headless --path . --script res://tests/checkpoint_disk_verify.gd -- read
    & $godotExe --headless --path . --script res://tests/menu_exit_verify.gd -- Title

For EXIT, repeat with Pause, GameOver and GameClear. Disk write/read must run in order. Tests use their own save paths.

## Manual verification pending

F8 → F5 → TITLE. Check NEW GAME, no-save Continue disabled, pause/resume via both Esc and button, and Title/Exit. Reach a later round and close/relaunch; Continue must restore that entry's HP/growth and shrine 0/3. Check Game Over Continue/Title/Exit and Game Clear New Game/Title/Exit. Confirm no boss practice, B shortcut, OPEN/GUARD or internal timer in normal play. Output/Debugger should remain clean through repeated transitions.

The user's embedded Godot window, human keyboard/mouse experience and exported desktop executable remain unconfirmed. Export templates are not installed in this environment, so no release executable was exported; release-mode gating is implemented in code, and the default hidden state is verified in the available runtime. No packaging/publishing or additional feature work was started.
