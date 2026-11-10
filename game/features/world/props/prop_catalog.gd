class_name PropCatalog
extends RefCounted
## Katalog properti dunia placeholder (pohon tropis, tanaman, dekorasi, perabot).
## Semua digambar dengan kode sebagai satu mesh per properti. Ini BUKAN gaya visual final
## (gaya seni masih PENDING, P-04); tiap jenis nanti diganti aset final dengan nama jenis sama.
## Jangkar = tengah sel; semua bentuk berada dalam sel 1x1 (±0.5), kecuali tertulis lain.

## kind -> menghalangi pemain?
const BLOCKS: Dictionary = {
	# pohon dan tumbuhan besar
	"palm": true, "banana": true, "bamboo": true, "fruit_tree": true, "bush": true,
	# tumbuhan rendah (bisa dilewati)
	"flowers_red": false, "flowers_yellow": false, "flowers_white": false, "grass": false,
	"herb_a": false, "herb_b": false, "herb_c": false,
	# dekorasi luar
	"rock": true, "fence_x": true, "fence_y": true, "well": true, "lantern": true,
	"basket": true, "jar": true, "sign": true,
	# perabot interior
	"wall_in": true, "wall_in_win_y": true, "wall_in_win_x": true, "partition": true,
	"counter": true, "mortar_counter": true, "table": true, "table_treat": true,
	"bed_head": true, "bed_foot": true, "stool": true, "bench": true,
	"shelf": true, "rack": true, "pot": true,
}

static var _cache: Dictionary = {}


static func has_kind(kind: String) -> bool:
	return BLOCKS.has(kind)


static func blocks(kind: String) -> bool:
	return BLOCKS.get(kind, true)


static func all_kinds() -> Array:
	return BLOCKS.keys()


## Mesh properti untuk ukuran tile tertentu (di-cache). Null bila jenis tidak dikenal.
static func mesh_for(kind: String, tile: Vector2) -> ArrayMesh:
	if not BLOCKS.has(kind):
		return null
	var key: String = "%s_%d_%d" % [kind, int(tile.x), int(tile.y)]
	if not _cache.has(key):
		_cache[key] = _build(kind, tile)
	return _cache[key]


