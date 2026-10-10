extends Node2D
## Original synthesized tones and short-lived pixel feedback. Continues during menus.
signal mute_changed
const NOTES := {
	"throw": [660.0, 440.0], "hit": [180.0, 120.0], "hurt": [150.0, 90.0],
	"defeat": [440.0, 660.0], "level": [523.0, 659.0, 784.0],
	"select": [659.0, 880.0], "clear": [523.0, 659.0, 784.0, 1047.0],
	"game_over": [330.0, 262.0, 196.0, 131.0],
}
var muted := false
var sounds: Dictionary = {}
var cue_counts: Dictionary = {}
var popups: Array[Dictionary] = []
var notice_left := 0.0
var flash_left := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_feedback")
	for cue in NOTES:
		var audio := AudioStreamPlayer.new()
		audio.stream = _tone(NOTES[cue], 0.045 if cue == "throw" or cue == "hit" else 0.1)
		audio.volume_db = -14.0
		audio.max_polyphony = 3
		add_child(audio)
		sounds[cue] = audio

func _tone(notes: Array, note_seconds: float) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * note_seconds)
	var data := PackedByteArray()
	data.resize(frames * notes.size() * 2)
	for note in range(notes.size()):
		for frame in range(frames):
			var time := float(frame) / rate
			var envelope := minf(time / 0.005, 1.0) * maxf(0, 1.0 - time / note_seconds)
			var sample := sin(TAU * notes[note] * time) + 0.2 * sin(TAU * notes[note] * 2 * time)
			data.encode_s16((note * frames + frame) * 2, int(sample * envelope * 0.4 * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream

func play_cue(cue: String) -> void:
	if not sounds.has(cue):
		return
	cue_counts[cue] = int(cue_counts.get(cue, 0)) + 1
	if not muted:
		sounds[cue].play()

func announce(message: String, color: Color = Color("e3cf8e")) -> void:
	var label: Label = get_parent().get_node("HUD/Notice")
	label.text = message
	label.modulate = color
	notice_left = 2.0

func hurt() -> void:
	flash_left = 0.2
	play_cue("hurt")
	announce("HIT!  Brief invulnerability", Color("ef9a7d"))

func burst(point: Vector2, message: String, color: Color) -> void:
	if popups.size() >= 24:
		return
	var label := Label.new()
	label.position = point + Vector2(-22, -38)
	label.text = message
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_shadow_color", Color("17251c"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.modulate = color
	add_child(label)
	popups.append({"label": label, "left": 0.6})

func _process(delta: float) -> void:
	if get_parent().menu_paused:
		return
	notice_left = maxf(0, notice_left - delta)
	get_parent().get_node("HUD/Notice").modulate.a = minf(1.0, notice_left * 3.0)
	flash_left = maxf(0, flash_left - delta)
	get_parent().get_node("HUD/HurtFlash").color.a = flash_left * 0.6
	for index in range(popups.size() - 1, -1, -1):
		var popup: Dictionary = popups[index]
		popup.left -= delta
		popup.label.position.y -= delta * 20
		popup.label.modulate.a = minf(1.0, popup.left * 4.0)
		if popup.left <= 0:
			popup.label.queue_free()
			popups.remove_at(index)

func clear_popups() -> void:
	for popup in popups:
		popup.label.free()
	popups.clear()

func _exit_tree() -> void:
	# Release generated streams explicitly when restarting or closing the game.
	for audio in sounds.values():
		audio.stop()
		audio.stream = null
	sounds.clear()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		muted = not muted
		if muted:
			for audio in sounds.values():
				audio.stop()
		mute_changed.emit()
		get_viewport().set_input_as_handled()
