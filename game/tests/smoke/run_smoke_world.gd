extends SceneTree
## Tes asap dunia Fase 2 (headless): memuat scene dunia lalu menguji gerak 8 arah, kecepatan
## diagonal, tabrakan, kamera, struktur Y-sort, dan joystick sentuh (event sintetis).
## Renderer headless tidak menggambar: urutan gambar Y-sort sebenarnya dan rasa kontrol
## hanya bisa dinilai di HP.
## Jalankan: godot --headless --path game -s res://tests/smoke/run_smoke_world.gd

const DT: float = 1.0 / 60.0

var _world: Node
var _stage: int = 0
var _frames: int = 0
var _fail: int = 0
var _count: int = 0


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/world/test_world.tscn")
	_world = packed.instantiate()
	root.add_child(_world)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	_run_all()
	print("Tes asap dunia: %d pemeriksaan, gagal: %d" % [_count, _fail])
	quit(1 if _fail > 0 else 0)
	return true


func _run_all() -> void:
	var player: Player = _world.get_player()
	var spawn: Vector2 = _world.get_spawn_grid()
	_check(player != null and _world.get_object_count() > 20, "dunia dimuat: pemain dan objek")
	_check(player.grid_pos.is_equal_approx(spawn), "pemain di titik mulai")
	_test_eight_directions(player, spawn)
	_test_collision(player)
	_test_camera(player)
	_test_ysort_structure(player)
	_test_joystick(player, spawn)
	_test_idle_walk(player, spawn)


func _walk(player: Player, input: Vector2, frames: int) -> void:
	player.move_input = input
	for _i in range(frames):
		player.advance(DT)
	player.move_input = Vector2.ZERO


func _test_eight_directions(player: Player, spawn: Vector2) -> void:
	var dists: Array[float] = []
	for i in range(8):
		player.teleport_grid(spawn)
		var start_screen: Vector2 = player.position
		var start_grid: Vector2 = player.grid_pos
		_walk(player, IsoMath.direction_vector(i), 24)
		var moved_screen: Vector2 = player.position - start_screen
		var name: String = IsoMath.direction_name(i)
		# Arah gerak di layar: sumbu y dilebarkan kembali (x2) sebelum mengukur sudut.
		var screen_dir := Vector2(moved_screen.x, moved_screen.y * 2.0)
		_check(IsoMath.direction_index(screen_dir) == i, "arah gerak layar = %s" % name)
		_check(player.facing == i, "hadap = %s" % name)
		dists.append(player.grid_pos.distance_to(start_grid))
	var lo: float = dists.min()
	var hi: float = dists.max()
	_check(lo > 1.0, "jarak tempuh wajar (min %.2f)" % lo)
	_check((hi - lo) / hi < 0.01, "diagonal konsisten: jarak %.3f..%.3f" % [lo, hi])


func _test_collision(player: Player) -> void:
	var col: GridCollision = _world.get_collision()
	var found: bool = false
	for cell: Vector2i in col.blocked_cells():
		var west := Vector2i(cell.x - 1, cell.y)
		if not col.is_cell_blocked(west) and not col.is_cell_blocked(Vector2i(cell.x - 2, cell.y)):
			found = true
			player.teleport_grid(Vector2(cell.x - 1 + 0.5, cell.y + 0.5))
			_walk(player, IsoMath.direction_vector(7), 90)  # se = grid +x
			_check(player.grid_pos.x < float(cell.x) - col.radius + 0.001, "tertahan objek di sel %s (x=%.3f)" % [cell, player.grid_pos.x])
			_check(col.is_free(player.grid_pos), "posisi akhir bebas")
			break
	_check(found, "ada sel terblokir untuk diuji")
	# Batas peta: jalan jauh ke arah n (grid -x -y) dari tengah, lalu periksa tetap di dalam peta.
	player.teleport_grid(_world.get_spawn_grid())
	_walk(player, IsoMath.direction_vector(4), 600)
	_check(col.is_free(player.grid_pos), "tetap di dalam batas setelah jalan jauh")
	_check(player.grid_pos.x >= 0.0 and player.grid_pos.y >= 0.0, "tidak keluar peta")
	# Air tidak bisa dilewati: kolam di kanan-atas.
	player.teleport_grid(Vector2(15.5, 5.5))
	_walk(player, IsoMath.direction_vector(7), 120)
	_check(player.grid_pos.x < 17.0, "air menghalangi (x=%.2f)" % player.grid_pos.x)


