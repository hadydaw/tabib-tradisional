class_name IsoProp
extends Node2D
## Balok isometrik placeholder untuk menguji Y-sort. Titik asal (0,0) = pusat tapak
## di tanah, yaitu titik urut Y-sort (posisi "kaki").

var tile: Vector2 = Vector2(64, 32):
	set(value):
		tile = value
		queue_redraw()

var height: float = 48.0:
	set(value):
		height = value
		queue_redraw()

var footprint: float = 0.8
var color: Color = Color("#a8764a")


func _draw() -> void:
	var hw: float = tile.x * 0.5 * footprint
	var hh: float = tile.y * 0.5 * footprint
	var left := Vector2(-hw, 0)
	var bottom := Vector2(0, hh)
	var right := Vector2(hw, 0)
	var top := Vector2(0, -hh)
	var up := Vector2(0, -height)
	# Bayangan di tanah
	draw_colored_polygon(PackedVector2Array([left, bottom, right, top]), Color(0, 0, 0, 0.25))
	# Sisi kiri, kanan, atas
	draw_colored_polygon(PackedVector2Array([left, bottom, bottom + up, left + up]), color.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([bottom, right, right + up, bottom + up]), color.darkened(0.45))
	draw_colored_polygon(PackedVector2Array([left + up, top + up, right + up, bottom + up]), color.lightened(0.1))
