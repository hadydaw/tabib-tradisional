class_name IsoMeshProp
extends Node2D
## Balok yang sama dengan IsoProp, tetapi satu mesh bersama: 1 draw call per balok.
## Mesh disimpan di cache menurut (tile, tinggi) sehingga banyak balok memakai mesh yang sama.

static var _cache: Dictionary = {}
var _mesh: ArrayMesh


func setup(tile: Vector2, height: float) -> void:
	var key: String = "%d_%d_%d" % [int(tile.x), int(tile.y), int(height * 10.0)]
	if not _cache.has(key):
		_cache[key] = IsoMeshes.prop_mesh(tile, height)
	_mesh = _cache[key]
	queue_redraw()


func _draw() -> void:
	if _mesh != null:
		draw_mesh(_mesh, null)
