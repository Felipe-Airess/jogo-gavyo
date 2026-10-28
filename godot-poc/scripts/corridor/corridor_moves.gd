extends RefCounted
## Golpes do corredor: port de battle.mjs (MOVES), context-moves.mjs (extendMoves,
## clinchChoice, canLink), build-moves.mjs e miguel-corridor.mjs (tabelas do Miguel).
const PARRY := {"window": 115.0, "opening": 620.0, "rearm": 260.0}
const FATIGUE := {"costFactor": 0.5, "exhaustedBelow": 6.0, "restPerSecond": 36.0, "recoverPerSecond": 14.0, "runPerSecond": 0.8, "dragPerSecond": 0.6}
const KNEE_TIMES := [70, 65, 50, 70, 70]
const PUNCHES := ["jab", "jabHead", "cross", "crossBody", "drive", "low", "reverse", "stepPunch", "rush", "counterStraight", "counterBody", "counterLeft", "counterBodyLeft"]
const KICKS := ["kick", "highKick", "comboKick", "lowKick", "groundKick"]
const MIGUEL_FALLBACK := {"reverse": "low", "rush": "drive", "comboKick": "kick", "stepPunch": "cross"}
const MIGUEL_CAN := {"run": true, "grab": false, "wipe": false}
const MIGUEL_MAP := {
	"jab": ["m4_jabBody", "JAB NO CORPO", "body"], "jabHead": ["m3_jab", "JAB NA CABECA", "head"], "cross": ["m3_cross", "DIRETO", "head"],
	"crossBody": ["m3_crossBody", "DIRETO NO TRONCO", "body"], "low": ["m4_hook", "GANCHO", "head"], "drive": ["m3_overhand", "GOLPE PESADO", ""],
	"kick": ["m3_roundKick", "CHUTE CIRCULAR", "body"], "highKick": ["m3_stepKick", "CHUTE COM PASSO", "body"], "lowKick": ["m3_lowKick", "CHUTE NA PERNA", "legs"],
}

static func jsround(v: float) -> int:
	return int(floor(v + 0.5))

static func total(times: Array) -> float:
	var s := 0.0
	for t in times: s += float(t)
	return s

static func range_list(n: int) -> Array:
	var out: Array = []
	for i in n: out.append(i)
	return out

static func make(name: String, clip: String, times: Array, extra := {}) -> Dictionary:
	var m := {"name": name, "clip": clip, "frames": range_list(times.size()), "times": times, "active": [3], "point": [23.0, -34.0], "size": [10.0, 8.0],
		"lunge": 0.0, "damage": 12.0, "knock": 40.0, "stun": 480.0, "pause": 32.0, "unbalance": 16.0, "chain": 300.0, "linkAt": 300.0, "cost": 11.0}
	m.merge(extra, true)
	return m

