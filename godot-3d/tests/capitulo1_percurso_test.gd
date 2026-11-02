extends SceneTree
## Percurso contínuo do capítulo 1, sem teletransportes: Miguel só se move por
## teclas simuladas (W) e pela física real do jogo. A direção da câmera é apontada
## para o próximo ponto de uma rota calculada pela própria grade A* do jogo.
## Interações usam game.interact(), o mesmo caminho do [Espaço].
## Observacional: registra fase, alerta e onde travou. Não avalia diversão/estética.
var passed:=0
var failed:=0
var game: Node3D
var frame_count:=0
var last_health:=100.0
## "rota": inimigos patrulham e bloqueiam fisicamente, mas não percebem Miguel;
## valida geometria e fluxo até o fim. "real": percepção ativa, só observacional.
## "patio": corredores passivos, cultistas do ritual atentos e Miguel agachado
## dentro do pátio de química — testa a passagem escondida.
var mode:="rota"
var max_ritual_susp:=0.0
var noticed_logged:=false
var nav_grid: AStarGrid2D

func _initialize() -> void: call_deferred("run")

func check(ok: bool,text: String) -> void:
 if ok: passed+=1; print("PASS ",text)
 else: failed+=1; push_error("FAIL "+text)

func note(text: String) -> void:
 print("PERCURSO ",text)

func key(code: Key,pressed: bool) -> void:
 var ev:=InputEventKey.new()
 ev.physical_keycode=code; ev.keycode=code; ev.pressed=pressed
 Input.parse_input_event(ev)
 Input.flush_buffered_events()

func step() -> void:
 if mode in ["rota","patio"]:
  # Rota testa mapa e fluxo: cultistas não percebem nem bloqueiam o corpo.
  for e in game.enemies:
   e.suspicion=0; e.aware=false; e.attack_target=null; e.collision_layer=0
 if mode=="rota":
  for f in game.school.ritual_figures: f.suspicion=0
 if mode=="patio":
  var px: float=game.player.position.x/game.school.SCALE+440
  var pz: float=game.player.position.z/game.school.SCALE+300
  var inside: bool=game.player.position.y<1 and px>160 and px<345 and pz>5 and pz<95
  if inside!=Input.is_physical_key_pressed(KEY_CTRL): key(KEY_CTRL,inside)
  for f in game.school.ritual_figures: max_ritual_susp=maxf(max_ritual_susp,f.suspicion)
  if game.ritual_noticed and not noticed_logged:
   noticed_logged=true
   note("ritual notou Miguel em p(%.0f,%.0f) agachado=%s bolsa=%s gravando=%s" % [px,pz,game.player.crouched,game.bag_found,game.recording])
 await physics_frame
 frame_count+=1
 if mode=="real" and game.player.health<last_health:
  note("dano %.0f em %s; inimigos: %s" % [last_health-game.player.health,game.player.position,enemy_summary()])
 last_health=game.player.health

func enemy_summary() -> String:
 var parts: Array[String]=[]
 for e in game.enemies:
  parts.append("%s d=%.1f aware=%s susp=%.2f" % [e.state,e.position.distance_to(game.player.position),e.aware,e.suspicion])
 return ", ".join(parts)

func aim(at: Vector3) -> void:
 var d: Vector3=at-game.player.position
 game.view.yaw=atan2(-d.x,-d.z)

## Rota no térreo pela grade do jogo; no andar superior, linha reta (a grade só
## representa o térreo, como no código de navegação dos inimigos).
func route(to: Vector3) -> Array[Vector3]:
 var out: Array[Vector3]=[]
 var from: Vector3=game.player.position
 var grid: AStarGrid2D=nav_grid if nav_grid!=null else game.path_grid
 if from.y<1 and to.y<1 and grid!=null:
  var a:=Vector2i(roundi(from.x*2),roundi(from.z*2))
  var b:=Vector2i(roundi(to.x*2),roundi(to.z*2))
  if grid.is_point_solid(b):
   note("destino em célula sólida %s" % [to])
  # Começo dentro da margem de uma parede: usa a célula livre mais próxima.
  if grid.is_point_solid(a):
   for r in range(1,5):
    var found:=false
    for dx in range(-r,r+1):
     for dz in range(-r,r+1):
      var c:=a+Vector2i(dx,dz)
      if grid.is_in_boundsv(c) and not grid.is_point_solid(c): a=c; found=true; break
     if found: break
    if found: break
  var id_path=grid.get_id_path(a,b,false)
  if id_path.is_empty(): note("rota vazia de %s (sólido=%s) até %s (sólido=%s)" % [a,grid.is_point_solid(a),b,grid.is_point_solid(b)])
  for pt in id_path:
   out.append(Vector3(pt.x*.5,0,pt.y*.5))
 out.append(to)
 return out

