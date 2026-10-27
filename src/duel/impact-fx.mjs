// Efeitos de impacto do duelo: faísca no contato, poeira, tremida da câmera,
// clarão no contra-ataque, câmera lenta no nocaute, sangue proporcional ao
// golpe e marcas que acumulam no rosto. Tudo desenhado com retângulos de 1 px,
// sem texturas novas nem shaders, e sem esticar sprites.
// A intensidade vem dos eventos do duelo (força do golpe, região, contra-ataque),
// então o efeito comunica o que a regra decidiu.
const SPARK = { 1: 5, 2: 7, 3: 10 };
const SHAKE = { block: 0.6, 1: 1, 2: 1.7, 3: 2.6, ko: 4 };
const PARRY_COLOR = 0x9fd0ff;

export class ImpactFX {
  constructor(blood) {
    this.blood = blood;
    this.reset();
  }

  reset() {
    this.sparks = [];
    this.dust = [];
    this.shakeT = 0; this.shakeAmp = 0;
    this.flashT = 0; this.flashAlpha = 0;
    this.slowT = 0;
    this.clock = 0;
    this.lastId = 0;
    this.dripAt = {};
  }

  // Velocidade da simulação: nocaute desacelera por um instante.
  timeScale() { return this.slowT > 0 ? 0.35 : 1; }

  shake(amp, ms) { if (amp >= this.shakeAmp || this.shakeT <= 0) { this.shakeAmp = amp; this.shakeT = ms; } }

  // Lê só os eventos novos do duelo.
  consume(duel) {
    for (const e of duel.events) if (e.id > this.lastId) { this.lastId = e.id; this.onEvent(e, duel); }
  }

  // `e.ground`: linha do chão de quem apanhou (o corredor não usa 150).
  onEvent(e, duel) {
    const ground = e.ground ?? 150;
    if (e.type === 'hit' && e.point) {
      const target = duel.byId(e.target), dir = target ? -target.facing : 1;
      const power = e.kind === 'ko' ? 3 : e.power || 1;
      this.burst(e.point, power, e.counter, dir);
      this.shake(e.kind === 'ko' ? SHAKE.ko : SHAKE[power], e.kind === 'ko' ? 320 : 90 + power * 50);
      if (e.counter || e.kind === 'ko') { this.flashT = e.kind === 'ko' ? 90 : 50; this.flashAlpha = e.kind === 'ko' ? 0.45 : 0.25; }
      if (e.kind === 'ko') this.slowT = 650;
      // Sangue: cabeça sangra mais; tronco só em golpe forte; perna quase nada.
      const zone = e.zone === 'head' ? 3 : e.zone === 'body' ? (power >= 2 ? 1.2 : 0.4) : 0.5;
      const scale = zone * (e.counter ? 1.5 : 1) * (power >= 3 ? 1.5 : 1) * (e.kind === 'ko' ? 2.5 : 1);
      if (scale > 0) this.blood.emit({ id: e.id, blood: true, blocked: false, zone: e.zone, point: e.point, finisher: e.kind === 'ko', dir }, ground, scale);
      // Suor e saliva claros num golpe de cabeça, separados do sangue.
      if (e.zone === 'head') for (let i = 0; i < 3 + power; i++) this.dust.push({ x: e.point.x, y: e.point.y, vx: dir * (20 + i * 9), vy: -18 + i * 6, life: 240, color: 0xd9d6c3, g: 160 });
    } else if ((e.type === 'block' && e.kind === 'parry' || e.type === 'parry') && e.point) {
      // Aparo: faísca fria com anel e clarão curto — diferente da defesa comum.
      this.burst(e.point, 2, false, 1, PARRY_COLOR);
      this.sparks.push({ x: e.point.x, y: e.point.y, life: 200, max: 200, ring: true, color: PARRY_COLOR, len: 0 });
      this.flashT = 60; this.flashAlpha = 0.3;
      this.shake(SHAKE[2], 130);
    } else if (e.type === 'block' && e.point) {
      this.burst(e.point, 1, false, 1, 0xaecb8c);
      this.shake(SHAKE.block, 70);
    } else if (e.type === 'land') {
      this.puff(e.x, ground, e.ko ? 14 : 10, 1);
      this.shake(e.ko ? 2.4 : 1.6, 140);
    } else if (e.type === 'brake') {
      const f = duel.byId(e.fighter);
      this.puff(e.x + (f?.facing || 1) * 10, ground, 6, f?.facing || 1);
    } else if (e.type === 'dash') {
      const f = duel.byId(e.fighter);
      this.puff(e.x - (f?.facing || 1) * 8, ground, 5, -(f?.facing || 1));
    }
  }

