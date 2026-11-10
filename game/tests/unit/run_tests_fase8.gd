extends SceneTree
## Tes unit Fase 8: data sosial, kepercayaan & bicara harian, bab cerita, bahan hadiah, alur quest dan pilihan,
## event desa (jadwal waktu permainan), simpan/muat (termasuk kompatibilitas mundur), grafik dialog per tingkat,
## dan kelengkapan localization.
## Jalankan: godot --headless --path game -s res://tests/unit/run_tests_fase8.gd

const TEST_DIR: String = "user://tes_unit_fase8"

var _count: int = 0
var _fail: int = 0


func _init() -> void:
	SaveSystem.override_dir = TEST_DIR
	SaveSystem.delete_all()
	Locale.set_language("id")
	_test_profiles()
	_test_trust_and_talk()
	_test_chapters()
	_test_gifts()
	_test_quest_flow()
	_test_quest_choices()
	_test_village_events()
	_test_state_roundtrip_and_sanitize()
	_test_save_compat()
	_test_dialogue_graph()
	_test_dialogue_runner_actions()
	_test_localization()
	SaveSystem.delete_all()
	print("Tes Fase 8 dijalankan: %d, gagal: %d" % [_count, _fail])
	quit(1 if _fail > 0 else 0)


func _check(condition: bool, name: String) -> void:
	_count += 1
	if condition:
		print("  OK   ", name)
	else:
		_fail += 1
		printerr("  GAGAL ", name)


func _test_profiles() -> void:
	var ok_ids: bool = true
	for id in NpcRoster.ids():
		if not SocialDb.is_npc(id):
			ok_ids = false
	_check(ok_ids and SocialDb.npc_ids().size() == NpcRoster.ids().size(), "profil sosial ada untuk semua penduduk")
	var likes_ok: bool = true
	for id in SocialDb.npc_ids():
		if not HerbDb.has(SocialDb.likes(id)):
			likes_ok = false
	_check(likes_ok, "setiap penduduk punya bahan kesukaan yang valid")
	var quest_ok: bool = true
	for qid in SocialDb.QUEST_ORDER:
		var d: Dictionary = SocialDb.quest(qid)
		if not SocialDb.is_npc(String(d["giver"])) or (d["choices"] as Dictionary).size() < 2:
			quest_ok = false
		for s in d["steps"]:
			var kind: String = String(s["kind"])
			if not [SocialDb.KIND_GATHER, SocialDb.KIND_IDENTIFY, SocialDb.KIND_ZONE, SocialDb.KIND_TREAT].has(kind):
				quest_ok = false
		for opt in d["choices"].keys():
			var herb: String = String(d["choices"][opt]["herb"])
			if herb != "" and not HerbDb.has(herb):
				quest_ok = false
	_check(quest_ok and SocialDb.QUEST_ORDER.size() == SocialDb.QUESTS.size(), "quest: pemberi valid, langkah dikenal, pilihan >= 2, bahan valid")
	var asc: bool = SocialDb.CHAPTER_TRUST[0] < SocialDb.CHAPTER_TRUST[1] and SocialDb.CHAPTER_TRUST[1] <= SocialDb.TRUST_MAX
	_check(asc, "ambang bab cerita naik dan dalam batas")
	_check(SocialDb.tier_of(0) == 0 and SocialDb.tier_of(34) == 0 and SocialDb.tier_of(35) == 1 and SocialDb.tier_of(69) == 1 and SocialDb.tier_of(70) == 2,
		"tingkat kepercayaan 0/1/2 pada ambang 35 dan 70")


