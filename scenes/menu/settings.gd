# res://scenes/menu/settings.gd
# Node: Settings (Control)
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"

@onready var _music_toggle: CheckButton = %MusicToggle
@onready var _bgm_volume_row: HBoxContainer = %BgmVolumeRow
@onready var _bgm_slider: HSlider = %BgmVolumeSlider
@onready var _bgm_volume_label: Label = %BgmVolumeValueLabel
@onready var _sfx_toggle: CheckButton = %SfxToggle
@onready var _motion_toggle: CheckButton = %MotionToggle
@onready var _resolution_button: Button = %ResolutionButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	# Set current values BEFORE connecting, so loading doesn't trigger saves.
	_music_toggle.button_pressed = GameState.music_enabled
	_bgm_slider.value = GameState.bgm_volume_percent
	_refresh_bgm_volume_ui(GameState.bgm_volume_percent)
	_sfx_toggle.button_pressed = GameState.sfx_enabled
	_motion_toggle.button_pressed = GameState.reduce_motion
	_refresh_resolution_label()

	_music_toggle.toggled.connect(_on_music_toggled)
	_bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	_bgm_slider.drag_ended.connect(_on_bgm_slider_drag_ended)
	_sfx_toggle.toggled.connect(_on_sfx_toggled)
	_motion_toggle.toggled.connect(_on_motion_toggled)
	_resolution_button.pressed.connect(_on_resolution_pressed)
	_back_button.pressed.connect(_go_back)
	_music_toggle.grab_focus()


func _on_music_toggled(enabled: bool) -> void:
	GameState.set_music_enabled(enabled)
	_refresh_bgm_volume_ui(roundi(_bgm_slider.value))


func _on_bgm_volume_changed(value: float) -> void:
	var percent: int = roundi(value)
	GameState.set_bgm_volume_percent(percent)
	_refresh_bgm_volume_ui(percent)


func _on_bgm_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		GameState.play_sfx(&"click")


func _refresh_bgm_volume_ui(percent: int) -> void:
	_bgm_volume_label.text = "%d%%" % percent
	_bgm_volume_row.modulate.a = 1.0 if GameState.music_enabled else 0.55


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
