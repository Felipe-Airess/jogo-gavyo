extends SceneTree
## Integração da segunda versão: narrativa, portas e troca real sem IK de braço.
var game: Node3D
var passed:=0
var failed:=0

func _initialize() -> void:
 call_deferred("run")

func check(value: bool, description: String) -> void:
 if value:
  passed+=1
  print("PASS ",description)
 else:
  failed+=1
  push_error("FAIL "+description)

func frames(count: int) -> void:
 for i in count:
  await physics_frame

func ticks(count: int) -> void:
 for i in count:
  game._physics_process(1.0/60)
  await physics_frame

func arena() -> void:
 game.restore_checkpoint()
 game.paused=false
 game.started=true
 game.intro_seen=true
 game.phase="investigate"
 game.player.position=Vector3(0,0,0)
 game.enemies[0].position=Vector3(0,0,-1)
 game.enemies[1].position=Vector3(8,0,-24)
 game.locked=game.enemies[0]
 game.player.face(Vector3(0,0,-1))
 game.enemies[0].face(game.player.position)
 game.enemies[0].aware=true
 game.enemies[0].suspicion=1
 game.enemies[0].memory=7
 game.turn_cooldown=0
 game.impact_pause=0
 game.combat_stats={"enemy_attacks":0,"enemy_hits":0,"misses":0,"counters":0,"counter_hits":0}
 game.view.yaw=0
 game.player.play("guarda")
 game.enemies[0].play("guarda")
 game.player.animate(.2)
 game.enemies[0].animate(.2)

