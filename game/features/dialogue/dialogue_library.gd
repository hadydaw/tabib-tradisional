class_name DialogueLibrary
extends RefCounted
## Membangun pohon dialog satu NPC (Dictionary node) dari data + konteks saat bicara.
## Node: {"speaker": kunci nama, "text": kunci teks, "args": {}, "choices": [{"label": kunci, "next": id, "action": ""}],
## "next": id | "" (tanpa pilihan: lanjut), "end": bool}. Teks dicari lewat Locale (Indonesia/English).
## ctx: {"activity", "patient": {"state", "complaint"}, "requests": RequestLog,
##       "social": SocialState (Fase 8), "day": int, "reputation": float, "herbs_available": bool}
## Aksi pilihan: "accept:<id>"/"claim:<id>" (permintaan Fase 4) dan aksi Fase 8 lewat DialogueRunner.action_requested.

const START: String = "start"


static func build(npc: NpcData, ctx: Dictionary) -> Dictionary:
	var nodes: Dictionary = {}
	var speaker: String = npc.name_key()
	var patient: Dictionary = ctx.get("patient", {})
	var req_log: RequestLog = ctx.get("requests", null)
	var social: SocialState = ctx.get("social", null)
	var day: int = int(ctx.get("day", 1))
	var rep: float = float(ctx.get("reputation", 0.0))
	var herbs_ok: bool = bool(ctx.get("herbs_available", false))
	var req: String = npc.request_id
	var req_status: int = req_log.status(req) if (req_log != null and req != "") else RequestLog.NONE

	# --- sapaan (pasien mendapat sapaan khusus; lainnya mengikuti tingkat kepercayaan) ---
	var greet_key: String = "dlg.%s.greet" % npc.id
	var greet_args: Dictionary = {}
	if not patient.is_empty():
		var st: String = String(patient.get("state", ""))
		var comp: String = Locale.t("complaint.%s" % String(patient.get("complaint", "")))
		greet_args = {"complaint": comp}
		match st:
			"menuju", "mendaftar": greet_key = "dlg.patient.coming"
			"menunggu": greet_key = "dlg.patient.waiting"
			"dipanggil":
				greet_key = "dlg.patient.called"
				greet_args = {}
			"diperiksa":
				greet_key = "dlg.patient.exam"
			"selesai":
				greet_key = "dlg.patient.leaving"
				greet_args = {}
			_:
				pass
	# Sapaan default diganti sapaan menurut tingkat kepercayaan (sapaan khusus pasien tetap didahulukan).
	if social != null and greet_key == "dlg.%s.greet" % npc.id:
		greet_key = "dlg.%s.t%d" % [npc.id, social.tier(npc.id)]
	if req_status == RequestLog.READY:
		greet_key = "dlg.request_claim"
		greet_args = {}
	var choices: Array = [
		{"label": "dlg.choice.status", "next": "status", "action": ""},
		{"label": "dlg.choice.about", "next": "about", "action": ""},
	]

	# --- Fase 8: bab cerita, quest cerita, dan pemberian bahan ---
	var story_quest: String = ""
	if social != null:
		var quests_here: Array[String] = SocialDb.quests_of(npc.id)
		story_quest = quests_here[0] if not quests_here.is_empty() else ""
		var due: int = social.chapter_due(npc.id)
		if due > 0:
			choices.append({"label": "dlg.choice.chapter", "next": "ch", "action": ""})
			nodes["ch"] = {"speaker": speaker, "text": "dlg.%s.ch%d" % [npc.id, due], "args": {}, "choices": [
				{"label": "dlg.choice.more", "next": "ch_more", "action": "chapter:%s:%d" % [npc.id, due]},
				{"label": "dlg.choice.later", "next": "ch_later", "action": ""},
			], "next": "", "end": false}
			nodes["ch_more"] = {"speaker": speaker, "text": "dlg.%s.ch%d_more" % [npc.id, due], "args": {}, "choices": [], "next": START, "end": false}
			nodes["ch_later"] = {"speaker": speaker, "text": "dlg.chapter_later", "args": {}, "choices": [], "next": START, "end": false}
		if story_quest != "":
			var qs: int = social.status(story_quest)
			if qs == SocialState.ACTIVE and social.is_ready(story_quest):
				choices.insert(0, {"label": "dlg.choice.report_quest", "next": "qturn_%s" % story_quest, "action": ""})
				_add_quest_turn(nodes, speaker, story_quest)
			elif qs == SocialState.ACTIVE:
				choices.append({"label": "dlg.choice.quest_status", "next": "qwait_%s" % story_quest, "action": ""})
				nodes["qwait_%s" % story_quest] = {"speaker": speaker, "text": "sq.%s.wait" % story_quest, "args": {}, "choices": [], "next": START, "end": false}
			elif social.can_offer(story_quest, rep):
				choices.append({"label": "dlg.choice.quest", "next": "qoffer_%s" % story_quest, "action": ""})
				_add_quest_offer(nodes, speaker, story_quest)
		if social.gift_available(npc.id, day) and herbs_ok:
			choices.append({"label": "dlg.choice.gift", "next": "gift_r", "action": "gift:%s" % npc.id})
			nodes["gift_r"] = {"speaker": speaker, "text": "dlg.gift_thanks", "args": {}, "choices": [], "next": START, "end": false}

	if req != "" and (req_status == RequestLog.NONE or req_status == RequestLog.ACTIVE):
		choices.append({"label": "dlg.choice.help", "next": "request", "action": ""})
	if req != "" and req_status == RequestLog.READY:
		choices.insert(0, {"label": "dlg.choice.report", "next": "done", "action": "claim:%s" % req})
	choices.append({"label": "dlg.choice.bye", "next": "", "action": ""})
	nodes[START] = {"speaker": speaker, "text": greet_key, "args": greet_args, "choices": choices, "next": "", "end": false}

	nodes["status"] = {"speaker": speaker, "text": "dlg.status",
		"args": {"activity": Locale.t("activity.%s" % String(ctx.get("activity", "di_rumah")))},
		"choices": [], "next": START, "end": false}
	nodes["about"] = {"speaker": speaker, "text": "dlg.%s.about" % npc.id, "args": {}, "choices": [], "next": "about2", "end": false}
	nodes["about2"] = {"speaker": speaker, "text": "dlg.%s.about2" % npc.id, "args": {}, "choices": [], "next": START, "end": false}

	if req != "":
		if req_status == RequestLog.NONE:
			nodes["request"] = {"speaker": speaker, "text": "%s.offer" % req, "args": {}, "choices": [
				{"label": "dlg.choice.accept", "next": "accepted", "action": "accept:%s" % req},
				{"label": "dlg.choice.decline", "next": "declined", "action": ""},
			], "next": "", "end": false}
			nodes["accepted"] = {"speaker": speaker, "text": "dlg.request_accepted", "args": {}, "choices": [], "next": "", "end": true}
			nodes["declined"] = {"speaker": speaker, "text": "dlg.request_declined", "args": {}, "choices": [], "next": "", "end": true}
		elif req_status == RequestLog.ACTIVE:
			nodes["request"] = {"speaker": speaker, "text": "dlg.request_pending", "args": {}, "choices": [], "next": START, "end": false}
		nodes["done"] = {"speaker": speaker, "text": "dlg.request_done", "args": {}, "choices": [], "next": "", "end": true}
	return nodes


