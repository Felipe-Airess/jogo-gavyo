// Oráculo de desenvolvimento: lutas reais do duelo Phaser gravadas tick a tick
// (entradas + estado). O teste Godot reproduz as mesmas entradas no motor
// GDScript e compara o estado. O jogo Godot nunca executa este JavaScript.
// Uso: node godot-poc/tools/generate_duel_traces.mjs
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { Duel, TICK } from '../../src/duel/duel.mjs';
import { DuelAI } from '../../src/duel/ai.mjs';

const read = p => JSON.parse(readFileSync(new URL(`../../assets/${p}`, import.meta.url)));
const clips = Object.fromEntries(read('sorriso-v70.json').clips.map(c => [c.id, c]));
const roster = { miguel: { clips: Object.fromEntries(read('miguel.json').clips.map(c => [c.id, c])), markers: read('miguel-markers.json') } };
const markers = read('sorriso-markers.json');
const make = (a, b) => { const d = new Duel({ clips, markers, roster }); d.setCharacters([a, b]); return d; };
const r6 = v => (typeof v === 'number' ? Math.round(v * 1e6) / 1e6 : v);

function snap(d) {
  return {
    clock: r6(d.clock), hitstop: r6(d.hitstop), result: d.result ? d.result.winner : null,
    lastHit: d.lastHit ? [d.lastHit.attacker, d.lastHit.move, d.lastHit.zone, d.lastHit.kind, r6(d.lastHit.damage), d.lastHit.quality] : null,
    f: d.fighters.map(f => {
      const a = d.animation(f);
      return [r6(f.x), r6(f.vx), f.facing, f.state, f.move ?? null, r6(f.moveT), r6(f.stamina), r6(f.balance),
        r6(f.condition.head), r6(f.condition.body), r6(f.condition.legs), f.chain, a.clip, a.frame, r6(d.drawX(f))];
    }),
  };
}

// Roteiro: lista de [ms, entrada do 1, entrada do 2]; o resto do tempo, nada.
function scripted(d, script, ms) {
  const out = { start: d.fighters.map(f => f.x), inputs: [], states: [] };
  let t = 0;
  while (t < ms && !d.result) {
    const step = script.find(s => Math.abs(s[0] - t) < TICK / 2);
    const inp = [step ? step[1] : {}, step ? step[2] || {} : {}];
    d.tick(inp);
    out.inputs.push(inp); out.states.push(snap(d));
    t += TICK;
  }
  return out;
}

function aiFight(d, seedA, seedB, levelA, levelB, ms) {
  const a = new DuelAI(seedA, levelA), b = new DuelAI(seedB, levelB);
  const out = { start: d.fighters.map(f => f.x), ai: [[seedA, levelA], [seedB, levelB]], inputs: [], states: [] };
  for (let t = 0; t < ms && !d.result; t += TICK) {
    const inp = [a.input(d, d.player, d.rival), b.input(d, d.rival, d.player)];
    d.tick(inp);
    out.inputs.push(inp); out.states.push(snap(d));
  }
  return out;
}

const scenarios = [];
const add = (name, chars, run) => { const d = make(...chars); scenarios.push({ name, chars, ...run(d) }); };
add('ia-miguel-sorriso', ['miguel', 'sorriso'], d => aiFight(d, 11, 23, 'firme', 'firme', 20000));
add('ia-sorriso-miguel', ['sorriso', 'miguel'], d => aiFight(d, 5, 9, 'dificil', 'calmo', 20000));
add('ia-miguel-miguel', ['miguel', 'miguel'], d => aiFight(d, 3, 4, 'dificil', 'dificil', 20000));
add('ia-sorriso-sorriso', ['sorriso', 'sorriso'], d => aiFight(d, 7, 8, 'firme', 'dificil', 20000));
const R = { right: true }, L = { left: true };
add('roteiro-clinch-miguel', ['miguel', 'sorriso'], d => { d.rival.x = d.player.x + 26; return scripted(d, [[0, { grab: true }], [400, { kick: true }], [1100, { attack: true }], [1800, { right: true }], [1817, { right: true }], [2600, { grab: true }], [3200, {}, { grab: true }], [3700, {}, { attack: true }], [3900, {}, { attack: true }], [4100, {}, { attack: true }]], 6000); });
add('roteiro-arremesso', ['miguel', 'sorriso'], d => { d.rival.x = d.player.x + 36; return scripted(d, [[0, { attack: true }], [180, { attack: true, right: true }], [360, { grab: true }], [2400, { attack: true }], [2700, { kick: true }]], 5000); });
add('roteiro-arremessado', ['sorriso', 'miguel'], d => { d.rival.x = d.player.x + 40; return scripted(d, [[0, { attack: true }], [180, { attack: true, down: true }], [360, { grab: true }]], 4000); });
add('roteiro-chutes-aparo', ['miguel', 'sorriso'], d => { d.rival.x = d.player.x + 40; return scripted(d, [[0, { kick: true }], [900, { kick: true, up: true }], [1900, { kick: true, right: true }], [2900, { attack: true }, {}], [2970, {}, { guard: true }], [3600, R], [3617, R], [3634, R], [4300, { run: true, right: true }], [4317, { run: true, right: true }], [4334, { run: true, right: true }]], 6000); });
add('roteiro-corrida-sorriso', ['sorriso', 'miguel'], d => { const s = []; for (let t = 0; t < 1500; t += TICK) s.push([t, { right: true, run: true }]); for (let t = 2000; t < 2600; t += TICK) s.push([t, L]); s.push([2700, { kick: true, down: true }]); return scripted(d, s, 4000); });

mkdirSync(new URL('../tests/fixtures/', import.meta.url), { recursive: true });
writeFileSync(new URL('../tests/fixtures/duel_traces.json', import.meta.url), JSON.stringify(scenarios));
console.log(scenarios.map(s => `${s.name}: ${s.states.length} ticks, fim ${s.states.at(-1).result ?? '-'}`).join('\n'));
