# res://scenes/challenges/challenge_play.gd
# Node: ChallengePlay (Control)
# Powers both Timer Blitz (90s + 30s fast OST + Time's Up OST) and Endless Marathon (3 Hearts).
extends Control

const CHALLENGE_PLAY_SCENE: String = "res://scenes/challenges/challenge_play.tscn"
const CHALLENGES_SCENE: String = "res://scenes/challenges/challenges_screen.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"
const RESULTS_SCENE: String = "res://scenes/shop/results_screen.tscn"

const TIMER_DURATION_SEC: float = 90.0
const TIMER_FAST_THRESHOLD_SEC: float = 30.0
const MAX_HEARTS: int = 3

const ALL_ACTIVITIES: Array[String] = [
	"little_shop", "puzzle_doors", "little_builder", "fair_sharing",
	"number_patterns", "clock_time", "rocket_shapes", "coin_jar",
	"balance_scale", "number_forge"
]
const ACT_LABELS: Dictionary = {
	"little_shop": "THE LITTLE SHOP",
	"puzzle_doors": "PUZZLE DOORS",
	"little_builder": "LITTLE BUILDER",
	"fair_sharing": "FAIR SHARING",
	"number_patterns": "NUMBER PATTERNS",
	"clock_time": "CLOCK & TIME",
	"rocket_shapes": "ROCKET SHAPES",
	"coin_jar": "COIN JAR",
	"balance_scale": "BALANCE SCALE",
	"number_forge": "NUMBER FORGE",
}
const MASCOT_TEX: Texture2D = preload("res://assets/art/mascot.svg")
const MASCOT_TALK_TEX: Texture2D = preload("res://assets/art/mascot_talk.svg")
const STAR_FULL_TEX: Texture2D = preload("res://assets/ui/star.svg")
const STAR_EMPTY_TEX: Texture2D = preload("res://assets/ui/star_empty.svg")
const COIN_TEX: Texture2D = preload("res://assets/ui/coin.svg")

@onready var _menu_btn: Button = %MenuButton
@onready var _mode_label: Label = %ModeLabel
@onready var _status_panel: PanelContainer = %StatusPanel
@onready var _status_label: Label = %StatusLabel
@onready var _hearts_row: HBoxContainer = %HeartsRow
@onready var _score_label: Label = %ScoreLabel
@onready var _streak_panel: PanelContainer = %StreakPanel
@onready var _streak_label: Label = %StreakLabel
@onready var _sticker_cheer_panel: PanelContainer = %StickerCheerPanel
@onready var _equipped_sticker_view: StickerView = %EquippedStickerView
@onready var _coins_label: Label = %SessionCoinsLabel

@onready var _hero_card: PanelContainer = %HeroCard
@onready var _hero_icon: TextureRect = %HeroIcon
@onready var _tag_label: Label = %TagLabel
@onready var _prompt_label: Label = %PromptLabel

@onready var _visual_card: PanelContainer = %VisualCard
@onready var _visual_badge: Label = %VisualBadge
@onready var _groups_container: VBoxContainer = %GroupsContainer
@onready var _expression_label: Label = %ExpressionLabel

@onready var _feedback_panel: PanelContainer = %FeedbackPanel
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _hint_btn: Button = %HintButton
@onready var _number_pad: NumberPad = %NumberPad

var _mode: String = "timer"
var _time_remaining: float = TIMER_DURATION_SEC
var _switched_to_fast: bool = false
var _run_finished: bool = false
var _round_locked: bool = false

var _hearts: int = MAX_HEARTS
var _score: int = 0
var _solved_count: int = 0
var _streak: int = 0
var _best_streak: int = 0
var _session_coins: int = 0
var _last_answer: int = -1
var _current_activity: String = "little_shop"
var _current_question: MathQuestion
var _last_whole_sec: int = 90

var _talker: TalkingAvatar
var _pause_overlay: ActivityPauseOverlay


