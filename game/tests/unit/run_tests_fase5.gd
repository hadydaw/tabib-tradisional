extends SceneTree
## Tes unit Fase 5: penilaian, skill, inventaris, data fiktif, diagnosis, akupunktur, peracikan,
## identifikasi tanaman, kebun, alur pengobatan terintegrasi dengan antrean Fase 4, dan localization.
## Jalankan: godot --headless --path game -s res://tests/unit/run_tests_fase5.gd

var _count: int = 0
var _fail: int = 0


func _init() -> void:
	_test_grade_and_scoring()
	_test_rhythm()
	_test_data()
	_test_skills_and_inventory()
	_test_clinic_stats()
	_test_diagnosis()
	_test_acupuncture()
	_test_crafting()
	_test_plant_id()
	_test_garden()
	_test_treatment_flow()
	_test_treatment_wrong_diagnosis_and_failures()
	_test_localization_complete()
	print("Tes Fase 5 dijalankan: %d, gagal: %d" % [_count, _fail])
	quit(1 if _fail > 0 else 0)


func _check(condition: bool, name: String) -> void:
	_count += 1
	if condition:
		print("  OK   ", name)
	else:
		_fail += 1
		printerr("  GAGAL ", name)


# --- Penilaian ---------------------------------------------------------------

func _test_grade_and_scoring() -> void:
	_check(Grade.from_score(100.0) == Grade.Level.S and Grade.from_score(92.0) == Grade.Level.S, "skor 92+ = S")
	_check(Grade.from_score(91.9) == Grade.Level.A and Grade.from_score(80.0) == Grade.Level.A, "skor 80-91 = A")
	_check(Grade.from_score(79.9) == Grade.Level.B and Grade.from_score(65.0) == Grade.Level.B, "skor 65-79 = B")
	_check(Grade.from_score(64.9) == Grade.Level.C and Grade.from_score(45.0) == Grade.Level.C, "skor 45-64 = C")
	_check(Grade.from_score(44.9) == Grade.Level.D and Grade.from_score(0.0) == Grade.Level.D, "skor <45 = D")
	_check(Grade.letter(Grade.Level.S) == "S" and Grade.letter(Grade.Level.D) == "D", "huruf tingkat")
	var mono: bool = true
	for g in range(1, 5):
		if Grade.quality(g) <= Grade.quality(g - 1) or Grade.base_xp(g) <= Grade.base_xp(g - 1):
			mono = false
	_check(mono, "kualitas dan XP naik monoton menurut tingkat")
	var w: Dictionary = {"a": 0.5, "b": 0.5}
	_check(is_equal_approx(ScoringSystem.compose({"a": 1.0, "b": 0.0}, w), 50.0), "compose bobot 50/50")
	_check(ScoringSystem.compose({"a": 2.0, "b": -1.0}, w) == 50.0, "komponen dibatasi 0..1")
	# waktu bukan penentu tunggal
	var wt: Dictionary = {"ketepatan": 0.5, "waktu": 0.5}
	var slow_perfect: float = ScoringSystem.compose({"ketepatan": 1.0, "waktu": 0.0}, wt)
	var fast_wrong: float = ScoringSystem.compose({"ketepatan": 0.0, "waktu": 1.0}, wt)
	_check(slow_perfect >= 80.0, "sempurna tapi sangat lambat tetap >= A (%.1f)" % slow_perfect)
	_check(fast_wrong <= 20.0 and Grade.from_score(fast_wrong) == Grade.Level.D, "cepat tapi salah tetap D (%.1f)" % fast_wrong)
	_check(ScoringSystem.time_factor(5.0, 10.0, 60.0) == 1.0, "waktu <= par -> 1")
	_check(ScoringSystem.time_factor(1000.0, 10.0, 60.0) == ScoringSystem.TIME_FLOOR, "waktu terlalu lama -> lantai")
	_check(ScoringSystem.time_factor(35.0, 10.0, 60.0) < 1.0 and ScoringSystem.time_factor(35.0, 10.0, 60.0) > ScoringSystem.TIME_FLOOR, "waktu antara par dan batas -> menurun")
	_check(ScoringSystem.error_factor(0, 0.25) == 1.0 and ScoringSystem.error_factor(2, 0.25) == 0.5 and ScoringSystem.error_factor(9, 0.25) == 0.0, "faktor kesalahan")
	_check(ScoringSystem.order_factor(["a", "b", "c"], ["a", "b", "c"]) == 1.0, "urutan benar = 1")
	_check(ScoringSystem.order_factor(["a", "b", "c"], ["c", "b", "a"]) == 0.0, "urutan terbalik = 0")
	_check(is_equal_approx(ScoringSystem.order_factor(["a", "b", "c"], ["a", "c", "b"]), 2.0 / 3.0), "urutan sebagian")
	_check(ScoringSystem.order_factor(["a", "b", "c"], ["a"]) == 1.0, "satu item -> 1")
	var r: MinigameResult = ScoringSystem.make_result("diagnosis", "x", {"a": 1.0}, {"a": 1.0}, 0, 3.0, 1, Grade.Level.C)
	_check(r.score == 100.0 and r.grade == Grade.Level.C, "cap membatasi tingkat")
	var r2: MinigameResult = ScoringSystem.make_result("diagnosis", "x", {"a": 1.0}, {"a": 1.0}, 0, 3.0)
	_check(r2.grade == Grade.Level.S and r2.letter() == "S" and r2.to_dict()["grade"] == "S", "tanpa cap = S")


func _test_rhythm() -> void:
	var beats: Array = [1.0, 2.0, 3.0, 4.0]
	var perfect: Dictionary = RhythmJudge.judge(beats, [1.0, 2.01, 2.99, 4.0], 0.08, 0.2)
	_check(float(perfect["score"]) > 0.99 and int(perfect["perfect"]) == 4, "ritme sempurna")
	var none: Dictionary = RhythmJudge.judge(beats, [], 0.08, 0.2)
	_check(float(none["score"]) == 0.0 and int(none["miss"]) == 4, "tanpa ketukan = 0")
	var late: Dictionary = RhythmJudge.judge(beats, [1.5, 2.5, 3.5, 4.5], 0.08, 0.2)
	_check(float(late["score"]) == 0.0, "ketukan di luar jendela = 0")
	var spam: Dictionary = RhythmJudge.judge(beats, [1.0, 1.05, 1.1, 1.15, 2.0, 3.0, 4.0, 4.1], 0.08, 0.2)
	_check(float(spam["score"]) < 0.8 and int(spam["extra"]) >= 3, "ketukan berlebih dihukum")
	var half: Dictionary = RhythmJudge.judge(beats, [1.0, 2.0], 0.08, 0.2)
	_check(is_equal_approx(float(half["score"]), 0.5), "separuh ketukan = 0.5")
	var near: Dictionary = RhythmJudge.judge([1.0], [1.14], 0.08, 0.2)
	_check(float(near["score"]) > 0.0 and float(near["score"]) < 1.0 and int(near["good"]) == 1, "ketukan 'bagus' parsial")
	var gaps: Array[float] = DiagnosisSystem.pulse_beats_for("cepat")
	var gaps2: Array[float] = DiagnosisSystem.pulse_beats_for("lambat")
	_check(gaps.size() == DiagnosisSystem.PULSE_BEATS and gaps2[1] - gaps2[0] > gaps[1] - gaps[0], "nadi cepat lebih rapat daripada lambat")


# --- Data fiktif -------------------------------------------------------------

