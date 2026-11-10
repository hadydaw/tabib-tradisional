extends SceneTree
## Tes asap Fase 4 (headless): scene dunia dengan NPC, dialog, permintaan, pasien/antrean di klinik,
## tabrakan dan Y-sort dengan NPC. Waktu simulasi dimajukan lewat world.step_world(delta) agar
## tidak bergantung pada kecepatan frame headless. Tampilan sebenarnya hanya bisa dinilai di HP.
## Jalankan: godot --headless --path game -s res://tests/smoke/run_smoke_npc.gd

var _world: Node
var _steps: Array[Callable] = []
var _step_index: int = 0
var _frames: int = 0
var _fail: int = 0
var _count: int = 0


func _initialize() -> void:
	Locale.set_language("id")
	_world = (load("res://scenes/world/game_world.tscn") as PackedScene).instantiate()
	root.add_child(_world)
	_steps = [_step_load, _step_clock_label, _step_daily_schedule, _step_dialogue, _step_requests, _step_language,
		_step_collision_with_npc, _step_patient_to_clinic, _step_clinic_view, _step_clinic_actions,
		_step_exit_and_long_run, _step_final]


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	if _step_index < _steps.size():
		_steps[_step_index].call()
		_step_index += 1
		return false
	print("Tes asap NPC: %d pemeriksaan, gagal: %d" % [_count, _fail])
	quit(1 if _fail > 0 else 0)
	return true


func _check(condition: bool, name: String) -> void:
	_count += 1
	if condition:
		print("  OK   ", name)
	else:
		_fail += 1
		printerr("  GAGAL ", name)


func _run(seconds: float, step: float = 0.5) -> void:
	var t: float = 0.0
	while t < seconds:
		_world.step_world(step)
		t += step


func _first_visible_npc() -> NpcAgent:
	var list: Array[NpcAgent] = _world.get_sim().agents_in(_world.get_location().id)
	return list[0] if not list.is_empty() else null


func _place_player_next_to(a: NpcAgent) -> void:
	var player: Player = _world.get_player()
	var sim: NpcSimulation = _world.get_sim()
	# sel bebas terdekat di sebelah NPC
	var pf: GridPathfinder = sim.navigation(a.loc)
	var spot: Vector2i = pf.nearest_open(a.cell, sim.occupied_cells(a.loc), 3)
	player.teleport_grid(Vector2(spot) + Vector2(0.5, 0.5))


func _step_load() -> void:
	var sim: NpcSimulation = _world.get_sim()
	var visible_n: int = sim.agents_in("desa").size()
	_check(sim.agents.size() == 8, "8 NPC disimulasikan")
	_check(_world.npc_node_count() == visible_n and visible_n >= 1, "node NPC = NPC yang tampil di desa (%d)" % visible_n)
	var actors: Node2D = _world.get_actors()
	var in_actors: bool = true
	var placed: bool = true
	for a in sim.agents_in("desa"):
		var n: NpcNode = _world.get_npc_node(a.id)
		if n == null or n.get_parent() != actors:
			in_actors = false
		elif not n.position.is_equal_approx(IsoMath.grid_to_screen(a.pos, Vector2(64, 32))):
			placed = false
	_check(in_actors and actors.y_sort_enabled, "NPC berada di kelompok Y-sort yang sama dengan pemain")
	_check(placed, "posisi node NPC = posisi grid -> layar (titik kaki)")
	var n_nodes: int = actors.get_child_count()
	_check(n_nodes < 450, "jumlah node desa tetap dalam anggaran (%d)" % n_nodes)


func _step_clock_label() -> void:
	_world._refresh_clock_label()
	var lbl: Label = _world._clock_label
	_check(lbl.text.contains("Hari 1") and lbl.text.contains("07:"), "label jam menampilkan hari dan waktu (%s)" % lbl.text.replace("\n", " | "))
	_check(lbl.text.contains("Klinik tutup") and lbl.text.contains("Antrean: 0"), "label menampilkan status klinik dan antrean")