func _test_trust_and_talk() -> void:
	var s := SocialState.new()
	_check(s.trust_of("wiryo") == SocialDb.START_TRUST, "kepercayaan awal = START_TRUST")
	_check(s.talk("wiryo", 1) == SocialDb.TALK_GAIN, "bicara pertama hari ini menambah kepercayaan")
	_check(s.talk("wiryo", 1) == 0, "bicara kedua di hari yang sama tidak menambah")
	_check(s.talk("wiryo", 2) == SocialDb.TALK_GAIN, "bicara di hari berikutnya menambah lagi")
	_check(s.talk("penipu", 2) == 0 and not s.trust.has("penipu"), "penduduk tak dikenal diabaikan")
	var before: int = s.trust_of("wiryo")
	var gained: int = s.add_trust("wiryo", 500)
	_check(s.trust_of("wiryo") == SocialDb.TRUST_MAX and gained == SocialDb.TRUST_MAX - before, "kepercayaan dibatasi 100, selisih benar")
	_check(s.add_trust("wiryo", -999) == -SocialDb.TRUST_MAX and s.trust_of("wiryo") == 0, "kepercayaan dibatasi 0")
	_check(s.add_trust("tidak_ada", 5) == 0, "tambah kepercayaan ke penduduk tak dikenal: 0")


func _test_chapters() -> void:
	var s := SocialState.new()
	s.trust["wiryo"] = 20
	_check(s.chapter_due("wiryo") == 0, "bab 1 belum terbuka di bawah ambang")
	s.trust["wiryo"] = 25
	_check(s.chapter_due("wiryo") == 1, "bab 1 terbuka pada ambang 25")
	_check(not s.mark_chapter("wiryo", 2), "bab 2 tidak bisa ditandai sebelum bab 1")
	_check(s.mark_chapter("wiryo", 1) and s.chapter_seen("wiryo", 1), "bab 1 ditandai didengar")
	_check(s.chapter_due("wiryo") == 0, "bab 2 belum terbuka di kepercayaan 25")
	_check(not s.mark_chapter("wiryo", 1), "bab yang sama tidak bisa ditandai dua kali")
	s.trust["wiryo"] = 60
	_check(s.chapter_due("wiryo") == 2, "bab 2 terbuka pada ambang 60")
	_check(s.mark_chapter("wiryo", 2) and s.chapter_due("wiryo") == 0, "setelah bab 2, tidak ada bab tersisa")
	_check(s.chapter_due("penipu") == 0, "bab penduduk tak dikenal: 0")


func _test_gifts() -> void:
	var s := SocialState.new()
	var liked: String = SocialDb.likes("karto")
	var other: String = "jahe" if liked != "jahe" else "kunyit"
	_check(s.gift_available("karto", 1), "pemberian bahan tersedia di awal hari")
	_check(s.pick_gift("karto", [other, liked]) == liked, "bahan kesukaan dipilih bila tersedia")
	var a: Array[String] = [other]
	_check(s.pick_gift("karto", a) == other, "tanpa bahan kesukaan, bahan lain dipakai")
	var none: Array[String] = []
	_check(s.pick_gift("karto", none) == "", "tanpa bahan: kosong")
	var before: int = s.trust_of("karto")
	_check(s.record_gift("karto", 1, liked) == SocialDb.GIFT_LIKED and s.trust_of("karto") == before + SocialDb.GIFT_LIKED, "bahan kesukaan menambah kepercayaan besar")
	_check(s.record_gift("karto", 1, other) == 0, "kedua kali di hari yang sama tidak menambah")
	_check(s.record_gift("sari", 1, other) == SocialDb.GIFT_OTHER, "bahan lain menambah kepercayaan kecil")
	_check(s.record_gift("sari", 2, "") == 0 and s.gift_available("sari", 2), "tanpa bahan tidak mengubah apa pun")


