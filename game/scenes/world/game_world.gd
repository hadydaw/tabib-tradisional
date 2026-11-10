extends Node2D
## Fase 3: dunia permainan. Memuat lokasi (desa, interior klinik) dari LocationData,
## menempatkan pemain berkarakter kustom, kamera, kontrol sentuh, titik interaksi, dan
## perpindahan lokasi lewat keset pintu. Semua visual placeholder.
## Memakai pergerakan, tabrakan, kamera, dan joystick Fase 2 tanpa perubahan perilaku.

signal interaction_requested(interactable: Interactable)
signal location_changed(location_id: String)

const TILE: Vector2 = Vector2(64, 32)  # standar kerja sementara (T-14), bukan P-01
const CAMERA_ZOOM: float = 1.5
const WALK_SPEED: float = 3.5
const PLAYER_RADIUS: float = 0.25
const JOY_RADIUS: float = 90.0
const CAMERA_TOP_MARGIN: float = 140.0
const FADE_SEC: float = 0.15

var _loc: LocationData
var _loc_root: Node2D
var _ground_view: IsoGroundMapView
var _actors: Node2D
var _overlay: DebugOverlay
var _map: GroundMap
var _collision: GridCollision
var _player: Player
var _player_ready: bool = false
var _camera: FollowCamera
var _appearance: CharacterAppearance
var _near: Interactable

var _joystick: TouchJoystick
var _btn_debug: TouchActionButton
var _btn_interact: TouchActionButton
var _outfit_buttons: Array[TouchActionButton] = []
var _info: Label
var _toast: Label
var _interact_label: Label
var _fade: ColorRect
var _toast_left: float = 0.0
var _info_timer: float = 0.0
var _debug_on: bool = false
var _transitioning: bool = false
var _kb_active: bool = false

const OUTFIT_BUTTONS: PackedStringArray = ["Kulit", "Rambut", "Warna rambut", "Baju", "Celana", "Topi"]


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#161f23"))
	_appearance = CharacterAppearance.new()
	_player = Player.new()
	_player.walk_speed = WALK_SPEED
	_camera = FollowCamera.new()
	_camera.zoom = Vector2(CAMERA_ZOOM, CAMERA_ZOOM)
	_camera.target = _player
	add_child(_camera)
	_build_hud()
	load_location(LocationRegistry.START_LOCATION, LocationRegistry.START_SPAWN)
	get_viewport().size_changed.connect(_layout_hud)
	_layout_hud()
	_set_debug(false)


func _process(delta: float) -> void:
	poll_input()
	update_interaction()
	if Input.is_action_just_pressed("ui_accept"):
		press_interact()
	try_transition(false)
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.modulate.a = clampf(_toast_left / 0.5, 0.0, 1.0)
	_info_timer -= delta
	if _debug_on and _info_timer <= 0.0:
		_info_timer = 0.5
		_refresh_info()


# --- Lokasi ------------------------------------------------------------------

