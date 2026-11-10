class_name SkillProgressionSystem
extends RefCounted
## Perkembangan skill (logika murni, dites unit). Lima cabang: diagnosis, akupunktur, pengetahuan herbal,
## peracikan, identifikasi tanaman. XP datang dari hasil minigame (tingkat S..D x kesulitan). Efek tingkat
## dibaca lewat `effect()` (SkillDb) dan hanya melonggarkan jendela ketepatan secara terbatas.

signal leveled_up(branch: String, level: int)

## Pembagian XP: jenis minigame -> {cabang: pengali}.
const XP_RULES: Dictionary = {
	"diagnosis": {"diagnosis": 1.0},
	"akupunktur": {"akupunktur": 1.0},
	"peracikan": {"peracikan": 1.0, "pengetahuan_herbal": 0.3},
	"identifikasi": {"identifikasi_tanaman": 1.0, "pengetahuan_herbal": 0.4},
}

var xp: Dictionary = {}
var known_plants: Array[String] = []


func _init() -> void:
	for b in SkillDb.BRANCHES:
		xp[b] = 0


func xp_of(branch: String) -> int:
	return int(xp.get(branch, 0))


func level(branch: String) -> int:
	return SkillDb.level_for_xp(xp_of(branch))


## Pecahan menuju tingkat berikutnya (1.0 bila sudah maksimum).
func progress(branch: String) -> float:
	var lvl: int = level(branch)
	if lvl >= SkillDb.MAX_LEVEL:
		return 1.0
	var lo: int = SkillDb.LEVEL_XP[lvl - 1]
	var hi: int = SkillDb.LEVEL_XP[lvl]
	return clampf(float(xp_of(branch) - lo) / float(hi - lo), 0.0, 1.0)


func effect(branch: String, key: String) -> float:
	return SkillDb.effect(branch, key, level(branch))


## Tambah XP; mengembalikan jumlah tingkat yang naik.
func add_xp(branch: String, amount: int) -> int:
	if not xp.has(branch) or amount <= 0:
		return 0
	var before: int = level(branch)
	xp[branch] = xp_of(branch) + amount
	var after: int = level(branch)
	for l in range(before + 1, after + 1):
		leveled_up.emit(branch, l)
	return after - before


## Beri XP dari hasil minigame; mengisi result.xp (XP cabang utama). Mengembalikan [{branch, level, xp}].
func award(result: MinigameResult) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rules: Dictionary = XP_RULES.get(result.kind, {})
	var base: float = float(Grade.base_xp(result.grade)) * (1.0 + 0.25 * float(maxi(0, result.difficulty - 1)))
	var main_set: bool = false
	for b in rules.keys():
		var amount: int = int(roundf(base * float(rules[b])))
		var gained: int = add_xp(String(b), amount)
		if not main_set:
			result.xp = amount
			main_set = true
		out.append({"branch": String(b), "xp": amount, "level": level(String(b)), "levels_gained": gained})
	return out


func learn_plant(plant_id: String) -> bool:
	if known_plants.has(plant_id):
		return false
	known_plants.append(plant_id)
	return true


func knows_plant(plant_id: String) -> bool:
	return known_plants.has(plant_id)


func to_dict() -> Dictionary:
	return {"xp": xp.duplicate(), "known_plants": known_plants.duplicate()}


func from_dict(d: Dictionary) -> void:
	var src: Dictionary = d.get("xp", {})
	for b in SkillDb.BRANCHES:
		xp[b] = int(src.get(b, 0))
	known_plants.clear()
	for p in d.get("known_plants", []):
		known_plants.append(String(p))
