extends Node
## Only title-started runs write saves; isolated gameplay tests remain independent.
var save_path := "user://checkpoint.json"
var checkpoint: Dictionary = {}
var starting_checkpoint: Dictionary = {}
var managed_run := false
var switching := false

func load_checkpoint() -> void:
	checkpoint = {}
	if not FileAccess.file_exists(save_path):
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(save_path)) != OK:
		return
	var data: Variant = json.data
	if data is Dictionary and data.get("version") == 1 and valid_checkpoint(data.get("checkpoint")):
		checkpoint = data.checkpoint.duplicate(true)

func valid_checkpoint(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for key in ["round", "level", "exp", "hp", "max_hp", "speed", "damage", "interval", "projectile_speed", "range", "protection_duration", "kills"]:
		if not value.has(key) or not (value[key] is int or value[key] is float) or not is_finite(float(value[key])):
			return false
	if not value.get("forest") is bool or not value.get("auto") is bool or not value.get("abilities") is Array or value.abilities.size() != 3:
		return false
	for level in value.abilities:
		if not (level is int or level is float) or level < 1 or level > 100000 or level != int(level):
			return false
	for key in ["round", "level", "exp", "hp", "max_hp", "damage", "kills"]:
		if value[key] != int(value[key]):
			return false
	return (
		value.round >= 1 and value.round <= 5
		and value.forest == (int(value.round) % 2 == 0)
		and value.level >= 1 and value.level <= 100000
		and value.exp >= 0 and value.exp < 30 + (value.level - 1) * 10
		and value.hp > 0 and value.hp <= value.max_hp and value.max_hp <= 100000
		and value.speed > 0 and value.speed <= 100000
		and value.damage > 0 and value.damage <= 100000
		and value.interval > 0 and value.interval <= 100
		and value.projectile_speed > 0 and value.range > 0
		and value.protection_duration >= 0 and value.kills >= 0
	)

func save_checkpoint(value: Dictionary) -> void:
	checkpoint = value.duplicate(true)
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		push_error("Could not save checkpoint.")
		return
	file.store_string(JSON.stringify({"version": 1, "checkpoint": checkpoint}))
	file.close()
	if DirAccess.rename_absolute(save_path + ".tmp", save_path) != OK:
		push_error("Could not replace checkpoint save.")

func new_game() -> void:
	if switching:
		return
	checkpoint = {}
	starting_checkpoint = {}
	managed_run = true
	_switch("res://scenes/main.tscn")

func continue_game() -> void:
	if switching or checkpoint.is_empty():
		return
	starting_checkpoint = checkpoint.duplicate(true)
	managed_run = true
	_switch("res://scenes/main.tscn")

func show_title() -> void:
	if switching:
		return
	managed_run = false
	starting_checkpoint = {}
	_switch("res://scenes/title.tscn")

func _switch(path: String) -> void:
	switching = true
	call_deferred("_change_scene", path)

func _change_scene(path: String) -> void:
	get_tree().paused = false
	var result := get_tree().change_scene_to_file(path)
	if result != OK:
		push_error("Could not change scene: " + str(result))
	call_deferred("_unlock")

func _unlock() -> void:
	switching = false

func exit_game() -> void:
	get_tree().quit()
