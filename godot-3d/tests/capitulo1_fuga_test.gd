extends SceneTree
## Fuga final roteirizada.
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
 for e in game.enemies: e.position=Vector3(250,0,250)
 var s=game.school; var f=game.fuga
 game.player.position=game.NIVEL.ponto(s,"gravar")
 game.video_recorded=true; game.alert_spread=false; game.start_chase()
 check(is_instance_valid(game.pursuer) and f.ativa,"vídeo gravado sempre inicia a fuga")
 game.end_discovery()
 var ate_portao: float=game.player.position.distance_to(s.gate_at)
 check(game.pursuer.position.distance_to(s.gate_at)>ate_portao,"perseguidor surge atrás, não no caminho do portão")
 var luzes_antes: int=s.lampadas.filter(func(x): return x["luz"].visible).size()
 # Velocidade: correndo, segura atrás; parado, vem com tudo.
 var p=game.player; var q=game.pursuer
 q.position=p.position-Vector3(4.5,0,0); p.velocity=Vector3(3.8,0,0); f.lento_por=0
 var correndo: float=f.velocidade(game,1.0/60.0)
 check(correndo<=3.8+.01,"correndo a 3,8 m/s, ele não ultrapassa (%.2f m/s)"%correndo)
 q.position=p.position-Vector3(9,0,0)
 check(f.velocidade(game,1.0/60.0)>3.8,"se Miguel abre distância, ele acelera")
 p.velocity=Vector3.ZERO; q.position=p.position-Vector3(4.5,0,0)
 var parado:=0.0
 for i in 120: parado=f.velocidade(game,1.0/60.0)
 check(is_equal_approx(parado,f.VEL_MAX),"parado por 2 s, ele vem com tudo")
 # Eventos pela distância até o portão.
 var de: Vector3=p.position
 for u in [.3,.55,.8,.97]:
  p.position=de.lerp(s.gate_at,u); f._eventos(game)
 check(f.feitos.has("porta") and f.feitos.has("luzes") and f.feitos.has("carrinho") and f.feitos.has("grito"),"porta bate, luzes estouram, carrinho cai e ele grita perto do portão")
 check(s.lampadas.filter(func(x): return x["luz"].visible).size()<=luzes_antes,"luzes apagam no estouro")
 game.restore_checkpoint()
 check(not f.ativa,"voltar ao checkpoint encerra a fuga")
 print("CAPITULO1_FUGA: %d passed, %d failed"%[passed,failed])
 game.queue_free()
 for i in 3: await process_frame
 await create_timer(.1).timeout
 quit(1 if failed else 0)
