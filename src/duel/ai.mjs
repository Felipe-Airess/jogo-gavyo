// IA do duelo. Produz a mesma entrada que o teclado produziria e passa pelas
// mesmas regras do jogador. Só enxerga o que está na tela: posição, estado e há
// quanto tempo o golpe do adversário está visível — nunca o comando dele.
// Reage com atraso (tempo de reação), espaça os próprios ataques e só age
// quando o próprio corpo está livre.
import { NEUTRAL } from './fighter.mjs';

export const AI_LEVELS = {
  // reaction: ms até perceber um golpe; guard: chance de defender o que percebeu;
  // parry: chance de a defesa ser um aparo de propósito (o resto é guarda comum,
  // sem aparo acidental pelo tempo de reação).
  calmo: { reaction: 230, guard: 0.45, parry: 0.1, throw: 0.2, punish: 0.5, think: [260, 420], rest: [900, 1500] },
  firme: { reaction: 180, guard: 0.7, parry: 0.2, throw: 0.35, punish: 0.75, think: [180, 320], rest: [650, 1200] },
};

export class DuelAI {
  constructor(seed = 29, level = 'firme') {
    this.seed = seed;
    this.level = AI_LEVELS[level] || AI_LEVELS.firme;
    this.reset();
  }

  reset() {
    this.state = this.seed >>> 0;
    this.thinkAt = 0;
    this.attackAt = 900;
    this.guardUntil = 0;
    this.decided = null;
    this.mashAt = 0;
    this.walk = 0;
    this.plan = null;
    this.punishing = undefined;
  }

  random() {
    this.state = (Math.imul(this.state, 1664525) + 1013904223) >>> 0;
    return this.state / 4294967296;
  }

  range([a, b]) { return a + (b - a) * this.random(); }

