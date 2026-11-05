extends RefCounted
## Abertura (decisão de Felipe, 02/11/2026): de manhã, Miguel e Felipe saem do
## 3º Informática, descem a escada conversando, Felipe fica, Miguel atravessa
## o refeitório, deita na salinha (Materiais de esportes) e um corte brusco leva
## à noite. Falas aprovadas por Felipe; não inventar outras.
## Só posiciona atores, toca clipes existentes e enquadra a câmera. Nunca
## escreve pose de osso.

const FALAS:=[
 [6.0,9.0,"Miguel","Vou pra sala descansar."],
 [9.2,11.6,"Felipe","Eu vou contigo."],
 [11.8,16.4,"Miguel","Não, vai não, que tu é o porcão, gosta de ficar com o porcão não."],
]
## Marcos da linha do tempo (segundos).
const SAIDA_FIM:=5.0
const ESCADA_FIM:=18.0
const REFEITORIO_FIM:=23.5
const ENTRADA_FIM:=27.0
const DEITADO_FIM:=31.0      # corte brusco manhã -> noite
const CORTE_PRETO:=.45
const ACORDA_FIM:=36.5

var game: Node3D
var clock:=0.0
var active:=false
var felipe: CharacterBody3D
var vultos: Array=[]
var sol: SpotLight3D
var noite:=false
var luz_salva: Dictionary={}
var legenda:=""
var falante:=""
var rotas: Dictionary={}

func start(owner_game: Node3D) -> void:
 game=owner_game
 clock=0.0; active=true; noite=false
 var s=game.school
 var porta=_porta("3 Informática")
 var dentro: Vector3=porta+Vector3(0,0,-.5)
 var corredor: Vector3=porta+Vector3(0,0,1.15)
 var patamar: Vector3=Vector3(s.stairs_top.x-1.5,s.stairs_top.y,s.stairs_top.z)
 rotas["miguel_saida"]=[dentro,porta,corredor+Vector3(.9,0,0)]
 rotas["felipe_saida"]=[dentro+Vector3(.5,0,-.6),porta+Vector3(.4,0,-.2),corredor+Vector3(.2,0,.2)]
 rotas["escada"]=[patamar,s.stairs_top,s.stairs_bottom,s.stairs_bottom+Vector3(1.4,0,0)]
 var sala=_porta("Materiais de esportes")
 rotas["refeitorio"]=[sala+Vector3(-4.6,0,.35),sala+Vector3(-.9,0,0)]
 rotas["entrada"]=[sala+Vector3(-.9,0,0),sala+Vector3(.6,0,0),s.spawn]
 # Felipe: modelo definitivo, só figurante desta cena.
 felipe=game.PERSON.new(); felipe.model_role="felipe"; felipe.cinematic_friend=true
 game.add_child(felipe); felipe.setup(game,rotas["felipe_saida"][0],true)
 _figurante(felipe)
 # Escola viva: só silhuetas ao longe (decisão: nada de alunos modelados).
 var papeis=["sorriso","alessandro","passa_marcha","bola"]
 for i in papeis.size():
  var v=game.PERSON.new(); v.model_role=papeis[i]; v.cinematic_friend=true
  # Atrás do caminho de Miguel no refeitório, cruzando o fundo do plano.
  var a: Vector3=sala+Vector3(-4.5-i*2.4,0,-5.5-float(i%2)*2.0)
  var b: Vector3=a+Vector3(-6.0 if i%2==0 else 6.0,0,0)
  game.add_child(v); v.setup(game,a,true); _figurante(v)
  for mesh in v.model.find_children("*","MeshInstance3D",true,false):
   var m=StandardMaterial3D.new(); m.albedo_color=Color(.03,.03,.035); m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
   mesh.material_override=m
  vultos.append({"ator":v,"a":a,"b":b,"vel":1.1+i*.12,"ida":true})
 # Feixe de sol no rosto (manhã) para o plano do cochilo.
 sol=SpotLight3D.new(); sol.light_color=Color(1,.86,.55); sol.light_energy=6.0
 sol.spot_range=4.0; sol.spot_angle=11.0; sol.visible=false
 game.add_child(sol)
 _dia(true)
 # Portas do caminho abertas (sala de aula e salinha).
 for d in game.school.doors:
  if d.title in ["3 Informática","Materiais de esportes"]: d.set_open(true,true)
 var p=game.player
 p.state="intro"
 if not p.has_meta("mask_original"): p.set_meta("mask_original",p.collision_mask)
 p.collision_mask=0
 p.position=rotas["miguel_saida"][0]; p.velocity=Vector3.ZERO
 p.face(porta,1.0)

