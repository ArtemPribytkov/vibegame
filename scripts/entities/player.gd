extends CharacterBody2D
class_name Player

signal stats_changed(hp: float, max_hp: float, stamina: float, max_stamina: float)
signal slash_style_changed(style_name: String, icon_tex: Texture2D)

const ACCELERATION := 1600.0
const FRICTION := 1800.0
const JUMP_VELOCITY := -430.0
const GRAVITY := 1150.0

const ROLL_SPEED := 440.0
const ROLL_DURATION := 0.28
const ROLL_COST := 22.0

const ATTACK_DURATION := 0.36
const ATTACK_COOLDOWN := 0.40
const ATTACK_COST := 16.0

const STAMINA_REGEN_RATE := 28.0
const STAMINA_REGEN_DELAY := 0.65

const SLASH_STYLES := [
	{
		"id": "fire_slash",
		"title": "1: Огненный взмах (Fire Slash)",
		"folder": "res://assets/effects/slashes/fire_slash",
		"prefix": "fire_slash_frame_",
		"frames": 12,
		"flip_h": true,
		"offset": Vector2(44, -12),
		"scale": Vector2(0.23, 0.23),
		"icon": "res://assets/effects/slashes/icons/icons_fire_slash.png",
	},
	{
		"id": "ultimate_slash",
		"title": "2: Золотой рассекатель (Ultimate Slash)",
		"folder": "res://assets/effects/slashes/ultimate_slash",
		"prefix": "ultimate_slash_frame_",
		"frames": 20,
		"flip_h": false,
		"offset": Vector2(22, -10),
		"scale": Vector2(0.24, 0.24),
		"icon": "res://assets/effects/slashes/icons/icons_ultimate_slash.png",
	},
	{
		"id": "lightning_slash",
		"title": "3: Разряд молнии (Lightning Slash)",
		"folder": "res://assets/effects/slashes/lightning_slash",
		"prefix": "lightning_slash_frame_",
		"frames": 12,
		"flip_h": true,
		"offset": Vector2(44, -12),
		"scale": Vector2(0.23, 0.23),
		"icon": "res://assets/effects/slashes/icons/icons_lightning_slash.png",
	},
	{
		"id": "double_wind_slashes",
		"title": "4: Двойной вихрь (Double Wind)",
		"folder": "res://assets/effects/slashes/double_wind_slashes",
		"prefix": "double_wind_slashes_frame_",
		"frames": 18,
		"flip_h": true,
		"offset": Vector2(28, -8),
		"scale": Vector2(0.25, 0.25),
		"icon": "res://assets/effects/slashes/icons/icons_wind_slash.png",
	},
	{
		"id": "poisonous_slashes",
		"title": "5: Тёмное проклятие (Poison Slash)",
		"folder": "res://assets/effects/slashes/poisonous_slashes",
		"prefix": "poisonous_slashes_frame_",
		"frames": 24,
		"flip_h": false,
		"offset": Vector2(48, -10),
		"scale": Vector2(0.24, 0.24),
		"icon": "res://assets/effects/slashes/icons/icons_poisonous_slash.png",
	},
	{
		"id": "water_slash",
		"title": "6: Ледяной клинок (Water Slash)",
		"folder": "res://assets/effects/slashes/water_slash",
		"prefix": "water_slash_frame_",
		"frames": 12,
		"flip_h": true,
		"offset": Vector2(44, -12),
		"scale": Vector2(0.23, 0.23),
		"icon": "res://assets/effects/slashes/icons/icons_water_slash.png",
	},
]

var class_id: String = "knight_1"
var class_title: String = "СТРАЖ ПЕПЛА"
var move_speed: float = 240.0
var max_hp: float = 140.0
var hp: float = 140.0
var max_stamina: float = 110.0
var stamina: float = 110.0

var facing_dir: int = 1
var is_rolling: bool = false
var is_attacking: bool = false
var is_crouching: bool = false
var current_slash_index: int = 0
var _crouch_frame_index: int = 0

var _loaded_slash_frames: Array[Array] = []
var _loaded_slash_icons: Array[Texture2D] = []
var _char_sheets: Dictionary = {}
var _combo_toggle: bool = false

