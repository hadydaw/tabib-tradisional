class_name PlayerPlaceholder
extends Node2D
## Pemain placeholder untuk prototipe: siluet sederhana dengan penanda arah 8 arah.
## Titik asal (0,0) = telapak kaki, yaitu titik urut Y-sort.

var facing: int = 0:
	set(value):
		if value != facing:
			facing = value
			queue_redraw()

var body_scale: float = 1.0:
	set(value):
		body_scale = value
		queue_redraw()


func _draw() -> void:
	var s: float = body_scale
	_draw_ellipse(Vector2.ZERO, Vector2(14.0, 7.0) * s, Color(0, 0, 0, 0.3))
	draw_rect(Rect2(Vector2(-8.0, -34.0) * s, Vector2(16.0, 28.0) * s), Color("#3d7a5a"))
	draw_circle(Vector2(0.0, -40.0) * s, 8.0 * s, Color("#e0b48a"))
	# Penanda arah di tanah (pada layar, sumbu vertikal dipipihkan 2:1)
	var d: Vector2 = IsoMath.direction_vector(facing)
	var tip: Vector2 = Vector2(d.x, d.y * 0.5) * 24.0 * s
	draw_line(Vector2.ZERO, tip, Color("#ffd23f"), 3.0 * s)
	draw_circle(tip, 3.5 * s, Color("#ffd23f"))


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(24):
		var a: float = TAU * float(i) / 24.0
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, color)
