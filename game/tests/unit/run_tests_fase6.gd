extends SceneTree
## Tes unit Fase 6: ekonomi (buku kas, toko, biaya), upgrade klinik + efeknya pada sistem Fase 5,
## SaveSystem (bolak-balik, hilang, rusak, cadangan, versi), dan keseimbangan kemajuan (pacing).
## Jalankan: godot --headless --path game -s res://tests/unit/run_tests_fase6.gd

const TEST_DIR: String = "user://tes_fase6"

var _count: int = 0
var _fail: int = 0


func _init() -> void:
	SaveSystem.override_dir = TEST_DIR
	SaveSystem.delete_all()
	_test_economy_db()
	_test_ledger()
	_test_shop()
	_test_upgrades_rules()
	_test_upgrade_effects()
	_test_save_roundtrip()
	_test_save_failures()
	_test_sanitize_and_apply()
	_test_pacing()
	_test_localization()
	SaveSystem.delete_all()
	print("Tes Fase 6 dijalankan: %d, gagal: %d" % [_count, _fail])
	quit(1 if _fail > 0 else 0)


func _check(condition: bool, name: String) -> void:
	_count += 1
	if condition:
		print("  OK   ", name)
	else:
		_fail += 1
		printerr("  GAGAL ", name)


# --- Ekonomi ------------------------------------------------------------------

func _test_economy_db() -> void:
	var ok: bool = true
	for id in HerbDb.IDS:
		if EconomyDb.buy_price(id) <= 0 or EconomyDb.sell_price(id) <= 0 or EconomyDb.sell_price(id) >= EconomyDb.buy_price(id):
			ok = false
	_check(ok, "semua bahan berharga; harga jual < harga beli (tanpa arbitrase)")
	_check(EconomyDb.buy_price("tidak_ada") == 0 and EconomyDb.sell_price("tidak_ada") == 0, "bahan tak dikenal tak berharga")
	var cheap: int = 999
	for id in HerbDb.IDS:
		cheap = mini(cheap, EconomyDb.buy_price(id))
	_check(EconomyDb.START_MONEY >= cheap * 5, "modal awal cukup membeli beberapa bahan")
	var ids: Array[String] = []
	var uniq: bool = true
	for m in EconomyDb.MILESTONES:
		if ids.has(String(m["id"])):
			uniq = false
		ids.append(String(m["id"]))
	_check(uniq and ids.size() >= 5, "capaian unik")


func _test_ledger() -> void:
	var cs := ClinicStats.new()
	var events: Array = []
	cs.money_changed.connect(func(d: int, r: String, t: int) -> void: events.append([d, r, t]))
	cs.add_money(50, "pasien")
	_check(cs.money == 50 and events.size() == 1 and events[0] == [50, "pasien", 50], "add_money menambah & memancarkan sinyal")
	cs.add_money(0, "x")
	cs.add_money(-5, "x")
	_check(cs.money == 50 and events.size() == 1, "jumlah <= 0 diabaikan")
	_check(not cs.spend(80, "beli:kunyit") and cs.money == 50 and events.size() == 1, "belanja melebihi uang ditolak tanpa efek")
	_check(cs.spend(30, "beli:kunyit") and cs.money == 20 and cs.total_spent == 30 and cs.total_earned == 50, "belanja mengurangi uang & total tercatat")
	_check(cs.ledger.size() == 2 and int(cs.ledger[1]["delta"]) == -30 and int(cs.ledger[1]["total"]) == 20, "buku kas mencatat delta & saldo")
	_check(cs.charge_up_to(100, "operasional") == 20 and cs.money == 0, "biaya operasional dipotong sebatas uang (tidak minus)")
	_check(cs.charge_up_to(100, "operasional") == 0 and cs.money == 0, "uang 0: biaya tak membuat minus")
	for i in range(60):
		cs.add_money(1, "pasien")
	_check(cs.ledger.size() == ClinicStats.LEDGER_MAX, "buku kas dibatasi %d catatan" % ClinicStats.LEDGER_MAX)
	# kunjungan memakai buku kas
	var cs2 := ClinicStats.new()
	cs2.record_visit({"fee": 40, "grade": 3, "satisfaction": 80.0, "outcome": "sembuh"})
	_check(cs2.money == 40 and cs2.ledger.size() == 1 and String(cs2.ledger[0]["reason"]) == "pasien", "bayaran pasien masuk buku kas")
	# capaian: sekali saja
	var got: Array[String] = cs2.check_milestones()
	_check(got.has("pasien_1") and got.has("sembuh_1") and cs2.money == 40 + 20 + 30, "capaian pertama memberi koin")
	_check(cs2.check_milestones().is_empty() and cs2.money == 90, "capaian tidak diberikan dua kali")
	# serialisasi
	var back := ClinicStats.new()
	back.from_dict(JSON.parse_string(JSON.stringify(cs2.to_dict())))
	_check(back.money == cs2.money and back.treated == 1 and back.cured == 1 and back.reputation == cs2.reputation \
		and back.milestones_done.size() == cs2.milestones_done.size() and back.ledger.size() == cs2.ledger.size(), "ClinicStats bolak-balik lewat JSON")
	var bad := ClinicStats.new()
	bad.from_dict({"money": -50, "reputation": 900, "treated": -3, "cured": 99, "ledger": "x"})
	_check(bad.money == 0 and bad.reputation == 100.0 and bad.treated == 0 and bad.cured == 0 and bad.ledger.is_empty(), "data aneh dibatasi (uang>=0, reputasi 0..100)")


