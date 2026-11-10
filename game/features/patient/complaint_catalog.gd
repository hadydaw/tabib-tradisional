class_name ComplaintCatalog
extends RefCounted
## Keluhan pasien (fiksi, ringan). Teks lewat localization `complaint.<id>`.
## `ailment_hint` = tempat menyiapkan id penyakit fiktif untuk tahap diagnosis (kosong sekarang).

const IDS: Array[String] = [
	"demam_dingin", "pusing_berputar", "perut_kembung", "batuk_kering",
	"sendi_kaku", "gatal_kulit", "lelah_berat", "mata_perih",
]


static func has(id: String) -> bool:
	return IDS.has(id)


static func ailment_hint(_id: String) -> String:
	return ""