func _step_daily_schedule() -> void:
	# pukul 10:00 dan 02:00: penempatan sesuai jadwal; jalankan 20 menit dan pastikan NPC bergerak
	_world.debug_set_time(1, 10, 0)
	var sim: NpcSimulation = _world.get_sim()
	var out_n: int = sim.agents_in("desa").size() + sim.agents_in("klinik").size()
	_check(out_n >= 5, "pukul 10:00 mayoritas NPC di luar rumah (%d)" % out_n)
	_check(_world.npc_node_count() == sim.agents_in(_world.get_location().id).size(), "node NPC sinkron setelah lompat waktu")
	var before: Dictionary = {}
	for a in sim.agents:
		before[a.id] = a.pos
	_run(60.0)
	var moved: int = 0
	for a in sim.agents:
		if a.loc != "" and a.pos.distance_to(before[a.id]) > 0.5:
			moved += 1
	_check(moved >= 2, "dalam 1 menit beberapa NPC berjalan (%d)" % moved)
	_check(_world.npc_node_count() == sim.agents_in(_world.get_location().id).size(), "node NPC tetap sinkron saat NPC keluar/masuk")
	_world.debug_set_time(1, 2, 0)
	_check(sim.agents_in("desa").is_empty() and _world.npc_node_count() == 0, "pukul 02:00 desa kosong")
	_world.debug_set_time(1, 10, 0)


func _step_dialogue() -> void:
	var a: NpcAgent = _first_visible_npc()
	_check(a != null, "ada NPC di desa untuk diajak bicara")
	_place_player_next_to(a)
	_world.update_interaction()
	var near: Interactable = _world.get_near_interactable()
	_check(near != null and near.kind == "npc", "tombol interaksi menunjuk NPC terdekat")
	_check(_world._btn_interact.visible and _world._interact_label.text.begins_with("Bicara: "), "label interaksi: %s" % _world._interact_label.text)
	var started: bool = _world.press_interact()
	_check(started and _world.is_dialogue_active() and _world.get_panel().visible, "dialog dimulai dan panel tampil")
	_check(a.talking, "NPC berhenti berjalan saat diajak bicara")
	var v: Dictionary = _world.get_dialogue().view()
	_check(String(v["text"]) != "" and (v["choices"] as Array).size() >= 3, "dialog punya teks dan pilihan")
	_check(_world.get_panel().choice_count() == (v["choices"] as Array).size(), "panel menampilkan semua pilihan")
	# gerak pemain dibekukan saat dialog
	var p0: Vector2 = _world.get_player().grid_pos
	_world.get_player().move_input = Vector2(1, 0)
	_world.poll_input()
	_world.get_player().advance(0.05)
	_check(_world.get_player().grid_pos.is_equal_approx(p0), "pemain tidak bergerak saat dialog")
	_world.dialogue_choose(0)
	_world.dialogue_choose(-1)
	_world.dialogue_choose((_world.get_dialogue().view()["choices"] as Array).size() - 1)
	_check(not _world.is_dialogue_active() and not _world.get_panel().visible and not a.talking, "pilih Sampai jumpa -> dialog selesai, NPC jalan lagi")
	_check(not _world.press_interact() or _world.is_dialogue_active(), "interaksi lagi membuka dialog baru")
	_world.end_dialogue()


