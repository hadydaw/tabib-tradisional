class_name PlantView
extends MinigameView
## Tampilan minigame identifikasi tanaman: tanaman utuh (sebagian bisa tertutup kabut), tombol amati bagian,
## pembesaran bagian yang diamati, dan kartu pilihan identitas dengan catatan ciri bagian yang sudah diamati.

signal completed(result: MinigameResult)

var sys: PlantIdentificationSystem
var spot_label: String = ""
var current_part: String = ""

var _msg: String = ""
var _msg_t: float = 0.0
var _msg_color: Color = C_GOLD
var _flash_opt: String = ""
var _flash_t: float = 0.0


func setup(p_sys: PlantIdentificationSystem, p_spot_label: String) -> void:
	sys = p_sys
	spot_label = p_spot_label
	title_text = Locale.t("minigame.title.identifikasi")
	_dirty = true


func _tick(delta: float) -> void:
	if sys == null:
		return
	sys.update(delta)
	if _msg_t > 0.0:
		_msg_t -= delta
	if _flash_t > 0.0:
		_flash_t -= delta


func _say(text: String, color: Color = C_GOLD) -> void:
	_msg = text
	_msg_t = 3.0
	_msg_color = color


func plant_rect() -> Rect2:
	return Rect2(area.position.x, area.position.y + 78.0, 400.0, 340.0)


func part_rect(i: int) -> Rect2:
	return Rect2(area.position.x + 420.0 + float(i) * 205.0, area.position.y + 66.0, 195.0, 70.0)


func detail_rect() -> Rect2:
	return Rect2(area.position.x + 420.0, area.position.y + 150.0, 820.0, 200.0)


func option_rect(i: int) -> Rect2:
	var n: int = maxi(1, sys.options.size())
	var gap: float = 10.0
	var w: float = (area.size.x - gap * float(n - 1)) / float(n)
	return Rect2(area.position.x + float(i) * (w + gap), area.position.y + 462.0, w, 160.0)


func _build() -> void:
	if sys == null or sys.is_finished():
		return
	for i in range(HerbDb.PARTS.size()):
		var part: String = HerbDb.PARTS[i]
		_add_button("part:%s" % part, part_rect(i), Locale.t("part.%s" % part), true, "primary" if current_part == part else "normal")
	for i in range(sys.options.size()):
		var oid: String = sys.options[i]
		_add_button("opt:%s" % oid, option_rect(i), "", not sys.eliminated(oid), "invisible")


func _on_button(id: String, phase: String) -> void:
	if phase != "tap" or sys == null:
		return
	if id.begins_with("part:"):
		look(id.substr(5))
	elif id.begins_with("opt:"):
		choose(id.substr(4))


## Amati satu bagian tanaman.
func look(part: String) -> void:
	current_part = part
	if sys.is_hidden(part):
		_say(Locale.t("plant.hidden", {"part": Locale.t("part.%s" % part)}), C_ORANGE)
	else:
		sys.observe(part)
	_dirty = true


## Pilih identitas tanaman.
func choose(option_id: String) -> void:
	var r: Dictionary = sys.guess(option_id)
	if not bool(r.get("ok", false)):
		return
	_flash_opt = option_id
	_flash_t = 1.0
	if bool(r["finished"]):
		completed.emit(sys.result)
	else:
		_say(Locale.t("plant.wrong_try"), C_RED)
	_dirty = true


func _draw_content() -> void:
	if sys == null:
		return
	_t(area.position.x + 170.0, area.position.y + 6.0, "%s — %s" % [title_text, spot_label], 30, C_GOLD)
	# tanaman
	var pr: Rect2 = plant_rect()
	_box(pr, Color(0.55, 0.78, 0.9, 0.35), Color(1, 1, 1, 0.3), 16, 2)
	PlantArt.draw_plant(self, sys.plant_id, pr, sys.hidden_parts)
	_para(pr.position.x, pr.end.y + 6.0, Locale.t("plant.help"), 400.0, 18, C_DIM)
	# pembesaran
	var dr: Rect2 = detail_rect()
	_box(dr, Color(0.07, 0.12, 0.11, 0.9), Color(1, 1, 1, 0.3), 16, 2)
	if current_part == "":
		_t(dr.position.x + 16.0, dr.position.y + 70.0, Locale.t("plant.pick_part"), 26, C_DIM)
	elif sys.is_hidden(current_part):
		_t(dr.position.x + 16.0, dr.position.y + 70.0, Locale.t("plant.hidden", {"part": Locale.t("part.%s" % current_part)}), 26, C_ORANGE)
	else:
		var key: String = HerbDb.trait_of(sys.plant_id, current_part)
		var c := Vector2(dr.position.x + 150.0, dr.position.y + 110.0)
		match current_part:
			"daun":
				PlantArt.draw_leaf(self, key, Vector2(c.x - 90.0, c.y + 40.0), -0.35, 190.0)
			"bunga":
				PlantArt.draw_flower(self, key, c, 120.0)
			"akar":
				PlantArt.draw_root(self, key, c, 120.0)
			"buah":
				PlantArt.draw_fruit(self, key, c, 120.0)
		_t(dr.position.x + 330.0, dr.position.y + 30.0, Locale.t("part.%s" % current_part), 28, C_GOLD)
		_para(dr.position.x + 330.0, dr.position.y + 76.0, Locale.t("trait.%s.%s" % [current_part, key]), 460.0, 28, C_TEXT)
	# catatan jumlah pengamatan
	_t(area.position.x + 420.0, area.position.y + 360.0, Locale.t("plant.observed", {"n": sys.observed.size(), "total": sys.visible_parts().size()}), 22, C_TEXT)
	_t(area.position.x + 420.0, area.position.y + 392.0, Locale.t("plant.tries", {"n": PlantIdentificationSystem.MAX_GUESSES - sys.guesses.size()}), 22, C_DIM)
	if sys.evidence_sufficient():
		_t(area.position.x + 420.0, area.position.y + 424.0, Locale.t("plant.enough"), 22, C_GREEN)
	# pilihan
	for i in range(sys.options.size()):
		var oid: String = sys.options[i]
		var r: Rect2 = option_rect(i)
		var gone: bool = sys.eliminated(oid)
		var fill := Color(0.13, 0.22, 0.2, 0.95) if not gone else Color(0.35, 0.12, 0.1, 0.7)
		_box(r, fill, C_GOLD if (_flash_t > 0.0 and _flash_opt == oid) else Color(1, 1, 1, 0.3), 14, 2)
		_t(r.position.x, r.position.y + 6.0, Locale.t("herb.%s" % oid), 24, C_TEXT if not gone else C_DIM, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		var y: float = r.position.y + 44.0
		for part in sys.observed:
			var tk: String = HerbDb.trait_of(oid, String(part))
			_t(r.position.x + 8.0, y, "%s: %s" % [Locale.t("part.%s" % part), Locale.t("trait.%s.%s" % [part, tk])], 15, C_TEXT if not gone else C_DIM, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12.0)
			y += 22.0
	if _msg_t > 0.0 and _msg != "":
		_t(area.position.x, area.end.y - 52.0, _msg, 26, Color(_msg_color.r, _msg_color.g, _msg_color.b, clampf(_msg_t, 0.0, 1.0)), HORIZONTAL_ALIGNMENT_CENTER, area.size.x)