func _test_quest_flow() -> void:
	var s := SocialState.new()
	var qid: String = "q_karto_kebun"
	_check(not s.can_offer(qid, 50.0), "tugas belum ditawarkan: kepercayaan Karto masih rendah")
	s.trust["karto"] = 40
	_check(s.can_offer(qid, 0.0) and s.accept(qid, 0.0), "tugas diterima setelah kepercayaan cukup")
	_check(not s.accept(qid, 0.0) and s.status(qid) == SocialState.ACTIVE, "tugas tidak bisa diterima dua kali")
	_check(s.event("identify", "any").is_empty() and not s.is_ready(qid), "satu tanaman belum cukup")
	var ready1: Array[String] = s.event("identify", "any")
	_check(ready1.has(qid) and s.is_ready(qid), "dua identifikasi membuat tugas siap")
	_check(s.event("identify", "any").is_empty(), "tugas siap tidak diumumkan ulang")
	_check(s.event("gather", "any").is_empty(), "pengumpulan tidak memengaruhi tugas identifikasi")

	var q2: String = "q_ratih_pasien"
	s.trust["ratih"] = 30
	_check(not s.can_offer(q2, 10.0), "reputasi desa di bawah syarat: tugas belum ditawarkan")
	_check(s.can_offer(q2, 30.0), "reputasi 30 memenuhi syarat")
	s.accept(q2, 30.0)
	s.event("treat", "good")
	s.event("treat", "good")
	_check(not s.is_ready(q2), "dua pasien bagus belum cukup untuk tugas Ratih")
	s.event("treat", "bad")
	_check(not s.is_ready(q2) and s.progress_of(q2, 0) == 2, "pasien hasil buruk tidak dihitung")
	_check(s.event("treat", "good").has(q2), "pasien bagus ketiga membuat tugas siap")

	var q3: String = "q_dewi_sungai"
	s.trust["dewi"] = 15
	s.accept(q3, 0.0)
	_check(s.event("zone", "hutan").is_empty(), "area lain tidak menyelesaikan tugas Dewi")
	_check(s.event("zone", "sungai").has(q3), "masuk Sungai menyelesaikan tugas Dewi")

	var q4: String = "q_wiryo_ramuan"
	s.trust["wiryo"] = 30
	s.accept(q4, 0.0)
	for i in 3:
		s.event("gather", "any")
	_check(s.is_ready(q4), "tiga pengumpulan membuat tugas Wiryo siap")


func _test_quest_choices() -> void:
	var s := SocialState.new()
	var qid: String = "q_karto_kebun"
	s.trust["karto"] = 40
	_check(s.complete(qid, "bagi_jasa").is_empty(), "tugas belum siap tidak bisa diserahkan")
	s.accept(qid, 0.0)
	s.event("identify", "any")
	s.event("identify", "any")
	_check(s.complete(qid, "pilihan_palsu").is_empty() and s.status(qid) == SocialState.ACTIVE, "pilihan tak dikenal ditolak")
	var r: Dictionary = s.complete(qid, "bagi_jasa")
	_check(int(r["coin"]) == 20 and absf(float(r["rep"]) - 2.0) < 0.001 and int(r["trust"]) == 6, "hadiah pilihan 'bagi jasa' benar")
	_check(s.status(qid) == SocialState.DONE and s.trust_of("karto") == 46, "tugas selesai dan kepercayaan Karto naik")
	_check(s.complete(qid, "bagi_jasa").is_empty(), "tugas selesai tidak bisa diserahkan lagi")

	var q2: String = "q_wiryo_ramuan"
	s.trust["wiryo"] = 30
	s.accept(q2, 0.0)
	for i in 3:
		s.event("gather", "any")
	var untung: Dictionary = s.complete(q2, "untung")
	_check(int(untung["coin"]) == 60 and int(untung["trust"]) == -4 and s.trust_of("wiryo") == 26, "pilihan 'untung' lebih banyak koin tapi menurunkan kepercayaan")

	var q3: String = "q_dewi_sungai"
	s.trust["dewi"] = 15
	s.accept(q3, 0.0)
	s.event("zone", "sungai")
	var r3: Dictionary = s.complete(q3, "apa_adanya")
	_check(String(r3["herb"]) == "kayu_manis" and String(r3["giver"]) == "dewi", "hadiah bahan dari pilihan jujur")


