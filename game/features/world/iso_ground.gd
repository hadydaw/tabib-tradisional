class_name IsoGround
extends Node2D
## Lantai isometrik prototipe: grid papan catur dari tile diamond, digambar lewat kode.
## Placeholder untuk uji ukuran tile, bukan aset final.

const COLOR_A := Color("#6f9a5b")
const COLOR_B := Color("#79a664")
const COLOR_LINE := Color(0, 0, 0, 0.18)

var grid_size: int = 16:
	set(value):
		grid_size = value
		queue_redraw()

var tile: Vector2 = Vector2(64, 32):
	set(value):
		tile = value
		queue_redraw()


func _draw() -> void:
	for j in range(grid_size):
		for i in range(grid_size):
			var pts := PackedVector2Array([
				IsoMath.grid_to_screen(Vector2(i, j), tile),
				IsoMath.grid_to_screen(Vector2(i + 1, j), tile),
				IsoMath.grid_to_screen(Vector2(i + 1, j + 1), tile),
				IsoMath.grid_to_screen(Vector2(i, j + 1), tile),
			])
			draw_colored_polygon(pts, COLOR_A if (i + j) % 2 == 0 else COLOR_B)
			var closed := pts.duplicate()
			closed.append(pts[0])
			draw_polyline(closed, COLOR_LINE, 1.0)
