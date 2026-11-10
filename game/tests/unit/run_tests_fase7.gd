extends SceneTree
## Tes unit Fase 7: titik pengumpulan, stamina & regenerasi, misi, rahasia, kunjungan area, simpan/muat
## keadaan petualangan, data area (pintu dan titik mulai), keseimbangan stamina, dan localization.
## Jalankan: godot --headless --path game -s res://tests/unit/run_tests_fase7.gd

const TEST_DIR: String = "user://tes_unit_fase7"

var _count: int = 0
var _fail: int = 0


func _init() -> void:
	SaveSystem.override_dir = TEST_DIR
	SaveSystem.delete_all()
	_test_forage_data()
	_test_forage_roll()
	_test_stamina()
	_test_cooldown_and_gather_costs()
	_test_visits_and_missions()
	_test_secret()
	_test_state_roundtrip_and_sanitize()
	_test_area_locations()
	_test_pacing()
	_test_localization()
	SaveSystem.delete_all()
	print("Tes Fase 7 dijalankan: %d, gagal: %d" % [_count, _fail])
	quit(1 if _fail > 0 else 0)


func _check(condition: bool, name: String) -> void:
	_count += 1
	if condition:
		print("  OK   ", name)
	else:
		_fail += 1
		printerr("  GAGAL ", name)


func _test_forage_data() -> void:
	var nodes: Array[Dictionary] = ForageDb.all_nodes()
	_check(nodes.size() == 10 and ForageDb.AREAS.size() == 3, "10 titik pengumpulan di 3 area")
	var ids: Array[String] = []
	var valid: bool = true
	for n in nodes:
		var id: String = String(n["id"])
		if ids.has(id) or not ForageDb.is_area(String(n["area"])):
			valid = false
		ids.append(id)
		for h in n["common"]:
			if not HerbDb.has(String(h)):
				valid = false
		if not HerbDb.has(String(n["rare"])) or (n["common"] as Array).size() < 2:
			valid = false
	_check(valid, "id unik, area valid, bahan umum >= 2 dan bahan langka dikenal")
	for a in ForageDb.AREAS:
		_check(ForageDb.nodes_in(a).size() >= 2, "area %s punya >= 2 titik" % a)
	_check(ForageDb.has("forage_hutan_1") and not ForageDb.has("tidak_ada") and ForageDb.get_node("tidak_ada").is_empty(), "pencarian titik")
	_check(not ForageDb.has("wild_plant_kolam") and not ForageDb.has("garden_plot_1"), "titik kebun Fase 5 tidak ikut")


func _test_forage_roll() -> void:
	var rare: int = 0
	var all_valid: bool = true
	var deterministic: bool = ForageDb.roll("forage_hutan_1", 42)["herb"] == ForageDb.roll("forage_hutan_1", 42)["herb"]
	for s in range(1000):
		var r: Dictionary = ForageDb.roll("forage_sungai_2", s)
		if bool(r["rare"]):
			rare += 1
			if String(r["herb"]) != "sambiloto":
				all_valid = false
		elif not (ForageDb.get_node("forage_sungai_2")["common"] as Array).has(String(r["herb"])):
			all_valid = false
	var frac: float = float(rare) / 1000.0
	_check(deterministic, "hasil pengumpulan deterministik per (titik, seed)")
	_check(all_valid, "hasil selalu dari daftar bahan titik")
	_check(absf(frac - ForageDb.RARE_CHANCE) < 0.05, "peluang bahan langka ~%d%% (%.1f%%)" % [int(ForageDb.RARE_CHANCE * 100.0), frac * 100.0])
	_check(ForageDb.roll("tidak_ada", 1)["herb"] == "", "titik tak dikenal: tanpa hasil")


