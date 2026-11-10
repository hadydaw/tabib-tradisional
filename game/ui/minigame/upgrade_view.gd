class_name UpgradeView
extends MinigameView
## Layar Upgrade Klinik: kartu per fasilitas dengan tingkat, efek nyata, biaya & syarat, dan tombol Beli.

signal closed
signal purchased(upgrade_id: String, result: Dictionary)

var upgrades: ClinicUpgrades
var stats: ClinicStats
var skills: SkillProgressionSystem
var message: String = ""
var message_color: Color = MinigameView.C_TEXT


func setup(p_upgrades: ClinicUpgrades, p_stats: ClinicStats, p_skills: SkillProgressionSystem) -> void:
	upgrades = p_upgrades
	stats = p_stats
	skills = p_skills
	title_text = Locale.t("upgrade.title")
	allow_exit = false
	stats.money_changed.connect(_on_money)
	_dirty = true


func card_rect(i: int) -> Rect2:
	var col: int = i % 2
	var row: int = i / 2
	var w: float = (area.size.x - 20.0) / 2.0
	return Rect2(area.position.x + float(col) * (w + 20.0), area.position.y + 104.0 + float(row) * 156.0, w, 146.0)


func _build() -> void:
	for i in range(ClinicUpgrades.IDS.size()):
		var id: String = ClinicUpgrades.IDS[i]
		var r: Rect2 = card_rect(i)
		var chk: Dictionary = upgrades.check(id, stats, skills)
		var label: String = Locale.t("upgrade.max_btn") if upgrades.is_max(id) else Locale.t("upgrade.buy")
		_add_button("up:%s" % id, Rect2(r.end.x - 150.0, r.end.y - 66.0, 138.0, 56.0), label, bool(chk["ok"]), "primary")
	_add_button("up_close", Rect2(area.get_center().x - 170.0, area.end.y - 86.0, 340.0, 76.0), Locale.t("ui.close"), true, "ghost")


func _on_button(id: String, phase: String) -> void:
	if phase != "tap":
		return
	if id == "up_close":
		closed.emit()
	elif id.begins_with("up:"):
		do_buy(id.substr(3))


func do_buy(upgrade_id: String) -> Dictionary:
	var res: Dictionary = upgrades.buy(upgrade_id, stats, skills)
	if bool(res["ok"]):
		message = Locale.t("upgrade.bought", {"name": Locale.t("upgrade.%s.name" % upgrade_id), "cost": int(res["cost"])})
		message_color = C_GREEN
	else:
		message = EconomyText.upgrade_status(res, int(res.get("cost", 0)))
		message_color = C_RED
	_dirty = true
	purchased.emit(upgrade_id, res)
	return res


func _draw_content() -> void:
	_t(area.position.x + 170.0, area.position.y + 6.0, Locale.t("upgrade.title"), 34, C_GOLD)
	_t(area.end.x - 420.0, area.position.y + 10.0, Locale.t("shop.coins", {"money": stats.money}), 30, C_GOLD, HORIZONTAL_ALIGNMENT_RIGHT, 420.0)
	_para(area.position.x, area.position.y + 62.0, Locale.t("upgrade.help", {"cost": upgrades.operating_cost()}), area.size.x, 20, C_DIM)
	for i in range(ClinicUpgrades.IDS.size()):
		var id: String = ClinicUpgrades.IDS[i]
		var r: Rect2 = card_rect(i)
		var chk: Dictionary = upgrades.check(id, stats, skills)
		_box(r, Color(0.13, 0.24, 0.2, 0.92), C_GOLD if upgrades.is_max(id) else Color(1, 1, 1, 0.3), 16, 3 if upgrades.is_max(id) else 2)
		_t(r.position.x + 16.0, r.position.y + 8.0, Locale.t("upgrade.%s.name" % id), 26, C_TEXT)
		_pips(r.end.x - 90.0, r.position.y + 24.0, upgrades.level(id), ClinicUpgrades.max_level(id), C_GOLD)
		_para(r.position.x + 16.0, r.position.y + 42.0, Locale.t("upgrade.%s.effect" % id), r.size.x - 32.0, 18, C_DIM)
		var col: Color = C_GREEN if bool(chk["ok"]) else (C_DIM if upgrades.is_max(id) else C_ORANGE)
		var st: String = EconomyText.upgrade_status(chk, int(chk.get("cost", 0)) if not upgrades.is_max(id) else 0)
		_para(r.position.x + 16.0, r.end.y - 62.0, st, r.size.x - 180.0, 17, col)
	if message != "":
		_t(area.position.x, area.end.y - 70.0, message, 22, message_color)


func _on_money(_d: int, _r: String, _t: int) -> void:
	_dirty = true


func _exit_tree() -> void:
	if stats.money_changed.is_connected(_on_money):
		stats.money_changed.disconnect(_on_money)
