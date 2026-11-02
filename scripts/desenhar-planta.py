#!/usr/bin/env python3
"""Desenha a planta de cima do capítulo 1 a partir do JSON de
godot-3d/tools/exportar_planta.gd (grades ASCII + o que o jogo montou).

Uso:
  Godot --headless --path godot-3d --script res://tools/exportar_planta.gd -- planta.json
  python3 scripts/desenhar-planta.py planta.json planta.png

Térreo em cima, andar superior embaixo (com o térreo apagado por baixo).
Coordenadas = coluna/linha da grade (1 célula = 1 m). Contorno magenta fino =
colisão que o jogo realmente montou (deve coincidir com as paredes do texto).
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

data = json.load(open(sys.argv[1]))
saida = sys.argv[2]


def fonte(tamanho, negrito=False):
    nomes = ["DejaVuSans-Bold.ttf" if negrito else "DejaVuSans.ttf"]
    for pasta in ["/usr/share/fonts/truetype/dejavu", "/Library/Fonts", "/System/Library/Fonts/Supplemental"]:
        for nome in nomes + ["Arial.ttf"]:
            caminho = os.path.join(pasta, nome)
            if os.path.exists(caminho):
                return ImageFont.truetype(caminho, tamanho)
    try:
        return ImageFont.load_default(size=tamanho)
    except TypeError:
        return ImageFont.load_default()


F_PEQ, F_MED, F_GRD, F_TIT = fonte(10), fonte(12), fonte(14, True), fonte(20, True)

PISO = {".": (232, 232, 226), ";": (214, 208, 192), ",": (244, 247, 238), ":": (204, 226, 212), "_": (196, 184, 160)}
PAREDE = "#-DWOG"
RETAS = "DWOG"
SETAS = {"<": (-1, 0), ">": (1, 0), "^": (0, -1), "v": (0, 1)}


class Grade:
    def __init__(self, g):
        self.l = g["linhas"]
        self.h = len(self.l)
        self.w = max(len(x) for x in self.l)

    def ch(self, c, r):
        if r < 0 or r >= self.h or c < 0 or c >= len(self.l[r]):
            return " "
        return self.l[r][c]

    def parede(self, c, r):
        return self.ch(c, r) in PAREDE and self.ch(c, r) != " "

    def piso(self, c, r):
        s = self.ch(c, r)
        if s == " ":
            return None
        if s in PISO:
            return s
        conta = {}
        for raio in (1, 2):
            for dr in range(-raio, raio + 1):
                for dc in range(-raio, raio + 1):
                    v = self.ch(c + dc, r + dr)
                    if v in ".,;:":
                        conta[v] = conta.get(v, 0) + 1
            if conta:
                break
        return max(conta, key=conta.get) if conta else "."

    def eixo(self, c, r):
        s = self.ch(c, r)
        x = self.parede(c - 1, r) or self.parede(c + 1, r)
        z = self.parede(c, r - 1) or self.parede(c, r + 1)
        if x and z:
            x = self.ch(c - 1, r) == s or self.ch(c + 1, r) == s
        return "x" if x else "z"

    def bracos(self, c, r):
        out = []
        for d in ((1, 0), (0, 1), (-1, 0), (0, -1)):
            n = (c + d[0], r + d[1])
            s = self.ch(*n)
            if s == " " or s not in PAREDE:
                continue
            if s in RETAS and self.eixo(*n) != ("x" if d[1] == 0 else "z"):
                continue
            out.append(d)
        return out


def desenhar_andar(img, draw, g, ox, oy, S, fundo=None, titulo=""):
    W, H = g.w, g.h

    def px(x, z):
        return (ox + x * S, oy + z * S)

    draw.text((ox, oy - 34), titulo, fill=(20, 20, 20), font=F_TIT)
    # fundo: térreo apagado (no painel do andar de cima)
    if fundo is not None:
        for r in range(min(H, fundo.h)):
            for c in range(min(W, fundo.w)):
                if fundo.parede(c, r):
                    x0, y0 = px(c, r)
                    draw.rectangle([x0 + S * .35, y0 + S * .35, x0 + S * .65, y0 + S * .65], fill=(220, 220, 220))
    # pisos
    for r in range(H):
        for c in range(W):
            p = g.piso(c, r)
            if p is None:
                continue
            x0, y0 = px(c, r)
            draw.rectangle([x0, y0, x0 + S - 1, y0 + S - 1], fill=PISO.get(p, (230, 230, 230)))
    # grade de 1 m e 5 m
    for c in range(W + 1):
        cor = (150, 150, 150) if c % 5 == 0 else (225, 225, 225)
        if c % 5 == 0 or S >= 14:
            draw.line([px(c, 0), px(c, H)], fill=cor, width=1)
        if c % 5 == 0:
            draw.text((px(c, 0)[0] - 6, oy - 14), str(c), fill=(90, 90, 90), font=F_PEQ)
    for r in range(H + 1):
        cor = (150, 150, 150) if r % 5 == 0 else (225, 225, 225)
        if r % 5 == 0 or S >= 14:
            draw.line([px(0, r), px(W, r)], fill=cor, width=1)
        if r % 5 == 0:
            draw.text((ox - 24, px(0, r)[1] - 6), str(r), fill=(90, 90, 90), font=F_PEQ)
    # volumes
    for r in range(H):
        for c in range(W):
            s = g.ch(c, r)
            x0, y0 = px(c, r)
            cx, cy = x0 + S / 2, y0 + S / 2
            if s == "%":
                draw.rectangle([x0 + 1, y0 + 1, x0 + S - 2, y0 + S - 2], fill=(176, 136, 96), outline=(120, 90, 60))
            elif s == "C":
                draw.rectangle([cx - S * .22, cy - S * .22, cx + S * .22, cy + S * .22], fill=(60, 60, 60))
            elif s == "T":
                draw.ellipse([cx - S * 3, cy - S * 3, cx + S * 3, cy + S * 3], outline=(60, 140, 60), width=2)
                draw.ellipse([cx - S * .35, cy - S * .35, cx + S * .35, cy + S * .35], fill=(90, 70, 50))
            elif s in SETAS:
                d = SETAS[s]
                a = (cx + d[0] * S * .35, cy + d[1] * S * .35)
                b1 = (cx - d[0] * S * .3 - d[1] * S * .3, cy - d[1] * S * .3 + d[0] * S * .3)
                b2 = (cx - d[0] * S * .3 + d[1] * S * .3, cy - d[1] * S * .3 - d[0] * S * .3)
                draw.rectangle([x0, y0, x0 + S - 1, y0 + S - 1], fill=(205, 200, 230))
                draw.polygon([a, b1, b2], fill=(80, 60, 160))
    # paredes
    t = max(2, int(S * .2))
    for r in range(H):
        for c in range(W):
            s = g.ch(c, r)
            if s not in PAREDE or s == " ":
                continue
            x0, y0 = px(c, r)
            cx, cy = x0 + S / 2, y0 + S / 2
            if s in "#-":
                cor = (35, 35, 35) if s == "#" else (120, 120, 120)
                larg = t if s == "#" else max(2, t - 1)
                draw.rectangle([cx - larg / 2, cy - larg / 2, cx + larg / 2, cy + larg / 2], fill=cor)
                for d in g.bracos(c, r):
                    ex, ey = cx + d[0] * S / 2, cy + d[1] * S / 2
                    draw.line([(cx, cy), (ex, ey)], fill=cor, width=larg)
                continue
            ax = g.eixo(c, r) == "x"
            a = (x0, cy) if ax else (cx, y0)
            b = (x0 + S, cy) if ax else (cx, y0 + S)
            if s == "D":
                draw.line([a, b], fill=(200, 40, 40), width=t + 2)
            elif s == "W":
                draw.line([a, b], fill=(35, 35, 35), width=t)
                draw.line([a, b], fill=(110, 160, 230), width=max(1, t - 2))
            elif s == "O":
                draw.line([a, b], fill=(235, 140, 30), width=2)
            elif s == "G":
                draw.line([a, b], fill=(30, 130, 60), width=t + 3)
    # colisões montadas pelo jogo (devem cobrir as paredes desenhadas)
    for b in data["boxes"]:
        if b["nome"] in ("Chao", "Laje", "Telhado") or b["door"]:
            continue
        base = b["y"] - b["h"] / 2
        superior = titulo.startswith("ANDAR")
        if superior and not (3.3 <= base < 5.4):
            continue
        if not superior and base >= 2.0:
            continue  # vergas, lajes e telhados
        x0, y0 = px(b["x"] - b["w"] / 2, b["z"] - b["d"] / 2)
        x1, y1 = px(b["x"] + b["w"] / 2, b["z"] + b["d"] / 2)
        draw.rectangle([x0, y0, x1, y1], outline=(220, 0, 200), width=1)


def marcas(draw, andar, ox, oy, S):
    def px(x, z):
        return (ox + x * S, oy + z * S)

    for nome, info in data["salas"].items():
        x, z, a = info["rotulo"]
        if a != andar:
            continue
        f = F_MED if info["sala"] else F_GRD
        cor = (20, 30, 140) if info["sala"] else (90, 90, 90)
        rx, rz, rw, rh = info["rect"]
        # Nome dentro da sala: centro do retângulo, quebrado pela largura.
        cx, cy = px(rx + rw / 2, rz + rh / 2) if info["sala"] else px(x + .5, z + .5)
        limite = max(rw * S - 4, 40) if info["sala"] else 400
        linhas, atual = [], ""
        for palavra in nome.replace(" · ", " ").split(" "):
            teste = (atual + " " + palavra).strip()
            if atual and draw.textlength(teste, font=f) > limite:
                linhas.append(atual)
                atual = palavra
            else:
                atual = teste
        linhas.append(atual)
        alt = 13 if f == F_MED else 16
        for i, linha in enumerate(linhas):
            tw = draw.textlength(linha, font=f)
            draw.text((cx - tw / 2, cy - alt * len(linhas) / 2 + i * alt), linha, fill=cor, font=f)
    for p in data["portas"]:
        x, z, a, titulo, nx, nz = p
        if a != andar:
            continue
        cx, cy = px(x, z)
        draw.line([(cx, cy), (cx + nx * S * .6, cy + nz * S * .6)], fill=(200, 40, 40), width=1)
    for lamp in data["lampadas"]:
        if lamp[2] != andar:
            continue
        cx, cy = px(lamp[0], lamp[1])
        draw.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(240, 190, 40), outline=(150, 110, 0))
    for h in data["esconderijos"]:
        if h[2] != andar:
            continue
        cx, cy = px(h[0], h[1])
        draw.rectangle([cx - 5, cy - 5, cx + 5, cy + 5], fill=(130, 40, 170), outline=(0, 0, 0))
        draw.line([(cx, cy), (cx + h[3] * 10, cy + h[4] * 10)], fill=(130, 40, 170), width=2)
    for i, pst in enumerate(data["postos"]):
        if pst[2] != andar:
            continue
        cx, cy = px(pst[0], pst[1])
        rv = data["visao"] * S
        draw.ellipse([cx - rv, cy - rv, cx + rv, cy + rv], outline=(230, 120, 120), width=1)
        draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(210, 20, 20))
        draw.text((cx - 3, cy - 7), str(i + 1), fill=(255, 255, 255), font=F_MED)
    if andar == 0:
        for nome, cor in (("norte", (40, 90, 220)), ("sul", (230, 120, 20))):
            pts = [px(x, z) for x, z in data["rotas"][nome]]
            draw.line(pts, fill=cor, width=3)
            draw.text((pts[0][0] + 6, pts[0][1] - 18), "rota " + nome, fill=cor, font=F_GRD)
    for item in data["itens"]:
        if item[2] != andar:
            continue
        cx, cy = px(item[0], item[1])
        draw.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(40, 40, 40))
        draw.text((cx + 4, cy - 5), item[3], fill=(60, 60, 60), font=F_PEQ)
    for nome, m in data["marcas"].items():
        x, z, a = m
        if a != andar and not nome.startswith("escada"):
            continue
        if nome.startswith("escada") and ((nome.endswith("(topo)")) != (andar == 1)):
            continue
        cx, cy = px(x, z)
        cor = (200, 0, 0) if nome == "ritual" else (0, 140, 60)
        draw.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=cor, outline=(0, 0, 0))
        draw.text((cx + 9, cy - 8), nome.upper(), fill=cor, font=F_GRD)


def legenda(draw, x, y):
    itens = [
        ("parede", lambda d, a, b: d.line([a, b], fill=(35, 35, 35), width=3)),
        ("meia-parede / mureta", lambda d, a, b: d.line([a, b], fill=(120, 120, 120), width=2)),
        ("porta (DD)", lambda d, a, b: d.line([a, b], fill=(200, 40, 40), width=5)),
        ("janela gradeada", lambda d, a, b: d.line([a, b], fill=(110, 160, 230), width=3)),
        ("vão aberto com verga", lambda d, a, b: d.line([a, b], fill=(235, 140, 30), width=2)),
        ("portão de grade", lambda d, a, b: d.line([a, b], fill=(30, 130, 60), width=5)),
        ("bloco baixo (cobertura)", lambda d, a, b: d.rectangle([a[0], a[1] - 5, a[0] + 10, a[1] + 5], fill=(176, 136, 96))),
        ("armário (esconderijo)", lambda d, a, b: d.rectangle([a[0], a[1] - 5, a[0] + 10, a[1] + 5], fill=(130, 40, 170))),
        ("posto de cultista + visão 10,5 m", lambda d, a, b: d.ellipse([a[0], a[1] - 6, a[0] + 12, a[1] + 6], fill=(210, 20, 20))),
        ("lâmpada", lambda d, a, b: d.ellipse([a[0], a[1] - 3, a[0] + 6, a[1] + 3], fill=(240, 190, 40))),
        ("escada (seta = sobe)", lambda d, a, b: d.polygon([(a[0], a[1]), (a[0] + 10, a[1] - 5), (a[0] + 10, a[1] + 5)], fill=(80, 60, 160))),
        ("colisão montada no jogo", lambda d, a, b: d.rectangle([a[0], a[1] - 5, a[0] + 22, a[1] + 5], outline=(220, 0, 200))),
    ]
    pisos = [("azulejo, coberto  .", "."), ("cimento, coberto  ;", ";"), ("céu aberto  ,", ","), ("quadra coberta  :", ":"), ("palco  _", "_")]
    draw.rectangle([x - 10, y - 10, x + 330, y + 22 * (len(itens) + len(pisos)) + 30], fill=(255, 255, 255), outline=(120, 120, 120))
    draw.text((x, y - 4), "LEGENDA (1 quadrado = 1 m)", fill=(0, 0, 0), font=F_GRD)
    yy = y + 24
    for nome, f in itens:
        f(draw, (x, yy + 6), (x + 24, yy + 6))
        draw.text((x + 34, yy - 1), nome, fill=(0, 0, 0), font=F_MED)
        yy += 22
    for nome, s in pisos:
        draw.rectangle([x, yy, x + 22, yy + 12], fill=PISO[s], outline=(150, 150, 150))
        draw.text((x + 34, yy - 1), nome, fill=(0, 0, 0), font=F_MED)
        yy += 22


terreo = Grade(data["grades"][0])
superior = Grade(data["grades"][1])
S = 13
S2 = 22
M = 50
# Andar superior: só o retângulo ocupado.
ucols = max((c for r in range(superior.h) for c in range(superior.w) if superior.ch(c, r) != " "), default=0) + 2
urows = superior.h + 1
largura = max(M * 2 + terreo.w * S, M * 2 + ucols * S2 + 360)
altura = M + 40 + terreo.h * S + 80 + max(urows * S2, 460) + M
img = Image.new("RGB", (largura, altura), (252, 252, 250))
draw = ImageDraw.Draw(img)
oy0 = M + 40
desenhar_andar(img, draw, terreo, M, oy0, S, titulo="TÉRREO  (godot-3d/capitulo1/mapa/terreo.txt)")
marcas(draw, 0, M, oy0, S)
oy1 = oy0 + terreo.h * S + 80
cortado = Grade({"linhas": [l[:ucols] for l in superior.l]})
desenhar_andar(img, draw, cortado, M, oy1, S2, fundo=terreo, titulo="ANDAR SUPERIOR +3,4 m  (superior.txt)")
marcas(draw, 1, M, oy1, S2)
legenda(draw, M + ucols * S2 + 60, oy1)
if data.get("avisos"):
    draw.text((M, altura - 30), "AVISOS DO MAPA: " + " | ".join(data["avisos"]), fill=(200, 0, 0), font=F_MED)
img.save(saida)
print("planta", saida, img.size)
