import test from 'node:test';
import assert from 'node:assert/strict';
import { Match, MATCH, damageTaken } from '../src/duel/match.mjs';
import { AI_LEVELS } from '../src/duel/ai.mjs';

const TICK = 1000 / 60;
const fighter = (id, head = 0) => ({ id, condition: { head, body: 0, legs: 0 }, balance: 100, stamina: 100 });
const duel = (result = null, a = fighter(1), b = fighter(2)) => ({ result, fighters: [a, b] });
const run = (m, ms, d) => { const out = []; for (let t = 0; t < ms; t += TICK) { const e = m.update(TICK, d); if (e) out.push(e); } return out; };

test('round começa com anúncio e só abre os comandos no "LUTA!"', () => {
  const m = new Match();
  assert.equal(m.phase, 'intro');
  assert.equal(m.inputsOpen, false);
  assert.equal(m.banner.title, 'ROUND 1');
  run(m, MATCH.introMs - MATCH.fightCallMs + 20, duel());
  assert.equal(m.banner.title, 'LUTA!');
  run(m, MATCH.fightCallMs, duel());
  assert.equal(m.inputsOpen, true);
  assert.equal(m.banner, null);
});

test('nocaute dá o round, anuncia K.O. e passa ao próximo round', () => {
  const m = new Match();
  run(m, MATCH.introMs + 20, duel());
  const events = run(m, 50, duel({ winner: 1, reason: 'Nocaute.' }));
  assert.deepEqual(m.wins, [1, 0]);
  assert.equal(m.banner.title, 'K.O.');
  assert.ok(events.includes('roundEnd'));
  const later = run(m, MATCH.roundEndMs + 20, duel({ winner: 1 }));
  assert.ok(later.includes('nextRound'));
  assert.equal(m.round, 2);
  assert.equal(m.phase, 'intro');
});

test('melhor de 3 termina com duas vitórias', () => {
  const m = new Match({ bestOf: 3 });
  for (let r = 0; r < 2; r++) {
    run(m, MATCH.introMs + 20, duel());
    run(m, 50, duel({ winner: 2 }));
    run(m, MATCH.roundEndMs + 20, duel({ winner: 2 }));
  }
  assert.equal(m.finished, true);
  assert.equal(m.winner, 2);
  assert.deepEqual(m.wins, [0, 2]);
  assert.equal(m.update(TICK, duel()), null, 'partida encerrada não anda');
});

test('última chance vira "ROUND FINAL"', () => {
  const m = new Match({ bestOf: 3 });
  for (const w of [1, 2]) { run(m, MATCH.introMs + 20, duel()); run(m, 50, duel({ winner: w })); run(m, MATCH.roundEndMs + 20, duel({ winner: w })); }
  assert.equal(m.banner.title, 'ROUND FINAL');
});

test('tempo esgotado: vence quem apanhou menos; igual é empate sem ponto', () => {
  const m = new Match({ seconds: 2 });
  run(m, MATCH.introMs + 20, duel());
  run(m, 2100, duel(null, fighter(1, 10), fighter(2, 40)));
  assert.equal(m.outcome.by, 'time');
  assert.equal(m.outcome.winner, 1);
  assert.equal(m.banner.title, 'TEMPO!');
  const e = new Match({ seconds: 2 });
  run(e, MATCH.introMs + 20, duel());
  run(e, 2100, duel(null, fighter(1, 20), fighter(2, 20)));
  assert.equal(e.outcome.by, 'draw');
  assert.deepEqual(e.wins, [0, 0]);
  assert.ok(damageTaken(fighter(1, 30)) > damageTaken(fighter(1, 10)));
});

test('sem tempo o relógio não decide', () => {
  const m = new Match({ seconds: 0 });
  run(m, MATCH.introMs + 20, duel());
  run(m, 200000, duel(null, fighter(1, 10), fighter(2, 40)));
  assert.equal(m.phase, 'fight');
  assert.equal(m.clockSeconds, null);
});

test('round único encerra no primeiro nocaute', () => {
  const m = new Match({ bestOf: 1 });
  run(m, MATCH.introMs + 20, duel());
  run(m, 50 + MATCH.roundEndMs, duel({ winner: 1 }));
  assert.equal(m.finished, true);
  assert.equal(m.winner, 1);
});

test('empates em sequência não prendem a partida', () => {
  const m = new Match({ bestOf: 3, seconds: 1 });
  run(m, MATCH.introMs + 20, duel());
  run(m, 50, duel({ winner: 1 }));
  run(m, MATCH.roundEndMs + 20, duel());
  for (let i = 0; i < MATCH.drawLimit; i++) {
    if (m.finished) break;
    run(m, MATCH.introMs + 1100 + MATCH.roundEndMs + 60, duel());
  }
  assert.equal(m.finished, true);
  assert.equal(m.winner, 1);
});

test('três níveis de IA, do mais lento ao mais rápido', () => {
  const { calmo, firme, dificil } = AI_LEVELS;
  assert.ok(calmo.reaction > firme.reaction && firme.reaction > dificil.reaction);
  assert.ok(dificil.reaction > 140, 'ainda não lê o jab de 161 ms');
});
