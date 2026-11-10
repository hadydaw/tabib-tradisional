class_name ClinicQueue
extends RefCounted
## Antrean klinik (logika murni, dites unit): nomor antrean, urutan, dan satu ruang periksa.
## Urutan dipanggil = nomor terkecil di antara yang mendaftar; bila yang terdepan belum duduk,
## pemanggilan ditunda sebentar agar urutan tidak dilompati.

var records: Array[PatientRecord] = []
var next_ticket: int = 1


func new_day() -> void:
	next_ticket = 1


func add(p: PatientRecord) -> void:
	records.append(p)


func register(p: PatientRecord) -> int:
	p.ticket = next_ticket
	next_ticket += 1
	p.state = PatientRecord.State.MENDAFTAR
	return p.ticket


func in_line() -> Array[PatientRecord]:
	var out: Array[PatientRecord] = []
	for p in records:
		if not p.done and p.is_in_line():
			out.append(p)
	out.sort_custom(func(a: PatientRecord, b: PatientRecord) -> bool: return a.ticket < b.ticket)
	return out


func waiting_count() -> int:
	return in_line().size()


func exam_patient() -> PatientRecord:
	for p in records:
		if not p.done and (p.state == PatientRecord.State.DIPANGGIL or p.state == PatientRecord.State.DIPERIKSA):
			return p
	return null


func room_busy() -> bool:
	return exam_patient() != null


## Pasien terdepan yang siap dipanggil (sudah duduk/menunggu), atau null.
func peek_next() -> PatientRecord:
	var line: Array[PatientRecord] = in_line()
	if line.is_empty():
		return null
	var first: PatientRecord = line[0]
	if first.state != PatientRecord.State.MENUNGGU:
		return null
	return first


func call_next() -> PatientRecord:
	if room_busy():
		return null
	var p: PatientRecord = peek_next()
	if p == null:
		return null
	p.state = PatientRecord.State.DIPANGGIL
	return p


func for_npc(npc_id: String) -> PatientRecord:
	for p in records:
		if p.npc_id == npc_id and not p.done:
			return p
	return null