## MOVES de battle.mjs, já com extendMoves aplicado.
static func base_moves() -> Dictionary:
	var M := {
		"jab": {"name": "SOCO NO CORPO", "clip": "jab", "frames": [0, 1, 4, 5], "times": [90, 60, 75, 115], "active": [1], "point": [24.5, -36.8], "size": [8, 6], "lunge": 4, "damage": 16, "knock": 48, "stun": 490, "pause": 20, "unbalance": 14, "chain": 220},
		"cross": {"name": "DIRETO NA ABERTURA", "clip": "cross", "frames": [0, 2, 3, 4, 5], "times": [100, 55, 45, 80, 110], "active": [2, 3], "point": [25, -36.8], "size": [9, 6], "lunge": 7, "damage": 18, "knock": 60, "stun": 540, "pause": 26, "unbalance": 18, "chain": 265},
		"drive": {"name": "GOLPE PESADO", "clip": "heavyMotion", "frames": [0, 1, 2, 3, 4], "times": [145, 70, 55, 100, 160], "active": [2, 3], "point": [35, -40], "size": [9, 7], "lunge": 12, "damage": 24, "knock": 112, "stun": 620, "pause": 32, "unbalance": 35, "chain": 450, "heavy": true, "finish": true},
		"low": {"name": "SOCO BAIXO", "clip": "hook", "frames": [0, 1, 2, 3, 4], "times": [90, 55, 70, 85, 140], "active": [2], "point": [14, -25], "size": [9, 7], "lunge": 8, "damage": 20, "knock": 44, "stun": 560, "pause": 24, "unbalance": 20, "chain": 330},
		"reverse": {"name": "GOLPE PARA TRAS", "clip": "reverseMotion", "frames": [0, 1, 2, 3, 4], "times": [55, 55, 55, 65, 140], "active": [3], "point": [32, -36], "size": [9, 6], "lunge": 3, "damage": 15, "knock": 65, "stun": 400, "pause": 22, "unbalance": 15, "chain": 285},
		"kick": {"name": "CHUTE FRONTAL", "clip": "kick", "frames": [0, 1, 2, 3, 5], "times": [100, 70, 85, 90, 140], "active": [2], "point": [31, -23], "size": [11, 8], "lunge": 5, "damage": 24, "knock": 120, "stun": 650, "pause": 32, "unbalance": 30, "chain": 420, "heavy": true, "finish": true},
		"comboKick": {"name": "SOCO > CHUTE ALTO", "clip": "highKick", "sequence": [["jab", 4], ["highKick", 0], ["highKick", 1], ["highKick", 2], ["highKick", 4], ["kick", 0]], "frames": [0, 1, 2, 3, 4, 5], "times": [35, 35, 50, 65, 55, 90], "active": [2, 3, 4], "point": [37, -45], "size": [10, 8], "lunge": 9, "damage": 20, "knock": 72, "stun": 650, "pause": 28, "unbalance": 23, "chain": 265, "linkAt": 240},
		"stepPunch": {"name": "CHUTE > DIRETO", "clip": "combo", "sequence": [["kick", 5], ["combo", 0], ["combo", 3], ["combo", 5], ["combo", 7]], "frames": [0, 1, 2, 3, 4], "times": [35, 55, 55, 65, 100], "active": [2, 3], "point": [30, -45], "size": [10, 7], "lunge": 10, "damage": 16, "knock": 48, "stun": 540, "pause": 24, "unbalance": 18, "chain": 240, "linkAt": 220},
		"knee": {"name": "JOELHADA", "clip": "kneeMotion", "frames": [0, 1, 2, 3, 4], "times": KNEE_TIMES.duplicate(), "active": [2], "point": [18, -25], "size": [10, 9], "lunge": 0, "damage": 10, "knock": 0, "stun": 500, "pause": 30, "unbalance": 12, "chain": 325},
	}
	for name in ["jab", "cross", "low", "kick"]:
		M[name].point = [M[name].point[0] * 1.25, M[name].point[1] * 1.25]
	M.jab.linkAt = 160; M.cross.linkAt = 205; M.drive.linkAt = 330; M.low.linkAt = 235; M.reverse.linkAt = 245; M.kick.linkAt = 270
	M.jab.merge({"clip": "boxingFluid", "frames": [0, 1, 2, 3, 4, 5], "times": [35, 25, 30, 55, 85, 110], "active": [3], "cost": 10}, true)
	M.cross.merge({"clip": "boxingFluid", "frames": [6, 7, 8, 9, 10, 11], "times": [40, 25, 35, 50, 80, 160], "active": [9, 10], "cost": 14}, true)
	M.kick.merge({"clip": "roundFluid", "frames": range_list(12), "times": [40, 35, 35, 35, 35, 55, 50, 40, 35, 35, 40, 50], "active": [5, 6, 7], "point": [35, -42], "cost": 22, "linkAt": 330}, true)
	M.lowKick = {"name": "CHUTE NA PERNA", "clip": "lowFluid", "frames": range_list(12), "times": [35, 35, 35, 35, 40, 55, 55, 35, 35, 35, 35, 60], "active": [5, 6], "point": [32, -13], "size": [10, 8], "lunge": 6, "damage": 18, "knock": 24, "stun": 450, "pause": 32, "unbalance": 18, "chain": 400, "linkAt": 345, "cost": 18, "zone": "legs"}
	M.groundKick = {"name": "CHUTE NO CHAO", "clip": "groundFluid", "frames": range_list(12), "times": [50, 45, 45, 50, 40, 60, 60, 45, 40, 40, 45, 80], "active": [5, 6], "point": [27, -5], "size": [12, 9], "lunge": 4, "damage": 70, "knock": 0, "stun": 0, "pause": 55, "unbalance": 0, "chain": 660, "linkAt": 660, "cost": 28, "ground": true}
	M.rush = {"name": "SOCO COM O CORPO", "clip": "rushFluid", "frames": range_list(6), "times": [55, 50, 50, 55, 65, 95], "active": [3, 4], "point": [32, -41], "size": [11, 9], "lunge": 10, "damage": 28, "knock": 125, "stun": 700, "pause": 45, "unbalance": 50, "chain": 600, "linkAt": 600, "cost": 34, "rush": true, "heavy": true, "finish": true}
	M.lowKick.active = [4]; M.groundKick.active = [6]
	for name in M:
		if not M[name].has("cost"): M[name].cost = 7 if name == "knee" else (24 if name == "drive" else 16)
	# extendMoves
	M.merge({
		"clinchPunch": make("SOCO CURTO", "clinchPunch", [45, 35, 35, 45, 45, 45, 55, 65], {"active": [2], "clinch": true, "zone": "head", "damage": 9, "cost": 7}),
		"clinchElbow": make("COTOVELADA", "clinchElbow", [45, 40, 45, 45, 45, 50, 50, 70], {"active": [2], "clinch": true, "zone": "head", "damage": 13, "cost": 11}),
		"clinchFinish": make("GOLPE DE QUEDA", "clinchFinish", [50, 45, 55, 55, 70, 60, 65, 90], {"active": [4], "size": [12, 14], "clinch": true, "zone": "head", "damage": 24, "cost": 22, "release": true, "knock": 92, "heavy": true}),
		"counterStraight": make("APARO > DIRETO", "parryCounter", [35, 30, 35, 45, 45, 60, 65, 100], {"active": [4], "point": [33, -43], "lunge": 9, "damage": 22, "knock": 80, "cost": 15, "zone": "head", "carry": {"distance": 12, "time": 85}, "chain": 300, "linkAt": 300}),
		"counterBody": make("APARO > CORPO", "boxingFluid", [35, 25, 30, 50, 75, 120], {"frames": [0, 1, 2, 3, 4, 5], "active": [3], "point": [28, -33], "lunge": 7, "damage": 21, "knock": 56, "cost": 13, "zone": "body", "carry": {"distance": 10, "time": 80}, "chain": 220, "linkAt": 200}),
		"counterLeft": make("APARO > CRUZADO", "counterLeft", [35, 30, 35, 45, 45, 60, 65, 100], {"active": [4, 5], "point": [32, -46], "lunge": 8, "damage": 22, "knock": 76, "cost": 15, "zone": "head", "carry": {"distance": 12, "time": 85}, "chain": 300, "linkAt": 300}),
		"counterBodyLeft": make("APARO > TRONCO", "counterLeft", [35, 30, 35, 45, 45, 60, 65, 100], {"active": [4, 5], "point": [28, -37], "lunge": 7, "damage": 21, "knock": 56, "cost": 13, "zone": "body", "carry": {"distance": 10, "time": 80}, "chain": 270, "linkAt": 250}),
		"groundPunch": make("SOCO NO CHAO", "clinchFinish", [45, 40, 55, 55, 65, 65, 70, 110], {"active": [4], "point": [17, -6], "size": [14, 15], "ground": true, "lunge": 5, "cost": 22, "damage": 70, "pause": 50}),
		"groundStomp": make("PISADA", "groundStomp", [50, 50, 60, 65, 65, 60, 60, 105], {"active": [3, 4], "point": [24, -7], "size": [14, 16], "ground": true, "lunge": 4, "cost": 26, "damage": 70, "pause": 55}),
	}, true)
	M.drive.carry = {"distance": 20, "time": 110}
	M.low.carry = {"distance": 12, "time": 85}
	M.cross.carry = {"distance": 5, "time": 45}
	M.rush.carry = {"distance": 24, "time": 105}
	M.rush.name = "SOCO DE IMPULSO"; M.jab.name = "DIRETO NO CORPO"; M.cross.name = "CRUZADO"
	M.knee.merge({"clinch": true, "zone": "body", "clip": "kneeV6", "frames": range_list(8), "times": [45, 35, 45, 50, 50, 40, 45, 50], "active": [3, 4]}, true)
	for name in M:
		var m: Dictionary = M[name]
		m.duration = total(m.times)
		m.cost = maxf(3.0, ceil(float(m.cost) * FATIGUE.costFactor))
	return M

