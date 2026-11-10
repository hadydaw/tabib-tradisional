class_name NpcSimulation
extends RefCounted
## Simulasi seluruh NPC (logika murni, dites unit): jadwal harian, navigasi A* pada grid yang sama
## dengan tabrakan pemain, perpindahan antarlokasi lewat keset pintu, dan penanganan tersangkut.
## Semua NPC disimulasikan setiap saat (murah), tetapi hanya NPC di lokasi aktif yang digambar.
##
## Cara menghindari tersangkut/bertumpuk:
## - Satu sel hanya boleh dipesan satu agen (hunian). Langkah ke sel berikutnya perlu pesanan.
## - Bila sel berikutnya dipakai agen lain/pemain: tunggu, lalu rencanakan ulang menghindari sel itu,
##   lalu bila tetap gagal batalkan tugas sementara dan geser ke sel terbuka terdekat (evade).
## - Pengawas kemajuan: tanpa sel baru selama STUCK_SEC, paksa evade.

signal agent_arrived(agent_id: String, goal_key: String)
signal agent_location_changed(agent_id: String, from_loc: String, to_loc: String)

const WALK_SPEED: float = 1.9        # sel per detik
const SUBSTEP: float = 0.1
const WAIT_SEC: float = 1.0
const STUCK_SEC: float = 9.0
const PLAYER_MARGIN: float = 0.32

var clock: GameClock
var agents: Array[NpcAgent] = []
var stats: Dictionary = {"replans": 0, "evasions": 0, "waits": 0, "watchdog": 0, "failed_plans": 0}

var _by_id: Dictionary = {}
var _navs: Dictionary = {}
var _occ: Dictionary = {}          # loc -> {cell: agent_id}
var _player_loc: String = ""
var _player_cells: Dictionary = {}


func setup(npcs: Array[NpcData], p_clock: GameClock) -> void:
	clock = p_clock
	agents.clear()
	_by_id.clear()
	var i: int = 0
	for n in npcs:
		var a := NpcAgent.new()
		a.data = n
		a.id = n.id
		a.rank = i
		a.rng.seed = hash(n.id) + 7
		a.wander_timer = a.rng.randf_range(2.0, 8.0)
		agents.append(a)
		_by_id[n.id] = a
		i += 1
	snap_to_schedule()


func agent(id: String) -> NpcAgent:
	return _by_id.get(id, null)


func agents_in(loc: String) -> Array[NpcAgent]:
	var out: Array[NpcAgent] = []
	for a in agents:
		if a.loc == loc and loc != "":
			out.append(a)
	return out


## Sel yang sedang dipakai/dipesan NPC di lokasi (dipakai tabrakan pemain). Dictionary hidup, jangan diubah.
func occupied_cells(loc: String) -> Dictionary:
	return _occ_of(loc)


func navigation(loc: String) -> GridPathfinder:
	return _nav(loc)


# --- Pemain ------------------------------------------------------------------

func set_player(loc: String, pos: Vector2) -> void:
	_player_loc = loc
	_player_cells = {}
	var x0: int = floori(pos.x - PLAYER_MARGIN)
	var x1: int = ceili(pos.x + PLAYER_MARGIN) - 1
	var y0: int = floori(pos.y - PLAYER_MARGIN)
	var y1: int = ceili(pos.y + PLAYER_MARGIN) - 1
	for cy in range(y0, y1 + 1):
		for cx in range(x0, x1 + 1):
			_player_cells[Vector2i(cx, cy)] = true


## Pemain muncul di `pos`: geser NPC yang menempati sel itu ke sel terbuka terdekat.
func clear_for_player(loc: String, pos: Vector2) -> void:
	set_player(loc, pos)
	var occ: Dictionary = _occ_of(loc)
	for c: Vector2i in _player_cells.keys():
		if occ.has(c):
			var a: NpcAgent = agent(String(occ[c]))
			if a != null:
				_relocate_nearby(a)


func _relocate_nearby(a: NpcAgent) -> void:
	var pf: GridPathfinder = _nav(a.loc)
	var avoid: Dictionary = _others_occ(a)
	for c: Vector2i in _player_cells.keys():
		avoid[c] = true
	var dest: Vector2i = pf.nearest_open(a.cell, avoid, 6)
	if dest.x < 0:
		return
	_occ_of(a.loc).erase(a.cell)
	if a.moving and not a.path.is_empty():
		_occ_of(a.loc).erase(a.path[0])
	a.moving = false
	a.path.clear()
	a.cell = dest
	a.pos = Vector2(dest) + Vector2(0.5, 0.5)
	_occ_of(a.loc)[dest] = a.id
	a.sitting = false
	a.arrived = false


