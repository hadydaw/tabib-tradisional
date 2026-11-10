class_name ForageDb
extends RefCounted
## Titik pengumpulan tanaman liar di area petualangan (data fiktif). Tiap titik punya daftar bahan umum dan
## satu bahan langka (peluang RARE_CHANCE). Titik regenerasi setelah REGEN_MINUTES menit permainan.
## Tanaman yang belum dikenal memicu minigame identifikasi (Fase 5). Logika murni, dites unit.
## Menambah titik: tambahkan entri di all_nodes() + teks `forage.<id>` di tools/loc_fase7.py; sel harus dapat dilewati.

const AREAS: Array[String] = ["hutan", "sungai", "pegunungan"]
const RARE_CHANCE: float = 0.15
const REGEN_MINUTES: float = 240.0


static func all_nodes() -> Array[Dictionary]:
	return [
		{"id": "forage_hutan_1", "area": "hutan", "cell": Vector2i(5, 4), "common": ["kumis_kucing", "sirih", "sambiloto"], "rare": "kayu_manis"},
		{"id": "forage_hutan_2", "area": "hutan", "cell": Vector2i(16, 5), "common": ["sirih", "kencur", "kumis_kucing"], "rare": "sambiloto"},
		{"id": "forage_hutan_3", "area": "hutan", "cell": Vector2i(4, 15), "common": ["serai", "lengkuas", "kumis_kucing"], "rare": "temulawak"},
		{"id": "forage_hutan_4", "area": "hutan", "cell": Vector2i(17, 15), "common": ["kencur", "kunyit", "serai"], "rare": "kayu_manis"},
		{"id": "forage_sungai_1", "area": "sungai", "cell": Vector2i(3, 15), "common": ["kunyit", "jahe", "lengkuas"], "rare": "temulawak"},
		{"id": "forage_sungai_2", "area": "sungai", "cell": Vector2i(17, 14), "common": ["lengkuas", "serai", "jahe"], "rare": "sambiloto"},
		{"id": "forage_sungai_3", "area": "sungai", "cell": Vector2i(23, 4), "common": ["kunyit", "jahe", "kencur"], "rare": "kayu_manis"},
		{"id": "forage_pegunungan_1", "area": "pegunungan", "cell": Vector2i(5, 7), "common": ["kumis_kucing", "sambiloto", "temulawak"], "rare": "kayu_manis"},
		{"id": "forage_pegunungan_2", "area": "pegunungan", "cell": Vector2i(16, 5), "common": ["temulawak", "lengkuas", "sambiloto"], "rare": "temulawak"},
		{"id": "forage_pegunungan_3", "area": "pegunungan", "cell": Vector2i(15, 15), "common": ["kayu_manis", "sirih", "kumis_kucing"], "rare": "sambiloto"},
	]


static func has(id: String) -> bool:
	return not get_node(id).is_empty()


static func get_node(id: String) -> Dictionary:
	for n in all_nodes():
		if String(n["id"]) == id:
			return n
	return {}


static func nodes_in(area: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for n in all_nodes():
		if String(n["area"]) == area:
			out.append(n)
	return out


static func is_area(id: String) -> bool:
	return AREAS.has(id)


## Hasil satu pengumpulan, deterministik dari (titik, seed). Mengembalikan {herb, rare}.
static func roll(node_id: String, seed_value: int) -> Dictionary:
	var n: Dictionary = get_node(node_id)
	if n.is_empty():
		return {"herb": "", "rare": false}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + absi(node_id.hash()) % 100003 + 1
	var rare: bool = rng.randf() < RARE_CHANCE
	var common: Array = n["common"]
	var herb: String = String(n["rare"]) if rare else String(common[rng.randi() % common.size()])
	return {"herb": herb, "rare": rare}
