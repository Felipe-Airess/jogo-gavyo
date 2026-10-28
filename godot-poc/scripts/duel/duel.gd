extends RefCounted
## Port de src/duel/duel.mjs: duelo lateral 1×1. Os dois lutadores passam pelas
## mesmas funções: entrada → buffer → estado → golpe → contato → dano.
## Tempos em ms, posições em pixels do mundo (pivô no pé). Determinístico.
const Buffer = preload("res://scripts/core/command_buffer.gd")
const Moves = preload("res://scripts/core/moves.gd")
const Damage = preload("res://scripts/core/damage.gd")
const Collision = preload("res://scripts/core/collision.gd")
const Markers = preload("res://scripts/duel/markers.gd")
const Fighter = preload("res://scripts/duel/fighter.gd")
const Clinch = preload("res://scripts/duel/clinch.gd")
const Loco = preload("res://scripts/duel/locomotion.gd")

const RECOIL := {"ms": 90.0, "block": 1.0, "graze": 1.0, "hit": 2.0, "clean": 4.0}
const HEAVY_STUN := 440.0
const AIM_MIN := 0.25
const ELBOW_SLACK := 12.0
const SWEEP_MAX := 45.0
const STAGE := {"minX": 24.0, "maxX": 456.0, "ground": 150.0, "half": 13.0, "strike": 8.0}
const TICK := 1000.0 / 60.0
const HITSTOP := {"block": 50.0, "light": 66.0, "medium": 83.0, "heavy": 116.0}
const PARRY := {"window": 180.0, "stagger": 480.0, "counter": 520.0}
const GROUND := {"reach": 46.0, "extend": 320.0, "maxExtend": 1600.0, "downMs": 700.0, "thrownMs": 1000.0}
const STEP_IN := {"max": 8.0, "forward": 4.0, "margin": 12.0, "bite": 4.0}
const COMBO := {"hitPush": 0.5, "push": 0.35, "scale": [1.0, 1.0, 1.0, 0.85, 0.72]}
const ROCK := {"threshold": 32.0, "decay": 12.0, "ms": 2600.0, "speed": 0.6, "clean": 1.5, "koHead": 45.0}
const DOWN := ["knockdown", "down", "getup", "ko"]
const CLINCH_STATES := ["clinchEntry", "clinch", "clinchStrike", "held"]

var roster := {}        # nome -> {clips, markers}
var moves_by := {}
var reach_by := {}
var gait := {}
var characters := ["sorriso", "sorriso"]
var fighters: Array = []
var clock := 0.0
var hitstop := 0.0
var events: Array = []
var event_id := 0
var last_hit: Variant = null
var result: Variant = null
var message := ""
var entry_cache := {}

## `art`: {nome: {clips: {id: clip}, markers: {id: [quadros]}}}; `specs`: CHARACTER_SPECS.
func _init(art: Dictionary, specs: Dictionary, chars := ["sorriso", "sorriso"]) -> void:
	roster = art
	for name in roster:
		var moves: Dictionary = Moves.create_moves(roster[name].clips, specs.get(name, specs.sorriso))
		for id in moves:
			var m: Dictionary = moves[id]
			if m.get("plant") is bool and m.plant:
				m.plant = Markers.planted_offsets(roster[name].markers.get(m.clip, []))
		moves_by[name] = moves
		reach_by[name] = measure_reach(moves, roster[name].markers)
	var sm: Dictionary = roster.sorriso.markers
	gait = {"run": Loco.gait_table(sm.r2_run), "walk": Loco.gait_table(sm.r2_walk)}
	characters = chars.duplicate()
	reset()

func reset() -> void:
	fighters = [Fighter.create_fighter(1, characters[0], 200, 1, roster[characters[0]].clips),
		Fighter.create_fighter(2, characters[1], 280, -1, roster[characters[1]].clips)]
	clock = 0.0
	hitstop = 0.0
	events = []
	event_id = 0
	last_hit = null
	result = null
	message = "Controle a distância. Golpe errado custa caro."

func set_characters(chars: Array) -> bool:
	for c in chars:
		if not roster.has(c):
			return false
	characters = chars.duplicate()
	reset()
	return true

# ---- consultas ---------------------------------------------------------------
func player() -> Dictionary: return fighters[0]
func rival() -> Dictionary: return fighters[1]
func other(f: Dictionary) -> Dictionary: return fighters[1] if f.id == fighters[0].id else fighters[0]
func by_id(id: Variant) -> Variant:
	for f in fighters:
		if f.id == id: return f
	return null
func clips_of(f: Dictionary) -> Dictionary: return roster[f.character].clips
func moves_of(f: Dictionary) -> Dictionary: return moves_by.get(f.character, moves_by.sorriso)
func move_of(f: Dictionary, id: Variant = "__move") -> Variant:
	var key: Variant = f.move if id is String and id == "__move" else id
	return moves_of(f).get(key, null) if key != null else null
func reach_of(f: Dictionary) -> Dictionary: return reach_by.get(f.character, reach_by.sorriso)
func marker_frame(character: String, clip: String, frame: Variant) -> Variant:
	var frames: Array = roster[character].markers.get(clip, [])
	var i := int(frame)
	return frames[i] if i >= 0 and i < frames.size() else null
func is_rocked(f: Dictionary) -> bool: return clock < f.rockedUntil

func command_move(f: Dictionary, c: Dictionary) -> String:
	return Moves.choose_move({"kind": "kick" if c.get("kick", false) else "attack", "forward": c.get("forward", false), "back": c.get("back", false),
		"up": c.get("up", false), "down": c.get("down", false), "run": c.get("run", false)}, f, moves_of(f))

func event(type: String, extra := {}) -> void:
	event_id += 1
	var e := {"id": event_id, "type": type, "at": clock}
	e.merge(extra, true)
	events.append(e)
	if events.size() > 32:
		events.pop_front()

func clear_inputs() -> void:
	for f in fighters:
		f.buffer.clear(); f.input = {}

