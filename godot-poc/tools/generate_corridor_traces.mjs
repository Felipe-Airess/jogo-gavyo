// Oráculo de desenvolvimento do corredor: treinos do Phaser gravados quadro a
// quadro (entradas + estado). O teste Godot repete as entradas no motor GDScript.
// Uso: node godot-poc/tools/generate_corridor_traces.mjs
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { Battle } from '../../src/battle.mjs';
import { createBuildMoves } from '../../src/build-moves.mjs';
import { createMiguelCorridorMoves, miguelPlayerClips, MIGUEL_CAN, MIGUEL_FALLBACK } from '../../src/miguel-corridor.mjs';

const read = p => JSON.parse(readFileSync(new URL(`../../assets/${p}`, import.meta.url)));
const clips = Object.fromEntries(read('sorriso-v70.json').clips.map(c => [c.id, c]));
const miguelClips = miguelPlayerClips(Object.fromEntries(read('miguel.json').clips.map(c => [c.id, c])), read('miguel-markers.json'));
const r = v => (typeof v === 'number' ? Math.round(v * 1e5) / 1e5 : v);
const DT = 1000 / 60;

function make(character, mode) {
  const b = new Battle(2, 731, createBuildMoves(clips));
  b.artClips = clips;
  if (character === 'miguel') { b.moves = createMiguelCorridorMoves(miguelClips); b.can = { ...MIGUEL_CAN }; b.fallback = MIGUEL_FALLBACK; b.playerClips = miguelClips; b.reset(); }
  b.setMode(mode);
  return b;
}

function snap(b) {
  const p = b.player;
  return {
    clock: r(b.clock), hitstop: r(b.hitstop),
    p: [r(p.x), r(p.y), r(p.vx), r(p.vy), p.state, p.move ?? null, r(p.elapsed), r(p.stamina), p.hp, p.facing, p.handBlood.left, p.handBlood.right],
    e: b.enemies.map(d => [r(d.x), r(d.y), d.state, r(d.parts.head), r(d.parts.body), r(d.parts.arms), r(d.parts.legs), r(d.stun), d.facing, !!d.knockedOut, !!d.dead]),
    hit: b.lastHit ? [b.lastHit.target, b.lastHit.zone, !!b.lastHit.blocked, r(b.lastHit.damage)] : null,
  };
}

// Entradas pseudoaleatórias, puxadas para o alvo mais perto (para haver luta).
function botInputs(b, seed, frames) {
  let s = seed >>> 0;
  const rand = () => ((s = (Math.imul(s, 1664525) + 1013904223) >>> 0) / 4294967296);
  const out = { inputs: [], states: [] };
  let held = {};
  for (let i = 0; i < frames; i++) {
    if (i % 8 === 0) {
      const d = b.nearest, p = b.player;
      const toward = d ? (d.x > p.x ? 'right' : 'left') : 'right';
      held = {};
      if (rand() < 0.7) held[toward] = true; else if (rand() < 0.5) held[toward === 'right' ? 'left' : 'right'] = true;
      if (d && Math.abs(d.y - p.y) > 3) held[d.y > p.y ? 'down' : 'up'] = rand() < 0.8;
      if (rand() < 0.15) held.run = true;
      if (rand() < 0.12) held.guard = true;
    }
    const input = { ...held };
    if (rand() < 0.09) input.attack = true;
    if (rand() < 0.05) input.kick = true;
    if (rand() < 0.015) input.grab = true;
    if (rand() < 0.03) input.down = true;
    b.step(input, DT);
    out.inputs.push(input); out.states.push(snap(b));
  }
  return out;
}

const scenarios = [];
for (const [character, mode, seed] of [['sorriso', 'reaction', 1], ['sorriso', 'guard', 2], ['sorriso', 'sparring', 3], ['miguel', 'reaction', 4], ['miguel', 'sparring', 5], ['sorriso', 'reaction', 6]]) {
  const b = make(character, mode);
  scenarios.push({ name: `${character}-${mode}-${seed}`, character, mode, ...botInputs(b, seed, 2400) });
}
mkdirSync(new URL('../tests/fixtures/', import.meta.url), { recursive: true });
writeFileSync(new URL('../tests/fixtures/corridor_traces.json', import.meta.url), JSON.stringify(scenarios));
for (const s of scenarios) {
  const last = s.states.at(-1), hits = s.states.filter((x, i) => x.hit && (i === 0 || JSON.stringify(x.hit) !== JSON.stringify(s.states[i - 1].hit))).length;
  console.log(`${s.name}: ${s.states.length} quadros, ${hits} acertos, alvos ${last.e.map(e => e[2]).join('/')}, jogador ${last.p[4]} hp ${last.p[8]}`);
}
