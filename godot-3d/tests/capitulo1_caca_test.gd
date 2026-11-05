extends SceneTree
## Percepção real, física real e leitura das animações. Não escreve ossos.
const DT:=1.0/60
var game: Node3D
var passed:=0
var failed:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 if ok: passed+=1; print("PASS ",label)
 else: failed+=1; print("FAIL ",label)
func reset() -> void:
 game.escape.clear(); game.escape_blackout=0; game.escape_advantage_until=0
 game.player.dead=false; game.player.hidden=false; game.player.state="idle"
 game.hidden_spot=-1; game.seen_hiding=false; game.hide_witnesses.clear()
 game.player.position=Vector3(200,0,200); game.player.velocity=Vector3.ZERO
 game.phase="investigate"; game.sighting_seen=true; game.alert_spread=false
 game.disturbance_until=0; game.phone_light=false; game.simulation_ticks=1
 for i in game.enemies.size():
  var e=game.enemies[i]
  e.position=Vector3(240+i*2,0,200); e.home=e.position; e.aware=false; e.suspicion=0
  e.hunt.reset(); e.dead=false; e.down=false; e.state="idle"; e.clock=0; e.attack_target=null
  e.velocity=Vector3.ZERO; e.memory=0; e.evidence.clear()
func place(e,at: Vector3) -> void:
 e.position=at; e.home=at; e.face(game.player.position); e.play("guarda"); e.animate(0)
func wall(at: Vector3,size: Vector3) -> StaticBody3D:
 var body=StaticBody3D.new(); body.position=at; body.collision_layer=1
 var shape=CollisionShape3D.new(); var box=BoxShape3D.new(); box.size=size
 shape.shape=box; body.add_child(shape); game.add_child(body)
 return body
func tick() -> void:
 game.elapsed+=DT; game._enemy_ticks(DT)
 await physics_frame
func finish_escape() -> void:
 for code in game.escape.sequence.duplicate(): game.escape_direction(code)
