# res://autoload/game_state.gd
# Autoload singleton: GameState
# The project's only autoload: progress (coins/stars/tiers/stickers), settings,
# save/load, scene transitions, background music, and UI/gameplay sound playback.
extends Node

const SAVE_PATH: String = "user://save_data.cfg"
const MAX_ACTIVITY_TIER: int = 8
const FADE_COLOR: Color = Color(0.184314, 0.282353, 0.345098, 1.0) # Dark teal #2F4858
const FADE_DURATION: float = 0.18

const BGM_PATH: String = "res://assets/audio/bgm_cozy.mp3"
const ACTIVITY_BGM_PATH: String = "res://assets/audio/bgm_activity.mp3"
const RARE_BGM_PATH: String = "res://scenes/menu/re-learn the basics main theme (Secret).mp3"
const BGM_BASE_DB: float = -10.0
const BGM_ACTIVITY_DB: float = -16.5
const BGM_DUCK_DB: float = -16.0
const BGM_ACTIVITY_DUCK_DB: float = -22.5
const BGM_SILENT_DB: float = -80.0
const BGM_FADE_DURATION: float = 0.8
const BGM_SWITCH_DURATION: float = 0.45

const SFX_PATHS: Dictionary = {
	&"hover": "res://assets/audio/ui_hover.wav",
	&"click": "res://assets/audio/ui_click.wav",
	&"back": "res://assets/audio/ui_back.wav",
	&"start": "res://assets/audio/ui_start.wav",
	&"toggle": "res://assets/audio/ui_toggle.wav",
	&"correct": "res://assets/audio/sfx_correct.wav",
	&"hint": "res://assets/audio/sfx_hint.wav",
	&"win": "res://assets/audio/sfx_win.wav",
	&"talk": "res://assets/audio/sfx_talk.wav",
}
const SFX_VOICES: int = 4
const SFX_PITCH_VARIATION: float = 0.05

const STICKER_CATALOG: Array[Dictionary] = [
	{"id": "sprout", "name": "Sprout", "cost": 15, "icon": "res://assets/art/stickers/sticker_sprout.svg", "animated": false},
	{"id": "cat", "name": "Cozy Kitty", "cost": 25, "icon": "res://assets/art/stickers/sticker_cat.svg", "animated": false},
	{"id": "rainbow", "name": "Rainbow", "cost": 35, "icon": "res://assets/art/stickers/sticker_rainbow.svg", "animated": false},
	{"id": "rocket", "name": "Rocket", "cost": 45, "icon": "res://assets/art/stickers/sticker_rocket.svg", "animated": false},
	{"id": "crown", "name": "Gold Crown", "cost": 60, "icon": "res://assets/art/stickers/sticker_crown.svg", "animated": false},
	{"id": "trophy", "name": "Math Trophy", "cost": 80, "icon": "res://assets/art/stickers/sticker_trophy.svg", "animated": false},
	{"id": "dino", "name": "Happy Dino", "cost": 95, "icon": "res://assets/art/stickers/sticker_dino.svg", "animated": false},
	{"id": "unicorn", "name": "Star Unicorn", "cost": 115, "icon": "res://assets/art/stickers/sticker_unicorn.svg", "animated": false},
	{"id": "panda", "name": "Cozy Panda", "cost": 135, "icon": "res://assets/art/stickers/sticker_panda.svg", "animated": false},
	{"id": "shooting_star", "name": "Comet Star", "cost": 180, "icon": "res://assets/art/stickers/sticker_shooting_star.svg", "animated": true, "anim_style": "comet"},
	{"id": "dragon", "name": "Galaxy Dragon", "cost": 240, "icon": "res://assets/art/stickers/sticker_dragon.svg", "animated": true, "anim_style": "float"},
	{"id": "prism_owl", "name": "Prism Owl", "cost": 320, "icon": "res://assets/art/stickers/sticker_prism_owl.svg", "animated": true, "anim_style": "rainbow"},
]

