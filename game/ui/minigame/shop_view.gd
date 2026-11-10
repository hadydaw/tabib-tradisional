class_name ShopView
extends MinigameView
## Pasar bahan herbal: daftar 10 bahan, tombol Beli / Jual per bahan, koin dan stok tampil jelas.

signal closed
signal transaction(kind: String, herb_id: String, result: Dictionary)

var shop: ClinicShop
var message: String = ""
var message_color: Color = MinigameView.C_TEXT


func setup(p_shop: ClinicShop) -> void:
	shop = p_shop
	title_text = Locale.t("shop.title")
	allow_exit = false
	shop.stats.money_changed.connect(_on_money)
	_dirty = true


func row_rect(i: int) -> Rect2:
	var col: int = i % 2
	var row: int = i / 2
	var w: float = (area.size.x - 20.0) / 2.0
	return Rect2(area.position.x + float(col) * (w + 20.0), area.position.y + 112.0 + float(row) * 78.0, w, 70.0)


func _build() -> void:
	for i in range(HerbDb.IDS.size()):
		var id: String = HerbDb.IDS[i]
		var r: Rect2 = row_rect(i)
		_add_button("buy:%s" % id, Rect2(r.end.x - 270.0, r.position.y + 7.0, 126.0, 56.0),
			Locale.t("shop.buy", {"p": EconomyDb.buy_price(id)}), shop.stats.money >= EconomyDb.buy_price(id), "primary")
		_add_button("sell:%s" % id, Rect2(r.end.x - 136.0, r.position.y + 7.0, 126.0, 56.0),
			Locale.t("shop.sell", {"p": EconomyDb.sell_price(id)}), shop.inventory.count(id) > 0, "normal")
	_add_button("shop_close", Rect2(area.get_center().x - 170.0, area.end.y - 86.0, 340.0, 76.0), Locale.t("ui.close"), true, "ghost")


func _on_button(id: String, phase: String) -> void:
	if phase != "tap":
		return
	if id == "shop_close":
		closed.emit()
	elif id.begins_with("buy:"):
		do_buy(id.substr(4))
	elif id.begins_with("sell:"):
		do_sell(id.substr(5))


func do_buy(herb_id: String) -> Dictionary:
	var res: Dictionary = shop.buy(herb_id, 1)
	if bool(res["ok"]):
		message = Locale.t("shop.bought", {"name": Locale.t("herb.%s" % herb_id), "cost": int(res["cost"])})
		message_color = C_GREEN
	else:
		message = Locale.t("shop.no_money")
		message_color = C_RED
	_dirty = true
	transaction.emit("buy", herb_id, res)
	return res


func do_sell(herb_id: String) -> Dictionary:
	var res: Dictionary = shop.sell(herb_id, 1)
	if bool(res["ok"]):
		message = Locale.t("shop.sold", {"name": Locale.t("herb.%s" % herb_id), "gain": int(res["gain"])})
		message_color = C_GREEN
	else:
		message = Locale.t("shop.no_stock")
		message_color = C_RED
	_dirty = true
	transaction.emit("sell", herb_id, res)
	return res


func _draw_content() -> void:
	_t(area.position.x + 170.0, area.position.y + 6.0, Locale.t("shop.title"), 34, C_GOLD)
	_t(area.end.x - 420.0, area.position.y + 10.0, Locale.t("shop.coins", {"money": shop.stats.money}), 30, C_GOLD, HORIZONTAL_ALIGNMENT_RIGHT, 420.0)
	_para(area.position.x, area.position.y + 62.0, Locale.t("shop.help", {"pct": int(EconomyDb.SELL_RATIO * 100.0)}), area.size.x, 20, C_DIM)
	for i in range(HerbDb.IDS.size()):
		var id: String = HerbDb.IDS[i]
		var r: Rect2 = row_rect(i)
		_box(r, Color(0.13, 0.24, 0.2, 0.9), Color(1, 1, 1, 0.25), 14, 2)
		_t(r.position.x + 16.0, r.position.y + 8.0, Locale.t("herb.%s" % id), 26, C_TEXT)
		_t(r.position.x + 16.0, r.position.y + 40.0, Locale.t("shop.stock", {"n": shop.inventory.count(id)}), 20, C_DIM)
	if message != "":
		_t(area.position.x, area.end.y - 70.0, message, 24, message_color)


func _on_money(_d: int, _r: String, _t: int) -> void:
	_dirty = true


func _exit_tree() -> void:
	if shop.stats.money_changed.is_connected(_on_money):
		shop.stats.money_changed.disconnect(_on_money)
