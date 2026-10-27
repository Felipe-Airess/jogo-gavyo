"""Acrescenta ao atlas do Miguel o lote 5 (quadros limpos por scripts/miguel-lote5/extrair.py).

Uso: python scripts/add-miguel-lote5.py   (rodar de novo substitui só o lote 5)

Entram: transições do andar, guarda rompida, cansado (zip de 27/10) e os itens
9-20 da prancha (chute alto refeito, arremesso, sendo arremessado, soco no
chão, pisada, apanhando no chão e o clinch). Tempos: os do pedido
(PROMPTS / 3-POSES-QUE-FALTAM) ou os sugeridos no metadados.json do zip;
golpes com o mesmo perfil de aceleração do lote 4.
"""
import importlib.util
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'arte' / 'personagens' / 'miguel' / 'lote5'
ATLAS, DATA = ROOT / 'assets' / 'miguel.png', ROOT / 'assets' / 'miguel.json'
CELL, COLUMNS = (128, 96), 8

_spec = importlib.util.spec_from_file_location('lote4', ROOT / 'scripts' / 'add-miguel-lote4.py')
lote4 = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(lote4)

# id: (pasta, tipo, ms, ms de volta, quadros usados 1-based ou None)
#   'loop'/'once': ms por quadro (número ou lista); 'strike': ms até o contato e de volta.
CLIPS = {
    # Transições: só desenho (a física do andar não espera); 3 quadros em ~160 ms.
    'm5_walkStart': ('walkStart', 'once', [55, 50, 55], 0, None),
    'm5_walkStop': ('walkStop', 'once', [55, 50, 60], 0, None),
    'm5_guardBreak': ('guardBreak', 'once', [95, 100, 100, 110, 105, 145], 0, None),
    'm5_tired': ('tired', 'loop', [150, 160, 160, 170, 160, 150], 0, None),
    # Chute alto: mesmo tempo do m4_kickHigh.
    'm5_kickHigh': ('kickHigh3', 'strike', 291, 650, None),
    'm5_throw': ('throw', 'once', [60, 55, 60, 70, 80, 90, 90, 110], 0, None),
    'm5_thrown': ('thrown', 'once', [60, 55, 60, 70, 80, 90, 90, 110, 300], 0, None),
    'm5_groundPunch': ('groundPunch', 'once', [60, 55, 60, 50, 70, 70, 75, 100], 0, None),
    'm5_stomp': ('stomp', 'once', [60, 60, 65, 50, 70, 70, 75, 100], 0, None),
    'm5_groundHit': ('groundHit', 'once', [50, 70, 90, 110], 0, None),
    'm5_clinchGrab': ('clinchGrab', 'once', [40, 40, 40, 40, 40, 60], 0, None),
    # Segurar: o 1 e o 6 da folha são guarda; o loop são os quadros curvados.
    'm5_clinchHold': ('clinchBent', 'loop', 160, 0, [2, 3, 4, 5]),
    'm5_clinchKnee': ('clinchKnee', 'strike', 180, 280, None),
    'm5_clinchRelease': ('clinchRelease', 'once', [50, 60, 60, 60, 60, 70], 0, None),
    'm5_held': ('heldSquat', 'loop', 170, 0, None),
    'm5_clinchEscape': ('clinchEscape', 'once', [50, 50, 55, 60, 60, 60, 60, 70], 0, None),
}
# Contato conferido no desenho (1-based): maior extensão do pé/joelho.
CONTACT = {'m5_clinchKnee': 5}


def main():
    data = json.loads(DATA.read_text(encoding='utf-8'))
    keep = [c for c in data['clips'] if c.get('source') != 'lote5']
    base = 1 + max(f['index'] for c in keep for f in c['frames'])
    old = Image.open(ATLAS).convert('RGBA')
    files = {}
    for cid, (folder, _, _, _, used) in CLIPS.items():
        fs = sorted((SRC / folder).glob('*.png'))
        files[cid] = [fs[i - 1] for i in used] if used else fs
    total = base + sum(len(v) for v in files.values())
    rows = (total + COLUMNS - 1) // COLUMNS
    atlas = Image.new('RGBA', (CELL[0] * COLUMNS, CELL[1] * rows))
    keep_rows = (base + COLUMNS - 1) // COLUMNS
    atlas.paste(old.crop((0, 0, old.width, min(old.height, keep_rows * CELL[1]))), (0, 0))
    for i in range(base, rows * COLUMNS):
        atlas.paste((0, 0, 0, 0), ((i % COLUMNS) * CELL[0], (i // COLUMNS) * CELL[1], (i % COLUMNS + 1) * CELL[0], (i // COLUMNS + 1) * CELL[1]))
    index, clips, notes = base, [], {}
    for cid, (folder, kind, pre, post, _) in CLIPS.items():
        imgs = [Image.open(p).convert('RGBA') for p in files[cid]]
        n = len(imgs); contact = None
        if kind == 'loop': times = list(pre) if isinstance(pre, list) else [pre] * n
        elif kind == 'once': times = list(pre)[:n] + [pre[-1]] * max(0, n - len(pre))
        else:
            lote4.KICK = True
            r = [lote4.reach(i) for i in imgs]
            contact = CONTACT[cid] - 1 if cid in CONTACT else int(np.argmax(r[1:-1])) + 1
            times = lote4.eased(contact, n - contact, pre, post)
            notes[cid] = {'contato': contact + 1, 'alcance_px': [round(v) for v in r]}
        assert len(times) == n, (cid, len(times), n)
        frames = []
        for k, (p, img) in enumerate(zip(files[cid], imgs)):
            atlas.paste(img, ((index % COLUMNS) * CELL[0], (index // COLUMNS) * CELL[1]))
            frames.append({'index': index, 'duration': times[k], 'sourceFacing': 1, 'file': f'lote5/{folder}/{p.name}', 'root': [64, 88],
                           'phase': '' if contact is None else 'preparação' if k < contact else 'contato' if k <= contact + 1 else 'recuperação'})
            index += 1
        clips.append({'id': cid, 'loop': kind == 'loop', 'source': 'lote5', 'frames': frames,
                      'durations': times, 'totalMs': sum(times),
                      'contactFrames': [] if contact is None else [contact, min(n - 1, contact + 1)]})
    data['clips'] = keep + clips
    atlas.save(ATLAS)
    DATA.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Miguel: {base} quadros anteriores + {index - base} do lote 5; atlas {atlas.size}.')
    for k, v in notes.items(): print(k, v)


if __name__ == '__main__':
    main()
