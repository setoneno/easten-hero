extends Node2D
signal thrown
## Press/hold to throw. Aim modes remain selectable until user playtesting decides.
const SWORD := preload("res://scenes/thrown_sword.tscn")
@export var projectile_speed := 320.0
@export var attack_interval := 0.4
@export var attack_range := 400.0
@export var attack_damage := 10
var auto_aim := true
var cooldown := 0.0
var shots_fired := 0
var mouse_viewport_position := Vector2.ZERO
@onready var player: CharacterBody2D = get_parent()

func _ready() -> void:
	mouse_viewport_position = get_viewport().get_mouse_position()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		mouse_viewport_position = event.position

func mouse_world_position() -> Vector2:
	# Reproject the stationary cursor each frame as the camera follows the player.
	return get_canvas_transform().affine_inverse() * mouse_viewport_position

func _physics_process(delta: float) -> void:
	if player.dead:
		return
	cooldown = maxf(0, cooldown - delta)
	if Input.is_action_just_pressed("toggle_aim"):
		auto_aim = not auto_aim
	if Input.is_action_pressed("throw_sword"):
		throw_sword()
	queue_redraw()

func aim_direction() -> Vector2:
	if not auto_aim:
		var offset := mouse_world_position() - player.global_position
		return offset.normalized() if offset.length() > 1 else player.facing.normalized()
	var closest: Node2D = null
	var closest_distance := attack_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.dead or enemy.is_queued_for_deletion():
			continue
		var distance: float = player.global_position.distance_to(enemy.global_position)
		if distance > closest_distance:
			continue
		var query := PhysicsRayQueryParameters2D.create(player.global_position, enemy.global_position, 1)
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			continue
		closest = enemy
		closest_distance = distance
	if closest and player.global_position.distance_to(closest.global_position) > 1:
		return player.global_position.direction_to(closest.global_position)
	return player.facing.normalized()

func throw_sword() -> CharacterBody2D:
	if player.dead or get_tree().paused or cooldown > 0:
		return null
	var sword: CharacterBody2D = SWORD.instantiate()
	sword.direction = aim_direction()
	sword.speed = projectile_speed
	sword.damage = attack_damage
	sword.max_range = attack_range
	player.get_parent().add_child(sword)
	sword.global_position = player.global_position
	cooldown = attack_interval
	shots_fired += 1
	thrown.emit()
	return sword

func _draw() -> void:
	# Manual aim marker, independent of the facing pose used for movement.
	if not auto_aim:
		var offset := (mouse_world_position() - player.global_position).normalized() * 24
		draw_rect(Rect2(offset.floor() - Vector2(2, 2), Vector2(4, 4)), Color("e2c978"))
