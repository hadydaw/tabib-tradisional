extends Node2D
## Prototipe teknis Fase 1 (bukan gameplay). Menguji: tile isometrik 64x32 vs 128x64,
## pemain placeholder 8 arah, joystick virtual, Y-sort pada posisi kaki, kamera,
## tombol interaksi, serta alat ukur performa dan info perangkat untuk uji di HP.
## Semua visual digambar lewat kode; tidak ada aset eksternal.

const GRID_SIZE: int = 16
const TILE_OPTIONS: Array[Vector2] = [Vector2(64, 32), Vector2(128, 64)]
const SPEED_TILE_WIDTHS_PER_SEC: float = 1.6
const PROP_CELLS: Array[Vector2i] = [
	Vector2i(5, 5), Vector2i(10, 6), Vector2i(7, 11),
	Vector2i(12, 12), Vector2i(4, 9), Vector2i(9, 9),
]
## Uji beban: jumlah objek tambahan untuk mengukur biaya Y-sort dan gambar.
const STRESS_COUNT: int = 300
const FPS_CAP_OPTIONS: Array[int] = [0, 60, 30]  # 0 = tanpa batas (ikut refresh layar)
const FRAME_WINDOW: int = 300
## Frame awal setelah setiap perubahan (ganti tile/profil/beban) yang tidak dihitung,
## agar lonjakan pembangunan dunia tidak mencemari statistik.
const WARMUP_FRAMES: int = 60
const INFO_INTERVAL_SEC: float = 1.0
const JANK_MS: float = 20.0
## Profil render: eksperimen untuk memisahkan penyebab biaya. Bentuk dan warna sama di semua
## profil; hanya cara menggambarnya yang berbeda.
##   0 = awal: lantai 512 draw call, balok 4 draw call
##   1 = lantai jadi 2 mesh (2 draw call); balok tetap poligon
##   2 = lantai mesh + balok 1 mesh (jumlah node sama dengan 1, draw call per balok 1/4)
##   3 = lantai mesh + balok Sprite2D dari satu atlas tekstur (bisa di-batch)
const RENDER_PROFILE_NAMES: Array[String] = [
	"0 Poligon (awal)", "1 Lantai mesh", "2 Lantai+balok mesh", "3 Lantai mesh+atlas sprite",
]
## Tiga varian tinggi balok (kelipatan tile.y), dipakai oleh semua profil.
const HEIGHT_FACTORS: Array[float] = [1.5, 2.1, 2.7]

var _tile_index: int = 0
var _tile: Vector2 = TILE_OPTIONS[0]
var _profile: int = 0
var _atlas: IsoSpriteAtlas
var _ground: Node2D
var _actors: Node2D
var _player: PlayerPlaceholder
var _props: Array[Node2D] = []
var _stress_props: Array[Node2D] = []
var _stress_on: bool = false
var _fps_cap_index: int = 0
var _camera: Camera2D
var _player_grid: Vector2 = Vector2(8.5, 8.5)
var _facing: int = 0
var _joy: Vector2 = Vector2.ZERO

var _joystick: TouchJoystick
var _btn_interact: TouchActionButton
var _btn_tile: TouchActionButton
var _btn_stress: TouchActionButton
var _btn_fps: TouchActionButton
var _btn_profile: TouchActionButton
var _info: Label
var _toast: Label
var _toast_left: float = 0.0
var _info_timer: float = 0.0
var _safe_size: Vector2 = Vector2.ZERO

# Jendela geser (ring buffer) per metrik, dalam ms. Dicatat tiap frame setelah pemanasan.
var _frame_ms: PackedFloat32Array = PackedFloat32Array()
var _script_ms: PackedFloat32Array = PackedFloat32Array()
var _draw_ms: PackedFloat32Array = PackedFloat32Array()
var _frame_head: int = 0
var _warmup_left: int = WARMUP_FRAMES
var _draw_start_us: int = 0
var _last_draw_ms: float = 0.0
var _hud_ms: float = 0.0


