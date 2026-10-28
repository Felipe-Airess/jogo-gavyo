"""Copy existing art, keeping source pixels, frame indices and measured boxes."""
import hashlib
import json
import shutil
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]
ROOT = PROJECT.parent
CLIPS = ('r1_idle', 'r2_walk', 'r3_jab_head', 'r3_cross_head', 'block', 'hurt')

def prepare():
    atlas = json.loads((ROOT / 'assets/sorriso-v70.json').read_text(encoding='utf-8'))
    markers = json.loads((ROOT / 'assets/sorriso-markers.json').read_text(encoding='utf-8'))
    clips = {c['id']: c for c in atlas['clips'] if c['id'] in CLIPS}
    assert len(clips) == len(CLIPS)
    for name, clip in clips.items():
        assert len(clip['frames']) == len(markers['clips'][name])
        assert len(clip['frames']) == len(clip['durations'])
    target = PROJECT / 'assets'
    target.mkdir(exist_ok=True)
    source = ROOT / 'assets/sorriso-v70.png'
    shutil.copyfile(source, target / 'sorriso.png')
    data = dict(frame=atlas['frame'], columns=atlas['columns'], root=atlas['root'],
                clips=clips, markers={c: markers['clips'][c] for c in CLIPS},
                source='assets/sorriso-v70.png', sha256=hashlib.sha256(source.read_bytes()).hexdigest())
    (target / 'combat.json').write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    print('Assets: 6 existing clips, original pixels and measured collision markers.')

if __name__ == '__main__':
    prepare()
