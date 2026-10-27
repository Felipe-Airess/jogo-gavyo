"""Acrescenta ao atlas do Miguel o lote 3 (folhas do ChatGPT já padronizadas).

Uso: python scripts/add-miguel-lote3.py
Fonte: arte/personagens/miguel/lote3/<clip>/NN.png (128x96, pivô 64,88).
Lotes 1 e 2 ficam como estão; rodar de novo substitui só o lote 3.

Tempos: medidos nos vídeos do Miguel (arte/personagens/miguel/tempos-dos-videos.json),
preparação ×1,2 e recuperação ×1,5, para o golpe sair rápido e o erro ainda
ser punível. `skip`: quadros descartados por defeito do desenho.
"""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'arte' / 'personagens' / 'miguel' / 'lote3'
ATLAS, DATA = ROOT / 'assets' / 'miguel.png', ROOT / 'assets' / 'miguel.json'
CELL, COLUMNS = (128, 96), 8
# id: (pasta, quadro de contato 0-based depois do skip, ms de preparação, ms depois do contato, loop, skip)
CLIPS = {
    'm3_idle': ('m3_idle', None, 200, 200, True, []),
    'm3_walk': ('m3_walkNeutral', None, 125, 125, True, []),
    'm3_jab': ('m3_jab', 3, 60, 56, False, []),
    # o quadro 2 da folha estica o braço antes da hora (pulo na animação)
    'm3_cross': ('m3_cross', 3, 53, 104, False, [1]),
    'm3_crossBody': ('m3_crossBody', 4, 86, 93, False, []),
    'm3_overhand': ('m3_overhand', 5, 82, 83, False, []),
    'm3_roundKick': ('m3_roundKick', 5, 84, 75, False, []),
    'm3_stepKick': ('m3_stepKick', 6, 94, 114, False, []),
    'm3_lowKick': ('m3_lowKick', 4, 106, 105, False, []),
    'm3_knee': ('m3_knee', 3, 112, 100, False, []),
}


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
        for k, p in enumerate(files[cid]):
            cell = Image.open(p).convert('RGBA')
            assert cell.size == CELL, (p, cell.size)
            atlas.paste(cell, ((index % COLUMNS) * CELL[0], (index // COLUMNS) * CELL[1]))
            ms = pre if contact is None or k < contact else post
            frames.append({'index': index, 'duration': ms, 'sourceFacing': 1, 'file': f'{folder}/{p.name}', 'root': [64, 88],
                           'phase': '' if contact is None else 'preparação' if k < contact else 'contato' if k <= contact + 1 else 'recuperação'})
            index += 1
        clips.append({'id': cid, 'loop': loop, 'source': 'lote3', 'frames': frames,
                      'durations': [f['duration'] for f in frames], 'totalMs': sum(f['duration'] for f in frames),
                      'contactFrames': [] if contact is None else [contact, contact + 1]})
    data['clips'] = keep + clips
    atlas.save(ATLAS)
    DATA.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Miguel: {base} quadros dos lotes 1–2 + {index - base} do lote 3; atlas {atlas.size}.')


if __name__ == '__main__':
    main()
