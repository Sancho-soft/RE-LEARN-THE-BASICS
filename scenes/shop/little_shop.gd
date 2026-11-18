# res://scenes/shop/little_shop.gd
# Node: LittleShop (Control)
extends Control

const LITTLE_SHOP_SCENE: String = "res://scenes/shop/little_shop.tscn"
const ACTIVITIES_SCENE: String = "res://scenes/activities/activities_screen.tscn"
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

@onready var _menu_btn: Button = %MenuButton
@onready var _progress_label: Label = %ProgressLabel
@onready var _tier_label: Label = %TierLabel
@onready var _question_stepper: QuestionStepper = %QuestionStepper
@onready var _streak_panel: PanelContainer = %StreakPanel
@onready var _streak_label: Label = %StreakLabel
@onready var _sticker_cheer_panel: PanelContainer = %StickerCheerPanel
@onready var _equipped_sticker_view: StickerView = %EquippedStickerView
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
var _selected_tier: int = 1
var _current_question: MathQuestion
var _attempts_on_question: int = 0
var _round_locked: bool = false

var _session_coins: int = 0
var _clean_answers: int = 0
var _first_try_streak: int = 0
var _last_answer: int = -1
var _talker: TalkingAvatar
var _pause_overlay: ActivityPauseOverlay
var _bob_time: float = 0.0


func _ready() -> void:
	GameState.set_bgm_context(&"activity")
	_selected_tier = clampi(GameState.get_activity_tier("little_shop"), 1, GameState.get_highest_unlocked_tier("little_shop"))
	_question_stepper.setup_steps(QUESTIONS_PER_SHIFT)
	_number_pad.set_unit_format("", "", true)
	_refresh_equipped_sticker()

	_talker = TalkingAvatar.new()
	add_child(_talker)
	_talker.setup(_customer_icon, _speech_label, CUSTOMERS[0], CUSTOMER_TALK[0])

	_pause_overlay = ActivityPauseOverlay.new()
	add_child(_pause_overlay)
	_pause_overlay.resumed.connect(_on_pause_resumed)
	_pause_overlay.restart_requested.connect(func() -> void: GameState.change_scene(LITTLE_SHOP_SCENE))
	_pause_overlay.activities_requested.connect(func() -> void: GameState.change_scene(ACTIVITIES_SCENE))
	_pause_overlay.menu_requested.connect(func() -> void: GameState.change_scene(MAIN_MENU_SCENE))

	_menu_btn.pressed.connect(_toggle_pause)
	_hint_btn.pressed.connect(_on_hint_pressed)
	_number_pad.answer_submitted.connect(_on_answer_submitted)
	_load_next_question()


func _refresh_equipped_sticker() -> void:
	var sid: String = GameState.equipped_sticker
	if sid != "" and GameState.get_sticker_icon_path(sid) != "":
		_sticker_cheer_panel.visible = true
		_equipped_sticker_view.setup_sticker(sid, Vector2(40, 40), false)
	else:
		_sticker_cheer_panel.visible = false


func _process(delta: float) -> void:
	if GameState.reduce_motion or _pause_overlay.visible:
		_left_icon.rotation = 0.0
		_right_icon.rotation = 0.0
		return
	_bob_time += delta
	_left_icon.pivot_offset = _left_icon.size * 0.5
	_right_icon.pivot_offset = _right_icon.size * 0.5
	_left_icon.rotation = sin(_bob_time * 2.1) * 0.05
	_right_icon.rotation = sin(_bob_time * 2.1 + 1.6) * 0.05


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		GameState.play_sfx(&"back")
		_toggle_pause()


func _toggle_pause() -> void:
	if _pause_overlay.visible:
		_pause_overlay.close_pause()
	else:
		_number_pad.set_locked(true)
		_pause_overlay.open_pause()


func _on_pause_resumed() -> void:
	_number_pad.set_locked(_round_locked)


func _load_next_question() -> void:
	_question_index += 1
	if _question_index > QUESTIONS_PER_SHIFT:
		_finish_shift()
		return

	_round_locked = false
	_attempts_on_question = 0
	_hint_btn.disabled = false
	_number_pad.clear_input()
	_number_pad.set_locked(false)
	_question_stepper.update_progress(_question_index, _question_index - 1)

	for _try: int in 4:
		_current_question = ShopQuestionGenerator.generate(_selected_tier)
		if _current_question.correct_answer != _last_answer:
			break
	_last_answer = _current_question.correct_answer

	_render_question()


