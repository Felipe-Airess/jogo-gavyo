extends RefCounted
## Efeitos de impacto (port de impact-fx.mjs): faísca, poeira, tremida, clarão,
## câmera lenta no nocaute, sangue pela região e força, marcas no rosto.
## A intensidade vem dos eventos do duelo: o efeito comunica o que a regra decidiu.
const SPARK := {1: 5, 2: 7, 3: 10}
const SHAKE := {"block": 0.6, 1: 1.0, 2: 1.7, 3: 2.6, "ko": 4.0}
const PARRY_COLOR := Color8(0x9f, 0xd0, 0xff)

var blood
var sparks: Array = []
var dust: Array = []
var shake_t := 0.0
var shake_amp := 0.0
var flash_t := 0.0
var flash_alpha := 0.0
var slow_t := 0.0
var clock := 0.0
var last_id := 0
var drip_at := {}

func _init(blood_model) -> void:
	blood = blood_model

func reset() -> void:
	sparks.clear(); dust.clear(); shake_t = 0; shake_amp = 0; flash_t = 0; flash_alpha = 0; slow_t = 0
	clock = 0; last_id = 0; drip_at.clear()

func time_scale() -> float:
	return 0.35 if slow_t > 0 else 1.0

func shake(amp: float, ms: float) -> void:
	if amp >= shake_amp or shake_t <= 0:
		shake_amp = amp; shake_t = ms

func consume(duel) -> void:
	for e in duel.events:
		if e.id > last_id:
			last_id = e.id
			on_event(e, duel)

func on_event(e: Dictionary, duel) -> void:
	var ground: float = e.get("ground_y", 150.0)
	if e.type == "hit" and e.get("point") != null:
		var target = duel.by_id(e.get("target"))
		var dir: float = -target.facing if target != null else 1.0
		var power: int = 3 if e.kind == "ko" else int(e.get("power", 1))
		burst(e.point, power, e.get("counter", false), dir)
		shake(SHAKE.ko if e.kind == "ko" else SHAKE[power], 320.0 if e.kind == "ko" else 90.0 + power * 50)
		if e.get("counter", false) or e.kind == "ko":
			flash_t = 90.0 if e.kind == "ko" else 50.0
			flash_alpha = 0.45 if e.kind == "ko" else 0.25
		if e.kind == "ko": slow_t = 650.0
		var zone := 3.0 if e.zone == "head" else ((1.2 if power >= 2 else 0.4) if e.zone == "body" else 0.5)
		var scale: float = zone * (1.5 if e.get("counter", false) else 1.0) * (1.5 if power >= 3 else 1.0) * (2.5 if e.kind == "ko" else 1.0)
		if scale > 0:
			blood.emit({"id": e.id, "blood": true, "blocked": false, "zone": e.zone, "point": e.point, "finisher": e.kind == "ko", "dir": dir}, ground, scale)
		if e.zone == "head":
			for i in 3 + power:
				dust.append({"x": e.point.x, "y": e.point.y, "vx": dir * (20 + i * 9), "vy": -18.0 + i * 6, "life": 240.0, "color": Color8(0xd9, 0xd6, 0xc3), "g": 160.0, "size": 1})
	elif ((e.type == "block" and e.get("kind") == "parry") or e.type == "parry") and e.get("point") != null:
		# Aparo: faísca fria com anel e clarão curto — diferente da defesa comum.
		burst(e.point, 2, false, 1, PARRY_COLOR)
		sparks.append({"x": e.point.x, "y": e.point.y, "life": 200.0, "max": 200.0, "ring": true, "color": PARRY_COLOR, "len": 0.0})
		flash_t = 60.0
		flash_alpha = 0.3
		shake(SHAKE[2], 130)
	elif e.type == "block" and e.get("point") != null:
		burst(e.point, 1, false, 1, Color8(0xae, 0xcb, 0x8c))
		shake(SHAKE.block, 70)
	elif e.type == "land":
		puff(e.x, ground, 14 if e.get("ko", false) else 10, 1)
		shake(2.4 if e.get("ko", false) else 1.6, 140)
	elif e.type == "brake" or e.type == "dash":
		var f = duel.by_id(e.fighter)
		var facing: float = f.facing if f != null else 1.0
		if e.type == "brake": puff(e.x + facing * 10, ground, 6, facing)
		else: puff(e.x - facing * 8, ground, 5, -facing)

## Faísca radial; o contra-ataque ganha um anel.
func burst(p: Vector2, power: int, counter: bool, dir: float, color := Color8(0xf0, 0xd9, 0xa0)) -> void:
	var n: int = SPARK[power] + (4 if counter else 0)
	var length := 2.0 + power * 1.5
	for i in n:
		var a := float(i) / n * TAU + (PI if dir < 0 else 0.0) * 0.15
		sparks.append({"x": p.x, "y": p.y, "dx": cos(a), "dy": sin(a), "len": length * (0.6 if i % 2 else 1.0), "life": 80.0 + power * 30, "max": 80.0 + power * 30,
			"color": Color8(0xf0, 0xa0, 0x60) if counter else color, "ring": false})
	if counter or power >= 3:
		sparks.append({"x": p.x, "y": p.y, "life": 140.0, "max": 140.0, "ring": true, "color": Color8(0xf0, 0xa0, 0x60) if counter else Color8(0xe8, 0xdc, 0xc0), "len": 0.0})