func _ready() -> void:
	_camera = Camera2D.new()
	add_child(_camera)
	RenderingServer.frame_pre_draw.connect(_on_frame_pre_draw)
	RenderingServer.frame_post_draw.connect(_on_frame_post_draw)
	_build_world()
	_build_hud()
	get_viewport().size_changed.connect(_layout_hud)
	_layout_hud()
	_refresh_info()


func _process(delta: float) -> void:
	var t0: int = Time.get_ticks_usec()
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
		_info_timer = INFO_INTERVAL_SEC
		var h0: int = Time.get_ticks_usec()
		_refresh_info()
		_hud_ms = float(Time.get_ticks_usec() - h0) / 1000.0
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.modulate.a = clampf(_toast_left / 0.5, 0.0, 1.0)
	_record_frame(delta, float(Time.get_ticks_usec() - t0) / 1000.0)


func _on_frame_pre_draw() -> void:
	_draw_start_us = Time.get_ticks_usec()


func _on_frame_post_draw() -> void:
	_last_draw_ms = float(Time.get_ticks_usec() - _draw_start_us) / 1000.0


# --- Hook publik untuk tes asap dan uji terkontrol ----------------------------

func set_render_profile(index: int) -> void:
	_profile = clampi(index, 0, RENDER_PROFILE_NAMES.size() - 1)
	_build_world()
	_update_button_labels()


func set_tile_index(index: int) -> void:
	_tile_index = clampi(index, 0, TILE_OPTIONS.size() - 1)
	_build_world()
	_update_button_labels()


func set_stress(enabled: bool) -> void:
	if enabled == _stress_on:
		return
	_stress_on = enabled
	if _stress_on:
		_spawn_stress()
	else:
		_clear_stress()
	_reset_frame_stats()
	_update_button_labels()


func get_state() -> Dictionary:
	var sprites: int = 0
	for child in _actors.get_children():
		if child is Sprite2D and not child.is_queued_for_deletion():
			sprites += 1
	var live: int = 0
	for child in _actors.get_children():
		if not child.is_queued_for_deletion():
			live += 1
	return {
		"profile": _profile, "tile_index": _tile_index, "actor_count": live,
		"sprite_count": sprites, "ground_class": _ground.get_script().get_global_name(),
	}


func _read_input() -> Vector2:
	# Keyboard hanya untuk uji di komputer; di Android yang dipakai joystick.
	var k := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if k.length() > 0.0:
		return k.normalized()
	return _joy


# --- Dunia -------------------------------------------------------------------

func _build_world() -> void:
	if _ground != null:
		_ground.queue_free()
	if _actors != null:
		_actors.queue_free()
	_props.clear()
	_stress_props.clear()
	_reset_frame_stats()
	_tile = TILE_OPTIONS[_tile_index]
	_atlas = null
	if _profile == 3:
		var heights: Array[float] = []
		for f: float in HEIGHT_FACTORS:
			heights.append(_tile.y * f)
		_atlas = IsoSpriteAtlas.new(_tile, heights)
	if _profile == 0:
		var g := IsoGround.new()
		g.grid_size = GRID_SIZE
		g.tile = _tile
		_ground = g
	else:
		var gm := IsoGroundMesh.new()
		gm.grid_size = GRID_SIZE
		gm.tile = _tile
		_ground = gm
	add_child(_ground)
	# Pemain dan objek berada dalam satu kelompok Y-sort (urut berdasarkan posisi kaki).
	_actors = Node2D.new()
	_actors.y_sort_enabled = true
	add_child(_actors)
	for cell: Vector2i in PROP_CELLS:
		var prop := _make_prop(cell)
		_actors.add_child(prop)
		_props.append(prop)
	_player = PlayerPlaceholder.new()
	_player.body_scale = _tile.x / 64.0
	_actors.add_child(_player)
	_apply_player()
	if _stress_on:
		_spawn_stress()


