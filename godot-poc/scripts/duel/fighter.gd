extends RefCounted
## Port de src/duel/fighter.mjs. Jogador e IA usam exatamente esta estrutura.
const Buffer = preload("res://scripts/core/command_buffer.gd")
const Moves = preload("res://scripts/core/moves.gd")
const Loco = preload("res://scripts/duel/locomotion.gd")

## O que cada personagem consegue mostrar com a arte existente.
const CHARACTERS := {
	"sorriso": {"name": "SORRISO", "requires": {"walk": "r2_walk", "run": "r2_run", "crouch": "r2_crouchHold", "attack": "r3_jab_head", "hurt": "hurt", "fall": "fall", "rise": "rise", "guard": "block", "clinch": "clinchWalk"}},
	"miguel": {"name": "MIGUEL", "requires": {"walk": "m3_walk", "run": "m4_run", "crouch": "", "attack": "m3_jab", "hurt": "m4_hitHead", "fall": "m4_fall", "rise": "m4_rise", "guard": "m_block", "clinch": "m5_clinchHold"}},
}
const SPEED := {"forward": 52.0, "back": 42.0, "run": 120.0, "crouch": 0.0}
const RUN_START_MS := 340.0
const NEUTRAL := ["idle", "walk", "run", "brake", "guard", "crouch"]
const MIGUEL_GUARD := {"clip": "m_enterGuard", "frame": 5}
const MIGUEL_ABSORB := {"clip": "m_block", "frame": 3}
const MIGUEL_WALK_CYCLE := 36.0
const MIGUEL_HIT := {"head": "m4_hitHead", "body": "m4_hitBody", "legs": "m4_hitLeg"}
const MIGUEL_REACT := {
	"straight": [["m4_hitHeadHeavy"], ["m4_hitHead"]],
	"hook": [["m4_hitHookHeavy", "m4_hitHook", "m4_hitHeadHeavy"], ["m4_hitHook", "m4_hitHead"]],
	"uppercut": [["m4_hitUppercutHeavy", "m4_hitUppercut", "m4_hitHeadHeavy"], ["m4_hitUppercut", "m4_hitHead"]],
	"body": [["m4_hitBodyHeavy", "m4_hitBody"], ["m4_hitBody"]],
	"liver": [["m4_hitLiver", "m4_hitBody"], ["m4_hitLiver", "m4_hitBody"]],
	"legs": [["m4_hitLegHeavy", "m4_hitLeg"], ["m4_hitLeg"]],
	"guardBreak": [["m5_guardBreak", "m4_hitBody"], ["m5_guardBreak", "m4_hitBody"]],
}
const MIGUEL_TIRED := 25.0
const MIGUEL_AFTER := {"walk": "m5_walkStop", "clinch": "m5_clinchRelease", "clinchEntry": "m5_clinchRelease", "clinchStrike": "m5_clinchRelease", "held": "m5_clinchEscape"}
const MIGUEL_HEAVY_STUN := 440.0

static func capabilities(character: String, clips: Dictionary) -> Dictionary:
	var out := {}
	var req: Dictionary = CHARACTERS[character].requires
	for action in req:
		out[action] = req[action] != "" and clips.has(req[action])
	return out

static func create_fighter(id: int, character: String, x: float, facing: int, clips: Dictionary) -> Dictionary:
	return {
		"id": id, "character": character, "x": x, "prevX": x, "y": 150.0, "facing": facing, "vx": 0.0,
		"state": "idle", "t": 0.0, "from": null,
		"move": null, "moveT": 0.0, "connected": false, "hitDone": false, "chain": 0, "prevTip": null, "moveFrom": null,
		"combo": [], "hitWindow": -1, "plantBase": 0.0,
		"gait": 0.0, "runDistance": 0.0, "walkRel": 0,
		"condition": {"head": 0.0, "body": 0.0, "legs": 0.0}, "balance": 100.0, "stamina": 100.0,
		"headRecent": 0.0, "rockedUntil": -1.0,
		"guardAt": -1e9, "parryUntil": 0.0, "downMs": 0.0, "downExtra": 0.0, "stepLeft": 0.0, "stepRate": 0.0,
		"buffer": Buffer.new(), "stun": 0.0, "reaction": null, "reactKind": null, "reactHeavy": null, "recoil": 0.0,
		"clinch": null, "result": null, "ko": false, "landed": false, "invulnerable": false,
		"pairOf": null, "pairRef": null, "pairDone": [], "landFrom": null, "groundHitAt": null,
		"can": capabilities(character, clips), "input": {},
		"lastHitAt": -1e9,
	}

