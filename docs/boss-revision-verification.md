# Phase 10 boss movement / attack revision — 2026-10-10

The user confirmed boss-practice operation, found the boss too weak, and requested faster active movement plus arrow projectiles and a naginata fan attack. This revision remains Phase 10; final difficulty and Ver 1.0 confirmation await another user playtest.

Historical tuning report: the next user instruction removes the warnings and adds a post-attack damage window. See `boss-counter-verification.md` and README for current behavior.

## Changes

- Pursuit speed 55 → 125px/s, with path refresh at most 0.18s apart. Between attacks the boss alternates flank routes around the player at 145px/s for 0.4s, then pursues for 0.45s. Terrain collision/navigation remains active. HP stays 240 and ordinary contact damage stays 18.
- Replaced charge and full-circle strike with two attacks. At close range arrows and naginata alternate; at long range the boss repeats arrow volleys rather than waiting indefinitely for melee distance.
- Arrow volley: 0.45s gold-line warning, three arrows at -12 / 0 / +12 degrees, speed260, range600, damage18. Aim locks during the warning. Physical swept collisions stop arrows at terrain or player feet; regular enemies are ignored. Arrows expire by range, freeze with gameplay and respect player invulnerability.
- Naginata: 0.55s warning, forward 140-degree fan, radius84, damage30. Direction locks during the warning. Damage is resolved once when the swing starts; a 0.18s bright fan and moving blade show the swing. Beyond the fan, outside its angle, at the sides or behind the boss are safe. A terrain ray blocks through-wall damage.
- Added an original pixel arrow, bow during the firing preparation, a curved naginata blade and pixel fan/edge/swing graphics. Existing four poses, alternating feet and 45% behind-scenery display remain. No scenery was added.
- Boss appearance, existing swords/growth pause, boss HP UI, victory/death priority, five-round limit and B/button/R practice flow are retained. Round cleanup also removes hostile arrows.

## Files

New: scripts/boss_arrow.gd and Godot UID, scenes/boss_arrow.tscn, this report and boss-revision logs / new Phase 10 attack screenshots.

Updated: scripts/final_boss.gd, scenes/final_boss.tscn, scripts/main.gd, tests/phase_10_verify.gd, tests/boss_practice_verify.gd, README.md and the historical phase-10-verification.md pointer. Notion's Phase 10 section and implementation record carry the user request and current tuning.

## Results

Godot 4.7.2 / Windows / Compatibility renderer / GTX 1050 Ti.

- Updated Phase 10 headless and normal-render integration: PASS, 0 failures, exit0. Normal-render error log empty.
- Boss practice normal-render integration: PASS, 0 failures, exit0; error log empty. Real movement, Space throwing, live arrow attack timers, B switching, R retry and practice button still work.
- Phase 9 shrine/five-round regression: PASS. Import and normal main startup succeeded without script errors. git diff --check passed.
- Viewed phase-10-naginata-warning-preview.png, phase-10-naginata-swing-preview.png and phase-10-arrows-preview.png. The forward fan, curved weapon, swing and three physical arrows are distinguishable.

Updated combat checks cover contact/invulnerability; warned fan hit; behind/side/range/angular rejection and inside-angle hit; changing position behind the locked fan; rock-blocked sweep; actual three-arrow spawn; frozen arrows and no firing during pause; arrow hit on the player without allied damage; volley dodge; river wall blocking all arrows; range expiry; faster pursuit displacement; active lateral flank displacement; bridge navigation; existing occlusion; sword damage; level-up pause/resume; final victory and both same-frame lethal orderings.

## Try it

F8 stops the old build. F5 → click game view → B, or click Boss practice (B). Dodge volleys sideways and move outside/behind the orange fan. Compare pursuit speed, short attack intervals and lateral movement. R retries after victory/defeat; B/button retry at any time. The fixed practice player remains HP100 / Level8 EXP60 / damage30 / interval0.34 / speed120, so the boss is now slightly faster than that preset.

Unconfirmed: the user's revised difficulty, attack readability in crowded regular play, balance against different earned upgrades/remaining HP, and long-session feel. Numeric tuning is provisional. Existing sideways walking polish remains deferred.
