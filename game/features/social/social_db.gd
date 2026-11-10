class_name SocialDb
extends RefCounted
## Data sosial fiktif (Fase 8): kesukaan bahan tiap penduduk, ambang kepercayaan tingkat dan bab cerita,
## serta definisi quest cerita (syarat, langkah, dan pilihan dengan konsekuensi). Data murni, dites unit.
## Semua teks berada di localization (`sq.<id>.*`, `dlg.<npc>.*`); di sini hanya kunci dan angka.

const START_TRUST: int = 10
const TRUST_MAX: int = 100
const TALK_GAIN: int = 2          ## bicara sekali per hari
const GIFT_LIKED: int = 8         ## bahan yang disukai penduduk itu
const GIFT_OTHER: int = 3         ## bahan lain
const CHAPTER_GAIN: int = 4       ## mendengar bab cerita
const TIER_MID: int = 35          ## kepercayaan >= ini: tingkat 1 (akrab sedikit)
const TIER_HIGH: int = 70         ## kepercayaan >= ini: tingkat 2 (akrab)

## Ambang kepercayaan tiap bab cerita (bab 1, bab 2). Bab terbuka berurutan.
const CHAPTER_TRUST: Array[int] = [25, 60]

const KIND_GATHER: String = "gather"
const KIND_IDENTIFY: String = "identify"
const KIND_ZONE: String = "zone"
const KIND_TREAT: String = "treat"
const KIND_DISCOVER: String = "discover"   ## Fase 9: penemuan langka pertama
const KIND_DUNGEON: String = "dungeon"     ## Fase 9: selesai satu area khusus (gua/rawa)
const ANY: String = "any"
const GOOD_TREAT: String = "good"

## Penduduk: kesukaan bahan (ID bahan dari HerbDb) dan kepribadian singkat (kunci localization).
const PROFILES: Dictionary = {
	"karto": {"likes": "kumis_kucing", "personality": "tenang_berpengalaman"},
	"sari": {"likes": "kencur", "personality": "ramah_cerewet"},
	"wiryo": {"likes": "sirih", "personality": "bijak_pelan"},
	"dewi": {"likes": "kayu_manis", "personality": "penasaran_ceria"},
	"joko": {"likes": "lengkuas", "personality": "pendiam_jujur"},
	"lastri": {"likes": "serai", "personality": "hangat_teliti"},
	"raka": {"likes": "kunyit", "personality": "berani_bersemangat"},
	"ratih": {"likes": "jahe", "personality": "tegas_peduli"},
}

## Quest cerita. "giver": penduduk pemberi. "steps": urutan syarat (semua harus terpenuhi).
## "choices": pilihan pemain saat menyerahkan, dengan efek koin, reputasi desa, kepercayaan pemberi, dan bahan.
const QUESTS: Dictionary = {
	"q_wiryo_ramuan": {
		"giver": "wiryo", "min_trust": 30, "min_rep": 0.0,
		"steps": [{"kind": KIND_GATHER, "key": ANY, "need": 3}],
		"choices": {
			"jujur": {"coin": 25, "rep": 1.0, "trust": 6, "herb": ""},
			"untung": {"coin": 60, "rep": -1.0, "trust": -4, "herb": ""},
		},
	},
	"q_dewi_sungai": {
		"giver": "dewi", "min_trust": 15, "min_rep": 0.0,
		"steps": [{"kind": KIND_ZONE, "key": "sungai", "need": 1}],
		"choices": {
			"apa_adanya": {"coin": 15, "rep": 1.0, "trust": 5, "herb": "kayu_manis"},
			"dilebihkan": {"coin": 30, "rep": -2.0, "trust": 1, "herb": ""},
		},
	},
	"q_lastri_rawa": {
		"giver": "lastri", "min_trust": 20, "min_rep": 0.0,
		"steps": [{"kind": KIND_DISCOVER, "key": ANY, "need": 3}],
		"choices": {
			"bagi_hasil": {"coin": 30, "rep": 1.0, "trust": 5, "herb": ""},
			"simpan_sendiri": {"coin": 15, "rep": 0.0, "trust": 2, "herb": ""},
		},
	},
	"q_joko_gua": {
		"giver": "joko", "min_trust": 35, "min_rep": 0.0,
		"steps": [{"kind": KIND_DUNGEON, "key": "gua", "need": 1}],
		"choices": {
			"jujur": {"coin": 40, "rep": 1.0, "trust": 6, "herb": ""},
			"minta_bagian": {"coin": 70, "rep": -1.0, "trust": -3, "herb": ""},
		},
	},
	"q_ratih_pasien": {
		"giver": "ratih", "min_trust": 25, "min_rep": 30.0,
		"steps": [{"kind": KIND_TREAT, "key": GOOD_TREAT, "need": 3}],
		"choices": {
			"upah": {"coin": 50, "rep": 1.0, "trust": 0, "herb": ""},
			"bagi": {"coin": 10, "rep": 2.0, "trust": 6, "herb": "jahe"},
		},
	},
	"q_karto_kebun": {
		"giver": "karto", "min_trust": 40, "min_rep": 0.0,
		"steps": [{"kind": KIND_IDENTIFY, "key": ANY, "need": 2}],
		"choices": {
			"bagi_jasa": {"coin": 20, "rep": 2.0, "trust": 6, "herb": ""},
			"ambil_pujian": {"coin": 40, "rep": -1.0, "trust": -4, "herb": ""},
		},
	},
}

const QUEST_ORDER: Array[String] = ["q_dewi_sungai", "q_wiryo_ramuan", "q_karto_kebun", "q_ratih_pasien", "q_lastri_rawa", "q_joko_gua"]


static func npc_ids() -> Array[String]:
	var out: Array[String] = []
	for k in PROFILES.keys():
		out.append(String(k))
	out.sort()
	return out


static func is_npc(id: String) -> bool:
	return PROFILES.has(id)


static func likes(npc_id: String) -> String:
	return String(PROFILES.get(npc_id, {}).get("likes", ""))


static func tier_of(trust: int) -> int:
	if trust >= TIER_HIGH:
		return 2
	if trust >= TIER_MID:
		return 1
	return 0


static func has_quest(qid: String) -> bool:
	return QUESTS.has(qid)


static func quest(qid: String) -> Dictionary:
	return QUESTS.get(qid, {})


static func quest_steps(qid: String) -> Array:
	return quest(qid).get("steps", [])


static func quests_of(npc_id: String) -> Array[String]:
	var out: Array[String] = []
	for qid in QUEST_ORDER:
		if String(quest(qid).get("giver", "")) == npc_id:
			out.append(qid)
	return out
