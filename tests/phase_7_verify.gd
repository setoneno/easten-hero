extends SceneTree
var failures := 0
var world: Node2D

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	world = load("res://scenes/main.tscn").instantiate()
	world.shrines_enabled = false
	root.add_child(world)
	current_scene = world
	var player: CharacterBody2D = world.get_node("Player")
	player.set_physics_process(false)
	var progression: Node = world.get_node("Progression")
	var map: Node2D = world.get_node("ExplorationMap")
	player.hp = 70
	progression.add_exp(10)
	check(world.round_number == 1 and not map.forest, "round 1 starts on Riverside")
	world.advance_round()
	await frames(2)
	check(world.round_number == 1, "cannot advance an uncleared round")
	for cycle in range(4):
		var old_spawner: Node2D = world.get_node("EnemySpawner")
		# Forest inspection can legitimately retire all distant enemies.
		var old_enemy: Node = old_spawner.spawn_enemy() if old_spawner.get_child_count() == 0 else old_spawner.get_child(0)
		var sword: CharacterBody2D = load("res://scenes/thrown_sword.tscn").instantiate()
		sword.position = Vector2(800, 960)
		world.add_child(sword)
		var item: Node2D = world.get_node("Objective")
		item.position = player.position
		item.try_collect()
		check(paused and world.round_cleared, "pickup freezes the current round")
		var before_round: int = world.round_number
		world.advance_round()
		check(world.round_number == before_round and not world.transitioning, "bonus choices block advance")
		while progression.pending_choices > 0:
			key_event(KEY_1 + (progression.pending_choices % 3), true)
			await frames(2)
			key_event(KEY_1 + ((progression.pending_choices + 1) % 3), false)
		check(world.get_node("HUD/RoundClear").visible and paused, "clear screen waits for next command")
		var saved_level: int = progression.level
		var saved_exp: int = progression.exp
		var thrower: Node2D = player.get_node("SwordThrower")
		var saved_damage: int = thrower.attack_damage
		var saved_interval: float = thrower.attack_interval
		var saved_speed: float = player.move_speed
		if cycle == 0 and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/phase-7-clear-preview.png")
		if cycle % 2 == 0:
			key_event(KEY_N, true)
			key_event(KEY_N, true)
			await frames(4)
			key_event(KEY_N, false)
		else:
			mouse_click(Vector2(320, 300))
			await frames(4)
		check(world.round_number == before_round + 1 and not paused and not world.round_cleared, "N or actual GUI button advances exactly one round")
		check(map.forest == (world.round_number % 2 == 0), "consecutive maps alternate")
		check(progression.level == saved_level and progression.exp == saved_exp and progression.pending_choices == 0, "Level and overflow EXP preserved")
		check(thrower.attack_damage == saved_damage and thrower.attack_interval == saved_interval and player.move_speed == saved_speed and player.hp == 70, "all acquired abilities and remaining HP preserved")
		check(not is_instance_valid(old_spawner) and not is_instance_valid(old_enemy) and not is_instance_valid(sword), "old enemies, spawner and projectiles removed")
		check(world.get_node("EnemySpawner").get_child_count() == 4, "new map starts with four fresh enemies")
		check(map.is_clear(player.position) and player.position == map.start_position, "player starts on safe new map position")
		check(item.visible and not item.collected_once and map.is_clear(item.position) and not map.route(player.position, item.position).is_empty(), "new objective is visible, uncollected and reachable")
		check(world.get_node("HUD/Round").text.contains(str(world.round_number)) and world.get_node("HUD/Round").text.contains(map.map_title), "HUD shows current round and map")
		check(map.get_child_count() == map.obstacle_rects.size(), "wall bodies do not accumulate across transitions")
		if cycle == 0:
			await verify_forest(player, map)
	# Verify continuous spawn and pursuit on a later round.
	var spawner: Node2D = world.get_node("EnemySpawner")
	var enemy: CharacterBody2D = spawner.get_child(0)
	var distance := enemy.position.distance_to(player.position)
	await frames(40)
	check(enemy.position.distance_to(player.position) < distance, "pursuit resumes on new rounds")
	spawner.elapsed = spawner.spawn_interval
	var count: int = spawner.total_spawned
	await frames(3)
	check(spawner.total_spawned > count, "continuous spawning resumes on later rounds")
	player.invulnerability_left = 0
	player.take_damage(100)
	world.advance_round()
	await frames(2)
	check(world.game_over and world.round_number == 5 and paused, "GAME OVER prevents round transition")
	key_event(KEY_R, true)
	await frames(8)
	key_event(KEY_R, false)
	world = current_scene
	check(world.round_number == 5 and not world.get_node("ExplorationMap").forest and not paused, "continue retries Round 5 Riverside")
	check(world.get_node("Progression").level == world.checkpoint.level and world.get_node("Player").hp == 70, "continue restores entry progression and HP")
	print("PHASE_7_VERIFY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	world.queue_free()
	await process_frame
	# Allow the audio mixer to release stopped playback before process exit.
	await create_timer(0.15).timeout
	quit(0 if failures == 0 else 1)

func verify_forest(player: CharacterBody2D, map: Node2D) -> void:
	check(map.trees.size() == 48 and map.is_clear(Vector2(1024, 400)), "forest changes obstacle density and removes river")
	var rng := RandomNumberGenerator.new()
	rng.seed = 707
	var item: Node2D = world.get_node("Objective")
	var valid := true
	for index in range(25):
		valid = item.place(map, player, rng) and valid
		valid = map.is_clear(item.position) and not map.route(player.position, item.position).is_empty() and not map.is_behind_scenery(item.position) and valid
	check(valid, "25 forest objectives have safe reachable visible locations")
	for point in [map.trees[0] + Vector2(0, -38), map.shrine_position + Vector2(40, -10), map.gate_position + Vector2(48, 24)]:
		player.position = point
		await frames(12)
		check(is_equal_approx(player.modulate.a, 0.45), "forest tree / roof / gate applies behind opacity")
		player.position = Vector2(256, 256)
		await frames(12)
		check(is_equal_approx(player.modulate.a, 1.0), "exiting forest scenery restores full opacity")
	player.position = map.trees[0] + Vector2(0, 64)
	await frames(12)
	check(is_equal_approx(player.modulate.a, 1.0), "in front of forest trees stays fully visible")
	player.position = map.gate_position + Vector2(48, 48)
	await frames(3)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-7-forest-preview.png")
	player.position = map.start_position

func mouse_click(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)

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
