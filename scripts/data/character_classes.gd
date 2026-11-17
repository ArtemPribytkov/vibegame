extends RefCounted
class_name CharacterClasses

const CLASSES: Array[Dictionary] = [
	{
		"id": "knight_1",
		"name": "СТРАЖ ПЕПЛА",
		"subtitle": "Рыцарь старого ордена",
		"lore": "Закованный в светлую сталь воин со щитом и полуторным мечом. Несокрушимая стойкость и высокая живучесть в ближнем бою.",
		"folder": "res://assets/characters/knight_1",
		"attack_file": "attack_1.png",
		"attack_2_file": "attack_2.png",
		"hp": 140.0,
		"stamina": 110.0,
		"speed": 235.0,
		"slash_index": 1,
		"slash_name": "Золотой рассекатель",
		"crouch_frame": 0,
	},
	{
		"id": "knight_3",
		"name": "БАГРОВЫЙ ПАЛАЧ",
		"subtitle": "Падший рыцарь крови",
		"lore": "Его латы потемнели от пепла и чужой крови. Жертвует частью защиты ради стремительного натиска и беспощадных ударов.",
		"folder": "res://assets/characters/knight_3",
		"attack_file": "attack_1.png",
		"attack_2_file": "attack_2.png",
		"hp": 125.0,
		"stamina": 125.0,
		"speed": 255.0,
		"slash_index": 4,
		"slash_name": "Тёмное проклятие",
		"crouch_frame": 0,
	},
	{
		"id": "fire_wizard",
		"name": "ПИРОМАНТ-ИЗГНАННИК",
		"subtitle": "Хранитель первородного пламени",
		"lore": "Странник из великих болот, сочетающий фехтование с огненным искусством. Каждый взмах его клинка оставляет шлейф раскалённых углей.",
		"folder": "res://assets/characters/fire_wizard",
		"attack_file": "attack_1.png",
		"attack_2_file": "attack_2.png",
		"hp": 100.0,
		"stamina": 135.0,
		"speed": 260.0,
		"slash_index": 0,
		"slash_name": "Огненный взмах",
		"crouch_frame": 2,
	},
	{
		"id": "lightning_mage",
		"name": "ЖРИЦА ГРОМА",
		"subtitle": "Вестница небесной бури",
		"lore": "Обладает высочайшей скоростью и запасом выносливости. Поражает врагов молниеносными выпадами прежде, чем те успеют замахнуться.",
		"folder": "res://assets/characters/lightning_mage",
		"attack_file": "attack_1.png",
		"attack_2_file": "attack_2.png",
		"hp": 90.0,
		"stamina": 150.0,
		"speed": 275.0,
		"slash_index": 2,
		"slash_name": "Разряд молнии",
		"crouch_frame": 1,
	},
	{
		"id": "wanderer_magican",
		"name": "СТРАННИК БЕЗДНЫ",
		"subtitle": "Тёмный мистик с посохом",
		"lore": "Познавший тайны пустоты отшельник. Управляет потоками эфирного ветра, удерживая врагов на смертоносной дистанции.",
		"folder": "res://assets/characters/wanderer_magican",
		"attack_file": "attack_1.png",
		"attack_2_file": "attack_2.png",
		"hp": 105.0,
		"stamina": 140.0,
		"speed": 260.0,
		"slash_index": 3,
		"slash_name": "Двойной вихрь",
		"crouch_frame": 2,
	},
	{
		"id": "knight_2",
		"name": "СЕВЕРНЫЙ АВАНГАРД",
		"subtitle": "Мечник морозных земель",
		"lore": "Мастер выверенного боя в воронёной броне. Сбалансированный класс для тех, кто полагается на точный тайминг перекатов и ударов.",
		"folder": "res://assets/characters/knight_2",
		"attack_file": "attack_1.png",
		"attack_2_file": "attack_2.png",
		"hp": 130.0,
		"stamina": 120.0,
		"speed": 245.0,
		"slash_index": 5,
		"slash_name": "Ледяной клинок",
		"crouch_frame": 0,
	},
]


static func get_class_by_id(class_id: String) -> Dictionary:
	for cls: Dictionary in CLASSES:
		if String(cls["id"]) == class_id:
			return cls
	return CLASSES[0]


static func load_sheet_texture(res_path: String) -> Texture2D:
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)

	if ResourceLoader.exists(res_path):
		var loaded := load(res_path) as Texture2D
		if loaded:
			return loaded
	return null
