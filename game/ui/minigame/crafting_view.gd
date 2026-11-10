class_name CraftingView
extends MinigameView
## Tampilan minigame peracikan herbal: PILIH bahan dari inventaris (jumlah dan urutan), TAKAR dengan menahan
## tombol tuang, TUMBUK dengan ritme mortar-alu, ADUK dengan gerak melingkar. Logika di HerbalCraftingSystem.

signal completed(result: MinigameResult)

const CARD_W: float = 160.0
const CARD_H: float = 96.0
const CARD_GAP: float = 10.0
const STIR_CENTER_R: Vector2 = Vector2(50.0, 330.0)   # radius sentuh yang diterima untuk mengaduk (min, maks)

var sys: HerbalCraftingSystem
var patient_name: String = ""

var _hold: bool = false
var _hold_time: float = 0.0
var _grams: float = 0.0
var _pound_t: float = 0.0
var _pound_fb: String = ""
var _pound_fb_t: float = 0.0
var _pestle: float = 0.0
var _stir_touch: int = -2
var _stir_angle: float = 0.0
var _stir_time: float = 0.0
var _stir_speed: float = 0.0
var _msg: String = ""
var _msg_t: float = 0.0
var _last_measure: Dictionary = {}
var _pound_started: bool = false


func setup(p_sys: HerbalCraftingSystem, p_patient_name: String) -> void:
	sys = p_sys
	patient_name = p_patient_name
	title_text = Locale.t("minigame.title.peracikan")
	_dirty = true


func _say(text: String) -> void:
	_msg = text
	_msg_t = 2.5


func _tick(delta: float) -> void:
	if sys == null:
		return
	sys.update(delta)
	if _msg_t > 0.0:
		_msg_t -= delta
	_pound_fb_t -= delta
	_pestle = maxf(0.0, _pestle - delta * 4.0)
	match sys.stage:
		HerbalCraftingSystem.Stage.TAKAR:
			if _hold:
				_hold_time += delta
				var rate: float = HerbalCraftingSystem.FILL_RATE * (0.5 + 0.5 * minf(1.0, _hold_time / 1.2))
				_grams = minf(_grams + rate * delta, gauge_max())
		HerbalCraftingSystem.Stage.TUMBUK:
			if not _pound_started:
				_pound_started = true
				_pound_t = 0.0
			_pound_t += delta
			if _pound_t >= sys.pound_duration():
				finish_pound()
		HerbalCraftingSystem.Stage.ADUK:
			_stir_speed = maxf(0.0, _stir_speed - delta * 4.0)


func gauge_max() -> float:
	return sys.measure_target() * 1.8


# --- Letak ------------------------------------------------------------------

func shelf_origin() -> Vector2:
	return Vector2(area.position.x + 305.0, area.position.y + 96.0)


func card_rect(i: int) -> Rect2:
	var o: Vector2 = shelf_origin()
	return Rect2(o.x + float(i % 4) * (CARD_W + CARD_GAP), o.y + float(i / 4) * (CARD_H + CARD_GAP), CARD_W, CARD_H)


func bowl_x() -> float:
	return shelf_origin().x + 4.0 * (CARD_W + CARD_GAP) + 10.0


func stir_center() -> Vector2:
	return Vector2(area.get_center().x, area.position.y + 360.0)


func _build() -> void:
	if sys == null:
		return
	match sys.stage:
		HerbalCraftingSystem.Stage.PILIH:
			for i in range(HerbDb.IDS.size()):
				var id: String = HerbDb.IDS[i]
				_add_button("herb:%s" % id, card_rect(i), "", sys.inventory.count(id) > 0, "invisible")
			var bx: float = bowl_x()
			var bw: float = area.end.x - bx
			_add_button("undo", Rect2(bx, area.end.y - 164.0, bw, 62.0), Locale.t("craft.undo"), not sys.picks.is_empty(), "normal")
			_add_button("to_measure", Rect2(bx, area.end.y - 90.0, bw, 74.0), Locale.t("craft.to_measure"), not sys.picks.is_empty(), "primary")
		HerbalCraftingSystem.Stage.TAKAR:
			_add_button("pour", Rect2(area.end.x - 460.0, area.end.y - 250.0, 440.0, 220.0), Locale.t("craft.pour"), true, "primary", "hold")
		HerbalCraftingSystem.Stage.TUMBUK:
			_add_button("pound", Rect2(area.get_center().x - 320.0, area.end.y - 200.0, 640.0, 170.0), Locale.t("craft.pound_tap"), true, "primary", "down")
		_:
			pass


