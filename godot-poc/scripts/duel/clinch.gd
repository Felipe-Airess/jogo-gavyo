extends RefCounted
## Port de src/duel/clinch.mjs. Entrada pelo alcance do agarrão; quem segura
## arrasta e bate gastando fôlego; quem é segurado enche a barra de escape.
const CLINCH := {"gap": 22.0, "approach": 70.0, "entry": 200.0, "grip": 2600.0, "maxGrip": 3600.0, "refresh": 500.0,
	"drag": 20.0, "dragCost": 6.0, "pulseEscape": 16.0, "holdEscape": 25.0, "pulseCost": 2.0, "breakPush": 60.0, "missMs": 300.0}
## Distância por quem segura: a joelhada do Miguel só alcança a 20 px ou menos.
const CLINCH_GAP := {"miguel": 20.0}

static func start_clinch(a: Dictionary, d: Dictionary) -> void:
	a.state = "clinchEntry"; a.t = 0.0; a.vx = 0.0; a.gait = 0.0
	a.clinch = {"role": "control", "partner": d.id, "grip": CLINCH.grip, "gap": CLINCH_GAP.get(a.character, CLINCH.gap)}
	d.state = "held"; d.t = 0.0; d.vx = 0.0; d.move = null
	d.clinch = {"role": "held", "partner": a.id, "escape": 0.0}
	a.buffer.clear(); d.buffer.clear()

static func end_clinch(a: Variant, d: Variant, how := "") -> void:
	for f in [a, d]:
		if f == null:
			continue
		f.clinch = null
		if f.state in ["clinchEntry", "clinch", "clinchStrike", "held"]:
			f.from = f.state; f.state = "idle"; f.t = 0.0; f.move = null
	if how == "escape" and a != null and d != null:
		a.vx = -a.facing * CLINCH.breakPush
		d.vx = -d.facing * CLINCH.breakPush

static func keep_gap(a: Dictionary, d: Dictionary, dt: float) -> void:
	var s := dt / 1000.0
	var gap: float = a.clinch.gap if a.clinch != null and a.clinch.has("gap") else CLINCH.gap
	var target: float = a.x + a.facing * gap
	var step: float = CLINCH.approach * s
	if a.state == "clinchEntry":
		var error: float = d.x - target
		var move := clampf(error / 2.0, -step, step)
		a.x += move; d.x -= move
	else:
		d.x += clampf(target - d.x, -step, step)

static func escape_gain(d: Dictionary, a: Dictionary) -> float:
	return CLINCH.pulseEscape * clampf((d.stamina + 10.0) / (a.stamina + 20.0), 0.5, 1.6)
