extends RefCounted
const QUALITY = {"clean": {"damage": 1.25, "balance": 1.2, "stun": 1.15}, "normal": {"damage": 1.0, "balance": 1.0, "stun": 1.0}, "graze": {"damage": 0.5, "balance": 0.5, "stun": 0.7}}

static func contact_quality(coverage: Variant) -> String:
	return "normal" if coverage == null else ("clean" if float(coverage) >= 0.6 else ("normal" if float(coverage) >= 0.25 else "graze"))

static func resolve_hit(move: Dictionary, defender: Dictionary, zone: String, options: Dictionary = {}) -> Dictionary:
	var rocked: bool = options.get("rocked", false)
	var counter: bool = options.get("counter", false)
	var quality: String = options.get("quality", "normal")
	var ground: bool = options.get("ground", false)
	var scale: float = options.get("scale", 1)
	if options.get("blocked", false):
		var stamina := maxf(4, float(move.cost) * 0.9 + float(move.power) * 2) * (2 if rocked else 1)
		var broken: bool = defender.stamina - stamina <= 0
		return {"kind": "guardBreak" if broken else "block", "zone": "arms", "damage": 0, "stamina": stamina,
			"balance": move.balance * 0.3, "stun": 520 if broken else move.blockstun, "push": move.push * 0.5,
			"reason": "Guarda rompida: sem fôlego para segurar." if broken else null}
	var q: Dictionary = QUALITY.get(quality, QUALITY.normal)
	var mult := (1.35 if counter else 1.0) * (1.2 if defender.balance < 30 else 1.0) * (1.15 if defender.stamina < 20 else 1.0)
	# JS Math.round for nonnegative values, avoiding banker's rounding.
	var damage := floori(float(move.damage) * mult * q.damage * scale + 0.5)
	var balance: float = move.balance * mult * q.balance * scale * (1.3 if zone == "legs" else 1.0) * (1 + defender.condition.legs / 200.0)
	var after: Dictionary = defender.condition.duplicate()
	after[zone] = minf(100, float(after[zone]) + damage)
	var out := {"kind": "hit", "zone": zone, "damage": damage, "balance": balance,
		"stamina": damage * (0.9 if zone == "body" else 0.3), "stun": floori(move.hitstun * (1.2 if counter else 1) * q.stun + 0.5),
		"push": move.push, "counter": counter, "quality": quality, "reason": null}
	var solid: bool = move.power >= 2 and quality != "graze"
	if zone == "head":
		if after.head >= 100:
			return outcome(out, "ko", "Nocaute: a cabeça não aguentou mais.")
		if ground and solid and after.head >= 55:
			return outcome(out, "ko", "Nocaute: finalizado no chão.")
		if solid and quality == "clean" and rocked and after.head >= 45:
			return outcome(out, "ko", "Nocaute: golpe limpo em quem estava grogue.")
		var clean: bool = solid and quality == "clean" and after.head >= 55
		if clean and counter:
			return outcome(out, "ko", "Nocaute: golpe limpo no contra-ataque, com a cabeça já castigada.")
		if clean and defender.balance - balance <= 30:
			return outcome(out, "ko", "Nocaute: golpe limpo com a base já perdida.")
	if ground:
		out.stun = 0
		return out
	if zone == "body" and after.body >= 100:
		return outcome(out, "collapse", "O tronco cedeu: dobrou de dor.")
	if zone == "legs" and after.legs >= 100:
		return outcome(out, "knockdown", "A perna cedeu.")
	if defender.balance - balance <= 0:
		return outcome(out, "knockdown", "Perdeu o equilíbrio e caiu.")
	return out

static func outcome(value: Dictionary, kind: String, reason: String) -> Dictionary:
	value.kind = kind
	value.reason = reason
	return value

static func apply_hit(defender: Dictionary, result: Dictionary) -> void:
	defender.stamina = maxf(0, defender.stamina - result.stamina)
	defender.balance = maxf(0, defender.balance - result.balance)
	if result.zone != "arms":
		defender.condition[result.zone] = minf(100, defender.condition[result.zone] + result.damage)