## build-moves.mjs: o jogo usa os golpes revisados do Sorriso (lote r3).
static func build_moves(clips: Dictionary) -> Dictionary:
	var moves: Dictionary = base_moves().duplicate(true)
	moves.jabHead = moves.jab.duplicate(true); moves.jabHead.name = "JAB NA CABECA"
	moves.crossBody = moves.cross.duplicate(true); moves.crossBody.name = "DIRETO NO TRONCO"
	moves.highKick = moves.kick.duplicate(true); moves.highKick.name = "CIRCULAR ALTO"
	var mapping := {"jab": ["jab_body", 0, 1.6], "jabHead": ["jab_head", 0, 1.6], "cross": ["cross_head", 0, 1.65], "crossBody": ["cross_body", 0, 1.65], "low": ["hook_body", 0, 1.7],
		"drive": ["overhand_heavy", 0, 1.65], "reverse": ["reverse_strike", 0, 1.65], "rush": ["running_punch", 0, 1.6], "kick": ["round_kick_body", 0, 1.65],
		"highKick": ["round_kick_head", 0, 1.65], "lowKick": ["low_kick", 0, 1.65], "comboKick": ["combo_punch_kick", 5, 1.8], "stepPunch": ["combo_kick_punch", 5, 1.8]}
	for id in mapping:
		var clip: Variant = clips.get("r3_" + mapping[id][0])
		if clip == null: continue
		var start: int = mapping[id][1]
		var factor: float = mapping[id][2]
		var m: Dictionary = moves[id]
		var frames: Array = []
		for i in range(start, clip.frames.size()): frames.append(i)
		var times: Array = []
		for t in clip.durations.slice(start):
			times.append(maxi(35, jsround(float(t) * (1.0 if clip.get("timingRevision") == "0.7.0" else factor))))
		var contacts: Array = []
		for i in clip.contactFrames:
			if int(i) >= start: contacts.append(int(i))
		m.erase("sequence")
		m.merge({"clip": clip.id, "frames": frames, "times": times, "active": contacts, "duration": total(times), "reviewed": true, "animationStart": start}, true)
		var contact_start := total(times.slice(0, frames.find(contacts[0])))
		var contact_end := total(times.slice(0, frames.find(contacts[-1]) + 1))
		m.lungeUntil = maxf(160, contact_start + 30)
		m.chain = minf(m.duration - 60, contact_end + 150)
		m.linkAt = minf(m.duration - 80, contact_end + 120)
		m.pause = 55 if id == "drive" or id == "rush" else (42 if id.contains("Kick") or id == "kick" else 32)
		if m.has("carry"): m.carry = {"distance": m.carry.distance, "time": maxf(85, m.carry.time)}
		if id in ["jab", "low", "crossBody"]: m.zone = "body"
		elif id in ["cross", "jabHead", "highKick"]: m.zone = "head"
		elif id == "lowKick": m.zone = "legs"
		elif id in ["drive", "reverse", "rush", "comboKick", "stepPunch"]: m.erase("zone")
		else: m.zone = "body"
		if id == "comboKick" or id == "stepPunch":
			m.chain = m.duration - 80; m.linkAt = m.duration - 80
	return moves

