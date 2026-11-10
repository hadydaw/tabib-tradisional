class_name VillageEvents
extends RefCounted
## Event desa berkala (Fase 8). Jadwal terikat waktu permainan: hari ke-N kelipatan `every` dan jam dalam
## rentang [start, start + length) menit. Peserta: pemain berada di desa saat event berlangsung (sekali per hari).
## Hadiah: koin, reputasi desa, dan/atau kepercayaan semua penduduk. Data murni, dites unit.

const PASAR: String = "pasar_desa"
const BAKTI: String = "malam_bakti"

const EVENTS: Dictionary = {
	"pasar_desa": {"every": 3, "start": 480, "length": 120, "coin": 20, "rep": 1.0, "trust_all": 0},
	"malam_bakti": {"every": 4, "start": 1080, "length": 60, "coin": 0, "rep": 2.0, "trust_all": 3},
}


static func ids() -> Array[String]:
	var out: Array[String] = []
	for k in EVENTS.keys():
		out.append(String(k))
	out.sort()
	return out


static func is_event(id: String) -> bool:
	return EVENTS.has(id)


static func def(id: String) -> Dictionary:
	return EVENTS.get(id, {})


## Event yang sedang berlangsung pada `day` (1-based) dan menit harian `minute` (0..1439).
static func active_at(day: int, minute: int) -> Array[String]:
	var out: Array[String] = []
	for id in ids():
		var d: Dictionary = EVENTS[id]
		var every: int = int(d["every"])
		if every <= 0 or day % every != 0:
			continue
		var start: int = int(d["start"])
		if minute >= start and minute < start + int(d["length"]):
			out.append(id)
	return out


## Kunci klaim sekali per hari: "<id>:<hari>".
static func claim_key(id: String, day: int) -> String:
	return "%s:%d" % [id, day]


static func is_claim_key(key: String) -> bool:
	var parts: PackedStringArray = key.split(":")
	return parts.size() == 2 and is_event(parts[0]) and parts[1].is_valid_int()


## Hari kemunculan berikutnya (>= day) untuk event `id`; bila hari ini masih bisa diikuti (sebelum selesai), hari ini.
static func next_occurrence(id: String, day: int, minute: int) -> int:
	var d: Dictionary = def(id)
	var every: int = int(d.get("every", 0))
	if every <= 0:
		return -1
	if day % every == 0 and minute < int(d["start"]) + int(d["length"]):
		return day
	var nxt: int = day + 1
	while nxt % every != 0:
		nxt += 1
	return nxt


## Event berikutnya dari sekarang: {"id", "day"} (untuk HUD dan tes).
static func soonest(day: int, minute: int) -> Dictionary:
	var best: Dictionary = {}
	for id in ids():
		var d: int = next_occurrence(id, day, minute)
		if best.is_empty() or d < int(best["day"]):
			best = {"id": id, "day": d}
	return best