  input(duel, me, foe) {
    const out = {}, now = duel.clock, L = this.level;
    const toward = fwd => (me.facing > 0) === fwd ? 'right' : 'left';
    const dist = Math.abs(foe.x - me.x);
    if (me.state === 'held') {
      if (now >= this.mashAt) { out.attack = true; this.mashAt = now + this.range([170, 260]); }
      out[toward(false)] = true;
      return out;
    }
    if (me.state === 'clinch') {
      if (now >= this.thinkAt) {
        this.thinkAt = now + this.range([380, 560]);
        if (me.stamina < 18) out.grab = true;
        else if (this.random() < 0.65) out.kick = true;
        else out.attack = true;
      }
      return out;
    }
    if (this.follow && now >= this.follow) {
      this.follow = 0;
      if (me.state === 'attack') {
        // Sequência que entrou e o outro está atordoado: às vezes agarra e arremessa.
        if (me.connected && me.chain >= 2 && foe.state === 'hitstun' && this.random() < L.throw) { out.grab = true; return out; }
        out.attack = true; out[toward(true)] = true;
        if (me.chain < 2 && this.random() < 0.5) this.follow = now + 240;
        return out;
      }
    }
    // Adversário no chão: chega perto e bate.
    if ((foe.state === 'down' || foe.state === 'knockdown') && NEUTRAL.has(me.state)) {
      const dx = (foe.x - me.x) * me.facing;
      if (dx > 0 && dx <= 40) {
        if (now >= this.thinkAt) { this.thinkAt = now + this.range([200, 340]); out[this.random() < 0.5 ? 'attack' : 'kick'] = true; }
        return out;
      }
      out[toward(true)] = true;
      return out;
    }
    if (!NEUTRAL.has(me.state) && me.state !== 'rise') return out;
    // Aparou: contra-ataca na janela.
    if (now < me.parryUntil) { out.attack = true; return out; }

    // Defesa: só depois de o golpe estar visível pelo tempo de reação.
    const fm = foe.state === 'attack' ? duel.moveOf(foe) : null;
    if (fm) {
      const key = foe.move + ':' + Math.round((now - foe.moveT) / 10);
      const threat = dist < (duel.reachOf(foe)[foe.move] || 30) + 18 && foe.moveT < fm.activeEnd;
      if (threat && foe.moveT >= L.reaction && this.decided !== key) {
        this.decided = key;
        if (this.random() < L.guard) { this.guardUntil = now + (fm.activeEnd - foe.moveT) + 60; this.steady = this.random() >= L.parry; }
      }
    }
    if (now < this.guardUntil) { out.guard = true; out.steady = this.steady; return out; }

    // Punição: adversário preso na recuperação de um golpe que errou.
    // Também depois de defender: um golpe bloqueado ainda tem recuperação a pagar.
    const blockedByMe = duel.lastHit?.blocked && duel.lastHit.target === me.id && duel.lastHit.attacker === foe.id;
    const exposed = foe.state === 'whiff' || foe.state === 'grabMiss' || foe.state === 'parried' ||
      (fm && foe.moveT > fm.activeEnd && (!foe.connected || blockedByMe));
    const reach = (duel.reachOf(me).cross || 40) + 6;
    if (exposed && dist <= reach + 30) {
      if (this.punishing === undefined || this.punishing < now - 1500) this.punishing = this.random() < L.punish ? now : -1e9;
      if (this.punishing >= now - 1500) {
        // Encurta a distância andando e só então bate: nada de golpe no vazio.
        if (dist > reach) { out[toward(true)] = true; return out; }
        out.attack = true;
        out[toward(true)] = true;
        this.punishing = -1e9;
        this.attackAt = now + this.range(L.rest);
        return out;
      }
    }

    if (now >= this.thinkAt) {
      this.thinkAt = now + this.range(L.think);
      const tired = me.stamina < 25;
      const desired = tired ? 74 : 50 + this.range([-6, 6]);
      this.walk = dist > desired + 6 ? 1 : dist < desired - 8 ? -1 : 0;
      this.plan = null;
      if (!tired && now >= this.attackAt) {
        // Golpe conforme o alcance de CADA golpe, medido nos marcadores de
        // contato do próprio personagem (o comando vira o golpe que ele tem).
        // Antes o jab no corpo usava o alcance do jab e o chute baixo o do
        // direto: o Miguel errava ~70% deles.
        const options = [];
        if (dist < 28) options.push({ grab: true });
        const reach = duel.reachOf(me), moves = duel.movesOf(me);
        const COMMANDS = [{ attack: true }, { attack: true, down: true }, { attack: true, forward: true }, { attack: true, back: true },
          { attack: true, up: true }, { kick: true }, { kick: true, down: true }];
        // Especiais (combos desenhados) raros: só perto e com fôlego.
        if (me.stamina > 45 && this.random() < 0.25) COMMANDS.push({ attack: true, run: true, down: true }, { kick: true, run: true }, { kick: true, run: true, forward: true });
        for (const c of COMMANDS) {
          const id = duel.commandMove(me, c);
          if (!id || !moves[id] || moves[id].ground || moves[id].throw) continue;
          if (options.some(o => o.id === id)) continue;
          const r = reach[id] ?? 30;
          if (dist <= r + 12) options.push({ ...c, id });
        }
        if (options.length) {
          this.plan = options[Math.floor(this.random() * options.length)];
          this.attackAt = now + this.range(L.rest);
          // Às vezes emenda um segundo comando, que só sai se o primeiro tocar.
          this.follow = this.plan.attack && !this.plan.forward && this.random() < 0.4 ? now + 260 : 0;
        } else this.walk = 1;
      }
    }
    if (this.plan) {
      const p = this.plan;
      this.plan = null;
      if (p.grab) out.grab = true;
      if (p.attack) out.attack = true;
      if (p.kick) out.kick = true;
      if (p.down) out.down = true;
      if (p.up) out.up = true;
      if (p.run) out.run = true;
      if (p.forward) out[toward(true)] = true;
      if (p.back) out[toward(false)] = true;
      return out;
    }
    if (this.walk) out[toward(this.walk > 0)] = true;
    return out;
  }
}
