class_name SaveSystem
extends RefCounted
## Simpan & muat kemajuan (Fase 6). Format JSON berversi di `user://save.json`, ditulis ATOMIK:
## tulis ke berkas sementara -> salin berkas lama jadi cadangan (.bak) -> ganti nama. Saat memuat, berkas utama yang
## hilang / rusak / versi tak dikenal otomatis jatuh ke cadangan, lalu ke permainan baru. Logika murni (tanpa node), dites unit.
##
## Isi: hari & jam, bahasa, lokasi, statistik klinik (koin, reputasi, buku kas, capaian), skill, inventaris,
## kebun, upgrade klinik. Pasien yang sedang antre / sesi minigame setengah jalan TIDAK disimpan
## (keadaan itu dibuat ulang dari jadwal hari itu).
##
## Saat tes headless (-s / --script) penyimpanan dimatikan agar tes tidak saling menimpa; tes penyimpanan
## memakai `override_dir` + `force_enabled`.

const VERSION: int = 1
const FILE_NAME: String = "save.json"
const BAK_NAME: String = "save.json.bak"
const TMP_NAME: String = "save.json.tmp"

enum Status { OK, MISSING, RESTORED_BACKUP, CORRUPT_NEW }

static var override_dir: String = ""
static var force_enabled: bool = false


static func enabled() -> bool:
	if force_enabled:
		return true
	var args: PackedStringArray = OS.get_cmdline_args()
	return not (args.has("--script") or args.has("-s"))


static func dir() -> String:
	return override_dir if override_dir != "" else "user://"


static func path(name: String = FILE_NAME) -> String:
	return dir().path_join(name)


static func exists() -> bool:
	return FileAccess.file_exists(path()) or FileAccess.file_exists(path(BAK_NAME))


# --- Tulis ------------------------------------------------------------------

## Tulis `data` (isi permainan) dengan pembungkus versi. True bila berhasil.
static func write(data: Dictionary) -> bool:
	var d: String = dir()
	if d != "user://" and not DirAccess.dir_exists_absolute(d):
		DirAccess.make_dir_recursive_absolute(d)
	var envelope: Dictionary = {"version": VERSION, "saved_at": int(Time.get_unix_time_from_system()), "data": data}
	var text: String = JSON.stringify(envelope, " ")
	var f := FileAccess.open(path(TMP_NAME), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.flush()
	f.close()
	# Berkas sementara harus utuh sebelum menggantikan yang lama.
	if not _parse(FileAccess.get_file_as_string(path(TMP_NAME))).has("data"):
		return false
	var da := DirAccess.open(d)
	if da == null:
		return false
	if FileAccess.file_exists(path()):
		da.copy(path(), path(BAK_NAME))
		da.remove(FILE_NAME)
	return da.rename(TMP_NAME, FILE_NAME) == OK


## Hapus semua berkas simpanan (permainan baru / tes).
static func delete_all() -> void:
	var da := DirAccess.open(dir())
	if da == null:
		return
	for n in [FILE_NAME, BAK_NAME, TMP_NAME]:
		if da.file_exists(n):
			da.remove(n)


# --- Baca -------------------------------------------------------------------

## Pastikan pembungkus sah; kembalikan isi bila ya, {} bila tidak.
static func _parse(text: String) -> Dictionary:
	if text.strip_edges() == "":
		return {}
	var j := JSON.new()
	if j.parse(text) != OK:   # parse() (bukan parse_string) agar berkas rusak tidak mencetak galat mesin
		return {}
	var v: Variant = j.data
	if not (v is Dictionary):
		return {}
	var env: Dictionary = v
	if not (env.get("version") is float or env.get("version") is int):
		return {}
	var ver: int = int(env["version"])
	if ver < 1 or ver > VERSION:
		return {}
	if not (env.get("data") is Dictionary):
		return {}
	return env


static func _read_file(name: String) -> Dictionary:
	var p: String = path(name)
	if not FileAccess.file_exists(p):
		return {}
	return _parse(FileAccess.get_file_as_string(p))


## Muat. Hasil: {status: Status, data: Dictionary}. Berkas utama -> cadangan -> permainan baru.
static func read() -> Dictionary:
	var main_exists: bool = FileAccess.file_exists(path())
	var bak_exists: bool = FileAccess.file_exists(path(BAK_NAME))
	if not main_exists and not bak_exists:
		return {"status": Status.MISSING, "data": {}}
	var env: Dictionary = _read_file(FILE_NAME)
	if not env.is_empty():
		return {"status": Status.OK, "data": sanitize(env["data"])}
	env = _read_file(BAK_NAME)
	if not env.is_empty():
		return {"status": Status.RESTORED_BACKUP, "data": sanitize(env["data"])}
	return {"status": Status.CORRUPT_NEW, "data": {}}


## Bersihkan isi: tipe yang salah dibuang, angka dibatasi. (Sistem juga membatasi lagi di from_dict.)
static func sanitize(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	out["day"] = maxi(1, int(d.get("day", 1)))
	out["minute"] = clampf(float(d.get("minute", 420.0)), 0.0, float(GameClock.MINUTES_PER_DAY) - 1.0)
	var lang: String = String(d.get("language", Locale.DEFAULT_LANG))
	out["language"] = lang if Locale.LANGS.has(lang) else Locale.DEFAULT_LANG
	var loc: String = String(d.get("location", "desa"))
	out["location"] = loc if loc == "klinik" else "desa"
	for k in ["stats", "skills", "inventory", "garden", "upgrades"]:
		var v: Variant = d.get(k, {})
		out[k] = v if v is Dictionary else {}
	return out


# --- Susun / terapkan ---------------------------------------------------------

static func collect(clock: GameClock, location_id: String, stats: ClinicStats, skills: SkillProgressionSystem,
		inventory: HerbInventory, garden: GardenSystem, upgrades: ClinicUpgrades) -> Dictionary:
	return {
		"day": clock.day, "minute": clock.minute_f, "language": Locale.current, "location": location_id,
		"stats": stats.to_dict(), "skills": skills.to_dict(), "inventory": inventory.to_dict(),
		"garden": garden.to_dict(), "upgrades": upgrades.to_dict(),
	}


## Terapkan `data` (hasil sanitize) ke sistem-sistem. Jam/lokasi/bahasa diurus pemanggil.
static func apply(data: Dictionary, stats: ClinicStats, skills: SkillProgressionSystem,
		inventory: HerbInventory, garden: GardenSystem, upgrades: ClinicUpgrades) -> void:
	stats.from_dict(data.get("stats", {}))
	skills.from_dict(data.get("skills", {}))
	upgrades.from_dict(data.get("upgrades", {}))
	inventory.daily_min = upgrades.herb_daily_min()
	inventory.from_dict(data.get("inventory", {}))
	garden.from_dict(data.get("garden", {}))
