extends RefCounted
## Port de src/battle.mjs: corredor de treino com profundidade, dois manequins,
## clinch, carregar no golpe, queda física (ragdoll), aparo e modos de treino.
## Estado em dicionários com os mesmos campos do JS (replays comparáveis).
const Ragdoll = preload("res://scripts/corridor/ragdoll.gd")
const CM = preload("res://scripts/corridor/corridor_moves.gd")

const LIMITS := {"minX": 16.0, "maxX": 624.0, "minY": 122.0, "maxY": 164.0}
const PARTS := {"head": 70.0, "body": 80.0, "arms": 60.0, "legs": 60.0}
const CLINCH := {"entry": 240.0, "grip": 3200.0, "maxGrip": 4000.0, "refresh": 700.0, "guardDamage": 18.0}

var moves: Dictionary
var can := {"run": true, "grab": true, "wipe": true}
var fallback := {}
var count := 2
var seed := 731
var mode := "reaction"
var rng := 0
var player: Dictionary
var enemies: Array = []
var clock := 0.0
var hitstop := 0.0
var attack_id := 0
var buffer: Variant = null
var last_hit: Variant = null
var advantage: Variant = null
var carry: Variant = null
var guard_held := false
var parry_ready := 0.0
var last_event: Variant = null
var event_id := 0
var combo := {"hits": 0, "best": 0, "ttl": 0.0}
var message := ""
var art_clips: Dictionary = {}       # clipes do Sorriso (manequins e pontas dos golpes)
var player_clips: Variant = null     # clipes do Miguel quando ele joga

func _init(n := 2, seed_value := 731, move_set: Dictionary = {}) -> void:
	moves = move_set
	count = n
	seed = seed_value
	reset()

func random() -> float:
	rng = (rng * 1664525 + 1013904223) & 0xFFFFFFFF
	return float(rng) / 4294967296.0

static func enemy(id: int, x: float, y := 146.0) -> Dictionary:
	return {"id": id, "x": x, "y": y, "facing": -1, "state": "idle", "parts": PARTS.duplicate(), "vx": 0.0, "stun": 0.0, "timer": 0.0, "reaction": 0.0, "zone": null,
		"lowered": false, "unbalance": 0.0, "hits": 0, "guard": false, "ragdoll": null, "recoveryFrom": null, "recovery": 0.0, "knockedOut": false, "aiTimer": 700.0 + id * 180}

func reset() -> void:
	rng = seed & 0xFFFFFFFF
	player = {"x": 76.0, "y": 146.0, "facing": 1, "vx": 0.0, "vy": 0.0, "state": "idle", "elapsed": 0.0, "distance": 0.0, "gaitDistance": 0.0, "visualOffsetX": 0.0,
		"move": null, "travel": 0.0, "hit": false, "confirmed": false, "hp": 5, "stamina": 100.0, "chainCount": 0, "invulnerable": 0.0, "guard": false, "grip": 0.0,
		"knees": 0, "strikes": 0, "grabbed": null, "wasRunning": false, "handBlood": {"left": 0, "right": 0}, "idleTime": 0.0, "parryUntil": 0.0, "counterUntil": 0.0,
		"clinchDistance": 0.0, "runDistance": 0.0, "walkDistance": 0.0, "runStart": 0.0, "actionAt": -1000.0, "linkFrom": null, "releaseId": null, "queuedClinch": null,
		"queuedKnee": false, "grabUntil": 0.0, "fallTrigger": 0.0, "previousTip": null, "sweptBox": null, "activeHand": "right", "exhaustedAttack": false, "runMomentum": 0.0,
		"recoverFrom": null, "recoverDuration": 0.0, "counterQueued": null, "counterTarget": null, "parryArm": "right", "groundId": null, "clinchWalking": false,
		"grabAnchor": null, "fallHeight": 0.0, "fallVy": 0.0, "fallVx": 0.0, "whiffMove": null, "wipeStart": null}
	enemies = []
	for i in count:
		var e := enemy(i + 1, 230 + i * 240)
		e.mass = 0.94 + random() * 0.12
		e.balanceLimit = 44 + random() * 10
		e.downTime = 1400 + random() * 400
		e.dead = false
		e.attackArm = "left" if i % 2 else "right"
		enemies.append(e)
	clock = 0.0; hitstop = 0.0; attack_id = 0; buffer = null; last_hit = null; advantage = null; carry = null; guard_held = false; parry_ready = 0.0; last_event = null; event_id = 0
	combo = {"hits": 0, "best": 0, "ttl": 0.0}
	message = "Acerte, acompanhe e escolha a próxima abertura."

func event(type: String, extra := {}) -> void:
	event_id += 1
	last_event = {"id": event_id, "type": type, "at": clock}
	last_event.merge(extra, true)

static func hypot(a: float, b: float) -> float: return sqrt(a * a + b * b)
static func overlap(a: Dictionary, b: Dictionary) -> bool:
	return a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y
static func approach(v: float, t: float, a: float) -> float: return v + clampf(t - v, -a, a)

func nearest() -> Variant:
	var best: Variant = null
	var bd := INF
	for d in enemies:
		if d.dead: continue
		var dist := hypot(d.x - player.x, d.y - player.y)
		if dist < bd: bd = dist; best = d
	return best

func set_mode(m: String) -> void:
	mode = m
	for d in enemies: d.guard = false

