# res://scenes/play/math_activity.gd
# Node: MathActivity (Control)
# Reusable gameplay scene powering Puzzle Doors, Little Builder, and Fair Sharing.
extends Control

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
const SPARKLE_TEX: Texture2D = preload("res://assets/art/sparkle.svg")

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
var _current_tier: int = 1
var _current_question: MathQuestion
var _attempts_on_question: int = 0

var _session_coins: int = 0
var _clean_answers: int = 0
var _correct_streak: int = 0
var _miss_streak: int = 0
var _last_answer: int = -1
var _talker: TalkingAvatar


func _ready() -> void:
	_activity_id = GameState.active_activity_id
	if not ACTIVITY_CONFIG.has(_activity_id):
		_activity_id = "puzzle_doors"

	_current_tier = GameState.get_activity_tier(_activity_id)
	var init_cfg: Dictionary = ACTIVITY_CONFIG[_activity_id]
	_talker = TalkingAvatar.new()
	add_child(_talker)
	_talker.setup(_hero_icon, _prompt_label, init_cfg["hero"] as Texture2D, init_cfg["hero_talk"] as Texture2D)
	_menu_btn.pressed.connect(func() -> void: GameState.change_scene(MAIN_MENU_SCENE))
	_hint_btn.pressed.connect(_on_hint_pressed)
	_number_pad.answer_submitted.connect(_on_answer_submitted)
	_load_next_question()


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

	_attempts_on_question = 0
	_hint_btn.disabled = false
	_number_pad.clear_input()
	_number_pad.set_locked(false)

	for _try: int in 4:
		_current_question = _generate_for_activity(_current_tier)
		if _current_question.correct_answer != _last_answer:
			break
	_last_answer = _current_question.correct_answer
	_render_question()


func _render_question() -> void:
	var cfg: Dictionary = ACTIVITY_CONFIG[_activity_id]
	var noun: String = str(cfg["progress_noun"])
	_progress_label.text = "%s %d / %d" % [noun, _question_index, QUESTIONS_PER_SESSION]
	_tier_label.text = _get_tier_label(_current_tier)
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

	var icon_tex: Texture2D = load(_current_question.visual_icon_path) as Texture2D
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


func _animate_group_row(row: Control, delay: float) -> void:
	if GameState.reduce_motion:
		return
	row.modulate.a = 0.0
	var tween: Tween = create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(row, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)


func _on_hint_pressed() -> void:
	if _current_question == null:
		return
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

	_talker.finish_now()
	if _activity_id == "puzzle_doors":
		_talker.set_textures(DOOR_OPEN, DOOR_OPEN)
		_hero_icon.texture = DOOR_OPEN

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
		_miss_streak = _miss_streak + 1 if _attempts_on_question >= 2 else 0

	var level_note: String = ""
	if _correct_streak >= 2 and _current_tier < GameState.MAX_ACTIVITY_TIER:
		_current_tier += 1
		_correct_streak = 0
		level_note = " Level up!"
	elif _miss_streak >= 2 and _current_tier > 1:
		_current_tier -= 1
		_miss_streak = 0

	_expression_label.text = _current_question.expression_text.replace("?", str(_current_question.correct_answer))
	_set_feedback("Awesome! +%d coins!%s" % [reward, level_note], Color(0.82, 0.96, 0.84, 1.0))
	_talker.react_happy()
	_pop_node(_feedback_panel)
	_pop_node(_coins_panel)
	_spawn_sparkles(_hero_card.global_position + _hero_card.size * 0.5)
	_spawn_floating_coins(_hero_card.global_position + Vector2(_hero_card.size.x * 0.5, 18.0), reward)

	var delay: float = 0.55 if GameState.reduce_motion else 1.05
	await get_tree().create_timer(delay).timeout
	if is_inside_tree():
		_load_next_question()


func _handle_gentle_retry(submitted_value: int) -> void:
	_attempts_on_question += 1
	GameState.play_sfx(&"hint")

	var prefix: String = "Let's check again! " if _attempts_on_question == 1 else "You entered %d — close! " % submitted_value
	_set_feedback(prefix + _current_question.hint_text, Color(1.0, 0.93, 0.72, 1.0))
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
		Vector2(-105, -40),
		Vector2(-40, -75),
		Vector2(45, -70),
		Vector2(105, -35),
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


func _finish_session() -> void:
	var stars_earned: int = 1
	if _clean_answers >= 7:
		stars_earned = 3
	elif _clean_answers >= 5:
		stars_earned = 2

	var cfg: Dictionary = ACTIVITY_CONFIG[_activity_id]
	GameState.set_activity_tier(_activity_id, _current_tier)
	GameState.last_run_summary = {
		"activity_id": _activity_id,
		"activity_name": str(cfg["title"]),
		"coins_earned": _session_coins,
		"stars_earned": stars_earned,
		"clean_answers": _clean_answers,
		"total_questions": QUESTIONS_PER_SESSION,
		"tier_reached": _current_tier,
	}
	GameState.add_rewards(_session_coins, stars_earned, _activity_id, QUESTIONS_PER_SESSION)
	GameState.play_sfx(&"win")
	GameState.change_scene(RESULTS_SCENE)
