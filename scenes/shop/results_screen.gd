# res://scenes/shop/results_screen.gd
# Node: ResultsScreen (Control)
extends Control

const LITTLE_SHOP_SCENE: String = "res://scenes/shop/little_shop.tscn"
const MATH_ACTIVITY_SCENE: String = "res://scenes/play/math_activity.tscn"
const ACTIVITIES_SCENE: String = "res://scenes/activities/activities_screen.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"

const STAR_FILLED: Texture2D = preload("res://assets/ui/star.svg")
const STAR_EMPTY: Texture2D = preload("res://assets/ui/star_empty.svg")
const SPARKLE_TEX: Texture2D = preload("res://assets/art/sparkle.svg")
const MASCOT_IDLE: Texture2D = preload("res://assets/art/mascot.svg")
const MASCOT_TALK: Texture2D = preload("res://assets/art/mascot_talk.svg")

@onready var _mascot: TextureRect = %MascotTexture
@onready var _title_label: Label = %TitleLabel
@onready var _mascot_speech_label: Label = %MascotSpeechLabel
@onready var _stars_row: HBoxContainer = %StarsRow
@onready var _coins_earned_label: Label = %CoinsEarnedLabel
@onready var _detail_label: Label = %DetailLabel
@onready var _totals_label: Label = %TotalsLabel

@onready var _play_again_btn: Button = %PlayAgainButton
@onready var _activities_btn: Button = %ActivitiesButton
@onready var _menu_btn: Button = %MenuButton

var _activity_id: String = "little_shop"


func _ready() -> void:
	_populate_summary()
	_play_again_btn.pressed.connect(_on_play_again)
	_activities_btn.pressed.connect(func() -> void: GameState.change_scene(ACTIVITIES_SCENE))
	_menu_btn.pressed.connect(func() -> void: GameState.change_scene(MAIN_MENU_SCENE))
	_play_again_btn.grab_focus()


func _on_play_again() -> void:
	GameState.active_activity_id = _activity_id
	if _activity_id == "little_shop":
		GameState.change_scene(LITTLE_SHOP_SCENE)
	else:
		GameState.change_scene(MATH_ACTIVITY_SCENE)


func _get_tier_text(activity_id: String, tier: int) -> String:
	match activity_id:
		"little_shop":
			return ShopQuestionGenerator.get_tier_label(tier)
		"puzzle_doors":
			return DoorsQuestionGenerator.get_tier_label(tier)
		"little_builder":
			return BuilderQuestionGenerator.get_tier_label(tier)
		"fair_sharing":
			return SharingQuestionGenerator.get_tier_label(tier)
	return "Level %d" % tier


func _populate_summary() -> void:
	var summary: Dictionary = GameState.last_run_summary
	_activity_id = str(summary.get("activity_id", "little_shop"))
	var activity_name: String = str(summary.get("activity_name", "The Little Shop"))
	var earned_coins: int = int(summary.get("coins_earned", 0))
	var earned_stars: int = int(summary.get("stars_earned", 1))
	var clean: int = int(summary.get("clean_answers", 0))
	var total_q: int = int(summary.get("total_questions", 8))
	var tier: int = int(summary.get("tier_reached", GameState.get_activity_tier(_activity_id)))

	var cheer_line: String = "You finished the whole round! That takes real heart!"
	match earned_stars:
		3:
			_title_label.text = "%s: SUPER!" % activity_name.to_upper()
			cheer_line = "Hooray! You shone like a true math star today!"
		2:
			_title_label.text = "%s: GREAT!" % activity_name.to_upper()
			cheer_line = "Great teamwork! Every round gets smoother and brighter!"
		_:
			_title_label.text = "%s COMPLETE!" % activity_name.to_upper()

	var talker: TalkingAvatar = TalkingAvatar.new()
	add_child(talker)
	talker.setup(_mascot, _mascot_speech_label, MASCOT_IDLE, MASCOT_TALK)
	talker.say(cheer_line)
	talker.react_happy()

	_detail_label.text = "Solved %d / %d smoothly  •  %s" % [clean, total_q, _get_tier_text(_activity_id, tier)]
	_totals_label.text = "Total Saved:  %d Coins   |   %d Stars" % [GameState.coins, GameState.stars]

	if GameState.reduce_motion or earned_coins <= 0:
		_coins_earned_label.text = "+%d Coins Earned!" % earned_coins
	else:
		_coins_earned_label.text = "+0 Coins Earned!"
		var coin_tween: Tween = create_tween()
		coin_tween.tween_method(_set_coin_rollup, 0, earned_coins, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var star_nodes: Array[Node] = _stars_row.get_children()
	for i: int in star_nodes.size():
		var rect: TextureRect = star_nodes[i] as TextureRect
		if rect == null:
			continue
		var is_earned: bool = i < earned_stars
		rect.texture = STAR_FILLED if is_earned else STAR_EMPTY
		if is_earned and not GameState.reduce_motion:
			rect.pivot_offset = rect.custom_minimum_size * 0.5
			rect.scale = Vector2.ZERO
			var tween: Tween = create_tween()
			tween.tween_interval(0.15 * float(i))
			tween.tween_property(rect, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_callback(_play_star_sparkle.bind(rect))


func _set_coin_rollup(val: int) -> void:
	_coins_earned_label.text = "+%d Coins Earned!" % val


func _play_star_sparkle(star_rect: TextureRect) -> void:
	if not is_inside_tree():
		return
	GameState.play_sfx(&"toggle", -4.0)
	var spr: TextureRect = TextureRect.new()
	spr.texture = SPARKLE_TEX
	spr.custom_minimum_size = Vector2(28, 28)
	spr.size = Vector2(28, 28)
	spr.pivot_offset = Vector2(14, 14)
	spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spr.global_position = star_rect.global_position + Vector2(star_rect.size.x * 0.5 - 14.0, -10.0)
	spr.scale = Vector2.ZERO
	add_child(spr)

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(spr, "position:y", spr.position.y - 26.0, 0.45).set_ease(Tween.EASE_OUT)
	tween.tween_property(spr, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(spr, "modulate:a", 0.0, 0.25).set_delay(0.22)
	tween.chain().tween_callback(spr.queue_free)
