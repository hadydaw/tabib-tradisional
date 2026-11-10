class_name RecipeDb
extends RefCounted
## Resep ramuan FIKTIF. `steps` = urutan bahan yang benar (herb, units = jumlah potong/ruas yang diambil
## dari inventaris, grams = takaran target). `min_level` = tingkat Pengetahuan Herbal yang membuka resep.
## `fits` = kecocokan resep terhadap penyakit (0..1); penyakit lain dianggap OTHER_FIT.
## pound_beats/pound_gap = jumlah dan jarak ketukan menumbuk (detik); stir_turns = putaran mengaduk.
## Menambah resep: tambahkan entri DATA + id di IDS + teks `recipe.<id>.name|desc` di localization.

const OTHER_FIT: float = 0.25

const IDS: Array[String] = [
	"ramuan_penghangat", "seduhan_penyejuk", "tumbukan_perut_lega", "jamu_pelega_napas",
	"lulur_pelentur_sendi", "air_tenang_kepala", "bilasan_mata_segar",
]

const DATA: Dictionary = {
	"ramuan_penghangat": {"min_level": 1, "difficulty": 1, "pound_beats": 7, "pound_gap": 0.95, "stir_turns": 3,
		"steps": [{"herb": "kunyit", "units": 2, "grams": 30}, {"herb": "jahe", "units": 1, "grams": 20}, {"herb": "serai", "units": 1, "grams": 15}],
		"fits": {"demam_embun": 0.95, "angin_gelombang": 0.7, "batuk_debu": 0.5, "sendi_karat": 0.45, "perut_kabut": 0.4}},
	"seduhan_penyejuk": {"min_level": 1, "difficulty": 1, "pound_beats": 6, "pound_gap": 1.0, "stir_turns": 3,
		"steps": [{"herb": "temulawak", "units": 1, "grams": 25}, {"herb": "sambiloto", "units": 1, "grams": 10}, {"herb": "kumis_kucing", "units": 2, "grams": 20}],
		"fits": {"lambung_panas": 0.95, "kulit_getah": 0.8, "tenggorok_kering": 0.6, "mata_pasir": 0.45, "otot_tegang": 0.3}},
	"tumbukan_perut_lega": {"min_level": 1, "difficulty": 2, "pound_beats": 8, "pound_gap": 0.85, "stir_turns": 3,
		"steps": [{"herb": "kencur", "units": 2, "grams": 25}, {"herb": "jahe", "units": 1, "grams": 15}, {"herb": "kayu_manis", "units": 1, "grams": 10}],
		"fits": {"perut_kabut": 0.95, "kulit_lembap": 0.8, "lambung_panas": 0.5, "demam_embun": 0.35}},
	"jamu_pelega_napas": {"min_level": 2, "difficulty": 2, "pound_beats": 8, "pound_gap": 0.85, "stir_turns": 4,
		"steps": [{"herb": "sirih", "units": 2, "grams": 20}, {"herb": "kencur", "units": 1, "grams": 20}, {"herb": "kayu_manis", "units": 1, "grams": 10}],
		"fits": {"batuk_debu": 0.95, "tenggorok_kering": 0.85, "angin_gelombang": 0.4}},
	"lulur_pelentur_sendi": {"min_level": 2, "difficulty": 2, "pound_beats": 10, "pound_gap": 0.8, "stir_turns": 4,
		"steps": [{"herb": "lengkuas", "units": 2, "grams": 30}, {"herb": "kunyit", "units": 1, "grams": 20}, {"herb": "serai", "units": 1, "grams": 10}],
		"fits": {"sendi_karat": 0.95, "otot_tegang": 0.85, "perut_kabut": 0.3}},
	"air_tenang_kepala": {"min_level": 3, "difficulty": 3, "pound_beats": 8, "pound_gap": 0.75, "stir_turns": 5,
		"steps": [{"herb": "serai", "units": 2, "grams": 20}, {"herb": "sirih", "units": 1, "grams": 10}, {"herb": "kumis_kucing", "units": 1, "grams": 15}, {"herb": "temulawak", "units": 1, "grams": 10}],
		"fits": {"kepala_kabut": 0.95, "angin_gelombang": 0.8, "mata_pasir": 0.75}},
	"bilasan_mata_segar": {"min_level": 3, "difficulty": 3, "pound_beats": 6, "pound_gap": 0.75, "stir_turns": 5,
		"steps": [{"herb": "sirih", "units": 1, "grams": 10}, {"herb": "sambiloto", "units": 1, "grams": 10}, {"herb": "kencur", "units": 1, "grams": 10}],
		"fits": {"mata_pasir": 0.95, "kepala_kabut": 0.55, "kulit_lembap": 0.5}},
}


static func has(id: String) -> bool:
	return DATA.has(id)


static func get_data(id: String) -> Dictionary:
	return DATA.get(id, {})


static func steps(id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var d: Dictionary = DATA.get(id, {})
	for s in d.get("steps", []):
		out.append(s)
	return out


static func herb_order(id: String) -> Array[String]:
	var out: Array[String] = []
	for s in steps(id):
		out.append(String(s["herb"]))
	return out


static func min_level(id: String) -> int:
	var d: Dictionary = DATA.get(id, {})
	return int(d.get("min_level", 1))


static func difficulty(id: String) -> int:
	var d: Dictionary = DATA.get(id, {})
	return int(d.get("difficulty", 1))


static func fit_for(recipe_id: String, ailment_id: String) -> float:
	var d: Dictionary = DATA.get(recipe_id, {})
	var f: Dictionary = d.get("fits", {})
	return float(f.get(ailment_id, OTHER_FIT))


## Resep yang terbuka pada tingkat Pengetahuan Herbal `level`.
static func unlocked(level: int) -> Array[String]:
	var out: Array[String] = []
	for id in IDS:
		if min_level(id) <= level:
			out.append(id)
	return out


## Resep terbaik untuk penyakit (semua tingkat). Dipakai tes dan hint.
static func best_for(ailment_id: String) -> String:
	var best: String = ""
	var bf: float = -1.0
	for id in IDS:
		var f: float = fit_for(id, ailment_id)
		if f > bf:
			bf = f
			best = id
	return best
