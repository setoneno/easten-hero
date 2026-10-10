extends CharacterBody2D
## Rust-clad foot soldier with headband, lamellar vest and decorative spear.
@export var speed := 65.0
@export var max_hp := 20
@export var contact_damage := 10
@export var exp_reward := 10
signal defeated(exp_amount: int)
var hp := 20
var dead := false
var hit_flash := 0.0
var player: CharacterBody2D
var map: Node2D
var path := PackedVector2Array()
var repath_time := 0.0
var walk_time := 0.0
var facing := Vector2.DOWN
const COLORS := {"h": Color("34312e"), "s": Color("cba075"), "r": Color("a15b48"), "a": Color("754336"), "b": Color("544b45")}
const PIXELS := ["...hhhh...", "..hhhhhh..", "..rrrrrr..", "..hssssh..", "...ssss...", "..aaaaaa..", ".saaraars.", ".saaaaaas.", "..rrrrrr..", "..bbbbbb..", "...b..b...", "...h..h..."]
const BACK := ["...hhhh...", "..hhhhhh..", "..rrrrrr..", "..hhhhhh..", "...hhhh...", "..aaaaaa..", ".saaraars.", ".saaaaaas.", "..rrrrrr..", "..bbbbbb..", "...b..b...", "...h..h..."]
const SIDE := ["...hhh....", "..hhhhh...", "..rrrrr...", "..hhsss...", "...hsss...", "...aaaa...", "...aasaa..", "...aasaa..", "...rrrr...", "...bbbb...", "...b..b...", "...h..h..."]

func _ready() -> void:
	add_to_group("field_characters")
	add_to_group("enemies")
	hp = max_hp

func take_damage(amount: int) -> void:
	if dead or get_tree().paused or amount <= 0:
		return
	hp = maxi(0, hp - amount)
	hit_flash = 0.12
	queue_redraw()
	if hp > 0:
		get_tree().call_group("game_feedback", "play_cue", "hit")
		get_tree().call_group("game_feedback", "burst", global_position, "-%d" % amount, Color("f0d5a6"))
	if hp == 0:
		get_tree().call_group("game_feedback", "burst", global_position, "DEFEATED", Color("e3cf8e"))
		dead = true
		remove_from_group("enemies")
		set_physics_process(false)
		defeated.emit(exp_reward)
		queue_free()

func _process(delta: float) -> void:
	hit_flash = maxf(0, hit_flash - delta)
	self_modulate = Color(1.8, 1.4, 1.2) if hit_flash > 0 else Color.WHITE

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(map):
		return
	if player.dead:
		velocity = Vector2.ZERO
		return
	repath_time -= delta
	if repath_time <= 0.0:
		path = map.route(position, player.position)
		if path.size() > 1:
			path.remove_at(0) # The starting cell is behind the current movement.
		repath_time = 0.6
	while not path.is_empty() and position.distance_to(path[0]) < 3.0:
		path.remove_at(0)
	velocity = Vector2.ZERO
	if position.distance_to(player.position) > 18.0 and not path.is_empty():
		velocity = position.direction_to(path[0]) * speed
		facing = velocity.normalized()
	var before := position
	move_and_slide()
	walk_time = walk_time + delta if position.distance_to(before) > 0.01 else 0.0
	queue_redraw()

func _draw() -> void:
	if hp < max_hp:
		draw_rect(Rect2(-10, -34, 20, 3), Color("3b302d"))
		draw_rect(Rect2(-10, -34, 20.0 * hp / max_hp, 3), Color("d69066"))
	draw_rect(Rect2(-9, 1, 18, 4), Color(0.08, 0.12, 0.1, 0.4))
	var sideways := absf(facing.x) >= absf(facing.y) and facing.x != 0
	var pixels: Array = SIDE if sideways else (BACK if facing.y < 0 else PIXELS)
	var phase := int(walk_time * 8.0) % 4
	for y in range(pixels.size()):
		if sideways and y >= 10:
			continue
		for x in range(pixels[y].length()):
			var symbol: String = pixels[y][x]
			if symbol == ".":
				continue
			var offset_y := 0
			if y >= 10:
				offset_y = (2 if phase == 1 else (-2 if phase == 3 else 0)) * (1 if x < 5 else -1)
			var draw_x := 9 - x if sideways and facing.x < 0 else x
			draw_rect(Rect2(draw_x * 2 - 10, y * 2 - 22 + offset_y, 2, 2), COLORS[symbol])
	# Contact damage comes from the feet hurtbox overlap, not the spear graphic.
	if sideways:
		_draw_side_legs(phase)
	var spear_x := -13 if sideways and facing.x < 0 else 11
	draw_rect(Rect2(spear_x, -24, 2, 27), Color("937a51"))
	draw_rect(Rect2(spear_x - 1, -28, 4, 6), Color("bac4b4"))

func _draw_side_legs(phase: int) -> void:
	var direction := -1.0 if facing.x < 0 else 1.0
	var stride := 4.0 if phase == 1 else (-4.0 if phase == 3 else 0.0)
	for leg in range(2):
		var swing := stride * (-1.0 if leg == 0 else 1.0)
		var lift := 2.0 if swing < 0 else 0.0
		var shade: Color = COLORS["b"].darkened(0.3) if leg == 0 else COLORS["b"]
		draw_line(Vector2(0, -3), Vector2(swing * 0.5 * direction, -1 - lift), shade, 2)
		draw_line(Vector2(swing * 0.5 * direction, -1 - lift), Vector2(swing * direction, 1 - lift), shade, 2)
		var toe_x := swing if direction > 0 else -swing - 4
		draw_rect(Rect2(toe_x, 1 - lift, 4, 2), COLORS["h"].darkened(0.2) if leg == 0 else COLORS["h"])
