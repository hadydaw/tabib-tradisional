class_name IsoMath
extends RefCounted
## Matematika grid isometrik 2:1 (dimetrik piksel).
## Logika murni tanpa node, bisa diuji dengan game/tests/unit/run_tests.gd.
##
## Konvensi grid: sumbu gx bertambah ke kanan-bawah layar, gy ke kiri-bawah layar.
## Konvensi arah (urutan tetap, lihat docs/ISOMETRIC_VISUAL_STANDARD.md):
## s, sw, w, nw, n, ne, e, se  (s = menghadap bawah layar).

const DIR_NAMES: PackedStringArray = ["s", "sw", "w", "nw", "n", "ne", "e", "se"]


## Titik grid (kontinu) ke posisi layar. `tile` = ukuran diamond (lebar, tinggi).
static func grid_to_screen(grid: Vector2, tile: Vector2) -> Vector2:
	return Vector2((grid.x - grid.y) * tile.x * 0.5, (grid.x + grid.y) * tile.y * 0.5)


## Kebalikan dari grid_to_screen.
static func screen_to_grid(screen: Vector2, tile: Vector2) -> Vector2:
	var gx: float = screen.x / tile.x + screen.y / tile.y
	var gy: float = screen.y / tile.y - screen.x / tile.x
	return Vector2(gx, gy)


## Vektor arah di LAYAR (misalnya dari joystick) ke indeks 0..7 pada DIR_NAMES.
## Vektor nol mengembalikan 0 (s); pemanggil yang menentukan apakah itu berarti diam.
static func direction_index(screen_dir: Vector2) -> int:
	if screen_dir.length_squared() < 0.000001:
		return 0
	var angle: float = atan2(-screen_dir.x, screen_dir.y)
	return posmod(roundi(angle / (PI / 4.0)), 8)


## Indeks arah ke vektor satuan di layar.
static func direction_vector(index: int) -> Vector2:
	var angle: float = float(posmod(index, 8)) * (PI / 4.0)
	return Vector2(-sin(angle), cos(angle))


static func direction_name(index: int) -> String:
	return DIR_NAMES[posmod(index, 8)]


# --- Gerak pemain (Fase 2) ------------------------------------------------------

const DEAD_ZONE: float = 0.15
const FULL_SPEED_INPUT: float = 0.6
const MIN_SPEED_FACTOR: float = 0.4


## Kunci arah masukan ke 8 arah, panjang dipertahankan (maks 1). Nol bila di bawah ambang.
static func snap_input_8(input: Vector2) -> Vector2:
	var mag: float = input.length()
	if mag < 0.0001:
		return Vector2.ZERO
	return direction_vector(direction_index(input)) * minf(mag, 1.0)


## Faktor kecepatan dari panjang masukan: 0 di zona mati, 0.4 di batas zona mati, 1.0 mulai 0.6.
static func speed_factor(input_len: float) -> float:
	if input_len < DEAD_ZONE:
		return 0.0
	return clampf(remap(input_len, DEAD_ZONE, FULL_SPEED_INPUT, MIN_SPEED_FACTOR, 1.0), MIN_SPEED_FACTOR, 1.0)


## Masukan arah LAYAR (x kanan, y bawah) menjadi kecepatan di ruang grid (kotak/detik).
## Besar kecepatan sama di semua 8 arah (diagonal tidak lebih cepat atau lambat):
## panjang hasil = speed * |input|. Tidak bergantung ukuran tile.
static func input_to_grid_velocity(input: Vector2, speed: float) -> Vector2:
	return Vector2(input.x + input.y, input.y - input.x) * (0.5 * sqrt(2.0) * speed)
