# res://scenes/activities/activities_screen.gd
# Node: ActivitiesScreen (Control)
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"
const LITTLE_SHOP_SCENE: String = "res://scenes/shop/little_shop.tscn"
const MATH_ACTIVITY_SCENE: String = "res://scenes/play/math_activity.tscn"

const STAR_FILLED: Texture2D = preload("res://assets/ui/star.svg")
const STAR_EMPTY: Texture2D = preload("res://assets/ui/star_empty.svg")
const PAGE_SIZE: int = 4
const PAGE_TWO_IDS: Array[String] = ["number_patterns", "clock_time", "rocket_shapes", "coin_jar"]

@onready var _back_btn: Button = %BackButton
@onready var _coins_label: Label = %CoinsLabel
@onready var _stars_label: Label = %StarsLabel
@onready var _grid: GridContainer = %Grid
@onready var _prev_page_btn: Button = %PrevPageButton
@onready var _next_page_btn: Button = %NextPageButton
@onready var _page_label: Label = %PageLabel

@onready var _shop_tier_label: Label = %ShopTierLabel
@onready var _shop_stars_row: HBoxContainer = %ShopStarsRow
@onready var _shop_prev_btn: Button = %ShopPrevLevelButton
@onready var _shop_level_badge: Label = %ShopLevelBadge
@onready var _shop_next_btn: Button = %ShopNextLevelButton
@onready var _play_shop_btn: Button = %PlayShopButton

@onready var _doors_tier_label: Label = %DoorsTierLabel
@onready var _doors_stars_row: HBoxContainer = %DoorsStarsRow
@onready var _doors_prev_btn: Button = %DoorsPrevLevelButton
@onready var _doors_level_badge: Label = %DoorsLevelBadge
@onready var _doors_next_btn: Button = %DoorsNextLevelButton
@onready var _play_doors_btn: Button = %PlayDoorsButton

@onready var _builder_tier_label: Label = %BuilderTierLabel
@onready var _builder_stars_row: HBoxContainer = %BuilderStarsRow
@onready var _builder_prev_btn: Button = %BuilderPrevLevelButton
@onready var _builder_level_badge: Label = %BuilderLevelBadge
@onready var _builder_next_btn: Button = %BuilderNextLevelButton
@onready var _play_builder_btn: Button = %PlayBuilderButton

@onready var _sharing_tier_label: Label = %SharingTierLabel
@onready var _sharing_stars_row: HBoxContainer = %SharingStarsRow
@onready var _sharing_prev_btn: Button = %SharingPrevLevelButton
@onready var _sharing_level_badge: Label = %SharingLevelBadge
@onready var _sharing_next_btn: Button = %SharingNextLevelButton
@onready var _play_sharing_btn: Button = %PlaySharingButton

@onready var _patterns_tier_label: Label = %PatternsTierLabel
@onready var _patterns_stars_row: HBoxContainer = %PatternsStarsRow
@onready var _patterns_prev_btn: Button = %PatternsPrevLevelButton
@onready var _patterns_level_badge: Label = %PatternsLevelBadge
@onready var _patterns_next_btn: Button = %PatternsNextLevelButton
@onready var _play_patterns_btn: Button = %PlayPatternsButton

@onready var _time_tier_label: Label = %TimeTierLabel
@onready var _time_stars_row: HBoxContainer = %TimeStarsRow
@onready var _time_prev_btn: Button = %TimePrevLevelButton
@onready var _time_level_badge: Label = %TimeLevelBadge
@onready var _time_next_btn: Button = %TimeNextLevelButton
@onready var _play_time_btn: Button = %PlayTimeButton

@onready var _shapes_tier_label: Label = %ShapesTierLabel
@onready var _shapes_stars_row: HBoxContainer = %ShapesStarsRow
@onready var _shapes_prev_btn: Button = %ShapesPrevLevelButton
@onready var _shapes_level_badge: Label = %ShapesLevelBadge
@onready var _shapes_next_btn: Button = %ShapesNextLevelButton
@onready var _play_shapes_btn: Button = %PlayShapesButton

