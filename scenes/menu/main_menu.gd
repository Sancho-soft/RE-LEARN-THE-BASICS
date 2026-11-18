# res://scenes/menu/main_menu.gd
# Node: MainMenu (Control)
extends Control

const ACTIVITIES_SCENE: String = "res://scenes/activities/activities_screen.tscn"
const PROGRESS_SCENE: String = "res://scenes/menu/progress_screen.tscn"
const SETTINGS_SCENE: String = "res://scenes/menu/settings.tscn"
const ABOUT_SCENE: String = "res://scenes/menu/about_screen.tscn"

const MASCOT_IDLE: Texture2D = preload("res://assets/art/mascot.svg")
const MASCOT_TALK: Texture2D = preload("res://assets/art/mascot_talk.svg")

@onready var _coins_label: Label = %CoinsLabel
@onready var _stars_label: Label = %StarsLabel
@onready var _badge_icon: StickerView = %BadgeIcon
@onready var _mascot: TextureRect = %MascotTexture
@onready var _greeting_label: Label = %GreetingLabel
@onready var _mascot_card: PanelContainer = %MascotCard
@onready var _menu_panel: PanelContainer = %MenuPanel

@onready var _play_btn: Button = %PlayButton
@onready var _activities_btn: Button = %ActivitiesButton
@onready var _progress_btn: Button = %ProgressButton
@onready var _settings_btn: Button = %SettingsButton
@onready var _about_btn: Button = %AboutButton
@onready var _quit_btn: Button = %QuitButton

var _talker: TalkingAvatar
var _greeting_index: int = 0


func _ready() -> void:
	GameState.set_bgm_context(&"menu")
	_update_stats(GameState.coins, GameState.stars)
	GameState.stats_changed.connect(_update_stats)
	_setup_keyboard_navigation()
	_connect_signals()

	_talker = TalkingAvatar.new()
	add_child(_talker)
	_talker.setup(_mascot, _greeting_label, MASCOT_IDLE, MASCOT_TALK)
	_mascot_card.gui_input.connect(_on_mascot_card_clicked)

	if not GameState.reduce_motion:
		_play_entrance()
	_say_welcome()


func _say_welcome() -> void:
	if GameState.stars >= 9:
		_talker.say("Look at all %d stars!\nYou're a math superstar!" % GameState.stars)
	elif GameState.total_solved > 0:
		_talker.say("Welcome back! We've\nsolved %d puzzles so far!" % GameState.total_solved)
	else:
		_talker.say("Hi, I'm Pip! Ready to\nplay with numbers?")


func _on_mascot_card_clicked(event: InputEvent) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var lines: Array[String] = [
			"Mistakes just mean\nwe're learning!",
			"Check the Sticker Shop\nin Progress sometime!",
			"Every puzzle earns\nyou shiny coins!",
			"Let's visit The Little\nShop or Puzzle Doors!",
		]
		_talker.react_happy()
		_talker.say(lines[_greeting_index % lines.size()])
		_greeting_index += 1


func _play_entrance() -> void:
	for i: int in 2:
		var card: Control = _mascot_card if i == 0 else _menu_panel
		card.modulate.a = 0.0
		card.pivot_offset = card.size * 0.5
		card.scale = Vector2(0.95, 0.95)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.25).set_delay(0.06 * float(i))
		tween.tween_property(card, "scale", Vector2.ONE, 0.3).set_delay(0.06 * float(i)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_stats(new_coins: int, new_stars: int) -> void:
	_coins_label.text = str(new_coins)
	_stars_label.text = str(new_stars)
	var badge_path: String = GameState.get_sticker_icon_path(GameState.equipped_sticker)
	if badge_path != "":
		_badge_icon.setup_sticker(GameState.equipped_sticker, Vector2(42, 42), false)
		_badge_icon.visible = true
	else:
		_badge_icon.visible = false


func _setup_keyboard_navigation() -> void:
	var buttons: Array[Button] = [
		_play_btn,
		_activities_btn,
		_progress_btn,
		_settings_btn,
		_about_btn,
		_quit_btn,
	]
	var count: int = buttons.size()
	for i: int in count:
		var prev_idx: int = (i - 1 + count) % count
		var next_idx: int = (i + 1) % count
		buttons[i].focus_neighbor_top = buttons[i].get_path_to(buttons[prev_idx])
		buttons[i].focus_neighbor_bottom = buttons[i].get_path_to(buttons[next_idx])


func _connect_signals() -> void:
	_play_btn.pressed.connect(_on_play_pressed)
	_activities_btn.pressed.connect(_on_activities_pressed)
	_progress_btn.pressed.connect(_on_progress_pressed)
	_settings_btn.pressed.connect(_on_settings_pressed)
	_about_btn.pressed.connect(_on_about_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	GameState.change_scene(ACTIVITIES_SCENE)


func _on_activities_pressed() -> void:
	GameState.change_scene(ACTIVITIES_SCENE)


func _on_progress_pressed() -> void:
	GameState.change_scene(PROGRESS_SCENE)


func _on_settings_pressed() -> void:
	GameState.change_scene(SETTINGS_SCENE)


func _on_about_pressed() -> void:
	GameState.change_scene(ABOUT_SCENE)


func _on_quit_pressed() -> void:
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
