// Golpes do duelo 1×1. Tempo e quadros de contato vêm do atlas revisado
// (lote 3, `contactFrames` e `durations`); nada aqui estica ou duplica quadros.
// Fases: preparação até o primeiro contato, contato, continuação e recuperação.
//
// Regras de cancelamento (sequências):
//  - só a partir do contato e até o fim da continuação;
//  - só se o golpe tocou (acerto ou bloqueio) — errar exige a recuperação toda;
//  - qualquer golpe de pé ou de punho emenda em qualquer outro, inclusive
//    chute em chute; o mesmo golpe no máximo duas vezes seguidas;
//  - golpes pesados (`finisher`) fecham a sequência: entram nela, não saem;
//  - no máximo MAX_CHAIN ações por sequência.
export const MAX_CHAIN = 4;
export const MAX_REPEAT = 2;
// Soco não conta na perna: um punho que desce até a linha da cintura acerta
// o tronco. Chutes e joelhadas podem atingir as três regiões.
const FIST_TARGETS = ['head', 'body'];
const ALL_TARGETS = ['head', 'body', 'legs'];

// Vítima do arremesso, quadro a quadro com quem arremessa (8 quadros, contato
// no 5º). O Miguel sendo arremessado (m5_thrown) chega ao giro no contato; o
// resto da queda toca já no chão (miguelRef, estado 'down').
const THROW_VICTIM = { sorriso: { clip: 'fall', frames: [0, 0, 1, 1, 2, 3, 3, 3] }, miguel: { clip: 'm5_thrown', frames: [0, 2, 3, 5, 6, 6, 6, 6] } };

const SPEC = {
  jab: { name: 'JAB', clip: 'r3_jab_head', limb: 'fist', power: 1, damage: 7, balance: 8, hitstun: 300, blockstun: 190, push: 7, cost: 5, links: { kick: 'punchKick' } },
  jabBody: { name: 'JAB NO CORPO', clip: 'r3_jab_body', limb: 'fist', power: 1, damage: 7, balance: 7, hitstun: 300, blockstun: 190, push: 6, cost: 5 },
  cross: { name: 'DIRETO', clip: 'r3_cross_head', limb: 'fist', power: 2, damage: 12, balance: 14, hitstun: 380, blockstun: 230, push: 10, cost: 9 },
  crossBody: { name: 'DIRETO NO TRONCO', clip: 'r3_cross_body', limb: 'fist', power: 2, damage: 11, balance: 12, hitstun: 380, blockstun: 230, push: 9, cost: 9 },
  hook: { name: 'GANCHO NO CORPO', clip: 'r3_hook_body', limb: 'fist', power: 2, damage: 12, balance: 15, hitstun: 400, blockstun: 240, push: 8, cost: 10 },
  overhand: { name: 'GOLPE PESADO', clip: 'r3_overhand_heavy', limb: 'fist', power: 3, damage: 18, balance: 28, hitstun: 520, blockstun: 260, push: 14, cost: 16,
    finisher: true, whiff: { clip: 'missMotion', times: [70, 90, 110, 110, 120] } },
  rushPunch: { name: 'SOCO DE IMPULSO', clip: 'r3_running_punch', limb: 'fist', power: 3, damage: 16, balance: 32, hitstun: 520, blockstun: 280, push: 18, cost: 18,
    finisher: true, whiff: { clip: 'missMotion', times: [70, 90, 110, 110, 120] }, carry: 70 },
  roundBody: { name: 'CIRCULAR NO CORPO', clip: 'r3_round_kick_body', limb: 'foot', power: 2, damage: 14, balance: 18, hitstun: 440, blockstun: 260, push: 12, cost: 12 },
  roundHead: { name: 'CIRCULAR ALTO', clip: 'r3_round_kick_head', limb: 'foot', power: 3, damage: 17, balance: 22, hitstun: 500, blockstun: 270, push: 12, cost: 15 },
  lowKick: { name: 'CHUTE NA PERNA', clip: 'r3_low_kick', limb: 'foot', power: 2, damage: 11, balance: 20, hitstun: 360, blockstun: 220, push: 6, cost: 10,
    targets: ['legs'], links: { attack: 'kickPunch' } },
  // Continuações desenhadas: começam no quadro 5 da sequência combinada, que
  // segue a postura do contato do golpe anterior.
  punchKick: { name: 'JAB > CHUTE ALTO', clip: 'r3_combo_punch_kick', start: 5, limb: 'foot', power: 2, damage: 13, balance: 18, hitstun: 440, blockstun: 250, push: 11, cost: 11 },
  kickPunch: { name: 'CHUTE > DIRETO', clip: 'r3_combo_kick_punch', start: 5, limb: 'fist', power: 2, damage: 11, balance: 13, hitstun: 400, blockstun: 230, push: 10, cost: 9 },
  // Contexto (linhagem anterior, tempos do corredor):
  // arremesso no fim da sequência (G), golpes em quem está no chão e contra-ataque do aparo.
  takedown: { name: 'ARREMESSO', clip: 'clinchFinish', times: [50, 45, 55, 55, 70, 60, 65, 90], active: [4], limb: 'fist', power: 3, damage: 10, balance: 0, hitstun: 0, blockstun: 0, push: 0, cost: 14,
    targets: ['body'], throw: true,
    // Golpe em par: os dois travados na distância do desenho, a vítima em
    // sincronia quadro a quadro com quem arremessa (ver Duel.updatePair).
    pair: { gap: 20, when: 'combo', reach: 44,
      contacts: [{ frame: 4, zone: 'body', lands: true }],
      victim: THROW_VICTIM } },
  groundPunch: { name: 'SOCO NO CHÃO', clip: 'clinchFinish', times: [45, 40, 55, 55, 65, 65, 70, 110], active: [4], limb: 'fist', power: 2, damage: 13, balance: 0, hitstun: 0, blockstun: 0, push: 0, cost: 9,
    ground: true },
  groundKick: { name: 'CHUTE NO CHÃO', clip: 'groundFluid', times: [50, 45, 45, 50, 40, 60, 60, 45, 40, 40, 45, 80], active: [6, 7], limb: 'foot', power: 3, damage: 16, balance: 0, hitstun: 0, blockstun: 0, push: 0, cost: 12,
    ground: true },
  parryCounter: { name: 'APARO > DIRETO', clip: 'parryCounter', times: [35, 30, 35, 45, 45, 60, 65, 100], active: [4], limb: 'fist', power: 2, damage: 14, balance: 18, hitstun: 420, blockstun: 240, push: 10, cost: 6,
    special: true },
  // Clinch: quadros da linhagem anterior (kneeV6 / clinchPunch), tempo do treino.
  knee: { name: 'JOELHADA', clip: 'kneeV6', times: [45, 35, 45, 50, 50, 40, 45, 50], active: [3, 4], limb: 'knee', power: 2, damage: 12, balance: 16, hitstun: 360, blockstun: 0, push: 0, cost: 8,
    targets: ['body'], clinch: true },
  clinchPunch: { name: 'SOCO CURTO', clip: 'clinchPunch', times: [45, 35, 35, 45, 45, 45, 55, 65], active: [2], limb: 'fist', power: 1, damage: 6, balance: 7, hitstun: 300, blockstun: 0, push: 0, cost: 5,
    targets: ['head'], clinch: true },
};

