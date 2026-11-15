# res://scenes/menu/sub_screen_placeholder.gd
# Node: SubScreenPlaceholder (Control)
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/menu/main_menu.tscn"

@export var screen_title: String = "COMING SOON"
@export_multiline var screen_description: String = "This screen will be built in the next phase."

@onready var _title_label: Label = %TitleLabel
@onready var _desc_label: Label = %DescriptionLabel
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_title_label.text = screen_title
	_desc_label.text = screen_description
	_back_button.pressed.connect(_go_back)
	_back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		GameState.play_sfx(&"back")
		_go_back()


func _go_back() -> void:
	GameState.change_scene(MAIN_MENU_SCENE)