func pose(d: Dictionary) -> Array:
	if d.state == "fallen": return d.ragdoll.nodes
	var x: float = d.x
	var y: float = d.y
	var f: int = d.facing
	var down: bool = d.state == "bodyDown" or d.parts.body == 0
	var fold: bool = d.lowered or down or d.state == "clinch"
	var n: Array = []
	for o in [[0, -61], [0, -51], [0, -28], [-10, -40], [-14, -28], [10, -40], [14, -28], [-5, -14], [-8, 0], [5, -14], [8, 0]]:
		n.append({"x": x + o[0], "y": y + o[1]})
	if fold:
		n[0].y += 21 if down else 14; n[0].x += f * 7; n[1].y += 16 if down else 10; n[1].x += f * 4; n[2].y += 5 if down else 1
	if d.zone == "head" and d.reaction > 0:
		n[0].x -= f * 5 * d.reaction / 260.0; n[0].y += 2
	if d.guard:
		n[3] = {"x": x + f * 9, "y": y - 36}; n[4] = {"x": x + f * 13, "y": y - 51}; n[5] = {"x": x + f * 5, "y": y - 35}; n[6] = {"x": x + f * 14, "y": y - 40}
	if d.parts.arms == 0:
		n[4] = {"x": x - 10, "y": y - 15}; n[6] = {"x": x + 10, "y": y - 15}
	if down:
		n[4] = {"x": x - 3, "y": y - 23}; n[6] = {"x": x + 3, "y": y - 25}
	if d.state == "clinch":
		n[0] = {"x": x + f * 5, "y": y - 37}; n[1] = {"x": x + f * 4, "y": y - 33}
	if d.state == "recovering" and d.recoveryFrom != null:
		var t := clampf(d.recovery / 460.0, 0, 1)
		var q := t * t * (3 - 2 * t)
		var out: Array = []
		for i in n.size():
			out.append({"x": d.recoveryFrom[i].x + (n[i].x - d.recoveryFrom[i].x) * q, "y": d.recoveryFrom[i].y + (n[i].y - d.recoveryFrom[i].y) * q})
		return out
	var ref := CM.enemy_ref(d)
	var clip: Variant = art_clips.get(ref.clip)
	var art: Variant = clip.frames[ref.frame].get("pose") if clip != null and ref.frame < clip.frames.size() else null
	if art != null:
		for i in 3: n[i] = {"x": x - art[i].x * f, "y": y + art[i].y}
	return n

func hurtboxes(d: Dictionary) -> Dictionary:
	var n := pose(d)
	var h: Dictionary = ground_head(d) if d.state == "fallen" else n[0]
	return {"head": {"x": h.x - 6, "y": h.y - 6, "w": 12.0, "h": 12.0},
		"body": {"x": minf(n[1].x, n[2].x) - 9, "y": minf(n[1].y, n[2].y), "w": 18 + absf(n[1].x - n[2].x), "h": maxf(12, absf(n[1].y - n[2].y) + 4)},
		"legs": {"x": d.x - 10, "y": d.y - 21, "w": 20.0, "h": 21.0}}

func ground_head(d: Dictionary) -> Dictionary:
	var th: Variant = art_clips.get("targetHead")
	var art: Variant = th.frames[4].get("pose") if th != null and th.frames.size() > 4 else null
	if art != null and d.ragdoll != null and d.ragdoll.age >= 230:
		return {"x": d.x - art[0].x * d.facing, "y": minf(d.y, d.ragdoll.nodes[2].y + 4) + art[0].y}
	return d.ragdoll.nodes[0] if d.ragdoll != null else {"x": d.x, "y": d.y - 6}

func ground_target() -> Variant:
	var best: Variant = null
	var bd := INF
	for d in enemies:
		if d.state != "fallen" or d.dead or d.ragdoll.age <= 450 or absf(d.y - player.y) > 8: continue
		var head := ground_head(d)
		if absf(head.x - player.x) < 46 and head.y > player.y - 16 and absf(head.x - player.x) < bd:
			bd = absf(head.x - player.x); best = d
	return best

func body(x: float = NAN, y: float = NAN) -> Dictionary:
	if is_nan(x): x = player.x
	if is_nan(y): y = player.y
	return {"x": x - 6, "y": y - 7, "w": 12.0, "h": 9.0}

func move(dx: float, dy := 0.0) -> void:
	var p := player
	var nx := clampf(p.x + dx, LIMITS.minX, LIMITS.maxX)
	var ny := clampf(p.y + dy, LIMITS.minY, LIMITS.maxY)
	for d in enemies:
		if d.state in ["fallen", "recovering", "clinch", "carried", "bodyDown"]: continue
		var b := {"x": d.x - 7, "y": d.y - 7, "w": 14.0, "h": 9.0}
		var inside := overlap(body(), b)
		if overlap(body(nx, p.y), b) and not (inside and absf(nx - d.x) > absf(p.x - d.x)): nx = p.x
		if overlap(body(nx, ny), b) and not (inside and absf(ny - d.y) > absf(p.y - d.y)): ny = p.y
	p.distance += hypot(nx - p.x, ny - p.y)
	p.x = nx; p.y = ny

func move_pair(d: Dictionary, dx: float, dy := 0.0) -> float:
	var p := player
	var x: float = p.x
	var y: float = p.y
	dx = clampf(dx, maxf(LIMITS.minX - p.x, LIMITS.minX - d.x), minf(LIMITS.maxX - p.x, LIMITS.maxX - d.x))
	dy = clampf(dy, maxf(LIMITS.minY - p.y, LIMITS.minY - d.y), minf(LIMITS.maxY - p.y, LIMITS.maxY - d.y))
	for e in enemies:
		if e.id == d.id or e.state in ["fallen", "recovering"]: continue
		var b := {"x": e.x - 7, "y": e.y - 7, "w": 14.0, "h": 9.0}
		if overlap(body(d.x + dx, d.y + dy), b): return 0.0
	move(dx, dy)
	d.x += p.x - x; d.y += p.y - y
	return hypot(p.x - x, p.y - y)

