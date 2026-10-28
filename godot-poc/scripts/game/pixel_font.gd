extends RefCounted
## Fonte pixel 3×5 do jogo (port de art.js `lettering`). Desenha com retângulos.
const GLYPHS := {"A": "010101111101101", "B": "110101110101110", "C": "011100100100011", "D": "110101101101110", "E": "111100110100111",
	"F": "111100110100100", "G": "011100101101011", "H": "101101111101101", "I": "111010010010111", "J": "001001001101010",
	"K": "101101110101101", "L": "100100100100111", "M": "101111111101101", "N": "101111111111101", "O": "010101101101010",
	"P": "110101110100100", "Q": "010101101111011", "R": "110101110101101", "S": "011100010001110", "T": "111010010010010",
	"U": "101101101101111", "V": "101101101101010", "W": "101101111111101", "X": "101101010101101", "Y": "101101010010010",
	"Z": "111001010100111", "0": "111101101101111", "1": "010110010010111", "2": "110001010100111", "3": "110001010001110",
	"4": "101101111001001", "5": "111100110001110", "6": "011100111101111", "7": "111001010010010", "8": "111101111101111",
	"9": "111101111001110", ":": "000010000010000", ".": "000000000000010", "/": "001001010100100", "-": "000000111000000",
	"!": "010010010000010", "?": "110001010000010", "+": "000010111010000", "(": "010100100100010", ")": "010001001001010",
	">": "100010001010100", "<": "001010100010001"}
const ACCENTS := {"Á": "A", "À": "A", "Â": "A", "Ã": "A", "É": "E", "Ê": "E", "Í": "I", "Ó": "O", "Ô": "O", "Õ": "O", "Ú": "U", "Ç": "C"}

static func clean(text: String) -> String:
	var up := text.to_upper()
	var out := ""
	for ch in up:
		out += ACCENTS.get(ch, ch)
	return out

static func draw(ci: CanvasItem, text: String, pos: Vector2, color: Color, scale := 1.0) -> void:
	var t := clean(text)
	for i in t.length():
		var glyph: String = GLYPHS.get(t[i], "")
		if glyph.is_empty():
			continue
		for n in 15:
			if glyph[n] == "1":
				ci.draw_rect(Rect2(pos.x + (i * 4 + n % 3) * scale, pos.y + floor(n / 3.0) * scale, scale, scale), color)

static func width(text: String, scale := 1.0) -> float:
	return text.length() * 4 * scale

static func centered(ci: CanvasItem, text: String, center_x: float, y: float, color: Color, scale := 1.0) -> void:
	draw(ci, text, Vector2(round(center_x - text.length() * 2 * scale), y), color, scale)
