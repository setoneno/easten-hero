# Phase 10 verification — 2026-10-10

Status: implemented; awaiting user Godot playtest. Phase 9 was confirmed by the user on this date. Ver 1.0 is not marked complete before the Phase 10 playtest.

Historical report: the user later confirmed boss-practice operation and requested stronger movement plus arrows/naginata. The current boss replaces the charge/ground strike described below; see `boss-revision-verification.md` and README for current behavior and tuning.

## Scope and decisions

The Notion Phase 10 criteria are: Round 5's three prayers release the magatama; pickup summons a high-HP final boss; the boss has at least two patterns; existing HP, swords and growth work during combat; boss defeat produces GAME CLEAR; GAME OVER and GAME CLEAR are exclusive.

The boss appears on the existing Round 5 map at a clear reachable position near the player, initially outside scenery cover and at least 112px away. Placement checks occupied enemy locations and has a reachable grid fallback. The player is not teleported or healed. Regular enemies and their spawner continue, retaining their EXP and upgrade path. The boss itself does not retire at distance like regular enemies.

Bronze Guardian tuning is provisional:

| Setting | Value |
| --- | --- |
| Boss HP / regular enemy HP | 240 / 20 |
| Pursuit speed | 55px/s |
| Ordinary contact damage | 18 |
| Charge warning / speed / duration | 1.0s / 200px/s / 0.7s |
| Ground strike warning / radius | 0.9s / 52px |
| Charge contact / strike damage | 25 |
| Recovery / pursuit interval | 1.0s / 1.2s |

The boss alternates a locked-direction straight charge and a nearby ground strike. Dotted gold lines warn of the charge; a pixel orange ring warns of the strike. The direction locks before charging, letting the player dodge sideways. Leaving the strike ring avoids damage. Charges stop at scenery, and a scenery ray blocks strike damage through walls. Existing player invulnerability applies to all damage.

The boss uses an original 2px bronze/green/red armor figure, four directional poses and alternating feet, extending the existing enemy implementation. It joins the existing sword target and contact groups. Its taller sprite registers custom character bounds for the existing map occlusion policy: behind 45%, in front/outside 100%.

Round 5 pickup grants no ordinary clear bonus or victory. Boss defeat gives no additional EXP or upgrade queue; it completes the run. Victory is decided after the physics frame, so simultaneous lethal player damage wins. GAME CLEAR freezes gameplay, hides other menus and offers R to restart; no Next or Round 6 exists.

## Files

- New: `scripts/final_boss.gd`, its Godot UID, `scenes/final_boss.tscn`, `tests/phase_10_verify.gd`, this report, and `docs/phase-10-*` logs/screenshots.
- Updated: `scripts/main.gd` (spawn, boss HUD and guarded terminal states), `scripts/exploration_map.gd` (optional custom character bounds), `scripts/game_over_ui.gd` (R on GAME CLEAR), `scenes/main.tscn` (boss HP and separate victory UI).
- Updated: `README.md` Run / Verify, `docs/phase-9-verification.md` user confirmation, and `tests/phase_9_verify.gd` historical handoff fixture. The Phase 9 fixture disables boss combat; Phase 10 tests the default production path.

## Results

Godot 4.7.2 stable, Windows, Compatibility OpenGL 3.3, GeForce GTX 1050 Ti.

- Import: exit 0, no script errors.
- Phase 1–10 headless integration scripts: all PASS, 0 failures, exit 0. `docs/phase-10-regression-1.log` through `phase-10-regression-10.log` contain no ERROR, WARNING or FAIL.
- Phase 10 normal-render integration: PASS, 0 failures, exit 0; `phase-10-render-error.log` is empty.
- F5 main-scene equivalent normal startup for 120 frames: exit 0; `phase-10-startup-error.log` is empty.
- Viewed normal-render images for boss HP/appearance, charge line, strike ring, growth selection and GAME CLEAR. Text and buttons are readable and the victory UI has no Next button. Saved `phase-10-boss-preview.png`, `phase-10-charge-preview.png`, `phase-10-strike-preview.png`, `phase-10-level-preview.png`, `phase-10-clear-preview.png`, `phase-10-game-over-preview.png`.
- `git diff --check`: passed.

Phase 10 integration exercises the actual shrine gate and pickups through all five rounds; no premature boss; one boss spawn; retained HP and upgrades; placement at field edges and both riverbanks; real upgraded sword hits and boss HP bar; a regular enemy kill causing level-up during combat; keyboard upgrade and frozen boss/timers/spawner/damage during selection; ordinary boss contact and invulnerability; warning before damage; strike hit/escape; locked charge direction, dodge and real charge damage; wall-stopped charge and bridge pursuit; rock-blocked strike; foliage/roof/front/exit opacity and all four render poses; real projectile boss defeat; exclusive GAME CLEAR; no Round 6 or post-clear attacks/rewards; R reset; and both orderings of same-frame boss/player lethal damage resolving to GAME OVER only.

The first opacity fixture accidentally stood under the neighboring tree's canopy while testing the front of another tree. Moving the fixture clear of that neighboring canopy resolved the test; no weakening of the scenery policy was needed. Final headless and normal-render runs pass.

## Manual F5 check

1. Open `project.godot`, F5, and complete the three-shrine/magatama/upgrade loop through Rounds 1–4.
2. In Round 5, visit three shrines and collect the magatama. Confirm one boss appears, gameplay continues, and carried HP/upgrades remain.
3. Watch boss HP and attack hints. Dodge the gold-line charge sideways and leave the orange strike ring. Check damage, invulnerability, scenery collision and behind-scenery visibility.
4. Defeat a regular enemy at an EXP threshold. Confirm the full fight pauses for upgrade selection and resumes after choosing.
5. Defeat the boss with swords. Confirm GAME CLEAR, frozen gameplay, no Next/Round 6, and R returning to Round 1 with base abilities and reset shrines.
6. On another run, lose during boss combat and confirm only GAME OVER, then R. Check Godot Output and Debugger throughout.

## Unconfirmed

The user's interactive F5 boss playtest, five-round difficulty/remaining-HP balance, warning readability while fighting crowds, attack tuning and long-session feel remain unconfirmed. Existing sideways walking polish remains deferred. Audio event/data checks are covered by regression; subjective sound quality is not newly confirmed. Phase 10 and Ver 1.0 await the user's confirmation; no further feature work was started.
