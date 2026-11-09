class_name PerfStats
extends RefCounted
## Ringkasan statistik waktu frame (logika murni, dites unit).

## Persentil nearest-rank: p dalam 0..1 pada array yang sudah diurutkan naik.
static func percentile(sorted_values: PackedFloat32Array, p: float) -> float:
	var n: int = sorted_values.size()
	if n == 0:
		return 0.0
	var rank: int = clampi(int(ceil(p * float(n))), 1, n)
	return sorted_values[rank - 1]


## {"n","avg","p95","p99","max","jank_pct"}; jank_pct = persen frame lebih lambat dari jank_ms.
static func summarize(values: PackedFloat32Array, jank_ms: float = 20.0) -> Dictionary:
	var n: int = values.size()
	if n == 0:
		return {"n": 0, "avg": 0.0, "p95": 0.0, "p99": 0.0, "max": 0.0, "jank_pct": 0.0}
	var sorted: PackedFloat32Array = values.duplicate()
	sorted.sort()
	var total: float = 0.0
	var slow: int = 0
	for v: float in values:
		total += v
		if v > jank_ms:
			slow += 1
	return {
		"n": n, "avg": total / float(n),
		"p95": percentile(sorted, 0.95), "p99": percentile(sorted, 0.99),
		"max": sorted[n - 1], "jank_pct": 100.0 * float(slow) / float(n),
	}
