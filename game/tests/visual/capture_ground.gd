extends SceneTree
## Uji visual sistem tile dan ground (Fase 10): hamparan 10x10 per jenis (rumput, tanah, batu, air)
## dan satu area campuran. Memakai IsoGroundMapView yang sama dengan permainan, dengan ukuran tile
## seperti Ladang (44x30 dikali skala layar k) untuk lebar layar 1280. Butuh renderer nyata (xvfb).
## Keluaran: JPG di direktori dari SHOT_DIR (default /tmp/shots).

const SCREEN := Vector2(1280, 720)
const TILE_BASE := Vector2(44, 30)

var _dir: String = "/tmp/shots"
var _steps: Array[Callable] = []
var _i: int = 0
var _wait: int = 0
var _holder: Node2D
var _pending_name: String = ""


func _initialize() -> void:
	var env: String = OS.get_environment("SHOT_DIR")
	if env != "":
		_dir = env
	DirAccess.make_dir_recursive_absolute(_dir)
	var k: float = clampf(SCREEN.x / 420.0 * 1.25, 1.0, 1.8)
	var tile: Vector2 = TILE_BASE * k
	_steps = [
		func() -> void: _show_patch("90_hamparan_rumput_10x10", _uniform(10, 10, TileKinds.GRASS), tile),
		func() -> void: _show_patch("91_hamparan_tanah_10x10", _uniform(10, 10, TileKinds.DIRT), tile),
		func() -> void: _show_patch("92_hamparan_batu_10x10", _uniform(10, 10, TileKinds.STONE), tile),
		func() -> void: _show_patch("93_hamparan_air_10x10", _uniform(10, 10, TileKinds.WATER), tile),
		func() -> void: _show_patch("94_campuran_16x16", _mixed(16, 16), tile),
	]


func _process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	if _pending_name != "":
		_shot(_pending_name)
		_pending_name = ""
	if _i >= _steps.size():
		quit()
		return true
	_steps[_i].call()
	_i += 1
	_wait = 3
	return false


func _shot(name: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_jpg("%s/%s.jpg" % [_dir, name], 0.85)
	print("tangkapan: ", name, " ", img.get_size())


## Hamparan satu jenis tile.
func _uniform(w: int, h: int, kind: int) -> GroundMap:
	var kinds := PackedInt32Array()
	kinds.resize(w * h)
	kinds.fill(kind)
	return GroundMap.from_kinds(w, h, kinds)


## Area campuran: kuadran rumput, tanah, batu, dan air, dengan jalur batu di tengah.
func _mixed(w: int, h: int) -> GroundMap:
	var kinds := PackedInt32Array()
	kinds.resize(w * h)
	for y in range(h):
		for x in range(w):
			var k: int = TileKinds.GRASS
			if x >= w / 2 and y < h / 2:
				k = TileKinds.DIRT
			elif x < w / 2 and y >= h / 2:
				k = TileKinds.STONE
			elif x >= w / 2 and y >= h / 2:
				k = TileKinds.WATER
			if y == h / 2 - 1 or x == w / 2 - 1:
				k = TileKinds.STONE if (x + y) % 2 == 0 else k
			kinds[y * w + x] = k
	return GroundMap.from_kinds(w, h, kinds)


func _show_patch(name: String, map: GroundMap, tile: Vector2) -> void:
	if _holder != null:
		_holder.queue_free()
	_holder = Node2D.new()
	root.add_child(_holder)
	var view := IsoGroundMapView.new()
	view.map = map
	view.tile = tile
	_holder.add_child(view)
	var bounds: Rect2 = IsoMapMeshes.screen_bounds(map, tile)
	_holder.position = SCREEN * 0.5 - bounds.get_center()
	_pending_name = name