func measure_reach(moves: Dictionary, markers: Dictionary) -> Dictionary:
	var out := {}
	for id in moves:
		var m: Dictionary = moves[id]
		var best := 0.0
		for frame in m.active:
			var frames: Array = markers.get(m.clip, [])
			var mk: Variant = frames[frame] if frame < frames.size() else null
			if mk == null: continue
			var tip: Variant = mk.get("frontFoot") if m.limb == "foot" else (mk.get("frontKnee") if m.limb == "knee" else mk.get("frontFist"))
			if tip is Dictionary and not tip.is_empty():
				best = maxf(best, float(tip.get("tipX", tip.get("x", 0))))
		var plant_max := 0.0
		if m.get("plant") is Array:
			for i in m.active:
				plant_max = maxf(plant_max, float(m.plant[i]) if i < m.plant.size() else 0.0)
		out[id] = best + plant_max
	return out

func plant_of(f: Dictionary) -> float:
	if f.state != "attack" or f.move == null: return 0.0
	var m: Variant = move_of(f)
	if m == null or not (m.get("plant") is Array): return 0.0
	var fr: int = m.frames[Moves.frame_index(m, f.moveT)]
	return float(m.plant[fr] if fr < m.plant.size() else 0) - float(f.plantBase)

func animation(f: Dictionary) -> Dictionary:
	return Fighter.animation_ref(f, moves_of(f), clips_of(f), gait, clock)

## Onde o sprite está desenhado (posição física + degrau da passada + recuo + passo do chute).
func draw_x(f: Dictionary) -> float:
	var recoil := 0.0
	if (f.state == "hitstun" or f.state == "blockstun") and f.recoil and f.t < RECOIL.ms:
		recoil = -f.facing * f.recoil * (1.0 - f.t / RECOIL.ms)
	var step: float = Fighter.gait_offset(f, gait) if f.character == "sorriso" else 0.0
	return f.x + step + recoil + f.facing * plant_of(f)

func markers_of(f: Dictionary) -> Variant:
	var ref := animation(f)
	var g := f.duplicate()
	g.x = draw_x(f)
	return Markers.world_markers(marker_frame(f.character, ref.clip, ref.frame), g)

func hurtboxes_of(f: Dictionary) -> Dictionary:
	if f.state in DOWN: return {}
	return Markers.hurtboxes(markers_of(f), f.state == "attack" or f.state == "clinchStrike")

# ---- ciclo -------------------------------------------------------------------
## inputs: [entrada do lutador 1, entrada do lutador 2]
func tick(inputs: Array, dt := TICK) -> void:
	for i in 2:
		var f: Dictionary = fighters[i]
		var input: Dictionary = inputs[i] if i < inputs.size() and inputs[i] != null else {}
		f.input = input
		f.prevX = f.x
		var cmd: Variant = Buffer.from_input(input, f.facing)
		if cmd != null: f.buffer.push(cmd, clock)
	if hitstop > 0:
		hitstop = maxf(0.0, hitstop - dt)
		return
	clock += dt
	for f in fighters: update(f, dt)
	var contacts: Array = []
	for f in fighters:
		var c: Variant = probe(f, other(f))
		if c != null: contacts.append(c)
	for c in contacts: apply_contact(c)
	separate()
	face()

func set_state(f: Dictionary, state: String) -> void:
	if f.state != state:
		f.from = f.state; f.state = state; f.t = 0.0

func to_idle(f: Dictionary) -> void:
	commit_root(f)
	f.from = f.state; f.state = "idle"; f.t = 0.0; f.move = null; f.chain = 0; f.vx *= 0.3

func regen(f: Dictionary, s: float) -> void:
	var busy: bool = f.state == "attack" or f.state in CLINCH_STATES
	var stunned: bool = f.state in ["hitstun", "blockstun", "knockdown", "down", "ko", "collapse"]
	f.headRecent = maxf(0.0, f.headRecent - ROCK.decay * s)
	if not stunned and not is_rocked(f):
		f.balance = minf(100.0, f.balance + (12.0 if busy else 30.0) * s)
	var gain := -6.0 if f.state == "run" else (8.0 if f.state == "guard" else (0.0 if busy or stunned else 22.0))
	f.stamina = clampf(f.stamina + gain * s, 0.0, 100.0)

func update(f: Dictionary, dt: float) -> void:
	var s := dt / 1000.0
	var o := other(f)
	f.t += dt
	regen(f, s)
	match f.state:
		"attack": update_attack(f, dt)
		"clinchStrike": update_clinch_strike(f, o, dt)
		"whiff":
			var total := 0.0
			for v in move_of(f).whiff.times: total += float(v)
			if f.t >= total:
				to_idle(f); take_buffered(f)
		"hitstun", "blockstun":
			slide(f, s, 10)
			if f.t >= f.stun: to_idle(f)
		"knockdown":
			slide(f, s, 5)
			if f.t >= 450:
				set_state(f, "down"); event("land", {"fighter": f.id, "x": f.x})
		"ko":
			slide(f, s, 5)
			if not f.landed and f.t >= 340:
				f.landed = true; event("land", {"fighter": f.id, "x": f.x, "ko": true})
		"down":
			if f.t >= (f.downMs if f.downMs else GROUND.downMs):
				f.downMs = 0.0; f.downExtra = 0.0; f.landFrom = null; set_state(f, "getup")
		"parried":
			slide(f, s, 8)
			if f.t >= PARRY.stagger: to_idle(f)
		"thrown": update_thrown(f, o)
		"getup":
			if f.t >= 160 + 90 * 6:
				to_idle(f); f.balance = maxf(f.balance, 60.0)
		"collapse":
			if f.t >= 1300:
				set_state(f, "rise"); f.condition.body = minf(f.condition.body, 70.0); f.balance = maxf(f.balance, 50.0)
		"grabMiss":
			if f.t >= Clinch.CLINCH.missMs: to_idle(f)
		"clinchEntry":
			Clinch.keep_gap(f, o, dt)
			f.clinch.grip -= dt
			if f.t >= Clinch.CLINCH.entry: set_state(f, "clinch")
		"clinch": update_clinch(f, o, dt)
		"held": update_held(f, o, dt)
		"brake":
			var cmd: Variant = f.buffer.peek(clock)
			if cmd != null and act(f, o, cmd):
				f.buffer.clear(); return
			if f.input.get("guard", false) and f.can.guard:
				f.guardAt = clock; set_state(f, "guard"); return
			f.vx = approach(f.vx, 0.0, Fighter.SPEED.run / 0.42 * s)
			slide(f, s, 0)
			if f.t >= Fighter.total_ms(roster.sorriso.clips.r2_runStop) or (absf(f.vx) < 1 and f.t >= 330): to_idle(f)
		"rise":
			var cmd2: Variant = f.buffer.peek(clock)
			if cmd2 != null and act(f, o, cmd2):
				f.buffer.clear(); return
			if f.t >= Fighter.total_ms(roster.sorriso.clips.r2_crouchUp): to_idle(f)
		_: update_neutral(f, o, dt)

