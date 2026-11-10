extends SceneTree
## Tes unit Fase 4: pencari jalan, jam, localization, roster/jadwal, simulasi NPC (invarian jangka
## panjang, anti-tersangkut), dialog, permintaan, antrean dan sistem pasien, tabrakan dinamis.
## Jalankan: godot --headless --path game -s res://tests/unit/run_tests_fase4.gd

var _count: int = 0
var _fail: int = 0


func _init() -> void:
	_test_pathfinder()
	_test_clock()
	_test_locale()
	_test_dynamic_collision_and_interactable()
	_test_location_data()
	_test_roster()
	_test_requests_and_dialogue()
	_test_queue()
	_test_sim_schedule_snap()
	_test_sim_long_run()
	_test_sim_blocked_by_player()
	_test_patient_flow()
	_test_patient_crowd()
	_test_patient_giveup_and_close()
	_test_plan()
	print("Tes Fase 4 dijalankan: %d, gagal: %d" % [_count, _fail])
	quit(1 if _fail > 0 else 0)


func _check(condition: bool, name: String) -> void:
	_count += 1
	if condition:
		print("  OK   ", name)
	else:
		_fail += 1
		printerr("  GAGAL ", name)


# --- Pencari jalan ------------------------------------------------------------

func _test_pathfinder() -> void:
	var pf := GridPathfinder.new(10, 10)
	var p: Array[Vector2i] = pf.find_path(Vector2i(0, 0), Vector2i(5, 0))
	_check(p.size() == 5 and p[p.size() - 1] == Vector2i(5, 0), "jalur lurus 5 langkah")
	_check(pf.find_path(Vector2i(2, 2), Vector2i(2, 2)).is_empty(), "awal = tujuan -> kosong")
	var d: Array[Vector2i] = pf.find_path(Vector2i(0, 0), Vector2i(4, 4))
	_check(d.size() == 4, "diagonal bebas = 4 langkah")
	# dinding vertikal x=5 dengan celah di y=8
	for y in range(0, 8):
		pf.blocked[Vector2i(5, y)] = true
	pf.blocked[Vector2i(5, 9)] = true
	var around: Array[Vector2i] = pf.find_path(Vector2i(2, 2), Vector2i(8, 2))
	_check(not around.is_empty() and around.has(Vector2i(5, 8)), "memutar lewat celah")
	var ok: bool = true
	for c in around:
		if pf.blocked.has(c):
			ok = false
	_check(ok, "jalur tidak melewati sel terhalang")
	pf.blocked[Vector2i(5, 8)] = true
	_check(pf.find_path(Vector2i(2, 2), Vector2i(8, 2)).is_empty(), "tertutup -> tanpa jalur")
	pf.blocked.erase(Vector2i(5, 8))
	# tidak memotong sudut
	var pf2 := GridPathfinder.new(4, 4)
	pf2.blocked[Vector2i(1, 0)] = true
	pf2.blocked[Vector2i(0, 1)] = true
	_check(pf2.find_path(Vector2i(0, 0), Vector2i(1, 1)).is_empty(), "tidak memotong sudut sel terhalang")
	# kursi: hanya boleh dimasuki bila diizinkan
	var pf3 := GridPathfinder.new(5, 5)
	pf3.blocked[Vector2i(2, 2)] = true
	_check(pf3.find_path(Vector2i(0, 2), Vector2i(2, 2)).is_empty(), "tujuan terhalang tanpa izin -> kosong")
	var s: Array[Vector2i] = pf3.find_path(Vector2i(0, 2), Vector2i(2, 2), {}, {Vector2i(2, 2): true})
	_check(not s.is_empty() and s[s.size() - 1] == Vector2i(2, 2), "tujuan kursi diizinkan")
	# menghindari sel sementara
	var pf4 := GridPathfinder.new(5, 5)
	var av: Array[Vector2i] = pf4.find_path(Vector2i(0, 2), Vector2i(4, 2), {Vector2i(2, 2): true})
	_check(not av.is_empty() and not av.has(Vector2i(2, 2)), "menghindari sel avoid")
	# biaya keset
	var pf5 := GridPathfinder.new(5, 3)
	pf5.extra_cost[Vector2i(2, 1)] = 6.0
	var m: Array[Vector2i] = pf5.find_path(Vector2i(0, 1), Vector2i(4, 1))
	_check(not m.has(Vector2i(2, 1)), "biaya ekstra menghindari keset")
	# sel terbuka terdekat
	var n: Vector2i = pf4.nearest_open(Vector2i(2, 2), {Vector2i(1, 2): true, Vector2i(3, 2): true}, 3)
	_check(n.x >= 0 and n != Vector2i(2, 2) and not (n.x == 1 and n.y == 2), "nearest_open menemukan sel bebas")
	var boxed := GridPathfinder.new(3, 3)
	for y in range(3):
		for x in range(3):
			if not (x == 1 and y == 1):
				boxed.blocked[Vector2i(x, y)] = true
	_check(boxed.nearest_open(Vector2i(1, 1), {}, 3).x < 0, "terkurung -> tidak ada sel terbuka")


# --- Jam ----------------------------------------------------------------------

