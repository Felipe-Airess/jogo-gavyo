extends RefCounted
## Ventilações (decisão de Felipe, 05/11/2026): atalho rastejando por um duto
## curto de uma sala para outra, totalmente seguro (ninguém vê nem entra).
## A primeira saída da ventilação marcada tem o jumpscare do rosto na grade:
## só susto, sem perigo.
## [PROVISÓRIO: rastejar usa o agachado até chegar "Crawling" do Mixamo.]
## Só posiciona atores e câmera; nunca escreve pose de osso.

## [sala A, sala B, susto na primeira saída]
const DUTOS:=[
 ["Materiais de esportes","Estoque da cozinha",true],
 ["Laboratório Informática 2","Laboratório de hardware",false],
]
const ENTRAR:=.55
const ESCURECER:=.35
const VELOCIDADE_DUTO:=1.3
const SUSTO:=1.1

var game: Node3D
var grades: Array=[]          # {pos, normal, par, susto, no}
var estado:=""                # "" · entrando · dentro · susto · saindo
var clock:=0.0
var de: Dictionary={}
var para: Dictionary={}
var duracao:=3.0
var susto_usado:=false        # vale para a sessão: o susto não se repete
var rosto: CharacterBody3D
var luz_rosto: OmniLight3D
var _som:=0.0

func setup(owner_game: Node3D) -> void:
 game=owner_game
 var s=game.school
 for d in DUTOS:
  if not s.rooms.has(d[0]) or not s.rooms.has(d[1]):
   push_warning("Ventilação: sala ausente "+str(d)); continue
  var a=_grade(s.rooms[d[0]],s.rooms[d[1]])
  var b=_grade(s.rooms[d[1]],s.rooms[d[0]])
  a["par"]=b; b["par"]=a
  a["susto"]=false; b["susto"]=d[2]  # o susto é ao sair do lado B
  a["nome"]=d[0]; b["nome"]=d[1]
  grades.append(a); grades.append(b)

## Grade na parede da sala voltada para a outra sala, a 35 cm do chão.
func _grade(sala: Dictionary,outra: Dictionary) -> Dictionary:
 var s=game.school
 var rect: Rect2=sala["rect"]
 var dir: Vector3=outra["center"]-sala["center"]; dir.y=0
 var eixo:=Vector3(signf(dir.x),0,0) if absf(dir.x)>absf(dir.z) else Vector3(0,0,signf(dir.z))
 var centro: Vector3=sala["center"]
 var meio: float
 var pos: Vector3
 if eixo.x!=0:
  meio=(rect.end.x if eixo.x>0 else rect.position.x)+s.ORIGEM.x
  pos=Vector3(meio-eixo.x*.12,sala["floor"]+.35,centro.z)
 else:
  meio=(rect.end.y if eixo.z>0 else rect.position.y)+s.ORIGEM.z
  pos=Vector3(centro.x,sala["floor"]+.35,meio-eixo.z*.12)
 var no=Node3D.new(); no.position=pos; no.rotation.y=atan2(eixo.x,eixo.z); s.add_child(no)
 var fundo=MeshInstance3D.new(); var m=BoxMesh.new(); m.size=Vector3(.62,.42,.04); fundo.mesh=m
 var preto=StandardMaterial3D.new(); preto.albedo_color=Color(.02,.02,.025); fundo.material_override=preto
 no.add_child(fundo)
 var metal=StandardMaterial3D.new(); metal.albedo_color=Color(.42,.43,.45); metal.metallic=.5
 for i in 5:
  var barra=MeshInstance3D.new(); var bm=BoxMesh.new(); bm.size=Vector3(.025,.40,.03); barra.mesh=bm
  barra.material_override=metal; barra.position=Vector3(-.24+i*.12,0,-.03); no.add_child(barra)
 return {"pos":pos,"normal":-eixo,"no":no}

func perto() -> Dictionary:
 if estado!="": return {}
 for g in grades:
  if game._near_looking(g["pos"],1.4): return g
 return {}

func texto() -> String:
 var g=perto()
 return "" if g.is_empty() else "[Espaço] Entrar na ventilação · leva a "+String(g["par"]["nome"])

