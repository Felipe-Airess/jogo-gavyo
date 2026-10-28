extends SceneTree
## Replays do corredor: mesmas entradas no motor GDScript, mesmo estado do Phaser
## (tools/generate_corridor_traces.mjs).
const Battle = preload("res://scripts/corridor/battle.gd")
const CM = preload("res://scripts/corridor/corridor_moves.gd")
const Art = preload("res://scripts/duel/art.gd")
const PF := ["x", "y", "vx", "vy", "state", "move", "elapsed", "stamina", "hp", "facing", "bloodL", "bloodR"]
const EF := ["x", "y", "state", "head", "body", "arms", "legs", "stun", "facing", "knockedOut", "dead"]

static func make(art: Dictionary, character: String, mode: String) -> Battle:
	var clips: Dictionary = art.roster.sorriso.clips
	var b := Battle.new(2, 731, CM.build_moves(clips))
	b.art_clips = clips
	if character == "miguel":
		var mc := CM.miguel_player_clips(art.roster.miguel.clips, art.roster.miguel.markers)
		b.moves = CM.miguel_moves(mc); b.can = CM.MIGUEL_CAN.duplicate(); b.fallback = CM.MIGUEL_FALLBACK; b.player_clips = mc; b.reset()
	b.set_mode(mode)
	return b

func near(a: Variant, b: Variant) -> bool:
	if (a is float or a is int or a is bool) and (b is float or b is int or b is bool):
		return absf(float(a) - float(b)) < 0.002
	if a == null or b == null: return a == b
	return str(a) == str(b)

func _init() -> void:
	var art := Art.load_all()
	var scenarios: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/corridor_traces.json"))
	var failures := 0
	var frames := 0
	for sc in scenarios:
		var b := make(art, sc.character, sc.mode)
		var err := ""
		for i in sc.inputs.size():
			b.step(sc.inputs[i], 1000.0 / 60.0)
			frames += 1
			var want: Dictionary = sc.states[i]
			var p := b.player
			var got := [p.x, p.y, p.vx, p.vy, p.state, p.move, p.elapsed, p.stamina, p.hp, p.facing, p.handBlood.left, p.handBlood.right]
			var errs: Array = []
			if not near(b.clock, want.clock): errs.append("clock %s/%s" % [b.clock, want.clock])
			for j in PF.size():
				if not near(got[j], want.p[j]): errs.append("p.%s %s/%s" % [PF[j], got[j], want.p[j]])
			for k in b.enemies.size():
				var d: Dictionary = b.enemies[k]
				var ge := [d.x, d.y, d.state, d.parts.head, d.parts.body, d.parts.arms, d.parts.legs, d.stun, d.facing, d.knockedOut, d.dead]
				for j in EF.size():
					if not near(ge[j], want.e[k][j]): errs.append("e%d.%s %s/%s" % [k + 1, EF[j], ge[j], want.e[k][j]])
			if not errs.is_empty():
				err = "quadro %d: %s" % [i, ", ".join(errs.slice(0, 6))]
				failures += 1
				break
		print("%s: %s" % [sc.name, "OK (%d quadros)" % sc.inputs.size() if err == "" else "DIVERGE " + err])
	print("Corridor traces: %d quadros, %d cenários com diferença" % [frames, failures])
	quit(1 if failures else 0)
