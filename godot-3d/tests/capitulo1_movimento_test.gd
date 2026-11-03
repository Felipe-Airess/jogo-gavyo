extends SceneTree
## Só mede. A referência é a própria trilha original, avaliada sem escrever no rig.
const DT:=1.0/60
const BONES:=["LeftHand","RightHand","LeftFoot","RightFoot"]
var game: Node3D
var passed:=0
var failed:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 if ok: passed+=1; print("PASS ",label)
 else: failed+=1; print("FAIL ",label)
func points(actor) -> Array[Vector3]:
 var result: Array[Vector3]=[]
 for name in BONES: result.append(actor.bone_point(name))
 return result
func move(actor,speed: float,crouched: bool) -> void:
 actor.crouched=crouched; actor.velocity=Vector3.BACK*speed
 actor.face(actor.position+Vector3.BACK)
 actor.play("correr" if speed>2 else "andaFrente" if speed>0 else "guarda")
 actor._slide(DT); actor.animate(DT)
func graph_clip(actor) -> String:
 return String(actor.motion.machine.get_node(actor.motion.playback.get_current_node()).get_node("Clipe").animation)
func original_pose(actor,endpoint:=false) -> Vector2:
 var rig: Skeleton3D=actor.rig
 var clip: Animation=actor.anim.get_animation(graph_clip(actor))
 var time=fposmod(actor.motion.position(),clip.length)
 var positions: Array[Vector3]=[]; var rotations: Array[Quaternion]=[]
 for i in rig.get_bone_count():
  positions.append(rig.get_bone_rest(i).origin)
  rotations.append(rig.get_bone_rest(i).basis.get_rotation_quaternion())
 for t in clip.get_track_count():
  var id=rig.find_bone(String(clip.track_get_path(t)).get_slice(":",1))
  if id<0: continue
  match clip.track_get_type(t):
   Animation.TYPE_POSITION_3D: positions[id]=(clip.track_get_key_value(t,clip.track_get_key_count(t)-1) if endpoint else clip.position_track_interpolate(t,time))*rig.motion_scale
   Animation.TYPE_ROTATION_3D: rotations[id]=clip.track_get_key_value(t,clip.track_get_key_count(t)-1) if endpoint else clip.rotation_track_interpolate(t,time)
 var error:=Vector2.ZERO
 for i in rig.get_bone_count():
  error.x=maxf(error.x,positions[i].distance_to(rig.get_bone_pose_position(i)))
  error.y=maxf(error.y,1-absf(rotations[i].normalized().dot(rig.get_bone_pose_rotation(i).normalized())))
 # Na emenda, o playback já pode informar zero enquanto o mixer avaliou
 # o último quadro. Ambos os candidatos são quadros originais, só leitura.
 if not endpoint and time<.000001 and clip.loop_mode==Animation.LOOP_LINEAR:
  var last=original_pose(actor,true)
  if last.x+last.y<error.x+error.y: return last
 return error
func transitions(actor) -> void:
 actor.position=Vector3(200,0,200); actor.state="idle"; actor.crouched=false; actor.velocity=Vector3.ZERO
 actor.play("guarda")
 for i in 30: actor.animate(DT)
 var previous=points(actor)
 for data in [[1.45,false],[3.8,false],[0.0,false],[1.05,true],[0.0,true],[1.45,false]]:
  var maximum:=0.0; var saw_fade:=false
  for i in 24:
   move(actor,data[0],data[1])
   saw_fade=saw_fade or not String(actor.motion.playback.get_fading_from_node()).is_empty()
   var now=points(actor)
   for j in BONES.size(): maximum=maxf(maximum,now[j].distance_to(previous[j]))
   previous=now; await physics_frame
  print("TRANSICAO velocidade=%.2f agachado=%s salto_medido=%.4f m"%[data[0],data[1],maximum])
  check(saw_fade,"troca de locomoção usa crossfade real da máquina")
  if maximum>.08: print("AVISO amplitude da pose original/transição supera 8 cm; não limitar ossos")
 var invalid:=0
 for i in actor.motion.machine.get_transition_count():
  var from=String(actor.motion.machine.get_transition_from(i)); var to=String(actor.motion.machine.get_transition_to(i))
  var flat=from in actor.motion.FLAT and to in actor.motion.FLAT
  var time=actor.motion.machine.get_transition(i).xfade_time
  if (flat and absf(time-.15)>.0001) or (not flat and (time<.20 or time>.25)): invalid+=1
 check(invalid==0,"arestas: 0,15 s no plano e 0,20–0,25 s em ações/escada")
func native_cycle(actor,speed: float,crouched: bool,label: String) -> void:
 actor.position=Vector3(220 if actor.enemy else 200,0,200); actor.state="idle"
 # Os antigos ajustes de ferido, cabeça, apoio e ferramentas também devem ficar inativos.
 actor.health=40; actor.tool_pose=true; actor.activity="ritual"
 for i in 40: move(actor,speed,crouched); await physics_frame
 var anchors: Dictionary={}; var worst:=0.0; var support_frames:=0
 var exact:=true; var changed:=0; var correct:=0
 var time: float=actor.motion.position()
 var expected="novo/Crouch_Fwd" if crouched else "novo/Sprint" if speed>2 else "novo/Walk"
 var error:=Vector2.ZERO
 for i in 180:
  move(actor,speed,crouched)
  var current: float=actor.motion.position()
  if absf(current-time)>.000001: changed+=1
  time=current
  if graph_clip(actor)==expected: correct+=1
  var delta=original_pose(actor); error.x=maxf(error.x,delta.x); error.y=maxf(error.y,delta.y)
  exact=exact and delta.x<.0001 and delta.y<.00001
  for side in ["Left","Right"]:
   var foot: Vector3=actor.bone_point(side+"Foot")
   if absf(foot.y-actor.motion.foot_clearance-actor.position.y)<.05:
    if not anchors.has(side): anchors[side]=foot
    else: worst=maxf(worst,foot.distance_to(anchors[side])); support_frames+=1
   else: anchors.erase(side)
  await physics_frame
 print("ORIGINAL %s clipe=%s certo=%d/180 avanca=%d/180 erro_pos=%.7f erro_rot=%.7f apoio=%d deriva=%.4f m"%[label,expected,correct,changed,error.x,error.y,support_frames,worst])
 check(correct==180 and changed==180,label+": clipe correto avança sem congelar")
 check(exact,label+": todos os ossos coincidem com as trilhas originais")
 if worst>.03 or support_frames==0: print("AVISO ",label,": deriva/contato original registrado; nenhuma correção de pose")
 actor.health=100; actor.tool_pose=false; actor.activity=""
