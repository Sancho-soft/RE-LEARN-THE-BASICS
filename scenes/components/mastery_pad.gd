# res://scenes/components/mastery_pad.gd
# Non-calculator interactive answer pad for Level 9 (Token Tray Composer)
# and Level 10 (Base-10 Bead Lock Abacus), designed for elementary mastery.
class_name MasteryPad
extends PanelContainer

signal answer_submitted(value: int)

const GAME_THEME: Theme = preload("res://assets/ui/game_theme.tres")
const JUICY_BUTTON_SCRIPT: Script = preload("res://scenes/components/juicy_button.gd")
const COIN_ICON: Texture2D = preload("res://assets/ui/coin.svg")

const TOKEN_VALUES: Array[int] = [200, 100, 50, 20, 10, 5, 2, 1]
const TOKEN_COLORS: Dictionary = {
	200: Color(0.72, 0.56, 0.98, 1.0),
	100: Color(0.55, 0.85, 0.98, 1.0),
	50: Color(0.46, 0.86, 0.56, 1.0),
	20: Color(1.0, 0.86, 0.42, 1.0),
	10: Color(1.0, 0.68, 0.42, 1.0),
	5: Color(1.0, 0.54, 0.60, 1.0),
	2: Color(0.84, 0.94, 0.72, 1.0),
	1: Color(1.0, 0.96, 0.84, 1.0),
}
const MAX_TOTAL: int = 999

var _mode: int = 9 # 9 = Token Tray, 10 = Base-10 Bead Abacus
var _locked: bool = false
var _unit_prefix: String = ""
var _unit_suffix: String = ""
var _show_coin_icon: bool = false

# Shared display + controls
var _mode_badge: Label
var _display_box: PanelContainer
var _unit_coin_icon: TextureRect
var _display_label: Label
var _sub_readout_label: Label
var _token_container: VBoxContainer
var _abacus_container: VBoxContainer
var _submit_btn: Button
var _interactive_buttons: Array[Button] = []

# Level 9 Token Tray state
var _token_stack: Array[int] = []
var _token_total: int = 0

# Level 10 Abacus state [hundreds, tens, ones]
var _abacus_digits: Array[int] = [0, 0, 0]
var _abacus_beads: Array[Array] = [[], [], []]
var _abacus_num_labels: Array[Label] = []


func _ready() -> void:
	theme = GAME_THEME
	custom_minimum_size = Vector2(336, 0)
	_build_ui()
	_apply_mode_visibility()
	_refresh_display()


func set_mode(tier: int) -> void:
	_mode = 10 if tier >= 10 else 9
	if is_node_ready():
		_apply_mode_visibility()
	clear_input(true)


func set_unit_format(prefix: String, suffix: String = "", show_coin_icon: bool = false) -> void:
	_unit_prefix = prefix
	_unit_suffix = suffix
	_show_coin_icon = show_coin_icon
	if _unit_coin_icon != null:
		_unit_coin_icon.visible = _show_coin_icon
	_refresh_display()


func clear_input(force: bool = false) -> void:
	if _locked and not force:
		return
	_token_stack.clear()
	_token_total = 0
	_abacus_digits = [0, 0, 0]
	_refresh_display()


func lock_and_clear() -> void:
	_token_stack.clear()
	_token_total = 0
	_abacus_digits = [0, 0, 0]
	set_locked(true)
	_refresh_display()


func set_locked(locked: bool) -> void:
	_locked = locked
	for btn: Button in _interactive_buttons:
		if is_instance_valid(btn):
			btn.disabled = locked
	if _submit_btn != null:
		_submit_btn.disabled = locked or _get_current_value() <= 0


func nudge_gentle() -> void:
	if GameState.reduce_motion or _display_box == null:
		return
	var base_x: float = _display_box.position.x
	var tween: Tween = create_tween()
	tween.tween_property(_display_box, "position:x", base_x - 6.0, 0.05)
	tween.tween_property(_display_box, "position:x", base_x + 6.0, 0.08)
	tween.tween_property(_display_box, "position:x", base_x, 0.06)


func _get_current_value() -> int:
	if _mode == 9:
		return _token_total
	return _abacus_digits[0] * 100 + _abacus_digits[1] * 10 + _abacus_digits[2]


func _submit_current() -> void:
	var val: int = _get_current_value()
	if _locked or val <= 0:
		return
	answer_submitted.emit(val)


