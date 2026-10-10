extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	root.get_node("GameSession").save_path = "user://exit-test-unused.json"
	var args := OS.get_cmdline_user_args()
	var menu: String = args[0] if not args.is_empty() else "Title"
	if menu == "Title":
		change_scene_to_file("res://scenes/title.tscn")
	else:
		change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	var exit_button: Button
	if menu == "Title":
		exit_button = current_scene.get_node("Exit")
	else:
		current_scene.get_node("HUD/" + menu).show()
		paused = true
		exit_button = current_scene.get_node("HUD/" + menu + "/Exit")
	create_timer(0.3).timeout.connect(func() -> void:
		push_error("EXIT_VERIFY: FAIL - exit did not terminate")
		quit(1)
	)
	print("EXIT_VERIFY: invoking ", menu, " EXIT")
	exit_button.pressed.emit()
