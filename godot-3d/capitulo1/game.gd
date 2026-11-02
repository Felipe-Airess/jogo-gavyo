extends "res://prototipo/game.gd"
## Capítulo 1 integrado. Mantém a revisão 2 como referência separada.
const CAMPUS=preload("res://capitulo1/escola.gd")
const PERSON=preload("res://capitulo1/ator.gd")
const CHAPTER_HUD=preload("res://capitulo1/hud.gd")
const CHAPTER_CAMERA=preload("res://capitulo1/camera.gd")
var bag_found:=false
var alert_spread:=false
var video_recorded:=false
var recording:=false
var record_time:=0.0
var phone_light:=false
var flashlight: SpotLight3D
var before_ritual:=false
var fatigue:=0.0
var mouse_held:=false
var hold_clock:=0.0
var hold_consumed:=false
var heavy_attack:=false
var hit_profile: Dictionary={}
var profiles: Dictionary={}
var chain_step:=0
var ground_hits:=0
var carried: Node3D
var carried_body: CharacterBody3D
var tool_active: Dictionary={}
var tool_progress: Dictionary={}
var tool_inventory: Array[String]=[]
var world_objects: Array[Dictionary]=[]
var tools: Array[Dictionary]=[]
var disturbance:=Vector3.ZERO
var disturbance_until:=0.0
var distraction_count:=0
var sighting_seen:=false
var story_clock:=0.0
var ending_clock:=0.0
var ambient_filter: CanvasLayer
var filter_rect: ColorRect
var film_enabled:=true
var tool_prop: Node3D
var gate_from:=Vector3.ZERO
var gate_to:=Vector3.ZERO
var burst_clock:=0.0
var fleeing_return:=false
var ending_set: Node3D
var phone_prop: Node3D
var precise_buffer:=false
var precise_attack:=false
var breathing: AudioStreamPlayer
var sfx: Dictionary={}
var scare_played:=false
var scare_time:=0.0
var silhouette: Node3D
var death_count:=0
var pair_context: Dictionary={}
var spawn_style:=0

func _ready() -> void:
 qa_mode="--qa-inspect" in OS.get_cmdline_user_args()
 lightweight=true
 school=CAMPUS.new()
 add_child(school)
 school.build(self)
 player=spawn_actor(school.spawn,false)
 for at in [school.first_cultist,school.p(323,160),school.p(366,98),school.p(318,83)]:
  var e=spawn_actor(at,true)
  e.face(at+Vector3.FORWARD)
  enemies.append(e)
 # Cada inimigo conserva intenção própria, mas só dois entram no confronto.
 view=CHAPTER_CAMERA.new()
 add_child(view)
 view.setup(self)
 view.yaw=PI/2
 hud=CHAPTER_HUD.new()
 add_child(hud)
 hud.setup(self)
 _audio()
 for name in ["metal","parede","bloqueio","carne","respiracao","susto"]:
  sfx[name]=AudioStreamWAV.load_from_file("res://capitulo1/assets/"+name+".wav")
 breathing=AudioStreamPlayer.new(); breathing.stream=sfx["respiracao"]
 breathing.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD; breathing.stream.loop_end=breathing.stream.data.size()/2
 breathing.volume_db=-80; add_child(breathing); breathing.play()
 cult_audio.position=school.ritual_center
 cult_audio.unit_size=4
 cult_audio.max_distance=26
 var chant=AudioStreamWAV.load_from_file("res://capitulo1/assets/culto.wav")
 chant.loop_mode=AudioStreamWAV.LOOP_FORWARD
 chant.loop_end=chant.data.size()/2
 cult_audio.stream=chant
 cult_audio.pitch_scale=.76
 cult_audio.volume_db=-18
 cult_audio.play()
 flashlight=SpotLight3D.new()
 flashlight.light_color=Color(.88,.90,.78)
 flashlight.light_energy=1.4
 flashlight.spot_range=13
 flashlight.spot_angle=27
 flashlight.shadow_enabled=false
 flashlight.visible=false
 view.camera.add_child(flashlight)
 var hand=BoneAttachment3D.new()
 hand.bone_name="RightHand"
 player.rig.add_child(hand)
 phone_prop=Node3D.new(); phone_prop.visible=false; hand.add_child(phone_prop)
 var visual=MeshInstance3D.new(); var phone_mesh=BoxMesh.new(); phone_mesh.size=Vector3(.075,.012,.14)
 visual.mesh=phone_mesh; var phone_mat=StandardMaterial3D.new(); phone_mat.albedo_color=Color(.04,.075,.10)
 visual.material_override=phone_mat; phone_prop.add_child(visual)
 _postprocess()
 _props()
 silhouette=Node3D.new(); add_child(silhouette)
 for data in [[Vector3(.35,1.2,.23),Vector3(0,.6,0)],[Vector3(.22,.27,.22),Vector3(0,1.38,0)]]:
  var ghost=MeshInstance3D.new(); var shape=BoxMesh.new(); shape.size=data[0]
  ghost.mesh=shape; ghost.material_override=school.mats["dark"]; ghost.position=data[1]; silhouette.add_child(ghost)
 silhouette.position=school.p(323,118)
 silhouette.visible=false
 _measure_moves()
 player.anim.add_animation_library("actions",load("res://capitulo1/acoes.gd").build(player))
 ending_set=load("res://capitulo1/encerramento.gd").new()
 add_child(ending_set)
 ending_set.setup(self)
 if qa_mode:
  var qa=load("res://capitulo1/qa.gd").new()
  add_child(qa); qa.setup(self)
 var perf=load("res://prototipo/performance_monitor.gd").new()
 add_child(perf)
 perf.setup(self)
 _snapshot(false)
 call_deferred("_build_paths")
 # Participantes do ritual são pessoas visíveis, sem acrescentar atacantes à área inicial.
 for i in 3:
  var a=float(i)*TAU/3
  var e=spawn_actor(school.ritual_center+Vector3(sin(a)*2.5,0,cos(a)*1.7),true)
  e.activity="ritual"
  e.face(school.ritual_center)
  school.ritual_figures.append(e)
 if "--capturar-capitulo" in OS.get_cmdline_user_args(): call_deferred("_capture")

func spawn_actor(at: Vector3,is_enemy: bool,big:=false) -> CharacterBody3D:
 var actor=PERSON.new()
 actor.style=spawn_style%3
 spawn_style+=1
 add_child(actor)
 actor.setup(self,at,is_enemy,big)
 return actor

func _postprocess() -> void:
 ambient_filter=CanvasLayer.new()
 ambient_filter.layer=-1
 add_child(ambient_filter)
 filter_rect=ColorRect.new()
 filter_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 filter_rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var mat=ShaderMaterial.new()
 mat.shader=load("res://capitulo1/gravacao.gdshader")
 filter_rect.material=mat
 ambient_filter.add_child(filter_rect)

