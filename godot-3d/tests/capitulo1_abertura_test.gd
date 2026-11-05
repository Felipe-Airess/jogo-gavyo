extends SceneTree
## Abertura de dia (Miguel + Felipe, falas aprovadas) e primeiro cultista na
## cozinha (timing por coberturas, vigilância, morte direta, checkpoint).
var passed:=0
var failed:=0
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok: passed+=1; print("PASS ",message)
 else: failed+=1; print("FAIL ",message)
func tick(seconds: float) -> void:
 for i in int(seconds*60):
  game._physics_process(1.0/60.0)
  game._process(1.0/60.0)
func run() -> void:
 game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_process(false); game.set_physics_process(false); game.qa_mode=true
 for i in 3: await physics_frame
 var env: Environment=game.school.find_children("*","WorldEnvironment",true,false)[0].environment
 var fog_night=env.fog_density
 var mask=game.player.collision_mask
 # --- Abertura ---
 game.begin()
 var ab=game.abertura
 check(game.phase=="intro" and ab!=null and ab.active,"começar abre a cena de dia")
 check(is_instance_valid(ab.felipe) and ab.felipe.model_role=="felipe","Felipe usa o modelo definitivo existente")
 check(env.fog_density<fog_night and env.ambient_light_energy>.9,"luz de manhã durante a abertura")
 var falas=ab.FALAS.map(func(f): return f[3])
 check("Vou pra sala descansar." in falas and "Eu vou contigo." in falas and "Não, vai não, que tu é o porcão, gosta de ficar com o porcão não." in falas,"falas aprovadas por Felipe, exatas")
 tick(7.0)
 check(ab.falante=="Miguel" and game.player.position.y>0 and game.player.position.y<game.school.LEVEL,"diálogo acontece descendo a escada")
 tick(ab.DEITADO_FIM-7.0+.2)
 check(ab.noite and env.fog_density==fog_night,"corte brusco devolve a noite")
 tick(8.0)
 check(game.phase=="investigate" and game.abertura==null,"abertura termina sozinha e devolve o controle")
 check(game.player.position.distance_to(game.school.spawn)<.1,"Miguel acorda na salinha")
 check(game.player.collision_mask==mask,"colisão de Miguel restaurada")
 check(not is_instance_valid(ab.felipe) or ab.felipe.is_queued_for_deletion(),"Felipe da abertura sai de cena")
 # Pular no meio também restaura tudo.
 game.intro_seen=false; game.begin(); tick(3.0)
 var key=InputEventKey.new(); key.keycode=KEY_SPACE; key.pressed=true
 game._unhandled_input(key)
 check(game.phase=="investigate" and env.fog_density==fog_night and game.player.collision_mask==mask,"Espaço pula a abertura sem deixar luz de dia")
 # --- Cozinha ---
 var cz=game.cozinha
 check(cz.estado=="espera" and cz.coberturas.size()==4,"cozinha armada com 4 coberturas")
 check(cz.coberturas.all(func(c): return absf(c.x-cz.mesa.x)>absf(cz.porta.x-cz.mesa.x)),"coberturas se afastam da mesa do cultista")
 game.player.position=cz.porta+Vector3(0,0,-1.3); tick(.2)
 check(game.phase=="cozinha" and cz.estado=="cena","entrar na porta inicia o storyboard")
 tick(cz.Q4+.2)
 check(cz.estado=="jogo","depois de Q1–Q4 o jogador assume")
 check(game.vigilance_level()==cz.vigilancia,"barra de vigilância mostra a cozinha")
 # Errar o tempo enche a barra.
 while cz.janela_aberta(): tick(.05)
 var antes=cz.vigilancia; cz.apertar()
 check(cz.vigilancia>=antes+.4,"apertar fora da janela enche a vigilância")
 cz.apertar(); cz.apertar(); tick(.2)
 check(game.player.dead,"vigilância cheia na cozinha mata direto")
 tick(2.0)
 check(not game.player.dead and game.player.position.distance_to(cz.porta)<1.7,"volta ao checkpoint da porta da cozinha")
 # Acertar o tempo vence.
 var t:=0.0
 while cz.estado!="feito" and t<40:
  if cz.janela_aberta() and cz.ciclo>.1: cz.apertar()
  tick(.05); t+=.05
 check(cz.estado=="feito" and game.phase=="investigate","timing certo passa pelas paredes e devolve o controle")
 game.player.position=cz.porta+Vector3(0,0,-1.3); tick(.3)
 check(game.phase=="investigate","cozinha concluída não repete")
 print("CAPITULO1_ABERTURA: %d passed, %d failed"%[passed,failed])
 game.queue_free()
 for i in 3: await process_frame
 await create_timer(.1).timeout
 quit(1 if failed else 0)