func _test_shop() -> void:
	var cs := ClinicStats.new()
	cs.money = 30
	var inv := HerbInventory.new()
	var shop := ClinicShop.new()
	shop.setup(cs, inv)
	var kunyit0: int = inv.count("kunyit")
	var r: Dictionary = shop.buy("kunyit", 2)
	_check(bool(r["ok"]) and cs.money == 30 - 2 * EconomyDb.buy_price("kunyit") and inv.count("kunyit") == kunyit0 + 2, "beli 2 kunyit: koin turun, stok naik")
	var m1: int = cs.money
	r = shop.buy("kayu_manis", 5)
	_check(not bool(r["ok"]) and String(r["reason"]) == "money" and cs.money == m1, "koin kurang: pembelian ditolak tanpa efek")
	_check(not bool(shop.buy("tak_ada", 1)["ok"]) and not bool(shop.buy("kunyit", 0)["ok"]), "bahan/jumlah tak valid ditolak")
	var before: int = cs.money
	var s: Dictionary = shop.sell("kunyit", 1)
	_check(bool(s["ok"]) and cs.money == before + EconomyDb.sell_price("kunyit") and inv.count("kunyit") == kunyit0 + 1, "jual 1 kunyit")
	var empty := HerbInventory.new()
	empty.stock["jahe"] = 0
	var sh2 := ClinicShop.new()
	sh2.setup(cs, empty)
	_check(not bool(sh2.sell("jahe", 1)["ok"]), "jual tanpa stok ditolak")
	# beli lalu jual tidak boleh untung
	cs.money = 100
	for i in range(20):
		shop.buy("jahe", 1)
		shop.sell("jahe", 1)
	_check(cs.money < 100, "beli-jual berulang merugi (uang %d)" % cs.money)


# --- Upgrade --------------------------------------------------------------------

