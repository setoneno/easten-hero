extends Node2D
## A prayer spot at a shrine entrance; all three spots count once per round.
signal prayed
var player: CharacterBody2D
var visited := false
var draw_building := true
var prayer_point := Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if is_instance_valid(player) and player.global_position.distance_to(global_position + prayer_point) <= 18:
		call_deferred("try_pray")

func try_pray() -> void:
	if visited or not is_instance_valid(player) or player.dead or get_tree().paused:
		return
	if player.global_position.distance_to(global_position + prayer_point) > 18:
		return
	visited = true
	queue_redraw()
	prayed.emit()

func _draw() -> void:
	if draw_building:
		draw_rect(Rect2(-16, -16, 32, 20), Color("64513d"))
		draw_rect(Rect2(-12, -14, 24, 16), Color("b49a6a"))
		draw_rect(Rect2(-4, -10, 8, 14), Color("343a2d"))
		for row in range(4):
			draw_rect(Rect2(-20 + row * 4, -20 - row * 4, 40 - row * 8, 4), Color("a18b59") if row % 2 else Color("84714c"))
		draw_rect(Rect2(-8, 4, 16, 4), Color("a8aa91"))
	var point := prayer_point + Vector2(0, -5)
	var color := Color("8ed09b") if visited else Color("e6ca7d")
	draw_rect(Rect2(point + Vector2(-10, 0), Vector2(20, 2)), color)
	draw_rect(Rect2(point + Vector2(-10, -4), Vector2(2, 4)), color)
	draw_rect(Rect2(point + Vector2(8, -4), Vector2(2, 4)), color)
	if visited:
		draw_line(point + Vector2(-4, -8), point + Vector2(0, -4), color, 2)
		draw_line(point + Vector2(0, -4), point + Vector2(6, -12), color, 2)
