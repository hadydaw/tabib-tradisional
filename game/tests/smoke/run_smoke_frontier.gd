extends SceneTree
## Tes asap Fase 9 (headless, dunia nyata): penemuan langka di Rawa, teka-teki (salah lalu benar), kabut,
## gerbang Gua Kapur (syarat penemuan), tablet dan tuas, peti, serta simpan/muat lintas dunia.
## Jalankan: godot --headless --path game -s res://tests/smoke/run_smoke_frontier.gd

const DIR: String = "user://tes_asap_fase9"

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
	_steps = [_step_start, _step_rare, _step_fog, _step_gate, _step_gua, _step_save, _step_reopen, _step_final]


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
	print("Tes asap eksplorasi Fase 9: %d pemeriksaan, gagal: %d" % [_count, _fail])
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


func _swap_world() -> void:
	UiGate.blocked = false
	root.remove_child(_world)
	_world.free()
	_world = _new_world()


func _blocked(c: Vector2i) -> bool:
	return _world.get_collision().is_cell_blocked(c)


## Pilih simbol satu per satu lalu konfirmasi pada layar teka-teki yang sedang terbuka.
func _answer(seq: Array[String]) -> void:
	var v: PuzzleView = _world.get_minigames().current_view() as PuzzleView
	if v == null:
		return
	for s in seq:
		v.click_button("sym:%s" % s)
	v.click_button("confirm")


func _step_start() -> void:
	var clk: GameClock = _world.get_clock()
	clk.day = 1
	clk.minute_f = 720.0
	_world.get_sim().snap_to_schedule()
	_check(_world.get_frontier() != null, "keadaan eksplorasi lanjut tersedia")
	_check(_world.get_location().id == "desa", "mulai di desa")


func _step_rare() -> void:
	var f: FrontierState = _world.get_frontier()
	_world.load_location("sungai", "dari_desa")
	_check(_world.load_location("rawa", "dari_sungai"), "masuk Rawa dari Sungai")
	_check(_world.get_location().id == "rawa", "lokasi Rawa aktif")
	var mg: MinigameManager = _world.get_minigames()
	_check(mg.start_rare("rawa_1"), "ambil bahan langka dari rumpun basah")
	_check(f.distinct_found() == 1, "penemuan pertama tercatat di Buku Tabib")
	mg.close()
	_check(not mg.start_rare("rawa_1"), "rumpun yang sama beristirahat setelah diambil")
	_check(mg.start_rare("rawa_2"), "rumpun lain di Rawa bisa diambil")
	mg.close()


func _step_fog() -> void:
	var mg: MinigameManager = _world.get_minigames()
	var f: FrontierState = _world.get_frontier()
	_check(_blocked(Vector2i(16, 9)), "kabut menutup rawa dalam")
	_check(mg.start_puzzle("penjaga_rawa"), "buka teka-teki Penjaga Rawa")
	_answer(["api", "api", "api"])
	_check(not f.puzzle_solved("penjaga_rawa") and mg.current_view() is PuzzleView, "jawaban salah tidak menyelesaikan teka-teki")
	_answer(["air", "angin", "api"])
	_check(f.puzzle_solved("penjaga_rawa"), "jawaban benar menyelesaikan teka-teki")
	_check(not _blocked(Vector2i(16, 9)), "kabut terangkat setelah teka-teki selesai")
	mg.close()
	_check(not mg.start_puzzle("penjaga_rawa"), "teka-teki yang sudah selesai tidak bisa diulang")


func _step_gate() -> void:
	var f: FrontierState = _world.get_frontier()
	_world.load_location("pegunungan", "dari_hutan")
	_world.get_player().teleport_grid(Vector2(23.5, 10.5))
	_check(not _world.try_transition(true) and _world.get_location().id == "pegunungan", "gua terkunci sebelum penemuan cukup")
	f.discover("akar_rawa")
	f.discover("benih_cendana")
	_check(_world.try_transition(true) and _world.get_location().id == "gua", "gua terbuka setelah dua jenis penemuan")


func _step_gua() -> void:
	var f: FrontierState = _world.get_frontier()
	var mg: MinigameManager = _world.get_minigames()
	_check(_blocked(Vector2i(10, 10)), "pintu tablet tertutup di awal")
	_check(_blocked(Vector2i(6, 5)), "celah tuas tertutup di awal")
	_check(mg.start_puzzle("tablet_gua"), "buka tablet batu")
	_answer(["tanah", "api", "air"])
	_check(f.puzzle_solved("tablet_gua") and not _blocked(Vector2i(10, 10)), "tablet membuka pintu ke ruang dalam")
	mg.close()
	_check(mg.start_puzzle("tuas_gua"), "tarik tuas batu")
	_answer(["angin", "tanah"])
	_check(f.puzzle_solved("tuas_gua") and not _blocked(Vector2i(6, 5)), "tuas membuka celah ke ceruk")
	mg.close()
	_check(mg.start_chest(), "buka peti gua")
	mg.close()
	_check(f.chest_opened and not mg.start_chest(), "peti hanya bisa dibuka sekali")
	mg.close()
	_check(mg.start_rare("gua_1"), "titik jamur gua bisa diambil")
	mg.close()


func _step_save() -> void:
	_check(_world.save_game(), "simpan berhasil")
	var f: FrontierState = _world.get_frontier()
	_snap = {"distinct": f.distinct_found(), "akar": f.count("akar_rawa"), "penjaga": f.puzzle_solved("penjaga_rawa"),
		"tuas": f.puzzle_solved("tuas_gua"), "peti": f.chest_opened}


func _step_reopen() -> void:
	_swap_world()
	var f: FrontierState = _world.get_frontier()
	_check(_world.load_status == SaveSystem.Status.OK, "dunia baru memuat simpanan")
	_check(f.distinct_found() == int(_snap["distinct"]) and f.count("akar_rawa") == int(_snap["akar"]), "penemuan langka tersimpan")
	_check(f.puzzle_solved("penjaga_rawa") == bool(_snap["penjaga"]) and f.puzzle_solved("tuas_gua") == bool(_snap["tuas"]), "teka-teki tersimpan")
	_check(f.chest_opened == bool(_snap["peti"]), "peti yang sudah dibuka tersimpan")
	_check(_world.get_location().id == "gua", "lokasi gua dipulihkan")
	_check(not _blocked(Vector2i(10, 10)) and not _blocked(Vector2i(6, 5)), "segel gua tetap terbuka setelah dimuat")


func _step_final() -> void:
	_check(not UiGate.blocked, "kontrol dunia tidak terkunci di akhir")
	_check(not _world.is_minigame_open(), "tidak ada layar minigame yang tertinggal")