# --- Pembaruan ---------------------------------------------------------------

func update(delta: float) -> void:
	var remaining: float = minf(delta, 1.0)
	while remaining > 0.0:
		var dt: float = minf(remaining, SUBSTEP)
		remaining -= dt
		clock.advance(dt)
		var minute: int = clock.minute()
		for a in agents:
			_step_agent(a, dt, minute)


## Tempatkan semua NPC sesuai jadwal saat ini tanpa berjalan (awal permainan, lompat waktu).
func snap_to_schedule() -> void:
	for a in agents:
		_release(a)
		a.path.clear()
		a.moving = false
		a.evading = false
		a.cooldown = 0.0
		a.sitting = false
		a.override_goal = {}
		a.cached_minute = -1
	var minute: int = clock.minute()
	for a in agents:
		var goal: Dictionary = a.data.goal_at(minute)
		a.goal_key = goal["key"]
		a.current_activity = goal["activity"]
		if goal["home"]:
			a.loc = ""
			a.cell = Vector2i(-1, -1)
			a.state = NpcAgent.INDOORS
			a.arrived = true
			continue
		var loc: String = goal["loc"]
		var pf: GridPathfinder = _nav(loc)
		var cells: Array = LocationRegistry.get_location(loc).spot_cells(goal["spot"])
		var placed: Vector2i = Vector2i(-1, -1)
		var start_i: int = a.rng.randi() % maxi(1, cells.size())
		for k in range(cells.size()):
			var c: Vector2i = cells[(start_i + k) % cells.size()]
			if not _occ_of(loc).has(c) and pf.passable(c, {}, {}):
				placed = c
				break
		if placed.x < 0:
			placed = pf.nearest_open(cells[0] if not cells.is_empty() else Vector2i(1, 1), _occ_of(loc), 6)
		a.loc = loc
		a.cell = placed
		a.pos = Vector2(placed) + Vector2(0.5, 0.5)
		a.state = NpcAgent.IDLE
		a.arrived = true
		_occ_of(loc)[placed] = a.id


func set_override(id: String, goal: Dictionary) -> void:
	var a: NpcAgent = agent(id)
	if a != null:
		a.override_goal = goal


func clear_override(id: String) -> void:
	var a: NpcAgent = agent(id)
	if a != null:
		a.override_goal = {}


# --- Inti per agen -----------------------------------------------------------

func _goal_for(a: NpcAgent, minute: int) -> Dictionary:
	if not a.override_goal.is_empty():
		return a.override_goal
	if a.cached_minute != minute:
		a.cached_minute = minute
		a.cached_goal = a.data.goal_at(minute)
	return a.cached_goal


func _step_agent(a: NpcAgent, dt: float, minute: int) -> void:
	var goal: Dictionary = _goal_for(a, minute)
	if a.goal_key != goal["key"]:
		_on_goal_changed(a, goal)
	if a.loc == "":
		_step_indoors(a, goal)
		return
	if a.moving:
		_advance_move(a, dt)
		return
	if a.talking:
		a.state = NpcAgent.IDLE
		return
	if a.cooldown > 0.0:
		a.cooldown -= dt
		a.state = NpcAgent.COOLDOWN
		if a.cooldown > 0.0:
			return
		a.state = NpcAgent.IDLE
		a.replans = 0
	if not a.path.is_empty():
		_try_start_step(a, dt)
		return
	if a.evading:
		a.evading = false
		a.cooldown = a.rng.randf_range(3.0, 6.0)
		a.state = NpcAgent.COOLDOWN
		return
	_decide(a, goal, dt)


func _on_goal_changed(a: NpcAgent, goal: Dictionary) -> void:
	a.goal_key = goal["key"]
	a.current_activity = goal["activity"]
	a.arrived = false
	a.replans = 0
	a.cooldown = 0.0
	a.evading = false
	a.wait_time = 0.0
	a.since_progress = 0.0
	a.sitting = false
	if a.moving and not a.path.is_empty():
		var first: Vector2i = a.path[0]
		a.path.clear()
		a.path.append(first)  # selesaikan langkah yang sudah berjalan
	else:
		a.path.clear()
	if a.state != NpcAgent.INDOORS:
		a.state = NpcAgent.IDLE


