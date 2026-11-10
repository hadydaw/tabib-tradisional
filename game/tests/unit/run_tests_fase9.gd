extends SceneTree
## Tes unit Fase 9: data penemuan langka dan teka-teki, status eksplorasi (penemuan pertama, cooldown, teka-teki,
## peti, segel), keterjangkauan wilayah baru (Rawa dan Gua Kapur, dengan dan tanpa segel), quest eksplorasi,
## sanitasi simpanan, dan kelengkapan localization.
## Jalankan: godot --headless --path game -s res://tests/unit/run_tests_fase9.gd

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _count: int = 0
var _fail: int = 0


func _init() -> void:
	Locale.set_language("id")
	_test_rare_data()
	_test_puzzle_data()
	_test_frontier_flow()
	_test_frontier_roundtrip()
	_test_regions()
	_test_reachability()
	_test_quests()
	_test_localization()
	print("Tes Fase 9 dijalankan: %d, gagal: %d" % [_count, _fail])
	quit(1 if _fail > 0 else 0)


func _check(condition: bool, name: String) -> void:
	_count += 1
	if condition:
		print("  OK   ", name)
	else:
		_fail += 1
		printerr("  GAGAL ", name)


func _test_rare_data() -> void:
	_check(RareDb.ITEMS.size() == 6, "enam jenis bahan langka")
	var pools_ok: bool = true
	for nid in RareDb.NODES.keys():
		var n: Dictionary = RareDb.node(String(nid))
		var pool: Array = n["pool"]
		if pool.size() != 2 or not RareDb.has_item(String(pool[0])) or not RareDb.has_item(String(pool[1])):
			pools_ok = false
		if not ["rawa", "gua"].has(String(n["area"])):
			pools_ok = false
	_check(pools_ok, "setiap titik punya dua bahan yang dikenal dan area valid")
	_check(RareDb.nodes_in("rawa").size() == 4 and RareDb.nodes_in("gua").size() == 2, "rawa 4 titik, gua 2 titik")
	var same: bool = true
	for s in range(20):
		if RareDb.roll("rawa_1", s) != RareDb.roll("rawa_1", s):
			same = false
	_check(same, "pengambilan bahan deterministik untuk seed yang sama")
	var rare_hits: int = 0
	for s in range(1000):
		if RareDb.roll("rawa_dalam_1", s) == String(RareDb.node("rawa_dalam_1")["pool"][1]):
			rare_hits += 1
	_check(rare_hits > 100 and rare_hits < 350, "bahan langka muncul sekitar seperlima kali (%d/1000)" % rare_hits)
	_check(RareDb.roll("tidak_ada", 1) == "", "titik tak dikenal tidak memberi bahan")


func _test_puzzle_data() -> void:
	_check(RareDb.PUZZLES.size() == 3, "tiga teka-teki")
	var ok: bool = true
	for pid in RareDb.PUZZLES.keys():
		var d: Dictionary = RareDb.puzzle(String(pid))
		var opts: Array = d["options"]
		var ans: Array = d["answer"]
		for a in ans:
			if not opts.has(a):
				ok = false
		if int(d["reward"]["coin"]) <= 0 or not RareDb.has_item(String(d["reward"]["item"])):
			ok = false
	_check(ok, "jawaban ada di pilihan, dan setiap teka-teki punya hadiah")
	_check(RareDb.has_item(String(RareDb.CHEST["item"])) and int(RareDb.CHEST["coin"]) > 0, "peti gua berisi koin dan bahan")
	_check(RareDb.TABLET_ID != RareDb.LEVER_ID and RareDb.has_puzzle(RareDb.RIDDLE_ID), "id teka-teki konsisten")


func _test_frontier_flow() -> void:
	var f := FrontierState.new()
	_check(f.discover("akar_rawa") and not f.discover("akar_rawa"), "penemuan pertama hanya sekali, berikutnya biasa")
	_check(f.count("akar_rawa") == 2 and f.distinct_found() == 1, "jumlah dan jenis penemuan benar")
	_check(not f.discover("bukan_bahan"), "bahan tak dikenal ditolak")
	_check(not f.gua_unlocked(), "gua masih tertutup dengan satu jenis penemuan")
	f.discover("benih_cendana")
	_check(f.gua_unlocked(), "gua terbuka setelah dua jenis penemuan")
	_check(f.node_ready("rawa_1", 0.0), "titik belum pernah diambil siap")
	f.mark_node("rawa_1", 100.0)
	_check(not f.node_ready("rawa_1", 100.0 + RareDb.COOLDOWN_MINUTES - 1.0), "titik istirahat sebelum cooldown selesai")
	_check(f.node_ready("rawa_1", 100.0 + RareDb.COOLDOWN_MINUTES), "titik siap setelah cooldown")
	_check(f.solve("penjaga_rawa") and not f.solve("penjaga_rawa"), "teka-teki selesai sekali")
	_check(not f.solve("tidak_ada"), "teka-teki tak dikenal ditolak")
	_check(f.fog_lifted(), "kabut terangkat setelah penjaga rawa")
	_check(f.loot_chest() and not f.loot_chest(), "peti hanya bisa dibuka sekali")