static func _build(kind: String, tile: Vector2) -> ArrayMesh:
	var b := ShapeBuilder.new(tile)
	var h: float = tile.y  # satuan tinggi: 1 tile.y piksel
	match kind:
		"palm":
			b.add_shadow(-0.3, -0.3, 0.3, 0.3)
			b.add_box(-0.1, -0.1, 0.1, 0.1, 0.0, 3.3 * h, Color("#8a6a43"))
			b.add_box(-0.12, -0.12, 0.12, 0.12, 3.0 * h, 3.3 * h, Color("#6b4f30"))
			b.add_leaf_crown(0.0, 0.0, 3.3 * h, tile.x * 0.5, 8, Color("#2f7d3a"), Color("#3f9a4a"))
			b.add_ellipse(0.04, 0.04, 3.1 * h, 4.0, 3.0, Color("#5a3a20"))
		"banana":
			b.add_shadow(-0.3, -0.3, 0.3, 0.3)
			b.add_box(-0.1, -0.1, 0.1, 0.1, 0.0, 1.1 * h, Color("#6fae4a"))
			b.add_leaf_crown(0.0, 0.0, 1.1 * h, tile.x * 0.42, 6, Color("#4aa14a"), Color("#62bb5a"))
		"bamboo":
			b.add_shadow(-0.4, -0.4, 0.4, 0.4)
			var poles: Array = [[-0.25, -0.1, 3.6], [0.05, 0.2, 3.0], [0.25, -0.2, 3.3]]
			for p: Array in poles:
				var px: float = p[0]
				var py: float = p[1]
				var ph: float = p[2] * h
				b.add_box(px - 0.05, py - 0.05, px + 0.05, py + 0.05, 0.0, ph, Color("#9bbf4a"))
				var band: float = 0.6 * h
				while band < ph:
					b.add_box(px - 0.065, py - 0.065, px + 0.065, py + 0.065, band, band + 0.05 * h, Color("#6f8f30"))
					band += 0.6 * h
				b.add_leaf_crown(px, py, ph, tile.x * 0.2, 4, Color("#6fae4a"), Color("#86c25a"))
		"fruit_tree":
			b.add_shadow(-0.4, -0.4, 0.4, 0.4)
			b.add_box(-0.1, -0.1, 0.1, 0.1, 0.0, 1.3 * h, Color("#7a5535"))
			b.add_ellipse(0.0, 0.0, 1.9 * h, tile.x * 0.48, tile.y * 0.62, Color("#2f6b3a"))
			b.add_ellipse(0.0, 0.0, 2.35 * h, tile.x * 0.36, tile.y * 0.46, Color("#3f8a48"))
			for off: Vector2 in [Vector2(-0.12, 0.1), Vector2(0.15, 0.05), Vector2(0.0, -0.15)]:
				b.add_ellipse(off.x, off.y, 2.1 * h, 3.0, 2.2, Color("#d04a3a"), 8)
		"bush":
			b.add_shadow(-0.35, -0.35, 0.35, 0.35)
			b.add_ellipse(0.0, 0.0, 0.35 * h, tile.x * 0.32, tile.y * 0.4, Color("#3f8a48"))
			b.add_ellipse(0.0, 0.0, 0.6 * h, tile.x * 0.22, tile.y * 0.28, Color("#55a35a"))
		"flowers_red", "flowers_yellow", "flowers_white":
			var petal := Color("#d04a5a")
			if kind == "flowers_yellow":
				petal = Color("#e8c43a")
			elif kind == "flowers_white":
				petal = Color("#f2f0e6")
			for off: Vector2 in [Vector2(-0.25, -0.1), Vector2(0.1, -0.25), Vector2(0.25, 0.1), Vector2(-0.05, 0.2), Vector2(0.0, 0.0)]:
				b.add_ellipse(off.x, off.y, 3.0, 5.0, 2.8, Color("#3f8a48"), 8)
				b.add_ellipse(off.x, off.y, 6.0, 3.0, 2.0, petal, 8)
		"grass":
			for off: Vector2 in [Vector2(-0.2, 0.0), Vector2(0.05, 0.12), Vector2(0.22, -0.1)]:
				var base: Vector2 = b.pt(off.x, off.y)
				b.add_poly(PackedVector2Array([base + Vector2(-3, 0), base + Vector2(3, 0), base + Vector2(0, -9)]), Color("#4f8f45"))
		"herb_a":
			b.add_ellipse(0.0, 0.0, 5.0, 9.0, 5.0, Color("#4aa14a"))
			b.add_ellipse(0.0, 0.0, 11.0, 6.0, 3.5, Color("#62bb5a"))
		"herb_b":
			b.add_ellipse(0.0, 0.0, 4.0, 8.0, 4.5, Color("#4aa14a"))
			b.add_box(-0.03, -0.03, 0.03, 0.03, 0.0, 12.0, Color("#3f8a48"))
			b.add_ellipse(0.0, 0.0, 15.0, 5.0, 3.0, Color("#9a5ab0"), 10)
		"herb_c":
			b.add_ellipse(0.0, 0.0, 4.0, 8.0, 4.5, Color("#4aa14a"))
			b.add_box(-0.03, -0.03, 0.03, 0.03, 0.0, 14.0, Color("#3f8a48"))
			b.add_ellipse(0.0, 0.0, 17.0, 4.5, 3.0, Color("#e0c040"), 10)
		"rock":
			b.add_shadow(-0.4, -0.4, 0.4, 0.4)
			b.add_box(-0.35, -0.3, 0.35, 0.3, 0.0, 0.6 * h, Color("#7c7c82"))
			b.add_box(-0.15, -0.12, 0.2, 0.15, 0.6 * h, 0.9 * h, Color("#8d8d93"))
		"fence_x":
			b.add_box(-0.5, -0.04, -0.4, 0.04, 0.0, 1.0 * h, Color("#a8764a"))
			b.add_box(0.4, -0.04, 0.5, 0.04, 0.0, 1.0 * h, Color("#a8764a"))
			b.add_box(-0.4, -0.025, 0.4, 0.025, 0.35 * h, 0.45 * h, Color("#b88556"))
			b.add_box(-0.4, -0.025, 0.4, 0.025, 0.7 * h, 0.8 * h, Color("#b88556"))
		"fence_y":
			b.add_box(-0.04, -0.5, 0.04, -0.4, 0.0, 1.0 * h, Color("#a8764a"))
			b.add_box(-0.04, 0.4, 0.04, 0.5, 0.0, 1.0 * h, Color("#a8764a"))
			b.add_box(-0.025, -0.4, 0.025, 0.4, 0.35 * h, 0.45 * h, Color("#b88556"))
			b.add_box(-0.025, -0.4, 0.025, 0.4, 0.7 * h, 0.8 * h, Color("#b88556"))
		"well":
			b.add_shadow(-0.45, -0.45, 0.45, 0.45)
			b.add_box(-0.38, -0.38, 0.38, 0.38, 0.0, 0.6 * h, Color("#8d8d93"))
			b.add_poly(PackedVector2Array([b.pt(-0.26, -0.26, 0.6 * h + 0.5), b.pt(0.26, -0.26, 0.6 * h + 0.5), b.pt(0.26, 0.26, 0.6 * h + 0.5), b.pt(-0.26, 0.26, 0.6 * h + 0.5)]), Color("#1c2a33"))
			b.add_box(-0.4, -0.04, -0.32, 0.04, 0.6 * h, 2.0 * h, Color("#6b4a30"))
			b.add_box(0.32, -0.04, 0.4, 0.04, 0.6 * h, 2.0 * h, Color("#6b4a30"))
			b.add_hip_roof(-0.5, -0.25, 0.5, 0.25, 2.0 * h, 0.55 * h, Color("#8a5a3a"))
		"lantern":
			b.add_shadow(-0.2, -0.2, 0.2, 0.2)
			b.add_box(-0.05, -0.05, 0.05, 0.05, 0.0, 2.2 * h, Color("#4a3a30"))
			b.add_box(-0.12, -0.12, 0.12, 0.12, 2.2 * h, 2.6 * h, Color("#ffd88a"))
		"basket":
			b.add_shadow(-0.3, -0.3, 0.3, 0.3)
			b.add_box(-0.2, -0.2, 0.2, 0.2, 0.0, 0.5 * h, Color("#c9a14a"))
		"jar":
			b.add_shadow(-0.3, -0.3, 0.3, 0.3)
			b.add_box(-0.22, -0.22, 0.22, 0.22, 0.0, 0.9 * h, Color("#9a5a3a"))
			b.add_box(-0.12, -0.12, 0.12, 0.12, 0.9 * h, 1.1 * h, Color("#7a4228"))
		"sign":
			b.add_shadow(-0.35, -0.2, 0.35, 0.2)
			b.add_box(-0.05, -0.05, 0.05, 0.05, 0.0, 1.2 * h, Color("#6b4a30"))
			b.add_box(-0.42, -0.04, 0.42, 0.04, 0.8 * h, 1.45 * h, Color("#d9b97a"))
			b.add_face_y(0.04, -0.3, 0.3, 1.2 * h, 1.3 * h, Color("#5a3a20"))
			b.add_face_y(0.04, -0.2, 0.2, 0.95 * h, 1.05 * h, Color("#5a3a20"))
		"wall_in", "wall_in_win_y", "wall_in_win_x":
			b.add_box(-0.5, -0.5, 0.5, 0.5, 0.0, 2.8 * h, Color("#d8c9a8"))
			if kind == "wall_in_win_y":
				b.add_face_y(0.5, -0.3, 0.3, 1.1 * h, 2.2 * h, Color("#6b4a30"))
				b.add_face_y(0.5, -0.24, 0.24, 1.2 * h, 2.1 * h, Color("#9ad0e8"))
			elif kind == "wall_in_win_x":
				b.add_face_x(0.5, -0.3, 0.3, 1.1 * h, 2.2 * h, Color("#6b4a30"))
				b.add_face_x(0.5, -0.24, 0.24, 1.2 * h, 2.1 * h, Color("#9ad0e8"))
		"partition":
			b.add_box(-0.5, -0.5, 0.5, 0.5, 0.0, 2.0 * h, Color("#c9b48c"))
		"counter":
			b.add_box(-0.5, -0.5, 0.5, 0.5, 0.0, 0.95 * h, Color("#a67c52"))
			b.add_face_y(0.5, -0.4, 0.4, 0.15 * h, 0.35 * h, Color("#8a6a45"))
		"mortar_counter":
			b.add_box(-0.5, -0.5, 0.5, 0.5, 0.0, 0.95 * h, Color("#a67c52"))
			b.add_box(-0.16, -0.16, 0.16, 0.16, 0.95 * h, 1.2 * h, Color("#5c5c62"))
			b.add_box(0.12, 0.12, 0.18, 0.18, 0.95 * h, 1.55 * h, Color("#c9b48c"))
		"table":
			b.add_shadow(-0.45, -0.45, 0.45, 0.45)
			for sx: float in [-0.4, 0.34]:
				for sy: float in [-0.4, 0.34]:
					b.add_box(sx, sy, sx + 0.06, sy + 0.06, 0.0, 0.75 * h, Color("#6b4a30"))
			b.add_box(-0.45, -0.45, 0.45, 0.45, 0.75 * h, 0.9 * h, Color("#a67c52"))
		"table_treat":
			b.add_shadow(-0.45, -0.45, 0.45, 0.45)
			for sx: float in [-0.4, 0.34]:
				for sy: float in [-0.4, 0.34]:
					b.add_box(sx, sy, sx + 0.06, sy + 0.06, 0.0, 0.75 * h, Color("#6b4a30"))
			b.add_box(-0.45, -0.45, 0.45, 0.45, 0.75 * h, 0.9 * h, Color("#a67c52"))
			b.add_box(-0.3, -0.3, 0.15, 0.3, 0.9 * h, 0.93 * h, Color("#f2f0e6"))
			b.add_box(0.2, -0.2, 0.32, -0.05, 0.9 * h, 1.05 * h, Color("#5c7aa0"))
			b.add_box(0.2, 0.05, 0.3, 0.15, 0.9 * h, 1.0 * h, Color("#c25a3a"))
		"bed_head":
			b.add_shadow(-0.5, -0.5, 0.5, 0.5)
			b.add_box(-0.5, -0.47, 0.5, 0.47, 0.0, 0.5 * h, Color("#8a6a45"))
			b.add_box(-0.46, -0.43, 0.5, 0.43, 0.5 * h, 0.65 * h, Color("#d8e0e8"))
			b.add_box(-0.4, -0.3, -0.12, 0.3, 0.65 * h, 0.8 * h, Color("#f2f0e6"))
		"bed_foot":
			b.add_shadow(-0.5, -0.5, 0.5, 0.5)
			b.add_box(-0.5, -0.47, 0.5, 0.47, 0.0, 0.5 * h, Color("#8a6a45"))
			b.add_box(-0.5, -0.43, 0.46, 0.43, 0.5 * h, 0.68 * h, Color("#7aa08a"))
		"stool":
			b.add_shadow(-0.25, -0.25, 0.25, 0.25)
			b.add_box(-0.18, -0.18, 0.18, 0.18, 0.0, 0.45 * h, Color("#a67c52"))
		"bench":
			b.add_shadow(-0.5, -0.3, 0.5, 0.3)
			b.add_box(-0.5, -0.25, -0.4, -0.15, 0.0, 0.35 * h, Color("#6b4a30"))
			b.add_box(0.4, -0.25, 0.5, -0.15, 0.0, 0.35 * h, Color("#6b4a30"))
			b.add_box(-0.5, -0.25, 0.5, 0.25, 0.35 * h, 0.45 * h, Color("#a67c52"))
		"shelf":
			b.add_box(-0.5, -0.5, 0.5, -0.1, 0.0, 2.4 * h, Color("#7a5535"))
			var jar_colors: Array = [Color("#9a5ab0"), Color("#4aa14a"), Color("#e0c040"), Color("#c25a3a")]
			var row: int = 0
			for zr: float in [0.25, 0.9, 1.55]:
				for i in range(4):
					var jx: float = -0.42 + 0.22 * float(i)
					b.add_face_y(-0.1, jx, jx + 0.16, zr * h, (zr + 0.4) * h, jar_colors[(i + row) % 4])
				row += 1
		"rack":
			b.add_shadow(-0.45, -0.3, 0.45, 0.3)
			for sx: float in [-0.42, 0.36]:
				b.add_box(sx, -0.2, sx + 0.06, -0.14, 0.0, 1.8 * h, Color("#6b4a30"))
				b.add_box(sx, 0.14, sx + 0.06, 0.2, 0.0, 1.8 * h, Color("#6b4a30"))
			b.add_box(-0.42, -0.2, 0.42, -0.14, 1.2 * h, 1.28 * h, Color("#8a6a45"))
			b.add_box(-0.42, 0.14, 0.42, 0.2, 1.2 * h, 1.28 * h, Color("#8a6a45"))
			var bundle: Array = [Color("#4aa14a"), Color("#8a8a3a"), Color("#6fae4a")]
			for i in range(3):
				var bx: float = -0.3 + 0.28 * float(i)
				b.add_box(bx, -0.12, bx + 0.12, 0.12, 0.7 * h, 1.2 * h, bundle[i])
		"pot":
			b.add_shadow(-0.3, -0.3, 0.3, 0.3)
			b.add_box(-0.18, -0.18, 0.18, 0.18, 0.0, 0.5 * h, Color("#9a5a3a"))
			b.add_leaf_crown(0.0, 0.0, 0.5 * h, tile.x * 0.2, 5, Color("#4aa14a"), Color("#62bb5a"))
	return b.build()
