class_name EconomyText
extends RefCounted
## Teks tampilan ekonomi: alasan transaksi buku kas, syarat upgrade. Logika murni (tanpa node).


## Alasan "jenis:arg" (lihat ClinicStats.add_money / spend) -> teks lokal.
static func reason_text(reason: String) -> String:
	var parts: PackedStringArray = reason.split(":", true, 1)
	var kind: String = parts[0]
	var arg: String = parts[1] if parts.size() > 1 else ""
	var item: String = ""
	match kind:
		"beli", "jual":
			item = Locale.t("herb.%s" % arg)
		"upgrade":
			item = Locale.t("upgrade.%s.name" % arg)
		"capaian":
			item = Locale.t("milestone.%s" % arg)
		"naik_tingkat":
			item = Locale.t("skill.%s" % arg) if arg != "" else ""
		"jelajah":
			item = Locale.t("area.%s.name" % arg)
		"misi":
			item = Locale.t("mission.%s.title" % arg)
		"tugas":
			item = Locale.t("sq.%s.title" % arg)
		"event":
			item = Locale.t("event.%s.title" % arg)
		"langka":
			item = Locale.t("rare.%s.name" % arg)
		"teka":
			item = Locale.t("fr.puzzle.%s.title" % arg)
	var key: String = "ledger.%s" % kind
	if not Locale.has_key(key):
		return reason
	return Locale.t(key, {"item": item})


## Teks syarat/biaya upgrade dari hasil ClinicUpgrades.check().
static func upgrade_status(chk: Dictionary, cost: int) -> String:
	match String(chk.get("reason", "")):
		"max":
			return Locale.t("upgrade.max")
		"rep":
			return Locale.t("upgrade.req_rep", {"cost": cost, "rep": int(chk["rep"])})
		"skill":
			return Locale.t("upgrade.req_skill", {"cost": cost, "skill": Locale.t("skill.%s" % String(chk["branch"])), "lv": int(chk["level"])})
		"money":
			return Locale.t("upgrade.req_money", {"cost": cost})
	return Locale.t("upgrade.ready", {"cost": cost})
