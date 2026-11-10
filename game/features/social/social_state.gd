class_name SocialState
extends RefCounted
## Keadaan sosial (Fase 8): kepercayaan tiap penduduk, bab cerita yang sudah didengar, bicara & hadiah harian,
## quest cerita (progres dan pilihan), dan klaim event desa. Logika murni (dites unit): efek ke koin, inventaris,
## dan reputasi dijalankan oleh GameWorld, sama seperti RequestLog. Ikut disimpan lewat SaveSystem.

const NONE: int = 0
const ACTIVE: int = 1
const DONE: int = 2

## npc -> kepercayaan (0..100)
var trust: Dictionary = {}
## "npc:n" -> true (bab n sudah didengar)
var chapters: Dictionary = {}
## npc -> hari terakhir diajak bicara (untuk kepercayaan harian)
var talk_day: Dictionary = {}
## npc -> hari terakhir menerima bahan
var gift_day: Dictionary = {}
## qid -> {"status": int, "progress": Array (int per langkah), "option": String}
var quests: Dictionary = {}
## "<event>:<hari>" -> true (klaim event desa)
var claims: Dictionary = {}
## Permintaan sederhana Fase 4 ikut disimpan di sini (referensi ke RequestLog milik dunia).
var requests: RequestLog = null


func _init(p_requests: RequestLog = null) -> void:
	requests = p_requests


# --- kepercayaan ---------------------------------------------------------------

func trust_of(npc_id: String) -> int:
	return int(trust.get(npc_id, SocialDb.START_TRUST))


## Mengubah kepercayaan (dibatasi 0..100). Mengembalikan selisih yang benar-benar terjadi.
func add_trust(npc_id: String, n: int) -> int:
	if not SocialDb.is_npc(npc_id):
		return 0
	var before: int = trust_of(npc_id)
	trust[npc_id] = clampi(before + n, 0, SocialDb.TRUST_MAX)
	return int(trust[npc_id]) - before


func add_trust_all(n: int) -> void:
	for id in SocialDb.npc_ids():
		add_trust(id, n)


func tier(npc_id: String) -> int:
	return SocialDb.tier_of(trust_of(npc_id))


# --- bicara & bab cerita -------------------------------------------------------

## Bicara sekali per hari menambah kepercayaan kecil. Mengembalikan selisih.
func talk(npc_id: String, day: int) -> int:
	if not SocialDb.is_npc(npc_id) or int(talk_day.get(npc_id, 0)) == day:
		return 0
	talk_day[npc_id] = day
	return add_trust(npc_id, SocialDb.TALK_GAIN)


static func _ckey(npc_id: String, n: int) -> String:
	return "%s:%d" % [npc_id, n]


func chapter_seen(npc_id: String, n: int) -> bool:
	return chapters.has(_ckey(npc_id, n))


## Bab berikutnya yang sudah terbuka (1..N), atau 0. Bab berurutan: bab n baru terbuka setelah bab n-1.
func chapter_due(npc_id: String) -> int:
	if not SocialDb.is_npc(npc_id):
		return 0
	for i in SocialDb.CHAPTER_TRUST.size():
		var n: int = i + 1
		if chapter_seen(npc_id, n):
			continue
		return n if trust_of(npc_id) >= SocialDb.CHAPTER_TRUST[i] else 0
	return 0


func mark_chapter(npc_id: String, n: int) -> bool:
	if chapter_due(npc_id) != n:
		return false
	chapters[_ckey(npc_id, n)] = true
	return true


# --- bahan hadiah -------------------------------------------------------------

func gift_available(npc_id: String, day: int) -> bool:
	return SocialDb.is_npc(npc_id) and int(gift_day.get(npc_id, 0)) != day


## Bahan yang akan diberikan: kesukaan penduduk bila ada, selain itu bahan pertama yang tersedia.
func pick_gift(npc_id: String, available: Array[String]) -> String:
	var liked: String = SocialDb.likes(npc_id)
	if available.has(liked):
		return liked
	return available[0] if not available.is_empty() else ""


## Mencatat pemberian bahan (sekali per hari per penduduk). Mengembalikan selisih kepercayaan.
func record_gift(npc_id: String, day: int, herb: String) -> int:
	if herb == "" or not gift_available(npc_id, day):
		return 0
	gift_day[npc_id] = day
	var gain: int = SocialDb.GIFT_LIKED if herb == SocialDb.likes(npc_id) else SocialDb.GIFT_OTHER
	return add_trust(npc_id, gain)


# --- quest cerita -------------------------------------------------------------

func status(qid: String) -> int:
	if not quests.has(qid):
		return NONE
	return int(quests[qid]["status"])


func _entry(qid: String) -> Dictionary:
	if not quests.has(qid):
		quests[qid] = {"status": NONE, "progress": [], "option": ""}
	return quests[qid]


func progress_of(qid: String, index: int) -> int:
	if status(qid) == NONE:
		return 0
	var prog: Array = _entry(qid)["progress"]
	return int(prog[index]) if index >= 0 and index < prog.size() else 0


func can_offer(qid: String, reputation: float) -> bool:
	var d: Dictionary = SocialDb.quest(qid)
	if d.is_empty() or status(qid) != NONE:
		return false
	return trust_of(String(d["giver"])) >= int(d["min_trust"]) and reputation >= float(d["min_rep"])


func accept(qid: String, reputation: float) -> bool:
	if not can_offer(qid, reputation):
		return false
	var e: Dictionary = _entry(qid)
	e["status"] = ACTIVE
	var prog: Array = []
	for _s in SocialDb.quest_steps(qid):
		prog.append(0)
	e["progress"] = prog
	return true


