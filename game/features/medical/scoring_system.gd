class_name ScoringSystem
extends RefCounted
## Sistem penilaian minigame (logika murni, dites unit). Skor = jumlah berbobot dari komponen 0..1:
## ketepatan, urutan tindakan, kesalahan, kesesuaian dengan kebutuhan pasien, dan (kecil) waktu.
## Waktu TIDAK PERNAH menjadi penentu tunggal: bobotnya dibatasi MAX_TIME_WEIGHT dan faktor waktu
## tidak turun di bawah TIME_FLOOR.

const MAX_TIME_WEIGHT: float = 0.15
const TIME_FLOOR: float = 0.35
const TIME_KEY: String = "waktu"


## Gabungkan komponen (0..1) dengan bobot menjadi skor 0..100. Komponen tanpa bobot diabaikan.
static func compose(components: Dictionary, weights: Dictionary) -> float:
	var total: float = 0.0
	for k in weights.keys():
		total += maxf(0.0, float(weights[k]))
	if total <= 0.0:
		return 0.0
	var norm: Dictionary = {}
	for k in weights.keys():
		norm[k] = maxf(0.0, float(weights[k])) / total
	if norm.has(TIME_KEY) and float(norm[TIME_KEY]) > MAX_TIME_WEIGHT:
		var excess: float = float(norm[TIME_KEY]) - MAX_TIME_WEIGHT
		var others: float = 1.0 - float(norm[TIME_KEY])
		norm[TIME_KEY] = MAX_TIME_WEIGHT
		for k in norm.keys():
			if k != TIME_KEY:
				norm[k] = float(norm[k]) + (excess * float(norm[k]) / others if others > 0.0 else 0.0)
	var s: float = 0.0
	for k in norm.keys():
		var c: float = clampf(float(components.get(k, 0.0)), 0.0, 1.0)
		s += c * float(norm[k])
	return clampf(s * 100.0, 0.0, 100.0)


## 1.0 bila selesai dalam `par` detik; menurun linear sampai TIME_FLOOR pada `limit` detik.
static func time_factor(elapsed: float, par: float, limit: float) -> float:
	if elapsed <= par or limit <= par:
		return 1.0
	var f: float = 1.0 - (elapsed - par) / (limit - par) * (1.0 - TIME_FLOOR)
	return clampf(f, TIME_FLOOR, 1.0)


static func error_factor(errors: int, penalty: float) -> float:
	return clampf(1.0 - float(errors) * penalty, 0.0, 1.0)


## Kesesuaian urutan: pasangan item bersama yang urutannya sama / seluruh pasangan. 1.0 bila < 2 item bersama.
static func order_factor(expected: Array, actual: Array) -> float:
	var shared: Array = []
	for a in actual:
		if expected.has(a) and not shared.has(a):
			shared.append(a)
	if shared.size() < 2:
		return 1.0
	var ok: int = 0
	var total: int = 0
	for i in range(shared.size()):
		for j in range(i + 1, shared.size()):
			total += 1
			if expected.find(shared[i]) < expected.find(shared[j]):
				ok += 1
	return float(ok) / float(total)


## Bangun MinigameResult. `cap` (>= 0) membatasi tingkat tertinggi (mis. diagnosis salah -> maksimal D).
static func make_result(kind: String, subject_id: String, components: Dictionary, weights: Dictionary,
		errors: int, duration: float, difficulty: int = 1, cap: int = -1) -> MinigameResult:
	var r := MinigameResult.new()
	r.kind = kind
	r.subject_id = subject_id
	r.components = components.duplicate()
	r.errors = errors
	r.duration = duration
	r.difficulty = difficulty
	r.score = compose(components, weights)
	r.grade = Grade.from_score(r.score)
	if cap >= 0 and r.grade > cap:
		r.grade = cap
	return r
