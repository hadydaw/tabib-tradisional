class_name IsoGroundMesh
extends Node2D
## Lantai yang sama dengan IsoGround, tetapi dari dua mesh (isi dan garis): 2 draw call
## alih-alih 512. Dibuat sekali, tidak dibangun ulang per frame.

var grid_size: int = 16
var tile: Vector2 = Vector2(64, 32)
var _fill: ArrayMesh
var _lines: ArrayMesh


func _ready() -> void:
	_fill = IsoMeshes.ground_fill_mesh(grid_size, tile)
	_lines = IsoMeshes.ground_line_mesh(grid_size, tile)
	queue_redraw()


func _draw() -> void:
	if _fill == null:
		return
	draw_mesh(_fill, null)
	draw_mesh(_lines, null)