func _test_clock() -> void:
	var c := GameClock.new()
	_check(c.minute() == 420 and c.day == 1, "mulai hari 1 pukul 07:00")
	c.advance(60.0)
	_check(c.minute() == 480 and c.format_time() == "08:00", "60 detik = 60 menit permainan")
	c.set_time(1, 23, 50)
	c.advance(20.0)
	_check(c.day == 2 and c.minute() == 10, "melewati tengah malam -> hari berikutnya")
	c.paused = true
	c.advance(100.0)
	_check(c.minute() == 10, "jeda menghentikan jam")
	_check(GameClock.format_minute(-60) == "23:00", "format menit negatif membungkus")
	c.paused = false
	c.set_time(3, 9, 5)
	_check(absf(c.absolute_minutes() - (2.0 * 1440.0 + 545.0)) < 0.001, "menit absolut")


# --- Localization --------------------------------------------------------------

func _test_locale() -> void:
	Locale.set_language("id")
	_check(Locale.keys("id").size() > 100, "tabel id terisi (%d kunci)" % Locale.keys("id").size())
	_check(Locale.missing_keys("en").is_empty(), "semua kunci id ada di en (kurang: %s)" % str(Locale.missing_keys("en")))
	_check(Locale.tr("ui.next") == "Lanjut", "teks Indonesia")
	Locale.set_language("en")
	_check(Locale.tr("ui.next") == "Next", "teks English")
	_check(Locale.tr("ui.talk", {"name": "Raka"}) == "Talk: Raka", "penanda {name} diganti")
	_check(Locale.tr("kunci.tidak.ada") == "kunci.tidak.ada", "kunci tak dikenal -> kunci")
	_check(not Locale.set_language("fr") and Locale.current == "en", "bahasa tak dikenal ditolak")
	Locale.set_language("id")
	_check(Locale.toggle_language() == "en" and Locale.toggle_language() == "id", "toggle bahasa")
	var missing: Array = []
	for n in NpcRoster.all():
		for k in [n.name_key(), n.role_key(), "dlg.%s.greet" % n.id, "dlg.%s.about" % n.id, "dlg.%s.about2" % n.id]:
			if not Locale.has_key(k) or not Locale.has_key(k, "en"):
				missing.append(k)
		for e in n.schedule:
			var ak: String = "activity.%s" % String(e["activity"])
			if not Locale.has_key(ak):
				missing.append(ak)
		if n.request_id != "":
			for suffix in [".title", ".offer", ".remind"]:
				if not Locale.has_key(n.request_id + suffix) or not Locale.has_key(n.request_id + suffix, "en"):
					missing.append(n.request_id + suffix)
	for cid in ComplaintCatalog.IDS:
		if not Locale.has_key("complaint.%s" % cid) or not Locale.has_key("complaint.%s" % cid, "en"):
			missing.append("complaint." + cid)
	for a in ["menunggu_giliran", "berobat", "diperiksa"]:
		if not Locale.has_key("activity." + a):
			missing.append("activity." + a)
	_check(missing.is_empty(), "semua kunci NPC/jadwal/keluhan/permintaan tersedia (kurang: %s)" % str(missing))


# --- Tabrakan dinamis dan titik interaksi dinamis ------------------------------

func _test_dynamic_collision_and_interactable() -> void:
	var col := GridCollision.new(6, 6, 0.25)
	col.block_cell(Vector2i(4, 1))
	var dyn: Dictionary = {Vector2i(2, 1): true}
	col.set_dynamic_blocked(dyn)
	var end: Vector2 = col.move(Vector2(0.5, 1.5), Vector2(3.0, 0.0))
	_check(end.x < 2.0, "sel dinamis menghalangi pemain (x=%.2f)" % end.x)
	dyn.erase(Vector2i(2, 1))
	var end2: Vector2 = col.move(Vector2(0.5, 1.5), Vector2(3.0, 0.0))
	_check(end2.x > 2.5, "sel dinamis dilepas -> bebas lewat")
	_check(col.is_cell_blocked(Vector2i(4, 1)) and col.is_static_blocked(Vector2i(4, 1)), "sel statis tetap terhalang")
	_check(not col.is_static_blocked(Vector2i(2, 1)), "is_static_blocked tidak melihat dinamis")
	var it := Interactable.new("x", Vector2i(2, 2), "X")
	_check(it.center() == Vector2(2.5, 2.5), "titik interaksi statis di tengah sel")
	it.use_dynamic_pos = true
	it.dynamic_pos = Vector2(7.2, 1.1)
	_check(it.center() == Vector2(7.2, 1.1), "titik interaksi dinamis mengikuti posisi")


# --- Data lokasi ---------------------------------------------------------------

func _reachable(loc: LocationData, from: Vector2i, to: Vector2i) -> bool:
	var pf := GridPathfinder.new(loc.width, loc.height)
	pf.blocked = loc.blocked_cells()
	if loc.is_seat(to):
		return not pf.find_path(from, to, {}, {to: true}).is_empty()
	return from == to or not pf.find_path(from, to).is_empty()


