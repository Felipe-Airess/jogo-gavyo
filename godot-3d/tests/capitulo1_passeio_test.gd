extends SceneTree
var passed:=0
var failed:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 if ok: passed+=1; print("PASS ",label)
 else: failed+=1; print("FAIL ",label)
func f9(game) -> void:
 var event=InputEventKey.new(); event.keycode=KEY_F9; event.pressed=true
 game._unhandled_input(event)
func run() -> void:
 var game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_physics_process(false); game.set_process(false)
 for i in 3: await physics_frame
 f9(game)
 if not OS.is_debug_build():
  check(not game.walk_mode,"F9 não ativa passeio na versão release")
 else:
  check(game.walk_mode and game.started and game.phase=="investigate","F9 abre passeio direto do menu em debug")
  var quiet=true
  for actor in game.find_children("*","CharacterBody3D",true,false):
   if actor==game.player or not "hurt_areas" in actor: continue
   quiet=quiet and not actor.is_visible_in_tree() and actor.collision_layer==0
   for area in actor.hurt_areas: quiet=quiet and area.collision_layer==0
  check(quiet,"passeio oculta inimigos/ritual e remove colisões e áreas de acerto")
  var body=StaticBody3D.new(); var shape=CollisionShape3D.new(); var box=BoxShape3D.new()
  box.size=Vector3(20,.1,20); shape.shape=box; body.position=Vector3(200,-.05,200); body.add_child(shape); game.add_child(body)
  game.player.position=Vector3(200,.02,200)
  var start=game.player.position
  var key=InputEventKey.new(); key.physical_keycode=KEY_W; key.keycode=KEY_W; key.pressed=true
  Input.parse_input_event(key); Input.flush_buffered_events()
  for i in 40: game._physics_process(1.0/60); await physics_frame
  key.pressed=false; Input.parse_input_event(key); Input.flush_buffered_events()
  check(game.player.position.distance_to(start)>.5,"Miguel anda com input e física normais no passeio")
  var e=game.enemies[0]; e.position=game.player.position+Vector3.BACK*.55
  check(not game._grab_player(e) and not game.enemy_sees(e),"inimigo próximo não detecta nem agarra no passeio")
  game.alert_spread=true; game.video_recorded=true; game.start_chase(); game._story_tick(0)
  check(game.pursuer==null,"passeio não gera perseguidor")
  game._process(.1); check(game.pressure.value==0 and not game.tension.playing,"pressão fica desligada no passeio")
  game.player.position=game.school.bag_at-Vector3.UP*1.01+Vector3(0,0,-.95)
  var bag=game.bag_found; game.interact()
  check(game.bag_found==bag and game.interaction.is_empty(),"passeio não coleta bolsa nem inicia roteiro")
  f9(game)
  check(not game.walk_mode and game.enemies.all(func(actor):return actor.visible and actor.collision_layer==2),"F9 sai e restaura os inimigos do checkpoint")
  check(game.player.position.distance_to(game.school.spawn)<.1,"saída retoma o checkpoint sem salvar o passeio")
 print("CAPITULO1_PASSEIO: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
