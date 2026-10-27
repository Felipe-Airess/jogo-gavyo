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


def ground_feet_x(sm, hh, y):
    """x (no recorte) dos pés encostados no chão (base do recorte na linha do chão)."""
    if y + hh < PIV[1] - 1: return []
    op = sm[..., 3] > 0; band = op[max(0, hh - 3):hh].any(0)
    lab, n = ndimage.label(band)
    return [float(np.nonzero(lab == i)[0].mean()) for i in range(1, n + 1) if (lab == i).sum() >= 3]


def shirt_area(a):
    rgb = a[..., :3].astype(int); op = a[..., 3] > 0
    white = (rgb.min(2) > 150) & (rgb.max(2) - rgb.min(2) < 45)
    green = (rgb[..., 1] > rgb[..., 0] + 25) & (rgb[..., 1] > rgb[..., 2] + 5)
    return float((op & (white | green)).sum())


# Quadros desenhados maiores que os vizinhos: voltam à escala pela cabeça.
BIGGER = {}   # chute alto 6-7 parecem maiores, mas a altura medida (92 px x 86) é a da perna de apoio esticada
# Animações com erro de anatomia/direção: extraídas para conferência, mas
# marcadas para refazer (não entram no jogo).
REFAZER = {}   # refeitas em folhas separadas (REFEITAS, abaixo) substituem as do pacote 2

# Folhas refeitas (uma animação por imagem, 2172x724): arquivo em fontes/,
# quadros, quadro de guarda para a escala (1-based) ou None (escala pela
# largura do cabelo, comparada com a guarda de 'leanBack').
# Alinhamento: 'feet' mantém parado o pé que continua no chão (golpes,
# andar, reações em pé); 'shirt' centra a camisa (queda, levantar, corrida,
# onde os pés saem do chão). Com 'shirt' num golpe, o tronco que avança com
# o soco era puxado de volta: soco curto e pé de trás deslizando.
ALIGN_SHIRT = {'fall', 'rise', 'run', 'walkA', 'walkB', 'walkC'}
REFEITAS = {
    'leanBack': ('leanBack.png', 6, 1),
    'hitHeadHeavy': ('hitHeadHeavy.png', 7, 1),
    'rise': ('rise.png', 7, 7),
    'fall': ('fall.png', 6, None),
    'run': ('run.png', 8, None),
    # pacote 3 (27/10): versões novas, comparadas com as atuais antes de trocar
    'elbow2': ('elbow2.png', 8, 1), 'jabStep2': ('jabStep2.png', 8, 1), 'jabBody2': ('jabBody2.png', 8, 1),
    'crossStep2': ('crossStep2.png', 9, 1), 'uppercut2': ('uppercut2.png', 9, 1), 'kickHigh2': ('kickHigh2.png', 12, 1),
    'hook2': ('hook2.png', 9, 1), 'comboBodyUpper': ('comboBodyUpper.png', 14, 1),
    'comboJabElbowKnee': ('comboJabElbowKnee.png', 12, 1), 'comboLowHigh': ('comboLowHigh.png', 14, 1),
    'walkA': ('walkA.png', 6, 1), 'walkB': ('walkB.png', 6, 1), 'walkC': ('walkC.png', 6, 1),
}

sheet = np.array(Image.open(SRC).convert('RGB')).astype(int)
mag_d = np.sqrt(((sheet - [255, 0, 255]) ** 2).sum(2))


# Animações em que um pé passa da divisa da célula (o pé de trás da corrida
# entra no espaço da figura anterior): recorte com folga, só a figura desta
# célula (o pedaço que mais ocupa a célula e o que encosta nele).
CUT_PAD = {'run': 36, 'runStart': 36}