func _test_location_data() -> void:
	var village: LocationData = LocationRegistry.get_location("desa")
	var clinic: LocationData = LocationRegistry.get_location("klinik")
	var vblocked: Dictionary = village.blocked_cells()
	var cblocked: Dictionary = clinic.blocked_cells()
	var vstart := Vector2i(floori(village.spawns["awal"].x), floori(village.spawns["awal"].y))
	var cstart := Vector2i(floori(clinic.spawns["dari_desa"].x), floori(clinic.spawns["dari_desa"].y))
	var bad: Array = []
	for sp: String in village.spots.keys():
		for c: Vector2i in village.spots[sp]:
			if vblocked.has(c) or not _reachable(village, vstart, c):
				bad.append("desa/%s %s" % [sp, str(c)])
	for sp: String in clinic.spots.keys():
		for c: Vector2i in clinic.spots[sp]:
			if cblocked.has(c) or not _reachable(clinic, cstart, c):
				bad.append("klinik/%s %s" % [sp, str(c)])
	_check(bad.is_empty(), "semua titik tujuan bebas dan terjangkau (bermasalah: %s)" % str(bad))
	var doors_ok: bool = village.doors.size() == 6
	for dn: String in village.doors.keys():
		var dc: Vector2i = village.doors[dn]
		if vblocked.has(dc) or not _reachable(village, vstart, dc) or not village.spots.has(dn):
			doors_ok = false
	_check(doors_ok, "6 pintu rumah bebas, terjangkau, dan punya spot")
	_check(village.spots.size() >= 14, "desa punya >= 14 titik tujuan (%d)" % village.spots.size())
	_check(clinic.seats_of_kind("tunggu").size() == 6 and clinic.seats_of_kind("periksa").size() == 1, "klinik: 6 kursi tunggu + 1 tempat periksa")
	var seats_ok: bool = true
	for st in clinic.seats:
		var c2: Vector2i = st["cell"]
		if not cblocked.has(c2) or not _reachable(clinic, cstart, c2):
			seats_ok = false
	_check(seats_ok, "semua kursi (sel terhalang) dapat dicapai lewat izin kursi")
	# mat: jalur menuju keset ada dari kedua sisi
	var mats_ok: bool = true
	for t in village.transitions:
		for c3: Vector2i in t["cells"]:
			if not _reachable(village, vstart, c3):
				mats_ok = false
	for t in clinic.transitions:
		for c4: Vector2i in t["cells"]:
			if not _reachable(clinic, cstart, c4):
				mats_ok = false
	_check(mats_ok, "semua keset pintu dapat dicapai NPC")


# --- Roster --------------------------------------------------------------------

func _test_roster() -> void:
	var all: Array[NpcData] = NpcRoster.all()
	_check(all.size() == 8, "8 penduduk")
	var ids: Dictionary = {}
	var village: LocationData = LocationRegistry.get_location("desa")
	var ok_sched: bool = true
	var ok_spots: bool = true
	var ok_look: bool = true
	for n in all:
		ids[n.id] = true
		if n.schedule.is_empty() or int(n.schedule[0]["start"]) != 0:
			ok_sched = false
		var last: int = -1
		for e in n.schedule:
			if int(e["start"]) <= last:
				ok_sched = false
			last = int(e["start"])
			var loc: LocationData = LocationRegistry.get_location(String(e["loc"]))
			if loc == null or loc.spot_cells(String(e["spot"])).is_empty():
				ok_spots = false
		if not village.spots.has(n.home_spot):
			ok_spots = false
		var ap: CharacterAppearance = n.make_appearance()
		for slot in [OutfitItem.Slot.TOP, OutfitItem.Slot.BOTTOM]:
			if ap.item_in(slot) == null:
				ok_look = false
	_check(ids.size() == 8, "id NPC unik")
	_check(ok_sched, "jadwal berurutan dan dimulai pukul 00:00")
	_check(ok_spots, "semua spot jadwal dan rumah ada di data lokasi")
	_check(ok_look, "semua NPC punya baju dan celana valid")
	var karto: NpcData = NpcRoster.by_id("karto")
	_check(karto.goal_at(7 * 60)["spot"] == "kebun", "Karto di kebun pukul 07:00")
	_check(karto.goal_at(60)["home"] == true, "Karto di rumah pukul 01:00")
	_check(karto.goal_at(23 * 60)["home"] == true, "Karto di rumah pukul 23:00 (lanjutan)")
	var ratih: NpcData = NpcRoster.by_id("ratih")
	_check(ratih.goal_at(11 * 60)["loc"] == "klinik", "Ratih ke klinik pukul 11:00 (lintas lokasi)")
	var looks: Dictionary = {}
	for n in all:
		looks["%s" % str(n.look)] = true
	_check(looks.size() == 8, "tampilan setiap NPC berbeda")


# --- Permintaan dan dialog -----------------------------------------------------

