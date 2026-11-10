class_name MinigameResult
extends RefCounted
## Hasil satu minigame: skor 0..100, tingkat S..D, komponen penilaian (0..1), jumlah kesalahan, durasi,
## XP yang diberikan, dan rincian khusus minigame. `kind`: "diagnosis", "akupunktur", "peracikan", "identifikasi".

var kind: String = ""
var subject_id: String = ""
var score: float = 0.0
var grade: int = Grade.Level.D
var components: Dictionary = {}
var errors: int = 0
var duration: float = 0.0
var xp: int = 0
var difficulty: int = 1
var details: Dictionary = {}


func letter() -> String:
	return Grade.letter(grade)


func quality() -> float:
	return Grade.quality(grade)


func to_dict() -> Dictionary:
	return {"kind": kind, "subject_id": subject_id, "score": snappedf(score, 0.1), "grade": letter(),
		"components": components.duplicate(), "errors": errors, "duration": snappedf(duration, 0.1),
		"xp": xp, "difficulty": difficulty, "details": details.duplicate()}
