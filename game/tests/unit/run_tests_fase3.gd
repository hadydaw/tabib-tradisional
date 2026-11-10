extends SceneTree
## Tes unit Fase 3: pembuat bentuk, katalog properti, bangunan, karakter kustom, interaksi, lokasi.
## Jalankan: godot --headless --path game -s res://tests/unit/run_tests_fase3.gd

var _count: int = 0
var _fail: int = 0


func _init() -> void:
	_test_shapes()
	_test_props()
	_test_structures()
	_test_outfits_and_appearance()
	_test_interaction()
	_test_locations()
	print("Tes Fase 3 dijalankan: %d, gagal: %d" % [_count, _fail])
	quit(1 if _fail > 0 else 0)


func _check(condition: bool, name: String) -> void:
	_count += 1
	if condition:
		print("  OK   ", name)
	else:
		_fail += 1
		printerr("  GAGAL ", name)


func _verts(mesh: ArrayMesh) -> int:
	if mesh == null:
		return -1
	return (mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector2Array).size()


# --- Bentuk ------------------------------------------------------------------

func _test_shapes() -> void:
	var tile := Vector2(64, 32)
	var b := ShapeBuilder.new(tile)
	_check(b.build() == null, "pembuat kosong -> null")
	b.add_box(-0.5, -0.5, 0.5, 0.5, 0.0, 32.0, Color.WHITE)
	_check(b.vertex_count() == 18, "balok = 3 bidang x 6 vertex")
	_check(_verts(b.build()) == 18, "mesh balok 18 vertex")
	_check(b.pt(1.0, 0.0).is_equal_approx(IsoMath.grid_to_screen(Vector2(1, 0), tile)), "pt di tanah = grid_to_screen")
	_check(b.pt(0.0, 0.0, 10.0).is_equal_approx(Vector2(0.0, -10.0)), "z menaikkan titik ke atas layar")
	var roof := ShapeBuilder.new(tile)
	roof.add_hip_roof(-2.0, -1.0, 2.0, 1.0, 64.0, 32.0, Color.RED)
	_check(roof.vertex_count() == 9, "atap = 1 segi empat + 1 segitiga")
	var roof2 := ShapeBuilder.new(tile)
	roof2.add_hip_roof(-1.0, -2.0, 1.0, 2.0, 64.0, 32.0, Color.RED)
	_check(roof2.vertex_count() == 9, "atap arah sebaliknya sama banyak")
	var e := ShapeBuilder.new(tile)
	e.add_ellipse(0, 0, 0, 10, 5, Color.GREEN)
	_check(e.vertex_count() == 12 * 3, "elips 14 segmen = 12 segitiga")
	var l := ShapeBuilder.new(tile)
	l.add_leaf_crown(0, 0, 50, 30, 7, Color.GREEN, Color.DARK_GREEN)
	_check(l.vertex_count() == 7 * 6, "mahkota 7 daun")


# --- Properti ----------------------------------------------------------------

func _test_props() -> void:
	var kinds: Array = PropCatalog.all_kinds()
	_check(kinds.size() >= 40, "katalog punya >= 40 jenis (%d)" % kinds.size())
	var all_ok: bool = true
	for tile: Vector2 in [Vector2(64, 32), Vector2(128, 64)]:
		for k: String in kinds:
			var m: ArrayMesh = PropCatalog.mesh_for(k, tile)
			if m == null or _verts(m) < 3:
				all_ok = false
				printerr("    jenis bermasalah: ", k, " ", tile)
	_check(all_ok, "semua jenis properti menghasilkan mesh (2 ukuran tile)")
	_check(PropCatalog.mesh_for("palm", Vector2(64, 32)) == PropCatalog.mesh_for("palm", Vector2(64, 32)), "mesh di-cache")
	_check(PropCatalog.mesh_for("tidak_ada", Vector2(64, 32)) == null, "jenis tak dikenal -> null")
	_check(not PropCatalog.has_kind("tidak_ada"), "has_kind palsu")
	_check(PropCatalog.blocks("palm") and not PropCatalog.blocks("flowers_red") and not PropCatalog.blocks("herb_a"), "tumbuhan rendah tidak menghalangi")
	for k in ["palm", "banana", "bamboo", "fruit_tree", "bush", "well", "sign", "shelf", "counter", "bed_head"]:
		_check(PropCatalog.has_kind(k), "jenis ada: " + k)


