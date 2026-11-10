class_name PlantArt
extends RefCounted
## Gambar prosedural placeholder untuk bagian tanaman (daun, bunga, akar/rimpang, buah). Dipakai minigame
## identifikasi dan ikon bahan. Semua dipanggil dari dalam `_draw()` CanvasItem pemanggil.

const LEAF_GREEN: Color = Color("#4f9a4f")
const LEAF_DARK: Color = Color("#2f6a38")


static func _leaf_points(length: float, half_w: float, power: float, serrate: bool = false) -> PackedVector2Array:
	var n: int = 14
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		var w: float = half_w * pow(sin(PI * t), power)
		if serrate and i > 0 and i < n:
			w *= 1.0 + (0.28 if i % 2 == 0 else -0.12)
		pts.append(Vector2(t * length, -w))
	for i in range(n - 1, 0, -1):
		var t2: float = float(i) / float(n)
		var w2: float = half_w * pow(sin(PI * t2), power)
		if serrate:
			w2 *= 1.0 + (0.28 if i % 2 == 0 else -0.12)
		pts.append(Vector2(t2 * length, w2))
	return pts


static func _place(pts: PackedVector2Array, base: Vector2, angle: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(base + p.rotated(angle))
	return out


static func _heart(size: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n: int = 28
	for i in range(n):
		var t: float = TAU * float(i) / float(n)
		var x: float = 16.0 * pow(sin(t), 3.0)
		var y: float = -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(Vector2(x, y) * (size / 34.0))
	return pts


## Daun menurut kunci ciri. `base` = pangkal daun, `angle` = arah (radian, 0 = kanan), `size` = panjang acuan.
static func draw_leaf(ci: CanvasItem, key: String, base: Vector2, angle: float, size: float) -> void:
	var col: Color = LEAF_GREEN
	match key:
		"lebar_lanset":
			_leaf(ci, _leaf_points(size, size * 0.30, 0.8), base, angle, col)
		"lanset_sempit":
			_leaf(ci, _leaf_points(size, size * 0.11, 0.9), base, angle, col)
		"pita_panjang":
			_leaf(ci, _leaf_points(size * 1.5, size * 0.06, 0.6), base, angle, col.lightened(0.1))
		"membulat_pendek":
			_leaf(ci, _leaf_points(size * 0.8, size * 0.40, 0.5), base, angle, col.lightened(0.05))
		"hati_mengkilap":
			var pts := PackedVector2Array()
			for p in _heart(size * 0.9):
				pts.append(base + (p + Vector2(0.0, -size * 0.28)).rotated(angle + PI * 0.5))
			ci.draw_colored_polygon(pts, col.lightened(0.12))
			ci.draw_polyline(PackedVector2Array([base, base + Vector2(size * 0.7, 0).rotated(angle)]), LEAF_DARK, 2.0)
			ci.draw_circle(base + Vector2(size * 0.32, -size * 0.12).rotated(angle), size * 0.05, Color(1, 1, 1, 0.45))
		"bergerigi":
			_leaf(ci, _leaf_points(size * 0.9, size * 0.26, 0.7, true), base, angle, col.darkened(0.05))
		"lanset_kecil":
			_leaf(ci, _leaf_points(size * 0.55, size * 0.12, 0.8), base, angle - 0.45, col)
			_leaf(ci, _leaf_points(size * 0.55, size * 0.12, 0.8), base, angle + 0.45, col)
		"tiga_tulang":
			_leaf(ci, _leaf_points(size * 0.95, size * 0.17, 0.8), base, angle, col.darkened(0.12))
			for off in [-0.35, 0.0, 0.35]:
				var a: float = angle + float(off) * 0.35
				ci.draw_line(base, base + Vector2(size * 0.8, 0).rotated(a), Color(0.85, 0.9, 0.6, 0.8), 2.0)
		_:
			_leaf(ci, _leaf_points(size, size * 0.2, 0.8), base, angle, col)


static func _leaf(ci: CanvasItem, pts: PackedVector2Array, base: Vector2, angle: float, col: Color) -> void:
	ci.draw_colored_polygon(_place(pts, base, angle), col)
	var tip: Vector2 = pts[int(float(pts.size()) * 0.5)] if pts.size() > 2 else Vector2(10, 0)
	ci.draw_line(base, base + tip.rotated(angle), LEAF_DARK, 2.0)


static func draw_flower(ci: CanvasItem, key: String, c: Vector2, s: float) -> void:
	match key:
		"putih_kuning":
			for i in range(5):
				var a: float = TAU * float(i) / 5.0 - PI * 0.5
				ci.draw_circle(c + Vector2(cos(a), sin(a)) * s * 0.34, s * 0.26, Color("#f7f2e4"))
			ci.draw_circle(c, s * 0.2, Color("#f2c53a"))
		"merah_kerucut", "ungu_kerucut":
			var base_col: Color = Color("#d2362c") if key == "merah_kerucut" else Color("#a98bd0")
			for i in range(6):
				var y: float = c.y + s * 0.55 - float(i) * s * 0.2
				var w: float = s * (0.42 - 0.05 * float(i))
				ci.draw_colored_polygon(PackedVector2Array([Vector2(c.x - w, y), Vector2(c.x + w, y), Vector2(c.x, y - s * 0.34)]),
					base_col.darkened(0.08 * float(i % 2)))
			ci.draw_circle(c + Vector2(0, -s * 0.62), s * 0.1, base_col.lightened(0.2))
		"putih_ungu_kecil":
			for k in range(3):
				var fc: Vector2 = c + Vector2((float(k) - 1.0) * s * 0.52, (float(k % 2) - 0.5) * s * 0.35)
				for i in range(5):
					var a2: float = TAU * float(i) / 5.0
					ci.draw_circle(fc + Vector2(cos(a2), sin(a2)) * s * 0.13, s * 0.11, Color("#f7f2e4"))
				ci.draw_circle(fc, s * 0.07, Color("#7a4aa8"))
		"kumis_panjang":
			for i in range(4):
				var a3: float = TAU * float(i) / 4.0 + 0.4
				ci.draw_circle(c + Vector2(cos(a3), sin(a3)) * s * 0.18, s * 0.17, Color("#f7f2e4"))
			for i in range(5):
				var a4: float = -PI * 0.5 + (float(i) - 2.0) * 0.32
				var e: Vector2 = c + Vector2(cos(a4), sin(a4)) * s * 0.85
				ci.draw_line(c, e, Color("#f0eaff"), 2.0)
				ci.draw_circle(e, s * 0.05, Color("#7a4aa8"))
		"tak_mencolok":
			for i in range(5):
				ci.draw_circle(c + Vector2(float(i - 2) * s * 0.18, float(i % 2) * s * 0.12), s * 0.05, Color("#7fb26a"))
		"bulir_hijau":
			for i in range(9):
				ci.draw_circle(c + Vector2(float(i - 4) * s * 0.12, sin(float(i) * 0.7) * s * 0.1), s * 0.09, Color("#8bbf5a"))
		"kuning_pucat":
			for i in range(11):
				var a5: float = float(i) * 2.399
				var rr: float = s * 0.09 * sqrt(float(i + 1))
				ci.draw_circle(c + Vector2(cos(a5), sin(a5)) * rr, s * 0.07, Color("#f2e29a"))
		_:
			ci.draw_circle(c, s * 0.2, Color("#f0f0f0"))


static func _blob(ci: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	ci.draw_line(a, b, col, w)
	ci.draw_circle(a, w * 0.5, col)
	ci.draw_circle(b, w * 0.5, col)


static func draw_root(ci: CanvasItem, key: String, c: Vector2, s: float) -> void:
	match key:
		"rimpang_jingga":
			_blob(ci, c + Vector2(-s * 0.5, 0), c + Vector2(s * 0.3, s * 0.05), s * 0.34, Color("#e8902e"))
			_blob(ci, c + Vector2(s * 0.1, -s * 0.25), c + Vector2(s * 0.5, -s * 0.1), s * 0.26, Color("#f0a244"))
			ci.draw_circle(c + Vector2(s * 0.3, s * 0.05), s * 0.12, Color("#ffc267"))
		"rimpang_krem":
			_blob(ci, c + Vector2(-s * 0.55, s * 0.05), c + Vector2(s * 0.2, s * 0.05), s * 0.22, Color("#e6d3a8"))
			for i in range(3):
				_blob(ci, c + Vector2(-s * 0.3 + float(i) * s * 0.3, s * 0.05), c + Vector2(-s * 0.2 + float(i) * s * 0.3, -s * 0.4 - float(i % 2) * s * 0.1), s * 0.15, Color("#efe0ba"))
		"rimpang_kuning_besar":
			_blob(ci, c + Vector2(-s * 0.4, 0), c + Vector2(s * 0.4, s * 0.05), s * 0.5, Color("#d6a52a"))
			_blob(ci, c + Vector2(-s * 0.1, -s * 0.38), c + Vector2(s * 0.25, -s * 0.3), s * 0.22, Color("#e2b83c"))
			ci.draw_circle(c + Vector2(s * 0.4, s * 0.05), s * 0.18, Color("#f2cc58"))
		"rimpang_kecil":
			for i in range(5):
				var off := Vector2(float(i - 2) * s * 0.26, (float(i % 2) - 0.5) * s * 0.3)
				_blob(ci, c + off, c + off + Vector2(s * 0.12, s * 0.04), s * 0.2, Color("#b08a5a"))
		"serabut_rumpun":
			ci.draw_rect(Rect2(c.x - s * 0.1, c.y - s * 0.6, s * 0.2, s * 0.5), Color("#f1f0e6"))
			for i in range(11):
				var a: float = PI * 0.5 + (float(i) - 5.0) * 0.19
				ci.draw_line(c + Vector2(0, -s * 0.1), c + Vector2(cos(a), sin(a)) * s * 0.75, Color("#c9b48a"), 2.0)
		"rimpang_merah":
			_blob(ci, c + Vector2(-s * 0.45, 0), c + Vector2(s * 0.45, 0), s * 0.46, Color("#a8543a"))
			for i in range(5):
				var x: float = c.x - s * 0.4 + float(i) * s * 0.2
				ci.draw_line(Vector2(x, c.y - s * 0.2), Vector2(x, c.y + s * 0.2), Color("#7a3524"), 3.0)
		"serabut_halus":
			for i in range(8):
				var a2: float = PI * 0.5 + (float(i) - 3.5) * 0.24
				ci.draw_line(c + Vector2(0, -s * 0.3), c + Vector2(cos(a2), sin(a2)) * s * 0.7, Color("#d8c9a4"), 1.5)
			ci.draw_circle(c + Vector2(0, -s * 0.3), s * 0.08, Color("#d8c9a4"))
		"kulit_batang":
			for i in range(3):
				var y: float = c.y + (float(i) - 1.0) * s * 0.3
				ci.draw_line(Vector2(c.x - s * 0.55, y), Vector2(c.x + s * 0.55, y), Color("#8a5a34"), s * 0.22)
				ci.draw_circle(Vector2(c.x + s * 0.55, y), s * 0.11, Color("#5c3a1e"))
				ci.draw_arc(Vector2(c.x + s * 0.55, y), s * 0.06, 0.0, TAU * 0.8, 10, Color("#c58f58"), 2.0)
		_:
			_blob(ci, c + Vector2(-s * 0.3, 0), c + Vector2(s * 0.3, 0), s * 0.3, Color("#b08a5a"))


static func draw_fruit(ci: CanvasItem, key: String, c: Vector2, s: float) -> void:
	ci.draw_line(c + Vector2(-s * 0.6, s * 0.3), c + Vector2(s * 0.6, -s * 0.1), Color("#6b5a3a"), 3.0)
	match key:
		"polong_kecil":
			for i in range(3):
				var a: Vector2 = c + Vector2(float(i - 1) * s * 0.4, -s * 0.05 + float(i) * -s * 0.03)
				_blob(ci, a, a + Vector2(s * 0.08, s * 0.5), s * 0.12, Color("#7aa84a"))
		"bulat_kecil":
			for i in range(4):
				ci.draw_circle(c + Vector2(float(i - 1.5) * s * 0.3, float(i % 2) * s * 0.22), s * 0.12, Color("#5a7a3a"))
		"buni_merah":
			for i in range(5):
				ci.draw_circle(c + Vector2(float(i - 2) * s * 0.25, float(i % 2) * s * 0.25), s * 0.11, Color("#c83a3a"))
		_:
			ci.draw_arc(c, s * 0.5, 0.0, TAU, 24, Color(1, 1, 1, 0.25), 2.0)
			ci.draw_string(ThemeDB.fallback_font, c + Vector2(-8.0, 12.0), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(1, 1, 1, 0.35))


## Ikon kecil bahan (gambar bagian akar/rimpang).
static func draw_herb_icon(ci: CanvasItem, herb_id: String, c: Vector2, s: float) -> void:
	draw_root(ci, HerbDb.trait_of(herb_id, "akar"), c, s)


## Seluruh tanaman dalam `r`; bagian di `hidden` digambar tertutup kabut.
static func draw_plant(ci: CanvasItem, plant_id: String, r: Rect2, hidden: Array) -> void:
	var soil_y: float = r.position.y + r.size.y * 0.62
	ci.draw_rect(Rect2(r.position.x, soil_y, r.size.x, r.size.y * 0.38), Color("#5b4630"))
	ci.draw_rect(Rect2(r.position.x, soil_y - 4.0, r.size.x, 8.0), Color("#6f8f3a"))
	var cx: float = r.get_center().x
	var s: float = minf(r.size.x, r.size.y) * 0.34
	# batang
	ci.draw_line(Vector2(cx, soil_y), Vector2(cx, r.position.y + r.size.y * 0.2), LEAF_DARK, 6.0)
	# daun
	if hidden.has("daun"):
		_fog(ci, Vector2(cx, soil_y - s * 0.9), s * 0.8)
	else:
		var lk: String = HerbDb.trait_of(plant_id, "daun")
		draw_leaf(ci, lk, Vector2(cx, soil_y - s * 0.2), -PI * 0.78, s * 1.1)
		draw_leaf(ci, lk, Vector2(cx, soil_y - s * 0.2), -PI * 0.22, s * 1.1)
		draw_leaf(ci, lk, Vector2(cx, soil_y - s * 0.9), -PI * 0.66, s * 0.9)
	# bunga
	var fpos := Vector2(cx, r.position.y + r.size.y * 0.16)
	if hidden.has("bunga"):
		_fog(ci, fpos, s * 0.5)
	else:
		draw_flower(ci, HerbDb.trait_of(plant_id, "bunga"), fpos, s * 0.8)
	# buah
	var bpos := Vector2(r.position.x + r.size.x * 0.82, r.position.y + r.size.y * 0.34)
	if hidden.has("buah"):
		_fog(ci, bpos, s * 0.4)
	else:
		draw_fruit(ci, HerbDb.trait_of(plant_id, "buah"), bpos, s * 0.55)
	# akar (di bawah tanah)
	var rpos := Vector2(cx, soil_y + r.size.y * 0.17)
	if hidden.has("akar"):
		_fog(ci, rpos, s * 0.6)
	else:
		draw_root(ci, HerbDb.trait_of(plant_id, "akar"), rpos, s * 0.62)


static func _fog(ci: CanvasItem, c: Vector2, rad: float) -> void:
	ci.draw_circle(c, rad, Color(0.85, 0.88, 0.9, 0.55))
	ci.draw_circle(c + Vector2(rad * 0.4, -rad * 0.2), rad * 0.6, Color(0.85, 0.88, 0.9, 0.45))
	ci.draw_string(ThemeDB.fallback_font, c + Vector2(-8.0, 12.0), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(0.2, 0.25, 0.3, 0.8))
