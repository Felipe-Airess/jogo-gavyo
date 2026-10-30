"""Import current characters in full. Never modify source atlases or markers."""
import hashlib
import json
import os
import shutil
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]
ROOT = PROJECT.parent

def prepare():
    target = PROJECT / 'assets/full'
    target.mkdir(parents=True, exist_ok=True)
    manifest = {}
    # Miguel: sprites renderizados do modelo 3D (arte/miguel_sprites.py, branch
    # boneco-miguel); MIGUEL_ARTE=2d volta para os desenhos dos lotes 2D.
    miguel = 'miguel3d' if os.environ.get('MIGUEL_ARTE', '3d') == '3d' else 'miguel'
    for name, source, marks in [('sorriso', 'sorriso-v70', 'sorriso'), ('miguel', miguel, miguel)]:
        atlas = json.loads((ROOT / f'assets/{source}.json').read_text(encoding='utf-8'))
        markers = json.loads((ROOT / f'assets/{marks}-markers.json').read_text(encoding='utf-8'))
        png = ROOT / f'assets/{source}.png'
        shutil.copyfile(png, target / f'{name}.png')
        data = {'frame': atlas['frame'], 'columns': atlas['columns'], 'root': atlas['root'],
                'clips': {c['id']: c for c in atlas['clips']}, 'markers': markers['clips'],
                'sha256': hashlib.sha256(png.read_bytes()).hexdigest()}
        (target / f'{name}.json').write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':'))+'\n', encoding='utf-8')
        manifest[name] = {'clips': len(atlas['clips']), 'frames': sum(len(c['frames']) for c in atlas['clips']),
                          'sha256': data['sha256']}
    (target / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(manifest))

if __name__ == '__main__':
    prepare()
