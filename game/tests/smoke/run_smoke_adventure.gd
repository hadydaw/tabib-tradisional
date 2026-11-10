extends SceneTree
## Tes asap Fase 7 (headless, dunia nyata): perpindahan antar-area lewat keset, kunjungan pertama, pengumpulan
## (bahan dikenal & identifikasi tanaman baru), papan Pengembara dan klaim misi, celah rahasia, stamina,
## dan simpan/muat lintas-area (dunia dibuang lalu dibuat ulang). Tampilan hanya dinilai di HP.
## Jalankan: godot --headless --path game -s res://tests/smoke/run_smoke_adventure.gd

const DIR: String = "user://tes_asap_fase7"

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
	_steps = [_step_start, _step_travel, _step_forage_known, _step_forage_identify, _step_board, _step_secret,
		_step_save, _step_reopen, _step_final]


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
	print("Tes asap petualangan: %d pemeriksaan, gagal: %d" % [_count, _fail])
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
	UiGate.blocked = false
	root.remove_child(_world)
	_world.free()
	_world = _new_world()


## Pindahkan pemain ke sel `cell` (pusat sel) lalu perbarui interaksi.
func _stand(cell: Vector2i, dy: float = 0.5) -> void:
	_world.get_player().teleport_grid(Vector2(float(cell.x) + 0.5, float(cell.y) + dy))
	_world.update_interaction()


func _near_id() -> String:
	var it: Interactable = _world.get_near_interactable()
	return it.id if it != null else ""


func _step_start() -> void:
	_mg().transitions = false
	_check(_world.get_adventure() != null and _world.get_adventure().stamina == AdventureState.MAX_STAMINA, "stamina awal penuh")
	_check(_world.get_location().id == "desa", "mulai di desa")


func _step_travel() -> void:
	var st: ClinicStats = _world.get_stats()
	var m0: int = st.money
	# desa -> hutan (keset barat)
	_world.get_player().teleport_grid(Vector2(0.5, 20.5))
	_check(_world.try_transition(true) and _world.get_location().id == "hutan", "keset barat desa membawa ke hutan")
	_check(_world.get_adventure().count("visit:hutan") == 1 and st.money == m0 + AdventureState.VISIT_BONUS, "kunjungan pertama hutan: bonus koin")
	# hutan -> pegunungan (keset utara)
	_world.get_player().teleport_grid(Vector2(11.5, 0.5))
	_check(_world.try_transition(true) and _world.get_location().id == "pegunungan", "keset utara hutan membawa ke pegunungan")
	# pegunungan -> hutan (keset selatan)
	_world.get_player().teleport_grid(Vector2(11.5, 21.5))
	_check(_world.try_transition(true) and _world.get_location().id == "hutan", "keset selatan pegunungan kembali ke hutan")
	_check(_world.get_adventure().count("visit:hutan") == 1, "kunjungan ulang tidak memberi bonus lagi")
	# hutan -> desa (keset timur)
	_world.get_player().teleport_grid(Vector2(23.5, 9.5))
	_check(_world.try_transition(true) and _world.get_location().id == "desa", "keset timur hutan kembali ke desa")
	# desa -> sungai (keset timur desa), menyeberang lewat jembatan
	_world.get_player().teleport_grid(Vector2(47.5, 20.5))
	_check(_world.try_transition(true) and _world.get_location().id == "sungai", "keset timur desa membawa ke sungai")
	_check(_world.get_adventure().count("visit:sungai") == 1, "sungai tercatat sebagai kunjungan")
	_world.load_location("hutan", "dari_desa")
	_check(not UiGate.blocked and not _world.is_minigame_open(), "kontrol dunia kembali setelah pindah area")


