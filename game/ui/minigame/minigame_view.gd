class_name MinigameView
extends Control
## Dasar tampilan minigame layar penuh (Android landscape, sentuh). Mode "immediate": tombol dibangun ulang
## lewat `_build()` setiap keadaan berubah (`_dirty`), digambar di `_draw()`, dan diuji lewat press_at/drag_to/
## release_at/click_button (tanpa perlu input nyata). Tombol berukuran besar untuk ibu jari. Layar hasil (S..D)
## bersama untuk semua minigame.

signal finished(result: MinigameResult, awards: Array)
signal cancelled

const C_BG: Color = Color("#14231f")
const C_PANEL: Color = Color(0.09, 0.15, 0.14, 0.94)
const C_PAPER: Color = Color("#e9dcb4")
const C_INK: Color = Color("#2b2418")
const C_GOLD: Color = Color("#f2d58a")
const C_GREEN: Color = Color("#6fcf8e")
const C_RED: Color = Color("#e0675a")
const C_BLUE: Color = Color("#7fc4ff")
const C_ORANGE: Color = Color("#f0b060")
const C_TEXT: Color = Color("#f4efe0")
const C_DIM: Color = Color(0.85, 0.85, 0.8, 0.6)
const GRADE_COLORS: Array[Color] = [Color("#e0675a"), Color("#f0b060"), Color("#7fc4ff"), Color("#7fdc8f"), Color("#ffd966")]

var area: Rect2 = Rect2(16, 12, 1248, 696)
var time: float = 0.0
var title_text: String = ""
var allow_exit: bool = true

var _buttons: Array[Dictionary] = []
var _dirty: bool = true
var _pressed_btn: int = -1
var _pressed_touch: int = -2
var _result: MinigameResult = null
var _awards: Array = []
var _result_lines: Array[String] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func layout(vis: Vector2, safe: Rect2) -> void:
	position = Vector2.ZERO
	size = vis
	area = safe.grow(-14.0)
	_dirty = true
	_on_layout()
	queue_redraw()


## Hook untuk subkelas bila ukuran area berubah.
func _on_layout() -> void:
	pass


func _process(delta: float) -> void:
	time += delta
	if _result == null:
		_tick(delta)
	queue_redraw()


## Dipanggil tiap frame selama minigame berjalan (bukan di layar hasil).
func _tick(_delta: float) -> void:
	pass


func mark_dirty() -> void:
	_dirty = true


