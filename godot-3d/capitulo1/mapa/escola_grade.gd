extends "res://prototipo/school.gd"
## Escola do capítulo 1 montada a partir das grades em texto
## (capitulo1/mapa/terreo.txt e superior.txt, 1 caractere = 1 m) com o kit
## modular (kit.gd) num GridMap. Estado atual: BLOQUEIO CINZA para aprovação de
## Felipe; materiais e objetos de decoração só depois de aprovado.
##
## Visual: GridMap (peças do kit). Colisão: caixas mescladas geradas da mesma
## grade (a IA monta a grade de rotas a partir de caixas; poucas caixas longas
## custam menos que uma forma por célula).
const GRADE=preload("res://capitulo1/mapa/grade.gd")
const KIT=preload("res://capitulo1/mapa/kit.gd")
const NIVEL=preload("res://capitulo1/nivel.gd")
const ARQUIVOS:=["res://capitulo1/mapa/terreo.txt","res://capitulo1/mapa/superior.txt"]
const LEVEL:=KIT.ALTURA
## Compatibilidade com p() (pixels do desenho de Felipe, 0,12 m/px).
const SCALE:=.12
## Célula (c, r) ocupa x ∈ [c-53, c-52], z ∈ [r-36, r-35]. Mantém o mundo no
## mesmo lugar do desenho anterior (p() continua apontando perto do mesmo ponto).
const ORIGEM:=Vector3(-53,0,-36)
const DIRECOES:=[Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1)]

var andares: Array=[]
## Três GridMaps com o mesmo kit: o GridMap guarda UMA peça por célula, então
## piso, estrutura (paredes/volumes) e telhado não podem dividir o mesmo mapa
## (a parede apagaria a placa de piso 2×2 que começa na célula dela).
var mapa: GridMap
var pisos: GridMap
var telhados: GridMap
var lib: MeshLibrary
var rooms: Dictionary={}
var ambiente_celula: Array[Dictionary]=[{},{}]
var postos: Array[Vector3]=[]
var pursuer_post:=Vector3.ZERO
var bag: Node3D
var ritual_center: Vector3
var bag_at: Vector3
var spawn: Vector3
var gate_at: Vector3
var stairs_bottom: Vector3
var stairs_top: Vector3
var ritual_approach: Vector3
var first_cultist: Vector3
var escada: Dictionary={}
var ritual_figures: Array[Node3D]=[]
var fixtures: Array[Node3D]=[]
var hawk: Node3D
var flicker: OmniLight3D
var avisos: PackedStringArray=[]
var solidos:=0

## Ponto da grade -> mundo (centro da célula). Aceita frações.
func cel(c: float,r: float,y:=0.0) -> Vector3:
 return Vector3(c+.5+ORIGEM.x,y,r+.5+ORIGEM.z)

func celula_de(pos: Vector3) -> Vector2i:
 return Vector2i(floori(pos.x-ORIGEM.x),floori(pos.z-ORIGEM.z))

func andar_de(pos: Vector3) -> int:
 return 1 if pos.y>LEVEL*.75 else 0

func ambiente_de(pos: Vector3) -> String:
 return ambiente_celula[andar_de(pos)].get(celula_de(pos),"")

## Retângulo do mundo coberto pela grade (x, z).
func limites() -> Rect2:
 var w:=0; var h:=0
 for g in andares: w=maxi(w,g.largura); h=maxi(h,g.altura)
 return Rect2(ORIGEM.x,ORIGEM.z,w,h)

func p(x: float,z: float,y:=0.0) -> Vector3:
 return Vector3((x-440)*SCALE,y,(z-300)*SCALE)

func box(size: Vector3,at: Vector3,kind: String,solid:=true) -> Node3D:
 var node=super.box(size,at,kind,solid)
 node.set_meta("kind",kind)
 return node