func attack_box() -> Variant:
	var p := player
	var m: Variant = moves.get(p.move) if p.move != null else null
	if not (p.state in ["attack", "knee"]) or m == null or not m.active.has(CM.frame_at(p.elapsed, m)): return null
	var f := CM.frame_at(p.elapsed, m)
	var clip_id: String = m.clip
	var index := f
	if m.has("sequence"):
		clip_id = m.sequence[f][0]; index = int(m.sequence[f][1])
	var clips: Dictionary = player_clips if player_clips != null else art_clips
	var c: Variant = clips.get(clip_id)
	var art: Variant = c.frames[index] if c != null and index < c.frames.size() else null
	var kick: bool = p.move in CM.KICKS or p.move == "groundStomp"
	var tip: Variant = null
	if not (m.get("ground", false) or p.move == "knee") and art != null:
		tip = art.get("foot") if kick else art.get("fist")
	var w: float = m.size[0]
	var h: float = m.size[1]
	var x: float = tip.x if tip != null else m.point[0]
	var y: float = tip.y if tip != null else m.point[1]
	return {"x": p.x + p.facing * x - w / 2.0, "y": p.y + y - h / 2.0, "w": w, "h": h}

func choose(input: Dictionary) -> String:
	var n := choose_raw(input)
	var f: Variant = fallback.get(n)
	return n if moves.has(n) or f == null or not moves.has(f) else f

func choose_raw(input: Dictionary) -> String:
	var p := player
	var dir := int(bool(input.get("right", false))) - int(bool(input.get("left", false)))
	var recent: bool = p.state == "attack" or clock - float(p.actionAt) < 620
	var ground: Variant = null
	if ((input.get("down", false) and input.get("kick", false)) or input.get("attack", false) or (input.get("run", false) and input.get("kick", false))) and moves.has("groundPunch"):
		ground = ground_target()
	if ground != null:
		p.facing = 1 if ground_head(ground).x >= p.x else -1
		p.groundId = ground.id
		return ("groundStomp" if input.get("run", false) else "groundKick") if input.get("kick", false) else "groundPunch"
	if p.counterUntil > clock and input.get("attack", false):
		var d: Variant = null
		for e in enemies:
			if e.id == p.counterTarget: d = e
		if d != null and not d.knockedOut and absf(d.x - p.x) < 52 and absf(d.y - p.y) < 9:
			p.facing = 1 if d.x > p.x else -1
			p.counterUntil = 0.0
			if input.get("down", false): return "counterBodyLeft" if p.parryArm == "right" else "counterBody"
			return "counterLeft" if p.parryArm == "right" else "counterStraight"
	if input.get("up", false) and input.get("attack", false) and moves.has("jabHead"): return "jabHead"
	if input.get("up", false) and input.get("kick", false) and moves.has("highKick"): return "highKick"
	if input.get("down", false) and input.get("run", false) and input.get("attack", false) and moves.has("crossBody"): return "crossBody"
	if input.get("kick", false) and input.get("down", false): return "lowKick"
	if input.get("kick", false): return "comboKick" if recent and p.move in CM.PUNCHES else "kick"
	if input.get("run", false) and hypot(p.vx, p.vy) > 60: return "rush"
	if input.get("down", false): return "low"
	if dir == -p.facing: return "reverse"
	if dir == p.facing or input.get("run", false): return "drive"
	if recent and p.move in CM.KICKS: return "stepPunch"
	var a: Variant = advantage
	if a != null and clock - a.at < 750 and a.target.parts.head > 0:
		return "cross" if a.zone == "body" else ("drive" if a.zone == "head" else "jab")
	return "jab"

func begin(name: String) -> bool:
	var p := player
	var m: Variant = moves.get(name)
	if m == null or p.stamina < m.cost:
		buffer = null
		message = "Sem fôlego: recupere a base." if m != null else "Golpe ainda sem desenho."
		return false
	var chaining: bool = p.state == "attack"
	p.chainCount = 0 if m.get("clinch", false) else (p.chainCount + 1 if chaining else 1)
	p.stamina -= m.cost
	p.exhaustedAttack = p.stamina <= CM.FATIGUE.exhaustedBelow
	p.runMomentum = hypot(p.vx, p.vy)
	if name == "reverse": p.facing *= -1
	if m.get("clinch", false):
		for e in enemies:
			if e.id == p.grabbed: e.clinchMove = name; e.clinchProgress = 0.0
	p.linkFrom = p.move; p.actionAt = clock; p.releaseId = null; p.queuedClinch = null; p.queuedKnee = false
	p.state = "knee" if m.get("clinch", false) else "attack"
	p.move = name; p.elapsed = 0.0; p.travel = 0.0; p.hit = false; p.confirmed = false; p.grabUntil = 0.0; p.fallTrigger = 0.0; p.idleTime = 0.0
	p.vx *= 1.0 if m.get("rush", false) else 0.3
	p.vy = 0.0; p.guard = false; p.previousTip = null; p.sweptBox = null
	p.activeHand = "left" if name in ["cross", "crossBody", "counterLeft", "counterBodyLeft"] else "right"
	buffer = null
	attack_id += 1
	return true

func hurt(direction: float = NAN) -> bool:
	var p := player
	if is_nan(direction): direction = -p.facing
	if p.invulnerable > 0 or p.hp <= 0: return false
	end_carry(true); release(false); p.hp -= 1; p.invulnerable = 850.0; p.counterUntil = 0.0; p.parryUntil = 0.0
	if p.state in ["rushFall", "gettingUp"]: return true
	p.state = "hurt"; p.elapsed = 0.0; p.vx = direction * 40; buffer = null; advantage = null; event("hurt")
	return true

