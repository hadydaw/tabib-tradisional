class_name IsoGroundMapView
extends Node2D
## Tampilan lantai dari GroundMap. Mesh dibuat sekali di _ready.

var map: GroundMap
var tile: Vector2 = Vector2(64, 32)
var _meshes: Array[ArrayMesh] = []
var _lines: ArrayMesh
## Lapisan kabut/segel (Fase 9): sel yang tertutup digambar transparan di atas lantai.
var _overlay_cells: Array[Vector2i] = []
var _overlay_color: Color = Color(0.85, 0.9, 0.95, 0.55)


func set_overlay(cells: Array[Vector2i]) -> void:
	_overlay_cells = cells.duplicate()
	queue_redraw()


func _ready() -> void:
	for kind in range(TileKinds.COUNT):
		var m: ArrayMesh = IsoMapMeshes.fill_mesh(map, tile, kind)
		if m != null:
			_meshes.append(m)
	_lines = IsoMapMeshes.line_mesh(map, tile)
	queue_redraw()


func _draw() -> void:
	for m in _meshes:
		draw_mesh(m, null)
	if _lines != null:
		draw_mesh(_lines, null)
	for c in _overlay_cells:
		draw_colored_polygon(IsoMeshes.tile_corners(c.x, c.y, tile), _overlay_color)


func draw_call_estimate() -> int:
	return _meshes.size() + 1
