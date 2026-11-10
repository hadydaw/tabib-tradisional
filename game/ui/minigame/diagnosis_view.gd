class_name DiagnosisView
extends MinigameView
## Tampilan minigame diagnosis: pasien (placeholder), enam titik periksa yang bisa disentuh, uji ritme nadi,
## buku catatan temuan, dan tabel kandidat untuk menetapkan diagnosis. Logika di DiagnosisSystem.

signal completed(result: MinigameResult)

enum Mode { PERIKSA, NADI, PUTUSAN }

const HOT_R: float = 36.0
const HIT_R: float = 50.0
const PULSE_LEAD: float = 1.2
const PULSE_SHOWN: int = 3   # jumlah denyut yang ditampilkan; sisanya dijaga ritmenya oleh pemain

var sys: DiagnosisSystem
var patient_name: String = ""
var complaint_text: String = ""
var mode: int = Mode.PERIKSA
var selected: String = ""

var _msg: String = ""
var _msg_t: float = 0.0
var _msg_color: Color = C_GOLD
var _pulse_t: float = 0.0
var _pulse_beats: Array[float] = []
var _pulse_taps: Array[float] = []
var _pulse_running: bool = false
var _pulse_feedback: String = ""
var _pulse_feedback_t: float = 0.0
var _pulse_flash: float = 0.0


func setup(p_sys: DiagnosisSystem, p_patient_name: String, p_complaint_text: String) -> void:
	sys = p_sys
	patient_name = p_patient_name
	complaint_text = p_complaint_text
	title_text = Locale.t("minigame.title.diagnosis")
	_dirty = true


func _tick(delta: float) -> void:
	if sys == null:
		return
	if _msg_t > 0.0:
		_msg_t -= delta
	sys.update(delta)
	if mode == Mode.NADI and _pulse_running:
		_pulse_t += delta
		_pulse_feedback_t -= delta
		_pulse_flash = maxf(0.0, _pulse_flash - delta * 3.0)
		if _pulse_t > float(_pulse_beats[_pulse_beats.size() - 1]) + 0.9:
			finish_pulse()


func _say(text: String, color: Color = C_GOLD) -> void:
	_msg = text
	_msg_t = 3.0
	_msg_color = color


# --- Letak ------------------------------------------------------------------

func _fig_center() -> Vector2:
	return Vector2(area.position.x + area.size.x * 0.20, area.position.y + 90.0)


## Posisi titik periksa (pusat) pada gambar pasien.
func hotspot_pos(area_id: String) -> Vector2:
	var c: Vector2 = _fig_center()
	var head: Vector2 = c + Vector2(0.0, 150.0)
	match area_id:
		"dahi": return head + Vector2(0.0, -70.0)
		"mata": return head + Vector2(0.0, -14.0)
		"lidah": return head + Vector2(0.0, 52.0)
		"kulit": return c + Vector2(-150.0, 400.0)
		"perut": return c + Vector2(0.0, 400.0)
		"nadi": return c + Vector2(150.0, 440.0)
	return head


func _build() -> void:
	if sys == null:
		return
	var by: float = area.end.y - 78.0
	match mode:
		Mode.PERIKSA:
			var x0: float = area.position.x + area.size.x * 0.40
			_add_button("observe", Rect2(x0, by, 270.0, 66.0), Locale.t("diag.observe"), not sys.observed, "normal")
			_add_button("to_verdict", Rect2(area.end.x - 340.0, by, 340.0, 66.0), Locale.t("diag.to_verdict"), sys.can_submit(), "primary")
		Mode.NADI:
			var r := Rect2(area.get_center().x - 280.0, area.end.y - 210.0, 560.0, 170.0)
			_add_button("pulse_tap", r, Locale.t("diag.pulse_tap"), true, "primary", "down")
			_add_button("pulse_cancel", Rect2(area.end.x - 190.0, area.position.y, 190.0, 60.0), Locale.t("ui.cancel"), true, "ghost")
		Mode.PUTUSAN:
			var rows: Array[String] = sys.candidates
			var y: float = _table_top()
			for c in rows:
				_add_button("cand:%s" % c, Rect2(_table_left(), y, _table_width(), 78.0), "", not sys.guesses.has(c), "invisible")
				y += 86.0
			_add_button("verdict_back", Rect2(area.position.x + 10.0, by, 300.0, 66.0), Locale.t("diag.back"), true, "normal")
			_add_button("verdict_ok", Rect2(area.end.x - 380.0, by, 380.0, 66.0), Locale.t("diag.confirm"), selected != "" and not sys.guesses.has(selected), "primary")


