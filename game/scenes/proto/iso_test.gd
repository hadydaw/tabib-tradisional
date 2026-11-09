extends Node2D
## Prototipe teknis Fase 1 (bukan gameplay). Menguji: tile isometrik 64x32 vs 128x64,
## pemain placeholder 8 arah, joystick virtual, Y-sort pada posisi kaki, kamera,
## tombol interaksi, dan info perangkat (untuk uji kompatibilitas di HP).
## Semua visual digambar lewat kode; tidak ada aset eksternal.

const GRID_SIZE: int = 16
const TILE_OPTIONS: Array[Vector2] = [Vector2(64, 32), Vector2(128, 64)]
const SPEED_TILE_WIDTHS_PER_SEC: float = 1.6
const PROP_CELLS: Array[Vector2i] = [
	Vector2i(5, 5), Vector2i(10, 6), Vector2i(7, 11),
	Vector2i(12, 12), Vector2i(4, 9), Vector2i(9, 9),
]

var _tile_index: int = 0
var _tile: Vector2 = TILE_OPTIONS[0]
var _ground: IsoGround
var _actors: Node2D
var _player: PlayerPlaceholder
var _props: Array[IsoProp] = []
var _camera: Camera2D
var _player_grid: Vector2 = Vector2(8.5, 8.5)
var _facing: int = 0
var _joy: Vector2 = Vector2.ZERO

var _joystick: TouchJoystick
var _btn_interact: TouchActionButton
var _btn_tile: TouchActionButton
var _info: Label
var _toast: Label
var _toast_left: float = 0.0
var _info_timer: float = 0.0


func _ready() -> void:
	_camera = Camera2D.new()
	add_child(_camera)
	_build_world()
	_build_hud()
	get_viewport().size_changed.connect(_layout_hud)
	_layout_hud()
	_refresh_info()


func _process(delta: float) -> void:
	var move: Vector2 = _read_input()
	if move.length() > 0.01:
		_facing = IsoMath.direction_index(move)
		var px_per_sec: float = _tile.x * SPEED_TILE_WIDTHS_PER_SEC
		var screen_vel := Vector2(move.x, move.y * 0.5) * px_per_sec
		var pos: Vector2 = IsoMath.grid_to_screen(_player_grid, _tile) + screen_vel * delta
		var limit: float = float(GRID_SIZE) - 0.3
		_player_grid = IsoMath.screen_to_grid(pos, _tile).clamp(Vector2(0.3, 0.3), Vector2(limit, limit))
	_apply_player()
	_camera.global_position = _player.global_position + Vector2(0.0, -_tile.y)
	_info_timer -= delta
	if _info_timer <= 0.0:
		_info_timer = 0.25
		_refresh_info()
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.modulate.a = clampf(_toast_left / 0.5, 0.0, 1.0)


func _read_input() -> Vector2:
	# Keyboard hanya untuk uji di komputer; di Android yang dipakai joystick.
	var k := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if k.length() > 0.0:
		return k.normalized()
	return _joy


func _build_world() -> void:
	if _ground != null:
		_ground.queue_free()
	if _actors != null:
		_actors.queue_free()
	_props.clear()
	_tile = TILE_OPTIONS[_tile_index]
	_ground = IsoGround.new()
	_ground.grid_size = GRID_SIZE
	_ground.tile = _tile
	add_child(_ground)
	# Pemain dan objek berada dalam satu kelompok Y-sort (urut berdasarkan posisi kaki).
	_actors = Node2D.new()
	_actors.y_sort_enabled = true
	add_child(_actors)
	for cell: Vector2i in PROP_CELLS:
		var prop := IsoProp.new()
		prop.tile = _tile
		prop.height = _tile.y * (1.5 + float((cell.x + cell.y) % 3) * 0.6)
		prop.position = IsoMath.grid_to_screen(Vector2(cell.x + 0.5, cell.y + 0.5), _tile)
		_actors.add_child(prop)
		_props.append(prop)
	_player = PlayerPlaceholder.new()
	_player.body_scale = _tile.x / 64.0
	_actors.add_child(_player)
	_apply_player()


