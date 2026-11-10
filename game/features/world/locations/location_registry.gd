class_name LocationRegistry
extends RefCounted
## Daftar lokasi yang ada. Id lokasi dipakai oleh perpindahan (LocationData.transitions).

const IDS: Array[String] = ["desa", "klinik", "hutan", "sungai", "pegunungan", "rawa", "gua"]
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
			"hutan": _cache[id] = ForestLocation.build()
			"sungai": _cache[id] = RiverLocation.build()
			"pegunungan": _cache[id] = MountainLocation.build()
			"rawa": _cache[id] = RawaLocation.build()
			"gua": _cache[id] = GuaLocation.build()
	return _cache[id]
