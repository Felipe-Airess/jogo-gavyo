extends SceneTree
## Ventilações: atalho seguro entre salas e susto único na grade.
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
func diante(g: Dictionary) -> void:
 game.player.position=Vector3(g["pos"].x,g["pos"].y-.35,g["pos"].z)+g["normal"]*.9
 var d: Vector3=g["pos"]-(game.player.position+Vector3.UP*.9)
 game.view.yaw=atan2(-d.x,-d.z); game.view.pitch=asin(d.normalized().y)
 game.player.face(g["pos"],1.0)
func run() -> void:
 game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_process(false); game.set_physics_process(false); game.qa_mode=true
 for i in 3: await physics_frame
 game.begin(); game.end_intro()
 var v=game.ventilacao
 check(v.grades.size()==4,"duas ventilações, com grade dos dois lados")
 var a: Dictionary=v.grades[0]; var b: Dictionary=a["par"]
 check(game.school.ambiente_de(Vector3(a["pos"].x,0,a["pos"].z)+a["normal"]*.6)==a["nome"],"grade A dentro da sala "+a["nome"])
 diante(a)
 check(v.texto().begins_with("[Espaço] Entrar na ventilação"),"olhar a grade mostra o convite")
 game.interact()
 check(game.phase=="duto","Espaço entra na ventilação")
 tick(v.ENTRAR+v.ESCURECER+.3)
 check(game.player.hidden and v.preto(),"dentro do duto: escondido e tela escura")
 var e=game.enemies[0]; e.position=game.player.position+Vector3(0,0,2); e.face(game.player.position,1.0)
 check(game.percepcao.olhar(game,e)==0.0,"ninguém vê Miguel dentro do duto")
 tick(v.duracao+.2)
 check(v.estado=="susto" and is_instance_valid(v.rosto) and v.rosto.visible,"primeira saída da ventilação marcada: rosto na grade")
 tick(v.SUSTO+v.ESCURECER+.6)
 check(game.phase=="investigate" and not game.player.hidden,"depois do susto, Miguel sai e o controle volta")
 check(game.school.ambiente_de(game.player.position)==b["nome"],"saiu na outra sala: "+b["nome"])
 check(not v.rosto.visible and not game.player.dead,"susto sem perigo: rosto some, Miguel vivo")
 # Volta pelo mesmo duto e entra de novo: o susto não se repete.
 diante(b); game.interact(); tick(v.ENTRAR+v.ESCURECER+v.duracao+v.ESCURECER+1.0)
 diante(a); game.interact(); tick(v.ENTRAR+v.ESCURECER+v.duracao+.3)
 check(v.estado!="susto","o susto acontece uma vez só")
 tick(2.0)
 check(game.phase=="investigate","segunda travessia termina normalmente")
 print("CAPITULO1_VENTILACAO: %d passed, %d failed"%[passed,failed])
 game.queue_free()
 for i in 3: await process_frame
 await create_timer(.1).timeout
 quit(1 if failed else 0)
