extends RefCounted
const PULSES := ["attack", "kick", "grab"]
var dt := 1000.0 / 60.0
var max_steps := 6
var accumulator := 0.0
var latched := {}
var alpha := 0.0
var ticks := 0

func reset() -> void:
	accumulator = 0
	latched.clear()
	alpha = 0
	ticks = 0

func advance(milliseconds: float, input: Dictionary, tick: Callable) -> int:
	for key in PULSES:
		if input.get(key, false):
			latched[key] = true
	accumulator += clampf(milliseconds, 0, dt * max_steps)
	var steps := 0
	while accumulator >= dt - 0.000001:
		var sample := input.duplicate()
		for key in PULSES:
			sample[key] = bool(latched.get(key, false))
		latched.clear()
		tick.call(sample, dt)
		accumulator -= dt
		steps += 1
		ticks += 1
	alpha = clampf(accumulator / dt, 0, 1)
	return steps
