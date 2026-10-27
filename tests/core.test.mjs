import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { FixedStep } from '../src/core/fixed-step.mjs';
import { CommandBuffer, commandFrom } from '../src/core/command-buffer.mjs';
import { TouchState } from '../src/touch-controls.mjs';
import { Duel } from '../src/duel/duel.mjs';
import { DuelAI } from '../src/duel/ai.mjs';
import { Battle } from '../src/battle.mjs';

const clips = Object.fromEntries(JSON.parse(fs.readFileSync(new URL('../assets/sorriso-v70.json', import.meta.url))).clips.map(c => [c.id, c]));
const markers = JSON.parse(fs.readFileSync(new URL('../assets/sorriso-markers.json', import.meta.url)));

// Mesma linha do tempo de entradas vista por navegadores com taxas de quadro
// diferentes. As mudanças caem em múltiplos de 166⅔ ms, que são início de quadro
// em 30, 60, 120 e 144 FPS: o resultado precisa ser idêntico. (Uma entrada no
// meio de um quadro só é vista no quadro seguinte — limite do próprio navegador.)
function play(fps, ticks = 230) {
  const d = new Duel({ clips, markers }), ai = new DuelAI(3), step = new FixedStep(60);
  let n = 0;
  d.rival.x = 245;
  const at = (t, k) => t <= k * 1000 / 6 + 1e-6 && k * 1000 / 6 < t + 1000 / fps - 1e-6;
  const between = (t, a, b) => t >= a * 1000 / 6 - 1e-6 && t < b * 1000 / 6 - 1e-6;
  const timeline = t => ({ right: between(t, 1, 4), attack: at(t, 6), kick: at(t, 12), guard: between(t, 16, 19) });
  // Compara após o mesmo número de ticks: a soma de quadros em ponto flutuante
  // pode terminar um tick antes ou depois.
  for (let frame = 0; n < ticks; frame++) {
    step.advance(1000 / fps, timeline(frame * 1000 / fps), (input, dt) => { if (n++ < ticks) d.tick([input, ai.input(d, d.rival, d.player)], dt); });
  }
  return d;
}

test('simulação idêntica a 30, 60, 120 e 144 FPS de renderização', () => {
  const base = JSON.stringify(play(60).snapshot());
  for (const fps of [30, 120, 144]) assert.equal(JSON.stringify(play(fps).snapshot()), base, fps + ' FPS');
});

test('pulso curto entre dois ticks não se perde', () => {
  const step = new FixedStep(60), got = [];
  // 144 FPS: um quadro de 6,9 ms com o aperto não executa tick nenhum.
  step.advance(1000 / 144, { attack: true }, i => got.push(i.attack));
  assert.deepEqual(got, []);
  step.advance(1000 / 144, {}, i => got.push(i.attack));
  step.advance(1000 / 144, {}, i => got.push(i.attack));
  assert.deepEqual(got, [true]);
  step.advance(100, {}, i => got.push(i.attack));
  assert.ok(got.slice(1).every(v => v === false), 'o pulso vale uma vez só');
});

test('quadro lento não dispara rajada de ticks e o restante vira interpolação', () => {
  const step = new FixedStep(60, 6);
  let n = 0;
  assert.equal(step.advance(1000, {}, () => n++), 6);
  step.reset();
  step.advance(25, {}, () => n++);
  assert.ok(step.alpha > 0.4 && step.alpha < 0.6);
});

test('buffer guarda só o último comando e expira', () => {
  const b = new CommandBuffer(134);
  b.push({ kind: 'attack' }, 0);
  b.push({ kind: 'kick' }, 20);
  assert.equal(b.peek(100).kind, 'kick');
  assert.equal(b.peek(160), null);
});

test('direções do comando são relativas ao olhar', () => {
  assert.equal(commandFrom({ attack: true, right: true }, 1).forward, true);
  assert.equal(commandFrom({ attack: true, right: true }, -1).back, true);
  assert.equal(commandFrom({ right: true }, 1), null);
});

test('toques simultâneos: direcional e golpe juntos; soltar um mantém o outro', () => {
  const t = new TouchState();
  t.set(1, { right: true });
  t.set(2, { attack: true });
  t.set(3, { run: true });
  let r = t.read();
  assert.equal(r.right && r.attack && r.run, true);
  r = t.read();
  assert.equal(r.attack, false, 'segurar não repete o golpe');
  t.release(2);
  r = t.read();
  assert.equal(r.right && r.run, true);
  t.clear();
  assert.deepEqual(t.read(), { attack: false, kick: false, grab: false });
});

test('corredor antigo: passo fixo dá o mesmo resultado a 30 e 144 FPS', () => {
  const runAt = fps => {
    const m = new Battle(1), step = new FixedStep(60);
    for (let t = 0; t < 2500; t += 1000 / fps) {
      const input = { right: t < 900, attack: t >= 1000 && t < 1000 + 1000 / fps };
      step.advance(1000 / fps, input, (i, dt) => m.step(i, dt));
    }
    return [m.player.x, m.player.state, m.attackId, m.enemies[0].hits];
  };
  assert.deepEqual(runAt(30), runAt(144));
});
