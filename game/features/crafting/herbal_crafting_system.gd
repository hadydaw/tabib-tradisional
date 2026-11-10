class_name HerbalCraftingSystem
extends RefCounted
## Logika minigame peracikan herbal (murni, dites unit). Tahap: PILIH (ambil bahan dari inventaris, jumlah
## potong, urutan) -> TAKAR (menakar gram tiap bahan) -> TUMBUK (ritme mortar-alu) -> ADUK (gerak melingkar)
## -> SELESAI. Kesalahan jumlah/urutan/takaran memengaruhi kualitas ramuan. Bahan diambil langsung dari
## HerbInventory (dikembalikan bila sesi dibatalkan).

enum Stage { PILIH, TAKAR, TUMBUK, ADUK, SELESAI }

const WEIGHTS: Dictionary = {"komposisi": 0.25, "urutan": 0.15, "takaran": 0.20, "tumbuk": 0.15, "aduk": 0.10, "kesalahan": 0.10, "waktu": 0.05}
const POUND_PERFECT: float = 0.09
const POUND_GOOD: float = 0.22
const POUND_LEAD: float = 1.0
var tolerance_mult: float = 1.0   # dari upgrade Lumpang Batu
const MEASURE_TOLERANCE: float = 0.06    # galat relatif yang dinilai sempurna
const MEASURE_MAX_ERR: float = 0.40      # galat relatif skor 0
const FILL_RATE: float = 14.0            # gram per detik saat menuang
const STIR_MIN_SPEED: float = 1.0        # rad/detik
const STIR_MAX_SPEED: float = 4.2

var recipe_id: String = ""
var steps: Array[Dictionary] = []
var inventory: HerbInventory
var herbal_level: int = 1
var craft_level: int = 1
var stage: int = Stage.PILIH
var picks: Array[String] = []          # satu entri per potong yang diambil, berurutan
var errors: int = 0
var elapsed: float = 0.0
var result: MinigameResult = null

# TAKAR
var measure_index: int = 0
var measure_scores: Array[float] = []
var measure_errors: Array[float] = []
# TUMBUK
var pound_beats: Array[float] = []
var pound_taps: Array[float] = []
var pound_time: float = 0.0
var pound_result: Dictionary = {}
# ADUK
var stir_target: float = 0.0
var stir_progress: float = 0.0
var stir_good_time: float = 0.0
var stir_total_time: float = 0.0
var stir_dir_match: float = 0.0
var stir_dir_total: float = 0.0
var stir_dir: int = 0
var stir_score: float = 0.0


func setup(p_recipe_id: String, p_inventory: HerbInventory, p_herbal_level: int, p_craft_level: int) -> bool:
	if not RecipeDb.has(p_recipe_id):
		return false
	recipe_id = p_recipe_id
	steps = RecipeDb.steps(p_recipe_id)
	inventory = p_inventory
	herbal_level = clampi(p_herbal_level, 1, SkillDb.MAX_LEVEL)
	craft_level = clampi(p_craft_level, 1, SkillDb.MAX_LEVEL)
	var d: Dictionary = RecipeDb.get_data(p_recipe_id)
	var gap: float = float(d["pound_gap"])
	var n: int = int(d["pound_beats"])
	pound_beats.clear()
	for i in range(n):
		pound_beats.append(POUND_LEAD + gap * float(i))
	stir_target = float(d["stir_turns"]) * TAU
	return true


func update(delta: float) -> void:
	if stage != Stage.SELESAI:
		elapsed += delta


func recipe_difficulty() -> int:
	return RecipeDb.difficulty(recipe_id)


func shows_amounts() -> bool:
	return SkillDb.effect("pengetahuan_herbal", "hint_resep", herbal_level) >= 1.0


# --- PILIH ------------------------------------------------------------------

func count_picked(herb_id: String) -> int:
	var n: int = 0
	for h in picks:
		if h == herb_id:
			n += 1
	return n