func is_ready(qid: String) -> bool:
	if status(qid) != ACTIVE:
		return false
	var steps: Array = SocialDb.quest_steps(qid)
	for i in steps.size():
		if progress_of(qid, i) < int(steps[i]["need"]):
			return false
	return true


## Peristiwa dunia (gather/identify/zone/treat). Mengembalikan quest yang baru menjadi siap diserahkan.
func event(kind: String, key: String, n: int = 1) -> Array[String]:
	var newly_ready: Array[String] = []
	for qid in SocialDb.QUEST_ORDER:
		if status(qid) != ACTIVE:
			continue
		var was_ready: bool = is_ready(qid)
		var steps: Array = SocialDb.quest_steps(qid)
		var prog: Array = _entry(qid)["progress"]
		for i in steps.size():
			var s: Dictionary = steps[i]
			if String(s["kind"]) != kind:
				continue
			if String(s["key"]) != SocialDb.ANY and String(s["key"]) != key:
				continue
			prog[i] = mini(int(prog[i]) + n, int(s["need"]))
		if not was_ready and is_ready(qid):
			newly_ready.append(qid)
	return newly_ready


## Serahkan quest ke pemberi dengan pilihan `option`. Mengembalikan hadiah {coin, rep, trust, giver, herb}
## atau {} bila belum siap / pilihan tidak dikenal.
func complete(qid: String, option: String) -> Dictionary:
	if not is_ready(qid):
		return {}
	var d: Dictionary = SocialDb.quest(qid)
	var choices: Dictionary = d["choices"]
	if not choices.has(option):
		return {}
	var c: Dictionary = choices[option]
	var e: Dictionary = _entry(qid)
	e["status"] = DONE
	e["option"] = option
	var giver: String = String(d["giver"])
	return {"coin": int(c["coin"]), "rep": float(c["rep"]), "trust": add_trust(giver, int(c["trust"])),
		"giver": giver, "herb": String(c["herb"]), "qid": qid}


func quests_in_status(s: int) -> Array[String]:
	var out: Array[String] = []
	for qid in SocialDb.QUEST_ORDER:
		if status(qid) == s:
			out.append(qid)
	return out


# --- event desa ---------------------------------------------------------------

func event_claimed(id: String, day: int) -> bool:
	return claims.has(VillageEvents.claim_key(id, day))


func claim_event(id: String, day: int) -> bool:
	if not VillageEvents.is_event(id) or event_claimed(id, day):
		return false
	claims[VillageEvents.claim_key(id, day)] = true
	return true


# --- simpan / muat -----------------------------------------------------------

func to_dict() -> Dictionary:
	var q: Dictionary = {}
	for qid in quests.keys():
		var e: Dictionary = quests[qid]
		q[qid] = {"status": int(e["status"]), "progress": (e["progress"] as Array).duplicate(), "option": String(e["option"])}
	return {
		"trust": trust.duplicate(), "chapters": chapters.duplicate(), "talk_day": talk_day.duplicate(),
		"gift_day": gift_day.duplicate(), "quests": q, "claims": claims.duplicate(),
		"requests": requests.to_dict() if requests != null else {},
	}


## Membaca data (JSON). Nilai tak dikenal dibuang, angka dibatasi; tidak pernah melempar galat.
func from_dict(d: Dictionary) -> void:
	trust = {}
	var t: Variant = d.get("trust", {})
	if t is Dictionary:
		for k in t.keys():
			var id: String = String(k)
			if SocialDb.is_npc(id):
				trust[id] = clampi(int(t[k]), 0, SocialDb.TRUST_MAX)
	chapters = _clean_chapters(d.get("chapters", {}))
	talk_day = _clean_days(d.get("talk_day", {}))
	gift_day = _clean_days(d.get("gift_day", {}))
	quests = _clean_quests(d.get("quests", {}))
	claims = {}
	var c: Variant = d.get("claims", {})
	if c is Dictionary:
		for k in c.keys():
			if VillageEvents.is_claim_key(String(k)):
				claims[String(k)] = true
	if requests != null:
		var r: Variant = d.get("requests", {})
		requests.from_dict(r if r is Dictionary else {})


func _clean_chapters(v: Variant) -> Dictionary:
	var out: Dictionary = {}
	if not (v is Dictionary):
		return out
	for k in v.keys():
		var parts: PackedStringArray = String(k).split(":")
		if parts.size() != 2 or not SocialDb.is_npc(parts[0]) or not parts[1].is_valid_int():
			continue
		var n: int = int(parts[1])
		if n >= 1 and n <= SocialDb.CHAPTER_TRUST.size():
			out[_ckey(parts[0], n)] = true
	return out


func _clean_days(v: Variant) -> Dictionary:
	var out: Dictionary = {}
	if not (v is Dictionary):
		return out
	for k in v.keys():
		if SocialDb.is_npc(String(k)):
			out[String(k)] = maxi(0, int(v[k]))
	return out


func _clean_quests(v: Variant) -> Dictionary:
	var out: Dictionary = {}
	if not (v is Dictionary):
		return out
	for k in v.keys():
		var qid: String = String(k)
		if not SocialDb.has_quest(qid) or not (v[k] is Dictionary):
			continue
		var raw: Dictionary = v[k]
		var s: int = clampi(int(raw.get("status", NONE)), NONE, DONE)
		if s == NONE:
			continue
		var steps: Array = SocialDb.quest_steps(qid)
		var src: Variant = raw.get("progress", [])
		var prog: Array = []
		for i in steps.size():
			var val: int = 0
			if src is Array and i < src.size():
				val = int(src[i])
			prog.append(clampi(val, 0, int(steps[i]["need"])))
		var opt: String = String(raw.get("option", ""))
		if not SocialDb.quest(qid)["choices"].has(opt):
			opt = ""
		out[qid] = {"status": s, "progress": prog, "option": opt}
	return out
