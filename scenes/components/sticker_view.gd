# res://scenes/components/sticker_view.gd
# Reusable sticker display component supporting static and 6 distinct animated deluxe styles.
class_name StickerView
extends Control

const SPARKLE_TEX: Texture2D = preload("res://assets/art/sparkle.svg")
const COIN_TEX: Texture2D = preload("res://assets/ui/coin.svg")

const SHIMMER_SHADER_CODE: String = """
shader_type canvas_item;
uniform int mode = 0; // 0=gold, 1=rainbow, 2=cosmic, 3=flame
uniform float speed = 1.9;
uniform float strength = 0.42;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float sweep = sin((UV.x * 4.5 + UV.y * 3.0) - TIME * speed);
	float band = smoothstep(0.45, 1.0, sweep);
	vec3 tint = vec3(1.0, 0.94, 0.58);
	if (mode == 1) {
		float h = fract(UV.x * 0.75 + UV.y * 0.45 - TIME * 0.35);
		tint = clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
		band = max(band, 0.32);
	} else if (mode == 2) {
		float ring = sin((UV.x - 0.5) * 8.0 + TIME * 2.2) * cos((UV.y - 0.5) * 8.0 - TIME * 1.8);
		band = max(band, smoothstep(0.2, 0.95, ring) * 0.75);
		tint = mix(vec3(0.42, 0.92, 1.0), vec3(0.76, 0.55, 1.0), 0.5 + 0.5 * sin(TIME * 2.0));
	} else if (mode == 3) {
		float rise = fract(UV.y + TIME * 0.55);
		band = max(band, smoothstep(0.35, 1.0, sin(rise * 6.2831)) * 0.8);
		tint = mix(vec3(1.0, 0.45, 0.25), vec3(1.0, 0.92, 0.38), 1.0 - UV.y);
	}
	vec3 lit = mix(tex.rgb, tex.rgb + tint * 0.65, band * strength);
	COLOR = vec4(lit, tex.a) * COLOR;
}
"""

static var _shared_shader: Shader

var _aura: Panel
var _icon: TextureRect
var _particles: Array[TextureRect] = []
var _is_animated: bool = false
var _anim_active: bool = true
var _anim_style: String = "float"
var _is_locked: bool = false
var _time: float = 0.0
var _shader_mat: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	GameState.settings_changed.connect(_sync_motion_state)


func setup_sticker(sticker_id: String, icon_size: Vector2 = Vector2(68, 68), locked_dim: bool = false, animate_active: bool = true) -> void:
	var item: Dictionary = GameState.get_sticker_info(sticker_id)
	if item.is_empty():
		visible = false
		set_process(false)
		return
	visible = true
	clip_contents = false
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
		_icon.modulate = Color(0.78, 0.80, 0.86, 0.82)
	else:
		_icon.modulate = Color.WHITE

	_configure_particles_for_style()
	_time = randf() * 3.0
	_sync_motion_state()


func set_anim_active(active: bool) -> void:
	_anim_active = active
	_sync_motion_state()


func _ensure_nodes(icon_size: Vector2) -> void:
	if _aura == null:
		_aura = Panel.new()
		_aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_aura.visible = false
		add_child(_aura)

	var aura_size: Vector2 = icon_size * 1.18
	_aura.size = aura_size
	_aura.position = (icon_size - aura_size) * 0.5
	_aura.pivot_offset = aura_size * 0.5
	var aura_style: StyleBoxFlat = StyleBoxFlat.new()
	aura_style.bg_color = _get_aura_color()
	aura_style.corner_radius_top_left = 999
	aura_style.corner_radius_top_right = 999
	aura_style.corner_radius_bottom_right = 999
	aura_style.corner_radius_bottom_left = 999
	_aura.add_theme_stylebox_override("panel", aura_style)

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

	if _particles.is_empty():
		var count: int = 4
		for _i: int in count:
			var sp: TextureRect = TextureRect.new()
			sp.texture = SPARKLE_TEX
			var sp_size: float = maxf(13.0, icon_size.x * 0.28)
			sp.custom_minimum_size = Vector2(sp_size, sp_size)
			sp.size = Vector2(sp_size, sp_size)
			sp.pivot_offset = Vector2(sp_size, sp_size) * 0.5
			sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sp.visible = false
			add_child(sp)
			_particles.append(sp)
	else:
		var sp_size: float = maxf(13.0, icon_size.x * 0.28)
		for sp: TextureRect in _particles:
			sp.custom_minimum_size = Vector2(sp_size, sp_size)
			sp.size = Vector2(sp_size, sp_size)
			sp.pivot_offset = Vector2(sp_size, sp_size) * 0.5