func _build_ui() -> void:
	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	_mode_badge = Label.new()
	_mode_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_badge.add_theme_font_size_override("font_size", 15)
	_mode_badge.add_theme_color_override("font_color", Color(0.45, 0.25, 0.78, 1.0))
	main_vbox.add_child(_mode_badge)

	_display_box = PanelContainer.new()
	var disp_style: StyleBoxFlat = StyleBoxFlat.new()
	disp_style.content_margin_left = 14.0
	disp_style.content_margin_top = 10.0
	disp_style.content_margin_right = 14.0
	disp_style.content_margin_bottom = 10.0
	disp_style.bg_color = Color(0.745098, 0.898039, 0.960784, 1.0)
	disp_style.border_width_left = 4
	disp_style.border_width_top = 4
	disp_style.border_width_right = 4
	disp_style.border_width_bottom = 6
	disp_style.border_color = Color(0.184314, 0.282353, 0.345098, 1.0)
	disp_style.corner_radius_top_left = 16
	disp_style.corner_radius_top_right = 16
	disp_style.corner_radius_bottom_right = 16
	disp_style.corner_radius_bottom_left = 16
	_display_box.add_theme_stylebox_override("panel", disp_style)
	main_vbox.add_child(_display_box)

	var disp_vbox: VBoxContainer = VBoxContainer.new()
	disp_vbox.add_theme_constant_override("separation", 2)
	_display_box.add_child(disp_vbox)

	var disp_row: HBoxContainer = HBoxContainer.new()
	disp_row.alignment = BoxContainer.ALIGNMENT_CENTER
	disp_row.add_theme_constant_override("separation", 8)
	disp_vbox.add_child(disp_row)

	_unit_coin_icon = TextureRect.new()
	_unit_coin_icon.custom_minimum_size = Vector2(28, 28)
	_unit_coin_icon.texture = COIN_ICON
	_unit_coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_unit_coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_unit_coin_icon.visible = _show_coin_icon
	disp_row.add_child(_unit_coin_icon)

	_display_label = Label.new()
	_display_label.add_theme_font_size_override("font_size", 34)
	_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disp_row.add_child(_display_label)

	_sub_readout_label = Label.new()
	_sub_readout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_readout_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub_readout_label.add_theme_font_size_override("font_size", 14)
	_sub_readout_label.add_theme_color_override("font_color", Color(0.18, 0.32, 0.42, 0.88))
	disp_vbox.add_child(_sub_readout_label)

	_build_token_tray_ui(main_vbox)
	_build_abacus_ui(main_vbox)

	_submit_btn = Button.new()
	_submit_btn.text = "CHECK!"
	_submit_btn.focus_mode = Control.FOCUS_NONE
	_submit_btn.set_script(JUICY_BUTTON_SCRIPT)
	_submit_btn.add_theme_font_size_override("font_size", 24)
	_apply_submit_styles(_submit_btn)
	_submit_btn.pressed.connect(_submit_current)
	main_vbox.add_child(_submit_btn)


func _build_token_tray_ui(parent: VBoxContainer) -> void:
	_token_container = VBoxContainer.new()
	_token_container.add_theme_constant_override("separation", 8)
	parent.add_child(_token_container)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_token_container.add_child(grid)

	for val: int in TOKEN_VALUES:
		var chip: Button = _make_styled_btn("+%d" % val, TOKEN_COLORS[val] as Color, 22)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.custom_minimum_size = Vector2(138, 48)
		chip.pressed.connect(_on_token_pressed.bind(val))
		grid.add_child(chip)
		_interactive_buttons.append(chip)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	_token_container.add_child(action_row)

	var undo_btn: Button = _make_styled_btn("Undo", Color(1.0, 0.85, 0.48, 1.0), 19)
	undo_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	undo_btn.custom_minimum_size = Vector2(0, 44)
	undo_btn.pressed.connect(_on_token_undo)
	action_row.add_child(undo_btn)
	_interactive_buttons.append(undo_btn)

	var clear_btn: Button = _make_styled_btn("Clear", Color(1.0, 0.72, 0.68, 1.0), 19)
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_btn.custom_minimum_size = Vector2(0, 44)
	clear_btn.pressed.connect(func() -> void: clear_input())
	action_row.add_child(clear_btn)
	_interactive_buttons.append(clear_btn)