static func approach(v: float, target: float, a: float) -> float:
	return v + clampf(target - v, -a, a)

func slide(f: Dictionary, s: float, friction: float) -> void:
	f.x = clampf(f.x + f.vx * s, STAGE.minX, STAGE.maxX)
	f.vx *= exp(-friction * s)

func update_neutral(f: Dictionary, o: Dictionary, dt: float) -> void:
	var s := dt / 1000.0
	var input: Dictionary = f.input
	var cmd: Variant = f.buffer.peek(clock)
	if cmd != null and act(f, o, cmd):
		f.buffer.clear(); return
	if input.get("guard", false) and f.can.guard:
		# `steady`: guarda comum pedida pela IA, que não vira aparo pelo tempo de reação.
		if f.state != "guard": f.guardAt = -1e9 if input.get("steady", false) else clock
		set_state(f, "guard"); f.vx = approach(f.vx, 0.0, 600 * s); slide(f, s, 0); return
	if input.get("down", false) and f.can.crouch:
		set_state(f, "crouch"); f.vx = 0.0; return
	if f.state == "crouch":
		set_state(f, "rise"); return
	var dir := int(bool(input.get("right", false))) - int(bool(input.get("left", false)))
	var rel: int = dir * f.facing
	var legs: float = (1.0 - f.condition.legs / 250.0) * (ROCK.speed if is_rocked(f) else 1.0)
	var running: bool = input.get("run", false) and rel > 0 and f.can.run and f.stamina > 5 and not is_rocked(f)
	var speed: float = Fighter.SPEED.run if running else (Fighter.SPEED.forward * legs if rel > 0 else (-Fighter.SPEED.back * legs if rel < 0 else 0.0))
	if not f.can.walk and not running:
		f.vx = 0.0; set_state(f, "idle" if f.state == "guard" else f.state); return
	if f.state == "run" and not running and absf(f.vx) > 50:
		set_state(f, "brake"); event("brake", {"fighter": f.id, "x": f.x}); return
	if running and f.state != "run":
		f.state = "run"; f.t = 0.0; f.runDistance = 0.0; event("dash", {"fighter": f.id, "x": f.x})
	var accel: float = Fighter.SPEED.run / (Fighter.RUN_START_MS / 1000.0) if running and f.t < Fighter.RUN_START_MS else 520.0
	f.vx = approach(f.vx, speed * f.facing, accel * s)
	var before: float = f.x
	f.x = clampf(f.x + f.vx * s, STAGE.minX, STAGE.maxX)
	var moved: float = (f.x - before) * f.facing
	if running:
		if f.t >= Fighter.RUN_START_MS: f.runDistance += absf(moved)
	elif absf(f.vx) > 2:
		var r := int(signf(moved))
		if f.state == "walk" and r != 0 and r != f.walkRel: f.t = 0.0
		if r != 0: f.walkRel = r
		set_state(f, "walk"); f.gait += moved
	else:
		set_state(f, "idle")

func act(f: Dictionary, o: Dictionary, cmd: Dictionary) -> bool:
	if cmd.kind == "grab": return try_grab(f, o)
	if not f.can.attack: return false
	if cmd.kind == "attack" and clock < f.parryUntil and move_of(f, "parryCounter") != null:
		f.parryUntil = 0.0; return begin(f, "parryCounter", false)
	if ground_reach(f, o) and move_of(f, Moves.ground_move(cmd)) != null:
		return begin(f, Moves.ground_move(cmd), false)
	var id := Moves.choose_move(cmd, f, moves_of(f))
	if id == "jab" and move_of(f, "elbow") != null and not (o.state in DOWN) and absf(o.x - f.x) <= float(reach_of(f).get("elbow", 0)) + ELBOW_SLACK:
		id = "elbow"
	return begin(f, id, false)

## O passo do chute (plant) ou o avanço desenhado (root) vira posição.
func commit_root(f: Dictionary) -> void:
	if f.state != "attack" or f.move == null: return
	var m: Variant = move_of(f)
	var plant := plant_of(f)
	if plant != 0.0:
		f.x = clampf(f.x + f.facing * plant, STAGE.minX, STAGE.maxX); f.plantBase = float(f.plantBase) + plant; return
	if m == null or not m.get("root", false): return
	var clip: Dictionary = clips_of(f).get(m.clip, {})
	var fr: int = m.frames[Moves.frame_index(m, f.moveT)]
	var adv := float(clip.frames[fr].get("advance", 0)) if not clip.is_empty() else 0.0
	if adv != 0.0: f.x = clampf(f.x + f.facing * adv, STAGE.minX, STAGE.maxX)

func ground_reach(f: Dictionary, o: Dictionary) -> bool:
	var dx: float = (o.x - f.x) * f.facing
	return (o.state == "knockdown" or o.state == "down") and dx > 0 and dx <= GROUND.reach

# ---- golpes em par -----------------------------------------------------------
func pair_for(f: Dictionary, o: Dictionary, when: String) -> String:
	var ms := moves_of(f)
	for id in ms:
		var m: Dictionary = ms[id]
		if m.get("pair") is Dictionary and m.pair.get("when") == when and absf(o.x - f.x) <= float(m.pair.get("reach", 44)):
			return id
	return ""

