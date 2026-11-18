# res://scenes/components/number_pad.gd
# Node: NumberPad (PanelContainer)
# Reusable number pad supporting mouse, touch, and physical keyboard digits.
class_name NumberPad
extends PanelContainer

signal answer_submitted(value: int)

const MAX_DIGITS: int = 3

@onready var _display_box: PanelContainer = %DisplayBox
@onready var _unit_coin_icon: TextureRect = %UnitCoinIcon
@onready var _display_label: Label = %DisplayLabel
@onready var _digits_grid: GridContainer = %DigitsGrid
@onready var _clear_btn: Button = %ClearButton
@onready var _zero_btn: Button = %ZeroButton
@onready var _back_btn: Button = %BackspaceButton
@onready var _submit_btn: Button = %SubmitButton

var _current_text: String = ""
var _locked: bool = false
var _unit_prefix: String = ""
var _unit_suffix: String = ""
var _show_coin_icon: bool = false


func _ready() -> void:
	_connect_buttons()
	_refresh_display()


func _connect_buttons() -> void:
	for child: Node in _digits_grid.get_children():
		var btn: Button = child as Button
		if btn == null:
			continue
		btn.focus_mode = Control.FOCUS_NONE
		if btn == _clear_btn:
			btn.pressed.connect(clear_input)
		elif btn == _back_btn:
			btn.pressed.connect(backspace)
		elif btn == _zero_btn:
			btn.pressed.connect(append_digit.bind("0"))
		else:
			btn.pressed.connect(append_digit.bind(btn.text))

	_submit_btn.pressed.connect(submit_current)


func append_digit(digit: String) -> void:
	if _locked:
		return
	if _current_text.length() >= MAX_DIGITS:
		return
	if _current_text == "0":
		_current_text = digit
	else:
		_current_text += digit
	_refresh_display()


func backspace() -> void:
	if _locked or _current_text.is_empty():
		return
	_current_text = _current_text.substr(0, _current_text.length() - 1)
	_refresh_display()


func clear_input(force: bool = false) -> void:
	if _locked and not force:
		return
	_current_text = ""
	_refresh_display()


func submit_current() -> void:
	if _locked or _current_text.is_empty():
		return
	answer_submitted.emit(int(_current_text))


func lock_and_clear() -> void:
	_current_text = ""
	set_locked(true)
	_refresh_display()


func set_locked(locked: bool) -> void:
	_locked = locked
	for child: Node in _digits_grid.get_children():
		var btn: Button = child as Button
		if btn != null:
			btn.disabled = locked
	_submit_btn.disabled = locked or _current_text.is_empty()


func set_unit_format(prefix: String, suffix: String = "", show_coin_icon: bool = false) -> void:
	_unit_prefix = prefix
	_unit_suffix = suffix
	_show_coin_icon = show_coin_icon
	if _unit_coin_icon != null:
		_unit_coin_icon.visible = _show_coin_icon
	_refresh_display()


func _refresh_display() -> void:
	var core: String = "__" if _current_text.is_empty() else _current_text
	var parts: PackedStringArray = []
	if not _unit_prefix.is_empty():
		parts.append(_unit_prefix)
	parts.append(core)
	if not _unit_suffix.is_empty():
		parts.append(_unit_suffix)
	_display_label.text = "  ".join(parts)

	if not _current_text.is_empty() and not GameState.reduce_motion:
		_display_label.pivot_offset = _display_label.size * 0.5
		_display_label.scale = Vector2(1.08, 1.08)
		var tween: Tween = create_tween()
		tween.tween_property(_display_label, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT)
	_submit_btn.disabled = _locked or _current_text.is_empty()


## Soft horizontal nudge used on a gentle retry (no harsh red shake).
func nudge_gentle() -> void:
	if GameState.reduce_motion:
		return
	var base_x: float = _display_box.position.x
	var tween: Tween = create_tween()
	tween.tween_property(_display_box, "position:x", base_x - 6.0, 0.05)
	tween.tween_property(_display_box, "position:x", base_x + 6.0, 0.08)
	tween.tween_property(_display_box, "position:x", base_x, 0.06)


func _unhandled_key_input(event: InputEvent) -> void:
	if _locked or not is_visible_in_tree():
		return
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	var code: Key = key_event.keycode
	if code >= KEY_0 and code <= KEY_9:
		GameState.play_sfx(&"click", -4.0)
		append_digit(str(code - KEY_0))
		get_viewport().set_input_as_handled()
	elif code >= KEY_KP_0 and code <= KEY_KP_9:
		GameState.play_sfx(&"click", -4.0)
		append_digit(str(code - KEY_KP_0))
		get_viewport().set_input_as_handled()
	elif code == KEY_BACKSPACE:
		GameState.play_sfx(&"back", -4.0)
		backspace()
		get_viewport().set_input_as_handled()
	elif code == KEY_DELETE or code == KEY_C:
		GameState.play_sfx(&"back", -4.0)
		clear_input()
		get_viewport().set_input_as_handled()
	elif code == KEY_ENTER or code == KEY_KP_ENTER:
		if not _current_text.is_empty():
			GameState.play_sfx(&"click")
			submit_current()
			get_viewport().set_input_as_handled()
