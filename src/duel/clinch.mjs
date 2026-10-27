// Clinch entre dois lutadores do duelo.
// Entrada: alcance de agarrão sobre o tronco do alvo, alvo fora de ataque e de pé.
// Controle: quem segura arrasta, dá joelhada ou soco curto, gastando fôlego.
// Resistência: quem é segurado aperta comandos ou puxa para trás e enche a
// barra de escape; o ganho depende da diferença de fôlego.
// Soltura previsível: pega esgotada, escape completo, fôlego zerado, G de novo
// ou queda do alvo. Os corpos se aproximam com velocidade limitada, sem teleporte.
export const CLINCH = {
  gap: 22, approach: 70, entry: 200, grip: 2600, maxGrip: 3600, refresh: 500,
  drag: 20, dragCost: 6, pulseEscape: 16, holdEscape: 25, pulseCost: 2, breakPush: 60, missMs: 300,
};
// Distância por quem segura: a joelhada do Miguel (lote 5) sobe colada ao
// corpo e só alcança o tronco a 20 px ou menos.
export const CLINCH_GAP = { miguel: 20 };

export function startClinch(a, d) {
  a.state = 'clinchEntry'; a.t = 0; a.vx = 0; a.gait = 0;
  a.clinch = { role: 'control', partner: d.id, grip: CLINCH.grip, gap: CLINCH_GAP[a.character] ?? CLINCH.gap };
  d.state = 'held'; d.t = 0; d.vx = 0; d.move = null;
  d.clinch = { role: 'held', partner: a.id, escape: 0 };
  a.buffer.clear(); d.buffer.clear();
}

export function endClinch(a, d, how) {
  for (const f of [a, d]) {
    if (!f) continue;
    f.clinch = null;
    if (['clinchEntry', 'clinch', 'clinchStrike', 'held'].includes(f.state)) { f.from = f.state; f.state = 'idle'; f.t = 0; f.move = null; }
  }
  if (how === 'escape' && a && d) {
    // Separação com velocidade, não deslocamento instantâneo.
    a.vx = -a.facing * CLINCH.breakPush;
    d.vx = -d.facing * CLINCH.breakPush;
  }
}

// Move o par em direção ao espaçamento do clinch.
export function keepGap(a, d, dt) {
  const s = dt / 1000, target = a.x + a.facing * (a.clinch?.gap ?? CLINCH.gap);
  const step = CLINCH.approach * s;
  if (a.state === 'clinchEntry') {
    // Os dois cedem metade do caminho.
    const error = d.x - target, move = Math.max(-step, Math.min(step, error / 2));
    a.x += move; d.x -= move;
  } else {
    d.x += Math.max(-step, Math.min(step, target - d.x));
  }
}

// Quanto um pulso de escape rende: fôlego de quem escapa contra quem segura.
export function escapeGain(d, a) {
  return CLINCH.pulseEscape * Math.max(0.5, Math.min(1.6, (d.stamina + 10) / (a.stamina + 20)));
}
