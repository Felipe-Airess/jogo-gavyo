// Dano localizado, equilíbrio, fôlego e nocaute — sem sorteio.
// Cada lutador acumula castigo na cabeça, no tronco e nas pernas (0 a 100).
// O equilíbrio cai com os impactos e se recupera com o tempo; perto de zero o
// lutador cai. O nocaute depende do estado: um golpe limpo na cabeça derruba
// quem já está castigado, desequilibrado ou foi pego no meio do próprio ataque.
export const LIMIT = 100;
export const KO = {
  // Cabeça acima disso fica vulnerável a um nocaute situacional.
  hurtHead: 55,
  // Equilíbrio abaixo disso conta como vulnerável.
  lowBalance: 30,
  lowStamina: 20,
};

// Qualidade do contato, medida pela parte da hitbox do membro que entrou na
// região atingida (Duel.probe): golpe limpo entra fundo; raspão só encosta.
export const QUALITY = {
  clean: { damage: 1.25, balance: 1.2, stun: 1.15, min: 0.6 },
  normal: { damage: 1, balance: 1, stun: 1, min: 0.25 },
  graze: { damage: 0.5, balance: 0.5, stun: 0.7, min: 0 },
};
export function contactQuality(coverage) {
  if (coverage == null) return 'normal';
  return coverage >= QUALITY.clean.min ? 'clean' : coverage >= QUALITY.normal.min ? 'normal' : 'graze';
}

// Grogue: dano na cabeça em sequência curta. O acumulado cai com o tempo;
// passando do limite, o lutador fica grogue por `ms`: anda devagar, não corre,
// não recupera equilíbrio, a guarda gasta o dobro de fôlego e um golpe limpo
// médio ou pesado na cabeça nocauteia, se a cabeça já tiver `koHead` de castigo.
export const ROCK = { threshold: 32, decay: 12, ms: 2600, speed: 0.6, clean: 1.5, koHead: 45 };

export function freshCondition() {
  return { head: 0, body: 0, legs: 0 };
}

// Multiplicador de vulnerabilidade: contra-ataque, base quebrada, sem fôlego.
export function vulnerability(defender, counter) {
  let m = 1;
  if (counter) m *= 1.35;
  if (defender.balance < KO.lowBalance) m *= 1.2;
  if (defender.stamina < KO.lowStamina) m *= 1.15;
  return m;
}

// Retorna o resultado sem alterar o defensor; `applyHit` aplica.
export function resolveHit(move, defender, zone, { blocked = false, counter = false, quality = 'normal', rocked = false, scale = 1 } = {}) {
  if (blocked) {
    const stamina = Math.max(4, move.cost * 0.9 + move.power * 2) * (rocked ? 2 : 1);
    const broken = defender.stamina - stamina <= 0;
    return { kind: broken ? 'guardBreak' : 'block', zone: 'arms', damage: 0, stamina, balance: move.balance * 0.3,
      stun: broken ? 520 : move.blockstun, push: move.push * 0.5, reason: broken ? 'Guarda rompida: sem fôlego para segurar.' : null };
  }
  const q = QUALITY[quality] || QUALITY.normal;
  const mult = vulnerability(defender, counter);
  const damage = Math.round(move.damage * mult * q.damage * scale);
  let balance = move.balance * mult * q.balance * scale * (zone === 'legs' ? 1.3 : 1);
  // Pernas castigadas sustentam menos o corpo.
  balance *= 1 + defender.condition.legs / 200;
  const stamina = zone === 'body' ? damage * 0.9 : damage * 0.3;
  const after = { ...defender.condition, [zone]: Math.min(LIMIT, defender.condition[zone] + damage) };
  const balanceAfter = defender.balance - balance;
  const out = { kind: 'hit', zone, damage, balance, stamina, stun: Math.round(move.hitstun * (counter ? 1.2 : 1) * q.stun), push: move.push, counter, quality, reason: null };

  if (zone === 'head') {
    if (after.head >= LIMIT) return { ...out, kind: 'ko', reason: 'Nocaute: a cabeça não aguentou mais.' };
    // Raspão nunca nocauteia por situação; só pelo limite da cabeça.
    const solid = move.power >= 2 && quality !== 'graze';
    if (solid && quality === 'clean' && rocked && after.head >= ROCK.koHead) return { ...out, kind: 'ko', reason: 'Nocaute: golpe limpo em quem estava grogue.' };
    const clean = solid && after.head >= KO.hurtHead;
    if (clean && counter) return { ...out, kind: 'ko', reason: 'Nocaute: golpe limpo no contra-ataque, com a cabeça já castigada.' };
    if (clean && balanceAfter <= KO.lowBalance) return { ...out, kind: 'ko', reason: 'Nocaute: golpe limpo com a base já perdida.' };
  }
  if (zone === 'body' && after.body >= LIMIT) return { ...out, kind: 'collapse', reason: 'O tronco cedeu: dobrou de dor.' };
  if (zone === 'legs' && after.legs >= LIMIT) return { ...out, kind: 'knockdown', reason: 'A perna cedeu.' };
  if (balanceAfter <= 0) return { ...out, kind: 'knockdown', reason: 'Perdeu o equilíbrio e caiu.' };
  return out;
}

export function applyHit(defender, result) {
  defender.stamina = Math.max(0, defender.stamina - result.stamina);
  defender.balance = Math.max(0, defender.balance - result.balance);
  if (result.zone !== 'arms') defender.condition[result.zone] = Math.min(LIMIT, defender.condition[result.zone] + result.damage);
}
