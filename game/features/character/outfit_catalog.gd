class_name OutfitCatalog
extends RefCounted
## Katalog pakaian placeholder. Nama bersifat netral dan sementara; pilihan pakaian khas daerah
## menunggu peninjauan budaya (P-17) dan keputusan gaya seni (P-04).

const EMPTY: String = ""

static var _items: Dictionary = {}
static var _order: Array[String] = []


static func _ensure() -> void:
	if not _items.is_empty():
		return
	var list: Array[OutfitItem] = [
		OutfitItem.make("top_polos_hijau", OutfitItem.Slot.TOP, "Baju Polos Hijau", "polos", Color("#3d7a5a")),
		OutfitItem.make("top_polos_biru", OutfitItem.Slot.TOP, "Baju Polos Biru", "polos", Color("#3a5f8a")),
		OutfitItem.make("top_rompi_cokelat", OutfitItem.Slot.TOP, "Rompi Cokelat", "rompi", Color("#8a5a3a"), Color("#e8dcc0")),
		OutfitItem.make("top_jubah_tabib", OutfitItem.Slot.TOP, "Jubah Tabib", "jubah", Color("#4a7a6a"), Color("#e0c88a")),
		OutfitItem.make("bottom_celana_gelap", OutfitItem.Slot.BOTTOM, "Celana Gelap", "celana", Color("#2b3f35")),
		OutfitItem.make("bottom_celana_cokelat", OutfitItem.Slot.BOTTOM, "Celana Cokelat", "celana", Color("#6b4a30")),
		OutfitItem.make("bottom_kain_merah", OutfitItem.Slot.BOTTOM, "Kain Merah", "kain", Color("#9a4a3a"), Color("#e0c88a")),
		OutfitItem.make("bottom_kain_biru", OutfitItem.Slot.BOTTOM, "Kain Biru", "kain", Color("#3a5f8a"), Color("#e0c88a")),
		OutfitItem.make("head_ikat_kepala", OutfitItem.Slot.HEAD, "Ikat Kepala", "ikat", Color("#b03a3a")),
		OutfitItem.make("head_caping", OutfitItem.Slot.HEAD, "Caping", "caping", Color("#d9b97a")),
		OutfitItem.make("head_kain_kepala", OutfitItem.Slot.HEAD, "Kain Kepala", "kain_kepala", Color("#2f3f6a")),
	]
	for item in list:
		_items[item.id] = item
		_order.append(item.id)


static func get_item(id: String) -> OutfitItem:
	_ensure()
	return _items.get(id, null)


static func has_item(id: String) -> bool:
	_ensure()
	return _items.has(id)


## Id pakaian untuk satu slot, urut katalog.
static func ids_for_slot(slot: int) -> Array[String]:
	_ensure()
	var out: Array[String] = []
	for id in _order:
		if (_items[id] as OutfitItem).slot == slot:
			out.append(id)
	return out


static func count() -> int:
	_ensure()
	return _items.size()


## Pakaian awal: baju polos hijau, celana gelap, tanpa penutup kepala.
static func default_outfit() -> Dictionary:
	return {
		OutfitItem.Slot.TOP: "top_jubah_tabib",
		OutfitItem.Slot.BOTTOM: "bottom_celana_gelap",
	}
