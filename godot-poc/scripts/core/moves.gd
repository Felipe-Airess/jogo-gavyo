extends RefCounted
const FALLBACK = {"jabBody": "crossBody", "hook": "jab", "rushPunch": "overhand", "kneeStrike": "roundBody", "uppercut": "jab", "elbow": "jab", "comboBodyUpper": "overhand", "comboJabElbowKnee": "kneeStrike", "comboLowHigh": "roundBody"}

static func before(times: Array, index: int) -> float:
	var result := 0.0
	for i in maxi(0, index): result += float(times[i])
	return result

static func create_moves(clips: Dictionary, specs: Dictionary) -> Dictionary:
	var moves := {}
	for id in specs:
		var spec: Dictionary = specs[id]
		if not clips.has(spec.clip): continue
		var clip: Dictionary = clips[spec.clip]
		var start := int(spec.get("start", 0))
		var frames: Array = []
		for i in range(start, clip.frames.size()): frames.append(i)
		var times: Array = spec.times if spec.has("times") else clip.durations.slice(start)
		var hits: Variant = null
		var active: Array = []
		if spec.has("hits"):
			hits = spec.hits.duplicate(true)
			for i in hits.size():
				hits[i].index = i
				for f in hits[i].frames:
					if not active.has(int(f)): active.append(int(f))
			active.sort()
		else:
			for f in spec.get("active", clip.get("contactFrames", [])):
				if int(f) >= start: active.append(int(f))
		if active.is_empty(): continue
		var active_start := before(times, frames.find(active[0]))
		var active_end := before(times, frames.find(active[-1])) + float(times[frames.find(active[-1])])
		var cancel_end := active_end + 80
		for i in frames:
			var phase: String = clip.frames[i].get("phase", "")
			if i > active[-1] and (phase.begins_with("recup") or phase.begins_with("recol") or phase.begins_with("acomo")):
				cancel_end = before(times, frames.find(i))
				break
		var move: Dictionary = spec.duplicate(true)
		move.merge({"id": id, "frames": frames, "times": times, "active": active, "activeStart": active_start,
			"activeEnd": active_end, "cancelStart": active_start, "cancelEnd": cancel_end,
			"duration": before(times, times.size()), "targets": spec.get("targets", ["head", "body"] if spec.limb == "fist" else ["head", "body", "legs"])}, true)
		if hits != null: move.hits = hits
		moves[id] = move
	var standing: Array = []
	var ground: Array = []
	for id in moves:
		var m: Dictionary = moves[id]
		if not (m.get("clinch", false) or m.get("ground", false) or m.get("throw", false) or m.get("special", false)): standing.append(id)
		if m.get("ground", false): ground.append(id)
	for id in moves:
		var m: Dictionary = moves[id]
		m.cancels = [] if m.get("finisher", false) or m.get("clinch", false) or m.get("throw", false) else (ground.duplicate() if m.get("ground", false) else standing.duplicate())
	return moves

static func resolve_move(moves: Dictionary, id: String) -> String:
	var next := id
	for i in 4:
		if moves.has(next) or not FALLBACK.has(next): break
		next = FALLBACK[next]
	return next if moves.has(next) else id

static func choose_move(cmd: Dictionary, fighter: Dictionary, moves: Dictionary = {}) -> String:
	var id := "jab"
	if cmd.kind == "kick" and cmd.run: id = "comboJabElbowKnee" if cmd.forward else "comboLowHigh"
	elif cmd.kind == "kick": id = "roundHead" if cmd.up else ("lowKick" if cmd.down else ("kneeStrike" if cmd.forward else "roundBody"))
	elif cmd.run and cmd.down: id = "comboBodyUpper"
	elif cmd.run and fighter.state == "run" and absf(fighter.vx) > 60: id = "rushPunch"
	elif cmd.run: id = "overhand"
	elif cmd.down and cmd.forward: id = "crossBody"
	elif cmd.down: id = "jabBody"
	elif cmd.forward: id = "cross"
	elif cmd.back: id = "hook"
	elif cmd.up: id = "uppercut"
	return resolve_move(moves, id) if not moves.is_empty() else id

# ---- Port do restante de src/duel/moves.mjs usado pelo duelo -----------------
const MAX_CHAIN := 4
const MAX_REPEAT := 2

## Quadro (índice em move.frames) no instante t do golpe.
static func frame_index(move: Dictionary, t: float) -> int:
	var rest := maxf(0.0, t)
	var times: Array = move.times
	for i in times.size():
		if rest < float(times[i]):
			return i
		rest -= float(times[i])
	return times.size() - 1

## Em quem está no chão: J soco de martelo, K chute.
static func ground_move(cmd: Dictionary) -> String:
	return "groundKick" if cmd.kind == "kick" else "groundPunch"

## Movimento seguinte permitido durante um golpe, ou "".
static func cancel_target(move: Dictionary, cmd: Dictionary, fighter: Dictionary, history: Array, moves: Dictionary) -> String:
	if move.cancels.is_empty():
		return ""
	var next := ""
	if move.get("ground", false):
		next = ground_move(cmd)
	elif move.get("links") is Dictionary and move.links.has(cmd.kind):
		next = move.links[cmd.kind]
	else:
		next = choose_move(cmd, fighter, moves)
	if not move.cancels.has(next):
		return ""
	var tail := history.slice(maxi(0, history.size() - MAX_REPEAT))
	if tail.size() == MAX_REPEAT:
		var all_same := true
		for id in tail:
			if id != next:
				all_same = false
		if all_same:
			return ""
	return next