func start_pair(a: Dictionary, d: Dictionary, id: String, chained: bool) -> bool:
	if not begin(a, id, chained): return false
	a.pairDone = []
	d.state = "thrown"; d.t = 0.0; d.vx = 0.0; d.move = null; d.buffer.clear(); d.pairOf = a.id; d.pairRef = null
	if d.clinch != null: Clinch.end_clinch(by_id(d.clinch.partner), d)
	event("grab", {"fighter": a.id, "target": d.id})
	return true

func update_pair(a: Dictionary, d: Dictionary, m: Dictionary) -> void:
	var frame: int = m.frames[Moves.frame_index(m, a.moveT)]
	if d.state == "thrown" and d.pairOf == a.id:
		var contacts: Array = m.pair.contacts
		for i in contacts.size():
			var c: Dictionary = contacts[i]
			if frame >= int(c.frame) and not a.pairDone.has(i):
				a.pairDone.append(i); pair_hit(a, d, m, c)
	if a.moveT >= m.duration:
		if d.state == "thrown" and d.pairOf == a.id: to_idle(d)
		to_idle(a); take_buffered(a)

func update_thrown(f: Dictionary, o: Dictionary) -> void:
	var m: Variant = move_of(o) if o.state == "attack" else null
	if m == null or not (m.get("pair") is Dictionary) or f.pairOf != o.id:
		f.pairRef = null; to_idle(f); return
	var k := Moves.frame_index(m, o.moveT)
	var gap: float = float(m.pair.gap[mini(k, m.pair.gap.size() - 1)]) if m.pair.gap is Array else float(m.pair.gap)
	f.x = clampf(o.x + o.facing * gap, STAGE.minX, STAGE.maxX); f.facing = -o.facing; f.vx = 0.0
	var v: Variant = m.pair.get("victim", {}).get(f.character)
	f.pairRef = {"clip": v.clip, "frame": int(v.frames[mini(k, v.frames.size() - 1)])} if v != null and clips_of(f).has(v.clip) else null

func pair_hit(a: Dictionary, d: Dictionary, m: Dictionary, c: Dictionary) -> void:
	a.hitDone = true; a.connected = true
	var mm := m
	if c.has("scale"):
		mm = m.duplicate(); mm.damage = floor(m.damage * c.scale + 0.5)
	var r := Damage.resolve_hit(mm, d, c.zone, {"quality": "clean", "rocked": is_rocked(d)})
	Damage.apply_hit(d, r)
	hitstop = HITSTOP.heavy
	var point := Vector2(d.x, d.y - (52.0 if c.zone == "head" else 6.0))
	var kind := "throw" if m.get("throw", false) else "hit"
	last_hit = {"at": clock, "attacker": a.id, "target": d.id, "move": m.id, "zone": c.zone, "kind": kind, "damage": r.damage, "counter": false, "blocked": false, "quality": "clean", "point": point}
	event("hit", {"attacker": a.id, "target": d.id, "move": m.id, "zone": c.zone, "kind": kind, "counter": false, "quality": "clean", "heavy": true, "power": 3, "damage": r.damage, "point": point})
	if c.get("lands", false) or r.kind == "ko":
		d.state = "ko" if r.kind == "ko" else "down"; d.t = 0.0; d.downMs = GROUND.thrownMs; d.downExtra = 0.0; d.vx = a.facing * 30.0; d.move = null; d.buffer.clear(); d.pairRef = null
		d.landFrom = "thrown" if m.get("throw", false) else null
		event("land", {"fighter": d.id, "x": d.x})
	if r.kind == "ko":
		d.ko = true; result = {"winner": a.id, "loser": d.id, "reason": r.reason, "at": clock}; event("ko", {"winner": a.id, "reason": r.reason})
	if m.get("throw", false):
		message = "Arremessado! Aguente no chão." if d.id == player().id else "ARREMESSO! J e K batem no chão."
	else:
		message = m.name + "!"

# ---- golpe -------------------------------------------------------------------
func begin(f: Dictionary, id: String, chained: bool) -> bool:
	id = Moves.resolve_move(moves_of(f), id)
	var m: Variant = move_of(f, id)
	if m == null: return false
	if f.stamina < m.cost * 0.5:
		event("winded", {"fighter": f.id})
		if f.id == player().id: message = "Sem fôlego para esse golpe."
		return false
	f.stamina = maxf(0.0, f.stamina - m.cost)
	var from: Variant = animation(f) if chained else null
	if chained: commit_root(f)
	f.moveFrom = f.move if chained else null
	f.chain = f.chain + 1 if chained else 1
	f.combo = (f.combo + [id]) if chained else [id]
	var entry := entry_frame(from, m, f.character) if from != null else 0
	f.state = "attack"; f.t = 0.0; f.move = id
	f.moveT = Moves.before(m.times, entry)
	f.plantBase = float(m.plant[m.frames[entry]]) if m.get("plant") is Array else 0.0
	f.stepLeft = 0.0
	if chained and not m.get("ground", false) and not m.get("throw", false):
		var o := other(f)
		var boxes := hurtboxes_of(o)
		var edges: Array = []
		for z in m.targets:
			for b in boxes.get(z, []):
				if b.size.x * b.size.y >= 16:
					edges.append(b.position.x - f.x if f.facing > 0 else f.x - b.end.x)
		var edge: float = edges.min() if not edges.is_empty() else absf(o.x - f.x) - STEP_IN.margin
		var need: float = edge - float(reach_of(f).get(id, 30) if reach_of(f).get(id, 0) else 30) + STEP_IN.bite
		var fwd: bool = (f.input.get("right", false) and f.facing > 0) or (f.input.get("left", false) and f.facing < 0)
		var step := minf(STEP_IN.max, maxf(need, STEP_IN.forward if fwd else 0.0))
		var prep: float = m.activeStart - f.moveT
		if step > 0.5 and prep > 0:
			f.stepLeft = step; f.stepRate = step / prep
	f.connected = false; f.hitDone = false; f.prevTip = null; f.hitWindow = -1
	if not m.get("carry", 0): f.vx *= 0.2
	event("attack", {"fighter": f.id, "move": id, "chained": chained})
	return true

