class_name ClinicStats
extends RefCounted
## Statistik klinik: uang (pendapatan), reputasi tabib (0..100), jumlah pasien ditangani, kepuasan rata-rata.
## Logika murni, dites unit.

const START_REPUTATION: float = 20.0
signal money_changed(delta: int, reason: String, total: int)

const LEDGER_MAX: int = 40
const REPUTATION_DELTA: Array[float] = [-2.0, 0.0, 1.0, 2.0, 3.0]  # indeks = Grade.Level

var money: int = 0
var reputation: float = START_REPUTATION
var treated: int = 0
var cured: int = 0
var satisfaction_sum: float = 0.0
var last_visit: Dictionary = {}
var ledger: Array[Dictionary] = []   # transaksi terakhir: {delta, reason, total, day}
var total_earned: int = 0
var total_spent: int = 0
var day_now: int = 1                 # diisi dunia agar catatan punya hari
var milestones_done: Array[String] = []


func average_satisfaction() -> float:
	return satisfaction_sum / float(maxi(1, treated))


## Biaya = dasar x (0.4 + 0.8 x kualitas) x (1 + reputasi/250); 0 bila perawatan gagal total (kualitas < 0.15).
static func fee_for(base_fee: int, quality: float, reputation_value: float) -> int:
	if quality < 0.15:
		return 0
	return int(roundf(float(base_fee) * (0.4 + 0.8 * clampf(quality, 0.0, 1.0)) * (1.0 + reputation_value / 250.0)))


## Catat satu kunjungan selesai. `visit` = {fee, grade, satisfaction, outcome}.
func record_visit(visit: Dictionary) -> void:
	add_money(int(visit.get("fee", 0)), "pasien")
	treated += 1
	if String(visit.get("outcome", "")) == "sembuh":
		cured += 1
	satisfaction_sum += float(visit.get("satisfaction", 0.0))
	var g: int = clampi(int(visit.get("grade", 0)), 0, REPUTATION_DELTA.size() - 1)
	reputation = clampf(reputation + REPUTATION_DELTA[g], 0.0, 100.0)
	last_visit = visit.duplicate()


# --- Uang & buku kas ----------------------------------------------------------

## Ubah reputasi desa (Fase 8: quest & event), dibatasi 0..100.
func shift_reputation(delta: float) -> void:
	reputation = clampf(reputation + delta, 0.0, 100.0)


## Tambah uang (delta > 0) dan catat di buku kas. delta 0 diabaikan.
func add_money(amount: int, reason: String) -> void:
	if amount <= 0:
		return
	money += amount
	total_earned += amount
	_log(amount, reason)


## Belanja `cost` koin. False (tanpa efek) bila uang kurang.
func spend(cost: int, reason: String) -> bool:
	if cost < 0 or money < cost:
		return false
	if cost == 0:
		return true
	money -= cost
	total_spent += cost
	_log(-cost, reason)
	return true


## Biaya yang tidak bisa ditolak (operasional): dipotong sebanyak uang yang ada, tidak pernah di bawah 0.
## Mengembalikan jumlah yang benar-benar dipotong.
func charge_up_to(cost: int, reason: String) -> int:
	var c: int = clampi(cost, 0, money)
	if c > 0:
		spend(c, reason)
	return c


func _log(delta: int, reason: String) -> void:
	ledger.append({"delta": delta, "reason": reason, "total": money, "day": day_now})
	while ledger.size() > LEDGER_MAX:
		ledger.pop_front()
	money_changed.emit(delta, reason, money)


## Periksa capaian (EconomyDb.MILESTONES) dan beri hadiah koin. Mengembalikan id capaian yang baru tercapai.
func check_milestones() -> Array[String]:
	var out: Array[String] = []
	for m in EconomyDb.MILESTONES:
		var id: String = String(m["id"])
		if milestones_done.has(id):
			continue
		if EconomyDb.milestone_value(m, self) >= float(m["target"]):
			milestones_done.append(id)
			add_money(int(m["coin"]), "capaian:%s" % id)
			out.append(id)
	return out


# --- Simpan -----------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"money": money, "reputation": reputation, "treated": treated, "cured": cured,
		"satisfaction_sum": satisfaction_sum, "total_earned": total_earned, "total_spent": total_spent,
		"milestones": milestones_done.duplicate(), "ledger": ledger.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	money = maxi(0, int(d.get("money", money)))
	reputation = clampf(float(d.get("reputation", START_REPUTATION)), 0.0, 100.0)
	treated = maxi(0, int(d.get("treated", 0)))
	cured = clampi(int(d.get("cured", 0)), 0, treated)
	satisfaction_sum = maxf(0.0, float(d.get("satisfaction_sum", 0.0)))
	total_earned = maxi(0, int(d.get("total_earned", 0)))
	total_spent = maxi(0, int(d.get("total_spent", 0)))
	milestones_done.clear()
	for m in d.get("milestones", []):
		milestones_done.append(String(m))
	ledger.clear()
	for e in d.get("ledger", []):
		if e is Dictionary:
			ledger.append({"delta": int(e.get("delta", 0)), "reason": String(e.get("reason", "")),
				"total": int(e.get("total", 0)), "day": int(e.get("day", 1))})
	while ledger.size() > LEDGER_MAX:
		ledger.pop_front()