static func total_ms(clip: Dictionary) -> float:
	if clip.has("totalMs"):
		return float(clip.totalMs)
	var s := 0.0
	for d in clip.durations:
		s += float(d)
	return s

static func loop_frame(clip: Dictionary, t: float) -> int:
	var total := total_ms(clip)
	var rest := fmod(fmod(t, total) + total, total)
	var durations: Array = clip.durations
	for i in durations.size():
		if rest < float(durations[i]):
			return i
		rest -= float(durations[i])
	return 0

static func timed(times: Array, t: float) -> int:
	return Moves.frame_index({"times": times}, t)

static func hold(durations: Array, t: float, from := 0) -> int:
	return from + timed(durations.slice(from), t)

static func by_distance(clip: Dictionary, d: float, stride: float) -> int:
	var n: int = clip.frames.size()
	return int(floor(fmod(fmod(d, stride) + stride, stride) / stride * n)) % n

static func once(clip: Dictionary, t: float) -> Dictionary:
	return {"clip": clip.id, "frame": timed(clip.durations, t)}

## Deslocamento visual da locomoção do Sorriso: degraus iguais ao recuo do pé apoiado.
static func gait_offset(f: Dictionary, gait: Variant) -> float:
	if gait == null or (f.state != "walk" and not (f.state == "run" and f.t >= RUN_START_MS)):
		return 0.0
	var table: Dictionary = gait.run if f.state == "run" else gait.walk
	var distance: float = f.runDistance if f.state == "run" else f.gait
	var stride: float = table.stride
	var phase := fmod(fmod(distance, stride) + stride, stride)
	return -(phase - float(table.start[Loco.table_frame(table, distance)])) * f.facing

static func miguel_hit(f: Dictionary, clips: Dictionary) -> Variant:
	var kind: String = f.reactKind if f.reactKind != null else ("straight" if f.reaction == "head" else (f.reaction if f.reaction != null else "body"))
	var heavy: bool = f.reactHeavy if f.reactHeavy != null else f.stun >= MIGUEL_HEAVY_STUN
	for id in MIGUEL_REACT.get(kind, MIGUEL_REACT.body)[0 if heavy else 1]:
		if clips.has(id):
			return clips[id]
	return clips.get(MIGUEL_HIT.get(f.reaction, "m4_hitBody"), null)

