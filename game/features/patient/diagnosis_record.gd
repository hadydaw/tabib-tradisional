class_name DiagnosisRecord
extends RefCounted
## Struktur data diagnosis (BELUM diisi oleh sistem apa pun di Fase 4). Disiapkan agar tahap
## berikutnya tinggal mengisi: temuan pemeriksaan, diagnosis, dan rencana perawatan.

var patient_id: String = ""
var complaint_id: String = ""
var findings: Array[String] = []     # id temuan pemeriksaan (tahap diagnosis)
var diagnosis_id: String = ""        # id penyakit fiktif; "" = belum didiagnosis
var treatments: Array[TreatmentRecord] = []
var outcome: String = ""             # "", "sembuh", "membaik", "gagal" (tahap berikutnya)


func is_diagnosed() -> bool:
	return diagnosis_id != ""


func to_dict() -> Dictionary:
	var t: Array = []
	for tr in treatments:
		t.append(tr.to_dict())
	return {"patient_id": patient_id, "complaint_id": complaint_id, "findings": findings.duplicate(),
		"diagnosis_id": diagnosis_id, "treatments": t, "outcome": outcome}