func _step_indoors(a: NpcAgent, goal: Dictionary) -> void:
	if goal["home"]:
		a.arrived = true
		return
	# keluar rumah lewat pintu
	var village: LocationData = LocationRegistry.get_location("desa")
	var door: Vector2i = village.doors.get(a.data.home_spot, Vector2i(-1, -1))
	if door.x < 0:
		return
	var avoid: Dictionary = _occ_of("desa").duplicate()
	if _player_loc == "desa":
		for c: Vector2i in _player_cells.keys():
			avoid[c] = true
	var c2: Vector2i = door
	if avoid.has(door):
		c2 = _nav("desa").nearest_open(door, avoid, 4)
		if c2.x < 0:
			return  # pintu penuh; coba lagi nanti
	a.loc = "desa"
	a.cell = c2
	a.pos = Vector2(c2) + Vector2(0.5, 0.5)
	a.state = NpcAgent.IDLE
	a.arrived = false
	a.facing = 0
	_occ_of("desa")[c2] = a.id
	agent_location_changed.emit(a.id, "", "desa")


func _advance_move(a: NpcAgent, dt: float) -> void:
	var nxt: Vector2i = a.path[0]
	var target: Vector2 = Vector2(nxt) + Vector2(0.5, 0.5)
	var d: Vector2 = target - a.pos
	var step: float = WALK_SPEED * dt
	a.since_progress += dt
	if d.length() <= step:
		a.pos = target
		var occ: Dictionary = _occ_of(a.loc)
		if occ.get(a.cell, "") == a.id:
			occ.erase(a.cell)
		a.cell = nxt
		a.path.remove_at(0)
		a.moving = false
		a.since_progress = 0.0
		a.state = NpcAgent.WALKING if not a.path.is_empty() else NpcAgent.IDLE
	else:
		a.pos += d.normalized() * step


func _try_start_step(a: NpcAgent, dt: float) -> void:
	var nxt: Vector2i = a.path[0]
	if _can_enter(a, nxt):
		_occ_of(a.loc)[nxt] = a.id
		a.moving = true
		a.facing = _facing_for(nxt - a.cell)
		a.state = NpcAgent.WALKING
		a.wait_time = 0.0
		return
	a.state = NpcAgent.WAITING
	a.wait_time += dt
	a.since_progress += dt
	if a.since_progress > STUCK_SEC:
		stats["watchdog"] += 1
		_evade(a)
		return
	var limit: float = WAIT_SEC + 0.5 * float(a.rank)
	if a.wait_time < limit:
		return
	stats["waits"] += 1
	a.wait_time = 0.0
	a.replans += 1
	if a.replans <= 2:
		# rencanakan ulang menghindari sel yang dipakai
		var goal_cell: Vector2i = a.path[a.path.size() - 1]
		var pf: GridPathfinder = _nav(a.loc)
		var avoid: Dictionary = _others_occ(a)
		avoid.erase(goal_cell)
		var np: Array[Vector2i] = pf.find_path(a.cell, goal_cell, avoid, _allow_for(a, goal_cell))
		stats["replans"] += 1
		if not np.is_empty():
			a.path = np
			return
	_evade(a)


func _can_enter(a: NpcAgent, cell: Vector2i) -> bool:
	var occ: Dictionary = _occ_of(a.loc)
	if occ.has(cell) and occ[cell] != a.id:
		return false
	if a.loc == _player_loc and _player_cells.has(cell):
		return false
	var dlt: Vector2i = cell - a.cell
	if dlt.x != 0 and dlt.y != 0:
		for oc in [Vector2i(a.cell.x + dlt.x, a.cell.y), Vector2i(a.cell.x, a.cell.y + dlt.y)]:
			if occ.has(oc) and occ[oc] != a.id:
				return false
			if a.loc == _player_loc and _player_cells.has(oc):
				return false
	return true


