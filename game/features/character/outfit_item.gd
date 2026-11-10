class_name OutfitItem
extends Resource
## Satu potong pakaian/aksesori. Data murni (Resource); tampilan placeholder digambar
## CharacterView menurut `style`. Saat sprite final tiba, `id` menjadi nama lapisan sprite.

enum Slot { TOP, BOTTOM, HEAD }

@export var id: String = ""
@export var slot: Slot = Slot.TOP
@export var display_name: String = ""
@export var style: String = ""
@export var color: Color = Color.WHITE
@export var color2: Color = Color.WHITE


static func make(p_id: String, p_slot: Slot, p_name: String, p_style: String, p_color: Color, p_color2: Color = Color.WHITE) -> OutfitItem:
	var item := OutfitItem.new()
	item.id = p_id
	item.slot = p_slot
	item.display_name = p_name
	item.style = p_style
	item.color = p_color
	item.color2 = p_color2
	return item
