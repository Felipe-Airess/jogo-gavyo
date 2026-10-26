// Duelo lateral 1×1 sem profundidade jogável. Os dois lutadores passam pelas
// mesmas funções: entrada → buffer → estado → golpe → contato → dano.
import { commandFrom } from '../core/command-buffer.mjs';
import { createFighter, animationRef, NEUTRAL, SPEED } from './fighter.mjs';
import { createDuelMoves, chooseMove, cancelTarget, frameIndex, MAX_CHAIN } from './moves.mjs';
import { MarkerSet, worldMarkers, hurtboxes, guardBox, grabBox, LIMB_SIZE } from './markers.mjs';
import { sweep, contactPoint, overlap } from './collision.mjs';
import { resolveHit, applyHit } from './damage.mjs';
import { startClinch, endClinch, keepGap, escapeGain, CLINCH } from './clinch.mjs';

export const STAGE = { minX: 24, maxX: 456, ground: 150, half: 8 };
export const TICK = 1000 / 60;
export const HITSTOP = { block: 50, light: 66, medium: 83, heavy: 116 };
const DOWN = new Set(['knockdown', 'down', 'getup', 'ko']);
const CLINCH_STATES = new Set(['clinchEntry', 'clinch', 'clinchStrike', 'held']);
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const approach = (v, t, a) => v + clamp(t - v, -a, a);

export class Duel {
  constructor({ clips, markers, characters = ['sorriso', 'sorriso'] }) {
    this.clips = clips;
    this.markers = markers instanceof MarkerSet ? markers : new MarkerSet(markers);
    this.moves = createDuelMoves(clips);
    this.characters = characters;
    this.reach = this.measureReach();
    this.reset();
  }

  reset() {
    const [a, b] = this.characters;
    this.fighters = [createFighter(1, a, 200, 1, this.clips), createFighter(2, b, 280, -1, this.clips)];
    this.clock = 0;
    this.hitstop = 0;
    this.events = [];
    this.eventId = 0;
    this.lastHit = null;
    this.result = null;
    this.message = 'Controle a distância. Golpe errado custa caro.';
  }

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
  measureReach() {
    const out = {};
    for (const m of Object.values(this.moves)) {
      let best = 0;
      for (const frame of m.active) {
        const mk = this.markers.frame(m.clip, frame);
        const tip = m.limb === 'foot' ? mk?.frontFoot : m.limb === 'knee' ? mk?.frontKnee : mk?.frontFist;
        if (tip) best = Math.max(best, tip.tipX ?? tip.x);
      }
      out[m.id] = best;
    }
    return out;
  }

  animation(f) { return animationRef(f, this.moves, this.clips); }
  markersOf(f) { const ref = this.animation(f); return worldMarkers(this.markers.frame(ref.clip, ref.frame), f); }
  hurtboxesOf(f) { return DOWN.has(f.state) ? {} : hurtboxes(this.markersOf(f)); }

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

  setState(f, state) { if (f.state !== state) { f.state = state; f.t = 0; } }
  toIdle(f) { f.state = 'idle'; f.t = 0; f.move = null; f.chain = 0; f.vx *= 0.3; }

  regen(f, s) {
    const busy = f.state === 'attack' || CLINCH_STATES.has(f.state);
    const stunned = ['hitstun', 'blockstun', 'knockdown', 'down', 'ko', 'collapse'].includes(f.state);
    if (!stunned) f.balance = Math.min(100, f.balance + (busy ? 12 : 30) * s);
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
      case 'whiff': if (f.t >= this.moves[f.move].whiff.times.reduce((a, b) => a + b, 0)) this.toIdle(f); return;
      case 'hitstun':
      case 'blockstun':
        this.slide(f, s, 10);
        if (f.t >= f.stun) this.toIdle(f);
        return;
      case 'knockdown': this.slide(f, s, 5); if (f.t >= 450) this.setState(f, 'down'); return;
      case 'ko': this.slide(f, s, 5); return;
      case 'down': if (f.t >= 700) this.setState(f, 'getup'); return;
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
    if (input.guard && f.can.guard) { this.setState(f, 'guard'); f.vx = approach(f.vx, 0, 600 * s); this.slide(f, s, 0); return; }
    if (input.down && f.can.crouch) { this.setState(f, 'crouch'); f.vx = 0; return; }
    if (f.state === 'crouch') { this.setState(f, 'rise'); return; }
    const dir = Number(!!input.right) - Number(!!input.left), rel = dir * f.facing;
    const legs = 1 - f.condition.legs / 250;
    const running = input.run && rel > 0 && f.can.run && f.stamina > 5;
    const speed = running ? SPEED.run : rel > 0 ? SPEED.forward * legs : rel < 0 ? -SPEED.back * legs : 0;
    if (!f.can.walk && !running) { f.vx = 0; this.setState(f, f.state === 'guard' ? 'idle' : f.state); return; }
    f.vx = approach(f.vx, speed * f.facing, 520 * s);
    const before = f.x;
    f.x = clamp(f.x + f.vx * s, STAGE.minX, STAGE.maxX);
    const moved = (f.x - before) * f.facing;
    if (running) { if (f.state !== 'run') { f.state = 'run'; f.t = 0; } f.runDistance += Math.abs(moved); }
    else if (Math.abs(f.vx) > 2) { this.setState(f, 'walk'); f.gait += moved; }
    else this.setState(f, 'idle');
  }

