"""Lote 5 do Miguel: prancha única do ChatGPT (itens 9-20) e quadros prontos do
zip de 27/10 (transições, guarda rompida, cansado) -> quadros 128x96 do jogo.

Uso: python scripts/miguel-lote5/extrair.py
Fontes: arte/personagens/miguel/lote5/fontes/pacote5.png (1536x1024, títulos dentro)
        arte/personagens/miguel/lote5/fontes/zip/<animação>/quadro_NN.png
Saída:  arte/personagens/miguel/lote5/<anim>/NN.png + relatorio.json + revisao.png

Correções técnicas, sem redesenhar (mesmas do lote 4):
- fundo magenta, vazamento rosa e as linhas pretas entre as células;
- escala pela guarda (66 px) do quadro 1 do painel, ou de um vizinho da mesma
  linha quando o painel não começa em guarda; a prancha saiu ~2x maior;
- pé de apoio parado entre quadros (golpes) ou camisa centrada (quedas, chão);
- altura no ar preservada (fundo da figura em relação ao chão do painel);
- paleta do lote 3 (as cores do jogo), alfa binário, buracos de 1-6 px fechados.
Correções de conteúdo (quadros fora/reordenados) estão em FORA e LOOP, com o motivo.
"""
import json, os, glob
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = f'{ROOT}/arte/personagens/miguel/lote5/fontes/pacote5.png'
ZIP = f'{ROOT}/arte/personagens/miguel/lote5/fontes/zip'
OUT = f'{ROOT}/arte/personagens/miguel/lote5'
TARGET_H, PIV = 66, (64, 88)

# Painéis da prancha: nome -> (x0, x1, y0, y1) da faixa magenta, células desenhadas.
PANELS = {
    'kickHigh3': ((3, 768, 24, 165), 12),
    'throw': ((772, 1534, 24, 165), 11),
    'thrown': ((3, 774, 199, 331), 11),
    'groundPunch': ((783, 1534, 199, 331), 8),
    'stomp': ((3, 799, 364, 508), 8),
    'groundHit': ((807, 1533, 364, 508), 4),
    'clinchGrab': ((3, 747, 540, 689), 6),
    'clinchBent': ((757, 1533, 540, 689), 6),
    'clinchKnee': ((3, 769, 724, 861), 8),
    'clinchRelease': ((782, 1533, 724, 861), 6),
    'heldSquat': ((3, 772, 891, 1018), 6),
    'clinchEscape': ((783, 1533, 891, 1018), 8),
}
# Painel que dá a escala (quadro 1 em guarda) para quem não começa em guarda.
SCALE_FROM = {'thrown': 'throw', 'groundPunch': 'throw', 'groundHit': 'stomp', 'clinchBent': 'clinchGrab',
              'heldSquat': 'clinchEscape'}
# Quadros que saem (1-based, ordem desenhada) e o motivo.
FORA = {
    'throw': {5: 'perna de trás cortada pela linha da célula (repete o 4)',
              7: 'perna de trás cortada pela linha da célula (o 6 já é o empurrão)',
              8: 'pulo agachado sem apoio no meio do arremesso'},
    'thrown': {11: 'deitado repetido e cortado na borda do painel'},
    'heldSquat': {6: 'termina sentado no chão: não fecha o loop'},
}
# Pé/perna da figura vizinha que entra na célula e encosta no pé desta
# (não dá para separar pela cor): retângulos apagados no quadro final,
# (quadro desenhado 1-based) -> [(x0, y0, x1, y1)], conferidos na revisao.png.
ERASE = {'throw': {3: [(78, 70, 96, 92)], 4: [(80, 60, 96, 96)], 6: [(70, 56, 90, 79)],
                   9: [(73, 56, 90, 96)], 10: [(44, 64, 53, 78)]}}
# Células que são um quadro só (a figura deitada atravessa a linha): 1-based, juntas.
MERGE = {'thrown': [(9, 10)]}
# Desenhados olhando para a esquerda (vítima de frente para quem ataca): o
# atlas guarda tudo olhando para a direita (o jogo vira pelo olhar e os
# marcadores contam com isso), então são espelhados em torno do pivô.
MIRROR = {'thrown', 'heldSquat', 'clinchEscape'}
# Quedas, chão e voo: alinhar pela camisa (os pés saem do chão).
ALIGN_SHIRT = {'thrown', 'groundHit', 'groundPunch', 'clinchBent', 'heldSquat'}

# ---------------------------------------------------------------- paleta
lote3 = [np.array(Image.open(p).convert('RGBA')) for p in glob.glob(f'{ROOT}/arte/personagens/miguel/lote3/m3_idle/*.png')]
px = np.concatenate([a[..., :3][a[..., 3] > 0] for a in lote3])
pal = Image.fromarray(px.reshape(-1, 1, 3)).quantize(colors=48, method=Image.Quantize.MEDIANCUT)


