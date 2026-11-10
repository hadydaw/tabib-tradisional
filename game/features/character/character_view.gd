class_name CharacterView
extends Node2D
## Tampilan karakter berlapis (placeholder, digambar kode): bayangan, kaki/bawahan, lengan,
## badan/atasan, rambut, kepala, wajah, penutup kepala. Semua warna dan gaya berasal dari
## CharacterAppearance sehingga mengganti pakaian/rambut/kulit langsung terlihat.
## Titik asal = telapak kaki (titik Y-sort). Animasi: state "idle"/"walk" + fase 0..1 dari
## PlayerAnimator dan arah 0..7. Antarmuka apply_animation sama dengan PlayerPlaceholder,
## jadi saat sprite final (SpriteFrames per lapisan, nama "<state>_<arah>") dipasang,
## Player tidak perlu diubah.

var appearance: CharacterAppearance:
	set(value):
		if appearance != null and appearance.changed.is_connected(queue_redraw):
			appearance.changed.disconnect(queue_redraw)
		appearance = value
		if appearance != null:
			appearance.changed.connect(queue_redraw)
		queue_redraw()

var body_scale: float = 1.0
var facing: int = 0
var state: String = "idle"
var phase: float = 0.0


func apply_animation(p_state: String, p_phase: float, p_facing: int) -> void:
	state = p_state
	phase = p_phase
	facing = p_facing
	queue_redraw()


func _s(v: Vector2) -> Vector2:
	return v * body_scale


func _rect(x0: float, y0: float, x1: float, y1: float, color: Color) -> void:
	draw_rect(Rect2(_s(Vector2(x0, y0)), _s(Vector2(x1 - x0, y1 - y0))), color)


func _poly(points: Array, color: Color) -> void:
	var pts := PackedVector2Array()
	for p: Vector2 in points:
		pts.append(_s(p))
	draw_colored_polygon(pts, color)


