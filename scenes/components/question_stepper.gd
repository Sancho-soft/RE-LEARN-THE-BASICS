# res://scenes/components/question_stepper.gd
# Visual 8-step question progress bar for elementary math activities.
class_name QuestionStepper
extends HBoxContainer

const COLOR_DONE: Color = Color(0.419608, 0.796078, 0.466667, 1.0)
const COLOR_CURRENT: Color = Color(1.0, 0.86, 0.42, 1.0)
const COLOR_PENDING: Color = Color(0.84, 0.89, 0.92, 1.0)
const COLOR_BORDER: Color = Color(0.184314, 0.282353, 0.345098, 1.0)

var _pips: Array[Panel] = []
var _total_steps: int = 8


func setup_steps(total: int) -> void:
	_total_steps = maxi(total, 1)
	for child: Node in get_children():
		child.queue_free()
	_pips.clear()

	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 6)

	for i: int in _total_steps:
		var pip: Panel = Panel.new()
		pip.custom_minimum_size = Vector2(20, 14)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.pivot_offset = Vector2(10, 7)
		add_child(pip)
		_pips.append(pip)

	update_progress(1, 0)


func update_progress(current_question: int, completed_count: int) -> void:
	for i: int in _pips.size():
		var pip: Panel = _pips[i]
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 3
		style.border_color = COLOR_BORDER
		style.corner_radius_top_left = 7
		style.corner_radius_top_right = 7
		style.corner_radius_bottom_right = 7
		style.corner_radius_bottom_left = 7

		if i < completed_count:
			style.bg_color = COLOR_DONE
			pip.custom_minimum_size = Vector2(20, 14)
			pip.scale = Vector2.ONE
		elif i == current_question - 1:
			style.bg_color = COLOR_CURRENT
			pip.custom_minimum_size = Vector2(26, 16)
			if not GameState.reduce_motion:
				pip.pivot_offset = Vector2(13, 8)
				pip.scale = Vector2(1.12, 1.12)
				var tween: Tween = create_tween()
				tween.tween_property(pip, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			style.bg_color = COLOR_PENDING
			pip.custom_minimum_size = Vector2(18, 14)
			pip.scale = Vector2.ONE

		pip.add_theme_stylebox_override("panel", style)
