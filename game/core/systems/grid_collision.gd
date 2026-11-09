class_name GridCollision
extends RefCounted
## Tabrakan berbasis sel grid untuk pemain. Logika murni (tanpa node), dites unit.
## Pemain berbentuk kotak sejajar sumbu grid dengan setengah sisi `radius` (satuan kotak).
## Di luar batas peta dianggap terblokir. Gerak dipecah per sumbu sehingga pemain
## meluncur di sepanjang dinding alih-alih berhenti, dan dipecah dalam langkah kecil
## sehingga tidak menembus walau delta besar.

const MAX_STEP: float = 0.2

var width: int
var height: int
var radius: float
var _blocked: Dictionary = {}


func _init(p_width: int, p_height: int, p_radius: float = 0.25) -> void:
	width = p_width
	height = p_height
	radius = p_radius


func block_cell(cell: Vector2i) -> void:
	_blocked[cell] = true


func unblock_cell(cell: Vector2i) -> void:
	_blocked.erase(cell)


func blocked_cells() -> Array:
	return _blocked.keys()


func is_cell_blocked(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return true
	return _blocked.has(cell)


## Apakah kotak pemain berpusat di `pos` bebas dari sel terblokir?
func is_free(pos: Vector2) -> bool:
	var x0: int = floori(pos.x - radius)
	var x1: int = floori(pos.x + radius)
	var y0: int = floori(pos.y - radius)
	var y1: int = floori(pos.y + radius)
	for cy in range(y0, y1 + 1):
		for cx in range(x0, x1 + 1):
			if is_cell_blocked(Vector2i(cx, cy)):
				return false
	return true


## Gerakkan dari `pos` sejauh `delta` (ruang grid) dengan tabrakan dan peluncuran.
func move(pos: Vector2, delta: Vector2) -> Vector2:
	var steps: int = maxi(1, ceili(delta.length() / MAX_STEP))
	var step: Vector2 = delta / float(steps)
	var p: Vector2 = pos
	for _i in range(steps):
		if step.x != 0.0 and is_free(Vector2(p.x + step.x, p.y)):
			p.x += step.x
		if step.y != 0.0 and is_free(Vector2(p.x, p.y + step.y)):
			p.y += step.y
	return p