func _test_requests_and_dialogue() -> void:
	var log := RequestLog.new()
	_check(log.status("req_salam_wiryo") == RequestLog.NONE, "permintaan awal NONE")
	_check(not log.accept("tidak_ada"), "id tak dikenal ditolak")
	_check(log.accept("req_salam_wiryo") and not log.accept("req_salam_wiryo"), "terima sekali saja")
	_check(log.notify_talk("joko").is_empty(), "bicara dengan NPC lain tidak memenuhi syarat")
	_check(log.notify_talk("wiryo") == ["req_salam_wiryo"] as Array[String] and log.status("req_salam_wiryo") == RequestLog.READY, "bicara dengan target -> READY")
	_check(log.claim("req_salam_wiryo") and log.status("req_salam_wiryo") == RequestLog.DONE, "lapor -> DONE")
	_check(not log.claim("req_salam_wiryo"), "tidak bisa lapor dua kali")
	log.accept("req_lihat_kebun")
	_check(log.notify_zone("Kebun Herbal").size() == 1 and log.status("req_lihat_kebun") == RequestLog.READY, "masuk zona -> READY")
	var d: Dictionary = log.to_dict()
	var log2 := RequestLog.new()
	log2.from_dict(d)
	_check(log2.status("req_salam_wiryo") == RequestLog.DONE and log2.status("req_lihat_kebun") == RequestLog.READY, "serialisasi bolak-balik")
	log2.from_dict({"sampah": 2, "req_kabar_joko": 99})
	_check(log2.status("sampah") == RequestLog.NONE and log2.status("req_kabar_joko") == RequestLog.DONE, "from_dict membersihkan data tak valid")

	# dialog
	Locale.set_language("id")
	var rlog := RequestLog.new()
	var karto: NpcData = NpcRoster.by_id("karto")
	var nodes: Dictionary = DialogueLibrary.build(karto, {"activity": "berkebun", "requests": rlog})
	var runner := DialogueRunner.new()
	runner.start("karto", nodes, rlog)
	_check(runner.is_active(), "dialog aktif")
	var v: Dictionary = runner.view()
	_check(v["speaker"] == "Pak Karto" and String(v["text"]).begins_with("Selamat datang"), "sapaan Indonesia + nama pembicara")
	_check(v["has_choices"] and (v["choices"] as Array).size() == 4, "pilihan: kabar, desa, bantu, pamit")
	runner.select(0)  # status
	_check(String(runner.view()["text"]).contains("merawat kebun herbal"), "status memakai aktivitas")
	runner.select(-1)  # lanjut ke sapaan
	_check(runner.node_id == DialogueLibrary.START, "node status lanjut ke sapaan")
	runner.select(1)  # tentang desa
	runner.select(-1)
	runner.select(-1)
	_check(runner.node_id == DialogueLibrary.START, "about -> about2 -> sapaan")
	runner.select(2)  # bantu
	_check(String(runner.view()["text"]).contains("Mbah Wiryo"), "permintaan menyebut target")
	runner.select(0)  # terima
	_check(rlog.status("req_salam_wiryo") == RequestLog.ACTIVE, "menerima permintaan lewat dialog")
	runner.select(-1)
	_check(not runner.is_active(), "dialog selesai setelah menerima")
	# bahasa Inggris
	Locale.set_language("en")
	var en_nodes: Dictionary = DialogueLibrary.build(karto, {"activity": "berkebun", "requests": rlog})
	var r2 := DialogueRunner.new()
	r2.start("karto", en_nodes, rlog)
	_check(String(r2.view()["text"]).begins_with("Welcome, Healer"), "sapaan English")
	Locale.set_language("id")
	# sapaan berubah: pending, lalu siap lapor
	rlog.notify_talk("wiryo")
	var n3: Dictionary = DialogueLibrary.build(karto, {"activity": "berkebun", "requests": rlog})
	var r3 := DialogueRunner.new()
	r3.start("karto", n3, rlog)
	_check(String(r3.view()["text"]).begins_with("Sudah selesai"), "sapaan saat permintaan siap lapor")
	r3.select(0)  # lapor
	_check(rlog.status("req_salam_wiryo") == RequestLog.DONE, "lapor lewat dialog -> DONE")
	# pilihan tak valid diabaikan
	var r4 := DialogueRunner.new()
	r4.start("karto", DialogueLibrary.build(karto, {"activity": "berkebun", "requests": RequestLog.new()}), RequestLog.new())
	r4.select(99)
	r4.select(-1)
	_check(r4.is_active() and r4.node_id == DialogueLibrary.START, "pilihan tak valid diabaikan")
	# NPC tanpa permintaan
	var wiryo: NpcData = NpcRoster.by_id("wiryo")
	var r5 := DialogueRunner.new()
	r5.start("wiryo", DialogueLibrary.build(wiryo, {"activity": "bersantai", "requests": RequestLog.new()}), RequestLog.new())
	_check((r5.view()["choices"] as Array).size() == 3, "NPC tanpa permintaan: 3 pilihan")
	# dialog pasien
	var r6 := DialogueRunner.new()
	r6.start("sari", DialogueLibrary.build(NpcRoster.by_id("sari"), {"activity": "menunggu_giliran", "requests": RequestLog.new(),
		"patient": {"state": "menunggu", "complaint": "batuk_kering"}}), RequestLog.new())
	_check(String(r6.view()["text"]).contains("menunggu giliran") and String(r6.view()["text"]).contains("batuk"), "dialog pasien memuat keluhan")
	# semua NPC: dialog dapat dijalankan sampai selesai tanpa error di kedua bahasa
	for lang in ["id", "en"]:
		Locale.set_language(lang)
		var all_ok: bool = true
		for n in NpcRoster.all():
			var rr := DialogueRunner.new()
			var rl := RequestLog.new()
			rr.start(n.id, DialogueLibrary.build(n, {"activity": "bersantai", "requests": rl}), rl)
			var guard: int = 0
			while rr.is_active() and guard < 40:
				var vv: Dictionary = rr.view()
				if String(vv["text"]) == "" or String(vv["text"]).begins_with("dlg.") or String(vv["text"]).contains("{"):
					all_ok = false
				rr.select(-1 if not vv["has_choices"] else (vv["choices"] as Array).size() - 1)
				guard += 1
			if rr.is_active():
				all_ok = false
		_check(all_ok, "semua dialog NPC selesai dan teks terlokalisasi (%s)" % lang)
	Locale.set_language("id")


# --- Antrean -------------------------------------------------------------------

