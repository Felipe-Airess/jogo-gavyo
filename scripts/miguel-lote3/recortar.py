import sys, os, numpy as np
from PIL import Image
from scipy import ndimage
src, outdir, counts = sys.argv[1], sys.argv[2], list(map(int, sys.argv[3].split(',')))
os.makedirs(outdir, exist_ok=True)
im = np.array(Image.open(src).convert('RGB')).astype(int)
H, W, _ = im.shape
r, g, b = im[...,0], im[...,1], im[...,2]
dark_green = (r < 80) & (g < 100) & (b < 90) & (g >= r)
rows = dark_green.mean(1) > 0.5
heads = []; y = 0
while y < H:
    if rows[y]:
        y0 = y
        while y < H and rows[y]: y += 1
        if y - y0 > 8: heads.append((y0, y))
    y += 1
bands = [(h[1], heads[i+1][0] if i+1 < len(heads) else H) for i, h in enumerate(heads)]
assert len(bands) == len(counts), (bands, counts)
mx = im.max(2); mn = im.min(2); sat = mx - mn; lum = im.mean(2)
nearbg = ((np.abs(im - np.array([243,245,239])).sum(2) < 30) |
          ((r > 228) & (g > 195) & (b > 190) & (r - g > 8)) |
          ((sat < 26) & (lum > 150)))
# bordas do painel: colunas cinzas contínuas perto das margens
PX0, PX1 = 16, W - 16
meta = {}
for bi, ((y0, y1), n) in enumerate(zip(bands, counts)):
    sub = nearbg[y0:y1]
    lab, _ = ndimage.label(sub)
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:,0], lab[:,-1]]))) - {0}
    fig = ~np.isin(lab, list(edge))
    hb = fig.shape[0]
    rowfill = fig[:, PX0:PX1].mean(1)
    fig[rowfill > 0.85] = False            # linha do chão / borda do painel
    cw = (PX1 - PX0) / n
    for k in range(n):
        lx, rx = int(PX0 + k*cw) + 3, int(PX0 + (k+1)*cw) - 3
        cell = fig[:, lx:rx].copy()
        cl, cn = ndimage.label(cell, structure=np.ones((3,3)))
        if not cn: print('vazia', bi, k); continue
        objs = ndimage.find_objects(cl); sizes = ndimage.sum(cell, cl, range(1, cn+1))
        main = int(np.argmax(sizes)) + 1
        my0, my1 = objs[main-1][0].start, objs[main-1][0].stop
        keep = []
        for i in range(cn):
            sl = objs[i]
            if sizes[i] < 25: continue
            if sl[0].stop <= 46 and i+1 != main: continue          # número do quadro
            # pedaços (mão, pé) que tocam a faixa vertical do corpo principal
            if i+1 == main or (sl[0].start < my1 and sl[0].stop > my0 and sizes[i] > 0.004*sizes[main-1]): keep.append(i+1)
        m = np.isin(cl, keep)
        ys, xs = np.nonzero(m)
        Y0, Y1, X0, X1 = ys.min(), ys.max()+1, xs.min(), xs.max()+1
        rgba = np.zeros((Y1-Y0, X1-X0, 4), np.uint8)
        rgba[..., :3] = im[y0+Y0:y0+Y1, lx+X0:lx+X1]; rgba[..., 3] = m[Y0:Y1, X0:X1]*255
        Image.fromarray(rgba).save(f"{outdir}/b{bi}_{k:02d}.png")
        meta.setdefault(bi, []).append({'x': int(X0), 'bottom': int(Y1), 'cellw': rx - lx})
    print('faixa', bi, n, 'ok')

import json
json.dump(meta, open(f'{outdir}/meta.json','w'))
