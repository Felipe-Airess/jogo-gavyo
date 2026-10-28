extends SceneTree
## Fumaça do jogo inteiro (game.tscn): duelo com todos os pares de personagens
## (IA nos dois lados) e corredor de treino com Sorriso e Miguel nos três modos,
## desenhando cada quadro. Erros de script aparecem na saída.
var game
var frames := 0
var stage := 0
var stage_frames := 0
var bot
var rng := 7
var report: Array = []
const DUEL_PAIRS := [["miguel", "sorriso"], ["sorriso", "miguel"], ["miguel", "miguel"], ["sorriso", "sorriso"]]
const CORRIDOR := [["sorriso", "reaction"], ["sorriso", "sparring"], ["miguel", "guard"], ["miguel", "sparring"]]

func _initialize() -> void:
	game = load("res://game.tscn").instantiate()
	root.add_child(game)

func rand() -> float:
	rng = (rng * 1664525 + 1013904223) & 0xFFFFFFFF
	return float(rng) / 4294967296.0

func _process(_delta: float) -> bool:
	frames += 1
	if frames > 12000 or game == null or game.duel == null:
		print("Game smoke: FALHOU (cena não carregou ou travou)")
		return true
	if frames < 3: return false
	var duel = game.duel
	var corridor = game.corridor
	if stage_frames == 0: start_stage()
	stage_frames += 1
	if stage < DUEL_PAIRS.size():
		if duel.mode == "playing":
			var inp: Dictionary = bot.input(duel.model, duel.model.fighters[0], duel.model.fighters[1])
			for k in ["attack", "kick", "grab"]:
				if inp.get(k, false): duel.stepper.latched[k] = true
			duel.touch.sources[99] = inp
	else:
		var p: Dictionary = corridor.model.player
		var d: Variant = corridor.model.nearest()
		var inp2 := {}
		if d != null: inp2["right" if d.x > p.x else "left"] = rand() < 0.8
		if rand() < 0.1: inp2.guard = true
		corridor.touch.sources[99] = inp2
		if rand() < 0.1: corridor.stepper.latched["attack"] = true
		if rand() < 0.05: corridor.stepper.latched["kick"] = true
		if rand() < 0.02: corridor.stepper.latched["grab"] = true
	if stage_frames >= 700:
		record()
		stage += 1
		stage_frames = 0
		if stage >= DUEL_PAIRS.size() + CORRIDOR.size():
			print("Game smoke: %d quadros; %s" % [frames, "; ".join(report)])
			return true
	return false

func start_stage() -> void:
	var duel = game.duel
	if stage < DUEL_PAIRS.size():
		duel.settings.mode = "duelo"
		duel.settings.player = DUEL_PAIRS[stage][0]
		duel.settings.rival = DUEL_PAIRS[stage][1]
		duel.settings.seconds = 0
		duel.debug_visible = true
		duel.start_match()
		bot = load("res://scripts/duel/ai.gd").new(7 + stage, "dificil")
	else:
		if game.corridor.visible: game._to_menu()
		var c: Array = CORRIDOR[stage - DUEL_PAIRS.size()]
		duel.settings.mode = "corredor"
		duel.settings.player = c[0]
		duel.settings.training = c[1]
		duel.start_match()
		game.corridor.debug_visible = true

func record() -> void:
	if stage < DUEL_PAIRS.size():
		var m = game.duel.model
		report.append("duelo %s: relógio %d ms, %s" % [DUEL_PAIRS[stage], int(m.clock), "resultado" if m.result != null else "em luta"])
	else:
		var b = game.corridor.model
		var states: Array = []
		for d in b.enemies: states.append(d.state)
		report.append("corredor %s: %d ms, acertos %d, alvos %s" % [CORRIDOR[stage - DUEL_PAIRS.size()], int(b.clock), b.combo.best, "/".join(states)])