## Batalkan tugas sementara dan menepi ke sel terbuka terdekat; lalu jeda sebelum mencoba lagi.
func _evade(a: NpcAgent) -> void:
	stats["evasions"] += 1
	a.path.clear()
	a.replans = 0
	a.wait_time = 0.0
	a.since_progress = 0.0
	a.arrived = false
	var pf: GridPathfinder = _nav(a.loc)
	var avoid: Dictionary = _others_occ(a)
	var spot: Vector2i = pf.nearest_open(a.cell, avoid, 5)
	if spot.x >= 0:
		var p: Array[Vector2i] = pf.find_path(a.cell, spot, avoid)
		if not p.is_empty():
			a.path = p
			a.evading = true
			a.state = NpcAgent.WALKING
			return
	a.cooldown = a.rng.randf_range(3.0, 6.0)
	a.state = NpcAgent.COOLDOWN


func _decide(a: NpcAgent, goal: Dictionary, dt: float) -> void:
	var goal_loc: String = goal["loc"]
	var pf: GridPathfinder = _nav(a.loc)
	if goal_loc == a.loc:
		var target: Vector2i = _pick_target(a, goal)
		if target.x < 0:
			a.cooldown = 2.0  # tidak ada sel tujuan bebas; tunggu
			return
		if a.cell == target:
			_arrived(a, goal, dt)
			return
		var p: Array[Vector2i] = pf.find_path(a.cell, target, _others_occ(a), _allow_for(a, target))
		if p.is_empty():
			_fail_plan(a)
			return
		a.path = p
		a.state = NpcAgent.WALKING
		return
	# tujuan di lokasi lain: menuju keset pintu menuju lokasi itu
	var hop: Dictionary = _next_hop(a.loc, goal_loc)
	if hop.is_empty():
		a.cooldown = 5.0
		return
	var cells: Array = hop["cells"]
	if cells.has(a.cell):
		_transit(a, hop)
		return
	var best: Array[Vector2i] = []
	var avoid: Dictionary = _others_occ(a)
	for c: Vector2i in cells:
		if avoid.has(c):
			continue
		var p2: Array[Vector2i] = pf.find_path(a.cell, c, avoid)
		if not p2.is_empty() and (best.is_empty() or p2.size() < best.size()):
			best = p2
	if best.is_empty():
		_fail_plan(a)
		return
	a.path = best
	a.state = NpcAgent.WALKING


func _fail_plan(a: NpcAgent) -> void:
	stats["failed_plans"] += 1
	a.replans += 1
	if a.replans >= 3:
		a.replans = 0
		_evade(a)
	else:
		a.cooldown = 0.8


func _pick_target(a: NpcAgent, goal: Dictionary) -> Vector2i:
	if NpcGoal.has_cell(goal):
		var c: Vector2i = goal["cell"]
		var occ: Dictionary = _occ_of(a.loc)
		if occ.has(c) and occ[c] != a.id:
			return Vector2i(-1, -1)
		return c
	var cells: Array = LocationRegistry.get_location(a.loc).spot_cells(goal["spot"])
	if cells.is_empty():
		return Vector2i(-1, -1)
	if cells.has(a.cell) and not goal["wander"]:
		return a.cell
	var pf: GridPathfinder = _nav(a.loc)
	var occ2: Dictionary = _others_occ(a)
	var free: Array[Vector2i] = []
	for c2: Vector2i in cells:
		if (not occ2.has(c2)) and pf.passable(c2, {}, {}):
			free.append(c2)
	if free.is_empty():
		return Vector2i(-1, -1)
	if cells.has(a.cell):
		return a.cell
	free.sort_custom(func(x: Vector2i, y: Vector2i) -> bool:
		return (x - a.cell).length_squared() < (y - a.cell).length_squared())
	return free[a.rng.randi() % mini(3, free.size())]


func _arrived(a: NpcAgent, goal: Dictionary, dt: float) -> void:
	if not a.arrived:
		a.arrived = true
		a.state = NpcAgent.IDLE
		a.wander_timer = a.rng.randf_range(4.0, 9.0)
		if goal["seat"]:
			a.sitting = true
			var st: Dictionary = LocationRegistry.get_location(a.loc).seat_at(a.cell)
			if not st.is_empty():
				a.facing = int(st["facing"])
		var key: String = goal["key"]
		agent_arrived.emit(a.id, key)
		if goal["home"] and a.goal_key == key:
			_go_indoors(a)
		return
	if goal["wander"] and not goal["seat"]:
		a.wander_timer -= dt
		if a.wander_timer <= 0.0:
			a.wander_timer = a.rng.randf_range(4.0, 9.0)
			var cells: Array = LocationRegistry.get_location(a.loc).spot_cells(goal["spot"])
			if cells.size() > 1:
				var c: Vector2i = cells[a.rng.randi() % cells.size()]
				var occ: Dictionary = _others_occ(a)
				if c != a.cell and not occ.has(c):
					var p: Array[Vector2i] = _nav(a.loc).find_path(a.cell, c, occ)
					if not p.is_empty() and p.size() <= 14:
						a.path = p
						a.state = NpcAgent.WALKING
						a.arrived = true  # tetap dianggap tiba di tujuan


