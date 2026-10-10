extends CharacterBody2D
## Original 2px pixel figure: tied hair, cream tunic, indigo sash and leggings.
@export var move_speed := 100.0
@export var max_hp := 100
@export var invulnerability_duration := 1.0
signal health_changed(current_hp: int, maximum_hp: int)
signal died
var hp := 100
var dead := false
var invulnerability_left := 0.0
var hit_flash := 0.0
const COLORS := {"h": Color("292c32"), "s": Color("d6ad7b"), "c": Color("ded6b4"), "b": Color("465e72")}
const FRONT := ["....hh....", "...hhhh...", "..hssssh..", "..hshssh..", "...ssss...", "..cccccc..", ".sccccccs.", ".sccbbccs.", "..bbbbbb..", "..cccccc..", "...b..b...", "...h..h..."]
const BACK := ["....hh....", "...hhhh...", "..hhhhhh..", "..hhhhhh..", "...hhhh...", "..cccccc..", ".sccccccs.", ".sccbbccs.", "..bbbbbb..", "..cccccc..", "...b..b...", "...h..h..."]
const SIDE := ["...hhh....", "..hhhhh...", "..hhsss...", "..hhshss..", "...hsss...", "...cccc...", "...ccssc..", "...ccssc..", "...bbbb...", "...cccc...", "...b..b...", "...h..h..."]
var facing := Vector2.DOWN
var walk_time := 0.0

func _ready() -> void:
	add_to_group("field_characters")
	hp = max_hp

func take_damage(amount: int) -> void:
	if dead or get_tree().paused or invulnerability_left > 0 or amount <= 0:
		return
	hp = maxi(0, hp - amount)
	invulnerability_left = invulnerability_duration
	hit_flash = 0.12
	health_changed.emit(hp, max_hp)
	if hp == 0:
		dead = true
		velocity = Vector2.ZERO
		self_modulate = Color("887b73")
		died.emit()

func _process(_delta: float) -> void:
	if hit_flash > 0:
		self_modulate = Color(1.7, 0.65, 0.65)
	elif invulnerability_left > 0 and int(invulnerability_left * 10) % 2 == 0:
		self_modulate = Color(1.3, 1.2, 0.8)
	else:
		self_modulate = Color.WHITE

func _physics_process(delta: float) -> void:
	if dead:
		return
	invulnerability_left = maxf(0, invulnerability_left - delta)
	hit_flash = maxf(0, hit_flash - delta)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	if direction != Vector2.ZERO:
		facing = direction
	var before := position
	move_and_slide()
	walk_time = walk_time + delta if position.distance_to(before) > 0.01 else 0.0
	queue_redraw()
	for body in $Hurtbox.get_overlapping_bodies():
		if body.is_in_group("enemies") and not body.dead and not body.is_queued_for_deletion():
			take_damage(body.contact_damage)
			break # Multiple enemies cannot stack damage in a single physics step.

func _draw() -> void:
	draw_rect(Rect2(-9, 1, 18, 4), Color(0.08, 0.12, 0.1, 0.4))
	var sideways := absf(facing.x) >= absf(facing.y) and facing.x != 0
	var pixels: Array = SIDE if sideways else (BACK if facing.y < 0 else FRONT)
	var phase := int(walk_time * 8.0) % 4
	for y in range(pixels.size()):
		if sideways and y >= 10:
			continue # Side poses use their own overlapping, forward/backward legs.
		for x in range(pixels[y].length()):
			var symbol: String = pixels[y][x]
			if symbol == ".":
				continue
			var offset_y := 0
			if y >= 10:
				offset_y = (2 if phase == 1 else (-2 if phase == 3 else 0)) * (1 if x < 5 else -1)
			var draw_x := 9 - x if sideways and facing.x < 0 else x
			draw_rect(Rect2(draw_x * 2 - 10, y * 2 - 22 + offset_y, 2, 2), COLORS[symbol])
	draw_rect(Rect2(-4 if sideways else -6, -10, 8 if sideways else 12, 2), Color("9d5443"))
	if sideways:
		_draw_side_legs(phase)

func _draw_side_legs(phase: int) -> void:
	var direction := -1.0 if facing.x < 0 else 1.0
	var stride := 4.0 if phase == 1 else (-4.0 if phase == 3 else 0.0)
	# Far leg first; near leg has the normal clothing color. Mirror the entire gait.
	for leg in range(2):
		var swing := stride * (-1.0 if leg == 0 else 1.0)
		var lift := 2.0 if swing < 0 else 0.0
		var shade: Color = COLORS["b"].darkened(0.3) if leg == 0 else COLORS["b"]
		draw_line(Vector2(0, -3), Vector2(swing * 0.5 * direction, -1 - lift), shade, 2)
		draw_line(Vector2(swing * 0.5 * direction, -1 - lift), Vector2(swing * direction, 1 - lift), shade, 2)
		var toe_x := swing if direction > 0 else -swing - 4
		draw_rect(Rect2(toe_x, 1 - lift, 4, 2), COLORS["h"].darkened(0.2) if leg == 0 else COLORS["h"])
