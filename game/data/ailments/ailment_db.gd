class_name AilmentDb
extends RefCounted
## Penyakit FIKTIF untuk gameplay (bukan referensi medis). Setiap penyakit punya:
## - complaints: keluhan awal yang bisa dibawa pasien,
## - profile: temuan pada tiap bagian pemeriksaan (AREAS),
## - acu_plan: urutan titik akupunktur fiktif yang dibutuhkan, acu_fit: kecocokan akupunktur (0..1),
## - difficulty (1..3) dan fee dasar.
## Menambah penyakit: tambahkan entri DATA, teks `ailment.<id>.name|desc` di localization, dan (bila perlu)
## kecocokan resep di RecipeDb. Tes unit memastikan semua profil saling berbeda cukup jauh.

## Urutan area pemeriksaan (nadi diperiksa lewat minigame ritme).
const AREAS: Array[String] = ["dahi", "mata", "lidah", "kulit", "perut", "nadi"]
const PULSE_AREA: String = "nadi"
const VISIBLE_AREAS: Array[String] = ["mata", "kulit"]  # terlihat saat "amati pasien" (gratis)

const VALUES: Dictionary = {
	"dahi": ["hangat", "dingin", "berkeringat", "normal"],
	"mata": ["merah", "kuning", "berair", "sayu"],
	"lidah": ["putih", "kuning", "merah", "pucat"],
	"kulit": ["kering", "lembap", "panas", "ruam"],
	"perut": ["kembung", "nyeri", "lunak", "normal"],
	"nadi": ["cepat", "lambat", "kuat", "lemah", "bergelombang"],
}

const IDS: Array[String] = [
	"demam_embun", "angin_gelombang", "kepala_kabut", "perut_kabut", "lambung_panas", "batuk_debu",
	"tenggorok_kering", "sendi_karat", "otot_tegang", "kulit_getah", "kulit_lembap", "mata_pasir",
]

const DATA: Dictionary = {
	"demam_embun": {
		"complaints": ["demam_dingin", "lelah_berat"], "difficulty": 1, "fee": 35, "acu_fit": 0.8,
		"profile": {"dahi": "hangat", "mata": "sayu", "lidah": "putih", "kulit": "lembap", "perut": "normal", "nadi": "cepat"},
		"acu_plan": ["ubun_embun", "pusar_bulan", "pergelangan_nadi"]},
	"angin_gelombang": {
		"complaints": ["demam_dingin", "pusing_berputar"], "difficulty": 2, "fee": 40, "acu_fit": 1.0,
		"profile": {"dahi": "dingin", "mata": "berair", "lidah": "pucat", "kulit": "kering", "perut": "normal", "nadi": "lambat"},
		"acu_plan": ["leher_kendi", "pelipis_angin", "pergelangan_nadi"]},
	"kepala_kabut": {
		"complaints": ["pusing_berputar", "mata_perih"], "difficulty": 2, "fee": 40, "acu_fit": 1.0,
		"profile": {"dahi": "normal", "mata": "sayu", "lidah": "pucat", "kulit": "kering", "perut": "normal", "nadi": "lemah"},
		"acu_plan": ["alis_pagi", "ubun_embun", "leher_kendi"]},
	"perut_kabut": {
		"complaints": ["perut_kembung", "lelah_berat"], "difficulty": 1, "fee": 35, "acu_fit": 0.7,
		"profile": {"dahi": "normal", "mata": "sayu", "lidah": "putih", "kulit": "lembap", "perut": "kembung", "nadi": "lemah"},
		"acu_plan": ["pusar_bulan", "dada_telaga", "telapak_akar"]},
	"lambung_panas": {
		"complaints": ["perut_kembung"], "difficulty": 2, "fee": 40, "acu_fit": 0.8,
		"profile": {"dahi": "hangat", "mata": "kuning", "lidah": "kuning", "kulit": "panas", "perut": "nyeri", "nadi": "kuat"},
		"acu_plan": ["pelipis_angin", "dada_telaga", "pergelangan_nadi"]},
	"batuk_debu": {
		"complaints": ["batuk_kering", "demam_dingin"], "difficulty": 2, "fee": 40, "acu_fit": 0.6,
		"profile": {"dahi": "hangat", "mata": "merah", "lidah": "putih", "kulit": "kering", "perut": "normal", "nadi": "lambat"},
		"acu_plan": ["dada_telaga", "leher_kendi", "alis_pagi"]},
	"tenggorok_kering": {
		"complaints": ["batuk_kering"], "difficulty": 1, "fee": 30, "acu_fit": 0.7,
		"profile": {"dahi": "normal", "mata": "berair", "lidah": "merah", "kulit": "kering", "perut": "normal", "nadi": "kuat"},
		"acu_plan": ["leher_kendi", "pelipis_angin", "dada_telaga"]},
	"sendi_karat": {
		"complaints": ["sendi_kaku"], "difficulty": 2, "fee": 45, "acu_fit": 1.0,
		"profile": {"dahi": "dingin", "mata": "sayu", "lidah": "pucat", "kulit": "lembap", "perut": "lunak", "nadi": "lambat"},
		"acu_plan": ["bahu_batu", "lutut_batu", "pusar_bulan"]},
	"otot_tegang": {
		"complaints": ["sendi_kaku", "lelah_berat"], "difficulty": 1, "fee": 35, "acu_fit": 1.0,
		"profile": {"dahi": "normal", "mata": "merah", "lidah": "merah", "kulit": "panas", "perut": "nyeri", "nadi": "kuat"},
		"acu_plan": ["bahu_batu", "lutut_batu", "ubun_embun"]},
	"kulit_getah": {
		"complaints": ["gatal_kulit"], "difficulty": 2, "fee": 40, "acu_fit": 0.55,
		"profile": {"dahi": "normal", "mata": "merah", "lidah": "kuning", "kulit": "ruam", "perut": "normal", "nadi": "cepat"},
		"acu_plan": ["pelipis_angin", "pergelangan_nadi", "telapak_akar"]},
	"kulit_lembap": {
		"complaints": ["gatal_kulit", "perut_kembung"], "difficulty": 3, "fee": 50, "acu_fit": 0.6,
		"profile": {"dahi": "berkeringat", "mata": "berair", "lidah": "putih", "kulit": "ruam", "perut": "kembung", "nadi": "bergelombang"},
		"acu_plan": ["pusar_bulan", "pergelangan_nadi", "leher_kendi"]},
	"mata_pasir": {
		"complaints": ["mata_perih", "pusing_berputar"], "difficulty": 3, "fee": 50, "acu_fit": 0.9,
		"profile": {"dahi": "normal", "mata": "merah", "lidah": "merah", "kulit": "kering", "perut": "normal", "nadi": "bergelombang"},
		"acu_plan": ["alis_pagi", "pelipis_angin", "ubun_embun"]},
}


