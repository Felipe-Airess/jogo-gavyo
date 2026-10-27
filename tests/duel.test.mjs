import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { Duel, TICK, STAGE } from '../src/duel/duel.mjs';
import { DuelAI } from '../src/duel/ai.mjs';
import { CLINCH } from '../src/duel/clinch.mjs';
import { resolveHit, contactQuality, ROCK } from '../src/duel/damage.mjs';
import { sweep } from '../src/duel/collision.mjs';
import { capabilities, createFighter } from '../src/duel/fighter.mjs';
import { MAX_CHAIN, cancelTarget } from '../src/duel/moves.mjs';
import { worldMarkers, bounds, hurtboxes, limbCenter, LIMB_SIZE } from '../src/duel/markers.mjs';

const atlas = JSON.parse(fs.readFileSync(new URL('../assets/sorriso-v70.json', import.meta.url)));
const clips = Object.fromEntries(atlas.clips.map(c => [c.id, c]));
const markers = JSON.parse(fs.readFileSync(new URL('../assets/sorriso-markers.json', import.meta.url)));
const miguel = Object.fromEntries(JSON.parse(fs.readFileSync(new URL('../assets/miguel.json', import.meta.url))).clips.map(c => [c.id, c]));

const make = (gap = 40, mirror = false) => {
  const d = new Duel({ clips, markers });
  if (mirror) { d.player.x = 280; d.player.facing = -1; d.rival.x = 280 - gap; d.rival.facing = 1; }
  else d.rival.x = d.player.x + gap;
  return d;
};
const run = (d, ms, p = {}, r = {}) => { for (let t = 0; t < ms - 1e-6; t += TICK) d.tick([p, r]); };
const press = (d, p = {}, r = {}) => d.tick([p, r]);
const attacks = (d, id = 1) => d.events.filter(e => e.type === 'attack' && e.fighter === id).length;
const until = (d, fn, max = 3000, p = {}, r = {}) => { for (let t = 0; t < max && !fn(); t += TICK) d.tick([p, r]); assert.ok(fn(), 'estado esperado não ocorreu'); };

test('o jab acerta dos dois lados com o espelhamento dos marcadores', () => {
  for (const mirror of [false, true]) {
    const d = make(40, mirror);
    press(d, { attack: true });
    run(d, 400);
    assert.equal(d.lastHit?.target, 2, 'lado ' + (mirror ? 'esquerdo' : 'direito'));
    assert.equal(d.lastHit.zone, 'head');
    assert.ok(d.rival.condition.head > 0);
  }
});

test('hurtboxes espelham em torno do pivô', () => {
  const d = make(60), f = d.rival, a = d.hurtboxesOf(f);
  f.facing = -f.facing;
  const b = d.hurtboxesOf(f);
  for (const zone of ['head', 'body', 'legs']) {
    const p = bounds(a[zone]), q = bounds(b[zone]);
    assert.ok(Math.abs((p.x + p.w / 2 - f.x) + (q.x + q.w / 2 - f.x)) < 0.01, zone);
  }
});

test('golpe fora do alcance passa no vazio sem dano nem contato', () => {
  for (const gap of [56, 70]) {
    const d = make(gap);
    press(d, { attack: true });
    run(d, 700);
    assert.equal(d.lastHit, null);
    assert.deepEqual(d.rival.condition, { head: 0, body: 0, legs: 0 });
  }
});

test('alcance depende do membro desenhado: o chute circular é mais curto que o pesado', () => {
  const d = make();
  assert.ok(d.reach.overhand > d.reach.jab);
  assert.ok(d.reach.roundBody < d.reach.overhand);
  assert.equal(d.markers.limits.size, 0);
});

test('varredura detecta um punho rápido que atravessaria a caixa entre dois ticks', () => {
  const box = { x: 10, y: 0, w: 2, h: 10 };
  assert.equal(sweep({ x: 0, y: 5 }, { x: 20, y: 5 }, 1, 1, box) !== null, true);
  assert.equal(sweep({ x: 0, y: 30 }, { x: 20, y: 30 }, 1, 1, box), null);
});

test('um contato por golpe, mesmo com dois quadros ativos', () => {
  const d = make(40);
  press(d, { attack: true });
  run(d, 600);
  assert.equal(d.events.filter(e => e.type === 'hit').length, 1);
});

test('três apertos antes do contato não formam uma fila de golpes', () => {
  const d = make(70);
  press(d, { attack: true }); run(d, 40); press(d, { attack: true }); run(d, 40); press(d, { attack: true });
  run(d, 1200);
  assert.equal(attacks(d), 1);
});

test('aperto pouco antes do fim da recuperação sai no primeiro tick livre', () => {
  const d = make(70);
  press(d, { attack: true });
  const m = d.moves.jab;
  run(d, m.duration - 100);
  press(d, { attack: true });
  run(d, 120);
  assert.equal(attacks(d), 2);
  const [first, second] = d.events.filter(e => e.type === 'attack').map(e => e.at);
  assert.ok(second - first <= m.duration + TICK + 1e-6, 'o segundo jab começou no primeiro tick livre');
});

test('aperto cedo demais na recuperação expira e não vira golpe atrasado', () => {
  const d = make(70);
  press(d, { attack: true });
  run(d, 150);
  press(d, { attack: true });
  run(d, 900);
  assert.equal(attacks(d), 1);
});

