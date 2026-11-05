extends SceneTree
const MODELS=preload("res://capitulo1/modelos_definitivos.gd")
var passed:=0
var failed:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 if ok: passed+=1;print("PASS ",label)
 else: failed+=1;print("FAIL ",label)
func run() -> void:
 var gallery=load("res://capitulo1/galeria.tscn").instantiate();root.add_child(gallery)
 gallery.set_process(false)
 for index in MODELS.list().size():
  gallery.show_model(index)
  var info=MODELS.list()[index]
  check(gallery.model!=null,info.id+" carrega")
  var expected=["Hips","Spine","Chest","UpperChest","Neck","Head","LeftUpperArm","RightUpperArm","LeftHand","RightHand","LeftFoot","RightFoot"]
  check(expected.all(func(name):return gallery.rig.find_bone(name)>=0),info.id+" esqueleto mapeado")
  var box=MODELS.bounds(gallery.model)
  check(absf(box.size.y*gallery.model.scale.y-float(info.altura))<.015,info.id+" altura informada por Felipe")
  check(absf(box.position.y*gallery.model.scale.y+gallery.model.position.y)<.015,info.id+" chão na pose de referência")
  var lengths_ok=true
  var all_clips=true
  var animated=false
  var hand=gallery.rig.find_bone("RightHand")
  if hand<0: continue
  for name in MODELS.NEW.get_animation_list():
   gallery.play_clip(name)
   for frame in 20: gallery.tree.advance(.02)
   if name in ["Sprint","Crouch_Fwd","Agarrar","Death01"]:
    await process_frame
    await process_frame
    var originals=gallery.model.find_children("OriginalSkeleton","Skeleton3D",true,false)
    var skin_rig=gallery.rig if originals.is_empty() else originals[0]
    for pair in [["LeftUpperArm","LeftLowerArm"],["LeftLowerArm","LeftHand"],["RightUpperArm","RightLowerArm"],["RightLowerArm","RightHand"],["LeftUpperLeg","LeftLowerLeg"],["LeftLowerLeg","LeftFoot"],["RightUpperLeg","RightLowerLeg"],["RightLowerLeg","RightFoot"]]:
     var a=skin_rig.find_bone(pair[0]);var b=skin_rig.find_bone(pair[1])
     var reference=skin_rig.get_bone_global_rest(a).origin.distance_to(skin_rig.get_bone_global_rest(b).origin)
     var posed=skin_rig.get_bone_global_pose(a).origin.distance_to(skin_rig.get_bone_global_pose(b).origin)
     lengths_ok=lengths_ok and absf(posed-reference)<maxf(.002,reference*.02)
   var position=gallery.playback.get_current_play_position()
   all_clips=all_clips and position>0
   if name=="Walk":
    var before=gallery.rig.get_bone_global_pose(hand)
    gallery.tree.advance(.2)
    animated=before.origin.distance_to(gallery.rig.get_bone_global_pose(hand).origin)>.001
  check(all_clips,info.id+" todos os clipes avançam na máquina")
  check(lengths_ok,info.id+" correr/agachar/agarrar/morrer preservam comprimentos no rig da skin")
  check(animated,info.id+" Walk altera a pose pelo AnimationTree")
  var textures=true
  for visual in gallery.model.find_children("*","MeshInstance3D",true,false):
   for surface in visual.mesh.get_surface_count():
    var material=visual.get_active_material(surface)
    textures=textures and material is StandardMaterial3D and material.albedo_texture!=null and material.albedo_texture.get_width()>0
  check(textures,info.id+" texturas StandardMaterial3D carregadas em Compatibility")
 gallery.set_night(true);gallery.set_retro(true)
 check(gallery.lamp.visible and gallery.container.stretch_shrink==4,"galeria noite/lanterna e filtro")
 var old_yaw=gallery.yaw;gallery.orbit(Vector2(30,0))
 check(gallery.yaw!=old_yaw,"galeria câmera orbita")
 var touch=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=Vector2(400,300);gallery._unhandled_input(touch)
 var drag=InputEventScreenDrag.new();drag.index=0;drag.relative=Vector2(40,0)
 old_yaw=gallery.yaw;gallery._unhandled_input(drag)
 check(gallery.yaw!=old_yaw,"galeria orbita por gesto de toque")
 var before_selection=gallery.selected
 var next_button: Button
 for layer in gallery.get_children():
  if layer is CanvasLayer:
   for button in layer.find_children("*","Button",true,false):
    if button.text=="Próximo ▶": next_button=button
 touch.pressed=true
 next_button.gui_input.emit(touch)
 check(gallery.selected==posmod(before_selection+1,MODELS.list().size()),"botão Próximo atende toque sem emulação de mouse")
 gallery.free()
 var game=load("res://capitulo1/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.set_physics_process(false)
 check(game.player.model.get_meta("modelo_definitivo","")=="miguel","Miguel no papel jogável")
 check(game.enemies.size()==7 and game.enemies.all(func(actor):return actor.model.get_meta("modelo_definitivo","")=="cultista"),"sete postos usam cultista definitivo")
 var event=InputEventKey.new();event.keycode=KEY_F10;event.pressed=true
 game._unhandled_input(event);check(is_instance_valid(game.gallery),"F10 abre galeria em debug")
 check(game.hud.gallery_button!=null,"menu debug oferece botão de galeria no PC/toque")
 game.close_gallery();game.free()
 print("CAPITULO1_MODELOS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
