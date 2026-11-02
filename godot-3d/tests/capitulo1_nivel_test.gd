extends SceneTree
## Validação do level design (skill level-design: rotas sem dependência única,
## métricas, cobertura e esconderijos nas zonas vigiadas, ritmo em dente de serra).
var passed:=0
var failed:=0
const NIVEL=preload("res://capitulo1/nivel.gd")
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
 if ok: passed+=1; print("PASS ",text)
 else: failed+=1; push_error("FAIL "+text)

func cell(g,v: Vector3) -> Vector2i: return Vector2i(roundi(v.x*2),roundi(v.z*2))

func reachable(g,s,a: Vector2,b: Vector2,block: Rect2) -> bool:
 var saved: Array=[]
 if block.size!=Vector2.ZERO:
  var lo: Vector3=s.p(block.position.x,block.position.y); var hi: Vector3=s.p(block.end.x,block.end.y)
  for x in range(floori(lo.x*2),ceili(hi.x*2)+1):
   for z in range(floori(lo.z*2),ceili(hi.z*2)+1):
    var c:=Vector2i(x,z)
    if g.is_in_boundsv(c) and not g.is_point_solid(c): g.set_point_solid(c,true); saved.append(c)
 var path=g.get_id_path(cell(g,s.p(a.x,a.y)),cell(g,s.p(b.x,b.y)),false)
 for c in saved: g.set_point_solid(c,false)
 return not path.is_empty()

func run() -> void:
 var game=load("res://capitulo1/main.tscn").instantiate()
 root.add_child(game)
 for i in 3: await physics_frame
 var s=game.school
 for d in s.doors: d.set_open(true,true)
 await physics_frame
 game._build_paths()
 var g=game.path_grid
 var start: Vector2=NIVEL.ROUTE_NORTH[0]; var goal: Vector2=NIVEL.ROUTE_NORTH[-1]
 check(reachable(g,s,start,goal,Rect2()),"pátio aberto alcança o pátio de química")
 check(reachable(g,s,start,goal,NIVEL.CHOKE_SOUTH),"rota norte funciona sozinha (sul bloqueada)")
 check(reachable(g,s,start,goal,NIVEL.CHOKE_NORTH),"rota sul funciona sozinha (norte bloqueada)")
 check(reachable(g,s,Vector2(817,123),goal,Rect2()),"de onde Miguel acorda até o pátio de química")
 check(reachable(g,s,Vector2(324,80),Vector2(632.5,630),Rect2()),"do pátio de química até o portão 1")
 # Portas: vão cabe a cápsula com folga de câmera.
 check(.78*2>=NIVEL.CAPSULE_RADIUS*2+.9,"vão das portas comporta Miguel")
 # Esconderijo perto de cada posto de cultista.
 var far: Array=[]
 for post in NIVEL.GUARD_POSTS:
  var at: Vector3=s.p(post.x,post.y)
  var best:=INF
  for h in s.hides:
   if absf(h["inside"].y-at.y)<2: best=minf(best,Vector2(h["inside"].x-at.x,h["inside"].z-at.z).length())
  if best>NIVEL.HIDE_NEAR_GUARD: far.append([post,best])
 print("POSTOS_SEM_ESCONDERIJO ",far)
 check(far.is_empty(),"todo posto de cultista tem esconderijo a até 10 m")
 # Cobertura: nos trechos de rota vistos por um posto, há obstáculo baixo/médio
 # (0,8–3 m) a até ~5 m.
 var covers: Array[Vector3]=[]
 for body in s.find_children("*","StaticBody3D",true,false):
  for c in body.get_children():
   if c is CollisionShape3D and c.shape is BoxShape3D:
    var size: Vector3=c.shape.size
    var w: Vector3=body.global_basis.x.abs()*size.x+body.global_basis.y.abs()*size.y+body.global_basis.z.abs()*size.z
    var top: float=body.to_global(c.position).y+w.y*.5
    if top>.8 and top<3.3 and w.x<4.5 and w.z<4.5 and body.to_global(c.position).y<2: covers.append(body.to_global(c.position))
 var bare: Array=[]
 for route in [NIVEL.ROUTE_NORTH,NIVEL.ROUTE_SOUTH]:
  for i in route.size()-1:
   var a: Vector3=s.p(route[i].x,route[i].y); var b: Vector3=s.p(route[i+1].x,route[i+1].y)
   var steps:=int(a.distance_to(b))
   for k in steps+1:
    var at:=a.lerp(b,float(k)/maxf(1,steps))
    var watched:=false
    for post in NIVEL.GUARD_POSTS:
     var gp: Vector3=s.p(post.x,post.y)
     if gp.distance_to(at)<NIVEL.GUARD_SIGHT and game.visible_between(gp+Vector3.UP*1.5,at+Vector3.UP*1.0): watched=true; break
    if not watched: continue
    var near:=false
    for c in covers:
     if Vector2(c.x-at.x,c.z-at.z).length()<NIVEL.COVER_SPACING: near=true; break
    if not near: bare.append(Vector2i(roundi(at.x/s.SCALE+440),roundi(at.z/s.SCALE+300)))
 print("TRECHOS_VIGIADOS_SEM_COBERTURA ",bare)
 check(bare.is_empty(),"trechos vigiados das rotas têm cobertura a cada ~5 m")
 # Ritmo: sobe no geral, com respiro (<=0,25) antes do pico do ritual e da gravação.
 var b: Array=NIVEL.BEATS
 var dips:=0
 for i in range(1,b.size()):
  if b[i]["intensidade"]<b[i-1]["intensidade"]: dips+=1
 var top:=0
 for i in b.size(): if b[i]["intensidade"]>b[top]["intensidade"]: top=i
 check(dips>=2 and top>=b.size()-3,"ritmo em dente de serra com clímax no fim")
 print("CAPITULO1_NIVEL: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