test('cancelamento só com contato e dentro da janela: jab acertado emenda direto', () => {
  const d = make(40);
  press(d, { attack: true });
  until(d, () => d.player.connected);
  press(d, { attack: true, right: true });
  run(d, 50);
  assert.equal(d.player.move, 'jab', 'pausa de impacto segura a troca');
  run(d, 100);
  assert.equal(d.player.move, 'cross');
  assert.equal(d.player.moveFrom, 'jab');
  assert.equal(d.player.chain, 2);
});

test('jab no vazio não cancela: o direto espera a recuperação inteira', () => {
  const d = make(70);
  press(d, { attack: true });
  run(d, d.moves.jab.activeEnd + 20);
  press(d, { attack: true, right: true });
  run(d, 60);
  assert.equal(d.player.move, 'jab');
});

// Aperta um comando a cada `every` ms, como quem martela a sequência.
const mash = (seq, gap = 40, every = 180) => {
  const d = make(gap);
  Object.assign(d.rival.condition, { head: -500, body: -500, legs: -500 });
  d.rival.balance = 1e6;
  const hits = [];
  const ev = d.event.bind(d);
  d.event = (type, x) => { if (type === 'hit' && x.attacker === 1) hits.push(x.move); return ev(type, x); };
  let i = 0;
  for (let t = 0; t < 3000; t += TICK) d.tick([i < seq.length && t >= i * every ? seq[i++] : {}, {}]);
  return { d, hits };
};

test('sequência: chute emenda em chute e soco em chute, sem acertar o tempo exato', () => {
  const K = { kick: true }, J = { attack: true }, D = { attack: true, down: true }, F = { attack: true, right: true };
  const kk = mash([K, K]);
  assert.deepEqual(kk.hits, ['roundBody', 'roundBody'], 'chute → chute');
  assert.equal(kk.d.events.filter(e => e.type === 'attack' && e.chained).length, 1);
  const jdf = mash([J, D, F]);
  assert.deepEqual(jdf.hits, ['jab', 'jabBody', 'cross'], 'jab → corpo → direto');
});

test('sequência: mesmo golpe no máximo duas vezes seguidas e no máximo quatro ações', () => {
  const J = { attack: true };
  const d = make(40);
  d.player.combo = ['jab', 'jab'];
  assert.equal(cancelTarget(d.moves.jab, { kind: 'attack' }, d.player, ['jab', 'jab']), null);
  assert.equal(cancelTarget(d.moves.jab, { kind: 'attack' }, d.player, ['cross', 'jab']), 'jab');
  const long = mash([J, { attack: true, down: true }, { attack: true, right: true }, { kick: true, down: true }, { kick: true }, J]);
  assert.ok(Math.max(...long.d.events.filter(e => e.type === 'attack').map(() => long.d.player.chain)) <= MAX_CHAIN);
});

test('pesado fecha a sequência', () => {
  const d = make(40);
  d.rival.condition.head = -500; d.rival.balance = 1e6;
  press(d, { attack: true });
  until(d, () => d.player.connected);
  press(d, { attack: true, run: true });
  until(d, () => d.player.move === 'overhand', 600);
  assert.deepEqual(d.moves.overhand.cancels, []);
  until(d, () => d.player.connected, 1200);
  press(d, { attack: true });
  run(d, 200);
  assert.equal(d.player.move, 'overhand');
});

test('soco e chute misturados usam a continuação desenhada', () => {
  const d = make(40);
  d.rival.balance = 1e6;
  press(d, { attack: true });
  until(d, () => d.player.connected);
  press(d, { kick: true });
  run(d, 150);
  assert.equal(d.player.move, 'punchKick');
  assert.equal(d.moves.punchKick.frames[0], 5);
});

test('golpe pesado no vazio cobra a recuperação de erro', () => {
  const d = make(90);
  press(d, { attack: true, run: true });
  assert.equal(d.player.move, 'overhand');
  run(d, d.moves.overhand.duration + 20);
  assert.equal(d.player.state, 'whiff');
  until(d, () => d.player.state === 'idle', 1000);
});

test('defesa segura cabeça e tronco, gasta fôlego e o pesado bloqueado é punível', () => {
  const d = make(44);
  run(d, 50, {}, { guard: true });
  press(d, { attack: true, run: true }, { guard: true });
  until(d, () => !!d.lastHit, 1200, {}, { guard: true });
  assert.equal(d.lastHit.blocked, true);
  assert.deepEqual(d.rival.condition, { head: 0, body: 0, legs: 0 });
  assert.ok(d.rival.stamina < 100);
  until(d, () => d.rival.state !== 'blockstun', 1000);
  assert.equal(d.player.state, 'attack', 'defensor livre antes do atacante: pode contra-atacar');
});

test('chute na perna passa pela guarda alta e só castiga pernas', () => {
  const d = make(42);
  run(d, 50, {}, { guard: true });
  press(d, { kick: true, down: true }, { guard: true });
  run(d, 700, {}, { guard: true });
  assert.equal(d.lastHit?.zone, 'legs');
  assert.equal(d.lastHit.blocked, false);
  assert.equal(d.rival.condition.head, 0);
  assert.equal(d.rival.condition.body, 0);
  assert.ok(d.rival.condition.legs > 0);
});

test('agachar tira a cabeça da linha do jab', () => {
  const d = make(40);
  run(d, 500, {}, { down: true });
  press(d, { attack: true }, { down: true });
  run(d, 600, {}, { down: true });
  assert.equal(d.lastHit, null);
});

