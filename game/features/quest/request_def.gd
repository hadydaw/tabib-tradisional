class_name RequestDef
extends RefCounted
## Definisi permintaan sederhana dari NPC (bukan sistem quest penuh). Dua jenis syarat:
## "talk_to" (bicara dengan NPC target) dan "visit" (masuk zona bernama). Tanpa hadiah.

const TALK_TO: String = "talk_to"
const VISIT: String = "visit"

static var _defs: Dictionary = {
	"req_salam_wiryo": {"giver": "karto", "type": TALK_TO, "target": "wiryo"},
	"req_lihat_kebun": {"giver": "lastri", "type": VISIT, "target": "Kebun Herbal"},
	"req_kabar_joko": {"giver": "dewi", "type": TALK_TO, "target": "joko"},
	"req_lihat_resepsi": {"giver": "ratih", "type": VISIT, "target": "Area Penerimaan"},
}


static func get_def(id: String) -> Dictionary:
	return _defs.get(id, {})


static func ids() -> Array:
	return _defs.keys()
