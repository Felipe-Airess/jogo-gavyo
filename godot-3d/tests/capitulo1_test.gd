extends SceneTree
const NIVEL=preload("res://capitulo1/nivel.gd")
var passed:=0
var failed:=0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
 if ok: passed+=1; print("PASS ",text)
 else: failed+=1; push_error("FAIL "+text)
func frames(n: int) -> void:
 for i in n: await physics_frame
func run() -> void:
 var deadline=create_timer(80,true,false,true)
 deadline.timeout.connect(func():push_error("CAPITULO TIMEOUT");quit(2))
 game=load("res://capitulo1/main.tscn").instantiate()
 root.add_child(game)
 game.set_physics_process(false)
 game.qa_mode=true
 await frames(3)
 check(game.school.rooms.size()>=28,"mapa contempla os blocos e todas as salas nomeadas")
 check(game.school.doors.size()>=26,"salas têm portas físicas e acessos")
 check(not game.bag_found and not game.phone_prop.visible,"Miguel começa sem celular")
 check(game.school.bag_at.y>3,"bolsa fica no andar superior")
 check(game.school.spawn.distance_to(game.school.ritual_center)>30,"ritual separado do pátio onde acorda")
 check(game.enemies.all(func(e):return e.home.x<0),"cultistas começam a partir do corredor interno")
 check(game.player.anim.has_animation("novo/Sprint"),"ciclo novo de corrida importado")
 game.player.velocity=Vector3(0,0,3.8); game.player.face(game.player.position+Vector3.BACK)
 game.player.play("correr"); game.player.animate(.1)
 check(game.player.motion.active_clip=="novo/Sprint" and game.player.motion.playback.get_current_node()=="Correr","corrida seleciona estado próprio com crossfade")
 for i in 240:
  game.player.play("correr"); game.player.animate(1.0/60)
 check(game.player.motion.playback.get_current_node()=="Correr","corrida contínua não reinicia arrancada")
 # Corredor superior inteiro, em pé e agachado, não vê o ritual.
 var seen_from: Array=[]
 var superior=game.school.andares[1]
 for v in superior.celulas("."):
  for eye in [1.0,1.5]:
   var origin: Vector3=game.school.cel(v.x,v.y,game.school.LEVEL+eye)
   if game.visible_between(origin,game.school.ritual_center+Vector3.UP*.7): seen_from.append([v,eye])
 print("RITUAL_VISTO_DE_CIMA ",seen_from)
 check(seen_from.is_empty(),"andar superior não permite observar o ritual")
 # Portas de todos os blocos liberam passagem ao abrir; não só a sala de teste.
 var blocked: Array[String]=[]
 for door in game.school.doors:
  door.set_open(true,true)
 await frames(2)
 for door in game.school.doors:
  var from: Vector3=door.center()+door.normal*.55
  var to: Vector3=door.center()-door.normal*.55
  if not game.visible_between(from,to): blocked.append(door.title)
 print("BLOCKED_DOORS ",blocked)
 check(blocked.is_empty(),"todas as portas abertas têm vãos desobstruídos")
 game.begin()
 check(game.phase=="intro","abertura integrada sem pular para sala de testes")
 game.end_intro()
 game.player.position=game.school.bag_at-Vector3.UP*1.01+Vector3(0,0,-.95)
 game.interact()
 for i in 180:
  game._player_tick(1.0/60); await physics_frame
 check(game.bag_found and game.checkpoint_index==1 and not game.school.bag.visible,"recuperar bolsa salva primeiro checkpoint")
 check(not game.checkpoint["alert"],"checkpoint da bolsa guarda ausência de alerta")
 game.alert_spread=true
 game.restore_checkpoint()
 check(not game.alert_spread,"restauração recupera alerta salvo, permitindo nova rota discreta")
 game.player.position=game.school.ritual_approach
 game._story_tick(.016)
 check(game.checkpoint_index==2 and game.before_ritual,"segundo checkpoint antes de se aproximar do ritual")
 game.player.position=NIVEL.ponto(game.school,"gravar")
 var target: Vector3=game.school.ritual_center+Vector3.UP*.7
 game.view.camera.global_position=game.player.position+Vector3.UP*1.5
 var delta: Vector3=target-game.view.camera.global_position
 game.view.yaw=atan2(-delta.x,-delta.z)
 game.view.pitch=asin(delta.normalized().y)
 print("FRAME_RITUAL ",game.can_frame_ritual()," ",game.player.position," ",delta.length())
 check(game.can_frame_ritual(),"ritual pode ser enquadrado manualmente no térreo")
 # No vão da porta o ombro pode ver o ritual sem que o olho da lente veja.
 var keep: Vector3=game.player.position
 game.player.position=NIVEL.ponto(game.school,"vao_do_patio")
 var eye: Vector3=game.recording_eye()
 var to_ritual: Vector3=target-eye
 game.view.yaw=atan2(-to_ritual.x,-to_ritual.z); game.view.pitch=asin(to_ritual.normalized().y)
 game.toggle_recording()
 check(not game.recording or game.can_frame_ritual(true),"REC só começa se a visão da lente enquadra o ritual")
 game.recording=false; game.record_time=0
 game.player.position=keep
 game.toggle_recording()
 game._story_tick(4.1)
 check(game.video_recorded and game.phase=="investigate" and game.pursuer==null,"rota discreta grava e continua sem perseguidor")
 game.phase="investigate"; game.alert_spread=true; game.video_recorded=true
 game.start_chase()
 check(game.phase=="discovery" and is_instance_valid(game.pursuer),"alerta espalhado habilita apresentação do perseguidor")
 check(game.checkpoint_index==2,"perseguição não cria checkpoint adicional")
 game.end_discovery(); game.view.update(1)
 check(game.view.mode=="first_person","controle da perseguição em primeira pessoa")
 game.player.position=game.school.gate_at-Vector3(0,0,1.5)
 game._story_tick(.1)
 # Aproximação e Interact completo (2 s) precedem a escalada.
 for i in 240:
  if game.phase=="gate_jump": break
  game._player_tick(1.0/60); await physics_frame
 check(game.phase=="gate_jump" and game.school.gate.collision_layer==1,"saída pula o portão, sem abri-lo")
 game.paused=false
 for i in 150:
  game._physics_process(1.0/60); await physics_frame
 check(game.phase=="ending" and game.player.position.z>game.school.gate_at.z,"transposição termina fora da escola")
 game.ending_clock=8; game._physics_process(.016); game.view.update(1)
 check(game.ending_set.visible,"encerramento mostra o quarto e os amigos")
 game.restore_checkpoint()
 game.phase="investigate"
 var e=game.enemies[1]
 e.aware=true; game.alert_spread=false
 game._spread_alert(e)
 check(game.alert_spread,"chamado concluído espalha alerta")
 game.alert_spread=false
 e.make_down(); e.health=30; e.help_clock=0
 game._enemy_ticks(4.1)
 check(e.state=="rising" and not game.alert_spread,"derrubado levanta antes de tentar chamar ajuda")
 game._enemy_ticks(3.8)
 check(e.state=="calling" and not game.alert_spread,"chamado tem preparação interrompível")
 var middle=InputEventMouseButton.new(); middle.button_index=MOUSE_BUTTON_MIDDLE; middle.pressed=true
 game._unhandled_input(middle)
 check(game.locked==null,"sem travar alvo de luta")
 check(not game.context_text().contains("finalizar"),"sem finalizações na interface")
 # O agarrão direcional (acerto, erro, prazo e item) tem suíte integrada própria:
 # capitulo1_escape_test.gd. Não repete a antiga mecânica de quatro apertos.
 game.player.state="idle"; game.food=1; game.player.health=40
 game.heal(); game.hurt_player(1)
 check(game.food==1,"dano cancela cura sem consumir item")
 # Escada atravessável com a cápsula real, sem teletransporte para o andar superior.
 # A escada fica no pátio de química (fechada), não na quadra.
 var climb: Vector3=(game.school.stairs_top-game.school.stairs_bottom)*Vector3(1,0,1)
 climb=climb.normalized()
 var saida_escada: Vector3=game.school.stairs_bottom-climb*2.5
 print("ESCADA_DESEMBOCA ",game.school.ambiente_de(saida_escada))
 check(game.school.ambiente_de(saida_escada)=="Pátio de química","escada sai do pátio de química")
 check(game.school.ambiente_de(saida_escada)!="Quadra coberta","escada não sai da quadra")
 game.player.position=game.school.stairs_bottom-climb*.8+Vector3.UP*.1
 game.player.velocity=Vector3.ZERO
 # O passo é o da captura original; a espera depende da velocidade permitida.
 var flight: Vector3=game.school.stairs_top-game.school.stairs_bottom
 var speed_limit: float=game.player.motion.strides["Ascending_Stairs"]["native_speed"]*1.8
 var stair_frames=ceili((Vector2(flight.x,flight.z).length()+3)/speed_limit*60)+120
 for i in stair_frames:
  var to_target: Vector3=climb if game.player.position.y<game.school.LEVEL-.05 else (NIVEL.ponto(game.school,"corredor_superior")-game.player.position)*Vector3(1,0,1)
  if to_target.length()<.3: break
  var v: Vector3=to_target.normalized()*2.0
  game.player.velocity.x=v.x; game.player.velocity.z=v.z
  game.player._slide(1.0/60)
  await physics_frame
 print("STAIR_RESULT ",game.player.position)
 for i in game.player.get_slide_collision_count():
  var contact=game.player.get_slide_collision(i)
  print("STAIR_CONTACT ",contact.get_collider().name," ",contact.get_normal()," ",contact.get_collider().global_position)
 check(game.player.position.y>3.2 and game.player.position.distance_to(NIVEL.ponto(game.school,"corredor_superior"))<.6,"subir a escada alcança corredor superior com colisão real")
 # Fechada: do patamar e do corredor não se vê o ritual.
 check(not game.visible_between(game.school.stairs_top+Vector3.UP*1.5,game.school.ritual_center+Vector3.UP*.7),"caixa da escada não deixa ver o ritual")
 # Mas da entrada, agachado, dá para espiar.
 var peek: Vector3=NIVEL.ponto(game.school,"espiar",1.0)
 check(game.visible_between(peek,game.school.ritual_center+Vector3.UP*.7),"entrada da escada permite espiar o ritual")
 print("CAPITULO1_TEST: %d passed, %d failed"%[passed,failed])
 game.queue_free(); await process_frame
 quit(1 if failed else 0)
