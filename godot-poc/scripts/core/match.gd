extends RefCounted
## Native port of rounds/timer; no engine or browser objects required.
var best_of := 3
var seconds := 60
var round_number := 1
var wins := [0, 0]
var history: Array = []
var over := false
var winner: Variant = null
var phase := "intro"
var phase_t := 0.0
var time_left := 60000.0
var outcome: Variant = null

func _init(options: Dictionary = {}) -> void:
	best_of = int(options.get("bestOf", 3))
	seconds = int(options.get("seconds", 60))
	reset()

func reset() -> void:
	round_number = 1
	wins = [0, 0]
	history.clear()
	over = false
	winner = null
	start_round()

func start_round() -> void:
	phase = "intro"
	phase_t = 0
	time_left = seconds * 1000.0
	outcome = null

func banner() -> Variant:
	if phase == "intro":
		var last: bool = best_of > 1 and wins[0] == ceili(best_of / 2.0) - 1 and wins[1] == ceili(best_of / 2.0) - 1
		return {"title": ("ROUND FINAL" if last else "ROUND %d" % round_number) if phase_t < 1100 else "LUTA!", "sub": ("MELHOR DE %d" % best_of if best_of > 1 else "") if phase_t < 1100 else ""}
	if phase == "roundEnd" and outcome != null:
		return {"title": "K.O." if outcome.by == "ko" else ("TEMPO!" if outcome.by == "time" else "EMPATE"),
			"sub": ("PONTO SEU" if outcome.winner == 1 else "PONTO DO RIVAL") if outcome.winner != null else "NINGUEM PONTUA"}
	return null

static func damage_taken(f: Dictionary) -> float:
	return f.condition.head + f.condition.body + f.condition.legs + (100 - f.balance) * 0.05 + (100 - f.stamina) * 0.02

func update(dt: float, duel) -> Variant:
	if phase == "done":
		return null
	phase_t += dt
	if phase == "intro":
		if phase_t >= 1700:
			phase = "fight"
			phase_t = 0
			return "fight"
		return null
	if phase == "fight":
		if duel.get("result") != null:
			return end_round({"by": "ko", "winner": duel.result.winner, "reason": duel.result.reason})
		if seconds != 0:
			time_left -= dt
			if time_left <= 0:
				var a: Dictionary = duel.fighters[0]
				var b: Dictionary = duel.fighters[1]
				var da := damage_taken(a)
				var db := damage_taken(b)
				var won: Variant = null if absf(da - db) < 0.5 else (a.id if da < db else b.id)
				return end_round({"by": "draw" if won == null else "time", "winner": won, "reason": "Tempo: castigo igual." if won == null else "Tempo: venceu quem apanhou menos."})
		return null
	if phase == "roundEnd" and phase_t >= 2600:
		if over:
			phase = "done"
			return "over"
		round_number += 1
		start_round()
		return "nextRound"
	return null

func end_round(value: Dictionary) -> String:
	outcome = value
	history.append(value)
	if value.winner != null:
		wins[int(value.winner) - 1] += 1
	phase = "roundEnd"
	phase_t = 0
	for i in 2:
		if wins[i] >= ceili(best_of / 2.0):
			over = true
			winner = i + 1
			return "roundEnd"
	if history.size() >= 9 and wins[0] != wins[1]:
		over = true
		winner = 1 if wins[0] > wins[1] else 2
	return "roundEnd"