func _go_indoors(a: NpcAgent) -> void:
	var from: String = a.loc
	_release(a)
	a.loc = ""
	a.cell = Vector2i(-1, -1)
	a.state = NpcAgent.INDOORS
	a.moving = false
	a.path.clear()
	a.sitting = false
	agent_location_changed.emit(a.id, from, "")


func _transit(a: NpcAgent, hop: Dictionary) -> void:
	var from: String = a.loc
	var target_loc: String = hop["target"]
	var data: LocationData = LocationRegistry.get_location(target_loc)
	var sp: Vector2 = data.spawns[hop["spawn"]]
	var c: Vector2i = Vector2i(floori(sp.x), floori(sp.y))
	var avoid: Dictionary = _occ_of(target_loc).duplicate()
	if _player_loc == target_loc:
		for pc: Vector2i in _player_cells.keys():
			avoid[pc] = true
	if avoid.has(c):
		c = _nav(target_loc).nearest_open(c, avoid, 5)
		if c.x < 0:
			a.cooldown = 1.0
			return
	_release(a)
	a.loc = target_loc
	a.cell = c
	a.pos = Vector2(c) + Vector2(0.5, 0.5)
	a.path.clear()
	a.moving = false
	a.state = NpcAgent.IDLE
	a.arrived = false
	_occ_of(target_loc)[c] = a.id
	agent_location_changed.emit(a.id, from, target_loc)


# --- Bantuan -----------------------------------------------------------------

func _release(a: NpcAgent) -> void:
	if a.loc == "":
		return
	var occ: Dictionary = _occ_of(a.loc)
	var to_erase: Array = []
	for c: Vector2i in occ.keys():
		if occ[c] == a.id:
			to_erase.append(c)
	for c2 in to_erase:
		occ.erase(c2)


func _occ_of(loc: String) -> Dictionary:
	if not _occ.has(loc):
		_occ[loc] = {}
	return _occ[loc]


func _others_occ(a: NpcAgent) -> Dictionary:
	var out: Dictionary = {}
	var occ: Dictionary = _occ_of(a.loc)
	for c: Vector2i in occ.keys():
		if occ[c] != a.id:
			out[c] = true
	if a.loc == _player_loc:
		for pc: Vector2i in _player_cells.keys():
			out[pc] = true
	return out


func _allow_for(a: NpcAgent, target: Vector2i) -> Dictionary:
	var data: LocationData = LocationRegistry.get_location(a.loc)
	if data.is_seat(target):
		return {target: true}
	return {}


func _nav(loc: String) -> GridPathfinder:
	if not _navs.has(loc):
		var data: LocationData = LocationRegistry.get_location(loc)
		var pf := GridPathfinder.new(data.width, data.height)
		pf.blocked = data.blocked_cells()
		for t in data.transitions:
			for c: Vector2i in t["cells"]:
				pf.extra_cost[c] = 6.0
		_navs[loc] = pf
	return _navs[loc]


## Transisi pertama dari `from` menuju `to` (BFS pada graf lokasi). Kosong bila tak terhubung.
func _next_hop(from: String, to: String) -> Dictionary:
	if from == to:
		return {}
	var visited: Dictionary = {from: true}
	var queue: Array = [[from, {}]]
	while not queue.is_empty():
		var item: Array = queue.pop_front()
		var cur: String = item[0]
		var first: Dictionary = item[1]
		for t in LocationRegistry.get_location(cur).transitions:
			var nxt: String = t["target"]
			if visited.has(nxt):
				continue
			visited[nxt] = true
			var f: Dictionary = first if not first.is_empty() else t
			if nxt == to:
				return f
			queue.append([nxt, f])
	return {}


static func facing_for(grid_delta: Vector2) -> int:
	return IsoMath.direction_index(IsoMath.grid_to_screen(grid_delta, Vector2(64, 32)))


func _facing_for(d: Vector2i) -> int:
	return facing_for(Vector2(d))
