extends RefCounted
## Independent fixed-step rules. All coordinates are original sprite pixels.
const MOVES = {"jab": {"clip": "r3_jab_head", "damage": 7.0, "cost": 5.0},
	"cross": {"clip": "r3_cross_head", "damage": 12.0, "cost": 9.0}}
var data: Dictionary
var fighters: Array[Dictionary] = []
var time := 0.0
var result := ""
var feedback := "Aproxime-se e teste a distância."
var hitstop := 0.0
var ai_enabled := true
var ai_timer := 0.7
var ai_turn := 0

func _init() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/combat.json"))
	reset()

func reset() -> void:
	fighters.clear()
	for i in 2:
		fighters.append({"x": 122.0 + i * 76.0, "facing": 1 if i == 0 else -1,
			"hp": 100.0, "stamina": 100.0, "state": "idle", "elapsed": 0.0,
			"clip": "r1_idle", "frame": 0, "connected": false,
			"guard": false, "stun": 0.0, "dodge_cooldown": 0.0})
	time = 0.0
	hitstop = 0.0
	result = ""
	feedback = "Aproxime-se e teste a distância."
	ai_timer = 0.7
	ai_turn = 0

func total(clip: String) -> float:
	var value := 0.0
	for ms in data.clips[clip].durations:
		value += float(ms) / 1000.0
	return value

func frame_at(clip: String, elapsed: float, loop: bool) -> int:
	var t := fmod(elapsed, total(clip)) if loop else elapsed
	var durations: Array = data.clips[clip].durations
	for i in durations.size():
		t -= float(durations[i]) / 1000.0
		if t < 0.0:
			return i
	return durations.size() - 1

func command(index: int, action: String) -> bool:
	var f := fighters[index]
	if result != "" or f.stun > 0.0 or f.state in ["jab", "cross", "dodge"]:
		return false
	if action == "dodge":
		if f.stamina < 14.0 or f.dodge_cooldown > 0.0:
			return false
		f.stamina -= 14.0
		f.dodge_cooldown = 0.75
		f.state = "dodge"
		f.elapsed = 0.0
		f.guard = false
		return true
	if not MOVES.has(action) or f.guard or f.stamina < MOVES[action].cost:
		return false
	f.stamina -= MOVES[action].cost
	f.state = action
	f.clip = MOVES[action].clip
	f.elapsed = 0.0
	f.frame = 0
	f.connected = false
	return true

func marker(index: int) -> Dictionary:
	var f := fighters[index]
	return data.markers[f.clip][f.frame]

func world_rect(index: int, box: Array) -> Rect2:
	var f := fighters[index]
	var a: float = f.x + float(box[0]) * f.facing
	var b: float = f.x + float(box[2]) * f.facing
	return Rect2(minf(a, b), float(box[1]), absf(b - a), float(box[3]) - float(box[1]))

func hurtboxes(index: int) -> Array[Rect2]:
	var boxes: Array[Rect2] = []
	for zone in ["head", "body"]:
		for box in marker(index).get("hurt", {}).get(zone, []):
			boxes.append(world_rect(index, box))
	return boxes

func hitbox(index: int) -> Rect2:
	var f := fighters[index]
	if not MOVES.has(f.state):
		return Rect2()
	var active := false
	for frame in data.clips[f.clip].contactFrames:
		if int(frame) == int(f.frame):
			active = true
	if not active:
		return Rect2()
	var fist: Dictionary = marker(index).get("frontFist", {})
	if fist.is_empty():
		return Rect2() # Missing measured marker means no attack box.
	var tip: float = f.x + float(fist.tipX) * f.facing
	return Rect2(tip - (6.0 if f.facing > 0 else 0.0), float(fist.tipY) - 3.0, 6.0, 6.0)

