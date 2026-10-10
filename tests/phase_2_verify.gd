extends SceneTree
var failures := 0
var world: Node2D
var player: CharacterBody2D
var map: Node2D

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	world = load("res://scenes/main.tscn").instantiate()
	world.shrines_enabled = false
	world.objective_enabled = false
	root.add_child(world)
	player = world.get_node("Player")
	player.set_physics_process(false) # Keep pursuit targets independent of live keyboard input.
	map = world.get_node("ExplorationMap")
	var spawner: Node2D = world.get_node("EnemySpawner")
	await frames(2)
	check(spawner.get_child_count() == 4, "four initial enemies")
	for enemy in spawner.get_children():
		check(map.is_clear(enemy.position), "valid initial spawn")
		check(enemy.position.distance_to(player.position) > 150, "spawn away from player")
	var initial_count: int = spawner.total_spawned
	await frames(190)
	check(spawner.total_spawned > initial_count, "continuous timed spawn")
	spawner.spawn_interval = 0.05
	await frames(180)
	check(spawner.get_child_count() == 24, "enemy cap reached without exceeding 24")
	player.position = Vector2(1400, 1000)
	await frames(8)
	check(spawner.get_child_count() < 24, "distant enemies retire")
	initial_count = spawner.total_spawned
	await frames(12)
	check(spawner.total_spawned > initial_count, "spawning resumes after retirement")
	spawner.set_physics_process(false)
	for enemy in spawner.get_children():
		enemy.queue_free()
	await frames(2)
	# Pursuer must route around the rock rather than push into it.
	player.position = Vector2(640, 384)
	var pursuer := create_enemy(Vector2(520, 384))
	await frames(220)
	print("ROCK position=", pursuer.position, " target=", player.position)
	check(pursuer.position.distance_to(player.position) < 24, "pursuit around rock")
	check(pursuer.position.x > 600, "passed rock without getting stuck")
	pursuer.queue_free()
	await frames(2)
	# Across-bank pursuit must use the only bridge.
	player.position = Vector2(1120, 440)
	pursuer = create_enemy(Vector2(900, 440))
	var crossed_bridge := false
	var crossed_water := false
	for index in range(600):
		await frames(1)
		if pursuer.position.x >= 992 and pursuer.position.x <= 1056:
			if pursuer.position.y >= 548 and pursuer.position.y <= 604:
				crossed_bridge = true
			else:
				crossed_water = true
	check(crossed_bridge and not crossed_water, "river crossing uses bridge only")
	print("RIVER position=", pursuer.position, " target=", player.position)
	check(pursuer.position.distance_to(player.position) < 24, "reaches target across river")
	# Player is faster and remains able to move through pursuers in this phase.
	player.position = Vector2(480, 440)
	pursuer.position = Vector2(430, 440)
	pursuer.repath_time = 0
	var initial_gap := player.position.distance_to(pursuer.position)
	player.set_physics_process(true)
	Input.action_press("move_right")
	await frames(45)
	Input.action_release("move_right")
	player.set_physics_process(false)
	print("ESCAPE position=", player.position, " enemy=", pursuer.position)
	check(player.position.distance_to(pursuer.position) > initial_gap, "player can escape slower enemy")
	check(player.position.x > 550, "player movement remains enabled")
	pursuer.queue_free()
	await frames(2)
	player.position = Vector2(480, 384)
	for point in [Vector2(400, 400), Vector2(600, 420), Vector2(520, 480)]:
		create_enemy(point)
	await frames(2)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-2-preview.png")
	print("PHASE_2_VERIFY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	world.queue_free()
	await process_frame
	# Allow the audio mixer to release stopped playback before process exit.
	await create_timer(0.15).timeout
	quit(0 if failures == 0 else 1)

func create_enemy(point: Vector2) -> CharacterBody2D:
	var enemy: CharacterBody2D = load("res://scenes/enemy.tscn").instantiate()
	enemy.position = point
	enemy.player = player
	enemy.map = map
	world.add_child(enemy)
	return enemy

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
