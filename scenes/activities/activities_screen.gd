# res://scenes/activities/activities_screen.gd
# Node: ActivitiesScreen (Control)
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"
const LITTLE_SHOP_SCENE: String = "res://scenes/shop/little_shop.tscn"
const MATH_ACTIVITY_SCENE: String = "res://scenes/play/math_activity.tscn"

const STAR_FILLED: Texture2D = preload("res://assets/ui/star.svg")
const STAR_EMPTY: Texture2D = preload("res://assets/ui/star_empty.svg")

@onready var _back_btn: Button = %BackButton
@onready var _coins_label: Label = %CoinsLabel
@onready var _stars_label: Label = %StarsLabel
@onready var _grid: GridContainer = %Grid

@onready var _shop_tier_label: Label = %ShopTierLabel
@onready var _shop_stars_row: HBoxContainer = %ShopStarsRow
@onready var _play_shop_btn: Button = %PlayShopButton

@onready var _doors_tier_label: Label = %DoorsTierLabel
@onready var _doors_stars_row: HBoxContainer = %DoorsStarsRow
@onready var _play_doors_btn: Button = %PlayDoorsButton

@onready var _builder_tier_label: Label = %BuilderTierLabel
@onready var _builder_stars_row: HBoxContainer = %BuilderStarsRow
@onready var _play_builder_btn: Button = %PlayBuilderButton

@onready var _sharing_tier_label: Label = %SharingTierLabel
@onready var _sharing_stars_row: HBoxContainer = %SharingStarsRow
@onready var _play_sharing_btn: Button = %PlaySharingButton


func _ready() -> void:
	_coins_label.text = str(GameState.coins)
	_stars_label.text = str(GameState.stars)

	_shop_tier_label.text = ShopQuestionGenerator.get_tier_label(GameState.get_activity_tier("little_shop"))
	_doors_tier_label.text = DoorsQuestionGenerator.get_tier_label(GameState.get_activity_tier("puzzle_doors"))
	_builder_tier_label.text = BuilderQuestionGenerator.get_tier_label(GameState.get_activity_tier("little_builder"))
	_sharing_tier_label.text = SharingQuestionGenerator.get_tier_label(GameState.get_activity_tier("fair_sharing"))

	_populate_stars(_shop_stars_row, int(GameState.activity_stars.get("little_shop", 0)))
	_populate_stars(_doors_stars_row, int(GameState.activity_stars.get("puzzle_doors", 0)))
	_populate_stars(_builder_stars_row, int(GameState.activity_stars.get("little_builder", 0)))
	_populate_stars(_sharing_stars_row, int(GameState.activity_stars.get("fair_sharing", 0)))

	_back_btn.pressed.connect(_go_back)
	_play_shop_btn.pressed.connect(_launch_activity.bind("little_shop"))
	_play_doors_btn.pressed.connect(_launch_activity.bind("puzzle_doors"))
	_play_builder_btn.pressed.connect(_launch_activity.bind("little_builder"))
	_play_sharing_btn.pressed.connect(_launch_activity.bind("fair_sharing"))

	_play_shop_btn.grab_focus()
	if not GameState.reduce_motion:
		_animate_cards_in()


func _animate_cards_in() -> void:
	var cards: Array[Node] = _grid.get_children()
	for i: int in cards.size():
		var card: Control = cards[i] as Control
		if card == null:
			continue
		card.modulate.a = 0.0
		card.pivot_offset = card.custom_minimum_size * 0.5
		card.scale = Vector2(0.94, 0.94)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.22).set_delay(0.05 * float(i))
		tween.tween_property(card, "scale", Vector2.ONE, 0.26).set_delay(0.05 * float(i)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
	GameState.change_scene(MAIN_MENU_SCENE)
