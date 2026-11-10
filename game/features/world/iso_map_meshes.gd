class_name IsoMapMeshes
extends RefCounted
## Mesh lantai dari GroundMap: satu mesh isi per jenis tile + satu mesh garis,
## sehingga lantai selesai dalam beberapa draw call (jumlah jenis tile + 1).

const SHADE: float = 0.035  # selisih terang kotak catur


static func fill_mesh(map: GroundMap, tile: Vector2, kind: int) -> ArrayMesh:
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	for y in range(map.height):
		for x in range(map.width):
			if map.kind_at(Vector2i(x, y)) != kind:
				continue
			var base: Color = TileKinds.COLORS[kind]
			var color: Color = base.lightened(SHADE) if (x + y) % 2 == 0 else base
			IsoMeshes._add_quad(verts, cols, IsoMeshes.tile_corners(x, y, tile), color)
	if verts.is_empty():
		return null
	return IsoMeshes._build(verts, cols, Mesh.PRIMITIVE_TRIANGLES)


static func line_mesh(map: GroundMap, tile: Vector2) -> ArrayMesh:
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	for y in range(map.height):
		for x in range(map.width):
			var p: PackedVector2Array = IsoMeshes.tile_corners(x, y, tile)
			for k in range(4):
				verts.append(p[k])
				verts.append(p[(k + 1) % 4])
				cols.append(IsoMeshes.GROUND_LINE)
				cols.append(IsoMeshes.GROUND_LINE)
	return IsoMeshes._build(verts, cols, Mesh.PRIMITIVE_LINES)


## Kotak pembatas peta dalam koordinat layar (untuk batas kamera).
## `top_margin` memperluas batas ke atas untuk objek tinggi (pohon, dinding) di tepi belakang.
static func screen_bounds(map: GroundMap, tile: Vector2, top_margin: float = 0.0) -> Rect2:
	return Rect2(
		-float(map.height) * tile.x * 0.5, -top_margin,
		float(map.width + map.height) * tile.x * 0.5,
		float(map.width + map.height) * tile.y * 0.5 + top_margin)
