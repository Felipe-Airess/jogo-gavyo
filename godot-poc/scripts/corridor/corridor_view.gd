extends RefCounted
## Quadros do corredor: port de sprite-player.mjs (Sorriso), miguel-corridor.mjs
## (Miguel jogando) e target-view.mjs (manequins).
const CM = preload("res://scripts/corridor/corridor_moves.gd")
const R2_STRIDE := {"run": 112.0, "walk": 76.0}

static func timed(clip: String, frames: Array, times: Array, time: float) -> Dictionary:
	var t := maxf(0.0, time)
	for i in times.size():
		if t < float(times[i]): return {"clip": clip, "frame": int(frames[i])}
		t -= float(times[i])
	return {"clip": clip, "frame": int(frames[-1])}

static func gait_frame(p: Dictionary, clips: Dictionary) -> int:
	var run: bool = p.state == "run"
	var count: int = clips["r2_run" if run else "r2_walk"].frames.size()
	var distance: float = p.runDistance if run else p.walkDistance
	var stride: float = R2_STRIDE.run if run else R2_STRIDE.walk
	return int(floor(fmod(distance, stride) / stride * count)) % count

static func total(times: Array) -> float:
	var s := 0.0
	for t in times: s += float(t)
	return s

## sprite-player.mjs spriteRef, ramo com o atlas revisado (r1_idle).
static func sorriso_ref(p: Dictionary, moves: Dictionary, clips: Dictionary) -> Dictionary:
	var st: String = p.state
	if st in ["idle", "winded", "guard", "attackRecover"]:
		var c: Dictionary = clips.r1_idle
		var frames: Array = []
		for i in c.frames.size(): frames.append(i)
		return timed("r1_idle", frames, c.durations, fmod(p.elapsed, total(c.durations)))
	if st == "walk": return {"clip": "r2_walk", "frame": gait_frame(p, clips)}
	if st == "run":
		if p.runStart < 280: return timed("r2_runStart", [0, 1, 2, 3, 4, 5, 6, 7], [40, 35, 35, 35, 35, 35, 35, 30], p.runStart)
		return {"clip": "r2_run", "frame": gait_frame(p, clips)}
	if st == "brake": return timed("r2_runStop", [0, 1, 2, 3, 4, 5, 6, 7], [35, 40, 50, 45, 40, 40, 45, 1000], p.elapsed)
	if st == "clinchEntry": return {"clip": "clinchPunch", "frame": 0}
	if st == "clinch":
		return {"clip": "clinchWalk", "frame": int(floor(p.clinchDistance / 3.0)) % 8} if p.clinchWalking else {"clip": "clinchPunch", "frame": 0}
	if st == "attack" or st == "knee":
		var m: Dictionary = moves[p.move]
		var f := CM.frame_at(p.elapsed, m)
		if m.has("sequence"): return {"clip": m.sequence[f][0], "frame": int(m.sequence[f][1])}
		return {"clip": m.clip, "frame": f}
	if st == "parry": return timed("counterLeft" if p.parryArm == "right" else "parryCounter", [0, 1, 2], [30, 35, 1000], p.elapsed)
	if st == "wipe": return timed("wipeHands", [0, 1, 2, 3, 4, 5, 6, 7], [100, 100, 130, 130, 130, 160, 140, 1000], p.elapsed)
	if st == "rushFall": return timed("rushFluid", [6, 7, 8, 9, 10], [90, 100, 150, 220, 10000], p.elapsed)
	if st == "gettingUp": return timed("rushFluid", [10, 11], [180, 10000], p.elapsed)
	if st == "stumble":
		if p.whiffMove == "drive": return timed("missMotion", [0, 1, 2, 3, 4], [45, 65, 80, 75, 10000], p.elapsed)
		return timed("hurt", [0, 2, 3], [100, 120, 10000], p.elapsed)
	if st == "hurt": return timed("hurt", [0, 1, 2, 3], [70, 80, 100, 10000], p.elapsed)
	if st == "recover": return {"clip": "clinchPunch", "frame": 7 if p.elapsed < 100 else 0}
	return timed("idle", [0, 1, 2, 3, 4, 5, 4, 3, 2, 1], [180, 180, 180, 180, 180, 180, 180, 180, 180, 180], fmod(p.elapsed, 1800.0))

static func sorriso_flip(p: Dictionary) -> bool:
	return p.facing > 0 if p.state == "attack" and p.move == "reverse" else p.facing < 0