func _test_queue() -> void:
	var q := ClinicQueue.new()
	var a := PatientRecord.new()
	var b := PatientRecord.new()
	var c := PatientRecord.new()
	a.npc_id = "a"
	b.npc_id = "b"
	c.npc_id = "c"
	for p in [a, b, c]:
		q.add(p)
	_check(q.register(a) == 1 and q.register(b) == 2 and q.register(c) == 3, "nomor antrean berurutan")
	_check(q.waiting_count() == 3, "3 di antrean")
	_check(q.peek_next() == null, "yang terdepan belum duduk -> belum dipanggil")
	b.state = PatientRecord.State.MENUNGGU
	_check(q.peek_next() == null, "urutan tidak dilompati")
	a.state = PatientRecord.State.MENUNGGU
	c.state = PatientRecord.State.MENUNGGU
	var first: PatientRecord = q.call_next()
	_check(first == a and a.state == PatientRecord.State.DIPANGGIL, "nomor 1 dipanggil dulu")
	_check(q.room_busy() and q.call_next() == null, "ruang terisi -> tidak bisa memanggil lagi")
	_check(q.waiting_count() == 2, "yang dipanggil keluar dari antrean")
	a.state = PatientRecord.State.SELESAI
	a.done = true
	_check(not q.room_busy() and q.call_next() == b, "ruang kosong -> nomor 2")
	q.new_day()
	_check(q.next_ticket == 1, "nomor antrean direset tiap hari")
	_check(q.for_npc("c") == c and q.for_npc("a") == null, "for_npc hanya pasien aktif")
	var diag := DiagnosisRecord.new()
	_check(not diag.is_diagnosed() and diag.to_dict()["treatments"].is_empty(), "struktur diagnosis kosong siap dipakai")
	var t := TreatmentRecord.new()
	_check(t.status == "belum", "struktur perawatan awal")


# --- Simulasi: jadwal ----------------------------------------------------------

func _make_sim(hour: int = 7, minute: int = 0) -> NpcSimulation:
	var clock := GameClock.new()
	clock.set_time(1, hour, minute)
	var sim := NpcSimulation.new()
	sim.setup(NpcRoster.all(), clock)
	return sim


func _test_sim_schedule_snap() -> void:
	var sim: NpcSimulation = _make_sim(7, 0)
	var indoors: int = 0
	var placed_ok: bool = true
	for a in sim.agents:
		if a.loc == "":
			indoors += 1
			continue
		var goal: Dictionary = a.data.goal_at(7 * 60)
		var cells: Array = LocationRegistry.get_location(String(goal["loc"])).spot_cells(String(goal["spot"]))
		if a.loc != goal["loc"] or not cells.has(a.cell):
			placed_ok = false
	_check(placed_ok, "pukul 07:00 NPC di luar rumah berada di spot jadwalnya")
	_check(indoors >= 1 and indoors < 8, "pukul 07:00 sebagian NPC di rumah (%d)" % indoors)
	var sim2: NpcSimulation = _make_sim(2, 0)
	_check(sim2.agents_in("desa").is_empty() and sim2.agents_in("klinik").is_empty(), "pukul 02:00 semua NPC di dalam rumah")
	var sim3: NpcSimulation = _make_sim(11, 0)
	_check(sim3.agent("ratih").loc == "klinik", "pukul 11:00 Ratih di klinik")


func _scan_invariants(sim: NpcSimulation, tag: String, report: Dictionary) -> void:
	var seen: Dictionary = {}
	for a in sim.agents:
		if a.loc == "":
			continue
		var key: String = "%s:%d,%d" % [a.loc, a.cell.x, a.cell.y]
		if seen.has(key):
			report["overlap"] += 1
			if report["first_overlap"] == "":
				report["first_overlap"] = "%s %s & %s" % [tag, key, seen[key]]
		seen[key] = a.id
		var pf: GridPathfinder = sim.navigation(a.loc)
		var loc: LocationData = LocationRegistry.get_location(a.loc)
		if pf.blocked.has(a.cell) and not loc.is_seat(a.cell):
			report["in_blocked"] += 1
			if report["first_blocked"] == "":
				report["first_blocked"] = "%s %s %s" % [tag, a.id, str(a.cell)]
		if not pf.in_bounds(a.cell):
			report["out_bounds"] += 1
		var occ: Dictionary = sim.occupied_cells(a.loc)
		if occ.get(a.cell, "") != a.id:
			report["occ_mismatch"] += 1
			if report["first_mismatch"] == "":
				report["first_mismatch"] = "%s %s %s" % [tag, a.id, str(a.cell)]