# --- Bangunan ----------------------------------------------------------------

func _test_structures() -> void:
	var tile := Vector2(64, 32)
	var rect := Rect2i(10, 5, 4, 3)
	var style := {"wall": Color("#d9c9a0"), "roof": Color("#a8523a"), "height": 2.0, "roof_height": 1.5, "door_side": "y", "door_cells": [1], "windows": false}
	_check(StructureBuilder.footprint_cells(rect).size() == 12, "footprint 4x3 = 12 sel")
	_check(StructureBuilder.visible_wall_cells(rect).size() == 4 + 3 - 1, "dinding terlihat = w + d - 1")
	var nodes: Array[Node2D] = StructureBuilder.spawn_nodes(tile, rect, style)
	_check(nodes.size() == 7, "node bangunan = dinding terlihat + atap")
	var roof: Node2D = nodes[nodes.size() - 1]
	_check(roof.y_sort_origin > 0, "atap digambar di atas dinding sudut (y_sort_origin)")
	_check(roof.position.is_equal_approx(IsoMath.grid_to_screen(Vector2(13.5, 7.5), tile)), "atap berjangkar di sel sudut depan")
	var plain: int = _verts(StructureBuilder.wall_mesh(tile, rect, style, Vector2i(10, 7)))
	var door: int = _verts(StructureBuilder.wall_mesh(tile, rect, style, Vector2i(11, 7)))
	_check(plain == 18 and door > plain, "sel pintu punya dekal tambahan (%d > %d)" % [door, plain])
	_check(_verts(StructureBuilder.roof_mesh(tile, rect, style)) == 9, "mesh atap")
	for n in nodes:
		n.free()


# --- Karakter ----------------------------------------------------------------

