// Duelo lateral 1×1 sem profundidade jogável. Os dois lutadores passam pelas
// mesmas funções: entrada → buffer → estado → golpe → contato → dano.
import { commandFrom, CHAIN_BUFFER_MS } from '../core/command-buffer.mjs';
import { gaitTable } from '../locomotion.mjs';
import { createFighter, animationRef, gaitOffset, NEUTRAL, SPEED, RUN_START_MS } from './fighter.mjs';
import { createDuelMoves, chooseMove, cancelTarget, frameIndex, groundMove, resolveMove, MAX_CHAIN, CHARACTER_SPECS } from './moves.mjs';
import { MarkerSet, worldMarkers, hurtboxes, guardBox, grabBox, LIMB_SIZE, limbCenter } from './markers.mjs';
import { sweep, contactPoint, overlap } from './collision.mjs';
import { resolveHit, applyHit, contactQuality, ROCK } from './damage.mjs';
import { startClinch, endClinch, keepGap, escapeGain, CLINCH } from './clinch.mjs';

// Recuo visual do atingido (px) no começo da reação, decaindo em RECOIL.ms.
export const RECOIL = { ms: 90, block: 1, graze: 1, hit: 2, clean: 4 };
// Atordoamento a partir do qual a reação é a forte.
export const HEAVY_STUN = 440;
// Direção do impacto: decide qual reação desenhada usar.
//   straight: cabeça para trás · hook: cabeça gira para o lado · uppercut: queixo sobe
//   body: dobra para frente · liver: dobra de lado · legs: joelho cede
export function reactKind(m, zone) {
  if (m.react) return m.react;
  const id = m.id || '';
  if (zone === 'legs') return 'legs';
  if (zone === 'body') return /hook|round/.test(id) ? 'liver' : 'body';
  if (/upper/.test(id)) return 'uppercut';
  if (/hook|round|overhand/.test(id)) return 'hook';
  return 'straight';
}
// Uma janela de um golpe com vários contatos, como golpe próprio: os contatos
// de preparação batem com fração do dano, menos atordoamento e quase sem
// empurrão (o combo continua alcançando); o último bate cheio.
export function hitOf(m, win) {
  const last = win.index === m.hits.length - 1, k = win.scale ?? 1;
  return { ...m, limb: win.limb || m.limb, targets: win.targets || m.targets, react: win.react || m.react,
    damage: Math.round(m.damage * k), balance: Math.round(m.balance * k),
    hitstun: last ? m.hitstun : Math.round(m.hitstun * 0.75), push: last ? m.push : m.push * 0.25, window: win.index };
}
// Região mirada pelo golpe: socos "no corpo" miram o tronco; os outros socos
// miram a cabeça; chutes e golpes com `aim` próprio seguem o spec.
export const AIM_MIN = 0.25;
export function aimOf(m) {
  if (m.aim) return m.targets.includes(m.aim) ? m.aim : null;
  if (m.limb !== 'fist') return null;
  const zone = /body|Body/.test(m.id) ? 'body' : 'head';
  return m.targets.includes(zone) ? zone : null;
}
// Cotovelada: J com o adversário colado (quadris até esta distância).
export const ELBOW_RANGE = 25;
// Maior deslocamento do membro entre dois ticks que ainda conta como varredura.
export const SWEEP_MAX = 45;
export const STAGE = { minX: 24, maxX: 456, ground: 150, half: 10 };
export const TICK = 1000 / 60;
export const HITSTOP = { block: 50, light: 66, medium: 83, heavy: 116 };
// Acerto empurra metade do valor do golpe (o recuo da cabeça já afasta o alvo).
// Sequência: empurrão dos golpes emendados e dano decrescente por posição
// (1º e 2º cheios, depois 85%, 72%), para combo longo não virar nocaute grátis.
// Aparo: L apertado até `window` ms antes do contato desvia o golpe; quem
// atacou fica aberto `stagger` ms e quem aparou tem `counter` ms para o
// contra-ataque (J). Chão: cada golpe segura o caído mais `extend` ms, até
// `maxExtend` no total; arremesso deixa no chão `thrownMs`.
export const PARRY = { window: 140, stagger: 480, counter: 520 };
export const GROUND = { reach: 46, extend: 320, maxExtend: 1600, downMs: 700, thrownMs: 1000 };
// Acompanhar (provisório, até existir golpe com passo desenhado): o golpe
// emendado avança até `max` px durante a preparação quando o alvo recuou além
// do alcance, ou sempre que a frente estiver apertada. O pé desliza esse tanto.
export const STEP_IN = { max: 8, forward: 4, margin: 12, bite: 4 };
export const COMBO = { hitPush: 0.5, push: 0.35, scale: [1, 1, 1, 0.85, 0.72] };
const DOWN = new Set(['knockdown', 'down', 'getup', 'ko']);
const CLINCH_STATES = new Set(['clinchEntry', 'clinch', 'clinchStrike', 'held']);
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const approach = (v, t, a) => v + clamp(t - v, -a, a);

export class Duel {
  // `roster`: arte de outros personagens, { miguel: { clips, markers } }.
  // `clips`/`markers` são os do Sorriso (golpes, alcance e passada vêm dele).
  constructor({ clips, markers, characters = ['sorriso', 'sorriso'], roster = {} }) {
    this.clips = clips;
    this.markers = markers instanceof MarkerSet ? markers : new MarkerSet(markers);
    this.roster = { sorriso: { clips, markers: this.markers } };
    for (const [name, art] of Object.entries(roster)) {
      this.roster[name] = { clips: art.clips, markers: art.markers instanceof MarkerSet ? art.markers : new MarkerSet(art.markers) };
    }
    this.moves = createDuelMoves(clips);
    this.characters = characters;
    // Golpes e alcance por personagem (cada um com a própria arte).
    this.movesBy = {};
    this.reachBy = {};
    for (const [name, art] of Object.entries(this.roster)) {
      this.movesBy[name] = name === 'sorriso' ? this.moves : createDuelMoves(art.clips, CHARACTER_SPECS[name] || {});
      this.reachBy[name] = this.measureReach(this.movesBy[name], art.markers);
    }
    this.reach = this.reachBy.sorriso;
    this.gait = { run: gaitTable(this.markers.clips.r2_run), walk: gaitTable(this.markers.clips.r2_walk) };
    this.reset();
  }

