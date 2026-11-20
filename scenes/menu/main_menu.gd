# res://scenes/menu/main_menu.gd
# Node: MainMenu (Control)
extends Control

const ACTIVITIES_SCENE: String = "res://scenes/activities/activities_screen.tscn"
const CHALLENGES_SCENE: String = "res://scenes/challenges/challenges_screen.tscn"
const PROGRESS_SCENE: String = "res://scenes/menu/progress_screen.tscn"
const SETTINGS_SCENE: String = "res://scenes/menu/settings.tscn"
const ABOUT_SCENE: String = "res://scenes/menu/about_screen.tscn"

const MASCOT_IDLE: Texture2D = preload("res://assets/art/mascot.svg")
const MASCOT_TALK: Texture2D = preload("res://assets/art/mascot_talk.svg")
const LOCK_ICON: Texture2D = preload("res://assets/ui/lock.svg")
const CROWN_ICON: Texture2D = preload("res://assets/art/stickers/sticker_crown.svg")
const SPARKLE_ICON: Texture2D = preload("res://assets/art/sparkle.svg")
const STAR_RAINBOW: Texture2D = preload("res://assets/ui/star_rainbow.svg")

@onready var _coins_label: Label = %CoinsLabel
@onready var _stars_label: Label = %StarsLabel
@onready var _badge_icon: StickerView = %BadgeIcon
@onready var _mascot: TextureRect = %MascotTexture
@onready var _greeting_label: Label = %GreetingLabel
@onready var _mascot_card: PanelContainer = %MascotCard
@onready var _menu_panel: PanelContainer = %MenuPanel

@onready var _play_btn: Button = %PlayButton
@onready var _challenges_btn: Button = %ChallengesButton
@onready var _progress_btn: Button = %ProgressButton
@onready var _settings_btn: Button = %SettingsButton
@onready var _about_btn: Button = %AboutButton
@onready var _quit_btn: Button = %QuitButton

var _talker: TalkingAvatar
var _greeting_index: int = 0
var _is_completed: bool = false
var _champion_crown: TextureRect
var _champion_sparkles: Array[TextureRect] = []
var _champion_time: float = 0.0
var _trick_index: int = 0


func _ready() -> void:
	GameState.set_bgm_context(&"menu")
	_is_completed = GameState.is_game_completed()
	_update_stats(GameState.coins, GameState.stars)
	GameState.stats_changed.connect(_update_stats)
	_configure_challenges_button()
	_setup_keyboard_navigation()
	_connect_signals()

	_talker = TalkingAvatar.new()
	add_child(_talker)
	_talker.setup(_mascot, _greeting_label, MASCOT_IDLE, MASCOT_TALK)
	_mascot_card.gui_input.connect(_on_mascot_card_clicked)

	if _is_completed:
		_setup_champion_pip()

	if not GameState.reduce_motion:
		_play_entrance()
	_say_welcome()


func _configure_challenges_button() -> void:
	if _is_completed:
		_challenges_btn.disabled = false
		_challenges_btn.icon = CROWN_ICON
		_challenges_btn.expand_icon = true
		_challenges_btn.text = "CHALLENGES"
		_challenges_btn.tooltip_text = "Timer Blitz & Endless Marathon!"

		var normal: StyleBoxFlat = StyleBoxFlat.new()
		normal.content_margin_left = 20.0
		normal.content_margin_top = 12.0
		normal.content_margin_right = 20.0
		normal.content_margin_bottom = 14.0
		normal.bg_color = Color(0.62, 0.44, 0.96, 1.0)
		normal.border_width_left = 4
		normal.border_width_top = 4
		normal.border_width_right = 4
		normal.border_width_bottom = 8
		normal.border_color = Color(0.184314, 0.282353, 0.345098, 1.0)
		normal.corner_radius_top_left = 18
		normal.corner_radius_top_right = 18
		normal.corner_radius_bottom_right = 18
		normal.corner_radius_bottom_left = 18

		var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.70, 0.54, 1.0, 1.0)
		var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
		pressed.bg_color = Color(0.52, 0.34, 0.86, 1.0)

		_challenges_btn.add_theme_color_override("font_color", Color(1.0, 0.9725, 0.9059, 1.0))
		_challenges_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9725, 0.9059, 1.0))
		_challenges_btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.9725, 0.9059, 1.0))
		_challenges_btn.add_theme_stylebox_override("normal", normal)
		_challenges_btn.add_theme_stylebox_override("hover", hover)
		_challenges_btn.add_theme_stylebox_override("pressed", pressed)
	else:
		var done: int = GameState.get_completed_activities_count()
		var total_act: int = GameState.activity_stars.size()
		_challenges_btn.disabled = true
		_challenges_btn.icon = LOCK_ICON
		_challenges_btn.expand_icon = true
		_challenges_btn.text = "CHALLENGES (%d/%d)" % [done, total_act]
		_challenges_btn.tooltip_text = "Complete Level 8 in all %d activities to unlock Challenges!" % total_act


