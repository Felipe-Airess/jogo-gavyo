import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { Duel, TICK, STAGE } from '../src/duel/duel.mjs';
import { DuelAI } from '../src/duel/ai.mjs';
import { CLINCH } from '../src/duel/clinch.mjs';
import { sweep } from '../src/duel/collision.mjs';
import { capabilities, createFighter } from '../src/duel/fighter.mjs';
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
  assert.ok(d.player.moveT <= 40, 'o segundo jab começou sem atraso');
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

test('golpe não cancela nele mesmo e a sequência tem limite', () => {
  const d = make(40);
  d.rival.condition.head = -500; // segura o alvo de pé para medir a sequência
  d.rival.balance = 1e6;
  press(d, { attack: true });
  until(d, () => d.player.connected);
  press(d, { attack: true });
  run(d, 150);
  assert.equal(d.player.chain, 1, 'jab não cancela em jab');
  const e = make(40);
  e.rival.balance = 1e6;
  press(e, { attack: true });
  until(e, () => e.player.connected);
  press(e, { attack: true, right: true });
  until(e, () => e.player.move === 'cross' && e.player.connected, 1500);
  press(e, { attack: true, left: true });
  until(e, () => e.player.move === 'hook', 600);
  assert.equal(e.player.chain, 3);
  assert.deepEqual(e.moves.hook.cancels, []);
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
  assert.equal(can.attack, false);
  assert.equal(can.walk, false);
  const d = make(60);
  d.rival.can = can;
  const x = d.rival.x;
  press(d, {}, { attack: true });
  run(d, 300, {}, { left: true });
  assert.equal(attacks(d, 2), 0);
  assert.equal(d.rival.x, x);
  run(d, 50, {}, { guard: true });
  assert.equal(d.rival.state, 'guard');
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
