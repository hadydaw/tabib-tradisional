class_name DialogueRunner
extends RefCounted
## Menjalankan pohon dialog (logika murni, dites unit). Tampilan dipisah (DialoguePanel).
## Aksi pilihan: "accept:<id>" dan "claim:<id>" diteruskan ke RequestLog.

var nodes: Dictionary = {}
var node_id: String = ""
var finished: bool = true
var req_log: RequestLog
var npc_id: String = ""


func start(p_npc_id: String, p_nodes: Dictionary, p_log: RequestLog) -> void:
	npc_id = p_npc_id
	nodes = p_nodes
	req_log = p_log
	finished = false
	node_id = DialogueLibrary.START
	if not nodes.has(node_id):
		finished = true


func is_active() -> bool:
	return not finished


## Data node saat ini sudah dilokalisasi: {"speaker", "text", "choices": Array[String], "has_choices"}.
func view() -> Dictionary:
	if finished:
		return {}
	var n: Dictionary = nodes[node_id]
	var labels: Array[String] = []
	for c: Dictionary in n["choices"]:
		labels.append(Locale.t(String(c["label"])))
	return {
		"speaker": Locale.t(String(n["speaker"])),
		"text": Locale.t(String(n["text"]), n["args"]),
		"choices": labels,
		"has_choices": not labels.is_empty(),
	}


## Pilih jawaban `index`, atau (-1) lanjut pada node tanpa pilihan.
func select(index: int) -> void:
	if finished:
		return
	var n: Dictionary = nodes[node_id]
	var choices: Array = n["choices"]
	var nxt: String = String(n["next"])
	var ends: bool = bool(n["end"])
	if not choices.is_empty():
		if index < 0 or index >= choices.size():
			return
		var c: Dictionary = choices[index]
		_run_action(String(c["action"]))
		nxt = String(c["next"])
		ends = false
	elif index != -1:
		return
	if ends or nxt == "" or not nodes.has(nxt):
		finished = true
		node_id = ""
		return
	node_id = nxt


func _run_action(action: String) -> void:
	if action == "" or req_log == null:
		return
	var parts: PackedStringArray = action.split(":")
	if parts.size() != 2:
		return
	match parts[0]:
		"accept": req_log.accept(parts[1])
		"claim": req_log.claim(parts[1])