var _roll_timer: float = 0.0
var _attack_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var _stamina_delay_timer: float = 0.0
var _coyote_timer: float = 0.0
var _anim_time: float = 0.0
var _was_jump_pressed: bool = false
var _was_roll_pressed: bool = false
var _was_attack_pressed: bool = false
var _was_num_pressed: Array[bool] = [false, false, false, false, false, false]

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_root: Node2D = %VisualRoot
@onready var sprite: Sprite2D = %Sprite2D
@onready var slash_sprite: Sprite2D = %SlashSprite
@onready var attack_hitbox: Area2D = %AttackHitbox
@onready var sfx_player: AudioStreamPlayer2D = %SfxPlayer


func _ready() -> void:
	slash_sprite.visible = false
	attack_hitbox.monitoring = false
	_preload_all_slash_styles()

	var initial_class := "knight_1"
	if get_tree().has_meta("selected_class_id"):
		initial_class = String(get_tree().get_meta("selected_class_id"))
	apply_character_class(initial_class)


func apply_character_class(target_class_id: String) -> void:
	var cls: Dictionary = CharacterClasses.get_class_by_id(target_class_id)
	class_id = String(cls["id"])
	class_title = String(cls["name"])
	max_hp = float(cls["hp"])
	hp = max_hp
	max_stamina = float(cls["stamina"])
	stamina = max_stamina
	move_speed = float(cls["speed"])
	_crouch_frame_index = int(cls.get("crouch_frame", 0))

	var folder := String(cls["folder"])
	_char_sheets = {
		"idle": CharacterClasses.load_sheet_texture(folder + "/idle.png"),
		"run": CharacterClasses.load_sheet_texture(folder + "/run.png"),
		"walk": CharacterClasses.load_sheet_texture(folder + "/walk.png"),
		"jump": CharacterClasses.load_sheet_texture(folder + "/jump.png"),
		"attack_1": CharacterClasses.load_sheet_texture(folder + "/" + String(cls["attack_file"])),
		"attack_2": CharacterClasses.load_sheet_texture(folder + "/" + String(cls["attack_2_file"])),
	}

	_apply_slash_style(int(cls["slash_index"]))
	stats_changed.emit(hp, max_hp, stamina, max_stamina)
	_set_character_sheet("idle", 0)


func _set_character_sheet(anim_key: String, frame_index: int) -> void:
	var tex: Texture2D = _char_sheets.get(anim_key) as Texture2D
	if not tex:
		return
	var total_frames := maxi(1, int(tex.get_width() / 128))
	sprite.texture = tex
	sprite.hframes = total_frames
	sprite.vframes = 1
	sprite.frame = clampi(frame_index, 0, total_frames - 1)


func _preload_all_slash_styles() -> void:
	_loaded_slash_frames.clear()
	_loaded_slash_icons.clear()

	for style: Dictionary in SLASH_STYLES:
		var frames_arr: Array[Texture2D] = []
		var count: int = int(style["frames"])
		var folder: String = String(style["folder"])
		var prefix: String = String(style["prefix"])

		for i in range(1, count + 1):
			var path := "%s/%s%02d.png" % [folder, prefix, i]
			var tex := CharacterClasses.load_sheet_texture(path)
			if tex:
				frames_arr.append(tex)

		_loaded_slash_frames.append(frames_arr)
		_loaded_slash_icons.append(CharacterClasses.load_sheet_texture(String(style["icon"])))


func _apply_slash_style(index: int) -> void:
	current_slash_index = clampi(index, 0, SLASH_STYLES.size() - 1)
	var style: Dictionary = SLASH_STYLES[current_slash_index]
	slash_sprite.flip_h = bool(style["flip_h"])
	slash_sprite.position = style["offset"] as Vector2
	slash_sprite.scale = style["scale"] as Vector2
	var icon_tex: Texture2D = _loaded_slash_icons[current_slash_index] if current_slash_index < _loaded_slash_icons.size() else null
	slash_style_changed.emit("%s • %s" % [class_title, String(style["title"])], icon_tex)