  reset() {
    const [a, b] = this.characters;
    this.fighters = [createFighter(1, a, 200, 1, this.artOf(a).clips), createFighter(2, b, 280, -1, this.artOf(b).clips)];
    this.clock = 0;
    this.hitstop = 0;
    this.events = [];
    this.eventId = 0;
    this.lastHit = null;
    this.result = null;
    this.message = 'Controle a distância. Golpe errado custa caro.';
  }

  // Troca os personagens e recomeça. Só personagens com arte carregada.
  setCharacters(characters) {
    if (!characters.every(c => this.roster[c])) return false;
    this.characters = [...characters];
    this.reset();
    return true;
  }

  artOf(character) { return this.roster[character] || this.roster.sorriso; }
  movesOf(f) { return this.movesBy[f.character] || this.moves; }
  moveOf(f, id = f.move) { return this.movesOf(f)[id]; }
  reachOf(f) { return this.reachBy[f.character] || this.reach; }
  // Golpe que um comando daria a este lutador agora (mesma escolha de act, sem executar).
  commandMove(f, c) { return chooseMove({ kind: c.kick ? 'kick' : 'attack', forward: !!c.forward, back: !!c.back, up: !!c.up, down: !!c.down, run: !!c.run }, f, this.movesOf(f)); }

  get player() { return this.fighters[0]; }
  get rival() { return this.fighters[1]; }
  other(f) { return f === this.fighters[0] ? this.fighters[1] : this.fighters[0]; }
  byId(id) { return this.fighters.find(f => f.id === id); }

  event(type, extra = {}) {
    this.events.push({ id: ++this.eventId, type, at: this.clock, ...extra });
    if (this.events.length > 32) this.events.shift();
  }

  clearInputs() { for (const f of this.fighters) { f.buffer.clear(); f.input = {}; } }

  // Alcance de cada golpe medido nos marcadores dos quadros de contato.
  measureReach(moves = this.moves, markers = this.markers) {
    const out = {};
    for (const m of Object.values(moves)) {
      let best = 0;
      for (const frame of m.active) {
        const mk = markers.frame(m.clip, frame);
        const tip = m.limb === 'foot' ? mk?.frontFoot : m.limb === 'knee' ? mk?.frontKnee : mk?.frontFist;
        if (tip) best = Math.max(best, tip.tipX ?? tip.x);
      }
      out[m.id] = best;
    }
    return out;
  }

  animation(f) { return animationRef(f, this.movesOf(f), this.artOf(f.character).clips, this.gait, this.clock); }
  // Onde o sprite está desenhado (posição física + degrau da passada).
  // O degrau usa a passada medida do Sorriso; Miguel não tem tabela própria.
  drawX(f) {
    const recoil = (f.state === 'hitstun' || f.state === 'blockstun') && f.recoil && f.t < RECOIL.ms ? -f.facing * f.recoil * (1 - f.t / RECOIL.ms) : 0;
    return f.x + (f.character === 'sorriso' ? gaitOffset(f, this.gait) : 0) + recoil;
  }
  markerSetOf(f) { return this.artOf(f.character).markers; }
  markersOf(f) { const ref = this.animation(f); return worldMarkers(this.markerSetOf(f).frame(ref.clip, ref.frame), { ...f, x: this.drawX(f) }); }
  // Durante um golpe o braço estendido também pode ser atingido (e conta como tronco).
  hurtboxesOf(f) { return DOWN.has(f.state) ? {} : hurtboxes(this.markersOf(f), { arms: f.state === 'attack' || f.state === 'clinchStrike' }); }

  // inputs: [entrada do lutador 1, entrada do lutador 2]
  tick(inputs, dt = TICK) {
    for (let i = 0; i < 2; i++) {
      const f = this.fighters[i], input = inputs[i] || {};
      f.input = input;
      f.prevX = f.x;
      const cmd = commandFrom(input, f.facing);
      // Durante a pausa de impacto o relógio para: comandos não expiram.
      if (cmd) f.buffer.push(cmd, this.clock);
    }
    if (this.hitstop > 0) { this.hitstop = Math.max(0, this.hitstop - dt); return; }
    this.clock += dt;
    for (const f of this.fighters) this.update(f, dt);
    const contacts = [];
    for (const f of this.fighters) { const c = this.probe(f, this.other(f)); if (c) contacts.push(c); }
    // Trocas simultâneas: os dois contatos valem.
    for (const c of contacts) this.applyContact(c);
    this.separate();
    this.face();
  }

  // `from`: estado anterior, para o desenho escolher a transição (andar → guarda etc.).
  setState(f, state) { if (f.state !== state) { f.from = f.state; f.state = state; f.t = 0; } }
  toIdle(f) { this.commitRoot(f); f.from = f.state; f.state = 'idle'; f.t = 0; f.move = null; f.chain = 0; f.vx *= 0.3; }

  regen(f, s) {
    const busy = f.state === 'attack' || CLINCH_STATES.has(f.state);
    const stunned = ['hitstun', 'blockstun', 'knockdown', 'down', 'ko', 'collapse'].includes(f.state);
    f.headRecent = Math.max(0, f.headRecent - ROCK.decay * s);
    if (!stunned && !this.isRocked(f)) f.balance = Math.min(100, f.balance + (busy ? 12 : 30) * s);
    const gain = f.state === 'run' ? -6 : f.state === 'guard' ? 8 : busy || stunned ? 0 : 22;
    f.stamina = clamp(f.stamina + gain * s, 0, 100);
  }

