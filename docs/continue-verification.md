# Ver 1.0 additional revision — Continue (2026-10-10)

Scope: same-round GAME OVER continuation from the round-entry checkpoint. The separate Notion release-polish section (title/menu flow, pause, debug visibility) is not implemented in this revision.

## Behavior

- Main captures a checkpoint after initial setup and after each completed next-round setup. It contains round/layout, Level, remaining EXP, a copied ability-level array, HP/max HP, movement speed, attack damage/interval/projectile speed/range, protection duration, aim mode and defeat count.
- GAME OVER waits for CONTINUE (R), by keyboard or button. It restores the entry values, discards failed-round EXP/upgrades, resets shrines to 0/3 and locks/hides the jade. Entry HP is restored exactly, even when below maximum. It does not heal to full.
- Removes the old spawner, enemies including boss, swords and hostile arrows; rebuilds the map and shrine gate, resets the player to the safe starting position, clears death/protection/hit/cooldown/menu flags and feedback, and resumes fresh spawning. The checkpoint is not overwritten by a retry, allowing repeated identical recovery.
- A Round 5 boss death returns to Round 5 before shrine visits; collecting the newly released jade can summon a fresh boss again.
- GAME CLEAR → R and ROUND CLEAR → R retain fresh-run behavior. Boss-only practice remains an independent retry preset, with an explicit RETRY PRACTICE button/text.
- Checkpoints are in memory for the current run. Cross-launch save files and the title-menu CONTINUE flow belong to separate release work. Sound preference is retained.

## Files

Updated scripts/main.gd, scripts/game_over_ui.gd, scripts/boss_test.gd, scenes/main.tscn, README.md and tests/phase_4_verify.gd / phase_7_verify.gd. Added tests/continue_verify.gd, this report and continue-* logs / screenshot.

The Phase 4 fixture now names its manually added spawner and restores production spawn enablement before continuing. Its previous reload expectation implicitly discarded fixture settings; continuation retains the current scene configuration. Phase 7's historical Round 1-on-death expectation was updated to the new Round 5-entry behavior.

## Verification

Godot 4.7.2 on Windows / Compatibility renderer.

- New continue integration: headless and normal renderer PASS, zero failures, exit0, stderr empty.
- Tests use actual R input and the button signal, repeat Round 2 failures with added EXP/upgrades, assert exact entry stats/HP/aim/ability levels and shrine/jade reset, check four fresh enemies and cleanup, then test boss death → Round 5 reset → boss reappearance → GAME CLEAR → fresh Round 1.
- Phase 4, 7, 10, boss-practice and UI/display headless regressions verify existing behavior with updated continuation expectations.
- Viewed continue-death.png: the stopped GAME OVER scene has a readable CONTINUE (R) button.

## Manual verification pending

F8 → F5. Reach Round 2 or later, note entry HP/growth, then earn additional EXP/upgrades and die. Use R or CONTINUE and confirm same-round entry values, lost failed-round gains and 0/3 shrines. Repeat after summoning the Round 5 boss. Verify that victory → R starts Round 1. Manual feel, intended rollback values and the restored scene's gameplay are awaiting user confirmation. No separate release-polish features were started.
