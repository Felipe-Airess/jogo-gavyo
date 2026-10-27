// Cena do duelo 1×1. Só desenha: as regras ficam em duel.mjs.
// Canvas, 320×180, nearest-neighbor — o mesmo perfil leve do corredor.
import { Duel, STAGE } from './duel.mjs';
import { CHARACTERS } from './fighter.mjs';
import { Match, ROUND_OPTIONS, TIME_OPTIONS } from './match.mjs';
import { DuelAI, AI_LEVELS, AI_LEVEL_NAMES } from './ai.mjs';
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
  constructor() { super('Duel'); this.mode = 'select'; this.debugVisible = false; this.hudClock = 0; this.rivalFrames = new Set(); this.menuRow = 0; this.menuHeld = {}; this.bannerKey = ''; }

  // Escolhas da tela de seleção. Ficam no navegador de quem joga (conveniência).
  static SETTINGS_KEY = 'gaviao-duelo';
  loadSettings() {
    const base = { player: 'sorriso', rival: 'sorriso', level: 'firme', bestOf: 3, seconds: 60 };
    try { return { ...base, ...JSON.parse(localStorage.getItem(DuelScene.SETTINGS_KEY) || '{}') }; } catch { return base; }
  }
  saveSettings() { try { localStorage.setItem(DuelScene.SETTINGS_KEY, JSON.stringify(this.settings)); } catch { /* sem armazenamento: só não lembra */ } }

  preload() {
    if (!this.cache.json.get('sorriso-markers')) this.load.json('sorriso-markers', 'assets/sorriso-markers.json');
    if (!this.cache.json.get('miguel-markers')) this.load.json('miguel-markers', 'assets/miguel-markers.json');
  }

  create() {
    const ui = this.registry.get('ui');
    this.ui = ui;
    this.clips = Object.fromEntries(this.cache.json.get('sorriso-data').clips.map(c => [c.id, c]));
    const miguel = this.cache.json.get('miguel-data'), miguelMarkers = this.cache.json.get('miguel-markers');
    const roster = miguel && miguelMarkers ? { miguel: { clips: Object.fromEntries(miguel.clips.map(c => [c.id, c])), markers: miguelMarkers } } : {};
    this.model = new Duel({ clips: this.clips, markers: this.cache.json.get('sorriso-markers'), roster });
    this.settings = this.loadSettings();
    for (const k of ['player', 'rival']) if (!this.model.roster[this.settings[k]]) this.settings[k] = 'sorriso';
    if (!AI_LEVELS[this.settings.level]) this.settings.level = 'firme';
    this.ai = new DuelAI(41, this.settings.level);
    this.match = new Match({ bestOf: this.settings.bestOf, seconds: this.settings.seconds });
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
    this.changeMode(this.mode);
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
    this.ui.play.textContent = mode === 'playing' ? 'Pausar' : mode === 'select' ? 'Lutar' : mode === 'over' ? 'Revanche' : 'Continuar';
    this.menuHeld = {};
    this.paintOverlay();
  }

  toggle() {
    if (!this.model) return;
    this.audio?.unlock();
    if (this.mode === 'select' || this.mode === 'over') this.startMatch();
    else this.changeMode(this.mode === 'playing' ? 'paused' : 'playing');
  }
  // R e Reiniciar: mesma configuração, partida do zero (revanche).
  restart() { if (!this.model) return; if (this.mode === 'select') return; this.startMatch(); }
  startMatch() {
    const st = this.settings;
    if (!this.model.setCharacters([st.player, st.rival])) return;
    this.saveSettings();
    this.ai = new DuelAI(41, st.level);
    this.match = new Match({ bestOf: st.bestOf, seconds: st.seconds });
    this.fx.reset(); this.blood.reset(); this.cameraX = 80;
    this.changeMode('playing');
    this.render(0);
  }
  openSelect() { this.changeMode('select'); }
  setDebug(on) { this.debugVisible = on; }
  // Personagem do jogador; o rival continua sendo o Sorriso controlado pela IA.
  // Seletor "Lutador" da página: muda a escolha e volta para a tela de seleção.
  setPlayer(character) {
    if (!this.model?.roster[character]) return false;
    this.settings.player = character;
    this.saveSettings();
    this.openSelect();
    return true;
  }

  // Linhas da tela de seleção: [rótulo, valores, chave].
  menuRows() {
    const chars = Object.keys(this.model.roster);
    return [
      ['VOCE', chars, 'player'],
      ['RIVAL', chars, 'rival'],
      ['IA', Object.keys(AI_LEVELS), 'level'],
      ['ROUNDS', ROUND_OPTIONS, 'bestOf'],
      ['TEMPO', TIME_OPTIONS, 'seconds'],
      ['LUTAR', null, null],
    ];
  }
  menuLabel(key, value) {
    if (key === 'player' || key === 'rival') return CHARACTERS[value].name;
    if (key === 'level') return AI_LEVEL_NAMES[value];
    if (key === 'bestOf') return value === 1 ? '1 ROUND' : 'MELHOR DE ' + value;
    if (key === 'seconds') return value ? value + ' SEG' : 'SEM TEMPO';
    return String(value);
  }
  // Teclado e toque: borda de subida das direções (segurar não rola a lista).
  updateMenu(input) {
    const edge = k => input[k] && !this.menuHeld[k];
    const rows = this.menuRows();
    let changed = false;
    if (edge('up')) { this.menuRow = (this.menuRow + rows.length - 1) % rows.length; changed = true; }
    if (edge('down')) { this.menuRow = (this.menuRow + 1) % rows.length; changed = true; }
    const [, values, key] = rows[this.menuRow];
    const step = edge('right') ? 1 : edge('left') ? -1 : 0;
    if (step && values) {
      const i = values.indexOf(this.settings[key]);
      this.settings[key] = values[(i + step + values.length) % values.length];
      changed = true;
    }
    this.menuHeld = { up: input.up, down: input.down, left: input.left, right: input.right };
    if (input.attack || input.kick) { this.startMatch(); return; }
    if (changed) { this.saveSettings(); this.paintOverlay(); }
  }

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
    if (pressed.has('KeyM') && this.mode !== 'playing') this.openSelect();
    if (pressed.has('KeyB')) document.getElementById('blood')?.click();
    this.blood.enabled = document.getElementById('blood')?.getAttribute('aria-pressed') !== 'false';
    if ((pressed.has('Enter') && !['BUTTON', 'SELECT'].includes(document.activeElement?.tagName)) || pressed.has('Escape')) this.toggle();
    if (this.mode === 'select') this.updateMenu(this.readInput(pressed));
    else if (this.mode === 'over') {
      const input = this.readInput(pressed);
      if (input.kick) this.openSelect();
      else if (input.attack) this.startMatch();
    }
    if (this.mode === 'playing') {
      const input = this.readInput(pressed), m = this.model, match = this.match, scale = this.fx.timeScale();
      // Comandos só valem com o round valendo; no anúncio os dois ficam parados.
      // Câmera lenta do nocaute: menos tempo de jogo por quadro, mesmo passo fixo.
      this.stepper.advance(delta * scale, input, (sample, dt) => {
        const open = match.inputsOpen;
        m.tick([open ? sample : {}, open ? this.ai.input(m, m.rival, m.player) : {}], dt);
        const step = match.update(dt, m);
        if (step === 'nextRound') { m.reset(); this.ai.reset(); this.fx.reset(); this.cameraX = 80; }
      });
      if (match.finished) this.changeMode('over');
      this.fx.consume(m);
      this.fx.step(delta, m);
      this.blood.step(delta * this.fx.timeScale());
      this.playAudio();
    }
    // Anúncio novo: redesenha a camada da frente só quando muda.
    const banner = this.mode === 'playing' ? this.match.banner : null, key = banner ? banner.title + banner.sub : '';
    if (key !== this.bannerKey) { this.bannerKey = key; this.paintOverlay(); }
    const status = this.mode === 'paused' ? 'Pausado. Toque em Continuar.' : this.mode === 'select' ? 'Escolha com o direcional; Soco ou Lutar começa.' : this.mode === 'over' ? 'Soco/J: revanche · Chute/K: trocar lutadores.' : this.model.message;
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
      const view = this.views[i], ref = m.animation(f), frame = m.artOf(f.character).clips[ref.clip].frames[ref.frame];
      // Interpolação só da posição: a pose continua sendo o quadro desenhado.
      // Interpolação só fora da passada: na locomoção o degrau por quadro já
      // define onde o sprite fica (pé apoiado parado).
      const step = m.drawX(f) - f.x;
      let x = step ? m.drawX(f) : lerp(f.prevX, f.x, alpha);
      if (m.hitstop > 0 && m.lastHit?.target === f.id) x += (Math.floor(m.hitstop / 33) % 2 ? 1 : -1);
      const index = frame.index;
      // Rival com roupa escura só quando é o mesmo personagem do jogador.
      const sheet = CHARACTERS[f.character].sheet, mirror = i === 1 && f.character === m.player.character && f.character === 'sorriso';
      view.image.setTexture(mirror ? this.rivalFrame(index) : sheet, mirror ? undefined : index);
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
      const mv = m.moveOf(f), tip = limbCenter(w?.[mv.limb], mv.limb, f.facing), frame = mv.frames[frameIndex(mv, f.moveT)];
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
    // Na seleção a barra fica vazia: a luta anterior não vale mais.
    if (this.mode === 'select') { lettering(c, 'GAVIAO', 6, 10, '#d8d5b7'); this.hud.refresh(); return; }
    m.fighters.forEach((f, i) => {
      const left = i === 0, x0 = left ? 6 : 170;
      const name = CHARACTERS[f.character].name + (!left && f.character === m.player.character ? ' B' : '');
      lettering(c, name, x0, 3, left ? '#d8d5b7' : '#c9a7a2');
      // Vitórias de round: quadradinhos depois do nome.
      for (let k = 0; k < this.match.toWin; k++) {
        c.fillStyle = k < this.match.wins[i] ? '#d1bd85' : '#354438';
        c.fillRect(x0 + name.length * 4 + 3 + k * 5, 4, 3, 3);
      }
      const bars = [['C', 100 - f.condition.head, '#cab47a'], ['T', 100 - f.condition.body, '#a3b180'], ['P', 100 - f.condition.legs, '#b39d80'], ['E', f.balance, '#87aeb0'], ['F', f.stamina, '#91a17b']];
      bars.forEach(([label, value, color], j) => {
        const x = x0 + j * 29;
        lettering(c, label, x, 11, color);
        c.fillStyle = '#354438'; c.fillRect(x + 5, 12, 20, 3);
        c.fillStyle = color; c.fillRect(x + 5, 12, Math.round(20 * Math.max(0, value) / 100), 3);
      });
      const action = f.state === 'attack' ? m.moveOf(f).name + (f.chain > 1 ? ' X' + f.chain : '') : f.state === 'held' ? 'PRESO' : f.state === 'thrown' ? 'ARREMESSADO' : f.state === 'parried' ? 'APARADO' : m.clock < f.parryUntil ? 'CONTRA-ATAQUE' : f.clinch ? 'CLINCH' : f.state === 'ko' ? 'NOCAUTE' : f.state === 'guard' ? 'GUARDA' : m.isRocked(f) ? 'GROGUE' : '';
      lettering(c, action.slice(0, 18), x0, 19, '#d1bd85');
      if (f.clinch?.role === 'held') { c.fillStyle = '#c7af71'; c.fillRect(x0 + 80, 20, Math.round(60 * Math.min(1, f.clinch.escape / 100)), 2); }
    });
    const secs = this.match.clockSeconds;
    lettering(c, secs === null ? '--' : String(secs).padStart(2, '0'), 156, 4, secs !== null && secs <= 10 ? '#d98a6a' : '#ded8b3');
    if (this.debugVisible) lettering(c, 'FPS ' + Math.round(this.game.loop.actualFps || 0), 250, 19, '#82947e');
    this.hud.refresh();
    const n = this.note.context;
    n.clearRect(0, 0, 320, 11); n.fillStyle = '#182922'; n.fillRect(0, 0, 320, 11);
    // A faixa de baixo fica livre para a mensagem de estado (DOM, sobreposta).
    if (!m.player.can.attack) lettering(n, 'MIGUEL: GOLPES AINDA SEM DESENHO', 7, 3, '#a3ae90');
    this.note.refresh();
  }

  paintOverlay() {
    const c = this.overlay.context, m = this.model;
    c.clearRect(0, 0, 320, 180);
    const center = (text, y, color, scale = 1) => lettering(c, text, Math.round(160 - text.length * 2 * scale), y, color, scale);
    if (this.mode === 'playing') {
      const b = this.match?.banner;
      if (b) {
        c.fillStyle = 'rgba(12,23,21,.55)'; c.fillRect(0, 62, 320, b.sub ? 34 : 24);
        center(b.title, 66, b.title === 'K.O.' ? '#e0a070' : '#ded8b3', 2);
        if (b.sub) center(b.sub, 84, '#c1c5a1');
      }
    } else if (this.mode === 'select') {
      c.fillStyle = 'rgba(12,23,21,.9)'; c.fillRect(0, 28, 320, 141);
      center('DUELO 1X1', 36, '#ded8b3', 2);
      this.menuRows().forEach(([label, values, key], i) => {
        const y = 60 + i * 15, on = i === this.menuRow;
        if (on) { c.fillStyle = '#2b3b33'; c.fillRect(40, y - 3, 240, 11); }
        const color = on ? '#e7d38f' : '#a9b19a';
        if (!values) { center(on ? '> LUTAR <' : 'LUTAR', y, color); return; }
        lettering(c, label, 52, y, color);
        lettering(c, (on ? '< ' : '') + this.menuLabel(key, this.settings[key]) + (on ? ' >' : ''), 140, y, color);
      });
      if (this.settings.player === 'miguel' || this.settings.rival === 'miguel') lettering(c, 'MIGUEL: ARTE DOS LOTES 2 A 4', 52, 152, '#82947e');
    } else {
      c.fillStyle = 'rgba(12,23,21,.86)'; c.fillRect(0, 28, 320, 141);
      const won = this.match?.winner === 1;
      const title = this.mode === 'over' ? (won ? 'VITORIA' : 'DERROTA') : 'PAUSADO';
      center(title, 52, '#ded8b3', 2);
      if (this.mode === 'over') {
        center(this.match.wins[0] + ' X ' + this.match.wins[1], 74, '#d1bd85', 2);
        const last = this.match.history.at(-1)?.reason || '';
        center(last.replace(/[^\w\s:.\-À-ú]/g, '').slice(0, 60), 98, '#c1c5a1');
        center('J REVANCHE   K TROCAR LUTADORES', 128, '#c7b376');
      } else center('CONTINUAR PARA VOLTAR   M MENU', 92, '#c1c5a1');
    }
    this.overlay.refresh();
  }
}