func _test_sim_long_run() -> void:
	var sim: NpcSimulation = _make_sim(7, 0)
	var report: Dictionary = {"overlap": 0, "in_blocked": 0, "out_bounds": 0, "occ_mismatch": 0,
		"first_overlap": "", "first_blocked": "", "first_mismatch": ""}
	var unproductive: Dictionary = {}
	var max_unprod: Dictionary = {}
	var visits: Dictionary = {}       # id -> set lokasi yang pernah dikunjungi
	var seen_loc_change: Array = [0]
	sim.agent_location_changed.connect(func(_id: String, _f: String, to_loc: String) -> void:
		seen_loc_change[0] += 1
		if to_loc != "":
			visits[to_loc] = true)
	# pemain berdiri di alun-alun sepanjang waktu
	sim.set_player("desa", Vector2(23.5, 16.5))
	var player_cells: Dictionary = {}
	for x in [22, 23, 24]:
		for y in [15, 16, 17]:
			player_cells[Vector2i(x, y)] = true
	var player_hits: int = 0
	var sched_checks: int = 0
	var sched_good: int = 0
	var steps: int = int(3.0 * 1440.0 / 0.5)  # 3 hari permainan, langkah 0,5 detik
	for i in range(steps):
		sim.update(0.5)
		if i % 4 == 0:
			_scan_invariants(sim, "t=%d" % i, report)
		for a in sim.agents:
			if a.loc == "" or a.moving or a.arrived or a.talking:
				unproductive[a.id] = 0.0
			else:
				unproductive[a.id] = float(unproductive.get(a.id, 0.0)) + 0.5
				max_unprod[a.id] = maxf(float(max_unprod.get(a.id, 0.0)), float(unproductive[a.id]))
			if a.loc == "desa" and player_cells.has(a.cell):
				player_hits += 1
		# periksa kepatuhan jadwal pada jam tertentu (30 menit setelah entri berganti, saat sudah sempat berjalan)
		var m: int = sim.clock.minute()
		if i % 2 == 0 and m % 60 == 30:
			for a in sim.agents:
				var goal: Dictionary = a.data.goal_at(m - 30)  # tujuan yang sudah berlaku >= 30 menit
				var now_goal: Dictionary = a.data.goal_at(m)
				if goal["key"] != now_goal["key"]:
					continue  # tujuan baru saja berganti
				sched_checks += 1
				if goal["home"]:
					if a.loc == "":
						sched_good += 1
				elif a.loc == goal["loc"]:
					sched_good += 1
	_check(report["overlap"] == 0, "3 hari: tidak pernah dua NPC di sel yang sama (%d, %s)" % [report["overlap"], report["first_overlap"]])
	_check(report["in_blocked"] == 0, "3 hari: NPC tidak pernah di sel terhalang (%d, %s)" % [report["in_blocked"], report["first_blocked"]])
	_check(report["out_bounds"] == 0, "3 hari: NPC tidak keluar batas peta")
	_check(report["occ_mismatch"] == 0, "3 hari: peta hunian selalu sinkron (%d, %s)" % [report["occ_mismatch"], report["first_mismatch"]])
	_check(player_hits == 0, "NPC tidak pernah masuk ke sel pemain (%d)" % player_hits)
	var worst: float = 0.0
	for k in max_unprod.keys():
		worst = maxf(worst, float(max_unprod[k]))
	_check(worst <= 30.0, "tidak ada NPC macet lebih dari 30 detik (terburuk %.1f dtk)" % worst)
	_check(seen_loc_change[0] > 50, "NPC keluar-masuk rumah dan klinik (%d perpindahan)" % seen_loc_change[0])
	_check(visits.has("klinik") and visits.has("desa"), "NPC berjalan lintas lokasi desa <-> klinik")
	_check(sched_checks > 20 and float(sched_good) / float(sched_checks) >= 0.9, "jadwal harian dipatuhi >= 90%% (%d/%d)" % [sched_good, sched_checks])
	_check(int(sim.stats["evasions"]) < 40, "jumlah menepi (evade) wajar dalam 3 hari (%d)" % int(sim.stats["evasions"]))
	print("  info  statistik simulasi 3 hari: ", sim.stats)


# --- Simulasi: dihalangi pemain ------------------------------------------------

func _test_sim_blocked_by_player() -> void:
	var sim: NpcSimulation = _make_sim(11, 0)
	var ratih: NpcAgent = sim.agent("ratih")
	var clinic: LocationData = LocationRegistry.get_location("klinik")
	var exam: Vector2i = clinic.seats_of_kind("periksa")[0]["cell"]
	# tutup jalan memutar (celah sekat peracikan) pada salinan navigasi simulasi saja
	var nav: GridPathfinder = sim.navigation("klinik")
	nav.blocked[Vector2i(10, 3)] = true
	nav.blocked[Vector2i(10, 4)] = true
	sim.set_override("ratih", NpcGoal.at_cell("klinik", exam, true, "diperiksa"))
	# pemain menutup celah sekat (x=5..6 pada y=6): ruang periksa tak bisa dicapai
	sim.set_player("klinik", Vector2(6.0, 6.5))
	var ok_cells: bool = true
	for _i in range(200):
		sim.update(0.5)
		sim.set_player("klinik", Vector2(6.0, 6.5))
		if ratih.loc == "klinik" and nav.blocked.has(ratih.cell) and not clinic.is_seat(ratih.cell):
			ok_cells = false
	_check(ok_cells, "NPC terhalang tidak menembus dinding")
	_check(ratih.cell != exam and ratih.cell.y > 6, "NPC tidak menembus pemain; tetap di sisi penerimaan")
	_check(int(sim.stats["failed_plans"]) + int(sim.stats["evasions"]) + int(sim.stats["waits"]) > 0, "terhalang -> tugas dibatalkan/menunggu/menepi (stats %s)" % str(sim.stats))
	_check(ratih.state != NpcAgent.INDOORS and ratih.loc == "klinik", "NPC tidak hilang atau terlempar saat terhalang")
	# pemain pergi, jalan dibuka: NPC akhirnya sampai dan duduk
	nav.blocked.erase(Vector2i(10, 3))
	nav.blocked.erase(Vector2i(10, 4))
	sim.set_player("klinik", Vector2(13.5, 10.5))
	for _i in range(400):
		sim.update(0.5)
		if ratih.cell == exam:
			break
	_check(ratih.cell == exam and ratih.sitting, "setelah pemain pergi, NPC mencapai tempat periksa dan duduk")


