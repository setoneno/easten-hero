# Game 002 Prototype

Godot 4 / GDScript prototype for a top-down action game set in an ancient Japan-inspired world.

The player explores ancient Japan-inspired maps, throws swords, gains EXP and chooses upgrades. Each of five rounds requires visiting three shrines to release the jade magatama. Round 5 pickup summons the Bronze Guardian; defeating it completes the game.

## Core Concept

- Top-down 2D action
- Ancient Japan-inspired world
- Freely explore relatively large maps
- Throw swords as the primary attack
- Gain EXP by defeating enemies
- Gain bonus EXP when completing a round
- Pause and select an upgrade immediately when reaching the required EXP
- Find the objective item to complete the current round
- Change maps between rounds
- Pixel-art visuals inspired by the density of late Super Famicom-era RPG field graphics

## Development

- Engine: Godot 4
- Language: GDScript
- IDE: VSCode
- Implementation support: Codex
- Source control: GitHub
- Authoritative game specification: Notion

## Run

Phases 1–10 and same-round continuation are user-confirmed, reaching the Ver 1.0 completion line. The release-polish revision (title/menu flow, pause and debug hiding) is also user-confirmed on 2026-10-10. Exported executable testing and distribution remain separate work.

1. Import `project.godot` in Godot 4 (verified with the installed **4.7.2**).
2. Press **F5** to start `scenes/title.tscn`. Choose **NEW GAME** for Round 1, **CONTINUE** for the last saved round entry, or **EXIT**. CONTINUE is disabled when no valid checkpoint exists. Buttons support mouse, keyboard focus and Enter.
3. Click the game view if keyboard focus is elsewhere. Move with **WASD or arrow keys**; diagonal movement has the same 100px/s speed as straight movement.
4. Follow the dirt path south, then east across the wooden bridge. Head north on the far bank to find the wooden gateway and thatched shrine.
5. Rust-clad foot soldiers appear around you and pursue you. Keep moving to escape; your speed is 100px/s and their speed is 65px/s. Enemies also route across the bridge when you move to the far bank.
6. Press or hold **Space / left mouse button** to throw swords. **Tab** switches **AUTO** (nearest visible enemy; facing direction if none) and **MOUSE** (cursor direction). The HUD shows the current mode and defeat count.
7. Each soldier starts with 20 HP. Swords deal 10 damage, so two hits defeat one. Moving targets can evade a sword; shots fly straight.
8. The HUD shows **HP 100 / 100**. Touching an enemy deals **10 damage**, then grants **1 second of invulnerability**. Hit feedback uses color changes; the scenery opacity remains separate.
9. At zero HP, **GAME OVER** freezes gameplay and waits for **CONTINUE (R)**. Click the button or press **R** to retry the same round from its entry checkpoint. Entry HP (not necessarily full), Level, EXP, ability levels, combat values, aim mode and kills are restored; growth earned during the failed round is lost. Shrines reset to 0/3 and the jade is hidden. Round 5 retries start before shrines and boss, even if you died during the boss fight. R does not restart a running game.
10. Defeat enemies to gain **10 EXP each**. The HUD shows Level and EXP; the first level needs **30 EXP** (three kills), then the requirement increases by 10 per level.
11. On level-up, gameplay pauses immediately. **Click one of the three buttons or press 1 / 2 / 3**: POWER adds 5 damage, QUICK THROW reduces attack interval by 15%, SWIFT FEET adds 10px/s movement speed. Choices display current and new ability levels and values. Each ability starts at **Lv1**, rising once per acquisition; the header always shows all three levels. The same upgrade can be chosen repeatedly. Ability levels carry between rounds and reset when restarting.
12. Overflow EXP carries forward. If one award earns multiple levels, choose once for each level before gameplay resumes. A fresh run resets Level, EXP and all upgrades; GAME OVER continuation restores the round-entry checkpoint instead.
13. Visit **three shrines** each round. One is the existing large shrine; two are small wayside shrines near the southwest and southern parts of the field. Approach the gold entrance marker to pray automatically (18px radius); a green check marks each visited shrine. HUD **Shrines 0/3 → 3/3** counts distinct visits. Repeating a visit gives no extra count.
    The jade magatama starts hidden and inactive. After the third visit it appears at a random reachable location, away from scenery cover. Walk onto it to collect it.
