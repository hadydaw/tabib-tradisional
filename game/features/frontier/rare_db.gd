class_name RareDb
extends RefCounted
## Data penemuan langka (Fase 9): jenis bahan langka, titik pengambilan di Rawa dan Gua Kapur, dan teka-teki
## lingkungan. Semua fiktif. Bahan langka tidak punya efek pengobatan nyata; hanya koleksi, quest, dan kunci akses.
## Data murni, dites unit.

const COOLDOWN_MINUTES: int = 300
const RARE_CHANCE: float = 0.2
const STAMINA_COST: float = 10.0

const ITEMS: Array[String] = ["akar_rawa", "benih_kemuning", "benih_cendana", "jamur_gua", "batu_kompas", "kristal_tetes"]

## Titik pengambilan. pool[0] = bahan umum titik itu, pool[1] = bahan langka (peluang RARE_CHANCE).
const NODES: Dictionary = {
	"rawa_1": {"area": "rawa", "cell": Vector2i(4, 4), "pool": ["akar_rawa", "benih_kemuning"]},
	"rawa_2": {"area": "rawa", "cell": Vector2i(9, 14), "pool": ["akar_rawa", "benih_cendana"]},
	"rawa_dalam_1": {"area": "rawa", "cell": Vector2i(21, 3), "pool": ["benih_cendana", "kristal_tetes"]},
	"rawa_dalam_2": {"area": "rawa", "cell": Vector2i(22, 8), "pool": ["benih_kemuning", "kristal_tetes"]},
	"gua_1": {"area": "gua", "cell": Vector2i(4, 11), "pool": ["jamur_gua", "batu_kompas"]},
	"gua_2": {"area": "gua", "cell": Vector2i(13, 13), "pool": ["jamur_gua", "kristal_tetes"]},
}

## Teka-teki lingkungan: urutan simbol yang benar. Simbol: api, air, angin, tanah.
## reward: hadiah pertama kali teka-teki dipecahkan (koin dan satu bahan langka).
const PUZZLES: Dictionary = {
	"penjaga_rawa": {"options": ["air", "angin", "api", "tanah"], "answer": ["air", "angin", "api"],
		"reward": {"coin": 25, "item": "kristal_tetes"}},
	"tablet_gua": {"options": ["api", "air", "angin", "tanah"], "answer": ["tanah", "api", "air"],
		"reward": {"coin": 25, "item": "batu_kompas"}},
	"tuas_gua": {"options": ["api", "air", "angin", "tanah"], "answer": ["angin", "tanah"],
		"reward": {"coin": 25, "item": "jamur_gua"}},
}

## Isi peti gua (sekali seumur permainan).
const CHEST: Dictionary = {"coin": 60, "item": "benih_cendana", "n": 2}
## Koin tambahan untuk setiap jenis penemuan langka yang pertama kali ditemukan.
const FIRST_COIN: int = 15

const TABLET_ID: String = "tablet_gua"
const LEVER_ID: String = "tuas_gua"
const RIDDLE_ID: String = "penjaga_rawa"
const CHEST_ID: String = "peti_gua"
const GATE_GUA_FIRST_FINDS: int = 2


static func is_node(id: String) -> bool:
	return NODES.has(id)


static func node(id: String) -> Dictionary:
	return NODES.get(id, {})


static func nodes_in(area: String) -> Array[String]:
	var out: Array[String] = []
	for k in NODES.keys():
		if String(NODES[k]["area"]) == area:
			out.append(String(k))
	out.sort()
	return out


static func has_item(id: String) -> bool:
	return ITEMS.has(id)


static func has_puzzle(id: String) -> bool:
	return PUZZLES.has(id)


static func puzzle(id: String) -> Dictionary:
	return PUZZLES.get(id, {})


## Bahan yang didapat dari sebuah titik. Deterministik dari (titik, seed) agar tes dan simpanan konsisten.
static func roll(node_id: String, seed_value: int) -> String:
	var n: Dictionary = node(node_id)
	if n.is_empty():
		return ""
	var pool: Array = n["pool"]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 6151 + absi(node_id.hash()) % 100003 + 1
	return String(pool[1]) if rng.randf() < RARE_CHANCE else String(pool[0])
