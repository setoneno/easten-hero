# Ver 1.0 additional revision — UI / display (2026-10-10)

Implemented the two additions in the authoritative Notion section. Phase 10 remains user-confirmed; this revision awaits user playtest.

## Changes

- Progression owns three ability levels, each initialized to Lv1. Selecting POWER, QUICK THROW or SWIFT FEET increments only that ability. Repeated choices increment again, round changes preserve levels, and restart creates fresh Lv1 values. Existing effects remain +5 damage, interval ×0.85 and +10px/s.
- Added an always-visible ability row, plus current-to-next Lv in choice buttons alongside existing effect values. The fixed boss-practice stat preset has no earned selections and starts ability levels at Lv1.
- The opaque header ends at y100 normally, y140 with boss status, in the 640×360 logical screen. Boss HP and hints now occupy the header. The practice button moved into the ability row to avoid covering the character at the lower-right edge.
- Camera offset is -header_height/2, centering the player below the header. Godot applies offset after limit clamping, so top limit is -header_height/2 and bottom limit is 1152+header_height/2. This aligns map top with header bottom and map bottom with screen bottom. Horizontal limits remain 0..1536. No map layout, movement/combat values, upgrade effects or game loop changes.

## Files

Updated scripts/level_progression.gd, scripts/main.gd, scenes/main.tscn, tests/phase_1_verify.gd and README.md. Added tests/ui_display_verify.gd, this report and ui-display / ui-regression logs and PNG evidence.

## Results

Godot 4.7.2 / Windows / Compatibility renderer.

- New UI/display integration: headless and normal renderer PASS, zero failures, exit0, stderr empty.
- Headless Phase 1, 5, 7, 10 and boss-practice regression: all PASS, zero failures, stderr empty. These cover movement/collision, real keyboard and mouse choice behavior, growth/pause, carryover, boss combat and practice/restart.
- Normal-render boss-practice regression after button relocation: PASS, zero failures, stderr empty.
- Checked actual canvas transforms at center and all four corners of Riverside, Forest and boss layouts. The effective map rectangle stays within map bounds, upper edges align with the header and lower edges with the screen, and the player is centered within the remaining area away from edge clamps.
- Checked initial/repeated/independent ability levels, actual unchanged effect values, selection labels, carryover and restart reset.
- Viewed ability HUD, three-choice menu, boss upper edge and Riverside lower edge PNGs. Text is readable, the map has no empty strips, and relocating practice removes its lower-edge overlap.
- Initial test iteration exposed offset being applied after limits; both limits were corrected and final runs pass. The test fixture's hard-coded old interval was replaced with the actual baseline. Final logs replace failed development runs.

## Manual verification pending

F8 → F5. Check Lv1 ability row, then acquire the same ability twice (Lv2 → Lv3). Confirm current/next levels on the choices and unchanged effect values. Advance to Forest and check retained ability levels; restart from a result screen and check Lv1 reset. Walk to top/bottom/left/right map edges, then use B or the header button to check the taller boss header and camera. User-perceived field of view and readability, especially with the taller boss header, await confirmation. No further feature work started.
