extends RefCounted
## Um andar do mapa descrito em texto (capitulo1/mapa/terreo.txt, superior.txt).
## 1 caractere = 1 m. Coluna = x, linha = z. Só lê e responde perguntas sobre a
## grade; quem monta a geometria é escola_grade.gd.

## Bloqueiam a passagem entre ambientes (delimitam salas).
const PAREDES:="#-DWOG"
## Paredes com eixo próprio (peças retas de 2 m): o eixo vem dos vizinhos.
const RETAS:="DWOG"
const PISOS:=".,;:_"
const ESCADA:="<>^v"
## Direção para onde a escada sobe.
const SOBE:={"<":Vector2i(-1,0),">":Vector2i(1,0),"^":Vector2i(0,-1),"v":Vector2i(0,1)}
## Símbolos com significado próprio: não podem nomear ambientes.
const RESERVADOS:="#-DWOG.,;:_<>^vCLT%@$*+&0123456789"
const VIZINHOS:=[Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1)]

var linhas: PackedStringArray=[]
var largura:=0
var altura:=0
var salas: Dictionary={}   # letra -> nome (ambiente com porta)
var areas: Dictionary={}   # letra -> nome (área aberta)
var erros: PackedStringArray=[]
var _eixo: Dictionary={}   # Vector2i -> "x"/"z" para RETAS

static func ler(caminho: String) -> RefCounted:
 var g=load("res://capitulo1/mapa/grade.gd").new()
 g._ler_texto(FileAccess.get_file_as_string(caminho),caminho)
 return g

func _ler_texto(texto: String,origem:="") -> void:
 var na_grade:=false
 for bruta in texto.split("\n"):
  var linha:=bruta.trim_suffix("\r")
  if not na_grade:
   if linha.strip_edges()=="---": na_grade=true; continue
   if linha.begins_with(";") or linha.strip_edges()=="": continue
   var partes:=linha.strip_edges().split(" ",false,2)
   if partes.size()==3 and partes[0] in ["sala","area"] and partes[1].length()==1:
    if partes[1] in RESERVADOS: erros.append("%s: a letra %s é reservada (estrutura/marca)"%[origem,partes[1]])
    if partes[0]=="sala": salas[partes[1]]=partes[2]
    else: areas[partes[1]]=partes[2]
   else: erros.append("%s: linha de legenda não entendida: %s"%[origem,linha])
   continue
  linhas.append(linha)
 while linhas.size()>0 and linhas[linhas.size()-1].strip_edges()=="": linhas.resize(linhas.size()-1)
 altura=linhas.size()
 for l in linhas: largura=maxi(largura,l.length())
 if not na_grade: erros.append("%s: falta a linha --- antes da grade"%origem)
 _calcular_eixos()

func ch(c: int,r: int) -> String:
 if r<0 or r>=altura or c<0: return " "
 var l:=linhas[r]
 return l[c] if c<l.length() else " "

func chv(v: Vector2i) -> String: return ch(v.x,v.y)

func e_parede(c: int,r: int) -> bool: return ch(c,r) in PAREDES and ch(c,r)!=" "
func e_vazio(c: int,r: int) -> bool: return ch(c,r)==" "
func e_escada(c: int,r: int) -> bool: return ch(c,r) in ESCADA and ch(c,r)!=" "

## Piso efetivo: símbolos e letras herdam o piso mais comum entre os vizinhos.
func piso(c: int,r: int) -> String:
 var s:=ch(c,r)
 if s==" ": return ""
 if s in PISOS: return s
 var conta: Dictionary={}
 for raio in [1,2]:
  for dr in range(-raio,raio+1):
   for dc in range(-raio,raio+1):
    var v:=ch(c+dc,r+dr)
    if v in PISOS and v!=" " and v!="_": conta[v]=int(conta.get(v,0))+1
  if not conta.is_empty(): break
 var melhor:=""
 for k in conta:
  if melhor=="" or conta[k]>conta[melhor]: melhor=k
 return melhor if melhor!="" else "."

## Eixo de portas/janelas/vãos/portões: corre ao longo das paredes vizinhas.
func _calcular_eixos() -> void:
 for r in altura:
  for c in largura:
   var s:=ch(c,r)
   if s==" " or not s in RETAS: continue
   var x:=e_parede(c-1,r) or e_parede(c+1,r)
   var z:=e_parede(c,r-1) or e_parede(c,r+1)
   if x and z:
    # Prefere o eixo da sequência do mesmo tipo.
    x=ch(c-1,r)==s or ch(c+1,r)==s
   _eixo[Vector2i(c,r)]="x" if x else "z"

