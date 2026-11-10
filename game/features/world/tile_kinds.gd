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
## Varian tekstur tile per jenis (Fase 10). Tiap sel memilih satu varian lewat variant_index(), sehingga
## pola tidak tampak berulang. Jenis yang tidak ada di sini tetap warna datar.
const TEXTURE_VARIANTS: Dictionary = {
	GRASS: ["res://assets/tiles/tile_rumput_a.png", "res://assets/tiles/tile_rumput_b.png"],
	DIRT: ["res://assets/tiles/tile_tanah_a.png", "res://assets/tiles/tile_tanah_b.png"],
	STONE: ["res://assets/tiles/tile_batu_a.png", "res://assets/tiles/tile_batu_b.png"],
	WATER: ["res://assets/tiles/tile_air_a.png", "res://assets/tiles/tile_air_b.png"],
}
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


## Hash deterministik per sel: dasar untuk varian, cermin, dan variasi warna (tidak berpola kisi).
static func cell_hash(c: Vector2i) -> int:
	var h: int = c.x * 374761393 + c.y * 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return (h ^ (h >> 16)) & 0x7fffffff


## Indeks varian (0..count-1) untuk satu sel.
static func variant_index(c: Vector2i, count: int) -> int:
	if count <= 1:
		return 0
	return cell_hash(c) % count


## Cermin horizontal per sel (0 atau 1): memecah pengulangan pola antar-sel.
static func cell_flip(c: Vector2i) -> bool:
	return ((cell_hash(c) >> 8) & 1) == 1


## Pengali warna halus per sel (sekitar 0.96..1.04).
static func cell_tint(c: Vector2i) -> float:
	return 0.96 + float((cell_hash(c) >> 12) & 15) / 15.0 * 0.08


static func is_walkable(kind: int) -> bool:
	return kind >= 0 and kind < COUNT and WALKABLE[kind]