func build(owner_game: Node3D) -> void:
 game=owner_game
 for data in [["wall",Color(.62,.62,.6)],["metal",Color(.33,.34,.36)],["wood",Color(.44,.40,.35)],
  ["dark",Color(.05,.06,.07)],["paper",Color(.70,.68,.60)],["red",Color(.42,.02,.03)],
  ["tile",Color(.5,.5,.5)],["floor",Color(.36,.36,.35)]]:
  mats[data[0]]=material(data[1])
 for caminho in ARQUIVOS:
  var g=GRADE.ler(caminho)
  andares.append(g)
  for e in g.erros: _aviso(e)
 lib=KIT.construir()
 mapa=GridMap.new()
 mapa.name="MapaGrade"
 mapa.mesh_library=lib
 mapa.cell_size=Vector3(1,LEVEL,1)
 mapa.cell_center_y=false
 mapa.position=ORIGEM
 # Colisão do jogo vem de _colisoes(); a do kit fica para o editor.
 mapa.collision_layer=0
 mapa.collision_mask=0
 add_child(mapa)
 pisos=mapa.duplicate()
 pisos.name="Pisos"
 add_child(pisos)
 telhados=mapa.duplicate()
 telhados.name="Telhados"
 add_child(telhados)
 for n in andares.size(): _pisos(n); _paredes(n); _volumes(n)
 _telhados()
 _mesclar_visual()
 _colisoes()
 _escada()
 _ambientes()
 _marcas()
 _ritual()
 _itens()
 _environment()
 var env: Environment=find_children("*","WorldEnvironment",true,false)[0].environment
 # Mesma base escura do capítulo (terror); o cinza do bloqueio lê melhor
 # com um pouco mais de ambiente.
 env.ambient_light_color=Color(.38,.42,.52)
 env.ambient_light_energy=.42
 env.fog_enabled=true
 env.fog_light_color=Color(.018,.022,.032)
 env.fog_light_energy=1.0
 env.fog_density=.06
 env.fog_sky_affect=.85
 env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 for light in find_children("*","DirectionalLight3D",true,false): light.light_energy=.2
 limitar_alcance()
 for a in avisos: push_warning("MAPA: "+a)

## Desempenho (web): o GridMap desenha cada tipo de peça em cada octante
## separado (~1000 desenhos e 23 mil comandos WebGL por quadro, medido no
## Chrome). Aqui as peças viram poucas malhas grandes por região de 16 m e
## material. Os GridMaps continuam com os dados (testes/editor), só invisíveis.
const BLOCO_VISUAL:=16.0
var visual_mesclado: Node3D
func _mesclar_visual() -> void:
 visual_mesclado=Node3D.new();visual_mesclado.name="VisualMesclado";add_child(visual_mesclado)
 var grupos:={}
 for gm in [mapa,pisos,telhados]:
  for cell in gm.get_used_cells():
   var item=gm.get_cell_item(cell)
   var mesh: Mesh=gm.mesh_library.get_item_mesh(item)
   if mesh==null: continue
   var base=gm.get_basis_with_orthogonal_index(gm.get_cell_item_orientation(cell))
   var xf: Transform3D=gm.transform*Transform3D(base,gm.map_to_local(cell))*gm.mesh_library.get_item_mesh_transform(item)
   var bloco=Vector2i(floori(xf.origin.x/BLOCO_VISUAL),floori(xf.origin.z/BLOCO_VISUAL))
   for i in mesh.get_surface_count():
    var mat=mesh.surface_get_material(i)
    var chave=[bloco,mat]
    if not grupos.has(chave):
     var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_material(mat);grupos[chave]=st
    grupos[chave].append_from(mesh,i,xf)
 for chave in grupos:
  var mi=MeshInstance3D.new();mi.mesh=grupos[chave].commit()
  visual_mesclado.add_child(mi)
 for gm in [mapa,pisos,telhados]: gm.visible=false

## Objetos soltos (móveis, placas, portas) somem além de 30 m: a neblina já
## esconde, mas o navegador os desenhava todos a cada quadro.
const ALCANCE_OBJETOS:=30.0
func limitar_alcance() -> void:
 for m in find_children("*","GeometryInstance3D",true,false):
  if m.get_parent()==visual_mesclado or m is GridMap: continue
  m.visibility_range_end=ALCANCE_OBJETOS
  m.visibility_range_end_margin=2.0

func _aviso(texto: String) -> void:
 avisos.append(texto)

# --------------------------------------------------------------------------- visual

func _orientacao(rot: int) -> int:
 return mapa.get_orthogonal_index_from_basis(Basis(Vector3.UP,-rot*PI/2))

func _por(n: int,c: int,r: int,peca: String,rot:=0) -> void:
 var alvo: GridMap=telhados if peca.begins_with("telhado") else (pisos if peca.begins_with("piso_") else mapa)
 alvo.set_cell_item(Vector3i(c,n,r),KIT.item(lib,peca),_orientacao(rot))

const PISO_PECA:={".":"piso_azulejo",",":"piso_cimento",";":"piso_cimento",":":"piso_quadra","_":"piso_azulejo"}

## Pisos em placas de 2×2 m; 1×1 só onde a placa não cabe.
func _pisos(n: int) -> void:
 var g=andares[n]
 var tipo: Dictionary={}
 for r in g.altura:
  for c in g.largura:
   if g.e_vazio(c,r): continue
   tipo[Vector2i(c,r)]=PISO_PECA.get(g.piso(c,r),"piso_cimento")
 _placas(n,tipo,"")

