// Cena do duelo 1×1. Só desenha: as regras ficam em duel.mjs.
// Canvas, 320×180, nearest-neighbor — o mesmo perfil leve do corredor.
import { Duel, STAGE } from './duel.mjs';
import { DuelAI } from './ai.mjs';
import { FixedStep, lerp } from '../core/fixed-step.mjs';
import { hurtboxes, pushbox, guardBox, grabBox, LIMB_SIZE, limbCenter } from './markers.mjs';
import { frameIndex } from './moves.mjs';
import { lettering } from '../art.js';
import { SORRISO_ASSET } from '../assets.js';
import { Blood } from '../blood.mjs';
import { ImpactFX } from './impact-fx.mjs';

const WORLD_X = -80; // o corredor de 640 px fica centrado no palco
const COLORS = { head: 0xd5ba79, body: 0x88bdc0, legs: 0x7f95c9, hit: 0xe36f5a, push: 0x9cad8a, guard: 0xb9cc8c, grab: 0xd59a4f, point: 0xf2efd2 };

// Paleta do rival: camisa clara vira grafite e verde vira vinho. Pele, cabelo
// e calça ficam iguais. É o mesmo personagem em outra roupa, não um novo lutador.
function recolor(data) {
  for (let i = 0; i < data.length; i += 4) {
    const r = data[i], g = data[i + 1], b = data[i + 2];
    if (data[i + 3] < 8) continue;
    const mx = Math.max(r, g, b), mn = Math.min(r, g, b);
    if (mn > 150 && mx - mn < 50) { const v = mx * 0.42; data[i] = v * 0.95; data[i + 1] = v; data[i + 2] = v * 1.12; }
    else if (g > r + 18 && g > b + 10) { data[i] = g * 0.75; data[i + 1] = r * 0.45; data[i + 2] = b * 0.5; }
  }
}

export class DuelScene extends Phaser.Scene {
  constructor() { super('Duel'); this.mode = 'title'; this.debugVisible = false; this.hudClock = 0; this.rivalFrames = new Set(); }

  preload() { if (!this.cache.json.get('sorriso-markers')) this.load.json('sorriso-markers', 'assets/sorriso-markers.json'); }

  create() {
    const ui = this.registry.get('ui');
    this.ui = ui;
    this.clips = Object.fromEntries(this.cache.json.get('sorriso-data').clips.map(c => [c.id, c]));
    this.model = new Duel({ clips: this.clips, markers: this.cache.json.get('sorriso-markers') });
    this.ai = new DuelAI(41);
    this.stepper = new FixedStep(60);
    this.touch = this.registry.get('touch');
    this.audio = this.registry.get('audio');
    this.add.image(WORLD_X, 0, 'hallway').setOrigin(0);
    // Manchas no chão ficam por toda a luta; gotas e faíscas passam por cima dos lutadores.
    this.blood = new Blood({ particles: 220, marks: 140, markLife: 1e9, palette: { drop: 0xb2302b, mark: 0x6e1d1b } });
    this.fx = new ImpactFX(this.blood);
    this.floor = this.add.graphics().setDepth(100);
    this.flash = this.add.graphics().setDepth(760).setScrollFactor(0);
    this.views = this.model.fighters.map(() => ({
      shadow: this.add.ellipse(0, STAGE.ground, 25, 4, 0x172723, 0.6),
      image: this.add.image(0, 0, 'sorriso-sheet', 0).setOrigin(SORRISO_ASSET.originX, SORRISO_ASSET.originY),
    }));
    this.effects = this.add.graphics().setDepth(700);
    this.debugLayer = this.add.graphics().setDepth(720);
    // Sem setBounds: o alvo da câmera já é limitado e a tremida precisa sair do eixo.
    this.cameras.main.roundPixels = true;
    this.cameraX = 80;
    this.hud = this.canvasImage('duel-hud', 320, 28, 0, 0, 800);
    this.note = this.canvasImage('duel-note', 320, 11, 0, 169, 800);
    this.overlay = this.canvasImage('duel-overlay', 320, 180, 0, 0, 900);
    this.keys = this.input.keyboard.addKeys('W,A,S,D,UP,DOWN,LEFT,RIGHT,SHIFT,J,K,G,L');
    this.pressed = new Set();
    this.input.keyboard.on('keydown', e => { if (!e.repeat) this.pressed.add(e.code); });
    this.game.events.on('blur', () => { if (this.scene.isActive() && this.mode === 'playing') this.changeMode('paused'); });
    this.events.on('wake', () => { this.changeMode(this.mode === 'playing' ? 'paused' : this.mode); this.render(0); });
    this.render(0);
  }

