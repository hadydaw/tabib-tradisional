extends SceneTree
## Tes asap Fase 3 (headless, bertahap satu langkah per frame): memuat scene dunia permainan,
## menguji gerak, tabrakan, Y-sort (struktur), perpindahan desa <-> klinik, titik interaksi,
## karakter kustom, kamera. Langkah rias menggambar karakter di banyak kombinasi agar galat
## pada kode gambar (SCRIPT ERROR) tertangkap. Renderer headless tidak menghasilkan gambar:
## tampilan sebenarnya dan rasa kontrol hanya bisa dinilai di HP.
## Jalankan: godot --headless --path game -s res://tests/smoke/run_smoke_game.gd

const DT: float = 1.0 / 60.0

var _world: Node
var _steps: Array[Callable] = []
var _step_index: int = 0
var _frames: int = 0
var _fail: int = 0
var _count: int = 0
var _signal_hits: Array = []
var _location_hits: Array = []


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/world/game_world.tscn")
	_world = packed.instantiate()
	root.add_child(_world)
	_world.interaction_requested.connect(func(it: Interactable) -> void: _signal_hits.append(it.id))
	_world.location_changed.connect(func(id: String) -> void: _location_hits.append(id))
	_steps = [_step_load, _step_directions, _step_collision, _step_ysort, _step_interaction_village,
		_step_enter_clinic, _step_clinic_interactions, _step_exit_clinic, _step_camera, _step_appearance_logic]
	for i in range(36):
		_steps.append(_step_look.bind(i))
	_steps.append(_step_final)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	if _step_index < _steps.size():
		_steps[_step_index].call()
		_step_index += 1
		return false
	print("Tes asap game: %d pemeriksaan, gagal: %d" % [_count, _fail])
	quit(1 if _fail > 0 else 0)
	return true


func _walk(player: Player, input: Vector2, frames: int) -> void:
	player.move_input = input
	for _i in range(frames):
		player.advance(DT)
	player.move_input = Vector2.ZERO


func _step_load() -> void:
	var player: Player = _world.get_player()
	var loc: LocationData = _world.get_location()
	_check(loc.id == "desa", "mulai di desa")
	_check(player.grid_pos.is_equal_approx(loc.spawns["awal"]), "pemain di titik mulai")
	_check(_location_hits.size() >= 1 and _location_hits[0] == "desa", "sinyal location_changed desa")
	var n: int = _world.get_actors().get_child_count()
	_check(n > 150 and n < 450, "jumlah node dunia desa wajar (%d)" % n)
	_check(player.appearance == _world.get_appearance(), "pemain memakai CharacterAppearance")
	_check(player.animator.animation_name() == "idle_s", "mulai idle_s")


func _step_directions() -> void:
	var player: Player = _world.get_player()
	var spawn: Vector2 = _world.get_location().spawns["awal"]
	var dists: Array[float] = []
	for i in range(8):
		player.teleport_grid(spawn)
		var start_screen: Vector2 = player.position
		var start_grid: Vector2 = player.grid_pos
		_walk(player, IsoMath.direction_vector(i), 24)
		var moved: Vector2 = player.position - start_screen
		_check(IsoMath.direction_index(Vector2(moved.x, moved.y * 2.0)) == i, "arah gerak layar = %s" % IsoMath.direction_name(i))
		dists.append(player.grid_pos.distance_to(start_grid))
	_check((dists.max() - dists.min()) / dists.max() < 0.01, "diagonal konsisten di desa (%.3f..%.3f)" % [dists.min(), dists.max()])


func _step_collision() -> void:
	var player: Player = _world.get_player()
	var col: GridCollision = _world.get_collision()
	var found: int = 0
	for cell: Vector2i in col.blocked_cells():
		var west := Vector2i(cell.x - 1, cell.y)
		if col.is_cell_blocked(west) or col.is_cell_blocked(Vector2i(cell.x - 2, cell.y)):
			continue
		player.teleport_grid(Vector2(cell.x - 1 + 0.5, cell.y + 0.5))
		_walk(player, IsoMath.direction_vector(7), 60)  # se = grid +x
		if player.grid_pos.x < float(cell.x) - col.radius + 0.001 and col.is_free(player.grid_pos):
			found += 1
		else:
			printerr("    menembus di ", cell, " x=", player.grid_pos.x)
		if found >= 40:
			break
	_check(found >= 40, "40 sel terblokir menahan pemain tanpa tembus (%d)" % found)
	# Dinding klinik
	var clinic_cell := Vector2i(22, 11)
	_check(col.is_cell_blocked(clinic_cell), "dinding klinik terblokir")
	player.teleport_grid(Vector2(22.5, 14.5))
	_walk(player, IsoMath.direction_vector(5), 20)  # ne = grid -y, menuju dinding
	_check(player.grid_pos.y > 12.0 - 0.001 or _world.get_location().transition_at(Vector2i(floori(player.grid_pos.x), floori(player.grid_pos.y))).size() > 0, "tidak bisa menembus dinding klinik")
	# Air kolam
	player.teleport_grid(Vector2(36.5, 5.5))
	_walk(player, IsoMath.direction_vector(7), 120)
	_check(player.grid_pos.x < 38.0, "air kolam menghalangi (x=%.2f)" % player.grid_pos.x)


