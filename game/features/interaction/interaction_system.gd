class_name InteractionSystem
extends RefCounted
## Memilih titik interaksi terbaik untuk pemain. Logika murni, dites unit.
## Skor = jarak dikurangi bonus bila titik berada di depan arah hadap.

const FRONT_BONUS: float = 0.4


## `facing_dir` = vektor arah hadap di ruang grid (tak harus satuan; nol = tanpa bonus).
static func find_best(player_grid: Vector2, facing_dir: Vector2, list: Array) -> Interactable:
	var best: Interactable = null
	var best_score: float = INF
	var f: Vector2 = facing_dir.normalized() if facing_dir.length() > 0.0001 else Vector2.ZERO
	for it: Interactable in list:
		var to: Vector2 = it.center() - player_grid
		var dist: float = to.length()
		if dist > it.radius:
			continue
		var front: float = 0.0
		if dist > 0.0001 and f != Vector2.ZERO:
			front = maxf(0.0, to.normalized().dot(f))
		var score: float = dist - FRONT_BONUS * front
		if score < best_score:
			best_score = score
			best = it
	return best