func _test_upgrades_rules() -> void:
	var up := ClinicUpgrades.new()
	var cs := ClinicStats.new()
	var sk := SkillProgressionSystem.new()
	_check(up.total_levels() == 0 and up.operating_cost() == EconomyDb.BASE_OPERATING_COST, "awal: tanpa upgrade, biaya dasar")
	var defs_ok: bool = true
	for id in ClinicUpgrades.IDS:
		if not ClinicUpgrades.has(id) or ClinicUpgrades.max_level(id) < 2:
			defs_ok = false
		var prev: int = 0
		for l in (ClinicUpgrades.DEFS[id]["levels"] as Array):
			if int(l["cost"]) <= prev:
				defs_ok = false
			prev = int(l["cost"])
	_check(defs_ok, "6 upgrade punya tingkat dengan biaya naik")
	var r: Dictionary = up.check("lentera", cs, sk)
	_check(not bool(r["ok"]) and String(r["reason"]) == "money", "uang kurang -> alasan 'money'")
	cs.money = 1000
	cs.reputation = 10.0
	_check(String(up.check("lentera", cs, sk)["reason"]) == "rep", "reputasi kurang -> alasan 'rep'")
	cs.reputation = 50.0
	_check(String(up.check("jarum_perak", cs, sk)["reason"]) == "skill", "skill kurang -> alasan 'skill'")
	sk.add_xp("akupunktur", 100)
	_check(bool(up.check("jarum_perak", cs, sk)["ok"]), "syarat terpenuhi -> bisa beli")
	var m0: int = cs.money
	r = up.buy("jarum_perak", cs, sk)
	_check(bool(r["ok"]) and up.level("jarum_perak") == 1 and cs.money == m0 - 180, "beli jarum perak: tingkat 1, koin -180")
	_check(String(up.check("jarum_perak", cs, sk)["reason"]) == "skill", "tingkat 2 butuh akupunktur 3")
	var m1: int = cs.money
	r = up.buy("jarum_perak", cs, sk)
	_check(not bool(r["ok"]) and up.level("jarum_perak") == 1 and cs.money == m1, "beli gagal -> tak ada efek samping")
	sk.add_xp("akupunktur", 400)
	cs.money = 1000
	up.buy("jarum_perak", cs, sk)
	_check(up.is_max("jarum_perak") and String(up.check("jarum_perak", cs, sk)["reason"]) == "max" and up.next_cost("jarum_perak") == -1, "tingkat maksimum tercapai & tak bisa dibeli lagi")
	_check(up.operating_cost() == EconomyDb.BASE_OPERATING_COST + 2 * EconomyDb.COST_PER_UPGRADE_LEVEL, "biaya harian naik per tingkat upgrade")
	var back := ClinicUpgrades.new()
	back.from_dict(JSON.parse_string(JSON.stringify(up.to_dict())))
	_check(back.level("jarum_perak") == 2, "upgrade bolak-balik lewat JSON")
	back.from_dict({"lentera": 99, "lumpang": -4, "tak_dikenal": 3})
	_check(back.level("lentera") == 2 and back.level("lumpang") == 0, "tingkat aneh dibatasi")


func _make_world(hour: int = 8) -> Array:
	var clock := GameClock.new()
	clock.set_time(1, hour, 0)
	var sim := NpcSimulation.new()
	sim.setup(NpcRoster.all(), clock)
	var ps := PatientSystem.new()
	ps.setup(sim, clock)
	ps.auto_call = false
	ps.auto_exam = false
	ps.suppress_plan()
	var tm := TreatmentManager.new()
	tm.setup(ps, SkillProgressionSystem.new(), HerbInventory.new(), ClinicStats.new())
	tm.upgrades = ClinicUpgrades.new()
	return [sim, ps, tm]


func _bring_to_exam(sim: NpcSimulation, ps: PatientSystem, npc: String, complaint: String) -> PatientRecord:
	var p: PatientRecord = ps.start_visit(npc, complaint)
	var t: float = 0.0
	while p.state != PatientRecord.State.MENUNGGU and t < 1500.0:
		sim.update(0.5)
		ps.update(0.5)
		t += 0.5
	ps.call_next()
	t = 0.0
	while p.state != PatientRecord.State.DIPERIKSA and t < 400.0:
		sim.update(0.5)
		ps.update(0.5)
		t += 0.5
	return p


func _finish_diagnosis(tm: TreatmentManager, p: PatientRecord) -> void:
	var s: TreatmentSession = tm.session_for(p)
	var d: DiagnosisSystem = tm.begin_diagnosis(p)
	d.observe()
	d.submit(s.true_ailment)
	tm.complete_diagnosis(p, d)


