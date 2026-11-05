extends SceneTree
## Percepção gradual dos cultistas (capitulo1/percepcao.gd).
var passed:=0
var failed:=0
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok: passed+=1; print("PASS ",message)
 else: failed+=1; print("FAIL ",message)
## Segundos até a suspeita encher com o cultista parado olhando.
func tempo(e,luz: float,agachado: bool,velocidade: float) -> float:
 e.suspicion=0; e.set_meta("respiro",0.0)
 game.player.crouched=agachado
 game.player.velocity=Vector3(velocidade,0,0)
 var t:=0.0
 while t<30.0:
  game.percepcao.luz=luz
  if game.percepcao.tick(game,e,.05): return t
  t+=.05
 return t
func run() -> void:
 game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_process(false); game.set_physics_process(false); game.qa_mode=true
 for i in 3: await physics_frame
 game.begin(); game.end_intro()
 var chao=StaticBody3D.new(); var forma=CollisionShape3D.new(); var caixa=BoxShape3D.new(); caixa.size=Vector3(60,.1,60)
 forma.shape=caixa; chao.add_child(forma); chao.position=Vector3(300,-.05,300); game.add_child(chao)
 var e=game.enemies[0]
 e.position=Vector3(300,0,306); e.aware=false
 game.player.position=Vector3(300,0,300); game.player.velocity=Vector3.ZERO
 e.face(game.player.position,1.0)
 for i in 3: await physics_frame
 var p=game.percepcao
 var escuro=tempo(e,.12,false,0); var claro=tempo(e,1.0,false,0)
 var agachado=tempo(e,.12,true,0); var correndo=tempo(e,1.0,false,3.5)
 print("PERCEPCAO 6m escuro=%.1f claro=%.1f agachado_escuro=%.1f correndo_claro=%.1f"%[escuro,claro,agachado,correndo])
 check(claro>.5,"nem na luz a percepção é instantânea")
 check(escuro>claro*1.8,"escuro esconde: leva bem mais tempo que na luz")
 check(agachado>escuro*1.8,"agachado no escuro é o mais difícil de perceber")
 check(correndo<claro,"correndo na luz é percebido mais rápido")
 # De costas: não vê a 6 m, só sente colado.
 e.face(e.position+(e.position-game.player.position),1.0)
 game.player.crouched=false; game.player.velocity=Vector3.ZERO
 check(p.olhar(game,e)==0.0,"de costas não vê Miguel a 6 m")
 game.player.position=e.position+Vector3(0,0,-1.0)
 check(p.olhar(game,e)>0.0,"colado às costas, sente a presença")
 # Parede bloqueia.
 game.player.position=Vector3(300,0,300); e.face(game.player.position,1.0)
 var parede=StaticBody3D.new(); var f2=CollisionShape3D.new(); var b2=BoxShape3D.new(); b2.size=Vector3(4,3,.3)
 f2.shape=b2; parede.add_child(f2); parede.position=Vector3(300,1.5,303); game.add_child(parede)
 await physics_frame; await physics_frame
 check(p.olhar(game,e)==0.0,"parede inteira bloqueia a visão")
 parede.queue_free(); await physics_frame
 # Sem ver, a suspeita cai depois de um respiro.
 e.suspicion=.6; e.set_meta("respiro",p.RESPIRO)
 e.face(e.position+Vector3(0,0,5),1.0)
 for i in 10: p.tick(game,e,.1)
 var depois_respiro=e.suspicion
 for i in 30: p.tick(game,e,.1)
 check(depois_respiro>=.59 and e.suspicion<.6,"suspeita espera o respiro e depois cai")
 # Barulho: correr perto é ouvido mesmo de costas.
 game.player.position=e.position+Vector3(0,0,-3.0); game.player.velocity=Vector3(3.5,0,0)
 check(p.ouvir(game,e)>0.0,"correr a 3 m é ouvido")
 game.player.crouched=true
 check(p.ouvir(game,e)==0.0,"agachado não faz barulho")
 print("CAPITULO1_PERCEPCAO: %d passed, %d failed"%[passed,failed])
 game.queue_free()
 for i in 3: await process_frame
 await create_timer(.1).timeout
 quit(1 if failed else 0)
