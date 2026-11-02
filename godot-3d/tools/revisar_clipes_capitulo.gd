extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var lab=load("res://validacao/inicio.tscn").instantiate()
 root.add_child(lab)
 lab.set_physics_process(false)
 lab.set_process(false)
 lab.view.yaw=-.7
 lab.player.face(lab.player.position+Vector3.BACK)
 for name in ["Brutal_Assassination","Hell_Slammer_A","Knee_Jab","pesado"]:
  lab.player.anim.play(name,0)
  lab.player.anim.seek(lab.player.anim.get_animation(name).length*.55,true)
  lab.player.rig.force_update_all_bone_transforms()
  lab.view.update(1)
  lab.label.text=name
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../work/clipe-"+name+".png"))
 quit()