func _test_data() -> void:
	# titik akupunktur
	var tags: Dictionary = {}
	var pts_ok: bool = true
	for id in AcupointDb.IDS:
		if not AcupointDb.has(id) or tags.has(AcupointDb.tag(id)):
			pts_ok = false
		tags[AcupointDb.tag(id)] = true
		var pp: Vector2 = AcupointDb.pos(id)
		if pp.x < 0.0 or pp.x > 1.0 or pp.y < 0.0 or pp.y > 1.0:
			pts_ok = false
	_check(pts_ok and AcupointDb.IDS.size() == AcupointDb.DATA.size(), "titik akupunktur: tag unik, posisi dalam tubuh (%d titik)" % AcupointDb.IDS.size())
	# penyakit
	var ail_ok: bool = true
	var plan_ok: bool = true
	for id in AilmentDb.IDS:
		var prof: Dictionary = AilmentDb.profile(id)
		for area in AilmentDb.AREAS:
			if not (AilmentDb.VALUES[area] as Array).has(prof.get(area, "")):
				ail_ok = false
		var plan: Array[String] = AilmentDb.acu_plan(id)
		var ptags: Dictionary = {}
		for pid in plan:
			if not AcupointDb.has(pid) or ptags.has(AcupointDb.tag(pid)):
				plan_ok = false
			ptags[AcupointDb.tag(pid)] = true
		if plan.size() < 2 or plan.size() > AcupunctureSystem.MAX_POINTS:
			plan_ok = false
		if AilmentDb.acu_fit(id) <= 0.0 or AilmentDb.acu_fit(id) > 1.0:
			plan_ok = false
	_check(ail_ok, "profil penyakit: semua nilai temuan valid")
	_check(plan_ok, "rencana akupunktur valid (titik ada, tag unik per rencana)")
	_check(AilmentDb.IDS.size() == AilmentDb.DATA.size() and AilmentDb.IDS.size() >= 10, "jumlah penyakit fiktif: %d" % AilmentDb.IDS.size())
	var dist_ok: bool = true
	var min_dist: int = 99
	for c in ComplaintCatalog.IDS:
		var cand: Array[String] = AilmentDb.candidates_for(c)
		if cand.size() < 2:
			dist_ok = false
		for i in range(cand.size()):
			for j in range(i + 1, cand.size()):
				var d: int = AilmentDb.distance(cand[i], cand[j])
				min_dist = mini(min_dist, d)
				if d < 3:
					dist_ok = false
	_check(dist_ok, "tiap keluhan punya >= 2 kandidat yang berbeda minimal 3 area (min %d)" % min_dist)
	_check(AilmentDb.pick_for("demam_dingin", 5) == AilmentDb.pick_for("demam_dingin", 5), "pilihan penyakit deterministik")
	_check(AilmentDb.candidates_for("demam_dingin").has(AilmentDb.pick_for("demam_dingin", 12345)), "penyakit terpilih cocok keluhan")
	# herbal
	var herb_ok: bool = true
	for id in HerbDb.IDS:
		for part in HerbDb.PARTS:
			if not (HerbDb.TRAITS[part] as Array).has(HerbDb.trait_of(id, part)):
				herb_ok = false
		if not HerbDb.is_unique_among(id, HerbDb.IDS, HerbDb.PARTS):
			herb_ok = false
	_check(herb_ok and HerbDb.IDS.size() == HerbDb.DATA.size(), "tanaman: ciri valid dan tiap tanaman unik (%d)" % HerbDb.IDS.size())
	var stock_ok: bool = true
	for id in HerbDb.STARTER_STOCK.keys():
		if not HerbDb.has(String(id)):
			stock_ok = false
	_check(stock_ok, "stok awal merujuk bahan yang ada")
	# resep
	var rec_ok: bool = true
	var fit_ok: bool = true
	for rid in RecipeDb.IDS:
		var steps: Array[Dictionary] = RecipeDb.steps(rid)
		if steps.size() < 3:
			rec_ok = false
		for s in steps:
			if not HerbDb.has(String(s["herb"])) or int(s["units"]) < 1 or float(s["grams"]) <= 0.0:
				rec_ok = false
		var fits: Dictionary = RecipeDb.get_data(rid)["fits"]
		for aid in fits.keys():
			if not AilmentDb.has(String(aid)) or float(fits[aid]) <= 0.0 or float(fits[aid]) > 1.0:
				fit_ok = false
	_check(rec_ok and fit_ok, "resep: bahan ada, jumlah/gram valid, kecocokan merujuk penyakit ada")
	var sigs: Dictionary = {}
	for rid in RecipeDb.IDS:
		sigs[str(RecipeDb.herb_order(rid))] = true
	_check(sigs.size() == RecipeDb.IDS.size(), "tiap resep punya komposisi/urutan berbeda")
	var cover_ok: bool = true
	for aid in AilmentDb.IDS:
		if RecipeDb.fit_for(RecipeDb.best_for(aid), aid) < 0.8 or RecipeDb.min_level(RecipeDb.best_for(aid)) > 3:
			cover_ok = false
	_check(cover_ok, "setiap penyakit punya resep cocok >= 0.8 yang terbuka pada Pengetahuan Herbal <= 3")
	_check(RecipeDb.unlocked(1).size() >= 3 and RecipeDb.unlocked(3).size() == RecipeDb.IDS.size(), "resep terbuka bertahap menurut tingkat")
	_check(RecipeDb.fit_for("ramuan_penghangat", "mata_pasir") == RecipeDb.OTHER_FIT, "resep tak terdaftar -> kecocokan dasar")


# --- Skill, inventaris -------------------------------------------------------

func _test_skills_and_inventory() -> void:
	var sk := SkillProgressionSystem.new()
	_check(SkillDb.BRANCHES.size() == 5, "lima cabang skill")
	for b in SkillDb.BRANCHES:
		if sk.level(b) != 1 or sk.xp_of(b) != 0:
			_check(false, "level awal 1: %s" % b)
	_check(sk.level("diagnosis") == 1, "level awal 1")
	var ups: Array = []
	sk.leveled_up.connect(func(b: String, l: int) -> void: ups.append("%s:%d" % [b, l]))
	_check(sk.add_xp("diagnosis", 59) == 0 and sk.level("diagnosis") == 1, "59 XP masih level 1")
	_check(sk.add_xp("diagnosis", 1) == 1 and sk.level("diagnosis") == 2 and ups == ["diagnosis:2"], "60 XP -> level 2 + sinyal")
	_check(sk.add_xp("diagnosis", 10000) >= 1 and sk.level("diagnosis") == SkillDb.MAX_LEVEL and sk.progress("diagnosis") == 1.0, "level maksimum dibatasi")
	_check(sk.add_xp("tidak_ada", 10) == 0 and sk.add_xp("diagnosis", -5) == 0, "cabang/jumlah tidak valid ditolak")
	# award per jenis
	var r := MinigameResult.new()
	r.kind = "identifikasi"
	r.grade = Grade.Level.A
	r.difficulty = 1
	var aw: Array[Dictionary] = sk.award(r)
	_check(aw.size() == 2 and sk.xp_of("identifikasi_tanaman") == 30 and sk.xp_of("pengetahuan_herbal") == 12 and r.xp == 30, "XP identifikasi: cabang utama + pengetahuan herbal")
	var r3 := MinigameResult.new()
	r3.kind = "peracikan"
	r3.grade = Grade.Level.S
	r3.difficulty = 3
	sk.award(r3)
	_check(sk.xp_of("peracikan") == 60 and r3.xp == 60, "XP dikalikan kesulitan (S, kesulitan 3 = 40 x 1.5)")
	var rd := MinigameResult.new()
	rd.kind = "diagnosis"
	rd.grade = Grade.Level.D
	var before: int = sk.xp_of("diagnosis")
	sk.award(rd)
	_check(sk.xp_of("diagnosis") == before + 5, "gagal (D) tetap memberi sedikit XP")
	# efek terbatas
	var bounded: bool = true
	for branch in SkillDb.EFFECTS.keys():
		for key in (SkillDb.EFFECTS[branch] as Dictionary).keys():
			var arr: Array = SkillDb.EFFECTS[branch][key]
			if arr.size() != SkillDb.MAX_LEVEL:
				bounded = false
			for i in range(1, arr.size()):
				if float(arr[i]) < float(arr[i - 1]) and key != "getar":
					bounded = false
	_check(bounded, "efek skill: panjang = MAX_LEVEL dan tidak menurun (kecuali getaran)")
	_check(SkillDb.effect("akupunktur", "radius", 5) <= 1.35 and SkillDb.effect("peracikan", "toleransi_takar", 5) <= 1.45, "bantuan skill terbatas (<= +45%)")
	_check(SkillDb.effect("akupunktur", "getar", 5) >= 0.6, "getaran tidak hilang sepenuhnya")
	# tanaman dikenal dan simpan/muat
	_check(sk.learn_plant("kunyit") and not sk.learn_plant("kunyit") and sk.knows_plant("kunyit"), "pengetahuan tanaman")
	var sk2 := SkillProgressionSystem.new()
	sk2.from_dict(sk.to_dict())
	_check(sk2.xp_of("diagnosis") == sk.xp_of("diagnosis") and sk2.knows_plant("kunyit") and sk2.level("peracikan") == sk.level("peracikan"), "to_dict/from_dict")
	# inventaris
	var inv := HerbInventory.new()
	_check(inv.count("kunyit") == int(HerbDb.STARTER_STOCK["kunyit"]), "stok awal")
	_check(inv.remove("kunyit", 2) and inv.count("kunyit") == int(HerbDb.STARTER_STOCK["kunyit"]) - 2, "ambil bahan")
	_check(not inv.remove("kunyit", 99) and not inv.remove("kunyit", 0), "tidak bisa ambil melebihi stok")
	_check(inv.add("jahe", 3) and not inv.add("batu", 1) and not inv.add("jahe", 0), "tambah bahan valid saja")
	for id in HerbDb.IDS:
		inv.remove(id, inv.count(id))
	_check(inv.total() == 0 and inv.ids_in_stock().is_empty(), "inventaris kosong")
	inv.restock_daily()
	var restocked: bool = true
	for id in HerbDb.IDS:
		if inv.count(id) != HerbInventory.DAILY_MIN:
			restocked = false
	_check(restocked, "stok harian menjamin minimal %d tiap bahan" % HerbInventory.DAILY_MIN)
	var inv2 := HerbInventory.new()
	var fired: Array = []
	inv2.changed.connect(func() -> void: fired.append(1))
	inv2.add("serai", 1)
	inv2.remove("serai", 1)
	_check(fired.size() == 2, "sinyal changed")


