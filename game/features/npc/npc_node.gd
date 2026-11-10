class_name NpcNode
extends Node2D
## Node tampilan satu NPC di dunia. Posisi node = telapak kaki (titik Y-sort), sama dengan pemain.
## Menggambar ulang hanya saat bingkai animasi berganti (hemat CPU). State "sit" dipakai saat duduk.

var agent: NpcAgent
var tile: Vector2 = Vector2(64, 32)
var animator: PlayerAnimator = PlayerAnimator.new()
var view: CharacterView
var _last_key: String = ""


func setup(p_agent: NpcAgent, p_tile: Vector2) -> void:
	agent = p_agent
	tile = p_tile
	view = CharacterView.new()
	view.body_scale = tile.x / 64.0
	view.appearance = agent.data.make_appearance()
	add_child(view)
	sync(0.0)


func sync(delta: float) -> void:
	position = IsoMath.grid_to_screen(agent.pos, tile) + (Vector2(0.0, 1.0) if agent.sitting else Vector2.ZERO)
	animator.update(delta, agent.moving, agent.facing)
	var st: String = "sit" if agent.sitting else animator.state
	var step: int = int(animator.phase() * 10.0)
	var key: String = "%s|%d|%d" % [st, animator.facing, step]
	if key != _last_key:
		_last_key = key
		view.apply_animation(st, animator.phase(), animator.facing)