const RESOLUTION_PRESETS: Array[Dictionary] = [
	{"label": "1280 x 720 (HD)", "size": Vector2i(1280, 720), "fullscreen": false},
	{"label": "1600 x 900", "size": Vector2i(1600, 900), "fullscreen": false},
	{"label": "1920 x 1080 (Full HD)", "size": Vector2i(1920, 1080), "fullscreen": false},
	{"label": "Fullscreen", "size": Vector2i(1280, 720), "fullscreen": true},
]

signal stats_changed(new_coins: int, new_stars: int)
signal settings_changed

# --- Progress ---
var coins: int = 0
var stars: int = 0
var total_solved: int = 0
var activity_stars: Dictionary = {
	"little_shop": 0,
	"puzzle_doors": 0,
	"little_builder": 0,
	"fair_sharing": 0,
	"number_patterns": 0,
	"clock_time": 0,
	"rocket_shapes": 0,
	"coin_jar": 0,
}
var activity_level_stars: Dictionary = {}
var activity_tiers: Dictionary = {
	"little_shop": 1,
	"puzzle_doors": 1,
	"little_builder": 1,
	"fair_sharing": 1,
	"number_patterns": 1,
	"clock_time": 1,
	"rocket_shapes": 1,
	"coin_jar": 1,
}
var shop_tier: int:
	get:
		return get_activity_tier("little_shop")
	set(value):
		set_activity_tier("little_shop", value)

var unlocked_stickers: Array[String] = []
var equipped_sticker: String = ""

var active_activity_id: String = "little_shop"
var last_run_summary: Dictionary = {}

# --- Settings ---
var sfx_enabled: bool = true
var music_enabled: bool = true
var bgm_volume_percent: int = 100
var reduce_motion: bool = false
var resolution_index: int = 0

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _is_transitioning: bool = false

var _bgm_player: AudioStreamPlayer
var _duck_tween: Tween
var _bgm_fade_tween: Tween
var _is_fading_bgm: bool = false
var _bgm_context: StringName = &"menu"
var _is_rare_theme_active: bool = false
var _menu_bgm_stream: AudioStream
var _activity_bgm_stream: AudioStream
var _rare_bgm_stream: AudioStream
var _texture_cache: Dictionary = {}

var _sfx_streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_voice: int = 0


func _ready() -> void:
	load_game()
	_apply_display_settings()
	_setup_fade_overlay()
	_setup_sfx()
	_setup_bgm()


# ---------------------------------------------------------------- Transitions