func _test_frontier_roundtrip() -> void:
	var a := FrontierState.new()
	a.discover("jamur_gua", 3)
	a.mark_node("gua_1", 500.0)
	a.solve("tablet_gua")
	a.loot_chest()
	var b := FrontierState.new()
	b.from_dict(a.to_dict())
	_check(b.count("jamur_gua") == 3 and b.distinct_found() == 1, "penemuan tersimpan dan dibaca ulang")
	_check(b.puzzle_solved("tablet_gua") and b.chest_opened, "teka-teki dan peti tersimpan")
	_check(not b.node_ready("gua_1", 600.0), "cooldown titik tersimpan")
	var junk := FrontierState.new()
	junk.from_dict({"rare": {"tidak_ada": 5, "akar_rawa": -4}, "firsts": {"tidak_ada": true},
		"node_taken": {"tidak_ada": 1.0}, "puzzles": {"tidak_ada": true}, "chest_opened": "bukan_bool"})
	_check(junk.count("akar_rawa") == 0 and junk.distinct_found() == 0, "data rusak: nilai negatif dan id tak dikenal dibuang")
	_check(junk.puzzles.is_empty() and junk.node_taken.is_empty(), "data rusak: teka-teki dan titik tak dikenal dibuang")
	var sanitized: Dictionary = SaveSystem.sanitize({"frontier": "rusak"})
	_check(sanitized.has("frontier") and sanitized["frontier"] is Dictionary, "sanitasi simpanan selalu memberi kamus frontier")


func _test_regions() -> void:
	_check(LocationRegistry.has_location("rawa") and LocationRegistry.has_location("gua"), "rawa dan gua terdaftar")
	var rawa: LocationData = LocationRegistry.get_location("rawa")
	var gua: LocationData = LocationRegistry.get_location("gua")
	_check(rawa != null and gua != null, "rawa dan gua bisa dibangun")
	_check(rawa.transition_at(Vector2i(0, 9)).get("target", "") == "sungai", "pintu barat rawa kembali ke sungai")
	_check(gua.transition_at(Vector2i(0, 10)).get("target", "") == "pegunungan", "pintu barat gua kembali ke pegunungan")
	var river: LocationData = LocationRegistry.get_location("sungai")
	_check(river.transition_at(Vector2i(27, 9)).get("target", "") == "rawa", "pintu timur sungai menuju rawa")
	var mountain: LocationData = LocationRegistry.get_location("pegunungan")
	_check(mountain.transition_at(Vector2i(23, 10)).get("target", "") == "gua", "pintu timur pegunungan menuju gua")
	_check(rawa.spawns.has("dari_sungai") and gua.spawns.has("dari_pegunungan"), "titik masuk rawa dan gua tersedia")
	_check(river.spawns.has("dari_rawa") and mountain.spawns.has("dari_gua"), "titik kembali sungai dan pegunungan tersedia")
	_check(rawa.spawns.has("dari_desa") and gua.spawns.has("dari_desa"), "muat simpanan (dari_desa) berfungsi di rawa dan gua")
	var rawa_nodes: int = 0
	for n in rawa.interactables:
		if RareDb.is_node(n.id):
			rawa_nodes += 1
	_check(rawa_nodes == 4 and rawa.interactable_by_id(RareDb.RIDDLE_ID) != null, "rawa: 4 titik langka dan batu penjaga")
	_check(gua.interactable_by_id(RareDb.TABLET_ID) != null and gua.interactable_by_id(RareDb.LEVER_ID) != null and gua.interactable_by_id(RareDb.CHEST_ID) != null, "gua: tablet, tuas, dan peti")


func _reach(loc: LocationData, start: Vector2i, sealed: Dictionary) -> Dictionary:
	var blocked: Dictionary = loc.blocked_cells()
	for c in sealed.keys():
		blocked[c] = true
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d: Vector2i in DIRS:
			var n: Vector2i = c + d
			if n.x < 0 or n.y < 0 or n.x >= loc.width or n.y >= loc.height:
				continue
			if seen.has(n) or blocked.has(n):
				continue
			seen[n] = true
			queue.append(n)
	return seen


func _cell_of(loc: LocationData, spawn: String) -> Vector2i:
	var p: Vector2 = loc.spawns[spawn]
	return Vector2i(floori(p.x), floori(p.y))


func _sealed_of(loc_id: String, f: FrontierState) -> Dictionary:
	var out: Dictionary = {}
	for c in f.sealed_cells(loc_id):
		out[c] = true
	return out