# --- Pasien --------------------------------------------------------------------

func _run_until(sim: NpcSimulation, ps: PatientSystem, max_sec: float, cond: Callable) -> bool:
	var t: float = 0.0
	while t < max_sec:
		sim.update(0.5)
		ps.update(0.5)
		t += 0.5
		if cond.call():
			return true
	return false


func _make_patient_sim(hour: int = 8, minute: int = 0) -> Array:
	var sim: NpcSimulation = _make_sim(hour, minute)
	var ps := PatientSystem.new()
	ps.setup(sim, sim.clock)
	ps.auto_call = false
	return [sim, ps]


func _test_patient_flow() -> void:
	var pair: Array = _make_patient_sim(8, 0)
	var sim: NpcSimulation = pair[0]
	var ps: PatientSystem = pair[1]
	var events: Array = []
	ps.patient_event.connect(func(kind: String, p: PatientRecord) -> void: events.append("%s:%s" % [kind, p.npc_id]))
	# cegah rencana otomatis ikut campur: tandai semua rencana hari ini sudah dimulai
	ps.update(0.0)
	for e in ps.planned():
		e["started"] = true
	var p: PatientRecord = ps.start_visit("sari", "demam_dingin")
	_check(p != null and p.state == PatientRecord.State.MENUJU and p.npc_id == "sari", "kunjungan dimulai (MENUJU)")
	_check(ps.start_visit("sari", "batuk_kering") == null, "tidak bisa dua kunjungan bersamaan")
	_check(ps.start_visit("tidak_ada", "batuk_kering") == null, "NPC tak dikenal ditolak")
	var seated: bool = _run_until(sim, ps, 1500.0, func() -> bool: return p.state == PatientRecord.State.MENUNGGU)
	_check(seated, "pasien berjalan ke klinik, mendaftar, dan duduk menunggu")
	var agent: NpcAgent = sim.agent("sari")
	_check(p.ticket == 1, "nomor antrean 1")
	_check(agent.loc == "klinik" and agent.sitting, "pasien duduk di klinik")
	var clinic: LocationData = LocationRegistry.get_location("klinik")
	_check(clinic.seats_of_kind("tunggu").any(func(st: Dictionary) -> bool: return st["cell"] == agent.cell), "pasien duduk di kursi tunggu")
	_check(ps.queue.waiting_count() == 1 and ps.queue.peek_next() == p, "antrean 1 menunggu")
	_check(ps.finish_exam() == null, "belum ada yang diperiksa")
	var called: PatientRecord = ps.call_next()
	_check(called == p and p.state == PatientRecord.State.DIPANGGIL, "dipanggil")
	var exam_cell: Vector2i = clinic.seats_of_kind("periksa")[0]["cell"]
	var in_exam: bool = _run_until(sim, ps, 300.0, func() -> bool: return p.state == PatientRecord.State.DIPERIKSA)
	_check(in_exam and agent.cell == exam_cell and agent.sitting, "pasien berjalan ke ruang periksa dan duduk di tempat periksa")
	_check(ps.queue.room_busy(), "ruang periksa terisi")
	var done_p: PatientRecord = ps.finish_exam()
	_check(done_p == p and p.state == PatientRecord.State.SELESAI, "pemeriksaan selesai (placeholder)")
	var home: bool = _run_until(sim, ps, 1500.0, func() -> bool: return p.done)
	_check(home, "pasien pulang ke rumah dan kunjungan berakhir")
	_check(agent.override_goal.is_empty() and ps.completed_count == 1, "override dibersihkan, 1 pasien selesai")
	_check(ps.patient_for("sari") == null, "tidak lagi tercatat sebagai pasien aktif")
	_check(events.has("arrived:sari") and events.has("registered:sari") and events.has("seated:sari") and events.has("called:sari") and events.has("exam_started:sari") and events.has("exam_done:sari") and events.has("left:sari"), "semua peristiwa pasien terkirim (%s)" % str(events))
	# kunjungan jalur otomatis (auto_call)
	var pair2: Array = _make_patient_sim(9, 0)
	var sim2: NpcSimulation = pair2[0]
	var ps2: PatientSystem = pair2[1]
	ps2.auto_call = true
	ps2.update(0.0)
	for e in ps2.planned():
		e["started"] = true
	var p2: PatientRecord = ps2.start_visit("joko", "mata_perih")
	var finished: bool = _run_until(sim2, ps2, 4000.0, func() -> bool: return p2.done)
	_check(finished and p2.state == PatientRecord.State.SELESAI and ps2.completed_count == 1, "auto_call: panggil, periksa, dan pulang otomatis")


