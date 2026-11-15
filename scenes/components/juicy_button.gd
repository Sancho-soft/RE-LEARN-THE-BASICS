# res://scenes/components/juicy_button.gd
# Node: any Button (attach this script instead of a plain Button)
# Reusable button with layered feedback: visual (scale bounce) + audio (sound).
# Mouse hover moves keyboard focus, so only one button is ever highlighted.
class_name JuicyButton
extends Button

@export var hover_scale: float = 1.05
@export var press_scale: float = 0.94
@export var press_sfx: StringName = &"click"
@export var hover_sfx: StringName = &"hover"

var _tween: Tween


func _ready() -> void:
	_update_pivot()
	resized.connect(_update_pivot)
	mouse_entered.connect(_on_mouse_entered)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	button_down.connect(_on_button_down)
	pressed.connect(_on_pressed)


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _on_mouse_entered() -> void:
	if not disabled and focus_mode != Control.FOCUS_NONE:
		grab_focus()


func _on_focus_entered() -> void:
	# Stay quiet while a scene is fading in (e.g. the default focus on load).
	if not GameState.is_transitioning():
		GameState.play_sfx(hover_sfx, -4.0)
	_animate_to(hover_scale, 0.12)


func _on_focus_exited() -> void:
	_animate_to(1.0, 0.12)


func _on_button_down() -> void:
	_animate_to(press_scale, 0.06)


func _on_pressed() -> void:
	GameState.play_sfx(press_sfx)
	_animate_to(hover_scale if has_focus() else 1.0, 0.18, Tween.TRANS_BACK)


func _animate_to(target: float, duration: float, trans: Tween.TransitionType = Tween.TRANS_SINE) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if GameState.reduce_motion:
		scale = Vector2.ONE
		return
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(target, target), duration).set_trans(trans).set_ease(Tween.EASE_OUT)
