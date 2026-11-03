extends Node
## Recursos importados, variação sem repetição imediata e mistura com headroom.
## Somente áudio: não altera física, IA, clipes ou poses.
const LEVELS=preload("res://capitulo1/sons_niveis.gd").LEVELS
const ROOT="res://capitulo1/assets/sons/"
const STEPS="01_PASSOS/"
const DOORS="02_PORTAS_RANGIDOS/rpg-audio/"
const CLOTH="03_ROUPAS_MOVIMENTO/rpg-audio/"
const IMPACT="04_OBJETOS_IMPACTOS/impact-sounds/"
const UI="06_INTERFACE/interface-sounds/"
const VOICE="07_VOZES_CRIATURAS_REFERENCIA/oga-zombies/zombies/"
var game: Node3D
var pools: Dictionary={}
var streams: Dictionary={}
var last: Dictionary={}
var step_players: Dictionary={}
var positions: Dictionary={}
var travelled: Dictionary={}
var effects: Array[AudioStreamPlayer3D]=[]
var ui_player: AudioStreamPlayer
var effect_index:=0
var played: Dictionary={}
var last_file:=""
var breath_profile:="silencio"
var random:=RandomNumberGenerator.new()

func setup(owner_game: Node3D) -> void:
 game=owner_game
 for data in [["CapituloEfeitos",-3.0],["CapituloEscada",-3.0],["CapituloVoz",-3.0],["CapituloUI",-6.0],["CapituloAmbiente",-5.0]]:
  if AudioServer.get_bus_index(data[0])>=0: continue
  AudioServer.add_bus(); var index=AudioServer.bus_count-1
  AudioServer.set_bus_name(index,data[0]); AudioServer.set_bus_send(index,"Master")
  AudioServer.set_bus_volume_db(index,data[1])
 var stairs_bus=AudioServer.get_bus_index("CapituloEscada")
 if AudioServer.get_bus_effect_count(stairs_bus)==0:
  var room=AudioEffectReverb.new(); room.room_size=.45; room.wet=.18; room.dry=1.0
  AudioServer.add_bus_effect(stairs_bus,room)
 var limited=false
 for i in AudioServer.get_bus_effect_count(0):
  if AudioServer.get_bus_effect(0,i) is AudioEffectHardLimiter: limited=true
 if not limited:
  var limiter=AudioEffectHardLimiter.new(); limiter.ceiling_db=-1.0
  AudioServer.add_bus_effect(0,limiter)
 pools={"azulejo":[],"cimento":[],"escada":[STEPS+"oga-footsteps/stone01.ogg"],
 "porta_abrir":[DOORS+"doorOpen_1.ogg",DOORS+"doorOpen_2.ogg"],
 "porta_fechar":[],"armario_abrir":[],"armario_fechar":[DOORS+"metalLatch.ogg"],
 "bolsa":[CLOTH+"handleSmallLeather.ogg",CLOTH+"handleSmallLeather2.ogg"],
 "roupa":[CLOTH+"cloth1.ogg",CLOTH+"cloth2.ogg",CLOTH+"cloth3.ogg",CLOTH+"cloth4.ogg"],
 "portao":[DOORS+"metalLatch.ogg",IMPACT+"impactMetal_medium_000.ogg"],
 "agarrao":[],"impacto_metal":[],"impacto_parede":[],"impacto_corpo":[],"impacto_madeira":[],
 "grito":[],"seta":[UI+"tick_001.ogg",UI+"tick_002.ogg",UI+"tick_004.ogg"],
 "sucesso":[UI+"confirmation_001.ogg",UI+"confirmation_002.ogg"],
 "erro":[UI+"error_001.ogg",UI+"error_002.ogg"],"falha":[UI+"close_001.ogg"]}
 for i in 10: pools["azulejo"].append(STEPS+"rpg-audio/footstep%02d.ogg"%i)
 for i in 5:
  var concrete=STEPS+"impact-sounds/footstep_concrete_%03d.ogg"%i
  pools["cimento"].append(concrete); pools["escada"].append(concrete)
  pools["agarrao"].append(IMPACT+"impactSoft_heavy_%03d.ogg"%i)
  pools["impacto_metal"].append(IMPACT+"impactMetal_medium_%03d.ogg"%i)
  pools["impacto_parede"].append(IMPACT+"impactGeneric_light_%03d.ogg"%i)
  pools["impacto_corpo"].append(IMPACT+"impactPunch_medium_%03d.ogg"%i)
  pools["impacto_madeira"].append(IMPACT+"impactWood_medium_%03d.ogg"%i)
 for i in range(1,5): pools["porta_fechar"].append(DOORS+"doorClose_%d.ogg"%i)
 for i in range(1,4): pools["armario_abrir"].append(DOORS+"creak%d.ogg"%i)
 for i in range(1,13): pools["grito"].append(VOICE+"zombie-%d.wav"%i)
 # load() resolve .import e o recurso empacotado na web. Nunca lê bytes do som.
 for pool in pools.values():
  for file in pool:
   if not streams.has(file): streams[file]=load(ROOT+file)
 for i in 8:
  var voice=AudioStreamPlayer3D.new(); add_child(voice); effects.append(voice)
  configure(voice,10,3.0)
 ui_player=AudioStreamPlayer.new(); ui_player.bus="CapituloUI"; ui_player.max_polyphony=4; add_child(ui_player)

