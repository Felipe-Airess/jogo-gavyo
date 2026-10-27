"""Acrescenta ao atlas do Miguel o lote 3 (folhas do ChatGPT já padronizadas).

Uso: python scripts/add-miguel-lote3.py
Fonte: arte/personagens/miguel/lote3/<clip>/NN.png (128x96, pivô 64,88).
Lotes 1 e 2 ficam como estão; rodar de novo substitui só o lote 3.

Tempos: total medido nos vídeos do Miguel (arte/personagens/miguel/tempos-dos-videos.json)
×0,85 na preparação (jogo encurta a carga; com ×1,1 os chutes levavam 390–520 ms
até o contato, contra 220–290 ms no Sorriso) e ×1,2 na volta, distribuído com aceleração: quadros
longos no começo da preparação, curtos perto do contato, contato segurado e
volta desacelerando (o mesmo perfil dos golpes do Sorriso). `skip`: quadros
descartados por defeito do desenho.

Alinhamento: as folhas do ChatGPT não põem o boneco no mesmo lugar em cada
célula (o quadril pulava até 14 px de um quadro para o outro). Cada quadro é
deslocado para que o tronco (faixa entre 25% e 65% da altura, sem braço
erguido nem pernas) fique no mesmo x. Comparado com o alinhamento pela célula
e pelo pé de apoio, é o que menos faz o corpo saltar (soma dos saltos da
cabeça 169 → 143 px; o maior que sobra, 24 px no pesado, é a mão erguida
acima da cabeça puxando o marcador, não o corpo). ALIGN=cell|support|blend
mantém as outras opções para comparação.

Andar: o ciclo da folha é andar no lugar (dois passos). A passada (`stride`)
é medida nos pixels — 2 × a maior distância entre as pontas dos tênis no
chão — e o jogo troca de quadro pela distância andada, não pelo relógio.
"""
import json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'arte' / 'personagens' / 'miguel' / 'lote3'
ATLAS, DATA = ROOT / 'assets' / 'miguel.png', ROOT / 'assets' / 'miguel.json'
CELL, COLUMNS = (128, 96), 8
# id: (pasta, quadro de contato 0-based depois do skip, ms reais de preparação, ms reais de volta, loop, skip)
CLIPS = {
    'm3_idle': ('m3_idle', None, 1200, 0, True, []),
    'm3_walk': ('m3_walkNeutral', None, 1000, 0, True, []),
    'm3_jab': ('m3_jab', 3, 150, 150, False, []),
    # o quadro 2 da folha estica o braço antes da hora (pulo na animação)
    'm3_cross': ('m3_cross', 3, 175, 275, False, [1]),
    'm3_crossBody': ('m3_crossBody', 4, 290, 250, False, []),
    'm3_overhand': ('m3_overhand', 5, 340, 330, False, []),
    'm3_roundKick': ('m3_roundKick', 5, 350, 300, False, []),
    'm3_stepKick': ('m3_stepKick', 6, 470, 380, False, []),
    'm3_lowKick': ('m3_lowKick', 4, 350, 350, False, []),
    'm3_knee': ('m3_knee', 3, 280, 270, False, []),
}
PREP, RECOVER = 0.85, 1.2


def eased(n_pre, n_post, pre_ms, post_ms):
    """Durações com aceleração na preparação e desaceleração na volta."""
    w_pre = np.linspace(1.6, 0.6, n_pre) if n_pre else np.array([])
    w_post = np.concatenate([[1.2], np.linspace(0.95, 1.5, n_post - 1)]) if n_post > 1 else np.array([1.0] * n_post)
    pre = w_pre / w_pre.sum() * pre_ms * PREP if n_pre else w_pre
    post = w_post / w_post.sum() * post_ms * RECOVER
    return [int(round(max(35, v))) for v in list(pre) + list(post)]


def ground_feet(img):
    """Centros (x) dos blocos opacos nas 2 linhas de baixo: pés no chão."""
    a = np.array(img)[..., 3] > 0
    ys = np.nonzero(a.any(1))[0]
    if not len(ys): return []
    band = a[ys.max() - 1:ys.max() + 1].any(0)
    lab, n = ndimage.label(band)
    return [float(np.nonzero(lab == i)[0].mean()) for i in range(1, n + 1)]


def toe_spread(img):
    """Distância entre as pontas (lado da frente) dos dois tênis no chão."""
    a = np.array(img)[..., 3] > 0
    ys = np.nonzero(a.any(1))[0]
    if not len(ys): return 0
    band = a[ys.max() - 5:ys.max() + 1].any(0)
    lab, n = ndimage.label(np.convolve(band, [1, 1, 1], 'same') > 0)   # junta furos de 1 px
    tips = [np.nonzero(lab == i)[0].max() for i in range(1, n + 1) if (lab == i).sum() >= 6]
    return float(max(tips) - min(tips)) if len(tips) >= 2 else 0


def body_x(img):
    """x médio do tronco (faixa do meio da figura, medida a partir do chão)."""
    a = np.array(img)[..., 3] > 0
    ys = np.nonzero(a.any(1))[0]
    if not len(ys): return 64.0
    h = ys.max() - ys.min()
    top = a[ys.max() - int(h * 0.75):ys.max() - int(h * 0.35)]   # tronco: entre 25% e 65% da altura, sem braço erguido nem pernas
    return float(np.nonzero(top)[1].mean())


