#!/usr/bin/env python3
"""Desenha a planta do térreo a partir do JSON de godot-3d/tools/exportar_planta.gd.

Uso:
  Godot --headless --path godot-3d --script res://tools/exportar_planta.gd -- planta.json
  python3 scripts/desenhar-planta.py planta.json planta.png

Legenda: paredes cinza-escuro, objetos baixos cinza, portas vermelhas, lâmpadas
amarelas, cultistas vermelhos, esconderijos roxos, pontos da história verdes.
"""
import json
import sys

from PIL import Image, ImageDraw

data = json.load(open(sys.argv[1]))
S = 14
OX, OZ = 42 * S, 32 * S
image = Image.new("RGB", (86 * S, 64 * S), (245, 245, 240))
draw = ImageDraw.Draw(image)


def at(x, z):
    return (x * S + OX, z * S + OZ)


for b in data["boxes"]:
    if b["y"] - b["h"] / 2 > 2.0 or b["h"] < 0.5 or b["w"] > 60:
        continue
    x0, z0 = at(b["x"] - b["w"] / 2, b["z"] - b["d"] / 2)
    x1, z1 = at(b["x"] + b["w"] / 2, b["z"] + b["d"] / 2)
    color = (200, 60, 60) if b["door"] else ((60, 60, 60) if b["h"] > 1.5 else (150, 150, 150))
    draw.rectangle([x0, z0, x1, z1], fill=color)
for lamp in data["lamps"]:
    if lamp[1] < 3:
        x, z = at(lamp[0], lamp[2])
        draw.ellipse([x - 4, z - 4, x + 4, z + 4], fill=(240, 190, 40))
for title, center in data["rooms"].items():
    if center[1] < 1:
        x, z = at(center[0], center[2])
        draw.text((x - 30, z), title[:22], fill=(20, 20, 160))
for name, point in data["marks"].items():
    x, z = at(point[0], point[2])
    draw.ellipse([x - 7, z - 7, x + 7, z + 7], fill=(0, 160, 0))
    draw.text((x + 9, z - 6), name, fill=(0, 110, 0))
for enemy in data["enemies"]:
    x, z = at(enemy[0], enemy[1])
    draw.ellipse([x - 6, z - 6, x + 6, z + 6], fill=(220, 0, 0))
for hide in data["hides"]:
    x, z = at(hide[0], hide[1])
    draw.rectangle([x - 5, z - 5, x + 5, z + 5], outline=(0, 0, 0), fill=(120, 0, 160))
image.save(sys.argv[2])
