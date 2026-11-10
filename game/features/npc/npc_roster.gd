class_name NpcRoster
extends RefCounted
## Daftar penduduk desa (8 orang) beserta jadwal harian. Semua data sementara dan fiksi.
## Jadwal: tiap entri berlaku sampai entri berikutnya; entri pertama harus start 0 (malam di rumah).
## Titik tujuan ("spot") didefinisikan di data lokasi (VillageLocation / ClinicLocation).

static var _cache: Array[NpcData] = []


static func _e(h: int, m: int, loc: String, spot: String, activity: String, wander: bool = false) -> Dictionary:
	return {"start": h * 60 + m, "loc": loc, "spot": spot, "activity": activity, "wander": wander, "home": activity == "di_rumah"}


static func _home(h: int, m: int, home_spot: String) -> Dictionary:
	return _e(h, m, "desa", home_spot, "di_rumah")


static func _npc(id: String, age: int, home: String, look: Dictionary, sched: Array, req: String = "") -> NpcData:
	var n := NpcData.new()
	n.id = id
	n.age = age
	n.home_spot = home
	n.look = look
	for e: Dictionary in sched:
		n.schedule.append(e)
	n.request_id = req
	return n


static func all() -> Array[NpcData]:
	if not _cache.is_empty():
		return _cache
	_cache = [
		_npc("karto", 52, "rumah_1", {"skin": 2, "hair_style": 1, "hair_color": 4, "top": "top_rompi_cokelat", "bottom": "bottom_celana_cokelat", "head": "head_caping"}, [
			_home(0, 0, "rumah_1"), _e(6, 30, "desa", "kebun", "berkebun", true), _e(11, 30, "desa", "sumur", "mengambil_air"),
			_e(12, 15, "desa", "alun_alun", "bersantai", true), _e(14, 0, "desa", "kebun", "berkebun", true), _home(17, 30, "rumah_1")], "req_salam_wiryo"),
		_npc("sari", 34, "rumah_2", {"skin": 1, "hair_style": 3, "hair_color": 0, "top": "top_polos_biru", "bottom": "bottom_kain_merah", "head": ""}, [
			_home(0, 0, "rumah_2"), _e(7, 30, "desa", "jalan_barat", "berdagang", true), _e(11, 45, "desa", "alun_alun", "berdagang", true),
			_e(15, 30, "desa", "sumur", "mengambil_air"), _e(16, 15, "desa", "jalan_tengah", "berjalan", true), _home(18, 0, "rumah_2")]),
		_npc("wiryo", 71, "rumah_3", {"skin": 2, "hair_style": 0, "hair_color": 5, "top": "top_jubah_tabib", "bottom": "bottom_kain_biru", "head": "head_kain_kepala"}, [
			_home(0, 0, "rumah_3"), _e(7, 0, "desa", "alun_alun", "bersantai", true), _e(11, 0, "desa", "klinik_depan", "berjalan", true),
			_e(12, 0, "desa", "alun_alun", "bersantai", true), _e(16, 30, "desa", "jalan_timur", "berjalan", true), _home(18, 30, "rumah_3")], ""),
		_npc("dewi", 19, "rumah_4", {"skin": 0, "hair_style": 2, "hair_color": 1, "top": "top_polos_hijau", "bottom": "bottom_kain_biru", "head": "head_ikat_kepala"}, [
			_home(0, 0, "rumah_4"), _e(8, 0, "desa", "kolam", "bermain", true), _e(12, 0, "desa", "alun_alun", "bersantai", true),
			_e(15, 0, "desa", "kolam", "bermain", true), _home(18, 0, "rumah_4")], "req_kabar_joko"),
		_npc("joko", 45, "rumah_5", {"skin": 3, "hair_style": 1, "hair_color": 2, "top": "top_polos_biru", "bottom": "bottom_celana_gelap", "head": "head_caping"}, [
			_home(0, 0, "rumah_5"), _e(6, 0, "desa", "kolam", "memancing", true), _e(12, 0, "desa", "sumur", "mengambil_air"),
			_e(13, 0, "desa", "kolam", "memancing", true), _home(17, 0, "rumah_5")]),
		_npc("lastri", 38, "rumah_6", {"skin": 4, "hair_style": 3, "hair_color": 0, "top": "top_polos_hijau", "bottom": "bottom_kain_merah", "head": ""}, [
			_home(0, 0, "rumah_6"), _e(7, 0, "desa", "sumur", "mengambil_air"), _e(8, 0, "desa", "kebun", "berkebun", true),
			_e(13, 0, "desa", "alun_alun", "bersantai", true), _e(16, 0, "desa", "jalan_timur", "berjalan", true), _home(18, 30, "rumah_6")], "req_lihat_kebun"),
		_npc("raka", 22, "rumah_1", {"skin": 1, "hair_style": 1, "hair_color": 1, "top": "top_rompi_cokelat", "bottom": "bottom_celana_gelap", "head": "head_ikat_kepala"}, [
			_home(0, 0, "rumah_1"), _e(8, 30, "desa", "jalan_timur", "berjalan", true), _e(10, 30, "desa", "kebun", "berkebun", true),
			_e(14, 30, "desa", "alun_alun", "bersantai", true), _e(17, 0, "desa", "kolam", "bermain", true), _home(19, 0, "rumah_1")]),
		_npc("ratih", 58, "rumah_2", {"skin": 2, "hair_style": 3, "hair_color": 5, "top": "top_jubah_tabib", "bottom": "bottom_kain_merah", "head": ""}, [
			_home(0, 0, "rumah_2"), _e(7, 0, "desa", "kebun", "berkebun", true), _e(10, 45, "klinik", "tamu", "mengantar_rempah", true),
			_e(11, 45, "desa", "alun_alun", "bersantai", true), _e(15, 0, "desa", "jalan_barat", "berjalan", true), _home(17, 45, "rumah_2")], "req_lihat_resepsi"),
	]
	return _cache


static func by_id(id: String) -> NpcData:
	for n in all():
		if n.id == id:
			return n
	return null


static func ids() -> Array[String]:
	var out: Array[String] = []
	for n in all():
		out.append(n.id)
	return out
