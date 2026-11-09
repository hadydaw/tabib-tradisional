class_name GroundMap
extends RefCounted
## Data peta lantai: grid jenis tile (lihat TileKinds). Logika murni, dites unit.

var width: int = 0
var height: int = 0
var cells: PackedInt32Array = PackedInt32Array()


## Dari baris teks (semua baris harus sama panjang).
static func from_rows(rows: Array[String]) -> GroundMap:
	var m := GroundMap.new()
	m.height = rows.size()
	m.width = rows[0].length() if rows.size() > 0 else 0
	m.cells.resize(m.width * m.height)
	for y in range(m.height):
		for x in range(m.width):
			m.cells[y * m.width + x] = TileKinds.kind_from_char(rows[y][x])
	return m


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


## Jenis tile di sel; -1 di luar peta.
func kind_at(cell: Vector2i) -> int:
	if not in_bounds(cell):
		return -1
	return cells[cell.y * width + cell.x]


func is_walkable(cell: Vector2i) -> bool:
	return TileKinds.is_walkable(kind_at(cell))