## Clipes do Miguel com fist/foot por quadro (pontas dos marcadores).
static func miguel_player_clips(clips: Dictionary, markers: Dictionary) -> Dictionary:
	var out := {}
	for id in clips:
		var c: Dictionary = clips[id].duplicate(true)
		var mk: Array = markers.get(id, [])
		for i in c.frames.size():
			var m: Variant = mk[i] if i < mk.size() else null
			var fist: Variant = m.get("frontFist") if m is Dictionary else null
			var foot: Variant = m.get("frontFoot") if m is Dictionary else null
			if fist is Dictionary and not fist.is_empty(): c.frames[i].fist = {"x": fist.tipX, "y": fist.tipY}
			if foot is Dictionary and not foot.is_empty(): c.frames[i].foot = {"x": foot.tipX, "y": foot.tipY}
		out[id] = c
	return out

static func miguel_moves(clips: Dictionary) -> Dictionary:
	var base := base_moves()
	var moves := {}
	for id in MIGUEL_MAP:
		var key: String = id
		if not base.has(key): key = "jab" if id == "jabHead" else ("cross" if id == "crossBody" else ("kick" if id == "highKick" else id))
		var clip: Variant = clips.get(MIGUEL_MAP[id][0])
		if not base.has(key) or clip == null or clip.get("contactFrames", []).is_empty(): continue
		var times: Array = clip.durations.duplicate()
		var active: Array = []
		for f in clip.contactFrames: active.append(int(f))
		var duration := total(times)
		var contact_start := total(times.slice(0, active[0]))
		var contact_end := total(times.slice(0, active[-1] + 1))
		var m: Dictionary = base[key].duplicate(true)
		m.merge({"name": MIGUEL_MAP[id][1], "clip": MIGUEL_MAP[id][0], "frames": range_list(clip.frames.size()), "times": times, "active": active, "duration": duration, "reviewed": true, "animationStart": 0}, true)
		m.erase("sequence")
		m.lungeUntil = maxf(160, contact_start + 30)
		m.chain = minf(duration - 60, contact_end + 150)
		m.linkAt = minf(duration - 80, contact_end + 120)
		m.pause = 55 if id == "drive" else (42 if id.contains("Kick") or id == "kick" else 32)
		if MIGUEL_MAP[id][2] != "": m.zone = MIGUEL_MAP[id][2]
		else: m.erase("zone")
		moves[id] = m
	return moves

