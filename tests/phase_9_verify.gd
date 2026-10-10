extends SceneTree
var failures := 0
var world: Node2D

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	world = load("res://scenes/main.tscn").instantiate()
	world.enemies_enabled = false
	world.boss_enabled = false # Verify the Phase 9 handoff in isolation.
	root.add_child(world)
	current_scene = world
	var player: CharacterBody2D = world.get_node("Player")
	player.set_physics_process(false)
	var trials: Node2D = world.get_node("Shrines")
	var item: Node2D = world.get_node("Objective")
	var map: Node2D = world.get_node("ExplorationMap")
	var progression: Node = world.get_node("Progression")
	var boss_requests := [0]
	world.final_battle_requested.connect(func() -> void: boss_requests[0] += 1)
	for round_index in range(5):
		check(world.round_number == round_index + 1 and world.round_number <= 5, "round stays in five-stage range")
		check(trials.get_child_count() == 3 and trials.visited_count == 0, "each round starts with three unvisited shrines")
		check(not item.visible and not item.is_physics_processing(), "magatama absent and inactive at round start")
		item.try_collect()
		world._on_objective_collected()
		check(not world.round_cleared and not world.final_battle_pending, "locked magatama cannot complete round")
		for shrine in trials.get_children():
			var entrance: Vector2 = shrine.position + shrine.prayer_point
			check(map.is_clear(entrance) and not map.route(player.position, entrance).is_empty(), "prayer entrance is unobstructed and reachable")
		var shrines := trials.get_children()
		player.position = shrines[0].position + shrines[0].prayer_point
		paused = true
		shrines[0].try_pray()
		check(trials.visited_count == 0, "paused gameplay rejects prayer")
		paused = false
		for index in range(3):
			var shrine: Node2D = shrines[index]
			if index == 1 and round_index == 0:
				# Move into a real prayer radius from just outside it.
				player.position = shrine.position + shrine.prayer_point + Vector2(34, 0)
				await frames(2)
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://docs/phase-9-shrine-preview.png")
				player.set_physics_process(true)
				Input.action_press("move_left")
				await frames(12)
				Input.action_release("move_left")
				player.set_physics_process(false)
			else:
				player.position = shrine.position + shrine.prayer_point
				await frames(3)
			check(shrine.visited and trials.visited_count == index + 1, "praying increments distinct shrine count")
			shrine.try_pray()
			check(trials.visited_count == index + 1, "repeat prayer does not count twice")
			check(item.visible == (index == 2), "magatama appears only after third prayer")
		check(world.get_node("HUD/ObjectiveHint").text.contains("3/3"), "HUD shows three shrines completed")
		check(map.is_clear(item.position) and not map.route(player.position, item.position).is_empty(), "released magatama is reachable")
		if round_index == 0:
			await verify_occlusion(player, map, shrines[1])
		player.position = item.position
		await frames(3)
		if round_index < 4:
			check(world.round_cleared and paused and not world.final_battle_pending, "rounds 1-4 award normal clear")
			while progression.pending_choices > 0:
				world._on_upgrade_selected(0)
			check(world.get_node("HUD/RoundClear").visible and paused, "bonus selections finish before advancing")
			var saved_level: int = progression.level
			var saved_exp: int = progression.exp
			world.advance_round()
			await frames(4)
			check(not paused and progression.level == saved_level and progression.exp == saved_exp, "next stage preserves progression")
		else:
			check(world.final_battle_pending and paused and boss_requests[0] == 1, "round 5 pickup requests final battle exactly once")
			check(not world.round_cleared and not world.game_over and progression.pending_choices == 0, "round 5 pickup is neither GAME CLEAR nor normal clear")
			check(not world.get_node("HUD/RoundClear/Next").visible, "final battle has no next-round button")
			world.advance_round()
			world._begin_next_round()
			world._on_objective_collected()
			await frames(3)
			check(world.round_number == 5 and boss_requests[0] == 1 and paused, "cannot enter round 6 or request boss twice")
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://docs/phase-9-final-pending-preview.png")
	key_event(KEY_R, true)
	await frames(8)
	key_event(KEY_R, false)
	world = current_scene
	trials = world.get_node("Shrines")
	player = world.get_node("Player")
	player.set_physics_process(false)
	check(world.round_number == 1 and trials.visited_count == 0 and not world.get_node("Objective").visible and not paused, "restart resets all shrine and final-battle state")
	# Same-frame death must beat deferred prayer just as it beats item pickup.
	var shrine: Node2D = trials.get_child(0)
	player.position = shrine.position + shrine.prayer_point
	shrine._physics_process(1.0 / 60)
	player.take_damage(100)
	await frames(3)
	check(world.game_over and not shrine.visited and trials.visited_count == 0, "lethal damage wins over deferred prayer")
	print("PHASE_9_VERIFY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	paused = false
	world.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(0 if failures == 0 else 1)

func verify_occlusion(player: CharacterBody2D, map: Node2D, shrine: Node2D) -> void:
	player.position = shrine.position + Vector2(0, -26)
	await frames(12)
	check(is_equal_approx(player.modulate.a, 0.45), "new shrine roof has behind opacity")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-9-roof-preview.png")
	player.position = shrine.position + Vector2(0, 40)
	await frames(12)
	check(is_equal_approx(player.modulate.a, 1.0), "new shrine front restores opacity")
	player.position = shrine.position + Vector2(50, 0)
	player.set_physics_process(true)
	Input.action_press("move_left")
	await frames(24)
	Input.action_release("move_left")
	player.set_physics_process(false)
	check(player.position.x >= shrine.position.x + 21, "new shrine has actual feet collision")

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