14. In **Rounds 1–4**, pickup clears the round and grants **120 bonus EXP** into the same gauge. Complete every earned upgrade choice; then **ROUND CLEAR** appears and gameplay stays stopped. **N** or the **Next round** button advances after all choices are complete. **R** returns to TITLE, retaining the entry checkpoint. Choose NEW GAME explicitly to reset progress.
15. Round 1 is **Riverside**; Round 2 is **Shrine Forest**, with darker grass, 48 trees, new paths, rocks and shrine positions. The two existing layouts alternate over exactly **five rounds** (Riverside / Forest / Riverside / Forest / Riverside). Five distinct map layouts are not required by Phase 9. HUD shows ROUND n / 5 and map name.
16. Level, remaining EXP, upgrades, remaining HP, aim mode and defeat count carry into the next round. No automatic healing or difficulty increase is applied. Old enemies and swords are removed; each round starts with four new enemies and three unvisited shrines and a locked magatama. Spawning resumes normally.
17. **M** toggles sound, including during upgrade/clear/GAME OVER menus. The HUD shows SFX ON/OFF. Eight original short tones cover throwing, enemy hits, player hits, defeat, level-up, selection, clear and GAME OVER. No BGM is included.
18. HP uses a green bar; EXP uses a gold bar. The compact HUD shows round/map, HP, Level/EXP, objective and controls. Player damage adds a short warm flash; enemy hits/defeat show temporary labels, and EXP gains/upgrades show brief notices.
19. In **Round 5**, magatama pickup summons the **Bronze Guardian**, a larger bronze-armored warrior with **240 HP**. The fight starts immediately on the current map; your HP, EXP, upgrades and aim mode remain. Regular enemies and spawning continue, so kills still grant EXP and level-up choices pause the whole fight. Boss HP appears in the header; internal attack hints are hidden in normal play.
20. The boss pursues at **125px/s**, updates its route frequently and moves sideways at **145px/s** between attacks. Attacks have **no warning display or windup delay**: **three arrows** fan out at ±12 degrees, flying at **260px/s** up to **600px** and dealing **18 damage**, or a **140-degree / 84px** forward naginata fan deals **30 damage** immediately. The fan/blade shown for 0.18 seconds is the actual swing. Far away it repeats volleys; nearby it alternates arrows and sweeps. Recovery is **0.4 seconds** with flanking movement, followed by **0.45 seconds** of pursuit. Ordinary contact remains **18 damage**. Existing invulnerability applies; arrows collide with scenery and the player, and walls block the sweep.
    The boss accepts damage only for **0.6 seconds starting at actual arrow release or naginata swing**. Acceptance is checked at impact, not when you throw. The window freezes during upgrade selection and pause. Normal play retains the color cue, but hides OPEN/GUARD, the remaining timer and GUARD debug popups. Development mode can show those hints. Tune **Damage Window** on the FinalBoss root in `scenes/final_boss.tscn`.
21. Defeat the boss with swords to see **GAME CLEAR**, which waits for **NEW GAME / TITLE / EXIT**. NEW GAME (also R) starts fresh Round 1; TITLE keeps the checkpoint. GAME OVER offers **CONTINUE / TITLE / EXIT**. There is no Next button or Round 6. If the player also suffers lethal damage in the boss-defeat frame, GAME OVER takes priority.
22. During play, **Esc / PAUSE** opens **RESUME / TITLE / EXIT**. Resume or Esc continues at the same position. Title ends this attempt and preserves its round-entry save. Pause freezes player/enemies/boss/projectiles, spawning, damage and timers; Esc cannot bypass upgrade choices or result screens.
23. Press F8 in the editor to stop, or choose EXIT in any full-screen menu.

The 1536×1152 field contains grass, paths, trees, rocks, a river, bridge and shrine. The original pixel character wears a cream tunic with an indigo sash. Feet collide with tree trunks, rocks, the shrine, river and map boundary. The camera follows within map limits. Phase 2 starts with four enemies, adds one every 3 seconds, and caps the regular enemy count at 24. Enemies farther than 700px retire to allow continued spawning near your new location. Enemies have HP and take sword damage. Enemy contact damages the player without physically trapping them. Defeat stops player movement, attacks, existing swords, enemy pursuit and spawning. Enemy defeat grants EXP and level-up selection is available. Three shrine prayers release the magatama. It ends Rounds 1–4; Round 5 summons one persistent boss in addition to regular enemies. The five rounds reuse Riverside and Shrine Forest, with growth carried forward.

