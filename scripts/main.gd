extends Node2D
@export var enemies_enabled := true
@export var objective_enabled := true
@export var round_bonus_exp := 120
@export var shrines_enabled := true
@export var boss_enabled := true
@export var debug_tools_enabled := false
var managed_run := false
var menu_paused := false

func debug_tools_allowed() -> bool:
	return debug_tools_enabled and OS.is_debug_build()
const TOTAL_ROUNDS := 5
signal final_battle_requested
var final_battle_pending := false
var boss_active := false
var boss_defeated := false
var game_cleared := false
var defeated_count := 0
var game_over := false
var round_cleared := false
var round_number := 1
var transitioning := false
var checkpoint: Dictionary = {}

func _ready() -> void:
	managed_run = GameSession.managed_run
	$Player.died.connect(_on_player_died)
	$Player.health_changed.connect(_on_health_changed)
	$Player/SwordThrower.thrown.connect(func() -> void: $Feedback.play_cue("throw"))
	$Feedback.mute_changed.connect(_update_hud)
	$Progression.changed.connect(_on_progression_changed)
	$HUD/LevelUp.selected.connect(_on_upgrade_selected)
	$HUD.next_round_requested.connect(advance_round)
	$Objective.collected.connect(_on_objective_collected)
	$Shrines.progress_changed.connect(_on_shrine_progress)
	if managed_run and not GameSession.starting_checkpoint.is_empty():
		checkpoint = GameSession.starting_checkpoint.duplicate(true)
		GameSession.starting_checkpoint = {}
		_restore_checkpoint()
	else:
		_setup_objective()
		_create_spawner()
	_update_hud()
	_capture_checkpoint()
	print("Game 002 Phase 10: Round 5 boss defeat clears the game; R restarts; M toggles sound.")

func _capture_checkpoint() -> void:
	checkpoint = {
		"round": round_number, "forest": round_number % 2 == 0,
		"level": $Progression.level, "exp": $Progression.exp,
		"abilities": $Progression.ability_levels.duplicate(),
		"hp": $Player.hp, "max_hp": $Player.max_hp, "speed": $Player.move_speed,
		"damage": $Player/SwordThrower.attack_damage,
		"interval": $Player/SwordThrower.attack_interval,
		"projectile_speed": $Player/SwordThrower.projectile_speed,
		"range": $Player/SwordThrower.attack_range,
		"protection_duration": $Player.invulnerability_duration,
		"auto": $Player/SwordThrower.auto_aim, "kills": defeated_count,
	}
	if managed_run:
		GameSession.save_checkpoint(checkpoint)

func toggle_pause() -> void:
	if game_over or game_cleared or round_cleared or final_battle_pending or transitioning or $Progression.pending_choices > 0:
		return
	menu_paused = not menu_paused
	$HUD/Pause.visible = menu_paused
	get_tree().paused = menu_paused
	if menu_paused:
		$HUD/Pause/Resume.grab_focus()

func continue_round() -> void:
	if not game_over or transitioning or checkpoint.is_empty():
		return
	transitioning = true
	call_deferred("_restore_checkpoint")

func _restore_checkpoint() -> void:
	if has_node("EnemySpawner"):
		$EnemySpawner.free()
	for group in ["enemies", "thrown_swords", "boss_projectiles"]:
		for actor in get_tree().get_nodes_in_group(group):
			actor.free()
	round_number = checkpoint.round
	$ExplorationMap.load_layout(checkpoint.forest)
	$Player.position = $ExplorationMap.start_position
	$Player.hp = checkpoint.hp
	$Player.max_hp = checkpoint.max_hp
	$Player.move_speed = checkpoint.speed
	$Player.dead = false
	$Player.velocity = Vector2.ZERO
	$Player.walk_time = 0
	$Player.facing = Vector2.DOWN
	$Player.invulnerability_duration = checkpoint.protection_duration
	$Player.invulnerability_left = 0
	$Player.hit_flash = 0
	$Player.modulate = Color.WHITE
	$Player.self_modulate = Color.WHITE
	$Player/SwordThrower.attack_damage = checkpoint.damage
	$Player/SwordThrower.attack_interval = checkpoint.interval
	$Player/SwordThrower.auto_aim = checkpoint.auto
	$Player/SwordThrower.cooldown = 0
	$Player/SwordThrower.projectile_speed = checkpoint.projectile_speed
	$Player/SwordThrower.attack_range = checkpoint.range
	$Progression.level = checkpoint.level
	$Progression.exp = checkpoint.exp
	$Progression.ability_levels.assign(checkpoint.abilities)
	$Progression.pending_choices = 0
	defeated_count = checkpoint.kills
	game_over = false
	round_cleared = false
	final_battle_pending = false
	boss_active = false
	boss_defeated = false
	game_cleared = false
	menu_paused = false
	for menu in ["GameOver", "GameClear", "RoundClear", "LevelUp", "Pause"]:
		get_node("HUD/" + menu).hide()
	$HUD.restarting = false
	$Feedback.clear_popups()
	$Feedback.flash_left = 0
	$HUD/HurtFlash.color.a = 0
	_setup_objective()
	get_tree().paused = false
	_create_spawner()
	transitioning = false
	_update_hud()

