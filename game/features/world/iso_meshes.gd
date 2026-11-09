class_name IsoMeshes
extends RefCounted
## Pembuat geometri isometrik placeholder (lantai dan balok). Satu sumber geometri
## dipakai oleh jalur gambar poligon (IsoProp), jalur mesh, dan pembuat atlas sprite,
## sehingga ketiganya menghasilkan bentuk dan warna yang sama.

const GROUND_COLOR_A := Color("#6f9a5b")
const GROUND_COLOR_B := Color("#79a664")
const GROUND_LINE := Color(0, 0, 0, 0.18)
const PROP_COLOR := Color("#a8764a")
const PROP_FOOTPRINT: float = 0.8
const SHADOW := Color(0, 0, 0, 0.25)


static func tile_corners(i: int, j: int, tile: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		IsoMath.grid_to_screen(Vector2(i, j), tile),
		IsoMath.grid_to_screen(Vector2(i + 1, j), tile),
		IsoMath.grid_to_screen(Vector2(i + 1, j + 1), tile),
		IsoMath.grid_to_screen(Vector2(i, j + 1), tile),
	])


static func ground_color(i: int, j: int) -> Color:
	return GROUND_COLOR_A if (i + j) % 2 == 0 else GROUND_COLOR_B


## Seluruh tile lantai sebagai satu mesh segitiga berwarna per-vertex (6 vertex per tile).
static func ground_fill_mesh(grid_size: int, tile: Vector2) -> ArrayMesh:
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	for j in range(grid_size):
		for i in range(grid_size):
			_add_quad(verts, cols, tile_corners(i, j, tile), ground_color(i, j))
	return _build(verts, cols, Mesh.PRIMITIVE_TRIANGLES)


## Garis tepi tiap tile sebagai satu mesh garis (8 vertex per tile).
static func ground_line_mesh(grid_size: int, tile: Vector2) -> ArrayMesh:
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	for j in range(grid_size):
		for i in range(grid_size):
			var p: PackedVector2Array = tile_corners(i, j, tile)
			for k in range(4):
				verts.append(p[k])
				verts.append(p[(k + 1) % 4])
				cols.append(GROUND_LINE)
				cols.append(GROUND_LINE)
	return _build(verts, cols, Mesh.PRIMITIVE_LINES)


## Bidang-bidang balok sesuai urutan gambar: bayangan, sisi kiri, sisi kanan, atas.
## Hasil: {"polys": Array[PackedVector2Array], "colors": PackedColorArray}.
static func prop_faces(tile: Vector2, height: float, footprint: float, color: Color) -> Dictionary:
	var hw: float = tile.x * 0.5 * footprint
	var hh: float = tile.y * 0.5 * footprint
	var left := Vector2(-hw, 0)
	var bottom := Vector2(0, hh)
	var right := Vector2(hw, 0)
	var top := Vector2(0, -hh)
	var up := Vector2(0, -height)
	var polys: Array[PackedVector2Array] = [
		PackedVector2Array([left, bottom, right, top]),
		PackedVector2Array([left, bottom, bottom + up, left + up]),
		PackedVector2Array([bottom, right, right + up, bottom + up]),
		PackedVector2Array([left + up, top + up, right + up, bottom + up]),
	]
	var colors := PackedColorArray([SHADOW, color.darkened(0.25), color.darkened(0.45), color.lightened(0.1)])
	return {"polys": polys, "colors": colors}


## Satu balok sebagai satu mesh (24 vertex), jadi satu draw call.
static func prop_mesh(tile: Vector2, height: float, footprint: float = PROP_FOOTPRINT, color: Color = PROP_COLOR) -> ArrayMesh:
	var faces: Dictionary = prop_faces(tile, height, footprint, color)
	var polys: Array[PackedVector2Array] = faces["polys"]
	var colors: PackedColorArray = faces["colors"]
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	for k in range(polys.size()):
		_add_quad(verts, cols, polys[k], colors[k])
	return _build(verts, cols, Mesh.PRIMITIVE_TRIANGLES)


static func _add_quad(verts: PackedVector2Array, cols: PackedColorArray, q: PackedVector2Array, color: Color) -> void:
	for idx: int in [0, 1, 2, 0, 2, 3]:
		verts.append(q[idx])
		cols.append(color)


static func _build(verts: PackedVector2Array, cols: PackedColorArray, primitive: Mesh.PrimitiveType) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(primitive, arrays)
	return mesh
