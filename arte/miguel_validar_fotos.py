"""Comparação por máscaras e relatório de revisão, sem depender de OpenCV.

Adapta o cálculo de multiview-fit-loop/scripts/multiview_fit_report.py para
NumPy/Pillow (os binários OpenCV recentes não carregam neste macOS 11).
O escopo quantitativo é só o contorno facial frontal, não cabelo/orelhas
nem uma suposta reconstrução 3D exata a partir de fotografias de perspectiva.

  work/venv-modelo/bin/python arte/miguel_validar_fotos.py
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'arte/revisoes/miguel-20261101'
OVAL = [10,338,297,332,284,251,389,356,454,323,361,288,397,365,379,378,
        400,377,152,148,176,149,150,136,172,58,132,93,234,127,162,21,54,103,67,109]


def mask(pts, size):
    im = Image.new('L', (size, size))
    ImageDraw.Draw(im).polygon([tuple(pts[i]) for i in OVAL], fill=255)
    return np.array(im) > 0


def bounds(m):
    y, x = np.where(m)
    return np.array([x.min(), y.min(), x.max()-x.min()+1, y.max()-y.min()+1], float)


def compare(folder):
    with open(folder / 'landmarks_frente.json') as arq:
        data = json.load(arq)
    size = data['resolucao']
    ref, ren = [mask(data[k], size) for k in ['foto_alinhada_px','modelo_px']]
    br, bn = bounds(ref), bounds(ren)
    drift = (bn[:2]+bn[2:]/2)-(br[:2]+br[2:]/2)
    error = (bn[2:]-br[2:])/br[2:]
    iou = float((ref & ren).sum()/(ref | ren).sum())
    rgb = np.zeros((size,size,3), np.uint8)
    rgb[ref] = (0,255,255); rgb[ren] = (255,255,0)
    rgb[ref & ren] = (0,255,0); rgb[ref ^ ren] = (255,0,0)
    Image.fromarray(rgb).save(folder/'front_mask_overlay.png')
    for name, m in [('reference',ref),('render',ren)]:
        Image.fromarray(m.astype(np.uint8)*255).save(folder/f'front_mask_{name}.png')
    report = {'scope':'Contorno facial frontal detectado; exclui cabelo e orelhas.',
              'iou':iou,'reference_bbox':br.tolist(),'render_bbox':bn.tolist(),
              'bbox_center_drift_px':drift.tolist(),'bbox_size_error_ratio':error.tolist(),
              'pass_iou_90pct':iou >= .90,
              'pass_bbox_center_1p5pct':bool((np.abs(drift) <= .015*size).all()),
              'pass_bbox_size_3pct':bool((np.abs(error) <= .03).all())}
    (folder/'front_mask_validation.json').write_text(json.dumps(report,indent=2)+'\n')
    return report


def main():
    reports = {k:compare(OUT/f'medidas-{k}') for k in ['antes','depois']}
    metrics = {k:json.loads((OUT/f'medidas-{k}/medidas_frente.json').read_text()) for k in reports}
    before = metrics['antes']['desvio_projetado_medio_mm']
    after = metrics['depois']['desvio_projetado_medio_mm']
    summary = {'frente':reports,'medidas':metrics,'reducao_desvio_pct':100*(1-after/before),
               'front_projected_mean_pass_1mm':after <= 1.0,
               'multiview_fit_complete':False,
               'status':'Prévia para revisão visual; perfil e cabelo ainda não têm validação quantitativa.',
               'implementation':'Cálculos bbox/IoU do multiview-fit-loop adaptados a NumPy/Pillow.'}
    (OUT/'validacao-fotos.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
    # Foto alinhada à câmera de rosto usada nos renders com cabelo.
    data = json.loads((OUT/'medidas-depois/landmarks_frente.json').read_text())
    m = np.vstack([data['foto_para_render'], [0,0,1]])
    f = 800/1024*.30/.40
    full = np.array([[f,0,400-512*f],[0,f,440-512*f],[0,0,1]]) @ m
    photo = Image.open(ROOT/'arte/referencias/miguel/rosto_frente4.jpg').convert('RGB')
    photo = photo.transform((800,800),Image.Transform.AFFINE,tuple(np.linalg.inv(full)[:2].ravel()),
                            resample=Image.Resampling.BICUBIC,fillcolor=(235,235,232))
    sheet = Image.new('RGB',(1800,630),(235,235,232)); draw=ImageDraw.Draw(sheet)
    for i,(label,im) in enumerate([('FOTO',photo),('ANTES',Image.open(OUT/'antes/rosto.png')),
                                  ('DEPOIS - PREVIA',Image.open(OUT/'depois/rosto.png'))]):
        if im.mode=='RGBA':
            bg=Image.new('RGBA',im.size,(235,235,232,255));im=Image.alpha_composite(bg,im).convert('RGB')
        sheet.paste(im.resize((600,600)),(i*600,30));draw.text((i*600+15,10),label,fill='black')
    sheet.save(OUT/'comparacao-rosto.png')
    full_sheet=Image.new('RGB',(1800,1030),(235,235,232));d=ImageDraw.Draw(full_sheet)
    for i,(label,file) in enumerate([('FRENTE','frente'),('LADO','lado'),('COSTAS','costas')]):
        im=Image.open(OUT/f'depois/{file}.png').convert('RGBA')
        bg=Image.new('RGBA',im.size,(235,235,232,255));im=Image.alpha_composite(bg,im).convert('RGB')
        full_sheet.paste(im,(i*600,30));d.text((i*600+15,10),label,fill='black')
    full_sheet.save(OUT/'comparacao-corpo.png')
    print(json.dumps({'desvio_antes_mm':before,'desvio_depois_mm':after,
                      'reducao_pct':summary['reducao_desvio_pct'],'mascaras':reports},indent=2))


if __name__ == '__main__':
    main()