  update(f, dt) {
    const s = dt / 1000, o = this.other(f);
    f.t += dt;
    this.regen(f, s);
    switch (f.state) {
      case 'attack': return this.updateAttack(f, dt);
      case 'clinchStrike': return this.updateClinchStrike(f, o, dt);
      case 'whiff': if (f.t >= this.moveOf(f).whiff.times.reduce((a, b) => a + b, 0)) { this.toIdle(f); this.takeBuffered(f); } return;
      case 'hitstun':
      case 'blockstun':
        this.slide(f, s, 10);
        if (f.t >= f.stun) this.toIdle(f);
        return;
      case 'knockdown':
        this.slide(f, s, 5);
        if (f.t >= 450) { this.setState(f, 'down'); this.event('land', { fighter: f.id, x: f.x }); }
        return;
      case 'ko':
        this.slide(f, s, 5);
        if (!f.landed && f.t >= 340) { f.landed = true; this.event('land', { fighter: f.id, x: f.x, ko: true }); }
        return;
      case 'down': if (f.t >= (f.downMs || GROUND.downMs)) { f.downMs = 0; f.downExtra = 0; f.landFrom = null; this.setState(f, 'getup'); } return;
      case 'parried':
        this.slide(f, s, 8);
        if (f.t >= PARRY.stagger) this.toIdle(f);
        return;
      case 'thrown': return this.updateThrown(f, o);
      case 'getup':
        if (f.t >= 160 + 90 * 6) { this.toIdle(f); f.balance = Math.max(f.balance, 60); }
        return;
      case 'collapse':
        if (f.t >= 1300) { this.setState(f, 'rise'); f.condition.body = Math.min(f.condition.body, 70); f.balance = Math.max(f.balance, 50); }
        return;
      case 'grabMiss': if (f.t >= CLINCH.missMs) this.toIdle(f); return;
      case 'clinchEntry':
        keepGap(f, o, dt);
        f.clinch.grip -= dt;
        if (f.t >= CLINCH.entry) this.setState(f, 'clinch');
        return;
      case 'clinch': return this.updateClinch(f, o, dt);
      case 'held': return this.updateHeld(f, o, dt);
      case 'brake': {
        // Freada da corrida: desacelera junto com os apoios de r2_runStop.
        const cmd = f.buffer.peek(this.clock);
        if (cmd && this.act(f, o, cmd)) { f.buffer.clear(); return; }
        if ((f.input || {}).guard && f.can.guard) { f.guardAt = this.clock; this.setState(f, 'guard'); return; }
        const s = dt / 1000;
        f.vx = approach(f.vx, 0, SPEED.run / 0.42 * s);
        this.slide(f, s, 0);
        if (f.t >= this.clips.r2_runStop.totalMs || (Math.abs(f.vx) < 1 && f.t >= 330)) this.toIdle(f);
        return;
      }
      case 'rise': {
        const cmd = f.buffer.peek(this.clock);
        if (cmd && this.act(f, o, cmd)) { f.buffer.clear(); return; }
        if (f.t >= this.clips.r2_crouchUp.totalMs) this.toIdle(f);
        return;
      }
      default: return this.updateNeutral(f, o, dt);
    }
  }

  slide(f, s, friction) { f.x = clamp(f.x + f.vx * s, STAGE.minX, STAGE.maxX); f.vx *= Math.exp(-friction * s); }

  updateNeutral(f, o, dt) {
    const s = dt / 1000, input = f.input || {};
    const cmd = f.buffer.peek(this.clock);
    if (cmd && this.act(f, o, cmd)) { f.buffer.clear(); return; }
    if (input.guard && f.can.guard) {
      // `steady`: guarda comum pedida pela IA, que não vira aparo pelo tempo de reação.
      if (f.state !== 'guard') f.guardAt = input.steady ? -1e9 : this.clock;
      this.setState(f, 'guard'); f.vx = approach(f.vx, 0, 600 * s); this.slide(f, s, 0); return;
    }
    if (input.down && f.can.crouch) { this.setState(f, 'crouch'); f.vx = 0; return; }
    if (f.state === 'crouch') { this.setState(f, 'rise'); return; }
    const dir = Number(!!input.right) - Number(!!input.left), rel = dir * f.facing;
    const legs = (1 - f.condition.legs / 250) * (this.isRocked(f) ? ROCK.speed : 1);
    const running = input.run && rel > 0 && f.can.run && f.stamina > 5 && !this.isRocked(f);
    const speed = running ? SPEED.run : rel > 0 ? SPEED.forward * legs : rel < 0 ? -SPEED.back * legs : 0;
    if (!f.can.walk && !running) { f.vx = 0; this.setState(f, f.state === 'guard' ? 'idle' : f.state); return; }
    // Soltou a corrida em velocidade: freada desenhada, não o ciclo de andar girando.
    if (f.state === 'run' && !running && Math.abs(f.vx) > 50) { this.setState(f, 'brake'); this.event('brake', { fighter: f.id, x: f.x }); return; }
    if (running && f.state !== 'run') { f.state = 'run'; f.t = 0; f.runDistance = 0; this.event('dash', { fighter: f.id, x: f.x }); }
    // Na arrancada a aceleração acompanha os 340 ms dos quadros de saída.
    const accel = running && f.t < RUN_START_MS ? SPEED.run / (RUN_START_MS / 1000) : 520;
    f.vx = approach(f.vx, speed * f.facing, accel * s);
    const before = f.x;
    f.x = clamp(f.x + f.vx * s, STAGE.minX, STAGE.maxX);
    const moved = (f.x - before) * f.facing;
    // O ciclo começa depois da arrancada, na fase do primeiro contato.
    if (running) { if (f.t >= RUN_START_MS) f.runDistance += Math.abs(moved); }
    else if (Math.abs(f.vx) > 2) {
      const rel = Math.sign(moved);
      // Mudar de direção reinicia o ciclo (frente e trás são desenhos diferentes no Miguel).
      if (f.state === 'walk' && rel && rel !== f.walkRel) f.t = 0;
      if (rel) f.walkRel = rel;
      this.setState(f, 'walk'); f.gait += moved;
    }
    else this.setState(f, 'idle');
  }

  act(f, o, cmd) {
    if (cmd.kind === 'grab') return this.tryGrab(f, o);
    if (!f.can.attack) return false;
    // Aparou há pouco: J vira o contra-ataque desenhado.
    if (cmd.kind === 'attack' && this.clock < f.parryUntil && this.moveOf(f, 'parryCounter')) { f.parryUntil = 0; return this.begin(f, 'parryCounter', false); }
    // Adversário caído à frente e perto: golpes de chão (se o personagem tiver desenho).
    if (this.groundReach(f, o) && this.moveOf(f, groundMove(cmd))) return this.begin(f, groundMove(cmd), false);
    let id = chooseMove(cmd, f, this.movesOf(f));
    if (id === 'jab' && this.moveOf(f, 'elbow') && !DOWN.has(o.state) && Math.abs(o.x - f.x) <= ELBOW_RANGE) id = 'elbow';
    return this.begin(f, id, false);
  }

  // Avanço desenhado (golpe com `root`): o corpo anda dentro do quadro; ao sair
  // do golpe, a posição do lutador assume esse avanço, sem voltar ao centro.
  commitRoot(f) {
    if (f.state !== 'attack' || !f.move) return;
    const m = this.moveOf(f);
    if (!m?.root) return;
    const adv = this.artOf(f.character).clips[m.clip]?.frames[m.frames[frameIndex(m, f.moveT)]]?.advance || 0;
    if (adv) f.x = clamp(f.x + f.facing * adv, STAGE.minX, STAGE.maxX);
  }

