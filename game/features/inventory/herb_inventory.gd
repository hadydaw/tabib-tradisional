class_name HerbInventory
extends RefCounted
## Inventaris bahan herbal (logika murni, dites unit). Dipakai peracikan (mengambil bahan) dan
## identifikasi/kebun (menambah hasil panen). Stok harian dijamin minimal `DAILY_MIN` agar tidak buntu.

signal changed

const DAILY_MIN: int = 2

var stock: Dictionary = {}
var daily_min: int = DAILY_MIN   # naik lewat upgrade Rak Herbal Besar


func _init() -> void:
	for id in HerbDb.STARTER_STOCK.keys():
		stock[id] = int(HerbDb.STARTER_STOCK[id])


func count(herb_id: String) -> int:
	return int(stock.get(herb_id, 0))


func has(herb_id: String, n: int = 1) -> bool:
	return count(herb_id) >= n


func add(herb_id: String, n: int = 1) -> bool:
	if not HerbDb.has(herb_id) or n <= 0:
		return false
	stock[herb_id] = count(herb_id) + n
	changed.emit()
	return true


func remove(herb_id: String, n: int = 1) -> bool:
	if n <= 0 or count(herb_id) < n:
		return false
	stock[herb_id] = count(herb_id) - n
	changed.emit()
	return true


func total() -> int:
	var t: int = 0
	for k in stock.keys():
		t += int(stock[k])
	return t


func ids_in_stock() -> Array[String]:
	var out: Array[String] = []
	for id in HerbDb.IDS:
		if count(id) > 0:
			out.append(id)
	return out


## Pergantian hari: setiap bahan dijamin minimal DAILY_MIN (persediaan klinik).
func restock_daily() -> void:
	for id in HerbDb.IDS:
		if count(id) < daily_min:
			stock[id] = daily_min
	changed.emit()


func to_dict() -> Dictionary:
	return stock.duplicate()


func from_dict(d: Dictionary) -> void:
	for id in HerbDb.IDS:
		stock[id] = maxi(0, int(d.get(id, 0)))
	changed.emit()