func _test_clinic_stats() -> void:
	_check(ClinicStats.fee_for(40, 1.0, 0.0) == 48 and ClinicStats.fee_for(40, 0.5, 0.0) == 32, "biaya naik dengan kualitas")
	_check(ClinicStats.fee_for(40, 0.1, 50.0) == 0, "kualitas rendah -> tanpa biaya")
	_check(ClinicStats.fee_for(40, 1.0, 100.0) > ClinicStats.fee_for(40, 1.0, 0.0), "reputasi menaikkan biaya")
	var cs := ClinicStats.new()
	cs.record_visit({"fee": 50, "grade": Grade.Level.S, "satisfaction": 90.0, "outcome": "sembuh"})
	_check(cs.money == 50 and cs.treated == 1 and cs.cured == 1 and cs.reputation == ClinicStats.START_REPUTATION + 3.0, "kunjungan S: uang, pasien, reputasi +3")
	cs.record_visit({"fee": 0, "grade": Grade.Level.D, "satisfaction": 10.0, "outcome": "gagal"})
	_check(cs.reputation == ClinicStats.START_REPUTATION + 1.0 and is_equal_approx(cs.average_satisfaction(), 50.0), "kunjungan D: reputasi -2, rata-rata kepuasan")
	for _i in range(60):
		cs.record_visit({"fee": 0, "grade": Grade.Level.D, "satisfaction": 0.0, "outcome": "gagal"})
	_check(cs.reputation == 0.0, "reputasi tidak di bawah 0")
	for _i in range(60):
		cs.record_visit({"fee": 0, "grade": Grade.Level.S, "satisfaction": 0.0, "outcome": "sembuh"})
	_check(cs.reputation == 100.0, "reputasi tidak di atas 100")


# --- Diagnosis ---------------------------------------------------------------

## Pemain ideal: amati, lalu periksa area yang paling banyak menyingkirkan kandidat sampai tinggal satu.
func _play_diagnosis(ailment: String, complaint: String, level: int, seed_value: int, pulse_acc: float) -> DiagnosisSystem:
	var d := DiagnosisSystem.new()
	d.setup(ailment, complaint, level, seed_value)
	d.observe()
	var guard: int = 0
	while d.remaining().size() > 1 and d.energy_left > 0 and guard < 10:
		guard += 1
		var best_area: String = ""
		var best_elim: int = 0
		for area in AilmentDb.AREAS:
			if d.findings.has(area):
				continue
			var groups: Dictionary = {}
			for c in d.remaining():
				groups[AilmentDb.finding(c, area)] = true
			if groups.size() > 1 and groups.size() > best_elim:
				best_elim = groups.size()
				best_area = area
		if best_area == "":
			break
		d.update(1.0)
		if best_area == AilmentDb.PULSE_AREA:
			d.inspect_pulse(pulse_acc)
		else:
			d.inspect(best_area)
	return d


func _test_diagnosis() -> void:
	var all_ok: bool = true
	var all_a: bool = true
	var checked: int = 0
	for ailment in AilmentDb.IDS:
		for complaint in (AilmentDb.DATA[ailment]["complaints"] as Array):
			var d: DiagnosisSystem = _play_diagnosis(ailment, String(complaint), 1, checked, 0.9)
			var rem: Array[String] = d.remaining()
			if rem.size() != 1 or rem[0] != ailment:
				all_ok = false
			var res: Dictionary = d.submit(ailment)
			if not bool(res["correct"]) or not d.is_finished():
				all_ok = false
			elif d.result.grade < Grade.Level.A:
				all_a = false
			checked += 1
	_check(all_ok, "pemain ideal mempersempit ke 1 kandidat dan diagnosis benar (%d kasus)" % checked)
	_check(all_a, "diagnosis ideal selalu >= A di semua kasus")
	# batas tenaga
	var d1 := DiagnosisSystem.new()
	d1.setup("demam_embun", "demam_dingin", 1, 1)
	_check(d1.energy_max == 4 and d1.energy_left == 4, "tenaga periksa level 1 = 4")
	_check(d1.inspect("dahi")["ok"] and d1.inspect("lidah")["ok"] and d1.inspect("kulit")["ok"] and d1.inspect("perut")["ok"], "4 pemeriksaan pertama berhasil")
	_check(not d1.inspect("mata")["ok"] and d1.energy_left == 0, "tenaga habis -> pemeriksaan ditolak")
	var dh := DiagnosisSystem.new()
	dh.setup("demam_embun", "demam_dingin", 5, 1)
	_check(dh.energy_max == 6 and dh.helper_marks() and dh.pulse_window_scale() > 1.0, "skill diagnosis tinggi: tenaga +2, tanda bantu, jendela nadi")
	_check(not d1.helper_marks(), "level 1 tanpa tanda bantu")
	# pemeriksaan ganda dan area tidak valid
	var d2 := DiagnosisSystem.new()
	d2.setup("angin_gelombang", "pusing_berputar", 1, 2)
	_check(d2.inspect("dahi")["ok"] and not d2.inspect("dahi")["ok"] and not d2.inspect("telinga")["ok"] and not d2.inspect("nadi")["ok"], "area ganda/tidak valid/nadi lewat inspect ditolak")
	_check(d2.energy_left == 3, "pemeriksaan ditolak tidak memakai tenaga")
	# nadi gagal terbaca
	var d3 := DiagnosisSystem.new()
	d3.setup("angin_gelombang", "pusing_berputar", 1, 2)
	var bad: Dictionary = d3.inspect_pulse(0.1)
	_check(bool(bad["ok"]) and not bool(bad["readable"]) and not d3.findings.has("nadi") and d3.energy_left == 3 and d3.failed_pulses == 1, "nadi tak terbaca memakai tenaga tanpa petunjuk")
	var good: Dictionary = d3.inspect_pulse(0.8)
	_check(bool(good["readable"]) and String(good["value"]) == "lambat", "nadi terbaca -> nilai benar")
	_check(not d3.inspect_pulse(0.9)["ok"], "nadi tidak bisa diulang setelah terbaca")
	# tebakan tanpa bukti cukup dibatasi
	var d4 := DiagnosisSystem.new()
	d4.setup("angin_gelombang", "pusing_berputar", 1, 3)
	d4.update(5.0)
	_check(not d4.can_submit(), "belum bisa menetapkan tanpa pemeriksaan")
	d4.inspect("kulit")   # kulit/perut tidak membedakan ketiga kandidat pusing -> sia-sia
	_check(d4.wasted == 1 and d4.remaining().size() == 3, "pemeriksaan yang tidak menyingkirkan kandidat dihitung sia-sia")
	var luck: Dictionary = d4.submit("angin_gelombang")
	_check(bool(luck["correct"]) and d4.result.grade <= Grade.Level.B, "benar tanpa bukti cukup dibatasi maks B (%s)" % d4.result.letter())
	var dobs := DiagnosisSystem.new()
	dobs.setup("angin_gelombang", "pusing_berputar", 1, 3)
	var ob: Dictionary = dobs.observe()
	_check(bool(ob["ok"]) and AilmentDb.VISIBLE_AREAS.has(String(ob["area"])) and not dobs.observe()["ok"] and dobs.energy_left == dobs.energy_max, "amati pasien: satu temuan gratis, sekali saja, tanpa tenaga")
	# salah dua kali
	var d5 := DiagnosisSystem.new()
	d5.setup("angin_gelombang", "pusing_berputar", 1, 4)
	d5.observe()
	d5.inspect("dahi")
	var w1: Dictionary = d5.submit("kepala_kabut")
	_check(bool(w1["ok"]) and not bool(w1["correct"]) and not bool(w1["finished"]) and d5.errors == 1, "tebakan salah pertama: lanjut")
	_check(not d5.submit("kepala_kabut")["ok"] and not d5.submit("batuk_debu")["ok"], "tebakan ulang/di luar kandidat ditolak")
	var w2: Dictionary = d5.submit("mata_pasir")
	_check(not bool(w2["correct"]) and bool(w2["finished"]) and d5.result.grade == Grade.Level.D, "salah dua kali -> selesai, D")
	_check(not d5.inspect("kulit")["ok"], "setelah selesai tidak bisa memeriksa")
	# benar pada tebakan kedua
	var d6 := DiagnosisSystem.new()
	d6.setup("angin_gelombang", "pusing_berputar", 1, 5)
	d6.observe()
	d6.inspect("dahi")
	d6.submit("kepala_kabut")
	var second: Dictionary = d6.submit("angin_gelombang")
	_check(bool(second["correct"]) and d6.result.grade <= Grade.Level.B and d6.result.grade >= Grade.Level.D, "benar di tebakan kedua dibatasi maks B")
	_check(d6.mark("angin_gelombang", "dahi") == 1 and d6.mark("kepala_kabut", "dahi") == -1 and d6.mark("angin_gelombang", "perut") == 0, "tanda bantu cocok/bertentangan/tak diketahui")
	# pemeriksaan tidak relevan menurunkan skor relevansi
	var d7 := DiagnosisSystem.new()
	d7.setup("demam_embun", "demam_dingin", 5, 6)
	d7.observe()
	var redundant: int = 0
	for area in ["dahi", "lidah", "kulit", "perut", "mata"]:
		d7.inspect(area)
	if d7.wasted > 0:
		redundant = d7.wasted
	d7.submit("demam_embun")
	_check(d7.result.components["relevansi"] <= 1.0 and (redundant == 0 or d7.result.components["relevansi"] < 1.0), "relevansi turun bila ada pemeriksaan sia-sia")
	# hasil konsisten (deterministik)
	var ra: DiagnosisSystem = _play_diagnosis("kulit_getah", "gatal_kulit", 2, 9, 0.9)
	var rb: DiagnosisSystem = _play_diagnosis("kulit_getah", "gatal_kulit", 2, 9, 0.9)
	ra.submit("kulit_getah")
	rb.submit("kulit_getah")
	_check(ra.result.score == rb.result.score and ra.result.grade == rb.result.grade, "hasil penilaian konsisten untuk masukan sama")


