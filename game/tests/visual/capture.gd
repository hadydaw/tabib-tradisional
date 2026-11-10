extends SceneTree
## Menangkap tangkapan layar dunia Fase 3 (butuh renderer nyata, misalnya xvfb + Mesa llvmpipe).
## Hanya untuk pemeriksaan visual placeholder di CI; tidak dijalankan headless.
## Keluaran: JPG di direktori dari variabel lingkungan SHOT_DIR (default /tmp/shots).

const CROP := Vector2i(160, 240)

var _world: Node
var _steps: Array[Callable] = []
var _i: int = 0
var _wait: int = 0
var _frames: int = 0
var _dir: String = "/tmp/shots"
var _sheet: Image
var _sheet_name: String = ""


func _initialize() -> void:
	var env: String = OS.get_environment("SHOT_DIR")
	if env != "":
		_dir = env
	DirAccess.make_dir_recursive_absolute(_dir)
	_world = (load("res://scenes/world/game_world.tscn") as PackedScene).instantiate()
	root.add_child(_world)
	_steps = [
		func() -> void: _shot("01_desa_awal"),
		func() -> void: _go(Vector2(23.0, 14.5)),
		func() -> void: _shot("02_klinik_depan"),
		func() -> void: _go(Vector2(11.0, 17.0)),
		func() -> void: _shot("03_rumah_barat"),
		func() -> void: _go(Vector2(36.0, 33.0)),
		func() -> void: _shot("04_kebun_herbal"),
		func() -> void: _go(Vector2(41.0, 20.5)),
		func() -> void: _shot("05_jalan_timur"),
		func() -> void: _go(Vector2(10.0, 27.0)),
		func() -> void: _shot("06_rumah_selatan"),
		func() -> void: _world.load_location("klinik", "dari_desa"),
		func() -> void: _shot("07_klinik_penerimaan"),
		func() -> void: _go(Vector2(6.0, 3.8)),
		func() -> void: _shot("08_klinik_pemeriksaan"),
		func() -> void: _go(Vector2(12.5, 4.2)),
		func() -> void: _shot("09_klinik_peracikan"),
		func() -> void: _world.load_location("desa", "awal"),
		func() -> void: _begin_sheet("10_karakter_a"),
	]
	for f in range(8):
		_steps.append(func() -> void: _set_face(f))
		_steps.append(func() -> void: _crop(f))
	_steps.append(func() -> void: _end_sheet())
	_steps.append(func() -> void: _look_b())
	_steps.append(func() -> void: _begin_sheet("11_karakter_b"))
	for f in range(8):
		_steps.append(func() -> void: _set_face(f))
		_steps.append(func() -> void: _crop(f))
	_steps.append(func() -> void: _end_sheet())
	# Fase 4: NPC, dialog, pasien di klinik
	_steps.append(func() -> void:
		_world.get_camera().zoom = Vector2(1.5, 1.5)
		_world.load_location("desa", "awal")
		_world.debug_set_time(1, 10, 0)
		_go(Vector2(23.5, 16.5)))
	_steps.append(func() -> void: _shot("12_desa_npc"))
	_steps.append(func() -> void:
		_next_to("karto")
		_world.start_dialogue("karto"))
	_steps.append(func() -> void: _shot("13_dialog_npc"))
	_steps.append(func() -> void:
		_world.end_dialogue()
		var ps: PatientSystem = _world.get_patients()
		ps.suppress_plan()
		ps.auto_call = false
		for _i in range(4):
			_world.debug_new_patient()
		for _k in range(150):
			_world.step_world(0.5)
		_world.load_location("klinik", "dari_desa"))
	_steps.append(func() -> void: _go(Vector2(8.0, 9.5)))
	_steps.append(func() -> void: _shot("14_klinik_pasien"))
	_steps.append(func() -> void: _go(Vector2(7.0, 7.5)))
	_steps.append(func() -> void: _shot("14b_klinik_pasien_dekat"))
	_steps.append(func() -> void:
		_world.start_dialogue(_world.get_patients().queue.records[0].npc_id))
	_steps.append(func() -> void: _shot("15_dialog_pasien"))
	_steps.append(func() -> void: _world.end_dialogue())
	_add_medical_steps()


