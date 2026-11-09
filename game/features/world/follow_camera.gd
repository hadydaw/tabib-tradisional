class_name FollowCamera
extends Camera2D
## Kamera yang mengikuti target dengan perataan eksponensial dan dibatasi kotak peta.
## Bila peta lebih kecil dari layar pada satu sumbu, kamera dipusatkan di sumbu itu.

@export var smooth_speed: float = 9.0

var target: Node2D
var bounds: Rect2 = Rect2()  # ukuran nol = tanpa batas
var follow_offset: Vector2 = Vector2(0.0, -24.0)  # naikkan sedikit ke arah badan, bukan kaki


func _init() -> void:
	process_priority = 100  # setelah pemain bergerak di frame yang sama


## Pusat kamera yang valid untuk `center` agar tepi layar tidak keluar dari `b`.
static func clamp_center(center: Vector2, view_size: Vector2, b: Rect2) -> Vector2:
	if b.size.x <= 0.0 or b.size.y <= 0.0:
		return center
	var half: Vector2 = view_size * 0.5
	var out: Vector2 = center
	if b.size.x <= view_size.x:
		out.x = b.get_center().x
	else:
		out.x = clampf(center.x, b.position.x + half.x, b.end.x - half.x)
	if b.size.y <= view_size.y:
		out.y = b.get_center().y
	else:
		out.y = clampf(center.y, b.position.y + half.y, b.end.y - half.y)
	return out


func view_size() -> Vector2:
	return get_viewport_rect().size / zoom


func desired_center() -> Vector2:
	if target == null:
		return global_position
	return clamp_center(target.global_position + follow_offset, view_size(), bounds)


func snap_to_target() -> void:
	global_position = desired_center()
	reset_smoothing()


func step(delta: float) -> void:
	var want: Vector2 = desired_center()
	var t: float = 1.0 - exp(-smooth_speed * delta)
	global_position = global_position.lerp(want, t)


func _process(delta: float) -> void:
	step(delta)