  // Faísca radial; o contra-ataque ganha um anel.
  burst(p, power, counter, dir, color = 0xf0d9a0) {
    const n = SPARK[power] + (counter ? 4 : 0), len = 2 + power * 1.5;
    for (let i = 0; i < n; i++) {
      const a = (i / n) * Math.PI * 2 + (dir < 0 ? Math.PI : 0) * 0.15;
      this.sparks.push({ x: p.x, y: p.y, dx: Math.cos(a), dy: Math.sin(a), len: len * (i % 2 ? 0.6 : 1), life: 80 + power * 30, max: 80 + power * 30, color: counter ? 0xf0a060 : color, ring: false });
    }
    if (counter || power >= 3) this.sparks.push({ x: p.x, y: p.y, life: 140, max: 140, ring: true, color: counter ? 0xf0a060 : 0xe8dcc0, len: 0 });
  }

  puff(x, y, n, dir) {
    n = Math.round(n * 1.5);
    for (let i = 0; i < n; i++) this.dust.push({ x: x + ((i * 7) % 9) - 4, y: y - 1, vx: dir * (6 + (i * 11) % 22) * (i % 2 ? 1 : -0.5), vy: -6 - (i * 5) % 14, life: 380 + (i * 37) % 220, color: i % 3 ? 0xb9b49a : 0x8f8c78, g: 18, size: i % 2 ? 2 : 1 });
  }

  // Tempo real (não acompanha a câmera lenta): os efeitos continuam legíveis.
  step(ms, duel) {
    const s = Math.min(ms, 50) / 1000;
    this.clock += ms;
    this.shakeT = Math.max(0, this.shakeT - ms);
    this.flashT = Math.max(0, this.flashT - ms);
    this.slowT = Math.max(0, this.slowT - ms);
    for (const k of this.sparks) k.life -= ms;
    this.sparks = this.sparks.filter(k => k.life > 0);
    for (const d of this.dust) { d.x += d.vx * s; d.y += d.vy * s; d.vy += d.g * s; d.vx *= Math.exp(-3 * s); d.life -= ms; }
    this.dust = this.dust.filter(d => d.life > 0).slice(-80);
    // Rosto castigado pinga, mais rápido quanto pior a cabeça.
    if (duel && this.blood.enabled) for (const f of duel.fighters) {
      if (f.condition.head < 45 || ['knockdown', 'down', 'ko'].includes(f.state)) continue;
      const every = 1100 - f.condition.head * 7, next = this.dripAt[f.id] ?? this.clock + every;
      if (this.clock >= next) {
        const face = this.face(duel, f);
        if (face) this.blood.drip(face.x, face.y + 4, f.y);
        this.dripAt[f.id] = this.clock + every;
      } else this.dripAt[f.id] = next;
    }
  }

  // Ponto do rosto: frente da cabeça, pelo marcador do quadro atual.
  face(duel, f) {
    const w = duel.markersOf(f);
    if (!w?.head) return null;
    return { x: w.head.x + f.facing * Math.max(3, w.headR * 0.5), y: (w.chin ?? w.head.y + 6) - 3 };
  }

  // Deslocamento da câmera, determinístico pelo relógio.
  offset() {
    if (this.shakeT <= 0) return { x: 0, y: 0 };
    const k = this.shakeAmp * Math.min(1, this.shakeT / 120);
    return { x: Math.round(Math.sin(this.clock * 0.9) * k), y: Math.round(Math.cos(this.clock * 1.3) * k * 0.6) };
  }

  render(g) {
    for (const k of this.sparks) {
      const t = k.life / k.max;
      g.lineStyle(1, k.color, Math.min(1, t * 1.6));
      if (k.ring) { g.strokeCircle(k.x, k.y, 3 + (1 - t) * 8); continue; }
      const r0 = 2 + (1 - t) * 3, r1 = r0 + k.len;
      g.lineBetween(k.x + k.dx * r0, k.y + k.dy * r0, k.x + k.dx * r1, k.y + k.dy * r1);
    }
    for (const d of this.dust) { g.fillStyle(d.color, Math.min(0.85, d.life / 300)); g.fillRect(Math.round(d.x), Math.round(d.y), d.size || 1, d.size || 1); }
  }

  // Marcas no rosto: aparecem conforme o castigo da cabeça e acompanham o quadro.
  renderWounds(g, duel) {
    if (!this.blood.enabled) return;
    for (const f of duel.fighters) {
      const level = Math.min(5, Math.floor(f.condition.head / 18));
      if (!level || ['knockdown', 'down', 'ko', 'getup'].includes(f.state)) continue;
      const face = this.face(duel, f);
      if (!face) continue;
      const spots = [[0, 0], [-2, -4], [1, 2], [-3, 1], [-1, -6]];
      for (let i = 0; i < level; i++) {
        g.fillStyle(i % 2 ? 0x7f2425 : 0xa33a33);
        g.fillRect(Math.round(face.x + spots[i][0] * f.facing), Math.round(face.y + spots[i][1]), i === 0 ? 2 : 1, i === 0 ? 3 : i === 2 ? 2 : 1);
      }
    }
  }

  renderFlash(g) {
    if (this.flashT <= 0) return;
    g.fillStyle(0xf3ead2, this.flashAlpha * (this.flashT / 90));
    g.fillRect(0, 0, 320, 180);
  }
}
