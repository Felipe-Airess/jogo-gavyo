extends SceneTree
## Testa input e fluxo real. Nenhum teste escreve poses de osso.
const DT:=1.0/60
var passed:=0
var failed:=0
var game: Node3D
var enemy: CharacterBody3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 if ok: passed+=1; print("PASS ",label)
 else: failed+=1; print("FAIL ",label)
func key(code: int,echo:=false,pressed:=true) -> void:
 var event=InputEventKey.new(); event.keycode=code; event.physical_keycode=code
 event.pressed=pressed; event.echo=echo; game._unhandled_input(event)
func fixture(actor: CharacterBody3D) -> void:
 game.escape.clear(); game.escape_blackout=0; game.escape_advantage_until=0
 game.player.dead=false; game.player.hidden=false; game.player.state="idle"
 game.player.position=Vector3(200,0,200); game.player.velocity=Vector3.ZERO
 actor.position=Vector3(200,0,200.63 if actor.pursuer else 200.55)
 actor.state="idle"; actor.clock=0; actor.down=false; actor.dead=false
 actor.velocity=Vector3.ZERO; actor.attack_target=null; actor.opening=0
 game.sighting_seen=true
 game.action_target=null; game.phase="chase" if actor.pursuer else "investigate"
 game.hud.show_escape_blackout(false)
func finish() -> void:
 for code in game.escape.sequence.duplicate(): key(code)
func touch_arrow(code: int,index:=0) -> void:
 for b in game.touch.escape_buttons:
  if b["direction"]==code:
   var event=InputEventScreenTouch.new(); event.index=index; event.position=b["at"]; event.pressed=true
   game.touch._touch(event); event.pressed=false; game.touch._touch(event)
   return