def align(imgs, loop):
    import os
    mode = os.environ.get('ALIGN', 'body')
    if mode == 'cell': return [0.0] * len(imgs), support_shifts(imgs, True)[1]
    if mode == 'support': return support_shifts(imgs, loop)
    if mode == 'body':
        bx = [body_x(i) for i in imgs]
        return [bx[0] - b for b in bx], support_shifts(imgs, True)[1]
    # blend: o corpo (tronco e cabeça) não salta; o pé de apoio decide só
    # deslocamentos pequenos (até 3 px) que o corpo aceita.
    sup, travel = support_shifts(imgs, loop)
    bx = [body_x(i) for i in imgs]
    shifts = [0.0]
    for k in range(1, len(imgs)):
        body = shifts[-1] - (bx[k] - bx[k - 1])            # mantém o corpo no lugar
        cand = sup[k] if not loop else shifts[-1]
        # aceita o apoio se ele não fizer o corpo pular mais de 3 px
        shifts.append(cand if abs((cand + bx[k]) - (shifts[-1] + bx[k - 1])) <= 3 else body)
    return shifts, travel


def support_shifts(imgs, loop):
    """Deslocamento de cada quadro para o pé de apoio ficar parado.

    Pé de apoio = o pé no chão mais perto (no mundo) de onde o apoio estava no
    quadro anterior. Retorna (deslocamentos, recuo acumulado do apoio)."""
    shifts, travel = [0.0], 0.0
    prev = ground_feet(imgs[0])
    planted = min(prev) if prev else 64.0          # começa pelo pé de trás
    for img in imgs[1:]:
        cur = ground_feet(img)
        if not cur:
            shifts.append(shifts[-1]); continue
        # candidato: cada pé atual; escolhe o que deixa o apoio mais parado
        world_prev = planted + shifts[-1]
        best = min(cur, key=lambda c: abs((c + shifts[-1]) - world_prev))
        shift = world_prev - best
        if loop:
            # no andar o corpo não é deslocado: o recuo do apoio vira passada
            travel += shift - shifts[-1]
            shifts.append(shifts[-1])
        else:
            shifts.append(shift)
        planted = best
    return shifts, travel


def main():
    data = json.loads(DATA.read_text(encoding='utf-8'))
    keep = [c for c in data['clips'] if c.get('source') != 'lote3']
    base = 1 + max(f['index'] for c in keep for f in c['frames'])
    old = Image.open(ATLAS).convert('RGBA')
    files = {cid: [p for i, p in enumerate(sorted((SRC / folder).glob('*.png'))) if i not in skip]
             for cid, (folder, _, _, _, _, skip) in CLIPS.items()}
    total = base + sum(len(v) for v in files.values())
    rows = (total + COLUMNS - 1) // COLUMNS
    atlas = Image.new('RGBA', (CELL[0] * COLUMNS, CELL[1] * rows))
    keep_rows = (base + COLUMNS - 1) // COLUMNS
    atlas.paste(old.crop((0, 0, old.width, min(old.height, keep_rows * CELL[1]))), (0, 0))
    for i in range(base, rows * COLUMNS):
        atlas.paste((0, 0, 0, 0), ((i % COLUMNS) * CELL[0], (i // COLUMNS) * CELL[1], (i % COLUMNS + 1) * CELL[0], (i // COLUMNS + 1) * CELL[1]))
    index, clips = base, []
    for cid, (folder, contact, pre, post, loop, _) in CLIPS.items():
        frames = []
        imgs = [Image.open(p).convert('RGBA') for p in files[cid]]
        shifts, travel = align(imgs, loop)
        # recentraliza: a média dos deslocamentos fica em zero
        mid = sum(shifts) / len(shifts)
        n = len(imgs)
        times = [int(round(pre / n))] * n if contact is None else eased(contact, n - contact, pre, post)
        for k, (p, cell) in enumerate(zip(files[cid], imgs)):
            assert cell.size == CELL, (p, cell.size)
            dx = int(round(shifts[k] - mid))
            if dx:
                moved = Image.new('RGBA', CELL)
                moved.paste(cell, (dx, 0))
                cell = moved
            atlas.paste(cell, ((index % COLUMNS) * CELL[0], (index // COLUMNS) * CELL[1]))
            ms = times[k]
            frames.append({'index': index, 'duration': ms, 'sourceFacing': 1, 'file': f'{folder}/{p.name}', 'root': [64, 88], 'shift': dx,
                           'phase': '' if contact is None else 'preparação' if k < contact else 'contato' if k <= contact + 1 else 'recuperação'})
            index += 1
        stride = 2 * max(toe_spread(i) for i in imgs) if cid == 'm3_walk' else 0
        clips.append({'id': cid, 'loop': loop, 'source': 'lote3', 'frames': frames,
                      **({'stride': stride} if stride else {}),
                      'durations': [f['duration'] for f in frames], 'totalMs': sum(f['duration'] for f in frames),
                      'contactFrames': [] if contact is None else [contact, contact + 1]})
    data['clips'] = keep + clips
    atlas.save(ATLAS)
    DATA.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Miguel: {base} quadros dos lotes 1–2 + {index - base} do lote 3; atlas {atlas.size}.')


if __name__ == '__main__':
    main()
