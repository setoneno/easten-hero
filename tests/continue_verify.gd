extends SceneTree
var failures := 0
var world: Node2D

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await frames(3)
	var player: CharacterBody2D = world.get_node("Player")
	player.set_physics_process(false)
	# Give Round 2 distinct entry values, then exercise real Next-round setup.
	world.get_node("Progression").level = 4
	world.get_node("Progression").exp = 17
	world.get_node("Progression").ability_levels.assign([3, 2, 1])
	player.hp = 70
	player.move_speed = 110
	player.get_node("SwordThrower").attack_damage = 20
	player.get_node("SwordThrower").attack_interval = 0.34
	player.get_node("SwordThrower").auto_aim = false
	world.defeated_count = 7
	world.round_cleared = true
	world.advance_round()
	await frames(3)
	check(world.round_number == 2 and world.checkpoint.hp == 70, "next round captures entry checkpoint")
	for attempt in range(2):
		world.get_node("Progression").add_exp(100)
		while world.get_node("Progression").pending_choices > 0:
			world._on_upgrade_selected(0)
		world.get_node("Shrines")._on_prayed()
		player.invulnerability_left = 0
		player.take_damage(1000)
		check(paused and world.game_over, "death waits for continue selection")
		if attempt == 0:
			var key := InputEventKey.new()
			key.physical_keycode = KEY_R
			key.pressed = true
			Input.parse_input_event(key)
			Input.flush_buffered_events()
		else:
			world.get_node("HUD/GameOver/Continue").pressed.emit()
		await frames(4)
		check(world.round_number == 2 and not paused and not world.game_over, "R/button continue same round")
		check(player.hp == 70 and not player.dead and player.invulnerability_left == 0, "restore entry HP and clear death")
		check(world.get_node("Progression").level == 4 and world.get_node("Progression").exp == 17 and world.get_node("Progression").ability_levels == [3, 2, 1], "discard this round growth, keep entry growth")
		check(player.get_node("SwordThrower").attack_damage == 20 and is_equal_approx(player.get_node("SwordThrower").attack_interval, 0.34) and player.move_speed == 110 and not player.get_node("SwordThrower").auto_aim, "restore combat and aim values")
		check(world.get_node("Shrines").visited_count == 0 and not world.get_node("Objective").visible and world.defeated_count == 7, "reset shrine/jade and restore entry kills")
		check(world.get_node("EnemySpawner").get_child_count() == 4 and get_nodes_in_group("thrown_swords").is_empty(), "fresh actors without old projectiles")
	# Round 5 checkpoint is before shrines and boss, even when death is in combat.
	world.round_number = 4
	world.round_cleared = true
	world.advance_round()
	await frames(3)
	for shrine in world.get_node("Shrines").get_children():
		shrine.prayed.emit()
	world._on_objective_collected()
	check(world.boss_active and world.has_node("FinalBoss"), "Round 5 has live boss before death")
	player.invulnerability_left = 0
	player.take_damage(1000)
	await screenshot("death")
	world.get_node("HUD/GameOver/Continue").pressed.emit()
	await frames(4)
	check(world.round_number == 5 and not world.boss_active and not world.has_node("FinalBoss"), "boss death restarts Round 5 before boss")
	check(world.get_node("Shrines").visited_count == 0 and not world.get_node("Objective").visible and get_nodes_in_group("boss_projectiles").is_empty(), "Round 5 shrine gate and projectile cleanup reset")
	for shrine in world.get_node("Shrines").get_children():
		shrine.prayed.emit()
	world._on_objective_collected()
	check(world.boss_active, "Round 5 can release jade and summon boss again")
	world.boss_defeated = true
	world._finish_game()
	var hud: CanvasLayer = world.get_node("HUD")
	hud._restart()
	await frames(4)
	world = current_scene
	check(world.round_number == 1 and world.get_node("Progression").level == 1 and world.get_node("Player").hp == 100, "GAME CLEAR starts fresh Round 1")
	world.queue_free()
	await frames(3)
	print("CONTINUE_VERIFY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

func frames(count: int) -> void:
	for index in range(count):
		if not paused:
			await physics_frame
		await process_frame

func screenshot(tag: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/continue-" + tag + ".png")

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
