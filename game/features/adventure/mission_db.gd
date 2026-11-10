class_name MissionDb
extends RefCounted
## Misi Pengembara (data fiktif, berurutan). `goal.keys` = kunci penghitung di AdventureState; semuanya harus
## mencapai `goal.n`. Hadiah berupa koin. Teks: `mission.<id>.title|desc` (tools/loc_fase7.py).


static func all() -> Array[Dictionary]:
	return [
		{"id": "m_hutan", "goal": {"keys": ["gather:hutan"], "n": 4}, "coin": 60},
		{"id": "m_kenali", "goal": {"keys": ["identify_new"], "n": 3}, "coin": 90},
		{"id": "m_jelajah", "goal": {"keys": ["visit:sungai", "visit:pegunungan"], "n": 1}, "coin": 80},
		{"id": "m_celah", "goal": {"keys": ["secret"], "n": 1}, "coin": 150},
	]


static func goal_n(m: Dictionary) -> int:
	return int((m["goal"] as Dictionary)["n"])


static func goal_keys(m: Dictionary) -> Array:
	return (m["goal"] as Dictionary)["keys"]
