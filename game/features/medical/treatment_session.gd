class_name TreatmentSession
extends RefCounted
## Keadaan alur pengobatan satu pasien: penyakit sebenarnya, diagnosis pemain, metode terpilih, hasil tiap
## minigame, dan ringkasan akhir. Dikelola TreatmentManager.

enum Stage { DIAGNOSIS, METODE, AKUPUNKTUR, RAMUAN, HASIL, SELESAI }

const STAGE_KEYS: PackedStringArray = ["diagnosis", "metode", "akupunktur", "ramuan", "hasil", "selesai"]

var patient_id: String = ""
var true_ailment: String = ""
var diagnosed_id: String = ""
var stage: int = Stage.DIAGNOSIS
var methods: Array[String] = []        # metode dipilih: "akupunktur", "herbal"
var done_methods: Array[String] = []
var recipe_id: String = ""
var results: Dictionary = {}           # jenis minigame -> MinigameResult
var summary: Dictionary = {}
var diagnosis_attempts: int = 0


func stage_key() -> String:
	return STAGE_KEYS[clampi(stage, 0, STAGE_KEYS.size() - 1)]


func pending_methods() -> Array[String]:
	var out: Array[String] = []
	for m in methods:
		if not done_methods.has(m):
			out.append(m)
	return out