func stairs(up: bool,running: bool) -> void:
 var actor=game.player
 var a: Vector3=game.school.stairs_bottom; var b: Vector3=game.school.stairs_top
 var direction=((b-a)*Vector3(1,0,1)).normalized()*(1 if up else -1)
 actor.position=(a if up else b)+direction*.7
 actor.position.y=game.school.LEVEL*(.7/Vector2(b.x-a.x,b.z-a.z).length() if up else 1-.7/Vector2(b.x-a.x,b.z-a.z).length())
 actor.state="idle"; actor.crouched=false; actor.face(actor.position+direction)
 var expected="novo/Running_Up_Stairs" if up and running else "novo/Ascending_Stairs" if up else "novo/Descending_Stairs"
 var correct:=0; var changed:=0; var native:=true; var time:=-1.0
 var worst:=Vector2.ZERO; var last_state:=""
 for i in 160:
  actor.velocity=direction*(3.8 if running else 1.45)
  actor.play("correr" if running else "andaFrente"); actor._slide(DT); actor.animate(DT)
  if i>30:
   if graph_clip(actor)==expected: correct+=1
   if absf(time-actor.motion.position())>.000001 or String(actor.motion.playback.get_current_node())!=last_state or not String(actor.motion.playback.get_fading_from_node()).is_empty(): changed+=1
   # No intervalo de crossfade, a pose é a mistura legítima de dois clipes.
   if String(actor.motion.playback.get_fading_from_node()).is_empty():
    var error=original_pose(actor); native=native and error.x<.0001 and error.y<.00001
    worst.x=maxf(worst.x,error.x); worst.y=maxf(worst.y,error.y)
  time=actor.motion.position(); last_state=String(actor.motion.playback.get_current_node()); await physics_frame
 print("ESCADA_ORIGINAL sobe=%s corre=%s clipe=%s correto=%d/129 avanca=%d/129 erro=%s"%[up,running,expected,correct,changed,worst])
 check(correct==129 and changed==129,"escada: captura correta, em movimento")
 check(native,"escada: pose original fora do crossfade")
func camera_checks() -> void:
 var view=game.view; var enemy=game.enemies[1]
 var start:=Vector3(200,1.4,200); var desired:=Vector3(200,1.5,202.5)
 enemy.position=(start+desired)*.5-Vector3.UP*.8; enemy.collision_layer=2
 for i in 3: await physics_frame
 check(view._collision_camera(start,desired).distance_to(desired)<.001,"câmera ignora corpo de cultista na camada 2")
 var wall=StaticBody3D.new(); wall.collision_layer=1
 var shape=CollisionShape3D.new(); var box=BoxShape3D.new(); box.size=Vector3(2,3,.2); shape.shape=box
 wall.position=(start+desired)*.5; wall.add_child(shape); game.add_child(wall)
 for i in 3: await physics_frame
 check(view._collision_camera(start,desired).distance_to(start)<desired.distance_to(start)-.1,"câmera colide com cenário da camada 1")
 wall.queue_free(); await physics_frame
 view.mode="third_person"; view.camera.global_position=desired
 enemy.position=desired+Vector3(0,-1.3,-.25); enemy.model.visible=true
 view._update_occluders()
 check(not enemy.model.visible,"cultista junto da lente fica oculto")
 enemy.position=Vector3(230,0,230); view._update_occluders()
 check(enemy.model.visible,"cultista volta a aparecer ao se afastar da lente")
 game.player.model.visible=false; view._update_occluders()
 check(not game.player.model.visible,"oclusão não revela Miguel na câmera em primeira pessoa")
 game.player.model.visible=true
func run() -> void:
 var deadline=create_timer(150,true,false,true)
 deadline.timeout.connect(func(): print("FAIL MOVIMENTO TIMEOUT"); quit(2))
 game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_physics_process(false); game.set_process(false); game.qa_mode=true
 for i in 3: await physics_frame
 var floor_body=StaticBody3D.new(); var shape=CollisionShape3D.new(); var box=BoxShape3D.new()
 box.size=Vector3(100,1,100); shape.shape=box; floor_body.position=Vector3(200,-.5,200)
 floor_body.add_child(shape); game.add_child(floor_body)
 game.phase="investigate"; game.started=true; game.paused=false
 await transitions(game.player)
 for actor in [game.player,game.enemies[1]]:
  for data in [[1.45,false],[3.8,false],[1.05,true]]: await native_cycle(actor,data[0],data[1],"cultista" if actor.enemy else "Miguel")
 for up in [true,false]:
  for running in [false,true]: await stairs(up,running)
 await camera_checks()
 check(not game.DODGE_AVAILABLE,"esquiva continua desativada")
 print("CAPITULO1_MOVIMENTO: %d passed, %d failed"%[passed,failed])
 game.queue_free(); await process_frame; quit(1 if failed else 0)
