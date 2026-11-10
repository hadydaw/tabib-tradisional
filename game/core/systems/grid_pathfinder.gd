class_name GridPathfinder
extends RefCounted
## Pencari jalan A* pada grid sel (logika murni, dites unit). Dipakai NPC dan memakai
## aturan tabrakan yang sama dengan pemain: sel bebas = bisa dilewati kotak berjari-jari < 0,5.
## Gerak 8 arah; diagonal hanya bila kedua sel ortogonalnya bebas (tidak memotong sudut).
## Hasil jalur = daftar sel dari tujuan pertama langkah (tanpa sel awal) sampai goal.

const SQRT2: float = 1.41421356
const MAX_NODES: int = 6000
const DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

var width: int
var height: int
## Sel terhalang statis (dinding, objek, air).
var blocked: Dictionary = {}
## Biaya ekstra per sel (mis. keset pintu agar tidak dijadikan jalur lewat).
var extra_cost: Dictionary = {}


func _init(p_width: int, p_height: int) -> void:
	width = p_width
	height = p_height


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


## Sel bisa diinjak? `allow` = sel tambahan yang diizinkan (kursi/tujuan), `avoid` = sel sementara terhalang.
func passable(c: Vector2i, avoid: Dictionary, allow: Dictionary) -> bool:
	if not in_bounds(c):
		return false
	if avoid.has(c):
		return false
	if blocked.has(c) and not allow.has(c):
		return false
	return true


func find_path(start: Vector2i, goal: Vector2i, avoid: Dictionary = {}, allow: Dictionary = {}) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if start == goal:
		return out
	if not in_bounds(goal) or not in_bounds(start):
		return out
	var allow2: Dictionary = allow
	if not passable(goal, avoid, allow2):
		return out
	var g: Dictionary = {start: 0.0}
	var came: Dictionary = {}
	var open: Array[Vector2i] = [start]
	var f: Dictionary = {start: _h(start, goal)}
	var closed: Dictionary = {}
	var expanded: int = 0
	while not open.is_empty():
		# pilih f terendah (daftar kecil; cukup linear)
		var bi: int = 0
		var best: float = f[open[0]]
		for i in range(1, open.size()):
			var fv: float = f[open[i]]
			if fv < best:
				best = fv
				bi = i
		var cur: Vector2i = open[bi]
		open.remove_at(bi)
		if cur == goal:
			return _rebuild(came, cur)
		closed[cur] = true
		expanded += 1
		if expanded > MAX_NODES:
			break
		for d in DIRS:
			var nb: Vector2i = cur + d
			if closed.has(nb) or not passable(nb, avoid, allow2):
				continue
			var diag: bool = d.x != 0 and d.y != 0
			if diag:
				if not passable(Vector2i(cur.x + d.x, cur.y), avoid, allow2) or not passable(Vector2i(cur.x, cur.y + d.y), avoid, allow2):
					continue
				# tidak memotong sudut sel statis, dan kursi tidak dimasuki secara diagonal
				if blocked.has(nb) or blocked.has(Vector2i(cur.x + d.x, cur.y)) or blocked.has(Vector2i(cur.x, cur.y + d.y)):
					continue
			var step: float = (SQRT2 if diag else 1.0) + float(extra_cost.get(nb, 0.0))
			var ng: float = float(g[cur]) + step
			if not g.has(nb) or ng < float(g[nb]):
				g[nb] = ng
				came[nb] = cur
				f[nb] = ng + _h(nb, goal)
				if not open.has(nb):
					open.append(nb)
	return out


func _h(a: Vector2i, b: Vector2i) -> float:
	var dx: float = absf(float(a.x - b.x))
	var dy: float = absf(float(a.y - b.y))
	return (dx + dy) + (SQRT2 - 2.0) * minf(dx, dy)  # jarak oktil


func _rebuild(came: Dictionary, end: Vector2i) -> Array[Vector2i]:
	var rev: Array[Vector2i] = [end]
	var c: Vector2i = end
	while came.has(c):
		c = came[c]
		rev.append(c)
	rev.pop_back()  # buang sel awal
	rev.reverse()
	return rev


## Sel bebas terdekat dari `from` (BFS, jari-jari terbatas) yang bukan dalam `avoid`, bukan terhalang,
## bukan sel biaya ekstra (keset), dan bukan sel `exclude`. Mengembalikan Vector2i(-1,-1) bila tidak ada.
func nearest_open(from: Vector2i, avoid: Dictionary, max_radius: int = 5, exclude: Dictionary = {}) -> Vector2i:
	var seen: Dictionary = {from: true}
	var frontier: Array[Vector2i] = [from]
	for _r in range(max_radius):
		var next: Array[Vector2i] = []
		for c in frontier:
			for d in DIRS:
				var nb: Vector2i = c + d
				if seen.has(nb):
					continue
				seen[nb] = true
				if not passable(nb, avoid, {}):
					continue
				if d.x != 0 and d.y != 0 and (not passable(Vector2i(c.x + d.x, c.y), avoid, {}) or not passable(Vector2i(c.x, c.y + d.y), avoid, {})):
					continue
				next.append(nb)
				if not extra_cost.has(nb) and not exclude.has(nb):
					return nb
		frontier = next
	return Vector2i(-1, -1)


## Sel terdekat (oktil) dari `target` yang dapat diinjak; untuk tujuan yang kebetulan terhalang.
func nearest_passable(target: Vector2i, avoid: Dictionary = {}, max_radius: int = 4) -> Vector2i:
	if passable(target, avoid, {}):
		return target
	return nearest_open(target, avoid, max_radius)
