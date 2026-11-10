class_name LocationBuilder
extends RefCounted
## Perakit LocationData dari kode (isi lantai, taruh objek/bangunan, titik interaksi, dll.).
## Acak memakai seed tetap sehingga dunia sama di setiap perangkat.

var data: LocationData = LocationData.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _occupied: Dictionary = {}
var _reserved: Dictionary = {}


func _init(p_id: String, p_name: String, p_width: int, p_height: int, seed_value: int) -> void:
	data.id = p_id
	data.display_name = p_name
	data.width = p_width
	data.height = p_height
	data.kinds.resize(p_width * p_height)
	rng.seed = seed_value


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < data.width and cell.y < data.height


func fill(kind: int) -> void:
	data.kinds.fill(kind)


func set_kind(cell: Vector2i, kind: int) -> void:
	if in_bounds(cell):
		data.kinds[cell.y * data.width + cell.x] = kind


func kind_at(cell: Vector2i) -> int:
	if not in_bounds(cell):
		return -1
	return data.kinds[cell.y * data.width + cell.x]


func rect(r: Rect2i, kind: int) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			set_kind(Vector2i(x, y), kind)


## Cegah penempatan acak/otomatis di area ini (jalan, alun-alun, halaman).
func reserve(r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_reserved[Vector2i(x, y)] = true


func is_free(cell: Vector2i) -> bool:
	return in_bounds(cell) and not _occupied.has(cell) and TileKinds.is_walkable(kind_at(cell))


## Taruh objek bila sel bebas dan tidak dicadangkan. True bila berhasil.
func try_object(cell: Vector2i, kind: String) -> bool:
	if not is_free(cell) or _reserved.has(cell):
		return false
	return force_object(cell, kind)


## Taruh objek tanpa memeriksa pencadangan (tetap tidak boleh menumpuk atau di air).
func force_object(cell: Vector2i, kind: String) -> bool:
	if not is_free(cell):
		return false
	assert(PropCatalog.has_kind(kind), "jenis properti tidak dikenal: " + kind)
	data.objects.append({"cell": cell, "kind": kind})
	_occupied[cell] = true
	return true


func add_building(r: Rect2i, style: Dictionary, p_name: String) -> void:
	data.buildings.append({"rect": r, "style": style, "name": p_name})
	for c in StructureBuilder.footprint_cells(r):
		_occupied[c] = true


func add_interactable(p_id: String, cell: Vector2i, prompt: String) -> void:
	data.interactables.append(Interactable.new(p_id, cell, prompt))


func add_transition(cells: Array[Vector2i], target: String, spawn: String) -> void:
	data.transitions.append({"cells": cells, "target": target, "spawn": spawn})


func set_spawn(p_name: String, grid: Vector2) -> void:
	data.spawns[p_name] = grid


func add_zone(p_name: String, r: Rect2i) -> void:
	data.zones.append({"name": p_name, "rect": r})


## Sebar `count` objek acak dari `kinds` di dalam `area`. Mengembalikan jumlah yang berhasil.
func scatter(kinds: Array[String], count: int, area: Rect2i) -> int:
	var placed: int = 0
	var attempts: int = 0
	while placed < count and attempts < count * 30:
		attempts += 1
		var c := Vector2i(rng.randi_range(area.position.x, area.end.x - 1), rng.randi_range(area.position.y, area.end.y - 1))
		if try_object(c, kinds[rng.randi() % kinds.size()]):
			placed += 1
	return placed
