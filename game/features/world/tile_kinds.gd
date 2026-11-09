class_name TileKinds
extends RefCounted
## Jenis tile lantai (data placeholder). Warna sementara; tiap jenis punya sifat dapat dilewati.

const GRASS: int = 0
const DIRT: int = 1
const STONE: int = 2
const WATER: int = 3
const COUNT: int = 4

const COLORS: Array[Color] = [Color("#6f9a5b"), Color("#9b7b52"), Color("#8d8d93"), Color("#3f78b5")]
const WALKABLE: Array[bool] = [true, true, true, false]
const NAMES: PackedStringArray = ["rumput", "tanah", "batu", "air"]


static func kind_from_char(c: String) -> int:
	match c:
		"d": return DIRT
		"s": return STONE
		"~": return WATER
		_: return GRASS


static func is_walkable(kind: int) -> bool:
	return kind >= 0 and kind < COUNT and WALKABLE[kind]
