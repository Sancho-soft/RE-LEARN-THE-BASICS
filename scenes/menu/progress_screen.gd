# res://scenes/menu/progress_screen.gd
# Node: ProgressScreen (Control)
# Displays lifetime math mastery across all 8 activities + Sticker Shop coin sink.
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"
const JUICY_BUTTON_SCRIPT: Script = preload("res://scenes/components/juicy_button.gd")
const STAR_FILLED: Texture2D = preload("res://assets/ui/star.svg")
const STAR_RAINBOW: Texture2D = preload("res://assets/ui/star_rainbow.svg")
const COIN_ICON: Texture2D = preload("res://assets/ui/coin.svg")
const STICKERS_PER_PAGE: int = 6

@onready var _back_btn: Button = %BackButton
@onready var _coins_label: Label = %CoinsLabel
@onready var _stars_label: Label = %StarsLabel
@onready var _solved_label: Label = %SolvedLabel
@onready var _mastery_list: VBoxContainer = %MasteryList
@onready var _subtitle_label: Label = %Subtitle
@onready var _sticker_grid: GridContainer = %StickerGrid
@onready var _prev_sticker_btn: Button = %PrevStickerPageButton
@onready var _sticker_page_label: Label = %StickerPageLabel
@onready var _next_sticker_btn: Button = %NextStickerPageButton

var _sticker_page: int = 0
var _sticker_page_count: int = 2


func _ready() -> void:
	GameState.set_bgm_context(&"menu")
	_sticker_page_count = maxi(1, ceili(float(GameState.STICKER_CATALOG.size()) / float(STICKERS_PER_PAGE)))
	_back_btn.pressed.connect(_go_back)
	_prev_sticker_btn.pressed.connect(_change_sticker_page.bind(-1))
	_next_sticker_btn.pressed.connect(_change_sticker_page.bind(1))
	GameState.stats_changed.connect(_on_stats_changed)
	_refresh_all()


func _on_stats_changed(_c: int, _s: int) -> void:
	_refresh_all()


func _refresh_all() -> void:
	_coins_label.text = str(GameState.coins)
	_stars_label.text = "%d / %d" % [GameState.stars, GameState.get_max_total_stars()]
	_solved_label.text = "Questions Solved: %d" % GameState.total_solved
	_subtitle_label.text = "Collected %d / %d stickers • Pin one next to Pip!" % [
		GameState.unlocked_stickers.size(), GameState.STICKER_CATALOG.size()
	]
	_rebuild_mastery_list()
	_rebuild_sticker_grid()


func _change_sticker_page(delta: int) -> void:
	var updated: int = clampi(_sticker_page + delta, 0, _sticker_page_count - 1)
	if updated == _sticker_page:
		return
	_sticker_page = updated
	_rebuild_sticker_grid()


func _rebuild_mastery_list() -> void:
	for child: Node in _mastery_list.get_children():
		child.queue_free()

	_mastery_list.add_theme_constant_override("separation", 3)
	var activities: Array[Dictionary] = [
		{"id": "little_shop", "name": "1. The Little Shop"},
		{"id": "puzzle_doors", "name": "2. Puzzle Doors"},
		{"id": "little_builder", "name": "3. Little Builder"},
		{"id": "fair_sharing", "name": "4. Fair Sharing"},
		{"id": "number_patterns", "name": "5. Number Patterns"},
		{"id": "clock_time", "name": "6. Clock & Time"},
		{"id": "rocket_shapes", "name": "7. Rocket Shapes"},
		{"id": "coin_jar", "name": "8. Coin Jar"},
		{"id": "balance_scale", "name": "9. Balance Scale"},
		{"id": "number_forge", "name": "10. Number Forge"},
	]

	for act: Dictionary in activities:
		var act_id: String = str(act["id"])
		var star_count: int = GameState.get_activity_total_stars(act_id)
		var max_act_stars: int = GameState.get_max_activity_stars()
		var levels_cleared: int = GameState.get_activity_completed_levels(act_id)
		var max_done: bool = GameState.has_finished_max_level(act_id)

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)

		var title: Label = Label.new()
		title.text = str(act["name"])
		title.add_theme_font_size_override("font_size", 16)

		var tier_lbl: Label = Label.new()
		tier_lbl.text = GameState.get_activity_tier_label(act_id)
		tier_lbl.add_theme_font_size_override("font_size", 12)
		tier_lbl.add_theme_color_override("font_color", Color(0.129412, 0.619608, 0.737255, 1.0))

		info.add_child(title)
		info.add_child(tier_lbl)

		var stars_col: VBoxContainer = VBoxContainer.new()
		stars_col.alignment = BoxContainer.ALIGNMENT_CENTER
		stars_col.add_theme_constant_override("separation", 0)

		var stars_top: HBoxContainer = HBoxContainer.new()
		stars_top.alignment = BoxContainer.ALIGNMENT_END
		stars_top.add_theme_constant_override("separation", 5)

		var stars_lbl: Label = Label.new()
		stars_lbl.text = "%d / %d" % [star_count, max_act_stars]
		stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stars_lbl.add_theme_font_size_override("font_size", 16)
		stars_lbl.add_theme_color_override("font_color", Color(0.55, 0.30, 0.88, 1.0) if max_done else Color(0.92, 0.65, 0.08, 1.0))

		var star_icon: TextureRect = TextureRect.new()
		star_icon.custom_minimum_size = Vector2(18, 18)
		star_icon.texture = STAR_RAINBOW if max_done else STAR_FILLED
		star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		stars_top.add_child(stars_lbl)
		stars_top.add_child(star_icon)

		var levels_lbl: Label = Label.new()
		levels_lbl.text = "%d / %d lvls%s" % [levels_cleared, GameState.MAX_ACTIVITY_TIER, " ★" if max_done else ""]
		levels_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		levels_lbl.add_theme_font_size_override("font_size", 12)
		levels_lbl.add_theme_color_override("font_color", Color(0.32, 0.42, 0.48, 1.0))

		stars_col.add_child(stars_top)
		stars_col.add_child(levels_lbl)

		row.add_child(info)
		row.add_child(stars_col)
		_mastery_list.add_child(row)


