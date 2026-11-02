extends SceneTree
## Só lê recursos; relatório fica em work, fora das fontes do jogo.
func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var model=load("res://miguel_animado.glb").instantiate()
 root.add_child(model)
 var ap: AnimationPlayer=model.find_child("AnimationPlayer",true,false)
 var report={"glb":"godot-3d/miguel_animado.glb","clips":[],"prototipo":[]}
 for name in ap.get_animation_list():
  var clip=ap.get_animation(name)
  report["clips"].append({"nome":name,"segundos":clip.length,"trilhas":clip.get_track_count(),"loop":clip.loop_mode})
 var library: AnimationLibrary=load("res://prototipo/motions.tres")
 for name in library.get_animation_list():
  var clip=library.get_animation(name)
  report["prototipo"].append({"nome":name,"segundos":clip.length,"trilhas":clip.get_track_count()})
 var path=ProjectSettings.globalize_path("res://../work/inventario-animacoes.json")
 var output=FileAccess.open(path,FileAccess.WRITE)
 if output==null:
  push_error("Não foi possível gravar inventário: "+path)
  quit(1)
  return
 output.store_string(JSON.stringify(report,"  ")+"\n")
 print(JSON.stringify(report))
 model.free()
 quit()