## Índice (em m.frames) do quadro de preparação mais próximo da pose `ref`.
func entry_frame(ref: Dictionary, m: Dictionary, character: String) -> int:
	var key := "%s:%s>%s:%s" % [ref.clip, ref.frame, m.clip, m.id]
	if entry_cache.has(key): return entry_cache[key]
	var a: Variant = marker_frame(character, ref.clip, ref.frame)
	var last: int = m.frames.find(m.active[0]) - 1
	var pa: Variant = _pose_points(a)
	var best := 0
	var cost := INF
	if pa != null:
		for i in range(0, last + 1):
			var pb: Variant = _pose_points(marker_frame(character, m.clip, m.frames[i]))
			if pb == null: continue
			var c := 0.0
			for j in pa.size():
				c += pa[j].distance_to(pb[j]) if pa[j] != null and pb[j] != null else 12.0
			if c < cost - 0.5:
				cost = c; best = i
	entry_cache[key] = best
	return best

static func _pose_points(k: Variant) -> Variant:
	if k == null: return null
	var pt := func(p: Variant) -> Variant: return Vector2(p.x, p.y) if p is Dictionary and not p.is_empty() and p.has("x") else null
	var tip := func(p: Variant) -> Variant: return Vector2(p.tipX, p.tipY) if p is Dictionary and not p.is_empty() else null
	return [pt.call(k.get("head")), pt.call(k.get("hip")), tip.call(k.get("frontFist")), tip.call(k.get("frontFoot"))]

func update_attack(f: Dictionary, dt: float) -> void:
	var s := dt / 1000.0
	var m: Dictionary = move_of(f)
	f.moveT += dt
	if f.stepLeft > 0:
		var dx := minf(f.stepLeft, f.stepRate * dt)
		f.x = clampf(f.x + f.facing * dx, STAGE.minX, STAGE.maxX)
		f.stepLeft -= dx
	if m.get("carry", 0):
		f.vx = approach(f.vx, 0.0, m.carry * 2 * s); slide(f, s, 0)
	else:
		f.vx = approach(f.vx, 0.0, 400 * s); slide(f, s, 0)
	var o := other(f)
	if m.get("pair") is Dictionary:
		update_pair(f, o, m); return
	var cmd: Variant = f.buffer.peek(clock, Buffer.CHAIN_BUFFER_MS)
	if cmd != null and cmd.kind == "grab" and f.connected and f.chain >= 2 and not m.get("ground", false) and f.moveT >= m.cancelStart and f.moveT <= m.cancelEnd and o.state == "hitstun":
		var pid := pair_for(f, o, "combo")
		if pid != "" and start_pair(f, o, pid, true):
			f.buffer.clear(); return
	if cmd != null and cmd.kind != "grab" and f.connected and f.chain < Moves.MAX_CHAIN and f.moveT >= m.cancelStart and f.moveT <= m.cancelEnd and (not m.get("ground", false) or ground_reach(f, o)):
		var next := Moves.cancel_target(m, cmd, f, f.combo, moves_of(f))
		if next != "" and begin(f, next, true):
			f.buffer.clear(); return
	if f.moveT >= m.duration:
		if not f.connected and m.get("whiff") is Dictionary:
			f.state = "whiff"; f.t = 0.0; event("whiff", {"fighter": f.id, "move": m.id}); return
		to_idle(f)
		take_buffered(f)

func take_buffered(f: Dictionary) -> void:
	var cmd: Variant = f.buffer.peek(clock, Buffer.CHAIN_BUFFER_MS)
	if cmd != null and act(f, other(f), cmd): f.buffer.clear()

static func react_kind(m: Dictionary, zone: String) -> String:
	if m.get("react"): return m.react
	var id: String = m.get("id", "")
	if zone == "legs": return "legs"
	if zone == "body": return "liver" if (id.contains("hook") or id.contains("round")) else "body"
	if id.contains("upper"): return "uppercut"
	if id.contains("hook") or id.contains("round") or id.contains("overhand"): return "hook"
	return "straight"

## Uma janela de um golpe com vários contatos, como golpe próprio.
static func hit_of(m: Dictionary, win: Dictionary) -> Dictionary:
	var last: bool = int(win.index) == m.hits.size() - 1
	var k := float(win.get("scale", 1.0))
	var out := m.duplicate()
	out.limb = win.get("limb", m.limb); out.targets = win.get("targets", m.targets); out.react = win.get("react", m.get("react"))
	out.damage = floor(m.damage * k + 0.5); out.balance = floor(m.balance * k + 0.5)
	out.hitstun = m.hitstun if last else floor(m.hitstun * 0.75 + 0.5)
	out.push = m.push if last else m.push * 0.25
	out.window = win.index
	return out

static func aim_of(m: Dictionary) -> String:
	if m.get("aim"): return m.aim if m.targets.has(m.aim) else ""
	if m.limb != "fist": return ""
	var zone := "body" if (m.id.contains("body") or m.id.contains("Body")) else "head"
	return zone if m.targets.has(zone) else ""