func _make_prop(cell: Vector2i) -> Node2D:
	var variant: int = (cell.x + cell.y) % 3
	var height: float = _tile.y * HEIGHT_FACTORS[variant]
	var prop: Node2D
	match _profile:
		0, 1:
			var poly := IsoProp.new()
			poly.tile = _tile
			poly.height = height
			prop = poly
		2:
			var mesh_prop := IsoMeshProp.new()
			mesh_prop.setup(_tile, height)
			prop = mesh_prop
		_:
			prop = _atlas.make_sprite(variant)
	prop.position = IsoMath.grid_to_screen(Vector2(cell.x + 0.5, cell.y + 0.5), _tile)
	return prop


func _spawn_stress() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261109  # tetap, agar hasil uji bisa dibandingkan antar-perangkat
	for i in range(STRESS_COUNT):
		var cell := Vector2i(rng.randi_range(0, GRID_SIZE - 1), rng.randi_range(0, GRID_SIZE - 1))
		var prop := _make_prop(cell)
		_actors.add_child(prop)
		_stress_props.append(prop)


func _clear_stress() -> void:
	for prop in _stress_props:
		prop.queue_free()
	_stress_props.clear()


func _apply_player() -> void:
	_player.position = IsoMath.grid_to_screen(_player_grid, _tile)
	_player.facing = _facing


# --- Statistik frame ---------------------------------------------------------

func _record_frame(delta: float, script_ms: float) -> void:
	if _warmup_left > 0:
		_warmup_left -= 1
		return
	_push(_frame_ms, delta * 1000.0)
	_push(_script_ms, script_ms)
	_push(_draw_ms, _last_draw_ms)
	_frame_head = (_frame_head + 1) % FRAME_WINDOW


func _push(buf: PackedFloat32Array, value: float) -> void:
	if buf.size() < FRAME_WINDOW:
		buf.append(value)
	else:
		buf[_frame_head] = value


func _reset_frame_stats() -> void:
	_frame_ms.clear()
	_script_ms.clear()
	_draw_ms.clear()
	_frame_head = 0
	_warmup_left = WARMUP_FRAMES


# --- HUD ---------------------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 17)
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

	_btn_stress = TouchActionButton.new()
	_btn_stress.font_size = 22
	_btn_stress.pressed.connect(_on_toggle_stress)
	layer.add_child(_btn_stress)

	_btn_fps = TouchActionButton.new()
	_btn_fps.font_size = 22
	_btn_fps.pressed.connect(_on_cycle_fps)
	layer.add_child(_btn_fps)

	_btn_profile = TouchActionButton.new()
	_btn_profile.font_size = 20
	_btn_profile.pressed.connect(_on_cycle_profile)
	layer.add_child(_btn_profile)

	_update_button_labels()


func _layout_hud() -> void:
	var vis: Vector2 = get_viewport().get_visible_rect().size
	var safe: Rect2 = _safe_rect(vis)
	_safe_size = safe.size
	_info.position = safe.position + Vector2(16.0, 8.0)
	var bx: float = safe.end.x - 270.0 - 16.0
	var by: float = safe.position.y + 8.0
	for btn: TouchActionButton in [_btn_profile, _btn_tile, _btn_stress, _btn_fps]:
		btn.size = Vector2(270.0, 56.0)
		btn.position = Vector2(bx, by)
		by += 64.0
	_joystick.size = Vector2(260.0, 260.0)
	_joystick.position = Vector2(safe.position.x + 24.0, safe.end.y - 260.0 - 24.0)
	_btn_interact.size = Vector2(150.0, 150.0)
	_btn_interact.position = Vector2(safe.end.x - 150.0 - 40.0, safe.end.y - 150.0 - 40.0)
	_toast.size = Vector2(700.0, 40.0)
	_toast.position = Vector2(vis.x * 0.5 - 350.0, safe.position.y + 110.0)


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