# --- Masukan ----------------------------------------------------------------

func _on_button(id: String, phase: String) -> void:
	if sys == null:
		return
	if id.begins_with("herb:") and phase == "tap":
		take(id.substr(5))
	elif id == "undo" and phase == "tap":
		sys.undo_pick()
		_dirty = true
	elif id == "to_measure" and phase == "tap":
		if sys.confirm_picks():
			_grams = 0.0
			_hold_time = 0.0
		_dirty = true
	elif id == "pour":
		if phase == "down":
			_hold = true
			_hold_time = 0.0
		elif phase == "up":
			release_pour()
	elif id == "pound" and phase == "down":
		pound_now()


func take(herb_id: String) -> void:
	if sys.take_herb(herb_id):
		var over: bool = sys.count_picked(herb_id) > sys.required_units(herb_id)
		if over:
			_say(Locale.t("craft.too_many", {"herb": Locale.t("herb.%s" % herb_id)}))
	else:
		_say(Locale.t("craft.out_of_stock", {"herb": Locale.t("herb.%s" % herb_id)}))
	_dirty = true


## Lepas tombol tuang: catat takaran. Takaran sangat kecil diabaikan (sentuhan tidak sengaja).
func release_pour() -> void:
	_hold = false
	if sys.stage != HerbalCraftingSystem.Stage.TAKAR or _grams < 0.5:
		return
	submit_grams(_grams)


## Kirim takaran gram tertentu (dari tombol tuang atau uji).
func submit_grams(g: float) -> void:
	var r: Dictionary = sys.submit_measure(g)
	if bool(r.get("ok", false)):
		_last_measure = r
		var sc: float = float(r["score"])
		_say(Locale.t("craft.measure_good" if sc >= 0.85 else ("craft.measure_ok" if sc >= 0.4 else "craft.measure_bad"), {"grams": snappedf(g, 0.1)}))
	_grams = 0.0
	_hold_time = 0.0
	_pound_started = false
	_dirty = true


func pound_now() -> void:
	pound_at(_pound_t)


## Ketuk menumbuk pada waktu tahap `t`; memberi umpan balik langsung.
func pound_at(t: float) -> void:
	if sys.stage != HerbalCraftingSystem.Stage.TUMBUK:
		return
	sys.pound_tap(t)
	_pestle = 1.0
	var best: float = 9.0
	for b in sys.pound_beats:
		best = minf(best, absf(float(b) - t))
	var w: float = sys.pound_window_scale()
	if best <= HerbalCraftingSystem.POUND_PERFECT * w:
		_pound_fb = Locale.t("rhythm.perfect")
	elif best <= HerbalCraftingSystem.POUND_GOOD * w:
		_pound_fb = Locale.t("rhythm.good")
	else:
		_pound_fb = Locale.t("rhythm.miss")
	_pound_fb_t = 0.6


func finish_pound() -> void:
	if sys.stage != HerbalCraftingSystem.Stage.TUMBUK:
		return
	sys.finish_pound()
	_stir_touch = -2
	_dirty = true


func _on_press(p: Vector2, index: int) -> void:
	if sys == null:
		return
	if sys.stage == HerbalCraftingSystem.Stage.TUMBUK:
		pound_now()
	elif sys.stage == HerbalCraftingSystem.Stage.ADUK and _stir_touch == -2:
		var c: Vector2 = stir_center()
		var d: float = p.distance_to(c)
		if d >= STIR_CENTER_R.x and d <= STIR_CENTER_R.y:
			_stir_touch = index
			_stir_angle = (p - c).angle()
			_stir_time = time


func _on_drag(p: Vector2, index: int) -> void:
	if sys == null or sys.stage != HerbalCraftingSystem.Stage.ADUK or index != _stir_touch:
		return
	var c: Vector2 = stir_center()
	var d: float = p.distance_to(c)
	var ang: float = (p - c).angle()
	var dt: float = maxf(0.004, time - _stir_time)
	var delta_a: float = wrapf(ang - _stir_angle, -PI, PI)
	_stir_angle = ang
	_stir_time = time
	if d < STIR_CENTER_R.x or d > STIR_CENTER_R.y:
		return
	stir_drag(delta_a, dt)