func _ready() -> void:
	_mode = GameState.active_challenge_mode
	if _mode != "timer" and _mode != "endless":
		_mode = "timer"

	if _mode == "timer":
		GameState.set_bgm_context(&"timer_normal")
		_mode_label.text = "TIMER BLITZ"
		_hearts_row.visible = false
		_status_panel.visible = true
		_update_timer_display()
	else:
		GameState.set_bgm_context(&"endless")
		_mode_label.text = "ENDLESS MARATHON"
		_status_panel.visible = false
		_hearts_row.visible = true
		_refresh_hearts_ui()

	_refresh_equipped_sticker()

	_talker = TalkingAvatar.new()
	add_child(_talker)
	_talker.setup(_hero_icon, _prompt_label, MASCOT_TEX, MASCOT_TALK_TEX)

	_pause_overlay = ActivityPauseOverlay.new()
	add_child(_pause_overlay)
	_pause_overlay.set_labels("Restart Challenge", "Back to Challenges")
	_pause_overlay.resumed.connect(_on_pause_resumed)
	_pause_overlay.restart_requested.connect(func() -> void: GameState.change_scene(CHALLENGE_PLAY_SCENE))
	_pause_overlay.activities_requested.connect(func() -> void: GameState.change_scene(CHALLENGES_SCENE))
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
	if _mode != "timer" or _run_finished or _pause_overlay.visible:
		return

	_time_remaining = maxf(0.0, _time_remaining - delta)
	_update_timer_display()

	if _time_remaining <= TIMER_FAST_THRESHOLD_SEC and not _switched_to_fast:
		_switched_to_fast = true
		GameState.set_bgm_context(&"timer_fast")
		_status_panel.self_modulate = Color(1.0, 0.72, 0.72, 1.0)
		_pop_node(_status_panel)
		CelebrationFX.spawn_floating_text(
			self,
			_status_panel.global_position + Vector2(_status_panel.size.x * 0.5, 42.0),
			"30s LEFT! FAST MODE!",
			Color(1.0, 0.42, 0.42, 1.0)
		)

	if _time_remaining <= 0.0:
		_finish_timer_run()


func _update_timer_display() -> void:
	var secs: int = ceili(_time_remaining)
	var mins: int = secs / 60
	var rem: int = secs % 60
	_status_label.text = "%d:%02d" % [mins, rem]
	if secs <= 10 and secs != _last_whole_sec and secs > 0:
		_pop_node(_status_panel)
	_last_whole_sec = secs


func _refresh_hearts_ui() -> void:
	for child: Node in _hearts_row.get_children():
		child.queue_free()
	for i: int in MAX_HEARTS:
		var heart: TextureRect = TextureRect.new()
		heart.custom_minimum_size = Vector2(28, 28)
		heart.texture = STAR_FULL_TEX if i < _hearts else STAR_EMPTY_TEX
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_hearts_row.add_child(heart)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _run_finished:
		get_viewport().set_input_as_handled()
		GameState.play_sfx(&"back")
		_toggle_pause()


func _toggle_pause() -> void:
	if _run_finished:
		return
	if _pause_overlay.visible:
		_pause_overlay.close_pause()
	else:
		_number_pad.set_locked(true)
		_pause_overlay.open_pause()


func _on_pause_resumed() -> void:
	_number_pad.set_locked(_round_locked or _run_finished)


func _pick_tier_for_challenge() -> int:
	if _mode == "timer":
		return clampi(2 + (_solved_count / 3), 2, 8)
	return clampi(2 + (_solved_count / 4), 2, 8)


func _generate_challenge_question(act_id: String, tier: int) -> MathQuestion:
	match act_id:
		"little_shop":
			return ShopQuestionGenerator.generate(tier)
		"puzzle_doors":
			return DoorsQuestionGenerator.generate(tier)
		"little_builder":
			return BuilderQuestionGenerator.generate(tier)
		"fair_sharing":
			return SharingQuestionGenerator.generate(tier)
		"number_patterns":
			return PatternsQuestionGenerator.generate(tier)
		"clock_time":
			return TimeQuestionGenerator.generate(tier)
		"rocket_shapes":
			return ShapesQuestionGenerator.generate(tier)
		"coin_jar":
			return CoinJarQuestionGenerator.generate(tier)
		"balance_scale":
			return BalanceScaleQuestionGenerator.generate(tier)
		"number_forge":
			return NumberForgeQuestionGenerator.generate(tier)
	return ShopQuestionGenerator.generate(tier)


