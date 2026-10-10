# Phase 9 verification — 2026-10-10

Status: user playtest confirmed on 2026-10-10. The user authorized Phase 10 next. The following implementation results describe the historical Phase 9 build; Phase 10 replaces its pending boss screen with combat.

## Approved scope

The user confirmed that the boss itself belongs to Phase 10. Phase 9 implements three shrines per round, magatama release, exactly five rounds, and the final-battle handoff. Round 5 pickup pauses at a clearly labeled unimplemented boss encounter. It does not award GAME CLEAR or advance to Round 6.

## Implementation

- `scripts/prayer_shrine.gd`: pixel wooden shrine and entrance marker. Approaching within 18 world pixels automatically prays once. Gold markers become green checks; repeated visits add nothing. Paused/dead players cannot pray.
- `scripts/shrine_trials.gd`: reuses the existing large shrine and adds two small shrines near (320, 480) and (800, 960). Placement searches nearby clear footprints and validates reachable entrances. New walls participate in collision/navigation; roof occluders apply the existing behind-character alpha policy.
- `scripts/objective_item.gd`: locks and hides the magatama at round start, rejects hidden pickup, and releases it at a reachable clear location only after the third distinct prayer.
- `scripts/main.gd`, `scenes/main.tscn`: HUD prayer count, progress notices, release, round reset, five-round cap, and one-shot `final_battle_requested` handoff. Shrine scenery draws before the player. R restarts from the pending final battle.
- Rounds 1–4 retain the 120 EXP clear bonus and queued upgrade selection before Next/N. Level, EXP and upgrades carry forward; prayer count and magatama reset each round. Round 5 handoff grants no ordinary round-clear bonus.
- The five rounds alternate existing layouts: Riverside, Forest, Riverside, Forest, Riverside. This is five rounds, not five unique maps.
- `tests/phase_1_verify.gd` through `tests/phase_8_verify.gd`: isolate their historical checks from the new shrine gate. Phase 6 restart expects the production locked objective; Phase 7 now checks the five-round cap. `tests/phase_9_verify.gd` exercises the production shrine gate.
- `README.md`: updated Run, Verify, project structure and scope/status.

## Verification results

Godot 4.7.2, Windows, Compatibility renderer, NVIDIA GTX 1050 Ti.

- Project import: exit 0.
- Phase 1–9 headless verification scripts: all PASS, exit 0. See `phase-9-regression-1.log` through `phase-9-regression-9.log`.
- Phase 9 normal-render verification: PASS, exit 0; `phase-9-render-error.log` empty.
- Normal main-scene startup for 120 frames: exit 0; `phase-9-startup-error.log` empty. This uses the same main scene as F5, with normal enemy settings.
- `git diff --check`: passed.
- Viewed normal-render screenshots: `phase-9-shrine-preview.png`, `phase-9-roof-preview.png`, `phase-9-final-pending-preview.png`. Entrance marker, HUD count, behind-roof transparency and pending final battle render correctly.

Phase 9 automation verifies exactly three reachable entrances on every round; real movement/proximity prayer; no duplicate counts; no early magatama; third-prayer release; reachable item placement; new shrine collision and front/behind opacity; Round 1–4 clear/upgrade/advance; carried progression; fresh per-round objective; exactly one final-battle handoff; no Round 6 or false GAME CLEAR; R restart; and death taking priority over scheduled prayer.

## User Run / Verify

1. Open `project.godot` in Godot and press F5.
2. Find the large shrine and two small wooden shrines. Approach each gold entrance marker; confirm HUD advances 0/3 → 3/3, markers turn green, and revisiting does not count again.
3. Confirm no magatama exists before the third prayer, then find and collect the released item.
4. Finish upgrade choices and use Next/N on Rounds 1–4. Confirm progression carries over and each new round starts with three unvisited shrines and no magatama.
5. Check collision and transparency behind the small shrine roofs, alongside existing scenery.
6. On Round 5 collect the released magatama. Confirm the pending boss screen, no GAME CLEAR/Next/Round 6, and R restarting Round 1.

## Unconfirmed / deferred

The user's interactive F5 playtest, exploration balance and audio experience are awaiting confirmation. Five unique map layouts were not added. The final boss, actual boss battle, boss defeat and GAME CLEAR belong to Phase 10 and have not been implemented. The previously deferred sideways walking polish remains unchanged.
