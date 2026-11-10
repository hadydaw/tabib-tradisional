class_name ClinicShop
extends RefCounted
## Pasar bahan herbal: beli (harga EconomyDb) dan jual surplus (harga lebih murah). Logika murni, dites unit.

var stats: ClinicStats
var inventory: HerbInventory


func setup(p_stats: ClinicStats, p_inventory: HerbInventory) -> void:
	stats = p_stats
	inventory = p_inventory


## Beli `n` satuan. Hasil: {ok, reason ("money"|"unknown"), cost}.
func buy(herb_id: String, n: int = 1) -> Dictionary:
	var price: int = EconomyDb.buy_price(herb_id)
	if price <= 0 or n <= 0:
		return {"ok": false, "reason": "unknown", "cost": 0}
	var cost: int = price * n
	if stats.money < cost:
		return {"ok": false, "reason": "money", "cost": cost}
	if not stats.spend(cost, "beli:%s" % herb_id):
		return {"ok": false, "reason": "money", "cost": cost}
	inventory.add(herb_id, n)
	return {"ok": true, "reason": "", "cost": cost}


## Jual `n` satuan. Hasil: {ok, reason ("stock"|"unknown"), gain}.
func sell(herb_id: String, n: int = 1) -> Dictionary:
	var price: int = EconomyDb.sell_price(herb_id)
	if price <= 0 or n <= 0:
		return {"ok": false, "reason": "unknown", "gain": 0}
	if not inventory.remove(herb_id, n):
		return {"ok": false, "reason": "stock", "gain": 0}
	stats.add_money(price * n, "jual:%s" % herb_id)
	return {"ok": true, "reason": "", "gain": price * n}
