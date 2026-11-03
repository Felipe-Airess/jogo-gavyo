extends RefCounted
## Pressão audiovisual lê a caça existente. Nunca liga alerta, muda IA ou escreve ossos.
var value:=0.0
var hunters:=0
var nearest:=INF
const MODES=["notice","chase","last_seen","search","to_hide","open_hide"]
func is_hunting(game,actor) -> bool:
 if actor.dead or actor.down or actor.state=="escape_stunned": return false
 if actor.pursuer: return game.phase=="chase"
 return actor.aware and actor.hunt.mode in MODES
func proximity(distance: float) -> float:
 return 1-clampf((distance-1.5)/10.5,0,1)
func foot_boost(game,actor) -> float:
 if not is_hunting(game,actor): return 0.0
 return value*proximity(actor.global_position.distance_to(game.player.global_position))*5.0
func tick(game,dt: float) -> void:
 hunters=0; nearest=INF
 if game.started and not game.paused and not game.player.dead and game.phase in ["investigate","chase"]:
  var actors: Array=game.enemies.duplicate()
  if is_instance_valid(game.pursuer): actors.append(game.pursuer)
  for actor in actors:
   if not is_hunting(game,actor): continue
   hunters+=1; nearest=minf(nearest,actor.global_position.distance_to(game.player.global_position))
 var target=0.0 if hunters==0 else .2+.8*proximity(nearest)
 if game.paused or game.player.dead or game.phase not in ["investigate","chase"]: value=0
 else: value=move_toward(value,target,dt*(1.5 if target>value else .9))
 game.tension.volume_db=-32+14*value
 game.tension.pitch_scale=.90+.10*value
 if value>.001:
  if not game.tension.playing: game.tension.play()
 elif game.tension.playing: game.tension.stop()
func reset(game) -> void:
 value=0; hunters=0; nearest=INF
 game.tension.stop(); game.tension.volume_db=-60
