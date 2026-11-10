class_name SkillDb
extends RefCounted
## Data cabang kemampuan dan efeknya per tingkat (1..MAX_LEVEL). Efek hanya MELONGGARKAN jendela
## ketepatan secara terbatas (maksimum sekitar +30-40%) agar keterampilan manual tetap menentukan.
## Menambah efek: tambahkan kunci di EFFECTS (array sepanjang MAX_LEVEL).

const BRANCHES: Array[String] = ["diagnosis", "akupunktur", "pengetahuan_herbal", "peracikan", "identifikasi_tanaman"]
const MAX_LEVEL: int = 5
## XP minimum untuk mencapai tingkat 1..5.
const LEVEL_XP: Array[int] = [0, 60, 160, 320, 540]

const EFFECTS: Dictionary = {
	"diagnosis": {
		"energi": [4, 4, 5, 5, 6],                 # jumlah pemeriksaan
		"jendela_nadi": [1.0, 1.1, 1.2, 1.3, 1.4], # pengali jendela ketukan nadi
		"tanda_bantu": [0, 1, 1, 1, 1],            # 1 = tabel kandidat menandai temuan cocok/bertentangan
	},
	"akupunktur": {
		"radius": [1.0, 1.08, 1.16, 1.24, 1.32],   # pengali radius titik sasaran
		"getar": [1.0, 0.92, 0.84, 0.76, 0.68],    # pengali getaran jarum
		"kedalaman": [1.0, 1.1, 1.2, 1.3, 1.4],    # pengali lebar zona kedalaman
	},
	"pengetahuan_herbal": {
		"hint_resep": [0, 1, 1, 1, 1],             # 1 = kartu resep menampilkan takaran tiap bahan
	},
	"peracikan": {
		"toleransi_takar": [1.0, 1.1, 1.2, 1.3, 1.4],
		"jendela_tumbuk": [1.0, 1.1, 1.2, 1.3, 1.4],
		"toleransi_aduk": [1.0, 1.1, 1.2, 1.3, 1.4],
	},
	"identifikasi_tanaman": {
		"pilihan": [3, 3, 4, 4, 5],                # jumlah pilihan jawaban
		"mirip": [0, 1, 1, 2, 2],                  # jumlah pengecoh yang mirip
		"tertutup": [0, 0, 1, 1, 2],               # bagian tanaman yang tidak terlihat
	},
}


static func level_for_xp(xp: int) -> int:
	var lvl: int = 1
	for i in range(LEVEL_XP.size()):
		if xp >= LEVEL_XP[i]:
			lvl = i + 1
	return mini(lvl, MAX_LEVEL)


static func effect(branch: String, key: String, level: int) -> float:
	var b: Dictionary = EFFECTS.get(branch, {})
	var arr: Array = b.get(key, [])
	if arr.is_empty():
		return 0.0
	return float(arr[clampi(level, 1, arr.size()) - 1])
