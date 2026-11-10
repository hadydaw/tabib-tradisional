class_name AcupunctureView
extends MinigameView
## Tampilan minigame akupunktur FIKTIF. Fase PILIH: ilustrasi tubuh dengan titik yang bisa disentuh; urutan
## memilih = urutan menusuk. Fase JARUM: geser jari di bantalan bidik (jarum bergetar) dan tekan TUSUK dengan
## ibu jari lain saat ujung jarum di sasaran dan penanda kedalaman di zona hijau. Logika di AcupunctureSystem.

signal completed(result: MinigameResult)

const PT_R: float = 20.0
const PT_HIT: float = 46.0
const AIM_SENS: float = 1.15
const FLASH_SEC: float = 0.9
const START_AIM: Vector2 = Vector2(0.62, 0.58)

var sys: AcupunctureSystem
var patient_name: String = ""
var diagnosed_text: String = ""
var aim: Vector2 = START_AIM
var _aim_touch: int = -2
var _aim_last: Vector2 = Vector2.ZERO
var _flash_t: float = 0.0
var _flash_text: String = ""
var _flash_color: Color = C_GOLD
var _flash_tip: Vector2 = Vector2.ZERO
var _flash_depth: float = 0.0
var _finish_pending: bool = false


func setup(p_sys: AcupunctureSystem, p_patient_name: String, p_diagnosed_text: String) -> void:
	sys = p_sys
	patient_name = p_patient_name
	diagnosed_text = p_diagnosed_text
	title_text = Locale.t("minigame.title.akupunktur")
	_dirty = true


func _tick(delta: float) -> void:
	if sys == null:
		return
	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			_dirty = true
			if _finish_pending:
				_finish_pending = false
				completed.emit(sys.result)
		return
	sys.update(delta)


# --- Letak ------------------------------------------------------------------

func body_rect() -> Rect2:
	var h: float = area.size.y - 96.0
	var w: float = h * 0.62
	return Rect2(area.position.x + area.size.x * 0.30 - w * 0.5, area.position.y + 80.0, w, h)


func point_screen_pos(id: String) -> Vector2:
	var b: Rect2 = body_rect()
	var p: Vector2 = AcupointDb.pos(id)
	return b.position + Vector2(p.x * b.size.x, p.y * b.size.y)


func field_rect() -> Rect2:
	var s: float = minf(area.size.y - 150.0, 500.0)
	return Rect2(area.position.x + area.size.x * 0.30 - s * 0.5, area.position.y + 96.0, s, s)


func field_to_screen(v: Vector2) -> Vector2:
	var f: Rect2 = field_rect()
	return f.get_center() + v * (f.size.x * 0.5)


func depth_rect() -> Rect2:
	var f: Rect2 = field_rect()
	return Rect2(f.end.x + 70.0, f.position.y, 60.0, f.size.y)


func _build() -> void:
	if sys == null:
		return
	if sys.phase == AcupunctureSystem.Phase.PILIH:
		var rx: float = area.position.x + area.size.x * 0.68
		var rw: float = area.end.x - rx
		_add_button("undo", Rect2(rx, area.end.y - 160.0, rw, 62.0), Locale.t("acu.undo"), not sys.selected.is_empty(), "normal")
		_add_button("start", Rect2(rx, area.end.y - 86.0, rw, 74.0), Locale.t("acu.start"), not sys.selected.is_empty(), "primary")
	elif sys.phase == AcupunctureSystem.Phase.JARUM:
		var d: Rect2 = depth_rect()
		var bx: float = d.end.x + 40.0
		_add_button("needle", Rect2(bx, area.end.y - 270.0, area.end.x - bx, 240.0), Locale.t("acu.needle"), _flash_t <= 0.0, "primary", "down")
		_add_button("finish_early", Rect2(bx, area.position.y + 70.0, area.end.x - bx, 60.0), Locale.t("acu.finish"), sys.insertions.size() > 0, "ghost")


# --- Masukan ----------------------------------------------------------------