func _render_question() -> void:
	_progress_label.text = "Customer %d / %d" % [_question_index, QUESTIONS_PER_SHIFT]
	_tier_label.text = ShopQuestionGenerator.get_tier_label(_selected_tier)
	_session_coins_label.text = "+%d" % _session_coins

	var customer_idx: int = (_question_index - 1) % CUSTOMERS.size()
	_talker.set_textures(CUSTOMERS[customer_idx], CUSTOMER_TALK[customer_idx])
	_talker.say(_current_question.prompt)

	if _current_question.operation == "add":
		_left_icon.texture = load(_current_question.left_icon_path) as Texture2D
		_left_name.text = _current_question.left_label
		_left_price.text = str(_current_question.left_price)
		_operator_label.text = "+"
		_right_icon.texture = load(_current_question.right_icon_path) as Texture2D
		_right_name.text = _current_question.right_label
		_right_price.text = str(_current_question.right_price)
	else:
		_left_icon.texture = COIN_ICON
		_left_name.text = "Paid"
		_left_price.text = str(_current_question.paid_amount)
		_operator_label.text = "-"
		_right_icon.texture = load(_current_question.left_icon_path) as Texture2D
		_right_name.text = _current_question.left_label
		_right_price.text = str(_current_question.left_price)

	_expression_label.text = _current_question.expression_text
	_set_feedback("Use the number pad and press CHECK!", Color(1.0, 0.9725, 0.9059, 1.0))
	_pop_node(_customer_card)
	_pop_node(_left_item, 0.06)
	_pop_node(_right_item, 0.14)


func _on_hint_pressed() -> void:
	if _current_question == null or _round_locked:
		return
	_hint_btn.disabled = true
	_set_feedback(_current_question.hint_text, Color(1.0, 0.93, 0.72, 1.0))


func _on_answer_submitted(value: int) -> void:
	if _current_question == null or _round_locked:
		return

	if value == _current_question.correct_answer:
		_handle_correct_answer()
	else:
		_handle_gentle_retry(value)


func _handle_correct_answer() -> void:
	_round_locked = true
	_number_pad.lock_and_clear()
	GameState.play_sfx(&"correct")

	if _attempts_on_question <= 1:
		_clean_answers += 1

	if _attempts_on_question == 0:
		_first_try_streak += 1
	else:
		_first_try_streak = 0

	var base_reward: int = 5 if _attempts_on_question <= 1 else 3
	var streak_bonus: int = 1 if _first_try_streak >= 3 else 0
	var reward: int = base_reward + streak_bonus
	_session_coins += reward
	_session_coins_label.text = "+%d" % _session_coins
	_update_streak_ui()
	_question_stepper.update_progress(_question_index, _question_index)

	_expression_label.text = _current_question.expression_text.replace("?", str(_current_question.correct_answer))
	var bonus_note: String = "  Streak +1!" if streak_bonus > 0 else ""
	_set_feedback("Nice job! +%d coins!%s" % [reward, bonus_note], Color(0.82, 0.96, 0.84, 1.0))
	_talker.react_happy()
	_pop_node(_feedback_panel)
	_pop_node(_coins_panel)
	var fx_origin: Vector2 = _customer_card.global_position + _customer_card.size * 0.5
	CelebrationFX.spawn_sparkles(self, fx_origin)
	CelebrationFX.spawn_floating_text(self, _customer_card.global_position + Vector2(_customer_card.size.x * 0.5, 18.0), "+%d coins!" % reward)

	var delay: float = 0.55 if GameState.reduce_motion else 1.05
	await get_tree().create_timer(delay).timeout
	if is_inside_tree():
		_load_next_question()


func _handle_gentle_retry(submitted_value: int) -> void:
	_attempts_on_question += 1
	_first_try_streak = 0
	_update_streak_ui()
	GameState.play_sfx(&"hint")

	var prefix: String = "Let's check again! " if _attempts_on_question == 1 else "You entered %d — close! " % submitted_value
	_set_feedback(prefix + _current_question.hint_text, Color(1.0, 0.93, 0.72, 1.0))
	_hint_btn.disabled = true
	_number_pad.clear_input()
	_number_pad.nudge_gentle()
	_talker.react_curious()
	_pop_node(_feedback_panel)


func _update_streak_ui() -> void:
	if _first_try_streak >= 2:
		_streak_panel.visible = true
		_streak_label.text = "%d Streak!" % _first_try_streak
		_pop_node(_streak_panel)
	else:
		_streak_panel.visible = false


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


func _finish_shift() -> void:
	var stars_earned: int = 1
	if _clean_answers >= 7:
		stars_earned = 3
	elif _clean_answers >= 5:
		stars_earned = 2

	var prev_best: int = GameState.get_level_stars("little_shop", _selected_tier)
	var unlocked_next_tier: int = 0
	if prev_best == 0 and _selected_tier < GameState.MAX_ACTIVITY_TIER:
		unlocked_next_tier = _selected_tier + 1

	GameState.add_rewards(_session_coins, stars_earned, "little_shop", QUESTIONS_PER_SHIFT, _selected_tier)
	GameState.set_activity_tier("little_shop", _selected_tier, true)

	GameState.last_run_summary = {
		"activity_id": "little_shop",
		"activity_name": "The Little Shop",
		"coins_earned": _session_coins,
		"stars_earned": stars_earned,
		"prev_level_best": prev_best,
		"new_level_best": GameState.get_level_stars("little_shop", _selected_tier),
		"unlocked_next_tier": unlocked_next_tier,
		"clean_answers": _clean_answers,
		"total_questions": QUESTIONS_PER_SHIFT,
		"tier_reached": _selected_tier,
	}
	GameState.play_sfx(&"win")
	GameState.change_scene(RESULTS_SCENE)
