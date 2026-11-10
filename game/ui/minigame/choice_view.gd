class_name ChoiceView
extends MinigameView
## Layar pilihan besar untuk ibu jari: daftar kartu (metode pengobatan, resep ramuan). Mendukung pilihan
## tunggal (langsung terkirim) atau ganda (tombol Konfirmasi). Data kartu: {id, title, sub, enabled}.

signal chosen(ids: Array)

var heading: String = ""
var subtitle: String = ""
var items: Array[Dictionary] = []
var multi: bool = false
var selected: Array[String] = []
var confirm_text: String = ""


func setup(p_title: String, p_subtitle: String, p_items: Array[Dictionary], p_multi: bool, p_confirm_text: String = "") -> void:
	heading = p_title
	subtitle = p_subtitle
	items = p_items
	multi = p_multi
	confirm_text = p_confirm_text if p_confirm_text != "" else Locale.t("ui.confirm")
	title_text = p_title
	_dirty = true


func card_rect(i: int) -> Rect2:
	var cols: int = 1 if items.size() <= 3 else 2
	var w: float = (area.size.x - 20.0 * float(cols - 1)) / float(cols)
	var h: float = 110.0 if cols == 2 else 124.0
	var col: int = i % cols
	var row: int = i / cols
	return Rect2(area.position.x + float(col) * (w + 20.0), area.position.y + 130.0 + float(row) * (h + 14.0), w, h)


func _build() -> void:
	for i in range(items.size()):
		var it: Dictionary = items[i]
		_add_button("item:%s" % String(it["id"]), card_rect(i), "", bool(it.get("enabled", true)), "invisible")
	if multi:
		_add_button("confirm", Rect2(area.end.x - 360.0, area.end.y - 86.0, 350.0, 76.0), confirm_text, not selected.is_empty(), "primary")


func _on_button(id: String, phase: String) -> void:
	if phase != "tap":
		return
	if id.begins_with("item:"):
		pick(id.substr(5))
	elif id == "confirm":
		chosen.emit(selected.duplicate())


## Pilih/ubah pilihan satu kartu (pilihan tunggal langsung terkirim).
func pick(item_id: String) -> void:
	if not multi:
		chosen.emit([item_id])
		return
	if selected.has(item_id):
		selected.erase(item_id)
	else:
		selected.append(item_id)
	_dirty = true


func _draw_content() -> void:
	_t(area.position.x + 170.0, area.position.y + 6.0, heading, 34, C_GOLD)
	if subtitle != "":
		_para(area.position.x, area.position.y + 76.0, subtitle, area.size.x, 24, C_TEXT)
	for i in range(items.size()):
		var it: Dictionary = items[i]
		var r: Rect2 = card_rect(i)
		var ok: bool = bool(it.get("enabled", true))
		var sel: bool = selected.has(String(it["id"]))
		var fill := Color(0.13, 0.24, 0.2, 0.95) if ok else Color(0.16, 0.16, 0.16, 0.75)
		_box(r, fill, C_GOLD if sel else Color(1, 1, 1, 0.3), 16, 4 if sel else 2)
		_t(r.position.x + 20.0, r.position.y + 12.0, String(it["title"]), 28, C_TEXT if ok else C_DIM)
		_para(r.position.x + 20.0, r.position.y + 54.0, String(it.get("sub", "")), r.size.x - 70.0, 20, C_DIM)
		if sel:
			_check_mark(Vector2(r.end.x - 34.0, r.position.y + 34.0), 22.0, C_GREEN)
