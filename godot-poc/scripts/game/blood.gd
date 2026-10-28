extends RefCounted
## Sangue (port de blood.mjs): gotas com gravidade que viram manchas no chão.
var enabled := true
var particles: Array = []
var marks: Array = []
var max_particles := 220
var max_marks := 140
var mark_life := 1e9
var drop_color := Color8(0xb2, 0x30, 0x2b)
var mark_color := Color8(0x6e, 0x1d, 0x1b)

func reset() -> void:
	particles.clear(); marks.clear()

func emit(hit: Dictionary, ground: float, scale := 1.0) -> void:
	if not enabled or hit.get("blocked", false) or not hit.get("blood", false): return
	var n := int(round((10.0 if hit.get("finisher", false) else (6.0 if hit.zone == "head" else 3.0)) * scale))
	var dir: float = hit.get("dir", 0)
	for i in n:
		var a: float = i * 2.399 + hit.id * 0.7
		var speed := 18.0 + (i * 13) % 37
		particles.append({"x": hit.point.x, "y": hit.point.y, "vx": cos(a) * speed * (0.6 if dir else 1.0) + dir * speed * 0.8,
			"vy": -12 - absf(sin(a)) * 45, "ground": ground + ((i * 5) % 7) - 3 if scale > 1 else ground,
			"life": 1800.0 if scale > 1 else 700.0, "size": 2 if i % 3 == 0 and scale > 1 else 1})
	if particles.size() > max_particles: particles = particles.slice(particles.size() - max_particles)

func drip(x: float, y: float, ground: float) -> void:
	if not enabled: return
	particles.append({"x": x, "y": y, "vx": 0.0, "vy": 8.0, "ground": ground, "life": 1500.0, "size": 1})
	if particles.size() > max_particles: particles.pop_front()

func step(ms: float) -> void:
	var dt := minf(ms, 50.0) / 1000.0
	for p in particles:
		p.x += p.vx * dt; p.y += p.vy * dt; p.vy += 180 * dt; p.life -= ms
		if p.y >= p.ground:
			marks.append({"x": p.x, "y": p.ground, "life": mark_life, "w": 4 if p.size > 1 else 3, "h": 2 if p.size > 1 else 1})
			p.life = 0
	particles = particles.filter(func(p): return p.life > 0)
	for m in marks: m.life -= ms
	marks = marks.filter(func(m): return m.life > 0)
	if marks.size() > max_marks: marks = marks.slice(marks.size() - max_marks)

func render_marks(ci: CanvasItem) -> void:
	if not enabled: return
	for m in marks:
		ci.draw_rect(Rect2(round(m.x) - 1, round(m.y), m.w, m.h), Color(mark_color, 0.95))

func render_particles(ci: CanvasItem) -> void:
	if not enabled: return
	for p in particles:
		ci.draw_rect(Rect2(round(p.x), round(p.y), p.size, p.size), drop_color)
