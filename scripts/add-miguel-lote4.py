"""Acrescenta ao atlas do Miguel o lote 4 (quadros já limpos por scripts/miguel-lote4/extrair.py).

Uso: python scripts/add-miguel-lote4.py   (rodar de novo substitui só o lote 4)

Entram as animações aprovadas na revisão. Correr, reação forte, esquiva para
trás, queda e levantar vêm das folhas refeitas (lote4/fontes/*.png).

Tempos: não há vídeo destes golpes; o total segue o golpe equivalente do
Sorriso (mesmo perfil de aceleração do lote 3). O quadro de contato é o de
maior extensão do punho/pé, medido nos pixels (mais à frente do tronco).
Andar: passada medida nos pés (abertura máxima − mínima entre as pontas).
"""
import json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'arte' / 'personagens' / 'miguel' / 'lote4'
ATLAS, DATA = ROOT / 'assets' / 'miguel.png', ROOT / 'assets' / 'miguel.json'
CELL, COLUMNS = (128, 96), 8

# id: (pasta, tipo, ms de preparação (até o contato), ms de volta) — tipo:
#   'loop' (ms = duração de cada quadro), 'once' (ms por quadro), 'strike' (contato medido)
CLIPS = {
    'm4_walkFwd': ('walkB', 'loop', 130, 0),          # pacote 3: pé sai do chão de verdade
    'm4_walkBack': ('walkA', 'loop', 140, 0),          # andar para frente tocado ao contrário = passo para trás (REVERSE)
    'm4_block': ('block', 'once', [60, 60, 70, 70, 80, 90], 0),
    'm4_hitHead': ('hitHeadLight', 'once', [50, 70, 90, 90, 80], 0),
    'm4_hitBody': ('hitBody', 'once', [50, 70, 90, 90, 80, 70], 0),
    'm4_hitLeg': ('hitLeg', 'once', [50, 70, 90, 90, 80, 70], 0),
    'm4_dazed': ('dazed', 'loop', 150, 0),
    'm4_lying': ('lying', 'loop', 450, 0),
    'm4_runStart': ('runStart', 'once', [70, 70, 70, 70, 70], 0),
    'm4_runStop': ('runStop', 'once', [70, 80, 80, 90, 90], 0),
    'm4_hitHeadHeavy': ('hitHeadHeavy', 'once', [50, 70, 90, 100, 100, 90, 80], 0),
    'm4_leanBack': ('leanBack', 'once', [60, 70, 90, 90, 80, 70], 0),
    'm4_fall': ('fall', 'once', [80, 90, 110, 140, 160, 1000], 0),
    'm4_rise': ('rise', 'once', [120, 110, 100, 90, 80, 80, 90], 0),
    'm4_run': ('run', 'loop', 70, 0),
    'm4_kickHigh': ('kickHigh', 'strike', 291, 650),
    'm4_hook': ('hook2', 'strike', 206, 478),
    'm4_jabBody': ('jabBody2', 'strike', 161, 392),
    'm4_uppercut': ('uppercut2', 'strike', 220, 460),
    'm4_elbow': ('elbow2', 'strike', 150, 380),
    'm4_jabStep': ('jabStep2', 'strike', 180, 380),
    'm4_crossStep': ('crossStep2', 'strike', 220, 440),
    'm4_comboBodyUpper': ('comboBodyUpper', 'strike', 260, 520),
    'm4_comboJabElbowKnee': ('comboJabElbowKnee', 'strike', 240, 520),
    'm4_comboLowHigh': ('comboLowHigh', 'strike', 300, 560),
    'm4_kickHigh2': ('kickHigh2', 'strike', 291, 650),
    'm4_slipCounter': ('slipCounter', 'strike', 330, 300),
    'm4_parryCounter': ('parryCounter', 'strike', 230, 400),
}


# Contato conferido no desenho (1-based) onde a medida automática erra: braço
# esticado mal passa do punho em guarda, e o tapa do aparo engana a medida.
CONTACT = {'m4_jabStep': 4, 'm4_crossStep': 5, 'm4_jabBody': 4, 'm4_uppercut': 6, 'm4_elbow': 4,
           'm4_parryCounter': 4, 'm4_hook': 5, 'm4_kickHigh2': 7,
           # combos: o último golpe (os anteriores ficam para quando houver golpe com vários contatos)
           'm4_comboBodyUpper': 12, 'm4_comboJabElbowKnee': 11, 'm4_comboLowHigh': 11}
# Tocados ao contrário (quadros na ordem inversa).
REVERSE = {'m4_walkBack'}


def eased(n_pre, n_post, pre_ms, post_ms):
    w_pre = np.linspace(1.6, 0.6, n_pre) if n_pre else np.array([])
    w_post = np.concatenate([[1.2], np.linspace(0.95, 1.5, n_post - 1)]) if n_post > 1 else np.array([1.0] * n_post)
    pre = w_pre / w_pre.sum() * pre_ms if n_pre else w_pre
    post = w_post / w_post.sum() * post_ms
    return [int(round(max(35, v))) for v in list(pre) + list(post)]