## Muat lokasi `id` dan taruh pemain di titik mulai `spawn_name`. False bila tidak dikenal.
func load_location(id: String, spawn_name: String) -> bool:
	var data: LocationData = LocationRegistry.get_location(id)
	if data == null or not data.spawns.has(spawn_name):
		push_error("Lokasi/titik mulai tidak dikenal: %s / %s" % [id, spawn_name])
		return false
	var spawn: Vector2 = data.spawns[spawn_name]
	if _player.get_parent() != null:
		_player.get_parent().remove_child(_player)
	if _loc_root != null:
		remove_child(_loc_root)
		_loc_root.queue_free()
	_loc = data
	_map = data.ground_map()
	_collision = data.build_collision(PLAYER_RADIUS)

	_loc_root = Node2D.new()
	add_child(_loc_root)

	_ground_view = IsoGroundMapView.new()
	_ground_view.map = _map
	_ground_view.tile = TILE
	_ground_view.z_index = WorldLayers.Z_GROUND
	_loc_root.add_child(_ground_view)

	# Semua yang berdiri/bergerak berbagi satu kelompok Y-sort (urut berdasarkan posisi kaki).
	_actors = Node2D.new()
	_actors.y_sort_enabled = true
	_actors.z_index = WorldLayers.Z_ACTORS
	_loc_root.add_child(_actors)
	for o in data.objects:
		var cell: Vector2i = o["cell"]
		var prop := IsoStaticMesh.new()
		prop.mesh = PropCatalog.mesh_for(o["kind"], TILE)
		prop.position = IsoMath.grid_to_screen(Vector2(cell.x + 0.5, cell.y + 0.5), TILE)
		_actors.add_child(prop)
	for bd in data.buildings:
		for node in StructureBuilder.spawn_nodes(TILE, bd["rect"], bd["style"]):
			_actors.add_child(node)

	_overlay = DebugOverlay.new()
	_overlay.z_index = WorldLayers.Z_OVERLAY
	_overlay.collision = _collision
	_overlay.map = _map
	_overlay.tile = TILE
	_overlay.visible = _debug_on
	_loc_root.add_child(_overlay)

	if not _player_ready:
		_player.setup(TILE, _collision, spawn, _appearance)
		_player_ready = true
	else:
		_player.collision = _collision
	_player.move_input = Vector2.ZERO
	_player.teleport_grid(spawn)
	_actors.add_child(_player)
	_overlay.player = _player

	_camera.bounds = IsoMapMeshes.screen_bounds(_map, TILE, CAMERA_TOP_MARGIN)
	_camera.snap_to_target()
	_near = null
	if _btn_interact != null:
		update_interaction()
		_show_toast(data.display_name)
	location_changed.emit(id)
	return true


## Cek keset perpindahan di bawah pemain. `instant` = tanpa pudar (untuk tes).
func try_transition(instant: bool = false) -> bool:
	if _transitioning:
		return false
	var cell := Vector2i(floori(_player.grid_pos.x), floori(_player.grid_pos.y))
	var t: Dictionary = _loc.transition_at(cell)
	if t.is_empty():
		return false
	var target: String = t["target"]
	var spawn: String = t["spawn"]
	if instant:
		load_location(target, spawn)
		return true
	_transitioning = true
	_player.move_input = Vector2.ZERO
	var tw: Tween = create_tween()
	tw.tween_property(_fade, "color:a", 1.0, FADE_SEC)
	tw.tween_callback(func() -> void: load_location(target, spawn))
	tw.tween_property(_fade, "color:a", 0.0, FADE_SEC)
	tw.tween_callback(func() -> void: _transitioning = false)
	return true


# --- Masukan dan interaksi ---------------------------------------------------

## Gabungkan keyboard (uji di komputer) dan joystick sentuh menjadi masukan pemain.
func poll_input() -> void:
	var k := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if _transitioning:
		_player.move_input = Vector2.ZERO
	elif k.length() > 0.0:
		_player.move_input = k.normalized()
		_kb_active = true
	elif _kb_active:
		_player.move_input = Vector2.ZERO
		_kb_active = false
	else:
		_player.move_input = _joystick.get_value()


func update_interaction() -> void:
	var facing_grid: Vector2 = IsoMath.input_to_grid_velocity(IsoMath.direction_vector(_player.facing), 1.0)
	_near = InteractionSystem.find_best(_player.grid_pos, facing_grid, _loc.interactables)
	_btn_interact.visible = _near != null
	_interact_label.visible = _near != null
	if _near != null:
		_interact_label.text = _near.prompt


## Tekan tombol interaksi. Hanya memancarkan sinyal dan pesan; sistem di baliknya belum ada.
func press_interact() -> bool:
	if _near == null:
		return false
	interaction_requested.emit(_near)
	_show_toast("[Placeholder] %s: sistemnya belum dibuat" % _near.prompt)
	return true