func _table_left() -> float:
	return area.position.x + 10.0


func _table_width() -> float:
	return minf(area.size.x - 20.0, 1200.0)


func _table_top() -> float:
	return area.position.y + 150.0


# --- Masukan ----------------------------------------------------------------

func _on_press(p: Vector2, _index: int) -> void:
	if sys == null or mode != Mode.PERIKSA:
		return
	var best: String = ""
	var best_d: float = HIT_R
	for a in AilmentDb.AREAS:
		var d: float = hotspot_pos(a).distance_to(p)
		if d <= best_d:
			best_d = d
			best = a
	if best != "":
		inspect_area(best)


## Periksa area (dari sentuhan titik periksa atau uji). Area nadi memulai uji ritme.
func inspect_area(a: String) -> void:
	if sys.is_finished() or mode != Mode.PERIKSA:
		return
	if sys.findings.has(a):
		_say(Locale.t("diag.already", {"area": Locale.t("area.%s" % a)}), C_DIM)
		return
	if sys.energy_left <= 0:
		_say(Locale.t("diag.no_energy"), C_RED)
		return
	if a == AilmentDb.PULSE_AREA:
		start_pulse()
		return
	var r: Dictionary = sys.inspect(a)
	if bool(r.get("ok", false)):
		_say(Locale.t("diag.found", {"area": Locale.t("area.%s" % a), "value": Locale.t("finding.%s.%s" % [a, r["value"]])}),
			C_GREEN if bool(r["informative"]) else C_ORANGE)
	_dirty = true


func _on_button(id: String, phase: String) -> void:
	if sys == null:
		return
	if id == "observe" and phase == "tap":
		var r: Dictionary = sys.observe()
		if bool(r.get("ok", false)):
			_say(Locale.t("diag.observed", {"area": Locale.t("area.%s" % r["area"]), "value": Locale.t("finding.%s.%s" % [r["area"], r["value"]])}), C_GREEN)
		_dirty = true
	elif id == "to_verdict" and phase == "tap":
		_msg_t = 0.0
		mode = Mode.PUTUSAN
		_dirty = true
	elif id == "verdict_back" and phase == "tap":
		mode = Mode.PERIKSA
		_dirty = true
	elif id.begins_with("cand:") and phase == "tap":
		selected = id.substr(5)
		_dirty = true
	elif id == "verdict_ok" and phase == "tap":
		confirm_verdict()
	elif id == "pulse_tap" and phase == "down":
		pulse_tap_now()
	elif id == "pulse_cancel" and phase == "tap":
		_pulse_running = false
		mode = Mode.PERIKSA
		_dirty = true


## Tetapkan diagnosis terpilih.
func confirm_verdict() -> void:
	if selected == "" or sys.guesses.has(selected):
		return
	var r: Dictionary = sys.submit(selected)
	if bool(r.get("finished", false)):
		completed.emit(sys.result)
	elif bool(r.get("ok", false)):
		_say(Locale.t("diag.wrong_try", {"name": Locale.t("ailment.%s.name" % selected)}), C_RED)
		selected = ""
	_dirty = true


# --- Uji nadi ---------------------------------------------------------------

func start_pulse() -> void:
	_msg_t = 0.0
	mode = Mode.NADI
	_pulse_t = 0.0
	_pulse_taps.clear()
	_pulse_beats = sys.pulse_beats(PULSE_LEAD)
	_pulse_running = true
	_pulse_feedback = ""
	_dirty = true


