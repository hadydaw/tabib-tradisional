class_name CharacterAppearance
extends Resource
## Data tampilan karakter: warna kulit, rambut, dan pakaian per slot. Satu sumber untuk
## pemain, NPC, dan pembuat karakter. Mengirim sinyal `changed` bila ada perubahan.
## Bisa diserialisasi (to_dict/from_dict) untuk Save System nanti.

@export var display_name: String = "Tabib"
@export var skin_index: int = 1
@export var hair_style: int = 1
@export var hair_color_index: int = 0
## slot (OutfitItem.Slot) -> id pakaian. Slot yang tidak ada = kosong.
var outfit: Dictionary = {}


func _init() -> void:
	outfit = OutfitCatalog.default_outfit()


func skin_color() -> Color:
	return CharacterPalette.SKIN_TONES[clampi(skin_index, 0, CharacterPalette.SKIN_TONES.size() - 1)]


func hair_color() -> Color:
	return CharacterPalette.HAIR_COLORS[clampi(hair_color_index, 0, CharacterPalette.HAIR_COLORS.size() - 1)]


func hair_style_name() -> String:
	return CharacterPalette.HAIR_STYLES[clampi(hair_style, 0, CharacterPalette.HAIR_STYLES.size() - 1)]


## Pakaian di slot, atau null bila kosong.
func item_in(slot: int) -> OutfitItem:
	var id: String = outfit.get(slot, OutfitCatalog.EMPTY)
	return OutfitCatalog.get_item(id)


## Pasang pakaian menurut id; menggantikan yang ada di slot itu. False bila id tidak dikenal.
func equip(id: String) -> bool:
	var item: OutfitItem = OutfitCatalog.get_item(id)
	if item == null:
		return false
	outfit[item.slot] = id
	emit_changed()
	return true


func unequip(slot: int) -> void:
	if outfit.erase(slot):
		emit_changed()


func set_skin(index: int) -> void:
	skin_index = posmod(index, CharacterPalette.SKIN_TONES.size())
	emit_changed()


func set_hair_style(index: int) -> void:
	hair_style = posmod(index, CharacterPalette.HAIR_STYLES.size())
	emit_changed()


func set_hair_color(index: int) -> void:
	hair_color_index = posmod(index, CharacterPalette.HAIR_COLORS.size())
	emit_changed()


## Pilihan slot: HEAD boleh kosong; TOP dan BOTTOM selalu terisi.
func options_for_slot(slot: int) -> Array[String]:
	var options: Array[String] = []
	if slot == OutfitItem.Slot.HEAD:
		options.append(OutfitCatalog.EMPTY)
	options.append_array(OutfitCatalog.ids_for_slot(slot))
	return options


## Maju/mundur ke pakaian berikutnya di slot (berputar).
func cycle_outfit(slot: int, step: int = 1) -> void:
	var options: Array[String] = options_for_slot(slot)
	if options.is_empty():
		return
	var current: String = outfit.get(slot, OutfitCatalog.EMPTY)
	var idx: int = options.find(current)
	if idx < 0:
		idx = 0
	var next_id: String = options[posmod(idx + step, options.size())]
	if next_id == OutfitCatalog.EMPTY:
		unequip(slot)
	else:
		equip(next_id)


func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for slot in outfit:
		out[str(slot)] = outfit[slot]
	return {
		"name": display_name, "skin": skin_index, "hair_style": hair_style,
		"hair_color": hair_color_index, "outfit": out,
	}


## Dari dictionary (misal hasil JSON); nilai tidak valid dibersihkan ke nilai aman.
static func from_dict(data: Dictionary) -> CharacterAppearance:
	var a := CharacterAppearance.new()
	a.display_name = str(data.get("name", "Tabib"))
	a.skin_index = posmod(int(data.get("skin", 1)), CharacterPalette.SKIN_TONES.size())
	a.hair_style = posmod(int(data.get("hair_style", 1)), CharacterPalette.HAIR_STYLES.size())
	a.hair_color_index = posmod(int(data.get("hair_color", 0)), CharacterPalette.HAIR_COLORS.size())
	var raw: Variant = data.get("outfit", null)
	if raw is Dictionary:
		a.outfit = {}
		for key in raw:
			var id: String = str(raw[key])
			var item: OutfitItem = OutfitCatalog.get_item(id)
			if item != null:
				a.outfit[item.slot] = id
		for slot in OutfitCatalog.default_outfit():
			if not a.outfit.has(slot):
				a.outfit[slot] = OutfitCatalog.default_outfit()[slot]
	return a
