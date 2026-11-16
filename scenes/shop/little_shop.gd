# res://scenes/shop/little_shop.gd
# Node: LittleShop (Control)
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"
const RESULTS_SCENE: String = "res://scenes/shop/results_screen.tscn"
const QUESTIONS_PER_SHIFT: int = 8

const CUSTOMERS: Array[Texture2D] = [
	preload("res://assets/art/customer_bunny.svg"),
	preload("res://assets/art/customer_bear.svg"),
]
const CUSTOMER_TALK: Array[Texture2D] = [
	preload("res://assets/art/customer_bunny_talk.svg"),
	preload("res://assets/art/customer_bear_talk.svg"),
]
const COIN_ICON: Texture2D = preload("res://assets/ui/coin.svg")
const SPARKLE_TEX: Texture2D = preload("res://assets/art/sparkle.svg")

@onready var _menu_btn: Button = %MenuButton
@onready var _progress_label: Label = %ProgressLabel
@onready var _tier_label: Label = %TierLabel
@onready var _coins_panel: PanelContainer = %CoinsPanel
@onready var _session_coins_label: Label = %SessionCoinsLabel

@onready var _customer_card: PanelContainer = %CustomerCard
@onready var _customer_icon: TextureRect = %CustomerIcon
@onready var _speech_label: Label = %SpeechLabel

@onready var _left_item: PanelContainer = %LeftItem
@onready var _left_icon: TextureRect = %LeftIcon
@onready var _left_name: Label = %LeftName
@onready var _left_price: Label = %LeftPrice
@onready var _operator_label: Label = %OperatorLabel
@onready var _right_item: PanelContainer = %RightItem
@onready var _right_icon: TextureRect = %RightIcon
@onready var _right_name: Label = %RightName
@onready var _right_price: Label = %RightPrice
@onready var _expression_label: Label = %ExpressionLabel

@onready var _feedback_panel: PanelContainer = %FeedbackPanel
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _hint_btn: Button = %HintButton
@onready var _number_pad: NumberPad = %NumberPad

var _question_index: int = 0
var _current_tier: int = 1
var _current_question: MathQuestion
var _attempts_on_question: int = 0
var _hint_shown: bool = false

var _session_coins: int = 0
var _clean_answers: int = 0 # Answered within first try or first retry
var _correct_streak: int = 0
var _miss_streak: int = 0
var _last_answer: int = -1
var _talker: TalkingAvatar
var _bob_time: float = 0.0


func _ready() -> void:
	_current_tier = clampi(GameState.shop_tier, 1, GameState.MAX_ACTIVITY_TIER)
	_talker = TalkingAvatar.new()
	add_child(_talker)
	_talker.setup(_customer_icon, _speech_label, CUSTOMERS[0], CUSTOMER_TALK[0])
	_menu_btn.pressed.connect(_on_menu_pressed)
	_hint_btn.pressed.connect(_on_hint_pressed)
	_number_pad.answer_submitted.connect(_on_answer_submitted)
	_load_next_question()


func _process(delta: float) -> void:
	if GameState.reduce_motion:
		_left_icon.rotation = 0.0
		_right_icon.rotation = 0.0
		return
	_bob_time += delta
	_left_icon.pivot_offset = _left_icon.size * 0.5
	_right_icon.pivot_offset = _right_icon.size * 0.5
	_left_icon.rotation = sin(_bob_time * 2.1) * 0.05
	_right_icon.rotation = sin(_bob_time * 2.1 + 1.6) * 0.05


func _load_next_question() -> void:
	_question_index += 1
	if _question_index > QUESTIONS_PER_SHIFT:
		_finish_shift()
		return

	_attempts_on_question = 0
	_hint_shown = false
	_hint_btn.disabled = false
	_number_pad.clear_input()
	_number_pad.set_locked(false)

	# Generate a fresh question avoiding identical back-to-back answers when easy
	for _try: int in 4:
		_current_question = ShopQuestionGenerator.generate(_current_tier)
		if _current_question.correct_answer != _last_answer:
			break
	_last_answer = _current_question.correct_answer

	_render_question()


func _render_question() -> void:
	_progress_label.text = "Customer %d / %d" % [_question_index, QUESTIONS_PER_SHIFT]
	_tier_label.text = ShopQuestionGenerator.get_tier_label(_current_tier)
	_session_coins_label.text = "+%d" % _session_coins

	var customer_idx: int = (_question_index - 1) % CUSTOMERS.size()
	_talker.set_textures(CUSTOMERS[customer_idx], CUSTOMER_TALK[customer_idx])
	_talker.say(_current_question.prompt)

	if _current_question.operation == "add":
		_left_icon.texture = load(_current_question.left_icon_path) as Texture2D
		_left_name.text = _current_question.left_label
		_left_price.text = "₱%d" % _current_question.left_price
		_operator_label.text = "+"
		_right_icon.texture = load(_current_question.right_icon_path) as Texture2D
		_right_name.text = _current_question.right_label
		_right_price.text = "₱%d" % _current_question.right_price
	else:
		_left_icon.texture = COIN_ICON
		_left_name.text = "Paid"
		_left_price.text = "₱%d" % _current_question.paid_amount
		_operator_label.text = "-"
		_right_icon.texture = load(_current_question.left_icon_path) as Texture2D
		_right_name.text = _current_question.left_label
		_right_price.text = "₱%d" % _current_question.left_price

	_expression_label.text = _current_question.expression_text
	_set_feedback("Use the number pad and press CHECK!", Color(1.0, 0.9725, 0.9059, 1.0))
	_pop_node(_customer_card)
	_pop_node(_left_item, 0.06)
	_pop_node(_right_item, 0.14)