func _props() -> void:
 for data in [["chave de fenda",school.p(414,256.5,.91)],["alicate",school.p(371,36.5,.91)],["régua",school.p(547,65.5,.91)]]:
  var prop=school.box(Vector3(.035,.035,.28),data[1],"metal",false)
  tools.append({"name":data[0],"at":data[1],"node":prop,"taken":false})
 for at in [school.p(455,300,.12),school.p(320,228,.12),school.p(720,240,.12)]:
  var prop=school.box(Vector3(.20,.24,.20),at,"metal",false)
  world_objects.append({"node":prop,"origin":at,"taken":false})
 # Uso interrompível, sem som atraindo inimigos: reparar luz / abrir caixa de materiais.
 for data in [["luminária","chave de fenda",school.p(306,206,1.2)],["caixa de materiais","alicate",school.p(414,290,.175)],["livros altos","régua",school.p(690,42,1.95)]]:
  var prop=school.box(Vector3(.35,.35,.22),data[2],"wood",false)
  prop.set_meta("use",data[0]); prop.set_meta("tool",data[1])
  prop.set_meta("original_at",data[2])
  school.reactive.append(prop)
  tool_progress[data[0]]=0.0
 school.box(Vector3(.65,.05,.35),school.p(690,42,1.75),"wood",false)

func _measure_moves() -> void:
 # Mede o membro e o instante de extensão no próprio clipe, sem IK de mãos.
 for clip in ["jab","direto","gancho","pesado","Brutal_Assassination","Fist_Fight_A","chuteCircular"]:
  var animation=player.anim.get_animation(clip)
  var best=-1.0
  var data={"clip":clip,"duration":animation.length,"contact":.3,"bone":"RightHand","bias":0.0}
  player.anim.play(clip,0)
  for i in 61:
   var t=animation.length*float(i)/60
   player.anim.seek(t,true)
   player.rig.force_update_all_bone_transforms()
   for bone in (["LeftFoot","RightFoot"] if clip=="chuteCircular" else ["LeftHand","RightHand"]):
    var v: Vector3=player.model.to_local(player.bone_point(bone))
    var center: Vector3=player.model.to_local(player.bone_point("Hips"))
    var reach=Vector2(v.x-center.x,v.z-center.z).length()
    if clip=="Brutal_Assassination": reach=2.0-v.y if t>1.0 and t<4.2 else -2
    if reach>best:
     best=reach
     data["contact"]=t
     data["point"]=v
     data["bone"]=bone
     data["bias"]=-atan2(v.x-center.x,v.z-center.z)
  profiles[clip]=data
 player.anim.stop()
 player.play("guarda")
 player.animate(0)

func begin() -> void:
 started=true
 paused=false
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if qa_mode else Input.MOUSE_MODE_CAPTURED
 if not intro_seen:
  phase="intro"
  intro_clock=0
  player.state="intro"
  player.play("prototype/sit")

func end_intro() -> void:
 intro_seen=true
 phase="investigate"
 player.state="idle"
 player.position=school.spawn
 player.play("guarda")
 view.yaw=PI/2
 for door in school.doors:
  if door.title=="Materiais de esportes":
   var to_door: Vector3=door.position-player.position
   view.yaw=atan2(-to_door.x,-to_door.z)
   break
 player.face(player.position+view.direction())
 hud.say("A bolsa ficou no terceiro de Informática. [Espaço] abre a porta.",5)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE:
   paused=not paused
   mouse_held=false
   Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
   return
  if event.keycode==KEY_ENTER and (not started or phase=="escaped"):
   if phase=="escaped": get_tree().reload_current_scene()
   else: begin()
   return
  if event.keycode==KEY_C and not started:
   load_checkpoint(); begin(); return
  if event.keycode==KEY_R and (paused or player.dead):
   restore_checkpoint(); begin(); return
 if paused or player.dead: return
 if phase in ["intro","sighting","discovery","gate_jump","ending"]:
  # Cenas obrigatórias protegidas; olhar livre durante a observação inicial.
  if event is InputEventMouseMotion and phase=="sighting": view.look_mouse(event.screen_relative)
  return
 if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
  view.look_mouse(event.screen_relative)
 if event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_SPACE: interact()
   KEY_E: heal()
   KEY_Q: takedown_or_finish()
   KEY_F: toggle_peek()
   KEY_L:
    if bag_found: phone_light=not phone_light
   KEY_V: toggle_recording()
   KEY_G: drag_body()
   KEY_T: throw_object()
   KEY_F1: show_help=not show_help
   KEY_F3:
    film_enabled=not film_enabled
    filter_rect.visible=film_enabled
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT:
   if event.pressed:
    if carried!=null: throw_object(); return
    if player.state=="attack":
     if buffered_attack: fatigue=minf(1,fatigue+.17)
     else:
      buffered_attack=true
      precise_buffer=absf(player.clock-float(hit_profile.get("contact",.3)))<.15
     return
    mouse_held=true; hold_clock=0; hold_consumed=false
   else:
    if mouse_held and not hold_consumed: attack()
    mouse_held=false
  elif event.pressed:
   match event.button_index:
    MOUSE_BUTTON_RIGHT:
     _drop_load(); dodge()
    MOUSE_BUTTON_MIDDLE: toggle_lock()
    MOUSE_BUTTON_WHEEL_UP: cycle_target(1)
    MOUSE_BUTTON_WHEEL_DOWN: cycle_target(-1)

func _process(dt: float) -> void:
 if player.dead: player.animate(dt)
 view.update(dt)
 hud.update(dt)
 filter_rect.size=get_viewport().get_visible_rect().size
 flashlight.visible=bag_found and phone_light and not paused
 phone_prop.visible=bag_found and (recording or phone_light)
 player.tool_pose=recording or not tool_active.is_empty()
 burst_clock=maxf(0,burst_clock-dt)
 breathing.volume_db=-26+fatigue*8 if burst_clock>0 else -80
 if silhouette.visible:
  scare_time+=dt
  if scare_time>.2: silhouette.visible=false

