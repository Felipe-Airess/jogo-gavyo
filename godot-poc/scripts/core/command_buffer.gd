extends RefCounted
## Port of src/core/command-buffer.mjs. All times in milliseconds.
const BUFFER_MS := 134.0
const CHAIN_BUFFER_MS := 400.0
var window := BUFFER_MS
var command: Variant = null

func _init(window_ms := BUFFER_MS) -> void:
	window = window_ms

func push(value: Dictionary, now: float) -> void:
	command = value.duplicate(true)
	command.at = now

func peek(now: float, window_ms := -1.0) -> Variant:
	var limit := window if window_ms < 0 else window_ms
	if command != null and now - float(command.at) > limit:
		if limit >= window:
			command = null
		return null
	return command

func take(now: float) -> Variant:
	var value: Variant = peek(now)
	command = null
	return value

func clear() -> void:
	command = null

static func from_input(input: Dictionary, facing: int) -> Variant:
	var direction := int(bool(input.get("right", false))) - int(bool(input.get("left", false)))
	var kind := "grab" if input.get("grab", false) else ("kick" if input.get("kick", false) else ("attack" if input.get("attack", false) else ""))
	if kind.is_empty():
		return null
	return {"kind": kind, "forward": direction != 0 and direction == facing,
		"back": direction != 0 and direction == -facing, "up": bool(input.get("up", false)),
		"down": bool(input.get("down", false)), "run": bool(input.get("run", false))}