## Duração por quadro: lista `durations` ou, nos clipes antigos, `duration` em cada quadro.
static func durations_of(clip: Dictionary) -> Array:
	if clip.has("durations"): return clip.durations
	var out: Array = []
	for f in clip.frames: out.append(float(f.get("duration", 100)))
	return out

static func loop_frame(clip: Dictionary, t: float) -> int:
	var ds := durations_of(clip)
	var tot := total(ds)
	var rest := fmod(fmod(t, tot) + tot, tot)
	for i in ds.size():
		if rest < float(ds[i]): return i
		rest -= float(ds[i])
	return 0

static func clip_timed(clip: Dictionary, t: float) -> int:
	var ds := durations_of(clip)
	var rest := maxf(0.0, t)
	for i in ds.size():
		if rest < float(ds[i]): return i
		rest -= float(ds[i])
	return ds.size() - 1

## miguel-corridor.mjs miguelCorridorRef.
static func miguel_ref(p: Dictionary, moves: Dictionary, clips: Dictionary) -> Dictionary:
	match p.state:
		"walk":
			var back: bool = int(signf(p.vx)) == -p.facing
			var c: Dictionary = clips["m4_walkBack" if back else "m4_walkFwd"]
			var n: int = c.frames.size()
			var d := fmod(fmod(p.gaitDistance, 36.0) + 36.0, 36.0)
			return {"clip": c.id, "frame": int(floor(d / 36.0 * n)) % n}
		"attack", "knee":
			if p.move != null and moves.has(p.move):
				var m: Dictionary = moves[p.move]
				return {"clip": m.clip, "frame": CM.frame_at(p.elapsed, m)}
		"attackRecover":
			var key: Variant = p.recoverFrom if p.recoverFrom != null else p.move
			if key != null and moves.has(key):
				var mr: Dictionary = moves[key]
				return {"clip": mr.clip, "frame": int(mr.frames[-1]) if p.elapsed < 80 else int(mr.frames[0])}
		"guard": return {"clip": "m4_block", "frame": mini(2, clip_timed(clips.m4_block, p.elapsed))}
		"parry": return {"clip": "m4_parryCounter", "frame": mini(1, clip_timed(clips.m4_parryCounter, p.elapsed))}
		"hurt": return {"clip": "m4_hitHead", "frame": clip_timed(clips.m4_hitHead, p.elapsed)}
		"stumble": return {"clip": "m4_hitBody", "frame": clip_timed(clips.m4_hitBody, p.elapsed)}
		"winded": return {"clip": "m4_dazed", "frame": loop_frame(clips.m4_dazed, p.elapsed)}
		"run":
			if p.runStart < 280: return {"clip": "m4_runStart", "frame": clip_timed(clips.m4_runStart, p.runStart * total(durations_of(clips.m4_runStart)) / 280.0)}
			var rc: Dictionary = clips.m4_run
			var d2 := fmod(fmod(p.runDistance, R2_STRIDE.run) + R2_STRIDE.run, R2_STRIDE.run)
			return {"clip": "m4_run", "frame": int(floor(d2 / R2_STRIDE.run * rc.frames.size())) % rc.frames.size()}
		"brake": return {"clip": "m4_runStop", "frame": clip_timed(clips.m4_runStop, p.elapsed)}
		"rushFall": return {"clip": "m4_fall", "frame": clip_timed(clips.m4_fall, p.elapsed)}
		"gettingUp": return {"clip": "m4_rise", "frame": clip_timed(clips.m4_rise, p.elapsed)}
	return {"clip": "m3_idle", "frame": loop_frame(clips.m3_idle, p.elapsed)}

## target-view.mjs: quadro e altura do manequim (a queda segue a física).
static func target_ref(d: Dictionary) -> Dictionary:
	var y: float = d.y
	var ref := CM.enemy_ref(d)
	if d.state == "fallen":
		var age: float = d.ragdoll.age
		ref = {"clip": "targetHead", "frame": 2 if age < 90 else (3 if age < 230 else 4)}
		var hip_above := 4.0 if ref.frame == 4 else 23.0
		y = minf(d.y, d.ragdoll.nodes[2].y + hip_above)
	elif d.state == "recovering":
		ref = {"clip": "targetClinch", "frame": maxi(0, 4 - int(floor(d.recovery / 92.0)))}
	ref.y = y
	return ref
