class_name GardenSystem
extends RefCounted
## Titik tanaman di dunia: petak kebun herbal (desa) dan tanaman liar (eksplorasi). Tiap titik menyediakan
## satu tanaman per hari (deterministik dari id titik + hari) untuk minigame identifikasi. Setelah dikerjakan,
## titik kosong sampai hari berikutnya. Logika murni, dites unit.

## id titik -> daftar tanaman yang bergiliran muncul.
const SPOTS: Dictionary = {
	"garden_plot_1": ["kunyit", "jahe", "serai", "temulawak"],
	"garden_plot_2": ["jahe", "kencur", "kunyit", "lengkuas"],
	"garden_plot_3": ["serai", "temulawak", "kencur", "sambiloto"],
	"garden_plot_4": ["lengkuas", "sambiloto", "kunyit", "kencur"],
	"wild_plant_kolam": ["kumis_kucing", "sambiloto", "sirih"],
	"wild_plant_sumur": ["sirih", "serai", "kencur"],
	"wild_plant_barat": ["kayu_manis", "kumis_kucing", "lengkuas"],
}

var done_day: Dictionary = {}   # id titik -> hari terakhir dikerjakan


static func is_spot(id: String) -> bool:
	return SPOTS.has(id)


static func is_wild(id: String) -> bool:
	return id.begins_with("wild_")


static func plant_for(spot_id: String, day: int) -> String:
	var list: Array = SPOTS.get(spot_id, [])
	if list.is_empty():
		return ""
	return String(list[(absi(spot_id.hash()) + day * 3) % list.size()])


func available(spot_id: String, day: int) -> bool:
	return is_spot(spot_id) and int(done_day.get(spot_id, -1)) != day


func mark_done(spot_id: String, day: int) -> void:
	if is_spot(spot_id):
		done_day[spot_id] = day


func to_dict() -> Dictionary:
	return done_day.duplicate()


func from_dict(d: Dictionary) -> void:
	done_day.clear()
	for k in d.keys():
		if is_spot(String(k)):
			done_day[String(k)] = int(d[k])
