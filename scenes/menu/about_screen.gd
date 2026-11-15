# res://scenes/menu/about_screen.gd
# Node: AboutScreen (Control)
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"
const MASCOT_IDLE: Texture2D = preload("res://assets/art/mascot.svg")
const MASCOT_TALK: Texture2D = preload("res://assets/art/mascot_talk.svg")
const RARE_THEME_CLICKS: int = 5

@onready var _mascot: TextureRect = %MascotTexture
@onready var _speech_label: Label = %SpeechLabel
@onready var _card: PanelContainer = %Card
@onready var _creator1: Label = %Creator1
@onready var _creator2: Label = %Creator2
@onready var _back_button: Button = %BackButton

var _talker: TalkingAvatar
var _creator_clicks: int = 0


func _ready() -> void:
	_back_button.pressed.connect(_go_back)
	_back_button.grab_focus()
	_creator1.gui_input.connect(_on_creator_gui_input)
	_creator2.gui_input.connect(_on_creator_gui_input)

	_talker = TalkingAvatar.new()
	add_child(_talker)
	_talker.setup(_mascot, _speech_label, MASCOT_IDLE, MASCOT_TALK)
	_talker.say("Thank you for playing Re-Learn The Basics!")
	_talker.react_happy()

	if not GameState.reduce_motion:
		_card.modulate.a = 0.0
		_card.pivot_offset = _card.size * 0.5
		_card.scale = Vector2(0.95, 0.95)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(_card, "modulate:a", 1.0, 0.25)
		tween.tween_property(_card, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		GameState.play_sfx(&"back")
		_go_back()


func _on_creator_gui_input(event: InputEvent) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if GameState.is_rare_theme_active():
		return
	_creator_clicks += 1
	if _creator_clicks >= RARE_THEME_CLICKS and GameState.activate_rare_theme():
		_talker.react_happy()
		_talker.say("Ooh! You unlocked the secret rare theme!")


func _go_back() -> void:
	GameState.change_scene(MAIN_MENU_SCENE)