func _on_release(_p: Vector2, index: int) -> void:
	if index == _stir_touch:
		_stir_touch = -2


## Umpan gerakan aduk (radian, detik). Dipakai sentuhan dan uji.
func stir_drag(angle_delta: float, dt: float) -> void:
	sys.stir_move(angle_delta, dt)
	_stir_speed = absf(angle_delta) / maxf(0.001, dt)
	if sys.is_finished():
		completed.emit(sys.result)


# --- Gambar -----------------------------------------------------------------

func _draw_content() -> void:
	if sys == null:
		return
	var recipe_name: String = Locale.t("recipe.%s.name" % sys.recipe_id)
	_t(area.position.x + 170.0, area.position.y + 6.0, "%s — %s" % [title_text, recipe_name], 30, C_GOLD)
	_draw_stage_bar()
	_draw_recipe_card()
	match sys.stage:
		HerbalCraftingSystem.Stage.PILIH:
			_draw_shelf()
		HerbalCraftingSystem.Stage.TAKAR:
			_draw_measure()
		HerbalCraftingSystem.Stage.TUMBUK:
			_draw_pound()
		HerbalCraftingSystem.Stage.ADUK:
			_draw_stir()
	if _msg_t > 0.0 and _msg != "":
		_t(area.position.x, area.end.y - 270.0 if sys.stage == HerbalCraftingSystem.Stage.TAKAR else area.end.y - 236.0, _msg, 26, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, clampf(_msg_t, 0.0, 1.0)), HORIZONTAL_ALIGNMENT_CENTER, area.size.x)


func _draw_stage_bar() -> void:
	var names: Array[String] = ["craft.stage_pick", "craft.stage_measure", "craft.stage_pound", "craft.stage_stir"]
	var x: float = area.position.x + 305.0
	for i in range(names.size()):
		var active: bool = i == sys.stage
		var done: bool = i < sys.stage
		var col: Color = C_GOLD if active else (C_GREEN if done else C_DIM)
		draw_circle(Vector2(x + 14.0, area.position.y + 70.0), 12.0, col)
		_t(x + 34.0, area.position.y + 56.0, Locale.t(names[i]), 21, col)
		x += 190.0


func _draw_recipe_card() -> void:
	var card := Rect2(area.position.x, area.position.y + 96.0, 290.0, 420.0)
	_box(card, C_PAPER, C_INK, 14, 3)
	_t(card.position.x + 14.0, card.position.y + 8.0, Locale.t("craft.recipe"), 22, C_INK)
	_para(card.position.x + 14.0, card.position.y + 38.0, Locale.t("recipe.%s.desc" % sys.recipe_id), card.size.x - 28.0, 17, Color("#4a3d22"))
	var y: float = card.position.y + 112.0
	var idx: int = 1
	for st in sys.steps:
		var hid: String = String(st["herb"])
		var have: int = sys.count_picked(hid)
		var need: int = int(st["units"])
		var col: Color = Color("#1d5c34") if have == need else (Color("#a33a2a") if have > need else C_INK)
		var line: String = "%d. %s ×%d" % [idx, Locale.t("herb.%s" % hid), need]
		if sys.shows_amounts():
			line += "  %dg" % int(st["grams"])
		_t(card.position.x + 14.0, y, line, 22, col)
		if sys.stage == HerbalCraftingSystem.Stage.PILIH:
			_t(card.position.x + 14.0, y + 26.0, Locale.t("craft.picked", {"n": have, "need": need}), 17, Color("#4a3d22"))
		y += 60.0
		idx += 1
	if sys.stage == HerbalCraftingSystem.Stage.PILIH:
		var sh: Dictionary = sys.shortages()
		if not sh.is_empty():
			_para(card.position.x + 14.0, card.end.y - 56.0, Locale.t("craft.shortage"), card.size.x - 28.0, 17, Color("#a33a2a"))