test('dano localizado: corpo drena fôlego, cabeça não toca o tronco', () => {
  const a = make(40), b = make(40);
  press(a, { attack: true }); run(a, 500);
  press(b, { attack: true, down: true }); run(b, 500);
  assert.equal(a.lastHit.zone, 'head');
  assert.equal(b.lastHit.zone, 'body');
  assert.equal(a.rival.condition.body, 0);
  assert.equal(b.rival.condition.head, 0);
  assert.ok(100 - b.rival.stamina > 100 - a.rival.stamina);
});

test('desequilíbrio derruba; caído não recebe golpes e levanta com base mínima', () => {
  const d = make(40);
  d.rival.balance = 4;
  press(d, { attack: true, right: true });
  until(d, () => d.rival.state === 'knockdown', 800);
  const head = d.rival.condition.head;
  run(d, 200);
  press(d, { attack: true });
  run(d, 300);
  assert.equal(d.rival.condition.head, head, 'sem dano no chão');
  until(d, () => d.rival.state === 'idle', 3000);
  assert.ok(d.rival.balance >= 60);
});

test('nocaute situacional é determinístico e explicado', () => {
  const setup = counter => {
    const d = make(40);
    d.rival.condition.head = 60;
    press(d, { attack: true, right: true });
    // O jab dele começa depois: o direto chega durante a preparação dele.
    run(d, 80);
    if (counter) press(d, {}, { attack: true });
    run(d, 700);
    return d;
  };
  const ko1 = setup(true), ko2 = setup(true), clean = setup(false);
  assert.equal(ko1.result?.winner, 1);
  assert.match(ko1.result.reason, /contra-ataque/);
  assert.deepEqual(ko1.result, ko2.result);
  assert.equal(clean.result, null, 'mesmo golpe sem contra-ataque nem base perdida não nocauteia');
});

test('cabeça esgotada nocauteia e o lutador não levanta', () => {
  const d = make(40);
  d.rival.condition.head = 95;
  press(d, { attack: true });
  run(d, 4000);
  assert.equal(d.rival.state, 'ko');
  assert.equal(d.result.winner, 1);
});

test('clinch exige distância de agarrão e não pega quem está atacando', () => {
  const far = make(70);
  press(far, { grab: true });
  assert.equal(far.player.state, 'grabMiss');
  const busy = make(26);
  press(busy, {}, { attack: true });
  press(busy, { grab: true });
  assert.equal(busy.player.state, 'grabMiss');
  const ok = make(26);
  press(ok, { grab: true });
  assert.equal(ok.player.state, 'clinchEntry');
  assert.equal(ok.rival.state, 'held');
});

test('entrada no clinch aproxima os corpos sem teleporte', () => {
  const d = make(30);
  press(d, { grab: true });
  let last = [d.player.x, d.rival.x];
  for (let i = 0; i < 20; i++) {
    press(d);
    const now = [d.player.x, d.rival.x];
    for (let k = 0; k < 2; k++) assert.ok(Math.abs(now[k] - last[k]) <= CLINCH.approach * TICK / 1000 + 1e-6);
    last = now;
  }
  assert.ok(Math.abs(Math.abs(d.rival.x - d.player.x) - CLINCH.gap) < 1);
});

test('joelhada no clinch castiga o tronco, renova a pega e mantém o alvo preso', () => {
  const d = make(26);
  press(d, { grab: true });
  run(d, 260);
  const grip = d.player.clinch.grip;
  press(d, { kick: true });
  run(d, 400);
  assert.equal(d.lastHit?.zone, 'body');
  assert.equal(d.rival.state, 'held');
  assert.ok(d.player.clinch.grip > grip - 400);
  assert.ok(d.player.stamina < 100);
});

test('clinch solta por tempo, por escape, por G e derruba quando o corpo cede', () => {
  const t = make(26); press(t, { grab: true }); run(t, CLINCH.grip + 300);
  assert.equal(t.player.clinch, null);
  const e = make(26); press(e, { grab: true }); run(e, 250);
  for (let i = 0; i < 12 && e.rival.clinch; i++) { press(e, {}, { attack: true }); run(e, 100, {}, { right: true }); }
  assert.equal(e.rival.clinch, null);
  assert.equal(e.events.at(-1).type === 'escape' || e.events.some(x => x.type === 'escape'), true);
  const g = make(26); press(g, { grab: true }); run(g, 250); press(g, { grab: true });
  assert.equal(g.player.clinch, null);
  const k = make(26); k.rival.condition.body = 95; press(k, { grab: true }); run(k, 250); press(k, { kick: true }); run(k, 500);
  assert.equal(k.rival.state, 'collapse');
  assert.equal(k.player.clinch, null);
});

test('corpos de pé não se atravessam e a parede empurra só o outro', () => {
  const d = make(30);
  run(d, 1500, { right: true });
  assert.ok(d.rival.x - d.player.x >= STAGE.half * 2 - 1e-6);
  const w = make(20);
  w.rival.x = STAGE.maxX; w.player.x = STAGE.maxX - 10;
  run(w, 100, { right: true });
  assert.equal(w.rival.x, STAGE.maxX);
  assert.ok(w.rival.x - w.player.x >= STAGE.half * 2 - 1e-6);
});

test('caminhada sincroniza a fase dos pés com a distância, nos dois sentidos', () => {
  const d = make(200);
  run(d, 1000, { right: true });
  const moved = d.player.x - 200;
  assert.ok(Math.abs(d.player.gait - moved) < 1e-6);
  const back = make(200);
  run(back, 1000, { left: true });
  assert.ok(back.player.gait < 0);
  assert.ok(Math.abs(back.player.x - 200) < Math.abs(moved), 'para trás é mais lento');
});