func _test_village_events() -> void:
	_check(VillageEvents.active_at(3, 480) == ["pasar_desa"], "pasar aktif pada hari 3 pukul 08:00")
	_check(VillageEvents.active_at(3, 479).is_empty(), "pasar belum aktif pada 07:59")
	_check(VillageEvents.active_at(3, 599) == ["pasar_desa"] and VillageEvents.active_at(3, 600).is_empty(), "pasar berakhir tepat 120 menit")
	_check(VillageEvents.active_at(4, 1080) == ["malam_bakti"], "malam bakti aktif pada hari 4 pukul 18:00")
	_check(VillageEvents.active_at(2, 480).is_empty() and VillageEvents.active_at(5, 1080).is_empty(), "event tidak aktif di hari yang tidak sesuai jadwal")
	_check(VillageEvents.active_at(12, 500) == ["pasar_desa"], "hari 12 (kelipatan 3 dan 4): pasar saja pada jamnya")
	_check(VillageEvents.next_occurrence("pasar_desa", 3, 500) == 3 and VillageEvents.next_occurrence("pasar_desa", 3, 700) == 6,
		"jadwal berikutnya: hari ini bila masih berlangsung, lalu hari berikutnya")
	var nxt: Dictionary = VillageEvents.soonest(4, 0)
	_check(String(nxt["id"]) == "malam_bakti" and int(nxt["day"]) == 4, "event terdekat dari hari 4 pagi: malam bakti hari ini")
	var s := SocialState.new()
	_check(s.claim_event("pasar_desa", 3) and not s.claim_event("pasar_desa", 3), "event diklaim sekali per hari")
	_check(s.claim_event("pasar_desa", 6) and not s.claim_event("tidak_ada", 3), "klaim hari berikutnya boleh; event tak dikenal ditolak")
	_check(VillageEvents.is_claim_key("pasar_desa:3") and not VillageEvents.is_claim_key("x:3"), "format kunci klaim dikenali")


func _test_state_roundtrip_and_sanitize() -> void:
	var rl := RequestLog.new()
	rl.accept("req_salam_wiryo")
	var a := SocialState.new(rl)
	a.trust["wiryo"] = 50
	a.mark_chapter("wiryo", 1)
	a.talk("wiryo", 3)
	a.record_gift("karto", 2, SocialDb.likes("karto"))
	a.trust["dewi"] = 15
	a.accept("q_dewi_sungai", 0.0)
	a.event("zone", "sungai")
	a.claim_event("pasar_desa", 3)
	var rl2 := RequestLog.new()
	var b := SocialState.new(rl2)
	b.from_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	_check(b.trust_of("wiryo") == 50 and b.chapter_seen("wiryo", 1) and b.talk_day.get("wiryo") == 3, "kepercayaan, bab, dan hari bicara bolak-balik JSON")
	_check(b.gift_available("karto", 2) == false and b.trust_of("karto") == a.trust_of("karto"), "hari pemberian bahan bolak-balik JSON")
	_check(b.status("q_dewi_sungai") == SocialState.ACTIVE and b.is_ready("q_dewi_sungai"), "progres quest bolak-balik JSON")
	_check(b.event_claimed("pasar_desa", 3) and not b.event_claimed("pasar_desa", 6), "klaim event bolak-balik JSON")
	_check(rl2.status("req_salam_wiryo") == RequestLog.ACTIVE, "permintaan Fase 4 ikut tersimpan")

	var c := SocialState.new()
	c.from_dict({"trust": {"wiryo": 999, "penipu": 5}, "chapters": {"wiryo:9": true, "wiryo:1": true, "x:1": true},
		"talk_day": {"wiryo": -4}, "gift_day": {"karto": 7},
		"quests": {"q_dewi_sungai": {"status": 7, "progress": ["a", 9], "option": "bohong"}, "q_palsu": {"status": 1}},
		"claims": {"pasar_desa:3": true, "rusak": true}})
	_check(c.trust_of("wiryo") == 100 and not c.trust.has("penipu"), "kepercayaan dibatasi dan penduduk tak dikenal dibuang")
	_check(c.chapters.size() == 1 and c.chapter_seen("wiryo", 1), "bab tak valid dibuang")
	_check(int(c.talk_day.get("wiryo", -1)) == 0, "hari bicara negatif dinolkan")
	_check(c.status("q_dewi_sungai") == SocialState.DONE and c.progress_of("q_dewi_sungai", 0) == 0 and String(c.quests["q_dewi_sungai"]["option"]) == "",
		"status quest dibatasi, progres dibatasi, pilihan tak dikenal dibuang")
	_check(not c.quests.has("q_palsu") and c.claims.size() == 1, "quest tak dikenal dan klaim rusak dibuang")
	var d := SocialState.new()
	d.from_dict({})
	_check(d.trust_of("wiryo") == SocialDb.START_TRUST and d.quests.is_empty(), "data kosong: keadaan awal")


