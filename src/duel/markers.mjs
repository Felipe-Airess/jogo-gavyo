// Marcadores anatômicos por quadro (scripts/extract-markers.py) convertidos
// para o mundo: espelhamento pelo olhar, pivô no pé e escala do sprite.
// Quando um marcador não existe no quadro, a caixa correspondente não existe:
// não há coordenada inventada para um membro que não foi encontrado.
import { centerBox } from './collision.mjs';

export class MarkerSet {
  constructor(data) {
    this.clips = data.clips;
    this.limits = new Map();
  }

  frame(clip, frame) {
    return this.clips[clip]?.[frame] || null;
  }

  // Registra (uma vez) que um quadro usado em combate não tem o membro pedido.
  note(clip, frame, what) {
    const key = clip + ':' + frame + ':' + what;
    if (!this.limits.has(key)) this.limits.set(key, { clip, frame, what });
  }
}

// Local (olhando para a direita, y para cima negativo) → mundo.
export const toWorld = (p, f) => p && { x: f.x + p.x * f.facing * (f.scale || 1), y: f.y + p.y * (f.scale || 1) };
const tipOf = h => h && { x: h.tipX, y: h.tipY };

// Pontos do quadro atual: cabeça, tronco, quadril, punho/pé/joelho da frente.
export function worldMarkers(m, f) {
  if (!m) return null;
  return {
    head: toWorld(m.head, f),
    headR: (m.head?.r || 9) * (f.scale || 1),
    chin: m.head?.chin != null ? f.y + m.head.chin * (f.scale || 1) : null,
    torso: toWorld(m.torso, f),
    torsoTop: m.torso ? f.y + m.torso.top : null,
    hip: toWorld(m.hip, f),
    fist: toWorld(tipOf(m.frontFist), f),
    rearFist: m.fists.length > 1 ? toWorld(tipOf(m.fists[0]), f) : null,
    foot: toWorld(tipOf(m.frontFoot), f),
    knee: toWorld(m.frontKnee, f),
    feet: m.feet.map(p => toWorld(tipOf(p), f)),
  };
}

// Hurtboxes por região. Cabeça usa um quadrado menor que o cabelo volumoso.
export function hurtboxes(w) {
  if (!w) return {};
  const out = {};
  if (w.head) {
    // Do alto do cabelo (sem todo o volume) até o queixo: o soco no rosto conta.
    const s = Math.max(9, w.headR * 1.5), top = w.head.y - w.headR * 0.75;
    const bottom = w.chin ?? w.head.y + s / 2;
    out.head = { x: w.head.x - s / 2, y: top, w: s, h: Math.max(s * 0.8, bottom - top) };
  }
  if (w.torso && w.hip) {
    const top = Math.min(w.torsoTop ?? w.torso.y - 8, w.hip.y - 6);
    const cx = (w.torso.x + w.hip.x) / 2;
    out.body = { x: cx - 8, y: top, w: 16, h: Math.max(6, w.hip.y - top) };
  }
  if (w.hip && w.feet.length) {
    const xs = [w.hip.x, ...w.feet.map(p => p.x)];
    const x0 = Math.min(...xs) - 3, x1 = Math.max(...xs) + 3;
    const bottom = Math.max(...w.feet.map(p => p.y)) + 2;
    out.legs = { x: x0, y: w.hip.y, w: x1 - x0, h: Math.max(4, bottom - w.hip.y) };
  }
  return out;
}

// Pushbox (desenho de depuração): largura fixa centrada no quadril, como em Duel.separate.
export const pushbox = (f, w) => ({ x: (w?.hip?.x ?? f.x) - 8, y: f.y - 40, w: 16, h: 40 });

// Zona de guarda: braços à frente da cabeça e do tronco.
export function guardBox(f, w) {
  if (!w?.head || !w.hip) return null;
  const front = (w.torso?.x ?? f.x) + f.facing * 4;
  const x0 = Math.min(front, front + f.facing * 14), top = w.head.y - w.headR;
  return { x: x0, y: top, w: 14, h: w.hip.y - top };
}

// Área de agarrão: à frente do tronco, na altura do peito.
export function grabBox(f, w) {
  if (!w?.torso) return null;
  const x = w.torso.x + f.facing * 6;
  return { x: Math.min(x, x + f.facing * 22), y: w.torso.y - 12, w: 22, h: 20 };
}

export const LIMB_SIZE = { fist: [6, 6], rearFist: [6, 6], foot: [9, 8], knee: [10, 10] };