func _on_press(p: Vector2, index: int) -> void:
	if sys == null:
		return
	if sys.phase == AcupunctureSystem.Phase.PILIH:
		var best: String = ""
		var best_d: float = PT_HIT
		for id in AcupointDb.IDS:
			var d: float = point_screen_pos(id).distance_to(p)
			if d <= best_d:
				best_d = d
				best = id
		if best != "":
			toggle(best)
	elif sys.phase == AcupunctureSystem.Phase.JARUM and _aim_touch == -2 and _flash_t <= 0.0:
		_aim_touch = index
		_aim_last = p


func _on_drag(p: Vector2, index: int) -> void:
	if sys == null or sys.phase != AcupunctureSystem.Phase.JARUM or index != _aim_touch or _flash_t > 0.0:
		return
	var half: float = field_rect().size.x * 0.5
	aim += (p - _aim_last) / half * AIM_SENS
	aim = Vector2(clampf(aim.x, -1.15, 1.15), clampf(aim.y, -1.15, 1.15))
	_aim_last = p


func _on_release(_p: Vector2, index: int) -> void:
	if index == _aim_touch:
		_aim_touch = -2


func toggle(id: String) -> void:
	if sys.toggle_point(id):
		_dirty = true


func _on_button(id: String, phase: String) -> void:
	if sys == null:
		return
	if id == "undo" and phase == "tap":
		if not sys.selected.is_empty():
			sys.toggle_point(sys.selected[sys.selected.size() - 1])
			_dirty = true
	elif id == "start" and phase == "tap":
		start_insertion()
	elif id == "needle" and phase == "down":
		insert_now()
	elif id == "finish_early" and phase == "tap":
		sys.finish_early()
		if sys.is_finished():
			completed.emit(sys.result)


func start_insertion() -> void:
	if sys.begin_insertion():
		aim = START_AIM
		_aim_touch = -2
		_dirty = true


## Tusuk sekarang di posisi ujung jarum saat ini (termasuk getaran) dan kedalaman penanda saat ini.
func insert_now() -> void:
	if sys == null or sys.phase != AcupunctureSystem.Phase.JARUM or _flash_t > 0.0:
		return
	var tip: Vector2 = sys.tip_position(aim, sys.point_time)
	var depth: float = sys.depth_at(sys.point_time)
	insert_at(tip, depth)


## Tusuk di `tip` dan `depth` tertentu (dipakai tes dan insert_now).
func insert_at(tip: Vector2, depth: float) -> void:
	if sys.phase != AcupunctureSystem.Phase.JARUM:
		return
	var rec: Dictionary = sys.insert(tip, depth)
	if not bool(rec.get("ok", false)):
		return
	_flash_tip = tip
	_flash_depth = depth
	var sc: float = float(rec["score"])
	if sc >= 0.9:
		_flash_text = Locale.t("acu.flash_perfect")
		_flash_color = C_GOLD
	elif sc >= 0.65:
		_flash_text = Locale.t("acu.flash_good")
		_flash_color = C_GREEN
	elif sc >= 0.35:
		_flash_text = Locale.t("acu.flash_close")
		_flash_color = C_ORANGE
	else:
		_flash_text = Locale.t("acu.flash_miss")
		_flash_color = C_RED
	if not bool(rec.get("in_plan", true)):
		_flash_text = Locale.t("acu.flash_wrong")
		_flash_color = C_RED
	_flash_t = FLASH_SEC
	_finish_pending = sys.is_finished()
	aim = START_AIM
	_aim_touch = -2
	_dirty = true


func is_flashing() -> bool:
	return _flash_t > 0.0


# --- Gambar -----------------------------------------------------------------

func _draw_content() -> void:
	if sys == null:
		return
	_t(area.position.x + 170.0, area.position.y + 6.0, "%s — %s" % [title_text, patient_name], 30, C_GOLD)
	if sys.phase == AcupunctureSystem.Phase.PILIH:
		_draw_select()
	elif sys.phase == AcupunctureSystem.Phase.JARUM or sys.phase == AcupunctureSystem.Phase.SELESAI:
		_draw_needle()