func pulse_tap_now() -> void:
	pulse_tap_time(_pulse_t)


## Catat ketukan pada waktu `t` (detik sejak uji dimulai).
func pulse_tap_time(t: float) -> void:
	if not _pulse_running:
		return
	_pulse_taps.append(t)
	_pulse_flash = 1.0
	var best: float = 9.0
	for b in _pulse_beats:
		best = minf(best, absf(float(b) - t))
	var w: float = sys.pulse_window_scale()
	if best <= 0.09 * w:
		_pulse_feedback = Locale.t("rhythm.perfect")
	elif best <= 0.22 * w:
		_pulse_feedback = Locale.t("rhythm.good")
	else:
		_pulse_feedback = Locale.t("rhythm.miss")
	_pulse_feedback_t = 0.6


func finish_pulse() -> void:
	if not _pulse_running:
		return
	_pulse_running = false
	var w: float = sys.pulse_window_scale()
	var j: Dictionary = RhythmJudge.judge(_pulse_beats, _pulse_taps, 0.09 * w, 0.22 * w)
	var r: Dictionary = sys.inspect_pulse(float(j["score"]))
	mode = Mode.PERIKSA
	if bool(r.get("ok", false)) and bool(r.get("readable", false)):
		_say(Locale.t("diag.found", {"area": Locale.t("area.nadi"), "value": Locale.t("finding.nadi.%s" % r["value"])}), C_GREEN)
	elif bool(r.get("ok", false)):
		_say(Locale.t("diag.pulse_unclear"), C_ORANGE)
	_dirty = true


# --- Gambar -----------------------------------------------------------------

func _draw_content() -> void:
	if sys == null:
		return
	_t(area.position.x + 170.0, area.position.y + 6.0, "%s — %s" % [title_text, patient_name], 30, C_GOLD)
	match mode:
		Mode.PERIKSA:
			_draw_examine()
		Mode.NADI:
			_draw_pulse()
		Mode.PUTUSAN:
			_draw_verdict()
	if _msg_t > 0.0 and _msg != "":
		var a: float = clampf(_msg_t / 0.6, 0.0, 1.0)
		var col := Color(_msg_color.r, _msg_color.g, _msg_color.b, a)
		_t(area.position.x, area.end.y - 124.0, _msg, 26, col, HORIZONTAL_ALIGNMENT_CENTER, area.size.x)


func _draw_patient() -> void:
	var c: Vector2 = _fig_center()
	var skin := Color("#d9a877")
	# badan dan lengan
	draw_colored_polygon(PackedVector2Array([c + Vector2(-70, 290), c + Vector2(70, 290), c + Vector2(130, 590), c + Vector2(-130, 590)]), Color("#4b7a66"))
	draw_line(c + Vector2(-80, 300), c + Vector2(-150, 470), Color("#4b7a66"), 40.0)
	draw_line(c + Vector2(80, 300), c + Vector2(150, 500), Color("#4b7a66"), 40.0)
	draw_circle(c + Vector2(-152, 485), 24.0, skin)
	draw_circle(c + Vector2(152, 515), 24.0, skin)
	draw_rect(Rect2(c + Vector2(-26, 250), Vector2(52, 50)), skin.darkened(0.1))
	# kepala
	var head: Vector2 = c + Vector2(0.0, 150.0)
	draw_circle(head, 118.0, skin)
	draw_arc(head, 118.0, PI * 1.08, PI * 1.92, 24, Color("#2b1c14"), 26.0)
	draw_circle(head + Vector2(-38, -14), 9.0, Color("#2b2418"))
	draw_circle(head + Vector2(38, -14), 9.0, Color("#2b2418"))
	draw_line(head + Vector2(-20, 52), head + Vector2(20, 52), Color("#8a4d3c"), 6.0)


