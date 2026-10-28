extends SceneTree
## Fumaça da cena completa: seleção → partida (IA nos dois lados, todos os pares
## de personagens) → pausa → fim → menu, desenhando cada quadro. Falha em erro.
var game
var frames := 0
var pairs := [["miguel", "sorriso"], ["sorriso", "miguel"], ["miguel", "miguel"], ["sorriso", "sorriso"]]
var pair := 0
var bot
var checks := 0
var problems: Array = []

func _initialize() -> void:
	game = load("res://duel_game.tscn").instantiate()
	root.add_child(game)

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		game.debug_visible = true
		start_pair()
	if game.mode == "playing" and bot != null:
		# O jogador também é uma IA: entra pela mesma leitura de comandos.
		var inp: Dictionary = bot.input(game.model, game.model.fighters[0], game.model.fighters[1])
		for k in ["attack", "kick", "grab"]:
			if inp.get(k, false): game.stepper.latched[k] = true
		game.touch.sources[99] = inp
	if frames % 900 == 0 or game.mode == "over":
		checks += 1
		if game.model.clock <= 0: problems.append("relógio parado em %s" % [pairs[pair]])
		pair += 1
		if pair >= pairs.size():
			game.change_mode("paused"); game.change_mode("select")
			print("Game smoke: %d partidas, %d quadros, problemas: %s" % [checks, frames, problems])
			return true
		start_pair()
	return false

func start_pair() -> void:
	game.settings.player = pairs[pair][0]
	game.settings.rival = pairs[pair][1]
	game.settings.seconds = 0
	game.start_match()
	bot = load("res://scripts/duel/ai.gd").new(7 + pair, "dificil")
