extends "res://prototipo/game.gd"
## Capítulo 1 integrado. Mantém a revisão 2 como referência separada.
const CAMPUS=preload("res://capitulo1/mapa/escola_grade.gd")
const NIVEL=preload("res://capitulo1/nivel.gd")
const PERSON=preload("res://capitulo1/ator.gd")
const CHAPTER_HUD=preload("res://capitulo1/hud.gd")
const CHAPTER_CAMERA=preload("res://capitulo1/camera.gd")
const TOUCH=preload("res://capitulo1/toque.gd")
const ACTIONS=preload("res://capitulo1/acoes.gd")
var touch: CanvasLayer
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
var carried: Node3D
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
var filter_rect: TextureRect
var film_enabled:=true
var tool_prop: Node3D
var gate_from:=Vector3.ZERO
var gate_to:=Vector3.ZERO
var burst_clock:=0.0
var fleeing_return:=false
var ending_set: Node3D
var phone_prop: Node3D
var breathing: AudioStreamPlayer
var sfx: Dictionary={}
var scare_played:=false
var scare_time:=0.0
var silhouette: Node3D
var death_count:=0
var spawn_style:=0

func _ready() -> void:
 qa_mode="--qa-inspect" in OS.get_cmdline_user_args()
 lightweight=true
 school=CAMPUS.new()
 add_child(school)
 school.build(self)
 player=spawn_actor(school.spawn,false)
 # Postos marcados na grade do mapa (1–4 em capitulo1/mapa/terreo.txt).
 for at in school.postos:
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
 if TOUCH.wanted():
  touch=TOUCH.new(); add_child(touch); touch.setup(self)
 _audio()
 for name in ["metal","parede","bloqueio","carne","respiracao","susto"]:
  sfx[name]=load("res://capitulo1/assets/"+name+".wav").duplicate()
 breathing=AudioStreamPlayer.new(); breathing.stream=sfx["respiracao"]
 breathing.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD; breathing.stream.loop_end=int(breathing.stream.get_length()*breathing.stream.mix_rate)
 breathing.volume_db=-80; add_child(breathing); breathing.play()
 cult_audio.position=school.ritual_center
 cult_audio.unit_size=4
 cult_audio.max_distance=26
 var chant=load("res://capitulo1/assets/culto.wav").duplicate()
 chant.loop_mode=AudioStreamWAV.LOOP_FORWARD
 chant.loop_end=int(chant.get_length()*chant.mix_rate)
 cult_audio.stream=chant
 cult_audio.pitch_scale=.76
 cult_audio.volume_db=-18
 cult_audio.play()
 flashlight=SpotLight3D.new()
 flashlight.light_color=Color(.88,.90,.78)
 flashlight.light_energy=2.6
 flashlight.spot_range=16
 flashlight.spot_angle=27
 flashlight.shadow_enabled=false
 flashlight.visible=false
 add_child(flashlight)
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
 silhouette.position=NIVEL.ponto(school,"silhueta")
 silhouette.visible=false
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
  var e=spawn_actor(school.ritual_center+Vector3(sin(a)*1.75,0,cos(a)*1.15),true)
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
 # Clipes FK próprios: empurrão, agarrão (acoes.gd).
 if not actor.anim.has_animation_library("actions"):
  actor.anim.add_animation_library("actions",ACTIONS.build(actor))
 return actor

## Retrô robusto: o 3D é desenhado direto em baixa resolução numa SubViewport
## (mesmo mundo, câmera espelhada) e ampliado com pixels duros + pontilhado.
## Não lê a tela, então vale igual no PC, web e celular, e custa menos.
const LOW_HEIGHT:=200
var low_view: SubViewport
var low_camera: Camera3D

