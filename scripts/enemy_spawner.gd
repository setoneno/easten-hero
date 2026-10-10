extends Node2D
## Bounded continuous spawning. Distant enemies retire, making room for new pursuers.
const ENEMY := preload("res://scenes/enemy.tscn")
signal enemy_defeated(exp_amount: int)
@export var spawn_interval := 3.0
@export var max_enemies := 24
var player: CharacterBody2D
var map: Node2D
var elapsed := 0.0
var total_spawned := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	for index in range(4):
		spawn_enemy()

func _physics_process(delta: float) -> void:
	if player.dead:
		return
	for enemy in get_children():
		if enemy.position.distance_to(player.position) > 700.0:
			enemy.queue_free()
	elapsed += delta
	if elapsed >= spawn_interval:
		elapsed = 0.0
		spawn_enemy()

func spawn_enemy() -> CharacterBody2D:
	if player.dead or get_tree().paused or get_child_count() >= max_enemies:
		return null
	for attempt in range(40):
		var candidate := player.position + Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(180, 300)
		candidate = (candidate / 16).floor() * 16 + Vector2(8, 8)
		if not map.is_clear(candidate) or map.route(candidate, player.position).is_empty():
			continue
		var occupied := false
		for existing in get_children():
			if existing.position.distance_to(candidate) < 24:
				occupied = true
		if occupied:
			continue
		var enemy: CharacterBody2D = ENEMY.instantiate()
		enemy.position = candidate
		enemy.player = player
		enemy.map = map
		enemy.defeated.connect(func(amount: int) -> void: enemy_defeated.emit(amount))
		add_child(enemy)
		total_spawned += 1
		return enemy
	return null
