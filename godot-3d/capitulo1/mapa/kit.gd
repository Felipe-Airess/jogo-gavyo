extends RefCounted
## Kit modular do bloqueio cinza (blockout). Módulo de 2 m; peças de 1 m só
## completam sequências ímpares e cantos. Todas com pivô na base, no centro da
## primeira célula, e comprimento ao longo de +X (a grade gira a peça).
## Cada peça leva a própria colisão na MeshLibrary (para uso no editor); no
## jogo a colisão é gerada da mesma grade em caixas mescladas (escola_grade.gd).
##
## Regerar o recurso salvo: godot --headless --path godot-3d --script res://tools/gerar_kit.gd

const ALTURA:=3.4          # pé-direito = distância entre andares
const ESPESSURA:=.2
const MEIA:=1.1            # meia-parede / mureta
const VERGA_PORTA:=2.3
const VERGA_VAO:=2.1
const PEITORIL:=1.0
const VAO_PORTA:=1.56      # vão livre da porta de 2 m (métrica do level design)
const GRADE:=2.35
const BLOCO:=.9
const PALCO:=.35
const DEGRAU_ALTURA:=.17
const DEGRAU_PISO:=.3

## Cores do bloqueio: só cinzas (aprovação antes de decorar).
const CORES:={
 "parede":Color(.66,.66,.64),"meia":Color(.56,.56,.54),"porta":Color(.40,.40,.42),
 "janela":Color(.30,.31,.33),"grade":Color(.26,.27,.28),"coluna":Color(.60,.60,.58),
 "azulejo":Color(.52,.52,.52),"cimento":Color(.36,.36,.35),"quadra":Color(.44,.46,.45),
 "telhado":Color(.28,.28,.29),"degrau":Color(.58,.58,.56),"palco":Color(.47,.47,.47),
 "bloco":Color(.46,.44,.41),"tronco":Color(.30,.29,.28),"copa":Color(.38,.41,.38),
}

static var _materiais: Dictionary={}

static func material(nome: String) -> StandardMaterial3D:
 if _materiais.has(nome): return _materiais[nome]
 var cor: Color=CORES[nome]
 # Textura de protótipo: linha a cada 1 m (lê a escala nas capturas).
 var img:=Image.create(32,32,false,Image.FORMAT_RGB8)
 for y in 32:
  for x in 32:
   var linha:=x==0 or y==0
   var meio:=(x==16 or y==16) and nome in ["azulejo","quadra"]
   var k:=.72 if linha else (.86 if meio else 1.0)
   img.set_pixel(x,y,Color(cor.r*k,cor.g*k,cor.b*k))
 var mat:=StandardMaterial3D.new()
 mat.resource_name="blockout_"+nome
 mat.albedo_texture=ImageTexture.create_from_image(img)
 mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 mat.uv1_triplanar=true
 mat.uv1_world_triplanar=true
 mat.roughness=.95
 _materiais[nome]=mat
 return mat

