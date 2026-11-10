class_name GuaLocation
extends RefCounted
## Gua Kapur (Fase 9): dibuka setelah eksplorasi cukup (lihat FrontierState.gua_unlocked). Aula masuk berisi
## Tablet Batu dan Tuas. Tablet membuka pintu ke ruang dalam (titik langka dan lorong). Tuas membuka celah ke
## ceruk tempat Peti Gua. Pintu barat kembali ke Pegunungan.

const WIDTH: int = 24
const HEIGHT: int = 16
## Sel pintu yang disegel oleh tablet_gua (dinding antara aula dan ruang dalam).
const DOOR: Rect2i = Rect2i(10, 8, 1, 6)
## Sel celah yang disegel oleh tuas_gua (jalan ke ceruk peti).
const CRACK: Rect2i = Rect2i(6, 5, 2, 1)
const TABLET_CELL: Vector2i = Vector2i(9, 9)
const LEVER_CELL: Vector2i = Vector2i(2, 7)
const CHEST_CELL: Vector2i = Vector2i(8, 2)


static func _in_rooms(c: Vector2i, rooms: Array[Rect2i]) -> bool:
	for r in rooms:
		if r.has_point(c):
			return true
	return false


static func build() -> LocationData:
	var b := LocationBuilder.new("gua", "Gua Kapur", WIDTH, HEIGHT, 20261116)
	b.fill(TileKinds.STONE)
	b.rect(Rect2i(0, 6, 10, 8), TileKinds.DIRT)
	b.rect(Rect2i(11, 6, 12, 8), TileKinds.DIRT)
	b.rect(Rect2i(5, 1, 5, 4), TileKinds.DIRT)
	b.rect(DOOR, TileKinds.DIRT)
	b.rect(CRACK, TileKinds.DIRT)
	b.reserve(Rect2i(0, 9, 11, 3))
	b.reserve(DOOR)
	b.reserve(CRACK)
	# Batu padat: setiap sel di luar ruangan menjadi objek penghalang (dinding ikut terbentuk).
	var rooms: Array[Rect2i] = [Rect2i(0, 6, 10, 8), Rect2i(11, 6, 12, 8), Rect2i(5, 1, 5, 4), DOOR, CRACK]
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var c := Vector2i(x, y)
			if not _in_rooms(c, rooms):
				b.force_object(c, "rock")

	var west: Array[Vector2i] = [Vector2i(0, 10), Vector2i(0, 11)]
	for c in west:
		b.set_kind(c, TileKinds.MAT)
		b.reserve(Rect2i(c, Vector2i(1, 1)))
	b.add_transition(west, "pegunungan", "dari_gua")

	# Tablet dan tuas (teka-teki): batu yang bisa diperiksa.
	b.force_object(TABLET_CELL, "rock")
	b.add_interactable(RareDb.TABLET_ID, TABLET_CELL, "Baca tablet batu")
	b.force_object(LEVER_CELL, "rock")
	b.add_interactable(RareDb.LEVER_ID, LEVER_CELL, "Tarik tuas batu")

	# Peti di ceruk (terbuka setelah celah dibuka).
	b.add_interactable(RareDb.CHEST_ID, CHEST_CELL, "Buka peti")

	# Titik penemuan langka: satu di aula, satu di ruang dalam.
	for n in RareDb.nodes_in("gua"):
		var c: Vector2i = RareDb.node(n)["cell"]
		b.reserve(Rect2i(c, Vector2i(1, 1)))
		b.force_object(c, "herb_a")
		b.add_interactable(n, c, "Periksa jamur gua")

	b.scatter(["rock"] as Array[String], 8, Rect2i(0, 6, 10, 8))
	b.scatter(["rock"] as Array[String], 10, Rect2i(11, 6, 12, 8))
	b.add_zone("Gua Kapur", Rect2i(0, 0, WIDTH, HEIGHT))
	b.set_spawn("dari_pegunungan", Vector2(1.5, 10.5))
	b.set_spawn("dari_desa", Vector2(1.5, 10.5))
	return b.data