func _draw_examine() -> void:
	_draw_patient()
	for a in AilmentDb.AREAS:
		var p: Vector2 = hotspot_pos(a)
		var done: bool = sys.findings.has(a)
		var can: bool = not done and sys.energy_left > 0
		if done:
			draw_circle(p, HOT_R, Color(0.2, 0.55, 0.3, 0.9))
			_check_mark(p, HOT_R * 0.9, Color.WHITE)
		else:
			var pulse: float = 0.5 + 0.5 * sin(time * 4.0 + p.y * 0.02)
			draw_circle(p, HOT_R, Color(0.95, 0.8, 0.3, 0.25 + 0.2 * pulse if can else 0.12))
			draw_arc(p, HOT_R, 0.0, TAU, 28, C_GOLD if can else C_DIM, 4.0)
		var lx: float = p.x + HOT_R + 10.0
		if a == "kulit":
			lx = p.x - HOT_R - 10.0 - 70.0
		_t(lx, p.y - 13.0, Locale.t("area.%s" % a), 24, C_TEXT, HORIZONTAL_ALIGNMENT_RIGHT if a == "kulit" else HORIZONTAL_ALIGNMENT_LEFT, 70.0 if a == "kulit" else -1.0)
	# kolom kanan
	var x0: float = area.position.x + area.size.x * 0.40
	var w: float = area.end.x - x0
	_t(x0, area.position.y + 6.0, Locale.t("diag.energy"), 22, C_TEXT, HORIZONTAL_ALIGNMENT_RIGHT, w - 24.0 - 34.0 * float(sys.energy_max))
	_pips(area.end.x - 34.0 * float(sys.energy_max) + 14.0, area.position.y + 22.0, sys.energy_left, sys.energy_max, C_GOLD)
	var comp := Rect2(x0, area.position.y + 76.0, w, 118.0)
	_box(comp, C_PANEL, Color(1, 1, 1, 0.25), 16, 2)
	_t(comp.position.x + 18.0, comp.position.y + 8.0, Locale.t("diag.complaint"), 20, C_GOLD)
	_para(comp.position.x + 18.0, comp.position.y + 36.0, "“%s”" % complaint_text, comp.size.x - 36.0, 23, C_TEXT)
	var notes := Rect2(x0, comp.end.y + 12.0, w, 322.0)
	_box(notes, C_PAPER, C_INK, 16, 3)
	_t(notes.position.x + 18.0, notes.position.y + 8.0, Locale.t("diag.notes"), 24, C_INK)
	var y: float = notes.position.y + 46.0
	for a in AilmentDb.AREAS:
		_t(notes.position.x + 24.0, y, Locale.t("area.%s" % a), 24, C_INK)
		var txt: String = "—"
		var col: Color = Color(0.2, 0.16, 0.1, 0.4)
		if sys.findings.has(a):
			txt = Locale.t("finding.%s.%s" % [a, sys.findings[a]])
			col = Color("#1d5c34")
		_t(notes.position.x + 190.0, y, txt, 24, col)
		y += 42.0


func _draw_pulse() -> void:
	var c := Vector2(area.get_center().x, area.position.y + 250.0)
	_t(area.position.x, area.position.y + 70.0, Locale.t("diag.pulse_help"), 24, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, area.size.x)
	var beats_n: int = _pulse_beats.size()
	# denyut yang tampak (hanya beberapa pertama), selanjutnya pemain menjaga ritme sendiri
	var scale_v: float = 1.0
	var nadi_val: String = AilmentDb.finding(sys.true_ailment, AilmentDb.PULSE_AREA)
	var amp: float = 1.4 if nadi_val == "kuat" else (0.5 if nadi_val == "lemah" else 1.0)
	for i in range(mini(PULSE_SHOWN, beats_n)):
		var dt: float = _pulse_t - float(_pulse_beats[i])
		if dt >= 0.0 and dt < 0.5:
			scale_v += amp * 0.45 * exp(-dt * 7.0)
	var base_r: float = 78.0
	draw_circle(c, base_r * scale_v + 26.0, Color(0.95, 0.4, 0.35, 0.18))
	draw_circle(c, base_r * scale_v, Color("#c8483c"))
	draw_arc(c, base_r * scale_v + 6.0, 0.0, TAU, 40, Color(1, 1, 1, 0.5 + 0.5 * _pulse_flash), 5.0)
	var hidden: bool = _pulse_t > float(_pulse_beats[mini(PULSE_SHOWN, beats_n) - 1]) + 0.35
	if hidden:
		_t(c.x - 240.0, c.y + 118.0, Locale.t("diag.pulse_keep"), 24, C_ORANGE, HORIZONTAL_ALIGNMENT_CENTER, 480.0)
	var done: int = 0
	for b in _pulse_beats:
		if _pulse_t >= float(b):
			done += 1
	_t(c.x - 200.0, c.y + 160.0, Locale.t("diag.pulse_count", {"n": done, "total": beats_n}), 22, C_DIM, HORIZONTAL_ALIGNMENT_CENTER, 400.0)
	if _pulse_feedback_t > 0.0:
		_t(c.x - 200.0, c.y - 150.0, _pulse_feedback, 36, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 400.0)