func launch(d: Dictionary, zone: String, point: Dictionary, knock := 80.0, lift := 85.0) -> void:
	var ps := pose(d)
	d.ragdoll = Ragdoll.new(d.x, d.y, player.facing, knock, lift, ps)
	d.ragdoll.impulse_at(point, player.facing, 35, 15)
	d.state = "fallen"; d.downKind = zone; d.timer = d.downTime; d.guard = false; d.lowered = false; d.vx = 0.0

func start_player_fall() -> void:
	var p := player
	end_carry()
	p.state = "rushFall"; p.elapsed = 0.0; p.fallHeight = 8.0; p.fallVy = 42.0; p.fallVx = p.facing * maxf(45, p.runMomentum * 0.72); p.visualOffsetX = 0.0
	buffer = null; advantage = null
	message = "O impulso levou os dois. Recupere o apoio." if p.confirmed else "Sorriso perdeu o equilíbrio. Recupere o apoio."

func stain(m: Dictionary) -> void:
	var p := player
	if p.move != "knee" and p.move != "clinchElbow" and not (p.move in CM.KICKS) and not m.get("ground", false):
		var k: String = p.activeHand if p.activeHand else "right"
		p.handBlood[k] = mini(4, p.handBlood[k] + 1)

func damage(d: Dictionary, m: Dictionary, zone: String, point: Dictionary, blocked := false) -> void:
	var p := player
	p.hit = true; p.confirmed = not blocked; d.hits += 1; d.zone = "arms" if blocked else zone; d.reaction = 260.0
	var amount: float = 12.0 if blocked else float(m.damage)
	var part := "arms" if blocked else zone
	d.parts[part] = maxf(0.0, d.parts[part] - amount)
	hitstop = 12.0 if blocked else float(m.pause)
	last_hit = {"id": attack_id, "move": p.move, "target": d.id, "zone": d.zone, "blocked": blocked, "point": point.duplicate(), "damage": amount, "at": clock, "blood": not blocked and amount >= 9}
	event("block" if blocked else "hit", {"heavy": m.get("heavy", false)})
	if blocked:
		advantage = null; combo.hits = 0; d.vx = 0.0
		if d.parts.arms == 0:
			d.guard = false; d.state = "guardBreak"; d.stun = 700.0; message = "Guarda rompida. Os braços cederam."
		else:
			message = "Defendido: desgaste nos braços, corpo sem recuo."
		return
	stain(m)
	d.guard = false; d.stun = float(m.stun); d.lowered = zone != "legs"
	d.state = "headStagger" if zone == "head" else ("legStagger" if zone == "legs" else "bodyStagger")
	d.unbalance += m.unbalance
	combo.hits = combo.hits + 1 if combo.ttl > 0 else 1
	combo.best = maxi(combo.best, combo.hits); combo.ttl = 1050.0
	advantage = {"target": d, "zone": zone, "at": clock}
	if m.get("clinch", false):
		d.state = "clinch"; return
	if m.has("carry") and d.parts.legs > 0:
		d.vx = 0.0; d.state = "carried"
		carry = {"target": d.id, "move": p.move, "zone": zone, "point": point.duplicate(), "elapsed": 0.0, "travel": 0.0, "distance": m.carry.distance / d.get("mass", 1.0), "duration": float(m.carry.time), "direction": p.facing}
		message = "Contato firme: o corpo acompanha o golpe."
		return
	finish_impact(d, m, zone, point)

func finish_impact(d: Dictionary, m: Dictionary, zone: String, point: Dictionary) -> void:
	var p := player
	d.state = "headStagger" if zone == "head" else ("legStagger" if zone == "legs" else "bodyStagger")
	d.vx = p.facing * float(m.knock) / d.get("mass", 1.0)
	if zone == "legs":
		message = "Perna atingida: o apoio está cedendo."
		if d.parts.legs == 0:
			launch(d, "legs", point, 32, 15); message = "A perna cedeu."
		return
	if m.get("rush", false):
		if d.parts.head == 0: d.knockedOut = true
		launch(d, zone, point, maxf(105, p.runMomentum * 1.3), 45); p.fallTrigger = p.elapsed + 10
		return
	if d.parts.head == 0:
		d.knockedOut = true; launch(d, "head", point, 75, 55); message = "Cabeça esgotada: desmaio."; return
	if d.parts.body == 0:
		d.state = "bodyDown"; d.lowered = true; d.stun = 0.0; d.vx *= 0.4; message = "O tronco cedeu."
	else:
		message = "Corpo aberto. Acompanhe e procure a cabeça." if zone == "body" else "Cabeça atingida. Procure outra abertura."
	if m.get("finish", false) and d.unbalance >= d.balanceLimit: launch(d, zone, point, m.knock * 0.75, 80)

func enemy_by_id(id: Variant) -> Variant:
	for e in enemies:
		if e.id == id: return e
	return null

func update_carry(dt: float) -> bool:
	var c: Variant = carry
	if c == null: return false
	var d: Variant = enemy_by_id(c.target)
	if d == null or d.dead or player.state != "attack":
		end_carry(true); return false
	c.elapsed += dt
	var t := clampf(c.elapsed / c.duration, 0, 1)
	var travel: float = c.distance * (1 - (1 - t) * (1 - t))
	var dx: float = (travel - c.travel) * c.direction
	c.travel = travel
	var moved := move_pair(d, dx)
	d.facing = -c.direction
	if t >= 1 or (absf(dx) > 0.02 and moved < 0.001): end_carry()
	return true