# --- Akupunktur --------------------------------------------------------------

func _play_acu(ailment: String, hint: String, level: int, pos_off: Vector2, depth: float, order_reverse: bool = false) -> AcupunctureSystem:
	var a := AcupunctureSystem.new()
	a.setup(ailment, hint, level, 7)
	var plan: Array[String] = AilmentDb.acu_plan(ailment)
	if order_reverse:
		plan.reverse()
	for p in plan:
		a.toggle_point(p)
	a.update(30.0)
	a.begin_insertion()
	while a.phase == AcupunctureSystem.Phase.JARUM:
		a.insert(pos_off, depth)
	return a


func _test_acupuncture() -> void:
	var all_s: bool = true
	for ailment in AilmentDb.IDS:
		var a: AcupunctureSystem = _play_acu(ailment, "", 1, Vector2.ZERO, AcupunctureSystem.DEPTH_CENTER)
		if not a.is_finished() or a.result.grade < Grade.Level.S:
			all_s = false
	_check(all_s, "akupunktur sempurna (titik benar, urutan benar, presisi penuh) = S untuk semua penyakit")
	var a2 := AcupunctureSystem.new()
	a2.setup("demam_embun", "", 1, 7)
	_check(a2.hint_tags() == ["tenang", "hangat", "selaras"], "petunjuk = tag rencana berurutan (%s)" % str(a2.hint_tags()))
	_check(a2.toggle_point("ubun_embun") and a2.selected == ["ubun_embun"], "pilih titik")
	_check(a2.toggle_point("ubun_embun") and a2.selected.is_empty(), "pilih lagi = batal pilih")
	_check(not a2.toggle_point("titik_palsu"), "titik tidak dikenal ditolak")
	for p in ["ubun_embun", "alis_pagi", "pelipis_angin", "leher_kendi", "bahu_batu"]:
		a2.toggle_point(p)
	_check(not a2.toggle_point("dada_telaga") and a2.selected.size() == AcupunctureSystem.MAX_POINTS, "maksimum titik dibatasi")
	var empty := AcupunctureSystem.new()
	empty.setup("demam_embun", "", 1, 7)
	_check(not empty.begin_insertion() and not empty.insert(Vector2.ZERO, 0.6)["ok"], "tanpa titik tidak bisa menusuk")
	# presisi menurun dengan jarak
	var near: Dictionary = a2.score_insertion(Vector2(0.0, 0.0), 0.62)
	var mid: Dictionary = a2.score_insertion(Vector2(a2.target_radius() * 0.9, 0.0), 0.62)
	var far: Dictionary = a2.score_insertion(Vector2(a2.target_radius() * 2.0, 0.0), 0.62)
	_check(float(near["pos"]) == 1.0 and float(mid["pos"]) < 1.0 and float(mid["pos"]) > 0.0 and float(far["pos"]) == 0.0, "skor posisi: tepat > dekat > jauh=0")
	var shallow: Dictionary = a2.score_insertion(Vector2.ZERO, 0.1)
	var deep: Dictionary = a2.score_insertion(Vector2.ZERO, 0.62)
	_check(float(shallow["depth"]) < float(deep["depth"]) and float(deep["depth"]) == 1.0, "skor kedalaman: zona hijau = 1")
	# kualitas
	var mediocre: AcupunctureSystem = _play_acu("demam_embun", "", 1, Vector2(0.12, 0.0), 0.45)
	var sloppy: AcupunctureSystem = _play_acu("demam_embun", "", 1, Vector2(0.5, 0.0), 0.2)
	var perfect: AcupunctureSystem = _play_acu("demam_embun", "", 1, Vector2.ZERO, 0.62)
	_check(perfect.result.score > mediocre.result.score and mediocre.result.score > sloppy.result.score, "ketepatan memengaruhi skor (%.0f > %.0f > %.0f)" % [perfect.result.score, mediocre.result.score, sloppy.result.score])
	_check(sloppy.result.grade <= Grade.Level.C, "penusukan meleset jauh <= C")
	# urutan
	var rev: AcupunctureSystem = _play_acu("demam_embun", "", 1, Vector2.ZERO, 0.62, true)
	_check(rev.result.components["urutan"] < 1.0 and rev.result.score < perfect.result.score, "urutan terbalik menurunkan skor")
	# titik salah = kesalahan
	var wrong := AcupunctureSystem.new()
	wrong.setup("demam_embun", "", 1, 7)
	for p in ["ubun_embun", "pusar_bulan", "pergelangan_nadi", "lutut_batu", "bahu_batu"]:
		wrong.toggle_point(p)
	wrong.begin_insertion()
	while wrong.phase == AcupunctureSystem.Phase.JARUM:
		wrong.insert(Vector2.ZERO, 0.62)
	_check(wrong.result.errors == 2 and wrong.result.components["kesalahan"] == 0.5 and wrong.result.score < perfect.result.score, "titik di luar rencana dihitung kesalahan")
	# hanya titik salah
	var allwrong := AcupunctureSystem.new()
	allwrong.setup("demam_embun", "", 1, 7)
	allwrong.toggle_point("lutut_batu")
	allwrong.begin_insertion()
	allwrong.insert(Vector2.ZERO, 0.62)
	_check(allwrong.result.grade == Grade.Level.D, "tak ada titik rencana ditusuk -> D")
	# sebagian
	var partial := AcupunctureSystem.new()
	partial.setup("demam_embun", "", 1, 7)
	partial.toggle_point("ubun_embun")
	partial.begin_insertion()
	partial.insert(Vector2.ZERO, 0.62)
	_check(partial.is_finished() and partial.result.grade <= Grade.Level.C and partial.result.components["kelengkapan"] < 0.5, "hanya 1 dari 3 titik -> kelengkapan rendah, maks C")
	# diagnosis salah -> petunjuk dari penyakit lain, tetapi penilaian vs penyakit sebenarnya
	var mis := AcupunctureSystem.new()
	mis.setup("demam_embun", "angin_gelombang", 1, 7)
	_check(mis.hint_tags() == ["lancar", "sejuk", "selaras"] and mis.plan == AilmentDb.acu_plan("demam_embun"), "petunjuk dari diagnosis, penilaian dari penyakit sebenarnya")
	# skill: sasaran lebih besar, getaran lebih kecil, tetapi tetap ada
	var l1 := AcupunctureSystem.new()
	l1.setup("angin_gelombang", "", 1, 7)
	var l5 := AcupunctureSystem.new()
	l5.setup("angin_gelombang", "", 5, 7)
	_check(l5.target_radius() > l1.target_radius() and l5.tremor_amplitude() < l1.tremor_amplitude() and l5.tremor_amplitude() > 0.0, "skill memperbesar sasaran dan mengurangi getaran (tidak menghilangkannya)")
	_check(l5.depth_half_width() > l1.depth_half_width(), "skill memperlebar zona kedalaman")
	var hard := AcupunctureSystem.new()
	hard.setup("kulit_lembap", "", 1, 7)
	_check(hard.target_radius() < l1.target_radius() * 1.2 and hard.tremor_amplitude() > AcupunctureSystem.new().tremor_amplitude(), "penyakit sulit: sasaran lebih kecil dan getaran lebih besar")
	# getaran deterministik dan terbatas
	var t1: Vector2 = l1.tremor_offset(1.234)
	_check(t1 == l1.tremor_offset(1.234) and t1.length() <= l1.tremor_amplitude() * 2.5, "getaran deterministik dan terbatas")
	var dmin: float = 9.0
	var dmax: float = -9.0
	for i in range(100):
		var dv: float = l1.depth_at(float(i) * 0.05)
		dmin = minf(dmin, dv)
		dmax = maxf(dmax, dv)
	_check(dmin >= 0.0 and dmax <= 1.0 and dmax > 0.9, "penanda kedalaman bolak-balik 0..1")
	# selesai dini
	var early := AcupunctureSystem.new()
	early.setup("demam_embun", "", 1, 7)
	early.toggle_point("ubun_embun")
	early.toggle_point("pusar_bulan")
	early.begin_insertion()
	early.insert(Vector2.ZERO, 0.62)
	early.finish_early()
	_check(early.is_finished() and early.insertions.size() == 1, "sesi dapat diakhiri lebih awal")


