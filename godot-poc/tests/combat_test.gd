extends SceneTree
const Combat = preload("res://scripts/combat.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func fresh():
	var c = Combat.new()
	c.ai_enabled = false
	c.fighters[0].x = 140.0
	c.fighters[1].x = 180.0
	return c

func advance(c, seconds: float, axis: float = 0, guard: bool = false) -> void:
	for tick in ceili(seconds * 60.0):
		c.step(1.0 / 60.0, axis, guard)

func _initialize() -> void:
	var c = fresh()
	check(c.command(0, "jab"), "jab starts")
	check(not c.command(0, "cross"), "no attack cancel during startup")
	advance(c, 0.15)
	check(c.fighters[1].hp == 100, "no damage before measured active frame")
	advance(c, 0.65)
	check(c.fighters[1].hp == 93, "one jab deals one hit, not one per active frame")
	c = fresh()
	c.fighters[1].x = 260.0
	c.command(0, "cross")
	advance(c, 1.0)
	check(c.fighters[1].hp == 100, "out of range misses")
	c = fresh()
	c.fighters[1].guard = true
	c.fighters[1].state = "guard"
	c.fighters[1].clip = "block"
	c.command(0, "cross")
	# Stop at first active frame so guard is held independently of AI.
	for tick in 35:
		c.fighters[1].guard = true
		c.step(1.0 / 60.0)
	check(c.fighters[1].hp == 100, "front guard prevents health damage")
	check(c.fighters[1].stamina < 100, "guard impact spends stamina")
	c = fresh()
	c.fighters[0].stamina = 0.0
	check(not c.command(0, "cross"), "exhausted attack rejected")
	check(not c.command(0, "dodge"), "exhausted dodge rejected")
	c = fresh()
	c.command(1, "jab")
	advance(c, 0.8)
	check(c.fighters[0].hp == 93, "mirrored jab hits from the right")
	c = fresh()
	c.command(0, "dodge")
	c.command(1, "jab")
	advance(c, 0.8)
	check(c.fighters[0].hp == 100, "retreat evades by moving out of range")
	check(c.fighters[0].x < 115, "retreat moves backwards")
	c = fresh()
	c.fighters[0].x = 26.0
	c.command(0, "dodge")
	advance(c, 0.4)
	check(c.fighters[0].x == 26.0, "retreat stops at wall")
	c = fresh()
	advance(c, 10.0, 1.0)
	check(c.fighters[1].x - c.fighters[0].x >= 25.99, "bodies cannot cross")
	check(c.fighters[1].x <= 294, "push cannot move defender past wall")
	c = fresh()
	c.fighters[1].hp = 1.0
	c.command(0, "cross")
	advance(c, 1.0)
	check(c.result == "Você venceu", "health depletion ends match")
	var saved: float = c.time
	advance(c, 1.0)
	check(c.time == saved, "KO freezes simulation")
	check(not c.command(1, "jab"), "KO rejects attack")
	c.reset()
	check(c.result == "" and c.fighters[1].hp == 100 and c.hitstop == 0, "reset clears combat state")
	c = fresh()
	c.fighters[0].state = "jab"
	c.fighters[0].clip = "r3_jab_head"
	c.fighters[0].frame = 4
	c.data.markers.r3_jab_head[4].erase("frontFist")
	check(not c.hitbox(0).has_area(), "missing marker has no invented box")
	var a = Combat.new()
	var b = Combat.new()
	advance(a, 20.0)
	advance(b, 20.0)
	check(a.fighters == b.fighters and a.result == b.result, "AI replay deterministic")
	print("Combat: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