func end_carry(interrupted := false) -> void:
	var c: Variant = carry
	if c == null: return
	carry = null
	var d: Variant = enemy_by_id(c.target)
	if d == null or d.dead: return
	if interrupted:
		if d.parts.head == 0:
			d.knockedOut = true; launch(d, "head", pose(d)[0], 18, 10)
		else:
			d.state = "bodyStagger"; d.stun = 220.0; d.vx = 0.0
	else:
		finish_impact(d, moves[c.move], c.zone, {"x": d.x, "y": d.y + (c.point.y - player.y)})

func finish_ground(d: Dictionary, m: Dictionary) -> void:
	var p := player
	var h := ground_head(d)
	d.dead = true; d.knockedOut = true; d.parts.head = 0.0; d.timer = INF
	d.ragdoll.impulse_at(h, p.facing, 12, 0)
	p.hit = true; p.confirmed = true; hitstop = float(m.pause)
	last_hit = {"id": attack_id, "move": p.move, "target": d.id, "zone": "head", "point": h.duplicate(), "damage": m.damage, "blocked": false, "blood": true, "finisher": true, "at": clock}
	if p.move == "groundPunch": p.handBlood.right = mini(4, p.handBlood.right + 2)
	event("hit", {"heavy": true})
	message = "Finalizado. R reinicia o treino."

func contact() -> void:
	var box: Variant = attack_box()
	var p := player
	if p.hit: return
	var m: Variant = moves.get(p.move) if p.move != null else null
	if box == null:
		if m != null: p.previousTip = {"x": p.x + p.facing * 6, "y": p.y + m.point[1]}
		return
	var tip := {"x": box.x + box.w / 2.0, "y": box.y + box.h / 2.0}
	var old: Dictionary = p.previousTip if p.previousTip != null else tip
	box = {"x": minf(old.x, tip.x) - box.w / 2.0, "y": minf(old.y, tip.y) - box.h / 2.0, "w": absf(tip.x - old.x) + box.w, "h": absf(tip.y - old.y) + box.h}
	p.sweptBox = box; p.previousTip = tip
	if m.get("ground", false):
		var d: Variant = enemy_by_id(p.groundId)
		if d == null: d = ground_target()
		if d == null or d.dead or d.state != "fallen" or d.ragdoll.age < 450 or absf(d.y - p.y) > 8: return
		var h := ground_head(d)
		if overlap(box, {"x": h.x - 6, "y": h.y - 6, "w": 12.0, "h": 12.0}): finish_ground(d, m)
		return
	var order := enemies.duplicate()
	order.sort_custom(func(a, b): return absf(a.x - p.x) < absf(b.x - p.x))
	for d in order:
		if d.knockedOut or d.state in ["fallen", "recovering", "carried", "clinch"] or absf(d.y - p.y) > 8: continue
		var hb := hurtboxes(d)
		var hits: Array = []
		for zone in ["head", "body", "legs"]:
			var b: Dictionary = hb[zone]
			if (not m.has("zone") or m.zone == zone) and overlap(box, b):
				var x := maxf(box.x, b.x)
				var y := maxf(box.y, b.y)
				var w := minf(box.x + box.w, b.x + b.w) - x
				var h2 := minf(box.y + box.h, b.y + b.h) - y
				hits.append({"zone": zone, "area": w * h2, "point": {"x": x + w / 2.0, "y": y + h2 / 2.0}})
		hits.sort_custom(func(a, b): return a.area > b.area)
		var front: bool = (p.x - d.x) * d.facing > 0
		var guard_box := {"x": d.x + d.facing * 11 - 5, "y": d.y - 53, "w": 10.0, "h": 33.0}
		if d.guard and front and m.get("zone") != "legs" and (overlap(box, guard_box) or not hits.is_empty()):
			damage(d, m, "arms", {"x": guard_box.x + guard_box.w / 2.0, "y": box.y + box.h / 2.0}, true); return
		if not hits.is_empty():
			damage(d, m, hits[0].zone, hits[0].point); return

func grab() -> void:
	if not can.grab: return
	var p := player
	if p.state in ["clinchEntry", "clinch", "knee"]:
		release(); return
	if p.state == "attack":
		p.grabUntil = maxf(moves[p.move].chain, p.elapsed) + 260; message = "Agarrão preparado após o golpe."; return
	if not (p.state in ["idle", "walk", "run", "brake", "guard"]): return
	var d: Variant = nearest()
	if d == null or d.knockedOut or d.state in ["fallen", "recovering", "carried"] or absf(d.x - p.x) > 30 or absf(d.y - p.y) > 8:
		message = "Aproxime-se para agarrar."; return
	if d.guard: d.parts.arms = maxf(0.0, d.parts.arms - CLINCH.guardDamage)
	p.facing = 1 if d.x >= p.x else -1
	p.grabAnchor = (p.x + d.x - p.facing * 28) / 2.0
	p.grabbed = d.id; p.grip = CLINCH.grip; p.knees = 0; p.strikes = 0; p.queuedClinch = null; p.state = "clinchEntry"; p.elapsed = 0.0; p.vx = 0.0; p.vy = 0.0; p.guard = false; p.idleTime = 0.0
	d.state = "clinch"; d.guard = false; d.vx = 0.0; d.lowered = true; d.stun = 0.0
	buffer = null
	message = "J soco · baixo+J cotovelo · K joelho · Shift+J derruba."