func _create_spawner() -> void:
	if not enemies_enabled:
		return
	var spawner := preload("res://scripts/enemy_spawner.gd").new()
	spawner.name = "EnemySpawner"
	spawner.player = $Player
	spawner.map = $ExplorationMap
	spawner.enemy_defeated.connect(_on_enemy_defeated)
	add_child(spawner)

func _process(_delta: float) -> void:
	_update_hud()

func _update_hud() -> void:
	$HUD/BossPractice.visible = debug_tools_allowed()
	$HUD/PauseButton.offset_left = 420 if debug_tools_allowed() else 500
	$HUD/PauseButton.offset_right = 492 if debug_tools_allowed() else 628
	$HUD/PauseButton.disabled = game_over or game_cleared or round_cleared or $Progression.pending_choices > 0
	$HUD/Abilities.text = "POWER Lv%d  |  QUICK THROW Lv%d  |  SWIFT FEET Lv%d" % $Progression.ability_levels
	var mode := "AUTO" if $Player/SwordThrower.auto_aim else "MOUSE"
	$HUD/Controls.text = "WASD / Arrows: move | Space / LMB: throw | Tab: %s | Kills: %d | M: SFX %s" % [mode, defeated_count, "OFF" if $Feedback.muted else "ON"]
	$HUD/Round.text = "ROUND %d / %d  |  %s" % [round_number, TOTAL_ROUNDS, $ExplorationMap.map_title]
	$HUD/Health.text = "HP " + str($Player.hp) + " / " + str($Player.max_hp)
	$HUD/HealthBar.max_value = $Player.max_hp
	$HUD/HealthBar.value = $Player.hp
	$HUD/Protection.text = "INVULNERABLE" if $Player.invulnerability_left > 0 and not $Player.dead else ""
	$HUD/Experience.text = "Lv " + str($Progression.level) + "   EXP " + str($Progression.exp) + " / " + str($Progression.required_exp())
	$HUD/ExperienceBar.max_value = $Progression.required_exp()
	$HUD/ExperienceBar.value = $Progression.exp
	$HUD/ObjectiveHint.text = "Find the jade magatama" if not round_cleared else "Magatama found! +%d EXP" % round_bonus_exp
	if shrines_enabled:
		$HUD/ObjectiveHint.text = "Shrines %d/3 | %s" % [$Shrines.visited_count, "Jade released" if $Shrines.visited_count == 3 else "Pray at entrances"]
	if final_battle_pending:
		$HUD/ObjectiveHint.text = "Final battle pending"
	if boss_active:
		$HUD/ObjectiveHint.text = "Defeat the final boss"
	if game_cleared:
		$HUD/ObjectiveHint.text = "GAME CLEAR"
	$HUD/BossStatus.visible = boss_active and has_node("FinalBoss") and not game_over
	if $HUD/BossStatus.visible:
		$HUD/BossStatus/Health.max_value = $FinalBoss.max_hp
		$HUD/BossStatus/Health.value = $FinalBoss.hp
		$HUD/BossStatus/Name.text = "BRONZE GUARDIAN  %d / %d" % [$FinalBoss.hp, $FinalBoss.max_hp]
		if debug_tools_allowed():
			$HUD/BossStatus/Name.text += "  |  " + $FinalBoss.attack_hint()
	_update_game_view()

func _update_game_view() -> void:
	# The opaque header masks only the space above the map's visible top edge.
	# Center the player in the remaining area, and clamp that area's map edges.
	var header_height := 140 if $HUD/BossStatus.visible else 100
	$HUD/Panel.offset_bottom = header_height
	var camera: Camera2D = $Player/Camera2D
	camera.offset = Vector2(0, -header_height / 2.0)
	# Camera offset is applied after Godot's limit clamp, so compensate both ends.
	camera.limit_top = -header_height / 2
	camera.limit_bottom = 1152 + header_height / 2
	camera.force_update_scroll()