func _physics_process(dt: float) -> void:
 if paused or player.dead or phase=="escaped": return
 elapsed+=dt
 simulation_ticks+=1
 school.update(dt,elapsed)
 for e in school.ritual_figures: e.animate(dt)
 if phase=="intro":
  intro_clock+=dt
  player.animate(dt)
  if intro_clock>6.5: end_intro()
  return
 if phase=="sighting":
  story_clock+=dt
  _enemy_ticks(dt)
  if story_clock>3.2:
   phase="investigate"
   sighting_seen=true
  return
 if phase=="discovery":
  discovery_clock+=dt
  player.animate(dt)
  if is_instance_valid(pursuer):
   pursuer.move_toward(player.position, .4 if discovery_clock<3 else 0,dt)
   pursuer.animate(dt)
  if discovery_clock>7.2: end_discovery()
  return
 if phase=="gate_jump":
  story_clock+=dt
  player.clock=story_clock
  var t=clampf(story_clock/2.2,0,1)
  player.position=gate_from.lerp(gate_to,smoothstep(0,1,t))+Vector3.UP*sin(t*PI)*2.55
  player.animate(dt)
  if t>=1:
   phase="ending"; ending_clock=0
   player.state="idle"
  return
 if phase=="ending":
  ending_clock+=dt
  ending_set.update(ending_clock,dt)
  if is_instance_valid(pursuer):
   pursuer.move_toward(school.ritual_approach,3,dt)
   pursuer.animate(dt)
  if ending_clock>14:
   phase="escaped"
   Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
  return
 if impact_pause>0:
  impact_pause=maxf(0,impact_pause-dt); return
 fatigue=maxf(0,fatigue-dt*(.18 if player.state!="attack" else .01))
 if mouse_held and not hold_consumed:
  hold_clock+=dt
  if hold_clock>.42:
   hold_consumed=true; attack(true)
 turn_cooldown=maxf(0,turn_cooldown-dt)
 if not tool_active.is_empty():
  _tool_tick(dt)
 else: _player_tick(dt)
 if protected_target!=null and player.state not in ["attack","pair"]: protected_target=null
 _enemy_ticks(dt)
 _pursuer_tick(dt)
 if player.dead: return
 if is_instance_valid(locked) and (locked.dead or locked.down or phase=="chase" or player.position.distance_to(locked.position)>13): locked=null
 _loads_tick(dt)
 _story_tick(dt)

func _story_tick(dt: float) -> void:
 if phase!="investigate" and phase!="chase": return
 if not bag_found and player.position.distance_to(school.bag_at)<1.7 and player.position.y>2.5:
  hud.say("A bolsa está sobre a mesa. [Espaço] Pegar",1)
 if bag_found and not before_ritual and player.position.distance_to(school.ritual_approach)<3 and player.position.y<1:
  before_ritual=true; checkpoint_index=2; _snapshot()
  hud.say("Checkpoint · algo acontece no pátio de química.",3)
 if not sighting_seen and player.position.distance_to(school.p(442,316))<4 and phase=="investigate":
  phase="sighting"; story_clock=0
  var look: Vector3=enemies[0].position-player.position
  view.yaw=atan2(-look.x,-look.z)
  hud.say("Uma pessoa desconhecida segue para dentro do corredor.",3)
 if recording:
  if not can_frame_ritual():
   recording=false; record_time=0
   hud.say("Mantenha o ritual enquadrado.",2)
  else:
   record_time+=dt
   if record_time>=4.0:
    recording=false; video_recorded=true
    hud.say("Vídeo salvo. Saia pelo portão 1.",4)
    if alert_spread: start_chase()
 if video_recorded and player.position.distance_to(school.gate_at)<2.4:
  _jump_gate()
 if bag_found and not scare_played and player.position.distance_to(school.p(323,205+posmod(death_count,3)*8))<3:
  scare_played=true; scare_time=0; silhouette.visible=true
  view.trauma=.25
  impact_audio.stream=sfx["susto"]; impact_audio.play()

func can_frame_ritual() -> bool:
 if not bag_found or player.position.y>1 or player.hidden: return false
 var at: Vector3=school.ritual_center+Vector3.UP*.7
 var from: Vector3=view.camera.global_position
 return from.distance_to(at)<14 and view.direction().dot((at-from).normalized())>.88 and visible_between(from,at)

func toggle_recording() -> void:
 if not bag_found:
  hud.say("O celular está na bolsa.",2); return
 if video_recorded: return
 if can_frame_ritual():
  recording=not recording; record_time=0
 else: hud.say("Aproxime-se e enquadre o ritual no pátio de química.",3)

func _jump_gate() -> void:
 phase="gate_jump"
 story_clock=0
 gate_from=player.position
 gate_to=school.gate_at+Vector3(0,0,2.8)
 player.state="gate_jump"
 player.clock=0
 player.face(gate_to)
 player.play("guarda")
 player.collision_layer=0
 locked=null

func start_chase() -> void:
 if not alert_spread or not video_recorded or phase!="investigate": return
 phase="discovery"
 discovery_clock=0
 locked=null; protected_target=null; enemy_turn=null
 player.state="idle"
 recording=true
 pursuer=spawn_actor(player.position+Vector3(0,0,5),true,true)
 pursuer.face(player.position)
 pursuer.aware=true
 pursuer.last_seen=player.position
 pursuit_memory=12
 hud.say("Um cultista o encontra e chama alguém. Passos pesados se aproximam.",4)
 view.trauma=.35

func end_discovery() -> void:
 phase="chase"
 recording=false
 player.state="idle"
 view.yaw=atan2(-(school.gate_at-player.position).x,-(school.gate_at-player.position).z)
 view.pitch=0
 hud.say("CORRA. Quebre a visão antes de se esconder. Portas compram tempo.",5)

