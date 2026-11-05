extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var args=OS.get_cmdline_user_args()
 if args.is_empty() or not ProjectSettings.load_resource_pack(args[0]):
  push_error("Pacote Web não carregou");quit(1);return
 var catalog=load("res://capitulo1/modelos_definitivos.gd")
 var count=0
 for info in catalog.list():
  var model=catalog.instantiate(info.id)
  root.add_child(model)
  var rig=catalog.skeleton(model)
  assert(rig.find_bone("Head")>=0)
  assert(rig.find_bone("LeftFoot")>=0)
  for mesh in model.find_children("*","MeshInstance3D",true,false):
   for surface in mesh.mesh.get_surface_count():
    var material=mesh.get_active_material(surface)
    assert(material is StandardMaterial3D and material.albedo_texture!=null)
  print("PASS pacote Web: ",info.id," com rig e textura importados")
  count+=1;model.free()
 print("DEFINITIVOS_WEB_PACK: ",count," passed, 0 failed")
 quit()
