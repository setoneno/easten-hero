extends CharacterBody2D
## Straight, non-piercing sword. Swept movement prevents tunneling between frames.
var direction := Vector2.RIGHT
var speed := 320.0
var damage := 10
var max_range := 400.0
var traveled := 0.0

func _ready() -> void:
	rotation = direction.angle()
	add_to_group("thrown_swords")
	add_to_group("field_characters")

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	var distance := minf(speed * delta, max_range - traveled)
	var collision := move_and_collide(direction * distance, false, 0.08, true)
	traveled += distance
	if collision:
		var body := collision.get_collider()
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif traveled >= max_range:
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(-2, -2, 11, 4), Color("c7d5cf"))
	draw_rect(Rect2(-1, -2, 9, 1), Color("f0f1d8"))
	draw_rect(Rect2(9, -1, 3, 2), Color("dce4da"))
	draw_rect(Rect2(-4, -4, 2, 8), Color("c2a667"))
	draw_rect(Rect2(-10, -1, 6, 2), Color("70533d"))
