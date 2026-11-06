extends SceneTree
## Mensagens dos amigos no celular e HUD mínimo.
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
 var o=game.objectives
 check(o.mensagens.is_empty(),"sem a bolsa, nenhuma mensagem")
 o.receber("bolsa")
 check(o.mensagens.size()==3,"ao pegar a bolsa chegam as não lidas da tarde")
 o.receber("bolsa")
 check(o.mensagens.size()==3,"mensagens não se repetem")
 o.receber("ritual"); o.receber("video")
 check(o.mensagens.size()==5,"mais mensagens no ritual e no vídeo")
 check(o.mensagens.all(func(id): return o.text(id).begins_with("[PROVISÓRIO]")),"textos provisórios até Felipe escrever")
 var estado=o.save_state(); o.mensagens.clear(); o.restore_state(estado)
 check(o.mensagens.size()==5,"checkpoint guarda as mensagens")
 game.bag_found=true; o.open_phone()
 var lista:=""
 for c in o.column.get_children(): if c is Label: lista+=c.text+"\n"
 check(o.text("mensagens") in lista and o.title("msg_bola_1") in lista,"celular lista as mensagens")
 o.close_screen()
 # HUD mínimo: objetivo some depois de alguns segundos e volta com [Tab].
 game.hud.objetivo_ate=0; game.hud.update(.1)
 check(not game.hud.objective.visible,"objetivo escondido fora de mudança")
 game.hud.mostrar_objetivo(); game.hud.update(.1)
 check(game.hud.objective.visible,"[Tab] mostra o objetivo")
 game.player.position=Vector3(400,0,400); game.hud.update(.1)
 check(not game.hud.luz_label.visible,"sem cultista perto, indicador de luz some")
 print("CAPITULO1_CELULAR: %d passed, %d failed"%[passed,failed])
 game.queue_free()
 for i in 3: await process_frame
 await create_timer(.1).timeout
 quit(1 if failed else 0)
