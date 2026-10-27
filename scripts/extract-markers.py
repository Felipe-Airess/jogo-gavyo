"""Extrai marcadores anatômicos dos quadros de Sorriso usados no combate.

Uso: python scripts/extract-markers.py [sorriso] [miguel]
Saída: assets/sorriso-markers.json, assets/miguel-markers.json

Os marcadores antigos do atlas usam o extremo frontal de pixels claros. Esse
ponto serve tanto para mão quanto para tênis e, em vários quadros, os dois
coincidem. Aqui cada pixel é classificado por cor (pele, cabelo, camisa,
calça, tênis) e os membros vêm de componentes conectados dessas classes.

Coordenadas: relativas ao pivô (64,88) da célula, olhando para a direita,
y negativo para cima — as mesmas convenções de `fist`/`foot` no atlas.
Quando a classe não separa o membro (mão encostada no rosto, tênis sob a
calça), o marcador fica `null` e o motivo vai para `limits`. Nenhuma
coordenada é inventada.
"""
import json
from collections import deque
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ATLAS = ROOT / 'assets' / 'sorriso-v70.png'
DATA = ROOT / 'assets' / 'sorriso-v70.json'
OUT = ROOT / 'assets' / 'sorriso-markers.json'
CELL_W, CELL_H, COLUMNS, PIVOT = 128, 96, 8, (64, 88)
CLIPS = ['r1_idle', 'r2_walk', 'r2_run', 'r2_runStart', 'r2_runStop', 'r2_turn', 'r2_crouchDown', 'r2_crouchHold', 'r2_crouchUp',
         'r3_jab_body', 'r3_jab_head', 'r3_cross_body', 'r3_cross_head', 'r3_hook_body',
         'r3_overhand_heavy', 'r3_reverse_strike', 'r3_low_kick', 'r3_round_kick_body',
         'r3_round_kick_head', 'r3_running_punch', 'r3_combo_punch_kick', 'r3_combo_kick_punch',
         'hurt', 'fall', 'rise', 'block', 'crouch', 'missMotion', 'clinchPunch', 'clinchWalk', 'kneeV6',
         'clinchFinish', 'groundFluid', 'groundStomp', 'parryCounter', 'counterLeft']


# Cabelo castanho com reflexos avermelhados (Miguel): além dos tons escuros,
# conta como cabelo o marrom-avermelhado escuro, sem o azul da pele.
REDDISH_HAIR = False


def classify(r, g, b, a):
    if a < 128:
        return None
    mx, mn = max(r, g, b), min(r, g, b)
    if mx < 70:
        return 'hair'  # cabelo e contornos escuros
    if REDDISH_HAIR and mx <= 120 and b <= 48 and r > g + 30:
        return 'hair'
    if r > 125 and r > g + 15 and g > b + 5 and b > 70 and g - b < 60:
        return 'skin'  # inclui sombras do antebraço
    if b > r + 25 and b >= g:
        return 'jeans'
    if g > r + 18 and g > b + 10:
        return 'green'
    if r > 150 and g > 135 and b > 60 and r > b + 50 and g > b + 40:
        return 'yellow'
    if mn > 160 and mx - mn < 45:
        return 'white'  # camisa ou tênis; separados por adjacência
    return 'other'


def components(cls, wanted):
    seen, out = set(), []
    for (x, y), c in cls.items():
        if c not in wanted or (x, y) in seen:
            continue
        group, queue = [], deque([(x, y)])
        seen.add((x, y))
        while queue:
            px, py = queue.popleft()
            group.append((px, py))
            for nx, ny in ((px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)):
                if (nx, ny) not in seen and cls.get((nx, ny)) in wanted:
                    seen.add((nx, ny))
                    queue.append((nx, ny))
        out.append(group)
    return out


def touches(group, cls, wanted):
    for x, y in group:
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1), (x + 1, y + 1), (x - 1, y + 1)):
            if cls.get((nx, ny)) in wanted:
                return True
    return False


def local(x, y):
    return {'x': round(x - PIVOT[0], 2), 'y': round(y - PIVOT[1], 2)}