# ---- contato -----------------------------------------------------------------
func probe(a: Dictionary, d: Dictionary) -> Variant:
	if a.state != "attack" and a.state != "clinchStrike": return null
	var base: Dictionary = move_of(a)
	var frame: int = base.frames[Moves.frame_index(base, a.moveT)]
	var win: Variant = null
	if base.get("hits") is Array:
		for h in base.hits:
			if h.frames.has(float(frame)) or h.frames.has(frame): win = h; break
	if win != null and int(win.index) != a.hitWindow:
		var prev_limb: String = base.hits[a.hitWindow].get("limb", base.limb) if a.hitWindow >= 0 else base.limb
		if win.get("limb", base.limb) != prev_limb: a.prevTip = null
		a.hitWindow = int(win.index); a.hitDone = false
	var m: Dictionary = hit_of(base, win) if win != null else base
	var g := a.duplicate(); g.x = draw_x(a)
	var w: Variant = Markers.world_markers(marker_frame(a.character, m.clip, frame), g)
	var tip: Variant = Markers.limb_center(w.get(m.limb) if w != null else null, m.limb, a.facing)
	var active: bool = m.active.has(frame)
	if tip == null:
		a.prevTip = null; return null
	var near: bool = a.prevTip != null and tip.distance_to(a.prevTip) <= SWEEP_MAX
	var from: Vector2 = a.prevTip if near else tip
	a.prevTip = tip
	if not active or a.hitDone or m.get("throw", false): return null
	var downed: bool = d.state == "knockdown" or d.state == "down"
	if m.get("ground", false):
		if not downed: return null
	elif d.state in DOWN or d.state == "thrown":
		return null
	if bool(m.get("clinch", false)) != (a.state == "clinchStrike"): return null
	if d.state == "held" and (d.clinch == null or d.clinch.partner != a.id): return null
	var boxes: Dictionary
	if m.get("ground", false):
		var lying := Markers.hurtboxes(markers_of(d))
		boxes = {"head": lying.get("head", []), "body": lying.get("body", []) + lying.get("legs", [])}
	else:
		boxes = hurtboxes_of(d)
	var half: Vector2 = Markers.LIMB_SIZE[m.limb] / 2.0
	var legs_only: bool = m.targets.size() == 1 and m.targets[0] == "legs"
	var hip_y := INF
	for b in boxes.get("legs", []): hip_y = minf(hip_y, b.position.y)
	var zone_boxes := func(zone: String) -> Array:
		if not legs_only: return boxes.get(zone, [])
		var thigh: Array = []
		for b in boxes.get("body", []):
			if b.end.y > hip_y - 8:
				var y := maxf(b.position.y, hip_y - 8)
				thigh.append(Rect2(b.position.x, y, b.size.x, b.end.y - y))
		return boxes.get("legs", []) + thigh
	var limb := Rect2(tip - half, half * 2)
	var best: Variant = null
	var areas := {}
	for zone in m.targets:
		var area := 0.0
		var top: Variant = null
		for box in zone_boxes.call(zone):
			if not _overlap(limb, box): continue
			var part: float = (minf(limb.end.x, box.end.x) - maxf(limb.position.x, box.position.x)) * (minf(limb.end.y, box.end.y) - maxf(limb.position.y, box.position.y))
			area += part
			if top == null or part > top.part: top = {"box": box, "part": part}
		if top != null:
			areas[zone] = {"zone": zone, "t": 1.0, "area": area, "box": top.box, "coverage": minf(1.0, area / (4 * half.x * half.y))}
			if best == null or area > best.area: best = areas[zone]
	var aim := aim_of(m)
	if aim != "" and areas.has(aim) and areas[aim].area >= AIM_MIN * 4 * half.x * half.y: best = areas[aim]
	if best == null:
		for zone in m.targets:
			for box in zone_boxes.call(zone):
				var t: Variant = Collision.sweep(from, tip, half, box)
				if t != null and (best == null or t < best.t): best = {"zone": zone, "t": t, "box": box}
	var front: bool = (a.x - d.x) * d.facing > 0
	if (d.state == "guard" or d.state == "blockstun") and front and not legs_only and not m.get("ground", false):
		var gb: Variant = Markers.guard_box(d, markers_of(d))
		var tg: Variant = Collision.sweep(from, tip, half, gb) if gb != null else null
		if (tg != null and (best == null or tg <= best.t)) or (best != null and best.zone != "legs"):
			var point: Vector2 = Collision.contact_point(from, tip, tg, gb) if tg != null else Collision.contact_point(from, tip, best.t, best.box)
			var parried: bool = d.state == "guard" and clock - float(d.guardAt) <= PARRY.window
			return {"a": a, "d": d, "m": m, "blocked": true, "parried": parried, "zone": "arms", "point": point}
	if best == null: return null
	return {"a": a, "d": d, "m": m, "blocked": false, "parried": false, "zone": best.zone, "point": Collision.contact_point(from, tip, best.t, best.box), "coverage": best.get("coverage")}

static func _overlap(a: Rect2, b: Rect2) -> bool:
	return a.position.x < b.end.x and a.end.x > b.position.x and a.position.y < b.end.y and a.end.y > b.position.y

func apply_contact(c: Dictionary) -> void:
	if c.parried: apply_parry(c)
	elif c.m.get("ground", false): apply_ground(c)
	else: apply_strike(c)

func apply_parry(c: Dictionary) -> void:
	var a: Dictionary = c.a
	var d: Dictionary = c.d
	a.hitDone = true; a.connected = false
	a.state = "parried"; a.t = 0.0; a.move = null; a.chain = 0; a.buffer.clear(); a.vx = a.facing * 90.0
	d.parryUntil = clock + PARRY.counter
	d.stamina = minf(100.0, d.stamina + 6)
	hitstop = HITSTOP.heavy
	last_hit = {"at": clock, "attacker": a.id, "target": d.id, "move": c.m.id, "zone": "arms", "kind": "parry", "damage": 0, "counter": false, "blocked": true, "quality": "normal", "point": c.point}
	event("block", {"attacker": a.id, "target": d.id, "move": c.m.id, "zone": "arms", "kind": "parry", "counter": true, "quality": "normal", "heavy": true, "power": 2, "damage": 0, "point": c.point})
	message = "APARADO! J agora contra-ataca." if d.id == player().id else "Ele aparou: saia da frente."

