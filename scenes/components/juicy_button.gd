# res://scenes/components/juicy_button.gd
# Node: any Button (attach this script instead of a plain Button)
# Reusable button with layered feedback: visual (scale bounce) + audio (sound).
# Separates mouse hover from keyboard focus so buttons never stay stuck highlighted.
class_name JuicyButton
extends Button

@export var hover_scale: float = 1.05
@export var press_scale: float = 0.94
@export var press_sfx: StringName = &"click"
@export var hover_sfx: StringName = &"hover"

var _tween: Tween
var _is_hovered: bool = false


func _ready() -> void:
	_update_pivot()
	resized.connect(_update_pivot)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	button_down.connect(_on_button_down)
	pressed.connect(_on_pressed)


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and has_focus() and not _is_hovered:
		release_focus()


func _on_mouse_entered() -> void:
	if disabled:
		return
	_is_hovered = true
	var prev_focus: Control = get_viewport().gui_get_focus_owner()
	if prev_focus != null and prev_focus != self:
		prev_focus.release_focus()
	if not GameState.is_transitioning():
		GameState.play_sfx(hover_sfx, -4.0)
	_animate_to(hover_scale, 0.12)


func _on_mouse_exited() -> void:
	_is_hovered = false
	if has_focus():
		release_focus()
	_animate_to(1.0, 0.12)


func _on_focus_entered() -> void:
	if not _is_hovered and not GameState.is_transitioning():
		GameState.play_sfx(hover_sfx, -4.0)
	_animate_to(hover_scale, 0.12)


func _on_focus_exited() -> void:
	if not _is_hovered:
		_animate_to(1.0, 0.12)


func _on_button_down() -> void:
	_animate_to(press_scale, 0.06)


func _on_pressed() -> void:
	GameState.play_sfx(press_sfx)
	var target: float = hover_scale if ((_is_hovered or has_focus()) and not disabled) else 1.0
	_animate_to(target, 0.18, Tween.TRANS_BACK)


func _animate_to(target: float, duration: float, trans: Tween.TransitionType = Tween.TRANS_SINE) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if GameState.reduce_motion:
		scale = Vector2.ONE
		return
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(target, target), duration).set_trans(trans).set_ease(Tween.EASE_OUT)