# --- Input ------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		var p: Vector2 = _to_local(t.position)
		if t.pressed:
			press_at(p, t.index)
		else:
			release_at(p, t.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		drag_to(_to_local(d.position), d.index)
		get_viewport().set_input_as_handled()


func _to_local(canvas_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * canvas_pos


func _ensure_built() -> void:
	if not _dirty:
		return
	_dirty = false
	_buttons.clear()
	if _result != null:
		_build_result()
	else:
		_build()
		if allow_exit:
			_add_button("exit", Rect2(area.position, Vector2(150.0, 60.0)), Locale.t("ui.postpone"), true, "ghost")


## Subkelas menambahkan tombol dengan `_add_button` sesuai keadaan.
func _build() -> void:
	pass


## mode: "tap" (aksi saat dilepas di dalam), "down" (aksi saat disentuh), "hold" (down lalu up).
func _add_button(id: String, rect: Rect2, text: String, enabled: bool = true, style: String = "normal", mode: String = "tap") -> void:
	_buttons.append({"id": id, "rect": rect, "text": text, "enabled": enabled, "style": style, "mode": mode})


func button_ids() -> Array[String]:
	_ensure_built()
	var out: Array[String] = []
	for b in _buttons:
		out.append(String(b["id"]))
	return out


func button_enabled(id: String) -> bool:
	_ensure_built()
	for b in _buttons:
		if String(b["id"]) == id:
			return bool(b["enabled"])
	return false


func button_rect(id: String) -> Rect2:
	_ensure_built()
	for b in _buttons:
		if String(b["id"]) == id:
			return b["rect"]
	return Rect2()


## Tekan tombol berdasarkan id (jalur uji; sama seperti sentuhan tap di tombol). False bila tak ada/nonaktif.
func click_button(id: String) -> bool:
	_ensure_built()
	for b in _buttons:
		if String(b["id"]) == id and bool(b["enabled"]):
			_dispatch(id, "tap")
			return true
	return false


func press_at(p: Vector2, index: int = 0) -> void:
	_ensure_built()
	for i in range(_buttons.size() - 1, -1, -1):
		var b: Dictionary = _buttons[i]
		var r: Rect2 = b["rect"]
		if bool(b["enabled"]) and r.has_point(p):
			var mode: String = String(b["mode"])
			if mode == "tap":
				_pressed_btn = i
				_pressed_touch = index
			else:
				_dispatch(String(b["id"]), "down")
				if mode == "hold":
					_pressed_btn = i
					_pressed_touch = index
			return
	_on_press(p, index)


func release_at(p: Vector2, index: int = 0) -> void:
	if _pressed_touch == index and _pressed_btn >= 0 and _pressed_btn < _buttons.size():
		var b: Dictionary = _buttons[_pressed_btn]
		var r: Rect2 = b["rect"]
		var mode: String = String(b["mode"])
		_pressed_btn = -1
		_pressed_touch = -2
		if mode == "hold":
			_dispatch(String(b["id"]), "up")
		elif mode == "tap" and r.has_point(p):
			_dispatch(String(b["id"]), "tap")
		return
	_on_release(p, index)


func drag_to(p: Vector2, index: int = 0) -> void:
	if _pressed_touch == index and _pressed_btn >= 0:
		return
	_on_drag(p, index)


func tap(p: Vector2) -> void:
	press_at(p)
	release_at(p)


func _dispatch(id: String, phase: String) -> void:
	if phase != "up" and id == "result_continue":
		finished.emit(_result, _awards)
		return
	if id == "exit" and phase == "tap":
		cancelled.emit()
		return
	_on_button(id, phase)


## id tombol, phase: "tap" | "down" | "up".
func _on_button(_id: String, _phase: String) -> void:
	pass


func _on_press(_p: Vector2, _index: int) -> void:
	pass


func _on_release(_p: Vector2, _index: int) -> void:
	pass


func _on_drag(_p: Vector2, _index: int) -> void:
	pass


# --- Hasil ------------------------------------------------------------------

func show_result(result: MinigameResult, awards: Array, lines: Array[String]) -> void:
	_result = result
	_awards = awards
	_result_lines = lines
	_pressed_btn = -1
	_pressed_touch = -2
	_dirty = true


func has_result() -> bool:
	return _result != null


func get_result() -> MinigameResult:
	return _result


func _build_result() -> void:
	var w: float = 320.0
	_add_button("result_continue", Rect2(area.get_center().x - w * 0.5, area.end.y - 100.0, w, 76.0), Locale.t("ui.next"), true, "primary")


func _result_panel() -> Rect2:
	var w: float = minf(area.size.x - 40.0, 960.0)
	var h: float = minf(area.size.y - 120.0, 560.0)
	return Rect2(area.get_center().x - w * 0.5, area.position.y + 16.0, w, h)


func _draw_result() -> void:
	var panel: Rect2 = _result_panel()
	_box(panel, C_PANEL, C_GOLD, 22, 3)
	var gcol: Color = GRADE_COLORS[clampi(_result.grade, 0, 4)]
	_t(panel.position.x + 30.0, panel.position.y + 18.0, Locale.t("minigame.title.%s" % _result.kind), 30, C_GOLD)
	if not _result_lines.is_empty():
		_t(panel.position.x + 30.0, panel.position.y + 58.0, _result_lines[0], 22, C_TEXT)
	var cx: float = panel.position.x + 30.0 + 110.0
	var cy: float = panel.position.y + 230.0
	draw_circle(Vector2(cx, cy), 104.0, Color(0, 0, 0, 0.35))
	draw_arc(Vector2(cx, cy), 100.0, 0.0, TAU, 48, gcol, 8.0)
	_t(cx - 100.0, cy - 62.0, _result.letter(), 112, gcol, HORIZONTAL_ALIGNMENT_CENTER, 200.0)
	_t(cx - 110.0, cy + 112.0, Locale.t(Grade.name_key(_result.grade)), 28, gcol, HORIZONTAL_ALIGNMENT_CENTER, 220.0)
	_t(cx - 110.0, cy + 146.0, Locale.t("minigame.score", {"score": int(roundf(_result.score))}), 22, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, 220.0)
	var bx: float = panel.position.x + 290.0
	var by: float = panel.position.y + 100.0
	var bw: float = panel.size.x - 290.0 - 40.0
	for k in _result.components.keys():
		var v: float = clampf(float(_result.components[k]), 0.0, 1.0)
		_t(bx, by, Locale.t("comp.%s" % str(k)), 21, C_TEXT)
		var track := Rect2(bx + 190.0, by + 6.0, bw - 190.0 - 60.0, 18.0)
		_box(track, Color(0, 0, 0, 0.4), Color(0, 0, 0, 0), 9, 0)
		var fill := Rect2(track.position, Vector2(track.size.x * v, track.size.y))
		if fill.size.x > 2.0:
			_box(fill, C_GREEN.lerp(C_RED, 1.0 - v), Color(0, 0, 0, 0), 9, 0)
		_t(track.end.x + 10.0, by, "%d%%" % int(roundf(v * 100.0)), 20, C_DIM)
		by += 36.0
	by += 6.0
	for i in range(1, _result_lines.size()):
		by += _para(bx, by, _result_lines[i], bw, 21, C_TEXT) + 6.0
	var ay: float = panel.end.y - 38.0
	var xp_total: String = ""
	for a in _awards:
		var ad: Dictionary = a
		if int(ad.get("xp", 0)) > 0:
			xp_total += "+%d XP %s   " % [int(ad["xp"]), Locale.t("skill.%s" % str(ad["branch"]))]
	_t(panel.position.x + 30.0, ay - 34.0, xp_total, 21, C_GOLD)
	var ups: String = ""
	for a in _awards:
		var ad2: Dictionary = a
		if int(ad2.get("levels_gained", 0)) > 0:
			ups += Locale.t("minigame.level_up", {"skill": Locale.t("skill.%s" % str(ad2["branch"])), "level": int(ad2["level"])}) + "   "
	_t(panel.position.x + 30.0, ay - 4.0, ups, 22, C_GREEN)


# --- Gambar -----------------------------------------------------------------

func _draw() -> void:
	_ensure_built()
	draw_rect(Rect2(Vector2.ZERO, size), C_BG)
	draw_rect(Rect2(0, 0, size.x, size.y * 0.5), Color(1, 1, 1, 0.025))
	if _result != null:
		_draw_result()
	else:
		_draw_content()
	_draw_buttons()


func _draw_content() -> void:
	pass


func _draw_buttons() -> void:
	for i in range(_buttons.size()):
		var b: Dictionary = _buttons[i]
		var r: Rect2 = b["rect"]
		var enabled: bool = bool(b["enabled"])
		var down: bool = i == _pressed_btn
		var style: String = String(b["style"])
		if style == "invisible":
			continue
		var fill: Color = Color(0.15, 0.35, 0.28, 0.92)
		var border: Color = Color(1, 1, 1, 0.45)
		if style == "primary":
			fill = Color(0.78, 0.52, 0.12, 0.96)
			border = C_GOLD
		elif style == "ghost":
			fill = Color(0.1, 0.14, 0.15, 0.8)
		elif style == "danger":
			fill = Color(0.6, 0.2, 0.16, 0.95)
		if down:
			fill = fill.lightened(0.25)
		if not enabled:
			fill = Color(0.18, 0.2, 0.2, 0.7)
			border = Color(1, 1, 1, 0.15)
		_box(r, fill, border, int(minf(r.size.x, r.size.y) * 0.22), 3)
		var fs: int = int(clampf(r.size.y * 0.36, 18.0, 34.0))
		var col: Color = C_TEXT if enabled else Color(1, 1, 1, 0.4)
		_t(r.position.x, r.position.y + (r.size.y - float(fs)) * 0.5 - 2.0, String(b["text"]), fs, col, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


# --- Penolong gambar --------------------------------------------------------

func _box(r: Rect2, fill: Color, border: Color = Color(0, 0, 0, 0), radius: int = 14, bw: int = 3) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	if bw > 0 and border.a > 0.0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	draw_style_box(sb, r)


## Teks dengan sudut kiri-atas (x, y). Untuk rata tengah/kanan beri `width` kotak.
func _t(x: float, y: float, text: String, fsize: int, color: Color = C_TEXT, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(x, y + font.get_ascent(fsize)), text, align, width, fsize, color)


## Paragraf berlipat; mengembalikan tinggi yang dipakai.
func _para(x: float, y: float, text: String, width: float, fsize: int, color: Color = C_TEXT, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> float:
	var font: Font = ThemeDB.fallback_font
	draw_multiline_string(font, Vector2(x, y + font.get_ascent(fsize)), text, align, width, fsize, -1, color)
	return font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, fsize).y


func _pips(x: float, y: float, filled: int, total: int, color: Color) -> void:
	for i in range(total):
		var c := Vector2(x + float(i) * 34.0, y)
		draw_circle(c, 12.0, Color(0, 0, 0, 0.4))
		if i < filled:
			draw_circle(c, 9.0, color)
		else:
			draw_arc(c, 9.0, 0.0, TAU, 20, Color(1, 1, 1, 0.35), 2.0)


func _check_mark(c: Vector2, r: float, color: Color) -> void:
	draw_polyline(PackedVector2Array([c + Vector2(-r * 0.5, 0.0), c + Vector2(-r * 0.1, r * 0.4), c + Vector2(r * 0.55, -r * 0.45)]), color, 4.0)
