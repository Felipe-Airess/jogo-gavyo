extends SceneTree
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
 check(game.player.anim.has_animation("Running"),"corrida capturada existente disponível")
 game.player.velocity=Vector3(0,0,3.4)
 game.player.play("correr")
 check(game.player.anim.current_animation=="correr","corrida não usa o ciclo procedural")
 var origin: Vector3=game.school.p(130,78,game.school.LEVEL+1.5)
 check(not game.visible_between(origin,game.school.ritual_center+Vector3.UP*.7),"andar superior não permite observar o ritual")
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
 game.player.position=game.school.bag_at-Vector3.UP*1.01+Vector3(.95,0,0)
 game.interact()
 check(game.bag_found and game.checkpoint_index==1 and not game.school.bag.visible,"recuperar bolsa salva primeiro checkpoint")
 check(not game.checkpoint["alert"],"checkpoint da bolsa guarda ausência de alerta")
 game.alert_spread=true
 game.restore_checkpoint()
 check(not game.alert_spread,"restauração recupera alerta salvo, permitindo nova rota discreta")
 game.player.position=game.school.ritual_approach
 game._story_tick(.016)
 check(game.checkpoint_index==2 and game.before_ritual,"segundo checkpoint antes de se aproximar do ritual")
 game.player.position=game.school.p(323,62)
 var target: Vector3=game.school.ritual_center+Vector3.UP*.7
 game.view.camera.global_position=game.player.position+Vector3.UP*1.5
 var delta: Vector3=target-game.view.camera.global_position
 game.view.yaw=atan2(-delta.x,-delta.z)
 game.view.pitch=asin(delta.normalized().y)
 print("FRAME_RITUAL ",game.can_frame_ritual()," ",game.player.position," ",delta.length())
 check(game.can_frame_ritual(),"ritual pode ser enquadrado manualmente no térreo")
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
 check(game.phase=="gate_jump" and game.school.gate.collision_layer==1,"saída pula o portão, sem abri-lo")
 game.story_clock=2.3; game.paused=false; game._physics_process(.016)
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
 e.style=0; game.action_target=e; game.attack_mode="normal"; game.heavy_attack=false
 game._land_hit(e,e.position+Vector3.UP)
 check(e.state!="calling" and not game.alert_spread,"golpe interrompe chamado comum")
 game.player.state="idle"; game.player.position=game.school.p(500,320)
 game.attack()
 check(game.player.state=="attack","ataque funciona sem esperar esquiva perfeita")
 var click=InputEventMouseButton.new(); click.button_index=MOUSE_BUTTON_LEFT; click.pressed=true
 game._unhandled_input(click)
 check(game.buffered_attack and game.fatigue==0,"um próximo comando guardado não cansa")
 game._unhandled_input(click)
 check(game.fatigue>0,"cliques extras com comando guardado acumulam fadiga")
 game.hurt_player(1)
 check(game.player.state=="hurt" and not game.buffered_attack,"tomar golpe interrompe ação e sequência")
 game.player.state="idle"; game.food=1; game.player.health=40
 game.heal(); game.hurt_player(1)
 check(game.food==1,"dano cancela cura sem consumir item")
 # Contato do clipe real: a checagem não chama _land_hit diretamente.
 game.player.state="idle"; game.player.clock=0; game.player.health=100
 game.player.position=game.school.p(500,480)
 game.player.velocity=Vector3.ZERO
 game.fatigue=0; game.chain_step=0; game.protected_target=null
 e.position=game.player.position+Vector3(0,0,-.9)
 e.health=100; e.down=false; e.dead=false; e.style=0; e.state="idle"; e.aware=true
 e.collision_layer=2
 for area in e.hurt_areas: area.collision_layer=4
 e.face(game.player.position); e.play("guarda"); e.animate(.2)
 game.player.face(e.position); game.player.play("guarda"); game.player.animate(.2)
 await frames(2)
 game.attack()
 for i in 85:
  game._player_tick(1.0/60); game._enemy_ticks(1.0/60)
  await physics_frame
 print("PUNCH_RESULT ",e.health," ",game.profiles["jab"])
 check(e.health<100,"soco causa dano pela trajetória física do clipe")
 game.player.state="idle"; game.player.clock=0; game.chain_step=0
 e.health=25; e.make_down(); e.animate(2)
 game.player.position=e.bone_point("Head")+Vector3(0,0,.8)
 game.player.position.y=0
 await frames(2)
 game.attack()
 for i in 320:
  game._player_tick(1.0/60); game._enemy_ticks(1.0/60)
  await physics_frame
 print("GROUND_RESULT ",e.health," ",game.profiles["Brutal_Assassination"])
 check(e.health<25,"ação no chão usa clipe ajoelhado e contato real")
 game.player.state="idle"; game.player.clock=0; game.player.position=e.position+Vector3(0,0,.9)
 game.player.position.y=0
 e.health=100; e.dead=false; e.down=false; e.state="idle"; e.clock=0; e.style=0; e.opening=1
 e.collision_layer=2
 for area in e.hurt_areas: area.collision_layer=4
 e.play("guarda"); e.animate(.2); e.face(game.player.position)
 await frames(2)
 game.takedown_or_finish()
 for i in 100:
  game._player_tick(1.0/60); game._enemy_ticks(1.0/60)
  await physics_frame
 print("TAKEDOWN_RESULT ",e.health," ",e.down)
 check(e.down,"sequência de derrubada exige contato real da pegada")
 for kind in ["parede","armário","mesa"]:
  var start: Vector3=game.school.p(500+(["parede","armário","mesa"].find(kind))*65,540)
  game.player.position=start; game.player.state="idle"; game.player.clock=0; game.fatigue=0
  e.position=start+Vector3(0,0,-.7)
  e.dead=false; e.down=false; e.health=30; e.style=0; e.state="idle"; e.opening=.5; e.clock=0; e.traversal={}
  e.collision_layer=2
  for area in e.hurt_areas: area.collision_layer=4
  e.play("guarda"); e.animate(.3); e.face(game.player.position)
  if kind=="mesa": game.school.table(e.position+Vector3(0,0,-.9),1.7,1.0)
  else: game.school.box(Vector3(2,2.5,.3),e.position+Vector3(0,1.25,-.9),"metal" if kind=="armário" else "wall")
  game.player.play("guarda"); game.player.animate(.3)
  await frames(2)
  game.takedown_or_finish()
  check(game.pair_context.get("kind","")==kind,"finalização detecta contexto de "+kind)
  for i in 145:
   game._player_tick(1.0/60); game._enemy_ticks(1.0/60)
   await physics_frame
  print("ENVIRONMENT_FINISH ",kind," health=",e.health," at=",e.position)
  check(e.health==0 and e.down,"finalização em "+kind+" conclui após contato da pegada")
 # Escada atravessável com a cápsula real, sem teletransporte para o andar superior.
 game.player.position=game.school.stairs_bottom+Vector3(0,.1,.8)
 game.player.velocity=Vector3.ZERO
 for i in 450:
  game.player.velocity.x=0; game.player.velocity.z=-2.0
  game.player._slide(1.0/60)
  await physics_frame
 print("STAIR_RESULT ",game.player.position)
 for i in game.player.get_slide_collision_count():
  var contact=game.player.get_slide_collision(i)
  print("STAIR_CONTACT ",contact.get_collider().name," ",contact.get_normal()," ",contact.get_collider().global_position)
 check(game.player.position.y>3.2 and game.player.position.z<game.school.stairs_top.z-.2,"subir a escada alcança corredor superior com colisão real")
 print("CAPITULO1_TEST: %d passed, %d failed"%[passed,failed])
 game.queue_free(); await process_frame
 quit(1 if failed else 0)
