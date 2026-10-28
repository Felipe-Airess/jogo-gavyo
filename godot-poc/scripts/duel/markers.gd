extends RefCounted
## Port de src/duel/markers.mjs. Marcadores anatômicos por quadro convertidos
## para o mundo: espelhamento pelo olhar, pivô no pé. Marcador ausente = caixa
## ausente; nenhuma coordenada é inventada.
## Pontos são Vector2 (ou null); caixas são Rect2.

const LIMB_SIZE := {"fist": Vector2(6, 6), "rearFist": Vector2(6, 6), "foot": Vector2(9, 8), "knee": Vector2(10, 10)}

static func to_world(p: Variant, f: Dictionary) -> Variant:
	if p == null or not (p is Dictionary) or p.is_empty():
		return null
	var s := float(f.get("scale", 1.0))
	return Vector2(f.x + float(p.x) * f.facing * s, f.y + float(p.y) * s)

static func tip_of(h: Variant) -> Variant:
	if h == null or not (h is Dictionary) or h.is_empty():
		return null
	return {"x": h.tipX, "y": h.tipY}

## Pontos do quadro atual: cabeça, tronco, quadril, punho/pé/joelho da frente.
static func world_markers(m: Variant, f: Dictionary) -> Variant:
	if m == null or (m is Dictionary and m.is_empty()):
		return null
	var s := float(f.get("scale", 1.0))
	var head: Variant = m.get("head")
	var torso: Variant = m.get("torso")
	var fists: Array = m.get("fists", [])
	var feet: Array = []
	for p in m.get("feet", []):
		feet.append(to_world(tip_of(p), f))
	return {
		"head": to_world(head, f),
		"headR": float(head.get("r", 9) if head is Dictionary and head.get("r") != null else 9) * s,
		"chin": f.y + float(head.chin) * s if head is Dictionary and head.get("chin") != null else null,
		"torso": to_world(torso, f),
		"torsoTop": f.y + float(torso.top) if torso is Dictionary and torso.get("top") != null else null,
		"hip": to_world(m.get("hip"), f),
		"fist": to_world(tip_of(m.get("frontFist")), f),
		"rearFist": to_world(tip_of(fists[0]), f) if fists.size() > 1 else null,
		"foot": to_world(tip_of(m.get("frontFoot")), f),
		"knee": to_world(m.get("frontKnee"), f),
		"feet": feet,
		"hurt": hurt_rects(m.hurt, f) if m.get("hurt") != null else null,
	}

## Retângulos locais [x0,y0,x1,y1) → caixas no mundo, espelhadas pelo olhar.
static func hurt_rects(hurt: Dictionary, f: Dictionary) -> Dictionary:
	var s := float(f.get("scale", 1.0))
	var out := {}
	for zone in hurt:
		var list: Array = []
		for r in hurt[zone]:
			var a: float = f.x + float(r[0]) * f.facing * s
			var b: float = f.x + float(r[2]) * f.facing * s
			list.append(Rect2(minf(a, b), f.y + float(r[1]) * s, absf(b - a), (float(r[3]) - float(r[1])) * s))
		out[zone] = list
	return out

## Hurtboxes por região, sempre listas. Braços só com `arms` (golpe em curso), como tronco.
static func hurtboxes(w: Variant, arms := false) -> Dictionary:
	if w == null:
		return {}
	if w.hurt != null:
		var out := {}
		for zone in w.hurt:
			if zone == "arms":
				continue
			if not w.hurt[zone].is_empty():
				out[zone] = w.hurt[zone]
		if arms and w.hurt.has("arms") and not w.hurt.arms.is_empty():
			out["body"] = out.get("body", []) + w.hurt.arms
		return out
	var one := marker_hurtboxes(w)
	var out2 := {}
	for zone in one:
		out2[zone] = [one[zone]]
	return out2

