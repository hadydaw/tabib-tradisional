extends SceneTree
## Tes asap Fase 6 (headless): toko bahan & upgrade lewat layar nyata, bayaran pasien, biaya harian, dan SIMPAN/MUAT
## dengan menutup lalu membuka ulang dunia (dunia lama dibuang, dunia baru memuat berkas), termasuk berkas rusak,
## cadangan, dan berkas hilang. Rasa sentuhan & tampilan hanya bisa dinilai di HP.
## Jalankan: godot --headless --path game -s res://tests/smoke/run_smoke_economy.gd

const DIR: String = "user://tes_asap_fase6"

var _world: Node
var _steps: Array[Callable] = []
var _step_index: int = 0
var _frames: int = 0
var _fail: int = 0
var _count: int = 0
var _snap: Dictionary = {}


func _initialize() -> void:
	Locale.set_language("id")
	SaveSystem.override_dir = DIR
	SaveSystem.force_enabled = true
	SaveSystem.delete_all()
	_world = _new_world()
	_steps = [_step_new_game, _step_shop, _step_shop_failures, _step_upgrades, _step_visit, _step_save, _step_reopen,
		_step_new_day_cost, _step_backup, _step_corrupt, _step_missing, _step_final]


func _new_world() -> Node:
	var w: Node = (load("res://scenes/world/game_world.tscn") as PackedScene).instantiate()
	root.add_child(w)
	return w


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	if _step_index < _steps.size():
		_steps[_step_index].call()
		_step_index += 1
		return false
	print("Tes asap ekonomi/simpan: %d pemeriksaan, gagal: %d" % [_count, _fail])
	SaveSystem.delete_all()
	SaveSystem.force_enabled = false
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


func _swap_world() -> void:
	## "Tutup lalu buka ulang game": buang dunia lama sepenuhnya, buat dunia baru yang memuat berkas.
	UiGate.blocked = false
	root.remove_child(_world)
	_world.free()
	_world = _new_world()


func _step_new_game() -> void:
	_mg().transitions = false
	_check(_world.load_status == SaveSystem.Status.MISSING, "tanpa berkas: permainan baru")
	_check(_world.get_stats().money == EconomyDb.START_MONEY and _world.get_stats().treated == 0, "modal awal %d koin" % EconomyDb.START_MONEY)
	_check(_world.get_upgrades().total_levels() == 0 and _world.get_shop() != null, "upgrade & toko terpasang")


func _step_shop() -> void:
	var inv: HerbInventory = _world.get_inventory()
	var st: ClinicStats = _world.get_stats()
	_world.load_location("klinik", "dari_desa")
	var k0: int = inv.count("kunyit")
	var m0: int = st.money
	_world.interact_shelf()
	_check(_world.is_minigame_open() and _mg().kind() == "toko" and _view() is ShopView, "Rak Herbal membuka pasar bahan")
	_check(UiGate.blocked, "kontrol dunia terkunci di toko")
	_check(_view().click_button("buy:kunyit") and _view().click_button("buy:kunyit"), "tombol Beli ditekan 2x")
	_check(inv.count("kunyit") == k0 + 2 and st.money == m0 - 2 * EconomyDb.buy_price("kunyit"), "beli 2 kunyit: stok & koin berubah")
	_check(st.ledger.size() == 2 and String(st.ledger[1]["reason"]) == "beli:kunyit", "buku kas mencatat pembelian")
	_check(_view().click_button("sell:kunyit") and inv.count("kunyit") == k0 + 1, "tombol Jual menjual 1")
	_check(not _view().button_enabled("sell:tak") and _view().button_ids().has("shop_close"), "tombol tutup ada")
	_view().click_button("shop_close")
	_check(not _world.is_minigame_open() and not UiGate.blocked, "toko ditutup; kontrol kembali")
	_check(SaveSystem.exists(), "menutup toko menyimpan otomatis")