  groundReach(f, o) {
    const dx = (o.x - f.x) * f.facing;
    return (o.state === 'knockdown' || o.state === 'down') && dx > 0 && dx <= GROUND.reach;
  }

  // Arremesso: quem foi pego acompanha quem arremessa até o quadro do contato.
  // ---- Golpes em par -------------------------------------------------------
  // Golpe em par disponível para a situação (`pair.when`): 'combo' = depois de
  // 2+ golpes que tocaram, com o adversário atordoado e ao alcance.
  pairFor(f, o, when) {
    for (const [id, m] of Object.entries(this.movesOf(f))) {
      if (m.pair?.when === when && Math.abs(o.x - f.x) <= (m.pair.reach ?? 44)) return id;
    }
    return null;
  }

  startPair(a, d, id, chained) {
    if (!this.begin(a, id, chained)) return false;
    a.pairDone = [];
    d.state = 'thrown'; d.t = 0; d.vx = 0; d.move = null; d.buffer.clear(); d.pairOf = a.id; d.pairRef = null;
    if (d.clinch) endClinch(this.byId(d.clinch.partner), d);
    this.event('grab', { fighter: a.id, target: d.id });
    return true;
  }

  // Quem bate: contatos no quadro desenhado; ao fim, guarda (e solta a vítima
  // se ela ainda estiver presa, p.ex. golpe interrompido).
  updatePair(a, d, m) {
    const frame = m.frames[frameIndex(m, a.moveT)];
    if (d.state === 'thrown' && d.pairOf === a.id) {
      for (const [i, c] of m.pair.contacts.entries()) {
        if (frame >= c.frame && !a.pairDone.includes(i)) { a.pairDone.push(i); this.pairHit(a, d, m, c); }
      }
    }
    if (a.moveT >= m.duration) {
      if (d.state === 'thrown' && d.pairOf === a.id) this.toIdle(d);
      this.toIdle(a); this.takeBuffered(a);
    }
  }

  // Vítima: presa na distância e no olhar do desenho; o quadro dela segue o
  // do atacante (pair.victim[personagem].frames[i]).
  updateThrown(f, o) {
    const m = o.state === 'attack' ? this.moveOf(o) : null;
    if (!m?.pair || f.pairOf !== o.id) { f.pairRef = null; this.toIdle(f); return; }
    const k = frameIndex(m, o.moveT), gap = Array.isArray(m.pair.gap) ? m.pair.gap[Math.min(k, m.pair.gap.length - 1)] : m.pair.gap;
    f.x = clamp(o.x + o.facing * gap, STAGE.minX, STAGE.maxX); f.facing = -o.facing; f.vx = 0;
    const v = m.pair.victim?.[f.character];
    f.pairRef = v && this.artOf(f.character).clips[v.clip] ? { clip: v.clip, frame: v.frames[Math.min(k, v.frames.length - 1)] } : null;
  }

  // Contato garantido pelo desenho (sem caixa): dano, efeitos e, se `lands`,
  // a vítima vai ao chão.
  pairHit(a, d, m, c) {
    a.hitDone = true; a.connected = true;
    const mm = c.scale ? { ...m, damage: Math.round(m.damage * c.scale) } : m;
    const r = resolveHit(mm, d, c.zone, { quality: 'clean', rocked: this.isRocked(d) });
    applyHit(d, r);
    this.hitstop = HITSTOP.heavy;
    const point = { x: d.x, y: d.y - (c.zone === 'head' ? 52 : 6) };
    this.lastHit = { at: this.clock, attacker: a.id, target: d.id, move: m.id, zone: c.zone, kind: m.throw ? 'throw' : 'hit', damage: r.damage, counter: false, blocked: false, quality: 'clean', point };
    this.event('hit', { attacker: a.id, target: d.id, move: m.id, zone: c.zone, kind: m.throw ? 'throw' : 'hit', counter: false, quality: 'clean', heavy: true, power: 3, damage: r.damage, point });
    if (c.lands || r.kind === 'ko') {
      d.state = r.kind === 'ko' ? 'ko' : 'down'; d.t = 0; d.downMs = GROUND.thrownMs; d.downExtra = 0; d.vx = a.facing * 30; d.move = null; d.buffer.clear(); d.pairRef = null;
      d.landFrom = m.throw ? 'thrown' : null;
      this.event('land', { fighter: d.id, x: d.x });
    }
    if (r.kind === 'ko') { d.ko = true; this.result = { winner: a.id, loser: d.id, reason: r.reason, at: this.clock }; this.event('ko', { winner: a.id, reason: r.reason }); }
    if (m.throw) this.message = d === this.player ? 'Arremessado! Aguente no chão.' : 'ARREMESSO! J e K batem no chão.';
    else this.message = m.name + '!';
  }

  begin(f, id, chained) {
    id = resolveMove(this.movesOf(f), id);
    const m = this.moveOf(f, id);
    if (!m) return false;
    if (f.stamina < m.cost * 0.5) { this.event('winded', { fighter: f.id }); if (f === this.player) this.message = 'Sem fôlego para esse golpe.'; return false; }
    f.stamina = Math.max(0, f.stamina - m.cost);
    const from = chained ? this.animation(f) : null;
    if (chained) this.commitRoot(f);
    f.moveFrom = chained ? f.move : null;
    f.chain = chained ? f.chain + 1 : 1;
    f.combo = chained ? [...(f.combo || []), id] : [id];
    // Na sequência o golpe novo começa no quadro de preparação mais parecido
    // com a pose atual (marcadores), em vez de voltar à guarda: emenda sem
    // salto e mais rápido. Fica sempre ao menos um quadro antes do contato.
    const entry = from ? this.entryFrame(from, m, this.markerSetOf(f)) : 0;
    f.state = 'attack'; f.t = 0; f.move = id; f.moveT = m.times.slice(0, entry).reduce((a, b) => a + b, 0);
    f.stepLeft = 0;
    if (chained && !m.ground && !m.throw) {
      // Distância até a borda mais próxima das regiões que o golpe mira, no
      // quadro atual do alvo (a reação desenhada pode recuar a cabeça ou a perna).
      const o = this.other(f), boxes = this.hurtboxesOf(o);
      // Fragmentos de poucos pixels (mão, contorno) não contam: dariam só raspão.
      const edges = m.targets.flatMap(z => (boxes[z] || []).filter(b => b.w * b.h >= 16).map(b => (f.facing > 0 ? b.x - f.x : f.x - (b.x + b.w))));
      const edge = edges.length ? Math.min(...edges) : Math.abs(o.x - f.x) - STEP_IN.margin;
      const need = edge - (this.reachOf(f)[id] || 30) + STEP_IN.bite;
      const forward = (f.input?.right && f.facing > 0) || (f.input?.left && f.facing < 0);
      const step = Math.min(STEP_IN.max, Math.max(need, forward ? STEP_IN.forward : 0));
      const prep = m.activeStart - f.moveT;
      if (step > 0.5 && prep > 0) { f.stepLeft = step; f.stepRate = step / prep; }
    }
    f.connected = false; f.hitDone = false; f.prevTip = null; f.hitWindow = -1;
    // Socos do lote 3 mantêm o pé de trás plantado no pivô: sem avanço extra
    // (avançar o sprite faria o pé deslizar). Só o soco de impulso conserva a corrida.
    if (!m.carry) f.vx *= 0.2;
    this.event('attack', { fighter: f.id, move: id, chained });
    return true;
  }

