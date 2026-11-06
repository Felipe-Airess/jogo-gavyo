extends SceneTree
## Laboratório — "Trancado por dentro".
var passed:=0
var failed:=0
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok: passed+=1; print("PASS ",message)
 else: failed+=1; print("FAIL ",message)
func tick(seconds: float) -> void:
 for i in int(seconds*60):
  game._physics_process(1.0/60.0); game._process(1.0/60.0)
func tecla(code: Key,on: bool) -> void:
 var k=InputEventKey.new(); k.keycode=code; k.physical_keycode=code; k.pressed=on; Input.parse_input_event(k); Input.flush_buffered_events()
func entrar_e_pegar() -> void:
 var lab=game.laboratorio
 game.player.position=game.objectives.position_of("pista_2")+Vector3(0,-.035,.8)
 if not "pista_2" in game.objectives.collected: game.objectives.collected.append("pista_2")
 game.objectives.props["pista_2"].visible=false
 tick(.2)
func run() -> void:
 game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_process(false); game.set_physics_process(false); game.qa_mode=true
 for i in 3: await physics_frame
 game.begin(); game.end_intro()
 for e in game.enemies: e.position=Vector3(250,0,250)
 var lab=game.laboratorio
 check(game.school.ambiente_de(game.objectives.position_of("pista_2"))==lab.SALA,"pista da ave 2 no Laboratório de matemática")
 entrar_e_pegar()
 check(game.phase=="laboratorio" and lab.estado=="entra","pegar a pista dispara a entrada do cultista")
 tick(lab.ENTRA+.1)
 check(lab.porta.locked and not lab.porta.opened,"cultista tranca a porta por dentro")
 check(lab.estado=="esconder","Miguel precisa se esconder")
 # Não se esconder a tempo: morte direta.
 tick(lab.PRAZO_ESCONDER+.2)
 check(game.player.dead,"sem se esconder a tempo, morre")
 tick(2.0)
 check(not game.player.dead and not lab.porta.locked,"volta ao checkpoint com a porta destrancada")
 # Esconder e se mexer: vigilância enche.
 tick(.3)
 if lab.estado=="espera": entrar_e_pegar()
 tick(lab.ENTRA+.1); lab.apertar()
 check(lab.estado=="escondido" and game.player.hidden and game.player.crouched,"[Espaço] esconde agachado atrás da bancada")
 tecla(KEY_W,true); tick(1.0)
 var com_movimento: float=lab.vigilancia
 tecla(KEY_W,false)
 check(com_movimento>.3,"mexer escondido enche a vigilância")
 # Parado até o fim: ele termina os frascos e sai.
 lab.vigilancia=0.0
 tick(lab.MEXER*3+lab.ENTRA+8.0)
 check(lab.estado=="feito" and game.phase=="investigate","parado, ele termina e sai")
 check(lab.porta.opened and not lab.porta.locked and not game.player.hidden,"porta fica aberta e Miguel sai do esconderijo")
 check(not game.player.dead,"parado o tempo todo, Miguel sobrevive")
 print("CAPITULO1_LABORATORIO: %d passed, %d failed"%[passed,failed])
 game.queue_free()
 for i in 3: await process_frame
 await create_timer(.1).timeout
 quit(1 if failed else 0)
