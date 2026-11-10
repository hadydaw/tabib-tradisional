class_name TreatmentManager
extends RefCounted
## Pengelola alur pengobatan (logika murni, dites unit), terintegrasi dengan PatientSystem Fase 4:
## pasien di ruang periksa -> diagnosis (minigame) -> pilih metode -> akupunktur dan/atau ramuan (minigame)
## -> hasil (kualitas, kepuasan, biaya, reputasi, XP) -> pasien pulang lewat PatientSystem.finish_exam().
## Hasil pengobatan sepenuhnya ditentukan performa pemain di minigame.

signal stage_changed(patient_id: String, stage: int)
signal visit_completed(patient: PatientRecord, summary: Dictionary)

const METHOD_ACU: String = "akupunktur"
const METHOD_HERB: String = "herbal"
const CURE_QUALITY: float = 0.60
const IMPROVE_QUALITY: float = 0.35
const DIAG_WEIGHT: float = 0.25

var patients: PatientSystem
var skills: SkillProgressionSystem
var inventory: HerbInventory
var stats: ClinicStats
var sessions: Dictionary = {}   # id pasien -> TreatmentSession


func setup(p_patients: PatientSystem, p_skills: SkillProgressionSystem, p_inventory: HerbInventory, p_stats: ClinicStats) -> void:
	patients = p_patients
	skills = p_skills
	inventory = p_inventory
	stats = p_stats
	patients.patient_event.connect(_on_patient_event)


func _on_patient_event(kind: String, p: PatientRecord) -> void:
	if kind == "gave_up" or kind == "left":
		sessions.erase(p.id)


## Pasien yang sedang di ruang periksa dan siap ditangani (null bila tidak ada).
func exam_patient() -> PatientRecord:
	var p: PatientRecord = patients.queue.exam_patient()
	if p != null and p.state == PatientRecord.State.DIPERIKSA:
		return p
	return null


func session_for(p: PatientRecord) -> TreatmentSession:
	if sessions.has(p.id):
		return sessions[p.id]
	var s := TreatmentSession.new()
	s.patient_id = p.id
	s.true_ailment = AilmentDb.pick_for(p.complaint_id, absi(p.id.hash()) + patients.clock.day * 7)
	sessions[p.id] = s
	return s


func _set_stage(s: TreatmentSession, stage: int) -> void:
	s.stage = stage
	stage_changed.emit(s.patient_id, stage)


# --- Diagnosis --------------------------------------------------------------

func begin_diagnosis(p: PatientRecord) -> DiagnosisSystem:
	var s: TreatmentSession = session_for(p)
	if s.stage != TreatmentSession.Stage.DIAGNOSIS:
		return null
	s.diagnosis_attempts += 1
	var d := DiagnosisSystem.new()
	d.setup(s.true_ailment, p.complaint_id, skills.level("diagnosis"), absi(p.id.hash()) + s.diagnosis_attempts)
	return d


func complete_diagnosis(p: PatientRecord, d: DiagnosisSystem) -> Array[Dictionary]:
	var s: TreatmentSession = session_for(p)
	if d == null or not d.is_finished() or s.stage != TreatmentSession.Stage.DIAGNOSIS:
		return []
	s.diagnosed_id = d.chosen
	s.results["diagnosis"] = d.result
	var awards: Array[Dictionary] = skills.award(d.result)
	p.diagnosis.diagnosis_id = d.chosen
	p.diagnosis.findings.clear()
	for area in d.findings.keys():
		p.diagnosis.findings.append("%s=%s" % [area, d.findings[area]])
	_set_stage(s, TreatmentSession.Stage.METODE)
	return awards


# --- Metode -----------------------------------------------------------------

## Pilih metode ("akupunktur", "herbal", atau keduanya). Tidak valid / kosong -> false.
func choose_methods(p: PatientRecord, methods: Array[String]) -> bool:
	var s: TreatmentSession = session_for(p)
	if s.stage != TreatmentSession.Stage.METODE or methods.is_empty():
		return false
	var chosen: Array[String] = []
	for m in [METHOD_ACU, METHOD_HERB]:   # urutan tetap: akupunktur lalu ramuan
		if methods.has(m):
			chosen.append(m)
	if chosen.is_empty():
		return false
	s.methods = chosen
	_advance(p)
	return true


func _advance(p: PatientRecord) -> void:
	var s: TreatmentSession = session_for(p)
	var pending: Array[String] = s.pending_methods()
	if pending.is_empty():
		_set_stage(s, TreatmentSession.Stage.HASIL)
		return
	_set_stage(s, TreatmentSession.Stage.AKUPUNKTUR if pending[0] == METHOD_ACU else TreatmentSession.Stage.RAMUAN)


# --- Akupunktur -------------------------------------------------------------

func begin_acupuncture(p: PatientRecord) -> AcupunctureSystem:
	var s: TreatmentSession = session_for(p)
	if s.stage != TreatmentSession.Stage.AKUPUNKTUR:
		return null
	var a := AcupunctureSystem.new()
	a.setup(s.true_ailment, s.diagnosed_id, skills.level("akupunktur"), absi(p.id.hash()) + 3)
	return a


