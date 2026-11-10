extends SceneTree
## Tes asap Fase 8 (headless, dunia nyata): bicara harian dan kepercayaan, pemberian bahan, bab cerita,
## quest cerita (tawaran, progres lewat area & identifikasi, penyerahan dengan pilihan), event desa berbasis
## jam permainan, dan simpan/muat lintas dunia (dunia dibuang lalu dibuat ulang). Tampilan hanya dinilai di HP.
## Jalankan: godot --headless --path game -s res://tests/smoke/run_smoke_social.gd

const DIR: String = "user://tes_asap_fase8"

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
	_steps = [_step_start, _step_talk, _step_gift, _step_chapter, _step_quest, _step_event, _step_save, _step_reopen, _step_final]


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
	print("Tes asap sosial Fase 8: %d pemeriksaan, gagal: %d" % [_count, _fail])
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


## Indeks pilihan dialog yang sedang tampil berdasarkan kunci teks, atau -99 bila tidak ada dialog.
func _idx(label_key: String) -> int:
	var v: Dictionary = _world.get_dialogue().view()
	if v.is_empty():
		return -99
	return (v["choices"] as Array).find(Locale.t(label_key))


func _swap_world() -> void:
	UiGate.blocked = false
	root.remove_child(_world)
	_world.free()
	_world = _new_world()


func _step_start() -> void:
	var clk: GameClock = _world.get_clock()
	clk.day = 1
	clk.minute_f = 720.0
	_world.get_sim().snap_to_schedule()
	_check(_world.get_location().id == "desa", "mulai di desa")
	_check(_world.get_social() != null and _world.get_social().trust_of("wiryo") == SocialDb.START_TRUST, "keadaan sosial awal tersedia")


func _step_talk() -> void:
	var so: SocialState = _world.get_social()
	var t0: int = so.trust_of("wiryo")
	_check(_world.start_dialogue("wiryo"), "dialog dengan Wiryo dimulai")
	_check(so.trust_of("wiryo") == t0 + SocialDb.TALK_GAIN, "bicara pertama hari ini menambah kepercayaan")
	_check(_idx("dlg.choice.gift") >= 0, "pilihan berikan bahan tersedia")
	_world.dialogue_choose(_idx("dlg.choice.bye"))
	_check(not _world.is_dialogue_active(), "dialog selesai")
	_check(_world.start_dialogue("wiryo"), "dialog kedua dengan Wiryo dimulai")
	_check(so.trust_of("wiryo") == t0 + SocialDb.TALK_GAIN, "bicara kedua di hari yang sama tidak menambah")
	_world.dialogue_choose(_idx("dlg.choice.bye"))


func _step_gift() -> void:
	var so: SocialState = _world.get_social()
	var inv: HerbInventory = _world.get_inventory()
	var liked: String = SocialDb.likes("wiryo")
	inv.add(liked, 1)
	var n0: int = inv.count(liked)
	var t0: int = so.trust_of("wiryo")
	_check(_world.start_dialogue("wiryo"), "dialog Wiryo untuk memberi bahan")
	_world.dialogue_choose(_idx("dlg.choice.gift"))
	_check(inv.count(liked) == n0 - 1, "bahan kesukaan berkurang dari tas")
	_check(so.trust_of("wiryo") == t0 + SocialDb.GIFT_LIKED, "bahan kesukaan menambah kepercayaan")
	_world.dialogue_choose(-1)
	_check(_world.is_dialogue_active(), "dialog lanjut setelah ucapan terima kasih")
	_world.dialogue_choose(_idx("dlg.choice.bye"))
	_check(_world.start_dialogue("wiryo"), "dialog Wiryo lagi")
	_check(_idx("dlg.choice.gift") == -99 or _idx("dlg.choice.gift") == -1, "pemberian kedua di hari yang sama tidak ditawarkan")
	_world.dialogue_choose(_idx("dlg.choice.bye"))


func _step_chapter() -> void:
	var so: SocialState = _world.get_social()
	so.trust["wiryo"] = 25
	var t0: int = so.trust_of("wiryo")
	_check(_world.start_dialogue("wiryo"), "dialog Wiryo untuk bab cerita")
	_check(_idx("dlg.choice.chapter") >= 0, "bab cerita terbuka saat kepercayaan 25")
	_world.dialogue_choose(_idx("dlg.choice.chapter"))
	_world.dialogue_choose(_idx("dlg.choice.more"))
	_check(so.chapter_seen("wiryo", 1), "bab 1 tercatat didengar")
	_check(so.trust_of("wiryo") == t0 + SocialDb.CHAPTER_GAIN, "mendengar bab menambah kepercayaan")
	_world.dialogue_choose(-1)
	_world.dialogue_choose(_idx("dlg.choice.bye"))
	_check(_world.start_dialogue("wiryo"), "dialog Wiryo setelah bab")
	_check(_idx("dlg.choice.chapter") == -1, "bab yang sudah didengar tidak ditawarkan lagi")
	_world.dialogue_choose(_idx("dlg.choice.bye"))