func _load_next_question() -> void:
	if _run_finished:
		return
	_round_locked = false
	_hint_btn.disabled = false
	_number_pad.clear_input()
	_number_pad.set_locked(false)

	var tier: int = _pick_tier_for_challenge()
	for _try: int in 5:
		_current_activity = ALL_ACTIVITIES[randi() % ALL_ACTIVITIES.size()]
		_current_question = _generate_challenge_question(_current_activity, tier)
		if _current_question.correct_answer != _last_answer:
			break
	_last_answer = _current_question.correct_answer

	_apply_unit_format()
	_render_question()


func _apply_unit_format() -> void:
	if _current_question == null:
		_number_pad.set_unit_format("")
		return
	var expr: String = _current_question.expression_text
	if _current_activity == "little_shop":
		_number_pad.set_unit_format("", "", true)
	elif _current_activity == "coin_jar" and _current_question.operation != "avg" and _current_question.visual_badge_text != "Master Vault Riddle":
		_number_pad.set_unit_format("", "", true)
	elif _current_activity == "little_builder" and _current_question.operation == "pct":
		_number_pad.set_unit_format("", "", true)
	elif _current_activity == "clock_time":
		if expr.ends_with("min"):
			_number_pad.set_unit_format("", "min")
		elif expr.ends_with("hrs"):
			_number_pad.set_unit_format("", "hrs")
		elif expr.ends_with("days"):
			_number_pad.set_unit_format("", "days")
		elif expr.ends_with("km"):
			_number_pad.set_unit_format("", "km")
		else:
			_number_pad.set_unit_format("")
	elif _current_activity == "rocket_shapes" and (_current_question.visual_badge_text.contains("180°") or _current_question.visual_badge_text.contains("360°")):
		_number_pad.set_unit_format("", "°")
	else:
		_number_pad.set_unit_format("")


func _render_question() -> void:
	_score_label.text = "Score: %d" % _score
	_coins_label.text = "+%d" % _session_coins

	var act_title: String = str(ACT_LABELS.get(_current_activity, "CHALLENGE"))
	_tag_label.text = "CHALLENGE  •  %s  •  TIER %d" % [act_title, _current_question.tier]
	_talker.say(_current_question.prompt)

	if _current_activity == "little_shop":
		_visual_badge.text = "Shop Counter" if _current_question.operation == "add" else "Customer Change"
	else:
		_visual_badge.text = _current_question.visual_badge_text
	_expression_label.text = _current_question.expression_text

	_rebuild_visuals()
	_set_feedback("Solve quickly and press CHECK!", Color(1.0, 0.9725, 0.9059, 1.0))
	_pop_node(_visual_card)


func _rebuild_visuals() -> void:
	for child: Node in _groups_container.get_children():
		child.queue_free()

	if _current_activity == "little_shop":
		_build_shop_pair_row()
		return
	if _current_activity == "number_patterns":
		_build_pattern_stones()
		return

	var icon_tex: Texture2D = GameState.load_texture_safe(_current_question.visual_icon_path)
	var groups: int = clampi(_current_question.group_count, 1, 5)
	if icon_tex != null:
		var badge_row: HBoxContainer = HBoxContainer.new()
		badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
		badge_row.add_theme_constant_override("separation", 12)
		for _i: int in groups:
			var icon: TextureRect = TextureRect.new()
			icon.texture = icon_tex
			icon.custom_minimum_size = Vector2(42, 42)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			badge_row.add_child(icon)
		_groups_container.add_child(badge_row)


func _build_shop_pair_row() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)

	if _current_question.operation == "add":
		row.add_child(_make_item_pill(
			_current_question.left_icon_path, _current_question.left_label, str(_current_question.left_price)
		))
		var op: Label = Label.new()
		op.text = "+"
		op.add_theme_font_size_override("font_size", 32)
		row.add_child(op)
		row.add_child(_make_item_pill(
			_current_question.right_icon_path, _current_question.right_label, str(_current_question.right_price)
		))
	else:
		row.add_child(_make_item_pill("res://assets/ui/coin.svg", "Paid", str(_current_question.paid_amount)))
		var op: Label = Label.new()
		op.text = "-"
		op.add_theme_font_size_override("font_size", 32)
		row.add_child(op)
		row.add_child(_make_item_pill(
			_current_question.left_icon_path, _current_question.left_label, str(_current_question.left_price)
		))

	_groups_container.add_child(row)


