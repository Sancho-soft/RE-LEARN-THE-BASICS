# res://scenes/play/math_activity.gd
# Node: MathActivity (Control)
# Reusable gameplay scene powering Puzzle Doors, Little Builder, Fair Sharing,
# Number Patterns, Clock & Time, Rocket Shapes, and Coin Jar.
extends Control

const MATH_ACTIVITY_SCENE: String = "res://scenes/play/math_activity.tscn"
const ACTIVITIES_SCENE: String = "res://scenes/activities/activities_screen.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"
const RESULTS_SCENE: String = "res://scenes/shop/results_screen.tscn"
const QUESTIONS_PER_SESSION: int = 8

const DOOR_CLOSED: Texture2D = preload("res://assets/art/door_closed.svg")
const DOOR_OPEN: Texture2D = preload("res://assets/art/door_open.svg")
const BEAR_TEX: Texture2D = preload("res://assets/art/customer_bear.svg")
const BEAR_TALK_TEX: Texture2D = preload("res://assets/art/customer_bear_talk.svg")
const BUNNY_TEX: Texture2D = preload("res://assets/art/customer_bunny.svg")
const BUNNY_TALK_TEX: Texture2D = preload("res://assets/art/customer_bunny_talk.svg")
const MASCOT_TEX: Texture2D = preload("res://assets/art/mascot.svg")
const MASCOT_TALK_TEX: Texture2D = preload("res://assets/art/mascot_talk.svg")

const ACTIVITY_CONFIG: Dictionary = {
	"puzzle_doors": {
		"title": "Puzzle Doors",
		"tag": "TEMPLE LOCK",
		"hero": DOOR_CLOSED,
		"hero_talk": DOOR_CLOSED,
		"progress_noun": "Door",
	},
	"little_builder": {
		"title": "Little Builder",
		"tag": "WORKSHOP PLAN",
		"hero": BEAR_TEX,
		"hero_talk": BEAR_TALK_TEX,
		"progress_noun": "Build",
	},
	"fair_sharing": {
		"title": "Fair Sharing",
		"tag": "SNACK TABLE",
		"hero": BUNNY_TEX,
		"hero_talk": BUNNY_TALK_TEX,
		"progress_noun": "Round",
	},
	"number_patterns": {
		"title": "Number Patterns",
		"tag": "GARDEN PATH",
		"hero": MASCOT_TEX,
		"hero_talk": MASCOT_TALK_TEX,
		"progress_noun": "Step",
	},
	"clock_time": {
		"title": "Clock & Time",
		"tag": "SUNDIAL TOWER",
		"hero": BUNNY_TEX,
		"hero_talk": BUNNY_TALK_TEX,
		"progress_noun": "Tick",
	},
	"rocket_shapes": {
		"title": "Rocket Shapes",
		"tag": "LAUNCH PAD",
		"hero": BEAR_TEX,
		"hero_talk": BEAR_TALK_TEX,
		"progress_noun": "Stage",
	},
	"coin_jar": {
		"title": "Coin Jar",
		"tag": "TREASURE VAULT",
		"hero": MASCOT_TEX,
		"hero_talk": MASCOT_TALK_TEX,
		"progress_noun": "Puzzle",
	},
}

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

var _activity_id: String = "puzzle_doors"
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


func _ready() -> void:
	GameState.set_bgm_context(&"activity")
	_activity_id = GameState.active_activity_id
	if not ACTIVITY_CONFIG.has(_activity_id):
		_activity_id = "puzzle_doors"

	_selected_tier = clampi(GameState.get_activity_tier(_activity_id), 1, GameState.get_highest_unlocked_tier(_activity_id))
	_question_stepper.setup_steps(QUESTIONS_PER_SESSION)
	_refresh_equipped_sticker()

	var init_cfg: Dictionary = ACTIVITY_CONFIG[_activity_id]
	_talker = TalkingAvatar.new()
	add_child(_talker)
	_talker.setup(_hero_icon, _prompt_label, init_cfg["hero"] as Texture2D, init_cfg["hero_talk"] as Texture2D)

	_pause_overlay = ActivityPauseOverlay.new()
	add_child(_pause_overlay)
	_pause_overlay.resumed.connect(_on_pause_resumed)
	_pause_overlay.restart_requested.connect(func() -> void: GameState.change_scene(MATH_ACTIVITY_SCENE))
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


func _generate_for_activity(tier: int) -> MathQuestion:
	match _activity_id:
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
	return DoorsQuestionGenerator.generate(tier)


func _get_tier_label(tier: int) -> String:
	return GameState.get_activity_tier_label(_activity_id, tier)


func _load_next_question() -> void:
	_question_index += 1
	if _question_index > QUESTIONS_PER_SESSION:
		_finish_session()
		return

	_round_locked = false
	_attempts_on_question = 0
	_hint_btn.disabled = false
	_number_pad.clear_input()
	_number_pad.set_locked(false)
	_question_stepper.update_progress(_question_index, _question_index - 1)

	for _try: int in 4:
		_current_question = _generate_for_activity(_selected_tier)
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
	if _activity_id == "coin_jar" and _current_question.operation != "avg" and _current_question.visual_badge_text != "Master Vault Riddle":
		_number_pad.set_unit_format("", "", true)
	elif _activity_id == "little_builder" and _current_question.operation == "pct":
		_number_pad.set_unit_format("", "", true)
	elif _activity_id == "clock_time":
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
	elif _activity_id == "rocket_shapes" and (_current_question.visual_badge_text.contains("180°") or _current_question.visual_badge_text.contains("360°")):
		_number_pad.set_unit_format("", "°")
	else:
		_number_pad.set_unit_format("")


