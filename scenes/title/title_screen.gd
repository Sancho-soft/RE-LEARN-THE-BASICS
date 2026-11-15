# res://scenes/title/title_screen.gd
# Node: TitleScreen (Control)
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"

@onready var _logo: TextureRect = %Logo
@onready var _prompt_panel: PanelContainer = %PromptPanel

var _has_started: bool = false


func _ready() -> void:
	_logo.pivot_offset = _logo.custom_minimum_size * 0.5
	if not GameState.reduce_motion:
		_play_entrance()


func _play_entrance() -> void:
	_logo.scale = Vector2(0.85, 0.85)
	_logo.modulate.a = 0.0
	_prompt_panel.modulate.a = 0.0

	var enter: Tween = create_tween().set_parallel(true)
	enter.tween_property(_logo, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	enter.tween_property(_logo, "modulate:a", 1.0, 0.3)
	enter.tween_property(_prompt_panel, "modulate:a", 1.0, 0.4).set_delay(0.2)
	await enter.finished
	if is_inside_tree():
		_start_idle_animations()


func _start_idle_animations() -> void:
	var logo_tween: Tween = create_tween().set_loops()
	logo_tween.tween_property(_logo, "scale", Vector2(1.03, 1.03), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	logo_tween.tween_property(_logo, "scale", Vector2(1.0, 1.0), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var prompt_tween: Tween = create_tween().set_loops()
	prompt_tween.tween_property(_prompt_panel, "modulate:a", 0.55, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	prompt_tween.tween_property(_prompt_panel, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# Uses _input (not _unhandled_input) because the root Control would
# otherwise swallow mouse clicks before they reach _unhandled_input.
func _input(event: InputEvent) -> void:
	if _has_started or GameState.is_transitioning():
		return

	var should_start: bool = false

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		should_start = key_event.pressed and not key_event.echo
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		should_start = mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT

	if should_start:
		_has_started = true
		get_viewport().set_input_as_handled()
		GameState.play_sfx(&"start")
		GameState.change_scene(MAIN_MENU_SCENE)