## Preenche com peça de 2×2 quando as quatro células têm o mesmo valor.
func _placas(n: int,tipo: Dictionary,sufixo_1m: String) -> void:
 var feito: Dictionary={}
 var chaves: Array=tipo.keys()
 chaves.sort_custom(func(a,b): return a.y<b.y or (a.y==b.y and a.x<b.x))
 for v in chaves:
  if feito.has(v): continue
  var peca: String=tipo[v]
  var quatro:=[v,v+Vector2i(1,0),v+Vector2i(0,1),v+Vector2i(1,1)]
  var cabe:=true
  for q in quatro:
   if feito.has(q) or tipo.get(q,"")!=peca: cabe=false; break
  if cabe:
   for q in quatro: feito[q]=true
   _por(n,v.x,v.y,peca)
  else:
   feito[v]=true
   _por(n,v.x,v.y,peca+"_1m")

## Rotação (passos de -90°) que leva o conjunto-base de braços ao conjunto pedido.
func _giro(base: Array,bracos: Array) -> int:
 for k in 4:
  var girado: Array=[]
  for d in base:
   var v: Vector2i=d
   for i in k: v=Vector2i(-v.y,v.x)
   girado.append(v)
  var igual:=girado.size()==bracos.size()
  for d in bracos:
   if not d in girado: igual=false
  if igual: return k
 return 0

func _paredes(n: int) -> void:
 var g=andares[n]
 # Retas (# e -) em módulos de 2 m; cantos, pontas, T e cruz por célula.
 for simbolo in ["#","-"]:
  var prefixo:="parede" if simbolo=="#" else "meia_parede"
  var reta_x: Dictionary={}; var reta_z: Dictionary={}
  for v in g.celulas(simbolo):
   var b: Array=g.bracos(v.x,v.y)
   var e:=Vector2i(1,0) in b; var w:=Vector2i(-1,0) in b
   var s:=Vector2i(0,1) in b; var nn:=Vector2i(0,-1) in b
   if b.size()==2 and e and w: reta_x[v]=true; continue
   if b.size()==2 and s and nn: reta_z[v]=true; continue
   match b.size():
    0: _por(n,v.x,v.y,prefixo+"_poste")
    1: _por(n,v.x,v.y,prefixo+"_ponta",_giro([Vector2i(1,0)],b))
    2: _por(n,v.x,v.y,prefixo+"_canto",_giro([Vector2i(1,0),Vector2i(0,1)],b))
    3: _por(n,v.x,v.y,prefixo+"_t",_giro([Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1)],b))
    _: _por(n,v.x,v.y,prefixo+"_cruz")
  _modulos(n,reta_x,Vector2i(1,0),prefixo,prefixo+"_1m")
  _modulos(n,reta_z,Vector2i(0,1),prefixo,prefixo+"_1m")
 # Portas, janelas, vãos e portões: peças retas ao longo do eixo.
 var nomes:={"D":["porta",""],"W":["janela","janela_1m"],"O":["vao","vao_1m"],"G":["grade","grade_1m"]}
 for simbolo in nomes:
  for seq in g.sequencias(simbolo):
   var passo:=Vector2i(1,0) if seq["eixo"]=="x" else Vector2i(0,1)
   var rot:=0 if seq["eixo"]=="x" else 1
   var i:=0
   if simbolo=="D" and seq["n"]!=2:
    _aviso("porta em %s com %d células (use DD)"%[seq["inicio"],seq["n"]])
   while i<seq["n"]:
    var v: Vector2i=seq["inicio"]+passo*i
    if seq["n"]-i>=2:
     _por(n,v.x,v.y,nomes[simbolo][0],rot); i+=2
    else:
     _por(n,v.x,v.y,nomes[simbolo][1] if nomes[simbolo][1]!="" else "parede_1m",rot); i+=1

## Sequências retas em peças de 2 m; sobra ímpar em 1 m.
func _modulos(n: int,celulas: Dictionary,passo: Vector2i,peca2: String,peca1: String) -> void:
 var rot:=0 if passo.x==1 else 1
 var feito: Dictionary={}
 var chaves: Array=celulas.keys()
 chaves.sort_custom(func(a,b): return a.y<b.y or (a.y==b.y and a.x<b.x))
 for v in chaves:
  if feito.has(v): continue
  if celulas.has(v+passo) and not feito.has(v+passo):
   feito[v]=true; feito[v+passo]=true
   _por(n,v.x,v.y,peca2,rot)
  else:
   feito[v]=true
   _por(n,v.x,v.y,peca1,rot)

func _volumes(n: int) -> void:
 var g=andares[n]
 for v in g.celulas("C"): _por(n,v.x,v.y,"coluna")
 for v in g.celulas("%"): _por(n,v.x,v.y,"bloco_baixo")
 for v in g.celulas("_"): _por(n,v.x,v.y,"palco")
 for v in g.celulas("="): _por(n,v.x,v.y,"relevo")
 for v in g.celulas("T"): _por(n,v.x,v.y,"arvore")

