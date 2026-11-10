extends SceneTree
## Tes asap Fase 5 (headless): alur pengobatan LENGKAP lewat dunia + layar minigame nyata (tombol & sentuhan
## disimulasikan), tunda/lanjut, identifikasi tanaman di kebun, Buku Tabib, kunci kontrol dunia, jeda waktu.
## Tampilan dan rasa sentuhan sebenarnya hanya bisa dinilai di HP.
## Jalankan: godot --headless --path game -s res://tests/smoke/run_smoke_medical.gd

var _world: Node
var _steps: Array[Callable] = []
var _step_index: int = 0
var _frames: int = 0
var _fail: int = 0
var _count: int = 0
var _patient: PatientRecord


func _initialize() -> void:
	Locale.set_language("id")
	_world = (load("res://scenes/world/game_world.tscn") as PackedScene).instantiate()
	root.add_child(_world)
	_steps = [_step_bring_patient, _step_blocked_when_open, _step_postpone_resume, _step_diagnosis, _step_methods,
		_step_acupuncture, _step_crafting, _step_summary, _step_plant, _step_book, _step_second_patient_failures, _step_final]


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	if _step_index < _steps.size():
		_steps[_step_index].call()
		_step_index += 1
		return false
	print("Tes asap medis: %d pemeriksaan, gagal: %d" % [_count, _fail])
	quit(1 if _fail > 0 else 0)
	return true


func _check(condition: bool, name: String) -> void:
	_count += 1
	if condition:
		print("  OK   ", name)
	else:
		_fail += 1
		printerr("  GAGAL ", name)


func _mg() -> MinigameManager:
	return _world.get_minigames()


func _view() -> MinigameView:
	return _mg().current_view()


func _bring_to_exam(complaint_idx: int = 0) -> PatientRecord:
	var ps: PatientSystem = _world.get_patients()
	ps.auto_call = false
	ps.suppress_plan()
	_world.debug_set_time(_world.get_clock().day, 9, 0)
	_world.load_location("klinik", "dari_desa")
	var p: PatientRecord = null
	for id in NpcRoster.ids():
		if ps.patient_for(id) == null:
			p = ps.start_visit(id, ComplaintCatalog.IDS[complaint_idx])
			break
	var guard: int = 0
	while p.state != PatientRecord.State.MENUNGGU and guard < 4000:
		_world.step_world(0.5)
		guard += 1
	_world._interact_reception()
	guard = 0
	while p.state != PatientRecord.State.DIPERIKSA and guard < 1000:
		_world.step_world(0.5)
		guard += 1
	return p


func _step_bring_patient() -> void:
	_mg().transitions = false
	_check(_world.get_treatment() != null and _world.get_skills() != null and _world.get_inventory() != null, "sistem medis terpasang di dunia")
	_check(_world.get_inventory().total() > 0, "inventaris bahan awal terisi")
	_patient = _bring_to_exam(0)
	_check(_patient.state == PatientRecord.State.DIPERIKSA, "pasien siap di ruang periksa")
	_check(not _world.is_minigame_open() and not UiGate.blocked, "belum ada minigame terbuka")


func _step_blocked_when_open() -> void:
	var clock: GameClock = _world.get_clock()
	var t0: float = clock.minute()
	_world.interact_exam_bed()
	_check(_world.is_minigame_open() and _mg().kind() == "diagnosis", "tempat periksa membuka minigame diagnosis")
	_check(_view() is DiagnosisView, "tampilan diagnosis aktif")
	_check(UiGate.blocked, "kontrol dunia terkunci saat minigame")
	for i in range(40):
		_world.step_world(0.5)
	_check(absf(clock.minute() - t0) < 0.01, "waktu dunia berhenti selama minigame")
	_world.get_player().move_input = Vector2.ONE
	_world.poll_input()
	_check(_world.get_player().move_input == Vector2.ZERO, "pemain tidak bergerak saat minigame")
	var before: int = _view().button_ids().size()
	_check(before > 0, "tombol layar minigame terdaftar (%d)" % before)
	_check(not _world.press_interact(), "tombol interaksi dunia tidak aktif saat minigame")


