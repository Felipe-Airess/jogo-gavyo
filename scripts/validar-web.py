"""Fail before publication if the Android-friendly preset or export regresses."""
import configparser
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
preset = configparser.ConfigParser(interpolation=None)
preset.read(root / 'godot-3d/export_presets.cfg')
options = preset['preset.0.options']
assert preset['preset.0']['name'] == '"Web"'
for key, value in {
    'variant/thread_support': 'false',
    'variant/extensions_support': 'false',
    'vram_texture_compression/for_mobile': 'true',
    'progressive_web_app/enabled': 'false',
}.items():
    assert options[key] == value, f'{key} must be {value}'
project = (root / 'godot-3d/project.godot').read_text()
assert 'renderer/rendering_method="gl_compatibility"' in project
assert 'renderer/rendering_method.mobile="gl_compatibility"' in project
assert 'pointing/emulate_mouse_from_touch=false' in project
assert 'touch-action:none' in options['html/head_include']
output = Path(sys.argv[1])
for name in ['index.html', 'index.js', 'index.wasm', 'index.pck']:
    assert (output / name).stat().st_size > 0, f'Missing/empty {name}'
assert (output / 'index.wasm').read_bytes()[:4] == b'\0asm'
assert (output / 'index.pck').read_bytes()[:4] == b'GDPC'
html = (output / 'index.html').read_text()
assert 'const GODOT_THREADS_ENABLED = false;' in html
assert 'touch-action:none' in html
assert 'viewport-fit=cover' in html
print('Web export: files, WebAssembly, PCK, single-thread, mobile textures and touch configuration OK')
