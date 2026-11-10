class_name RequestLog
extends RefCounted
## Catatan permintaan NPC: NONE -> ACTIVE (diterima) -> READY (syarat terpenuhi) -> DONE (dilaporkan).
## Logika murni (dites unit); bisa diserialisasi untuk Save System nanti.

const NONE: int = 0
const ACTIVE: int = 1
const READY: int = 2
const DONE: int = 3

var _status: Dictionary = {}


func status(id: String) -> int:
	return int(_status.get(id, NONE))


func accept(id: String) -> bool:
	if RequestDef.get_def(id).is_empty() or status(id) != NONE:
		return false
	_status[id] = ACTIVE
	return true


## Lapor ke pemberi: hanya dari READY menjadi DONE.
func claim(id: String) -> bool:
	if status(id) != READY:
		return false
	_status[id] = DONE
	return true


func notify_talk(npc_id: String) -> Array[String]:
	return _notify(RequestDef.TALK_TO, npc_id)


func notify_zone(zone_name: String) -> Array[String]:
	return _notify(RequestDef.VISIT, zone_name)


func _notify(kind: String, target: String) -> Array[String]:
	var changed: Array[String] = []
	for id: String in _status.keys():
		if int(_status[id]) != ACTIVE:
			continue
		var d: Dictionary = RequestDef.get_def(id)
		if d["type"] == kind and d["target"] == target:
			_status[id] = READY
			changed.append(id)
	return changed


func active_ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in _status.keys():
		var s: int = int(_status[id])
		if s == ACTIVE or s == READY:
			out.append(id)
	return out


func to_dict() -> Dictionary:
	return _status.duplicate()


func from_dict(d: Dictionary) -> void:
	_status = {}
	for k: Variant in d.keys():
		var id: String = String(k)
		var s: int = clampi(int(d[k]), NONE, DONE)
		if not RequestDef.get_def(id).is_empty() and s != NONE:
			_status[id] = s
