class_name VillageLocation
extends RefCounted
## Desa tradisional Nusantara (placeholder): jalan, alun-alun, rumah penduduk, klinik tabib,
## kebun herbal, kolam, pepohonan tropis, dekorasi. Tata letak adalah data uji, bukan desain
## dunia final. Sumbu: x ke kanan-bawah layar, y ke kiri-bawah layar.

const WIDTH: int = 48
const HEIGHT: int = 40
const CLINIC_RECT: Rect2i = Rect2i(19, 6, 9, 6)  # sel x 19..27, y 6..11; pintu di sisi +y


static func house_style(roof: Color, wall: Color, door_side: String, door_cells: Array) -> Dictionary:
	return {"wall": wall, "roof": roof, "height": 2.0, "roof_height": 1.5, "door_side": door_side, "door_cells": door_cells, "windows": true}


static func build() -> LocationData:
	var b := LocationBuilder.new("desa", "Desa", WIDTH, HEIGHT, 20261110)
	b.fill(TileKinds.GRASS)

	# --- Jalan dan alun-alun ---
	var main_road := Rect2i(0, 19, 48, 3)
	var lane := Rect2i(22, 22, 3, 18)
	var square := Rect2i(16, 12, 15, 7)
	b.rect(main_road, TileKinds.DIRT)
	b.rect(lane, TileKinds.DIRT)
	b.rect(square, TileKinds.STONE)
	b.reserve(main_road)
	b.reserve(lane)
	b.reserve(square)

	# --- Kolam (timur laut) ---
	var pond := Rect2i(38, 3, 7, 5)
	b.rect(pond, TileKinds.WATER)
	for corner in [pond.position, Vector2i(pond.end.x - 1, pond.position.y), Vector2i(pond.position.x, pond.end.y - 1), Vector2i(pond.end.x - 1, pond.end.y - 1)]:
		b.set_kind(corner, TileKinds.GRASS)
	b.reserve(Rect2i(37, 2, 9, 7))

	# --- Klinik tabib ---
	var clinic_style := {"wall": Color("#d8d4b4"), "roof": Color("#3f7a58"), "height": 2.4, "roof_height": 1.8, "door_side": "y", "door_cells": [3, 4], "windows": true}
	b.add_building(CLINIC_RECT, clinic_style, "Klinik Tabib")
	b.reserve(Rect2i(CLINIC_RECT.position.x - 1, CLINIC_RECT.position.y - 1, CLINIC_RECT.size.x + 2, CLINIC_RECT.size.y + 2))
	# Keset di depan pintu: berjalan ke sini masuk ke klinik.
	var door_x: int = CLINIC_RECT.position.x + 3
	var mat_y: int = CLINIC_RECT.end.y  # y = 12, tepat di depan baris dinding depan
	b.set_kind(Vector2i(door_x, mat_y), TileKinds.MAT)
	b.set_kind(Vector2i(door_x + 1, mat_y), TileKinds.MAT)
	var mat_cells: Array[Vector2i] = [Vector2i(door_x, mat_y), Vector2i(door_x + 1, mat_y)]
	b.add_transition(mat_cells, "klinik", "dari_desa")
	b.add_zone("Klinik Tabib", Rect2i(CLINIC_RECT.position.x - 2, CLINIC_RECT.position.y, CLINIC_RECT.size.x + 4, CLINIC_RECT.size.y + 3))
	b.force_object(Vector2i(door_x - 2, mat_y + 0), "sign")
	b.add_interactable("village_clinic_sign", Vector2i(door_x - 2, mat_y), "Papan Klinik Tabib")
	b.force_object(Vector2i(door_x + 3, mat_y), "jar")
	b.force_object(Vector2i(door_x - 3, mat_y), "pot")
	b.force_object(Vector2i(door_x + 4, mat_y), "pot")

	# --- Rumah penduduk ---
	var houses: Array = [
		[Rect2i(4, 12, 4, 4), "#a8523a", "#e0d2b0", "y", [1, 2]],
		[Rect2i(10, 13, 3, 3), "#b8763a", "#d9c9a0", "y", [1]],
		[Rect2i(33, 12, 4, 4), "#8a5a3a", "#e0d2b0", "y", [1, 2]],
		[Rect2i(39, 13, 3, 3), "#a8523a", "#d9c9a0", "y", [1]],
		[Rect2i(6, 25, 4, 3), "#7a4a6a", "#e0d2b0", "x", [1]],
		[Rect2i(35, 23, 3, 4), "#8a5a3a", "#d9c9a0", "x", [1, 2]],
	]
	var hi: int = 1
	for h: Array in houses:
		var r: Rect2i = h[0]
		b.add_building(r, house_style(Color(h[1]), Color(h[2]), h[3], h[4]), "Rumah %d" % hi)
		b.reserve(Rect2i(r.position.x - 1, r.position.y - 1, r.size.x + 2, r.size.y + 2))
		# jalan setapak dari pintu ke jalan raya
		if h[3] == "y":
			var px: int = r.position.x + int((h[4] as Array)[0])
			for yy in range(r.end.y, 19):
				b.set_kind(Vector2i(px, yy), TileKinds.DIRT)
				b.reserve(Rect2i(px, yy, 1, 1))
		else:
			var py: int = r.position.y + int((h[4] as Array)[0])
			var stop_x: int = 22 if r.end.x <= 22 else r.end.x + 3
			for xx in range(r.end.x, stop_x):
				b.set_kind(Vector2i(xx, py), TileKinds.DIRT)
				b.reserve(Rect2i(xx, py, 1, 1))
		# titik pintu rumah: sel tepat di depan pintu (NPC masuk/keluar rumah di sini)
		var front: Vector2i
		if h[3] == "y":
			front = Vector2i(r.position.x + int((h[4] as Array)[0]), r.end.y)
		else:
			front = Vector2i(r.end.x, r.position.y + int((h[4] as Array)[0]))
		b.add_spot("rumah_%d" % hi, [front] as Array[Vector2i])
		b.add_door("rumah_%d" % hi, front)
		hi += 1
	# jalan setapak rumah 6 ke jalan raya (rumah menghadap timur, jauh dari lorong)
	for yy in range(21, 25):
		b.set_kind(Vector2i(40, yy), TileKinds.DIRT)
		b.reserve(Rect2i(40, yy, 1, 1))
	b.add_zone("Permukiman Barat", Rect2i(2, 11, 14, 8))
	b.add_zone("Permukiman Timur", Rect2i(32, 11, 12, 8))

	# --- Kebun herbal (tenggara) ---
	var garden := Rect2i(29, 29, 16, 9)  # x 29..44, y 29..37
	b.reserve(Rect2i(garden.position.x - 1, garden.position.y - 1, garden.size.x + 2, garden.size.y + 2))
	b.rect(Rect2i(25, 33, 5, 1), TileKinds.DIRT)  # jalan dari lorong ke gerbang
	b.rect(Rect2i(garden.position.x + 1, 33, garden.size.x - 2, 1), TileKinds.DIRT)  # lorong tengah kebun
	for xx in range(garden.position.x, garden.end.x):
		b.force_object(Vector2i(xx, garden.position.y), "fence_x")
		b.force_object(Vector2i(xx, garden.end.y - 1), "fence_x")
	for yy in range(garden.position.y + 1, garden.end.y - 1):
		if yy != 33:  # gerbang
			b.force_object(Vector2i(garden.position.x, yy), "fence_y")
		b.force_object(Vector2i(garden.end.x - 1, yy), "fence_y")
	var herb_kinds: Array[String] = ["herb_a", "herb_b", "herb_c"]
	for row_y: int in [31, 32, 34, 35]:
		for xx in range(31, 43):
			b.set_kind(Vector2i(xx, row_y), TileKinds.PLOT)
			if (xx + row_y) % 2 == 0:
				b.force_object(Vector2i(xx, row_y), herb_kinds[(xx + row_y) % 3])
	b.add_zone("Kebun Herbal", garden)
	b.force_object(Vector2i(28, 31), "sign")
	b.add_interactable("village_herb_garden", Vector2i(28, 31), "Kebun Herbal")
	b.force_object(Vector2i(27, 35), "well")
	b.add_interactable("village_well", Vector2i(27, 35), "Sumur")
	b.force_object(Vector2i(30, 30), "basket")
	b.force_object(Vector2i(43, 36), "jar")

	# --- Titik tujuan NPC (dicadangkan agar tidak tertutup pohon/benda acak) ---
	var plaza_spots: Array[Vector2i] = [Vector2i(18, 14), Vector2i(20, 16), Vector2i(26, 14), Vector2i(28, 16), Vector2i(19, 17), Vector2i(27, 17)]
	b.add_spot("alun_alun", plaza_spots)
	b.add_spot("klinik_depan", [Vector2i(21, 13), Vector2i(24, 13), Vector2i(22, 14), Vector2i(25, 14)] as Array[Vector2i])
	b.add_spot("jalan_barat", [Vector2i(6, 20), Vector2i(8, 20), Vector2i(12, 20), Vector2i(14, 20)] as Array[Vector2i])
	b.add_spot("jalan_timur", [Vector2i(34, 20), Vector2i(38, 20), Vector2i(41, 20), Vector2i(44, 20)] as Array[Vector2i])
	b.add_spot("jalan_tengah", [Vector2i(20, 20), Vector2i(23, 20), Vector2i(26, 20)] as Array[Vector2i])
	b.add_spot("kebun", [Vector2i(33, 33), Vector2i(36, 33), Vector2i(39, 33), Vector2i(41, 33)] as Array[Vector2i])
	b.add_spot("sumur", [Vector2i(26, 34), Vector2i(28, 34), Vector2i(26, 36), Vector2i(27, 36), Vector2i(28, 36)] as Array[Vector2i])
	b.reserve(Rect2i(25, 34, 4, 3))
	# kolam: jalan setapak dari jalan raya ke tepi selatan kolam
	for yy in range(9, 19):
		b.set_kind(Vector2i(43, yy), TileKinds.DIRT)
		b.reserve(Rect2i(43, yy, 1, 1))
	b.reserve(Rect2i(40, 8, 5, 2))
	b.add_spot("kolam", [Vector2i(41, 9), Vector2i(42, 9), Vector2i(43, 9), Vector2i(44, 9)] as Array[Vector2i])

	# --- Lampu dan dekorasi di sepanjang jalan ---
	for xx in range(3, 46, 6):
		b.try_object(Vector2i(xx, 18), "lantern")
	for xx in range(5, 46, 8):
		b.try_object(Vector2i(xx, 22), "basket")

	# --- Pepohonan tropis ---
	for xx in range(2, 47, 4):
		b.try_object(Vector2i(xx, 23), "palm")
		b.try_object(Vector2i(xx, 17), "palm")
	var tree_kinds: Array[String] = ["palm", "banana", "fruit_tree", "bamboo"]
	# tepi peta
	for i in range(0, WIDTH, 2):
		b.try_object(Vector2i(i, 0), tree_kinds[b.rng.randi() % 4])
		b.try_object(Vector2i(i, HEIGHT - 1), tree_kinds[b.rng.randi() % 4])
	for j in range(0, HEIGHT, 2):
		b.try_object(Vector2i(0, j), tree_kinds[b.rng.randi() % 4])
		b.try_object(Vector2i(WIDTH - 1, j), tree_kinds[b.rng.randi() % 4])
	b.scatter(tree_kinds, 28, Rect2i(1, 1, WIDTH - 2, 10))     # utara, di belakang klinik
	b.scatter(tree_kinds, 18, Rect2i(1, 38 - 8, WIDTH - 2, 7))  # selatan
	b.scatter(["banana", "fruit_tree"] as Array[String], 10, Rect2i(1, 11, WIDTH - 2, 8))
	b.scatter(["bush"] as Array[String], 14, Rect2i(1, 1, WIDTH - 2, HEIGHT - 2))
	b.scatter(["flowers_red", "flowers_yellow", "flowers_white"] as Array[String], 16, Rect2i(1, 1, WIDTH - 2, HEIGHT - 2))
	b.scatter(["grass"] as Array[String], 12, Rect2i(1, 1, WIDTH - 2, HEIGHT - 2))
	b.scatter(["rock"] as Array[String], 8, Rect2i(1, 1, WIDTH - 2, HEIGHT - 2))
	# bunga di halaman rumah
	for pos in [Vector2i(3, 17), Vector2i(8, 17), Vector2i(34, 17), Vector2i(40, 17)]:
		b.try_object(pos, "flowers_red")

	# --- Titik mulai ---
	b.set_spawn("awal", Vector2(23.5, 16.5))
	b.set_spawn("dari_klinik", Vector2(float(door_x) + 1.0, float(mat_y) + 2.5))
	return b.data