func _test_save_compat() -> void:
	var clock := GameClock.new()
	clock.set_time(3, 10, 0)
	var cs := ClinicStats.new()
	var sk := SkillProgressionSystem.new()
	var inv := HerbInventory.new()
	var gd := GardenSystem.new()
	var up := ClinicUpgrades.new()
	var ad := AdventureState.new()
	var so := SocialState.new()
	so.trust["karto"] = 47
	so.accept("q_karto_kebun", 0.0)
	var data: Dictionary = SaveSystem.collect(clock, "desa", cs, sk, inv, gd, up, ad, so)
	_check(data.has("social") and (data["social"] as Dictionary).has("trust"), "simpanan memuat kunci social")
	SaveSystem.write(data)
	var r: Dictionary = SaveSystem.read()
	_check(int(r["status"]) == SaveSystem.Status.OK, "simpanan Fase 8 terbaca")
	var so2 := SocialState.new()
	SaveSystem.apply(r["data"], ClinicStats.new(), SkillProgressionSystem.new(), HerbInventory.new(), GardenSystem.new(), ClinicUpgrades.new(), AdventureState.new(), so2)
	_check(so2.trust_of("karto") == 47 and so2.status("q_karto_kebun") == SocialState.ACTIVE, "keadaan sosial dipulihkan dari simpanan")
	# simpanan Fase 7 (tanpa kunci social) tetap bisa dimuat: keadaan sosial mulai dari awal
	var old: Dictionary = data.duplicate()
	old.erase("social")
	var so3 := SocialState.new()
	SaveSystem.apply(old, ClinicStats.new(), SkillProgressionSystem.new(), HerbInventory.new(), GardenSystem.new(), ClinicUpgrades.new(), AdventureState.new(), so3)
	_check(so3.trust_of("karto") == SocialDb.START_TRUST and so3.quests.is_empty(), "simpanan Fase 7 (tanpa social) dimuat sebagai awal")
	var san: Dictionary = SaveSystem.sanitize({"social": "rusak", "day": 2})
	_check(san["social"] is Dictionary and (san["social"] as Dictionary).is_empty(), "sanitize: social yang rusak jadi kosong")
	SaveSystem.delete_all()


