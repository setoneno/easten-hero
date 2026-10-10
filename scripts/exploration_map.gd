extends Node2D
## Fixed original pixel field; obstacle rectangles also create physics bodies.
const SIZE := Vector2(1536, 1152)
const RIVER_X := 992.0
const BRIDGE_Y := 544.0
const CELL := 16
const BEHIND_ALPHA := 0.45
var navigation := AStarGrid2D.new()
var obstacle_rects: Array[Rect2] = []
var occluders: Array[Dictionary] = []
var trees: Array[Vector2] = [Vector2(320, 288), Vector2(352, 320), Vector2(640, 256), Vector2(768, 320), Vector2(256, 576), Vector2(288, 608), Vector2(672, 704), Vector2(736, 736), Vector2(1152, 352), Vector2(1248, 384), Vector2(1280, 800), Vector2(416, 832), Vector2(448, 864), Vector2(864, 880)]
var rocks: Array[Vector2] = [Vector2(576, 384), Vector2(704, 448), Vector2(1200, 720)]
var forest := false
var shrine_position := Vector2(1168, 176)
var gate_position := Vector2(1168, 282)
var start_position := Vector2(480, 384)
var map_title := "Riverside"
var riverside_trees: Array[Vector2]
var riverside_rocks: Array[Vector2]

func _ready() -> void:
	riverside_trees = trees.duplicate()
	riverside_rocks = rocks.duplicate()
	load_layout(false)

func load_layout(use_forest: bool) -> void:
	for wall in get_children():
		wall.free()
	obstacle_rects.clear()
	occluders.clear()
	forest = use_forest
	trees = riverside_trees.duplicate()
	rocks = riverside_rocks.duplicate()
	shrine_position = Vector2(896, 720) if forest else Vector2(1168, 176)
	gate_position = shrine_position + Vector2(0, 106)
	start_position = Vector2(256, 256) if forest else Vector2(480, 384)
	map_title = "Shrine Forest" if forest else "Riverside"
	if forest:
		trees.clear()
		for y in [192, 400, 656, 912]:
			for x in [128, 384, 576, 768, 1088, 1376]:
				trees.append(Vector2(x, y))
				trees.append(Vector2(x + 32, y + 32))
		rocks = [Vector2(448, 544), Vector2(704, 848), Vector2(1200, 464), Vector2(1024, 944)]
	for point in trees:
		_add_wall(Rect2(point + Vector2(-10, -6), Vector2(20, 14)))
	for point in rocks:
		_add_wall(Rect2(point + Vector2(-14, -10), Vector2(28, 20)))
	if not forest:
		_add_wall(Rect2(RIVER_X, 0, 64, BRIDGE_Y))
		_add_wall(Rect2(RIVER_X, BRIDGE_Y + 64, 64, SIZE.y - BRIDGE_Y - 64))
	_add_wall(Rect2(shrine_position, Vector2(96, 72)))
	_add_wall(Rect2(-32, -32, SIZE.x + 64, 32))
	_add_wall(Rect2(-32, SIZE.y, SIZE.x + 64, 32))
	_add_wall(Rect2(-32, 0, 32, SIZE.y))
	_add_wall(Rect2(SIZE.x, 0, 32, SIZE.y))
	_build_navigation()
	_build_occluders()
	queue_redraw()

func _process(delta: float) -> void:
	for character in get_tree().get_nodes_in_group("field_characters"):
		var feet := to_local(character.global_position)
		var bounds: Rect2 = character.occlusion_bounds() if character.has_method("occlusion_bounds") else Rect2(-10, -22, 24, 26)
		var alpha := BEHIND_ALPHA if is_behind_scenery(feet, bounds) else 1.0
		character.modulate.a = move_toward(character.modulate.a, alpha, delta * 6.0)

func is_behind_scenery(feet: Vector2, bounds: Rect2 = Rect2(-10, -22, 24, 26)) -> bool:
	var figure := Rect2(feet + bounds.position, bounds.size)
	for occluder in occluders:
		if feet.y < occluder.front_y and figure.intersects(occluder.rect):
			return true
	return false

func register_occluder(rect: Rect2, front_y: float) -> void:
	# New scenery must register the portions that can cover a character.
	occluders.append({"rect": rect, "front_y": front_y})

