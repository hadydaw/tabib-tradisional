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
