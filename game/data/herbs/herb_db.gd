class_name HerbDb
extends RefCounted
## Tanaman obat/bahan herbal terinspirasi Nusantara. Id tanaman = id bahan hasil panennya.
## Ciri pengamatan (4 bagian) dipakai minigame identifikasi dan digambar prosedural (placeholder).
## Menambah tanaman: tambahkan entri DATA + id di IDS + teks `herb.<id>` dan `trait.<bagian>.<kunci>` di localization.

const PARTS: Array[String] = ["daun", "bunga", "akar", "buah"]

const IDS: Array[String] = [
	"kunyit", "jahe", "temulawak", "kencur", "serai",
	"lengkuas", "sambiloto", "kumis_kucing", "sirih", "kayu_manis",
]

## Kunci ciri per bagian (teks `trait.<bagian>.<kunci>`; gambar prosedural di PlantArt).
const TRAITS: Dictionary = {
	"daun": ["lebar_lanset", "lanset_sempit", "pita_panjang", "membulat_pendek", "hati_mengkilap", "bergerigi", "lanset_kecil", "tiga_tulang"],
	"bunga": ["putih_kuning", "merah_kerucut", "ungu_kerucut", "putih_ungu_kecil", "kumis_panjang", "tak_mencolok", "bulir_hijau", "kuning_pucat"],
	"akar": ["rimpang_jingga", "rimpang_krem", "rimpang_kuning_besar", "rimpang_kecil", "serabut_rumpun", "rimpang_merah", "serabut_halus", "kulit_batang"],
	"buah": ["polong_kecil", "bulat_kecil", "tak_tampak", "buni_merah"],
}

const DATA: Dictionary = {
	"kunyit": {"daun": "lebar_lanset", "bunga": "putih_kuning", "akar": "rimpang_jingga", "buah": "tak_tampak"},
	"jahe": {"daun": "lanset_sempit", "bunga": "merah_kerucut", "akar": "rimpang_krem", "buah": "tak_tampak"},
	"temulawak": {"daun": "lebar_lanset", "bunga": "ungu_kerucut", "akar": "rimpang_kuning_besar", "buah": "tak_tampak"},
	"kencur": {"daun": "membulat_pendek", "bunga": "putih_ungu_kecil", "akar": "rimpang_kecil", "buah": "tak_tampak"},
	"serai": {"daun": "pita_panjang", "bunga": "tak_mencolok", "akar": "serabut_rumpun", "buah": "tak_tampak"},
	"lengkuas": {"daun": "lanset_sempit", "bunga": "putih_kuning", "akar": "rimpang_merah", "buah": "bulat_kecil"},
	"sambiloto": {"daun": "lanset_kecil", "bunga": "putih_ungu_kecil", "akar": "serabut_halus", "buah": "polong_kecil"},
	"kumis_kucing": {"daun": "bergerigi", "bunga": "kumis_panjang", "akar": "serabut_halus", "buah": "polong_kecil"},
	"sirih": {"daun": "hati_mengkilap", "bunga": "bulir_hijau", "akar": "serabut_halus", "buah": "tak_tampak"},
	"kayu_manis": {"daun": "tiga_tulang", "bunga": "kuning_pucat", "akar": "kulit_batang", "buah": "buni_merah"},
}

## Bahan awal (jumlah di inventaris pada mulai permainan).
const STARTER_STOCK: Dictionary = {
	"kunyit": 4, "jahe": 3, "serai": 3, "temulawak": 3, "sambiloto": 2,
	"kumis_kucing": 3, "kencur": 3, "kayu_manis": 2, "sirih": 3, "lengkuas": 2,
}


static func has(id: String) -> bool:
	return DATA.has(id)


static func trait_of(id: String, part: String) -> String:
	var d: Dictionary = DATA.get(id, {})
	return String(d.get(part, ""))


## Berapa ciri (dari bagian `parts`) yang sama antara dua tanaman.
static func shared_traits(a: String, b: String, parts: Array = PARTS) -> int:
	var n: int = 0
	for part in parts:
		if trait_of(a, String(part)) == trait_of(b, String(part)):
			n += 1
	return n


## Apakah `id` dapat dibedakan dari semua tanaman lain di `options` hanya dengan bagian `parts`.
static func is_unique_among(id: String, options: Array, parts: Array) -> bool:
	for o in options:
		var other: String = String(o)
		if other == id:
			continue
		if shared_traits(id, other, parts) == parts.size():
			return false
	return true
