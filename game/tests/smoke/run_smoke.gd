extends SceneTree
## Tes asap headless: memuat scene prototipe, melewati semua profil render x ukuran tile x
## beban, lalu memastikan tidak ada error skrip dan jumlah node sesuai. Renderer headless
## tidak menggambar, jadi draw call dan FPS TIDAK bisa dinilai di sini (hanya di HP).
## Jalankan: godot --headless --path game -s res://tests/smoke/run_smoke.gd

const STEP_FRAMES: int = 3

var _scene: Node
var _plan: Array[Dictionary] = []
var _step: int = -1
var _frame: int = 0
var _fail: int = 0
var _count: int = 0


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/proto/iso_test.tscn")
	_scene = packed.instantiate()
	root.add_child(_scene)
	for profile in range(_scene.RENDER_PROFILE_NAMES.size()):
		for tile in range(_scene.TILE_OPTIONS.size()):
			for stress in [false, true]:
				_plan.append({"profile": profile, "tile": tile, "stress": stress})


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame % STEP_FRAMES != 0:
		return false
	if _step >= 0:
		_verify(_plan[_step])
	_step += 1
	if _step >= _plan.size():
		print("Tes asap: %d pemeriksaan, gagal: %d" % [_count, _fail])
		return true_exit()
	var p: Dictionary = _plan[_step]
	_scene.set_render_profile(p["profile"])
	_scene.set_tile_index(p["tile"])
	_scene.set_stress(p["stress"])
	return false


func true_exit() -> bool:
	quit(1 if _fail > 0 else 0)
	return true


func _verify(p: Dictionary) -> void:
	var st: Dictionary = _scene.get_state()
	var label: String = "profil %d tile %d beban %s" % [p["profile"], p["tile"], p["stress"]]
	var expected_actors: int = 6 + 1 + (_scene.STRESS_COUNT if p["stress"] else 0)
	_check(st["profile"] == p["profile"], "profil aktif " + label)
	_check(st["tile_index"] == p["tile"], "tile aktif " + label)
	_check(st["actor_count"] == expected_actors, "jumlah aktor %d (dapat %d) %s" % [expected_actors, st["actor_count"], label])
	var ground_ok: bool = (st["ground_class"] == "IsoGround") == (p["profile"] == 0)
	_check(ground_ok, "kelas lantai sesuai profil " + label)
	if p["profile"] == 3:
		_check(st["sprite_count"] == expected_actors - 1, "sprite atlas dipakai " + label)


func _check(cond: bool, name: String) -> void:
	_count += 1
	if cond:
		print("  OK   ", name)
	else:
		_fail += 1
		printerr("  GAGAL ", name)
