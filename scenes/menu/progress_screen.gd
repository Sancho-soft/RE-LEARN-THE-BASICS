# res://scenes/menu/progress_screen.gd
# Node: ProgressScreen (Control)
# Displays lifetime math mastery across all 4 activities + Sticker Shop coin sink.
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"
const JUICY_BUTTON_SCRIPT: Script = preload("res://scenes/components/juicy_button.gd")

@onready var _back_btn: Button = %BackButton
@onready var _coins_label: Label = %CoinsLabel
@onready var _stars_label: Label = %StarsLabel
@onready var _solved_label: Label = %SolvedLabel
@onready var _mastery_list: VBoxContainer = %MasteryList
@onready var _sticker_grid: GridContainer = %StickerGrid


func _ready() -> void:
	_back_btn.pressed.connect(_go_back)
	GameState.stats_changed.connect(_on_stats_changed)
	_refresh_all()
	_back_btn.grab_focus()


func _on_stats_changed(_c: int, _s: int) -> void:
	_refresh_all()


func _refresh_all() -> void:
	_coins_label.text = str(GameState.coins)
	_stars_label.text = "%d / %d" % [GameState.stars, GameState.activity_stars.size() * 3]
	_solved_label.text = "Questions Solved: %d" % GameState.total_solved
	_rebuild_mastery_list()
	_rebuild_sticker_grid()


func _rebuild_mastery_list() -> void:
	for child: Node in _mastery_list.get_children():
		child.queue_free()

	var activities: Array[Dictionary] = [
		{"id": "little_shop", "name": "1. The Little Shop"},
		{"id": "puzzle_doors", "name": "2. Puzzle Doors"},
		{"id": "little_builder", "name": "3. Little Builder"},
		{"id": "fair_sharing", "name": "4. Fair Sharing"},
		{"id": "number_patterns", "name": "5. Number Patterns"},
		{"id": "clock_time", "name": "6. Clock & Time"},
		{"id": "rocket_shapes", "name": "7. Rocket Shapes"},
		{"id": "coin_jar", "name": "8. Coin Jar"},
	]

	for act: Dictionary in activities:
		var act_id: String = str(act["id"])
		var star_count: int = int(GameState.activity_stars.get(act_id, 0))
		var star_str: String = "★".repeat(star_count) + "☆".repeat(3 - star_count)

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var title: Label = Label.new()
		title.text = str(act["name"])
		title.add_theme_font_size_override("font_size", 19)

		var tier_lbl: Label = Label.new()
		tier_lbl.text = GameState.get_activity_tier_label(act_id)
		tier_lbl.add_theme_font_size_override("font_size", 14)
		tier_lbl.add_theme_color_override("font_color", Color(0.129412, 0.619608, 0.737255, 1.0))

		info.add_child(title)
		info.add_child(tier_lbl)

		var stars_lbl: Label = Label.new()
		stars_lbl.text = star_str
		stars_lbl.add_theme_font_size_override("font_size", 22)
		stars_lbl.add_theme_color_override("font_color", Color(0.92, 0.65, 0.08, 1.0))

		row.add_child(info)
		row.add_child(stars_lbl)
		_mastery_list.add_child(row)


func _rebuild_sticker_grid() -> void:
	for child: Node in _sticker_grid.get_children():
		child.queue_free()

	for item: Dictionary in GameState.STICKER_CATALOG:
		var sid: String = str(item["id"])
		var sname: String = str(item["name"])
		var cost: int = int(item["cost"])
		var icon_path: String = str(item["icon"])
		var unlocked: bool = sid in GameState.unlocked_stickers
		var equipped: bool = GameState.equipped_sticker == sid

		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(180, 185)

		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 8)

		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(68, 68)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.texture = load(icon_path) as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not unlocked:
			icon.modulate = Color(0.75, 0.78, 0.82, 0.7)

		var name_lbl: Label = Label.new()
		name_lbl.text = sname
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 19)

		var btn: Button = Button.new()
		btn.set_script(JUICY_BUTTON_SCRIPT)
		btn.add_theme_font_size_override("font_size", 18)

		if equipped:
			btn.text = "Pinned ★"
			btn.disabled = true
		elif unlocked:
			btn.text = "Pin Badge"
			btn.pressed.connect(_on_equip_sticker.bind(sid))
		elif GameState.coins >= cost:
			btn.text = "Buy ₱%d" % cost
			btn.pressed.connect(_on_buy_sticker.bind(sid))
		else:
			btn.text = "₱%d" % cost
			btn.disabled = true

		vbox.add_child(icon)
		vbox.add_child(name_lbl)
		vbox.add_child(btn)
		card.add_child(vbox)
		_sticker_grid.add_child(card)


func _on_buy_sticker(sid: String) -> void:
	if GameState.unlock_sticker(sid):
		GameState.play_sfx(&"correct")


func _on_equip_sticker(sid: String) -> void:
	GameState.equip_sticker(sid)
	GameState.play_sfx(&"toggle")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		GameState.play_sfx(&"back")
		_go_back()


func _go_back() -> void:
	GameState.change_scene(MAIN_MENU_SCENE)
