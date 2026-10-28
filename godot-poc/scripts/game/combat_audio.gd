extends Node
## Sons curtos gerados no próprio jogo (port de combat-audio.mjs), sem arquivos:
## ruído com envelope e um tom grave, filtrados (passa-baixa; passa-alta no aparo).
const RATE := 22050
var enabled := true
var cache := {}
var players: Array = []

func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)

func make(kind: String) -> AudioStreamWAV:
	var duration := 0.12 if kind == "parry" else (0.035 if kind == "step" else 0.085)
	var tone := 1800.0 if kind == "parry" else (130.0 if kind == "step" else 85.0)
	var cutoff := 850.0 if kind == "parry" else (950.0 if kind == "guard" else (500.0 if kind == "step" else 1800.0))
	var high := kind == "parry"
	var n := int(ceil(RATE * duration))
	var data := PackedByteArray()
	data.resize(n * 2)
	var a := exp(-TAU * cutoff / RATE)
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		var env := pow(1.0 - float(i) / n, 3)
		var noise := sin(i * 127.1 + sin(i * 0.71) * 317.7)
		var x := (noise * 0.65 + sin(t * tone * TAU) * 0.35) * env
		low = (1.0 - a) * x + a * low
		var y := x - low if high else low
		data.encode_s16(i * 2, int(clampf(y * 0.9, -1, 1) * 32767))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.data = data
	return s

func play(kind: String, strength := 1.0) -> void:
	if not enabled: return
	if not cache.has(kind): cache[kind] = make(kind)
	var gain := (0.025 if kind == "step" else (0.045 if kind == "guard" else 0.09)) * strength
	for p in players:
		if not p.playing:
			p.stream = cache[kind]
			p.volume_db = linear_to_db(gain * 8.0)
			p.play()
			return