func _physics_process(delta: float) -> void:
	_anim_time += delta

	var key_codes := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]
	for idx in range(key_codes.size()):
		var down := Input.is_key_pressed(key_codes[idx])
		if down and not _was_num_pressed[idx]:
			_apply_slash_style(idx)
		_was_num_pressed[idx] = down

	if is_on_floor():
		_coyote_timer = 0.12
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
		velocity.y += GRAVITY * delta

	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer = maxf(0.0, _attack_cooldown_timer - delta)

	var move_dir := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_dir -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_dir += 1.0

	var jump_down := Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var jump_just_pressed := jump_down and not _was_jump_pressed
	_was_jump_pressed = jump_down

	var roll_down := Input.is_key_pressed(KEY_SHIFT)
	var roll_just_pressed := roll_down and not _was_roll_pressed
	_was_roll_pressed = roll_down

	var attack_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_J)
	var attack_just_pressed := attack_down and not _was_attack_pressed
	_was_attack_pressed = attack_down

	var crouch_down := Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	is_crouching = crouch_down and is_on_floor() and not is_rolling and not is_attacking
	_update_crouch_collision()

	if is_rolling:
		_roll_timer -= delta
		velocity.x = facing_dir * ROLL_SPEED
		if _roll_timer <= 0.0:
			is_rolling = false
			visual_root.rotation = 0.0
			visual_root.scale.y = 1.0
			visual_root.position.y = -32.0
			sprite.modulate = Color(1, 1, 1, 1)
	else:
		if move_dir != 0.0 and not is_attacking:
			facing_dir = 1 if move_dir > 0.0 else -1

		# Плавный разворот без рывка и телепортации
		var target_scale_x := float(facing_dir)
		visual_root.scale.x = move_toward(visual_root.scale.x, target_scale_x, delta * 22.0)
		if absf(visual_root.scale.x) < 0.15:
			visual_root.scale.x = 0.15 * signf(target_scale_x)

		var speed_mult := 1.0
		if is_attacking:
			speed_mult = 0.45
		elif is_crouching:
			speed_mult = 0.42

		var target_speed := move_dir * (move_speed * speed_mult)
		if move_dir != 0.0:
			velocity.x = move_toward(velocity.x, target_speed, ACCELERATION * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

		if jump_just_pressed and _coyote_timer > 0.0 and not is_attacking:
			is_crouching = false
			velocity.y = JUMP_VELOCITY
			_coyote_timer = 0.0

		if roll_just_pressed and not is_attacking and stamina >= ROLL_COST:
			is_crouching = false
			if move_dir != 0.0:
				facing_dir = 1 if move_dir > 0.0 else -1
			visual_root.scale.x = float(facing_dir)
			_start_roll()

		if attack_just_pressed and _attack_cooldown_timer <= 0.0 and stamina >= ATTACK_COST:
			is_crouching = false
			visual_root.scale.x = float(facing_dir)
			_start_attack()

	if is_attacking:
		_attack_timer -= delta
		var progress := clampf(1.0 - (_attack_timer / ATTACK_DURATION), 0.0, 0.999)
		var frames_list: Array = _loaded_slash_frames[current_slash_index]
		if not frames_list.is_empty():
			var frame_idx := int(progress * float(frames_list.size()))
			slash_sprite.texture = frames_list[frame_idx]

		var atk_key := "attack_2" if _combo_toggle else "attack_1"
		var atk_tex: Texture2D = _char_sheets.get(atk_key) as Texture2D
		if atk_tex:
			var atk_frames := maxi(1, int(atk_tex.get_width() / 128))
			_set_character_sheet(atk_key, int(progress * float(atk_frames)))

		if _attack_timer <= 0.0:
			is_attacking = false
			slash_sprite.visible = false
			attack_hitbox.monitoring = false

	if _stamina_delay_timer > 0.0:
		_stamina_delay_timer = maxf(0.0, _stamina_delay_timer - delta)
	elif stamina < max_stamina and not is_rolling and not is_attacking:
		stamina = minf(max_stamina, stamina + STAMINA_REGEN_RATE * delta)
		stats_changed.emit(hp, max_hp, stamina, max_stamina)

	move_and_slide()
	_update_character_sprite_animation(move_dir)


func _start_roll() -> void:
	is_rolling = true
	_roll_timer = ROLL_DURATION
	_consume_stamina(ROLL_COST)
	sprite.modulate = Color(0.7, 0.65, 0.6, 0.9)
	_play_whoosh(180.0, 85.0, 0.14)


func _start_attack() -> void:
	is_attacking = true
	_combo_toggle = not _combo_toggle
	_attack_timer = ATTACK_DURATION
	_attack_cooldown_timer = ATTACK_COOLDOWN
	_consume_stamina(ATTACK_COST)

	var frames_list: Array = _loaded_slash_frames[current_slash_index]
	if not frames_list.is_empty():
		slash_sprite.texture = frames_list[0]
	slash_sprite.visible = true
	attack_hitbox.monitoring = true
	velocity.x = facing_dir * 135.0
	_play_whoosh(420.0, 140.0, 0.18)


func _consume_stamina(amount: float) -> void:
	stamina = maxf(0.0, stamina - amount)
	_stamina_delay_timer = STAMINA_REGEN_DELAY
	stats_changed.emit(hp, max_hp, stamina, max_stamina)


func restore_at_bonfire() -> void:
	hp = max_hp
	stamina = max_stamina
	stats_changed.emit(hp, max_hp, stamina, max_stamina)


func _update_crouch_collision() -> void:
	if not collision_shape:
		return
	var capsule := collision_shape.shape as CapsuleShape2D
	if not capsule:
		return
	if is_crouching:
		capsule.height = 42.0
		collision_shape.position.y = -21.0
	else:
		capsule.height = 64.0
		collision_shape.position.y = -32.0


func _update_character_sprite_animation(move_dir: float) -> void:
	if is_attacking:
		visual_root.scale.y = 1.0
		visual_root.position.y = -32.0
		return

	if is_rolling:
		var progress := clampf(1.0 - (_roll_timer / ROLL_DURATION), 0.0, 0.999)
		# Кувырок на 360 градусов вокруг центра тяжести персонажа (y = -32)
		visual_root.rotation = facing_dir * progress * TAU
		visual_root.scale.y = 1.0
		visual_root.position.y = -26.0
		var jmp_tex: Texture2D = _char_sheets.get("jump") as Texture2D
		if jmp_tex:
			var count := maxi(1, int(jmp_tex.get_width() / 128))
			_set_character_sheet("jump", mini(2, count - 1))
		return

	visual_root.rotation = 0.0

	if is_crouching:
		# Плавное приседание с сохранением опоры ног на земле
		visual_root.scale.y = move_toward(visual_root.scale.y, 0.78, 0.08)
		visual_root.position.y = -32.0 * visual_root.scale.y
		var jmp_tex: Texture2D = _char_sheets.get("jump") as Texture2D
		if jmp_tex:
			var count := maxi(1, int(jmp_tex.get_width() / 128))
			_set_character_sheet("jump", clampi(_crouch_frame_index, 0, count - 1))
		return

	visual_root.scale.y = move_toward(visual_root.scale.y, 1.0, 0.1)
	visual_root.position.y = -32.0 * visual_root.scale.y

	if not is_on_floor():
		var jmp_tex: Texture2D = _char_sheets.get("jump") as Texture2D
		if jmp_tex:
			var count := maxi(1, int(jmp_tex.get_width() / 128))
			var air_frame := 2 if velocity.y < 0.0 else mini(count - 1, 4)
			_set_character_sheet("jump", air_frame)
		return

	if absf(velocity.x) > 15.0 and move_dir != 0.0:
		var run_tex: Texture2D = _char_sheets.get("run") as Texture2D
		if run_tex:
			var count := maxi(1, int(run_tex.get_width() / 128))
			var frame := int(_anim_time * 12.0) % count
			_set_character_sheet("run", frame)
	else:
		var idle_tex: Texture2D = _char_sheets.get("idle") as Texture2D
		if idle_tex:
			var count := maxi(1, int(idle_tex.get_width() / 128))
			var frame := int(_anim_time * 6.5) % count
			_set_character_sheet("idle", frame)


func _play_whoosh(f_start: float, f_end: float, duration: float) -> void:
	var sr := 22050
	var count := int(sr * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var p := float(i) / float(count)
		var t := float(i) / float(sr)
		var freq := lerpf(f_start, f_end, p)
		var env := sin(p * PI) * (1.0 - p * 0.5)
		var noise := (randf() * 2.0 - 1.0) * 0.35
		var tone := sin(TAU * freq * t) * 0.35
		var val := int(clampf((noise + tone) * env * 0.55, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, val)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sr
	wav.data = data
	sfx_player.stream = wav
	sfx_player.play()