func _test_stamina() -> void:
	var a := AdventureState.new()
	a.last_tick = 100.0
	_check(a.stamina == AdventureState.MAX_STAMINA, "stamina awal penuh")
	_check(a.spend(30.0) and absf(a.stamina - 70.0) < 0.001, "aktivitas mengurangi stamina")
	_check(not a.spend(200.0) and absf(a.stamina - 70.0) < 0.001, "stamina kurang: aktivitas ditolak tanpa efek")
	a.sync(100.0)
	_check(absf(a.stamina - 70.0) < 0.001, "sync di waktu yang sama tidak mengubah stamina")
	a.sync(200.0)
	_check(absf(a.stamina - 80.0) < 0.001, "100 menit = +10 stamina")
	a.sync(100000.0)
	_check(a.stamina == AdventureState.MAX_STAMINA, "stamina pulih tetapi tidak melebihi maksimum")
	a.spend(50.0)
	a.refund(8.0)
	_check(absf(a.stamina - 58.0) < 0.001, "refund mengembalikan stamina")
	a.sync(50.0)
	_check(absf(a.stamina - 58.0) < 0.001, "waktu mundur tidak mengurangi/menambah stamina")


func _test_cooldown_and_gather_costs() -> void:
	var a := AdventureState.new()
	var t: float = 600.0
	_check(a.node_ready("forage_hutan_1", t), "titik baru siap dikumpulkan")
	a.mark_forage("forage_hutan_1", t)
	_check(not a.node_ready("forage_hutan_1", t + ForageDb.REGEN_MINUTES - 1.0), "titik tumbuh kembali setelah REGEN_MINUTES, belum sebelumnya")
	_check(a.node_ready("forage_hutan_1", t + ForageDb.REGEN_MINUTES), "titik siap tepat setelah REGEN_MINUTES")
	_check(a.node_ready("forage_hutan_2", t), "titik lain tidak terpengaruh")
	_check(AdventureState.COST_IDENTIFY > AdventureState.COST_GATHER and AdventureState.COST_GATHER > 0.0, "biaya identifikasi > bahan dikenal > 0")
	var per_day: int = int(AdventureState.MAX_STAMINA / AdventureState.COST_GATHER)
	_check(per_day >= 10, "stamina penuh cukup untuk >= 10 pengumpulan sebelum habis (%d)" % per_day)


func _test_visits_and_missions() -> void:
	var a := AdventureState.new()
	_check(a.visit("hutan") and not a.visit("hutan") and a.count("visit:hutan") == 1, "kunjungan pertama dihitung sekali")
	var m: Dictionary = a.active_mission()
	_check(String(m["id"]) == "m_hutan" and not a.mission_done(m), "misi pertama aktif dan belum selesai")
	a.bump("gather:hutan", 3)
	_check(a.mission_progress(m) == 3 and not a.mission_done(m), "kemajuan 3/4")
	_check(a.claim().is_empty(), "klaim ditolak bila belum selesai")
	a.bump("gather:hutan")
	var got: Dictionary = a.claim()
	_check(got.get("id", "") == "m_hutan" and int(got.get("coin", 0)) == 60, "klaim misi pertama memberi 60 koin")
	_check(a.claim().is_empty() and String(a.active_mission()["id"]) == "m_kenali", "misi berikutnya aktif setelah klaim")
	a.bump("identify_new", 3)
	a.claim()
	var j: Dictionary = a.active_mission()
	_check(String(j["id"]) == "m_jelajah" and not a.mission_done(j), "misi jelajah: butuh dua kunjungan")
	a.visit("sungai")
	_check(not a.mission_done(j), "satu kunjungan belum cukup")
	a.visit("pegunungan")
	_check(a.mission_done(j), "dua kunjungan cukup")
	a.claim()
	_check(String(a.active_mission()["id"]) == "m_celah", "misi celah berikutnya")
	a.claimed.append("m_celah")
	_check(a.active_mission().is_empty(), "semua misi selesai -> papan kosong")