func _test_reachability() -> void:
	var rawa: LocationData = LocationRegistry.get_location("rawa")
	var gua: LocationData = LocationRegistry.get_location("gua")
	var f := FrontierState.new()
	var seen_outer: Dictionary = _reach(rawa, _cell_of(rawa, "dari_sungai"), _sealed_of("rawa", f))
	_check(seen_outer.has(Vector2i(4, 4)) and seen_outer.has(Vector2i(9, 14)), "rawa luar bisa dijelajahi dari pintu masuk")
	_check(seen_outer.has(Vector2i(14, 9)), "batu penjaga bisa didekati dari rawa luar")
	_check(not seen_outer.has(Vector2i(21, 3)), "rawa dalam tertutup kabut sebelum teka-teki selesai")
	f.solve(RareDb.RIDDLE_ID)
	var seen_all: Dictionary = _reach(rawa, _cell_of(rawa, "dari_sungai"), _sealed_of("rawa", f))
	_check(seen_all.has(Vector2i(21, 3)) and seen_all.has(Vector2i(22, 8)), "setelah kabut terangkat, rawa dalam bisa dicapai")

	var g := FrontierState.new()
	var gua_hall: Dictionary = _reach(gua, _cell_of(gua, "dari_pegunungan"), _sealed_of("gua", g))
	_check(gua_hall.has(Vector2i(3, 10)) and gua_hall.has(Vector2i(8, 9)), "aula gua bisa dijelajahi, tablet terjangkau")
	_check(not gua_hall.has(Vector2i(13, 13)) and not gua_hall.has(Vector2i(8, 2)), "ruang dalam dan ceruk tertutup sebelum teka-teki")
	g.solve(RareDb.TABLET_ID)
	var gua_door: Dictionary = _reach(gua, _cell_of(gua, "dari_pegunungan"), _sealed_of("gua", g))
	_check(gua_door.has(Vector2i(12, 13)) and gua_door.has(Vector2i(13, 13)), "pintu tablet membuka ruang dalam (titik langka)")
	_check(not gua_door.has(Vector2i(8, 3)), "ceruk peti masih tertutup sebelum tuas")
	g.solve(RareDb.LEVER_ID)
	var gua_all: Dictionary = _reach(gua, _cell_of(gua, "dari_pegunungan"), _sealed_of("gua", g))
	_check(gua_all.has(Vector2i(8, 3)), "tuas membuka celah ke ceruk peti (sel di depan peti)")


func _test_quests() -> void:
	_check(SocialDb.QUEST_ORDER.has("q_lastri_rawa") and SocialDb.QUEST_ORDER.has("q_joko_gua"), "dua quest eksplorasi terdaftar")
	var lastri: Dictionary = SocialDb.quest("q_lastri_rawa")
	var joko: Dictionary = SocialDb.quest("q_joko_gua")
	_check(String(lastri["giver"]) == "lastri" and String(joko["giver"]) == "joko", "pemberi quest benar")
	_check(String(lastri["steps"][0]["kind"]) == SocialDb.KIND_DISCOVER, "quest Lastri: langkah penemuan")
	_check(String(joko["steps"][0]["kind"]) == SocialDb.KIND_DUNGEON and String(joko["steps"][0]["key"]) == "gua", "quest Joko: langkah gua")
	_check(SocialDb.quests_of("lastri").has("q_lastri_rawa") and SocialDb.quests_of("joko").has("q_joko_gua"), "quest tampil di dialog pemberinya")


func _test_localization() -> void:
	var keys: Array[String] = []
	for rid in RareDb.ITEMS:
		keys.append("rare.%s.name" % rid)
		keys.append("rare.%s.habitat" % rid)
	for pid in RareDb.PUZZLES.keys():
		keys.append("fr.puzzle.%s.title" % String(pid))
		keys.append("fr.puzzle.%s.hint" % String(pid))
	for s in ["api", "air", "angin", "tanah"]:
		keys.append("fr.sym.%s" % s)
	for qid in ["q_lastri_rawa", "q_joko_gua"]:
		for suffix in ["title", "offer", "accepted", "wait", "turn", "done"]:
			keys.append("sq.%s.%s" % [qid, suffix])
		for o in SocialDb.quest(qid)["choices"].keys():
			keys.append("sq.%s.opt.%s" % [qid, String(o)])
	for k in ["fr.node_title", "fr.rare_got", "fr.rare_first", "fr.node_prompt", "fr.node_resting", "fr.puzzle_prompt",
			"fr.puzzle_undo", "fr.puzzle_wrong", "fr.puzzle_solved", "fr.reward", "fr.puzzle_done", "fr.fog_lifted",
			"fr.door_open", "fr.crack_open", "fr.chest_title", "fr.chest_prompt", "fr.chest_open", "fr.chest_empty",
			"fr.gate_gua", "fr.unavailable", "fr.book_rare", "fr.book_puzzles", "ledger.langka", "ledger.teka", "ledger.peti"]:
		keys.append(k)
	var missing: int = 0
	for k in keys:
		for lang in ["id", "en"]:
			if not Locale.has_key(k, lang):
				missing += 1
				printerr("    kunci hilang: ", k, " (", lang, ")")
	_check(missing == 0, "semua kunci Fase 9 ada di Indonesia dan Inggris (%d kunci)" % keys.size())
	Locale.set_language("id")
	_check(Locale.t("fr.rare_got", {"name": "X"}).find("X") >= 0, "format argumen localization berfungsi")
