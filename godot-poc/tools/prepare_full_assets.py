"""Import current characters in full. Never modify source atlases or markers."""
import hashlib
import json
import shutil
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]
ROOT = PROJECT.parent

def prepare():
    target = PROJECT / 'assets/full'
    target.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for name, source in [('sorriso', 'sorriso-v70'), ('miguel', 'miguel')]:
        atlas = json.loads((ROOT / f'assets/{source}.json').read_text(encoding='utf-8'))
        markers = json.loads((ROOT / f'assets/{name}-markers.json').read_text(encoding='utf-8'))
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
