class_name PlayerAnimator
extends RefCounted
## Mesin keadaan animasi pemain (logika murni, dites unit): idle dan walk x 8 arah.
## Nama animasi mengikuti konvensi aset final: "idle_s", "walk_ne", dst. Saat sprite final
## tiba, nama ini dipakai langsung sebagai nama animasi SpriteFrames.

const IDLE: String = "idle"
const WALK: String = "walk"
const WALK_CYCLE_SEC: float = 0.6
const IDLE_CYCLE_SEC: float = 2.4

var state: String = IDLE
var facing: int = 0
var time: float = 0.0


## Maju satu frame. `moving` = pemain benar-benar berpindah (bukan sekadar masukan).
func update(delta: float, moving: bool, new_facing: int) -> void:
	var wanted: String = WALK if moving else IDLE
	if wanted != state:
		state = wanted
		time = 0.0
	facing = posmod(new_facing, 8)
	time += delta


## Fase siklus 0..1 (berulang).
func phase() -> float:
	var cycle: float = WALK_CYCLE_SEC if state == WALK else IDLE_CYCLE_SEC
	return fposmod(time, cycle) / cycle


func animation_name() -> String:
	return "%s_%s" % [state, IsoMath.direction_name(facing)]