## Peças: nome -> lista de [material, mínimo, máximo].
static func pecas() -> Dictionary:
 var h:=ALTURA; var t:=ESPESSURA*.5
 var p: Dictionary={}
 # Paredes retas (2 m e 1 m), ponta, canto, T, cruz e poste.
 p["parede"]=[["parede",Vector3(-.5,0,-t),Vector3(1.5,h,t)]]
 p["parede_1m"]=[["parede",Vector3(-.5,0,-t),Vector3(.5,h,t)]]
 p["parede_ponta"]=[["parede",Vector3(-t,0,-t),Vector3(.5,h,t)]]
 p["parede_canto"]=[["parede",Vector3(-t,0,-t),Vector3(.5,h,t)],["parede",Vector3(-t,0,t),Vector3(t,h,.5)]]
 p["parede_t"]=[["parede",Vector3(-.5,0,-t),Vector3(.5,h,t)],["parede",Vector3(-t,0,t),Vector3(t,h,.5)]]
 p["parede_cruz"]=[["parede",Vector3(-.5,0,-t),Vector3(.5,h,t)],["parede",Vector3(-t,0,-.5),Vector3(t,h,-t)],["parede",Vector3(-t,0,t),Vector3(t,h,.5)]]
 p["parede_poste"]=[["parede",Vector3(-t,0,-t),Vector3(t,h,t)]]
 # Meia-parede (mureta de azulejo), mesmas variações.
 for nome in ["","_1m","_ponta","_canto","_t","_cruz","_poste"]:
  var base: Array=p["parede"+nome]
  var meia: Array=[]
  for caixa in base: meia.append(["meia",caixa[1],Vector3(caixa[2].x,MEIA,caixa[2].z)])
  p["meia_parede"+nome]=meia
 # Porta de 2 m: batentes + verga; a folha é um objeto à parte (abre e fecha).
 var batente:=(2.0-VAO_PORTA)*.5
 p["porta"]=[["porta",Vector3(-.5,0,-t),Vector3(-.5+batente,h,t)],
  ["porta",Vector3(1.5-batente,0,-t),Vector3(1.5,h,t)],
  ["parede",Vector3(-.5+batente,VERGA_PORTA,-t),Vector3(1.5-batente,h,t)]]
 # Vão aberto com verga.
 p["vao"]=[["parede",Vector3(-.5,VERGA_VAO,-t),Vector3(1.5,h,t)]]
 p["vao_1m"]=[["parede",Vector3(-.5,VERGA_VAO,-t),Vector3(.5,h,t)]]
 # Janela gradeada: peitoril, verga e barras.
 for nome in ["janela","janela_1m"]:
  var fim:=1.5 if nome=="janela" else .5
  var caixas: Array=[["parede",Vector3(-.5,0,-t),Vector3(fim,PEITORIL,t)],["parede",Vector3(-.5,VERGA_VAO,-t),Vector3(fim,h,t)]]
  var x:=-.5+.15
  while x<fim-.05:
   caixas.append(["janela",Vector3(x-.015,PEITORIL,-.02),Vector3(x+.015,VERGA_VAO,.02)])
   x+=.15
  caixas.append(["janela",Vector3(-.5,1.55,-.02),Vector3(fim,1.58,.02)])
  p[nome]=caixas
 # Portão de grade.
 for nome in ["grade","grade_1m"]:
  var fim:=1.5 if nome=="grade" else .5
  var caixas: Array=[["grade",Vector3(-.5,.05,-.04),Vector3(fim,.13,.04)],["grade",Vector3(-.5,GRADE-.08,-.04),Vector3(fim,GRADE,.04)],["grade",Vector3(-.5,1.15,-.04),Vector3(fim,1.23,.04)]]
  var x:=-.5+.06
  while x<fim:
   caixas.append(["grade",Vector3(x-.02,0,-.02),Vector3(x+.02,GRADE,.02)])
   x+=.14
  p[nome]=caixas
 p["coluna"]=[["coluna",Vector3(-.2,0,-.2),Vector3(.2,h,.2)]]
 # Pisos e telhado: 2×2 m e 1×1 m. Topo no pivô (y = 0).
 for piso in ["azulejo","cimento","quadra"]:
  p["piso_"+piso]=[[piso,Vector3(-.5,-.1,-.5),Vector3(1.5,0,1.5)]]
  p["piso_"+piso+"_1m"]=[[piso,Vector3(-.5,-.1,-.5),Vector3(.5,0,.5)]]
 p["telhado"]=[["telhado",Vector3(-.5,-.15,-.5),Vector3(1.5,0,1.5)]]
 p["telhado_1m"]=[["telhado",Vector3(-.5,-.15,-.5),Vector3(.5,0,.5)]]
 # Degrau de 2 m de largura (a escada empilha degraus).
 p["degrau"]=[["degrau",Vector3(-1,0,0),Vector3(1,DEGRAU_ALTURA,DEGRAU_PISO)]]
 # Volumes de jogo no bloqueio.
 p["bloco_baixo"]=[["bloco",Vector3(-.5,0,-.5),Vector3(.5,BLOCO,.5)]]
 p["palco"]=[["palco",Vector3(-.5,0,-.5),Vector3(.5,PALCO,.5)]]
 p["arvore"]=[["tronco",Vector3(-.35,0,-.35),Vector3(.35,4.2,.35)],["copa",Vector3(-3.2,3.9,-3.2),Vector3(3.2,6.5,3.2)],["copa",Vector3(-2.1,6.5,-2.1),Vector3(2.1,7.6,2.1)]]
 return p