func _figurante(a: CharacterBody3D) -> void:
 a.collision_layer=0; a.collision_mask=0
 if a.warning: a.warning.visible=false
 for area in a.hurt_areas: area.collision_layer=0; area.collision_mask=0

func _porta(titulo: String) -> Vector3:
 for d in game.school.doors:
  if d.title==titulo: return d.position
 push_warning("Abertura: porta não encontrada: "+titulo)
 return game.school.spawn

## Clima de manhã: luz alta, pouca neblina. Restaurado no corte para a noite.
func _dia(ligar: bool) -> void:
 var env: Environment=game.school.find_children("*","WorldEnvironment",true,false)[0].environment
 var sol_dir: Array=game.school.find_children("*","DirectionalLight3D",true,false)
 if ligar:
  luz_salva={"amb":env.ambient_light_energy,"amb_cor":env.ambient_light_color,"fog":env.fog_density,
   "fog_cor":env.fog_light_color,"fundo":env.background_color,"dir":sol_dir.map(func(l): return [l.light_energy,l.light_color])}
  env.ambient_light_energy=1.15; env.ambient_light_color=Color(.95,.92,.85)
  env.fog_density=.012; env.fog_light_color=Color(.75,.78,.8); env.background_color=Color(.62,.72,.82)
  for l in sol_dir: l.light_energy=1.6; l.light_color=Color(1,.93,.8)
 elif not luz_salva.is_empty():
  env.ambient_light_energy=luz_salva["amb"]; env.ambient_light_color=luz_salva["amb_cor"]
  env.fog_density=luz_salva["fog"]; env.fog_light_color=luz_salva["fog_cor"]; env.background_color=luz_salva["fundo"]
  for i in sol_dir.size():
   sol_dir[i].light_energy=luz_salva["dir"][i][0]; sol_dir[i].light_color=luz_salva["dir"][i][1]
  luz_salva.clear()

## Anda por uma rota no tempo [t0,t1]; altura acompanha a rota (escada).
func _rota(ator: CharacterBody3D,pontos: Array,t0: float,t1: float,dt: float) -> void:
 var u=clampf((clock-t0)/maxf(.01,t1-t0),0,1)
 var total:=0.0
 for i in pontos.size()-1: total+=pontos[i].distance_to(pontos[i+1])
 var alvo: float=u*total
 var at: Vector3=pontos[-1]
 var direcao:=Vector3.ZERO
 for i in pontos.size()-1:
  var trecho: float=pontos[i].distance_to(pontos[i+1])
  if alvo<=trecho or i==pontos.size()-2:
   at=pontos[i].lerp(pontos[i+1],clampf(alvo/maxf(.001,trecho),0,1)); direcao=pontos[i+1]-pontos[i]; break
  alvo-=trecho
 var anterior: Vector3=ator.position
 ator.position=at
 var passo: Vector3=(at-anterior)/maxf(dt,.001)
 ator.velocity=Vector3(passo.x,0,passo.z) if u<1.0 else Vector3.ZERO
 ator.play("andaFrente" if u<1.0 else "guarda")
 var plano=Vector3(direcao.x,0,direcao.z)
 if plano.length()>.01: ator.face(ator.position+plano,dt*.6)

