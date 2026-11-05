extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var gallery=load("res://capitulo1/galeria.tscn").instantiate();root.add_child(gallery);gallery.set_process(false)
 var folder=ProjectSettings.globalize_path("res://../arte/revisoes/definitivos/godot/")
 DirAccess.make_dir_recursive_absolute(folder)
 for index in ([5] if "--apenas-miguel" in OS.get_cmdline_user_args() else range(gallery.MODELS.list().size())):
  gallery.show_model(index);gallery.set_night(false);gallery.set_retro(false)
  var id=gallery.MODELS.list()[index].id
  for view in ([] if "--somente-morte" in OS.get_cmdline_user_args() else [["frente",0.0],["lado",PI/2],["costas",PI]]):
   gallery.yaw=view[1]
   for filtered in [false,true]:
    gallery.set_retro(filtered);gallery.set_night(false)
    gallery._process(.3)
    await process_frame;await process_frame;await RenderingServer.frame_post_draw
    var image=root.get_texture().get_image() if filtered else gallery.viewport.get_texture().get_image()
    if filtered: image.resize(960,640,Image.INTERPOLATE_NEAREST)
    image.save_png(folder+id+"_"+view[0]+("_retro" if filtered else "_neutro")+".png")
  gallery.yaw=0;gallery.set_retro(false)
  for clip in (["Death01"] if "--somente-morte" in OS.get_cmdline_user_args() else ["Sprint","Crouch_Fwd","Agarrar","Death01"]):
   gallery.yaw=.7 if clip=="Death01" else 0.0
   gallery.pitch=.7 if clip=="Death01" else .12
   gallery.distance=float(gallery.MODELS.list()[index].altura)*(2.3 if clip=="Death01" else 1.8)
   gallery.play_clip(clip)
   var duration=gallery.MODELS.NEW.get_animation(clip).length*.92 if clip=="Death01" else .7
   for frame in ceili(duration*60):
    gallery._process(1.0/60.0)
    await process_frame
   await process_frame;await process_frame;await RenderingServer.frame_post_draw
   gallery.viewport.get_texture().get_image().save_png(folder+id+"_"+clip+".png")
  gallery.yaw=0;gallery.pitch=.12;gallery.distance=float(gallery.MODELS.list()[index].altura)*1.8
  gallery.play_clip("Idle");gallery.set_night(true);gallery._process(.3)
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  gallery.viewport.get_texture().get_image().save_png(folder+id+"_noite.png")
  print("CAPTURA_DEFINITIVO ",id)
 gallery.free();quit()
