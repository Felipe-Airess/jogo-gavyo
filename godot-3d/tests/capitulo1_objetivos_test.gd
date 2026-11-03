extends SceneTree
var passed:=0
var failed:=0
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok: passed+=1; print("PASS ",message)
 else: failed+=1; print("FAIL ",message)
func look_at(at: Vector3) -> void:
 var delta=at-(game.player.position+Vector3.UP*.9)
 game.view.yaw=atan2(-delta.x,-delta.z); game.view.pitch=asin(delta.normalized().y)
func reach(id: String) -> void:
 game.player.position=game.objectives.position_of(id)+Vector3(0,-.035,.7)
 look_at(game.objectives.position_of(id))
func press(code: Key) -> void:
 var key=InputEventKey.new(); key.keycode=code; key.pressed=true
 game._unhandled_input(key)
func run() -> void:
 game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_process(false); game.set_physics_process(false); game.qa_mode=true
 for i in 3: await physics_frame
 game.begin(); game.end_intro()
 var objectives=game.objectives; var door=objectives.bag_door
 check(objectives.texts.size()>=25 and objectives.texts.has("fome"),"textos centralizados incluem pensamento provisório da fome")
 var provisional=true
 for entry in objectives.texts.values(): provisional=provisional and entry["texto"].begins_with("[PROVISÓRIO]") and entry["titulo"].begins_with("[PROVISÓRIO]")
 check(provisional,"todo texto e título novo está marcado PROVISÓRIO")
 check(door.locked and game.school.doors.filter(func(d):return d.locked).size()==1,"só o acesso da bolsa tem tranca")
 door.set_open(true,true)
 check(not door.opened and not objectives.unlock(door),"sem chave, nem abertura direta nem interação destrancam")
 game.player.position=game.school.bag_at-Vector3.UP*1.01+Vector3(0,0,-.95); game.interact()
 check(not game.bag_found and game.interaction.is_empty(),"não pega a bolsa sem obter a chave")
 check(not objectives.collect("chave"),"não coleta chave à distância")
 reach("chave"); game.interact()
 check(objectives.has_key() and not objectives.props["chave"].visible,"interação guarda chave no inventário e remove pickup")
 check("chave" in game.checkpoint["objectives"]["collected"] and game.player.position.distance_to(Vector3(game.checkpoint["position"][0],game.checkpoint["position"][1],game.checkpoint["position"][2]))<.01,"pegar chave salva checkpoint automático na posição real")
 check(objectives.unlock(door) and not door.locked,"chave destranca apenas a porta da bolsa")
 door.set_open(true)
 await create_timer(.8).timeout
 check(door.opened and not door.moving and absf(door.pivot.rotation.y)>1,"porta abre por animação articulada e emite som existente")
 check(int(game.sound.played.get("porta_abrir",0))>0,"porta destrancada usa áudio importado")
 # Coletáveis: chamadas pela interação real, com alcance e leitura modal.
 for id in ["nota_1","nota_2","nota_3","nota_4","pista_1","pista_2"]:
  reach(id); game.interact()
  var before=game.elapsed; var enemy_at: Vector3=game.enemies[0].position
  game._physics_process(.5)
  check(objectives.reading and game.paused and game.elapsed==before and game.enemies[0].position==enemy_at,"ler %s abre tela e pausa ameaça"%id)
  press(KEY_ESCAPE)
  check(not objectives.modal and not game.paused,"fechar %s devolve ameaça e controle"%id)
 check(objectives.count("nota")==4 and objectives.count("pista")==2,"quatro notas e duas pistas coletadas e contadas")
 check(not objectives.collect("nota_1") and objectives.count("nota")==4,"reler ou tentar pegar nota repetida não duplica registro")
 game.bag_found=true; press(KEY_N)
 check(objectives.modal and not game.paused and not objectives.reading,"celular abre listas sem pausar a ameaça")
 check(objectives.ui_buttons.size()==7,"celular lista seis registros e botão de fechar")
 objectives.ui_buttons[0].pressed.emit()
 check(objectives.reading and game.paused,"reler registro pelo celular pausa apenas a leitura")
 press(KEY_ESCAPE)
 # Botões de toque percorrem a mesma entrada de teclado e os mesmos registros.
 root.content_scale_size=Vector2i(960,540); root.size=Vector2i(960,540)
 objectives.layout()
 var touch=load("res://capitulo1/toque.gd").new(); game.add_child(touch); game.touch=touch; touch.setup(game)
 var phone_buttons=touch.buttons.filter(func(b):return b["id"]=="celular")
 check(phone_buttons.size()==1,"toque oferece botão do celular")
 touch._press_button(phone_buttons[0],true); Input.flush_buffered_events(); await process_frame
 check(objectives.modal,"botão de celular do toque abre a lista")
 await process_frame
 for i in 3: await process_frame
 print("LEITURA_TOQUE altura_lista=",objectives.column.size.y," altura_janela=",objectives.scroll.size.y," max=",objectives.scroll.get_v_scroll_bar().max_value)
 var drag=InputEventScreenDrag.new(); drag.index=8; drag.relative=Vector2(0,-140)
 touch._drag(drag)
 check(objectives.scroll.scroll_vertical>0,"toque arrasta a lista de registros sem mover Miguel")
 check(objectives.ui_buttons[-1].get_global_rect().end.y<=get_root().get_visible_rect().size.y,"fechar permanece visível mesmo com lista longa")
 objectives.scroll.scroll_vertical=0
 await process_frame
 var tap=InputEventScreenTouch.new(); tap.pressed=true; tap.index=8
 tap.position=objectives.ui_buttons[0].get_global_rect().get_center(); touch._touch(tap)
 check(objectives.reading and game.paused,"toque abre leitura de um registro pela lista")
 await process_frame
 tap.position=objectives.ui_buttons[-1].get_global_rect().get_center(); touch._touch(tap)
 check(not objectives.modal and not game.paused,"botão de fechar do toque restaura o jogo")
 reach("finalizador"); game.interact()
 check(game.finisher_item_available and not objectives.props["finalizador"].visible,"item opcional escondido é guardado")
 var enemy=game.enemies[0]
 check(objectives.finish(enemy) and enemy.dead and not game.finisher_item_available and objectives.spent,"item finaliza cultista comum e é consumido")
 check(not objectives.finish(game.enemies[1]) and not game.enemies[1].dead,"mesmo item não pode finalizar um segundo comum")
 var big=game.spawn_actor(Vector3(200,0,200),true,true)
 game.finisher_item_available=true
 check(not objectives.finish(big) and not big.dead and game.finisher_item_available,"item nunca finaliza perseguidor nem é consumido nele")
 game.finisher_item_available=false
 game._snapshot(false); game.restore_checkpoint()
 check(objectives.spent and not game.finisher_item_available and game.enemies[0].dead and objectives.count("nota")==4 and objectives.count("pista")==2,"checkpoint restaura registros e finalização sem duplicar uso")
 for e in game.enemies: e.suspicion=0
 for e in game.school.ritual_figures: e.suspicion=0
 var watcher=game.enemies[1]; watcher.position=game.player.position+Vector3(0,0,3); watcher.suspicion=.65
 game.hud.update(.016)
 check(game.hud.suspicion_bar.visible and absf(game.hud.suspicion_bar.value-65)<.01,"barra superior mostra vigilância de cultista próximo")
 watcher.position=game.player.position+Vector3(0,0,30); game.hud.update(.016)
 check(not game.hud.suspicion_bar.visible,"barra de vigilância some longe dos cultistas")
 # Todos os pontos estão em piso, dentro de salas existentes; não dependem de decoração.
 var floors=true
 for spec in objectives.PLACES.values():
  var grid=game.school.andares[spec[1]]
  floors=floors and not grid.e_vazio(int(spec[0].x),int(spec[0].y)) and grid.ch(int(spec[0].x),int(spec[0].y)) not in "#DWG%"
 check(floors,"oito pickups em piso livre de salas existentes")
 print("CAPITULO1_OBJETIVOS: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
