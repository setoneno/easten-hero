extends "res://scripts/main.gd"
## Boss-only combat shortcut. Inspector settings allow different upgrade presets.
@export var test_damage := 30
@export var test_interval := 0.34
@export var test_speed := 120.0

func _ready() -> void:
	debug_tools_enabled = true
	super._ready()
	round_number = TOTAL_ROUNDS
	$Player.position = Vector2(560, 520)
	$Player/SwordThrower.attack_damage = test_damage
	$Player/SwordThrower.attack_interval = test_interval
	$Player.move_speed = test_speed
	$Progression.level = 8
	$Progression.exp = 60
	_start_final_battle()
	$HUD/BossPractice.text = "Retry boss (B)"
	$HUD/GameOver/Message.text = "GAME OVER"
	$HUD/GameOver/Continue.text = "RETRY PRACTICE (R)"
	$HUD/GameClear/NewGame.text = "RETRY PRACTICE (R)"
	$Feedback.announce("Boss practice | HP 100 | R retries after victory/defeat")
	print("BOSS TEST: standalone practice; R reloads this scene after victory/defeat.")
