class_name LocationData
extends RefCounted
## Data satu lokasi (desa, interior klinik, ...): lantai, objek, bangunan, titik interaksi,
## perpindahan, titik mulai, dan zona. Data murni sehingga bisa dites tanpa engine.

var id: String = ""
var display_name: String = ""
var width: int = 0
var height: int = 0
var kinds: PackedInt32Array = PackedInt32Array()
## {"cell": Vector2i, "kind": String}
var objects: Array[Dictionary] = []
## {"rect": Rect2i, "style": Dictionary, "name": String}
var buildings: Array[Dictionary] = []
var interactables: Array[Interactable] = []
## {"cells": Array[Vector2i], "target": String, "spawn": String}
var transitions: Array[Dictionary] = []
## nama -> posisi grid (Vector2)
var spawns: Dictionary = {}
## {"name": String, "rect": Rect2i}
var zones: Array[Dictionary] = []
## Titik tujuan bernama untuk NPC: nama -> Array[Vector2i] (sel jalan yang bebas).
var spots: Dictionary = {}
## Kursi: {"cell": Vector2i, "facing": int, "kind": "tunggu"|"periksa"}. Sel kursi boleh dimasuki NPC walau terhalang bagi pemain.
var seats: Array[Dictionary] = []
## Pintu rumah: nama spot -> sel pintu (NPC menghilang/muncul di sini saat masuk/keluar rumah).
var doors: Dictionary = {}


func ground_map() -> GroundMap:
	return GroundMap.from_kinds(width, height, kinds)


## Semua sel yang menghalangi pemain (tile tak bisa dilewati, objek penghalang, bangunan).
func blocked_cells() -> Dictionary:
	var out: Dictionary = {}
	var gm: GroundMap = ground_map()
	for y in range(height):
		for x in range(width):
			if not gm.is_walkable(Vector2i(x, y)):
				out[Vector2i(x, y)] = true
	for o in objects:
		if PropCatalog.blocks(o["kind"]):
			out[o["cell"]] = true
	for b in buildings:
		for c in StructureBuilder.footprint_cells(b["rect"]):
			out[c] = true
	return out


func build_collision(radius: float) -> GridCollision:
	var col := GridCollision.new(width, height, radius)
	for c: Vector2i in blocked_cells():
		col.block_cell(c)
	return col


## Data perpindahan di sel ini, atau Dictionary kosong.
func transition_at(cell: Vector2i) -> Dictionary:
	for t in transitions:
		if (t["cells"] as Array).has(cell):
			return t
	return {}


func zone_at(cell: Vector2i) -> String:
	for z in zones:
		if (z["rect"] as Rect2i).has_point(cell):
			return z["name"]
	return ""


func interactable_by_id(p_id: String) -> Interactable:
	for it in interactables:
		if it.id == p_id:
			return it
	return null


func count_kind(kind: String) -> int:
	var n: int = 0
	for o in objects:
		if o["kind"] == kind:
			n += 1
	return n


func spot_cells(spot: String) -> Array:
	return spots.get(spot, [])


func seat_at(cell: Vector2i) -> Dictionary:
	for st in seats:
		if st["cell"] == cell:
			return st
	return {}


func is_seat(cell: Vector2i) -> bool:
	return not seat_at(cell).is_empty()


func seats_of_kind(kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for st in seats:
		if st["kind"] == kind:
			out.append(st)
	return out
