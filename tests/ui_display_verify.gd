extends SceneTree
var failures := 0
var world: Node2D

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	world = load("res://scenes/main.tscn").instantiate()
	world.enemies_enabled = false
	world.objective_enabled = false
	world.shrines_enabled = false
	root.add_child(world)
	current_scene = world
	var player: CharacterBody2D = world.get_node("Player")
	player.set_physics_process(false)
	var progress: Node = world.get_node("Progression")
	var initial_interval: float = player.get_node("SwordThrower").attack_interval
	check(progress.ability_levels == [1, 1, 1], "all abilities start at Lv1")
	check(world.get_node("HUD/Abilities").text.contains("QUICK THROW Lv1"), "ability HUD initialized")
	for choice in [0, 0, 1, 2]:
		progress.add_exp(progress.required_exp() - progress.exp)
		var button: Button = world.get_node("HUD/LevelUp/Choice" + str(choice + 1))
		check(button.text.contains("Lv%d > Lv%d" % [progress.ability_levels[choice], progress.ability_levels[choice] + 1]), "choice shows current and next ability level")
		world._on_upgrade_selected(choice)
	check(progress.ability_levels == [3, 2, 2], "only selected ability advances, repeated choice supported")
	check(player.get_node("SwordThrower").attack_damage == 20 and is_equal_approx(player.get_node("SwordThrower").attack_interval, initial_interval * 0.85) and player.move_speed == 110, "existing effect values retained")
	await snapshot("abilities")
	progress.add_exp(progress.required_exp() - progress.exp)
	await snapshot("choices")
	world._on_upgrade_selected(2)
	world.round_cleared = true
	world._begin_next_round()
	check(progress.ability_levels == [3, 2, 3], "ability levels carry into next map")
	for forest in [false, true]:
		world.get_node("ExplorationMap").load_layout(forest)
		await verify_camera(player, "forest" if forest else "riverside")
	world.round_number = 5
	player.position = Vector2(560, 520)
	world._start_final_battle()
	world.get_node("FinalBoss").set_physics_process(false)
	await verify_camera(player, "boss")
	reload_current_scene()
	await frames(3)
	world = current_scene
	check(world.get_node("Progression").ability_levels == [1, 1, 1], "restart resets ability levels")
	world.queue_free()
	await frames(3)
	print("UI_DISPLAY_VERIFY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

func verify_camera(player: CharacterBody2D, tag: String) -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	var header: float = world.get_node("HUD/Panel").offset_bottom
	for point in [Vector2(480, 440), Vector2(24, 32), Vector2(1512, 32), Vector2(24, 1120), Vector2(1512, 1120)]:
		player.position = point
		await frames(3)
		var transform := player.get_canvas_transform()
		var screen := transform * player.position
		var top_left := transform.affine_inverse() * Vector2(0, header)
		var bottom_right := transform.affine_inverse() * Vector2(640, 360)
		print("VIEW ", tag, " ", point, " screen=", screen, " bounds=", top_left, "..", bottom_right)
		check(screen.y >= header + 24 and screen.y <= 360 and screen.x >= 0 and screen.x <= 640, "player above feet remains below header " + tag)
		check(top_left.x >= -0.1 and top_left.y >= -0.1 and bottom_right.x <= 1536.1 and bottom_right.y <= 1152.1, "effective map viewport stays within map " + tag)
		if point == Vector2(480, 440):
			check(screen.distance_to(Vector2(320, (header + 360) / 2)) < 1, "player centered in game area " + tag)
		if point == Vector2(24, 32) or point == Vector2(1512, 1120):
			await snapshot(tag + ("-top" if point.y == 32 else "-bottom"))

func snapshot(tag: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/ui-display-" + tag + ".png")

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