# --- Peracikan ---------------------------------------------------------------

func _play_craft(recipe: String, inv: HerbInventory, herbal_lvl: int, craft_lvl: int, grams_factor: float = 1.0, tap_offset: float = 0.0, stir_ok: bool = true) -> HerbalCraftingSystem:
	var h := HerbalCraftingSystem.new()
	h.setup(recipe, inv, herbal_lvl, craft_lvl)
	for s in h.steps:
		for _u in range(int(s["units"])):
			h.take_herb(String(s["herb"]))
	h.update(40.0)
	h.confirm_picks()
	for s in h.steps:
		h.submit_measure(float(s["grams"]) * grams_factor)
	for b in h.pound_beats:
		h.pound_tap(float(b) + tap_offset)
	h.finish_pound()
	var dir_sign: float = 1.0
	var guard: int = 0
	while not h.is_finished() and guard < 2000:
		h.stir_move(0.05 * dir_sign, 0.025 if stir_ok else 0.2)   # 2 rad/dtk (baik) atau 0.25 rad/dtk (terlalu lambat)
		if not stir_ok and guard % 2 == 1:
			dir_sign = -dir_sign
		guard += 1
	return h


func _test_crafting() -> void:
	var all_s: bool = true
	for rid in RecipeDb.IDS:
		var inv := HerbInventory.new()
		var h: HerbalCraftingSystem = _play_craft(rid, inv, 3, 1)
		if not h.is_finished() or h.result.grade < Grade.Level.S:
			all_s = false
			printerr("   resep ", rid, " skor ", h.result.score if h.result != null else -1.0)
	_check(all_s, "peracikan sempurna = S untuk semua resep")
	# inventaris berkurang sesuai bahan
	var inv := HerbInventory.new()
	var kun0: int = inv.count("kunyit")
	var jahe0: int = inv.count("jahe")
	_play_craft("ramuan_penghangat", inv, 1, 1)
	_check(inv.count("kunyit") == kun0 - 2 and inv.count("jahe") == jahe0 - 1, "bahan diambil dari inventaris (kunyit -2, jahe -1)")
	# bahan salah / berlebih
	var inv2 := HerbInventory.new()
	var h2 := HerbalCraftingSystem.new()
	h2.setup("ramuan_penghangat", inv2, 1, 1)
	_check(h2.take_herb("sirih") and h2.errors == 1, "bahan di luar resep = kesalahan")
	_check(h2.undo_pick() and h2.errors == 0 and inv2.count("sirih") == int(HerbDb.STARTER_STOCK["sirih"]), "urungkan mengembalikan bahan dan kesalahan")
	for _i in range(3):
		h2.take_herb("jahe")
	_check(h2.errors == 2 and h2.count_picked("jahe") == 3, "jumlah berlebih dihitung kesalahan (2 kelebihan)")
	_check(h2.composition_score() < 1.0, "komposisi tidak sempurna")
	# stok habis
	var empty := HerbInventory.new()
	for id in HerbDb.IDS:
		empty.remove(id, empty.count(id))
	var h3 := HerbalCraftingSystem.new()
	h3.setup("ramuan_penghangat", empty, 1, 1)
	_check(not h3.take_herb("kunyit") and h3.picks.is_empty() and h3.shortages().size() == 3, "stok habis -> tidak bisa ambil, kekurangan tercatat")
	_check(not h3.confirm_picks(), "tanpa bahan tidak bisa lanjut")
	# abort mengembalikan bahan
	var inv4 := HerbInventory.new()
	var before: int = inv4.total()
	var h4 := HerbalCraftingSystem.new()
	h4.setup("ramuan_penghangat", inv4, 1, 1)
	h4.take_herb("kunyit")
	h4.take_herb("jahe")
	_check(inv4.total() == before - 2, "dua bahan terambil")
	h4.abort()
	_check(inv4.total() == before and h4.picks.is_empty(), "abort mengembalikan semua bahan")
	# kualitas menurun karena kesalahan
	var perfect: HerbalCraftingSystem = _play_craft("ramuan_penghangat", HerbInventory.new(), 1, 1)
	var bad_measure: HerbalCraftingSystem = _play_craft("ramuan_penghangat", HerbInventory.new(), 1, 1, 1.5)
	var bad_pound: HerbalCraftingSystem = _play_craft("ramuan_penghangat", HerbInventory.new(), 1, 1, 1.0, 0.5)
	var bad_stir: HerbalCraftingSystem = _play_craft("ramuan_penghangat", HerbInventory.new(), 1, 1, 1.0, 0.0, false)
	_check(bad_measure.result.score < perfect.result.score - 5.0 and bad_measure.result.components["takaran"] == 0.0, "takaran meleset menurunkan kualitas")
	_check(bad_pound.result.score < perfect.result.score - 5.0 and bad_pound.result.components["tumbuk"] == 0.0, "menumbuk tidak sesuai ritme menurunkan kualitas")
	_check(bad_stir.is_finished() and bad_stir.result.score < perfect.result.score, "mengaduk tidak stabil menurunkan kualitas (%.1f < %.1f)" % [bad_stir.result.score, perfect.result.score])
	# urutan bahan
	var inv5 := HerbInventory.new()
	var h5 := HerbalCraftingSystem.new()
	h5.setup("ramuan_penghangat", inv5, 1, 1)
	for hid in ["serai", "jahe", "kunyit", "kunyit"]:
		h5.take_herb(hid)
	_check(h5.order_score() == 0.0 and h5.composition_score() == 1.0, "urutan bahan terbalik: urutan 0, komposisi tetap 1")
	# bahan kurang -> dibatasi
	var inv6 := HerbInventory.new()
	var h6 := HerbalCraftingSystem.new()
	h6.setup("ramuan_penghangat", inv6, 1, 1)
	h6.take_herb("kunyit")
	h6.confirm_picks()
	for s in h6.steps:
		h6.submit_measure(float(s["grams"]))
	for b in h6.pound_beats:
		h6.pound_tap(float(b))
	h6.finish_pound()
	var g6: int = 0
	while not h6.is_finished() and g6 < 2000:
		h6.stir_move(0.05, 0.025)
		g6 += 1
	_check(h6.result.grade <= Grade.Level.D, "bahan sangat kurang -> D (komposisi %.2f)" % h6.composition_score())
	# urutan tahap
	var h7 := HerbalCraftingSystem.new()
	h7.setup("ramuan_penghangat", HerbInventory.new(), 1, 1)
	_check(not h7.submit_measure(10.0)["ok"] and not h7.confirm_picks(), "tahap TAKAR/lanjut ditolak sebelum bahan dipilih")
	h7.take_herb("kunyit")
	h7.confirm_picks()
	_check(not h7.take_herb("jahe"), "tidak bisa mengambil bahan setelah tahap PILIH")
	# skill memperlebar toleransi
	var hs1 := HerbalCraftingSystem.new()
	hs1.setup("ramuan_penghangat", HerbInventory.new(), 1, 1)
	var hs5 := HerbalCraftingSystem.new()
	hs5.setup("ramuan_penghangat", HerbInventory.new(), 5, 5)
	_check(hs5.measure_tolerance() > hs1.measure_tolerance() and hs5.pound_window_scale() > hs1.pound_window_scale() and hs5.shows_amounts() and not hs1.shows_amounts(), "skill: toleransi takaran/tumbuk lebih lebar, hint resep terbuka")
	_check(hs5.measure_tolerance() < 0.12, "toleransi takaran tetap sempit di level tertinggi")


