"""Lote 4 do Miguel: folha única do ChatGPT -> quadros 128x96 do jogo.

Uso: python scripts/miguel-lote4/extrair.py
Fonte: arte/personagens/miguel/lote4/fontes/pacote2.png (1536x1024, títulos dentro).
Células: scripts/miguel-lote4/celulas.json (corte no vale da silhueta entre figuras).
Saída: arte/personagens/miguel/lote4/<anim>/NN.png + relatorio.json + revisao.png

Correções técnicas (nada é redesenhado):
- fundo magenta e "vazamento" rosa nas bordas, braços e camisa (despill);
- pedaços da figura vizinha que caem na célula;
- escala única pela guarda (66 px), igual ao lote 3; quadros desenhados
  maiores (chute alto 6-7) voltam à escala pelo tamanho da cabeça;
- alinhamento pelo tronco, pé no chão em y = 88;
- paleta do lote 3 (as cores do jogo), alfa binário;
- quadros repetidos ou com erro de anatomia ficam fora (FORA) e são listados.
"""
import json, os, glob
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = f'{ROOT}/arte/personagens/miguel/lote4/fontes/pacote2.png'
OUT = f'{ROOT}/arte/personagens/miguel/lote4'
CELLS = json.load(open(f'{ROOT}/scripts/miguel-lote4/celulas.json'))
TARGET_H, PIV = 66, (64, 88)

# Quadros fora (1-based, na ordem desenhada) e o motivo.
FORA = {
    'kickHigh': {12: 'guarda repetida (13 desenhados para 12)'},
}
def shirt_x(a):
    """Centro da camisa (branco/cinza claro e verde da faixa): o tronco sem os braços."""
    rgb = a[..., :3].astype(int); op = a[..., 3] > 0
    white = (rgb.min(2) > 150) & (rgb.max(2) - rgb.min(2) < 45)
    green = (rgb[..., 1] > rgb[..., 0] + 25) & (rgb[..., 1] > rgb[..., 2] + 5)
    m = op & (white | green)
    return np.nonzero(m)[1].mean() if m.sum() > 20 else np.nonzero(op)[1].mean()


# Quadros desenhados maiores que os vizinhos: voltam à escala pela cabeça.
BIGGER = {}   # chute alto 6-7 parecem maiores, mas a altura medida (92 px x 86) é a da perna de apoio esticada
# Animações com erro de anatomia/direção: extraídas para conferência, mas
# marcadas para refazer (não entram no jogo).
REFAZER = {
    'hitHeadHeavy': 'quadros 2-3 viram de frente para a câmera',
    'leanBack': 'quadros 2-3 mostram as costas',
    'fall': 'figuras deitadas encostadas umas nas outras na folha (4-6 não se separam)',
    'rise': 'figuras sobrepostas na folha (3-7 não se separam)',
    'run': 'pernas não alternam (mesma perna na frente), quadro 1 com joelho quase no chão',
}

sheet = np.array(Image.open(SRC).convert('RGB')).astype(int)
mag_d = np.sqrt(((sheet - [255, 0, 255]) ** 2).sum(2))


