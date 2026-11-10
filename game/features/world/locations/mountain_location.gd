class_name MountainLocation
extends RefCounted
## Pegunungan (placeholder): tanah batu dengan jalur silang, petak rumput, dan celah batu rahasia
## di timur laut. Pintu selatan kembali ke hutan.

const WIDTH: int = 24
const HEIGHT: int = 22
const SECRET_CELL: Vector2i = Vector2i(20, 2)


static func build() -> LocationData:
	var b := LocationBuilder.new("pegunungan", "Pegunungan", WIDTH, HEIGHT, 20261114)
	b.fill(TileKinds.STONE)
	var path_v := Rect2i(11, 0, 2, HEIGHT)
	var path_h := Rect2i(0, 10, WIDTH, 2)
	b.rect(path_v, TileKinds.DIRT)
	b.rect(path_h, TileKinds.DIRT)
	b.reserve(path_v)
	b.reserve(path_h)
	for patch in [Rect2i(3, 5, 5, 4), Rect2i(14, 3, 5, 4), Rect2i(13, 13, 5, 4)]:
		b.rect(patch, TileKinds.GRASS)

	var south: Array[Vector2i] = [Vector2i(11, HEIGHT - 1), Vector2i(12, HEIGHT - 1)]
	for c in south:
		b.set_kind(c, TileKinds.MAT)
		b.reserve(Rect2i(c, Vector2i(1, 1)))
	b.add_transition(south, "hutan", "dari_pegunungan")

	for n in ForageDb.nodes_in("pegunungan"):
		var c: Vector2i = n["cell"]
		b.reserve(Rect2i(c, Vector2i(1, 1)))
		b.force_object(c, "herb_a")
		b.add_interactable(String(n["id"]), c, "Cari tanaman liar")

	# Celah rahasia: dikelilingi semak agar terlihat seperti celah sempit
	b.reserve(Rect2i(18, 0, 6, 5))
	b.force_object(Vector2i(19, 2), "bush")
	b.force_object(Vector2i(21, 2), "bush")
	b.add_interactable("secret_cleft", SECRET_CELL, "Tanda di celah")

	b.scatter(["rock"] as Array[String], 16, Rect2i(0, 0, WIDTH, HEIGHT))
	b.scatter(["bush"] as Array[String], 8, Rect2i(0, 0, WIDTH, HEIGHT))
	b.scatter(["palm", "bamboo"] as Array[String], 4, Rect2i(0, 0, WIDTH, HEIGHT))

	b.add_zone("Pegunungan", Rect2i(0, 0, WIDTH, HEIGHT))
	b.set_spawn("dari_hutan", Vector2(11.5, HEIGHT - 2.5))
	b.set_spawn("dari_desa", Vector2(11.5, HEIGHT - 2.5))
	return b.data