func _step_requests() -> void:
	var sim: NpcSimulation = _world.get_sim()
	var req: RequestLog = _world.get_requests()
	_world.debug_set_time(1, 10, 0)
	var karto: NpcAgent = sim.agent("karto")
	var wiryo: NpcAgent = sim.agent("wiryo")
	_check(karto.loc == "desa" and wiryo.loc == "desa", "pukul 10:00 Karto dan Mbah Wiryo di desa")
	_place_player_next_to(karto)
	_check(_world.start_dialogue("karto"), "bicara dengan Pak Karto")
	var labels: Array = _world.get_dialogue().view()["choices"]
	var help_i: int = labels.find(Locale.tr("dlg.choice.help"))
	_check(help_i >= 0, "ada pilihan 'Ada yang bisa kubantu?'")
	_world.dialogue_choose(help_i)
	_world.dialogue_choose(0)  # terima
	_check(req.status("req_salam_wiryo") == RequestLog.ACTIVE, "permintaan diterima lewat dialog")
	_world.dialogue_choose(-1)
	_check(not _world.is_dialogue_active(), "dialog selesai")
	_world._refresh_clock_label()
	_check(_world._clock_label.text.contains("Sampaikan salam"), "permintaan aktif tampil di HUD")
	_place_player_next_to(wiryo)
	_check(_world.start_dialogue("wiryo"), "bicara dengan Mbah Wiryo")
	_check(req.status("req_salam_wiryo") == RequestLog.READY, "bicara dengan target -> permintaan siap dilaporkan")
	_world.end_dialogue()
	_place_player_next_to(karto)
	_world.start_dialogue("karto")
	_check(String(_world.get_dialogue().view()["text"]).begins_with("Sudah selesai"), "Karto menyapa dengan permintaan siap dilaporkan")
	_world.dialogue_choose(0)
	_check(req.status("req_salam_wiryo") == RequestLog.DONE, "lapor -> selesai")
	_world.dialogue_choose(-1)
	_world.end_dialogue()
	# permintaan kunjungan zona: terima dari Bu Lastri lalu masuk Kebun Herbal
	req.accept("req_lihat_kebun")
	var garden: Rect2i = Rect2i()
	for z in _world.get_location().zones:
		if z["name"] == "Kebun Herbal":
			garden = z["rect"]
	_world.get_player().teleport_grid(Vector2(garden.position.x + 3.5, 33.5))
	_world.step_world(0.1)
	_check(req.status("req_lihat_kebun") == RequestLog.READY, "masuk zona Kebun Herbal -> permintaan siap dilaporkan")


func _step_language() -> void:
	var a: NpcAgent = _first_visible_npc()
	_place_player_next_to(a)
	_world.start_dialogue(a.id)
	var id_text: String = String(_world.get_dialogue().view()["text"])
	_world._toggle_language()
	var en_text: String = String(_world.get_dialogue().view()["text"])
	_check(Locale.current == "en" and en_text != id_text and en_text != "", "ganti bahasa: dialog tampil dalam English")
	_world._toggle_language()
	_check(Locale.current == "id" and String(_world.get_dialogue().view()["text"]) == id_text, "kembali ke Indonesia")
	_world.end_dialogue()


func _step_collision_with_npc() -> void:
	_world.debug_set_time(1, 10, 0)
	var a: NpcAgent = _first_visible_npc()
	var player: Player = _world.get_player()
	# beri NPC waktu berhenti: pakai NPC yang sedang diam (talking membekukan)
	a.talking = true
	var target: Vector2 = a.pos
	player.teleport_grid(target + Vector2(-1.6, 0.0))
	_world.step_world(0.05)
	var hit: bool = false
	for _i in range(90):
		player.move_input = IsoMath.direction_vector(IsoMath.direction_index(IsoMath.grid_to_screen(Vector2(1, 0), Vector2(64, 32))))
		player.advance(1.0 / 60.0)
		if absf(player.grid_pos.x - target.x) < 0.7 and absf(player.grid_pos.y - target.y) < 0.7:
			hit = true
	player.move_input = Vector2.ZERO
	_check(not hit, "pemain tidak bisa menembus NPC (jarak akhir %.2f)" % player.grid_pos.distance_to(target))
	_check(_world.get_collision().is_cell_blocked(a.cell), "sel NPC terhalang di tabrakan pemain")
	a.talking = false


