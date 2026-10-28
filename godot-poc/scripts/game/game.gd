extends Node
## Raiz do jogo: menu/duelo e corredor de treino, um ativo por vez.
const Art = preload("res://scripts/duel/art.gd")
const DuelGame = preload("res://scripts/game/duel_game.gd")
const CorridorGame = preload("res://scripts/game/corridor_game.gd")

var duel
var corridor

func _ready() -> void:
	var art := Art.load_all()
	duel = DuelGame.new()
	duel.setup(art)
	add_child(duel)
	corridor = CorridorGame.new()
	corridor.setup(art, duel.settings)
	add_child(corridor)
	corridor.activate(false)
	duel.corridor_requested.connect(_to_corridor)
	corridor.menu_requested.connect(_to_menu)

func _to_corridor() -> void:
	duel.activate(false)
	corridor.activate(true)
	corridor.start(duel.settings.player, duel.settings.training, duel.touch.visible)

func _to_menu() -> void:
	corridor.activate(false)
	duel.activate(true)