func _build_occluders() -> void:
	for point in trees:
		for canopy in [Rect2(-14, -34, 28, 22), Rect2(-20, -28, 40, 10),
			Rect2(-10, -46, 20, 34), Rect2(-16, -38, 32, 18), Rect2(-5, -22, 10, 26)]:
			register_occluder(Rect2(point + canopy.position, canopy.size), point.y)
	for timber in [Rect2(0, 0, 96, 8), Rect2(10, 16, 76, 4),
		Rect2(6, 6, 6, 38), Rect2(84, 6, 6, 38)]:
		register_occluder(Rect2(gate_position + timber.position, timber.size), gate_position.y + 44)
	var building := shrine_position
	register_occluder(Rect2(building, Vector2(96, 72)), building.y + 72)
	for row in range(7):
		register_occluder(Rect2(building + Vector2(-8 + row * 4, -8 - row * 4),
			Vector2(112 - row * 8, 4)), building.y + 72)
	register_occluder(Rect2(building + Vector2(24, -40), Vector2(48, 6)), building.y + 72)
	for point in rocks:
		register_occluder(Rect2(point + Vector2(-14, -6), Vector2(28, 16)), point.y)
		register_occluder(Rect2(point + Vector2(-10, -10), Vector2(20, 16)), point.y)

func _add_wall(rect: Rect2) -> void:
	obstacle_rects.append(rect)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.position = rect.get_center()
	body.add_child(collision)
	add_child(body)

func _build_navigation() -> void:
	navigation.region = Rect2i(0, 0, int(SIZE.x) / CELL, int(SIZE.y) / CELL)
	navigation.cell_size = Vector2(CELL, CELL)
	navigation.offset = Vector2(8, 8)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for y in range(navigation.region.size.y):
		for x in range(navigation.region.size.x):
			var cell := Vector2i(x, y)
			if not is_clear(navigation.get_point_position(cell)):
				navigation.set_point_solid(cell)

func is_clear(point: Vector2) -> bool:
	for rect in obstacle_rects:
		if rect.grow(8).has_point(point):
			return false
	return Rect2(Vector2(8, 8), SIZE - Vector2(16, 16)).has_point(point)

func _nearest_cell(point: Vector2) -> Vector2i:
	var center := Vector2i(floori(point.x / CELL), floori(point.y / CELL))
	for radius in range(6):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var cell := center + Vector2i(x, y)
				if navigation.is_in_boundsv(cell) and not navigation.is_point_solid(cell):
					return cell
	return Vector2i(-1, -1)

func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start := _nearest_cell(from)
	var end := _nearest_cell(to)
	if start.x < 0 or end.x < 0:
		return PackedVector2Array()
	return navigation.get_point_path(start, end)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("435b3b") if forest else Color("617548"))
	for y in range(0, int(SIZE.y), 16):
		for x in range(0, int(SIZE.x), 16):
			var n := (x * 13 + y * 7) % 37
			draw_rect(Rect2(x + n % 12, y + n % 10, 2, 3), Color("57734b") if forest else Color("718553"))
			draw_rect(Rect2(x + 6, y + 12, 3, 1), Color("536740"))
	if forest:
		_path(Rect2(224, 128, 64, 896))
		_path(Rect2(224, 544, 1088, 64))
		_path(Rect2(912, 544, 64, 400))
	else:
		_draw_riverside()
	for point in trees:
		_tree(point)
	for point in rocks:
		_rock(point)
	_shrine(shrine_position)
	draw_rect(Rect2(gate_position + Vector2(6, 6), Vector2(6, 38)), Color("82513d"))
	draw_rect(Rect2(gate_position + Vector2(84, 6), Vector2(6, 38)), Color("82513d"))
	draw_rect(Rect2(gate_position, Vector2(96, 8)), Color("a46749"))
	draw_rect(Rect2(gate_position + Vector2(10, 16), Vector2(76, 4)), Color("ba9568"))
	for x in range(0, int(SIZE.x), 16):
		draw_rect(Rect2(x, 0, 14, 4), Color("8d9277"))
		draw_rect(Rect2(x, SIZE.y - 4, 14, 4), Color("8d9277"))
	for y in range(0, int(SIZE.y), 16):
		draw_rect(Rect2(0, y, 4, 14), Color("8d9277"))
		draw_rect(Rect2(SIZE.x - 4, y, 4, 14), Color("8d9277"))