// Miguel (lotes 3 e 4): mesmos golpes e números do Sorriso onde existe desenho
// equivalente; tempos e quadros vêm do atlas (scripts/add-miguel-lote3.py e
// add-miguel-lote4.py). Sem desenho: impulso e soco curto no clinch —
// `MOVE_FALLBACK` troca pelo golpe mais próximo.
const MIGUEL_SPEC = {
  jab: { ...SPEC.jab, clip: 'm3_jab', links: undefined },
  cross: { ...SPEC.cross, clip: 'm3_cross' },
  crossBody: { ...SPEC.crossBody, clip: 'm3_crossBody' },
  overhand: { ...SPEC.overhand, clip: 'm3_overhand', whiff: undefined },
  // Chutes do lote 3 com o pé de apoio parado (`plant`, markers.plantedOffsets):
  // o corpo entra com o chute em vez de recuar.
  roundBody: { ...SPEC.roundBody, clip: 'm3_roundKick', name: 'CHUTE CIRCULAR', plant: true },
  // Cima+K: chute com passo do lote 3, na cintura (pé a −25/−28 px no
  // contato): mira tronco e perna, dano de chute médio. Os chutes altos ficam
  // no atlas sem comando: m4_kickHigh tem o pé no topo da cabeça (−65 px) e
  // m5_kickHigh tem o pé no rosto (−58) mas colado ao corpo (17 px à frente);
  // os corpos nunca ficam a menos de ~35 px e ele não alcança ninguém.
  roundHead: { ...SPEC.roundHead, clip: 'm3_stepKick', name: 'CHUTE COM PASSO', damage: 14, balance: 24, push: 16, targets: ['body', 'legs'], plant: true },
  hook: { ...SPEC.hook, clip: 'm4_hook', name: 'GANCHO' },
  jabBody: { ...SPEC.jabBody, clip: 'm4_jabBody', targets: ['body'] },
  parryCounter: { ...SPEC.parryCounter, clip: 'm4_parryCounter', times: undefined, active: undefined },
  lowKick: { ...SPEC.lowKick, clip: 'm3_lowKick', links: undefined },
  kneeStrike: { name: 'JOELHADA', clip: 'm3_knee', limb: 'knee', power: 2, damage: 12, balance: 16, hitstun: 380, blockstun: 220, push: 8, cost: 9, targets: ['body', 'head'], plant: true },
};
// Golpes do lote 4/pacote 3 do Miguel. `hits`: golpes com vários contatos
// (combos desenhados): cada janela acerta uma vez, com o membro, as regiões e
// a fração do dano dela. `root`: o corpo anda no desenho e a posição final
// vira a do lutador (ver Duel.commitRoot).
Object.assign(MIGUEL_SPEC, {
  uppercut: { name: 'UPPERCUT', clip: 'm4_uppercut', limb: 'fist', power: 2, damage: 13, balance: 16, hitstun: 460, blockstun: 240, push: 9, cost: 10, targets: ['head'], react: 'uppercut' },
  elbow: { name: 'COTOVELADA', clip: 'm4_elbow', limb: 'fist', power: 2, damage: 12, balance: 12, hitstun: 420, blockstun: 230, push: 6, cost: 8, targets: ['head'], react: 'hook' },
  comboBodyUpper: { name: 'CORPO > UPPERCUT', clip: 'm4_comboBodyUpper', limb: 'fist', power: 3, damage: 18, balance: 26, hitstun: 520, blockstun: 260, push: 12, cost: 22, finisher: true,
    hits: [{ frames: [2], targets: ['body'], scale: 0.4 }, { frames: [5], targets: ['body'], scale: 0.4 }, { frames: [8], targets: ['body'], scale: 0.4 }, { frames: [11], targets: ['head'], scale: 1, react: 'uppercut' }] },
  comboJabElbowKnee: { name: 'JAB > COTOVELADA > JOELHADA', clip: 'm4_comboJabElbowKnee', limb: 'fist', power: 3, damage: 18, balance: 24, hitstun: 520, blockstun: 260, push: 12, cost: 22, finisher: true, root: true,
    hits: [{ frames: [2], targets: ['head'], scale: 0.4 }, { frames: [6], targets: ['head'], scale: 0.6, react: 'hook' }, { frames: [10], limb: 'knee', targets: ['body', 'head'], scale: 1 }] },
  comboLowHigh: { name: 'CHUTE BAIXO > ALTO', clip: 'm4_comboLowHigh', limb: 'foot', power: 3, damage: 18, balance: 26, hitstun: 520, blockstun: 270, push: 12, cost: 22, finisher: true,
    hits: [{ frames: [3, 4], targets: ['legs'], scale: 0.5 }, { frames: [10], targets: ['head', 'body'], scale: 1, react: 'hook' }] },
});
// Lote 5: arremesso, chão e clinch do Miguel. Tempos e contato vêm do atlas
// (scripts/add-miguel-lote5.py); dano e custo iguais aos do Sorriso.
Object.assign(MIGUEL_SPEC, {
  // Puxa pelo braço e empurra por cima do quadril; contato no empurrão (quadro 5).
  takedown: { ...SPEC.takedown, clip: 'm5_throw', times: undefined, active: [4],
    pair: { ...SPEC.takedown.pair, contacts: [{ frame: 4, zone: 'body', lands: true }], victim: THROW_VICTIM } },
  // Ajoelhado ao lado: o martelo desce depois de o braço subir (quadro 6).
  groundPunch: { ...SPEC.groundPunch, clip: 'm5_groundPunch', times: undefined, active: [5] },
  // Joelho sobe e o pé desce no tronco (quadro 4).
  groundKick: { ...SPEC.groundKick, clip: 'm5_stomp', name: 'PISADA', times: undefined, active: [3] },
  knee: { ...SPEC.knee, clip: 'm5_clinchKnee', times: undefined, active: undefined },
});
export const CHARACTER_SPECS = { sorriso: SPEC, miguel: MIGUEL_SPEC };
// Sem desenho: o golpe mais próximo. Os novos (uppercut, combos) caem no que o
// mesmo comando já fazia antes deles, para quem não os tem (Sorriso).
export const MOVE_FALLBACK = { jabBody: 'crossBody', hook: 'jab', rushPunch: 'overhand', kneeStrike: 'roundBody',
  uppercut: 'jab', elbow: 'jab', comboBodyUpper: 'overhand', comboJabElbowKnee: 'kneeStrike', comboLowHigh: 'roundBody' };