func _postprocess() -> void:
 ambient_filter=CanvasLayer.new()
 ambient_filter.layer=-1
 add_child(ambient_filter)
 low_view=SubViewport.new()
 low_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 low_view.audio_listener_enable_3d=true
 low_view.msaa_3d=Viewport.MSAA_DISABLED
 add_child(low_view)
 low_camera=Camera3D.new()
 low_view.add_child(low_camera)
 low_camera.current=true
 get_viewport().disable_3d=true
 filter_rect=TextureRect.new()
 filter_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 filter_rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
 filter_rect.texture=low_view.get_texture()
 filter_rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 filter_rect.stretch_mode=TextureRect.STRETCH_SCALE
 filter_rect.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var mat=ShaderMaterial.new()
 mat.shader=load("res://capitulo1/retro.gdshader")
 filter_rect.material=mat
 ambient_filter.add_child(filter_rect)
 _resize_low()

func _resize_low() -> void:
 var screen: Vector2=get_viewport().get_visible_rect().size
 var height:=float(LOW_HEIGHT) if film_enabled else screen.y
 var size:=Vector2i(maxi(1,roundi(height*screen.x/maxf(1,screen.y))),int(height))
 if low_view.size!=size: low_view.size=size
 filter_rect.material.set_shader_parameter("low_size",Vector2(size))
 filter_rect.material.set_shader_parameter("intensity",1.0 if film_enabled else 0.0)

func _sync_low_camera() -> void:
 var cam: Camera3D=view.camera
 low_camera.global_transform=cam.global_transform
 low_camera.fov=cam.fov
 low_camera.near=cam.near
 low_camera.far=cam.far
 low_camera.h_offset=cam.h_offset
 low_camera.v_offset=cam.v_offset
 low_camera.environment=cam.environment
 low_camera.cull_mask=cam.cull_mask

func _props() -> void:
 # Posições em células da grade (capitulo1/nivel.gd), sobre blocos do mapa.
 for data in NIVEL.FERRAMENTAS:
  var at: Vector3=school.topo(data[1],data[2])+Vector3.UP*.02
  var prop=school.box(Vector3(.035,.035,.28),at,"metal",false)
  tools.append({"name":data[0],"at":at,"node":prop,"taken":false})
 for cell in NIVEL.OBJETOS:
  var at: Vector3=school.cel(cell.x,cell.y,.12)
  var prop=school.box(Vector3(.20,.24,.20),at,"metal",false)
  world_objects.append({"node":prop,"origin":at,"taken":false})
 # Uso interrompível, sem som atraindo inimigos: reparar luz / abrir caixa de materiais.
 for data in NIVEL.USOS:
  var at: Vector3=school.cel(data[2].x,data[2].y,data[3])+data[4]
  var prop=school.box(Vector3(.35,.35,.22),at,"wood",false)
  prop.set_meta("use",data[0]); prop.set_meta("tool",data[1])
  prop.set_meta("original_at",at)
  school.reactive.append(prop)
  tool_progress[data[0]]=0.0
  if data[0]=="livros altos": school.box(Vector3(.65,.05,.35),at-Vector3.UP*.2,"wood",false)

func begin() -> void:
 started=true
 paused=false
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if qa_mode or touch!=null else Input.MOUSE_MODE_CAPTURED
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
   Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if paused or touch!=null else Input.MOUSE_MODE_CAPTURED
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
   KEY_Q:
    if player.state=="grabbed": dodge()
   KEY_F: toggle_peek()
   KEY_L:
    if bag_found: phone_light=not phone_light
   KEY_V: toggle_recording()
   KEY_T: throw_object()
   KEY_F1: show_help=not show_help
   KEY_F3:
    film_enabled=not film_enabled
    _resize_low()
 if event is InputEventMouseButton and event.pressed:
  match event.button_index:
   MOUSE_BUTTON_LEFT:
    if carried!=null: throw_object()
    else: shove()
   MOUSE_BUTTON_RIGHT:
    _drop_load(); dodge()

## Empurrão: única resposta física de Miguel. Derruba por alguns segundos e não
## fere; quem cai levanta e tenta chamar ajuda. Compra tempo, não resolve.
const SHOVE_DURATION:=.75
const SHOVE_CONTACT:=.28
const SHOVE_REACH:=1.5
var shove_cooldown:=0.0

func shove() -> void:
 if phase not in ["investigate","chase"] or player.hidden or is_instance_valid(peek_door): return
 if player.state not in ["idle","heal"]: return
 if shove_cooldown>0:
  fatigue=minf(1,fatigue+.2); burst_clock=3; return
 _drop_load(); cancel_heal()
 var e: CharacterBody3D=nearest_enemy(SHOVE_REACH,false)
 action_target=e
 attack_mode="shove"
 player.state="attack"; player.clock=0; player.hit_once=false
 attack_duration=SHOVE_DURATION*(1+fatigue*.6)
 player.anim.speed_scale=1.0/(1+fatigue*.6)
 player.anim.play("actions/empurrao",.06)
 if e!=null: player.face(e.position)
 shove_cooldown=attack_duration+.5
 fatigue=minf(1,fatigue+.12)

func _shove_tick(dt: float) -> void:
 var e=action_target
 if is_instance_valid(e) and not e.down and player.clock<SHOVE_CONTACT: player.face(e.position,dt)
 player.animate(dt)
 if not player.hit_once and player.clock>=SHOVE_CONTACT*(1+fatigue*.6):
  player.hit_once=true
  if is_instance_valid(e) and not e.down and not e.dead and player.position.distance_to(e.position)<SHOVE_REACH+.15:
   var away: Vector3=(e.position-player.position)*Vector3(1,0,1)
   e.attack_target=null; e.strike_yaw_bias=0
   if enemy_turn==e: enemy_turn=null
   e.aware=true; e.last_seen=player.position
   e.make_down(); e.help_clock=0
   e.move_and_collide(away.normalized()*.6)
   view.trauma=.2
   impact_audio.stream=sfx["parede"]; impact_audio.play()
   combat_stats["shoves"]=int(combat_stats.get("shoves",0))+1
 if player.clock>=attack_duration:
  player.state="idle"; player.play("guarda")

func _process(dt: float) -> void:
 if player.dead: player.animate(dt)
 view.update(dt)
 _sync_low_camera()
 hud.update(dt)
 _resize_low()
 flashlight.visible=bag_found and phone_light and not paused
 if flashlight.visible:
  # Sai do celular na mão, não da câmera: em terceira pessoa a luz da câmera
  # iluminava as costas de Miguel em vez do caminho.
  var from: Vector3=player.bone_point("RightHand")+Vector3.UP*.05 if view.mode not in ["first_person","recording","peek"] else view.camera.global_position
  var aim: Vector3=view.camera.global_position+view.direction()*12
  flashlight.global_position=from
  if from.distance_squared_to(aim)>.01: flashlight.look_at(aim)
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
 if phase in ["investigate","sighting"]: _ritual_watch(dt)
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
   # Ensina antes de testar: o corredor seguinte tem guardas.
   hud.say("Agachado ("+("AGACHAR" if touch!=null else "Ctrl")+"), Miguel faz menos barulho e é mais difícil de ver.",5)
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
 shove_cooldown=maxf(0,shove_cooldown-dt)
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
 _unease_beats()
 if not bag_found and player.position.distance_to(school.bag_at)<1.7 and player.position.y>2.5:
  hud.say("A bolsa está sobre a mesa. [Espaço] Pegar",1)
 if bag_found and not before_ritual and player.position.distance_to(school.ritual_approach)<3 and player.position.y<1 and checkpoint_safe():
  before_ritual=true; checkpoint_index=2; _snapshot()
  hud.say("Checkpoint · algo acontece no pátio de química.",3)
 if not sighting_seen and player.position.distance_to(NIVEL.ponto(school,"avistamento"))<4 and phase=="investigate":
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
 if bag_found and not scare_played and player.position.distance_to(NIVEL.ponto(school,"susto")+Vector3(0,0,posmod(death_count,3)))<3:
  scare_played=true; scare_time=0; silhouette.visible=true
  view.trauma=.25
  impact_audio.stream=sfx["susto"]; impact_audio.play()

## Não salva com um cultista em cima: voltar do checkpoint seria morrer de novo.
func checkpoint_safe() -> bool:
 for e in enemies:
  if e.dead or e.down: continue
  if e.position.distance_to(player.position)<6 and (e.aware or e.suspicion>.4 or enemy_sees(e)): return false
 return true

func recording_eye() -> Vector3:
 return player.position+Vector3.UP*(1.0 if player.crouched else 1.55)

## Ao iniciar, valida pelo olho da gravação (câmera de lente), não pelo ombro:
## no vão da porta o ombro vê o ritual e a cabeça não, o que cancelava o REC.
func can_frame_ritual(from_eye:=false) -> bool:
 if not bag_found or player.position.y>1 or player.hidden: return false
 var at: Vector3=school.ritual_center+Vector3.UP*.7
 var from: Vector3=recording_eye() if from_eye else view.camera.global_position
 return from.distance_to(at)<14 and view.direction().dot((at-from).normalized())>.88 and visible_between(from,at)

func toggle_recording() -> void:
 if not bag_found:
  hud.say("O celular está na bolsa.",2); return
 if video_recorded: return
 if recording:
  recording=false; record_time=0
 elif can_frame_ritual(true):
  recording=true; record_time=0
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
  if e==enemies[0] and not sighting_seen and phase!="sighting":
   e.play("guarda"); e.animate(dt); continue
  if e.down:
   e.animate(dt)
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
   e.face(player.position,dt)
   e.animate(dt)
   view.trauma=maxf(view.trauma,.12)
   if e.clock>GRAB_TIME:
    e.state="idle"; e.clock=0; e.opening=.8
    player.state="idle"
    hurt_player(GRAB_DAMAGE)
    hud.say("Ele o machucou. Fuja antes que agarre de novo.",2)
   continue
  if e.state=="inspect":
   e.play("guarda"); e.animate(dt)
   e._bend("Chest",Vector3.ZERO,Vector3(.3,0,0)); e._bend("Head",Vector3.ZERO,Vector3(.2,0,0))
   e.rig.force_update_all_bone_transforms()
   if e.clock>1.6:
    e.state="idle"; e.suspicion=maxf(e.suspicion,.55)
    e.home=e.last_seen+Vector3(0,0,1.5)
   continue
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

## Ritmo (skills level-design/godot-genre-horror): trecho inicial antes do
## primeiro cultista ganhava só caminhada. Três sinais de inquietação, só
## ambiente (som/luz), sem susto barato nem fato novo de história.
var beats_done: Dictionary={}
var beat_lights: Array=[]
var beat_clock:=0.0

func _unease_beats() -> void:
 if beat_clock>0:
  beat_clock-=get_physics_process_delta_time()
  if beat_clock<=0:
   for light in beat_lights: light.light_energy=light.get_meta("energy",1.0)
   beat_lights.clear()
 if bag_found or alert_spread: return
 var px:=player.position
 if not beats_done.has("metal") and px.distance_to(NIVEL.ponto(school,"batida_metal"))<3.5:
  beats_done["metal"]=true
  impact_audio.stream=sfx["metal"]; impact_audio.global_position=px+view.direction()*-6; impact_audio.play()
  view.trauma=maxf(view.trauma,.12)
 if not beats_done.has("luzes") and px.distance_to(NIVEL.ponto(school,"batida_luzes"))<3.5:
  beats_done["luzes"]=true
  cult_audio.volume_db=-10
  get_tree().create_timer(4).timeout.connect(func(): cult_audio.volume_db=-18)
  for light in school.find_children("*","OmniLight3D",true,false):
   if light.global_position.distance_to(px+view.direction()*8)<7 and light!=school.flicker:
    light.set_meta("energy",light.light_energy); light.light_energy=0; beat_lights.append(light)
  beat_clock=2.2
 if not beats_done.has("passos") and px.distance_to(NIVEL.ponto(school,"batida_passos"))<3.5:
  beats_done["passos"]=true
  for i in 4:
   get_tree().create_timer(.45*i).timeout.connect(func():
    step_audio.global_position=player.position+Vector3(-4+i*1.5,0,-3)
    step_audio.pitch_scale=.8; step_audio.volume_db=-12; step_audio.play())

## Cultistas do ritual percebem Miguel (decisão: ritual já acontece na
## subida; ele passa escondido). Em transe: percebem devagar. Agachado no
## escuro demora; velas por perto ou lanterna aceleram. Se completar, o
## cultista interrompe o ritual e o alerta se espalha.
const RITUAL_SIGHT:=7.5
const RITUAL_RATE:=.42
var ritual_noticed:=false

func _ritual_watch(dt: float) -> void:
 if ritual_noticed or player.hidden: return
 for f in school.ritual_figures:
  var seen:=false
  if f.position.distance_to(player.position)<RITUAL_SIGHT and enemy_sees(f):
   seen=true
  if seen:
   var rate:=RITUAL_RATE*(.3 if player.crouched else 1.0)
   if phone_light: rate*=2.5
   for candle in school.candles:
    if candle.position.distance_to(player.position)<1.6: rate*=1.4; break
   if player.velocity.length()>2.5: rate*=1.6
   # Sombra da caixa da escada: lugar de espiar (decisão de Felipe).
   if school.na_sombra_da_escada(player.position): rate*=.35
   f.suspicion=minf(1,f.suspicion+dt*rate)
  else:
   f.suspicion=maxf(0,f.suspicion-dt*.08)
  if f.suspicion>=1:
   ritual_noticed=true
   f.aware=true; f.activity=""
   f.face(player.position)
   hud.say("Um dos encapuzados interrompe o canto e aponta para você.",4)
   view.trauma=.35
   _spread_alert(f)
   for e in enemies:
    if not e.dead: e.last_seen=player.position; e.memory=30
   return

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

## Único "ataque" de Miguel é o empurrão (ver shove()).
func _attack_tick(dt: float) -> void:
 _shove_tick(dt)

func hurt_player(damage: float) -> void:
 tool_active.clear()
 mouse_held=false
 _drop_load()
 super.hurt_player(damage)

func _player_tick(dt: float) -> void:
 if player.state=="grabbed":
  player.clock+=dt; player.animate(dt); return
 super._player_tick(dt)

func dodge() -> void:
 if player.state=="grabbed":
  grab_struggle+=1
  view.trauma=minf(.5,view.trauma+.15)
  if knife:
   knife=false; grab_struggle=GRAB_PRESSES
   hud.say("A faca o fez soltar. Corra.",2)
  if grab_struggle<GRAB_PRESSES: return
  player.state="idle"
  if is_instance_valid(action_target):
   action_target.state="hurt"; action_target.clock=0; action_target.opening=1.2
   action_target.move_and_collide((action_target.position-player.position).normalized()*.4)
  return
 super.dodge()

func _start_enemy_attack(e: CharacterBody3D) -> void:
 super._start_enemy_attack(e)
 step_audio.position=e.position
 step_audio.pitch_scale=.72; step_audio.volume_db=-18; step_audio.play()

## Terror: o cultista agarra em vez de trocar socos. Soltar-se exige insistir
## (Q ou clique direito); a faca solta na hora. Falhar custa muita vida.
const GRAB_TIME:=1.8
const GRAB_DAMAGE:=34.0
const GRAB_PRESSES:=4
var grab_struggle:=0

func _enemy_contact(e: CharacterBody3D) -> void:
 if player.hidden or not _hand_hits(e,player): return
 e.hit_once=true
 combat_stats["enemy_hits"]+=1
 _grab_player(e)

func _grab_player(e: CharacterBody3D) -> void:
 cancel_heal(); _drop_load()
 e.attack_target=null; e.strike_yaw_bias=0
 enemy_turn=null; turn_cooldown=1.0
 e.state="grab_hold"; e.clock=0
 e.anim.speed_scale=1.0; e.anim.play("actions/agarrao",.12)
 player.state="grabbed"; player.clock=0; player.velocity=Vector3.ZERO
 player.anim.speed_scale=1.4; player.anim.play("Body_Block",.12)
 player.face(e.position)
 action_target=e; grab_struggle=0
 impact_audio.stream=sfx["carne"]; impact_audio.play()
 hud.say("AGARRADO · aperte "+("ESQUIVA" if touch!=null else "[Q]")+" várias vezes para se soltar",GRAB_TIME)

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
   peek_door=null
   # Abre para longe de quem abre: de dentro não bate em Miguel; do corredor
   # abre para dentro e não tranca a passagem.
   if not door.opened: door.swing=1.65 if (player.position-door.global_position).dot(door.normal)>0 else -1.65
   door.toggle(); return
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
 if player.hidden: return "ESCONDIDO · observe e escute · [Espaço] Sair"
 if show_help: return "WASD mover · Espaço interagir · clique empurrar · Ctrl agachar · V gravar · L lanterna"
 for door in school.doors:
  if _near_looking(door.center(),1.8): return "[Espaço] "+("Fechar " if door.opened else "Abrir ")+door.title+(" · [F] Fresta" if not door.opened else "")
 for item in tools:
  if not item["taken"] and _near_looking(item["at"],1.5): return "[Espaço] Pegar "+item["name"]
 for prop in school.reactive:
  if prop.has_meta("use") and _near_looking(prop.position,1.5): return "[Espaço] Usar "+str(prop.get_meta("tool"))+" · "+str(prop.get_meta("use"))
 for item in world_objects:
  if not item["taken"] and _near_looking(item["node"].position,1.5): return "[Espaço] Pegar objeto · [T] Arremessar"
 var e=nearest_enemy(1.6,true)
 if e!=null and e.down: return "Ele vai levantar e chamar ajuda. Saia daqui."
 for item in school.pickups:
  if not item["taken"] and _near_looking(item["at"],1.5): return "[Espaço] Pegar "+item["kind"]
 for spot in school.hides:
  if _near_looking(spot["entry"]+Vector3.UP*.9,1.5): return "[Espaço] Esconder-se · quebre a visão antes"
 if e!=null and is_behind(e): return "Passe agachado · [Clique] empurrar o derruba, mas alerta"
 return ""

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

func _drop_load() -> void:
 if carried!=null:
  for item in world_objects:
   if item["node"]==carried: item["taken"]=false
 carried=null

func _loads_tick(dt: float) -> void:
 if carried!=null: carried.global_position=player.bone_point("RightHand")

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
 # Região da grade (células de 0,5 m) a partir do mapa, com margem da rua.
 var area: Rect2=school.limites().grow(2)
 path_grid.region=Rect2i(floori(area.position.x*2),floori(area.position.y*2),ceili(area.size.x*2),ceili(area.size.y*2))
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
 checkpoint["version"]=4 # 4: mapa em grade (02/11)
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
 if not saved is Dictionary or saved.get("version")!=4 or saved.get("enemies",[]).size()!=enemies.size(): return false
 checkpoint=saved; restore_checkpoint(); return true

func restore_checkpoint() -> void:
 if player.dead: death_count+=1
 super.restore_checkpoint()
 bag_found=bool(checkpoint.get("bag",false))
 alert_spread=bool(checkpoint.get("alert",false))
 # Ritual volta ao transe se o alerta salvo não existia.
 ritual_noticed=alert_spread
 for f in school.ritual_figures:
  f.suspicion=0; f.aware=false; f.activity="ritual"; f.face(school.ritual_center)
 video_recorded=bool(checkpoint.get("video",false))
 before_ritual=bool(checkpoint.get("before_ritual",false))
 sighting_seen=bool(checkpoint.get("sighting",false))
 scare_played=bool(checkpoint.get("scare",false)); silhouette.visible=false
 silhouette.position=NIVEL.ponto(school,"silhueta")+Vector3(0,0,posmod(death_count,3))
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
 player.position=NIVEL.ponto(school,"patio_aberto")
 view.yaw=PI/2
 await get_tree().create_timer(5).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../work/capitulo1.png"))
 get_tree().quit()

## Cultista calmo não faz parkour: a patrulha esbarrava em mesas e repetia o
## salto para sempre. Só quem está caçando Miguel pula obstáculos.
func try_vault(actor: CharacterBody3D,direction: Vector3,automatic: bool) -> bool:
 if actor.enemy and not actor.aware and not actor.pursuer: return false
 return super.try_vault(actor,direction,automatic)
