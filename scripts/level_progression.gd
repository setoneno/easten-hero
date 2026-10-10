extends Node
## Remaining EXP and queued selections are independent of the game's pause state.
signal changed
@export var initial_requirement := 30
@export var requirement_step := 10
var level := 1
var exp := 0
var pending_choices := 0
var ability_levels: Array[int] = [1, 1, 1]

func required_exp() -> int:
	return initial_requirement + (level - 1) * requirement_step

func add_exp(amount: int) -> void:
	if amount <= 0:
		return
	exp += amount
	while exp >= required_exp():
		exp -= required_exp()
		level += 1
		pending_choices += 1
	changed.emit()