  // Índice (em m.frames) do quadro de preparação mais próximo da pose `ref`.
  entryFrame(ref, m, markers = this.markers) {
    const key = ref.clip + ':' + ref.frame + '>' + m.clip + ':' + m.id;
    this.entryCache ??= new Map();
    if (this.entryCache.has(key)) return this.entryCache.get(key);
    const a = markers.frame(ref.clip, ref.frame), last = m.frames.indexOf(m.active[0]) - 1;
    const pts = k => k && [k.head, k.hip, k.frontFist && { x: k.frontFist.tipX, y: k.frontFist.tipY }, k.frontFoot && { x: k.frontFoot.tipX, y: k.frontFoot.tipY }];
    const pa = pts(a);
    let best = 0, cost = Infinity;
    for (let i = 0; pa && i <= last; i++) {
      const pb = pts(markers.frame(m.clip, m.frames[i]));
      if (!pb) continue;
      let c = 0;
      for (let j = 0; j < pa.length; j++) c += pa[j] && pb[j] ? Math.hypot(pa[j].x - pb[j].x, pa[j].y - pb[j].y) : 12;
      if (c < cost - 0.5) { cost = c; best = i; }
    }
    this.entryCache.set(key, best);
    return best;
  }

  updateAttack(f, dt) {
    const s = dt / 1000, m = this.moveOf(f);
    f.moveT += dt;
    if (f.stepLeft > 0) {
      const dx = Math.min(f.stepLeft, f.stepRate * dt);
      f.x = clamp(f.x + f.facing * dx, STAGE.minX, STAGE.maxX);
      f.stepLeft -= dx;
    }
    if (m.carry) { f.vx = approach(f.vx, 0, m.carry * 2 * s); this.slide(f, s, 0); }
    else { f.vx = approach(f.vx, 0, 400 * s); this.slide(f, s, 0); }
    const o = this.other(f);
    // Golpe em par (arremesso e, quando houver arte, finalizações): os dois em
    // sincronia; o dano sai no quadro de contato desenhado.
    if (m.pair) { this.updatePair(f, o, m); return; }
    const cmd = f.buffer.peek(this.clock, CHAIN_BUFFER_MS);
    // Fim de sequência: G com o adversário atordoado e perto agarra e arremessa.
    if (cmd?.kind === 'grab' && f.connected && f.chain >= 2 && !m.ground && f.moveT >= m.cancelStart && f.moveT <= m.cancelEnd
      && o.state === 'hitstun') {
      const id = this.pairFor(f, o, 'combo');
      if (id && this.startPair(f, o, id, true)) { f.buffer.clear(); return; }
    }
    if (cmd && cmd.kind !== 'grab' && f.connected && f.chain < MAX_CHAIN && f.moveT >= m.cancelStart && f.moveT <= m.cancelEnd
      && (!m.ground || this.groundReach(f, o))) {
      const next = cancelTarget(m, cmd, f, f.combo, this.movesOf(f));
      if (next && this.begin(f, next, true)) { f.buffer.clear(); return; }
    }
    if (f.moveT >= m.duration) {
      if (!f.connected && m.whiff) { f.state = 'whiff'; f.t = 0; this.event('whiff', { fighter: f.id, move: m.id }); return; }
      this.toIdle(f);
      this.takeBuffered(f);
    }
  }

  // Primeira brecha: o comando apertado durante o golpe (ou a recuperação do
  // erro) sai no primeiro tick livre, sem precisar apertar de novo no tempo exato.
  takeBuffered(f) {
    const cmd = f.buffer.peek(this.clock, CHAIN_BUFFER_MS);
    if (cmd && this.act(f, this.other(f), cmd)) f.buffer.clear();
  }

