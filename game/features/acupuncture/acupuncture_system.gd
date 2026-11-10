class_name AcupunctureSystem
extends RefCounted
## Logika minigame akupunktur FIKTIF (murni, dites unit). Fase PILIH: pemain memilih titik (urutan pilihan =
## urutan penusukan). Fase JARUM: tiap titik ditusuk dengan presisi: ujung jarum digeser (bergetar) ke
## sasaran dan kedalaman dihentikan di zona hijau. Nilai: ketepatan, kelengkapan, urutan, kesalahan, waktu.
## Koordinat bidang jarum ternormalisasi: sasaran di (0,0), bidang [-1,1]^2.

enum Phase { PILIH, JARUM, SELESAI }

const MAX_POINTS: int = 5
const BULLSEYE: float = 0.35     # jarak (dalam radius) yang dihitung tepat sempurna
const MAX_MISS: float = 1.6      # jarak (dalam radius) skor posisi 0
const DEPTH_CENTER: float = 0.62
const DEPTH_HALF: float = 0.13
const DEPTH_FALLOFF: float = 0.35
const WEIGHTS: Dictionary = {"ketepatan": 0.30, "kelengkapan": 0.25, "urutan": 0.15, "kesalahan": 0.20, "waktu": 0.10}

var ailment_id: String = ""        # penyakit sebenarnya (menentukan rencana yang benar)
var hint_ailment_id: String = ""   # penyakit hasil diagnosis (menentukan catatan petunjuk)
var skill_level: int = 1
var difficulty: int = 1
var plan: Array[String] = []
var selected: Array[String] = []
var phase: int = Phase.PILIH
var cursor: int = 0
var insertions: Array[Dictionary] = []
var elapsed: float = 0.0
var point_time: float = 0.0
var result: MinigameResult = null

var _ph: Array[float] = [0.0, 0.0, 0.0, 0.0]


func setup(p_ailment: String, p_hint_ailment: String, p_skill_level: int, p_seed: int = 0) -> void:
	ailment_id = p_ailment
	hint_ailment_id = p_hint_ailment if p_hint_ailment != "" else p_ailment
	skill_level = clampi(p_skill_level, 1, SkillDb.MAX_LEVEL)
	difficulty = AilmentDb.difficulty(p_ailment)
	plan = AilmentDb.acu_plan(p_ailment)
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed * 31 + 7
	for i in range(_ph.size()):
		_ph[i] = rng.randf_range(0.0, TAU)


## Petunjuk yang dilihat pemain: urutan tag fungsi dari rencana penyakit hasil diagnosis.
func hint_tags() -> Array[String]:
	var out: Array[String] = []
	for p in AilmentDb.acu_plan(hint_ailment_id):
		out.append(AcupointDb.tag(p))
	return out


func update(delta: float) -> void:
	if phase == Phase.SELESAI:
		return
	elapsed += delta
	if phase == Phase.JARUM:
		point_time += delta


func toggle_point(id: String) -> bool:
	if phase != Phase.PILIH or not AcupointDb.has(id):
		return false
	if selected.has(id):
		selected.erase(id)
		return true
	if selected.size() >= MAX_POINTS:
		return false
	selected.append(id)
	return true


func begin_insertion() -> bool:
	if phase != Phase.PILIH or selected.is_empty():
		return false
	phase = Phase.JARUM
	cursor = 0
	point_time = 0.0
	return true


func current_point() -> String:
	if phase != Phase.JARUM or cursor >= selected.size():
		return ""
	return selected[cursor]


func is_plan_point(id: String) -> bool:
	return plan.has(id)


# --- Parameter presisi (dipengaruhi kesulitan dan skill) --------------------

func target_radius() -> float:
	var base: float = 0.26 - 0.03 * float(difficulty - 1)
	return base * SkillDb.effect("akupunktur", "radius", skill_level)


func tremor_amplitude() -> float:
	var base: float = 0.05 + 0.025 * float(difficulty)
	return base * SkillDb.effect("akupunktur", "getar", skill_level)


## Geseran getaran ujung jarum pada waktu `t` (detik sejak titik dimulai), deterministik.
func tremor_offset(t: float) -> Vector2:
	var a: float = tremor_amplitude()
	return Vector2(sin(1.7 * t + _ph[0]) + 0.5 * sin(3.1 * t + _ph[1]),
		cos(1.3 * t + _ph[2]) + 0.5 * sin(2.7 * t + _ph[3])) * a * 0.66


