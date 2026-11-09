extends SceneTree
## Runner tes unit sederhana (tanpa plugin). Jalankan:
##   godot --headless --path game -s res://tests/unit/run_tests.gd
## Keluar dengan kode 0 jika semua lolos, 1 jika ada yang gagal.

const IsoMathScript := preload("res://core/systems/iso_math.gd")

var _count: int = 0
var _fail: int = 0


func _init() -> void:
	_test_grid_roundtrip()
	_test_grid_known_points()
	_test_direction_index()
	_test_direction_roundtrip()
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
