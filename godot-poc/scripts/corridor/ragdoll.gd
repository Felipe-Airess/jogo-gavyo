extends RefCounted
## Port de src/ragdoll.mjs: 11 pontos com comprimentos fixos, gravidade e chão.
## Verlet a 120 Hz. Pontos em dicionários {x, y, px, py} (64 bits, como no JS).
const LINKS := [[0, 1], [1, 2], [0, 2], [1, 3], [3, 4], [1, 5], [5, 6], [2, 7], [7, 8], [2, 9], [9, 10]]

var floor_y := 146.0
var accumulator := 0.0
var age := 0.0
var energy := 0.0
var nodes: Array = []
var links: Array = []

static func standing_pose(x: float, y: float, lean := 0.0) -> Array:
	var out: Array = []
	for d in [[lean * 1.3, -43], [lean, -33], [0, -18], [-9 + lean, -27], [-12 + lean, -18], [9 + lean, -26], [12 + lean, -16], [-5, -9], [-8, 0], [5, -9], [8, 0]]:
		out.append({"x": x + d[0], "y": y + d[1]})
	return out

func _init(x: float, y: float, direction := 1.0, speed := 150.0, lift := 130.0, initial_pose: Variant = null) -> void:
	floor_y = y
	var pose: Array = initial_pose if initial_pose != null else standing_pose(x, y, direction * 2)
	for i in pose.size():
		var p: Dictionary = pose[i]
		var vx := direction * (speed + (15.0 if i == 0 else (35.0 if i == 4 or i == 6 else 0.0)))
		var vy := -lift + (25.0 if i >= 7 else 0.0)
		nodes.append({"x": float(p.x), "y": float(p.y), "px": p.x - vx / 120.0, "py": p.y - vy / 120.0})
	for l in LINKS:
		links.append({"a": l[0], "b": l[1], "length": hypot(pose[l[1]].x - pose[l[0]].x, pose[l[1]].y - pose[l[0]].y)})

static func hypot(a: float, b: float) -> float:
	return sqrt(a * a + b * b)

func impulse(direction: float, speed: float, lift: float) -> void:
	for n in nodes:
		n.px -= direction * speed / 120.0; n.py += lift / 120.0

func impulse_at(point: Dictionary, direction: float, speed: float, lift: float) -> void:
	for n in nodes:
		var d := hypot(n.x - point.x, n.y - point.y)
		var weight := exp(-d * d / 320.0)
		n.px -= direction * speed * weight / 120.0; n.py += lift * weight / 120.0

func step(milliseconds: float) -> void:
	accumulator += minf(50.0, maxf(0.0, milliseconds)) / 1000.0
	while accumulator >= 1.0 / 120.0:
		integrate()
		accumulator -= 1.0 / 120.0
		age += 1000.0 / 120.0

func integrate() -> void:
	for n in nodes:
		var vx: float = (n.x - n.px) * 0.996
		var vy: float = (n.y - n.py) * 0.996
		n.px = n.x; n.py = n.y; n.x += vx; n.y += vy + 470.0 / (120.0 * 120.0)
	for iteration in 7:
		for l in links:
			var p: Dictionary = nodes[l.a]
			var q: Dictionary = nodes[l.b]
			var dx: float = q.x - p.x
			var dy: float = q.y - p.y
			var dist := maxf(0.001, hypot(dx, dy))
			var correction: float = (dist - l.length) / dist * 0.5
			p.x += dx * correction; p.y += dy * correction; q.x -= dx * correction; q.y -= dy * correction
		for i in nodes.size():
			var n: Dictionary = nodes[i]
			var radius := 5.0 if i == 0 else (3.0 if i == 1 else 1.0)
			n.x = clampf(n.x, 17.0, 623.0)
			if n.y > floor_y - radius:
				var vx2: float = n.x - n.px
				var vy2: float = n.y - n.py
				n.y = floor_y - radius
				n.px = n.x - vx2 * 0.78
				n.py = n.y + maxf(0.0, vy2) * 0.12
	var total := 0.0
	for n in nodes:
		total += hypot(n.x - n.px, n.y - n.py)
	energy = total / nodes.size()

func center() -> Dictionary:
	return nodes[2]