func tick(dt: float) -> bool:
 if not active: return true
 clock+=dt
 var p=game.player
 legenda=""; falante=""
 for f in FALAS:
  if clock>=f[0] and clock<f[1]: falante=f[2]; legenda=f[3]
 if clock<SAIDA_FIM:
  _rota(p,rotas["miguel_saida"],0,SAIDA_FIM-.4,dt)
  _rota(felipe,rotas["felipe_saida"],.3,SAIDA_FIM-.2,dt)
 elif clock<ESCADA_FIM:
  var r: Array=rotas["escada"]
  _rota(p,r,SAIDA_FIM,ESCADA_FIM-.3,dt)
  # Felipe desce meio passo atrás e para no pé da escada.
  _rota(felipe,r.slice(0,3),SAIDA_FIM+.4,ESCADA_FIM-1.2,dt)
  if clock>ESCADA_FIM-1.2: felipe.face(p.position,dt)
 elif clock<REFEITORIO_FIM:
  if is_instance_valid(felipe): felipe.visible=false
  _rota(p,rotas["refeitorio"],ESCADA_FIM,REFEITORIO_FIM,dt)
 elif clock<ENTRADA_FIM:
  _rota(p,rotas["entrada"],REFEITORIO_FIM,ENTRADA_FIM-.4,dt)
 elif clock<DEITADO_FIM+CORTE_PRETO+2.0:
  if p.velocity!=Vector3.ZERO or clock-dt<ENTRADA_FIM:
   p.velocity=Vector3.ZERO; p.position=game.school.spawn
   p.play("deitado")
  sol.visible=not noite and clock<DEITADO_FIM
  if sol.visible:
   var rosto: Vector3=p.bone_point("Head")
   sol.global_position=rosto+Vector3(.8,1.6,.4)
   sol.look_at(rosto)
  if clock>=DEITADO_FIM and not noite:
   noite=true; sol.visible=false
   _dia(false)
   for v in vultos: v["ator"].visible=false
 elif clock<ACORDA_FIM:
  if p.motion.requested!="novo/LayToIdle": p.start_action("levantar")
 else:
  return true
 for v in vultos:
  var ator: CharacterBody3D=v["ator"]
  if not ator.visible: continue
  var destino: Vector3=v["b"] if v["ida"] else v["a"]
  var dir: Vector3=destino-ator.position; dir.y=0
  if dir.length()<.3: v["ida"]=not v["ida"]; continue
  ator.velocity=dir.normalized()*v["vel"]
  ator.position+=ator.velocity*dt
  ator.play("andaFrente"); ator.face(destino,dt)
  ator.animate(dt)
 p.animate(dt)
 if is_instance_valid(felipe) and felipe.visible: felipe.animate(dt)
 return false

## Tela preta curta no corte manhã -> noite.
func preto() -> bool:
 return active and clock>=DEITADO_FIM and clock<DEITADO_FIM+CORTE_PRETO

## Enquadramento por plano: [posição, alvo, fov]. Cortes secos entre planos.
func shot() -> Array:
 var p=game.player
 var head: Vector3=p.bone_point("Head")
 if clock<SAIDA_FIM:
  var porta=_porta("3 Informática")
  return [porta+Vector3(2.6,1.55,2.0),p.position+Vector3.UP*1.2,52.0]
 if clock<ESCADA_FIM:
  # Frente dos dois, abaixo deles na escada (eles descem na direção da câmera).
  var desce: Vector3=game.school.stairs_bottom-game.school.stairs_top; desce.y=0; desce=desce.normalized()
  var lado: Vector3=desce.cross(Vector3.UP).normalized()
  if falante!="" and is_instance_valid(felipe):
   var quem: CharacterBody3D=p if falante=="Miguel" else felipe
   var h: Vector3=quem.bone_point("Head")
   return [h+desce*1.25+lado*(.45 if quem==p else -.75)+Vector3.UP*.05,h,38.0]
  var meio: Vector3=(p.position+felipe.position)*.5 if is_instance_valid(felipe) else p.position
  return [meio+desce*3.2+lado*.6+Vector3.UP*.6,meio+Vector3.UP*1.3,52.0]
 if clock<REFEITORIO_FIM:
  return [p.position+Vector3(1.5,1.3,3.6),p.position+Vector3.UP*1.0,50.0]
 if clock<ENTRADA_FIM:
  var sala=_porta("Materiais de esportes")
  return [sala+Vector3(-3.2,1.7,-1.4),p.position+Vector3.UP*1.0,50.0]
 if clock<DEITADO_FIM+CORTE_PRETO+2.0:
  # Mesmo enquadramento antes e depois do corte: só a luz muda.
  return [head+Vector3(.15,.75,.55),head,38.0]
 return [p.position+Vector3(-1.2,1.4,1.6),p.position+Vector3.UP*.9,50.0]

## Pular ou terminar: devolve luz, remove figurantes e a câmera volta ao jogo.
func finish() -> void:
 if not active: return
 active=false
 _dia(false)
 if is_instance_valid(felipe): felipe.queue_free()
 for v in vultos:
  if is_instance_valid(v["ator"]): v["ator"].queue_free()
 vultos.clear()
 if is_instance_valid(sol): sol.queue_free()
 game.player.collision_mask=game.player.get_meta("mask_original",game.player.collision_mask)
 legenda=""; falante=""
