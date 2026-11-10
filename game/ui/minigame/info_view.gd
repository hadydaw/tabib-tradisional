class_name InfoView
extends MinigameView
## Layar informasi satu halaman: ringkasan kunjungan pasien dan "Buku Tabib" (skill, bahan, tanaman, klinik).
## Baris: {text, size, color (opsional), indent (opsional)}.

signal closed

var heading: String = ""
var lines: Array[Dictionary] = []
var button_text: String = ""
var grade: int = -1


func setup(p_heading: String, p_lines: Array[Dictionary], p_button_text: String = "", p_grade: int = -1) -> void:
	heading = p_heading
	lines = p_lines
	button_text = p_button_text if p_button_text != "" else Locale.t("ui.next")
	grade = p_grade
	title_text = p_heading
	allow_exit = false
	_dirty = true


func _build() -> void:
	_add_button("info_close", Rect2(area.get_center().x - 170.0, area.end.y - 86.0, 340.0, 76.0), button_text, true, "primary")


func _on_button(id: String, phase: String) -> void:
	if id == "info_close" and phase == "tap":
		closed.emit()


func _draw_content() -> void:
	var panel := Rect2(area.position.x + 20.0, area.position.y + 6.0, area.size.x - 40.0, area.size.y - 108.0)
	_box(panel, C_PANEL, C_GOLD, 22, 3)
	_t(panel.position.x + 30.0, panel.position.y + 16.0, heading, 34, C_GOLD)
	var x0: float = panel.position.x + 30.0
	if grade >= 0:
		var gc: Color = GRADE_COLORS[clampi(grade, 0, 4)]
		var c := Vector2(panel.end.x - 120.0, panel.position.y + 110.0)
		draw_circle(c, 70.0, Color(0, 0, 0, 0.35))
		draw_arc(c, 66.0, 0.0, TAU, 40, gc, 7.0)
		_t(c.x - 66.0, c.y - 44.0, Grade.letter(grade), 80, gc, HORIZONTAL_ALIGNMENT_CENTER, 132.0)
	var y: float = panel.position.y + 70.0
	for ln in lines:
		var d: Dictionary = ln
		var fs: int = int(d.get("size", 22))
		var col: Color = d.get("color", C_TEXT)
		var ind: float = float(d.get("indent", 0.0))
		var h: float = _para(x0 + ind, y, String(d["text"]), panel.size.x - 60.0 - ind - (150.0 if grade >= 0 else 0.0), fs, col)
		y += maxf(h, float(fs) + 6.0) + 6.0
		if y > panel.end.y - 30.0:
			break