The map's effective display starts below the opaque header: y=100 normally and y=140 during a boss fight (640×360 logical screen). The player is centered in that remaining area. Camera limits compensate its vertical offset so the top map edge meets the header bottom, the bottom edge meets the screen bottom, and side edges do not show empty space. Boss HP and OPEN/GUARD now belong to the header too.

## Release-flow verification

F8 → F5 must show TITLE before any actors start. Try NEW GAME, Esc / PAUSE → RESUME / TITLE, GAME OVER → CONTINUE / TITLE, and GAME CLEAR → NEW GAME / TITLE. Check each menu's EXIT. Upgrade/result screens must ignore Esc as a resume shortcut. After reaching a later round, exit and relaunch, then CONTINUE: it must restore that round's entry stats and 0/3 shrines. Normal startup must hide practice/debug hints and ignore B.

Run `& $godotExe --path . --script res://tests/release_flow_verify.gd` (or `--headless`). Expected `RELEASE_FLOW_VERIFY: PASS (0 failures)`. EXIT and separate-process disk-save tests are documented in `docs/release-verification.md`; automated tests use separate save filenames and never overwrite the player save.

## Continue verification

In a later round, note entry HP, Level, EXP and ability levels; earn more EXP/upgrades and visit shrines, then die. R or CONTINUE must retry that same map with entry stats and unvisited shrines. Repeat to confirm the checkpoint is not replaced by death-time values. In Round 5, die after summoning the boss and confirm the retry starts with 0/3, no jade or boss; revisit all shrines to summon it again. GAME CLEAR → R still starts a fresh Round 1. Boss-only practice retains its independent R retry preset.

Round entries are saved automatically to `user://checkpoint.json` and survive application closure. NEW GAME replaces the save with a fresh Round 1 checkpoint. TITLE / EXIT preserve it, including after GAME CLEAR. Corrupt or unsupported save files disable title CONTINUE. Atomic temporary-file replacement avoids partially overwriting the previous save. Isolated gameplay test scenes do not write the player's save.

Automated: `& $godotExe --path . --script res://tests/continue_verify.gd` (or add `--headless`). Expected `CONTINUE_VERIFY: PASS (0 failures)`. See `docs/continue-verification.md`.

## UI/display revision verification

Run F5 → NEW GAME and check POWER / QUICK THROW / SWIFT FEET Lv1 in the header. Gain EXP, select the same ability twice and check Lv2 then Lv3, including current/next levels in the choice buttons. Other ability levels stay unchanged. Check carryover after Next round and reset after NEW GAME.

Walk toward all four map edges in Riverside and Shrine Forest; check that the map begins directly below the header, with no empty strip. Use B for the boss layout and verify the taller header and following camera. Practice starts ability levels at Lv1: its adjustable fixed combat values do not represent earned upgrade selections.

Automated check: `& $godotExe --path . --script res://tests/ui_display_verify.gd` (add `--headless` for logic-only checks). Expected: `UI_DISPLAY_VERIFY: PASS (0 failures)`. Details and screenshots: `docs/ui-display-verification.md`.

## Boss-only practice

Normal F5 play hides Boss practice and ignores B. For development, enable **Debug Tools Enabled** on Main's root in `scenes/main.tscn`, then F5 → NEW GAME. B / Boss practice opens the test scene; development hints show OPEN/GUARD. This flag is additionally gated by `OS.is_debug_build()`, so release builds always hide/disable these tools. Practice does not replace the normal saved checkpoint. F9 remains Godot's embedded pause, not a practice shortcut.

Alternatively, double-click `scenes/boss_test.tscn`, select its tab and press **F6**. It explicitly enables development tools and starts Round 5 practice with no shrine visits or earlier rounds. F5 always starts TITLE.

The practice preset is HP100, Level8 / EXP60, damage30, interval0.34s and speed120px/s. It is a fixed test preset, not a replay of your earned upgrades. Regular enemies are disabled to focus on the boss. Enable **Enemies Enabled** on the BossTest root to also test regular kills and level-up during the fight. **Test Damage / Test Interval / Test Speed** can be adjusted in the Inspector. After GAME CLEAR or GAME OVER, **R** retries this boss-only scene. F8 stops it.

CLI alternative: `& $godotExe --path . res://scenes/boss_test.tscn`.

`tests/boss_practice_verify.gd` checks normal start → B practice, actual player movement/sword input, boss movement/attack timers, Round 5 HUD, victory → R retry, defeat → B retry and the screen button. Expected: `BOSS_PRACTICE_VERIFY: PASS (0 failures)`.