func release(recover := true) -> void:
	var p := player
	var d: Variant = enemy_by_id(p.grabbed)
	p.releaseId = null
	if d != null and d.state == "clinch":
		d.state = "bodyDown" if d.parts.body == 0 else "bodyStagger"; d.stun = 450.0
	p.grabbed = null; p.grip = 0.0; p.queuedClinch = null; p.queuedKnee = false
	if recover and p.state in ["clinchEntry", "clinch", "knee"]:
		p.state = "recover"; p.elapsed = 0.0

func tick_clinch(input: Dictionary, dt: float) -> void:
	var p := player
	var d: Variant = enemy_by_id(p.grabbed)
	var s := dt / 1000.0
	if d == null:
		release(); return
	p.grip -= dt
	if p.grip <= 0:
		message = "O clinch escapou."; release(); return
	if p.state == "clinchEntry":
		if p.grabAnchor != null: p.x += clampf(p.grabAnchor - p.x, -28 * s, 28 * s)
		if p.elapsed >= CLINCH.entry:
			p.state = "clinch"; p.elapsed = 0.0
			var next: Variant = p.queuedClinch
			p.queuedClinch = null
			if next != null: begin(next)
		return
	if p.state == "clinch":
		if input.get("attack", false) or input.get("kick", false):
			if not begin(CM.clinch_choice(input)): release()
			return
		var dx := int(bool(input.get("right", false))) - int(bool(input.get("left", false)))
		var dy := int(bool(input.get("down", false))) - int(bool(input.get("up", false)))
		var length := hypot(dx, dy)
		if length == 0: length = 1.0
		var speed: float = 21.0 / d.get("mass", 1.0)
		p.clinchWalking = dx != 0 or dy != 0
		if p.clinchWalking:
			var moved := move_pair(d, dx / length * speed * s, dy / length * speed * s * 0.65)
			p.clinchDistance += moved; p.grip -= dt * 0.25
			p.stamina = maxf(0.0, p.stamina - s * CM.FATIGUE.dragPerSecond)
			if p.stamina == 0: release()
		return
	p.clinchWalking = false
	var m: Dictionary = moves[p.move]
	d.clinchProgress = p.elapsed
	if not p.hit and m.active.has(CM.frame_at(p.elapsed, m)):
		var zone: String = m.get("zone", "body")
		var box: Variant = attack_box()
		var target: Dictionary = hurtboxes(d)[zone]
		if box == null or not overlap(box, target): return
		var point := {"x": clampf(box.x + box.w / 2.0, target.x, target.x + target.w), "y": clampf(box.y + box.h / 2.0, target.y, target.y + target.h)}
		damage(d, m, zone, point); p.strikes += 1
		if p.move == "knee": p.knees += 1
		p.grip = minf(CLINCH.maxGrip, p.grip + CLINCH.refresh); d.vx = 0.0
		if m.get("release", false) or d.parts.head == 0 or d.parts.body == 0:
			if d.parts.head == 0: d.knockedOut = true
			launch(d, zone, point, 92 if m.get("release", false) else 55, 45); release(false); p.state = "attack"; p.recoverFrom = p.move
			message = "Pegada solta no impacto: o alvo perdeu a base." if m.get("release", false) else "O alvo cedeu."
			return
		d.state = "clinch"; message = m.name + ". Escolha o próximo golpe."
	if p.elapsed >= m.duration:
		var nxt: Variant = p.queuedClinch
		p.queuedClinch = null; d.clinchMove = null
		if nxt != null:
			if not begin(nxt): release()
		else:
			p.state = "clinch"; p.elapsed = 0.0

func enemy_attack(d: Dictionary) -> void:
	var p := player
	if d.parts.arms <= 0 or absf(d.x - p.x) >= 36 or absf(d.y - p.y) >= 9: return
	if p.guard and (d.x - p.x) * p.facing > 0:
		if clock <= p.parryUntil:
			p.state = "parry"; p.elapsed = 0.0; p.parryArm = "left" if d.attackArm == "right" else "right"; p.counterTarget = d.id; p.counterUntil = clock + CM.PARRY.opening; p.parryUntil = 0.0
			d.state = "parried"; d.stun = 620.0; d.guard = false; hitstop = 42.0; event("parry"); message = "Aparo! J responde; baixo+J procura o corpo."
		else:
			message = "Defesa firme. Solte e aperte L no instante do contato para aparar."; hitstop = 12.0; event("block")
	else:
		hurt(d.facing)

func update_enemy(d: Dictionary, dt: float) -> void:
	var p := player
	var s := dt / 1000.0
	d.reaction = maxf(0.0, d.reaction - dt); d.stun = maxf(0.0, d.stun - dt); d.unbalance = maxf(0.0, d.unbalance - s * 5)
	if d.dead:
		d.ragdoll.step(dt); d.x = d.ragdoll.center().x; return
	if d.parts.body == 0: d.bodyDownAge = d.get("bodyDownAge", 0.0) + dt
	if d.state == "carried": return
	if d.state == "clinch":
		var q := 1 - exp(-dt / 55.0)
		d.x += (clampf(p.x + p.facing * 28, 16, 624) - d.x) * q; d.y += (p.y - d.y) * q; d.facing = -p.facing; return
	if d.state == "fallen":
		d.ragdoll.step(dt); d.x = d.ragdoll.center().x; d.timer -= dt
		if d.timer <= 0 and not d.knockedOut and d.parts.legs > 0:
			var copy: Array = []
			for n in d.ragdoll.nodes: copy.append(n.duplicate())
			d.recoveryFrom = copy; d.state = "recovering"; d.recovery = 0.0
		return
	if d.state == "recovering":
		d.recovery += dt
		if d.recovery >= 460:
			d.state = "bodyDown" if d.parts.body == 0 else ("legDown" if d.parts.legs == 0 else "idle")
			d.lowered = d.parts.body == 0; d.ragdoll = null; d.recoveryFrom = null; d.stun = 0.0
		return
	d.x = clampf(d.x + d.vx * s, 16, 624); d.vx *= exp(-8 * s)
	if d.state == "enemyWindup":
		d.timer -= dt
		if d.timer <= 0:
			enemy_attack(d)
			if d.state != "parried": d.state = "idle"
			d.attackArm = "right" if d.attackArm == "left" else "left"
			d.aiTimer = 900 + random() * 550
		return
	if d.parts.body == 0:
		d.state = "bodyDown"; d.guard = false; return
	if d.parts.legs == 0:
		d.state = "legDown"; d.guard = false; return
	if d.stun > 0:
		d.guard = false; return
	d.state = "idle"; d.lowered = false; d.facing = -1 if p.x < d.x else 1
	d.guard = mode == "guard" and d.parts.arms > 0
	if mode == "sparring" and d.parts.arms > 0 and p.hp > 0:
		d.aiTimer -= dt; d.guard = d.aiTimer > 450
		if d.aiTimer <= 0 and absf(d.x - p.x) < 48 and absf(d.y - p.y) < 9:
			d.guard = false; d.state = "enemyWindup"; d.timer = 320 + random() * 130 + (1 - d.parts.legs / 60.0) * 180