func _half_disc(center: Vector2, radius: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(0, 11):
		var a: float = PI + PI * float(i) / 10.0
		pts.append(_s(center + Vector2(cos(a) * radius, sin(a) * radius * 0.9)))
	draw_colored_polygon(pts, color)


func _draw() -> void:
	if appearance == null:
		return
	var d: Vector2 = IsoMath.direction_vector(facing)
	var fwd := Vector2(d.x, d.y * 0.5)  # arah hadap di layar (vertikal dipipihkan 2:1)
	var back: bool = d.y < -0.3
	var swing: float = 0.0
	var bob: float = 0.0
	if state == "walk":
		swing = sin(phase * TAU)
		bob = -absf(sin(phase * TAU)) * 2.5
	else:
		bob = sin(phase * TAU) * 1.2
	var skin: Color = appearance.skin_color()
	var hair: Color = appearance.hair_color()
	var hair_style: String = appearance.hair_style_name()
	var top: OutfitItem = appearance.item_in(OutfitItem.Slot.TOP)
	var bottom: OutfitItem = appearance.item_in(OutfitItem.Slot.BOTTOM)
	var headgear: OutfitItem = appearance.item_in(OutfitItem.Slot.HEAD)
	var top_style: String = top.style if top != null else "polos"
	var top_color: Color = top.color if top != null else Color("#3d7a5a")
	var top_color2: Color = top.color2 if top != null else Color.WHITE
	var head := Vector2(0.0, -44.0 + bob)

	# 1. Bayangan
	var shadow := PackedVector2Array()
	for i in range(20):
		var a: float = TAU * float(i) / 20.0
		shadow.append(_s(Vector2(cos(a) * 14.0, sin(a) * 7.0)))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.3))

	# 2. Rambut panjang di belakang badan (tampak depan/samping)
	if hair_style == "panjang" and not back:
		_rect(-8.5, head.y - 2.0, 8.5, head.y + 17.0, hair)

	# 3. Kaki dan bawahan
	var hip_y: float = -13.0 + bob
	var foot_l: Vector2 = Vector2(-4.0, 0.0) + fwd * swing * 8.0
	var foot_r: Vector2 = Vector2(4.0, 0.0) - fwd * swing * 8.0
	var bstyle: String = bottom.style if bottom != null else "celana"
	var bcolor: Color = bottom.color if bottom != null else Color("#2b3f35")
	if bstyle == "kain":
		draw_line(_s(Vector2(-4.0, hip_y)), _s(foot_l), skin, 4.0 * body_scale)
		draw_line(_s(Vector2(4.0, hip_y)), _s(foot_r), skin, 4.0 * body_scale)
		var sway: float = swing * 1.5
		_poly([Vector2(-8.5, -22.0 + bob), Vector2(8.5, -22.0 + bob), Vector2(10.5 + sway, -5.0 + bob * 0.5), Vector2(-10.5 + sway, -5.0 + bob * 0.5)], bcolor)
		_rect(-8.5, -22.0 + bob, 8.5, -19.5 + bob, bottom.color2 if bottom != null else Color.WHITE)
	else:
		draw_line(_s(Vector2(-4.0, hip_y)), _s(foot_l), bcolor, 5.0 * body_scale)
		draw_line(_s(Vector2(4.0, hip_y)), _s(foot_r), bcolor, 5.0 * body_scale)
		draw_circle(_s(foot_l), 2.6 * body_scale, bcolor.darkened(0.3))
		draw_circle(_s(foot_r), 2.6 * body_scale, bcolor.darkened(0.3))

	# 4. Lengan (berayun berlawanan dengan kaki)
	var sleeve: Color = top_color if top_style in ["polos", "jubah"] else skin
	var arm_swing: Vector2 = fwd * swing * 6.0
	draw_line(_s(Vector2(-9.0, -33.0 + bob)), _s(Vector2(-10.0, -19.0 + bob) - arm_swing), sleeve, 4.0 * body_scale)
	draw_line(_s(Vector2(9.0, -33.0 + bob)), _s(Vector2(10.0, -19.0 + bob) + arm_swing), sleeve, 4.0 * body_scale)
	draw_circle(_s(Vector2(-10.0, -18.0 + bob) - arm_swing), 2.2 * body_scale, skin)
	draw_circle(_s(Vector2(10.0, -18.0 + bob) + arm_swing), 2.2 * body_scale, skin)

	# 5. Badan / atasan
	match top_style:
		"rompi":
			_rect(-8.0, -37.0 + bob, 8.0, -12.0 + bob, top_color2)
			_rect(-8.0, -37.0 + bob, -3.0, -12.0 + bob, top_color)
			_rect(3.0, -37.0 + bob, 8.0, -12.0 + bob, top_color)
		"jubah":
			_poly([Vector2(-8.0, -37.0 + bob), Vector2(8.0, -37.0 + bob), Vector2(10.5, -8.0 + bob), Vector2(-10.5, -8.0 + bob)], top_color)
			_rect(-1.0, -37.0 + bob, 1.0, -8.0 + bob, top_color2)
			_rect(-8.0, -37.0 + bob, 8.0, -34.5 + bob, top_color2)
		_:
			_rect(-8.0, -37.0 + bob, 8.0, -12.0 + bob, top_color)

	# 6. Leher dan kepala
	_rect(-2.5, -39.0 + bob, 2.5, -35.0 + bob, skin)
	draw_circle(_s(head), 8.0 * body_scale, skin)

	# 7. Rambut di atas kepala
	if back:
		if hair_style != "botak":
			draw_circle(_s(head + Vector2(0.0, -1.0)), 8.3 * body_scale, hair)
			if hair_style == "panjang":
				_rect(-8.5, head.y - 2.0, 8.5, head.y + 17.0, hair)
	else:
		if hair_style != "botak":
			_half_disc(head + Vector2(0.0, -1.0), 8.6, hair)
	if hair_style == "sanggul":
		draw_circle(_s(head + Vector2(-d.x * 3.0, -9.5)), 4.5 * body_scale, hair)

	# 8. Wajah (hanya bila tidak membelakangi)
	if not back:
		var base := Vector2(d.x * 4.0, 0.5)
		var spread: float = 2.6 * (1.0 - absf(d.x) * 0.8)
		var eye := Color("#2a1d16")
		if d.y > 0.2:
			draw_circle(_s(head + base + Vector2(-spread, 0.0)), 1.5 * body_scale, eye)
			draw_circle(_s(head + base + Vector2(spread, 0.0)), 1.5 * body_scale, eye)
		else:
			draw_circle(_s(head + base), 1.5 * body_scale, eye)

	# 9. Penutup kepala
	if headgear != null:
		match headgear.style:
			"ikat":
				draw_line(_s(head + Vector2(-8.2, -3.0)), _s(head + Vector2(8.2, -3.0)), headgear.color, 3.5 * body_scale)
				draw_circle(_s(head + Vector2(-d.x * 8.0, -2.0)), 2.6 * body_scale, headgear.color)
			"caping":
				var brim := PackedVector2Array()
				for i in range(20):
					var a: float = TAU * float(i) / 20.0
					brim.append(_s(head + Vector2(0.0, -6.0) + Vector2(cos(a) * 17.0, sin(a) * 6.0)))
				draw_colored_polygon(brim, headgear.color.darkened(0.15))
				_poly([head + Vector2(-11.0, -6.0), head + Vector2(0.0, -20.0), head + Vector2(11.0, -6.0)], headgear.color)
			"kain_kepala":
				_half_disc(head + Vector2(0.0, -0.5), 9.0, headgear.color)
				draw_circle(_s(head + Vector2(-d.x * 6.0, -6.0)), 3.0 * body_scale, headgear.color.lightened(0.15))
