extends Control

const SAVE_PATH := "user://savegame.save"
const CLASS_SELECT_SCENE := "res://scenes/ui/class_select.tscn"
const GAME_WORLD_SCENE := "res://scenes/world/game_world.tscn"

@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	# При первом запуске (пока нет файла сохранения) кнопка "Продолжить игру" отключена
	continue_button.disabled = not FileAccess.file_exists(SAVE_PATH)

	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file(CLASS_SELECT_SCENE)


func _on_continue_pressed() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	get_tree().set_meta("load_from_save", true)
	get_tree().change_scene_to_file(GAME_WORLD_SCENE)


func _on_settings_pressed() -> void:
	status_label.text = "Настройки мира пока недоступны"


func _on_quit_pressed() -> void:
	get_tree().quit()