# --- HUD ---------------------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = WorldLayers.HUD_LAYER
	add_child(layer)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 17)
	_info.add_theme_color_override("font_outline_color", Color.BLACK)
	_info.add_theme_constant_override("outline_size", 6)
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_info)

	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 28)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	layer.add_child(_toast)

	_joystick = TouchJoystick.new()
	_joystick.floating = true
	_joystick.radius = JOY_RADIUS
	layer.add_child(_joystick)

	_btn_interact = TouchActionButton.new()
	_btn_interact.text = "Interaksi"
	_btn_interact.pressed.connect(press_interact)
	_btn_interact.visible = false
	layer.add_child(_btn_interact)

	_interact_label = Label.new()
	_interact_label.add_theme_font_size_override("font_size", 22)
	_interact_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_interact_label.add_theme_constant_override("outline_size", 6)
	_interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_interact_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interact_label.visible = false
	layer.add_child(_interact_label)

	_btn_debug = TouchActionButton.new()
	_btn_debug.font_size = 22
	_btn_debug.pressed.connect(func() -> void: _set_debug(not _debug_on))
	layer.add_child(_btn_debug)

	for i in range(OUTFIT_BUTTONS.size()):
		var btn := TouchActionButton.new()
		btn.font_size = 20
		btn.text = OUTFIT_BUTTONS[i]
		btn.pressed.connect(_on_outfit_button.bind(i))
		layer.add_child(btn)
		_outfit_buttons.append(btn)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = WorldLayers.HUD_LAYER + 10
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(_fade)


func _layout_hud() -> void:
	var vis: Vector2 = get_viewport().get_visible_rect().size
	var safe: Rect2 = SafeArea.rect(vis)
	_info.position = safe.position + Vector2(16.0, 8.0)
	_btn_debug.size = Vector2(190.0, 52.0)
	_btn_debug.position = Vector2(safe.end.x - 190.0 - 16.0, safe.position.y + 8.0)
	var by: float = safe.position.y + 68.0
	for btn in _outfit_buttons:
		btn.size = Vector2(190.0, 44.0)
		btn.position = Vector2(safe.end.x - 190.0 - 16.0, by)
		by += 50.0
	_btn_interact.size = Vector2(150.0, 150.0)
	_btn_interact.position = Vector2(safe.end.x - 150.0 - 40.0, safe.end.y - 150.0 - 40.0)
	_interact_label.size = Vector2(360.0, 34.0)
	_interact_label.position = Vector2(safe.end.x - 360.0 - 40.0, _btn_interact.position.y - 40.0)
	_toast.size = Vector2(800.0, 44.0)
	_toast.position = Vector2(vis.x * 0.5 - 400.0, safe.position.y + 70.0)
	# Area sentuh joystick: separuh kiri layar, bagian bawah.
	var zone_top: float = safe.position.y + safe.size.y * 0.30
	_joystick.position = Vector2(safe.position.x, zone_top)
	_joystick.size = Vector2(safe.size.x * 0.5, safe.end.y - zone_top)
	_joystick.rest_center = Vector2(JOY_RADIUS + 40.0, _joystick.size.y - JOY_RADIUS - 40.0)
	_joystick.queue_redraw()


func _set_debug(on: bool) -> void:
	_debug_on = on
	_overlay.visible = on
	_info.visible = on
	for btn in _outfit_buttons:
		btn.visible = on
	_btn_debug.text = "Debug: %s" % ("nyala" if on else "mati")
	if on:
		_refresh_info()


func _on_outfit_button(index: int) -> void:
	match index:
		0: _appearance.set_skin(_appearance.skin_index + 1)
		1: _appearance.set_hair_style(_appearance.hair_style + 1)
		2: _appearance.set_hair_color(_appearance.hair_color_index + 1)
		3: _appearance.cycle_outfit(OutfitItem.Slot.TOP)
		4: _appearance.cycle_outfit(OutfitItem.Slot.BOTTOM)
		5: _appearance.cycle_outfit(OutfitItem.Slot.HEAD)


func _show_toast(message: String) -> void:
	_toast.text = message
	_toast_left = 2.0
	_toast.modulate.a = 1.0


func _refresh_info() -> void:
	var cell := Vector2i(floori(_player.grid_pos.x), floori(_player.grid_pos.y))
	var zone: String = _loc.zone_at(cell)
	var lines := PackedStringArray()
	lines.append("FPS %d | Draw call %d | Node %d" % [
		int(Engine.get_frames_per_second()),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	lines.append("%s%s | Sel %d,%d | Anim %s" % [
		_loc.display_name, (" / " + zone) if zone != "" else "", cell.x, cell.y, _player.animator.animation_name()])
	lines.append("Objek %d | Titik interaksi %d" % [_actors.get_child_count(), _loc.interactables.size()])
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


func get_ground_view() -> IsoGroundMapView:
	return _ground_view


func get_location() -> LocationData:
	return _loc


func get_appearance() -> CharacterAppearance:
	return _appearance


func get_near_interactable() -> Interactable:
	return _near
