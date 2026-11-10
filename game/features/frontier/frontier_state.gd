class_name FrontierState
extends RefCounted
## Keadaan eksplorasi lanjut (Fase 9): inventaris bahan langka, penemuan pertama (Buku Tabib), cooldown titik,
## teka-teki yang sudah dipecahkan, peti harta, dan sel yang masih tertutup. Logika murni (dites unit); efek ke
## koin dan quest dijalankan GameWorld / MinigameManager.

## id bahan langka -> jumlah yang dimiliki
var rare: Dictionary = {}
## id bahan langka -> true (penemuan pertama, sudah tercatat di Buku Tabib)
var firsts: Dictionary = {}
## id titik -> menit absolut terakhir diambil
var node_taken: Dictionary = {}
## id teka-teki -> true
var puzzles: Dictionary = {}
## true bila peti gua sudah dibuka
var chest_opened: bool = false


func total_count() -> int:
	var n: int = 0
	for k in rare.keys():
		n += int(rare[k])
	return n


func distinct_found() -> int:
	return firsts.size()


## Gua Kapur terbuka setelah pemain menemukan sejumlah jenis penemuan langka berbeda (syarat eksplorasi).
func gua_unlocked() -> bool:
	return distinct_found() >= RareDb.GATE_GUA_FIRST_FINDS


func node_ready(node_id: String, now_minutes: float) -> bool:
	if not RareDb.is_node(node_id):
		return false
	if not node_taken.has(node_id):
		return true
	return now_minutes - float(node_taken[node_id]) >= float(RareDb.COOLDOWN_MINUTES)


func mark_node(node_id: String, now_minutes: float) -> void:
	if RareDb.is_node(node_id):
		node_taken[node_id] = now_minutes


## Menambah satu bahan langka. Mengembalikan true bila itu penemuan pertama jenis tersebut.
func discover(item: String, n: int = 1) -> bool:
	if not RareDb.has_item(item) or n <= 0:
		return false
	rare[item] = int(rare.get(item, 0)) + n
	if firsts.has(item):
		return false
	firsts[item] = true
	return true


func count(item: String) -> int:
	return int(rare.get(item, 0))


func puzzle_solved(id: String) -> bool:
	return puzzles.has(id)


## Teka-teki selesai untuk pertama kali. Mengembalikan false bila sudah pernah atau id tidak dikenal.
func solve(id: String) -> bool:
	if not RareDb.has_puzzle(id) or puzzles.has(id):
		return false
	puzzles[id] = true
	return true


func fog_lifted() -> bool:
	return puzzle_solved(RareDb.RIDDLE_ID)


func loot_chest() -> bool:
	if chest_opened:
		return false
	chest_opened = true
	return true


## Sel yang saat ini tertutup di lokasi `loc_id` (dipakai sebagai penghalang dinamis).
func sealed_cells(loc_id: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if loc_id == "rawa" and not fog_lifted():
		_add_rect(out, RawaLocation.FOG)
	elif loc_id == "gua":
		if not puzzle_solved(RareDb.TABLET_ID):
			_add_rect(out, GuaLocation.DOOR)
		if not puzzle_solved(RareDb.LEVER_ID):
			_add_rect(out, GuaLocation.CRACK)
	return out


static func _add_rect(out: Array[Vector2i], r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			out.append(Vector2i(x, y))


func to_dict() -> Dictionary:
	return {"rare": rare.duplicate(), "firsts": firsts.duplicate(), "node_taken": node_taken.duplicate(),
		"puzzles": puzzles.duplicate(), "chest_opened": chest_opened}


## Membaca data (JSON). Nilai tak dikenal dibuang, angka dibatasi; tidak pernah melempar galat.
func from_dict(d: Dictionary) -> void:
	rare = {}
	var r: Variant = d.get("rare", {})
	if r is Dictionary:
		for k in r.keys():
			if RareDb.has_item(String(k)):
				rare[String(k)] = maxi(0, int(r[k]))
	firsts = {}
	var f: Variant = d.get("firsts", {})
	if f is Dictionary:
		for k in f.keys():
			if RareDb.has_item(String(k)):
				firsts[String(k)] = true
	node_taken = {}
	var nt: Variant = d.get("node_taken", {})
	if nt is Dictionary:
		for k in nt.keys():
			if RareDb.is_node(String(k)):
				node_taken[String(k)] = maxf(0.0, float(nt[k]))
	puzzles = {}
	var p: Variant = d.get("puzzles", {})
	if p is Dictionary:
		for k in p.keys():
			if RareDb.has_puzzle(String(k)):
				puzzles[String(k)] = true
	chest_opened = bool(d.get("chest_opened", false))