# --- Identifikasi tanaman ----------------------------------------------------

func _test_plant_id() -> void:
	var cover: bool = true
	var perfect_all: bool = true
	var unique_all: bool = true
	var n: int = 0
	for level in range(1, 6):
		for plant in HerbDb.IDS:
			for seed_value in range(3):
				var p := PlantIdentificationSystem.new()
				p.setup(plant, level, seed_value)
				n += 1
				if not p.options.has(plant) or p.options.size() != int(SkillDb.effect("identifikasi_tanaman", "pilihan", level)):
					cover = false
				var uniq: Dictionary = {}
				for o in p.options:
					uniq[o] = true
				if uniq.size() != p.options.size():
					cover = false
				if not HerbDb.is_unique_among(plant, p.options, p.visible_parts()):
					unique_all = false
				for part in p.visible_parts():
					p.observe(part)
				p.update(10.0)
				var g: Dictionary = p.guess(plant)
				if not bool(g["correct"]) or p.result.grade < Grade.Level.S or not p.succeeded():
					perfect_all = false
	_check(cover, "pilihan identifikasi: berisi jawaban, tanpa duplikat, jumlah sesuai level (%d kasus)" % n)
	_check(unique_all, "bagian yang terlihat selalu cukup untuk membedakan jawaban dari pilihan lain")
	_check(perfect_all, "identifikasi ideal (amati semua bagian terlihat) = S")
	# kesulitan naik
	var l1 := PlantIdentificationSystem.new()
	l1.setup("kunyit", 1, 1)
	var l5 := PlantIdentificationSystem.new()
	l5.setup("kunyit", 5, 1)
	var sim5: int = 0
	for o in l5.options:
		if o != "kunyit":
			sim5 += HerbDb.shared_traits("kunyit", o)
	_check(l5.options.size() > l1.options.size() and l5.hidden_parts.size() > l1.hidden_parts.size() and l1.hidden_parts.is_empty(), "kesulitan naik: lebih banyak pilihan dan bagian tertutup")
	var similar5: int = 0
	for o in l5.options:
		if o != "kunyit" and HerbDb.shared_traits("kunyit", o) >= 1:
			similar5 += 1
	_check(similar5 >= 2 and sim5 >= 2, "level tinggi memuat sedikitnya 2 pengecoh yang mirip")
	# amati bagian tertutup / tidak valid
	var hid := PlantIdentificationSystem.new()
	hid.setup("kunyit", 5, 2)
	var closed: String = hid.hidden_parts[0]
	_check(hid.observe(closed) == "" and hid.observe("batang") == "" and hid.observed.is_empty(), "bagian tertutup/tidak valid tidak bisa diamati")
	var vis: String = hid.visible_parts()[0]
	_check(hid.observe(vis) == HerbDb.trait_of("kunyit", vis) and hid.observe(vis) != "" and hid.observed.size() == 1, "mengamati bagian terlihat mengungkap cirinya")
	# tebakan salah
	var w := PlantIdentificationSystem.new()
	w.setup("kunyit", 1, 3)
	var wrong: String = ""
	for o in w.options:
		if o != "kunyit":
			wrong = o
			break
	var r1: Dictionary = w.guess(wrong)
	_check(not bool(r1["correct"]) and not bool(r1["finished"]) and w.errors == 1 and w.eliminated(wrong), "tebakan salah pertama: lanjut, pilihan tersingkir")
	_check(not w.guess(wrong)["ok"] and not w.guess("tidak_ada")["ok"], "tebakan ulang/di luar pilihan ditolak")
	var wrong2: String = ""
	for o in w.options:
		if o != "kunyit" and o != wrong:
			wrong2 = o
			break
	var r2: Dictionary = w.guess(wrong2)
	_check(bool(r2["finished"]) and not w.succeeded() and w.result.grade == Grade.Level.D and w.harvest == 0, "salah dua kali -> D, tanpa panen")
	# tebakan tanpa pengamatan
	var blind := PlantIdentificationSystem.new()
	blind.setup("kunyit", 1, 4)
	blind.guess("kunyit")
	_check(blind.succeeded() and blind.result.grade <= Grade.Level.B, "benar tanpa pengamatan cukup dibatasi maks B (%s)" % blind.result.letter())
	# panen menurut tingkat
	var hv := PlantIdentificationSystem.new()
	hv.setup("jahe", 1, 5)
	for part in hv.visible_parts():
		hv.observe(part)
	hv.update(5.0)
	hv.guess("jahe")
	_check(hv.harvest == 3 and int(hv.result.details["harvest"]) == 3, "panen S = 3 bahan")
	# lambat sekali tetap bagus (waktu bukan penentu)
	var slow := PlantIdentificationSystem.new()
	slow.setup("jahe", 1, 5)
	for part in slow.visible_parts():
		slow.observe(part)
	slow.update(10000.0)
	slow.guess("jahe")
	_check(slow.result.grade >= Grade.Level.A, "benar dan teliti tapi sangat lambat tetap >= A (%s)" % slow.result.letter())