func _draw_shelf() -> void:
	for i in range(HerbDb.IDS.size()):
		var id: String = HerbDb.IDS[i]
		var r: Rect2 = card_rect(i)
		var n: int = sys.inventory.count(id)
		var in_recipe: bool = sys.required_units(id) > 0
		var fill := Color(0.14, 0.24, 0.2, 0.95) if n > 0 else Color(0.14, 0.14, 0.14, 0.7)
		_box(r, fill, C_GOLD if sys.count_picked(id) > 0 else Color(1, 1, 1, 0.25), 14, 3 if sys.count_picked(id) > 0 else 2)
		PlantArt.draw_herb_icon(self, id, r.position + Vector2(r.size.x * 0.5, 36.0), 44.0)
		_t(r.position.x, r.position.y + 64.0, Locale.t("herb.%s" % id), 19, C_TEXT if n > 0 else C_DIM, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		_t(r.position.x + 8.0, r.position.y + 4.0, "×%d" % n, 20, C_GOLD if n > 0 else C_RED)
		if in_recipe:
			draw_circle(r.position + Vector2(r.size.x - 14.0, 14.0), 5.0, C_GREEN)
	# mangkuk
	var bx: float = bowl_x()
	var bw: float = area.end.x - bx
	var bowl := Rect2(bx, area.position.y + 96.0, bw, 300.0)
	_box(bowl, Color(0.2, 0.15, 0.1, 0.95), C_GOLD, 16, 2)
	_t(bowl.position.x + 12.0, bowl.position.y + 6.0, Locale.t("craft.bowl"), 22, C_GOLD)
	var y: float = bowl.position.y + 40.0
	var shown: int = 0
	for i in range(sys.picks.size()):
		if shown >= 8:
			_t(bowl.position.x + 12.0, y, "…", 20, C_DIM)
			break
		var hid: String = sys.picks[i]
		var ok: bool = sys.required_units(hid) > 0
		_t(bowl.position.x + 12.0, y, "%d. %s" % [i + 1, Locale.t("herb.%s" % hid)], 20, C_TEXT if ok else C_RED)
		y += 30.0
		shown += 1
	_t(area.position.x + 305.0, area.end.y - 150.0, Locale.t("craft.pick_help"), 21, C_DIM, HORIZONTAL_ALIGNMENT_LEFT, bx - area.position.x - 320.0)


func _draw_measure() -> void:
	var target: float = sys.measure_target()
	var herb: String = sys.measure_herb()
	var hdr_x: float = area.position.x + 305.0
	_t(hdr_x, area.position.y + 96.0, Locale.t("craft.measure_title", {"herb": Locale.t("herb.%s" % herb), "grams": int(target), "n": sys.measure_index + 1, "total": sys.steps.size()}), 28, C_TEXT)
	# alat ukur
	var g := Rect2(hdr_x + 40.0, area.position.y + 150.0, 110.0, 340.0)
	_box(g, Color(0, 0, 0, 0.5), Color(1, 1, 1, 0.5), 14, 3)
	var mx: float = gauge_max()
	var tol: float = sys.measure_tolerance()
	var ty: float = g.end.y - g.size.y * (target / mx)
	var band: float = g.size.y * (target * tol / mx)
	draw_rect(Rect2(g.position.x + 3.0, ty - band, g.size.x - 6.0, band * 2.0), Color(0.3, 0.85, 0.45, 0.55))
	draw_line(Vector2(g.position.x - 14.0, ty), Vector2(g.end.x + 14.0, ty), C_GOLD, 4.0)
	_t(g.end.x + 22.0, ty - 14.0, "%d g" % int(target), 24, C_GOLD)
	var fh: float = g.size.y * (_grams / mx)
	if fh > 1.0:
		draw_rect(Rect2(g.position.x + 6.0, g.end.y - fh, g.size.x - 12.0, fh), Color("#d6a52a"))
	_t(hdr_x + 200.0, area.position.y + 250.0, "%.1f g" % _grams, 64, C_TEXT)
	_t(hdr_x + 200.0, area.position.y + 330.0, Locale.t("craft.measure_help"), 21, C_DIM, HORIZONTAL_ALIGNMENT_LEFT, 360.0)
	var y: float = area.position.y + 150.0
	for i in range(sys.measure_scores.size()):
		_t(area.end.x - 430.0, y, "%s  %d%%" % [Locale.t("herb.%s" % sys.steps[i]["herb"]), int(roundf(sys.measure_scores[i] * 100.0))], 21, C_GREEN)
		y += 30.0


func _draw_pound() -> void:
	var c := Vector2(area.get_center().x + 100.0, area.position.y + 280.0)
	# mortar
	draw_colored_polygon(PackedVector2Array([c + Vector2(-130, -10), c + Vector2(130, -10), c + Vector2(95, 100), c + Vector2(-95, 100)]), Color("#6b6b70"))
	draw_circle(c + Vector2(0, -10), 1.0, Color.WHITE)
	draw_rect(Rect2(c.x - 140.0, c.y - 22.0, 280.0, 18.0), Color("#8a8a90"))
	var py: float = c.y - 150.0 + _pestle * 110.0
	draw_line(Vector2(c.x + 10.0, py), Vector2(c.x + 70.0, py - 130.0), Color("#8a5a34"), 22.0)
	draw_circle(Vector2(c.x + 10.0, py), 18.0, Color("#8a5a34"))
	# cincin ketukan
	var ring_c: Vector2 = c + Vector2(0, -110)
	draw_arc(ring_c, 54.0, 0.0, TAU, 36, C_GOLD, 5.0)
	for b in sys.pound_beats:
		var dt: float = float(b) - _pound_t
		if dt >= -0.1 and dt <= 1.0:
			var rr: float = 54.0 + clampf(dt, 0.0, 1.0) * 120.0
			draw_arc(ring_c, rr, 0.0, TAU, 40, Color(1, 1, 1, 0.9 - clampf(dt, 0.0, 1.0) * 0.6), 4.0)
	var beats_done: int = 0
	for b in sys.pound_beats:
		if _pound_t >= float(b) + 0.2:
			beats_done += 1
	_t(area.position.x + 305.0, area.position.y + 96.0, Locale.t("craft.pound_help"), 24, C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 660.0)
	_t(area.position.x + 305.0, area.position.y + 190.0, Locale.t("craft.pound_count", {"n": beats_done, "total": sys.pound_beats.size()}), 22, C_DIM)
	if _pound_fb_t > 0.0:
		_t(c.x - 200.0, c.y - 270.0, _pound_fb, 44, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 400.0)


func _draw_stir() -> void:
	var c: Vector2 = stir_center()
	draw_circle(c, 190.0, Color("#6b4a2c"))
	draw_circle(c, 168.0, Color("#c79a52"))
	draw_arc(c, 120.0, 0.0, TAU, 48, Color(0, 0, 0, 0.2), 3.0)
	# kemajuan
	draw_arc(c, 206.0, -PI * 0.5, -PI * 0.5 + TAU * sys.stir_fraction(), 60, C_GREEN, 10.0)
	# sendok
	var a: float = _stir_angle if _stir_touch != -2 else time * 0.6
	var tip: Vector2 = c + Vector2(cos(a), sin(a)) * 130.0
	draw_line(c + Vector2(cos(a), sin(a)) * 40.0, tip, Color("#5c3a1e"), 14.0)
	draw_circle(tip, 22.0, Color("#5c3a1e"))
	_t(area.position.x + 305.0, area.position.y + 96.0, Locale.t("craft.stir_help"), 24, C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 660.0)
	# meter kecepatan
	var band: Vector2 = sys.stir_speed_band()
	var m := Rect2(area.end.x - 150.0, area.position.y + 140.0, 60.0, 320.0)
	_box(m, Color(0, 0, 0, 0.5), Color(1, 1, 1, 0.4), 12, 2)
	var vmax: float = 6.0
	var top: float = m.end.y - m.size.y * clampf(band.y / vmax, 0.0, 1.0)
	var bot: float = m.end.y - m.size.y * clampf(band.x / vmax, 0.0, 1.0)
	draw_rect(Rect2(m.position.x + 3.0, top, m.size.x - 6.0, bot - top), Color(0.3, 0.85, 0.45, 0.6))
	var sy: float = m.end.y - m.size.y * clampf(_stir_speed / vmax, 0.0, 1.0)
	draw_rect(Rect2(m.position.x - 8.0, sy - 5.0, m.size.x + 16.0, 10.0), C_GOLD)
	_t(m.position.x - 40.0, m.position.y - 32.0, Locale.t("craft.speed"), 20, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, m.size.x + 80.0)
