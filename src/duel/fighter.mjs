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
  // Miguel: lote 3 (guarda, socos e chutes) e lote 4 (andar em guarda,
  // bloqueio, reações, grogue, queda, deitado, levantar, corrida, gancho,
  // jab no corpo, aparo). Agachar e clinch ainda faltam.
  miguel: { name: 'MIGUEL', sheet: 'miguel-sheet', requires: { walk: 'm3_walk', run: 'm4_run', crouch: null, attack: 'm3_jab', hurt: 'm4_hitHead', fall: 'm4_fall', rise: 'm4_rise', guard: 'm_block', clinch: null } },
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

// Quadros do Miguel. Só sequências desenhadas para ele.
const MIGUEL_GUARD = { clip: 'm_enterGuard', frame: 5 };
const MIGUEL_ABSORB = { clip: 'm_block', frame: 3 };
// Passo do andar em guarda: o desenho avança ~10 px por ciclo (passo curto);
// a 52 px/s isso seria um ciclo a cada 0,2 s. A cadência usa 36 px por ciclo
// (~0,7 s) e o pé desliza a diferença — volta a ser medida quando o passo
// desenhado tiver o tamanho pedido (1 pé).
const MIGUEL_WALK_CYCLE = 36;
const hold = (durations, t, from = 0) => from + timed(durations.slice(from), t);
const byDistance = (clip, d, stride) => { const n = clip.frames.length; return Math.floor((((d % stride) + stride) % stride) / stride * n) % n; };
const MIGUEL_HIT = { head: 'm4_hitHead', body: 'm4_hitBody', legs: 'm4_hitLeg' };
// Reações por direção (pedidas no PROMPTS-LOTE4, seção 19), da mais específica
// para a já desenhada: [forte, leve].
const MIGUEL_REACT = {
  straight: [['m4_hitHeadHeavy'], ['m4_hitHead']],
  hook: [['m4_hitHookHeavy', 'm4_hitHook', 'm4_hitHeadHeavy'], ['m4_hitHook', 'm4_hitHead']],
  uppercut: [['m4_hitUppercutHeavy', 'm4_hitUppercut', 'm4_hitHeadHeavy'], ['m4_hitUppercut', 'm4_hitHead']],
  body: [['m4_hitBodyHeavy', 'm4_hitBody'], ['m4_hitBody']],
  liver: [['m4_hitLiver', 'm4_hitBody'], ['m4_hitLiver', 'm4_hitBody']],
  legs: [['m4_hitLegHeavy', 'm4_hitLeg'], ['m4_hitLeg']],
};
function miguelHit(f, clips) {
  const kind = f.reactKind || (f.reaction === 'head' ? 'straight' : f.reaction || 'body');
  const heavy = f.reactHeavy ?? (f.stun >= MIGUEL_HEAVY_STUN);
  for (const id of (MIGUEL_REACT[kind] || MIGUEL_REACT.body)[heavy ? 0 : 1]) if (clips[id]) return clips[id];
  return clips[MIGUEL_HIT[f.reaction] || 'm4_hitBody'] || null;
}
// Atordoamento a partir do qual a reação na cabeça é a forte (direto, pesado, chutes).
const MIGUEL_HEAVY_STUN = 440;
const once = (clip, t) => ({ clip: clip.id, frame: timed(clip.durations, t) });