## Peças que não bloqueiam a passagem: sem colisão própria.
const SEM_COLISAO:=["copa"]

static func malha(caixas: Array) -> ArrayMesh:
 var por_material: Dictionary={}
 for caixa in caixas:
  if not por_material.has(caixa[0]): por_material[caixa[0]]=[]
  por_material[caixa[0]].append(caixa)
 var mesh:=ArrayMesh.new()
 for nome in por_material:
  var st:=SurfaceTool.new()
  st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for caixa in por_material[nome]: _caixa(st,caixa[1],caixa[2])
  st.index()
  st.generate_tangents()
  st.commit(mesh)
  mesh.surface_set_material(mesh.get_surface_count()-1,material(nome))
 return mesh

static func _caixa(st: SurfaceTool,a: Vector3,b: Vector3) -> void:
 var faces:=[
  [Vector3.RIGHT,[Vector3(b.x,a.y,b.z),Vector3(b.x,a.y,a.z),Vector3(b.x,b.y,a.z),Vector3(b.x,b.y,b.z)]],
  [Vector3.LEFT,[Vector3(a.x,a.y,a.z),Vector3(a.x,a.y,b.z),Vector3(a.x,b.y,b.z),Vector3(a.x,b.y,a.z)]],
  [Vector3.UP,[Vector3(a.x,b.y,b.z),Vector3(b.x,b.y,b.z),Vector3(b.x,b.y,a.z),Vector3(a.x,b.y,a.z)]],
  [Vector3.DOWN,[Vector3(a.x,a.y,a.z),Vector3(b.x,a.y,a.z),Vector3(b.x,a.y,b.z),Vector3(a.x,a.y,b.z)]],
  [Vector3.BACK,[Vector3(a.x,a.y,b.z),Vector3(b.x,a.y,b.z),Vector3(b.x,b.y,b.z),Vector3(a.x,b.y,b.z)]],
  [Vector3.FORWARD,[Vector3(b.x,a.y,a.z),Vector3(a.x,a.y,a.z),Vector3(a.x,b.y,a.z),Vector3(b.x,b.y,a.z)]],
 ]
 for face in faces:
  var n: Vector3=face[0]; var v: Array=face[1]
  # Sentido horário visto de fora (frente no Godot).
  for i in [0,2,1,0,3,2]:
   st.set_normal(n)
   st.set_uv(Vector2(v[i].x+v[i].z,v[i].y))
   st.add_vertex(v[i])

static func construir() -> MeshLibrary:
 var lib:=MeshLibrary.new()
 var lista:=pecas()
 var id:=0
 for nome in lista:
  lib.create_item(id)
  lib.set_item_name(id,nome)
  lib.set_item_mesh(id,malha(lista[nome]))
  var formas: Array=[]
  for caixa in lista[nome]:
   if caixa[0] in SEM_COLISAO: continue
   var forma:=BoxShape3D.new()
   forma.size=caixa[2]-caixa[1]
   formas.append(forma)
   formas.append(Transform3D(Basis.IDENTITY,(caixa[1]+caixa[2])*.5))
  lib.set_item_shapes(id,formas)
  id+=1
 return lib

static func item(lib: MeshLibrary,nome: String) -> int:
 var id:=lib.find_item_by_name(nome)
 assert(id>=0,"peça do kit inexistente: "+nome)
 return id