func run() -> void:
 var timeout=create_timer(90,true,false,true)
 timeout.timeout.connect(func():print("CACA TIMEOUT");quit(2))
 game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_physics_process(false); game.set_process(false); game.qa_mode=true
 for i in 3: await physics_frame
 game.begin(); game.end_intro()
 wall(Vector3(205,-.05,200),Vector3(40,.1,40))
 reset(); var e=game.enemies[0]; place(e,Vector3(200,0,206))
 await physics_frame
 check(game.enemy_sees(e),"visão real detecta Miguel em área aberta")
 # Percepção gradual: um quadro de visão não basta; a suspeita enche com o tempo.
 game._enemy_ticks(.01)
 check(e.hunt.mode!="notice" and e.suspicion>0 and e.suspicion<.2,"um quadro de visão só levanta suspeita, sem alerta instantâneo")
 var perceber:=0.0
 while e.hunt.mode!="notice" and perceber<6.0:
  game._enemy_ticks(.05); perceber+=.05
 print("CACA_PERCEPCAO tempo_ate_perceber=%.2f s luz=%.2f"%[perceber,game.percepcao.luz])
 check(e.hunt.mode=="notice" and perceber>.3,"de frente e perto, percebe Miguel depois de alguns instantes")
 var at: Vector3=e.position
 check(e.velocity==Vector3.ZERO,"ser visto interrompe a caminhada e inicia aviso")
 game._enemy_ticks(.39)
 check(e.hunt.mode=="notice" and e.hunt.shout_count==0 and e.position==at,"cultista permanece parado durante 0,4 s")
 game._enemy_ticks(.02)
 check(e.hunt.mode=="chase" and e.hunt.shout_count==1 and is_instance_valid(e.hunt_voice),"após pausa, grita e começa perseguição")
 check(game.alert_spread,"grito espalha o alerta")
 check(absf(Vector2(e.velocity.x,e.velocity.z).length()-3.0)<.001,"perseguição usa 3,0 m/s")
 check(e.motion.active_clip=="novo/Sprint","perseguição toca corrida original")
 var before: Vector3=e.position
 for i in 20: await tick()
 var travel=Vector2(e.position.x-before.x,e.position.z-before.z).length()
 print("CACA_CORRIDA deslocamento=%.4f m em %.3f s velocidade=%.3f clipe=%s"%[travel,20*DT,travel/(20*DT),e.motion.active_clip])
 check(absf(travel/(20*DT)-3.0)<.08,"deslocamento físico confirma 3,0 m/s")
 check(e.hunt.shout_count==1,"visão contínua não repete grito a cada quadro")
 # Parede real corta a visão. A memória permanece no último ponto, sem seguir Miguel oculto.
 var divider=wall(Vector3(200,1.1,202),Vector3(20,2.2,.1))
 await physics_frame
 var remembered: Vector3=e.last_seen
 check(not game.enemy_sees(e),"parede bloqueia visão real")
 game.player.position=Vector3(230,0,200)
 await tick()
 check(e.hunt.mode=="last_seen" and e.last_seen==remembered,"perdeu visão: vai ao último local visto, sem rastrear posição oculta")
 # Põe apenas o corpo no destino para isolar o relógio de busca da distância até ele.
 e.position=remembered+Vector3(0,0,.2); e.velocity=Vector3.ZERO
 await tick()
 check(e.hunt.mode=="search" and e.hunt.search_left>59.9,"busca de 60 s começa ao chegar ao último ponto")
 var first_target: Vector3=e.hunt.destination
 var directions: Dictionary={}; var searched_points: Dictionary={}; var walked=false
 for i in 360:
  await tick()
  directions[str(e.facing.round())]=true; searched_points[str(e.hunt.destination)]=true
  walked=walked or e.velocity.length()>.1
 check(e.hunt.mode=="search" and e.hunt.search_left>53,"perder visão não encerra busca em poucos segundos")
 check(walked and searched_points.size()>1 and directions.size()>1,"caça anda entre pontos e olha em volta com o corpo")
 check(e.last_seen==remembered and first_target.distance_to(remembered)<3,"pontos de busca pertencem à região lembrada")
 e.hunt.tick(game,e,53.5)
 check(e.hunt.mode=="search" and e.hunt.search_left>0,"busca continua antes dos 60 s")
 e.hunt.tick(game,e,.6)
 check(e.hunt.mode=="return" and not e.aware,"após 60 s sem visão, volta ao posto")
 check(absf(Vector2(e.velocity.x,e.velocity.z).length()-.8)<.01 and e.hunt.destination==e.home,"retorno lento a 0,8 m/s para o posto original")
 e.position=e.home; e.hunt.tick(game,e,DT)
 check(e.hunt.mode=="patrol","chegada ao posto retoma patrulha")
 divider.queue_free(); await physics_frame
 # Armário real do capítulo, com porta móvel e colisão real.
 reset(); var index=game.school.hides.size()
 game.school.locker(Vector3(210,0,200),Vector3.BACK)
 var spot: Dictionary=game.school.hides[index]
 game.player.position=spot["entry"]
 place(e,spot["entry"]+Vector3.BACK*3)
 var other=game.enemies[1]; place(other,spot["entry"]+Vector3(0,0,6)); other.face(other.position+Vector3.BACK)
 await physics_frame
 game._enemy_ticks(DT)
 other.face(other.position+Vector3.BACK)
 game._enter_hide(index)
 check(e.hunt.witnessed_hide==index and other.hunt.witnessed_hide==-1,"somente quem viu entrar conhece o armário")
 check(game.player.hidden and not game.enemy_sees(e) and not game.enemy_sees(other),"esconderijo oculta Miguel mesmo de quem lembra onde entrou")
 var extracted=false
 for i in 360:
  await tick()
  if game.escape.active: extracted=true; break
 check(spot["opened"] and spot["hinge"].rotation.y<-.5,"testemunha abre a folha do armário")
 check(extracted and not game.player.hidden and game.action_target==e,"viu entrar: tira Miguel do armário e abre minigame")
 check(e.position.distance_to(game.player.position)>=.54,"extração mantém separação entre corpos")
 finish_escape()
 reset(); game.player.position=spot["entry"]
 place(e,spot["entry"]+Vector3.BACK*3); e.face(e.position+Vector3.BACK)
 e.aware=true; e.hunt.mode="last_seen"; e.last_seen=spot["entry"]+Vector3(2,0,1)
 await physics_frame
 game._enter_hide(index)
 check(e.hunt.witnessed_hide==-1,"não viu a entrada: não conhece o armário")
 var opened=false
 for i in 420:
  await tick(); opened=opened or bool(spot["opened"]) or game.escape.active
 check(game.player.hidden and not opened,"sem testemunha: ronda por perto sem abrir nem agarrar")
 # O perseguidor também não pode herdar a localização secreta de um armário.
 e.position=Vector3(240,0,200)
 game.pursuer=game.spawn_actor(spot["entry"]+Vector3.BACK*3,true,true)
 game.pursuer.last_seen=spot["entry"]; game.pursuit_memory=0; game.search_time=0; game.phase="chase"
 for i in 180:
  game._pursuer_tick(DT); await physics_frame
 check(game.pursuer.position.distance_to(spot["entry"])<1.2 and game.player.hidden and not game.escape.active and not spot["opened"],"perseguidor ronda perto, mas não abre armário cuja entrada não viu")
 game.pursuer.queue_free(); game.pursuer=null; await physics_frame
 # Mede a vantagem relativa com os dois corpos se deslocando pela física.
 for speed in [1.45,3.8]:
  reset(); place(e,Vector3(200,0,206)); e.aware=true; e.hunt.mode="chase"
  game.player.face(game.player.position+Vector3.FORWARD)
  var initial_distance=e.position.distance_to(game.player.position)
  for i in 60:
   game.player.velocity=Vector3.FORWARD*speed
   game.player._slide(DT); game.player.play("correr" if speed>2 else "andaFrente"); game.player.animate(DT)
   await tick()
  var gap=e.position.distance_to(game.player.position)-initial_distance
  print("CACA_VANTAGEM miguel=%.2f m/s variacao_distancia=%.3f m"%[speed,gap])
  check(gap>.65 if speed>2 else gap<-1.3,"Miguel correndo ganha distância" if speed>2 else "Miguel andando perde distância")
 # Cerco com três cultistas visíveis, destinos distintos e cápsulas preservadas.
 reset(); var hunters=game.enemies.slice(0,3)
 for i in hunters.size():
  var actor=hunters[i]; place(actor,Vector3(198+float(i)*1.2,0,207))
  actor.aware=true; actor.hunt.mode="chase"; actor.last_seen=game.player.position
 var distinct=true; var minimum=INF; var positions: Dictionary={}
 for i in 60:
  await tick()
  for a in hunters:
   positions[str(a.hunt.destination)]=true
   for b in hunters:
    if a==b: continue
    minimum=minf(minimum,a.position.distance_to(b.position))
    distinct=distinct and a.hunt.destination.distance_to(b.hunt.destination)>.1
 check(distinct and positions.size()>=3,"vários caçadores escolhem lados distintos de Miguel")
 check(minimum>=.535,"cerco mantém cápsulas separadas, sem empilhar")
 # Em parede, o desvio do cerco não pode mandar o caçador para dentro do cenário.
 var blocked_slot: Vector3=hunters[0].hunt.surround(game,hunters[0])
 var obstruction=wall((blocked_slot+game.player.position)*.5+Vector3.UP,Vector3(.25,2,.25))
 await physics_frame
 check(hunters[0].hunt.surround(game,hunters[0])==hunters[0].last_seen,"cerco abandona desvio bloqueado por parede e mantém aproximação")
 obstruction.queue_free(); await physics_frame
 print("CACA_CERCO menor_distancia=%.4f m destinos=%d"%[minimum,positions.size()])
 print("CAPITULO1_CACA: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