def cut_padded(box, pad):
    x0, y0, x1, y1 = box
    X0, X1 = max(0, x0 - pad), min(sheet.shape[1], x1 + pad)
    rgb = sheet[y0:y1, X0:X1].copy(); d = mag_d[y0:y1, X0:X1]
    al = d > 150
    g = rgb[..., 1]; m = np.minimum(rgb[..., 0], rgb[..., 2]); ex = np.clip(m - g, 0, None)
    k = np.where(d < 260, 1.0, 0.7)
    rgb[..., 0] -= (ex * k).astype(int); rgb[..., 2] -= (ex * k).astype(int)
    light = (rgb.min(2) > 140) & (rgb.max(2) - rgb.min(2) < 90)
    lum = (rgb * [0.3, 0.59, 0.11]).sum(2)
    rgb[light] = np.stack([lum[light]] * 3, 1).astype(int)
    lab, n = ndimage.label(al, structure=np.ones((3, 3)))
    inside = np.zeros_like(al); inside[:, x0 - X0:x1 - X0] = True
    main = int(np.argmax(ndimage.sum(al & inside, lab, range(1, n + 1)))) + 1
    grown = ndimage.binary_dilation(lab == main, iterations=2)
    keep = lab == main
    for i in range(1, n + 1):
        if i != main and (grown & (lab == i)).any() and (lab == i).sum() > 0.02 * (lab == main).sum(): keep |= lab == i
    ys, xs = np.nonzero(keep)
    rgb = rgb[ys.min():ys.max() + 1, xs.min():xs.max() + 1]; keep = keep[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    return np.dstack([np.clip(rgb, 0, 255), keep * 255]).astype(np.uint8)


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
def build_lut(src, s):
    rgb = np.array(Image.fromarray(src).resize((max(1, round(src.shape[1] * s)), max(1, round(src.shape[0] * s))), Image.BOX))
    sp = rgb[..., :3][rgb[..., 3] >= 128]
    return [np.searchsorted(_cdf(px[:, ch]), _cdf(sp[:, ch])).clip(0, 255).astype(np.uint8) for ch in range(3)]
_src = cut(CELLS['walkFwd'][0])
LUT = build_lut(_src, TARGET_H / _src.shape[0])
def match(rgb):
    return np.stack([LUT[c][rgb[..., c]] for c in range(3)], -1)

report, review = {}, []
for name, boxes in CELLS.items():
    if name in REFEITAS: continue
    out_dir = f'{OUT}/{name}'; os.makedirs(out_dir, exist_ok=True)
    for f in glob.glob(f'{out_dir}/*.png'): os.remove(f)
    frames, dropped, scaled = [], [], []
    torso0 = None
    S, REF_HEAD = scale_of(name)
    for i, box in enumerate(boxes, 1):
        if i in FORA.get(name, {}): dropped.append(i); continue
        a = cut_padded(box, CUT_PAD[name]) if name in CUT_PAD else cut(box); s = S
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

# ---- folhas refeitas: corte pelo vale da silhueta, altura relativa ao chão preservada
def label_centers(fig_top, n):
    """x dos números das células: componentes claros acima das figuras, da esquerda para a direita."""
    top = mag_d[:max(1, fig_top - 2)] > 150            # texto claro ou escuro, tudo que não é magenta
    lab, k = ndimage.label(ndimage.binary_dilation(top, iterations=3))
    objs = [sl for i, sl in enumerate(ndimage.find_objects(lab))
            if sl is not None and (lab[sl] == i + 1).sum() > 30
            and sl[0].stop - sl[0].start < 80 and sl[1].stop - sl[1].start < 120]   # linhas de célula ficam fora
    xs = sorted((sl[1].start + sl[1].stop) / 2 for sl in objs)
    # números de dois dígitos podem virar dois blocos próximos: junta os que ficam a < 25 px
    merged = []
    for x in xs:
        if merged and x - merged[-1][-1] < 25: merged[-1].append(x)
        else: merged.append([x])
    cs = [sum(m) / len(m) for m in merged]
    return cs if len(cs) == n else None

def row_boxes(n):
    fgm = mag_d > 150
    rows = fgm.mean(1) > 0.002
    # faixa mais alta de linhas com figura (os números ficam numa faixa própria, acima)
    runs, st = [], None
    for y, v in enumerate(list(rows) + [False]):
        if v and st is None: st = y
        if not v and st is not None: runs.append((st, y)); st = None
    y0, y1 = max(runs, key=lambda r: r[1] - r[0])
    band = fgm[y0:y1]
    # linhas pretas de célula (colunas quase cheias e finas) viram fronteira e saem da máscara
    full = band.mean(0) > 0.9
    prof = band.sum(0).astype(float); prof[full] = 0
    xs = np.nonzero(prof)[0]; x0, x1 = xs.min(), xs.max() + 1
    # centros pelos números acima de cada figura (texto claro na faixa de cima);
    # sem os n números, divisão igual
    labels = label_centers(y0, n)
    LABELS_OK.append(bool(labels))
    if labels:
        guess = [(labels[i] + labels[i + 1]) / 2 for i in range(n - 1)]
        gaps = [labels[i + 1] - labels[i] for i in range(n - 1)]
    else:
        cw = (x1 - x0) / n; guess = [x0 + i * cw for i in range(1, n)]; gaps = [cw] * (n - 1)
    bs = [x0]
    for c, g in zip(guess, gaps):
        r = int(g * 0.25); c = int(c); seg = prof[c - r:c + r + 1]
        bs.append(c - r + int(np.argmin(seg)))
    bs.append(x1)
    return [(bs[i] + (3 if full[bs[i]] else 0), y0, bs[i + 1] - (2 if full[min(bs[i + 1], len(full) - 1)] else 0), y1) for i in range(n)], y1

lean_hair = None
LABELS_OK = []


def equalize_legs(cells):
    """Corrida: a folha repete a mesma passada duas vezes (a perna escura, de
    longe, fica sempre atrás) — no jogo, manca. Sem redesenhar, a perna de longe
    recebe os tons da de perto (mesma luminância relativa; contorno escuro
    fica): sem perna mais escura, não se distingue qual está à frente e o ciclo
    lê como pernas alternando. Só cor."""
    lum = lambda c: 0.3 * c[..., 0] + 0.59 * c[..., 1] + 0.11 * c[..., 2]
    jm = [(c[..., 3] > 0) & (c[..., 2].astype(int) > c[..., 0].astype(int) + 25) & (c[..., 2] >= c[..., 1]) for c in cells]
    pal_j = np.unique(np.concatenate([c[..., :3][j] for c, j in zip(cells, jm)]), axis=0)
    light = pal_j[lum(pal_j.astype(float)) >= 115]; light = light[np.argsort(lum(light.astype(float)))]
    for c, j in zip(cells, jm):
        L = lum(c[..., :3].astype(float)); dark = j & (L < 115) & (L > 60)
        lab, n = ndimage.label(ndimage.binary_opening(dark, iterations=1))
        for i in range(1, n + 1):
            m = lab == i
            if m.sum() < 25: continue
            m = ndimage.binary_dilation(m, iterations=1) & dark
            k = np.clip((L[m] - 60) / 55 * (len(light) - 1), 0, len(light) - 1).astype(int)
            c[m, :3] = light[k]
for name, (fname, n, guard) in REFEITAS.items():
    sheet = np.array(Image.open(f'{OUT}/fontes/{fname}').convert('RGB')).astype(int)
    mag_d = np.sqrt(((sheet - [255, 0, 255]) ** 2).sum(2))
    boxes, _ = row_boxes(n)
    raw = [cut_padded(b, CUT_PAD[name]) if name in CUT_PAD else cut(b) for b in boxes]
    # fundo da figura na folha (para manter o voo da corrida e a altura no chão)
    bottoms = []
    for b in boxes:
        al = mag_d[b[1]:b[3], b[0]:b[2]] > 150
        lab, k = ndimage.label(al, structure=np.ones((3, 3)))
        sz = ndimage.sum(al, lab, range(1, k + 1)); main = lab == (int(np.argmax(sz)) + 1)
        bottoms.append(b[1] + np.nonzero(main.any(1))[0].max())
    ground = max(bottoms)
    if guard:
        S = TARGET_H / raw[guard - 1].shape[0]
        if name == 'leanBack': lean_hair = (shirt_area(raw[0]), S)
    else:
        # sem guarda: área da camisa (não muda com a inclinação), média dos quadros,
        # comparada com a da guarda da esquiva
        S = lean_hair[1] * (lean_hair[0] / np.median([shirt_area(r) for r in raw])) ** 0.5
    out_dir = f'{OUT}/{name}'; os.makedirs(out_dir, exist_ok=True)
    for f in glob.glob(f'{out_dir}/*.png'): os.remove(f)
    # cor casada por folha: cada folha refeita veio com tons próprios; a guarda
    # dela (ou, sem guarda, o quadro 1) é comparada com a guarda do lote 3
    LUT = build_lut(raw[(guard or 1) - 1], S)
    frames = []
    for k, (a, bot) in enumerate(zip(raw, bottoms)):
        im = Image.fromarray(a); w, h = im.size
        sm = np.array(im.resize((max(1, round(w * S)), max(1, round(h * S))), Image.BOX))
        sm[..., 3] = np.where(sm[..., 3] >= 128, 255, 0)
        sm[..., :3] = match(sm[..., :3])
        q = np.array(Image.fromarray(sm[..., :3]).quantize(palette=pal, dither=Image.Dither.NONE).convert('RGB'))
        sm = np.dstack([q, sm[..., 3]]); sm[sm[..., 3] == 0] = 0
        hh = sm.shape[0]; tx = shirt_x(sm)
        y = PIV[1] - hh - int(round((ground - bot) * S))
        if name in ALIGN_SHIRT or k == 0:
            x = int(round(PIV[0] - tx))
        else:
            # pé apoiado: entre os pés no chão deste quadro, o que fica mais perto
            # (no mundo) de um pé no chão do quadro anterior; sem pé no chão, mantém
            x = prev_x
            fx = ground_feet_x(sm, hh, y)
            if fx and prev_feet:
                best = min(((abs((x0 + prev_x) - pf), x0, pf) for x0 in fx for pf in prev_feet))
                x = int(round(best[2] - best[1]))
        prev_x = x
        cur = [f + x for f in ground_feet_x(sm, hh, y)]
        prev_feet = cur or (prev_feet if k else [])
        cell = np.zeros((96, 128, 4), np.uint8)
        X0, Y0, X1, Y1 = max(0, x), max(0, y), min(128, x + sm.shape[1]), min(96, y + hh)
        cell[Y0:Y1, X0:X1] = sm[Y0 - y:Y1 - y, X0 - x:X1 - x]
        frames.append((cell, x < 0 or x + sm.shape[1] > 128 or y < 0))
    if name == 'run': equalize_legs([c for c, _ in frames])
    for k, (cell, _) in enumerate(frames): Image.fromarray(cell).save(f'{out_dir}/{k + 1:02d}.png')
    report[name] = {'numeros_achados': LABELS_OK[-1], 'quadros': len(frames), 'fonte': fname, 'escala': round(float(S), 3), 'cortados_na_celula': [i + 1 for i, (_, c) in enumerate(frames) if c], 'refazer': None}
    review = [(nm, fr) if nm != name else (nm, [c for c, _ in frames]) for nm, fr in review]
    if name not in [nm for nm, _ in review]: review.append((name, [c for c, _ in frames]))

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