func _test_dialogue_graph() -> void:
	var ids_ok: bool = true
	for id in NpcRoster.ids():
		var npc: NpcData = NpcRoster.by_id(id)
		for tier_score in [0, 40, 80]:
			var s := SocialState.new()
			s.trust[id] = tier_score
			var nodes: Dictionary = DialogueLibrary.build(npc, {"social": s, "day": 1, "reputation": 60.0, "herbs_available": true, "requests": RequestLog.new(), "activity": "di_rumah"})
			if not nodes.has(DialogueLibrary.START):
				ids_ok = false
			for nid in nodes.keys():
				var n: Dictionary = nodes[nid]
				if not Locale.has_key(String(n["text"]), "id") or not Locale.has_key(String(n["text"]), "en"):
					ids_ok = false
				if String(n["next"]) != "" and not nodes.has(String(n["next"])):
					ids_ok = false
				for c in n["choices"]:
					if String(c["next"]) != "" and not nodes.has(String(c["next"])):
						ids_ok = false
	_check(ids_ok, "grafik dialog valid untuk semua penduduk pada 3 tingkat (semua tujuan ada, teks ada)")

	var karto: NpcData = NpcRoster.by_id("karto")
	var s1 := SocialState.new()
	s1.trust["karto"] = 25
	var n1: Dictionary = DialogueLibrary.build(karto, {"social": s1, "day": 1, "herbs_available": true, "requests": RequestLog.new()})
	_check(_has_choice(n1, DialogueLibrary.START, "dlg.choice.chapter"), "bab cerita muncul sebagai pilihan saat terbuka")
	_check(_action_of(n1["ch"], "dlg.choice.more") == "chapter:karto:1", "pilihan 'ceritakan lebih banyak' mencatat bab 1")
	_check(not _has_choice(n1, DialogueLibrary.START, "dlg.choice.quest"), "tugas Karto belum ditawarkan di kepercayaan 25")

	s1.trust["karto"] = 45
	var n2: Dictionary = DialogueLibrary.build(karto, {"social": s1, "day": 1, "herbs_available": true, "requests": RequestLog.new()})
	_check(_has_choice(n2, DialogueLibrary.START, "dlg.choice.quest"), "tugas Karto ditawarkan di kepercayaan 45")
	_check(n2.has("qoffer_q_karto_kebun") and _action_of(n2["qoffer_q_karto_kebun"], "dlg.choice.accept") == "squest_accept:q_karto_kebun", "tawaran tugas punya aksi terima")

	s1.accept("q_karto_kebun", 0.0)
	var n3: Dictionary = DialogueLibrary.build(karto, {"social": s1, "day": 1, "herbs_available": true, "requests": RequestLog.new()})
	_check(_has_choice(n3, DialogueLibrary.START, "dlg.choice.quest_status") and not _has_choice(n3, DialogueLibrary.START, "dlg.choice.quest"), "tugas aktif: pilihan status, tanpa tawaran ulang")
	s1.event("identify", "any")
	s1.event("identify", "any")
	var n4: Dictionary = DialogueLibrary.build(karto, {"social": s1, "day": 1, "herbs_available": true, "requests": RequestLog.new()})
	_check(_has_choice(n4, DialogueLibrary.START, "dlg.choice.report_quest"), "tugas siap: pilihan lapor muncul")
	var turn: Dictionary = n4["qturn_q_karto_kebun"]
	_check(turn["choices"].size() == 2 and _action_of(turn, "sq.q_karto_kebun.opt.bagi_jasa") == "squest_choice:q_karto_kebun:bagi_jasa", "pilihan penyerahan tugas mencatat keputusan")

	var n5: Dictionary = DialogueLibrary.build(karto, {"social": s1, "day": 1, "herbs_available": false, "requests": RequestLog.new()})
	_check(not _has_choice(n5, DialogueLibrary.START, "dlg.choice.gift"), "tanpa bahan di tas: tidak ada pilihan berikan bahan")
	var n6: Dictionary = DialogueLibrary.build(karto, {"social": s1, "day": 1, "herbs_available": true, "requests": RequestLog.new()})
	_check(_has_choice(n6, DialogueLibrary.START, "dlg.choice.gift"), "dengan bahan: pilihan berikan bahan muncul")
	s1.record_gift("karto", 1, SocialDb.likes("karto"))
	var n7: Dictionary = DialogueLibrary.build(karto, {"social": s1, "day": 1, "herbs_available": true, "requests": RequestLog.new()})
	_check(not _has_choice(n7, DialogueLibrary.START, "dlg.choice.gift"), "sudah memberi bahan hari ini: pilihan tidak muncul lagi")

	var greet_a: String = String(DialogueLibrary.build(karto, {"social": SocialState.new(), "day": 1}).get(DialogueLibrary.START)["text"])
	var sx := SocialState.new()
	sx.trust["karto"] = 80
	var greet_b: String = String(DialogueLibrary.build(karto, {"social": sx, "day": 1}).get(DialogueLibrary.START)["text"])
	_check(greet_a == "dlg.karto.t0" and greet_b == "dlg.karto.t2", "sapaan berbeda menurut tingkat kepercayaan")


