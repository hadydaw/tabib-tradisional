class_name Player
extends Node2D
## Pemain: bergerak 8 arah di ruang grid dengan tabrakan, menggerakkan animasi.
## Masukan datang dari luar lewat `move_input` (joystick/keyboard) sehingga logika ini
## tidak bergantung pada perangkat masukan. Posisi node = telapak kaki (titik Y-sort).

const MAX_DELTA: float = 0.05  # batas delta agar frame lambat tidak melempar pemain jauh

var walk_speed: float = 3.5  # kotak per detik, sama di semua 8 arah
var move_input: Vector2 = Vector2.ZERO  # arah LAYAR, panjang 0..1
var grid_pos: Vector2 = Vector2(0.5, 0.5)
var facing: int = 0
var tile: Vector2 = Vector2(64, 32)
var collision: GridCollision
var animator: PlayerAnimator = PlayerAnimator.new()
var last_moved: bool = false

var _view: PlayerPlaceholder


func setup(p_tile: Vector2, p_collision: GridCollision, start_grid: Vector2) -> void:
	tile = p_tile
	collision = p_collision
	grid_pos = start_grid
	position = IsoMath.grid_to_screen(grid_pos, tile)
	if _view == null:
		_view = PlayerPlaceholder.new()
		_view.body_scale = tile.x / 64.0
		add_child(_view)


func _process(delta: float) -> void:
	advance(delta)


## Maju satu langkah waktu. Dipisah dari _process agar bisa dites dengan delta tetap.
func advance(delta: float) -> void:
	delta = minf(delta, MAX_DELTA)
	var dir_in: Vector2 = IsoMath.snap_input_8(move_input)
	last_moved = false
	var factor: float = IsoMath.speed_factor(dir_in.length())
	if factor > 0.0:
		facing = IsoMath.direction_index(dir_in)
		var dir: Vector2 = IsoMath.direction_vector(facing)
		var vel: Vector2 = IsoMath.input_to_grid_velocity(dir, walk_speed * factor)
		var before: Vector2 = grid_pos
		grid_pos = collision.move(grid_pos, vel * delta)
		last_moved = grid_pos.distance_squared_to(before) > 0.000001
	animator.update(delta, last_moved, facing)
	position = IsoMath.grid_to_screen(grid_pos, tile)
	if _view != null:
		_view.apply_animation(animator.state, animator.phase(), animator.facing)


## Pindahkan langsung (mulai, uji). Tidak memeriksa tabrakan.
func teleport_grid(cell_pos: Vector2) -> void:
	grid_pos = cell_pos
	position = IsoMath.grid_to_screen(grid_pos, tile)
