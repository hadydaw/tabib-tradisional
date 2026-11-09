extends Node2D
## Fase 2: dunia isometrik uji dengan pemain, tabrakan, kamera, dan kontrol sentuh.
## Semua visual placeholder. Bukan desain dunia final.
## Ukuran tile 64x32 = standar kerja sementara (T-14), bukan keputusan P-01.

const TILE: Vector2 = Vector2(64, 32)
const CAMERA_ZOOM: float = 1.5
const WALK_SPEED: float = 3.5
const PLAYER_RADIUS: float = 0.25
const JOY_RADIUS: float = 90.0

var _map: GroundMap
var _collision: GridCollision
var _ground_view: IsoGroundMapView
var _actors: Node2D
var _objects: Array[Node2D] = []
var _player: Player
var _camera: FollowCamera
var _overlay: DebugOverlay
var _spawn_cell: Vector2i = Vector2i(1, 1)

var _joystick: TouchJoystick
var _btn_debug: TouchActionButton
var _info: Label
var _debug_on: bool = false
var _info_timer: float = 0.0
var _kb_active: bool = false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#1d2a2f"))
	_build_world()
	_build_hud()
	get_viewport().size_changed.connect(_layout_hud)
	_layout_hud()
	_set_debug(false)


func _process(delta: float) -> void:
	# Keyboard hanya untuk uji di komputer; di Android yang dipakai joystick.
	var k := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if k.length() > 0.0:
		_player.move_input = k.normalized()
		_kb_active = true
	elif _kb_active:
		_player.move_input = Vector2.ZERO
		_kb_active = false
	_info_timer -= delta
	if _debug_on and _info_timer <= 0.0:
		_info_timer = 0.5
		_refresh_info()


# --- Dunia -------------------------------------------------------------------

func _build_world() -> void:
	_map = GroundMap.from_rows(WorldLayout.GROUND_ROWS)
	_collision = GridCollision.new(_map.width, _map.height, PLAYER_RADIUS)
	for y in range(_map.height):
		for x in range(_map.width):
			if not _map.is_walkable(Vector2i(x, y)):
				_collision.block_cell(Vector2i(x, y))

	_ground_view = IsoGroundMapView.new()
	_ground_view.map = _map
	_ground_view.tile = TILE
	add_child(_ground_view)

	_overlay = DebugOverlay.new()
	_overlay.z_index = 5
	add_child(_overlay)

	# Objek dan pemain dalam satu kelompok Y-sort (urut berdasarkan posisi kaki).
	_actors = Node2D.new()
	_actors.y_sort_enabled = true
	add_child(_actors)

	var parsed: Dictionary = WorldObjectKinds.parse(WorldLayout.OBJECT_ROWS)
	_spawn_cell = parsed["spawn"]
	for entry: Dictionary in parsed["objects"]:
		var cell: Vector2i = entry["cell"]
		var def: Dictionary = WorldObjectKinds.DEFS[entry["char"]]
		var prop := IsoMeshProp.new()
		prop.setup(TILE, TILE.y * float(def["height_factor"]), float(def["footprint"]), def["color"])
		prop.position = IsoMath.grid_to_screen(Vector2(cell.x + 0.5, cell.y + 0.5), TILE)
		_actors.add_child(prop)
		_objects.append(prop)
		_collision.block_cell(cell)

	_player = Player.new()
	_player.walk_speed = WALK_SPEED
	_actors.add_child(_player)
	_player.setup(TILE, _collision, Vector2(_spawn_cell.x + 0.5, _spawn_cell.y + 0.5))

	_overlay.collision = _collision
	_overlay.player = _player
	_overlay.map = _map
	_overlay.tile = TILE

	_camera = FollowCamera.new()
	_camera.zoom = Vector2(CAMERA_ZOOM, CAMERA_ZOOM)
	_camera.target = _player
	_camera.bounds = IsoMapMeshes.screen_bounds(_map, TILE)
	add_child(_camera)
	_camera.snap_to_target()


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

	_joystick = TouchJoystick.new()
	_joystick.floating = true
	_joystick.radius = JOY_RADIUS
	_joystick.vector_changed.connect(func(v: Vector2) -> void: _player.move_input = v)
	layer.add_child(_joystick)

	_btn_debug = TouchActionButton.new()
	_btn_debug.font_size = 22
	_btn_debug.pressed.connect(func() -> void: _set_debug(not _debug_on))
	layer.add_child(_btn_debug)


func _layout_hud() -> void:
	var vis: Vector2 = get_viewport().get_visible_rect().size
	var safe: Rect2 = SafeArea.rect(vis)
	_info.position = safe.position + Vector2(16.0, 8.0)
	_btn_debug.size = Vector2(190.0, 52.0)
	_btn_debug.position = Vector2(safe.end.x - 190.0 - 16.0, safe.position.y + 8.0)
	# Area sentuh joystick: separuh kiri layar, bagian bawah (di luar tombol atas).
	var zone_top: float = safe.position.y + safe.size.y * 0.30
	_joystick.position = Vector2(safe.position.x, zone_top)
	_joystick.size = Vector2(safe.size.x * 0.5, safe.end.y - zone_top)
	_joystick.rest_center = Vector2(JOY_RADIUS + 40.0, _joystick.size.y - JOY_RADIUS - 40.0)
	_joystick.queue_redraw()


func _set_debug(on: bool) -> void:
	_debug_on = on
	_overlay.visible = on
	_info.visible = on
	_btn_debug.text = "Debug: %s" % ("nyala" if on else "mati")
	if on:
		_refresh_info()


func _refresh_info() -> void:
	var lines := PackedStringArray()
	lines.append("FPS %d | Draw call %d | Node %d" % [
		int(Engine.get_frames_per_second()),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	lines.append("Grid %.2f, %.2f | Sel %d,%d | Anim %s" % [
		_player.grid_pos.x, _player.grid_pos.y,
		floori(_player.grid_pos.x), floori(_player.grid_pos.y), _player.animator.animation_name()])
	lines.append("Joystick %.2f, %.2f | Kamera %.0f, %.0f" % [
		_player.move_input.x, _player.move_input.y, _camera.global_position.x, _camera.global_position.y])
	_info.text = "\n".join(lines)


# --- Hook publik untuk tes ---------------------------------------------------

func get_player() -> Player:
	return _player


func get_camera() -> FollowCamera:
	return _camera


func get_collision() -> GridCollision:
	return _collision


func get_joystick() -> TouchJoystick:
	return _joystick


func get_actors() -> Node2D:
	return _actors


func get_object_count() -> int:
	return _objects.size()


func get_spawn_grid() -> Vector2:
	return Vector2(_spawn_cell.x + 0.5, _spawn_cell.y + 0.5)