func _step_patient_to_clinic() -> void:
	_world.debug_set_time(1, 9, 0)
	var ps: PatientSystem = _world.get_patients()
	ps.update(0.0)
	for e in ps.planned():
		e["started"] = true
	ps.auto_call = false
	_world.get_player().teleport_grid(Vector2(23.5, 16.5))
	var p: PatientRecord = _world.debug_new_patient()
	_check(p != null and p.state == PatientRecord.State.MENUJU, "pasien baru berangkat ke klinik")
	var guard: int = 0
	while p.state != PatientRecord.State.MENUNGGU and guard < 3000:
		_world.step_world(0.5)
		guard += 1
	_check(p.state == PatientRecord.State.MENUNGGU, "pasien tiba, mendaftar, dan menunggu (%d langkah)" % guard)
	_check(ps.queue.waiting_count() == 1 and p.ticket == 1, "antrean: 1 pasien nomor 1")
	_world._refresh_clock_label()
	_check(_world._clock_label.text.contains("Antrean: 1"), "HUD menampilkan antrean 1")


func _step_clinic_view() -> void:
	_world.load_location("klinik", "dari_desa")
	var sim: NpcSimulation = _world.get_sim()
	var p: PatientRecord = _world.get_patients().queue.records[0]
	var node: NpcNode = _world.get_npc_node(p.npc_id)
	_check(node != null, "pasien tampil di klinik")
	var agent: NpcAgent = sim.agent(p.npc_id)
	_check(agent.sitting and node.get_parent() == _world.get_actors(), "pasien duduk di kursi, berada di kelompok Y-sort")
	_check(_world.get_collision().is_cell_blocked(agent.cell), "kursi pasien terhalang bagi pemain")
	# dialog dengan pasien memuat keluhan
	_place_player_next_to(agent)
	_world.start_dialogue(agent.id)
	var txt: String = String(_world.get_dialogue().view()["text"])
	_check(txt.contains("menunggu giliran"), "dialog pasien: %s" % txt)
	_world.end_dialogue()


func _step_clinic_actions() -> void:
	var ps: PatientSystem = _world.get_patients()
	var p: PatientRecord = ps.queue.records[0]
	_world._interact_reception()
	_check(p.state == PatientRecord.State.DIPANGGIL, "meja penerimaan memanggil pasien")
	_check(_world._toast.text.contains("No. 1"), "toast pemanggilan: %s" % _world._toast.text)
	var guard: int = 0
	while p.state != PatientRecord.State.DIPERIKSA and guard < 600:
		_world.step_world(0.5)
		guard += 1
	_check(p.state == PatientRecord.State.DIPERIKSA, "pasien di ruang periksa")
	_world._interact_exam_bed()
	_check(p.state == PatientRecord.State.SELESAI, "tempat periksa mengakhiri pemeriksaan (placeholder)")
	_world._interact_reception()
	_check(_world._toast.text == Locale.tr("clinic.no_patient"), "tidak ada pasien menunggu -> pesan")
	# pasien keluar dari klinik dan hilang dari tampilan
	guard = 0
	while _world.get_npc_node(p.npc_id) != null and guard < 1500:
		_world.step_world(0.5)
		guard += 1
	_check(_world.get_npc_node(p.npc_id) == null, "pasien meninggalkan klinik (node dihapus)")


func _step_exit_and_long_run() -> void:
	_world.load_location("desa", "dari_klinik")
	_world.get_player().teleport_grid(Vector2(23.5, 16.5))
	# 6 jam permainan dengan pemain diam: tidak ada galat, node dan simulasi tetap sinkron
	var sim: NpcSimulation = _world.get_sim()
	var ok_sync: bool = true
	for i in range(720):
		_world.step_world(0.5)
		if i % 20 == 0:
			if _world.npc_node_count() != sim.agents_in(_world.get_location().id).size():
				ok_sync = false
	_check(ok_sync, "6 jam permainan: node NPC selalu sinkron dengan simulasi")
	var player_cell := Vector2i(floori(_world.get_player().grid_pos.x), floori(_world.get_player().grid_pos.y))
	var overlap: bool = false
	for a in sim.agents_in("desa"):
		if a.cell == player_cell:
			overlap = true
	_check(not overlap, "tidak ada NPC menumpuk di sel pemain")
	_check(_world.get_clock().day >= 1, "jam permainan berjalan (%s)" % _world.get_clock().format_time())


func _step_final() -> void:
	_check(_world.get_actors().get_child_count() < 450, "node dunia akhir dalam anggaran")