static func has(id: String) -> bool:
	return DATA.has(id)


static func get_data(id: String) -> Dictionary:
	return DATA.get(id, {})


static func profile(id: String) -> Dictionary:
	var d: Dictionary = DATA.get(id, {})
	return d.get("profile", {})


static func finding(id: String, area: String) -> String:
	return String(profile(id).get(area, ""))


static func acu_plan(id: String) -> Array[String]:
	var out: Array[String] = []
	var d: Dictionary = DATA.get(id, {})
	for p in d.get("acu_plan", []):
		out.append(String(p))
	return out


static func acu_fit(id: String) -> float:
	var d: Dictionary = DATA.get(id, {})
	return float(d.get("acu_fit", 0.5))


static func difficulty(id: String) -> int:
	var d: Dictionary = DATA.get(id, {})
	return int(d.get("difficulty", 1))


static func fee(id: String) -> int:
	var d: Dictionary = DATA.get(id, {})
	return int(d.get("fee", 30))


## Penyakit yang bisa muncul sebagai keluhan `complaint_id` (urutan IDS, deterministik).
static func candidates_for(complaint_id: String) -> Array[String]:
	var out: Array[String] = []
	for id in IDS:
		var d: Dictionary = DATA[id]
		if (d["complaints"] as Array).has(complaint_id):
			out.append(id)
	return out


## Penyakit sebenarnya untuk satu kunjungan: deterministik dari `seed_value`.
static func pick_for(complaint_id: String, seed_value: int) -> String:
	var c: Array[String] = candidates_for(complaint_id)
	if c.is_empty():
		return IDS[absi(seed_value) % IDS.size()]
	return c[absi(seed_value) % c.size()]


## Jumlah area yang temuannya berbeda antara dua penyakit.
static func distance(a: String, b: String) -> int:
	var n: int = 0
	for area in AREAS:
		if finding(a, area) != finding(b, area):
			n += 1
	return n