def _cdf(v):
    h = np.bincount(v.ravel(), minlength=256).astype(float); c = np.cumsum(h); return c / c[-1]


def build_lut(src_rgba, s=1.0):
    im = Image.fromarray(src_rgba)
    if s != 1.0: im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.BOX)
    rgb = np.array(im); sp = rgb[..., :3][rgb[..., 3] >= 128]
    return [np.searchsorted(_cdf(px[:, ch]), _cdf(sp[:, ch])).clip(0, 255).astype(np.uint8) for ch in range(3)]


def to_palette(sm, lut):
    sm = sm.copy()
    sm[..., 3] = np.where(sm[..., 3] >= 128, 255, 0)
    sm[..., :3] = np.stack([lut[c][sm[..., c]] for c in range(3)], -1)
    q = np.array(Image.fromarray(np.ascontiguousarray(sm[..., :3])).quantize(palette=pal, dither=Image.Dither.NONE).convert('RGB'))
    sm = np.dstack([q, sm[..., 3]]).astype(np.uint8); sm[sm[..., 3] == 0] = 0
    return close_pinholes(sm)


def close_pinholes(a, max_px=6):
    """Buracos de 1-6 px dentro da figura (sobra do fundo) ganham a cor vizinha mais comum."""
    op = a[..., 3] > 0
    holes = ndimage.binary_fill_holes(op) & ~op
    lab, n = ndimage.label(holes)
    for i in range(1, n + 1):
        m = lab == i
        if m.sum() > max_px: continue
        ring = ndimage.binary_dilation(m) & op
        cols, cnt = np.unique(a[ring][:, :3], axis=0, return_counts=True)
        a[m, :3] = cols[np.argmax(cnt)]; a[m, 3] = 255
    return a


# ---------------------------------------------------------------- prancha
sheet = np.array(Image.open(SRC).convert('RGB')).astype(int)
mag_d = np.sqrt(((sheet - [255, 0, 255]) ** 2).sum(2))


def cells_of(box, n):
    """Células = regiões magenta separadas pelas linhas escuras; pedaços da mesma célula se juntam."""
    x0, x1, y0, y1 = box
    s = sheet[y0:y1, x0:x1]   # estrito: o anti-serrilhado da linha não liga células
    mag = (s[..., 0] > 200) & (s[..., 2] > 200) & (s[..., 1] < 90)
    lab, k = ndimage.label(mag)
    objs = [(sl[1].start, sl[1].stop, int((lab[sl] == i + 1).sum())) for i, sl in enumerate(ndimage.find_objects(lab))]
    objs = sorted([o for o in objs if o[2] > 1500])
    merged = []
    for a, b, _ in objs:
        if merged and min(b, merged[-1][1]) - max(a, merged[-1][0]) > 0.5 * min(b - a, merged[-1][1] - merged[-1][0]):
            merged[-1] = [min(a, merged[-1][0]), max(b, merged[-1][1])]
        else:
            merged.append([a, b])
    assert len(merged) == n, (box, n, merged)
    return [(x0 + a, y0, x0 + b, y1) for a, b in merged]


def panel_cells(name, box, n):
    cells = cells_of(box, n)
    for a, b in sorted(MERGE.get(name, []), reverse=True):
        joins = tuple(c[0] for c in cells[a:b])   # linhas entre as células juntadas
        cells[a - 1:b] = [(cells[a - 1][0], box[2], cells[b - 1][2], box[3], joins)]
    return cells