func eixo(c: int,r: int) -> String: return _eixo.get(Vector2i(c,r),"")

## Braços de uma parede (# ou -): direções para vizinhos de parede ligáveis.
func bracos(c: int,r: int) -> Array[Vector2i]:
 var out: Array[Vector2i]=[]
 for d in VIZINHOS:
  var n: Vector2i=Vector2i(c,r)+d
  var s:=chv(n)
  if s==" " or not s in PAREDES: continue
  if s in RETAS and eixo(n.x,n.y)!=("x" if d.y==0 else "z"): continue
  out.append(d)
 return out

func celulas(simbolos: String) -> Array[Vector2i]:
 var out: Array[Vector2i]=[]
 for r in altura:
  for c in largura:
   var s:=ch(c,r)
   if s!=" " and s in simbolos: out.append(Vector2i(c,r))
 return out

## Ambiente que contém a célula: tudo ligado sem atravessar parede/porta/vão.
func regiao(inicio: Vector2i) -> Array[Vector2i]:
 var out: Array[Vector2i]=[]
 if e_vazio(inicio.x,inicio.y) or e_parede(inicio.x,inicio.y): return out
 var visto: Dictionary={inicio:true}
 var fila: Array[Vector2i]=[inicio]
 while not fila.is_empty():
  var v: Vector2i=fila.pop_back()
  out.append(v)
  for d in VIZINHOS:
   var n: Vector2i=v+d
   if visto.has(n) or e_vazio(n.x,n.y) or e_parede(n.x,n.y): continue
   visto[n]=true; fila.append(n)
 return out

## Sequências retas de um mesmo símbolo de RETAS: [{inicio, eixo, n, simbolo}].
func sequencias(simbolo: String) -> Array[Dictionary]:
 var out: Array[Dictionary]=[]
 var usado: Dictionary={}
 for v in celulas(simbolo):
  if usado.has(v): continue
  var e:=eixo(v.x,v.y)
  var passo:=Vector2i(1,0) if e=="x" else Vector2i(0,1)
  # Começa no primeiro da sequência.
  var a:=v
  while chv(a-passo)==simbolo and eixo(a.x-passo.x,a.y-passo.y)==e: a-=passo
  var n:=0
  while chv(a+passo*n)==simbolo and eixo(a.x+passo.x*n,a.y+passo.y*n)==e:
   usado[a+passo*n]=true; n+=1
  out.append({"inicio":a,"eixo":e,"n":n,"simbolo":simbolo})
 return out

## Retângulos da escada com a direção de subida.
func escadas() -> Array[Dictionary]:
 var out: Array[Dictionary]=[]
 var usado: Dictionary={}
 for v in celulas(ESCADA):
  if usado.has(v): continue
  var s:=chv(v)
  var c1:=v.x; var r1:=v.y
  while chv(Vector2i(c1+1,v.y))==s: c1+=1
  while chv(Vector2i(v.x,r1+1))==s: r1+=1
  for r in range(v.y,r1+1):
   for c in range(v.x,c1+1): usado[Vector2i(c,r)]=true
  out.append({"rect":Rect2i(v.x,v.y,c1-v.x+1,r1-v.y+1),"sobe":SOBE[s]})
 return out

## Retângulos gulosos de células que satisfazem `teste` (para lajes e blocos).
func retangulos(teste: Callable) -> Array[Rect2i]:
 var out: Array[Rect2i]=[]
 var usado: Dictionary={}
 for r in altura:
  for c in largura:
   var v:=Vector2i(c,r)
   if usado.has(v) or not teste.call(c,r): continue
   var w:=1
   while not usado.has(Vector2i(c+w,r)) and teste.call(c+w,r): w+=1
   var h:=1
   var ok:=true
   while ok:
    for dc in w:
     if usado.has(Vector2i(c+dc,r+h)) or not teste.call(c+dc,r+h): ok=false; break
    if ok: h+=1
   for dr in h:
    for dc in w: usado[Vector2i(c+dc,r+dr)]=true
   out.append(Rect2i(c,r,w,h))
 return out