test('pernas castigadas reduzem a velocidade', () => {
  const a = make(300), b = make(300);
  b.player.condition.legs = 80;
  run(a, 800, { right: true }); run(b, 800, { right: true });
  assert.ok(b.player.x - 200 < (a.player.x - 200) * 0.8);
});

test('pausa de impacto congela o relógio e não deixa o comando expirar', () => {
  const d = make(40);
  press(d, { attack: true });
  until(d, () => d.hitstop > 0);
  const clock = d.clock;
  press(d, { attack: true, right: true });
  run(d, d.hitstop - 1);
  assert.equal(d.clock, clock);
  run(d, 80);
  assert.equal(d.player.move, 'cross');
});

test('limpar entradas (pausa/perda de foco) descarta o comando guardado', () => {
  const d = make(70);
  press(d, { attack: true });
  run(d, d.moves.jab.duration - 60);
  press(d, { attack: true });
  d.clearInputs();
  run(d, 200);
  assert.equal(attacks(d), 1);
});

test('reiniciar devolve condição, fôlego e posições', () => {
  const d = make(40);
  press(d, { attack: true }); run(d, 600);
  d.reset();
  assert.deepEqual(d.rival.condition, { head: 0, body: 0, legs: 0 });
  assert.equal(d.rival.stamina, 100);
  assert.equal(d.result, null);
  assert.equal(d.lastHit, null);
});

test('IA: espaça ataques, defende golpes lentos e nunca age presa na recuperação', () => {
  const d = make(60), ai = new DuelAI(5);
  let busyPulses = 0;
  for (let t = 0; t < 20000; t += TICK) {
    const r = ai.input(d, d.rival, d.player);
    if ((r.attack || r.kick) && !['idle', 'walk', 'guard', 'crouch', 'rise', 'run', 'attack', 'clinch', 'held'].includes(d.rival.state)) busyPulses++;
    d.tick([{}, r]);
    if (d.result) break;
  }
  const n = attacks(d, 2);
  assert.ok(n >= 4, 'ataca: ' + n);
  assert.ok(n <= 26, 'não ataca sem parar: ' + n);
  assert.equal(busyPulses, 0);
});

test('IA reage ao golpe pesado visível, mas não adivinha o jab', () => {
  let guardedHeavy = 0, guardedJab = 0;
  for (let seed = 1; seed <= 12; seed++) {
    for (const heavy of [true, false]) {
      const d = make(44), ai = new DuelAI(seed);
      ai.attackAt = 1e9;
      ai.thinkAt = 1e9; // só reação: sem recuar para a distância preferida
      d.tick([heavy ? { attack: true, run: true } : { attack: true }, ai.input(d, d.rival, d.player)]);
      for (let t = 0; t < 900 && !d.lastHit; t += TICK) d.tick([{}, ai.input(d, d.rival, d.player)]);
      if (d.lastHit?.blocked) heavy ? guardedHeavy++ : guardedJab++;
    }
  }
  assert.ok(guardedHeavy >= 6, 'defende o pesado: ' + guardedHeavy);
  assert.equal(guardedJab, 0, 'jab sai antes do tempo de reação');
});

test('IA é reproduzível pela semente', () => {
  const play = () => { const d = make(60), ai = new DuelAI(9); for (let t = 0; t < 8000; t += TICK) d.tick([{}, ai.input(d, d.rival, d.player)]); return JSON.stringify(d.snapshot()); };
  assert.equal(play(), play());
});

test('IA pune golpe pesado errado ou bloqueado', () => {
  let punished = 0;
  for (let seed = 1; seed <= 8; seed++) {
    const d = make(50), ai = new DuelAI(seed);
    ai.attackAt = 1e9;
    d.tick([{ attack: true, run: true }, ai.input(d, d.rival, d.player)]);
    for (let t = 0; t < 1600; t += TICK) d.tick([{}, ai.input(d, d.rival, d.player)]);
    if (d.events.some(e => e.type === 'hit' && e.attacker === 2)) punished++;
  }
  assert.ok(punished >= 3, 'puniu ' + punished);
});

test('Miguel compartilha as regras, mas só faz o que tem desenho', () => {
  const can = capabilities('miguel', miguel);
  assert.equal(can.guard, true);
  assert.equal(can.walk, true);
  assert.equal(can.attack, true);
  for (const action of ['run', 'fall', 'rise']) assert.equal(can[action], true, action);
  for (const action of ['crouch', 'clinch']) assert.equal(can[action], false, action);
  const d = withMiguel();
  const x = d.player.x;
  run(d, 300, { left: true });
  assert.ok(d.player.x < x, 'anda');
  const seen = new Set();
  for (let t = 0; t < 700; t += TICK) { d.tick([{ right: true, run: true }, {}]); seen.add(d.animation(d.player).clip); }
  assert.equal(d.player.state, 'run', 'corre');
  assert.ok(seen.has('m4_runStart') && seen.has('m4_run'), [...seen].join());
  run(d, 300);
  run(d, 50, { guard: true });
  assert.equal(d.player.state, 'guard');
});

const miguelMarkers = JSON.parse(fs.readFileSync(new URL('../assets/miguel-markers.json', import.meta.url)));
const withMiguel = () => {
  const d = new Duel({ clips, markers, roster: { miguel: { clips: miguel, markers: miguelMarkers } } });
  d.setCharacters(['miguel', 'sorriso']);
  return d;
};