func _step_ysort() -> void:
	var actors: Node2D = _world.get_actors()
	var player: Player = _world.get_player()
	_check(actors.y_sort_enabled, "kelompok aktor Y-sort")
	_check(player.get_parent() == actors, "pemain dalam kelompok Y-sort")
	_check(_world.get_ground_view().z_index < actors.z_index, "lantai di lapisan bawah aktor")
	var nested: bool = false
	var roofs: int = 0
	for c in actors.get_children():
		if c is Node2D and (c as Node2D).y_sort_enabled and c != actors:
			nested = true
		if c is Node2D and (c as Node2D).y_sort_origin > 0:
			roofs += 1
	_check(not nested, "tidak ada Y-sort bersarang")
	_check(roofs == _world.get_location().buildings.size(), "satu atap per bangunan (%d)" % roofs)
	player.teleport_grid(Vector2(23.5, 16.5))
	_check(player.position.y == IsoMath.grid_to_screen(player.grid_pos, player.tile).y, "titik urut pemain = kaki")


func _step_interaction_village() -> void:
	var player: Player = _world.get_player()
	player.teleport_grid(Vector2(20.5, 13.5))  # di bawah papan klinik (20,12)
	player.facing = 5  # ne = menghadap grid -y
	_world.update_interaction()
	var it: Interactable = _world.get_near_interactable()
	_check(it != null and it.id == "village_clinic_sign", "papan klinik dapat diinteraksi")
	_signal_hits.clear()
	_check(_world.press_interact(), "tombol interaksi bekerja")
	_check(_signal_hits.size() == 1 and _signal_hits[0] == "village_clinic_sign", "sinyal interaction_requested")
	player.teleport_grid(Vector2(23.5, 16.5))
	_world.update_interaction()
	_check(_world.get_near_interactable() == null and not _world.press_interact(), "jauh dari titik interaksi: tidak ada")
	player.teleport_grid(Vector2(26.5, 35.5))
	player.facing = 2  # w
	_world.update_interaction()
	var well: Interactable = _world.get_near_interactable()
	_check(well != null and well.id == "village_well", "sumur dapat diinteraksi")


func _step_enter_clinic() -> void:
	var player: Player = _world.get_player()
	player.teleport_grid(Vector2(23.0, 14.5))
	_check(not _world.try_transition(true), "bukan keset: tidak pindah")
	_walk(player, IsoMath.direction_vector(5), 30)  # ne = grid -y, menuju keset di y = 12
	var cell := Vector2i(floori(player.grid_pos.x), floori(player.grid_pos.y))
	_check(_world.get_location().transition_at(cell).size() > 0, "berjalan ke keset (sel %s)" % cell)
	_check(_world.try_transition(true), "keset memindahkan ke klinik")
	var loc: LocationData = _world.get_location()
	_check(loc.id == "klinik", "sekarang di klinik")
	_check(_location_hits.back() == "klinik", "sinyal location_changed klinik")
	_check(player.grid_pos.is_equal_approx(loc.spawns["dari_desa"]), "pemain di titik masuk klinik")
	_check(_world.get_collision().is_free(player.grid_pos), "titik masuk bebas")
	_check(not _world.try_transition(true), "tidak memicu ulang segera setelah masuk")
	_check(player.get_parent() == _world.get_actors() and _world.get_actors().y_sort_enabled, "pemain di Y-sort klinik")
	_check(loc.zone_at(Vector2i(floori(player.grid_pos.x), floori(player.grid_pos.y))) == "Area Penerimaan", "zona penerimaan")
	# Jalan dari pintu ke ruang pemeriksaan lewat celah sekat (dengan tabrakan nyata)
	_walk(player, IsoMath.direction_vector(4), 40)  # n = grid (-1,-1) dari (8,9.5)
	_check(_world.get_collision().is_free(player.grid_pos), "berjalan di klinik tetap bebas dari perabot")