func _enemy_ticks(dt: float) -> void:
 var engaged=0
 for e in enemies:
  e.clock+=dt
  e.opening=maxf(0,e.opening-dt)
  if e.dead: e.animate(dt); continue
  if e.traversal.get("environment",false):
   _environment_finish_tick(e,dt); continue
  if e==enemies[0] and not sighting_seen and phase!="sighting":
   e.play("guarda"); e.animate(dt); continue
  if e.down:
   e.animate(dt)
   if e==protected_target and player.state=="attack" and attack_mode=="ground": continue
   e.help_clock+=dt
   if e.health<=0 and e.help_clock>1.2:
    e.kill(); continue
   if e.help_clock>4 and e.health>0:
    e.down=false; e.state="rising"; e.clock=0
    e.play("levantar",1.5)
   continue
  if e.state=="rising":
   e.animate(dt)
   if e.clock>3.7:
    e.state="calling"; e.clock=0; e.alert_attempt=true
    hud.say("O cultista está tentando pedir ajuda.",2)
   continue
  if e.state=="calling":
   e.animate(dt)
   if e.clock>1.6:
    _spread_alert(e); e.state="idle"; e.clock=0
   continue
  if e.state in ["hurt","block","dodge"]:
   e.animate(dt)
   if e.clock>(.55 if e.state!="hurt" else .65): e.state="idle"; e.play("guarda")
   continue
  if e.state=="grab_hold":
   e.animate(dt)
   if e.clock>1.3:
    hurt_player(15); e.state="idle"; e.clock=0
   continue
  if e.state=="inspect":
   e.play("guarda"); e.animate(dt)
   e._bend("Chest",Vector3.ZERO,Vector3(.3,0,0)); e._bend("Head",Vector3.ZERO,Vector3(.2,0,0))
   e.rig.force_update_all_bone_transforms()
   if e.clock>1.6:
    e.state="idle"; e.suspicion=maxf(e.suspicion,.55)
    e.home=e.last_seen+Vector3(0,0,1.5)
   continue
  if e==protected_target:
   if attack_mode=="stealth" and player.state=="attack" and enemy_sees(e):
    e.suspicion=minf(1,e.suspicion+dt)
    if e.suspicion>=1:
     e.state="grab_hold"; e.clock=0; e.aware=true
     player.state="grabbed"; player.clock=0
     protected_target=null
     hud.say("Ele percebeu. [Esquiva / Q] Escape do agarrão.",2)
   e.animate(dt); continue
  var distance=e.position.distance_to(player.position)
  if phase not in ["investigate","sighting"]:
   e.animate(dt); continue
  var sees=enemy_sees(e)
  if phone_light and distance<14 and visible_between(e.bone_point("Head"),player.bone_point("Chest")): sees=true
  var loud=not player.crouched and player.velocity.length()>2.5 and distance<7
  if player.state=="attack" and distance<8: loud=true
  if elapsed<disturbance_until and e.position.distance_to(disturbance)<10:
   e.last_seen=disturbance; e.suspicion=maxf(e.suspicion,.35)
  if sees:
   var exposure=.65 if player.crouched and not phone_light else 1.0
   for candle in school.candles:
    if candle.position.distance_to(player.position)<3.2: exposure=1.45; break
   e.suspicion=minf(1,e.suspicion+dt*exposure)
   e.last_seen=player.position; e.memory=25
   if e.suspicion>=1 and phase!="sighting": e.aware=true
  elif loud:
   e.suspicion=minf(.85,e.suspicion+dt*.6)
   e.last_seen=player.position; e.memory=20
  else:
   e.suspicion=maxf(.0,e.suspicion-dt*.07)
   e.memory=maxf(0,e.memory-dt)
  if e.attack_target!=null:
   if e.clock<.35: e.face(player.position,dt)
   e.state="windup" if e.clock<ACTIVE_FROM else ("strike" if e.clock<ACTIVE_TO else "recover")
   e.animate(dt)
   if e.clock>=ACTIVE_FROM and e.clock<=ACTIVE_TO and not e.hit_once and protected_target==null:
    _enemy_contact(e)
   e.hand_previous=e.fist_point()
   if e.clock>ACTIVE_TO and not e.attack_landed:
    e.attack_landed=true; e.opening=1.1
    if not e.hit_once: combat_stats["misses"]+=1
   if e.clock>=HOOK_DURATION:
    e.attack_target=null; e.state="idle"; e.clock=0; e.strike_yaw_bias=0
    enemy_turn=null; turn_cooldown=.5 if e.style==0 else (.9 if e.style==1 else 1.2)
   continue
  if not e.aware:
   if e.suspicion>.12:
    e.face(e.last_seen,dt*.20)
    if e.suspicion>.4: _navigate(e,e.last_seen,.65,dt)
   else:
    e.patrol_clock+=dt
    var target=e.home+Vector3(0,0,-1.7 if int(e.patrol_clock/5)%2==0 else 1.7)
    _navigate(e,target,.65,dt)
   e.animate(dt); continue
  if distance<9: engaged+=1
  if engaged>2:
   e.play("guarda"); e.animate(dt); continue
  var target: Vector3=player.position if sees else e.last_seen
  if not sees and e.memory<=0:
   # Continua buscando perto da última visão, sem seguir a posição oculta.
   target=e.last_seen+Vector3(sin(elapsed*.2)*2,0,cos(elapsed*.2)*2)
  if distance>1.05 or not sees:
   _navigate(e,target,1.35 if enemy_turn==null and protected_target==null else .35,dt)
  else:
   e.velocity=Vector3.ZERO; e.face(player.position,dt); e.play("guarda")
   if enemy_turn==null and protected_target==null and turn_cooldown<=0 and e.opening<=0 and not player.hidden:
    _start_enemy_attack(e)
  e.animate(dt)
 # Vestígios aumentam a busca, sem ativar o estado de alerta espalhado.
 if simulation_ticks%60==0:
  for e in enemies:
   if e.dead or e.aware: continue
   for body in enemies:
    if body.down and e!=body and not e.evidence.has(body.get_instance_id()) and e.position.distance_to(body.position)<6 and visible_between(e.bone_point("Head"),body.position+Vector3.UP*.3):
     e.evidence[body.get_instance_id()]=true
     e.suspicion=maxf(e.suspicion,.5); e.last_seen=body.position; e.memory=30
     e.state="inspect"; e.clock=0
   for stain in blood:
    if not e.evidence.has(stain.get_instance_id()) and e.position.distance_to(stain.position)<4 and visible_between(e.bone_point("Head"),stain.position+Vector3.UP*.02):
     e.evidence[stain.get_instance_id()]=true
     e.suspicion=maxf(e.suspicion,.4); e.last_seen=stain.position; e.memory=25

func _spread_alert(e: CharacterBody3D) -> void:
 if not e.aware: return
 alert_spread=true
 disturbance=e.position; disturbance_until=elapsed+8
 cult_audio.pitch_scale=.83
 cult_audio.play()
 hud.say("Uma resposta distante. Mais passos atravessam a escola.",4)
 for other in enemies:
  if other!=e and not other.dead:
   other.last_seen=e.position; other.suspicion=maxf(other.suspicion,.4); other.memory=30

