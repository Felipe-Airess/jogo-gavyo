import json, glob, os, numpy as np
from PIL import Image
from scipy import ndimage
import sys
BASE, OUT = sys.argv[1], sys.argv[2]; os.makedirs(OUT, exist_ok=True)
# (id, folha, faixa, quadros, contato 1-based ou None, loop)
ANIMS = [('m3_idle','guarda_andar',0,6,None,True), ('m3_walkNeutral','guarda_andar',1,8,None,True),
         ('m3_roundKick','chutes',0,12,6,False), ('m3_stepKick','chutes',1,12,7,False), ('m3_lowKick','chutes',2,10,5,False), ('m3_knee','chutes',3,8,4,False),
         ('m3_jab','socos',0,8,4,False), ('m3_cross','socos',1,9,5,False), ('m3_hookTry','socos',2,9,5,False), ('m3_crossBody','socos',3,9,5,False), ('m3_overhand','socos',4,12,6,False)]
TARGET_H, PIV = 66, (64, 88)
BG = np.array([243,245,239])
def clean(a):
    a = a.copy(); rgb = a[..., :3].astype(int); al = a[..., 3] > 0
    h = a.shape[0]
    near = (np.abs(rgb - BG).sum(2) < 34) | ((rgb.max(2) - rgb.min(2) < 26) & (rgb.mean(2) > 150))
    # buracos claros encostados na base (fundo preso entre as pernas / sombra)
    lab, n = ndimage.label(near & al)
    for i, sl in enumerate(ndimage.find_objects(lab), 1):
        if sl is None: continue
        # fundo preso entre as pernas: buraco claro cuja base fica no quarto de baixo
        if sl[0].stop >= h * 0.75 and (lab[sl] == i).sum() > 12: al[lab == i] = False
    # pedaços soltos: pequenos, ou que não encostam no corpo principal (pé ou
    # punho da célula vizinha, resto de legenda)
    fl, fn = ndimage.label(al, structure=np.ones((3,3)))
    if fn > 1:
        sz = ndimage.sum(al, fl, range(1, fn+1)); main = int(np.argmax(sz)) + 1
        msl = ndimage.find_objects(fl)[main-1]
        grown = ndimage.binary_dilation(fl == main, iterations=4)
        for i, z in enumerate(sz, 1):
            if i == main: continue
            if z < 0.01 * sz[main-1] or not (grown & (fl == i)).any(): al[fl == i] = False
    a[..., 3] = al * 255
    return a
def feet(al):
    h = al.shape[0]; ys, xs = np.nonzero(al)
    base = ys.max()
    band = al[base-max(2,int(h*0.03)):base+1].any(0)
    lab, n = ndimage.label(band)
    return [(np.nonzero(lab == i)[0].min(), np.nonzero(lab == i)[0].max()) for i in range(1, n+1)]
