extends Control

func _ready() -> void:
	get_tree().paused = false
	GameSession.load_checkpoint()
	preload("res://scripts/menu_layout.gd").populate(self, "EASTEN HERO\nAncient Japan • Ver 1.0", ["NEW GAME", "CONTINUE", "EXIT"])
	$NewGame.pressed.connect(GameSession.new_game)
	$Continue.disabled = GameSession.checkpoint.is_empty()
	$Continue.pressed.connect(GameSession.continue_game)
	$Exit.pressed.connect(GameSession.exit_game)
	$NewGame.grab_focus()