  canvasImage(key, w, h, x, y, depth) {
    const texture = this.textures.exists(key) ? this.textures.get(key) : this.textures.createCanvas(key, w, h);
    this.add.image(x, y, key).setOrigin(0).setDepth(depth).setScrollFactor(0);
    return texture;
  }

  // Quadro recolorido sob demanda: só os quadros realmente exibidos ocupam memória.
  rivalFrame(index) {
    const key = 'rival-' + index;
    if (!this.rivalFrames.has(key)) {
      const source = this.textures.get('sorriso-sheet').getSourceImage();
      const texture = this.textures.createCanvas(key, 128, 96), ctx = texture.context;
      ctx.drawImage(source, (index % 8) * 128, Math.floor(index / 8) * 96, 128, 96, 0, 0, 128, 96);
      const pixels = ctx.getImageData(0, 0, 128, 96);
      recolor(pixels.data);
      ctx.putImageData(pixels, 0, 0);
      texture.refresh();
      texture.setFilter(Phaser.Textures.FilterMode.NEAREST);
      this.rivalFrames.add(key);
    }
    return key;
  }

  changeMode(mode) {
    if (!this.model) return;
    this.mode = mode;
    this.stepper.reset();
    this.model.clearInputs();
    this.input.keyboard.resetKeys();
    this.pressed.clear();
    this.touch?.clear();
    this.ui.play.textContent = mode === 'playing' ? 'Pausar' : mode === 'title' ? 'Jogar' : mode === 'over' ? 'Revanche' : 'Continuar';
    this.paintOverlay();
  }

  toggle() { if (!this.model) return; this.audio?.unlock(); if (this.mode === 'over') this.restart(); else this.changeMode(this.mode === 'playing' ? 'paused' : 'playing'); }
  restart() { if (!this.model) return; this.model.reset(); this.ai.reset(); this.fx.reset(); this.blood.reset(); this.cameraX = 80; this.changeMode('playing'); this.render(0); }
  setDebug(on) { this.debugVisible = on; }

  readInput(pressed) {
    const t = this.touch?.read() || {}, k = this.keys;
    return {
      left: t.left || k.A.isDown || k.LEFT.isDown, right: t.right || k.D.isDown || k.RIGHT.isDown,
      up: t.up || k.W.isDown || k.UP.isDown, down: t.down || k.S.isDown || k.DOWN.isDown,
      run: t.run || k.SHIFT.isDown, guard: t.guard || k.L.isDown,
      attack: t.attack || pressed.has('KeyJ'), kick: t.kick || pressed.has('KeyK'), grab: t.grab || pressed.has('KeyG'),
    };
  }

  update(time, delta) {
    const pressed = this.pressed;
    this.pressed = new Set();
    if (pressed.has('F2')) { this.debugVisible = !this.debugVisible; this.ui.debug.setAttribute('aria-pressed', String(this.debugVisible)); }
    if (pressed.has('KeyR')) this.restart();
    if (pressed.has('KeyB')) document.getElementById('blood')?.click();
    this.blood.enabled = document.getElementById('blood')?.getAttribute('aria-pressed') !== 'false';
    if ((pressed.has('Enter') && !['BUTTON', 'SELECT'].includes(document.activeElement?.tagName)) || pressed.has('Escape')) this.toggle();
    if (this.mode === 'playing') {
      const input = this.readInput(pressed), m = this.model;
      // Câmera lenta do nocaute: menos tempo de jogo por quadro, mesmo passo fixo.
      this.stepper.advance(delta * this.fx.timeScale(), input, (sample, dt) => m.tick([sample, this.ai.input(m, m.rival, m.player)], dt));
      this.fx.consume(m);
      this.fx.step(delta, m);
      this.blood.step(delta * this.fx.timeScale());
      this.playAudio();
      if (m.result && this.mode !== 'over' && m.clock - m.result.at > 900) this.changeMode('over');
    }
    const status = this.mode === 'paused' ? 'Pausado. Toque em Continuar.' : this.mode === 'title' ? 'Duelo 1×1: toque em Jogar.' : this.model.message;
    if (this.ui.status.textContent !== status) this.ui.status.textContent = status;
    this.render(delta);
    this.hudClock += delta;
    if (this.hudClock >= 90) { this.paintHud(); this.hudClock = 0; }
  }