func _setup_objective() -> void:
	$Objective.lock()
	if shrines_enabled:
		if not $Shrines.setup($ExplorationMap, $Player):
			push_error("Could not place three reachable shrines.")
			return
	elif objective_enabled:
		_release_objective()

func _on_shrine_progress(count: int) -> void:
	if game_over or round_cleared or final_battle_pending or boss_active or game_cleared:
		return
	$Feedback.play_cue("select")
	$Feedback.announce("Shrine visited  %d/3" % count)
	if count == 3 and objective_enabled:
		_release_objective()
		$Feedback.announce("All shrines visited - magatama released!")
	_update_hud()

func _release_objective() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if not $Objective.place($ExplorationMap, $Player, rng):
		push_error("No reachable objective placement found.")

func _on_enemy_defeated(amount: int) -> void:
	if game_over or $Player.dead or round_cleared or final_battle_pending or game_cleared:
		return
	defeated_count += 1
	$Feedback.play_cue("defeat")
	$Feedback.announce("Enemy defeated  +%d EXP" % amount)
	$Progression.add_exp(amount)

func _on_progression_changed() -> void:
	_update_hud()
	if $Progression.pending_choices > 0 and not game_over and not game_cleared:
		$Feedback.play_cue("level")
		get_tree().paused = true
		_present_upgrades()

func _present_upgrades() -> void:
	var thrower := $Player/SwordThrower
	var descriptions: Array[String] = [
		"1  POWER\nLv%d > Lv%d\nDamage %d > %d" % [$Progression.ability_levels[0], $Progression.ability_levels[0] + 1, thrower.attack_damage, thrower.attack_damage + 5],
		"2  QUICK THROW\nLv%d > Lv%d\nInterval %.2fs > %.2fs" % [$Progression.ability_levels[1], $Progression.ability_levels[1] + 1, thrower.attack_interval, thrower.attack_interval * 0.85],
		"3  SWIFT FEET\nLv%d > Lv%d\nSpeed %d > %d px/s" % [$Progression.ability_levels[2], $Progression.ability_levels[2] + 1, $Player.move_speed, $Player.move_speed + 10.0],
	]
	$HUD/LevelUp.present($Progression.level - $Progression.pending_choices + 1, $Progression.pending_choices, descriptions)

func _on_upgrade_selected(index: int) -> void:
	if game_over or game_cleared or $Player.dead or $Progression.pending_choices <= 0 or index < 0 or index > 2:
		return
	match index:
		0: $Player/SwordThrower.attack_damage += 5
		1:
			$Player/SwordThrower.attack_interval *= 0.85
			$Player/SwordThrower.cooldown = minf($Player/SwordThrower.cooldown, $Player/SwordThrower.attack_interval)
		2: $Player.move_speed += 10.0
	$Progression.ability_levels[index] += 1
	$Progression.pending_choices -= 1
	$Feedback.play_cue("select")
	$Feedback.announce("Upgrade applied")
	_update_hud()
	if $Progression.pending_choices > 0:
		_present_upgrades()
	else:
		$HUD/LevelUp.hide()
		if round_cleared:
			_show_round_clear()
		else:
			get_tree().paused = false

func _on_objective_collected() -> void:
	if game_over or $Player.dead or round_cleared or final_battle_pending or boss_active or game_cleared or get_tree().paused:
		return
	if shrines_enabled and $Shrines.visited_count != 3:
		return
	if round_number == TOTAL_ROUNDS:
		final_battle_pending = true
		final_battle_requested.emit()
		if boss_enabled:
			_start_final_battle()
			return
		get_tree().paused = true
		$HUD/RoundClear/Next.hide()
		$HUD/RoundClear/Message.text = "FINAL BATTLE\nBoss encounter is not implemented yet.\n\nR: Restart run"
		$HUD/RoundClear.show()
		_update_hud()
		return
	round_cleared = true
	$Feedback.play_cue("clear")
	get_tree().paused = true
	$HUD/RoundClear/Message.text = "ROUND %d CLEAR\nMagatama found! +%d EXP\n\nN: Next round   |   R: Restart run" % [round_number, round_bonus_exp]
	$Progression.add_exp(round_bonus_exp)
	_update_hud()
	if $Progression.pending_choices == 0:
		_show_round_clear()