func _test_upgrade_effects() -> void:
	# Lentera -> energi diagnosis
	var w: Array = _make_world()
	var tm: TreatmentManager = w[2]
	var p: PatientRecord = _bring_to_exam(w[0], w[1], "sari", "demam_dingin")
	var base_e: int = int(SkillDb.effect("diagnosis", "energi", 1))
	var d0: DiagnosisSystem = tm.begin_diagnosis(p)
	_check(d0.energy_max == base_e and d0.energy_left == base_e, "tanpa lentera: energi dasar %d" % base_e)
	tm.session_for(p).stage = TreatmentSession.Stage.DIAGNOSIS
	tm.upgrades.levels["lentera"] = 2
	var d1: DiagnosisSystem = tm.begin_diagnosis(p)
	_check(d1.energy_max == base_e + 2 and d1.energy_left == base_e + 2, "lentera tingkat 2: energi +2")
	# Lumpang -> toleransi takaran (jalur ramuan)
	var w2: Array = _make_world()
	var tm2: TreatmentManager = w2[2]
	var p2: PatientRecord = _bring_to_exam(w2[0], w2[1], "sari", "demam_dingin")
	_finish_diagnosis(tm2, p2)
	var herb_only: Array[String] = ["herbal"]
	tm2.choose_methods(p2, herb_only)
	var rid: String = tm2.recipes_available()[0]
	var h0: HerbalCraftingSystem = tm2.begin_crafting(p2, rid)
	var tol0: float = h0.measure_tolerance()
	tm2.upgrades.levels["lumpang"] = 2
	var h1: HerbalCraftingSystem = tm2.begin_crafting(p2, rid)
	_check(is_equal_approx(h1.measure_tolerance(), tol0 * 1.2), "lumpang tingkat 2: toleransi takaran x1,2 (%.4f -> %.4f)" % [tol0, h1.measure_tolerance()])
	# Jarum perak -> radius bidik
	var w3: Array = _make_world()
	var tm3: TreatmentManager = w3[2]
	var p3: PatientRecord = _bring_to_exam(w3[0], w3[1], "sari", "demam_dingin")
	_finish_diagnosis(tm3, p3)
	var acu_only: Array[String] = ["akupunktur"]
	tm3.choose_methods(p3, acu_only)
	var a0: AcupunctureSystem = tm3.begin_acupuncture(p3)
	var r0: float = a0.target_radius()
	tm3.upgrades.levels["jarum_perak"] = 2
	var a1: AcupunctureSystem = tm3.begin_acupuncture(p3)
	_check(is_equal_approx(a1.target_radius(), r0 + 0.04) and a1.target_radius() > r0, "jarum perak tingkat 2: radius bidik +0,04")
	# Rak besar -> stok harian
	var inv := HerbInventory.new()
	var up := ClinicUpgrades.new()
	for id in HerbDb.IDS:
		inv.stock[id] = 0
	up.levels["rak_besar"] = 2
	inv.daily_min = up.herb_daily_min()
	inv.restock_daily()
	_check(inv.count("kunyit") == HerbInventory.DAILY_MIN + 2, "rak besar tingkat 2: stok harian min %d" % (HerbInventory.DAILY_MIN + 2))
	# Ruang tunggu & kebun
	up.levels["ruang_tunggu"] = 2
	up.levels["kebun"] = 1
	_check(is_equal_approx(up.wait_penalty_mult(), 0.4) and up.harvest_bonus() == 1, "ruang tunggu tingkat 2: penalti x0,4; kebun +1 panen")
	var sat_gain: bool = true
	var base_pen: float = 20.0
	if base_pen * up.wait_penalty_mult() >= base_pen:
		sat_gain = false
	_check(sat_gain, "ruang tunggu mengurangi penalti menunggu")


# --- Simpan -----------------------------------------------------------------------

func _sample_state() -> Array:
	var clock := GameClock.new()
	clock.set_time(7, 14, 30)
	var cs := ClinicStats.new()
	cs.day_now = 7
	cs.money = 321
	cs.reputation = 47.5
	cs.record_visit({"fee": 44, "grade": 3, "satisfaction": 77.0, "outcome": "sembuh"})
	cs.check_milestones()
	var sk := SkillProgressionSystem.new()
	sk.add_xp("diagnosis", 170)
	sk.add_xp("peracikan", 61)
	sk.learn_plant("kunyit")
	sk.learn_plant("sirih")
	var inv := HerbInventory.new()
	inv.stock["jahe"] = 9
	inv.stock["kayu_manis"] = 0
	var gd := GardenSystem.new()
	gd.mark_done("garden_plot_1", 7)
	var up := ClinicUpgrades.new()
	up.levels["lentera"] = 1
	up.levels["rak_besar"] = 2
	return [clock, cs, sk, inv, gd, up]


