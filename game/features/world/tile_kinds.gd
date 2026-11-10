class_name TileKinds
extends RefCounted
## Jenis tile lantai (data placeholder). Warna sementara; tiap jenis punya sifat dapat dilewati.

const GRASS: int = 0
const DIRT: int = 1
const STONE: int = 2
const WATER: int = 3
const WOOD: int = 4       # lantai kayu (interior)
const WOOD_DARK: int = 5  # lantai kayu gelap (area peracikan)
const MAT: int = 6        # keset pintu; sel ini memicu perpindahan lokasi
const PLOT: int = 7       # tanah olahan (kebun herbal)
const COUNT: int = 8

const COLORS: Array[Color] = [
	Color("#6f9a5b"), Color("#9b7b52"), Color("#8d8d93"), Color("#3f78b5"),
	Color("#b08a5a"), Color("#8a6a45"), Color("#9a4a3a"), Color("#6b4a30"),
]
const WALKABLE: Array[bool] = [true, true, true, false, true, true, true, true]
const NAMES: PackedStringArray = ["rumput", "tanah", "batu", "air", "kayu", "kayu gelap", "keset", "tanah olahan"]


static func kind_from_char(c: String) -> int:
	match c:
		"d": return DIRT
		"s": return STONE
		"~": return WATER
		"w": return WOOD
		"x": return WOOD_DARK
		"m": return MAT
		"p": return PLOT
		_: return GRASS


static func is_walkable(kind: int) -> bool:
	return kind >= 0 and kind < COUNT and WALKABLE[kind]
