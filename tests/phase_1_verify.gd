extends SceneTree
## Integration check using real input events and CharacterBody2D physics.
var failures := 0
var player: CharacterBody2D
var world: Node2D

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	world = load("res://scenes/main.tscn").instantiate()
	world.shrines_enabled = false
	world.objective_enabled = false
	world.enemies_enabled = false
	root.add_child(world)
	player = world.get_node("Player")
	await frames(3)
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		check(InputMap.action_get_events(action).size() == 2, action + " has WASD + arrow binding")
	# All eight directions with physical key events, away from obstacles.
	for keys in [[KEY_D], [KEY_A], [KEY_W], [KEY_S], [KEY_D, KEY_W], [KEY_D, KEY_S], [KEY_A, KEY_W], [KEY_A, KEY_S], [KEY_LEFT], [KEY_RIGHT], [KEY_UP], [KEY_DOWN]]:
		player.position = Vector2(480, 440)
		for key in keys:
			key_event(key, true)
		await frames(15)
		check(is_equal_approx(player.velocity.length(), 100.0), "8-way normalized speed " + str(keys))
		check(player.position.distance_to(Vector2(480, 440)) > 15.0, "movement " + str(keys))
		for key in keys:
			key_event(key, false)
		await frames(2)
	player.position = Vector2(540, 384)
	await move(KEY_D, 60)
	check(player.position.x < 557.0, "rock collision")
	player.position = Vector2(320, 330)
	await move(KEY_W, 45)
	check(player.position.y >= 298.0, "tree trunk collision")
	player.position = Vector2(950, 450)
	await move(KEY_D, 60)
	check(player.position.x < 987.0, "river collision")
	player.position = Vector2(950, 576)
	await move(KEY_D, 90)
	check(player.position.x > 1060.0, "bridge crossing")
	for entry in [[Vector2(20, 440), KEY_A], [Vector2(1516, 440), KEY_D], [Vector2(480, 20), KEY_W], [Vector2(480, 1132), KEY_S]]:
		player.position = entry[0]
		await move(entry[1], 45)
		check(player.position.x >= 5.9 and player.position.x <= 1530.1 and player.position.y >= 3.9 and player.position.y <= 1148.1, "map boundary " + str(entry[1]))
	player.position = Vector2(800, 600)
	await frames(3)
	var camera: Camera2D = player.get_node("Camera2D")
	check((player.get_canvas_transform() * player.position).distance_to(Vector2(320, 230)) < 1.0, "camera follows player in area below header")
	player.position = Vector2(6, 4)
	await frames(3)
	var center := camera.get_screen_center_position()
	check(center.x >= 320 and is_equal_approx(center.y, 80), "camera limits place map top below 100px header")
	player.position = Vector2(480, 384)
	await frames(3)
	if not DisplayServer.get_name() == "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-1-preview.png")
		player.position = Vector2(1140, 390)
		await frames(3)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-1-shrine-preview.png")
	print("PHASE_1_VERIFY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
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

func move(key: int, count: int) -> void:
	key_event(key, true)
	await frames(count)
	key_event(key, false)
	await frames(2)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)
