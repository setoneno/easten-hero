extends SceneTree
var failures := 0
var session: Node
var world: Node2D

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://release-flow-test.json"
	if FileAccess.file_exists(session.save_path):
		DirAccess.remove_absolute(session.save_path)
	change_scene_to_file("res://scenes/title.tscn")
	await frames(4)
	check(current_scene.name == "Title" and current_scene.get_node("Continue").disabled and not paused, "startup title without save disables Continue")
	await snapshot("title")
	current_scene.get_node("NewGame").pressed.emit()
	await frames(5)
	world = current_scene
	check(world.round_number == 1 and world.managed_run and FileAccess.file_exists(session.save_path), "New Game starts Round 1 and persists entry checkpoint")
	check(not world.get_node("HUD/BossPractice").visible, "release-default hides practice UI")
	press(KEY_B)
	await frames(3)
	check(current_scene == world and world.round_number == 1, "release-default ignores B")
	var player: CharacterBody2D = world.get_node("Player")
	player.position = Vector2(480, 440)
	player.invulnerability_left = 10
	var thrower: Node2D = player.get_node("SwordThrower")
	var sword: CharacterBody2D = thrower.throw_sword()
	world.get_node("Feedback").announce("Pause verification")
	press(KEY_ESCAPE)
	await frames(3)
	check(paused and world.menu_paused and world.get_node("HUD/Pause").visible, "Esc opens pause menu")
	var before := player.position
	var enemy: CharacterBody2D = world.get_node("EnemySpawner").get_child(0)
	var enemy_before := enemy.position
	var flying := sword.position
	var cooldown: float = thrower.cooldown
	var spawn_time: float = world.get_node("EnemySpawner").elapsed
	var protection: float = player.invulnerability_left
	var notice: float = world.get_node("Feedback").notice_left
	Input.action_press("move_right")
	Input.action_press("throw_sword")
	await frames(20)
	Input.action_release("move_right")
	Input.action_release("throw_sword")
	player.take_damage(1000)
	check(player.position == before and enemy.position == enemy_before and sword.position == flying and thrower.cooldown == cooldown and world.get_node("EnemySpawner").elapsed == spawn_time and player.invulnerability_left == protection and world.get_node("Feedback").notice_left == notice and player.hp == 100, "pause freezes movement/enemies/projectiles/spawn/attack/protection/feedback/damage")
	await snapshot("pause")
	world.get_node("HUD/Pause/Resume").pressed.emit()
	await frames(4)
	check(not paused and not world.menu_paused and sword.position != flying, "Resume restarts same live scene")
	world.get_node("HUD/PauseButton").pressed.emit()
	await frames(3)
	check(paused, "HUD Pause button works")
	press(KEY_ESCAPE)
	await frames(2)
	check(not paused and not world.menu_paused, "Esc resumes the pause menu")
	world.get_node("HUD/PauseButton").pressed.emit()
	world.get_node("HUD/Pause/Title").pressed.emit()
	await frames(5)
	check(current_scene.name == "Title" and not paused and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("thrown_swords").is_empty(), "Pause Title removes old world and clears pause")
	check(not current_scene.get_node("Continue").disabled, "title enables persisted Continue")
	current_scene.get_node("Continue").pressed.emit()
	await frames(5)
	world = current_scene
	check(world.round_number == 1 and world.get_node("Player").hp == 100, "title Continue restores entry, not paused mid-round state")
	# A later entry is saved, then failed-round growth and boss are rolled back.
	world.get_node("Player").hp = 70
	world.get_node("Progression").level = 4
	world.get_node("Progression").exp = 17
	world.get_node("Progression").ability_levels.assign([3, 2, 1])
	world.round_number = 4
	world.round_cleared = true
	world.advance_round()
	await frames(4)
	check(session.checkpoint.round == 5, "latest Round 5 entry replaces disk checkpoint")
	world.get_node("Player").invulnerability_left = 10
	world._start_final_battle()
	var boss: CharacterBody2D = world.get_node("FinalBoss")
	check(not boss.debug_hints_enabled and not world.get_node("HUD/BossStatus/Name").text.contains(" | GUARD") and not world.get_node("HUD/BossStatus/Name").text.contains("OPEN"), "normal boss HUD hides internal hint/window")
	boss.take_damage(10)
	check(world.get_node("Feedback").popups.is_empty(), "normal guarded impact has no GUARD debug popup")
	boss._fire_arrows()
	var arrows := get_nodes_in_group("boss_projectiles")
	var arrow_before: Vector2 = arrows[0].position
	press(KEY_ESCAPE)
	await frames(2)
	var boss_time: float = boss.state_time
	var boss_position := boss.position
	boss._fire_arrows()
	await frames(10)
	check(boss.state_time == boss_time and boss.position == boss_position and arrows[0].position == arrow_before and get_nodes_in_group("boss_projectiles").size() == 3, "pause freezes boss/live arrows and blocks additional attacks")
	world.get_node("HUD/Pause/Resume").pressed.emit()
	world.get_node("Progression").add_exp(100)
	press(KEY_ESCAPE)
	check(paused and not world.menu_paused and world.get_node("HUD/LevelUp").visible, "Esc cannot bypass level choice")
	while world.get_node("Progression").pending_choices > 0:
		world._on_upgrade_selected(0)
	world.get_node("Player").invulnerability_left = 0
	world.get_node("Player").take_damage(1000)
	await frames(2)
	press(KEY_ESCAPE)
	check(paused and world.game_over and not world.menu_paused, "Esc cannot bypass Game Over")
	await snapshot("game-over")
	world.get_node("HUD/GameOver/Continue").pressed.emit()
	await frames(4)
	check(world.round_number == 5 and world.get_node("Player").hp == 70 and world.get_node("Progression").level == 4 and world.get_node("Shrines").visited_count == 0 and not world.has_node("FinalBoss"), "Game Over Continue restores Round 5 before boss")
	world.get_node("Player").invulnerability_left = 0
	world.get_node("Player").take_damage(1000)
	world.get_node("HUD/GameOver/Title").pressed.emit()
	await frames(4)
	check(current_scene.name == "Title" and not paused, "Game Over Title works")
	# Clear memory to prove a real disk reload, independent of this session's cache.
	session.checkpoint = {}
	session.load_checkpoint()
	check(session.checkpoint.round == 5 and session.checkpoint.hp == 70, "checkpoint survives cache reset and disk reload")
	current_scene.get_node("Continue").pressed.emit()
	await frames(5)
	world = current_scene
	world._start_final_battle()
	world.boss_defeated = true
	world._finish_game()
	await frames(3)
	check(paused and world.get_node("HUD/GameClear/NewGame").visible, "Game Clear waits for menu selection")
	press(KEY_ESCAPE)
	check(paused and not world.menu_paused, "Esc cannot bypass Game Clear")
	await snapshot("game-clear")
	world.get_node("HUD/GameClear/Title").pressed.emit()
	await frames(4)
	check(current_scene.name == "Title" and session.checkpoint.round == 5, "Game Clear Title retains checkpoint")
	current_scene.get_node("NewGame").pressed.emit()
	await frames(5)
	world = current_scene
	check(world.round_number == 1 and world.get_node("Progression").level == 1 and session.checkpoint.round == 1 and world.get_node("Progression").ability_levels == [1, 1, 1], "explicit New Game resets progress and disk checkpoint")
	# All result menus expose Exit; actual process-exit is checked separately.
	for menu in ["GameOver", "GameClear", "Pause"]:
		check(world.get_node("HUD/" + menu + "/Exit").pressed.get_connections().size() == 1, "Exit wired on " + menu)
	world.queue_free()
	await frames(3)
	var invalid_save := FileAccess.open(session.save_path, FileAccess.WRITE)
	invalid_save.store_string("invalid save")
	invalid_save.close()
	session.show_title()
	await frames(4)
	check(current_scene.get_node("Continue").disabled and not paused, "corrupt save disables Continue without starting gameplay")
	current_scene.queue_free()
	await frames(3)
	DirAccess.remove_absolute(session.save_path)
	session.managed_run = false
	print("RELEASE_FLOW_VERIFY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

func press(key: int) -> void:
	for pressed in [true, false]:
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

func snapshot(tag: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/release-" + tag + ".png")

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