func _draw_riverside() -> void:
	_path(Rect2(440, 128, 64, 832))
	_path(Rect2(240, 544, 1088, 64))
	_path(Rect2(1184, 248, 64, 360))
	draw_rect(Rect2(RIVER_X - 4, 0, 72, SIZE.y), Color("b0a078"))
	draw_rect(Rect2(RIVER_X, 0, 64, SIZE.y), Color("476f81"))
	for y in range(0, int(SIZE.y), 16):
		draw_rect(Rect2(RIVER_X + (y % 3) * 12 + 6, y, 22, 2), Color("80a6aa"))
	for y in range(int(BRIDGE_Y), int(BRIDGE_Y + 64), 8):
		draw_rect(Rect2(RIVER_X - 8, y, 80, 7), Color("ad8b59"))
	draw_rect(Rect2(RIVER_X - 8, BRIDGE_Y, 80, 4), Color("634e39"))
	draw_rect(Rect2(RIVER_X - 8, BRIDGE_Y + 60, 80, 4), Color("634e39"))

func _path(rect: Rect2) -> void:
	draw_rect(rect, Color("aa9568"))
	for y in range(int(rect.position.y), int(rect.end.y), 8):
		for x in range(int(rect.position.x), int(rect.end.x), 16):
			draw_rect(Rect2(x + 3, y + 3, 3, 1), Color("8e7e58"))

func _tree(point: Vector2) -> void:
	draw_rect(Rect2(point + Vector2(-18, -1), Vector2(36, 8)), Color("475839"))
	draw_rect(Rect2(point + Vector2(-5, -22), Vector2(10, 26)), Color("70513b"))
	# Stepped canopy silhouette and small leaf clusters.
	draw_rect(Rect2(point + Vector2(-14, -34), Vector2(28, 22)), Color("344f3c"))
	draw_rect(Rect2(point + Vector2(-20, -28), Vector2(40, 10)), Color("344f3c"))
	draw_rect(Rect2(point + Vector2(-10, -46), Vector2(20, 34)), Color("426449"))
	draw_rect(Rect2(point + Vector2(-16, -38), Vector2(32, 18)), Color("426449"))
	draw_rect(Rect2(point + Vector2(-8, -44), Vector2(14, 8)), Color("638057"))
	draw_rect(Rect2(point + Vector2(-16, -28), Vector2(10, 6)), Color("53734d"))
	draw_rect(Rect2(point + Vector2(8, -20), Vector2(8, 4)), Color("283f34"))
	for leaf in [Vector2(-6, -34), Vector2(4, -38), Vector2(8, -28), Vector2(-10, -22)]:
		draw_rect(Rect2(point + leaf, Vector2(4, 2)), Color("739060"))

func _rock(point: Vector2) -> void:
	draw_rect(Rect2(point + Vector2(-14, -6), Vector2(28, 16)), Color("555e57"))
	draw_rect(Rect2(point + Vector2(-10, -10), Vector2(20, 16)), Color("8a9181"))
	draw_rect(Rect2(point + Vector2(-8, -8), Vector2(12, 4)), Color("b0b3a0"))
	draw_rect(Rect2(point + Vector2(4, 2), Vector2(8, 4)), Color("6c7960"))

func _shrine(point: Vector2) -> void:
	draw_rect(Rect2(point, Vector2(96, 72)), Color("64513d"))
	draw_rect(Rect2(point + Vector2(8, 8), Vector2(80, 52)), Color("b49a6a"))
	for x in range(12, 88, 8):
		draw_rect(Rect2(point + Vector2(x, 8), Vector2(2, 48)), Color("88734f"))
	draw_rect(Rect2(point + Vector2(36, 32), Vector2(24, 30)), Color("3b3c32"))
	for row in range(7):
		draw_rect(Rect2(point + Vector2(-8 + row * 4, -8 - row * 4), Vector2(112 - row * 8, 4)), Color("84714c") if row % 2 == 0 else Color("a18b59"))
	draw_rect(Rect2(point + Vector2(24, -40), Vector2(48, 6)), Color("554a36"))
	draw_rect(Rect2(point + Vector2(28, 64), Vector2(40, 6)), Color("a8aa91"))