static func miguel_ref(f: Dictionary, clips: Dictionary, clock: float, moves: Dictionary) -> Dictionary:
	if f.state == "thrown" and f.pairRef != null and clips.has(f.pairRef.clip):
		return f.pairRef
	var fallen: Dictionary = {"clip": "m4_hitHead", "frame": 2} if clips.has("m4_hitHead") else MIGUEL_ABSORB
	match f.state:
		"idle":
			var after_id: String = MIGUEL_AFTER.get(f.from, "") if f.from != null else ""
			if after_id != "" and clips.has(after_id) and f.t < total_ms(clips[after_id]):
				return once(clips[after_id], f.t)
			if clock < f.rockedUntil and clips.has("m4_dazed"):
				return {"clip": "m4_dazed", "frame": loop_frame(clips.m4_dazed, f.t)}
			if f.stamina < MIGUEL_TIRED and clips.has("m5_tired"):
				return {"clip": "m5_tired", "frame": loop_frame(clips.m5_tired, f.t)}
			return {"clip": "m3_idle", "frame": loop_frame(clips.m3_idle, f.t)} if clips.has("m3_idle") else MIGUEL_GUARD
		"walk":
			if (f.from == "idle" or f.from == "guard") and clips.has("m5_walkStart") and f.t < total_ms(clips.m5_walkStart):
				return once(clips.m5_walkStart, f.t)
			var gid := "m4_walkBack" if f.walkRel < 0 else "m4_walkFwd"
			if clips.has(gid):
				return {"clip": gid, "frame": by_distance(clips[gid], absf(f.gait), MIGUEL_WALK_CYCLE)}
			if clips.has("m3_walk"):
				var c: Dictionary = clips.m3_walk
				var n: int = c.frames.size()
				var k := by_distance(c, f.gait, float(c.stride)) if c.get("stride") else loop_frame(c, f.t)
				return {"clip": "m3_walk", "frame": n - 1 - k if f.walkRel < 0 else k}
			var cid := "m_walkBack" if f.walkRel < 0 else "m_walkFwd"
			return {"clip": cid, "frame": loop_frame(clips[cid], f.t)}
		"attack":
			if f.move != null and moves.has(f.move):
				var m: Dictionary = moves[f.move]
				return {"clip": m.clip, "frame": m.frames[Moves.frame_index(m, f.moveT)]}
			return MIGUEL_ABSORB
		"guard":
			if clips.has("m4_block"):
				return {"clip": "m4_block", "frame": mini(2, timed(clips.m4_block.durations, f.t))}
			return {"clip": "m_block", "frame": mini(2, timed(clips.m_block.durations, f.t))}
		"blockstun":
			var bc: Dictionary = clips.m4_block if clips.has("m4_block") else clips.m_block
			return {"clip": bc.id, "frame": mini(5, hold(bc.durations, f.t, 3))}
		"run":
			if f.t < RUN_START_MS and clips.has("m4_runStart"):
				return {"clip": "m4_runStart", "frame": timed(clips.m4_runStart.durations, f.t * total_ms(clips.m4_runStart) / RUN_START_MS)}
			if clips.has("m4_run"):
				return {"clip": "m4_run", "frame": by_distance(clips.m4_run, f.runDistance, Loco.R2_STRIDE.run)}
			return fallen
		"brake":
			return once(clips.m4_runStop, f.t) if clips.has("m4_runStop") else fallen
		"knockdown", "ko":
			return once(clips.m4_fall, f.t) if clips.has("m4_fall") else fallen
		"getup":
			return once(clips.m4_rise, f.t) if clips.has("m4_rise") else fallen
		"hitstun":
			var hc: Variant = miguel_hit(f, clips)
			if hc == null:
				return MIGUEL_ABSORB
			var hn: int = hc.frames.size()
			var first := 1 if hn > 2 else 0
			return {"clip": hc.id, "frame": mini(hn - 1, first + int(floor(f.t / maxf(1.0, f.stun) * (hn - first))))}
		"down":
			if f.landFrom == "thrown" and clips.has("m5_thrown"):
				var th: Dictionary = clips.m5_thrown
				var tail: Array = th.durations.slice(7)
				var total := 0.0
				for v in tail:
					total += float(v)
				if f.t < total:
					return {"clip": th.id, "frame": 7 + timed(tail, f.t)}
			var since: float = clock - (f.groundHitAt if f.groundHitAt != null else -1e9)
			if clips.has("m5_groundHit") and since >= 0 and since < total_ms(clips.m5_groundHit):
				return once(clips.m5_groundHit, since)
			return {"clip": "m4_lying", "frame": loop_frame(clips.m4_lying, f.t)} if clips.has("m4_lying") else MIGUEL_ABSORB
		"clinchEntry":
			if clips.has("m5_clinchGrab"):
				return {"clip": "m5_clinchGrab", "frame": mini(clips.m5_clinchGrab.frames.size() - 1, timed(clips.m5_clinchGrab.durations, f.t))}
		"clinch":
			if clips.has("m5_clinchHold"):
				return {"clip": "m5_clinchHold", "frame": loop_frame(clips.m5_clinchHold, f.t)}
		"clinchStrike":
			if f.move != null and moves.has(f.move):
				var cm: Dictionary = moves[f.move]
				return {"clip": cm.clip, "frame": cm.frames[Moves.frame_index(cm, f.moveT)]}
		"grabMiss":
			if clips.has("m5_clinchGrab"):
				return {"clip": "m5_clinchGrab", "frame": [0, 1, 2, 1, 0][mini(4, int(floor(f.t / 60.0)))]}
		"held":
			if clips.has("m5_held"):
				return {"clip": "m5_held", "frame": loop_frame(clips.m5_held, f.t)}
			return {"clip": "m4_hitBody", "frame": 2} if clips.has("m4_hitBody") else MIGUEL_ABSORB
		"thrown", "parried":
			return {"clip": "m4_hitBody", "frame": 2} if clips.has("m4_hitBody") else MIGUEL_ABSORB
	return fallen

