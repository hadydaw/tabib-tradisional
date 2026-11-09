class_name WorldObjectKinds
extends RefCounted
## Jenis objek dunia placeholder (balok berwarna). Semua menghalangi satu sel penuh.
## height_factor = kelipatan tinggi tile; footprint = lebar tapak visual (0..1).

const DEFS: Dictionary = {
	"T": {"name": "pohon", "height_factor": 2.6, "footprint": 0.5, "color": Color("#2f6b3a")},
	"R": {"name": "batu", "height_factor": 0.8, "footprint": 0.75, "color": Color("#7c7c82")},
	"W": {"name": "dinding", "height_factor": 2.0, "footprint": 1.0, "color": Color("#a8764a")},
	"C": {"name": "peti", "height_factor": 0.9, "footprint": 0.6, "color": Color("#c9a14a")},
}


static func has_kind(c: String) -> bool:
	return DEFS.has(c)


## Daftar {"cell": Vector2i, "char": String} dari baris teks objek, plus titik mulai.
static func parse(rows: Array[String]) -> Dictionary:
	var objects: Array[Dictionary] = []
	var spawn := Vector2i(-1, -1)
	for y in range(rows.size()):
		for x in range(rows[y].length()):
			var c: String = rows[y][x]
			if c == "@":
				spawn = Vector2i(x, y)
			elif DEFS.has(c):
				objects.append({"cell": Vector2i(x, y), "char": c})
	return {"objects": objects, "spawn": spawn}
