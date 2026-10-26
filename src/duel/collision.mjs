// Caixas alinhadas aos eixos e varredura de segmento.
// Hitbox, hurtbox, pushbox, guarda e agarrão usam o mesmo formato {x,y,w,h}.
export const overlap = (a, b) => !!a && !!b && a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;

export const centerBox = (cx, cy, w, h) => ({ x: cx - w / 2, y: cy - h / 2, w, h });

// Primeiro instante t∈[0,1] em que um ponto movido de `a` até `b`, com meia
// largura (hw,hh), toca `box`. Retorna null se não toca. Isso é a colisão
// contínua: um punho rápido não atravessa a cabeça entre dois ticks.
export function sweep(a, b, hw, hh, box) {
  const minX = box.x - hw, maxX = box.x + box.w + hw, minY = box.y - hh, maxY = box.y + box.h + hh;
  let t0 = 0, t1 = 1;
  const dx = b.x - a.x, dy = b.y - a.y;
  for (const [p, d, lo, hi] of [[a.x, dx, minX, maxX], [a.y, dy, minY, maxY]]) {
    if (Math.abs(d) < 1e-9) {
      if (p <= lo || p >= hi) return null;
      continue;
    }
    let near = (lo - p) / d, far = (hi - p) / d;
    if (near > far) [near, far] = [far, near];
    t0 = Math.max(t0, near);
    t1 = Math.min(t1, far);
    if (t0 > t1) return null;
  }
  return t0;
}

// Ponto de contato: posição varrida no instante t, recortada para dentro da caixa.
export function contactPoint(a, b, t, box) {
  const x = a.x + (b.x - a.x) * t, y = a.y + (b.y - a.y) * t;
  return { x: Math.max(box.x, Math.min(box.x + box.w, x)), y: Math.max(box.y, Math.min(box.y + box.h, y)) };
}