test('Miguel jogável: só quadros dele e caixas dele', () => {
  const d = withMiguel(), p = d.player;
  assert.equal(p.character, 'miguel');
  const seen = new Set();
  const look = () => { const ref = d.animation(p); assert.ok(miguel[ref.clip]?.frames[ref.frame], ref.clip + ' ' + ref.frame); seen.add(ref.clip); };
  for (let t = 0; t < 600; t += TICK) { d.tick([{}, {}]); look(); }
  for (let t = 0; t < 500; t += TICK) { d.tick([{ right: true }, {}]); look(); }
  for (let t = 0; t < 500; t += TICK) { d.tick([{ left: true }, {}]); look(); }
  for (let t = 0; t < 400; t += TICK) { d.tick([{ guard: true }, {}]); look(); }
  d.tick([{ attack: true }, {}]);
  for (let t = 0; t < 700; t += TICK) { d.tick([{}, {}]); look(); }
  d.tick([{ kick: true }, {}]);
  for (let t = 0; t < 1200; t += TICK) { d.tick([{}, {}]); look(); }
  for (const clip of ['m3_idle', 'm4_walkFwd', 'm4_walkBack', 'm4_block', 'm3_jab', 'm3_roundKick']) assert.ok(seen.has(clip), clip);
  assert.equal(attacks(d, 1), 2);
  assert.ok(Object.keys(d.hurtboxesOf(p)).length === 3, 'cabeça, tronco e pernas');
});

test('Sorriso acerta e é bloqueado pelo Miguel com as caixas do Miguel', () => {
  const d = withMiguel();
  d.rival.x = d.player.x + 40;
  d.tick([{}, { attack: true }]);
  run(d, 500);
  assert.equal(d.lastHit?.target, 1, 'acertou o Miguel');
  const b = withMiguel();
  b.rival.x = b.player.x + 40;
  run(b, 200, { guard: true });
  b.tick([{ guard: true }, { attack: true }]);
  run(b, 500, { guard: true });
  assert.equal(b.lastHit?.blocked, true, 'guarda do Miguel segura');
});

test('marcadores ausentes não viram coordenadas: o golpe só procura o membro existente', () => {
  const f = createFighter(1, 'sorriso', 100, 1, clips);
  const w = worldMarkers({ head: null, torso: null, hip: null, fists: [], feet: [], frontFist: null, frontFoot: null, frontKnee: null }, f);
  assert.equal(w.fist, null);
  assert.equal(w.foot, null);
});

// Deslizamento: entre dois quadros de apoio seguidos, o pé no chão deve ficar
// quase parado no mundo. Mede-se o pé apoiado mais próximo do anterior.
function footSlide(d, input, clip) {
  const slides = [];
  let last = null;
  for (let t = 0; t < 2500; t += TICK) {
    d.tick([input, {}]);
    const ref = d.animation(d.player);
    if (ref.clip !== clip) { last = null; continue; }
    const mk = d.markers.frame(ref.clip, ref.frame);
    const planted = mk.feet.filter(p => p.tipY >= -5).map(p => d.drawX(d.player) + p.tipX * d.player.facing);
    // Compara também dentro do mesmo quadro: a pose parada não pode deslizar.
    if (last && planted.length && last.planted.length) {
      const prev = last.planted, now = planted;
      const best = Math.min(...prev.flatMap(a => now.map(b => Math.abs(b - a))));
      if (best < 15) slides.push(best);
    }
    last = { frame: ref.frame, planted };
    if (d.player.x > 420) break;
  }
  slides.sort((a, b) => a - b);
  return { median: slides[Math.floor(slides.length / 2)], n: slides.length };
}

test('corrida e caminhada: o pé apoiado não escorrega', () => {
  const run = footSlide(make(400), { right: true, run: true }, 'r2_run');
  const walk = footSlide(make(400), { right: true }, 'r2_walk');
  assert.ok(run.n >= 4 && run.median < 3.5, 'corrida ' + JSON.stringify(run));
  assert.ok(walk.n >= 4 && walk.median < 3.5, 'caminhada ' + JSON.stringify(walk));
});

test('arrancada completa e freada desenhada ao soltar a corrida', () => {
  const d = make(400);
  const seen = new Set();
  for (let t = 0; t < 700; t += TICK) { d.tick([{ right: true, run: true }, {}]); const a = d.animation(d.player); if (a.clip === 'r2_runStart') seen.add(a.frame); }
  assert.equal(seen.size, 8, 'os 8 quadros de saída aparecem');
  d.tick([{}, {}]);
  assert.equal(d.player.state, 'brake');
  assert.equal(d.animation(d.player).clip, 'r2_runStop');
  run(d, 700);
  assert.equal(d.player.state, 'idle');
});

// Hurtboxes justas aos pixels (extract-markers.py → `hurt`).
const frameBoxes = (clip, frame, opts) => {
  const f = { x: 0, y: 0, facing: 1 };
  return hurtboxes(worldMarkers(markers.clips[clip][frame], f), opts);
};
const hits = (list, x, y) => (list || []).some(b => x >= b.x && x < b.x + b.w && y >= b.y && y < b.y + b.h);

test('todo quadro de combate tem cabeça, tronco e pernas em caixas justas', () => {
  for (const clip of ['r1_idle', 'r2_walk', 'r3_jab_head', 'r3_cross_head', 'r3_low_kick', 'r3_round_kick_body', 'block', 'hurt']) {
    markers.clips[clip].forEach((_, i) => {
      const b = frameBoxes(clip, i);
      for (const zone of ['head', 'body', 'legs']) assert.ok(b[zone]?.length, clip + ' ' + i + ' ' + zone);
    });
  }
});