func _step_postpone_resume() -> void:
	_check(_view().click_button("exit"), "tombol Tunda tersedia")
	_check(not _world.is_minigame_open() and not UiGate.blocked, "Tunda menutup layar & membuka kunci")
	var s: TreatmentSession = _world.get_treatment().session_for(_patient)
	_check(s.stage == TreatmentSession.Stage.DIAGNOSIS and _patient.state == PatientRecord.State.DIPERIKSA, "sesi tetap di tahap diagnosis; pasien menunggu")
	_world.interact_exam_bed()
	_check(_world.is_minigame_open() and _mg().kind() == "diagnosis", "lanjut kembali ke diagnosis")


func _drive_diagnosis(view: DiagnosisView, s: TreatmentSession, correct: bool) -> void:
	var d: DiagnosisSystem = view.sys
	view.click_button("observe")
	var guard: int = 0
	while d.remaining().size() > 1 and d.energy_left > 0 and guard < 10:
		guard += 1
		for area in AilmentDb.AREAS:
			if d.findings.has(area):
				continue
			var groups: Dictionary = {}
			for c in d.remaining():
				groups[AilmentDb.finding(c, area)] = true
			if groups.size() > 1:
				if area == AilmentDb.PULSE_AREA:
					view.inspect_area(area)
					for b in view._pulse_beats:
						view.pulse_tap_time(float(b))
					view.finish_pulse()
				else:
					view.press_at(view.hotspot_pos(area))
					view.release_at(view.hotspot_pos(area))
				break
	view.click_button("to_verdict")
	var pick: String = s.true_ailment
	if not correct:
		for c in d.candidates:
			if c != s.true_ailment:
				pick = c
				break
	view.click_button("cand:%s" % pick)
	view.click_button("verdict_ok")
	if not view.has_result() and not correct:
		for c in d.candidates:
			if c != s.true_ailment and not d.guesses.has(c):
				view.click_button("cand:%s" % c)
				view.click_button("verdict_ok")
				break


func _step_diagnosis() -> void:
	var view := _view() as DiagnosisView
	var s: TreatmentSession = _world.get_treatment().session_for(_patient)
	_drive_diagnosis(view, s, true)
	_check(view.has_result(), "layar hasil diagnosis tampil")
	_check(view.get_result().kind == "diagnosis" and view.get_result().grade >= Grade.Level.C, "nilai diagnosis wajar (%s)" % view.get_result().letter())
	_check(_world.get_skills().xp_of("diagnosis") > 0, "XP diagnosis bertambah")
	_check(view.click_button("result_continue"), "tombol Lanjut tersedia")


func _step_methods() -> void:
	_check(_mg().kind() == "metode" and _view() is ChoiceView, "lanjut ke pilihan metode")
	var cv := _view() as ChoiceView
	_check(cv.button_ids().has("item:akupunktur") and cv.button_ids().has("item:herbal"), "dua metode ditawarkan")
	_check(not cv.button_enabled("confirm"), "konfirmasi nonaktif tanpa pilihan")
	cv.click_button("item:herbal")
	cv.click_button("item:akupunktur")
	_check(cv.button_enabled("confirm"), "konfirmasi aktif setelah memilih")
	cv.click_button("confirm")
	_check(_mg().kind() == "akupunktur" and _view() is AcupunctureView, "metode dipilih -> minigame akupunktur")


