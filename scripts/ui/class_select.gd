extends Control

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const GAME_WORLD_SCENE := "res://scenes/world/game_world.tscn"

@onready var class_list_grid: GridContainer = %ClassListGrid
@onready var preview_sprite: Sprite2D = %PreviewSprite
@onready var class_title_label: Label = %ClassTitleLabel
@onready var class_subtitle_label: Label = %ClassSubtitleLabel
@onready var class_lore_label: Label = %ClassLoreLabel
@onready var stat_hp_bar: ProgressBar = %StatHpBar
@onready var stat_hp_value: Label = %StatHpValue
@onready var stat_stamina_bar: ProgressBar = %StatStaminaBar
@onready var stat_stamina_value: Label = %StatStaminaValue
@onready var stat_speed_bar: ProgressBar = %StatSpeedBar
@onready var stat_speed_value: Label = %StatSpeedValue
@onready var stat_slash_label: Label = %StatSlashLabel
@onready var back_button: Button = %BackButton
@onready var start_button: Button = %StartButton

var _selected_index: int = 0
var _class_buttons: Array[Button] = []
var _idle_tex: Texture2D
var _attack_tex: Texture2D
var _idle_frames: int = 4
var _attack_frames: int = 4
var _anim_timer: float = 0.0
var _playing_attack_preview: bool = false


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	_build_class_cards()
	_select_class(0)


func _process(delta: float) -> void:
	_anim_timer += delta
	if _playing_attack_preview and _attack_tex:
		var frame_idx := int(_anim_timer * 10.0)
		if frame_idx >= _attack_frames:
			_playing_attack_preview = false
			_anim_timer = 0.0
			_apply_preview_sheet(_idle_tex, _idle_frames, 0)
		else:
			_apply_preview_sheet(_attack_tex, _attack_frames, frame_idx)
	elif _idle_tex:
		var frame_idx: int = int(_anim_timer * 7.0) % maxi(1, _idle_frames)
		_apply_preview_sheet(_idle_tex, _idle_frames, frame_idx)


func _apply_preview_sheet(tex: Texture2D, hframes_count: int, frame_idx: int) -> void:
	if not tex:
		return
	preview_sprite.texture = tex
	preview_sprite.hframes = maxi(1, hframes_count)
	preview_sprite.vframes = 1
	preview_sprite.frame = clampi(frame_idx, 0, maxi(0, hframes_count - 1))


func _build_class_cards() -> void:
	for child in class_list_grid.get_children():
		child.queue_free()
	_class_buttons.clear()

	for i in range(CharacterClasses.CLASSES.size()):
		var cls: Dictionary = CharacterClasses.CLASSES[i]
		var btn := _create_class_card_button(i, cls)
		class_list_grid.add_child(btn)
		_class_buttons.append(btn)


func _create_class_card_button(index: int, cls: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(215, 110)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.focus_mode = Control.FOCUS_ALL

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.075, 0.065, 0.06, 0.96)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 2
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.38, 0.3, 0.2, 0.85)
	normal_style.set_content_margin_all(10)

	var hover_style := normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.18, 0.08, 0.06, 0.98)
	hover_style.border_color = Color(0.86, 0.65, 0.34, 1.0)
	hover_style.shadow_color = Color(0.75, 0.25, 0.08, 0.35)
	hover_style.shadow_size = 10

	var pressed_style := hover_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.24, 0.09, 0.05, 1.0)
	pressed_style.border_color = Color(0.96, 0.78, 0.45, 1.0)

	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)

	var name_lbl := Label.new()
	name_lbl.text = String(cls["name"])
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.82, 0.68, 1.0))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sub_lbl := Label.new()
	sub_lbl.text = String(cls["subtitle"])
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.62, 0.52, 0.42, 0.95))
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var stats_mini := Label.new()
	stats_mini.text = "ОЗ: %d  |  ВЫН: %d" % [int(cls["hp"]), int(cls["stamina"])]
	stats_mini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_mini.add_theme_font_size_override("font_size", 12)
	stats_mini.add_theme_color_override("font_color", Color(0.75, 0.56, 0.36, 0.9))
	stats_mini.mouse_filter = Control.MOUSE_FILTER_IGNORE

	vbox.add_child(name_lbl)
	vbox.add_child(sub_lbl)
	vbox.add_child(stats_mini)
	btn.add_child(vbox)

	btn.pressed.connect(_select_class.bind(index))
	return btn


func _select_class(index: int) -> void:
	_selected_index = clampi(index, 0, CharacterClasses.CLASSES.size() - 1)
	var cls: Dictionary = CharacterClasses.CLASSES[_selected_index]

	# Визуально выделяем выбранную карточку
	for i in range(_class_buttons.size()):
		var b := _class_buttons[i]
		b.modulate = Color(1.15, 1.08, 0.95, 1.0) if i == _selected_index else Color(0.82, 0.8, 0.78, 0.9)

	class_title_label.text = String(cls["name"])
	class_subtitle_label.text = "— %s —" % String(cls["subtitle"])
	class_lore_label.text = String(cls["lore"])

	var hp_val := float(cls["hp"])
	var stam_val := float(cls["stamina"])
	var spd_val := float(cls["speed"])

	stat_hp_bar.value = hp_val
	stat_hp_value.text = str(int(hp_val))

	stat_stamina_bar.value = stam_val
	stat_stamina_value.text = str(int(stam_val))

	stat_speed_bar.value = spd_val
	stat_speed_value.text = str(int(spd_val))

	stat_slash_label.text = "Стихия удара: %s" % String(cls["slash_name"])

	var folder := String(cls["folder"])
	_idle_tex = CharacterClasses.load_sheet_texture(folder + "/idle.png")
	_attack_tex = CharacterClasses.load_sheet_texture(folder + "/" + String(cls["attack_file"]))

	_idle_frames = int(_idle_tex.get_width() / 128) if _idle_tex else 4
	_attack_frames = int(_attack_tex.get_width() / 128) if _attack_tex else 4

	_anim_timer = 0.0
	_playing_attack_preview = true
	_apply_preview_sheet(_attack_tex, _attack_frames, 0)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_start_pressed() -> void:
	var cls: Dictionary = CharacterClasses.CLASSES[_selected_index]
	get_tree().set_meta("selected_class_id", String(cls["id"]))
	get_tree().set_meta("load_from_save", false)
	get_tree().change_scene_to_file(GAME_WORLD_SCENE)
