extends SceneTree
## Runner tes unit sederhana (tanpa plugin). Jalankan:
##   godot --headless --path game -s res://tests/unit/run_tests.gd
## Keluar dengan kode 0 jika semua lolos, 1 jika ada yang gagal.

const IsoMathScript := preload("res://core/systems/iso_math.gd")
const PerfStatsScript := preload("res://core/systems/perf_stats.gd")
const IsoMeshesScript := preload("res://features/world/iso_meshes.gd")

var _count: int = 0
var _fail: int = 0


func _init() -> void:
	_test_grid_roundtrip()
	_test_grid_known_points()
	_test_direction_index()
	_test_direction_roundtrip()
	_test_perf_stats()
	_test_meshes()
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