@onready var _coin_jar_tier_label: Label = %CoinJarTierLabel
@onready var _coin_jar_stars_row: HBoxContainer = %CoinJarStarsRow
@onready var _coin_jar_prev_btn: Button = %CoinJarPrevLevelButton
@onready var _coin_jar_level_badge: Label = %CoinJarLevelBadge
@onready var _coin_jar_next_btn: Button = %CoinJarNextLevelButton
@onready var _play_coin_jar_btn: Button = %PlayCoinJarButton

var _card_controls: Dictionary = {}
var _current_page: int = 0
var _page_count: int = 2


func _ready() -> void:
	_coins_label.text = str(GameState.coins)
	_stars_label.text = str(GameState.stars)

	_card_controls = {
		"little_shop": {
			"tier_label": _shop_tier_label,
			"stars_row": _shop_stars_row,
			"prev_btn": _shop_prev_btn,
			"badge": _shop_level_badge,
			"next_btn": _shop_next_btn,
			"play_btn": _play_shop_btn,
		},
		"puzzle_doors": {
			"tier_label": _doors_tier_label,
			"stars_row": _doors_stars_row,
			"prev_btn": _doors_prev_btn,
			"badge": _doors_level_badge,
			"next_btn": _doors_next_btn,
			"play_btn": _play_doors_btn,
		},
		"little_builder": {
			"tier_label": _builder_tier_label,
			"stars_row": _builder_stars_row,
			"prev_btn": _builder_prev_btn,
			"badge": _builder_level_badge,
			"next_btn": _builder_next_btn,
			"play_btn": _play_builder_btn,
		},
		"fair_sharing": {
			"tier_label": _sharing_tier_label,
			"stars_row": _sharing_stars_row,
			"prev_btn": _sharing_prev_btn,
			"badge": _sharing_level_badge,
			"next_btn": _sharing_next_btn,
			"play_btn": _play_sharing_btn,
		},
		"number_patterns": {
			"tier_label": _patterns_tier_label,
			"stars_row": _patterns_stars_row,
			"prev_btn": _patterns_prev_btn,
			"badge": _patterns_level_badge,
			"next_btn": _patterns_next_btn,
			"play_btn": _play_patterns_btn,
		},
		"clock_time": {
			"tier_label": _time_tier_label,
			"stars_row": _time_stars_row,
			"prev_btn": _time_prev_btn,
			"badge": _time_level_badge,
			"next_btn": _time_next_btn,
			"play_btn": _play_time_btn,
		},
		"rocket_shapes": {
			"tier_label": _shapes_tier_label,
			"stars_row": _shapes_stars_row,
			"prev_btn": _shapes_prev_btn,
			"badge": _shapes_level_badge,
			"next_btn": _shapes_next_btn,
			"play_btn": _play_shapes_btn,
		},
		"coin_jar": {
			"tier_label": _coin_jar_tier_label,
			"stars_row": _coin_jar_stars_row,
			"prev_btn": _coin_jar_prev_btn,
			"badge": _coin_jar_level_badge,
			"next_btn": _coin_jar_next_btn,
			"play_btn": _play_coin_jar_btn,
		},
	}

	_back_btn.pressed.connect(_go_back)
	_prev_page_btn.pressed.connect(_change_page.bind(-1))
	_next_page_btn.pressed.connect(_change_page.bind(1))
	for activity_id: String in _card_controls:
		var ctrl: Dictionary = _card_controls[activity_id]
		(ctrl["prev_btn"] as Button).pressed.connect(_change_activity_level.bind(activity_id, -1))
		(ctrl["next_btn"] as Button).pressed.connect(_change_activity_level.bind(activity_id, 1))
		(ctrl["play_btn"] as Button).pressed.connect(_launch_activity.bind(activity_id))
		_populate_stars(ctrl["stars_row"] as HBoxContainer, int(GameState.activity_stars.get(activity_id, 0)))
		_refresh_activity_level(activity_id)

	_page_count = maxi(1, ceili(float(_grid.get_child_count()) / float(PAGE_SIZE)))
	_current_page = 1 if GameState.active_activity_id in PAGE_TWO_IDS else 0
	_apply_page()
	if _current_page == 0:
		_play_shop_btn.grab_focus()
	else:
		_play_patterns_btn.grab_focus()