func _update_button_labels() -> void:
	var t: Vector2 = TILE_OPTIONS[_tile_index]
	_btn_tile.text = "Tile %dx%d (ganti)" % [int(t.x), int(t.y)]
	_btn_stress.text = "Beban +%d: %s" % [STRESS_COUNT, "NYALA" if _stress_on else "mati"]
	var cap: int = FPS_CAP_OPTIONS[_fps_cap_index]
	_btn_fps.text = "FPS maks: %s" % ("auto" if cap == 0 else str(cap))
	_btn_profile.text = "Profil " + RENDER_PROFILE_NAMES[_profile]


func _on_cycle_profile() -> void:
	set_render_profile((_profile + 1) % RENDER_PROFILE_NAMES.size())
	_show_toast("Profil render " + RENDER_PROFILE_NAMES[_profile])


func _on_toggle_tile() -> void:
	set_tile_index((_tile_index + 1) % TILE_OPTIONS.size())
	_show_toast("Ukuran tile: %dx%d" % [int(_tile.x), int(_tile.y)])


func _on_toggle_stress() -> void:
	set_stress(not _stress_on)
	_show_toast("Uji beban %s" % ("dinyalakan" if _stress_on else "dimatikan"))


func _on_cycle_fps() -> void:
	_fps_cap_index = (_fps_cap_index + 1) % FPS_CAP_OPTIONS.size()
	Engine.max_fps = FPS_CAP_OPTIONS[_fps_cap_index]
	_reset_frame_stats()
	_update_button_labels()
	_show_toast("Batas FPS: %s" % ("auto" if Engine.max_fps == 0 else str(Engine.max_fps)))


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
	var st: Dictionary = PerfStats.summarize(_frame_ms, JANK_MS)
	var sc: Dictionary = PerfStats.summarize(_script_ms, JANK_MS)
	var dr: Dictionary = PerfStats.summarize(_draw_ms, JANK_MS)
	var mem: Dictionary = OS.get_memory_info()
	var phys: int = int(mem.get("physical", -1))
	var phys_text: String = "tidak dilaporkan"
	if phys > 0:
		phys_text = "%d MB" % int(phys / 1048576)
	var cap: int = FPS_CAP_OPTIONS[_fps_cap_index]
	var lines: PackedStringArray = PackedStringArray()
	var warm: String = "" if _warmup_left <= 0 else " (pemanasan %d)" % _warmup_left
	lines.append("FPS %d | frame rata2 %.1f p95 %.1f p99 %.1f maks %.1f ms | lambat>%dms: %.0f%% | batas %s%s" % [
		int(Engine.get_frames_per_second()), st["avg"], st["p95"], st["p99"], st["max"],
		int(JANK_MS), st["jank_pct"], "auto" if cap == 0 else str(cap), warm])
	lines.append("Skrip %.2f ms (p95 %.2f) | Gambar-CPU %.2f ms (p95 %.2f) | TIME_PROCESS %.2f ms | HUD %.2f ms/%ds" % [
		sc["avg"], sc["p95"], dr["avg"], dr["p95"],
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, _hud_ms, int(INFO_INTERVAL_SEC)])
	lines.append("Profil %s | Tile %dx%d | Arah %s | Objek +%d | Node %d | Draw call %d" % [
		RENDER_PROFILE_NAMES[_profile], int(_tile.x), int(_tile.y), IsoMath.direction_name(_facing),
		_stress_props.size(), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))])
	lines.append("Layar %dx%d (virtual %dx%d) | %d Hz | DPI %d | Area aman %dx%d" % [
		win.x, win.y, int(vis.x), int(vis.y), int(DisplayServer.screen_get_refresh_rate()),
		DisplayServer.screen_get_dpi(), int(_safe_size.x), int(_safe_size.y)])
	lines.append("RAM fisik (lapor OS) %s | Memori statis %.1f MB | %s %s" % [
		phys_text, float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0,
		OS.get_name(), OS.get_model_name()])
	lines.append("Render %s | GPU %s | API %s" % [
		RenderingServer.get_current_rendering_method(),
		RenderingServer.get_video_adapter_name(),
		RenderingServer.get_video_adapter_api_version()])
	_info.text = "\n".join(lines)
