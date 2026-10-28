extends SceneTree
const Damage = preload("res://scripts/core/damage.gd")
const Buffer = preload("res://scripts/core/command_buffer.gd")
const Collision = preload("res://scripts/core/collision.gd")
const Library = preload("res://scripts/character_library.gd")
const Match = preload("res://scripts/core/match.gd")
const Step = preload("res://scripts/core/fixed_step.gd")
const Moves = preload("res://scripts/core/moves.gd")
var checks := 0
var failures := 0

func same(a: Variant, b: Variant) -> bool:
	if (a is float or a is int) and (b is float or b is int):
		return absf(float(a) - float(b)) < 0.000001
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key in a:
			if not b.has(key) or not same(a[key], b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not same(a[i], b[i]): return false
		return true
	return a == b

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if failures < 10: printerr(label)

func vec(value: Dictionary) -> Vector2:
	return Vector2(value.x, value.y)

func _initialize() -> void:
	var fixtures: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/parity.json"))
	for f in fixtures.damage:
		var result := Damage.resolve_hit(f.move, f.defender, f.zone, f.options)
		check(same(result, f.result), "Damage mismatch %s" % str(f))
		var defender: Dictionary = f.defender.duplicate(true)
		Damage.apply_hit(defender, result)
		check(same(defender, f.after), "Damage application mismatch")
	for f in fixtures.commands:
		check(same(Buffer.from_input(f.input, int(f.facing)), f.result), "Relative command mismatch")
	for f in fixtures.sweeps:
		check(same(Collision.sweep(vec(f.a), vec(f.b), Vector2(f.half[0], f.half[1]), Rect2(f.box.x, f.box.y, f.box.w, f.box.h)), f.result), "Sweep mismatch")
	for f in fixtures.quality:
		check(Damage.contact_quality(f.coverage) == f.result, "Quality mismatch")
	var library := Library.new()
	var specs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/specs.json"))
	for character in fixtures.moves:
		var moves := Moves.create_moves(library.characters[character].clips, specs[character])
		for id in fixtures.moves[character]:
			check(same(moves.get(id), fixtures.moves[character][id]), "Move table mismatch %s/%s" % [character, id])
	for character in library.characters:
		for id in library.characters[character].clips:
			var clip: Dictionary = library.clip(character, id)
			for i in clip.frames.size():
				check(library.atlas_region(character, id, i).has_area(), "Missing atlas frame")
			check(library.frame_at(character, id, 0) == 0, "Animation first frame")
	check(library.marker("miguel", "missing", 0).is_empty(), "Missing markers must stay absent")
	var buffer := Buffer.new()
	buffer.push({"kind": "attack"}, 0)
	check(buffer.peek(134) != null and buffer.peek(135) == null, "Buffer expiry")
	buffer.push({"kind": "attack"}, 0)
	check(buffer.peek(399, 400) != null, "Combo buffer window")
	var match_model := Match.new({"bestOf": 1, "seconds": 60})
	check(match_model.update(1700, {}) == "fight", "Round intro closes commands")
	match_model.update(16, {"result": {"winner": 1, "reason": "test"}})
	check(match_model.over and match_model.winner == 1, "Round KO")
	check(match_model.update(2600, {}) == "over", "Match completion")
	var step := Step.new()
	var sampled: Array = []
	step.advance(5, {"attack": true}, func(input, _dt): sampled.append(input))
	step.advance(30, {}, func(input, _dt): sampled.append(input))
	check(sampled.size() == 2 and sampled[0].attack and not sampled[1].attack, "Pulse latch across render frames")
	print("Native parity: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