func configure(player: AudioStreamPlayer3D,reach: float,unit: float) -> void:
 player.bus="CapituloEfeitos"; player.max_distance=reach; player.unit_size=unit
 player.max_db=0; player.max_polyphony=2

func pick(event: String,key: String="") -> String:
 var pool: Array=pools[event]
 if key.is_empty(): key=event
 var index=random.randi_range(0,pool.size()-1)
 if pool.size()>1 and index==int(last.get(key,-1)): index=(index+1+random.randi_range(0,pool.size()-2))%pool.size()
 last[key]=index
 return pool[index]

func prepare(player,event: String,offset:=0.0,pitch:=1.0,key: String="") -> String:
 var file=pick(event,key)
 player.stream=streams[file]
 player.volume_db=float(LEVELS[file]["gain_db"])+offset+random.randf_range(-.6,.6)
 player.pitch_scale=pitch*random.randf_range(.97,1.03)
 last_file=file
 return file
func note(event: String) -> void: played[event]=int(played.get(event,0))+1
func emit_at(event: String,at: Vector3,offset:=-3.0) -> void:
 var player=effects[effect_index]; effect_index=(effect_index+1)%effects.size()
 prepare(player,event,offset); player.global_position=at+Vector3.UP*.7; player.play(); note(event)
func ui(event: String) -> void:
 prepare(ui_player,event,-3); ui_player.play(); note(event)
func shout(actor) -> void:
 if not is_instance_valid(actor.hunt_voice):
  actor.hunt_voice=AudioStreamPlayer3D.new(); actor.add_child(actor.hunt_voice)
 configure(actor.hunt_voice,10,3.5); actor.hunt_voice.bus="CapituloVoz"; actor.hunt_voice.position=Vector3.UP*1.6
 prepare(actor.hunt_voice,"grito",0,.78 if actor.pursuer else 1.0,"grito%d"%actor.get_instance_id())
 actor.hunt_voice.play(); note("grito")

func floor_at(at: Vector3) -> String:
 var school=game.school
 var flight: Vector3=school.stairs_top-school.stairs_bottom
 var axis=flight*Vector3(1,0,1); var length=axis.length(); axis/=length
 var delta=(at-school.stairs_bottom)*Vector3(1,0,1); var t=delta.dot(axis)
 if t>=-.2 and t<=length+.2 and (delta-axis*t).length()<1.1:
  if absf(at.y-lerpf(school.stairs_bottom.y,school.stairs_top.y,clampf(t/length,0,1)))<.5: return "escada"
 var cell=school.celula_de(at)
 var level=1 if at.y>school.LEVEL*.7 else 0
 var symbol=school.andares[level].piso(cell.x,cell.y)
 return "azulejo" if school.PISO_PECA.get(symbol,"")=="piso_azulejo" else "cimento"

