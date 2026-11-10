class_name ClinicUpgrades
extends RefCounted
## Upgrade fasilitas klinik. Setiap upgrade punya tingkat, biaya, syarat (reputasi / tingkat skill) dan
## EFEK GAMEPLAY nyata (bukan dekorasi). Logika murni, dites unit.
## Efek dibaca lewat fungsi *_bonus() oleh TreatmentManager, HerbInventory, MinigameManager.

signal changed

## id -> {levels: [ {cost, rep, skill: {cabang: tingkat}} ... ]}. Efek dijelaskan di teks `upgrade.<id>.effect`.
const DEFS: Dictionary = {
	"lentera": {"levels": [
		{"cost": 120, "rep": 20.0, "skill": {}},
		{"cost": 320, "rep": 30.0, "skill": {"diagnosis": 2}},
	]},
	"jarum_perak": {"levels": [
		{"cost": 180, "rep": 20.0, "skill": {"akupunktur": 2}},
		{"cost": 420, "rep": 35.0, "skill": {"akupunktur": 3}},
	]},
	"lumpang": {"levels": [
		{"cost": 150, "rep": 20.0, "skill": {"peracikan": 2}},
		{"cost": 380, "rep": 35.0, "skill": {"peracikan": 3}},
	]},
	"rak_besar": {"levels": [
		{"cost": 140, "rep": 25.0, "skill": {}},
		{"cost": 300, "rep": 40.0, "skill": {}},
	]},
	"ruang_tunggu": {"levels": [
		{"cost": 160, "rep": 25.0, "skill": {}},
		{"cost": 340, "rep": 40.0, "skill": {}},
	]},
	"kebun": {"levels": [
		{"cost": 130, "rep": 20.0, "skill": {"identifikasi_tanaman": 2}},
		{"cost": 300, "rep": 30.0, "skill": {"identifikasi_tanaman": 3}},
	]},
}

const IDS: Array[String] = ["lentera", "jarum_perak", "lumpang", "rak_besar", "ruang_tunggu", "kebun"]

## Besar efek per tingkat.
const ACU_RADIUS_PER_LEVEL: float = 0.02      # tambahan radius bidik jarum (basis 0.26)
const CRAFT_TOLERANCE_PER_LEVEL: float = 0.10 # toleransi takaran +10% per tingkat
const WAIT_PENALTY_CUT_PER_LEVEL: float = 0.30  # penalti kepuasan menunggu -30% per tingkat

var levels: Dictionary = {}


func _init() -> void:
	for id in IDS:
		levels[id] = 0


static func has(id: String) -> bool:
	return DEFS.has(id)


static func max_level(id: String) -> int:
	return (DEFS[id]["levels"] as Array).size() if DEFS.has(id) else 0


func level(id: String) -> int:
	return int(levels.get(id, 0))


func is_max(id: String) -> bool:
	return level(id) >= max_level(id)


## Data tingkat berikutnya ({cost, rep, skill}); kosong bila sudah maksimum / id tak dikenal.
func next_def(id: String) -> Dictionary:
	if not DEFS.has(id) or is_max(id):
		return {}
	return (DEFS[id]["levels"] as Array)[level(id)]


func next_cost(id: String) -> int:
	var d: Dictionary = next_def(id)
	return int(d.get("cost", -1)) if not d.is_empty() else -1


## Cek syarat beli. Hasil: {ok, reason ("max"|"rep"|"skill"|"money"|""), rep, branch, level, cost}.
func check(id: String, stats: ClinicStats, skills: SkillProgressionSystem) -> Dictionary:
	var d: Dictionary = next_def(id)
	if d.is_empty():
		return {"ok": false, "reason": "max"}
	var out: Dictionary = {"ok": true, "reason": "", "cost": int(d["cost"])}
	if stats.reputation < float(d["rep"]):
		return {"ok": false, "reason": "rep", "rep": int(d["rep"]), "cost": int(d["cost"])}
	var sk: Dictionary = d["skill"]
	for b in sk.keys():
		if skills.level(String(b)) < int(sk[b]):
			return {"ok": false, "reason": "skill", "branch": String(b), "level": int(sk[b]), "cost": int(d["cost"])}
	if stats.money < int(d["cost"]):
		return {"ok": false, "reason": "money", "cost": int(d["cost"])}
	return out


## Beli tingkat berikutnya. Mengembalikan hasil check(); uang berkurang bila ok.
func buy(id: String, stats: ClinicStats, skills: SkillProgressionSystem) -> Dictionary:
	var c: Dictionary = check(id, stats, skills)
	if not bool(c["ok"]):
		return c
	if not stats.spend(int(c["cost"]), "upgrade:%s" % id):
		c["ok"] = false
		c["reason"] = "money"
		return c
	levels[id] = level(id) + 1
	changed.emit()
	return c


func total_levels() -> int:
	var t: int = 0
	for id in IDS:
		t += level(id)
	return t


# --- Efek -------------------------------------------------------------------

func diagnosis_energy_bonus() -> int:
	return level("lentera")


func acupuncture_radius_bonus() -> float:
	return ACU_RADIUS_PER_LEVEL * float(level("jarum_perak"))


func crafting_tolerance_mult() -> float:
	return 1.0 + CRAFT_TOLERANCE_PER_LEVEL * float(level("lumpang"))


func herb_daily_min() -> int:
	return HerbInventory.DAILY_MIN + level("rak_besar")


func wait_penalty_mult() -> float:
	return maxf(0.0, 1.0 - WAIT_PENALTY_CUT_PER_LEVEL * float(level("ruang_tunggu")))


func harvest_bonus() -> int:
	return level("kebun")


## Biaya operasional per hari (naik seiring fasilitas).
func operating_cost() -> int:
	return EconomyDb.BASE_OPERATING_COST + EconomyDb.COST_PER_UPGRADE_LEVEL * total_levels()


# --- Simpan -----------------------------------------------------------------

func to_dict() -> Dictionary:
	return levels.duplicate()


func from_dict(d: Dictionary) -> void:
	for id in IDS:
		levels[id] = clampi(int(d.get(id, 0)), 0, max_level(id))
	changed.emit()