func _render_question() -> void:
	var cfg: Dictionary = ACTIVITY_CONFIG[_activity_id]
	var noun: String = str(cfg["progress_noun"])
	_progress_label.text = "%s %d / %d" % [noun, _question_index, QUESTIONS_PER_SESSION]
	_tier_label.text = _get_tier_label(_selected_tier)
	_session_coins_label.text = "+%d" % _session_coins

	_talker.set_textures(cfg["hero"] as Texture2D, cfg["hero_talk"] as Texture2D)
	_tag_label.text = "%s  •  %s" % [str(cfg["title"]).to_upper(), str(cfg["tag"])]
	_talker.say(_current_question.prompt)
	_visual_badge.text = _current_question.visual_badge_text
	_expression_label.text = _current_question.expression_text

	_rebuild_visual_groups()
	_set_feedback("Use the number pad and press CHECK!", Color(1.0, 0.9725, 0.9059, 1.0))
	_pop_node(_hero_card)
	_pop_node(_visual_card, 0.06)


func _rebuild_visual_groups() -> void:
	for child: Node in _groups_container.get_children():
		child.queue_free()

	if _activity_id == "number_patterns":
		_build_pattern_stones()
		return

	var icon_tex: Texture2D = GameState.load_texture_safe(_current_question.visual_icon_path)
	var groups: int = _current_question.group_count
	var per_group: int = _current_question.items_per_group

	# Show concrete icon rows when total icons <= 24; otherwise show clean pill badges
	if icon_tex != null and groups > 0 and per_group > 0 and groups <= 4 and (groups * per_group) <= 24:
		for r: int in groups:
			var row: HBoxContainer = HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 6)
			for _c: int in per_group:
				var icon: TextureRect = TextureRect.new()
				icon.texture = icon_tex
				icon.custom_minimum_size = Vector2(32, 32)
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				row.add_child(icon)
			_groups_container.add_child(row)
			_animate_group_row(row, float(r) * 0.06)
	elif icon_tex != null:
		var badge_row: HBoxContainer = HBoxContainer.new()
		badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
		badge_row.add_theme_constant_override("separation", 12)
		var show_count: int = clampi(groups, 1, 5)
		for _i: int in show_count:
			var icon: TextureRect = TextureRect.new()
			icon.texture = icon_tex
			icon.custom_minimum_size = Vector2(44, 44)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			badge_row.add_child(icon)
		_groups_container.add_child(badge_row)
		_animate_group_row(badge_row, 0.0)


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
		style.content_margin_left = 14.0
		style.content_margin_top = 8.0
		style.content_margin_right = 14.0
		style.content_margin_bottom = 8.0
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 5
		style.border_color = Color(0.184314, 0.282353, 0.345098, 1.0)
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_right = 16
		style.corner_radius_bottom_left = 16
		style.bg_color = Color(1.0, 0.86, 0.42, 1.0) if tok == "?" else Color(0.84, 0.96, 0.86, 1.0)
		stone.add_theme_stylebox_override("panel", style)

		var lbl: Label = Label.new()
		lbl.text = tok
		lbl.add_theme_font_size_override("font_size", 24)
		stone.add_child(lbl)
		row.add_child(stone)

		if i < tokens.size() - 1:
			var arrow: Label = Label.new()
			arrow.text = "→"
			arrow.add_theme_font_size_override("font_size", 22)
			arrow.add_theme_color_override("font_color", Color(0.28, 0.39, 0.45, 1.0))
			row.add_child(arrow)

	_groups_container.add_child(row)
	_animate_group_row(row, 0.0)


func _animate_group_row(row: Control, delay: float) -> void:
	if GameState.reduce_motion:
		return
	row.modulate.a = 0.0
	var tween: Tween = create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(row, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)


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

	_talker.finish_now()
	if _activity_id == "puzzle_doors":
		_talker.set_textures(DOOR_OPEN, DOOR_OPEN)
		_hero_icon.texture = DOOR_OPEN

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
	_set_feedback("Awesome! +%d coins!%s" % [reward, bonus_note], Color(0.82, 0.96, 0.84, 1.0))
	_talker.react_happy()
	_pop_node(_feedback_panel)
	_pop_node(_coins_panel)
	var fx_origin: Vector2 = _hero_card.global_position + _hero_card.size * 0.5
	CelebrationFX.spawn_sparkles(self, fx_origin)
	CelebrationFX.spawn_floating_text(self, _hero_card.global_position + Vector2(_hero_card.size.x * 0.5, 18.0), "+%d coins!" % reward)

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


func _finish_session() -> void:
	var stars_earned: int = 1
	if _clean_answers >= 7:
		stars_earned = 3
	elif _clean_answers >= 5:
		stars_earned = 2

	var prev_best: int = GameState.get_level_stars(_activity_id, _selected_tier)
	var unlocked_next_tier: int = 0
	if prev_best == 0 and _selected_tier < GameState.MAX_ACTIVITY_TIER:
		unlocked_next_tier = _selected_tier + 1

	var cfg: Dictionary = ACTIVITY_CONFIG[_activity_id]
	GameState.add_rewards(_session_coins, stars_earned, _activity_id, QUESTIONS_PER_SESSION, _selected_tier)
	GameState.set_activity_tier(_activity_id, _selected_tier, true)

	GameState.last_run_summary = {
		"activity_id": _activity_id,
		"activity_name": str(cfg["title"]),
		"coins_earned": _session_coins,
		"stars_earned": stars_earned,
		"prev_level_best": prev_best,
		"new_level_best": GameState.get_level_stars(_activity_id, _selected_tier),
		"unlocked_next_tier": unlocked_next_tier,
		"clean_answers": _clean_answers,
		"total_questions": QUESTIONS_PER_SESSION,
		"tier_reached": _selected_tier,
	}
	GameState.play_sfx(&"win")
	GameState.change_scene(RESULTS_SCENE)