## Anda até `to`. Abre portas fechadas à frente com interact(). Falha se ficar
## parado por muito tempo ou se a fase mudar para algo fora de `allowed`.
func walk(to: Vector3,label: String,tolerance:=.6,limit:=60*90) -> bool:
 var points:=route(to)
 var start_frame:=frame_count
 var last_progress:=frame_count
 var best:=INF
 var i:=0
 key(KEY_W,true)
 while i<points.size():
  if frame_count-start_frame>limit:
   note("%s: tempo esgotado em %s alvo %s" % [label,game.player.position,points[i]]); key(KEY_W,false); return false
  if game.phase not in ["investigate","chase","sighting"]:
   key(KEY_W,false)
   # Cenas de história param o controle; aguarda e continua.
   if game.phase in ["intro","discovery"]:
    await step(); continue
   note("%s: fase mudou para %s" % [label,game.phase]); return game.phase=="gate_jump"
  if game.player.dead:
   note("%s: Miguel morreu em %s" % [label,game.player.position]); key(KEY_W,false); return false
  key(KEY_W,true)
  var target: Vector3=points[i]
  aim(target)
  var flat:=Vector2(game.player.position.x-target.x,game.player.position.z-target.z).length()
  if flat<(tolerance if i==points.size()-1 else .45):
   i+=1; best=INF; last_progress=frame_count; continue
  if flat<best-.05: best=flat; last_progress=frame_count
  # Porta fechada logo à frente: para e aperta [Espaço] olhando para ela.
  for door in game.school.doors:
   var c: Vector3=door.center()
   if not door.opened and absf(c.y-1-game.player.position.y)<1 and game.player.position.distance_to(c-Vector3.UP)<1.7 and (c-game.player.position).dot(target-game.player.position)>0:
    key(KEY_W,false); aim(c); await step()
    game.interact(); note("%s: abriu porta %s" % [label,door.title])
    for w in 30: await step()
    last_progress=frame_count
  if frame_count-last_progress==40:
   # Parado: tenta abrir porta à frente como o jogador faria.
   for door in game.school.doors:
    if not door.opened and game.player.position.distance_to(door.center())<2.2:
     key(KEY_W,false); aim(door.center()); await step()
     game.interact(); note("%s: abriu porta %s" % [label,door.title])
     for w in 30: await step()
     last_progress=frame_count
     break
  if frame_count-last_progress>240:
   var sp=game.get_world_3d().direct_space_state
   var hit=sp.intersect_ray(PhysicsRayQueryParameters3D.create(game.player.position+Vector3.UP*.5,target+Vector3.UP*.5,1,[game.player.get_rid()]))
   if hit: note("obstáculo: %s %s em %s" % [hit.collider.name,hit.collider.get_parent().name,hit.position])
   note("%s: TRAVOU em %s (alvo %s, faltam %.1f m)" % [label,game.player.position,target,flat])
   key(KEY_W,false); return false
  await step()
 key(KEY_W,false)
 note("%s: chegou em %s após %.1f s" % [label,game.player.position,(frame_count-start_frame)/60.0])
 return true