static func clinch_choice(input: Dictionary) -> String:
	if input.get("run", false) and input.get("attack", false): return "clinchFinish"
	if input.get("attack", false) and input.get("down", false): return "clinchElbow"
	if input.get("attack", false): return "clinchPunch"
	return "knee"

static func can_link(move: Dictionary, player: Dictionary, mixed := false) -> bool:
	if move.get("ground", false) or move.get("rush", false) or move.get("clinch", false) or player.stamina < 3: return false
	return player.confirmed or (mixed and not player.hit)

static func frame_at(time: float, m: Dictionary) -> int:
	var t := maxf(0.0, time)
	for i in m.times.size():
		if t < float(m.times[i]): return int(m.frames[i])
		t -= float(m.times[i])
	return int(m.frames[-1])

## pose-state.mjs: quadro do manequim pelo estado.
static func enemy_ref(d: Dictionary) -> Dictionary:
	if d.state == "clinch":
		return {"clip": "targetBody", "frame": mini(4, int(floor(d.get("clinchProgress", 0.0) / 50.0)))} if d.get("clinchMove") == "clinchFinish" else {"clip": "targetClinch", "frame": 2}
	if d.state == "carried": return {"clip": "targetHead" if d.zone == "head" else "targetBody", "frame": 1}
	if d.state == "parried": return {"clip": "targetGuard", "frame": 4}
	if d.state == "enemyWindup": return {"clip": "targetGuard", "frame": 1 if d.attackArm == "left" else 0}
	if d.state == "legDown": return {"clip": "targetClinch", "frame": 4}
	if d.state == "legStagger": return {"clip": "targetClinch", "frame": 1}
	if d.state == "bodyDown": return {"clip": "targetBody", "frame": mini(4, 2 + int(floor(d.get("bodyDownAge", 0.0) / 120.0)))}
	if d.guard: return {"clip": "targetGuard", "frame": mini(3, int(floor((60 - d.parts.arms) / 12.0)))}
	if d.state == "guardBreak": return {"clip": "targetGuard", "frame": 4}
	if d.state == "headStagger": return {"clip": "targetHead", "frame": 1 if d.reaction > 145 else 2}
	if d.state == "bodyStagger": return {"clip": "targetBody", "frame": 1 if d.reaction > 190 else 2}
	if d.parts.arms == 0: return {"clip": "targetGuard", "frame": 4}
	return {"clip": "targetBody", "frame": 0}