## Structure

- `scenes/title.tscn`, `scripts/title.gd`: application entry and NEW GAME / CONTINUE / EXIT.
- `scripts/game_session.gd`: scene transitions and versioned, validated persistent round-entry saves.
- `scripts/menu_layout.gd`: shared menu layout and button styles.
- `tests/release_flow_verify.gd`, `tests/menu_exit_verify.gd`, `tests/checkpoint_disk_verify.gd`, `docs/release-verification.md`: menu/pause/debug, actual exit and cross-process save verification.

- `project.godot`: main scene, display, renderer and WASD/arrow Input Map.
- `scenes/main.tscn`, `scripts/main.gd`: world, player and controls HUD.
- `scenes/player.tscn`, `scripts/player.gd`: normalized movement, feet collision, camera and pixel walking figure.
- `scripts/exploration_map.gd`: two fixed layouts, original pixel scenery, collision/navigation and occlusion rebuilds.
- `scenes/enemy.tscn`, `scripts/enemy.gd`: original foot soldier pixels and obstacle-aware pursuit.
- `scenes/final_boss.tscn`, `scripts/final_boss.gd`: agile bronze guardian, immediate arrows/naginata fan, post-attack damage window, collision and larger occlusion bounds.
- `scenes/boss_arrow.tscn`, `scripts/boss_arrow.gd`: swept hostile arrows, terrain/player collision and bounded lifetime.
- `docs/boss-revision-verification.md`: movement/attack revision and verification results.
- `docs/boss-counter-verification.md`: warning removal and post-attack damage acceptance checks.
- `scenes/boss_test.tscn`, `scripts/boss_test.gd`: F6 boss-only practice and adjustable test combat preset.
- `tests/phase_10_verify.gd`, `docs/phase-10-verification.md`: five-stage gate, boss combat, growth pause, victory/defeat and restart checks.
- `scripts/enemy_spawner.gd`: valid spawn positions, continuous spawning, cap and retirement.
- `scripts/sword_thrower.gd`: attack settings, cooldown, auto/mouse aim and input.
- `scenes/thrown_sword.tscn`, `scripts/thrown_sword.gd`: swept projectile collision, damage and range lifetime.
- `tests/phase_3_verify.gd`: combat integration checks.
- `scripts/game_over_ui.gd`: restart input during GAME OVER/ROUND CLEAR and next-round button/N input.
- `tests/phase_4_verify.gd`: contact/invulnerability, HUD, freeze and restart integration checks.
- `docs/phase-4-verification.md`: Phase 4 decisions and results; user playtest confirmed.
- `scripts/objective_item.gd`: locked/released pixel magatama and deferred pickup.
- `scripts/prayer_shrine.gd`, `scripts/shrine_trials.gd`: prayer markers, distinct visits, collision/occlusion and validated placement.
- `tests/phase_9_verify.gd`, `docs/phase-9-verification.md`: shrine gating, all five rounds and boss handoff checks.
- `tests/phase_6_verify.gd`, `docs/phase-6-verification.md`: placement, bonus, clear and defeat-priority integration checks.
- `tests/phase_7_verify.gd`, `docs/phase-7-verification.md`: consecutive rounds through Round 5, carryover, cleanup and forest checks (the historical Phase 7 report retains its original seven-round results).
- `docs/phase-7-forest-preview.png`, `docs/phase-7-clear-preview.png`: forest and next-round screen.
- `docs/phase-6-item-preview.png`, `docs/phase-6-clear-preview.png`: rendered item and final clear screen.
- `scripts/game_feedback.gd`: generated PCM tones, mute control, bounded popups, hit flash and notices.
- `tests/phase_8_verify.gd`, `docs/phase-8-verification.md`: full loop and presentation/audio checks.
- `docs/phase-8-*-preview.png`: combat, upgrade, clear and GAME OVER captures.
- `scripts/level_progression.gd`: EXP thresholds, overflow and queued selections.
- `scripts/level_up_ui.gd`: three buttons and keyboard input during pause.
- `tests/phase_5_verify.gd`, `docs/phase-5-verification.md`: growth integration checks and results.
- `docs/phase-5-upgrade-preview.png`, `docs/phase-5-exp-preview.png`: rendered selection and EXP HUD.
- `docs/phase-3-verification.md`, `docs/phase-3-preview.png`: Phase 3 evidence and deferred issues.
- `tests/phase_1_verify.gd`: exploration regression checks with spawning disabled.
- `tests/phase_2_verify.gd`: spawning, obstacle routing, bridge pursuit and escape checks.
- `docs/phase-2-verification.md`, `docs/phase-2-preview.png`: Phase 2 evidence.
- `docs/phase-1-plan.md`: scope and acceptance criteria.
- `docs/phase-1-verification.md`: verification results and remaining manual checks.
- `docs/phase-1-preview.png`, `docs/phase-1-shrine-preview.png`: captured game views.