func _build_abacus_ui(parent: VBoxContainer) -> void:
	_abacus_container = VBoxContainer.new()
	_abacus_container.add_theme_constant_override("separation", 8)
	parent.add_child(_abacus_container)

	var cols_row: HBoxContainer = HBoxContainer.new()
	cols_row.add_theme_constant_override("separation", 10)
	cols_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_abacus_container.add_child(cols_row)

	var titles: Array[String] = ["100s", "10s", "1s"]
	var colors: Array[Color] = [
		Color(1.0, 0.48, 0.48, 1.0),
		Color(1.0, 0.82, 0.35, 1.0),
		Color(0.42, 0.82, 0.50, 1.0),
	]

	_abacus_beads = [[], [], []]
	_abacus_num_labels.clear()

	for col_idx: int in 3:
		var col_panel: PanelContainer = PanelContainer.new()
		col_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var col_style: StyleBoxFlat = StyleBoxFlat.new()
		col_style.content_margin_left = 6.0
		col_style.content_margin_top = 8.0
		col_style.content_margin_right = 6.0
		col_style.content_margin_bottom = 8.0
		col_style.bg_color = Color(1.0, 0.985, 0.94, 1.0)
		col_style.border_width_left = 3
		col_style.border_width_top = 3
		col_style.border_width_right = 3
		col_style.border_width_bottom = 5
		col_style.border_color = Color(0.184314, 0.282353, 0.345098, 1.0)
		col_style.corner_radius_top_left = 14
		col_style.corner_radius_top_right = 14
		col_style.corner_radius_bottom_right = 14
		col_style.corner_radius_bottom_left = 14
		col_panel.add_theme_stylebox_override("panel", col_style)
		cols_row.add_child(col_panel)

		var col_vbox: VBoxContainer = VBoxContainer.new()
		col_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		col_vbox.add_theme_constant_override("separation", 4)
		col_panel.add_child(col_vbox)

		var hdr: Label = Label.new()
		hdr.text = titles[col_idx]
		hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hdr.add_theme_font_size_override("font_size", 15)
		hdr.add_theme_color_override("font_color", Color(0.24, 0.36, 0.44, 1.0))
		col_vbox.add_child(hdr)

		var up_btn: Button = _make_styled_btn("▲", colors[col_idx], 18)
		up_btn.custom_minimum_size = Vector2(72, 36)
		up_btn.pressed.connect(_step_abacus.bind(col_idx, 1))
		col_vbox.add_child(up_btn)
		_interactive_buttons.append(up_btn)

		var beads_vbox: VBoxContainer = VBoxContainer.new()
		beads_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		beads_vbox.add_theme_constant_override("separation", 3)
		col_vbox.add_child(beads_vbox)

		var bead_arr: Array[Panel] = []
		for _b: int in 9:
			var bead: Panel = Panel.new()
			bead.custom_minimum_size = Vector2(46, 9)
			bead.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			bead.mouse_filter = Control.MOUSE_FILTER_IGNORE
			beads_vbox.add_child(bead)
			bead_arr.append(bead)
		_abacus_beads[col_idx] = bead_arr

		var num_lbl: Label = Label.new()
		num_lbl.text = "0"
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_size_override("font_size", 22)
		col_vbox.add_child(num_lbl)
		_abacus_num_labels.append(num_lbl)

		var down_btn: Button = _make_styled_btn("▼", Color(0.95, 0.94, 0.88, 1.0), 18)
		down_btn.custom_minimum_size = Vector2(72, 36)
		down_btn.pressed.connect(_step_abacus.bind(col_idx, -1))
		col_vbox.add_child(down_btn)
		_interactive_buttons.append(down_btn)

	var reset_btn: Button = _make_styled_btn("Reset Beads", Color(1.0, 0.85, 0.48, 1.0), 17)
	reset_btn.custom_minimum_size = Vector2(0, 38)
	reset_btn.pressed.connect(func() -> void: clear_input())
	_abacus_container.add_child(reset_btn)
	_interactive_buttons.append(reset_btn)


func _make_styled_btn(lbl: String, fill_color: Color, font_sz: int) -> Button:
	var btn: Button = Button.new()
	btn.text = lbl
	btn.focus_mode = Control.FOCUS_NONE
	btn.set_script(JUICY_BUTTON_SCRIPT)
	btn.add_theme_font_size_override("font_size", font_sz)

	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = fill_color
	normal.content_margin_left = 8.0
	normal.content_margin_top = 6.0
	normal.content_margin_right = 8.0
	normal.content_margin_bottom = 8.0
	normal.border_width_left = 3
	normal.border_width_top = 3
	normal.border_width_right = 3
	normal.border_width_bottom = 6
	normal.border_color = Color(0.184314, 0.282353, 0.345098, 1.0)
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_right = 14
	normal.corner_radius_bottom_left = 14

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = fill_color.lightened(0.15)

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = fill_color.darkened(0.10)
	pressed.border_width_top = 5
	pressed.border_width_bottom = 3

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	return btn


func _apply_submit_styles(btn: Button) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.419608, 0.796078, 0.466667, 1.0)
	normal.content_margin_left = 18.0
	normal.content_margin_top = 12.0
	normal.content_margin_right = 18.0
	normal.content_margin_bottom = 14.0
	normal.border_width_left = 4
	normal.border_width_top = 4
	normal.border_width_right = 4
	normal.border_width_bottom = 7
	normal.border_color = Color(0.184314, 0.282353, 0.345098, 1.0)
	normal.corner_radius_top_left = 18
	normal.corner_radius_top_right = 18
	normal.corner_radius_bottom_right = 18
	normal.corner_radius_bottom_left = 18

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.51, 0.86, 0.55, 1.0)
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.35, 0.72, 0.40, 1.0)
	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.84, 0.88, 0.85, 1.0)
	disabled.border_color = Color(0.45, 0.52, 0.56, 1.0)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)