  playAudio() {
    const e = [...this.model.events].reverse().find(x => x.type === 'hit' || x.type === 'block');
    if (e && e !== this.lastSound) { this.lastSound = e; this.audio?.play(e.type === 'block' ? 'guard' : 'hit', e.heavy ? 1.2 : 1); }
  }

  render() {
    const m = this.model, alpha = this.mode === 'playing' && m.hitstop <= 0 ? this.stepper.alpha : 1;
    this.effects.clear();
    this.debugLayer.clear();
    this.floor.clear();
    this.flash.clear();
    this.blood.renderMarks(this.floor);
    m.fighters.forEach((f, i) => {
      const view = this.views[i], ref = m.animation(f), frame = this.clips[ref.clip].frames[ref.frame];
      // Interpolação só da posição: a pose continua sendo o quadro desenhado.
      // Interpolação só fora da passada: na locomoção o degrau por quadro já
      // define onde o sprite fica (pé apoiado parado).
      const step = m.drawX(f) - f.x;
      let x = step ? m.drawX(f) : lerp(f.prevX, f.x, alpha);
      if (m.hitstop > 0 && m.lastHit?.target === f.id) x += (Math.floor(m.hitstop / 33) % 2 ? 1 : -1);
      const index = frame.index;
      view.image.setTexture(i === 1 ? this.rivalFrame(index) : 'sorriso-sheet', i === 1 ? undefined : index);
      view.image.setPosition(Math.round(x), f.y).setFlipX(f.facing < 0).setDepth(f.y + (f.state === 'attack' ? 0.6 : 0.4));
      view.shadow.setPosition(Math.round(x), f.y).setDepth(f.y - 1);
      if (this.debugVisible) this.drawDebug(f);
    });
    this.blood.renderParticles(this.effects);
    this.fx.renderWounds(this.effects, m);
    this.fx.render(this.effects);
    this.fx.renderFlash(this.flash);
    const [a, b] = m.fighters, target = Math.max(WORLD_X, Math.min(WORLD_X + 320, (a.x + b.x) / 2 - 160));
    this.cameraX += (target - this.cameraX) * 0.18;
    const shake = this.fx.offset();
    this.cameras.main.scrollX = Math.round(this.cameraX) + shake.x;
    this.cameras.main.scrollY = shake.y;
  }

  drawDebug(f) {
    const m = this.model, g = this.debugLayer, w = m.markersOf(f), boxes = hurtboxes(w, { arms: f.state === 'attack' || f.state === 'clinchStrike' });
    const stroke = (b, color) => { if (b) { g.lineStyle(1, color); g.strokeRect(Math.round(b.x) + 0.5, Math.round(b.y) + 0.5, Math.round(b.w), Math.round(b.h)); } };
    if (!['knockdown', 'down', 'getup', 'ko'].includes(f.state)) for (const [zone, list] of Object.entries(boxes)) for (const b of list) stroke(b, COLORS[zone]);
    stroke(pushbox(f, w), COLORS.push);
    if (f.state === 'guard' || f.state === 'blockstun') stroke(guardBox(f, w), COLORS.guard);
    if (['idle', 'walk', 'clinchEntry'].includes(f.state)) stroke(grabBox(f, w), COLORS.grab);
    if (f.state === 'attack' || f.state === 'clinchStrike') {
      const mv = m.moves[f.move], tip = limbCenter(w?.[mv.limb], mv.limb, f.facing), frame = mv.frames[frameIndex(mv, f.moveT)];
      if (tip) {
        const [bw, bh] = LIMB_SIZE[mv.limb], active = mv.active.includes(frame);
        g.lineStyle(1, active ? COLORS.hit : 0x806050);
        g.strokeRect(Math.round(tip.x - bw / 2) + 0.5, Math.round(tip.y - bh / 2) + 0.5, bw, bh);
        if (active && f.prevTip) g.lineBetween(f.prevTip.x, f.prevTip.y, tip.x, tip.y);
      }
    }
    g.fillStyle(COLORS.point);
    for (const p of [w?.head, w?.hip, w?.fist, w?.rearFist, w?.foot, w?.knee, ...(w?.feet || [])]) if (p) g.fillRect(Math.round(p.x), Math.round(p.y), 1, 1);
  }