func tentar_entrar() -> bool:
 var g=perto()
 if g.is_empty(): return false
 de=g; para=g["par"]; estado="entrando"; clock=0.0
 duracao=clampf(Vector2(de["pos"].x-para["pos"].x,de["pos"].z-para["pos"].z).length()/VELOCIDADE_DUTO,2.5,6.0)
 var p=game.player
 p.velocity=Vector3.ZERO; p.crouched=true; p.state="intro"
 game.phase="duto"
 return true

func preto() -> bool:
 return estado=="dentro" or (estado=="entrando" and clock>ENTRAR) or (estado=="saindo" and clock<ESCURECER)

func tick(dt: float) -> void:
 clock+=dt
 var p=game.player
 if estado=="entrando":
  var alvo: Vector3=de["pos"]+de["normal"]*.55; alvo.y=p.position.y
  p.position=p.position.lerp(alvo,minf(1.0,dt*6.0)); p.face(de["pos"],dt)
  p.play("andaFrente" if clock<ENTRAR else "guarda")
  if clock>=ENTRAR+ESCURECER:
   estado="dentro"; clock=0.0
   p.hidden=true; p.model.visible=false
 elif estado=="dentro":
  _som-=dt
  if _som<=0: _som=.55; game.sound.emit_at("roupa",p.position,-14)
  # Miguel "rasteja" pelo duto: posição acompanha (para som e câmera).
  p.position=de["pos"].lerp(para["pos"],clampf(clock/duracao,0,1))*Vector3(1,0,1)+Vector3.UP*p.position.y
  if clock>=duracao:
   p.position=Vector3(para["pos"].x,para["pos"].y-.35,para["pos"].z)+para["normal"]*.6
   if para["susto"] and not susto_usado: _iniciar_susto()
   else: estado="saindo"; clock=0.0; _sair()
 elif estado=="susto":
  if is_instance_valid(rosto):
   rosto.face(para["pos"],1.0); rosto.play("guarda"); rosto.animate(dt)
  if clock>=SUSTO:
   if is_instance_valid(rosto): rosto.visible=false
   if is_instance_valid(luz_rosto): luz_rosto.visible=false
   estado="saindo"; clock=0.0; _sair()
 elif estado=="saindo":
  p.play("guarda")
  if clock>=ESCURECER+.4:
   estado=""; p.state="idle"; game.phase="investigate"
 p.animate(dt)

func _sair() -> void:
 var p=game.player
 p.hidden=false; p.model.visible=true
 p.face(p.position+para["normal"],1.0)
 game.view.yaw=atan2(-para["normal"].x,-para["normal"].z)

## Rosto do lado de fora da grade, olhando para dentro, de baixo para cima.
func _iniciar_susto() -> void:
 susto_usado=true; estado="susto"; clock=0.0
 var fora: Vector3=Vector3(para["pos"].x,para["pos"].y-.35,para["pos"].z)+para["normal"]*.55
 if not is_instance_valid(rosto):
  rosto=game.PERSON.new(); rosto.cinematic_friend=true
  game.add_child(rosto); rosto.setup(game,fora,true)
  rosto.collision_layer=0; rosto.collision_mask=0
  for area in rosto.hurt_areas: area.collision_layer=0; area.collision_mask=0
  if rosto.warning: rosto.warning.visible=false
  luz_rosto=OmniLight3D.new(); luz_rosto.light_color=Color(.7,.78,1.0); luz_rosto.light_energy=2.2
  luz_rosto.omni_range=2.5; luz_rosto.shadow_enabled=false; game.add_child(luz_rosto)
 rosto.position=fora; rosto.visible=true; rosto.face(para["pos"],1.0)
 luz_rosto.global_position=para["pos"]+Vector3.UP*.2; luz_rosto.visible=true
 game.sound.emit_at("grito",fora+Vector3.UP*1.6,-2)
 game.view.trauma=maxf(game.view.trauma,.6)
 if game.medo!=null: game.medo.assustar()

## Enquadramento: [posição, alvo, fov].
func shot() -> Array:
 var p=game.player
 if estado=="susto" and is_instance_valid(rosto):
  # Por dentro da grade, olhando para fora e para cima: o rosto encostado.
  var olho: Vector3=para["pos"]-para["normal"]*.25
  return [olho,rosto.bone_point("Head"),62.0]
 var g: Dictionary=para if estado=="saindo" else de
 return [p.position-g["normal"]*-1.6+Vector3.UP*1.3,p.position+Vector3.UP*.5,58.0]
