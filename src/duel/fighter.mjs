// Lutador do duelo. Jogador e IA usam exatamente esta estrutura e as mesmas
// regras; a única diferença é de onde vem a entrada.
import { CommandBuffer } from '../core/command-buffer.mjs';
import { freshCondition } from './damage.mjs';
import { frameIndex } from './moves.mjs';
import { R2_STRIDE, tableFrame } from '../locomotion.mjs';

// O que cada personagem consegue mostrar com a arte existente. Uma ação sem
// desenho próprio fica indisponível — não é emprestada de outro personagem.
export const CHARACTERS = {
  sorriso: { name: 'SORRISO', sheet: 'sorriso-sheet', requires: { walk: 'r2_walk', run: 'r2_run', crouch: 'r2_crouchHold', attack: 'r3_jab_head', hurt: 'hurt', fall: 'fall', rise: 'rise', guard: 'block', clinch: 'clinchWalk' } },
  // Miguel (lote 2, arte/personagens/miguel/lote2): entra em guarda, anda em
  // guarda para frente e para trás e bloqueia. Golpes, corrida, agachar,
  // reações e queda ainda não foram desenhados.
  miguel: { name: 'MIGUEL', sheet: 'miguel-sheet', requires: { walk: 'm_walkFwd', run: null, crouch: null, attack: null, hurt: null, fall: null, rise: null, guard: 'm_block', clinch: null } },
};

export function capabilities(character, clips) {
  const out = {};
  for (const [action, clip] of Object.entries(CHARACTERS[character].requires)) out[action] = !!clip && !!clips[clip];
  return out;
}

// Velocidades escolhidas junto com a passada desenhada: a 120 px/s a corrida
// troca de quadro a cada ~78 ms (desenho: 60 ms) sem o pé escorregar; andar a
// 52 px/s dá ~146 ms por quadro. Mais devagar que isso, as pernas parecem em
// câmera lenta; mais rápido, o espaço do duelo acaba.
export const SPEED = { forward: 52, back: 42, run: 120, crouch: 0 };
export const WALK_STRIDE = R2_STRIDE.walk;
export const RUN_STRIDE = R2_STRIDE.run;
// Arrancada inteira (os 8 quadros de r2_runStart, 490 ms no desenho) em 340 ms.
export const RUN_START_MS = 340;
export const NEUTRAL = new Set(['idle', 'walk', 'run', 'brake', 'guard', 'crouch']);

export function createFighter(id, character, x, facing, clips) {
  return {
    id, character, x, prevX: x, y: 150, facing, vx: 0,
    state: 'idle', t: 0,
    move: null, moveT: 0, connected: false, hitDone: false, chain: 0, prevTip: null, moveFrom: null,
    gait: 0, runDistance: 0, walkRel: 0,
    condition: freshCondition(), balance: 100, stamina: 100,
    headRecent: 0, rockedUntil: -1,
    guardAt: -1e9, parryUntil: 0, downMs: 0, downExtra: 0, stepLeft: 0, stepRate: 0,
    buffer: new CommandBuffer(), stun: 0, reaction: null,
    clinch: null, result: null, ko: false, invulnerable: false,
    can: capabilities(character, clips),
    lastHitAt: -1e9,
  };
}

const loop = (clip, t) => {
  let rest = ((t % clip.totalMs) + clip.totalMs) % clip.totalMs;
  for (let i = 0; i < clip.durations.length; i++) {
    if (rest < clip.durations[i]) return i;
    rest -= clip.durations[i];
  }
  return 0;
};
const timed = (times, t) => frameIndex({ times }, t);

// Quadro a desenhar: {clip, frame} com `frame` relativo ao clip.
// Deslocamento visual da locomoção: o sprite avança em degraus iguais ao recuo
// do pé apoiado em cada quadro, em vez de deslizar continuamente com a pose
// parada. A posição física (f.x) continua contínua; só o desenho e as caixas
// usam x + offset, então o pé no chão fica fixo enquanto o quadro dura.
export function gaitOffset(f, gait) {
  if (!gait || (f.state !== 'walk' && !(f.state === 'run' && f.t >= RUN_START_MS))) return 0;
  const table = f.state === 'run' ? gait.run : gait.walk, distance = f.state === 'run' ? f.runDistance : f.gait;
  const phase = ((distance % table.stride) + table.stride) % table.stride;
  return -(phase - table.start[tableFrame(table, distance)]) * f.facing;
}

// Quadros do Miguel. Só sequências desenhadas para ele; o que não tem desenho
// (reação, queda, nocaute, preso) segura o quadro de absorção do bloqueio
// (m_block 3), escolha registrada com o usuário até chegar a arte própria.
const MIGUEL_GUARD = { clip: 'm_enterGuard', frame: 5 };
const MIGUEL_ABSORB = { clip: 'm_block', frame: 3 };
const hold = (durations, t, from = 0) => from + timed(durations.slice(from), t);

