class_name Grade
extends RefCounted
## Tingkat penilaian minigame: S (Sempurna), A (Sangat Bagus), B (Bagus), C (Cukup), D (Gagal).
## Logika murni, dites unit. Nilai 0..100 -> tingkat; tingkat -> kualitas (0..1) dan XP dasar.

enum Level { D, C, B, A, S }

const LETTERS: PackedStringArray = ["D", "C", "B", "A", "S"]
const MIN_SCORE: Array[float] = [0.0, 45.0, 65.0, 80.0, 92.0]
const QUALITY: Array[float] = [0.2, 0.5, 0.7, 0.85, 1.0]
const BASE_XP: Array[int] = [5, 12, 20, 30, 40]


static func from_score(score: float) -> int:
	var g: int = Level.D
	for i in range(MIN_SCORE.size()):
		if score >= MIN_SCORE[i]:
			g = i
	return g


static func letter(g: int) -> String:
	return LETTERS[clampi(g, 0, LETTERS.size() - 1)]


static func quality(g: int) -> float:
	return QUALITY[clampi(g, 0, QUALITY.size() - 1)]


static func base_xp(g: int) -> int:
	return BASE_XP[clampi(g, 0, BASE_XP.size() - 1)]


static func name_key(g: int) -> String:
	return "grade.%s" % letter(g).to_lower()


static func is_pass(g: int) -> bool:
	return g >= Level.C