export function createDuelMoves(clips, spec = SPEC) {
  const moves = {};
  for (const [id, specEntry] of Object.entries(spec)) {
    const spec = specEntry;
    const clip = clips[spec.clip];
    if (!clip) continue; // sem arte, sem golpe
    const start = spec.start || 0;
    const frames = clip.frames.map((_, i) => i).slice(start);
    const times = spec.times || clip.durations.slice(start);
    const hits = spec.hits?.map((h, i) => ({ ...h, index: i }));
    const active = hits ? [...new Set(hits.flatMap(h => h.frames))].sort((a, b) => a - b) : spec.active || clip.contactFrames.filter(i => i >= start);
    if (!active.length) continue;
    const before = i => times.slice(0, frames.indexOf(i)).reduce((a, b) => a + b, 0);
    const activeStart = before(active[0]);
    const activeEnd = before(active.at(-1)) + times[frames.indexOf(active.at(-1))];
    // A continuação termina onde o atlas marca o início da recuperação.
    const phases = clip.frames.map(f => f.phase || '');
    const firstRecovery = frames.find(i => i > active.at(-1) && /^recup|^recol|^acomo/.test(phases[i]));
    const cancelEnd = firstRecovery === undefined ? activeEnd + 80 : before(firstRecovery);
    const duration = times.reduce((a, b) => a + b, 0);
    moves[id] = { id, ...spec, hits, frames, times, active, activeStart, activeEnd, cancelStart: activeStart, cancelEnd, duration, targets: spec.targets || (spec.limb === 'fist' ? FIST_TARGETS : ALL_TARGETS) };
  }
  // Grafo de sequência: todo golpe em pé emenda em todos os outros em pé;
  // pesados e golpes de clinch não abrem sequência.
  // Golpes no chão emendam entre si; arremesso e golpes de clinch não emendam.
  const standing = Object.values(moves).filter(m => !m.clinch && !m.ground && !m.throw && !m.special).map(m => m.id);
  const ground = Object.values(moves).filter(m => m.ground).map(m => m.id);
  for (const m of Object.values(moves)) m.cancels = m.finisher || m.clinch || m.throw ? [] : m.ground ? ground : standing;
  return moves;
}