func _on_hint_pressed() -> void:
	if _current_question == null:
		return
	_hint_shown = true
	_hint_btn.disabled = true
	_set_feedback(_current_question.hint_text, Color(1.0, 0.93, 0.72, 1.0))


func _on_answer_submitted(value: int) -> void:
	if _current_question == null:
		return

	if value == _current_question.correct_answer:
		_handle_correct_answer()
	else:
		_handle_gentle_retry(value)


func _handle_correct_answer() -> void:
	_number_pad.set_locked(true)
	GameState.play_sfx(&"correct")

	# Brief rule: no score penalty on the first retry!
	var reward: int = 5 if _attempts_on_question <= 1 else 3
	_session_coins += reward
	_session_coins_label.text = "+%d" % _session_coins

	if _attempts_on_question <= 1:
		_clean_answers += 1

	if _attempts_on_question == 0:
		_correct_streak += 1
		_miss_streak = 0
	else:
		_correct_streak = 0
		if _attempts_on_question >= 2:
			_miss_streak += 1
		else:
			_miss_streak = 0

	var level_note: String = ""
	if _correct_streak >= 2 and _current_tier < GameState.MAX_ACTIVITY_TIER:
		_current_tier += 1
		_correct_streak = 0
		level_note = " Level up!"
	elif _miss_streak >= 2 and _current_tier > 1:
		_current_tier -= 1
		_miss_streak = 0

	_expression_label.text = _current_question.expression_text.replace("?", str(_current_question.correct_answer))
	_set_feedback("Nice job! +%d coins!%s" % [reward, level_note], Color(0.82, 0.96, 0.84, 1.0))
	_talker.react_happy()
	_pop_node(_feedback_panel)
	_pop_node(_coins_panel)
	_spawn_sparkles(_customer_card.global_position + _customer_card.size * 0.5)
	_spawn_floating_coins(_customer_card.global_position + Vector2(_customer_card.size.x * 0.5, 18.0), reward)

	var delay: float = 0.55 if GameState.reduce_motion else 1.05
	await get_tree().create_timer(delay).timeout
	if is_inside_tree():
		_load_next_question()


func _handle_gentle_retry(submitted_value: int) -> void:
	_attempts_on_question += 1
	GameState.play_sfx(&"hint")

	var prefix: String = "You entered ₱%d — close! " % submitted_value
	if _attempts_on_question == 1:
		prefix = "Let's check again! "
	_set_feedback(prefix + _current_question.hint_text, Color(1.0, 0.93, 0.72, 1.0))
	_hint_shown = true
	_hint_btn.disabled = true
	_number_pad.clear_input()
	_number_pad.nudge_gentle()
	_talker.react_curious()
	_pop_node(_feedback_panel)


func _set_feedback(message: String, bg_color: Color) -> void:
	_feedback_label.text = message
	_feedback_panel.self_modulate = bg_color


func _pop_node(target: Control, delay: float = 0.0) -> void:
	if GameState.reduce_motion:
		return
	target.pivot_offset = target.size * 0.5
	var tween: Tween = create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(target, "scale", Vector2(1.04, 1.04), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", Vector2.ONE, 0.14).set_ease(Tween.EASE_OUT)


func _spawn_sparkles(center: Vector2) -> void:
	if GameState.reduce_motion:
		return
	var offsets: Array[Vector2] = [
		Vector2(-110, -45),
		Vector2(-45, -75),
		Vector2(50, -70),
		Vector2(115, -35),
	]
	for i: int in offsets.size():
		var spr: TextureRect = TextureRect.new()
		spr.texture = SPARKLE_TEX
		spr.custom_minimum_size = Vector2(36, 36)
		spr.size = Vector2(36, 36)
		spr.pivot_offset = Vector2(18, 18)
		spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spr.global_position = center - Vector2(18, 18)
		spr.scale = Vector2.ZERO
		add_child(spr)

		var target_pos: Vector2 = spr.global_position + offsets[i]
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(spr, "global_position", target_pos, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(spr, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(spr, "rotation", randf_range(-0.6, 0.6), 0.5)
		tween.tween_property(spr, "modulate:a", 0.0, 0.25).set_delay(0.3)
		tween.chain().tween_callback(spr.queue_free)


func _spawn_floating_coins(origin: Vector2, amount: int) -> void:
	if GameState.reduce_motion:
		return
	var badge: Label = Label.new()
	badge.text = "+%d coins!" % amount
	badge.add_theme_font_size_override("font_size", 28)
	badge.add_theme_color_override("font_color", Color(1.0, 0.86, 0.28, 1.0))
	badge.add_theme_color_override("font_outline_color", Color(0.1843, 0.2824, 0.3451, 1.0))
	badge.add_theme_constant_override("outline_size", 6)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.global_position = origin - Vector2(60.0, 12.0)
	add_child(badge)

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(badge, "global_position:y", badge.global_position.y - 54.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tween.chain().tween_callback(badge.queue_free)


func _finish_shift() -> void:
	var stars_earned: int = 1
	if _clean_answers >= 7:
		stars_earned = 3
	elif _clean_answers >= 5:
		stars_earned = 2

	GameState.shop_tier = _current_tier
	GameState.last_run_summary = {
		"activity_id": "little_shop",
		"activity_name": "The Little Shop",
		"coins_earned": _session_coins,
		"stars_earned": stars_earned,
		"clean_answers": _clean_answers,
		"total_questions": QUESTIONS_PER_SHIFT,
		"tier_reached": _current_tier,
	}
	GameState.add_rewards(_session_coins, stars_earned, "little_shop", QUESTIONS_PER_SHIFT, _current_tier)
	GameState.play_sfx(&"win")
	GameState.change_scene(RESULTS_SCENE)


func _on_menu_pressed() -> void:
	GameState.change_scene(MAIN_MENU_SCENE)