## Quadro a desenhar: {clip, frame}. `gait`: tabelas de avanço medidas nos pés.
static func animation_ref(f: Dictionary, moves: Dictionary, clips: Dictionary, gait: Variant, clock: float) -> Dictionary:
	if f.character == "miguel":
		return miguel_ref(f, clips, clock, moves)
	if f.state == "thrown" and f.pairRef != null and clips.has(f.pairRef.clip):
		return f.pairRef
	match f.state:
		"walk":
			if gait != null:
				return {"clip": "r2_walk", "frame": Loco.table_frame(gait.walk, f.gait)}
			var n: int = clips.r2_walk.frames.size()
			var stride: float = Loco.R2_STRIDE.walk
			var phase := fmod(fmod(f.gait, stride) + stride, stride)
			return {"clip": "r2_walk", "frame": int(floor(phase / stride * n)) % n}
		"run":
			if f.t < RUN_START_MS:
				return {"clip": "r2_runStart", "frame": timed(clips.r2_runStart.durations, f.t * total_ms(clips.r2_runStart) / RUN_START_MS)}
			if gait != null:
				return {"clip": "r2_run", "frame": Loco.table_frame(gait.run, f.runDistance)}
			var rn: int = clips.r2_run.frames.size()
			return {"clip": "r2_run", "frame": int(floor(fmod(f.runDistance, Loco.R2_STRIDE.run) / Loco.R2_STRIDE.run * rn)) % rn}
		"brake":
			return {"clip": "r2_runStop", "frame": timed(clips.r2_runStop.durations, f.t)}
		"crouch":
			if f.t < total_ms(clips.r2_crouchDown):
				return {"clip": "r2_crouchDown", "frame": timed(clips.r2_crouchDown.durations, f.t)}
			return {"clip": "r2_crouchHold", "frame": loop_frame(clips.r2_crouchHold, f.t)}
		"rise":
			return {"clip": "r2_crouchUp", "frame": timed(clips.r2_crouchUp.durations, f.t)}
		"attack", "clinchStrike":
			var m: Dictionary = moves[f.move]
			return {"clip": m.clip, "frame": m.frames[Moves.frame_index(m, f.moveT)]}
		"whiff":
			var w: Dictionary = moves[f.move].whiff
			return {"clip": w.clip, "frame": timed(w.times, f.t)}
		"guard":
			return {"clip": "block", "frame": 0}
		"blockstun":
			return {"clip": "block", "frame": mini(3, 1 + int(floor(f.t / 70.0)))}
		"hitstun":
			return {"clip": "hurt", "frame": 1 if f.reaction == "head" else (3 if f.reaction == "legs" else 0)}
		"knockdown", "ko":
			return {"clip": "fall", "frame": mini(3, timed([90, 110, 140, 1e9], f.t))}
		"down":
			return {"clip": "fall", "frame": 3}
		"getup":
			return {"clip": "fall", "frame": 4} if f.t < 160 else {"clip": "rise", "frame": timed([90, 90, 90, 90, 90, 90, 1e9], f.t - 160)}
		"collapse":
			return {"clip": "crouch", "frame": mini(5, 2 + int(floor(f.t / 130.0)))}
		"clinchEntry", "clinch":
			return {"clip": "clinchWalk", "frame": int(floor(absf(f.gait) / 3.0)) % 8 if f.state == "clinch" else mini(2, int(floor(f.t / 70.0)))}
		"grabMiss":
			return {"clip": "clinchWalk", "frame": [0, 1, 2, 1, 0][mini(4, int(floor(f.t / 60.0)))]}
		"held", "thrown", "parried":
			return {"clip": "hurt", "frame": 0}
	return {"clip": "r1_idle", "frame": loop_frame(clips.r1_idle, f.t)}