func _next_to(npc_id: String) -> void:
	var sim: NpcSimulation = _world.get_sim()
	var a: NpcAgent = sim.agent(npc_id)
	var pf: GridPathfinder = sim.navigation(a.loc)
	var spot: Vector2i = pf.nearest_open(a.cell, sim.occupied_cells(a.loc), 3)
	_go(Vector2(spot) + Vector2(0.5, 0.5))


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 8:
		return false
	if _wait > 0:
		_wait -= 1
		return false
	if _i >= _steps.size():
		quit(0)
		return true
	_steps[_i].call()
	_i += 1
	_wait = 5
	return false


func _go(grid: Vector2) -> void:
	var p: Player = _world.get_player()
	p.teleport_grid(grid)
	_world.get_camera().snap_to_target()


func _shot(name: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_jpg("%s/%s.jpg" % [_dir, name], 0.82)
	print("tangkapan: ", name, " ", img.get_size())


func _begin_sheet(name: String) -> void:
	_sheet_name = name
	_sheet = Image.create(CROP.x * 8, CROP.y, false, Image.FORMAT_RGBA8)
	_sheet.fill(Color(0.1, 0.14, 0.16))
	var p: Player = _world.get_player()
	p.set_process(false)
	_go(Vector2(23.5, 16.5))
	_world.get_camera().zoom = Vector2(4.0, 4.0)
	_world.get_camera().snap_to_target()


func _set_face(f: int) -> void:
	var p: Player = _world.get_player()
	p._view.apply_animation("walk", 0.25, f)


func _crop(f: int) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	var c := Vector2i(img.get_width() / 2, img.get_height() / 2)
	var src := Rect2i(c.x - CROP.x / 2, c.y - 135, CROP.x, CROP.y)
	_sheet.blit_rect(img, src, Vector2i(f * CROP.x, 0))


func _end_sheet() -> void:
	_sheet.save_png("%s/%s.png" % [_dir, _sheet_name])
	_sheet.save_jpg("%s/%s.jpg" % [_dir, _sheet_name], 0.85)
	print("lembar: ", _sheet_name)


func _look_b() -> void:
	var a: CharacterAppearance = _world.get_appearance()
	a.set_skin(4)
	a.set_hair_style(3)
	a.set_hair_color(3)
	a.equip("top_rompi_cokelat")
	a.equip("bottom_kain_merah")
	a.equip("head_caping")


# --- Fase 5: layar minigame ---------------------------------------------------

var _mp: PatientRecord
var _mv: MinigameView


func _mg() -> MinigameManager:
	return _world.get_minigames()


func _add_medical_steps() -> void:
	_steps.append(func() -> void:
		_mg().transitions = false
		_mp = _world.get_patients().queue.records[0]
		_world._interact_reception()
		var guard: int = 0
		while _mp.state != PatientRecord.State.DIPERIKSA and guard < 900:
			_world.step_world(0.5)
			guard += 1
		print("medis: pasien ", _mp.npc_id, " state ", _mp.state_key(), " langkah ", guard)
		_world.interact_exam_bed())
	_steps.append(func() -> void:
		var v := _mg().current_view() as DiagnosisView
		v.click_button("observe")
		v.press_at(v.hotspot_pos("lidah"))
		v.release_at(v.hotspot_pos("lidah"))
		v.press_at(v.hotspot_pos("kulit"))
		v.release_at(v.hotspot_pos("kulit")))
	_steps.append(func() -> void: _shot("16_diagnosis_periksa"))
	_steps.append(func() -> void:
		var v := _mg().current_view() as DiagnosisView
		v.inspect_area("nadi")
		v._pulse_t = 2.0)
	_steps.append(func() -> void: _shot("17_diagnosis_nadi"))
	_steps.append(func() -> void:
		var v := _mg().current_view() as DiagnosisView
		v.pulse_tap_time(1.2)
		v.finish_pulse()
		v.click_button("to_verdict"))
	_steps.append(func() -> void: _shot("18_diagnosis_putusan"))
	_steps.append(func() -> void:
		var v := _mg().current_view() as DiagnosisView
		var s: TreatmentSession = _world.get_treatment().session_for(_mp)
		v.click_button("cand:%s" % s.true_ailment)
		v.click_button("verdict_ok"))
	_steps.append(func() -> void: _shot("19_diagnosis_hasil"))
	_steps.append(func() -> void:
		_mg().current_view().click_button("result_continue"))
	_steps.append(func() -> void: _shot("20_pilih_metode"))
	_steps.append(func() -> void:
		var cv := _mg().current_view() as ChoiceView
		cv.click_button("item:akupunktur")
		cv.click_button("item:herbal")
		cv.click_button("confirm")
		var av := _mg().current_view() as AcupunctureView
		var s: TreatmentSession = _world.get_treatment().session_for(_mp)
		var plan: Array[String] = AilmentDb.acu_plan(s.true_ailment)
		av.toggle(plan[0])
		av.toggle(plan[1]))
	_steps.append(func() -> void: _shot("21_akupunktur_pilih"))
	_steps.append(func() -> void:
		var av := _mg().current_view() as AcupunctureView
		av.toggle(AilmentDb.acu_plan(_world.get_treatment().session_for(_mp).true_ailment)[2])
		av.click_button("start")
		av.aim = Vector2(0.15, -0.1))
	_steps.append(func() -> void: _shot("22_akupunktur_jarum"))
	_steps.append(func() -> void:
		var av := _mg().current_view() as AcupunctureView
		var guard: int = 0
		while av.sys.phase == AcupunctureSystem.Phase.JARUM and guard < 20:
			av.insert_at(Vector2(0.05, 0.03), AcupunctureSystem.DEPTH_CENTER)
			guard += 1
		av._tick(3.0))
	_steps.append(func() -> void: _shot("23_akupunktur_hasil"))
	_steps.append(func() -> void:
		_mg().current_view().click_button("result_continue"))
	_steps.append(func() -> void: _shot("24_pilih_resep"))
	_steps.append(func() -> void:
		var s: TreatmentSession = _world.get_treatment().session_for(_mp)
		var best: String = RecipeDb.best_for(s.true_ailment)
		if not _world.get_treatment().recipes_available().has(best):
			best = _world.get_treatment().recipes_available()[0]
		(_mg().current_view() as ChoiceView).click_button("item:%s" % best)
		var v := _mg().current_view() as CraftingView
		var first: Dictionary = v.sys.steps[0]
		v.click_button("herb:%s" % String(first["herb"])))
	_steps.append(func() -> void: _shot("25_peracikan_pilih"))
	_steps.append(func() -> void:
		var v := _mg().current_view() as CraftingView
		for st in v.sys.steps:
			for _u in range(int(st["units"])):
				v.take(String(st["herb"]))
		v.click_button("to_measure")
		v._grams = v.sys.measure_target() * 0.85)
	_steps.append(func() -> void: _shot("26_peracikan_takar"))
	_steps.append(func() -> void:
		var v := _mg().current_view() as CraftingView
		for st in v.sys.steps:
			v.submit_grams(float(st["grams"]))
		v._pound_t = 0.5)
	_steps.append(func() -> void: _shot("27_peracikan_tumbuk"))
	_steps.append(func() -> void:
		var v := _mg().current_view() as CraftingView
		for b in v.sys.pound_beats:
			v.pound_at(float(b))
		v.finish_pound()
		v.sys.stir_progress = v.sys.stir_target * 0.45)
	_steps.append(func() -> void: _shot("28_peracikan_aduk"))
	_steps.append(func() -> void:
		var v := _mg().current_view() as CraftingView
		var guard: int = 0
		while not v.sys.is_finished() and guard < 3000:
			v.stir_drag(0.05, 0.025)
			guard += 1)
	_steps.append(func() -> void: _shot("29_peracikan_hasil"))
	_steps.append(func() -> void:
		_mg().current_view().click_button("result_continue"))
	_steps.append(func() -> void: _shot("30_ringkasan_kunjungan"))
	_steps.append(func() -> void:
		_mg().current_view().click_button("info_close")
		_world.load_location("desa", "awal")
		_world.get_clock().set_time(2, 9, 0)
		_mg().start_plant("garden_plot_2")
		var pv := _mg().current_view() as PlantView
		pv.look("daun")
		pv.look("akar"))
	_steps.append(func() -> void: _shot("31_identifikasi_tanaman"))
	_steps.append(func() -> void:
		_mg().close()
		_mg().show_book())
	_steps.append(func() -> void: _shot("32_buku_tabib"))
	_steps.append(func() -> void: _mg().close())
