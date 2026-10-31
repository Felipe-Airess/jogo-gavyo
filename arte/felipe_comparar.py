"""Comparacao lado a lado: foto do Felipe x render do modelo, mesma altura.

  python arte/felipe_comparar.py RENDERS SAIDA.png
  python arte/felipe_comparar.py --rosto RENDERS SAIDA.png

RENDERS: pasta com frente.png, lado.png, costas.png (fundo transparente) feita
por `felipe_humano.py -- --render`. A pessoa na foto e achada pela diferenca
para a parede/chao claros (cinza escuro, preto ou pele); a altura da foto vai
do topo do cabelo a sola do pe, igual ao render.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
ANG = os.path.join(AQUI, "referencias", "felipe", "angulos_principais")
PARES = [  # (foto, render, rotulo)
    ("frente_neutra_19.50s.jpg", "frente.png", "frente"),
    ("perfil_virado_esquerda_46.50s.jpg", "lado.png", "perfil"),
    ("costas_37.50s.jpg", "costas.png", "costas"),
]
ALTURA = 900


def caixa_foto(im):
    """Caixa da pessoa: pixels escuros ou de pele, longe da mochila (canto esq.)."""
    a = np.asarray(im, np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    pele = (r - b > 35) & (r > g) & (lum < 200)
    m = (lum < 95) | pele
    h, w = m.shape
    m[:, : int(w * 0.28)] = False  # mochila e roupa empilhada no canto
    cols = np.where(m.sum(0) > h * 0.02)[0]
    x0, x1 = cols.min(), cols.max()
    sub = m[:, x0:x1 + 1]
    rows = np.where(sub.sum(1) > 3)[0]
    return x0, rows.min(), x1, rows.max()


def caixa_render(im):
    a = np.asarray(im)[..., 3]
    ys, xs = np.where(a > 10)
    return xs.min(), ys.min(), xs.max(), ys.max()


def ajustar(im, caixa, fundo):
    x0, y0, x1, y1 = caixa
    pad = int((y1 - y0) * 0.06)
    cx = (x0 + x1) // 2
    lado = int((y1 - y0) * 0.33) + pad
    caixa = (cx - lado, y0 - pad, cx + lado, y1 + pad)
    if im.mode == "RGB":  # fora da foto: branco, nao preto
        rec = Image.new("RGB", (caixa[2] - caixa[0], caixa[3] - caixa[1]), (235, 235, 232))
        rec.paste(im, (-caixa[0], -caixa[1]))
    else:
        rec = im.crop(caixa)
    k = ALTURA / (y1 - y0)
    rec = rec.resize((int(rec.width * k), int(rec.height * k)), Image.LANCZOS)
    if rec.mode == "RGBA":
        bg = Image.new("RGB", rec.size, fundo)
        bg.paste(rec, (0, 0), rec)
        rec = bg
    return rec


FOTOS = os.path.join(AQUI, "referencias", "felipe", "fotos_originais")
ROSTOS = [  # (foto, caixa na foto, render, espelhar render)
    ("36554.jpg", (150, 300, 1050, 1200), "rosto.png", False),
    ("36555.jpg", (150, 300, 1050, 1200), "rosto_34.png", False),
    ("36560.jpg", (250, 300, 1150, 1200), "rosto_lado.png", True),
]


def comparar_rostos(pasta, saida, lado=600):
    """Fotos do rosto em cima, renders do modelo embaixo."""
    from PIL import ImageOps
    out = Image.new("RGB", (lado * len(ROSTOS), lado * 2), (205, 205, 200))
    for i, (foto, caixa, render, esp) in enumerate(ROSTOS):
        f = Image.open(os.path.join(FOTOS, foto)).convert("RGB").crop(caixa).resize((lado, lado))
        r = Image.open(os.path.join(pasta, render)).convert("RGBA").resize((lado, lado))
        if esp:
            r = ImageOps.mirror(r)
        out.paste(f, (lado * i, 0))
        out.paste(r, (lado * i, lado), r)
    out.save(saida)


def main():
    if sys.argv[1] == "--rosto":
        comparar_rostos(sys.argv[2], sys.argv[3])
        return
    pasta, saida = sys.argv[1], sys.argv[2]
    blocos = []
    for foto, render, rot in PARES:
        f = Image.open(os.path.join(ANG, foto)).convert("RGB")
        r = Image.open(os.path.join(pasta, render)).convert("RGBA")
        a = ajustar(f, caixa_foto(f), None)
        b = ajustar(r, caixa_render(r), (205, 205, 200))
        blocos.append((rot, a, b))
    w = sum(a.width + b.width + 20 for _, a, b in blocos)
    h = max(a.height for _, a, _ in blocos) + 30
    out = Image.new("RGB", (w, h), (255, 255, 255))
    d = ImageDraw.Draw(out)
    x = 0
    for rot, a, b in blocos:
        out.paste(a, (x, 30))
        out.paste(b, (x + a.width, 30))
        d.text((x + 6, 8), "%s: foto | modelo" % rot, fill=(0, 0, 0))
        x += a.width + b.width + 20
    out.save(saida)


if __name__ == "__main__":
    main()
