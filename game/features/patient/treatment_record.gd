class_name TreatmentRecord
extends RefCounted
## Struktur data satu perawatan (belum dipakai). `kind` nanti: "herbal" atau "akupunktur" (fiktif).

var id: String = ""
var kind: String = ""
var item_ids: Array[String] = []
var status: String = "belum"  # "belum", "berjalan", "selesai"


func to_dict() -> Dictionary:
	return {"id": id, "kind": kind, "item_ids": item_ids.duplicate(), "status": status}