func _step_acupuncture() -> void:
	var av := _view() as AcupunctureView
	var s: TreatmentSession = _world.get_treatment().session_for(_patient)
	_check(not av.button_enabled("start"), "mulai menusuk nonaktif tanpa titik")
	for pid in AilmentDb.acu_plan(s.true_ailment):
		av.press_at(av.point_screen_pos(pid))
		av.release_at(av.point_screen_pos(pid))
	_check(av.sys.selected.size() == AilmentDb.acu_plan(s.true_ailment).size(), "titik dipilih lewat sentuhan (%d)" % av.sys.selected.size())
	av.click_button("start")
	_check(av.sys.phase == AcupunctureSystem.Phase.JARUM, "fase penusukan dimulai")
	var guard: int = 0
	while av.sys.phase == AcupunctureSystem.Phase.JARUM and guard < 20:
		av.insert_at(Vector2.ZERO, AcupunctureSystem.DEPTH_CENTER)
		guard += 1
	av._tick(3.0)
	_check(av.has_result(), "layar hasil akupunktur tampil")
	_check(av.get_result().grade >= Grade.Level.A, "penusukan presisi -> nilai tinggi (%s)" % av.get_result().letter())
	av.click_button("result_continue")


func _step_crafting() -> void:
	_check(_mg().kind() == "resep" and _view() is ChoiceView, "lanjut ke pemilihan resep")
	var s: TreatmentSession = _world.get_treatment().session_for(_patient)
	var best: String = RecipeDb.best_for(s.true_ailment)
	if not _world.get_treatment().recipes_available().has(best):
		best = _world.get_treatment().recipes_available()[0]
	var cv := _view() as ChoiceView
	_check(cv.click_button("item:%s" % best), "resep dipilih (%s)" % best)
	_check(_mg().kind() == "peracikan" and _view() is CraftingView, "minigame peracikan terbuka")
	var v := _view() as CraftingView
	var h: HerbalCraftingSystem = v.sys
	var inv0: int = _world.get_inventory().total()
	for st in h.steps:
		for _u in range(int(st["units"])):
			_check(v.click_button("herb:%s" % String(st["herb"])), "ambil %s dari rak" % String(st["herb"]))
	_check(_world.get_inventory().total() < inv0, "inventaris berkurang saat bahan diambil")
	_check(v.click_button("to_measure"), "lanjut menakar")
	for st in h.steps:
		v.submit_grams(float(st["grams"]))
	_check(h.stage == HerbalCraftingSystem.Stage.TUMBUK, "semua bahan ditakar -> tahap tumbuk")
	for b in h.pound_beats:
		v.pound_at(float(b))
	v.finish_pound()
	_check(h.stage == HerbalCraftingSystem.Stage.ADUK, "tumbuk selesai -> tahap aduk")
	var guard: int = 0
	while not h.is_finished() and guard < 3000:
		v.stir_drag(0.05, 0.025)
		guard += 1
	_check(v.has_result() or h.is_finished(), "pengadukan selesai")
	_check(v.has_result(), "layar hasil peracikan tampil")
	_check(v.get_result().grade >= Grade.Level.A, "peracikan cermat -> nilai tinggi (%s)" % v.get_result().letter())
	v.click_button("result_continue")


func _step_summary() -> void:
	_check(_mg().kind() == "ringkasan" and _view() is InfoView, "ringkasan kunjungan tampil")
	var s: TreatmentSession = _world.get_treatment().session_for(_patient)
	_check(String(s.summary.get("outcome", "")) == "sembuh", "hasil: sembuh (kualitas %.2f)" % float(s.summary.get("quality", 0.0)))
	_check(_world.get_stats().money > 0 and _world.get_stats().treated == 1, "pendapatan klinik tercatat")
	_check(_patient.state == PatientRecord.State.SELESAI, "pasien selesai diperiksa")
	_view().click_button("info_close")
	_check(not _world.is_minigame_open() and not UiGate.blocked, "kunci dunia terbuka setelah ringkasan")
	var guard: int = 0
	while not _patient.done and guard < 3000:
		_world.step_world(0.5)
		guard += 1
	_check(_patient.done, "pasien meninggalkan klinik")


