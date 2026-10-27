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
    hurt: m.hurt ? hurtRects(m.hurt, f) : null,
  };
}

// Retângulos locais [x0,y0,x1,y1) → caixas no mundo, espelhadas pelo olhar.
export function hurtRects(hurt, f) {
  const s = f.scale || 1, out = {};
  for (const [zone, list] of Object.entries(hurt)) {
    out[zone] = list.map(([x0, y0, x1, y1]) => {
      const a = f.x + x0 * f.facing * s, b = f.x + x1 * f.facing * s;
      return { x: Math.min(a, b), y: f.y + y0 * s, w: Math.abs(b - a), h: (y1 - y0) * s };
    });
  }
  return out;
}

// Hurtboxes por região, sempre como lista de caixas: { head: [...], body: [...], legs: [...] }.
// Com `hurt` nos marcadores (pixels do quadro), as caixas seguem o desenho;
// sem ele, uma caixa por região estimada pelos marcadores (método anterior).
// Braços (antebraço e mão) só são atingíveis com `arms: true` — o duelo liga
// isso durante o golpe, quando o membro está estendido — e contam como tronco.
// Parado, a mão diante do corpo não aumenta o alcance de quem bate.
export function hurtboxes(w, { arms = false } = {}) {
  if (!w) return {};
  if (w.hurt) {
    const out = {};
    for (const [zone, list] of Object.entries(w.hurt)) {
      if (zone === 'arms') continue;
      if (list.length) out[zone] = list;
    }
    if (arms && w.hurt.arms?.length) out.body = [...(out.body || []), ...w.hurt.arms];
    return out;
  }
  const one = markerHurtboxes(w), out = {};
  for (const [zone, box] of Object.entries(one)) out[zone] = [box];
  return out;
}

// Retângulo que envolve todas as caixas de uma região (desenho e testes).
export function bounds(list) {
  if (!list?.length) return null;
  const x0 = Math.min(...list.map(b => b.x)), y0 = Math.min(...list.map(b => b.y));
  const x1 = Math.max(...list.map(b => b.x + b.w)), y1 = Math.max(...list.map(b => b.y + b.h));
  return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 };
}

// Método anterior: uma caixa por região a partir dos marcadores.
// Cabeça usa um quadrado menor que o cabelo volumoso.
function markerHurtboxes(w) {
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

// Pé de apoio parado (golpes com `plant`): deslocamento do corpo, por quadro,
// que mantém no mesmo lugar do mundo o pé que sustenta o chute. O desenho do
// Miguel põe o pé de apoio no centro da célula, mas na guarda o pé da frente
// fica ~18 px à frente: sem isto o chute recua e o pé que chuta não chega.
// Regra: nos quadros com um só pé no chão, esse pé está onde estava o pé da
// frente da guarda (quadro 0); antes deles, a transição é proporcional; depois,
// o pé no chão mais perto do anterior fica parado (até `tol` px).
export function plantedOffsets(frames, tol = 14) {
  const ground = f => (f?.feet || []).filter(p => p.tipY >= -6).map(p => p.tipX);
  const g = frames.map(ground);
  if (!g[0]?.length) return frames.map(() => 0);
  const G0 = Math.max(...g[0]);
  const single = g.map((x, k) => (k > 0 && x.length === 1 ? k : -1)).filter(k => k >= 0);
  if (!single.length) return frames.map(() => 0);
  const a = single[0], b = single.at(-1), off = [];
  for (let k = 0; k < frames.length; k++) {
    if (k <= a) off[k] = (G0 - g[a][0]) * k / a;
    else if (k <= b) off[k] = g[k].length === 1 ? G0 - g[k][0] : off[k - 1];
    else {
      const prev = g[k - 1].map(x => x + off[k - 1]);
      let best = null;
      for (const x of g[k]) for (const q of prev) { const d = Math.abs(x + off[k - 1] - q); if (!best || d < best.d) best = { d, x, q }; }
      off[k] = best && best.d <= tol ? best.q - best.x : off[k - 1];
    }
  }
  return off.map(v => Math.round(v));
}

export const LIMB_SIZE = { fist: [6, 6], rearFist: [6, 6], foot: [9, 8], knee: [10, 10] };

// Centro da hitbox do membro. O marcador é o pixel mais à frente do punho,
// do tênis ou do joelho; a caixa termina nele, em vez de passar dele pela
// metade da largura (o que dava 3 a 5 px de alcance a mais que o desenho).
export function limbCenter(tip, limb, facing) {
  if (!tip) return null;
  return { x: tip.x - facing * LIMB_SIZE[limb][0] / 2, y: tip.y };
}