func footstep(actor,forced_surface: String="") -> void:
 var id=actor.get_instance_id()
 if not step_players.has(id):
  var player=AudioStreamPlayer3D.new(); actor.add_child(player); player.position=Vector3.UP*.15
  step_players[id]=player
 var player: AudioStreamPlayer3D=step_players[id]
 var surface=floor_at(actor.global_position) if forced_surface.is_empty() else forced_surface
 configure(player,10 if actor.enemy else 7,4.0 if actor.pursuer else 3.0 if actor.enemy else 1.5)
 if surface=="escada": player.bus="CapituloEscada"
 var offset=-1.0 if actor.pursuer else -3.0 if actor.enemy else -9.0 if actor.crouched else -6.0
 if actor.enemy: offset+=game.pressure.foot_boost(game,actor)
 var pitch=.72 if actor.pursuer else .87 if actor.enemy else 1.0
 prepare(player,surface,offset,pitch,"passo%d_%s"%[id,surface])
 player.play(); note("passo_"+surface); note("passo_perseguidor" if actor.pursuer else "passo_cultista" if actor.enemy else "passo_miguel")

func tick(dt: float) -> void:
 var moving=game.started and not game.paused and not game.player.dead
 var actors: Array=[game.player]; actors.append_array(game.enemies)
 if is_instance_valid(game.pursuer): actors.append(game.pursuer)
 for actor in actors:
  var id=actor.get_instance_id(); var at: Vector3=actor.global_position
  var delta=Vector2(at.x,at.z).distance_to(Vector2(positions.get(id,at).x,positions.get(id,at).z))
  positions[id]=at
  if not moving or game.escape.active or actor.hidden or actor.dead or actor.down or game.phase not in ["investigate","chase","sighting","discovery"]:
   travelled[id]=0.0
   if step_players.has(id): step_players[id].stop()
   continue
  # Teleporte de checkpoint/armário não é passada. Pés no ar também ficam mudos.
  if delta>.45 or not actor.is_on_floor(): travelled[id]=0.0; continue
  if delta<.00001: continue
  var clip=String(actor.motion.active_clip).trim_prefix("novo/")
  var stride=float(actor.motion.strides.get(clip,{"stride":1.2})["stride"])*.5
  travelled[id]=float(travelled.get(id,0))+delta
  if travelled[id]>=maxf(.12,stride):
   travelled[id]=fmod(travelled[id],maxf(.12,stride)); footstep(actor)
 var profile="agarrado" if game.escape.active else "correndo" if Vector2(game.player.velocity.x,game.player.velocity.z).length()>2.5 or game.burst_clock>0 else "normal"
 breath_profile=profile if moving else "silencio"
 var breath: AudioStreamPlayer=game.breathing
 if not moving:
  breath.stop(); return
 var volume={"normal":-38.0,"correndo":-23.0,"agarrado":-19.0}[profile]
 var panic=game.pressure.value
 volume+=panic*(15.0 if profile=="normal" else 4.0)
 breath.volume_db=lerpf(breath.volume_db,volume,1-exp(-5*dt))
 breath.pitch_scale={"normal":.85,"correndo":1.1,"agarrado":1.25}[profile]+panic*(.35 if profile=="normal" else .15)
 if not breath.playing: breath.play()

func reset() -> void:
 positions.clear(); travelled.clear()
 for player in step_players.values():
  if is_instance_valid(player): player.stop()
 for player in effects: player.stop()
 ui_player.stop(); game.breathing.stop(); breath_profile="silencio"
