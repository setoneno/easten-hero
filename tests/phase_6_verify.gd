extends SceneTree
var failures := 0
var world: Node2D

func _initialize() -> void:
	call_deferred("verify")

func start_world(bonus: int = 120) -> void:
	world = load("res://scenes/main.tscn").instantiate()
	world.shrines_enabled = false
	world.enemies_enabled = false
	world.round_bonus_exp = bonus
	root.add_child(world)
	current_scene = world
	world.get_node("Player").set_physics_process(false)

func verify() -> void:
	start_world()
	var player: CharacterBody2D = world.get_node("Player")
	var item: Node2D = world.get_node("Objective")
	var map: Node2D = world.get_node("ExplorationMap")
	var progression: Node = world.get_node("Progression")
	var rng := RandomNumberGenerator.new()
	rng.seed = 602
	var positions: Array[Vector2] = []
	var all_valid := true
	for attempt in range(40):
		all_valid = item.place(map, player, rng) and all_valid
		all_valid = map.is_clear(item.position) and not map.route(player.position, item.position).is_empty() and all_valid
		all_valid = item.position.distance_to(player.position) >= 240 and not map.is_behind_scenery(item.position) and all_valid
		if not positions.has(item.position):
			positions.append(item.position)
	check(all_valid, "40 placements are reachable, obstacle-free, visible and away from spawn")
	check(positions.size() > 30, "random placement produces varied locations")
	check(not world.round_cleared and not paused, "exploration begins without clear")
	item.try_collect()
	check(not item.collected_once and progression.exp == 0, "distant item cannot be collected")
	# Verify real movement into the pickup radius rather than only a direct handler call.
	item.position = Vector2(530, 440)
	player.position = Vector2(480, 440)
	await frames(3)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-6-item-preview.png")
	player.set_physics_process(true)
	var spawner: Node2D = load("res://scripts/enemy_spawner.gd").new()
	spawner.player = player
	spawner.map = map
	world.add_child(spawner)
	var flying: CharacterBody2D = load("res://scenes/thrown_sword.tscn").instantiate()
	flying.position = Vector2(800, 960)
	world.add_child(flying)
	Input.action_press("move_right")
	await frames(30)
	Input.action_release("move_right")
	check(world.round_cleared and paused and item.collected_once and not item.visible, "walking into magatama clears and consumes it")
	check(progression.level == 4 and progression.exp == 0 and progression.pending_choices == 3, "bonus 120 uses shared EXP and queues three upgrades")
	check(world.get_node("HUD/LevelUp").visible and not world.get_node("HUD/RoundClear").visible, "bonus choices precede final clear screen")
	var before_level: int = progression.level
	var before_enemy: Vector2 = spawner.get_child(0).position
	var before_sword := flying.position
	var before_timer: float = spawner.elapsed
	var before_spawned: int = spawner.total_spawned
	item.try_collect()
	world._on_objective_collected()
	world._on_enemy_defeated(1000)
	check(progression.level == before_level and progression.pending_choices == 3 and world.defeated_count == 0, "duplicate pickups and late kills cannot add reward")
	key_event(KEY_R, true)
	await frames(3)
	key_event(KEY_R, false)
	check(current_scene == world and paused, "R cannot skip bonus choices")
	for key in [KEY_1, KEY_2, KEY_3]:
		key_event(key, true)
		await frames(2)
		key_event(key, false)
		check(paused, "game stays stopped throughout bonus selections")
	check(progression.pending_choices == 0 and not world.get_node("HUD/LevelUp").visible, "every earned level gets one choice")
	check(world.get_node("HUD/RoundClear").visible and not world.game_over, "final clear screen shown after choices")
	check(player.get_node("SwordThrower").attack_damage == 15 and player.move_speed == 110, "bonus upgrades actually apply")
	var frozen_position := player.position
	Input.action_press("move_right")
	Input.action_press("throw_sword")
	await frames(8)
	Input.action_release("move_right")
	Input.action_release("throw_sword")
	check(player.position == frozen_position and player.get_node("SwordThrower").throw_sword() == null, "clear screen prevents movement and combat")
	check(spawner.get_child(0).position == before_enemy and flying.position == before_sword, "enemies and flying swords remain frozen through clear choices")
	check(spawner.elapsed == before_timer and spawner.total_spawned == before_spawned and spawner.spawn_enemy() == null, "clear freezes spawning and its timer")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-6-clear-preview.png")
	key_event(KEY_R, true)
	await frames(8)
	key_event(KEY_R, false)
	world = current_scene
	check(not paused and not world.round_cleared and not world.game_over, "R retries a fresh round")
	check(world.get_node("Progression").level == 1 and world.get_node("Player").move_speed == 100, "retry resets growth")
	check(not world.get_node("Objective").visible and not world.get_node("Objective").collected_once and world.get_node("Shrines").visited_count == 0, "retry resets shrine trials and locks new objective")
	world.queue_free()
	await process_frame
	# Bonus below the next threshold skips the upgrade menu and retains EXP.
	start_world(5)
	player = world.get_node("Player")
	item = world.get_node("Objective")
	progression = world.get_node("Progression")
	progression.add_exp(20)
	item.position = player.position
	item.try_collect()
	check(paused and world.get_node("HUD/RoundClear").visible and not world.get_node("HUD/LevelUp").visible, "small bonus clears without upgrade menu")
	check(progression.exp == 25 and progression.level == 1, "kill EXP and bonus share one gauge")
	paused = false
	world.queue_free()
	await process_frame
	# Pickup queued during the physics frame must lose to lethal damage that frame.
	start_world()
	player = world.get_node("Player")
	item = world.get_node("Objective")
	progression = world.get_node("Progression")
	item.position = player.position
	item._physics_process(1.0 / 60.0)
	player.take_damage(100)
	await frames(3)
	check(world.game_over and not world.round_cleared and not item.collected_once, "same-frame lethal damage wins over deferred pickup")
	check(progression.level == 1 and progression.exp == 0 and not world.get_node("HUD/RoundClear").visible, "GAME OVER gives no clear bonus or overlay")
	# Paused for an ordinary level-up: no pickup until gameplay resumes.
	paused = false
	world.queue_free()
	await process_frame
	start_world(5)
	player = world.get_node("Player")
	item = world.get_node("Objective")
	progression = world.get_node("Progression")
	progression.add_exp(30)
	item.position = player.position
	item.try_collect()
	check(not item.collected_once and not world.round_cleared, "level-up pause blocks pickup")
	key_event(KEY_1, true)
	await frames(4)
	key_event(KEY_1, false)
	check(item.collected_once and world.round_cleared and progression.exp == 5, "pickup resolves normally after selection resumes")
	print("PHASE_6_VERIFY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	paused = false
	world.queue_free()
	await process_frame
	# Allow the audio mixer to release stopped playback before process exit.
	await create_timer(0.15).timeout
	quit(0 if failures == 0 else 1)

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
