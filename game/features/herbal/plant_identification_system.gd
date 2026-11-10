class_name PlantIdentificationSystem
extends RefCounted
## Logika minigame identifikasi tanaman (murni, dites unit). Pemain mengamati bagian tanaman (daun, bunga,
## akar, buah) lalu memilih identitasnya dari beberapa pilihan. Kesulitan naik bersama skill identifikasi:
## lebih banyak pilihan, pengecoh yang mirip, dan bagian tanaman yang tidak terlihat (tertutup).
## Berhasil -> pengetahuan herbal + panen bahan (jumlah menurut tingkat).

enum Phase { AMATI, SELESAI }

const MAX_GUESSES: int = 2
const WEIGHTS: Dictionary = {"ketepatan": 0.50, "pengamatan": 0.25, "kesalahan": 0.15, "waktu": 0.10}
const HARVEST: Array[int] = [0, 1, 2, 3, 3]  # indeks = Grade.Level

var plant_id: String = ""
var skill_level: int = 1
var options: Array[String] = []
var hidden_parts: Array[String] = []
var observed: Array[String] = []
var guesses: Array[String] = []
var errors: int = 0
var elapsed: float = 0.0
var phase: int = Phase.AMATI
var result: MinigameResult = null
var harvest: int = 0


func setup(p_plant_id: String, p_skill_level: int, p_seed: int = 0) -> void:
	plant_id = p_plant_id
	skill_level = clampi(p_skill_level, 1, SkillDb.MAX_LEVEL)
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed * 131 + 17
	var n_opt: int = int(SkillDb.effect("identifikasi_tanaman", "pilihan", skill_level))
	var n_similar: int = int(SkillDb.effect("identifikasi_tanaman", "mirip", skill_level))
	var n_hidden: int = int(SkillDb.effect("identifikasi_tanaman", "tertutup", skill_level))
	options = _pick_options(rng, n_opt, n_similar)
	hidden_parts = _pick_hidden(rng, n_hidden)


func _pick_options(rng: RandomNumberGenerator, n_opt: int, n_similar: int) -> Array[String]:
	var others: Array[String] = []
	for id in HerbDb.IDS:
		if id != plant_id:
			others.append(id)
	# Urutkan pengecoh berdasarkan kemiripan (menurun), tie-break acak deterministik.
	var keyed: Array = []
	for o in others:
		keyed.append({"id": o, "sim": HerbDb.shared_traits(plant_id, o), "r": rng.randf()})
	keyed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["sim"] != b["sim"]:
			return int(a["sim"]) > int(b["sim"])
		return float(a["r"]) < float(b["r"]))
	var chosen: Array[String] = [plant_id]
	for k in range(mini(n_similar, keyed.size())):
		chosen.append(String(keyed[k]["id"]))
	var rest: Array = []
	for e in keyed:
		if not chosen.has(String(e["id"])):
			rest.append(String(e["id"]))
	while chosen.size() < n_opt and not rest.is_empty():
		var i: int = rng.randi() % rest.size()
		chosen.append(String(rest[i]))
		rest.remove_at(i)
	# Kocok urutan tampil.
	for i in range(chosen.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = chosen[i]
		chosen[i] = chosen[j]
		chosen[j] = tmp
	return chosen


## Pilih bagian tertutup; pastikan tanaman tetap bisa dibedakan dari semua pilihan dengan bagian yang tersisa.
func _pick_hidden(rng: RandomNumberGenerator, n_hidden: int) -> Array[String]:
	var parts: Array[String] = HerbDb.PARTS.duplicate()
	var out: Array[String] = []
	for k in range(n_hidden):
		var cand: Array[String] = []
		for p in parts:
			if not out.has(p):
				cand.append(p)
		if cand.size() <= 2:
			break
		var tries: int = 0
		while tries < 6 and not cand.is_empty():
			var pick: String = cand[rng.randi() % cand.size()]
			var visible: Array = []
			for p in parts:
				if p != pick and not out.has(p):
					visible.append(p)
			if HerbDb.is_unique_among(plant_id, options, visible):
				out.append(pick)
				break
			cand.erase(pick)
			tries += 1
	return out


func update(delta: float) -> void:
	if phase == Phase.AMATI:
		elapsed += delta


func visible_parts() -> Array[String]:
	var out: Array[String] = []
	for p in HerbDb.PARTS:
		if not hidden_parts.has(p):
			out.append(p)
	return out


func is_hidden(part: String) -> bool:
	return hidden_parts.has(part)


## Amati satu bagian; mengembalikan kunci cirinya, atau "" bila tertutup/tak valid.
func observe(part: String) -> String:
	if phase != Phase.AMATI or not HerbDb.PARTS.has(part) or hidden_parts.has(part):
		return ""
	if not observed.has(part):
		observed.append(part)
	return HerbDb.trait_of(plant_id, part)


## Bagian yang diamati cukup untuk membedakan tanaman dari semua pilihan?
func evidence_sufficient() -> bool:
	return HerbDb.is_unique_among(plant_id, options, observed)


func eliminated(option_id: String) -> bool:
	return guesses.has(option_id)


func guess(option_id: String) -> Dictionary:
	if phase != Phase.AMATI or not options.has(option_id) or guesses.has(option_id):
		return {"ok": false, "correct": false, "finished": false}
	var sufficient: bool = evidence_sufficient()
	guesses.append(option_id)
	if option_id == plant_id:
		_finish(true, sufficient)
		return {"ok": true, "correct": true, "finished": true}
	errors += 1
	if guesses.size() >= MAX_GUESSES:
		_finish(false, sufficient)
		return {"ok": true, "correct": false, "finished": true}
	return {"ok": true, "correct": false, "finished": false}


func _finish(correct: bool, sufficient: bool) -> void:
	phase = Phase.SELESAI
	var acc: float = 0.0
	if correct:
		acc = 1.0 if guesses.size() == 1 else 0.55
	var obs: float = 1.0 if sufficient else clampf(0.2 + 0.2 * float(observed.size()), 0.0, 0.8)
	var comps: Dictionary = {
		"ketepatan": acc, "pengamatan": obs,
		"kesalahan": ScoringSystem.error_factor(errors, 0.4),
		"waktu": ScoringSystem.time_factor(elapsed, 20.0, 90.0),
	}
	var cap: int = -1
	if not correct:
		cap = Grade.Level.D
	elif not sufficient:
		cap = Grade.Level.B
	var diff: int = 1 + int(float(skill_level - 1) / 2.0)
	result = ScoringSystem.make_result("identifikasi", plant_id, comps, WEIGHTS, errors, elapsed, diff, cap)
	harvest = HARVEST[result.grade] if correct else 0
	result.details = {"correct": correct, "guesses": guesses.duplicate(), "observed": observed.duplicate(),
		"harvest": harvest, "options": options.duplicate()}


func is_finished() -> bool:
	return phase == Phase.SELESAI


func succeeded() -> bool:
	return result != null and bool(result.details.get("correct", false))
