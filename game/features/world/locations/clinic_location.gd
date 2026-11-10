class_name ClinicLocation
extends RefCounted
## Interior Klinik Tabib (placeholder, tampilan irisan tanpa dinding depan agar isi terlihat).
## Zona: Penerimaan (depan), Pemeriksaan (belakang kiri), Peracikan (belakang kanan).
## Hanya lingkungan dan struktur interaksi; sistem pengobatan belum dibuat (di luar Fase 3).

const WIDTH: int = 16
const HEIGHT: int = 12


static func build() -> LocationData:
	var b := LocationBuilder.new("klinik", "Klinik Tabib", WIDTH, HEIGHT, 20261111)
	b.fill(TileKinds.WOOD)
	b.rect(Rect2i(11, 1, 4, 5), TileKinds.WOOD_DARK)  # area peracikan

	# Dinding belakang (baris y = 0 dan kolom x = 0); dinding depan sengaja tidak ada.
	for x in range(0, WIDTH):
		b.force_object(Vector2i(x, 0), "wall_in_win_y" if x in [3, 7, 11] else "wall_in")
	for y in range(1, HEIGHT):
		b.force_object(Vector2i(0, y), "wall_in_win_x" if y in [3, 8] else "wall_in")

	# Sekat: pemeriksaan | peracikan (x = 10, celah y 3..4) dan penerimaan | belakang (y = 6, celah x 5..6)
	for y in [1, 2, 5]:
		b.force_object(Vector2i(10, y), "partition")
	for x in [1, 2, 3, 4, 7, 8, 9, 10]:
		b.force_object(Vector2i(x, 6), "partition")

	# Ruang pemeriksaan
	b.force_object(Vector2i(2, 2), "bed_head")
	b.force_object(Vector2i(3, 2), "bed_foot")
	b.force_object(Vector2i(3, 3), "stool")
	b.force_object(Vector2i(8, 2), "table_treat")
	b.force_object(Vector2i(8, 3), "table")
	b.force_object(Vector2i(9, 1), "pot")
	b.force_object(Vector2i(1, 5), "jar")
	b.add_interactable("clinic_exam_bed", Vector2i(3, 2), "Tempat Periksa")
	b.add_interactable("clinic_treatment_table", Vector2i(8, 2), "Meja Pengobatan")

	# Area peracikan
	for x in range(11, 15):
		b.force_object(Vector2i(x, 1), "shelf")
	b.force_object(Vector2i(12, 3), "mortar_counter")
	b.force_object(Vector2i(13, 3), "counter")
	b.force_object(Vector2i(14, 4), "rack")
	b.force_object(Vector2i(14, 2), "jar")
	b.force_object(Vector2i(11, 5), "basket")
	b.force_object(Vector2i(11, 4), "stool")
	b.add_interactable("clinic_herb_shelf", Vector2i(12, 1), "Rak Herbal")
	b.add_interactable("clinic_compounding", Vector2i(12, 3), "Meja Peracikan")

	# Area penerimaan
	for x in range(3, 7):
		b.force_object(Vector2i(x, 8), "counter")
	for x in range(11, 14):
		b.force_object(Vector2i(x, 9), "bench")
	b.force_object(Vector2i(1, 10), "pot")
	b.force_object(Vector2i(14, 7), "pot")
	b.force_object(Vector2i(2, 7), "jar")
	b.add_interactable("clinic_reception", Vector2i(4, 8), "Meja Penerimaan")

	# Keset keluar (baris depan)
	b.set_kind(Vector2i(7, HEIGHT - 1), TileKinds.MAT)
	b.set_kind(Vector2i(8, HEIGHT - 1), TileKinds.MAT)
	var exit_cells: Array[Vector2i] = [Vector2i(7, HEIGHT - 1), Vector2i(8, HEIGHT - 1)]
	b.add_transition(exit_cells, "desa", "dari_klinik")

	b.add_zone("Ruang Pemeriksaan", Rect2i(1, 1, 9, 5))
	b.add_zone("Area Peracikan", Rect2i(11, 1, 4, 5))
	b.add_zone("Area Penerimaan", Rect2i(1, 7, 14, 5))
	b.set_spawn("dari_desa", Vector2(8.0, 9.5))
	return b.data