static func _add_quest_offer(nodes: Dictionary, speaker: String, qid: String) -> void:
	nodes["qoffer_%s" % qid] = {"speaker": speaker, "text": "sq.%s.offer" % qid, "args": {}, "choices": [
		{"label": "dlg.choice.accept", "next": "qacc_%s" % qid, "action": "squest_accept:%s" % qid},
		{"label": "dlg.choice.decline", "next": "", "action": ""},
	], "next": "", "end": false}
	nodes["qacc_%s" % qid] = {"speaker": speaker, "text": "sq.%s.accepted" % qid, "args": {}, "choices": [], "next": "", "end": true}


static func _add_quest_turn(nodes: Dictionary, speaker: String, qid: String) -> void:
	var opts: Array = SocialDb.quest(qid)["choices"].keys()
	opts.sort()
	var choices: Array = []
	for o in opts:
		choices.append({"label": "sq.%s.opt.%s" % [qid, String(o)], "next": "qdone_%s" % qid,
			"action": "squest_choice:%s:%s" % [qid, String(o)]})
	nodes["qturn_%s" % qid] = {"speaker": speaker, "text": "sq.%s.turn" % qid, "args": {}, "choices": choices, "next": "", "end": false}
	nodes["qdone_%s" % qid] = {"speaker": speaker, "text": "sq.%s.done" % qid, "args": {}, "choices": [], "next": "", "end": true}