  // Contato do golpe atual contra o outro lutador, com varredura do membro.
  probe(a, d) {
    if (a.state !== 'attack' && a.state !== 'clinchStrike') return null;
    const base = this.moveOf(a), frame = base.frames[frameIndex(base, a.moveT)];
    // Golpe com vários contatos (combo desenhado): cada janela acerta uma vez,
    // com o membro, as regiões e a fração do dano dela.
    const win = base.hits?.find(h => h.frames.includes(frame)) || null;
    if (win && win.index !== a.hitWindow) {
      if ((win.limb || base.limb) !== (base.hits[a.hitWindow]?.limb || base.limb)) a.prevTip = null;
      a.hitWindow = win.index; a.hitDone = false;
    }
    const m = win ? hitOf(base, win) : base;
    const w = worldMarkers(this.markerSetOf(a).frame(m.clip, frame), a), tip = limbCenter(w?.[m.limb], m.limb, a.facing);
    const active = m.active.includes(frame);
    if (!tip) { if (active) this.markerSetOf(a).note(m.clip, frame, m.limb); a.prevTip = null; return null; }
    // Varredura só entre posições vizinhas do mesmo membro. Um salto maior que
    // SWEEP_MAX (o marcador trocou de pé, ou o desenho não tem os quadros do
    // meio — chute alto do Miguel sai do chão direto para a cabeça) não arrasta
    // a caixa pelo caminho inventado.
    const near = a.prevTip && Math.hypot(tip.x - a.prevTip.x, tip.y - a.prevTip.y) <= SWEEP_MAX;
    const from = near ? a.prevTip : tip;
    a.prevTip = tip;
    if (!active || a.hitDone || m.throw) return null;
    // Golpes de chão só em quem está caído; os outros só em quem está de pé.
    const downed = d.state === 'knockdown' || d.state === 'down';
    if (m.ground ? !downed : DOWN.has(d.state) || d.state === 'thrown') return null;
    if (!!m.clinch !== (a.state === 'clinchStrike')) return null;
    if (d.state === 'held' && d.clinch?.partner !== a.id) return null;
    // No chão o desenho deitado não separa tronco e pernas pela altura: o que
    // não é cabeça conta como tronco.
    const lying = m.ground ? hurtboxes(this.markersOf(d)) : null;
    const boxes = lying ? { head: lying.head || [], body: [...(lying.body || []), ...(lying.legs || [])] } : this.hurtboxesOf(d);
    const [hw, hh] = LIMB_SIZE[m.limb].map(v => v / 2);
    let best = null;
    const legsOnly = m.targets.length === 1 && m.targets[0] === 'legs';
    // Chute na perna mira a coxa: a caixa sobe um pouco acima da linha da calça.
    // Chute na perna mira a coxa: a faixa de 8 px acima do quadril também conta como perna.
    const hipY = boxes.legs ? Math.min(...boxes.legs.map(b => b.y)) : null;
    const zoneBoxes = zone => {
      if (!legsOnly) return boxes[zone] || [];
      const thigh = (boxes.body || []).filter(b => b.y + b.h > hipY - 8).map(b => {
        const y = Math.max(b.y, hipY - 8);
        return { ...b, y, h: b.y + b.h - y };
      });
      return [...(boxes.legs || []), ...thigh];
    };
    // Primeiro, onde o membro está agora (maior sobreposição). A varredura em
    // linha reta só entra quando o membro passou inteiro entre dois ticks:
    // num chute circular a reta entre a perna dobrada e a estendida cortaria o
    // tronco, embora o pé desenhado chegue na cabeça.
    const limb = { x: tip.x - hw, y: tip.y - hh, w: hw * 2, h: hh * 2 };
    // Área somada por região: a região mais coberta pelo membro decide —
    // exceto quando o golpe é mirado (`aimOf`) e pega ao menos AIM_MIN da
    // região mirada: direto no rosto que pega o queixo é cabeça, mesmo com a
    // maior parte do punho sobre o peito (2 px de diferença de altura entre
    // personagens mandavam quase todo soco do Sorriso para o tronco do Miguel).
    const areas = {};
    for (const zone of m.targets) {
      let area = 0, top = null;
      for (const box of zoneBoxes(zone)) {
        if (!overlap(limb, box)) continue;
        const part = (Math.min(limb.x + limb.w, box.x + box.w) - Math.max(limb.x, box.x)) * (Math.min(limb.y + limb.h, box.y + box.h) - Math.max(limb.y, box.y));
        area += part;
        if (!top || part > top.part) top = { box, part };
      }
      if (top) areas[zone] = { zone, t: 1, area, box: top.box, coverage: Math.min(1, area / (4 * hw * hh)) };
      if (top && (!best || area > best.area)) best = areas[zone];
    }
    const aim = aimOf(m);
    if (aim && areas[aim] && areas[aim].area >= AIM_MIN * 4 * hw * hh) best = areas[aim];
    if (!best) for (const zone of m.targets) for (const box of zoneBoxes(zone)) {
      const t = sweep(from, tip, hw, hh, box);
      if (t !== null && t !== undefined && (!best || t < best.t)) best = { zone, t, box };
    }
    const front = (a.x - d.x) * d.facing > 0;
    if ((d.state === 'guard' || d.state === 'blockstun') && front && !legsOnly && !m.ground) {
      const g = guardBox(d, this.markersOf(d)), tg = g ? sweep(from, tip, hw, hh, g) : null;
      // A guarda alta cobre cabeça e tronco; a perna continua exposta.
      if ((tg !== null && (!best || tg <= best.t)) || (best && best.zone !== 'legs')) {
        const point = tg !== null ? contactPoint(from, tip, tg, g) : contactPoint(from, tip, best.t, best.box);
        // Guarda levantada no último instante: aparo.
        const parried = d.state === 'guard' && this.clock - (d.guardAt ?? -1e9) <= PARRY.window;
        return { a, d, m, blocked: true, parried, zone: 'arms', point };
      }
    }
    if (!best) return null;
    // Cobertura só existe quando o membro está dentro da caixa; na varredura
    // (membro atravessou entre dois ticks) a profundidade não é medida: normal.
    return { a, d, m, blocked: false, zone: best.zone, point: contactPoint(from, tip, best.t, best.box), coverage: best.coverage ?? null };
  }

  isRocked(f) { return this.clock < f.rockedUntil; }

  applyContact(c) {
    if (c.parried) return this.applyParry(c);
    if (c.m.ground) return this.applyGround(c);
    return this.applyStrike(c);
  }

  applyParry({ a, d, m, point }) {
    a.hitDone = true; a.connected = false;
    // O golpe desviado leva o corpo de quem bateu para dentro da guarda.
    a.state = 'parried'; a.t = 0; a.move = null; a.chain = 0; a.buffer.clear(); a.vx = a.facing * 90;
    d.parryUntil = this.clock + PARRY.counter;
    d.stamina = Math.min(100, d.stamina + 6);
    this.hitstop = HITSTOP.heavy;
    this.lastHit = { at: this.clock, attacker: a.id, target: d.id, move: m.id, zone: 'arms', kind: 'parry', damage: 0, counter: false, blocked: true, quality: 'normal', point };
    this.event('block', { attacker: a.id, target: d.id, move: m.id, zone: 'arms', kind: 'parry', counter: true, quality: 'normal', heavy: true, power: 2, damage: 0, point: { ...point } });
    this.message = d === this.player ? 'APARADO! J agora contra-ataca.' : 'Ele aparou: saia da frente.';
  }

