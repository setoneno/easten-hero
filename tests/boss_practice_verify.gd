extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var world: Node2D = load("res://scenes/main.tscn").instantiate()
	world.debug_tools_enabled = true
	root.add_child(world)
	current_scene = world
	check(world.round_number == 1, "normal main starts Round 1")
	await frames(3)
	press(KEY_B)
	await frames(12)
	world = current_scene
	check(world.scene_file_path == "res://scenes/boss_test.tscn" and world.round_number == 5 and world.boss_active and not paused, "B from normal main opens live Round 5 boss practice")
	check(world.get_node("Player").hp == 100 and world.get_node("Player/SwordThrower").attack_damage == 30 and not world.has_node("EnemySpawner"), "practice preset and boss-only population applied")
	check(world.get_node("HUD/Round").text.contains("5 / 5") and world.get_node("HUD/BossStatus").visible, "practice visibly identifies Round 5 and boss")
	var player: CharacterBody2D = world.get_node("Player")
	var boss: CharacterBody2D = world.get_node("FinalBoss")
	var player_start := player.position
	var boss_start := boss.position
	key_event(KEY_S, true)
	await frames(15)
	key_event(KEY_S, false)
	check(player.position.y > player_start.y + 15 and boss.position.distance_to(boss_start) > 5, "after switching, real movement input works and boss pursuit advances")
	var thrower: Node2D = player.get_node("SwordThrower")
	var shots_before: int = thrower.shots_fired
	key_event(KEY_SPACE, true)
	await frames(3)
	key_event(KEY_SPACE, false)
	check(thrower.shots_fired > shots_before, "after switching, Space fires real swords")
	player.invulnerability_left = 10 # Input/timer test; damage is covered by Phase 10.
	await frames(155)
	check(boss.attacks_started.arrows > 0, "boss warning and arrow attack timers advance after switching")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/boss-practice-preview.png")
	world.get_node("FinalBoss")._fire_arrows()
	world.get_node("FinalBoss").take_damage(240)
	await frames(4)
	check(world.game_cleared and paused, "practice reaches GAME CLEAR")
	press(KEY_R)
	await frames(12)
	world = current_scene
	check(world.round_number == 5 and world.boss_active and not world.game_cleared and not paused, "R retries boss practice instead of Round 1")
	world.get_node("Player").invulnerability_left = 0
	world.get_node("Player").take_damage(100)
	await frames(3)
	press(KEY_B)
	await frames(12)
	world = current_scene
	check(world.round_number == 5 and world.boss_active and not world.game_over and not paused, "B from paused defeat retries practice")
	world.get_node("HUD/BossPractice").pressed.emit()
	await frames(12)
	world = current_scene
	check(world.round_number == 5 and world.boss_active and not paused, "screen button starts fresh live boss practice")
	print("BOSS_PRACTICE_VERIFY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	paused = false
	world.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(0 if failures == 0 else 1)

func press(key: int) -> void:
	key_event(key, true)
	key_event(key, false)

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

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)
