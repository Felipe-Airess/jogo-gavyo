extends SceneTree
## Mede o desvio mínimo de exploração pela navegação real do térreo.
## Portas abertas somente nesta instância de medição; nenhum osso/grade é escrito.
const OUT="res://../docs/verificacao-objetivos/duracao-exploracao.json"
func _initialize() -> void: call_deferred("run")
func distance_between(game,a: Vector3,b: Vector3) -> float:
 var start=Vector2i(roundi(a.x*2),roundi(a.z*2)); var end=Vector2i(roundi(b.x*2),roundi(b.z*2))
 var points=game.path_grid.get_point_path(start,end,false)
 assert(points.size()>0,"Ponto de objetivo sem caminho")
 var length:=0.0
 for i in range(1,points.size()): length+=points[i].distance_to(points[i-1])
 return length
func run() -> void:
 var game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_process(false); game.set_physics_process(false)
 game.objectives.bag_door.locked=false
 for door in game.school.doors: door.set_open(true,true)
 for i in 3: await physics_frame
 game._build_paths()
 var ids=["nota_1","nota_2","nota_3","nota_4","pista_1","pista_2","finalizador"]
 var points: Array=[game.objectives.position_of("chave")]
 for id in ids: points.append(game.objectives.position_of(id))
 points.append(game.school.stairs_bottom)
 var distances: Array=[]
 for a in points:
  var row: Array=[]
  for b in points: row.append(distance_between(game,a,b))
  distances.append(row)
 # Caminho mínimo que visita os sete opcionais antes de continuar à escada.
 var costs: Dictionary={}; var size=ids.size(); var full=(1<<size)-1
 for i in size: costs[Vector2i(1<<i,i)]=distances[0][i+1]
 for mask in range(1,full+1):
  for i in size:
   var state=Vector2i(mask,i)
   if not costs.has(state): continue
   for j in size:
    if mask&(1<<j): continue
    var next=Vector2i(mask|(1<<j),j)
    costs[next]=minf(float(costs.get(next,INF)),float(costs[state])+float(distances[i+1][j+1]))
 var best:=INF
 for i in size: best=minf(best,float(costs[Vector2i(full,i)])+float(distances[i+1][-1]))
 var direct: float=distances[0][-1]
 var data={"metodo":"A* real, portas abertas na instância; visita mínima dos sete opcionais entre chave e escada", "direto_m":direct,"com_opcionais_m":best,"desvio_extra_m":best-direct,"desvio_extra_s_1_45_m_s":(best-direct)/1.45,"leitura_estimada_s":[60,120],"busca_espera_estimada_s":[120,300],"limite":"Não mede a abertura diurna/cozinha do Prompt C, ainda não implementadas. Não inclui duração futura dos textos de Felipe."}
 var file=FileAccess.open(OUT,FileAccess.WRITE); file.store_string(JSON.stringify(data,"  "))
 print("EXPLORACAO ",JSON.stringify(data))
 quit()