export function miguelRef(f, clips, clock = Infinity) {
  switch (f.state) {
    case 'idle':
      // Abertura da luta: neutro → guarda, uma vez; depois a guarda parada.
      return clock < clips.m_enterGuard.totalMs ? { clip: 'm_enterGuard', frame: timed(clips.m_enterGuard.durations, clock) } : MIGUEL_GUARD;
    case 'walk': {
      // Ciclos desenhados com duração própria (o pé quase não se desloca no
      // desenho, então a passada não é medida em distância como no Sorriso).
      const clip = clips[f.walkRel < 0 ? 'm_walkBack' : 'm_walkFwd'];
      return { clip: clip.id, frame: loop(clip, f.t) };
    }
    case 'guard':
      // Sobe a guarda (quadros 0–2) e segura a pose fechada.
      return { clip: 'm_block', frame: Math.min(2, timed(clips.m_block.durations, f.t)) };
    case 'blockstun':
      // Absorve e volta (quadros 3–5).
      return { clip: 'm_block', frame: Math.min(5, hold(clips.m_block.durations, f.t, 3)) };
    default:
      return MIGUEL_ABSORB;
  }
}

// `gait`: tabelas de avanço por quadro (Duel.gait), medidas nos pés desenhados.
export function animationRef(f, moves, clips, gait = null, clock) {
  if (f.character === 'miguel') return miguelRef(f, clips, clock);
  switch (f.state) {
    case 'walk': {
      // Fase pela distância percorrida: os pés acompanham o deslocamento.
      // Andar para trás percorre o ciclo ao contrário.
      if (gait) return { clip: 'r2_walk', frame: tableFrame(gait.walk, f.gait) };
      const n = clips.r2_walk.frames.length, phase = ((f.gait % WALK_STRIDE) + WALK_STRIDE) % WALK_STRIDE;
      return { clip: 'r2_walk', frame: Math.floor(phase / WALK_STRIDE * n) % n };
    }
    case 'run':
      if (f.t < RUN_START_MS) return { clip: 'r2_runStart', frame: timed(clips.r2_runStart.durations, f.t * clips.r2_runStart.totalMs / RUN_START_MS) };
      if (gait) return { clip: 'r2_run', frame: tableFrame(gait.run, f.runDistance) };
      return { clip: 'r2_run', frame: Math.floor((f.runDistance % RUN_STRIDE) / RUN_STRIDE * clips.r2_run.frames.length) % clips.r2_run.frames.length };
    case 'brake':
      return { clip: 'r2_runStop', frame: timed(clips.r2_runStop.durations, f.t) };
    case 'crouch':
      if (f.t < clips.r2_crouchDown.totalMs) return { clip: 'r2_crouchDown', frame: timed(clips.r2_crouchDown.durations, f.t) };
      return { clip: 'r2_crouchHold', frame: loop(clips.r2_crouchHold, f.t) };
    case 'rise':
      return { clip: 'r2_crouchUp', frame: timed(clips.r2_crouchUp.durations, f.t) };
    case 'attack':
    case 'clinchStrike': {
      const m = moves[f.move];
      return { clip: m.clip, frame: m.frames[frameIndex(m, f.moveT)] };
    }
    case 'whiff': {
      const w = moves[f.move].whiff;
      return { clip: w.clip, frame: timed(w.times, f.t) };
    }
    case 'guard':
      return { clip: 'block', frame: 0 };
    case 'blockstun':
      return { clip: 'block', frame: Math.min(3, 1 + Math.floor(f.t / 70)) };
    case 'hitstun':
      // Uma pose por região. A sequência de reação ainda não foi desenhada.
      return { clip: 'hurt', frame: f.reaction === 'head' ? 1 : f.reaction === 'legs' ? 3 : 0 };
    case 'knockdown':
    case 'ko':
      return { clip: 'fall', frame: Math.min(3, timed([90, 110, 140, 1e9], f.t)) };
    case 'down':
      return { clip: 'fall', frame: 3 };
    case 'getup':
      return f.t < 160 ? { clip: 'fall', frame: 4 } : { clip: 'rise', frame: timed([90, 90, 90, 90, 90, 90, 1e9], f.t - 160) };
    case 'collapse':
      return { clip: 'crouch', frame: Math.min(5, 2 + Math.floor(f.t / 130)) };
    case 'clinchEntry':
    case 'clinch':
      return { clip: 'clinchWalk', frame: f.state === 'clinch' ? Math.floor(Math.abs(f.gait) / 3) % 8 : Math.min(2, Math.floor(f.t / 70)) };
    case 'grabMiss':
      // Braços estendidos para a pega que não encontrou o corpo, e recolhidos.
      return { clip: 'clinchWalk', frame: [0, 1, 2, 1, 0][Math.min(4, Math.floor(f.t / 60))] };
    case 'held':
    case 'thrown':
    case 'parried':
      return { clip: 'hurt', frame: 0 };
    default:
      return { clip: 'r1_idle', frame: loop(clips.r1_idle, f.t) };
  }
}