func _test_save_roundtrip() -> void:
	_check(not SaveSystem.enabled(), "penyimpanan otomatis mati saat tes headless")
	_check(SaveSystem.read()["status"] == SaveSystem.Status.MISSING, "berkas belum ada -> MISSING")
	var st: Array = _sample_state()
	var data: Dictionary = SaveSystem.collect(st[0], "klinik", st[1], st[2], st[3], st[4], st[5])
	_check(SaveSystem.write(data) and SaveSystem.exists(), "tulis simpanan")
	var r: Dictionary = SaveSystem.read()
	_check(r["status"] == SaveSystem.Status.OK, "baca simpanan -> OK")
	var d: Dictionary = r["data"]
	_check(int(d["day"]) == 7 and is_equal_approx(float(d["minute"]), 14.0 * 60.0 + 30.0) and d["location"] == "klinik", "hari, jam, lokasi tersimpan")
	var cs := ClinicStats.new()
	var sk := SkillProgressionSystem.new()
	var inv := HerbInventory.new()
	var gd := GardenSystem.new()
	var up := ClinicUpgrades.new()
	SaveSystem.apply(d, cs, sk, inv, gd, up)
	var ocs: ClinicStats = st[1]
	var osk: SkillProgressionSystem = st[2]
	_check(cs.money == ocs.money and is_equal_approx(cs.reputation, ocs.reputation) and ocs.reputation > 47.5 and cs.treated == 1 and cs.cured == 1, "koin, reputasi, pasien dipulihkan")
	_check(cs.ledger.size() == ocs.ledger.size() and cs.milestones_done.size() == ocs.milestones_done.size(), "buku kas & capaian dipulihkan")
	_check(sk.xp_of("diagnosis") == osk.xp_of("diagnosis") and sk.level("diagnosis") == osk.level("diagnosis") and sk.xp_of("peracikan") == 61, "XP & tingkat skill dipulihkan")
	_check(sk.known_plants == osk.known_plants and sk.known_plants.size() == 2, "tanaman dikenal dipulihkan")
	_check(inv.count("jahe") == 9 and inv.count("kayu_manis") == 0, "inventaris dipulihkan (termasuk stok 0)")
	_check(not gd.available("garden_plot_1", 7) and gd.available("garden_plot_1", 8), "kebun: petak yang sudah dikerjakan tetap terkunci hari itu")
	_check(up.level("lentera") == 1 and up.level("rak_besar") == 2 and inv.daily_min == HerbInventory.DAILY_MIN + 2, "upgrade dipulihkan & efek rak besar aktif")
	# tulis kedua kali -> cadangan terbentuk, berkas utama tetap valid
	cs.add_money(10, "pasien")
	SaveSystem.write(SaveSystem.collect(st[0], "desa", cs, sk, inv, gd, up))
	_check(FileAccess.file_exists(SaveSystem.path(SaveSystem.BAK_NAME)) and not FileAccess.file_exists(SaveSystem.path(SaveSystem.TMP_NAME)), "tulis ulang: cadangan ada, berkas sementara bersih")
	_check(int(SaveSystem.read()["data"]["stats"]["money"]) == ocs.money + 10 and SaveSystem.read()["data"]["location"] == "desa", "simpanan terbaru terbaca")