func _step_forage_known() -> void:
	## Bahan yang sudah dikenal: langsung masuk inventaris, memakai stamina, lalu titik tumbuh kembali.
	var adv: AdventureState = _world.get_adventure()
	var sk: SkillProgressionSystem = _world.get_skills()
	var inv: HerbInventory = _world.get_inventory()
	var node: Dictionary = ForageDb.get_node("forage_hutan_1")
	var now: float = _world.get_clock().absolute_minutes()
	var herb: String = String(ForageDb.roll("forage_hutan_1", int(now))["herb"])
	sk.learn_plant(herb)
	_stand(node["cell"])
	_check(_near_id() == "forage_hutan_1", "titik pengumpulan hutan dapat diinteraksi")
	var n0: int = inv.count(herb)
	var s0: float = adv.stamina
	var rare: bool = bool(ForageDb.roll("forage_hutan_1", int(now))["rare"])
	_check(_world.press_interact() and _mg().kind() == "info", "bahan dikenal: hasil langsung ditampilkan")
	var gain: int = 2 if rare else 1
	_check(inv.count(herb) == n0 + gain, "bahan masuk inventaris (+%d %s)" % [gain, herb])
	_check(absf(adv.stamina - (s0 - AdventureState.COST_GATHER)) < 0.01, "pengumpulan memakai stamina %d" % int(AdventureState.COST_GATHER))
	_check(adv.count("gather:hutan") == gain, "penghitung pengumpulan hutan bertambah")
	_mg().close()
	_check(not _world.is_minigame_open(), "hasil ditutup")
	_world.press_interact()
	_check(not _world.is_minigame_open(), "titik yang baru dikumpulkan belum tumbuh kembali (tidak membuka layar)")
	_check(not adv.node_ready("forage_hutan_1", now), "cooldown titik aktif")


func _step_forage_identify() -> void:
	## Tanaman belum dikenal -> identifikasi (Fase 5). Selesai -> dikenal, masuk Buku, dan panen masuk inventaris.
	var adv: AdventureState = _world.get_adventure()
	var sk: SkillProgressionSystem = _world.get_skills()
	var node_id: String = "forage_hutan_2"
	var node: Dictionary = ForageDb.get_node(node_id)
	var now: float = _world.get_clock().absolute_minutes()
	var herb: String = String(ForageDb.roll(node_id, int(now))["herb"])
	# pastikan tanaman ini belum dikenal
	var kp: Array[String] = []
	for p in sk.known_plants:
		if p != herb:
			kp.append(p)
	sk.known_plants = kp
	_stand(node["cell"])
	var s0: float = adv.stamina
	_check(_world.press_interact() and _mg().kind() == "identifikasi", "tanaman baru membuka minigame identifikasi")
	_check(absf(adv.stamina - (s0 - AdventureState.COST_IDENTIFY)) < 0.01, "identifikasi memakai stamina %d" % int(AdventureState.COST_IDENTIFY))
	var pv := _view() as PlantView
	var sys: PlantIdentificationSystem = pv.sys
	for part in HerbDb.PARTS:
		pv.click_button("part:%s" % part)
	pv.click_button("opt:%s" % sys.plant_id)
	_check(pv.has_result() and sys.succeeded(), "jawaban benar -> tanaman dikenali")
	pv.click_button("result_continue")
	_check(sk.knows_plant(herb) and adv.count("identify_new") == 1, "tanaman baru tercatat di Buku dan penghitung identifikasi")
	_check(adv.count("gather:hutan") >= 1, "pengumpulan dari identifikasi dihitung")
	_check(not _world.is_minigame_open(), "layar identifikasi ditutup")


func _step_board() -> void:
	## Papan Pengembara: misi pertama butuh 4 pengumpulan di hutan (sudah terpenuhi lewat langkah sebelumnya).
	var adv: AdventureState = _world.get_adventure()
	var st: ClinicStats = _world.get_stats()
	_stand(ForestLocation.BOARD_CELL, 1.4)
	_check(_near_id() == "adventure_board", "papan Pengembara dapat diinteraksi")
	adv.bump("gather:hutan", 4 - adv.count("gather:hutan") if adv.count("gather:hutan") < 4 else 0)
	var m0: int = st.money
	_check(_world.press_interact() and _mg().kind() == "info", "papan menampilkan misi")
	_check(st.money == m0 + 60 and adv.claimed.has("m_hutan"), "misi selesai: hadiah 60 koin diklaim sekali")
	_mg().close()
	_world.press_interact()
	_check(st.money == m0 + 60 and adv.claimed.size() == 1, "klaim tidak berulang")
	_mg().close()
	# selesaikan misi berikutnya lewat penghitung (kenali tanaman baru)
	adv.bump("identify_new", 3)
	_mg().close()
	m0 = st.money
	_check(_world.press_interact() and st.money == m0 + 90, "misi kedua (kenali 3 tanaman) diklaim: +90")
	_mg().close()


