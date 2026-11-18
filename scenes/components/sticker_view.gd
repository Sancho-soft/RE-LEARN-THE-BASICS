# res://scenes/components/sticker_view.gd
# Reusable sticker display component supporting both static and animated premium stickers.
class_name StickerView
extends Control

const SPARKLE_TEX: Texture2D = preload("res://assets/art/sparkle.svg")

const SHIMMER_SHADER_CODE: String = """
shader_type canvas_item;
uniform float speed = 1.6;
uniform float strength = 0.28;
uniform bool rainbow_mode = false;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float sweep = sin((UV.x * 4.5 + UV.y * 3.0) - TIME * speed);
	float band = smoothstep(0.65, 1.0, sweep);
	vec3 tint = vec3(1.0, 0.96, 0.75);
	if (rainbow_mode) {
		float h = fract(UV.x * 0.7 + UV.y * 0.4 - TIME * 0.25);
		tint = clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	}
	vec3 lit = mix(tex.rgb, tex.rgb + tint * 0.55, band * strength);
	COLOR = vec4(lit, tex.a) * COLOR;
}
"""

static var _shared_shader: Shader

var _icon: TextureRect
var _sparkles: Array[TextureRect] = []
var _is_animated: bool = false
var _anim_active: bool = true
var _anim_style: String = "float"
var _is_locked: bool = false
var _time: float = 0.0
var _shader_mat: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.settings_changed.connect(_sync_motion_state)


func setup_sticker(sticker_id: String, icon_size: Vector2 = Vector2(68, 68), locked_dim: bool = false, animate_active: bool = true) -> void:
	var item: Dictionary = GameState.get_sticker_info(sticker_id)
	if item.is_empty():
		visible = false
		set_process(false)
		return
	visible = true
	_is_locked = locked_dim
	_is_animated = bool(item.get("animated", false))
	_anim_active = animate_active
	_anim_style = str(item.get("anim_style", "float"))

	custom_minimum_size = icon_size
	size = icon_size
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

	_ensure_nodes(icon_size)
	_icon.texture = GameState.load_texture_safe(str(item.get("icon", "")))

	if _is_locked:
		_icon.modulate = Color(0.75, 0.78, 0.84, 0.75)
	else:
		_icon.modulate = Color.WHITE

	_time = randf() * 3.0
	_sync_motion_state()


func set_anim_active(active: bool) -> void:
	_anim_active = active
	_sync_motion_state()


func _ensure_nodes(icon_size: Vector2) -> void:
	if _icon == null:
		_icon = TextureRect.new()
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_icon)

	_icon.position = Vector2.ZERO
	_icon.size = icon_size
	_icon.custom_minimum_size = icon_size
	_icon.pivot_offset = icon_size * 0.5

	if _sparkles.is_empty():
		var count: int = 3
		for i: int in count:
			var sp: TextureRect = TextureRect.new()
			sp.texture = SPARKLE_TEX
			var sp_size: float = maxf(12.0, icon_size.x * 0.26)
			sp.custom_minimum_size = Vector2(sp_size, sp_size)
			sp.size = Vector2(sp_size, sp_size)
			sp.pivot_offset = Vector2(sp_size, sp_size) * 0.5
			sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sp.visible = false
			add_child(sp)
			_sparkles.append(sp)
	else:
		var sp_size: float = maxf(12.0, icon_size.x * 0.26)
		for sp: TextureRect in _sparkles:
			sp.custom_minimum_size = Vector2(sp_size, sp_size)
			sp.size = Vector2(sp_size, sp_size)
			sp.pivot_offset = Vector2(sp_size, sp_size) * 0.5


func _apply_shimmer_material(rainbow_mode: bool) -> void:
	if _shared_shader == null:
		_shared_shader = Shader.new()
		_shared_shader.code = SHIMMER_SHADER_CODE
	if _shader_mat == null:
		_shader_mat = ShaderMaterial.new()
		_shader_mat.shader = _shared_shader
	_shader_mat.set_shader_parameter("rainbow_mode", rainbow_mode)
	_shader_mat.set_shader_parameter("strength", 0.22 if _is_locked else 0.34)
	_shader_mat.set_shader_parameter("speed", 1.8 if rainbow_mode else 1.5)
	_icon.material = _shader_mat


func _sync_motion_state() -> void:
	var show_anim: bool = _is_animated and _anim_active
	if _icon != null:
		if show_anim:
			_apply_shimmer_material(_anim_style == "rainbow")
		else:
			_icon.material = null
	for sp: TextureRect in _sparkles:
		sp.visible = show_anim and not _is_locked

	var should_run: bool = show_anim and not GameState.reduce_motion
	set_process(should_run)
	if not should_run and _icon != null:
		_icon.position = Vector2.ZERO
		_icon.rotation = 0.0
		_icon.scale = Vector2.ONE
		for sp: TextureRect in _sparkles:
			sp.scale = Vector2(0.75, 0.75)
			sp.modulate.a = 0.7


func _process(delta: float) -> void:
	if _icon == null:
		return
	_time += delta
	_icon.pivot_offset = _icon.size * 0.5
	var amp: float = 0.6 if _is_locked else 1.0

	match _anim_style:
		"comet":
			_icon.position = Vector2(sin(_time * 2.6) * 2.5, cos(_time * 3.1) * 2.8) * amp
			_icon.rotation = sin(_time * 2.2) * 0.09 * amp
			var s_comet: float = 1.0 + sin(_time * 3.8) * 0.055 * amp
			_icon.scale = Vector2(s_comet, s_comet)
		"rainbow":
			_icon.position = Vector2(0.0, sin(_time * 3.2) * 3.2 * amp)
			_icon.rotation = sin(_time * 2.0) * 0.07 * amp
			var squash: float = sin(_time * 3.2) * 0.05 * amp
			_icon.scale = Vector2(1.0 - squash * 0.6, 1.0 + squash)
		_:
			_icon.position = Vector2(0.0, sin(_time * 2.5) * 3.0 * amp)
			_icon.rotation = sin(_time * 1.7) * 0.08 * amp
			var s_float: float = 1.0 + sin(_time * 2.9) * 0.045 * amp
			_icon.scale = Vector2(s_float, s_float)

	if not _is_locked:
		var radius_x: float = _icon.size.x * 0.44
		var radius_y: float = _icon.size.y * 0.44
		var center: Vector2 = _icon.size * 0.5
		for i: int in _sparkles.size():
			var sp: TextureRect = _sparkles[i]
			var angle: float = _time * 1.35 + float(i) * (TAU / float(_sparkles.size()))
			var orbit_pos: Vector2 = center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
			sp.position = orbit_pos - sp.size * 0.5
			var twinkle: float = 0.45 + 0.55 * absf(sin(_time * 3.6 + float(i) * 1.4))
			sp.scale = Vector2(twinkle, twinkle)
			sp.modulate.a = 0.35 + 0.65 * twinkle
			sp.rotation = _time * 1.8 + float(i)