  paintHud() {
    const c = this.hud.context, m = this.model;
    c.clearRect(0, 0, 320, 28);
    c.fillStyle = '#142321'; c.fillRect(0, 0, 320, 27);
    c.fillStyle = '#8c956f'; c.fillRect(0, 26, 320, 1);
    m.fighters.forEach((f, i) => {
      const left = i === 0, x0 = left ? 6 : 170;
      lettering(c, left ? 'SORRISO' : 'SORRISO B', x0, 3, left ? '#d8d5b7' : '#c9a7a2');
      const bars = [['C', 100 - f.condition.head, '#cab47a'], ['T', 100 - f.condition.body, '#a3b180'], ['P', 100 - f.condition.legs, '#b39d80'], ['E', f.balance, '#87aeb0'], ['F', f.stamina, '#91a17b']];
      bars.forEach(([label, value, color], j) => {
        const x = x0 + j * 29;
        lettering(c, label, x, 11, color);
        c.fillStyle = '#354438'; c.fillRect(x + 5, 12, 20, 3);
        c.fillStyle = color; c.fillRect(x + 5, 12, Math.round(20 * Math.max(0, value) / 100), 3);
      });
      const action = f.state === 'attack' ? m.moves[f.move].name : f.state === 'held' ? 'PRESO' : f.clinch ? 'CLINCH' : f.state === 'ko' ? 'NOCAUTE' : f.state === 'guard' ? 'GUARDA' : '';
      lettering(c, action.slice(0, 18), x0, 19, '#d1bd85');
      if (f.clinch?.role === 'held') { c.fillStyle = '#c7af71'; c.fillRect(x0 + 80, 20, Math.round(60 * Math.min(1, f.clinch.escape / 100)), 2); }
    });
    lettering(c, 'FPS ' + Math.round(this.game.loop.actualFps || 0), 290, 19, '#82947e');
    this.hud.refresh();
    const n = this.note.context;
    n.clearRect(0, 0, 320, 11); n.fillStyle = '#182922'; n.fillRect(0, 0, 320, 11);
    lettering(n, 'J SOCO  K CHUTE  L GUARDA  G CLINCH  S AGACHAR', 7, 3, '#a3ae90');
    this.note.refresh();
  }

  paintOverlay() {
    const c = this.overlay.context, m = this.model;
    c.clearRect(0, 0, 320, 180);
    if (this.mode !== 'playing') {
      c.fillStyle = 'rgba(12,23,21,.86)'; c.fillRect(0, 28, 320, 141);
      const title = this.mode === 'title' ? 'DUELO 1X1' : this.mode === 'over' ? (m.result?.winner === 1 ? 'VITORIA' : 'DERROTA') : 'PAUSADO';
      lettering(c, title, 28, 60, '#ded8b3', 2);
      const reason = this.mode === 'over' ? (m.result?.reason || '').replace(/[^\w\s:.\-À-ú]/g, '') : this.mode === 'title' ? 'DISTANCIA > ABERTURA > IMPACTO' : 'CONTINUAR PARA VOLTAR';
      const words = reason.split(' '), lines = [''];
      for (const w of words) { if ((lines.at(-1) + ' ' + w).length > 34) lines.push(w); else lines[lines.length - 1] = (lines.at(-1) + ' ' + w).trim(); }
      lines.slice(0, 3).forEach((line, i) => lettering(c, line, 28, 86 + i * 8, '#c1c5a1'));
      lettering(c, this.mode === 'over' ? 'R OU REVANCHE' : '> TOQUE EM JOGAR', 28, 134, '#c7b376');
    }
    this.overlay.refresh();
  }
}