func _test_patient_crowd() -> void:
	var pair: Array = _make_patient_sim(8, 0)
	var sim: NpcSimulation = pair[0]
	var ps: PatientSystem = pair[1]
	ps.update(0.0)
	for e in ps.planned():
		e["started"] = true
	var recs: Array[PatientRecord] = []
	var i: int = 0
	for id in NpcRoster.ids():
		recs.append(ps.start_visit(id, ComplaintCatalog.IDS[i]))
		i += 1
	var report: Dictionary = {"overlap": 0, "in_blocked": 0, "out_bounds": 0, "occ_mismatch": 0,
		"first_overlap": "", "first_blocked": "", "first_mismatch": ""}
	var t: float = 0.0
	var all_in: bool = false
	while t < 1500.0:
		sim.update(0.5)
		ps.update(0.5)
		t += 0.5
		_scan_invariants(sim, "crowd t=%.1f" % t, report)
		var n_wait: int = 0
		for r in recs:
			if r.state == PatientRecord.State.MENUNGGU:
				n_wait += 1
		if n_wait == 8:
			all_in = true
			break
	_check(all_in, "8 pasien sekaligus semuanya mendaftar dan menunggu (%.0f dtk)" % t)
	_check(report["overlap"] == 0 and report["in_blocked"] == 0 and report["occ_mismatch"] == 0, "kerumunan: tanpa tumpukan/sel terhalang/hunian rusak (%s %s %s)" % [report["first_overlap"], report["first_blocked"], report["first_mismatch"]])
	var tickets: Array = []
	for r in recs:
		tickets.append(r.ticket)
	tickets.sort()
	_check(tickets == [1, 2, 3, 4, 5, 6, 7, 8], "nomor antrean 1..8 unik (%s)" % str(tickets))
	var seated: int = 0
	var standing: int = 0
	for r in recs:
		var a: NpcAgent = sim.agent(r.npc_id)
		if a.sitting:
			seated += 1
		else:
			standing += 1
	_check(seated == 6 and standing == 2, "6 duduk, 2 berdiri (%d/%d)" % [seated, standing])
	# panggil satu; satu kursi kosong -> yang berdiri pindah duduk
	var called: PatientRecord = ps.call_next()
	_check(called != null and called.ticket == 1, "nomor 1 dipanggil lebih dulu")
	var moved: bool = _run_until(sim, ps, 600.0, func() -> bool:
		var s: int = 0
		for r in recs:
			if r.state == PatientRecord.State.MENUNGGU and sim.agent(r.npc_id).sitting:
				s += 1
		return s == 6 and called.state == PatientRecord.State.DIPERIKSA)
	_check(moved, "kursi kosong diisi pasien yang berdiri, nomor 1 di ruang periksa")


func _test_patient_giveup_and_close() -> void:
	var pair: Array = _make_patient_sim(8, 0)
	var sim: NpcSimulation = pair[0]
	var ps: PatientSystem = pair[1]
	ps.update(0.0)
	for e in ps.planned():
		e["started"] = true
	var p: PatientRecord = ps.start_visit("dewi", "gatal_kulit")
	_run_until(sim, ps, 1500.0, func() -> bool: return p.state == PatientRecord.State.MENUNGGU)
	_check(p.state == PatientRecord.State.MENUNGGU, "siap menunggu")
	var gave: Array = [0]
	ps.patient_event.connect(func(kind: String, _p: PatientRecord) -> void:
		if kind == "gave_up":
			gave[0] += 1)
	sim.clock.set_time(sim.clock.day, 10, 30)
	p.waiting_since = sim.clock.absolute_minutes() - (PatientSystem.PATIENCE_MIN + 5.0)
	ps.update(0.5)
	_check(p.state == PatientRecord.State.BATAL and gave[0] == 1 and ps.gave_up_count == 1, "menunggu terlalu lama -> pulang tanpa berobat")
	var left: bool = _run_until(sim, ps, 1500.0, func() -> bool: return p.done)
	_check(left and sim.agent("dewi").override_goal.is_empty(), "pasien yang menyerah tetap pulang dan override dibersihkan")
	# klinik tutup: yang masih mengantre pulang
	var pair2: Array = _make_patient_sim(15, 0)
	var sim2: NpcSimulation = pair2[0]
	var ps2: PatientSystem = pair2[1]
	ps2.update(0.0)
	for e in ps2.planned():
		e["started"] = true
	var p2: PatientRecord = ps2.start_visit("raka", "lelah_berat")
	_run_until(sim2, ps2, 1200.0, func() -> bool: return p2.state == PatientRecord.State.MENUNGGU)
	_check(p2.state == PatientRecord.State.MENUNGGU, "pasien menunggu sebelum tutup")
	sim2.clock.set_time(sim2.clock.day, 16, 1)
	ps2.update(0.5)
	_check(p2.state == PatientRecord.State.BATAL and not ps2.is_open(), "klinik tutup 16:00 -> antrean bubar")


func _test_plan() -> void:
	var ids: Array[String] = NpcRoster.ids()
	var ok: bool = true
	for day in range(1, 15):
		var plan: Array[Dictionary] = PatientSystem.plan_for_day(day, ids)
		var again: Array[Dictionary] = PatientSystem.plan_for_day(day, ids)
		if plan.size() < 3 or plan.size() > 5 or str(plan) != str(again):
			ok = false
		var seen: Dictionary = {}
		var last: int = -1
		for e in plan:
			if seen.has(e["npc"]) or int(e["minute"]) < PatientSystem.FIRST_ARRIVAL_MIN or int(e["minute"]) > PatientSystem.LAST_ARRIVAL_MIN or int(e["minute"]) <= last:
				ok = false
			if not ComplaintCatalog.has(String(e["complaint"])):
				ok = false
			seen[e["npc"]] = true
			last = int(e["minute"])
	_check(ok, "rencana pasien harian: 3-5 pasien, unik, berurutan, jam buka, deterministik (14 hari)")