func attack(heavy:=false) -> void:
 if phase!="investigate" or player.hidden or is_instance_valid(peek_door): return
 if player.state=="attack":
  if buffered_attack: fatigue=minf(1,fatigue+.17)
  else: buffered_attack=true
  return
 if player.state not in ["idle","heal"]: return
 _drop_load()
 cancel_heal()
 var e: CharacterBody3D=locked if is_instance_valid(locked) and not locked.dead and player.position.distance_to(locked.position)<1.6 else nearest_enemy(1.6,true)
 action_target=e
 heavy_attack=heavy
 attack_mode="normal"
 if e!=null and e.down: attack_mode="ground"
 elif e!=null and is_behind(e): attack_mode="stealth"
 elif e!=null and e.opening>0: attack_mode="counter"
 var clip="pesado" if heavy else ["jab","direto","gancho"][chain_step%3]
 if attack_mode=="ground": clip="Brutal_Assassination"
 if attack_mode=="stealth": clip="Fist_Fight_A"
 hit_profile=profiles[clip]
 player.state="attack"; player.clock=0; player.hit_once=false
 player.strike_bone=hit_profile["bone"]
 player.strike_yaw_bias=hit_profile["bias"]
 attack_duration=float(hit_profile["duration"])*(1+fatigue*.6)
 player.anim.speed_scale=1/(1+fatigue*.6)
 player.anim.play(clip,.07)
 attack_origin=player.position
 if e!=null:
  player.face(e.bone_point("Head") if e.down else e.position)
  if attack_mode in ["counter","stealth","ground"]: protected_target=e
  if e.aware and e.style==1 and e.opening<=0 and not e.down and e.state=="idle":
   e.state="block"; e.clock=0; e.play("bloqueio")
 player.hand_previous=player.fist_point()
 if attack_mode=="counter": combat_stats["counters"]+=1

func _attack_tick(dt: float) -> void:
 if attack_mode=="takedown":
  _takedown_tick(dt); return
 var e=action_target
 if is_instance_valid(e) and not e.dead and player.clock<float(hit_profile["contact"])*.6:
  player.face(e.bone_point("Head") if e.down else e.position,dt)
  if attack_mode=="ground":
   var local_point: Vector3=hit_profile["point"]
   var desired: Vector3=e.bone_point("Head")-player.model.global_basis*Vector3(local_point.x,0,local_point.z)
   var motion=Vector3(desired.x-player.position.x,0,desired.z-player.position.z).limit_length(.8*dt)
   player.move_and_collide(motion)
 player.animate(dt)
 var t=player.clock/(1+fatigue*.6)
 var at=float(hit_profile["contact"])
 if t>=at-.12 and t<=at+.14 and not player.hit_once and is_instance_valid(e) and not e.dead:
  if e.state=="block" and _guard_contact(e):
   player.hit_once=true
   _impact(player.fist_point(),false)
   impact_audio.stream=sfx["bloqueio"]; impact_audio.play()
  elif _hand_hits(player,e):
   player.hit_once=true; _land_hit(e,player.fist_point())
 player.hand_previous=player.fist_point()
 if player.clock>=attack_duration:
  player.state="idle"; player.strike_yaw_bias=0
  protected_target=null
  if buffered_attack and player.hit_once:
   precise_attack=precise_buffer
   precise_buffer=false
   buffered_attack=false; chain_step+=1; attack()
  else:
   buffered_attack=false; chain_step=0; precise_attack=false; player.play("guarda")
   if not player.hit_once:
    player.opening=.5
    hud.say("Golpe fora do alcance.",1)

func _land_hit(e: CharacterBody3D,at: Vector3) -> void:
 var damage=(40.0 if heavy_attack else 23.0)*(1-fatigue*.45)
 if precise_attack: damage*=1.25
 if attack_mode=="counter": damage*=1.35
 if attack_mode=="stealth": damage=100
 e.health=maxf(0,e.health-damage)
 e.attack_target=null; e.strike_yaw_bias=0
 e.alert_attempt=false; e.help_clock=0
 enemy_turn=null; turn_cooldown=.7
 if attack_mode=="counter": combat_stats["counter_hits"]+=1
 if e.health<=0:
  e.make_down()
 elif e.health<=35 or heavy_attack or attack_mode=="takedown":
  e.make_down()
 else:
  e.state="hurt"; e.clock=0; e.play("guarda")
  e.aware=true
 protected_target=e
 impact_pause=.045 if not heavy_attack else .075
 e.bleed=1
 burst_clock=5
 _impact(at,true)

func _guard_contact(e: CharacterBody3D) -> bool:
 var fist: Vector3=player.fist_point()
 for side in ["Left","Right"]:
  var a: Vector3=e.bone_point(side+"LowerArm")
  var b: Vector3=e.bone_point(side+"Hand")
  var closest=Geometry3D.get_closest_point_to_segment(fist,a,b)
  if fist.distance_to(closest)<.20 and visible_between(player.bone_point("Chest"),fist): return true
 return false

func takedown_or_finish() -> void:
 if player.state=="grabbed": dodge(); return
 if player.state!="idle" or phase!="investigate": return
 var e=nearest_enemy(1.45,true)
 if e==null: return
 if e.down:
  # Finalização depende de vulnerabilidade e contato; não mata de longe.
  attack(true)
  return
 pair_context=_finish_context(e) if e.health<=45 else {}
 e.set_meta("environment_kind","")
 if e.opening<=0 and e.style==2:
  e.state="block"; e.clock=0; e.play("bloqueio")
  player.opening=.7
  hud.say("Ele resistiu à tentativa de derrubada.",1.5)
  return
 player.anim.play("actions/takedown",.10)
 player.state="attack"; player.clock=0; player.hit_once=false
 action_target=e; protected_target=e
 attack_mode="takedown"
 hit_profile={"duration":2.05,"contact":.65}
 attack_duration=2.05*(1+fatigue*.6)
 player.anim.speed_scale=1/(1+fatigue*.6)
 heavy_attack=false
 player.strike_bone="RightHand"; player.strike_yaw_bias=0
 player.face(e.position)
 player.hand_previous=player.fist_point()

func _takedown_tick(dt: float) -> void:
 var e=action_target
 var time=player.clock/(1+fatigue*.6)
 if not is_instance_valid(e) or e.dead:
  player.state="idle"; protected_target=null; return
 player.face(e.position,dt)
 if time<.8:
  var to: Vector3=e.position-player.position; to.y=0
  if to.length()>.62: player.move_and_collide(to.normalized()*.9*dt)
 player.animate(dt)
 if not player.hit_once and time>=.30 and time<=.95:
  for bone in ["RightHand","LeftHand"]:
   player.strike_bone=bone
   if _hand_hits(player,e):
    player.hit_once=true; e.state="paired"; e.clock=0; e.attack_target=null
    e.aware=true; e.health=maxf(1,e.health-12)
    enemy_turn=null
    _impact(e.bone_point("Chest"),false)
    break
 if player.hit_once and time>=1.05 and not e.down:
  if not pair_context.is_empty() and not e.traversal.get("environment",false):
   var away: Vector3=(e.position-player.position).normalized()
   var desired: Vector3=e.position+away*.9
   if pair_context["kind"]=="mesa":
    desired=pair_context["node"].global_position+Vector3.UP*.055
   e.traversal={"environment":true,"clock":0.0,"from":e.position,"to":desired,"kind":pair_context["kind"],"at":pair_context["at"]}
   e.set_meta("environment_kind",pair_context["kind"])
  elif pair_context.is_empty():
   e.make_down(); e.bleed=1
   _impact(e.position+Vector3.UP*.2,true)
 if player.clock>=attack_duration:
  player.state="idle"; player.strike_yaw_bias=0; player.play("guarda")
  protected_target=null; turn_cooldown=.8
  pair_context={}
  if not player.hit_once: hud.say("Não conseguiu firmar a pegada.",1.5)

