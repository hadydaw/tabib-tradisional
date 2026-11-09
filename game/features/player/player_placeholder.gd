class_name PlayerPlaceholder
extends Node2D
## Pemain placeholder: boneka sederhana dengan animasi idle (bernapas) dan walk (ayun kaki),
## arah hadap 8 arah (titik wajah bergeser, tampak belakang tanpa wajah).
## Titik asal (0,0) = telapak kaki, yaitu titik urut Y-sort. Bukan seni final.

var facing: int = 0
var state: String = "idle"
var phase: float = 0.0

var body_scale: float = 1.0:
	set(value):
		body_scale = value
		queue_redraw()


## Dipanggil tiap frame oleh Player dengan keadaan dari PlayerAnimator.
func apply_animation(p_state: String, p_phase: float, p_facing: int) -> void:
	state = p_state
	phase = p_phase
	facing = p_facing
	queue_redraw()


func _draw() -> void:
	var s: float = body_scale
	var d: Vector2 = IsoMath.direction_vector(facing)
	var fwd := Vector2(d.x, d.y * 0.5)  # arah hadap di layar (sumbu vertikal dipipihkan 2:1)
	var swing: float = 0.0
	var bob: float = 0.0
	if state == "walk":
		swing = sin(phase * TAU)
		bob = -absf(sin(phase * TAU)) * 2.5
	else:
		bob = sin(phase * TAU) * 1.2
	_draw_ellipse(Vector2.ZERO, Vector2(14.0, 7.0) * s, Color(0, 0, 0, 0.3))
	# Kaki: berayun maju-mundur sepanjang arah hadap.
	var leg_color := Color("#2b3f35")
	var hip_y: float = -13.0 + bob
	draw_line(Vector2(-4.0, hip_y) * s, (Vector2(-4.0, 0.0) + fwd * swing * 8.0) * s, leg_color, 5.0 * s)
	draw_line(Vector2(4.0, hip_y) * s, (Vector2(4.0, 0.0) - fwd * swing * 8.0) * s, leg_color, 5.0 * s)
	# Badan dan kepala
	draw_rect(Rect2(Vector2(-8.0, -37.0 + bob) * s, Vector2(16.0, 25.0) * s), Color("#3d7a5a"))
	var head := Vector2(0.0, -44.0 + bob) * s
	draw_circle(head, 8.0 * s, Color("#e0b48a"))
	if d.y < -0.3:
		draw_circle(head + Vector2(0.0, -1.0) * s, 7.0 * s, Color("#3a2a20"))  # tampak belakang: rambut
	else:
		draw_circle(head + Vector2(d.x * 4.5, d.y * 1.5 + 1.0) * s, 1.8 * s, Color("#2a1d16"))  # wajah
	# Penanda arah di tanah
	var tip: Vector2 = fwd * 24.0 * s
	draw_line(Vector2.ZERO, tip, Color("#ffd23f"), 3.0 * s)
	draw_circle(tip, 3.5 * s, Color("#ffd23f"))


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(24):
		var a: float = TAU * float(i) / 24.0
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, color)
