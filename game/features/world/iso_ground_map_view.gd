class_name IsoGroundMapView
extends Node2D
## Tampilan lantai dari GroundMap. Mesh dibuat sekali di _ready.

var map: GroundMap
var tile: Vector2 = Vector2(64, 32)
var _meshes: Array[ArrayMesh] = []
var _lines: ArrayMesh


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


func draw_call_estimate() -> int:
	return _meshes.size() + 1
