extends SceneTree
## Runner tes unit sederhana (tanpa plugin). Jalankan:
##   godot --headless --path game -s res://tests/unit/run_tests.gd
## Keluar dengan kode 0 jika semua lolos, 1 jika ada yang gagal.

const IsoMathScript := preload("res://core/systems/iso_math.gd")
const PerfStatsScript := preload("res://core/systems/perf_stats.gd")
const IsoMeshesScript := preload("res://features/world/iso_meshes.gd")
const GridCollisionScript := preload("res://core/systems/grid_collision.gd")
const GroundMapScript := preload("res://features/world/ground_map.gd")
const WorldObjectKindsScript := preload("res://features/world/world_object_kinds.gd")
const WorldLayoutScript := preload("res://features/world/world_layout.gd")
const PlayerAnimatorScript := preload("res://features/player/player_animator.gd")
const FollowCameraScript := preload("res://features/world/follow_camera.gd")

var _count: int = 0
var _fail: int = 0


func _init() -> void:
	_test_grid_roundtrip()
	_test_grid_known_points()
	_test_direction_index()
	_test_direction_roundtrip()
	_test_perf_stats()
	_test_meshes()
	_test_movement_math()
	_test_collision()
	_test_ground_map()
	_test_animator()
	_test_camera_clamp()
	print("Tes dijalankan: %d, gagal: %d" % [_count, _fail])
	quit(1 if _fail > 0 else 0)


func _check(condition: bool, name: String) -> void:
	_count += 1
	if condition:
		print("  OK   ", name)
	else:
		_fail += 1
		printerr("  GAGAL ", name)


func _test_grid_roundtrip() -> void:
	for tile: Vector2 in [Vector2(64, 32), Vector2(128, 64)]:
		for g: Vector2 in [Vector2(0, 0), Vector2(3, 7), Vector2(15.5, 2.25), Vector2(-4, 9)]:
			var back: Vector2 = IsoMathScript.screen_to_grid(IsoMathScript.grid_to_screen(g, tile), tile)
			_check(back.is_equal_approx(g), "roundtrip grid %s tile %s" % [g, tile])


func _test_grid_known_points() -> void:
	var tile := Vector2(64, 32)
	_check(IsoMathScript.grid_to_screen(Vector2(1, 0), tile).is_equal_approx(Vector2(32, 16)), "gx+1 -> kanan-bawah")
	_check(IsoMathScript.grid_to_screen(Vector2(0, 1), tile).is_equal_approx(Vector2(-32, 16)), "gy+1 -> kiri-bawah")
	_check(IsoMathScript.grid_to_screen(Vector2(1, 1), tile).is_equal_approx(Vector2(0, 32)), "diagonal -> lurus ke bawah")


func _test_direction_index() -> void:
	var cases := {
		"s": Vector2(0, 1), "sw": Vector2(-1, 1), "w": Vector2(-1, 0), "nw": Vector2(-1, -1),
		"n": Vector2(0, -1), "ne": Vector2(1, -1), "e": Vector2(1, 0), "se": Vector2(1, 1),
	}
	for expected: String in cases:
		var idx: int = IsoMathScript.direction_index(cases[expected])
		_check(IsoMathScript.direction_name(idx) == expected, "arah %s" % expected)
	_check(IsoMathScript.direction_index(Vector2.ZERO) == 0, "vektor nol -> indeks 0")


func _test_direction_roundtrip() -> void:
	for i in range(8):
		var v: Vector2 = IsoMathScript.direction_vector(i)
		_check(is_equal_approx(v.length(), 1.0), "panjang vektor arah %d = 1" % i)
		_check(IsoMathScript.direction_index(v) == i, "roundtrip indeks arah %d" % i)


func _test_perf_stats() -> void:
	var empty: Dictionary = PerfStatsScript.summarize(PackedFloat32Array())
	_check(empty["n"] == 0 and empty["avg"] == 0.0, "statistik kosong aman")
	var vals := PackedFloat32Array()
	for i in range(1, 101):
		vals.append(float(i))
	var st: Dictionary = PerfStatsScript.summarize(vals, 90.0)
	_check(is_equal_approx(st["avg"], 50.5), "rata-rata 1..100")
	_check(is_equal_approx(st["p95"], 95.0), "p95 nearest-rank")
	_check(is_equal_approx(st["p99"], 99.0), "p99 nearest-rank")
	_check(is_equal_approx(st["max"], 100.0), "maks")
	_check(is_equal_approx(st["jank_pct"], 10.0), "jank 10 persen (>90 ms)")
	var one: Dictionary = PerfStatsScript.summarize(PackedFloat32Array([7.0]))
	_check(is_equal_approx(one["p99"], 7.0), "satu sampel")


func _test_meshes() -> void:
	var tile := Vector2(64, 32)
	var fill: ArrayMesh = IsoMeshesScript.ground_fill_mesh(16, tile)
	var fill_arr: Array = fill.surface_get_arrays(0)
	_check((fill_arr[Mesh.ARRAY_VERTEX] as PackedVector2Array).size() == 16 * 16 * 6, "mesh lantai: 6 vertex per tile")
	_check((fill_arr[Mesh.ARRAY_COLOR] as PackedColorArray).size() == 16 * 16 * 6, "mesh lantai: warna per vertex")
	var lines: ArrayMesh = IsoMeshesScript.ground_line_mesh(16, tile)
	_check((lines.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector2Array).size() == 16 * 16 * 8, "mesh garis: 8 vertex per tile")
	for t: Vector2 in [Vector2(64, 32), Vector2(128, 64)]:
		var prop: ArrayMesh = IsoMeshesScript.prop_mesh(t, t.y * 2.0)
		_check((prop.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector2Array).size() == 24, "mesh balok: 24 vertex (%s)" % t)
		var faces: Dictionary = IsoMeshesScript.prop_faces(t, t.y * 2.0, 0.8, Color.WHITE)
		_check((faces["polys"] as Array).size() == 4 and (faces["colors"] as PackedColorArray).size() == 4, "balok: 4 bidang (%s)" % t)
	# Bidang balok harus tetap di sekitar kaki: tapak simetris terhadap titik asal.
	var f64: Dictionary = IsoMeshesScript.prop_faces(Vector2(64, 32), 48.0, 0.8, Color.WHITE)
	var shadow: PackedVector2Array = (f64["polys"] as Array)[0]
	_check(is_equal_approx(shadow[0].x, -shadow[2].x) and is_equal_approx(shadow[1].y, -shadow[3].y), "tapak simetris di titik kaki")


func _test_movement_math() -> void:
	# Besar kecepatan sama di semua 8 arah (diagonal konsisten).
	for i in range(8):
		var dir: Vector2 = IsoMathScript.direction_vector(i)
		var vel: Vector2 = IsoMathScript.input_to_grid_velocity(dir, 3.5)
		_check(is_equal_approx(vel.length(), 3.5), "kecepatan arah %s = 3.5" % IsoMathScript.direction_name(i))
	# Arah layar -> arah grid yang benar
	var e: Vector2 = IsoMathScript.input_to_grid_velocity(Vector2(1, 0), 1.0)
	_check(is_equal_approx(e.x, e.length() * 0.7071068) and e.y < 0.0, "kanan layar = grid +x -y")
	var dn: Vector2 = IsoMathScript.input_to_grid_velocity(Vector2(0, 1), 1.0)
	_check(dn.x > 0.0 and dn.y > 0.0 and is_equal_approx(dn.x, dn.y), "bawah layar = grid +x +y")
	# Kunci ke 8 arah
	var snapped: Vector2 = IsoMathScript.snap_input_8(Vector2(1.0, 0.3))
	_check(IsoMathScript.direction_index(snapped) == IsoMathScript.direction_index(Vector2(1, 0)), "masukan hampir ke kanan -> e")
	_check(is_equal_approx(IsoMathScript.snap_input_8(Vector2(0.5, 0.0)).length(), 0.5), "snap mempertahankan panjang")
	_check(is_equal_approx(IsoMathScript.snap_input_8(Vector2(5.0, 0.0)).length(), 1.0), "snap membatasi panjang 1")
	_check(IsoMathScript.snap_input_8(Vector2.ZERO) == Vector2.ZERO, "snap nol")
	_check(IsoMathScript.speed_factor(0.1) == 0.0, "zona mati -> 0")
	_check(is_equal_approx(IsoMathScript.speed_factor(0.15), 0.4), "batas zona mati -> 0.4")
	_check(is_equal_approx(IsoMathScript.speed_factor(0.6), 1.0) and is_equal_approx(IsoMathScript.speed_factor(1.0), 1.0), "penuh dari 0.6")


func _test_collision() -> void:
	var c = GridCollisionScript.new(10, 10, 0.25)
	c.block_cell(Vector2i(5, 5))
	_check(c.is_free(Vector2(2.5, 2.5)), "area kosong bebas")
	_check(not c.is_free(Vector2(5.5, 5.5)), "sel terblokir")
	_check(not c.is_free(Vector2(4.9, 5.5)), "tepi kotak menyentuh sel terblokir")
	_check(c.is_free(Vector2(4.7, 5.5)), "tepat di luar jarak radius")
	_check(not c.is_free(Vector2(0.1, 5.0)), "batas kiri peta")
	_check(not c.is_free(Vector2(9.9, 5.0)), "batas kanan peta")
	# Berhenti di dinding
	var p: Vector2 = c.move(Vector2(3.5, 5.5), Vector2(3.0, 0.0))
	_check(p.x <= 4.75 + 0.0001 and p.x > 4.5, "berhenti di depan sel terblokir (x=%.3f)" % p.x)
	_check(is_equal_approx(p.y, 5.5), "tidak bergeser sumbu lain")
	# Meluncur di sepanjang dinding
	var q: Vector2 = c.move(Vector2(4.7, 5.5), Vector2(0.3, 1.0))
	_check(q.y > 6.4 and q.x <= 4.75 + 0.0001, "meluncur sepanjang dinding (x tertahan, y lanjut): %s" % q)
	_check(c.is_free(q), "hasil luncur tetap bebas")
	# Tidak menembus walau delta besar
	var t: Vector2 = c.move(Vector2(1.5, 5.5), Vector2(20.0, 0.0))
	_check(c.is_free(t) and t.x < 5.0, "delta besar tidak menembus")
	# Batas peta
	var b: Vector2 = c.move(Vector2(8.5, 8.5), Vector2(10.0, 10.0))
	_check(b.x <= 9.75 + 0.0001 and b.y <= 9.75 + 0.0001, "tertahan batas peta")
	# Sudut diagonal
	var d: Vector2 = c.move(Vector2(4.3, 4.3), Vector2(1.0, 1.0))
	_check(c.is_free(d), "gerak diagonal ke sudut tetap valid")
	# Layout dunia uji valid: titik mulai bebas
	var map = GroundMapScript.from_rows(WorldLayoutScript.GROUND_ROWS)
	var parsed: Dictionary = WorldObjectKindsScript.parse(WorldLayoutScript.OBJECT_ROWS)
	var wc = GridCollisionScript.new(map.width, map.height, 0.25)
	for y in range(map.height):
		for x in range(map.width):
			if not map.is_walkable(Vector2i(x, y)):
				wc.block_cell(Vector2i(x, y))
	for entry: Dictionary in parsed["objects"]:
		wc.block_cell(entry["cell"])
	var sp: Vector2i = parsed["spawn"]
	_check(sp.x >= 0 and wc.is_free(Vector2(sp.x + 0.5, sp.y + 0.5)), "titik mulai dunia uji bebas")
	_check(map.width == WorldLayoutScript.OBJECT_ROWS[0].length() and map.height == WorldLayoutScript.OBJECT_ROWS.size(), "lapisan lantai dan objek berukuran sama")


func _test_ground_map() -> void:
	var rows: Array[String] = [".d", "s~"]
	var m = GroundMapScript.from_rows(rows)
	_check(m.width == 2 and m.height == 2, "ukuran peta")
	_check(m.kind_at(Vector2i(0, 0)) == 0 and m.kind_at(Vector2i(1, 0)) == 1, "rumput dan tanah")
	_check(m.kind_at(Vector2i(0, 1)) == 2 and m.kind_at(Vector2i(1, 1)) == 3, "batu dan air")
	_check(m.is_walkable(Vector2i(0, 1)) and not m.is_walkable(Vector2i(1, 1)), "air tidak bisa dilewati")
	_check(m.kind_at(Vector2i(5, 5)) == -1 and not m.is_walkable(Vector2i(-1, 0)), "di luar peta")
	var objs: Dictionary = WorldObjectKindsScript.parse(["T@", "RW"] as Array[String])
	_check((objs["objects"] as Array).size() == 3 and objs["spawn"] == Vector2i(1, 0), "parse objek dan titik mulai")


func _test_animator() -> void:
	var a = PlayerAnimatorScript.new()
	a.update(0.1, false, 0)
	_check(a.animation_name() == "idle_s", "mulai idle_s")
	a.update(0.1, true, 5)
	_check(a.animation_name() == "walk_ne", "ke walk_ne")
	_check(is_equal_approx(a.time, 0.1), "waktu direset saat ganti keadaan")
	a.update(0.2, true, 5)
	_check(is_equal_approx(a.phase(), 0.3 / 0.6), "fase walk 0.5")
	a.update(0.3, true, 5)
	_check(is_equal_approx(a.phase(), 0.0) or a.phase() > 0.999, "siklus walk berulang")
	a.update(0.0, false, 6)
	_check(a.animation_name() == "idle_e", "kembali idle_e")
	for i in range(8):
		a.update(0.016, true, i)
		_check(a.animation_name() == "walk_" + IsoMathScript.direction_name(i), "nama animasi arah %d" % i)


func _test_camera_clamp() -> void:
	var view := Vector2(800, 450)
	var b := Rect2(0, 0, 2000, 1000)
	_check(FollowCameraScript.clamp_center(Vector2(1000, 500), view, b) == Vector2(1000, 500), "tengah tidak berubah")
	_check(FollowCameraScript.clamp_center(Vector2(-500, -500), view, b) == Vector2(400, 225), "klamp kiri-atas")
	_check(FollowCameraScript.clamp_center(Vector2(5000, 5000), view, b) == Vector2(1600, 775), "klamp kanan-bawah")
	_check(FollowCameraScript.clamp_center(Vector2(10, 10), view, Rect2(0, 0, 500, 300)) == Vector2(250, 150), "peta lebih kecil: dipusatkan")
	_check(FollowCameraScript.clamp_center(Vector2(7, 9), view, Rect2()) == Vector2(7, 9), "tanpa batas")