export function frameIndex(move, t) {
  let rest = Math.max(0, t);
  for (let i = 0; i < move.times.length; i++) {
    if (rest < move.times[i]) return i;
    rest -= move.times[i];
  }
  return move.times.length - 1;
}

// Em quem está no chão: J soco de martelo, K chute.
export const groundMove = cmd => (cmd.kind === 'kick' ? 'groundKick' : 'groundPunch');

// Escolha a partir do comando relativo ao olhar. Mesma tabela para jogador e IA.
// Com `moves`, um golpe sem desenho no personagem vira o substituto mais próximo.
export function chooseMove(cmd, fighter, moves = null) {
  return moves ? resolveMove(moves, rawMove(cmd, fighter)) : rawMove(cmd, fighter);
}

function rawMove(cmd, fighter) {
  // Shift = especial: combos desenhados (só o Miguel tem; o Sorriso cai no que já fazia).
  if (cmd.kind === 'kick' && cmd.run) return cmd.forward ? 'comboJabElbowKnee' : 'comboLowHigh';
  if (cmd.kind === 'kick') return cmd.up ? 'roundHead' : cmd.down ? 'lowKick' : cmd.forward ? 'kneeStrike' : 'roundBody';
  if (cmd.run && cmd.down) return 'comboBodyUpper';
  if (cmd.run && fighter.state === 'run' && Math.abs(fighter.vx) > 60) return 'rushPunch';
  if (cmd.run) return 'overhand';
  if (cmd.down && cmd.forward) return 'crossBody';
  if (cmd.down) return 'jabBody';
  if (cmd.forward) return 'cross';
  if (cmd.back) return 'hook';
  if (cmd.up) return 'uppercut';
  return 'jab';
}

export function resolveMove(moves, id) {
  let next = id;
  for (let i = 0; i < 4 && !moves[next] && MOVE_FALLBACK[next]; i++) next = MOVE_FALLBACK[next];
  return moves[next] ? next : id;
}

// Movimento seguinte permitido durante um golpe, ou null. `history` são os
// golpes já feitos na sequência atual, do primeiro ao atual.
export function cancelTarget(move, cmd, fighter, history = [move.id], moves = null) {
  if (!move.cancels.length) return null;
  const next = move.ground ? groundMove(cmd) : move.links?.[cmd.kind] || chooseMove(cmd, fighter, moves);
  if (!move.cancels.includes(next)) return null;
  const tail = history.slice(-MAX_REPEAT);
  if (tail.length === MAX_REPEAT && tail.every(id => id === next)) return null;
  return next;
}
