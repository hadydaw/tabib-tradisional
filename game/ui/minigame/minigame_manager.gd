class_name MinigameManager
extends CanvasLayer
## Pengelola layar minigame: membuka/menutup layar penuh di atas dunia isometrik (dengan pudar lembut),
## mengunci kontrol dunia lewat UiGate, dan menjalankan alur pengobatan per tahap dari TreatmentManager:
## diagnosis -> pilih metode -> akupunktur/ramuan -> ringkasan kunjungan. Juga identifikasi tanaman dan Buku Tabib.
## Tahap sesi disimpan di TreatmentSession, sehingga "Tunda" lalu lanjut kembali ke tahap yang sama.

signal opened(kind: String)
signal closed
signal visit_summary(summary: Dictionary)
signal plant_finished(spot_id: String, result: MinigameResult)
## Fase 8: kemajuan quest cerita (kind: "gather"/"identify", key: "any" atau area).
signal social_event(kind: String, key: String)

const FADE_IN: float = 0.28
const FADE_DIP: float = 0.18

var treatment: TreatmentManager
var skills: SkillProgressionSystem
var inventory: HerbInventory
var stats: ClinicStats
var garden: GardenSystem
var clock: GameClock
var upgrades: ClinicUpgrades = null
var adventure: AdventureState = null   # Fase 7
var social: SocialState = null         # Fase 8: hubungan & quest (ditampilkan di Buku Tabib)
var shop: ClinicShop = null
var save_action: Callable = Callable()   # dipanggil tombol Simpan di Buku Tabib; mengembalikan bool
var transitions: bool = true

var _view: MinigameView = null
var _kind: String = ""
var _fade: ColorRect
var _tween: Tween = null


func setup(p_treatment: TreatmentManager, p_skills: SkillProgressionSystem, p_inventory: HerbInventory,
		p_stats: ClinicStats, p_garden: GardenSystem, p_clock: GameClock) -> void:
	treatment = p_treatment
	skills = p_skills
	inventory = p_inventory
	stats = p_stats
	garden = p_garden
	clock = p_clock


## Fase 6: sambungkan upgrade klinik & pasar bahan.
func setup_economy(p_upgrades: ClinicUpgrades, p_shop: ClinicShop) -> void:
	upgrades = p_upgrades
	shop = p_shop