func _test_secret() -> void:
	var a := AdventureState.new()
	_check(not a.has_secret(AdventureState.SECRET_ID), "rahasia belum dibuka")
	_check(a.reveal_secret(AdventureState.SECRET_ID) and a.has_secret(AdventureState.SECRET_ID), "rahasia dibuka")
	_check(not a.reveal_secret(AdventureState.SECRET_ID) and a.count("secret") == 1, "rahasia hanya sekali")
	_check(AdventureState.SECRET_COIN > 0 and AdventureState.SECRET_UNITS > 0 and HerbDb.has(AdventureState.SECRET_HERB), "hadiah rahasia valid")


func _test_state_roundtrip_and_sanitize() -> void:
	var a := AdventureState.new()
	a.spend(40.0)
	a.mark_forage("forage_pegunungan_1", 500.0)
	a.visit("hutan")
	a.bump("gather:hutan", 2)
	a.reveal_secret(AdventureState.SECRET_ID)
	a.claimed.append("m_hutan")
	a.sync(700.0)
	var b := AdventureState.new()
	b.from_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	_check(absf(b.stamina - a.stamina) < 0.001 and b.count("gather:hutan") == 2 and b.count("visit:hutan") == 1, "stamina & penghitung bolak-balik JSON")
	_check(b.node_ready("forage_pegunungan_1", 500.0 + ForageDb.REGEN_MINUTES - 1.0) == false and b.has_secret(AdventureState.SECRET_ID), "cooldown & rahasia bolak-balik")
	_check(b.claimed == ["m_hutan"], "misi diklaim tetap diklaim")
	var c := AdventureState.new()
	c.from_dict({"stamina": 900.0, "last_tick": -5.0, "forage_last": {"tak_ada": 3.0, "forage_sungai_1": -4.0},
		"counters": {"gather:hutan": -9, "x": "abc"}, "claimed": [1, "m_hutan", "m_hutan"], "secrets": "bukan"})
	_check(c.stamina == AdventureState.MAX_STAMINA and c.last_tick == 0.0, "stamina & waktu dibatasi")
	_check(not c.forage_last.has("tak_ada") and float(c.forage_last["forage_sungai_1"]) == 0.0, "titik asing dibuang, waktu negatif dibatasi")
	_check(c.count("gather:hutan") == 0 and c.claimed == ["m_hutan"] and c.secrets.is_empty(), "penghitung negatif, tipe salah, duplikat dibersihkan")
	# simpan & muat keadaan petualangan lewat SaveSystem
	var clock := GameClock.new()
	clock.set_time(3, 10, 0)
	var cs := ClinicStats.new()
	var sk := SkillProgressionSystem.new()
	var inv := HerbInventory.new()
	var gd := GardenSystem.new()
	var up := ClinicUpgrades.new()
	SaveSystem.write(SaveSystem.collect(clock, "pegunungan", cs, sk, inv, gd, up, a))
	var r: Dictionary = SaveSystem.read()
	var d: Dictionary = r["data"]
	_check(d["location"] == "pegunungan", "lokasi area tersimpan")
	var a2 := AdventureState.new()
	SaveSystem.apply(d, cs, sk, inv, gd, up, a2)
	_check(a2.count("visit:hutan") == 1 and a2.has_secret(AdventureState.SECRET_ID), "keadaan petualangan dipulihkan lewat SaveSystem")
	var old: Dictionary = SaveSystem.sanitize({"location": "bulan"})
	_check(old["location"] == "desa" and SaveSystem.sanitize({"location": "sungai"})["location"] == "sungai", "lokasi tak dikenal -> desa; area valid dipertahankan")
	# berkas Fase 6 (tanpa kunci adventure) tetap bisa dimuat
	var a3 := AdventureState.new()
	SaveSystem.apply({"stats": {}, "skills": {}, "inventory": {}, "garden": {}, "upgrades": {}}, cs, sk, inv, gd, up, a3)
	_check(a3.stamina == AdventureState.MAX_STAMINA and a3.counters.is_empty(), "simpanan Fase 6 (tanpa petualangan) tetap valid")
	SaveSystem.delete_all()


