extends Node2D
## Original jade magatama. Pickup resolves after the physics frame; defeat wins ties.
signal collected
var player: CharacterBody2D
var collected_once := false
var shimmer := 0.0

func lock() -> void:
	hide()
	player = null
	collected_once = false
	set_physics_process(false)

func place(map: Node2D, owner_player: CharacterBody2D, rng: RandomNumberGenerator) -> bool:
	collected_once = false
	shimmer = 0.0
	set_physics_process(true)
	player = owner_player
	var columns := int(map.SIZE.x / map.CELL)
	var rows := int(map.SIZE.y / map.CELL)
	var start := rng.randi_range(0, columns * rows - 1)
	# Complete scan from a random cell guarantees a valid fallback if one exists.
	for offset in range(columns * rows):
		var cell := (start + offset) % (columns * rows)
		var point := Vector2((cell % columns) * map.CELL + 8, (cell / columns) * map.CELL + 8)
		if point.distance_to(player.position) < 240 or not map.is_clear(point):
			continue
		if map.is_behind_scenery(point) or map.route(player.position, point).is_empty():
			continue
		position = point
		show()
		return true
	return false

func _process(delta: float) -> void:
	shimmer += delta
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= 18:
		call_deferred("try_collect")

func try_collect() -> void:
	if not visible or collected_once or not is_instance_valid(player) or player.dead or get_tree().paused:
		return
	if global_position.distance_to(player.global_position) > 18:
		return
	collected_once = true
	hide()
	set_physics_process(false)
	collected.emit()

func _draw() -> void:
	draw_rect(Rect2(-10, 4, 20, 4), Color(0.08, 0.12, 0.1, 0.35))
	var pixels := ["..gggg..", ".gllllg.", "gl..lllg", "gl..lllg", ".glllllg", "..gglllg", "....llg.", "...llg..", "..ggg..."]
	for y in range(pixels.size()):
		for x in range(pixels[y].length()):
			var symbol: String = pixels[y][x]
			if symbol != ".":
				draw_rect(Rect2(x * 2 - 8, y * 2 - 12, 2, 2), Color("b0d5ab") if symbol == "l" else Color("367b65"))
	var bright := Color("f4df88") if int(shimmer * 3) % 2 == 0 else Color("a1b978")
	draw_line(Vector2(-14, -8), Vector2(-8, -8), bright, 2)
	draw_line(Vector2(-11, -11), Vector2(-11, -5), bright, 2)
	draw_rect(Rect2(11, -2, 2, 2), bright)