def centroid(points):
    return sum(p[0] for p in points) / len(points), sum(p[1] for p in points) / len(points)


BAND = 4  # altura das faixas da decomposição (px)


def rects(mask):
    """Cobre um conjunto de pixels com retângulos justos.

    Faixas horizontais de BAND linhas; em cada faixa, um retângulo por trecho
    contínuo de colunas (vãos de 3 px ou mais separam, por exemplo, as duas
    pernas). Faixas vizinhas com bordas a até 2 px de distância são unidas.
    Saída em coordenadas locais [x0, y0, x1, y1), x1/y1 exclusivos.
    """
    if not mask:
        return []
    ys = [y for _, y in mask]
    y_top, y_bot = min(ys), max(ys)
    out = []
    for band in range(y_top, y_bot + 1, BAND):
        pts = [p for p in mask if band <= p[1] < band + BAND]
        if not pts:
            continue
        cols = sorted({x for x, _ in pts})
        runs, start, prev = [], cols[0], cols[0]
        for x in cols[1:]:
            if x - prev >= 3:
                runs.append((start, prev))
                start = x
            prev = x
        runs.append((start, prev))
        for x0, x1 in runs:
            rows = [y for x, y in pts if x0 <= x <= x1]
            out.append([x0, min(rows), x1 + 1, max(rows) + 1])
    merged = []
    for r in out:
        for m in merged:
            if m[3] == r[1] and abs(m[0] - r[0]) <= 2 and abs(m[2] - r[2]) <= 2:
                m[0], m[2], m[3] = min(m[0], r[0]), max(m[2], r[2]), r[3]
                break
        else:
            merged.append(list(r))
    return [[x0 - PIVOT[0], y0 - PIVOT[1], x1 - PIVOT[0], y1 - PIVOT[1]] for x0, y0, x1, y1 in merged]


def hurt_regions(cls, head_mass, head_box, hip_y, shoes=()):
    """Separa os pixels opacos em cabeça, tronco e pernas e cobre cada região.

    Cabeça: bloco de cabelo do topo e rosto, sem o quarto superior do volume do
    cabelo (golpe que só raspa o penteado não conta) e sem nada abaixo do queixo.
    Pernas: calça, tênis e contornos abaixo do quadril. Braços: pele fora da
    cabeça (antebraços e mãos), separada para o jogo decidir quando contam.
    Tronco: o resto (camisa, mangas e contornos). Sem cabeça ou quadril detectados, a região correspondente fica
    vazia em vez de estimada.
    """
    head, body, legs, arms = set(), set(), set(), set()
    mass = set(head_mass or [])
    shoe = {p for g in shoes for p in g}
    # Só blocos grandes de calça: o emblema azul e reflexos na camisa ficam fora.
    jeans = {p for g in components(cls, {'jeans'}) if len(g) >= 30 for p in g}
    if head_box:
        hx0, hy0, hx1, hy1 = head_box
        cut = hy0 + (hy1 - hy0) // 4
    for p, c in cls.items():
        x, y = p
        # Dentro da caixa da cabeça: cabelo (sem o quarto superior), rosto e o
        # punho erguido diante dele. Fora da guarda ativa, um golpe no rosto
        # coberto só pela mão conta como cabeça, como antes.
        if head_box and hx0 <= x <= hx1 and hy0 <= y <= hy1 and (p in mass or c in ('skin', 'hair', 'other')):
            if y >= cut:
                head.add(p)
            continue
        # Calça e tênis são perna mesmo acima da linha do quadril (perna erguida no chute).
        if p in jeans or p in shoe or (hip_y is not None and y >= hip_y and c not in ('green', 'yellow')):
            legs.add(p)
        elif c == 'skin':
            arms.add(p)
        else:
            body.add(p)
    return {'head': rects(head), 'body': rects(body), 'legs': rects(legs), 'arms': rects(arms)}


