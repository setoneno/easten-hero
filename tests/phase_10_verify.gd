extends SceneTree
var failures := 0
var world: Node2D

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	world = load("res://scenes/main.tscn").instantiate()
	world.enemies_enabled = false
	root.add_child(world)
	current_scene = world
	var player: CharacterBody2D = world.get_node("Player")
	var map: Node2D = world.get_node("ExplorationMap")
	var progression: Node = world.get_node("Progression")
	player.set_physics_process(false)
	player.hp = 70
	var requests := [0]
	world.final_battle_requested.connect(func() -> void: requests[0] += 1)
	# Exercise the complete production shrine/item gate through all five stages.
	for round_index in range(5):
		check(not world.has_node("FinalBoss"), "no boss before Round 5 pickup")
		for shrine in world.get_node("Shrines").get_children():
			player.position = shrine.position + shrine.prayer_point
			await frames(3)
		check(world.get_node("Shrines").visited_count == 3 and world.get_node("Objective").visible, "three prayers unlock this round's magatama")
		check(not world.has_node("FinalBoss"), "third prayer alone does not spawn boss")
		player.position = world.get_node("Objective").position
		await frames(3)
		if round_index < 4:
			check(world.round_cleared and paused, "Rounds 1-4 retain normal clear")
			while progression.pending_choices > 0:
				world._on_upgrade_selected(0)
			world.advance_round()
			await frames(4)
		else:
			check(world.boss_active and not paused and requests[0] == 1, "Round 5 pickup starts one live boss encounter")
	check(not world.game_cleared and not world.game_over and not world.round_cleared, "pickup is not victory or defeat")
	check(player.hp == 70 and progression.level > 1 and player.get_node("SwordThrower").attack_damage > 10, "boss encounter retains health and earned upgrades")
	var boss: CharacterBody2D = world.get_node("FinalBoss")
	boss.set_physics_process(false)
	check(boss.hp == 240 and boss.max_hp > 20 and boss.is_in_group("enemies"), "high-HP boss participates in existing targeting and damage")
	check(map.is_clear(boss.position) and not map.route(player.position, boss.position).is_empty(), "boss spawns at reachable unobstructed location")
	world._on_objective_collected()
	world._finish_game()
	world.advance_round()
	check(requests[0] == 1 and world.round_number == 5 and not world.game_cleared, "duplicate pickup cannot spawn again, clear alive boss or enter Round 6")
	for sample in [Vector2(24, 24), Vector2(960, 568), Vector2(1064, 568), Vector2(1480, 1100), Vector2(480, 440)]:
		player.position = sample
		var spawn: Vector2 = world._boss_spawn_position()
		check(spawn != Vector2.INF and map.is_clear(spawn) and not map.route(sample, spawn).is_empty(), "boss placement works near edges and both riverbanks")
	player.position = Vector2(560, 520)
	boss.position = Vector2(640, 520)
	var thrower: Node2D = player.get_node("SwordThrower")
	await frames(3)
	thrower.cooldown = 0
	thrower.throw_sword()
	await frames(24)
	check(boss.hp == 240, "outside attack window, real sword is guarded")
	check(world.get_node("HUD/BossStatus").visible and world.get_node("HUD/BossStatus/Health").value == boss.hp, "boss health HUD reflects sword damage")
	await screenshot("boss")
	await verify_damage_window(player, boss, thrower)
	await verify_level_up(player, boss, progression, thrower)
	await verify_patterns(player, boss)
	await verify_occlusion(boss, map)
	# Finish using real projectiles, not a direct victory call.
	player.set_physics_process(false)
	player.position = Vector2(560, 520)
	boss.position = Vector2(640, 520)
	boss.set_physics_process(false)
	boss.facing = Vector2.DOWN
	player.invulnerability_left = 0
	for shot in range(24):
		if world.game_cleared or not is_instance_valid(boss):
			break
		boss.attack_direction = Vector2.RIGHT
		boss._fire_arrows()
		clear_arrows()
		thrower.cooldown = 0
		thrower.throw_sword()
		await frames(24)
	check(world.game_cleared and paused and not world.boss_active and not world.game_over, "actual boss defeat yields exclusive GAME CLEAR")
	check(world.get_node("HUD/GameClear").visible and not world.get_node("HUD/GameOver").visible and not world.get_node("HUD/RoundClear").visible, "victory has separate overlay without Next")
	world._finish_game()
	world._on_enemy_defeated(10)
	world.advance_round()
	check(world.round_number == 5 and thrower.throw_sword() == null, "victory freezes attacks, rejects rewards and Round 6")
	await screenshot("clear")
	await restart()
	player = world.get_node("Player")
	check(world.round_number == 1 and player.hp == 100 and world.get_node("Progression").level == 1 and not world.boss_active and not world.game_cleared and not paused, "R from GAME CLEAR resets the entire run")
	check(not world.has_node("FinalBoss") and world.get_node("Shrines").visited_count == 0 and not world.get_node("Objective").visible, "restart removes boss and restores shrine gate")
	# Both same-frame orderings must resolve to GAME OVER only.
	for boss_first in [true, false]:
		if world.has_node("EnemySpawner"):
			world.get_node("EnemySpawner").free()
		world.enemies_enabled = false
		player = world.get_node("Player")
		player.set_physics_process(false)
		world.round_number = 5
		for shrine in world.get_node("Shrines").get_children():
			player.position = shrine.position + shrine.prayer_point
			await frames(3)
		player.position = world.get_node("Objective").position
		await frames(3)
		boss = world.get_node("FinalBoss")
		boss.set_physics_process(false)
		if boss_first:
			boss.vulnerable_left = boss.damage_window
			boss.take_damage(240)
			player.take_damage(100)
		else:
			player.take_damage(100)
			boss.vulnerable_left = boss.damage_window
			boss.take_damage(240)
		await frames(4)
		check(world.game_over and not world.game_cleared and paused, "same-frame lethal player damage wins regardless of ordering")
		check(world.get_node("HUD/GameOver").visible and not world.get_node("HUD/GameClear").visible, "defeat overlay excludes victory")
		world._finish_game()
		check(not world.game_cleared, "deferred boss completion cannot replace GAME OVER")
		if not boss_first:
			check(boss.hp == 240, "GAME OVER stops further boss damage")
		await screenshot("game-over")
		await restart()
	print("PHASE_10_VERIFY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	paused = false
	world.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(0 if failures == 0 else 1)

func verify_damage_window(player: CharacterBody2D, boss: CharacterBody2D, thrower: Node2D) -> void:
	var hp_before: int = boss.hp
	boss.attack_direction = Vector2.RIGHT
	boss._fire_arrows()
	clear_arrows()
	check(boss.vulnerable_left == boss.damage_window and boss.attack_hint().begins_with("OPEN"), "actual volley opens damage acceptance immediately")
	boss.take_damage(10)
	check(boss.hp == hp_before - 10, "damage is accepted inside attack window")
	var original_speed: float = boss.speed
	boss.speed = 0
	boss.state = boss.State.PURSUIT
	boss.state_time = 10
	boss.set_physics_process(true)
	await frames(8)
	var window_left: float = boss.vulnerable_left
	paused = true
	await frames(15)
	boss.take_damage(10)
	check(boss.vulnerable_left == window_left and boss.hp == hp_before - 10, "pause freezes damage window and rejects damage")
	paused = false
	await frames(45)
	check(boss.vulnerable_left == 0 and boss.attack_hint() == "GUARD", "window closes after actual elapsed time")
	boss.take_damage(10)
	check(boss.hp == hp_before - 10, "damage is rejected again after window expires")
	boss.set_physics_process(false)
	boss.speed = original_speed
	hp_before = boss.hp
	thrower.cooldown = 0
	thrower.throw_sword()
	await frames(7)
	boss._fire_arrows()
	clear_arrows()
	await frames(17)
	check(boss.hp == hp_before - thrower.attack_damage, "sword launched while guarded can hit during later open window")
	await screenshot("counter-open")
	hp_before = boss.hp
	thrower.cooldown = 0
	thrower.throw_sword()
	await frames(7)
	boss.vulnerable_left = 0
	await frames(17)
	check(boss.hp == hp_before, "sword launched while open is rejected if impact occurs after closing")
	await screenshot("counter-guard")

func verify_level_up(player: CharacterBody2D, boss: CharacterBody2D, progression: Node, thrower: Node2D) -> void:
	world.enemies_enabled = true
	world._create_spawner()
	var spawner: Node2D = world.get_node("EnemySpawner")
	for enemy in spawner.get_children():
		enemy.set_physics_process(false)
		enemy.position = Vector2(880, 800)
	var target: CharacterBody2D = spawner.get_child(0)
	target.position = Vector2(600, 520)
	progression.exp = progression.required_exp() - 10
	boss.state = boss.State.PURSUIT
	boss.state_time = 1.0
	boss.set_physics_process(true)
	var hp_before: int = boss.hp
	var interval_before: float = thrower.attack_interval
	thrower.cooldown = 0
	thrower.throw_sword()
	await frames(18)
	check(paused and world.boss_active and progression.pending_choices == 1 and world.get_node("HUD/LevelUp").visible, "regular kill during boss fight grants EXP and opens upgrade menu")
	var time_before: float = boss.state_time
	var boss_position: Vector2 = boss.position
	var spawn_elapsed: float = spawner.elapsed
	boss.take_damage(10)
	await frames(20)
	check(boss.hp == hp_before and boss.state_time == time_before and boss.position == boss_position and spawner.elapsed == spawn_elapsed, "upgrade pause freezes boss attacks, damage and spawning")
	await screenshot("level")
	boss.set_physics_process(false)
	key_event(KEY_2, true)
	await frames(2)
	key_event(KEY_2, false)
	check(not paused and world.boss_active and thrower.attack_interval < interval_before, "keyboard upgrade applies and resumes boss fight")
	check(is_instance_valid(spawner) and spawner.is_physics_processing(), "normal spawner remains available during fight")
	spawner.free()
	world.enemies_enabled = false
	player.invulnerability_left = 0

func verify_patterns(player: CharacterBody2D, boss: CharacterBody2D) -> void:
	player.hp = 100
	player.position = boss.position
	player.set_physics_process(true)
	await frames(4)
	check(player.hp == 82 and player.invulnerability_left > 0, "boss contact uses existing HP and invulnerability")
	boss._sweep()
	check(player.hp == 82, "invulnerability rejects naginata damage")
	player.set_physics_process(false)
	player.invulnerability_left = 0
	boss.position = Vector2(640, 520)
	player.position = Vector2(700, 520)
	boss.next_sweep = true
	boss.state = boss.State.PURSUIT
	boss.state_time = 0
	boss.set_physics_process(true)
	await frames(2)
	check(boss.state == boss.State.SWEEP and player.hp == 52, "naginata hits immediately with no warning")
	await screenshot("naginata-immediate")
	check(player.hp == 52 and boss.attacks_started.sweep > 0, "naginata deals 30 damage once in forward fan")
	await screenshot("naginata-swing")
	boss.set_physics_process(false)
	boss.position = Vector2(640, 520)
	boss.attack_direction = Vector2.RIGHT
	player.hp = 100
	for offset in [Vector2(-60, 0), Vector2(0, 60), Vector2(90, 0), Vector2.from_angle(deg_to_rad(75)) * 60]:
		player.position = boss.position + offset
		player.invulnerability_left = 0
		boss._sweep()
		check(player.hp == 100, "behind, side, range and angle outside fan are safe")
	player.position = boss.position + Vector2.from_angle(deg_to_rad(65)) * 60
	boss._sweep()
	check(player.hp == 70, "inside fan near angle boundary is hit")
	player.invulnerability_left = 0
	player.position = Vector2(580, 520)
	boss.attack_direction = Vector2.RIGHT
	boss._sweep()
	check(player.hp == 70, "behind immediate forward sweep stays safe")
	boss.position = Vector2(557, 384)
	player.position = Vector2(595, 384)
	boss.attack_direction = Vector2.RIGHT
	player.invulnerability_left = 0
	boss._sweep()
	check(player.hp == 70, "rock blocks naginata sweep")
	boss.position = Vector2(640, 520)
	player.position = Vector2(800, 520)
	boss.next_sweep = false
	boss.state = boss.State.PURSUIT
	boss.state_time = 0
	boss.set_physics_process(true)
	await frames(2)
	check(boss.state == boss.State.ARROWS and get_nodes_in_group("boss_projectiles").size() == 3, "arrows release immediately with no warning")
	boss.set_physics_process(false)
	await screenshot("arrows-immediate")
	check(get_nodes_in_group("boss_projectiles").size() == 3, "arrow volley releases three physical projectiles")
	var arrow: CharacterBody2D = get_nodes_in_group("boss_projectiles")[1]
	var arrow_position := arrow.position
	paused = true
	boss._fire_arrows()
	await frames(10)
	check(arrow.position == arrow_position and get_nodes_in_group("boss_projectiles").size() == 3, "pause freezes flying arrows and rejects extra volleys")
	paused = false
	await frames(12)
	await screenshot("arrows")
	var ally: CharacterBody2D = load("res://scenes/enemy.tscn").instantiate()
	ally.position = Vector2(752, 520)
	world.add_child(ally)
	ally.set_physics_process(false)
	await frames(30)
	check(player.hp == 52 and ally.hp == 20, "real arrow hits player for 18 and passes allied enemy without damage")
	ally.free()
	clear_arrows()
	player.invulnerability_left = 0
	boss.attack_direction = Vector2.RIGHT
	boss._fire_arrows()
	player.position = Vector2(800, 620)
	await frames(40)
	check(player.hp == 52, "sidestepping locked arrow volley avoids damage")
	clear_arrows()
	boss.position = Vector2(936, 400)
	player.position = Vector2(1120, 400)
	boss._fire_arrows()
	await frames(25)
	check(get_nodes_in_group("boss_projectiles").is_empty() and player.hp == 52, "river wall stops all arrows")
	boss.position = Vector2(640, 520)
	player.position = Vector2(560, 800)
	boss.attack_direction = Vector2.LEFT
	boss._fire_arrows()
	for projectile in get_nodes_in_group("boss_projectiles"):
		projectile.max_range = 40
	await frames(20)
	check(get_nodes_in_group("boss_projectiles").is_empty(), "arrows expire at range limit")
	player.position = Vector2(800, 520)
	boss.position = Vector2(640, 520)
	boss.state = boss.State.PURSUIT
	boss.state_time = 10
	boss.repath_time = 0
	boss.set_physics_process(true)
	await frames(20)
	check(boss.speed == 125 and boss.position.distance_to(Vector2(640, 520)) > 35, "boss pursues at substantially faster speed")
	boss.set_physics_process(false)
	boss.position = Vector2(640, 520)
	boss._recover()
	boss.set_physics_process(true)
	await frames(15)
	check(absf(boss.position.y - 520) > 5 and boss.position.distance_to(Vector2(640, 520)) > 20, "recovery actively flanks instead of standing still")
	boss.position = Vector2(936, 400)
	player.position = Vector2(1120, 400)
	boss.state = boss.State.PURSUIT
	boss.state_time = 10
	boss.repath_time = 0
	await frames(30)
	check(boss.position.y > 410 and boss.position.x < 992, "faster boss still uses bridge route across river")
	boss.set_physics_process(false)

func clear_arrows() -> void:
	for arrow in get_nodes_in_group("boss_projectiles"):
		arrow.free()

func verify_occlusion(boss: CharacterBody2D, map: Node2D) -> void:
	boss.position = map.trees[0] + Vector2(0, -18)
	await frames(12)
	check(is_equal_approx(boss.modulate.a, 0.45), "boss fades behind foliage")
	boss.position = map.trees[0] + Vector2(-24, 20) # In front of this tree, clear of the adjacent canopy.
	await frames(12)
	check(is_equal_approx(boss.modulate.a, 1), "boss in front stays opaque")
	boss.position = map.shrine_position + Vector2(48, -20)
	await frames(12)
	check(is_equal_approx(boss.modulate.a, 0.45), "larger boss also fades behind shrine roof")
	boss.position = Vector2(640, 520)
	await frames(12)
	check(is_equal_approx(boss.modulate.a, 1), "boss leaving scenery restores opacity")
	for direction in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]:
		boss.facing = direction
		boss.walk_time = 0.15
		boss.queue_redraw()
		await frames(2)
		check(boss.occlusion_bounds().size.y > 26, "boss uses full-height scenery bounds for every pose")

func restart() -> void:
	key_event(KEY_R, true)
	await frames(8)
	key_event(KEY_R, false)
	world = current_scene

func screenshot(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-10-%s-preview.png" % label)

func key_event(key: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func frames(count: int) -> void:
	for index in range(count):
		if not paused:
			await physics_frame
		await process_frame

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