func resolve_hit(attacker: int) -> void:
	var f := fighters[attacker]
	if f.connected:
		return
	var box := hitbox(attacker)
	if not box.has_area():
		return
	var target := 1 - attacker
	var victim := fighters[target]
	for hurt in hurtboxes(target):
		if not box.intersects(hurt):
			continue
		f.connected = true
		var blocking: bool = victim.guard and victim.facing != f.facing and victim.stamina >= 8.0
		if blocking:
			victim.stamina = maxf(0.0, victim.stamina - 15.0)
			victim.stun = 0.12
			victim.state = "blockstun"
			victim.clip = "block"
			feedback = "Bloqueado"
		else:
			victim.hp = maxf(0.0, victim.hp - float(MOVES[f.state].damage))
			victim.stun = 0.22 if f.state == "jab" else 0.30
			victim.state = "hurt"
			victim.clip = "hurt"
			victim.guard = false
			feedback = "Jab acertou" if f.state == "jab" else "Direto acertou"
		victim.elapsed = 0.0
		victim.frame = 0
		victim.x = clampf(victim.x + f.facing * (2.0 if blocking else 4.0), 26.0, 294.0)
		hitstop = 0.035 if blocking else 0.055
		if victim.hp <= 0.0:
			result = "Você venceu" if target == 1 else "Rival venceu"
			feedback = result + " · Reinicie para lutar novamente"
		return

func step(dt: float, direction: float = 0.0, guard: bool = false, actions: Array = []) -> void:
	if result != "":
		return
	if hitstop > 0.0:
		hitstop = maxf(0.0, hitstop - dt)
		return
	time += dt
	var rival_dir := 0.0
	var rival_guard: bool = fighters[1].guard if not ai_enabled else false
	if ai_enabled:
		ai_timer -= dt
		var gap: float = absf(fighters[0].x - fighters[1].x)
		rival_dir = float(fighters[1].facing) if gap > 43.0 else 0.0
		rival_guard = ai_turn % 3 == 2
		if ai_timer <= 0.0:
			ai_turn += 1
			ai_timer = 0.7
			if gap < 61.0:
				command(1, "jab" if ai_turn % 2 == 0 else "cross")
	for i in 2:
		var f := fighters[i]
		f.dodge_cooldown = maxf(0.0, f.dodge_cooldown - dt)
		f.elapsed += dt
		f.stun = maxf(0.0, f.stun - dt)
		if f.stun > 0.0:
			f.frame = frame_at(f.clip, f.elapsed, false)
			continue
		if f.state in ["hurt", "blockstun"] or (MOVES.has(f.state) and f.elapsed >= total(f.clip)) or (f.state == "dodge" and f.elapsed >= 0.23):
			f.state = "idle"
			f.elapsed = 0.0
		if not MOVES.has(f.state) and f.state != "dodge":
			f.facing = 1 if fighters[1 - i].x >= f.x else -1
			f.guard = (guard if i == 0 else rival_guard) and f.stamina > 8.0
			if i == 0:
				for action in actions:
					if command(i, action):
						break
			if not MOVES.has(f.state) and f.state != "dodge":
				var axis: float = clampf(direction if i == 0 else rival_dir, -1.0, 1.0)
				f.state = "guard" if f.guard else ("walk" if axis != 0.0 else "idle")
				f.x += axis * (20.0 if f.guard else 52.0) * dt
				f.clip = "block" if f.guard else ("r2_walk" if axis != 0.0 else "r1_idle")
				f.stamina = clampf(f.stamina + (-4.0 if f.guard else 12.0) * dt, 0.0, 100.0)
		if f.state == "dodge":
			f.x -= float(f.facing) * 145.0 * dt
			f.clip = "r1_idle" # Fast retreat, no fabricated duck animation or invulnerability.
		f.x = clampf(f.x, 26.0, 294.0)
		f.frame = frame_at(f.clip, f.elapsed, not MOVES.has(f.state))
	# Pushboxes stop bodies crossing; resolve symmetrically, including at walls.
	var gap: float = fighters[1].x - fighters[0].x
	if gap < 26.0:
		var center: float = clampf((fighters[0].x + fighters[1].x) / 2.0, 39.0, 281.0)
		fighters[0].x = center - 13.0
		fighters[1].x = center + 13.0
	# Stable attacker order for this POC; simultaneous trades remain review scope.
	resolve_hit(0)
	if result == "":
		resolve_hit(1)