func _write_raw(name: String, text: String) -> void:
	var f := FileAccess.open(SaveSystem.path(name), FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _test_save_failures() -> void:
	var st: Array = _sample_state()
	var good: Dictionary = SaveSystem.collect(st[0], "desa", st[1], st[2], st[3], st[4], st[5])
	# utama rusak (terpotong), cadangan sehat
	SaveSystem.delete_all()
	SaveSystem.write(good)
	SaveSystem.write(good)
	_write_raw(SaveSystem.FILE_NAME, '{"version": 1, "data": {"day": 7, "stats"')
	var r: Dictionary = SaveSystem.read()
	_check(r["status"] == SaveSystem.Status.RESTORED_BACKUP and int(r["data"]["day"]) == 7, "berkas utama terpotong -> pulih dari cadangan")
	# kedua-duanya rusak
	_write_raw(SaveSystem.BAK_NAME, "bukan json {{{")
	r = SaveSystem.read()
	_check(r["status"] == SaveSystem.Status.CORRUPT_NEW and (r["data"] as Dictionary).is_empty(), "utama & cadangan rusak -> CORRUPT_NEW (mulai baru, tanpa crash)")
	# berkas kosong
	SaveSystem.delete_all()
	_write_raw(SaveSystem.FILE_NAME, "")
	_check(SaveSystem.read()["status"] == SaveSystem.Status.CORRUPT_NEW, "berkas kosong -> CORRUPT_NEW")
	# JSON valid tapi bentuk salah
	for bad in ["[1,2,3]", '"teks"', "42", "null", '{"version": 1}', '{"version": 1, "data": [1]}', '{"data": {"day": 3}}',
			'{"version": 0, "data": {}}', '{"version": 99, "data": {"day": 3}}', '{"version": "satu", "data": {}}']:
		SaveSystem.delete_all()
		_write_raw(SaveSystem.FILE_NAME, bad)
		if SaveSystem.read()["status"] != SaveSystem.Status.CORRUPT_NEW:
			_check(false, "bentuk salah ditolak: %s" % bad)
			return
	_check(true, "10 bentuk berkas salah/versi tak dikenal ditolak -> mulai baru")
	# utama hilang, cadangan ada
	SaveSystem.delete_all()
	SaveSystem.write(good)
	SaveSystem.write(good)
	DirAccess.remove_absolute(SaveSystem.path(SaveSystem.FILE_NAME))
	_check(SaveSystem.read()["status"] == SaveSystem.Status.RESTORED_BACKUP, "utama hilang, cadangan ada -> pulih")
	# sisa berkas sementara (crash di tengah tulis) tidak mengganggu
	SaveSystem.delete_all()
	SaveSystem.write(good)
	_write_raw(SaveSystem.TMP_NAME, '{"version": 1, "da')
	_check(SaveSystem.read()["status"] == SaveSystem.Status.OK, "sisa berkas .tmp separuh tidak dipakai")
	SaveSystem.write(good)
	_check(SaveSystem.read()["status"] == SaveSystem.Status.OK and not FileAccess.file_exists(SaveSystem.path(SaveSystem.TMP_NAME)), "tulis berikutnya membersihkan .tmp")
	SaveSystem.delete_all()
	_check(not SaveSystem.exists() and SaveSystem.read()["status"] == SaveSystem.Status.MISSING, "delete_all menghapus semua")


func _test_sanitize_and_apply() -> void:
	var s: Dictionary = SaveSystem.sanitize({"day": -5, "minute": 99999.0, "language": "xx", "location": "bulan",
		"stats": [1], "skills": "x", "inventory": 3, "garden": null, "upgrades": {"lentera": 50}})
	_check(int(s["day"]) == 1 and float(s["minute"]) < 1440.0 and s["language"] == "id" and s["location"] == "desa", "sanitize: hari/jam/bahasa/lokasi dibatasi")
	_check(s["stats"] is Dictionary and s["skills"] is Dictionary and s["inventory"] is Dictionary and s["garden"] is Dictionary, "sanitize: tipe salah diganti {}")
	var cs := ClinicStats.new()
	var sk := SkillProgressionSystem.new()
	var inv := HerbInventory.new()
	var gd := GardenSystem.new()
	var up := ClinicUpgrades.new()
	SaveSystem.apply(s, cs, sk, inv, gd, up)
	_check(cs.money == 0 and sk.level("diagnosis") == 1 and up.level("lentera") == 2, "apply dengan data hampir kosong tidak crash; upgrade dibatasi")
	var s2: Dictionary = SaveSystem.sanitize({"skills": {"xp": {"diagnosis": -999, "tak_ada": 5}, "known_plants": [1, "kunyit"]},
		"garden": {"titik_palsu": 3, "garden_plot_2": 4}, "inventory": {"jahe": -5}})
	SaveSystem.apply(s2, cs, sk, inv, gd, up)
	_check(sk.xp_of("diagnosis") == 0 and not sk.xp.has("tak_ada") and inv.count("jahe") == 0, "XP/stok negatif & kunci asing dibersihkan")
	_check(not gd.done_day.has("titik_palsu") and gd.done_day.has("garden_plot_2"), "kebun: titik asing dibuang")


# --- Keseimbangan ------------------------------------------------------------------

func _xp_visits_to_level(grade: int, difficulty: int, target_level: int) -> int:
	var sk := SkillProgressionSystem.new()
	var n: int = 0
	while sk.level("diagnosis") < target_level and n < 500:
		var r := MinigameResult.new()
		r.kind = "diagnosis"
		r.grade = grade
		r.difficulty = difficulty
		sk.award(r)
		n += 1
	return n


func _test_pacing() -> void:
	# Pemain biasa (nilai B, kesulitan sedang): tingkat 2 dalam beberapa kunjungan, tingkat 5 dalam puluhan.
	var l2: int = _xp_visits_to_level(Grade.Level.B, 2, 2)
	var l3: int = _xp_visits_to_level(Grade.Level.B, 2, 3)
	var l5: int = _xp_visits_to_level(Grade.Level.B, 2, 5)
	_check(l2 >= 2 and l2 <= 5, "pemain B: diagnosis tingkat 2 setelah %d kunjungan (2..5)" % l2)
	_check(l3 >= 5 and l3 <= 12, "pemain B: tingkat 3 setelah %d kunjungan (5..12)" % l3)
	_check(l5 >= 15 and l5 <= 45, "pemain B: tingkat 5 setelah %d kunjungan (15..45)" % l5)
	var c5: int = _xp_visits_to_level(Grade.Level.C, 2, 5)
	var s5: int = _xp_visits_to_level(Grade.Level.S, 2, 5)
	_check(c5 > l5 and l5 > s5, "nilai lebih baik = naik lebih cepat (C %d > B %d > S %d)" % [c5, l5, s5])
	_check(c5 <= 120, "pemain C tidak terlalu lambat (%d kunjungan ke tingkat 5)" % c5)
	# Ekonomi: pendapatan harian bersih dan waktu membeli upgrade.
	var fee_b: int = ClinicStats.fee_for(40, Grade.quality(Grade.Level.B), ClinicStats.START_REPUTATION)
	var fee_a: int = ClinicStats.fee_for(40, Grade.quality(Grade.Level.A), ClinicStats.START_REPUTATION)
	var patients_per_day: float = 4.0   # rencana harian PatientSystem: 3..5
	var net_b: float = patients_per_day * float(fee_b) - float(EconomyDb.BASE_OPERATING_COST)
	_check(fee_a > fee_b and fee_b > 20, "bayaran nilai A (%d) > B (%d) > 20 koin" % [fee_a, fee_b])
	_check(net_b > 80.0, "pendapatan bersih harian pemain B > 80 koin (%.0f)" % net_b)
	var cheapest: int = 99999
	var total: int = 0
	for id in ClinicUpgrades.IDS:
		for l in (ClinicUpgrades.DEFS[id]["levels"] as Array):
			cheapest = mini(cheapest, int(l["cost"]))
			total += int(l["cost"])
	_check(float(cheapest - EconomyDb.START_MONEY) / net_b <= 2.0, "upgrade termurah terjangkau dalam <= 2 hari")
	var days_all: float = float(total) / (net_b + 40.0)   # +40: bonus capaian/naik tingkat rata-rata awal
	_check(days_all >= 10.0 and days_all <= 40.0, "semua upgrade dalam ~%.0f hari (10..40)" % days_all)
	# biaya operasional maksimum tidak menghabiskan pendapatan
	var up := ClinicUpgrades.new()
	for id in ClinicUpgrades.IDS:
		up.levels[id] = ClinicUpgrades.max_level(id)
	_check(float(up.operating_cost()) < patients_per_day * float(fee_b) * 0.5, "biaya operasional penuh (%d) < 50%% pendapatan harian" % up.operating_cost())


func _test_localization() -> void:
	var missing: Array[String] = []
	var keys: Array[String] = ["ui.new_day_cost", "ui.coin_gain", "ui.coin_loss", "ui.loaded", "ui.load_backup", "ui.load_corrupt",
		"shop.title", "shop.coins", "shop.help", "shop.buy", "shop.sell", "shop.stock", "shop.bought", "shop.sold", "shop.no_money", "shop.no_stock",
		"upgrade.title", "upgrade.help", "upgrade.buy", "upgrade.max_btn", "upgrade.max", "upgrade.ready", "upgrade.req_rep", "upgrade.req_skill",
		"upgrade.req_money", "upgrade.bought", "summary.milestone", "book.upgrades", "book.ledger", "book.save", "book.saved", "book.save_fail"]
	for id in ClinicUpgrades.IDS:
		keys.append("upgrade.%s.name" % id)
		keys.append("upgrade.%s.effect" % id)
	for m in EconomyDb.MILESTONES:
		keys.append("milestone.%s" % String(m["id"]))
	for kind in ["pasien", "jual", "beli", "upgrade", "operasional", "naik_tingkat", "capaian"]:
		keys.append("ledger.%s" % kind)
	for k in keys:
		for lang in Locale.LANGS:
			if not Locale.has_key(k, lang):
				missing.append("%s[%s]" % [k, lang])
	_check(missing.is_empty(), "kunci Fase 6 lengkap di ID+EN (hilang: %s)" % str(missing.slice(0, 8)))
	Locale.set_language("id")
	_check(EconomyText.reason_text("beli:jahe") == "Beli Jahe" and EconomyText.reason_text("operasional") == "Biaya operasional", "teks alasan transaksi")
	_check(EconomyText.reason_text("tidak_dikenal:x") == "tidak_dikenal:x", "alasan tak dikenal ditampilkan apa adanya")