func _step_shop_failures() -> void:
	var st: ClinicStats = _world.get_stats()
	var inv: HerbInventory = _world.get_inventory()
	st.money = 0
	_world.interact_shelf()
	var k0: int = inv.count("kayu_manis")
	var v: ShopView = _view() as ShopView
	_check(not v.button_enabled("buy:kayu_manis"), "koin 0: tombol Beli nonaktif")
	var r: Dictionary = v.do_buy("kayu_manis")
	_check(not bool(r["ok"]) and inv.count("kayu_manis") == k0 and st.money == 0, "pembelian paksa tanpa koin ditolak")
	inv.stock["jahe"] = 0
	v.mark_dirty()
	r = v.do_sell("jahe")
	_check(not bool(r["ok"]) and st.money == 0, "jual stok 0 ditolak")
	v.closed.emit()
	_check(not _world.is_minigame_open(), "toko ditutup")
	inv.stock["jahe"] = 3


func _step_upgrades() -> void:
	var st: ClinicStats = _world.get_stats()
	var up: ClinicUpgrades = _world.get_upgrades()
	st.money = 1000
	st.reputation = 40.0
	_world.interact_table()
	_check(_world.is_minigame_open() and _mg().kind() == "upgrade" and _view() is UpgradeView, "Meja Pengobatan membuka upgrade klinik")
	_check(not _view().button_enabled("up:jarum_perak"), "upgrade dengan syarat skill belum terpenuhi: tombol nonaktif")
	_check(_view().button_enabled("up:lentera") and _view().click_button("up:lentera"), "beli Lentera Periksa")
	_check(up.level("lentera") == 1 and st.money == 1000 - 120, "tingkat 1, koin -120")
	_check(String(st.ledger[st.ledger.size() - 1]["reason"]) == "upgrade:lentera", "buku kas mencatat upgrade")
	_check(_view().click_button("up:rak_besar") and _world.get_inventory().daily_min == HerbInventory.DAILY_MIN + 1, "Rak Herbal Besar menaikkan stok harian minimal")
	var uv: UpgradeView = _view() as UpgradeView
	var m: int = st.money
	var r: Dictionary = uv.do_buy("jarum_perak")
	_check(not bool(r["ok"]) and String(r["reason"]) == "skill" and st.money == m and up.level("jarum_perak") == 0, "beli tanpa syarat skill ditolak tanpa potong koin")
	st.money = 5
	r = uv.do_buy("ruang_tunggu")
	_check(not bool(r["ok"]) and String(r["reason"]) == "money" and up.level("ruang_tunggu") == 0, "koin kurang ditolak")
	uv.closed.emit()
	st.money = 200


