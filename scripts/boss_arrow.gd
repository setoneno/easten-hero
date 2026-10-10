extends CharacterBody2D
## Swept arrow: hits terrain or player feet, never allies, and expires by range.
var direction := Vector2.RIGHT
var speed := 260.0
var damage := 18
var max_range := 600.0
var traveled := 0.0
var player: CharacterBody2D

func _ready() -> void:
	rotation = direction.angle()
	add_to_group("boss_projectiles")
	add_to_group("field_characters")

func _physics_process(delta: float) -> void:
	if get_tree().paused or not is_instance_valid(player) or player.dead:
		return
	var distance := minf(speed * delta, max_range - traveled)
	var collision := move_and_collide(direction * distance)
	traveled += distance
	if collision:
		if collision.get_collider() == player:
			player.take_damage(damage)
		queue_free()
	elif traveled >= max_range:
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(-10, -1, 19, 2), Color("ab8857"))
	draw_rect(Rect2(8, -2, 4, 4), Color("e0ddba"))
	draw_rect(Rect2(12, -1, 2, 2), Color("edead1"))
	draw_rect(Rect2(-10, -3, 5, 2), Color("c1c6a4"))
	draw_rect(Rect2(-10, 1, 5, 2), Color("c1c6a4"))