func run() -> void:
 var deadline=create_timer(70,true,false,true)
 deadline.timeout.connect(func():print("ESCAPE TIMEOUT");quit(2))
 game=load("res://capitulo1/main.tscn").instantiate()
 root.add_child(game); game.set_physics_process(false); game.set_process(false); game.qa_mode=true
 for i in 3: await physics_frame
 game.begin(); game.end_intro(); game.sighting_seen=true
 var floor=StaticBody3D.new(); floor.collision_layer=1; floor.position=Vector3(200,-.05,200)
 var shape=CollisionShape3D.new(); var box=BoxShape3D.new(); box.size=Vector3(20,.1,20)
 shape.shape=box; floor.add_child(shape); game.add_child(floor)
 enemy=game.enemies[0]
 for i in game.enemies.size(): game.enemies[i].position=Vector3(230+i*2,0,200)
 await physics_frame
 check(game.has_method("escape_direction"),"agarrão oferece sequência direcional")
 if not game.has_method("escape_direction"): quit(1); return
 fixture(enemy); game._enemy_ticks(DT)
 check(game.escape.active and game.player.state=="grabbed" and enemy.state=="grab_hold","encostar no cultista comum abre o minigame")
 check(game.escape.sequence.size()==3 and is_equal_approx(game.escape.limit,3.0),"primeiro agarrão: 3 setas, 3,0 s")
 check(game.escape.sequence.all(func(code):return code in game.ESCAPE.DIRECTIONS),"sequência contém somente quatro direções válidas")
 var separation=enemy.position.distance_to(game.player.position)
 check(separation>=.54 and separation<=.68,"corpos separados em aproximadamente 0,6 m")
 check(enemy.facing.dot((game.player.position-enemy.position).normalized())>.99 and game.player.facing.dot((enemy.position-game.player.position).normalized())>.99,"os dois ficam de frente")
 var player_at: Vector3=game.player.position; var enemy_at: Vector3=enemy.position
 game._physics_process(.15)
 check(game.player.position==player_at and enemy.position==enemy_at,"agarrão mantém corpos sem atravessar")
 var cursor=game.escape.cursor
 key(game.escape.sequence[0],true); key(game.escape.sequence[0],false,false); key(KEY_Q)
 check(game.escape.cursor==cursor and game.escape.active,"segurar tecla, soltá-la ou apertar Q não resolve a sequência")
 key(KEY_ESCAPE); var remaining=game.escape.remaining; game._physics_process(.25)
 check(game.paused and game.escape.remaining==remaining,"pausa suspende prazo do minigame")
 key(KEY_ESCAPE)
 # Mistura WASD e setas; envia também uma tecla repetida fisicamente após soltura.
 for i in game.escape.sequence.size():
  var code=game.escape.sequence[i]
  var wasd={KEY_UP:KEY_W,KEY_RIGHT:KEY_D,KEY_DOWN:KEY_S,KEY_LEFT:KEY_A}
  key(wasd[code] if i%2==0 else code)
 check(not game.escape.active and game.player.state=="idle" and enemy.state=="escape_stunned","sequência correta solta Miguel e atordoa cultista")
 check(game.player.position.distance_to(player_at)>.25 and game.player.position.distance_to(player_at)<.31,"acerto faz recuo curto de 30 cm pela física")
 check(is_equal_approx(game.escape_advantage_until-game.elapsed,1.5),"acerto concede 1,5 s de vantagem")
 game._enemy_ticks(1.99); check(enemy.state=="escape_stunned","atordoamento dura pelo menos 1,99 s")
 game._enemy_ticks(.02); check(enemy.state=="idle","atordoamento termina após 2 s")
 # Outro cultista encostado não elimina a vantagem recém-concedida.
 var other=game.enemies[1]; other.position=game.player.position+Vector3.BACK*.55
 check(not game._grab_player(other),"vantagem impede agarrão imediato de outro cultista")
 other.position=Vector3(240,0,200)
 fixture(enemy); game._enemy_ticks(DT)
 check(game.escape.sequence.size()==4 and is_equal_approx(game.escape.limit,2.7),"segundo agarrão: 4 setas, 2,7 s")
 var expected_position: Array=game.checkpoint["position"]
 var attempts=game.escape.attempts
 var wrong=KEY_LEFT if game.escape.sequence[0]!=KEY_LEFT else KEY_RIGHT
 key(wrong); game.hud.update(0)
 check(game.player.dead and not game.escape.active and is_equal_approx(game.escape_blackout,1.5) and game.hud.escape_black.visible,"uma seta errada causa tela preta por 1,5 s")
 game._unhandled_input(InputEventMouseButton.new()); key(KEY_R)
 game._physics_process(1.49)
 check(game.player.dead and game.escape_blackout>0,"input não pula os 1,5 s de tela preta")
 game._physics_process(.02)
 check(not game.player.dead and game.escape_blackout==0 and not game.hud.escape_black.visible and game.player.position.distance_to(Vector3(expected_position[0],expected_position[1],expected_position[2]))<.01,"erro retorna automaticamente ao checkpoint")
 check(game.escape.attempts==attempts,"checkpoint preserva crescimento por agarrão nesta partida")
 fixture(enemy); game._enemy_ticks(DT)
 game._physics_process(game.escape.remaining+.01)
 check(game.player.dead and game.escape_blackout>0,"tempo esgotado também falha sem input")
 game._physics_process(1.51)
 check(not game.player.dead and not game.escape.active,"tempo esgotado volta ao checkpoint")
 # Crescimento exercitado por agarrões reais até além dos limites.
 var growth=true
 for i in 7:
  fixture(enemy); game._enemy_ticks(DT)
  growth=growth and game.escape.sequence.size()==mini(7,game.escape.attempts+2) and is_equal_approx(game.escape.limit,maxf(1.5,3.0-.3*(game.escape.attempts-1)))
  finish()
 check(growth and game.escape.sequence.size()==7 and is_equal_approx(game.escape.limit,1.5),"crescimento: +1 seta/-0,3 s, máximo 7 e mínimo 1,5 s")
 var variants: Dictionary={}
 var model=game.ESCAPE.new(); model.random.seed=20261102
 for i in 16:
  model.start(); variants[str(model.sequence)]=true
 check(variants.size()>1,"sorteio produz sequências diferentes")
 fixture(enemy); game.finisher_item_available=true; var before=game.escape.attempts
 game._enemy_ticks(DT)
 check(not game.escape.active and not game.finisher_item_available and game.escape.attempts==before and enemy.state=="escape_stunned","gancho do futuro item evita agarrão comum e consome uso")
 # A faca antiga não é o futuro item e não pula a sequência.
 fixture(enemy); game.knife=true; game._enemy_ticks(DT)
 check(game.escape.active and game.knife,"faca antiga não substitui o item futuro nem pula minigame")
 finish()
 game.pursuer=game.spawn_actor(Vector3(250,0,200),true,true)
 fixture(game.pursuer); game.finisher_item_available=true
 game._pursuer_tick(DT)
 check(game.escape.active and game.action_target==game.pursuer and game.finisher_item_available and not game.pursuer.dead,"perseguidor agarra; item não o finaliza nem é consumido")
 check(game.pursuer.position.distance_to(game.player.position)>=.62 and game.pursuer.position.distance_to(game.player.position)<.70,"perseguidor respeita raio maior sem atravessar Miguel")
 finish(); game._pursuer_tick(1.99)
 check(game.pursuer.state=="escape_stunned","acerto também atordoa perseguidor por 2 s")
 game._pursuer_tick(.02); check(game.pursuer.state=="idle" and not game.pursuer.dead,"perseguidor retoma caça vivo após atordoamento")
 # Regressão: a IA antiga parava a 1,05/0,83 m, antes de encostar.
 game.finisher_item_available=false; game.pursuer.position=Vector3(250,0,200)
 fixture(enemy); enemy.position=Vector3(200,0,200.95); enemy.aware=true
 enemy.last_seen=game.player.position; game.turn_cooldown=0
 for i in 60:
  game._enemy_ticks(DT)
  if game.escape.active: break
  await physics_frame
 print("APROX comum distancia=",enemy.position.distance_to(game.player.position)," active=",game.escape.active)
 check(game.escape.active,"cultista aproxima pela física até encostar, sem parar a 1,05 m")
 finish()
 game.pursuer.position=Vector3(250,0,200)
 enemy.position=Vector3(230,0,200)
 fixture(game.pursuer); game.pursuer.position=Vector3(200,0,200.80); game.pursuit_memory=9
 for i in 30:
  game._pursuer_tick(DT)
  if game.escape.active: break
  await physics_frame
 print("APROX perseguidor pos=",game.pursuer.position," estado=",game.pursuer.state," distancia=",game.pursuer.position.distance_to(game.player.position)," active=",game.escape.active)
 check(game.escape.active,"perseguidor aproxima pela física até encostar, sem parar a 0,83 m")
 finish()
 # Toque usa a mesma validação, com quatro alvos grandes e sem movimento residual.
 game.pursuer.position=Vector3(250,0,200); game.finisher_item_available=false
 var t=game.TOUCH.new(); game.add_child(t); t.setup(game); game.touch=t
 t._hold(KEY_W,true); Input.flush_buffered_events()
 fixture(enemy); await physics_frame
 game._enemy_ticks(DT); Input.flush_buffered_events(); t._process(0); game.hud.update(0)
 check(t.escape_controls and t.escape_buttons.size()==4 and t.escape_buttons.all(func(b):return b["r"]>=32),"celular mostra quatro setas com alvos de pelo menos 64 px")
 check(not Input.is_physical_key_pressed(KEY_W) and game.hud.escape_prompt.visible,"entrada no minigame solta analógico e mostra sequência")
 for arrow in game.escape.sequence.duplicate(): touch_arrow(arrow)
 t._process(0); game.hud.update(0)
 check(not game.escape.active and not t.escape_controls and not game.hud.escape_prompt.visible,"toque acerta a sequência; setas somem ao soltar")
 fixture(enemy); game._enemy_ticks(DT)
 wrong=KEY_LEFT if game.escape.sequence[0]!=KEY_LEFT else KEY_RIGHT
 touch_arrow(wrong)
 check(game.escape_blackout>0,"seta errada no celular também falha")
 game._physics_process(1.51)
 check(not game.player.dead,"falha por toque também restaura checkpoint")
 print("CAPITULO1_ESCAPE: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
