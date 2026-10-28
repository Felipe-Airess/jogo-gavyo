extends RefCounted
## Port de src/duel/ai.mjs. Produz a mesma entrada que o teclado e passa pelas
## mesmas regras do jogador; só vê o que está na tela, com tempo de reação.
const Fighter = preload("res://scripts/duel/fighter.gd")

const LEVELS := {
	"calmo": {"reaction": 230.0, "guard": 0.45, "parry": 0.1, "throw": 0.2, "punish": 0.5, "think": [260.0, 420.0], "rest": [900.0, 1500.0]},
	"firme": {"reaction": 180.0, "guard": 0.7, "parry": 0.2, "throw": 0.35, "punish": 0.75, "think": [180.0, 320.0], "rest": [650.0, 1200.0]},
	"dificil": {"reaction": 150.0, "guard": 0.85, "parry": 0.35, "throw": 0.45, "punish": 0.9, "think": [140.0, 240.0], "rest": [450.0, 900.0]},
}
const LEVEL_NAMES := {"calmo": "CALMO", "firme": "FIRME", "dificil": "DIFICIL"}

var seed := 29
var level: Dictionary
var rng := 0
var think_at := 0.0
var attack_at := 900.0
var guard_until := 0.0
var decided: Variant = null
var mash_at := 0.0
var walk := 0
var plan: Variant = null
var punishing: Variant = null
var follow := 0.0
var steady := false

func _init(seed_value := 29, level_name := "firme") -> void:
	seed = seed_value
	level = LEVELS.get(level_name, LEVELS.firme)
	reset()

func reset() -> void:
	rng = seed & 0xFFFFFFFF
	think_at = 0.0; attack_at = 900.0; guard_until = 0.0; decided = null; mash_at = 0.0
	walk = 0; plan = null; punishing = null; follow = 0.0; steady = false

## Mesmo gerador congruente do JS (32 bits sem sinal).
func random() -> float:
	rng = (rng * 1664525 + 1013904223) & 0xFFFFFFFF
	return float(rng) / 4294967296.0

func span(r: Array) -> float:
	return r[0] + (r[1] - r[0]) * random()

func input(duel, me: Dictionary, foe: Dictionary) -> Dictionary:
	var out := {}
	var now: float = duel.clock
	var L := level
	var toward := func(fwd: bool) -> String: return "right" if (me.facing > 0) == fwd else "left"
	var dist: float = absf(foe.x - me.x)
	if me.state == "held":
		if now >= mash_at:
			out.attack = true; mash_at = now + span([170.0, 260.0])
		out[toward.call(false)] = true
		return out
	if me.state == "clinch":
		if now >= think_at:
			think_at = now + span([380.0, 560.0])
			if me.stamina < 18: out.grab = true
			elif random() < 0.65: out.kick = true
			else: out.attack = true
		return out
	if follow and now >= follow:
		follow = 0.0
		if me.state == "attack":
			if me.connected and me.chain >= 2 and foe.state == "hitstun" and random() < L.throw:
				out.grab = true; return out
			out.attack = true; out[toward.call(true)] = true
			if me.chain < 2 and random() < 0.5: follow = now + 240
			return out
	if (foe.state == "down" or foe.state == "knockdown") and me.state in Fighter.NEUTRAL:
		var dx: float = (foe.x - me.x) * me.facing
		if dx > 0 and dx <= 40:
			if now >= think_at:
				think_at = now + span([200.0, 340.0])
				out["attack" if random() < 0.5 else "kick"] = true
			return out
		out[toward.call(true)] = true
		return out
	if not (me.state in Fighter.NEUTRAL) and me.state != "rise": return out
	if now < me.parryUntil:
		out.attack = true; return out
	var fm: Variant = duel.move_of(foe) if foe.state == "attack" else null
	if fm != null:
		var key := "%s:%d" % [foe.move, int(floor((now - foe.moveT) / 10.0 + 0.5))]
		var threat: bool = dist < float(duel.reach_of(foe).get(foe.move, 30) if duel.reach_of(foe).get(foe.move, 0) else 30) + 18 and foe.moveT < fm.activeEnd
		if threat and foe.moveT >= L.reaction and decided != key:
			decided = key
			if random() < L.guard:
				guard_until = now + (fm.activeEnd - foe.moveT) + 60
				steady = random() >= L.parry
	if now < guard_until:
		out.guard = true; out.steady = steady; return out
	var lh: Variant = duel.last_hit
	var blocked_by_me: bool = lh != null and lh.blocked and lh.target == me.id and lh.attacker == foe.id
	var exposed: bool = foe.state == "whiff" or foe.state == "grabMiss" or foe.state == "parried" or (fm != null and foe.moveT > fm.activeEnd and (not foe.connected or blocked_by_me))
	var reach: float = float(duel.reach_of(me).get("cross", 40) if duel.reach_of(me).get("cross", 0) else 40) + 6
	if exposed and dist <= reach + 30:
		if punishing == null or punishing < now - 1500:
			punishing = now if random() < L.punish else -1e9
		if punishing >= now - 1500:
			if dist > reach:
				out[toward.call(true)] = true; return out
			out.attack = true
			out[toward.call(true)] = true
			punishing = -1e9
			attack_at = now + span(L.rest)
			return out
	if now >= think_at:
		think_at = now + span(L.think)
		var tired: bool = me.stamina < 25
		var desired := 74.0 if tired else 50.0 + span([-6.0, 6.0])
		walk = 1 if dist > desired + 6 else (-1 if dist < desired - 8 else 0)
		plan = null
		if not tired and now >= attack_at:
			var options: Array = []
			if dist < 28: options.append({"grab": true, "id": ""})
			var reach_map: Dictionary = duel.reach_of(me)
			var moves: Dictionary = duel.moves_of(me)
			var commands: Array = [{"attack": true}, {"attack": true, "down": true}, {"attack": true, "forward": true}, {"attack": true, "back": true},
				{"attack": true, "up": true}, {"kick": true}, {"kick": true, "down": true}]
			if me.stamina > 45 and random() < 0.25:
				commands += [{"attack": true, "run": true, "down": true}, {"kick": true, "run": true}, {"kick": true, "run": true, "forward": true}]
			for c in commands:
				var id: String = duel.command_move(me, c)
				if id == "" or not moves.has(id) or moves[id].get("ground", false) or moves[id].get("throw", false): continue
				var dup := false
				for o in options:
					if o.get("id", "") == id: dup = true
				if dup: continue
				var r := float(reach_map.get(id, 30))
				if dist <= r + 12:
					var opt: Dictionary = c.duplicate(); opt.id = id
					options.append(opt)
			if not options.is_empty():
				plan = options[int(floor(random() * options.size()))]
				attack_at = now + span(L.rest)
				follow = now + 260 if plan.get("attack", false) and not plan.get("forward", false) and random() < 0.4 else 0.0
			else:
				walk = 1
	if plan != null:
		var p: Dictionary = plan
		plan = null
		for k in ["grab", "attack", "kick", "down", "up", "run"]:
			if p.get(k, false): out[k] = true
		if p.get("forward", false): out[toward.call(true)] = true
		if p.get("back", false): out[toward.call(false)] = true
		return out
	if walk != 0: out[toward.call(walk > 0)] = true
	return out
