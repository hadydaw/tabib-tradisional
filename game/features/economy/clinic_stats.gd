class_name ClinicStats
extends RefCounted
## Statistik klinik: uang (pendapatan), reputasi tabib (0..100), jumlah pasien ditangani, kepuasan rata-rata.
## Logika murni, dites unit.

const START_REPUTATION: float = 20.0
const REPUTATION_DELTA: Array[float] = [-2.0, 0.0, 1.0, 2.0, 3.0]  # indeks = Grade.Level

var money: int = 0
var reputation: float = START_REPUTATION
var treated: int = 0
var cured: int = 0
var satisfaction_sum: float = 0.0
var last_visit: Dictionary = {}


func average_satisfaction() -> float:
	return satisfaction_sum / float(maxi(1, treated))


## Biaya = dasar x (0.4 + 0.8 x kualitas) x (1 + reputasi/250); 0 bila perawatan gagal total (kualitas < 0.15).
static func fee_for(base_fee: int, quality: float, reputation_value: float) -> int:
	if quality < 0.15:
		return 0
	return int(roundf(float(base_fee) * (0.4 + 0.8 * clampf(quality, 0.0, 1.0)) * (1.0 + reputation_value / 250.0)))


## Catat satu kunjungan selesai. `visit` = {fee, grade, satisfaction, outcome}.
func record_visit(visit: Dictionary) -> void:
	money += int(visit.get("fee", 0))
	treated += 1
	if String(visit.get("outcome", "")) == "sembuh":
		cured += 1
	satisfaction_sum += float(visit.get("satisfaction", 0.0))
	var g: int = clampi(int(visit.get("grade", 0)), 0, REPUTATION_DELTA.size() - 1)
	reputation = clampf(reputation + REPUTATION_DELTA[g], 0.0, 100.0)
	last_visit = visit.duplicate()