def analyse(cell):
    px = cell.load()
    cls = {}
    for y in range(CELL_H):
        for x in range(CELL_W):
            c = classify(*px[x, y])
            if c:
                cls[(x, y)] = c
    limits = []
    opaque = list(cls)
    if not opaque:
        return None
    top = min(y for _, y in opaque)
    bottom = max(y for _, y in opaque)

    # Cabeça: maior bloco de cabelo no topo + pele do rosto junto dele.
    hair = [g for g in components(cls, {'hair'}) if min(y for _, y in g) <= top + 4]
    head = None
    head_box = None
    mass = None
    if hair:
        mass = max(hair, key=len)
        hx0, hx1 = min(x for x, _ in mass), max(x for x, _ in mass)
        hy0, hy1 = min(y for _, y in mass), max(y for _, y in mass)
        face = [p for p in cls if cls[p] == 'skin' and hx0 - 3 <= p[0] <= hx1 + 3 and hy0 <= p[1] <= hy1 + 5]
        pts = mass + face
        cx, cy = centroid(pts)
        head_box = (hx0 - 2, hy0, hx1 + 2, max(hy1, max((y for _, y in face), default=hy1)) + 1)
        head = local(cx, cy)
        head['r'] = round(max(hx1 - hx0, head_box[3] - hy0) / 2, 2)
        head['chin'] = round(head_box[3] - PIVOT[1], 2)  # base do rosto
    else:
        limits.append('head: cabelo não separado no topo')

    # Tronco: camisa (branco/verde/amarelo) conectada ao verde.
    shirt_groups = components(cls, {'white', 'green', 'yellow'})
    shirt = max(shirt_groups, key=len) if shirt_groups else None
    torso = None
    if shirt and len(shirt) > 40:
        sx, sy = centroid(shirt)
        torso = local(sx, sy)
        torso['top'] = round(min(y for _, y in shirt) - PIVOT[1], 2)
        torso['bottom'] = round(max(y for _, y in shirt) - PIVOT[1], 2)
    else:
        limits.append('torso: camisa sem massa suficiente')

    # Quadril: linha superior do maior bloco de calça (o emblema azul fica de fora).
    jean_groups = components(cls, {'jeans'})
    jeans = max(jean_groups, key=len) if jean_groups else []
    hip = None
    if len(jeans) > 30:
        jy = min(y for _, y in jeans)
        row = [p for p in jeans if p[1] <= jy + 2]
        hip = local(*centroid(row))
    else:
        limits.append('hip: calça não encontrada')

    # Tênis: blocos claros fora da caixa da camisa, encostados na calça ou abaixo do quadril.
    box = None
    if shirt:
        box = (min(x for x, _ in shirt) - 1, min(y for _, y in shirt) - 1, max(x for x, _ in shirt) + 1, max(y for _, y in shirt) + 1)
    hip_y = hip['y'] + PIVOT[1] if hip else bottom - 20
    shoes = []
    for g in components(cls, {'white', 'skin', 'other'}):
        whites = [p for p in g if cls[p] == 'white']
        if len(whites) < 3 or len(g) > 160:
            continue
        cx, cy = centroid(whites)
        inside = box and box[0] <= cx <= box[2] and box[1] <= cy <= box[3]
        if inside or touches(g, cls, {'green', 'yellow'}):
            continue
        beside = box and (cx > box[2] or cx < box[0])
        if (cy > hip_y + 6 or beside) and touches(g, cls, {'jeans', 'hair'}):
            shoes.append(g)
    feet = []
    for g in shoes:
        x, y = centroid(g)
        tip = max(g, key=lambda p: (p[0], -p[1]))
        feet.append({'x': round(x - PIVOT[0], 2), 'y': round(y - PIVOT[1], 2),
                     'tipX': round(tip[0] - PIVOT[0], 2), 'tipY': round(tip[1] - PIVOT[1], 2), 'n': len(g)})
    feet.sort(key=lambda f: f['tipX'])
    if not feet:
        limits.append('feet: tênis não separado da camisa/calça')

    # Mãos: blocos de pele fora da caixa da cabeça.
    hands = []
    # Pixels de pele dentro da caixa da cabeça saem antes: um braço estendido
    # encostado no queixo não pode ser absorvido pelo rosto.
    arms = {p: c for p, c in cls.items() if not (head_box and head_box[0] <= p[0] <= head_box[2] and head_box[1] <= p[1] <= head_box[3])}
    for g in components(arms, {'skin'}):
        cx, cy = centroid(g)
        if len(g) < 3:
            continue
        if head_box and head_box[0] <= cx <= head_box[2] and head_box[1] <= cy <= head_box[3]:
            continue
        if any(set(g) & set(shoe) for shoe in shoes) or len(g) < 6:
            continue  # tons bege do tênis
        tip = max(g, key=lambda p: p[0])
        hands.append({'x': round(cx - PIVOT[0], 2), 'y': round(cy - PIVOT[1], 2),
                      'tipX': round(tip[0] - PIVOT[0], 2), 'tipY': round(tip[1] - PIVOT[1], 2), 'n': len(g)})
    hands.sort(key=lambda h: h['tipX'])
    if not hands:
        limits.append('fists: mãos encostadas ao rosto ou cobertas')

    # Joelho: ponto mais à frente da calça entre o quadril e a canela.
    knee = None
    if hip and jeans:
        thigh = [p for p in jeans if hip['y'] + PIVOT[1] + 4 <= p[1] <= bottom - 14]
        if thigh:
            k = max(thigh, key=lambda p: p[0])
            knee = local(*k)

    hurt = hurt_regions(cls, mass, head_box, hip['y'] + PIVOT[1] if hip else None, shoes)

    support = max((p for p in opaque if p[1] >= bottom - 1), key=lambda p: p[0], default=None)
    limits.append('elbows: manga clara e antebraço não têm contraste suficiente; sem marcador')
    return {
        'head': head, 'torso': torso, 'hip': hip,
        'fists': hands[-2:], 'feet': feet[-2:],
        'frontFist': hands[-1] if hands else None,
        'frontFoot': feet[-1] if feet else None,
        'frontKnee': knee,
        'hurt': hurt,
        'ground': local(*support) if support else None,
        'bounds': {'x0': min(x for x, _ in opaque) - PIVOT[0], 'x1': max(x for x, _ in opaque) - PIVOT[0],
                   'y0': top - PIVOT[1], 'y1': bottom - PIVOT[1]},
        'limits': limits,
    }