## O jogo chama a 60 Hz; a regra roda em passos de até 1/120 s.
func step(input: Dictionary, ms: float) -> void:
	var remaining := clampf(ms, 0, 100)
	var first := true
	while remaining > 1e-6:
		var dt := minf(1000.0 / 120.0, remaining)
		var inp := input if first else _no_pulse(input)
		tick(inp, dt)
		remaining -= dt
		first = false

static func _no_pulse(input: Dictionary) -> Dictionary:
	var out := input.duplicate()
	out.attack = false; out.kick = false; out.grab = false
	return out

func update_gait(dx: float, dy: float, dt: float) -> void:
	var p := player
	var moving := hypot(dx, dy)
	p.gaitDistance += moving
	if p.state == "run": p.runDistance += moving
	else: p.walkDistance += moving
	var clips: Dictionary = player_clips if player_clips != null else art_clips
	if clips.has("r2_run") and p.state == "run" and p.runStart < 280: p.runDistance = 0.0
	p.visualOffsetX = p.visualOffsetX * exp(-dt / 55.0)

func tick(input: Dictionary, dt: float) -> void:
	var p := player
	var s := dt / 1000.0
	clock += dt
	var pulse: bool = input.get("attack", false) or input.get("kick", false)
	var guard_press: bool = input.get("guard", false) and not guard_held
	guard_held = bool(input.get("guard", false))
	if guard_press and clock >= parry_ready and p.state in ["idle", "walk", "run", "brake", "guard", "wipe"]:
		p.parryUntil = clock + CM.PARRY.window; parry_ready = clock + CM.PARRY.rearm; p.guard = true; p.state = "guard"; p.elapsed = 0.0
	if pulse and p.state == "attack" and buffer == null:
		var m: Dictionary = moves[p.move]
		var mixed: bool = (input.get("kick", false) and p.move in CM.PUNCHES) or (input.get("attack", false) and p.move in CM.KICKS)
		if CM.can_link(m, p, mixed) and (mixed or p.elapsed >= float(m.times[0])):
			buffer = {"move": choose(input), "until": maxf(m.linkAt, p.elapsed) + 180, "mixed": mixed}
	if pulse and (p.state == "clinchEntry" or (p.state == "knee" and p.hit)) and p.queuedClinch == null: p.queuedClinch = CM.clinch_choice(input)
	if pulse and p.state == "parry" and p.counterQueued == null:
		p.counterQueued = {"attack": input.get("attack", false), "kick": input.get("kick", false), "down": input.get("down", false)}
	if buffer != null and buffer.until < p.elapsed: buffer = null
	if input.get("grab", false) and p.state == "attack":
		grab(); input = input.duplicate(); input.grab = false
	if hitstop > 0:
		hitstop = maxf(0.0, hitstop - dt); return
	for d in enemies: update_enemy(d, dt)
	p.elapsed += dt; p.invulnerable = maxf(0.0, p.invulnerable - dt); combo.ttl = maxf(0.0, combo.ttl - dt)
	if combo.ttl == 0: combo.hits = 0
	if p.state in ["idle", "walk", "guard", "winded", "wipe"]: p.stamina = minf(100.0, p.stamina + s * CM.FATIGUE.restPerSecond)
	elif p.state == "attackRecover": p.stamina = minf(100.0, p.stamina + s * CM.FATIGUE.recoverPerSecond)
	elif p.state == "run": p.stamina = maxf(0.0, p.stamina - s * CM.FATIGUE.runPerSecond)
	if p.hp <= 0:
		p.state = "hurt"; end_carry(true); return
	if input.get("grab", false): grab()
	if p.state in ["clinchEntry", "clinch", "knee"]:
		tick_clinch(input, dt); return
	if p.state == "parry":
		if p.elapsed < 90: return
		var next: Variant = p.counterQueued
		p.counterQueued = null
		p.state = "guard" if input.get("guard", false) else "idle"; p.elapsed = 0.0
		if next != null:
			begin(choose(next)); return
	if p.state == "rushFall":
		p.x = clampf(p.x + p.fallVx * s, LIMITS.minX, LIMITS.maxX); p.fallVx *= exp(-2.6 * s); p.fallVy -= 470 * s
		p.fallHeight = maxf(0.0, p.fallHeight + p.fallVy * s)
		if p.fallHeight == 0: p.fallVy = 0.0
		if p.elapsed >= 760:
			p.state = "gettingUp"; p.elapsed = 0.0; p.fallHeight = 0.0
		return
	if p.state in ["gettingUp", "attackRecover", "winded"]:
		p.vx = approach(p.vx, 0, 240 * s)
		var limit: float = 420.0 if p.state == "gettingUp" else (550.0 if p.state == "winded" else (p.recoverDuration if p.recoverDuration else 180.0))
		if p.elapsed > limit:
			p.state = "idle"; p.elapsed = 0.0; p.chainCount = 0
		return
	if p.state in ["hurt", "stumble", "recover"]:
		p.vx = approach(p.vx, 0, (100.0 if p.state == "stumble" else 200.0) * s); move(p.vx * s)
		if p.elapsed > {"hurt": 360.0, "stumble": 330.0, "recover": 220.0}[p.state]:
			p.state = "idle"; p.elapsed = 0.0
		return
	if p.state == "attack":
		var m2: Dictionary = moves[p.move]
		if carry != null:
			p.elapsed -= dt; update_carry(dt); return
		var lunge_until: float = m2.lungeUntil if m2.get("lungeUntil") else float(m2.times[0]) + float(m2.times[1])
		var t := clampf(p.elapsed / lunge_until, 0, 1)
		var travel: float = m2.lunge * t * t * (3 - 2 * t)
		move((travel - p.travel) * p.facing); p.travel = travel
		if m2.get("rush", false):
			move(p.vx * s); p.vx = approach(p.vx, 0, 60 * s)
		contact()
		if carry != null: return
		if m2.get("rush", false) and p.confirmed and p.fallTrigger and p.elapsed >= p.fallTrigger:
			start_player_fall(); return
		if p.grabUntil >= p.elapsed and p.elapsed >= m2.chain:
			p.grabUntil = 0.0; p.state = "idle"; grab(); return
		if buffer != null and CM.can_link(m2, p, buffer.mixed) and p.elapsed >= (m2.linkAt if buffer.mixed else m2.chain):
			if begin(buffer.move): return
		if p.elapsed < m2.duration: return
		if not p.hit and p.exhaustedAttack:
			p.state = "stumble"; p.elapsed = 0.0; p.whiffMove = p.move; p.vx = p.facing * (38.0 if m2.get("heavy", false) else 18.0); buffer = null; advantage = null
			message = "Sem fôlego e golpe no vazio: recupere o equilíbrio."; return
		p.state = "attackRecover"; p.recoverFrom = p.move; p.elapsed = 0.0
		p.recoverDuration = 240.0 if p.hit and not p.confirmed else (250.0 if m2.get("heavy", false) else 120.0)
		buffer = null
		return
	var moving: bool = input.get("left", false) or input.get("right", false) or input.get("up", false) or input.get("down", false)
	if p.state == "wipe":
		if pulse or moving or input.get("guard", false) or input.get("grab", false):
			p.state = "idle"; p.elapsed = 0.0; p.idleTime = 0.0
		else:
			if p.elapsed > 460:
				var amount := int(floor((p.elapsed - 460) / 95.0))
				for k in ["left", "right"]: p.handBlood[k] = maxi(0, p.wipeStart[k] - amount)
			if p.elapsed >= 1050:
				p.handBlood = {"left": 0, "right": 0}; p.state = "idle"; p.elapsed = 0.0; p.idleTime = 0.0
			return
	if pulse:
		if not begin(choose(input)):
			p.state = "winded"; p.elapsed = 0.0
		return
	p.guard = bool(input.get("guard", false))
	if p.guard:
		p.vx = approach(p.vx, 0, 400 * s); p.vy = approach(p.vy, 0, 400 * s); move(p.vx * s, p.vy * s); p.state = "guard"; p.idleTime = 0.0; return
	var dx := int(bool(input.get("right", false))) - int(bool(input.get("left", false)))
	var dy := int(bool(input.get("down", false))) - int(bool(input.get("up", false)))
	var length := hypot(dx, dy)
	if length == 0: length = 1.0
	var max_speed := 88.0 if input.get("run", false) and p.stamina > 0 else 49.0
	var before := absf(p.vx)
	if dx == 0 and dy == 0 and p.wasRunning and before > 20 and p.state != "brake":
		p.state = "brake"; p.elapsed = 0.0
	var old_state: String = p.state
	p.vx = approach(p.vx, dx / length * max_speed, (300.0 if dx else 210.0) * s)
	p.vy = approach(p.vy, dy / length * max_speed, (300.0 if dy else 260.0) * s)
	var old_x: float = p.x
	var old_y: float = p.y
	move(p.vx * s, p.vy * s)
	if absf(p.vx) > 10: p.facing = int(signf(p.vx))
	elif dx != 0: p.facing = dx
	if dx != 0 or dy != 0:
		p.state = "run" if input.get("run", false) and can.run and p.stamina > 0 else "walk"
		p.wasRunning = p.state == "run"; p.idleTime = 0.0
		if p.state == "run" and old_state != "run": p.runStart = 0.0
		p.runStart = p.runStart + dt
	elif hypot(p.vx, p.vy) < 2:
		p.state = "idle"; p.wasRunning = false
		if old_state != "idle": p.elapsed = 0.0
		p.idleTime += dt
		if can.wipe and p.idleTime > 2300 and (p.handBlood.left or p.handBlood.right):
			p.state = "wipe"; p.elapsed = 0.0; p.wipeStart = p.handBlood.duplicate()
	elif p.state != "brake":
		p.state = "walk"
	update_gait(p.x - old_x, p.y - old_y, dt)
