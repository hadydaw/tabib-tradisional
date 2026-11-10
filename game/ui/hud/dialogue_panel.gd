class_name DialoguePanel
extends Control
## Panel dialog di bagian bawah layar: nama pembicara, teks, dan sampai 4 pilihan (atau tombol Lanjut).
## Memakai TouchActionButton (multi-touch) karena emulasi mouse dari sentuhan dimatikan.
## `choice_selected(index)`: indeks pilihan, atau -1 untuk Lanjut.

signal choice_selected(index: int)

const MAX_CHOICES: int = 4
const PANEL_HEIGHT: float = 236.0

var _speaker: Label
var _text: Label
var _buttons: Array[TouchActionButton] = []
var _next: TouchActionButton
var _choice_count: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", 26)
	_speaker.add_theme_color_override("font_color", Color("#f2d58a"))
	_speaker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_speaker)
	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 24)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)
	for i in range(MAX_CHOICES):
		var b := TouchActionButton.new()
		b.font_size = 22
		b.pressed.connect(func() -> void: choice_selected.emit(i))
		b.visible = false
		add_child(b)
		_buttons.append(b)
	_next = TouchActionButton.new()
	_next.font_size = 26
	_next.pressed.connect(func() -> void: choice_selected.emit(-1))
	_next.visible = false
	add_child(_next)


func layout(vis: Vector2, safe: Rect2) -> void:
	var w: float = safe.size.x - 32.0
	size = Vector2(w, PANEL_HEIGHT)
	position = Vector2(safe.position.x + 16.0, safe.end.y - PANEL_HEIGHT - 12.0)
	_speaker.position = Vector2(20.0, 10.0)
	_speaker.size = Vector2(w - 460.0, 34.0)
	_text.position = Vector2(20.0, 50.0)
	_text.size = Vector2(w - 460.0, PANEL_HEIGHT - 60.0)
	for i in range(_buttons.size()):
		_buttons[i].size = Vector2(410.0, 48.0)
		_buttons[i].position = Vector2(w - 430.0, 12.0 + float(i) * 55.0)
	_next.size = Vector2(300.0, 70.0)
	_next.position = Vector2(w - 320.0, PANEL_HEIGHT - 90.0)
	queue_redraw()


## Tampilkan satu node dialog (hasil DialogueRunner.view()).
func show_view(view: Dictionary) -> void:
	visible = true
	_speaker.text = String(view.get("speaker", ""))
	_text.text = String(view.get("text", ""))
	var labels: Array = view.get("choices", [])
	_choice_count = mini(labels.size(), MAX_CHOICES)
	for i in range(_buttons.size()):
		_buttons[i].visible = i < _choice_count
		if i < _choice_count:
			_buttons[i].text = String(labels[i])
	_next.visible = _choice_count == 0
	_next.text = Locale.t("ui.next")


func hide_panel() -> void:
	visible = false
	for b in _buttons:
		b.visible = false
	_next.visible = false


func choice_count() -> int:
	return _choice_count


func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.11, 0.12, 0.92)
	sb.set_corner_radius_all(18)
	sb.border_color = Color(0.95, 0.85, 0.55, 0.7)
	sb.set_border_width_all(3)
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