func _setup_fade_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(FADE_COLOR.r, FADE_COLOR.g, FADE_COLOR.b, 0.0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


func change_scene(scene_path: String, duration: float = FADE_DURATION) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var fade_time: float = duration * 0.5 if reduce_motion else duration
	var tween_out: Tween = create_tween()
	tween_out.tween_property(_fade_rect, "color:a", 1.0, fade_time).set_ease(Tween.EASE_IN)
	await tween_out.finished

	var err: Error = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("GameState: Failed to load scene: %s" % scene_path)

	var tween_in: Tween = create_tween()
	tween_in.tween_property(_fade_rect, "color:a", 0.0, fade_time).set_ease(Tween.EASE_OUT)
	await tween_in.finished

	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false


func is_transitioning() -> bool:
	return _is_transitioning


# ---------------------------------------------------------------- Audio & Music

func _setup_bgm() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = &"Master"
	_bgm_player.volume_db = _get_bgm_target_db()
	add_child(_bgm_player)

	_menu_bgm_stream = _load_bgm_stream(BGM_PATH)
	_activity_bgm_stream = _load_bgm_stream(ACTIVITY_BGM_PATH)
	if _menu_bgm_stream != null:
		_bgm_player.stream = _menu_bgm_stream
		if music_enabled:
			_bgm_player.play()
	else:
		push_warning("GameState: Missing BGM at %s" % BGM_PATH)


func _get_bgm_base_db() -> float:
	return BGM_ACTIVITY_DB if _bgm_context == &"activity" else BGM_BASE_DB


func _get_bgm_target_db() -> float:
	if bgm_volume_percent <= 0:
		return BGM_SILENT_DB
	return maxf(_get_bgm_base_db() + linear_to_db(float(bgm_volume_percent) / 100.0), BGM_SILENT_DB)


func _get_bgm_duck_db() -> float:
	if bgm_volume_percent <= 0:
		return BGM_SILENT_DB
	var duck_base: float = BGM_ACTIVITY_DUCK_DB if _bgm_context == &"activity" else BGM_DUCK_DB
	return maxf(duck_base + linear_to_db(float(bgm_volume_percent) / 100.0), BGM_SILENT_DB)


func _get_stream_for_context(context: StringName) -> AudioStream:
	if _is_rare_theme_active:
		var rare_stream: AudioStream = _load_rare_bgm()
		if rare_stream != null:
			return rare_stream
	if context == &"activity":
		if _activity_bgm_stream == null:
			_activity_bgm_stream = _load_bgm_stream(ACTIVITY_BGM_PATH)
		if _activity_bgm_stream != null:
			return _activity_bgm_stream
	if _menu_bgm_stream == null:
		_menu_bgm_stream = _load_bgm_stream(BGM_PATH)
	return _menu_bgm_stream


func set_bgm_context(context: StringName) -> void:
	if _bgm_context == context:
		return
	_bgm_context = context
	if _bgm_player == null:
		return

	var target_stream: AudioStream = _get_stream_for_context(context)
	var target_db: float = _get_bgm_target_db()

	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	if _bgm_fade_tween != null and _bgm_fade_tween.is_valid():
		_bgm_fade_tween.kill()
	_is_fading_bgm = false

	if not music_enabled:
		if target_stream != null and _bgm_player.stream != target_stream:
			_bgm_player.stream = target_stream
		_bgm_player.volume_db = target_db
		return

	if target_stream == null:
		return

	# Same stream (e.g. secret rare theme active): just smoothly adjust volume for gameplay focus.
	if _bgm_player.stream == target_stream and _bgm_player.playing:
		var vol_time: float = 0.25 if reduce_motion else BGM_SWITCH_DURATION
		_is_fading_bgm = true
		_bgm_fade_tween = create_tween()
		_bgm_fade_tween.tween_property(_bgm_player, "volume_db", target_db, vol_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_bgm_fade_tween.tween_callback(func() -> void: _is_fading_bgm = false)
		return

	var fade_time: float = 0.22 if reduce_motion else BGM_SWITCH_DURATION
	_is_fading_bgm = true
	_bgm_fade_tween = create_tween()
	if _bgm_player.playing:
		_bgm_fade_tween.tween_property(_bgm_player, "volume_db", BGM_SILENT_DB, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_bgm_fade_tween.tween_callback(_switch_bgm_stream.bind(target_stream))
	else:
		_switch_bgm_stream(target_stream)
	_bgm_fade_tween.tween_property(_bgm_player, "volume_db", target_db, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_bgm_fade_tween.tween_callback(func() -> void: _is_fading_bgm = false)


func _switch_bgm_stream(target_stream: AudioStream) -> void:
	if _bgm_player == null:
		return
	_bgm_player.stop()
	_bgm_player.stream = target_stream
	_bgm_player.volume_db = BGM_SILENT_DB
	if music_enabled:
		_bgm_player.play()


func _duck_bgm(hold_sec: float = 0.35) -> void:
	if not music_enabled or not _bgm_player.playing or _is_fading_bgm:
		return
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(_bgm_player, "volume_db", _get_bgm_duck_db(), 0.08)
	_duck_tween.tween_interval(hold_sec)
	_duck_tween.tween_property(_bgm_player, "volume_db", _get_bgm_target_db(), 0.45)


func is_rare_theme_active() -> bool:
	return _is_rare_theme_active


func activate_rare_theme() -> bool:
	if _is_rare_theme_active:
		return false
	var rare_stream: AudioStream = _load_rare_bgm()
	if rare_stream == null:
		push_warning("GameState: Missing rare BGM at %s" % RARE_BGM_PATH)
		return false

	# Session-only easter egg: intentionally not persisted so default BGM returns on next launch.
	_is_rare_theme_active = true
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	if _bgm_fade_tween != null and _bgm_fade_tween.is_valid():
		_bgm_fade_tween.kill()

	if _bgm_player == null:
		return true

	if not music_enabled:
		_bgm_player.stream = rare_stream
		_bgm_player.volume_db = _get_bgm_target_db()
		return true

	var fade_time: float = BGM_FADE_DURATION * 0.4 if reduce_motion else BGM_FADE_DURATION
	_is_fading_bgm = true
	_bgm_fade_tween = create_tween()
	if _bgm_player.playing:
		_bgm_fade_tween.tween_property(_bgm_player, "volume_db", BGM_SILENT_DB, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_bgm_fade_tween.tween_callback(_switch_to_rare_bgm.bind(rare_stream))
	else:
		_switch_to_rare_bgm(rare_stream)
	_bgm_fade_tween.tween_property(_bgm_player, "volume_db", _get_bgm_target_db(), fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_bgm_fade_tween.tween_callback(func() -> void: _is_fading_bgm = false)
	return true


func _load_rare_bgm() -> AudioStream:
	if _rare_bgm_stream != null:
		return _rare_bgm_stream
	_rare_bgm_stream = _load_bgm_stream(RARE_BGM_PATH)
	return _rare_bgm_stream


func _load_bgm_stream(path: String) -> AudioStream:
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	if stream == null and path.to_lower().ends_with(".mp3") and FileAccess.file_exists(path):
		stream = AudioStreamMP3.load_from_file(path)
	if stream is AudioStreamWAV:
		var wav: AudioStreamWAV = stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / 2
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	return stream


func _switch_to_rare_bgm(rare_stream: AudioStream) -> void:
	if _bgm_player == null:
		return
	_bgm_player.stop()
	_bgm_player.stream = rare_stream
	_bgm_player.volume_db = BGM_SILENT_DB
	if music_enabled:
		_bgm_player.play()


func _setup_sfx() -> void:
	for key: StringName in SFX_PATHS:
		var path: String = SFX_PATHS[key]
		if ResourceLoader.exists(path):
			_sfx_streams[key] = load(path)
		else:
			push_warning("GameState: Missing sound '%s' at %s" % [key, path])

	for i: int in SFX_VOICES:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_sfx_players.append(player)


func play_sfx(sfx_name: StringName, volume_db: float = 0.0) -> void:
	if not sfx_enabled or not _sfx_streams.has(sfx_name):
		return
	if sfx_name == &"correct" or sfx_name == &"win":
		_duck_bgm(0.65 if sfx_name == &"win" else 0.3)

	var player: AudioStreamPlayer = _sfx_players[_next_voice]
	_next_voice = (_next_voice + 1) % _sfx_players.size()
	player.stream = _sfx_streams[sfx_name]
	player.volume_db = volume_db
	player.pitch_scale = randf_range(1.0 - SFX_PITCH_VARIATION, 1.0 + SFX_PITCH_VARIATION)
	player.play()


# ---------------------------------------------------------------- Settings

func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	save_game()
	settings_changed.emit()


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if _bgm_player != null:
		if _bgm_fade_tween != null and _bgm_fade_tween.is_valid():
			_bgm_fade_tween.kill()
		_is_fading_bgm = false
		var expected_stream: AudioStream = _get_stream_for_context(_bgm_context)
		if expected_stream != null and _bgm_player.stream != expected_stream:
			_bgm_player.stop()
			_bgm_player.stream = expected_stream
		if music_enabled and _bgm_player.stream != null and not _bgm_player.playing:
			_bgm_player.volume_db = _get_bgm_target_db()
			_bgm_player.play()
		elif music_enabled and _bgm_player.playing:
			_bgm_player.volume_db = _get_bgm_target_db()
		elif not music_enabled and _bgm_player.playing:
			_bgm_player.stop()
			_bgm_player.volume_db = _get_bgm_target_db()
	save_game()
	settings_changed.emit()


func set_bgm_volume_percent(percent: int) -> void:
	bgm_volume_percent = clampi(percent, 0, 100)
	if _bgm_player != null and not _is_fading_bgm:
		if _duck_tween != null and _duck_tween.is_valid():
			_duck_tween.kill()
		_bgm_player.volume_db = _get_bgm_target_db()
	save_game()
	settings_changed.emit()


func set_reduce_motion(enabled: bool) -> void:
	reduce_motion = enabled
	save_game()
	settings_changed.emit()


func set_resolution_index(idx: int) -> void:
	resolution_index = posmod(idx, RESOLUTION_PRESETS.size())
	_apply_display_settings()
	save_game()
	settings_changed.emit()


func get_resolution_label() -> String:
	var safe_idx: int = clampi(resolution_index, 0, RESOLUTION_PRESETS.size() - 1)
	return str(RESOLUTION_PRESETS[safe_idx]["label"])


func _apply_display_settings() -> void:
	if OS.has_feature("headless"):
		return
	var safe_idx: int = clampi(resolution_index, 0, RESOLUTION_PRESETS.size() - 1)
	var preset: Dictionary = RESOLUTION_PRESETS[safe_idx]
	if bool(preset["fullscreen"]):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var target_size: Vector2i = preset["size"] as Vector2i
	var screen_id: int = DisplayServer.window_get_current_screen()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(screen_id)
	var applied_size: Vector2i = target_size
	if usable.size.x > 0 and usable.size.y > 0:
		applied_size.x = mini(target_size.x, usable.size.x)
		applied_size.y = mini(target_size.y, usable.size.y)
		var centered_pos: Vector2i = usable.position + (usable.size - applied_size) / 2
		DisplayServer.window_set_size(applied_size)
		DisplayServer.window_set_position(centered_pos)
	else:
		DisplayServer.window_set_size(applied_size)


# ---------------------------------------------------------------- Progress & Stickers

func get_highest_unlocked_tier(activity_id: String) -> int:
	var highest: int = 1
	for t: int in range(2, MAX_ACTIVITY_TIER + 1):
		if get_level_stars(activity_id, t - 1) > 0 or get_level_stars(activity_id, t) > 0:
			highest = t
		else:
			break
	# Also preserve access if a legacy save already has stars on a higher tier.
	for t: int in range(MAX_ACTIVITY_TIER, highest, -1):
		if get_level_stars(activity_id, t) > 0:
			highest = t
			break
	return clampi(highest, 1, MAX_ACTIVITY_TIER)


func is_level_unlocked(activity_id: String, tier: int) -> bool:
	if tier <= 1:
		return true
	return clampi(tier, 1, MAX_ACTIVITY_TIER) <= get_highest_unlocked_tier(activity_id)


func get_activity_tier(activity_id: String) -> int:
	var unlocked: int = get_highest_unlocked_tier(activity_id)
	return clampi(int(activity_tiers.get(activity_id, 1)), 1, unlocked)


func set_activity_tier(activity_id: String, tier: int, persist: bool = false) -> void:
	var unlocked: int = get_highest_unlocked_tier(activity_id)
	activity_tiers[activity_id] = clampi(tier, 1, unlocked)
	if persist:
		save_game()


func get_activity_tier_label(activity_id: String, tier: int = -1) -> String:
	var resolved_tier: int = get_activity_tier(activity_id) if tier < 1 else clampi(tier, 1, MAX_ACTIVITY_TIER)
	match activity_id:
		"little_shop":
			return ShopQuestionGenerator.get_tier_label(resolved_tier)
		"puzzle_doors":
			return DoorsQuestionGenerator.get_tier_label(resolved_tier)
		"little_builder":
			return BuilderQuestionGenerator.get_tier_label(resolved_tier)
		"fair_sharing":
			return SharingQuestionGenerator.get_tier_label(resolved_tier)
		"number_patterns":
			return PatternsQuestionGenerator.get_tier_label(resolved_tier)
		"clock_time":
			return TimeQuestionGenerator.get_tier_label(resolved_tier)
		"rocket_shapes":
			return ShapesQuestionGenerator.get_tier_label(resolved_tier)
		"coin_jar":
			return CoinJarQuestionGenerator.get_tier_label(resolved_tier)
	return "Level %d" % resolved_tier


func get_level_stars(activity_id: String, tier: int = -1) -> int:
	var resolved_tier: int = get_activity_tier(activity_id) if tier < 1 else clampi(tier, 1, MAX_ACTIVITY_TIER)
	var per_level: Variant = activity_level_stars.get(activity_id, {})
	if per_level is Dictionary:
		var level_dict: Dictionary = per_level as Dictionary
		if level_dict.has(resolved_tier):
			return clampi(int(level_dict[resolved_tier]), 0, 3)
		return clampi(int(level_dict.get(str(resolved_tier), 0)), 0, 3)
	return 0


func get_activity_total_stars(activity_id: String) -> int:
	var total: int = 0
	for tier_idx: int in range(1, MAX_ACTIVITY_TIER + 1):
		total += get_level_stars(activity_id, tier_idx)
	return total


func get_activity_completed_levels(activity_id: String) -> int:
	var count: int = 0
	for tier_idx: int in range(1, MAX_ACTIVITY_TIER + 1):
		if get_level_stars(activity_id, tier_idx) > 0:
			count += 1
	return count


func has_finished_max_level(activity_id: String) -> bool:
	return get_level_stars(activity_id, MAX_ACTIVITY_TIER) > 0


func get_max_activity_stars() -> int:
	return MAX_ACTIVITY_TIER * 3


func get_max_total_stars() -> int:
	return activity_stars.size() * MAX_ACTIVITY_TIER * 3


func add_rewards(earned_coins: int, earned_stars: int, activity_id: String = "", solved_count: int = 8, tier: int = -1) -> void:
	coins += maxi(earned_coins, 0)
	total_solved += maxi(solved_count, 0)
	if activity_id != "":
		var target_tier: int = get_activity_tier(activity_id) if tier < 1 else clampi(tier, 1, MAX_ACTIVITY_TIER)
		var per_level: Dictionary = _ensure_activity_level_dict(activity_id)
		var prev_best: int = clampi(int(per_level.get(target_tier, 0)), 0, 3)
		var clamped_stars: int = clampi(earned_stars, 0, 3)
		if clamped_stars > prev_best:
			per_level[target_tier] = clamped_stars
		_recalculate_total_stars()
	else:
		stars += maxi(earned_stars, 0)

	save_game()
	stats_changed.emit(coins, stars)


func unlock_sticker(sticker_id: String) -> bool:
	if sticker_id in unlocked_stickers:
		return false
	for item: Dictionary in STICKER_CATALOG:
		if str(item["id"]) == sticker_id:
			var cost: int = int(item["cost"])
			if coins < cost:
				return false
			coins -= cost
			unlocked_stickers.append(sticker_id)
			equipped_sticker = sticker_id
			save_game()
			stats_changed.emit(coins, stars)
			return true
	return false


func equip_sticker(sticker_id: String) -> void:
	if sticker_id == "" or sticker_id in unlocked_stickers:
		equipped_sticker = sticker_id
		save_game()
		stats_changed.emit(coins, stars)


func get_sticker_info(sticker_id: String) -> Dictionary:
	for item: Dictionary in STICKER_CATALOG:
		if str(item["id"]) == sticker_id:
			return item
	return {}


func is_sticker_animated(sticker_id: String) -> bool:
	var item: Dictionary = get_sticker_info(sticker_id)
	return bool(item.get("animated", false))


func get_sticker_icon_path(sticker_id: String) -> String:
	var item: Dictionary = get_sticker_info(sticker_id)
	return str(item.get("icon", ""))


func load_texture_safe(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null and path.to_lower().ends_with(".svg") and FileAccess.file_exists(path):
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
		if not bytes.is_empty():
			var img: Image = Image.new()
			if img.load_svg_from_buffer(bytes, 2.0) == OK:
				tex = ImageTexture.create_from_image(img)
	elif tex == null and FileAccess.file_exists(path):
		var img: Image = Image.load_from_file(path)
		if img != null:
			tex = ImageTexture.create_from_image(img)
	if tex != null:
		_texture_cache[path] = tex
	return tex


func _ensure_activity_level_dict(activity_id: String) -> Dictionary:
	if not activity_level_stars.has(activity_id) or not (activity_level_stars[activity_id] is Dictionary):
		activity_level_stars[activity_id] = {}
	return activity_level_stars[activity_id] as Dictionary


func _recalculate_total_stars() -> void:
	var total: int = 0
	for key: Variant in activity_stars.keys():
		var act_id: String = str(key)
		var act_total: int = get_activity_total_stars(act_id)
		activity_stars[act_id] = act_total
		total += act_total
	stars = total


# ---------------------------------------------------------------- Save / Load

func save_game() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("progress", "coins", coins)
	config.set_value("progress", "stars", stars)
	config.set_value("progress", "total_solved", total_solved)
	config.set_value("progress", "activity_stars", activity_stars)
	config.set_value("progress", "activity_level_stars", activity_level_stars)
	config.set_value("progress", "activity_tiers", activity_tiers)
	config.set_value("progress", "unlocked_stickers", unlocked_stickers)
	config.set_value("progress", "equipped_sticker", equipped_sticker)
	config.set_value("settings", "sfx_enabled", sfx_enabled)
	config.set_value("settings", "music_enabled", music_enabled)
	config.set_value("settings", "bgm_volume_percent", bgm_volume_percent)
	config.set_value("settings", "reduce_motion", reduce_motion)
	config.set_value("settings", "resolution_index", resolution_index)
	var err: Error = config.save(SAVE_PATH)
	if err != OK:
		push_error("GameState: Failed to save (error %d)" % err)


func load_game() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	coins = int(config.get_value("progress", "coins", 0))
	stars = int(config.get_value("progress", "stars", 0))
	total_solved = int(config.get_value("progress", "total_solved", 0))

	var loaded_stars: Variant = config.get_value("progress", "activity_stars", {})
	if loaded_stars is Dictionary:
		activity_stars.merge(loaded_stars as Dictionary, true)

	var loaded_tiers: Variant = config.get_value("progress", "activity_tiers", {})
	if loaded_tiers is Dictionary:
		activity_tiers.merge(loaded_tiers as Dictionary, true)
	elif config.has_section_key("progress", "shop_tier"):
		activity_tiers["little_shop"] = clampi(int(config.get_value("progress", "shop_tier", 1)), 1, MAX_ACTIVITY_TIER)

	activity_level_stars.clear()
	var loaded_level_stars: Variant = config.get_value("progress", "activity_level_stars", null)
	if loaded_level_stars is Dictionary:
		for act_key: Variant in (loaded_level_stars as Dictionary).keys():
			var act_id: String = str(act_key)
			var raw_levels: Variant = (loaded_level_stars as Dictionary)[act_key]
			if raw_levels is Dictionary:
				var normalized: Dictionary = {}
				for tier_key: Variant in (raw_levels as Dictionary).keys():
					var tier_num: int = clampi(int(tier_key), 1, MAX_ACTIVITY_TIER)
					var star_num: int = clampi(int((raw_levels as Dictionary)[tier_key]), 0, 3)
					normalized[tier_num] = maxi(int(normalized.get(tier_num, 0)), star_num)
				activity_level_stars[act_id] = normalized
	else:
		# Migrate pre-revamp saves cleanly by keeping prior stars on each activity's active tier.
		for act_key: Variant in activity_stars.keys():
			var act_id: String = str(act_key)
			var legacy_stars: int = clampi(int(activity_stars.get(act_id, 0)), 0, 3)
			if legacy_stars > 0:
				var tier_num: int = clampi(int(activity_tiers.get(act_id, 1)), 1, MAX_ACTIVITY_TIER)
				activity_level_stars[act_id] = {tier_num: legacy_stars}

	var loaded_stickers: Variant = config.get_value("progress", "unlocked_stickers", [])
	if loaded_stickers is Array:
		unlocked_stickers.clear()
		for s: Variant in loaded_stickers as Array:
			unlocked_stickers.append(str(s))

	equipped_sticker = str(config.get_value("progress", "equipped_sticker", ""))
	sfx_enabled = bool(config.get_value("settings", "sfx_enabled", true))
	music_enabled = bool(config.get_value("settings", "music_enabled", true))
	bgm_volume_percent = clampi(int(config.get_value("settings", "bgm_volume_percent", 100)), 0, 100)
	reduce_motion = bool(config.get_value("settings", "reduce_motion", false))
	resolution_index = clampi(int(config.get_value("settings", "resolution_index", 0)), 0, RESOLUTION_PRESETS.size() - 1)
	_recalculate_total_stars()
	for act_key: Variant in activity_tiers.keys():
		var act_id: String = str(act_key)
		activity_tiers[act_id] = clampi(int(activity_tiers[act_id]), 1, get_highest_unlocked_tier(act_id))