func _step_plant() -> void:
	_world.load_location("desa", "dari_klinik")
	var spot: String = "garden_plot_1"
	var cell: Vector2i = Vector2i(32, 33)
	_world.get_player().teleport_grid(Vector2(float(cell.x) + 0.5, float(cell.y) + 1.1))
	_world.update_interaction()
	var near: Interactable = _world.get_near_interactable()
	_check(near != null and near.id == spot, "petak kebun dapat diinteraksi (%s)" % (near.id if near != null else "-"))
	_check(_world.press_interact() and _mg().kind() == "identifikasi" and _view() is PlantView, "identifikasi tanaman terbuka dari kebun")
	var pv := _view() as PlantView
	var sys: PlantIdentificationSystem = pv.sys
	var inv0: int = _world.get_inventory().count(sys.plant_id)
	for part in HerbDb.PARTS:
		pv.click_button("part:%s" % part)
	_check(sys.observed.size() == sys.visible_parts().size(), "semua bagian terlihat diamati")
	pv.click_button("opt:%s" % sys.plant_id)
	_check(pv.has_result() and sys.succeeded(), "jawaban benar -> hasil tampil (%s)" % pv.get_result().letter())
	pv.click_button("result_continue")
	_check(not _world.is_minigame_open(), "layar identifikasi ditutup")
	_check(_world.get_skills().knows_plant(sys.plant_id), "pengetahuan herbal tercatat")
	_check(_world.get_inventory().count(sys.plant_id) > inv0, "hasil panen masuk inventaris")
	_check(_world.get_skills().xp_of("identifikasi_tanaman") > 0, "XP identifikasi bertambah")
	_world.interact_plant(spot)
	_check(not _world.is_minigame_open(), "petak tidak bisa diulang di hari yang sama")
	_world.get_clock().set_time(2, 9, 0)
	_world._check_new_day()
	_world.interact_plant(spot)
	_check(_world.is_minigame_open() and _mg().kind() == "identifikasi", "hari berikutnya petak terbuka lagi")
	_mg().close()


func _step_book() -> void:
	_check(_mg().show_book() and _mg().kind() == "buku", "Buku Tabib terbuka")
	_check(_view().button_ids().has("info_close"), "Buku Tabib punya tombol tutup")
	_view().click_button("info_close")
	_check(not _world.is_minigame_open(), "Buku Tabib ditutup")


func _step_second_patient_failures() -> void:
	_world.get_clock().set_time(2, 9, 0)
	var p: PatientRecord = _bring_to_exam(0)  # demam_dingin: >=3 kandidat, jadi dua tebakan salah mungkin
	_world.interact_exam_bed()
	var view := _view() as DiagnosisView
	var s: TreatmentSession = _world.get_treatment().session_for(p)
	_drive_diagnosis(view, s, false)
	_check(view.has_result() and view.get_result().grade == Grade.Level.D, "diagnosis salah -> nilai D")
	view.click_button("result_continue")
	var cv := _view() as ChoiceView
	cv.click_button("item:akupunktur")
	cv.click_button("confirm")
	var av := _view() as AcupunctureView
	var wrong: String = ""
	for id in AcupointDb.IDS:
		if not AilmentDb.acu_plan(s.true_ailment).has(id):
			wrong = id
			break
	av.toggle(wrong)
	av.click_button("start")
	av.insert_at(Vector2(0.6, 0.6), 0.05)
	av._tick(3.0)
	_check(av.has_result() and av.get_result().grade <= Grade.Level.D, "titik salah & meleset -> nilai D")
	av.click_button("result_continue")
	_check(_mg().kind() == "ringkasan", "tanpa ramuan langsung ke ringkasan")
	_check(String(s.summary.get("outcome", "")) == "gagal", "pengobatan gagal tercatat (%s)" % str(s.summary.get("outcome", "")))
	_view().click_button("info_close")
	_check(_world.get_stats().reputation < ClinicStats.START_REPUTATION + 10.0 and _world.get_stats().treated == 2, "statistik klinik memuat dua pasien")


func _step_final() -> void:
	_check(not UiGate.blocked, "tidak ada kunci masukan tersisa")
	_check(_world.get_actors().get_child_count() < 450, "node dunia dalam anggaran")