static func marker_hurtboxes(w: Dictionary) -> Dictionary:
	var out := {}
	if w.head != null:
		var s := maxf(9.0, w.headR * 1.5)
		var top: float = w.head.y - w.headR * 0.75
		var bottom: float = w.chin if w.chin != null else w.head.y + s / 2.0
		out["head"] = Rect2(w.head.x - s / 2.0, top, s, maxf(s * 0.8, bottom - top))
	if w.torso != null and w.hip != null:
		var top2: float = minf(w.torsoTop if w.torsoTop != null else w.torso.y - 8, w.hip.y - 6)
		var cx: float = (w.torso.x + w.hip.x) / 2.0
		out["body"] = Rect2(cx - 8, top2, 16, maxf(6, w.hip.y - top2))
	if w.hip != null and not w.feet.is_empty():
		var x0: float = w.hip.x
		var x1: float = w.hip.x
		var bottom2 := -INF
		for p in w.feet:
			if p == null:
				continue
			x0 = minf(x0, p.x)
			x1 = maxf(x1, p.x)
			bottom2 = maxf(bottom2, p.y)
		out["legs"] = Rect2(x0 - 3, w.hip.y, x1 - x0 + 6, maxf(4, bottom2 + 2 - w.hip.y))
	return out

static func bounds(list: Array) -> Variant:
	if list.is_empty():
		return null
	var r: Rect2 = list[0]
	for b in list:
		r = r.merge(b)
	return r

static func pushbox(f: Dictionary, w: Variant) -> Rect2:
	var x: float = w.hip.x if w != null and w.hip != null else f.x
	return Rect2(x - 8, f.y - 40, 16, 40)

## Zona de guarda: braços à frente da cabeça e do tronco.
static func guard_box(f: Dictionary, w: Variant) -> Variant:
	if w == null or w.head == null or w.hip == null:
		return null
	var front: float = (w.torso.x if w.torso != null else f.x) + f.facing * 4
	var x0 := minf(front, front + f.facing * 14)
	var top: float = w.head.y - w.headR
	return Rect2(x0, top, 14, w.hip.y - top)

## Área de agarrão: à frente do tronco, na altura do peito.
static func grab_box(f: Dictionary, w: Variant) -> Variant:
	if w == null or w.torso == null:
		return null
	var x: float = w.torso.x + f.facing * 6
	return Rect2(minf(x, x + f.facing * 22), w.torso.y - 12, 22, 20)

## Centro da hitbox do membro: a caixa termina na ponta medida.
static func limb_center(tip: Variant, limb: String, facing: int) -> Variant:
	if tip == null:
		return null
	return Vector2(tip.x - facing * LIMB_SIZE[limb].x / 2.0, tip.y)

## Pé de apoio parado (golpes com `plant`): deslocamento por quadro que mantém
## no mesmo lugar do mundo o pé que sustenta o chute (ver markers.mjs).
static func planted_offsets(frames: Array, tol := 14.0) -> Array:
	var ground := func(f: Variant) -> Array:
		var out: Array = []
		if f is Dictionary:
			for p in f.get("feet", []):
				if float(p.tipY) >= -6:
					out.append(float(p.tipX))
		return out
	var g: Array = []
	for f in frames:
		g.append(ground.call(f))
	var zeros: Array = []
	for f in frames:
		zeros.append(0)
	if g.is_empty() or g[0].is_empty():
		return zeros
	var g0: float = g[0].max()
	var single: Array = []
	for k in range(1, g.size()):
		if g[k].size() == 1:
			single.append(k)
	if single.is_empty():
		return zeros
	var a: int = single[0]
	var b: int = single[-1]
	var off: Array = []
	for k in frames.size():
		if k <= a:
			off.append((g0 - g[a][0]) * k / a)
		elif k <= b:
			off.append(g0 - g[k][0] if g[k].size() == 1 else off[k - 1])
		else:
			var best: Variant = null
			for x in g[k]:
				for q0 in g[k - 1]:
					var q: float = q0 + off[k - 1]
					var d := absf(x + off[k - 1] - q)
					if best == null or d < best.d:
						best = {"d": d, "x": x, "q": q}
			off.append(best.q - best.x if best != null and best.d <= tol else off[k - 1])
	var out: Array = []
	for v in off:
		out.append(int(floor(v + 0.5)))
	return out
