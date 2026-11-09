class_name TouchJoystick
extends Control
## Joystick virtual multi-touch. Membaca InputEventScreenTouch/Drag langsung (bukan
## event mouse), sehingga bisa dipakai bersamaan dengan TouchActionButton.
## Memerlukan project setting: emulate_touch_from_mouse=true agar bisa diuji dengan mouse.

signal vector_changed(value: Vector2)

@export var radius: float = 90.0
@export var dead_zone: float = 0.15
## Mode melayang: seluruh Control menjadi area sentuh; pangkal joystick muncul di titik
## sentuhan pertama dan mengikuti jari bila ditarik melewati radius (lebih nyaman di HP).
@export var floating: bool = false
## Posisi lokal pangkal saat tidak disentuh (mode melayang). Default: tengah Control.
var rest_center: Vector2 = Vector2(-1.0, -1.0)

var _touch_index: int = -1
var _knob: Vector2 = Vector2.ZERO
var _value: Vector2 = Vector2.ZERO
var _origin_canvas: Vector2 = Vector2.ZERO  # pangkal aktif (koordinat kanvas), mode melayang


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if _touch_index == -1 and _in_area(t.position):
				_touch_index = t.index
				_origin_canvas = t.position
				_update(t.position)
		elif t.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch_index:
			_update(d.position)


func _in_area(point: Vector2) -> bool:
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * point
	return Rect2(Vector2.ZERO, size).grow(0.0 if floating else 30.0).has_point(local)


func _center_in_canvas() -> Vector2:
	if floating and _touch_index != -1:
		return _origin_canvas
	return get_global_transform_with_canvas() * (size * 0.5)


func _update(point: Vector2) -> void:
	if floating:
		var offset: Vector2 = point - _origin_canvas
		if offset.length() > radius:
			_origin_canvas += offset.normalized() * (offset.length() - radius)
	_knob = (point - _center_in_canvas()).limit_length(radius)
	var v: Vector2 = _knob / radius
	_value = Vector2.ZERO if v.length() < dead_zone else v
	vector_changed.emit(_value)
	queue_redraw()


func _release() -> void:
	_touch_index = -1
	_knob = Vector2.ZERO
	_value = Vector2.ZERO
	vector_changed.emit(_value)
	queue_redraw()


func _draw() -> void:
	var c: Vector2 = size * 0.5
	if floating:
		if _touch_index != -1:
			c = get_global_transform_with_canvas().affine_inverse() * _origin_canvas
		elif rest_center.x >= 0.0:
			c = rest_center
	draw_circle(c, radius, Color(1, 1, 1, 0.12))
	draw_arc(c, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.45), 3.0)
	draw_circle(c + _knob, radius * 0.42, Color(1, 1, 1, 0.55 if _touch_index != -1 else 0.35))
