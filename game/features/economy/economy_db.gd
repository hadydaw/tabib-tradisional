class_name EconomyDb
extends RefCounted
## Angka ekonomi klinik (koin fiktif): modal awal, harga bahan, biaya operasional, hadiah capaian.
## Semua angka di satu tempat agar mudah diseimbangkan. Logika murni, dites unit.
##
## Garis besar keseimbangan: satu kunjungan bagus bernilai ~35-60 koin; 5-6 pasien per hari = ~200 koin;
## biaya operasional awal 20 koin/hari; upgrade pertama terjangkau dalam ~1 hari, seluruh upgrade dalam ~2 minggu.

const START_MONEY: int = 100
const BASE_OPERATING_COST: int = 20      # koin per hari
const COST_PER_UPGRADE_LEVEL: int = 5    # tambahan biaya harian per tingkat upgrade
const SELL_RATIO: float = 0.4            # harga jual = harga beli x rasio (selalu lebih murah: tak ada arbitrase)
const LEVEL_UP_COIN: int = 25            # hadiah koin per tingkat skill yang dicapai (x tingkat baru)

## Harga beli bahan di pasar desa (koin per satuan).
const HERB_BUY: Dictionary = {
	"kunyit": 6, "jahe": 7, "temulawak": 9, "kencur": 8, "serai": 5,
	"lengkuas": 6, "sambiloto": 10, "kumis_kucing": 9, "sirih": 6, "kayu_manis": 14,
}

## Capaian sekali-seumur-permainan: id -> {kind, target, coin}. kind: treated | cured | reputation.
const MILESTONES: Array[Dictionary] = [
	{"id": "pasien_1", "kind": "treated", "target": 1, "coin": 20},
	{"id": "sembuh_1", "kind": "cured", "target": 1, "coin": 30},
	{"id": "pasien_10", "kind": "treated", "target": 10, "coin": 80},
	{"id": "reputasi_40", "kind": "reputation", "target": 40, "coin": 100},
	{"id": "pasien_30", "kind": "treated", "target": 30, "coin": 200},
	{"id": "reputasi_70", "kind": "reputation", "target": 70, "coin": 250},
]


static func buy_price(herb_id: String) -> int:
	return int(HERB_BUY.get(herb_id, 0))


static func sell_price(herb_id: String) -> int:
	var b: int = buy_price(herb_id)
	if b <= 0:
		return 0
	return maxi(1, int(floorf(float(b) * SELL_RATIO)))


static func milestone_value(m: Dictionary, stats: ClinicStats) -> float:
	match String(m["kind"]):
		"treated":
			return float(stats.treated)
		"cured":
			return float(stats.cured)
		"reputation":
			return stats.reputation
	return 0.0