func _setup_champion_pip() -> void:
	# Royal golden-violet border on Pip's card
	var champ_style: StyleBoxFlat = StyleBoxFlat.new()
	champ_style.content_margin_left = 20.0
	champ_style.content_margin_top = 16.0
	champ_style.content_margin_right = 20.0
	champ_style.content_margin_bottom = 18.0
	champ_style.bg_color = Color(1.0, 0.985, 0.91, 1.0)
	champ_style.border_width_left = 5
	champ_style.border_width_top = 5
	champ_style.border_width_right = 5
	champ_style.border_width_bottom = 9
	champ_style.border_color = Color(0.92, 0.65, 0.08, 1.0)
	champ_style.corner_radius_top_left = 26
	champ_style.corner_radius_top_right = 26
	champ_style.corner_radius_bottom_right = 26
	champ_style.corner_radius_bottom_left = 26
	_mascot_card.add_theme_stylebox_override("panel", champ_style)

	var vbox: VBoxContainer = _mascot.get_parent() as VBoxContainer
	if vbox != null:
		var banner: PanelContainer = PanelContainer.new()
		banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var b_style: StyleBoxFlat = StyleBoxFlat.new()
		b_style.content_margin_left = 14.0
		b_style.content_margin_top = 4.0
		b_style.content_margin_right = 14.0
		b_style.content_margin_bottom = 5.0
		b_style.bg_color = Color(0.62, 0.44, 0.96, 1.0)
		b_style.border_width_left = 2
		b_style.border_width_top = 2
		b_style.border_width_right = 2
		b_style.border_width_bottom = 4
		b_style.border_color = Color(0.184314, 0.282353, 0.345098, 1.0)
		b_style.corner_radius_top_left = 999
		b_style.corner_radius_top_right = 999
		b_style.corner_radius_bottom_right = 999
		b_style.corner_radius_bottom_left = 999
		banner.add_theme_stylebox_override("panel", b_style)

		var b_lbl: Label = Label.new()
		b_lbl.text = "GRAND CHAMPION PIP!"
		b_lbl.add_theme_font_size_override("font_size", 15)
		b_lbl.add_theme_color_override("font_color", Color(1.0, 0.9725, 0.9059, 1.0))
		banner.add_child(b_lbl)
		vbox.add_child(banner)
		vbox.move_child(banner, 0)

	# Floating Crown perched atop Pip's head + orbiting sparkles
	_champion_crown = TextureRect.new()
	_champion_crown.texture = CROWN_ICON
	_champion_crown.custom_minimum_size = Vector2(64, 64)
	_champion_crown.size = Vector2(64, 64)
	_champion_crown.pivot_offset = Vector2(32, 32)
	_champion_crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_champion_crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_champion_crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_champion_crown.position = Vector2(83, -24)
	_mascot.add_child(_champion_crown)

	for i: int in 4:
		var sp: TextureRect = TextureRect.new()
		sp.texture = STAR_RAINBOW if i % 2 == 0 else SPARKLE_ICON
		sp.custom_minimum_size = Vector2(24, 24)
		sp.size = Vector2(24, 24)
		sp.pivot_offset = Vector2(12, 12)
		sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mascot.add_child(sp)
		_champion_sparkles.append(sp)

	if not GameState.reduce_motion:
		call_deferred("_play_champion_entrance")