func _test_outfits_and_appearance() -> void:
	_check(OutfitCatalog.count() == 11, "katalog pakaian 11 item")
	_check(OutfitCatalog.ids_for_slot(OutfitItem.Slot.TOP).size() == 4, "4 atasan")
	_check(OutfitCatalog.ids_for_slot(OutfitItem.Slot.BOTTOM).size() == 4, "4 bawahan")
	_check(OutfitCatalog.ids_for_slot(OutfitItem.Slot.HEAD).size() == 3, "3 penutup kepala")
	_check(OutfitCatalog.get_item("tidak_ada") == null and OutfitCatalog.get_item("") == null, "id tak dikenal/kosong -> null")
	for slot in [OutfitItem.Slot.TOP, OutfitItem.Slot.BOTTOM, OutfitItem.Slot.HEAD]:
		var ok: bool = true
		for id in OutfitCatalog.ids_for_slot(slot):
			if OutfitCatalog.get_item(id).slot != slot:
				ok = false
		_check(ok, "slot item konsisten %d" % slot)

	var a := CharacterAppearance.new()
	_check(a.item_in(OutfitItem.Slot.TOP) != null and a.item_in(OutfitItem.Slot.BOTTOM) != null, "pakaian awal: atasan + bawahan")
	_check(a.item_in(OutfitItem.Slot.HEAD) == null, "awal tanpa penutup kepala")
	var hits: Array = [0]
	a.changed.connect(func() -> void: hits[0] += 1)
	_check(a.equip("head_caping") and a.item_in(OutfitItem.Slot.HEAD).id == "head_caping", "pasang caping")
	_check(hits[0] == 1, "sinyal changed saat ganti pakaian")
	_check(not a.equip("tidak_ada"), "id tak dikenal ditolak")
	_check(hits[0] == 1, "tidak ada sinyal bila ditolak")
	a.equip("top_polos_biru")
	_check(a.item_in(OutfitItem.Slot.TOP).id == "top_polos_biru", "ganti atasan menggantikan yang lama")
	a.unequip(OutfitItem.Slot.HEAD)
	_check(a.item_in(OutfitItem.Slot.HEAD) == null, "lepas penutup kepala")
	# cycle HEAD: kosong -> 3 item -> kosong
	var seen: Array[String] = []
	for i in range(4):
		a.cycle_outfit(OutfitItem.Slot.HEAD)
		var it: OutfitItem = a.item_in(OutfitItem.Slot.HEAD)
		seen.append(it.id if it != null else "")
	_check(seen[0] != "" and seen[1] != "" and seen[2] != "" and seen[3] == "", "cycle HEAD melewati 3 item lalu kosong")
	a.cycle_outfit(OutfitItem.Slot.HEAD, -1)
	_check(a.item_in(OutfitItem.Slot.HEAD) != null, "cycle mundur dari kosong ke item terakhir")
	for i in range(10):
		a.cycle_outfit(OutfitItem.Slot.TOP)
		a.cycle_outfit(OutfitItem.Slot.BOTTOM)
	_check(a.item_in(OutfitItem.Slot.TOP) != null and a.item_in(OutfitItem.Slot.BOTTOM) != null, "atasan dan bawahan tak pernah kosong")
	a.set_skin(-1)
	_check(a.skin_index == CharacterPalette.SKIN_TONES.size() - 1, "skin berputar mundur")
	a.set_hair_style(CharacterPalette.HAIR_STYLES.size())
	_check(a.hair_style == 0, "gaya rambut berputar maju")
	_check(a.skin_color() == CharacterPalette.SKIN_TONES[a.skin_index], "warna kulit sesuai indeks")

	# Serialisasi
	var d: Dictionary = a.to_dict()
	var json_text: String = JSON.stringify(d)
	var parsed: Variant = JSON.parse_string(json_text)
	_check(parsed is Dictionary, "JSON valid")
	var b: CharacterAppearance = CharacterAppearance.from_dict(parsed)
	_check(JSON.stringify(b.to_dict()) == json_text, "roundtrip JSON identik")
	var junk: CharacterAppearance = CharacterAppearance.from_dict({"skin": 99, "hair_style": -7, "hair_color": 1000, "outfit": {"0": "tidak_ada", "9": "head_caping"}})
	_check(junk.skin_index >= 0 and junk.skin_index < CharacterPalette.SKIN_TONES.size(), "skin tak valid dibersihkan")
	_check(junk.hair_style >= 0 and junk.hair_style < CharacterPalette.HAIR_STYLES.size(), "gaya rambut tak valid dibersihkan")
	_check(junk.item_in(OutfitItem.Slot.TOP) != null and junk.item_in(OutfitItem.Slot.BOTTOM) != null, "pakaian wajib dipulihkan ke default")
	_check(junk.item_in(OutfitItem.Slot.HEAD) != null, "id valid pada data kotor tetap dipasang")
	_check(CharacterAppearance.from_dict({}).display_name == "Tabib", "dict kosong -> default")


# --- Interaksi ---------------------------------------------------------------

func _test_interaction() -> void:
	var near := Interactable.new("a", Vector2i(5, 5), "A")
	var far := Interactable.new("b", Vector2i(9, 5), "B")
	var list: Array = [far, near]
	_check(InteractionSystem.find_best(Vector2(5.5, 6.5), Vector2.ZERO, list) == near, "pilih yang terdekat")
	_check(InteractionSystem.find_best(Vector2(5.5, 9.0), Vector2.ZERO, list) == null, "di luar radius -> null")
	_check(InteractionSystem.find_best(Vector2(1.0, 1.0), Vector2.ZERO, []) == null, "daftar kosong -> null")
	# Dua titik berjarak sama: yang di depan arah hadap menang
	var left := Interactable.new("l", Vector2i(4, 5), "L")
	var right := Interactable.new("r", Vector2i(6, 5), "R")
	var pair: Array = [left, right]
	var pos := Vector2(5.5, 5.5)
	_check(InteractionSystem.find_best(pos, Vector2(1, 0), pair) == right, "hadap kanan -> pilih kanan")
	_check(InteractionSystem.find_best(pos, Vector2(-1, 0), pair) == left, "hadap kiri -> pilih kiri")
	_check(Interactable.new("x", Vector2i(2, 3), "X").center() == Vector2(2.5, 3.5), "tengah sel")