func _test_garden() -> void:
	var ok: bool = true
	for sid in GardenSystem.SPOTS.keys():
		for day in range(1, 12):
			var pl: String = GardenSystem.plant_for(String(sid), day)
			if not HerbDb.has(pl) or pl != GardenSystem.plant_for(String(sid), day):
				ok = false
	_check(ok, "titik tanaman: tanaman valid dan deterministik per hari")
	var seen: Dictionary = {}
	for day in range(1, 8):
		seen[GardenSystem.plant_for("garden_plot_1", day)] = true
	_check(seen.size() >= 3, "tanaman di petak bergiliran antar hari (%d jenis)" % seen.size())
	var g := GardenSystem.new()
	_check(g.available("garden_plot_1", 1) and not g.available("tidak_ada", 1), "titik tersedia / tidak dikenal")
	g.mark_done("garden_plot_1", 1)
	_check(not g.available("garden_plot_1", 1) and g.available("garden_plot_1", 2) and g.available("garden_plot_2", 1), "titik kosong sampai hari berikutnya")
	_check(GardenSystem.is_wild("wild_plant_kolam") and not GardenSystem.is_wild("garden_plot_1"), "pembeda tanaman liar")
	# titik ada di peta desa
	var village: LocationData = LocationRegistry.get_location("desa")
	var found: int = 0
	for it in village.interactables:
		if GardenSystem.is_spot(it.id):
			found += 1
	_check(found == GardenSystem.SPOTS.size(), "semua titik tanaman ada di peta desa (%d)" % found)


# --- Alur pengobatan terintegrasi dengan antrean Fase 4 -----------------------

func _make_world(hour: int = 8) -> Array:
	var clock := GameClock.new()
	clock.set_time(1, hour, 0)
	var sim := NpcSimulation.new()
	sim.setup(NpcRoster.all(), clock)
	var ps := PatientSystem.new()
	ps.setup(sim, clock)
	ps.auto_call = false
	ps.auto_exam = false
	ps.suppress_plan()
	var tm := TreatmentManager.new()
	tm.setup(ps, SkillProgressionSystem.new(), HerbInventory.new(), ClinicStats.new())
	return [sim, ps, tm]


func _bring_to_exam(sim: NpcSimulation, ps: PatientSystem, npc: String, complaint: String) -> PatientRecord:
	var p: PatientRecord = ps.start_visit(npc, complaint)
	var t: float = 0.0
	while p.state != PatientRecord.State.MENUNGGU and t < 1500.0:
		sim.update(0.5)
		ps.update(0.5)
		t += 0.5
	ps.call_next()
	t = 0.0
	while p.state != PatientRecord.State.DIPERIKSA and t < 400.0:
		sim.update(0.5)
		ps.update(0.5)
		t += 0.5
	return p


func _do_diagnosis(tm: TreatmentManager, p: PatientRecord, correct: bool) -> TreatmentSession:
	var s: TreatmentSession = tm.session_for(p)
	var d: DiagnosisSystem = tm.begin_diagnosis(p)
	d.observe()
	var guard: int = 0
	while d.remaining().size() > 1 and d.energy_left > 0 and guard < 10:
		guard += 1
		for area in AilmentDb.AREAS:
			if d.findings.has(area):
				continue
			var groups: Dictionary = {}
			for c in d.remaining():
				groups[AilmentDb.finding(c, area)] = true
			if groups.size() > 1:
				if area == AilmentDb.PULSE_AREA:
					d.inspect_pulse(0.9)
				else:
					d.inspect(area)
				break
	if correct:
		d.submit(s.true_ailment)
	else:
		var other: String = ""
		for c in d.candidates:
			if c != s.true_ailment:
				other = c
				break
		d.submit(other)
		if not d.is_finished():
			for c in d.candidates:
				if c != s.true_ailment and not d.guesses.has(c):
					d.submit(c)
					break
	tm.complete_diagnosis(p, d)
	return s


func _test_treatment_flow() -> void:
	var w: Array = _make_world(8)
	var sim: NpcSimulation = w[0]
	var ps: PatientSystem = w[1]
	var tm: TreatmentManager = w[2]
	var done: Array = []
	tm.visit_completed.connect(func(pp: PatientRecord, sm: Dictionary) -> void: done.append(sm))
	_check(tm.exam_patient() == null, "belum ada pasien di ruang periksa")
	var p: PatientRecord = _bring_to_exam(sim, ps, "sari", "demam_dingin")
	_check(p.state == PatientRecord.State.DIPERIKSA and tm.exam_patient() == p, "pasien di ruang periksa siap ditangani")
	var s: TreatmentSession = tm.session_for(p)
	_check(s.stage == TreatmentSession.Stage.DIAGNOSIS and AilmentDb.candidates_for("demam_dingin").has(s.true_ailment), "sesi dimulai di tahap diagnosis; penyakit sesuai keluhan (%s)" % s.true_ailment)
	var none: Array[String] = []
	_check(not tm.choose_methods(p, none), "metode belum bisa dipilih sebelum diagnosis")
	_check(tm.begin_acupuncture(p) == null and tm.begin_crafting(p, "ramuan_penghangat") == null, "minigame pengobatan belum bisa dimulai sebelum diagnosis")
	_do_diagnosis(tm, p, true)
	_check(s.stage == TreatmentSession.Stage.METODE and p.diagnosis.diagnosis_id == s.true_ailment and not p.diagnosis.findings.is_empty(), "diagnosis selesai -> tahap metode; catatan pasien terisi")
	_check(tm.skills.xp_of("diagnosis") > 0, "XP diagnosis diberikan")
	_check(tm.begin_diagnosis(p) == null, "diagnosis tidak bisa diulang")
	_check(not tm.choose_methods(p, none), "metode kosong ditolak")
	var both: Array[String] = ["herbal", "akupunktur"]
	_check(tm.choose_methods(p, both) and s.methods == ["akupunktur", "herbal"] and s.stage == TreatmentSession.Stage.AKUPUNKTUR, "dua metode terpilih; akupunktur lebih dulu")
	_check(tm.begin_crafting(p, "ramuan_penghangat") == null, "ramuan belum bisa sebelum akupunktur selesai")
	var a: AcupunctureSystem = tm.begin_acupuncture(p)
	_check(a != null and a.hint_tags().size() == 3, "akupunktur dimulai dengan petunjuk dari diagnosis")
	for pid in a.plan:
		a.toggle_point(pid)
	a.begin_insertion()
	while a.phase == AcupunctureSystem.Phase.JARUM:
		a.insert(Vector2.ZERO, AcupunctureSystem.DEPTH_CENTER)
	var aw: Array[Dictionary] = tm.complete_acupuncture(p, a)
	_check(not aw.is_empty() and s.stage == TreatmentSession.Stage.RAMUAN and tm.skills.xp_of("akupunktur") > 0, "akupunktur selesai -> tahap ramuan; XP akupunktur")
	var best: String = RecipeDb.best_for(s.true_ailment)
	if not tm.recipes_available().has(best):
		best = tm.recipes_available()[0]
	var h: HerbalCraftingSystem = tm.begin_crafting(p, best)
	_check(h != null and s.recipe_id == best, "ramuan dimulai (%s)" % best)
	for st in h.steps:
		for _u in range(int(st["units"])):
			h.take_herb(String(st["herb"]))
	h.confirm_picks()
	for st in h.steps:
		h.submit_measure(float(st["grams"]))
	for b in h.pound_beats:
		h.pound_tap(float(b))
	h.finish_pound()
	var g: int = 0
	while not h.is_finished() and g < 3000:
		h.stir_move(0.05, 0.025)
		g += 1
	_check(h.is_finished(), "peracikan selesai")
	var money0: int = tm.stats.money
	tm.complete_crafting(p, h)
	_check(s.stage == TreatmentSession.Stage.SELESAI and done.size() == 1, "alur selesai: ringkasan dikirim")
	var sum: Dictionary = done[0]
	_check(p.state == PatientRecord.State.SELESAI and ps.completed_count == 1 and not ps.queue.room_busy(), "pasien selesai & ruang periksa kosong (terintegrasi antrean)")
	_check(String(sum["outcome"]) == "sembuh" and bool(sum["diagnosis_correct"]) and float(sum["quality"]) >= 0.6, "kinerja tinggi -> sembuh (kualitas %.2f)" % float(sum["quality"]))
	_check(tm.stats.money > money0 and int(sum["fee"]) > 0 and tm.stats.treated == 1 and tm.stats.reputation > ClinicStats.START_REPUTATION, "pendapatan & reputasi naik")
	_check(float(sum["satisfaction"]) > 50.0 and p.diagnosis.outcome == "sembuh" and p.diagnosis.treatments.size() == 2, "kepuasan, hasil, dan catatan perawatan tersimpan")
	_check(tm.skills.xp_of("peracikan") > 0 and tm.skills.xp_of("pengetahuan_herbal") > 0, "XP peracikan & pengetahuan herbal")
	# pasien benar-benar pulang dan sesi dibersihkan
	var t: float = 0.0
	while not p.done and t < 1200.0:
		sim.update(0.5)
		ps.update(0.5)
		t += 0.5
	_check(p.done and not tm.sessions.has(p.id), "pasien meninggalkan klinik; sesi dibersihkan")
	# metode tunggal
	var w2: Array = _make_world(8)
	var p2: PatientRecord = _bring_to_exam(w2[0], w2[1], "wiryo", "sendi_kaku")
	var tm2: TreatmentManager = w2[2]
	var s2: TreatmentSession = _do_diagnosis(tm2, p2, true)
	var only_acu: Array[String] = ["akupunktur"]
	tm2.choose_methods(p2, only_acu)
	var a2: AcupunctureSystem = tm2.begin_acupuncture(p2)
	for pid in a2.plan:
		a2.toggle_point(pid)
	a2.begin_insertion()
	while a2.phase == AcupunctureSystem.Phase.JARUM:
		a2.insert(Vector2.ZERO, AcupunctureSystem.DEPTH_CENTER)
	tm2.complete_acupuncture(p2, a2)
	_check(s2.stage == TreatmentSession.Stage.SELESAI and p2.state == PatientRecord.State.SELESAI and s2.summary["methods"] == ["akupunktur"], "alur hanya akupunktur langsung selesai")
	_check(tm2.recipes_available().size() == RecipeDb.unlocked(1).size() and not tm2.recipes_available().has("air_tenang_kepala"), "resep level tinggi belum terbuka")