func _finish_context(e: CharacterBody3D) -> Dictionary:
 var away: Vector3=(e.position-player.position).normalized()
 for from in [e.bone_point("Chest"),e.bone_point("Hips"),e.position+Vector3.UP*.8]:
  var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,from+away*1.1,1))
  if hit.is_empty(): continue
  var body=hit["collider"]
  if body.has_meta("reactive"): return {"kind":"mesa","at":hit["position"],"node":body}
  var kind=body.get_meta("kind","")
  if kind in ["wall","tile","metal"]:
   return {"kind":"armário" if kind=="metal" else "parede","at":hit["position"],"node":body}
 return {}

func _environment_finish_tick(e: CharacterBody3D,dt: float) -> void:
 var data=e.traversal
 data["clock"]=float(data["clock"])+dt
 var t=clampf(float(data["clock"])/.65,0,1)
 var desired: Vector3=data["from"].lerp(data["to"],smoothstep(0,1,t))
 if data["kind"]=="mesa":
  desired.y=maxf(desired.y,float(data["from"].y)+sin(t*PI)*1.25)
  if not e.down and t>.35: e.make_down()
 e.move_and_collide(Vector3(0,maxf(0,desired.y-e.position.y),0))
 e.move_and_collide(Vector3(desired.x-e.position.x,0,desired.z-e.position.z))
 e.move_and_collide(Vector3(0,minf(0,desired.y-e.position.y),0))
 e.animate(dt)
 if t>=1:
  _impact(data["at"],true)
  if data["kind"]=="armário": impact_audio.stream=sfx["metal"]; impact_audio.play()
  e.health=0
  if not e.down: e.make_down()
  e.help_clock=0
  e.traversal={}

func hurt_player(damage: float) -> void:
 tool_active.clear()
 buffered_attack=false; mouse_held=false
 chain_step=0; precise_attack=false; precise_buffer=false
 _drop_load()
 super.hurt_player(damage)

func _player_tick(dt: float) -> void:
 if player.state=="grabbed":
  player.clock+=dt; player.animate(dt); return
 super._player_tick(dt)

func dodge() -> void:
 if player.state=="grabbed":
  player.state="idle"
  if is_instance_valid(action_target):
   action_target.state="hurt"; action_target.clock=0; action_target.opening=1
 super.dodge()

func _start_enemy_attack(e: CharacterBody3D) -> void:
 super._start_enemy_attack(e)
 step_audio.position=e.position
 step_audio.pitch_scale=.72; step_audio.volume_db=-18; step_audio.play()

func _enemy_contact(e: CharacterBody3D) -> void:
 if player.hidden or not _hand_hits(e,player): return
 e.hit_once=true
 combat_stats["enemy_hits"]+=1
 hurt_player(38)

func interact() -> void:
 if player.hidden: _leave_hide(); return
 if player.state=="hang":
  vault["climb"]=true; player.clock=float(vault["hang_clock"]); player.state="vault"; return
 if player.state not in ["idle","heal","hang"] and not player.hidden: return
 if not bag_found and player.position.distance_to(school.bag_at)<1.7 and player.position.y>2.5:
  bag_found=true; school.bag.visible=false; checkpoint_index=1
  _snapshot(); hud.say("Bolsa e celular recuperados. Desça e procure a origem das vozes.",5); return
 if video_recorded and player.position.distance_to(school.gate_at)<3:
  _jump_gate(); return
 for item in tools:
  if not item["taken"] and _near_looking(item["at"],1.5):
   item["taken"]=true; item["node"].visible=false
   tool_inventory.append(item["name"]); hud.say("Ferramenta: "+item["name"],2); return
 for prop in school.reactive:
  if prop.has_meta("use") and _near_looking(prop.position,1.5):
   if prop.get_meta("finished",false): return
   if prop.get_meta("tool") in tool_inventory:
    tool_active={"node":prop,"name":prop.get_meta("use")}; player.tool_pose=true
   else: hud.say("Precisa de "+prop.get_meta("tool")+".",2)
   return
 for item in world_objects:
  if not item["taken"] and _near_looking(item["node"].position,1.5):
   item["taken"]=true; carried=item["node"]; return
 for door in school.doors:
  if _near_looking(door.center(),1.8):
   peek_door=null; door.toggle(); return
 for item in school.pickups:
  if not item["taken"] and _near_looking(item["at"],1.5):
   item["taken"]=true; item["node"].visible=false
   if item["kind"]=="empanado": food+=1
   else: knife=true
   hud.say("Empanado guardado." if item["kind"]=="empanado" else "Faca guardada para escapar de um agarrão.",2)
   return
 for i in school.hides.size():
  if _near_looking(school.hides[i]["entry"]+Vector3.UP*.9,1.5): _enter_hide(i); return
 var direction: Vector3=view.movement(raw_movement())
 try_vault(player,player.facing if direction.length()<.1 else direction,false)

func _near_looking(at: Vector3,distance: float) -> bool:
 var delta=at-(player.position+Vector3.UP*.9)
 return delta.length()<distance and view.direction().dot(delta.normalized())>.25

func context_text() -> String:
 if phase in ["intro","sighting","discovery","gate_jump","ending"]: return ""
 if not tool_active.is_empty(): return "USANDO FERRAMENTA · mover ou sofrer dano interrompe"
 if recording: return "● REC  %02d s · mantenha o ritual enquadrado"%int(record_time)
 if not bag_found and _near_looking(school.bag_at,1.7): return "[Espaço] Pegar bolsa e celular"
 if bag_found and not video_recorded and can_frame_ritual(): return "[V] Gravar vídeo do ritual"
 if video_recorded and player.position.distance_to(school.gate_at)<3: return "[Espaço] Pular o portão 1"
 if carried!=null: return "[T / clique] Arremessar objeto · esquiva solta a carga"
 if carried_body!=null: return "[G] Soltar corpo · esquiva solta a carga"
 if player.hidden: return "ESCONDIDO · observe e escute · [Espaço] Sair"
 if show_help: return "WASD mover · Espaço interagir · ataque continuar · Q derrubar · V gravar · L lanterna"
 for door in school.doors:
  if _near_looking(door.center(),1.8): return "[Espaço] "+("Fechar " if door.opened else "Abrir ")+door.title+(" · [F] Fresta" if not door.opened else "")
 for item in tools:
  if not item["taken"] and _near_looking(item["at"],1.5): return "[Espaço] Pegar "+item["name"]
 for prop in school.reactive:
  if prop.has_meta("use") and _near_looking(prop.position,1.5): return "[Espaço] Usar "+str(prop.get_meta("tool"))+" · "+str(prop.get_meta("use"))
 for item in world_objects:
  if not item["taken"] and _near_looking(item["node"].position,1.5): return "[Espaço] Pegar objeto · [T] Arremessar"
 var e=nearest_enemy(1.6,true)
 if e!=null and e.down: return "[G] Arrastar corpo · [Q] Tentar finalizar"
 for item in school.pickups:
  if not item["taken"] and _near_looking(item["at"],1.5): return "[Espaço] Pegar "+item["kind"]
 for spot in school.hides:
  if _near_looking(spot["entry"]+Vector3.UP*.9,1.5): return "[Espaço] Esconder-se · quebre a visão antes"
 if e!=null and is_behind(e): return "[Ataque] Ação furtiva · ou passe escondido"
 return "ALVO TRAVADO · meio solta · rodinha troca" if is_instance_valid(locked) else ""

