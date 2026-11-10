class_name GameClock
extends RefCounted
## Jam permainan: hari dan menit (0..1439). Logika murni, dites unit.
## `minutes_per_second` = berapa menit permainan per detik nyata (bawaan 1,0 -> sehari 24 menit nyata).

const MINUTES_PER_DAY: int = 1440

var day: int = 1
var minute_f: float = 7.0 * 60.0  # mulai pukul 07:00
var minutes_per_second: float = 1.0
var paused: bool = false


func advance(delta_sec: float) -> void:
	if paused or delta_sec <= 0.0:
		return
	minute_f += delta_sec * minutes_per_second
	while minute_f >= float(MINUTES_PER_DAY):
		minute_f -= float(MINUTES_PER_DAY)
		day += 1


func minute() -> int:
	return int(floorf(minute_f)) % MINUTES_PER_DAY


func set_time(p_day: int, hour: int, min: int = 0) -> void:
	day = p_day
	minute_f = float(clampi(hour, 0, 23) * 60 + clampi(min, 0, 59))


## Jumlah menit absolut sejak hari 1 pukul 00:00.
func absolute_minutes() -> float:
	return float(day - 1) * float(MINUTES_PER_DAY) + minute_f


func format_time() -> String:
	var m: int = minute()
	return "%02d:%02d" % [m / 60, m % 60]


static func format_minute(m: int) -> String:
	m = posmod(m, MINUTES_PER_DAY)
	return "%02d:%02d" % [m / 60, m % 60]