func _apply_player() -> void:
	_player.position = IsoMath.grid_to_screen(_player_grid, _tile)
	_player.facing = _facing


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 18)
	_info.add_theme_color_override("font_outline_color", Color.BLACK)
	_info.add_theme_constant_override("outline_size", 6)
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_info)

	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 26)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	layer.add_child(_toast)

	_joystick = TouchJoystick.new()
	_joystick.vector_changed.connect(func(v: Vector2) -> void: _joy = v)
	layer.add_child(_joystick)

	_btn_interact = TouchActionButton.new()
	_btn_interact.text = "Interaksi"
	_btn_interact.pressed.connect(_on_interact)
	layer.add_child(_btn_interact)

	_btn_tile = TouchActionButton.new()
	_btn_tile.font_size = 22
	_btn_tile.pressed.connect(_on_toggle_tile)
	layer.add_child(_btn_tile)
	_update_tile_button()


func _layout_hud() -> void:
	var vis: Vector2 = get_viewport().get_visible_rect().size
	var safe: Rect2 = _safe_rect(vis)
	_info.position = safe.position + Vector2(16.0, 10.0)
	_btn_tile.size = Vector2(250.0, 64.0)
	_btn_tile.position = Vector2(safe.end.x - 250.0 - 16.0, safe.position.y + 10.0)
	_joystick.size = Vector2(260.0, 260.0)
	_joystick.position = Vector2(safe.position.x + 24.0, safe.end.y - 260.0 - 24.0)
	_btn_interact.size = Vector2(150.0, 150.0)
	_btn_interact.position = Vector2(safe.end.x - 150.0 - 40.0, safe.end.y - 150.0 - 40.0)
	_toast.size = Vector2(700.0, 40.0)
	_toast.position = Vector2(vis.x * 0.5 - 350.0, safe.position.y + 90.0)


## Area aman (di luar notch/cutout) dalam koordinat viewport virtual. Hanya di Android.
func _safe_rect(vis: Vector2) -> Rect2:
	var full := Rect2(Vector2.ZERO, vis)
	if OS.get_name() != "Android":
		return full
	var win := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if win.x <= 0.0 or win.y <= 0.0 or safe.size.x <= 0.0 or safe.size.y <= 0.0:
		return full
	var k: Vector2 = vis / win
	return full.intersection(Rect2(safe.position * k, safe.size * k))


func _update_tile_button() -> void:
	var t: Vector2 = TILE_OPTIONS[_tile_index]
	_btn_tile.text = "Tile %dx%d (ganti)" % [int(t.x), int(t.y)]


func _on_toggle_tile() -> void:
	_tile_index = (_tile_index + 1) % TILE_OPTIONS.size()
	_build_world()
	_update_tile_button()
	_show_toast("Ukuran tile: %dx%d" % [int(_tile.x), int(_tile.y)])


func _on_interact() -> void:
	var best: int = -1
	var best_dist: float = 1.6
	for i in range(_props.size()):
		var prop_grid: Vector2 = IsoMath.screen_to_grid(_props[i].position, _tile)
		var dist: float = prop_grid.distance_to(_player_grid)
		if dist < best_dist:
			best_dist = dist
			best = i
	if best >= 0:
		_show_toast("Interaksi: objek #%d (jarak %.1f tile)" % [best + 1, best_dist])
	else:
		_show_toast("Tidak ada objek di dekat sini")


func _show_toast(message: String) -> void:
	_toast.text = message
	_toast_left = 2.0
	_toast.modulate.a = 1.0


func _refresh_info() -> void:
	var win: Vector2i = DisplayServer.window_get_size()
	var vis: Vector2 = get_viewport().get_visible_rect().size
	var model: String = OS.get_model_name()
	_info.text = "FPS %d | Tile %dx%d | Arah %s | Grid %.1f, %.1f\nLayar %dx%d (virtual %dx%d) | DPI %d\nRender %s | %s %s" % [
		int(Engine.get_frames_per_second()), int(_tile.x), int(_tile.y),
		IsoMath.direction_name(_facing), _player_grid.x, _player_grid.y,
		win.x, win.y, int(vis.x), int(vis.y), DisplayServer.screen_get_dpi(),
		RenderingServer.get_current_rendering_method(), OS.get_name(), model,
	]
