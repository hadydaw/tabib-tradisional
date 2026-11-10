class_name RawaLocation
extends RefCounted
## Rawa (Fase 9): kolam dan rumpun basah di barat, dengan titik penemuan langka. Di tengah ada Kabut
## yang menutup rawa dalam sampai teka-teki Penjaga Rawa dipecahkan. Pintu barat kembali ke Sungai.

const WIDTH: int = 26
const HEIGHT: int = 18
## Sel kabut (tertutup sampai teka-teki penjaga_rawa selesai).
const FOG: Rect2i = Rect2i(16, 0, 2, 18)
const GUARD_CELL: Vector2i = Vector2i(15, 9)


static func build() -> LocationData:
	var b := LocationBuilder.new("rawa", "Rawa", WIDTH, HEIGHT, 20261115)
	b.fill(TileKinds.GRASS)
	b.rect(Rect2i(2, 12, 4, 3), TileKinds.WATER)
	b.rect(Rect2i(12, 2, 3, 3), TileKinds.WATER)
	b.rect(Rect2i(20, 12, 4, 3), TileKinds.WATER)
	b.rect(Rect2i(0, 9, WIDTH, 2), TileKinds.DIRT)
	b.reserve(Rect2i(0, 9, WIDTH, 2))

	var west: Array[Vector2i] = [Vector2i(0, 9), Vector2i(0, 10)]
	for c in west:
		b.set_kind(c, TileKinds.MAT)
		b.reserve(Rect2i(c, Vector2i(1, 1)))
	b.add_transition(west, "sungai", "dari_rawa")

	# Titik penemuan langka (pohon basah di tepi jalan), tidak tumpang tindih dengan air.
	for n in RareDb.nodes_in("rawa"):
		var c: Vector2i = RareDb.node(n)["cell"]
		b.reserve(Rect2i(c, Vector2i(1, 1)))
		b.force_object(c, "herb_b")
		b.add_interactable(n, c, "Periksa rumpun basah")

	# Penjaga Rawa: batu bertulis di depan kabut.
	b.reserve(Rect2i(GUARD_CELL, Vector2i(1, 1)))
	b.force_object(GUARD_CELL, "rock")
	b.add_interactable(RareDb.RIDDLE_ID, GUARD_CELL, "Baca batu penjaga")

	b.scatter(["bush", "bamboo", "palm"] as Array[String], 10, Rect2i(0, 0, 15, HEIGHT))
	b.scatter(["bush", "palm", "rock"] as Array[String], 10, Rect2i(18, 0, WIDTH - 18, HEIGHT))
	b.scatter(["flowers_yellow", "grass", "rock"] as Array[String], 10, Rect2i(0, 0, WIDTH, HEIGHT))

	b.add_zone("Rawa", Rect2i(0, 0, WIDTH, HEIGHT))
	b.set_spawn("dari_sungai", Vector2(1.5, 10.5))
	b.set_spawn("dari_desa", Vector2(1.5, 10.5))
	return b.data