func _test_dialogue_runner_actions() -> void:
	var s := SocialState.new()
	s.trust["karto"] = 25
	var rl := RequestLog.new()
	var n: Dictionary = DialogueLibrary.build(NpcRoster.by_id("karto"), {"social": s, "day": 1, "requests": rl})
	var runner := DialogueRunner.new()
	var got: Array[String] = []
	runner.action_requested.connect(func(a: String) -> void: got.append(a))
	runner.start("karto", n, rl)
	var labels: Array = runner.view()["choices"]
	var idx: int = labels.find(Locale.t("dlg.choice.chapter"))
	_check(idx >= 0, "pilihan bab cerita ada di tampilan dialog")
	runner.select(idx)
	idx = (runner.view()["choices"] as Array).find(Locale.t("dlg.choice.more"))
	runner.select(idx)
	_check(got == ["chapter:karto:1"], "aksi bab diteruskan ke dunia lewat sinyal")
	_check(runner.is_active() and runner.node_id == "ch_more", "setelah 'lebih banyak', dialog lanjut ke teks tambahan")
	runner.select(-1)
	_check(runner.node_id == DialogueLibrary.START, "teks tambahan kembali ke sapaan utama")
	rl.accept("req_salam_wiryo")
	_check(rl.status("req_salam_wiryo") == RequestLog.ACTIVE, "permintaan Fase 4 tetap berjalan lewat RequestLog")


func _test_localization() -> void:
	var keys: Array[String] = ["ui.trust_gain", "ui.gift_done", "ui.gift_none", "ui.squest_taken", "ui.squest_ready", "ui.squest_done",
		"ui.squest_line", "ui.squest_line_ready", "ui.event_next", "book.trust", "book.quests", "book.tier.0", "book.tier.1", "book.tier.2",
		"ledger.tugas", "ledger.event", "dlg.choice.chapter", "dlg.choice.more", "dlg.choice.later", "dlg.choice.quest",
		"dlg.choice.quest_status", "dlg.choice.report_quest", "dlg.choice.gift", "dlg.chapter_later", "dlg.gift_thanks"]
	for id in SocialDb.npc_ids():
		for t in 3:
			keys.append("dlg.%s.t%d" % [id, t])
		for suf in ["ch1", "ch1_more", "ch2", "ch2_more"]:
			keys.append("dlg.%s.%s" % [id, suf])
	for qid in SocialDb.QUEST_ORDER:
		for suf in ["title", "offer", "accepted", "wait", "turn", "done"]:
			keys.append("sq.%s.%s" % [qid, suf])
		for opt in SocialDb.quest(qid)["choices"].keys():
			keys.append("sq.%s.opt.%s" % [qid, String(opt)])
	for eid in VillageEvents.ids():
		keys.append("event.%s.title" % eid)
		keys.append("event.%s.toast" % eid)
	var missing: Array[String] = []
	for k in keys:
		for lang in Locale.LANGS:
			if not Locale.has_key(k, lang):
				missing.append("%s[%s]" % [k, lang])
	_check(missing.is_empty(), "kunci Fase 8 lengkap di ID+EN (%d kunci; hilang: %s)" % [keys.size(), str(missing.slice(0, 8))])
	Locale.set_language("id")
	_check(EconomyText.reason_text("event:pasar_desa") == "Event: Pasar Desa", "teks alasan event di buku kas")
	_check(EconomyText.reason_text("tugas:q_karto_kebun") == "Tugas: " + Locale.t("sq.q_karto_kebun.title"), "teks alasan tugas di buku kas")


func _has_choice(nodes: Dictionary, node_key: String, label: String) -> bool:
	for c in nodes[node_key]["choices"]:
		if String(c["label"]) == label:
			return true
	return false


func _action_of(node: Dictionary, label: String) -> String:
	for c in node["choices"]:
		if String(c["label"]) == label:
			return String(c["action"])
	return ""
