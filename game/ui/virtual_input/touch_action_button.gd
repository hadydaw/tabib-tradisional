class_name TouchActionButton
extends Control
## Tombol sentuh multi-touch (membaca InputEventScreenTouch langsung). Dibuat sendiri
## karena emulasi mouse dari sentuhan hanya melayani satu jari, sedangkan joystick dan
## tombol aksi harus bisa dipakai bersamaan.

signal pressed

@export var font_size: int = 26

var text: String = "":
	set(value):
		text = value
		queue_redraw()

var _touch_index: int = -1
var _down: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if _touch_index == -1 and _contains(t.position):
				_touch_index = t.index
				_set_down(true)
		elif t.index == _touch_index:
			var inside: bool = _contains(t.position)
			_touch_index = -1
			_set_down(false)
			if inside:
				pressed.emit()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch_index:
			_set_down(_contains(d.position))


func _contains(point: Vector2) -> bool:
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * point
	return Rect2(Vector2.ZERO, size).has_point(local)


func _set_down(value: bool) -> void:
	if _down != value:
		_down = value
		queue_redraw()


func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.9, 0.6, 0.15, 0.95) if _down else Color(0.15, 0.35, 0.28, 0.85)
	sb.set_corner_radius_all(int(minf(size.x, size.y) * 0.25))
	sb.border_color = Color(1, 1, 1, 0.5)
	sb.set_border_width_all(3)
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	var font: Font = ThemeDB.fallback_font
	var tw: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pos := Vector2((size.x - tw.x) * 0.5, size.y * 0.5 + float(font_size) * 0.35)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