func _draw_verdict() -> void:
	var left: float = _table_left()
	var wtot: float = _table_width()
	_t(left, area.position.y + 70.0, Locale.t("diag.verdict_help"), 23, C_TEXT, HORIZONTAL_ALIGNMENT_LEFT, wtot)
	var name_w: float = 300.0
	var col_w: float = (wtot - name_w) / float(AilmentDb.AREAS.size())
	var hy: float = area.position.y + 104.0
	for i in range(AilmentDb.AREAS.size()):
		var a: String = AilmentDb.AREAS[i]
		var cx: float = left + name_w + col_w * float(i)
		_t(cx, hy, Locale.t("area.%s" % a), 21, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, col_w)
		if sys.findings.has(a):
			_t(cx, hy + 22.0, Locale.t("finding.%s.%s" % [a, sys.findings[a]]), 19, C_GREEN, HORIZONTAL_ALIGNMENT_CENTER, col_w)
		else:
			_t(cx, hy + 22.0, "?", 19, C_DIM, HORIZONTAL_ALIGNMENT_CENTER, col_w)
	var y: float = _table_top()
	for c in sys.candidates:
		var row := Rect2(left, y, wtot, 78.0)
		var out: bool = sys.guesses.has(c)
		var sel: bool = c == selected
		var fill := Color(0.12, 0.2, 0.19, 0.95)
		if sel:
			fill = Color(0.35, 0.28, 0.1, 0.95)
		if out:
			fill = Color(0.2, 0.1, 0.1, 0.8)
		_box(row, fill, C_GOLD if sel else Color(1, 1, 1, 0.2), 14, 3 if sel else 2)
		var nm_col: Color = C_DIM if out else C_TEXT
		_t(row.position.x + 14.0, row.position.y + 8.0, Locale.t("ailment.%s.name" % c), 25, nm_col)
		if out:
			_t(row.position.x + 14.0, row.position.y + 42.0, Locale.t("diag.ruled_out"), 19, C_RED)
		else:
			_para(row.position.x + 14.0, row.position.y + 38.0, Locale.t("ailment.%s.desc" % c).split(";")[0], name_w - 24.0, 16, C_DIM)
		for i in range(AilmentDb.AREAS.size()):
			var a: String = AilmentDb.AREAS[i]
			var cx: float = left + name_w + col_w * float(i)
			var val: String = Locale.t("finding.%s.%s" % [a, AilmentDb.finding(c, a)])
			var col: Color = C_TEXT
			if sys.helper_marks() and sys.findings.has(a):
				var m: int = sys.mark(c, a)
				col = C_GREEN if m > 0 else C_RED
				draw_circle(Vector2(cx + col_w * 0.5, row.end.y - 14.0), 5.0, col)
			if out:
				col = C_DIM
			_t(cx, row.position.y + 26.0, val, 20, col, HORIZONTAL_ALIGNMENT_CENTER, col_w)
		y += 86.0
