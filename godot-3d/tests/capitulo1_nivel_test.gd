extends SceneTree
## Validação do level design (skill level-design: rotas sem dependência única,
## métricas, cobertura e esconderijos nas zonas vigiadas, ritmo em dente de serra).
## Pontos em células da grade ASCII (capitulo1/mapa/terreo.txt).
var passed:=0
var failed:=0
const NIVEL=preload("res://capitulo1/nivel.gd")
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
 if ok: passed+=1; print("PASS ",text)
 else: failed+=1; push_error("FAIL "+text)

func cell(v: Vector3) -> Vector2i: return Vector2i(roundi(v.x*2),roundi(v.z*2))

## A* do jogo entre duas células da grade, com um retângulo de células bloqueado.
func reachable(g,s,a: Vector2,b: Vector2,block: Rect2i) -> bool:
 var saved: Array=[]
 if block.size!=Vector2i.ZERO:
  var lo: Vector3=s.cel(block.position.x,block.position.y)-Vector3(.5,0,.5)
  var hi: Vector3=s.cel(block.end.x,block.end.y)-Vector3(.5,0,.5)
  for x in range(floori(lo.x*2),ceili(hi.x*2)+1):
   for z in range(floori(lo.z*2),ceili(hi.z*2)+1):
    var c:=Vector2i(x,z)
    if g.is_in_boundsv(c) and not g.is_point_solid(c): g.set_point_solid(c,true); saved.append(c)
 var path=g.get_id_path(cell(s.cel(a.x,a.y)),cell(s.cel(b.x,b.y)),false)
 for c in saved: g.set_point_solid(c,false)
 return not path.is_empty()

func path_length(g,a: Vector3,b: Vector3) -> float:
 var start=cell(a); var end=cell(b)
 if not g.is_in_boundsv(start) or not g.is_in_boundsv(end) or g.is_point_solid(start) or g.is_point_solid(end): return INF
 var path=g.get_point_path(start,end,false)
 if path.is_empty(): return INF
 var length:=0.0
 for i in range(1,path.size()): length+=path[i-1].distance_to(path[i])
 return length

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
 var acorda: Vector2i=s.celula_de(s.spawn)
 var portao: Vector2i=s.celula_de(s.gate_at-Vector3(0,0,1.0))
 check(reachable(g,s,start,goal,Rect2i()),"pátio aberto alcança o pátio de química")
 check(reachable(g,s,start,goal,NIVEL.CHOKE_SOUTH),"rota norte funciona sozinha (sul bloqueada)")
 check(reachable(g,s,start,goal,NIVEL.CHOKE_NORTH),"rota sul funciona sozinha (norte bloqueada)")
 check(reachable(g,s,Vector2(acorda),goal,Rect2i()),"de onde Miguel acorda até o pátio de química")
 check(reachable(g,s,goal,Vector2(portao),Rect2i()),"do pátio de química até o portão 1")
 # Portas: vão cabe a cápsula com folga de câmera.
 check(s.KIT.VAO_PORTA>=NIVEL.CAPSULE_RADIUS*2+.9,"vão das portas comporta Miguel")
 # Esconderijo perto de cada posto de cultista.
 var far: Array=[]
 for at in s.postos:
  var best:=INF
  for h in s.hides:
   if absf(h["inside"].y-at.y)<2: best=minf(best,Vector2(h["inside"].x-at.x,h["inside"].z-at.z).length())
  if best>NIVEL.HIDE_NEAR_GUARD: far.append([s.celula_de(at),best])
 print("POSTOS_SEM_ESCONDERIJO ",far)
 check(s.postos.size()==7 and far.is_empty(),"sete postos, todos com esconderijo a até 10 m")
 # O abrigo deve ser alcançável, não só próximo do outro lado de uma parede.
 var all_posts: Array=s.postos.duplicate(); all_posts.append(s.pursuer_post)
 var inaccessible: Array=[]
 for i in all_posts.size():
  var best=INF
  for h in s.hides: best=minf(best,path_length(g,all_posts[i],h["entry"]))
  print("POSTO %d celula=%s abrigo_por_caminho=%.2f m"%[i+1,s.celula_de(all_posts[i]),best])
  if best>10: inaccessible.append(i+1)
 check(inaccessible.is_empty(),"oito postos têm caminho de até 10 m até um esconderijo")
 var marks=true
 for number in range(1,9): marks=marks and s.andares[0].celulas(str(number)).size()==1
 check(marks and game.enemies.size()==8 and game.pursuer==null,"grade tem sete comuns, o leitor da biblioteca e um posto condicional, sem perseguidor inicial")
 # Reserva um disco de 1 m em TODOS os postos: simula corpo e margem de desvio.
 var occupied: Array=[]
 for at in all_posts:
  var middle=cell(at)
  for dx in range(-2,3):
   for dz in range(-2,3):
    var v=middle+Vector2i(dx,dz)
    if Vector2(dx,dz).length()>2 or not g.is_in_boundsv(v) or g.is_point_solid(v): continue
    g.set_point_solid(v,true); occupied.append(v)
 check(reachable(g,s,start,goal,NIVEL.CHOKE_SOUTH),"rota norte desvia dos oito postos ocupados")
 check(reachable(g,s,start,goal,NIVEL.CHOKE_NORTH),"rota sul desvia dos oito postos ocupados")
 check(reachable(g,s,Vector2(acorda),goal,Rect2i()) and reachable(g,s,goal,Vector2(portao),Rect2i()),"postos ocupados não bloqueiam caminho obrigatório nem fuga")
 for v in occupied: g.set_point_solid(v,false)
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
   var a: Vector3=s.cel(route[i].x,route[i].y); var b: Vector3=s.cel(route[i+1].x,route[i+1].y)
   var steps:=int(a.distance_to(b))
   for k in steps+1:
    var at:=a.lerp(b,float(k)/maxf(1,steps))
    var watched:=false
    for gp in s.postos:
     if gp.distance_to(at)<NIVEL.GUARD_SIGHT and game.visible_between(gp+Vector3.UP*1.5,at+Vector3.UP*1.0): watched=true; break
    if not watched: continue
    var near:=false
    for c in covers:
     if Vector2(c.x-at.x,c.z-at.z).length()<NIVEL.COVER_SPACING: near=true; break
    if not near: bare.append(s.celula_de(at))
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
 # Pontos de roteiro caem em chão livre (não dentro de parede/bloco).
 var space=game.get_world_3d().direct_space_state
 var presos: Array=[]
 for nome in NIVEL.PONTOS:
  var q:=PhysicsPointQueryParameters3D.new()
  q.position=NIVEL.ponto(s,nome,1.0); q.collision_mask=1
  if not space.intersect_point(q).is_empty(): presos.append(nome)
 print("PONTOS_EM_SOLIDO ",presos)
 check(presos.is_empty(),"pontos de roteiro em chão livre")
 print("CAPITULO1_NIVEL: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