# --- Lokasi ------------------------------------------------------------------

func _reachable(data: LocationData, start: Vector2i) -> Dictionary:
	var blocked: Dictionary = data.blocked_cells()
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + step
			if n.x < 0 or n.y < 0 or n.x >= data.width or n.y >= data.height:
				continue
			if blocked.has(n) or seen.has(n):
				continue
			seen[n] = true
			queue.append(n)
	return seen


func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x), floori(p.y))


func _test_locations() -> void:
	for id in LocationRegistry.IDS:
		var data: LocationData = LocationRegistry.get_location(id)
		_check(data != null and data.id == id, "lokasi ada: " + id)
		_check(data.kinds.size() == data.width * data.height, "%s: ukuran lantai sesuai" % id)
		_check(LocationRegistry.get_location(id) == data, "%s: di-cache" % id)
		var blocked: Dictionary = data.blocked_cells()
		var col: GridCollision = data.build_collision(0.25)
		# Objek: tidak menumpuk, tidak di air, jenis valid
		var seen_cells: Dictionary = {}
		var dup: bool = false
		var bad_kind: bool = false
		var in_water: bool = false
		var gm: GroundMap = data.ground_map()
		for o in data.objects:
			if seen_cells.has(o["cell"]):
				dup = true
			seen_cells[o["cell"]] = true
			if not PropCatalog.has_kind(o["kind"]):
				bad_kind = true
			if not gm.is_walkable(o["cell"]):
				in_water = true
		_check(not dup, "%s: tidak ada objek menumpuk" % id)
		_check(not bad_kind, "%s: semua jenis objek valid" % id)
		_check(not in_water, "%s: tidak ada objek di air" % id)
		# Bangunan tidak menimpa objek
		var overlap: bool = false
		for bd in data.buildings:
			for c in StructureBuilder.footprint_cells(bd["rect"]):
				if seen_cells.has(c):
					overlap = true
		_check(not overlap, "%s: bangunan tidak menimpa objek" % id)
		# Titik mulai bebas
		_check(data.spawns.size() >= 1, "%s: punya titik mulai" % id)
		for sp_name in data.spawns:
			var sp: Vector2 = data.spawns[sp_name]
			_check(col.is_free(sp), "%s: titik mulai '%s' bebas" % [id, sp_name])
			_check(data.transition_at(_cell_of(sp)).is_empty(), "%s: titik mulai '%s' bukan keset (tidak memicu ulang)" % [id, sp_name])
		# Perpindahan menunjuk lokasi dan titik mulai yang ada
		for t in data.transitions:
			var target: LocationData = LocationRegistry.get_location(t["target"])
			_check(target != null and target.spawns.has(t["spawn"]), "%s: perpindahan ke %s/%s valid" % [id, t["target"], t["spawn"]])
			for c: Vector2i in t["cells"]:
				_check(not blocked.has(c), "%s: sel keset %s bisa dijangkau tanpa terblokir" % [id, c])
				_check(gm.kind_at(c) == TileKinds.MAT, "%s: sel keset %s bertanda keset" % [id, c])
		# Keterjangkauan dari titik mulai pertama
		var first_spawn: Vector2 = data.spawns.values()[0]
		var reach: Dictionary = _reachable(data, _cell_of(first_spawn))
		for sp_name in data.spawns:
			_check(reach.has(_cell_of(data.spawns[sp_name])), "%s: titik mulai '%s' terjangkau" % [id, sp_name])
		for t in data.transitions:
			for c: Vector2i in t["cells"]:
				_check(reach.has(c), "%s: keset %s terjangkau" % [id, c])
		for it in data.interactables:
			var ok: bool = false
			for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if reach.has(it.cell + step):
					ok = true
			_check(ok, "%s: titik interaksi '%s' bisa didekati" % [id, it.id])
		var free_total: int = data.width * data.height - blocked.size()
		_check(float(reach.size()) / float(free_total) >= 0.85, "%s: >= 85%% sel bebas terjangkau (%d/%d)" % [id, reach.size(), free_total])

	var village: LocationData = LocationRegistry.get_location("desa")
	_check(village.buildings.size() >= 7, "desa: >= 6 rumah + klinik (%d)" % village.buildings.size())
	var has_clinic: bool = false
	for bd in village.buildings:
		if bd["name"] == "Klinik Tabib":
			has_clinic = true
	_check(has_clinic, "desa: ada bangunan Klinik Tabib")
	_check(village.count_kind("palm") >= 8 and village.count_kind("banana") >= 3 and village.count_kind("bamboo") >= 3, "desa: pepohonan tropis")
	_check(village.count_kind("herb_a") + village.count_kind("herb_b") + village.count_kind("herb_c") >= 20, "desa: kebun herbal berisi tanaman")
	_check(village.count_kind("fence_x") + village.count_kind("fence_y") >= 30, "desa: pagar kebun")
	_check(village.count_kind("well") == 1 and village.count_kind("lantern") >= 4, "desa: sumur dan lentera")
	var garden_plots: int = 0
	var vgm: GroundMap = village.ground_map()
	for y in range(village.height):
		for x in range(village.width):
			if vgm.kind_at(Vector2i(x, y)) == TileKinds.PLOT:
				garden_plots += 1
	_check(garden_plots >= 40, "desa: petak tanah olahan (%d)" % garden_plots)
	_check(village.zone_at(Vector2i(35, 33)) == "Kebun Herbal", "zona kebun herbal")
	_check(village.interactable_by_id("village_herb_garden") != null and village.interactable_by_id("village_well") != null, "desa: titik interaksi kebun dan sumur")
	var budget: int = village.objects.size()
	for bd in village.buildings:
		budget += StructureBuilder.visible_wall_cells(bd["rect"]).size() + 1
	_check(budget < 450, "anggaran node desa < 450 (%d)" % budget)

	var clinic: LocationData = LocationRegistry.get_location("klinik")
	for required in ["clinic_reception", "clinic_exam_bed", "clinic_treatment_table", "clinic_herb_shelf", "clinic_compounding"]:
		_check(clinic.interactable_by_id(required) != null, "klinik: titik interaksi " + required)
	var zone_names: Array = []
	for z in clinic.zones:
		zone_names.append(z["name"])
	for zn in ["Area Penerimaan", "Ruang Pemeriksaan", "Area Peracikan"]:
		_check(zone_names.has(zn), "klinik: zona " + zn)
	_check(clinic.zone_at(_cell_of(clinic.spawns["dari_desa"])) == "Area Penerimaan", "klinik: pintu masuk di area penerimaan")
	_check(clinic.count_kind("shelf") >= 4 and clinic.count_kind("bed_head") == 1 and clinic.count_kind("table_treat") == 1, "klinik: rak herbal, tempat tidur, meja pengobatan")
	_check(clinic.objects.size() < 150, "anggaran node klinik < 150 (%d)" % clinic.objects.size())
	# Titik interaksi dapat dipilih dari sel tetangga yang bebas (dengan arah hadap ke titik itu)
	for it in clinic.interactables:
		var picked: bool = false
		var cblocked: Dictionary = clinic.blocked_cells()
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = it.cell + step
			if cblocked.has(n) or n.x < 0 or n.y < 0 or n.x >= clinic.width or n.y >= clinic.height:
				continue
			var pos := Vector2(n.x + 0.5, n.y + 0.5)
			if InteractionSystem.find_best(pos, it.center() - pos, clinic.interactables) == it:
				picked = true
		_check(picked, "klinik: '%s' terpilih saat didekati menghadapnya" % it.id)
