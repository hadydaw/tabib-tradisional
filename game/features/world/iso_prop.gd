class_name IsoProp
extends Node2D
## Balok isometrik placeholder untuk menguji Y-sort. Titik asal (0,0) = pusat tapak
## di tanah, yaitu titik urut Y-sort (posisi "kaki").
## Jalur gambar poligon: 4 draw call per balok (profil render 0/1).

var tile: Vector2 = Vector2(64, 32):
	set(value):
		tile = value
		queue_redraw()

var height: float = 48.0:
	set(value):
		height = value
		queue_redraw()

var footprint: float = IsoMeshes.PROP_FOOTPRINT
var color: Color = IsoMeshes.PROP_COLOR


func _draw() -> void:
	var faces: Dictionary = IsoMeshes.prop_faces(tile, height, footprint, color)
	var polys: Array[PackedVector2Array] = faces["polys"]
	var colors: PackedColorArray = faces["colors"]
	for k in range(polys.size()):
		draw_colored_polygon(polys[k], colors[k])
