// Miguel como jogador no corredor. As regras são as do corredor (battle.mjs):
// a caixa de ataque é a de cada golpe (point/size), não a do desenho. Aqui
// só se troca o desenho e o tempo de cada golpe pelos do Miguel, e se desliga
// o que ele não tem desenhado — nada é emprestado do Sorriso.
import { MOVES, frameAt } from './battle.mjs';
import { R2_STRIDE } from './locomotion.mjs';

// golpe do corredor → [clip do Miguel, nome no HUD, região]
const MAP = {
  jab: ['m4_jabBody', 'JAB NO CORPO', 'body'],
  jabHead: ['m3_jab', 'JAB NA CABECA', 'head'],
  cross: ['m3_cross', 'DIRETO', 'head'],
  crossBody: ['m3_crossBody', 'DIRETO NO TRONCO', 'body'],
  low: ['m4_hook', 'GANCHO', 'head'],
  drive: ['m3_overhand', 'GOLPE PESADO', null],
  kick: ['m3_roundKick', 'CHUTE CIRCULAR', 'body'],
  highKick: ['m3_stepKick', 'CHUTE COM PASSO', 'body'],
  lowKick: ['m3_lowKick', 'CHUTE NA PERNA', 'legs'],
};

// Sem desenho próprio: o golpe desenhado mais próximo (como MOVE_FALLBACK no duelo).
export const MIGUEL_FALLBACK = { reverse: 'low', rush: 'drive', comboKick: 'kick', stepPunch: 'cross' };   // impulso: pesado (sem soco correndo desenhado)

// Clipes do Miguel com fist/foot por quadro (pontas medidas nos marcadores,
// mesma convenção do atlas do Sorriso: relativo ao pivô, y negativo para cima),
// para a caixa de ataque do corredor seguir o desenho dele.
export function miguelPlayerClips(clips, markers) {
  const out = {};
  for (const [id, c] of Object.entries(clips)) {
    const mk = markers.clips[id];
    out[id] = { ...c, frames: c.frames.map((f, i) => {
      const m = mk?.[i], fist = m?.frontFist, foot = m?.frontFoot;
      return { ...f, fist: fist ? { x: fist.tipX, y: fist.tipY } : undefined, foot: foot ? { x: foot.tipX, y: foot.tipY } : undefined };
    }) };
  }
  return out;
}

// O que o Miguel ainda não tem desenhado no corredor.
export const MIGUEL_CAN = { run: true, grab: false, wipe: false };

export function createMiguelCorridorMoves(clips) {
  const moves = {};
  for (const [id, [clipId, name, zone]] of Object.entries(MAP)) {
    const base = MOVES[id] || MOVES[id === 'jabHead' ? 'jab' : id === 'crossBody' ? 'cross' : id === 'highKick' ? 'kick' : id];
    const clip = clips[clipId];
    if (!base || !clip || !clip.contactFrames?.length) continue;
    const frames = clip.frames.map((_, i) => i), times = [...clip.durations], active = [...clip.contactFrames];
    const duration = times.reduce((a, b) => a + b, 0);
    const contactStart = times.slice(0, active[0]).reduce((a, b) => a + b, 0);
    const contactEnd = times.slice(0, active.at(-1) + 1).reduce((a, b) => a + b, 0);
    const m = { ...base, name, clip: clipId, frames, times, active, duration, reviewed: true, animationStart: 0 };
    delete m.sequence;
    m.lungeUntil = Math.max(160, contactStart + 30);
    m.chain = Math.min(duration - 60, contactEnd + 150);
    m.linkAt = Math.min(duration - 80, contactEnd + 120);
    m.pause = id === 'drive' ? 55 : id.includes('Kick') || id === 'kick' ? 42 : 32;
    if (zone) m.zone = zone; else delete m.zone;
    moves[id] = m;
  }
  return moves;
}

const loop = (clip, t) => {
  let rest = ((t % clip.totalMs) + clip.totalMs) % clip.totalMs;
  for (let i = 0; i < clip.durations.length; i++) { if (rest < clip.durations[i]) return i; rest -= clip.durations[i]; }
  return 0;
};
const timed = (clip, t, from = 0, to = clip.frames.length - 1) => {
  let rest = Math.max(0, t);
  for (let i = from; i <= to; i++) { if (rest < clip.durations[i]) return i; rest -= clip.durations[i]; }
  return to;
};
// Passo do andar em guarda (ver MIGUEL_WALK_CYCLE no duelo).
const WALK_CYCLE = 36;

export function miguelCorridorRef(p, moves, clips) {
  const idle = () => ({ clip: 'm3_idle', frame: loop(clips.m3_idle, p.elapsed) });
  switch (p.state) {
    case 'walk': {
      // Para trás quando anda contra o olhar.
      const back = Math.sign(p.vx || 0) === -p.facing;
      const c = clips[back ? 'm4_walkBack' : 'm4_walkFwd'], n = c.frames.length;
      const d = ((p.gaitDistance || 0) % WALK_CYCLE + WALK_CYCLE) % WALK_CYCLE;
      return { clip: c.id, frame: Math.floor(d / WALK_CYCLE * n) % n };
    }
    case 'attack':
    case 'knee': {
      const m = moves[p.move];
      if (m) return { clip: m.clip, frame: m.frames[frameAt(p.elapsed, m)] };
      return idle();
    }
    case 'attackRecover': {
      const m = moves[p.recoverFrom || p.move];
      return m ? { clip: m.clip, frame: p.elapsed < 80 ? m.frames.at(-1) : m.frames[0] } : idle();
    }
    case 'guard':
      return { clip: 'm4_block', frame: Math.min(2, timed(clips.m4_block, p.elapsed)) };
    case 'parry':
      // Tapa da mão da frente (quadros 0–1 do aparo + contra).
      return { clip: 'm4_parryCounter', frame: Math.min(1, timed(clips.m4_parryCounter, p.elapsed)) };
    case 'hurt':
      return { clip: 'm4_hitHead', frame: timed(clips.m4_hitHead, p.elapsed) };
    case 'stumble':
      return { clip: 'm4_hitBody', frame: timed(clips.m4_hitBody, p.elapsed) };
    case 'winded':
      return { clip: 'm4_dazed', frame: loop(clips.m4_dazed, p.elapsed) };
    case 'run': {
      // Arrancada e ciclo pela distância (passada da corrida do corredor).
      if ((p.runStart || 0) < 280) return { clip: 'm4_runStart', frame: timed(clips.m4_runStart, (p.runStart || 0) * clips.m4_runStart.totalMs / 280) };
      const c = clips.m4_run, n = c.frames.length, st = R2_STRIDE.run, d = ((p.runDistance || 0) % st + st) % st;
      return { clip: 'm4_run', frame: Math.floor(d / st * n) % n };
    }
    case 'brake':
      return { clip: 'm4_runStop', frame: timed(clips.m4_runStop, p.elapsed) };
    case 'rushFall':
      return { clip: 'm4_fall', frame: timed(clips.m4_fall, p.elapsed) };
    case 'gettingUp':
      return { clip: 'm4_rise', frame: timed(clips.m4_rise, p.elapsed) };
    default:
      return idle();
  }
}

export const miguelCorridorMeta = (p, moves, clips) => { const r = miguelCorridorRef(p, moves, clips); return clips[r.clip].frames[r.frame]; };
