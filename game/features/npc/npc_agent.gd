class_name NpcAgent
extends RefCounted
## Keadaan runtime satu NPC. Diubah hanya oleh NpcSimulation.

const INDOORS: String = "indoors"
const IDLE: String = "idle"
const WALKING: String = "walking"
const WAITING: String = "waiting"
const COOLDOWN: String = "cooldown"

var data: NpcData
var id: String = ""
var rank: int = 0                      # prioritas jalan (kecil = didahulukan)
var loc: String = ""                   # "" = di dalam rumah (tidak tampil)
var cell: Vector2i = Vector2i(-1, -1)  # sel jangkar yang dipesan
var pos: Vector2 = Vector2.ZERO        # posisi kontinu di ruang grid (telapak kaki)
var facing: int = 0
var state: String = INDOORS
var sitting: bool = false
var talking: bool = false
var moving: bool = false
var path: Array[Vector2i] = []
var evading: bool = false
var goal_key: String = ""
var arrived: bool = false
var override_goal: Dictionary = {}     # tujuan khusus (mis. pasien); mengalahkan jadwal
var wait_time: float = 0.0
var since_progress: float = 0.0
var replans: int = 0
var cooldown: float = 0.0
var wander_timer: float = 4.0
var current_activity: String = "di_rumah"
var cached_minute: int = -1
var cached_goal: Dictionary = {}
var rng := RandomNumberGenerator.new()


func is_visible_in(location_id: String) -> bool:
	return loc == location_id and loc != ""


func is_indoors() -> bool:
	return loc == ""
