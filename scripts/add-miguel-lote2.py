"""Acrescenta ao atlas do Miguel os quadros do segundo lote (duelo).

Uso: python scripts/add-miguel-lote2.py
Fonte: arte/personagens/miguel/lote2/ (quadros 128x96 RGBA, pivô 64,88,
olhando para a direita; limpeza técnica descrita no MANIFESTO_MIGUEL.json).
Os clips do primeiro lote (idle e guarda, usados no corredor) ficam como
estão. Rodar de novo substitui só os clips do lote 2. Nenhum quadro é
redesenhado, esticado ou duplicado: cada PNG vira uma célula do atlas.
"""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'arte' / 'personagens' / 'miguel' / 'lote2'
ATLAS, DATA = ROOT / 'assets' / 'miguel.png', ROOT / 'assets' / 'miguel.json'
CELL, COLUMNS = (128, 96), 8
# id no jogo -> pasta do lote, se repete em loop
CLIPS = [
    ('m_enterGuard', '01_entrar_na_guarda', False),
    ('m_walkFwd', '02_andar_na_guarda_frente', True),
    ('m_walkBack', '03_andar_na_guarda_tras', True),
    ('m_lowerGuard', '04_baixar_a_guarda', False),
    ('m_block', '05_bloqueio_alto', False),
]


def main():
    data = json.loads(DATA.read_text(encoding='utf-8'))
    manifest = {a['pasta']: a for a in json.loads((SRC / 'MANIFESTO_MIGUEL.json').read_text(encoding='utf-8'))['animacoes']}
    keep = [c for c in data['clips'] if c.get('source') != 'lote2']
    base = 1 + max(f['index'] for c in keep for f in c['frames'])
    old = Image.open(ATLAS).convert('RGBA')
    total = base + sum(len(manifest[folder]['frames']) for _, folder, _ in CLIPS)
    rows = (total + COLUMNS - 1) // COLUMNS
    atlas = Image.new('RGBA', (CELL[0] * COLUMNS, CELL[1] * rows))
    atlas.paste(old.crop((0, 0, old.width, min(old.height, ((base + COLUMNS - 1) // COLUMNS) * CELL[1]))), (0, 0))
    # limpa células do lote 2 que possam ter ficado de uma execução anterior
    for i in range(base, rows * COLUMNS):
        atlas.paste((0, 0, 0, 0), ((i % COLUMNS) * CELL[0], (i // COLUMNS) * CELL[1], (i % COLUMNS + 1) * CELL[0], (i // COLUMNS + 1) * CELL[1]))
    index, clips = base, []
    for cid, folder, loop in CLIPS:
        anim = manifest[folder]
        frames = []
        for fr, ms in zip(anim['frames'], anim['duracoes_ms']):
            cell = Image.open(SRC / folder / fr['file']).convert('RGBA')
            assert cell.size == CELL, (folder, fr['file'], cell.size)
            atlas.paste(cell, ((index % COLUMNS) * CELL[0], (index // COLUMNS) * CELL[1]))
            frames.append({'index': index, 'duration': ms, 'sourceFacing': 1, 'file': f'{folder}/{fr["file"]}', 'root': [64, 88]})
            index += 1
        clips.append({'id': cid, 'loop': loop, 'source': 'lote2', 'status': anim['status'], 'frames': frames,
                      'durations': [f['duration'] for f in frames], 'totalMs': sum(f['duration'] for f in frames)})
    data['clips'] = keep + clips
    atlas.save(ATLAS)
    DATA.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Miguel: {base} quadros do lote 1 + {index - base} do lote 2; atlas {atlas.size}.')


if __name__ == '__main__':
    main()
