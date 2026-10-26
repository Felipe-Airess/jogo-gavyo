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
export function resolveHit(move, defender, zone, { blocked = false, counter = false } = {}) {
  if (blocked) {
    const stamina = Math.max(4, move.cost * 0.9 + move.power * 2);
    const broken = defender.stamina - stamina <= 0;
    return { kind: broken ? 'guardBreak' : 'block', zone: 'arms', damage: 0, stamina, balance: move.balance * 0.3,
      stun: broken ? 520 : move.blockstun, push: move.push * 0.5, reason: broken ? 'Guarda rompida: sem fôlego para segurar.' : null };
  }
  const mult = vulnerability(defender, counter);
  const damage = Math.round(move.damage * mult);
  let balance = move.balance * mult * (zone === 'legs' ? 1.3 : 1);
  // Pernas castigadas sustentam menos o corpo.
  balance *= 1 + defender.condition.legs / 200;
  const stamina = zone === 'body' ? damage * 0.9 : damage * 0.3;
  const after = { ...defender.condition, [zone]: Math.min(LIMIT, defender.condition[zone] + damage) };
  const balanceAfter = defender.balance - balance;
  const out = { kind: 'hit', zone, damage, balance, stamina, stun: Math.round(move.hitstun * (counter ? 1.2 : 1)), push: move.push, counter, reason: null };

  if (zone === 'head') {
    if (after.head >= LIMIT) return { ...out, kind: 'ko', reason: 'Nocaute: a cabeça não aguentou mais.' };
    const clean = move.power >= 2 && after.head >= KO.hurtHead;
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
