extends SceneTree
var failures := 0
var world: Node2D

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	world = load("res://scenes/main.tscn").instantiate()
	world.shrines_enabled = false
	world.objective_enabled = false
	root.add_child(world)
	current_scene = world
	var player: CharacterBody2D = world.get_node("Player")
	player.position = Vector2(480, 440)
	player.set_physics_process(false)
	var progression: Node = world.get_node("Progression")
	var menu: Control = world.get_node("HUD/LevelUp")
	var spawner: Node2D = world.get_node("EnemySpawner")
	var thrower: Node2D = player.get_node("SwordThrower")
	for enemy in spawner.get_children():
		enemy.set_physics_process(false)
	await frames(3)
	check(progression.level == 1 and progression.exp == 0, "starts at level 1 / EXP 0")
	check(world.get_node("HUD/Experience").text == "Lv 1   EXP 0 / 30", "level and EXP HUD initialized")
	var enemies := spawner.get_children()
	enemies[0].take_damage(20)
	enemies[0].take_damage(20)
	enemies[1].take_damage(20)
	check(progression.exp == 20 and world.defeated_count == 2 and not paused, "kills award EXP once, below threshold stays active")
	enemies[2].position = Vector2(530, 440)
	var sword: CharacterBody2D = thrower.throw_sword()
	check(sword != null, "real sword created for threshold kill")
	# First hit leaves 10 HP; a second real sword reaches the level threshold.
	await frames(30)
	check(enemies[2].hp == 10 and progression.exp == 20, "nonlethal sword gives no EXP")
	thrower.cooldown = 0
	thrower.throw_sword()
	await frames(30)
	check(paused and menu.visible and progression.level == 2, "sword kill immediately pauses and opens level 2 menu")
	check(progression.exp == 0 and progression.pending_choices == 1, "threshold consumed exactly once")
	check(world.get_node("HUD/ExperienceBar").max_value == 40 and world.get_node("HUD/ExperienceBar").value == 0, "EXP gauge uses next requirement")
	check(menu.get_node("Choice1").text.contains("10 > 15"), "three choices describe actual stat values")
	# A live projectile, pursuit, cooldown, protection and spawning all freeze.
	var flying: CharacterBody2D = load("res://scenes/thrown_sword.tscn").instantiate()
	flying.position = Vector2(800, 960)
	world.add_child(flying)
	var remaining: CharacterBody2D = enemies[3]
	remaining.set_physics_process(true)
	var before_enemy := remaining.position
	var before_player := player.position
	var before_sword := flying.position
	var before_timer: float = spawner.elapsed
	var before_count: int = spawner.total_spawned
	var before_cooldown: float = thrower.cooldown
	player.invulnerability_left = 0.5
	player.set_physics_process(true)
	Input.action_press("move_right")
	Input.action_press("throw_sword")
	key_event(KEY_R, true)
	await frames(15)
	key_event(KEY_R, false)
	Input.action_release("move_right")
	Input.action_release("throw_sword")
	check(current_scene == world, "R cannot bypass level choices")
	check(player.position == before_player and remaining.position == before_enemy and flying.position == before_sword, "player, enemies and swords freeze during choice")
	check(spawner.elapsed == before_timer and spawner.total_spawned == before_count and thrower.cooldown == before_cooldown, "spawn and attack timers freeze")
	check(player.invulnerability_left == 0.5 and thrower.throw_sword() == null, "protection freezes and direct attacks are blocked")
	player.take_damage(10)
	check(player.hp == 100, "no damage during choice")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-5-upgrade-preview.png")
	player.set_physics_process(false)
	key_event(KEY_1, true)
	await frames(2)
	key_event(KEY_1, false)
	check(not paused and not menu.visible and thrower.attack_damage == 15, "keyboard choice applies damage and resumes")
	thrower.cooldown = 0
	sword = thrower.throw_sword()
	check(sword.damage == 15, "upgraded damage used by new projectile")
	sword.queue_free()
	flying.queue_free()
	remaining.queue_free()
	await frames(2)
	check(progression.exp == 0 and world.defeated_count == 3, "retirement does not award EXP")
	progression.add_exp(125)
	check(progression.level == 4 and progression.exp == 35 and progression.pending_choices == 2, "large award carries overflow through multiple thresholds")
	check(paused and menu.get_node("Title").text.begins_with("LEVEL 3"), "first queued level selection shown")
	# Actual GUI click, not merely a direct call to the selection handler.
	mouse_click(Vector2(320, 220))
	await frames(2)
	check(is_equal_approx(thrower.attack_interval, 0.34), "mouse choice applies shorter attack interval")
	check(paused and progression.pending_choices == 1 and menu.get_node("Title").text.begins_with("LEVEL 4"), "second choice remains paused")
	key_event(KEY_3, true)
	await frames(2)
	key_event(KEY_3, false)
	check(not paused and progression.pending_choices == 0 and player.move_speed == 110, "last queued choice applies speed and resumes")
	progression.add_exp(25)
	key_event(KEY_1, true)
	await frames(2)
	key_event(KEY_1, false)
	check(thrower.attack_damage == 20 and progression.level == 5, "same upgrade can be selected again")
	player.set_physics_process(true)
	Input.action_press("move_right")
	Input.action_press("move_down")
	await frames(4)
	check(is_equal_approx(player.velocity.length(), 110), "upgraded diagonal movement still normalized")
	Input.action_release("move_right")
	Input.action_release("move_down")
	await frames(2)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-5-exp-preview.png")
	player.invulnerability_left = 0
	player.take_damage(100)
	var old_exp: int = progression.exp
	world._on_enemy_defeated(1000)
	world._on_upgrade_selected(0)
	check(paused and world.game_over and not menu.visible and progression.exp == old_exp, "GAME OVER rejects EXP and selections without resuming")
	key_event(KEY_R, true)
	await frames(8)
	key_event(KEY_R, false)
	world = current_scene
	player = world.get_node("Player")
	progression = world.get_node("Progression")
	thrower = player.get_node("SwordThrower")
	check(not paused and progression.level == 1 and progression.exp == 0 and progression.pending_choices == 0, "restart resets level, EXP and choices")
	check(player.move_speed == 100 and thrower.attack_damage == 10 and thrower.attack_interval == 0.4, "restart resets every upgrade")
	print("PHASE_5_VERIFY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	paused = false
	world.queue_free()
	await process_frame
	# Allow the audio mixer to release stopped playback before process exit.
	await create_timer(0.15).timeout
	quit(0 if failures == 0 else 1)

func mouse_click(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true) # Coordinates already use the 640x360 viewport.

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