func _get_aura_color() -> Color:
	match _anim_style:
		"comet":
			return Color(1.0, 0.78, 0.30, 0.24)
		"rainbow":
			return Color(0.68, 0.45, 0.98, 0.24)
		"orbit":
			return Color(0.30, 0.76, 0.96, 0.24)
		"flutter":
			return Color(1.0, 0.56, 0.72, 0.24)
		"flame":
			return Color(1.0, 0.50, 0.22, 0.28)
		_:
			return Color(0.32, 0.85, 0.72, 0.22)


func _configure_particles_for_style() -> void:
	var tints: Array[Color] = [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]
	match _anim_style:
		"comet":
			tints = [Color(1.0, 0.86, 0.35), Color(1.0, 0.52, 0.48), Color(0.55, 0.84, 0.98), Color(1.0, 0.94, 0.65)]
		"rainbow":
			tints = [Color(1.0, 0.42, 0.48), Color(1.0, 0.84, 0.30), Color(0.42, 0.86, 0.55), Color(0.58, 0.46, 0.98)]
		"orbit":
			tints = [Color(0.45, 0.92, 1.0), Color(1.0, 0.84, 0.36), Color(0.75, 0.58, 1.0), Color(0.55, 0.96, 0.82)]
		"flutter":
			tints = [Color(1.0, 0.58, 0.74), Color(0.52, 0.95, 0.88), Color(1.0, 0.88, 0.48), Color(0.84, 0.64, 1.0)]
		"flame":
			tints = [Color(1.0, 0.45, 0.20), Color(1.0, 0.78, 0.22), Color(1.0, 0.35, 0.35), Color(1.0, 0.94, 0.55)]
		_:
			tints = [Color(0.45, 0.92, 0.82), Color(1.0, 0.84, 0.35), Color(0.45, 0.85, 0.98), Color(1.0, 0.65, 0.32)]

	for i: int in _particles.size():
		var sp: TextureRect = _particles[i]
		sp.texture = COIN_TEX if (_anim_style == "orbit" and i < 2) else SPARKLE_TEX
		sp.self_modulate = tints[i % tints.size()]


func _apply_shimmer_material() -> void:
	if _shared_shader == null:
		_shared_shader = Shader.new()
		_shared_shader.code = SHIMMER_SHADER_CODE
	if _shader_mat == null:
		_shader_mat = ShaderMaterial.new()
		_shader_mat.shader = _shared_shader

	var shader_mode: int = 0
	var shader_speed: float = 1.9
	match _anim_style:
		"rainbow":
			shader_mode = 1
			shader_speed = 2.2
		"orbit":
			shader_mode = 2
			shader_speed = 2.0
		"flame":
			shader_mode = 3
			shader_speed = 2.4
		_:
			shader_mode = 0
			shader_speed = 1.8

	_shader_mat.set_shader_parameter("mode", shader_mode)
	_shader_mat.set_shader_parameter("strength", 0.26 if _is_locked else 0.45)
	_shader_mat.set_shader_parameter("speed", shader_speed)
	_icon.material = _shader_mat