def cut(box, pad=8):
    """Figura da célula (com folga para mãos/pés que passam da linha), sem fundo nem vizinhos."""
    x0, y0, x1, y1 = box[:4]; joins = box[4] if len(box) > 4 else ()
    X0, X1 = max(0, x0 - pad), min(sheet.shape[1], x1 + pad)
    rgb = sheet[y0:y1, X0:X1].copy(); d = mag_d[y0:y1, X0:X1]
    al = d > 150
    # linhas pretas das células: colunas quase cheias saem da máscara
    # (só perto das bordas: a perna esticada de um chute também enche a coluna)
    edge = np.zeros(al.shape[1], bool)
    # linha entre células juntadas: as colunas dela copiam a vizinha de cada lado
    for j in joins:
        j -= X0
        line = [c for c in range(j - 4, j + 4) if al[:, c].mean() > 0.8]   # cheia de alto a baixo
        if line:
            a, b = min(line), max(line); mid = (a + b) / 2
            for c in range(a, b + 1):
                src = a - 1 if c <= mid else b + 1
                rgb[:, c] = rgb[:, src]; al[:, c] = al[:, src]
    for e in (x0 - X0, x1 - X0):
        edge[max(0, e - 4):e + 4] = True
    # linha da célula: escura e fina; pedaços dela que encostam no pé também saem
    dark = (rgb.max(2) < 90)
    al[:, edge & (al.mean(0) > 0.85)] = False
    al[:, edge & ((al & dark).mean(0) > 0.3)] &= ~dark[:, edge & ((al & dark).mean(0) > 0.3)]
    al[:2] = False; al[-1:] = False
    # despill
    g = rgb[..., 1]; m = np.minimum(rgb[..., 0], rgb[..., 2]); ex = np.clip(m - g, 0, None)
    k = np.where(d < 260, 1.0, 0.7)
    rgb[..., 0] -= (ex * k).astype(int); rgb[..., 2] -= (ex * k).astype(int)
    light = (rgb.min(2) > 140) & (rgb.max(2) - rgb.min(2) < 90)
    lum = (rgb * [0.3, 0.59, 0.11]).sum(2)
    rgb[light] = np.stack([lum[light]] * 3, 1).astype(int)
    # só a figura desta célula: o maior pedaço que cruza a célula e o que encosta nele
    lab, n = ndimage.label(al, structure=np.ones((3, 3)))
    inside = np.zeros_like(al); inside[:, x0 - X0:x1 - X0] = True
    sz = ndimage.sum(al & inside, lab, range(1, n + 1)); main = int(np.argmax(sz)) + 1
    grown = ndimage.binary_dilation(lab == main, iterations=2)
    keep = lab == main
    for i in range(1, n + 1):
        if i != main and (grown & (lab == i)).any() and ndimage.sum(inside, lab == i) > 0.5 * (lab == i).sum()                 and (lab == i).sum() > 0.03 * (lab == main).sum():
            keep |= lab == i
    al = keep
    ys, xs = np.nonzero(al)
    bottom = y0 + ys.max()
    rgb = rgb[ys.min():ys.max() + 1, xs.min():xs.max() + 1]; al = al[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    return np.dstack([np.clip(rgb, 0, 255), al * 255]).astype(np.uint8), bottom


def shirt_x(a):
    rgb = a[..., :3].astype(int); op = a[..., 3] > 0
    white = (rgb.min(2) > 150) & (rgb.max(2) - rgb.min(2) < 45)
    green = (rgb[..., 1] > rgb[..., 0] + 25) & (rgb[..., 1] > rgb[..., 2] + 5)
    m = op & (white | green)
    return np.nonzero(m)[1].mean() if m.sum() > 20 else np.nonzero(op)[1].mean()


def ground_feet_x(sm, y):
    hh = sm.shape[0]
    if y + hh < PIV[1] - 1: return []
    band = (sm[..., 3] > 0)[max(0, hh - 3):hh].any(0)
    lab, n = ndimage.label(band)
    return [float(np.nonzero(lab == i)[0].mean()) for i in range(1, n + 1) if (lab == i).sum() >= 3]


def place(sm, x, y):
    cell = np.zeros((96, 128, 4), np.uint8)
    X0, Y0, X1, Y1 = max(0, x), max(0, y), min(128, x + sm.shape[1]), min(96, y + sm.shape[0])
    cell[Y0:Y1, X0:X1] = sm[Y0 - y:Y1 - y, X0 - x:X1 - x]
    return cell, (x < 0 or x + sm.shape[1] > 128 or y < 0)


report, review = {}, []
raw = {name: [cut(b) for b in panel_cells(name, box, n)] for name, (box, n) in PANELS.items()}
def hair_area(a):
    """Pixels de cabelo (castanho escuro) da figura: régua do tamanho da cabeça."""
    rgb = a[..., :3].astype(int); op = a[..., 3] > 0
    return float((op & (rgb[..., 0] < 120) & (rgb[..., 1] < 90) & (rgb[..., 2] < 80) & (rgb[..., 0] >= rgb[..., 1]) & (rgb.sum(2) > 40)).sum())


# Escala: painel com guarda no quadro 1 → guarda de 66 px. Painel sem guarda →
# a cabeça do mesmo tamanho da guarda do vizinho (SCALE_FROM). Pela escala do
# vizinho só, o segurado saía 48% maior que a guarda e o soco no chão 30%.
scale = {name: TARGET_H / raw[name][0][0].shape[0] for name in PANELS if name not in SCALE_FROM}
for name, ref in SCALE_FROM.items():
    ref_hair = hair_area(raw[ref][0][0])
    own = float(np.median([hair_area(a) for a, _ in raw[name]]))
    scale[name] = scale[ref] * (ref_hair / own) ** 0.5

for name, (box, n) in PANELS.items():
    S = scale[name]
    ground = max(b for _, b in raw[name])
    ref = raw[SCALE_FROM.get(name, name)][0][0]
    lut = build_lut(ref, TARGET_H / ref.shape[0])
    frames, prev_x, prev_feet = [], None, []
    # numeração desenhada: quadros juntados contam como o primeiro deles
    nums = list(range(1, n + 1))
    for a, b in sorted(MERGE.get(name, []), reverse=True): del nums[a:b]
    drawn = [(i, a, b) for i, (a, b) in zip(nums, raw[name]) if i not in FORA.get(name, {})]
    for k, (i, a, bot) in enumerate(drawn):
        im = Image.fromarray(a)
        sm = np.array(im.resize((max(1, round(im.width * S)), max(1, round(im.height * S))), Image.BOX))
        sm = to_palette(sm, lut)
        hh = sm.shape[0]
        y = PIV[1] - hh - int(round((ground - bot) * S))
        tx = shirt_x(sm)
        if name in ALIGN_SHIRT or k == 0:
            x = int(round(PIV[0] - tx))
        else:
            x = prev_x
            fx = ground_feet_x(sm, y)
            if fx and prev_feet:
                best = min(((abs((f0 + prev_x) - pf), f0, pf) for f0 in fx for pf in prev_feet))
                x = int(round(best[2] - best[1]))
        prev_x = x
        cur = [f + x for f in ground_feet_x(sm, y)]
        prev_feet = cur or prev_feet
        cell, clipped = place(sm, x, y)
        if name in MIRROR: cell = np.roll(cell[:, ::-1], 1, axis=1)   # x -> 128 - x: pivô 64 fica em 64
        for ex0, ey0, ex1, ey1 in ERASE.get(name, {}).get(i, []): cell[ey0:ey1, ex0:ex1] = 0
        frames.append((i, cell, clipped))
    report[name] = {'desenhados': n, 'quadros': len(frames), 'escala': round(S, 3),
                    'fora': {str(i): FORA[name][i] for i in FORA.get(name, {})},
                    'cortados_na_celula': [i for i, _, c in frames if c]}
    review.append((name, [c for _, c, _ in frames]))

# ---------------------------------------------------------------- zip (já 128x96)
ZIP_ANIMS = {'walkStart': '01_guarda_para_andar_3_quadros', 'walkStop': '02_andar_para_guarda_3_quadros',
             'guardBreak': '05_guarda_rompida_refeita_6_quadros', 'tired': '06_cansado_loop_6_quadros'}
for name, folder in ZIP_ANIMS.items():
    files = sorted(glob.glob(f'{ZIP}/{folder}/quadro_*.png'))
    imgs = [np.array(Image.open(p).convert('RGBA')) for p in files]
    out = []
    for a in imgs:
        # cada quadro veio de uma fonte (cabelo laranja na rompida 4-5): cor casada quadro a quadro
        b = to_palette(a, build_lut(a))
        op = b[..., 3] > 0; ys = np.nonzero(op.any(1))[0]
        # pé no chão: base em y = 87 (como o lote 3)
        dy = (PIV[1] - 1) - ys.max()
        if dy: b = np.roll(b, dy, axis=0)
        out.append(b)
    review.append((name, out))
    report[name] = {'quadros': len(out), 'fonte': f'zip/{folder}', 'corrigido': 'paleta do jogo, alfa binário, buracos fechados, pé em y=87'}
    os.makedirs(f'{OUT}/{name}', exist_ok=True)
    for f in glob.glob(f'{OUT}/{name}/*.png'): os.remove(f)
    for k, c in enumerate(out): Image.fromarray(c).save(f'{OUT}/{name}/{k + 1:02d}.png')

for name, fr in review:
    if name in ZIP_ANIMS: continue
    os.makedirs(f'{OUT}/{name}', exist_ok=True)
    for f in glob.glob(f'{OUT}/{name}/*.png'): os.remove(f)
    for k, c in enumerate(fr): Image.fromarray(c).save(f'{OUT}/{name}/{k + 1:02d}.png')

json.dump(report, open(f'{OUT}/relatorio.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

Z = 2; W = max(len(f) for _, f in review) * 128 * Z
img = Image.new('RGBA', (W + 160, len(review) * 96 * Z), (40, 44, 52, 255))
d = ImageDraw.Draw(img)
for r, (name, fr) in enumerate(review):
    y = r * 96 * Z
    d.text((6, y + 6), name, fill=(255, 220, 120, 255))
    for k, c in enumerate(fr):
        x = 160 + k * 128 * Z
        img.alpha_composite(Image.fromarray(c).resize((128 * Z, 96 * Z), Image.NEAREST), (x, y))
        d.line([(x, y + 88 * Z), (x + 128 * Z, y + 88 * Z)], fill=(255, 80, 80, 120))
        d.line([(x + 64 * Z, y), (x + 64 * Z, y + 96 * Z)], fill=(80, 200, 255, 90))
        d.text((x + 4, y + 4), str(k + 1), fill=(200, 200, 200, 255))
img.save(f'{OUT}/revisao.png')
for k, v in report.items(): print(k, v)
