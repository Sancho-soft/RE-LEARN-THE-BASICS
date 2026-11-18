# res://scenes/components/activity_pause_overlay.gd
# Cozy full-screen pause modal overlay for gameplay scenes; prevents accidental progress loss.
class_name ActivityPauseOverlay
extends CanvasLayer

signal resumed
signal restart_requested
signal activities_requested
signal menu_requested

const GAME_THEME: Theme = preload("res://assets/ui/game_theme.tres")
const JUICY_BUTTON_SCRIPT: Script = preload("res://scenes/components/juicy_button.gd")

var _root_ctrl: Control
var _card: PanelContainer
var _resume_btn: Button
var _restart_btn: Button
var _activities_btn: Button
var _menu_btn: Button


func _ready() -> void:
	layer = 50
	visible = false
	_build_ui()


func _build_ui() -> void:
	_root_ctrl = Control.new()
	_root_ctrl.theme = GAME_THEME
	_root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root_ctrl)

	var backdrop: ColorRect = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.11, 0.19, 0.25, 0.58)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_root_ctrl.add_child(backdrop)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_ctrl.add_child(center)

	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(440, 0)
	center.add_child(_card)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_child(vbox)

	var title: Label = Label.new()
	title.text = "GAME PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	var sub: Label = Label.new()
	sub.text = "Take a cozy breather or choose where to go:"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 19)
	sub.add_theme_color_override("font_color", Color(0.28, 0.39, 0.45, 1.0))
	vbox.add_child(sub)

	_resume_btn = _make_btn("Resume Playing", true)
	_resume_btn.pressed.connect(close_pause)
	vbox.add_child(_resume_btn)

	_restart_btn = _make_btn("Restart This Level")
	_restart_btn.pressed.connect(func() -> void:
		visible = false
		restart_requested.emit()
	)
	vbox.add_child(_restart_btn)

	_activities_btn = _make_btn("Back to Activities")
	_activities_btn.pressed.connect(func() -> void:
		visible = false
		activities_requested.emit()
	)
	vbox.add_child(_activities_btn)

	_menu_btn = _make_btn("Main Menu", false, &"back")
	_menu_btn.pressed.connect(func() -> void:
		visible = false
		menu_requested.emit()
	)
	vbox.add_child(_menu_btn)

	var buttons: Array[Button] = [_resume_btn, _restart_btn, _activities_btn, _menu_btn]
	for i: int in buttons.size():
		var prev_i: int = (i - 1 + buttons.size()) % buttons.size()
		var next_i: int = (i + 1) % buttons.size()
		buttons[i].focus_neighbor_top = buttons[i].get_path_to(buttons[prev_i])
		buttons[i].focus_neighbor_bottom = buttons[i].get_path_to(buttons[next_i])


func _make_btn(label_text: String, primary: bool = false, sfx: StringName = &"click") -> Button:
	var btn: Button = Button.new()
	btn.text = label_text
	btn.set_script(JUICY_BUTTON_SCRIPT)
	btn.press_sfx = sfx
	if primary:
		var normal: StyleBoxFlat = StyleBoxFlat.new()
		normal.content_margin_left = 20.0
		normal.content_margin_top = 12.0
		normal.content_margin_right = 20.0
		normal.content_margin_bottom = 14.0
		normal.bg_color = Color(0.419608, 0.796078, 0.466667, 1.0)
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
		hover.bg_color = Color(0.51, 0.86, 0.55, 1.0)
		var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
		pressed.content_margin_top = 15.0
		pressed.content_margin_bottom = 11.0
		pressed.border_width_top = 6
		pressed.border_width_bottom = 4
		pressed.bg_color = Color(0.35, 0.72, 0.40, 1.0)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("hover_pressed", pressed)
	return btn


func open_pause() -> void:
	if visible:
		return
	visible = true
	if not GameState.reduce_motion:
		_card.modulate.a = 0.0
		_card.pivot_offset = _card.size * 0.5
		_card.scale = Vector2(0.92, 0.92)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(_card, "modulate:a", 1.0, 0.16)
		tween.tween_property(_card, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close_pause() -> void:
	if not visible:
		return
	visible = false
	resumed.emit()
