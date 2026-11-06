extends SceneTree
## Biblioteca — "O leitor": estantes, patrulha com leitura e distração.
var passed:=0
var failed:=0
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok: passed+=1; print("PASS ",message)
 else: failed+=1; print("FAIL ",message)
func run() -> void:
 game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_process(false); game.set_physics_process(false); game.qa_mode=true
 for i in 3: await physics_frame
 game.begin(); game.end_intro()
 var b=game.biblioteca; var s=game.school; var l=b.leitor
 check(b.estantes.size()>=4,"biblioteca tem fileiras de estantes")
 check(l in game.enemies and game.enemies.size()==8,"leitor é o 8º cultista comum")
 check(s.ambiente_de(l.position)=="Biblioteca" and b.rota.all(func(p): return s.ambiente_de(p)=="Biblioteca"),"rota do leitor fica dentro da biblioteca")
 check(s.ambiente_de(game.objectives.position_of("pista_1"))=="Biblioteca","pista da ave no fundo da biblioteca")
 var livros: int=game.world_objects.filter(func(o): return s.ambiente_de(o["node"].position)=="Biblioteca").size()
 check(livros>=2,"livros para arremessar na entrada")
 # Miguel longe: o leitor patrulha e para para ler.
 game.player.position=Vector3(200,0,200); game.player.velocity=Vector3.ZERO
 var visitados:={}; var parou:=false
 for i in 60*40:
  game._enemy_ticks(1.0/60.0)
  for c in game.enemies: if c!=l: c.position=Vector3(220,0,220)
  visitados[int(l.get_meta("rota_i",0))]=true
  if float(l.get_meta("rota_parado",0.0))>0: parou=true
 check(visitados.size()>=3,"leitor percorre vários pontos da rota")
 check(parou,"leitor para em pontos para ler")
 # Distração: barulho do outro lado atrai o leitor (sem ver Miguel).
 l.position=b.rota[0]; l.aware=false; l.suspicion=0; l.memory=0
 var alvo: Vector3=b.rota[3]
 game.disturbance=alvo; game.disturbance_until=game.elapsed+6
 var antes: float=l.position.distance_to(alvo)
 for i in 60*6: game._enemy_ticks(1.0/60.0); game.elapsed+=1.0/60.0
 check(l.position.distance_to(alvo)<antes-3.0 and not l.aware,"livro jogado atrai o leitor para o barulho sem alertar")
 print("CAPITULO1_BIBLIOTECA: %d passed, %d failed"%[passed,failed])
 game.queue_free()
 for i in 3: await process_frame
 await create_timer(.1).timeout
 quit(1 if failed else 0)