func _step_visit() -> void:
	## Pasien nyata melewati antrean klinik; bayaran, XP, reputasi, dan capaian masuk ke sistem yang sama.
	var ps: PatientSystem = _world.get_patients()
	ps.auto_call = false
	ps.suppress_plan()
	_world.debug_set_time(_world.get_clock().day, 9, 0)
	_world.load_location("klinik", "dari_desa")
	var p: PatientRecord = ps.start_visit(NpcRoster.ids()[0], ComplaintCatalog.IDS[0])
	var guard: int = 0
	while p.state != PatientRecord.State.MENUNGGU and guard < 4000:
		_world.step_world(0.5)
		guard += 1
	_world._interact_reception()
	guard = 0
	while p.state != PatientRecord.State.DIPERIKSA and guard < 1000:
		_world.step_world(0.5)
		guard += 1
	_check(p.state == PatientRecord.State.DIPERIKSA, "pasien di ruang periksa")
	var tm: TreatmentManager = _world.get_treatment()
	var st: ClinicStats = _world.get_stats()
	var s: TreatmentSession = tm.session_for(p)
	var d: DiagnosisSystem = tm.begin_diagnosis(p)
	_check(d.energy_max == int(SkillDb.effect("diagnosis", "energi", 1)) + 1, "upgrade Lentera berlaku pada diagnosis nyata (energi %d)" % d.energy_max)
	d.observe()
	d.submit(s.true_ailment)
	tm.complete_diagnosis(p, d)
	var acu: Array[String] = ["akupunktur"]
	tm.choose_methods(p, acu)
	var a: AcupunctureSystem = tm.begin_acupuncture(p)
	for pid in a.plan:
		a.toggle_point(pid)
	a.begin_insertion()
	while a.phase == AcupunctureSystem.Phase.JARUM:
		a.insert(Vector2.ZERO, AcupunctureSystem.DEPTH_CENTER)
	var m0: int = st.money
	tm.complete_acupuncture(p, a)
	var sum: Dictionary = s.summary
	_check(not sum.is_empty() and int(sum["fee"]) > 0, "kunjungan selesai dengan bayaran %d" % int(sum.get("fee", 0)))
	_check(st.money >= m0 + int(sum["fee"]) and st.treated == 1, "bayaran masuk ke koin klinik")
	_check((sum["milestones"] as Array).has("pasien_1"), "capaian 'pasien pertama' dihitung")
	_check(_world.get_skills().xp_of("diagnosis") > 0 and _world.get_skills().xp_of("akupunktur") > 0, "XP skill dari kunjungan")
	_world.get_garden().mark_done("garden_plot_1", _world.get_clock().day)
	_world.get_skills().learn_plant("jahe")


func _step_save() -> void:
	var st: ClinicStats = _world.get_stats()
	var sk: SkillProgressionSystem = _world.get_skills()
	Locale.set_language("en")
	_check(_world.save_game(), "simpan manual berhasil")
	_snap = {
		"money": st.money, "rep": st.reputation, "treated": st.treated, "cured": st.cured, "ledger": st.ledger.size(),
		"xp_d": sk.xp_of("diagnosis"), "xp_a": sk.xp_of("akupunktur"), "jahe": _world.get_inventory().count("jahe"),
		"kunyit": _world.get_inventory().count("kunyit"), "lentera": _world.get_upgrades().level("lentera"),
		"day": _world.get_clock().day, "minute": _world.get_clock().minute_f, "known": sk.known_plants.size(),
		"ms": st.milestones_done.size(),
	}
	var text: String = FileAccess.get_file_as_string(SaveSystem.path())
	_check(text.length() > 200 and JSON.parse_string(text) is Dictionary, "berkas simpanan JSON valid (%d byte)" % text.length())


func _step_reopen() -> void:
	_swap_world()
	var st: ClinicStats = _world.get_stats()
	var sk: SkillProgressionSystem = _world.get_skills()
	_check(_world.load_status == SaveSystem.Status.OK, "dunia baru memuat berkas (OK)")
	_check(st.money == _snap["money"] and is_equal_approx(st.reputation, float(_snap["rep"])), "koin & reputasi sama setelah dibuka ulang")
	_check(st.treated == _snap["treated"] and st.cured == _snap["cured"] and st.ledger.size() == _snap["ledger"] and st.milestones_done.size() == _snap["ms"], "pasien, buku kas, capaian sama")
	_check(sk.xp_of("diagnosis") == _snap["xp_d"] and sk.xp_of("akupunktur") == _snap["xp_a"] and sk.known_plants.size() == _snap["known"], "XP & tanaman dikenal sama")
	_check(_world.get_inventory().count("jahe") == _snap["jahe"] and _world.get_inventory().count("kunyit") == _snap["kunyit"], "inventaris sama")
	_check(_world.get_upgrades().level("lentera") == 1 and _world.get_upgrades().level("rak_besar") == 1 and _world.get_inventory().daily_min == HerbInventory.DAILY_MIN + 1, "upgrade & efeknya sama")
	_check(not _world.get_garden().available("garden_plot_1", _world.get_clock().day), "petak kebun tetap terkunci hari itu")
	_check(_world.get_clock().day == _snap["day"] and absf(_world.get_clock().minute_f - float(_snap["minute"])) < 0.5, "hari & jam sama")
	_check(Locale.current == "en", "bahasa dipulihkan")
	_check(_world.get_location().id == "klinik", "lokasi dipulihkan (klinik)")
	_check(not _world.is_minigame_open() and not UiGate.blocked, "tidak ada layar tersisa setelah memuat")
	Locale.set_language("id")
	# Buku Tabib menampilkan buku kas & tombol Simpan
	_mg().transitions = false
	_check(_mg().show_book() and _view() is InfoView and _view().button_ids().has("info_extra"), "Buku Tabib punya tombol Simpan")
	_view().click_button("info_extra")
	_check((_view() as InfoView).extra_text == Locale.t("book.saved"), "tombol Simpan memberi umpan balik")
	_view().click_button("info_close")