func complete_acupuncture(p: PatientRecord, a: AcupunctureSystem) -> Array[Dictionary]:
	var s: TreatmentSession = session_for(p)
	if a == null or not a.is_finished() or s.stage != TreatmentSession.Stage.AKUPUNKTUR:
		return []
	s.results[METHOD_ACU] = a.result
	s.done_methods.append(METHOD_ACU)
	var awards: Array[Dictionary] = skills.award(a.result)
	var tr := TreatmentRecord.new()
	tr.id = "%s_akupunktur" % p.id
	tr.kind = METHOD_ACU
	tr.item_ids = a.selected.duplicate()
	tr.status = "selesai"
	p.diagnosis.treatments.append(tr)
	_advance(p)
	return awards


# --- Ramuan -----------------------------------------------------------------

## Resep yang terbuka menurut tingkat Pengetahuan Herbal.
func recipes_available() -> Array[String]:
	return RecipeDb.unlocked(skills.level("pengetahuan_herbal"))


func begin_crafting(p: PatientRecord, recipe_id: String) -> HerbalCraftingSystem:
	var s: TreatmentSession = session_for(p)
	if s.stage != TreatmentSession.Stage.RAMUAN or not recipes_available().has(recipe_id):
		return null
	var h := HerbalCraftingSystem.new()
	h.setup(recipe_id, inventory, skills.level("pengetahuan_herbal"), skills.level("peracikan"))
	s.recipe_id = recipe_id
	return h


func complete_crafting(p: PatientRecord, h: HerbalCraftingSystem) -> Array[Dictionary]:
	var s: TreatmentSession = session_for(p)
	if h == null or not h.is_finished() or s.stage != TreatmentSession.Stage.RAMUAN:
		return []
	s.results[METHOD_HERB] = h.result
	s.done_methods.append(METHOD_HERB)
	var awards: Array[Dictionary] = skills.award(h.result)
	var tr := TreatmentRecord.new()
	tr.id = "%s_ramuan" % p.id
	tr.kind = METHOD_HERB
	tr.item_ids = [h.recipe_id]
	tr.status = "selesai"
	p.diagnosis.treatments.append(tr)
	_advance(p)
	return awards


# --- Hasil ------------------------------------------------------------------

## Kualitas satu metode: kecocokan metode x skor minigame (0..1).
func method_quality(s: TreatmentSession, method: String) -> float:
	var r: MinigameResult = s.results.get(method, null)
	if r == null:
		return 0.0
	var fit: float = AilmentDb.acu_fit(s.true_ailment) if method == METHOD_ACU \
			else RecipeDb.fit_for(s.recipe_id, s.true_ailment)
	return clampf(fit * r.score / 100.0, 0.0, 1.0)


func treatment_quality(s: TreatmentSession) -> float:
	var rest: float = 1.0
	var any: bool = false
	for m in s.done_methods:
		rest *= 1.0 - method_quality(s, m)
		any = true
	return (1.0 - rest) if any else 0.0


static func outcome_for(quality: float) -> String:
	if quality >= CURE_QUALITY:
		return "sembuh"
	if quality >= IMPROVE_QUALITY:
		return "membaik"
	return "gagal"


## Selesaikan kunjungan: hitung hasil, catat statistik klinik, dan pasien pulang. Null bila belum waktunya.
func finalize(p: PatientRecord) -> Dictionary:
	var s: TreatmentSession = session_for(p)
	if s.stage != TreatmentSession.Stage.HASIL:
		return {}
	var quality: float = treatment_quality(s)
	var outcome: String = outcome_for(quality)
	var diag: MinigameResult = s.results.get("diagnosis", null)
	var diag_score: float = diag.score if diag != null else 0.0
	var visit_score: float = DIAG_WEIGHT * diag_score + (1.0 - DIAG_WEIGHT) * quality * 100.0
	var grade: int = Grade.from_score(visit_score)
	var waited: float = 0.0
	if p.waiting_since >= 0.0 and p.exam_started >= p.waiting_since:
		waited = p.exam_started - p.waiting_since
	var wait_penalty: float = clampf((waited - 30.0) / 6.0, 0.0, 25.0)
	var satisfaction: float = clampf(35.0 + 65.0 * quality - wait_penalty, 0.0, 100.0)
	var fee: int = ClinicStats.fee_for(AilmentDb.fee(s.true_ailment), quality, stats.reputation)
	var rep_before: float = stats.reputation
	var summary: Dictionary = {
		"patient_id": p.id, "npc_id": p.npc_id, "ailment_id": s.true_ailment, "diagnosed_id": s.diagnosed_id,
		"diagnosis_correct": s.diagnosed_id == s.true_ailment, "quality": quality, "outcome": outcome,
		"grade": grade, "visit_score": visit_score, "fee": fee, "satisfaction": satisfaction,
		"methods": s.done_methods.duplicate(), "recipe_id": s.recipe_id,
	}
	stats.record_visit(summary)
	summary["reputation_delta"] = stats.reputation - rep_before
	summary["reputation"] = stats.reputation
	summary["money"] = stats.money
	p.diagnosis.outcome = outcome
	s.summary = summary
	_set_stage(s, TreatmentSession.Stage.SELESAI)
	patients.finish_exam()
	visit_completed.emit(p, summary)
	return summary
