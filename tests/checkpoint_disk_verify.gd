extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://release-disk-test.json"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and args[0] == "write":
		var world: Node2D = load("res://scenes/main.tscn").instantiate()
		world.enemies_enabled = false
		root.add_child(world)
		var checkpoint: Dictionary = world.checkpoint.duplicate(true)
		checkpoint.round = 3
		checkpoint.hp = 70
		checkpoint.level = 4
		checkpoint.exp = 17
		checkpoint.abilities = [2, 2, 2]
		session.save_checkpoint(checkpoint)
		world.queue_free()
		await process_frame
		print("DISK_VERIFY_WRITE: PASS")
		quit()
		return
	session.load_checkpoint()
	if session.checkpoint.is_empty():
		push_error("DISK_VERIFY_READ: missing saved checkpoint")
		quit(1)
		return
	session.continue_game()
	for index in range(5):
		await process_frame
	var world: Node2D = current_scene
	var passed: bool = world.round_number == 3 and world.get_node("Player").hp == 70 and world.get_node("Progression").level == 4 and world.get_node("Progression").exp == 17 and world.get_node("Progression").ability_levels == [2, 2, 2] and world.get_node("Shrines").visited_count == 0
	world.queue_free()
	await process_frame
	DirAccess.remove_absolute(session.save_path)
	print("DISK_VERIFY_READ: ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)
