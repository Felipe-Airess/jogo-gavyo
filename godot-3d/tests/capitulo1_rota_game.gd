extends "res://capitulo1/game.gd"
## A rota automática mede geometria e fluxo, sem percepção/agarrão de comuns.
## Os testes de caça usam o jogo real, sem esta subclasse.
var isolate_common_ai:=false
func enemy_sees(actor: CharacterBody3D,ignore_facing:=false) -> bool:
 if isolate_common_ai and actor in enemies: return false
 return super.enemy_sees(actor,ignore_facing)
func _grab_player(actor: CharacterBody3D) -> bool:
 if isolate_common_ai and actor in enemies: return false
 return super._grab_player(actor)
