extends SceneTree
## Verifica o arquivo realmente importado pelo Godot, incluindo poses avaliadas.

func _initialize() -> void:
	call_deferred("_testar")

func _testar() -> void:
	var manifesto: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://miguel_animacoes.json"))
	var cena: PackedScene = load("res://miguel_animado.glb")
	var modelo := cena.instantiate()
	root.add_child(modelo)
	var ap := modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var esqueletos := modelo.find_children("*", "Skeleton3D", true, false)
	assert(ap != null and esqueletos.size() == 1)
	var rig := esqueletos[0] as Skeleton3D
	assert(rig.get_bone_count() == 22)
	var resultados := {}
	for nome in manifesto:
		assert(ap.has_animation(nome), "Animação ausente: " + nome)
		var anim := ap.get_animation(nome)
		assert(absf(anim.length - float(manifesto[nome]["duracaoMs"]) / 1000.0) < 0.04, nome)
		assert(anim.get_track_count() > 0, nome)
		ap.play(nome)
		for proporcao in [0.0, 0.25, 0.5, 0.75, 1.0]:
			ap.seek(anim.length * proporcao, true)
			rig.force_update_all_bone_transforms()
			for osso in rig.get_bone_count():
				var pose := rig.get_bone_global_pose(osso)
				assert(pose.is_finite(), "Pose inválida: " + nome)
		resultados[nome] = {"segundos": anim.length, "canais": anim.get_track_count(), "poses_finitas": 5}
	var arquivo := FileAccess.open("res://../arte/revisoes/miguel-animacoes-20261101/godot.json", FileAccess.WRITE)
	# O resultado também vai para stdout, para uso em CI.
	if arquivo != null:
		arquivo.store_string(JSON.stringify(resultados, "  ") + "\n")
	print("ANIMACOES_OK ", manifesto.size(), " / OSSOS ", rig.get_bone_count())
	modelo.queue_free()
	quit(0)
