class_name ShapeBuilder
extends RefCounted
## Perakit geometri isometrik berwarna (placeholder) menjadi SATU mesh = satu draw call.
## Koordinat dalam satuan kotak grid relatif terhadap titik jangkar objek (z = tinggi piksel).
## Bidang yang terlihat dari kamera isometrik: sisi +y ("kiri"), sisi +x ("kanan"), dan atas.

var tile: Vector2
var _verts: PackedVector2Array = PackedVector2Array()
var _cols: PackedColorArray = PackedColorArray()


func _init(p_tile: Vector2) -> void:
	tile = p_tile


## Titik grid (gx, gy) pada ketinggian z (piksel) ke koordinat layar relatif jangkar.
func pt(gx: float, gy: float, z: float = 0.0) -> Vector2:
	return IsoMath.grid_to_screen(Vector2(gx, gy), tile) + Vector2(0.0, -z)


func vertex_count() -> int:
	return _verts.size()


## Poligon cembung dipecah menjadi segitiga kipas.
func add_poly(points: PackedVector2Array, color: Color) -> void:
	for i in range(1, points.size() - 1):
		_verts.append(points[0])
		_verts.append(points[i])
		_verts.append(points[i + 1])
		for _k in range(3):
			_cols.append(color)


func add_shadow(x0: float, y0: float, x1: float, y1: float) -> void:
	add_poly(PackedVector2Array([pt(x0, y0), pt(x1, y0), pt(x1, y1), pt(x0, y1)]), IsoMeshes.SHADOW)


## Balok: sisi +y (gelap 25%), sisi +x (gelap 45%), atas (terang 10%).
func add_box(x0: float, y0: float, x1: float, y1: float, z0: float, z1: float, color: Color) -> void:
	add_poly(PackedVector2Array([pt(x0, y1, z0), pt(x1, y1, z0), pt(x1, y1, z1), pt(x0, y1, z1)]), color.darkened(0.25))
	add_poly(PackedVector2Array([pt(x1, y0, z0), pt(x1, y1, z0), pt(x1, y1, z1), pt(x1, y0, z1)]), color.darkened(0.45))
	add_poly(PackedVector2Array([pt(x0, y0, z1), pt(x1, y0, z1), pt(x1, y1, z1), pt(x0, y1, z1)]), color.lightened(0.1))


## Bidang tegak pada bidang y = konstan (sisi +y), untuk dekal pintu/jendela/botol.
func add_face_y(y: float, xa: float, xb: float, za: float, zb: float, color: Color) -> void:
	add_poly(PackedVector2Array([pt(xa, y, za), pt(xb, y, za), pt(xb, y, zb), pt(xa, y, zb)]), color)


## Bidang tegak pada bidang x = konstan (sisi +x).
func add_face_x(x: float, ya: float, yb: float, za: float, zb: float, color: Color) -> void:
	add_poly(PackedVector2Array([pt(x, ya, za), pt(x, yb, za), pt(x, yb, zb), pt(x, ya, zb)]), color)


## Atap pelana/limas. Hanya dua bidang depan (+y dan +x) yang digambar; sisi belakang
## tidak terlihat pada proyeksi ini. Punggung atap sejajar sisi terpanjang.
func add_hip_roof(x0: float, y0: float, x1: float, y1: float, z: float, rise: float, color: Color) -> void:
	var w: float = x1 - x0
	var d: float = y1 - y0
	var zr: float = z + rise
	var inset: float = minf(w, d) * 0.5
	if w >= d:
		var ym: float = (y0 + y1) * 0.5
		var rx0: float = x0 + inset
		var rx1: float = x1 - inset
		add_poly(PackedVector2Array([pt(x0, y1, z), pt(x1, y1, z), pt(rx1, ym, zr), pt(rx0, ym, zr)]), color.darkened(0.12))
		add_poly(PackedVector2Array([pt(x1, y0, z), pt(x1, y1, z), pt(rx1, ym, zr)]), color.darkened(0.38))
	else:
		var xm: float = (x0 + x1) * 0.5
		var ry0: float = y0 + inset
		var ry1: float = y1 - inset
		add_poly(PackedVector2Array([pt(x1, y0, z), pt(x1, y1, z), pt(xm, ry1, zr), pt(xm, ry0, zr)]), color.darkened(0.38))
		add_poly(PackedVector2Array([pt(x0, y1, z), pt(x1, y1, z), pt(xm, ry1, zr)]), color.darkened(0.12))


## Elips datar (tajuk pohon, semak) berpusat di titik grid pada tinggi z; radius dalam piksel.
func add_ellipse(gx: float, gy: float, z: float, rx: float, ry: float, color: Color, segments: int = 14) -> void:
	var c: Vector2 = pt(gx, gy, z)
	var pts := PackedVector2Array()
	for i in range(segments):
		var a: float = TAU * float(i) / float(segments)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	add_poly(pts, color)


## Mahkota daun menjari (palem, pisang): n daun memancar dari titik (gx, gy, z).
func add_leaf_crown(gx: float, gy: float, z: float, length: float, n: int, color_a: Color, color_b: Color) -> void:
	var c: Vector2 = pt(gx, gy, z)
	for i in range(n):
		var a: float = TAU * (float(i) + 0.5) / float(n)
		var dir := Vector2(cos(a), sin(a) * 0.55)
		var tip: Vector2 = c + dir * length + Vector2(0.0, length * 0.28)
		var perp: Vector2 = Vector2(-dir.y, dir.x).normalized() * length * 0.2
		var mid: Vector2 = c + dir * length * 0.5 + Vector2(0.0, -length * 0.05)
		add_poly(PackedVector2Array([c, mid + perp, tip, mid - perp]), color_a if i % 2 == 0 else color_b)


## Mesh hasil, atau null bila kosong.
func build() -> ArrayMesh:
	if _verts.is_empty():
		return null
	return IsoMeshes._build(_verts, _cols, Mesh.PRIMITIVE_TRIANGLES)
