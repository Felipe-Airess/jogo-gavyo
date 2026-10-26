"""Recorta as duas folhas fornecidas, sem gerar ou redesenhar poses.

Preparação opcional de assets: Python 3 e Pillow. O jogo não depende de Python.
"""
from collections import deque
from pathlib import Path
import json
from PIL import Image, ImageFilter, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'arte/personagens/miguel/fontes'
CELL = (128, 96)
PIVOT = (64, 88)


def silhouette(image):
    """Cor/contorno delimitam o corpo; preencher só interiores preserva a polo branca."""
    w, h = image.size
    seed = Image.new('L', (w, h))
    seed.putdata([255 if max(p)-min(p) > 20 or max(p) < (145 if i//w > h*.88 else 215) else 0
                  for i, p in enumerate(image.getdata())])
    seed = seed.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
    # Descartar riscos de revisão e pontos soltos, mantendo cabeça/mãos separadas.
    pixels = seed.load()
    seen = set()
    clean = Image.new('L', (w, h))
    dest = clean.load()
    for y in range(h):
        for x in range(w):
            if not pixels[x, y] or (x, y) in seen:
                continue
            queue = deque([(x, y)])
            seen.add((x, y))
            component = []
            while queue:
                px, py = queue.popleft()
                component.append((px, py))
                for nx, ny in ((px-1, py), (px+1, py), (px, py-1), (px, py+1)):
                    if 0 <= nx < w and 0 <= ny < h and pixels[nx, ny] and (nx, ny) not in seen:
                        seen.add((nx, ny))
                        queue.append((nx, ny))
            if len(component) >= 30 and max(p[1] for p in component)-min(p[1] for p in component) >= 5:
                for p in component:
                    dest[p] = 255
    padded = Image.new('L', (w+2, h+2))
    padded.paste(clean, (1, 1))
    ImageDraw.floodfill(padded, (0, 0), 128)
    return padded.crop((1, 1, w+1, h+1)).point(lambda p: 0 if p == 128 else 255)


def prepare():
    atlas = Image.new('RGBA', (8*CELL[0], 4*CELL[1]))
    clips = []
    definitions = [
        ('idle', 'miguel_idle_10_quadros.png', [(0, 383, [0, 172, 328, 470, 619, 758, 928, 1079, 1225, 1368, 1536])], 70/380, 350),
        ('guard', 'miguel_guarda_16_quadros.png', [(0, 241, [0, 171, 346, 527, 721, 954, 1150, 1357, 1536]),
                                                (241, 464, [0, 174, 343, 523, 717, 918, 1140, 1368, 1536])], 66/240, 150),
    ]
    index = 0
    for name, filename, rows, scale, duration in definitions:
        image = Image.open(SOURCE / filename).convert('RGB')
        frames = []
        for y0, y1, boundaries in rows:
            for x0, x1 in zip(boundaries, boundaries[1:]):
                crop = image.crop((x0, y0, x1, y1))
                alpha = silhouette(crop)
                if x0 == 0 and y0 == 0:
                    # Rabisco no canto superior da folha, fora do cabelo.
                    ImageDraw.Draw(alpha).rectangle((0, 0, 70 if name == 'idle' else 80, 7), fill=0)
                box = alpha.getbbox()
                sprite = crop.convert('RGBA')
                sprite.putalpha(alpha)
                sprite = sprite.crop(box)
                # Uma escala uniforme por folha, conservando as diferenças de postura.
                size = tuple(max(1, round(n*scale)) for n in sprite.size)
                sprite = sprite.resize(size, Image.Resampling.NEAREST)
                at = (PIVOT[0]-size[0]//2, PIVOT[1]-size[1]+1)
                cell = Image.new('RGBA', CELL)
                cell.alpha_composite(sprite, at)
                atlas.paste(cell, ((index % 8)*CELL[0], (index // 8)*CELL[1]))
                frames.append({'index': index, 'duration': duration,
                               'sourceFacing': -1 if name == 'guard' and len(frames) >= 14 else 1,
                               'source': [x0+box[0], y0+box[1], x0+box[2], y0+box[3]],
                               'draw': [*at, *size], 'root': list(PIVOT)})
                index += 1
        clips.append({'id': name, 'loop': True, 'frames': frames,
                      'totalMs': len(frames)*duration, 'source': filename,
                      'scale': scale})
    atlas.save(ROOT / 'assets/miguel.png')
    data = {'name': 'Miguel', 'frame': list(CELL), 'columns': 8, 'root': list(PIVOT),
            'clips': clips, 'reference': 'Sorriso: guarda 66 px; Miguel em pé 70 px.',
            'preparation': 'Recorte, máscara do fundo e redução proporcional por nearest-neighbor. Sem poses novas.'}
    (ROOT / 'assets/miguel.json').write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n')
    print(f'Miguel: {index} quadros, célula {CELL}, pivô {PIVOT}.')


if __name__ == '__main__':
    prepare()
