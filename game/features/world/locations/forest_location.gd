class_name ForestLocation
extends RefCounted
## Hutan Nusantara (placeholder): jalur tanah, pepohonan, titik pengumpulan, dan papan Pengembara.
## Pintu timur ke desa (sel 23, y 9..10); pintu utara ke pegunungan (sel x 11..12, y 0).

const WIDTH: int = 24
const HEIGHT: int = 20
const BOARD_CELL: Vector2i = Vector2i(6, 6)


static func build() -> LocationData:
	var b := LocationBuilder.new("hutan", "Hutan", WIDTH, HEIGHT, 20261112)
	b.fill(TileKinds.GRASS)
	var path_h := Rect2i(0, 9, WIDTH, 2)
	var path_v := Rect2i(11, 0, 2, HEIGHT)
	b.rect(path_h, TileKinds.DIRT)
	b.rect(path_v, TileKinds.DIRT)
	b.reserve(path_h)
	b.reserve(path_v)

	var east: Array[Vector2i] = [Vector2i(WIDTH - 1, 9), Vector2i(WIDTH - 1, 10)]
	var north: Array[Vector2i] = [Vector2i(11, 0), Vector2i(12, 0)]
	for c in east:
		b.set_kind(c, TileKinds.MAT)
		b.reserve(Rect2i(c, Vector2i(1, 1)))
	for c in north:
		b.set_kind(c, TileKinds.MAT)
		b.reserve(Rect2i(c, Vector2i(1, 1)))
	b.add_transition(east, "desa", "dari_hutan")
	b.add_transition(north, "pegunungan", "dari_hutan")

	# Titik pengumpulan (dicadangkan agar tidak tertutup pepohonan)
	for n in ForageDb.nodes_in("hutan"):
		var c: Vector2i = n["cell"]
		b.reserve(Rect2i(c, Vector2i(1, 1)))
		b.force_object(c, "herb_c")
		b.add_interactable(String(n["id"]), c, "Cari tanaman liar")
	b.reserve(Rect2i(BOARD_CELL, Vector2i(1, 1)))
	b.force_object(BOARD_CELL, "sign")
	b.add_interactable("adventure_board", BOARD_CELL, "Papan Pengembara")

	b.scatter(["palm", "fruit_tree", "bamboo", "banana"] as Array[String], 22, Rect2i(0, 0, WIDTH, HEIGHT))
	b.scatter(["bush"] as Array[String], 14, Rect2i(0, 0, WIDTH, HEIGHT))
	b.scatter(["rock"] as Array[String], 5, Rect2i(0, 0, WIDTH, HEIGHT))
	b.scatter(["flowers_red", "flowers_white", "grass"] as Array[String], 18, Rect2i(0, 0, WIDTH, HEIGHT))

	b.add_zone("Hutan", Rect2i(0, 0, WIDTH, HEIGHT))
	b.set_spawn("dari_desa", Vector2(21.5, 9.5))
	b.set_spawn("dari_pegunungan", Vector2(11.5, 1.5))
	return b.data
