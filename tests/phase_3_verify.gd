extends SceneTree
var failures := 0
var world: Node2D
var player: CharacterBody2D
var thrower: Node2D

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	world = load("res://scenes/main.tscn").instantiate()
	world.shrines_enabled = false
	world.objective_enabled = false
	world.enemies_enabled = false
	root.add_child(world)
	player = world.get_node("Player")
	thrower = player.get_node("SwordThrower")
	player.set_physics_process(false)
	player.position = Vector2(480, 440)
	var enemy := create_enemy(Vector2(600, 440))
	await frames(3)
	check(thrower.aim_direction().dot(Vector2.RIGHT) > 0.99, "auto aim targets nearest visible enemy")
	var sword: CharacterBody2D = thrower.throw_sword()
	check(thrower.throw_sword() == null, "cooldown rejects immediate repeat")
	await frames(40)
	check(enemy.hp == 10, "sword impact deals damage exactly once")
	check(not is_instance_valid(sword), "sword disappears on enemy impact")
	thrower.throw_sword()
	await frames(40)
	check(not is_instance_valid(enemy), "zero HP enemy disappears")
	check(get_nodes_in_group("enemies").is_empty(), "dead enemy removed from target group")
	# A rock blocks nearer enemy; auto aim must select an unobstructed target.
	player.position = Vector2(520, 384)
	var blocked := create_enemy(Vector2(616, 384))
	var visible := create_enemy(Vector2(520, 520))
	await frames(3)
	check(thrower.aim_direction().dot(Vector2.DOWN) > 0.99, "auto aim skips enemy behind rock")
	thrower.auto_aim = false
	var mouse := InputEventMouseMotion.new()
	mouse.position = world.get_global_transform_with_canvas() * Vector2(700, 384)
	root.push_input(mouse, true)
	await frames(2)
	check(thrower.aim_direction().dot(Vector2.RIGHT) > 0.99, "manual aim follows mouse world position")
	thrower.cooldown = 0
	sword = thrower.throw_sword()
	await frames(35)
	check(blocked.hp == 20 and not is_instance_valid(sword), "obstacle stops sword before enemy")
	blocked.queue_free()
	visible.queue_free()
	await frames(2)
	# Ray sweep movement must still hit a narrow enemy at extreme test speed.
	player.position = Vector2(480, 440)
	enemy = create_enemy(Vector2(600, 440))
	await frames(2)
	thrower.auto_aim = true
	thrower.projectile_speed = 12000
	thrower.cooldown = 0
	thrower.throw_sword()
	await frames(3)
	check(enemy.hp == 10, "fast sword cannot tunnel through enemy")
	enemy.queue_free()
	await frames(2)
	thrower.projectile_speed = 320
	thrower.attack_range = 40
	thrower.cooldown = 0
	player.facing = Vector2.RIGHT
	sword = thrower.throw_sword()
	await frames(12)
	check(not is_instance_valid(sword), "range limit removes missed sword")
	thrower.attack_range = 400
	# Real input bindings, hold-to-repeat, switching and release.
	thrower.cooldown = 0
	var initial_shots: int = thrower.shots_fired
	key_event(KEY_SPACE, true)
	await frames(65)
	key_event(KEY_SPACE, false)
	check(thrower.shots_fired - initial_shots == 3, "Space hold repeats at configured interval")
	initial_shots = thrower.shots_fired
	await frames(30)
	check(thrower.shots_fired == initial_shots, "release stops throwing")
	key_event(KEY_TAB, true)
	await frames(2)
	key_event(KEY_TAB, false)
	check(not thrower.auto_aim, "Tab toggles to manual aim")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await frames(2)
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(click)
	check(thrower.shots_fired > initial_shots, "left click throws sword")
	# Snapshot a visible sword, two HP states and both player/enemy sprites.
	await frames(90)
	player.position = Vector2(480, 440)
	enemy = create_enemy(Vector2(650, 440))
	create_enemy(Vector2(600, 510))
	enemy.take_damage(10)
	thrower.auto_aim = true
	thrower.cooldown = 0
	await frames(2)
	thrower.throw_sword()
	await frames(8)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-3-preview.png")
	print("PHASE_3_VERIFY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	world.queue_free()
	await process_frame
	world = load("res://scenes/main.tscn").instantiate()
	world.shrines_enabled = false
	world.objective_enabled = false
	root.add_child(world)
	var spawner: Node2D = world.get_node("EnemySpawner")
	await frames(3)
	enemy = spawner.get_child(0)
	enemy.take_damage(enemy.max_hp)
	enemy.take_damage(enemy.max_hp)
	await frames(2)
	check(world.defeated_count == 1, "defeat signal updates HUD counter only once")
	check(spawner.get_child_count() == 3, "defeat frees an active spawn slot")
	spawner.spawn_interval = 0.05
	await frames(6)
	check(spawner.total_spawned > 4, "spawning continues after defeat")
	world.queue_free()
	await process_frame
	print("PHASE_3_FINAL: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	# Allow the audio mixer to release stopped playback before process exit.
	await create_timer(0.15).timeout
	quit(0 if failures == 0 else 1)

func create_enemy(point: Vector2) -> CharacterBody2D:
	var enemy: CharacterBody2D = load("res://scenes/enemy.tscn").instantiate()
	enemy.position = point
	enemy.player = player
	enemy.map = world.get_node("ExplorationMap")
	world.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy

func key_event(key: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
