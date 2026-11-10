class_name Interactable
extends RefCounted
## Titik interaksi di dunia (struktur saja; belum ada sistem di baliknya).
## `id` stabil (dipakai sistem lain nanti), `prompt` teks tampilan (Indonesia, sementara).

var id: String
var cell: Vector2i
var prompt: String
var radius: float  # jarak maksimum (satuan kotak) dari pemain ke tengah sel


func _init(p_id: String, p_cell: Vector2i, p_prompt: String, p_radius: float = 1.6) -> void:
	id = p_id
	cell = p_cell
	prompt = p_prompt
	radius = p_radius


func center() -> Vector2:
	return Vector2(cell.x + 0.5, cell.y + 0.5)