func _sync_motion_state() -> void:
	var show_anim: bool = _is_animated and _anim_active
	if _aura != null:
		_aura.visible = show_anim and not _is_locked
	if _icon != null:
		if show_anim:
			_apply_shimmer_material()
		else:
			_icon.material = null
	for sp: TextureRect in _particles:
		sp.visible = show_anim

	var should_run: bool = show_anim and not GameState.reduce_motion
	set_process(should_run)
	if not should_run and _icon != null:
		_icon.position = Vector2.ZERO
		_icon.rotation = 0.0
		_icon.scale = Vector2.ONE
		if _aura != null:
			_aura.scale = Vector2.ONE
		for sp: TextureRect in _particles:
			sp.scale = Vector2(0.7, 0.7)
			sp.modulate.a = 0.65


func _process(delta: float) -> void:
	if _icon == null:
		return
	_time += delta
	_icon.pivot_offset = _icon.size * 0.5
	var amp: float = 0.75 if _is_locked else 1.0
	var w: float = _icon.size.x
	var h: float = _icon.size.y
	var center: Vector2 = Vector2(w, h) * 0.5

	if _aura != null and _aura.visible:
		var pulse: float = 0.96 + 0.10 * sin(_time * 3.4)
		_aura.scale = Vector2(pulse, pulse)

	match _anim_style:
		"comet":
			# Swooping diagonal dash-bob + snappy tilt
			_icon.position = Vector2(sin(_time * 3.2) * 4.5, -absf(sin(_time * 3.2)) * 4.0) * amp
			_icon.rotation = -0.10 + sin(_time * 3.2) * 0.16 * amp
			var sc: float = 1.0 + sin(_time * 4.5) * 0.07 * amp
			_icon.scale = Vector2(sc, sc)
			_animate_comet_trail(center, w)
		"rainbow":
			# Cheerful bouncy hop + playful head-bob + circular rainbow star orbit
			var hop: float = absf(sin(_time * 3.4))
			_icon.position = Vector2(sin(_time * 1.7) * 2.5, -hop * 6.0) * amp
			_icon.rotation = sin(_time * 3.4) * 0.14 * amp
			_icon.scale = Vector2(1.0 + (1.0 - hop) * 0.07 * amp, 1.0 - (1.0 - hop) * 0.06 * amp)
			_animate_orbit_ring(center, w * 0.52, h * 0.50, 1.9, 0.0)
		"orbit":
			# Steady Saturn tilt + front/back tilted planetary moons
			_icon.position = Vector2(0.0, sin(_time * 2.2) * 3.2 * amp)
			_icon.rotation = sin(_time * 1.4) * 0.09 * amp
			_icon.scale = Vector2.ONE * (1.0 + sin(_time * 2.4) * 0.04 * amp)
			_animate_planet_moons(center, w)
		"flutter":
			# Real wing-flap horizontal squeeze + figure-8 butterfly flight
			_icon.position = Vector2(sin(_time * 2.4) * 5.0, sin(_time * 4.8) * 3.4) * amp
			_icon.rotation = sin(_time * 2.4) * 0.16 * amp
			var flap: float = 0.78 + 0.26 * absf(cos(_time * 7.5))
			_icon.scale = Vector2(flap, 1.02 + (1.0 - flap) * 0.25)
			_animate_rising_sparks(center, w, 1.45)
		"flame":
			# Heroic phoenix soar + radiant shimmer scale + upward fire embers
			_icon.position = Vector2(cos(_time * 2.1) * 2.4, -2.0 + sin(_time * 3.6) * 4.8) * amp
			_icon.rotation = sin(_time * 2.1) * 0.10 * amp
			var blaze: float = 1.02 + sin(_time * 5.2) * 0.08 * amp
			_icon.scale = Vector2(blaze, blaze)
			_animate_rising_sparks(center, w, 2.2)
		_:
			# "float" (Galaxy Dragon): graceful figure-8 hover + rising embers
			_icon.position = Vector2(sin(_time * 2.0) * 4.2, cos(_time * 3.0) * 3.6) * amp
			_icon.rotation = sin(_time * 2.0) * 0.11 * amp
			var breath: float = 1.0 + sin(_time * 3.2) * 0.065 * amp
			_icon.scale = Vector2(breath, 2.0 - breath)
			_animate_rising_sparks(center, w, 1.65)


