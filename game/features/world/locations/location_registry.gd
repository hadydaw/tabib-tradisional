class_name LocationRegistry
extends RefCounted
## Daftar lokasi yang ada. Id lokasi dipakai oleh perpindahan (LocationData.transitions).

const IDS: Array[String] = ["desa", "klinik"]
const START_LOCATION: String = "desa"
const START_SPAWN: String = "awal"

static var _cache: Dictionary = {}


static func has_location(id: String) -> bool:
	return IDS.has(id)


static func get_location(id: String) -> LocationData:
	if not has_location(id):
		return null
	if not _cache.has(id):
		match id:
			"desa": _cache[id] = VillageLocation.build()
			"klinik": _cache[id] = ClinicLocation.build()
	return _cache[id]
