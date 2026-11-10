class_name DiagnosisSystem
extends RefCounted
## Logika minigame diagnosis (murni, dites unit). Pemain mengumpulkan petunjuk dengan tenaga periksa
## terbatas (dahi, mata, lidah, kulit, perut, dan denyut nadi lewat uji ritme), lalu menetapkan diagnosis
## dari penyakit-penyakit yang cocok dengan keluhan. Nilai: ketepatan, relevansi pemeriksaan,
## kelengkapan bukti, dan waktu (kecil). Seluruh penyakit fiktif.

enum Phase { PERIKSA, SELESAI }

const MAX_GUESSES: int = 2
const PULSE_MIN_ACCURACY: float = 0.45
const PULSE_BEATS: int = 6
const PAR_TIME: float = 70.0
const LIMIT_TIME: float = 200.0
const WEIGHTS: Dictionary = {"ketepatan": 0.45, "relevansi": 0.20, "kelengkapan": 0.25, "waktu": 0.10}

## Tempo denyut per jenis nadi (detik antar ketukan; "bergelombang" bergantian).
const PULSE_GAPS: Dictionary = {
	"cepat": [0.55], "lambat": [1.15], "kuat": [0.85], "lemah": [0.85], "bergelombang": [0.6, 1.0],
}

var true_ailment: String = ""
var complaint_id: String = ""
var skill_level: int = 1
var candidates: Array[String] = []
var findings: Dictionary = {}          # area -> nilai terbaca
var inspected: Array[String] = []      # urutan pemeriksaan sukses
var energy_max: int = 4
var energy_left: int = 4
var wasted: int = 0                    # pemeriksaan yang tidak menyingkirkan kandidat/gagal
var failed_pulses: int = 0
var guesses: Array[String] = []
var errors: int = 0
var elapsed: float = 0.0
var phase: int = Phase.PERIKSA
var observed: bool = false
var observed_area: String = ""
var result: MinigameResult = null
var chosen: String = ""

var _seed: int = 0


func setup(p_ailment_id: String, p_complaint_id: String, p_skill_level: int, p_seed: int = 0) -> void:
	true_ailment = p_ailment_id
	complaint_id = p_complaint_id
	skill_level = clampi(p_skill_level, 1, SkillDb.MAX_LEVEL)
	_seed = p_seed
	candidates = AilmentDb.candidates_for(p_complaint_id)
	if not candidates.has(p_ailment_id):
		candidates.append(p_ailment_id)
	energy_max = int(SkillDb.effect("diagnosis", "energi", skill_level))
	energy_left = energy_max


func update(delta: float) -> void:
	if phase == Phase.PERIKSA:
		elapsed += delta


func pulse_window_scale() -> float:
	return SkillDb.effect("diagnosis", "jendela_nadi", skill_level)


func helper_marks() -> bool:
	return SkillDb.effect("diagnosis", "tanda_bantu", skill_level) >= 1.0


## Kandidat yang masih konsisten dengan semua temuan terkumpul.
func remaining() -> Array[String]:
	var out: Array[String] = []
	for c in candidates:
		if guesses.has(c):
			continue
		var ok: bool = true
		for area in findings.keys():
			if AilmentDb.finding(c, String(area)) != String(findings[area]):
				ok = false
				break
		if ok:
			out.append(c)
	return out


## "Amati pasien": satu temuan gratis dari area yang tampak (mata/kulit), dipilih yang paling LEMAH
## menyingkirkan kandidat agar petunjuk gratis tidak langsung memecahkan kasus. Sekali per sesi.
func observe() -> Dictionary:
	if observed or phase != Phase.PERIKSA:
		return {"ok": false}
	observed = true
	var areas: Array[String] = AilmentDb.VISIBLE_AREAS
	var start: int = absi(_seed) % areas.size()
	var area: String = areas[start]
	var best_left: int = -1
	for k in range(areas.size()):
		var a2: String = areas[(start + k) % areas.size()]
		var left: int = _left_after(a2)
		if left > best_left:
			best_left = left
			area = a2
	observed_area = area
	findings[area] = AilmentDb.finding(true_ailment, area)
	return {"ok": true, "area": area, "value": String(findings[area])}


## Jumlah kandidat tersisa bila `area` diungkap dengan nilai penyakit sebenarnya.
func _left_after(area: String) -> int:
	var value: String = AilmentDb.finding(true_ailment, area)
	var n: int = 0
	for c in remaining():
		if AilmentDb.finding(c, area) == value:
			n += 1
	return n


func _discriminates(area: String) -> bool:
	var rem: Array[String] = remaining()
	var seen: Dictionary = {}
	for c in rem:
		seen[AilmentDb.finding(c, area)] = true
	return seen.size() > 1


