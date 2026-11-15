# res://scenes/components/sky_background.gd
# Node: SkyBackground (Control)
extends Control

@export var cloud_speeds: Array[float] = [24.0, 16.0, 30.0, 19.0]

@onready var _clouds_layer: Control = $CloudsLayer
@onready var _birds_layer: Control = $BirdsLayer
@onready var _sun: TextureRect = $Sun

var _time: float = 0.0
var _cloud_base_y: Array[float] = []
var _bird_base_y: Array[float] = []


func _ready() -> void:
	_sun.pivot_offset = _sun.size * 0.5
	for c: Node in _clouds_layer.get_children():
		var ctrl: Control = c as Control
		_cloud_base_y.append(ctrl.position.y if ctrl != null else 0.0)
	for b: Node in _birds_layer.get_children():
		var ctrl: Control = b as Control
		if ctrl != null:
			ctrl.pivot_offset = ctrl.size * 0.5
			_bird_base_y.append(ctrl.position.y)

	GameState.settings_changed.connect(_apply_motion_setting)
	_apply_motion_setting()


# With Reduce Motion on, the sky becomes a calm still picture.
func _apply_motion_setting() -> void:
	set_process(not GameState.reduce_motion)
	if GameState.reduce_motion:
		_sun.rotation = 0.0
		_sun.scale = Vector2.ONE


func _process(delta: float) -> void:
	_time += delta
	_sun.rotation = sin(_time * 0.4) * 0.08
	var sun_pulse: float = 1.0 + sin(_time * 1.2) * 0.03
	_sun.scale = Vector2(sun_pulse, sun_pulse)

	var view_width: float = size.x if size.x > 0.0 else 1280.0
	var clouds: Array[Node] = _clouds_layer.get_children()
	for i: int in clouds.size():
		var cloud: Control = clouds[i] as Control
		if cloud == null:
			continue
		var speed: float = cloud_speeds[i] if i < cloud_speeds.size() else 20.0
		cloud.position.x += speed * delta
		if i < _cloud_base_y.size():
			cloud.position.y = _cloud_base_y[i] + sin(_time * 0.9 + float(i) * 1.6) * 5.0
		if cloud.position.x > view_width + 40.0:
			cloud.position.x = -cloud.size.x - 40.0

	var birds: Array[Node] = _birds_layer.get_children()
	for i: int in birds.size():
		var bird: Control = birds[i] as Control
		if bird == null:
			continue
		var b_speed: float = 52.0 if i == 0 else 42.0
		bird.position.x += b_speed * delta
		if i < _bird_base_y.size():
			bird.position.y = _bird_base_y[i] + sin(_time * 2.2 + float(i) * 2.1) * 8.0
		# Subtle wing-flap squash
		bird.scale = Vector2(1.0, 0.85 + 0.2 * absf(sin(_time * 5.5 + float(i))))
		if bird.position.x > view_width + 60.0:
			bird.position.x = -bird.size.x - 80.0