# Outros personagens com o mesmo uniforme: atlas, dados, saída e clips.
CHARACTERS = {
    'sorriso': (ATLAS, DATA, OUT, CLIPS),
    'miguel': (ROOT / 'assets' / 'miguel.png', ROOT / 'assets' / 'miguel.json', ROOT / 'assets' / 'miguel-markers.json',
               ['m_enterGuard', 'm_walkFwd', 'm_walkBack', 'm_lowerGuard', 'm_block']),
}


def main(character='sorriso'):
    global REDDISH_HAIR
    REDDISH_HAIR = character == 'miguel'
    atlas_path, data_path, out_path, clip_ids = CHARACTERS[character]
    atlas = Image.open(atlas_path).convert('RGBA')
    data = json.loads(data_path.read_text(encoding='utf-8'))
    clips = {c['id']: c for c in data['clips']}
    out = {'source': str(atlas_path.relative_to(ROOT)).replace('\\', '/'), 'method': 'classes de cor + componentes conectados; ver scripts/extract-markers.py',
           'pivot': list(PIVOT), 'facing': 1, 'clips': {}}
    for cid in clip_ids:
        clip = clips.get(cid)
        if not clip:
            continue
        frames = []
        for f in clip['frames']:
            i = f['index']
            x, y = (i % COLUMNS) * CELL_W, (i // COLUMNS) * CELL_H
            m = analyse(atlas.crop((x, y, x + CELL_W, y + CELL_H)))
            m['index'] = i
            frames.append(m)
        out['clips'][cid] = frames
    out_path.write_text(json.dumps(out, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    print(f'{out_path.relative_to(ROOT)}: {sum(len(v) for v in out["clips"].values())} quadros')


if __name__ == '__main__':
    import sys
    for name in (sys.argv[1:] or ['sorriso']):
        main(name)