  applyGround({ a, d, m, zone, point, coverage = null }) {
    a.hitDone = true; a.connected = true;
    const quality = contactQuality(coverage);
    const r = resolveHit(m, d, zone, { quality, ground: true, scale: COMBO.scale[Math.min(a.chain, COMBO.scale.length - 1)] });
    applyHit(d, r);
    d.groundHitAt = this.clock;
    this.hitstop = r.kind === 'ko' ? HITSTOP.heavy : HITSTOP.medium;
    this.lastHit = { at: this.clock, attacker: a.id, target: d.id, move: m.id, zone: r.zone, kind: r.kind, damage: r.damage, counter: false, blocked: false, quality, coverage, point };
    this.event('hit', { attacker: a.id, target: d.id, move: m.id, zone: r.zone, kind: r.kind, counter: false, quality, heavy: true, power: 3, damage: r.damage, point: { ...point }, ground: true });
    if (r.kind === 'ko') {
      d.state = 'ko'; d.t = 0; d.ko = true; d.landed = true;
      this.result = { winner: a.id, loser: d.id, reason: r.reason, at: this.clock };
      this.event('ko', { winner: a.id, reason: r.reason });
      this.message = r.reason;
      return;
    }
    // Cada golpe segura o caído um pouco mais no chão, até um limite.
    const extra = Math.min(GROUND.extend, GROUND.maxExtend - (d.downExtra || 0));
    if (extra > 0) { d.downExtra = (d.downExtra || 0) + extra; d.downMs = (d.downMs || GROUND.downMs) + extra; }
    this.message = m.name + (zone === 'head' ? ' na cabeça.' : ' no corpo.');
  }

  applyStrike({ a, d, m, blocked, zone, point, coverage = null }) {
    a.hitDone = true;
    a.connected = true;
    const dm = d.state === 'attack' ? this.moveOf(d) : null;
    const counter = m.id === 'parryCounter' || (!blocked && !!dm && d.moveT < dm.activeEnd);
    let quality = blocked ? 'normal' : contactQuality(coverage);
    // Golpe abafado: colado demais para o braço/perna estender, não sai limpo.
    if (quality === 'clean' && Math.abs(a.x - d.x) < (this.reachOf(a)[m.id] || 0) * 0.6) quality = 'normal';
    const wasRocked = this.isRocked(d);
    const r = resolveHit(m, d, zone, { blocked, counter, quality, rocked: wasRocked, scale: COMBO.scale[Math.min(a.chain, COMBO.scale.length - 1)] });
    applyHit(d, r);
    // Impacto sentido: o limpo sobe um degrau na pausa e no tremor; o raspão desce.
    const power = Math.max(1, Math.min(3, m.power + (quality === 'clean' ? 1 : quality === 'graze' ? -1 : 0)));
    this.hitstop = blocked || quality === 'graze' ? HITSTOP.block : r.kind !== 'hit' || power >= 3 ? HITSTOP.heavy : power === 2 ? HITSTOP.medium : HITSTOP.light;
    this.lastHit = { at: this.clock, attacker: a.id, target: d.id, move: m.id, zone: r.zone, kind: r.kind, damage: r.damage, counter, blocked, quality, coverage, point };
    this.event(r.kind === 'block' ? 'block' : 'hit', { attacker: a.id, target: d.id, move: m.id, zone: r.zone, kind: r.kind, counter, quality, heavy: power >= 3, power, damage: r.damage, point: { ...point } });
    // Grogue: dano recente na cabeça (o limpo pesa mais) passando do limite.
    if (!blocked && r.zone === 'head' && r.kind !== 'ko') {
      d.headRecent += r.damage * (quality === 'clean' ? ROCK.clean : 1);
      if (!wasRocked && d.headRecent >= ROCK.threshold) {
        d.rockedUntil = this.clock + ROCK.ms;
        this.event('rocked', { fighter: d.id });
      }
    }
    const tag = quality === 'clean' ? ' LIMPO' : quality === 'graze' ? ' de raspão' : '';
    if (r.reason) this.message = r.reason;
    else if (this.isRocked(d) && !wasRocked) this.message = (d === this.player ? 'Você está grogue' : 'Ele ficou grogue') + ': um golpe limpo na cabeça derruba.';
    else if (counter) this.message = 'Contra-ataque: ' + m.name + tag + '.';
    else this.message = blocked ? 'Defendido.' : m.name + tag + (zone === 'head' ? ' na cabeça.' : zone === 'body' ? ' no tronco.' : ' na perna.');
    // Dentro da sequência o empurrão é menor: cada acerto afastava o alvo uns
    // 6–12 px e o terceiro golpe passava no vazio.
    const pushV = a.facing * r.push * 10 * (r.kind === 'hit' ? COMBO.hitPush : 1) * (a.chain > 1 ? COMBO.push : 1);
    if (a.clinch && d.clinch && r.kind === 'hit') { a.clinch.grip = Math.min(CLINCH.maxGrip, a.clinch.grip + CLINCH.refresh); return; }
    if (d.clinch) endClinch(this.byId(d.clinch.partner), d);
    d.buffer.clear();
    this.commitRoot(d);
    d.move = null;
    d.stun = r.stun;
    d.reaction = r.zone;
    // Reação acompanha o golpe: tipo (direção do impacto), força e um recuo de
    // poucos px só no começo, na direção do golpe (ver RECOIL e drawX).
    d.reactKind = reactKind(m, r.zone);
    d.reactHeavy = r.kind === 'hit' && (quality === 'clean' || r.stun >= HEAVY_STUN || this.isRocked(d));
    d.recoil = r.kind === 'block' ? RECOIL.block : quality === 'clean' ? RECOIL.clean : quality === 'graze' ? RECOIL.graze : RECOIL.hit;
    if (r.kind === 'block') { d.state = 'blockstun'; d.t = 0; d.vx = pushV; }
    else if (r.kind === 'guardBreak') { d.state = 'hitstun'; d.t = 0; d.reaction = 'body'; d.reactKind = 'guardBreak'; d.vx = pushV; }
    else if (r.kind === 'hit') { d.state = 'hitstun'; d.t = 0; d.vx = pushV; }
    else if (r.kind === 'knockdown') { d.state = 'knockdown'; d.t = 0; d.vx = pushV + a.facing * 40; }
    else if (r.kind === 'collapse') { d.state = 'collapse'; d.t = 0; d.vx = 0; }
    else if (r.kind === 'ko') { d.state = 'ko'; d.t = 0; d.ko = true; d.vx = pushV + a.facing * 50; this.result = { winner: a.id, loser: d.id, reason: r.reason, at: this.clock }; this.event('ko', { winner: a.id, reason: r.reason }); }
    // Contra a parede, quem bate recua no lugar de quem apanha.
    const wall = d.x <= STAGE.minX + 1 || d.x >= STAGE.maxX - 1;
    if (wall && (r.kind === 'hit' || r.kind === 'block')) a.vx = -pushV * 0.6;
  }

