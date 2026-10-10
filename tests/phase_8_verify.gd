extends SceneTree
var failures := 0
var world: Node2D

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	world = load("res://scenes/main.tscn").instantiate()
	world.shrines_enabled = false
	root.add_child(world)
	current_scene = world
	var player: CharacterBody2D = world.get_node("Player")
	player.position = Vector2(480, 440)
	player.set_physics_process(false)
	var feedback: Node2D = world.get_node("Feedback")
	var progression: Node = world.get_node("Progression")
	var thrower: Node2D = player.get_node("SwordThrower")
	check(feedback.sounds.size() == 8, "eight original sound cues initialized")
	for audio in feedback.sounds.values():
		check(audio.stream.get_length() > 0 and audio.stream.data.size() > 0, "valid generated PCM audio stream")
	check(world.get_node("HUD/Panel").offset_bottom == 76, "compact HUD leaves more field visible")
	check(world.get_node("HUD/HealthBar").get_theme_stylebox("fill") != world.get_node("HUD/ExperienceBar").get_theme_stylebox("fill"), "HP and EXP use distinct fill styles")
	for enemy in world.get_node("EnemySpawner").get_children():
		enemy.set_physics_process(false)
	var target: CharacterBody2D = world.get_node("EnemySpawner").get_child(0)
	target.position = Vector2(530, 440)
	thrower.throw_sword()
	await frames(30)
	check(target.hp == 10 and feedback.cue_counts.get("throw", 0) == 1 and feedback.cue_counts.get("hit", 0) == 1, "real sword throw and hit produce sound feedback")
	thrower.cooldown = 0
	thrower.throw_sword()
	await frames(15)
	check(world.defeated_count == 1 and progression.exp == 10 and feedback.cue_counts.get("defeat", 0) == 1, "real kill awards EXP and defeat cue")
	check(feedback.popups.size() > 0 and world.get_node("HUD/Notice").text.contains("+10 EXP"), "defeat popup and EXP notice shown")
	player.take_damage(10)
	await frames(1)
	check(player.hp == 90 and world.get_node("HUD/HurtFlash").color.a > 0 and feedback.cue_counts.get("hurt", 0) == 1, "hit flash and hurt cue accompany HP loss")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-8-combat-preview.png")
	await frames(45)
	check(feedback.popups.is_empty() and world.get_node("HUD/HurtFlash").color.a == 0, "temporary feedback expires without accumulating")
	# Follow the same shared growth/clear path through multiple maps.
	for round_index in range(3):
		var item: Node2D = world.get_node("Objective")
		item.position = player.position
		item.try_collect()
		check(paused and feedback.cue_counts.get("clear", 0) == round_index + 1, "clear sound triggers once per round")
		if round_index == 0:
			check(feedback.cue_counts.get("level", 0) > 0, "level cue accompanies immediate menu")
			check(not feedback.sounds["level"].stream_paused, "UI sounds continue while gameplay is paused")
			key_event(KEY_M, true)
			await frames(1)
			key_event(KEY_M, false)
			check(feedback.muted and world.get_node("HUD/Controls").text.contains("SFX OFF"), "M toggles mute and HUD while paused")
			var all_stopped := true
			for audio in feedback.sounds.values():
				all_stopped = not audio.playing and all_stopped
			check(all_stopped, "mute stops current sounds")
			key_event(KEY_M, true)
			await frames(1)
			key_event(KEY_M, false)
			check(not feedback.muted and world.get_node("HUD/Controls").text.contains("SFX ON"), "M restores sound without bypassing upgrade pause")
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://docs/phase-8-level-preview.png")
		while progression.pending_choices > 0:
			key_event(KEY_1, true)
			await frames(2)
			key_event(KEY_1, false)
		check(world.get_node("HUD/RoundClear").visible and paused, "growth selections end at clear menu")
		if round_index == 0 and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/phase-8-clear-preview.png")
		key_event(KEY_N, true)
		await frames(5)
		key_event(KEY_N, false)
		check(world.round_number == round_index + 2 and not paused and player.hp == 90 and feedback.popups.is_empty(), "next map preserves HP/growth and clears old effects")
	check(feedback.cue_counts.get("select", 0) > 0 and progression.level > 1 and thrower.attack_damage > 10, "selection sounds and retained upgrades verified")
	player.invulnerability_left = 0
	player.take_damage(100)
	await frames(1)
	check(world.game_over and paused and feedback.cue_counts.get("game_over", 0) == 1, "GAME OVER visual and cue trigger once")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase-8-game-over-preview.png")
	key_event(KEY_R, true)
	await frames(8)
	key_event(KEY_R, false)
	world = current_scene
	check(world.round_number == 1 and world.get_node("Player").hp == 100 and world.get_node("Progression").level == 1 and not paused, "R restarts the complete loop cleanly")
	print("PHASE_8_VERIFY: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
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