func _test_treatment_wrong_diagnosis_and_failures() -> void:
	# diagnosis salah -> hasil buruk meski pengobatan 'rapi' mengikuti petunjuk
	var w: Array = _make_world(8)
	var p: PatientRecord = _bring_to_exam(w[0], w[1], "karto", "pusing_berputar")
	var tm: TreatmentManager = w[2]
	var s: TreatmentSession = _do_diagnosis(tm, p, false)
	_check(s.diagnosed_id != s.true_ailment and s.results["diagnosis"].grade == Grade.Level.D, "diagnosis salah dinilai D")
	var acu: Array[String] = ["akupunktur"]
	tm.choose_methods(p, acu)
	var a: AcupunctureSystem = tm.begin_acupuncture(p)
	var hint_plan: Array[String] = AilmentDb.acu_plan(s.diagnosed_id)
	for pid in hint_plan:
		a.toggle_point(pid)
	a.begin_insertion()
	while a.phase == AcupunctureSystem.Phase.JARUM:
		a.insert(Vector2.ZERO, AcupunctureSystem.DEPTH_CENTER)
	tm.complete_acupuncture(p, a)
	var sum: Dictionary = s.summary
	_check(not bool(sum["diagnosis_correct"]) and String(sum["outcome"]) != "sembuh", "mengikuti petunjuk diagnosis salah -> tidak sembuh (%s, kualitas %.2f)" % [sum["outcome"], float(sum["quality"])])
	_check(int(sum["grade"]) <= Grade.Level.B, "nilai kunjungan rendah")
	# pengobatan asal-asalan -> gagal, tanpa biaya
	var w2: Array = _make_world(8)
	var p2: PatientRecord = _bring_to_exam(w2[0], w2[1], "dewi", "batuk_kering")
	var tm2: TreatmentManager = w2[2]
	var s2: TreatmentSession = _do_diagnosis(tm2, p2, true)
	var acu2: Array[String] = ["akupunktur"]
	tm2.choose_methods(p2, acu2)
	var a2: AcupunctureSystem = tm2.begin_acupuncture(p2)
	a2.toggle_point("lutut_batu")
	a2.begin_insertion()
	a2.insert(Vector2(1.0, 1.0), 0.0)
	tm2.complete_acupuncture(p2, a2)
	_check(String(s2.summary["outcome"]) == "gagal" and int(s2.summary["grade"]) == Grade.Level.D and int(s2.summary["fee"]) < AilmentDb.fee(s2.true_ailment) and tm2.stats.reputation < ClinicStats.START_REPUTATION, "pengobatan gagal: nilai D, biaya rendah, reputasi turun")
	# keadaan tidak valid
	var w3: Array = _make_world(8)
	var tm3: TreatmentManager = w3[2]
	var p3: PatientRecord = _bring_to_exam(w3[0], w3[1], "joko", "mata_perih")
	var unfinished: DiagnosisSystem = tm3.begin_diagnosis(p3)
	_check(tm3.complete_diagnosis(p3, unfinished).is_empty() and tm3.session_for(p3).stage == TreatmentSession.Stage.DIAGNOSIS, "diagnosis belum selesai tidak diterima")
	_check(tm3.finalize(p3).is_empty(), "finalisasi sebelum waktunya ditolak")
	_check(tm3.recipes_available().has("ramuan_penghangat"), "resep awal tersedia")
	# pasien menyerah saat menunggu di ruang periksa tanpa ditangani
	var w4: Array = _make_world(8)
	var sim4: NpcSimulation = w4[0]
	var ps4: PatientSystem = w4[1]
	var tm4: TreatmentManager = w4[2]
	var p4: PatientRecord = _bring_to_exam(sim4, ps4, "ratih", "perut_kembung")
	tm4.session_for(p4)
	sim4.clock.set_time(sim4.clock.day, 14, 0)   # > EXAM_PATIENCE_MIN sejak masuk ruang periksa
	var t: float = 0.0
	while not p4.done and t < 1500.0:
		sim4.update(0.5)
		ps4.update(0.5)
		t += 0.5
	_check(p4.done and p4.state == PatientRecord.State.BATAL and not tm4.sessions.has(p4.id), "pasien yang tak ditangani akhirnya pulang (BATAL), sesi dibersihkan")
	# fase 4 tetap: auto_exam menyelesaikan pemeriksaan otomatis
	var clock := GameClock.new()
	clock.set_time(1, 8, 0)
	var sim5 := NpcSimulation.new()
	sim5.setup(NpcRoster.all(), clock)
	var ps5 := PatientSystem.new()
	ps5.setup(sim5, clock)
	ps5.auto_call = false
	ps5.suppress_plan()
	_check(ps5.auto_exam, "auto_exam bawaan tetap menyala (kompatibel Fase 4)")


# --- Localization ------------------------------------------------------------

func _test_localization_complete() -> void:
	var keys: Array[String] = []
	for id in AilmentDb.IDS:
		keys.append("ailment.%s.name" % id)
		keys.append("ailment.%s.desc" % id)
	for area in AilmentDb.AREAS:
		keys.append("area.%s" % area)
		for v in (AilmentDb.VALUES[area] as Array):
			keys.append("finding.%s.%s" % [area, v])
	for id in AcupointDb.IDS:
		keys.append("point.%s" % id)
		keys.append("tag.%s" % AcupointDb.tag(id))
		keys.append("region.%s" % AcupointDb.region(id))
	for id in HerbDb.IDS:
		keys.append("herb.%s" % id)
	for part in HerbDb.PARTS:
		keys.append("part.%s" % part)
		for tk in (HerbDb.TRAITS[part] as Array):
			keys.append("trait.%s.%s" % [part, tk])
	for id in RecipeDb.IDS:
		keys.append("recipe.%s.name" % id)
		keys.append("recipe.%s.desc" % id)
	for b in SkillDb.BRANCHES:
		keys.append("skill.%s" % b)
	for g in ["s", "a", "b", "c", "d"]:
		keys.append("grade.%s" % g)
	for id in GardenSystem.SPOTS.keys():
		keys.append("prompt.%s" % id)
	for st in TreatmentSession.STAGE_KEYS:
		keys.append("stage.%s" % st)
	for o in ["sembuh", "membaik", "gagal"]:
		keys.append("outcome.%s" % o)
	var missing: Array[String] = []
	for k in keys:
		for lang in Locale.LANGS:
			if not Locale.has_key(k, lang):
				missing.append("%s[%s]" % [k, lang])
	_check(missing.is_empty(), "localization lengkap untuk data Fase 5 (%d kunci x 2 bahasa; hilang: %s)" % [keys.size(), str(missing.slice(0, 12))])