test('o vão sob a perna do chute baixo não é atingível', () => {
  // Quadro de contato: a perna estendida passa por cima de um vazio até o chão.
  const b = frameBoxes('r3_low_kick', 5), all = [...b.head, ...b.body, ...b.legs];
  const foot = markers.clips.r3_low_kick[5].frontFoot;
  assert.ok(hits(b.legs, foot.tipX - 4, foot.tipY), 'o tênis estendido é perna');
  assert.equal(hits(all, foot.tipX - 4, -6), false, 'o chão abaixo do tênis é vazio');
});

test('mão parada não aumenta o alcance; braço do golpe pode ser atingido', () => {
  const tip = markers.clips.r3_jab_head[4].frontFist;
  const x = tip.tipX - 2, y = tip.tipY;
  assert.equal(hits(frameBoxes('r3_jab_head', 4).body, x, y), false);
  assert.ok(hits(frameBoxes('r3_jab_head', 4, { arms: true }).body, x, y));
});

test('a hitbox do membro termina no pixel mais à frente do desenho', () => {
  for (const facing of [1, -1]) {
    const tip = { x: 100, y: 50 }, c = limbCenter(tip, 'fist', facing), [w] = LIMB_SIZE.fist;
    assert.equal(facing > 0 ? c.x + w / 2 : c.x - w / 2, tip.x);
  }
});

// Golpe limpo x raspão e grogue.
test('qualidade do contato muda dano, equilíbrio e atordoamento', () => {
  const d = make(40), m = d.moves.cross, f = d.rival;
  const clean = resolveHit(m, f, 'body', { quality: 'clean' }), normal = resolveHit(m, f, 'body', {}), graze = resolveHit(m, f, 'body', { quality: 'graze' });
  assert.ok(clean.damage > normal.damage && normal.damage > graze.damage);
  assert.ok(clean.balance > normal.balance && normal.balance > graze.balance);
  assert.ok(clean.stun > normal.stun && normal.stun > graze.stun);
  assert.equal(contactQuality(0.9), 'clean');
  assert.equal(contactQuality(0.4), 'normal');
  assert.equal(contactQuality(0.1), 'graze');
  assert.equal(contactQuality(null), 'normal');
});

test('raspão na cabeça castigada não nocauteia; limpo em quem está grogue nocauteia', () => {
  const d = make(40), m = d.moves.cross, f = d.rival;
  f.condition.head = 60; f.balance = 10;
  assert.notEqual(resolveHit(m, f, 'head', { quality: 'graze', counter: true }).kind, 'ko');
  f.condition.head = 40; f.balance = 100;
  assert.equal(resolveHit(m, f, 'head', { quality: 'clean', rocked: true }).kind, 'ko');
  f.condition.head = 5;
  assert.notEqual(resolveHit(m, f, 'head', { quality: 'clean', rocked: true }).kind, 'ko', 'cabeça ainda inteira');
  assert.notEqual(resolveHit(d.moves.jab, f, 'head', { quality: 'clean', rocked: true }).kind, 'ko', 'jab não derruba sozinho');
});

test('no ponto certo o jab sai limpo; na ponta do alcance sai mais fraco', () => {
  const hit = gap => { const d = make(gap); d.rival.condition.head = -500; press(d, { attack: true }); run(d, 500); return d.lastHit; };
  const sweet = hit(32), edge = hit(48);
  assert.equal(sweet?.quality, 'clean');
  assert.ok(edge && edge.quality !== 'clean', 'na ponta: ' + edge?.quality);
  assert.ok(sweet.damage > edge.damage);
});

test('dano seguido na cabeça deixa grogue: anda devagar, não recupera base, passa com o tempo', () => {
  const d = make(36), f = d.rival;
  f.headRecent = ROCK.threshold - 1;
  press(d, { attack: true });
  run(d, 450);
  assert.equal(d.lastHit?.zone, 'head');
  assert.ok(d.isRocked(f), 'grogue');
  assert.ok(d.events.some(e => e.type === 'rocked' && e.fighter === 2));
  // anda mais devagar que o normal
  const g = make(120); g.player.rockedUntil = 1e9;
  const n = make(120);
  for (const x of [g, n]) run(x, 500, { right: true });
  assert.ok(g.player.x - 200 < (n.player.x - 200) * 0.75, 'mais lento');
  // equilíbrio não volta enquanto grogue
  g.player.balance = 40; run(g, 300);
  assert.equal(g.player.balance, 40);
  // passa
  run(d, ROCK.ms + 100, {}, {});
  assert.equal(d.isRocked(f), false);
});

// Arremesso, chão e aparo.
test('sequência + G arremessa: o alvo vai ao chão e J/K batem nele lá', () => {
  const { d } = mash([{ attack: true }, { attack: true, down: true }, { grab: true }], 40, 180);
  const kinds = [];
  // refaz registrando os eventos desde o começo
  const e = make(40);
  Object.assign(e.rival.condition, { head: -500, body: -500 }); e.rival.balance = 1e6;
  const ev = e.event.bind(e);
  e.event = (type, x) => { kinds.push(type + ':' + (x.kind || x.move || '')); return ev(type, x); };
  const seq = [{ attack: true }, { attack: true, down: true }, { grab: true }];
  let i = 0, downAt = null;
  for (let t = 0; t < 2600; t += TICK) {
    let input = i < seq.length && t >= i * 180 ? seq[i++] : {};
    if (e.rival.state === 'down' && downAt === null) downAt = t;
    if (downAt !== null && t - downAt > 120 && t - downAt < 140) input = { attack: true };
    e.tick([input, {}]);
  }
  assert.ok(kinds.includes('hit:throw'), 'arremessou: ' + kinds.join(' '));
  assert.ok(kinds.some(k => k === 'hit:hit') && kinds.filter(k => k.startsWith('attack:ground')).length >= 1, 'bateu no chão: ' + kinds.join(' '));
  assert.ok(d, 'mash roda');
});