func _rebuild_sticker_grid() -> void:
	for child: Node in _sticker_grid.get_children():
		child.queue_free()

	var total_items: int = GameState.STICKER_CATALOG.size()
	var start_idx: int = _sticker_page * STICKERS_PER_PAGE
	var end_idx: int = mini(total_items, start_idx + STICKERS_PER_PAGE)

	_prev_sticker_btn.disabled = _sticker_page <= 0
	_next_sticker_btn.disabled = _sticker_page >= _sticker_page_count - 1
	var page_themes: Array[String] = ["Cozy Classics", "Deluxe Friends", "Animated Legends"]
	var page_theme: String = page_themes[_sticker_page] if _sticker_page < page_themes.size() else "Deluxe Stickers"
	_sticker_page_label.text = "Page %d / %d • %s" % [_sticker_page + 1, _sticker_page_count, page_theme]

	for idx: int in range(start_idx, end_idx):
		var item: Dictionary = GameState.STICKER_CATALOG[idx]
		var sid: String = str(item["id"])
		var sname: String = str(item["name"])
		var cost: int = int(item["cost"])
		var is_animated: bool = bool(item.get("animated", false))
		var unlocked: bool = sid in GameState.unlocked_stickers
		var equipped: bool = GameState.equipped_sticker == sid

		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(174, 174)
		var card_style: StyleBoxFlat = StyleBoxFlat.new()
		card_style.content_margin_left = 10.0
		card_style.content_margin_top = 8.0
		card_style.content_margin_right = 10.0
		card_style.content_margin_bottom = 8.0
		card_style.bg_color = Color(0.96, 0.92, 1.0, 1.0) if is_animated else Color(1.0, 0.985, 0.94, 1.0)
		card_style.border_width_left = 4
		card_style.border_width_top = 4
		card_style.border_width_right = 4
		card_style.border_width_bottom = 6
		card_style.border_color = Color(0.55, 0.30, 0.88, 1.0) if is_animated else Color(0.184314, 0.282353, 0.345098, 1.0)
		card_style.corner_radius_top_left = 20
		card_style.corner_radius_top_right = 20
		card_style.corner_radius_bottom_right = 20
		card_style.corner_radius_bottom_left = 20
		card.add_theme_stylebox_override("panel", card_style)

		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 4)

		var badge_lbl: Label = Label.new()
		badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_lbl.add_theme_font_size_override("font_size", 12)
		if is_animated:
			badge_lbl.text = "ANIMATED"
			badge_lbl.add_theme_color_override("font_color", Color(0.55, 0.30, 0.88, 1.0))
		else:
			badge_lbl.text = "STICKER"
			badge_lbl.add_theme_color_override("font_color", Color(0.32, 0.42, 0.48, 0.7))

		var icon_view: StickerView = StickerView.new()
		vbox.add_child(badge_lbl)
		vbox.add_child(icon_view)
		icon_view.setup_sticker(sid, Vector2(56, 56), not unlocked, equipped)

		var name_lbl: Label = Label.new()
		name_lbl.text = sname
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 17)

		var btn: Button = Button.new()
		btn.set_script(JUICY_BUTTON_SCRIPT)
		btn.add_theme_font_size_override("font_size", 16)

		if equipped:
			btn.text = "Pinned ★"
			btn.disabled = true
		elif unlocked:
			btn.text = "Pin Badge"
			btn.pressed.connect(_on_equip_sticker.bind(sid))
		elif GameState.coins >= cost:
			btn.icon = COIN_ICON
			btn.expand_icon = true
			btn.text = "Buy %d" % cost
			btn.pressed.connect(_on_buy_sticker.bind(sid))
		else:
			btn.icon = COIN_ICON
			btn.expand_icon = true
			btn.text = "%d" % cost
			btn.disabled = true

		if is_animated and not equipped:
			card.mouse_entered.connect(func() -> void: icon_view.set_anim_active(true))
			card.mouse_exited.connect(func() -> void: icon_view.set_anim_active(false))
			btn.mouse_entered.connect(func() -> void: icon_view.set_anim_active(true))
			btn.mouse_exited.connect(func() -> void: icon_view.set_anim_active(false))
			btn.focus_entered.connect(func() -> void: icon_view.set_anim_active(true))
			btn.focus_exited.connect(func() -> void: icon_view.set_anim_active(false))

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