func _tool_tick(dt: float) -> void:
 if raw_movement().length()>.1:
  tool_active.clear(); player.tool_pose=false; return
 var key: String=tool_active["name"]
 tool_progress[key]=minf(4,float(tool_progress[key])+dt)
 player.animate(dt)
 if tool_progress[key]>=4:
  tool_active["node"].set_meta("finished",true)
  _apply_tool_state(tool_active["node"],true)
  hud.say("Concluído: "+key,2)
  if key=="caixa de materiais":
   food+=1
  tool_active.clear(); player.tool_pose=false

func _apply_tool_state(prop: Node3D,complete: bool) -> void:
 prop.position=prop.get_meta("original_at",prop.position)
 var key=prop.get_meta("use","")
 if key=="caixa de materiais": prop.rotation.x=-.7 if complete else 0.0
 elif key=="livros altos" and complete: prop.position.y-=.55
 elif key=="luminária":
  var light: OmniLight3D=prop.get_meta("light") if prop.has_meta("light") else null
  if not is_instance_valid(light) and complete:
   light=OmniLight3D.new(); light.light_color=Color(.95,.8,.5); light.omni_range=5
   light.position=prop.position+Vector3.UP*1.4; school.add_child(light)
   prop.set_meta("light",light)
  if is_instance_valid(light): light.visible=complete

func drag_body() -> void:
 if carried_body!=null: carried_body=null; return
 if player.state!="idle": return
 for e in enemies:
  if e.down and player.position.distance_to(e.position)<1.6:
   carried_body=e; return

func _drop_load() -> void:
 if carried!=null:
  for item in world_objects:
   if item["node"]==carried: item["taken"]=false
 carried=null
 carried_body=null

func _loads_tick(dt: float) -> void:
 if carried!=null: carried.global_position=player.bone_point("RightHand")
 if carried_body!=null:
  if not carried_body.down:
   carried_body=null; return
  var goal=player.position-player.facing*.7
  carried_body.move_and_collide((goal-carried_body.position).limit_length(dt*1.8))
  if simulation_ticks%60==0 and carried_body.bleed>0: _stain(carried_body.position)

func throw_object() -> void:
 if carried==null: return
 var prop=carried
 carried=null
 var from: Vector3=prop.position
 var desired=from+view.direction()*6
 desired.y=.15
 var ray=PhysicsRayQueryParameters3D.create(from,desired,1)
 var hit=get_world_3d().direct_space_state.intersect_ray(ray)
 if not hit.is_empty(): desired=hit["position"]
 var tween=prop.create_tween()
 tween.tween_property(prop,"position",desired,.55)
 tween.tween_callback(func():
  disturbance=prop.position; disturbance_until=elapsed+6
  distraction_count+=1
  if distraction_count>1: disturbance=Vector3(from.x,0,from.z)
  for item in world_objects:
   if item["node"]==prop: item["taken"]=false
 )

func _pursuer_tick(dt: float) -> void:
 if is_instance_valid(pursuer) and phase=="chase" and pursuit_memory<=0 and pursuer.state=="idle" and not enemy_sees(pursuer,true):
  var nearby: Array[int]=[]
  for i in school.hides.size():
   if school.hides[i]["entry"].distance_to(pursuer.last_seen)<5: nearby.append(i)
  if not nearby.is_empty():
   search_time+=dt
   var index=nearby[int(search_time/5)%nearby.size()]
   var entry: Vector3=school.hides[index]["entry"]
   _navigate(pursuer,entry,1.25,dt)
   pursuer.animate(dt)
   if pursuer.position.distance_to(entry)<1.1 and player.hidden and hidden_spot==index: _grab()
   return
 super._pursuer_tick(dt)

func _navigate(actor: CharacterBody3D,target: Vector3,speed: float,dt: float) -> void:
 if target.y>2.5 and actor.position.y<3.2:
  if actor.position.distance_to(school.stairs_bottom)<1.4: actor.set_meta("subindo",true)
  if actor.get_meta("subindo",false):
   actor.move_toward(school.stairs_top,speed,dt)
   actor.play("andaFrente"); return
  super._navigate(actor,school.stairs_bottom,speed,dt); return
 if actor.position.y>2.5 and target.y<1:
  if Vector2(actor.position.x-school.stairs_top.x,actor.position.z-school.stairs_top.z).length()<1.2:
   actor.set_meta("descendo",true)
  if actor.get_meta("descendo",false):
   actor.move_toward(school.stairs_bottom,speed,dt)
   actor.play("andaFrente"); return
  actor.move_toward(school.stairs_top,speed,dt); actor.play("andaFrente"); return
 if actor.position.y<.5: actor.set_meta("descendo",false)
 if actor.position.y>3.2: actor.set_meta("subindo",false)
 # Portas comuns também compram tempo de fuga; não são atravessadas pelo pathfinding.
 for door in school.doors:
  if not door.opened and actor.position.distance_to(door.position)<1.6:
   var before=(actor.position-door.position).dot(door.normal)
   var after=(target-door.position).dot(door.normal)
   if before*after<0 and actor.aware:
    var progress=float(door.get_meta("break",0.0))+dt
    door.set_meta("break",progress)
    if int(progress*2)!=int((progress-dt)*2): _impact(door.center(),false)
    if progress>(3.6 if actor.pursuer else 4.6): door.set_open(true)
    actor.play("guarda"); return
 super._navigate(actor,target,speed,dt)