func _step_secret() -> void:
	## Celah rahasia di pegunungan: butuh Identifikasi tingkat 2 atau 3 tanaman dikenal.
	var adv: AdventureState = _world.get_adventure()
	var sk: SkillProgressionSystem = _world.get_skills()
	var inv: HerbInventory = _world.get_inventory()
	_world.load_location("pegunungan", "dari_hutan")
	_stand(MountainLocation.SECRET_CELL, 1.4)
	_check(_near_id() == "secret_cleft", "celah rahasia dapat diinteraksi")
	var saved_xp: int = sk.xp_of("identifikasi_tanaman")
	var known_backup: Array[String] = []
	for kp0 in sk.known_plants:
		known_backup.append(kp0)
	sk.known_plants = [] as Array[String]
	sk.xp["identifikasi_tanaman"] = 0
	var m: int = _world.get_stats().money
	_world.press_interact()
	_check(not _world.is_minigame_open() and not adv.has_secret(AdventureState.SECRET_ID), "syarat belum terpenuhi: celah tetap tertutup")
	## Syarat terbuka: tingkat Identifikasi minimal 2 (XP ambang level 2).
	sk.known_plants = known_backup
	sk.xp["identifikasi_tanaman"] = SkillDb.LEVEL_XP[1]
	var k0: int = inv.count(AdventureState.SECRET_HERB)
	var s0: float = adv.stamina
	_check(_world.press_interact() and _mg().kind() == "info", "syarat terpenuhi: celah terbuka")
	_check(adv.has_secret(AdventureState.SECRET_ID) and inv.count(AdventureState.SECRET_HERB) == k0 + AdventureState.SECRET_UNITS, "rahasia memberi bahan")
	_check(_world.get_stats().money == m + AdventureState.SECRET_COIN and absf(adv.stamina - (s0 - AdventureState.COST_SECRET)) < 0.01, "rahasia memberi koin dan memakai stamina")
	_mg().close()
	_world.press_interact()
	_check(_world.get_stats().money == m + AdventureState.SECRET_COIN and not _world.is_minigame_open(), "celah yang sudah dibuka tidak memberi hadiah lagi")
	sk.known_plants = known_backup
	sk.xp["identifikasi_tanaman"] = saved_xp


func _step_save() -> void:
	## Simpan di pegunungan dengan keadaan petualangan yang sudah berubah.
	_check(_world.save_game(), "simpan di pegunungan berhasil")
	var adv: AdventureState = _world.get_adventure()
	_snap = {"stamina": adv.stamina, "visit_h": adv.count("visit:hutan"), "gather": adv.count("gather:hutan"),
		"secret": adv.has_secret(AdventureState.SECRET_ID), "claimed": adv.claimed.size(), "money": _world.get_stats().money,
		"herbs": _world.get_inventory().total(), "known": _world.get_skills().known_plants.size(),
		"fl": adv.forage_last.size(), "minute": _world.get_clock().minute_f, "day": _world.get_clock().day}


func _step_reopen() -> void:
	_swap_world()
	var adv: AdventureState = _world.get_adventure()
	_check(_world.load_status == SaveSystem.Status.OK, "dunia baru memuat simpanan")
	_check(_world.get_location().id == "pegunungan", "lokasi pegunungan dipulihkan")
	_check(absf(adv.stamina - float(_snap["stamina"])) < 0.01, "stamina sama setelah dibuka ulang")
	_check(adv.count("visit:hutan") == _snap["visit_h"] and adv.count("gather:hutan") == _snap["gather"], "kunjungan & pengumpulan sama")
	_check(adv.has_secret(AdventureState.SECRET_ID) == _snap["secret"] and adv.claimed.size() == _snap["claimed"], "rahasia & misi diklaim sama")
	_check(_world.get_stats().money == _snap["money"] and _world.get_inventory().total() == _snap["herbs"], "koin & inventaris sama")
	_check(_world.get_skills().known_plants.size() == _snap["known"] and adv.forage_last.size() == _snap["fl"], "tanaman dikenal & cooldown sama")
	_check(_world.get_clock().day == _snap["day"], "hari sama")
	# berkas rusak: jatuh ke permainan baru tanpa crash
	var f := FileAccess.open(SaveSystem.path(), FileAccess.WRITE)
	f.store_string('{"version": 1, "data": {"loc')
	f.close()
	var b := FileAccess.open(SaveSystem.path(SaveSystem.BAK_NAME), FileAccess.WRITE)
	b.store_string("rusak")
	b.close()
	_swap_world()
	_check(_world.load_status == SaveSystem.Status.CORRUPT_NEW and _world.get_location().id == "desa", "simpanan rusak -> permainan baru di desa")
	_check(_world.get_adventure().stamina == AdventureState.MAX_STAMINA, "stamina permainan baru penuh")


func _step_final() -> void:
	_check(not UiGate.blocked, "kontrol dunia tidak terkunci di akhir")