## Coberturas: salas e varandas a 3,4 m (onde não há andar de cima); quadra,
## caixa da escada e andar de cima a 6,8 m.
func _telhados() -> void:
 var t=andares[0]; var u=andares[1]
 var baixo: Dictionary={}; var alto: Dictionary={}
 for r in t.altura:
  for c in t.largura:
   if t.e_vazio(c,r): continue
   var v:=Vector2i(c,r)
   var cob:=_cobertura(t,c,r)
   if t.e_escada(c,r) or cob==":": alto[v]="telhado"
   elif cob!="" and u.e_vazio(c,r): baixo[v]="telhado"
 for r in u.altura:
  for c in u.largura:
   if not u.e_vazio(c,r): alto[Vector2i(c,r)]="telhado"
 _placas(1,baixo,"")
 _placas(2,alto,"")
 telhado_celulas=[baixo,alto]

var telhado_celulas: Array=[{},{}]

## "." ou ";" = coberto a 3,4 m; ":" = quadra (alto); "" = céu aberto.
func _cobertura(g,c: int,r: int) -> String:
 if g.e_parede(c,r) or not g.ch(c,r) in GRADE.PISOS:
  var achou:=""
  for d in DIRECOES:
   var n: Vector2i=Vector2i(c,r)+d
   if g.e_vazio(n.x,n.y) or g.e_parede(n.x,n.y): continue
   var pz: String=g.piso(n.x,n.y)
   if pz in ".;": return "."
   if pz==":": achou=":"
  if g.e_parede(c,r): return achou
  var proprio: String=g.piso(c,r)
  return proprio if proprio in ".;:" else achou
 var s: String=g.ch(c,r)
 if s=="_": return "."
 return s if s in ".;:" else ""

# --------------------------------------------------------------------------- colisão

## Caixa sólida sem visual (o visual é do GridMap). Mínimo/máximo no mundo.
func _solido(a: Vector3,b: Vector3,nome:="Parede") -> StaticBody3D:
 var body:=StaticBody3D.new()
 body.name=nome
 body.collision_layer=1
 body.collision_mask=2
 body.position=(a+b)*.5
 add_child(body)
 var cs:=CollisionShape3D.new()
 var shape:=BoxShape3D.new()
 shape.size=(b-a).abs()
 cs.shape=shape
 body.add_child(cs)
 solidos+=1
 return body

## Caixas de parede em coordenadas da grade (x, z) e altura (y), mescladas.
func _colisoes() -> void:
 var area:=limites()
 _solido(Vector3(area.position.x-2,-.3,area.position.y-2),Vector3(area.end.x+2,0,area.end.y+2),"Chao")
 var t:=KIT.ESPESSURA*.5
 for n in andares.size():
  var g=andares[n]
  var y0:=n*LEVEL
  var caixas: Array=[]
  for simbolo in ["#","-"]:
   var alto:=LEVEL if simbolo=="#" else KIT.MEIA
   for v in g.celulas(simbolo):
    var cx: float=v.x+.5; var cz: float=v.y+.5
    var b: Array=g.bracos(v.x,v.y)
    caixas.append([cx-t,cx+t,cz-t,cz+t,0.0,alto])
    for d in b:
     if d.x!=0: caixas.append([minf(cx,cx+d.x*.5)-(t if d.x<0 else 0.0),maxf(cx,cx+d.x*.5)+(t if d.x>0 else 0.0),cz-t,cz+t,0.0,alto])
     else: caixas.append([cx-t,cx+t,minf(cz,cz+d.y*.5),maxf(cz,cz+d.y*.5),0.0,alto])
  # Faixas de altura por tipo de peça reta (portas recebem batentes à parte).
  var perfil:={"W":[[0.0,KIT.PEITORIL],[KIT.VERGA_VAO,LEVEL]],"O":[[KIT.VERGA_VAO,LEVEL]],"D":[[KIT.VERGA_PORTA,LEVEL]]}
  for simbolo in perfil:
   for seq in g.sequencias(simbolo):
    for i in seq["n"]:
     var v: Vector2i=seq["inicio"]+(Vector2i(i,0) if seq["eixo"]=="x" else Vector2i(0,i))
     for faixa in perfil[simbolo]:
      if seq["eixo"]=="x": caixas.append([v.x,v.x+1.0,v.y+.5-t,v.y+.5+t,faixa[0],faixa[1]])
      else: caixas.append([v.x+.5-t,v.x+.5+t,v.y,v.y+1.0,faixa[0],faixa[1]])
    if simbolo=="D":
     var b: float=(seq["n"]-KIT.VAO_PORTA)*.5
     var a: Vector2i=seq["inicio"]
     if seq["eixo"]=="x":
      caixas.append([a.x,a.x+b,a.y+.5-t,a.y+.5+t,0.0,KIT.VERGA_PORTA])
      caixas.append([a.x+seq["n"]-b,a.x+seq["n"],a.y+.5-t,a.y+.5+t,0.0,KIT.VERGA_PORTA])
     else:
      caixas.append([a.x+.5-t,a.x+.5+t,a.y,a.y+b,0.0,KIT.VERGA_PORTA])
      caixas.append([a.x+.5-t,a.x+.5+t,a.y+seq["n"]-b,a.y+seq["n"],0.0,KIT.VERGA_PORTA])
  for caixa in _mesclar(caixas):
   _solido(Vector3(caixa[0]+ORIGEM.x,caixa[4]+y0,caixa[2]+ORIGEM.z),Vector3(caixa[1]+ORIGEM.x,caixa[5]+y0,caixa[3]+ORIGEM.z))
  # Volumes baixos e colunas.
  for rect in g.retangulos(func(c,r): return g.ch(c,r)=="%"):
   _solido(_canto(rect.position,y0),_canto(rect.end,y0+KIT.BLOCO),"Bloco")
  for rect in g.retangulos(func(c,r): return g.ch(c,r)=="_"):
   _solido(_canto(rect.position,y0),_canto(rect.end,y0+KIT.PALCO),"Palco")
  # Relevo: 8 cm, a cápsula passa por cima (a grade de rotas o ignora).
  for rect in g.retangulos(func(c,r): return g.ch(c,r)=="="):
   _solido(_canto(rect.position,y0),_canto(rect.end,y0+KIT.RELEVO),"Relevo")
  for v in g.celulas("C"):
   _solido(cel(v.x,v.y,y0)-Vector3(.2,0,.2),cel(v.x,v.y,y0+LEVEL)+Vector3(.2,0,.2),"Coluna")
  for v in g.celulas("T"):
   _solido(cel(v.x,v.y,y0)-Vector3(.35,0,.35),cel(v.x,v.y,y0+4.2)+Vector3(.35,0,.35),"Arvore")
 # Laje do andar de cima (piso e teto do térreo).
 var u=andares[1]
 for rect in u.retangulos(func(c,r): return not u.e_vazio(c,r)):
  _solido(_canto(rect.position,LEVEL-.1),_canto(rect.end,LEVEL),"Laje")
 # Telhados também bloqueiam a visão.
 for nivel in 2:
  var cel_tel: Dictionary=telhado_celulas[nivel]
  var g2=andares[0]
  for rect in g2.retangulos(func(c,r): return cel_tel.has(Vector2i(c,r))):
   var y:=(nivel+1)*LEVEL
   _solido(_canto(rect.position,y-.15),_canto(rect.end,y),"Telhado")