func _make_item_pill(icon_path: String, item_name: String, price_str: String) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	var st: StyleBoxFlat = StyleBoxFlat.new()
	st.content_margin_left = 14.0
	st.content_margin_top = 8.0
	st.content_margin_right = 14.0
	st.content_margin_bottom = 8.0
	st.bg_color = Color(0.95, 0.98, 1.0, 1.0)
	st.border_width_left = 3
	st.border_width_top = 3
	st.border_width_right = 3
	st.border_width_bottom = 5
	st.border_color = Color(0.184314, 0.282353, 0.345098, 1.0)
	st.corner_radius_top_left = 16
	st.corner_radius_top_right = 16
	st.corner_radius_bottom_right = 16
	st.corner_radius_bottom_left = 16
	card.add_theme_stylebox_override("panel", st)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	var tex: TextureRect = TextureRect.new()
	tex.custom_minimum_size = Vector2(44, 44)
	tex.texture = GameState.load_texture_safe(icon_path)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(tex)

	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	hbox.add_child(v)

	var n_lbl: Label = Label.new()
	n_lbl.text = item_name
	n_lbl.add_theme_font_size_override("font_size", 18)
	v.add_child(n_lbl)

	var p_row: HBoxContainer = HBoxContainer.new()
	p_row.add_theme_constant_override("separation", 4)
	v.add_child(p_row)

	var c_ico: TextureRect = TextureRect.new()
	c_ico.custom_minimum_size = Vector2(18, 18)
	c_ico.texture = COIN_TEX
	c_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	c_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p_row.add_child(c_ico)

	var p_lbl: Label = Label.new()
	p_lbl.text = price_str
	p_lbl.add_theme_font_size_override("font_size", 20)
	p_row.add_child(p_lbl)

	return card


func _build_pattern_stones() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var tokens: PackedStringArray = _current_question.expression_text.split(",")
	for i: int in tokens.size():
		var tok: String = tokens[i].strip_edges()
		if tok.is_empty():
			continue
		var stone: PanelContainer = PanelContainer.new()
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.content_margin_left = 12.0
		style.content_margin_top = 6.0
		style.content_margin_right = 12.0
		style.content_margin_bottom = 6.0
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 5
		style.border_color = Color(0.184314, 0.282353, 0.345098, 1.0)
		style.corner_radius_top_left = 14
		style.corner_radius_top_right = 14
		style.corner_radius_bottom_right = 14
		style.corner_radius_bottom_left = 14
		style.bg_color = Color(1.0, 0.86, 0.42, 1.0) if tok == "?" else Color(0.84, 0.96, 0.86, 1.0)
		stone.add_theme_stylebox_override("panel", style)
		var lbl: Label = Label.new()
		lbl.text = tok
		lbl.add_theme_font_size_override("font_size", 22)
		stone.add_child(lbl)
		row.add_child(stone)
	_groups_container.add_child(row)


func _on_hint_pressed() -> void:
	if _current_question == null or _round_locked or _run_finished:
		return
	_hint_btn.disabled = true
	_set_feedback(_current_question.hint_text, Color(1.0, 0.93, 0.72, 1.0))


func _on_answer_submitted(value: int) -> void:
	if _current_question == null or _round_locked or _run_finished:
		return
	if value == _current_question.correct_answer:
		_handle_correct_answer()
	else:
		_handle_wrong_answer(value)


