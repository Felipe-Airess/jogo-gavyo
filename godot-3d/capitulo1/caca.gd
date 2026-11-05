extends RefCounted
## Memória individual da caça. Só move corpos e pede clipes ao controlador.
const RUN:=3.0
const WALK:=1.1
const NOTICE:=.4
const SEARCH:=60.0
var mode:="patrol"
var remaining:=0.0
var search_left:=0.0
var point_time:=0.0
var scan_left:=0.0
var step:=0
var witnessed_hide:=-1
var destination:=Vector3.ZERO
var shout_count:=0

func reset() -> void:
 mode="patrol"; remaining=0; search_left=0; point_time=0; scan_left=0
 step=0; witnessed_hide=-1; destination=Vector3.ZERO; shout_count=0

func _stop(e) -> void:
 e.velocity=Vector3.ZERO; e.play("guarda")
func _notice(e) -> void:
 mode="notice"; remaining=NOTICE; e.aware=true; _stop(e)
func _move(game,e,target: Vector3,speed: float,dt: float) -> void:
 destination=target
 var repel:=Vector3.ZERO
 for other in game.enemies:
  if other==e or other.dead or other.down or absf(other.position.y-e.position.y)>.8: continue
  var delta: Vector3=(e.position-other.position)*Vector3(1,0,1)
  var distance=delta.length()
  if distance>.001 and distance<1.05: repel+=delta/distance*(1.05-distance)*2.0
 var forward=(target-e.position)*Vector3(1,0,1)
 var waypoint=target
 if repel.length()>.01 and forward.length()>.2:
  waypoint=e.position+(forward.normalized()+repel).normalized()*minf(2,forward.length())
  waypoint.y=target.y
 e.state="hunt"
 game._navigate(e,waypoint,speed,dt)

func surround(game,e) -> Vector3:
 var hunters: Array=[]
 for other in game.enemies:
  if not other.dead and not other.down and other.aware: hunters.append(other)
 if hunters.size()<2: return e.last_seen
 var slot=hunters.find(e)
 var angle=TAU*maxi(0,slot)/hunters.size()
 # Desvia por lados diferentes à distância, fecha até o contato ao chegar.
 var radius=2.2 if e.position.distance_to(e.last_seen)>4 else .45
 var point: Vector3=e.last_seen+Vector3(cos(angle),0,sin(angle))*radius
 var cell=Vector2i(roundi(point.x*2),roundi(point.z*2))
 if game.path_grid!=null and game.path_grid.is_in_boundsv(cell) and game.path_grid.is_point_solid(cell): return e.last_seen
 if not game.visible_between(e.last_seen+Vector3.UP*.6,point+Vector3.UP*.6): return e.last_seen
 return point

func _search_point(game,e) -> Vector3:
 var slot=game.enemies.find(e)
 for attempt in 12:
  var angle=float(step+attempt)*2.39996+float(slot)*1.7
  var radius=1.4+float(posmod(step+attempt,3))*.65
  var point: Vector3=e.last_seen+Vector3(cos(angle),0,sin(angle))*radius
  var cell=Vector2i(roundi(point.x*2),roundi(point.z*2))
  if game.path_grid==null or not game.path_grid.is_in_boundsv(cell) or not game.path_grid.is_point_solid(cell): return point
 return e.last_seen

func tick(game,e,dt: float) -> void:
 # Quem já caça rastreia pelo cone; quem não sabe precisa encher a suspeita
 # (percepcao.gd: luz, distância, postura, periferia, barulho).
 var sees: bool=game.enemy_sees(e) if e.aware else game.percepcao.tick(game,e,dt)
 if sees:
  e.last_seen=game.player.position; e.memory=SEARCH; e.suspicion=1
  if mode in ["patrol","return"]:
   _notice(e); return
  e.aware=true
  if mode!="notice": mode="chase"
 if mode=="notice":
  _stop(e); e.face(e.last_seen,dt)
  remaining-=dt
  if remaining>0: return
  shout_count+=1; game._cultist_shout(e)
  mode="chase" if sees else "last_seen"
 if mode=="chase" and not sees: mode="last_seen"
 if mode not in ["notice","open_hide"] and game.player.hidden and witnessed_hide>=0 and witnessed_hide==game.hidden_spot:
  mode="to_hide"
 if mode in ["to_hide","open_hide"]:
  if not game.player.hidden or witnessed_hide!=game.hidden_spot:
   witnessed_hide=-1; mode="last_seen"
  else:
   var spot: Dictionary=game.school.hides[witnessed_hide]
   var approach: Vector3=spot["entry"]+spot["normal"]*.60
   if mode=="to_hide":
    if e.position.distance_to(approach)>.18: _move(game,e,approach,RUN,dt); return
    _stop(e); e.face(spot["inside"])
    e.start_action("novo/Interact")
    game.school.set_hide_open(witnessed_hide,true)
    mode="open_hide"; remaining=.65; return
   e.velocity=Vector3.ZERO; remaining-=dt
   if remaining>0: return
   if not game.CONTACT.room_for(game.player,spot["entry"]): return
   game._leave_hide()
   mode="chase"
   if game._grab_player(e): return
 if mode=="chase":
  _move(game,e,surround(game,e),RUN,dt); return
 if mode=="last_seen":
  if e.position.distance_to(e.last_seen)>.35: _move(game,e,e.last_seen,RUN,dt); return
  mode="search"; search_left=SEARCH; step=0; scan_left=1.0
  destination=_search_point(game,e); point_time=0
 if mode=="search":
  search_left=maxf(0,search_left-dt); e.memory=search_left
  if search_left<=0:
   mode="return"; e.aware=false; e.suspicion=0; witnessed_hide=-1
  else:
   point_time+=dt
   if scan_left>0:
    scan_left=maxf(0,scan_left-dt); _stop(e)
    # Olha com o corpo inteiro; nenhum osso recebe rotação procedural.
    var angle=float(step)*2.39996+(1-scan_left)*2.2
    e.face(e.position+Vector3(cos(angle),0,sin(angle)),dt)
   elif e.position.distance_to(destination)<.25 or point_time>4:
    step+=1; destination=_search_point(game,e); point_time=0; scan_left=1.0
    _stop(e)
   else: _move(game,e,destination,WALK,dt)
   return
 if mode=="return":
  if e.position.distance_to(e.home)>.25: _move(game,e,e.home,.8,dt); return
  mode="patrol"; e.state="idle"; _stop(e); return
 if e.aware:
  mode="last_seen"; return
 # Ruído/chamado pode despertar interesse, mas não dá visão através de paredes.
 e.memory=maxf(0,e.memory-dt)
 if e.suspicion>.35 and e.memory>0:
  if e.position.distance_to(e.last_seen)>.35: _move(game,e,e.last_seen,.85,dt)
  else: _stop(e); e.face(e.position+Vector3(sin(e.clock),0,cos(e.clock)),dt)
 else:
  e.patrol_clock+=dt
  _move(game,e,e.home+Vector3(0,0,-1.7 if int(e.patrol_clock/5)%2==0 else 1.7),game.NIVEL.WALK,dt)