## Ambil satu potong `herb_id` dari inventaris. Bahan di luar resep atau melebihi jumlah resep = kesalahan
## (bahan tetap terpakai). False bila stok kosong atau bukan tahap PILIH.
func take_herb(herb_id: String) -> bool:
	if stage != Stage.PILIH or not inventory.has(herb_id, 1):
		return false
	inventory.remove(herb_id, 1)
	picks.append(herb_id)
	if count_picked(herb_id) > required_units(herb_id):
		errors += 1
	return true


## Urungkan potong terakhir (dikembalikan ke inventaris; kesalahannya dihapus).
func undo_pick() -> bool:
	if stage != Stage.PILIH or picks.is_empty():
		return false
	var last: String = picks[picks.size() - 1]
	if count_picked(last) > required_units(last):
		errors = maxi(0, errors - 1)
	picks.remove_at(picks.size() - 1)
	inventory.add(last, 1)
	return true


func required_units(herb_id: String) -> int:
	for s in steps:
		if String(s["herb"]) == herb_id:
			return int(s["units"])
	return 0


## Kemampuan memenuhi resep dari inventaris saat ini: {herb: kekurangan}.
func shortages() -> Dictionary:
	var out: Dictionary = {}
	for s in steps:
		var need: int = int(s["units"]) - count_picked(String(s["herb"]))
		var have: int = inventory.count(String(s["herb"]))
		if need > have:
			out[String(s["herb"])] = need - have
	return out


func composition_score() -> float:
	var req_total: int = 0
	var diff: int = 0
	for s in steps:
		var want: int = int(s["units"])
		req_total += want
		diff += absi(want - count_picked(String(s["herb"])))
	for h in picks:
		if required_units(h) == 0:
			diff += 1
	return clampf(1.0 - float(diff) / float(maxi(1, req_total)), 0.0, 1.0)


## Urutan bahan sesuai resep (berdasarkan kemunculan pertama tiap bahan yang dipilih).
func order_score() -> float:
	var first: Array = []
	for h in picks:
		if not first.has(h):
			first.append(h)
	return ScoringSystem.order_factor(RecipeDb.herb_order(recipe_id), first)


func confirm_picks() -> bool:
	if stage != Stage.PILIH or picks.is_empty():
		return false
	stage = Stage.TAKAR
	measure_index = 0
	measure_scores.clear()
	measure_errors.clear()
	return true


# --- TAKAR ------------------------------------------------------------------

func measure_target() -> float:
	if measure_index >= steps.size():
		return 0.0
	return float(steps[measure_index]["grams"])


func measure_herb() -> String:
	if measure_index >= steps.size():
		return ""
	return String(steps[measure_index]["herb"])


func measure_tolerance() -> float:
	return MEASURE_TOLERANCE * SkillDb.effect("peracikan", "toleransi_takar", craft_level) * tolerance_mult


## Skor takaran untuk `grams`; menyimpannya dan maju ke bahan berikutnya (atau ke TUMBUK).
func submit_measure(grams: float) -> Dictionary:
	if stage != Stage.TAKAR:
		return {"ok": false}
	var target: float = measure_target()
	var rel: float = absf(grams - target) / maxf(0.001, target)
	var tol: float = measure_tolerance()
	var s: float = 1.0
	if rel > tol:
		s = clampf(1.0 - (rel - tol) / (MEASURE_MAX_ERR - tol), 0.0, 1.0)
	# Bahan yang tidak diambil sama sekali tidak bisa ditakar dengan benar.
	if count_picked(measure_herb()) == 0:
		s = 0.0
	measure_scores.append(s)
	measure_errors.append(rel)
	var rec: Dictionary = {"ok": true, "herb": measure_herb(), "target": target, "grams": grams, "score": s}
	measure_index += 1
	if measure_index >= steps.size():
		stage = Stage.TUMBUK
		pound_time = 0.0
		pound_taps.clear()
		rec["next"] = "tumbuk"
	return rec


