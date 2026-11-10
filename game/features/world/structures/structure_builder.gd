class_name StructureBuilder
extends RefCounted
## Bangunan placeholder dari potongan per-sel agar urutan Y-sort benar untuk bangunan lebar:
## tiap sel dinding yang terlihat (kolom +x dan baris +y) adalah satu node berjangkar di
## sel itu; atap adalah satu node berjangkar di sel sudut depan (dengan y_sort_origin lebih besar
## sehingga digambar di atas dinding sudut). Sel bagian dalam tidak digambar (tertutup atap).
##
## Gaya (Dictionary): wall, roof (Color), height (kelipatan tile.y), roof_height,
## door_side "y"|"x", door_cells (Array[int] indeks sel sepanjang sisi pintu), windows (bool).

const OVERHANG: float = 0.3
## Atap digeser turun sekian piksel (node) dan mesh digeser naik sebaliknya: tampilan sama,
## tetapi titik urut Y-sort atap sedikit di depan dinding sudut sehingga digambar di atasnya.
const ROOF_SORT_SHIFT: float = 2.0

static var _cache: Dictionary = {}


## Semua sel yang ditempati bangunan (untuk tabrakan).
static func footprint_cells(rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, y))
	return cells


## Sel yang digambar sebagai dinding (terlihat dari kamera).
static func visible_wall_cells(rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var x1: int = rect.end.x - 1
	var y1: int = rect.end.y - 1
	for c in footprint_cells(rect):
		if c.x == x1 or c.y == y1:
			cells.append(c)
	return cells


static func _door_cell(rect: Rect2i, style: Dictionary, cell: Vector2i) -> bool:
	var side: String = style.get("door_side", "y")
	var cells: Array = style.get("door_cells", [])
	if side == "y" and cell.y == rect.end.y - 1:
		return cells.has(cell.x - rect.position.x)
	if side == "x" and cell.x == rect.end.x - 1:
		return cells.has(cell.y - rect.position.y)
	return false


static func wall_mesh(tile: Vector2, rect: Rect2i, style: Dictionary, cell: Vector2i) -> ArrayMesh:
	var is_door: bool = _door_cell(rect, style, cell)
	var side: String = style.get("door_side", "y")
	var windows: bool = style.get("windows", true)
	var on_y_face: bool = cell.y == rect.end.y - 1
	var on_x_face: bool = cell.x == rect.end.x - 1
	var win_y: bool = windows and on_y_face and not is_door and (cell.x - rect.position.x) % 2 == 0 and side == "y"
	var win_x: bool = windows and on_x_face and not is_door and (cell.y - rect.position.y) % 2 == 0 and side == "x"
	# Jendela juga di sisi yang bukan sisi pintu, agar dinding tidak polos.
	if windows and on_y_face and side == "x" and (cell.x - rect.position.x) % 2 == 1:
		win_y = true
	if windows and on_x_face and side == "y" and (cell.y - rect.position.y) % 2 == 1:
		win_x = true
	var key: String = "w|%d|%s|%s|%s|%s|%s|%s" % [int(tile.x), str(style.get("height", 2.0)), (style["wall"] as Color).to_html(), is_door, win_y, win_x, "%d%d" % [int(on_y_face), int(on_x_face)]]
	if _cache.has(key):
		return _cache[key]
	var b := ShapeBuilder.new(tile)
	var h: float = tile.y * float(style.get("height", 2.0))
	b.add_box(-0.5, -0.5, 0.5, 0.5, 0.0, h, style["wall"])
	if is_door:
		var door_h: float = tile.y * 1.5
		if side == "y" and on_y_face:
			b.add_face_y(0.5, -0.32, 0.32, 0.0, door_h + 4.0, Color("#6b4a30"))
			b.add_face_y(0.5, -0.24, 0.24, 0.0, door_h, Color("#3a2418"))
		if side == "x" and on_x_face:
			b.add_face_x(0.5, -0.32, 0.32, 0.0, door_h + 4.0, Color("#6b4a30"))
			b.add_face_x(0.5, -0.24, 0.24, 0.0, door_h, Color("#3a2418"))
	if win_y and on_y_face:
		b.add_face_y(0.5, -0.24, 0.24, h * 0.45, h * 0.8, Color("#6b4a30"))
		b.add_face_y(0.5, -0.18, 0.18, h * 0.5, h * 0.75, Color("#9ad0e8"))
	if win_x and on_x_face:
		b.add_face_x(0.5, -0.24, 0.24, h * 0.45, h * 0.8, Color("#6b4a30"))
		b.add_face_x(0.5, -0.18, 0.18, h * 0.5, h * 0.75, Color("#9ad0e8"))
	_cache[key] = b.build()
	return _cache[key]


## Atap berjangkar di sel sudut depan (x1, y1) dari `rect`.
static func roof_mesh(tile: Vector2, rect: Rect2i, style: Dictionary) -> ArrayMesh:
	var key: String = "r|%d|%d,%d|%s|%s|%s|%s" % [int(tile.x), rect.size.x, rect.size.y, str(style.get("height", 2.0)), str(style.get("roof_height", 1.4)), (style["roof"] as Color).to_html(), "x"]
	if _cache.has(key):
		return _cache[key]
	var b := ShapeBuilder.new(tile)
	b.shift = Vector2(0.0, -ROOF_SORT_SHIFT)
	var ax: float = float(rect.end.x - 1) + 0.5
	var ay: float = float(rect.end.y - 1) + 0.5
	var x0: float = float(rect.position.x) - ax - OVERHANG
	var y0: float = float(rect.position.y) - ay - OVERHANG
	var x1: float = float(rect.end.x) - ax + OVERHANG
	var y1: float = float(rect.end.y) - ay + OVERHANG
	var wall_h: float = tile.y * float(style.get("height", 2.0))
	var rise: float = tile.y * float(style.get("roof_height", 1.4))
	b.add_hip_roof(x0, y0, x1, y1, wall_h, rise, style["roof"])
	_cache[key] = b.build()
	return _cache[key]


## Node-node bangunan: dinding terlihat + atap. Posisi sudah dalam koordinat layar.
static func spawn_nodes(tile: Vector2, rect: Rect2i, style: Dictionary) -> Array[Node2D]:
	var nodes: Array[Node2D] = []
	for cell in visible_wall_cells(rect):
		var wall := IsoStaticMesh.new()
		wall.mesh = wall_mesh(tile, rect, style, cell)
		wall.position = IsoMath.grid_to_screen(Vector2(cell.x + 0.5, cell.y + 0.5), tile)
		nodes.append(wall)
	var roof := IsoStaticMesh.new()
	roof.mesh = roof_mesh(tile, rect, style)
	roof.position = IsoMath.grid_to_screen(Vector2(rect.end.x - 0.5, rect.end.y - 0.5), tile) + Vector2(0.0, ROOF_SORT_SHIFT)
	nodes.append(roof)
	return nodes
