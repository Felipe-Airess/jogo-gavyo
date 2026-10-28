extends RefCounted
## Complete source atlases. No animation substitution, invented box or rescaling.
var characters: Dictionary = {}

func _init() -> void:
	for character in ["sorriso", "miguel"]:
		characters[character] = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/%s.json" % character))

func clip(character: String, id: String) -> Dictionary:
	return characters.get(character, {}).get("clips", {}).get(id, {})

func frame_at(character: String, id: String, milliseconds: float, loop := true) -> int:
	var animation := clip(character, id)
	if animation.is_empty():
		return -1
	var durations: Array = animation.get("durations", [])
	if durations.is_empty():
		return 0
	var total := 0.0
	for duration in durations:
		total += float(duration)
	var elapsed := fmod(maxf(0, milliseconds), total) if loop and total > 0 else maxf(0, milliseconds)
	for i in durations.size():
		elapsed -= float(durations[i])
		if elapsed < 0:
			return i
	return durations.size() - 1

func marker(character: String, id: String, frame: int) -> Dictionary:
	var frames: Array = characters.get(character, {}).get("markers", {}).get(id, [])
	return frames[frame] if frame >= 0 and frame < frames.size() else {}

func atlas_region(character: String, id: String, frame: int) -> Rect2:
	var animation := clip(character, id)
	if animation.is_empty() or frame < 0 or frame >= animation.frames.size():
		return Rect2()
	var data: Dictionary = characters[character]
	var index := int(animation.frames[frame].index)
	var cell := Vector2(data.frame[0], data.frame[1])
	return Rect2(Vector2(index % int(data.columns), floori(float(index) / float(data.columns))) * cell, cell)

func world_hurtboxes(character: String, id: String, frame: int, position: Vector2, facing: int, arms := false) -> Dictionary:
	var out := {}
	for zone in marker(character, id, frame).get("hurt", {}):
		if zone == "arms" and not arms:
			continue
		var target: String = "body" if zone == "arms" else zone
		if not out.has(target):
			out[target] = []
		for box in marker(character, id, frame).hurt[zone]:
			var a := position.x + float(box[0]) * facing
			var b := position.x + float(box[2]) * facing
			out[target].append(Rect2(minf(a, b), position.y + float(box[1]), absf(b - a), float(box[3]) - float(box[1])))
	return out
