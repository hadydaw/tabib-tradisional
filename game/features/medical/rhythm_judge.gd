class_name RhythmJudge
extends RefCounted
## Penilai ketukan ritme (logika murni, dites unit): mencocokkan ketukan pemain dengan ketukan target.
## Dipakai pemeriksaan nadi (diagnosis) dan menumbuk (peracikan).


## Per ketukan target: skor 1.0 bila selisih <= `perfect`, menurun linear ke 0 pada `good`, 0 di luar itu.
## Setiap sentuhan hanya dipakai sekali (yang terdekat). Mengembalikan {score, perfect, good, miss, extra, per_beat}.
static func judge(beats: Array, taps: Array, perfect: float, good: float) -> Dictionary:
	var used: Array = []
	for i in range(taps.size()):
		used.append(false)
	var per: Array = []
	var perfect_n: int = 0
	var good_n: int = 0
	var miss_n: int = 0
	var matched: int = 0
	var sum: float = 0.0
	for b in beats:
		var best: int = -1
		var best_d: float = 1e9
		for i in range(taps.size()):
			if used[i]:
				continue
			var d: float = absf(float(taps[i]) - float(b))
			if d < best_d:
				best_d = d
				best = i
		var s: float = 0.0
		if best >= 0 and best_d <= good:
			used[best] = true
			matched += 1
			if best_d <= perfect:
				s = 1.0
				perfect_n += 1
			else:
				s = 1.0 - (best_d - perfect) / maxf(0.0001, good - perfect)
				s = clampf(s, 0.0, 1.0)
				good_n += 1
		else:
			miss_n += 1
		per.append(s)
		sum += s
	var extra: int = maxi(0, taps.size() - matched)
	var score: float = sum / float(maxi(1, beats.size()))
	score *= maxf(0.25, 1.0 - 0.12 * float(extra))
	return {"score": score, "perfect": perfect_n, "good": good_n, "miss": miss_n, "extra": extra, "per_beat": per}
