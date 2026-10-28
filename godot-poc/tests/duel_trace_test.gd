extends SceneTree
## Replays do duelo: as mesmas entradas, tick a tick, no motor GDScript; o estado
## precisa bater com o gravado do Phaser (tools/generate_duel_traces.mjs).
const Duel = preload("res://scripts/duel/duel.gd")
const Art = preload("res://scripts/duel/art.gd")
const AI = preload("res://scripts/duel/ai.gd")

const FIELDS := ["x", "vx", "facing", "state", "move", "moveT", "stamina", "balance", "head", "body", "legs", "chain", "clip", "frame", "drawX"]

func near(a: Variant, b: Variant) -> bool:
	if (a is float or a is int) and (b is float or b is int):
		return absf(float(a) - float(b)) < 0.0005
	if a == null or b == null:
		return a == b
	return str(a) == str(b)

func same_input(a: Dictionary, b: Dictionary) -> bool:
	for k in a:
		if bool(a[k]) != bool(b.get(k, false)): return false
	for k in b:
		if bool(b[k]) != bool(a.get(k, false)): return false
	return true

func _init() -> void:
	var art := Art.load_all()
	var scenarios: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/duel_traces.json"))
	var failures := 0
	var ticks := 0
	for sc in scenarios:
		var d := Duel.new(art.roster, art.specs, sc.chars)
		var first_err := ""
		for k in 2:
			d.fighters[k].x = float(sc.start[k])
		# Lutas de IA: as entradas saem da IA GDScript e precisam ser as gravadas.
		var ais: Array = []
		if sc.has("ai"):
			for k in 2: ais.append(AI.new(int(sc.ai[k][0]), sc.ai[k][1]))
		for i in sc.inputs.size():
			var inp: Array = sc.inputs[i]
			if not ais.is_empty():
				var mine := [ais[0].input(d, d.fighters[0], d.fighters[1]), ais[1].input(d, d.fighters[1], d.fighters[0])]
				for k in 2:
					if not same_input(mine[k], inp[k]):
						if first_err == "": first_err = "tick %d: IA %d %s / %s" % [i, k + 1, mine[k], inp[k]]
				inp = mine
			if first_err != "":
				failures += 1
				break
			d.tick(inp)
			ticks += 1
			var want: Dictionary = sc.states[i]
			var errs: Array = []
			if not near(d.clock, want.clock): errs.append("clock %s/%s" % [d.clock, want.clock])
			if not near(d.hitstop, want.hitstop): errs.append("hitstop %s/%s" % [d.hitstop, want.hitstop])
			var res: Variant = d.result.winner if d.result != null else null
			if not near(res, want.result): errs.append("result %s/%s" % [res, want.result])
			for k in 2:
				var f: Dictionary = d.fighters[k]
				var a := d.animation(f)
				var got := [f.x, f.vx, f.facing, f.state, f.move, f.moveT, f.stamina, f.balance, f.condition.head, f.condition.body, f.condition.legs, f.chain, a.clip, a.frame, d.draw_x(f)]
				for j in FIELDS.size():
					if not near(got[j], want.f[k][j]):
						errs.append("f%d.%s %s/%s" % [k + 1, FIELDS[j], got[j], want.f[k][j]])
			if not errs.is_empty():
				failures += 1
				if first_err == "":
					first_err = "tick %d: %s" % [i, ", ".join(errs.slice(0, 6))]
				break
		print("%s: %s" % [sc.name, "OK (%d ticks)" % sc.inputs.size() if first_err == "" else "DIVERGE " + first_err])
	print("Duel traces: %d ticks, %d scenarios failing" % [ticks, failures])
	quit(1 if failures else 0)