func measure_average() -> float:
	if measure_scores.is_empty():
		return 0.0
	var t: float = 0.0
	for s in measure_scores:
		t += s
	return t / float(steps.size())


# --- TUMBUK -----------------------------------------------------------------

func pound_window_scale() -> float:
	return SkillDb.effect("peracikan", "jendela_tumbuk", craft_level)


func pound_duration() -> float:
	return float(pound_beats[pound_beats.size() - 1]) + POUND_GOOD + 0.5


func pound_tap(t: float) -> void:
	if stage == Stage.TUMBUK:
		pound_taps.append(t)


func finish_pound() -> Dictionary:
	if stage != Stage.TUMBUK:
		return pound_result
	var w: float = pound_window_scale()
	pound_result = RhythmJudge.judge(pound_beats, pound_taps, POUND_PERFECT * w, POUND_GOOD * w)
	stage = Stage.ADUK
	stir_progress = 0.0
	return pound_result


# --- ADUK -------------------------------------------------------------------

func stir_speed_band() -> Vector2:
	var s: float = SkillDb.effect("peracikan", "toleransi_aduk", craft_level)
	return Vector2(STIR_MIN_SPEED / s, STIR_MAX_SPEED * s)


## Umpan gerakan melingkar: `angle_delta` radian (+ searah jarum jam) selama `dt` detik.
func stir_move(angle_delta: float, dt: float) -> void:
	if stage != Stage.ADUK or dt <= 0.0 or absf(angle_delta) < 0.0005:
		return
	var dir: int = 1 if angle_delta > 0.0 else -1
	if stir_dir == 0:
		stir_dir = dir
	var speed: float = absf(angle_delta) / dt
	var band: Vector2 = stir_speed_band()
	stir_total_time += dt
	if speed >= band.x and speed <= band.y:
		stir_good_time += dt
	stir_dir_total += absf(angle_delta)
	if dir == stir_dir:
		stir_dir_match += absf(angle_delta)
		stir_progress += absf(angle_delta)
	if stir_progress >= stir_target:
		_finish_stir()


func stir_fraction() -> float:
	return clampf(stir_progress / maxf(0.001, stir_target), 0.0, 1.0)


func _finish_stir() -> void:
	var smooth: float = stir_good_time / maxf(0.001, stir_total_time)
	var consistent: float = stir_dir_match / maxf(0.001, stir_dir_total)
	stir_score = clampf(0.55 * smooth + 0.45 * consistent, 0.0, 1.0)
	_finish()


func _finish() -> void:
	stage = Stage.SELESAI
	var pound_s: float = float(pound_result.get("score", 0.0))
	var comps: Dictionary = {
		"komposisi": composition_score(), "urutan": order_score(), "takaran": measure_average(),
		"tumbuk": pound_s, "aduk": stir_score,
		"kesalahan": ScoringSystem.error_factor(errors, 0.2),
		"waktu": ScoringSystem.time_factor(elapsed, 60.0 + 10.0 * float(steps.size()), 240.0),
	}
	var cap: int = -1
	if composition_score() < 0.5:
		cap = Grade.Level.D
	elif composition_score() < 0.75:
		cap = Grade.Level.C
	result = ScoringSystem.make_result("peracikan", recipe_id, comps, WEIGHTS, errors, elapsed, recipe_difficulty(), cap)
	result.details = {"picks": picks.duplicate(), "pound": pound_result.duplicate(), "stir": stir_score}


func is_finished() -> bool:
	return stage == Stage.SELESAI


## Batalkan sesi sebelum selesai: bahan yang terambil dikembalikan ke inventaris.
func abort() -> void:
	if stage == Stage.SELESAI:
		return
	for h in picks:
		inventory.add(h, 1)
	picks.clear()
	stage = Stage.PILIH
