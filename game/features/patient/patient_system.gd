class_name PatientSystem
extends RefCounted
## Sistem pasien: penduduk datang ke klinik, mendaftar, duduk menunggu di area penerimaan,
## dipanggil ke ruang periksa, lalu pulang. BELUM ada diagnosis/perawatan (hanya struktur data).
## Logika murni di atas NpcSimulation (dites unit). Pemanggilan dan penyelesaian pemeriksaan bisa
## dilakukan pemain (meja penerimaan / tempat periksa) atau otomatis sebagai pengganti sementara:
## `auto_call` memanggil pasien terdepan setelah AUTO_CALL_DELAY_MIN menit permainan, dan pemeriksaan
## selesai otomatis setelah AUTO_EXAM_MIN menit (nanti digantikan tahap diagnosis).

signal patient_event(kind: String, patient: PatientRecord)

const OPEN_MIN: int = 8 * 60
const CLOSE_MIN: int = 16 * 60
const FIRST_ARRIVAL_MIN: int = 8 * 60 + 15
const LAST_ARRIVAL_MIN: int = 15 * 60
const PATIENCE_MIN: float = 120.0
const VISIT_TIMEOUT_MIN: float = 180.0
const AUTO_CALL_DELAY_MIN: float = 12.0
const AUTO_EXAM_MIN: float = 25.0
const RECEPTION_SPOT: String = "antre_resepsi"
const STANDING_SPOT: String = "berdiri_tunggu"

var sim: NpcSimulation
var clock: GameClock
var queue: ClinicQueue = ClinicQueue.new()
var auto_call: bool = true
var completed_count: int = 0
var gave_up_count: int = 0

var _plan: Array[Dictionary] = []
var _planned_day: int = 0
var _claimed: Dictionary = {}   # sel kursi -> id pasien
var _counter: int = 0


func setup(p_sim: NpcSimulation, p_clock: GameClock) -> void:
	sim = p_sim
	clock = p_clock
	sim.agent_arrived.connect(_on_agent_arrived)


func is_open() -> bool:
	var m: int = clock.minute()
	return m >= OPEN_MIN and m < CLOSE_MIN


func now() -> float:
	return clock.absolute_minutes()


func patient_for(npc_id: String) -> PatientRecord:
	return queue.for_npc(npc_id)


# --- Rencana harian ----------------------------------------------------------

static func plan_for_day(day: int, npc_ids: Array[String]) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 7919 + 13
	var ids: Array[String] = npc_ids.duplicate()
	for i in range(ids.size() - 1, 0, -1):  # kocok deterministik
		var j: int = rng.randi_range(0, i)
		var tmp: String = ids[i]
		ids[i] = ids[j]
		ids[j] = tmp
	var count: int = mini(3 + day % 3, ids.size())
	var out: Array[Dictionary] = []
	var minute: int = FIRST_ARRIVAL_MIN + rng.randi_range(0, 15)
	for k in range(count):
		if minute > LAST_ARRIVAL_MIN:
			break
		out.append({
			"npc": ids[k], "minute": minute, "started": false,
			"complaint": ComplaintCatalog.IDS[rng.randi() % ComplaintCatalog.IDS.size()],
		})
		minute += rng.randi_range(30, 75)
	return out


func planned() -> Array[Dictionary]:
	return _plan


# --- Pembaruan ---------------------------------------------------------------

func update(_delta: float) -> void:
	if clock.day != _planned_day:
		_planned_day = clock.day
		_plan = plan_for_day(clock.day, NpcRoster.ids())
		queue.new_day()
	var m: int = clock.minute()
	var t: float = now()
	for e in _plan:
		if not e["started"] and m >= int(e["minute"]) and m < CLOSE_MIN - 30:
			e["started"] = true
			if queue.for_npc(String(e["npc"])) == null:
				start_visit(String(e["npc"]), String(e["complaint"]))
	for p in queue.records:
		if p.done:
			continue
		match p.state:
			PatientRecord.State.MENUJU:
				if t - p.started_min > VISIT_TIMEOUT_MIN or m >= CLOSE_MIN:
					_leave(p, "batal")
			PatientRecord.State.MENDAFTAR, PatientRecord.State.MENUNGGU:
				if m >= CLOSE_MIN or (p.waiting_since >= 0.0 and t - p.waiting_since > PATIENCE_MIN) \
						or t - p.started_min > VISIT_TIMEOUT_MIN:
					_leave(p, "batal")
			PatientRecord.State.DIPERIKSA:
				if auto_call and t - p.exam_started >= AUTO_EXAM_MIN:
					finish_exam()
			PatientRecord.State.DIPANGGIL:
				if t - p.started_min > VISIT_TIMEOUT_MIN + 60.0:
					_leave(p, "batal")
			_:
				pass
	_promote_standing()
	if auto_call and is_open() and not queue.room_busy():
		var nxt: PatientRecord = queue.peek_next()
		if nxt != null and nxt.waiting_since >= 0.0 and t - nxt.waiting_since >= AUTO_CALL_DELAY_MIN:
			call_next()


# --- Alur pasien -------------------------------------------------------------

