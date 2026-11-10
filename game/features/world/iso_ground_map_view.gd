class_name IsoGroundMapView
extends Node2D
## Tampilan lantai dari GroundMap. Mesh dibuat sekali di _ready.

var map: GroundMap
var tile: Vector2 = Vector2(64, 32)
var _meshes: Array[ArrayMesh] = []
var _lines: ArrayMesh
var _tex_meshes: Array = []   # pasangan [mesh, Texture2D] untuk jenis tile bertekstur
## Lapisan kabut/segel (Fase 9): sel yang tertutup digambar transparan di atas lantai.
var _overlay_cells: Array[Vector2i] = []
var _overlay_color: Color = Color(0.85, 0.9, 0.95, 0.55)


func set_overlay(cells: Array[Vector2i]) -> void:
	_overlay_cells = cells.duplicate()
	queue_redraw()


func _ready() -> void:
	# Tekstur lantai berulang agar UV dunia (di luar 0-1) tetap menampilkan tekstur.
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for kind in range(TileKinds.COUNT):
		if TileKinds.TEXTURES.has(kind):
			var tm: ArrayMesh = IsoMapMeshes.textured_fill_mesh(map, tile, kind)
			var tex: Texture2D = load(TileKinds.TEXTURES[kind]) as Texture2D
			if tm != null and tex != null:
				_tex_meshes.append([tm, tex])
				continue
		var m: ArrayMesh = IsoMapMeshes.fill_mesh(map, tile, kind)
		if m != null:
			_meshes.append(m)
	var textured_kinds: Array[int] = []
	for kind in range(TileKinds.COUNT):
		if TileKinds.TEXTURES.has(kind):
			textured_kinds.append(kind)
	_lines = IsoMapMeshes.line_mesh(map, tile, textured_kinds)
	queue_redraw()


func _draw() -> void:
	for m in _meshes:
		draw_mesh(m, null)
	for pair in _tex_meshes:
		draw_mesh(pair[0], pair[1])
	if _lines != null:
		draw_mesh(_lines, null)
	for c in _overlay_cells:
		draw_colored_polygon(IsoMeshes.tile_corners(c.x, c.y, tile), _overlay_color)


func draw_call_estimate() -> int:
	return _meshes.size() + 1