func _draw_body() -> void:
	var b: Rect2 = body_rect()
	var skin := Color("#d9a877")
	var cx: float = b.position.x + b.size.x * 0.5
	var u: float = b.size.y
	draw_circle(Vector2(cx, b.position.y + u * 0.075), u * 0.062, skin)
	draw_rect(Rect2(cx - u * 0.02, b.position.y + u * 0.13, u * 0.04, u * 0.05), skin.darkened(0.1))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - u * 0.10, b.position.y + u * 0.18), Vector2(cx + u * 0.10, b.position.y + u * 0.18),
		Vector2(cx + u * 0.085, b.position.y + u * 0.56), Vector2(cx - u * 0.085, b.position.y + u * 0.56)]), Color("#4b7a66"))
	draw_line(Vector2(cx - u * 0.10, b.position.y + u * 0.2), Vector2(cx - u * 0.2, b.position.y + u * 0.52), skin, u * 0.04)
	draw_line(Vector2(cx + u * 0.10, b.position.y + u * 0.2), Vector2(b.position.x + b.size.x * 0.86, b.position.y + u * 0.52), skin, u * 0.04)
	draw_line(Vector2(cx - u * 0.04, b.position.y + u * 0.56), Vector2(cx - u * 0.07, b.position.y + u * 0.97), Color("#355a4a"), u * 0.055)
	draw_line(Vector2(cx + u * 0.04, b.position.y + u * 0.56), Vector2(b.position.x + b.size.x * 0.60, b.position.y + u * 0.97), Color("#355a4a"), u * 0.055)


func _draw_select() -> void:
	_draw_body()
	var b: Rect2 = body_rect()
	for id in AcupointDb.IDS:
		var p: Vector2 = point_screen_pos(id)
		var idx: int = sys.selected.find(id)
		if idx >= 0:
			draw_circle(p, PT_R + 4.0, C_GOLD)
			_t(p.x - 20.0, p.y - 14.0, str(idx + 1), 26, C_INK, HORIZONTAL_ALIGNMENT_CENTER, 40.0)
		else:
			var pulse: float = 0.5 + 0.5 * sin(time * 3.0 + p.y * 0.03)
			draw_circle(p, PT_R, Color(0.95, 0.35, 0.3, 0.55 + 0.25 * pulse))
			draw_arc(p, PT_R, 0.0, TAU, 24, Color.WHITE, 3.0)
		var right: bool = p.x >= b.position.x + b.size.x * 0.5 and not (id == "alis_pagi" or id == "ubun_embun")
		var label: String = "%s · %s" % [Locale.t("point.%s" % id), Locale.t("tag.%s" % AcupointDb.tag(id))]
		var lw: float = 250.0
		if right:
			draw_line(p + Vector2(PT_R, 0), p + Vector2(PT_R + 22.0, 0), Color(1, 1, 1, 0.5), 2.0)
			_t(p.x + PT_R + 26.0, p.y - 13.0, label, 20, C_TEXT)
		else:
			draw_line(p - Vector2(PT_R, 0), p - Vector2(PT_R + 22.0, 0), Color(1, 1, 1, 0.5), 2.0)
			_t(p.x - PT_R - 26.0 - lw, p.y - 13.0, label, 20, C_TEXT, HORIZONTAL_ALIGNMENT_RIGHT, lw)
	# panel kanan: kebutuhan pasien
	var rx: float = area.position.x + area.size.x * 0.68
	var rw: float = area.end.x - rx
	var panel := Rect2(rx, area.position.y + 70.0, rw, area.size.y - 250.0)
	_box(panel, C_PAPER, C_INK, 16, 3)
	_t(panel.position.x + 16.0, panel.position.y + 8.0, Locale.t("acu.need_title"), 24, C_INK)
	_para(panel.position.x + 16.0, panel.position.y + 42.0, diagnosed_text, rw - 32.0, 20, Color("#4a3d22"))
	var y: float = panel.position.y + 112.0
	var tags: Array[String] = sys.hint_tags()
	for i in range(tags.size()):
		_t(panel.position.x + 16.0, y, "%d. %s" % [i + 1, Locale.t("tag.%s" % tags[i])], 26, C_INK)
		y += 36.0
	_para(panel.position.x + 16.0, y + 6.0, Locale.t("acu.select_help"), rw - 32.0, 18, Color("#4a3d22"))
	_t(rx, area.end.y - 192.0, Locale.t("acu.chosen", {"n": sys.selected.size(), "max": AcupunctureSystem.MAX_POINTS}), 21, C_TEXT)