## Verify

Run from this directory in PowerShell (replace the executable path if needed):

```powershell
$godotExe = 'C:\Users\keisuke\AppData\Local\Programs\Godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --version
& $godotExe --headless --path . --import
& $godotExe --headless --path . --script res://tests/phase_1_verify.gd
& $godotExe --headless --path . --script res://tests/phase_2_verify.gd
& $godotExe --headless --path . --script res://tests/phase_3_verify.gd
& $godotExe --headless --path . --script res://tests/phase_4_verify.gd
& $godotExe --headless --path . --script res://tests/phase_5_verify.gd
& $godotExe --headless --path . --script res://tests/phase_6_verify.gd
& $godotExe --headless --path . --script res://tests/phase_7_verify.gd
& $godotExe --headless --path . --script res://tests/phase_8_verify.gd
& $godotExe --headless --path . --script res://tests/phase_9_verify.gd
& $godotExe --headless --path . --script res://tests/phase_10_verify.gd
& $godotExe --headless --path . --script res://tests/boss_practice_verify.gd
& $godotExe --path . --quit-after 120
```

Expected integration results: `PHASE_1_VERIFY: PASS (0 failures)` , `PHASE_2_VERIFY: PASS (0 failures)` , `PHASE_3_FINAL: PASS (0 failures)` , `PHASE_4_VERIFY: PASS (0 failures)` , `PHASE_5_VERIFY: PASS (0 failures)` , `PHASE_6_VERIFY: PASS (0 failures)` , `PHASE_7_VERIFY: PASS (0 failures)` , `PHASE_8_VERIFY: PASS (0 failures)`, `PHASE_9_VERIFY: PASS (0 failures)` and `PHASE_10_VERIFY: PASS (0 failures)`, exit code 0, no `ERROR` or `SCRIPT ERROR`. The final command runs the F5 main scene with normal rendering for 120 frames. To refresh game-view PNGs, run the integration script without `--headless`. Options follow the [official Godot CLI documentation](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).

Manual F5 checklist:

- Map and character appear immediately, with clear pixel shapes.
- WASD and arrows each move in the intended direction; two keys give diagonal movement without extra speed.
- The rock immediately east of the spawn and the tree trunks block movement.
- River crossing is possible on the bridge, and the shrine blocks movement.
- All four map edges stop the player; the camera follows without exposing space outside the field.
- Several foot soldiers appear, continue arriving, and approach you while respecting the map.
- Lure enemies around rocks, trees and across the bridge. Running away remains possible.
- Walk behind tree foliage, gateway beams or the shrine roof: player and enemy opacity fades to 45%, then returns smoothly outside. Characters in front of scenery keep full opacity.
- Check front/back/left/right poses while moving. Both feet alternate during walking and return to a standing pose when stopped.
- Sideways walking uses side-view legs and toes: legs swing horizontally, with a darker far leg. Left-facing movement mirrors the entire gait.
- Space and left click throw visible swords; holding repeats and releasing stops.
- Tab switches AUTO/MOUSE. Compare both while moving and aiming around obstacles.
- First sword hit flashes an enemy and shows its reduced HP bar. The second hit defeats it and increments the HUD count.
- Swords stop at rocks, trees, river and buildings, and disappear at their range limit.
- Touch an enemy: HP drops by 10, then INVULNERABLE appears for 1 second. Multiple contacts cannot stack damage during this protection.
- At HP0, GAME OVER appears. Movement, throwing, flying swords, enemies and spawn timers stay frozen.
- Press R or CONTINUE: entry HP and defeat count are restored, enemies/projectiles are rebuilt, and movement/throwing work again.
- Three enemy kills open a level-up menu immediately. Level and EXP gauge update correctly.
- While choosing, movement, enemies, flying swords, attacks, spawning and invulnerability timers remain frozen.
- Test both clicking and 1 / 2 / 3. Compare damage, throwing interval and movement speed before/after choosing; repeat an upgrade at later levels.
- R during level-up does not bypass choices. R after GAME OVER restores entry EXP, Level and upgrades.
- Visit all three shrine entrances; count progresses 0/3 to 3/3. No magatama appears before the third distinct visit. Repeat visits do not add counts.
- Small shrine walls stop movement; walking behind the roof fades the character to 45% and leaving restores visibility.
- In Rounds 1–4, find the released magatama and confirm +120 EXP, required upgrade choices, then ROUND CLEAR. Gameplay stays frozen after the last choice.
- Verify each next round resets visits to 0/3 and hides the magatama. In Round 5, pickup summons exactly one boss and continues gameplay; pickup alone never produces GAME CLEAR.
- N and R cannot skip bonus upgrade choices. On a Round 1–4 clear screen, N or Next round advances; R returns to TITLE and retains the checkpoint.
- In the boss fight, check fast pursuit/flanking, four directional poses, both feet walking and behind-scenery opacity. Arrows and naginata fire without warnings; stay outside/behind the forward fan and dodge physical arrows. Check wall collisions, fan direction/range, damage and invulnerability.
- In normal play, confirm boss HP appears without OPEN/GUARD/timers and B does nothing. In explicitly enabled development practice, throw during GUARD and confirm no HP loss; after attack, OPEN lasts 0.6 seconds and arriving hits reduce HP. Late impacts are guarded again.
- Defeat a regular enemy during the boss fight to reach a level threshold; the boss, damage-window timer, swords and spawning freeze during selection and resume afterward.
- Defeat the boss: GAME CLEAR appears and all gameplay freezes. No Next or Round 6 is available; R resets the entire run. If defeated during the fight, GAME OVER appears instead and R retries Round 5 from its entry checkpoint, before shrine visits and boss appearance.
- Complete at least three rounds. Check changing maps, round number, retained HP/Level/EXP/upgrades, fresh enemies and new magatama.
- In the forest, test tree/rock/shrine collision and behind-tree/roof/gate opacity. Check that pursuit and repeated spawning resume.
- GAME OVER on a later round blocks progression; R retries the same round with entry HP and abilities.
- Check HP/EXP colors, controls and round/map labels at the default window size and after resizing. Distinguish cream-clad player, rust-clad enemies, silver swords and jade magatama.
- Listen for throw/hit/defeat, player damage, level-up/selection, clear and GAME OVER tones. M toggles mute during play and pause; unmute and confirm sound returns.
- Damage flash, floating enemy labels and brief notices appear, then disappear. Popup effects clear when switching maps.
- Complete exploration → combat/EXP → upgrade → objective/bonus → next map for at least three rounds, then GAME OVER → R.
- Output and Debugger show no errors during exploration, combat, level-up, objective pickup, ROUND CLEAR, GAME OVER and restart.

Phases 1–8 and Ver 0.1 are confirmed by the user on 2026-10-02; Phase 9 is confirmed on 2026-10-10. Phase 10 and Ver 1.0 await user confirmation. AUTO remains the initial aim setting with MOUSE selectable. Sideways walking still looks awkward and is explicitly deferred for later adjustment. Prior-phase test fixtures disable shrine gating/objective pickup where needed to retain their original checks; Phase 7 respects the five-round limit. Phase 9's historical handoff test disables boss combat, while Phase 10 tests the default production boss path. Run input tests one at a time; headless mode avoids interference from live keyboard input.

Tune `Projectile Speed` (320px/s), `Attack Interval` (0.4s), `Attack Range` (400px), and `Attack Damage` (10) on Player > SwordThrower in `scenes/player.tscn`; tune enemy `Max Hp` (20) in `scenes/enemy.tscn`. These are provisional playtest values.

## Development Policy

Implement and verify one phase at a time.

Update this README with the current run and verification steps whenever a phase is completed.

The authoritative game specification is maintained in [Notion](https://app.notion.com/p/3ec32305966281aab50fe218f60b533b).

Phase 4 tuning: Player `Max Hp` = 100 and `Invulnerability Duration` = 1.0s; Enemy `Contact Damage` = 10. Hurtbox radius is 16px. These are provisional values.

Phase 6 tuning: Main "Round Bonus Exp" = 120. Pickup radius is 18px; objective placement distance from the start is at least 240px. These are provisional values. Same-frame lethal damage takes priority over objective pickup; GAME OVER grants no clear bonus.