func run() -> void:
 if "--real" in OS.get_cmdline_user_args(): mode="real"
 if "--patio" in OS.get_cmdline_user_args(): mode="patio"
 note("modo "+mode)
 game=load("res://capitulo1/main.tscn").instantiate()
 root.add_child(game)
 game.qa_mode=true
 for i in 5: await step()
 # A grade de rotas considera portas abertas (o robô as abre ao chegar).
 for door in game.school.doors: door.set_open(true,true)
 await step()
 game._build_paths()
 nav_grid=game.path_grid
 for door in game.school.doors: door.set_open(false,true)
 await step()
 game._build_paths()
 var enemy_grid=game.path_grid
 game.begin()
 while game.phase=="intro": await step()
 check(game.phase=="investigate","abertura termina sozinha pelo tempo do jogo")
 game.path_grid=nav_grid
 var s=game.school
 var entrance: Vector3=s.p(s.STAIR_EAST_X+8,51)
 var landing: Vector3=s.p(172,75,s.LEVEL)
 var ok:=await walk(entrance,"entrada da escada no pátio de química")
 if ok: ok=await walk(s.stairs_bottom,"pé da escada",.4)
 game.path_grid=enemy_grid
 if ok: ok=await walk(s.stairs_top,"subir escada",.5)
 if ok: ok=await walk(landing,"patamar",.5)
 check(ok and game.player.position.y>3,"chega ao andar superior andando")
 if ok: ok=await walk(s.p(130.5,78,s.LEVEL),"corredor superior")
 if ok: ok=await walk(s.p(130.5,58,s.LEVEL),"porta do 3 Informática")
 if ok: ok=await walk(s.p(130.5,42.5,s.LEVEL),"mesa da bolsa",.3)
 if ok:
  aim(s.bag_at); await step(); game.interact()
 check(game.bag_found,"pega a bolsa após percurso contínuo")
 note("alerta=%s fase=%s" % [game.alert_spread,game.phase])
 if ok: ok=await walk(s.p(130.5,78,s.LEVEL),"sair da sala")
 if ok: ok=await walk(landing,"patamar na volta",.5)
 if ok: ok=await walk(s.stairs_top,"topo da escada",.5)
 if ok: ok=await walk(s.stairs_bottom,"descer escada",.6)
 check(ok and game.player.position.y<.6,"desce ao térreo andando")
 game.path_grid=nav_grid
 if ok: ok=await walk(s.ritual_approach,"abrigo no pé da escada",1.0)
 check(game.before_ritual,"checkpoint antes do ritual alcançado andando")
 if ok: ok=await walk(entrance,"entrada da escada",.5)
 if ok: ok=await walk(s.p(s.STAIR_EAST_X+1,51),"espiar da entrada da escada",.35)
 if ok:
  var target: Vector3=s.ritual_center+Vector3.UP*.7
  for w in 20:
   var d: Vector3=target-game.view.camera.global_position
   game.view.yaw=atan2(-d.x,-d.z); game.view.pitch=asin(d.normalized().y)
   await step()
  note("enquadra=%s inimigos: %s" % [game.can_frame_ritual(),enemy_summary()])
  game.toggle_recording()
  for w in 60*5:
   var d: Vector3=target-game.view.camera.global_position
   game.view.yaw=atan2(-d.x,-d.z); game.view.pitch=asin(d.normalized().y)
   await step()
   if w%60==0: note("gravando=%s t=%.1f" % [game.recording,game.record_time])
   if game.video_recorded: break
 check(game.video_recorded,"grava o ritual em sequência contínua")
 note("alerta=%s fase=%s perseguidor=%s" % [game.alert_spread,game.phase,is_instance_valid(game.pursuer)])
 if ok: ok=await walk(s.gate_at-Vector3(0,0,1.4),"portão 1",1.0,60*150)
 for w in 60*3:
  if game.phase=="ending": break
  await step()
 check(game.phase in ["ending","escaped"] and game.player.position.z>s.gate_at.z,"pula o portão e chega ao encerramento")
 for e in game.enemies:
  if e.state=="vault" and not e.aware: note("inimigo preso tentando pular em %s" % [e.position])
 note("tempo de jogo total %.1f s, mortes %d" % [frame_count/60.0,game.death_count])
 var nearest:=INF
 for e in game.enemies: nearest=minf(nearest,e.home.distance_to(s.ritual_approach))
 note("distância do checkpoint 2 ao cultista mais próximo (posição inicial): %.2f m" % nearest)
 if mode=="patio":
  note("suspeita máxima do ritual %.2f; notado=%s" % [max_ritual_susp,game.ritual_noticed])
  check(not game.ritual_noticed,"agachado, passa pelo pátio sem o ritual notar")
 print("CAPITULO1_PERCURSO[%s]: %d passed, %d failed" % [mode,passed,failed])
 # Modo real é observacional: falhas viram registro, não reprovação.
 quit(1 if failed and mode=="rota" else 0)
