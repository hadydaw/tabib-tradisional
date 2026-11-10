class_name PatientRecord
extends RefCounted
## Satu kunjungan pasien: identitas (NPC), keluhan fiktif, nomor antrean, status, dan data
## diagnosis/perawatan untuk tahap berikutnya.

enum State { MENUJU, MENDAFTAR, MENUNGGU, DIPANGGIL, DIPERIKSA, SELESAI, BATAL }

const STATE_KEYS: PackedStringArray = ["menuju", "mendaftar", "menunggu", "dipanggil", "diperiksa", "selesai", "batal"]

var id: String = ""
var npc_id: String = ""
var complaint_id: String = ""
var ticket: int = 0
var state: int = State.MENUJU
var stage_key: String = ""        # kunci tujuan NPC yang sedang ditunggu kedatangannya
var started_min: float = 0.0       # menit absolut mulai kunjungan
var waiting_since: float = -1.0
var exam_started: float = -1.0
var seat_cell: Vector2i = Vector2i(-1, -1)
var done: bool = false             # sudah kembali ke rumah (kunjungan berakhir)
var diagnosis: DiagnosisRecord = DiagnosisRecord.new()


func state_key() -> String:
	return STATE_KEYS[clampi(state, 0, STATE_KEYS.size() - 1)]


func is_in_line() -> bool:
	return state == State.MENDAFTAR or state == State.MENUNGGU


func is_leaving() -> bool:
	return state == State.SELESAI or state == State.BATAL


func is_active() -> bool:
	return not done