func _change_activity_level(activity_id: String, delta: int) -> void:
	var current: int = GameState.get_activity_tier(activity_id)
	var updated: int = clampi(current + delta, 1, GameState.MAX_ACTIVITY_TIER)
	if updated == current:
		return
	GameState.set_activity_tier(activity_id, updated, true)
	_refresh_activity_level(activity_id)


func _refresh_activity_level(activity_id: String) -> void:
	var ctrl: Dictionary = _card_controls[activity_id]
	var tier: int = GameState.get_activity_tier(activity_id)
	(ctrl["tier_label"] as Label).text = _get_tier_label(activity_id, tier)
	(ctrl["badge"] as Label).text = "Lvl %d/%d" % [tier, GameState.MAX_ACTIVITY_TIER]
	(ctrl["prev_btn"] as Button).disabled = tier <= 1
	(ctrl["next_btn"] as Button).disabled = tier >= GameState.MAX_ACTIVITY_TIER


func _get_tier_label(activity_id: String, tier: int) -> String:
	return GameState.get_activity_tier_label(activity_id, tier)


func _change_page(delta: int) -> void:
	var updated: int = clampi(_current_page + delta, 0, _page_count - 1)
	if updated == _current_page:
		return
	var prev_had_focus: bool = _prev_page_btn.has_focus()
	var next_had_focus: bool = _next_page_btn.has_focus()
	_current_page = updated
	_apply_page()
	if _prev_page_btn.disabled and prev_had_focus:
		_play_shop_btn.grab_focus()
	elif _next_page_btn.disabled and next_had_focus:
		_play_patterns_btn.grab_focus()


func _apply_page() -> void:
	var cards: Array[Node] = _grid.get_children()
	var start_idx: int = _current_page * PAGE_SIZE
	var end_idx: int = mini(cards.size(), start_idx + PAGE_SIZE)
	for i: int in cards.size():
		var card: Control = cards[i] as Control
		if card != null:
			card.visible = i >= start_idx and i < end_idx
			card.modulate.a = 1.0
			card.scale = Vector2.ONE

	_prev_page_btn.disabled = _current_page <= 0
	_next_page_btn.disabled = _current_page >= _page_count - 1
	_page_label.text = "Activities %d–%d   •   Page %d of %d" % [start_idx + 1, end_idx, _current_page + 1, _page_count]

	if not GameState.reduce_motion:
		_animate_cards_in()


func _animate_cards_in() -> void:
	var cards: Array[Node] = _grid.get_children()
	var visible_index: int = 0
	for card_node: Node in cards:
		var card: Control = card_node as Control
		if card == null or not card.visible:
			continue
		card.modulate.a = 0.0
		card.pivot_offset = card.custom_minimum_size * 0.5
		card.scale = Vector2(0.94, 0.94)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.22).set_delay(0.05 * float(visible_index))
		tween.tween_property(card, "scale", Vector2.ONE, 0.26).set_delay(0.05 * float(visible_index)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		visible_index += 1


func _populate_stars(row: HBoxContainer, filled_count: int) -> void:
	var icons: Array[Node] = row.get_children()
	for i: int in icons.size():
		var rect: TextureRect = icons[i] as TextureRect
		if rect != null:
			rect.texture = STAR_FILLED if i < filled_count else STAR_EMPTY


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		GameState.play_sfx(&"back")
		_go_back()


func _launch_activity(activity_id: String) -> void:
	GameState.active_activity_id = activity_id
	if activity_id == "little_shop":
		GameState.change_scene(LITTLE_SHOP_SCENE)
	else:
		GameState.change_scene(MATH_ACTIVITY_SCENE)


func _go_back() -> void:
	GameState.active_activity_id = "little_shop"
	GameState.change_scene(MAIN_MENU_SCENE)
