"""Folhas de comparação foto × antes × depois para a revisão do Miguel v2.

  python3 arte/miguel_v2_folha.py REVISAO_DIR [--so-antes]

Lê REVISAO_DIR/antes e REVISAO_DIR/depois (saídas de miguel_v2_vistas.py)
e grava corpo.png, rosto.png e jogo.png em REVISAO_DIR. As fotos têm
perspectiva e outra pose/luz: servem para leitura visual, não medição 3D.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
REF = ROOT / "referencias/miguel"
FUNDO = (226, 228, 230)


def abrir(p, caixa, alvo):
    im = Image.open(p).convert("RGBA")
    if caixa:
        im = im.crop(caixa)
    bg = Image.new("RGBA", im.size, FUNDO + (255,))
    im = Image.alpha_composite(bg, im).convert("RGB")
    im.thumbnail(alvo, Image.Resampling.LANCZOS)
    tela = Image.new("RGB", alvo, FUNDO)
    tela.paste(im, ((alvo[0] - im.width) // 2, (alvo[1] - im.height) // 2))
    return tela


def folha(linhas, colunas_nomes, alvo, saida):
    w, h = alvo
    s = Image.new("RGB", (w * len(colunas_nomes), (h + 22) * len(linhas) + 26), (250, 250, 250))
    d = ImageDraw.Draw(s)
    for j, n in enumerate(colunas_nomes):
        d.text((j * w + 6, 6), n, fill=(10, 10, 10))
    for i, (rotulo, celulas) in enumerate(linhas):
        y = 26 + i * (h + 22)
        d.text((6, y + 2), rotulo, fill=(120, 0, 0))
        for j, c in enumerate(celulas):
            if c is None:
                continue
            caminho, caixa = c
            if Path(caminho).exists():
                s.paste(abrir(caminho, caixa, alvo), (j * w, y + 20))
    s.save(saida)
    print("FOLHA", saida)


def main():
    rev = Path(sys.argv[1])
    a, dp = rev / "antes", rev / "depois"
    so_antes = "--so-antes" in sys.argv
    cols = ["foto", "aprovado (antes)"] + ([] if so_antes else ["v2 (depois)"])

    def lin(rotulo, foto, caixa, nome):
        cel = [(REF / foto, caixa) if foto else None, (a / nome, None)]
        if not so_antes:
            cel.append((dp / nome, None))
        return (rotulo, cel)

    folha([lin("frente", "corpo_frente2.jpg", (330, 150, 1170, 1950), "frente.png"),
           lin("lado", "guarda_lado.jpg", (300, 150, 1140, 1950), "lado.png"),
           lin("costas", "camisa_costas.jpg", None, "costas.png"),
           lin("3/4", "camisa_frente.jpg", None, "tres_quartos.png")],
          cols, (330, 520), rev / ("corpo-antes.png" if so_antes else "corpo.png"))
    folha([lin("rosto", "rosto_frente4.jpg", (300, 280, 1260, 1240), "rosto.png"),
           lin("3/4", "perfil_esq2.jpg", (100, 0, 1260, 1160), "rosto_34.png"),
           lin("perfil", "perfil_dir2.jpg", (0, 100, 1300, 1400), "rosto_lado.png"),
           lin("nuca", "cabeca_costas.jpg", None, "nuca.png")],
          cols, (420, 420), rev / ("rosto-antes.png" if so_antes else "rosto.png"))
    # Escala do jogo: 160 px de altura, ampliado sem suavizar.
    lin_j = []
    for nome in ("jogo_frente.png", "jogo_34.png"):
        cel = []
        for pasta in ([a] if so_antes else [a, dp]):
            p = pasta / nome
            if p.exists():
                im = Image.open(p).convert("RGBA")
                bg = Image.new("RGBA", im.size, (40, 42, 48, 255))
                Image.alpha_composite(bg, im).convert("RGB").resize(
                    (im.width * 3, im.height * 3), Image.Resampling.NEAREST).save(pasta / ("x3_" + nome))
                cel.append((pasta / ("x3_" + nome), None))
        lin_j.append((nome[:-4], [None] + cel))
    folha(lin_j, cols, (300, 490), rev / ("jogo-antes.png" if so_antes else "jogo.png"))


if __name__ == "__main__":
    main()
