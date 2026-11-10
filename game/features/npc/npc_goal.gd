class_name NpcGoal
extends RefCounted
## Tujuan NPC sebagai Dictionary sederhana (data murni):
## loc (lokasi), spot (nama titik tujuan) atau cell (sel tepat), seat (sel kursi),
## home (masuk rumah saat tiba), wander (berkeliling kecil di titik itu), activity (id aktivitas),
## key (identitas tujuan; berubah = rencana ulang).

const NO_CELL: Vector2i = Vector2i(-1, -1)


static func at_spot(loc: String, spot: String, activity: String = "", wander: bool = false, home: bool = false) -> Dictionary:
	return {
		"loc": loc, "spot": spot, "cell": NO_CELL, "seat": false, "home": home,
		"wander": wander, "activity": activity, "key": "%s/%s/%s" % [loc, spot, activity],
	}


static func at_cell(loc: String, cell: Vector2i, seat: bool = false, activity: String = "") -> Dictionary:
	return {
		"loc": loc, "spot": "", "cell": cell, "seat": seat, "home": false,
		"wander": false, "activity": activity, "key": "%s/%d,%d/%s" % [loc, cell.x, cell.y, activity],
	}


static func go_home(home_spot: String) -> Dictionary:
	return at_spot("desa", home_spot, "di_rumah", false, true)


static func has_cell(goal: Dictionary) -> bool:
	return goal["cell"] != NO_CELL