report = {}
allframes = []
for aid, sheet, band, n, contact, loop in ANIMS:
    files = sorted(glob.glob(f'{BASE}/{sheet}/b{band}_*.png'))
    assert len(files) == n, (aid, len(files))
    raw = [clean(np.array(Image.open(f).convert('RGBA'))) for f in files]
    s = (70 if aid == 'm3_walkNeutral' else TARGET_H) / (raw[0][..., 3] > 0).any(1).sum()   # guarda 66 px; em pé 70 px
    small = []
    for a in raw:
        im = Image.fromarray(a); w, h = im.size
        sm = np.array(im.resize((max(1, round(w*s)), max(1, round(h*s))), Image.BOX))
        sm[..., 3] = np.where(sm[..., 3] >= 128, 255, 0)
        # linha de sombra sob os tênis: cinza nas 2 linhas de baixo sem nada logo acima
        op = sm[..., 3] > 0; hh = op.shape[0]
        rgbi = sm[..., :3].astype(int); grey = (rgbi.max(2) - rgbi.min(2) < 30) & (rgbi.mean(2) < 200)
        for yy in range(max(0, hh-2), hh):
            above = op[max(0, yy-3):yy].any(0) if yy >= 1 else np.zeros(op.shape[1], bool)
            kill = op[yy] & grey[yy] & ~above
            sm[yy, kill, 3] = 0
        small.append(sm)
    # Alinhamento pelo pé apoiado: em cada quadro, o deslocamento escolhido é o
    # que mantém algum pé no mesmo x do quadro anterior, o mais perto possível
    # do deslocamento anterior (o corpo não salta).
    # Posição de cada figura dentro da sua célula na folha (o desenho já foi
    # feito no mesmo lugar da célula): é o alinhamento mais fiel à folha.
    meta = json.load(open(f'{BASE}/{sheet}/meta.json'))[str(band)]
    offs = [m['x'] * s for m in meta]
    offs = [o - offs[0] for o in offs]
    drift = offs[-1] - offs[0]
    step = False  # a folha não traz o avanço entre células
    al0 = small[0][..., 3] > 0
    tors = al0[int(al0.shape[0]*.35):int(al0.shape[0]*.6)]
    cx = np.nonzero(tors)[1].mean()
    base = PIV[0] - cx
    frames = []; adv = []
    for k, sm in enumerate(small):
        if step: rel = 0.0; adv.append(round(offs[k] - (offs[k-1] if k else offs[0]), 1))     # avanço vai para o jogo
        else: rel = (offs[k] - offs[0]) - (drift * k / max(1, n - 1) if loop or True else 0); adv.append(0)
        cell = np.zeros((96, 128, 4), np.uint8)
        h, w = sm.shape[:2]
        x = int(round(base + rel)); y = PIV[1] - h
        X0, Y0 = max(0, x), max(0, y); X1, Y1 = min(128, x + w), min(96, y + h)
        cell[Y0:Y1, X0:X1] = sm[Y0 - y:Y1 - y, X0 - x:X1 - x]
        # linha de chão da folha: cinza azulado fino nas linhas de baixo, sem nada acima nem abaixo
        op = cell[..., 3] > 0; rgbc = cell[..., :3].astype(int)
        greyish = (rgbc.max(2) - rgbc.min(2) < 34) & (rgbc.mean(2) > 70) & (rgbc.mean(2) < 175)
        for yy in range(PIV[1] - 6, PIV[1]):
            up = op[yy-1]; dn = op[yy+1] if yy + 1 < 96 else np.zeros(128, bool)
            kill = op[yy] & greyish[yy] & ~up & ~dn
            cell[yy, kill] = 0; op[yy, kill] = False
        frames.append((cell, x < 0 or x + w > 128 or y < 0))
    report[aid] = {'escala': float(round(s, 3)), 'deriva_px': float(round(drift, 1)), 'avanco_px': adv, 'cortado': [i+1 for i, (_, c) in enumerate(frames) if c],
                   'desloc_por_quadro': [float(round(o - offs[0], 1)) for o in offs]}
    for k, (cell, _) in enumerate(frames): allframes.append((aid, k, cell))
# paleta comum
stack = np.concatenate([c[..., :3][c[..., 3] > 0] for _, _, c in allframes])
pal_img = Image.fromarray(stack.reshape(-1, 1, 3).astype(np.uint8)).quantize(colors=48, method=Image.Quantize.MEDIANCUT)
for aid, k, cell in allframes:
    rgb = Image.fromarray(cell[..., :3]).quantize(palette=pal_img, dither=Image.Dither.NONE).convert('RGB')
    out = np.array(rgb); a = cell[..., 3]
    rgba = np.dstack([out, a]); rgba[a == 0] = 0
    os.makedirs(f'{OUT}/{aid}', exist_ok=True)
    Image.fromarray(rgba).save(f'{OUT}/{aid}/{k:02d}.png')
json.dump(report, open(f'{OUT}/relatorio.json', 'w'), ensure_ascii=False, indent=1)
for k, v in report.items(): print(k, v)