func _animate_orbit_ring(center: Vector2, rx: float, ry: float, speed: float, tilt: float) -> void:
	for i: int in _particles.size():
		var sp: TextureRect = _particles[i]
		var angle: float = _time * speed + float(i) * (TAU / float(_particles.size()))
		var local_p: Vector2 = Vector2(cos(angle) * rx, sin(angle) * ry).rotated(tilt)
		sp.position = center + local_p - sp.size * 0.5
		var tw: float = 0.55 + 0.45 * absf(sin(_time * 4.0 + float(i) * 1.2))
		sp.scale = Vector2(tw, tw)
		sp.modulate.a = 0.45 + 0.55 * tw
		sp.rotation = _time * 2.4 + float(i)
		sp.z_index = 1


func _animate_comet_trail(center: Vector2, width_px: float) -> void:
	for i: int in _particles.size():
		var sp: TextureRect = _particles[i]
		var phase: float = fmod(_time * 1.6 + float(i) * 0.25, 1.0)
		var trail_pos: Vector2 = center + Vector2(0.15 * width_px, -0.15 * width_px) + Vector2(-0.62 * width_px, 0.52 * width_px) * phase
		trail_pos.y += sin(phase * PI * 2.0 + float(i)) * 4.0
		sp.position = trail_pos - sp.size * 0.5
		var s: float = (1.0 - phase) * 0.95 + 0.2
		sp.scale = Vector2(s, s)
		sp.modulate.a = (1.0 - phase)
		sp.rotation = _time * 3.2 + float(i)
		sp.z_index = 1


func _animate_rising_sparks(center: Vector2, width_px: float, rise_speed: float) -> void:
	var x_offsets: Array[float] = [-0.36, -0.14, 0.16, 0.36]
	for i: int in _particles.size():
		var sp: TextureRect = _particles[i]
		var phase: float = fmod(_time * rise_speed * 0.65 + float(i) * 0.27, 1.0)
		var x_drift: float = x_offsets[i % x_offsets.size()] * width_px + sin(_time * 4.0 + float(i)) * 4.0
		var y_drift: float = (0.34 - phase * 0.92) * width_px
		sp.position = center + Vector2(x_drift, y_drift) - sp.size * 0.5
		var s: float = sin(phase * PI) * 0.95 + 0.2
		sp.scale = Vector2(s, s)
		sp.modulate.a = sin(phase * PI)
		sp.rotation = _time * 2.0 + float(i)
		sp.z_index = 1


func _animate_planet_moons(center: Vector2, width_px: float) -> void:
	for i: int in _particles.size():
		var sp: TextureRect = _particles[i]
		if i < 2:
			var angle: float = _time * (1.8 if i == 0 else -1.3) + float(i) * PI
			var local_p: Vector2 = Vector2(cos(angle) * width_px * 0.54, sin(angle) * width_px * 0.20).rotated(-0.34)
			sp.position = center + local_p - sp.size * 0.5
			var depth_scale: float = 0.52 + 0.26 * (sin(angle) * 0.5 + 0.5)
			sp.scale = Vector2(depth_scale, depth_scale)
			sp.modulate.a = 0.55 + 0.45 * (sin(angle) * 0.5 + 0.5)
			sp.z_index = 1 if sin(angle) > 0.0 else -1
			sp.rotation = _time * 1.2
		else:
			var angle2: float = _time * 1.1 + float(i) * 2.2
			sp.position = center + Vector2(cos(angle2), sin(angle2)) * width_px * 0.45 - sp.size * 0.5
			var tw: float = 0.45 + 0.5 * absf(sin(_time * 3.5 + float(i)))
			sp.scale = Vector2(tw, tw)
			sp.modulate.a = tw
			sp.z_index = 1
