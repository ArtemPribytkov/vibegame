extends Node2D

const SAVE_PATH := "user://savegame.save"
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var player: Player = %Player
@onready var bonfire_area: Area2D = %BonfireArea
@onready var bonfire_prompt: Label = %BonfirePrompt
@onready var hp_bar: ProgressBar = %HpBar
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var slash_style_label: Label = %SlashStyleLabel
@onready var crest_icon: TextureRect = %CrestIcon
@onready var banner_label: Label = %BannerLabel
@onready var banner_sub_label: Label = %BannerSubLabel
@onready var banner_container: Control = %BannerContainer

var _near_bonfire: bool = false
var _was_interact_pressed: bool = false
var _was_esc_pressed: bool = false
var _banner_timer: float = 0.0


func _ready() -> void:
	player.stats_changed.connect(_on_player_stats_changed)
	player.slash_style_changed.connect(_on_slash_style_changed)
	_on_player_stats_changed(player.hp, player.max_hp, player.stamina, player.max_stamina)
	player._apply_slash_style(player.current_slash_index)

	bonfire_area.body_entered.connect(_on_bonfire_body_entered)
	bonfire_area.body_exited.connect(_on_bonfire_body_exited)
	bonfire_prompt.visible = false

	# Если загружаем сохранение (или есть точка спавна в сохранении)
	if get_tree().has_meta("load_from_save") and bool(get_tree().get_meta("load_from_save")):
		get_tree().set_meta("load_from_save", false)
		_load_game()
		_show_banner("ПРОБУЖДЕНИЕ У КОСТРА", "Путь продолжается")
	else:
		# При старте новой игры сразу создаём начальное сохранение, чтобы "Продолжить игру" работало
		_save_game()
		_show_banner("ПЕПЕЛЬНЫЙ ПРЕДЕЛ", "Начало пути")


func _process(delta: float) -> void:
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer < 1.0:
			banner_container.modulate.a = clampf(_banner_timer, 0.0, 1.0)
		elif _banner_timer > 2.6:
			banner_container.modulate.a = clampf((3.2 - _banner_timer) / 0.6, 0.0, 1.0)
		else:
			banner_container.modulate.a = 1.0
	else:
		banner_container.visible = false

	var interact_down := Input.is_key_pressed(KEY_E)
	var interact_just_pressed := interact_down and not _was_interact_pressed
	_was_interact_pressed = interact_down

	if _near_bonfire and interact_just_pressed:
		_rest_at_bonfire()

	var esc_down := Input.is_key_pressed(KEY_ESCAPE)
	var esc_just_pressed := esc_down and not _was_esc_pressed
	_was_esc_pressed = esc_down

	if esc_just_pressed:
		_save_game()
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_player_stats_changed(hp: float, max_hp: float, stamina: float, max_stamina: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	stamina_bar.max_value = max_stamina
	stamina_bar.value = stamina


func _on_slash_style_changed(style_name: String, icon_tex: Texture2D) -> void:
	if slash_style_label:
		slash_style_label.text = "Стиль клинка: %s  (клавиши 1–6)" % style_name
	if crest_icon and icon_tex:
		crest_icon.texture = icon_tex


func _on_bonfire_body_entered(body: Node2D) -> void:
	if body == player:
		_near_bonfire = true
		bonfire_prompt.visible = true


func _on_bonfire_body_exited(body: Node2D) -> void:
	if body == player:
		_near_bonfire = false
		bonfire_prompt.visible = false


func _rest_at_bonfire() -> void:
	player.restore_at_bonfire()
	_save_game()
	_show_banner("КОСТЁР ЗАЖЖЁН", "Здоровье и силы восстановлены • Прогресс сохранён")
	if UISoundManager:
		UISoundManager.play_click()


func _show_banner(title: String, subtitle: String) -> void:
	banner_label.text = title
	banner_sub_label.text = subtitle
	banner_container.modulate.a = 0.0
	banner_container.visible = true
	_banner_timer = 3.2


func _save_game() -> void:
	var save_data := {
		"class_id": player.class_id,
		"player_x": player.global_position.x,
		"player_y": player.global_position.y,
		"hp": player.hp,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))


func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var data: Dictionary = parsed
		if data.has("class_id"):
			player.apply_character_class(String(data["class_id"]))
		if data.has("player_x") and data.has("player_y"):
			player.global_position = Vector2(float(data["player_x"]), float(data["player_y"]))
		if data.has("hp"):
			player.hp = float(data["hp"])
			player.stats_changed.emit(player.hp, player.max_hp, player.stamina, player.max_stamina)
