# res://scenes/challenges/challenges_screen.gd
# Node: ChallengesScreen (Control)
# Hub for unlocked Challenge Modes: Timer Blitz and Endless Marathon.
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"
const CHALLENGE_PLAY_SCENE: String = "res://scenes/challenges/challenge_play.tscn"

@onready var _back_btn: Button = %BackButton
@onready var _coins_label: Label = %CoinsLabel
@onready var _stars_label: Label = %StarsLabel
@onready var _timer_record_label: Label = %TimerRecordLabel
@onready var _endless_record_label: Label = %EndlessRecordLabel
@onready var _play_timer_btn: Button = %PlayTimerButton
@onready var _play_endless_btn: Button = %PlayEndlessButton
@onready var _timer_card: PanelContainer = %TimerCard
@onready var _endless_card: PanelContainer = %EndlessCard


func _ready() -> void:
	GameState.set_bgm_context(&"menu")
	_coins_label.text = str(GameState.coins)
	_stars_label.text = "%d / %d" % [GameState.stars, GameState.get_max_total_stars()]
	_timer_record_label.text = "Best: %d pts  •  %d solved" % [GameState.timer_best_score, GameState.timer_best_solved]
	_endless_record_label.text = "Best: %d pts  •  %d solved  •  %d streak" % [
		GameState.endless_best_score, GameState.endless_best_solved, GameState.endless_best_streak
	]

	_back_btn.pressed.connect(func() -> void: GameState.change_scene(MAIN_MENU_SCENE))
	_play_timer_btn.pressed.connect(_start_challenge.bind("timer"))
	_play_endless_btn.pressed.connect(_start_challenge.bind("endless"))

	if not GameState.reduce_motion:
		_animate_cards()


func _animate_cards() -> void:
	var cards: Array[Control] = [_timer_card, _endless_card]
	for i: int in cards.size():
		var card: Control = cards[i]
		card.modulate.a = 0.0
		card.pivot_offset = card.custom_minimum_size * 0.5
		card.scale = Vector2(0.94, 0.94)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.24).set_delay(0.08 * float(i))
		tween.tween_property(card, "scale", Vector2.ONE, 0.28).set_delay(0.08 * float(i)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _start_challenge(mode: String) -> void:
	GameState.active_challenge_mode = mode
	GameState.change_scene(CHALLENGE_PLAY_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		GameState.play_sfx(&"back")
		GameState.change_scene(MAIN_MENU_SCENE)