func _step_new_day_cost() -> void:
	var st: ClinicStats = _world.get_stats()
	var up: ClinicUpgrades = _world.get_upgrades()
	var clock: GameClock = _world.get_clock()
	_world.get_inventory().stock["jahe"] = 0
	var m0: int = st.money
	var cost: int = up.operating_cost()
	_world.debug_set_time(clock.day + 1, 7, 0)
	_world._check_new_day()
	_check(st.money == m0 - cost, "pergantian hari memotong biaya operasional %d" % cost)
	_check(String(st.ledger[st.ledger.size() - 1]["reason"]) == "operasional", "biaya operasional tercatat")
	_check(_world.get_inventory().count("jahe") == up.herb_daily_min(), "bahan diisi ulang sesuai Rak Herbal")
	# uang tak cukup: tidak jadi minus
	st.money = 3
	_world.debug_set_time(clock.day + 1, 7, 0)
	_world._check_new_day()
	_check(st.money == 0, "uang kurang dari biaya: saldo 0, tidak minus")
	_check(_world.get_stats().ledger.size() <= ClinicStats.LEDGER_MAX, "buku kas dibatasi")
	_snap["money"] = 0


func _step_backup() -> void:
	## Simpanan terbaru ada di berkas utama; rusak -> dimuat dari cadangan (simpanan sebelumnya), game tidak crash.
	_world.save_game()
	_world.save_game()
	_world.save_game()
	var f := FileAccess.open(SaveSystem.path(), FileAccess.WRITE)
	f.store_string('{"version": 1, "data": {"day": 5, "sta')
	f.close()
	_swap_world()
	_check(_world.load_status == SaveSystem.Status.RESTORED_BACKUP, "berkas utama rusak -> dimuat dari cadangan")
	_check(_world.get_stats().money == 0 and _world.get_upgrades().level("lentera") == 1, "data dari cadangan utuh")


func _step_corrupt() -> void:
	for n in [SaveSystem.FILE_NAME, SaveSystem.BAK_NAME]:
		var f := FileAccess.open(SaveSystem.path(n), FileAccess.WRITE)
		f.store_string("sampah bukan json")
		f.close()
	_swap_world()
	_check(_world.load_status == SaveSystem.Status.CORRUPT_NEW, "utama & cadangan rusak -> permainan baru")
	_check(_world.get_stats().money == EconomyDb.START_MONEY and _world.get_stats().treated == 0 and _world.get_upgrades().total_levels() == 0, "permainan baru bersih (modal awal)")
	_check(not _world.is_minigame_open() and _world.get_player() != null, "dunia tetap berjalan")


func _step_missing() -> void:
	SaveSystem.delete_all()
	_swap_world()
	_check(_world.load_status == SaveSystem.Status.MISSING and _world.get_stats().money == EconomyDb.START_MONEY, "berkas hilang -> permainan baru")
	_check(_world.save_game() and SaveSystem.read()["status"] == SaveSystem.Status.OK, "permainan baru dapat disimpan lagi")


func _step_final() -> void:
	_check(not UiGate.blocked, "kontrol dunia tidak terkunci di akhir")
