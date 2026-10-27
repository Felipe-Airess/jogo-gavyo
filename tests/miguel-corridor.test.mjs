import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { Battle } from '../src/battle.mjs';
import { createMiguelCorridorMoves, miguelCorridorRef, miguelPlayerClips, MIGUEL_CAN, MIGUEL_FALLBACK } from '../src/miguel-corridor.mjs';

const json = f => JSON.parse(fs.readFileSync(new URL('../assets/' + f, import.meta.url)));
const clips = miguelPlayerClips(Object.fromEntries(json('miguel.json').clips.map(c => [c.id, c])), json('miguel-markers.json'));
const advance = (m, ms, input = {}) => { for (let t = 0; t < ms; t += 8) m.step(input, 8); };
const miguel = () => {
  const m = new Battle(1, 731, createMiguelCorridorMoves(clips));
  m.can = { ...MIGUEL_CAN }; m.fallback = MIGUEL_FALLBACK; m.playerClips = clips;
  m.player.x = 205; return m;
};
const look = m => { const r = miguelCorridorRef(m.player, m.moves, clips); assert.ok(clips[r.clip]?.frames[r.frame], m.player.state + ' ' + r.clip + ':' + r.frame); return r.clip; };

test('corredor com Miguel: só quadros dele, em todos os estados percorridos', () => {
  const m = miguel(), seen = new Set();
  const go = (ms, input) => { for (let t = 0; t < ms; t += 8) { m.step(input, 8); seen.add(look(m)); } };
  go(300, {}); go(400, { left: true }); go(400, { right: true }); go(300, { guard: true }); go(200, {});
  m.step({ attack: true }, 8); go(600, {});
  m.step({ kick: true }, 8); go(900, {});
  for (const c of ['m3_idle', 'm4_walkFwd', 'm4_walkBack', 'm4_block']) assert.ok(seen.has(c), c);
});

test('corredor com Miguel: corpo abre a cabeça; o soco acerta com a ponta do punho desenhada', () => {
  const m = miguel();
  m.step({ attack: true }, 8);                    // jab no corpo (m4_jabBody) abaixa a guarda
  advance(m, 220);
  assert.equal(m.lastHit?.zone, 'body');
  m.lastHit = null;
  m.step({ attack: true, up: true }, 8);          // jab na cabeça (m3_jab)
  const centers = [];
  for (let t = 0; t < 400 && !m.lastHit; t += 8) { m.step({}, 8); const b = m.attackBox(); if (b && m.player.move === 'jabHead') centers.push(b.x + b.w / 2 - m.player.x); }
  assert.equal(m.player.move, 'jabHead');
  assert.ok(m.lastHit, 'acertou');
  const tips = clips.m3_jab.contactFrames.map(i => clips.m3_jab.frames[i].fist?.x).filter(x => x != null);
  assert.ok(centers.length && centers.every(c => tips.some(x => Math.abs(c - x) < 0.01)), `caixa ${centers} na ponta do punho ${tips}`);
});

test('corredor com Miguel: corre com a arte dele, sem clinch; golpe sem desenho vira o substituto', () => {
  const m = miguel();
  const seen = new Set();
  for (let t = 0; t < 800; t += 8) { m.step({ right: true, run: true }, 8); seen.add(look(m)); }
  assert.equal(m.player.state, 'run');
  assert.ok(seen.has('m4_runStart') && seen.has('m4_run'));
  m.step({}, 8); seen.add(look(m));
  m.grab();
  assert.ok(!m.player.grabbed, 'não agarra');
  m.player.facing = 1;
  assert.equal(m.choose({ attack: true, left: true }), 'low', 'trás+J: gancho no lugar do giratório');
  assert.equal(m.moves.low.clip, 'm4_hook');
});