  act(f, o, cmd) {
    if (cmd.kind === 'grab') return this.tryGrab(f, o);
    if (!f.can.attack) return false;
    return this.begin(f, chooseMove(cmd, f), false);
  }

  begin(f, id, chained) {
    const m = this.moves[id];
    if (!m) return false;
    if (f.stamina < m.cost * 0.5) { this.event('winded', { fighter: f.id }); if (f === this.player) this.message = 'Sem fôlego para esse golpe.'; return false; }
    f.stamina = Math.max(0, f.stamina - m.cost);
    f.moveFrom = chained ? f.move : null;
    f.chain = chained ? f.chain + 1 : 1;
    f.state = 'attack'; f.t = 0; f.move = id; f.moveT = 0;
    f.connected = false; f.hitDone = false; f.prevTip = null;
    // Socos do lote 3 mantêm o pé de trás plantado no pivô: sem avanço extra
    // (avançar o sprite faria o pé deslizar). Só o soco de impulso conserva a corrida.
    if (!m.carry) f.vx *= 0.2;
    this.event('attack', { fighter: f.id, move: id, chained });
    return true;
  }

  updateAttack(f, dt) {
    const s = dt / 1000, m = this.moves[f.move];
    f.moveT += dt;
    if (m.carry) { f.vx = approach(f.vx, 0, m.carry * 2 * s); this.slide(f, s, 0); }
    else { f.vx = approach(f.vx, 0, 400 * s); this.slide(f, s, 0); }
    const cmd = f.buffer.peek(this.clock);
    if (cmd && cmd.kind !== 'grab' && f.connected && f.chain < MAX_CHAIN && f.moveT >= m.cancelStart && f.moveT <= m.cancelEnd) {
      const next = cancelTarget(m, cmd, f);
      if (next && this.begin(f, next, true)) { f.buffer.clear(); return; }
    }
    if (f.moveT >= m.duration) {
      if (!f.connected && m.whiff) { f.state = 'whiff'; f.t = 0; this.event('whiff', { fighter: f.id, move: m.id }); return; }
      this.toIdle(f);
    }
  }

