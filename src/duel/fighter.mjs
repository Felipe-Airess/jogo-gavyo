// Lutador do duelo. Jogador e IA usam exatamente esta estrutura e as mesmas
// regras; a única diferença é de onde vem a entrada.
import { CommandBuffer } from '../core/command-buffer.mjs';
import { freshCondition } from './damage.mjs';
import { frameIndex } from './moves.mjs';

// O que cada personagem consegue mostrar com a arte existente. Uma ação sem
// desenho próprio fica indisponível — não é emprestada de outro personagem.
export const CHARACTERS = {
  sorriso: { name: 'SORRISO', sheet: 'sorriso-sheet', requires: { walk: 'r2_walk', run: 'r2_run', crouch: 'r2_crouchHold', attack: 'r3_jab_head', hurt: 'hurt', fall: 'fall', rise: 'rise', guard: 'block', clinch: 'clinchWalk' } },
  // Miguel: só idle e guarda foram entregues (arte/personagens/miguel).
  miguel: { name: 'MIGUEL', sheet: 'miguel-sheet', requires: { walk: null, run: null, crouch: null, attack: null, hurt: null, fall: null, rise: null, guard: 'guard', clinch: null } },
};

export function capabilities(character, clips) {
  const out = {};
  for (const [action, clip] of Object.entries(CHARACTERS[character].requires)) out[action] = !!clip && !!clips[clip];
  return out;
}

export const SPEED = { forward: 44, back: 36, run: 86, crouch: 0 };
export const WALK_STRIDE = 40;
export const RUN_STRIDE = 84;
export const NEUTRAL = new Set(['idle', 'walk', 'run', 'guard', 'crouch']);

export function createFighter(id, character, x, facing, clips) {
  return {
    id, character, x, prevX: x, y: 150, facing, vx: 0,
    state: 'idle', t: 0,
    move: null, moveT: 0, connected: false, hitDone: false, chain: 0, prevTip: null, moveFrom: null,
    gait: 0, runDistance: 0,
    condition: freshCondition(), balance: 100, stamina: 100,
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
export function animationRef(f, moves, clips) {
  switch (f.state) {
    case 'walk': {
      const n = clips.r2_walk.frames.length;
      // Fase pela distância percorrida: os pés acompanham o deslocamento.
      // Andar para trás percorre o ciclo ao contrário.
      const phase = ((f.gait % WALK_STRIDE) + WALK_STRIDE) % WALK_STRIDE;
      return { clip: 'r2_walk', frame: Math.floor(phase / WALK_STRIDE * n) % n };
    }
    case 'run':
      if (f.t < 280) return { clip: 'r2_runStart', frame: timed(clips.r2_runStart.durations, f.t) };
      return { clip: 'r2_run', frame: Math.floor((f.runDistance % RUN_STRIDE) / RUN_STRIDE * clips.r2_run.frames.length) % clips.r2_run.frames.length };
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
      return { clip: 'hurt', frame: 0 };
    default:
      return { clip: 'r1_idle', frame: loop(clips.r1_idle, f.t) };
  }
}
