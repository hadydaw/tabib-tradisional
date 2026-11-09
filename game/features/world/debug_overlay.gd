class_name DebugOverlay
extends Node2D
## Overlay debug: sel terblokir (merah), kotak tabrakan pemain, sel pemain. Hanya saat visible.

var collision: GridCollision
var player: Player
var map: GroundMap
var tile: Vector2 = Vector2(64, 32)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if collision == null or player == null:
		return
	for cell: Vector2i in collision.blocked_cells():
		draw_colored_polygon(IsoMeshes.tile_corners(cell.x, cell.y, tile), Color(1, 0.1, 0.1, 0.35))
	if map != null:
		for y in range(map.height):
			for x in range(map.width):
				if not map.is_walkable(Vector2i(x, y)):
					draw_colored_polygon(IsoMeshes.tile_corners(x, y, tile), Color(1, 0.1, 0.1, 0.35))
	var r: float = collision.radius
	var g: Vector2 = player.grid_pos
	var box := PackedVector2Array([
		IsoMath.grid_to_screen(g + Vector2(-r, -r), tile), IsoMath.grid_to_screen(g + Vector2(r, -r), tile),
		IsoMath.grid_to_screen(g + Vector2(r, r), tile), IsoMath.grid_to_screen(g + Vector2(-r, r), tile),
	])
	draw_colored_polygon(box, Color(0.2, 1, 0.4, 0.5))
	var cell := Vector2i(floori(g.x), floori(g.y))
	var corners: PackedVector2Array = IsoMeshes.tile_corners(cell.x, cell.y, tile)
	corners.append(corners[0])
	draw_polyline(corners, Color(1, 1, 0, 0.9), 2.0)
