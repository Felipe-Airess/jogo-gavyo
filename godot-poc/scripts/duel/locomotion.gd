extends RefCounted
## Port de src/locomotion.mjs (parte usada pelo duelo).
## Passadas medidas nos pés do lote 2: corrida ~112 px por ciclo, andar ~76.
const R2_STRIDE := {"run": 112.0, "walk": 76.0}

## Tabela de avanço por quadro: quanto o pé apoiado recua de um quadro ao seguinte.
static func gait_table(frames: Array) -> Dictionary:
	var step: Array = []
	for i in frames.size():
		var a: Array = frames[i].feet.filter(func(p): return float(p.tipY) >= -5)
		var b: Array = frames[(i + 1) % frames.size()].feet.filter(func(p): return float(p.tipY) >= -5)
		var best: Variant = null
		for p in a:
			for q in b:
				var dx: float = float(p.tipX) - float(q.tipX)
				if dx >= 0 and dx < 24 and (best == null or absf(dx - 9) < absf(best - 9)):
					best = dx
		step.append(best)
	var known: Array = step.filter(func(v): return v != null)
	var mean := 8.0
	if not known.is_empty():
		var sum := 0.0
		for v in known:
			sum += v
		mean = sum / known.size()
	var start: Array = []
	var total := 0.0
	for v in step:
		start.append(total)
		total += mean if v == null else v
	return {"start": start, "stride": total}

static func table_frame(table: Dictionary, distance: float) -> int:
	var stride: float = table.stride
	var phase := fmod(fmod(distance, stride) + stride, stride)
	var i: int = table.start.size() - 1
	while i > 0 and table.start[i] > phase:
		i -= 1
	return i
