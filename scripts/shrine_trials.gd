extends Node2D
signal progress_changed(count: int)
const SHRINE := preload("res://scripts/prayer_shrine.gd")
var visited_count := 0

func setup(map: Node2D, player: CharacterBody2D) -> bool:
	for shrine in get_children():
		shrine.free()
	visited_count = 0
	# The existing large shrine is one of the three; add two smaller wayside shrines.
	var existing := SHRINE.new()
	existing.draw_building = false
	existing.position = map.shrine_position
	existing.prayer_point = Vector2(48, 94)
	_add_shrine(existing, player)
	for target in [Vector2(320, 480), Vector2(800, 960)]:
		var found := false
		for radius in range(0, 240, 16):
			for offset in [Vector2(radius, 0), Vector2(-radius, 0), Vector2(0, radius), Vector2(0, -radius)]:
				var point: Vector2 = target + offset
				var footprint := Rect2(point + Vector2(-24, -40), Vector2(48, 72))
				var blocked := false
				for obstacle in map.obstacle_rects:
					blocked = blocked or footprint.intersects(obstacle.grow(8))
				if blocked or not map.is_clear(point) or map.route(player.position, point + Vector2(0, 24)).is_empty():
					continue
				var shrine := SHRINE.new()
				shrine.position = point
				shrine.prayer_point = Vector2(0, 24)
				map._add_wall(Rect2(point + Vector2(-16, -16), Vector2(32, 20)))
				map.register_occluder(Rect2(point + Vector2(-20, -32), Vector2(40, 36)), point.y + 4)
				_add_shrine(shrine, player)
				found = true
				break
			if found:
				break
		if not found:
			return false
	map._build_navigation()
	for shrine in get_children():
		if not map.is_clear(shrine.position + shrine.prayer_point) or map.route(player.position, shrine.position + shrine.prayer_point).is_empty():
			return false
	return true

func _add_shrine(shrine: Node2D, player: CharacterBody2D) -> void:
	shrine.player = player
	shrine.prayed.connect(_on_prayed)
	add_child(shrine)

func _on_prayed() -> void:
	visited_count += 1
	progress_changed.emit(visited_count)