KICK = False


def reach(img):
    """Quanto o pixel mais à frente passa do centro da camisa (o tronco sem os braços)."""
    a = np.array(img); op = a[..., 3] > 0; rgb = a[..., :3].astype(int)
    white = (rgb.min(2) > 150) & (rgb.max(2) - rgb.min(2) < 45)
    green = (rgb[..., 1] > rgb[..., 0] + 25) & (rgb[..., 1] > rgb[..., 2] + 5)
    m = op & (white | green)
    ys = np.nonzero(op.any(1))[0]; top, bot = ys.min(), ys.max()
    # socos: só a metade de cima (o pé da frente não conta); chutes: o corpo inteiro
    upper = op.copy(); upper[top + int((bot - top) * 0.55):] = False
    use = op if KICK else upper
    return np.nonzero(use)[1].max() - np.nonzero(m)[1].mean()


def toe_spread(img):
    a = np.array(img)[..., 3] > 0
    ys = np.nonzero(a.any(1))[0]
    band = a[ys.max() - 4:ys.max() + 1].any(0)
    lab, n = ndimage.label(np.convolve(band, [1, 1, 1], 'same') > 0)
    tips = [np.nonzero(lab == i)[0].max() for i in range(1, n + 1) if (lab == i).sum() >= 4]
    return float(max(tips) - min(tips)) if len(tips) >= 2 else None


def main():
    data = json.loads(DATA.read_text(encoding='utf-8'))
    keep = [c for c in data['clips'] if c.get('source') != 'lote4']
    base = 1 + max(f['index'] for c in keep for f in c['frames'])
    old = Image.open(ATLAS).convert('RGBA')
    files = {cid: sorted((SRC / folder).glob('*.png')) for cid, (folder, *_) in CLIPS.items()}
    total = base + sum(len(v) for v in files.values())
    rows = (total + COLUMNS - 1) // COLUMNS
    atlas = Image.new('RGBA', (CELL[0] * COLUMNS, CELL[1] * rows))
    keep_rows = (base + COLUMNS - 1) // COLUMNS
    atlas.paste(old.crop((0, 0, old.width, min(old.height, keep_rows * CELL[1]))), (0, 0))
    for i in range(base, rows * COLUMNS):
        atlas.paste((0, 0, 0, 0), ((i % COLUMNS) * CELL[0], (i // COLUMNS) * CELL[1], (i % COLUMNS + 1) * CELL[0], (i // COLUMNS + 1) * CELL[1]))
    index, clips, notes = base, [], {}
    for cid, (folder, kind, pre, post) in CLIPS.items():
        if cid in REVERSE: files[cid] = files[cid][::-1]
        imgs = [Image.open(p).convert('RGBA') for p in files[cid]]
        n = len(imgs); contact = None; extra = {}
        if kind == 'loop': times = [pre] * n
        elif kind == 'once': times = list(pre)[:n] + [pre[-1]] * max(0, n - len(pre))
        else:
            global KICK; KICK = 'kick' in cid.lower()
            r = [reach(i) for i in imgs]
            contact = CONTACT[cid] - 1 if cid in CONTACT else int(np.argmax(r[1:-1])) + 1
            times = eased(contact, n - contact, pre, post)
            notes[cid] = {'contato': contact + 1, 'alcance_px': [round(v) for v in r]}
        if cid in ('m4_walkFwd', 'm4_walkBack'):
            sp = [s for s in (toe_spread(i) for i in imgs) if s]
            extra['stride'] = round(max(sp) - min(sp), 1)
            notes[cid] = {'abertura_px': sp, 'passada': extra['stride']}
        frames = []
        for k, (p, img) in enumerate(zip(files[cid], imgs)):
            atlas.paste(img, ((index % COLUMNS) * CELL[0], (index // COLUMNS) * CELL[1]))
            frames.append({'index': index, 'duration': times[k], 'sourceFacing': 1, 'file': f'lote4/{folder}/{p.name}', 'root': [64, 88],
                           'phase': '' if contact is None else 'preparação' if k < contact else 'contato' if k <= contact + 1 else 'recuperação'})
            index += 1
        clips.append({'id': cid, 'loop': kind == 'loop', 'source': 'lote4', 'frames': frames, **extra,
                      'durations': times, 'totalMs': sum(times),
                      'contactFrames': [] if contact is None else [contact, min(n - 1, contact + 1)]})
    data['clips'] = keep + clips
    atlas.save(ATLAS)
    DATA.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Miguel: {base} quadros anteriores + {index - base} do lote 4; atlas {atlas.size}.')
    for k, v in notes.items(): print(k, v)


if __name__ == '__main__':
    main()
