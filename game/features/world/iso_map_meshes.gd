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


static func line_mesh(map: GroundMap, tile: Vector2, skip_kinds: Array[int] = []) -> ArrayMesh:
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	for y in range(map.height):
		for x in range(map.width):
			# Lantai bertekstur tidak diberi garis kisi agar sambungan antar-tile tidak terlihat.
			if skip_kinds.has(map.kind_at(Vector2i(x, y))):
				continue
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


## Mesh bertekstur untuk satu jenis tile: setiap sel mendapat UV dari kotak layarnya (diamond mengisi kotak).
## Bagian atas tekstur yang berisi permukaan tile (di bawahnya ada pita tepi gelap ketebalan sisi).
const TOP_FACE_V: float = 0.875


static func textured_fill_mesh(map: GroundMap, tile: Vector2, kind: int, variant: int = 0, count: int = 1) -> ArrayMesh:
	var verts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	for y in range(map.height):
		for x in range(map.width):
			if map.kind_at(Vector2i(x, y)) != kind:
				continue
			if TileKinds.variant_index(Vector2i(x, y), count) != variant:
				continue
			var q: PackedVector2Array = IsoMeshes.tile_corners(x, y, tile)
			var mn: Vector2 = q[0]
			var mx: Vector2 = q[0]
			for p in q:
				mn = mn.min(p)
				mx = mx.max(p)
			var size: Vector2 = mx - mn
			for idx: int in [0, 1, 2, 0, 2, 3]:
				verts.append(q[idx])
				# UV per sel: x 0-1, y dipotong ke permukaan atas (TOP_FACE_V) agar pita tepi gelap tidak tampil.
				var uv: Vector2 = (q[idx] - mn) / size
				uvs.append(Vector2(uv.x, uv.y * TOP_FACE_V))
				cols.append(Color(1, 1, 1, 1))
	if verts.is_empty():
		return null
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