func _canto(v: Vector2i,y: float) -> Vector3:
 return Vector3(v.x+ORIGEM.x,y,v.y+ORIGEM.z)

## Junta caixas vizinhas de mesma seção (primeiro em x, depois em z).
func _mesclar(caixas: Array) -> Array:
 var out:=caixas
 for eixo in [0,2]:
  var outro:=2 if eixo==0 else 0
  out.sort_custom(func(a,b):
   for k in [outro,outro+1,4,5,eixo]:
    if absf(a[k]-b[k])>.001: return a[k]<b[k]
   return false)
  var junto: Array=[]
  for caixa in out:
   if not junto.is_empty():
    var u: Array=junto.back()
    if absf(u[outro]-caixa[outro])<.001 and absf(u[outro+1]-caixa[outro+1])<.001 and absf(u[4]-caixa[4])<.001 and absf(u[5]-caixa[5])<.001 and caixa[eixo]<=u[eixo+1]+.001:
     u[eixo+1]=maxf(u[eixo+1],caixa[eixo+1]); continue
   junto.append(caixa.duplicate())
  out=junto
 return out

# --------------------------------------------------------------------------- escada

## Rampa física contínua sob degraus visuais (não prende a cápsula nas quinas).
func _escada() -> void:
 var lista: Array=andares[0].escadas()
 if lista.size()!=1:
  _aviso("o térreo precisa de exatamente uma escada (tem %d)"%lista.size())
  if lista.is_empty(): return
 escada=lista[0]
 var rect: Rect2i=escada["rect"]
 var sobe: Vector2i=escada["sobe"]
 var ao_longo:=Vector3(sobe.x,0,sobe.y)
 var lado:=Vector3(absf(sobe.y),0,absf(sobe.x))
 var comprimento:=float(rect.size.x if sobe.x!=0 else rect.size.y)
 var largura:=float(rect.size.y if sobe.x!=0 else rect.size.x)
 var centro:=Vector3(rect.position.x+rect.size.x*.5+ORIGEM.x,0,rect.position.y+rect.size.y*.5+ORIGEM.z)
 stairs_bottom=centro-ao_longo*comprimento*.5
 stairs_top=centro+ao_longo*comprimento*.5+Vector3.UP*LEVEL
 # A rampa encosta nas faces das paredes laterais (0,4 m dentro de cada célula de parede).
 var meia:=largura*.5+.4
 var a:=stairs_bottom-lado*meia; var b:=stairs_bottom+lado*meia
 var c:=stairs_top+lado*meia; var d:=stairs_top-lado*meia
 var body:=StaticBody3D.new()
 body.name="Escada"
 body.collision_layer=1; body.collision_mask=2
 add_child(body)
 var cs:=CollisionShape3D.new()
 var rampa:=ConcavePolygonShape3D.new()
 rampa.set_faces(PackedVector3Array([a,c,d,a,b,c]))
 rampa.backface_collision=true
 cs.shape=rampa
 body.add_child(cs)
 # Degraus do kit empilhados (20 degraus de 17 cm).
 var degraus:=int(round(LEVEL/KIT.DEGRAU_ALTURA))
 var piso:=comprimento/degraus
 var giro:=Basis(Vector3.UP,atan2(ao_longo.x,ao_longo.z))
 var malha: Mesh=lib.get_item_mesh(KIT.item(lib,"degrau"))
 for i in degraus:
  var m:=MeshInstance3D.new()
  m.mesh=malha
  m.transform=Transform3D(giro*Basis.from_scale(Vector3(largura/2.0,(i+1)*LEVEL/degraus/KIT.DEGRAU_ALTURA,piso/KIT.DEGRAU_PISO)),stairs_bottom+ao_longo*piso*i)
  add_child(m)