test('golpe no chão segura o caído e finaliza a cabeça castigada', () => {
  // Caiu de costas: a cabeça fica do lado de lá. Quem bate passa por cima das
  // pernas (sem empurrão com alguém no chão) e bate do lado da cabeça.
  const d = make(30);
  d.rival.state = 'down'; d.rival.t = 0; d.rival.condition.head = 50;
  d.player.x = d.rival.x + 40; d.player.facing = -1;
  press(d, { attack: true });
  assert.equal(d.player.move, 'groundPunch');
  run(d, 600);
  assert.equal(d.lastHit?.move, 'groundPunch', 'acertou no chão');
  assert.equal(d.rival.state, 'ko', d.message);
  assert.match(d.result.reason, /chão/);
  const e = make(30);
  e.rival.state = 'down'; e.rival.t = 0;
  press(e, { kick: true });
  run(e, 600);
  assert.equal(e.lastHit?.move, 'groundKick');
  assert.ok(e.rival.downMs > 700, 'ficou mais tempo no chão');
});

test('aparo: L no último instante desvia, abre quem bateu e J contra-ataca', () => {
  const d = make(40);
  press(d, { attack: true, right: true }, {});
  const m = d.moves.cross;
  run(d, m.activeStart - 80);
  d.tick([{}, { guard: true }]);
  until(d, () => d.lastHit, 400, {}, { guard: true });
  assert.equal(d.lastHit.kind, 'parry');
  assert.equal(d.player.state, 'parried');
  d.tick([{}, { attack: true, guard: true }]);
  until(d, () => d.rival.move === 'parryCounter', 300, {}, { guard: true });
  until(d, () => d.lastHit?.move === 'parryCounter', 600);
  assert.equal(d.lastHit.counter, true);
  assert.equal(d.lastHit.blocked, false);
  // Guarda levantada cedo: bloqueio comum.
  const b = make(40);
  run(b, 300, {}, { guard: true });
  b.tick([{ attack: true, right: true }, { guard: true }]);
  until(b, () => b.lastHit, 600, {}, { guard: true });
  assert.equal(b.lastHit.kind, 'block');
});

test('golpes do Miguel acertam com o desenho e as caixas dele; sem desenho, substituto', () => {
  const d = withMiguel();
  d.rival.x = d.player.x + 36;
  press(d, { attack: true });
  run(d, 400);
  assert.equal(d.lastHit?.attacker, 1, 'jab do Miguel acertou');
  assert.equal(d.moveOf(d.player, 'jab').clip, 'm3_jab');
  const h = withMiguel();
  h.rival.x = h.player.x + 36;
  press(h, { attack: true, left: true });          // trás + J: gancho (lote 4)
  assert.equal(h.player.move, 'hook');
  assert.equal(h.moveOf(h.player).clip, 'm4_hook');
  const k = withMiguel();
  k.rival.x = k.player.x + 30;
  press(k, { kick: true, right: true });          // frente + K: joelhada (só o Miguel tem)
  assert.equal(k.player.move, 'kneeStrike');
  const g = withMiguel();
  g.rival.state = 'down'; g.rival.x = g.player.x + 30;
  press(g, { attack: true });
  assert.notEqual(g.player.move, 'groundPunch', 'sem arte de chão');
});

test('Miguel: andar em guarda troca de quadro pela distância andada, não pelo relógio', () => {
  const d = withMiguel();
  const p = d.player, frames = [];
  for (let t = 0; t < 1500; t += TICK) { d.tick([{ right: true }, {}]); const ref = d.animation(p); if (ref.clip === 'm4_walkFwd') frames.push([ref.frame, p.gait]); }
  assert.ok(frames.length > 60, 'andou em guarda');
  const step = 36 / miguel.m4_walkFwd.frames.length;
  const changes = frames.filter((f, i) => i && f[0] !== frames[i - 1][0]).map(f => f[1]);
  for (let i = 1; i < changes.length; i++) assert.ok(Math.abs(changes[i] - changes[i - 1] - step) < 1.5, `troca a cada ${(changes[i] - changes[i - 1]).toFixed(1)} px, esperado ${step}`);
  run(d, 200);
  for (let t = 0; t < 600; t += TICK) { d.tick([{ left: true }, {}]); }
  assert.equal(d.animation(p).clip, 'm4_walkBack');
});