func _play_champion_entrance() -> void:
	if not is_inside_tree():
		return
	_mascot.pivot_offset = _mascot.size * 0.5
	var flip: Tween = create_tween()
	flip.tween_interval(0.35)
	flip.tween_property(_mascot, "rotation", TAU, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	flip.tween_callback(func() -> void: _mascot.rotation = 0.0)
	CelebrationFX.spawn_confetti_burst(self, _mascot.global_position + _mascot.size * 0.5, 20)


func _process(delta: float) -> void:
	if not _is_completed or GameState.reduce_motion:
		return
	_champion_time += delta
	if _champion_crown != null:
		_champion_crown.position.y = -24.0 + sin(_champion_time * 3.2) * 5.0
		_champion_crown.rotation = sin(_champion_time * 2.4) * 0.14
	var center: Vector2 = _mascot.size * 0.5
	for i: int in _champion_sparkles.size():
		var sp: TextureRect = _champion_sparkles[i]
		var ang: float = _champion_time * 1.4 + float(i) * (TAU / float(_champion_sparkles.size()))
		sp.position = center + Vector2(cos(ang) * 116.0, sin(ang) * 98.0) - sp.size * 0.5
		var tw: float = 0.6 + 0.4 * absf(sin(_champion_time * 3.5 + float(i)))
		sp.scale = Vector2(tw, tw)
		sp.rotation = _champion_time * 1.8


func _say_welcome() -> void:
	if _is_completed:
		_talker.say("YOU BEAT ALL 10 ACTIVITIES!\nTap me or enter Challenges!")
	elif GameState.stars >= 9:
		_talker.say("Look at all %d stars!\nYou're a math superstar!" % GameState.stars)
	elif GameState.total_solved > 0:
		_talker.say("Welcome back! We've\nsolved %d puzzles so far!" % GameState.total_solved)
	else:
		_talker.say("Hi, I'm Pip! Ready to\nplay with numbers?")


func _on_mascot_card_clicked(event: InputEvent) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return

	if _is_completed:
		_play_champion_party_trick()
		return

	var lines: Array[String] = [
		"Mistakes just mean\nwe're learning!",
		"Check Progress & Sticker\nShop sometime!",
		"Every puzzle earns\nyou shiny coins!",
		"Let's visit The Little\nShop or Puzzle Doors!",
	]
	_talker.react_happy()
	_talker.say(lines[_greeting_index % lines.size()])
	_greeting_index += 1


func _play_champion_party_trick() -> void:
	var lines: Array[String] = [
		"Hooray! Champion flip!\nNothing can stop us!",
		"Timer Blitz & Endless\nawait in Challenges!",
		"You mastered all 8 levels\nacross all 10 activities!",
	]
	var center: Vector2 = _mascot.global_position + _mascot.size * 0.5
	_talker.react_happy()
	_talker.say(lines[_trick_index % lines.size()])

	if not GameState.reduce_motion:
		_mascot.pivot_offset = _mascot.size * 0.5
		match _trick_index % 3:
			0:
				var tw: Tween = create_tween()
				tw.tween_property(_mascot, "rotation", TAU, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_callback(func() -> void: _mascot.rotation = 0.0)
				CelebrationFX.spawn_confetti_burst(self, center, 18)
			1:
				CelebrationFX.spawn_sparkles(self, center)
				CelebrationFX.spawn_floating_text(self, center - Vector2(0, 40), "MATH CHAMPION!")
			2:
				if _champion_crown != null:
					var tw_c: Tween = create_tween()
					tw_c.tween_property(_champion_crown, "position:y", -58.0, 0.22).set_ease(Tween.EASE_OUT)
					tw_c.tween_property(_champion_crown, "position:y", -24.0, 0.26).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
				CelebrationFX.spawn_sparkles(self, center)
	_trick_index += 1


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
		_challenges_btn,
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
	_challenges_btn.pressed.connect(_on_challenges_pressed)
	_progress_btn.pressed.connect(_on_progress_pressed)
	_settings_btn.pressed.connect(_on_settings_pressed)
	_about_btn.pressed.connect(_on_about_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	GameState.change_scene(ACTIVITIES_SCENE)


func _on_challenges_pressed() -> void:
	if _is_completed:
		GameState.change_scene(CHALLENGES_SCENE)


func _on_progress_pressed() -> void:
	GameState.change_scene(PROGRESS_SCENE)


func _on_settings_pressed() -> void:
	GameState.change_scene(SETTINGS_SCENE)


func _on_about_pressed() -> void:
	GameState.change_scene(ABOUT_SCENE)


func _on_quit_pressed() -> void:
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
