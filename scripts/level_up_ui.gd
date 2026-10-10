extends Control
signal selected(index: int)
var choosing := false

func _ready() -> void:
	for index in range(3):
		get_node("Choice" + str(index + 1)).pressed.connect(_choose.bind(index))

func present(level: int, pending: int, descriptions: Array[String]) -> void:
	$Title.text = "LEVEL " + str(level) + "  /  CHOOSE AN UPGRADE"
	$Hint.text = "Click or press 1 / 2 / 3   |   Remaining choices: " + str(pending)
	for index in range(3):
		var button: Button = get_node("Choice" + str(index + 1))
		button.text = descriptions[index]
		button.disabled = false
	choosing = false
	show()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or choosing or not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if key >= KEY_1 and key <= KEY_3:
		get_viewport().set_input_as_handled()
		_choose(key - KEY_1)

func _choose(index: int) -> void:
	if not visible or choosing:
		return
	choosing = true
	for number in range(1, 4):
		get_node("Choice" + str(number)).disabled = true
	# Defer so one mouse/key event cannot select twice across consecutive menus.
	call_deferred("_emit_selection", index)

func _emit_selection(index: int) -> void:
	if visible:
		selected.emit(index)