## Sombra da caixa da escada (onde Miguel espia o ritual): dentro da caixa e no vão.
func na_sombra_da_escada(pos: Vector3) -> bool:
 if escada.is_empty() or andar_de(pos)!=0: return false
 var rect: Rect2i=escada["rect"]
 var sobe: Vector2i=escada["sobe"]
 var zona:=rect.grow(1)
 # Estende 2 células para o lado de baixo (a entrada).
 if sobe.x<0: zona=zona.grow_individual(0,0,2,0)
 elif sobe.x>0: zona=zona.grow_individual(2,0,0,0)
 elif sobe.y<0: zona=zona.grow_individual(0,0,0,2)
 else: zona=zona.grow_individual(0,2,0,0)
 return zona.has_point(celula_de(pos))

# --------------------------------------------------------------------------- salas e portas

func _ambientes() -> void:
 for n in andares.size():
  var g=andares[n]
  var y:=n*LEVEL
  var rotulos: Dictionary=g.salas.duplicate()
  rotulos.merge(g.areas)
  for letra in rotulos:
   var onde: Array=g.celulas(letra)
   if onde.size()!=1:
    _aviso("%s: a letra %s aparece %d vezes"%[rotulos[letra],letra,onde.size()]); continue
   var regiao: Array=g.regiao(onde[0])
   var lo: Vector2i=onde[0]; var hi: Vector2i=onde[0]
   for v in regiao:
    lo=Vector2i(mini(lo.x,v.x),mini(lo.y,v.y)); hi=Vector2i(maxi(hi.x,v.x),maxi(hi.y,v.y))
    if not ambiente_celula[n].has(v) or g.salas.has(letra): ambiente_celula[n][v]=rotulos[letra]
   var rect:=Rect2(Vector2(lo),Vector2(hi-lo+Vector2i.ONE))
   rooms[rotulos[letra]]={"rect":rect,"floor":y,"center":Vector3(rect.get_center().x+ORIGEM.x,y,rect.get_center().y+ORIGEM.z),
    "celulas":regiao.size(),"andar":n,"sala":g.salas.has(letra),"rotulo":cel(onde[0].x,onde[0].y,y)}
   if g.salas.has(letra):
    _lamp(Vector3(rect.get_center().x+ORIGEM.x,y+2.9,rect.get_center().y+ORIGEM.z),Color(.98,.80,.49),4.5,.75)
  for seq in g.sequencias("D"): _porta(n,seq)

func _porta(n: int,seq: Dictionary) -> void:
 var g=andares[n]
 var a: Vector2i=seq["inicio"]
 var meio: Vector3
 var lados: Array
 if seq["eixo"]=="x":
  meio=Vector3(a.x+seq["n"]*.5,0,a.y+.5)
  lados=[[Vector2i(a.x,a.y+1),Vector3.FORWARD],[Vector2i(a.x,a.y-1),Vector3.BACK]]
 else:
  meio=Vector3(a.x+.5,0,a.y+seq["n"]*.5)
  lados=[[Vector2i(a.x+1,a.y),Vector3.LEFT],[Vector2i(a.x-1,a.y),Vector3.RIGHT]]
 # Normal aponta para fora da sala (a folha abre para dentro dela).
 var titulo:="Porta"
 var normal: Vector3=lados[1][1]
 for lado in lados:
  var nome: String=ambiente_celula[n].get(lado[0],"")
  if nome!="" and rooms.has(nome) and rooms[nome]["sala"]:
   titulo=nome; normal=lado[1]; break
 var at:=Vector3(meio.x+ORIGEM.x,n*LEVEL,meio.z+ORIGEM.z)
 var door=load("res://capitulo1/porta_som.gd").new()
 add_child(door)
 door.width=KIT.VAO_PORTA-.06
 door.setup(game,at,normal,titulo)
 door.swing=1.65
 doors.append(door)
 sign_at(titulo,at+Vector3.UP*2.6+normal*.13,rad_to_deg(atan2(normal.x,normal.z)))

