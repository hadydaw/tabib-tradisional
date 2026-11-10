class_name PuzzleView
extends MinigameView
## Teka-teki urutan simbol (Fase 9): pemain menyusun urutan dari empat simbol, lalu konfirmasi.
## Jawaban salah membuat urutan dikosongkan dan menampilkan umpan balik (lewat reject).

signal answered(seq: Array)

var subtitle: String = ""
var options: Array[String] = []
var needed: int = 0
var sequence: Array[String] = []
var feedback: String = ""


func setup(p_title: String, p_subtitle: String, p_options: Array[String], p_needed: int) -> void:
	title_text = p_title
	subtitle = p_subtitle
	options = p_options
	needed = p_needed
	_dirty = true


## Jawaban salah: kosongkan urutan dan tampilkan pesan.
func reject(message: String) -> void:
	sequence.clear()
	feedback = message
	_dirty = true


func _sym_rect(i: int) -> Rect2:
	var w: float = 220.0
	var gap: float = 24.0
	var total: float = float(options.size()) * w + float(options.size() - 1) * gap
	var x0: float = area.position.x + (area.size.x - total) * 0.5
	return Rect2(x0 + float(i) * (w + gap), area.position.y + 150.0, w, 150.0)


func _slot_rect(i: int) -> Rect2:
	var w: float = 170.0
	var gap: float = 18.0
	var total: float = float(needed) * w + float(needed - 1) * gap
	var x0: float = area.position.x + (area.size.x - total) * 0.5
	return Rect2(x0 + float(i) * (w + gap), area.position.y + 340.0, w, 96.0)


func _build() -> void:
	for i in range(options.size()):
		var sym: String = options[i]
		_add_button("sym:%s" % sym, _sym_rect(i), "", sequence.size() < needed, "invisible")
	_add_button("undo", Rect2(area.position.x, area.end.y - 86.0, 230.0, 76.0), Locale.t("fr.puzzle_undo"),
		not sequence.is_empty(), "normal")
	_add_button("confirm", Rect2(area.end.x - 360.0, area.end.y - 86.0, 350.0, 76.0), Locale.t("ui.confirm"),
		sequence.size() == needed, "primary")


func _on_button(id: String, phase: String) -> void:
	if phase != "tap":
		return
	if id.begins_with("sym:"):
		if sequence.size() < needed:
			sequence.append(id.substr(4))
			feedback = ""
			_dirty = true
	elif id == "undo":
		if not sequence.is_empty():
			sequence.pop_back()
			_dirty = true
	elif id == "confirm":
		answered.emit(sequence.duplicate())


func _draw_content() -> void:
	_t(area.position.x, area.position.y + 6.0, title_text, 34, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, area.size.x)
	if subtitle != "":
		_para(area.position.x, area.position.y + 64.0, subtitle, area.size.x, 24, C_TEXT)
	for i in range(options.size()):
		var sym: String = options[i]
		var r: Rect2 = _sym_rect(i)
		_box(r, Color(0.13, 0.24, 0.2, 0.95), Color(1, 1, 1, 0.3), 16, 2)
		_t(r.position.x, r.position.y + 50.0, Locale.t("fr.sym.%s" % sym), 30, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	for i in range(needed):
		var s: Rect2 = _slot_rect(i)
		var filled: bool = i < sequence.size()
		_box(s, Color(0.2, 0.2, 0.16, 0.95) if filled else Color(0.12, 0.12, 0.12, 0.8), C_GOLD if filled else Color(1, 1, 1, 0.25), 14, 3)
		var label: String = Locale.t("fr.sym.%s" % sequence[i]) if filled else "%d" % (i + 1)
		_t(s.position.x, s.position.y + 30.0, label, 26, C_TEXT if filled else C_DIM, HORIZONTAL_ALIGNMENT_CENTER, s.size.x)
	if feedback != "":
		_para(area.position.x, area.position.y + 460.0, feedback, area.size.x, 24, C_GOLD)