func apply_ground(c: Dictionary) -> void:
	var a: Dictionary = c.a
	var d: Dictionary = c.d
	var m: Dictionary = c.m
	a.hitDone = true; a.connected = true
	var quality := Damage.contact_quality(c.get("coverage"))
	var r := Damage.resolve_hit(m, d, c.zone, {"quality": quality, "ground": true, "scale": COMBO.scale[mini(a.chain, COMBO.scale.size() - 1)]})
	Damage.apply_hit(d, r)
	d.groundHitAt = clock
	hitstop = HITSTOP.heavy if r.kind == "ko" else HITSTOP.medium
	last_hit = {"at": clock, "attacker": a.id, "target": d.id, "move": m.id, "zone": r.zone, "kind": r.kind, "damage": r.damage, "counter": false, "blocked": false, "quality": quality, "coverage": c.get("coverage"), "point": c.point}
	event("hit", {"attacker": a.id, "target": d.id, "move": m.id, "zone": r.zone, "kind": r.kind, "counter": false, "quality": quality, "heavy": true, "power": 3, "damage": r.damage, "point": c.point, "ground": true})
	if r.kind == "ko":
		d.state = "ko"; d.t = 0.0; d.ko = true; d.landed = true
		result = {"winner": a.id, "loser": d.id, "reason": r.reason, "at": clock}
		event("ko", {"winner": a.id, "reason": r.reason})
		message = r.reason
		return
	var extra := minf(GROUND.extend, GROUND.maxExtend - float(d.downExtra))
	if extra > 0:
		d.downExtra = float(d.downExtra) + extra
		d.downMs = (d.downMs if d.downMs else GROUND.downMs) + extra
	message = m.name + (" na cabeça." if c.zone == "head" else " no corpo.")

func apply_strike(c: Dictionary) -> void:
	var a: Dictionary = c.a
	var d: Dictionary = c.d
	var m: Dictionary = c.m
	var blocked: bool = c.blocked
	a.hitDone = true; a.connected = true
	var dm: Variant = move_of(d) if d.state == "attack" else null
	var counter: bool = m.id == "parryCounter" or (not blocked and dm != null and d.moveT < dm.activeEnd)
	var quality := "normal" if blocked else Damage.contact_quality(c.get("coverage"))
	if quality == "clean" and absf(a.x - d.x) < float(reach_of(a).get(m.id, 0)) * 0.6: quality = "normal"
	var was_rocked := is_rocked(d)
	var r := Damage.resolve_hit(m, d, c.zone, {"blocked": blocked, "counter": counter, "quality": quality, "rocked": was_rocked, "scale": COMBO.scale[mini(a.chain, COMBO.scale.size() - 1)]})
	Damage.apply_hit(d, r)
	var power := clampi(int(m.power) + (1 if quality == "clean" else (-1 if quality == "graze" else 0)), 1, 3)
	if blocked or quality == "graze": hitstop = HITSTOP.block
	elif r.kind != "hit" or power >= 3: hitstop = HITSTOP.heavy
	elif power == 2: hitstop = HITSTOP.medium
	else: hitstop = HITSTOP.light
	last_hit = {"at": clock, "attacker": a.id, "target": d.id, "move": m.id, "zone": r.zone, "kind": r.kind, "damage": r.damage, "counter": counter, "blocked": blocked, "quality": quality, "coverage": c.get("coverage"), "point": c.point}
	event("block" if r.kind == "block" else "hit", {"attacker": a.id, "target": d.id, "move": m.id, "zone": r.zone, "kind": r.kind, "counter": counter, "quality": quality, "heavy": power >= 3, "power": power, "damage": r.damage, "point": c.point})
	if not blocked and r.zone == "head" and r.kind != "ko":
		d.headRecent += r.damage * (ROCK.clean if quality == "clean" else 1.0)
		if not was_rocked and d.headRecent >= ROCK.threshold:
			d.rockedUntil = clock + ROCK.ms
			event("rocked", {"fighter": d.id})
	var tag := " LIMPO" if quality == "clean" else (" de raspão" if quality == "graze" else "")
	if r.reason != null: message = r.reason
	elif is_rocked(d) and not was_rocked: message = ("Você está grogue" if d.id == player().id else "Ele ficou grogue") + ": um golpe limpo na cabeça derruba."
	elif counter: message = "Contra-ataque: " + m.name + tag + "."
	elif blocked: message = "Defendido."
	else: message = m.name + tag + (" na cabeça." if c.zone == "head" else (" no tronco." if c.zone == "body" else " na perna."))
	var push_v: float = a.facing * r.push * 10.0 * (COMBO.hitPush if r.kind == "hit" else 1.0) * (COMBO.push if a.chain > 1 else 1.0)
	if a.clinch != null and d.clinch != null and r.kind == "hit":
		a.clinch.grip = minf(Clinch.CLINCH.maxGrip, a.clinch.grip + Clinch.CLINCH.refresh); return
	if d.clinch != null: Clinch.end_clinch(by_id(d.clinch.partner), d)
	d.buffer.clear()
	commit_root(d)
	d.move = null
	d.stun = r.stun
	d.reaction = r.zone
	d.reactKind = react_kind(m, r.zone)
	d.reactHeavy = r.kind == "hit" and (quality == "clean" or r.stun >= HEAVY_STUN or is_rocked(d))
	d.recoil = RECOIL.block if r.kind == "block" else (RECOIL.clean if quality == "clean" else (RECOIL.graze if quality == "graze" else RECOIL.hit))
	match r.kind:
		"block": d.state = "blockstun"; d.t = 0.0; d.vx = push_v
		"guardBreak": d.state = "hitstun"; d.t = 0.0; d.reaction = "body"; d.reactKind = "guardBreak"; d.vx = push_v
		"hit": d.state = "hitstun"; d.t = 0.0; d.vx = push_v
		"knockdown": d.state = "knockdown"; d.t = 0.0; d.vx = push_v + a.facing * 40.0
		"collapse": d.state = "collapse"; d.t = 0.0; d.vx = 0.0
		"ko":
			d.state = "ko"; d.t = 0.0; d.ko = true; d.vx = push_v + a.facing * 50.0
			result = {"winner": a.id, "loser": d.id, "reason": r.reason, "at": clock}; event("ko", {"winner": a.id, "reason": r.reason})
	var wall: bool = d.x <= STAGE.minX + 1 or d.x >= STAGE.maxX - 1
	if wall and (r.kind == "hit" or r.kind == "block"): a.vx = -push_v * 0.6