# --------------------------------------------------------------------------- marcas da história

func _marcas() -> void:
 var postos_por_numero: Dictionary={}
 for n in andares.size():
  var g=andares[n]
  var y:=n*LEVEL
  for v in g.celulas("@"): spawn=cel(v.x,v.y,y)
  for v in g.celulas("*"): ritual_center=cel(v.x,v.y,y)
  for v in g.celulas("+"): ritual_approach=cel(v.x,v.y,y)
  for v in g.celulas("1234567"): postos_por_numero[int(g.ch(v.x,v.y))]=cel(v.x,v.y,y)
  for v in g.celulas("8"): pursuer_post=cel(v.x,v.y,y)
  for v in g.celulas("$"):
   var mesa:=cel(v.x,v.y,y)
   box(Vector3(1.2,.85,.65),mesa+Vector3.UP*.425,"wood")
   bag_at=mesa+Vector3.UP*1.01
   bag=box(Vector3(.42,.32,.30),bag_at,"dark",false)
   var alca=box(Vector3(.15,.05,.12),bag_at+Vector3(0,.19,0),"metal",false)
   alca.reparent(bag)
  for v in g.celulas("&"): _armario(g,v,y)
  for v in g.celulas("L"): _lamp(cel(v.x,v.y,y+2.9),Color(.95,.78,.5),6,.7)
  for seq in g.sequencias("G"):
   var a: Vector2i=seq["inicio"]
   var largura: float=seq["n"]
   var eixo_x: bool=seq["eixo"]=="x"
   gate_at=Vector3(a.x+(largura*.5 if eixo_x else .5)+ORIGEM.x,y,a.y+(.5 if eixo_x else largura*.5)+ORIGEM.z)
   gate=_solido(gate_at-Vector3(largura*.5 if eixo_x else .07,0,.07 if eixo_x else largura*.5),gate_at+Vector3(largura*.5 if eixo_x else .07,KIT.GRADE,.07 if eixo_x else largura*.5),"Portao1")
   sign_at("PORTÃO 1",gate_at+Vector3(0,2.7,-.13))
 var numeros: Array=postos_por_numero.keys()
 numeros.sort()
 for k in numeros: postos.append(postos_por_numero[k])
 if not postos.is_empty(): first_cultist=postos[0]
 for nome in ["spawn","ritual_center","ritual_approach","bag_at","gate_at"]:
  if get(nome)==Vector3.ZERO: _aviso("marca ausente no mapa: "+nome)
 # Lâmpada que falha: a mais próxima do portão.
 var melhor:=INF
 for luz in find_children("*","OmniLight3D",true,false):
  var d: float=luz.global_position.distance_to(gate_at)
  if d<melhor: melhor=d; flicker=luz

## Armário encostado na parede vizinha, aberto para o lado livre.
## Armário do capítulo com folha móvel; mantém as medidas do modelo anterior.
func locker(at: Vector3,normal: Vector3) -> void:
 var cabinet=Node3D.new(); cabinet.position=at
 cabinet.rotation.y=atan2(normal.x,normal.z); add_child(cabinet)
 for part in [[Vector3(1,2.15,.1),Vector3(0,1.075,-.45)],
  [Vector3(.08,2.15,1),Vector3(-.5,1.075,0)],
  [Vector3(.08,2.15,1),Vector3(.5,1.075,0)],
  [Vector3(1,.08,1),Vector3(0,2.15,0)]]:
  var node=box(part[0],Vector3.ZERO,"metal")
  remove_child(node); cabinet.add_child(node); node.position=part[1]
 var hinge=Node3D.new(); cabinet.add_child(hinge); hinge.position=Vector3(-.5,0,.48)
 for part in [[Vector3(1,.65,.08),Vector3(.5,1.8,0)],
  [Vector3(1,1,.08),Vector3(.5,.5,0)]]:
  var node=box(part[0],Vector3.ZERO,"metal")
  remove_child(node); hinge.add_child(node); node.position=part[1]
 hides.append({"inside":at,"entry":at+normal*.95,"normal":normal,"hinge":hinge,"opened":false})