def cut(box):
    x0, y0, x1, y1 = box
    rgb = sheet[y0:y1, x0:x1].copy(); d = mag_d[y0:y1, x0:x1]
    al = d > 150
    # despill: tira o excesso de magenta (vermelho e azul acima do verde)
    g = rgb[..., 1]; m = np.minimum(rgb[..., 0], rgb[..., 2]); ex = np.clip(m - g, 0, None)
    k = np.where(d < 260, 1.0, 0.7)[..., None]
    rgb[..., 0] -= (ex * k[..., 0]).astype(int); rgb[..., 2] -= (ex * k[..., 0]).astype(int)
    # camisa com realce rosa/pêssego do contato: claro e pouco saturado vira cinza
    # claro com a mesma luminância (pele tem azul bem abaixo de 140, não entra)
    light = (rgb.min(2) > 140) & (rgb.max(2) - rgb.min(2) < 90)
    lum = (rgb * [0.3, 0.59, 0.11]).sum(2)
    rgb[light] = np.stack([lum[light]] * 3, 1).astype(int)
    # números e texto brancos soltos no topo
    lab, n = ndimage.label(al, structure=np.ones((3, 3)))
    if n > 1:
        sz = ndimage.sum(al, lab, range(1, n + 1)); main = int(np.argmax(sz)) + 1
        grown = ndimage.binary_dilation(lab == main, iterations=3)
        for i, z in enumerate(sz, 1):
            if i != main and (z < 0.02 * sz[main - 1] or not (grown & (lab == i)).any()): al[lab == i] = False
    ys, xs = np.nonzero(al)
    rgb = rgb[ys.min():ys.max() + 1, xs.min():xs.max() + 1]; al = al[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    return np.dstack([np.clip(rgb, 0, 255), al * 255]).astype(np.uint8)


def head_w(a):
    """Largura do cabelo (pixels escuros no quinto de cima): régua da escala."""
    al = a[..., 3] > 0; h = al.shape[0]; top = a[: max(4, h // 5)]
    dark = (top[..., :3].astype(int).sum(2) < 260) & (top[..., 3] > 0)
    xs = np.nonzero(dark.any(0))[0]
    return (xs.max() - xs.min() + 1) if len(xs) else None


# Escala: cada linha da folha saiu num tamanho (guarda de 85 a 98 px). A guarda
# do quadro 1 de cada animação vira 66 px; animações que não começam em guarda
# usam a guarda de uma vizinha da mesma linha.
REF_ANIM = {'run': 'walkFwd', 'runStop': 'runStart', 'fall': 'kickHigh', 'lying': 'kickHigh', 'rise': 'kickHigh'}
def scale_of(name):
    a = cut(CELLS[REF_ANIM.get(name, name)][0]); return TARGET_H / a.shape[0], head_w(a)

# paleta: cores do lote 3 (o que já está no jogo)
lote3 = [np.array(Image.open(p).convert('RGBA')) for p in glob.glob(f'{ROOT}/arte/personagens/miguel/lote3/m3_idle/*.png')]
px = np.concatenate([a[..., :3][a[..., 3] > 0] for a in lote3])
pal = Image.fromarray(px.reshape(-1, 1, 3)).quantize(colors=48, method=Image.Quantize.MEDIANCUT)

# Cor: o lote 4 saiu mais escuro (pele e cabelo) que o lote 3. Casamento de
# histograma por canal, das cores da guarda do lote 4 para as da guarda do
# lote 3, aplicado antes da paleta — muda só a cor, não o desenho.
def _cdf(v):
    h = np.bincount(v.ravel(), minlength=256).astype(float); c = np.cumsum(h); return c / c[-1]
_src = cut(CELLS['walkFwd'][0])
_s_rgb = np.array(Image.fromarray(_src).resize((round(_src.shape[1] * TARGET_H / _src.shape[0]), TARGET_H), Image.BOX))
_s_px = _s_rgb[..., :3][_s_rgb[..., 3] >= 128]
LUT = []
for ch in range(3):
    cs, cr = _cdf(_s_px[:, ch]), _cdf(px[:, ch])
    LUT.append(np.searchsorted(cr, cs).clip(0, 255).astype(np.uint8))
def match(rgb):
    return np.stack([LUT[c][rgb[..., c]] for c in range(3)], -1)

report, review = {}, []
for name, boxes in CELLS.items():
    out_dir = f'{OUT}/{name}'; os.makedirs(out_dir, exist_ok=True)
    for f in glob.glob(f'{out_dir}/*.png'): os.remove(f)
    frames, dropped, scaled = [], [], []
    torso0 = None
    S, REF_HEAD = scale_of(name)
    for i, box in enumerate(boxes, 1):
        if i in FORA.get(name, {}): dropped.append(i); continue
        a = cut(box); s = S
        hw = head_w(a)
        if name in BIGGER and i in BIGGER[name] and hw and REF_HEAD:   # desenhado maior que os vizinhos
            s = S * REF_HEAD / hw; scaled.append(i)
        im = Image.fromarray(a); w, h = im.size
        sm = np.array(im.resize((max(1, round(w * s)), max(1, round(h * s))), Image.BOX))
        sm[..., 3] = np.where(sm[..., 3] >= 128, 255, 0)
        sm[..., :3] = match(sm[..., :3])
        q = np.array(Image.fromarray(sm[..., :3]).quantize(palette=pal, dither=Image.Dither.NONE).convert('RGB'))
        sm = np.dstack([q, sm[..., 3]]); sm[sm[..., 3] == 0] = 0
        al = sm[..., 3] > 0; hh = al.shape[0]
        tx = shirt_x(sm)
        if torso0 is None: torso0 = tx
        x = int(round(PIV[0] - tx)); y = PIV[1] - hh
        cell = np.zeros((96, 128, 4), np.uint8)
        X0, Y0, X1, Y1 = max(0, x), max(0, y), min(128, x + sm.shape[1]), min(96, y + hh)
        cell[Y0:Y1, X0:X1] = sm[Y0 - y:Y1 - y, X0 - x:X1 - x]
        frames.append((i, cell, (x < 0 or x + sm.shape[1] > 128 or y < 0)))
    for k, (i, cell, _) in enumerate(frames): Image.fromarray(cell).save(f'{out_dir}/{k + 1:02d}.png')
    report[name] = {'quadros': len(frames), 'fora': {str(i): FORA[name][i] for i in dropped},
                    'reescalados': scaled, 'cortados_na_celula': [i for i, _, c in frames if c],
                    'refazer': REFAZER.get(name)}
    review.append((name, [c for _, c, _ in frames]))
json.dump(report, open(f'{OUT}/relatorio.json', 'w'), ensure_ascii=False, indent=1)

# folha de revisão: uma linha por animação, linha do chão e do pivô
Z = 2; W = max(len(f) for _, f in review) * 128 * Z
sheet_img = Image.new('RGBA', (W + 220, len(review) * 96 * Z), (40, 44, 52, 255))
from PIL import ImageDraw
d = ImageDraw.Draw(sheet_img)
for r, (name, fr) in enumerate(review):
    y = r * 96 * Z
    d.text((6, y + 6), name + (' (REFAZER)' if name in REFAZER else ''), fill=(255, 220, 120, 255))
    for k, c in enumerate(fr):
        x = 220 + k * 128 * Z
        sheet_img.alpha_composite(Image.fromarray(c).resize((128 * Z, 96 * Z), Image.NEAREST), (x, y))
        d.line([(x, y + 88 * Z), (x + 128 * Z, y + 88 * Z)], fill=(255, 80, 80, 120))
        d.line([(x + 64 * Z, y), (x + 64 * Z, y + 96 * Z)], fill=(80, 200, 255, 90))
sheet_img.save(f'{OUT}/revisao.png')
for k, v in report.items(): print(k, v)
