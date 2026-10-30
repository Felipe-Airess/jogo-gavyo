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
    adaptar_specs(target, miguel)
    (target / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(manifest))

def adaptar_specs(target, miguel):
    """specs.json = specs.base.json com os quadros dos golpes do Miguel levados
    para os clipes novos (moveset do Mixamo tem outro numero de quadros)."""
    base = json.loads((target / 'specs.base.json').read_text(encoding='utf-8'))
    if miguel == 'miguel3d':
        velho = {c['id']: c for c in json.loads((ROOT / 'assets/miguel.json').read_text(encoding='utf-8'))['clips']}
        novo = {c['id']: c for c in json.loads((ROOT / 'assets/miguel3d.json').read_text(encoding='utf-8'))['clips']}

        def escala(i, a, b):
            na, nb = len(velho[a]['frames']), len(novo[b]['frames'])
            return int(round(float(i) * (nb - 1) / max(na - 1, 1)))

        def reamostra(lista, n):
            return [lista[int(round(k * (len(lista) - 1) / max(n - 1, 1)))] for k in range(n)]

        for m in base['miguel'].values():
            cid = m.get('clip')
            if cid not in novo or cid not in velho:
                continue
            cont = novo[cid].get('contactFrames') or []
            n = len(novo[cid]['frames'])
            if 'active' in m:
                m['active'] = cont[:1] if cont else [escala(i, cid, cid) for i in m['active']]
            for i, h in enumerate(m.get('hits', [])):
                h['frames'] = [cont[i]] if i < len(cont) else [escala(f, cid, cid) for f in h['frames']]
            par = m.get('pair')
            if par:
                if isinstance(par.get('gap'), list):
                    par['gap'] = reamostra(par['gap'], n)
                for c in par.get('contacts', []):
                    c['frame'] = cont[0] if cont else escala(c['frame'], cid, cid)
                for quem, v in par.get('victim', {}).items():
                    fr = reamostra(v['frames'], n)
                    if quem == 'miguel' and v['clip'] in novo:
                        fr = [escala(x, v['clip'], v['clip']) for x in fr]
                    v['frames'] = fr
    (target / 'specs.json').write_text(json.dumps(base, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')


if __name__ == '__main__':
    prepare()