func puff(x: float, y: float, n: int, dir: float) -> void:
	n = int(round(n * 1.5))
	for i in n:
		dust.append({"x": x + ((i * 7) % 9) - 4, "y": y - 1, "vx": dir * (6 + (i * 11) % 22) * (1.0 if i % 2 else -0.5), "vy": -6.0 - (i * 5) % 14,
			"life": 380.0 + (i * 37) % 220, "color": Color8(0xb9, 0xb4, 0x9a) if i % 3 else Color8(0x8f, 0x8c, 0x78), "g": 18.0, "size": 2 if i % 2 else 1})

## Tempo real (não acompanha a câmera lenta): os efeitos continuam legíveis.
func step(ms: float, duel) -> void:
	var s := minf(ms, 50.0) / 1000.0
	clock += ms
	shake_t = maxf(0, shake_t - ms)
	flash_t = maxf(0, flash_t - ms)
	slow_t = maxf(0, slow_t - ms)
	for k in sparks: k.life -= ms
	sparks = sparks.filter(func(k): return k.life > 0)
	for d in dust:
		d.x += d.vx * s; d.y += d.vy * s; d.vy += d.g * s; d.vx *= exp(-3 * s); d.life -= ms
	dust = dust.filter(func(d): return d.life > 0)
	if dust.size() > 80: dust = dust.slice(dust.size() - 80)
	# Rosto castigado pinga, mais rápido quanto pior a cabeça.
	if duel != null and blood.enabled:
		for f in duel.fighters:
			if f.condition.head < 45 or f.state in ["knockdown", "down", "ko"]: continue
			var every: float = 1100 - f.condition.head * 7
			var next: float = drip_at.get(f.id, clock + every)
			if clock >= next:
				var face: Variant = face_point(duel, f)
				if face != null: blood.drip(face.x, face.y + 4, f.y)
				drip_at[f.id] = clock + every
			else:
				drip_at[f.id] = next

## Ponto do rosto: frente da cabeça, pelo marcador do quadro atual.
static func face_point(duel, f: Dictionary) -> Variant:
	var w = duel.markers_of(f)
	if w == null or w.head == null: return null
	return Vector2(w.head.x + f.facing * maxf(3, w.headR * 0.5), (w.chin if w.chin != null else w.head.y + 6) - 3)

func offset() -> Vector2:
	if shake_t <= 0: return Vector2.ZERO
	var k := shake_amp * minf(1.0, shake_t / 120.0)
	return Vector2(round(sin(clock * 0.9) * k), round(cos(clock * 1.3) * k * 0.6))

func render(ci: CanvasItem) -> void:
	for k in sparks:
		var t: float = k.life / k.max
		var c: Color = k.color
		c.a = minf(1.0, t * 1.6)
		if k.ring:
			ci.draw_arc(Vector2(k.x, k.y), 3 + (1 - t) * 8, 0, TAU, 16, c, 1.0)
			continue
		var r0 := 2 + (1 - t) * 3
		var r1: float = r0 + k.len
		ci.draw_line(Vector2(k.x + k.dx * r0, k.y + k.dy * r0), Vector2(k.x + k.dx * r1, k.y + k.dy * r1), c, 1.0)
	for d in dust:
		var c2: Color = d.color
		c2.a = minf(0.85, d.life / 300.0)
		ci.draw_rect(Rect2(round(d.x), round(d.y), d.size, d.size), c2)

## Marcas no rosto: aparecem conforme o castigo da cabeça e acompanham o quadro.
func render_wounds(ci: CanvasItem, duel) -> void:
	if not blood.enabled: return
	var spots := [[0, 0], [-2, -4], [1, 2], [-3, 1], [-1, -6]]
	for f in duel.fighters:
		var level := mini(5, int(floor(f.condition.head / 18.0)))
		if level == 0 or f.state in ["knockdown", "down", "ko", "getup"]: continue
		var face: Variant = face_point(duel, f)
		if face == null: continue
		for i in level:
			var color := Color8(0x7f, 0x24, 0x25) if i % 2 else Color8(0xa3, 0x3a, 0x33)
			ci.draw_rect(Rect2(round(face.x + spots[i][0] * f.facing), round(face.y + spots[i][1]), 2 if i == 0 else 1, 3 if i == 0 else (2 if i == 2 else 1)), color)

func render_flash(ci: CanvasItem, size: Vector2) -> void:
	if flash_t <= 0: return
	ci.draw_rect(Rect2(Vector2.ZERO, size), Color(Color8(0xf3, 0xea, 0xd2), flash_alpha * (flash_t / 90.0)))
