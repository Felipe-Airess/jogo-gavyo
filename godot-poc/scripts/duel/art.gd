extends RefCounted
## Arte e especificações completas dos dois personagens (assets/full/), no
## formato do motor do duelo: {roster: {nome: {clips, markers}}, specs}.
static func load_all() -> Dictionary:
	var roster := {}
	for name in ["sorriso", "miguel"]:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/%s.json" % name))
		roster[name] = {"clips": data.clips, "markers": data.markers, "frame": data.frame, "columns": data.columns}
	var specs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/full/specs.json"))
	return {"roster": roster, "specs": specs}