func _handle_correct_answer() -> void:
	_round_locked = true
	_number_pad.lock_and_clear()
	GameState.play_sfx(&"correct")
	_talker.finish_now()

	_solved_count += 1
	_streak += 1
	_best_streak = maxi(_best_streak, _streak)

	var pts: int = 100 + (_streak - 1) * 15
	_score += pts
	var coin_gain: int = 6 + (2 if _streak >= 3 else 0)
	_session_coins += coin_gain

	_score_label.text = "Score: %d" % _score
	_coins_label.text = "+%d" % _session_coins
	_update_streak_ui()

	_expression_label.text = _current_question.expression_text.replace("?", str(_current_question.correct_answer))
	_set_feedback("+%d pts  •  +%d coins!" % [pts, coin_gain], Color(0.82, 0.96, 0.84, 1.0))
	_talker.react_happy()
	CelebrationFX.spawn_sparkles(self, _hero_card.global_position + _hero_card.size * 0.5)
	CelebrationFX.spawn_floating_text(
		self,
		_hero_card.global_position + Vector2(_hero_card.size.x * 0.5, 16.0),
		"+%d!" % pts
	)

	var delay: float = 0.35 if _mode == "timer" else 0.70
	if GameState.reduce_motion:
		delay = 0.28
	await get_tree().create_timer(delay).timeout
	if is_inside_tree() and not _run_finished:
		_load_next_question()


func _handle_wrong_answer(submitted_value: int) -> void:
	_streak = 0
	_update_streak_ui()
	GameState.play_sfx(&"hint")
	_number_pad.clear_input()
	_number_pad.nudge_gentle()
	_talker.react_curious()

	if _mode == "endless":
		_hearts -= 1
		_refresh_hearts_ui()
		if _hearts <= 0:
			_finish_endless_run()
			return
		_set_feedback("Oops (%d)! %d heart%s left — %s" % [
			submitted_value, _hearts, "s" if _hearts != 1 else "", _current_question.hint_text
		], Color(1.0, 0.86, 0.86, 1.0))
	else:
		_set_feedback("Not %d! %s" % [submitted_value, _current_question.hint_text], Color(1.0, 0.93, 0.72, 1.0))
	_pop_node(_feedback_panel)


func _update_streak_ui() -> void:
	if _streak >= 2:
		_streak_panel.visible = true
		_streak_label.text = "%d Streak!" % _streak
		_pop_node(_streak_panel)
	else:
		_streak_panel.visible = false


func _finish_timer_run() -> void:
	if _run_finished:
		return
	_run_finished = true
	_round_locked = true
	_number_pad.lock_and_clear()
	_hint_btn.disabled = true
	_menu_btn.disabled = true

	GameState.play_times_up_music()
	_set_feedback("TIME'S UP! Tallying your Timer Blitz score...", Color(1.0, 0.88, 0.76, 1.0))
	_talker.react_happy()
	CelebrationFX.spawn_floating_text(
		self,
		_visual_card.global_position + _visual_card.size * 0.5,
		"TIME'S UP!",
		Color(1.0, 0.45, 0.35, 1.0)
	)

	await get_tree().create_timer(2.35).timeout
	if is_inside_tree():
		_submit_and_exit()


func _finish_endless_run() -> void:
	if _run_finished:
		return
	_run_finished = true
	_round_locked = true
	_number_pad.lock_and_clear()
	_hint_btn.disabled = true
	_menu_btn.disabled = true

	_expression_label.text = _current_question.expression_text.replace("?", str(_current_question.correct_answer))
	_set_feedback("Out of hearts! Amazing Endless Marathon run!", Color(0.95, 0.86, 1.0, 1.0))
	GameState.play_sfx(&"win")

	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		_submit_and_exit()


func _submit_and_exit() -> void:
	var is_new_record: bool = GameState.record_challenge_run(_mode, _score, _solved_count, _best_streak, _session_coins)
	GameState.last_run_summary = {
		"mode": _mode,
		"score": _score,
		"solved_count": _solved_count,
		"best_streak": _best_streak,
		"coins_earned": _session_coins,
		"is_new_record": is_new_record,
	}
	GameState.change_scene(RESULTS_SCENE)


func _set_feedback(message: String, bg_color: Color) -> void:
	_feedback_label.text = message
	_feedback_panel.self_modulate = bg_color


func _pop_node(target: Control) -> void:
	if GameState.reduce_motion:
		return
	target.pivot_offset = target.size * 0.5
	var tween: Tween = create_tween()
	tween.tween_property(target, "scale", Vector2(1.05, 1.05), 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT)