test('Miguel: reação desenhada por região, grogue cambaleando e deitado no chão', () => {
  for (const [zone, clip] of [['head', 'm4_hitHead'], ['body', 'm4_hitBody'], ['legs', 'm4_hitLeg']]) {
    const d = withMiguel(), p = d.player;
    p.state = 'hitstun'; p.t = 0; p.stun = 400; p.reaction = zone;
    const seen = new Set();
    for (let t = 0; t < 400; t += 20) { p.t = t; const r = d.animation(p); assert.equal(r.clip, clip); seen.add(r.frame); }
    assert.equal(seen.size, miguel[clip].frames.length - 1, 'percorre a reação inteira, começando no impacto');
    assert.ok(!seen.has(0), 'não mostra a guarda no tick do contato');
  }
  const d = withMiguel(), p = d.player;
  p.rockedUntil = 1e9; p.state = 'idle';
  assert.equal(d.animation(p).clip, 'm4_dazed');
  p.state = 'down';
  assert.equal(d.animation(p).clip, 'm4_lying');
  p.state = 'knockdown'; p.t = 0;
  assert.equal(d.animation(p).clip, 'm4_fall');
  p.state = 'getup';
  assert.equal(d.animation(p).clip, 'm4_rise');
  p.state = 'hitstun'; p.reaction = 'head'; p.stun = 520;
  assert.equal(d.animation(p).clip, 'm4_hitHeadHeavy');
  p.reactKind = 'hook'; p.reactHeavy = false;
  assert.equal(d.animation(p).clip, 'm4_hitHead', 'gancho sem desenho próprio: reação leve na cabeça');
  p.reactKind = 'liver';
  assert.equal(d.animation(p).clip, 'm4_hitBody');
});

test('Miguel: carga dos golpes perto da do Sorriso (o mais lento até o contato em ≤ 400 ms)', () => {
  const d = new Duel({ clips, markers, roster: { miguel: { clips: miguel, markers: miguelMarkers } } });
  for (const [id, m] of Object.entries(d.movesBy.miguel)) {
    if (m.ground || m.throw || m.clinch || m.special) continue;
    assert.ok(m.activeStart <= 400, `${id}: ${Math.round(m.activeStart)} ms até o contato`);
  }
  assert.ok(d.movesBy.miguel.jab.activeStart <= 160);
});

test('andar até o adversário não enfia um tronco no outro (quadris a ≥ 20 px)', () => {
  for (const ch of ['sorriso', 'miguel']) {
    const d = withMiguel(); d.setCharacters([ch, 'sorriso']);
    run(d, 2500, { right: true });
    const hip = f => d.markersOf(f)?.hip?.x ?? f.x;
    assert.ok(hip(d.rival) - hip(d.player) >= 19.5, `${ch}: ${(hip(d.rival) - hip(d.player)).toFixed(1)} px`);
  }
});

test('Miguel: cima+K é o chute com passo na cintura; lote 4 dá jab no corpo e aparo', () => {
  const d = withMiguel(), m = d.movesBy.miguel.roundHead;
  assert.equal(m.clip, 'm3_stepKick');
  assert.deepEqual(m.targets, ['body', 'legs']);
  assert.equal(d.movesBy.miguel.jabBody.clip, 'm4_jabBody');
  assert.equal(d.movesBy.miguel.parryCounter.clip, 'm4_parryCounter');
});

test('reação acompanha o golpe: tipo pela direção, força pela qualidade, recuo no sentido do golpe', async () => {
  const { reactKind, RECOIL } = await import('../src/duel/duel.mjs');
  assert.equal(reactKind({ id: 'hook' }, 'head'), 'hook');
  assert.equal(reactKind({ id: 'roundBody' }, 'body'), 'liver');
  assert.equal(reactKind({ id: 'cross' }, 'head'), 'straight');
  assert.equal(reactKind({ id: 'lowKick' }, 'legs'), 'legs');
  const d = make(36);
  press(d, { attack: true });
  until(d, () => d.rival.state === 'hitstun', 600);
  const r = d.rival, off = () => d.drawX(r) - d.drawX({ ...r, recoil: 0 });
  assert.ok(r.recoil >= RECOIL.graze);
  assert.ok(off() * r.facing < 0, 'recua para longe de quem bateu');
  until(d, () => r.t >= RECOIL.ms, 600);           // a pausa de impacto congela o relógio
  assert.equal(off(), 0, 'recuo só no começo');
});

test('Miguel: cima+J uppercut, J colado cotovelada; Sorriso mantém o jab', () => {
  const d = withMiguel(); d.rival.x = d.player.x + 22;
  press(d, { attack: true, up: true });
  assert.equal(d.player.move, 'uppercut');
  const e = withMiguel(); e.rival.x = e.player.x + 20;
  press(e, { attack: true });
  assert.equal(e.player.move, 'elbow');
  const f = withMiguel(); f.rival.x = f.player.x + 40;
  press(f, { attack: true });
  assert.equal(f.player.move, 'jab', 'de longe é jab');
  const s = make(22);
  press(s, { attack: true, up: true });
  assert.equal(s.player.move, 'jab', 'Sorriso sem uppercut desenhado: o que já fazia');
});

test('combo desenhado acerta em cada janela de contato (não só uma vez)', () => {
  const d = withMiguel(); d.rival.x = d.player.x + 20;
  Object.assign(d.rival.condition, { head: -500, body: -500, legs: -500 }); d.rival.balance = 1e6;
  press(d, { attack: true, run: true, down: true });
  assert.equal(d.player.move, 'comboBodyUpper');
  run(d, 2500);
  const hits = d.events.filter(e => e.type === 'hit' && e.attacker === 1 && e.move === 'comboBodyUpper');
  assert.ok(hits.length >= 3, hits.length + ' contatos');
  assert.equal(hits.at(-1).zone, 'head', 'o último é o uppercut');
});

test('combo que anda no desenho: a posição final assume o avanço, sem voltar', () => {
  const d = withMiguel(); d.rival.x = d.player.x + 90;
  const x0 = d.player.x;
  press(d, { kick: true, run: true, right: true });
  assert.equal(d.player.move, 'comboJabElbowKnee');
  until(d, () => d.player.state === 'idle', 3000);
  assert.equal(Math.round(d.player.x - x0), miguel.m4_comboJabElbowKnee.frames.at(-1).advance);
});