func _build_paths() -> void:
 path_grid=AStarGrid2D.new()
 path_grid.region=Rect2i(-78,-58,168,130)
 path_grid.cell_size=Vector2(.5,.5)
 path_grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 path_grid.update()
 for body in school.find_children("*","StaticBody3D",true,false):
  var shape: CollisionShape3D=null
  for child in body.get_children():
   if child is CollisionShape3D: shape=child; break
  if shape==null or not shape.shape is BoxShape3D: continue
  if body.has_meta("door") and body.get_meta("door").opened: continue
  var size: Vector3=shape.shape.size
  var world_size=body.global_basis.x.abs()*size.x+body.global_basis.y.abs()*size.y+body.global_basis.z.abs()*size.z
  var at: Vector3=body.to_global(shape.position)
  if at.y+world_size.y*.5<.3 or at.y-world_size.y*.5>1.7: continue
  for x in range(ceili((at.x-world_size.x*.5-.27)*2),floori((at.x+world_size.x*.5+.27)*2)+1):
   for z in range(ceili((at.z-world_size.z*.5-.27)*2),floori((at.z+world_size.z*.5+.27)*2)+1):
    var cell=Vector2i(x,z)
    if path_grid.is_in_boundsv(cell): path_grid.set_point_solid(cell,true)
 paths.clear()

func _snapshot(persist:=true) -> void:
 super._snapshot(false)
 checkpoint["version"]=3
 checkpoint["bag"]=bag_found
 checkpoint["alert"]=alert_spread
 checkpoint["video"]=video_recorded
 checkpoint["before_ritual"]=before_ritual
 checkpoint["tools"]=tool_inventory.duplicate()
 checkpoint["tool_progress"]=tool_progress.duplicate()
 checkpoint["blood"]=blood.map(func(b): return [b.position.x,b.position.y,b.position.z])
 checkpoint["props"]=school.reactive.map(func(prop):return {"z":prop.rotation.z,"damage":prop.get_meta("damage",0)})
 checkpoint["objects"]=world_objects.map(func(item):return [item["node"].position.x,item["node"].position.y,item["node"].position.z])
 checkpoint["scare"]=scare_played
 checkpoint["sighting"]=sighting_seen
 if persist:
  var file=FileAccess.open(_save_path(),FileAccess.WRITE)
  if file: file.store_string(JSON.stringify(checkpoint))

func _save_path() -> String:
 return "res://../work/capitulo1-qa-save.json" if qa_mode else "user://terror_checkpoint_v3.json"

func load_checkpoint() -> bool:
 if not FileAccess.file_exists(_save_path()): return false
 var saved=JSON.parse_string(FileAccess.get_file_as_string(_save_path()))
 if not saved is Dictionary or saved.get("version")!=3 or saved.get("enemies",[]).size()!=enemies.size(): return false
 checkpoint=saved; restore_checkpoint(); return true

func restore_checkpoint() -> void:
 if player.dead: death_count+=1
 super.restore_checkpoint()
 bag_found=bool(checkpoint.get("bag",false))
 alert_spread=bool(checkpoint.get("alert",false))
 video_recorded=bool(checkpoint.get("video",false))
 before_ritual=bool(checkpoint.get("before_ritual",false))
 sighting_seen=bool(checkpoint.get("sighting",false))
 scare_played=bool(checkpoint.get("scare",false)); silhouette.visible=false
 silhouette.position=school.p(323,118+posmod(death_count,3)*8)
 school.bag.visible=not bag_found
 tool_inventory.assign(checkpoint.get("tools",[]))
 tool_progress=checkpoint.get("tool_progress",{}).duplicate()
 for prop in school.reactive:
  if prop.has_meta("use"):
   var complete=float(tool_progress.get(prop.get_meta("use"),0))>=4
   prop.set_meta("finished",complete)
   _apply_tool_state(prop,complete)
 for coords in checkpoint.get("blood",[]): _stain(Vector3(coords[0],coords[1],coords[2]))
 for item in tools:
  item["taken"]=item["name"] in tool_inventory
  item["node"].visible=not item["taken"]
 for e in enemies:
  e.help_clock=0; e.knocked_before=false; e.alert_attempt=false; e.bleed=1 if e.health<100 else 0
  e.evidence.clear(); e.traversal={}; e.set_meta("environment_kind","")
 for i in school.reactive.size():
  var props: Array=checkpoint.get("props",[])
  if i<props.size():
   school.reactive[i].rotation.z=float(props[i]["z"])
   school.reactive[i].set_meta("damage",props[i]["damage"])
 var objects: Array=checkpoint.get("objects",[])
 for i in world_objects.size():
  if i<objects.size(): world_objects[i]["node"].position=Vector3(objects[i][0],objects[i][1],objects[i][2])
  world_objects[i]["taken"]=false
 mouse_held=false; recording=false; record_time=0; fatigue=0
 player.tool_pose=false; tool_active.clear(); _drop_load()
 player.collision_layer=2
 phone_light=false
 view.yaw=PI/2
 _build_paths()

func _stain(at: Vector3) -> void:
 var node=MeshInstance3D.new()
 var mesh=CylinderMesh.new()
 mesh.top_radius=.12; mesh.bottom_radius=.12; mesh.height=.006; mesh.radial_segments=8
 node.mesh=mesh; node.material_override=school.mats["red"]
 node.position=at+Vector3.UP*.012
 add_child(node); blood.append(node)

func _impact(at: Vector3,gore: bool) -> void:
 impact_audio.stream=sfx["carne"] if gore else sfx["parede"]
 for prop in school.reactive:
  if prop.position.distance_to(at)<1.2 and not gore:
   impact_audio.stream=sfx["metal"]; break
 super._impact(at,false)
 if gore:
  var floor_y=school.LEVEL if player.position.y>2.7 else 0.0
  _stain(Vector3(at.x,floor_y,at.z))
  for i in 4:
   var dot=MeshInstance3D.new(); var mesh=BoxMesh.new(); mesh.size=Vector3(.018,.018,.018)
   dot.mesh=mesh; dot.material_override=school.mats["red"]; dot.position=at
   add_child(dot)
   var tween=dot.create_tween()
   tween.tween_property(dot,"position",Vector3(at.x+sin(i*2.1)*.4,floor_y+.02,at.z+cos(i*1.8)*.4),.22+i*.03)
   tween.tween_callback(dot.queue_free)
 for prop in school.reactive:
  if prop.position.distance_to(at)<1.6 and not prop.has_meta("use"):
   var damage=int(prop.get_meta("damage",0))+1
   prop.set_meta("damage",damage)
   if damage>=3: prop.rotation.z=.13

func _capture() -> void:
 begin(); end_intro()
 player.position=school.p(620,250)
 view.yaw=PI/2
 await get_tree().create_timer(5).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../work/capitulo1.png"))
 get_tree().quit()
