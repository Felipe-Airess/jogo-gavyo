extends SceneTree
## Mapa em grade ASCII + kit modular (capitulo1/mapa/). Confere o TEXTO (legenda,
## marcas, portas em par, perímetro fechado, salas alcançáveis), o KIT (peças de
## 2 m com pivô na base, recurso salvo em dia) e que a FÍSICA montada bate com o
## texto. Não avalia beleza nem diversão.
const GRADE=preload("res://capitulo1/mapa/grade.gd")
const KIT=preload("res://capitulo1/mapa/kit.gd")
var passed:=0
var failed:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
 if ok: passed+=1; print("PASS ",text)
 else: failed+=1; push_error("FAIL "+text)

## Células alcançáveis a pé a partir de `inicio` (portas e vãos passam; paredes,
## blocos, colunas, árvores e o portão não).
func andar_livre(g,inicio: Vector2i) -> Dictionary:
 var visto: Dictionary={inicio:true}
 var fila: Array[Vector2i]=[inicio]
 while not fila.is_empty():
  var v: Vector2i=fila.pop_back()
  for d in g.VIZINHOS:
   var n: Vector2i=v+d
   if visto.has(n): continue
   # Do alto da escada se chega ao andar de cima, não ao vão sob o patamar.
   if g.e_escada(v.x,v.y) and g.SOBE[g.chv(v)]==d and not g.e_escada(n.x,n.y): continue
   var s: String=g.chv(n)
   if s in "#-WG%CT_" or s==" ":
    if s==" ": visto[n]=true
    continue
   visto[n]=true; fila.append(n)
 return visto

