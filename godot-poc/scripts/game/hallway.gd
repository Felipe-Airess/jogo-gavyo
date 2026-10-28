extends Node2D
## Corredor da escola, 640×180 (port de art.js createArt). Desenhado uma vez.
const PixelFont = preload("res://scripts/game/pixel_font.gd")

func r(color: String, x: float, y: float, w: float, h: float) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))

func _draw() -> void:
	r("#252f30", 0, 0, 640, 180); r("#4f584a", 0, 24, 640, 64); r("#35493e", 0, 88, 640, 31)
	r("#8a8e6d", 0, 86, 640, 2); r("#202e2a", 0, 117, 640, 6)
	for x in range(16, 640, 160):
		r("#1d2b2c", x, 34, 112, 47); r("#7c8b7c", x + 3, 37, 106, 40); r("#929b84", x + 4, 38, 104, 13)
		for n in 8:
			var h := 9 + (n * 11) % 19
			r("#5e7268", x + 4 + n * 13, 77 - h, 12, h); r("#879381", x + 7 + n * 13, 81 - h, 2, 2)
		r("#3c5047", x + 3, 69, 106, 8); r("#293d36", x + 36, 36, 3, 43); r("#293d36", x + 73, 36, 3, 43); r("#293d36", x + 3, 55, 106, 2)
		r("#9b9e7a", x - 2, 80, 116, 3); r("#273932", x, 83, 113, 2)
		for n in 7:
			r("#778775", x + 7 + n * 15, 41 + (n * 7) % 27, 1, 6)
	for x in [139, 459]:
		r("#26342e", x, 35, 32, 84); r("#637257", x + 2, 38, 28, 79); r("#394f42", x + 5, 44, 22, 36); r("#1b302c", x + 7, 46, 18, 32)
		r("#929779", x + 25, 87, 2, 4); r("#929577", x - 2, 27, 36, 7)
		PixelFont.draw(self, "3 - B" if x == 139 else "3 - C", Vector2(x + 6, 28), Color("#263a33"))
	r("#202e28", 282, 43, 30, 32); r("#8b815e", 284, 45, 26, 28); r("#c2ba94", 287, 47, 20, 22)
	PixelFont.draw(self, "AVISO", Vector2(287, 49), Color("#4c5845")); PixelFont.draw(self, "O SINAL", Vector2(287, 57), Color("#4c5845")); PixelFont.draw(self, "FALTOU", Vector2(287, 63), Color("#4c5845"))
	r("#29392f", 263, 35, 11, 11); r("#b1b497", 264, 36, 9, 9); r("#475848", 268, 38, 1, 4); r("#475848", 268, 41, 3, 1)
	r("#576055", 0, 123, 640, 400)   # piso se estende para telas mais altas que 180
	for y in [125, 138, 155, 177]:
		r("#3c4b43", 0, y, 640, 1)
	for x in range(-100, 700, 42):
		for y in range(123, 180):
			r("#414e44", round(x + 25.0 * (180 - y) / 57.0), y, 1, 1)
	for n in 750:
		r("#646c59" if n % 3 else "#455347", (n * 73 + 11) % 640, 125 + (n * 31) % 54, 1, 1)
	r("#202d2b", 46, 111, 11, 9); r("#475447", 48, 108, 7, 11); r("#7d8061", 49, 111, 5, 1)
	r("#2c3d35", 389, 110, 10, 10); r("#7b8570", 389, 110, 10, 2); r("#546550", 391, 113, 6, 6)
	for n in 100:
		r("#455343", (n * 97) % 640, 91 + (n * 11) % 24, 1 + (n % 4), 1)
	for x in [0, 318, 638]:
		r("#263a32", x, 26, 2, 95)