func _step_clinic_interactions() -> void:
	var player: Player = _world.get_player()
	var loc: LocationData = _world.get_location()
	var col: GridCollision = _world.get_collision()
	for it in loc.interactables:
		var done: bool = false
		for step: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
			var n: Vector2i = it.cell + step
			var pos := Vector2(n.x + 0.5, n.y + 0.5)
			if not col.is_free(pos):
				continue
			player.teleport_grid(pos)
			# arah hadap grid ke titik interaksi -> indeks arah layar terdekat
			var g: Vector2 = Vector2(-step.x, -step.y)
			var screen_dir := Vector2(g.x - g.y, (g.x + g.y))
			player.facing = IsoMath.direction_index(Vector2(screen_dir.x, screen_dir.y * 0.5 if false else screen_dir.y))
			_world.update_interaction()
			if _world.get_near_interactable() != null and _world.get_near_interactable().id == it.id:
				done = true
				break
		_check(done, "klinik: titik '%s' dipilih saat didekati" % it.id)
	_signal_hits.clear()
	_world.press_interact()
	_check(_signal_hits.size() == 1, "klinik: interaksi memancarkan sinyal")


func _step_exit_clinic() -> void:
	var player: Player = _world.get_player()
	var loc: LocationData = _world.get_location()
	player.teleport_grid(Vector2(8.0, 9.5))
	_walk(player, IsoMath.direction_vector(1) if false else IsoMath.direction_vector(7), 0)
	player.teleport_grid(Vector2(7.5, 10.5))
	_walk(player, IsoMath.direction_vector(0), 12)  # s = grid (+1,+1) menuju keset keluar
	var cell := Vector2i(floori(player.grid_pos.x), floori(player.grid_pos.y))
	_check(loc.transition_at(cell).size() > 0, "keset keluar tercapai (sel %s)" % cell)
	_check(_world.try_transition(true), "keset keluar memindahkan ke desa")
	var village: LocationData = _world.get_location()
	_check(village.id == "desa", "kembali ke desa")
	_check(player.grid_pos.is_equal_approx(village.spawns["dari_klinik"]), "muncul di depan klinik")
	_check(not _world.try_transition(true), "tidak memicu ulang di desa")
	_check(_world.get_collision().is_free(player.grid_pos), "titik muncul bebas")


func _step_camera() -> void:
	var cam: FollowCamera = _world.get_camera()
	var player: Player = _world.get_player()
	for spawn_name in ["awal", "dari_klinik"]:
		player.teleport_grid(_world.get_location().spawns[spawn_name])
		cam.snap_to_target()
		_walk(player, IsoMath.direction_vector(6), 60)
		for _i in range(180):
			cam.step(DT)
		_check(cam.global_position.distance_to(cam.desired_center()) < 1.0, "kamera menyusul pemain (%s)" % spawn_name)
		var view: Vector2 = cam.view_size()
		var b: Rect2 = cam.bounds
		var c: Vector2 = cam.global_position
		var in_x: bool = (b.size.x <= view.x and is_equal_approx(c.x, b.get_center().x)) or (c.x - view.x * 0.5 >= b.position.x - 0.01 and c.x + view.x * 0.5 <= b.end.x + 0.01)
		var in_y: bool = (b.size.y <= view.y and is_equal_approx(c.y, b.get_center().y)) or (c.y - view.y * 0.5 >= b.position.y - 0.01 and c.y + view.y * 0.5 <= b.end.y + 0.01)
		_check(in_x and in_y, "kamera dalam batas peta (%s)" % spawn_name)


func _step_appearance_logic() -> void:
	var a: CharacterAppearance = _world.get_appearance()
	var hits: Array = [0]
	a.changed.connect(func() -> void: hits[0] += 1)
	a.cycle_outfit(OutfitItem.Slot.TOP)
	a.cycle_outfit(OutfitItem.Slot.HEAD)
	a.set_hair_style(a.hair_style + 1)
	_check(hits[0] == 3, "perubahan tampilan memicu sinyal (%d)" % hits[0])


## Menggambar karakter dengan kombinasi berbeda dan arah berbeda agar kode gambar teruji.
func _step_look(i: int) -> void:
	var a: CharacterAppearance = _world.get_appearance()
	var player: Player = _world.get_player()
	a.set_skin(i)
	a.set_hair_style(i)
	a.set_hair_color(i * 2)
	a.cycle_outfit(OutfitItem.Slot.TOP)
	a.cycle_outfit(OutfitItem.Slot.BOTTOM)
	a.cycle_outfit(OutfitItem.Slot.HEAD)
	player.facing = i % 8
	player.animator.update(0.05, i % 2 == 0, i % 8)
	player._view.apply_animation(player.animator.state, float(i % 10) / 10.0, i % 8)


func _step_final() -> void:
	var player: Player = _world.get_player()
	_check(_location_hits.size() >= 3, "lokasi berpindah desa -> klinik -> desa (%s)" % str(_location_hits))
	_check(player.get_parent() != null and player.get_parent() == _world.get_actors(), "pemain masih dalam kelompok Y-sort aktif")


func _check(cond: bool, name: String) -> void:
	_count += 1
	if cond:
		print("  OK   ", name)
	else:
		_fail += 1
		printerr("  GAGAL ", name)
