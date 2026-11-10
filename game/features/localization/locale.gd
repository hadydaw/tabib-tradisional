class_name Locale
extends RefCounted
## Localization sederhana: tabel kunci -> teks per bahasa (JSON di res://localization/).
## Bahasa bawaan Indonesia ("id"); English ("en") jatuh kembali ke Indonesia bila kunci belum ada.
## Teks diambil lewat Locale.t (bukan tr, bentrok dengan Object.tr). Mendukung penanda {nama}. Logika murni, dites unit.

const LANGS: Array[String] = ["id", "en"]
const DEFAULT_LANG: String = "id"
const DIR: String = "res://localization/"

static var current: String = DEFAULT_LANG
static var _tables: Dictionary = {}


static func _table(lang: String) -> Dictionary:
	if _tables.has(lang):
		return _tables[lang]
	var table: Dictionary = {}
	var path: String = "%s%s.json" % [DIR, lang]
	var res: Resource = load(path)
	if res is JSON:
		var data: Variant = (res as JSON).data
		if data is Dictionary:
			table = data
	if table.is_empty() and FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			table = parsed
	_tables[lang] = table
	return table


static func set_language(lang: String) -> bool:
	if not LANGS.has(lang):
		return false
	current = lang
	return true


static func toggle_language() -> String:
	current = "en" if current == "id" else "id"
	return current


static func has_key(key: String, lang: String = "") -> bool:
	var l: String = lang if lang != "" else current
	return _table(l).has(key)


## Teks untuk `key` dengan penanda `{nama}` diganti dari `args`. Kunci tak dikenal -> kunci itu sendiri.
static func t(key: String, args: Dictionary = {}) -> String:
	var text: String = ""
	var t: Dictionary = _table(current)
	if t.has(key):
		text = String(t[key])
	else:
		var d: Dictionary = _table(DEFAULT_LANG)
		text = String(d[key]) if d.has(key) else key
	for k in args.keys():
		text = text.replace("{%s}" % str(k), str(args[k]))
	return text


static func keys(lang: String) -> Array:
	return _table(lang).keys()


## Kunci yang ada di bahasa dasar tetapi belum ada di `lang`.
static func missing_keys(lang: String) -> Array:
	var out: Array = []
	var t: Dictionary = _table(lang)
	for k in _table(DEFAULT_LANG).keys():
		if not t.has(k):
			out.append(k)
	return out
