extends CanvasLayer
signal next_round_requested
## HUD keeps input processing during the frozen defeat scene.
var restarting := false

func _ready() -> void:
	var layout := preload("res://scripts/menu_layout.gd")
	layout.style_button($PauseButton)
	layout.populate($GameOver, "GAME OVER", ["CONTINUE", "TITLE", "EXIT"])
	layout.populate($GameClear, "GAME CLEAR", ["NEW GAME", "TITLE", "EXIT"])
	var pause_menu := Control.new()
	pause_menu.name = "Pause"
	pause_menu.hide()
	add_child(pause_menu)
	layout.populate(pause_menu, "PAUSED", ["RESUME", "TITLE", "EXIT"])
	$Pause/Resume.pressed.connect(func() -> void: get_parent().toggle_pause())
	$PauseButton.pressed.connect(func() -> void: get_parent().toggle_pause())
	$GameClear/NewGame.pressed.connect(_request_new_game)
	for menu in [$GameOver, $GameClear, $Pause]:
		menu.get_node("Title").pressed.connect(GameSession.show_title)
		menu.get_node("Exit").pressed.connect(GameSession.exit_game)
	$RoundClear/Next.pressed.connect(func() -> void: next_round_requested.emit())
	$BossPractice.pressed.connect(_request_boss_practice)
	$GameOver/Continue.pressed.connect(func() -> void:
		if not restarting:
			restarting = true
			call_deferred("_restart")
	)
	# Square borders and subdued cloth/wood colors match the field palette.
	for button in [$GameOver/Continue, $BossPractice, $RoundClear/Next, $LevelUp/Choice1, $LevelUp/Choice2, $LevelUp/Choice3]:
		for state in ["normal", "hover", "pressed", "disabled"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("304536") if state == "hover" else Color("202f26")
			style.border_color = Color("d6b876") if state != "disabled" else Color("52604c")
			style.set_border_width_all(2)
			button.add_theme_stylebox_override(state, style)
		button.add_theme_color_override("font_color", Color("eee0b4"))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		get_parent().toggle_pause()
		return
	if get_parent().debug_tools_allowed() and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_B and not restarting:
		get_viewport().set_input_as_handled()
		_request_boss_practice()
		return
	if $RoundClear.visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_N:
		get_viewport().set_input_as_handled()
		next_round_requested.emit()
		return
	if ($GameOver.visible or $RoundClear.visible or $GameClear.visible) and event.is_action_pressed("restart_game") and not event.is_echo() and not restarting:
		restarting = true
		get_viewport().set_input_as_handled()
		call_deferred("_restart")

func _restart() -> void:
	if $GameOver.visible and not get_parent().get_script().resource_path.ends_with("boss_test.gd"):
		get_parent().continue_round()
		return
	if get_parent().managed_run:
		if $GameClear.visible:
			GameSession.new_game()
		else:
			GameSession.show_title()
		return
	get_tree().paused = false
	var result := get_tree().reload_current_scene()
	if result != OK:
		get_tree().paused = true
		restarting = false
		push_error("Could not restart game: " + str(result))

func _request_boss_practice() -> void:
	if restarting or not get_parent().debug_tools_allowed() or get_parent().menu_paused or get_parent().get_node("Progression").pending_choices > 0:
		return
	restarting = true
	call_deferred("_start_boss_practice")

func _start_boss_practice() -> void:
	GameSession.managed_run = false
	GameSession.starting_checkpoint = {}
	get_tree().paused = false
	var result := get_tree().change_scene_to_file("res://scenes/boss_test.tscn")
	if result != OK:
		restarting = false
		push_error("Could not start boss practice: " + str(result))

func _request_new_game() -> void:
	if restarting:
		return
	restarting = true
	if get_parent().managed_run:
		GameSession.new_game()
	else:
		call_deferred("_restart")
