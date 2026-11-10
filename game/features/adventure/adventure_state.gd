class_name AdventureState
extends RefCounted
## Keadaan petualangan (Fase 7): stamina, cooldown titik pengumpulan, penghitung (kunjungan, pengumpulan,
## identifikasi baru, celah rahasia), misi yang sudah diklaim. Logika murni, dites unit.
## Stamina pulih seiring waktu permainan (REGEN_PER_MINUTE); aktivitas memakai stamina. Tidak pernah
## menghalangi berjalan: hanya aktivitas yang butuh stamina ditunda sampai pulih.

signal changed

const MAX_STAMINA: float = 100.0
const REGEN_PER_MINUTE: float = 0.1     # penuh dalam ~1000 menit (sekitar 17 menit nyata)
const COST_GATHER: float = 8.0          # bahan yang sudah dikenal
const COST_IDENTIFY: float = 12.0       # tanaman baru (minigame identifikasi)
const COST_SECRET: float = 10.0
const VISIT_BONUS: int = 15             # koin untuk kunjungan pertama ke area
const SECRET_ID: String = "celah_batu"
const SECRET_HERB: String = "kayu_manis"
const SECRET_UNITS: int = 2
const SECRET_COIN: int = 40

var stamina: float = MAX_STAMINA
var last_tick: float = 0.0
var forage_last: Dictionary = {}     # id titik -> menit absolut terakhir dikumpulkan
var counters: Dictionary = {}        # kunci -> jumlah
var claimed: Array[String] = []      # id misi yang sudah diklaim
var secrets: Array[String] = []      # rahasia yang sudah dibuka


## Pulihkan stamina sampai waktu absolut `abs_minutes` (menit sejak hari 1 pukul 00:00).
func sync(abs_minutes: float) -> void:
	if abs_minutes > last_tick:
		stamina = minf(MAX_STAMINA, stamina + (abs_minutes - last_tick) * REGEN_PER_MINUTE)
		changed.emit()
	last_tick = maxf(last_tick, abs_minutes)


func can_spend(cost: float) -> bool:
	return stamina + 0.0001 >= cost


func spend(cost: float) -> bool:
	if not can_spend(cost):
		return false
	stamina = maxf(0.0, stamina - cost)
	changed.emit()
	return true


func refund(cost: float) -> void:
	stamina = minf(MAX_STAMINA, stamina + cost)
	changed.emit()


func node_ready(node_id: String, abs_minutes: float) -> bool:
	return not forage_last.has(node_id) or abs_minutes - float(forage_last[node_id]) >= ForageDb.REGEN_MINUTES


func mark_forage(node_id: String, abs_minutes: float) -> void:
	forage_last[node_id] = abs_minutes


func bump(key: String, n: int = 1) -> void:
	counters[key] = count(key) + n
	changed.emit()


func count(key: String) -> int:
	return int(counters.get(key, 0))


## Kunjungan pertama ke area: true (dan dihitung). Kunjungan berikutnya: false.
func visit(area: String) -> bool:
	var key: String = "visit:%s" % area
	if count(key) > 0:
		return false
	bump(key)
	return true


func has_secret(id: String) -> bool:
	return secrets.has(id)


func reveal_secret(id: String) -> bool:
	if secrets.has(id):
		return false
	secrets.append(id)
	bump("secret")
	return true


## Kemajuan misi: nilai terkecil dari semua kunci, dibatasi `goal.n`.
func mission_progress(m: Dictionary) -> int:
	var n: int = MissionDb.goal_n(m)
	var low: int = n
	for k in MissionDb.goal_keys(m):
		low = mini(low, mini(count(String(k)), n))
	return low


func mission_done(m: Dictionary) -> bool:
	return mission_progress(m) >= MissionDb.goal_n(m)


func active_mission() -> Dictionary:
	for m in MissionDb.all():
		if not claimed.has(String(m["id"])):
			return m
	return {}


## Klaim hadiah misi aktif yang sudah selesai. {id, coin} bila berhasil; kosong bila belum.
func claim() -> Dictionary:
	var m: Dictionary = active_mission()
	if m.is_empty() or not mission_done(m):
		return {}
	claimed.append(String(m["id"]))
	changed.emit()
	return {"id": String(m["id"]), "coin": int(m["coin"])}


func to_dict() -> Dictionary:
	return {"stamina": stamina, "last_tick": last_tick, "forage_last": forage_last.duplicate(),
		"counters": counters.duplicate(), "claimed": claimed.duplicate(), "secrets": secrets.duplicate()}


func from_dict(d: Dictionary) -> void:
	stamina = clampf(float(d.get("stamina", MAX_STAMINA)), 0.0, MAX_STAMINA)
	last_tick = maxf(0.0, float(d.get("last_tick", 0.0)))
	forage_last.clear()
	var fl: Variant = d.get("forage_last", {})
	if fl is Dictionary:
		for k in fl.keys():
			if ForageDb.has(String(k)):
				forage_last[String(k)] = maxf(0.0, float(fl[k]))
	counters.clear()
	var cn: Variant = d.get("counters", {})
	if cn is Dictionary:
		for k in cn.keys():
			counters[String(k)] = maxi(0, int(cn[k]))
	claimed.clear()
	var cl: Variant = d.get("claimed", [])
	if cl is Array:
		for m in cl:
			if m is String and not claimed.has(m):
				claimed.append(m)
	secrets.clear()
	var sc: Variant = d.get("secrets", [])
	if sc is Array:
		for s in sc:
			if s is String and not secrets.has(s):
				secrets.append(s)
	changed.emit()
