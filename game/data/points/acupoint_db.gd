class_name AcupointDb
extends RefCounted
## Titik akupunktur FIKTIF. Hanya aturan gameplay (bukan panduan pengobatan nyata).
## pos = posisi relatif pada ilustrasi tubuh depan (0..1; x ke kanan, y ke bawah),
## region = bagian tubuh, tag = fungsi fiktif (unik per titik agar petunjuk tidak ambigu).
## Menambah titik: tambahkan entri DATA + id di IDS + teks `point.<id>` dan `tag.<tag>` di localization.

const IDS: Array[String] = [
	"ubun_embun", "alis_pagi", "pelipis_angin", "leher_kendi", "bahu_batu",
	"dada_telaga", "pusar_bulan", "pergelangan_nadi", "lutut_batu", "telapak_akar",
]

const DATA: Dictionary = {
	"ubun_embun": {"pos": Vector2(0.50, 0.040), "region": "kepala", "tag": "tenang"},
	"alis_pagi": {"pos": Vector2(0.50, 0.118), "region": "kepala", "tag": "segar"},
	"pelipis_angin": {"pos": Vector2(0.64, 0.095), "region": "kepala", "tag": "sejuk"},
	"leher_kendi": {"pos": Vector2(0.50, 0.205), "region": "leher", "tag": "lancar"},
	"bahu_batu": {"pos": Vector2(0.74, 0.255), "region": "bahu", "tag": "longgar"},
	"dada_telaga": {"pos": Vector2(0.50, 0.330), "region": "dada", "tag": "lapang"},
	"pusar_bulan": {"pos": Vector2(0.50, 0.500), "region": "perut", "tag": "hangat"},
	"pergelangan_nadi": {"pos": Vector2(0.86, 0.520), "region": "lengan", "tag": "selaras"},
	"lutut_batu": {"pos": Vector2(0.60, 0.760), "region": "tungkai", "tag": "kuat"},
	"telapak_akar": {"pos": Vector2(0.60, 0.960), "region": "tungkai", "tag": "menurun"},
}


static func has(id: String) -> bool:
	return DATA.has(id)


static func pos(id: String) -> Vector2:
	var d: Dictionary = DATA.get(id, {})
	return d.get("pos", Vector2(0.5, 0.5))


static func tag(id: String) -> String:
	var d: Dictionary = DATA.get(id, {})
	return String(d.get("tag", ""))


static func region(id: String) -> String:
	var d: Dictionary = DATA.get(id, {})
	return String(d.get("region", ""))
