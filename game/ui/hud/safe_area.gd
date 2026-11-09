class_name SafeArea
extends RefCounted
## Area aman layar (di luar notch/cutout) dalam koordinat viewport virtual. Hanya di Android.

static func rect(vis: Vector2) -> Rect2:
	var full := Rect2(Vector2.ZERO, vis)
	if OS.get_name() != "Android":
		return full
	var win := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if win.x <= 0.0 or win.y <= 0.0 or safe.size.x <= 0.0 or safe.size.y <= 0.0:
		return full
	var k: Vector2 = vis / win
	return full.intersection(Rect2(safe.position * k, safe.size * k))