# ---- clinch ------------------------------------------------------------------
func try_grab(f: Dictionary, o: Dictionary) -> bool:
	if not f.can.clinch: return false
	var g: Variant = Markers.grab_box(f, markers_of(f))
	var body: Array = hurtboxes_of(o).get("body", [])
	var blocked: bool = o.state in DOWN or o.clinch != null or o.state == "attack" or o.state == "collapse"
	var touches := false
	if g != null:
		for b in body:
			if _overlap(g, b): touches = true
	if not touches or blocked:
		f.state = "grabMiss"; f.t = 0.0; f.vx = 0.0
		event("grabMiss", {"fighter": f.id})
		if f.id == player().id: message = "O golpe dele impediu o agarrão." if o.state == "attack" else "Agarrão no vazio: chegue mais perto."
		return true
	Clinch.start_clinch(f, o)
	event("clinch", {"fighter": f.id, "target": o.id})
	message = "Clinch: J soco curto · K joelhada · direção arrasta · G solta." if f.id == player().id else "Agarrado! Aperte golpes ou puxe para trás para escapar."
	return true

func update_clinch(f: Dictionary, o: Dictionary, dt: float) -> void:
	var s := dt / 1000.0
	var c: Dictionary = f.clinch
	var input: Dictionary = f.input
	c.grip -= dt
	Clinch.keep_gap(f, o, dt)
	var cmd: Variant = f.buffer.take(clock)
	if cmd != null and cmd.kind == "grab":
		Clinch.end_clinch(f, o, "release"); event("release", {"fighter": f.id}); return
	if cmd != null:
		var want := "knee" if cmd.kind == "kick" else "clinchPunch"
		var id := want if move_of(f, want) != null else "knee"
		var m: Variant = move_of(f, id)
		if m != null and f.stamina >= m.cost * 0.5:
			f.stamina = maxf(0.0, f.stamina - m.cost)
			f.state = "clinchStrike"; f.t = 0.0; f.move = id; f.moveT = 0.0; f.hitDone = false; f.connected = false; f.prevTip = null
			return
	var rel: int = (int(bool(input.get("right", false))) - int(bool(input.get("left", false)))) * f.facing
	if rel != 0:
		var dx: float = rel * f.facing * Clinch.CLINCH.drag * s
		var nx := clampf(f.x + dx, STAGE.minX, STAGE.maxX)
		var ox := clampf(o.x + dx, STAGE.minX, STAGE.maxX)
		var moved := minf(absf(nx - f.x), absf(ox - o.x)) * signf(dx)
		f.x += moved; o.x += moved; f.gait += absf(moved)
		f.stamina = maxf(0.0, f.stamina - Clinch.CLINCH.dragCost * s)
		c.grip -= dt * 0.25
	if c.grip <= 0 or f.stamina <= 0:
		Clinch.end_clinch(f, o, "escape"); event("release", {"fighter": f.id, "reason": "grip"}); message = "A pegada se desfez."

func update_clinch_strike(f: Dictionary, o: Dictionary, dt: float) -> void:
	var m: Dictionary = move_of(f)
	f.moveT += dt
	if f.clinch != null:
		f.clinch.grip -= dt; Clinch.keep_gap(f, o, dt)
	if f.moveT >= m.duration:
		if f.clinch != null and o.clinch != null:
			f.state = "clinch"; f.t = 0.0; f.move = null
		else:
			to_idle(f)

func update_held(d: Dictionary, a: Dictionary, dt: float) -> void:
	var s := dt / 1000.0
	var c: Variant = d.clinch
	if a == null or a.clinch == null:
		Clinch.end_clinch(null, d); return
	var cmd: Variant = d.buffer.take(clock)
	if cmd != null:
		c.escape += Clinch.escape_gain(d, a); d.stamina = maxf(0.0, d.stamina - Clinch.CLINCH.pulseCost)
	var rel: int = (int(bool(d.input.get("right", false))) - int(bool(d.input.get("left", false)))) * d.facing
	if rel < 0 and d.stamina > 0: c.escape += Clinch.CLINCH.holdEscape * s
	if c.escape >= 100:
		Clinch.end_clinch(a, d, "escape"); event("escape", {"fighter": d.id})
		message = "Você escapou do clinch." if d.id == player().id else "Ele escapou do clinch."

# ---- corpos ------------------------------------------------------------------
func separate() -> void:
	var a: Dictionary = fighters[0]
	var b: Dictionary = fighters[1]
	if a.state in DOWN or b.state in DOWN or a.clinch != null or b.clinch != null or a.state == "thrown" or b.state == "thrown": return
	var ha := _push_center(a)
	var hb := _push_center(b)
	var dir := 1.0 if b.x >= a.x else -1.0
	var striking: bool = a.state == "attack" or b.state == "attack"
	var minimum: float = (STAGE.strike if striking else STAGE.half) * 2
	var gap := minf(absf(b.x - a.x), (hb - ha) * dir)
	if gap >= minimum: return
	var push := (minimum - gap) / 2.0
	var ax: float = a.x - dir * push
	var bx: float = b.x + dir * push
	if ax < STAGE.minX: bx += STAGE.minX - ax; ax = STAGE.minX
	if ax > STAGE.maxX: bx -= ax - STAGE.maxX; ax = STAGE.maxX
	if bx < STAGE.minX: ax += STAGE.minX - bx; bx = STAGE.minX
	if bx > STAGE.maxX: ax -= bx - STAGE.maxX; bx = STAGE.maxX
	a.x = ax; b.x = bx

func _push_center(f: Dictionary) -> float:
	if f.state == "attack":
		var w: Variant = markers_of(f)
		if w != null and w.hip != null: return w.hip.x
	return draw_x(f)

func face() -> void:
	for f in fighters:
		var o := other(f)
		if f.state in ["idle", "walk", "guard", "crouch"] and absf(o.x - f.x) > 1:
			f.facing = 1 if o.x > f.x else -1
