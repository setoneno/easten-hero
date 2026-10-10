extends SceneTree
var failures := 0
var world: Node2D
var player: CharacterBody2D

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	world = load("res://scenes/main.tscn").instantiate()
	world.shrines_enabled = false
	world.objective_enabled = false
	world.enemies_enabled = false
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	player.position = Vector2(480, 440)
	await frames(3)
	check(player.hp == 100 and not player.dead, "starts alive with full HP")
	check(world.get_node("HUD/Health").text == "HP 100 / 100", "HP label initialized")
	check(world.get_node("HUD/HealthBar").value == 100, "HP bar initialized")
	key_event(KEY_R, true)
	await frames(2)
	key_event(KEY_R, false)
	check(current_scene == world, "R does not restart an active game")
	await frames(5)
	check(player.hp == 100, "terrain and empty field do not damage player")
	# Real enemy pursuit must reach the hurtbox despite its close-range stop.
	var enemy := create_enemy(Vector2(540, 440), false)
	await frames(60)
	check(player.hp == 90, "pursuing enemy contact deals 10 damage")
	check(player.invulnerability_left > 0, "contact grants invulnerability")
	enemy.queue_free()
	await frames(70)
	check(player.hp == 90, "leaving contact prevents more damage")
	var contacts: Array[CharacterBody2D] = []
	for point in [Vector2(494, 440), Vector2(466, 440), Vector2(480, 454)]:
		contacts.append(create_enemy(point, true))
	await frames(4)
	check(player.hp == 80, "multiple touching enemies cannot stack damage")
	check(world.get_node("HUD/HealthBar").value == 80, "HP bar updates after hit")
	check(world.get_node("HUD/Protection").text == "INVULNERABLE", "invulnerability displayed")
	await frames(30)
	check(player.hp == 80, "continuous contact protected during 1 second cooldown")
	await frames(34)
	check(player.hp == 70, "continuous contact damages again after cooldown")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-4-health-preview.png")
	# A defeated enemy still present until deferred deletion must never deal contact damage.
	for contact in contacts:
		contact.take_damage(contact.max_hp)
	await frames(3)
	player.invulnerability_left = 0
	await frames(3)
	check(player.hp == 70, "dead enemies do not cause contact damage")
	# Freeze a running scene with enemies, a live projectile and a spawn timer.
	var spawner: Node2D = load("res://scripts/enemy_spawner.gd").new()
	spawner.name = "EnemySpawner"
	spawner.player = player
	spawner.map = world.get_node("ExplorationMap")
	world.add_child(spawner)
	enemy = create_enemy(Vector2(494, 440), true)
	var sword: CharacterBody2D = load("res://scenes/thrown_sword.tscn").instantiate()
	sword.position = Vector2(800, 960)
	world.add_child(sword)
	var deaths := [0]
	player.died.connect(func() -> void: deaths[0] += 1)
	player.hp = 10
	player.invulnerability_left = 0
	await frames(4)
	check(player.dead and player.hp == 0, "zero HP marks player dead")
	check(world.game_over and paused, "GAME OVER pauses SceneTree")
	check(world.get_node("HUD/GameOver").visible, "GAME OVER overlay visible")
	check(world.get_node("HUD/HealthBar").value == 0, "HP bar reaches zero before pause")
	var position_before := player.position
	var enemy_before: Vector2 = spawner.get_child(0).position
	var sword_before := sword.position
	var spawn_count: int = spawner.total_spawned
	var spawn_elapsed: float = spawner.elapsed
	var enemy_hp: int = enemy.hp
	var thrower: Node2D = player.get_node("SwordThrower")
	var shots: int = thrower.shots_fired
	key_event(KEY_D, true)
	key_event(KEY_SPACE, true)
	await frames(80)
	key_event(KEY_D, false)
	key_event(KEY_SPACE, false)
	check(player.position == position_before and player.velocity == Vector2.ZERO, "movement stopped after defeat")
	check(spawner.get_child(0).position == enemy_before, "enemy pursuit stopped after defeat")
	check(sword.position == sword_before, "existing projectiles stopped after defeat")
	check(spawner.total_spawned == spawn_count and spawner.elapsed == spawn_elapsed, "spawn timer and new spawns stopped")
	check(thrower.shots_fired == shots and thrower.throw_sword() == null, "attacks blocked after defeat")
	check(spawner.spawn_enemy() == null, "direct spawn request blocked during GAME OVER")
	enemy.take_damage(10)
	player.take_damage(100)
	check(enemy.hp == enemy_hp and player.hp == 0 and deaths[0] == 1, "combat frozen and death emitted only once")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-4-game-over-preview.png")
	world.enemies_enabled = true # Restore production spawning for the continuation fixture.
	key_event(KEY_R, true)
	await frames(8)
	key_event(KEY_R, false)
	world = current_scene
	player = world.get_node("Player")
	check(not paused and not world.game_over, "R continues and resumes the scene")
	check(player.hp == 100 and not player.dead and player.invulnerability_left == 0, "restart resets health and protection")
	check(world.defeated_count == 0 and not world.get_node("HUD/GameOver").visible, "restart resets HUD and overlay")
	check(world.get_node("EnemySpawner").get_child_count() == 4, "restart restores initial four enemies")
	check(get_nodes_in_group("thrown_swords").is_empty(), "restart removes old projectiles")
	Input.action_press("move_right")
	var restarted_position := player.position
	await frames(5)
	Input.action_release("move_right")
	check(player.position.x > restarted_position.x, "movement works after restart")
	print("PHASE_4_VERIFY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	paused = false
	world.queue_free()
	await process_frame
	# Allow the audio mixer to release stopped playback before process exit.
	await create_timer(0.15).timeout
	quit(0 if failures == 0 else 1)

func create_enemy(point: Vector2, stationary: bool) -> CharacterBody2D:
	var enemy: CharacterBody2D = load("res://scenes/enemy.tscn").instantiate()
	enemy.position = point
	enemy.player = player
	enemy.map = world.get_node("ExplorationMap")
	world.add_child(enemy)
	if stationary:
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
		if not paused:
			await physics_frame
		await process_frame

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
