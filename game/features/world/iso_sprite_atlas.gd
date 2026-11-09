class_name IsoSpriteAtlas
extends RefCounted
## Atlas tekstur untuk balok placeholder. Setiap varian tinggi digambar (diraster dengan kode)
## ke satu gambar; semua Sprite2D memakai tekstur yang sama sehingga bisa digabung batch.
## Ini hanya eksperimen biaya: bentuk sama dengan IsoProp, BUKAN aset seni final.

var texture: ImageTexture
var cell_size: Vector2i
var origin: Vector2i  # titik kaki di dalam sel
var variant_count: int = 0


func _init(tile: Vector2, heights: Array[float], footprint: float = IsoMeshes.PROP_FOOTPRINT, color: Color = IsoMeshes.PROP_COLOR) -> void:
	variant_count = heights.size()
	var max_h: float = 0.0
	for h: float in heights:
		max_h = maxf(max_h, h)
	var cw: int = int(ceil(tile.x * footprint)) + 4
	var ch: int = int(ceil(max_h + tile.y * footprint)) + 4
	cell_size = Vector2i(cw, ch)
	origin = Vector2i(cw / 2, ch - int(ceil(tile.y * 0.5 * footprint)) - 2)
	var img := Image.create(cw * variant_count, ch, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for v in range(variant_count):
		_raster_variant(img, v, tile, heights[v], footprint, color)
	texture = ImageTexture.create_from_image(img)


func _raster_variant(img: Image, v: int, tile: Vector2, height: float, footprint: float, color: Color) -> void:
	var faces: Dictionary = IsoMeshes.prop_faces(tile, height, footprint, color)
	var polys: Array[PackedVector2Array] = faces["polys"]
	var colors: PackedColorArray = faces["colors"]
	var base_x: int = v * cell_size.x
	for k in range(polys.size()):
		var poly: PackedVector2Array = polys[k]
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for p: Vector2 in poly:
			lo = lo.min(p)
			hi = hi.max(p)
		var x0: int = maxi(int(floor(lo.x)) + origin.x, 0)
		var x1: int = mini(int(ceil(hi.x)) + origin.x, cell_size.x - 1)
		var y0: int = maxi(int(floor(lo.y)) + origin.y, 0)
		var y1: int = mini(int(ceil(hi.y)) + origin.y, cell_size.y - 1)
		for py in range(y0, y1 + 1):
			for px in range(x0, x1 + 1):
				var local := Vector2(float(px - origin.x) + 0.5, float(py - origin.y) + 0.5)
				if Geometry2D.is_point_in_polygon(local, poly):
					img.set_pixel(base_x + px, py, colors[k])


## Sprite untuk varian v; titik asal node = kaki balok (sama seperti IsoProp).
func make_sprite(v: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture
	s.centered = false
	s.offset = -Vector2(origin)
	s.region_enabled = true
	s.region_rect = Rect2(v * cell_size.x, 0, cell_size.x, cell_size.y)
	return s