  tryGrab(f, o) {
    if (!f.can.clinch) return false;
    const g = grabBox(f, this.markersOf(f)), body = this.hurtboxesOf(o).body || [];
    const blocked = DOWN.has(o.state) || o.clinch || o.state === 'attack' || o.state === 'collapse';
    if (!body.some(b => overlap(g, b)) || blocked) {
      f.state = 'grabMiss'; f.t = 0; f.vx = 0;
      this.event('grabMiss', { fighter: f.id });
      if (f === this.player) this.message = o.state === 'attack' ? 'O golpe dele impediu o agarrão.' : 'Agarrão no vazio: chegue mais perto.';
      return true;
    }
    startClinch(f, o);
    this.event('clinch', { fighter: f.id, target: o.id });
    this.message = f === this.player ? 'Clinch: J soco curto · K joelhada · direção arrasta · G solta.' : 'Agarrado! Aperte golpes ou puxe para trás para escapar.';
    return true;
  }

  updateClinch(f, o, dt) {
    const s = dt / 1000, c = f.clinch, input = f.input || {};
    c.grip -= dt;
    keepGap(f, o, dt);
    const cmd = f.buffer.take(this.clock);
    if (cmd?.kind === 'grab') { endClinch(f, o, 'release'); this.event('release', { fighter: f.id }); return; }
    if (cmd) {
      // Sem soco curto desenhado (Miguel), J também dá a joelhada.
      const want = cmd.kind === 'kick' ? 'knee' : 'clinchPunch', id = this.moveOf(f, want) ? want : 'knee', m = this.moveOf(f, id);
      if (m && f.stamina >= m.cost * 0.5) {
        f.stamina = Math.max(0, f.stamina - m.cost);
        f.state = 'clinchStrike'; f.t = 0; f.move = id; f.moveT = 0; f.hitDone = false; f.connected = false; f.prevTip = null;
        return;
      }
    }
    const rel = (Number(!!input.right) - Number(!!input.left)) * f.facing;
    if (rel) {
      const dx = rel * f.facing * CLINCH.drag * s;
      const nx = clamp(f.x + dx, STAGE.minX, STAGE.maxX), ox = clamp(o.x + dx, STAGE.minX, STAGE.maxX);
      const moved = Math.min(Math.abs(nx - f.x), Math.abs(ox - o.x)) * Math.sign(dx);
      f.x += moved; o.x += moved; f.gait += Math.abs(moved);
      f.stamina = Math.max(0, f.stamina - CLINCH.dragCost * s);
      c.grip -= dt * 0.25;
    }
    if (c.grip <= 0 || f.stamina <= 0) { endClinch(f, o, 'escape'); this.event('release', { fighter: f.id, reason: 'grip' }); this.message = 'A pegada se desfez.'; }
  }

  updateClinchStrike(f, o, dt) {
    const m = this.moveOf(f);
    f.moveT += dt;
    if (f.clinch) { f.clinch.grip -= dt; keepGap(f, o, dt); }
    if (f.moveT >= m.duration) {
      if (f.clinch && o.clinch) { f.state = 'clinch'; f.t = 0; f.move = null; }
      else this.toIdle(f);
    }
  }

  updateHeld(d, a, dt) {
    const s = dt / 1000, c = d.clinch, input = d.input || {};
    if (!a?.clinch) { endClinch(null, d); return; }
    const cmd = d.buffer.take(this.clock);
    if (cmd) { c.escape += escapeGain(d, a); d.stamina = Math.max(0, d.stamina - CLINCH.pulseCost); }
    const rel = (Number(!!input.right) - Number(!!input.left)) * d.facing;
    if (rel < 0 && d.stamina > 0) c.escape += CLINCH.holdEscape * s;
    if (c.escape >= 100) { endClinch(a, d, 'escape'); this.event('escape', { fighter: d.id }); this.message = d === this.player ? 'Você escapou do clinch.' : 'Ele escapou do clinch.'; }
  }

  // Pushbox: corpos de pé não se atravessam. Contra a parede, empurra só o outro.
  separate() {
    const [a, b] = this.fighters;
    // Golpe em par: a distância é a do desenho (updateThrown), não a do empurrão.
    if (DOWN.has(a.state) || DOWN.has(b.state) || a.clinch || b.clinch || a.state === 'thrown' || b.state === 'thrown') return;
    // Centro do corpo pelo quadril desenhado: o passo à frente de um golpe
    // pesado empurra o outro, em vez de atravessá-lo.
    const hip = f => this.markersOf(f)?.hip?.x ?? f.x;
    const ha = hip(a), hb = hip(b), dir = b.x >= a.x ? 1 : -1;
    const min = STAGE.half * 2, gap = Math.min(Math.abs(b.x - a.x), (hb - ha) * dir);
    if (gap >= min) return;
    const push = (min - gap) / 2;
    let ax = a.x - dir * push, bx = b.x + dir * push;
    if (ax < STAGE.minX) { bx += STAGE.minX - ax; ax = STAGE.minX; }
    if (ax > STAGE.maxX) { bx -= ax - STAGE.maxX; ax = STAGE.maxX; }
    if (bx < STAGE.minX) { ax += STAGE.minX - bx; bx = STAGE.minX; }
    if (bx > STAGE.maxX) { ax -= bx - STAGE.maxX; bx = STAGE.maxX; }
    a.x = ax; b.x = bx;
  }

  face() {
    for (const f of this.fighters) {
      const o = this.other(f);
      if (['idle', 'walk', 'guard', 'crouch'].includes(f.state) && Math.abs(o.x - f.x) > 1) f.facing = o.x > f.x ? 1 : -1;
    }
  }

  // Estado mínimo para depuração e testes de navegador.
  snapshot() {
    return {
      clock: this.clock, hitstop: this.hitstop, result: this.result, message: this.message, lastHit: this.lastHit,
      fighters: this.fighters.map(f => ({ id: f.id, x: f.x, facing: f.facing, state: f.state, rocked: this.isRocked(f), headRecent: f.headRecent, move: f.move, moveT: f.moveT, chain: f.chain,
        condition: { ...f.condition }, balance: f.balance, stamina: f.stamina, clinch: f.clinch && { ...f.clinch }, anim: this.animation(f) })),
    };
  }
}