func _apply_mode_visibility() -> void:
	if _token_container != null:
		_token_container.visible = _mode == 9
	if _abacus_container != null:
		_abacus_container.visible = _mode == 10
	if _mode_badge != null:
		_mode_badge.text = "BALANCE TOKENS • TAP TO BUILD" if _mode == 9 else "BEAD LOCK • SET 100s / 10s / 1s"


func _on_token_pressed(amount: int) -> void:
	if _locked:
		return
	if _token_total + amount > MAX_TOTAL:
		nudge_gentle()
		return
	_token_stack.append(amount)
	_token_total += amount
	_refresh_display()


func _on_token_undo() -> void:
	if _locked or _token_stack.is_empty():
		return
	var last_val: int = _token_stack.pop_back() as int
	_token_total = maxi(0, _token_total - last_val)
	_refresh_display()


func _step_abacus(col_idx: int, delta: int) -> void:
	if _locked:
		return
	_abacus_digits[col_idx] = posmod(_abacus_digits[col_idx] + delta, 10)
	_refresh_display()


func _refresh_display() -> void:
	if _display_label == null:
		return
	var val: int = _get_current_value()
	var core: String = "__" if val <= 0 else str(val)
	var parts: PackedStringArray = []
	if not _unit_prefix.is_empty():
		parts.append(_unit_prefix)
	parts.append(core)
	if not _unit_suffix.is_empty():
		parts.append(_unit_suffix)
	_display_label.text = "  ".join(parts)

	if _mode == 9:
		if _token_stack.is_empty():
			_sub_readout_label.text = "Tap value tokens below to stack your answer!"
		else:
			var recent_start: int = maxi(0, _token_stack.size() - 6)
			var chips: PackedStringArray = []
			if recent_start > 0:
				chips.append("...")
			for i: int in range(recent_start, _token_stack.size()):
				chips.append("+%d" % int(_token_stack[i]))
			_sub_readout_label.text = "Tray (%d): %s" % [_token_stack.size(), " ".join(chips)]
	else:
		_sub_readout_label.text = "%d00 + %d0 + %d  =  %d" % [
			_abacus_digits[0], _abacus_digits[1], _abacus_digits[2], val
		]
		_refresh_abacus_beads()

	if _submit_btn != null:
		_submit_btn.disabled = _locked or val <= 0


func _refresh_abacus_beads() -> void:
	var active_colors: Array[Color] = [
		Color(1.0, 0.42, 0.42, 1.0),
		Color(1.0, 0.80, 0.25, 1.0),
		Color(0.35, 0.78, 0.45, 1.0),
	]
	for col_idx: int in 3:
		var count: int = _abacus_digits[col_idx]
		if col_idx < _abacus_num_labels.size():
			_abacus_num_labels[col_idx].text = str(count)
		var beads: Array = _abacus_beads[col_idx] as Array
		for i: int in beads.size():
			var bead: Panel = beads[i] as Panel
			if bead == null:
				continue
			# Fill bottom-up (index 8 down to 0)
			var is_lit: bool = (8 - i) < count
			var st: StyleBoxFlat = StyleBoxFlat.new()
			st.corner_radius_top_left = 5
			st.corner_radius_top_right = 5
			st.corner_radius_bottom_right = 5
			st.corner_radius_bottom_left = 5
			st.border_width_left = 1
			st.border_width_top = 1
			st.border_width_right = 1
			st.border_width_bottom = 2
			st.border_color = Color(0.184314, 0.282353, 0.345098, 0.85 if is_lit else 0.25)
			st.bg_color = active_colors[col_idx] if is_lit else Color(0.86, 0.89, 0.91, 0.55)
			bead.add_theme_stylebox_override("panel", st)


func _unhandled_key_input(event: InputEvent) -> void:
	if _locked or not is_visible_in_tree():
		return
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	var code: Key = key_event.keycode
	if code == KEY_ENTER or code == KEY_KP_ENTER:
		if _get_current_value() > 0:
			GameState.play_sfx(&"click")
			_submit_current()
			get_viewport().set_input_as_handled()
	elif code == KEY_BACKSPACE and _mode == 9:
		GameState.play_sfx(&"back", -4.0)
		_on_token_undo()
		get_viewport().set_input_as_handled()
	elif code == KEY_C or code == KEY_DELETE:
		GameState.play_sfx(&"back", -4.0)
		clear_input()
		get_viewport().set_input_as_handled()