export function miguelRef(f, clips, clock = Infinity, moves = null) {
  if (f.state === 'thrown' && f.pairRef && clips[f.pairRef.clip]) return f.pairRef;
  const fallen = clips.m4_hitHead ? { clip: 'm4_hitHead', frame: 2 } : MIGUEL_ABSORB;
  switch (f.state) {
    case 'idle':
      // Grogue: cambaleando (lote 4). Senão, guarda respirando (lote 3).
      if (clock < f.rockedUntil && clips.m4_dazed) return { clip: 'm4_dazed', frame: loop(clips.m4_dazed, f.t) };
      return clips.m3_idle ? { clip: 'm3_idle', frame: loop(clips.m3_idle, f.t) } : MIGUEL_GUARD;
    case 'walk': {
      // Andar em guarda (lote 4), um ciclo para cada sentido.
      const g = clips[f.walkRel < 0 ? 'm4_walkBack' : 'm4_walkFwd'];
      if (g) return { clip: g.id, frame: byDistance(g, Math.abs(f.gait), MIGUEL_WALK_CYCLE) };
      // Andar sem guarda (lote 3), passada medida.
      if (clips.m3_walk) {
        const c = clips.m3_walk, n = c.frames.length;
        const k = c.stride ? byDistance(c, f.gait, c.stride) : loop(c, f.t);
        return { clip: 'm3_walk', frame: f.walkRel < 0 ? n - 1 - k : k };
      }
      const clip = clips[f.walkRel < 0 ? 'm_walkBack' : 'm_walkFwd'];
      return { clip: clip.id, frame: loop(clip, f.t) };
    }
    case 'attack': {
      const m = moves?.[f.move];
      if (m) return { clip: m.clip, frame: m.frames[frameIndex(m, f.moveT)] };
      return MIGUEL_ABSORB;
    }
    case 'guard':
      // Sobe a guarda (quadros 0–2) e segura a pose fechada.
      if (clips.m4_block) return { clip: 'm4_block', frame: Math.min(2, timed(clips.m4_block.durations, f.t)) };
      return { clip: 'm_block', frame: Math.min(2, timed(clips.m_block.durations, f.t)) };
    case 'blockstun': {
      // Absorve e volta (quadros 3–5).
      const c = clips.m4_block || clips.m_block;
      return { clip: c.id, frame: Math.min(5, hold(c.durations, f.t, 3)) };
    }
    case 'run':
      // Arrancada, depois o ciclo pela distância (passada da corrida medida no
      // Sorriso, mesma escala: o desenho do Miguel corre no lugar).
      if (f.t < RUN_START_MS && clips.m4_runStart) return { clip: 'm4_runStart', frame: timed(clips.m4_runStart.durations, f.t * clips.m4_runStart.totalMs / RUN_START_MS) };
      if (clips.m4_run) return { clip: 'm4_run', frame: byDistance(clips.m4_run, f.runDistance, RUN_STRIDE) };
      return fallen;
    case 'brake':
      return clips.m4_runStop ? once(clips.m4_runStop, f.t) : fallen;
    case 'knockdown':
    case 'ko':
      return clips.m4_fall ? once(clips.m4_fall, f.t) : fallen;
    case 'getup':
      return clips.m4_rise ? once(clips.m4_rise, f.t) : fallen;
    case 'hitstun': {
      // Reação pela direção do impacto (reactKind) e pela força; desenhos que
      // ainda não existem caem na reação mais próxima já desenhada. Começa no
      // quadro 1 (o 0 é a guarda): a pose de impacto aparece no tick do contato.
      const c = miguelHit(f, clips);
      if (!c) return MIGUEL_ABSORB;
      const n = c.frames.length, first = n > 2 ? 1 : 0;
      return { clip: c.id, frame: Math.min(n - 1, first + Math.floor(f.t / Math.max(1, f.stun) * (n - first))) };
    }
    case 'down':
      // Deitado; se a queda acabou de terminar, o deitado respira no mesmo lugar.
      return clips.m4_lying ? { clip: 'm4_lying', frame: loop(clips.m4_lying, f.t) } : MIGUEL_ABSORB;
    case 'held':
    case 'thrown':
    case 'parried':
      return clips.m4_hitBody ? { clip: 'm4_hitBody', frame: 2 } : MIGUEL_ABSORB;
    default:
      return fallen;
  }
}

// `gait`: tabelas de avanço por quadro (Duel.gait), medidas nos pés desenhados.
export function animationRef(f, moves, clips, gait = null, clock) {
  if (f.character === 'miguel') return miguelRef(f, clips, clock, moves);
  if (f.state === 'thrown' && f.pairRef && clips[f.pairRef.clip]) return f.pairRef;
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