func _ready() -> void:
	layer = WorldLayers.HUD_LAYER + 5
	_fade = ColorRect.new()
	_fade.color = Color(0.05, 0.08, 0.07, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.z_index = 100
	add_child(_fade)
	get_viewport().size_changed.connect(relayout)


func is_open() -> bool:
	return _view != null


func kind() -> String:
	return _kind


func current_view() -> MinigameView:
	return _view


func relayout() -> void:
	if _view == null:
		return
	var vis: Vector2 = get_viewport().get_visible_rect().size
	_view.layout(vis, SafeArea.rect(vis))


func _patient_name(p: PatientRecord) -> String:
	return Locale.t(NpcRoster.by_id(p.npc_id).name_key())


# --- Buka / tutup ------------------------------------------------------------

func _show(view: MinigameView, p_kind: String) -> void:
	_drop_view()
	_view = view
	_kind = p_kind
	add_child(view)
	move_child(view, 0)
	UiGate.blocked = true
	relayout()
	view.cancelled.connect(close)
	if transitions and _fade != null and is_inside_tree():
		if _tween != null:
			_tween.kill()
		_fade.color.a = 1.0
		_tween = create_tween()
		_tween.tween_property(_fade, "color:a", 0.0, FADE_IN)
	opened.emit(p_kind)


func _drop_view() -> void:
	if _view != null:
		var v: MinigameView = _view
		_view = null
		remove_child(v)
		v.queue_free()


## Tutup layar minigame dan kembalikan kontrol ke dunia.
func close() -> void:
	if _view == null:
		return
	_drop_view()
	_kind = ""
	UiGate.blocked = false
	if transitions and _fade != null and is_inside_tree():
		if _tween != null:
			_tween.kill()
		_fade.color.a = 0.7
		_tween = create_tween()
		_tween.tween_property(_fade, "color:a", 0.0, FADE_DIP)
	closed.emit()


# --- Alur pengobatan ---------------------------------------------------------

## Mulai / lanjutkan penanganan pasien yang sedang di ruang periksa sesuai tahap sesinya.
func start_treatment(p: PatientRecord) -> bool:
	if p == null or is_open():
		return false
	return _step(p)


func _step(p: PatientRecord) -> bool:
	var s: TreatmentSession = treatment.session_for(p)
	match s.stage:
		TreatmentSession.Stage.DIAGNOSIS:
			return _open_diagnosis(p)
		TreatmentSession.Stage.METODE:
			return _open_methods(p)
		TreatmentSession.Stage.AKUPUNKTUR:
			return _open_acupuncture(p)
		TreatmentSession.Stage.RAMUAN:
			return _open_recipes(p)
		_:
			var sm: Dictionary = s.summary
			if sm.is_empty():
				sm = treatment.finalize(p)
			if sm.is_empty():
				close()
				return false
			_open_summary(sm)
			return true


func _open_diagnosis(p: PatientRecord) -> bool:
	var d: DiagnosisSystem = treatment.begin_diagnosis(p)
	if d == null:
		return false
	var v := DiagnosisView.new()
	v.setup(d, _patient_name(p), Locale.t("complaint.%s" % p.complaint_id))
	v.completed.connect(func(res: MinigameResult) -> void:
		var awards: Array[Dictionary] = treatment.complete_diagnosis(p, d)
		var s: TreatmentSession = treatment.session_for(p)
		var lines: Array[String] = [_patient_name(p)]
		lines.append(Locale.t("diag.verdict_ok" if s.diagnosed_id == s.true_ailment else "diag.verdict_wrong", {"name": Locale.t("ailment.%s.name" % s.diagnosed_id)}))
		v.show_result(res, awards, lines))
	v.finished.connect(func(_r: MinigameResult, _a: Array) -> void: _after_result(p))
	_show(v, "diagnosis")
	return true


func _after_result(p: PatientRecord) -> void:
	if not is_open():
		return
	var s: TreatmentSession = treatment.session_for(p)
	if s.stage == TreatmentSession.Stage.SELESAI:
		_open_summary(s.summary)
	else:
		_step(p)


func _open_methods(p: PatientRecord) -> bool:
	var v := ChoiceView.new()
	var items: Array[Dictionary] = [
		{"id": TreatmentManager.METHOD_ACU, "title": Locale.t("method.akupunktur"), "sub": Locale.t("method.akupunktur.desc"), "enabled": true},
		{"id": TreatmentManager.METHOD_HERB, "title": Locale.t("method.herbal"), "sub": Locale.t("method.herbal.desc"), "enabled": true},
	]
	v.setup(Locale.t("method.title"), Locale.t("method.help", {"name": _patient_name(p)}), items, true)
	v.chosen.connect(func(ids: Array) -> void:
		var ms: Array[String] = []
		for i in ids:
			ms.append(String(i))
		if treatment.choose_methods(p, ms):
			_after_result(p))
	_show(v, "metode")
	return true


func _open_acupuncture(p: PatientRecord) -> bool:
	var a: AcupunctureSystem = treatment.begin_acupuncture(p)
	if a == null:
		return false
	var s: TreatmentSession = treatment.session_for(p)
	var v := AcupunctureView.new()
	v.setup(a, _patient_name(p), Locale.t("ailment.%s.name" % s.diagnosed_id))
	v.completed.connect(func(res: MinigameResult) -> void:
		var awards: Array[Dictionary] = treatment.complete_acupuncture(p, a)
		var lines: Array[String] = [_patient_name(p)]
		v.show_result(res, awards, lines))
	v.finished.connect(func(_r: MinigameResult, _a: Array) -> void: _after_result(p))
	_show(v, "akupunktur")
	return true


func _open_recipes(p: PatientRecord) -> bool:
	var items: Array[Dictionary] = []
	for rid in treatment.recipes_available():
		var h := HerbalCraftingSystem.new()
		var ok: bool = h.setup(rid, inventory, skills.level("pengetahuan_herbal"), skills.level("peracikan"))
		var short: bool = not h.shortages().is_empty() if ok else true
		var sub: String = Locale.t("recipe.%s.desc" % rid)
		if short:
			sub += "\n" + Locale.t("craft.shortage")
		items.append({"id": rid, "title": Locale.t("recipe.%s.name" % rid), "sub": sub, "enabled": not short})
	var v := ChoiceView.new()
	v.setup(Locale.t("recipe.choose_title"), Locale.t("recipe.choose_help", {"name": _patient_name(p)}), items, false)
	v.chosen.connect(func(ids: Array) -> void:
		if ids.is_empty():
			return
		_open_crafting(p, String(ids[0])))
	_show(v, "resep")
	return true


func _open_crafting(p: PatientRecord, recipe_id: String) -> bool:
	var h: HerbalCraftingSystem = treatment.begin_crafting(p, recipe_id)
	if h == null:
		return false
	var v := CraftingView.new()
	v.setup(h, _patient_name(p))
	v.completed.connect(func(res: MinigameResult) -> void:
		var awards: Array[Dictionary] = treatment.complete_crafting(p, h)
		var lines: Array[String] = [Locale.t("recipe.%s.name" % recipe_id)]
		v.show_result(res, awards, lines))
	v.finished.connect(func(_r: MinigameResult, _a: Array) -> void: _after_result(p))
	_show(v, "peracikan")
	return true


func _open_summary(sm: Dictionary) -> void:
	visit_summary.emit(sm)
	var v := InfoView.new()
	var col_ok: Color = MinigameView.C_GREEN
	var lines: Array[Dictionary] = []
	lines.append({"text": Locale.t("summary.patient", {"name": Locale.t(NpcRoster.by_id(String(sm["npc_id"])).name_key())}), "size": 26})
	lines.append({"text": Locale.t("summary.ailment", {"name": Locale.t("ailment.%s.name" % String(sm["ailment_id"]))}), "size": 24})
	lines.append({"text": Locale.t("summary.diagnosed", {"name": Locale.t("ailment.%s.name" % String(sm["diagnosed_id"])),
		"ok": Locale.t("summary.right" if bool(sm["diagnosis_correct"]) else "summary.wrong")}), "size": 24})
	var oc: String = String(sm["outcome"])
	lines.append({"text": Locale.t("summary.outcome", {"outcome": Locale.t("outcome.%s" % oc)}), "size": 30,
		"color": col_ok if oc != "gagal" else MinigameView.C_RED})
	lines.append({"text": Locale.t("summary.quality", {"q": int(roundf(float(sm["quality"]) * 100.0)), "sat": int(roundf(float(sm["satisfaction"])))}), "size": 22})
	var rd: float = float(sm["reputation_delta"])
	lines.append({"text": Locale.t("summary.pay", {"fee": int(sm["fee"]), "rep": snappedf(rd, 0.1)}), "size": 24, "color": MinigameView.C_GOLD})
	lines.append({"text": Locale.t("summary.totals", {"money": int(sm["money"]), "rep": snappedf(float(sm["reputation"]), 0.1)}), "size": 20, "color": MinigameView.C_DIM})
	for mid in sm.get("milestones", []):
		lines.append({"text": Locale.t("summary.milestone", {"name": Locale.t("milestone.%s" % String(mid))}), "size": 22, "color": MinigameView.C_GREEN})
	v.setup(Locale.t("summary.title"), lines, Locale.t("summary.done"), int(sm["grade"]))
	v.closed.connect(close)
	_show(v, "ringkasan")


# --- Identifikasi tanaman -----------------------------------------------------

## Mulai minigame identifikasi di titik kebun/liar `spot_id`. False bila sudah dikerjakan hari ini / tak valid.
func start_plant(spot_id: String) -> bool:
	if is_open() or not GardenSystem.is_spot(spot_id) or not garden.available(spot_id, clock.day):
		return false
	var plant_id: String = GardenSystem.plant_for(spot_id, clock.day)
	return _open_plant(plant_id, absi(spot_id.hash()) + clock.day * 31, Locale.t("spot.%s" % spot_id),
		func(res: MinigameResult, _ok: bool, _learned: bool) -> void:
			garden.mark_done(spot_id, clock.day)
			plant_finished.emit(spot_id, res))


## Minigame identifikasi umum. `on_done(res, ok, learned)` dipanggil saat selesai; `on_cancel()` bila ditunda.
func _open_plant(plant_id: String, seed_value: int, title: String, on_done: Callable, on_cancel: Callable = Callable()) -> bool:
	var sys := PlantIdentificationSystem.new()
	sys.setup(plant_id, skills.level("identifikasi_tanaman"), seed_value)
	var v := PlantView.new()
	v.setup(sys, title)
	v.completed.connect(func(res: MinigameResult) -> void:
		var awards: Array[Dictionary] = skills.award(res)
		var lines: Array[String] = []
		var learned: bool = false
		if sys.succeeded():
			lines.append(Locale.t("plant.result_ok", {"name": Locale.t("herb.%s" % plant_id)}))
			learned = skills.learn_plant(plant_id)
			if learned:
				social_event.emit("identify", "any")
				lines.append(Locale.t("plant.learned", {"name": Locale.t("herb.%s" % plant_id)}))
				lines.append(Locale.t("plant.lore", {"habitat": Locale.t("lore.%s.habitat" % plant_id), "use": Locale.t("lore.%s.use" % plant_id)}))
			if sys.harvest > 0:
				var got: int = sys.harvest + (upgrades.harvest_bonus() if upgrades != null else 0)
				inventory.add(plant_id, got)
				lines.append(Locale.t("plant.harvest", {"n": got, "name": Locale.t("herb.%s" % plant_id)}))
		else:
			lines.append(Locale.t("plant.result_fail", {"name": Locale.t("herb.%s" % plant_id)}))
		on_done.call(res, sys.succeeded(), learned)
		v.show_result(res, awards, lines))
	v.finished.connect(func(_r: MinigameResult, _a: Array) -> void: close())
	if on_cancel.is_valid():
		v.cancelled.connect(func() -> void: on_cancel.call())
	_show(v, "identifikasi")
	return true


func _open_info(title: String, lines: Array[Dictionary], button: String = "") -> void:
	var v := InfoView.new()
	v.setup(title, lines, button)
	v.closed.connect(close)
	_show(v, "info")


# --- Petualangan (Fase 7) -----------------------------------------------------

## Kumpulkan dari titik liar. Bahan yang sudah dikenal langsung masuk inventaris; yang belum dikenal
## memulai identifikasi (Fase 5). Mengembalikan false bila titik masih tumbuh, stamina kurang, atau layar penuh.
func start_forage(node_id: String) -> bool:
	if is_open() or adventure == null or not ForageDb.has(node_id):
		return false
	var now: float = clock.absolute_minutes()
	if not adventure.node_ready(node_id, now):
		return false
	var area: String = String(ForageDb.get_node(node_id)["area"])
	var pick: Dictionary = ForageDb.roll(node_id, int(now))
	var herb: String = String(pick["herb"])
	var known: bool = skills.knows_plant(herb)
	var cost: float = AdventureState.COST_GATHER if known else AdventureState.COST_IDENTIFY
	if not adventure.spend(cost):
		return false
	var title: String = Locale.t("forage.%s" % node_id)
	if known:
		var n: int = 2 if bool(pick["rare"]) else 1
		adventure.mark_forage(node_id, now)
		inventory.add(herb, n)
		adventure.bump("gather:%s" % area, n)
		social_event.emit("gather", "any")
		var got: Array[Dictionary] = [{"text": Locale.t("adv.forage_got", {"name": Locale.t("herb.%s" % herb), "n": n}), "size": 26, "color": MinigameView.C_GREEN},
			{"text": Locale.t("lore.%s.habitat" % herb), "size": 20, "color": MinigameView.C_DIM}]
		_open_info(title, got, Locale.t("ui.close"))
		return true
	var on_done := func(_res: MinigameResult, ok: bool, learned: bool) -> void:
		adventure.mark_forage(node_id, now)
		if ok:
			adventure.bump("gather:%s" % area)
			social_event.emit("gather", "any")
		if learned:
			adventure.bump("identify_new")
	var on_cancel := func() -> void:
		adventure.refund(cost)
	return _open_plant(herb, int(now) + 17, title, on_done, on_cancel)


## Papan Pengembara: tampilkan misi aktif; bila selesai, klaim hadiah koin.
func start_board() -> bool:
	if is_open() or adventure == null:
		return false
	var lines: Array[Dictionary] = []
	var m: Dictionary = adventure.active_mission()
	if m.is_empty():
		lines.append({"text": Locale.t("board.all_done"), "size": 26})
	else:
		var mid: String = String(m["id"])
		lines.append({"text": Locale.t("mission.%s.title" % mid), "size": 30, "color": MinigameView.C_GOLD})
		lines.append({"text": Locale.t("mission.%s.desc" % mid), "size": 22})
		lines.append({"text": Locale.t("board.progress", {"done": adventure.mission_progress(m), "total": MissionDb.goal_n(m)}), "size": 24})
		var got: Dictionary = adventure.claim()
		if not got.is_empty():
			stats.add_money(int(got["coin"]), "misi:%s" % String(got["id"]))
			lines.append({"text": Locale.t("board.claimed", {"coin": int(got["coin"])}), "size": 24, "color": MinigameView.C_GREEN})
	_open_info(Locale.t("board.title"), lines, Locale.t("ui.close"))
	return true


## Baca tanda di celah rahasia (satu kali). Syarat dan stamina diperiksa pemanggil.
func start_secret() -> bool:
	if is_open() or adventure == null or adventure.has_secret(AdventureState.SECRET_ID):
		return false
	if not adventure.spend(AdventureState.COST_SECRET):
		return false
	adventure.reveal_secret(AdventureState.SECRET_ID)
	inventory.add(AdventureState.SECRET_HERB, AdventureState.SECRET_UNITS)
	stats.add_money(AdventureState.SECRET_COIN, "celah")
	var lines: Array[Dictionary] = [
		{"text": Locale.t("adv.secret_found", {"name": Locale.t("herb.%s" % AdventureState.SECRET_HERB), "n": AdventureState.SECRET_UNITS, "coin": AdventureState.SECRET_COIN}), "size": 26, "color": MinigameView.C_GOLD}]
	_open_info(Locale.t("adv.secret_title"), lines, Locale.t("ui.close"))
	return true


# --- Buku Tabib ----------------------------------------------------------------

func show_book() -> bool:
	if is_open():
		return false
	var lines: Array[Dictionary] = []
	lines.append({"text": Locale.t("book.clinic", {"money": stats.money, "rep": snappedf(stats.reputation, 0.1),
		"treated": stats.treated, "cured": stats.cured}), "size": 22, "color": MinigameView.C_GOLD})
	for b in SkillDb.BRANCHES:
		var lv: int = skills.level(b)
		var nxt: String = Locale.t("book.max") if lv >= SkillDb.MAX_LEVEL else "%d%%" % int(roundf(skills.progress(b) * 100.0))
		lines.append({"text": "%s — %s %d  (%s)" % [Locale.t("skill.%s" % b), Locale.t("book.level"), lv, nxt], "size": 22})
	var herbs: String = ""
	for id in HerbDb.IDS:
		var n: int = inventory.count(id)
		if n > 0:
			herbs += "%s ×%d   " % [Locale.t("herb.%s" % id), n]
	lines.append({"text": Locale.t("book.herbs", {"list": herbs if herbs != "" else "-"}), "size": 20})
	var known: String = ""
	for id in skills.known_plants:
		known += Locale.t("herb.%s" % id) + ", "
	lines.append({"text": Locale.t("book.plants", {"n": skills.known_plants.size(), "total": HerbDb.IDS.size(), "list": known.trim_suffix(", ") if known != "" else "-"}), "size": 20})
	if social != null:
		var rel: String = ""
		for nid in SocialDb.npc_ids():
			rel += "%s %s  " % [Locale.t("npc.%s.name" % nid), Locale.t("book.tier.%d" % social.tier(nid))]
		lines.append({"text": Locale.t("book.trust", {"list": rel.strip_edges()}), "size": 18})
		var q_done: int = social.quests_in_status(SocialState.DONE).size()
		var q_act: int = social.quests_in_status(SocialState.ACTIVE).size()
		lines.append({"text": Locale.t("book.quests", {"done": q_done, "active": q_act}), "size": 20})
	if upgrades != null:
		var ups: String = ""
		for id in ClinicUpgrades.IDS:
			if upgrades.level(id) > 0:
				ups += "%s %d, " % [Locale.t("upgrade.%s.name" % id), upgrades.level(id)]
		lines.append({"text": Locale.t("book.upgrades", {"list": ups.trim_suffix(", ") if ups != "" else "-", "cost": upgrades.operating_cost()}), "size": 20})
	if not stats.ledger.is_empty():
		var led: String = ""
		var from: int = maxi(0, stats.ledger.size() - 3)
		for i in range(stats.ledger.size() - 1, from - 1, -1):
			var e: Dictionary = stats.ledger[i]
			led += "%s%d  %s\n" % ["+" if int(e["delta"]) > 0 else "", int(e["delta"]), EconomyText.reason_text(String(e["reason"]))]
		lines.append({"text": Locale.t("book.ledger") + "\n" + led.strip_edges(), "size": 18, "color": MinigameView.C_DIM})
	var v := InfoView.new()
	if save_action.is_valid():
		v.extra_text = Locale.t("book.save")
	v.setup(Locale.t("book.title"), lines, Locale.t("ui.close"))
	v.closed.connect(close)
	v.extra.connect(func() -> void:
		var ok: bool = bool(save_action.call())
		v.extra_text = Locale.t("book.saved" if ok else "book.save_fail")
		v.mark_dirty())
	_show(v, "buku")
	return true


# --- Pasar bahan & upgrade klinik (Fase 6) --------------------------------------

func start_shop() -> bool:
	if is_open() or shop == null:
		return false
	var v := ShopView.new()
	v.setup(shop)
	v.closed.connect(close)
	_show(v, "toko")
	return true


func start_upgrades() -> bool:
	if is_open() or upgrades == null:
		return false
	var v := UpgradeView.new()
	v.setup(upgrades, stats, skills)
	v.closed.connect(close)
	_show(v, "upgrade")
	return true
