# res://scenes/menu/settings.gd
# Node: Settings (Control)
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"

@onready var _music_toggle: CheckButton = %MusicToggle
@onready var _sfx_toggle: CheckButton = %SfxToggle
@onready var _motion_toggle: CheckButton = %MotionToggle
@onready var _resolution_button: Button = %ResolutionButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	# Set current values BEFORE connecting, so loading doesn't trigger saves.
	_music_toggle.button_pressed = GameState.music_enabled
	_sfx_toggle.button_pressed = GameState.sfx_enabled
	_motion_toggle.button_pressed = GameState.reduce_motion
	_refresh_resolution_label()

	_music_toggle.toggled.connect(_on_music_toggled)
	_sfx_toggle.toggled.connect(_on_sfx_toggled)
	_motion_toggle.toggled.connect(_on_motion_toggled)
	_resolution_button.pressed.connect(_on_resolution_pressed)
	_back_button.pressed.connect(_go_back)
	_music_toggle.grab_focus()


func _on_music_toggled(enabled: bool) -> void:
	GameState.set_music_enabled(enabled)


func _on_sfx_toggled(enabled: bool) -> void:
	GameState.set_sfx_enabled(enabled)


func _on_motion_toggled(enabled: bool) -> void:
	GameState.set_reduce_motion(enabled)


func _on_resolution_pressed() -> void:
	GameState.set_resolution_index(GameState.resolution_index + 1)
	_refresh_resolution_label()


func _refresh_resolution_label() -> void:
	_resolution_button.text = GameState.get_resolution_label()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		GameState.play_sfx(&"back")
		_go_back()


func _go_back() -> void:
	GameState.change_scene(MAIN_MENU_SCENE)
