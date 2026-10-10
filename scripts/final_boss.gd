extends "res://scripts/enemy.gd"
## Agile guardian: rapid pursuit/flanking, arrow volleys and a naginata fan sweep.
enum State { PURSUIT, ARROWS, SWEEP, RECOVERY }
const ARROW := preload("res://scenes/boss_arrow.tscn")
@export var attack_damage := 30
@export var sweep_radius := 84.0
@export var sweep_angle := 140.0
@export var arrow_damage := 18
@export var arrow_speed := 260.0
@export var flank_speed := 145.0
@export var damage_window := 0.6
var vulnerable_left := 0.0
var guard_flash := 0.0
var debug_hints_enabled := false
var state := State.PURSUIT
var state_time := 0.5
var next_sweep := false
var attack_direction := Vector2.RIGHT
var flank_side := 1.0
var flank_path := PackedVector2Array()
var attacks_started := {"arrows": 0, "sweep": 0}
const ARMOR := {"h": Color("303631"), "g": Color("d4b773"), "s": Color("cfab7c"), "a": Color("69795c"), "r": Color("8b493f"), "b": Color("3e504b")}
const BOSS_FRONT := ["..g......g..", "..gg.hhhgg..", "...gggggg...", "...hhgghh...", "...hssssh...", "....ssss....", "..ggaaaagg..", ".ggaggggagg.", ".saaggggaas.", ".saagaagaas.", "..aaaagaaa..", "..rrrrrrrr..", "..aaggggaa..", "...bbbbbb...", "...b....b...", "...h....h..."]
const BOSS_BACK := ["..g......g..", "..gg.hhhgg..", "...gggggg...", "...hhhhhh...", "...hhhhhh...", "....hhhh....", "..ggaaaagg..", ".ggaggggagg.", ".saaggggaas.", ".saagaagaas.", "..aaaagaaa..", "..rrrrrrrr..", "..aaggggaa..", "...bbbbbb...", "...b....b...", "...h....h..."]
const BOSS_SIDE := ["....g.......", "....gg.h....", "....ggggg...", "....hhggh...", "....hhsss...", ".....hsss...", "....ggaaa...", "....gaggaa..", "....aaasaa..", "....aaasaa..", "....aaaaga..", "....rrrrrr..", "....aaggaa..", "....bbbbbb..", "....b...b...", "....h...h..."]

func _physics_process(delta: float) -> void:
	if dead or get_tree().paused or not is_instance_valid(player) or player.dead:
		return
	state_time -= delta
	vulnerable_left = maxf(0, vulnerable_left - delta)
	match state:
		State.PURSUIT:
			super._physics_process(delta)
			repath_time = minf(repath_time, 0.18)
			if state_time <= 0:
				_prepare_attack()
		State.ARROWS, State.SWEEP:
			if state_time <= 0:
				_recover()
		State.RECOVERY:
			_move_flank(delta)
			if state_time <= 0:
				state = State.PURSUIT
				state_time = 0.45
				repath_time = 0
	queue_redraw()

func _prepare_attack() -> void:
	velocity = Vector2.ZERO
	walk_time = 0
	facing = position.direction_to(player.position)
	attack_direction = facing if facing != Vector2.ZERO else Vector2.DOWN
	if next_sweep and position.distance_to(player.position) <= sweep_radius + 20:
		_sweep()
		state = State.SWEEP
		state_time = 0.18
		next_sweep = false
	else:
		_fire_arrows()
		state = State.ARROWS
		state_time = 0.12
		next_sweep = true

func _fire_arrows() -> void:
	if dead or get_tree().paused or player.dead:
		return
	vulnerable_left = damage_window
	attacks_started.arrows += 1
	for angle in [-12.0, 0.0, 12.0]:
		var arrow: CharacterBody2D = ARROW.instantiate()
		arrow.direction = attack_direction.rotated(deg_to_rad(angle))
		arrow.speed = arrow_speed
		arrow.damage = arrow_damage
		arrow.player = player
		arrow.position = position # Start at the feet so arrows cannot jump over walls.
		get_parent().add_child(arrow)
	get_tree().call_group("game_feedback", "play_cue", "throw")

func _sweep() -> void:
	if dead or get_tree().paused or player.dead:
		return
	vulnerable_left = damage_window
	attacks_started.sweep += 1
	var offset := player.position - position
	if offset.length() > sweep_radius or (offset.length() > 0.01 and attack_direction.dot(offset.normalized()) < cos(deg_to_rad(sweep_angle * 0.5))):
		return
	# The rendered swing matches the hit area. Scenery blocks through-wall hits.
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)
	if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		player.take_damage(attack_damage)

func _recover() -> void:
	state = State.RECOVERY
	state_time = 0.4
	velocity = Vector2.ZERO
	walk_time = 0
	flank_side *= -1
	flank_path.clear()
	var side := (position - player.position).normalized().rotated(flank_side * PI * 0.5)
	for distance in [100.0, 72.0, 48.0]:
		var target: Vector2 = player.position + side * distance
		if map.is_clear(target):
			flank_path = map.route(position, target)
			if flank_path.size() > 1:
				flank_path.remove_at(0)
				break

func _move_flank(delta: float) -> void:
	while not flank_path.is_empty() and position.distance_to(flank_path[0]) < 3:
		flank_path.remove_at(0)
	velocity = position.direction_to(flank_path[0]) * flank_speed if not flank_path.is_empty() else Vector2.ZERO
	if velocity != Vector2.ZERO:
		facing = velocity.normalized()
	var before := position
	move_and_slide()
	walk_time = walk_time + delta if position.distance_to(before) > 0.01 else 0.0