## Mulai kunjungan satu penduduk. Mengembalikan catatan pasien, atau null bila sudah menjadi pasien.
func start_visit(npc_id: String, complaint_id: String) -> PatientRecord:
	if sim.agent(npc_id) == null or queue.for_npc(npc_id) != null:
		return null
	_counter += 1
	var p := PatientRecord.new()
	p.id = "pasien_%d" % _counter
	p.npc_id = npc_id
	p.complaint_id = complaint_id
	p.diagnosis.patient_id = p.id
	p.diagnosis.complaint_id = complaint_id
	p.started_min = now()
	p.state = PatientRecord.State.MENUJU
	var goal: Dictionary = NpcGoal.at_spot("klinik", RECEPTION_SPOT, "berobat")
	p.stage_key = goal["key"]
	queue.add(p)
	sim.set_override(npc_id, goal)
	patient_event.emit("arrived", p)
	return p


func _on_agent_arrived(agent_id: String, goal_key: String) -> void:
	var p: PatientRecord = queue.for_npc(agent_id)
	if p == null or p.stage_key != goal_key:
		return
	match p.state:
		PatientRecord.State.MENUJU:
			queue.register(p)
			p.waiting_since = now()
			var seat: Dictionary = _free_waiting_seat()
			var goal: Dictionary
			if seat.is_empty():
				goal = NpcGoal.at_spot("klinik", STANDING_SPOT, "menunggu_giliran")
			else:
				p.seat_cell = seat["cell"]
				_claimed[p.seat_cell] = p.id
				goal = NpcGoal.at_cell("klinik", p.seat_cell, true, "menunggu_giliran")
			p.stage_key = goal["key"]
			sim.set_override(p.npc_id, goal)
			patient_event.emit("registered", p)
		PatientRecord.State.MENDAFTAR:
			p.state = PatientRecord.State.MENUNGGU
			p.stage_key = ""
			patient_event.emit("seated", p)
		PatientRecord.State.DIPANGGIL:
			p.state = PatientRecord.State.DIPERIKSA
			p.exam_started = now()
			p.stage_key = ""
			patient_event.emit("exam_started", p)
		PatientRecord.State.SELESAI, PatientRecord.State.BATAL:
			p.done = true
			p.stage_key = ""
			sim.clear_override(p.npc_id)
			if p.state == PatientRecord.State.SELESAI:
				completed_count += 1
			patient_event.emit("left", p)
		_:
			pass


## Panggil pasien terdepan ke ruang periksa. Null bila tidak ada/ruang terisi.
func call_next() -> PatientRecord:
	var p: PatientRecord = queue.call_next()
	if p == null:
		return null
	_release_seat(p)
	var exam: Array[Dictionary] = LocationRegistry.get_location("klinik").seats_of_kind("periksa")
	var cell: Vector2i = exam[0]["cell"]
	p.seat_cell = cell
	_claimed[cell] = p.id
	var goal: Dictionary = NpcGoal.at_cell("klinik", cell, true, "diperiksa")
	p.stage_key = goal["key"]
	sim.set_override(p.npc_id, goal)
	patient_event.emit("called", p)
	return p


## Akhiri pemeriksaan pasien di ruang periksa (placeholder; belum ada diagnosis). Pasien pulang.
func finish_exam() -> PatientRecord:
	var p: PatientRecord = queue.exam_patient()
	if p == null or p.state != PatientRecord.State.DIPERIKSA:
		return null
	_leave(p, "selesai")
	patient_event.emit("exam_done", p)
	return p


func _leave(p: PatientRecord, outcome: String) -> void:
	_release_seat(p)
	p.state = PatientRecord.State.SELESAI if outcome == "selesai" else PatientRecord.State.BATAL
	if p.state == PatientRecord.State.BATAL:
		gave_up_count += 1
		patient_event.emit("gave_up", p)
	var npc: NpcData = NpcRoster.by_id(p.npc_id)
	var goal: Dictionary = NpcGoal.go_home(npc.home_spot)
	p.stage_key = goal["key"]
	sim.set_override(p.npc_id, goal)


func _release_seat(p: PatientRecord) -> void:
	if p.seat_cell.x >= 0 and _claimed.get(p.seat_cell, "") == p.id:
		_claimed.erase(p.seat_cell)
	p.seat_cell = Vector2i(-1, -1)


func _free_waiting_seat() -> Dictionary:
	for st in LocationRegistry.get_location("klinik").seats_of_kind("tunggu"):
		var c: Vector2i = st["cell"]
		if not _claimed.has(c) and not sim.occupied_cells("klinik").has(c):
			return st
	return {}


## Pasien yang berdiri (tidak dapat kursi) pindah ke kursi kosong, urut nomor antrean.
func _promote_standing() -> void:
	for p in queue.in_line():
		if p.seat_cell.x >= 0 or p.state != PatientRecord.State.MENUNGGU:
			continue
		var seat: Dictionary = _free_waiting_seat()
		if seat.is_empty():
			return
		p.seat_cell = seat["cell"]
		_claimed[p.seat_cell] = p.id
		p.state = PatientRecord.State.MENDAFTAR  # berjalan ke kursi, lalu kembali menunggu
		var goal: Dictionary = NpcGoal.at_cell("klinik", p.seat_cell, true, "menunggu_giliran")
		p.stage_key = goal["key"]
		sim.set_override(p.npc_id, goal)


func status_summary() -> Dictionary:
	return {"waiting": queue.waiting_count(), "room_busy": queue.room_busy(), "open": is_open()}