func set_hide_open(index: int,on: bool,instant:=false) -> void:
 var spot: Dictionary=hides[index]
 if spot.get("opened",false)==on and not instant: return
 spot["opened"]=on
 if not instant and game.sound!=null: game.sound.emit_at("armario_abrir" if on else "armario_fechar",spot["entry"])
 if not spot.has("hinge"): return
 var hinge: Node3D=spot["hinge"]
 for body in hinge.find_children("*","StaticBody3D",true,false): body.collision_layer=0 if on else 1
 if spot.has("tween") and is_instance_valid(spot["tween"]): spot["tween"].kill()
 if instant: hinge.rotation.y=-1.8 if on else 0.0
 else:
  var tween=hinge.create_tween(); spot["tween"]=tween
  tween.tween_property(hinge,"rotation:y",-1.8 if on else 0.0,.22)

func _armario(g,v: Vector2i,y: float) -> void:
 var parede:=Vector2i.ZERO
 for d in DIRECOES:
  if g.e_parede(v.x+d.x,v.y+d.y): parede=d; break
 if parede==Vector2i.ZERO:
  _aviso("armário em %s sem parede ao lado"%v)
  parede=Vector2i(0,-1)
 var normal:=Vector3(-parede.x,0,-parede.y)
 locker(cel(v.x,v.y,y)-normal*.35,normal)

func _lamp(at: Vector3,color: Color,reach: float,energy: float) -> void:
 var bulb=box(Vector3(.6,.06,.16),at,"paper",false)
 var light=OmniLight3D.new()
 light.position=at-Vector3.UP*.15
 light.light_color=color
 light.omni_range=reach
 light.light_energy=energy
 light.shadow_enabled=false
 add_child(light)
 fixtures.append(bulb)

## Itens de jogo sobre blocos do mapa (posições em nivel.gd, em células).
func _itens() -> void:
 for item in NIVEL.ITENS:
  var at: Vector3=topo(item[1],item[2])
  pickup(item[0],at+Vector3.UP*.06)

## Topo da superfície de uma célula: bloco baixo, mesa da bolsa ou piso.
func topo(celula: Vector2,andar:=0) -> Vector3:
 var g=andares[andar]
 var s: String=g.ch(int(celula.x),int(celula.y))
 var y:=andar*LEVEL+(KIT.BLOCO if s=="%" else (.85 if s=="$" else (KIT.PALCO if s=="_" else 0.0)))
 return cel(celula.x,celula.y,y)

# --------------------------------------------------------------------------- ritual (elementos de jogo)

func _ritual() -> void:
 for i in 5:
  var a=ritual_center+Vector3(sin(i*TAU/5)*1.3,.018,cos(i*TAU/5)*1.3)
  var b=ritual_center+Vector3(sin((i+2)*TAU/5)*1.3,.018,cos((i+2)*TAU/5)*1.3)
  var line=box(Vector3(.055,.012,a.distance_to(b)),(a+b)*.5,"red",false)
  line.look_at(b)
 for i in 10:
  candle(ritual_center+Vector3(sin(i*TAU/10)*2.0,0,cos(i*TAU/10)*1.45),i%3==0)
 # Ave viva, pousada; nenhum destino/sacrifício presumido.
 var bird=Node3D.new()
 hawk=bird
 bird.position=ritual_center+Vector3.UP*.32
 add_child(bird)
 var body=MeshInstance3D.new()
 var mesh=SphereMesh.new()
 mesh.radius=.15; mesh.height=.40; mesh.radial_segments=10; mesh.rings=5
 body.mesh=mesh
 body.material_override=mats["wood"]
 bird.add_child(body)
 var head=box(Vector3(.17,.15,.18),bird.position+Vector3(0,.25,.04),"wood",false)
 var beak=box(Vector3(.08,.06,.14),head.position+Vector3(0,-.02,.13),"paper",false)
 for x in [-.075,.075]:
  var eye=box(Vector3(.025,.025,.025),head.position+Vector3(x,.02,.07),"dark",false)
  eye.reparent(bird)
 head.reparent(bird); beak.reparent(bird)

func sign_at(text: String,at: Vector3,yaw:=0.0) -> void:
 var label=Label3D.new()
 label.text=text
 label.position=at
 label.rotation_degrees.y=yaw
 label.font=load("res://prototipo/interface.ttf")
 label.font_size=32
 label.pixel_size=.004
 label.modulate=Color(.92,.92,.86)
 label.double_sided=false
 var normal=Vector3(sin(deg_to_rad(yaw)),0,cos(deg_to_rad(yaw)))
 var plate=box(Vector3(clampf(text.length()*.075,.7,3.6),.28,.025),at-normal*.018,"metal",false)
 plate.rotation_degrees.y=yaw
 add_child(label)

func open_exit() -> void:
 pass # Saída por transposição do portão, não abrindo-o.

func reset_exit() -> void:
 gate.collision_layer=1

func update(dt: float,time: float) -> void:
 super.update(dt,time)
 if hawk: hawk.rotation.y=.12*sin(time*.7)
 if flicker:
  var n=sin(time*13.1)+sin(time*7.3+1.7)+sin(time*2.9)
  flicker.light_energy=0.0 if n>2.1 else .9