func _test_camera(player: Player) -> void:
	var cam: FollowCamera = _world.get_camera()
	player.teleport_grid(_world.get_spawn_grid())
	cam.snap_to_target()
	var start: Vector2 = cam.global_position
	_walk(player, IsoMath.direction_vector(6), 60)  # e
	for _i in range(180):
		cam.step(DT)
	var want: Vector2 = cam.desired_center()
	_check(cam.global_position.distance_to(want) < 1.0, "kamera menyusul target (selisih %.2f)" % cam.global_position.distance_to(want))
	_check(cam.global_position.distance_to(start) > 20.0, "kamera ikut bergerak")
	var view: Vector2 = cam.view_size()
	var b: Rect2 = cam.bounds
	var c: Vector2 = cam.global_position
	# Bila peta lebih kecil dari layar pada satu sumbu, kamera dipusatkan; selain itu di dalam batas.
	if b.size.x <= view.x:
		_check(is_equal_approx(c.x, b.get_center().x), "peta lebih sempit dari layar: dipusatkan (x)")
	else:
		_check(c.x - view.x * 0.5 >= b.position.x - 0.01 and c.x + view.x * 0.5 <= b.end.x + 0.01, "kamera di dalam batas peta (x), layar %s" % view)
	if b.size.y <= view.y:
		_check(is_equal_approx(c.y, b.get_center().y), "peta lebih pendek dari layar: dipusatkan (y), layar %s" % view)
	else:
		_check(c.y - view.y * 0.5 >= b.position.y - 0.01 and c.y + view.y * 0.5 <= b.end.y + 0.01, "kamera di dalam batas peta (y), layar %s" % view)


func _test_ysort_structure(player: Player) -> void:
	var actors: Node2D = _world.get_actors()
	_check(actors.y_sort_enabled, "kelompok aktor memakai Y-sort")
	_check(player.get_parent() == actors, "pemain dalam kelompok Y-sort")
	var all_in := true
	for child in actors.get_children():
		if child.y_sort_enabled and child != actors:
			all_in = false
	_check(all_in, "tidak ada Y-sort bersarang yang mengacaukan urutan")
	player.teleport_grid(Vector2(10.5, 10.5))
	var below: Node2D = null
	for child in actors.get_children():
		if child != player and child.position.y > player.position.y:
			below = child
			break
	_check(below != null, "ada objek di depan (lebih bawah) pemain")
	_check(player.position.y == IsoMath.grid_to_screen(player.grid_pos, player.tile).y, "posisi Y-sort pemain = posisi kaki")


func _test_joystick(player: Player, spawn: Vector2) -> void:
	var joy: TouchJoystick = _world.get_joystick()
	player.teleport_grid(spawn)
	player.move_input = Vector2.ZERO
	var zone_center: Vector2 = joy.get_global_transform_with_canvas() * (joy.size * 0.5)
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = true
	t.position = zone_center
	joy._input(t)
	_check(player.move_input == Vector2.ZERO, "sentuh tanpa geser = diam (di zona mati)")
	var d := InputEventScreenDrag.new()
	d.index = 0
	d.position = zone_center + Vector2(joy.radius, 0.0)
	joy._input(d)
	_check(player.move_input.x > 0.95 and absf(player.move_input.y) < 0.05, "geser kanan -> masukan kanan")
	_check(IsoMath.direction_index(player.move_input) == 6, "masukan kanan = arah e")
	# Jari kedua di tempat lain tidak mengganggu
	var t2 := InputEventScreenTouch.new()
	t2.index = 1
	t2.pressed = true
	t2.position = zone_center + Vector2(10, 10)
	joy._input(t2)
	_check(player.move_input.x > 0.95, "jari kedua tidak mengganggu joystick")
	# Tarik jauh melewati radius: pangkal mengikuti, masukan tetap panjang 1
	d.position = zone_center + Vector2(joy.radius * 3.0, 0.0)
	joy._input(d)
	_check(is_equal_approx(player.move_input.length(), 1.0), "melewati radius dibatasi panjang 1")
	var d2 := InputEventScreenDrag.new()
	d2.index = 0
	d2.position = d.position + Vector2(-joy.radius, 0.0)
	joy._input(d2)
	_check(absf(player.move_input.length()) < 0.05, "pangkal mengikuti jari: tarik balik = netral")
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.pressed = false
	up.position = d.position
	joy._input(up)
	_check(player.move_input == Vector2.ZERO, "lepas -> masukan nol")
	_check(joy.floating, "joystick mode melayang")


func _test_idle_walk(player: Player, spawn: Vector2) -> void:
	player.teleport_grid(spawn)
	for _i in range(5):
		player.advance(DT)
	_check(player.animator.animation_name().begins_with("idle"), "diam -> idle")
	_walk(player, IsoMath.direction_vector(2), 10)
	player.move_input = IsoMath.direction_vector(2)
	player.advance(DT)
	_check(player.animator.animation_name() == "walk_w", "bergerak -> walk_w")
	player.move_input = Vector2.ZERO
	player.advance(DT)
	_check(player.animator.animation_name() == "idle_w", "berhenti -> idle_w")


func _check(cond: bool, name: String) -> void:
	_count += 1
	if cond:
		print("  OK   ", name)
	else:
		_fail += 1
		printerr("  GAGAL ", name)