func _draw_needle() -> void:
	var f: Rect2 = field_rect()
	_box(f.grow(10.0), Color("#c99a6b"), C_INK, 24, 4)
	var r: float = sys.target_radius() * f.size.x * 0.5
	var c: Vector2 = f.get_center()
	draw_circle(c, r * 3.0, Color(0.85, 0.6, 0.4, 0.5))
	draw_circle(c, r * 2.0, Color(0.95, 0.75, 0.35, 0.55))
	draw_circle(c, r, Color(0.35, 0.8, 0.45, 0.75))
	draw_circle(c, r * 0.35, Color(1, 1, 1, 0.9))
	draw_line(c + Vector2(-r * 3.4, 0), c + Vector2(r * 3.4, 0), Color(0, 0, 0, 0.25), 1.0)
	draw_line(c + Vector2(0, -r * 3.4), c + Vector2(0, r * 3.4), Color(0, 0, 0, 0.25), 1.0)
	var pid: String = sys.current_point()
	var total: int = sys.selected.size()
	if pid != "":
		_t(f.position.x, f.position.y - 44.0, "%s  (%d/%d)" % [Locale.t("point.%s" % pid), sys.cursor + 1, total], 28, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, f.size.x)
		_para(f.position.x, f.end.y + 10.0, Locale.t("acu.aim_help"), f.size.x, 17, C_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	# jarum
	var tip_v: Vector2 = aim
	var depth_v: float = sys.depth_at(sys.point_time)
	if _flash_t > 0.0:
		tip_v = _flash_tip
		depth_v = _flash_depth
	elif pid != "":
		tip_v = sys.tip_position(aim, sys.point_time)
	var tip: Vector2 = field_to_screen(tip_v)
	if sys.phase == AcupunctureSystem.Phase.JARUM or _flash_t > 0.0:
		draw_line(tip, tip + Vector2(120.0, -150.0), Color(0.9, 0.92, 0.95), 5.0)
		draw_circle(tip + Vector2(120.0, -150.0), 9.0, Color("#c8483c"))
		draw_circle(tip, 7.0, Color.WHITE)
		draw_arc(tip, 15.0, 0.0, TAU, 20, C_GOLD, 3.0)
	# meter kedalaman
	var d: Rect2 = depth_rect()
	_box(d, Color(0, 0, 0, 0.45), Color(1, 1, 1, 0.4), 12, 2)
	var half: float = sys.depth_half_width()
	var band_top: float = d.position.y + d.size.y * (AcupunctureSystem.DEPTH_CENTER - half)
	var band_h: float = d.size.y * half * 2.0
	draw_rect(Rect2(d.position.x + 3.0, band_top, d.size.x - 6.0, band_h), Color(0.3, 0.85, 0.45, 0.8))
	var my: float = d.position.y + d.size.y * depth_v
	draw_rect(Rect2(d.position.x - 10.0, my - 5.0, d.size.x + 20.0, 10.0), C_GOLD)
	_t(d.position.x - 40.0, d.position.y - 36.0, Locale.t("acu.depth"), 20, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, d.size.x + 80.0)
	if _flash_t > 0.0:
		var a: float = clampf(_flash_t / 0.4, 0.0, 1.0)
		_t(f.position.x, f.get_center().y - 40.0, _flash_text, 56, Color(_flash_color.r, _flash_color.g, _flash_color.b, a), HORIZONTAL_ALIGNMENT_CENTER, f.size.x)