func run() -> void:
 var t=GRADE.ler("res://capitulo1/mapa/terreo.txt")
 var u=GRADE.ler("res://capitulo1/mapa/superior.txt")
 check(t.erros.is_empty() and u.erros.is_empty(),"as duas grades são lidas sem erro")
 print("TAMANHO terreo=%dx%d superior=%dx%d"%[t.largura,t.altura,u.largura,u.altura])
 # Marcas da história: cada uma uma vez só.
 var unicas:={"@":t,"*":t,"+":t,"$":u}
 var faltando: Array=[]
 for m in unicas:
  if unicas[m].celulas(m).size()!=1: faltando.append(m)
 check(faltando.is_empty(),"acordar, ritual, checkpoint 2 e bolsa aparecem uma vez cada")
 check(t.celulas("1234567").size()==7 and t.celulas("8").size()==1 and t.celulas("G").size()>=2,"sete postos comuns, perseguidor condicional e portão marcados")
 # Toda letra da legenda está no mapa uma vez.
 var letras: Array=[]
 for g in [t,u]:
  for k in g.salas.keys()+g.areas.keys():
   if g.celulas(k).size()!=1: letras.append(k)
 check(letras.is_empty(),"cada nome da legenda marca exatamente um lugar")
 # Portas sempre em par (peça de 2 m).
 var impares: Array=[]
 for g in [t,u]:
  for seq in g.sequencias("D"):
   if seq["n"]!=2: impares.append(seq["inicio"])
 check(impares.is_empty(),"portas em pares DD")
 # Perímetro fechado: a pé, saindo de onde Miguel acorda, não se chega ao vazio.
 var acorda: Vector2i=t.celulas("@")[0]
 var livre:=andar_livre(t,acorda)
 var vaza: Array=[]
 for v in livre:
  if t.chv(v)==" ": vaza.append(v)
 print("VAZAMENTOS ",vaza.slice(0,10))
 check(vaza.is_empty(),"térreo fechado: não se sai para fora do mapa")
 # Todas as salas e áreas do térreo são alcançáveis a pé de onde Miguel acorda.
 var sem_acesso: Array=[]
 for k in t.salas.keys()+t.areas.keys():
  var v: Vector2i=t.celulas(k)[0]
  if not livre.has(v): sem_acesso.append(t.salas.get(k,t.areas.get(k,k)))
 # Área de saída e quadra contam: são caminho de fuga/esconderijo.
 print("SEM_ACESSO ",sem_acesso)
 check(sem_acesso.is_empty(),"todas as salas e áreas do térreo são alcançáveis")
 check(livre.has(t.celulas("+")[0]) and livre.has(t.celulas("*")[0]),"pé da escada e ritual no mesmo térreo andável")
 # Escada: uma, sobe para o patamar do andar de cima.
 var escadas: Array=t.escadas()
 check(escadas.size()==1,"uma escada no térreo")
 if escadas.size()==1:
  var e: Dictionary=escadas[0]
  var r: Rect2i=e["rect"]; var sobe: Vector2i=e["sobe"]
  var topo: Vector2i=(r.position if (sobe.x<0 or sobe.y<0) else r.end-Vector2i.ONE)+sobe
  check(u.ch(topo.x,topo.y)=="." and t.ch(topo.x,topo.y)==" ","topo da escada chega ao patamar (piso em cima, vão embaixo)")
  var vao: bool=true
  for rr in range(r.position.y,r.end.y):
   for cc in range(r.position.x,r.end.x):
    if u.ch(cc,rr)!=" ": vao=false
  check(vao,"sobre a escada o andar de cima é vão (sem laje na cabeça)")
 # Kit: peças pedidas existem, 2 m de comprimento, pivô na base.
 var lib: MeshLibrary=KIT.construir()
 var pedidas:=["parede","porta","janela","parede_canto","coluna","piso_azulejo","piso_cimento","meia_parede","telhado","degrau"]
 var ausentes: Array=[]
 for nome in pedidas:
  if lib.find_item_by_name(nome)<0: ausentes.append(nome)
 check(ausentes.is_empty(),"kit tem parede, porta, janela gradeada, canto, coluna, pisos, meia-parede, telhado e degrau")
 var fora: Array=[]
 for nome in ["parede","porta","janela","meia_parede","vao","grade","piso_azulejo","piso_cimento","telhado","degrau"]:
  var aabb: AABB=lib.get_item_mesh(lib.find_item_by_name(nome)).get_aabb()
  if absf(aabb.size.x-2.0)>.01: fora.append([nome,aabb.size.x])
 for nome in ["parede","porta","janela","coluna","meia_parede","degrau","bloco_baixo"]:
  var aabb: AABB=lib.get_item_mesh(lib.find_item_by_name(nome)).get_aabb()
  if absf(aabb.position.y)>.001: fora.append([nome,"base",aabb.position.y])
 print("KIT_FORA_DO_MODULO ",fora)
 check(fora.is_empty(),"peças de 2 m com pivô na base")
 var salvo=load("res://capitulo1/mapa/kit_blockout.meshlib")
 check(salvo is MeshLibrary and salvo.get_item_list().size()==lib.get_item_list().size(),"MeshLibrary salva em dia (tools/gerar_kit.gd)")
 # Física montada pelo jogo coincide com o texto.
 var game=load("res://capitulo1/main.tscn").instantiate()
 root.add_child(game)
 for i in 3: await physics_frame
 var s=game.school
 check(s.avisos.is_empty(),"montagem sem avisos do mapa")
 var space=game.get_world_3d().direct_space_state
 var parede_oca: Array=[]; var piso_cheio: Array=[]
 for n in 2:
  var g=s.andares[n]
  for r in g.altura:
   for c in g.largura:
    var ch: String=g.ch(c,r)
    if ch!="#" and ch!=".": continue
    var q:=PhysicsPointQueryParameters3D.new()
    q.collision_mask=1
    q.position=s.cel(c,r,n*s.LEVEL+1.5)
    var cheio: bool=not space.intersect_point(q).is_empty()
    if ch=="#" and not cheio: parede_oca.append(Vector3i(c,r,n))
    if ch=="." and cheio:
     # Armário/mesa da bolsa encostados podem ocupar a célula.
     var objeto:=false
     for h in s.hides:
      if Vector2(h["inside"].x,h["inside"].z).distance_to(Vector2(q.position.x,q.position.z))<1.2: objeto=true
     if not objeto: piso_cheio.append(Vector3i(c,r,n))
 print("PAREDE_SEM_COLISAO ",parede_oca.slice(0,10)," PISO_COM_COLISAO ",piso_cheio.slice(0,10))
 check(parede_oca.is_empty(),"toda célula # tem colisão")
 check(piso_cheio.is_empty(),"célula de piso . fica livre a 1,5 m")
 # Cada peça visual saiu do kit (sem caixa avulsa no lugar das paredes).
 var celulas: int=s.mapa.get_used_cells().size()+s.pisos.get_used_cells().size()+s.telhados.get_used_cells().size()
 print("GRIDMAP celulas=",celulas," colisores=",s.solidos)
 check(celulas>1000 and s.solidos<600,"geometria do kit no GridMap e colisão mesclada")
 print("CAPITULO1_MAPA: %d passed, %d failed"%[passed,failed])
 game.queue_free(); await process_frame
 quit(1 if failed else 0)