func _step_quest() -> void:
	var so: SocialState = _world.get_social()
	var st: ClinicStats = _world.get_stats()
	so.trust["karto"] = 45
	_check(_world.start_dialogue("karto"), "dialog Karto dimulai")
	_check(_idx("dlg.choice.quest") >= 0, "Karto menawarkan tugas")
	_world.dialogue_choose(_idx("dlg.choice.quest"))
	_world.dialogue_choose(_idx("dlg.choice.accept"))
	_check(so.status("q_karto_kebun") == SocialState.ACTIVE, "tugas Karto diterima")
	_world.dialogue_choose(-1)
	_check(not _world.is_dialogue_active(), "dialog selesai setelah menerima tugas")

	_world.report_progress("identify", "any")
	_check(not so.is_ready("q_karto_kebun"), "satu identifikasi belum menyelesaikan tugas")
	_world.report_progress("identify", "any")
	_check(so.is_ready("q_karto_kebun"), "dua identifikasi membuat tugas siap")

	var t_before: int = so.trust_of("karto")
	var coin0: int = st.money
	var rep0: float = st.reputation
	_check(_world.start_dialogue("karto"), "dialog Karto untuk lapor")
	_check(_idx("dlg.choice.report_quest") >= 0, "pilihan lapor tugas muncul")
	_world.dialogue_choose(_idx("dlg.choice.report_quest"))
	_world.dialogue_choose(_idx("sq.q_karto_kebun.opt.bagi_jasa"))
	_check(so.status("q_karto_kebun") == SocialState.DONE, "tugas Karto selesai")
	_check(st.money == coin0 + 20, "hadiah koin tugas Karto masuk buku kas")
	_check(absf(st.reputation - (rep0 + 2.0)) < 0.01, "reputasi desa naik sesuai pilihan")
	_check(so.trust_of("karto") == t_before + 6, "kepercayaan Karto naik dari pilihan")
	_world.dialogue_choose(-1)
	_check(not _world.is_dialogue_active(), "dialog selesai setelah lapor")

	# Tugas Dewi: masuk Sungai menyelesaikan langkah.
	so.trust["dewi"] = 15
	_check(_world.start_dialogue("dewi"), "dialog Dewi dimulai")
	_world.dialogue_choose(_idx("dlg.choice.quest"))
	_world.dialogue_choose(_idx("dlg.choice.accept"))
	_world.dialogue_choose(-1)
	_check(so.status("q_dewi_sungai") == SocialState.ACTIVE, "tugas Dewi diterima")
	_world.load_location("sungai", "dari_desa")
	_check(so.is_ready("q_dewi_sungai"), "tiba di Sungai menyelesaikan langkah tugas Dewi")
	_world.load_location("desa", "dari_sungai")
	_check(_world.get_location().id == "desa", "kembali ke desa")


func _step_event() -> void:
	var so: SocialState = _world.get_social()
	var st: ClinicStats = _world.get_stats()
	var clk: GameClock = _world.get_clock()
	clk.day = 3
	clk.minute_f = 500.0
	var coin0: int = st.money
	_world.step_world(0.0)
	_check(st.money == coin0 + 20, "pasar desa hari 3: hadiah koin saat berada di desa")
	_check(so.event_claimed("pasar_desa", 3), "event pasar tercatat diklaim")
	_world.step_world(0.0)
	_check(st.money == coin0 + 20, "event yang sama tidak memberi hadiah dua kali")
	clk.minute_f = 1100.0
	clk.day = 4
	var t0: int = so.trust_of("karto")
	_world.step_world(0.0)
	_check(so.trust_of("karto") == t0 + int(VillageEvents.def("malam_bakti")["trust_all"]), "malam bakti hari 4: semua penduduk makin percaya")
	_check(so.event_claimed("malam_bakti", 4), "malam bakti tercatat diklaim")


func _step_save() -> void:
	_check(_world.save_game(), "simpan berhasil")
	var so: SocialState = _world.get_social()
	var st: ClinicStats = _world.get_stats()
	_snap = {"wiryo": so.trust_of("wiryo"), "karto": so.trust_of("karto"), "chapter": so.chapter_seen("wiryo", 1),
		"quest": so.status("q_karto_kebun"), "dewi": so.status("q_dewi_sungai"), "claim": so.event_claimed("pasar_desa", 3),
		"money": st.money, "rep": st.reputation, "gift": so.gift_available("wiryo", 1)}


func _step_reopen() -> void:
	_swap_world()
	var so: SocialState = _world.get_social()
	var st: ClinicStats = _world.get_stats()
	_check(_world.load_status == SaveSystem.Status.OK, "dunia baru memuat simpanan")
	_check(so.trust_of("wiryo") == int(_snap["wiryo"]) and so.trust_of("karto") == int(_snap["karto"]), "kepercayaan NPC sama setelah dibuka ulang")
	_check(so.chapter_seen("wiryo", 1) == bool(_snap["chapter"]), "bab cerita yang sudah didengar tersimpan")
	_check(so.status("q_karto_kebun") == int(_snap["quest"]) and so.status("q_dewi_sungai") == SocialState.ACTIVE, "status quest tersimpan")
	_check(so.event_claimed("pasar_desa", 3) == bool(_snap["claim"]), "klaim event tersimpan")
	_check(st.money == int(_snap["money"]) and absf(st.reputation - float(_snap["rep"])) < 0.01, "koin dan reputasi desa sama")
	_check(so.gift_available("wiryo", 1) == bool(_snap["gift"]), "catatan pemberian harian tersimpan")
	# berkas rusak: jatuh ke permainan baru tanpa crash
	var f := FileAccess.open(SaveSystem.path(), FileAccess.WRITE)
	f.store_string('{"version": 1, "data": {"loc')
	f.close()
	var b := FileAccess.open(SaveSystem.path(SaveSystem.BAK_NAME), FileAccess.WRITE)
	b.store_string("rusak")
	b.close()
	_swap_world()
	_check(_world.load_status == SaveSystem.Status.CORRUPT_NEW, "simpanan rusak terdeteksi")
	_check(_world.get_social().trust_of("karto") == SocialDb.START_TRUST, "simpanan rusak -> hubungan mulai dari awal")


func _step_final() -> void:
	_check(not UiGate.blocked, "kontrol dunia tidak terkunci di akhir")
	_check(not _world.is_dialogue_active(), "tidak ada dialog yang tertinggal")
