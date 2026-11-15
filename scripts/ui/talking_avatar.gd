# res://scripts/ui/talking_avatar.gd
# Reusable character animation + typewriter talking controller for TextureRect portraits.
class_name TalkingAvatar
extends Node

const CHARS_PER_SEC: float = 48.0
const FLAP_INTERVAL: float = 0.09

var portrait: TextureRect
var speech_label: Label
var idle_texture: Texture2D
var talk_texture: Texture2D
var talk_volume_db: float = -9.0

var _is_talking: bool = false
var _char_progress: float = 0.0
var _target_chars: int = 0
var _flap_timer: float = 0.0
var _mouth_open: bool = false
var _chirp_counter: int = 0
var _idle_time: float = 0.0
var _react_tween: Tween


func setup(p_portrait: TextureRect, p_label: Label, p_idle: Texture2D, p_talk: Texture2D = null) -> void:
	portrait = p_portrait
	speech_label = p_label
	idle_texture = p_idle
	talk_texture = p_talk if p_talk != null else p_idle
	if portrait != null:
		portrait.pivot_offset = portrait.custom_minimum_size * 0.5
		if portrait.pivot_offset == Vector2.ZERO:
			portrait.pivot_offset = portrait.size * 0.5
		portrait.texture = idle_texture


func set_textures(p_idle: Texture2D, p_talk: Texture2D = null) -> void:
	idle_texture = p_idle
	talk_texture = p_talk if p_talk != null else p_idle
	if portrait != null and not _mouth_open:
		portrait.texture = idle_texture


func say(text: String) -> void:
	if speech_label == null:
		return
	speech_label.text = text
	if GameState.reduce_motion:
		speech_label.visible_characters = -1
		_stop_talking()
		return

	_target_chars = text.length()
	_char_progress = 0.0
	speech_label.visible_characters = 0
	_is_talking = true
	_flap_timer = 0.0
	_chirp_counter = 0
	_mouth_open = true
	if portrait != null:
		portrait.pivot_offset = portrait.size * 0.5
		portrait.texture = talk_texture


func finish_now() -> void:
	if speech_label != null:
		speech_label.visible_characters = -1
	_stop_talking()


func react_happy() -> void:
	if portrait == null or GameState.reduce_motion:
		return
	_stop_talking()
	portrait.pivot_offset = portrait.size * 0.5
	portrait.texture = talk_texture
	if _react_tween != null and _react_tween.is_valid():
		_react_tween.kill()
	_react_tween = create_tween()
	_react_tween.tween_property(portrait, "scale", Vector2(1.1, 0.92), 0.08)
	_react_tween.tween_property(portrait, "scale", Vector2(0.96, 1.12), 0.12).set_trans(Tween.TRANS_BACK)
	_react_tween.tween_property(portrait, "scale", Vector2(1.06, 0.95), 0.1)
	_react_tween.tween_property(portrait, "scale", Vector2.ONE, 0.14)
	_react_tween.tween_callback(func() -> void:
		if portrait != null and not _is_talking:
			portrait.texture = idle_texture
	)


func react_curious() -> void:
	if portrait == null or GameState.reduce_motion:
		return
	portrait.pivot_offset = portrait.size * 0.5
	if _react_tween != null and _react_tween.is_valid():
		_react_tween.kill()
	_react_tween = create_tween()
	_react_tween.tween_property(portrait, "rotation", -0.1, 0.12).set_ease(Tween.EASE_OUT)
	_react_tween.tween_property(portrait, "rotation", 0.04, 0.14)
	_react_tween.tween_property(portrait, "rotation", 0.0, 0.12)


func _process(delta: float) -> void:
	if portrait == null or GameState.reduce_motion:
		return

	if _is_talking:
		_char_progress += CHARS_PER_SEC * delta
		var shown: int = mini(_target_chars, int(_char_progress))
		speech_label.visible_characters = shown

		_flap_timer += delta
		if _flap_timer >= FLAP_INTERVAL:
			_flap_timer = 0.0
			_mouth_open = not _mouth_open
			portrait.texture = talk_texture if _mouth_open else idle_texture
			portrait.scale = Vector2(1.04, 0.95) if _mouth_open else Vector2(0.97, 1.04)
			portrait.rotation = 0.04 if _mouth_open else -0.04
			if _mouth_open:
				_chirp_counter += 1
				if _chirp_counter % 2 == 1:
					GameState.play_sfx(&"talk", talk_volume_db)

		if shown >= _target_chars:
			speech_label.visible_characters = -1
			_stop_talking()
	else:
		# Gentle breathing + cozy sway when idle (unless a reaction tween owns scale/rotation)
		if _react_tween == null or not _react_tween.is_running():
			_idle_time += delta
			var breath: float = sin(_idle_time * 2.4) * 0.025
			portrait.scale = Vector2(1.0 - breath * 0.6, 1.0 + breath)
			portrait.rotation = sin(_idle_time * 1.4) * 0.025


func _stop_talking() -> void:
	_is_talking = false
	_mouth_open = false
	if portrait != null:
		portrait.texture = idle_texture
		portrait.scale = Vector2.ONE
		portrait.rotation = 0.0
