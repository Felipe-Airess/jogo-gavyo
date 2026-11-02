extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var lab=load("res://validacao/inicio.tscn").instantiate()
 root.add_child(lab); lab.set_physics_process(false); lab.set_process(false)
 lab.view.yaw=-.9
 lab.player.face(lab.player.position+Vector3.BACK)
 for i in 7:
  lab.player.anim.play("Hell_Slammer_A",0)
  lab.player.anim.seek(.5+i,true)
  lab.player.rig.force_update_all_bone_transforms()
  lab.view.update(1); lab.label.text="Hell Slammer · "+str(.5+i)+" s"
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../work/par-"+str(i)+".png"))
 quit()
