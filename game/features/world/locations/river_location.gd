class_name RiverLocation
extends RefCounted
## Sungai (placeholder): sungai vertikal dengan jembatan tanah di tengah. Pintu barat ke desa.
## Tepi seberang (timur) hanya bisa dicapai lewat jembatan.

const WIDTH: int = 28
const HEIGHT: int = 20


static func build() -> LocationData:
	var b := LocationBuilder.new("sungai", "Sungai", WIDTH, HEIGHT, 20261113)
	b.fill(TileKinds.GRASS)
	b.rect(Rect2i(8, 0, 4, HEIGHT), TileKinds.WATER)
	var bridge := Rect2i(8, 9, 4, 2)
	b.rect(bridge, TileKinds.DIRT)
	var entry := Rect2i(0, 9, 8, 2)
	b.rect(entry, TileKinds.DIRT)
	b.reserve(bridge)
	b.reserve(entry)

	var west: Array[Vector2i] = [Vector2i(0, 9), Vector2i(0, 10)]
	for c in west:
		b.set_kind(c, TileKinds.MAT)
		b.reserve(Rect2i(c, Vector2i(1, 1)))
	b.add_transition(west, "desa", "dari_sungai")

	for n in ForageDb.nodes_in("sungai"):
		var c: Vector2i = n["cell"]
		b.reserve(Rect2i(c, Vector2i(1, 1)))
		b.force_object(c, "herb_b")
		b.add_interactable(String(n["id"]), c, "Cari tanaman liar")

	b.reserve(Rect2i(0, 0, 8, HEIGHT))
	b.reserve(Rect2i(12, 0, WIDTH - 12, HEIGHT))
	b.scatter(["palm", "bush", "bamboo"] as Array[String], 8, Rect2i(0, 0, 8, HEIGHT))
	b.scatter(["palm", "bush", "fruit_tree"] as Array[String], 12, Rect2i(12, 0, WIDTH - 12, HEIGHT))
	b.scatter(["flowers_yellow", "grass", "rock"] as Array[String], 10, Rect2i(0, 0, WIDTH, HEIGHT))

	b.add_zone("Sungai", Rect2i(8, 0, 4, HEIGHT))
	b.set_spawn("dari_desa", Vector2(2.5, 10.5))
	return b.data
