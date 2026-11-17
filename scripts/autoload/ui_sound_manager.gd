extends Node

const CLICK_SOUND_PATH := "res://assets/audio/ui_click.wav"
const HOVER_SOUND_PATH := "res://assets/audio/ui_hover.wav"

var _click_player: AudioStreamPlayer
var _hover_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_click_player = AudioStreamPlayer.new()
	_click_player.stream = _build_dark_click_stream()
	add_child(_click_player)

	_hover_player = AudioStreamPlayer.new()
	_hover_player.stream = _build_dark_hover_stream()
	add_child(_hover_player)

	get_tree().node_added.connect(_on_node_added)
	_bind_existing_buttons(get_tree().root)


func _bind_existing_buttons(root: Node) -> void:
	if root is BaseButton:
		_connect_button(root)
	for child in root.get_children():
		_bind_existing_buttons(child)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node)


func _connect_button(button: BaseButton) -> void:
	if not button.pressed.is_connected(play_click):
		button.pressed.connect(play_click)
	if not button.mouse_entered.is_connected(_on_button_hovered.bind(button)):
		button.mouse_entered.connect(_on_button_hovered.bind(button))


func _on_button_hovered(button: BaseButton) -> void:
	if not button.disabled:
		play_hover()


func play_click() -> void:
	if _click_player:
		_click_player.pitch_scale = randf_range(0.95, 1.03)
		_click_player.play()


func play_hover() -> void:
	if _hover_player:
		_hover_player.pitch_scale = randf_range(0.96, 1.04)
		_hover_player.play()


func _build_dark_click_stream() -> AudioStream:
	if ResourceLoader.exists(CLICK_SOUND_PATH):
		var loaded := load(CLICK_SOUND_PATH) as AudioStream
		if loaded:
			return loaded

	# Мрачный удар в стиле Dark Souls: глухой каменный бас + металлический резонанс клинка
	var sample_rate := 44100
	var duration := 0.28
	var count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)

	for i in range(count):
		var t := float(i) / float(sample_rate)
		var f_low := 42.0 + 95.0 * exp(-t * 38.0)
		var thud := sin(TAU * f_low * t) * exp(-t * 18.0) * 0.65
		var ring := (
			sin(TAU * 528.0 * t) * exp(-t * 16.0) * 0.18 +
			sin(TAU * 796.0 * t) * exp(-t * 22.0) * 0.12 +
			sin(TAU * 1185.0 * t) * exp(-t * 28.0) * 0.08 +
			sin(TAU * 1840.0 * t) * exp(-t * 40.0) * 0.05
		)
		var attack := minf(1.0, t / 0.003)
		var sample := int(clampf((thud + ring) * attack, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav


func _build_dark_hover_stream() -> AudioStream:
	if ResourceLoader.exists(HOVER_SOUND_PATH):
		var loaded := load(HOVER_SOUND_PATH) as AudioStream
		if loaded:
			return loaded

	# Тихий шелест пепла и низкий отзвук стали при наведении
	var sample_rate := 44100
	var duration := 0.09
	var count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)

	for i in range(count):
		var t := float(i) / float(sample_rate)
		var f_sub := 95.0 + 45.0 * exp(-t * 45.0)
		var sub := sin(TAU * f_sub * t) * exp(-t * 32.0) * 0.22
		var metal := sin(TAU * 640.0 * t) * exp(-t * 45.0) * 0.05
		var attack := minf(1.0, t / 0.004)
		var sample := int(clampf((sub + metal) * attack, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav
