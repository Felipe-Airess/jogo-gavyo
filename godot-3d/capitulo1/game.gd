extends "res://prototipo/game.gd"
## Capítulo 1 integrado. Mantém a revisão 2 como referência separada.
const CAMPUS=preload("res://capitulo1/mapa/escola_grade.gd")
const NIVEL=preload("res://capitulo1/nivel.gd")
const PERSON=preload("res://capitulo1/ator.gd")
const CHAPTER_HUD=preload("res://capitulo1/hud.gd")
const CHAPTER_CAMERA=preload("res://capitulo1/camera.gd")
const TOUCH=preload("res://capitulo1/toque.gd")
const ACTIONS=preload("res://capitulo1/acoes.gd")
const ESCAPE=preload("res://capitulo1/escape.gd")
var escape=ESCAPE.new()
var escape_blackout:=0.0
var escape_advantage_until:=0.0
## Gancho do futuro item único; não há pickup nem finalização nesta etapa.
var finisher_item_available:=false
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
var pressure=preload("res://capitulo1/pressao.gd").new()
var tension: AudioStreamPlayer
var sound: Node
var gate_sound_played:=false
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
 # Postos marcados na grade do mapa (1–7 em capitulo1/mapa/terreo.txt).
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

## Ambiente/respiração sem equivalente permanecem. Efeitos usam o pacote importado.
func _audio() -> void:
 sound=load("res://capitulo1/sons.gd").new(); add_child(sound); sound.setup(self)
 ambience=AudioStreamPlayer.new(); ambience.bus="CapituloAmbiente"
 ambience.stream=load("res://prototipo/audio/grilos.wav").duplicate()
 ambience.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
 ambience.stream.loop_end=int(ambience.stream.get_length()*ambience.stream.mix_rate)
 ambience.volume_db=-17; add_child(ambience); ambience.play()
 cult_audio=AudioStreamPlayer3D.new(); cult_audio.bus="CapituloAmbiente"
 cult_audio.position=school.ritual_center; cult_audio.unit_size=4; cult_audio.max_distance=26
 cult_audio.stream=load("res://capitulo1/assets/culto.wav").duplicate()
 cult_audio.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
 cult_audio.stream.loop_end=int(cult_audio.stream.get_length()*cult_audio.stream.mix_rate)
 cult_audio.pitch_scale=.76; cult_audio.volume_db=-18; add_child(cult_audio); cult_audio.play()
 step_audio=AudioStreamPlayer3D.new(); add_child(step_audio); sound.configure(step_audio,10,3)
 sound.prepare(step_audio,"cimento",-6)
 impact_audio=AudioStreamPlayer3D.new(); add_child(impact_audio); sound.configure(impact_audio,10,3)
 sound.prepare(impact_audio,"impacto_parede",-3)
 # O pacote recebido informa que não inclui respiração humana. Preserva o provisório.
 breathing=AudioStreamPlayer.new(); breathing.bus="CapituloVoz"
 breathing.stream=load("res://capitulo1/assets/respiracao.wav").duplicate()
 breathing.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
 breathing.stream.loop_end=int(breathing.stream.get_length()*breathing.stream.mix_rate)
 breathing.volume_db=-38; add_child(breathing)
 # [PROVISÓRIO] Pulso/drone sintetizado localmente; a trilha final virá de Felipe.
 tension=AudioStreamPlayer.new(); tension.bus="CapituloAmbiente"
 tension.stream=load("res://capitulo1/assets/tensao_provisoria.wav").duplicate()
 tension.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
 tension.stream.loop_end=int(tension.stream.get_length()*tension.stream.mix_rate)
 tension.volume_db=-60; add_child(tension)

func spawn_actor(at: Vector3,is_enemy: bool,big:=false) -> CharacterBody3D:
 var actor=PERSON.new()
 actor.style=spawn_style%3
 spawn_style+=1
 add_child(actor)
 actor.setup(self,at,is_enemy,big)
 # Biblioteca nova instalada pelo controlador compartilhado.
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
 if escape_blackout>0: return
 if escape.active:
  if event is InputEventKey and event.pressed and not event.echo:
   if event.keycode==KEY_ESCAPE:
    paused=not paused; mouse_held=false
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if paused or touch!=null else Input.MOUSE_MODE_CAPTURED
   elif not paused:
    escape_direction(event.physical_keycode if event.physical_keycode!=0 else event.keycode)
  return
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
   MOUSE_BUTTON_RIGHT:
    _drop_load(); dodge()

const CONTACT=preload("res://capitulo1/animacoes/contato.gd")
var interaction: Dictionary={}

func _process(dt: float) -> void:
 pressure.tick(self,dt)
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
 sound.tick(dt)
 if silhouette.visible:
  scare_time+=dt
  if scare_time>.2: silhouette.visible=false

func _physics_process(dt: float) -> void:
 if escape_blackout>0:
  _escape_tick(dt); return
 if paused or player.dead or phase=="escaped": return
 elapsed+=dt
 if escape.active:
  _escape_tick(dt); return
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
  var desired=gate_from
  if t<.42:
   desired.y+=smoothstep(0,.42,t)*2.55
  elif t<.76:
   desired=gate_from.lerp(gate_to,smoothstep(.42,.76,t))+Vector3.UP*2.55
  else:
   desired=gate_to+Vector3.UP*2.55*(1-smoothstep(.76,1,t))
  player.position=desired
  player.animate(dt)
  if not gate_sound_played and player.motion.position()>=.25:
   sound.emit_at("portao",school.gate_at); gate_sound_played=true
  if t>.10 and t<.34 and not player.motion.locomotion_visible():
   for side in ["Left","Right"]:
    var offset=.19 if side=="Left" else -.19
    CONTACT.hand_fit(player,side,school.gate_at+Vector3(offset,2.35,0),smoothstep(0,.12,player.motion.position())*(1-smoothstep(.15,.25,player.motion.position())))
  if t>=1 and player.motion.consume("finished"):
   phase="ending"; ending_clock=0
   player.state="idle"; player.play("guarda"); player.animate(0)
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
 turn_cooldown=maxf(0,turn_cooldown-dt)
 if not tool_active.is_empty():
  _tool_tick(dt)
 else: _player_tick(dt)
 if protected_target!=null and player.state not in ["attack","pair"]: protected_target=null
 _enemy_ticks(dt)
 if escape.active: return
 _pursuer_tick(dt)
 if escape.active: return
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
  sound.emit_at("grito",silhouette.global_position,-9)

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
 if player.state=="interaction": return
 _begin_interaction("gate",school.gate,school.gate_at+Vector3.UP*1.1,Vector3.BACK,"novo/Interact")

func _jump_gate_now() -> void:
 gate_sound_played=false
 phase="gate_jump"
 story_clock=0
 gate_from=player.position
 gate_to=school.gate_at+Vector3(0,0,2.8)
 player.state="gate_jump"
 player.clock=0
 player.face(gate_to)
 player.start_action("novo/ClimbUp_1m",.6666667/2.2)
 player.collision_layer=0
 locked=null

func start_chase() -> void:
 if not alert_spread or not video_recorded or phase!="investigate": return
 phase="discovery"
 discovery_clock=0
 locked=null; protected_target=null; enemy_turn=null
 player.state="idle"
 recording=true
 pursuer=spawn_actor(school.pursuer_post,true,true)
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
 if escape.active or escape_blackout>0: return
 for e in enemies:
  e.clock+=dt
  e.opening=maxf(0,e.opening-dt)
  if e.dead: e.animate(dt); continue
  if e.state=="escape_stunned":
   e.animate(dt)
   if e.clock>=2.0: e.state="idle"; e.play("guarda")
   continue
  if not e.down and phase in ["investigate","chase"] and _grab_player(e): return
  if e.state=="escape_stunned": continue
  if e==enemies[0] and not sighting_seen and phase!="sighting":
   e.play("guarda"); e.animate(dt); continue
  if e.down:
   e.velocity.y=0
   e.move_and_collide(e.velocity*dt)
   e.velocity=e.velocity.move_toward(Vector3.ZERO,dt*5)
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
   if e.motion.consume("finished") or e.clock>=e.anim.get_animation("novo/LayToIdle").length/1.5:
    e.state="calling"; e.clock=0; e.alert_attempt=true; e.play("guarda")
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
   e.animate(dt); continue
  if e.state=="inspect":
   e.play("guarda"); e.animate(dt)
   if not e.motion.locomotion_visible():
    e._bend("Chest",Vector3.ZERO,Vector3(.3,0,0)); e._bend("Head",Vector3.ZERO,Vector3(.2,0,0))
   e.rig.force_update_all_bone_transforms()
   if e.clock>1.6:
    e.state="idle"; e.suspicion=maxf(e.suspicion,.55)
   continue
  if phase not in ["investigate","chase","sighting"]:
   e.animate(dt); continue
  if phase=="sighting": e.play("guarda"); e.animate(dt); continue
  if not e.aware and elapsed<disturbance_until and e.position.distance_to(disturbance)<10:
   e.last_seen=disturbance; e.suspicion=maxf(e.suspicion,.4); e.memory=maxf(e.memory,8)
  e.hunt.tick(self,e,dt)
  e.animate(dt)
  if escape.active: return
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
  sound.emit_at("impacto_metal",px+view.direction()*-6)
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
    sound.emit_at("cimento",player.position+Vector3(-4+i*1.5,0,-3),-4))

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

func hurt_player(damage: float) -> void:
 _cancel_interaction()
 tool_active.clear()
 mouse_held=false
 _drop_load()
 super.hurt_player(damage)

const DODGE_AVAILABLE:=false

func _player_tick(dt: float) -> void:
 # Desliga só o temporizador legado; sons.tick mede deslocamento real e piso.
 footstep_time=1000.0
 if player.state=="interaction":
  _interaction_tick(dt); return
 if player.state=="grabbed":
  player.clock+=dt; player.animate(dt); return
 super._player_tick(dt)

func dodge() -> void:
 # Roll permanece desativado. O escape agora aceita somente a sequência de setas.
 return

func _start_enemy_attack(e: CharacterBody3D) -> void:
 enemy_turn=e; e.state="windup"; e.clock=0; e.hit_once=false; e.attack_landed=false
 e.attack_target=player; e.strike_yaw_bias=0; e.velocity=Vector3.ZERO
 e.face(player.position)
 e.start_action("novo/AgarrarEntrada")
 combat_stats["enemy_attacks"]+=1
 sound.footstep(e)

## Contato abre uma sequência; apenas o AnimationTree avalia os clipes originais.
func _enemy_contact(e: CharacterBody3D) -> void:
 if _grab_player(e):
  e.hit_once=true
  combat_stats["enemy_hits"]+=1

func _grab_player(e: CharacterBody3D) -> bool:
 if escape.active or escape_blackout>0 or player.dead or player.hidden or paused: return false
 if elapsed<escape_advantage_until or e.dead or e.down or e.state=="escape_stunned": return false
 if phase not in ["investigate","chase"]: return false
 var delta: Vector3=(player.position-e.position)*Vector3(1,0,1)
 var radius=.35 if e.pursuer else .27
 if delta.length()>.27+radius+.10 or absf(player.position.y-e.position.y)>.2: return false
 if delta.length()<.01 or not visible_between(e.bone_point("Chest"),player.bone_point("Chest")): return false
 # Move só o corpo pela física. Nunca teletransporta os quadris nem modifica ossos.
 e.move_and_collide(delta.normalized()*(delta.length()-(.27+radius+.04)))
 if player.position.distance_to(e.position)<.27+radius+.005: return false
 if finisher_item_available and not e.pursuer:
  finisher_item_available=false
  _escape_release(e)
  hud.say("O item evitou o agarrão.",2)
  return false
 cancel_heal(); _drop_load(); _cancel_interaction()
 recording=false; peek_door=null; tool_active.clear(); mouse_held=false
 if touch!=null: touch.release_all()
 _crouch(false)
 e.attack_target=null; e.strike_yaw_bias=0; e.velocity=Vector3.ZERO
 enemy_turn=null; turn_cooldown=1.0
 e.state="grab_hold"; e.clock=0; e.face(player.position)
 e.start_action("actions/agarrao")
 player.state="grabbed"; player.clock=0; player.velocity=Vector3.ZERO
 player.start_action("Body_Block"); player.face(e.position)
 action_target=e; escape.start()
 sound.emit_at("agarrao",player.position)
 sound.emit_at("roupa",player.position,-8)
 hud.say("AGARRADO · repita as setas da esquerda para a direita",escape.limit)
 return true

func escape_direction(code: int) -> void:
 if paused or escape_blackout>0: return
 var previous=escape.cursor
 var result=escape.press(code)
 if escape.cursor>previous: sound.ui("seta")
 if result<0: sound.ui("erro")
 if result<0: _escape_failure()
 elif result>0:
  sound.ui("sucesso")
  _escape_release(action_target)
  hud.say("Livre. Corra!",1.5)

func _escape_release(e: CharacterBody3D) -> void:
 player.state="idle"; player.velocity=Vector3.ZERO; player.play("guarda")
 if is_instance_valid(e):
  var back=(player.position-e.position)*Vector3(1,0,1)
  # Recuo de 30 cm com colisão; parede pode limitar a distância.
  if back.length()>.001: player.move_and_collide(back.normalized()*.30)
  e.state="escape_stunned"; e.clock=0; e.opening=2.0; e.velocity=Vector3.ZERO
  e.attack_target=null; e.play("guarda")
 escape_advantage_until=elapsed+1.5
 action_target=null; enemy_turn=null; turn_cooldown=1.5
 if touch!=null: touch.release_all()

func _escape_failure() -> void:
 sound.ui("falha")
 escape.active=false; escape_blackout=1.5
 player.dead=true; player.velocity=Vector3.ZERO
 # [PROVISÓRIO: trocar pela cena de morte quando chegarem as animações]
 hud.show_escape_blackout(true)
 if touch!=null: touch.release_all()

func _escape_tick(dt: float) -> void:
 if escape_blackout>0:
  escape_blackout=maxf(0,escape_blackout-dt)
  if escape_blackout<=0: restore_checkpoint()
  return
 player.clock+=dt; player.animate(dt)
 for e in enemies: e.animate(dt)
 if is_instance_valid(pursuer): pursuer.animate(dt)
 if escape.tick(dt): _escape_failure()

## Sobrescreve a morte/faca instantânea da base: perseguidor também abre sequência.
func _grab() -> void:
 if not is_instance_valid(pursuer): return
 if player.hidden: _leave_hide()
 _grab_player(pursuer)

func interact() -> void:
 if player.hidden: _leave_hide(); return
 if player.state=="hang":
  vault["climb"]=true; player.clock=float(vault["hang_clock"]); player.state="vault"; return
 if player.state not in ["idle","heal","hang"] and not player.hidden: return
 if not bag_found and player.position.distance_to(school.bag_at)<1.7 and player.position.y>2.5:
  _begin_interaction("bag",school.bag,school.bag_at,Vector3.ZERO,"novo/PickUp_Table"); return
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
   if door.moving: return
   var side=1.0 if (player.position-door.global_position).dot(door.normal)>0 else -1.0
   var handle: Vector3=door.handle_point(side)
   _begin_interaction("door",door,handle,-door.normal*side,"novo/Interact"); return
 for item in school.pickups:
  if not item["taken"] and _near_looking(item["at"],1.5):
   item["taken"]=true; item["node"].visible=false
   if item["kind"]=="empanado": food+=1
   else: knife=true
   hud.say("Empanado guardado." if item["kind"]=="empanado" else "Faca guardada.",2)
   return
 for i in school.hides.size():
  if _near_looking(school.hides[i]["entry"]+Vector3.UP*.9,1.5):
   var hide=school.hides[i]
   _begin_interaction("hide",null,hide["inside"]+hide["normal"]*.38+Vector3.UP*1.05,-hide["normal"],"novo/Chest_Open",i); return
 var direction: Vector3=view.movement(raw_movement())
 try_vault(player,player.facing if direction.length()<.1 else direction,false)

func _near_looking(at: Vector3,distance: float) -> bool:
 var delta=at-(player.position+Vector3.UP*.9)
 return delta.length()<distance and view.direction().dot(delta.normalized())>.25

## Oculto não é visível. Saber onde entrou é memória individual, não visão.
func enemy_sees(actor: CharacterBody3D,ignore_facing:=false) -> bool:
 if player.hidden: return false
 return super.enemy_sees(actor,ignore_facing)

var hide_witnesses: Dictionary={}
func _record_hide_witnesses() -> void:
 for e in enemies:
  if not e.dead and not e.down and enemy_sees(e): hide_witnesses[e.get_instance_id()]=true
 if is_instance_valid(pursuer) and enemy_sees(pursuer): hide_witnesses[pursuer.get_instance_id()]=true

func _enter_hide(index: int) -> void:
 _record_hide_witnesses()
 var witnessed=false
 for e in enemies:
  e.hunt.witnessed_hide=index if hide_witnesses.has(e.get_instance_id()) else -1
  if e.hunt.witnessed_hide==index:
   witnessed=true; e.last_seen=school.hides[index]["entry"]; e.aware=true
   if e.hunt.mode=="patrol": e.hunt.mode="last_seen"
 var pursuer_saw=is_instance_valid(pursuer) and hide_witnesses.has(pursuer.get_instance_id())
 super._enter_hide(index)
 # A flag da base serve apenas ao perseguidor; nunca herda a visão de outro NPC.
 seen_hiding=pursuer_saw
 if pursuer_saw:
  pursuer.last_seen=school.hides[index]["entry"]; pursuit_memory=9
 school.set_hide_open(index,false)
 hide_witnesses.clear()
 hud.say("Ele viu onde você entrou!" if witnessed or pursuer_saw else "Fique quieto. Escute os passos.",2)

func _leave_hide() -> void:
 if hidden_spot>=0: school.set_hide_open(hidden_spot,true)
 super._leave_hide()
 for e in enemies: e.hunt.witnessed_hide=-1
 hide_witnesses.clear()

## Vocalizações monstruosas fornecidas por Felipe, carregadas como recursos.
func _cultist_shout(e: CharacterBody3D) -> void:
 sound.shout(e)
 _spread_alert(e)
 hud.say("Um cultista gritou. Corra!",2)

func context_text() -> String:
 if escape.active or escape_blackout>0: return ""
 if phase in ["intro","sighting","discovery","gate_jump","ending"]: return ""
 if not tool_active.is_empty(): return "USANDO FERRAMENTA · mover ou sofrer dano interrompe"
 if recording: return "● REC  %02d s · mantenha o ritual enquadrado"%int(record_time)
 if not bag_found and _near_looking(school.bag_at,1.7): return "[Espaço] Pegar bolsa e celular"
 if bag_found and not video_recorded and can_frame_ritual(): return "[V] Gravar vídeo do ritual"
 if video_recorded and player.position.distance_to(school.gate_at)<3: return "[Espaço] Pular o portão 1"
 if carried!=null: return "[T / clique] Arremessar objeto · clique direito solta a carga"
 if player.hidden: return "ESCONDIDO · observe e escute · [Espaço] Sair"
 if show_help: return "WASD mover · Espaço interagir · Ctrl agachar · V gravar · L lanterna"
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
 if e!=null and is_behind(e): return "Passe agachado sem chamar atenção"
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
 if escape.active or escape_blackout>0: return
 if is_instance_valid(pursuer) and pursuer.state=="escape_stunned":
  pursuer.clock+=dt; pursuer.animate(dt)
  if pursuer.clock>=2.0: pursuer.state="idle"; pursuer.play("guarda")
  return
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
   if pursuer.position.distance_to(entry)<1.1 and player.hidden and seen_hiding and hidden_spot==index: _grab()
   return
 # A base para a 0,83 m: aqui aproxima até o contato real das cápsulas.
 if is_instance_valid(pursuer) and phase=="chase" and not player.hidden and pursuer.position.distance_to(player.position)<.83:
  if not _grab_player(pursuer):
   _navigate(pursuer,player.position,3.55,dt); pursuer.animate(dt)
  return
 super._pursuer_tick(dt)

func _navigate(actor: CharacterBody3D,target: Vector3,speed: float,dt: float) -> void:
 if target.y>2.5 and actor.position.y<3.2:
  if actor.position.distance_to(school.stairs_bottom)<1.4: actor.set_meta("subindo",true)
  if actor.get_meta("subindo",false):
   actor.move_toward(school.stairs_top,speed,dt)
   actor.play("correr" if speed>2.5 else "andaFrente"); return
  super._navigate(actor,school.stairs_bottom,speed,dt); return
 if actor.position.y>2.5 and target.y<1:
  if Vector2(actor.position.x-school.stairs_top.x,actor.position.z-school.stairs_top.z).length()<1.2:
   actor.set_meta("descendo",true)
  if actor.get_meta("descendo",false):
   actor.move_toward(school.stairs_bottom,speed,dt)
   actor.play("correr" if speed>2.5 else "andaFrente"); return
  actor.move_toward(school.stairs_top,speed,dt); actor.play("correr" if speed>2.5 else "andaFrente"); return
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
 pressure.reset(self)
 sound.reset()
 escape.clear(); escape_blackout=0; escape_advantage_until=0
 hud.show_escape_blackout(false)
 if touch!=null: touch.release_all()
 _cancel_interaction()
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
  e.hunt.reset()
  if is_instance_valid(e.hunt_voice): e.hunt_voice.stop()
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
 for i in school.hides.size(): school.set_hide_open(i,false,true)
 hide_witnesses.clear()
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
 var event="impacto_corpo" if gore else "impacto_parede"
 for prop in school.reactive:
  if prop.position.distance_to(at)<1.2 and not gore:
   var material=String(prop.get_meta("kind",""))
   event="impacto_metal" if material=="metal" else "impacto_madeira" if material=="wood" else "impacto_parede"
   break
 sound.prepare(impact_audio,event,-3)
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

## Aproximação varrida, contato no clipe e concessão apenas após tocar o objeto.
func _begin_interaction(kind: String,object: Node3D,contact: Vector3,direction: Vector3,clip: String,index:=-1) -> void:
 var forward=direction
 if forward.length()<.1: forward=((contact-player.position)*Vector3(1,0,1)).normalized()
 var right=Vector3(forward.z,0,-forward.x)
 if kind=="bag": contact-=forward*.16
 var anchor=contact-forward*.52-right*.12
 anchor.y=player.position.y
 if not CONTACT.room_for(player,anchor):
  hud.say("Aproxime-se pelo lado livre.",1.5); return
 if kind=="hide": hide_witnesses.clear(); _record_hide_witnesses()
 interaction={"kind":kind,"object":object,"contact":contact,"anchor":anchor,"forward":forward,"clip":clip,"index":index,"started":false,"committed":false,"elapsed":0.0}
 player.state="interaction"; player.velocity=Vector3.ZERO
 player.play("guarda")

func _cancel_interaction() -> void:
 if interaction.is_empty(): return
 if interaction.get("kind")=="hide": hide_witnesses.clear()
 interaction.clear()
 if player.state=="interaction": player.state="idle"; player.play("guarda")

func _interaction_tick(dt: float) -> void:
 if interaction.is_empty(): player.state="idle"; return
 if raw_movement().length()>.1: _cancel_interaction(); return
 if interaction["kind"]=="hide": _record_hide_witnesses()
 interaction["elapsed"]+=dt
 if interaction["elapsed"]>4.0: _cancel_interaction(); return
 if interaction["kind"] in ["door","bag"] and not is_instance_valid(interaction["object"]): _cancel_interaction(); return
 var anchor: Vector3=interaction["anchor"]
 player.face(player.position+interaction["forward"],dt)
 if not interaction["started"]:
  var delta=anchor-player.position
  if delta.length()>.025:
   player.velocity=delta.normalized()*minf(1.4,delta.length()/maxf(dt,.001))
   player.move_and_collide(player.velocity*dt)
   player.play("andaFrente"); player.animate(dt); return
  player.velocity=Vector3.ZERO
  player.start_action(interaction["clip"]); interaction["started"]=true
 player.animate(dt)
 var clip=String(interaction["clip"])
 var time=player.motion.position()
 var contact_time=.72 if clip.ends_with("Interact") else (.30 if clip.ends_with("PickUp_Table") else .60)
 var weight=smoothstep(0,contact_time,time)*(1-smoothstep(contact_time+.12,contact_time+.45,time))
 var fitted=false
 if not player.motion.locomotion_visible(): fitted=CONTACT.hand_fit(player,"Left",interaction["contact"],weight)
 if player.motion.consume("contact") and not interaction["committed"]:
  var target: Vector3=interaction["contact"]
  if not fitted or player.bone_point("LeftHand").distance_to(target)>.09:
   _cancel_interaction(); return
  interaction["committed"]=true
  match interaction["kind"]:
   "bag":
    bag_found=true; school.bag.visible=false; checkpoint_index=1
    sound.emit_at("bolsa",school.bag_at,-5)
    _snapshot(); hud.say("Bolsa e celular recuperados. Desça e procure a origem das vozes.",5)
   "door":
    var door=interaction["object"]
    peek_door=null
    if not door.opened: door.swing=1.65 if (player.position-door.global_position).dot(door.normal)>0 else -1.65
    door.toggle()
   "hide": school.set_hide_open(int(interaction["index"]),true)
   # Portão e armário aguardam o fim do gesto após o contato.
 if player.motion.consume("finished"):
  var completed=interaction
  interaction={}
  player.state="idle"; player.play("guarda")
  if completed["committed"]:
   if completed["kind"]=="gate": _jump_gate_now()
   elif completed["kind"]=="hide": _enter_hide(int(completed["index"]))