func depth_period() -> float:
	return 2.4 - 0.25 * float(difficulty - 1)


## Penanda kedalaman bolak-balik 0..1 (segitiga) pada waktu `t`.
func depth_at(t: float) -> float:
	var p: float = depth_period()
	var x: float = fposmod(t, p) / p
	return 1.0 - absf(2.0 * x - 1.0)


func depth_half_width() -> float:
	return DEPTH_HALF * SkillDb.effect("akupunktur", "kedalaman", skill_level)


## Posisi ujung jarum yang tampil = posisi geser pemain + getaran.
func tip_position(player_pos: Vector2, t: float) -> Vector2:
	return player_pos + tremor_offset(t)


## Skor satu penusukan: `tip` dalam koordinat bidang jarum, `depth` 0..1. Mengembalikan {pos, depth, score}.
func score_insertion(tip: Vector2, depth: float) -> Dictionary:
	var dist: float = tip.length() / maxf(0.0001, target_radius())
	var pos_s: float = 1.0
	if dist > BULLSEYE:
		pos_s = clampf(1.0 - (dist - BULLSEYE) / (MAX_MISS - BULLSEYE), 0.0, 1.0)
	var dd: float = maxf(0.0, absf(depth - DEPTH_CENTER) - depth_half_width())
	var depth_s: float = clampf(1.0 - dd / DEPTH_FALLOFF, 0.0, 1.0)
	return {"pos": pos_s, "depth": depth_s, "score": 0.65 * pos_s + 0.35 * depth_s}


## Tusuk titik saat ini pada posisi ujung `tip` dan kedalaman `depth`. Maju ke titik berikutnya / selesai.
func insert(tip: Vector2, depth: float) -> Dictionary:
	if phase != Phase.JARUM:
		return {"ok": false}
	var id: String = selected[cursor]
	var s: Dictionary = score_insertion(tip, depth)
	var rec: Dictionary = {"point": id, "pos": s["pos"], "depth": s["depth"], "score": s["score"], "in_plan": plan.has(id)}
	insertions.append(rec)
	cursor += 1
	point_time = 0.0
	if cursor >= selected.size():
		_finish()
	rec["ok"] = true
	rec["finished"] = phase == Phase.SELESAI
	return rec


## Akhiri sesi lebih awal (titik yang belum ditusuk dihitung tidak dikerjakan).
func finish_early() -> void:
	if phase == Phase.JARUM:
		_finish()


func _finish() -> void:
	phase = Phase.SELESAI
	var plan_hits: Array[String] = []
	var prec_sum: float = 0.0
	var wrong: int = 0
	for rec in insertions:
		var pid: String = String(rec["point"])
		if plan.has(pid):
			plan_hits.append(pid)
			prec_sum += float(rec["score"])
		else:
			wrong += 1
	var inserted_ids: Array = []
	for rec in insertions:
		inserted_ids.append(rec["point"])
	var coverage: float = float(plan_hits.size()) / float(maxi(1, plan.size()))
	var precision: float = prec_sum / float(maxi(1, plan.size()))   # titik yang tak ditusuk = 0
	# Titik terpilih tapi belum sempat ditusuk (sesi diakhiri lebih awal) tidak dianggap kesalahan.
	var order: float = ScoringSystem.order_factor(plan, inserted_ids)
	var comps: Dictionary = {
		"ketepatan": precision, "kelengkapan": coverage, "urutan": order,
		"kesalahan": ScoringSystem.error_factor(wrong, 0.25),
		"waktu": ScoringSystem.time_factor(elapsed, 20.0 + 12.0 * float(plan.size()), 120.0 + 40.0 * float(plan.size())),
	}
	var cap: int = -1
	if plan_hits.is_empty():
		cap = Grade.Level.D
	elif coverage < 0.5:
		cap = Grade.Level.C
	result = ScoringSystem.make_result("akupunktur", ailment_id, comps, WEIGHTS, wrong, elapsed, difficulty, cap)
	result.details = {"plan": plan.duplicate(), "selected": selected.duplicate(), "insertions": insertions.duplicate(true)}


func is_finished() -> bool:
	return phase == Phase.SELESAI
