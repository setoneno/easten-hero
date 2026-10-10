extends RefCounted
## Shared full-screen menu, sized to the game's logical 640 x 360 canvas.
static func populate(panel: Control, heading: String, actions: Array[String]) -> void:
	for child in panel.get_children():
		child.free()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(640, 360)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.size = panel.size
	shade.color = Color(0.05, 0.1, 0.07, 0.93)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(shade)
	var title := Label.new()
	title.name = "Message"
	title.text = heading
	title.position = Vector2(20, 68)
	title.size = Vector2(600, 76)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.modulate = Color("e5ce89")
	panel.add_child(title)
	for index in range(actions.size()):
		var button := Button.new()
		button.name = actions[index].capitalize().replace(" ", "")
		button.text = actions[index]
		button.position = Vector2(210, 166 + index * 48)
		button.size = Vector2(220, 40)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 18)
		style_button(button)
		panel.add_child(button)

static func style_button(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("304536") if state == "hover" or state == "focus" else Color("202f26")
		style.border_color = Color("d6b876") if state != "disabled" else Color("52604c")
		style.set_border_width_all(2)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", Color("eee0b4"))
	button.add_theme_color_override("font_disabled_color", Color("75806e"))
