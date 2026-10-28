"""Serve only the exported game, not the repository or source files."""
import argparse
import functools
import http.server
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--port', type=int, default=8060)
args = parser.parse_args()
web = Path(__file__).resolve().parents[1] / 'web'
if not (web / 'index.html').is_file():
    raise SystemExit('Build absent: run bash godot-poc/tools/build_web.sh first.')
class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      '.wasm': 'application/wasm', '.pck': 'application/octet-stream'}
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()
print(f'GAVYO Godot: port {args.port}', flush=True)
http.server.ThreadingHTTPServer(('0.0.0.0', args.port), functools.partial(Handler, directory=str(web))).serve_forever()
