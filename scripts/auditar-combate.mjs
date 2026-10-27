// Auditoria do combate do duelo, por simulação (sem navegador).
// Uso: node scripts/auditar-combate.mjs [atacante] [defensor]
//
// Para cada golpe em pé: de que distância (entre pivôs) ele acerta um
// adversário parado, qual região e qualidade, e a distância em que os corpos
// param quando um anda até o outro ("encostado"). Golpe que não acerta nessa
// distância nem um pouco mais longe é golpe que "não sai do lugar" no jogo.
import fs from 'node:fs';
import { Duel, TICK } from '../src/duel/duel.mjs';

const read = p => JSON.parse(fs.readFileSync(new URL(p, import.meta.url)));
const sorriso = read('../assets/sorriso-v70.json'), markers = read('../assets/sorriso-markers.json');
const miguel = read('../assets/miguel.json'), miguelMarkers = read('../assets/miguel-markers.json');
const clips = Object.fromEntries(sorriso.clips.map(c => [c.id, c]));
const mclips = Object.fromEntries(miguel.clips.map(c => [c.id, c]));
const make = (a, b) => {
  const d = new Duel({ clips, markers, roster: { miguel: { clips: mclips, markers: miguelMarkers } } });
  d.setCharacters([a, b]);
  return d;
};

export function restGap(a, b) {
  const d = make(a, b);
  for (let t = 0; t < 3000; t += TICK) d.tick([{ right: true }, {}]);
  for (let t = 0; t < 300; t += TICK) d.tick([{}, {}]);
  return d.rival.x - d.player.x;
}

export function probeMove(a, b, id, gap) {
  const d = make(a, b);
  d.rival.x = d.player.x + gap;
  d.tick([{}, {}]);
  if (!d.begin(d.player, id, false)) return null;
  const m = d.moveOf(d.player);
  for (let t = 0; t < m.duration + 400 && !d.lastHit; t += TICK) d.tick([{}, {}]);
  const h = d.lastHit;
  return { hit: !!h && h.attacker === 1, zone: h?.zone, quality: h?.quality, kind: h?.kind };
}

function audit(a, b) {
  const rest = restGap(a, b);
  const d = make(a, b);
  console.log(`\n${a.toUpperCase()} batendo em ${b.toUpperCase()} — corpos param a ${rest.toFixed(1)} px (pivô a pivô)`);
  console.log('golpe'.padEnd(20), 'alcance', 'acerta de..até', 'parado', '+8px', 'região/qualidade no encostado');
  for (const [id, m] of Object.entries(d.movesOf(d.player))) {
    if (m.ground || m.throw || m.clinch || m.pair) continue;
    const hits = [];
    for (let g = 20; g <= 90; g += 2) { const r = probeMove(a, b, id, g); if (r?.hit) hits.push(g); }
    const at = probeMove(a, b, id, Math.round(rest)), far = probeMove(a, b, id, Math.round(rest) + 8);
    const range = hits.length ? `${hits[0]}..${hits.at(-1)}` : '—';
    console.log(id.padEnd(20), String(Math.round(d.reachOf(d.player)[id] || 0)).padStart(7), range.padStart(14),
      (at?.hit ? 'SIM' : 'não').padStart(6), (far?.hit ? 'SIM' : 'não').padStart(5),
      `${at?.zone || '-'}/${at?.quality || '-'}`.padStart(16));
  }
}

if (import.meta.url.endsWith(process.argv[1].replaceAll('\\', '/').split('/').pop())) {
  const [a, b] = process.argv.slice(2);
  const pairs = a ? [[a, b || 'sorriso']] : [['miguel', 'sorriso'], ['sorriso', 'miguel'], ['miguel', 'miguel'], ['sorriso', 'sorriso']];
  for (const [x, y] of pairs) audit(x, y);
}