func run() -> void:
 var deadline=create_timer(55,true,false,true)
 deadline.timeout.connect(func(): push_error("TEST TIMEOUT"); quit(2))
 game=load("res://prototipo/main.tscn").instantiate()
 root.add_child(game)
 await frames(3)
 game.set_physics_process(false)
 check(game.player.rig.get_bone_count()==22,"modelo aprovado conserva rig de 22 ossos")
 check(game.player.rig.find_children("*","SkeletonIK3D",true,false).is_empty(),"combate sem solucionador que teletransporta mão")
 check(game.school.doors.size()==3,"portas físicas na sala de materiais e salas de aula")
 check(ProjectSettings.get_setting("display/window/size/viewport_width")>=960,"resolução de base aumentada")
 game.begin()
 check(game.phase=="intro" and game.player.state=="intro","começar apresenta Miguel antes da exploração")
 game.view.update(1)
 check(game.view.mode=="intro","abertura tem câmera dirigida")
 await ticks(490)
 check(game.phase=="investigate" and game.intro_seen,"abertura devolve o controle após apresentar horário e vozes")
 # Clipes exclusivos, com extremos do ciclo realmente coincidentes.
 for name in ["prototype/walk","prototype/run"]:
  var clip=game.player.anim.get_animation(name)
  var closed=true
  for track in clip.get_track_count():
   var count=clip.track_get_key_count(track)
   var a=clip.track_get_key_value(track,0)
   var b=clip.track_get_key_value(track,count-1)
   if a is Quaternion:
    closed=closed and absf(a.dot(b))>.99999
   elif a is Vector3:
    closed=closed and a.distance_to(b)<.0001
  check(closed and clip.loop_mode==Animation.LOOP_LINEAR,"ciclo fecha sem salto: "+name)
 game.player.velocity=Vector3(0,0,3.8)
 game.player.play("correr",1.2)
 game.player.play("correr",1.2)
 game.player.face(game.player.position+Vector3.BACK); game.player.animate(.1)
 var stride=float(game.player.motion.strides["Sprint"]["stride"])
 check(absf(float(game.player.motion.tree.get("parameters/Locomocao/Cadencia/scale"))-3.8/stride)<.01,"cadência usa velocidade e passada medida, sem multiplicar duas vezes")
 game.player.start_action("prototype/sit")
 game.player.animate(.25)
 check(maxf(game.player.bone_point("LeftFoot").y,game.player.bone_point("RightFoot").y)<.3,"pose sentada mantém pés abaixo do banco")
 var high=-100.0
 var low=100.0
 game.player.start_action("prototype/run")
 for i in 24:
  game.player.motion.seek(.7*float(i)/24)
  game.player.rig.force_update_all_bone_transforms()
  var y=game.player.bone_point("Head").y
  high=maxf(high,y)
  low=minf(low,y)
 check(high-low<.06,"corrida não faz o corpo saltar verticalmente a cada passada")
 check(game.player.anim.get_animation("prototype/hook").loop_mode==Animation.LOOP_NONE,"golpe completo não vira loop")
 # Porta realmente impede a passagem e sua folha gira junto com a colisão.
 var door=game.school.doors[0]
 check(not game.visible_between(Vector3(-4,1.2,8.5),Vector3(-2,1.2,8.5)),"porta fechada bloqueia visão/passagem")
 door.set_open(true,true)
 await frames(2)
 check(game.visible_between(Vector3(-4,1.2,8.5),Vector3(-2,1.2,8.5)),"abrir libera o vão de verdade")
 door.set_open(false,true)
 game.player.position=Vector3(-4.2,0,8.5)
 await frames(2)
 game.toggle_peek()
 game.view.update(1)
 check(game.peek_door==door and game.view.mode=="peek" and not game.player.model.visible,"fresta da porta usa primeira pessoa")
 game.toggle_peek()
 game.view.update(1)
 check(game.peek_door==null and game.player.model.visible,"sair da fresta restaura terceira pessoa")
 # O inimigo deve iniciar e acertar sem depender de o jogador atacá-lo.
 arena()
 await frames(2)
 await ticks(76)
 check(game.combat_stats["enemy_attacks"]>=1,"cultista inicia ataque por conta própria")
 check(game.combat_stats["enemy_hits"]==1 and game.player.health==62,"soco real acerta uma vez; jogador parado toma dano")
 check(game.enemies[0].opening>0,"inimigo tem recuperação aproveitável depois do golpe")
 # Esquiva curta seguida de um único contra-ataque; sem mão corrigida até o alvo.
 arena()
 await frames(2)
 await ticks(24)
 game.dodge()
 await ticks(36)
 print("DODGE_RESULT ",game.player.health," ",JSON.stringify(game.combat_stats)," opening=",game.enemies[0].opening)
 check(game.combat_stats["misses"]==1 and game.player.health==100,"esquiva tira hurtboxes do percurso do punho")
 check(game.player.state=="idle" and game.enemies[0].opening>0,"esquiva termina a tempo da janela de contra-ataque")
 game.attack()
 check(game.player.state=="attack" and game.player.strike_bone=="RightHand","contra-ataque usa o braço do gancho medido")
 var last: Vector3=game.player.fist_point()
 var largest=0.0
 for i in 160:
  game._physics_process(1.0/60)
  var now: Vector3=game.player.fist_point()
  largest=maxf(largest,last.distance_to(now))
  last=now
  await physics_frame
 print("COUNTER_RESULT ",JSON.stringify(game.combat_stats)," max_hand_step=",largest)
 check(game.combat_stats["counter_hits"]==1,"contra-ataque conecta pela trajetória do clipe")
 check(game.enemies[0].dead and game.enemies[0].health==0,"contra-ataque derruba e encerra cultista comum")
 check(game.enemies[0].bone_point("Head").y<.5,"corpo morto termina deitado")
 check(largest<.30,"punho não dá saltos artificiais para encontrar o alvo")
 # Patrulha e percepção, preservando a possibilidade de aproximar pelas costas.
 arena()
 game.enemies[0].aware=false
 game.enemies[0].suspicion=0
 game.enemies[0].face(Vector3(0,0,-2))
 check(not game.enemy_sees(game.enemies[0]),"não enxerga pelas costas a um metro")
 game.player.position=Vector3(-6,0,9)
 game.enemies[0].patrol_clock=3.2
 var old: Vector3=game.enemies[0].position
 await ticks(35)
 check(game.enemies[0].position.distance_to(old)>.15,"cultista patrulha em vez de esperar parado")
 # Cura temporizada e checkpoint com portas/inventário.
 game.player.state="idle"
 game.food=2
 game.player.health=30
 game.heal()
 game.hurt_player(5)
 check(game.food==2 and game.player.health==25 and game.player.state=="hurt","dano cancela cura sem consumir empanado")
 game.player.state="idle"
 game.heal()
 game.player.clock=2.41
 game._player_tick(1.0/60)
 check(game.food==1 and game.player.health==65,"empanado cura parte da vida após o tempo")
 door.set_open(true,true)
 game._snapshot(false)
 door.set_open(false,true)
 game.food=0
 game.restore_checkpoint()
 check(door.opened and game.food==1,"checkpoint restaura estado da porta e inventário")
 # Revelação e fuga em primeira pessoa, com câmera livre.
 game.player.position=Vector3(0,0,-27)
 game.start_chase()
 check(game.phase=="discovery" and game.pursuer!=null,"descoberta recebe cena de revelação")
 game.end_discovery()
 game.view.update(1)
 check(game.phase=="chase" and game.view.mode=="first_person" and not game.player.model.visible,"perseguição passa a primeira pessoa")
 var old_yaw: float=game.view.yaw
 game.view.look_mouse(Vector2(100,0))
 check(game.view.yaw!=old_yaw and game.locked==null,"mouse continua livre para olhar para trás")
 game.knife=true
 game._grab()
 check(not game.knife and not game.player.dead and game.pursuer.state=="stunned","faca fica no cultista e permite escapar")
 game._grab()
 check(game.player.dead,"captura sem faca continua letal")
 game.restore_checkpoint()
 check(not game.player.dead and game.phase=="investigate","morte retorna antes da revelação")
 game.player.position=Vector3(0,0,-27)
 game.start_chase()
 game.end_discovery()
 game.player.position=Vector3(.5,0,14.3)
 game._physics_process(1.0/60)
 check(game.phase=="escaped","chegar ao portão encerra o capítulo")
 print("PROTOTIPO_TEST: %d passed, %d failed"%[passed,failed])
 game.queue_free()
 await process_frame
 quit(1 if failed>0 else 0)