## Periksa satu area non-nadi. Biaya 1 tenaga. Mengembalikan {ok, area, value, informative}.
func inspect(area: String) -> Dictionary:
	if phase != Phase.PERIKSA or energy_left <= 0 or area == AilmentDb.PULSE_AREA \
			or not AilmentDb.AREAS.has(area) or findings.has(area):
		return {"ok": false}
	energy_left -= 1
	return _reveal(area)


## Hasil uji nadi (akurasi ketukan 0..1). Biaya 1 tenaga. Di bawah ambang -> nadi tidak terbaca.
func inspect_pulse(accuracy: float) -> Dictionary:
	if phase != Phase.PERIKSA or energy_left <= 0 or findings.has(AilmentDb.PULSE_AREA):
		return {"ok": false}
	energy_left -= 1
	if accuracy < PULSE_MIN_ACCURACY:
		failed_pulses += 1
		wasted += 1
		return {"ok": true, "area": AilmentDb.PULSE_AREA, "value": "", "informative": false, "readable": false}
	return _reveal(AilmentDb.PULSE_AREA)


func _reveal(area: String) -> Dictionary:
	var before: int = remaining().size()
	var value: String = AilmentDb.finding(true_ailment, area)
	findings[area] = value
	inspected.append(area)
	var after: int = remaining().size()
	var informative: bool = after < before
	if not informative:
		wasted += 1
	return {"ok": true, "area": area, "value": value, "informative": informative, "readable": true}


## Selang waktu ketukan nadi untuk penyakit sebenarnya (daftar waktu mulai dari `lead` detik).
func pulse_beats(lead: float = 1.2) -> Array[float]:
	return pulse_beats_for(AilmentDb.finding(true_ailment, AilmentDb.PULSE_AREA), lead)


static func pulse_beats_for(pulse_value: String, lead: float = 1.2) -> Array[float]:
	var gaps: Array = PULSE_GAPS.get(pulse_value, [0.85])
	var out: Array[float] = []
	var t: float = lead
	for i in range(PULSE_BEATS):
		out.append(t)
		t += float(gaps[i % gaps.size()])
	return out


func can_submit() -> bool:
	return phase == Phase.PERIKSA and (not inspected.is_empty() or observed)


## Tetapkan diagnosis. Benar -> selesai. Salah -> kesalahan; setelah MAX_GUESSES salah -> selesai gagal.
## Mengembalikan {correct, finished}.
func submit(ailment_id: String) -> Dictionary:
	if phase != Phase.PERIKSA or not candidates.has(ailment_id) or guesses.has(ailment_id):
		return {"correct": false, "finished": false, "ok": false}
	var determined: bool = remaining().size() <= 1
	guesses.append(ailment_id)
	if ailment_id == true_ailment:
		chosen = ailment_id
		_finish(determined)
		return {"ok": true, "correct": true, "finished": true}
	errors += 1
	if guesses.size() >= MAX_GUESSES or remaining().is_empty():
		chosen = ailment_id
		_finish(determined)
		return {"ok": true, "correct": false, "finished": true}
	return {"ok": true, "correct": false, "finished": false}


func _finish(determined: bool) -> void:
	phase = Phase.SELESAI
	var correct: bool = chosen == true_ailment
	var n_checks: int = inspected.size() + failed_pulses
	var informative_checks: int = maxi(0, inspected.size() - (wasted - failed_pulses))
	var relevance: float = 0.0
	if n_checks > 0:
		relevance = clampf(float(informative_checks) / float(n_checks), 0.0, 1.0)
	elif determined and observed:
		relevance = 1.0
	var accuracy: float = 0.0
	if correct:
		accuracy = 1.0 if guesses.size() == 1 else 0.6
	var completeness: float = 1.0 if determined else (0.45 if not findings.is_empty() else 0.0)
	var comps: Dictionary = {
		"ketepatan": accuracy, "relevansi": relevance, "kelengkapan": completeness,
		"waktu": ScoringSystem.time_factor(elapsed, PAR_TIME, LIMIT_TIME),
	}
	var cap: int = -1
	if not correct:
		cap = Grade.Level.D
	elif guesses.size() > 1 or not determined:
		cap = Grade.Level.B
	result = ScoringSystem.make_result("diagnosis", true_ailment, comps, WEIGHTS, errors, elapsed,
			AilmentDb.difficulty(true_ailment), cap)
	result.details = {"chosen": chosen, "correct": correct, "guesses": guesses.duplicate(),
		"inspected": inspected.duplicate(), "findings": findings.duplicate(), "determined": determined}


func is_finished() -> bool:
	return phase == Phase.SELESAI


## Tanda bantu untuk baris kandidat pada area terkumpul: 1 cocok, -1 bertentangan, 0 tak diketahui.
func mark(candidate: String, area: String) -> int:
	if not findings.has(area):
		return 0
	return 1 if AilmentDb.finding(candidate, area) == String(findings[area]) else -1
