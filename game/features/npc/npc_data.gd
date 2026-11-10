class_name NpcData
extends RefCounted
## Identitas dan jadwal satu penduduk. Data murni (dites unit). Nama dan peran dibaca lewat
## localization (`npc.<id>.name`, `npc.<id>.role`), bukan disimpan sebagai teks.

var id: String = ""
var age: int = 30
var home_spot: String = "rumah_1"
## Tampilan: {"skin", "hair_style", "hair_color", "top", "bottom", "head"} (head boleh "").
var look: Dictionary = {}
## Urut menurut "start" (menit 0..1439): {"start", "loc", "spot", "activity", "wander", "home"}.
var schedule: Array[Dictionary] = []
## Id permintaan sederhana yang bisa diberikan NPC ini ("" = tidak ada).
var request_id: String = ""


func name_key() -> String:
	return "npc.%s.name" % id


func role_key() -> String:
	return "npc.%s.role" % id


func entry_at(minute: int) -> Dictionary:
	if schedule.is_empty():
		return {}
	var m: int = posmod(minute, GameClock.MINUTES_PER_DAY)
	var best: Dictionary = schedule[schedule.size() - 1]  # sebelum entri pertama: lanjutan semalam
	for e in schedule:
		if int(e["start"]) <= m:
			best = e
		else:
			break
	return best


func goal_at(minute: int) -> Dictionary:
	var e: Dictionary = entry_at(minute)
	if e.is_empty():
		return NpcGoal.go_home(home_spot)
	return NpcGoal.at_spot(String(e["loc"]), String(e["spot"]), String(e["activity"]), bool(e.get("wander", false)), bool(e.get("home", false)))


func make_appearance() -> CharacterAppearance:
	var ap := CharacterAppearance.new()
	ap.skin_index = int(look.get("skin", 1))
	ap.hair_style = int(look.get("hair_style", 1))
	ap.hair_color_index = int(look.get("hair_color", 0))
	ap.outfit = {}
	for key in ["top", "bottom", "head"]:
		var oid: String = String(look.get(key, ""))
		if oid != "":
			ap.equip(oid)
	return ap
