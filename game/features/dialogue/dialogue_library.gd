class_name DialogueLibrary
extends RefCounted
## Membangun pohon dialog satu NPC (Dictionary node) dari data + konteks saat bicara.
## Node: {"speaker": kunci nama, "text": kunci teks, "args": {}, "choices": [{"label": kunci, "next": id, "action": ""}],
## "next": id | "" (tanpa pilihan: lanjut), "end": bool}. Teks dicari lewat Locale (Indonesia/English).
## ctx: {"activity": String, "patient": {"state": String, "complaint": String}, "requests": RequestLog}

const START: String = "start"


static func build(npc: NpcData, ctx: Dictionary) -> Dictionary:
	var nodes: Dictionary = {}
	var speaker: String = npc.name_key()
	var patient: Dictionary = ctx.get("patient", {})
	var req_log: RequestLog = ctx.get("requests", null)
	var req: String = npc.request_id
	var req_status: int = req_log.status(req) if (req_log != null and req != "") else RequestLog.NONE

	# --- sapaan (pasien mendapat sapaan khusus) ---
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
	if req_status == RequestLog.READY:
		greet_key = "dlg.request_claim"
		greet_args = {}
	var choices: Array = [
		{"label": "dlg.choice.status", "next": "status", "action": ""},
		{"label": "dlg.choice.about", "next": "about", "action": ""},
	]
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