func attack_hint() -> String:
	return "OPEN %.1fs" % vulnerable_left if vulnerable_left > 0 else "GUARD"

func take_damage(amount: int) -> void:
	if dead or get_tree().paused or amount <= 0:
		return
	if vulnerable_left <= 0:
		if guard_flash <= 0 and debug_hints_enabled:
			get_tree().call_group("game_feedback", "burst", global_position, "GUARD", Color("b8cad8"))
		guard_flash = 0.12
		return
	super.take_damage(amount)

func _process(delta: float) -> void:
	super._process(delta)
	guard_flash = maxf(0, guard_flash - delta)
	if hit_flash <= 0:
		self_modulate = Color(0.65, 0.85, 1.3) if guard_flash > 0 else (Color(1.25, 1.15, 0.8) if vulnerable_left > 0 else Color.WHITE)

func occlusion_bounds() -> Rect2:
	return Rect2(-18, -36, 38, 42)

func _draw() -> void:
	if state == State.SWEEP:
		_draw_fan()
	draw_rect(Rect2(-12, 1, 24, 5), Color(0.06, 0.1, 0.08, 0.5))
	var sideways := absf(facing.x) >= absf(facing.y) and facing.x != 0
	var pixels: Array = BOSS_SIDE if sideways else (BOSS_BACK if facing.y < 0 else BOSS_FRONT)
	var phase := int(walk_time * 8) % 4
	for y in range(pixels.size()):
		if sideways and y >= 14:
			continue
		for x in range(pixels[y].length()):
			var symbol: String = pixels[y][x]
			if symbol == ".":
				continue
			var offset := (2 if phase == 1 else (-2 if phase == 3 else 0)) * (1 if x < 6 else -1) if y >= 14 else 0
			var draw_x := 11 - x if sideways and facing.x < 0 else x
			draw_rect(Rect2(draw_x * 2 - 12, y * 2 - 30 + offset, 2, 2), ARMOR[symbol])
	if sideways:
		_draw_side_legs(phase)
	var weapon_x := -16 if sideways and facing.x < 0 else 14
	draw_rect(Rect2(weapon_x, -28, 2, 32), Color("8f6847"))
	# Curved silver naginata blade, distinct from the old straight spear.
	draw_rect(Rect2(weapon_x, -36, 2, 10), Color("ede0a4"))
	draw_rect(Rect2(weapon_x + 2, -38, 4, 6), Color("cbd1bd"))
	draw_rect(Rect2(weapon_x + 4, -40, 2, 4), Color("ede0a4"))
	if state == State.ARROWS:
		for step in range(7):
			draw_rect(Rect2(-14 - abs(3 - step), -22 + step * 3, 2, 3), Color("ba9663"))
		draw_line(Vector2(-14, -22), Vector2(-14, -1), Color("e1d5ad"), 1)

func _draw_fan() -> void:
	var half := deg_to_rad(sweep_angle * 0.5)
	var color := Color(1, 0.78, 0.4, 0.55)
	for y in range(-int(sweep_radius), int(sweep_radius) + 1, 4):
		for x in range(-int(sweep_radius), int(sweep_radius) + 1, 4):
			var point := Vector2(x, y)
			if point.length() <= sweep_radius and (point == Vector2.ZERO or attack_direction.dot(point.normalized()) >= cos(half)):
				draw_rect(Rect2(point, Vector2(4, 4)), color)
	for index in range(33):
		var point := (attack_direction.rotated(lerpf(-half, half, index / 32.0)) * sweep_radius / 2).round() * 2
		draw_rect(Rect2(point - Vector2(2, 2), Vector2(4, 4)), Color("eeb478"))
	for angle in [-half, half]:
		for distance in range(4, int(sweep_radius), 4):
			var point := (attack_direction.rotated(angle) * distance / 2).round() * 2
			draw_rect(Rect2(point, Vector2(2, 2)), Color("eeb478"))
	if state == State.SWEEP:
		var angle := lerpf(-half, half, clampf(1.0 - state_time / 0.18, 0, 1))
		for distance in range(12, int(sweep_radius), 2):
			var point := (attack_direction.rotated(angle) * distance / 2).round() * 2
			draw_rect(Rect2(point, Vector2(2, 2)), Color("ece2bc"))

func _draw_side_legs(phase: int) -> void:
	var direction := -1.0 if facing.x < 0 else 1.0
	var stride := 4.0 if phase == 1 else (-4.0 if phase == 3 else 0.0)
	for leg in range(2):
		var swing := stride * (-1.0 if leg == 0 else 1.0)
		var lift := 2.0 if swing < 0 else 0.0
		var shade: Color = ARMOR["b"].darkened(0.3) if leg == 0 else ARMOR["b"]
		draw_line(Vector2(0, -3), Vector2(swing * 0.5 * direction, -1 - lift), shade, 2)
		draw_line(Vector2(swing * 0.5 * direction, -1 - lift), Vector2(swing * direction, 1 - lift), shade, 2)
		var toe_x := swing if direction > 0 else -swing - 4
		draw_rect(Rect2(toe_x, 1 - lift, 4, 2), ARMOR["h"].darkened(0.2) if leg == 0 else ARMOR["h"])
