# res://scenes/components/celebration_fx.gd
# Shared visual celebration helpers (sparkles, floating reward text, confetti).
class_name CelebrationFX
extends RefCounted

const SPARKLE_TEX: Texture2D = preload("res://assets/art/sparkle.svg")
const CONFETTI_COLORS: Array[Color] = [
	Color(1.0, 0.42, 0.42, 1.0),
	Color(1.0, 0.82, 0.40, 1.0),
	Color(0.42, 0.80, 0.47, 1.0),
	Color(0.13, 0.62, 0.74, 1.0),
	Color(0.61, 0.36, 0.90, 1.0),
]


static func spawn_sparkles(host: Control, center: Vector2) -> void:
	if host == null or GameState.reduce_motion:
		return
	var offsets: Array[Vector2] = [
		Vector2(-105, -40),
		Vector2(-40, -75),
		Vector2(45, -70),
		Vector2(105, -35),
	]
	for i: int in offsets.size():
		var spr: TextureRect = TextureRect.new()
		spr.texture = SPARKLE_TEX
		spr.custom_minimum_size = Vector2(36, 36)
		spr.size = Vector2(36, 36)
		spr.pivot_offset = Vector2(18, 18)
		spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spr.global_position = center - Vector2(18, 18)
		spr.scale = Vector2.ZERO
		host.add_child(spr)

		var target_pos: Vector2 = spr.global_position + offsets[i]
		var tween: Tween = host.create_tween().set_parallel(true)
		tween.tween_property(spr, "global_position", target_pos, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(spr, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(spr, "rotation", randf_range(-0.6, 0.6), 0.5)
		tween.tween_property(spr, "modulate:a", 0.0, 0.25).set_delay(0.3)
		tween.chain().tween_callback(spr.queue_free)


static func spawn_floating_text(host: Control, origin: Vector2, text_str: String, text_color: Color = Color(1.0, 0.86, 0.28, 1.0)) -> void:
	if host == null or GameState.reduce_motion:
		return
	var badge: Label = Label.new()
	badge.text = text_str
	badge.add_theme_font_size_override("font_size", 28)
	badge.add_theme_color_override("font_color", text_color)
	badge.add_theme_color_override("font_outline_color", Color(0.1843, 0.2824, 0.3451, 1.0))
	badge.add_theme_constant_override("outline_size", 6)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.global_position = origin - Vector2(68.0, 12.0)
	host.add_child(badge)

	var tween: Tween = host.create_tween().set_parallel(true)
	tween.tween_property(badge, "global_position:y", badge.global_position.y - 54.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tween.chain().tween_callback(badge.queue_free)


static func spawn_confetti_burst(host: Control, origin: Vector2, count: int = 20) -> void:
	if host == null or GameState.reduce_motion:
		return
	for i: int in count:
		var piece: ColorRect = ColorRect.new()
		var w: float = randf_range(8.0, 14.0)
		var h: float = randf_range(6.0, 12.0)
		piece.size = Vector2(w, h)
		piece.pivot_offset = Vector2(w, h) * 0.5
		piece.color = CONFETTI_COLORS[i % CONFETTI_COLORS.size()]
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		piece.global_position = origin - piece.pivot_offset
		host.add_child(piece)

		var angle: float = randf_range(-PI * 0.92, -PI * 0.08)
		var dist: float = randf_range(90.0, 240.0)
		var apex: Vector2 = piece.global_position + Vector2(cos(angle) * dist, sin(angle) * dist)
		var fall_y: float = apex.y + randf_range(120.0, 220.0)
		var dur: float = randf_range(0.75, 1.15)

		var tween: Tween = host.create_tween().set_parallel(true)
		tween.tween_property(piece, "global_position:x", apex.x + randf_range(-30.0, 30.0), dur).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "global_position:y", apex.y, dur * 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "global_position:y", fall_y, dur * 0.58).set_delay(dur * 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(piece, "rotation", randf_range(-5.0, 5.0), dur)
		tween.tween_property(piece, "modulate:a", 0.0, 0.3).set_delay(dur - 0.3)
		tween.chain().tween_callback(piece.queue_free)
