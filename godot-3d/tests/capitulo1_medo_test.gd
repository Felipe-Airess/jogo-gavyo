extends SceneTree
## Medo e atmosfera: coração, lentidão após susto, caixa da ave, ronda e pensamentos.
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
 var m=game.medo
 # Caixa de materiais na salinha.
 check(m.caixa!=null and game.school.ambiente_de(m.caixa.position)=="Materiais de esportes","caixa de materiais está na salinha")
 game.player.position=m.caixa.position+Vector3(0,-.25,1.0)
 var d: Vector3=m.caixa.position+Vector3.UP*.3-(game.player.position+Vector3.UP*.9)
 game.view.yaw=atan2(-d.x,-d.z); game.view.pitch=asin(d.normalized().y)
 check(game.context_text()=="[Espaço] Abrir caixa de materiais","olhar a caixa mostra o convite")
 game.interact()
 check(m.caixa_aberta and is_instance_valid(m.ave) and m.susto_lento>0,"abrir a caixa solta a ave e assusta")
 check(m.multiplicador_velocidade()<1.0 and game._multiplicador_velocidade()<1.0,"depois do susto, Miguel fica lento")
 for i in 120: m.tick(1.0/60.0)
 check(m.multiplicador_velocidade()==1.0,"a lentidão passa em pouco mais de 1 s")
 check(not m.perto_da_caixa(),"a caixa não assusta de novo")
 # Coração acelera com a tensão.
 m.susto_lento=1.0; m.tick(.1)
 var rapido: float=m.coracao.pitch_scale
 check(m.coracao.playing and rapido>1.5,"coração bate rápido sob tensão")
 # Parado por muito tempo: um cultista vem rondar.
 m.susto_lento=0
 game.player.position=Vector3(0,0,0); game.player.velocity=Vector3.ZERO
 for e in game.enemies: e.last_seen=Vector3(999,0,999); e.memory=0; e.aware=false
 for i in int(m.PARADO_LIMITE*10)+5: m.tick(.1)
 var veio: bool=game.enemies.any(func(e): return e.last_seen.distance_to(game.player.position)<3.0 and e.memory>0)
 check(veio,"parado por 45 s, um cultista vem rondar")
 # Perdido: pensamento do objetivo atual.
 var falou:=""
 m.objetivo_atual=m.objetivo(); m.sem_avancar=0
 for i in int(m.PERDIDO_LIMITE*10)+5: m.tick(.1); game.elapsed+=.1
 falou=game.hud.toast.text if "toast" in game.hud else ""
 check(m.ultimo_pensamento>0,"sem avançar por 2,5 min, Miguel pensa em voz alta")
 check(game.objectives.text("pensamento_"+m.objetivo()).begins_with("[PROVISÓRIO]"),"pensamento provisório até Felipe escrever")
 print("CAPITULO1_MEDO: %d passed, %d failed"%[passed,failed])
 game.queue_free()
 for i in 3: await process_frame
 await create_timer(.1).timeout
 quit(1 if failed else 0)