func _test_area_locations() -> void:
	for id in ["hutan", "sungai", "pegunungan"]:
		var data: LocationData = LocationRegistry.get_location(id)
		_check(data != null and data.transitions.size() >= 1, "%s: ada dan punya pintu keluar" % id)
		var nodes_here: int = 0
		for it in data.interactables:
			if ForageDb.has(it.id):
				nodes_here += 1
		_check(nodes_here == ForageDb.nodes_in(id).size(), "%s: semua titik pengumpulan terpasang (%d)" % [id, nodes_here])
	var forest: LocationData = LocationRegistry.get_location("hutan")
	_check(forest.interactable_by_id("adventure_board") != null, "hutan: papan Pengembara ada")
	_check(LocationRegistry.get_location("pegunungan").interactable_by_id("secret_cleft") != null, "pegunungan: celah rahasia ada")
	var village: LocationData = LocationRegistry.get_location("desa")
	var to_area: Array[String] = []
	for t in village.transitions:
		to_area.append(String(t["target"]))
	_check(to_area.has("hutan") and to_area.has("sungai") and to_area.has("klinik"), "desa terhubung ke hutan, sungai, dan klinik")
	_check(LocationRegistry.get_location("hutan").transitions.size() == 2, "hutan punya dua pintu (desa, pegunungan)")


func _test_pacing() -> void:
	# Pemain biasa: 4 titik per area, regenerasi 4 jam; target: tidak ada hari tanpa aktivitas.
	var a := AdventureState.new()
	var day: float = 1440.0
	var gathered: int = 0
	var t: float = 420.0
	var nodes: Array[Dictionary] = ForageDb.all_nodes()
	for step in range(12):
		var n: Dictionary = nodes[step % nodes.size()]
		if a.node_ready(String(n["id"]), t) and a.spend(AdventureState.COST_GATHER):
			a.mark_forage(String(n["id"]), t)
			gathered += 1
		t += 30.0
	_check(gathered >= 8, "pemain biasa bisa mengumpulkan >= 8 kali dalam satu hari (%d)" % gathered)
	var recover_min: float = (AdventureState.MAX_STAMINA - a.stamina) / AdventureState.REGEN_PER_MINUTE
	_check(recover_min <= day, "stamina habis pulih dalam satu hari permainan (%d menit)" % int(recover_min))
	_check(ForageDb.REGEN_MINUTES <= day / 2.0, "titik tumbuh kembali <= setengah hari")


func _test_localization() -> void:
	var keys: Array[String] = ["ui.stamina", "adv.forage_prompt", "adv.board_prompt", "adv.secret_prompt", "adv.forage_got",
		"adv.node_resting", "adv.too_tired", "adv.first_visit", "adv.secret_title", "adv.secret_found", "adv.secret_done",
		"adv.secret_locked", "board.title", "board.progress", "board.claimed", "board.all_done", "plant.lore",
		"ledger.jelajah", "ledger.misi", "ledger.celah"]
	for aid in ForageDb.AREAS:
		keys.append("area.%s.name" % aid)
	for n in ForageDb.all_nodes():
		keys.append("forage.%s" % String(n["id"]))
	for m in MissionDb.all():
		keys.append("mission.%s.title" % String(m["id"]))
		keys.append("mission.%s.desc" % String(m["id"]))
	for h in ["kunyit", "jahe", "temulawak", "kencur", "serai", "lengkuas", "sambiloto", "kumis_kucing", "sirih", "kayu_manis"]:
		keys.append("lore.%s.habitat" % h)
		keys.append("lore.%s.use" % h)
	var missing: Array[String] = []
	for k in keys:
		for lang in Locale.LANGS:
			if not Locale.has_key(k, lang):
				missing.append("%s[%s]" % [k, lang])
	_check(missing.is_empty(), "kunci Fase 7 lengkap di ID+EN (hilang: %s)" % str(missing.slice(0, 8)))
	Locale.set_language("id")
	_check(EconomyText.reason_text("jelajah:hutan") == "Penemuan Hutan" and EconomyText.reason_text("misi:m_hutan") == "Misi: Kumpulkan bahan dari hutan", "teks alasan jelajah & misi")