  // Contato do golpe atual contra o outro lutador, com varredura do membro.
  probe(a, d) {
    if (a.state !== 'attack' && a.state !== 'clinchStrike') return null;
    const m = this.moves[a.move], frame = m.frames[frameIndex(m, a.moveT)];
    const w = worldMarkers(this.markers.frame(m.clip, frame), a), tip = w?.[m.limb];
    const active = m.active.includes(frame);
    if (!tip) { if (active) this.markers.note(m.clip, frame, m.limb); a.prevTip = null; return null; }
    const from = a.prevTip || tip;
    a.prevTip = tip;
    if (!active || a.hitDone || DOWN.has(d.state)) return null;
    if (!!m.clinch !== (a.state === 'clinchStrike')) return null;
    if (d.state === 'held' && d.clinch?.partner !== a.id) return null;
    const boxes = this.hurtboxesOf(d), [hw, hh] = LIMB_SIZE[m.limb].map(v => v / 2);
    let best = null;
    const legsOnly = m.targets.length === 1 && m.targets[0] === 'legs';
    // Chute na perna mira a coxa: a caixa sobe um pouco acima da linha da calça.
    const zoneBox = zone => legsOnly && boxes.legs ? { ...boxes.legs, y: boxes.legs.y - 8, h: boxes.legs.h + 8 } : boxes[zone];
    // Primeiro, onde o membro está agora (maior sobreposição). A varredura em
    // linha reta só entra quando o membro passou inteiro entre dois ticks:
    // num chute circular a reta entre a perna dobrada e a estendida cortaria o
    // tronco, embora o pé desenhado chegue na cabeça.
    const limb = { x: tip.x - hw, y: tip.y - hh, w: hw * 2, h: hh * 2 };
    for (const zone of m.targets) {
      const box = zoneBox(zone);
      if (!box || !overlap(limb, box)) continue;
      const area = (Math.min(limb.x + limb.w, box.x + box.w) - Math.max(limb.x, box.x)) * (Math.min(limb.y + limb.h, box.y + box.h) - Math.max(limb.y, box.y));
      if (!best || area > best.area) best = { zone, t: 1, area, box };
    }
    if (!best) for (const zone of m.targets) {
      const box = zoneBox(zone);
      const t = box && sweep(from, tip, hw, hh, box);
      if (t !== null && t !== undefined && (!best || t < best.t)) best = { zone, t, box };
    }
    const front = (a.x - d.x) * d.facing > 0;
    if ((d.state === 'guard' || d.state === 'blockstun') && front && !legsOnly) {
      const g = guardBox(d, this.markersOf(d)), tg = g ? sweep(from, tip, hw, hh, g) : null;
      // A guarda alta cobre cabeça e tronco; a perna continua exposta.
      if ((tg !== null && (!best || tg <= best.t)) || (best && best.zone !== 'legs')) {
        return { a, d, m, blocked: true, zone: 'arms', point: tg !== null ? contactPoint(from, tip, tg, g) : contactPoint(from, tip, best.t, best.box) };
      }
    }
    if (!best) return null;
    return { a, d, m, blocked: false, zone: best.zone, point: contactPoint(from, tip, best.t, best.box) };
  }

  applyContact({ a, d, m, blocked, zone, point }) {
    a.hitDone = true;
    a.connected = true;
    const dm = d.state === 'attack' ? this.moves[d.move] : null;
    const counter = !blocked && !!dm && d.moveT < dm.activeEnd;
    const r = resolveHit(m, d, zone, { blocked, counter });
    applyHit(d, r);
    this.hitstop = blocked ? HITSTOP.block : r.kind !== 'hit' || m.power >= 3 ? HITSTOP.heavy : m.power === 2 ? HITSTOP.medium : HITSTOP.light;
    this.lastHit = { at: this.clock, attacker: a.id, target: d.id, move: m.id, zone: r.zone, kind: r.kind, damage: r.damage, counter, blocked, point };
    this.event(r.kind === 'block' ? 'block' : 'hit', { attacker: a.id, target: d.id, move: m.id, zone: r.zone, kind: r.kind, counter, heavy: m.power >= 3 });
    if (r.reason) this.message = r.reason;
    else if (counter) this.message = 'Contra-ataque: ' + m.name + '.';
    else this.message = blocked ? 'Defendido.' : m.name + (zone === 'head' ? ' na cabeça.' : zone === 'body' ? ' no tronco.' : ' na perna.');
    const pushV = a.facing * r.push * 10;
    if (a.clinch && d.clinch && r.kind === 'hit') { a.clinch.grip = Math.min(CLINCH.maxGrip, a.clinch.grip + CLINCH.refresh); return; }
    if (d.clinch) endClinch(this.byId(d.clinch.partner), d);
    d.buffer.clear();
    d.move = null;
    d.stun = r.stun;
    d.reaction = r.zone;
    if (r.kind === 'block') { d.state = 'blockstun'; d.t = 0; d.vx = pushV; }
    else if (r.kind === 'guardBreak') { d.state = 'hitstun'; d.t = 0; d.reaction = 'body'; d.vx = pushV; }
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
    const g = grabBox(f, this.markersOf(f)), body = this.hurtboxesOf(o).body;
    const blocked = DOWN.has(o.state) || o.clinch || o.state === 'attack' || o.state === 'collapse';
    if (!overlap(g, body) || blocked) {
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
      const id = cmd.kind === 'kick' ? 'knee' : 'clinchPunch', m = this.moves[id];
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
    const m = this.moves[f.move];
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
    if (DOWN.has(a.state) || DOWN.has(b.state) || a.clinch || b.clinch) return;
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
      fighters: this.fighters.map(f => ({ id: f.id, x: f.x, facing: f.facing, state: f.state, move: f.move, moveT: f.moveT, chain: f.chain,
        condition: { ...f.condition }, balance: f.balance, stamina: f.stamina, clinch: f.clinch && { ...f.clinch }, anim: this.animation(f) })),
    };
  }
}