func _start_final_battle() -> void:
	if game_over or $Player.dead or game_cleared or boss_active or round_number != TOTAL_ROUNDS:
		return
	var spawn := _boss_spawn_position()
	if spawn == Vector2.INF:
		push_error("No reachable final boss placement found.")
		return
	var boss: CharacterBody2D = preload("res://scenes/final_boss.tscn").instantiate()
	boss.position = spawn
	boss.player = $Player
	boss.map = $ExplorationMap
	boss.debug_hints_enabled = debug_tools_allowed()
	boss.defeated.connect(_on_boss_defeated)
	add_child(boss)
	final_battle_pending = false
	boss_active = true
	$HUD/RoundClear.hide()
	$HUD/RoundClear/Next.hide()
	$Feedback.play_cue("clear")
	$Feedback.announce("Final boss appeared - defeat the Bronze Guardian!")
	_update_hud()

func _boss_spawn_position() -> Vector2:
	# Prefer a nearby visible position, with a full-grid reachable fallback.
	for radius in [160, 192, 224, 128]:
		for index in range(16):
			var candidate: Vector2 = (($Player.position + Vector2.from_angle(index * TAU / 16) * radius) / 16).floor() * 16 + Vector2(8, 8)
			if _valid_boss_spawn(candidate):
				return candidate
	for y in range(24, 1128, 16):
		for x in range(24, 1512, 16):
			var candidate := Vector2(x, y)
			if _valid_boss_spawn(candidate):
				return candidate
	return Vector2.INF

func _valid_boss_spawn(point: Vector2) -> bool:
	if point.distance_to($Player.position) < 112 or not $ExplorationMap.is_clear(point) or $ExplorationMap.is_behind_scenery(point, Rect2(-18, -36, 38, 42)):
		return false
	if $ExplorationMap.route(point, $Player.position).is_empty():
		return false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.position.distance_to(point) < 32:
			return false
	return true

func _on_boss_defeated(_amount: int) -> void:
	boss_defeated = true
	call_deferred("_finish_game")

func _finish_game() -> void:
	# Defer the decision until this frame's lethal player damage has been resolved.
	if game_over or $Player.dead or game_cleared or not boss_active or not boss_defeated:
		return
	game_cleared = true
	boss_active = false
	final_battle_pending = false
	round_cleared = false
	$HUD/LevelUp.hide()
	$Progression.pending_choices = 0
	$HUD/RoundClear.hide()
	$HUD/GameOver.hide()
	$HUD/GameClear.show()
	$Feedback.play_cue("clear")
	$Feedback.announce("The Bronze Guardian is defeated!")
	get_tree().paused = true
	_update_hud()
	print("GAME CLEAR: final boss defeated; gameplay paused.")

func _show_round_clear() -> void:
	if managed_run:
		$HUD/RoundClear/Message.text = $HUD/RoundClear/Message.text.replace("Restart run", "Title")
	if game_over or $Player.dead:
		return
	$HUD/RoundClear.show()
	get_tree().paused = true
	print("ROUND CLEAR: bonus EXP choices complete; next round available.")

func advance_round() -> void:
	if transitioning or game_over or $Player.dead or not round_cleared or final_battle_pending or round_number >= TOTAL_ROUNDS or $Progression.pending_choices > 0:
		return
	transitioning = true
	call_deferred("_begin_next_round")

func _begin_next_round() -> void:
	if game_over or $Player.dead or round_number >= TOTAL_ROUNDS:
		transitioning = false
		return
	# Explicitly remove old actors before rebuilding the collision/navigation map.
	if has_node("EnemySpawner"):
		$EnemySpawner.free()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.free()
	for sword in get_tree().get_nodes_in_group("thrown_swords"):
		sword.free()
	for arrow in get_tree().get_nodes_in_group("boss_projectiles"):
		arrow.free()
	round_number += 1
	$Feedback.clear_popups()
	$ExplorationMap.load_layout(round_number % 2 == 0)
	$Player.position = $ExplorationMap.start_position
	$Player.velocity = Vector2.ZERO
	$Player.walk_time = 0.0
	$Player.modulate.a = 1.0
	_setup_objective()
	round_cleared = false
	$HUD/RoundClear.hide()
	get_tree().paused = false
	_create_spawner()
	transitioning = false
	_update_hud()
	$Feedback.announce("Round %d  -  %s" % [round_number, $ExplorationMap.map_title])
	_capture_checkpoint()

func _on_health_changed(_hp: int, _maximum: int) -> void:
	$Feedback.hurt()
	_update_hud()

func _on_player_died() -> void:
	if game_over or game_cleared:
		return
	game_over = true
	final_battle_pending = false
	boss_active = false
	$HUD/GameClear.hide()
	$Feedback.play_cue("game_over")
	round_cleared = false
	$HUD/RoundClear.hide()
	$HUD/LevelUp.hide()
	$Progression.pending_choices = 0
	_update_hud()
	$HUD/GameOver.visible = true
	get_tree().paused = true
	print("GAME OVER: gameplay paused.")
